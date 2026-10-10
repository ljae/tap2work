import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../l10n/app_localizations.dart';
import '../domain/manual_translation_import.dart';
import '../state/operations_controller.dart';
import 'components.dart';

/// Field-level translations are saved against exact source text and opening CAS.
class ManualTranslationEditor extends StatefulWidget {
  const ManualTranslationEditor({
    super.key,
    required this.ops,
    required this.kind,
    this.entityId,
    this.stepId,
    required this.locale,
    required this.source,
    required this.initial,
  });
  final OperationsController ops;
  final String kind, locale;
  final String? entityId, stepId;
  final Json source, initial;
  @override
  State<ManualTranslationEditor> createState() =>
      _ManualTranslationEditorState();
}

class _ManualTranslationEditorState extends State<ManualTranslationEditor> {
  late final String actor;
  late final Object? workspace, revision;
  @override
  void initState() {
    super.initState();
    actor = widget.ops.actorId;
    workspace = widget.ops.data?['workspaceId'];
    revision = widget.ops.data?['revision'];
  }

  late final fields = <String, TextEditingController>{
    for (final field in [
      'title',
      'manual',
      'tip',
      'body',
      'name',
      'floor',
      'area',
      'description',
    ])
      if (widget.source[field] is String &&
          (widget.source[field] as String).trim().isNotEmpty)
        field: TextEditingController(text: '${widget.initial[field] ?? ''}'),
  };
  bool busy = false, leaving = false;
  bool get dirty => fields.entries.any(
    (e) => e.value.text != '${widget.initial[e.key] ?? ''}',
  );
  Future<void> close() async {
    if (busy) return;
    final discard =
        !dirty ||
        await showAppDialog<bool>(
              context: context,
              builder: (c) => AlertDialog(
                title: Text(context.t('welcome.leaveTitle')),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(c, false),
                    child: Text(context.t('welcome.keepEditing')),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(c, true),
                    child: Text(context.t('welcome.discard')),
                  ),
                ],
              ),
            ) ==
            true;
    if (discard && mounted) {
      setState(() => leaving = true);
      Navigator.pop(context);
    }
  }

  String? error;
  bool get valid =>
      widget.ops.actorId == actor &&
      widget.ops.data?['workspaceId'] == workspace &&
      widget.ops.canEditTasks &&
      !widget.ops.readOnly;
  int limit(String field) => manualTranslationLimit(field);
  List<Json> get values => [
    for (final entry in fields.entries)
      {
        if (widget.stepId != null) 'stepId': widget.stepId,
        'field': entry.key,
        'sourceText': widget.source[entry.key],
        'text': entry.value.text.trim(),
      },
  ];
  Future<void> importFile() async {
    if (busy || !valid) return;
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        withData: true,
      );
      if (!mounted || !valid || result == null) return;
      final file = result.files.single;
      if (file.size > 200000 || file.bytes == null) {
        throw const FormatException();
      }
      final imported = parseManualTranslationImport(
        utf8.decode(file.bytes!),
        locale: widget.locale,
        source: widget.source,
        stepId: widget.stepId,
      );
      setState(() {
        for (final e in imported.entries) {
          fields[e.key]!.text = e.value;
        }
        error = null;
      });
    } catch (_) {
      if (mounted) {
        setState(() => error = context.t('translation.invalidImport'));
      }
    }
  }

  Future<void> save() async {
    if (busy || !valid) return;
    final nonempty = values
        .where((r) => (r['text'] as String).isNotEmpty)
        .toList();
    if (nonempty.isEmpty) return;
    setState(() => busy = true);
    final ok = await widget.ops.act('save_manual_translation', {
      'revision': revision,
      'source': {
        'kind': widget.kind,
        if (widget.entityId != null) 'id': widget.entityId,
      },
      'locale': widget.locale,
      'fields': nonempty,
    });
    if (!mounted) return;
    setState(() {
      busy = false;
      error = ok ? null : widget.ops.error ?? context.t('work.saveFailed');
    });
    if (ok && valid) {
      setState(() => leaving = true);
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    for (final c in fields.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: leaving || (!busy && !dirty),
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop) close();
    },
    child: AppEditorScaffold(
      title: context.t('translation.edit'),
      onClose: close,
      subtitle: appLanguageNames[widget.locale],
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(context.t('translation.sourceBound'), style: AppText.caption),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            children: [
              TextButton(
                onPressed: busy
                    ? null
                    : () => Clipboard.setData(
                        ClipboardData(
                          text: const JsonEncoder.withIndent('  ').convert({
                            'locale': widget.locale,
                            'fields': values,
                          }),
                        ),
                      ),
                child: Text(context.t('translation.copyForm')),
              ),
              TextButton(
                onPressed: busy ? null : importFile,
                child: Text(context.t('translation.import')),
              ),
            ],
          ),
          for (final entry in fields.entries) ...[
            const SizedBox(height: 20),
            SelectableText(
              '${widget.source[entry.key]}',
              style: AppText.caption,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: entry.value,
              minLines: 2,
              maxLines: 8,
              maxLength: limit(entry.key),
              enabled: !busy && valid,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: context.t('manual.translation'),
              ),
            ),
          ],
        ],
      ),
      footer: AppSheetFooter(
        children: [
          if (error != null) Information(error!),
          if (!valid) Information(context.t('welcome.scopeChanged')),
          FilledButton(
            onPressed:
                busy ||
                    !valid ||
                    fields.values.every((c) => c.text.trim().isEmpty)
                ? null
                : save,
            child: Text(context.t(busy ? 'common.saving' : 'common.save')),
          ),
          TextButton(
            onPressed: busy ? null : close,
            child: Text(context.t('common.cancel')),
          ),
        ],
      ),
    ),
  );
}
