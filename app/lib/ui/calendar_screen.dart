import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../domain/part_schedule.dart';
import '../state/operations_controller.dart';
import '../state/schedule_controller.dart';
import 'components.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key, required this.operations});
  final OperationsController operations;
  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late ScheduleController model;
  final horizontal = ScrollController();
  final vertical = ScrollController();
  static const weekdays = ['월', '화', '수', '목', '금', '토', '일'];
  @override
  void initState() {
    super.initState();
    model = ScheduleController(widget.operations);
  }

  @override
  void dispose() {
    model.dispose();
    horizontal.dispose();
    vertical.dispose();
    super.dispose();
  }

  OperationsController get ops => widget.operations;

  Future<void> edit(RosterSlot slot) async {
    if (!model.editable) return;
    final revision = ops.data!['revision'];
    var start = slot.start, end = slot.end;
    String? crewId = slot.crewId;
    var repeat = 1;
    final days = <int>{DateTime.parse(slot.date).weekday};
    final crew = ops
        .rows('tappers')
        .where(
          (p) =>
              p['active'] != false &&
              ((p['workProfile']?['partIds'] as List? ?? []).isEmpty ||
                  (p['workProfile']['partIds'] as List).contains(slot.partId)),
        )
        .toList();
    final result = await showAppFormSheet<Json>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, update) => AppSheetPanel(
          title: Text(
            '${slot.date} · ${model.parts.where((p) => p.id == slot.partId).first.name}',
          ),
          content: SizedBox(
            width: 440,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    slot.shiftId == null
                        ? '슬롯 시간과 크루 배정'
                        : '${slot.name} 근무 조정',
                    style: AppText.title,
                  ),
                  const SizedBox(height: 16),
                  AppPicker<String>(
                    label: '시작 시간',
                    value: start,
                    items: [
                      for (var m = 0; m < 1440; m += 30)
                        DropdownMenuItem(
                          value: rosterClock(m),
                          child: Text(rosterClock(m)),
                        ),
                    ],
                    onChanged: (v) => update(() => start = v!),
                  ),
                  const SizedBox(height: 16),
                  AppPicker<String>(
                    label: '종료 시간',
                    value: end,
                    items: [
                      for (var m = 0; m < 1440; m += 30)
                        DropdownMenuItem(
                          value: rosterClock(m),
                          child: Text(rosterClock(m)),
                        ),
                    ],
                    onChanged: (v) => update(() => end = v!),
                  ),
                  if (end.compareTo(start) < 0)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text('종료는 다음 날이에요.', style: AppText.caption),
                    ),
                  const SizedBox(height: 16),
                  AppPicker<String>(
                    label: '담당 크루',
                    value: crewId,
                    items: [
                      if (slot.shiftId == null)
                        const DropdownMenuItem(
                          value: null,
                          child: Text('미배정 · 시간만 저장'),
                        ),
                      for (final person in crew)
                        DropdownMenuItem(
                          value: person['id'] as String,
                          child: Text(person['nickname']),
                        ),
                    ],
                    onChanged: (v) => update(() => crewId = v),
                  ),
                  if (crew.isEmpty)
                    const Text('이 파트에 배정 가능한 크루가 없어요.', style: AppText.caption),
                  if (slot.shiftId == null && crewId != null) ...[
                    const SizedBox(height: 16),
                    AppChoiceGroup<int>(
                      values: const [1, 28, 84],
                      selected: repeat,
                      labelOf: (v) => v == 1 ? '이번 날짜만' : '${v ~/ 7}주 반복',
                      onSelected: (v) => update(() => repeat = v),
                    ),
                    if (repeat > 1)
                      Wrap(
                        spacing: 8,
                        children: [
                          for (var d = 1; d <= 7; d++)
                            FilterChip(
                              chipAnimationStyle: AppMotion.chipStyle(context),
                              label: Text(weekdays[d - 1]),
                              selected: days.contains(d),
                              onSelected: (v) => update(() {
                                if (v) {
                                  days.add(d);
                                } else {
                                  days.remove(d);
                                }
                              }),
                            ),
                        ],
                      ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            if (slot.shiftId != null)
              TextButton(
                onPressed: () => Navigator.pop(context, {
                  'action': 'delete_staff_shift',
                  'id': slot.shiftId,
                }),
                child: const Text('배정 해제'),
              ),
            if (slot.adjusted)
              TextButton(
                onPressed: () => Navigator.pop(context, {
                  'action': 'reset_roster_slot',
                  'templateId': slot.templateId,
                  'date': slot.date,
                  'partId': slot.partId,
                }),
                child: const Text('영업시간으로 되돌리기'),
              ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: start == end || (repeat > 1 && days.isEmpty)
                  ? null
                  : () => Navigator.pop(context, {
                      'action': crewId == null
                          ? 'save_roster_slot'
                          : repeat > 1
                          ? 'save_shift_pattern'
                          : 'save_staff_shift',
                      'date': slot.date,
                      'partId': slot.partId,
                      'start': start,
                      'end': end,
                      if (crewId == null) 'templateId': slot.templateId,
                      if (crewId != null) ...{
                        'tapperId': crewId,
                        if (slot.shiftId != null) 'id': slot.shiftId,
                        'repeatDays': repeat,
                        'weekdays': days.toList(),
                      },
                    }),
              child: const Text('저장'),
            ),
          ],
        ),
      ),
    );
    if (result == null || !mounted) return;
    final action = result.remove('action') as String;
    final ok = await ops.act(action, {...result, 'revision': revision});
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ok ? '근무표에 반영했어요.' : ops.error ?? '저장하지 못했어요.')),
      );
    }
  }

  Widget month() {
    final first = DateTime(model.selected.year, model.selected.month, 1);
    final origin = first.subtract(Duration(days: first.weekday - 1));
    return LayoutBuilder(
      builder: (context, box) => Wrap(
        children: [
          for (var n = 0; n < 42; n++)
            Builder(
              builder: (context) {
                final day = origin.add(Duration(days: n));
                final assigned = model
                    .slots(day)
                    .where((s) => s.crewId != null)
                    .length;
                return SizedBox(
                  width: box.maxWidth / 7,
                  height:
                      90 * (MediaQuery.textScalerOf(context).scale(14) / 14),
                  child: InkWell(
                    onTap: () => model.selectDay(day),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.line),
                      ),
                      child: Column(
                        children: [
                          Text(
                            '${day.day}',
                            style: TextStyle(
                              color: day.month == first.month
                                  ? AppColors.ink
                                  : AppColors.muted,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '$assigned',
                            style: AppText.caption,
                            semanticsLabel: '배정 $assigned명',
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget week() {
    final parts = model.visibleParts;
    if (parts.isEmpty) return const Information('우리매장 → 파트 관리에서 파트를 추가해 주세요.');
    final days = [
      for (var n = 0; n < 7; n++) model.monday.add(Duration(days: n)),
    ];
    final coverage = rosterCoverage(ops.data ?? {}, model.monday, parts);
    final all = [for (final day in days) ...model.slots(day)];
    final from = all.isEmpty
        ? 9 * 60
        : all.map((s) => s.startMinute).reduce((a, b) => a < b ? a : b) ~/
              60 *
              60;
    final until = all.isEmpty
        ? 22 * 60
        : ((all.map((s) => s.endMinute).reduce((a, b) => a > b ? a : b) + 59) ~/
              60 *
              60);
    // 30 minutes is a 48px touch target; never compress the day/part columns.
    const scale = 48.0 / 30;
    final gridHeight = (until - from) * scale;
    final textScale = MediaQuery.textScalerOf(context).scale(14) / 14;
    final columnWidth = 148.0 * textScale.clamp(1, 1.6);
    final partWidths = <String, double>{};
    for (final part in parts) {
      var maximum = 1;
      for (final day in days) {
        final slots =
            all
                .where((s) => s.partId == part.id && s.date == rosterDate(day))
                .toList()
              ..sort((a, b) => a.startMinute.compareTo(b.startMinute));
        final ends = <int>[];
        for (final slot in slots) {
          final lane = ends.indexWhere((end) => end <= slot.startMinute);
          if (lane < 0) {
            ends.add(slot.endMinute);
          } else {
            ends[lane] = slot.endMinute;
          }
        }
        if (ends.length > maximum) maximum = ends.length;
      }
      partWidths[part.id] = columnWidth * maximum;
    }
    final headerHeight = 88.0 * textScale.clamp(1, 1.6);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('주간 배정 현황', style: AppText.body),
        Text(
          '충족 ${coverage.needed == 0 ? 0 : (coverage.covered * 100 / coverage.needed).round()}% · 미배정 ${((coverage.needed - coverage.covered) / 60).toStringAsFixed(1)}시간',
          style: AppText.caption,
        ),
        const SizedBox(height: 12),
        const SizedBox(height: 12),
        SizedBox(
          height: 640,
          child: Scrollbar(
            controller: vertical,
            thumbVisibility: true,
            child: SingleChildScrollView(
              controller: vertical,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    key: const ValueKey('roster-time-axis'),
                    width: 52,
                    child: Column(
                      children: [
                        SizedBox(
                          height: headerHeight,
                          child: const Center(
                            child: Text('시간', style: AppText.caption),
                          ),
                        ),
                        SizedBox(
                          height: gridHeight + 24,
                          child: Stack(
                            children: [
                              for (var m = from; m <= until; m += 60)
                                Positioned(
                                  top: (m - from) * scale,
                                  left: 0,
                                  right: 0,
                                  child: Text(
                                    '${m >= 1440 ? '+' : ''}${rosterClock(m)}',
                                    style: AppText.caption.copyWith(
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Scrollbar(
                      controller: horizontal,
                      thumbVisibility: true,
                      notificationPredicate: (n) =>
                          n.metrics.axis == Axis.horizontal,
                      child: SingleChildScrollView(
                        controller: horizontal,
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (final day in days)
                              SizedBox(
                                width: partWidths.values.fold<double>(
                                  0,
                                  (a, b) => a + b,
                                ),
                                child: Column(
                                  children: [
                                    Container(
                                      height: headerHeight / 2,
                                      alignment: Alignment.centerLeft,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.surface,
                                        border: Border.all(
                                          color: AppColors.line,
                                        ),
                                      ),
                                      child: Text(
                                        '${day.month}/${day.day} ${weekdays[day.weekday - 1]}',
                                        style: AppText.body.copyWith(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        for (final part in parts)
                                          SizedBox(
                                            width: partWidths[part.id]!,
                                            child: Column(
                                              children: [
                                                Container(
                                                  height: headerHeight / 2,
                                                  alignment: Alignment.center,
                                                  decoration: BoxDecoration(
                                                    color: AppColors.surface,
                                                    border: Border.all(
                                                      color: AppColors.line,
                                                    ),
                                                  ),
                                                  child: Text(
                                                    '${part.name}${part.hidden ? ' · 숨김' : ''}',
                                                    style: AppText.caption,
                                                  ),
                                                ),
                                                _column(
                                                  day,
                                                  part,
                                                  all
                                                      .where(
                                                        (s) =>
                                                            s.date ==
                                                                rosterDate(
                                                                  day,
                                                                ) &&
                                                            s.partId == part.id,
                                                      )
                                                      .toList(),
                                                  from,
                                                  until,
                                                  scale,
                                                  partWidths[part.id]!,
                                                ),
                                              ],
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
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
        ),
        if (all.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 16),
            child: Information(
              '설정한 영업시간이 없어요. 우리매장 → 영업 시간대에서 요일별 시간을 설정해 주세요.',
            ),
          ),
        const SizedBox(height: 12),
        const Text(
          '빈 슬롯을 누르면 시간을 조정하거나 크루를 배정해요. 배정된 근무는 영업시간을 바꿔도 유지돼요.',
          style: AppText.caption,
        ),
      ],
    );
  }

  Widget _column(
    DateTime day,
    WorkPart part,
    List<RosterSlot> slots,
    int from,
    int until,
    double scale,
    double width,
  ) {
    // Allocate overlapping assignments side-by-side rather than covering names.
    slots.sort((a, b) => a.startMinute.compareTo(b.startMinute));
    final ends = <int>[];
    final positions = <int>[];
    for (final slot in slots) {
      var lane = ends.indexWhere((e) => e <= slot.startMinute);
      if (lane < 0) {
        lane = ends.length;
        ends.add(slot.endMinute);
      } else {
        ends[lane] = slot.endMinute;
      }
      positions.add(lane);
    }
    final lanes = ends.isEmpty ? 1 : ends.length;
    final laneWidth = width / lanes;
    return SizedBox(
      height: (until - from) * scale + 24,
      child: Stack(
        children: [
          for (var m = from; m < until; m += 30)
            Positioned(
              top: (m - from) * scale,
              left: 0,
              right: 0,
              height: 48,
              child: Container(
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: AppColors.line),
                    right: BorderSide(color: AppColors.line),
                  ),
                ),
              ),
            ),
          for (var i = 0; i < slots.length; i++)
            Positioned(
              top: (slots[i].startMinute - from) * scale + 2,
              left: positions[i] * laneWidth + 3,
              width: laneWidth - 6,
              height: (slots[i].endMinute - slots[i].startMinute) * scale - 4,
              child: Semantics(
                button: true,
                label:
                    '${slots[i].date} ${part.name} ${slots[i].name} ${slots[i].start} ${slots[i].end}',
                child: Material(
                  color: slots[i].crewId == null
                      ? AppColors.surface
                      : AppColors.lime,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: slots[i].crewId == null
                          ? AppColors.line
                          : AppColors.green,
                    ),
                  ),
                  child: InkWell(
                    key: ValueKey(
                      'roster-${slots[i].date}-${slots[i].partId}-${slots[i].shiftId ?? slots[i].templateId}',
                    ),
                    borderRadius: BorderRadius.circular(12),
                    onTap: model.editable ? () => edit(slots[i]) : null,
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              slots[i].name,
                              style: AppText.body.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              '${slots[i].start}\n${slots[i].overnight ? '다음 날 ' : ''}${slots[i].end}',
                              style: AppText.caption,
                            ),
                            Text(
                              slots[i].crewId == null
                                  ? '미배정${slots[i].adjusted ? ' · 조정됨' : ''}'
                                  : '배정',
                              style: AppText.caption.copyWith(
                                color: AppColors.green,
                              ),
                            ),
                          ],
                        ),
                      ),
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
    listenable: model,
    builder: (context, _) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(child: Text('보기', style: AppText.caption)),
            AppSegmented<bool>(
              segments: const [
                ButtonSegment(value: false, label: Text('주간')),
                ButtonSegment(value: true, label: Text('월간')),
              ],
              selected: {model.month},
              onSelectionChanged: (v) => model.setMonth(v.first),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            IconButton(
              tooltip: '이전',
              onPressed: () => model.move(-1),
              icon: const Icon(CupertinoIcons.chevron_left),
            ),
            Expanded(
              child: Text(
                model.month
                    ? '${model.selected.year}년 ${model.selected.month}월'
                    : '${rosterDate(model.monday)} ~ ${rosterDate(model.monday.add(const Duration(days: 6)))}',
                textAlign: TextAlign.center,
                style: AppText.caption,
              ),
            ),
            IconButton(
              tooltip: '다음',
              onPressed: () => model.move(1),
              icon: const Icon(CupertinoIcons.chevron_right),
            ),
            TextButton(
              onPressed: () => model.selectDay(
                DateTime.tryParse(ops.data?['day'] ?? '') ?? DateTime.now(),
              ),
              child: const Text('오늘'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            spacing: 8,
            children: [
              ChoiceChip(
                chipAnimationStyle: AppMotion.chipStyle(context),
                label: const Text('전체 파트'),
                selected: model.partId == null,
                onSelected: (_) => model.selectPart(null),
              ),
              for (final part in model.parts)
                ChoiceChip(
                  chipAnimationStyle: AppMotion.chipStyle(context),
                  label: Text(part.name),
                  selected: model.partId == part.id,
                  onSelected: (_) => model.selectPart(part.id),
                ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        if (model.month) month() else week(),
      ],
    ),
  );
}
