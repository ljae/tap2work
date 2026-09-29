import 'workplace_screens.dart';
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../state/operations_controller.dart';
import 'components.dart';

/// Store settings use a local draft and the revision from the opening snapshot.
class StoreProfileScreen extends StatefulWidget {
  const StoreProfileScreen({super.key, required this.ops});
  final OperationsController ops;

  @override
  State<StoreProfileScreen> createState() => _StoreProfileScreenState();
}

class _StoreProfileScreenState extends State<StoreProfileScreen> {
  late final int openingRevision;
  late final String openingActor;
  late final TextEditingController name;
  late final TextEditingController note;
  late final TextEditingController address;
  late final TextEditingController arrival;
  late final TextEditingController staffCount;
  late final TextEditingController posModel;
  late final TextEditingController posName;
  late final TextEditingController guideUrl;
  late final TextEditingController deviceCount;
  late Json profile;
  String section = 'basic';
  String? error;
  bool saving = false;

  Json get draft => profile;
  Json get pos =>
      (draft['pos'] as Json?) ??
      {'configured': false, 'enabled': false, 'devices': <Json>[]};
  Json get delivery =>
      (draft['delivery'] as Json?) ??
      {'configured': false, 'enabled': false, 'platforms': <Json>[]};
  Json get staffing =>
      (draft['staffing'] as Json?) ??
      {'declaredCount': null, 'includesOwner': false, 'roleTargets': <Json>[]};
  Json get hours =>
      (draft['hours'] as Json?) ??
      {
        'weekdays': <int>[],
        'opening': '09:00',
        'closing': '21:00',
        'endsNextDay': false,
      };
  static const industry = {
    'restaurant': '식당',
    'cafe': '카페',
    'bar': '주점',
    'bakery': '베이커리',
    'other': '기타',
  };
  static const providers = {'okpos': '오케이포스', 'other': '기타'};
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
  Map<String, String> get roles => {
    for (final p in storeParts(widget.ops).where((p) => p['hidden'] != true))
      p['id'] as String: p['name'] as String,
  };

  @override
  void initState() {
    super.initState();
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
    arrival = TextEditingController(text: '${profile['arrivalNote'] ?? ''}');
    staffCount = TextEditingController(
      text: '${staffing['declaredCount'] ?? ''}',
    );
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
  }

  @override
  void dispose() {
    for (final controller in [
      name,
      note,
      address,
      arrival,
      staffCount,
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

  Future<void> save() async {
    if (saving || widget.ops.actorId != openingActor) return;
    Json values;
    if (section == 'basic') {
      if (name.text.trim().isEmpty || profile['industryId'] == null) {
        setState(() => error = '매장명과 업종을 입력해 주세요.');
        return;
      }
      values = {
        'name': name.text.trim(),
        'note': note.text.trim(),
        'industryId': profile['industryId'],
        'serviceModes': profile['serviceModes'] ?? <String>[],
        'address': address.text.trim(),
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
          for (final row in devices)
            {
              ...row,
              'model': posModel.text.trim(),
              'customName': posName.text.trim(),
              'guideUrl': guideUrl.text.trim(),
              'count': count,
            },
        ],
      };
    } else if (section == 'delivery') {
      values = delivery;
    } else if (section == 'staffing') {
      if (staffCount.text.trim().isNotEmpty &&
          int.tryParse(staffCount.text.trim()) == null) {
        setState(() => error = '직원 수는 숫자로 입력해 주세요.');
        return;
      }
      values = {
        ...staffing,
        'declaredCount': staffCount.text.trim().isEmpty
            ? null
            : int.tryParse(staffCount.text.trim()),
      };
    } else {
      values = hours;
    }
    setState(() {
      saving = true;
      error = null;
    });
    final ok = await widget.ops.act('save_store_profile', {
      'revision': openingRevision,
      'section': section,
      'values': values,
    });
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
        initialValue: industry.containsKey(profile['industryId'])
            ? profile['industryId']
            : null,
        decoration: const InputDecoration(
          labelText: '업종 · 필수',
          border: OutlineInputBorder(),
        ),
        items: [
          for (final entry in industry.entries)
            DropdownMenuItem(value: entry.key, child: Text(entry.value)),
        ],
        onChanged: (value) => update(() => profile['industryId'] = value),
      ),
      const SizedBox(height: 18),
      const Text('운영 형태'),
      chips(
        const {'hall': '홀', 'takeout': '포장', 'delivery': '배달'},
        List<String>.from(profile['serviceModes'] ?? []),
        (id) => toggleIn('serviceModes', id),
      ),
      const SizedBox(height: 32),
      textField('주소 · 선택', address),
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
        settingSwitch(
          'POS 사용 정보를 설정했어요',
          p['configured'] == true,
          (value) => update(() {
            p['configured'] = value;
            if (!value) p['enabled'] = false;
            profile['pos'] = p;
          }),
        ),
        if (p['configured'] == true) ...[
          settingSwitch(
            'POS 사용 중',
            p['enabled'] == true,
            (value) => update(() {
              p['enabled'] = value;
              profile['pos'] = p;
            }),
          ),
          if (p['enabled'] == true) ...[
            AppPillField<String>(
              initialValue: providers.containsKey(provider) ? provider : null,
              decoration: const InputDecoration(
                labelText: 'POS 제품',
                border: OutlineInputBorder(),
              ),
              items: [
                for (final entry in providers.entries)
                  DropdownMenuItem(value: entry.key, child: Text(entry.value)),
              ],
              onChanged: (id) => update(() {
                p['devices'] = [
                  {
                    'id': first?['id'] ?? 'pos-main',
                    'providerId': id,
                    'customName': posName.text.trim(),
                    'model': posModel.text.trim(),
                    'count': int.tryParse(deviceCount.text.trim()) ?? 1,
                    'functions': first?['functions'] ?? <String>[],
                    'guideUrl': guideUrl.text.trim(),
                  },
                ];
                profile['pos'] = p;
              }),
            ),
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
        settingSwitch(
          '배달 사용 정보를 설정했어요',
          d['configured'] == true,
          (v) => update(() {
            d['configured'] = v;
            if (!v) d['enabled'] = false;
            profile['delivery'] = d;
          }),
        ),
        if (d['configured'] == true) ...[
          settingSwitch(
            '배달앱 사용 중',
            d['enabled'] == true,
            (v) => update(() {
              d['enabled'] = v;
              profile['delivery'] = d;
            }),
          ),
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
                  onChanged: (v) => row['customName'] = v.trim(),
                ),
              TextFormField(
                key: ValueKey('delivery-device-${row['id']}'),
                initialValue: '${row['device'] ?? ''}',
                decoration: const InputDecoration(labelText: '주문 확인 기기 · 선택'),
                onChanged: (v) => row['device'] = v.trim(),
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

  Widget staffingForm() {
    final s = staffing;
    final targets = (s['roleTargets'] as List? ?? []).cast<Json>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        textField('직원 수 · 미입력 가능', staffCount, numeric: true),
        settingSwitch(
          '직원 수에 사장 포함',
          s['includesOwner'] == true,
          (v) => update(() {
            s['includesOwner'] = v;
            profile['staffing'] = s;
          }),
        ),
        const Text('필요한 파트 · 채용 초안에 활용'),
        chips(
          roles,
          targets.map((e) => (e['partId'] ?? e['roleId']) as String).toList(),
          (id) => update(() {
            final index = targets.indexWhere(
              (row) => (row['partId'] ?? row['roleId']) == id,
            );
            if (index >= 0) {
              targets.removeAt(index);
            } else {
              targets.add({'roleId': id, 'partId': id, 'count': 1});
            }
            s['roleTargets'] = targets;
            profile['staffing'] = s;
          }),
        ),
        for (final row in targets)
          Row(
            children: [
              Expanded(
                child: Text(roles[row['partId'] ?? row['roleId']] ?? '전체 파트'),
              ),
              IconButton(
                tooltip: '필요 인원 줄이기',
                onPressed: row['count'] > 0
                    ? () => update(() => row['count']--)
                    : null,
                icon: const Icon(CupertinoIcons.minus_circle),
              ),
              Text('${row['count']}명'),
              IconButton(
                tooltip: '필요 인원 늘리기',
                onPressed: row['count'] < 999
                    ? () => update(() => row['count']++)
                    : null,
                icon: const Icon(CupertinoIcons.plus_circle),
              ),
            ],
          ),
        const Information('입력한 직원 수는 등록된 직원 명단이나 확정 근무 인원과 별도로 보관돼요.'),
      ],
    );
  }

  Widget hoursForm() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Information('영업시간과 파트별 필요 인원을 한 곳에서 관리해요.'),
      const SizedBox(height: 16),
      SettingRow(
        title: '영업시간·필요 인원',
        subtitle: '휴무일 → 교대 → 시간·인원',
        icon: CupertinoIcons.clock,
        onTap: () => openWorkplaceHours(context, widget.ops),
      ),
      SettingRow(
        title: '파트 관리',
        subtitle: '이름·순서·숨김',
        icon: CupertinoIcons.person_2,
        onTap: () => showAppFormSheet(
          context: context,
          builder: (_) => WorkplaceSettings(ops: widget.ops, section: 'parts'),
        ),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) => AppEditorScaffold(
    title: '우리매장 설정',
    footer: section == 'hours'
        ? null
        : AppSheetFooter(
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
        constraints: const BoxConstraints(maxWidth: 720),
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            SettingRow(
              title: '주문처리 시스템 연결',
              subtitle: widget.ops.data?['orderBoardEnabled'] == true
                  ? '보드 사용 중'
                  : '보드 꺼짐',
              icon: CupertinoIcons.link,
              onTap: () => showAppSheet(
                context,
                builder: (_) =>
                    WorkplaceSettings(ops: widget.ops, section: 'order-system'),
              ),
            ),
            if (widget.ops.readOnly)
              const Information('공개 미리보기에서는 설정을 저장하지 않아요.'),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: AppSegmented<String>(
                segments: const [
                  ButtonSegment(value: 'basic', label: Text('기본')),
                  ButtonSegment(value: 'pos', label: Text('POS')),
                  ButtonSegment(value: 'delivery', label: Text('배달')),
                  ButtonSegment(value: 'staffing', label: Text('직원')),
                  ButtonSegment(value: 'hours', label: Text('운영')),
                ],
                selected: {section},
                onSelectionChanged: (values) => setState(() {
                  section = values.first;
                  error = null;
                }),
              ),
            ),
            const SizedBox(height: 32),
            KeyedSubtree(
              key: ValueKey('store-section-$section'),
              child: switch (section) {
                'pos' => posForm(),
                'delivery' => deliveryForm(),
                'staffing' => staffingForm(),
                'hours' => hoursForm(),
                _ => basicForm(),
              },
            ),
            if (error != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Information('$error\n입력 중인 내용은 남아 있어요.'),
              ),
            if (widget.ops.data?['revision'] != openingRevision)
              const Information('다른 변경이 저장됐어요. 이 화면을 다시 열어 최신 설정을 확인해 주세요.'),
            const SizedBox(height: 16),
          ],
        ),
      ),
    ),
  );
}
