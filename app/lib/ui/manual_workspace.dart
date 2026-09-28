import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../state/operations_controller.dart';
import 'components.dart';
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

class _ManualWorkspaceState extends State<ManualWorkspace> {
  List<Json> rows = [], folders = [];
  int revision = -1;
  String actor = '';
  String? scopeGroup, scopeTap, selectedId;
  bool editing = false, showTree = true, previewDirty = false;
  final expanded = <String>{};
  OperationsController get ops => widget.ops;
  bool get canEdit => ops.isLeader && !ops.busy;
  Json copy(Json row) => jsonDecode(jsonEncode(row)) as Json;

  void sync({bool force = false}) {
    final changedActor = actor != ops.actorId;
    if (!force &&
        !changedActor &&
        (previewDirty || revision == ops.data?['revision'])) {
      return;
    }
    rows = ops.rows('manualSearch').map(copy).toList();
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
      editing = false;
      scopeGroup = null;
      scopeTap = null;
      selectedId = null;
      expanded.clear();
      expanded.addAll(folders.map((f) => 'group:${f['id']}'));
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
      if (moving.isEmpty || target == null) return;
      nextRows.removeWhere((r) => r['tapId'] == command['id']);
      for (final r in moving) {
        r['folderId'] = target['id'];
        r['folderName'] = target['name'];
      }
      final at = command['beforeId'] == null
          ? nextRows.length
          : nextRows.indexWhere((r) => r['tapId'] == command['beforeId']);
      if (at < 0) return;
      nextRows.insertAll(at, moving);
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
      if (moving == null || target.isEmpty) return;
      final different = command['sourceTapId'] != command['targetId'];
      if (different && source.length <= 1) {
        notice('TAP에는 Task가 하나 이상 남아야 해요.');
        return;
      }
      if (different && target.length >= 30) {
        notice('한 TAP의 Task는 최대 30개예요.');
        return;
      }
      if (different && target.any((r) => r['sourceStepId'] == command['id'])) {
        moving['sourceStepId'] =
            'manual-${DateTime.now().microsecondsSinceEpoch}';
        moving['stepId'] = moving['sourceStepId'];
      }
      final parent = target.first;
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

  Future<void> chooseDestination(Json from) async {
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
      for (final row in rows.where((r) => r['editable'] == true)) {
        if (!seen.add(row['tapId'])) continue;
        choices.add({
          'label': '${row['folderName']} / ${row['tapTitle']} · 맨 아래',
          'command': {...from, 'targetId': row['tapId']},
        });
      }
    }
    final command = await showAppDialog<Json>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('이동 위치'),
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
    Widget row(bool hovering) => Container(
      margin: EdgeInsets.only(left: depth * 12.0, bottom: 2),
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
            const SizedBox(width: 12),
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
                    if (durationText != null) ...[
                      const SizedBox(width: 4),
                      Text(
                        durationText,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.muted,
                        ),
                      ),
                    ] else if (kind != 'task')
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
          if (editing && editable && canEdit) ...[
            if (MediaQuery.sizeOf(context).width < 700)
              LongPressDraggable<Json>(
                data: data,
                feedback: feedback,
                child: handle,
              )
            else
              Draggable<Json>(data: data, feedback: feedback, child: handle),
            PopupMenuButton<String>(
              popUpAnimationStyle: AppMotion.dialogStyle(context),
              tooltip: '이동',
              iconSize: 18,
              onSelected: (value) {
                if (value == 'move') {
                  chooseDestination(data);
                } else {
                  final command = shift(data, value == 'up' ? -1 : 1);
                  if (command != null) move(command);
                }
              },
              itemBuilder: (_) => [
                if (shift(data, -1) != null)
                  const PopupMenuItem(value: 'up', child: Text('위로')),
                if (shift(data, 1) != null)
                  const PopupMenuItem(value: 'down', child: Text('아래로')),
                const PopupMenuItem(value: 'move', child: Text('이동 위치 선택')),
              ],
            ),
          ],
        ],
      ),
    );
    if (!editing || !editable || !canEdit) return row(false);
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
      builder: (_, candidates, _) => row(candidates.isNotEmpty),
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
      final all = rows.where((r) => r['folderId'] == folder['id']).toList();
      final matching = all.where(matches).toList();
      if (widget.query.trim().isNotEmpty && matching.isEmpty) continue;
      nodes.add(
        node(
          kind: 'group',
          id: folder['id'],
          label: folder['name'],
          depth: 0,
          selected: scopeGroup == folder['id'] && scopeTap == null,
          count: all.map((r) => r['tapId']).toSet().length,
          hasChildren: all.isNotEmpty,
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
      final seen = <String>{};
      for (final tap in matching) {
        if (!seen.add(tap['tapId'])) continue;
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
            hasChildren: true,
            count: children.length,
            durationText: duration(
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
                openManual(task);
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
          return Scaffold(
            appBar: AppBar(
              title: const Text('매뉴얼'),
              leading: const CloseButton(),
            ),
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
              selected['templateId'] != null)
            Wrap(
              spacing: 8,
              children: [
                PressBounce(
                  child: TextButton.icon(
                    icon: const Icon(CupertinoIcons.clock),
                    label: const Text('소요시간 설정'),
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
                        builder: (_) => ChecklistEditor(
                          ops: ops,
                          initialFolder: selected['folderId'],
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
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Text('검색 결과가 없어요.'),
          );
        }
        final row = found[index];
        return AppCard(
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
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    sync();
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1240),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 760;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Wrap(
                    spacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
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
                            onPressed: () =>
                                setState(() => showTree = !showTree),
                          ),
                        ),
                      if (scopeGroup != null || scopeTap != null)
                        InputChip(
                          chipAnimationStyle: AppMotion.chipStyle(context),
                          label: Text(
                            scopeTap == null
                                ? '${folders.where((f) => f['id'] == scopeGroup).firstOrNull?['name'] ?? 'TAP그룹'}'
                                : '${rows.where((r) => r['tapId'] == scopeTap).firstOrNull?['tapTitle'] ?? 'TAP'}',
                          ),
                          onDeleted: () => setState(() {
                            scopeGroup = null;
                            scopeTap = null;
                            selectedId = null;
                          }),
                        ),
                      if (ops.isLeader)
                        PressBounce(
                          child: TextButton.icon(
                            icon: Icon(
                              editing
                                  ? Icons.check
                                  : Icons.drive_file_move_outline,
                            ),
                            label: Text(editing ? '편집 완료' : '구조 편집'),
                            onPressed: ops.busy
                                ? null
                                : () => setState(() => editing = !editing),
                          ),
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
                            onPressed: () => setState(() => sync(force: true)),
                            child: const Text('초기화'),
                          ),
                        ),
                    ],
                  ),
                  if (editing)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 8),
                      child: Text(
                        '같은 단계에 놓으면 앞 순서로, 상위 항목에 놓으면 안으로 이동해요.',
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
                      child: wide
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
