import 'dart:convert';
import 'package:flutter/material.dart';
import '../domain/part_schedule.dart';
import '../domain/crew_allocation.dart';
import '../state/operations_controller.dart';
import 'components.dart';
import 'crew_allocation_components.dart';
import 'weekday_scope_selector.dart';
import 'workplace_screens.dart';

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
  late final Json workplace = copyAllocation(ops.data?['workplace'] ?? {});
  late DateTime monday = widget.day.subtract(
    Duration(days: widget.day.weekday - 1),
  );
  late DateTime from = DateTime.parse(
    ops.data?['day'] ?? rosterDate(widget.day),
  );
  late DateTime until = from.add(const Duration(days: 27));
  Map<String, Json> patterns = {}, saved = {};
  final Set<String> changed = {};
  final Set<int> selected = {};
  AllocationSuggestion? ghost;
  String? error;
  bool saving = false, all = false;
  bool get editable =>
      ops.isLeader &&
      ops.data?['canEditSchedule'] != false &&
      !ops.readOnly &&
      !ops.busy &&
      !saving &&
      actor == ops.actorId;
  List<Json> get people =>
      ops.rows('tappers').where((p) => p['active'] != false).toList();
  CrewAllocationPlanner get planner => CrewAllocationPlanner(
    workplace: workplace,
    people: people,
    monday: monday,
  );
  Set<int> get days => all ? planner.openDays : selected;
  Map<String, Json> get shown => ghost?.patterns ?? patterns;
  String name(String id) =>
      people.where((p) => p['id'] == id).firstOrNull?['nickname'] ?? '크루';
  String dayLabel(Iterable<int> values) => (values.toList()..sort())
      .map((d) => ['월', '화', '수', '목', '금', '토', '일'][d - 1])
      .join('·');
  @override
  void initState() {
    super.initState();
    for (final person in people) {
      final id = person['id'] as String;
      patterns[id] = copyAllocation(
        ops
                .rows('crewPatterns')
                .where((p) => p['tapperId'] == id)
                .firstOrNull ??
            {
              'tapperId': id,
              'cycleWeeks': 1,
              'anchor': rosterDate(monday),
              'entries': <Json>[],
            },
      );
    }
    saved = copyPatterns(patterns);
    if (planner.openDays.isNotEmpty) {
      selected.add(
        planner.openDays.contains(widget.day.weekday)
            ? widget.day.weekday
            : planner.openDays.first,
      );
    }
  }

  Set<String> get pendingIds => {
    ...changed,
    for (final p in ops.rows('crewPatterns'))
      if (patterns.containsKey(p['tapperId']) &&
          p['hoursVersion'] != (workplace['hoursVersion'] ?? 0))
        p['tapperId'] as String,
  };
  void replaceDraft(Map<String, Json> next) {
    for (final id in patterns.keys) {
      if (jsonEncode(patterns[id]) != jsonEncode(next[id])) changed.add(id);
    }
    patterns = next;
    error = null;
  }

  Future<void> save() async {
    if (!editable) return;
    final next = ghost?.patterns ?? patterns;
    final ids = {
      ...pendingIds,
      for (final id in next.keys)
        if (jsonEncode(next[id]) != jsonEncode(patterns[id])) id,
    };
    if (ids.isEmpty) {
      setState(() => ghost = null);
      return;
    }
    setState(() => saving = true);
    final ok = await ops.act('save_crew_allocations', {
      'revision': revision,
      'patterns': [for (final id in ids) next[id]],
    });
    if (!mounted) return;
    setState(() {
      saving = false;
      error = ok ? null : ops.error;
      if (ok) {
        patterns = copyPatterns(next);
        for (final p in ops.rows('crewPatterns')) {
          if (patterns.containsKey(p['tapperId'])) {
            patterns[p['tapperId']] = copyAllocation(p);
          }
        }
        saved = copyPatterns(patterns);
        revision = ops.data!['revision'];
        changed.clear();
        ghost = null;
      }
    });
  }

  Future<void> pick(List<AllocationTarget> targets) async {
    if (!editable || ghost != null) return;
    final plans = <String, AllocationPlan>{};
    for (final person in people) {
      final id = person['id'] as String;
      final plan = planner.assign(patterns, id, targets);
      if (plan.valid &&
          jsonEncode(plan.patterns[id]) != jsonEncode(patterns[id])) {
        plans[id] = plan;
      }
    }
    final id = await showAppSheet<String>(
      context,
      builder: (c) => ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            '${partLabel(ops, targets.first.partId)} 크루 선택',
            style: AppText.title,
          ),
          Text(
            '${dayLabel(targets.map((t) => t.day).toSet())}에 함께 배정 · 예상 주간 시간',
            style: AppText.caption,
          ),
          if (plans.isEmpty)
            const Information(
              '선택한 모든 요일에 배정할 수 있는 크루가 없어요. 담당 파트·정원·겹치는 시간을 확인하거나 요일을 나누어 선택해 주세요.',
            ),
          for (final entry in plans.entries)
            ListTile(
              title: Text(name(entry.key)),
              subtitle: Text(
                '예상 ${planner.summary(entry.value.patterns[entry.key]!).label}${planner.summary(entry.value.patterns[entry.key]!).hint == null ? '' : ' · ${planner.summary(entry.value.patterns[entry.key]!).hint}'}',
              ),
              onTap: () => Navigator.pop(c, entry.key),
            ),
        ],
      ),
    );
    if (id != null && mounted && editable) {
      setState(() => replaceDraft(plans[id]!.patterns));
    }
  }

  Future<void> removeCrew(
    String id,
    List<AllocationTarget> targets, {
    Json? legacy,
  }) async {
    if (!editable || ghost != null) return;
    final yes = await showAppSheet<bool>(
      context,
      builder: (c) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('${name(id)} 배정', style: AppText.title),
            Text(
              '${dayLabel(legacy == null ? targets.map((t) => t.day).toSet() : [legacy['weekday'] as int])} · 선택 범위의 배정만 해제해요.',
              style: AppText.caption,
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () => Navigator.pop(c, true),
              child: const Text('배정 해제'),
            ),
          ],
        ),
      ),
    );
    if (yes == true && mounted && editable) {
      setState(() {
        final next = legacy == null
            ? planner.remove(patterns, id, targets)
            : copyPatterns(patterns);
        if (legacy != null) {
          (next[id]!['entries'] as List).removeWhere(
            (e) => jsonEncode(e) == jsonEncode(legacy),
          );
        }
        replaceDraft(next);
      });
    }
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
    if (changed.isNotEmpty || ghost != null) {
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
      setState(() {
        changed.clear();
        ghost = null;
      });
      Navigator.pop(context);
    }
  }

  Widget partCard(AllocationGroup group, Json part, int index) {
    final targets = group.targets.where((t) => t.partId == part['id']).toList();
    final members = planner.members(shown, targets);
    final vacancies = targets
        .map((t) => t.capacity - planner.assigned(shown, t).length)
        .fold<int>(0, (a, b) => a > b ? a : b);
    final detail = {
      for (final t in targets) '${t.start}–${t.end} · ${t.capacity}명',
    };
    return AllocationPartCard(
      key: ValueKey('allocation-${group.id}-${part['id']}'),
      title: part['name'],
      index: index,
      ghost: ghost != null,
      children: [
        Text(
          detail.length == 1
              ? detail.first
              : targets
                    .map(
                      (t) =>
                          '${dayLabel([t.day])} ${t.start}–${t.end} · ${t.capacity}명',
                    )
                    .join('\n'),
          style: AppText.caption,
        ),
        if (members.isNotEmpty)
          Wrap(
            spacing: 8,
            children: [
              for (final member in members.entries)
                ActionChip(
                  label: Text(
                    '${name(member.key)}${member.value.length == targets.map((t) => t.day).toSet().length ? '' : ' · ${dayLabel(member.value)}'}',
                    style: const TextStyle(color: AppColors.ink),
                  ),
                  onPressed: editable && ghost == null
                      ? () => removeCrew(member.key, targets)
                      : null,
                ),
            ],
          ),
        for (var n = 0; n < vacancies; n++)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: AllocationEmptySlot(
              key: ValueKey('empty-${group.id}-${part['id']}-$n'),
              label: '${group.name} ${part['name']} 크루 배정',
              onTap: editable && ghost == null ? () => pick(targets) : null,
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final groups = planner.groups(days);
    final unmatched = planner.unmatched(shown, days);
    return PopScope(
      canPop: changed.isEmpty && ghost == null && !saving,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) close();
      },
      child: AppEditorScaffold(
        title: '크루별 근무 배정',
        onClose: close,
        footer: AppSheetFooter(
          children: [
            FilledButton(
              onPressed:
                  editable &&
                      (ghost != null
                          ? ghost!.proposed > 0
                          : pendingIds.isNotEmpty)
                  ? save
                  : null,
              child: Text(
                saving
                    ? '저장 중…'
                    : ghost != null
                    ? '배정 확정'
                    : '기본 배정 저장',
              ),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              '1 영업시간·인원 → 2 크루 배정 → 3 근무표 조정',
              style: AppText.caption,
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final p in people)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: CrewHoursBadge(
                        name: name(p['id']),
                        hours: planner.summary(shown[p['id']]!),
                      ),
                    ),
                ],
              ),
            ),
            if (people.isEmpty) const Information('크루를 먼저 등록해 주세요.'),
            ExpansionTile(
              minTileHeight: 40,
              dense: true,
              tilePadding: EdgeInsets.zero,
              title: const Text(
                '선택 주 기본 배정 시간 · 휴게 미반영',
                style: AppText.caption,
              ),
              children: const [
                Text(
                  '15h는 주휴 조건을 확인하는 참고선이에요. 실제 주휴 여부는 4주 평균 소정근로시간·출근 등 조건을 확인해야 해요. 36h부터 주 40h 근접 표시를 해요. 실제 근로·급여 계산은 별도이며 매장 브레이크는 자동 차감하지 않아요.',
                  style: AppText.caption,
                ),
                Text(
                  '기본 배정을 저장한 뒤 기간을 정해 근무표에 적용해 주세요. 앞 설정이 바뀌면 다시 적용해야 해요.',
                  style: AppText.caption,
                ),
              ],
            ),
            Row(
              children: [
                IconButton(
                  tooltip: '이전 주',
                  onPressed: saving || ghost != null
                      ? null
                      : () => setState(
                          () =>
                              monday = monday.subtract(const Duration(days: 7)),
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
                  onPressed: saving || ghost != null
                      ? null
                      : () => setState(
                          () => monday = monday.add(const Duration(days: 7)),
                        ),
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
            WeekdayScopeSelector(
              all: all,
              selected: selected,
              openDays: planner.openDays,
              enabled: !saving && ghost == null,
              onMode: (v) => setState(() => all = v),
              onDay: (d) => setState(() {
                if (all) return;
                if (selected.contains(d)) {
                  if (selected.length > 1) selected.remove(d);
                } else {
                  selected.add(d);
                }
              }),
            ),
            OutlinedButton.icon(
              icon: const Icon(Icons.history),
              label: const Text('이전 스케줄 불러오기'),
              onPressed: editable && days.isNotEmpty && ghost == null
                  ? () => setState(() {
                      ghost = planner.suggest(patterns, saved, days);
                      error = null;
                    })
                  : null,
            ),
            if (ghost != null) ...[
              Information(
                '미리보기 ${ghost!.proposed}개 · ${dayLabel(days)}의 기존 배정을 교체해요.${ghost!.skipped > 0 ? '\n현재 파트·시간·정원에 맞지 않는 ${ghost!.skipped}개는 제외돼요.' : ''}${ghost!.proposed == 0 ? '\n불러올 수 있는 이전 배정이 없어요.' : '\n확정 후 근무표에는 별도로 적용해 주세요.'}',
              ),
              TextButton(
                onPressed: saving ? null : () => setState(() => ghost = null),
                child: const Text('미리보기 취소'),
              ),
            ],
            for (final group in groups) ...[
              const SizedBox(height: 16),
              Text('${group.name} · ${group.timeLabel}', style: AppText.title),
              const SizedBox(height: 8),
              for (var i = 0; i < planner.parts.length; i++)
                if (group.targets.any(
                  (t) => t.partId == planner.parts[i]['id'],
                ))
                  partCard(group, planner.parts[i], i),
            ],
            for (final row in unmatched)
              AllocationPartCard(
                title:
                    '${row.entry['start']}–${row.entry['end']} · ${partLabel(ops, row.entry['partId'])}',
                index: 0,
                children: [
                  const Text('변경 전 시간 · 현재 슬롯과 달라요', style: AppText.caption),
                  ActionChip(
                    label: Text(
                      '${name(row.id)} · ${dayLabel([row.entry['weekday'] as int])}',
                    ),
                    onPressed: editable && ghost == null
                        ? () => removeCrew(row.id, [], legacy: row.entry)
                        : null,
                  ),
                ],
              ),
            if (groups.isEmpty)
              const Information('선택한 요일의 영업시간과 필요 인원을 먼저 설정해 주세요.'),
            const SizedBox(height: 24),
            const Text('근무표에 적용', style: AppText.title),
            Wrap(
              spacing: 8,
              children: [
                TextButton(
                  onPressed: editable && ghost == null
                      ? () => chooseDate(true)
                      : null,
                  child: Text('시작 ${rosterDate(from)}'),
                ),
                TextButton(
                  onPressed: editable && ghost == null
                      ? () => chooseDate(false)
                      : null,
                  child: Text('종료 ${rosterDate(until)}'),
                ),
              ],
            ),
            OutlinedButton(
              onPressed: editable && pendingIds.isEmpty && ghost == null
                  ? apply
                  : null,
              child: const Text('기간 확인·근무표 적용'),
            ),
            if (error != null) Information('$error\n입력한 배정은 유지돼요.'),
          ],
        ),
      ),
    );
  }
}
