import '../l10n/entity_name_scope.dart';
import '../l10n/app_localizations.dart';
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
            context.t(
              'ui.audit825',
              args: {
                'p0': partLabel(ops, targets.first.partId, context: context),
              },
            ),
            style: AppText.title,
          ),
          Text(
            context.t(
              'ui.audit826',
              args: {'p0': dayLabel(targets.map((t) => t.day).toSet())},
            ),
            style: AppText.caption,
          ),
          if (plans.isEmpty) Information(context.t('ui.audit275')),
          for (final entry in plans.entries)
            ListTile(
              title: Text(name(entry.key)),
              subtitle: Text(
                context.t(
                  'ui.audit827',
                  args: {
                    'p0': planner
                        .summary(entry.value.patterns[entry.key]!)
                        .label,
                    'p1':
                        planner
                                .summary(entry.value.patterns[entry.key]!)
                                .hint ==
                            null
                        ? ''
                        : ' · ${planner.summary(entry.value.patterns[entry.key]!).hint}',
                  },
                ),
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
            Text(
              context.t('ui.audit828', args: {'p0': name(id)}),
              style: AppText.title,
            ),
            Text(
              context.t(
                'ui.audit829',
                args: {
                  'p0': dayLabel(
                    legacy == null
                        ? targets.map((t) => t.day).toSet()
                        : [legacy['weekday'] as int],
                  ),
                },
              ),
              style: AppText.caption,
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () => Navigator.pop(c, true),
              child: Text(context.t('ui.audit276')),
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
        title: Text(context.t('ui.audit277')),
        content: Text(
          context.t(
            'ui.audit830',
            args: {'p0': rosterDate(from), 'p1': rosterDate(until)},
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: Text(context.t('ui.audit33')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: Text(context.t('ui.audit278')),
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.t('ui.audit831'))));
    }
  }

  Future<void> close() async {
    if (saving) return;
    if (changed.isNotEmpty || ghost != null) {
      final discard = await showAppDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: Text(context.t('ui.audit178')),
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
      for (final t in targets)
        context.t(
          'ui.audit2107',
          args: {'p0': t.start, 'p1': t.end, 'p2': t.capacity},
        ),
    };
    return AllocationPartCard(
      key: ValueKey('allocation-${group.id}-${part['id']}'),
      title: entityDisplayName(context, ops, 'part', part['id'], part['name']),
      index: index,
      ghost: ghost != null,
      children: [
        Text(
          detail.length == 1
              ? detail.first
              : targets
                    .map(
                      (t) => context.t(
                        'ui.audit2108',
                        args: {
                          'p0': dayLabel([t.day]),
                          'p1': t.start,
                          'p2': t.end,
                          'p3': t.capacity,
                        },
                      ),
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
              label: context.t(
                'ui.audit832',
                args: {
                  'p0': group.name,
                  'p1': entityDisplayName(
                    context,
                    ops,
                    'part',
                    part['id'],
                    part['name'],
                  ),
                },
              ),
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
        title: context.t('ui.audit833'),
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
                    ? context.t('ui.audit532')
                    : ghost != null
                    ? context.t('ui.audit834')
                    : context.t('ui.audit835'),
              ),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(context.t('ui.audit279'), style: AppText.caption),
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
            if (people.isEmpty) Information(context.t('ui.audit280')),
            ExpansionTile(
              minTileHeight: 40,
              dense: true,
              tilePadding: EdgeInsets.zero,
              title: Text(context.t('ui.audit281'), style: AppText.caption),
              children: [
                Text(context.t('ui.audit836'), style: AppText.caption),
                Text(context.t('ui.audit837'), style: AppText.caption),
              ],
            ),
            Row(
              children: [
                IconButton(
                  tooltip: context.t('ui.audit838'),
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
                    context.t('ui.audit839', args: {'p0': rosterDate(monday)}),
                    textAlign: TextAlign.center,
                    style: AppText.caption,
                  ),
                ),
                IconButton(
                  tooltip: context.t('ui.audit840'),
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
              label: Text(context.t('ui.audit282')),
              onPressed: editable && days.isNotEmpty && ghost == null
                  ? () => setState(() {
                      ghost = planner.suggest(patterns, saved, days);
                      error = null;
                    })
                  : null,
            ),
            if (ghost != null) ...[
              Information(
                context.t(
                  'ui.audit841',
                  args: {
                    'p0': ghost!.proposed,
                    'p1': dayLabel(days),
                    'p2': ghost!.skipped > 0
                        ? context.t(
                            'ui.audit1158',
                            args: {'p0': ghost!.skipped},
                          )
                        : '',
                    'p3': ghost!.proposed == 0
                        ? context.t('ui.audit1159')
                        : context.t('ui.audit1160'),
                  },
                ),
              ),
              TextButton(
                onPressed: saving ? null : () => setState(() => ghost = null),
                child: Text(context.t('ui.audit283')),
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
                    '${row.entry['start']}–${row.entry['end']} · ${partLabel(ops, row.entry['partId'], context: context)}',
                index: 0,
                children: [
                  Text(context.t('ui.audit284'), style: AppText.caption),
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
            if (groups.isEmpty) Information(context.t('ui.audit285')),
            const SizedBox(height: 24),
            Text(context.t('ui.audit286'), style: AppText.title),
            Wrap(
              spacing: 8,
              children: [
                TextButton(
                  onPressed: editable && ghost == null
                      ? () => chooseDate(true)
                      : null,
                  child: Text(
                    context.t('ui.audit842', args: {'p0': rosterDate(from)}),
                  ),
                ),
                TextButton(
                  onPressed: editable && ghost == null
                      ? () => chooseDate(false)
                      : null,
                  child: Text(
                    context.t('ui.audit843', args: {'p0': rosterDate(until)}),
                  ),
                ),
              ],
            ),
            OutlinedButton(
              onPressed: editable && pendingIds.isEmpty && ghost == null
                  ? apply
                  : null,
              child: Text(context.t('ui.audit287')),
            ),
            if (error != null)
              Information(context.t('ui.audit844', args: {'p0': error})),
          ],
        ),
      ),
    );
  }
}
