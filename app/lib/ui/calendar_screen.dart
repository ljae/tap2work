import 'package:flutter/gestures.dart';
import 'shift_change_panel.dart';
import '../domain/korean_holidays.dart';
import 'crew_pattern_screen.dart';
import 'workplace_screens.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../domain/part_schedule.dart';
import '../state/operations_controller.dart';
import '../state/schedule_controller.dart';
import 'components.dart';
import 'direct_edit.dart';
import 'crew_colors.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key, required this.operations});
  final OperationsController operations;
  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late ScheduleController model;
  bool arranging = false;
  String? arrangingActor;
  RosterSlot? selectedSlot;
  Map<String, String> holidays = {};
  final holidayYears = <int>{};
  final liveHolidayYears = <int>{};
  String? previewColumn;
  int? previewMinute, previewDuration;
  String? resizingId;
  int? resizingEnd;
  double resizeOrigin = 0;
  Json? resizePayload;
  String slotKey(RosterSlot s) =>
      '${s.date}/${s.partId}/${s.shiftId ?? s.templateId}';
  int shownEnd(RosterSlot s) =>
      resizingId == slotKey(s) ? resizingEnd ?? s.endMinute : s.endMinute;
  Future<void> loadHolidays() async {
    final bundled = await KoreanHolidays.bundled().catchError(
      (Object _) => <String, String>{},
    );
    if (!mounted) return;
    setState(() => holidays = {...bundled, ...holidays});
    for (final year in {
      model.selected.year - 1,
      model.selected.year,
      model.selected.year + 1,
    }) {
      if (!holidayYears.add(year)) continue;
      KoreanHolidays.year(year)
          .then((dates) {
            if (mounted) {
              setState(() {
                holidays.addAll(dates);
                liveHolidayYears.add(year);
              });
            }
          })
          .catchError((Object _) {});
    }
  }

  String dayNote(DateTime day) {
    final days = ops.data?['workplace']?['days'] as Map? ?? {};
    final configured = days['${day.weekday}'] as List?;
    return [
      if (holidays[rosterDate(day)] != null) holidays[rosterDate(day)]!,
      if (configured != null && configured.isEmpty) '매장 휴무',
    ].join(' · ');
  }

  Color dayColor(DateTime day) =>
      holidays.containsKey(rosterDate(day)) || day.weekday == 7
      ? AppColors.accent
      : day.weekday == 6
      ? AppColors.blue
      : AppColors.ink;

  bool get editMode =>
      arranging && arrangingActor == ops.actorId && model.editable;
  void enterEdit(RosterSlot slot) => setState(() {
    arranging = true;
    arrangingActor = ops.actorId;
    selectedSlot = slot;
  });
  Json slotInput(RosterSlot slot) => {
    'date': slot.date,
    'partId': slot.partId,
    'start': slot.start,
    'end': slot.end,
    if (slot.shiftId != null) ...{
      'id': slot.shiftId,
      'tapperId': slot.crewId,
    } else
      'templateId': slot.templateId,
  };
  Future<void> renameSlot(RosterSlot slot) async {
    final revision = ops.data?['revision'], actor = ops.actorId;
    final name = await directEditName(context, slot.name);
    if (name == null || !mounted || actor != ops.actorId || !model.editable) {
      return;
    }
    final ok = await ops
        .act(slot.shiftId == null ? 'save_roster_slot' : 'save_staff_shift', {
          ...slotInput(slot),
          slot.shiftId == null ? 'name' : 'label': name,
          'revision': revision,
        });
    if (mounted) {
      if (ok) setState(() => selectedSlot = null);
      notice(ok ? '이름을 변경했어요.' : ops.error ?? '저장하지 못했어요.');
    }
  }

  void notice(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  Future<void> deleteSlot(RosterSlot slot) async {
    final revision = ops.data?['revision'], actor = ops.actorId;
    final yes = await showAppDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('근무 삭제'),
        content: Text(
          slot.shiftId == null
              ? '이 날짜의 필요 슬롯만 삭제해요. 기본 영업시간은 유지됩니다.'
              : '선택한 근무 배정을 해제해요. 출퇴근 기록은 유지됩니다.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
    if (yes != true || !mounted || actor != ops.actorId || !model.editable) {
      return;
    }
    final ok = await ops.act(
      slot.shiftId == null ? 'delete_roster_slot' : 'delete_staff_shift',
      {...slotInput(slot), 'revision': revision},
    );
    if (mounted) {
      if (ok) setState(() => selectedSlot = null);
      notice(ok ? '근무표에 반영했어요.' : ops.error ?? '삭제하지 못했어요.');
    }
  }

  Future<void> dropSlot(
    Json payload,
    DateTime day,
    WorkPart part,
    int minute,
  ) async {
    if (!editMode || payload['actor'] != ops.actorId) return;
    final duration = payload['duration'] as int;
    final ok = await ops
        .act(payload['id'] == null ? 'save_roster_slot' : 'save_staff_shift', {
          ...payload,
          'date': rosterDate(day),
          'partId': part.id,
          'start': rosterClock(minute),
          'end': rosterClock(minute + duration),
        });
    if (mounted) {
      if (ok) setState(() => selectedSlot = null);
      notice(ok ? '근무를 옮겼어요.' : ops.error ?? '이동하지 못했어요.');
    }
  }

  bool ownSlot(RosterSlot slot) =>
      !ops.readOnly &&
      !ops.busy &&
      ops
          .rows('tappers')
          .any((p) => p['id'] == slot.crewId && p['actorId'] == ops.actorId);
  String requestLabel(RosterSlot slot) {
    final current = ops
        .rows('staffShifts')
        .where((s) => s['id'] == slot.shiftId)
        .firstOrNull;
    final requests = ops.rows('shiftChangeRequests');
    if (requests.any(
      (r) => r['shiftId'] == slot.shiftId && r['status'] == 'pending',
    )) {
      return ' · 변경 신청 중';
    }
    if (current?['replacementForRequestId'] != null) return ' · 대체 배정';
    final approval = requests
        .where(
          (r) =>
              r['id'] == current?['approvedRequestId'] &&
              r['status'] == 'approved',
        )
        .firstOrNull;
    if (approval != null) return ' · 승인 반영';
    return '';
  }

  Widget slotFrame(RosterSlot slot, Widget child) {
    final frame = DirectEditFrame(
      enabled: model.editable,
      active: editMode,
      onEnter: () => enterEdit(slot),
      controls: false,
      child: editMode
          ? GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => setState(() => selectedSlot = slot),
              child: IgnorePointer(child: child),
            )
          : child,
    );
    if (!editMode) return frame;
    return Stack(
      fit: StackFit.expand,
      children: [
        Draggable<Json>(
          dragAnchorStrategy: pointerDragAnchorStrategy,
          onDragEnd: (_) => setState(() {
            previewColumn = null;
            previewMinute = null;
          }),
          data: {
            ...slotInput(slot),
            'duration': slot.endMinute - slot.startMinute,
            'revision': ops.data?['revision'],
            'actor': ops.actorId,
          },
          feedback: Material(
            color: AppColors.surface,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text(slot.name),
            ),
          ),
          childWhenDragging: Opacity(opacity: .3, child: frame),
          child: frame,
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: 32,
          child: Semantics(
            label: '종료 시간 높이 조절',
            button: true,
            child: MouseRegion(
              cursor: SystemMouseCursors.resizeUpDown,
              child: GestureDetector(
                dragStartBehavior: DragStartBehavior.down,
                key: ValueKey(
                  'resize-${slot.shiftId ?? slot.templateId}-${slot.date}',
                ),
                behavior: HitTestBehavior.opaque,
                onVerticalDragStart: (d) {
                  resizeOrigin = d.globalPosition.dy;
                  resizePayload = {
                    ...slotInput(slot),
                    'actor': ops.actorId,
                    'revision': ops.data?['revision'],
                  };
                  setState(() {
                    resizingId = slotKey(slot);
                    resizingEnd = slot.endMinute;
                  });
                },
                onVerticalDragUpdate: (d) => setState(() {
                  resizingEnd =
                      (slot.endMinute +
                              ((d.globalPosition.dy - resizeOrigin) /
                                          (48 / 30) /
                                          30)
                                      .round() *
                                  30)
                          .clamp(
                            slot.startMinute + 30,
                            slot.startMinute + 1410,
                          );
                }),
                onVerticalDragCancel: () => setState(() {
                  resizingId = null;
                  resizingEnd = null;
                }),
                onVerticalDragEnd: (_) async {
                  final end = resizingEnd, payload = resizePayload;
                  setState(() {
                    resizingId = null;
                    resizingEnd = null;
                  });
                  if (end == null ||
                      payload == null ||
                      !editMode ||
                      payload['actor'] != ops.actorId ||
                      end == slot.endMinute) {
                    return;
                  }
                  final ok = await ops.act(
                    slot.shiftId == null
                        ? 'save_roster_slot'
                        : 'save_staff_shift',
                    {...payload, 'end': rosterClock(end)},
                  );
                  if (mounted) {
                    notice(ok ? '시간을 조정했어요.' : ops.error ?? '저장하지 못했어요.');
                  }
                },
                child: Container(
                  alignment: Alignment.bottomCenter,
                  decoration: BoxDecoration(
                    color: AppColors.green.withValues(alpha: .18),
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(12),
                    ),
                  ),
                  child: const Icon(Icons.drag_handle, size: 24),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  final horizontal = ScrollController();
  final vertical = ScrollController();
  static const weekdays = ['월', '화', '수', '목', '금', '토', '일'];
  @override
  void initState() {
    super.initState();
    model = ScheduleController(widget.operations);
    loadHolidays();
  }

  @override
  void didUpdateWidget(covariant CalendarScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.operations != widget.operations) {
      model.dispose();
      model = ScheduleController(widget.operations);
      arranging = false;
      selectedSlot = null;
    }
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
    final actor = ops.actorId;
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
                ],
              ),
            ),
          ),
          actions: [
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
    if (result == null || !mounted || actor != ops.actorId || !model.editable) {
      return;
    }
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
          for (var w = 0; w < 7; w++)
            SizedBox(
              width: box.maxWidth / 7,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  weekdays[w],
                  textAlign: TextAlign.center,
                  style: AppText.caption.copyWith(
                    color: w == 6
                        ? AppColors.accent
                        : w == 5
                        ? AppColors.blue
                        : AppColors.ink,
                  ),
                ),
              ),
            ),
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
                      132 * (MediaQuery.textScalerOf(context).scale(14) / 14),
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
                                  ? dayColor(day)
                                  : AppColors.muted,
                            ),
                          ),
                          if (dayNote(day).isNotEmpty)
                            Expanded(
                              child: Tooltip(
                                message: dayNote(day),
                                child: Text(
                                  dayNote(day),
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppText.caption.copyWith(
                                    color: dayColor(day),
                                  ),
                                ),
                              ),
                            ),
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
        : ((all.map(shownEnd).reduce((a, b) => a > b ? a : b) + 59) ~/ 60 * 60);
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
    final headerHeight = 100.0 * textScale.clamp(1, 1.6);
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
                                        '${day.month}/${day.day} ${weekdays[day.weekday - 1]}${dayNote(day).isEmpty ? '' : '\n${dayNote(day)}'}',
                                        style: AppText.body.copyWith(
                                          fontWeight: FontWeight.w700,
                                          color: dayColor(day),
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
              '설정한 영업시간이 없어요. 우리매장 → 영업시간 설정에서 요일별 시간을 설정해 주세요.',
            ),
          ),
        const SizedBox(height: 12),
        const Text(
          '길게 눌러 편집해요. 아래 손잡이로 종료 시간을, 드래그로 위치를 30분 단위로 조정해요.',
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
    return Builder(
      builder: (columnContext) => DragTarget<Json>(
        onWillAcceptWithDetails: (d) =>
            editMode &&
            d.data['actor'] == ops.actorId &&
            (d.data['id'] != null ||
                (d.data['date'] == rosterDate(day) &&
                    d.data['partId'] == part.id)),
        onMove: (d) {
          final box = columnContext.findRenderObject() as RenderBox;
          final minute =
              (from +
                      (box.globalToLocal(d.offset).dy / scale / 30).floor() *
                          30)
                  .clamp(0, 1410);
          if (previewColumn != '${rosterDate(day)}/${part.id}' ||
              previewMinute != minute) {
            setState(() {
              previewColumn = '${rosterDate(day)}/${part.id}';
              previewMinute = minute;
              previewDuration = d.data['duration'] as int;
            });
          }
        },
        onLeave: (_) {
          if (previewColumn == '${rosterDate(day)}/${part.id}') {
            setState(() => previewColumn = null);
          }
        },
        onAcceptWithDetails: (d) {
          final box = columnContext.findRenderObject() as RenderBox;
          final minute =
              (from +
                      (box.globalToLocal(d.offset).dy / scale / 30).floor() *
                          30)
                  .clamp(0, 1410);
          dropSlot(d.data, day, part, minute);
        },
        builder: (context, candidates, rejected) => SizedBox(
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
                    key: ValueKey(
                      'roster-drop-${rosterDate(day)}-${part.id}-$m',
                    ),
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
                  height:
                      (shownEnd(slots[i]) - slots[i].startMinute) * scale - 4,
                  child: slotFrame(
                    slots[i],
                    Semantics(
                      button: true,
                      label:
                          '${slots[i].date} ${part.name} ${slots[i].name} ${slots[i].start} ${rosterClock(shownEnd(slots[i]))}',
                      child: Material(
                        color: slots[i].crewId == null
                            ? AppColors.surface
                            : crewColor(
                                slots[i].crewId!,
                              ).withValues(alpha: .12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: slots[i].crewId == null
                                ? AppColors.line
                                : crewColor(slots[i].crewId!),
                          ),
                        ),
                        child: InkWell(
                          key: ValueKey(
                            'roster-${slots[i].date}-${slots[i].partId}-${slots[i].shiftId ?? slots[i].templateId}',
                          ),
                          borderRadius: BorderRadius.circular(12),
                          onTap: model.editable
                              ? () {
                                  if (editMode) {
                                    setState(() => selectedSlot = slots[i]);
                                  } else {
                                    edit(slots[i]);
                                  }
                                }
                              : ownSlot(slots[i])
                              ? () => requestShiftChange(
                                  context,
                                  ops,
                                  slots[i].shiftId!,
                                )
                              : null,
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
                                    '${slots[i].start}\n${slots[i].overnight ? '다음 날 ' : ''}${rosterClock(shownEnd(slots[i]))}',
                                    style: AppText.caption,
                                  ),
                                  Text(
                                    slots[i].crewId == null
                                        ? '미배정${slots[i].adjusted ? ' · 조정됨' : ''}'
                                        : '${slots[i].adjusted ? '배정 · 미세조정' : '배정'}${requestLabel(slots[i])}',
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
                ),
              if (previewColumn == '${rosterDate(day)}/${part.id}' &&
                  previewMinute != null)
                Positioned(
                  top: (previewMinute! - from) * scale,
                  left: 3,
                  right: 3,
                  height: previewDuration! * scale,
                  child: IgnorePointer(
                    child: Container(
                      key: const ValueKey('roster-drop-preview'),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.green.withValues(alpha: .28),
                        border: Border.all(color: AppColors.green, width: 2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${rosterClock(previewMinute!)}–${previewMinute! + previewDuration! >= 1440 ? '다음 날 ' : ''}${rosterClock(previewMinute! + previewDuration!)}\n여기에 배정',
                        style: AppText.body,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: model,
    builder: (context, _) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ShiftChangePanel(ops: ops),
        if (!ops.isLeader)
          const Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: Text(
              '내 근무를 눌러 휴무·단축을 신청해요. 승인 전에는 원래 근무가 유지돼요.',
              style: AppText.caption,
            ),
          ),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final scale = MediaQuery.textScalerOf(context).scale(13) / 13;
              final paired =
                  model.editable && constraints.maxWidth >= 360 * scale;
              final width = paired
                  ? (constraints.maxWidth - 8) / 2
                  : constraints.maxWidth;
              final style = ButtonStyle(
                minimumSize: const WidgetStatePropertyAll(Size(48, 56)),
                padding: const WidgetStatePropertyAll(
                  EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                textStyle: WidgetStatePropertyAll(
                  AppText.caption.copyWith(fontWeight: FontWeight.w700),
                ),
                iconSize: const WidgetStatePropertyAll(20),
                alignment: Alignment.center,
              );
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (model.editable)
                    SizedBox(
                      width: width,
                      child: PressBounce(
                        child: FilledButton.icon(
                          key: const ValueKey('calendar-crew-pattern-button'),
                          style: style,
                          onPressed: () => showAppFormSheet(
                            context: context,
                            builder: (_) => CrewPatternScreen(
                              ops: ops,
                              day: model.selected,
                            ),
                          ),
                          icon: const Icon(Icons.people_outline),
                          label: const Text(
                            '크루별 근무 배정',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                  SizedBox(
                    width: width,
                    child: PressBounce(
                      child: OutlinedButton.icon(
                        key: const ValueKey('calendar-hours-button'),
                        style: style,
                        onPressed: () => openWorkplaceHours(context, ops),
                        icon: const Icon(Icons.schedule),
                        label: const Text(
                          '영업시간·인원',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child:
                  ops.isLeader &&
                      ops.data?['canEditSchedule'] != false &&
                      !ops.readOnly
                  ? DirectEditBar(
                      active: editMode,
                      onDone: () => setState(() {
                        arranging = false;
                        selectedSlot = null;
                      }),
                    )
                  : const Text('대한민국 달력', style: AppText.caption),
            ),
            IconButton(
              tooltip: '공휴일 출처·상태',
              icon: const Icon(Icons.info_outline, size: 20),
              onPressed: () => showAppDialog(
                context: context,
                builder: (c) => AlertDialog(
                  title: const Text('대한민국 공휴일'),
                  content: Text(
                    '${liveHolidayYears.contains(model.selected.year) ? '최신 달력을 확인했어요.' : '저장된 달력 (2026.09.29)을 표시하고 있어요.'}\n출처: holidays-kr (월력요항 가공 자료)\n공휴일과 매장 휴무는 별도예요.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(c),
                      child: const Text('닫기'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        if (!holidays.keys.any((d) => d.startsWith('${model.selected.year}-')))
          const Text('이 연도의 공휴일 정보를 불러오지 못했어요.', style: AppText.caption),
        if (editMode && selectedSlot != null)
          Wrap(
            spacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(selectedSlot!.name, style: AppText.caption),
              IconButton(
                tooltip: '시간·크루 변경',
                onPressed: () => edit(selectedSlot!),
                icon: const Icon(Icons.tune),
              ),
              IconButton(
                tooltip: '이름 변경',
                onPressed: () => renameSlot(selectedSlot!),
                icon: const Icon(Icons.edit_outlined),
              ),
              IconButton(
                tooltip: '삭제',
                onPressed: () => deleteSlot(selectedSlot!),
                icon: const Icon(Icons.delete_outline),
                color: AppColors.accent,
              ),
            ],
          ),
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
              onPressed: () {
                model.move(-1);
                loadHolidays();
              },
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
              onPressed: () {
                model.move(1);
                loadHolidays();
              },
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
