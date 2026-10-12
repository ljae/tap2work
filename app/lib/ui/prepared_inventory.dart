import '../l10n/app_localizations.dart';
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
          title: Text(
            context.t('ui.audit323'),
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          subtitle: Text(
            context.t(
              'ui.audit870',
              args: {
                'p0': items.length,
                'p1': low == 0
                    ? context.t('ui.audit1161')
                    : context.t('ui.audit1162', args: {'p0': low}),
              },
            ),
            style: const TextStyle(fontSize: 13, color: AppColors.muted),
          ),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(context.t('ui.audit871')),
            ),
            if (ops.isLeader && !ops.readOnly)
              Align(
                alignment: Alignment.centerLeft,
                child: PressBounce(
                  child: TextButton.icon(
                    onPressed: () => _save(context, null),
                    icon: const Icon(Icons.add, size: 18),
                    label: Text(context.t('ui.audit324')),
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
                      context.t(
                        'ui.audit872',
                        args: {
                          'p0': item['name'],
                          'p1': item['onHand'],
                          'p2': item['unit'],
                          'p3': item['minimum'],
                          'p4': item['unit'],
                        },
                      ),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    if ((item['onHand'] as num) < 0)
                      Text(
                        context.t(
                          'ui.audit873',
                          args: {
                            'p0': (item['onHand'] as num).abs(),
                            'p1': item['unit'],
                          },
                        ),
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
                              child: Text(context.t('ui.audit325')),
                            ),
                          ),
                          PressBounce(
                            child: TextButton(
                              onPressed: () => _count(context, item),
                              child: Text(context.t('ui.audit326')),
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
