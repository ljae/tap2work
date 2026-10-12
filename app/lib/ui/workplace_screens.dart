import 'entity_name_translation.dart';
import '../l10n/entity_name_scope.dart';
import 'weekday_scope_selector.dart';
import 'business_hours_slider.dart';
import 'crew_invitation_screen.dart';
import 'dart:convert';
import 'dart:math';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../state/operations_controller.dart';
import '../domain/store_preparation.dart';
import '../l10n/app_localizations.dart';
import 'components.dart';

/// All hours entry points use the same draft, validation and save flow.
Future<void> openWorkplaceHours(
  BuildContext context,
  OperationsController ops, {
  bool staffing = false,
}) => showAppFormSheet<void>(
  context: context,
  builder: (_) =>
      WorkplaceSettings(ops: ops, section: 'hours', staffing: staffing),
);

const defaultParts = <Json>[
  {
    'id': 'kitchen',
    'name': '주방',
    'roles': ['cook', 'prep', 'dishwashing'],
    'duties': ['조리'],
  },
  {
    'id': 'hall',
    'name': '홀',
    'roles': ['crew', 'service'],
    'duties': ['서빙1', '서빙2'],
  },
  {
    'id': 'management',
    'name': '관리',
    'roles': ['manager', 'owner', 'cashier'],
    'duties': ['cashier'],
  },
];
List<Json> storeParts(OperationsController ops) =>
    (ops.data?['workplace']?['parts'] as List? ?? defaultParts).cast<Json>();

String partLabel(
  OperationsController ops,
  dynamic id, {
  BuildContext? context,
}) {
  final part = storeParts(ops).where((p) => p['id'] == id).firstOrNull;
  if (context == null) return part?['name'] ?? '전체 파트';
  return part == null
      ? context.t('전체 파트')
      : entityDisplayName(context, ops, 'part', id, part['name']);
}

String crewPartsLabel(
  OperationsController ops,
  Json person, {
  BuildContext? context,
}) {
  final ids = person['workProfile']?['partIds'] as List? ?? [];
  return ids.isEmpty
      ? (context == null ? '전체 파트' : context.t('전체 파트'))
      : ids.map((id) => partLabel(ops, id, context: context)).join(' · ');
}

/// Compact, shared card row used by setup, settings and employee details.
class SettingRow extends StatelessWidget {
  const SettingRow({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.onTap,
    this.trailing,
    this.color = AppColors.muted,
  });
  final String title;
  final String? subtitle;
  final IconData? icon;
  final VoidCallback? onTap;
  final Widget? trailing;
  final Color color;
  @override
  Widget build(BuildContext context) => PressBounce(
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 16),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppText.body.copyWith(fontWeight: FontWeight.w700),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(subtitle!, style: AppText.caption),
                  ],
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 8),
              trailing!,
            ] else if (onTap != null)
              const Icon(
                CupertinoIcons.chevron_right,
                size: 18,
                color: AppColors.muted,
              ),
          ],
        ),
      ),
    ),
  );
}

class StorePreparation extends StatefulWidget {
  const StorePreparation({
    super.key,
    required this.ops,
    required this.onHours,
    required this.onPeople,
    required this.onTasks,
    required this.onSchedule,
    this.onMenus,
    this.onInventory,
  });
  final OperationsController ops;
  final VoidCallback onHours, onPeople, onTasks, onSchedule;
  final VoidCallback? onMenus, onInventory;
  @override
  State<StorePreparation> createState() => _StorePreparationState();
}

class _StorePreparationState extends State<StorePreparation> {
  bool collapsed = false;
  @override
  Widget build(BuildContext context) {
    final ops = widget.ops;
    final status = StorePreparationStatus(ops.data ?? {});
    final checks = [
      (
        title: context.t('setup.hours'),
        done: status.hasHours,
        icon: CupertinoIcons.clock,
        tap: widget.onHours,
      ),
      (
        title: context.t('setup.crew'),
        done: status.hasCrew,
        icon: CupertinoIcons.person_add,
        tap: widget.onPeople,
      ),
      (
        title: context.t('setup.tasks'),
        done: status.hasManuals || status.hasTodayTasks,
        icon: CupertinoIcons.checkmark_alt_circle,
        tap: widget.onTasks,
      ),
      (
        title: context.t('setup.schedule'),
        done: status.hasAssignments,
        icon: CupertinoIcons.calendar,
        tap: widget.onSchedule,
      ),
    ];
    final next = <({String title, VoidCallback? tap})>[
      if (!status.hasHours)
        (title: context.t('setup.hours'), tap: widget.onHours),
      if (!status.hasCrew)
        (title: context.t('setup.noCrew'), tap: widget.onPeople),
      if (status.neededMinutes > status.coveredMinutes)
        (
          title: context.t(
            'setup.coverage',
            args: {
              'needed': status.neededMinutes,
              'covered': status.coveredMinutes,
            },
          ),
          tap: widget.onSchedule,
        ),
      if (!status.hasTodayTasks)
        (title: context.t('setup.noTasks'), tap: widget.onTasks),
      if (status.menusToReview > 0)
        (
          title: context.t(
            'setup.menuReview',
            args: {'count': status.menusToReview},
          ),
          tap: widget.onMenus,
        ),
      if (status.inventoryToReview > 0)
        (
          title: context.t(
            'setup.inventoryReview',
            args: {'count': status.inventoryToReview},
          ),
          tap: widget.onInventory,
        ),
    ];
    return Surface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  context.t(
                    'setup.basicTitle',
                    args: {
                      'done': checks.where((c) => c.done).length,
                      'total': checks.length,
                    },
                  ),
                  style: AppText.body.copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => setState(() => collapsed = !collapsed),
                child: Text(
                  collapsed
                      ? context.t('ui.audit778')
                      : context.t('ui.audit779'),
                ),
              ),
            ],
          ),
          if (!collapsed) ...[
            Text(context.t('setup.nonBlocking'), style: AppText.caption),
            const SizedBox(height: 8),
            for (final check in checks)
              SettingRow(
                title: check.title,
                icon: check.icon,
                color: check.done ? AppColors.green : AppColors.muted,
                onTap: check.tap,
                trailing: Icon(
                  check.done
                      ? CupertinoIcons.checkmark_circle_fill
                      : CupertinoIcons.chevron_right,
                  color: check.done ? AppColors.green : AppColors.muted,
                  size: 22,
                ),
              ),
            if (next.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(context.t('setup.remaining'), style: AppText.section),
              for (final item in next.take(3))
                SettingRow(
                  title: item.title,
                  onTap: item.tap,
                  color: AppColors.accent,
                ),
            ],
          ],
        ],
      ),
    );
  }
}

class AttendanceCard extends StatelessWidget {
  const AttendanceCard({super.key, required this.ops});
  final OperationsController ops;
  @override
  Widget build(BuildContext context) {
    final own = ops
        .rows('tappers')
        .where((t) => t['actorId'] == ops.actorId)
        .firstOrNull;
    if (own == null) return const SizedBox.shrink();
    final state = own['attendanceState'] ?? 'off_duty';
    final working = state == 'clock_in' || state == 'break_end';
    final resting = state == 'break_start';
    final shifts = ops
        .rows('staffShifts')
        .where(
          (s) =>
              s['status'] != 'leave' &&
              s['tapperId'] == own['id'] &&
              s['date'] == ops.data?['day'],
        )
        .toList();
    Future<void> act(String action) async {
      final ok = await ops.act(action, {});
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              ok
                  ? context.t('ui.audit780')
                  : ops.error ?? context.t('ui.audit781'),
            ),
          ),
        );
      }
    }

    return Surface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.t(
              'ui.audit782',
              args: {
                'p0': own['nickname'],
                'p1': working
                    ? context.t('ui.audit1143')
                    : resting
                    ? context.t('ui.audit1144')
                    : shifts.isEmpty
                    ? context.t('ui.audit1145')
                    : context.t('ui.audit1146'),
              },
            ),
            style: AppText.body.copyWith(
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            shifts.isEmpty
                ? context.t('ui.audit783')
                : shifts
                      .map(
                        (s) =>
                            '${s['start']}–${s['end']} · ${partLabel(ops, s['partId'], context: context)}',
                      )
                      .join('\n'),
            style: AppText.caption,
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              if (!working && !resting)
                PressBounce(
                  child: FilledButton.icon(
                    onPressed: ops.readOnly || ops.busy
                        ? null
                        : () => act('clock_in'),
                    icon: const Icon(CupertinoIcons.arrow_right_circle),
                    label: Text(context.t('ui.audit247')),
                  ),
                ),
              if (working)
                PressBounce(
                  child: FilledButton(
                    onPressed: ops.readOnly || ops.busy
                        ? null
                        : () => act('clock_out'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.amber,
                      foregroundColor: AppColors.paper,
                    ),
                    child: Text(context.t('ui.audit248')),
                  ),
                ),
              if (working || resting)
                PressBounce(
                  child: OutlinedButton(
                    onPressed: ops.readOnly || ops.busy
                        ? null
                        : () => act(resting ? 'break_end' : 'break_start'),
                    child: Text(
                      resting
                          ? context.t('ui.audit366')
                          : context.t('ui.audit365'),
                    ),
                  ),
                ),
            ],
          ),
          if (ops.readOnly)
            Padding(
              padding: EdgeInsets.only(top: 12),
              child: Text(context.t('ui.audit784'), style: AppText.caption),
            ),
        ],
      ),
    );
  }
}

class WorkplaceSettings extends StatefulWidget {
  const WorkplaceSettings({
    super.key,
    required this.ops,
    required this.section,
    this.person,
    this.staffing = false,
  });
  final OperationsController ops;
  final String section;
  final Json? person;
  final bool staffing;
  @override
  State<WorkplaceSettings> createState() => _WorkplaceSettingsState();
}

class _WorkplaceSettingsState extends State<WorkplaceSettings> {
  late int revision;
  late final String actorId;
  @override
  void initState() {
    super.initState();
    revision = widget.ops.data?['revision'] as int? ?? 0;
    actorId = widget.ops.actorId;
    if (widget.section == 'hours') {
      hoursStep = widget.staffing ? 1 : 0;
      days = initialDays();
      weekday =
          [
            for (var d = 1; d <= 7; d++)
              if ((days['$d'] as List).isNotEmpty) d,
          ].firstOrNull ??
          1;
      final signatures = [
        for (final rows in days.values)
          if ((rows as List).isNotEmpty)
            jsonEncode([
              for (final b in rows)
                [
                  b['name'],
                  b['start'],
                  b['end'],
                  b['headcounts'],
                  b['crewIds'],
                ],
            ]),
      ];
      allHours = signatures.toSet().length <= 1;
      selectedWeekdays.add(weekday);
    }
  }

  late List<Json> parts =
      (jsonDecode(jsonEncode(storeParts(widget.ops))) as List).cast<Json>();
  late Json days = initialDays();
  // The opening time is the business-day boundary; no separate input.
  // The shared boundary uses the earliest opening across operating weekdays.
  String get businessDayStart {
    final starts = <String>[
      for (final rows in days.values)
        if ((rows as List).isNotEmpty) '${rows.first['start']}',
    ]..sort();
    return starts.firstOrNull ??
        ops.data?['workplace']?['businessDayStart'] ??
        '00:00';
  }

  late Json breaks = jsonDecode(
    jsonEncode(ops.data?['workplace']?['breaks'] ?? {}),
  );
  int hoursStep = 0;
  bool allHours = false;
  final selectedWeekdays = <int>{};
  late bool useClosedDays = days.values.any((rows) => (rows as List).isEmpty);
  final Map<int, List<Json>> openDayDrafts = {};
  final Map<int, Json> openBreakDrafts = {};
  // Only automatic reflow needs an impact confirmation. Manual cut changes
  // remain explicit edits, and valid cuts survive outside-hours changes.
  final Map<int, List<Json>> reflowedHours = {};

  String hoursSummary(List<Json> rows) =>
      rows.map((b) => '${b['start']}–${b['end']}').join(' / ');

  List<String> get hoursReflowImpact => [
    for (final entry in reflowedHours.entries)
      if ((days['${entry.key}'] as List).isNotEmpty)
        context.t(
          'ui.audit2105',
          args: {
            'p0': dayNames[entry.key - 1],
            'p1': hoursSummary(entry.value),
            'p2': hoursSummary(
              (days['${entry.key}'] as List)
                  .cast<Json>()
                  .where((b) => b['custom'] != true)
                  .toList(),
            ),
          },
        ),
  ];

  List<Json> reopenedDay(int day) =>
      openDayDrafts.remove(day) ??
      [
        {'id': newBandId(), 'name': '오픈', 'start': '06:00', 'end': '22:00'},
      ];

  void setClosedDay(int day, bool closed) => update(() {
    if (closed) {
      openDayDrafts[day] = (jsonDecode(jsonEncode(days['$day'])) as List)
          .cast<Json>();
      if (breaks['$day'] != null) {
        openBreakDrafts[day] = {...breaks['$day'] as Json};
      }
      days['$day'] = <Json>[];
      selectedWeekdays.remove(day);
      breaks.remove('$day');
      if (weekday == day) {
        weekday =
            [
              for (var d = 1; d <= 7; d++)
                if ((days['$d'] as List).isNotEmpty) d,
            ].firstOrNull ??
            day;
      }
      if (selectedWeekdays.isEmpty && (days['$weekday'] as List).isNotEmpty) {
        selectedWeekdays.add(weekday);
      }
    } else {
      days['$day'] = reopenedDay(day);
      selectedWeekdays.add(day);
      final pause = openBreakDrafts.remove(day);
      if (pause != null) breaks['$day'] = pause;
      weekday = day;
    }
  });

  void toggleClosedDays(bool value) {
    if (value) {
      setState(() => useClosedDays = true);
      return;
    }
    update(() {
      useClosedDays = false;
      for (var day = 1; day <= 7; day++) {
        if ((days['$day'] as List).isNotEmpty) continue;
        days['$day'] = reopenedDay(day);
        final pause = openBreakDrafts.remove(day);
        if (pause != null) breaks['$day'] = pause;
      }
    });
  }

  bool get multipleShifts => hoursTargets.any(
    (d) => (days['$d'] as List).where((b) => b['custom'] != true).length > 1,
  );

  Json initialDays() {
    final saved =
        jsonDecode(jsonEncode(ops.data?['workplace']?['days'] ?? {})) as Json;
    final hours = ops.data?['store']?['profile']?['hours'] as Json?;
    for (var d = 1; d <= 7; d++) {
      saved.putIfAbsent(
        '$d',
        () => hours != null && (hours['weekdays'] as List? ?? []).contains(d)
            ? <Json>[
                {
                  'name': '전체',
                  'start': hours['opening'],
                  'end': hours['closing'],
                },
              ]
            : hours == null
            ? <Json>[
                {'name': '전체', 'start': '06:00', 'end': '22:00'},
              ]
            : <Json>[],
      );
    }
    for (var d = 1; d <= 7; d++) {
      final rows = (saved['$d'] as List).cast<Json>();
      for (var i = 0; i < rows.length; i++) {
        if (rows[i]['id'] == null) {
          rows[i]['id'] = 'legacy-band-$d-$i';
          rows[i]['legacyIndex'] = i;
        }
      }
    }
    return saved;
  }

  late Json restrictions = jsonDecode(
    jsonEncode(widget.ops.data?['workplace']?['restrictions'] ?? {}),
  );
  late Set<String> partIds = Set<String>.from(
    widget.person?['workProfile']?['partIds'] ?? [],
  );
  late Set<String> bands = Set<String>.from(
    widget.person?['workProfile']?['bands'] ?? [],
  );
  int weekday = 1;
  String role = 'manager';
  bool dirty = false, saving = false;
  String? error;
  final partName = TextEditingController();
  OperationsController get ops => widget.ops;
  bool get editable =>
      ops.actorId == actorId &&
      ops.isOwner &&
      !ops.readOnly &&
      !saving &&
      !ops.busy;
  static const titles = {
    'order-system': '주문처리 시스템 연결',
    'parts': '파트 관리',
    'hours': '영업시간·필요 인원',
    'permissions': '직책별 권한',
    'person': '파트·시간대 수정',
    'invite': '크루 초대',
    'verification': '출퇴근 인증 설정',
    'certificate': '보건증',
    'settlement': '정산 설정',
  };
  @override
  void dispose() {
    partName.dispose();
    super.dispose();
  }

  void update(VoidCallback fn) => setState(() {
    fn();
    dirty = true;
    error = null;
  });
  Future<void> close() async {
    if (saving) return;
    if (!dirty) {
      Navigator.pop(context);
      return;
    }
    final discard = await showAppDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(context.t('ui.audit178')),
        content: Text(context.t('ui.audit43')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: Text(context.t('ui.audit21')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: Text(context.t('ui.audit22')),
          ),
        ],
      ),
    );
    if (discard == true && mounted) {
      setState(() => dirty = false);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.pop(context);
      });
    }
  }

  Future<void> save(String action, Json values) async {
    if (!editable) {
      setState(() => error = context.t('ui.audit1254'));
      return;
    }
    setState(() {
      saving = true;
      error = null;
    });
    final ok = await ops.act(action, {'revision': revision, ...values});
    if (!mounted) return;
    setState(() {
      saving = false;
      if (ok) {
        revision = ops.data!['revision'];
        dirty = false;
        if (action == 'save_workplace_hours') reflowedHours.clear();
      } else {
        error = context.t('ui.audit1255', args: {'p0': ops.error});
      }
    });
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            action == 'save_workplace_hours'
                ? context.t('ui.audit785')
                : context.t('ui.audit786'),
          ),
        ),
      );
    }
  }

  Widget saveButton(VoidCallback onSave, {String label = '저장'}) => Padding(
    padding: const EdgeInsets.only(top: 24),
    child: SizedBox(
      width: double.infinity,
      child: PressBounce(
        child: FilledButton(
          onPressed: editable ? onSave : null,
          child: Text(saving ? context.t('ui.audit532') : label),
        ),
      ),
    ),
  );
  Widget section(String text) => Padding(
    padding: const EdgeInsets.only(top: 24, bottom: 12),
    child: Text(text, style: AppText.caption),
  );
  List<Json> get dayBands => (days['$weekday'] as List? ?? []).cast<Json>();
  List<Json> get operatingBands {
    final base = dayBands.where((b) => b['custom'] != true).toList();
    return base.isEmpty ? dayBands : base;
  }

  String newBandId() =>
      'custom-${DateTime.now().microsecondsSinceEpoch}-${Random.secure().nextInt(0x100000000)}';

  Future<void> preset(int count) async {
    if (!canDraftHours) return;
    final base = dayBands.where((b) => b['custom'] != true).toList();
    final custom = dayBands.where((b) => b['custom'] == true).toList();
    final linkedIds = <String>{
      for (final tap in ops.rows('taskTemplates'))
        for (final row in [tap, ...(tap['steps'] as List? ?? []).cast<Json>()])
          ...List<String>.from(
            row['settings']?['assignment']?['timeBandIds'] ?? [],
          ),
    };
    for (final d in hoursTargets) {
      final rows = (days['$d'] as List).cast<Json>();
      final normal = rows.where((b) => b['custom'] != true).toList();
      final operating = normal.isEmpty ? rows : normal;
      final start = _minute(operating.first['start']);
      var end = _minute(operating.last['end']);
      if (end <= start) end += 1440;
      final retainedCount = normal
          .skip(count)
          .where(
            (b) => linkedIds.contains(b['id']) || linkedPatternBand(b['id']),
          )
          .length;
      if (end - start < count * 30 ||
          count +
                  rows.where((b) => b['custom'] == true).length +
                  retainedCount >
              24) {
        setState(
          () => error = context.t(
            'ui.audit1256',
            args: {'p0': context.t(dayNames[d - 1])},
          ),
        );
        return;
      }
    }
    final retained = base
        .skip(count)
        .where((b) => linkedIds.contains(b['id']))
        .toList();
    if (count + custom.length + retained.length > 24) {
      setState(() => error = context.t('ui.audit1257'));
      return;
    }
    final hours = ops.data?['store']?['profile']?['hours'] as Json? ?? {};
    final start = _minute(
      operatingBands.firstOrNull?['start'] ?? hours['opening'] ?? '06:00',
    );
    var end = _minute(
      operatingBands.lastOrNull?['end'] ?? hours['closing'] ?? '22:00',
    );
    if (end <= start) end += 1440;
    if (end - start < count * 30) {
      setState(() => error = context.t('ui.audit1258'));
      return;
    }
    update(() {
      for (final d in hoursTargets) {
        final rows = (days['$d'] as List).cast<Json>();
        final base = rows.where((b) => b['custom'] != true).toList();
        final operating = base.isEmpty ? rows : base;
        final start = _minute(operating.first['start']);
        var end = _minute(operating.last['end']);
        if (end <= start) end += 1440;
        if (end - start < count * 30) {
          error = context.t(
            'ui.audit1259',
            args: {'p0': context.t(dayNames[d - 1])},
          );
          continue;
        }
        final cuts = shiftBoundaries(start, end, count);
        final names = count == 1
            ? ['오픈']
            : count == 2
            ? ['오픈', '마감']
            : ['오픈', '미들', '마감'];
        days['$d'] = [
          for (var i = 0; i < count; i++)
            {
              ...?base.elementAtOrNull(i),
              'id': base.elementAtOrNull(i)?['id'] ?? newBandId(),
              'name': names[i],
              'start': _time(cuts[i]),
              'end': _time(cuts[i + 1]),
              'partTimes': null,
            },
          for (final row in base.skip(count))
            if (linkedIds.contains(row['id']) || linkedPatternBand(row['id']))
              {
                ...row,
                'custom': true,
                'headcounts': {
                  for (final p in parts)
                    p['id']: row['headcounts']?[p['id']] ?? 1,
                },
              },
          ...rows.where((b) => b['custom'] == true),
        ];
      }
    });
  }

  bool linkedPatternBand(dynamic id) =>
      (ops.data?['crewPatterns'] as List? ?? []).any(
        (pattern) => (pattern['entries'] as List? ?? []).any(
          (entry) => entry['timeBandId'] == id,
        ),
      );
  Iterable<int> get hoursTargets => allHours
      ? [
          for (var d = 1; d <= 7; d++)
            if ((days['$d'] as List).isNotEmpty) d,
        ]
      : selectedWeekdays.where((d) => (days['$d'] as List).isNotEmpty).toList();
  void selectHoursScope(bool all) {
    if (!all || hoursStep != 0 || operatingBands.isEmpty) {
      setState(() {
        allHours = all;
        if (selectedWeekdays.isEmpty) selectedWeekdays.add(weekday);
      });
      return;
    }
    final source = operatingBands;
    final start = _minute(source.first['start']);
    final boundaries = [start];
    for (final band in source) {
      var end = _minute(band['end']);
      if (end <= boundaries.last) end += 1440;
      boundaries.add(end);
    }
    final openDays = days.values.where((rows) => (rows as List).isNotEmpty);
    if (openDays.any((rows) {
      final regular = (rows as List).where((b) => b['custom'] != true);
      final count = regular.isEmpty ? rows.length : regular.length;
      return count > 3 || boundaries.last - start < count * 30;
    })) {
      setState(() => error = context.t('ui.audit1260'));
      return;
    }
    allHours = true;
    changeHours(start, boundaries.last, boundaries: boundaries);
  }

  void changeHours(int start, int end, {List<int>? boundaries}) => update(() {
    for (final d in hoursTargets) {
      final rows = (days['$d'] as List).cast<Json>();
      final base = rows.where((b) => b['custom'] != true).toList();
      final bands = base.isEmpty ? rows : base;
      if (end - start < bands.length * 30) continue;
      if (bands.length > 3) continue;
      final retained = retainedShiftBoundaries(start, end, bands);
      final cuts = boundaries?.length == bands.length + 1
          ? boundaries!
          : retained ?? shiftBoundaries(start, end, bands.length.clamp(1, 3));
      if (boundaries == null && retained == null) {
        reflowedHours.putIfAbsent(
          d,
          () => (jsonDecode(jsonEncode(bands)) as List).cast<Json>(),
        );
      }
      for (var i = 0; i < bands.length; i++) {
        bands[i]['start'] = _time(cuts[i]);
        bands[i]['end'] = _time(cuts[i + 1]);
        bands[i].remove('partTimes');
      }
      final pause = breaks['$d'];
      if (pause != null) {
        var bs = _minute(pause['start']);
        if (bs < start) bs += 1440;
        var be = _minute(pause['end']);
        if (be <= bs) be += 1440;
        if (bs < start || be > end) {
          final nextStart = bs.clamp(start, end - 30);
          breaks['$d'] = {
            'start': _time(nextStart),
            'end': _time(be.clamp(nextStart + 30, end)),
          };
        }
      }
    }
  });

  static int _minute(String time) {
    final p = time.split(':').map(int.parse).toList();
    return p[0] * 60 + p[1];
  }

  static String _time(int minute) =>
      '${(minute ~/ 60 % 24).toString().padLeft(2, '0')}:${(minute % 60).toString().padLeft(2, '0')}';
  bool get canDraftHours =>
      ops.actorId == actorId && ops.isOwner && !saving && !ops.busy;
  static const dayNames = ['월', '화', '수', '목', '금', '토', '일'];
  Widget hoursHeading(String title, String help) => Row(
    children: [
      Expanded(child: Text(title, style: AppText.section)),
      IconButton(
        tooltip: context.t('ui.audit787', args: {'p0': title}),
        onPressed: () => ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(help))),
        icon: const Icon(Icons.info_outline),
      ),
    ],
  );

  String bandLabel(Json band) {
    final base = dayBands.where((b) => b['custom'] != true).toList();
    final index = base.indexOf(band);
    return index < 0 ? '${band['name']}' : shiftLabel(index, base.length);
  }

  int countFor(Json band, String part) =>
      (band['headcounts'] as Map?)?[part] ?? (band['custom'] == true ? 0 : 1);

  List<String> crewFor(Json band, String part) =>
      (band['crewIds']?[part] as List? ?? []).cast<String>();

  Future<void> editCount(int index, Json part) async {
    var count = countFor(dayBands[index], part['id']);
    final ids = List<String>.generate(
      12,
      (i) => crewFor(dayBands[index], part['id']).elementAtOrNull(i) ?? '',
    );
    final people = ops
        .rows('tappers')
        .where((p) => p['active'] != false)
        .toList();
    final accepted = await showAppDialog<bool>(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (c, refresh) => AlertDialog(
          scrollable: true,
          title: Text(
            '${bandLabel(dayBands[index])} · ${entityDisplayName(context, ops, 'part', part['id'], part['name'])}',
          ),
          content: SizedBox(
            width: 360,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      tooltip: context.t('ui.audit788'),
                      onPressed: count > 0
                          ? () => refresh(() => count--)
                          : null,
                      icon: const Icon(Icons.remove),
                    ),
                    Text(
                      context.t('ui.audit602', args: {'p0': count}),
                      style: AppText.title,
                    ),
                    IconButton(
                      tooltip: context.t('ui.audit789'),
                      onPressed: count < 12
                          ? () => refresh(() => count++)
                          : null,
                      icon: const Icon(Icons.add),
                    ),
                  ],
                ),
                for (var seat = 0; seat < count; seat++)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: DropdownButtonFormField<String>(
                      key: ValueKey('staffing-crew-$seat-${ids[seat]}'),
                      initialValue: ids[seat],
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: context.t(
                          'ui.audit790',
                          args: {'p0': seat + 1},
                        ),
                      ),
                      items: [
                        DropdownMenuItem(
                          value: '',
                          child: Text(context.t('ui.audit769')),
                        ),
                        for (final person in people)
                          DropdownMenuItem<String>(
                            value: person['id'],
                            child: Text(
                              person['nickname'],
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        if (ids[seat].isNotEmpty &&
                            !people.any((p) => p['id'] == ids[seat]))
                          DropdownMenuItem(
                            value: ids[seat],
                            child: Text(context.t('ui.audit249')),
                          ),
                      ],
                      onChanged: (v) => refresh(() => ids[seat] = v ?? ''),
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: Text(context.t('ui.audit33')),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(c, true),
              child: Text(context.t('ui.audit34')),
            ),
          ],
        ),
      ),
    );
    if (accepted != true || !mounted || !canDraftHours) return;
    final source = dayBands[index];
    final ordinal = dayBands
        .where((b) => b['custom'] != true)
        .toList()
        .indexOf(source);
    update(() {
      for (final d in hoursTargets) {
        final rows = (days['$d'] as List).cast<Json>();
        final target = source['custom'] == true
            ? rows.where((b) => b['id'] == source['id']).firstOrNull
            : rows.where((b) => b['custom'] != true).elementAtOrNull(ordinal);
        if (target == null) continue;
        target['headcounts'] ??= <String, dynamic>{};
        target['headcounts'][part['id']] = count;
        target['crewIds'] ??= <String, dynamic>{};
        target['crewIds'][part['id']] = ids.take(count).toList();
      }
    });
  }

  Widget staffingMatrix() {
    final visibleParts = parts.where((p) => p['hidden'] != true).toList();
    String name(String id) =>
        ops
            .rows('tappers')
            .where((p) => p['id'] == id)
            .firstOrNull?['nickname'] ??
        '비활성 크루';
    Widget label(String text) => Padding(
      padding: const EdgeInsets.all(12),
      child: Text(text, textAlign: TextAlign.center),
    );
    return LayoutBuilder(
      builder: (context, box) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: max(
            box.maxWidth,
            (visibleParts.length + 1) *
                68.0 *
                MediaQuery.textScalerOf(context).scale(1),
          ),
          child: Table(
            key: const ValueKey('staffing-matrix'),
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            border: TableBorder.all(color: AppColors.line),
            children: [
              TableRow(
                decoration: const BoxDecoration(color: AppColors.elevated),
                children: [
                  label('교대'),
                  for (final p in visibleParts)
                    label(
                      entityDisplayName(
                        context,
                        ops,
                        'part',
                        p['id'],
                        p['name'],
                      ),
                    ),
                ],
              ),
              for (var i = 0; i < dayBands.length; i++)
                TableRow(
                  children: [
                    label(bandLabel(dayBands[i])),
                    for (final p in visibleParts)
                      TextButton(
                        key: ValueKey('staffing-count-$i-${p['id']}'),
                        onPressed: canDraftHours ? () => editCount(i, p) : null,
                        style: TextButton.styleFrom(
                          minimumSize: const Size(48, 88),
                          padding: const EdgeInsets.all(8),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              context.t(
                                'ui.audit791',
                                args: {
                                  'p0': crewFor(
                                    dayBands[i],
                                    p['id'],
                                  ).where((id) => id.isNotEmpty).length,
                                  'p1': countFor(dayBands[i], p['id']),
                                },
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              crewFor(
                                    dayBands[i],
                                    p['id'],
                                  ).any((id) => id.isNotEmpty)
                                  ? crewFor(dayBands[i], p['id'])
                                        .where((id) => id.isNotEmpty)
                                        .map(name)
                                        .join(' · ')
                                  : context.t('ui.audit769'),
                              style: AppText.caption,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> closedDayControls() => [
    SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(context.t('ui.audit250')),
      value: useClosedDays,
      onChanged: canDraftHours ? toggleClosedDays : null,
    ),
    if (useClosedDays)
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (var d = 1; d <= 7; d++)
            FilterChip(
              showCheckmark: false,
              label: Text(
                context.t(dayNames[d - 1]),
                style: TextStyle(
                  decoration: (days['$d'] as List).isEmpty
                      ? TextDecoration.lineThrough
                      : null,
                ),
              ),
              selected: (days['$d'] as List).isEmpty,
              onSelected: canDraftHours
                  ? (closed) => setClosedDay(d, closed)
                  : null,
            ),
        ],
      ),
  ];

  List<Widget> hours() => [
    WeekdayScopeSelector(
      all: allHours,
      selected: selectedWeekdays,
      openDays: {
        for (var d = 1; d <= 7; d++)
          if ((days['$d'] as List).isNotEmpty) d,
      },
      enabled: canDraftHours,
      onMode: selectHoursScope,
      onDay: (d) => setState(() {
        if (allHours) {
          weekday = d;
          return;
        }
        if (selectedWeekdays.contains(d)) {
          if (selectedWeekdays.length > 1) selectedWeekdays.remove(d);
        } else {
          selectedWeekdays.add(d);
        }
        if (!selectedWeekdays.contains(weekday)) {
          weekday = selectedWeekdays.first;
        }
      }),
    ),
    if (hoursStep == 0 && dayBands.isNotEmpty) ...[
      BusinessHoursSlider(
        shiftControls: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...closedDayControls(),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(context.t('ui.audit251')),
              value: multipleShifts,
              onChanged: canDraftHours
                  ? (value) => preset(value ? 2 : 1)
                  : null,
            ),
            if (multipleShifts)
              Wrap(
                spacing: 4,
                runSpacing: 8,
                children: [
                  for (final entry in {2: '2교대', 3: '3교대'}.entries)
                    ChoiceChip(
                      label: Text(entry.value),
                      selected:
                          dayBands.where((b) => b['custom'] != true).length ==
                          entry.key,
                      onSelected: canDraftHours
                          ? (_) => preset(entry.key)
                          : null,
                    ),
                  IconButton(
                    tooltip: context.t('ui.audit792'),
                    onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(context.t('ui.audit793'))),
                    ),
                    icon: const Icon(Icons.info_outline),
                  ),
                ],
              ),
          ],
        ),
        bands: operatingBands,
        breakTime: breaks['$weekday'] as Json?,
        enabled: canDraftHours,
        onHours: changeHours,
        onBreak: (pause) => update(() {
          for (final d in hoursTargets) {
            if (pause == null) {
              breaks.remove('$d');
            } else {
              final rows = (days['$d'] as List)
                  .cast<Json>()
                  .where((b) => b['custom'] != true)
                  .toList();
              if (rows.isEmpty) continue;
              final start = _minute(rows.first['start']);
              var end = _minute(rows.last['end']);
              if (end <= start) end += 1440;
              var bs = _minute(pause['start']);
              if (bs < start) bs += 1440;
              var be = _minute(pause['end']);
              if (be <= bs) be += 1440;
              bs = bs.clamp(start, end - 30);
              be = be.clamp(bs + 30, end);
              breaks['$d'] = {'start': _time(bs), 'end': _time(be)};
            }
          }
        }),
        onBoundary: (i, minute) => update(() {
          for (final d in hoursTargets) {
            final rows = (days['$d'] as List)
                .cast<Json>()
                .where((b) => b['custom'] != true)
                .toList();
            if (i + 1 >= rows.length) continue;
            var left = _minute(rows[i]['start']);
            final opening = _minute(rows.first['start']);
            if (left < opening) left += 1440;
            var right = _minute(rows[i + 1]['end']);
            if (right <= left) right += 1440;
            if (minute < left + 30 || minute > right - 30) continue;
            rows[i]['end'] = _time(minute);
            rows[i + 1]['start'] = _time(minute);
            rows[i].remove('partTimes');
            rows[i + 1].remove('partTimes');
          }
        }),
      ),
    ],
    if (hoursStep == 1 && dayBands.isNotEmpty) ...[
      hoursHeading(
        '인원 배치',
        '셀의 숫자는 배정 / 필요 인원이에요. 셀을 눌러 인원수와 크루를 수정해요. 전체는 모든 영업일, 개별은 선택한 요일에 적용해요.',
      ),
      staffingMatrix(),
      const SizedBox(height: 16),
    ],
    if (hoursStep == 0 && dayBands.isEmpty) ...closedDayControls(),
    if (dayBands.isEmpty) Information(context.t('ui.audit252')),
  ];
  List<Widget> orderSystem() => [
    SwitchListTile.adaptive(
      contentPadding: EdgeInsets.zero,
      title: Text(context.t('ui.audit253')),
      subtitle: Text(context.t('ui.audit254')),
      value: ops.data?['orderBoardEnabled'] == true,
      onChanged: editable
          ? (v) async {
              await save('save_order_system', {'enabled': v});
            }
          : null,
    ),
    const SizedBox(height: 16),
    Information(context.t('ui.audit255')),
  ];
  List<Widget> partEditor() => [
    Text(context.t('ui.audit256'), style: AppText.title),
    const SizedBox(height: 8),
    Text(context.t('ui.audit257'), style: AppText.caption),
    const SizedBox(height: 24),
    ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      buildDefaultDragHandles: false,
      itemCount: parts.length,
      onReorder: (old, next) => update(() {
        if (next > old) next--;
        parts.insert(next, parts.removeAt(old));
      }),
      itemBuilder: (context, i) => Padding(
        key: ValueKey(parts[i]['id'] ?? 'new-$i'),
        padding: const EdgeInsets.only(bottom: 12),
        child: Surface(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              ReorderableDragStartListener(
                index: i,
                child: const Padding(
                  padding: EdgeInsets.all(12),
                  child: Icon(Icons.drag_handle, color: AppColors.muted),
                ),
              ),
              Expanded(
                child: TextFormField(
                  key: ValueKey('part-name-${parts[i]['id'] ?? i}'),
                  initialValue: parts[i]['name'],
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: context.t('ui.audit258'),
                  ),
                  onChanged: (v) => update(() => parts[i]['name'] = v),
                ),
              ),
              IconButton(
                key: ValueKey('part-translation-${parts[i]['id']}'),
                tooltip: context.t('translation.edit'),
                icon: const Icon(Icons.translate),
                onPressed:
                    editable &&
                        storeParts(ops).any(
                          (p) =>
                              p['id'] == parts[i]['id'] &&
                              p['name'] == parts[i]['name'],
                        )
                    ? () => editEntityNameTranslation(
                        context,
                        ops,
                        'part',
                        parts[i]['id'],
                        parts[i]['name'],
                      )
                    : null,
              ),
              IconButton(
                tooltip: parts[i]['hidden'] == true
                    ? context.t('ui.audit794')
                    : context.t('ui.audit795'),
                onPressed: () => update(
                  () => parts[i]['hidden'] = parts[i]['hidden'] != true,
                ),
                icon: Icon(
                  parts[i]['hidden'] == true
                      ? CupertinoIcons.eye_slash
                      : CupertinoIcons.eye,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
    Row(
      children: [
        Expanded(
          child: TextField(
            controller: partName,
            decoration: InputDecoration(hintText: context.t('ui.audit97')),
            onSubmitted: (_) => addPart(),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: addPart,
          tooltip: context.t('ui.audit99'),
          icon: const Icon(CupertinoIcons.add),
        ),
      ],
    ),
  ];
  void addPart() {
    if (partName.text.trim().isEmpty) return;
    update(() {
      parts.add({'name': partName.text.trim(), 'hidden': false});
      partName.clear();
    });
  }

  List<Widget> permissions() {
    final current = (restrictions[role] as Json?) ?? <String, dynamic>{};
    return [
      Wrap(
        spacing: 8,
        children: [
          for (final e in {'manager': '점장', 'cook': '조리', 'crew': '크루'}.entries)
            ChoiceChip(
              chipAnimationStyle: AppMotion.chipStyle(context),
              label: Text(e.value),
              selected: role == e.key,
              onSelected: saving || dirty
                  ? null
                  : (_) => setState(() => role = e.key),
            ),
        ],
      ),
      const SizedBox(height: 20),
      Information(context.t('ui.audit259')),
      if (dirty && !ops.readOnly)
        Padding(
          padding: EdgeInsets.only(top: 12),
          child: Text(context.t('ui.audit796'), style: AppText.caption),
        ),
      section(context.t('ui.audit1147')),
      Surface(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            for (final e in {
              'tasks': ('할일 관리', '할 일을 만들고 고쳐요'),
              'complete': ('할일 체크', '담당 업무를 완료하고 되돌려요'),
              'schedule': ('근무표 편집', '근무 배정과 패턴을 바꿔요'),
              'stock': ('재고 기입', '수량을 세어 기록해요'),
              'orders': ('발주·입고 기입', '발주와 입고를 기록해요'),
              if (role == 'manager')
                'crew': (
                  context.t('permission.crewInvite'),
                  context.t('permission.crewInviteHelp'),
                ),
            }.entries)
              SettingRow(
                title: e.value.$1,
                subtitle: e.value.$2,
                trailing: Switch(
                  value: e.key == 'crew'
                      ? current[e.key] == true
                      : current[e.key] != false,
                  onChanged: (v) => update(() {
                    restrictions[role] = {...current, e.key: v};
                  }),
                ),
              ),
          ],
        ),
      ),
    ];
  }

  List<Widget> person() => [
    Text('${widget.person?['nickname']}', style: AppText.title),
    section(context.t('ui.audit1148')),
    Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final part in parts.where((p) => p['hidden'] != true))
          FilterChip(
            chipAnimationStyle: AppMotion.chipStyle(context),
            label: Text(
              entityDisplayName(context, ops, 'part', part['id'], part['name']),
            ),
            selected: partIds.contains(part['id']),
            onSelected: (v) => update(() {
              v ? partIds.add(part['id']) : partIds.remove(part['id']);
            }),
          ),
      ],
    ),
    section(context.t('ui.audit1149')),
    Wrap(
      spacing: 8,
      children: [
        for (final name in ['오픈', '미들', '마감'])
          FilterChip(
            chipAnimationStyle: AppMotion.chipStyle(context),
            label: Text(name),
            selected: bands.contains(name),
            onSelected: (v) => update(() {
              v ? bands.add(name) : bands.remove(name);
            }),
          ),
      ],
    ),
    const SizedBox(height: 16),
    Text(context.t('ui.audit260'), style: AppText.caption),
  ];
  List<Widget> invite() => [
    Information(context.t('ui.audit261')),
    const SizedBox(height: 20),
    for (final e in {
      'hourly': '알바용 코드',
      'employee': '크루용 코드',
      'manager': '점장용 코드',
    }.entries)
      Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Builder(
          builder: (context) {
            final code = ops
                .rows('demoInvites')
                .where((i) => i['role'] == e.key)
                .firstOrNull;
            return Surface(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(e.value, style: AppText.caption)),
                      TextButton(
                        onPressed: editable && !ops.cloud
                            ? () => save('create_demo_invite', {'role': e.key})
                            : null,
                        child: Text(context.t('ui.audit262')),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SelectableText(
                    code?['code'] ?? '발급 전',
                    textAlign: TextAlign.center,
                    style: AppText.title.copyWith(
                      fontSize: 32,
                      letterSpacing: 5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    code == null
                        ? context.t('ui.audit797')
                        : context.t(
                            'ui.audit798',
                            args: {
                              'p0': '${code['expiresAt']}'.substring(0, 10),
                            },
                          ),
                    textAlign: TextAlign.center,
                    style: AppText.caption,
                  ),
                  const SizedBox(height: 20),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 12,
                    children: [
                      OutlinedButton.icon(
                        onPressed: code == null
                            ? null
                            : () async {
                                await Clipboard.setData(
                                  ClipboardData(
                                    text: context.t(
                                      'ui.audit2106',
                                      args: {'p0': code['code']},
                                    ),
                                  ),
                                );
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(context.t('ui.audit799')),
                                    ),
                                  );
                                }
                              },
                        icon: const Icon(CupertinoIcons.doc_on_doc),
                        label: Text(context.t('ui.audit263')),
                      ),
                      OutlinedButton.icon(
                        onPressed: code == null
                            ? null
                            : () => showModalBottomSheet<void>(
                                context: context,
                                sheetAnimationStyle: AppMotion.panelStyle(
                                  context,
                                ),
                                showDragHandle: true,
                                builder: (c) => SafeArea(
                                  child: Padding(
                                    padding: const EdgeInsets.all(24),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          context.t('ui.audit264'),
                                          style: AppText.title,
                                        ),
                                        const SizedBox(height: 20),
                                        Flexible(
                                          child: Container(
                                            padding: const EdgeInsets.all(16),
                                            color: Colors.white,
                                            child: QrImageView(
                                              data:
                                                  'tap2work-demo:${code['role']}:${code['code']}',
                                              size: 240,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        SelectableText(
                                          '${code['code']}',
                                          style: AppText.title,
                                        ),
                                        Text(
                                          context.t('ui.audit265'),
                                          style: AppText.caption,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                        icon: const Icon(CupertinoIcons.qrcode),
                        label: Text(context.t('ui.audit266')),
                      ),
                      TextButton(
                        onPressed: code == null || !editable
                            ? null
                            : () => save('revoke_demo_invite', {'role': e.key}),
                        child: Text(context.t('ui.audit267')),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
  ];
  late String attendanceMethod =
      widget.ops.data?['workplace']?['attendancePreferences']?['method'] ??
      'location';
  List<Widget> verification() => [
    Text(context.t('ui.audit268'), style: AppText.title),
    const SizedBox(height: 16),
    Information(context.t('ui.audit269')),
    const SizedBox(height: 16),
    AppPicker<String>(
      label: context.t('ui.audit800'),
      value: attendanceMethod,
      items: [
        DropdownMenuItem(
          value: 'location',
          child: Text(context.t('ui.audit801')),
        ),
        DropdownMenuItem(value: 'wifi', child: Text(context.t('ui.audit802'))),
      ],
      onChanged: editable
          ? (value) => setState(() {
              attendanceMethod = value!;
              dirty = true;
            })
          : null,
    ),
    const SizedBox(height: 16),
    Text(
      attendanceMethod == 'location'
          ? context.t('ui.audit803')
          : context.t('ui.audit804'),
      style: AppText.caption,
    ),
  ];
  bool get hasSaveFooter => const [
    'verification',
    'hours',
    'parts',
    'permissions',
    'person',
  ].contains(widget.section);
  Future<void> saveSection() async {
    switch (widget.section) {
      case 'verification':
        await save('save_attendance_preferences', {'method': attendanceMethod});
      case 'hours':
        final impact = hoursReflowImpact;
        if (impact.isNotEmpty) {
          final accepted = await showAppDialog<bool>(
            context: context,
            builder: (c) => AlertDialog(
              title: Text(context.t('hours.reflowTitle')),
              content: SingleChildScrollView(
                child: Text(
                  '${context.t('hours.reflowHelp')}\n\n${impact.join('\n\n')}',
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(c, false),
                  child: Text(context.t('hours.reflowBack')),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(c, true),
                  child: Text(context.t('hours.reflowSave')),
                ),
              ],
            ),
          );
          if (accepted != true || !mounted) return;
        }
        await save('save_workplace_hours', {
          'days': days,
          'breaks': breaks,
          'businessDayStart': businessDayStart,
          'defaultAssignmentsEnabled': true,
          'resetScheduleWeekdays': hoursTargets.toList(),
        });
      case 'parts':
        await save('save_workplace_parts', {'parts': parts});
        if (mounted && error == null) {
          setState(
            () => parts = (jsonDecode(jsonEncode(storeParts(ops))) as List)
                .cast<Json>(),
          );
        }
      case 'permissions':
        await save('save_workplace_permissions', {
          'role': role,
          'permissions': restrictions[role] ?? {},
        });
      case 'person':
        await save('save_staff_profile', {
          'tapperId': widget.person!['id'],
          'partIds': partIds.toList(),
          'bands': bands.toList(),
        });
    }
  }

  @override
  Widget build(BuildContext context) => widget.section == 'invite' && ops.cloud
      ? CrewInvitationScreen(ops: ops, management: true)
      : PopScope(
          canPop: !dirty && !saving,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) close();
          },
          child: AppEditorScaffold(
            title: titles[widget.section] ?? context.t('ui.audit805'),
            footer: hasSaveFooter
                ? AppSheetFooter(
                    children: [
                      if (widget.section == 'hours' && hoursStep == 1)
                        Text(context.t('ui.audit270'), style: AppText.caption),
                      if (error != null)
                        Text(
                          error!,
                          style: AppText.caption.copyWith(
                            color: AppColors.accent,
                          ),
                        ),
                      FilledButton(
                        onPressed: widget.section == 'hours' && hoursStep < 1
                            ? (saving
                                  ? null
                                  : () => setState(() => hoursStep++))
                            : editable
                            ? saveSection
                            : null,
                        child: Text(
                          saving
                              ? context.t('ui.audit532')
                              : widget.section == 'hours'
                              ? (hoursStep < 1
                                    ? context.t('ui.audit806')
                                    : context.t('ui.audit807'))
                              : context.t('ui.audit51'),
                        ),
                      ),
                    ],
                  )
                : null,
            onClose: close,
            body: Column(
              children: [
                if (widget.section == 'hours')
                  Row(
                    children: [
                      for (var i = 0; i < 2; i++)
                        Expanded(
                          flex: 1,
                          child: Semantics(
                            selected: hoursStep == i,
                            child: TextButton(
                              onPressed: saving
                                  ? null
                                  : () => setState(() => hoursStep = i),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                                foregroundColor: hoursStep == i
                                    ? AppColors.green
                                    : AppColors.muted,
                                shape: const RoundedRectangleBorder(),
                                backgroundColor: hoursStep == i
                                    ? AppColors.lime
                                    : Colors.transparent,
                                minimumSize: const Size(0, 56),
                              ),
                              child: Text(
                                [
                                  context.t('ui.audit808'),
                                  context.t('ui.audit809'),
                                ][i],
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: appEditorWidth,
                      ),
                      child: ListView(
                        padding: const EdgeInsets.all(24),
                        children: [
                          if (ops.readOnly)
                            Padding(
                              padding: EdgeInsets.only(bottom: 16),
                              child: Information(context.t('ui.audit810')),
                            ),
                          ...switch (widget.section) {
                            'order-system' => orderSystem(),
                            'parts' => partEditor(),
                            'hours' => hours(),
                            'permissions' => permissions(),
                            'person' => person(),
                            'invite' => invite(),
                            'verification' => verification(),
                            _ => [Information(context.t('ui.audit271'))],
                          },
                          if (error != null && !hasSaveFooter)
                            Padding(
                              padding: const EdgeInsets.only(top: 16),
                              child: Information(context.t(error!)),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
}
