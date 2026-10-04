import 'business_hours_slider.dart';
import 'dart:convert';
import 'dart:math';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../state/operations_controller.dart';
import 'components.dart';

/// All hours entry points use the same draft, validation and save flow.
Future<void> openWorkplaceHours(
  BuildContext context,
  OperationsController ops,
) => showAppFormSheet<void>(
  context: context,
  builder: (_) => WorkplaceSettings(ops: ops, section: 'hours'),
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

String partLabel(OperationsController ops, dynamic id) =>
    storeParts(ops).where((p) => p['id'] == id).firstOrNull?['name'] ?? '전체 파트';
String crewPartsLabel(OperationsController ops, Json person) {
  final ids = person['workProfile']?['partIds'] as List? ?? [];
  return ids.isEmpty
      ? '전체 파트'
      : ids.map((id) => partLabel(ops, id)).join(' · ');
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
  });
  final OperationsController ops;
  final VoidCallback onHours, onPeople, onTasks, onSchedule;
  @override
  State<StorePreparation> createState() => _StorePreparationState();
}

class _StorePreparationState extends State<StorePreparation> {
  bool collapsed = false;
  @override
  Widget build(BuildContext context) {
    final ops = widget.ops;
    final checks = [
      (
        title: '영업시간 설정',
        done:
            ops.data?['store']?['profile']?['hours'] != null ||
            (ops.data?['workplace']?['days'] as Map? ?? {}).isNotEmpty,
        icon: CupertinoIcons.clock,
        tap: widget.onHours,
      ),
      (
        title: '크루 준비',
        done: ops
            .rows('tappers')
            .where((p) => p['active'] == true && p['rank'] != 'owner')
            .isNotEmpty,
        icon: CupertinoIcons.person_add,
        tap: widget.onPeople,
      ),
      (
        title: '할일 준비',
        done: ops.rows('tasks').isNotEmpty,
        icon: CupertinoIcons.checkmark_alt_circle,
        tap: widget.onTasks,
      ),
      (
        title: '근무 배정',
        done: ops.rows('staffShifts').isNotEmpty,
        icon: CupertinoIcons.calendar,
        tap: widget.onSchedule,
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
                  '매장 준비  ${checks.where((c) => c.done).length}/4',
                  style: AppText.body.copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => setState(() => collapsed = !collapsed),
                child: Text(collapsed ? '펼치기' : '접기'),
              ),
            ],
          ),
          if (!collapsed) ...[
            const Text('하나씩 준비하고, 함께 시작해요.', style: AppText.caption),
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
            content: Text(ok ? '근태를 기록했어요.' : ops.error ?? '기록하지 못했어요.'),
          ),
        );
      }
    }

    return Surface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${own['nickname']}님, ${working
                ? '근무 중이에요'
                : resting
                ? '쉬는 중이에요'
                : shifts.isEmpty
                ? '오늘은 배정이 없어요'
                : '오늘도 함께해요'}',
            style: AppText.body.copyWith(
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            shifts.isEmpty
                ? '배정이 없어도 출근을 기록할 수 있어요.'
                : shifts
                      .map(
                        (s) =>
                            '${s['start']}–${s['end']} · ${partLabel(ops, s['partId'])}',
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
                    label: const Text('출근하기'),
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
                    child: const Text('퇴근하기'),
                  ),
                ),
              if (working || resting)
                PressBounce(
                  child: OutlinedButton(
                    onPressed: ops.readOnly || ops.busy
                        ? null
                        : () => act(resting ? 'break_end' : 'break_start'),
                    child: Text(resting ? '휴게 종료' : '휴게 시작'),
                  ),
                ),
            ],
          ),
          if (ops.readOnly)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: Text('미리보기 · 근태 기록은 저장되지 않아요.', style: AppText.caption),
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
  });
  final OperationsController ops;
  final String section;
  final Json? person;
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
                [b['name'], b['start'], b['end'], b['headcounts']],
            ]),
      ];
      allHours = signatures.toSet().length <= 1;
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
  late bool useClosedDays = days.values.any((rows) => (rows as List).isEmpty);
  final Map<int, List<Json>> openDayDrafts = {};
  final Map<int, Json> openBreakDrafts = {};

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
      breaks.remove('$day');
      if (weekday == day) {
        weekday =
            [
              for (var d = 1; d <= 7; d++)
                if ((days['$d'] as List).isNotEmpty) d,
            ].firstOrNull ??
            day;
      }
    } else {
      days['$day'] = reopenedDay(day);
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
        title: const Text('변경을 버릴까요?'),
        content: const Text('아직 저장하지 않은 내용이 있어요.'),
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
    if (discard == true && mounted) {
      setState(() => dirty = false);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.pop(context);
      });
    }
  }

  Future<void> save(String action, Json values) async {
    if (!editable) {
      setState(() => error = '계정이 바뀌었어요. 닫고 다시 열어 주세요.');
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
      } else {
        error = '${ops.error}\n입력한 내용은 그대로 남아 있어요.';
      }
    });
    if (ok) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('저장했어요.')));
    }
  }

  Widget saveButton(VoidCallback onSave, {String label = '저장'}) => Padding(
    padding: const EdgeInsets.only(top: 24),
    child: SizedBox(
      width: double.infinity,
      child: PressBounce(
        child: FilledButton(
          onPressed: editable ? onSave : null,
          child: Text(saving ? '저장 중…' : label),
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
          () => error =
              '${dayNames[d - 1]}요일의 영업시간과 추가 시간대를 확인해 주세요. 교대마다 30분 이상 필요해요.',
        );
        return;
      }
    }
    final retained = base
        .skip(count)
        .where((b) => linkedIds.contains(b['id']))
        .toList();
    if (count + custom.length + retained.length > 24) {
      setState(() => error = '요일별 시간대는 최대 24개예요.');
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
      setState(() => error = '시간대당 30분 이상 필요해요.');
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
          error = '${dayNames[d - 1]}요일은 시간대당 30분 이상 필요해요.';
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
      : [weekday];
  void changeHours(int start, int end) => update(() {
    for (final d in hoursTargets) {
      final rows = (days['$d'] as List).cast<Json>();
      final base = rows.where((b) => b['custom'] != true).toList();
      final bands = base.isEmpty ? rows : base;
      if (end - start < bands.length * 30) continue;
      final cuts = shiftBoundaries(start, end, bands.length.clamp(1, 3));
      if (bands.length > 3) continue;
      for (var i = 0; i < bands.length; i++) {
        bands[i]['start'] = _time(cuts[i]);
        bands[i]['end'] = _time(cuts[i + 1]);
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
        tooltip: '$title 도움말',
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

  Future<void> editCount(int index, Json part) async {
    var count = countFor(dayBands[index], part['id']);
    final value = await showAppDialog<int>(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (c, refresh) => AlertDialog(
          title: Text('${bandLabel(dayBands[index])} · ${part['name']}'),
          content: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                tooltip: '인원 줄이기',
                onPressed: count > 0 ? () => refresh(() => count--) : null,
                icon: const Icon(Icons.remove),
              ),
              Text('$count명', style: AppText.title),
              IconButton(
                tooltip: '인원 늘리기',
                onPressed: count < 12 ? () => refresh(() => count++) : null,
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(c, count),
              child: const Text('적용'),
            ),
          ],
        ),
      ),
    );
    if (value == null || !mounted || !canDraftHours) return;
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
        target['headcounts'][part['id']] = value;
      }
    });
  }

  Widget staffingMatrix() {
    final visibleParts = parts.where((p) => p['hidden'] != true).toList();
    return LayoutBuilder(
      builder: (context, constraints) {
        final scale = MediaQuery.textScalerOf(context).scale(1);
        final width = max(
          constraints.maxWidth,
          (visibleParts.length + 1) * 68.0 * scale,
        );
        Widget label(String text) => Padding(
          padding: const EdgeInsets.all(12),
          child: Text(text, textAlign: TextAlign.center),
        );
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: width,
            child: Table(
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              border: TableBorder.all(
                color: AppColors.muted.withValues(alpha: .25),
              ),
              children: [
                TableRow(
                  decoration: const BoxDecoration(color: AppColors.elevated),
                  children: [
                    label('교대'),
                    for (final p in visibleParts) label(p['name']),
                  ],
                ),
                for (var i = 0; i < dayBands.length; i++)
                  TableRow(
                    children: [
                      label(bandLabel(dayBands[i])),
                      for (final p in visibleParts)
                        Semantics(
                          label: '${bandLabel(dayBands[i])} ${p['name']} 필요 인원',
                          child: TextButton(
                            onPressed: canDraftHours
                                ? () => editCount(i, p)
                                : null,
                            style: TextButton.styleFrom(
                              minimumSize: const Size(48, 56),
                            ),
                            child: Text('${countFor(dayBands[i], p['id'])}'),
                          ),
                        ),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<Widget> closedDayControls() => [
    SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: const Text('휴무일'),
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
                dayNames[d - 1],
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
    ...[
      Wrap(
        spacing: 8,
        children: [
          for (final mode in [true, false])
            SizedBox(
              width: 124,
              child: CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: Text(mode ? '전체' : '개별'),
                value: allHours == mode,
                onChanged: canDraftHours
                    ? (_) => setState(() => allHours = mode)
                    : null,
              ),
            ),
        ],
      ),
      if (!allHours)
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var d = 1; d <= 7; d++)
              if ((days['$d'] as List).isNotEmpty)
                ChoiceChip(
                  showCheckmark: false,
                  label: Text(dayNames[d - 1]),
                  selected: weekday == d,
                  onSelected: saving
                      ? null
                      : (_) => setState(() => weekday = d),
                ),
          ],
        ),
    ],
    if (hoursStep == 0 && dayBands.isNotEmpty) ...[
      BusinessHoursSlider(
        shiftControls: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...closedDayControls(),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('2교대 이상'),
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
                    tooltip: '시간 조정 도움말',
                    onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          '구분선이나 시간을 끌어 30분 단위로 조정해요. 시간을 누르면 숫자로 선택할 수 있어요. 전체는 모든 영업일에 적용해요.',
                        ),
                      ),
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
          }
        }),
      ),
    ],
    if (hoursStep == 1 && dayBands.isNotEmpty) ...[
      hoursHeading(
        '인원 배치',
        '셀을 눌러 필요한 인원을 입력해요. 전체는 모든 영업일의 같은 교대에 적용해요. 기존 시간대와 파트별 설정은 유지돼요.',
      ),
      staffingMatrix(),
      const SizedBox(height: 16),
    ],
    if (hoursStep == 0 && dayBands.isEmpty) ...closedDayControls(),
    if (dayBands.isEmpty) const Information('휴무일이에요. 영업시간 설정에서 휴무일을 해제해 주세요.'),
  ];
  List<Widget> orderSystem() => [
    SwitchListTile.adaptive(
      contentPadding: EdgeInsets.zero,
      title: const Text('주문처리 보드 사용'),
      subtitle: const Text('켜면 업무 메뉴에 주문처리 보드가 나타나요.'),
      value: ops.data?['orderBoardEnabled'] == true,
      onChanged: editable
          ? (v) async {
              await save('save_order_system', {'enabled': v});
            }
          : null,
    ),
    const SizedBox(height: 16),
    const Information('외부 주문 시스템은 아직 연결되지 않았어요. 보드에서는 예시 주문만 확인할 수 있어요.'),
  ];
  List<Widget> partEditor() => [
    const Text('파트로 나누면 더 간단해요', style: AppText.title),
    const SizedBox(height: 8),
    const Text('크루과 할 일을 파트별로 살펴보세요. 숨겨도 기존 기록은 남아요.', style: AppText.caption),
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
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: '파트 이름',
                  ),
                  onChanged: (v) => update(() => parts[i]['name'] = v),
                ),
              ),
              IconButton(
                tooltip: parts[i]['hidden'] == true ? '파트 표시' : '파트 숨기기',
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
            decoration: const InputDecoration(hintText: '새 파트 이름'),
            onSubmitted: (_) => addPart(),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: addPart,
          tooltip: '파트 추가',
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
      const Information(
        '사장은 항상 허용돼요. 켠 항목도 기존 직책의 권한 범위 안에서만 사용할 수 있어요. 급여·시급은 사장님만 볼 수 있어요.',
      ),
      if (dirty && !ops.readOnly)
        const Padding(
          padding: EdgeInsets.only(top: 12),
          child: Text('저장한 뒤 다른 직책을 선택할 수 있어요.', style: AppText.caption),
        ),
      section('운영 권한'),
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
            }.entries)
              SettingRow(
                title: e.value.$1,
                subtitle: e.value.$2,
                trailing: Switch(
                  value: current[e.key] != false,
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
    section('담당 파트 · 미선택 시 전체 파트 가능'),
    Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final part in parts.where((p) => p['hidden'] != true))
          FilterChip(
            chipAnimationStyle: AppMotion.chipStyle(context),
            label: Text(part['name']),
            selected: partIds.contains(part['id']),
            onSelected: (v) => update(() {
              v ? partIds.add(part['id']) : partIds.remove(part['id']);
            }),
          ),
      ],
    ),
    section('시간대 · 선택하지 않으면 전체'),
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
    const Text(
      '활동 파트와 선호 시간대예요. 실제 근무는 근무표에 별도로 배정해 주세요.',
      style: AppText.caption,
    ),
  ];
  List<Widget> invite() => [
    const Information('체험용 초대 코드예요. 실제 계정 가입·권한 부여·메시지 발송은 연결되지 않았어요.'),
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
                        child: const Text('새 코드'),
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
                        ? '코드를 만들면 7일 동안 표시돼요.'
                        : '만료 ${'${code['expiresAt']}'.substring(0, 10)} · 체험 전용',
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
                                    text:
                                        'tap2work 체험 코드: ${code['code']} (실제 가입 불가)',
                                  ),
                                );
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('체험 코드를 복사했어요.'),
                                    ),
                                  );
                                }
                              },
                        icon: const Icon(CupertinoIcons.doc_on_doc),
                        label: const Text('복사'),
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
                                        const Text(
                                          'QR 초대 · 체험',
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
                                        const Text(
                                          '체험 코드만 담겨 있어요. 실제 가입 링크가 아니에요.',
                                          style: AppText.caption,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                        icon: const Icon(CupertinoIcons.qrcode),
                        label: const Text('QR 보기'),
                      ),
                      TextButton(
                        onPressed: code == null || !editable
                            ? null
                            : () => save('revoke_demo_invite', {'role': e.key}),
                        child: const Text('폐기'),
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
  List<Widget> verification() => [
    const Text('출퇴근을 정확하게', style: AppText.title),
    const SizedBox(height: 16),
    const Information('현재는 서버에 출퇴근 시각을 기록해요. 위치·Wi-Fi 인증은 아직 연결되지 않았어요.'),
    section('인증 수단'),
    const Surface(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          SettingRow(
            title: '위치로 출퇴근 인증',
            subtitle: '매장 좌표·기기 권한·서버 검증 연결 필요',
            icon: CupertinoIcons.location,
            trailing: Icon(CupertinoIcons.lock, color: AppColors.muted),
          ),
          Divider(height: 1),
          SettingRow(
            title: '매장 Wi-Fi',
            subtitle: '네이티브 기기 연동 필요 · 웹에서는 확인 불가',
            icon: CupertinoIcons.wifi,
            trailing: Icon(CupertinoIcons.lock, color: AppColors.muted),
          ),
        ],
      ),
    ),
  ];
  bool get hasSaveFooter => const [
    'hours',
    'parts',
    'permissions',
    'person',
  ].contains(widget.section);
  Future<void> saveSection() async {
    switch (widget.section) {
      case 'hours':
        await save('save_workplace_hours', {
          'days': days,
          'breaks': breaks,
          'businessDayStart': businessDayStart,
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
  Widget build(BuildContext context) => PopScope(
    canPop: !dirty && !saving,
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop) close();
    },
    child: AppEditorScaffold(
      title: titles[widget.section] ?? '매장 설정',
      footer: hasSaveFooter
          ? AppSheetFooter(
              children: [
                if (error != null)
                  Text(
                    error!,
                    style: AppText.caption.copyWith(color: AppColors.accent),
                  ),
                FilledButton(
                  onPressed: widget.section == 'hours' && hoursStep < 1
                      ? (saving ? null : () => setState(() => hoursStep++))
                      : editable
                      ? saveSection
                      : null,
                  child: Text(
                    saving
                        ? '저장 중…'
                        : widget.section == 'hours'
                        ? (hoursStep < 1 ? '다음 단계' : '일주일 설정 저장')
                        : '저장',
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
                          padding: const EdgeInsets.symmetric(horizontal: 8),
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
                          ['영업시간 설정', '인원 배치'][i],
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
                constraints: const BoxConstraints(maxWidth: appEditorWidth),
                child: ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    if (ops.readOnly)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 16),
                        child: Information('미리보기 · 편집을 살펴볼 수 있지만 저장하지 않아요.'),
                      ),
                    ...switch (widget.section) {
                      'order-system' => orderSystem(),
                      'parts' => partEditor(),
                      'hours' => hours(),
                      'permissions' => permissions(),
                      'person' => person(),
                      'invite' => invite(),
                      'verification' => verification(),
                      _ => [
                        const Information(
                          '문서 보관은 보안 저장소 연결 후 사용할 수 있어요. 실제 보건증을 체험 매장에 올리지 마세요.',
                        ),
                      ],
                    },
                    if (error != null && !hasSaveFooter)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Information(error!),
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
