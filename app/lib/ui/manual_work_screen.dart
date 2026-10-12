import '../l10n/app_localizations.dart';
import '../l10n/manual_text_scope.dart';
import 'dart:math';
import 'package:flutter/material.dart';
import '../state/operations_controller.dart';
import 'components.dart';
import 'tap_settings_screen.dart';

/// A manager sees the server's execution diagnosis, not a guessed OFF warning.
class ManualWorkScreen extends StatefulWidget {
  const ManualWorkScreen({super.key, required this.ops});
  final OperationsController ops;
  @override
  State<ManualWorkScreen> createState() => _ManualWorkScreenState();
}

class _ManualWorkScreenState extends State<ManualWorkScreen> {
  String filter = 'all';
  @override
  Widget build(BuildContext context) {
    final rows = widget.ops
        .rows('taskTemplates')
        .where(
          (t) =>
              t['archivedAt'] == null &&
              (filter == 'all' ||
                  [
                    'unclassified',
                    'incomplete',
                    'missing',
                    'replacement',
                  ].contains(t['workStatus']?['code'])),
        )
        .toList();
    return AppEditorScaffold(
      title: context.t('ui.audit1067'),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          if (widget.ops.error != null) Information(widget.ops.error!),
          Information(context.t('ui.audit474')),
          Wrap(
            spacing: 8,
            children: [
              for (final value in ['all', 'needs'])
                ChoiceChip(
                  label: Text(
                    value == 'all'
                        ? context.t('ui.audit656')
                        : context.t('ui.audit1068'),
                  ),
                  selected: filter == value,
                  onSelected: (_) => setState(() => filter = value),
                ),
            ],
          ),
          for (final t in rows)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      manualDisplayText(context, '${t['title']}'),
                      style: AppText.section,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      localizedWorkStatus(context, t['workStatus'] as Json?),
                      style: AppText.caption,
                    ),
                    if (t['knowledge']?['scope'] != null)
                      Text(
                        {
                              'universal': context.t('ui.audit1069'),
                              'food': context.t('ui.audit1070'),
                              'process': context.t('ui.audit1071'),
                              'menu': context.t('ui.audit1072'),
                              'store': context.t('ui.audit1073'),
                            }[t['knowledge']['scope']] ??
                            '',
                        style: AppText.caption,
                      ),
                    Wrap(
                      spacing: 8,
                      children: [
                        TextButton(
                          onPressed: widget.ops.readOnly
                              ? null
                              : () async {
                                  await showAppSheet(
                                    context,
                                    builder: (_) => TapSettingsScreen(
                                      ops: widget.ops,
                                      initialTemplateId: t['id'],
                                    ),
                                  );
                                  if (mounted) setState(() {});
                                },
                          child: Text(context.t('ui.audit475')),
                        ),
                        if (t['workStatus']?['code'] == 'replacement')
                          TextButton(
                            onPressed:
                                (widget.ops.readOnly ||
                                    t['workStatus']?['replacementsAvailable'] !=
                                        true)
                                ? null
                                : () async {
                                    final accepted = await showAppDialog<bool>(
                                      context: context,
                                      builder: (c) => AlertDialog(
                                        title: Text(context.t('ui.audit476')),
                                        content: Text(context.t('ui.audit477')),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(c, false),
                                            child: Text(
                                              context.t('ui.audit33'),
                                            ),
                                          ),
                                          FilledButton(
                                            onPressed: () =>
                                                Navigator.pop(c, true),
                                            child: Text(
                                              context.t('ui.audit478'),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (accepted != true || !mounted) return;
                                    await widget.ops.act('replace_mixed_break', {
                                      'templateId': t['id'],
                                      'releaseId': widget
                                          .ops
                                          .data?['manualCatalog']?['releaseId'],
                                      'operationId': 'split-${t['id']}',
                                    });
                                    if (mounted) setState(() {});
                                  },
                            child: Text(context.t('ui.audit479')),
                          ),
                        if (t['workStatus']?['code'] == 'event')
                          FilledButton(
                            onPressed: widget.ops.readOnly
                                ? null
                                : () async {
                                    await showAppSheet(
                                      context,
                                      builder: (_) => StartManualWork(
                                        ops: widget.ops,
                                        template: t,
                                      ),
                                    );
                                    if (mounted) setState(() {});
                                  },
                            child: Text(context.t('ui.audit480')),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          if (rows.isEmpty) Information(context.t('ui.audit481')),
        ],
      ),
    );
  }
}

class StartManualWork extends StatefulWidget {
  const StartManualWork({super.key, required this.ops, required this.template});
  final OperationsController ops;
  final Json template;
  @override
  State<StartManualWork> createState() => _StartManualWorkState();
}

class _StartManualWorkState extends State<StartManualWork> {
  final subject = TextEditingController();
  late final String requestId =
      'work-${DateTime.now().microsecondsSinceEpoch}-${Random.secure().nextInt(1 << 30)}';
  late final actor = widget.ops.actorId;
  late final workspace = widget.ops.data?['workspaceId'];
  String? submitted, error;
  bool saving = false;
  @override
  void dispose() {
    subject.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if (saving ||
        widget.ops.actorId != actor ||
        widget.ops.data?['workspaceId'] != workspace) {
      return;
    }
    if (subject.text.trim().isEmpty) {
      setState(() => error = context.t('ui.audit1287'));
      return;
    }
    submitted ??= subject.text.trim();
    setState(() {
      saving = true;
      error = null;
    });
    final ok = await widget.ops.act('start_manual_work', {
      'templateId': widget.template['id'],
      'requestId': requestId,
      'subject': submitted,
    });
    if (!mounted) return;
    setState(() {
      saving = false;
      error = ok ? null : widget.ops.error;
    });
    if (ok) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) => AppEditorScaffold(
    title: context.t('ui.audit480'),
    body: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          manualDisplayText(context, '${widget.template['title']}'),
          style: AppText.title,
        ),
        const SizedBox(height: 16),
        Information(context.t('ui.audit482')),
        TextField(
          controller: subject,
          enabled: !saving && submitted == null,
          maxLength: 80,
          decoration: InputDecoration(
            labelText: context.t('ui.audit483'),
            hintText: context.t('ui.audit484'),
          ),
        ),
        if (widget.template['settings']?['operatingStandard']
            case final String standard)
          Text(standard),
        if (error != null) Information(context.t(error!)),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: saving || widget.ops.readOnly ? null : save,
          child: Text(
            saving
                ? context.t('ui.audit1074')
                : submitted == null
                ? context.t('ui.audit1075')
                : context.t('ui.audit1076'),
          ),
        ),
      ],
    ),
  );
}
