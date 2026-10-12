import '../l10n/app_localizations.dart';
import 'work_assignment_field.dart';
import 'workplace_screens.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../state/operations_controller.dart';
import 'components.dart';

/// Edits template settings only. Existing task snapshots retain their own rules.
class TapSettingsScreen extends StatefulWidget {
  const TapSettingsScreen({
    super.key,
    required this.ops,
    this.initialTemplateId,
    this.initialStepId,
    this.initialTimeBandId,
    this.effectiveFrom,
  });
  final OperationsController ops;
  final String? initialTemplateId,
      initialStepId,
      initialTimeBandId,
      effectiveFrom;
  @override
  State<TapSettingsScreen> createState() => _TapSettingsScreenState();
}

class _TapSettingsScreenState extends State<TapSettingsScreen> {
  late final int revision;
  late final String openingActor;
  late final Object? openingWorkspace;
  late final List<Json> templates =
      (jsonDecode(jsonEncode(widget.ops.rows('taskTemplates'))) as List)
          .cast<Json>()
          .where(
            (row) =>
                row['archivedAt'] == null &&
                (widget.initialTemplateId == null ||
                    row['id'] == widget.initialTemplateId),
          )
          .toList();
  String? selectedId;
  bool saving = false,
      dirty = false,
      leaving = false,
      acknowledgeLegacy = false;
  String? error;
  final Set<String> invalidTargetSteps = {};
  static const types = {
    'general': '일반',
    'opening': '오픈',
    'closing': '마감',
    'cleaning': '청소·정비',
    'order': '주문·포장',
    'preparation': '준비·수량',
    'training': '교육',
  };
  static const days = ['월', '화', '수', '목', '금', '토', '일'];
  @override
  void initState() {
    super.initState();
    revision = widget.ops.data?['revision'] as int? ?? 0;
    openingActor = widget.ops.actorId;
    openingWorkspace = widget.ops.data?['workspaceId'];
    if (widget.effectiveFrom != null) {
      for (final row in templates) {
        final scheduled = row['scheduledSettings'] as Json?;
        if (scheduled != null) row['settings'] = scheduled['settings'];
      }
    }
    selectedId = templates.any((row) => row['id'] == widget.initialTemplateId)
        ? widget.initialTemplateId
        : templates.firstOrNull?['id'];
    if (selectedId != null &&
        widget.initialTimeBandId != null &&
        (widget.initialStepId == null ||
            (template['steps'] as List).any(
              (s) => s['id'] == widget.initialStepId,
            ))) {
      dirty = true;
      final target = settings;
      final old = target['assignment'] as Json? ?? {};
      final band = assignmentBands(
        widget.ops,
      ).where((b) => b['id'] == widget.initialTimeBandId).firstOrNull;
      final availableParts = storeParts(widget.ops)
          .where(
            (p) =>
                p['hidden'] != true &&
                ((band?['headcounts'] as Map?)?[p['id']] ?? 1) > 0,
          )
          .toList();
      final partId = availableParts.any((p) => p['id'] == old['partId'])
          ? old['partId']
          : availableParts.any((p) => p['id'] == template['partId'])
          ? template['partId']
          : availableParts.firstOrNull?['id'];
      target['assignment'] = {
        ...old,
        'mode': 'scheduled',
        'timeBandIds': {
          if (partId == old['partId'])
            ...List<String>.from(old['timeBandIds'] ?? []),
          widget.initialTimeBandId!,
        }.toList(),
        'partId': partId,
      };
    }
  }

  Json get template => templates.firstWhere((row) => row['id'] == selectedId);
  Json get settings {
    final value =
        template.putIfAbsent('settings', () => <String, dynamic>{}) as Json;
    value.putIfAbsent('type', () => 'general');
    value.putIfAbsent('enabled', () => true);
    value.putIfAbsent(
      'recurrence',
      () => <String, dynamic>{'mode': 'daily', 'weekdays': <int>[]},
    );
    value.putIfAbsent('allowBulkComplete', () => true);
    value.putIfAbsent('enforceSequence', () => false);
    return value;
  }

  Json get completionPolicy =>
      settings.putIfAbsent(
            'completionPolicy',
            () => <String, dynamic>{'kind': 'check', 'quantitySpec': null},
          )
          as Json;
  void update(VoidCallback action) => setState(() {
    action();
    dirty = true;
    error = null;
  });
  Future<void> close() async {
    if (saving) return;
    if (dirty) {
      final discard = await showAppDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: Text(context.t('ui.audit178')),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: Text(context.t('ui.audit179')),
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
    setState(() => leaving = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.pop(context);
    });
  }

  Future<void> save() async {
    if (saving) return;
    if (openingActor != widget.ops.actorId ||
        openingWorkspace != widget.ops.data?['workspaceId']) {
      setState(() => error = context.t('ui.audit1269'));
      return;
    }
    final task = template;
    final recurrence = settings['recurrence'] as Json;
    recurrence['holidayPolicy'] = 'next_open';
    if (settings['usage'] != 'event' &&
        settings['usage'] != 'reference' &&
        recurrence['mode'] == 'weekly' &&
        (recurrence['weekdays'] as List? ?? []).isEmpty) {
      setState(() => error = context.t('ui.audit1270'));
      return;
    }
    if (invalidTargetSteps.isNotEmpty) {
      setState(() => error = context.t('ui.audit1271'));
      return;
    }
    if (completionPolicy['kind'] == 'quantity') {
      final spec = completionPolicy['quantitySpec'] as Json?;
      final target = spec?['target'];
      if (spec == null ||
          '${spec['unit'] ?? ''}'.trim().isEmpty ||
          (target != null &&
              (target is! num || target <= 0 || target > 100000))) {
        setState(() => error = context.t('ui.audit1272'));
        return;
      }
    }
    if (task['policyReport']?['needsReview'] == true && !acknowledgeLegacy) {
      setState(() => error = context.t('ui.audit1273'));
      return;
    }
    setState(() {
      saving = true;
      error = null;
    });
    final ok = await widget.ops.act(
      widget.effectiveFrom == null
          ? 'save_tap_settings'
          : 'schedule_tap_settings',
      {
        if (widget.effectiveFrom != null) 'effectiveFrom': widget.effectiveFrom,
        'revision': revision,
        'templateId': task['id'],
        'settings': settings,
        'assignmentScopeVersion': 2,
        'acknowledgeLegacyPolicy': acknowledgeLegacy,
        'zone': task['zone'],
      },
    );
    if (!mounted) return;
    setState(() {
      saving = false;
      error = ok ? null : widget.ops.error ?? context.t('ui.audit760');
    });
    if (ok) {
      setState(() => leaving = true);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.pop(context);
      });
    }
  }

  Future<void> splitLegacy() async {
    if (saving) return;
    if (openingActor != widget.ops.actorId ||
        openingWorkspace != widget.ops.data?['workspaceId']) {
      setState(() => error = context.t('ui.audit1269'));
      return;
    }
    final confirmed = await showAppDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(context.t('ui.audit374')),
        content: Text(context.t('ui.audit375')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: Text(context.t('ui.audit179')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: Text(context.t('ui.audit376')),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => saving = true);
    final ok = await widget.ops.act('split_tap_policy', {
      'revision': revision,
      'templateId': template['id'],
      'operationId': 'split-${template['id']}-$revision',
    });
    if (!mounted) return;
    setState(() {
      saving = false;
      error = ok ? null : widget.ops.error;
    });
    if (ok) {
      setState(() => leaving = true);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.pop(context);
      });
    }
  }

  Widget switchRow(String title, bool value, ValueChanged<bool> onChanged) =>
      SwitchListTile.adaptive(
        contentPadding: EdgeInsets.zero,
        title: Text(title),
        value: value,
        onChanged: onChanged,
      );

  Widget tapConstraints() {
    final step = <String, dynamic>{'id': 'tap-policy', 'title': 'TAP 완료 기준'};
    final config = completionPolicy;
    final quantity = config['kind'] == 'quantity';
    final zones = widget.ops.rows('zones');
    final place = template['zone'] as String?;
    final spec =
        (config['quantitySpec'] as Json?) ??
        <String, dynamic>{'unit': '', 'target': null, 'decimalPlaces': 0};
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Surface(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${step['title']}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            AppPillField<String>(
              key: ValueKey('kind-${step['id']}'),
              initialValue: config['kind'] ?? 'check',
              decoration: InputDecoration(labelText: context.t('ui.audit377')),
              items: [
                DropdownMenuItem(
                  value: 'check',
                  child: Text(context.t('ui.audit914')),
                ),
                DropdownMenuItem(
                  value: 'quantity',
                  child: Text(context.t('ui.audit915')),
                ),
              ],
              onChanged: (v) => update(() {
                config['kind'] = v;
                config['quantitySpec'] = v == 'quantity' ? spec : null;
                if (v != 'quantity') invalidTargetSteps.remove('${step['id']}');
              }),
            ),
            if (quantity) ...[
              const SizedBox(height: 10),
              TextFormField(
                key: ValueKey('unit-${step['id']}'),
                initialValue: '${spec['unit'] ?? ''}',
                decoration: InputDecoration(
                  labelText: context.t('ui.audit378'),
                ),
                onChanged: (v) => update(() => spec['unit'] = v.trim()),
              ),
              TextFormField(
                key: ValueKey('target-${step['id']}'),
                initialValue: spec['target']?.toString() ?? '',
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: context.t('ui.audit379'),
                ),
                onChanged: (v) => update(() {
                  final value = v.trim();
                  spec['target'] = value.isEmpty ? null : num.tryParse(value);
                  final id = '${step['id']}';
                  if (value.isNotEmpty && spec['target'] == null) {
                    invalidTargetSteps.add(id);
                  } else {
                    invalidTargetSteps.remove(id);
                  }
                }),
              ),
              AppPillField<int>(
                initialValue: spec['decimalPlaces'] ?? 0,
                decoration: InputDecoration(
                  labelText: context.t('ui.audit380'),
                ),
                items: [
                  DropdownMenuItem(
                    value: 0,
                    child: Text(context.t('ui.audit916')),
                  ),
                  DropdownMenuItem(
                    value: 1,
                    child: Text(context.t('ui.audit917')),
                  ),
                  DropdownMenuItem(
                    value: 2,
                    child: Text(context.t('ui.audit918')),
                  ),
                ],
                onChanged: (v) => update(() => spec['decimalPlaces'] = v),
              ),
            ],
            const SizedBox(height: 10),
            AppPillField<String>(
              initialValue: zones.any((row) => row['id'] == place)
                  ? place
                  : null,
              decoration: InputDecoration(labelText: context.t('ui.audit381')),
              items: [
                DropdownMenuItem<String>(
                  value: null,
                  child: Text(context.t('ui.audit919')),
                ),
                for (final zone in zones)
                  DropdownMenuItem(
                    value: '${zone['id']}',
                    child: Text('${zone['name']}'),
                  ),
              ],
              onChanged: (v) => update(() => template['zone'] = v),
            ),
            const SizedBox(height: 10),
            AppPillField<int>(
              initialValue: settings['estimatedMinutes'],
              decoration: InputDecoration(labelText: context.t('ui.audit382')),
              items: [
                if (settings['estimatedMinutes'] != null &&
                    ![
                      1,
                      2,
                      3,
                      5,
                      8,
                      10,
                      15,
                      20,
                      30,
                      45,
                      60,
                      90,
                      120,
                    ].contains(settings['estimatedMinutes']))
                  DropdownMenuItem<int>(
                    value: settings['estimatedMinutes'] as int,
                    child: Text(
                      context.t(
                        'ui.audit920',
                        args: {'p0': settings['estimatedMinutes']},
                      ),
                    ),
                  ),
                DropdownMenuItem<int>(
                  value: null,
                  child: Text(context.t('ui.audit921')),
                ),
                DropdownMenuItem(
                  value: 1,
                  child: Text(context.t('ui.audit922')),
                ),
                DropdownMenuItem(
                  value: 2,
                  child: Text(context.t('ui.audit923')),
                ),
                DropdownMenuItem(
                  value: 3,
                  child: Text(context.t('ui.audit924')),
                ),
                DropdownMenuItem(
                  value: 5,
                  child: Text(context.t('ui.audit925')),
                ),
                DropdownMenuItem(
                  value: 8,
                  child: Text(context.t('ui.audit926')),
                ),
                DropdownMenuItem(
                  value: 10,
                  child: Text(context.t('ui.audit927')),
                ),
                DropdownMenuItem(
                  value: 15,
                  child: Text(context.t('ui.audit928')),
                ),
                DropdownMenuItem(
                  value: 20,
                  child: Text(context.t('ui.audit929')),
                ),
                DropdownMenuItem(
                  value: 30,
                  child: Text(context.t('ui.audit930')),
                ),
                DropdownMenuItem(
                  value: 45,
                  child: Text(context.t('ui.audit931')),
                ),
                DropdownMenuItem(
                  value: 60,
                  child: Text(context.t('ui.audit932')),
                ),
                DropdownMenuItem(
                  value: 90,
                  child: Text(context.t('ui.audit933')),
                ),
                DropdownMenuItem(
                  value: 120,
                  child: Text(context.t('ui.audit934')),
                ),
              ],
              onChanged: (v) => update(() => settings['estimatedMinutes'] = v),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (templates.isEmpty ||
        (widget.initialStepId != null &&
            !(template['steps'] as List).any(
              (step) => step['id'] == widget.initialStepId,
            ))) {
      return AppEditorScaffold(
        title: widget.effectiveFrom == null
            ? context.t('ui.audit935')
            : context.t('ui.audit936'),
        body: Center(
          child: Information(
            widget.initialTemplateId == null
                ? context.t('ui.audit937')
                : context.t('ui.audit938'),
          ),
        ),
      );
    }
    final task = template;
    final config = settings;
    final recurrence = config['recurrence'] as Json;
    final weekdays = List<int>.from(recurrence['weekdays'] ?? []);
    return PopScope(
      canPop: leaving,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) close();
      },
      child: AppEditorScaffold(
        onClose: close,
        title: widget.effectiveFrom == null
            ? context.t('ui.audit935')
            : context.t('ui.audit936'),
        footer: AppSheetFooter(
          children: [
            if (error != null)
              Information(context.t('ui.audit939', args: {'p0': error})),
            FilledButton(
              onPressed:
                  widget.ops.canEditTasks && !widget.ops.readOnly && !saving
                  ? save
                  : null,
              child: Text(
                saving ? context.t('ui.audit532') : context.t('ui.audit940'),
              ),
            ),
          ],
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: appEditorWidth),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Information(
                  widget.effectiveFrom != null
                      ? context.t(
                          'ui.audit941',
                          args: {'p0': widget.effectiveFrom},
                        )
                      : context.t('ui.audit942'),
                ),
                if (widget.ops.readOnly) Information(context.t('ui.audit383')),
                const SizedBox(height: 14),
                if (widget.initialTemplateId != null)
                  Text('${task['title']}', style: AppText.title)
                else
                  AppPillField<String>(
                    key: const ValueKey('tap-settings-template'),
                    initialValue: selectedId,
                    decoration: InputDecoration(
                      labelText: context.t('ui.audit384'),
                    ),
                    items: [
                      for (final row in templates)
                        DropdownMenuItem(
                          value: '${row['id']}',
                          child: Text(
                            '${row['title']}',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    onChanged: (v) => setState(() {
                      selectedId = v;
                      invalidTargetSteps.clear();
                      error = null;
                    }),
                  ),
                ...[
                  const SizedBox(height: 16),
                  if (config['usage'] != 'reference')
                    WorkAssignmentField(
                      ops: widget.ops,
                      value: config['assignment'] as Json?,
                      onChanged: (v) => update(() => config['assignment'] = v),
                    ),
                  AppPillField<String>(
                    key: ValueKey('type-$selectedId'),
                    initialValue: config['type'],
                    decoration: InputDecoration(
                      labelText: context.t('ui.audit385'),
                    ),
                    items: [
                      for (final entry in types.entries)
                        DropdownMenuItem(
                          value: entry.key,
                          child: Text(context.t(entry.value)),
                        ),
                    ],
                    onChanged: (v) => update(() => config['type'] = v),
                  ),
                  AppPillField<String>(
                    key: ValueKey('usage-$selectedId'),
                    initialValue:
                        config['usage'] ??
                        (config['enabled'] == true
                            ? 'routine'
                            : 'unclassified'),
                    decoration: InputDecoration(
                      labelText: context.t('ui.audit386'),
                    ),
                    items: [
                      DropdownMenuItem(
                        value: 'unclassified',
                        child: Text(context.t('ui.audit943')),
                      ),
                      DropdownMenuItem(
                        value: 'reference',
                        child: Text(context.t('ui.audit944')),
                      ),
                      DropdownMenuItem(
                        value: 'routine',
                        child: Text(context.t('ui.audit945')),
                      ),
                      DropdownMenuItem(
                        value: 'event',
                        child: Text(context.t('ui.audit946')),
                      ),
                    ],
                    onChanged: (v) => update(() {
                      if (v == 'unclassified') {
                        config['usage'] = null;
                        config['enabled'] = false;
                      } else {
                        config['usage'] = v;
                        config['enabled'] = v != 'reference';
                      }
                      if (v == 'event') {
                        config['eventKind'] ??=
                            task['knowledge']?['eventKind'] ?? 'batch';
                        config['allowBulkComplete'] = false;
                        config['completionPolicy'] = {
                          'kind': 'check',
                          'quantitySpec': null,
                        };
                        if (config['assignment']?['mode'] == 'scheduled') {
                          config['assignment'] = {'mode': 'anyone'};
                        }
                      }
                    }),
                  ),
                  if (task['workStatus']?['label'] != null)
                    Information(
                      context.t(
                        'ui.audit947',
                        args: {
                          'p0': localizedWorkStatus(
                            context,
                            task['workStatus'] as Json?,
                          ),
                        },
                      ),
                    ),
                  if (config['usage'] == 'event') ...[
                    Information(context.t('ui.audit387')),
                    AppPillField<String>(
                      initialValue: config['eventKind'] ?? 'batch',
                      decoration: InputDecoration(
                        labelText: context.t('ui.audit388'),
                      ),
                      items: [
                        DropdownMenuItem(
                          value: 'batch',
                          child: Text(context.t('ui.audit948')),
                        ),
                        DropdownMenuItem(
                          value: 'opened',
                          child: Text(context.t('ui.audit949')),
                        ),
                        DropdownMenuItem(
                          value: 'thawed',
                          child: Text(context.t('ui.audit950')),
                        ),
                        DropdownMenuItem(
                          value: 'received',
                          child: Text(context.t('ui.audit951')),
                        ),
                      ],
                      onChanged: (v) => update(() => config['eventKind'] = v),
                    ),
                  ],
                  if (task['knowledge']?['safetyReviewRequired'] == true)
                    TextFormField(
                      key: ValueKey('standard-$selectedId'),
                      initialValue: config['operatingStandard'] ?? '',
                      maxLength: 1000,
                      maxLines: 4,
                      decoration: InputDecoration(
                        labelText: context.t('ui.audit389'),
                        hintText: context.t('ui.audit390'),
                      ),
                      onChanged: (v) =>
                          update(() => config['operatingStandard'] = v),
                    ),
                  if (config['usage'] != 'reference')
                    ExpansionTile(
                      title: Text(context.t('ui.audit391')),
                      children: [
                        for (final other
                            in widget.ops
                                .rows('taskTemplates')
                                .where(
                                  (t) =>
                                      t['id'] != selectedId &&
                                      t['archivedAt'] == null,
                                ))
                          CheckboxListTile(
                            title: Text('${other['title']}'),
                            value: (config['knowledgeIds'] as List? ?? [])
                                .contains(other['id']),
                            onChanged: (v) => update(() {
                              final ids = List<String>.from(
                                config['knowledgeIds'] ?? [],
                              );
                              if (v == true) {
                                ids.add(other['id']);
                              } else {
                                ids.remove(other['id']);
                              }
                              config['knowledgeIds'] = ids;
                            }),
                          ),
                      ],
                    ),
                  if (config['usage'] != 'event' &&
                      config['usage'] != 'reference') ...[
                    Text(
                      context.t('ui.audit392'),
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    AppSegmented<String>(
                      segments: [
                        ButtonSegment(
                          value: 'daily',
                          label: Text(context.t('ui.audit952')),
                        ),
                        ButtonSegment(
                          value: 'weekly',
                          label: Text(context.t('ui.audit953')),
                        ),
                        ButtonSegment(
                          value: 'monthly',
                          label: Text(context.t('ui.audit954')),
                        ),
                      ],
                      selected: {recurrence['mode'] ?? 'daily'},
                      onSelectionChanged: (v) => update(() {
                        recurrence['mode'] = v.first;
                        recurrence['holidayPolicy'] = 'next_open';
                        if (v.first == 'monthly') recurrence['monthDay'] ??= 1;
                        recurrence['weekdays'] = v.first == 'daily'
                            ? <int>[]
                            : [1];
                      }),
                    ),
                    if (widget.effectiveFrom != null)
                      Information(
                        context.t(
                          'ui.audit955',
                          args: {'p0': widget.effectiveFrom},
                        ),
                      ),
                    if (recurrence['mode'] == 'monthly')
                      AppPicker<int>(
                        label: context.t('ui.audit956'),
                        value: recurrence['monthDay'] as int? ?? 1,
                        items: List.generate(
                          31,
                          (i) => DropdownMenuItem(
                            value: i + 1,
                            child: Text(
                              context.t('ui.audit957', args: {'p0': i + 1}),
                            ),
                          ),
                        ),
                        onChanged: (v) =>
                            update(() => recurrence['monthDay'] = v),
                      ),
                    Information(context.t('ui.audit393')),
                    if (recurrence['mode'] == 'weekly')
                      Wrap(
                        spacing: 6,
                        children: [
                          for (var d = 1; d <= 7; d++)
                            FilterChip(
                              chipAnimationStyle: AppMotion.chipStyle(context),
                              label: Text(context.t(days[d - 1])),
                              selected: weekdays.contains(d),
                              onSelected: (_) => update(() {
                                final selected = List<int>.from(
                                  recurrence['weekdays'],
                                );
                                selected.contains(d)
                                    ? selected.remove(d)
                                    : selected.add(d);
                                recurrence['weekdays'] = selected;
                              }),
                            ),
                        ],
                      ),
                  ],
                  switchRow(
                    context.t('ui.audit1384'),
                    config['allowBulkComplete'] == true,
                    (v) => update(() => config['allowBulkComplete'] = v),
                  ),
                  switchRow(
                    context.t('ui.audit1385'),
                    config['enforceSequence'] == true,
                    (v) => update(() => config['enforceSequence'] = v),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    context.t(
                      'ui.audit958',
                      args: {'p0': (task['steps'] as List).length},
                    ),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                if (task['policyReport']?['needsReview'] == true) ...[
                  Information(
                    (task['policyReport']['issues'] as List)
                        .map((row) => '${row['title']} · ${row['kind']}')
                        .join('\n'),
                  ),
                  TextButton(
                    onPressed:
                        saving ||
                            widget.ops.readOnly ||
                            !widget.ops.canEditTasks
                        ? null
                        : splitLegacy,
                    child: Text(context.t('ui.audit394')),
                  ),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(context.t('ui.audit395')),
                    subtitle: Text(context.t('ui.audit396')),
                    value: acknowledgeLegacy,
                    onChanged: (value) =>
                        update(() => acknowledgeLegacy = value == true),
                  ),
                ],
                tapConstraints(),
                Information(context.t('ui.audit397')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
