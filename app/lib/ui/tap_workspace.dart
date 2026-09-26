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
import 'prepared_inventory.dart';

/// BIG TAP folders filter the TAP board; each TAP opens its Small TAPs.
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
  bool mineOnly = false;
  final previewStepOrder = <String, List<String>>{};
  List<String>? previewGroupOrder;
  OperationsController get ops => widget.ops;

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
  String platformBadge(String value) {
    if (value.contains('배달의민족') || value.contains('배민')) return '🩵 $value';
    if (value.contains('쿠팡이츠')) return '🧡 $value';
    if (value.contains('요기요')) return '❤️ $value';
    return '🛵 $value';
  }

  Color platformColor(String value) {
    if (value.contains('배달의민족') || value.contains('배민')) {
      return const Color(0xFF157B81);
    }
    if (value.contains('쿠팡이츠')) return const Color(0xFFA95015);
    if (value.contains('요기요')) return const Color(0xFFB33348);
    return AppColors.ink;
  }

  List<Json> assignees(Json task) {
    final required = task['requiredRole'];
    if (required == 'all') return [];
    final people = ops.rows('tappers').where((person) {
      if (person['active'] != true) return false;
      if (required == 'cook') {
        return (person['duties'] as List? ?? const []).any(
          (duty) => duty.toString().contains('조리'),
        );
      }
      return person['rank'] == required;
    }).toList();
    people.sort((a, b) => a['id'].toString().compareTo(b['id'].toString()));
    return people;
  }

  String assigneeLabel(Json task) {
    final people = assignees(task);
    if (task['requiredRole'] == 'all') return '누구나';
    return '${role(task)} · ${people.isEmpty ? '담당자 미지정' : '가능한 담당자'}';
  }

  Color personColor(String id) {
    var hash = 0;
    for (final unit in id.codeUnits) {
      hash = (hash * 31 + unit) & 0x7fffffff;
    }
    const palette = [
      Color(0xFF176B62),
      Color(0xFF8B5277),
      Color(0xFF3263A0),
      Color(0xFF9A5C22),
      Color(0xFF6A5B96),
    ];
    return palette[hash % palette.length];
  }

  Color assigneeColor(Json task) {
    final people = assignees(task);
    return people.isEmpty
        ? AppColors.muted
        : personColor(people.first['id'].toString());
  }

  Widget? assigneeBadges(Json task) {
    final people = assignees(task);
    if (people.isEmpty) return null;
    return Wrap(
      spacing: 10,
      runSpacing: 4,
      children: [
        for (final person in people)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: personColor(person['id'].toString()),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                person['nickname'].toString(),
                style: const TextStyle(fontSize: 12, color: AppColors.ink),
              ),
            ],
          ),
      ],
    );
  }

  String orderTime(Json task) {
    final created = task['orderCreatedAt'];
    if (created == null) return '';
    final date = DateTime.tryParse(created.toString());
    if (date == null) return '';
    final korean = date.toUtc().add(const Duration(hours: 9));
    final clock =
        '${korean.hour.toString().padLeft(2, '0')}:${korean.minute.toString().padLeft(2, '0')}';
    final queue = (ops.data?['dashboard']?['queue'] as List? ?? const [])
        .whereType<Json>();
    final ticket = queue
        .where((row) => row['id'] == task['orderId'])
        .firstOrNull;
    final members = groups
        .where((row) => row['orderId'] == task['orderId'])
        .toList();
    final completed =
        members.isNotEmpty &&
        members.every((row) => row['completedAt'] != null);
    final finishedAt = completed
        ? members
              .map((row) => DateTime.tryParse(row['completedAt'].toString()))
              .whereType<DateTime>()
              .fold<DateTime?>(
                null,
                (latest, value) =>
                    latest == null || value.isAfter(latest) ? value : latest,
              )
        : null;
    final elapsed =
        ((completed
                    ? finishedAt?.difference(date).inMinutes
                    : ticket?['elapsedMinutes'] as int?) ??
                DateTime.now().difference(date).inMinutes)
            .clamp(0, 999999);
    final target =
        ticket?['targetMinutes'] as int? ?? task['orderTargetMinutes'] as int?;
    final targetText = target == null
        ? ''
        : elapsed > target
        ? ' · 목표 $target분(가상) · ${elapsed - target}분 초과'
        : ' · 목표 $target분(가상) · ${target - elapsed}분 남음';
    return '${korean.month}/${korean.day} $clock 접수 · ${completed ? '완료까지 ' : ''}경과 $elapsed분$targetText';
  }

  void navigate({String? folder, String? task}) {
    FocusScope.of(context).unfocus();
    setState(() {
      folderId = folder;
      taskId = task;
      selectedStepId = null;
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
      final title = task?['title'] ?? 'TAP';
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (task != null)
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                TextButton.icon(
                  onPressed: () => navigate(folder: folderId),
                  icon: const Icon(Icons.dashboard_outlined, size: 17),
                  label: const Text('TAP 목록으로'),
                ),
                const Icon(
                  Icons.chevron_right,
                  size: 16,
                  color: AppColors.muted,
                ),
                Text(task['title']),
              ],
            ),
          if (task != null) const SizedBox(height: 8),
          PageHeading(
            level,
            title,
            task != null
                ? '${task['slot']} · ${role(task)} · ${place(task)}'
                : 'TAP을 선택하면 Small TAP과 방법을 볼 수 있어요. BIG TAP은 아래에서 업무를 묶어 보는 필터예요.',
          ),
          if (task != null &&
              (task['customer_memo'] ?? '').toString().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Information('요청사항 · ${task['customer_memo']}'),
            ),
          const SizedBox(height: 12),
          if (task == null)
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
          if (folder == null && task == null) PreparedInventory(ops: ops),
          ...[
            if (task == null) ...[_folderBar(), const SizedBox(height: 16)],
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: Text(
                    task != null
                        ? '이 TAP의 Small TAP · ${done(task)}/${total(task)} 완료'
                        : 'TAP · ${folder == null ? '전체 업무' : '${folder['name']} 그룹'}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
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
    final matched = scoped;
    final visibleOrderIds = matched
        .map((t) => t['orderId'])
        .whereType<String>()
        .toSet();
    final boardTasks = [
      ...matched.where((t) => t['orderId'] == null),
      ...groups.where((t) => visibleOrderIds.contains(t['orderId'])),
    ];
    for (final t in boardTasks) {
      entries.add((
        id: t['id'],
        state: t['orderId'] != null
            ? '주문처리중'
            : status(t) == '완료'
            ? '완료'
            : '할일',
        card: TapCard(
          key: ValueKey('tap-${t['id']}'),
          level: 'TAP',
          emoji: t['emoji'] ?? '📋',
          title: t['title'],
          subtitle:
              '${folders.where((f) => f['id'] == folderOf(t)).firstOrNull?['name'] ?? ''} · ${t['slot']} · ${assigneeLabel(t)}',
          accentColor: assigneeColor(t),
          assigneeBadges: assigneeBadges(t),
          dragHandle: _draggable(
            data: t['id'],
            feedback: Material(
              elevation: 8,
              child: SizedBox(width: 260, child: Text(t['title'])),
            ),
            child: const SizedBox(
              width: 32,
              height: 48,
              child: Icon(Icons.drag_indicator, color: AppColors.muted),
            ),
          ),
          total: total(t),
          done: done(t),
          onOpen: () => navigate(folder: folderId, task: t['id']),
          onCheck: t['preparedOutputMovementId'] != null
              ? null
              : () => t['preparedItemId'] != null && status(t) != '완료'
                    ? _finishPreparation(t)
                    : t['orderId'] != null
                    ? _checkMenu(t)
                    : _moveTap(
                        t,
                        folderOf(t),
                        status(t) == '완료' ? 'todo' : 'done',
                      ),
          checked: status(t) == '완료',
        ),
      ));
    }
    for (final orderId in visibleOrderIds) {
      final members = groups.where((t) => t['orderId'] == orderId).toList();
      final cards = entries
          .where((e) => members.any((t) => t['id'] == e.id))
          .toList();
      if (cards.isEmpty) continue;
      final first = members.first;
      final state = members.every((t) => status(t) == '완료') ? '완료' : '주문처리중';
      final count = members.fold<int>(0, (sum, t) => sum + total(t));
      final completed = members.fold<int>(0, (sum, t) => sum + done(t));
      final progress = count == 0 ? 0.0 : completed / count;
      final complete = count > 0 && completed == count;
      const groupText = AppColors.ink;
      final request = (first['customerRequest'] ?? '').toString();
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
            color: complete ? const Color(0xFFF0F2F4) : Colors.white,
            gradient: complete
                ? null
                : LinearGradient(
                    colors: [
                      assigneeColor(first).withValues(alpha: .18),
                      Colors.transparent,
                    ],
                    stops: [progress, progress],
                  ),
            border: Border.all(
              color: complete
                  ? AppColors.line
                  : completed > 0
                  ? assigneeColor(first)
                  : AppColors.line,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (count > 0)
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                  child: Row(
                    children: [
                      Text(
                        '$completed/$count',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: groupText,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 5,
                          color: complete
                              ? AppColors.muted
                              : assigneeColor(first),
                          backgroundColor: complete
                              ? Colors.white
                              : AppColors.paper,
                        ),
                      ),
                    ],
                  ),
                ),
              _draggable(
                data: first['id'],
                feedback: Material(child: Text('주문 ${first['orderNumber']}')),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '주문 ${first['orderNumber']} · ${first['orderChannel']} · ${members.length} 메뉴',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: groupText,
                              ),
                            ),
                          ),
                          if (request.isNotEmpty)
                            IconButton(
                              tooltip: '요청사항 보기',
                              icon: Icon(
                                CupertinoIcons.exclamationmark_bubble,
                                color: AppColors.accent,
                              ),
                              onPressed: () => showDialog<void>(
                                context: context,
                                builder: (_) => AlertDialog(
                                  title: const Text('주문 요청사항'),
                                  content: Text(request),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('확인'),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          PopupMenuButton<String>(
                            iconColor: groupText,
                            tooltip: '주문 그룹 이동',
                            onSelected: (value) =>
                                _moveTap(first, folderOf(first), value),
                            itemBuilder: (_) => [
                              if (complete)
                                const PopupMenuItem(
                                  value: 'todo',
                                  child: Text('전체 다시 열기'),
                                ),
                              if (!complete)
                                const PopupMenuItem(
                                  value: 'processing',
                                  child: Text('전체 조리 시작'),
                                ),
                              if (!complete)
                                const PopupMenuItem(
                                  value: 'done',
                                  child: Text('전체 완료'),
                                ),
                            ],
                          ),
                        ],
                      ),
                      Text(
                        orderTime(first),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.muted,
                        ),
                      ),
                      if (first['orderChannel'] == '배달' &&
                          (first['orderPlatform'] ?? '')
                              .toString()
                              .trim()
                              .isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Color.lerp(
                              platformColor(first['orderPlatform']),
                              Colors.white,
                              .88,
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            platformBadge(first['orderPlatform']),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: platformColor(first['orderPlatform']),
                            ),
                          ),
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
    const lanes = ['주문처리중', '할일', '완료'];
    String? targetStatus(Json moving, String lane) {
      final isOrder = moving['orderId'] != null;
      final complete = isOrder
          ? groups
                .where((t) => t['orderId'] == moving['orderId'])
                .every((t) => status(t) == '완료')
          : status(moving) == '완료';
      if (lane == '주문처리중' && !isOrder) return null;
      if (lane == '할일' && isOrder) return null;
      if (lane == '완료') return complete ? 'keep' : 'done';
      return complete ? 'todo' : 'keep';
    }

    Json? movingTask(String id) =>
        groups.where((t) => t['id'] == id).firstOrNull;
    bool canDrop(String id, String lane, {String? before}) {
      final moving = movingTask(id);
      if (moving == null || ops.busy || targetStatus(moving, lane) == null) {
        return false;
      }
      final target = before == null ? null : movingTask(before);
      return target == null ||
          (target['id'] != id &&
              (target['orderId'] == null ||
                  target['orderId'] != moving['orderId']));
    }

    void drop(String id, String lane, {String? before}) {
      final moving = movingTask(id);
      final next = moving == null ? null : targetStatus(moving, lane);
      if (moving == null || next == null) {
        notice('이 열에는 놓을 수 없어요.');
        return;
      }
      _moveTap(moving, folderOf(moving), next, beforeTaskId: before);
    }

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
                  key: ValueKey('lane-$lane'),
                  onWillAcceptWithDetails: (d) => canDrop(d.data, lane),
                  onAcceptWithDetails: (details) => drop(details.data, lane),
                  builder: (context, candidates, rejected) => Container(
                    width: width,
                    margin: EdgeInsets.only(
                      right: index == lanes.length - 1 ? 0 : 12,
                    ),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: candidates.isNotEmpty
                          ? const Color(0xFFFCE8E4)
                          : rejected.isNotEmpty
                          ? const Color(0xFFFBE8E8)
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
                                      ? AppColors.ink
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
                        if (rejected.isNotEmpty)
                          const Text(
                            '이 열에는 놓을 수 없어요',
                            style: TextStyle(
                              color: AppColors.accent,
                              fontSize: 11,
                            ),
                          ),
                        for (final entry in entries.where(
                          (e) => e.state == lane,
                        ))
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: DragTarget<String>(
                              onWillAcceptWithDetails: (details) =>
                                  canDrop(details.data, lane, before: entry.id),
                              onAcceptWithDetails: (details) =>
                                  drop(details.data, lane, before: entry.id),
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
                              '아직 카드가 없어요',
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
    if (task['preparedItemId'] != null &&
        targetStatus == 'done' &&
        task['completedAt'] == null) {
      await _finishPreparation(task);
      return;
    }
    if (task['preparedOutputMovementId'] != null && targetStatus != 'done') {
      notice('완성 수량이 반영된 Tap은 되돌릴 수 없어요. 실제 수량 보정을 사용해 주세요.');
      return;
    }
    final ownCompleted =
        task['completedAt'] != null &&
        task['completedBy']?['id'] == ops.actor['id'];
    if (!ops.isLeader && task['canComplete'] != true && !ownCompleted) {
      notice('담당 Tap만 이동할 수 있어요.');
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

  Future<int?> _preparedQuantity(Json task) async {
    final item = ops
        .rows('preparedItems')
        .where((row) => row['id'] == task['preparedItemId'])
        .firstOrNull;
    final controller = TextEditingController(
      text: '${task['plannedQuantity'] ?? 1}',
    );
    final result = await showDialog<int>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: Text('${item?['name'] ?? task['title']} 완성 수량'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('실제로 완성해 보관한 수량만 입력하세요.'),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: '완성 수량 · ${item?['unit'] ?? '개'}',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialog),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(dialog, int.tryParse(controller.text)),
            child: const Text('완료'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (result == null) return null;
    if (result < 1 || result > 100000) {
      notice('실제 완성 수량은 1~100,000으로 입력해 주세요.');
      return null;
    }
    return result;
  }

  Future<void> _finishPreparation(Json task) async {
    final quantity = await _preparedQuantity(task);
    if (quantity == null || !mounted) return;
    if (ops.readOnly) {
      ops.previewCompletePreparation(task['id'], quantity);
      return;
    }
    final ok = await ops.act('complete_preparation', {
      'taskId': task['id'],
      'quantity': quantity,
    });
    if (!ok && mounted) notice(ops.error ?? '준비 수량을 기록하지 못했어요.');
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

  Widget _folderBar() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'BIG TAP · 업무 그룹 필터',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.muted,
        ),
      ),
      const SizedBox(height: 8),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          spacing: 8,
          children: [
            ChoiceChip(
              label: const Text('전체 TAP'),
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
                      _moveTap(task, folder['id'], 'keep');
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
                label: const Text('그룹 관리'),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) =>
                        ChecklistEditor(ops: ops, initialFolder: folderId),
                  ),
                ),
              ),
          ],
        ),
      ),
    ],
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
    final all = steps(task);
    final selected =
        all.where((s) => s['id'] == selectedStepId).firstOrNull ??
        all.firstOrNull;
    Widget card(Json step, int index) => Padding(
      key: ValueKey('sort-small-${step['id']}'),
      padding: const EdgeInsets.only(bottom: 8),
      child: TapCard(
        key: ValueKey('small-${step['id']}'),
        level: 'SMALL TAP',
        emoji: '✓',
        title: step['title'],
        subtitle: step['completedAt'] == null
            ? '아직 확인 전'
            : '${step['completedBy']?['name'] ?? ''} · ${stampOf(step['completedAt'])} 확인',
        footer: '방법 보기',
        sequence: index + 1,
        selected: selected?['id'] == step['id'],
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
        locked:
            task['canComplete'] != true ||
            task['preparedOutputMovementId'] != null,
        onCheck: () {
          setState(() => selectedStepId = step['id']);
          _toggle(task, step);
        },
      ),
    );
    Widget list = ops.isLeader
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
            children: [
              for (final (index, step) in all.indexed) card(step, index),
            ],
          )
        : Column(
            children: [
              for (final (index, step) in all.indexed) card(step, index),
            ],
          );
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
      if ((step['tags'] as List? ?? []).isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Wrap(
            spacing: 6,
            children: [
              for (final tag in step['tags']) Chip(label: Text('#$tag')),
            ],
          ),
        ),
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
                  final source = TextEditingController(
                    text: step['sourceUrl'] ?? '',
                  );
                  final tags = TextEditingController(
                    text: (step['tags'] as List? ?? []).join(', '),
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
                              TextField(
                                controller: source,
                                decoration: const InputDecoration(
                                  labelText: '공식 사진 가이드 HTTPS 링크',
                                ),
                              ),
                              TextField(
                                controller: tags,
                                decoration: const InputDecoration(
                                  labelText: '#연관어 · 쉼표로 구분',
                                  helperText: '최대 20개, 각 30자 이내',
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
                      'sourceUrl': source.text.trim(),
                      'tags': tags.text
                          .split(',')
                          .map(
                            (tag) =>
                                tag.trim().replaceFirst(RegExp(r'^#+'), ''),
                          )
                          .where((tag) => tag.isNotEmpty)
                          .toList(),
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
                  source.dispose();
                  tags.dispose();
                },
        ),
      for (final field in ['videoUrl', 'imageUrl', 'sourceUrl'])
        if ((step[field] ?? '').toString().isNotEmpty)
          TextButton.icon(
            icon: Icon(
              field == 'videoUrl'
                  ? Icons.play_circle_outline
                  : Icons.image_outlined,
            ),
            label: Text(
              field == 'videoUrl'
                  ? '영상 열기'
                  : field == 'imageUrl'
                  ? '사진 열기'
                  : '공식 사진 가이드 열기',
            ),
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
    if (checked && task['preparedOutputMovementId'] != null) {
      notice('완성 수량이 반영된 Tap은 되돌릴 수 없어요. 실제 수량 보정을 사용해 주세요.');
      return;
    }
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
      if (!checked &&
          task['preparedItemId'] != null &&
          steps(task).where((s) => s['completedAt'] == null).length == 1) {
        final quantity = await _preparedQuantity(task);
        if (quantity != null) {
          ops.previewCompletePreparation(task['id'], quantity);
        }
      } else {
        ops.previewToggleStep(task['id'], step['id']);
      }
    } else {
      int? quantity;
      if (!checked &&
          task['preparedItemId'] != null &&
          steps(task).where((s) => s['completedAt'] == null).length == 1) {
        quantity = await _preparedQuantity(task);
        if (quantity == null || !mounted) return;
      }
      final success = await ops.act(checked ? 'reopen_step' : 'complete_step', {
        'taskId': task['id'],
        'stepId': step['id'],
        'quantity': ?quantity,
      });
      if (mounted && !success) notice(ops.error ?? '변경하지 못했어요.');
    }
  }
}
