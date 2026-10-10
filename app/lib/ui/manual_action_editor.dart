import 'dart:convert';
import 'package:flutter/material.dart';
import '../data/photo_capture_service.dart';
import '../domain/checklist_draft.dart';
import '../domain/manual_media_repository.dart';
import '../state/operations_controller.dart';
import 'components.dart';
import 'photo_registration.dart';
import 'place_guide.dart';

/// Edits the existing execution manual contract; completion stays separate.
class ManualActionEditor extends StatefulWidget {
  const ManualActionEditor({
    super.key,
    required this.ops,
    required this.task,
    required this.step,
  });
  final OperationsController ops;
  final Json task, step;
  @override
  State<ManualActionEditor> createState() => _ManualActionEditorState();
}

class _ManualActionEditorState extends State<ManualActionEditor> {
  late final String actor;
  late final Object? workspace, revision, day;
  late final Json draft;
  late final String original;
  late final TextEditingController imageLink;

  @override
  void initState() {
    super.initState();
    actor = widget.ops.actorId;
    workspace = widget.ops.data?['workspaceId'];
    revision = widget.ops.data?['revision'];
    day = widget.ops.data?['day'];
    draft = {
      for (final key in ['manual', 'imageUrl', 'videoUrl', 'sourceUrl'])
        key: widget.step[key] ?? '',
      'tags': (widget.step['tags'] as List? ?? []).join(', '),
    };
    original = jsonEncode(draft);
    imageLink = TextEditingController(text: draft['imageUrl']);
  }

  @override
  void dispose() {
    imageLink.dispose();
    super.dispose();
  }

  OptimizedPhoto? pending;
  bool saving = false, converting = false, leaving = false;
  String? failure;
  bool get dirty => pending != null || jsonEncode(draft) != original;
  bool get scopeCurrent =>
      widget.ops.actorId == actor &&
      widget.ops.data?['workspaceId'] == workspace &&
      widget.ops.data?['day'] == day &&
      widget.ops.canEditTasks;
  bool get currentStepEditable {
    final task = widget.ops
        .rows('tasks')
        .where((t) => t['id'] == widget.task['id'])
        .firstOrNull;
    final step = (task?['steps'] as List? ?? [])
        .whereType<Json>()
        .where((s) => s['id'] == widget.step['id'])
        .firstOrNull;
    return step != null && step['completedAt'] == null;
  }

  Future<void> close() async {
    if (saving || converting) return;
    final discard =
        !dirty ||
        await showAppDialog<bool>(
              context: context,
              builder: (c) => AlertDialog(
                title: const Text('매뉴얼 편집을 취소할까요?'),
                content: const Text('아직 저장하지 않은 내용이 있어요.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(c, false),
                    child: const Text('계속 수정'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(c, true),
                    child: const Text('변경 버리기'),
                  ),
                ],
              ),
            ) ==
            true;
    if (!discard || !mounted) return;
    setState(() => leaving = true);
    Navigator.pop(context);
  }

  Future<void> save() async {
    if (saving || converting || widget.ops.busy) return;
    final tags = (draft['tags'] as String)
        .split(',')
        .map((tag) => tag.trim().replaceFirst(RegExp(r'^#+'), ''))
        .where((tag) => tag.isNotEmpty)
        .toList();
    final payload = <String, dynamic>{
      'revision': revision,
      'taskId': widget.task['id'],
      'stepId': widget.step['id'],
      for (final key in ['manual', 'imageUrl', 'videoUrl', 'sourceUrl'])
        key: (draft[key] as String).trim(),
      'tags': tags,
    };
    String? problem = checklistStepIssue({
      ...widget.step,
      'tip': widget.step['tip'] ?? '',
      ...payload,
    });
    final source = Uri.tryParse(payload['sourceUrl']);
    if ((payload['sourceUrl'] as String).isNotEmpty &&
        (source?.scheme != 'https' || source?.host.isEmpty != false)) {
      problem = '공식 사진 가이드는 HTTPS 링크를 입력해 주세요.';
    }
    if (tags.length > 20 || tags.any((tag) => tag.length > 30)) {
      problem = '연관어는 최대 20개, 각 30자 이내로 입력해 주세요.';
    }
    if (!scopeCurrent || !currentStepEditable) {
      problem = '매장·권한 또는 업무가 변경됐어요. 다시 열어 주세요.';
    }
    if (widget.ops.data?['revision'] != revision) {
      problem = '다른 변경이 저장됐어요. 최신 매뉴얼을 다시 열어 주세요.';
    }
    if (problem != null) {
      setState(() => failure = problem);
      return;
    }
    setState(() {
      saving = true;
      failure = null;
    });
    try {
      if (pending != null) {
        final reference = await widget.ops.uploadManualPhoto(pending!.bytes);
        if (!mounted) return;
        if (!scopeCurrent ||
            !currentStepEditable ||
            widget.ops.data?['revision'] != revision) {
          throw StateError('매장 또는 업무가 변경됐어요. 다시 열어 주세요.');
        }
        draft['imageUrl'] = reference;
        pending = null;
        payload['imageUrl'] = reference;
      }
      final ok = await widget.ops.act('save_step_manual', payload);
      if (!mounted) return;
      if (ok && scopeCurrent) {
        setState(() => leaving = true);
        Navigator.pop(context);
      } else {
        setState(() => failure = widget.ops.error ?? '저장하지 못했어요. 다시 시도해 주세요.');
      }
    } catch (error) {
      if (mounted) setState(() => failure = '$error');
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Widget field(String name, String label, {int lines = 1, int? limit}) =>
      TextFormField(
        key: ValueKey('action-editor-$name'),
        initialValue: name == 'imageUrl' ? null : draft[name],
        controller: name == 'imageUrl' ? imageLink : null,
        minLines: lines,
        maxLines: lines == 1 ? 1 : 8,
        maxLength: limit,
        decoration: InputDecoration(labelText: label),
        onChanged: (value) => setState(() {
          draft[name] = value;
          failure = null;
        }),
      );

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: leaving,
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop) close();
    },
    child: AppEditorScaffold(
      title: '매뉴얼 편집',
      subtitle: widget.step['title'],
      onClose: close,
      body: AbsorbPointer(
        absorbing: saving,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.large),
          children: [
            field('manual', '방법과 완료 기준', lines: 3, limit: 700),
            const SizedBox(height: 20),
            PhotoRegistrationField(
              value: draft['imageUrl'],
              pending: pending,
              scopeKey: (
                actor,
                workspace,
                widget.task['id'],
                widget.step['id'],
              ),
              isScopeCurrent: () => scopeCurrent && currentStepEditable,
              enabled:
                  !saving &&
                  scopeCurrent &&
                  widget.ops.cloud &&
                  !widget.ops.readOnly,
              previewBuilder: (value) => placePhoto(value, ops: widget.ops),
              onBusyChanged: (value) {
                if (mounted) setState(() => converting = value);
              },
              onChanged: (photo) => setState(() {
                pending = photo;
                failure = null;
              }),
              onRemove: () => setState(() {
                pending = null;
                draft['imageUrl'] = '';
                imageLink.clear();
              }),
            ),
            if (!widget.ops.cloud)
              const Text(
                '촬영한 사진 등록은 로그인한 매장에서 사용할 수 있어요.',
                style: AppText.caption,
              ),
            if (pending == null && !isManualMediaReference(draft['imageUrl']))
              field('imageUrl', '사진 HTTPS 링크 (선택)'),
            const SizedBox(height: 20),
            field('videoUrl', '영상 HTTPS 링크 (선택)'),
            const SizedBox(height: 20),
            field('sourceUrl', '공식 사진 가이드 HTTPS 링크 (선택)'),
            const SizedBox(height: 20),
            field('tags', '#연관어 · 쉼표로 구분'),
            const SizedBox(height: 16),
            const Text(
              '연결된 기본 레시피도 갱신해 다음 주문에 사용해요. 완료 기록은 유지돼요.',
              style: AppText.caption,
            ),
          ],
        ),
      ),
      footer: AppSheetFooter(
        children: [
          if (failure != null)
            Semantics(
              liveRegion: true,
              child: Text(
                failure!,
                style: const TextStyle(color: AppColors.accent),
              ),
            ),
          PressBounce(
            child: FilledButton(
              onPressed: saving || converting ? null : save,
              child: Text(saving ? '저장 중…' : '저장'),
            ),
          ),
        ],
      ),
    ),
  );
}
