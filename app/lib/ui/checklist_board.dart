import 'dart:convert';
import 'package:flutter/material.dart';
import '../state/operations_controller.dart';
import '../domain/checklist_draft.dart';
import 'components.dart';

const _slots = ['오픈', '준비', '피크', '마감'];
const _roles = {
  'all': '누구나',
  'crew': '크루',
  'cook': '조리 담당',
  'manager': '매니저',
  'owner': '사장님',
};
List<Json> _rows(dynamic value) => (value as List? ?? []).cast<Json>();
Json _copy(Json value) => jsonDecode(jsonEncode(value)) as Json;
String _stamp(dynamic value) {
  final date = DateTime.tryParse(
    '$value',
  )?.toUtc().add(const Duration(hours: 9));
  return date == null
      ? ''
      : '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
}

class ChecklistBoard extends StatefulWidget {
  const ChecklistBoard({super.key, required this.ops, required this.onStock});
  final OperationsController ops;
  final Future<void> Function(Json task) onStock;
  @override
  State<ChecklistBoard> createState() => _ChecklistBoardState();
}

class _ChecklistBoardState extends State<ChecklistBoard> {
  String slot = '전체', role = 'all-filter', folder = 'all-filter';
  bool folders = false;
  @override
  Widget build(BuildContext context) {
    final ops = widget.ops;
    final all = ops.rows('tasks');
    final groups = ops.rows('checklistFolders');
    String folderOf(Json task) => task['kind'] == 'stock'
        ? 'stock'
        : (ops
                      .rows('taskTemplates')
                      .where((t) => t['id'] == task['templateId'])
                      .firstOrNull?['folderId'] ??
                  task['folderId'] ??
                  'general')
              as String;
    final visible = all
        .where(
          (t) =>
              (slot == '전체' || t['slot'] == slot) &&
              (role == 'all-filter' || t['requiredRole'] == role) &&
              (folder == 'all-filter' || folderOf(t) == folder),
        )
        .toList();
    visible.sort(
      (a, b) => ((a['displayOrder'] ?? -1) as int).compareTo(
        (b['displayOrder'] ?? -1) as int,
      ),
    );
    final displayGroups = [
      ...groups,
      if (groups.isEmpty) {'id': 'general', 'name': '기본 업무'},
      {'id': 'stock', 'name': '발주 후 재고 확인'},
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageHeading(
          'CHECK & LEARN',
          '작은 행동이, 우리 노하우 🌱',
          '오늘 ${all.where((t) => t['completedAt'] != null).length}/${all.length}개 업무 완료 · 카드를 열어 방법을 보고 하나씩 확인해요.',
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ChoiceChip(
              label: const Text('카드 보기'),
              avatar: const Icon(Icons.view_agenda_outlined, size: 18),
              selected: !folders,
              onSelected: (_) => setState(() => folders = false),
            ),
            ChoiceChip(
              label: const Text('폴더 보기'),
              avatar: const Icon(Icons.folder_outlined, size: 18),
              selected: folders,
              onSelected: (_) => setState(() => folders = true),
            ),
            if (ops.isLeader)
              OutlinedButton.icon(
                onPressed: ops.busy
                    ? null
                    : () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => ChecklistEditor(ops: ops),
                        ),
                      ),
                icon: const Icon(Icons.tune),
                label: const Text('목록 정리 · 업종 가져오기'),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 7,
          children: [
            for (final s in ['전체', ..._slots])
              ChoiceChip(
                label: Text(s),
                selected: slot == s,
                onSelected: (_) => setState(() => slot = s),
              ),
          ],
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: role,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: '담당 직급',
            border: OutlineInputBorder(),
          ),
          items: [
            const DropdownMenuItem(
              value: 'all-filter',
              child: Text('모든 담당 보기'),
            ),
            for (final r in _roles.entries)
              DropdownMenuItem(value: r.key, child: Text(r.value)),
          ],
          onChanged: (v) => setState(() => role = v!),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 6,
          children: [
            ChoiceChip(
              label: const Text('전체 폴더'),
              selected: folder == 'all-filter',
              onSelected: (_) => setState(() => folder = 'all-filter'),
            ),
            for (final f in displayGroups)
              ChoiceChip(
                label: Text(f['name']),
                selected: folder == f['id'],
                onSelected: (_) => setState(() => folder = f['id']),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (visible.isEmpty) const Information('이 조건에 맞는 할 일이 없어요 🌱'),
        if (folders) ...[
          for (final f in displayGroups)
            if (visible.any((t) => folderOf(t) == f['id']))
              Card(
                child: ExpansionTile(
                  key: PageStorageKey('folder-${f['id']}'),
                  leading: const Icon(Icons.folder_outlined),
                  title: Text(f['name']),
                  subtitle: Text(
                    '${visible.where((t) => folderOf(t) == f['id']).length}개 업무',
                  ),
                  childrenPadding: const EdgeInsets.all(8),
                  children: [
                    for (final t in visible.where(
                      (t) => folderOf(t) == f['id'],
                    ))
                      taskCard(t),
                  ],
                ),
              ),
        ] else ...[
          for (final t in visible) taskCard(t),
        ],
      ],
    );
  }

  Widget taskCard(Json task) {
    final ops = widget.ops;
    final steps = _rows(task['steps']);
    final complete = task['completedAt'] != null;
    final place = ops
        .rows('zones')
        .where((z) => z['id'] == task['zone'])
        .firstOrNull?['name'];
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Surface(
        padding: const EdgeInsets.all(8),
        color: complete ? const Color(0xFFEDF1E6) : AppColors.white,
        child: ExpansionTile(
          key: PageStorageKey('task-${task['id']}'),
          initiallyExpanded: task['kind'] == 'stock',
          title: Text(
            '${task['emoji']} ${task['title']}',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          subtitle: Text(
            '${task['slot']} · ${_roles[task['requiredRole']] ?? '누구나'}${place == null ? '' : ' · $place'}${steps.isEmpty ? '' : ' · ${steps.where((s) => s['completedAt'] != null).length}/${steps.length} 행위'}${complete ? ' · 완료' : ''}',
          ),
          childrenPadding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
          children: [
            if (steps.isNotEmpty)
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Text(
                  '방법을 읽고 실제로 마쳤을 때 확인해요.',
                  style: TextStyle(color: AppColors.muted),
                ),
              ),
            for (final (i, step) in steps.indexed)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.paper,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${i + 1}. ${step['title']}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      step['manual'] ?? '',
                      style: const TextStyle(height: 1.6),
                    ),
                    if ((step['tip'] ?? '').isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          '💡 ${step['tip']}',
                          style: const TextStyle(
                            fontSize: 12,
                            height: 1.6,
                            color: AppColors.muted,
                          ),
                        ),
                      ),
                    if (step['completedAt'] != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Text(
                          '✓ ${step['completedBy']['name']} · ${_stamp(step['completedAt'])}',
                        ),
                      )
                    else
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed:
                              ops.busy ||
                                  ops.readOnly ||
                                  task['canComplete'] != true
                              ? null
                              : () => ops.act('complete_step', {
                                  'taskId': task['id'],
                                  'stepId': step['id'],
                                }),
                          icon: const Icon(Icons.check_circle_outline),
                          label: Text('행위 ${i + 1} 확인'),
                        ),
                      ),
                  ],
                ),
              ),
            if (complete)
              Text(
                '✓ ${task['completedBy']['name']}님이 ${_stamp(task['completedAt'])} 확인했어요',
              )
            else if (steps.isEmpty)
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed:
                      ops.busy || ops.readOnly || task['canComplete'] != true
                      ? null
                      : () => task['kind'] == 'stock'
                            ? widget.onStock(task)
                            : ops.act('complete_task', {'taskId': task['id']}),
                  child: Text(task['kind'] == 'stock' ? '재고 수량 확인하기' : '확인했어요'),
                ),
              ),
            if (task['canComplete'] != true && !complete)
              Text('${_roles[task['requiredRole']]} 담당 업무'),
          ],
        ),
      ),
    );
  }
}

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
  String newId() =>
      'custom-${DateTime.now().microsecondsSinceEpoch}-${sequence++}';
  @override
  void initState() {
    super.initState();
    reset();
  }

  void reset() {
    final data = _copy(widget.ops.data ?? {});
    folders = _rows(data['checklistFolders']);
    if (folders.isEmpty) {
      folders = [
        {'id': 'general', 'name': '기본 업무'},
      ];
    }
    templates = _rows(data['taskTemplates']);
    revision = data['revision'] ?? 0;
    actor = widget.ops.actorId;
    selected = 'general';
    dirty = false;
  }

  void change(VoidCallback action) => setState(() {
    action();
    dirty = true;
  });
  Future<void> save() async {
    if (widget.ops.actorId != actor ||
        !widget.ops.isLeader ||
        widget.ops.busy) {
      return;
    }
    final ok = await widget.ops.act('save_checklists', {
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
    animation: widget.ops,
    builder: (context, _) {
      final ops = widget.ops;
      final visible = templates
          .where((t) => t['folderId'] == selected)
          .toList();
      final enabled = ops.isLeader && ops.actorId == actor && !ops.busy;
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
            title: const Text('우리 매장 체크리스트'),
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
                    '필요한 일만, 편하게.',
                    '폴더에 업무를 담고, 업무 안에 작은 행위와 매뉴얼을 넣어요.',
                  ),
                  if (ops.readOnly)
                    const Information(
                      '공개 미리보기에서는 자유롭게 편집을 체험해요. 변경은 저장되지 않아요.',
                    ),
                  const Information(
                    '새 매뉴얼은 아직 시작하지 않은 오늘 업무부터 적용돼요. 시작했거나 완료한 업무는 당시 내용과 기록을 유지해요. 시작한 업무를 삭제하면 내일부터 제외해요.',
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
                        onPressed: enabled ? () => editTask() : null,
                        icon: const Icon(Icons.add),
                        label: const Text('업무 만들기'),
                      ),
                      TextButton.icon(
                        onPressed: enabled ? () => editFolder() : null,
                        icon: const Icon(Icons.create_new_folder_outlined),
                        label: const Text('폴더 추가'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '카드를 길게 눌러 폴더로 옮겨요. 카드 오른쪽 메뉴로도 이동할 수 있어요.',
                    style: TextStyle(fontSize: 12, color: AppColors.muted),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final f in folders)
                        DragTarget<String>(
                          onWillAcceptWithDetails: (d) =>
                              enabled &&
                              templates.any((t) => t['id'] == d.data),
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
                  const SizedBox(height: 14),
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
                        child: const Text('폴더 삭제 · 업무는 기본 폴더로'),
                      ),
                    ),
                  if (visible.isEmpty)
                    const Information('빈 폴더예요. 업무를 만들거나 다른 폴더의 카드를 옮겨 보세요.'),
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
                    itemBuilder: (context, index) {
                      final task = visible[index];
                      final card = Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      task['title'],
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                  PopupMenuButton<String>(
                                    enabled: enabled,
                                    tooltip: '업무 수정·이동·삭제',
                                    onSelected: (value) {
                                      if (value == 'edit') {
                                        editTask(task);
                                      } else if (value == 'delete') {
                                        change(() => templates.remove(task));
                                      } else if (value == 'up' ||
                                          value == 'down') {
                                        final target =
                                            index + (value == 'up' ? -1 : 1);
                                        if (target >= 0 &&
                                            target < visible.length) {
                                          change(() {
                                            final a = templates.indexOf(task),
                                                b = templates.indexOf(
                                                  visible[target],
                                                );
                                            templates[a] = visible[target];
                                            templates[b] = task;
                                          });
                                        }
                                      } else {
                                        change(() => task['folderId'] = value);
                                      }
                                    },
                                    itemBuilder: (_) => [
                                      const PopupMenuItem(
                                        value: 'edit',
                                        child: Text('업무·행위·매뉴얼 수정'),
                                      ),
                                      const PopupMenuItem(
                                        value: 'up',
                                        child: Text('위로 이동'),
                                      ),
                                      const PopupMenuItem(
                                        value: 'down',
                                        child: Text('아래로 이동'),
                                      ),
                                      for (final f in folders.where(
                                        (f) => f['id'] != task['folderId'],
                                      ))
                                        PopupMenuItem<String>(
                                          value: f['id'],
                                          child: Text('${f['name']} 폴더로 이동'),
                                        ),
                                      const PopupMenuItem(
                                        value: 'delete',
                                        child: Text('업무 삭제'),
                                      ),
                                    ],
                                  ),
                                  if (enabled)
                                    ReorderableDragStartListener(
                                      index: index,
                                      child: const Padding(
                                        padding: EdgeInsets.all(12),
                                        child: Icon(
                                          Icons.drag_handle,
                                          semanticLabel: '업무 순서 드래그',
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              Text(
                                '${task['slot']} · ${_roles[task['requiredRole']]} · ${_rows(task['steps']).length}개 행위',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.muted,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _rows(
                                  task['steps'],
                                ).map((s) => s['title']).join(' → '),
                                style: const TextStyle(
                                  fontSize: 13,
                                  height: 1.5,
                                ),
                              ),
                              TextButton(
                                onPressed: enabled
                                    ? () => editTask(task)
                                    : null,
                                child: const Text('매뉴얼 열기 · 수정'),
                              ),
                            ],
                          ),
                        ),
                      );
                      return LongPressDraggable<String>(
                        key: ValueKey(task['id']),
                        data: task['id'],
                        maxSimultaneousDrags: enabled ? 1 : 0,
                        feedback: Material(
                          elevation: 8,
                          borderRadius: BorderRadius.circular(12),
                          child: SizedBox(
                            width: 240,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Text(task['title']),
                            ),
                          ),
                        ),
                        childWhenDragging: Opacity(opacity: .35, child: card),
                        child: card,
                      );
                    },
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

  Future<void> editFolder([Json? folder]) async {
    if (folder == null && folders.length >= checklistFolderLimit) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('폴더는 최대 30개예요. 사용하지 않는 폴더를 먼저 정리해 주세요.')),
      );
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

  Future<void> editTask([Json? task]) async {
    if (task == null && templates.length >= checklistTaskLimit) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('업무는 최대 150개예요. 필요 없는 업무를 먼저 정리해 주세요.')),
      );
      return;
    }
    final draft = task == null
        ? <String, dynamic>{
            'id': newId(),
            'title': '',
            'folderId': selected,
            'slot': '오픈',
            'requiredRole': 'all',
            'zone': widget.ops.rows('zones').firstOrNull?['id'] ?? 'entrance',
            'steps': <Json>[
              {'id': newId(), 'title': '', 'manual': '', 'tip': ''},
            ],
            'sourceIds': <String>[],
          }
        : _copy(task);
    final result = await Navigator.of(context).push<Json>(
      MaterialPageRoute(
        builder: (_) =>
            _TaskEditor(task: draft, zones: widget.ops.rows('zones')),
      ),
    );
    if (result != null && mounted) {
      change(() {
        if (task == null) {
          templates.add(result);
        } else {
          templates[templates.indexOf(task)] = result;
        }
      });
    }
  }

  Future<void> library() async {
    final catalog = widget.ops.data?['checklistLibrary'] as Json? ?? {};
    final industries = _rows(catalog['industries']);
    final selections = <String, Set<String>>{
      for (final industry in industries)
        industry['id']: missingIndustryTasks(
          industry,
          templates,
        ).map((t) => t['id'] as String).toSet(),
    };
    String query = '';
    String? importError;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, update) => SizedBox(
          height: MediaQuery.sizeOf(sheetContext).height * .88,
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
            ),
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    '업종별 노하우 기본 목록',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text('필요한 업무만 골라 가져오세요. 이미 수정한 업무는 그대로 유지해요.'),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      labelText: '업종·업무 검색',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (v) => update(() => query = v.trim()),
                  ),
                ),
                if (importError != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Information(importError!),
                  ),
                Expanded(
                  child: ListView(
                    children: [
                      for (final industry in industries.where(
                        (i) =>
                            '${i['name']} ${_rows(i['tasks']).map((t) => t['title']).join(' ')}'
                                .contains(query),
                      ))
                        ExpansionTile(
                          key: ValueKey('industry-${industry['id']}'),
                          title: Text(industry['name']),
                          subtitle: Text(
                            '${_rows(industry['tasks']).length}개 업무 · ${industry['basis'] ?? '출처를 참고한 운영 제안'}',
                          ),
                          children: [
                            for (final task in _rows(industry['tasks']))
                              ExpansionTile(
                                key: ValueKey(libraryTaskId(industry, task)),
                                leading: Checkbox(
                                  semanticLabel: '${task['title']} 가져오기',
                                  value: selections[industry['id']]!.contains(
                                    task['id'],
                                  ),
                                  onChanged:
                                      templates.any(
                                        (t) =>
                                            t['id'] ==
                                            libraryTaskId(industry, task),
                                      )
                                      ? null
                                      : (value) => update(() {
                                          if (value == true) {
                                            selections[industry['id']]!.add(
                                              task['id'],
                                            );
                                          } else {
                                            selections[industry['id']]!.remove(
                                              task['id'],
                                            );
                                          }
                                          importError = null;
                                        }),
                                ),
                                title: Text(task['title']),
                                subtitle: Text(
                                  templates.any(
                                        (t) =>
                                            t['id'] ==
                                            libraryTaskId(industry, task),
                                      )
                                      ? '이미 목록에 있어요 · 수정 내용 유지'
                                      : '${_rows(task['steps']).length}개 행위 · 눌러서 매뉴얼 보기',
                                ),
                                childrenPadding: const EdgeInsets.all(16),
                                children: [
                                  for (final step in _rows(task['steps']))
                                    ListTile(
                                      contentPadding: EdgeInsets.zero,
                                      title: Text(step['title']),
                                      subtitle: Text(
                                        '${step['manual']}\n💡 ${step['tip']}',
                                      ),
                                    ),
                                ],
                              ),
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  for (final source
                                      in _rows(catalog['sources']).where(
                                        (s) => _rows(industry['tasks']).any(
                                          (t) => (t['sourceIds'] as List? ?? [])
                                              .contains(s['id']),
                                        ),
                                      ))
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: SelectableText(
                                        '참고: ${source['title']}\n${source['url']}',
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ),
                                  FilledButton.icon(
                                    onPressed:
                                        selections[industry['id']]!.isEmpty
                                        ? null
                                        : () {
                                            try {
                                              final plan = planChecklistImport(
                                                industry: industry,
                                                selectedTaskIds:
                                                    selections[industry['id']]!,
                                                templates: templates,
                                                folders: folders,
                                                newFolderId: newId(),
                                                zoneId:
                                                    widget.ops
                                                        .rows('zones')
                                                        .firstOrNull?['id'] ??
                                                    'entrance',
                                              );
                                              change(() {
                                                if (plan.folder != null) {
                                                  folders.add(plan.folder!);
                                                }
                                                selected = plan.folderId;
                                                templates.addAll(plan.tasks);
                                              });
                                              Navigator.pop(sheetContext);
                                            } on FormatException catch (error) {
                                              update(
                                                () =>
                                                    importError = error.message,
                                              );
                                            }
                                          },
                                    icon: const Icon(Icons.add),
                                    label: Text(
                                      '선택한 ${selections[industry['id']]!.length}개 업무 가져오기',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TaskEditor extends StatefulWidget {
  const _TaskEditor({required this.task, required this.zones});
  final Json task;
  final List<Json> zones;
  @override
  State<_TaskEditor> createState() => _TaskEditorState();
}

class _TaskEditorState extends State<_TaskEditor> {
  final form = GlobalKey<FormState>();
  late final Json task = widget.task;
  late final String original;
  @override
  void initState() {
    super.initState();
    original = jsonEncode(widget.task);
  }

  bool applying = false;
  String? issue;
  bool get dirty => jsonEncode(task) != original;
  void changed() => setState(() => issue = null);
  List<Json> get steps => _rows(task['steps']);
  String? requiredText(String? value) =>
      value == null || value.trim().isEmpty ? '내용을 입력해 주세요.' : null;
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
        title: const Text('업무와 간단 매뉴얼'),
        actions: [
          TextButton(
            onPressed: () {
              final problem = checklistTaskIssue(task);
              form.currentState!.validate();
              if (problem != null) {
                setState(() => issue = problem);
                return;
              }
              setState(() => applying = true);
              Navigator.pop(context, task);
            },
            child: const Text('초안에 적용'),
          ),
        ],
      ),
      body: Column(
        children: [
          if (issue != null)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Information(issue!),
            ),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: Form(
                  key: form,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      TextFormField(
                        initialValue: task['title'],
                        maxLength: 100,
                        decoration: const InputDecoration(labelText: '업무 이름'),
                        validator: requiredText,
                        onChanged: (v) {
                          task['title'] = v.trim();
                          changed();
                        },
                      ),
                      DropdownButtonFormField<String>(
                        initialValue: task['slot'],
                        decoration: const InputDecoration(labelText: '시간대'),
                        items: [
                          for (final s in _slots)
                            DropdownMenuItem(value: s, child: Text(s)),
                        ],
                        onChanged: (v) {
                          task['slot'] = v;
                          changed();
                        },
                      ),
                      DropdownButtonFormField<String>(
                        initialValue: task['requiredRole'],
                        decoration: const InputDecoration(labelText: '담당 직급'),
                        items: [
                          for (final r in _roles.entries)
                            DropdownMenuItem(
                              value: r.key,
                              child: Text(r.value),
                            ),
                        ],
                        onChanged: (v) {
                          task['requiredRole'] = v;
                          changed();
                        },
                      ),
                      DropdownButtonFormField<String>(
                        initialValue: task['zone'],
                        isExpanded: true,
                        decoration: const InputDecoration(labelText: '장소'),
                        items: [
                          for (final z in widget.zones)
                            DropdownMenuItem<String>(
                              value: z['id'],
                              child: Text(z['name']),
                            ),
                        ],
                        onChanged: (v) {
                          task['zone'] = v;
                          changed();
                        },
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        '행위마다 방법 + 완료 기준을 짧게 적어요.',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      for (final (index, step) in steps.indexed)
                        Card(
                          key: ValueKey(step['id']),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(child: Text('행위 ${index + 1}')),
                                    IconButton(
                                      tooltip: '행위 위로',
                                      onPressed: index == 0
                                          ? null
                                          : () => setState(() {
                                              final list = steps;
                                              list.removeAt(index);
                                              list.insert(index - 1, step);
                                              task['steps'] = list;
                                            }),
                                      icon: const Icon(Icons.arrow_upward),
                                    ),
                                    IconButton(
                                      tooltip: '행위 아래로',
                                      onPressed: index == steps.length - 1
                                          ? null
                                          : () => setState(() {
                                              final list = steps;
                                              list.removeAt(index);
                                              list.insert(index + 1, step);
                                              task['steps'] = list;
                                            }),
                                      icon: const Icon(Icons.arrow_downward),
                                    ),
                                    IconButton(
                                      tooltip: '행위 삭제',
                                      onPressed: steps.length == 1
                                          ? null
                                          : () => setState(
                                              () => (task['steps'] as List)
                                                  .remove(step),
                                            ),
                                      icon: const Icon(Icons.delete_outline),
                                    ),
                                  ],
                                ),
                                TextFormField(
                                  initialValue: step['title'],
                                  maxLength: 100,
                                  decoration: const InputDecoration(
                                    labelText: '행위 이름',
                                  ),
                                  validator: requiredText,
                                  onChanged: (v) {
                                    step['title'] = v.trim();
                                    changed();
                                  },
                                ),
                                TextFormField(
                                  initialValue: step['manual'],
                                  minLines: 2,
                                  maxLines: 6,
                                  maxLength: 700,
                                  decoration: const InputDecoration(
                                    labelText: '간단 매뉴얼 · 방법과 완료 기준',
                                  ),
                                  validator: requiredText,
                                  onChanged: (v) {
                                    step['manual'] = v.trim();
                                    changed();
                                  },
                                ),
                                TextFormField(
                                  initialValue: step['tip'],
                                  minLines: 1,
                                  maxLines: 4,
                                  maxLength: 400,
                                  decoration: const InputDecoration(
                                    labelText: '놓치기 쉬운 노하우 (선택)',
                                  ),
                                  onChanged: (v) {
                                    step['tip'] = v.trim();
                                    changed();
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      OutlinedButton.icon(
                        onPressed: steps.length >= checklistStepLimit
                            ? null
                            : () => setState(
                                () => (task['steps'] as List).add({
                                  'id':
                                      'step-${DateTime.now().microsecondsSinceEpoch}',
                                  'title': '',
                                  'manual': '',
                                  'tip': '',
                                }),
                              ),
                        icon: const Icon(Icons.add),
                        label: const Text('행위 추가'),
                      ),
                      const SizedBox(height: 24),
                      const Information(
                        '초안에 적용한 뒤 목록 화면에서 저장해 주세요. 실제 장비 설정과 매장 기준에 맞게 내용을 확인해요.',
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
