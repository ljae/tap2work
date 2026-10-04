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
  });
  final OperationsController ops;
  final String? templateId, folderId;
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
      setState(() => error = '권한 또는 매장이 변경됐어요. 다시 열어 주세요.');
      return;
    }
    if (title.text.trim().isEmpty) {
      setState(() => error = 'TAP 이름을 적어 주세요.');
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
    });
    if (!mounted) return;
    setState(() => saving = false);
    if (ok) {
      setState(() => dirty = false);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.pop(context);
      });
    } else {
      setState(() => error = widget.ops.error ?? '입력 내용은 유지돼요. 다시 시도해 주세요.');
    }
  }

  Future<void> close() async {
    if (saving) return;
    if (dirty) {
      final leave = await showAppDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text('수정 내용을 버릴까요?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('계속 편집'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(c, true),
              child: const Text('버리기'),
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
      title: widget.templateId == null ? 'TAP 추가' : 'TAP 상세 수정',
      onClose: close,
      footer: AppSheetFooter(
        children: [
          const Text(
            '기존 업무·완료 기록은 유지하고 새로 생성되는 업무부터 반영해요.',
            style: AppText.caption,
          ),
          if (error != null) Information(error!),
          FilledButton(
            onPressed: saving || widget.ops.readOnly ? null : save,
            child: Text(saving ? '저장 중…' : '매뉴얼 저장'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          if (linked)
            const Information(
              '공용 연결 TAP이에요. 내용을 수정하면 개인화 항목으로 분리되어 공용 업데이트 대신 백업으로 관리해요.',
            ),
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
              label: const Text('공용 연결을 유지하고 개인화 사본 추가'),
            ),
          const SizedBox(height: 16),
          TextField(
            key: const ValueKey('manual-tap-title'),
            controller: title,
            maxLength: 100,
            enabled: !saving,
            decoration: const InputDecoration(labelText: 'TAP 이름'),
            onChanged: (_) => setState(() => dirty = true),
          ),
          TextField(
            controller: emoji,
            maxLength: 10,
            decoration: const InputDecoration(labelText: '아이콘'),
            onChanged: (_) => setState(() => dirty = true),
          ),
          AppPicker<String>(
            label: '그룹',
            value: folder,
            items: widget.ops
                .rows('checklistFolders')
                .map(
                  (f) => DropdownMenuItem(
                    value: f['id'] as String,
                    child: Text(f['name']),
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
          if (widget.templateId != null)
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
              label: const Text('파트·시간대·TAP 운영 설정'),
            ),
          if (dirty && widget.templateId != null)
            const Text('내용을 저장한 뒤 운영 설정을 바꿀 수 있어요.', style: AppText.caption),
          const SizedBox(height: 24),
          const Text('Task·매뉴얼', style: AppText.section),
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
                          child: const Text('Task 상세 수정'),
                        ),
                        IconButton(
                          tooltip: '위로',
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
                          tooltip: '아래로',
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
                          tooltip: 'Task 삭제',
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
            label: const Text('Task 추가'),
          ),
        ],
      ),
    ),
  );
}
