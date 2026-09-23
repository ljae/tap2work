import 'package:flutter/material.dart';
import '../domain/tap_planning.dart';
import '../state/operations_controller.dart';
import 'checklist_board.dart';
import 'components.dart';

/// A new view over existing shared checklist data. It does not change the
/// server's completion model, so the original one-tap flow remains canonical.
class TapWorkspace extends StatefulWidget {
  const TapWorkspace({super.key, required this.ops, required this.onStock});
  final OperationsController ops;
  final Future<void> Function(Json) onStock;
  @override
  State<TapWorkspace> createState() => _TapWorkspaceState();
}

class _TapWorkspaceState extends State<TapWorkspace> {
  int view = 0;

  List<Json> get groups => widget.ops
      .rows('tasks')
      .where((task) => task['kind'] == 'routine')
      .toList();

  int total(Json task) => (task['steps'] as List? ?? []).length;
  int done(Json task) => (task['steps'] as List? ?? [])
      .where((step) => step['completedAt'] != null)
      .length;
  String status(Json task) => done(task) == total(task)
      ? '완료'
      : done(task) == 0
      ? '대기'
      : '진행';

  @override
  Widget build(BuildContext context) {
    final tasks = groups;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PageHeading(
          'TAP BOARD · TODAY',
          '오늘의 탭을 한눈에',
          '카드는 업무 묶음, 안의 작은 탭은 실제로 확인할 행동이에요.',
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final (index, label, icon) in [
              (0, '칸반 보드', Icons.view_kanban_outlined),
              (1, '5분 계획', Icons.calendar_view_day_outlined),
              (2, '작은 탭 확인', Icons.touch_app_outlined),
            ])
              ChoiceChip(
                label: Text(label),
                avatar: Icon(icon, size: 18),
                selected: view == index,
                onSelected: (_) => setState(() => view = index),
              ),
          ],
        ),
        const SizedBox(height: 18),
        if (view == 0) _board(tasks),
        if (view == 1) _timeline(tasks),
        if (view == 2) ChecklistBoard(ops: widget.ops, onStock: widget.onStock),
      ],
    );
  }

  Widget _board(List<Json> tasks) {
    final stock = widget.ops
        .rows('tasks')
        .where((task) => task['kind'] == 'stock' && task['completedAt'] == null)
        .toList();
    final lanes = [
      ('대기', const Color(0xFFE9E8DF), Icons.inbox_outlined),
      ('진행', const Color(0xFFFBE7D6), Icons.bolt_outlined),
      ('완료', const Color(0xFFE4EFB7), Icons.check_circle_outline),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (stock.isNotEmpty) ...[
          Surface(
            color: const Color(0xFFFFEFE4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '발주 후 재고 확인',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Text(
                  stock.map((task) => task['title']).join(' · '),
                  style: const TextStyle(fontSize: 12, color: AppColors.muted),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: widget.ops.busy
                      ? null
                      : () => widget.onStock(stock.first),
                  child: const Text('재고 수량 확인하기'),
                ),
                if (stock.length > 1)
                  TextButton(
                    onPressed: () => setState(() => view = 2),
                    child: Text('다른 재료까지 보기 · ${stock.length}건'),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],
        const Information(
          '상태는 작은 탭 확인 결과로 자동 정리돼요. 카드를 열어 내용을 본 뒤 실제로 끝낸 행동을 터치해 주세요.',
        ),
        const SizedBox(height: 15),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final lane in lanes)
                Container(
                  width: 270,
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: lane.$2,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(lane.$3, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              lane.$1,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Text(
                            '${tasks.where((t) => status(t) == lane.$1).length}',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      for (final task in tasks.where(
                        (t) => status(t) == lane.$1,
                      ))
                        _taskCard(task),
                      if (!tasks.any((t) => status(t) == lane.$1))
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Text(
                            '지금은 비어 있어요',
                            style: TextStyle(color: AppColors.muted),
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _taskCard(Json task) => Padding(
    padding: const EdgeInsets.only(bottom: 9),
    child: Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: () => _details(task),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${task['emoji'] ?? '✓'}  ${task['title']}',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${task['slot']} · ${task['requiredRole']} · 작은 탭 ${done(task)}/${total(task)}',
                style: const TextStyle(fontSize: 12, color: AppColors.muted),
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: total(task) == 0 ? 0 : done(task) / total(task),
                minHeight: 5,
                borderRadius: BorderRadius.circular(9),
                color: AppColors.green,
                backgroundColor: AppColors.paper,
              ),
            ],
          ),
        ),
      ),
    ),
  );

  void _details(Json task) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${task['emoji'] ?? '✓'} ${task['title']}',
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              Text('${task['slot']} · 작은 탭 ${done(task)}/${total(task)}'),
              const SizedBox(height: 12),
              for (final step in (task['steps'] as List? ?? []).take(5))
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Text(
                    '${step['completedAt'] == null ? '○' : '✓'} ${step['title']}',
                  ),
                ),
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  setState(() => view = 2);
                },
                icon: const Icon(Icons.touch_app_outlined),
                label: const Text('작은 탭 확인하러 가기'),
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
