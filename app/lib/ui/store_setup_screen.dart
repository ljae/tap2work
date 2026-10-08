import 'dart:math';
import 'package:flutter/material.dart';
import '../state/operations_controller.dart';
import 'components.dart';
import 'address_search.dart';
import 'time_wheel.dart';
import 'workplace_screens.dart' show SettingRow;

const storeServiceModes = {'hall': '홀', 'takeout': '포장', 'delivery': '배달'};
// Shared labels for the existing advanced settings summary.
const setupPlatforms = {
  'baemin': '배달의민족',
  'coupang-eats': '쿠팡이츠',
  'yogiyo': '요기요',
  'other': '기타',
};
const setupParts = {'kitchen': '주방', 'hall': '홀', 'management': '관리'};

List<Json> storeBusinessTypes(OperationsController ops) =>
    (ops.data?['storeSetupCatalog']?['businessTypes'] as List? ?? [])
        .cast<Json>();
String storeBusinessName(OperationsController ops) {
  final profile = ops.data?['store']?['profile'] as Json? ?? {};
  return storeBusinessTypes(ops)
          .where((t) => t['id'] == profile['businessTypeId'])
          .firstOrNull?['name'] ??
      const {
        'restaurant': '식당',
        'cafe': '카페',
        'bar': '주점',
        'bakery': '베이커리',
        'other': '기타',
      }[profile['industryId']] ??
      '업종 미설정';
}

Future<void> openStoreSetup(BuildContext context, OperationsController ops) =>
    showAppFormSheet<void>(
      context: context,
      builder: (_) => StoreSetupScreen(ops: ops),
    );

/// One isolated draft. Creation + settings + published manuals commit together.
class StoreSetupScreen extends StatefulWidget {
  const StoreSetupScreen({super.key, required this.ops});
  final OperationsController ops;
  @override
  State<StoreSetupScreen> createState() => _StoreSetupScreenState();
}

class _StoreSetupScreenState extends State<StoreSetupScreen> {
  final name = TextEditingController();
  final address = TextEditingController();
  final addressDetail = TextEditingController();
  final partName = TextEditingController();
  Json? addressSelection;
  final partLabels = <String, String>{...setupParts};
  final menuIds = <String>{};
  final arrival = TextEditingController();
  final scroll = ScrollController();
  late final requestId = _uuid();
  String? typeId, error;
  final modes = <String>{'hall'};
  final weekdays = <int>{1, 2, 3, 4, 5, 6, 7};
  final parts = <String>{'kitchen', 'hall', 'management'};
  final headcounts = <String, int>{'kitchen': 1, 'hall': 1, 'management': 0};
  final selected = <String>{};
  String opening = '09:00', closing = '21:00';
  bool enableOperations = false, saving = false, completed = false;
  int step = 0, shiftCount = 1;
  bool hasBreak = false;
  String breakStart = '15:00', breakEnd = '16:00';
  Json? submitted;
  Json get catalog => widget.ops.data?['storeSetupCatalog'] as Json? ?? {};
  List<Json> get types => storeBusinessTypes(widget.ops);
  Json? get type => types.where((t) => t['id'] == typeId).firstOrNull;
  List<String> get steps => [
    'name',
    'type',
    'service',
    'location',
    'days',
    'hours',
    'shifts',
    'break',
    'parts',
    for (var i = 0; i < (parts.length / 3).ceil(); i++) 'counts-$i',
    'menus',
    'manual',
    'review',
  ];
  List<Json> get menuSuggestions =>
      (catalog['bundles']?[typeId] as List? ?? []).cast<Json>();
  String get current => steps[step.clamp(0, steps.length - 1)];
  List<Json> get recommended => (catalog['entries'] as List? ?? [])
      .cast<Json>()
      .where(
        (e) => [
          'common',
          type?['collectionId'],
          if (modes.contains('delivery')) 'delivery',
        ].contains(e['collectionId']),
      )
      .toList();
  static String _uuid() {
    final r = Random.secure();
    final b = List.generate(16, (_) => r.nextInt(256));
    b[6] = (b[6] & 15) | 64;
    b[8] = (b[8] & 63) | 128;
    final h = b.map((v) => v.toRadixString(16).padLeft(2, '0')).join();
    return '${h.substring(0, 8)}-${h.substring(8, 12)}-${h.substring(12, 16)}-${h.substring(16, 20)}-${h.substring(20)}';
  }

  @override
  void dispose() {
    name.dispose();
    address.dispose();
    addressDetail.dispose();
    partName.dispose();
    arrival.dispose();
    scroll.dispose();
    super.dispose();
  }

  void change(VoidCallback action) => setState(() {
    error = null;
    action();
  });
  void recommend() {
    menuIds
      ..clear()
      ..addAll(menuSuggestions.map((e) => e['id'] as String));
    selected
      ..clear()
      ..addAll(recommended.map((e) => e['sourceId'] as String));
  }

  void move(int delta) {
    FocusManager.instance.primaryFocus?.unfocus();
    change(() => step += delta);
    if (scroll.hasClients) scroll.jumpTo(0);
  }

  String? validate() => switch (current) {
    'name' when name.text.trim().isEmpty => '매장 이름을 입력해 주세요.',
    'type' when type == null => '매장 업종을 선택해 주세요.',
    'service' when modes.isEmpty => '운영 형태를 하나 이상 선택해 주세요.',
    'location'
        when address.text.trim().isNotEmpty && addressSelection == null =>
      '표준 주소 검색에서 주소를 선택해 주세요.',
    'days' when weekdays.isEmpty => '영업일을 하루 이상 선택해 주세요.',
    'hours' when opening == closing => '시작과 종료 시간을 다르게 선택해 주세요.',
    'parts' when parts.isEmpty => '파트를 하나 이상 선택해 주세요.',
    _ => null,
  };
  int minutes(String time) =>
      int.parse(time.substring(0, 2)) * 60 + int.parse(time.substring(3));
  String? timeIssue() {
    final duration = (minutes(closing) - minutes(opening) + 1440) % 1440;
    if (duration < shiftCount * 30) return '교대마다 30분 이상의 시간이 필요해요.';
    if (hasBreak) {
      final start = (minutes(breakStart) - minutes(opening) + 1440) % 1440;
      final end =
          start + (minutes(breakEnd) - minutes(breakStart) + 1440) % 1440;
      if (start == end || end > duration) return '브레이크 타임을 영업시간 안에서 선택해 주세요.';
    }
    return null;
  }

  Future<void> next() async {
    final issue =
        validate() ??
        (['shifts', 'break', 'review'].contains(current) ? timeIssue() : null);
    if (issue != null) {
      change(() => error = issue);
      return;
    }
    if (current != 'review') {
      move(1);
      return;
    }
    submitted ??= {
      'mode': 'blank',
      'name': name.text.trim(),
      'requestId': requestId,
      'revision': 0,
      'setup': {
        'businessTypeId': typeId,
        'address': address.text.trim(),
        'addressSelection': addressSelection,
        'addressDetail': addressDetail.text.trim(),
        'arrivalNote': arrival.text.trim(),
        'serviceModes': modes.toList(),
        'weekdays': weekdays.toList(),
        'opening': opening,
        'closing': closing,
        'shiftCount': shiftCount,
        'breakTime': hasBreak ? {'start': breakStart, 'end': breakEnd} : null,
        'partIds': parts.toList(),
        'customParts': [
          for (final entry in partLabels.entries.where(
            (e) => !setupParts.containsKey(e.key),
          ))
            {'id': entry.key, 'name': entry.value},
        ],
        'bundleVersion': catalog['bundleVersion'],
        'menuIds': menuIds.toList(),
        'headcounts': {for (final p in parts) p: headcounts[p]},
        'releaseId': catalog['releaseId'],
        'sourceIds': selected.toList(),
        'enableOperations': enableOperations,
      },
    };
    change(() => saving = true);
    final ok = await widget.ops.act('create_workspace', submitted!);
    if (!mounted) return;
    final failure = widget.ops.error;
    if (!ok && widget.ops.actionFailure?['setupRejected'] == true) {
      await widget.ops.refresh(force: true);
      if (!mounted) return;
      submitted = null;
      menuIds.retainAll(menuSuggestions.map((e) => e['id'] as String));
      selected.retainAll(recommended.map((e) => e['sourceId'] as String));
      step = steps.indexOf('manual');
    }
    change(() {
      saving = false;
      completed = ok;
      error = ok ? null : failure ?? '저장하지 못했어요. 다시 시도해 주세요.';
    });
    if (ok && scroll.hasClients) scroll.jumpTo(0);
  }

  Future<void> close() async {
    if (saving) return;
    if (completed || (step == 0 && name.text.isEmpty)) {
      Navigator.pop(context);
      return;
    }
    final discard = await showAppDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('매장 등록을 닫을까요?'),
        content: Text(
          submitted == null
              ? '입력한 설정은 저장되지 않아요.'
              : '응답을 받지 못했다면 매장이 생성됐을 수 있어요. 매장 목록을 확인해 주세요.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('계속 설정'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('닫기'),
          ),
        ],
      ),
    );
    if (discard == true && mounted) Navigator.pop(context);
  }

  Widget choices(
    Map<String, String> values,
    Set<String> picked,
    void Function(String) toggle,
  ) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [
      for (final e in values.entries)
        FilterChip(
          label: Text(e.value),
          selected: picked.contains(e.key),
          chipAnimationStyle: AppMotion.chipStyle(context),
          onSelected: (_) => change(() => toggle(e.key)),
        ),
    ],
  );
  void toggle(Set<String> set, String id) =>
      set.contains(id) ? set.remove(id) : set.add(id);
  Widget summary(String title, String value, String target) => SettingRow(
    title: title,
    subtitle: value,
    icon: Icons.check_circle_outline,
    onTap: submitted != null
        ? () {}
        : () {
            change(() => step = steps.indexOf(target));
            if (scroll.hasClients) scroll.jumpTo(0);
          },
  );
  List<Widget> content() {
    switch (current) {
      case 'name':
        return [
          TextField(
            key: const ValueKey('new-workspace-name'),
            controller: name,
            maxLength: 80,
            textInputAction: TextInputAction.next,
            onSubmitted: (_) => next(),
            decoration: const InputDecoration(
              labelText: '매장 이름',
              hintText: '예: 우리치킨 강남점',
            ),
          ),
        ];
      case 'type':
        return [
          choices(
            {for (final t in types) t['id'] as String: t['name'] as String},
            {?typeId},
            (id) {
              typeId = id;
              recommend();
            },
          ),
          if (typeId == 'donkatsu')
            const Information('돈까스 메뉴·재료와 튀김 작업 공통 매뉴얼을 함께 준비해요.'),
        ];
      case 'service':
        return [
          choices(storeServiceModes, modes, (id) {
            toggle(modes, id);
            recommend();
          }),
          const Text('함께 운영하는 형태를 모두 골라 주세요.', style: AppText.caption),
        ];
      case 'location':
        return [
          StoreAddressField(
            controller: address,
            onSelected: (value) => change(() => addressSelection = value),
          ),
          TextField(
            controller: addressDetail,
            maxLength: 100,
            decoration: const InputDecoration(
              labelText: '상세 주소 · 선택',
              hintText: '층·호수',
            ),
          ),
          TextField(
            controller: arrival,
            maxLength: 300,
            decoration: const InputDecoration(
              labelText: '찾아오는 안내 · 선택',
              hintText: '예: 건물 뒤쪽 직원 출입구',
            ),
          ),
          const Text('아직 정하지 않았다면 입력 없이 넘어가도 돼요.', style: AppText.caption),
        ];
      case 'days':
        return [
          choices(
            {
              for (var i = 1; i <= 7; i++)
                '$i': ['월', '화', '수', '목', '금', '토', '일'][i - 1],
            },
            weekdays.map((d) => '$d').toSet(),
            (id) {
              final d = int.parse(id);
              weekdays.contains(d) ? weekdays.remove(d) : weekdays.add(d);
            },
          ),
          const Text('선택하지 않은 요일은 정기 휴무일이에요.', style: AppText.caption),
        ];
      case 'hours':
        return [
          AppTimeField(
            label: '영업 시작',
            value: opening,
            onChanged: (v) => change(() => opening = v),
          ),
          AppTimeField(
            label: '영업 종료',
            value: closing,
            onChanged: (v) => change(() => closing = v),
          ),
          Text(
            '${closing.compareTo(opening) < 0 ? '다음 날 $closing에 마감해요. ' : ''}선택한 영업일에 같은 시간을 적용해요. 요일별 시간·교대·브레이크는 영업시간 설정에서 조정할 수 있어요.',
            style: AppText.caption,
          ),
        ];
      case 'shifts':
        return [
          choices(
            const {'1': '1교대', '2': '2교대', '3': '3교대'},
            {'$shiftCount'},
            (v) => shiftCount = int.parse(v),
          ),
          const Text(
            '영업시간을 교대 수에 맞춰 나눠요. 교대 경계와 인원은 영업시간 설정에서 조정할 수 있어요.',
            style: AppText.caption,
          ),
        ];
      case 'break':
        return [
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: const Text('브레이크 타임'),
            value: hasBreak,
            onChanged: (v) => change(() => hasBreak = v),
          ),
          if (hasBreak) ...[
            AppTimeField(
              label: '브레이크 시작',
              value: breakStart,
              onChanged: (v) => change(() => breakStart = v),
            ),
            AppTimeField(
              label: '브레이크 종료',
              value: breakEnd,
              onChanged: (v) => change(() => breakEnd = v),
            ),
            const Text(
              '영업시간 안에서 선택해요. 크루의 휴게·급여 시간과는 별도로 관리해요.',
              style: AppText.caption,
            ),
          ],
        ];
      case 'parts':
        return [
          choices(partLabels, parts, (id) => toggle(parts, id)),
          TextField(
            controller: partName,
            maxLength: 40,
            decoration: const InputDecoration(
              labelText: '새 파트 이름',
              hintText: '예: 제빵, 포장',
            ),
          ),
          OutlinedButton.icon(
            onPressed: partLabels.length >= 12
                ? null
                : () {
                    final value = partName.text.trim();
                    if (value.isEmpty || partLabels.values.contains(value)) {
                      change(() => error = '중복되지 않는 파트 이름을 입력해 주세요.');
                      return;
                    }
                    change(() {
                      final id = 'custom-${_uuid()}';
                      partLabels[id] = value;
                      parts.add(id);
                      headcounts[id] = 1;
                      partName.clear();
                    });
                  },
            icon: const Icon(Icons.add),
            label: const Text('파트 추가'),
          ),
          const Text(
            '파트는 업무를 나누는 기준이에요. 직책별 권한은 별도로 관리해요.',
            style: AppText.caption,
          ),
        ];
      case final countStep when countStep.startsWith('counts-'):
        return [
          for (final id
              in parts.skip(int.parse(current.split('-').last) * 3).take(3))
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${partLabels[id]} · 필요 인원', style: AppText.body),
                Row(
                  children: [
                    IconButton(
                      tooltip: '${partLabels[id]} 인원 줄이기',
                      onPressed: headcounts[id]! > 0
                          ? () => change(
                              () => headcounts[id] = headcounts[id]! - 1,
                            )
                          : null,
                      icon: const Icon(Icons.remove_circle_outline),
                    ),
                    Text('${headcounts[id]}명'),
                    IconButton(
                      tooltip: '${partLabels[id]} 인원 늘리기',
                      onPressed: headcounts[id]! < 12
                          ? () => change(
                              () => headcounts[id] = headcounts[id]! + 1,
                            )
                          : null,
                      icon: const Icon(Icons.add_circle_outline),
                    ),
                  ],
                ),
              ],
            ),
          const Text(
            '각 교대에 동시에 일할 인원이에요. 크루를 등록한 뒤 인원 배치에서 이름을 연결해 주세요.',
            style: AppText.caption,
          ),
        ];
      case 'menus':
        return [
          const Text(
            '선택한 메뉴의 주요 재료와 레시피 초안을 함께 준비해요. 가격·분량·조리 기준은 매장에 맞게 수정해 주세요.',
            style: AppText.caption,
          ),
          if (menuSuggestions.isEmpty)
            const Information(
              '이 업종은 메뉴를 직접 추가해 주세요. 등록 후 우리매장 → 메뉴에서 추가할 수 있어요.',
            ),
          for (final menu in menuSuggestions)
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: menuIds.contains(menu['id']),
              onChanged: (_) => change(() => toggle(menuIds, menu['id'])),
              title: Text(menu['name']),
              subtitle: Text(
                '주요 재료: ${(menu['ingredients'] as List).join(', ')}\n${menu['method']}',
              ),
            ),
          const Text(
            '재고는 0으로 시작해요. 메뉴 가격과 재료 단위·공급처·발주 기준을 등록 후 확인해 주세요.',
            style: AppText.caption,
          ),
        ];
      case 'manual':
        return [
          const Text(
            '선택한 TAP 안에 실행할 Task와 방법이 들어 있어요. 항목을 펼쳐 확인하고 필요 없는 TAP은 제외하세요.',
            style: AppText.caption,
          ),
          for (final purpose
              in (catalog['purposes'] as List? ?? []).cast<Json>())
            if (recommended.any((e) => e['purposeId'] == purpose['id'])) ...[
              Text(purpose['name'], style: AppText.section),
              for (final entry in recommended.where(
                (e) => e['purposeId'] == purpose['id'],
              ))
                ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  title: Text(entry['title'], style: AppText.body),
                  leading: Checkbox(
                    value: selected.contains(entry['sourceId']),
                    onChanged: (_) =>
                        change(() => toggle(selected, entry['sourceId'])),
                  ),
                  children: [
                    for (final task in entry['steps'] as List)
                      ListTile(
                        title: Text(task['title']),
                        subtitle: Text(task['manual']),
                      ),
                  ],
                ),
            ],
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: const Text('영업일마다 업무에도 사용'),
            subtitle: const Text('끄면 매뉴얼만 준비해요. 사용할 TAP은 나중에 켤 수 있어요.'),
            value: enableOperations,
            onChanged: (v) => change(() => enableOperations = v),
          ),
        ];
      default:
        return [
          summary('매장 이름', name.text.trim(), 'name'),
          summary('매장 업종', '${type?['name'] ?? ''}', 'type'),
          summary(
            '운영 형태',
            modes.map((m) => storeServiceModes[m]).join(' · '),
            'service',
          ),
          summary(
            '주소·찾아오는 안내',
            address.text.trim().isEmpty ? '나중에 설정' : '${address.text.trim()} ${addressDetail.text.trim()}'.trim(),
            'location',
          ),
          summary(
            '영업시간 설정',
            '${(weekdays.toList()..sort()).map((d) => ['월', '화', '수', '목', '금', '토', '일'][d - 1]).join('·')} $opening–${closing.compareTo(opening) < 0 ? '다음 날 ' : ''}$closing',
            'hours',
          ),
          summary('교대', '$shiftCount교대', 'shifts'),
          summary(
            '브레이크 타임',
            hasBreak ? '$breakStart–$breakEnd' : '없음',
            'break',
          ),
          summary(
            '파트·필요 인원',
            parts.map((p) => '${partLabels[p]} ${headcounts[p]}명').join(' · '),
            'counts-0',
          ),
          summary('메뉴·재료·레시피', '${menuIds.length}개 메뉴와 주요 재료', 'menus'),
          summary(
            '기본 매뉴얼',
            '${selected.length} TAP · ${enableOperations ? '영업일마다 업무 사용' : '매뉴얼만 준비'}',
            'manual',
          ),
          const Text(
            '메뉴 가격·재료 기준은 우리매장, 레시피는 매뉴얼 → 메뉴·레시피에서 수정해요. 크루·배치도·정산도 이어서 설정할 수 있어요.',
            style: AppText.caption,
          ),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final available = types.isNotEmpty;
    final titles = {
      'name': '매장 이름을 알려 주세요',
      'type': '어떤 매장을 운영하세요?',
      'service': '어떻게 판매하나요?',
      'location': '매장은 어디에 있나요?',
      'days': '어느 요일에 영업하나요?',
      'hours': '몇 시부터 몇 시까지 영업하나요?',
      'shifts': '몇 교대로 운영하나요?',
      'break': '브레이크 타임이 있나요?',
      'parts': '어떤 파트가 필요한가요?',
      'counts': '파트마다 몇 명이 필요한가요?',
      'menus': '기본 메뉴와 재료를 준비했어요',
      'manual': '기본 매뉴얼을 준비했어요',
      'review': '이 설정으로 시작할까요?',
    };
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          if (step > 0 && !saving && submitted == null) {
            move(-1);
          } else {
            close();
          }
        }
      },
      child: AppEditorScaffold(
        title: completed
            ? '매장 준비가 끝났어요'
            : current.startsWith('counts-')
            ? '파트마다 몇 명이 필요한가요?'
            : titles[current]!,
        subtitle: completed
            ? '우리매장에서 같은 항목을 찾아 수정할 수 있어요.'
            : '${step + 1} / ${steps.length} · 새 매장 등록',
        onClose: close,
        body: AppContentTransition(
          trigger: completed ? 'complete' : current,
          child: ListView(
            controller: scroll,
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
            children: [
              if (completed) ...[
                const Icon(
                  Icons.check_circle_outline,
                  color: AppColors.green,
                  size: 56,
                ),
                const SizedBox(height: 24),
                Text(name.text.trim(), style: AppText.title),
                const SizedBox(height: 16),
                const Text(
                  '매장 설정을 저장했어요. 크루를 등록하고 인원 배치를 연결하면 근무표를 준비할 수 있어요.',
                ),
              ] else if (!available) ...[
                const Information('등록에 필요한 업종 목록을 불러오지 못했어요.'),
                TextButton(
                  onPressed: () async {
                    await widget.ops.refresh(force: true);
                    if (mounted) setState(() {});
                  },
                  child: const Text('다시 불러오기'),
                ),
              ] else ...[
                LinearProgressIndicator(value: (step + 1) / steps.length),
                const SizedBox(height: 32),
                ...content().expand((w) => [w, const SizedBox(height: 16)]),
              ],
            ],
          ),
        ),
        footer: AppSheetFooter(
          children: [
            if (error != null) Information('$error\n입력한 설정은 남아 있어요.'),
            if (completed)
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('매장으로 가기'),
              )
            else ...[
              if (step > 0)
                TextButton(
                  onPressed: saving || submitted != null
                      ? null
                      : () => move(-1),
                  child: const Text('이전'),
                ),
              PressBounce(
                child: FilledButton(
                  onPressed: saving || !available ? null : next,
                  child: Text(
                    saving
                        ? '매장 준비 중…'
                        : current == 'review'
                        ? (submitted == null ? '매장 등록' : '등록 다시 시도')
                        : '다음',
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
