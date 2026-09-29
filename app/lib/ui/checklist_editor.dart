import 'workplace_screens.dart';
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../domain/checklist_draft.dart';
import '../state/operations_controller.dart';
import 'checklist_library.dart';
import 'components.dart';

List<Json> _rows(dynamic value) => (value as List? ?? []).cast<Json>();
Json _copy(Json value) => jsonDecode(jsonEncode(value)) as Json;

/// Payload for dragging one activity onto another group's header.
class _StepDrag {
  const _StepDrag(this.taskId, this.stepId);
  final String taskId, stepId;
}

/// Owner/manager editor: grouping filter → TAP → Task, all reorderable by drag and drop
/// with equivalent menu actions. Edits live in an isolated draft until a revision-checked save.
class ChecklistEditor extends StatefulWidget {
  const ChecklistEditor({super.key, required this.ops, this.initialFolder});
  final OperationsController ops;
  final String? initialFolder;
  @override
  State<ChecklistEditor> createState() => _ChecklistEditorState();
}

class _ChecklistEditorState extends State<ChecklistEditor> {
  late List<Json> folders, templates;
  late int revision;
  late String actor;
  String selected = 'general';
  bool dirty = false;
  int sequence = 0;
  String? issue;
  final collapsed = <String>{};
  String newId() =>
      'custom-${DateTime.now().microsecondsSinceEpoch}-${sequence++}';

  OperationsController get ops => widget.ops;
  bool get enabled => ops.canEditTasks && ops.actorId == actor && !ops.busy;
  List<String> get zoneIds =>
      ops.rows('zones').map((z) => z['id'] as String).toList();

  @override
  void initState() {
    super.initState();
    reset();
  }

  void reset() {
    final data = _copy(ops.data ?? {});
    folders = _rows(data['checklistFolders']);
    if (folders.isEmpty) {
      folders = [
        {'id': 'general', 'name': '기본 업무'},
      ];
    }
    templates = _rows(data['taskTemplates']);
    revision = data['revision'] ?? 0;
    actor = ops.actorId;
    selected =
        folders.any((f) => templates.any((t) => t['folderId'] == f['id']))
        ? folders.firstWhere(
            (f) => templates.any((t) => t['folderId'] == f['id']),
          )['id']
        : 'general';
    dirty = false;
    issue = null;
    if (folders.any((f) => f['id'] == widget.initialFolder)) {
      selected = widget.initialFolder!;
    }
  }

  void change(VoidCallback action) => setState(() {
    action();
    dirty = true;
    issue = null;
  });

  void notice(String message) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(message)));

  Future<void> save() async {
    if (!enabled) return;
    final problem = checklistDraftIssue(templates);
    if (problem != null) {
      // The inline banner sits at the top of a lazy list; the snackbar is visible from any scroll position.
      setState(() => issue = problem);
      notice('저장하려면 먼저 채워 주세요 · $problem');
      return;
    }
    final ok = await ops.act('save_checklists', {
      'revision': revision,
      'folders': folders,
      'templates': templates,
    });
    if (!mounted) return;
    if (ok) {
      setState(() => dirty = false);
      Navigator.pop(context);
    }
  }

  Future<bool> discard() async =>
      !dirty ||
      await showAppDialog<bool>(
            context: context,
            builder: (c) => AlertDialog(
              title: const Text('편집을 취소할까요?'),
              content: const Text('저장하지 않은 변경은 사라져요.'),
              actions: [
                PressBounce(
                  child: TextButton(
                    onPressed: () => Navigator.pop(c, false),
                    child: const Text('계속 편집'),
                  ),
                ),
                PressBounce(
                  child: FilledButton(
                    onPressed: () => Navigator.pop(c, true),
                    child: const Text('변경 버리기'),
                  ),
                ),
              ],
            ),
          ) ==
          true;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: ops,
    builder: (context, _) {
      final visible = templates
          .where((t) => t['folderId'] == selected)
          .toList();
      return PopScope(
        canPop: !dirty,
        onPopInvokedWithResult: (didPop, result) async {
          if (!didPop && await discard() && context.mounted) {
            setState(() => dirty = false);
            if (context.mounted) Navigator.pop(context);
          }
        },
        child: AppEditorScaffold(
          title: '보드 편집',
          footer: AppSheetFooter(
            children: [
              FilledButton(
                onPressed: !enabled || ops.readOnly || !dirty ? null : save,
                child: Text(ops.busy ? '저장 중…' : '저장'),
              ),
            ],
          ),
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 920),
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  if (ops.readOnly)
                    const Information(
                      '공개 미리보기에서는 자유롭게 편집을 체험해요. 변경은 저장되지 않아요.',
                    ),
                  const Information(
                    '새 매뉴얼은 아직 시작하지 않은 오늘 업무부터 적용돼요. 시작했거나 완료한 업무는 당시 내용과 기록을 유지해요.',
                  ),
                  if (ops.error != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Information('${ops.error}\n초안은 그대로 남아 있어요.'),
                    ),
                  if (ops.data?['revision'] != revision)
                    PressBounce(
                      child: TextButton.icon(
                        onPressed: ops.busy
                            ? null
                            : () async {
                                if (await discard() && mounted) setState(reset);
                              },
                        icon: const Icon(Icons.refresh),
                        label: const Text('최신 목록 다시 불러오기'),
                      ),
                    ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      PressBounce(
                        child: FilledButton.icon(
                          onPressed: enabled ? library : null,
                          icon: const Icon(Icons.auto_stories_outlined),
                          label: const Text('업종별 기본 목록'),
                        ),
                      ),
                      PressBounce(
                        child: OutlinedButton.icon(
                          onPressed: enabled ? () => editGroup() : null,
                          icon: const Icon(Icons.add),
                          label: const Text('TAP 만들기'),
                        ),
                      ),
                      PressBounce(
                        child: TextButton.icon(
                          onPressed: enabled ? () => editFolder() : null,
                          icon: const Icon(Icons.create_new_folder_outlined),
                          label: const Text('TAP그룹 추가'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final f in folders)
                        DragTarget<String>(
                          onWillAcceptWithDetails: (d) =>
                              enabled &&
                              templates.any(
                                (t) =>
                                    t['id'] == d.data &&
                                    t['folderId'] != f['id'],
                              ),
                          onAcceptWithDetails: (d) => change(
                            () => templates.firstWhere(
                              (t) => t['id'] == d.data,
                            )['folderId'] = f['id'],
                          ),
                          builder: (context, candidates, rejected) => InputChip(
                            chipAnimationStyle: AppMotion.chipStyle(context),
                            avatar: const Icon(Icons.folder_outlined, size: 18),
                            backgroundColor: candidates.isNotEmpty
                                ? AppColors.lime
                                : null,
                            label: Text(
                              '${f['name']} · ${templates.where((t) => t['folderId'] == f['id']).length}',
                            ),
                            selected: selected == f['id'],
                            onPressed: () => setState(() => selected = f['id']),
                            onDeleted: enabled ? () => editFolder(f) : null,
                            deleteIcon: const Icon(
                              Icons.edit_outlined,
                              size: 18,
                            ),
                            deleteButtonTooltipMessage: '그룹 이름 수정',
                          ),
                        ),
                    ],
                  ),
                  if (selected != 'general')
                    Align(
                      alignment: Alignment.centerRight,
                      child: PressBounce(
                        child: TextButton(
                          onPressed: enabled
                              ? () => change(() {
                                  for (final t in templates.where(
                                    (t) => t['folderId'] == selected,
                                  )) {
                                    t['folderId'] = 'general';
                                  }
                                  folders.removeWhere(
                                    (f) => f['id'] == selected,
                                  );
                                  selected = 'general';
                                })
                              : null,
                          child: const Text('그룹 삭제 · TAP은 기본 그룹으로'),
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  if (issue != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Information('저장하려면 먼저 채워 주세요 · $issue'),
                    ),
                  if (visible.isEmpty)
                    const Information(
                      '비어 있는 그룹이에요. TAP을 만들거나 다른 그룹의 TAP을 끌어다 놓아 보세요.',
                    ),
                  ReorderableListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    buildDefaultDragHandles: false,
                    itemCount: visible.length,
                    onReorder: (oldIndex, newIndex) {
                      if (!enabled) return;
                      if (newIndex > oldIndex) newIndex--;
                      change(() {
                        final ordered = [...visible];
                        final moved = ordered.removeAt(oldIndex);
                        ordered.insert(newIndex, moved);
                        var index = 0;
                        templates = [
                          for (final t in templates)
                            if (t['folderId'] == selected)
                              ordered[index++]
                            else
                              t,
                        ];
                      });
                    },
                    itemBuilder: (context, index) => groupCard(
                      visible,
                      index,
                      key: ValueKey(visible[index]['id']),
                    ),
                  ),
                  if (dirty)
                    const Padding(
                      padding: EdgeInsets.all(12),
                      child: Text('아직 저장하지 않은 변경이 있어요. 상단의 저장을 눌러 적용해 주세요.'),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );

  Widget groupCard(List<Json> visible, int index, {required Key key}) {
    final task = visible[index];
    final id = task['id'] as String;
    final steps = _rows(task['steps']);
    final place = ops
        .rows('zones')
        .where((z) => z['id'] == task['zone'])
        .firstOrNull?['name'];
    final open = !collapsed.contains(id);
    final header = DragTarget<_StepDrag>(
      onWillAcceptWithDetails: (d) => enabled && d.data.taskId != id,
      onAcceptWithDetails: (d) {
        final error = moveChecklistStep(
          templates: templates,
          fromTaskId: d.data.taskId,
          stepId: d.data.stepId,
          toTaskId: id,
        );
        if (error != null) {
          notice(error);
        } else {
          change(() => collapsed.remove(id));
        }
      },
      builder: (context, candidates, rejected) => Container(
        decoration: BoxDecoration(
          color: candidates.isNotEmpty ? AppColors.lime : null,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            if (enabled)
              ReorderableDragStartListener(
                index: index,
                child: const Padding(
                  padding: EdgeInsets.all(12),
                  child: Icon(
                    Icons.drag_indicator,
                    size: 28,
                    semanticLabel: 'TAP 순서 드래그',
                  ),
                ),
              )
            else
              const SizedBox(width: 12),
            Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: enabled ? () => editGroup(task) : null,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${task['title']}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        '${task['slot']} · ${storeParts(ops).where((p) => p['id'] == task['partId']).firstOrNull?['name'] ?? '전체 파트'}${place == null ? '' : ' · $place'} · Task ${steps.length}개',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            IconButton(
              tooltip: open ? 'Task 접기' : 'Task 펼치기',
              onPressed: () => setState(
                () => open ? collapsed.add(id) : collapsed.remove(id),
              ),
              icon: Icon(open ? Icons.expand_less : Icons.expand_more),
            ),
            PopupMenuButton<String>(
              popUpAnimationStyle: AppMotion.dialogStyle(context),
              enabled: enabled,
              tooltip: 'TAP 수정·이동·삭제',
              onSelected: (value) {
                if (value == 'edit') {
                  editGroup(task);
                } else if (value == 'delete') {
                  change(() => templates.remove(task));
                } else if (value == 'up' || value == 'down') {
                  final target = index + (value == 'up' ? -1 : 1);
                  if (target >= 0 && target < visible.length) {
                    change(() {
                      final a = templates.indexOf(task),
                          b = templates.indexOf(visible[target]);
                      templates[a] = visible[target];
                      templates[b] = task;
                    });
                  }
                } else {
                  change(() => task['folderId'] = value);
                }
              },
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'edit', child: Text('TAP 정보 수정')),
                const PopupMenuItem(value: 'up', child: Text('위로 이동')),
                const PopupMenuItem(value: 'down', child: Text('아래로 이동')),
                for (final f in folders.where(
                  (f) => f['id'] != task['folderId'],
                ))
                  PopupMenuItem<String>(
                    value: f['id'],
                    child: Text('${f['name']} 그룹으로 이동'),
                  ),
                const PopupMenuItem(value: 'delete', child: Text('TAP 삭제')),
              ],
            ),
          ],
        ),
      ),
    );
    final card = AppCard(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 4, 8, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            header,
            if (open) ...[
              ReorderableListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                buildDefaultDragHandles: false,
                itemCount: steps.length,
                onReorder: (oldIndex, newIndex) {
                  if (!enabled) return;
                  if (newIndex > oldIndex) newIndex--;
                  change(() {
                    final list = [...steps];
                    list.insert(newIndex, list.removeAt(oldIndex));
                    task['steps'] = list;
                  });
                },
                itemBuilder: (context, i) => activityRow(
                  task,
                  steps,
                  i,
                  key: ValueKey('$id-${steps[i]['id']}'),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: PressBounce(
                  child: TextButton.icon(
                    onPressed: enabled && steps.length < checklistStepLimit
                        ? () => editStep(task)
                        : null,
                    icon: const Icon(Icons.add),
                    label: const Text('Task 추가'),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
    return LongPressDraggable<String>(
      key: key,
      data: id,
      maxSimultaneousDrags: enabled ? 1 : 0,
      feedback: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 260,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text('${task['title']}'),
          ),
        ),
      ),
      childWhenDragging: Opacity(opacity: .35, child: card),
      child: card,
    );
  }

  Widget activityRow(Json task, List<Json> steps, int i, {required Key key}) {
    final step = steps[i];
    final row = Padding(
      padding: const EdgeInsets.only(left: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (enabled)
            ReorderableDragStartListener(
              index: i,
              child: const Padding(
                padding: EdgeInsets.all(10),
                child: Icon(
                  Icons.drag_handle,
                  size: 22,
                  color: AppColors.muted,
                  semanticLabel: 'Task 순서 드래그',
                ),
              ),
            )
          else
            const SizedBox(width: 10),
          Text(
            '${i + 1}',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.muted,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: enabled ? () => editStep(task, step) : null,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (step['title'] as String?)?.isNotEmpty == true
                          ? step['title']
                          : '(이름 없는 Task)',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      (step['manual'] as String?)?.isNotEmpty == true
                          ? step['manual']
                          : '매뉴얼을 적어 주세요',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Task 삭제',
            onPressed: enabled && steps.length > 1
                ? () => change(() => (task['steps'] as List).remove(step))
                : null,
            icon: const Icon(Icons.delete_outline, size: 20),
          ),
        ],
      ),
    );
    return LongPressDraggable<_StepDrag>(
      key: key,
      data: _StepDrag(task['id'], step['id']),
      maxSimultaneousDrags: enabled ? 1 : 0,
      feedback: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 240,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Text('↕ ${step['title']}'),
          ),
        ),
      ),
      childWhenDragging: Opacity(opacity: .35, child: row),
      child: row,
    );
  }

  Future<void> editFolder([Json? folder]) async {
    if (folder == null && folders.length >= checklistFolderLimit) {
      notice('TAP그룹은 최대 30개예요. 사용하지 않는 그룹을 먼저 정리해 주세요.');
      return;
    }
    var folderName = folder?['name'] as String? ?? '';
    final name = await showAppFormSheet<String>(
      context: context,
      builder: (c) => AppSheetPanel(
        title: Text(folder == null ? '새 TAP그룹' : 'TAP그룹 이름'),
        content: TextFormField(
          initialValue: folderName,
          onChanged: (value) => folderName = value,
          maxLength: 40,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'TAP그룹 이름'),
        ),
        actions: [
          PressBounce(
            child: TextButton(
              onPressed: () => Navigator.pop(c),
              child: const Text('취소'),
            ),
          ),
          PressBounce(
            child: FilledButton(
              onPressed: () {
                if (folderName.trim().isNotEmpty) {
                  Navigator.pop(c, folderName.trim());
                }
              },
              child: const Text('적용'),
            ),
          ),
        ],
      ),
    );
    if (name != null && mounted) {
      change(() {
        if (folder == null) {
          final id = newId();
          folders.add({'id': id, 'name': name});
          selected = id;
        } else {
          folder['name'] = name;
        }
      });
    }
  }

  /// Group info sheet: title, icon, time bucket, rank and place. A new group then opens its first activity.
  Future<void> editGroup([Json? task]) async {
    if (task == null && templates.length >= checklistTaskLimit) {
      notice('TAP은 최대 150개예요. 필요 없는 TAP을 먼저 정리해 주세요.');
      return;
    }
    final draft = task == null
        ? <String, dynamic>{
            'id': newId(),
            'title': '',
            'emoji': '📝',
            'folderId': selected,
            'slot': '오픈',
            'requiredRole': 'all',
            'zone': zoneIds.firstOrNull ?? 'entrance',
            'steps': <Json>[],
            'sourceIds': <String>[],
          }
        : _copy(task);
    final result = await showModalBottomSheet<Json>(
      context: context,
      sheetAnimationStyle: AppMotion.panelStyle(context),
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _GroupSheet(
        task: draft,
        parts: storeParts(ops),
        zones: ops.rows('zones'),
      ),
    );
    if (result == null || !mounted) return;
    change(() {
      if (task == null) {
        templates.add(result);
      } else {
        templates[templates.indexOf(task)] = result;
      }
    });
    if (task == null) await editStep(result);
  }

  Future<void> editStep(Json task, [Json? step]) async {
    final draft = step == null
        ? <String, dynamic>{
            'id': newId(),
            'title': '',
            'manual': '',
            'tip': '',
            'tags': <String>[],
          }
        : _copy(step);
    final result = await showAppSheet(
      context,
      builder: (_) => _ActivityEditor(step: draft, groupTitle: task['title']),
    );
    if (result == null || !mounted) return;
    change(() {
      final steps = _rows(task['steps']);
      if (step == null) {
        steps.add(result);
      } else {
        steps[steps.indexOf(step)] = result;
      }
      task['steps'] = steps;
      collapsed.remove(task['id']);
    });
  }

  Future<void> library() => showChecklistLibrary(
    context,
    catalog: ops.data?['checklistLibrary'] as Json? ?? {},
    templates: templates,
    folders: folders,
    zoneIds: zoneIds,
    newFolderId: newId,
    onImport: (plan) => change(() {
      if (plan.folder != null) folders.add(plan.folder!);
      selected = plan.folderId;
      templates.addAll(plan.tasks);
    }),
  );
}

class _GroupSheet extends StatefulWidget {
  const _GroupSheet({
    required this.task,
    required this.zones,
    required this.parts,
  });
  final Json task;
  final List<Json> zones;
  final List<Json> parts;
  @override
  State<_GroupSheet> createState() => _GroupSheetState();
}

class _GroupSheetState extends State<_GroupSheet> {
  late final Json task = widget.task;
  String? issue;
  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'TAP 정보',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          const Text(
            '하나의 TAP에는 같은 업무를 이루는 Task이 들어가요.',
            style: TextStyle(fontSize: 13, color: AppColors.muted),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 72,
                child: Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Column(
                    children: [
                      const Icon(
                        CupertinoIcons.list_bullet,
                        color: AppColors.green,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'TAP',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  initialValue: task['title'],
                  maxLength: 100,
                  autofocus: (task['title'] as String).isEmpty,
                  decoration: const InputDecoration(labelText: 'TAP 이름'),
                  onChanged: (v) => setState(() {
                    task['title'] = v.trim();
                    issue = null;
                  }),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text('시간대', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          AppChoiceGroup<String>(
            values: checklistSlots,
            selected: task['slot'] as String,
            labelOf: (slot) => slot,
            onSelected: (slot) => setState(() => task['slot'] = slot),
          ),
          const SizedBox(height: 14),
          const Text('담당 파트', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          AppChoiceGroup<String>(
            values: [
              'all',
              ...widget.parts
                  .where((p) => p['hidden'] != true)
                  .map((p) => p['id'] as String),
            ],
            selected: task['partId'] ?? 'all',
            labelOf: (id) => id == 'all'
                ? '전체 파트'
                : widget.parts.firstWhere((p) => p['id'] == id)['name'],
            onSelected: (id) => setState(() {
              task['partId'] = id == 'all' ? null : id;
              task['requiredRole'] = 'all';
            }),
          ),
          const SizedBox(height: 14),
          AppPicker<String>(
            label: '장소',
            value: widget.zones.any((z) => z['id'] == task['zone'])
                ? task['zone']
                : widget.zones.firstOrNull?['id'],
            items: [
              for (final z in widget.zones)
                DropdownMenuItem<String>(
                  value: z['id'],
                  child: Text(z['name']),
                ),
            ],
            onChanged: (v) => task['zone'] = v,
          ),
          if (issue != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Information(issue!),
            ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: PressBounce(
              child: FilledButton(
                onPressed: () {
                  if ((task['title'] as String).trim().isEmpty) {
                    setState(() => issue = 'TAP 이름을 1~100자로 입력해 주세요.');
                    return;
                  }
                  Navigator.pop(context, task);
                },
                child: const Text('TAP 정보 적용'),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

/// Opens one reusable Task manual from the manual directory, never the board.
class ManualTaskEditor extends StatefulWidget {
  const ManualTaskEditor({
    super.key,
    required this.ops,
    required this.templateId,
    required this.sourceStepId,
  });
  final OperationsController ops;
  final String templateId, sourceStepId;

  @override
  State<ManualTaskEditor> createState() => _ManualTaskEditorState();
}

class _ManualTaskEditorState extends State<ManualTaskEditor> {
  late final int openingRevision;
  late final String openingActor;

  @override
  void initState() {
    super.initState();
    openingRevision = widget.ops.data?['revision'] ?? -1;
    openingActor = widget.ops.actorId;
  }

  late final Json? sourceTemplate = widget.ops
      .rows('taskTemplates')
      .where((t) => t['id'] == widget.templateId && t['archivedAt'] == null)
      .firstOrNull;
  late final Json? sourceStep = (sourceTemplate?['steps'] as List? ?? [])
      .cast<Json>()
      .where((s) => s['id'] == widget.sourceStepId)
      .firstOrNull;

  Future<String?> save(Json draft) async {
    final ops = widget.ops;
    if (!ops.canEditTasks || ops.actorId != openingActor || ops.busy) {
      return '편집 권한 또는 매장이 변경됐어요. 다시 열어 주세요.';
    }
    if (ops.data?['revision'] != openingRevision) {
      return '다른 변경이 저장됐어요. 최신 매뉴얼을 다시 열어 주세요.';
    }
    if (ops.readOnly) {
      final updated = ops.previewUpdateManualStep(
        widget.templateId,
        widget.sourceStepId,
        draft,
      );
      return updated ? null : '이 Task를 찾지 못했어요. 다시 열어 주세요.';
    }
    final snapshot = _copy(ops.data!);
    final templates = _rows(snapshot['taskTemplates']);
    final target = templates
        .where((t) => t['id'] == widget.templateId)
        .firstOrNull;
    if (target == null || target['archivedAt'] != null) {
      return '이 Task를 찾지 못했어요. 다시 열어 주세요.';
    }
    final step = _rows(
      target['steps'],
    ).where((s) => s['id'] == widget.sourceStepId).firstOrNull;
    if (step == null) return '이 Task를 찾지 못했어요. 다시 열어 주세요.';
    step.addAll(draft);
    final ok = await ops.act('save_checklists', {
      'revision': openingRevision,
      'folders': snapshot['checklistFolders'],
      'templates': templates,
    });
    return ok ? null : (ops.error ?? '저장하지 못했어요. 다시 시도해 주세요.');
  }

  @override
  Widget build(BuildContext context) {
    if (sourceTemplate == null || sourceStep == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('매뉴얼 편집')),
        body: const Center(
          child: Information('이 Task를 찾지 못했어요. 목록을 새로고침해 주세요.'),
        ),
      );
    }
    return _ActivityEditor(
      step: _copy(sourceStep!),
      groupTitle: '${sourceTemplate!['title'] ?? ''}',
      onSave: save,
      previewOnly: widget.ops.readOnly,
    );
  }
}

class _ActivityEditor extends StatefulWidget {
  const _ActivityEditor({
    required this.step,
    required this.groupTitle,
    this.onSave,
    this.previewOnly = false,
  });
  final Json step;
  final String groupTitle;
  final Future<String?> Function(Json draft)? onSave;
  final bool previewOnly;
  @override
  State<_ActivityEditor> createState() => _ActivityEditorState();
}

class _ActivityEditorState extends State<_ActivityEditor> {
  late final Json step = widget.step;
  late final String original = jsonEncode(widget.step);
  bool applying = false, saving = false;
  String? issue;
  bool get dirty => jsonEncode(step) != original;

  Future<void> submit() async {
    final problem = checklistStepIssue(step);
    if (problem != null) {
      setState(() => issue = problem);
      return;
    }
    if (widget.onSave != null) {
      setState(() {
        saving = true;
        issue = null;
      });
      final failure = await widget.onSave!(step);
      if (!mounted) return;
      setState(() => saving = false);
      if (failure != null) {
        setState(() => issue = failure);
        return;
      }
    }
    setState(() => applying = true);
    if (mounted) Navigator.pop(context, step);
  }

  Widget field(
    String name,
    String label, {
    String? hint,
    int lines = 1,
    int? limit,
  }) => TextFormField(
    initialValue: step[name] ?? '',
    minLines: lines,
    maxLines: lines == 1 ? 1 : lines + 5,
    maxLength: limit,
    keyboardType: name.endsWith('Url')
        ? TextInputType.url
        : lines > 1
        ? TextInputType.multiline
        : TextInputType.text,
    textInputAction: lines > 1 ? TextInputAction.newline : TextInputAction.next,
    decoration: InputDecoration(
      labelText: label,
      hintText: hint,
      alignLabelWithHint: true,
    ),
    onChanged: (v) => setState(() {
      step[name] = v.trim();
      issue = null;
    }),
  );

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: applying || (!saving && !dirty),
    onPopInvokedWithResult: (didPop, result) async {
      if (didPop || saving) return;
      final discard = await showAppDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text('매뉴얼 편집을 취소할까요?'),
          content: const Text('아직 저장하지 않은 내용이 있어요.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('계속 편집'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(c, true),
              child: const Text('변경 버리기'),
            ),
          ],
        ),
      );
      if (discard == true && context.mounted) {
        setState(() => applying = true);
        Navigator.pop(context);
      }
    },
    child: AppEditorScaffold(
      title: widget.onSave == null ? 'Task과 간단 매뉴얼' : '매뉴얼 편집',
      subtitle: widget.groupTitle.isEmpty ? null : 'TAP · ${widget.groupTitle}',
      body: AbsorbPointer(
        absorbing: saving,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 688),
            child: ListView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              children: [
                if (widget.previewOnly)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 20),
                    child: Information('공개 샘플에서는 새로고침하면 원래 내용으로 돌아가요.'),
                  ),
                AppFormSection(
                  title: '업무 안내',
                  description: '방법과 완료 기준을 짧고 명확하게 적어 주세요.',
                  children: [
                    field('title', 'Task 이름', hint: '예) 핏물 빼기', limit: 100),
                    field(
                      'manual',
                      '간단 매뉴얼 · 방법과 완료 기준',
                      hint: '무엇을, 어떤 순서로, 어디까지 하면 끝인지 적어요.',
                      lines: 4,
                      limit: 700,
                    ),
                  ],
                ),
                AppFormSection(
                  title: '추가 안내',
                  description: '필요한 경우에만 입력해 주세요.',
                  children: [
                    field('tip', '놓치기 쉬운 노하우 (선택)', lines: 2, limit: 400),
                    TextFormField(
                      initialValue: ((step['tags'] as List?) ?? []).join(', '),
                      decoration: const InputDecoration(
                        labelText: '#연관어 (쉼표로 구분)',
                        hintText: '주문취소, 환불',
                        helperText: '최대 20개, 각 30자 이내',
                      ),
                      onChanged: (value) => setState(() {
                        step['tags'] = value
                            .split(',')
                            .map(
                              (tag) =>
                                  tag.trim().replaceFirst(RegExp(r'^#+'), ''),
                            )
                            .where((tag) => tag.isNotEmpty)
                            .toList();
                        issue = null;
                      }),
                    ),
                  ],
                ),
                AppFormSection(
                  title: '참고 자료',
                  description: '사진이나 영상이 있으면 HTTPS 링크를 넣어 주세요.',
                  children: [
                    field('imageUrl', '사진 HTTPS 링크 (선택)'),
                    field('videoUrl', '영상 HTTPS 링크 (선택)'),
                    field('sourceUrl', '공식 사진 가이드 HTTPS 링크 (선택)'),
                  ],
                ),
                Text(
                  widget.onSave == null
                      ? '초안에 적용한 뒤 보드 화면에서 저장해 주세요.'
                      : '이 Task의 매뉴얼만 바꿔요. 이미 시작한 업무의 기록은 유지돼요.',
                  style: AppText.caption,
                ),
              ],
            ),
          ),
        ),
      ),
      footer: AppSheetFooter(
        children: [
          if (issue != null)
            Semantics(
              liveRegion: true,
              child: Text(
                issue!,
                style: AppText.caption.copyWith(color: AppColors.accent),
              ),
            ),
          FilledButton(
            onPressed: saving ? null : submit,
            child: Text(
              saving
                  ? '저장 중…'
                  : widget.onSave == null
                  ? '초안에 적용'
                  : '매뉴얼 저장',
            ),
          ),
        ],
      ),
    ),
  );
}
