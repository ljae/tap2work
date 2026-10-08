import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../domain/manual_market_catalog.dart';
import '../state/operations_controller.dart';
import 'components.dart';
import 'manual_tap_editor.dart';

class ManualMarketScreen extends StatefulWidget {
  const ManualMarketScreen({
    super.key,
    required this.ops,
    this.folderId,
    this.setup = false,
  });
  final OperationsController ops;
  final String? folderId;
  final bool setup;
  @override
  State<ManualMarketScreen> createState() => _ManualMarketScreenState();
}

class _ManualMarketScreenState extends State<ManualMarketScreen> {
  late final int revision;
  late final String actor;
  late final Object? workspace;
  late final ManualMarketCatalog catalog;
  late String folder;
  String folderMode = 'purpose';
  final selected = <String>{};
  final search = TextEditingController();
  final specialization = TextEditingController();
  bool replaceExisting = false, enableOperations = false;
  String? industry, kind, error;
  bool saving = false, reviewing = false;
  final operationId = 'import-${DateTime.now().microsecondsSinceEpoch}';

  @override
  void initState() {
    super.initState();
    revision = widget.ops.data?['revision'] ?? 0;
    actor = widget.ops.actorId;
    workspace = widget.ops.data?['workspaceId'];
    catalog = ManualMarketCatalog(widget.ops.data?['manualCatalog'] ?? {});
    industry = widget.ops.data?['manualBusinessProfile']?['industryId'];
    specialization.text =
        widget.ops.data?['manualBusinessProfile']?['specialization'] ?? '';
    if (widget.setup) {
      final profile = widget.ops.data?['store']?['profile'] as Json? ?? {};
      final types =
          (widget.ops.data?['storeSetupCatalog']?['businessTypes'] as List? ??
                  [])
              .cast<Json>();
      final type = types
          .where((t) => t['id'] == profile['businessTypeId'])
          .firstOrNull;
      if (type != null) {
        industry = 'food';
        specialization.text = type['name'];
        final collections = {
          'common',
          type['collectionId'],
          if ((profile['serviceModes'] as List? ?? []).contains('delivery'))
            'delivery',
        };
        selected.addAll(
          catalog.entries
              .where(
                (e) =>
                    collections.contains(e['collectionId']) &&
                    e['kind'] != 'legal' &&
                    !catalog.linked(e),
              )
              .map((e) => e['sourceId'] as String),
        );
      }
    }
    final folders = widget.ops.rows('checklistFolders');
    folder = folders.any((f) => f['id'] == widget.folderId)
        ? widget.folderId!
        : folders.firstOrNull?['id'] ?? 'general';
  }

  @override
  void dispose() {
    search.dispose();
    specialization.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if (widget.ops.actorId != actor ||
        widget.ops.data?['workspaceId'] != workspace ||
        !widget.ops.canEditTasks) {
      setState(() => error = '권한 또는 매장이 변경됐어요. 다시 열어 주세요.');
      return;
    }
    setState(() {
      saving = true;
      error = null;
    });
    final ok = await widget.ops.act(
      widget.setup ? 'configure_manual_business' : 'import_market_taps',
      {
        'revision': revision,
        'operationId': operationId,
        'releaseId': catalog.data['releaseId'],
        'folderMode': folderMode,
        if (widget.setup) ...{
          'industryId': industry ?? 'all',
          'specialization': specialization.text.trim(),
          'replaceExisting': replaceExisting,
          'enableOperations': enableOperations,
        },
        if (folderMode == 'existing') 'folderId': folder,
        'sourceIds': selected.toList(),
      },
    );
    if (!mounted) return;
    setState(() => saving = false);
    if (ok) {
      final messenger = ScaffoldMessenger.of(context);
      Navigator.pop(context, selected.toList());
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            widget.setup
                ? '사업장 매뉴얼을 구성했어요. 메뉴·레시피에서 매장 기준을 채워 주세요.'
                : '매뉴얼에 담았어요. 실제 업무로 쓸 항목만 사용을 켜 주세요.',
          ),
        ),
      );
    } else {
      setState(() => error = widget.ops.error ?? '가져오지 못했어요. 다시 시도해 주세요.');
    }
  }

  void choose(Json entry, bool value) => setState(() {
    if (value) {
      selected.add(entry['sourceId']);
    } else {
      selected.remove(entry['sourceId']);
    }
  });

  Future<void> openSource(String value) async {
    final uri = Uri.tryParse(value);
    bool opened = false;
    if (uri != null && uri.scheme == 'https') {
      try {
        opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (_) {
        /* Keep the current selection if the browser cannot open. */
      }
    }
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('출처를 열지 못했어요. 잠시 후 다시 시도해 주세요.')),
      );
    }
  }

  Widget entryCard(Json entry) {
    final linked = !widget.setup && catalog.linked(entry);
    final legal = entry['kind'] == 'legal';
    final steps = (entry['steps'] as List? ?? []).cast<Json>();
    final references = (entry['references'] as List? ?? []).cast<Json>();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Surface(
        padding: const EdgeInsets.all(8),
        child: ExpansionTile(
          key: ValueKey('market-${entry['sourceId']}'),
          tilePadding: const EdgeInsets.symmetric(horizontal: 4),
          leading: Checkbox(
            semanticLabel: '${entry['title']} 담기',
            value: linked || selected.contains(entry['sourceId']),
            onChanged: linked || saving
                ? null
                : (v) => choose(entry, v == true),
          ),
          title: Text(entry['title'], style: AppText.body),
          subtitle: Text(
            '${legal ? '법적 기준 확인' : entry['collectionName']} · ${steps.length}개 항목${linked ? ' · 가져옴' : ''}',
            style: AppText.caption,
          ),
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (entry['summary'] != null)
                    Text(entry['summary'], style: AppText.body),
                  const SizedBox(height: 12),
                  Text('적용 대상', style: AppText.section),
                  Text(
                    entry['applicability'] ?? entry['collectionName'],
                    style: AppText.caption,
                  ),
                  if (legal)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(
                        '해당 여부를 확인하는 목록이에요. 체크 완료가 법적 충족을 뜻하지 않아요.',
                        style: AppText.caption,
                      ),
                    ),
                  for (var i = 0; i < steps.length; i++) ...[
                    const SizedBox(height: 16),
                    Text('${i + 1}. ${steps[i]['title']}', style: AppText.body),
                    Text(steps[i]['manual'] ?? '', style: AppText.caption),
                    if ((steps[i]['tip'] ?? '').isNotEmpty)
                      Text(steps[i]['tip'], style: AppText.caption),
                  ],
                  const SizedBox(height: 16),
                  Text(
                    '${entry['jurisdiction'] ?? '운영 참고'} · 자료 확인 ${entry['reviewedAt']}',
                    style: AppText.caption,
                  ),
                  Text(entry['basis'] ?? '', style: AppText.caption),
                  for (final ref in references) ...[
                    TextButton.icon(
                      onPressed: () => openSource(ref['url']),
                      icon: const Icon(Icons.open_in_new, size: 16),
                      label: Text(ref['title']),
                    ),
                    Text(
                      '${ref['scope']} · ${ref['checkedAt']}',
                      style: AppText.caption,
                    ),
                  ],
                  if (references.isEmpty)
                    const Text(
                      '운영 초안 · 매장의 실제 절차에 맞게 확인해 주세요.',
                      style: AppText.caption,
                    ),
                  if (linked)
                    TextButton(
                      onPressed: () => showAppSheet(
                        context,
                        builder: (_) => ManualTapEditor(
                          ops: widget.ops,
                          templateId: (entry['installed'] as List).firstWhere(
                            (i) => i['mode'] == 'linked',
                          )['templateId'],
                        ),
                      ),
                      child: const Text('내 TAP 상세 열기'),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final results = catalog.search(
      query: search.text,
      industry: industry,
      kind: kind,
    );
    final basket = catalog.entries
        .where((e) => selected.contains(e['sourceId']))
        .toList();
    final groups = <String, List<Json>>{};
    for (final entry in results) {
      final name = industry != null || kind != null || search.text.isNotEmpty
          ? catalog.purposeName(entry)
          : catalog.industryName(catalog.industryIds(entry).first);
      groups.putIfAbsent(name, () => []).add(entry);
    }
    final narrowed = industry != null || kind != null || search.text.isNotEmpty;
    final order = (narrowed ? catalog.purposes : catalog.industries)
        .map((item) => item['name'])
        .toList();
    final orderedGroups = groups.entries.toList()
      ..sort((a, b) => order.indexOf(a.key).compareTo(order.indexOf(b.key)));
    return AppEditorScaffold(
      title: reviewing
          ? '담은 항목 확인'
          : widget.setup
          ? '내 사업장 매뉴얼 구성'
          : '매뉴얼 마켓',
      footer: AppSheetFooter(
        children: [
          if (error != null) Information(error!),
          if (reviewing) ...[
            Text(
              widget.setup
                  ? '메뉴·레시피와 이미 진행한 업무 기록은 유지해요.'
                  : '공용 내용은 자동 업데이트돼요. 가져온 항목은 사용 OFF로 보관돼요.',
              style: AppText.caption,
            ),
            TextButton(
              onPressed: saving
                  ? null
                  : () => setState(() => reviewing = false),
              child: const Text('더 찾아보기'),
            ),
          ],
          FilledButton(
            onPressed: saving || widget.ops.readOnly || selected.isEmpty
                ? null
                : reviewing
                ? save
                : () => setState(() => reviewing = true),
            child: Text(
              saving
                  ? '가져오는 중…'
                  : reviewing
                  ? widget.setup
                        ? '선택한 ${selected.length}개로 구성하기'
                        : '선택한 ${selected.length}개 가져오기'
                  : '담은 ${selected.length}개 확인',
            ),
          ),
        ],
      ),
      body: ListView(
        key: ValueKey(reviewing ? 'market-basket' : 'market-browse'),
        padding: const EdgeInsets.all(24),
        children: reviewing
            ? [
                if (widget.setup) ...[
                  Text(
                    '${catalog.industryName(industry ?? 'all')} · ${specialization.text.isEmpty ? '내 사업장' : specialization.text}',
                    style: AppText.section,
                  ),
                  const Text(
                    '선택한 매뉴얼을 업무별로 분류해요. 메뉴의 재료·분량·조리법은 메뉴·레시피에서 직접 정해 주세요.',
                    style: AppText.caption,
                  ),
                  SwitchListTile(
                    title: const Text('기존 운영 매뉴얼을 새 구성으로 교체'),
                    subtitle: const Text(
                      '진행 전인 오늘 이후 업무는 보관하고, 진행·완료 기록과 메뉴·레시피는 유지해요.',
                    ),
                    value: replaceExisting,
                    onChanged: saving
                        ? null
                        : (v) => setState(() => replaceExisting = v),
                  ),
                  SwitchListTile(
                    title: const Text('선택한 운영 업무를 매일 사용'),
                    subtitle: const Text(
                      '법적 기준은 참고용으로 보관해요. 업무별 시간·담당·주기는 구성 후 조정할 수 있어요.',
                    ),
                    value: enableOperations,
                    onChanged: saving
                        ? null
                        : (v) => setState(() => enableOperations = v),
                  ),
                ],
                if (!widget.setup)
                  const Text('그룹은 한 번만 정하세요', style: AppText.section),
                const SizedBox(height: 12),
                if (!widget.setup)
                  AppPicker<String>(
                    label: '분류 방식',
                    value: folderMode,
                    items: const [
                      DropdownMenuItem(
                        value: 'purpose',
                        child: Text('업무별 자동 분류'),
                      ),
                      DropdownMenuItem(
                        value: 'existing',
                        child: Text('기존 그룹에 모으기'),
                      ),
                    ],
                    onChanged: saving
                        ? null
                        : (v) => setState(() => folderMode = v!),
                  ),
                if (folderMode == 'existing') ...[
                  const SizedBox(height: 16),
                  AppPicker<String>(
                    label: '가져올 그룹',
                    value: folder,
                    items: widget.ops
                        .rows('checklistFolders')
                        .map(
                          (f) => DropdownMenuItem(
                            value: f['id'] as String,
                            child: Text(f['name']),
                          ),
                        )
                        .toList(),
                    onChanged: saving
                        ? null
                        : (v) => setState(() => folder = v!),
                  ),
                ],
                const SizedBox(height: 16),
                for (final entry in basket)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(entry['title']),
                    subtitle: Text(
                      folderMode == 'purpose'
                          ? catalog.purposeName(entry)
                          : '선택한 그룹에 가져와요',
                    ),
                    trailing: IconButton(
                      tooltip: '${entry['title']} 담기 취소',
                      onPressed: saving ? null : () => choose(entry, false),
                      icon: const Icon(Icons.close),
                    ),
                  ),
                if (basket.isEmpty)
                  const Information('담은 항목이 없어요. 더 찾아보기에서 골라 주세요.'),
              ]
            : [
                if (widget.setup) ...[
                  const Text(
                    '1. 업종 선택 → 2. 필요한 항목 담기 → 3. 적용',
                    style: AppText.caption,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: specialization,
                    maxLength: 100,
                    decoration: const InputDecoration(
                      labelText: '우리 사업장 특성',
                      hintText: '예: 고기집 · 뼈찜 전문',
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                TextField(
                  controller: search,
                  decoration: InputDecoration(
                    labelText: '내 업종이나 필요한 업무 검색',
                    hintText: '예: 카페, 예약, 근로계약, 청소',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: search.text.isEmpty
                        ? null
                        : IconButton(
                            tooltip: '검색 지우기',
                            onPressed: () => setState(search.clear),
                            icon: const Icon(Icons.close),
                          ),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  key: const ValueKey('market-industry'),
                  onPressed: () async {
                    final value = await showAppSheet<String>(
                      context,
                      builder: (c) => AppEditorScaffold(
                        title: '업종 선택',
                        body: ListView(
                          children: [
                            ListTile(
                              title: const Text('모든 업종 둘러보기'),
                              selected: industry == null,
                              onTap: () => Navigator.pop(c, ''),
                            ),
                            for (final item in catalog.industries)
                              ListTile(
                                title: Text(item['name']),
                                subtitle: Text(
                                  (item['keywords'] as List? ?? []).join(' · '),
                                ),
                                selected: industry == item['id'],
                                onTap: () =>
                                    Navigator.pop(c, item['id'] as String),
                              ),
                          ],
                        ),
                      ),
                    );
                    if (value != null && mounted) {
                      setState(() => industry = value.isEmpty ? null : value);
                    }
                  },
                  icon: const Icon(Icons.storefront_outlined),
                  label: Text(
                    '업종 · ${industry == null ? '모든 업종 둘러보기' : catalog.industryName(industry!)}',
                  ),
                ),
                if (widget.setup)
                  TextButton.icon(
                    key: const ValueKey('market-starter'),
                    onPressed: saving
                        ? null
                        : () => setState(
                            () => selected.addAll(
                              catalog.entries
                                  .where(
                                    (e) => const {
                                      'business/opening',
                                      'business/service',
                                      'business/inventory',
                                      'business/cleaning',
                                      'business/safety',
                                      'business/people',
                                      'business/closing',
                                    }.contains(e['sourceId']),
                                  )
                                  .map((e) => e['sourceId'] as String),
                            ),
                          ),
                    icon: const Icon(Icons.playlist_add),
                    label: const Text('공통 기본 운영 7개 담기'),
                  ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    for (final option in const {
                      '': '전체',
                      'legal': '법적 기준',
                      'operation': '운영 업무',
                    }.entries)
                      ChoiceChip(
                        label: Text(option.value),
                        selected: (kind ?? '') == option.key,
                        onSelected: (_) => setState(
                          () => kind = option.key.isEmpty ? null : option.key,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  industry == null
                      ? '업종별로 찾고, 필요한 것만 담으세요.'
                      : '선택한 업종과 업종 공통 항목을 함께 보여드려요.',
                  style: AppText.caption,
                ),
                if (kind == 'legal')
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(
                      '업종·인원·시설에 따라 적용 기준이 달라요. 항목을 펼쳐 대상과 공식 출처를 확인하세요.',
                      style: AppText.caption,
                    ),
                  ),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${results.length}개 항목',
                        style: AppText.caption,
                      ),
                    ),
                    if (narrowed &&
                        results.any(
                          (e) =>
                              (widget.setup || !catalog.linked(e)) &&
                              !selected.contains(e['sourceId']),
                        ))
                      TextButton(
                        onPressed: () => setState(
                          () => selected.addAll(
                            results
                                .where(
                                  (e) => widget.setup || !catalog.linked(e),
                                )
                                .map((e) => e['sourceId'] as String),
                          ),
                        ),
                        child: const Text('이 결과 담기'),
                      ),
                  ],
                ),
                if (catalog.entries.isEmpty)
                  const Information(
                    '공용 목록을 불러오지 못했어요. 매뉴얼 목록을 새로고침하고 다시 열어 주세요.',
                  )
                else if (results.isEmpty) ...[
                  const Information('조건에 맞는 항목이 없어요. 다른 검색어나 업종 공통 업무를 살펴보세요.'),
                  TextButton(
                    onPressed: () => setState(() {
                      search.clear();
                      industry = 'all';
                      kind = null;
                    }),
                    child: const Text('공통 업무 보기'),
                  ),
                ],
                for (final group in orderedGroups)
                  ExpansionTile(
                    key: ValueKey(
                      'market-group-${industry ?? ''}-${kind ?? ''}-${search.text}-${group.key}',
                    ),
                    initiallyExpanded: narrowed || groups.length == 1,
                    tilePadding: EdgeInsets.zero,
                    title: Text(group.key, style: AppText.section),
                    subtitle: Text(
                      '${group.value.length}개 항목',
                      style: AppText.caption,
                    ),
                    children: [
                      for (final entry in group.value) entryCard(entry),
                    ],
                  ),
              ],
      ),
    );
  }
}
