import '../domain/manual_categories.dart';
import 'manual_hierarchy.dart';
import 'entity_name_translation.dart';
import '../l10n/entity_name_scope.dart';
import 'owner_workflow_screen.dart';
import '../l10n/manual_text_scope.dart';
import '../l10n/app_localizations.dart';
import 'translated_content.dart';
import 'manual_setup_screen.dart';
import 'place_guide.dart';
import 'linked_place_guide.dart';
import 'manual_work_screen.dart';
import 'manual_print_screen.dart';
import 'manual_tap_editor.dart';
import 'catalog_editor.dart';
import 'manual_market_screen.dart';
import 'checklist_backup_screen.dart';
import 'dart:convert';
import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../state/operations_controller.dart';
import 'components.dart';
import 'direct_edit.dart';
import 'tap_settings_screen.dart';
import 'checklist_editor.dart';

/// A manual belongs to one Task. The tree changes reusable definitions only.
class ManualWorkspace extends StatefulWidget {
  const ManualWorkspace({
    super.key,
    required this.ops,
    required this.query,
    this.onClearSearch,
    this.searchResultsBuilder,
  });
  final OperationsController ops;
  final String query;
  final VoidCallback? onClearSearch;
  final WidgetBuilder? searchResultsBuilder;
  @override
  State<ManualWorkspace> createState() => _ManualWorkspaceState();
}

class _ManualWorkspaceState extends State<ManualWorkspace> {
  List<Json> rows = [], folders = [], taps = [];
  int revision = -1;
  String actor = '';
  Object? workspace;
  String? scopeGroup, scopeTap, selectedId, category, browsingFolder;
  bool editing = false;
  bool previewDirty = false, recipes = false;
  final expanded = <String>{};
  OperationsController get ops => widget.ops;
  bool get canEdit => ops.canEditTasks && !ops.busy;
  Json copy(Json row) => jsonDecode(jsonEncode(row)) as Json;

  final directoryScroll = ScrollController();
  final directoryViewport = GlobalKey();
  Timer? dragScroll;
  double dragScrollSpeed = 0;

  @override
  void dispose() {
    dragScroll?.cancel();
    directoryScroll.dispose();
    super.dispose();
  }

  void stopDragScroll() {
    dragScroll?.cancel();
    dragScroll = null;
    dragScrollSpeed = 0;
  }

  void scrollDrag(DragUpdateDetails details) {
    final box =
        directoryViewport.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !directoryScroll.hasClients) return;
    final y = box.globalToLocal(details.globalPosition).dy;
    dragScrollSpeed = y < 56
        ? -10
        : y > box.size.height - 56
        ? 10
        : 0;
    if (dragScrollSpeed == 0) {
      stopDragScroll();
      return;
    }
    dragScroll ??= Timer.periodic(const Duration(milliseconds: 32), (_) {
      if (!mounted || !directoryScroll.hasClients) {
        stopDragScroll();
        return;
      }
      final position = directoryScroll.position;
      directoryScroll.jumpTo(
        (position.pixels + dragScrollSpeed).clamp(
          position.minScrollExtent,
          position.maxScrollExtent,
        ),
      );
    });
  }

  Future<void> openMarket() async {
    final before = ops.rows('taskTemplates').map((t) => t['id']).toSet();
    final openingActor = ops.actorId,
        openingWorkspace = ops.data?['workspaceId'];
    final imported = await showAppPage<List<String>>(
      context,
      builder: (_) => ManualMarketScreen(
        ops: ops,
        folderId: scopeGroup,
        initialCategory: recipes ? 'recipe' : null,
      ),
    );
    if (imported == null ||
        !mounted ||
        ops.actorId != openingActor ||
        ops.data?['workspaceId'] != openingWorkspace) {
      return;
    }
    final added = ops
        .rows('taskTemplates')
        .where(
          (t) =>
              !before.contains(t['id']) &&
              imported.contains(
                ops.data?['catalogLinks']?[t['id']]?['sourceId'],
              ) &&
              t['archivedAt'] == null &&
              t['menuManualId'] == null,
        )
        .toList();
    if (added.isEmpty) return;
    widget.onClearSearch?.call();
    setState(() {
      sync(force: true);
      recipes = manualCategoryOf(added.first) == 'recipe';
      category = recipes ? 'recipe' : null;
      scopeGroup = recipes ? null : added.first['folderId'];
      scopeTap = recipes ? null : added.first['id'];
      selectedId = null;
      browsingFolder = scopeGroup;
      expanded.addAll(folders.map((f) => 'group:${f['id']}'));
      expanded.addAll(taps.map((t) => 'tap:${t['tapId']}'));
    });
  }

  void sync({bool force = false}) {
    final changedActor =
        actor != ops.actorId || workspace != ops.data?['workspaceId'];
    if (!force &&
        !changedActor &&
        (previewDirty || revision == ops.data?['revision'])) {
      return;
    }
    final recipeIds = ops
        .rows('taskTemplates')
        .where((t) => manualCategoryOf(t) == 'recipe')
        .map((t) => t['id'])
        .toSet();
    rows = ops
        .rows('manualSearch')
        .where(
          (r) =>
              manualCategoryOf(r) != 'recipe' &&
              !recipeIds.contains(r['templateId']),
        )
        .map(copy)
        .toList();
    for (final row in rows) {
      final source = ops
          .rows('taskTemplates')
          .where((t) => t['id'] == row['templateId'])
          .firstOrNull;
      if (source != null) row['manualCategory'] = manualCategoryOf(source);
    }
    folders = ops.rows('checklistFolders').map(copy).toList();
    for (final row in rows) {
      row['folderId'] ??= 'general';
      row['tapId'] ??= row['templateId'] ?? row['taskId'] ?? row['tapTitle'];
      row['id'] ??= '${row['tapId']}/${row['title']}';
      row['sourceStepId'] ??= row['stepId'] ?? row['id'];
      if (!folders.any((f) => f['id'] == row['folderId'])) {
        folders.add({
          'id': row['folderId'],
          'name': row['folderName'] ?? '기본 업무',
        });
      }
    }
    for (final row in rows) {
      row['folderName'] = folders.firstWhere(
        (f) => f['id'] == row['folderId'],
      )['name'];
    }
    taps = [
      for (final t
          in ops
              .rows('taskTemplates')
              .where(
                (t) =>
                    manualCategoryOf(t) != 'recipe' && t['archivedAt'] == null,
              ))
        {
          'manualCategory': manualCategoryOf(t),
          'knowledge': t['knowledge'],
          'manualCustomization': t['manualCustomization'],
          'tapId': t['id'],
          'templateId': t['id'],
          'tapTitle': t['manualTitle'] ?? t['title'],
          'folderId': t['folderId'] ?? 'general',
          'editable': true,
        },
    ];
    for (final row in rows) {
      if (!taps.any((t) => t['tapId'] == row['tapId'])) taps.add(copy(row));
    }
    for (final tap in taps) {
      tap['folderName'] =
          folders
              .where((f) => f['id'] == tap['folderId'])
              .firstOrNull?['name'] ??
          '기본 업무';
    }
    final order = List<String>.from(ops.data?['bigTapOrder'] ?? []);
    if (order.isNotEmpty) {
      folders.sort((a, b) {
        final ai = order.indexOf(a['id']), bi = order.indexOf(b['id']);
        return (ai < 0 ? order.length : ai).compareTo(
          bi < 0 ? order.length : bi,
        );
      });
    }
    revision = ops.data?['revision'] ?? 0;
    actor = ops.actorId;
    workspace = ops.data?['workspaceId'];
    previewDirty = false;
    if (changedActor) {
      browsingFolder = null;
      editing = false;
      scopeGroup = null;
      scopeTap = null;
      selectedId = null;
      expanded.clear();
      if (ops.data?['manualBusinessProfile'] == null) {
        expanded.addAll(folders.map((f) => 'group:${f['id']}'));
      }
      recipes = false;
      category = null;
    }
  }

  String normalize(String text) =>
      text.toLowerCase().replaceAll('메뉴얼', '매뉴얼').replaceAll('결재', '결제');
  bool matches(Json row) {
    if (category != null && manualCategoryOf(row) != category) return false;
    final words = normalize(
      widget.query,
    ).trim().split(RegExp(r'\s+')).where((s) => s.isNotEmpty);
    final folder = folders.where((f) => f['id'] == row['folderId']).firstOrNull;
    final translated = [
      manualDisplayText(
        context,
        '${row['tapTitle'] ?? ''}',
        translations: ops.data?['manualContentTranslations'],
        templateId: row['templateId'],
      ),
      for (final field in ['title', 'manual', 'tip'])
        manualDisplayText(
          context,
          '${row[field] ?? ''}',
          translations: ops.data?['manualContentTranslations'],
          templateId: row['templateId'],
          stepId: row['sourceStepId'],
          field: field,
        ),
    ].join(' ');
    final text = normalize(
      '$translated ${folder?['name']} ${folderLabel(folder?['id'])} ${row['tapTitle']} ${row['title']} ${row['manual']} ${row['tip']} ${(row['tags'] as List? ?? []).join(' ')}',
    );
    return words.every(text.contains);
  }

  int? minutes(Json row) {
    final value = row['estimatedMinutes'];
    return value is int && value > 0 ? value : null;
  }

  String duration(List<Json> tasks) {
    final tapMinutes = tasks.isEmpty
        ? null
        : tasks.first['tapEstimatedMinutes'];
    if (tapMinutes is int && tapMinutes > 0) {
      return 'TAP ${context.t('work.approxMinutes', args: {'minutes': tapMinutes})}';
    }
    final known = tasks.map(minutes).whereType<int>().toList();
    if (known.isEmpty) return context.t('work.timeUnset');
    final total = known.fold<int>(0, (sum, value) => sum + value);
    return '${context.t('work.approxMinutes', args: {'minutes': total})}${known.length == tasks.length ? '' : '+'}';
  }

  void notice(String value) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(value)));

  Json drag(String kind, String id, {String? tapId}) => {
    'kind': kind,
    'id': id,
    'sourceTapId': ?tapId,
    'revision': revision,
    'actor': actor,
  };
  Json? destination(
    Json from,
    String kind,
    String id, {
    String? tapId,
    String? folderId,
  }) {
    if (from['kind'] == 'group' && kind == 'group' && from['id'] != id) {
      return {...from, 'beforeId': id};
    }
    if (from['kind'] == 'tap' && kind == 'group') {
      return {...from, 'targetId': id};
    }
    if (from['kind'] == 'tap' && kind == 'tap' && from['id'] != id) {
      return {...from, 'targetId': folderId, 'beforeId': id};
    }
    if (from['kind'] == 'task' && kind == 'group') {
      return {...from, 'targetFolderId': id};
    }
    if (from['kind'] == 'task' && kind == 'tap') {
      return {...from, 'targetId': id};
    }
    if (from['kind'] == 'task' &&
        kind == 'task' &&
        !(from['id'] == id && from['sourceTapId'] == tapId)) {
      return {...from, 'targetId': tapId, 'beforeId': id};
    }
    return null;
  }

  Future<void> move(Json command) async {
    if (!canEdit || command['actor'] != ops.actorId) return;
    if (command['targetFolderId'] != null) {
      await chooseDestination(command, folderId: command['targetFolderId']);
      return;
    }
    if (!ops.readOnly) {
      final ok = await ops.act(
        'move_manual_node',
        {...command}..remove('actor'),
      );
      if (!mounted) return;
      if (!ok) {
        notice(ops.error ?? context.t('ui.audit1230'));
        return;
      }
      setState(() {
        sync(force: true);
        selectedId = null;
        scopeTap = null;
        scopeGroup = null;
      });
      return;
    }
    // Public preview changes remain inside this view, never sent to a write API.
    final nextRows = rows.map(copy).toList();
    final nextFolders = folders.map(copy).toList();
    final nextTaps = taps.map(copy).toList();
    final kind = command['kind'];
    if (kind == 'group') {
      final moving = nextFolders.firstWhere((f) => f['id'] == command['id']);
      nextFolders.remove(moving);
      final at = command['beforeId'] == null
          ? nextFolders.length
          : nextFolders.indexWhere((f) => f['id'] == command['beforeId']);
      if (at < 0) return;
      nextFolders.insert(at, moving);
    } else if (kind == 'tap') {
      final moving = nextRows
          .where((r) => r['tapId'] == command['id'])
          .toList();
      final target = nextFolders
          .where((f) => f['id'] == command['targetId'])
          .firstOrNull;
      final tap = nextTaps
          .where((t) => t['tapId'] == command['id'])
          .firstOrNull;
      if (tap == null || target == null) return;
      nextTaps.remove(tap);
      tap['folderId'] = target['id'];
      tap['folderName'] = target['name'];
      final tapAt = command['beforeId'] == null
          ? nextTaps.length
          : nextTaps.indexWhere((t) => t['tapId'] == command['beforeId']);
      if (tapAt < 0) return;
      nextTaps.insert(tapAt, tap);
      nextRows.removeWhere((r) => r['tapId'] == command['id']);
      for (final r in moving) {
        r['folderId'] = target['id'];
        r['folderName'] = target['name'];
      }
      final at = command['beforeId'] == null
          ? nextRows.length
          : nextRows.indexWhere((r) => r['tapId'] == command['beforeId']);
      nextRows.insertAll(at < 0 ? nextRows.length : at, moving);
    } else {
      final source = nextRows
          .where((r) => r['tapId'] == command['sourceTapId'])
          .toList();
      final target = nextRows
          .where((r) => r['tapId'] == command['targetId'])
          .toList();
      final moving = source
          .where((r) => r['sourceStepId'] == command['id'])
          .firstOrNull;
      final parent = nextTaps
          .where((t) => t['tapId'] == command['targetId'])
          .firstOrNull;
      if (moving == null || parent == null) return;
      final different = command['sourceTapId'] != command['targetId'];
      if (different && target.length >= 30) {
        notice(context.t('ui.audit1231'));
        return;
      }
      if (different && target.any((r) => r['sourceStepId'] == command['id'])) {
        moving['sourceStepId'] =
            'manual-${DateTime.now().microsecondsSinceEpoch}';
        moving['stepId'] = moving['sourceStepId'];
      }
      nextRows.remove(moving);
      moving.addAll({
        'tapId': parent['tapId'],
        'templateId': parent['templateId'],
        'tapTitle': parent['tapTitle'],
        'folderId': parent['folderId'],
        'folderName': parent['folderName'],
        'id': '${parent['tapId']}/${moving['sourceStepId']}',
      });
      final at = command['beforeId'] == null
          ? nextRows.lastIndexWhere((r) => r['tapId'] == parent['tapId']) + 1
          : nextRows.indexWhere(
              (r) =>
                  r['tapId'] == parent['tapId'] &&
                  r['sourceStepId'] == command['beforeId'],
            );
      if (at < 0) return;
      nextRows.insert(at, moving);
    }
    setState(() {
      rows = nextRows;
      folders = nextFolders;
      taps = nextTaps;
      previewDirty = true;
      scopeTap = null;
      scopeGroup = null;
      selectedId = null;
    });
  }

  Json? shift(Json from, int delta) {
    final kind = from['kind'];
    late List<String> ids;
    String? parent;
    if (kind == 'group') {
      ids = folders.map((r) => r['id'] as String).toList();
    } else if (kind == 'tap') {
      parent = rows.firstWhere((r) => r['tapId'] == from['id'])['folderId'];
      ids = rows
          .where((r) => r['folderId'] == parent && r['editable'] == true)
          .map((r) => r['tapId'] as String)
          .toSet()
          .toList();
    } else {
      parent = from['sourceTapId'];
      ids = rows
          .where((r) => r['tapId'] == parent)
          .map((r) => r['sourceStepId'] as String)
          .toList();
    }
    final index = ids.indexOf(from['id']);
    if (index < 0 || index + delta < 0 || index + delta >= ids.length) {
      return null;
    }
    final before = delta < 0
        ? ids[index - 1]
        : index + 2 < ids.length
        ? ids[index + 2]
        : null;
    return {
      ...from,
      'beforeId': before,
      if (kind != 'group') 'targetId': parent,
    };
  }

  Future<void> chooseDestination(Json from, {String? folderId}) async {
    final kind = from['kind'];
    final choices = <Json>[];
    if (kind == 'group' || kind == 'tap') {
      for (final f in folders) {
        if (kind == 'group' && f['id'] == from['id']) continue;
        choices.add({
          'label': folderLabel(f['id']),
          'command': kind == 'group'
              ? {...from, 'beforeId': f['id']}
              : {...from, 'targetId': f['id']},
        });
      }
      if (kind == 'group') {
        choices.add({
          'label': '맨 아래',
          'command': {...from, 'beforeId': null},
        });
      }
    } else {
      final seen = <String>{};
      for (final row in taps.where(
        (r) =>
            r['editable'] == true &&
            (folderId == null || r['folderId'] == folderId),
      )) {
        if (!seen.add(row['tapId'])) continue;
        choices.add({
          'label': context.t(
            'ui.audit2132',
            args: {
              'p0': folderLabel(row['folderId'], row['folderName']),
              'p1': tapLabel(row),
            },
          ),
          'command': {...from, 'targetId': row['tapId']}
            ..remove('targetFolderId'),
        });
      }
    }
    if (choices.isEmpty) {
      notice(context.t('ui.audit1232'));
      return;
    }
    final command = await showAppDialog<Json>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(
          folderId == null
              ? context.t('ui.audit1081')
              : context.t('ui.audit1082'),
        ),
        children: [
          for (final option in choices)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, option['command']),
              child: Text(option['label']),
            ),
        ],
      ),
    );
    if (command != null && mounted) await move(command);
  }

  String folderLabel(dynamic id, [dynamic fallback]) {
    final folder = folders.where((f) => f['id'] == id).firstOrNull;
    return entityDisplayName(
      context,
      ops,
      'folder',
      id,
      folder?['name'] ?? fallback ?? '',
    );
  }

  String tapLabel(Json row) => manualDisplayText(
    context,
    '${row['tapTitle'] ?? ''}',
    translations: ops.data?['manualContentTranslations'],
    templateId: row['tapId'] ?? row['templateId'],
  );

  Widget node({
    required String kind,
    required String id,
    required String label,
    required int depth,
    required bool selected,
    required VoidCallback onTap,
    String? tapId,
    String? folderId,
    bool editable = true,
    bool hasChildren = false,
    int count = 0,
    String? durationText,
    dynamic customization,
  }) {
    final compactEdit = editing && MediaQuery.sizeOf(context).width < 700;
    final key = '$kind:$id${kind == 'task' ? ':$tapId' : ''}';
    final definition = ops
        .rows('taskTemplates')
        .where((t) => t['id'] == (kind == 'tap' ? id : tapId))
        .firstOrNull;
    final sourceStep = (definition?['steps'] as List? ?? [])
        .whereType<Json>()
        .where((step) => step['id'] == id)
        .firstOrNull;
    final sourceLabel = kind == 'group'
        ? (folders.where((f) => f['id'] == id).firstOrNull?['name'] ?? label)
        : kind == 'tap'
        ? (definition?['manualTitle'] ?? definition?['title'] ?? label)
        : sourceStep?['manualTitle'] ?? sourceStep?['title'] ?? label;
    final data = drag(kind, id, tapId: tapId);
    final handle = Semantics(
      key: ValueKey('manual-drag-$key'),
      label: context.t('ui.audit1083'),
      child: IconButton(
        tooltip: context.t('ui.audit567'),
        constraints: const BoxConstraints.tightFor(width: 48, height: 48),
        onPressed: () => chooseDestination(data),
        icon: const Icon(Icons.open_with, size: 18, color: AppColors.muted),
      ),
    );
    final feedback = Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Text(
          label,
          style: const TextStyle(fontFamily: 'Pretendard', fontSize: 13),
        ),
      ),
    );
    final source = ops
        .rows('taskTemplates')
        .where((t) => t['id'] == (kind == 'tap' ? id : tapId))
        .firstOrNull;
    final linkedMenu = source?['menuManualId'] != null;
    final deletable =
        !linkedMenu &&
        (kind == 'group'
            ? id != 'general' &&
                  !taps.any((r) => r['folderId'] == id) &&
                  !ops.rows('preparedItems').any((r) => r['folderId'] == id)
            : true);
    Widget row(bool hovering) => Container(
      margin: EdgeInsets.only(bottom: editing ? 2 : 8),
      decoration: BoxDecoration(
        color: hovering
            ? AppColors.lime
            : selected
            ? AppColors.green.withValues(alpha: .08)
            : kind == 'group'
            ? AppColors.elevated.withValues(alpha: .6)
            : null,
        borderRadius: BorderRadius.circular(AppShape.control),
        border: hovering ? Border.all(color: AppColors.green, width: 2) : null,
      ),
      child: Row(
        children: [
          if (hasChildren)
            IconButton(
              tooltip: expanded.contains(key)
                  ? context.t('ui.audit779')
                  : context.t('ui.audit778'),
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              icon: Icon(
                expanded.contains(key) || widget.query.isNotEmpty
                    ? Icons.expand_more
                    : Icons.chevron_right,
                size: 18,
              ),
              onPressed: () => setState(
                () => expanded.contains(key)
                    ? expanded.remove(key)
                    : expanded.add(key),
              ),
            )
          else
            SizedBox(width: compactEdit ? 8 : 48),
          Expanded(
            child: InkWell(
              key: ValueKey('manual-node-$key'),
              onTap: onTap,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  vertical: editing ? 12 : 16,
                  horizontal: 4,
                ),
                child: Row(
                  children: [
                    if (!compactEdit)
                      Icon(
                        kind == 'group'
                            ? CupertinoIcons.folder
                            : kind == 'tap'
                            ? CupertinoIcons.square_list
                            : CupertinoIcons.doc_text,
                        size: 17,
                        color: AppColors.green,
                      ),
                    if (!compactEdit) const SizedBox(width: 7),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Tooltip(
                            triggerMode: TooltipTriggerMode.manual,
                            message: editing && editable
                                ? context.t('ui.audit1084')
                                : label,
                            child: InkWell(
                              key: ValueKey('manual-rename-$key'),
                              mouseCursor: editing && editable
                                  ? SystemMouseCursors.text
                                  : SystemMouseCursors.click,
                              onTap: editing && editable && canEdit
                                  ? () {
                                      onTap();
                                      directEditNode(
                                        context,
                                        ops,
                                        'edit_manual_node',
                                        {
                                          'kind': kind,
                                          'id': id,
                                          'parentId': tapId,
                                          'operation': 'rename',
                                        },
                                        sourceLabel,
                                      );
                                    }
                                  : null,
                              child: Text(
                                label,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: editing
                                      ? 13
                                      : kind == 'group'
                                      ? 16
                                      : 15,
                                  fontWeight: selected || kind == 'group'
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                          ManualCustomizationBadge(value: customization),
                          if (durationText != null)
                            Text(
                              durationText,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.muted,
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (durationText == null && kind != 'task')
                      Text(
                        editing
                            ? '$count'
                            : '$count ${context.t(kind == 'group' ? 'manual.structure.tap' : 'manual.structure.task')}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.muted,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          if (!editing && editable && canEdit && kind != 'group')
            IconButton(
              key: ValueKey('manual-detail-$key'),
              tooltip: context.t('manual.edit'),
              icon: const Icon(
                CupertinoIcons.pencil,
                size: 18,
                color: AppColors.accent,
              ),
              onPressed: () => showAppSheet(
                context,
                builder: (_) => kind == 'tap'
                    ? ManualTapEditor(ops: ops, templateId: id)
                    : ManualTaskEditor(
                        ops: ops,
                        templateId: tapId!,
                        sourceStepId: id,
                      ),
              ),
            ),
          if (editing && !editable)
            Tooltip(
              message: context.t('ui.audit497'),
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Icon(
                  Icons.lock_outline,
                  size: 18,
                  color: AppColors.muted,
                ),
              ),
            ),
          if (editing && editable && canEdit) ...[
            PopupMenuButton<String>(
              key: ValueKey('manual-actions-$key'),
              tooltip: context.t('ui.audit1085', args: {'p0': label}),
              icon: const Icon(Icons.more_horiz, size: 18),
              constraints: const BoxConstraints(minWidth: 160),
              onSelected: (action) {
                if (action == 'translate') {
                  editEntityNameTranslation(
                    context,
                    ops,
                    'folder',
                    id,
                    sourceLabel,
                  );
                } else if (action == 'move') {
                  chooseDestination(data);
                } else if (action == 'detail' || action == 'add') {
                  showAppSheet(
                    context,
                    builder: (_) => kind == 'task'
                        ? ManualTaskEditor(
                            ops: ops,
                            templateId: tapId!,
                            sourceStepId: id,
                          )
                        : ManualTapEditor(
                            ops: ops,
                            templateId: kind == 'tap' ? id : null,
                            folderId: kind == 'group' ? id : folderId,
                            addTask: action == 'add' && kind == 'tap',
                          ),
                  );
                } else {
                  directEditNode(context, ops, 'edit_manual_node', {
                    'kind': kind,
                    'id': id,
                    'parentId': tapId,
                    'operation': action,
                  }, sourceLabel);
                }
              },
              itemBuilder: (_) => [
                if (kind == 'group')
                  PopupMenuItem(
                    value: 'translate',
                    child: Text(context.t('translation.edit')),
                  ),
                if (kind != 'group')
                  PopupMenuItem(
                    value: 'detail',
                    child: Text(context.t('ui.audit1086')),
                  ),
                if (kind != 'task')
                  PopupMenuItem(
                    value: 'add',
                    child: Text(
                      kind == 'group'
                          ? context.t('ui.audit845')
                          : context.t('ui.audit31'),
                    ),
                  ),
                PopupMenuItem(
                  value: 'move',
                  child: Text(context.t('ui.audit567')),
                ),
                PopupMenuItem(
                  value: 'rename',
                  child: Text(context.t('ui.audit568')),
                ),
                if (deletable)
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, color: AppColors.accent),
                        SizedBox(width: 8),
                        Text(context.t('ui.audit52')),
                      ],
                    ),
                  ),
              ],
            ),
            Draggable<Json>(
              data: data,
              feedback: feedback,
              onDragUpdate: scrollDrag,
              onDragEnd: (_) => stopDragScroll(),
              childWhenDragging: Opacity(opacity: .3, child: handle),
              child: handle,
            ),
          ],
        ],
      ),
    );
    Widget surface(bool hovering) => Padding(
      padding: EdgeInsets.only(left: depth * 12.0),
      child: DirectEditFrame(
        key: ValueKey('manual-tree-frame-$key'),
        enabled: canEdit,
        active: editing && editable,
        controls: false,
        outline: false,
        onEnter: () => setState(() {
          editing = true;
          scopeGroup = kind == 'group' ? id : folderId;
          scopeTap = kind == 'group'
              ? null
              : kind == 'tap'
              ? id
              : tapId;
          selectedId = null;
        }),
        child: row(hovering),
      ),
    );
    if (!editing || !editable || !canEdit) return surface(false);
    return DragTarget<Json>(
      key: ValueKey('manual-drop-$key'),
      onWillAcceptWithDetails: (d) =>
          destination(d.data, kind, id, tapId: tapId, folderId: folderId) !=
          null,
      onAcceptWithDetails: (d) {
        final command = destination(
          d.data,
          kind,
          id,
          tapId: tapId,
          folderId: folderId,
        );
        if (command != null) move(command);
      },
      builder: (_, candidates, _) => surface(candidates.isNotEmpty),
    );
  }

  void chooseCategory(String? value) => setState(() {
    category = value;
    recipes = value == 'recipe';
    editing = false;
    scopeGroup = null;
    scopeTap = null;
    selectedId = null;
    browsingFolder = null;
  });
  void navigateHierarchy(Json row, ManualHierarchyDestination destination) {
    setState(() {
      category = null;
      recipes = false;
      scopeGroup = row['folderId'];
      scopeTap = destination == ManualHierarchyDestination.tap
          ? row['tapId'] ?? row['templateId']
          : null;
      selectedId = null;
      browsingFolder = scopeGroup;
      expanded.add('group:$scopeGroup');
      if (scopeTap != null) expanded.add('tap:$scopeTap');
    });
  }

  Widget hierarchy({
    Json? selected,
    ValueChanged<ManualHierarchyDestination>? onNavigate,
  }) {
    final tap = taps
        .where((t) => t['tapId'] == (selected?['tapId'] ?? scopeTap))
        .firstOrNull;
    final folderId = selected?['folderId'] ?? tap?['folderId'] ?? scopeGroup;
    return ManualHierarchyPath(
      compact: MediaQuery.sizeOf(context).height < 600,
      folder: folderId == null ? null : folderLabel(folderId),
      reference: ['recipe', 'startup', 'reference'].contains(
        selected == null ? (category ?? 'routine') : manualCategoryOf(selected),
      ),
      tap: selected == null
          ? (tap == null ? null : tapLabel(tap))
          : tapLabel(selected),
      task: selected == null
          ? null
          : manualDisplayText(
              context,
              '${selected['title']}',
              translations: ops.data?['manualContentTranslations'],
              templateId: selected['templateId'],
              stepId: selected['sourceStepId'],
            ),
      onFolder: folderId == null
          ? null
          : () => onNavigate != null
                ? onNavigate(ManualHierarchyDestination.folder)
                : navigateHierarchy({
                    'folderId': folderId,
                  }, ManualHierarchyDestination.folder),
      onTap: tap == null
          ? null
          : () => onNavigate != null
                ? onNavigate(ManualHierarchyDestination.tap)
                : navigateHierarchy(tap, ManualHierarchyDestination.tap),
      onTask: tap == null
          ? null
          : () => onNavigate != null
                ? onNavigate(ManualHierarchyDestination.tap)
                : navigateHierarchy(tap, ManualHierarchyDestination.tap),
    );
  }

  Widget directory() {
    final nodes = <Widget>[];
    for (final folder in folders) {
      if (folder['id'] == 'store-recipes') continue;
      if (browsingFolder != null && folder['id'] != browsingFolder) continue;
      if (!editing &&
          browsingFolder == null &&
          ops.data?['manualBusinessProfile'] != null &&
          !taps.any((t) => t['folderId'] == folder['id'])) {
        continue;
      }
      final all = rows
          .where(
            (r) =>
                r['folderId'] == folder['id'] &&
                (category == null || manualCategoryOf(r) == category),
          )
          .toList();
      final matching = all.where(matches).toList();
      final folderTaps = taps
          .where(
            (t) =>
                t['folderId'] == folder['id'] &&
                (category == null || manualCategoryOf(t) == category),
          )
          .toList();
      if (category != null && folderTaps.isEmpty && all.isEmpty) continue;
      final visibleTaps = folderTaps
          .where(
            (t) =>
                widget.query.trim().isEmpty ||
                matching.any((r) => r['tapId'] == t['tapId']) ||
                normalize(
                  '${folder['name']} ${folderLabel(folder['id'])} ${t['tapTitle']}',
                ).contains(normalize(widget.query).trim()),
          )
          .toList();
      if (widget.query.trim().isNotEmpty &&
          visibleTaps.isEmpty &&
          !normalize(
            '${folder['name']} ${folderLabel(folder['id'])}',
          ).contains(normalize(widget.query).trim())) {
        continue;
      }
      final groupStart = nodes.length;
      nodes.add(
        node(
          kind: 'group',
          id: folder['id'],
          label: folderLabel(folder['id']),
          depth: 0,
          selected: scopeGroup == folder['id'] && scopeTap == null,
          count: folderTaps.length,
          hasChildren: folderTaps.isNotEmpty,
          onTap: () => setState(() {
            scopeGroup = folder['id'];
            scopeTap = null;
            selectedId = null;
            expanded.add('group:${folder['id']}');
          }),
        ),
      );
      if (!expanded.contains('group:${folder['id']}') && widget.query.isEmpty) {
        final header = nodes.removeLast();
        nodes.add(
          ManualFoldGroup(
            key: ValueKey('manual-fold-${folder['id']}'),
            header: header,
            children: const [],
          ),
        );
        continue;
      }
      for (final tap in visibleTaps) {
        final children = matching
            .where((r) => r['tapId'] == tap['tapId'])
            .toList();
        nodes.add(
          node(
            kind: 'tap',
            customization: tap['manualCustomization'],
            id: tap['tapId'],
            folderId: folder['id'],
            label: tap['editable'] == true
                ? tapLabel(tap)
                : context.t('ui.audit1087', args: {'p0': tapLabel(tap)}),
            depth: 1,
            editable: tap['editable'] == true,
            selected: scopeTap == tap['tapId'],
            hasChildren: children.isNotEmpty,
            count: children.length,
            durationText: all.where((r) => r['tapId'] == tap['tapId']).isEmpty
                ? context.t('manual.structure.actionCount', args: {'count': 0})
                : duration(
                    all.where((r) => r['tapId'] == tap['tapId']).toList(),
                  ),
            onTap: () => setState(() {
              scopeGroup = folder['id'];
              scopeTap = tap['tapId'];
              selectedId = null;
              expanded.add('tap:${tap['tapId']}');
            }),
          ),
        );
        if (!expanded.contains('tap:${tap['tapId']}') && widget.query.isEmpty) {
          continue;
        }
        for (final task in children) {
          nodes.add(
            node(
              kind: 'task',
              id: task['sourceStepId'],
              tapId: tap['tapId'],
              folderId: folder['id'],
              label: manualDisplayText(
                context,
                task['title'],
                translations: ops.data?['manualContentTranslations'],
                templateId: task['templateId'],
                stepId: task['sourceStepId'],
              ),
              depth: 2,
              editable: task['editable'] == true,
              durationText: task['editable'] == true
                  ? duration([task])
                  : context.t(
                      'ui.audit1089',
                      args: {
                        'p0': duration([task]),
                      },
                    ),
              selected: selectedId == task['id'],
              onTap: () {
                setState(() {
                  scopeGroup = folder['id'];
                  scopeTap = tap['tapId'];
                  selectedId = task['id'];
                });
                if (!editing) openManual(task);
              },
            ),
          );
        }
      }
      final group = nodes.sublist(groupStart);
      nodes.removeRange(groupStart, nodes.length);
      nodes.add(
        ManualFoldGroup(
          key: ValueKey('manual-fold-${folder['id']}'),
          header: group.first,
          children: group.skip(1).toList(),
        ),
      );
    }
    return KeyedSubtree(
      key: directoryViewport,
      child: ListView.builder(
        controller: directoryScroll,
        key: const ValueKey('manual-directory'),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(8),
        itemCount: nodes.length,
        itemBuilder: (_, index) => nodes[index],
      ),
    );
  }

  Future<void> openManual(Json row) async {
    final openingActor = ops.actorId,
        openingWorkspace = ops.data?['workspaceId'];
    setState(() => selectedId = row['id']);
    final destination = await showAppPage<ManualHierarchyDestination>(
      context,
      builder: (_) => ListenableBuilder(
        listenable: ops,
        builder: (context, _) {
          if (ops.actorId != openingActor ||
              ops.data?['workspaceId'] != openingWorkspace) {
            return AppEditorScaffold(
              title: context.t('nav.manual'),
              body: Information(context.t('manual.changedTask')),
            );
          }
          sync();
          final current = rows.where((r) => r['id'] == row['id']).firstOrNull;
          return AppEditorScaffold(
            title: context.t('nav.manual'),
            body: current == null
                ? Information(context.t('manual.changedTask'))
                : content(
                    selected: current,
                    onNavigate: (destination) =>
                        Navigator.pop(context, destination),
                  ),
          );
        },
      ),
    );
    if (mounted &&
        destination != null &&
        ops.actorId == openingActor &&
        ops.data?['workspaceId'] == openingWorkspace) {
      sync();
      final current = rows.where((r) => r['id'] == row['id']).firstOrNull;
      if (current != null) navigateHierarchy(current, destination);
    }
  }

  Widget content({
    required Json selected,
    ValueChanged<ManualHierarchyDestination>? onNavigate,
  }) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        hierarchy(selected: selected, onNavigate: onNavigate),
        const SizedBox(height: 16),
        ManualCustomizationBadge(value: selected['manualCustomization']),
        SharedPlaceLinks(ops: ops, row: selected),
        Text(
          '${folderLabel(selected['folderId'], selected['folderName'])} / ${tapLabel(selected)} / ${context.t(['recipe', 'startup', 'reference'].contains(manualCategoryOf(selected)) ? 'manual.structure.section' : 'manual.structure.task')}',
          style: const TextStyle(fontSize: 13, color: AppColors.muted),
        ),
        const SizedBox(height: 12),
        Text(
          duration([selected]),
          style: const TextStyle(fontSize: 13, color: AppColors.muted),
        ),
        for (final id in (selected['knowledgeIds'] as List? ?? []))
          ExpansionTile(
            title: Text(
              context.t(
                'ui.audit1032',
                args: {
                  'p0':
                      ops
                          .rows('manualSearch')
                          .where((r) => r['templateId'] == id)
                          .firstOrNull?['tapTitle'] ??
                      context.t('ui.audit1233'),
                },
              ),
            ),
            children: [
              for (final row
                  in ops
                      .rows('manualSearch')
                      .where((r) => r['templateId'] == id))
                ListTile(
                  title: Text('${row['title']}'),
                  subtitle: Text('${row['manual']}'),
                ),
            ],
          ),
        if (canEdit &&
            selected['editable'] == true &&
            selected['templateId'] != null &&
            selected['sourceStepId'] != null)
          Wrap(
            spacing: 8,
            children: [
              PressBounce(
                child: TextButton.icon(
                  icon: const Icon(CupertinoIcons.clock),
                  label: Text(context.t('manual.tapSettings')),
                  onPressed: () async {
                    await showAppSheet(
                      context,
                      builder: (_) => TapSettingsScreen(
                        ops: ops,
                        initialTemplateId: selected['templateId'],
                      ),
                    );
                    if (mounted) setState(() => sync(force: true));
                  },
                ),
              ),
              PressBounce(
                child: TextButton.icon(
                  icon: const Icon(CupertinoIcons.pencil),
                  label: Text(context.t('manual.edit')),
                  onPressed: () async {
                    await showAppSheet(
                      context,
                      builder: (_) => ManualTaskEditor(
                        ops: ops,
                        templateId: selected['templateId'],
                        sourceStepId: selected['sourceStepId'],
                      ),
                    );
                    if (mounted) setState(() => sync(force: true));
                  },
                ),
              ),
            ],
          ),
        TranslatedContent(
          ops: ops,
          kind: 'manual',
          entityId: selected['templateId'],
          stepId: selected['sourceStepId'],
          source: selected,
          builder: (context, displayed) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${displayed['title']}',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 20),
              SelectableText(
                '${displayed['manual'] ?? ''}',
                style: const TextStyle(fontSize: 16, height: 1.65),
              ),
              if ('${displayed['tip'] ?? ''}'.isNotEmpty) ...[
                const SizedBox(height: 20),
                Information('${displayed['tip']}'),
              ],
            ],
          ),
        ),
        if (selected['linkedPlace'] is Map)
          LinkedPlaceGuide(
            ops: ops,
            place: Map<String, dynamic>.from(selected['linkedPlace']),
          ),
        if ('${selected['imageUrl'] ?? ''}'.isNotEmpty) ...[
          const SizedBox(height: 16),
          placePhoto(selected['imageUrl'], ops: ops),
        ],
        for (final link in {'videoUrl': '영상', 'sourceUrl': '참고 자료'}.entries)
          if ('${selected[link.key] ?? ''}'.isNotEmpty)
            PressBounce(
              child: TextButton.icon(
                icon: const Icon(CupertinoIcons.arrow_up_right),
                label: Text(link.value),
                onPressed: () async {
                  final uri = Uri.tryParse(selected[link.key]);
                  if (uri != null && uri.scheme == 'https') {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
              ),
            ),
      ],
    );
  }

  Future<void> openRecipe(Json source) async {
    final actorId = ops.actorId, workspaceId = ops.data?['workspaceId'];
    await showAppPage<void>(
      context,
      builder: (_) => ListenableBuilder(
        listenable: ops,
        builder: (c, _) {
          if (ops.actorId != actorId ||
              ops.data?['workspaceId'] != workspaceId) {
            return AppEditorScaffold(
              title: c.t('manual.category.recipe'),
              body: Information(c.t('manual.changedTask')),
            );
          }
          final saved = ops
              .rows('taskTemplates')
              .where((t) => t['id'] == source['id'] && t['archivedAt'] == null)
              .firstOrNull;
          final guide = ops
              .rows('manualSearch')
              .where((row) => row['templateId'] == source['id'])
              .toList();
          final current =
              saved ??
              (guide.isEmpty
                  ? null
                  : <String, dynamic>{
                      'id': source['id'],
                      'title': guide.first['tapTitle'],
                      'folderId': guide.first['folderId'],
                      'steps': guide
                          .map(
                            (row) => <String, dynamic>{
                              ...row,
                              'id': row['sourceStepId'] ?? row['id'],
                            },
                          )
                          .toList(),
                    });
          if (current == null) {
            return AppEditorScaffold(
              title: c.t('manual.category.recipe'),
              body: Information(c.t('manual.changedTask')),
            );
          }
          return AppEditorScaffold(
            title: manualDisplayText(
              c,
              '${current['manualTitle'] ?? current['title']}',
              translations: ops.data?['manualContentTranslations'],
              templateId: current['id'],
            ),
            footer: ops.canEditTasks && !ops.readOnly
                ? AppSheetFooter(
                    children: [
                      FilledButton.icon(
                        key: ValueKey('recipe-edit-${current['id']}'),
                        onPressed: () => showAppFormSheet<void>(
                          context: c,
                          builder: (_) => ManualTapEditor(
                            ops: ops,
                            templateId: current['id'],
                          ),
                        ),
                        icon: const Icon(Icons.edit_outlined),
                        label: Text(c.t('manual.edit')),
                      ),
                    ],
                  )
                : null,
            body: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                ManualHierarchyPath(
                  reference: true,
                  folder: folderLabel(current['folderId']),
                  tap: manualDisplayText(c, '${current['title']}'),
                ),
                const SizedBox(height: 16),
                Text(c.t('manual.structure.reference'), style: AppText.caption),
                const SizedBox(height: 16),
                for (final step
                    in (current['steps'] as List? ?? []).cast<Json>())
                  Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: TranslatedContent(
                      ops: ops,
                      kind: 'manual',
                      entityId: current['id'],
                      stepId: step['id'],
                      source: step,
                      builder: (context, action) => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${action['title']}', style: AppText.section),
                          const SizedBox(height: 8),
                          Text(
                            '${action['manual'] ?? ''}',
                            style: AppText.body,
                          ),
                          if ('${step['imageUrl'] ?? ''}'.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            placePhoto(step['imageUrl'], ops: ops),
                          ],
                          if ((action['tip'] ?? '').isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(action['tip'], style: AppText.caption),
                          ],
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget recipeList() {
    final available = ops
        .rows('taskTemplates')
        .where(
          (t) => manualCategoryOf(t) == 'recipe' && t['archivedAt'] == null,
        )
        .toList();
    if (!ops.canEditTasks) {
      final grouped = <String, Json>{};
      for (final row
          in ops
              .rows('manualSearch')
              .where((r) => manualCategoryOf(r) == 'recipe')) {
        final id = row['templateId'] as String;
        final template = grouped.putIfAbsent(
          id,
          () => {'id': id, 'title': row['tapTitle'], 'steps': <Json>[]},
        );
        (template['steps'] as List).add(row);
      }
      available.addAll(grouped.values);
    }
    final templates = available
        .where(
          (t) => normalize(
            '${t['title']} ${(t['steps'] as List? ?? []).map((s) => s['manual']).join(' ')}',
          ).contains(normalize(widget.query)),
        )
        .toList();
    return ListView(
      key: const ValueKey('manual-recipes'),
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        Text(context.t('ui.audit498'), style: AppText.section),
        const SizedBox(height: 8),
        Text(context.t('ui.audit499'), style: AppText.caption),
        if (ops.canEditTasks)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => showAppSheet(
                context,
                builder: (_) => CatalogEditor(ops: ops, menusOnly: true),
              ),
              icon: const Icon(Icons.add),
              label: Text(context.t('ui.audit500')),
            ),
          ),
        if (templates.isEmpty) Information(context.t('ui.audit501')),
        for (final t in templates)
          ListTile(
            key: ValueKey('store-recipe-${t['id']}'),
            contentPadding: EdgeInsets.zero,
            title: Text(
              manualDisplayText(
                context,
                '${t['manualTitle'] ?? t['title']}',
                translations: ops.data?['manualContentTranslations'],
                templateId: t['id'],
              ),
            ),
            subtitle: Text(context.t('ui.audit502')),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => openRecipe(t),
          ),
      ],
    );
  }

  Widget header() => Row(
    key: const ValueKey('manual-header'),
    children: [
      Expanded(
        child: LayoutBuilder(
          builder: (context, constraints) => AppToolbarScroll(
            key: const ValueKey('manual-header-actions'),
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (ops.canEditTasks)
                    AppToolbarButton(
                      key: const ValueKey('manual-market-button'),
                      onPressed: ops.busy ? null : openMarket,
                      icon: Icons.storefront_outlined,
                      label: context.t(
                        recipes ? 'manual.recipeLibrary' : 'manual.market',
                      ),
                    ),
                  if (canEdit)
                    AppToolbarButton(
                      icon: Icons.link,
                      label: context.t('manual.linkWork'),
                      onPressed: () async {
                        await showAppSheet(
                          context,
                          builder: (_) => ManualWorkScreen(ops: ops),
                        );
                        if (mounted) setState(() => sync(force: true));
                      },
                    ),
                  AppToolbarButton(
                    key: const ValueKey('manual-print-button'),
                    onPressed: ops.busy
                        ? null
                        : () => showAppSheet(
                            context,
                            builder: (_) => ManualPrintScreen(
                              ops: ops,
                              templateId: scopeTap,
                              folderId: scopeGroup,
                              recipes: recipes,
                            ),
                          ),
                    icon: Icons.print_outlined,
                    label: context.t('manual.print'),
                  ),
                  if (!recipes && ops.canEditTasks)
                    AppToolbarButton(
                      key: const ValueKey('manual-add-folder'),
                      icon: Icons.create_new_folder_outlined,
                      onPressed: ops.busy
                          ? null
                          : () async {
                              widget.onClearSearch?.call();
                              setState(() {
                                editing = true;
                                browsingFolder = null;
                              });
                              await directEditNode(
                                context,
                                ops,
                                'edit_manual_node',
                                {'kind': 'group', 'operation': 'add'},
                                '',
                              );
                            },
                      label: context.t('manual.addFolder'),
                    ),
                  if (!recipes && ops.canEditTasks) ...[
                    AppToolbarButton(
                      key: const ValueKey('manual-add-tap'),
                      onPressed: ops.busy
                          ? null
                          : () => showAppSheet(
                              context,
                              builder: (_) => ManualTapEditor(
                                ops: ops,
                                folderId: scopeGroup,
                              ),
                            ),
                      icon: Icons.add,
                      label: context.t('manual.addTap'),
                    ),
                    AppToolbarButton(
                      key: const ValueKey('manual-backup'),
                      onPressed: ops.busy
                          ? null
                          : () => showAppSheet(
                              context,
                              builder: (_) => ChecklistBackupScreen(ops: ops),
                            ),
                      icon: Icons.restore,
                      label: context.t('manual.backup'),
                    ),
                  ],
                  if (!recipes && ops.canEditTasks && editing)
                    AppToolbarButton(
                      icon: Icons.check,
                      key: const ValueKey('manual-edit-done'),
                      onPressed: ops.busy
                          ? null
                          : () => setState(() {
                              stopDragScroll();
                              editing = false;
                            }),
                      label: context.t('manual.editDone'),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    ],
  );

  List<Json> get visibleFolders => folders
      .where(
        (folder) =>
            folder['id'] != 'store-recipes' &&
            (editing ||
                ops.data?['manualBusinessProfile'] == null ||
                taps.any((tap) => tap['folderId'] == folder['id'])),
      )
      .toList();

  Future<void> chooseFolder() async {
    final openingScope = (ops.actorId, ops.data?['workspaceId']);
    final folder = await showAppSheet<String>(
      context,
      builder: (context) => AppEditorScaffold(
        title: context.t('manual.chooseFolder'),
        body: ListView(
          children: [
            ListTile(
              key: const ValueKey('manual-folder-all'),
              leading: const Icon(CupertinoIcons.folder),
              title: Text(context.t('manual.all')),
              trailing: browsingFolder == null
                  ? const Icon(Icons.check, color: AppColors.green)
                  : null,
              onTap: () => Navigator.pop(context, ''),
            ),
            for (final folder in visibleFolders)
              ListTile(
                key: ValueKey('manual-folder-choice-${folder['id']}'),
                leading: const Icon(CupertinoIcons.folder),
                title: Text(folderLabel(folder['id'])),
                subtitle: Text(
                  context.t(
                    'manual.count',
                    args: {
                      'count': taps
                          .where((t) => t['folderId'] == folder['id'])
                          .length,
                    },
                  ),
                ),
                trailing: browsingFolder == folder['id']
                    ? const Icon(Icons.check, color: AppColors.green)
                    : null,
                onTap: () => Navigator.pop(context, folder['id'] as String),
              ),
          ],
        ),
      ),
    );
    if (!mounted ||
        folder == null ||
        openingScope != (ops.actorId, ops.data?['workspaceId'])) {
      return;
    }
    setState(() {
      browsingFolder = folder.isEmpty ? null : folder;
      scopeGroup = browsingFolder;
      scopeTap = null;
      selectedId = null;
      if (browsingFolder != null) expanded.add('group:$browsingFolder');
    });
    if (directoryScroll.hasClients) directoryScroll.jumpTo(0);
  }

  @override
  Widget build(BuildContext context) {
    sync();
    if (!ops.canEditTasks) editing = false;
    if (browsingFolder != null &&
        !folders.any((f) => f['id'] == browsingFolder)) {
      browsingFolder = null;
    }
    // Keep the directory selection mounted while global search is open.
    if (widget.query.trim().isNotEmpty && widget.searchResultsBuilder != null) {
      return widget.searchResultsBuilder!(context);
    }
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppLayout.pageMaxWidth),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppScrollHeader(
                key: const ValueKey('manual-controls'),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppViewToolbar(
                      key: const ValueKey('manual-view-toolbar'),
                      leading:
                          ops.actor['role'] == 'owner' &&
                              ops.data?['ownerWorkflow'] != null
                          ? AppToolbarButton(
                              onPressed: () => openOwnerWorkflow(context, ops),
                              icon: Icons.fact_check_outlined,
                              label: context.t(
                                'ui.audit1090',
                                args: {
                                  'p0':
                                      (ops.data?['ownerWorkflow']?['pending']
                                                  as List? ??
                                              [])
                                          .length,
                                },
                              ),
                            )
                          : null,
                      toggle: AppViewToggle<bool>(
                        key: const ValueKey('manual-view-toggle'),
                        values: const [false, true],
                        selected: recipes,
                        labelOf: (value) => context.t(
                          value ? 'manual.category.recipe' : 'nav.manual',
                        ),
                        onSelected: (value) =>
                            chooseCategory(value ? 'recipe' : null),
                      ),
                    ),
                    header(),
                    if (!recipes)
                      Row(
                        children: [
                          Expanded(
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: TextButton.icon(
                                key: const ValueKey('manual-folder-picker'),
                                icon: const Icon(
                                  CupertinoIcons.folder,
                                  size: 20,
                                ),
                                label: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        browsingFolder == null
                                            ? context.t('manual.all')
                                            : folderLabel(browsingFolder),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(Icons.expand_more, size: 18),
                                  ],
                                ),
                                onPressed: chooseFolder,
                              ),
                            ),
                          ),
                          if (canEdit && !editing)
                            IconButton(
                              key: const ValueKey('manual-organize'),
                              tooltip: context.t('manual.edit'),
                              icon: const Icon(
                                Icons.drive_file_rename_outline,
                                color: AppColors.accent,
                              ),
                              onPressed: () => setState(() => editing = true),
                            ),
                          if (previewDirty)
                            TextButton(
                              onPressed: () =>
                                  setState(() => sync(force: true)),
                              child: Text(context.t('common.reset')),
                            ),
                        ],
                      ),
                    if (editing)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          context.t(
                            ops.readOnly ? 'ui.audit503' : 'ui.audit1091',
                          ),
                          style: AppText.caption,
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    boxShadow: appCardShadow,
                    borderRadius: BorderRadius.circular(AppShape.card),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppShape.card),
                    child: recipes ? recipeList() : directory(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
