import 'package:flutter/material.dart';
import '../state/operations_controller.dart';
import 'components.dart';

class CatalogEditor extends StatefulWidget {
  const CatalogEditor({super.key, required this.ops});
  final OperationsController ops;
  @override
  State<CatalogEditor> createState() => _CatalogEditorState();
}

class _CatalogEditorState extends State<CatalogEditor> {
  OperationsController get ops => widget.ops;

  Future<bool> save(String action, Json values, int revision) async {
    final ok = await ops.act(action, {...values, 'revision': revision});
    if (mounted && ok) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('저장했어요.')));
    }
    return ok;
  }

  Future<void> editFields(
    String title,
    List<({String key, String label, String value, bool number})> fields,
    String action,
    int revision,
    Json Function(Json) transform,
  ) async {
    final inputs = {
      for (final field in fields)
        field.key: TextEditingController(text: field.value),
    };
    String? localError;
    bool saving = false;
    try {
      await showDialog<void>(
        context: context,
        builder: (dialog) => StatefulBuilder(
          builder: (dialog, update) {
            Future<void> submit() async {
              update(() {
                saving = true;
                localError = null;
              });
              final raw = <String, dynamic>{
                for (final field in fields)
                  field.key: inputs[field.key]!.text.trim(),
              };
              try {
                final ok = await save(action, transform(raw), revision);
                if (ok && dialog.mounted) {
                  Navigator.pop(dialog);
                } else if (dialog.mounted) {
                  update(() => localError = ops.error ?? '저장하지 못했어요.');
                }
              } catch (_) {
                if (dialog.mounted) update(() => localError = '입력 값을 확인해 주세요.');
              } finally {
                if (dialog.mounted) update(() => saving = false);
              }
            }

            return AlertDialog(
              title: Text(title),
              content: SizedBox(
                width: 440,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final field in fields)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: field.key == 'zone'
                              ? DropdownButtonFormField<String>(
                                  initialValue: inputs['zone']!.text.isEmpty
                                      ? ''
                                      : inputs['zone']!.text,
                                  decoration: const InputDecoration(
                                    labelText: '보관 장소',
                                    border: OutlineInputBorder(),
                                  ),
                                  items: [
                                    const DropdownMenuItem(
                                      value: '',
                                      child: Text('미지정'),
                                    ),
                                    for (final zone in ops.rows('zones'))
                                      DropdownMenuItem(
                                        value: '${zone['id']}',
                                        child: Text('${zone['name']}'),
                                      ),
                                  ],
                                  onChanged: (value) =>
                                      inputs['zone']!.text = value ?? '',
                                )
                              : TextField(
                                  controller: inputs[field.key],
                                  keyboardType: field.number
                                      ? const TextInputType.numberWithOptions(
                                          decimal: true,
                                        )
                                      : TextInputType.text,
                                  decoration: InputDecoration(
                                    labelText: field.label,
                                    border: const OutlineInputBorder(),
                                  ),
                                ),
                        ),
                      if (localError != null) Information(localError!),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: saving ? null : () => Navigator.pop(dialog),
                  child: const Text('취소'),
                ),
                if (localError != null)
                  TextButton(
                    onPressed: saving
                        ? null
                        : () async {
                            await ops.refresh(force: true);
                            if (dialog.mounted) Navigator.pop(dialog);
                          },
                    child: const Text('최신 내용 보기'),
                  ),
                FilledButton(
                  onPressed: saving ? null : submit,
                  child: Text(saving ? '저장 중…' : '저장'),
                ),
              ],
            );
          },
        ),
      );
    } finally {
      for (final input in inputs.values) {
        input.dispose();
      }
    }
  }

  Future<void> editStore() async {
    final revision = ops.data?['revision'] as int?;
    if (revision == null) return;
    final store = ops.data?['store'] as Json? ?? {};
    await editFields(
      '매장 정보',
      [
        (
          key: 'name',
          label: '매장 이름',
          value: '${store['name'] ?? ''}',
          number: false,
        ),
        (
          key: 'note',
          label: '팀 안내 (선택)',
          value: '${store['note'] ?? ''}',
          number: false,
        ),
      ],
      'save_store',
      revision,
      (values) => values,
    );
  }

  Future<void> editMenu([Json? menu]) async {
    final revision = ops.data?['revision'] as int?;
    if (revision == null) return;
    await editFields(
      menu == null ? '메뉴 추가' : '메뉴 수정',
      [
        (
          key: 'name',
          label: '메뉴 이름',
          value: '${menu?['name'] ?? ''}',
          number: false,
        ),
        (
          key: 'category',
          label: '분류',
          value: '${menu?['category'] ?? ''}',
          number: false,
        ),
        (
          key: 'price',
          label: '가격 (원)',
          value: '${menu?['price'] ?? 0}',
          number: true,
        ),
      ],
      'save_menu',
      revision,
      (values) => {
        ...values,
        'price': int.tryParse('${values['price']}'),
        if (menu != null) 'id': menu['id'],
      },
    );
  }

  Future<void> editItem([Json? item]) async {
    final revision = ops.data?['revision'] as int?;
    if (revision == null) return;
    await editFields(
      item == null ? '재료 추가' : '재료 수정',
      [
        (
          key: 'name',
          label: '재료 이름',
          value: '${item?['name'] ?? ''}',
          number: false,
        ),
        (
          key: 'emoji',
          label: '표시 이모지',
          value: '${item?['emoji'] ?? '📦'}',
          number: false,
        ),
        (
          key: 'unit',
          label: '단위 (예: kg, 봉)',
          value: '${item?['unit'] ?? ''}',
          number: false,
        ),
        (
          key: 'supplier',
          label: '공급처',
          value: '${item?['supplier'] ?? ''}',
          number: false,
        ),
        (
          key: 'zone',
          label: '보관 장소',
          value: '${item?['zone'] ?? ''}',
          number: false,
        ),
        (
          key: 'minimum',
          label: '보충 기준 수량',
          value: '${item?['minimum'] ?? 0}',
          number: true,
        ),
        (
          key: 'orderQuantity',
          label: '기본 발주 수량',
          value: '${item?['orderQuantity'] ?? 1}',
          number: true,
        ),
        (
          key: 'price',
          label: '예상 단가 (원)',
          value: '${item?['price'] ?? 0}',
          number: true,
        ),
        (
          key: 'reviewDays',
          label: '발주 후 확인 일수 (1~90)',
          value: '${item?['reviewDays'] ?? 3}',
          number: true,
        ),
      ],
      'save_inventory_item',
      revision,
      (values) => {
        ...values,
        'minimum': double.tryParse('${values['minimum']}'),
        'orderQuantity': double.tryParse('${values['orderQuantity']}'),
        'price': int.tryParse('${values['price']}'),
        'reviewDays': int.tryParse('${values['reviewDays']}'),
        if (item != null) 'id': item['id'],
      },
    );
  }

  Future<void> archive(String action, Json row, String label) async {
    final revision = ops.data?['revision'] as int?;
    if (revision == null) return;
    final yes = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: Text('$label 보관'),
        content: Text('${row['name']}을 목록에서 숨길까요? 이전 기록은 유지됩니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialog, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialog, true),
            child: const Text('보관'),
          ),
        ],
      ),
    );
    if (yes == true) await save(action, {'id': row['id']}, revision);
  }

  Future<void> startBlank() async {
    final revision = ops.data?['revision'] as int?;
    if (revision == null) return;
    final yes = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: const Text('빈 매장으로 시작'),
        content: const Text(
          '현재 샘플 주문·직원·재고·업무를 화면에서 숨기고 서버에 보관합니다. 지금까지 샘플 매장에서 수정한 내용도 함께 보관됩니다.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialog, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialog, true),
            child: const Text('보관하고 시작'),
          ),
        ],
      ),
    );
    if (yes == true) await save('start_blank_from_sample', {}, revision);
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: ops,
    builder: (context, _) {
      final menus = ops
          .rows('catalogMenus')
          .where((row) => row['archivedAt'] == null)
          .toList();
      final items = ops.rows('items');
      return Scaffold(
        appBar: AppBar(title: const Text('매장 설정')),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(18),
            children: [
              if (ops.cloud)
                const Information(
                  '이 계정의 매장에 저장됩니다. 동료가 먼저 수정한 경우 최신 내용을 확인한 뒤 다시 입력해 주세요.',
                ),
              if (ops.cloud &&
                  ops.isOwner &&
                  ops.data?['salesSource'] == 'sample' &&
                  ops.data?['hasSampleArchive'] != true) ...[
                const SizedBox(height: 12),
                Surface(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '샘플 매장 사용 중',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const Text(
                        '실제 매장 기록을 시작할 준비가 되었다면 샘플을 보관하고 빈 매장으로 전환하세요.',
                      ),
                      TextButton(
                        onPressed: ops.busy ? null : startBlank,
                        child: const Text('샘플 보관하고 빈 매장 시작'),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 14),
              Surface(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '매장 정보',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('${ops.data?['store']?['name'] ?? ''}'),
                    if ('${ops.data?['store']?['note'] ?? ''}'.isNotEmpty)
                      Text('${ops.data?['store']?['note']}'),
                    if (ops.isOwner)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: ops.busy ? null : editStore,
                          child: const Text('매장 정보 수정'),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      '메뉴',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (ops.isLeader)
                    FilledButton.tonal(
                      onPressed: ops.busy ? null : () => editMenu(),
                      child: const Text('메뉴 추가'),
                    ),
                ],
              ),
              if (menus.isEmpty)
                const Information('등록된 메뉴가 없어요. 실제 판매 메뉴를 추가해 주세요.'),
              for (final menu in menus)
                Card(
                  child: ListTile(
                    title: Text('${menu['name']}'),
                    subtitle: Text('${menu['category']} · ${menu['price']}원'),
                    trailing: ops.isLeader
                        ? PopupMenuButton<String>(
                            enabled: !ops.busy,
                            onSelected: (value) => value == 'edit'
                                ? editMenu(menu)
                                : archive('archive_menu', menu, '메뉴'),
                            itemBuilder: (_) => const [
                              PopupMenuItem(value: 'edit', child: Text('수정')),
                              PopupMenuItem(
                                value: 'archive',
                                child: Text('보관'),
                              ),
                            ],
                          )
                        : null,
                  ),
                ),
              const SizedBox(height: 20),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      '재료',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (ops.isLeader)
                    FilledButton.tonal(
                      onPressed: ops.busy ? null : () => editItem(),
                      child: const Text('재료 추가'),
                    ),
                ],
              ),
              const Text(
                '실제 수량은 재고 화면의 수량 확인에서 따로 기록합니다.',
                style: TextStyle(color: AppColors.muted),
              ),
              if (items.isEmpty)
                const Information('등록된 재료가 없어요. 재료를 추가한 뒤 실물 수량을 확인해 주세요.'),
              for (final item in items)
                Card(
                  child: ListTile(
                    title: Text('${item['emoji']} ${item['name']}'),
                    subtitle: Text(
                      '${item['supplier']} · ${item['unit']} · 기준 ${item['minimum']}',
                    ),
                    trailing: ops.isLeader
                        ? PopupMenuButton<String>(
                            enabled: !ops.busy,
                            onSelected: (value) => value == 'edit'
                                ? editItem(item)
                                : archive('archive_inventory_item', item, '재료'),
                            itemBuilder: (_) => const [
                              PopupMenuItem(value: 'edit', child: Text('수정')),
                              PopupMenuItem(
                                value: 'archive',
                                child: Text('보관'),
                              ),
                            ],
                          )
                        : null,
                  ),
                ),
            ],
          ),
        ),
      );
    },
  );
}
