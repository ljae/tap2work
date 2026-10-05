import 'manual_tap_editor.dart';
import 'catalog_editor.dart';
import 'manual_market_screen.dart';
import 'checklist_backup_screen.dart';
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../state/operations_controller.dart';
import 'components.dart';
import 'direct_edit.dart';
import 'tap_settings_screen.dart';
import 'checklist_editor.dart';

/// A manual belongs to one Task. The tree changes reusable definitions only.
class ManualWorkspace extends StatefulWidget {
  const ManualWorkspace({super.key, required this.ops, required this.query});
  final OperationsController ops;
  final String query;
  @override
  State<ManualWorkspace> createState() => _ManualWorkspaceState();
}

enum _ManualEditPane { directory, content }

class _ManualWorkspaceState extends State<ManualWorkspace> {
  List<Json> rows = [], folders = [], taps = [];
  int revision = -1;
  String actor = '';
  String? scopeGroup, scopeTap, selectedId;
  _ManualEditPane? editPane;
  bool showTree = true, previewDirty = false, recipes = false;
  bool get editing => editPane != null;
  bool get editingTree => editPane == _ManualEditPane.directory;
  bool get editingContent => editPane == _ManualEditPane.content;
  final expanded = <String>{};
  OperationsController get ops => widget.ops;
  bool get canEdit => ops.canEditTasks && !ops.busy;
  Json copy(Json row) => jsonDecode(jsonEncode(row)) as Json;

  void sync({bool force = false}) {
    final changedActor = actor != ops.actorId;
    if (!force &&
        !changedActor &&
        (previewDirty || revision == ops.data?['revision'])) {
      return;
    }
    final recipeIds = ops
        .rows('taskTemplates')
        .where((t) => t['menuManualId'] != null)
        .map((t) => t['id'])
        .toSet();
    rows = ops
        .rows('manualSearch')
        .where(
          (r) =>
              r['menuManualId'] == null && !recipeIds.contains(r['templateId']),
        )
        .map(copy)
        .toList();
    folders = ops.rows('checklistFolders').map(copy).toList();
    for (final row in rows) {
      row['folderId'] ??= 'general';
      row['tapId'] ??= row['templateId'] ?? row['taskId'] ?? row['tapTitle'];
      row['id'] ??= '${row['tapId']}/${row['title']}';
      row['sourceStepId'] ??= row['stepId'] ?? row['id'];
      if (!folders.any((f) => f['id'] == row['folderId'])) {
        folders.add({
          'id': row['folderId'],
          'name': row['folderName'] ?? '기본 업무',
        });
      }
    }
    for (final row in rows) {
      row['folderName'] = folders.firstWhere(
        (f) => f['id'] == row['folderId'],
      )['name'];
    }
    taps = [
      for (final t
          in ops
              .rows('taskTemplates')
              .where(
                (t) => t['menuManualId'] == null && t['archivedAt'] == null,
              ))
        {
          'tapId': t['id'],
          'templateId': t['id'],
          'tapTitle': t['manualTitle'] ?? t['title'],
          'folderId': t['folderId'] ?? 'general',
          'editable': true,
        },
    ];
    for (final row in rows) {
      if (!taps.any((t) => t['tapId'] == row['tapId'])) taps.add(copy(row));
    }
    for (final tap in taps) {
      tap['folderName'] =
          folders
              .where((f) => f['id'] == tap['folderId'])
              .firstOrNull?['name'] ??
          '기본 업무';
    }
    final order = List<String>.from(ops.data?['bigTapOrder'] ?? []);
    if (order.isNotEmpty) {
      folders.sort((a, b) {
        final ai = order.indexOf(a['id']), bi = order.indexOf(b['id']);
        return (ai < 0 ? order.length : ai).compareTo(
          bi < 0 ? order.length : bi,
        );
      });
    }
    revision = ops.data?['revision'] ?? 0;
    actor = ops.actorId;
    previewDirty = false;
    if (changedActor) {
      editPane = null;
      scopeGroup = null;
      scopeTap = null;
      selectedId = null;
      expanded.clear();
      if (ops.data?['manualBusinessProfile'] == null) {
        expanded.addAll(folders.map((f) => 'group:${f['id']}'));
      }
      recipes = false;
    }
  }

  String normalize(String text) =>
      text.toLowerCase().replaceAll('메뉴얼', '매뉴얼').replaceAll('결재', '결제');
  bool matches(Json row) {
    final words = normalize(
      widget.query,
    ).trim().split(RegExp(r'\s+')).where((s) => s.isNotEmpty);
    final folder = folders.where((f) => f['id'] == row['folderId']).firstOrNull;
    final text = normalize(
      '${folder?['name']} ${row['tapTitle']} ${row['title']} ${row['manual']} ${row['tip']} ${(row['tags'] as List? ?? []).join(' ')}',
    );
    return words.every(text.contains);
  }

  int? minutes(Json row) {
    final value = row['estimatedMinutes'];
    return value is int && value > 0 ? value : null;
  }

  String duration(List<Json> tasks) {
    final tapMinutes = tasks.isEmpty
        ? null
        : tasks.first['tapEstimatedMinutes'];
    if (tapMinutes is int && tapMinutes > 0) return 'TAP 약 $tapMinutes분';
    final known = tasks.map(minutes).whereType<int>().toList();
    if (known.isEmpty) return '시간 미설정';
    final total = known.fold<int>(0, (sum, value) => sum + value);
    return known.length == tasks.length ? '약 $total분' : '약 $total분+';
  }

  List<Json> get results => rows
      .where(
        (row) =>
            (scopeGroup == null || row['folderId'] == scopeGroup) &&
            (scopeTap == null || row['tapId'] == scopeTap) &&
            matches(row),
      )
      .toList();
  void notice(String value) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(value)));

  Json drag(String kind, String id, {String? tapId}) => {
    'kind': kind,
    'id': id,
    'sourceTapId': ?tapId,
    'revision': revision,
    'actor': actor,
  };
  Json? destination(
    Json from,
    String kind,
    String id, {
    String? tapId,
    String? folderId,
  }) {
    if (from['kind'] == 'group' && kind == 'group' && from['id'] != id) {
      return {...from, 'beforeId': id};
    }
    if (from['kind'] == 'tap' && kind == 'group') {
      return {...from, 'targetId': id};
    }
    if (from['kind'] == 'tap' && kind == 'tap' && from['id'] != id) {
      return {...from, 'targetId': folderId, 'beforeId': id};
    }
    if (from['kind'] == 'task' && kind == 'group') {
      return {...from, 'targetFolderId': id};
    }
    if (from['kind'] == 'task' && kind == 'tap') {
      return {...from, 'targetId': id};
    }
    if (from['kind'] == 'task' &&
        kind == 'task' &&
        !(from['id'] == id && from['sourceTapId'] == tapId)) {
      return {...from, 'targetId': tapId, 'beforeId': id};
    }
    return null;
  }

  Future<void> move(Json command) async {
    if (!canEdit || command['actor'] != ops.actorId) return;
    if (command['targetFolderId'] != null) {
      await chooseDestination(command, folderId: command['targetFolderId']);
      return;
    }
    if (!ops.readOnly) {
      final ok = await ops.act(
        'move_manual_node',
        {...command}..remove('actor'),
      );
      if (!mounted) return;
      if (!ok) {
        notice(ops.error ?? '이동하지 못했어요.');
        return;
      }
      setState(() {
        sync(force: true);
        selectedId = null;
        scopeTap = null;
        scopeGroup = null;
      });
      return;
    }
    // Public preview changes remain inside this view, never sent to a write API.
    final nextRows = rows.map(copy).toList();
    final nextFolders = folders.map(copy).toList();
    final nextTaps = taps.map(copy).toList();
    final kind = command['kind'];
    if (kind == 'group') {
      final moving = nextFolders.firstWhere((f) => f['id'] == command['id']);
      nextFolders.remove(moving);
      final at = command['beforeId'] == null
          ? nextFolders.length
          : nextFolders.indexWhere((f) => f['id'] == command['beforeId']);
      if (at < 0) return;
      nextFolders.insert(at, moving);
    } else if (kind == 'tap') {
      final moving = nextRows
          .where((r) => r['tapId'] == command['id'])
          .toList();
      final target = nextFolders
          .where((f) => f['id'] == command['targetId'])
          .firstOrNull;
      final tap = nextTaps
          .where((t) => t['tapId'] == command['id'])
          .firstOrNull;
      if (tap == null || target == null) return;
      nextTaps.remove(tap);
      tap['folderId'] = target['id'];
      tap['folderName'] = target['name'];
      final tapAt = command['beforeId'] == null
          ? nextTaps.length
          : nextTaps.indexWhere((t) => t['tapId'] == command['beforeId']);
      if (tapAt < 0) return;
      nextTaps.insert(tapAt, tap);
      nextRows.removeWhere((r) => r['tapId'] == command['id']);
      for (final r in moving) {
        r['folderId'] = target['id'];
        r['folderName'] = target['name'];
      }
      final at = command['beforeId'] == null
          ? nextRows.length
          : nextRows.indexWhere((r) => r['tapId'] == command['beforeId']);
      nextRows.insertAll(at < 0 ? nextRows.length : at, moving);
    } else {
      final source = nextRows
          .where((r) => r['tapId'] == command['sourceTapId'])
          .toList();
      final target = nextRows
          .where((r) => r['tapId'] == command['targetId'])
          .toList();
      final moving = source
          .where((r) => r['sourceStepId'] == command['id'])
          .firstOrNull;
      final parent = nextTaps
          .where((t) => t['tapId'] == command['targetId'])
          .firstOrNull;
      if (moving == null || parent == null) return;
      final different = command['sourceTapId'] != command['targetId'];
      if (different && target.length >= 30) {
        notice('한 TAP의 Task는 최대 30개예요.');
        return;
      }
      if (different && target.any((r) => r['sourceStepId'] == command['id'])) {
        moving['sourceStepId'] =
            'manual-${DateTime.now().microsecondsSinceEpoch}';
        moving['stepId'] = moving['sourceStepId'];
      }
      nextRows.remove(moving);
      moving.addAll({
        'tapId': parent['tapId'],
        'templateId': parent['templateId'],
        'tapTitle': parent['tapTitle'],
        'folderId': parent['folderId'],
        'folderName': parent['folderName'],
        'id': '${parent['tapId']}/${moving['sourceStepId']}',
      });
      final at = command['beforeId'] == null
          ? nextRows.lastIndexWhere((r) => r['tapId'] == parent['tapId']) + 1
          : nextRows.indexWhere(
              (r) =>
                  r['tapId'] == parent['tapId'] &&
                  r['sourceStepId'] == command['beforeId'],
            );
      if (at < 0) return;
      nextRows.insert(at, moving);
    }
    setState(() {
      rows = nextRows;
      folders = nextFolders;
      taps = nextTaps;
      previewDirty = true;
      scopeTap = null;
      scopeGroup = null;
      selectedId = null;
    });
  }

  Json? shift(Json from, int delta) {
    final kind = from['kind'];
    late List<String> ids;
    String? parent;
    if (kind == 'group') {
      ids = folders.map((r) => r['id'] as String).toList();
    } else if (kind == 'tap') {
      parent = rows.firstWhere((r) => r['tapId'] == from['id'])['folderId'];
      ids = rows
          .where((r) => r['folderId'] == parent && r['editable'] == true)
          .map((r) => r['tapId'] as String)
          .toSet()
          .toList();
    } else {
      parent = from['sourceTapId'];
      ids = rows
          .where((r) => r['tapId'] == parent)
          .map((r) => r['sourceStepId'] as String)
          .toList();
    }
    final index = ids.indexOf(from['id']);
    if (index < 0 || index + delta < 0 || index + delta >= ids.length) {
      return null;
    }
    final before = delta < 0
        ? ids[index - 1]
        : index + 2 < ids.length
        ? ids[index + 2]
        : null;
    return {
      ...from,
      'beforeId': before,
      if (kind != 'group') 'targetId': parent,
    };
  }

  Future<void> chooseDestination(Json from, {String? folderId}) async {
    final kind = from['kind'];
    final choices = <Json>[];
    if (kind == 'group' || kind == 'tap') {
      for (final f in folders) {
        if (kind == 'group' && f['id'] == from['id']) continue;
        choices.add({
          'label': f['name'],
          'command': kind == 'group'
              ? {...from, 'beforeId': f['id']}
              : {...from, 'targetId': f['id']},
        });
      }
      if (kind == 'group') {
        choices.add({
          'label': '맨 아래',
          'command': {...from, 'beforeId': null},
        });
      }
    } else {
      final seen = <String>{};
      for (final row in taps.where(
        (r) =>
            r['editable'] == true &&
            (folderId == null || r['folderId'] == folderId),
      )) {
        if (!seen.add(row['tapId'])) continue;
        choices.add({
          'label': '${row['folderName']} / ${row['tapTitle']} · 맨 아래',
          'command': {...from, 'targetId': row['tapId']}
            ..remove('targetFolderId'),
        });
      }
    }
    if (choices.isEmpty) {
      notice('이 폴더에 TAP을 먼저 추가해 주세요.');
      return;
    }
    final command = await showAppDialog<Json>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(folderId == null ? '이동 위치' : '이 폴더의 TAP 선택'),
        children: [
          for (final option in choices)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, option['command']),
              child: Text(option['label']),
            ),
        ],
      ),
    );
    if (command != null && mounted) await move(command);
  }

  Widget node({
    required String kind,
    required String id,
    required String label,
    required int depth,
    required bool selected,
    required VoidCallback onTap,
    String? tapId,
    String? folderId,
    bool editable = true,
    bool hasChildren = false,
    int count = 0,
    String? durationText,
  }) {
    final key = '$kind:$id${kind == 'task' ? ':$tapId' : ''}';
    final data = drag(kind, id, tapId: tapId);
    final handle = Tooltip(
      key: ValueKey('manual-drag-$key'),
      message: '순서·소속 드래그',
      child: SizedBox(
        width: 36,
        height: 44,
        child: Icon(Icons.drag_indicator, size: 18, color: AppColors.muted),
      ),
    );
    final feedback = Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Text(
          label,
          style: const TextStyle(fontFamily: 'Pretendard', fontSize: 13),
        ),
      ),
    );
    final source = ops
        .rows('taskTemplates')
        .where((t) => t['id'] == (kind == 'tap' ? id : tapId))
        .firstOrNull;
    final linkedMenu = source?['menuManualId'] != null;
    final deletable =
        !linkedMenu &&
        (kind == 'group'
            ? id != 'general' &&
                  !taps.any((r) => r['folderId'] == id) &&
                  !ops.rows('preparedItems').any((r) => r['folderId'] == id)
            : true);
    Widget row(bool hovering) => Container(
      margin: const EdgeInsets.only(bottom: 2),
      decoration: BoxDecoration(
        color: hovering
            ? AppColors.lime
            : selected
            ? AppColors.green.withValues(alpha: .08)
            : null,
        border: Border(
          left: BorderSide(
            color: hovering ? AppColors.green : AppColors.line,
            width: hovering ? 3 : 1,
          ),
        ),
      ),
      child: Row(
        children: [
          if (hasChildren)
            IconButton(
              tooltip: expanded.contains(key) ? '접기' : '펼치기',
              constraints: const BoxConstraints(minWidth: 36, minHeight: 44),
              icon: Icon(
                expanded.contains(key) || widget.query.isNotEmpty
                    ? Icons.expand_more
                    : Icons.chevron_right,
                size: 18,
              ),
              onPressed: () => setState(
                () => expanded.contains(key)
                    ? expanded.remove(key)
                    : expanded.add(key),
              ),
            )
          else
            const SizedBox(width: 48),
          Expanded(
            child: InkWell(
              key: ValueKey('manual-node-$key'),
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 4,
                ),
                child: Row(
                  children: [
                    Icon(
                      kind == 'group'
                          ? CupertinoIcons.folder
                          : kind == 'tap'
                          ? CupertinoIcons.square_list
                          : CupertinoIcons.doc_text,
                      size: 17,
                      color: AppColors.green,
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Tooltip(
                            triggerMode: TooltipTriggerMode.manual,
                            message: editingTree && editable
                                ? '이름을 눌러 변경'
                                : label,
                            child: InkWell(
                              key: ValueKey('manual-rename-$key'),
                              mouseCursor: editingTree && editable
                                  ? SystemMouseCursors.text
                                  : SystemMouseCursors.click,
                              onTap: editingTree && editable && canEdit
                                  ? () {
                                      onTap();
                                      directEditNode(
                                        context,
                                        ops,
                                        'edit_manual_node',
                                        {
                                          'kind': kind,
                                          'id': id,
                                          'parentId': tapId,
                                          'operation': 'rename',
                                        },
                                        label,
                                      );
                                    }
                                  : null,
                              child: Text(
                                label,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: selected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                          if (durationText != null)
                            Text(
                              durationText,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.muted,
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (durationText == null && kind != 'task')
                      Text(
                        '$count',
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
          if (editable && canEdit && kind != 'group')
            IconButton(
              key: ValueKey('manual-detail-$key'),
              tooltip: kind == 'tap' ? 'TAP 상세 수정' : 'Task 상세 수정',
              icon: const Icon(Icons.tune, size: 18),
              onPressed: () => showAppSheet(
                context,
                builder: (_) => kind == 'tap'
                    ? ManualTapEditor(ops: ops, templateId: id)
                    : ManualTaskEditor(
                        ops: ops,
                        templateId: tapId!,
                        sourceStepId: id,
                      ),
              ),
            ),
          if (editingTree && editable && canEdit) ...[
            PopupMenuButton<String>(
              key: ValueKey('manual-actions-$key'),
              tooltip: '$label 편집',
              icon: const Icon(Icons.more_horiz, size: 18),
              constraints: const BoxConstraints(minWidth: 160),
              onSelected: (action) {
                if (action == 'move') {
                  chooseDestination(data);
                } else {
                  directEditNode(context, ops, 'edit_manual_node', {
                    'kind': kind,
                    'id': id,
                    'parentId': tapId,
                    'operation': action,
                  }, label);
                }
              },
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'move', child: Text('위치 이동')),
                const PopupMenuItem(value: 'rename', child: Text('이름 변경')),
                if (deletable)
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, color: AppColors.accent),
                        SizedBox(width: 8),
                        Text('삭제'),
                      ],
                    ),
                  ),
              ],
            ),
            if (MediaQuery.sizeOf(context).width < 700)
              LongPressDraggable<Json>(
                data: data,
                feedback: feedback,
                child: handle,
              )
            else
              Draggable<Json>(data: data, feedback: feedback, child: handle),
          ],
        ],
      ),
    );
    Widget surface(bool hovering) => Padding(
      padding: EdgeInsets.only(left: depth * 12.0),
      child: DirectEditFrame(
        key: ValueKey('manual-tree-frame-$key'),
        enabled: editable && canEdit,
        active: editingTree,
        controls: false,
        outline: false,
        onEnter: () => setState(() {
          editPane = _ManualEditPane.directory;
          scopeGroup = kind == 'group' ? id : folderId;
          scopeTap = kind == 'group'
              ? null
              : kind == 'tap'
              ? id
              : tapId;
          selectedId = null;
        }),
        child: row(hovering),
      ),
    );
    if (!editingTree || !editable || !canEdit) return surface(false);
    return DragTarget<Json>(
      key: ValueKey('manual-drop-$key'),
      onWillAcceptWithDetails: (d) =>
          destination(d.data, kind, id, tapId: tapId, folderId: folderId) !=
          null,
      onAcceptWithDetails: (d) {
        final command = destination(
          d.data,
          kind,
          id,
          tapId: tapId,
          folderId: folderId,
        );
        if (command != null) move(command);
      },
      builder: (_, candidates, _) => surface(candidates.isNotEmpty),
    );
  }

  Widget directory() {
    final nodes = <Widget>[
      ListTile(
        dense: true,
        leading: const Icon(CupertinoIcons.folder),
        title: const Text('전체 매뉴얼'),
        selected: scopeGroup == null && scopeTap == null,
        onTap: () => setState(() {
          scopeGroup = null;
          scopeTap = null;
          selectedId = null;
        }),
      ),
    ];
    for (final folder in folders) {
      if (folder['id'] == 'store-recipes') continue;
      if (ops.data?['manualBusinessProfile'] != null &&
          !taps.any((t) => t['folderId'] == folder['id'])) {
        continue;
      }
      final all = rows.where((r) => r['folderId'] == folder['id']).toList();
      final matching = all.where(matches).toList();
      final folderTaps = taps
          .where((t) => t['folderId'] == folder['id'])
          .toList();
      final visibleTaps = folderTaps
          .where(
            (t) =>
                widget.query.trim().isEmpty ||
                matching.any((r) => r['tapId'] == t['tapId']) ||
                normalize(
                  '${folder['name']} ${t['tapTitle']}',
                ).contains(normalize(widget.query).trim()),
          )
          .toList();
      if (widget.query.trim().isNotEmpty &&
          visibleTaps.isEmpty &&
          !normalize(folder['name']).contains(normalize(widget.query).trim())) {
        continue;
      }
      nodes.add(
        node(
          kind: 'group',
          id: folder['id'],
          label: folder['name'],
          depth: 0,
          selected: scopeGroup == folder['id'] && scopeTap == null,
          count: folderTaps.length,
          hasChildren: folderTaps.isNotEmpty,
          onTap: () => setState(() {
            scopeGroup = folder['id'];
            scopeTap = null;
            selectedId = null;
            expanded.add('group:${folder['id']}');
          }),
        ),
      );
      if (!expanded.contains('group:${folder['id']}') && widget.query.isEmpty) {
        continue;
      }
      for (final tap in visibleTaps) {
        final children = matching
            .where((r) => r['tapId'] == tap['tapId'])
            .toList();
        nodes.add(
          node(
            kind: 'tap',
            id: tap['tapId'],
            folderId: folder['id'],
            label: tap['editable'] == true
                ? tap['tapTitle']
                : '${tap['tapTitle']} · 오늘 업무',
            depth: 1,
            editable: tap['editable'] == true,
            selected: scopeTap == tap['tapId'],
            hasChildren: children.isNotEmpty,
            count: children.length,
            durationText: all.where((r) => r['tapId'] == tap['tapId']).isEmpty
                ? 'Task 0개'
                : duration(
                    all.where((r) => r['tapId'] == tap['tapId']).toList(),
                  ),
            onTap: () => setState(() {
              scopeGroup = folder['id'];
              scopeTap = tap['tapId'];
              selectedId = null;
              expanded.add('tap:${tap['tapId']}');
            }),
          ),
        );
        if (!expanded.contains('tap:${tap['tapId']}') && widget.query.isEmpty) {
          continue;
        }
        for (final task in children) {
          nodes.add(
            node(
              kind: 'task',
              id: task['sourceStepId'],
              tapId: tap['tapId'],
              folderId: folder['id'],
              label: task['title'],
              depth: 2,
              editable: task['editable'] == true,
              selected: selectedId == task['id'],
              onTap: () {
                setState(() {
                  scopeGroup = folder['id'];
                  scopeTap = tap['tapId'];
                  selectedId = task['id'];
                });
                if (!editingTree) openManual(task);
              },
            ),
          );
        }
      }
    }
    return ListView.builder(
      key: const ValueKey('manual-directory'),
      padding: const EdgeInsets.all(8),
      itemCount: nodes.length,
      itemBuilder: (_, index) => nodes[index],
    );
  }

  Future<void> openManual(Json row) async {
    setState(() => selectedId = row['id']);
    await showAppSheet(
      context,
      builder: (_) => ListenableBuilder(
        listenable: ops,
        builder: (context, _) {
          sync();
          final current =
              rows.where((r) => r['id'] == row['id']).firstOrNull ?? row;
          return AppEditorScaffold(
            title: '매뉴얼',
            body: content(selected: current),
          );
        },
      ),
    );
  }

  Widget content({Json? selected}) {
    final found = results;
    if (selected != null) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            '${selected['folderName'] ?? ''} / ${selected['tapTitle']} / Task',
            style: const TextStyle(fontSize: 13, color: AppColors.muted),
          ),
          const SizedBox(height: 12),
          Text(
            duration([selected]),
            style: const TextStyle(fontSize: 13, color: AppColors.muted),
          ),
          if (canEdit &&
              selected['editable'] == true &&
              selected['templateId'] != null &&
              selected['sourceStepId'] != null)
            Wrap(
              spacing: 8,
              children: [
                PressBounce(
                  child: TextButton.icon(
                    icon: const Icon(CupertinoIcons.clock),
                    label: const Text('TAP 설정'),
                    onPressed: () async {
                      await showAppSheet(
                        context,
                        builder: (_) => TapSettingsScreen(
                          ops: ops,
                          initialTemplateId: selected['templateId'],
                        ),
                      );
                      if (mounted) setState(() => sync(force: true));
                    },
                  ),
                ),
                PressBounce(
                  child: TextButton.icon(
                    icon: const Icon(CupertinoIcons.pencil),
                    label: const Text('매뉴얼 편집'),
                    onPressed: () async {
                      await showAppSheet(
                        context,
                        builder: (_) => ManualTaskEditor(
                          ops: ops,
                          templateId: selected['templateId'],
                          sourceStepId: selected['sourceStepId'],
                        ),
                      );
                      if (mounted) setState(() => sync(force: true));
                    },
                  ),
                ),
              ],
            ),
          Text(
            selected['title'],
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 20),
          SelectableText(
            '${selected['manual']}',
            style: const TextStyle(fontSize: 16, height: 1.65),
          ),
          if ('${selected['tip'] ?? ''}'.isNotEmpty) ...[
            const SizedBox(height: 20),
            Information(selected['tip']),
          ],
          for (final link in {
            'imageUrl': '사진',
            'videoUrl': '영상',
            'sourceUrl': '참고 자료',
          }.entries)
            if ('${selected[link.key] ?? ''}'.isNotEmpty)
              PressBounce(
                child: TextButton.icon(
                  icon: const Icon(CupertinoIcons.arrow_up_right),
                  label: Text(link.value),
                  onPressed: () async {
                    final uri = Uri.tryParse(selected[link.key]);
                    if (uri != null && uri.scheme == 'https') {
                      await launchUrl(
                        uri,
                        mode: LaunchMode.externalApplication,
                      );
                    }
                  },
                ),
              ),
        ],
      );
    }
    return ListView.builder(
      key: const ValueKey('manual-results'),
      padding: const EdgeInsets.all(12),
      itemCount: found.isEmpty ? 1 : found.length,
      itemBuilder: (_, index) {
        if (found.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              widget.query.trim().isNotEmpty
                  ? '검색 결과가 없어요.'
                  : canEdit
                  ? 'Task가 없어요. TAP을 선택하고 Task를 추가해 주세요.'
                  : '등록된 Task가 없어요.',
            ),
          );
        }
        final row = found[index];
        final source = ops
            .rows('taskTemplates')
            .where((t) => t['id'] == row['templateId'])
            .firstOrNull;
        final linked = source?['menuManualId'] != null;
        return DirectEditFrame(
          enabled: canEdit && row['editable'] == true,
          key: ValueKey('manual-content-frame-${row['id']}'),
          active: editingContent,
          onEnter: () => setState(() => editPane = _ManualEditPane.content),
          onRename: () => directEditNode(context, ops, 'edit_manual_node', {
            'kind': 'task',
            'id': row['sourceStepId'],
            'parentId': row['templateId'],
            'operation': 'rename',
          }, row['title']),
          onDelete: linked
              ? null
              : () => directEditNode(context, ops, 'edit_manual_node', {
                  'kind': 'task',
                  'id': row['sourceStepId'],
                  'parentId': row['templateId'],
                  'operation': 'delete',
                }, row['title']),
          onMove: () => chooseDestination(
            drag('task', row['sourceStepId'], tapId: row['templateId']),
          ),
          child: AppCard(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              title: Text(
                row['title'],
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(duration([row]), maxLines: 1),
              trailing: const Icon(CupertinoIcons.chevron_right, size: 16),
              onTap: () {
                setState(() {
                  selectedId = row['id'];
                  expanded.add('group:${row['folderId']}');
                  expanded.add('tap:${row['tapId']}');
                  showTree = false;
                });
                openManual(row);
              },
            ),
          ),
        );
      },
    );
  }

  Widget recipeList() {
    final available = ops
        .rows('taskTemplates')
        .where((t) => t['menuManualId'] != null && t['archivedAt'] == null)
        .toList();
    if (!ops.canEditTasks) {
      final grouped = <String, Json>{};
      for (final row
          in ops.rows('manualSearch').where((r) => r['menuManualId'] != null)) {
        final id = row['templateId'] as String;
        final template = grouped.putIfAbsent(
          id,
          () => {'id': id, 'title': row['tapTitle'], 'steps': <Json>[]},
        );
        (template['steps'] as List).add(row);
      }
      available.addAll(grouped.values);
    }
    final templates = available
        .where(
          (t) => normalize(
            '${t['title']} ${(t['steps'] as List? ?? []).map((s) => s['manual']).join(' ')}',
          ).contains(normalize(widget.query)),
        )
        .toList();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('우리 매장만의 메뉴와 레시피', style: AppText.section),
        const SizedBox(height: 8),
        const Text(
          '판매 메뉴별 재료·분량·조리 순서·제공 기준을 직접 채워 주세요. 마켓의 공통 운영 매뉴얼과 따로 관리해요.',
          style: AppText.caption,
        ),
        if (ops.canEditTasks)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => showAppSheet(
                context,
                builder: (_) => CatalogEditor(ops: ops, menusOnly: true),
              ),
              icon: const Icon(Icons.add),
              label: const Text('판매 메뉴 추가·관리'),
            ),
          ),
        if (templates.isEmpty)
          const Information('판매 메뉴를 등록하면 메뉴별 레시피 공간이 생겨요.'),
        for (final t in templates)
          ListTile(
            key: ValueKey('store-recipe-${t['id']}'),
            contentPadding: EdgeInsets.zero,
            title: Text(t['manualTitle'] ?? t['title']),
            subtitle: const Text('매장 전용 · 레시피 보기'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => showAppSheet(
              context,
              builder: (_) => ops.canEditTasks
                  ? ManualTapEditor(ops: ops, templateId: t['id'])
                  : AppEditorScaffold(
                      title: t['title'],
                      body: ListView(
                        padding: const EdgeInsets.all(24),
                        children: [
                          for (final step
                              in (t['steps'] as List).cast<Json>()) ...[
                            Text(step['title'], style: AppText.section),
                            const SizedBox(height: 8),
                            Text(step['manual'] ?? '', style: AppText.body),
                            if ((step['tip'] ?? '').isNotEmpty)
                              Text(step['tip'], style: AppText.caption),
                            const SizedBox(height: 24),
                          ],
                        ],
                      ),
                    ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    sync();
    if (!ops.canEditTasks) editPane = null;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1240),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 760;
              final toolsVisible =
                  constraints.maxHeight >= 440 && widget.query.trim().isEmpty;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => setState(() => recipes = false),
                          child: Text(
                            '운영 매뉴얼',
                            style: TextStyle(
                              color: recipes ? AppColors.muted : AppColors.ink,
                              fontWeight: recipes
                                  ? FontWeight.normal
                                  : FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: TextButton(
                          onPressed: () => setState(() {
                            recipes = true;
                            editPane = null;
                          }),
                          child: Text(
                            '메뉴·레시피',
                            style: TextStyle(
                              color: recipes ? AppColors.ink : AppColors.muted,
                              fontWeight: recipes
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (!recipes && ops.canEditTasks && toolsVisible)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        ops.data?['manualBusinessProfile']?['specialization'] ??
                            '내 사업장에 맞게 시작하기',
                        style: AppText.body,
                      ),
                      subtitle: const Text(
                        '업종 선택 · 필요한 매뉴얼 담기 · 업무별 구성',
                        style: AppText.caption,
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => showAppSheet(
                        context,
                        builder: (_) =>
                            ManualMarketScreen(ops: ops, setup: true),
                      ),
                    ),
                  if (!recipes)
                    Wrap(
                      spacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (ops.canEditTasks && toolsVisible) ...[
                          TextButton.icon(
                            onPressed: () => showAppSheet(
                              context,
                              builder: (_) => ManualMarketScreen(
                                ops: ops,
                                folderId: scopeGroup,
                              ),
                            ),
                            icon: const Icon(Icons.storefront_outlined),
                            label: const Text('매뉴얼 마켓'),
                          ),
                          TextButton.icon(
                            onPressed: () => showAppSheet(
                              context,
                              builder: (_) => ManualTapEditor(
                                ops: ops,
                                folderId: scopeGroup,
                              ),
                            ),
                            icon: const Icon(Icons.add),
                            label: const Text('운영 매뉴얼 추가'),
                          ),
                          TextButton(
                            onPressed: () => showAppSheet(
                              context,
                              builder: (_) => ChecklistBackupScreen(ops: ops),
                            ),
                            child: const Text('백업·복원'),
                          ),
                        ],
                        if (!wide)
                          PressBounce(
                            child: TextButton.icon(
                              icon: Icon(
                                showTree
                                    ? CupertinoIcons.doc_text
                                    : CupertinoIcons.folder,
                              ),
                              label: Text(
                                showTree ? '매뉴얼 ${results.length}' : '디렉토리',
                              ),
                              onPressed: () => setState(() {
                                showTree = !showTree;
                                editPane = null;
                              }),
                            ),
                          ),
                        if (scopeGroup != null || scopeTap != null)
                          InputChip(
                            chipAnimationStyle: AppMotion.chipStyle(context),
                            label: Text(
                              scopeTap == null
                                  ? '${folders.where((f) => f['id'] == scopeGroup).firstOrNull?['name'] ?? 'TAP그룹'}'
                                  : '${taps.where((r) => r['tapId'] == scopeTap).firstOrNull?['tapTitle'] ?? 'TAP'}',
                            ),
                            onDeleted: () => setState(() {
                              scopeGroup = null;
                              scopeTap = null;
                              selectedId = null;
                            }),
                          ),
                        if (ops.canEditTasks && toolsVisible)
                          DirectEditBar(
                            active: editing,
                            onDone: () => setState(() => editPane = null),
                            onAdd: () => directEditNode(
                              context,
                              ops,
                              'edit_manual_node',
                              {
                                'kind': scopeTap != null
                                    ? 'task'
                                    : scopeGroup != null
                                    ? 'tap'
                                    : 'group',
                                'parentId': scopeTap ?? scopeGroup,
                                'operation': 'add',
                              },
                              '',
                            ),
                            addLabel: scopeTap != null
                                ? 'Task 추가'
                                : scopeGroup != null
                                ? 'TAP 추가'
                                : '그룹 추가',
                          ),
                        if (editing && ops.readOnly)
                          const Text(
                            '드래그 체험 · 저장 안 됨',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.muted,
                            ),
                          ),
                        if (previewDirty)
                          PressBounce(
                            child: TextButton(
                              onPressed: () =>
                                  setState(() => sync(force: true)),
                              child: const Text('초기화'),
                            ),
                          ),
                      ],
                    ),
                  if (editing)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        editingTree
                            ? '폴더 구조 편집 · 이름을 눌러 수정해요. TAP은 폴더로, Task는 TAP으로 옮겨요.'
                            : 'Task 편집 · 카드에서 이름·위치·삭제를 선택해요.',
                        style: TextStyle(fontSize: 13, color: AppColors.muted),
                      ),
                    ),
                  Expanded(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        boxShadow: appCardShadow,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: recipes
                          ? recipeList()
                          : wide
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                SizedBox(width: 340, child: directory()),
                                const VerticalDivider(width: 1),
                                Expanded(
                                  child: AppContentTransition(
                                    trigger: (scopeGroup, scopeTap),
                                    child: content(),
                                  ),
                                ),
                              ],
                            )
                          : AppContentTransition(
                              trigger: (showTree, scopeGroup, scopeTap),
                              child: showTree ? directory() : content(),
                            ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
