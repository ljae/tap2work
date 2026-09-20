import 'dart:convert';
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

/// Owner/manager editor: folder → group → activities, all reorderable by drag and drop
/// with equivalent menu actions. Edits live in an isolated draft until a revision-checked save.
class ChecklistEditor extends StatefulWidget {
  const ChecklistEditor({super.key, required this.ops});
  final OperationsController ops;
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
  bool get enabled => ops.isLeader && ops.actorId == actor && !ops.busy;
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
      await showDialog<bool>(
            context: context,
            builder: (c) => AlertDialog(
              title: const Text('편집을 취소할까요?'),
              content: const Text('저장하지 않은 변경은 사라져요.'),
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
        child: Scaffold(
          appBar: AppBar(
            title: const Text('체크리스트 편집'),
            actions: [
              TextButton(
                onPressed: !enabled || ops.readOnly || !dirty ? null : save,
                child: Text(ops.busy ? '저장 중…' : '저장'),
              ),
            ],
          ),
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 920),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const PageHeading(
                    'MAKE IT YOURS',
                    '우리 매장 체크리스트',
                    '폴더 → 그룹 → 활동과 짧은 매뉴얼. 손잡이를 잡아 끌면 순서가 바뀌고, 그룹을 길게 눌러 다른 폴더에, 활동을 길게 눌러 다른 그룹에 놓을 수 있어요.',
                  ),
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
                    TextButton.icon(
                      onPressed: ops.busy
                          ? null
                          : () async {
                              if (await discard() && mounted) setState(reset);
                            },
                      icon: const Icon(Icons.refresh),
                      label: const Text('최신 목록 다시 불러오기'),
                    ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilledButton.icon(
                        onPressed: enabled ? library : null,
                        icon: const Icon(Icons.auto_stories_outlined),
                        label: const Text('업종별 기본 목록'),
                      ),
                      OutlinedButton.icon(
                        onPressed: enabled ? () => editGroup() : null,
                        icon: const Icon(Icons.add),
                        label: const Text('그룹 만들기'),
                      ),
                      TextButton.icon(
                        onPressed: enabled ? () => editFolder() : null,
                        icon: const Icon(Icons.create_new_folder_outlined),
                        label: const Text('폴더 추가'),
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
                            deleteButtonTooltipMessage: '폴더 이름 수정',
                          ),
                        ),
                    ],
                  ),
                  if (selected != 'general')
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: enabled
                            ? () => change(() {
                                for (final t in templates.where(
                                  (t) => t['folderId'] == selected,
                                )) {
                                  t['folderId'] = 'general';
                                }
                                folders.removeWhere((f) => f['id'] == selected);
                                selected = 'general';
                              })
                            : null,
                        child: const Text('폴더 삭제 · 그룹은 기본 폴더로'),
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
                      '빈 폴더예요. 그룹을 만들거나 다른 폴더의 그룹을 끌어다 놓아 보세요.',
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
                    semanticLabel: '그룹 순서 드래그',
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
                        '${task['emoji'] ?? '📝'} ${task['title']}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        '${task['slot']} · ${checklistRoles[task['requiredRole']]}${place == null ? '' : ' · $place'} · ${steps.length}개 활동',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            IconButton(
              tooltip: open ? '활동 접기' : '활동 펼치기',
              onPressed: () => setState(
                () => open ? collapsed.add(id) : collapsed.remove(id),
              ),
              icon: Icon(open ? Icons.expand_less : Icons.expand_more),
            ),
            PopupMenuButton<String>(
              enabled: enabled,
              tooltip: '그룹 수정·이동·삭제',
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
                const PopupMenuItem(value: 'edit', child: Text('그룹 정보 수정')),
                const PopupMenuItem(value: 'up', child: Text('위로 이동')),
                const PopupMenuItem(value: 'down', child: Text('아래로 이동')),
                for (final f in folders.where(
                  (f) => f['id'] != task['folderId'],
                ))
                  PopupMenuItem<String>(
                    value: f['id'],
                    child: Text('${f['name']} 폴더로 이동'),
                  ),
                const PopupMenuItem(value: 'delete', child: Text('그룹 삭제')),
              ],
            ),
          ],
        ),
      ),
    );
    final card = Card(
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
                child: TextButton.icon(
                  onPressed: enabled && steps.length < checklistStepLimit
                      ? () => editStep(task)
                      : null,
                  icon: const Icon(Icons.add),
                  label: const Text('활동 추가'),
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
            child: Text('${task['emoji'] ?? '📝'} ${task['title']}'),
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
                  semanticLabel: '활동 순서 드래그',
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
                          : '(이름 없는 활동)',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      (step['manual'] as String?)?.isNotEmpty == true
                          ? step['manual']
                          : '매뉴얼을 적어 주세요',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: '활동 삭제',
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
      notice('폴더는 최대 30개예요. 사용하지 않는 폴더를 먼저 정리해 주세요.');
      return;
    }
    var folderName = folder?['name'] as String? ?? '';
    final name = await showDialog<String>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(folder == null ? '새 폴더' : '폴더 이름'),
        content: TextFormField(
          initialValue: folderName,
          onChanged: (value) => folderName = value,
          maxLength: 40,
          autofocus: true,
          decoration: const InputDecoration(labelText: '폴더 이름'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () {
              if (folderName.trim().isNotEmpty) {
                Navigator.pop(c, folderName.trim());
              }
            },
            child: const Text('적용'),
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
      notice('그룹은 최대 150개예요. 필요 없는 그룹을 먼저 정리해 주세요.');
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
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _GroupSheet(task: draft, zones: ops.rows('zones')),
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
        ? <String, dynamic>{'id': newId(), 'title': '', 'manual': '', 'tip': ''}
        : _copy(step);
    final result = await Navigator.of(context).push<Json>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _ActivityEditor(step: draft, groupTitle: task['title']),
      ),
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
  const _GroupSheet({required this.task, required this.zones});
  final Json task;
  final List<Json> zones;
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
            '그룹 정보',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          const Text(
            '한 그룹은 같은 시간대·같은 담당이 이어서 하는 활동 묶음이에요.',
            style: TextStyle(fontSize: 12, color: AppColors.muted),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 72,
                child: TextFormField(
                  initialValue: task['emoji'] ?? '📝',
                  maxLength: 2,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 22),
                  decoration: const InputDecoration(labelText: '아이콘'),
                  onChanged: (v) =>
                      task['emoji'] = v.trim().isEmpty ? '📝' : v.trim(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  initialValue: task['title'],
                  maxLength: 100,
                  autofocus: (task['title'] as String).isEmpty,
                  decoration: const InputDecoration(labelText: '그룹 이름'),
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
          Wrap(
            spacing: 6,
            children: [
              for (final s in checklistSlots)
                ChoiceChip(
                  label: Text(s),
                  selected: task['slot'] == s,
                  onSelected: (_) => setState(() => task['slot'] = s),
                ),
            ],
          ),
          const SizedBox(height: 14),
          const Text('담당 직급', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            children: [
              for (final r in checklistRoles.entries)
                ChoiceChip(
                  label: Text(r.value),
                  selected: task['requiredRole'] == r.key,
                  onSelected: (_) =>
                      setState(() => task['requiredRole'] = r.key),
                ),
            ],
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            initialValue: widget.zones.any((z) => z['id'] == task['zone'])
                ? task['zone']
                : widget.zones.firstOrNull?['id'],
            isExpanded: true,
            decoration: const InputDecoration(labelText: '장소'),
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
            child: FilledButton(
              onPressed: () {
                if ((task['title'] as String).trim().isEmpty) {
                  setState(() => issue = '그룹 이름을 1~100자로 입력해 주세요.');
                  return;
                }
                Navigator.pop(context, task);
              },
              child: const Text('그룹 정보 적용'),
            ),
          ),
        ],
      ),
    ),
  );
}

class _ActivityEditor extends StatefulWidget {
  const _ActivityEditor({required this.step, required this.groupTitle});
  final Json step;
  final String groupTitle;
  @override
  State<_ActivityEditor> createState() => _ActivityEditorState();
}

class _ActivityEditorState extends State<_ActivityEditor> {
  late final Json step = widget.step;
  late final String original = jsonEncode(widget.step);
  bool applying = false;
  String? issue;
  bool get dirty => jsonEncode(step) != original;
  @override
  Widget build(BuildContext context) => PopScope(
    canPop: applying || !dirty,
    onPopInvokedWithResult: (didPop, result) async {
      if (didPop) return;
      final discard = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text('매뉴얼 편집을 취소할까요?'),
          content: const Text('아직 초안에 적용하지 않은 내용이 있어요.'),
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
    child: Scaffold(
      appBar: AppBar(
        title: const Text('활동과 간단 매뉴얼'),
        actions: [
          TextButton(
            onPressed: () {
              final problem = checklistStepIssue(step);
              if (problem != null) {
                setState(() => issue = problem);
                return;
              }
              setState(() => applying = true);
              Navigator.pop(context, step);
            },
            child: const Text('초안에 적용'),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                '그룹 · ${widget.groupTitle.isEmpty ? '(이름 없음)' : widget.groupTitle}',
                style: const TextStyle(fontSize: 12, color: AppColors.muted),
              ),
              if (issue != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Information(issue!),
                ),
              TextFormField(
                initialValue: step['title'],
                maxLength: 100,
                autofocus: (step['title'] as String).isEmpty,
                decoration: const InputDecoration(
                  labelText: '활동 이름',
                  hintText: '예) 핏물 빼기',
                ),
                onChanged: (v) => setState(() {
                  step['title'] = v.trim();
                  issue = null;
                }),
              ),
              TextFormField(
                initialValue: step['manual'],
                minLines: 3,
                maxLines: 8,
                maxLength: 700,
                decoration: const InputDecoration(
                  labelText: '간단 매뉴얼 · 방법과 완료 기준',
                  hintText: '무엇을, 어떤 순서로, 어디까지 하면 끝인지 2~3문장으로.',
                ),
                onChanged: (v) => setState(() {
                  step['manual'] = v.trim();
                  issue = null;
                }),
              ),
              TextFormField(
                initialValue: step['tip'],
                minLines: 1,
                maxLines: 4,
                maxLength: 400,
                decoration: const InputDecoration(labelText: '놓치기 쉬운 노하우 (선택)'),
                onChanged: (v) => setState(() {
                  step['tip'] = v.trim();
                  issue = null;
                }),
              ),
              const SizedBox(height: 20),
              const Information(
                '초안에 적용한 뒤 목록 화면에서 저장해 주세요. 시간·온도·용량 같은 실제 기준은 우리 매장 레시피와 장비 설명서에 맞춰 적어요.',
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
