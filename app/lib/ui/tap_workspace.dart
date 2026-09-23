import 'package:flutter/material.dart';
import '../domain/checklist_draft.dart';
import '../domain/tap_planning.dart';
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
  String query = '';
  bool timeline = false, mineOnly = false;
  final search = TextEditingController();
  final preview = <String, Json>{};
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

  String previewKey(Json task, Json step) =>
      '${ops.actorId}/${ops.data?['day']}/${task['id']}/${step['id']}';
  List<Json> steps(Json task) => [
    for (final step in rowsOf(task['steps']))
      {...step, ...?preview[previewKey(task, step)]},
  ];
  int total(Json task) => steps(task).length;
  int done(Json task) =>
      steps(task).where((s) => s['completedAt'] != null).length;
  String status(Json task) => total(task) > 0 && done(task) == total(task)
      ? '완료'
      : done(task) > 0
      ? '진행 중'
      : '할 일';
  List<Json> inFolder(String id) =>
      groups.where((t) => (t['folderId'] ?? 'general') == id).toList();
  List<Json> get folders {
    final result = ops.rows('checklistFolders').map((f) => {...f}).toList();
    for (final t in groups) {
      final id = t['folderId'] ?? 'general';
      if (!result.any((f) => f['id'] == id)) {
        result.add({'id': id, 'name': id == 'general' ? '기본 업무' : '기타 업무'});
      }
    }
    result.sort(
      (a, b) => inFolder(b['id']).length.compareTo(inFolder(a['id']).length),
    );
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
      timeline = false;
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
      final task = groups
          .where(
            (t) =>
                t['id'] == taskId && (t['folderId'] ?? 'general') == folderId,
          )
          .firstOrNull;
      final level = task != null
          ? 'SMALL TAP'
          : folder != null
          ? 'TAP'
          : 'BIG TAP';
      final scoped = (folder == null ? groups : inFolder(folder['id']))
          .where(visibleTask)
          .toList();
      final title = task?['title'] ?? folder?['name'] ?? '우리 매장 보드';
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
                : 'BIG TAP을 열면 업무가, Tap을 열면 작은 행동이 보여요.',
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
              ChoiceChip(
                label: const Text('보드'),
                selected: !timeline,
                onSelected: (_) => setState(() => timeline = false),
              ),
              ChoiceChip(
                label: const Text('5분 계획'),
                selected: timeline,
                onSelected: (_) => setState(() => timeline = true),
              ),
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
                  icon: const Icon(Icons.tune, size: 17),
                  label: const Text('보드 편집'),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (!timeline) ...[
            TextField(
              controller: search,
              onChanged: (v) => setState(() => query = v.trim().toLowerCase()),
              decoration: InputDecoration(
                hintText: '이 보드에서 검색',
                prefixIcon: const Icon(Icons.search, size: 20),
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
                        : '업무 모음'}',
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
          ] else
            _timeline(task == null ? scoped : [task]),
          if (folder == null && task == null) _stock(),
        ],
      );
    },
  );

  Widget _board(Json? folder, Json? task, List<Json> scoped) {
    final entries = <({String id, String state, Widget card})>[];
    bool matches(String name) => name.toLowerCase().contains(query);
    if (task != null) {
      for (final step in steps(task).where((s) => matches(s['title']))) {
        final checked = step['completedAt'] != null;
        entries.add((
          id: step['id'],
          state: checked ? '완료' : '할 일',
          card: TapCard(
            key: ValueKey('small-${step['id']}'),
            level: 'SMALL TAP',
            emoji: '✓',
            title: step['title'],
            subtitle: checked
                ? '${step['completedBy']?['name'] ?? ''} · ${stampOf(step['completedAt'])} 확인'
                : '반복 업무 · 방법 보기',
            onOpen: () => _manual(task['id'], step['id']),
            checked: checked,
            locked: task['canComplete'] != true,
            onCheck: () => _toggle(task, step),
          ),
        ));
      }
    } else if (folder != null) {
      for (final t in scoped.where((t) => matches(t['title']))) {
        entries.add((
          id: t['id'],
          state: status(t),
          card: TapCard(
            key: ValueKey('tap-${t['id']}'),
            level: 'TAP',
            emoji: t['emoji'] ?? '📋',
            title: t['title'],
            subtitle: '${t['slot']} · ${role(t)} · ${place(t)}',
            total: total(t),
            done: done(t),
            footer: 'Small Tap ${done(t)}/${total(t)}',
            onOpen: () => navigate(folder: folderId, task: t['id']),
          ),
        ));
      }
    } else {
      for (final f in folders.where((f) => matches(f['name']))) {
        final all = inFolder(f['id']);
        final list = all.where(visibleTask).toList();
        if (mineOnly && list.isEmpty) continue;
        final count = all.fold(0, (n, t) => n + total(t));
        final checked = all.fold(0, (n, t) => n + done(t));
        entries.add((
          id: f['id'],
          state: count > 0 && checked == count
              ? '완료'
              : checked > 0
              ? '진행 중'
              : '할 일',
          card: TapCard(
            key: ValueKey('big-${f['id']}'),
            level: 'BIG TAP',
            title: f['name'],
            subtitle: '${all.length}개의 Tap · 업무 모음',
            total: count,
            done: checked,
            footer: 'Small Tap $checked/$count',
            onOpen: () => navigate(folder: f['id']),
          ),
        ));
      }
    }
    final lanes = task == null ? ['할 일', '진행 중', '완료'] : ['할 일', '완료'];
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
                Container(
                  width: width,
                  margin: EdgeInsets.only(
                    right: index == lanes.length - 1 ? 0 : 12,
                  ),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEBEDF0),
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
                                    : lane == '진행 중'
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
                      for (final entry in entries.where((e) => e.state == lane))
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: entry.card,
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
            ],
          ),
        );
      },
    );
  }

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
      setState(() {
        final key = previewKey(task, step);
        if (checked) {
          preview.remove(key);
        } else {
          preview[key] = {
            'completedAt': DateTime.now().toUtc().toIso8601String(),
            'completedBy': {'id': ops.actor['id'], 'name': ops.actor['name']},
            'preview': true,
          };
        }
      });
      notice('체험 표시만 변경했어요. 저장되지 않아요.');
    } else {
      final success = await ops.act(checked ? 'reopen_step' : 'complete_step', {
        'taskId': task['id'],
        'stepId': step['id'],
      });
      if (mounted && !success) notice(ops.error ?? '변경하지 못했어요.');
    }
  }

  Future<void> _manual(String id, String stepId) async {
    final task = groups.where((t) => t['id'] == id).firstOrNull;
    final step = task == null
        ? null
        : steps(task).where((s) => s['id'] == stepId).firstOrNull;
    if (task == null || step == null) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (c) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'SMALL TAP · 방법',
                style: TextStyle(fontSize: 11, color: AppColors.muted),
              ),
              const SizedBox(height: 10),
              Text(
                step['title'],
                style: const TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${task['title']} · ${role(task)}',
                style: const TextStyle(fontSize: 12, color: AppColors.muted),
              ),
              const SizedBox(height: 24),
              Text(
                step['manual'] ?? '등록된 방법이 없어요.',
                style: const TextStyle(height: 1.8),
              ),
              if ((step['tip'] ?? '').toString().isNotEmpty) ...[
                const SizedBox(height: 16),
                Information('기억해 주세요 · ${step['tip']}'),
              ],
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () {
                  Navigator.pop(c);
                  _toggle(task, step);
                },
                icon: Icon(
                  step['completedAt'] == null ? Icons.check : Icons.undo,
                ),
                label: Text(
                  step['completedAt'] == null ? '이 Small Tap 완료' : '완료 되돌리기',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _timeline(List<Json> tasks) {
    final pending = tasks.where((t) => status(t) != '완료').toList();
    final blocks = planTaps(
      [
        for (final t in pending)
          PlannedTap(
            id: t['id'] as String,
            durationMinutes: 5 * (total(t) - done(t)).clamp(1, 120),
          ),
      ],
      startMinute: 9 * 60,
      shiftEndMinute: 18 * 60,
    );
    String clock(int minute) =>
        '${(minute ~/ 60).toString().padLeft(2, '0')}:${(minute % 60).toString().padLeft(2, '0')}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Information(
          '계획 예시 · 미완료 작은 탭당 5분, 09:00 시작으로 배치했어요. 실제 주문·담당자·근무표와 연결된 자동 배정 또는 근태 기록은 아직 아니에요.',
        ),
        const SizedBox(height: 14),
        if (blocks.isEmpty) const Information('남은 탭이 없어요.'),
        for (final block in blocks)
          Padding(
            padding: const EdgeInsets.only(bottom: 7),
            child: Surface(
              padding: const EdgeInsets.all(14),
              color: block.overtime ? const Color(0xFFFFE7DC) : AppColors.white,
              child: Row(
                children: [
                  SizedBox(
                    width: 106,
                    child: Text(
                      '${clock(block.startMinute)}\n${clock(block.endMinute)}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      pending.firstWhere((t) => t['id'] == block.id)['title']
                          as String,
                    ),
                  ),
                  if (block.overtime)
                    const Text(
                      '예시 연장',
                      style: TextStyle(fontSize: 11, color: Color(0xFF9A4B32)),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
