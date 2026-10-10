import 'store_setup_screen.dart';
import 'package:flutter/material.dart';
import '../state/operations_controller.dart';
import 'components.dart';
import '../l10n/app_localizations.dart';
import 'shared_welcome_screen.dart';

/// Global store scope, immediately before the account menu.
class WorkspaceMenu extends StatelessWidget {
  const WorkspaceMenu({super.key, required this.ops, this.onWelcome});
  final OperationsController ops;
  final VoidCallback? onWelcome;

  @override
  Widget build(BuildContext context) {
    final selected = ops.workspaces
        .where((w) => w['id'] == ops.workspaceId)
        .firstOrNull;
    final name =
        '${ops.data?['store']?['name'] ?? selected?['name'] ?? context.t('store.select')}';
    return PopupMenuButton<String>(
      key: const ValueKey('header-workspace-menu'),
      enabled: !ops.busy,
      tooltip: context.t('store.selectNamed', args: {'name': name}),
      popUpAnimationStyle: AppMotion.dialogStyle(context),
      onSelected: (id) {
        if (id == 'welcome') {
          if (onWelcome != null) {
            onWelcome!();
          } else {
            openSharedWelcome(context, ops);
          }
        } else if (id == 'add') {
          openStoreSetup(context, ops);
        } else {
          ops.selectWorkspace(id);
        }
      },
      itemBuilder: (_) => [
        for (final store in ops.workspaces)
          PopupMenuItem<String>(
            value: store['id'] as String,
            child: Row(
              children: [
                Icon(
                  store['id'] == ops.workspaceId
                      ? Icons.check
                      : Icons.storefront_outlined,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${store['name']}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        const PopupMenuDivider(),
        PopupMenuItem<String>(
          value: 'welcome',
          child: Text(context.t('welcome.reopen')),
        ),
        PopupMenuItem<String>(
          value: 'add',
          child: Text(context.t('store.add')),
        ),
      ],
      child: Container(
        width: (MediaQuery.sizeOf(context).width - 180).clamp(100.0, 200.0),
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.line),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.body,
              ),
            ),
            const Icon(Icons.keyboard_arrow_down, size: 20),
          ],
        ),
      ),
    );
  }
}
