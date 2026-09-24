import 'package:flutter/material.dart';
import '../state/operations_controller.dart';
import 'components.dart';

/// A prepared portion is kitchen output; supplier stock keeps its own ledger.
class PreparedInventory extends StatelessWidget {
  const PreparedInventory({super.key, required this.ops});
  final OperationsController ops;

  Future<void> _save(BuildContext context, Json? item) async {
    final reports = (ops.data?['dashboard']?['reports'] as List? ?? [])
        .cast<Json>();
    final menus = (reports.firstOrNull?['menus'] as List? ?? []).cast<Json>();
    final name = TextEditingController(text: item?['name'] ?? '');
    final unit = TextEditingController(text: item?['unit'] ?? '인분');
    final minimum = TextEditingController(text: '${item?['minimum'] ?? 2}');
    final target = TextEditingController(text: '${item?['target'] ?? 10}');
    final batch = TextEditingController(
      text: '${item?['batchQuantity'] ?? 10}',
    );
    final instructions = TextEditingController(
      text: item?['instructions'] ?? '매장 절차에 따라 준비하고 실제 완성 수량을 세세요.',
    );
    final uses = {
      for (final menu in menus)
        menu['id'] as String: TextEditingController(
          text:
              '${(item?['menuUses'] as List? ?? []).cast<Json>().where((u) => u['menuId'] == menu['id']).firstOrNull?['quantity'] ?? ''}',
        ),
    };
    String folder =
        item?['folderId'] ??
        ops
            .rows('checklistFolders')
            .firstWhere(
              (f) => f['id'] == 'bone-preparation',
              orElse: () => ops.rows('checklistFolders').first,
            )['id'];
    String zone = item?['zone'] ?? ops.rows('zones').first['id'];
    final revision = ops.data?['revision'];
    final accepted = await showDialog<bool>(
      context: context,
      builder: (dialog) => StatefulBuilder(
        builder: (dialog, set) => AlertDialog(
          title: Text(item == null ? '준비품 추가' : '${item['name']} 설정'),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: name,
                    decoration: const InputDecoration(labelText: '준비품 이름'),
                  ),
                  TextField(
                    controller: unit,
                    decoration: const InputDecoration(
                      labelText: '단위 · 예: 인분, 개',
                    ),
                  ),
                  for (final (title, controller) in [
                    ('부족 기준', minimum),
                    ('목표 수량', target),
                    ('기본 준비량', batch),
                  ])
                    TextField(
                      controller: controller,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(labelText: title),
                    ),
                  DropdownButtonFormField<String>(
                    initialValue: folder,
                    decoration: const InputDecoration(labelText: '준비 BIG TAP'),
                    items: [
                      for (final f in ops.rows('checklistFolders'))
                        DropdownMenuItem(
                          value: f['id'] as String,
                          child: Text(f['name']),
                        ),
                    ],
                    onChanged: (v) => set(() => folder = v!),
                  ),
                  DropdownButtonFormField<String>(
                    initialValue: zone,
                    decoration: const InputDecoration(labelText: '준비 장소'),
                    items: [
                      for (final z in ops.rows('zones'))
                        DropdownMenuItem(
                          value: z['id'] as String,
                          child: Text(z['name']),
                        ),
                    ],
                    onChanged: (v) => set(() => zone = v!),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '메뉴 1개당 사용하는 준비품 수량',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  for (final menu in menus)
                    TextField(
                      controller: uses[menu['id']],
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: menu['name'],
                        hintText: '사용하지 않으면 비워 두세요',
                      ),
                    ),
                  TextField(
                    controller: instructions,
                    minLines: 2,
                    maxLines: 5,
                    maxLength: 700,
                    decoration: const InputDecoration(
                      labelText: '준비 방법 · 매장 기준',
                    ),
                  ),
                  const Text('예시 수량입니다. 실제 매장 기준으로 수정해 주세요.'),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialog, false),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialog, true),
              child: const Text('저장'),
            ),
          ],
        ),
      ),
    );
    if (accepted == true) {
      final ok = await ops.act('save_prepared_item', {
        'revision': revision,
        if (item != null) 'id': item['id'],
        'name': name.text.trim(),
        'unit': unit.text.trim(),
        'minimum': int.tryParse(minimum.text),
        'target': int.tryParse(target.text),
        'batchQuantity': int.tryParse(batch.text),
        'folderId': folder,
        'zone': zone,
        'instructions': instructions.text.trim(),
        'menuUses': [
          for (final menu in menus)
            if (uses[menu['id']]!.text.trim().isNotEmpty)
              {
                'menuId': menu['id'],
                'quantity': int.tryParse(uses[menu['id']]!.text.trim()),
              },
        ],
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ok ? '준비품 기준을 저장했어요.' : ops.error ?? '저장하지 못했어요.'),
          ),
        );
      }
    }
    name.dispose();
    unit.dispose();
    minimum.dispose();
    target.dispose();
    batch.dispose();
    instructions.dispose();
    for (final controller in uses.values) {
      controller.dispose();
    }
  }

  Future<void> _count(BuildContext context, Json item) async {
    final number = TextEditingController(text: '${item['onHand']}');
    final reason = TextEditingController();
    final revision = ops.data?['revision'];
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: Text('${item['name']} 실제 수량 확인'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: number,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: '현재 수량 · ${item['unit']}'),
            ),
            TextField(
              controller: reason,
              decoration: const InputDecoration(labelText: '보정 이유 · 예: 실사, 폐기'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialog, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialog, true),
            child: const Text('기록'),
          ),
        ],
      ),
    );
    if (saved == true) {
      final ok = await ops.act('count_prepared_item', {
        'revision': revision,
        'id': item['id'],
        'quantity': int.tryParse(number.text),
        'reason': reason.text.trim(),
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ok ? '실제 수량을 기록했어요.' : ops.error ?? '기록하지 못했어요.'),
          ),
        );
      }
    }
    number.dispose();
    reason.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = ops.rows('preparedItems');
    if (items.isEmpty && !ops.isLeader) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Surface(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    '사전 준비 수량',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                ),
                if (ops.isLeader && !ops.readOnly)
                  TextButton(
                    onPressed: () => _save(context, null),
                    child: const Text('준비품 추가'),
                  ),
              ],
            ),
            const Text('주문 조리 시작 때 메뉴별 사용량을 한 번 차감하고, 부족하면 준비 Tap이 생겨요.'),
            for (final item in items)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${item['name']} · ${item['onHand']}${item['unit']}  /  부족 기준 ${item['minimum']}${item['unit']}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    if ((item['onHand'] as num) < 0)
                      Text(
                        '준비분 부족 ${(item['onHand'] as num).abs()}${item['unit']}',
                        style: const TextStyle(color: AppColors.accent),
                      ),
                    if (ops.isLeader && !ops.readOnly)
                      Wrap(
                        spacing: 4,
                        children: [
                          TextButton(
                            onPressed: () => _save(context, item),
                            child: const Text('기준·메뉴 수정'),
                          ),
                          TextButton(
                            onPressed: () => _count(context, item),
                            child: const Text('실제 수량 보정'),
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
