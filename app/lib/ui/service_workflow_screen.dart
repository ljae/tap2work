import '../l10n/entity_name_scope.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../state/operations_controller.dart';
import '../state/service_workflow_controller.dart';
import '../l10n/app_localizations.dart';
import 'components.dart';
import 'action_failure_text.dart';
import 'manual_print_screen.dart';
import 'manual_tap_editor.dart';
import 'translated_content.dart';

class ServiceWorkflowScreen extends StatefulWidget {
  const ServiceWorkflowScreen({super.key, required this.ops});
  final OperationsController ops;
  @override
  State<ServiceWorkflowScreen> createState() => _ServiceWorkflowScreenState();
}

class _ServiceWorkflowScreenState extends State<ServiceWorkflowScreen> {
  late final scope = ServiceWorkflowDraft(widget.ops);
  late final acknowledgement = ServiceBriefingAcknowledgement(widget.ops);
  int pane = 0;
  OperationsController get ops => widget.ops;
  Json get flow => ops.data?['serviceWorkflow'] as Json? ?? {};
  Json get briefing => flow['briefing'] as Json? ?? {};
  List<Json> rows(String key) => (flow[key] as List? ?? []).cast<Json>();
  bool get writable => scope.valid && !ops.readOnly && !ops.busy;
  List<Json> get manuals => rows('manuals');

  Future<void> read(Json row, {bool candidate = false}) async {
    final source = candidate
        ? row
        : ops
              .rows('taskTemplates')
              .where((t) => t['id'] == row['id'])
              .firstOrNull;
    if (source == null) return;
    final frozen = jsonDecode(jsonEncode(source)) as Json;
    final draft = ServiceWorkflowDraft(ops);
    String? error;
    await showAppPage<void>(
      context,
      builder: (_) => ListenableBuilder(
        listenable: ops,
        builder: (_, _) => StatefulBuilder(
          builder: (context, update) => AppEditorScaffold(
            title: '${frozen['title']}',
            body: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                if (candidate) Information(context.t('service.draft')),
                if (frozen['sourceLocale'] == 'ko')
                  Information(context.t('service.original')),
                for (final step
                    in (frozen['steps'] as List? ?? []).cast<Json>()) ...[
                  const SizedBox(height: 16),
                  TranslatedContent(
                    ops: ops,
                    kind: 'manual',
                    entityId: candidate ? null : '${frozen['id']}',
                    stepId: step['id'],
                    source: step,
                    builder: (c, value) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${value['title']}', style: AppText.section),
                        const SizedBox(height: 12),
                        Text('${value['manual'] ?? ''}', style: AppText.body),
                        if ('${value['tip'] ?? ''}'.isNotEmpty)
                          Information('${value['tip']}'),
                      ],
                    ),
                  ),
                ],
                if (error != null) Information(error!),
              ],
            ),
            footer: candidate
                ? AppSheetFooter(
                    children: [
                      FilledButton(
                        onPressed: !writable
                            ? null
                            : () async {
                                final ok = await draft.save(
                                  'register_service_guide',
                                  {
                                    'guideId': row['id'],
                                    'reviewedHash': row['hash'],
                                  },
                                );
                                if (!context.mounted) return;
                                if (ok && draft.valid) {
                                  Navigator.pop(context);
                                } else {
                                  update(
                                    () =>
                                        error = actionFailureText(context, ops),
                                  );
                                }
                              },
                        child: Text(
                          context.t(
                            ops.busy ? 'common.saving' : 'service.register',
                          ),
                        ),
                      ),
                    ],
                  )
                : null,
          ),
        ),
      ),
    );
  }

  Future<void> configure() async {
    final draft = ServiceWorkflowDraft(ops);
    final selected = Set<String>.from(
      briefing['manualIds'] as List? ?? [],
    ).intersection(manuals.map((m) => '${m['id']}').toSet());
    final note = TextEditingController(text: '${briefing['note'] ?? ''}');
    final originalSelection = Set<String>.from(selected);
    final originalNote = note.text;
    String query = '', error = '';
    await showAppFormSheet<void>(
      context: context,
      builder: (_) => _ServiceFormLifecycle(
        controllers: [note],
        ops: ops,
        isDirty: () =>
            note.text != originalNote ||
            selected.length != originalSelection.length ||
            !selected.containsAll(originalSelection),
        builder: (_) => StatefulBuilder(
          builder: (context, update) => AppEditorScaffold(
            title: context.t('service.configure'),
            body: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Text(context.t('service.three'), style: AppText.caption),
                const SizedBox(height: 20),
                TextField(
                  controller: note,
                  maxLength: 300,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: context.t('service.today'),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  '${context.t('service.selected')} · ${selected.length}/3',
                  style: AppText.section,
                ),
                const SizedBox(height: 12),
                TextField(
                  onChanged: (v) => update(() => query = v),
                  decoration: InputDecoration(
                    labelText: context.t('manual.search'),
                  ),
                ),
                const SizedBox(height: 12),
                if (!manuals.any(
                  (m) => '${m['title']}'.toLowerCase().contains(
                    query.trim().toLowerCase(),
                  ),
                ))
                  Text(context.t('service.noMatches'), style: AppText.caption),
                for (final row in manuals.where(
                  (m) => '${m['title']}'.toLowerCase().contains(
                    query.trim().toLowerCase(),
                  ),
                ))
                  CheckboxListTile(
                    value: selected.contains(row['id']),
                    title: Text('${row['title']}'),
                    secondary: IconButton(
                      icon: const Icon(Icons.menu_book_outlined),
                      tooltip: context.t('service.read'),
                      onPressed: () => read(row),
                    ),
                    onChanged:
                        !selected.contains(row['id']) && selected.length >= 3
                        ? null
                        : (v) => update(() {
                            if (v == true && selected.length < 3) {
                              selected.add('${row['id']}');
                            } else if (v != true) {
                              selected.remove(row['id']);
                            }
                          }),
                  ),
              ],
            ),
            footer: AppSheetFooter(
              children: [
                if (error.isNotEmpty)
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      error,
                      style: AppText.caption.copyWith(color: AppColors.accent),
                    ),
                  ),
                FilledButton(
                  onPressed: !writable
                      ? null
                      : () async {
                          final ok = await draft.save('save_service_briefing', {
                            'manualIds': selected.toList(),
                            'note': note.text,
                          });
                          if (!context.mounted) return;
                          if (ok && draft.valid) {
                            Navigator.pop(context);
                          } else {
                            update(
                              () => error = actionFailureText(context, ops),
                            );
                          }
                        },
                  child: Text(
                    context.t(ops.busy ? 'common.saving' : 'common.save'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> record(String kind, {Json? source}) async {
    final draft = ServiceWorkflowDraft(ops);
    final note = TextEditingController(), next = TextEditingController();
    String? templateId, person;
    String cause = 'unknown',
        outcome = 'unmeasured',
        phase = 'handoff',
        error = '';
    final references = List<Json>.from(manuals);
    final people = ops
        .rows('tappers')
        .where(
          (p) =>
              p['active'] == true &&
              (kind != 'practice' ||
                  p['actorId'] != null && p['actorId'] != ops.actorId),
        )
        .toList();
    final resolving = kind == 'resolve', confirming = kind == 'confirm';
    final formKey = GlobalKey<FormState>();
    String? requiredValue(String? value) =>
        value == null || value.trim().isEmpty
        ? context.t('service.required')
        : null;
    await showAppFormSheet<void>(
      context: context,
      builder: (_) => _ServiceFormLifecycle(
        controllers: [note, next],
        ops: ops,
        isDirty: () =>
            note.text.isNotEmpty ||
            next.text.isNotEmpty ||
            templateId != null ||
            person != null ||
            cause != 'unknown' ||
            outcome != 'unmeasured' ||
            phase != 'handoff',
        builder: (_) => StatefulBuilder(
          builder: (context, update) => AppEditorScaffold(
            title: context.t('service.$kind'),
            body: Form(
              key: formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (source != null) ...[
                      Text('${source['note'] ?? ''}'),
                      if (source['nextAction'] != null)
                        Text('${source['nextAction']}'),
                    ],
                    if (kind == 'practice' || kind == 'feedback')
                      Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: DropdownButtonFormField<String>(
                          validator: kind == 'practice' ? requiredValue : null,
                          isExpanded: true,
                          initialValue: templateId,
                          decoration: InputDecoration(
                            labelText: context.t('service.manual'),
                          ),
                          items: [
                            if (kind == 'feedback')
                              DropdownMenuItem(
                                value: '',
                                child: Text(context.t('service.unassigned')),
                              ),
                            for (final row in references)
                              DropdownMenuItem(
                                value: '${row['id']}',
                                child: Text(
                                  '${row['title']}',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                          ],
                          onChanged: (v) => update(() => templateId = v),
                        ),
                      ),
                    if (kind == 'handoff') ...[
                      AppChoiceGroup<String>(
                        values: const ['handoff', 'closing'],
                        selected: phase,
                        labelOf: (v) => context.t('service.$v'),
                        onSelected: (v) => update(() => phase = v),
                      ),
                      const SizedBox(height: 20),
                      fieldLabel(
                        'service.next',
                        TextFormField(
                          validator: requiredValue,
                          controller: next,
                          maxLength: 300,
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                    fieldLabel(
                      'service.note',
                      TextFormField(
                        validator: requiredValue,
                        controller: note,
                        maxLength: resolving || confirming ? 300 : 500,
                        minLines: 2,
                        maxLines: 4,
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (kind == 'practice' && people.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Information(context.t('service.noBuddy')),
                      ),
                    if (kind == 'practice' || kind == 'handoff')
                      Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: DropdownButtonFormField<String>(
                          validator: kind == 'practice' ? requiredValue : null,
                          isExpanded: true,
                          initialValue: person,
                          decoration: InputDecoration(
                            labelText: context.t(
                              kind == 'practice'
                                  ? 'service.buddy'
                                  : 'service.assignee',
                            ),
                          ),
                          items: [
                            if (kind == 'handoff')
                              DropdownMenuItem(
                                value: '',
                                child: Text(context.t('service.unassigned')),
                              ),
                            for (final p in people)
                              DropdownMenuItem(
                                value: '${p['id']}',
                                child: Text(
                                  '${p['nickname']}',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                          ],
                          onChanged: (v) => update(() => person = v),
                        ),
                      ),
                    if (kind == 'feedback') ...[
                      DropdownButtonFormField<String>(
                        isExpanded: true,
                        initialValue: cause,
                        decoration: InputDecoration(
                          labelText: context.t('service.cause'),
                        ),
                        items: [
                          for (final c in [
                            'unknown',
                            'staffing',
                            'stock',
                            'equipment',
                            'handoff',
                            'manual',
                          ])
                            DropdownMenuItem(
                              value: c,
                              child: Text(context.t('service.cause.$c')),
                            ),
                        ],
                        onChanged: (v) => update(() => cause = v!),
                      ),
                      const SizedBox(height: 20),
                      DropdownButtonFormField<String>(
                        isExpanded: true,
                        initialValue: outcome,
                        decoration: InputDecoration(
                          labelText: context.t('service.outcome'),
                        ),
                        items: [
                          for (final c in [
                            'unmeasured',
                            'helpful',
                            'needs_changes',
                          ])
                            DropdownMenuItem(
                              value: c,
                              child: Text(context.t('service.outcome.$c')),
                            ),
                        ],
                        onChanged: (v) => update(() => outcome = v!),
                      ),
                      const SizedBox(height: 20),
                    ],
                    help([
                      kind == 'practice' || confirming
                          ? 'service.practiceMeaning'
                          : 'service.privacy',
                    ]),
                  ],
                ),
              ),
            ),
            footer: AppSheetFooter(
              children: [
                if (error.isNotEmpty)
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      error,
                      style: AppText.caption.copyWith(color: AppColors.accent),
                    ),
                  ),
                FilledButton(
                  onPressed: !writable
                      ? null
                      : () async {
                          final ref = references
                              .where((m) => m['id'] == templateId)
                              .firstOrNull;
                          final invalid = formKey.currentState!
                              .validateGranularly();
                          if (invalid.isNotEmpty) {
                            await Scrollable.ensureVisible(
                              invalid.first.context,
                              alignment: .2,
                            );
                            return;
                          }
                          final values = <String, dynamic>{
                            'note': note.text,
                            if (resolving) 'handoffId': source!['id'],
                            if (confirming) 'practiceId': source!['id'],
                            if (!resolving && !confirming) 'kind': kind,
                            if (ref != null) ...{
                              'templateId': ref['id'],
                              'manualHash': ref['hash'],
                            },
                            if (kind == 'practice') 'buddyCrewId': person,
                            if (kind == 'handoff') ...{
                              'nextAction': next.text,
                              'assigneeId': person == '' ? null : person,
                              'phase': phase,
                            },
                            if (kind == 'feedback') ...{
                              'cause': cause,
                              'outcome': outcome,
                            },
                          };
                          final ok = await draft.save(
                            resolving
                                ? 'resolve_service_handoff'
                                : confirming
                                ? 'confirm_service_practice'
                                : 'record_service',
                            values,
                          );
                          if (!context.mounted) return;
                          if (ok && draft.valid) {
                            Navigator.pop(context);
                          } else {
                            update(
                              () => error = actionFailureText(context, ops),
                            );
                          }
                        },
                  child: Text(
                    context.t(ops.busy ? 'common.saving' : 'common.save'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget fieldLabel(String key, Widget input) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(context.t(key), style: AppText.caption),
      const SizedBox(height: 8),
      Semantics(label: context.t(key), child: input),
    ],
  );

  Widget button(
    String key,
    VoidCallback? action, {
    IconData icon = Icons.add,
    bool primary = false,
  }) {
    final label = Text(context.t(key), textAlign: TextAlign.center);
    final style = ButtonStyle(
      minimumSize: const WidgetStatePropertyAll(Size(48, 52)),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
    return PressBounce(
      child: primary
          ? FilledButton.icon(
              onPressed: action,
              style: style,
              icon: Icon(icon, size: 20),
              label: label,
            )
          : OutlinedButton.icon(
              onPressed: action,
              style: style,
              icon: Icon(icon, size: 20),
              label: label,
            ),
    );
  }

  Widget heading(String key, {int? count}) => Padding(
    padding: const EdgeInsets.only(top: 24, bottom: 12),
    child: Semantics(
      header: true,
      child: Text(
        '${context.t(key)}${count == null ? '' : ' · $count'}',
        style: AppText.section,
      ),
    ),
  );

  Widget help(List<String> keys) => ExpansionTile(
    key: PageStorageKey('service-help-$pane'),
    tilePadding: EdgeInsets.zero,
    title: Text(context.t('service.help'), style: AppText.caption),
    leading: const Icon(Icons.info_outline, size: 20),
    children: [
      for (final key in keys)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(context.t(key), style: AppText.caption),
        ),
    ],
  );

  Widget manualLink(Json row, {bool candidate = false}) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Surface(
      padding: EdgeInsets.zero,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: const Icon(Icons.menu_book_outlined, color: AppColors.green),
        title: Text('${row['title']}', style: AppText.body),
        trailing: const Icon(Icons.chevron_right, color: AppColors.muted),
        onTap: () => read(row, candidate: candidate),
      ),
    ),
  );

  Widget rowCard(Json row) {
    final handoff = row['kind'] == 'handoff';
    final confirmed = row['confirmation'] != null;
    final resolved = row['resolution'] != null;
    final status = handoff
        ? (resolved ? 'service.resolved' : 'service.pending')
        : row['kind'] == 'practice'
        ? (confirmed ? 'service.confirmed' : 'service.waitBuddy')
        : 'service.outcome.${row['outcome']}';
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Surface(
        padding: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                context.t(status),
                style: AppText.caption.copyWith(
                  color: resolved || confirmed
                      ? AppColors.green
                      : AppColors.accent,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${handoff ? row['nextAction'] : row['note']}',
                style: AppText.body,
              ),
              if (handoff) ...[
                const SizedBox(height: 8),
                Text('${row['note']}', style: AppText.caption),
                const SizedBox(height: 12),
                Text(
                  '${context.t('service.assignee')} · ${row['assignee'] ?? context.t('service.unassigned')}',
                  style: AppText.caption,
                ),
              ],
              const SizedBox(height: 8),
              Text(
                '${row['day']} · ${row['actor']?['name'] ?? ''}',
                style: AppText.caption,
              ),
              if (row['manual'] != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    '${row['manual']['title']} · v${row['manual']['version']}',
                    style: AppText.caption,
                  ),
                ),
              if (handoff && resolved)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    '${row['resolution']['note']}',
                    style: AppText.body,
                  ),
                ),
              if (handoff && row['canResolve'] == true)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: button(
                    'service.resolve',
                    writable ? () => record('resolve', source: row) : null,
                    icon: Icons.check,
                  ),
                ),
              if (row['kind'] == 'practice' && confirmed)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    '${row['confirmation']['actor']['name']} · ${row['confirmation']['note'] ?? ''}',
                    style: AppText.caption,
                  ),
                ),
              if (ServiceWorkflowPresentation(ops).needsMyConfirmation(row))
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: button(
                    'service.confirm',
                    writable ? () => record('confirm', source: row) : null,
                    icon: Icons.check,
                  ),
                ),
              if (row['kind'] == 'feedback') ...[
                const SizedBox(height: 8),
                Text(
                  context.t('service.cause.${row['cause']}'),
                  style: AppText.caption,
                ),
                if (ops.canEditTasks && row['manual'] != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: button(
                      'service.edit',
                      writable
                          ? () => showAppFormSheet(
                              context: context,
                              builder: (_) => ManualTapEditor(
                                ops: ops,
                                templateId: row['manual']['id'],
                              ),
                            )
                          : null,
                      icon: Icons.edit_outlined,
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> acknowledge() async {
    final ok = await acknowledgement.save(flow['day'], briefing['hash']);
    if (mounted && !ok) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(actionFailureText(context, ops))));
    }
  }

  List<Widget> startContent(ServiceWorkflowPresentation view) => [
    Text('${flow['day'] ?? ops.data?['day'] ?? ''}', style: AppText.caption),
    for (final shift in rows('ownShifts'))
      Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text(
          '${entityDisplayName(context, ops, 'part', shift['partId'], shift['partName'])} · ${shift['date'] == flow['day'] ? '' : '${shift['date']} '}${shift['start']}–${shift['end']}',
          style: AppText.body,
        ),
      ),
    heading('service.briefing'),
    if ('${briefing['note'] ?? ''}'.isNotEmpty)
      Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Surface(
          padding: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Text('${briefing['note']}', style: AppText.body),
          ),
        ),
      ),
    for (final row in (briefing['manuals'] as List? ?? []).cast<Json>())
      manualLink(row),
    if ((briefing['manuals'] as List? ?? []).isEmpty &&
        '${briefing['note'] ?? ''}'.isEmpty)
      Information(context.t('service.empty')),
    if ((briefing['manuals'] as List? ?? []).isNotEmpty ||
        '${briefing['note'] ?? ''}'.isNotEmpty) ...[
      const SizedBox(height: 8),
      if (view.acknowledged)
        Semantics(
          liveRegion: true,
          child: Row(
            children: [
              const Icon(Icons.check_circle, color: AppColors.green),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  context.t('service.acknowledged'),
                  style: AppText.body,
                ),
              ),
            ],
          ),
        )
      else
        button(
          'service.ack',
          writable ? acknowledge : null,
          icon: Icons.check,
          primary: true,
        ),
    ],
    if (flow['canConfigure'] == true)
      Padding(
        padding: const EdgeInsets.only(top: 8),
        child: TextButton.icon(
          onPressed: writable ? configure : null,
          icon: const Icon(Icons.tune, size: 18),
          label: Text(context.t('service.configure')),
        ),
      ),
    if (view.pendingHandovers.isNotEmpty) ...[
      heading('service.pending', count: view.pendingHandovers.length),
      for (final row in view.pendingHandovers.take(2)) rowCard(row),
      button(
        'service.viewHandovers',
        () => setState(() => pane = 1),
        icon: Icons.arrow_forward,
      ),
    ],
    if (ops.rows('tasks').any((t) => t['workIssue']?['status'] == 'open')) ...[
      heading('service.workIssues'),
      for (final task
          in ops
              .rows('tasks')
              .where((t) => t['workIssue']?['status'] == 'open')
              .take(3))
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            '${task['title']} · ${task['workIssue']['reason']}',
            style: AppText.body,
          ),
        ),
    ],
    help(['service.focus', 'service.ackMeaning']),
  ];

  List<Widget> handoverContent(ServiceWorkflowPresentation view) => [
    button(
      'service.handoff',
      writable ? () => record('handoff') : null,
      primary: true,
      icon: Icons.edit_note,
    ),
    heading('service.pending', count: view.pendingHandovers.length),
    if (view.pendingHandovers.isEmpty)
      Information(context.t('service.noHandovers')),
    for (final row in view.pendingHandovers) rowCard(row),
    if (view.resolvedHandovers.isNotEmpty)
      _ServiceHistory(
        key: const ValueKey('resolved-history'),
        title: context.t('service.resolvedHistory'),
        records: view.resolvedHandovers,
        itemBuilder: rowCard,
      ),
    help(['service.checkAtTime', 'service.privacy']),
  ];

  List<Widget> csContent(ServiceWorkflowPresentation view) => [
    if (view.pendingConfirmations.isNotEmpty) ...[
      heading(
        'service.myConfirmations',
        count: view.pendingConfirmations.length,
      ),
      for (final row in view.pendingConfirmations) rowCard(row),
    ],
    button(
      'service.practice',
      writable ? () => record('practice') : null,
      primary: true,
      icon: Icons.people_outline,
    ),
    const SizedBox(height: 12),
    button(
      'service.feedback',
      writable ? () => record('feedback') : null,
      icon: Icons.chat_bubble_outline,
    ),
    if (rows('guides').isNotEmpty)
      Padding(
        padding: const EdgeInsets.only(top: 24),
        child: ExpansionTile(
          key: const PageStorageKey('service-guides'),
          tilePadding: EdgeInsets.zero,
          title: Text(context.t('service.guides'), style: AppText.section),
          subtitle: Text(context.t('service.draft'), style: AppText.caption),
          children: [
            for (final guide in rows('guides'))
              manualLink(guide, candidate: true),
          ],
        ),
      ),
    if (view.practiceHistory.isNotEmpty)
      _ServiceHistory(
        key: const ValueKey('practice-history'),
        title: context.t('service.history'),
        records: view.practiceHistory,
        itemBuilder: rowCard,
      ),
    const SizedBox(height: 16),
    TextButton.icon(
      onPressed: () =>
          showAppPage(context, builder: (_) => ManualPrintScreen(ops: ops)),
      icon: const Icon(Icons.print_outlined),
      label: Text(context.t('service.print')),
    ),
    help(['service.practiceMeaning', 'service.safety']),
  ];

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: ops,
    builder: (context, _) {
      final view = ServiceWorkflowPresentation(ops);
      final content = switch (pane) {
        0 => startContent(view),
        1 => handoverContent(view),
        _ => csContent(view),
      };
      return AppEditorScaffold(
        title: context.t('service.title'),
        body: !scope.valid
            ? Center(child: Text(context.t('service.scopeChanged')))
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
                    child: AppChoiceGroup<int>(
                      values: const [0, 1, 2],
                      selected: pane,
                      labelOf: (v) => context.t(
                        ['service.start', 'service.handover', 'service.cs'][v],
                      ),
                      onSelected: (v) => setState(() => pane = v),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      key: PageStorageKey('service-pane-$pane'),
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                      itemCount: content.length,
                      itemBuilder: (_, i) => content[i],
                    ),
                  ),
                ],
              ),
      );
    },
  );
}

class _ServiceHistory extends StatefulWidget {
  const _ServiceHistory({
    super.key,
    required this.title,
    required this.records,
    required this.itemBuilder,
  });
  final String title;
  final List<Json> records;
  final Widget Function(Json) itemBuilder;
  @override
  State<_ServiceHistory> createState() => _ServiceHistoryState();
}

class _ServiceHistoryState extends State<_ServiceHistory> {
  int count = 10;
  @override
  Widget build(BuildContext context) => ExpansionTile(
    key: PageStorageKey(widget.key),
    tilePadding: EdgeInsets.zero,
    title: Text(
      '${widget.title} · ${widget.records.length}',
      style: AppText.section,
    ),
    children: [
      for (final row in widget.records.take(count)) widget.itemBuilder(row),
      if (widget.records.length > count)
        TextButton(
          onPressed: () => setState(() => count += 10),
          child: Text(context.t('service.more')),
        ),
    ],
  );
}

// Keep input ownership, dismissal and pending state for the entire sheet route.
class _ServiceFormLifecycle extends StatefulWidget {
  const _ServiceFormLifecycle({
    required this.controllers,
    required this.builder,
    required this.ops,
    required this.isDirty,
  });
  final List<TextEditingController> controllers;
  final WidgetBuilder builder;
  final OperationsController ops;
  final bool Function() isDirty;
  @override
  State<_ServiceFormLifecycle> createState() => _ServiceFormLifecycleState();
}

class _ServiceFormLifecycleState extends State<_ServiceFormLifecycle> {
  bool asking = false;
  Future<void> close() async {
    if (widget.ops.busy || asking) return;
    if (!widget.isDirty()) {
      Navigator.pop(context);
      return;
    }
    asking = true;
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
    asking = false;
    if (discard == true && mounted) Navigator.pop(context);
  }

  @override
  void dispose() {
    for (final c in widget.controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.ops,
    builder: (context, _) => PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) close();
      },
      child: widget.builder(context),
    ),
  );
}
