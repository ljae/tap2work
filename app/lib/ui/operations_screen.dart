import 'dart:math';
import '../domain/inventory_readiness.dart';
import 'manual_setup_screen.dart';
import 'store_setup_screen.dart';
import 'water_search.dart';
import 'manual_market_screen.dart';
import 'workspace_menu.dart';
import 'payroll_settings_screen.dart';
import 'app_loading_screen.dart';
import 'workplace_screens.dart';
import 'labor_panel.dart';
import 'manual_workspace.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../state/operations_controller.dart';
import '../state/work_controller.dart';
import 'components.dart';
import 'store_dashboard.dart';
import 'floor_plan.dart';
import 'tap_workspace.dart';
import 'team_screen.dart';
import 'catalog_editor.dart';
import 'store_profile_screen.dart';
import 'staff_workspace.dart';
import 'recommended_taps_screen.dart';
import '../l10n/app_localizations.dart';
import 'shared_welcome_screen.dart';
import 'place_guide.dart';
import 'translated_content.dart';
import 'app_language_picker.dart';

class OperationsScreen extends StatefulWidget {
  const OperationsScreen({
    super.key,
    required this.operations,
    required this.work,
    this.onAccountPressed,
    this.accountEmail,
  });
  final OperationsController operations;
  final WorkController work;
  final Future<void> Function(BuildContext context)? onAccountPressed;
  final String? accountEmail;
  @override
  State<OperationsScreen> createState() => _OperationsScreenState();
}

class _OperationsScreenState extends State<OperationsScreen> {
  OperationsController get ops => widget.operations;
  final detailRevision = ValueNotifier<int>(0);
  void updateView(VoidCallback change) {
    setState(change);
    detailRevision.value++;
  }

  final taskPart = ValueNotifier<String?>(null);
  int tab = 0;
  final manualSearch = TextEditingController();
  String manualQuery = '';
  final presentedWelcomes = <String>{};
  bool welcomeQueued = false, welcomeOpen = false;

  String? get welcomeScope {
    final document = ops.data?['welcome'];
    if (document is! Json) return null;
    return '${ops.actorId}/${ops.data?['workspaceId']}/${document['importantRevision']}';
  }

  @override
  void initState() {
    super.initState();
    ops.addListener(maybeOpenWelcome);
    WidgetsBinding.instance.addPostFrameCallback((_) => maybeOpenWelcome());
  }

  @override
  void didUpdateWidget(covariant OperationsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.operations != ops) {
      oldWidget.operations.removeListener(maybeOpenWelcome);
      ops.addListener(maybeOpenWelcome);
      presentedWelcomes.clear();
      maybeOpenWelcome();
    }
  }

  void maybeOpenWelcome() {
    final scope = welcomeScope;
    if (!mounted ||
        scope == null ||
        welcomeOpen ||
        welcomeQueued ||
        ops.data?['welcomeNeedsAcknowledgment'] != true ||
        presentedWelcomes.contains(scope)) {
      return;
    }
    welcomeQueued = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      welcomeQueued = false;
      if (!mounted ||
          scope != welcomeScope ||
          welcomeOpen ||
          ops.data?['welcomeNeedsAcknowledgment'] != true ||
          presentedWelcomes.contains(scope)) {
        return;
      }
      openWelcome();
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  Future<void> openWelcome({VoidCallback? closeDetail}) async {
    if (welcomeOpen || !mounted || ops.data == null) return;
    final openingActor = ops.actorId;
    final openingWorkspace = ops.data?['workspaceId'];
    welcomeOpen = true;
    try {
      await openSharedWelcome(
        context,
        ops,
        onPresented: (document) {
          if (ops.actorId == openingActor &&
              ops.data?['workspaceId'] == openingWorkspace) {
            presentedWelcomes.add(
              '$openingActor/$openingWorkspace/${document['importantRevision']}',
            );
          }
        },
        onWork: () {
          closeDetail?.call();
          if (mounted) {
            updateView(() {
              tab = 0;
              manualSearch.clear();
              manualQuery = '';
            });
          }
        },
      );
    } finally {
      welcomeOpen = false;
      maybeOpenWelcome();
    }
  }

  @override
  void dispose() {
    ops.removeListener(maybeOpenWelcome);
    taskPart.dispose();
    manualSearch.dispose();
    detailRevision.dispose();
    super.dispose();
  }

  String normalizeManual(String value) => value
      .toLowerCase()
      .replaceAll('결재', '결제')
      .replaceAll('메뉴얼', '매뉴얼')
      .replaceAll(RegExp(r'방법|하는\s*법|하기|어떻게|#|\s'), '');
  List<Json> get manualResults {
    final query = normalizeManual(manualQuery);
    if (query.isEmpty) return ops.rows('manualSearch');
    final words = manualQuery
        .trim()
        .split(RegExp(r'\s+'))
        .map(normalizeManual)
        .where((word) => word.isNotEmpty)
        .toList();
    final scored = <({int score, Json row})>[];
    for (final row in ops.rows('manualSearch')) {
      final title = normalizeManual('${row['title']} ${row['tapTitle']}');
      final tags = normalizeManual((row['tags'] as List? ?? []).join(' '));
      final body = normalizeManual('${row['manual']} ${row['tip']}');
      final combined = '$title$tags$body';
      if (!combined.contains(query) && !words.every(combined.contains)) {
        continue;
      }
      final score = title.contains(query)
          ? 3
          : tags.contains(query)
          ? 2
          : 1;
      scored.add((score: score, row: row));
    }
    scored.sort((a, b) => b.score.compareTo(a.score));
    return scored.map((item) => item.row).toList();
  }

  Future<void> openManual(Json row) async {
    final actor = ops.actorId;
    final workspace = ops.data?['workspaceId'];
    await showAppSheet<void>(
      context,
      builder: (_) => AppEditorScaffold(
        title: context.t('nav.manual'),
        body: ListenableBuilder(
          listenable: ops,
          builder: (context, _) {
            final selected = ops
                .rows('manualSearch')
                .where((current) => current['id'] == row['id'])
                .firstOrNull;
            if (actor != ops.actorId ||
                workspace != ops.data?['workspaceId'] ||
                selected == null) {
              return Center(
                child: Information(context.t('manual.changedTask')),
              );
            }
            return SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.large),
              child: TranslatedContent(
                ops: ops,
                kind: 'manual',
                entityId: selected['templateId'] ?? selected['tapId'],
                stepId: selected['sourceStepId'],
                source: selected,
                builder: (context, displayed) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${displayed['tapTitle']} · Task',
                      style: AppText.caption,
                    ),
                    const SizedBox(height: 8),
                    Text('${displayed['title']}', style: AppText.title),
                    const SizedBox(height: 16),
                    SelectableText(
                      '${displayed['manual']}',
                      style: AppText.body,
                    ),
                    if ('${displayed['imageUrl'] ?? ''}'.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: placePhoto(displayed['imageUrl'], ops: ops),
                      ),
                    if ('${displayed['tip'] ?? ''}'.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Text(
                          '${context.t('manual.tip')} · ${displayed['tip']}',
                        ),
                      ),
                    if ((displayed['tags'] as List? ?? []).isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Wrap(
                          spacing: 8,
                          children: [
                            for (final tag in displayed['tags'])
                              Chip(label: Text('#$tag')),
                          ],
                        ),
                      ),
                    for (final field in ['sourceUrl', 'imageUrl', 'videoUrl'])
                      if (Uri.tryParse('${displayed[field] ?? ''}')?.scheme ==
                          'https')
                        PressBounce(
                          child: TextButton.icon(
                            onPressed: () => launchUrl(
                              Uri.parse(displayed[field]),
                              mode: LaunchMode.externalApplication,
                            ),
                            icon: Icon(
                              field == 'videoUrl'
                                  ? Icons.play_circle_outline
                                  : Icons.open_in_new,
                            ),
                            label: Text(
                              field == 'sourceUrl'
                                  ? context.t('manual.photo')
                                  : field == 'imageUrl'
                                  ? context.t('manual.openPhoto')
                                  : context.t('manual.openVideo'),
                            ),
                          ),
                        ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget manualSearchBar() => Padding(
    padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1240),
        child: WaterSearch(
          controller: manualSearch,
          onChanged: (value) => updateView(() => manualQuery = value),
          onClear: () => updateView(() {
            manualSearch.clear();
            manualQuery = '';
          }),
        ),
      ),
    ),
  );

  Widget manualResultList() {
    final results = manualResults;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1240),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                context.t('store.manualCount', args: {'count': results.length}),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              if (results.isEmpty)
                Information(context.t('store.noManualResults')),
              for (final row in results)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Surface(
                    child: InkWell(
                      onTap: () => openManual(row),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${row['title']}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              'TAP · ${row['tapTitle']}',
                              style: const TextStyle(
                                color: AppColors.muted,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${row['manual']}',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if ((row['tags'] as List? ?? []).isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 7),
                                child: Text(
                                  (row['tags'] as List)
                                      .map((tag) => '#$tag')
                                      .join('  '),
                                  style: const TextStyle(
                                    color: AppColors.green,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            if ('${row['sourceUrl'] ?? ''}'.isNotEmpty)
                              const Text(
                                '사진·상세 설명 보기 · 공식 가이드',
                                style: TextStyle(
                                  color: AppColors.green,
                                  fontSize: 13,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  final Map<String, double> cart = {};
  Json? item(String id) =>
      ops.rows('items').where((i) => i['id'] == id).firstOrNull;
  String zoneName(String? id) =>
      ops.rows('zones').where((z) => z['id'] == id).firstOrNull?['name']
          as String? ??
      context.t(
        id == null || id.isEmpty
            ? 'inventory.locationUnset'
            : 'inventory.locationUnavailable',
      );
  bool pending(String id) => ops
      .rows('orders')
      .any(
        (o) =>
            o['status'] == 'ordered' &&
            (o['lines'] as List).any((l) => l['itemId'] == id),
      );
  List<Json> get gaps => ops
      .rows('shifts')
      .where((s) => s['status'] == '휴가' && s['covering'] == null)
      .toList();
  List<Json> get lowStock => ops
      .rows('items')
      .where(
        (i) =>
            InventoryReadiness(i).status == 'low' &&
            InventoryReadiness(i).orderReady &&
            !pending(i['id']),
      )
      .toList();
  String qty(dynamic value) => value is num && value == value.roundToDouble()
      ? value.toInt().toString()
      : '$value';
  String money(num value) => value.round().toString().replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
    (m) => '${m[1]},',
  );
  String time(dynamic value) {
    final date = DateTime.tryParse(
      '$value',
    )?.toUtc().add(const Duration(hours: 9));
    return date == null
        ? ''
        : '${date.month}/${date.day} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  Future<bool> act(String action, Json values) async {
    final success = await ops.act(action, values);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? context.t('store.updated')
                : ops.error ?? context.t('store.saveFailed'),
          ),
        ),
      );
    }
    return success;
  }

  void go(int value) {
    final section = {0: 'overview', 2: 'inventory', 4: 'layout'}[value];
    if (section != null) {
      openStoreDetail(section);
      return;
    }
    updateView(() => tab = value == 1 ? 0 : 2);
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: ops,
    builder: (context, _) => AppContentTransition(
      trigger: ops.data != null,
      child: ops.data == null && !ops.cloud
          ? AppLoadingScreen(error: ops.error, onRetry: () => ops.refresh())
          : Scaffold(
              appBar: BrandHeader(
                compact: ops.cloud && MediaQuery.sizeOf(context).width < 480,
                action: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (ops.cloud) ...[
                      WorkspaceMenu(ops: ops, onWelcome: () => openWelcome()),
                      const SizedBox(width: 8),
                    ],
                    PopupMenuButton<String>(
                      popUpAnimationStyle: AppMotion.dialogStyle(context),
                      key: const ValueKey('header-account-menu'),
                      enabled: !ops.busy,
                      constraints: BoxConstraints(
                        minWidth: 200,
                        maxWidth: (MediaQuery.sizeOf(context).width - 32).clamp(
                          200.0,
                          320.0,
                        ),
                      ),
                      tooltip: context.t(
                        ops.cloud ? 'store.account' : 'store.accountPreview',
                      ),
                      onSelected: (id) async {
                        if (id == 'account') {
                          await widget.onAccountPressed?.call(context);
                        } else if (id == 'welcome') {
                          await openWelcome();
                        } else if (id == 'language') {
                          await openAppLanguagePicker(context);
                        } else if (id == 'catalog') {
                          if (mounted) {
                            showAppSheet(
                              context,
                              builder: (_) => CatalogEditor(ops: ops),
                            );
                          }
                        } else {
                          cart.clear();
                          ops.selectActor(id);
                        }
                      },
                      itemBuilder: (_) => [
                        PopupMenuItem<String>(
                          key: const ValueKey('header-language-menu'),
                          value: 'language',
                          child: Text(context.t('language.title')),
                        ),
                        if (ops.data != null)
                          PopupMenuItem<String>(
                            value: 'welcome',
                            child: Text(context.t('welcome.reopen')),
                          ),
                        if (ops.data != null && ops.isLeader && !ops.readOnly)
                          PopupMenuItem<String>(
                            value: 'catalog',
                            child: Text(context.t('store.editCatalog')),
                          ),
                        if (ops.cloud)
                          PopupMenuItem<String>(
                            enabled: false,
                            child: Text(
                              context.t(
                                'store.myStoreRole',
                                args: {
                                  'role': context.t(
                                    '${ops.actor['label'] ?? ops.actor['role'] ?? ''}',
                                  ),
                                },
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        if (widget.onAccountPressed != null)
                          PopupMenuItem<String>(
                            value: 'account',
                            child: Text(
                              widget.accountEmail == null
                                  ? context.t('store.login')
                                  : context.t(
                                      'store.emailAccount',
                                      args: {'email': widget.accountEmail!},
                                    ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        if (!ops.cloud) ...[
                          PopupMenuItem<String>(
                            enabled: false,
                            child: Text(context.t('store.previewRoles')),
                          ),
                          PopupMenuItem(
                            value: 'owner',
                            child: Text('서연 · ${context.t('store.owner')}'),
                          ),
                          PopupMenuItem(
                            value: 'manager',
                            child: Text('민지 · ${context.t('store.manager')}'),
                          ),
                          PopupMenuItem(
                            value: 'cook',
                            child: Text('현우 · ${context.t('store.cook')}'),
                          ),
                          PopupMenuItem(
                            value: 'crew',
                            child: Text('지우 · ${context.t('store.crew')}'),
                          ),
                        ],
                      ],
                      child: const HeaderAccountButton(),
                    ),
                  ],
                ),
              ),
              body: ops.data == null
                  ? AppLoadingScreen(
                      error: ops.error,
                      onRetry: () => ops.refresh(),
                    )
                  : SafeArea(
                      child: Column(
                        children: [
                          if (ops.data != null) manualSearchBar(),
                          if (ops.busy) const AppLinearProgress(minHeight: 2),
                          if (ops.error != null && ops.data != null)
                            MaterialBanner(
                              content: Text(
                                ops.error!,
                                style: const TextStyle(fontSize: 13),
                              ),
                              actions: [
                                PressBounce(
                                  child: TextButton(
                                    onPressed: ops.busy
                                        ? null
                                        : () => ops.refresh(),
                                    child: Text(context.t('store.refresh')),
                                  ),
                                ),
                              ],
                            ),
                          if (tab == 0 && manualQuery.trim().isEmpty)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(24, 8, 24, 4),
                              child: Center(
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    maxWidth: 1240,
                                  ),
                                  child: SizedBox(
                                    width: double.infinity,
                                    height:
                                        48 *
                                        (MediaQuery.textScalerOf(
                                              context,
                                            ).scale(13) /
                                            13),
                                    child: ValueListenableBuilder<String?>(
                                      valueListenable: taskPart,
                                      builder: (context, selected, _) =>
                                          AppToolbarScroll(
                                            child: Row(
                                              spacing: 8,
                                              children: [
                                                AppToolbarButton(
                                                  icon: Icons.groups_outlined,
                                                  label: context.t(
                                                    'store.allParts',
                                                  ),
                                                  selected: selected == null,
                                                  onPressed: () =>
                                                      taskPart.value = null,
                                                ),
                                                const AppToolbarDivider(),
                                                for (final part
                                                    in storeParts(ops).where(
                                                      (p) =>
                                                          p['hidden'] != true,
                                                    ))
                                                  AppToolbarButton(
                                                    icon: Icons.work_outline,
                                                    label: part['name'],
                                                    selected:
                                                        selected == part['id'],
                                                    onPressed: () =>
                                                        taskPart.value =
                                                            part['id'],
                                                  ),
                                              ],
                                            ),
                                          ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          Expanded(
                            child: AppContentTransition(
                              trigger: (
                                tab,
                                manualQuery.trim().isNotEmpty,
                                ops.data == null,
                              ),
                              child: ops.data == null
                                  ? Center(
                                      child: ops.error == null
                                          ? const WorkspaceSkeleton()
                                          : PressBounce(
                                              child: OutlinedButton(
                                                onPressed: () => ops.refresh(),
                                                child: Text(
                                                  context.t('store.reconnect'),
                                                ),
                                              ),
                                            ),
                                    )
                                  : tab == 1
                                  ? ManualWorkspace(
                                      ops: ops,
                                      query: manualQuery,
                                      onClearSearch: () => updateView(() {
                                        manualSearch.clear();
                                        manualQuery = '';
                                      }),
                                    )
                                  : manualQuery.trim().isNotEmpty
                                  ? manualResultList()
                                  : tab == 2
                                  ? Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                        24,
                                        16,
                                        24,
                                        0,
                                      ),
                                      child: StaffWorkspace(
                                        ops: ops,
                                        work: widget.work,
                                      ),
                                    )
                                  : RefreshIndicator(
                                      onRefresh: () => ops.refresh(),
                                      child: SingleChildScrollView(
                                        key: ValueKey(tab),
                                        physics:
                                            const AlwaysScrollableScrollPhysics(),
                                        padding: const EdgeInsets.fromLTRB(
                                          24,
                                          12,
                                          24,
                                          24,
                                        ),
                                        child: Center(
                                          child: ConstrainedBox(
                                            constraints: BoxConstraints(
                                              maxWidth: tab == 2
                                                  ? double.infinity
                                                  : 1240,
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                ...switch (tab) {
                                                  0 => tasks(),
                                                  1 => const <Widget>[],
                                                  2 => [
                                                    StaffWorkspace(
                                                      ops: ops,
                                                      work: widget.work,
                                                    ),
                                                  ],
                                                  _ => storeHome(),
                                                },
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
              bottomNavigationBar: FloatingMenu(
                selectedIndex: tab,
                onSelected: (value) => updateView(() {
                  tab = value;
                  manualSearch.clear();
                  manualQuery = '';
                  FocusScope.of(context).unfocus();
                }),
                items: [
                  FloatingMenuItem(
                    context.t('nav.work'),
                    CupertinoIcons.checkmark_alt_circle,
                  ),
                  FloatingMenuItem(
                    context.t('nav.manual'),
                    CupertinoIcons.book,
                  ),
                  FloatingMenuItem(
                    context.t('nav.roster'),
                    CupertinoIcons.calendar,
                  ),
                  FloatingMenuItem(
                    context.t('nav.store'),
                    CupertinoIcons.square_grid_2x2,
                  ),
                ],
              ),
            ),
    ),
  );

  Widget gap([double height = 32]) => SizedBox(height: height);

  Future<void> openStoreDetail(String section) => showAppSheet<void>(
    context,
    builder: (sheetContext) => ListenableBuilder(
      listenable: Listenable.merge([ops, detailRevision]),
      builder: (context, _) => AppEditorScaffold(
        title: context.t(
          {
            'overview': '운영 현황',
            'inventory': '재고와 발주',
            'people': '크루',
            'pay': '인건비',
            'layout': '공간·장비',
          }[section]!,
        ),
        body: SingleChildScrollView(
          primary: false,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (section == 'overview')
                StoreDashboard(
                  operations: ops,
                  onWelcome: () => openWelcome(
                    closeDetail: () => Navigator.pop(sheetContext),
                  ),
                  onNavigate: (value) {
                    Navigator.pop(sheetContext);
                    go(value);
                  },
                ),
              if (section == 'overview') ...overviewHistory(),
              if (section == 'inventory') ...inventory(),
              if (section == 'people') TeamScreen(operations: ops),
              if (section == 'pay') LaborPanel(ops: ops),
              if (section == 'layout') ...floorPlan(),
            ],
          ),
        ),
      ),
    ),
  );

  Future<void> openWorkplace(String section) => section == 'hours'
      ? openWorkplaceHours(context, ops)
      : showAppSheet<void>(
          context,
          builder: (_) => WorkplaceSettings(ops: ops, section: section),
        );

  List<Widget> storeHome() {
    final profile = ops.data?['store']?['profile'] as Json? ?? {};
    final pos = profile['pos'] as Json? ?? {};
    final delivery = profile['delivery'] as Json? ?? {};
    final configuredDays = ops.data?['workplace']?['days'] as Json? ?? {};
    final openDays = [
      for (var d = 1; d <= 7; d++)
        if ((configuredDays['$d'] as List? ?? []).isNotEmpty) d,
    ];
    final hours = <String>{};
    for (final d in openDays) {
      final bands = (configuredDays['$d'] as List)
          .cast<Json>()
          .where((b) => b['custom'] != true)
          .toList();
      if (bands.isNotEmpty) {
        hours.add(
          '${bands.first['start']}–${'${bands.last['end']}'.compareTo('${bands.first['start']}') < 0 ? '다음 날 ' : ''}${bands.last['end']} · ${bands.length}교대',
        );
      }
    }
    final hoursLabel = openDays.isEmpty
        ? '영업일·시간을 설정해 주세요'
        : '${openDays.length == 7 ? '매일' : openDays.map((d) => ['월', '화', '수', '목', '금', '토', '일'][d - 1]).join('·')} · ${hours.length == 1 ? hours.single : '요일별 시간'}';
    return [
      actionCard(
        CupertinoIcons.book,
        context.t('welcome.reopen'),
        context.t('welcome.shared'),
        () => openWelcome(),
      ),
      if (ops.isOwner) ...[
        actionCard(
          CupertinoIcons.money_dollar_circle,
          '정산 설정',
          '지급 주기 · 시작일 · 반올림 · 수당',
          () => showAppSheet(
            context,
            builder: (_) => PayrollSettingsScreen(ops: ops),
          ),
        ),
        StorePreparation(
          ops: ops,
          onHours: () => openWorkplace('hours'),
          onPeople: () => openStoreDetail('people'),
          onTasks: () async {
            if (ops.canEditTasks) {
              await showAppSheet(
                context,
                builder: (_) => ManualMarketScreen(ops: ops),
              );
              if (mounted) updateView(() => tab = 1);
            } else {
              updateView(() => tab = 0);
            }
          },
          onSchedule: () => updateView(() => tab = 2),
          onMenus: () =>
              showAppSheet(context, builder: (_) => CatalogEditor(ops: ops)),
          onInventory: () => openStoreDetail('inventory'),
        ),
        gap(16),
      ],
      AttendanceCard(ops: ops),
      gap(),
      title(context.t('store.management')),
      actionCard(
        CupertinoIcons.gear,
        '매장 정보',
        '${ops.data?['store']?['name'] ?? '새 매장'} · ${storeBusinessName(ops)}',
        () => showAppFormSheet(
          context: context,
          builder: (_) => StoreProfileScreen(ops: ops),
        ),
      ),
      actionCard(
        CupertinoIcons.creditcard,
        'POS',
        pos['configured'] != true
            ? '나중에 설정'
            : pos['enabled'] == true
            ? (pos['devices'] as List? ?? [])
                  .map(
                    (d) => d['providerId'] == 'okpos'
                        ? '오케이포스'
                        : (d['customName'] as String? ?? '').isNotEmpty
                        ? d['customName']
                        : '기타 POS',
                  )
                  .join(' · ')
            : '사용 안 함',
        () => showAppFormSheet(
          context: context,
          builder: (_) => StoreProfileScreen(ops: ops, initialSection: 'pos'),
        ),
      ),
      actionCard(
        CupertinoIcons.bag,
        '배달 플랫폼',
        delivery['configured'] != true
            ? '나중에 설정'
            : delivery['enabled'] == true
            ? (delivery['platforms'] as List? ?? [])
                  .map((p) => setupPlatforms[p['providerId']] ?? '기타')
                  .join(' · ')
            : '사용 안 함',
        () => showAppFormSheet(
          context: context,
          builder: (_) =>
              StoreProfileScreen(ops: ops, initialSection: 'delivery'),
        ),
      ),
      if (ops.canEditTasks)
        actionCard(
          CupertinoIcons.book,
          '업종·기본 매뉴얼',
          '${storeBusinessName(ops)} · ${ops.rows('taskTemplates').where((t) => t['archivedAt'] == null).length} TAP',
          () => showAppFormSheet(
            context: context,
            builder: (_) => ManualMarketScreen(ops: ops, setup: true),
          ),
        ),
      actionCard(
        CupertinoIcons.clock,
        '영업시간 설정',
        hoursLabel,
        () => openWorkplace('hours'),
      ),
      actionCard(
        CupertinoIcons.person_2_square_stack,
        '파트 관리',
        storeParts(
          ops,
        ).where((p) => p['hidden'] != true).map((p) => p['name']).join(' · '),
        () => openWorkplace('parts'),
      ),
      if (ops.isOwner) ...[
        actionCard(
          CupertinoIcons.link,
          '주문처리 시스템 연결',
          ops.data?['orderBoardEnabled'] == true
              ? '보드 사용 중 · 외부 시스템 미연결'
              : '보드 꺼짐',
          () => openWorkplace('order-system'),
        ),
        actionCard(
          CupertinoIcons.person_add,
          '크루 초대',
          '코드 · QR 체험',
          () => openWorkplace('invite'),
        ),
        actionCard(
          CupertinoIcons.lock_shield,
          '직책별 권한',
          '운영 작업 권한',
          () => openWorkplace('permissions'),
        ),
        actionCard(
          CupertinoIcons.location,
          '출퇴근 인증 설정',
          '연동 상태 확인',
          () => openWorkplace('verification'),
        ),
      ],
      gap(),
      title(context.t('store.operations')),
      actionCard(
        CupertinoIcons.chart_bar,
        '운영 현황',
        '매출 · 준비품 · 사장님 기록',
        () => openStoreDetail('overview'),
      ),
      actionCard(
        CupertinoIcons.cube_box,
        '재고와 발주',
        '실사 · 데모 발주 · 입고',
        () => openStoreDetail('inventory'),
      ),
      if (ops.isLeader)
        actionCard(
          CupertinoIcons.slider_horizontal_3,
          '매장 특성·공통 장소',
          '매장 특성 · 공통 장소 연결',
          () => openManualSetup(context, ops),
        ),
      actionCard(
        CupertinoIcons.map,
        '공간·장비',
        '층·구역 · 사진 · 위치 안내',
        () => openStoreDetail('layout'),
      ),
      if (ops.isOwner)
        actionCard(
          CupertinoIcons.money_dollar_circle,
          '인건비',
          '주간 예상 · 수당 확인',
          () => openStoreDetail('pay'),
        ),
      actionCard(
        CupertinoIcons.person_2,
        '크루',
        '크루 정보 · 근무',
        () => openStoreDetail('people'),
      ),
      if (ops.isLeader)
        actionCard(
          CupertinoIcons.square_list,
          '메뉴·재료 편집',
          '매장 메뉴와 재료 등록',
          () => showAppSheet(context, builder: (_) => CatalogEditor(ops: ops)),
        ),
      if (ops.isLeader &&
          (pos['enabled'] == true || delivery['enabled'] == true)) ...[
        title('설정에 맞는 업무'),
        const Information(
          '사용 중인 주문 도구에 맞춰 접수·포장·전달 확인 업무를 살펴보세요. 가져올 양식은 직접 선택할 수 있어요.',
        ),
        PressBounce(
          child: OutlinedButton.icon(
            onPressed: () => showAppSheet(
              context,
              builder: (_) => RecommendedTapsScreen(ops: ops),
            ),
            icon: const Icon(CupertinoIcons.list_bullet),
            label: const Text('업무 양식 미리보기·선택'),
          ),
        ),
      ],
    ];
  }

  Widget title(String text) => Padding(
    padding: const EdgeInsets.only(top: 16, bottom: 12),
    child: Semantics(
      header: true,
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          color: AppColors.ink,
        ),
      ),
    ),
  );
  Widget small(String text) => Text(
    text,
    style: const TextStyle(fontSize: 13, height: 1.65, color: AppColors.muted),
  );
  Widget badge(String text, {Color color = AppColors.lime}) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.green,
      ),
    ),
  );
  Widget actionCard(
    IconData icon,
    String heading,
    String detail,
    VoidCallback onTap, {
    Color color = AppColors.surface,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: PressBounce(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: appCardShadow,
        ),
        child: Material(
          color: color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(icon, size: 21, color: AppColors.green),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.t(heading),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(detail, style: AppText.caption),
                      ],
                    ),
                  ),
                  const Icon(CupertinoIcons.chevron_right, size: 17),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );

  List<Widget> overviewHistory() => [
    if (ops.isOwner && ops.data?['privateSummary']?['note'] != null) ...[
      gap(),
      title('매장 기록'),
      Text('${ops.data!['privateSummary']['note']}'),
    ],
    title(context.t('store.sharedUpdates')),
    if (ops.rows('activity').isEmpty)
      const Information('아직 새 소식이 없어요. 재고나 할 일을 확인하면 누가 했는지 이곳에 남아요.'),
    for (final event in ops.rows('activity').take(4))
      Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              CupertinoIcons.checkmark_circle,
              size: 16,
              color: AppColors.green,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(event['message'], style: const TextStyle(fontSize: 13)),
                  small('${event['actor']['name']} · ${time(event['at'])}'),
                ],
              ),
            ),
          ],
        ),
      ),
  ];

  List<Widget> tasks() => [
    TapWorkspace(
      key: ValueKey(ops.actorId),
      ops: ops,
      partFilter: taskPart,
      onStock: (task) async {
        final stock = item(task['itemId']);
        if (stock != null) await checkStock(stock, taskId: task['id']);
      },
    ),
  ];

  List<Widget> inventory() => [
    if (ops.isLeader && !ops.readOnly)
      Align(
        alignment: Alignment.centerLeft,
        child: PressBounce(
          child: OutlinedButton.icon(
            onPressed: ops.busy
                ? null
                : () => showAppSheet(
                    context,
                    builder: (_) => CatalogEditor(ops: ops),
                  ),
            icon: const Icon(Icons.edit_outlined),
            label: const Text('재료·메뉴 편집'),
          ),
        ),
      ),
    if (ops.isLeader) ...[
      Surface(
        color: AppColors.lime.withValues(alpha: .5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '보충 확인 ${lowStock.length}개 · 담은 재료 ${cart.length}개',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            gap(8),
            small('공급처별로 나눠 정리해요. 결제·문자·카카오 전송은 없는 체험이에요.'),
            gap(12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                PressBounce(
                  child: OutlinedButton(
                    onPressed: lowStock.isEmpty
                        ? null
                        : () => updateView(() {
                            for (final i in lowStock) {
                              cart[i['id']] = (i['orderQuantity'] as num)
                                  .toDouble();
                            }
                          }),
                    child: const Text('부족한 재료 담기'),
                  ),
                ),
                PressBounce(
                  child: FilledButton(
                    onPressed: cart.isEmpty || ops.busy ? null : reviewOrder,
                    child: Text('발주함 보기 (${cart.length})'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      gap(18),
    ] else ...[
      const Information('재고 수량 확인과 보충 요청은 누구나 할 수 있어요. 발주는 사장님·매니저가 확인해요.'),
      gap(),
    ],
    for (final i in ops.rows('items')) ...[
      Surface(
        padding: const EdgeInsets.all(17),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  CupertinoIcons.cube_box,
                  size: 24,
                  color: AppColors.muted,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        i['name'],
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      small('${zoneName(i['zone'])} · ${i['supplier']}'),
                    ],
                  ),
                ),
                Text(
                  '${qty(i['quantity'])}${i['unit']}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            gap(12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                badge(
                  pending(i['id'])
                      ? context.t('inventory.awaitingReceipt')
                      : context.t('inventory.${InventoryReadiness(i).status}'),
                  color: InventoryReadiness(i).status == 'low'
                      ? const Color(0xFF392E20)
                      : AppColors.lime,
                ),
                if (i['restockRequestedBy'] != null)
                  badge(
                    '${i['restockRequestedBy']['name']}님 보충 요청',
                    color: AppColors.paper,
                  ),
              ],
            ),
            gap(8),
            small(
              i['checkedBy'] == null
                  ? '아직 실물 수량을 확인하지 않았어요'
                  : '${i['checkedBy']['name']}님 · ${time(i['lastCheckedAt'])} 수량 확인',
            ),
            small(
              '기준 ${qty(i['minimum'])}${i['unit']} 이하 · 발주 ${i['reviewDays']}일 후 확인',
            ),
            if (i['lastOrderedAt'] != null)
              small(
                i['reviewState'] == 'completed'
                    ? '이번 발주 확인 완료 · ${i['reviewCompletedBy']?['name'] ?? ''}님 ${time(i['reviewCompletedAt'])}'
                    : '확인 예정 ${nextCheck(i)} · 중간에 수량을 확인해도 날짜는 유지돼요',
              ),
            gap(10),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: [
                PressBounce(
                  child: OutlinedButton(
                    onPressed: ops.busy ? null : () => checkStock(i),
                    child: const Text('수량 확인'),
                  ),
                ),
                if (ops.isLeader)
                  FilledButton.tonal(
                    onPressed:
                        pending(i['id']) || !InventoryReadiness(i).orderReady
                        ? null
                        : () => updateView(() {
                            if (cart.containsKey(i['id'])) {
                              cart.remove(i['id']);
                            } else {
                              cart[i['id']] = (i['orderQuantity'] as num)
                                  .toDouble();
                            }
                          }),
                    child: Text(
                      cart.containsKey(i['id']) ? '담았어요 ✓' : '발주함 담기',
                    ),
                  )
                else
                  PressBounce(
                    child: TextButton(
                      onPressed: ops.busy || i['restockRequestedBy'] != null
                          ? null
                          : () => act('request_restock', {'itemId': i['id']}),
                      child: const Text('보충 요청'),
                    ),
                  ),
                if (ops.isLeader)
                  PressBounce(
                    child: TextButton(
                      onPressed: ops.busy ? null : () => reviewPolicy(i),
                      child: const Text('확인 기준'),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
      gap(12),
    ],
    title('발주와 입고 내역'),
    if (ops.rows('orders').isEmpty)
      const Information('아직 발주 내역이 없어요. 발주함에서 수량을 확인한 뒤 한 번에 데모 발주해 보세요.'),
    for (final order in ops.rows('orders').take(10)) ...[
      Surface(
        padding: const EdgeInsets.all(17),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            badge(order['status'] == 'ordered' ? '데모 발주 · 입고 대기' : '입고 확인 완료'),
            gap(9),
            Text(
              (order['lines'] as List)
                  .map(
                    (l) =>
                        '${l['name']} · ${context.t('receipt.progress', args: {'received': qty(receivedQuantity(order, l)), 'ordered': qty(l['quantity']), 'unit': l['unit'], 'remaining': qty((l['quantity'] as num) - receivedQuantity(order, l))})}',
                  )
                  .join('\n'),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            gap(8),
            small(
              '${order['placedBy']['name']}님 · ${time(order['createdAt'])}',
            ),
            if (order['total'] != null)
              small('예시 금액 ${money(order['total'])}원 · 실제 청구 없음'),
            if (order['receivedBy'] != null)
              small(
                '${order['receivedBy']['name']}님이 ${time(order['receivedAt'])} 입고 확인',
              ),
            for (final receipt in (order['receiptHistory'] as List? ?? []))
              small(
                context.t(
                  'receipt.batch',
                  args: {
                    'name': receipt['receivedBy']['name'],
                    'time': time(receipt['receivedAt']),
                    'quantity': (receipt['lines'] as List)
                        .map(
                          (line) =>
                              '${line['name']} ${qty(line['quantity'])}${line['unit']}',
                        )
                        .join(' · '),
                  },
                ),
              ),
            if (ops.isLeader && order['status'] == 'ordered') ...[
              gap(10),
              PressBounce(
                child: OutlinedButton(
                  onPressed: ops.busy ? null : () => receiveOrder(order),
                  child: Text(context.t('receipt.save')),
                ),
              ),
            ],
          ],
        ),
      ),
      gap(10),
    ],
  ];

  String nextCheck(Json i) {
    final ordered = DateTime.parse(i['lastOrderedAt']);
    return time(
      i['reviewDueAt'] ??
          ordered.add(Duration(days: i['reviewDays'] as int)).toIso8601String(),
    );
  }

  List<Widget> team() => [
    const PageHeading(
      'OUR LITTLE TEAM',
      '서로의 빈자리를 알아요 🤝',
      '근무와 공석은 함께, 개인 사유와 급여는 비공개로.',
    ),
    Surface(
      color: const Color(0xFF392E20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '오늘 공석 ${gaps.length}곳',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          gap(7),
          small('대체 가능 표시만으로 근무가 확정되지는 않아요. 사장님·매니저 확인 후 함께 반영돼요.'),
        ],
      ),
    ),
    gap(18),
    for (final shift in ops.rows('shifts')) ...[
      Surface(
        padding: const EdgeInsets.all(17),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.lime.withValues(alpha: .6),
                  child: Text(shift['person'].toString().substring(0, 1)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${shift['person']} · ${shift['role']}',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      small(shift['time']),
                    ],
                  ),
                ),
                badge(
                  shift['status'],
                  color: shift['status'] == '휴가'
                      ? const Color(0xFF392E20)
                      : AppColors.lime,
                ),
              ],
            ),
            if (shift['status'] == '휴가') ...[
              gap(12),
              small(
                shift['covering'] == null
                    ? '아직 대체 근무자가 없어요'
                    : '✓ ${shift['covering']['name']}님이 이 시간을 함께해요',
              ),
              if (shift['covering'] == null) ...[
                gap(8),
                PressBounce(
                  child: OutlinedButton(
                    onPressed:
                        ops.busy ||
                            ops
                                .rows('coverRequests')
                                .any(
                                  (r) =>
                                      r['shiftId'] == shift['id'] &&
                                      r['actor']['id'] == ops.actorId &&
                                      r['status'] == 'pending',
                                )
                        ? null
                        : () => act('offer_cover', {'shiftId': shift['id']}),
                    child: const Text('저 이 시간 가능해요 🙋'),
                  ),
                ),
              ],
            ],
            if (shift['updatedBy'] != null)
              small(
                '${shift['updatedBy']['name']}님이 ${time(shift['updatedAt'])} 변경',
              ),
            if (ops.isLeader)
              PressBounce(
                child: TextButton(
                  onPressed: ops.busy ? null : () => changeShift(shift),
                  child: Text(shift['status'] == '휴가' ? '근무로 변경' : '휴가로 변경'),
                ),
              ),
          ],
        ),
      ),
      gap(10),
    ],
    if (ops.isLeader) ...[
      title('🙋 대체 근무 확인'),
      if (!ops.rows('coverRequests').any((r) => r['status'] == 'pending'))
        const Information('확인을 기다리는 신청이 없어요.'),
      for (final request
          in ops.rows('coverRequests').where((r) => r['status'] == 'pending'))
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Surface(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${request['actor']['name']}님이 가능해요'),
                small(
                  '${ops.rows('shifts').where((s) => s['id'] == request['shiftId']).first['time']} · 근무 가능 여부를 확인해 주세요',
                ),
                gap(8),
                PressBounce(
                  child: FilledButton(
                    onPressed: ops.busy
                        ? null
                        : () =>
                              act('assign_cover', {'requestId': request['id']}),
                    child: const Text('대체 근무 확정'),
                  ),
                ),
              ],
            ),
          ),
        ),
    ],
    gap(),
    const Information(
      '함께 보기: 이름·담당·근무 시간·휴가 여부·대체 근무\n비공개: 휴가 사유·급여·사장님 메모\n지금은 샘플 근무표이며 급여·근태·법정 서류는 연동 전이에요.',
    ),
  ];

  List<Widget> floorPlan() => [FloorPlanView(operations: ops)];

  Future<void> checkStock(Json i, {String? taskId}) async {
    final controller = TextEditingController(text: qty(i['quantity']));
    final values = await formDialog(
      '실제로 몇 ${i['unit']} 있나요?',
      [
        small('${i['name']} · ${zoneName(i['zone'])}'),
        gap(),
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: '현재 수량 (${i['unit']})',
            border: const OutlineInputBorder(),
          ),
        ),
        gap(),
        small('${ops.actor['name']}님이 확인한 기록으로 함께 보여요.'),
      ],
      () {
        final value = double.tryParse(controller.text);
        return value != null && value.isFinite && value >= 0 && value <= 100000
            ? {'quantity': value}
            : null;
      },
    );
    if (values != null) {
      await act(taskId == null ? 'check_stock' : 'complete_task', {
        ...values,
        if (taskId != null) 'taskId': taskId else 'itemId': i['id'],
      });
    }
    controller.dispose();
  }

  Future<void> reviewPolicy(Json i) async {
    final days = TextEditingController(text: '${i['reviewDays']}');
    final minimum = TextEditingController(text: qty(i['minimum']));
    final values = await formDialog(
      '재고 확인 기준',
      [
        small(
          '${i['name']} · 마지막 발주일에서 정해진 일수 뒤 한 번 확인해요. 중간 수량 확인은 예정일을 미루지 않아요.',
        ),
        gap(),
        TextField(
          controller: days,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: '발주 며칠 후 확인할까요? (1~90일)',
          ),
        ),
        gap(),
        TextField(
          controller: minimum,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(labelText: '보충 기준 (${i['unit']} 이하)'),
        ),
      ],
      () {
        final d = int.tryParse(days.text);
        final m = double.tryParse(minimum.text);
        return d != null &&
                d >= 1 &&
                d <= 90 &&
                m != null &&
                m.isFinite &&
                m >= 0 &&
                m <= 100000
            ? {'reviewDays': d, 'minimum': m}
            : null;
      },
    );
    if (values != null) {
      await act('review_policy', {'itemId': i['id'], ...values});
    }
    days.dispose();
    minimum.dispose();
  }

  Future<void> reviewOrder() async {
    final entries = cart.entries
        .where(
          (e) =>
              item(e.key) != null &&
              InventoryReadiness(item(e.key)!).orderReady &&
              !pending(e.key),
        )
        .toList();
    if (entries.isEmpty) {
      updateView(cart.clear);
      return;
    }
    final controllers = {
      for (final e in entries) e.key: TextEditingController(text: qty(e.value)),
    };
    final suppliers = entries
        .map((e) => item(e.key)!['supplier'] as String)
        .toSet();
    final values = await formDialog(
      '모아서 데모 발주',
      [
        const Information(
          '실제 공급처로 전송하거나 결제하지 않아요. 발주 기록만 생성하며 입고 확인 전에는 재고가 늘지 않아요.',
        ),
        gap(),
        for (final supplier in suppliers) ...[
          title(supplier),
          for (final e in entries.where(
            (e) => item(e.key)!['supplier'] == supplier,
          ))
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: TextField(
                controller: controllers[e.key],
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText:
                      '${item(e.key)!['name']} (${item(e.key)!['unit']})',
                  helperText: '단가 ${money(item(e.key)!['price'])}원 · 예시',
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
        ],
        small('선택한 모든 공급처의 항목을 한 번에 기록해요.'),
      ],
      () {
        final lines = <Json>[];
        for (final e in entries) {
          final value = double.tryParse(controllers[e.key]!.text);
          if (value == null ||
              !value.isFinite ||
              value <= 0 ||
              value > 100000) {
            return null;
          }
          lines.add({'itemId': e.key, 'quantity': value});
        }
        return {'lines': lines};
      },
      confirm: '한 번에 데모 발주',
    );
    if (values != null && await act('place_order', values) && mounted) {
      updateView(cart.clear);
    }
    for (final c in controllers.values) {
      c.dispose();
    }
  }

  // Keep an uncertain submission across closing/reopening this screen's dialog.
  // Its identity and quantities must not change until the server confirms it.
  final pendingReceipts = <String, Json>{};
  num receivedQuantity(Json order, dynamic line) =>
      line['receivedQuantity'] as num? ??
      (order['status'] == 'received' ? line['quantity'] as num : 0);

  Future<void> receiveOrder(Json order) async {
    final identity = '${ops.workspaceId}/${ops.actorId}/${order['id']}';
    final openingActor = ops.actorId;
    final openingWorkspace = ops.workspaceId;
    final lines = (order['lines'] as List).cast<Json>();
    final controllers = <String, TextEditingController>{};
    final pending = pendingReceipts[identity];
    for (final line in lines) {
      final prior = (pending?['lines'] as List? ?? [])
          .where((value) => value['itemId'] == line['itemId'])
          .firstOrNull;
      controllers[line['itemId']] = TextEditingController(
        text: qty(prior?['quantity'] ?? 0),
      );
    }
    bool saving = false;
    String? failure;
    final route = DialogRoute<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, update) {
          final locked = pendingReceipts.containsKey(identity);
          return PopScope(
            canPop: !saving,
            child: AlertDialog(
              title: Text(context.t('receipt.title')),
              content: SizedBox(
                width: 400,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      small(
                        context.t(
                          locked ? 'receipt.retryHelp' : 'receipt.help',
                        ),
                      ),
                      gap(),
                      for (final line in lines)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: TextField(
                            key: ValueKey('receipt-${line['itemId']}'),
                            controller: controllers[line['itemId']],
                            enabled: !saving && !locked,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: InputDecoration(
                              labelText: context.t(
                                'receipt.quantity',
                                args: {
                                  'name': line['name'],
                                  'unit': line['unit'],
                                },
                              ),
                              helperText: context.t(
                                'receipt.limit',
                                args: {
                                  'remaining': qty(
                                    (line['quantity'] as num) -
                                        receivedQuantity(order, line),
                                  ),
                                  'unit': line['unit'],
                                },
                              ),
                              border: const OutlineInputBorder(),
                            ),
                          ),
                        ),
                      if (failure != null)
                        Text(
                          failure!,
                          style: const TextStyle(color: Colors.red),
                        ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: saving ? null : () => Navigator.pop(dialogContext),
                  child: Text(context.t('common.close')),
                ),
                FilledButton(
                  onPressed: saving || ops.readOnly
                      ? null
                      : () async {
                          if (ops.actorId != openingActor ||
                              ops.workspaceId != openingWorkspace) {
                            Navigator.pop(dialogContext);
                            return;
                          }
                          Json? request = pendingReceipts[identity];
                          if (request == null) {
                            final received = <Json>[];
                            for (final line in lines) {
                              final value = double.tryParse(
                                controllers[line['itemId']]!.text,
                              );
                              final remaining =
                                  (line['quantity'] as num) -
                                  receivedQuantity(order, line);
                              if (value == null ||
                                  !value.isFinite ||
                                  value < 0 ||
                                  value > 100000 ||
                                  value > remaining + 1e-10) {
                                update(
                                  () => failure = context.t('receipt.invalid'),
                                );
                                return;
                              }
                              received.add({
                                'itemId': line['itemId'],
                                'quantity': value,
                              });
                            }
                            if (!received.any(
                              (line) => (line['quantity'] as num) > 0,
                            )) {
                              update(
                                () => failure = context.t('receipt.invalid'),
                              );
                              return;
                            }
                            request = {
                              'orderId': order['id'],
                              'receiptId': List.generate(
                                16,
                                (_) => Random.secure()
                                    .nextInt(256)
                                    .toRadixString(16)
                                    .padLeft(2, '0'),
                              ).join(),
                              'lines': received,
                            };
                            pendingReceipts[identity] = request;
                          }
                          update(() {
                            saving = true;
                            failure = null;
                          });
                          final success = await ops.act(
                            'receive_order',
                            request,
                          );
                          if (!dialogContext.mounted) return;
                          if (success) {
                            pendingReceipts.remove(identity);
                            Navigator.pop(dialogContext);
                          } else {
                            // Only an unknown response requires preserving the exact
                            // submitted body. A definite rejection is safe to edit.
                            if (!locked &&
                                ops.actionFailure?['code'] !=
                                    'WRITE_RESULT_UNKNOWN') {
                              pendingReceipts.remove(identity);
                            }
                            update(() {
                              saving = false;
                              failure =
                                  ops.error ?? context.t('store.saveFailed');
                            });
                          }
                        },
                  child: Text(
                    context.t(locked ? 'receipt.retry' : 'receipt.save'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
    await Navigator.of(context).push(route);
    await route.completed;
    for (final controller in controllers.values) {
      controller.dispose();
    }
  }

  Future<void> changeShift(Json shift) async {
    final status = shift['status'] == '휴가' ? '근무' : '휴가';
    final result = await formDialog(
      '$status로 변경할까요?',
      [
        Text('${shift['person']}님 · ${shift['time']}'),
        gap(),
        small(
          '이 변경은 모두에게 보여요. 기존 대체 배정·대기 신청은 해제되므로 팀과 먼저 확인해 주세요. 개인 휴가 사유는 입력하지 않아요.',
        ),
      ],
      () => {'shiftId': shift['id'], 'status': status},
      confirm: '팀에 반영',
    );
    if (result != null) await act('update_shift', result);
  }

  Future<Json?> formDialog(
    String heading,
    List<Widget> children,
    Json? Function() collect, {
    String confirm = '확인하고 저장',
  }) async {
    String? validation;
    final formRevision = ops.data!['revision'];
    final dialogRoute = DialogRoute<Json>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, update) => AlertDialog(
          title: Text(
            heading,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          content: SizedBox(
            width: 400,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...children,
                  if (validation != null) ...[
                    gap(),
                    Text(
                      validation!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            PressBounce(
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('닫기'),
              ),
            ),
            PressBounce(
              child: FilledButton(
                onPressed: ops.readOnly
                    ? null
                    : () {
                        final values = collect();
                        if (values == null) {
                          update(() => validation = '이름이나 수량의 입력 범위를 확인해 주세요.');
                        } else {
                          Navigator.pop(context, {
                            ...values,
                            'revision': formRevision,
                          });
                        }
                      },
                child: Text(ops.readOnly ? '미리보기 · 저장 불가' : confirm),
              ),
            ),
          ],
        ),
      ),
    );
    final result = await Navigator.of(context).push(dialogRoute);
    // Keep field controllers alive until the closing transition unmounts them.
    await dialogRoute.completed;
    return result;
  }
}
