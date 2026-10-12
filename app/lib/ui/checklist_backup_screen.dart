import '../l10n/app_localizations.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../state/operations_controller.dart';
import '../data/checklist_backup_repository.dart';
import '../domain/manual_media_repository.dart';
import 'components.dart';

class ChecklistBackupScreen extends StatefulWidget {
  const ChecklistBackupScreen({super.key, required this.ops, this.repository});
  final OperationsController ops;
  final ChecklistBackupRepository? repository;
  @override
  State<ChecklistBackupScreen> createState() => _ChecklistBackupScreenState();
}

class _ChecklistBackupScreenState extends State<ChecklistBackupScreen> {
  late final repository = widget.repository ?? ChecklistBackupRepository();
  late final scope =
      '${widget.ops.data?['workspaceId'] ?? widget.ops.endpoint}/${widget.ops.actorId}';
  late final String actor;
  late final Object? workspace;
  String? stored, error, message;
  Json? preview;
  int? previewRevision;
  bool busy = false;
  int get photosToRegister => (preview?['templates'] as List? ?? [])
      .expand((t) => t['steps'] as List)
      .where((s) {
        final value = s['imageUrl'];
        if (value is! String) return false;
        final photoWorkspace = manualMediaWorkspace(value);
        return photoWorkspace != null && photoWorkspace != workspace;
      })
      .length;
  String operationId = 'restore-${DateTime.now().microsecondsSinceEpoch}';
  @override
  void initState() {
    super.initState();
    actor = widget.ops.actorId;
    workspace = widget.ops.data?['workspaceId'];
    load();
  }

  bool get valid =>
      widget.ops.actorId == actor &&
      widget.ops.data?['workspaceId'] == workspace &&
      widget.ops.canEditTasks &&
      !widget.ops.readOnly;
  Future<void> load() async {
    try {
      final value = await repository.read(scope);
      if (mounted) setState(() => stored = value);
    } catch (e) {
      if (mounted) setState(() => error = context.t('ui.audit1242'));
    }
  }

  String get payload => const JsonEncoder.withIndent(
    '  ',
  ).convert(widget.ops.data?['checklistBackup']);
  Future<void> run(Future<void> Function() fn) async {
    if (busy || !valid) return;
    setState(() {
      busy = true;
      error = null;
      message = null;
    });
    try {
      await fn();
    } catch (e) {
      if (mounted) {
        setState(() => error = context.t('ui.audit1243'));
      }
    }
    if (mounted) setState(() => busy = false);
  }

  void review(String value) {
    if (!valid) return;
    final file = jsonDecode(value);
    if (file is! Json ||
        file['format'] != 'tap2work-checklists' ||
        file['schemaVersion'] != 1 ||
        file['templates'] is! List ||
        file['folders'] is! List) {
      throw const FormatException('Invalid backup');
    }
    final templates = file['templates'] as List;
    if (templates.isEmpty ||
        templates.length > 650 ||
        (file['folders'] as List).length > 30 ||
        templates.any(
          (t) =>
              t is! Json ||
              t['title'] is! String ||
              t['steps'] is! List ||
              (t['steps'] as List).any((s) => s is! Json),
        )) {
      throw const FormatException('Invalid backup content');
    }
    setState(() {
      preview = file;
      previewRevision = widget.ops.data?['revision'];
      operationId = 'restore-${DateTime.now().microsecondsSinceEpoch}';
    });
  }

  @override
  Widget build(BuildContext context) {
    final count =
        (widget.ops.data?['checklistBackup']?['templates'] as List? ?? [])
            .length;
    return AppEditorScaffold(
      title: context.t('ui.audit615'),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Information(context.t('ui.audit113')),
          const SizedBox(height: 16),
          Text(
            context.t('ui.audit616', args: {'p0': count}),
            style: AppText.section,
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: busy || !valid || count == 0
                ? null
                : () => run(() async {
                    final value = payload;
                    await repository.save(scope, value);
                    if (mounted) {
                      setState(() {
                        stored = value;
                        message = context.t('ui.audit1441');
                      });
                    }
                  }),
            child: Text(context.t('ui.audit114')),
          ),
          TextButton(
            onPressed: busy || !valid || count == 0
                ? null
                : () => run(() async {
                    if (await repository.export(payload) && mounted) {
                      setState(() => message = context.t('ui.audit1442'));
                    }
                  }),
            child: Text(context.t('ui.audit115')),
          ),
          const SizedBox(height: 24),
          Text(context.t('ui.audit116'), style: AppText.section),
          TextButton(
            onPressed: busy || !valid || stored == null
                ? null
                : () => run(() async {
                    review(stored!);
                  }),
            child: Text(context.t('ui.audit117')),
          ),
          OutlinedButton(
            onPressed: busy || !valid
                ? null
                : () => run(() async {
                    final value = await repository.pick();
                    if (value != null && mounted) review(value);
                  }),
            child: Text(context.t('ui.audit118')),
          ),
          if (preview != null && valid) ...[
            const SizedBox(height: 24),
            Text(
              context.t(
                'ui.audit617',
                args: {'p0': (preview!['templates'] as List).length},
              ),
              style: AppText.section,
            ),
            for (final t in (preview!['templates'] as List).take(30))
              Text(
                context.t(
                  'ui.audit618',
                  args: {
                    'p0': t['title'],
                    'p1': (t['steps'] as List? ?? []).length,
                  },
                ),
                style: AppText.caption,
              ),
            const SizedBox(height: 12),
            if (photosToRegister > 0)
              Information(
                context.t('ui.audit619', args: {'p0': photosToRegister}),
              ),
            Information(context.t('ui.audit119')),
            FilledButton(
              onPressed: busy || !valid
                  ? null
                  : () => run(() async {
                      final removedPhotos = photosToRegister;
                      final ok = await widget.ops
                          .act('restore_checklist_backup', {
                            'revision': previewRevision,
                            'operationId': operationId,
                            'backup': preview,
                          });
                      if (mounted) {
                        setState(() {
                          if (ok) {
                            preview = null;
                            message = removedPhotos == 0
                                ? context.t('ui.audit1443')
                                : context.t(
                                    'ui.audit2064',
                                    args: {'p0': removedPhotos},
                                  );
                          } else {
                            error = widget.ops.error;
                          }
                        });
                      }
                    }),
              child: Text(context.t('ui.audit120')),
            ),
          ],
          if (error != null) Information(context.t(error!)),
          if (message != null) Information(message!),
        ],
      ),
    );
  }
}
