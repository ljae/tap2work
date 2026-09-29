import 'package:flutter/material.dart';
import '../state/operations_controller.dart';
import 'components.dart';

/// Owns its draft and controllers until the sheet's exit transition completes.
class PreparedItemEditor extends StatefulWidget {
  const PreparedItemEditor({
    super.key,
    required this.ops,
    this.item,
    this.countOnly = false,
  });
  final OperationsController ops;
  final Json? item;
  final bool countOnly;
  @override
  State<PreparedItemEditor> createState() => _PreparedItemEditorState();
}

class _PreparedItemEditorState extends State<PreparedItemEditor> {
  final inputs = <String, TextEditingController>{};
  late final int revision;
  late final String actor;
  late final List<Json> folders, zones, menus;
  String? folder, zone, error;
  bool dirty = false, saving = false, leaving = false;
  OperationsController get ops => widget.ops;

  @override
  void initState() {
    super.initState();
    revision = ops.data?['revision'] ?? 0;
    actor = ops.actorId;
    folders = ops.rows('checklistFolders');
    zones = ops.rows('zones');
    final reports = (ops.data?['dashboard']?['reports'] as List? ?? [])
        .cast<Json>();
    final available = ops.rows('catalogMenus').isNotEmpty
        ? ops.rows('catalogMenus')
        : (reports.firstOrNull?['menus'] as List? ?? []).cast<Json>();
    menus = [
      for (final m in available) {...m},
    ];
    // A partial role projection must never silently remove existing menu links.
    for (final use in (widget.item?['menuUses'] as List? ?? []).cast<Json>()) {
      if (!menus.any((m) => m['id'] == use['menuId'])) {
        menus.add({'id': use['menuId'], 'name': '기존 연결 메뉴'});
      }
    }
    folder =
        widget.item?['folderId'] ??
        folders
            .where((f) => f['id'] == 'bone-preparation')
            .firstOrNull?['id'] ??
        folders.firstOrNull?['id'];
    zone = widget.item?['zone'] ?? zones.firstOrNull?['id'];
    final values = <String, dynamic>{
      'name': widget.item?['name'] ?? '',
      'unit': widget.item?['unit'] ?? '인분',
      'minimum': widget.item?['minimum'] ?? 2,
      'target': widget.item?['target'] ?? 10,
      'batchQuantity': widget.item?['batchQuantity'] ?? 10,
      'instructions':
          widget.item?['instructions'] ?? '매장 절차에 따라 준비하고 실제 완성 수량을 세세요.',
      'quantity': widget.item?['onHand'] ?? 0,
      'reason': '',
      for (final menu in menus)
        'menu:${menu['id']}':
            (widget.item?['menuUses'] as List? ?? [])
                .cast<Json>()
                .where((u) => u['menuId'] == menu['id'])
                .firstOrNull?['quantity'] ??
            '',
    };
    for (final entry in values.entries) {
      inputs[entry.key] = TextEditingController(text: '${entry.value}')
        ..addListener(() {
          if (!dirty && mounted) setState(() => dirty = true);
        });
    }
  }

  @override
  void dispose() {
    for (final input in inputs.values) {
      input.dispose();
    }
    super.dispose();
  }

  Future<void> close() async {
    if (saving) return;
    if (dirty) {
      final discard = await showAppDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text('변경을 버릴까요?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('계속 편집'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(c, true),
              child: const Text('변경 버리기'),
            ),
          ],
        ),
      );
      if (discard != true || !mounted) return;
    }
    setState(() => leaving = true);
    Navigator.pop(context);
  }

  String value(String key) => inputs[key]!.text.trim();
  Future<void> save() async {
    if (saving || ops.readOnly || !ops.isLeader) return;
    if (actor != ops.actorId) {
      setState(() => error = '계정이 변경되었어요. 화면을 다시 열어 주세요.');
      return;
    }
    setState(() {
      saving = true;
      error = null;
    });
    final ok = await ops.act(
      widget.countOnly ? 'count_prepared_item' : 'save_prepared_item',
      {
        'revision': revision,
        if (widget.item != null) 'id': widget.item!['id'],
        if (widget.countOnly) ...{
          'quantity': int.tryParse(value('quantity')),
          'reason': value('reason'),
        } else ...{
          'name': value('name'),
          'unit': value('unit'),
          for (final key in ['minimum', 'target', 'batchQuantity'])
            key: int.tryParse(value(key)),
          'folderId': folder,
          'zone': zone,
          'instructions': value('instructions'),
          'menuUses': [
            for (final menu in menus)
              if (value('menu:${menu['id']}').isNotEmpty)
                {
                  'menuId': menu['id'],
                  'quantity': int.tryParse(value('menu:${menu['id']}')),
                },
          ],
        },
      },
    );
    if (!mounted) return;
    if (ok) {
      setState(() {
        leaving = true;
        dirty = false;
      });
      Navigator.pop(context, true);
    } else {
      setState(() {
        saving = false;
        error = ops.error ?? '저장하지 못했어요.';
      });
    }
  }

  Widget field(
    String key,
    String label, {
    bool number = false,
    String? help,
    int lines = 1,
  }) => TextField(
    key: ValueKey('prepared-$key'),
    controller: inputs[key],
    keyboardType: number
        ? TextInputType.number
        : lines > 1
        ? TextInputType.multiline
        : TextInputType.text,
    textInputAction: lines > 1 ? TextInputAction.newline : TextInputAction.next,
    minLines: lines,
    maxLines: lines > 1 ? 5 : 1,
    maxLength: key == 'instructions' ? 700 : null,
    decoration: InputDecoration(
      labelText: label,
      helperText: help,
      helperMaxLines: 3,
    ),
  );

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: leaving || (!dirty && !saving),
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop) close();
    },
    child: AppEditorScaffold(
      title: widget.countOnly
          ? '${widget.item?['name']} 실제 수량 확인'
          : widget.item == null
          ? '준비품 추가'
          : '${widget.item!['name']} 설정',
      onClose: close,
      footer: AppSheetFooter(
        children: [
          if (error != null) Information(error!),
          if (ops.readOnly)
            const Text('공개 미리보기에서는 저장하지 않아요.', style: AppText.caption),
          FilledButton(
            onPressed:
                !saving &&
                    !ops.readOnly &&
                    ops.isLeader &&
                    (widget.countOnly || (folder != null && zone != null))
                ? save
                : null,
            child: Text(
              saving
                  ? '저장 중…'
                  : widget.countOnly
                  ? '실제 수량 기록'
                  : '준비품 저장',
            ),
          ),
        ],
      ),
      body: AbsorbPointer(
        absorbing: saving,
        child: ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          children: widget.countOnly
              ? [
                  AppFormSection(
                    title: '실제 수량',
                    children: [
                      field(
                        'quantity',
                        '현재 수량 · ${widget.item?['unit']}',
                        number: true,
                      ),
                      field('reason', '보정 이유', help: '예: 실사, 폐기'),
                    ],
                  ),
                ]
              : [
                  AppFormSection(
                    title: '기본 정보',
                    children: [
                      field('name', '준비품 이름'),
                      field('unit', '단위', help: '예: 인분, 개'),
                    ],
                  ),
                  AppFormSection(
                    title: '준비 수량 기준',
                    description: '실제 매장 기준으로 입력해 주세요.',
                    children: [
                      field(
                        'minimum',
                        '부족 기준',
                        number: true,
                        help: '이 수량 이하가 되면 준비가 필요해요.',
                      ),
                      field(
                        'target',
                        '목표 수량',
                        number: true,
                        help: '부족 기준보다 크게 설정해 주세요.',
                      ),
                      field(
                        'batchQuantity',
                        '기본 준비량',
                        number: true,
                        help: '한 번 준비할 때의 기본 수량이에요.',
                      ),
                    ],
                  ),
                  AppFormSection(
                    title: '업무 연결',
                    children: [
                      if (folders.isEmpty)
                        const Information('매뉴얼에서 폴더를 먼저 추가해 주세요.')
                      else
                        AppPicker<String>(
                          label: '준비 TAP그룹',
                          value: folder,
                          items: [
                            for (final f in folders)
                              DropdownMenuItem(
                                value: f['id'] as String,
                                child: Text(f['name']),
                              ),
                          ],
                          onChanged: (v) => setState(() {
                            folder = v;
                            dirty = true;
                          }),
                        ),
                      if (zones.isEmpty)
                        const Information('매장 배치도에 준비 장소를 먼저 추가해 주세요.')
                      else
                        AppPicker<String>(
                          label: '준비 장소',
                          value: zone,
                          items: [
                            for (final z in zones)
                              DropdownMenuItem(
                                value: z['id'] as String,
                                child: Text(z['name']),
                              ),
                          ],
                          onChanged: (v) => setState(() {
                            zone = v;
                            dirty = true;
                          }),
                        ),
                    ],
                  ),
                  AppFormSection(
                    title: '메뉴별 사용량',
                    description: '메뉴 1개당 쓰는 준비품 수량이에요. 사용하지 않는 메뉴는 비워 두세요.',
                    children: [
                      if (menus.isEmpty)
                        const Text('등록된 메뉴가 없어요.', style: AppText.caption),
                      for (final m in menus)
                        field('menu:${m['id']}', m['name'], number: true),
                    ],
                  ),
                  AppFormSection(
                    title: '준비 방법',
                    children: [field('instructions', '매장 기준', lines: 3)],
                  ),
                ],
        ),
      ),
    ),
  );
}
