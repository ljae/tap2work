import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import '../domain/checklist_draft.dart';
import 'package:url_launcher/url_launcher.dart';
import '../state/operations_controller.dart';
import 'checklist_board.dart' show rowsOf, stampOf;
import 'checklist_editor.dart';
import 'components.dart';
import 'tap_card.dart';

/// Folders, daily tasks and actions share one board and one card component.
/// Existing IDs, role checks and completion APIs remain the source of truth.
class TapWorkspace extends StatefulWidget {
  const TapWorkspace({super.key, required this.ops, required this.onStock});
  final OperationsController ops;
  final Future<void> Function(Json) onStock;
  @override
  State<TapWorkspace> createState() => _TapWorkspaceState();
}

class _TapWorkspaceState extends State<TapWorkspace> {
  String? folderId, taskId;
  String? selectedStepId;
  String query = '';
  bool mineOnly = false;
  final search = TextEditingController();
  final previewStepOrder = <String, List<String>>{};
  List<String>? previewGroupOrder;
  OperationsController get ops => widget.ops;

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  List<Json> get groups =>
      ops.rows('tasks').where((t) => t['kind'] == 'routine').toList()..sort(
        (a, b) => ((a['displayOrder'] ?? 0) as int).compareTo(
          (b['displayOrder'] ?? 0) as int,
        ),
      );

  List<Json> steps(Json task) {
    final result = <Json>[
      for (final step in rowsOf(task['steps'])) {...step},
    ];
    final order =
        previewStepOrder['${ops.actorId}/${ops.data?['day']}/${task['id']}'];
    if (order != null) {
      result.sort(
        (a, b) => order.indexOf(a['id']).compareTo(order.indexOf(b['id'])),
      );
    }
    return result;
  }

  int total(Json task) => steps(task).length;
  int done(Json task) =>
      steps(task).where((s) => s['completedAt'] != null).length;
  String status(Json task) {
    if (total(task) > 0 && done(task) == total(task)) return '완료';
    final state = task['boardStatus'];
    return state == 'processing' ? '주문처리중' : '할일';
  }

  String folderOf(Json task) => task['folderId'] ?? 'general';
  List<Json> inFolder(String id) =>
      groups.where((t) => folderOf(t) == id).toList();

  List<Json> get folders {
    final result = ops.rows('checklistFolders').map((f) => {...f}).toList();
    for (final t in groups) {
      final id = folderOf(t);
      if (!result.any((f) => f['id'] == id)) {
        result.add({'id': id, 'name': id == 'general' ? '기본 업무' : '기타 업무'});
      }
    }
    final order =
        previewGroupOrder ??
        (ops.data?['bigTapOrder'] as List?)?.cast<String>() ??
        [
          'order-work',
          'marketing',
          'bone-preparation',
          'noodle-preparation',
          'service',
          'maintenance',
          'settlement',
        ];
    result.removeWhere(
      (f) =>
          ['general', 'bonejjim'].contains(f['id']) &&
          inFolder(f['id']).isEmpty,
    );
    result.sort((a, b) {
      final ai = order.indexOf(a['id']);
      final bi = order.indexOf(b['id']);
      if (ai >= 0 && bi >= 0) return ai.compareTo(bi);
      if (ai >= 0) return -1;
      if (bi >= 0) return 1;
      return a['name'].toString().compareTo(b['name'].toString());
    });
    return result;
  }

  bool visibleTask(Json task) =>
      !mineOnly ||
      ops.isLeader ||
      task['requiredRole'] == 'all' ||
      task['requiredRole'] == ops.actor['role'];
  String place(Json task) =>
      ops
              .rows('zones')
              .where((z) => z['id'] == task['zone'])
              .firstOrNull?['name']
          as String? ??
      '';
  String role(Json task) => checklistRoles[task['requiredRole']] ?? '누구나';
  void navigate({String? folder, String? task}) {
    FocusScope.of(context).unfocus();
    setState(() {
      folderId = folder;
      taskId = task;
      selectedStepId = null;
      query = '';
      search.clear();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final position = Scrollable.maybeOf(context)?.position;
      position?.jumpTo(position.minScrollExtent);
    });
  }

  void notice(String text) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(text)));

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: ops,
    builder: (context, _) {
      final folder = folders.where((f) => f['id'] == folderId).firstOrNull;
      final task = groups.where((t) => t['id'] == taskId).firstOrNull;
      final level = task != null ? 'SMALL TAP' : 'TAP';
      final scoped = (folder == null ? groups : inFolder(folder['id']))
          .where(visibleTask)
          .toList();
      final title = task?['title'] ?? folder?['name'] ?? '체크리스트';
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (folder != null)
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                TextButton.icon(
                  onPressed: () => navigate(),
                  icon: const Icon(Icons.dashboard_outlined, size: 17),
                  label: const Text('전체 보드'),
                ),
                const Icon(
                  Icons.chevron_right,
                  size: 16,
                  color: AppColors.muted,
                ),
                TextButton(
                  onPressed: () => navigate(folder: folder['id']),
                  child: Text(folder['name']),
                ),
                if (task != null) ...[
                  const Icon(
                    Icons.chevron_right,
                    size: 16,
                    color: AppColors.muted,
                  ),
                  TextButton(
                    onPressed: () => navigate(folder: folderId, task: taskId),
                    child: Text(task['title']),
                  ),
                ],
              ],
            ),
          if (folder != null) const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              letterSpacing: -.8,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            task != null
                ? '${task['slot']} · ${role(task)} · ${place(task)}'
                : folder != null
                ? 'Tap을 열어, 해야 할 작은 행동을 확인하세요.'
                : '오늘의 업무를 한눈에. 카드를 끌어 순서와 상태를 바꾸세요.',
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 13,
              height: 1.6,
            ),
          ),
          if (task != null &&
              (task['customer_memo'] ?? '').toString().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Information('요청사항 · ${task['customer_memo']}'),
            ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (!ops.isLeader)
                FilterChip(
                  label: const Text('내 담당만'),
                  selected: mineOnly,
                  onSelected: (v) => setState(() => mineOnly = v),
                ),
              if (ops.isLeader)
                TextButton.icon(
                  onPressed: ops.busy
                      ? null
                      : () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => ChecklistEditor(
                              ops: ops,
                              initialFolder: folderId,
                            ),
                          ),
                        ),
                  icon: const Icon(
                    CupertinoIcons.slider_horizontal_3,
                    size: 17,
                  ),
                  label: const Text('보드 편집'),
                ),
            ],
          ),
          const SizedBox(height: 16),
          ...[
            if (task == null) ...[_folderBar(), const SizedBox(height: 16)],
            TextField(
              controller: search,
              onChanged: (v) => setState(() => query = v.trim().toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Tap 검색',
                prefixIcon: const Icon(CupertinoIcons.search, size: 20),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.line),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '$level · ${task != null
                        ? '하나의 행동'
                        : folder != null
                        ? '하나의 업무'
                        : '전체 업무'}',
                    style: const TextStyle(
                      fontSize: 11,
                      letterSpacing: .7,
                      color: AppColors.muted,
                    ),
                  ),
                ),
                if (ops.readOnly)
                  const Text(
                    '체험 · 저장 안 됨',
                    style: TextStyle(fontSize: 11, color: AppColors.muted),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            _board(folder, task, scoped),
          ],
          if (folder == null && task == null) _stock(),
        ],
      );
    },
  );

  Widget _board(Json? folder, Json? task, List<Json> scoped) {
    if (task != null) return _smallBoard(task);

    final entries = <({String id, String state, Widget card})>[];
    bool matches(String name) => name.toLowerCase().contains(query);
    for (final t in scoped.where(
      (t) => matches('${t['title']} ${t['orderNumber'] ?? ''}'),
    )) {
      entries.add((
        id: t['id'],
        state: status(t),
        card: _draggable(
          data: t['id'],
          feedback: Material(
            elevation: 8,
            child: SizedBox(width: 260, child: Text(t['title'])),
          ),
          child: TapCard(
            key: ValueKey('tap-${t['id']}'),
            level: 'TAP',
            emoji: t['emoji'] ?? '📋',
            title: t['title'],
            subtitle:
                '${folders.where((f) => f['id'] == folderOf(t)).firstOrNull?['name'] ?? ''} · ${t['slot']} · ${role(t)}',
            total: total(t),
            done: done(t),
            footer: 'Small Tap ${done(t)}/${total(t)}',
            onOpen: () => navigate(folder: folderOf(t), task: t['id']),
            onCheck: () => t['orderId'] != null
                ? _checkMenu(t)
                : _moveTap(
                    t,
                    folderOf(t),
                    status(t) == '완료' ? 'processing' : 'done',
                  ),
            checked: status(t) == '완료',
          ),
        ),
      ));
    }
    final orderIds = scoped
        .map((t) => t['orderId'])
        .whereType<String>()
        .toSet();
    for (final orderId in orderIds) {
      final members = scoped.where((t) => t['orderId'] == orderId).toList();
      final cards = entries
          .where((e) => members.any((t) => t['id'] == e.id))
          .toList();
      if (cards.isEmpty) continue;
      final first = members.first;
      final state = members.every((t) => status(t) == '완료')
          ? '완료'
          : members.any((t) => status(t) != '할일')
          ? '주문처리중'
          : '할일';
      final position = entries.indexWhere(
        (e) => members.any((t) => t['id'] == e.id),
      );
      entries.removeWhere((e) => members.any((t) => t['id'] == e.id));
      entries.insert(position, (
        id: first['id'],
        state: state,
        card: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: AppColors.line),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _draggable(
                data: first['id'],
                feedback: Material(child: Text('주문 ${first['orderNumber']}')),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '주문 ${first['orderNumber']} · ${members.length} 메뉴 ↕',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      PopupMenuButton<String>(
                        tooltip: '주문 그룹 이동',
                        onSelected: (value) =>
                            _moveTap(first, folderOf(first), value),
                        itemBuilder: (_) => const [
                          PopupMenuItem(
                            value: 'todo',
                            child: Text('전체 할일로 이동'),
                          ),
                          PopupMenuItem(
                            value: 'processing',
                            child: Text('전체 조리 시작'),
                          ),
                          PopupMenuItem(value: 'done', child: Text('전체 완료')),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              for (final card in cards) card.card,
            ],
          ),
        ),
      ));
    }
    final lanes = ['할일', '주문처리중', '완료'];
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 760;
        final width = wide
            ? (constraints.maxWidth - 12 * (lanes.length - 1)) / lanes.length
            : (constraints.maxWidth - 20).clamp(230.0, 340.0);
        return SingleChildScrollView(
          key: ValueKey('board/$folderId/$taskId'),
          scrollDirection: Axis.horizontal,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final (index, lane) in lanes.indexed)
                DragTarget<String>(
                  onWillAcceptWithDetails: (d) =>
                      !ops.busy && !d.data.startsWith('folder:'),
                  onAcceptWithDetails: (details) {
                    final moving = groups
                        .where((t) => t['id'] == details.data)
                        .firstOrNull;
                    if (moving != null) {
                      _moveTap(
                        moving,
                        folderOf(moving),
                        lane == '완료'
                            ? 'done'
                            : lane == '주문처리중'
                            ? 'processing'
                            : 'todo',
                      );
                    }
                  },
                  builder: (context, candidates, rejected) => Container(
                    width: width,
                    margin: EdgeInsets.only(
                      right: index == lanes.length - 1 ? 0 : 12,
                    ),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: candidates.isNotEmpty
                          ? const Color(0xFFFCE8E4)
                          : const Color(0xFFEBEDF0),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(4, 2, 4, 14),
                          child: Row(
                            children: [
                              Container(
                                width: 7,
                                height: 7,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: lane == '완료'
                                      ? AppColors.green
                                      : lane == '주문처리중'
                                      ? AppColors.accent
                                      : AppColors.muted,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  lane,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              Text(
                                '${entries.where((e) => e.state == lane).length}',
                                style: const TextStyle(
                                  color: AppColors.muted,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        for (final entry in entries.where(
                          (e) => e.state == lane,
                        ))
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: DragTarget<String>(
                              onWillAcceptWithDetails: (details) =>
                                  details.data != entry.id &&
                                  !details.data.startsWith('folder:'),
                              onAcceptWithDetails: (details) {
                                final moving = groups
                                    .where((row) => row['id'] == details.data)
                                    .firstOrNull;
                                if (moving != null) {
                                  _moveTap(
                                    moving,
                                    folderOf(moving),
                                    lane == '완료'
                                        ? 'done'
                                        : lane == '주문처리중'
                                        ? 'processing'
                                        : 'todo',
                                    beforeTaskId: entry.id,
                                  );
                                }
                              },
                              builder: (context, candidates, rejected) =>
                                  DecoratedBox(
                                    decoration: BoxDecoration(
                                      border: candidates.isNotEmpty
                                          ? const Border(
                                              top: BorderSide(
                                                color: AppColors.accent,
                                                width: 3,
                                              ),
                                            )
                                          : null,
                                    ),
                                    child: entry.card,
                                  ),
                            ),
                          ),
                        if (!entries.any((e) => e.state == lane))
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 24,
                              horizontal: 8,
                            ),
                            child: Text(
                              query.isNotEmpty ? '검색 결과가 없어요' : '아직 카드가 없어요',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.muted,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _checkMenu(Json task) async {
    if (status(task) == '완료') {
      await _toggle(task, steps(task).first);
    } else if (ops.readOnly) {
      for (final step in steps(task).where((s) => s['completedAt'] == null)) {
        ops.previewToggleStep(task['id'], step['id']);
      }
    } else {
      final ok = await ops.act('complete_task', {'taskId': task['id']});
      if (!ok && mounted) notice(ops.error ?? '완료하지 못했어요.');
    }
  }

  Future<void> _moveTap(
    Json task,
    String targetFolder,
    String targetStatus, {
    String? beforeTaskId,
  }) async {
    final ownCompleted =
        task['completedAt'] != null &&
        task['completedBy']?['id'] == ops.actor['id'];
    if (!ops.isLeader && task['canComplete'] != true && !ownCompleted) {
      notice('담당 Tap만 이동할 수 있어요.');
      return;
    }
    if (query.isNotEmpty) {
      notice('검색을 지운 뒤 순서를 바꿔 주세요.');
      return;
    }
    if (ops.readOnly) {
      ops.previewMoveTap(
        task['id'],
        targetFolder,
        targetStatus,
        beforeTaskId: beforeTaskId,
      );
      return;
    }
    final payload = <String, dynamic>{
      'taskId': task['id'],
      'folderId': targetFolder,
      'status': targetStatus,
    };
    if (beforeTaskId != null) payload['beforeTaskId'] = beforeTaskId;
    final ok = await ops.act('move_tap', payload);
    if (!ok && mounted) notice(ops.error ?? '이동하지 못했어요.');
  }

  Widget _draggable({
    required String data,
    required Widget feedback,
    required Widget child,
  }) {
    final mobile =
        defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.android;
    final faded = Opacity(opacity: .3, child: child);
    return MouseRegion(
      cursor: SystemMouseCursors.grab,
      child: mobile
          ? LongPressDraggable<String>(
              data: data,
              feedback: feedback,
              childWhenDragging: faded,
              maxSimultaneousDrags: ops.busy ? 0 : 1,
              child: child,
            )
          : Draggable<String>(
              data: data,
              feedback: feedback,
              childWhenDragging: faded,
              maxSimultaneousDrags: ops.busy ? 0 : 1,
              child: child,
            ),
    );
  }

  Widget _folderBar() => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(
      spacing: 8,
      children: [
        ChoiceChip(
          label: const Text('전체 Tap'),
          selected: folderId == null,
          onSelected: (_) => navigate(),
        ),
        for (final folder in folders)
          DragTarget<String>(
            onWillAcceptWithDetails: (_) => !ops.busy,
            onAcceptWithDetails: (details) {
              if (details.data.startsWith('folder:')) {
                _reorderGroup(details.data.substring(7), folder['id']);
              } else {
                final task = groups
                    .where((t) => t['id'] == details.data)
                    .firstOrNull;
                if (task != null) {
                  _moveTap(
                    task,
                    folder['id'],
                    status(task) == '완료'
                        ? 'done'
                        : status(task) == '주문처리중'
                        ? 'processing'
                        : 'todo',
                  );
                }
              }
            },
            builder: (context, candidates, _) => _draggable(
              data: 'folder:${folder['id']}',
              feedback: Material(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(folder['name']),
                ),
              ),
              child: ChoiceChip(
                avatar: Icon(
                  CupertinoIcons.folder,
                  size: 16,
                  color: candidates.isNotEmpty
                      ? AppColors.accent
                      : AppColors.muted,
                ),
                label: Text(
                  '${folder['name']}  ·  ${inFolder(folder['id']).length}',
                ),
                selected: folderId == folder['id'] || candidates.isNotEmpty,
                onSelected: (_) => navigate(folder: folder['id']),
              ),
            ),
          ),
        if (ops.isLeader)
          ActionChip(
            avatar: const Icon(CupertinoIcons.folder_badge_plus, size: 17),
            label: const Text('폴더 관리'),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) =>
                    ChecklistEditor(ops: ops, initialFolder: folderId),
              ),
            ),
          ),
      ],
    ),
  );

  Future<void> _reorderGroup(String source, String target) async {
    if (!ops.isLeader || source == target) return;
    final ids = List<String>.from(
      previewGroupOrder ??
          (ops.data?['bigTapOrder'] as List?)?.cast<String>() ??
          const <String>[],
    );
    if (!ids.contains(source) || !ids.contains(target)) return;
    ids.remove(source);
    ids.insert(ids.indexOf(target), source);
    if (ops.readOnly) {
      setState(() => previewGroupOrder = ids);
      notice('체험 순서만 바꿨어요. 저장되지 않아요.');
    } else {
      final ok = await ops.act('reorder_big_taps', {'folderIds': ids});
      if (!ok && mounted) notice(ops.error ?? '순서를 저장하지 못했어요.');
    }
  }

  Widget _smallBoard(Json task) {
    final all = steps(task)
        .where((s) => s['title'].toString().toLowerCase().contains(query))
        .toList();
    final selected =
        all.where((s) => s['id'] == selectedStepId).firstOrNull ??
        all.firstOrNull;
    Widget card(Json step) => Padding(
      key: ValueKey('sort-small-${step['id']}'),
      padding: const EdgeInsets.only(bottom: 8),
      child: TapCard(
        key: ValueKey('small-${step['id']}'),
        level: 'SMALL TAP',
        emoji: '✓',
        title: step['title'],
        subtitle: step['completedAt'] == null
            ? '방법 보기'
            : '${step['completedBy']?['name'] ?? ''} · ${stampOf(step['completedAt'])} 확인',
        onOpen: () {
          setState(() => selectedStepId = step['id']);
          if (MediaQuery.sizeOf(context).width < 700) {
            showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              showDragHandle: true,
              builder: (context) => SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: _manual(task, step),
                ),
              ),
            );
          }
        },
        checked: step['completedAt'] != null,
        locked: task['canComplete'] != true,
        onCheck: () {
          setState(() => selectedStepId = step['id']);
          _toggle(task, step);
        },
      ),
    );
    Widget list = ops.isLeader && query.isEmpty
        ? ReorderableListView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            onReorder: (oldIndex, newIndex) async {
              final ids = all.map((s) => s['id'] as String).toList();
              if (newIndex > oldIndex) newIndex--;
              ids.insert(newIndex, ids.removeAt(oldIndex));
              if (ops.readOnly) {
                setState(
                  () =>
                      previewStepOrder['${ops.actorId}/${ops.data?['day']}/${task['id']}'] =
                          ids,
                );
                notice('체험 순서만 바꿨어요. 저장되지 않아요.');
              } else {
                final ok = await ops.act('reorder_small_taps', {
                  'taskId': task['id'],
                  'stepIds': ids,
                });
                if (!ok && mounted) notice(ops.error ?? '순서를 저장하지 못했어요.');
              }
            },
            children: [for (final step in all) card(step)],
          )
        : Column(children: [for (final step in all) card(step)]);
    Widget detail = selected == null
        ? const Information('Small Tap을 선택해 주세요.')
        : Surface(child: _manual(task, selected));
    return LayoutBuilder(
      builder: (context, constraints) => constraints.maxWidth >= 700
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: list),
                const SizedBox(width: 16),
                Expanded(child: detail),
              ],
            )
          : list,
    );
  }

  Widget _manual(Json task, Json step) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        step['title'],
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 16),
      Text(step['manual'] ?? '등록된 방법이 없어요.'),
      if ((step['tip'] ?? '').toString().isNotEmpty) Text('팁 · ${step['tip']}'),
      if (ops.isLeader && step['completedAt'] == null)
        TextButton.icon(
          icon: const Icon(Icons.edit_outlined),
          label: const Text('매뉴얼 바로 수정'),
          onPressed: ops.readOnly
              ? null
              : () async {
                  final revision = ops.data?['revision'];
                  final manual = TextEditingController(text: step['manual']);
                  final video = TextEditingController(
                    text: step['videoUrl'] ?? '',
                  );
                  final photo = TextEditingController(
                    text: step['imageUrl'] ?? '',
                  );
                  final result = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text(step['title']),
                      content: SizedBox(
                        width: 480,
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TextField(
                                controller: manual,
                                minLines: 3,
                                maxLines: 8,
                                maxLength: 700,
                                decoration: const InputDecoration(
                                  labelText: '방법과 완료 기준',
                                ),
                              ),
                              TextField(
                                controller: video,
                                decoration: const InputDecoration(
                                  labelText: '영상 HTTPS 링크',
                                ),
                              ),
                              TextField(
                                controller: photo,
                                decoration: const InputDecoration(
                                  labelText: '사진 HTTPS 링크',
                                ),
                              ),
                              const Text(
                                '연결된 기본 레시피도 갱신해 다음 주문에 사용해요. 완료 기록은 유지돼요.',
                              ),
                            ],
                          ),
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('취소'),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('저장'),
                        ),
                      ],
                    ),
                  );
                  if (result == true) {
                    final ok = await ops.act('save_step_manual', {
                      'revision': revision,
                      'taskId': task['id'],
                      'stepId': step['id'],
                      'manual': manual.text.trim(),
                      'videoUrl': video.text.trim(),
                      'imageUrl': photo.text.trim(),
                    });
                    if (mounted) {
                      notice(
                        ok
                            ? '매뉴얼을 저장했어요. 다시 열면 새 내용이 보여요.'
                            : ops.error ?? '저장하지 못했어요.',
                      );
                    }
                  }
                  manual.dispose();
                  video.dispose();
                  photo.dispose();
                },
        ),
      for (final field in ['videoUrl', 'imageUrl'])
        if ((step[field] ?? '').toString().isNotEmpty)
          TextButton.icon(
            icon: Icon(
              field == 'videoUrl'
                  ? Icons.play_circle_outline
                  : Icons.image_outlined,
            ),
            label: Text(field == 'videoUrl' ? '영상 열기' : '사진 열기'),
            onPressed: () async {
              final uri = Uri.tryParse(step[field]);
              if (uri == null || uri.scheme != 'https') return;
              try {
                if (!await launchUrl(
                      uri,
                      mode: LaunchMode.externalApplication,
                    ) &&
                    mounted) {
                  notice('링크를 열지 못했어요.');
                }
              } catch (_) {
                if (mounted) notice('링크를 열지 못했어요.');
              }
            },
          ),
    ],
  );

  Widget _stock() {
    final stock = ops
        .rows('tasks')
        .where((t) => t['kind'] == 'stock' && t['completedAt'] == null);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final task in stock)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Surface(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task['title'],
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    '발주 후 재고 확인',
                    style: TextStyle(fontSize: 12, color: AppColors.muted),
                  ),
                  TextButton(
                    onPressed: ops.busy ? null : () => widget.onStock(task),
                    child: const Text('재고 수량 확인하기'),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _toggle(Json task, Json step) async {
    if (ops.busy) return;
    final currentTask = groups.where((t) => t['id'] == task['id']).firstOrNull;
    final currentStep = currentTask == null
        ? null
        : steps(currentTask).where((s) => s['id'] == step['id']).firstOrNull;
    if (currentTask == null ||
        currentStep == null ||
        currentStep['completedAt'] != step['completedAt']) {
      notice('업무가 변경됐어요. 현재 카드를 다시 확인해 주세요.');
      return;
    }
    task = currentTask;
    step = currentStep;
    final openingActor = ops.actorId;
    final checked = step['completedAt'] != null;
    if (!checked && task['canComplete'] != true) {
      notice('${role(task)} 담당 Tap이에요. 담당자나 사장님·매니저가 확인해요.');
      return;
    }
    if (checked) {
      if (!ops.isLeader && step['completedBy']?['id'] != ops.actor['id']) {
        notice('확인한 본인이나 사장님·매니저만 되돌릴 수 있어요.');
        return;
      }
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text('완료를 되돌릴까요?'),
          content: Text(step['title']),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(c, true),
              child: const Text('되돌리기'),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
      if (openingActor != ops.actorId || ops.busy) return;
    }
    if (ops.readOnly) {
      if (checked && step['preview'] != true) {
        notice('기존 확인 기록은 공개 미리보기에서 변경할 수 없어요.');
        return;
      }
      ops.previewToggleStep(task['id'], step['id']);
    } else {
      final success = await ops.act(checked ? 'reopen_step' : 'complete_step', {
        'taskId': task['id'],
        'stepId': step['id'],
      });
      if (mounted && !success) notice(ops.error ?? '변경하지 못했어요.');
    }
  }
}
