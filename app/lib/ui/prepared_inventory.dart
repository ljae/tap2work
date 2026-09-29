import 'package:flutter/material.dart';
import '../state/operations_controller.dart';
import 'components.dart';
import 'prepared_item_editor.dart';

/// A prepared portion is kitchen output; supplier stock keeps its own ledger.
class PreparedInventory extends StatelessWidget {
  const PreparedInventory({super.key, required this.ops});
  final OperationsController ops;

  Future<void> _save(BuildContext context, Json? item) async {
    await showAppFormSheet<bool>(
      context: context,
      builder: (_) => PreparedItemEditor(ops: ops, item: item),
    );
  }

  Future<void> _count(BuildContext context, Json item) async {
    await showAppFormSheet<bool>(
      context: context,
      builder: (_) => PreparedItemEditor(ops: ops, item: item, countOnly: true),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = ops.rows('preparedItems');
    if (items.isEmpty && !ops.isLeader) return const SizedBox.shrink();
    final low = items
        .where((item) => (item['onHand'] as num) <= (item['minimum'] as num))
        .length;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Surface(
        padding: EdgeInsets.zero,
        child: ExpansionTile(
          key: const Key('prepared-inventory-details'),
          tilePadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 3),
          childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
          shape: const Border(),
          collapsedShape: const Border(),
          title: const Text(
            '사전 준비 수량',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          subtitle: Text(
            '${items.length}종 준비품 · ${low == 0 ? '부족 없음' : '부족 기준 도달 $low종'}',
            style: const TextStyle(fontSize: 13, color: AppColors.muted),
          ),
          children: [
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('조리 시작 때 사용량을 차감하고, 부족하면 준비 Tap이 생겨요.'),
            ),
            if (ops.isLeader && !ops.readOnly)
              Align(
                alignment: Alignment.centerLeft,
                child: PressBounce(
                  child: TextButton.icon(
                    onPressed: () => _save(context, null),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('준비품 추가'),
                  ),
                ),
              ),
            for (final item in items)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${item['name']} · ${item['onHand']}${item['unit']}  /  부족 기준 ${item['minimum']}${item['unit']}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    if ((item['onHand'] as num) < 0)
                      Text(
                        '준비분 부족 ${(item['onHand'] as num).abs()}${item['unit']}',
                        style: const TextStyle(color: AppColors.accent),
                      ),
                    if (ops.isLeader && !ops.readOnly)
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          PressBounce(
                            child: TextButton(
                              onPressed: () => _save(context, item),
                              child: const Text('기준·메뉴 수정'),
                            ),
                          ),
                          PressBounce(
                            child: TextButton(
                              onPressed: () => _count(context, item),
                              child: const Text('실제 수량 보정'),
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
    );
  }
}
