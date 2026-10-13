import '../l10n/entity_name_scope.dart';
import '../l10n/manual_text_scope.dart';
import 'manual_example_screen.dart';
import '../l10n/app_localizations.dart';
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
    this.initialCategory,
  });
  final OperationsController ops;
  final String? folderId;
  final bool setup;
  final String? initialCategory;
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
  final browseScroll = ScrollController();
  final basketScroll = ScrollController();
  final specialization = TextEditingController();
  bool replaceExisting = false, enableOperations = false;
  String? industry, useCase, purpose, error;
  bool saving = false, reviewing = false;
  final operationId = 'import-${DateTime.now().microsecondsSinceEpoch}';

  @override
  void initState() {
    super.initState();
    revision = widget.ops.data?['revision'] ?? 0;
    actor = widget.ops.actorId;
    workspace = widget.ops.data?['workspaceId'];
    catalog = ManualMarketCatalog(widget.ops.data?['manualCatalog'] ?? {});
    useCase = widget.initialCategory;
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
          'food',
          type['collectionId'],
          if ((profile['serviceModes'] as List? ?? []).contains('delivery'))
            'delivery',
        };
        selected.addAll(
          catalog.entries
              .where(
                (e) =>
                    collections.contains(e['collectionId']) &&
                    catalog.discoverable(e) &&
                    catalog.useCaseOf(e) != 'recipe' &&
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
    browseScroll.dispose();
    basketScroll.dispose();
    specialization.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if (widget.ops.actorId != actor ||
        widget.ops.data?['workspaceId'] != workspace ||
        !widget.ops.canEditTasks) {
      setState(() => error = context.t('ui.audit1247'));
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
            widget.setup ? context.t('ui.audit671') : context.t('ui.audit672'),
          ),
        ),
      );
    } else {
      setState(() => error = widget.ops.error ?? context.t('ui.audit1248'));
    }
  }

  void choose(Json entry, bool value) => setState(() {
    if (value) {
      selected.add(entry['sourceId']);
    } else {
      selected.remove(entry['sourceId']);
    }
  });

  Future<void> openFilters() async {
    var nextIndustry = industry;
    var nextPurpose = purpose;
    final applied = await showAppSheet<bool>(
      context,
      builder: (c) => StatefulBuilder(
        builder: (c, change) => AppEditorScaffold(
          title: context.t('ui.audit673'),
          footer: AppSheetFooter(
            children: [
              TextButton(
                onPressed: () => change(() {
                  nextIndustry = null;
                  nextPurpose = null;
                }),
                child: Text(context.t('ui.audit192')),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(c, true),
                child: Text(context.t('ui.audit193')),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              AppPicker<String>(
                label: context.t('ui.audit674'),
                value: nextPurpose ?? '',
                items: [
                  DropdownMenuItem(
                    value: '',
                    child: Text(context.t('ui.audit675')),
                  ),
                  for (final item in catalog.purposes.where(
                    (p) => catalog
                        .search(useCase: useCase)
                        .any((e) => e['purposeId'] == p['id']),
                  ))
                    DropdownMenuItem(
                      value: item['id'] as String,
                      child: Text(display(item['name'])),
                    ),
                ],
                onChanged: (v) =>
                    change(() => nextPurpose = v == '' ? null : v),
              ),
              const SizedBox(height: 24),
              AppPicker<String>(
                key: const ValueKey('market-industry'),
                label: context.t('ui.audit676'),
                value: nextIndustry ?? '',
                items: [
                  DropdownMenuItem(
                    value: '',
                    child: Text(context.t('ui.audit677')),
                  ),
                  for (final item in catalog.industries)
                    DropdownMenuItem(
                      value: item['id'] as String,
                      child: Text(display(item['name'])),
                    ),
                ],
                onChanged: (v) =>
                    change(() => nextIndustry = v == '' ? null : v),
              ),
              const SizedBox(height: 16),
              Text(context.t('ui.audit194'), style: AppText.caption),
            ],
          ),
        ),
      ),
    );
    if (applied == true && mounted) {
      setState(() {
        industry = nextIndustry;
        purpose = nextPurpose;
      });
    }
  }

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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.t('ui.audit678'))));
    }
  }

  String display(dynamic value) => manualDisplayText(context, '${value ?? ''}');
  Future<void> openExample(Json profile) async {
    final ids = catalog.entries
        .where((e) => e['knowledge']?['exampleStoreId'] == profile['id'])
        .map((e) => e['sourceId'] as String)
        .toSet();
    final picked = await showAppPage<List<String>>(
      context,
      builder: (_) => ManualExampleScreen(
        profile: profile,
        entries: catalog.entries,
        initialSelected: selected.intersection(ids),
        canSelect: !saving,
      ),
    );
    if (!mounted ||
        picked == null ||
        widget.ops.actorId != actor ||
        widget.ops.data?['workspaceId'] != workspace) {
      return;
    }
    setState(() {
      selected.removeWhere(ids.contains);
      selected.addAll(picked.where(ids.contains));
    });
  }

  List<Json> matchingEntries() {
    final original = catalog.search(
      useCase: useCase,
      purpose: purpose,
      query: search.text,
      industry: industry,
    );
    if (search.text.trim().isEmpty) return original;
    String norm(String value) =>
        value.toLowerCase().replaceAll(RegExp(r'\s+'), '');
    final words = search.text.trim().split(RegExp(r'\s+')).map(norm);
    final translated = catalog
        .search(useCase: useCase, purpose: purpose, industry: industry)
        .where((entry) {
          final text = norm(
            [
              display(entry['title']),
              display(entry['summary']),
              display(entry['applicability']),
              display(entry['collectionName']),
              for (final action in (entry['steps'] as List? ?? []).cast<Json>())
                '${display(action['title'])} ${display(action['manual'])}',
            ].join(' '),
          );
          return words.every(text.contains);
        });
    return {
      for (final entry in [...original, ...translated])
        entry['sourceId']: entry,
    }.values.toList();
  }

  Widget exampleFeature(Json profile) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Surface(
      padding: const EdgeInsets.all(8),
      child: ListTile(
        key: ValueKey('market-example-${profile['id']}'),
        leading: const Icon(Icons.storefront_outlined, color: AppColors.green),
        title: Text(
          display(profile['name']),
          maxLines: 2,
          style: AppText.body.copyWith(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          context.t('manual.market.exampleTitle'),
          style: AppText.caption,
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => openExample(profile),
      ),
    ),
  );

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
            semanticLabel: context.t(
              'ui.audit679',
              args: {'p0': display(entry['title'])},
            ),
            value: linked || selected.contains(entry['sourceId']),
            onChanged: linked || saving
                ? null
                : (v) => choose(entry, v == true),
          ),
          title: Text(display(entry['title']), style: AppText.body),
          subtitle: Text(
            context.t(
              'ui.audit680',
              args: {
                'p0': context.t('manual.category.${catalog.useCaseOf(entry)}'),
                'p1': steps.length,
                'p2': linked ? context.t('ui.audit1123') : '',
              },
            ),
            style: AppText.caption,
          ),
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (entry['summary'] != null)
                    Text(display(entry['summary']), style: AppText.body),
                  const SizedBox(height: 12),
                  Text(context.t('ui.audit681'), style: AppText.section),
                  Text(
                    display(entry['applicability'] ?? entry['collectionName']),
                    style: AppText.caption,
                  ),
                  if (legal)
                    Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(
                        context.t('ui.audit682'),
                        style: AppText.caption,
                      ),
                    ),
                  for (var i = 0; i < steps.length; i++) ...[
                    const SizedBox(height: 16),
                    Text(
                      '${i + 1}. ${display(steps[i]['title'])}',
                      style: AppText.body,
                    ),
                    Text(display(steps[i]['manual']), style: AppText.caption),
                    if ((steps[i]['tip'] ?? '').isNotEmpty)
                      Text(display(steps[i]['tip']), style: AppText.caption),
                  ],
                  const SizedBox(height: 16),
                  Text(
                    context.t(
                      'ui.audit683',
                      args: {
                        'p0': display(
                          entry['jurisdiction'] ?? context.t('ui.audit1124'),
                        ),
                        'p1': entry['reviewedAt'],
                      },
                    ),
                    style: AppText.caption,
                  ),
                  Text(display(entry['basis']), style: AppText.caption),
                  for (final ref in references) ...[
                    TextButton.icon(
                      onPressed: () => openSource(ref['url']),
                      icon: const Icon(Icons.open_in_new, size: 16),
                      label: Text(display(ref['title'])),
                    ),
                    Text(
                      '${display(ref['scope'])} · ${ref['checkedAt']}',
                      style: AppText.caption,
                    ),
                  ],
                  if (references.isEmpty)
                    Text(context.t('ui.audit195'), style: AppText.caption),
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
                      child: Text(context.t('ui.audit196')),
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
    final results = matchingEntries();
    final basket = catalog.entries
        .where((e) => selected.contains(e['sourceId']))
        .toList();
    final groups = <String, List<Json>>{};
    for (final entry in results) {
      final name = catalog.purposeName(entry);
      groups.putIfAbsent(name, () => []).add(entry);
    }
    final narrowed =
        industry != null ||
        useCase != null ||
        purpose != null ||
        search.text.isNotEmpty;
    final order = catalog.purposes.map((item) => item['name']).toList();
    final orderedGroups = groups.entries.toList()
      ..sort((a, b) => order.indexOf(a.key).compareTo(order.indexOf(b.key)));
    return AppEditorScaffold(
      title: reviewing
          ? context.t('ui.audit684')
          : widget.setup
          ? context.t('ui.audit685')
          : useCase == 'recipe'
          ? context.t('manual.recipeLibrary')
          : context.t('ui.audit686'),
      footer: AppSheetFooter(
        children: [
          if (error != null) Information(context.t(error!)),
          if (reviewing) ...[
            Text(
              widget.setup
                  ? context.t('ui.audit687')
                  : context.t('ui.audit688'),
              style: AppText.caption,
            ),
            TextButton(
              onPressed: saving
                  ? null
                  : () => setState(() => reviewing = false),
              child: Text(context.t('ui.audit197')),
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
                  ? context.t('ui.audit689')
                  : reviewing
                  ? widget.setup
                        ? context.t(
                            'ui.audit690',
                            args: {'p0': selected.length},
                          )
                        : context.t(
                            'ui.audit691',
                            args: {'p0': selected.length},
                          )
                  : context.t('ui.audit692', args: {'p0': selected.length}),
            ),
          ),
        ],
      ),
      body: ListView(
        key: ValueKey(reviewing ? 'market-basket' : 'market-browse'),
        controller: reviewing ? basketScroll : browseScroll,
        padding: const EdgeInsets.all(24),
        children: reviewing
            ? [
                if (widget.setup) ...[
                  Text(
                    '${catalog.industryName(industry ?? 'all')} · ${specialization.text.isEmpty ? '내 사업장' : specialization.text}',
                    style: AppText.section,
                  ),
                  Text(context.t('ui.audit198'), style: AppText.caption),
                  SwitchListTile(
                    title: Text(context.t('ui.audit199')),
                    subtitle: Text(context.t('ui.audit200')),
                    value: replaceExisting,
                    onChanged: saving
                        ? null
                        : (v) => setState(() => replaceExisting = v),
                  ),
                  SwitchListTile(
                    title: Text(context.t('ui.audit201')),
                    subtitle: Text(context.t('ui.audit202')),
                    value: enableOperations,
                    onChanged: saving
                        ? null
                        : (v) => setState(() => enableOperations = v),
                  ),
                ],
                if (!widget.setup)
                  Text(context.t('ui.audit203'), style: AppText.section),
                const SizedBox(height: 12),
                if (!widget.setup)
                  AppPicker<String>(
                    label: context.t('ui.audit693'),
                    value: folderMode,
                    items: [
                      DropdownMenuItem(
                        value: 'purpose',
                        child: Text(context.t('ui.audit694')),
                      ),
                      if ((catalog.data['taxonomy']?['exampleStores']
                                  as List? ??
                              [])
                          .isNotEmpty)
                        DropdownMenuItem(
                          value: 'example',
                          child: Text(
                            context.t('manual.market.exampleStructure'),
                          ),
                        ),
                      DropdownMenuItem(
                        value: 'existing',
                        child: Text(context.t('ui.audit695')),
                      ),
                    ],
                    onChanged: saving
                        ? null
                        : (v) => setState(() => folderMode = v!),
                  ),
                if (folderMode == 'existing') ...[
                  const SizedBox(height: 16),
                  AppPicker<String>(
                    label: context.t('ui.audit696'),
                    value: folder,
                    items: widget.ops
                        .rows('checklistFolders')
                        .map(
                          (f) => DropdownMenuItem(
                            value: f['id'] as String,
                            child: Text(
                              entityDisplayName(
                                context,
                                widget.ops,
                                'folder',
                                f['id'],
                                f['name'],
                              ),
                            ),
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
                    title: Text(display(entry['title'])),
                    subtitle: Text(
                      folderMode == 'purpose'
                          ? catalog.purposeName(entry)
                          : context.t('ui.audit697'),
                    ),
                    trailing: IconButton(
                      tooltip: context.t(
                        'ui.audit698',
                        args: {'p0': display(entry['title'])},
                      ),
                      onPressed: saving ? null : () => choose(entry, false),
                      icon: const Icon(Icons.close),
                    ),
                  ),
                if (basket.isEmpty) Information(context.t('ui.audit204')),
              ]
            : [
                if (widget.setup) ...[
                  Text(context.t('ui.audit205'), style: AppText.caption),
                  const SizedBox(height: 16),
                  TextField(
                    controller: specialization,
                    maxLength: 100,
                    decoration: InputDecoration(
                      labelText: context.t('ui.audit206'),
                      hintText: context.t('ui.audit207'),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                for (final profile
                    in (catalog.data['taxonomy']?['exampleStores'] as List? ??
                            [])
                        .cast<Json>())
                  exampleFeature(profile),
                TextField(
                  controller: search,
                  decoration: InputDecoration(
                    labelText: context.t('ui.audit699'),
                    hintText: context.t('ui.audit700'),
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: search.text.isEmpty
                        ? null
                        : IconButton(
                            tooltip: context.t('ui.audit701'),
                            onPressed: () => setState(search.clear),
                            icon: const Icon(Icons.close),
                          ),
                  ),
                  onChanged: (_) {
                    setState(() {});
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted && browseScroll.hasClients) {
                        browseScroll.jumpTo(0);
                      }
                    });
                  },
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final item in {
                      '': '전체',
                      ...ManualMarketCatalog.useCases,
                    }.entries)
                      ChoiceChip(
                        label: Text(
                          item.key.isEmpty
                              ? context.t('manual.market.common')
                              : context.t('manual.category.${item.key}'),
                        ),
                        selected: (useCase ?? '') == item.key,
                        onSelected: (_) => setState(() {
                          useCase = item.key.isEmpty ? null : item.key;
                          purpose = null;
                        }),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  key: const ValueKey('market-filters'),
                  onPressed: openFilters,
                  icon: const Icon(Icons.tune, size: 18),
                  label: Text(
                    industry == null && purpose == null
                        ? context.t('ui.audit673')
                        : '${purpose == null ? '모든 업무' : catalog.purposes.where((p) => p['id'] == purpose).firstOrNull?['name'] ?? '모든 업무'} · ${industry == null ? '모든 업종' : catalog.industryName(industry!)}',
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
                    label: Text(context.t('ui.audit208')),
                  ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        context.t('ui.audit702', args: {'p0': results.length}),
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
                        child: Text(context.t('ui.audit209')),
                      ),
                  ],
                ),
                if (catalog.entries.isEmpty)
                  Information(context.t('ui.audit210'))
                else if (results.isEmpty) ...[
                  Information(context.t('ui.audit211')),
                  TextButton(
                    onPressed: () => setState(() {
                      search.clear();
                      industry = null;
                      useCase = null;
                      purpose = null;
                    }),
                    child: Text(context.t('ui.audit212')),
                  ),
                ],
                for (final group in orderedGroups)
                  ExpansionTile(
                    key: ValueKey(
                      'market-group-${industry ?? ''}-${useCase ?? ''}-${purpose ?? ''}-${search.text}-${group.key}',
                    ),
                    initiallyExpanded: narrowed || groups.length == 1,
                    tilePadding: EdgeInsets.zero,
                    title: Text(group.key, style: AppText.section),
                    subtitle: Text(
                      context.t(
                        'ui.audit702',
                        args: {'p0': group.value.length},
                      ),
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
