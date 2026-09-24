import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import '../state/operations_controller.dart';
import 'components.dart';
import 'team_screen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key, required this.operations});
  final OperationsController operations;
  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime? selected;
  bool monthly = false;
  OperationsController get ops => widget.operations;
  String date(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  String name(String? id) =>
      ops
          .rows('tappers')
          .where((t) => t['id'] == id)
          .firstOrNull?['nickname'] ??
      '빈 슬롯';
  bool get editable => ops.isLeader && !ops.readOnly && !ops.busy;
  Future<void> action(String type, Json data) async {
    final ok = await ops.act(type, data);
    if (mounted && !ok) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(ops.error ?? '저장하지 못했어요.')));
    }
  }

  Future<void> assign(DateTime day, Json slot, Json person) =>
      action('assign_staffing_slot', {
        'date': date(day),
        'slotId': slot['id'],
        'tapperId': person['tapperId'] ?? person['id'],
        if (person['tapperId'] != null) 'sourceShiftId': person['id'],
      });
  Future<void> configure() async {
    final revision = ops.data?['revision'];
    final draft = ops
        .rows('staffingSlots')
        .map((s) => Map<String, dynamic>.from(s))
        .toList();
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, update) => AlertDialog(
          title: const Text('하루 필요 인원'),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final slot in draft)
                    Wrap(
                      spacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        DropdownButton<String>(
                          value: slot['duty'],
                          items: ['조리', '서빙1', '서빙2', 'cashier']
                              .map(
                                (s) =>
                                    DropdownMenuItem(value: s, child: Text(s)),
                              )
                              .toList(),
                          onChanged: (v) => update(() => slot['duty'] = v),
                        ),
                        for (final field in ['start', 'end'])
                          TextButton(
                            onPressed: () async {
                              final parts = (slot[field] as String).split(':');
                              final time = await showTimePicker(
                                context: context,
                                initialTime: TimeOfDay(
                                  hour: int.parse(parts[0]),
                                  minute: int.parse(parts[1]),
                                ),
                              );
                              if (time != null) {
                                update(
                                  () => slot[field] =
                                      '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
                                );
                              }
                            },
                            child: Text(slot[field]),
                          ),
                        IconButton(
                          onPressed: draft.length > 1
                              ? () => update(() => draft.remove(slot))
                              : null,
                          icon: const Icon(Icons.remove_circle_outline),
                        ),
                      ],
                    ),
                  TextButton(
                    onPressed: draft.length < 12
                        ? () => update(
                            () => draft.add({
                              'duty': '서빙1',
                              'start': '09:00',
                              'end': '18:00',
                            }),
                          )
                        : null,
                    child: const Text('슬롯 추가'),
                  ),
                  const Text('기존 근무 기록은 유지돼요. 변경 후 배정을 확인하세요.'),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('저장'),
            ),
          ],
        ),
      ),
    );
    if (saved == true) {
      await action('save_staffing_slots', {
        'slots': draft,
        'revision': revision,
      });
    }
  }

  Future<void> pick(DateTime day, Json slot, Json? shift) async {
    final start = DateTime.parse('${date(day)}T${slot['start']}:00+09:00');
    final end = DateTime.parse('${date(day)}T${slot['end']}:00+09:00');
    final people = ops
        .rows('tappers')
        .where(
          (p) =>
              p['active'] == true &&
              (p['duties'] as List).contains(slot['duty']) &&
              !ops.rows('staffShifts').any((s) {
                if (s['tapperId'] != p['id'] || s['status'] == 'leave') {
                  return false;
                }
                final a = DateTime.parse('${s['date']}T${s['start']}:00+09:00');
                var b = DateTime.parse('${s['date']}T${s['end']}:00+09:00');
                if (!b.isAfter(a)) b = b.add(const Duration(days: 1));
                return a.isBefore(end) && b.isAfter(start);
              }),
        )
        .toList();
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${date(day)} · ${slot['duty']} ${slot['start']}–${slot['end']}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              if (shift != null)
                ListTile(
                  title: Text('${name(shift['tapperId'])} · 배정 해제'),
                  onTap: editable
                      ? () {
                          Navigator.pop(context);
                          action('assign_staffing_slot', {
                            'date': date(day),
                            'slotId': slot['id'],
                            'tapperId': null,
                          });
                        }
                      : null,
                ),
              if (shift == null) ...[
                const Text(
                  '추가 근무 후보 · 역할과 예정 근무를 기준으로 추천해요. 가능 여부는 직접 확인해 주세요.',
                ),
                for (final person in people)
                  ListTile(
                    title: Text(name(person['id'])),
                    subtitle: const Text('가능 여부 확인 후 배정'),
                    onTap: editable
                        ? () {
                            Navigator.pop(context);
                            assign(day, slot, person);
                          }
                        : null,
                  ),
                if (people.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(12),
                    child: Text('겹치지 않는 담당 크루가 없어요.'),
                  ),
                TextButton(
                  onPressed: () async {
                    await launchUrl(
                      Uri.parse('https://www.albamon.com/'),
                      mode: LaunchMode.externalApplication,
                    );
                  },
                  child: const Text('알바몬 채용 사이트 ↗ · HR 연동 준비 중'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget drag(Json data, Widget child) {
    final feedback = Material(
      elevation: 6,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Text(name(data['tapperId'] ?? data['id'])),
      ),
    );
    final faded = Opacity(opacity: .4, child: child);
    final mobile =
        defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.android;
    return mobile
        ? LongPressDraggable<Json>(
            data: data,
            maxSimultaneousDrags: editable ? 1 : 0,
            feedback: feedback,
            childWhenDragging: faded,
            child: child,
          )
        : Draggable<Json>(
            data: data,
            maxSimultaneousDrags: editable ? 1 : 0,
            feedback: feedback,
            childWhenDragging: faded,
            child: child,
          );
  }

  Widget dayCard(DateTime day) {
    final shifts = ops
        .rows('staffShifts')
        .where((s) => s['date'] == date(day))
        .toList();
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '${day.month}/${day.day} ${['월', '화', '수', '목', '금', '토', '일'][day.weekday - 1]}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          for (final slot in ops.rows('staffingSlots'))
            Builder(
              builder: (context) {
                final shift = shifts
                    .where(
                      (s) =>
                          s['slotId'] == slot['id'] &&
                          s['duty'] == slot['duty'] &&
                          s['start'] == slot['start'] &&
                          s['end'] == slot['end'],
                    )
                    .firstOrNull;
                return DragTarget<Json>(
                  onWillAcceptWithDetails: (_) => editable && shift == null,
                  onAcceptWithDetails: (d) => assign(day, slot, d.data),
                  builder: (context, candidates, _) {
                    final card = Container(
                      margin: const EdgeInsets.only(top: 8),
                      decoration: BoxDecoration(
                        color: candidates.isNotEmpty
                            ? const Color(0xFFFCE8E4)
                            : shift == null
                            ? const Color(0xFFFFF4E5)
                            : const Color(0xFFEDF5F1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: InkWell(
                        onTap: () => pick(day, slot, shift),
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(slot['duty']),
                              Text(
                                '${slot['start']}–${slot['end']}',
                                style: const TextStyle(fontSize: 11),
                              ),
                              Text(
                                name(shift?['tapperId']),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                    return shift == null ? card : drag(shift, card);
                  },
                );
              },
            ),
          for (final shift in shifts.where(
            (s) => !ops
                .rows('staffingSlots')
                .any(
                  (slot) =>
                      slot['id'] == s['slotId'] &&
                      slot['start'] == s['start'] &&
                      slot['end'] == s['end'] &&
                      slot['duty'] == s['duty'],
                ),
          ))
            drag(
              shift,
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '${name(shift['tapperId'])} · ${shift['duty']}\n${shift['start']}–${shift['end']} · 별도 근무',
                  style: const TextStyle(fontSize: 11),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: ops,
    builder: (context, _) {
      final day =
          selected ??
          DateTime.tryParse(ops.data?['day'] ?? '') ??
          DateTime.now();
      final start = monthly
          ? DateTime(day.year, day.month, 1)
          : day.subtract(Duration(days: day.weekday - 1));
      final count = monthly ? DateTime(day.year, day.month + 1, 0).day : 7;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PageHeading('CALENDAR', '크루 근무표', '빈 슬롯을 채우고 함께 일할 사람을 확인하세요.'),
          Wrap(
            spacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              ChoiceChip(
                label: const Text('주간'),
                selected: !monthly,
                onSelected: (_) => setState(() => monthly = false),
              ),
              ChoiceChip(
                label: const Text('월간'),
                selected: monthly,
                onSelected: (_) => setState(() => monthly = true),
              ),
              IconButton(
                tooltip: '이전',
                onPressed: () => setState(
                  () => selected = monthly
                      ? DateTime(day.year, day.month - 1, 1)
                      : day.subtract(const Duration(days: 7)),
                ),
                icon: const Icon(Icons.chevron_left),
              ),
              Text(monthly ? '${day.year}년 ${day.month}월' : '${date(start)} 주'),
              IconButton(
                tooltip: '다음',
                onPressed: () => setState(
                  () => selected = monthly
                      ? DateTime(day.year, day.month + 1, 1)
                      : day.add(const Duration(days: 7)),
                ),
                icon: const Icon(Icons.chevron_right),
              ),
              if (ops.isLeader)
                TextButton(
                  onPressed: editable ? configure : null,
                  child: Text(
                    '하루 ${ops.rows('staffingSlots').length}명 · 슬롯 설정',
                  ),
                ),
            ],
          ),
          if (ops.readOnly)
            const Information('공개 미리보기 · 근무 배정은 로그인 후 저장할 수 있어요.'),
          const SizedBox(height: 12),
          const Text('HR POOL · 길게 눌러 빈 슬롯으로 이동'),
          Wrap(
            spacing: 8,
            children: [
              for (final person
                  in ops.rows('tappers').where((p) => p['active'] == true))
                drag(
                  person,
                  Chip(
                    label: Text(
                      '${person['nickname']} · ${(person['duties'] as List).join('/')}',
                    ),
                  ),
                ),
              ActionChip(
                label: const Text('크루 등록 / 관리'),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => Scaffold(
                      appBar: AppBar(title: const Text('HR Pool')),
                      body: SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: TeamScreen(operations: ops),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: 1120,
              child: Column(
                children: [
                  Row(
                    children: [
                      for (final label in ['월', '화', '수', '목', '금', '토', '일'])
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Text(label),
                          ),
                        ),
                    ],
                  ),
                  for (
                    var row = 0;
                    row <
                        ((count + (monthly ? start.weekday - 1 : 0)) / 7)
                            .ceil();
                    row++
                  )
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (var col = 0; col < 7; col++)
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 3,
                                ),
                                child: Builder(
                                  builder: (_) {
                                    final index =
                                        row * 7 +
                                        col -
                                        (monthly ? start.weekday - 1 : 0);
                                    return index < 0 || index >= count
                                        ? const SizedBox()
                                        : dayCard(
                                            start.add(Duration(days: index)),
                                          );
                                  },
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      );
    },
  );
}
