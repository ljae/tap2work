import '../l10n/app_localizations.dart';
import 'address_search.dart';
import 'store_setup_screen.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../state/operations_controller.dart';
import 'components.dart';
import '../domain/edit_conflict.dart';
import 'edit_conflict_dialog.dart';

/// Store settings use a local draft and the revision from the opening snapshot.
class StoreProfileScreen extends StatefulWidget {
  const StoreProfileScreen({
    super.key,
    required this.ops,
    this.initialSection = 'basic',
  });
  final OperationsController ops;
  final String initialSection;

  @override
  State<StoreProfileScreen> createState() => _StoreProfileScreenState();
}

class _StoreProfileScreenState extends State<StoreProfileScreen> {
  late final int openingRevision;
  late final Json openingSnapshot;
  late final String openingActor;
  late final TextEditingController name;
  late final TextEditingController note;
  late final TextEditingController address;
  late final TextEditingController addressDetail;
  late final TextEditingController arrival;
  late final TextEditingController posModel;
  late final TextEditingController posName;
  late final TextEditingController guideUrl;
  late final TextEditingController deviceCount;
  late Json profile;
  late final String section;
  late final Object? openingWorkspace;
  String? error;
  bool saving = false;
  late final String initialSignature;
  late final String initialAddress;
  String get signature => jsonEncode([
    profile,
    name.text,
    note.text,
    address.text,
    addressDetail.text,
    arrival.text,
    posModel.text,
    posName.text,
    guideUrl.text,
    deviceCount.text,
  ]);

  Json get draft => profile;
  Json get pos =>
      (draft['pos'] as Json?) ??
      {'configured': false, 'enabled': false, 'devices': <Json>[]};
  Json get delivery =>
      (draft['delivery'] as Json?) ??
      {'configured': false, 'enabled': false, 'platforms': <Json>[]};
  static const industry = {
    'restaurant': '식당',
    'cafe': '카페',
    'bar': '주점',
    'bakery': '베이커리',
    'other': '기타',
  };
  static const platformNames = {
    'baemin': '배달의민족',
    'coupang-eats': '쿠팡이츠',
    'yogiyo': '요기요',
    'other': '기타',
  };
  static const functions = {
    'orders': '주문 접수',
    'payment': '결제',
    'receipt': '영수증',
    'kitchen-print': '주방 출력',
    'closing': '마감',
  };
  @override
  void initState() {
    super.initState();
    section = widget.initialSection;
    openingWorkspace = widget.ops.workspaceId;
    openingSnapshot = copyEditSnapshot(widget.ops.data ?? {});
    final store = widget.ops.data?['store'] as Json? ?? {};
    openingRevision = widget.ops.data?['revision'] as int? ?? 0;
    openingActor = widget.ops.actorId;
    profile =
        jsonDecode(jsonEncode(store['profile'] ?? <String, dynamic>{})) as Json;
    name = TextEditingController(
      text: store['setup'] == 'blank' ? '' : '${store['name'] ?? ''}',
    );
    note = TextEditingController(text: '${store['note'] ?? ''}');
    address = TextEditingController(text: '${profile['address'] ?? ''}');
    addressDetail = TextEditingController(
      text: '${profile['addressDetail'] ?? ''}',
    );
    arrival = TextEditingController(text: '${profile['arrivalNote'] ?? ''}');
    posModel = TextEditingController(
      text:
          '${((pos['devices'] as List? ?? []).firstOrNull as Json?)?['model'] ?? ''}',
    );
    posName = TextEditingController(
      text:
          '${((pos['devices'] as List? ?? []).firstOrNull as Json?)?['customName'] ?? ''}',
    );
    guideUrl = TextEditingController(
      text:
          '${((pos['devices'] as List? ?? []).firstOrNull as Json?)?['guideUrl'] ?? ''}',
    );
    deviceCount = TextEditingController(
      text:
          '${((pos['devices'] as List? ?? []).firstOrNull as Json?)?['count'] ?? 1}',
    );
    initialSignature = signature;
    initialAddress = address.text.trim();
  }

  @override
  void dispose() {
    for (final controller in [
      name,
      note,
      address,
      addressDetail,
      arrival,
      posModel,
      posName,
      guideUrl,
      deviceCount,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  void update(VoidCallback action) => setState(() {
    action();
    error = null;
  });
  void toggleIn(String key, String value) => update(() {
    final values = List<String>.from((draft[key] as List?) ?? []);
    values.contains(value) ? values.remove(value) : values.add(value);
    draft[key] = values;
  });

  Future<void> close() async {
    if (saving) return;
    if (signature == initialSignature) {
      Navigator.pop(context);
      return;
    }
    final discard = await showAppDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(context.t('ui.audit439')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: Text(context.t('ui.audit179')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: Text(context.t('ui.audit22')),
          ),
        ],
      ),
    );
    if (discard == true && mounted) Navigator.pop(context);
  }

  Future<void> save() async {
    if (saving) return;
    if (widget.ops.actorId != openingActor ||
        widget.ops.workspaceId != openingWorkspace) {
      setState(() => error = context.t('ui.audit1280'));
      return;
    }
    Json values;
    if (section == 'basic') {
      if (address.text.trim().isNotEmpty &&
          address.text.trim() != initialAddress &&
          profile['addressSelection'] == null) {
        setState(() => error = context.t('ui.audit1281'));
        return;
      }
      if (name.text.trim().isEmpty || profile['industryId'] == null) {
        setState(() => error = context.t('ui.audit1282'));
        return;
      }
      values = {
        'name': name.text.trim(),
        'note': note.text.trim(),
        'industryId': profile['industryId'],
        if (profile['businessTypeId'] != null)
          'businessTypeId': profile['businessTypeId'],
        'serviceModes': profile['serviceModes'] ?? <String>[],
        'address': address.text.trim(),
        'addressSelection': profile['addressSelection'],
        'addressDetail': addressDetail.text.trim(),
        'arrivalNote': arrival.text.trim(),
      };
    } else if (section == 'pos') {
      final p = pos;
      final devices = (p['devices'] as List? ?? []).cast<Json>();
      if (p['enabled'] == true && devices.isEmpty) {
        setState(() => error = context.t('ui.audit1283'));
        return;
      }
      final count = int.tryParse(deviceCount.text.trim());
      if (devices.isNotEmpty && (count == null || count < 0 || count > 99)) {
        setState(() => error = context.t('ui.audit1284'));
        return;
      }
      values = {
        ...p,
        'devices': [
          for (final (index, row) in devices.indexed)
            if (index == 0)
              {
                ...row,
                'model': posModel.text.trim(),
                'customName': posName.text.trim(),
                'guideUrl': guideUrl.text.trim(),
                'count': count,
              }
            else
              row,
        ],
      };
    } else if (section == 'delivery') {
      values = delivery;
    } else {
      return;
    }
    setState(() {
      saving = true;
      error = null;
    });
    final ok = await widget.ops.saveDraft(
      'save_store_profile',
      {'section': section, 'values': values},
      baseSnapshot: openingSnapshot,
      openingActor: openingActor,
      openingWorkspace: openingWorkspace as String?,
      resolve: (conflicts) => mounted
          ? showEditConflictDialog(context, conflicts, ops: widget.ops)
          : Future.value(EditConflictChoice.keepEditing),
    );
    if (!mounted) return;
    setState(() {
      saving = false;
      error = ok ? null : widget.ops.error ?? context.t('ui.audit760');
    });
    if (ok) Navigator.pop(context);
  }

  Widget textField(
    String label,
    TextEditingController controller, {
    bool numeric = false,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: TextField(
      controller: controller,
      onChanged: (_) => update(() {}),
      keyboardType: numeric ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    ),
  );

  Widget settingSwitch(
    String title,
    bool value,
    ValueChanged<bool> onChanged,
  ) => SwitchListTile.adaptive(
    contentPadding: EdgeInsets.zero,
    title: Text(title),
    value: value,
    onChanged: onChanged,
  );

  Widget chips(
    Map<String, String> options,
    List<String> selected,
    ValueChanged<String> changed,
  ) => Wrap(
    spacing: 8,
    runSpacing: 4,
    children: [
      for (final entry in options.entries)
        FilterChip(
          chipAnimationStyle: AppMotion.chipStyle(context),
          label: Text(context.t(entry.value)),
          selected: selected.contains(entry.key),
          onSelected: (_) => changed(entry.key),
        ),
    ],
  );

  Widget basicForm() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Information(context.t('ui.audit440')),
      const SizedBox(height: 14),
      textField(context.t('ui.audit1219'), name),
      textField(context.t('ui.audit1220'), note),
      AppPillField<String>(
        initialValue: profile['businessTypeId'] ?? profile['industryId'],
        decoration: InputDecoration(
          labelText: context.t('ui.audit441'),
          border: OutlineInputBorder(),
        ),
        items: [
          for (final t in storeBusinessTypes(widget.ops))
            DropdownMenuItem(
              value: t['id'] as String,
              child: Text(t['name'] as String),
            ),
          for (final e in industry.entries)
            if (!storeBusinessTypes(widget.ops).any((t) => t['id'] == e.key))
              DropdownMenuItem(value: e.key, child: Text(context.t(e.value))),
        ],
        onChanged: (value) => update(() {
          final type = storeBusinessTypes(
            widget.ops,
          ).where((t) => t['id'] == value).firstOrNull;
          profile['industryId'] = type?['industryId'] ?? value;
          profile['businessTypeId'] = type?['id'];
        }),
      ),
      Text(context.t('ui.audit442'), style: AppText.caption),
      const SizedBox(height: 18),
      Text(context.t('ui.audit443')),
      chips(
        const {'hall': '홀', 'takeout': '포장', 'delivery': '배달'},
        List<String>.from(profile['serviceModes'] ?? []),
        (id) => toggleIn('serviceModes', id),
      ),
      const SizedBox(height: 32),
      StoreAddressField(
        controller: address,
        onSelected: (value) =>
            setState(() => profile['addressSelection'] = value),
      ),
      textField(context.t('ui.audit88'), addressDetail),
      textField(context.t('ui.audit90'), arrival),
    ],
  );

  Widget posForm() {
    final p = pos;
    final devices = (p['devices'] as List? ?? []).cast<Json>();
    final first = devices.firstOrNull;
    final provider = first == null ? null : first['providerId'] as String?;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        chips(
          const {
            'unset': '나중에 설정',
            'none': '사용 안 함',
            'okpos': '오케이포스',
            'other': '기타 POS',
          },
          [
            p['configured'] != true
                ? 'unset'
                : p['enabled'] != true
                ? 'none'
                : provider ?? 'other',
          ],
          (id) => update(() {
            p['configured'] = id != 'unset';
            p['enabled'] = id != 'unset' && id != 'none';
            if (p['enabled'] == true) {
              p['devices'] = [
                {
                  ...?first,
                  'id': first?['id'] ?? 'pos-main',
                  'providerId': id,
                  'count': first?['count'] ?? 1,
                  'functions': first?['functions'] ?? <String>[],
                },
                ...devices.skip(1),
              ];
            }
            profile['pos'] = p;
          }),
        ),
        if (p['configured'] == true) ...[
          if (p['enabled'] == true) ...[
            const SizedBox(height: 14),
            textField(context.t('ui.audit1221'), posModel),
            if (first?['providerId'] == 'other')
              textField(context.t('ui.audit1222'), posName),
            textField(context.t('ui.audit1223'), deviceCount, numeric: true),
            Text(context.t('ui.audit444')),
            chips(
              functions,
              List<String>.from(first?['functions'] ?? []),
              (id) => update(() {
                final selected = List<String>.from(first?['functions'] ?? []);
                selected.contains(id) ? selected.remove(id) : selected.add(id);
                first?['functions'] = selected;
              }),
            ),
            const SizedBox(height: 14),
            textField(context.t('ui.audit1224'), guideUrl),
            Information(context.t('ui.audit445')),
          ],
        ],
      ],
    );
  }

  Widget deliveryForm() {
    final d = delivery;
    final platforms = (d['platforms'] as List? ?? []).cast<Json>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        chips(
          const {'unset': '나중에 설정', 'none': '사용 안 함', 'enabled': '사용 중'},
          [
            d['configured'] != true
                ? 'unset'
                : d['enabled'] == true
                ? 'enabled'
                : 'none',
          ],
          (id) => update(() {
            d['configured'] = id != 'unset';
            d['enabled'] = id == 'enabled';
            profile['delivery'] = d;
          }),
        ),
        if (d['configured'] == true) ...[
          if (d['enabled'] == true) ...[
            Text(context.t('ui.audit446')),
            chips(
              platformNames,
              platforms.map((e) => e['providerId'] as String).toList(),
              (id) => update(() {
                final index = platforms.indexWhere(
                  (row) => row['providerId'] == id,
                );
                if (index >= 0) {
                  platforms.removeAt(index);
                } else {
                  platforms.add({
                    'id': 'delivery-$id',
                    'providerId': id,
                    'acceptanceMode': 'unset',
                    'printTicket': false,
                    'handoffMode': 'unset',
                  });
                }
                d['platforms'] = platforms;
                profile['delivery'] = d;
              }),
            ),
            for (final row in platforms) ...[
              const SizedBox(height: 18),
              Text(
                platformNames[row['providerId']] ?? context.t('ui.audit1039'),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              if (row['providerId'] == 'other')
                TextFormField(
                  key: ValueKey('delivery-name-${row['id']}'),
                  initialValue: '${row['customName'] ?? ''}',
                  decoration: InputDecoration(
                    labelText: context.t('ui.audit447'),
                  ),
                  onChanged: (v) => update(() => row['customName'] = v.trim()),
                ),
              TextFormField(
                key: ValueKey('delivery-device-${row['id']}'),
                initialValue: '${row['device'] ?? ''}',
                decoration: InputDecoration(
                  labelText: context.t('ui.audit448'),
                ),
                onChanged: (v) => update(() => row['device'] = v.trim()),
              ),
              AppPillField<String>(
                initialValue: row['acceptanceMode'] ?? 'unset',
                decoration: InputDecoration(
                  labelText: context.t('ui.audit449'),
                ),
                items: [
                  DropdownMenuItem(
                    value: 'unset',
                    child: Text(context.t('ui.audit921')),
                  ),
                  DropdownMenuItem(
                    value: 'direct',
                    child: Text(context.t('ui.audit1040')),
                  ),
                  DropdownMenuItem(
                    value: 'tool',
                    child: Text(context.t('ui.audit1041')),
                  ),
                ],
                onChanged: (v) => update(() => row['acceptanceMode'] = v),
              ),
              settingSwitch(
                '주문표 출력',
                row['printTicket'] == true,
                (v) => update(() => row['printTicket'] = v),
              ),
              AppPillField<String>(
                initialValue: row['handoffMode'] ?? 'unset',
                decoration: InputDecoration(
                  labelText: context.t('ui.audit450'),
                ),
                items: [
                  DropdownMenuItem(
                    value: 'unset',
                    child: Text(context.t('ui.audit921')),
                  ),
                  DropdownMenuItem(
                    value: 'rider',
                    child: Text(context.t('ui.audit1042')),
                  ),
                  DropdownMenuItem(
                    value: 'pickup',
                    child: Text(context.t('ui.audit1043')),
                  ),
                  DropdownMenuItem(
                    value: 'other',
                    child: Text(context.t('ui.audit1039')),
                  ),
                ],
                onChanged: (v) => update(() => row['handoffMode'] = v),
              ),
            ],
            Information(context.t('ui.audit451')),
          ],
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !saving && signature == initialSignature,
    onPopInvokedWithResult: (didPop, result) {
      if (!didPop) close();
    },
    child: AppEditorScaffold(
      onClose: close,
      title: switch (section) {
        'pos' => 'POS',
        'delivery' => '배달 플랫폼',
        _ => '매장 정보',
      },
      footer: AppSheetFooter(
        children: [
          FilledButton(
            onPressed: widget.ops.isOwner && !widget.ops.readOnly && !saving
                ? save
                : null,
            child: Text(
              saving ? context.t('ui.audit532') : context.t('ui.audit1044'),
            ),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: appEditorWidth),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              if (widget.ops.readOnly) Information(context.t('ui.audit383')),
              KeyedSubtree(
                key: ValueKey('store-section-$section'),
                child: switch (section) {
                  'pos' => posForm(),
                  'delivery' => deliveryForm(),
                  _ => basicForm(),
                },
              ),
              if (error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Information(
                    context.t('ui.audit939', args: {'p0': error}),
                  ),
                ),
              if (widget.ops.data?['revision'] != openingRevision)
                Information(context.t('ui.audit452')),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    ),
  );
}
