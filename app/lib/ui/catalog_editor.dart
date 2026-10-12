import '../l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import '../state/operations_controller.dart';
import 'components.dart';
import 'store_profile_screen.dart';

class CatalogEditor extends StatefulWidget {
  const CatalogEditor({super.key, required this.ops, this.menusOnly = false});
  final OperationsController ops;
  final bool menusOnly;
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
      ).showSnackBar(SnackBar(content: Text(context.t('ui.audit786'))));
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
      await showAppFormSheet<void>(
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
                  update(
                    () => localError = ops.error ?? context.t('ui.audit760'),
                  );
                }
              } catch (_) {
                if (dialog.mounted) {
                  update(() => localError = context.t('ui.audit1541'));
                }
              } finally {
                if (dialog.mounted) update(() => saving = false);
              }
            }

            return AppSheetPanel(
              title: Text(title),
              content: SizedBox(
                width: 440,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final field in fields)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 20),
                          child: field.key == 'zone'
                              ? AppPillField<String>(
                                  initialValue: inputs['zone']!.text.isEmpty
                                      ? ''
                                      : inputs['zone']!.text,
                                  decoration: InputDecoration(
                                    labelText: context.t('ui.audit298'),
                                    border: OutlineInputBorder(),
                                  ),
                                  items: [
                                    DropdownMenuItem(
                                      value: '',
                                      child: Text(context.t('ui.audit852')),
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
                PressBounce(
                  child: TextButton(
                    onPressed: saving ? null : () => Navigator.pop(dialog),
                    child: Text(context.t('ui.audit33')),
                  ),
                ),
                if (localError != null)
                  PressBounce(
                    child: TextButton(
                      onPressed: saving
                          ? null
                          : () async {
                              await ops.refresh(force: true);
                              if (dialog.mounted) Navigator.pop(dialog);
                            },
                      child: Text(context.t('ui.audit299')),
                    ),
                  ),
                PressBounce(
                  child: FilledButton(
                    onPressed: saving ? null : submit,
                    child: Text(
                      saving
                          ? context.t('ui.audit532')
                          : context.t('ui.audit51'),
                    ),
                  ),
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
    await showAppSheet(context, builder: (_) => StoreProfileScreen(ops: ops));
  }

  Future<void> editMenu([Json? menu]) async {
    final revision = ops.data?['revision'] as int?;
    if (revision == null) return;
    await editFields(
      menu == null ? context.t('ui.audit310') : context.t('ui.audit1382'),
      [
        (
          key: 'name',
          label: context.t('ui.audit1542'),
          value: '${menu?['name'] ?? ''}',
          number: false,
        ),
        (
          key: 'category',
          label: context.t('ui.audit1543'),
          value: '${menu?['category'] ?? ''}',
          number: false,
        ),
        (
          key: 'price',
          label: context.t('ui.audit1544'),
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
      item == null ? context.t('ui.audit312') : context.t('ui.audit1383'),
      [
        (
          key: 'name',
          label: context.t('ui.audit1545'),
          value: '${item?['name'] ?? ''}',
          number: false,
        ),
        (
          key: 'emoji',
          label: context.t('ui.audit1546'),
          value: '${item?['emoji'] ?? '📦'}',
          number: false,
        ),
        (
          key: 'unit',
          label: context.t('ui.audit1547'),
          value: '${item?['unit'] ?? ''}',
          number: false,
        ),
        (
          key: 'supplier',
          label: context.t('ui.audit1548'),
          value: '${item?['supplier'] ?? ''}',
          number: false,
        ),
        (
          key: 'zone',
          label: context.t('ui.audit298'),
          value: '${item?['zone'] ?? ''}',
          number: false,
        ),
        (
          key: 'minimum',
          label: context.t('ui.audit1549'),
          value: '${item?['minimum'] ?? 0}',
          number: true,
        ),
        (
          key: 'orderQuantity',
          label: context.t('ui.audit1550'),
          value: '${item?['orderQuantity'] ?? 1}',
          number: true,
        ),
        (
          key: 'price',
          label: context.t('ui.audit1551'),
          value: '${item?['price'] ?? 0}',
          number: true,
        ),
        (
          key: 'reviewDays',
          label: context.t('ui.audit1552'),
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
    final yes = await showAppDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: Text(context.t('ui.audit853', args: {'p0': label})),
        content: Text(context.t('ui.audit854', args: {'p0': row['name']})),
        actions: [
          PressBounce(
            child: TextButton(
              onPressed: () => Navigator.pop(dialog, false),
              child: Text(context.t('ui.audit33')),
            ),
          ),
          PressBounce(
            child: FilledButton(
              onPressed: () => Navigator.pop(dialog, true),
              child: Text(context.t('ui.audit158')),
            ),
          ),
        ],
      ),
    );
    if (yes == true) await save(action, {'id': row['id']}, revision);
  }

  Future<void> startBlank() async {
    final revision = ops.data?['revision'] as int?;
    if (revision == null) return;
    final yes = await showAppDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: Text(context.t('ui.audit300')),
        content: Text(context.t('ui.audit301')),
        actions: [
          PressBounce(
            child: TextButton(
              onPressed: () => Navigator.pop(dialog, false),
              child: Text(context.t('ui.audit33')),
            ),
          ),
          PressBounce(
            child: FilledButton(
              onPressed: () => Navigator.pop(dialog, true),
              child: Text(context.t('ui.audit302')),
            ),
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
      return AppEditorScaffold(
        title: widget.menusOnly
            ? context.t('ui.audit855')
            : context.t('ui.audit805'),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              if (!widget.menusOnly) ...[
                if (ops.cloud) Information(context.t('ui.audit303')),
                if (ops.cloud &&
                    ops.isOwner &&
                    ops.data?['salesSource'] == 'sample' &&
                    ops.data?['hasSampleArchive'] != true) ...[
                  const SizedBox(height: 12),
                  Surface(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.t('ui.audit304'),
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(context.t('ui.audit305')),
                        PressBounce(
                          child: TextButton(
                            onPressed: ops.busy ? null : startBlank,
                            child: Text(context.t('ui.audit306')),
                          ),
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
                      Text(
                        context.t('ui.audit307'),
                        style: TextStyle(
                          fontSize: 16,
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
                          child: PressBounce(
                            child: TextButton(
                              onPressed: ops.busy ? null : editStore,
                              child: Text(context.t('ui.audit308')),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
              if (menus.any((m) => m['setupNeedsReview'] == true) ||
                  items.any((i) => i['setupNeedsReview'] == true))
                Information(context.t('ui.audit309')),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      context.t('ui.audit856'),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (ops.isLeader)
                    FilledButton.tonal(
                      onPressed: ops.busy ? null : () => editMenu(),
                      child: Text(context.t('ui.audit310')),
                    ),
                ],
              ),
              if (menus.isEmpty) Information(context.t('ui.audit311')),
              for (final menu in menus)
                AppCard(
                  child: ListTile(
                    title: Text('${menu['name']}'),
                    subtitle: Text(
                      menu['setupNeedsReview'] == true
                          ? context.t(
                              'ui.audit857',
                              args: {'p0': menu['category']},
                            )
                          : context.t(
                              'ui.audit858',
                              args: {
                                'p0': menu['category'],
                                'p1': menu['price'],
                              },
                            ),
                    ),
                    trailing: ops.isLeader
                        ? PopupMenuButton<String>(
                            popUpAnimationStyle: AppMotion.dialogStyle(context),
                            enabled: !ops.busy,
                            onSelected: (value) => value == 'edit'
                                ? editMenu(menu)
                                : archive('archive_menu', menu, '메뉴'),
                            itemBuilder: (_) => [
                              PopupMenuItem(
                                value: 'edit',
                                child: Text(context.t('ui.audit155')),
                              ),
                              PopupMenuItem(
                                value: 'archive',
                                child: Text(context.t('ui.audit158')),
                              ),
                            ],
                          )
                        : null,
                  ),
                ),
              if (!widget.menusOnly) ...[
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        context.t('ui.audit859'),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (ops.isLeader)
                      FilledButton.tonal(
                        onPressed: ops.busy ? null : () => editItem(),
                        child: Text(context.t('ui.audit312')),
                      ),
                  ],
                ),
                Text(
                  context.t('ui.audit313'),
                  style: TextStyle(color: AppColors.muted),
                ),
                if (items.isEmpty) Information(context.t('ui.audit314')),
                for (final item in items)
                  AppCard(
                    child: ListTile(
                      title: Text('${item['emoji']} ${item['name']}'),
                      subtitle: Text(
                        context.t(
                          'ui.audit860',
                          args: {
                            'p0': item['supplier'],
                            'p1': item['unit'],
                            'p2': item['minimum'],
                          },
                        ),
                      ),
                      trailing: ops.isLeader
                          ? PopupMenuButton<String>(
                              popUpAnimationStyle: AppMotion.dialogStyle(
                                context,
                              ),
                              enabled: !ops.busy,
                              onSelected: (value) => value == 'edit'
                                  ? editItem(item)
                                  : archive(
                                      'archive_inventory_item',
                                      item,
                                      '재료',
                                    ),
                              itemBuilder: (_) => [
                                PopupMenuItem(
                                  value: 'edit',
                                  child: Text(context.t('ui.audit155')),
                                ),
                                PopupMenuItem(
                                  value: 'archive',
                                  child: Text(context.t('ui.audit158')),
                                ),
                              ],
                            )
                          : null,
                    ),
                  ),
              ],
            ],
          ),
        ),
      );
    },
  );
}
