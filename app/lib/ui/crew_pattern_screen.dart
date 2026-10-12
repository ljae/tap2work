import '../l10n/entity_name_scope.dart';
import '../l10n/app_localizations.dart';
import 'time_wheel.dart';
import 'crew_week_grid.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../domain/part_schedule.dart';
import '../state/operations_controller.dart';
import 'components.dart';
import 'workplace_screens.dart';

class CrewPatternScreen extends StatefulWidget {
  const CrewPatternScreen({super.key, required this.ops, required this.day});
  final OperationsController ops;
  final DateTime day;
  @override
  State<CrewPatternScreen> createState() => _CrewPatternScreenState();
}

class _CrewPatternScreenState extends State<CrewPatternScreen> {
  OperationsController get ops => widget.ops;
  late final String actor;
  late int revision;
  String? crewId;
  int cycle = 1, week = 0;
  late DateTime anchor = widget.day.subtract(
    Duration(days: widget.day.weekday - 1),
  );
  late DateTime from = widget.day;
  late DateTime until = from.add(const Duration(days: 27));
  List<Json> entries = [];
  bool dirty = false, saving = false;
  String? error;
  bool get editable =>
      ops.isLeader &&
      ops.data?['canEditSchedule'] != false &&
      !ops.readOnly &&
      !saving &&
      !ops.busy &&
      ops.actorId == actor;
  List<Json> get people =>
      ops.rows('tappers').where((p) => p['active'] != false).toList();
  @override
  void initState() {
    super.initState();
    actor = ops.actorId;
    revision = ops.data?['revision'] ?? 0;
    final today = DateTime.tryParse(ops.data?['day'] ?? '') ?? DateTime.now();
    if (from.isBefore(today)) {
      from = today;
      until = from.add(const Duration(days: 27));
    }
    if (people.isNotEmpty) load(people.first['id']);
  }

  void load(String id) {
    crewId = id;
    final pattern = ops
        .rows('crewPatterns')
        .where((p) => p['tapperId'] == id)
        .firstOrNull;
    entries = (jsonDecode(jsonEncode(pattern?['entries'] ?? [])) as List)
        .cast<Json>();
    cycle = pattern?['cycleWeeks'] ?? 1;
    week = 0;
    anchor =
        DateTime.tryParse(pattern?['anchor'] ?? '') ??
        widget.day.subtract(Duration(days: widget.day.weekday - 1));
    dirty = false;
    error = null;
  }

  Future<void> close() async {
    if (dirty) {
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
      setState(() => dirty = false);
      Navigator.pop(context);
    }
  }

  Future<void> date(String target) async {
    final initial = target == 'anchor'
        ? anchor
        : target == 'from'
        ? from
        : until;
    final chosen = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (chosen == null || !mounted) return;
    setState(() {
      if (target == 'anchor') {
        anchor = chosen.subtract(Duration(days: chosen.weekday - 1));
        dirty = true;
      } else if (target == 'from') {
        from = chosen;
        if (until.isBefore(from)) until = from;
      } else {
        until = chosen;
      }
    });
  }

  Future<void> add(int weekday, [Json? existing, int? minute]) async {
    if (!editable || crewId == null) return;
    final person = people.where((p) => p['id'] == crewId).first;
    final ids = person['workProfile']?['partIds'] as List? ?? [];
    final parts = storeParts(ops)
        .where(
          (p) => p['hidden'] != true && (ids.isEmpty || ids.contains(p['id'])),
        )
        .toList();
    if (parts.isEmpty) {
      setState(() => error = context.t('ui.audit1285'));
      return;
    }
    var part = existing?['partId'] as String? ?? parts.first['id'] as String;
    if (!parts.any((p) => p['id'] == part)) part = parts.first['id'];
    final bands =
        ((ops.data?['workplace']?['days']?['$weekday'] as List?) ?? [])
            .cast<Json>()
            .where((b) => b['id'] is String)
            .toList();
    String bandId = existing?['timeBandId'] as String? ?? '';
    if (!bands.any((b) => b['id'] == bandId)) bandId = '';
    var start = existing?['start'] as String? ?? rosterClock(minute ?? 540),
        end = existing?['end'] as String? ?? rosterClock((minute ?? 540) + 60);
    final result = await showAppFormSheet<Json>(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (c, update) => AppSheetPanel(
          title: Text(
            context.t(
              'ui.audit1046',
              args: {
                'p0': [
                  context.t('ui.audit523'),
                  context.t('ui.audit524'),
                  context.t('ui.audit525'),
                  context.t('ui.audit526'),
                  context.t('ui.audit527'),
                  context.t('ui.audit528'),
                  context.t('ui.audit529'),
                ][weekday - 1],
              },
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppPicker<String>(
                  label: context.t('ui.audit160'),
                  value: part,
                  items: [
                    for (final p in parts)
                      DropdownMenuItem(
                        value: p['id'] as String,
                        child: Text(
                          entityDisplayName(
                            context,
                            ops,
                            'part',
                            p['id'],
                            p['name'],
                          ),
                        ),
                      ),
                  ],
                  onChanged: (v) => update(() {
                    part = v!;
                    final band = bands
                        .where((b) => b['id'] == bandId)
                        .firstOrNull;
                    if (band != null) {
                      start =
                          band['partTimes']?[part]?['start'] ?? band['start'];
                      end = band['partTimes']?[part]?['end'] ?? band['end'];
                    }
                  }),
                ),
                const SizedBox(height: 16),
                AppPicker<String>(
                  label: context.t('ui.audit1047'),
                  value: bandId,
                  items: [
                    DropdownMenuItem(
                      value: '',
                      child: Text(context.t('ui.audit1048')),
                    ),
                    for (final b in bands)
                      DropdownMenuItem(
                        value: b['id'] as String,
                        child: Text(
                          '${b['name']} · ${b['partTimes']?[part]?['start'] ?? b['start']}–${b['partTimes']?[part]?['end'] ?? b['end']}',
                        ),
                      ),
                  ],
                  onChanged: (v) => update(() {
                    bandId = v!;
                    final band = bands.where((b) => b['id'] == v).firstOrNull;
                    if (band != null) {
                      start =
                          band['partTimes']?[part]?['start'] ?? band['start'];
                      end = band['partTimes']?[part]?['end'] ?? band['end'];
                    }
                  }),
                ),
                const SizedBox(height: 16),
                for (final isStart in [true, false])
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: AppTimeField(
                      label: isStart
                          ? context.t('ui.audit664')
                          : context.t('ui.audit665'),
                      value: isStart ? start : end,

                      onChanged: (v) =>
                          update(() => isStart ? start = v : end = v),
                    ),
                  ),
                if (end.compareTo(start) < 0)
                  Text(context.t('ui.audit317'), style: AppText.caption),
              ],
            ),
          ),
          actions: [
            if (existing != null)
              TextButton(
                onPressed: () =>
                    Navigator.pop(c, <String, dynamic>{'delete': true}),
                child: Text(context.t('ui.audit463')),
              ),
            TextButton(
              onPressed: () => Navigator.pop(c),
              child: Text(context.t('ui.audit33')),
            ),
            FilledButton(
              onPressed: start == end
                  ? null
                  : () => Navigator.pop(c, {
                      'week': week,
                      'weekday': weekday,
                      'partId': part,
                      if (bandId.isNotEmpty) 'timeBandId': bandId,
                      'start': start,
                      'end': end,
                    }),
              child: Text(context.t('ui.audit464')),
            ),
          ],
        ),
      ),
    );
    if (result != null && mounted) {
      setState(() {
        if (existing != null) entries.remove(existing);
        if (result['delete'] != true) entries.add(result);
        dirty = true;
      });
    }
  }

  Future<void> save() async {
    if (!editable || crewId == null) return;
    setState(() => saving = true);
    final ok = await ops.act('save_crew_pattern', {
      'revision': revision,
      'tapperId': crewId,
      'cycleWeeks': cycle,
      'anchor': rosterDate(anchor),
      'entries': entries.where((e) => e['week'] < cycle).toList(),
    });
    if (!mounted) return;
    setState(() {
      saving = false;
      error = ok ? null : ops.error;
      if (ok) {
        revision = ops.data!['revision'];
        dirty = false;
      }
    });
  }

  Future<void> apply() async {
    if (!editable || dirty || crewId == null) return;
    final pattern = ops
        .rows('crewPatterns')
        .where((p) => p['tapperId'] == crewId)
        .firstOrNull;
    if (pattern == null) {
      setState(() => error = context.t('ui.audit1286'));
      return;
    }
    final replaced = ops
        .rows('staffShifts')
        .where(
          (s) =>
              s['patternId'] == pattern['id'] &&
              '${s['base']?['date'] ?? s['date']}'.compareTo(
                    rosterDate(from),
                  ) >=
                  0 &&
              '${s['base']?['date'] ?? s['date']}'.compareTo(
                    rosterDate(until),
                  ) <=
                  0,
        )
        .length;
    final yes = await showAppDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(context.t('ui.audit465')),
        content: Text(
          context.t(
            'ui.audit1049',
            args: {
              'p0': rosterDate(from),
              'p1': rosterDate(until),
              'p2': people.where((p) => p['id'] == crewId).first['nickname'],
              'p3': replaced,
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: Text(context.t('ui.audit33')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: Text(context.t('ui.audit466')),
          ),
        ],
      ),
    );
    if (yes != true || !mounted || !editable) return;
    setState(() => saving = true);
    final ok = await ops.act('apply_crew_pattern', {
      'revision': revision,
      'tapperId': crewId,
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
      ).showSnackBar(SnackBar(content: Text(context.t('ui.audit1050'))));
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !dirty,
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop) close();
    },
    child: AppEditorScaffold(
      title: context.t('ui.audit833'),
      maxWidth: 1440,
      onClose: close,
      footer: AppSheetFooter(
        children: [
          FilledButton(
            onPressed: editable && crewId != null ? save : null,
            child: Text(
              saving ? context.t('ui.audit532') : context.t('ui.audit835'),
            ),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1440),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              if (people.isEmpty) Information(context.t('ui.audit280')),
              AppPicker<String>(
                label: context.t('ui.audit765'),
                value: crewId,
                items: [
                  for (final p in people)
                    DropdownMenuItem(
                      value: p['id'] as String,
                      child: Text(p['nickname']),
                    ),
                ],
                onChanged: (v) {
                  if (!dirty && !saving) setState(() => load(v!));
                },
              ),
              if (dirty) Text(context.t('ui.audit467'), style: AppText.caption),
              const SizedBox(height: 24),
              AppChoiceGroup<int>(
                values: const [1, 2],
                selected: cycle,
                labelOf: (n) => n == 1
                    ? context.t('ui.audit1225')
                    : context.t('ui.audit1226'),
                onSelected: (n) {
                  if (!editable) return;
                  setState(() {
                    cycle = n;
                    week = 0;
                    dirty = true;
                  });
                },
              ),
              if (cycle == 2) ...[
                TextButton(
                  onPressed: () => date('anchor'),
                  child: Text(
                    context.t('ui.audit1051', args: {'p0': rosterDate(anchor)}),
                  ),
                ),
                AppChoiceGroup<int>(
                  values: const [0, 1],
                  selected: week,
                  labelOf: (n) => n == 0
                      ? context.t('ui.audit1227')
                      : context.t('ui.audit1228'),
                  onSelected: (n) => setState(() => week = n),
                ),
              ],
              const SizedBox(height: 16),
              Text(context.t('ui.audit468'), style: AppText.caption),
              const SizedBox(height: 12),
              CrewWeekGrid(
                entries: entries.where((e) => e['week'] == week).toList(),
                crewId: crewId ?? '',
                boundary:
                    ops.data?['workplace']?['businessDayStart'] ?? '00:00',
                editable: editable && crewId != null,
                partName: (id) => partLabel(ops, id, context: context),
                onAdd: (day, minute) => add(day, null, minute),
                onEdit: (day, entry) => add(day, entry),
              ),
              const SizedBox(height: 16),
              Text(context.t('ui.audit286'), style: AppText.title),
              const SizedBox(height: 8),
              Text(context.t('ui.audit469'), style: AppText.caption),
              Wrap(
                spacing: 8,
                children: [
                  TextButton(
                    onPressed: () => date('from'),
                    child: Text(
                      context.t('ui.audit842', args: {'p0': rosterDate(from)}),
                    ),
                  ),
                  TextButton(
                    onPressed: () => date('until'),
                    child: Text(
                      context.t('ui.audit843', args: {'p0': rosterDate(until)}),
                    ),
                  ),
                ],
              ),
              OutlinedButton(
                onPressed: editable && !dirty ? apply : null,
                child: Text(context.t('ui.audit470')),
              ),
              if (error != null)
                Information(context.t('ui.audit723', args: {'p0': error})),
            ],
          ),
        ),
      ),
    ),
  );
}
