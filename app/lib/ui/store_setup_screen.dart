import 'manual_setup_screen.dart';
import '../l10n/app_localizations.dart';
import 'team_screen.dart';
import 'dart:math';
import 'package:flutter/material.dart';
import '../state/operations_controller.dart';
import 'components.dart';
import 'address_search.dart';
import 'time_wheel.dart';
import 'workplace_screens.dart' show SettingRow, openWorkplaceHours;

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
  final Json conditions = {};
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
  List<Json> get recommended =>
      ((catalog['manualVariants']?[typeId] ?? catalog['entries']) as List? ??
              [])
          .cast<Json>()
          .where(
            (e) =>
                [
                  'common',
                  'food',
                  'process',
                  type?['collectionId'],
                  if (modes.contains('delivery')) 'delivery',
                ].contains(e['collectionId']) &&
                (e['knowledge']?['supersededBy'] as List? ?? []).isEmpty &&
                (![
                      'food/hall-open',
                      'food/hall-close',
                      'food/service',
                    ].contains(e['sourceId']) ||
                    modes.contains('hall')) &&
                (e['sourceId'] != 'food/packing' ||
                    modes.contains('takeout') ||
                    modes.contains('delivery')) &&
                (e['collectionId'] != 'process' ||
                    (e['knowledge']?['menuNames'] as List? ?? []).any(
                      (name) => menuSuggestions.any(
                        (m) => menuIds.contains(m['id']) && m['name'] == name,
                      ),
                    )),
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
        'manualSetup': {'conditions': conditions, 'places': {}},
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
        'sourceIds': selected
            .where((id) => recommended.any((e) => e['sourceId'] == id))
            .toList(),
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
      error = ok ? null : failure ?? context.t('ui.audit1139');
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
        title: Text(context.t('ui.audit81')),
        content: Text(
          submitted == null
              ? context.t('ui.audit593')
              : context.t('ui.audit594'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: Text(context.t('ui.audit82')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: Text(context.t('ui.audit83')),
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
          label: Text(context.t(e.value)),
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
            decoration: InputDecoration(
              labelText: context.t('ui.audit84'),
              hintText: context.t('ui.audit85'),
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
          if (typeId == 'donkatsu') Information(context.t('ui.audit86')),
        ];
      case 'service':
        return [
          choices(storeServiceModes, modes, (id) {
            toggle(modes, id);
            recommend();
          }),
          Text(context.t('ui.audit87'), style: AppText.caption),
          const SizedBox(height: 24),
          ManualConditions(
            values: conditions,
            onChanged: (k, v) => change(() => conditions[k] = v),
          ),
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
            decoration: InputDecoration(
              labelText: context.t('ui.audit88'),
              hintText: context.t('ui.audit89'),
            ),
          ),
          TextField(
            controller: arrival,
            maxLength: 300,
            decoration: InputDecoration(
              labelText: context.t('ui.audit90'),
              hintText: context.t('ui.audit91'),
            ),
          ),
          Text(context.t('ui.audit92'), style: AppText.caption),
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
          Text(context.t('ui.audit93'), style: AppText.caption),
        ];
      case 'hours':
        return [
          AppTimeField(
            label: context.t('ui.audit595'),
            value: opening,
            onChanged: (v) => change(() => opening = v),
          ),
          AppTimeField(
            label: context.t('ui.audit596'),
            value: closing,
            onChanged: (v) => change(() => closing = v),
          ),
          Text(
            context.t(
              'ui.audit597',
              args: {
                'p0': closing.compareTo(opening) < 0
                    ? context.t('ui.audit1111', args: {'p0': closing})
                    : '',
              },
            ),
            style: AppText.caption,
          ),
        ];
      case 'shifts':
        return [
          choices(
            {
              '1': context.t('ui.audit1376'),
              '2': context.t('ui.audit1377'),
              '3': context.t('ui.audit1378'),
            },
            {'$shiftCount'},
            (v) => shiftCount = int.parse(v),
          ),
          Text(context.t('ui.audit94'), style: AppText.caption),
        ];
      case 'break':
        return [
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: Text(context.t('ui.audit95')),
            value: hasBreak,
            onChanged: (v) => change(() => hasBreak = v),
          ),
          if (hasBreak) ...[
            AppTimeField(
              label: context.t('ui.audit598'),
              value: breakStart,
              onChanged: (v) => change(() => breakStart = v),
            ),
            AppTimeField(
              label: context.t('ui.audit599'),
              value: breakEnd,
              onChanged: (v) => change(() => breakEnd = v),
            ),
            Text(context.t('ui.audit96'), style: AppText.caption),
          ],
        ];
      case 'parts':
        return [
          choices(partLabels, parts, (id) => toggle(parts, id)),
          TextField(
            controller: partName,
            maxLength: 40,
            decoration: InputDecoration(
              labelText: context.t('ui.audit97'),
              hintText: context.t('ui.audit98'),
            ),
          ),
          OutlinedButton.icon(
            onPressed: partLabels.length >= 12
                ? null
                : () {
                    final value = partName.text.trim();
                    if (value.isEmpty || partLabels.values.contains(value)) {
                      change(() => error = context.t('ui.audit1241'));
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
            label: Text(context.t('ui.audit99')),
          ),
          Text(context.t('ui.audit100'), style: AppText.caption),
        ];
      case final countStep when countStep.startsWith('counts-'):
        return [
          for (final id
              in parts.skip(int.parse(current.split('-').last) * 3).take(3))
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.t('ui.audit600', args: {'p0': partLabels[id]}),
                  style: AppText.body,
                ),
                Row(
                  children: [
                    IconButton(
                      tooltip: context.t(
                        'ui.audit601',
                        args: {'p0': partLabels[id]},
                      ),
                      onPressed: headcounts[id]! > 0
                          ? () => change(
                              () => headcounts[id] = headcounts[id]! - 1,
                            )
                          : null,
                      icon: const Icon(Icons.remove_circle_outline),
                    ),
                    Text(
                      context.t('ui.audit602', args: {'p0': headcounts[id]}),
                    ),
                    IconButton(
                      tooltip: context.t(
                        'ui.audit603',
                        args: {'p0': partLabels[id]},
                      ),
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
          Text(context.t('ui.audit101'), style: AppText.caption),
        ];
      case 'menus':
        return [
          Text(context.t('ui.audit102'), style: AppText.caption),
          if (menuSuggestions.isEmpty) Information(context.t('ui.audit103')),
          for (final menu in menuSuggestions)
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: menuIds.contains(menu['id']),
              onChanged: (_) => change(() => toggle(menuIds, menu['id'])),
              title: Text(menu['name']),
              subtitle: Text(
                context.t(
                  'ui.audit604',
                  args: {
                    'p0': (menu['ingredients'] as List).join(', '),
                    'p1': menu['method'],
                  },
                ),
              ),
            ),
          Text(context.t('ui.audit104'), style: AppText.caption),
        ];
      case 'manual':
        return [
          Text(context.t('ui.audit105'), style: AppText.caption),
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
                  subtitle: Text(
                    ['common', 'food'].contains(entry['collectionId'])
                        ? context.t('ui.audit605')
                        : context.t('ui.audit606'),
                    style: AppText.caption,
                  ),
                  leading: Checkbox(
                    value: selected.contains(entry['sourceId']),
                    onChanged: (_) =>
                        change(() => toggle(selected, entry['sourceId'])),
                  ),
                  children: [
                    for (final task in entry['steps'] as List)
                      if (!(conditions['selfbar'] == false &&
                              ['selfbar'].contains(task['id'])) &&
                          !(conditions['tableBurner'] == false &&
                              task['id'] == 'burner'))
                        ListTile(
                          title: Text(task['title']),
                          subtitle: Text(task['manual']),
                        ),
                  ],
                ),
            ],
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: Text(context.t('ui.audit106')),
            subtitle: Text(context.t('ui.audit107')),
            value: enableOperations,
            onChanged: (v) => change(() => enableOperations = v),
          ),
        ];
      default:
        return [
          summary(context.t('ui.audit84'), name.text.trim(), 'name'),
          summary(context.t('ui.audit441'), '${type?['name'] ?? ''}', 'type'),
          summary(
            context.t('ui.audit443'),
            modes.map((m) => storeServiceModes[m]).join(' · '),
            'service',
          ),
          summary(
            context.t('ui.audit1112'),
            address.text.trim().isEmpty
                ? context.t('ui.audit739')
                : '${address.text.trim()} ${addressDetail.text.trim()}'.trim(),
            'location',
          ),
          summary(
            context.t('ui.audit808'),
            '${(weekdays.toList()..sort()).map((d) => ['월', '화', '수', '목', '금', '토', '일'][d - 1]).join('·')} $opening–${closing.compareTo(opening) < 0 ? '다음 날 ' : ''}$closing',
            'hours',
          ),
          summary(
            context.t('ui.audit1113'),
            context.t('ui.audit1114', args: {'p0': shiftCount}),
            'shifts',
          ),
          summary(
            context.t('ui.audit95'),
            hasBreak ? '$breakStart–$breakEnd' : context.t('ui.audit1115'),
            'break',
          ),
          summary(
            context.t('ui.audit1116'),
            parts
                .map(
                  (p) => context.t(
                    'ui.audit2099',
                    args: {'p0': partLabels[p], 'p1': headcounts[p]},
                  ),
                )
                .join(' · '),
            'counts-0',
          ),
          summary(
            context.t('ui.audit1117'),
            context.t('ui.audit1118', args: {'p0': menuIds.length}),
            'menus',
          ),
          summary(
            context.t('ui.audit1119'),
            '${selected.length} TAP · ${enableOperations ? '영업일마다 업무 사용' : '매뉴얼만 준비'}',
            'manual',
          ),
          Text(context.t('ui.audit108'), style: AppText.caption),
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
            ? context.t('setup.completeTitle')
            : current.startsWith('counts-')
            ? context.t('ui.audit607')
            : titles[current]!,
        subtitle: completed
            ? context.t('ui.audit608')
            : context.t(
                'ui.audit609',
                args: {'p0': step + 1, 'p1': steps.length},
              ),
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
                Text(context.t('setup.nextHelp')),
                const SizedBox(height: 16),
                SettingRow(
                  title: context.t('setup.crew'),
                  onTap: () => showAppSheet(
                    context,
                    builder: (_) => AppEditorScaffold(
                      title: context.t('setup.crew'),
                      body: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: TeamScreen(operations: widget.ops),
                      ),
                    ),
                  ),
                ),
                SettingRow(
                  title: context.t('setup.schedule'),
                  onTap: () =>
                      openWorkplaceHours(context, widget.ops, staffing: true),
                ),
                Text(context.t('setup.nonBlocking'), style: AppText.caption),
              ] else if (!available) ...[
                Information(context.t('ui.audit109')),
                TextButton(
                  onPressed: () async {
                    await widget.ops.refresh(force: true);
                    if (mounted) setState(() {});
                  },
                  child: Text(context.t('ui.audit110')),
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
            if (error != null)
              Information(context.t('ui.audit610', args: {'p0': error})),
            if (completed)
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: Text(context.t('ui.audit111')),
              )
            else ...[
              if (step > 0)
                TextButton(
                  onPressed: saving || submitted != null
                      ? null
                      : () => move(-1),
                  child: Text(context.t('ui.audit112')),
                ),
              PressBounce(
                child: FilledButton(
                  onPressed: saving || !available ? null : next,
                  child: Text(
                    saving
                        ? context.t('ui.audit611')
                        : current == 'review'
                        ? (submitted == null
                              ? context.t('ui.audit612')
                              : context.t('ui.audit613'))
                        : context.t('ui.audit614'),
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
