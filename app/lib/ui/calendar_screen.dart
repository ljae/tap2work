import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/cupertino.dart';
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
  bool detailed = false;
  final ScrollController weekTimeScroll = ScrollController();
  @override
  void dispose() {
    weekTimeScroll.dispose();
    super.dispose();
  }

  OperationsController get ops => widget.operations;
  String date(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  String name(String? id) =>
      ops
          .rows('tappers')
          .where((t) => t['id'] == id)
          .firstOrNull?['nickname'] ??
      '빈 슬롯';
  static const weekdays = ['월', '화', '수', '목', '금', '토', '일'];
  String dutyLabel(String duty) => duty == 'cashier' ? '계산' : duty;
  IconData dutyIcon(String duty) => duty == '조리'
      ? CupertinoIcons.flame
      : duty == 'cashier'
      ? CupertinoIcons.creditcard
      : CupertinoIcons.person_2;
  Color dutyTint(String duty) => duty == '조리'
      ? const Color(0xFFEAF3EF)
      : duty == 'cashier'
      ? const Color(0xFFEDEDF5)
      : const Color(0xFFFFEFE9);
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
      editShift(day, person, duty: slot['duty']);

  Future<void> editShift(
    DateTime day,
    Json person, {
    String? duty,
    Json? shift,
    String? startAt,
    String? endAt,
  }) async {
    if (!editable) return;
    final tapperId = person['tapperId'] ?? person['id'];
    final tapper = ops
        .rows('tappers')
        .where((p) => p['id'] == tapperId)
        .firstOrNull;
    if (tapper == null) return;
    final duties = (tapper['duties'] as List).cast<String>();
    var selectedDuty = duty != null && duties.contains(duty)
        ? duty
        : duties.first;
    var employment =
        (shift?['employmentType'] ?? tapper['employmentType'] ?? '시간알바')
            as String;
    var start = startAt ?? (shift?['start'] ?? '09:00') as String;
    var end = endAt ?? (shift?['end'] ?? '18:00') as String;
    var repeat = '한 번';
    var duration = 28;
    final times = [
      for (var hour = 0; hour < 24; hour++)
        for (final minute in ['00', '30'])
          '${hour.toString().padLeft(2, '0')}:$minute',
    ];
    final save = await showDialog<Json>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, update) => AlertDialog(
          title: Text('${tapper['nickname']} · ${date(day)} 근무'),
          content: SizedBox(
            width: 380,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('고용형태'),
                  DropdownButton<String>(
                    value: employment,
                    isExpanded: true,
                    items: ['정규직', '시간알바', '정규알바']
                        .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                        .toList(),
                    onChanged: (v) => update(() => employment = v!),
                  ),
                  const Text('담당 R&R'),
                  DropdownButton<String>(
                    value: selectedDuty,
                    isExpanded: true,
                    items: duties
                        .map(
                          (v) => DropdownMenuItem(
                            value: v,
                            child: Text(
                              v.startsWith('서빙')
                                  ? '서빙'
                                  : v == 'cashier'
                                  ? 'Cashier'
                                  : v,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => update(() => selectedDuty = v!),
                  ),
                  const Text('시작 · 종료 (30분 단위)'),
                  Row(
                    children: [
                      for (final field in [true, false])
                        Expanded(
                          child: DropdownButton<String>(
                            value: field ? start : end,
                            isExpanded: true,
                            items: times
                                .map(
                                  (v) => DropdownMenuItem(
                                    value: v,
                                    child: Text(v),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) => update(() {
                              if (field) {
                                start = v!;
                              } else {
                                end = v!;
                              }
                            }),
                          ),
                        ),
                    ],
                  ),
                  if (shift == null) ...[
                    const Text('반복'),
                    DropdownButton<String>(
                      value: repeat,
                      isExpanded: true,
                      items: ['한 번', '월수금', '화목토', '매일', '평일', '주말']
                          .map(
                            (v) => DropdownMenuItem(value: v, child: Text(v)),
                          )
                          .toList(),
                      onChanged: (v) => update(() => repeat = v!),
                    ),
                    if (repeat != '한 번')
                      DropdownButton<int>(
                        value: duration,
                        isExpanded: true,
                        items: [7, 14, 28, 90]
                            .map(
                              (v) => DropdownMenuItem(
                                value: v,
                                child: Text('$v일 동안'),
                              ),
                            )
                            .toList(),
                        onChanged: (v) => update(() => duration = v!),
                      ),
                  ],
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
              onPressed: () => Navigator.pop(context, {
                'tapperId': tapperId,
                'date': date(day),
                'duty': selectedDuty,
                'employmentType': employment,
                'start': start,
                'end': end,
                if (shift != null) 'id': shift['id'],
                'repeatDays': repeat == '한 번' ? 1 : duration,
                'weekdays': switch (repeat) {
                  '월수금' => [1, 3, 5],
                  '화목토' => [2, 4, 6],
                  '매일' => [1, 2, 3, 4, 5, 6, 7],
                  '평일' => [1, 2, 3, 4, 5],
                  '주말' => [6, 7],
                  _ => <int>[],
                },
              }),
              child: const Text('저장'),
            ),
          ],
        ),
      ),
    );
    if (save != null) await action('save_shift_pattern', save);
  }

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
                                      '${time.hour.toString().padLeft(2, '0')}:${(time.minute < 30 ? 0 : 30).toString().padLeft(2, '0')}',
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

  int minute(String value) =>
      int.parse(value.substring(0, 2)) * 60 + int.parse(value.substring(3, 5));
  String clockAt(int value) =>
      '${(value ~/ 60).toString().padLeft(2, '0')}:${(value % 60).toString().padLeft(2, '0')}';
  void dropShift(
    DateTime day,
    Json person,
    Offset global,
    BuildContext targetContext,
  ) {
    final box = targetContext.findRenderObject() as RenderBox;
    final local = box.globalToLocal(global);
    final start = (360 + (local.dy / 30).round() * 30).clamp(0, 1410);
    final shift = person['tapperId'] == null ? null : person;
    final oldStart = shift == null ? 540 : minute(shift['start']);
    final oldEnd = shift == null ? 1080 : minute(shift['end']);
    final duration = (oldEnd - oldStart + 1440) % 1440;
    final roleWidth = MediaQuery.sizeOf(context).width < 600 ? 70.0 : 120.0;
    final lane = (local.dx / roleWidth).floor().clamp(0, 2);
    final duties =
        (ops
                        .rows('tappers')
                        .where(
                          (p) =>
                              p['id'] == (person['tapperId'] ?? person['id']),
                        )
                        .firstOrNull?['duties']
                    as List? ??
                [])
            .cast<String>();
    final preferred = lane == 0
        ? '조리'
        : lane == 2
        ? 'cashier'
        : duties.where((d) => d.startsWith('서빙')).firstOrNull;
    editShift(
      day,
      person,
      shift: shift,
      duty: preferred,
      startAt: clockAt(start),
      endAt: clockAt((start + duration) % 1440),
    );
  }

  Future<void> chooseForDay(DateTime day) async {
    if (!editable) return;
    final people = ops
        .rows('tappers')
        .where((p) => p['active'] == true)
        .toList();
    final person = await showModalBottomSheet<Json>(
      context: context,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            const ListTile(title: Text('크루 선택')),
            for (final p in people)
              ListTile(
                title: Text(
                  '${p['nickname']} · ${(p['duties'] as List).join('/')}',
                ),
                onTap: () => Navigator.pop(context, p),
              ),
          ],
        ),
      ),
    );
    if (person != null) await editShift(day, person);
  }

  List<Json> earlyShifts(DateTime day) => ops.rows('staffShifts').where((s) {
    if (s['date'] == date(day)) return minute(s['start']) < 360;
    if (s['date'] == date(day.subtract(const Duration(days: 1)))) {
      return minute(s['end']) <= minute(s['start']) && minute(s['end']) > 0;
    }
    return false;
  }).toList();

  Future<void> showEarly(DateTime day) async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            ListTile(title: Text('${date(day)} · 06:00 이전 / 야간 근무')),
            for (final shift in earlyShifts(day))
              ListTile(
                title: Text('${shift['duty']} · ${name(shift['tapperId'])}'),
                subtitle: Text(
                  '${shift['date']} ${shift['start']}–${shift['end']}',
                ),
                onTap: !editable
                    ? null
                    : () {
                        Navigator.pop(context);
                        editShift(
                          DateTime.parse(shift['date']),
                          shift,
                          shift: shift,
                        );
                      },
              ),
          ],
        ),
      ),
    );
  }

  Json? matchingShift(DateTime day, Json slot) => ops
      .rows('staffShifts')
      .where(
        (s) =>
            s['date'] == date(day) &&
            s['slotId'] == slot['id'] &&
            s['duty'] == slot['duty'] &&
            s['start'] == slot['start'] &&
            s['end'] == slot['end'],
      )
      .firstOrNull;

  Widget weekStrip(DateTime monday, DateTime selectedDay) => Row(
    children: [
      for (var index = 0; index < 7; index++)
        Expanded(
          child: Builder(
            builder: (context) {
              final day = monday.add(Duration(days: index));
              final selected = date(day) == date(selectedDay);
              final filled = ops
                  .rows('staffingSlots')
                  .where((slot) => matchingShift(day, slot) != null)
                  .length;
              return Padding(
                padding: EdgeInsets.only(right: index == 6 ? 0 : 4),
                child: Semantics(
                  button: true,
                  selected: selected,
                  label:
                      '${day.month}월 ${day.day}일 ${weekdays[index]}, $filled명 배정',
                  child: InkWell(
                    key: Key('calendar-day-${date(day)}'),
                    onTap: () => setState(() => this.selected = day),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      constraints: const BoxConstraints(minHeight: 74),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: selected ? AppColors.ink : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: selected ? AppColors.ink : AppColors.line,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            weekdays[index],
                            style: TextStyle(
                              fontSize: 11,
                              color: selected
                                  ? Colors.white70
                                  : AppColors.muted,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${day.day}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: selected ? Colors.white : AppColors.ink,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Container(
                            width: 5,
                            height: 5,
                            decoration: BoxDecoration(
                              color: filled == 0
                                  ? (selected ? Colors.white54 : AppColors.line)
                                  : (selected
                                        ? const Color(0xFFFFB4A3)
                                        : AppColors.accent),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
    ],
  );

  Widget rosterCard(DateTime day, Json slot, Json? shift) {
    final duty = slot['duty'] as String;
    final filled = shift != null;
    return DragTarget<Json>(
      onWillAcceptWithDetails: (_) => editable && !filled,
      onAcceptWithDetails: (details) => assign(day, slot, details.data),
      builder: (context, candidates, _) {
        final card = Material(
          color: candidates.isNotEmpty
              ? const Color(0xFFFCE8E4)
              : filled
              ? Colors.white
              : const Color(0xFFFFFAF5),
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: () => pick(day, slot, shift),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              constraints: const BoxConstraints(minHeight: 76),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                border: Border.all(
                  color: filled ? AppColors.line : const Color(0xFFEACAB6),
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: dutyTint(duty),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(dutyIcon(duty), size: 19, color: AppColors.ink),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${dutyLabel(duty)} · ${slot['start']}–${slot['end']}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.muted,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          filled ? name(shift['tapperId']) : '빈 슬롯',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    filled ? CupertinoIcons.chevron_right : CupertinoIcons.plus,
                    size: 17,
                    color: filled ? AppColors.muted : AppColors.accent,
                  ),
                ],
              ),
            ),
          ),
        );
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: filled ? drag(shift, card) : card,
        );
      },
    );
  }

  Widget dayRoster(DateTime day) {
    final slots = ops.rows('staffingSlots');
    final filled = slots
        .where((slot) => matchingShift(day, slot) != null)
        .length;
    final extras = ops
        .rows('staffShifts')
        .where(
          (shift) =>
              shift['date'] == date(day) &&
              !slots.any(
                (slot) => matchingShift(day, slot)?['id'] == shift['id'],
              ),
        )
        .toList();
    final early = earlyShifts(day);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${day.month}월 ${day.day}일 ${weekdays[day.weekday - 1]}요일',
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '배정 $filled · 빈 슬롯 ${slots.length - filled}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
            if (editable)
              TextButton.icon(
                onPressed: () => chooseForDay(day),
                icon: const Icon(CupertinoIcons.plus, size: 16),
                label: const Text('근무 추가'),
              ),
          ],
        ),
        const SizedBox(height: 12),
        for (final slot in slots)
          rosterCard(day, slot, matchingShift(day, slot)),
        for (final shift in extras)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              shape: RoundedRectangleBorder(
                side: const BorderSide(color: AppColors.line),
                borderRadius: BorderRadius.circular(16),
              ),
              tileColor: Colors.white,
              leading: Icon(dutyIcon(shift['duty']), size: 20),
              title: Text(
                '${name(shift['tapperId'])} · ${dutyLabel(shift['duty'])}',
              ),
              subtitle: Text('${shift['start']}–${shift['end']} · 별도 근무'),
              onTap: editable
                  ? () => editShift(day, shift, shift: shift)
                  : null,
            ),
          ),
        if (early.isNotEmpty)
          TextButton.icon(
            onPressed: () => showEarly(day),
            icon: const Icon(CupertinoIcons.moon, size: 16),
            label: Text('새벽·야간 근무 ${early.length}건 보기'),
          ),
      ],
    );
  }

  Widget weekGrid(DateTime monday) {
    const rowHeight = 30.0;
    final compact = MediaQuery.sizeOf(context).width < 600;
    final dayWidth = compact ? 210.0 : 360.0;
    final roleWidth = dayWidth / 3;
    const axisWidth = 48.0;
    const gridHeight = 36 * rowHeight;
    final shifts = ops.rows('staffShifts');
    return SizedBox(
      height: 762,
      child: Stack(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: axisWidth + dayWidth * 7,
              child: Column(
                children: [
                  Row(
                    children: [
                      const SizedBox(width: axisWidth),
                      for (var n = 0; n < 7; n++)
                        Builder(
                          builder: (context) {
                            final day = monday.add(Duration(days: n));
                            final early = earlyShifts(day);
                            return SizedBox(
                              width: dayWidth,
                              height: 82,
                              child: Column(
                                children: [
                                  Text(
                                    '${['월', '화', '수', '목', '금', '토', '일'][n]} ${day.month}/${day.day}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      for (final role in [
                                        '조리',
                                        '서빙',
                                        'Cashier',
                                      ])
                                        Expanded(
                                          child: Center(
                                            child: Text(
                                              role,
                                              style: const TextStyle(
                                                fontSize: 11,
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  if (early.isNotEmpty)
                                    SizedBox(
                                      height: 24,
                                      child: InkWell(
                                        onTap: () => showEarly(day),
                                        child: Center(
                                          child: Text(
                                            '새벽·야간 ${early.length}',
                                            style: const TextStyle(
                                              fontSize: 10,
                                            ),
                                          ),
                                        ),
                                      ),
                                    )
                                  else
                                    const SizedBox(height: 24),
                                ],
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                  SizedBox(
                    height: 680,
                    child: SingleChildScrollView(
                      controller: weekTimeScroll,
                      child: SizedBox(
                        height: gridHeight,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(width: axisWidth),
                            for (var n = 0; n < 7; n++)
                              Builder(
                                builder: (context) {
                                  final day = monday.add(Duration(days: n));
                                  final dayShifts = shifts
                                      .where(
                                        (s) =>
                                            s['date'] == date(day) ||
                                            s['date'] ==
                                                date(
                                                  day.subtract(
                                                    const Duration(days: 1),
                                                  ),
                                                ),
                                      )
                                      .toList();
                                  return DragTarget<Json>(
                                    key: Key('week-grid-day-${date(day)}'),
                                    onWillAcceptWithDetails: (_) => editable,
                                    onAcceptWithDetails: (details) => dropShift(
                                      day,
                                      details.data,
                                      details.offset,
                                      context,
                                    ),
                                    builder: (context, candidates, _) => SizedBox(
                                      width: dayWidth,
                                      height: gridHeight,
                                      child: Stack(
                                        children: [
                                          for (var tick = 12; tick < 48; tick++)
                                            Positioned(
                                              top: (tick - 12) * rowHeight,
                                              left: 0,
                                              right: 0,
                                              height: rowHeight,
                                              child: InkWell(
                                                onTap: () => chooseForDay(day),
                                                child: DecoratedBox(
                                                  decoration: BoxDecoration(
                                                    color: candidates.isNotEmpty
                                                        ? const Color(
                                                            0xFFFCE8E4,
                                                          )
                                                        : Colors.white,
                                                    border: Border(
                                                      left: const BorderSide(
                                                        color: AppColors.line,
                                                      ),
                                                      top: BorderSide(
                                                        color: AppColors.line,
                                                        width: tick.isEven
                                                            ? 1
                                                            : .4,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          for (final shift in dayShifts)
                                            Builder(
                                              builder: (context) {
                                                final previous =
                                                    shift['date'] != date(day);
                                                final start = previous
                                                    ? 0
                                                    : minute(shift['start']);
                                                final finish = minute(
                                                  shift['end'],
                                                );
                                                final end = previous
                                                    ? finish
                                                    : finish <= start
                                                    ? 1440
                                                    : finish;
                                                if ((previous &&
                                                        finish >
                                                            minute(
                                                              shift['start'],
                                                            )) ||
                                                    end <= 360) {
                                                  return const SizedBox.shrink();
                                                }
                                                final visibleStart = start < 360
                                                    ? 360
                                                    : start;
                                                final color =
                                                    shift['duty'] == '조리'
                                                    ? const Color(0xFFE3EDF8)
                                                    : shift['duty'] == 'cashier'
                                                    ? const Color(0xFFE8E8F3)
                                                    : const Color(0xFFFBE9E4);
                                                final lane =
                                                    shift['duty'] == '조리'
                                                    ? 0
                                                    : shift['duty'] == 'cashier'
                                                    ? 2
                                                    : 1;
                                                return Positioned(
                                                  top:
                                                      (visibleStart - 360) /
                                                          30 *
                                                          rowHeight +
                                                      1,
                                                  left:
                                                      lane * roleWidth +
                                                      (lane == 1 &&
                                                              shift['duty'] ==
                                                                  '서빙2'
                                                          ? roleWidth / 2 + 1
                                                          : 2),
                                                  width: lane == 1
                                                      ? roleWidth / 2 - 4
                                                      : roleWidth - 4,
                                                  height:
                                                      ((end - visibleStart) /
                                                                  30 *
                                                                  rowHeight -
                                                              2)
                                                          .clamp(
                                                            28,
                                                            gridHeight,
                                                          ),
                                                  child: drag(
                                                    shift,
                                                    Material(
                                                      color: color,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            6,
                                                          ),
                                                      child: InkWell(
                                                        onTap: () => editShift(
                                                          DateTime.parse(
                                                            shift['date'],
                                                          ),
                                                          shift,
                                                          shift: shift,
                                                        ),
                                                        child: Padding(
                                                          padding:
                                                              const EdgeInsets.all(
                                                                5,
                                                              ),
                                                          child: Text(
                                                            compact
                                                                ? '${name(shift['tapperId'])}${lane == 1 ? '' : '\n${shift['start']}–${shift['end']}'}'
                                                                : '${shift['duty'].toString().startsWith('서빙')
                                                                      ? '서빙'
                                                                      : shift['duty'] == 'cashier'
                                                                      ? 'Cashier'
                                                                      : shift['duty']} · ${name(shift['tapperId'])}\n${shift['start']}–${shift['end']}',
                                                            style:
                                                                const TextStyle(
                                                                  fontSize: 10,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                ),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 0,
            top: 82,
            width: axisWidth,
            height: 680,
            child: IgnorePointer(
              child: ColoredBox(
                color: Colors.white,
                child: ClipRect(
                  child: AnimatedBuilder(
                    animation: weekTimeScroll,
                    builder: (context, _) {
                      final offset = weekTimeScroll.hasClients
                          ? weekTimeScroll.offset
                          : 0.0;
                      return Stack(
                        children: [
                          for (var n = 12; n < 48; n++)
                            Positioned(
                              top: (n - 12) * rowHeight - offset,
                              left: 2,
                              child: Text(
                                n.isEven
                                    ? '${(n ~/ 2).toString().padLeft(2, '0')}:00'
                                    : ':30',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: AppColors.muted,
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),
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
      final compact = MediaQuery.sizeOf(context).width < 600;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PageHeading('CALENDAR', '크루 근무표', '오늘 함께 일하는 사람과 빈 자리를 확인해요.'),
          Row(
            children: [
              IconButton(
                tooltip: '이전',
                onPressed: () => setState(
                  () => selected = monthly
                      ? DateTime(day.year, day.month - 1, 1)
                      : day.subtract(const Duration(days: 7)),
                ),
                icon: const Icon(CupertinoIcons.chevron_left, size: 19),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    monthly
                        ? '${day.year}년 ${day.month}월'
                        : '${start.month}월 ${start.day}일 – ${start.add(const Duration(days: 6)).month}월 ${start.add(const Duration(days: 6)).day}일',
                    maxLines: 1,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: AppColors.ink,
                    ),
                  ),
                ),
              ),
              IconButton(
                tooltip: '다음',
                onPressed: () => setState(
                  () => selected = monthly
                      ? DateTime(day.year, day.month + 1, 1)
                      : day.add(const Duration(days: 7)),
                ),
                icon: const Icon(CupertinoIcons.chevron_right, size: 19),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
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
              if (!monthly && compact)
                ChoiceChip(
                  label: const Text('시간표'),
                  selected: detailed,
                  onSelected: (_) => setState(() => detailed = !detailed),
                ),
              if (ops.isLeader)
                TextButton.icon(
                  onPressed: editable ? configure : null,
                  icon: const Icon(CupertinoIcons.person_2, size: 16),
                  label: Text(
                    '하루 ${ops.rows('staffingSlots').length}명 · 슬롯 설정',
                  ),
                ),
            ],
          ),
          if (ops.readOnly)
            const Information('공개 미리보기 · 근무 배정은 로그인 후 저장할 수 있어요.'),
          const SizedBox(height: 16),
          if (!monthly) ...[
            weekStrip(start, day),
            const SizedBox(height: 22),
            dayRoster(day),
            const SizedBox(height: 16),
            if (!compact || detailed) ...[
              const Text(
                '주간 시간표 · 06:00–24:00',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 8),
              weekGrid(start),
            ],
          ] else
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
          const SizedBox(height: 20),
          const Text(
            '크루 · 길게 눌러 빈 슬롯으로 이동',
            style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
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
                avatar: const Icon(
                  CupertinoIcons.person_crop_circle_badge_plus,
                  size: 17,
                ),
                label: const Text('크루 관리'),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => Scaffold(
                      appBar: AppBar(title: const Text('크루 관리')),
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
        ],
      );
    },
  );
}
