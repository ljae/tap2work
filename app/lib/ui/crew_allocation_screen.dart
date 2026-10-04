import 'dart:convert';
import 'package:flutter/material.dart';
import '../domain/part_schedule.dart';
import '../state/operations_controller.dart';
import 'components.dart';
import 'crew_colors.dart';
import 'business_hours_slider.dart';
import 'workplace_screens.dart';

/// Staffing requirements are read-only here. Drafts contain crew patterns only.
class CrewAllocationScreen extends StatefulWidget {
  const CrewAllocationScreen({super.key, required this.ops, required this.day});
  final OperationsController ops;
  final DateTime day;
  @override
  State<CrewAllocationScreen> createState() => _CrewAllocationScreenState();
}

class _CrewAllocationScreenState extends State<CrewAllocationScreen> {
  OperationsController get ops => widget.ops;
  late final String actor = ops.actorId;
  late int revision = ops.data?['revision'] ?? 0;
  late final Json workplace = jsonDecode(
    jsonEncode(ops.data?['workplace'] ?? {}),
  );
  late DateTime monday = widget.day.subtract(
    Duration(days: widget.day.weekday - 1),
  );
  late int weekday = widget.day.weekday;
  late DateTime from = DateTime.parse(
    ops.data?['day'] ?? rosterDate(widget.day),
  );
  late DateTime until = from.add(const Duration(days: 27));
  final Map<String, Json> patterns = {};
  final Set<String> changed = {};
  String? selectedCrew, error;
  bool saving = false;
  bool get editable =>
      ops.isLeader &&
      ops.data?['canEditSchedule'] != false &&
      !ops.readOnly &&
      !ops.busy &&
      !saving &&
      actor == ops.actorId;
  List<Json> get people =>
      ops.rows('tappers').where((p) => p['active'] != false).toList();
  List<Json> get parts => (workplace['parts'] as List? ?? [])
      .cast<Json>()
      .where((p) => p['hidden'] != true)
      .toList();
  List<Json> bands(int day) =>
      (workplace['days']?['$day'] as List? ?? []).cast<Json>();
  String name(String id) =>
      people.where((p) => p['id'] == id).firstOrNull?['nickname'] ?? '크루';
  int weekOf(Json pattern) =>
      (monday.difference(DateTime.parse(pattern['anchor'])).inDays ~/ 7) %
      (pattern['cycleWeeks'] as int);
  List<Json> entries(String id) =>
      (patterns[id]!['entries'] as List).cast<Json>();
  bool activeEntry(String id, Json e) =>
      e['week'] == weekOf(patterns[id]!) && e['weekday'] == weekday;
  String bandStart(Json b, String part) =>
      b['partTimes']?[part]?['start'] ?? b['start'];
  String bandEnd(Json b, String part) =>
      b['partTimes']?[part]?['end'] ?? b['end'];
  bool matches(Json e, Json b, String part) =>
      e['partId'] == part &&
      e['start'] == bandStart(b, part) &&
      e['end'] == bandEnd(b, part) &&
      (e['timeBandId'] == null || e['timeBandId'] == b['id']);
  int count(Json b, String part) =>
      b['headcounts']?[part] ?? (b['custom'] == true ? 0 : 1);
  List<({String id, Json entry})> assigned(Json b, String part) => [
    for (final id in patterns.keys)
      for (final e in entries(id))
        if (activeEntry(id, e) && matches(e, b, part)) (id: id, entry: e),
  ];
  @override
  void initState() {
    super.initState();
    for (final person in people) {
      final id = person['id'] as String;
      final old = ops
          .rows('crewPatterns')
          .where((p) => p['tapperId'] == id)
          .firstOrNull;
      patterns[id] = jsonDecode(
        jsonEncode(
          old ??
              {
                'tapperId': id,
                'cycleWeeks': 1,
                'anchor': rosterDate(monday),
                'entries': <Json>[],
              },
        ),
      );
    }
  }

  bool canAssign(String id, Json band, String part, [Json? source]) {
    final person = people.where((p) => p['id'] == id).firstOrNull;
    if (person == null) return false;
    final allowed = person['workProfile']?['partIds'] as List? ?? [];
    if (allowed.isNotEmpty && !allowed.contains(part)) return false;
    final boundary = rosterMinute(workplace['businessDayStart'] ?? '00:00');
    int absolute(String value) {
      final m = rosterMinute(value);
      return m < boundary ? m + 1440 : m;
    }

    final start = (weekday - 1) * 1440 + absolute(bandStart(band, part));
    var end = (weekday - 1) * 1440 + absolute(bandEnd(band, part));
    if (end <= start) end += 1440;
    final pattern = patterns[id]!;
    final cycle = pattern['cycleWeeks'] as int;
    // Include previous/next occurrence so Sunday overnight cannot overlap Monday.
    for (var offset = -1; offset <= 1; offset++) {
      for (final e in entries(id)) {
        if (identical(e, source) ||
            e['week'] != (weekOf(pattern) + offset) % cycle) {
          continue;
        }
        final a =
            (offset * 7 + (e['weekday'] as int) - 1) * 1440 +
            absolute(e['start']);
        var b =
            (offset * 7 + (e['weekday'] as int) - 1) * 1440 +
            absolute(e['end']);
        if (b <= a) b += 1440;
        if (a < end && start < b) return false;
      }
    }
    return true;
  }

  void assign(String id, Json band, String part, [Json? source]) {
    if (!editable || !canAssign(id, band, part, source)) return;
    setState(() {
      if (source != null) (patterns[id]!['entries'] as List).remove(source);
      (patterns[id]!['entries'] as List).add({
        'week': weekOf(patterns[id]!),
        'weekday': weekday,
        'partId': part,
        if (band['id'] != null) 'timeBandId': band['id'],
        'start': bandStart(band, part),
        'end': bandEnd(band, part),
      });
      changed.add(id);
      error = null;
    });
  }

  void remove(String id, Json entry) {
    if (!editable) return;
    setState(() {
      (patterns[id]!['entries'] as List).remove(entry);
      changed.add(id);
    });
  }

  Future<void> pick(Json band, String part) async {
    if (!editable) return;
    if (selectedCrew != null && canAssign(selectedCrew!, band, part)) {
      assign(selectedCrew!, band, part);
      return;
    }
    final id = await showAppSheet<String>(
      context,
      builder: (c) => ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            '${partLabel(ops, part)} · ${bandStart(band, part)}–${bandEnd(band, part)}',
            style: AppText.title,
          ),
          for (final person in people)
            ListTile(
              title: Text(person['nickname']),
              subtitle: canAssign(person['id'], band, part)
                  ? null
                  : const Text('담당 파트 또는 중복 시간 확인'),
              enabled: canAssign(person['id'], band, part),
              onTap: () => Navigator.pop(c, person['id'] as String),
            ),
        ],
      ),
    );
    if (id != null && mounted) assign(id, band, part);
  }

  Set<String> get pendingIds => {
    ...changed,
    for (final p in ops.rows('crewPatterns'))
      if (patterns.containsKey(p['tapperId']) &&
          p['hoursVersion'] != (workplace['hoursVersion'] ?? 0))
        p['tapperId'] as String,
  };

  Future<void> save() async {
    if (!editable || pendingIds.isEmpty) return;
    setState(() => saving = true);
    final ok = await ops.act('save_crew_allocations', {
      'revision': revision,
      'patterns': [for (final id in pendingIds) patterns[id]],
    });
    if (!mounted) return;
    setState(() {
      saving = false;
      error = ok ? null : ops.error;
      if (ok) {
        revision = ops.data!['revision'];
        changed.clear();
      }
    });
  }

  Future<void> chooseDate(bool start) async {
    final value = await showDatePicker(
      context: context,
      initialDate: start ? from : until,
      firstDate: DateTime.parse(ops.data?['day'] ?? rosterDate(widget.day)),
      lastDate: DateTime(2100),
    );
    if (value != null && mounted) {
      setState(() {
        if (start) {
          from = value;
          if (until.isBefore(from)) until = from;
        } else {
          until = value;
        }
      });
    }
  }

  Future<void> apply() async {
    if (!editable || pendingIds.isNotEmpty) return;
    final yes = await showAppDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('선택한 기간에 배정할까요?'),
        content: Text(
          '${rosterDate(from)} ~ ${rosterDate(until)}\n기존 반복 근무의 세부 시간 조정은 다시 설정해야 해요. 승인된 OFF·대타·출퇴근·대기 신청과 별도 근무는 유지해요.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('근무표 적용'),
          ),
        ],
      ),
    );
    if (yes != true || !mounted || !editable) return;
    setState(() => saving = true);
    final ok = await ops.act('apply_crew_allocations', {
      'revision': revision,
      'from': rosterDate(from),
      'until': rosterDate(until),
    });
    if (!mounted) return;
    setState(() {
      saving = false;
      error = ok ? null : ops.error;
      if (ok) revision = ops.data!['revision'];
    });
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('선택한 기간에 적용했어요. 근무표에서 세부 시간을 조정해 주세요.')),
      );
    }
  }

  Future<void> close() async {
    if (saving) return;
    if (changed.isNotEmpty) {
      final discard = await showAppDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text('변경을 버릴까요?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('계속 편집'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(c, true),
              child: const Text('변경 버리기'),
            ),
          ],
        ),
      );
      if (discard != true || !mounted) return;
    }
    if (mounted) {
      setState(changed.clear);
      Navigator.pop(context);
    }
  }

  Widget crewChip(String id, {Json? entry}) {
    final chip = InputChip(
      label: Text(name(id)),
      selected: selectedCrew == id,
      avatar: entry == null
          ? CircleAvatar(backgroundColor: crewColor(id), radius: 5)
          : null,
      onSelected: editable
          ? (_) async {
              if (entry == null) {
                setState(() => selectedCrew = id);
                return;
              }
              final yes = await showAppDialog<bool>(
                context: context,
                builder: (c) => AlertDialog(
                  title: Text('${name(id)} 배정을 해제할까요?'),
                  content: Text(
                    '${entry['start']}–${entry['end']} · ${partLabel(ops, entry['partId'])}',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(c, false),
                      child: const Text('취소'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(c, true),
                      child: const Text('배정 해제'),
                    ),
                  ],
                ),
              );
              if (yes == true && mounted) remove(id, entry);
            }
          : null,
    );
    if (!editable) return chip;
    return LongPressDraggable<Json>(
      data: {'id': id, 'entry': ?entry},
      delay: const Duration(milliseconds: 180),
      feedback: Material(
        color: Colors.transparent,
        child: Chip(label: Text(name(id)), backgroundColor: AppColors.elevated),
      ),
      childWhenDragging: Opacity(opacity: .4, child: chip),
      child: chip,
    );
  }

  Widget cell(Json band, String part) {
    final rows = assigned(band, part), required = count(band, part);
    return DragTarget<Json>(
      onWillAcceptWithDetails: (d) =>
          editable &&
          rows.length < required &&
          canAssign(d.data['id'], band, part, d.data['entry']),
      onAcceptWithDetails: (d) =>
          assign(d.data['id'], band, part, d.data['entry']),
      builder: (context, candidates, rejected) => Container(
        key: ValueKey('allocation-$weekday-${band['id']}-$part'),
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: candidates.isEmpty
              ? AppColors.surface
              : AppColors.green.withValues(alpha: .2),
          border: Border.all(
            color: candidates.isEmpty ? AppColors.line : AppColors.green,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final row in rows) crewChip(row.id, entry: row.entry),
            for (var n = rows.length; n < required; n++)
              TextButton(
                onPressed: editable ? () => pick(band, part) : null,
                style: TextButton.styleFrom(foregroundColor: AppColors.accent),
                child: Text(candidates.isEmpty ? '미배정' : '여기에 배정'),
              ),
            if (required == 0 && rows.isEmpty)
              const Center(child: Text('—', style: AppText.caption)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rows = bands(weekday);
    final unmatched = [
      for (final id in patterns.keys)
        for (final e in entries(id))
          if (activeEntry(id, e) &&
              !rows.any((b) => parts.any((p) => matches(e, b, p['id']))))
            (id: id, entry: e),
    ];
    return PopScope(
      canPop: changed.isEmpty && !saving,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) close();
      },
      child: AppEditorScaffold(
        title: '크루별 근무 배정',
        maxWidth: 1100,
        onClose: close,
        footer: AppSheetFooter(
          children: [
            FilledButton(
              onPressed: editable && pendingIds.isNotEmpty ? save : null,
              child: Text(saving ? '저장 중…' : '기본 배정 저장'),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Text(
              '1 영업시간·인원 → 2 크루 배정 → 3 근무표 조정',
              style: AppText.caption,
            ),
            const SizedBox(height: 8),
            const Text('저장 후 기간을 정해 근무표에 적용해 주세요.', style: AppText.caption),
            if (people.isEmpty) const Information('크루를 먼저 등록해 주세요.'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [for (final p in people) crewChip(p['id'])],
            ),
            const Text('크루를 끌어 놓거나 빈 슬롯을 눌러 배정해요.', style: AppText.caption),
            Row(
              children: [
                IconButton(
                  tooltip: '이전 주',
                  onPressed: () => setState(
                    () => monday = monday.subtract(const Duration(days: 7)),
                  ),
                  icon: const Icon(Icons.chevron_left),
                ),
                Expanded(
                  child: Text(
                    '${rosterDate(monday)} 기준 주',
                    textAlign: TextAlign.center,
                    style: AppText.caption,
                  ),
                ),
                IconButton(
                  tooltip: '다음 주',
                  onPressed: () => setState(
                    () => monday = monday.add(const Duration(days: 7)),
                  ),
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
            Wrap(
              spacing: 8,
              children: [
                for (var d = 1; d <= 7; d++)
                  ChoiceChip(
                    label: Text(['월', '화', '수', '목', '금', '토', '일'][d - 1]),
                    selected: weekday == d,
                    onSelected: (_) => setState(() => weekday = d),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (rows.isEmpty)
              const Information('정기 휴무일이에요. 추가 영업일은 월간에서 지정해 주세요.')
            else
              LayoutBuilder(
                builder: (context, box) {
                  final scale = MediaQuery.textScalerOf(context).scale(13) / 13;
                  final width = (parts.length * 88.0 + 70) * scale;
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: width < box.maxWidth ? box.maxWidth : width,
                      child: Table(
                        columnWidths: {0: FixedColumnWidth(70 * scale)},
                        defaultVerticalAlignment:
                            TableCellVerticalAlignment.intrinsicHeight,
                        children: [
                          TableRow(
                            children: [
                              const Padding(
                                padding: EdgeInsets.all(8),
                                child: Text('교대', style: AppText.caption),
                              ),
                              for (final p in parts)
                                Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: Text(
                                    p['name'],
                                    textAlign: TextAlign.center,
                                    style: AppText.body,
                                  ),
                                ),
                            ],
                          ),
                          for (var i = 0; i < rows.length; i++)
                            TableRow(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: Text(
                                    '${rows[i]['custom'] == true ? rows[i]['name'] : shiftLabel(i, rows.length)}\n${rows[i]['start']}\n–${rows[i]['end']}',
                                    style: AppText.caption,
                                  ),
                                ),
                                for (final p in parts) cell(rows[i], p['id']),
                              ],
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            if (unmatched.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text('이전 설정의 배정 · 확인 필요', style: AppText.caption),
              for (final row in unmatched)
                Wrap(
                  spacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    crewChip(row.id, entry: row.entry),
                    Text(
                      '${partLabel(ops, row.entry['partId'])} ${row.entry['start']}–${row.entry['end']}',
                      style: AppText.caption,
                    ),
                  ],
                ),
            ],
            const SizedBox(height: 24),
            const Text('근무표에 적용', style: AppText.title),
            Wrap(
              spacing: 8,
              children: [
                TextButton(
                  onPressed: editable ? () => chooseDate(true) : null,
                  child: Text('시작 ${rosterDate(from)}'),
                ),
                TextButton(
                  onPressed: editable ? () => chooseDate(false) : null,
                  child: Text('종료 ${rosterDate(until)}'),
                ),
              ],
            ),
            OutlinedButton(
              onPressed: editable && pendingIds.isEmpty ? apply : null,
              child: const Text('기간 확인·근무표 적용'),
            ),
            if (error != null) Information('$error\n입력한 배정은 유지돼요.'),
          ],
        ),
      ),
    );
  }
}
