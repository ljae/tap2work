import 'dart:convert';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../state/operations_controller.dart';
import 'components.dart';

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
        title: '직원 준비',
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
  }

  late List<Json> parts =
      (jsonDecode(jsonEncode(storeParts(widget.ops))) as List).cast<Json>();
  late Json days = initialDays();
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
                {'name': '전체', 'start': '09:00', 'end': '22:00'},
              ]
            : <Json>[],
      );
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
  bool get editable => ops.isOwner && !ops.readOnly && !saving && !ops.busy;
  static const titles = {
    'order-system': '주문처리 시스템 연결',
    'parts': '파트 관리',
    'hours': '영업시간·필요 인원',
    'permissions': '직책별 권한',
    'person': '파트·시간대 수정',
    'invite': '직원 초대',
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
      Navigator.pop(context);
    }
  }

  Future<void> save(String action, Json values) async {
    if (ops.actorId != actorId) {
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
  void preset(int count) {
    final hours = ops.data?['store']?['profile']?['hours'] as Json? ?? {};
    final start = _minute(
      dayBands.firstOrNull?['start'] ?? hours['opening'] ?? '09:00',
    );
    var end = _minute(
      dayBands.lastOrNull?['end'] ?? hours['closing'] ?? '22:00',
    );
    if (end <= start) end += 1440;
    if (end - start < count * 30) {
      setState(() => error = '시간대당 30분 이상 필요해요.');
      return;
    }
    final names = count == 1
        ? ['전체']
        : count == 2
        ? ['오픈', '마감']
        : ['오픈', '미들', '마감'];
    update(
      () => days['$weekday'] = [
        for (var i = 0; i < count; i++)
          {
            'name': names[i],
            'start': _time(
              start + ((end - start) * i / count / 30).round() * 30,
            ),
            'end': i == count - 1
                ? _time(end)
                : _time(
                    start + ((end - start) * (i + 1) / count / 30).round() * 30,
                  ),
          },
      ],
    );
  }

  static int _minute(String time) {
    final p = time.split(':').map(int.parse).toList();
    return p[0] * 60 + p[1];
  }

  static String _time(int minute) =>
      '${(minute ~/ 60 % 24).toString().padLeft(2, '0')}:${(minute % 60).toString().padLeft(2, '0')}';
  Future<void> editBoundary(int index, bool start) async {
    final row = dayBands[index];
    final value = _minute(row[start ? 'start' : 'end']);
    final chosen = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: value ~/ 60, minute: value % 60),
    );
    if (chosen == null || !mounted) return;
    if (chosen.minute != 0 && chosen.minute != 30) {
      setState(() => error = '00분 또는 30분을 선택해 주세요.');
      return;
    }
    final text = _time(chosen.hour * 60 + chosen.minute);
    update(() {
      row[start ? 'start' : 'end'] = text;
      if (start && index > 0) dayBands[index - 1]['end'] = text;
      if (!start && index + 1 < dayBands.length) {
        dayBands[index + 1]['start'] = text;
      }
    });
  }

  bool get canDraftHours => ops.isOwner && !saving && !ops.busy;
  static const dayNames = ['월', '화', '수', '목', '금', '토', '일'];
  List<Widget> hours() => [
    const Text('1. 휴무일을 선택해 주세요', style: AppText.title),
    const SizedBox(height: 16),
    Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (var d = 1; d <= 7; d++)
          FilterChip(
            label: Text(dayNames[d - 1]),
            selected: (days['$d'] as List).isEmpty,
            onSelected: canDraftHours
                ? (closed) => update(() {
                    days['$d'] = closed
                        ? <Json>[]
                        : <Json>[
                            {'name': '전체', 'start': '09:00', 'end': '22:00'},
                          ];
                    if (!closed) weekday = d;
                  })
                : null,
          ),
      ],
    ),
    const SizedBox(height: 8),
    const Text(
      '선택한 요일은 매장 휴무예요. 공휴일 표시는 영업 여부를 바꾸지 않아요.',
      style: AppText.caption,
    ),
    section('2. 영업일의 교대와 시간을 정해 주세요'),
    Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (var d = 1; d <= 7; d++)
          if ((days['$d'] as List).isNotEmpty)
            ChoiceChip(
              label: Text(dayNames[d - 1]),
              selected: weekday == d,
              onSelected: saving ? null : (_) => setState(() => weekday = d),
            ),
      ],
    ),
    const SizedBox(height: 16),
    if (dayBands.isEmpty)
      const Information('휴무일이에요. 위에서 영업일을 선택하거나 휴무를 해제해 주세요.'),
    if (dayBands.isNotEmpty) ...[
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final entry in {1: '한 타임', 2: '2교대', 3: '3교대'}.entries)
            ChoiceChip(
              label: Text(entry.value),
              selected: dayBands.length == entry.key,
              onSelected: canDraftHours ? (_) => preset(entry.key) : null,
            ),
        ],
      ),
      const SizedBox(height: 16),
      for (var i = 0; i < dayBands.length; i++)
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Surface(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${dayBands[i]['name']}', style: AppText.body),
                Wrap(
                  spacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    TextButton(
                      onPressed: canDraftHours
                          ? () => editBoundary(i, true)
                          : null,
                      child: Text('${dayBands[i]['start']}'),
                    ),
                    const Text('–'),
                    TextButton(
                      onPressed: canDraftHours
                          ? () => editBoundary(i, false)
                          : null,
                      child: Text('${dayBands[i]['end']}'),
                    ),
                    if (_minute(dayBands[i]['end']) <=
                        _minute(dayBands[i]['start']))
                      const Text('다음 날', style: AppText.caption),
                  ],
                ),
                const SizedBox(height: 8),
                for (final part in parts.where((p) => p['hidden'] != true))
                  Row(
                    children: [
                      Expanded(
                        child: Text('${part['name']}', style: AppText.caption),
                      ),
                      IconButton(
                        tooltip: '${part['name']} 인원 줄이기',
                        onPressed:
                            canDraftHours &&
                                ((dayBands[i]['headcounts']
                                            as Map?)?[part['id']] ??
                                        1) >
                                    0
                            ? () => changeCount(i, part['id'], -1)
                            : null,
                        icon: const Icon(Icons.remove),
                      ),
                      Text(
                        '${(dayBands[i]['headcounts'] as Map?)?[part['id']] ?? 1}명',
                      ),
                      IconButton(
                        tooltip: '${part['name']} 인원 늘리기',
                        onPressed:
                            canDraftHours &&
                                ((dayBands[i]['headcounts']
                                            as Map?)?[part['id']] ??
                                        1) <
                                    12
                            ? () => changeCount(i, part['id'], 1)
                            : null,
                        icon: const Icon(Icons.add),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      OutlinedButton(
        onPressed: canDraftHours
            ? () => update(() {
                for (var d = 1; d <= 7; d++) {
                  if ((days['$d'] as List).isNotEmpty && d != weekday) {
                    days['$d'] = jsonDecode(jsonEncode(dayBands));
                  }
                }
              })
            : null,
        child: const Text('다른 영업일에 복사'),
      ),
    ],
    const SizedBox(height: 16),
    const Text(
      '시간·필요 인원은 기본 슬롯에 반영돼요. 이미 배정한 근무는 유지돼요. 파트 이름과 추가·숨김은 파트 관리에서 변경해요.',
      style: AppText.caption,
    ),
  ];
  void changeCount(int index, String id, int delta) => update(() {
    dayBands[index]['headcounts'] ??= <String, dynamic>{};
    final counts = dayBands[index]['headcounts'] as Map;
    counts[id] = (counts[id] ?? 1) + delta;
  });
  List<Widget> orderSystem() => [
    const Text('주문처리 시스템 연결', style: AppText.title),
    const SizedBox(height: 16),
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
    const Text('직원과 할 일을 파트별로 살펴보세요. 숨겨도 기존 기록은 남아요.', style: AppText.caption),
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
    saveButton(() async {
      await save('save_workplace_parts', {'parts': parts});
      if (mounted && error == null) {
        setState(
          () => parts = (jsonDecode(jsonEncode(storeParts(ops))) as List)
              .cast<Json>(),
        );
      }
    }),
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
      saveButton(
        () => save('save_workplace_permissions', {
          'role': role,
          'permissions': restrictions[role] ?? {},
        }),
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
    saveButton(
      () => save('save_staff_profile', {
        'tapperId': widget.person!['id'],
        'partIds': partIds.toList(),
        'bands': bands.toList(),
      }),
    ),
  ];
  List<Widget> invite() => [
    const Information('체험용 초대 코드예요. 실제 계정 가입·권한 부여·메시지 발송은 연결되지 않았어요.'),
    const SizedBox(height: 20),
    for (final e in {
      'hourly': '알바용 코드',
      'employee': '직원용 코드',
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
  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !dirty,
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop) close();
    },
    child: AppEditorScaffold(
      title: titles[widget.section] ?? '매장 설정',
      footer: widget.section == 'hours'
          ? AppSheetFooter(
              children: [
                if (error != null)
                  Text(
                    error!,
                    style: AppText.caption.copyWith(color: AppColors.accent),
                  ),
                FilledButton(
                  onPressed: editable
                      ? () => save('save_workplace_hours', {'days': days})
                      : null,
                  child: Text(saving ? '저장 중…' : '일주일 설정 저장'),
                ),
              ],
            )
          : null,
      onClose: close,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
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
              if (error != null && widget.section != 'hours')
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Information(error!),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}
