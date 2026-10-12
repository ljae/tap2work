import 'package:flutter/material.dart';
import '../state/operations_controller.dart';
import '../domain/manual_categories.dart';
import '../l10n/app_localizations.dart';
import '../l10n/manual_text_scope.dart';
import 'components.dart';
import 'manual_hierarchy.dart';

/// A synthetic, read-only configuration. Selection changes only the import basket.
class ManualExampleScreen extends StatefulWidget {
  const ManualExampleScreen({
    super.key,
    required this.profile,
    required this.entries,
    this.initialSelected = const {},
    this.canSelect = true,
  });
  final Json profile;
  final List<Json> entries;
  final Set<String> initialSelected;
  final bool canSelect;
  @override
  State<ManualExampleScreen> createState() => _ManualExampleScreenState();
}

class _ManualExampleScreenState extends State<ManualExampleScreen> {
  late final selected = {...widget.initialSelected};
  String? category, folder, tapId, stepId;
  int pane = 0;
  DateTime date = DateTime(2026, 10, 12);
  final history =
      <({String? category, String? folder, String? tap, String? step})>[];
  List<Json> get entries => widget.entries
      .where((e) => e['knowledge']?['exampleStoreId'] == widget.profile['id'])
      .toList();
  Json? get tap => entries.where((e) => e['sourceId'] == tapId).firstOrNull;
  Json? get step => (tap?['steps'] as List? ?? [])
      .whereType<Json>()
      .where((s) => s['id'] == stepId)
      .firstOrNull;
  String display(dynamic value) => manualDisplayText(context, '${value ?? ''}');
  void openTap(Json entry, {bool remember = false}) => setState(() {
    if (remember) {
      history.add((
        category: category,
        folder: folder,
        tap: tapId,
        step: stepId,
      ));
    }
    category = manualCategoryOf(entry);
    folder = entry['knowledge']?['exampleFolder'];
    tapId = entry['sourceId'];
    stepId = null;
    pane = 0;
  });
  void back() => setState(() {
    if (history.isNotEmpty) {
      final old = history.removeLast();
      category = old.category;
      folder = old.folder;
      tapId = old.tap;
      stepId = old.step;
    } else if (stepId != null) {
      stepId = null;
    } else if (tapId != null) {
      tapId = null;
    } else if (folder != null) {
      folder = null;
    } else {
      category = null;
    }
  });
  Widget title(String value) => Padding(
    padding: const EdgeInsets.only(top: 24, bottom: 12),
    child: Text(value, style: AppText.section),
  );
  Widget selectBox(Json entry) => Checkbox(
    semanticLabel:
        '${context.t('manual.market.exampleImport')} · ${display(entry['title'])}',
    value: selected.contains(entry['sourceId']),
    onChanged:
        !widget.canSelect ||
            (entry['installed'] as List? ?? []).any(
              (e) => e['mode'] == 'linked',
            )
        ? null
        : (value) => setState(() {
            if (value == true) {
              selected.add(entry['sourceId']);
            } else {
              selected.remove(entry['sourceId']);
            }
          }),
  );
  Widget tapCard(Json entry, {String? caption}) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Surface(
      padding: const EdgeInsets.all(8),
      child: ListTile(
        leading: selectBox(entry),
        title: Text(
          display(entry['title']),
          style: AppText.body.copyWith(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          caption ?? display(entry['knowledge']?['cadenceHint']),
          style: AppText.caption,
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => openTap(entry),
      ),
    ),
  );
  List<Widget> get metadata => [
    Text(
      '${entries.length} TAP · ${entries.fold<int>(0, (n, e) => n + (e['steps'] as List).length)} ${context.t('manual.structure.section')}',
      style: AppText.section,
    ),
    const SizedBox(height: 8),
    Text(context.t('manual.market.aiDraft'), style: AppText.caption),
    const SizedBox(height: 16),
  ];
  Widget structure() {
    final current = tap, currentStep = step;
    final filtered = entries
        .where((e) => category == null || manualCategoryOf(e) == category)
        .toList();
    final names = {
      for (final e in filtered) '${e['knowledge']['exampleFolder']}',
    };
    final path = ManualHierarchyPath(
      compact: folder == null,
      folder: folder == null ? null : display(folder),
      tap: current == null ? null : display(current['title']),
      task: currentStep == null ? null : display(currentStep['title']),
      reference: [
        'startup',
        'recipe',
        'reference',
      ].contains(current == null ? category : manualCategoryOf(current)),
      onFolder: () => setState(() {
        folder = null;
        tapId = null;
        stepId = null;
        history.clear();
      }),
      onTap: folder == null
          ? null
          : () => setState(() {
              tapId = null;
              stepId = null;
              history.clear();
            }),
      onTask: current == null
          ? null
          : () => setState(() {
              stepId = null;
            }),
    );
    final children = <Widget>[
      if (compactNavigation) ...metadata,
      path,
      const SizedBox(height: 16),
    ];
    if (folder != null || tapId != null || history.isNotEmpty) {
      children.add(
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: back,
            icon: const Icon(Icons.arrow_back),
            label: Text(context.t('common.previous')),
          ),
        ),
      );
    }
    if (currentStep != null) {
      children.addAll([
        Text(display(currentStep['title']), style: AppText.title),
        const SizedBox(height: 16),
        Text(display(currentStep['manual']), style: AppText.body),
        const SizedBox(height: 16),
        if ((currentStep['tip'] ?? '').isNotEmpty)
          Information(display(currentStep['tip'])),
      ]);
    } else if (current != null) {
      final policy = (widget.profile['tapSettings'] as List)
          .whereType<Json>()
          .where((p) => p['sourceId'] == current['sourceId'])
          .firstOrNull;
      children.addAll([
        Text(display(current['title']), style: AppText.title),
        const SizedBox(height: 8),
        Text(display(current['summary']), style: AppText.caption),
        const SizedBox(height: 16),
      ]);
      if (policy != null) children.add(policyCard(policy));
      for (final action in (current['steps'] as List).cast<Json>()) {
        children.add(
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Surface(
              padding: const EdgeInsets.all(8),
              child: ListTile(
                leading: Icon(
                  [
                        'startup',
                        'recipe',
                        'reference',
                      ].contains(manualCategoryOf(current))
                      ? Icons.article_outlined
                      : Icons.checklist_outlined,
                  color: AppColors.green,
                ),
                key: ValueKey('example-action-${action['id']}'),
                title: Text(display(action['title']), style: AppText.body),
                subtitle: Text(context.t('manual.structure.open')),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => setState(() => stepId = action['id']),
              ),
            ),
          ),
        );
      }
      final related = (current['knowledge']?['relatedSourceIds'] as List? ?? [])
          .whereType<String>();
      if (related.isNotEmpty) {
        children.add(title(context.t('example.related')));
        for (final id in related) {
          final doc = entries.where((e) => e['sourceId'] == id).firstOrNull;
          if (doc != null) {
            children.add(
              ListTile(
                leading: const Icon(Icons.menu_book_outlined),
                title: Text(display(doc['title'])),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => openTap(doc, remember: true),
              ),
            );
          }
        }
      }
    } else if (folder != null) {
      children.add(Text(display(folder), style: AppText.title));
      children.add(const SizedBox(height: 16));
      children.addAll(
        filtered
            .where((e) => e['knowledge']?['exampleFolder'] == folder)
            .map(tapCard),
      );
    } else {
      for (final name in names) {
        final group = filtered
            .where((e) => e['knowledge']?['exampleFolder'] == name)
            .toList();
        children.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Surface(
              padding: const EdgeInsets.all(8),
              child: ListTile(
                leading: const Icon(
                  Icons.folder_outlined,
                  color: AppColors.green,
                ),
                title: Text(
                  display(name),
                  style: AppText.body.copyWith(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  '${group.length} TAP · ${group.fold<int>(0, (n, e) => n + (e['steps'] as List).length)} ${context.t('manual.structure.section')}',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => setState(() => folder = name),
              ),
            ),
          ),
        );
      }
    }
    return ListView(
      key: PageStorageKey('example/$category/$folder/$tapId/$stepId'),
      padding: const EdgeInsets.all(24),
      children: children,
    );
  }

  Widget policyCard(Json policy) {
    final p = (widget.profile['parts'] as List)
        .whereType<Json>()
        .where((p) => p['id'] == policy['partId'])
        .firstOrNull;
    final bands = (widget.profile['bands'] as List).whereType<Json>().where(
      (b) => (policy['timeBandIds'] as List).contains(b['id']),
    );
    final settings = policy['settings'] as Json;
    return Surface(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.t('example.policy'), style: AppText.section),
          const SizedBox(height: 8),
          Text(display(p?['name']), style: AppText.body),
          Text(
            settings['usage'] == 'event'
                ? context.t('example.trigger')
                : settings['usage'] == 'reference'
                ? context.t('manual.structure.reference')
                : bands
                      .map(
                        (b) =>
                            '${display(b['name'])} ${b['start']}–${b['end']}',
                      )
                      .join(' · '),
            style: AppText.caption,
          ),
          if (settings['recurrence']?['mode'] != 'daily')
            Text(
              display(
                entries
                    .where((e) => e['sourceId'] == policy['sourceId'])
                    .firstOrNull?['knowledge']?['cadenceHint'],
              ),
              style: AppText.caption,
            ),
        ],
      ),
    );
  }

  Widget setup() {
    final profile = widget.profile, hours = profile['hours'];
    return ListView(
      key: const PageStorageKey('example/setup'),
      padding: const EdgeInsets.all(24),
      children: [
        if (compactNavigation) ...metadata,
        Information(display(profile['notice'])),
        title(context.t('example.hours')),
        Surface(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${hours['open']}–${hours['close']}', style: AppText.title),
              Text(
                '${display('브레이크·교대')} ${hours['breakStart']}–${hours['breakEnd']}',
                style: AppText.caption,
              ),
              for (final band in (profile['bands'] as List).cast<Json>())
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    '${display(band['name'])} · ${band['start']}–${band['end']}',
                    style: AppText.body,
                  ),
                ),
            ],
          ),
        ),
        title(context.t('example.parts')),
        for (final part in (profile['parts'] as List).cast<Json>())
          ListTile(
            leading: const Icon(Icons.groups_outlined),
            title: Text(display(part['name'])),
            subtitle: Text(display(part['description'])),
          ),
        for (final role in (profile['roles'] as List).cast<Json>())
          ListTile(
            leading: const Icon(Icons.badge_outlined),
            title: Text(display(role['name'])),
            subtitle: Text(display(role['description'])),
          ),
        title(context.t('example.staffing')),
        for (final needs in (profile['staffing'] as List).cast<Json>())
          ListTile(
            title: Text(
              display(
                (profile['bands'] as List)
                    .where((b) => b['id'] == needs['timeBandId'])
                    .first['name'],
              ),
            ),
            subtitle: Text(
              (needs['parts'] as Json).entries
                  .map(
                    (e) =>
                        '${display((profile['parts'] as List).where((p) => p['id'] == e.key).first['name'])} ${e.value}',
                  )
                  .join(' · '),
            ),
          ),
        title(context.t('example.menus')),
        for (final menu in (profile['menus'] as List).cast<Json>())
          ListTile(
            leading: const Icon(Icons.restaurant_menu_outlined),
            title: Text(display(menu['name'])),
            subtitle: Text(display(menu['portion'])),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              final entry = entries
                  .where((e) => e['sourceId'] == menu['recipeSourceId'])
                  .firstOrNull;
              if (entry != null) openTap(entry);
            },
          ),
        title(context.t('example.places')),
        ExampleLayout(profile: profile),
        const SizedBox(height: 12),
        Text(
          context.t('example.capacity', args: {'seats': profile['capacity']}),
          style: AppText.caption,
        ),
        for (final place in (profile['places'] as List).cast<Json>())
          ListTile(
            leading: Icon(
              place['type'] == 'table'
                  ? Icons.table_restaurant_outlined
                  : Icons.place_outlined,
            ),
            title: Text(display(place['name'])),
            subtitle: Text(display(place['description'])),
          ),
        title(context.t('manual.category.description.startup')),
        for (final standard in (profile['standards'] as List).cast<Json>())
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Surface(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(display(standard['name']), style: AppText.section),
                  const SizedBox(height: 8),
                  Text(display(standard['value']), style: AppText.body),
                ],
              ),
            ),
          ),
      ],
    );
  }

  bool scheduled(Json policy) {
    final settings = policy['settings'] as Json;
    if (settings['enabled'] != true || settings['usage'] == 'reference') {
      return false;
    }
    if (!(widget.profile['hours']['openDays'] as List).contains(date.weekday)) {
      return false;
    }
    if (settings['usage'] == 'event') {
      return date == DateTime(2026, 10, 12) &&
          (widget.profile['exampleDay']['events'] as List).any(
            (e) => e['sourceId'] == policy['sourceId'],
          );
    }
    final recurrence = settings['recurrence'];
    if (recurrence['mode'] == 'weekly') {
      return (recurrence['weekdays'] as List).contains(date.weekday);
    }
    if (recurrence['mode'] == 'monthly') {
      return date.day ==
          (recurrence['monthDay'] as int).clamp(
            1,
            DateTime(date.year, date.month + 1, 0).day,
          );
    }
    return true;
  }

  Widget day() {
    final policies = (widget.profile['tapSettings'] as List)
        .cast<Json>()
        .where(scheduled)
        .toList();
    return ListView(
      key: PageStorageKey('example/day/$date'),
      padding: const EdgeInsets.all(24),
      children: [
        if (compactNavigation) ...metadata,
        Information(
          date == DateTime(2026, 10, 12)
              ? display(widget.profile['exampleDay']['description'])
              : context.t('manual.market.exampleNotice'),
        ),
        const SizedBox(height: 16),
        Text(context.t('example.date'), style: AppText.section),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final day in [
              DateTime(2026, 10, 12),
              DateTime(2026, 10, 13),
              DateTime(2026, 11, 5),
              DateTime(2026, 11, 10),
            ])
              ChoiceChip(
                label: Text('${day.month}/${day.day}'),
                selected: date == day,
                chipAnimationStyle: AppMotion.chipStyle(context),
                onSelected: (_) => setState(() => date = day),
              ),
          ],
        ),
        const SizedBox(height: 24),
        for (final policy in policies) ...[
          if (entries
                  .where((e) => e['sourceId'] == policy['sourceId'])
                  .firstOrNull
              case final Json entry)
            tapCard(
              entry,
              caption:
                  '${display((widget.profile['parts'] as List).where((p) => p['id'] == policy['partId']).first['name'])} · ${policy['settings']['usage'] == 'event' ? context.t('example.trigger') : display(entry['knowledge']['cadenceHint'])}',
            ),
        ],
      ],
    );
  }

  bool get compactNavigation =>
      MediaQuery.sizeOf(context).width < 600 &&
      MediaQuery.sizeOf(context).height < 850;
  String paneLabel(int value) => context.t(
    value == 0
        ? 'example.structure'
        : value == 1
        ? 'manual.market.exampleConfig'
        : 'example.day',
  );

  @override
  Widget build(BuildContext context) => AppEditorScaffold(
    title: context.t('manual.market.exampleTitle'),
    subtitle: display(widget.profile['name']),
    onClose: () => Navigator.pop(context),
    footer: widget.canSelect
        ? AppSheetFooter(
            children: [
              Text(
                context.t('example.basket', args: {'count': selected.length}),
                style: AppText.caption,
              ),
              FilledButton(
                onPressed: selected.isEmpty
                    ? null
                    : () => Navigator.pop(context, selected.toList()),
                child: Text(context.t('manual.market.exampleImport')),
              ),
            ],
          )
        : null,
    body: Column(
      children: [
        if (!compactNavigation)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(children: metadata),
          ),
        Padding(
          padding: compactNavigation
              ? const EdgeInsets.symmetric(horizontal: 24)
              : const EdgeInsets.all(16),
          child: compactNavigation
              ? SizedBox(
                  height: 48,
                  child: Semantics(
                    label: context.t('manual.market.exampleTitle'),
                    child: DropdownButton<int>(
                      key: const ValueKey('example-view-select'),
                      isExpanded: true,
                      value: pane,
                      underline: const SizedBox(),
                      items: [
                        for (final value in [0, 1, 2])
                          DropdownMenuItem(
                            value: value,
                            child: Text(
                              paneLabel(value),
                              maxLines: 2,
                              style: AppText.body,
                            ),
                          ),
                      ],
                      onChanged: (value) {
                        if (value != null) setState(() => pane = value);
                      },
                    ),
                  ),
                )
              : AppChoiceGroup<int>(
                  values: const [0, 1, 2],
                  selected: pane,
                  labelOf: paneLabel,
                  onSelected: (value) => setState(() => pane = value),
                ),
        ),
        if (pane == 0)
          Padding(
            padding: compactNavigation
                ? const EdgeInsets.symmetric(horizontal: 24)
                : EdgeInsets.zero,
            child: ManualCategoryPicker(
              compact: compactNavigation,
              selected: category,
              counts: {
                for (final c in manualCategoryIds)
                  c: entries.where((e) => manualCategoryOf(e) == c).length,
              },
              onSelected: (value) => setState(() {
                category = value;
                folder = null;
                tapId = null;
                stepId = null;
                history.clear();
              }),
            ),
          ),
        Expanded(
          child: AppContentTransition(
            trigger: (pane, category, folder, tapId, stepId, date),
            child: pane == 0
                ? structure()
                : pane == 1
                ? setup()
                : day(),
          ),
        ),
      ],
    ),
  );
}

class ExampleLayout extends StatelessWidget {
  const ExampleLayout({super.key, required this.profile});
  final Json profile;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final width = constraints.maxWidth,
          height =
              width *
              (profile['layout']['height'] as num) /
              (profile['layout']['width'] as num);
      return Semantics(
        label: context.t('example.places'),
        child: SizedBox(
          width: width,
          height: height,
          child: Stack(
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    border: Border.all(color: AppColors.line),
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              for (final place in (profile['places'] as List).cast<Json>())
                Positioned(
                  left: width * place['x'] / profile['layout']['width'],
                  top: height * place['y'] / profile['layout']['height'],
                  width: width * place['width'] / profile['layout']['width'],
                  height:
                      height * place['height'] / profile['layout']['height'],
                  child: Tooltip(
                    message: manualDisplayText(context, place['name']),
                    child: Container(
                      margin: const EdgeInsets.all(2),
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color:
                            (place['type'] == 'table'
                                    ? AppColors.accent
                                    : AppColors.green)
                                .withValues(alpha: .12),
                        border: Border.all(color: AppColors.line),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          manualDisplayText(context, place['name']),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: AppText.caption.copyWith(fontSize: 12),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    },
  );
}
