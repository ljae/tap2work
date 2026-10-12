import '../l10n/entity_name_scope.dart';
import '../l10n/app_localizations.dart';
import 'workplace_screens.dart';
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../domain/checklist_draft.dart';
import '../domain/optimized_photo.dart';
import '../domain/manual_media_repository.dart';
import '../state/operations_controller.dart';
import 'checklist_library.dart';
import 'components.dart';
import 'photo_registration.dart';
import 'place_guide.dart';

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
      notice(context.t('ui.audit536', args: {'p0': problem}));
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
              title: Text(context.t('ui.audit19')),
              content: Text(context.t('ui.audit20')),
              actions: [
                PressBounce(
                  child: TextButton(
                    onPressed: () => Navigator.pop(c, false),
                    child: Text(context.t('ui.audit21')),
                  ),
                ),
                PressBounce(
                  child: FilledButton(
                    onPressed: () => Navigator.pop(c, true),
                    child: Text(context.t('ui.audit22')),
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
          title: context.t('ui.audit534'),
          footer: AppSheetFooter(
            children: [
              FilledButton(
                onPressed: !enabled || ops.readOnly || !dirty ? null : save,
                child: Text(
                  ops.busy ? context.t('ui.audit532') : context.t('ui.audit51'),
                ),
              ),
            ],
          ),
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 920),
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  if (ops.readOnly) Information(context.t('ui.audit23')),
                  Information(context.t('ui.audit24')),
                  if (ops.error != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Information(
                        context.t('ui.audit535', args: {'p0': ops.error}),
                      ),
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
                        label: Text(context.t('ui.audit25')),
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
                          label: Text(context.t('ui.audit26')),
                        ),
                      ),
                      PressBounce(
                        child: OutlinedButton.icon(
                          onPressed: enabled ? () => editGroup() : null,
                          icon: const Icon(Icons.add),
                          label: Text(context.t('ui.audit27')),
                        ),
                      ),
                      PressBounce(
                        child: TextButton.icon(
                          onPressed: enabled ? () => editFolder() : null,
                          icon: const Icon(Icons.create_new_folder_outlined),
                          label: Text(context.t('ui.audit28')),
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
                              '${entityDisplayName(context, ops, 'folder', f['id'], f['name'])} · ${templates.where((t) => t['folderId'] == f['id']).length}',
                            ),
                            selected: selected == f['id'],
                            onPressed: () => setState(() => selected = f['id']),
                            onDeleted: enabled ? () => editFolder(f) : null,
                            deleteIcon: const Icon(
                              Icons.edit_outlined,
                              size: 18,
                            ),
                            deleteButtonTooltipMessage: context.t(
                              'ui.audit1100',
                            ),
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
                          child: Text(context.t('ui.audit29')),
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  if (issue != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Information(
                        context.t('ui.audit536', args: {'p0': issue}),
                      ),
                    ),
                  if (visible.isEmpty) Information(context.t('ui.audit30')),
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
                    Padding(
                      padding: EdgeInsets.all(12),
                      child: Text(context.t('ui.audit537')),
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
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Icon(
                    Icons.drag_indicator,
                    size: 28,
                    semanticLabel: context.t('ui.audit538'),
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
                        context.t(
                          'ui.audit539',
                          args: {
                            'p0': task['slot'],
                            'p1': partLabel(
                              ops,
                              task['partId'],
                              context: context,
                            ),
                            'p2': place == null ? '' : ' · $place',
                            'p3': steps.length,
                          },
                        ),
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
              tooltip: open
                  ? context.t('ui.audit540')
                  : context.t('ui.audit541'),
              onPressed: () => setState(
                () => open ? collapsed.add(id) : collapsed.remove(id),
              ),
              icon: Icon(open ? Icons.expand_less : Icons.expand_more),
            ),
            PopupMenuButton<String>(
              popUpAnimationStyle: AppMotion.dialogStyle(context),
              enabled: enabled,
              tooltip: context.t('ui.audit542'),
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
                PopupMenuItem(
                  value: 'edit',
                  child: Text(context.t('ui.audit543')),
                ),
                PopupMenuItem(
                  value: 'up',
                  child: Text(context.t('ui.audit544')),
                ),
                PopupMenuItem(
                  value: 'down',
                  child: Text(context.t('ui.audit545')),
                ),
                for (final f in folders.where(
                  (f) => f['id'] != task['folderId'],
                ))
                  PopupMenuItem<String>(
                    value: f['id'],
                    child: Text(
                      context.t(
                        'ui.audit546',
                        args: {
                          'p0': entityDisplayName(
                            context,
                            ops,
                            'folder',
                            f['id'],
                            f['name'],
                          ),
                        },
                      ),
                    ),
                  ),
                PopupMenuItem(
                  value: 'delete',
                  child: Text(context.t('ui.audit547')),
                ),
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
                    label: Text(context.t('ui.audit31')),
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
              child: Padding(
                padding: EdgeInsets.all(10),
                child: Icon(
                  Icons.drag_handle,
                  size: 22,
                  color: AppColors.muted,
                  semanticLabel: context.t('ui.audit548'),
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
                          : context.t('ui.audit549'),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      (step['manual'] as String?)?.isNotEmpty == true
                          ? step['manual']
                          : context.t('ui.audit550'),
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
            tooltip: context.t('ui.audit551'),
            onPressed: enabled
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
      notice(context.t('ui.audit1101'));
      return;
    }
    var folderName = folder?['name'] as String? ?? '';
    final name = await showAppFormSheet<String>(
      context: context,
      builder: (c) => AppSheetPanel(
        title: Text(
          folder == null ? context.t('ui.audit552') : context.t('ui.audit32'),
        ),
        content: TextFormField(
          initialValue: folderName,
          onChanged: (value) => folderName = value,
          maxLength: 40,
          autofocus: true,
          decoration: InputDecoration(labelText: context.t('ui.audit32')),
        ),
        actions: [
          PressBounce(
            child: TextButton(
              onPressed: () => Navigator.pop(c),
              child: Text(context.t('ui.audit33')),
            ),
          ),
          PressBounce(
            child: FilledButton(
              onPressed: () {
                if (folderName.trim().isNotEmpty) {
                  Navigator.pop(c, folderName.trim());
                }
              },
              child: Text(context.t('ui.audit34')),
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
      notice(context.t('ui.audit1102'));
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
        ops: ops,
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
    this.ops,
    required this.task,
    required this.zones,
    required this.parts,
  });
  final OperationsController? ops;
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
          Text(
            context.t('ui.audit35'),
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            context.t('ui.audit36'),
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
                  decoration: InputDecoration(
                    labelText: context.t('ui.audit37'),
                  ),
                  onChanged: (v) => setState(() {
                    task['title'] = v.trim();
                    issue = null;
                  }),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            context.t('ui.audit38'),
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          AppChoiceGroup<String>(
            values: checklistSlots,
            selected: task['slot'] as String,
            labelOf: (slot) => slot,
            onSelected: (slot) => setState(() => task['slot'] = slot),
          ),
          const SizedBox(height: 14),
          Text(
            context.t('ui.audit39'),
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
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
                ? context.t('ui.audit370')
                : entityDisplayName(
                    context,
                    widget.ops,
                    'part',
                    id,
                    widget.parts.firstWhere((p) => p['id'] == id)['name'],
                  ),
            onSelected: (id) => setState(() {
              task['partId'] = id == 'all' ? null : id;
              task['requiredRole'] = 'all';
            }),
          ),
          const SizedBox(height: 14),
          AppPicker<String>(
            label: context.t('ui.audit381'),
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
                    setState(() => issue = context.t('ui.audit1236'));
                    return;
                  }
                  Navigator.pop(context, task);
                },
                child: Text(context.t('ui.audit40')),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

/// Opens one reusable Task manual from the manual directory, never the board.
Future<Json?> editManualTaskContent(
  BuildContext context,
  Json step,
  String groupTitle, {
  OperationsController? ops,
}) => showAppSheet<Json>(
  context,
  builder: (_) =>
      _ActivityEditor(step: _copy(step), groupTitle: groupTitle, ops: ops),
);

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
  late final String? openingWorkspace;

  @override
  void initState() {
    super.initState();
    openingRevision = widget.ops.data?['revision'] ?? -1;
    openingActor = widget.ops.actorId;
    openingWorkspace = widget.ops.data?['workspaceId'];
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
    if (!ops.canEditTasks ||
        ops.actorId != openingActor ||
        ops.data?['workspaceId'] != openingWorkspace ||
        ops.busy) {
      return '편집 권한 또는 매장이 변경됐어요. 다시 열어 주세요.';
    }
    if (ops.data?['revision'] != openingRevision) {
      return '다른 변경이 저장됐어요. 최신 매뉴얼을 다시 열어 주세요.';
    }
    if (sourceTemplate?['menuManualId'] != null ||
        sourceStep?['manualTitle'] != null) {
      draft = {
        ...draft,
        'manualTitle': draft['title'],
        'title': sourceStep!['title'],
      };
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
    final ok = await ops.act('save_manual_tap', {
      'revision': openingRevision,
      'templateId': target['id'],
      'title': target['title'],
      'emoji': target['emoji'],
      'folderId': target['folderId'],
      'steps': target['steps'],
    });
    return ok ? null : (ops.error ?? '저장하지 못했어요. 다시 시도해 주세요.');
  }

  @override
  Widget build(BuildContext context) {
    if (sourceTemplate == null || sourceStep == null) {
      return Scaffold(
        appBar: AppBar(title: Text(context.t('ui.audit41'))),
        body: Center(child: Information(context.t('ui.audit553'))),
      );
    }
    return _ActivityEditor(
      ops: widget.ops,
      step: {
        ..._copy(sourceStep!),
        'title': sourceStep!['manualTitle'] ?? sourceStep!['title'],
      },
      groupTitle:
          '${sourceTemplate!['manualTitle'] ?? sourceTemplate!['title'] ?? ''}',
      onSave: save,
      previewOnly: widget.ops.readOnly,
      catalogLinked:
          widget.ops.data?['catalogLinks']?[widget.templateId]?['mode'] ==
          'linked',
    );
  }
}

class _ActivityEditor extends StatefulWidget {
  const _ActivityEditor({
    required this.step,
    required this.groupTitle,
    this.onSave,
    this.previewOnly = false,
    this.catalogLinked = false,
    this.ops,
  });
  final Json step;
  final String groupTitle;
  final Future<String?> Function(Json draft)? onSave;
  final bool previewOnly;
  final bool catalogLinked;
  final OperationsController? ops;
  @override
  State<_ActivityEditor> createState() => _ActivityEditorState();
}

class _ActivityEditorState extends State<_ActivityEditor> {
  late final Json step = widget.step;
  late final String original = jsonEncode(widget.step);
  bool applying = false, saving = false;
  bool convertingPhoto = false;
  OptimizedPhoto? pendingPhoto;
  late final String? openingPhotoActor;
  late final Object? openingPhotoWorkspace,
      openingPhotoRevision,
      openingPhotoStep;
  @override
  void initState() {
    super.initState();
    openingPhotoActor = widget.ops?.actorId;
    openingPhotoWorkspace = widget.ops?.data?['workspaceId'];
    openingPhotoRevision = widget.ops?.data?['revision'];
    openingPhotoStep = widget.step['id'];
  }

  bool get photoScopeCurrent =>
      widget.ops != null &&
      widget.ops!.actorId == openingPhotoActor &&
      widget.ops!.data?['workspaceId'] == openingPhotoWorkspace &&
      widget.ops!.canEditTasks;
  String? issue;
  bool get dirty => pendingPhoto != null || jsonEncode(step) != original;

  Future<void> submit() async {
    if (saving || convertingPhoto) return;
    final problem = checklistStepIssue(step);
    if (problem != null) {
      setState(() => issue = problem);
      return;
    }
    if (pendingPhoto != null || widget.onSave != null) {
      setState(() {
        saving = true;
        issue = null;
      });
      String? failure;
      try {
        if (pendingPhoto != null) {
          if (!photoScopeCurrent ||
              widget.ops!.data?['revision'] != openingPhotoRevision) {
            throw const ManualMediaException(
              '매장 또는 매뉴얼이 변경됐어요. 최신 내용을 다시 열어 주세요.',
            );
          }
          final reference = await widget.ops!.uploadManualPhoto(
            pendingPhoto!.bytes,
          );
          if (!mounted) return;
          if (!photoScopeCurrent) {
            throw const ManualMediaException('매장이 변경됐어요. 다시 열어 주세요.');
          }
          step['imageUrl'] = reference;
          pendingPhoto = null;
        }
        failure = await widget.onSave?.call(step);
      } catch (error) {
        failure = '$error';
      }
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
    canPop: applying || (!saving && !convertingPhoto && !dirty),
    onPopInvokedWithResult: (didPop, result) async {
      if (didPop || saving || convertingPhoto) return;
      final discard = await showAppDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: Text(context.t('ui.audit42')),
          content: Text(context.t('ui.audit43')),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: Text(context.t('ui.audit21')),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(c, true),
              child: Text(context.t('ui.audit22')),
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
      title: widget.onSave == null
          ? context.t('ui.audit554')
          : context.t('ui.audit41'),
      subtitle: widget.groupTitle.isEmpty ? null : 'TAP · ${widget.groupTitle}',
      body: AbsorbPointer(
        absorbing: saving,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: appEditorWidth),
            child: ListView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              children: [
                if (widget.catalogLinked)
                  Padding(
                    padding: EdgeInsets.only(bottom: 20),
                    child: Information(context.t('ui.audit555')),
                  ),
                if (widget.previewOnly)
                  Padding(
                    padding: EdgeInsets.only(bottom: 20),
                    child: Information(context.t('ui.audit556')),
                  ),
                AppFormSection(
                  title: context.t('ui.audit557'),
                  description: context.t('ui.audit558'),
                  children: [
                    field(
                      'title',
                      context.t('ui.audit1104'),
                      hint: context.t('ui.audit1103'),
                      limit: 100,
                    ),
                    field(
                      'manual',
                      context.t('ui.audit1106'),
                      hint: context.t('ui.audit1105'),
                      lines: 4,
                      limit: 700,
                    ),
                  ],
                ),
                AppFormSection(
                  title: context.t('ui.audit559'),
                  description: context.t('ui.audit560'),
                  children: [
                    field(
                      'tip',
                      context.t('ui.audit1107'),
                      lines: 2,
                      limit: 400,
                    ),
                    TextFormField(
                      initialValue: ((step['tags'] as List?) ?? []).join(', '),
                      decoration: InputDecoration(
                        labelText: context.t('ui.audit44'),
                        hintText: context.t('ui.audit45'),
                        helperText: context.t('ui.audit46'),
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
                  title: context.t('ui.audit561'),
                  description: context.t('ui.audit562'),
                  children: [
                    if (widget.ops != null)
                      PhotoRegistrationField(
                        value: step['imageUrl'] ?? '',
                        pending: pendingPhoto,
                        scopeKey: (
                          openingPhotoActor,
                          openingPhotoWorkspace,
                          openingPhotoStep,
                        ),
                        isScopeCurrent: () => photoScopeCurrent,
                        enabled:
                            !saving &&
                            widget.ops!.cloud &&
                            !widget.ops!.readOnly,
                        previewBuilder: (value) =>
                            placePhoto(value, ops: widget.ops),
                        onBusyChanged: (value) {
                          if (mounted) setState(() => convertingPhoto = value);
                        },
                        onChanged: (photo) => setState(() {
                          pendingPhoto = photo;
                          issue = null;
                        }),
                        onRemove: () => setState(() {
                          pendingPhoto = null;
                          step['imageUrl'] = '';
                        }),
                      ),
                    if (widget.ops != null && !widget.ops!.cloud)
                      Text(context.t('ui.audit47'), style: AppText.caption),
                    if (pendingPhoto == null &&
                        !isManualMediaReference(step['imageUrl'] ?? ''))
                      field('imageUrl', context.t('ui.audit1108')),
                    field('videoUrl', context.t('ui.audit1109')),
                    field('sourceUrl', context.t('ui.audit1110')),
                  ],
                ),
                Text(
                  widget.onSave == null
                      ? context.t('ui.audit563')
                      : context.t('ui.audit564'),
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
            onPressed: saving || convertingPhoto ? null : submit,
            child: Text(
              saving
                  ? context.t('ui.audit532')
                  : widget.onSave == null
                  ? context.t('ui.audit565')
                  : context.t('ui.audit566'),
            ),
          ),
        ],
      ),
    ),
  );
}
