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
        title: const Text('변경한 내용을 버릴까요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('계속 수정'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('변경 버리기'),
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
      setState(() => error = '매장 또는 권한이 변경됐어요. 다시 열어 주세요.');
      return;
    }
    Json values;
    if (section == 'basic') {
      if (address.text.trim().isNotEmpty &&
          address.text.trim() != initialAddress &&
          profile['addressSelection'] == null) {
        setState(() => error = '표준 주소 검색에서 주소를 선택해 주세요.');
        return;
      }
      if (name.text.trim().isEmpty || profile['industryId'] == null) {
        setState(() => error = '매장명과 업종을 입력해 주세요.');
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
        setState(() => error = '사용 중인 POS 제품을 선택해 주세요.');
        return;
      }
      final count = int.tryParse(deviceCount.text.trim());
      if (devices.isNotEmpty && (count == null || count < 0 || count > 99)) {
        setState(() => error = '단말 수는 0~99 사이로 입력해 주세요.');
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
      error = ok ? null : widget.ops.error ?? '저장하지 못했어요.';
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
          label: Text(entry.value),
          selected: selected.contains(entry.key),
          onSelected: (_) => changed(entry.key),
        ),
    ],
  );

  Widget basicForm() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Information('매장명과 업종만 입력하면 시작할 수 있어요. 다른 설정은 나중에 추가하세요.'),
      const SizedBox(height: 14),
      textField('매장명 · 필수', name),
      textField('팀 안내 · 선택', note),
      AppPillField<String>(
        initialValue: profile['businessTypeId'] ?? profile['industryId'],
        decoration: const InputDecoration(
          labelText: '매장 업종',
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
              DropdownMenuItem(value: e.key, child: Text(e.value)),
        ],
        onChanged: (value) => update(() {
          final type = storeBusinessTypes(
            widget.ops,
          ).where((t) => t['id'] == value).firstOrNull;
          profile['industryId'] = type?['industryId'] ?? value;
          profile['businessTypeId'] = type?['id'];
        }),
      ),
      const Text(
        '기존 매뉴얼은 그대로 유지해요. 기본 매뉴얼 구성에서 필요한 항목을 추가할 수 있어요.',
        style: AppText.caption,
      ),
      const SizedBox(height: 18),
      const Text('운영 형태'),
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
      textField('상세 주소 · 선택', addressDetail),
      textField('찾아오는 안내 · 선택', arrival),
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
            textField('모델명 · 선택', posModel),
            if (first?['providerId'] == 'other') textField('제품명', posName),
            textField('단말 수', deviceCount, numeric: true),
            const Text('쓰는 기능'),
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
            textField('제품 안내 HTTPS 링크 · 선택', guideUrl),
            const Information('실제 POS 주문 연동이나 기기 제어는 아직 연결되지 않아요.'),
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
            const Text('사용하는 플랫폼'),
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
                platformNames[row['providerId']] ?? '기타',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              if (row['providerId'] == 'other')
                TextFormField(
                  key: ValueKey('delivery-name-${row['id']}'),
                  initialValue: '${row['customName'] ?? ''}',
                  decoration: const InputDecoration(labelText: '플랫폼 이름'),
                  onChanged: (v) => update(() => row['customName'] = v.trim()),
                ),
              TextFormField(
                key: ValueKey('delivery-device-${row['id']}'),
                initialValue: '${row['device'] ?? ''}',
                decoration: const InputDecoration(labelText: '주문 확인 기기 · 선택'),
                onChanged: (v) => update(() => row['device'] = v.trim()),
              ),
              AppPillField<String>(
                initialValue: row['acceptanceMode'] ?? 'unset',
                decoration: const InputDecoration(labelText: '주문 확인 방식'),
                items: const [
                  DropdownMenuItem(value: 'unset', child: Text('미설정')),
                  DropdownMenuItem(value: 'direct', child: Text('직접 확인')),
                  DropdownMenuItem(value: 'tool', child: Text('연결 도구에서 확인')),
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
                decoration: const InputDecoration(labelText: '전달 방식'),
                items: const [
                  DropdownMenuItem(value: 'unset', child: Text('미설정')),
                  DropdownMenuItem(value: 'rider', child: Text('라이더 전달')),
                  DropdownMenuItem(value: 'pickup', child: Text('고객 픽업')),
                  DropdownMenuItem(value: 'other', child: Text('기타')),
                ],
                onChanged: (v) => update(() => row['handoffMode'] = v),
              ),
            ],
            const Information(
              '선택한 방식에 맞는 업무 양식을 추천할 수 있어요. 실제 주문은 자동 수신하지 않아요.',
            ),
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
            child: Text(saving ? '저장 중…' : '이 설정 저장'),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: appEditorWidth),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              if (widget.ops.readOnly)
                const Information('공개 미리보기에서는 설정을 저장하지 않아요.'),
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
                  child: Information('$error\n입력 중인 내용은 남아 있어요.'),
                ),
              if (widget.ops.data?['revision'] != openingRevision)
                const Information(
                  '새로 저장된 내용이 있어요. 저장할 때 내 입력과 비교하고, 같은 항목이 바뀌었으면 선택할 수 있어요.',
                ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    ),
  );
}
