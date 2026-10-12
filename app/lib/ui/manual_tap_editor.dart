import '../domain/manual_categories.dart';
import '../l10n/entity_name_scope.dart';
import '../l10n/app_localizations.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../state/operations_controller.dart';
import 'components.dart';
import 'checklist_editor.dart';
import 'tap_settings_screen.dart';

class ManualTapEditor extends StatefulWidget {
  const ManualTapEditor({
    super.key,
    required this.ops,
    this.templateId,
    this.folderId,
    this.addTask = false,
  });
  final OperationsController ops;
  final String? templateId, folderId;
  final bool addTask;
  @override
  State<ManualTapEditor> createState() => _ManualTapEditorState();
}

class _ManualTapEditorState extends State<ManualTapEditor> {
  late final Json source = jsonDecode(
    jsonEncode(
      widget.ops
              .rows('taskTemplates')
              .where((t) => t['id'] == widget.templateId)
              .firstOrNull ??
          {
            'title': '',
            'emoji': '📝',
            'folderId': widget.folderId ?? 'general',
            'steps': <Json>[],
          },
    ),
  );
  late final title = TextEditingController(
    text: source['manualTitle'] ?? source['title'],
  );
  late final emoji = TextEditingController(text: source['emoji']);
  late String folder = source['folderId'];
  late String category = manualCategoryOf(source);
  bool categoryChanged = false;
  late List<Json> steps = (source['steps'] as List).cast<Json>();
  late int revision;
  late final String actor;
  late final Object? workspace;
  @override
  void initState() {
    super.initState();
    revision = widget.ops.data?['revision'] ?? 0;
    actor = widget.ops.actorId;
    workspace = widget.ops.data?['workspaceId'];
    if (widget.addTask) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) edit();
      });
    }
  }

  final operationId = 'create-${DateTime.now().microsecondsSinceEpoch}';
  bool dirty = false, saving = false;
  String? error;
  bool get linked =>
      widget.ops.data?['catalogLinks']?[widget.templateId]?['mode'] == 'linked';
  @override
  void dispose() {
    title.dispose();
    emoji.dispose();
    super.dispose();
  }

  Future<void> edit([int? index]) async {
    final result = await editManualTaskContent(
      context,
      index == null
          ? {
              'id': 'task-${DateTime.now().microsecondsSinceEpoch}',
              'title': '',
              'manual': '',
              'tip': '',
              'tags': <String>[],
            }
          : {
              ...steps[index],
              'title': steps[index]['manualTitle'] ?? steps[index]['title'],
            },
      title.text,
      ops: widget.ops,
    );
    if (result != null && mounted) {
      setState(() {
        if (index == null) {
          steps.add(result);
        } else {
          if (source['menuManualId'] != null ||
              steps[index]['manualTitle'] != null) {
            steps[index] = {
              ...result,
              'manualTitle': result['title'],
              'title': steps[index]['title'],
            };
          } else {
            steps[index] = result;
          }
        }
        dirty = true;
      });
    }
  }

  Future<void> save() async {
    if (saving) return;
    if (widget.ops.actorId != actor ||
        widget.ops.data?['workspaceId'] != workspace ||
        !widget.ops.canEditTasks) {
      setState(() => error = context.t('ui.audit1247'));
      return;
    }
    if (title.text.trim().isEmpty) {
      setState(() => error = context.t('ui.audit1262'));
      return;
    }
    setState(() {
      saving = true;
      error = null;
    });
    final ok = await widget.ops.act('save_manual_tap', {
      'revision': revision,
      'operationId': operationId,
      'templateId': widget.templateId,
      'title': source['menuManualId'] != null || source['manualTitle'] != null
          ? source['title']
          : title.text.trim(),
      if (source['menuManualId'] != null || source['manualTitle'] != null)
        'manualTitle': title.text.trim(),
      'emoji': emoji.text.trim(),
      'folderId': folder,
      'steps': steps,
      if (categoryChanged || widget.templateId == null)
        'manualCategory': category,
    });
    if (!mounted) return;
    setState(() => saving = false);
    if (ok) {
      setState(() => dirty = false);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.pop(context);
      });
    } else {
      setState(() => error = widget.ops.error ?? context.t('ui.audit1263'));
    }
  }

  Future<void> close() async {
    if (saving) return;
    if (dirty) {
      final leave = await showAppDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: Text(context.t('ui.audit288')),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: Text(context.t('ui.audit21')),
            ),
            TextButton(
              onPressed: () => Navigator.pop(c, true),
              child: Text(context.t('ui.audit289')),
            ),
          ],
        ),
      );
      if (leave != true || !mounted) return;
    }
    setState(() => dirty = false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.pop(context);
    });
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !dirty && !saving,
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop) close();
    },
    child: AppEditorScaffold(
      title: widget.templateId == null
          ? context.t('ui.audit845')
          : context.t('ui.audit846'),
      onClose: close,
      footer: AppSheetFooter(
        children: [
          Text(context.t('ui.audit290'), style: AppText.caption),
          if (error != null) Information(context.t(error!)),
          FilledButton(
            onPressed: saving || widget.ops.readOnly ? null : save,
            child: Text(
              saving ? context.t('ui.audit532') : context.t('ui.audit566'),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          if (linked) Information(context.t('ui.audit291')),
          if (linked)
            TextButton.icon(
              onPressed: dirty || saving || widget.ops.readOnly
                  ? null
                  : () async {
                      if (widget.ops.actorId != actor ||
                          widget.ops.data?['workspaceId'] != workspace) {
                        return;
                      }
                      setState(() => saving = true);
                      final ok = await widget.ops
                          .act('personalize_market_tap', {
                            'revision': revision,
                            'operationId': 'copy-$operationId',
                            'templateId': widget.templateId,
                          });
                      if (!mounted) return;
                      setState(() {
                        saving = false;
                        error = ok ? null : widget.ops.error;
                      });
                      if (ok) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) Navigator.pop(context);
                        });
                      }
                    },
              icon: const Icon(Icons.copy_outlined),
              label: Text(context.t('ui.audit292')),
            ),
          const SizedBox(height: 16),
          TextField(
            key: const ValueKey('manual-tap-title'),
            controller: title,
            maxLength: 100,
            enabled: !saving,
            decoration: InputDecoration(labelText: context.t('ui.audit37')),
            onChanged: (_) => setState(() => dirty = true),
          ),
          AppPicker<String>(
            label: context.t('manual.category.label'),
            value: category,
            items: [
              for (final c in manualCategoryIds)
                DropdownMenuItem(
                  value: c,
                  child: Text(context.t('manual.category.$c')),
                ),
            ],
            onChanged: saving || source['menuManualId'] != null
                ? null
                : (value) => setState(() {
                    category = value!;
                    categoryChanged = true;
                    dirty = true;
                  }),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: emoji,
            maxLength: 10,
            decoration: InputDecoration(labelText: context.t('ui.audit293')),
            onChanged: (_) => setState(() => dirty = true),
          ),
          if (source['menuManualId'] == null)
            AppPicker<String>(
              label: context.t('ui.audit847'),
              value: folder,
              items: widget.ops
                  .rows('checklistFolders')
                  .map(
                    (f) => DropdownMenuItem(
                      value: f['id'] as String,
                      child: Text(
                        entityDisplayName(
                          context,
                          widget.ops,
                          'folder',
                          f['id'],
                          f['name'],
                        ),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: saving
                  ? null
                  : (v) => setState(() {
                      folder = v!;
                      dirty = true;
                    }),
            ),
          if (widget.templateId != null && source['menuManualId'] == null)
            TextButton.icon(
              onPressed: dirty || saving
                  ? null
                  : () async {
                      await showAppSheet(
                        context,
                        builder: (_) => TapSettingsScreen(
                          ops: widget.ops,
                          initialTemplateId: widget.templateId,
                        ),
                      );
                      if (mounted) {
                        setState(
                          () => revision =
                              widget.ops.data?['revision'] ?? revision,
                        );
                      }
                    },
              icon: const Icon(Icons.tune),
              label: Text(context.t('ui.audit294')),
            ),
          if (dirty && widget.templateId != null)
            Text(context.t('ui.audit295'), style: AppText.caption),
          const SizedBox(height: 24),
          Text(
            source['menuManualId'] == null
                ? context.t('ui.audit848')
                : context.t('ui.audit849'),
            style: AppText.section,
          ),
          if (source['menuManualId'] != null)
            Text(context.t('ui.audit296'), style: AppText.caption),
          for (var i = 0; i < steps.length; i++)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Surface(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      '${i + 1}. ${steps[i]['manualTitle'] ?? steps[i]['title']}',
                      style: AppText.body,
                    ),
                    Text(
                      steps[i]['manual'] ?? '',
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.caption,
                    ),
                    Wrap(
                      children: [
                        TextButton(
                          onPressed: saving ? null : () => edit(i),
                          child: Text(context.t('ui.audit297')),
                        ),
                        IconButton(
                          tooltip: context.t('ui.audit850'),
                          onPressed: saving || i == 0
                              ? null
                              : () => setState(() {
                                  final v = steps.removeAt(i);
                                  steps.insert(i - 1, v);
                                  dirty = true;
                                }),
                          icon: const Icon(Icons.arrow_upward),
                        ),
                        IconButton(
                          tooltip: context.t('ui.audit851'),
                          onPressed: saving || i == steps.length - 1
                              ? null
                              : () => setState(() {
                                  final v = steps.removeAt(i);
                                  steps.insert(i + 1, v);
                                  dirty = true;
                                }),
                          icon: const Icon(Icons.arrow_downward),
                        ),
                        IconButton(
                          tooltip: context.t('ui.audit551'),
                          onPressed: saving
                              ? null
                              : () => setState(() {
                                  steps.removeAt(i);
                                  dirty = true;
                                }),
                          icon: const Icon(Icons.delete_outline),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: saving || steps.length >= 30 ? null : () => edit(),
            icon: const Icon(Icons.add),
            label: Text(context.t('ui.audit31')),
          ),
        ],
      ),
    ),
  );
}
