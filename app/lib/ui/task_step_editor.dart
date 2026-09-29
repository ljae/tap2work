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
      setState(() => error = '편집 권한이 변경됐어요. 내용을 복사한 뒤 다시 열어 주세요.');
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
      error = widget.ops.error ?? '저장하지 못했어요. 입력 내용을 복사한 뒤 최신 업무에서 다시 시도해 주세요.';
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
          Text(stepId == null ? 'Task 추가' : 'Task 수정', style: AppText.title),
          const SizedBox(height: 16),
          TextFormField(
            key: const ValueKey('task-step-title'),
            controller: title,
            autofocus: true,
            enabled: !saving,
            maxLength: 100,
            minLines: 1,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Task 내용'),
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'Task 내용을 입력해 주세요.' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            key: const ValueKey('task-step-manual'),
            controller: manual,
            enabled: !saving,
            maxLength: 700,
            minLines: 2,
            maxLines: 8,
            decoration: const InputDecoration(labelText: '매뉴얼 · 방법과 완료 기준'),
            validator: (v) =>
                v == null || v.trim().isEmpty ? '방법과 완료 기준을 입력해 주세요.' : null,
          ),
          const SizedBox(height: 8),
          Text(
            widget.ops.readOnly
                ? '체험 변경 · 새로고침하면 사라져요.'
                : '오늘 이 미완료 Task와 연결된 기본 양식에 반영해요. 원본 양식이 없는 주문 Task는 오늘 업무에만 반영해요.',
            style: AppText.caption,
          ),
          if (error != null) ...[
            const SizedBox(height: 8),
            Information(error!),
          ],
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              PressBounce(
                child: TextButton(
                  onPressed: saving ? null : widget.onClose,
                  child: const Text('취소'),
                ),
              ),
              PressBounce(
                child: FilledButton(
                  onPressed: saving || widget.ops.busy ? null : save,
                  child: Text(saving ? '저장 중…' : '저장'),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
