import '../l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import '../state/operations_controller.dart';
import 'components.dart';

/// An isolated inline draft. Polling never replaces typed text or its revision.
class TaskStepEditor extends StatefulWidget {
  const TaskStepEditor({
    super.key,
    required this.ops,
    required this.task,
    this.step,
    required this.onClose,
  });
  final OperationsController ops;
  final Json task;
  final Json? step;
  final VoidCallback onClose;
  @override
  State<TaskStepEditor> createState() => _TaskStepEditorState();
}

class _TaskStepEditorState extends State<TaskStepEditor> {
  late final title = TextEditingController(text: widget.step?['title'] ?? '');
  late final manual = TextEditingController(text: widget.step?['manual'] ?? '');
  late final Object? revision;
  late final String actor, taskId;
  late final String? stepId;

  @override
  void initState() {
    super.initState();
    revision = widget.ops.data?['revision'];
    actor = widget.ops.actorId;
    taskId = widget.task['id'] as String;
    stepId = widget.step?['id'] as String?;
  }

  final form = GlobalKey<FormState>();
  bool saving = false;
  String? error;

  @override
  void dispose() {
    title.dispose();
    manual.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if (saving || !form.currentState!.validate()) return;
    if (actor != widget.ops.actorId || !widget.ops.canEditTasks) {
      setState(() => error = context.t('ui.audit1274'));
      return;
    }
    setState(() {
      saving = true;
      error = null;
    });
    final draft = <String, dynamic>{
      'title': title.text.trim(),
      'manual': manual.text.trim(),
    };
    final ok = widget.ops.readOnly
        ? widget.ops.previewSaveTaskStep(taskId, stepId, draft)
        : await widget.ops.act('save_task_step', {
            'revision': revision,
            'taskId': taskId,
            'stepId': stepId,
            ...draft,
          });
    if (!mounted) return;
    if (ok) {
      widget.onClose();
      return;
    }
    setState(() {
      saving = false;
      error = widget.ops.error ?? context.t('ui.audit1275');
    });
  }

  @override
  Widget build(BuildContext context) => Surface(
    padding: const EdgeInsets.all(16),
    child: Form(
      key: form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            stepId == null ? context.t('ui.audit31') : context.t('ui.audit970'),
            style: AppText.title,
          ),
          const SizedBox(height: 16),
          TextFormField(
            key: const ValueKey('task-step-title'),
            controller: title,
            autofocus: true,
            enabled: !saving,
            maxLength: 100,
            minLines: 1,
            maxLines: 3,
            decoration: InputDecoration(labelText: context.t('ui.audit398')),
            validator: (v) => v == null || v.trim().isEmpty
                ? context.t('ui.audit1638')
                : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            key: const ValueKey('task-step-manual'),
            controller: manual,
            enabled: !saving,
            maxLength: 700,
            minLines: 2,
            maxLines: 8,
            decoration: InputDecoration(labelText: context.t('ui.audit399')),
            validator: (v) => v == null || v.trim().isEmpty
                ? context.t('ui.audit1639')
                : null,
          ),
          const SizedBox(height: 8),
          Text(
            widget.ops.readOnly
                ? context.t('ui.audit971')
                : context.t('ui.audit972'),
            style: AppText.caption,
          ),
          if (error != null) ...[
            const SizedBox(height: 8),
            Information(context.t(error!)),
          ],
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              PressBounce(
                child: TextButton(
                  onPressed: saving ? null : widget.onClose,
                  child: Text(context.t('ui.audit33')),
                ),
              ),
              PressBounce(
                child: FilledButton(
                  onPressed: saving || widget.ops.busy ? null : save,
                  child: Text(
                    saving ? context.t('ui.audit532') : context.t('ui.audit51'),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
