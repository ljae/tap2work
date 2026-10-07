import 'time_wheel.dart';
import '../domain/schedule_layout.dart';
import '../domain/attendance_history.dart';
import 'package:flutter/gestures.dart';
import 'shift_change_panel.dart';
import '../domain/korean_holidays.dart';
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
  const CalendarScreen({
    super.key,
    required this.operations,
    this.scrollable = false,
  });
  final OperationsController operations;
  final bool scrollable;
  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late ScheduleController model;
  bool arranging = false;
  bool fullDay = false;
  String? arrangingActor;
  RosterSlot? selectedSlot;
  Map<String, String> holidays = {};
  final holidayYears = <int>{};
  final liveHolidayYears = <int>{};
  String? previewColumn;
  int? previewMinute, previewDuration;
  String? previewShiftId;
  RosterSlot? pendingMove;
  String? pendingActor;
  Object? pendingWorkspace;
  String? resizingId;
  int? resizingEnd;
  double resizeOrigin = 0;
  Json? resizePayload;
  Json? draftPayload;
  Object? editRevision;
  Object? arrangingWorkspace;
  bool draftFailed = false;
  final editRegion = Object();
  bool savingDraft = false;

  bool selected(RosterSlot slot) =>
      selectedSlot != null &&
      slot.shiftId == selectedSlot!.shiftId &&
      slot.templateId == selectedSlot!.templateId;

  Future<bool> finishEdit() async {
    if (savingDraft) return false;
    final payload = draftPayload;
    if (payload == null) {
      setState(() {
        arranging = false;
        selectedSlot = null;
      });
      return true;
    }
    if (pendingActor != ops.actorId ||
        pendingWorkspace != ops.data?['workspaceId']) {
      return false;
    }
    savingDraft = true;
    final savingOperations = ops;
    final savingActor = ops.actorId;
    final savingWorkspace = ops.data?['workspaceId'];
    final ok = await savingOperations.act(
      payload['id'] == null ? 'save_roster_slot' : 'save_staff_shift',
      payload,
    );
    if (!mounted ||
        ops != savingOperations ||
        ops.actorId != savingActor ||
        ops.data?['workspaceId'] != savingWorkspace) {
      return ok;
    }
    setState(() {
      savingDraft = false;
      draftFailed = !ok;
      if (ok) {
        pendingMove = null;
        draftPayload = null;
        arranging = false;
        selectedSlot = null;
      }
    });
    notice(ok ? '근무표에 저장했어요.' : ops.error ?? '저장하지 못했어요. 다시 시도해 주세요.');
    return ok;
  }

  void stageSlot(RosterSlot slot, Json payload) {
    setState(() {
      pendingMove = slot;
      selectedSlot = slot;
      pendingActor = ops.actorId;
      pendingWorkspace = ops.data?['workspaceId'];
      draftPayload = {...payload, 'revision': editRevision};
      draftFailed = false;
      resizingId = null;
      resizingEnd = null;
    });
  }

  Widget editTapRegion(Widget child, {bool enabled = true}) => TapRegion(
    groupId: editRegion,
    enabled: enabled,
    consumeOutsideTaps: true,
    onTapOutside: (_) {
      if (arranging && !savingDraft) finishEdit();
    },
    child: child,
  );
  String slotKey(RosterSlot s) =>
      '${s.date}/${s.partId}/${s.shiftId ?? s.templateId}/${s.start}';
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

  bool isClosedDay(DateTime day) {
    final exception =
        ops.data?['workplace']?['dateOverrides']?[rosterDate(day)];
    if (exception?['closed'] != null) return exception['closed'] == true;
    final configured =
        ops.data?['workplace']?['days']?['${day.weekday}'] as List?;
    return configured != null && configured.isEmpty;
  }

  String dayNote(DateTime day) {
    final days = ops.data?['workplace']?['days'] as Map? ?? {};
    final configured = days['${day.weekday}'] as List?;
    final exception =
        ops.data?['workplace']?['dateOverrides']?[rosterDate(day)];
    return [
      if (holidays[rosterDate(day)] != null) holidays[rosterDate(day)]!,
      if (exception?['closed'] == true)
        '추가 휴무'
      else if (exception?['closed'] == false)
        '추가 영업'
      else if (configured != null && configured.isEmpty)
        '휴무',
    ].join(' · ');
  }

  Color dayColor(DateTime day) =>
      holidays.containsKey(rosterDate(day)) || day.weekday == 7
      ? AppColors.accent
      : day.weekday == 6
      ? AppColors.blue
      : AppColors.ink;

  bool get editMode =>
      arranging &&
      arrangingActor == ops.actorId &&
      arrangingWorkspace == ops.data?['workspaceId'] &&
      model.editable;
  void enterEdit(RosterSlot slot) {
    if (editMode) return;
    setState(() {
      arranging = true;
      arrangingActor = ops.actorId;
      selectedSlot = slot;
      editRevision = ops.data?['revision'];
      arrangingWorkspace = ops.data?['workspaceId'];
      draftFailed = false;
    });
  }

  Json slotInput(RosterSlot slot) => {
    'date': slot.date,
    if (slot.shiftId != null) 'dateIsBusinessDay': true,
    'partId': slot.partId,
    'start': slot.start,
    'end': slot.end,
    if (slot.shiftId != null) ...{
      'scheduleDate': slot.date,
      'dayOffset': slot.dayOffset,
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

  List<RosterSlot> displayedSlots(DateTime day) {
    final slots = model.slots(day);
    final pending = pendingMove;
    if (pending == null ||
        pendingActor != ops.actorId ||
        pendingWorkspace != ops.data?['workspaceId']) {
      return slots;
    }
    return [
      for (final slot in slots)
        if (slot.shiftId != pending.shiftId)
          slot
        else if (pending.date == rosterDate(day))
          pending,
      if (pending.date == rosterDate(day) &&
          !slots.any((s) => s.shiftId == pending.shiftId))
        pending,
    ];
  }

  Future<void> dropSlot(
    Json payload,
    DateTime day,
    WorkPart part,
    int minute,
  ) async {
    if (!editMode || payload['actor'] != ops.actorId) return;
    final duration = payload['duration'] as int;
    final original = selectedSlot;
    if (original == null) return;
    stageSlot(
      RosterSlot(
        date: rosterDate(day),
        partId: part.id,
        start: rosterClock(minute),
        end: rosterClock(minute + duration),
        dayOffset: minute ~/ 1440,
        name: original.name,
        shiftId: original.shiftId,
        templateId: original.templateId,
        crewId: original.crewId,
        adjusted: true,
      ),
      {
        ...payload,
        'date': rosterDate(day),
        'partId': part.id,
        'scheduleDate': rosterDate(day),
        'dayOffset': minute ~/ 1440,
        'start': rosterClock(minute),
        'end': rosterClock(minute + duration),
      },
    );
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

  double get timeScale =>
      model.slots(model.selected).any((s) => s.endMinute - s.startMinute < 120)
      ? 48.0 / 30
      : 48.0 / 60;

  Widget slotFrame(RosterSlot slot, Widget child) {
    if (slot.vacancy) return child;
    final active = editMode && selected(slot);
    final frame = DirectEditFrame(
      enabled: model.editable,
      active: active,
      onEnter: () => enterEdit(slot),
      controls: false,
      child: active
          ? GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => setState(() => selectedSlot = slot),
              child: IgnorePointer(child: child),
            )
          : child,
    );
    if (!active) return frame;
    return editTapRegion(
      Stack(
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
                                            timeScale /
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
                    if (end == null ||
                        payload == null ||
                        !editMode ||
                        payload['actor'] != ops.actorId ||
                        end == slot.endMinute) {
                      setState(() {
                        resizingId = null;
                        resizingEnd = null;
                      });
                      return;
                    }
                    stageSlot(
                      RosterSlot(
                        date: slot.date,
                        partId: slot.partId,
                        start: slot.start,
                        end: rosterClock(end),
                        dayOffset: slot.dayOffset,
                        name: slot.name,
                        shiftId: slot.shiftId,
                        templateId: slot.templateId,
                        crewId: slot.crewId,
                        adjusted: true,
                      ),
                      {...payload, 'end': rosterClock(end)},
                    );
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
      ),
    );
  }

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
      pendingMove = null;
      draftPayload = null;
      resizingId = null;
      resizingEnd = null;
      savingDraft = false;
      draftFailed = false;
    }
  }

  @override
  void dispose() {
    model.dispose();
    vertical.dispose();
    super.dispose();
  }

  OperationsController get ops => widget.operations;

  Future<void> showPartShifts(WorkPart part) async {
    final slots = model
        .slots(model.selected)
        .where((s) => s.partId == part.id)
        .toList();
    final selected = await showAppSheet<RosterSlot>(
      context,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text('${part.name} 근무', style: AppText.title),
            ),
            for (final slot in slots)
              ListTile(
                title: Text(slot.name),
                subtitle: Text('${slot.start}–${slot.end}'),
                onTap: () => Navigator.pop(context, slot),
              ),
            if (slots.isEmpty) const ListTile(title: Text('배정된 근무가 없어요.')),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('닫기'),
            ),
          ],
        ),
      ),
    );
    if (selected != null && mounted && model.editable) await edit(selected);
  }

  Future<void> addShift(WorkPart part, int minute) => edit(
    RosterSlot(
      date: rosterDate(model.selected),
      partId: part.id,
      start: rosterClock(minute),
      end: rosterClock(minute + 60),
      dayOffset: minute ~/ 1440,
      name: '크루 추가',
      vacancy: true,
    ),
  );

  Future<void> edit(RosterSlot slot) async {
    if (!model.editable) return;
    final revision = ops.data!['revision'];
    final actor = ops.actorId;
    var start = slot.start, end = slot.end;
    var partId = slot.partId;
    var dayOffset = slot.dayOffset;
    String? crewId = slot.crewId;
    var repeat = 1;
    final days = <int>{DateTime.parse(slot.date).weekday};
    final crew = ops
        .rows('tappers')
        .where((p) => p['active'] != false)
        .toList();
    final result = await showAppFormSheet<Json>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, update) => AppSheetPanel(
          title: Text(
            '${slot.date} · ${slot.shiftId == null ? '크루 추가' : '근무 조정'}',
          ),
          content: SizedBox(
            width: 440,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    slot.shiftId == null ? '크루 추가 배정' : '${slot.name} 근무 조정',
                    style: AppText.title,
                  ),
                  const SizedBox(height: 16),
                  AppPicker<String>(
                    label: '담당 파트',
                    value: partId,
                    items: [
                      for (final part in model.parts.where(
                        (p) => !p.hidden || p.id == partId,
                      ))
                        DropdownMenuItem(
                          value: part.id,
                          child: Text(part.name),
                        ),
                    ],
                    onChanged: (v) {
                      if (v != null) update(() => partId = v);
                    },
                  ),
                  const SizedBox(height: 16),
                  AppPicker<int>(
                    label: '시작 날짜',
                    value: dayOffset,
                    items: [
                      DropdownMenuItem(value: 0, child: Text(slot.date)),
                      DropdownMenuItem(
                        value: 1,
                        child: Text(
                          '${rosterDate(DateTime.parse(slot.date).add(const Duration(days: 1)))} · 다음 날',
                        ),
                      ),
                    ],
                    onChanged: (v) {
                      if (v != null) update(() => dayOffset = v);
                    },
                  ),
                  const SizedBox(height: 16),
                  AppTimeField(
                    label: '시작 시간',
                    value: start,

                    onChanged: (v) => update(() => start = v),
                  ),
                  const SizedBox(height: 16),
                  AppTimeField(
                    label: '종료 시간',
                    value: end,

                    onChanged: (v) => update(() => end = v),
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
                      if (slot.shiftId == null && !slot.vacancy)
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
            if (slot.adjusted && !slot.vacancy && slot.shiftId == null)
              TextButton(
                onPressed: () => Navigator.pop(context, {
                  'action': 'reset_roster_slot',
                  'templateId': slot.templateId,
                  'date': slot.date,
                  'partId': partId,
                }),
                child: const Text('영업시간으로 되돌리기'),
              ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed:
                  start == end ||
                      (slot.vacancy && crewId == null) ||
                      (repeat > 1 && days.isEmpty)
                  ? null
                  : () => Navigator.pop(context, {
                      'action': crewId == null
                          ? 'save_roster_slot'
                          : repeat > 1
                          ? 'save_shift_pattern'
                          : 'save_staff_shift',
                      'date': slot.date,
                      if (crewId != null) 'dateIsBusinessDay': true,
                      'partId': partId,
                      'start': start,
                      'end': end,
                      if (crewId == null) 'templateId': slot.templateId,
                      if (crewId != null) ...{
                        'tapperId': crewId,
                        'scheduleDate': slot.date,
                        'dayOffset': dayOffset,
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

  Future<void> editCalendarDay(DateTime day) async {
    final revision = ops.data!['revision'];
    final actor = ops.actorId;
    final date = rosterDate(day);
    final days = ops.data?['workplace']?['days'] as Map? ?? {};
    final openDays = [
      for (var d = 1; d <= 7; d++)
        if ((days['$d'] as List? ?? []).isNotEmpty) d,
    ];
    var source = openDays.contains(day.weekday)
        ? day.weekday
        : openDays.firstOrNull;
    final exception = ops.data?['workplace']?['dateOverrides']?[date] as Map?;
    final currentlyOpen = exception == null
        ? openDays.contains(day.weekday)
        : exception['closed'] == false;
    var mode = currentlyOpen ? 'closed' : 'open';
    String? error;
    bool saving = false;
    await showAppFormSheet(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (c, update) => AppEditorScaffold(
          title: '$date 영업일 변경',
          onClose: () => Navigator.pop(c),
          footer: AppSheetFooter(
            children: [
              FilledButton(
                onPressed: saving
                    ? null
                    : () async {
                        if (actor != ops.actorId) return;
                        if ((mode == 'closed' && !currentlyOpen) ||
                            (mode == 'open' && currentlyOpen) ||
                            (mode == 'reset' && exception == null)) {
                          update(
                            () => error = mode == 'reset'
                                ? '이미 기본 일정이에요. 변경하지 않았어요.'
                                : currentlyOpen
                                ? '이미 영업일이에요. 변경하지 않았어요.'
                                : '이미 휴무일이에요. 변경하지 않았어요.',
                          );
                          return;
                        }
                        update(() => saving = true);
                        final ok = await ops.act('save_calendar_day', {
                          'revision': revision,
                          'date': date,
                          'mode': mode,
                          if (mode == 'open') 'weekday': source,
                        });
                        if (!c.mounted) return;
                        if (ok) {
                          Navigator.pop(c);
                          return;
                        }
                        update(() {
                          saving = false;
                          error = ops.error;
                        });
                      },
                child: Text(saving ? '저장 중…' : '일정 저장'),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const Text('이 날짜만 변경해요. 정기 휴무일은 유지돼요.', style: AppText.caption),
              for (final option in {
                'closed': '추가 휴무일 지정',
                'open': '추가 영업일 지정',
                'reset': '기본 일정으로 복원',
              }.entries)
                ListTile(
                  title: Text(option.value),
                  leading: Icon(
                    mode == option.key
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                    color: mode == option.key
                        ? AppColors.green
                        : AppColors.muted,
                  ),
                  selected: mode == option.key,
                  onTap: saving
                      ? null
                      : () => update(() {
                          mode = option.key;
                          error = null;
                        }),
                ),
              if (mode == 'open') ...[
                const Text('시간·크루 배정을 참고할 요일', style: AppText.caption),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final d in openDays)
                      ChoiceChip(
                        label: Text(weekdays[d - 1]),
                        selected: source == d,
                        onSelected: saving
                            ? null
                            : (_) => update(() => source = d),
                      ),
                  ],
                ),
                const Text(
                  '저장 후 인원 배치에 저장한 기본 크루 배정이 반영돼요.',
                  style: AppText.caption,
                ),
              ],
              if (mode == 'closed')
                const Text(
                  '아직 시작하지 않은 배정은 해제돼요. 승인·출퇴근·신청 기록이 있는 날은 변경을 멈추고 알려드려요.',
                  style: AppText.caption,
                ),
              if (mode == 'reset')
                const Text('인원 배치의 기본 크루 배정을 반영해요.', style: AppText.caption),
              if (error != null) Information(error!),
            ],
          ),
        ),
      ),
    );
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
                return SizedBox(
                  width: box.maxWidth / 7,
                  height:
                      80 * (MediaQuery.textScalerOf(context).scale(14) / 14),
                  child: InkWell(
                    onTap: () => !model.isPast(day) && model.editable
                        ? editCalendarDay(day)
                        : model.selectDay(day),
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
                                  : AppColors.muted.withValues(alpha: .4),
                            ),
                          ),
                          Text(
                            isClosedDay(day)
                                ? (model.isPast(day) ? '휴일' : '휴무')
                                : (model.isPast(day) ? '업무' : '영업'),
                            style: AppText.caption,
                            maxLines: 1,
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
                                    color: day.month == first.month
                                        ? dayColor(day)
                                        : AppColors.muted.withValues(alpha: .4),
                                  ),
                                ),
                              ),
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

  Widget week({bool slivers = false}) {
    final children = <Widget>[
      Row(
        children: [
          for (var i = 0; i < 7; i++)
            Expanded(
              child: Builder(
                builder: (context) {
                  final day = model.monday.add(Duration(days: i));
                  final selected =
                      rosterDate(day) == rosterDate(model.selected);
                  return Semantics(
                    selected: selected,
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: selected ? AppColors.green : AppColors.line,
                            width: selected ? 2 : 1,
                          ),
                        ),
                      ),
                      child: TextButton(
                        key: ValueKey('roster-day-${rosterDate(day)}'),
                        onPressed: () => model.selectDay(day),
                        style: TextButton.styleFrom(
                          minimumSize: const Size(0, 48),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          foregroundColor: selected
                              ? AppColors.ink
                              : dayColor(day),
                          textStyle: AppText.caption.copyWith(
                            fontWeight: selected
                                ? FontWeight.w700
                                : FontWeight.w400,
                          ),
                        ),
                        child: Text(
                          '${day.day}\n${weekdays[i]}',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
      const SizedBox(height: 16),
      if (isClosedDay(model.selected))
        const SizedBox(
          key: ValueKey('roster-closed-day'),
          width: double.infinity,
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Text(
              '휴무일',
              textAlign: TextAlign.center,
              style: AppText.section,
            ),
          ),
        )
      else if (model.history)
        attendanceHistory()
      else if (slivers)
        SliverLayoutBuilder(
          builder: (context, box) =>
              timeline(box.crossAxisExtent, slivers: true),
        )
      else
        LayoutBuilder(builder: (context, box) => timeline(box.maxWidth)),
    ];
    return slivers
        ? SliverMainAxisGroup(
            slivers: [
              for (final child in children)
                if (child is SliverLayoutBuilder)
                  child
                else
                  SliverToBoxAdapter(child: child),
            ],
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          );
  }

  Widget attendanceHistory() {
    final sessions = attendanceSessions(
      ops.rows('attendance'),
    ).where((s) => rosterDate(s.day) == rosterDate(model.selected)).toList();
    const labels = {
      'clock_in': '출근',
      'clock_out': '퇴근',
      'break_start': '휴게 시작',
      'break_end': '휴게 종료',
    };
    return Column(
      key: const ValueKey('attendance-history'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(rosterDate(model.selected), style: AppText.caption),
        const SizedBox(height: 4),
        const Text('출퇴근 이력', style: AppText.section),
        const SizedBox(height: 12),
        if (sessions.isEmpty) const Information('기록된 출퇴근 이력이 없어요.'),
        for (final session in sessions) ...[
          Surface(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  ops
                          .rows('tappers')
                          .where((p) => p['id'] == session.crewId)
                          .firstOrNull?['nickname'] ??
                      '크루',
                  style: AppText.body,
                ),
                if (!session.hasClockIn)
                  const Text('출근 미기록', style: AppText.caption),
                if (!session.hasClockOut)
                  const Text('퇴근 미기록', style: AppText.caption),
                const SizedBox(height: 8),
                for (final event in session.events)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            labels[event['type']]!,
                            style: AppText.caption,
                          ),
                        ),
                        Text(() {
                          final at = koreanAttendanceTime(event['at']);
                          final date = rosterDate(at) == rosterDate(session.day)
                              ? ''
                              : '${at.month}/${at.day} ';
                          return '$date${rosterClock(at.hour * 60 + at.minute)}';
                        }(), style: AppText.body),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget timeline(double availableWidth, {bool slivers = false}) {
    final parts = model.visibleParts;
    if (parts.isEmpty) {
      const empty = Information('우리매장 → 파트 관리에서 파트를 추가해 주세요.');
      return slivers ? const SliverToBoxAdapter(child: empty) : empty;
    }
    final days = [model.selected];
    final all = [for (final day in days) ...displayedSlots(day)];
    final bounds = slotsForDay(
      ops.data ?? {},
      model.selected,
      parts,
      includeCovered: true,
    );
    final exception =
        ops.data?['workplace']?['dateOverrides']?[rosterDate(model.selected)];
    final sourceDay = exception?['weekday'] ?? model.selected.weekday;
    final boundary = ops.data?['workplace']?['businessDayStart'] ?? '00:00';
    for (final band
        in (ops.data?['workplace']?['days']?['$sourceDay'] as List? ?? [])) {
      if (band['custom'] == true) continue;
      bounds.add(
        RosterSlot(
          date: rosterDate(model.selected),
          partId: '',
          name: '',
          start: band['start'],
          end: band['end'],
          dayOffset: (band['start'] as String).compareTo(boundary) < 0 ? 1 : 0,
        ),
      );
    }
    bounds.addAll(all);
    final earliest = bounds.fold<int>(
      9 * 60,
      (v, s) => s.startMinute < v ? s.startMinute : v,
    );
    final from = fullDay ? 0 : ((earliest - 120).clamp(0, 1440) ~/ 60) * 60;
    var until = bounds.fold<int>(
      fullDay ? 1440 : 16 * 60,
      (end, slot) => shownEnd(slot) + 120 > end ? shownEnd(slot) + 120 : end,
    );
    if (previewMinute != null &&
        previewDuration != null &&
        previewMinute! + previewDuration! > until) {
      until = previewMinute! + previewDuration!;
    }
    // Compact full shifts on phones; expand when short assignments need touch room.
    final scale = timeScale;
    final gridHeight = (until - from) * scale;
    final textScale = MediaQuery.textScalerOf(context).scale(14) / 14;
    final laneCounts = {
      for (final part in parts)
        part.id: scheduleLayout(
          all.where((s) => s.partId == part.id).toList(),
        ).values.fold<int>(1, (n, p) => p.count > n ? p.count : n),
    };
    final totalLanes = laneCounts.values.fold<int>(0, (a, b) => a + b);
    final partWidths = {
      for (final part in parts)
        part.id: (availableWidth - 36) * laneCounts[part.id]! / totalLanes,
    };
    final headerHeight =
        (dayNote(model.selected).isEmpty ? 80.0 : 112.0) * textScale;
    final header = ColoredBox(
      color: AppColors.paper,
      child: Row(
        children: [
          const SizedBox(
            width: 36,
            child: Center(child: Text('시간', style: AppText.caption)),
          ),
          Expanded(
            child: Column(
              children: [
                SizedBox(
                  key: const ValueKey('roster-date-heading'),
                  height: headerHeight / 2,
                  child: Center(
                    child: Text(
                      '${model.selected.month}/${model.selected.day} ${weekdays[model.selected.weekday - 1]}${dayNote(model.selected).isEmpty ? '' : '\n${dayNote(model.selected)}'}',
                      textAlign: TextAlign.center,
                      style: AppText.body.copyWith(
                        fontWeight: FontWeight.w700,
                        color: dayColor(model.selected),
                      ),
                    ),
                  ),
                ),
                Row(
                  children: [
                    for (final part in parts)
                      SizedBox(
                        key: ValueKey('roster-part-heading-${part.id}'),
                        width: partWidths[part.id],
                        height: headerHeight / 2,
                        child: InkWell(
                          onTap: () => showPartShifts(part),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Flexible(
                                child: Text(
                                  '${part.name}${part.hidden ? ' · 숨김' : ''}',
                                  style: AppText.caption,
                                ),
                              ),
                              const Icon(Icons.expand_more, size: 16),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
    final body = SizedBox(
      key: const ValueKey('roster-timeline'),
      height: gridHeight + 24,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            key: const ValueKey('roster-time-axis'),
            width: 36,
            child: Stack(
              children: [
                for (var m = from; m <= until; m += 30)
                  Positioned(
                    top: (m - from) * scale,
                    left: 0,
                    right: 0,
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            m % 60 == 0
                                ? '${m >= 1440 ? '+' : ''}${m ~/ 60 % 24}시'
                                : '-',
                            textAlign: TextAlign.center,
                            style: AppText.caption.copyWith(fontSize: 12),
                          ),
                        ),
                        SizedBox(
                          key: ValueKey('roster-time-tick-$m'),
                          width: 6,
                          height: 1,
                          child: ColoredBox(
                            color: m % 60 == 0
                                ? AppColors.muted
                                : Colors.transparent,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          for (final part in parts)
            SizedBox(
              width: partWidths[part.id],
              child: _column(
                model.selected,
                part,
                all.where((s) => s.partId == part.id).toList(),
                from,
                until,
                scale,
                partWidths[part.id]!,
              ),
            ),
        ],
      ),
    );
    final empty = all.isEmpty
        ? const Padding(
            padding: EdgeInsets.only(top: 16),
            child: Information('배정된 근무가 없어요. 크루 추가 버튼으로 배정할 수 있어요.'),
          )
        : const SizedBox.shrink();
    if (slivers) {
      return SliverMainAxisGroup(
        slivers: [
          SliverPersistentHeader(
            pinned: true,
            delegate: _RosterHeader(height: headerHeight, child: header),
          ),
          SliverToBoxAdapter(child: body),
          SliverToBoxAdapter(child: empty),
        ],
      );
    }
    return Column(
      children: [
        SizedBox(height: headerHeight, child: header),
        body,
        empty,
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
    final originalOrder = {
      for (var i = 0; i < slots.length; i++) slots[i].shiftId: i,
    };
    slots.sort((a, b) {
      final time = a.startMinute.compareTo(b.startMinute);
      return time != 0
          ? time
          : originalOrder[a.shiftId]!.compareTo(originalOrder[b.shiftId]!);
    });
    final layout = scheduleLayout(slots);
    final preview =
        previewColumn == '${rosterDate(day)}/${part.id}' &&
            previewMinute != null
        ? RosterSlot(
            date: rosterDate(day),
            partId: part.id,
            start: rosterClock(previewMinute!),
            end: rosterClock(previewMinute! + previewDuration!),
            dayOffset: previewMinute! ~/ 1440,
            name: '',
            shiftId: previewShiftId ?? 'preview',
          )
        : null;
    final previewLayout = preview == null
        ? null
        : scheduleLayout([
            ...slots.map((s) => s.shiftId == preview.shiftId ? preview : s),
            if (!slots.any((s) => s.shiftId == preview.shiftId)) preview,
          ])[preview.shiftId];
    final exception =
        ops.data?['workplace']?['dateOverrides']?[rosterDate(day)];
    final weekday = exception?['weekday'] ?? day.weekday;
    final bands = (ops.data?['workplace']?['days']?['$weekday'] as List? ?? [])
        .cast<Json>();
    final boundary = rosterMinute(
      ops.data?['workplace']?['businessDayStart'] ?? '00:00',
    );
    int bandStart(Json b) {
      final m = rosterMinute(b['start']);
      return m < boundary ? m + 1440 : m;
    }

    int bandEnd(Json b) {
      final start = bandStart(b);
      var end = rosterMinute(b['end']) + (start ~/ 1440) * 1440;
      if (end <= start) end += 1440;
      return end;
    }

    final opening = bands.isEmpty
        ? null
        : bands.map(bandStart).reduce((a, b) => a < b ? a : b);
    final closing = bands.isEmpty
        ? null
        : bands.map(bandEnd).reduce((a, b) => a > b ? a : b);
    final pause = ops.data?['workplace']?['breaks']?['$weekday'] as Map?;
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
                  .clamp(from, (until - 30).clamp(from, 2850));
          if (previewColumn != '${rosterDate(day)}/${part.id}' ||
              previewMinute != minute) {
            setState(() {
              previewColumn = '${rosterDate(day)}/${part.id}';
              previewMinute = minute;
              previewDuration = d.data['duration'] as int;
              previewShiftId = d.data['id'] as String?;
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
                  .clamp(from, (until - 30).clamp(from, 2850));
          dropSlot(d.data, day, part, minute);
        },
        builder: (context, candidates, rejected) => SizedBox(
          height: (until - from) * scale + 24,
          child: Stack(
            children: [
              for (var m = from; m < until; m += 30)
                Positioned(
                  key: ValueKey('roster-cell-${rosterDate(day)}-${part.id}-$m'),
                  top: (m - from) * scale,
                  left: 0,
                  right: 0,
                  height: 30 * scale,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: model.editable ? () => addShift(part, m) : null,
                    child: Container(
                      key: ValueKey(
                        'roster-drop-${rosterDate(day)}-${part.id}-$m',
                      ),
                    ),
                  ),
                ),
              for (var i = 0; i < slots.length; i++)
                Positioned(
                  key: ValueKey(
                    'roster-position-${slots[i].date}-${slots[i].partId}-${slots[i].shiftId ?? slots[i].templateId}',
                  ),
                  top: (slots[i].startMinute - from) * scale + 2,
                  left:
                      layout[slots[i].shiftId]!.lane *
                          width /
                          layout[slots[i].shiftId]!.count +
                      3,
                  width: width / layout[slots[i].shiftId]!.count - 6,
                  height:
                      (shownEnd(slots[i]) - slots[i].startMinute) * scale - 4,
                  child: slotFrame(
                    slots[i],
                    Semantics(
                      button: true,
                      label:
                          '${slots[i].date} ${part.name} ${slots[i].name} ${slots[i].start} ${rosterClock(shownEnd(slots[i]))}',
                      child: Material(
                        color: Color.alphaBlend(
                          (slots[i].crewId == null
                                  ? AppColors.accent
                                  : crewColor(slots[i].crewId!))
                              .withValues(alpha: .12),
                          AppColors.paper,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: slots[i].crewId == null
                                ? AppColors.accent.withValues(alpha: .6)
                                : crewColor(slots[i].crewId!),
                          ),
                        ),
                        child: InkWell(
                          key: ValueKey(
                            'roster-${slots[i].date}-${slots[i].partId}-${slots[i].shiftId ?? slots[i].templateId}${slots[i].vacancy ? '-${slots[i].start}' : ''}',
                          ),
                          borderRadius: BorderRadius.circular(12),
                          onTap: model.editable
                              ? () {
                                  if (editMode && !slots[i].vacancy) {
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
                          child: LayoutBuilder(
                            builder: (context, box) {
                              final compact = box.maxWidth < 100;
                              return Semantics(
                                label:
                                    '${slots[i].name} ${slots[i].start}–${rosterClock(shownEnd(slots[i]))}',
                                child: Padding(
                                  padding: EdgeInsets.all(compact ? 3 : 8),
                                  child: Center(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          slots[i].name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          textAlign: TextAlign.center,
                                          style:
                                              (compact
                                                      ? AppText.caption
                                                      : AppText.body)
                                                  .copyWith(
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                        ),
                                        if (box.maxHeight >= 80)
                                          Text(
                                            '${slots[i].start}–${slots[i].overnight ? '다음 날 ' : ''}${rosterClock(shownEnd(slots[i]))}',
                                            textAlign: TextAlign.center,
                                            style: AppText.caption,
                                          ),
                                        if (!compact && box.maxHeight >= 120)
                                          Text(
                                            slots[i].crewId == null
                                                ? '미배정'
                                                : '${slots[i].adjusted ? '배정 · 미세조정' : '배정'}${requestLabel(slots[i])}',
                                            style: AppText.caption,
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              if (pause != null &&
                  pause['start'] != null &&
                  pause['end'] != null)
                Positioned(
                  key: ValueKey('roster-break-position-${part.id}'),
                  top:
                      (bandStart(Map<String, dynamic>.from(pause)) - from) *
                      scale,
                  left: 0,
                  right: 0,
                  height:
                      (bandEnd(Map<String, dynamic>.from(pause)) -
                          bandStart(Map<String, dynamic>.from(pause))) *
                      scale,
                  child: IgnorePointer(
                    child: Container(
                      key: ValueKey('roster-break-${part.id}'),
                      color: Colors.orange.withValues(alpha: .18),
                    ),
                  ),
                ),
              for (final marker in [(opening, '영업 시작'), (closing, '영업 종료')])
                if (marker.$1 != null)
                  Positioned(
                    key: ValueKey('roster-marker-${part.id}-${marker.$2}'),
                    top: (marker.$1! - from) * scale,
                    left: 0,
                    right: 0,
                    child: IgnorePointer(
                      child: Container(
                        key: ValueKey('roster-hours-${part.id}-${marker.$2}'),
                        decoration: const BoxDecoration(
                          border: Border(
                            top: BorderSide(color: AppColors.green),
                          ),
                        ),
                        child: const SizedBox(height: 1),
                      ),
                    ),
                  ),
              if (previewColumn == '${rosterDate(day)}/${part.id}' &&
                  previewMinute != null)
                Positioned(
                  key: ValueKey('roster-preview-position-${part.id}'),
                  top: (previewMinute! - from) * scale,
                  left: previewLayout!.lane * width / previewLayout.count + 3,
                  width: width / previewLayout.count - 6,
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

  Widget viewControls() {
    final exception =
        ops.data?['workplace']?['dateOverrides']?[rosterDate(model.selected)];
    final sourceDay = exception?['weekday'] ?? model.selected.weekday;
    return SizedBox(
      key: const ValueKey('schedule-header'),
      height: 48 * (MediaQuery.textScalerOf(context).scale(13) / 13),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            AppToolbarButton(
              icon: CupertinoIcons.chevron_left,
              label: '이전',
              onPressed: () {
                model.move(-1);
                loadHolidays();
              },
            ),
            Text(
              model.month
                  ? '${model.selected.year}년 ${model.selected.month}월'
                  : '${rosterDate(model.monday)} ~ ${rosterDate(model.monday.add(const Duration(days: 6)))}',
              style: AppText.caption,
            ),
            AppToolbarButton(
              icon: CupertinoIcons.chevron_right,
              label: '다음',
              onPressed: () {
                model.move(1);
                loadHolidays();
              },
            ),
            AppToolbarButton(
              icon: Icons.today_outlined,
              label: '오늘',
              onPressed: () => model.selectDay(
                DateTime.tryParse(ops.data?['day'] ?? '') ?? DateTime.now(),
              ),
            ),
            const AppToolbarDivider(),
            AppToolbarButton(
              icon: Icons.view_week_outlined,
              label: '주간',
              selected: !model.month,
              onPressed: () => model.setMonth(false),
            ),
            AppToolbarButton(
              icon: Icons.calendar_month_outlined,
              label: '월간',
              selected: model.month,
              onPressed: () => model.setMonth(true),
            ),
            const AppToolbarDivider(),
            const Icon(Icons.horizontal_rule, size: 18, color: AppColors.green),
            Text(
              '영업시간',
              style: AppText.caption.copyWith(color: AppColors.green),
            ),
            if (ops.data?['workplace']?['breaks']?['$sourceDay'] != null) ...[
              const SizedBox(width: 8),
              const Icon(Icons.square, size: 18, color: Colors.orange),
              Text(
                '브레이크',
                style: AppText.caption.copyWith(color: Colors.orange),
              ),
            ],
            AppToolbarButton(
              icon: Icons.schedule,
              label: fullDay ? '근무 시간 중심 보기' : '24시간 보기',
              selected: fullDay,
              onPressed: () => setState(() => fullDay = !fullDay),
            ),
            const AppToolbarDivider(),
            AppToolbarButton(
              key: const ValueKey('calendar-hours-button'),
              icon: Icons.tune,
              label: '영업시간·인원',
              onPressed: () => openWorkplaceHours(context, ops),
            ),
            if (model.editable &&
                !model.history &&
                !isClosedDay(model.selected))
              AppToolbarButton(
                key: const ValueKey('calendar-add-crew'),
                icon: Icons.person_add_outlined,
                label: '크루 추가',
                onPressed: model.visibleParts.where((p) => !p.hidden).isEmpty
                    ? null
                    : () => addShift(
                        model.visibleParts.firstWhere((p) => !p.hidden),
                        9 * 60,
                      ),
              ),
            if (editMode)
              AppToolbarButton(
                icon: Icons.check,
                label: '편집 완료',
                onPressed: finishEdit,
              ),
          ],
        ),
      ),
    );
  }

  List<Widget> contents({bool slivers = false}) => [
    if (!holidays.keys.any((d) => d.startsWith('${model.selected.year}-')))
      const Text('이 연도의 공휴일 정보를 불러오지 못했어요.', style: AppText.caption),
    if (savingDraft) const Text('근무표 저장 중…', style: AppText.caption),
    if (draftFailed && editMode)
      editTapRegion(
        Row(
          children: [
            const Expanded(
              child: Text('저장하지 못했어요. 수정 내용은 유지돼요.', style: AppText.caption),
            ),
            TextButton(onPressed: finishEdit, child: const Text('다시 저장')),
            TextButton(
              onPressed: () => setState(() {
                pendingMove = null;
                draftPayload = null;
                selectedSlot = null;
                arranging = false;
                draftFailed = false;
              }),
              child: const Text('변경 취소'),
            ),
          ],
        ),
      ),
    if (editMode && selectedSlot != null)
      editTapRegion(
        Wrap(
          spacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              '${selectedSlot!.name} · 다른 곳을 누르면 저장',
              style: AppText.caption,
            ),
            IconButton(
              tooltip: '시간·크루 변경',
              onPressed: () async {
                final slot = selectedSlot!;
                if (await finishEdit() && mounted) await edit(slot);
              },
              icon: const Icon(Icons.tune),
            ),
            IconButton(
              tooltip: '이름 변경',
              onPressed: () async {
                final slot = selectedSlot!;
                if (await finishEdit() && mounted) await renameSlot(slot);
              },
              icon: const Icon(Icons.edit_outlined),
            ),
            IconButton(
              tooltip: '삭제',
              onPressed: () async {
                final slot = selectedSlot!;
                if (await finishEdit() && mounted) await deleteSlot(slot);
              },
              icon: const Icon(Icons.delete_outline),
              color: AppColors.accent,
            ),
          ],
        ),
      ),
    if (model.month && model.editable)
      const Padding(
        padding: EdgeInsets.only(bottom: 8),
        child: Text('날짜를 눌러 추가 휴무·업무일을 지정해요.', style: AppText.caption),
      ),
    if (model.month) month() else week(slivers: slivers),
    if (!model.history && !isClosedDay(model.selected))
      ShiftChangePanel(ops: ops),
  ];

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: model,
    builder: (context, _) => widget.scrollable
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              viewControls(),
              const SizedBox(height: 4),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => ops.refresh(),
                  child: CustomScrollView(
                    key: const ValueKey('schedule-scroll'),
                    controller: vertical,
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      for (final child in contents(slivers: true))
                        if (child is SliverMainAxisGroup)
                          child
                        else
                          SliverToBoxAdapter(child: child),
                      const SliverToBoxAdapter(child: SizedBox(height: 24)),
                    ],
                  ),
                ),
              ),
            ],
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [viewControls(), ...contents()],
          ),
  );
}

class _RosterHeader extends SliverPersistentHeaderDelegate {
  _RosterHeader({required this.height, required this.child});
  final double height;
  final Widget child;
  @override
  double get minExtent => height;
  @override
  double get maxExtent => height;
  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) => child;
  @override
  bool shouldRebuild(_RosterHeader oldDelegate) =>
      height != oldDelegate.height || child != oldDelegate.child;
}
