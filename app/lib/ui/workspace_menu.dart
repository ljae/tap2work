import 'dart:math';
import 'package:flutter/material.dart';
import '../state/operations_controller.dart';
import 'components.dart';

/// Global store scope, immediately before the account menu.
class WorkspaceMenu extends StatelessWidget {
  const WorkspaceMenu({super.key, required this.ops});
  final OperationsController ops;

  @override
  Widget build(BuildContext context) {
    final selected = ops.workspaces
        .where((w) => w['id'] == ops.workspaceId)
        .firstOrNull;
    final name =
        '${ops.data?['store']?['name'] ?? selected?['name'] ?? '매장 선택'}';
    return PopupMenuButton<String>(
      key: const ValueKey('header-workspace-menu'),
      enabled: !ops.busy,
      tooltip: '$name · 매장 선택',
      popUpAnimationStyle: AppMotion.dialogStyle(context),
      onSelected: (id) {
        if (id == 'add') {
          showAppFormSheet<void>(
            context: context,
            builder: (_) => _CreateWorkspace(ops: ops),
          );
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
        const PopupMenuItem<String>(value: 'add', child: Text('+ 새 매장 추가')),
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

class _CreateWorkspace extends StatefulWidget {
  const _CreateWorkspace({required this.ops});
  final OperationsController ops;
  @override
  State<_CreateWorkspace> createState() => _CreateWorkspaceState();
}

class _CreateWorkspaceState extends State<_CreateWorkspace> {
  final name = TextEditingController();
  // Keep the same identity on retry after a lost response: one store per intent.
  late final requestId = _requestId();
  bool saving = false;
  String? error;
  static String _requestId() {
    final random = Random.secure();
    final bytes = List.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 15) | 64;
    bytes[8] = (bytes[8] & 63) | 128;
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
  }

  @override
  void dispose() {
    name.dispose();
    super.dispose();
  }

  Future<void> create() async {
    if (saving) return;
    if (name.text.trim().isEmpty) {
      setState(() => error = '매장 이름을 입력해 주세요.');
      return;
    }
    setState(() {
      saving = true;
      error = null;
    });
    final ok = await widget.ops.act('create_workspace', {
      'mode': 'blank',
      'name': name.text.trim(),
      'requestId': requestId,
      'revision': 0,
    });
    if (!mounted) return;
    if (ok) {
      Navigator.pop(context);
      return;
    }
    setState(() {
      saving = false;
      error = widget.ops.error ?? '매장을 추가하지 못했어요.';
    });
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !saving,
    child: AppSheetPanel(
      title: const Text('새 매장 추가'),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('새 매장의 사장님으로 시작해요. 업무·매뉴얼·근무표와 크루는 매장별로 관리해요.'),
          const SizedBox(height: 24),
          TextField(
            key: const ValueKey('new-workspace-name'),
            controller: name,
            enabled: !saving,
            maxLength: 80,
            autofocus: true,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => create(),
            decoration: const InputDecoration(
              labelText: '매장 이름',
              hintText: '예: 강남점',
            ),
          ),
          if (error != null) Information(error!),
        ],
      ),
      actions: [
        TextButton(
          onPressed: saving ? null : () => Navigator.pop(context),
          child: const Text('취소'),
        ),
        FilledButton(
          onPressed: saving ? null : create,
          child: Text(saving ? '추가 중…' : '매장 추가'),
        ),
      ],
    ),
  );
}
