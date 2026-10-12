import '../l10n/app_localizations.dart';
import 'place_guide.dart';
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
          title: Text(context.t('ui.audit178')),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: Text(context.t('ui.audit21')),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(c, true),
              child: Text(context.t('ui.audit22')),
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
      setState(() => error = context.t('ui.audit1261'));
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
        error = ops.error ?? context.t('ui.audit760');
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
          ? context.t('ui.audit811', args: {'p0': widget.item?['name']})
          : widget.item == null
          ? context.t('ui.audit324')
          : context.t('ui.audit812', args: {'p0': widget.item!['name']}),
      onClose: close,
      footer: AppSheetFooter(
        children: [
          if (error != null) Information(context.t(error!)),
          if (ops.readOnly)
            Text(context.t('ui.audit8'), style: AppText.caption),
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
                  ? context.t('ui.audit532')
                  : widget.countOnly
                  ? context.t('ui.audit813')
                  : context.t('ui.audit814'),
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
                    title: context.t('ui.audit815'),
                    children: [
                      field(
                        'quantity',
                        context.t(
                          'ui.audit1150',
                          args: {'p0': widget.item?['unit']},
                        ),
                        number: true,
                      ),
                      field(
                        'reason',
                        context.t('ui.audit1151'),
                        help: context.t('ui.audit1536'),
                      ),
                    ],
                  ),
                ]
              : [
                  AppFormSection(
                    title: context.t('ui.audit816'),
                    children: [
                      field('name', context.t('ui.audit1152')),
                      field(
                        'unit',
                        context.t('ui.audit1153'),
                        help: context.t('ui.audit1537'),
                      ),
                    ],
                  ),
                  AppFormSection(
                    title: context.t('ui.audit817'),
                    description: context.t('ui.audit818'),
                    children: [
                      field(
                        'minimum',
                        context.t('ui.audit1154'),
                        number: true,
                        help: context.t('ui.audit1538'),
                      ),
                      field(
                        'target',
                        context.t('ui.audit1155'),
                        number: true,
                        help: context.t('ui.audit1539'),
                      ),
                      field(
                        'batchQuantity',
                        context.t('ui.audit1156'),
                        number: true,
                        help: context.t('ui.audit1540'),
                      ),
                    ],
                  ),
                  AppFormSection(
                    title: context.t('ui.audit819'),
                    children: [
                      if (folders.isEmpty)
                        Information(context.t('ui.audit272'))
                      else
                        AppPicker<String>(
                          label: context.t('ui.audit820'),
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
                        TextButton.icon(
                          onPressed: () => editPlace(context, widget.ops),
                          icon: const Icon(Icons.add_location_alt_outlined),
                          label: Text(context.t('ui.audit273')),
                        )
                      else
                        AppPicker<String>(
                          label: context.t('ui.audit821'),
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
                    title: context.t('ui.audit822'),
                    description: context.t('ui.audit823'),
                    children: [
                      if (menus.isEmpty)
                        Text(context.t('ui.audit274'), style: AppText.caption),
                      for (final m in menus)
                        field('menu:${m['id']}', m['name'], number: true),
                    ],
                  ),
                  AppFormSection(
                    title: context.t('ui.audit824'),
                    children: [
                      field(
                        'instructions',
                        context.t('ui.audit1157'),
                        lines: 3,
                      ),
                    ],
                  ),
                ],
        ),
      ),
    ),
  );
}
