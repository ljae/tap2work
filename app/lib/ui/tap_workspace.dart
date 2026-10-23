import 'manual_media_view.dart';
import '../domain/manual_media_assets.dart';
import '../l10n/entity_name_scope.dart';
import '../l10n/manual_text_scope.dart';
import '../l10n/app_localizations.dart';
import 'translated_content.dart';
import 'manual_setup_screen.dart';
import 'crew_colors.dart';
import 'workplace_screens.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import '../domain/checklist_draft.dart';
import '../state/operations_controller.dart';
import 'checklist_board.dart' show rowsOf, stampOf;
import 'components.dart';
import 'tap_card.dart';
import 'manual_hierarchy.dart';
import 'manual_action_editor.dart';
import 'place_guide.dart';
import 'linked_place_guide.dart';
import 'work_issue_editor.dart';
import 'action_failure_text.dart';

/// TAP그룹 folders filter the TAP board; each TAP opens its Task.
/// Existing IDs, role checks and completion APIs remain the source of truth.
class TapWorkspace extends StatefulWidget {
  const TapWorkspace({
    super.key,
    required this.ops,
    required this.onStock,
    this.partFilter,
    this.toolbarLeading,
  });
  final OperationsController ops;
  final ValueNotifier<String?>? partFilter;
  final Widget? toolbarLeading;
  final Future<void> Function(Json) onStock;
  @override
  State<TapWorkspace> createState() => _TapWorkspaceState();
}

class _TapWorkspaceState extends State<TapWorkspace> {
  bool showCompleted = false;
  String? boardScope;
  final expandedTaps = <String>{};
  final expandedMethods = <String, String>{};
  List<String>? pendingTapOrder;
  String? localPart;
  String? get selectedPart => widget.partFilter?.value ?? localPart;

  @override
  void initState() {
    super.initState();
    widget.partFilter?.addListener(partChanged);
  }

  void partChanged() {
    if (mounted) setState(() {});
  }

  String? celebratedStepId, celebratedTaskId;
  int completionTick = 0;
  Timer? celebrationTimer;
  final settlingTasks = <String>{};
  bool mineOnly = false;
  final previewStepOrder = <String, List<String>>{};
  List<String>? previewGroupOrder;
  OperationsController get ops => widget.ops;

  void celebrate({String? stepId, String? taskId}) {
    if (!mounted) return;
    celebrationTimer?.cancel();
    setState(() {
      celebratedStepId = stepId;
      celebratedTaskId = taskId;
      completionTick++;
      if (taskId != null && !MediaQuery.disableAnimationsOf(context)) {
        settlingTasks.add(taskId);
      }
    });
    celebrationTimer = Timer(AppMotion.completionHold, () {
      if (!mounted) return;
      setState(() {
        celebratedStepId = null;
        celebratedTaskId = null;
        settlingTasks.clear();
      });
    });
  }

  @override
  void dispose() {
    celebrationTimer?.cancel();
    widget.partFilter?.removeListener(partChanged);
    super.dispose();
  }

  List<Json> get groups {
    final result =
        ops
            .rows('tasks')
            .where((t) => t['kind'] == 'routine' && t['orderId'] == null)
            .toList()
          ..sort(
            (a, b) => ((a['displayOrder'] ?? 0) as int).compareTo(
              (b['displayOrder'] ?? 0) as int,
            ),
          );
    final order = pendingTapOrder;
    if (order != null) {
      // Replace only the visible lane's positions; hidden parts retain theirs.
      final positions = [
        for (var i = 0; i < result.length; i++)
          if (order.contains(result[i]['id'])) i,
      ];
      final ordered = [
        for (final id in order) ...result.where((t) => t['id'] == id),
      ];
      for (var i = 0; i < positions.length; i++) {
        result[positions[i]] = ordered[i];
      }
    }
    return result;
  }

  List<Json> steps(Json task) {
    final result = <Json>[
      for (final step in rowsOf(task['steps'])) {...step},
    ];
    final order =
        previewStepOrder['${ops.actorId}/${ops.data?['day']}/${task['id']}'];
    if (order != null) {
      result.sort((a, b) {
        final ai = order.indexOf(a['id']), bi = order.indexOf(b['id']);
        return (ai < 0 ? order.length : ai).compareTo(
          bi < 0 ? order.length : bi,
        );
      });
    }
    return result;
  }

  int total(Json task) => steps(task).length;
  int done(Json task) =>
      steps(task).where((s) => s['completedAt'] != null).length;
  String status(Json task) {
    if (task['completedAt'] != null) return '완료';
    return '할일';
  }

  String folderOf(Json task) => task['folderId'] ?? 'general';
  List<Json> inFolder(String id) =>
      groups.where((t) => folderOf(t) == id).toList();

  List<Json> get folders {
    final result = ops.rows('checklistFolders').map((f) => {...f}).toList();
    for (final t in groups) {
      final id = folderOf(t);
      if (!result.any((f) => f['id'] == id)) {
        result.add({'id': id, 'name': id == 'general' ? '기본 업무' : '기타 업무'});
      }
    }
    final order =
        previewGroupOrder ??
        (ops.data?['bigTapOrder'] as List?)?.cast<String>() ??
        [
          'order-work',
          'marketing',
          'bone-preparation',
          'noodle-preparation',
          'service',
          'maintenance',
          'settlement',
        ];
    result.removeWhere(
      (f) =>
          ['general', 'bonejjim'].contains(f['id']) &&
          inFolder(f['id']).isEmpty,
    );
    result.sort((a, b) {
      final ai = order.indexOf(a['id']);
      final bi = order.indexOf(b['id']);
      if (ai >= 0 && bi >= 0) return ai.compareTo(bi);
      if (ai >= 0) return -1;
      if (bi >= 0) return 1;
      return a['name'].toString().compareTo(b['name'].toString());
    });
    return result;
  }

  bool hasAssigned(Json task) =>
      task['assignmentView'] is Map &&
      task['assignmentView']['mode'] != 'legacy';

  bool visibleTask(Json task) =>
      !mineOnly ||
      (hasAssigned(task)
          ? task['assignmentView']['isMine'] == true
          : legacyMine(task));
  bool legacyMine(Json task) =>
      ops.canEditTasks ||
      task['requiredRole'] == 'all' ||
      task['requiredRole'] == ops.actor['role'];
  String estimatedDuration(Json task) {
    if (task['assignmentScopeVersion'] == 2) {
      final value = task['settings']?['estimatedMinutes'];
      return value is int && value > 0
          ? context.t('work.approxMinutes', args: {'minutes': value})
          : '';
    }
    final steps = (task['steps'] as List? ?? []).whereType<Json>().toList();
    final times = steps
        .map((step) => step['settings']?['estimatedMinutes'])
        .whereType<int>()
        .where((minutes) => minutes > 0)
        .toList();
    if (times.isEmpty) return '';
    final total = times.fold<int>(0, (sum, minutes) => sum + minutes);
    return '${context.t('work.approxMinutes', args: {'minutes': total})}${times.length == steps.length ? '' : '+'}';
  }

  String place(Json task) =>
      ops
              .rows('zones')
              .where((z) => z['id'] == task['zone'])
              .firstOrNull?['name']
          as String? ??
      '';
  bool matchesPart(Json task, Json part) {
    if (hasAssigned(task)) {
      final views = [
        for (final step in steps(task))
          if (hasAssigned(step)) step['assignmentView'] as Map,
      ];
      if (views.isEmpty) views.add(task['assignmentView'] as Map);
      return views.any(
        (view) => view['partId'] == null || view['partId'] == part['id'],
      );
    }
    return task.containsKey('partId')
        ? task['partId'] == null || task['partId'] == part['id']
        : task['requiredRole'] == 'all' ||
              (part['roles'] as List? ?? []).contains(task['requiredRole']);
  }

  String role(Json task) {
    if (task.containsKey('partId')) {
      return partLabel(ops, task['partId'], context: context);
    }
    return context.t(checklistRoles[task['requiredRole']] ?? '전체 파트');
  }

  List<Json> assignees(Json task) {
    if (hasAssigned(task)) {
      final all = (task['assignmentView']['assignees'] as List? ?? [])
          .whereType<Json>();
      return {for (final person in all) person['id']: person}.values.toList();
    }
    final required = task['requiredRole'];
    if (task.containsKey('partId')
        ? task['partId'] == null
        : required == 'all') {
      return [];
    }
    final people = ops.rows('tappers').where((person) {
      if (person['active'] != true) return false;
      if (task.containsKey('partId')) {
        final ids = person['workProfile']?['partIds'] as List? ?? [];
        return ids.isEmpty || ids.contains(task['partId']);
      }
      if (required == 'cook') {
        return (person['duties'] as List? ?? const []).any(
          (duty) => duty.toString().contains('조리'),
        );
      }
      return person['rank'] == required;
    }).toList();
    people.sort((a, b) => a['id'].toString().compareTo(b['id'].toString()));
    return people;
  }

  String assigneeLabel(Json task) {
    final view = hasAssigned(task) ? task['assignmentView'] as Map : null;
    if (view != null) {
      final label =
          view['timeBandName'] ??
          (view['mode'] == 'anyone'
              ? context.t('ui.audit1279')
              : context.t('ui.audit893'));
      final partName = storeParts(
        ops,
      ).where((p) => p['id'] == view['partId']).firstOrNull;
      final displayedPart = partName == null
          ? null
          : entityDisplayName(
              context,
              ops,
              'part',
              partName['id'],
              partName['name'],
            );
      return '$label${displayedPart == null ? '' : ' · $displayedPart'} · ${context.t(view['unassigned'] == true ? '담당 미배정' : '공동 업무')}';
    }
    final people = assignees(task);
    if (task.containsKey('partId')
        ? task['partId'] == null
        : task['requiredRole'] == 'all') {
      return context.t('전체 파트');
    }
    return '${role(task)} · ${context.t(people.isEmpty ? '담당자 미지정' : '가능한 담당자')}';
  }

  String assignmentTimes(Json task, dynamic id) {
    final all = (task['assignmentView']?['assignees'] as List? ?? [])
        .whereType<Map>()
        .where((p) => p['id'] == id && p['start'] != null && p['end'] != null);
    final times = all
        .map(
          (p) =>
              '${p['start']}–${p['startDate'] != null && p['endDate'] != null && p['startDate'] != p['endDate'] ? context.t('다음 날 ') : ''}${p['end']}',
        )
        .toSet();
    return times.isEmpty ? '' : ' · ${times.join(', ')}';
  }

  Color personColor(String id) => crewColor(id);

  Color assigneeColor(Json task) {
    final people = assignees(task);
    return people.isEmpty
        ? AppColors.muted
        : personColor(people.first['id'].toString());
  }

  Widget? assigneeBadges(Json task) {
    final people = assignees(task);
    if (people.isEmpty) return null;
    return Wrap(
      spacing: 10,
      runSpacing: 4,
      children: [
        for (final person in people)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: personColor(person['id'].toString()),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  '${person['nickname']}${assignmentTimes(task, person['id'])}',
                  style: const TextStyle(fontSize: 13, color: AppColors.ink),
                ),
              ),
            ],
          ),
      ],
    );
  }

  void notice(String text) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(text)));

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: ops,
    builder: (context, _) {
      final scope =
          '${ops.actorId}/${ops.data?['workspaceId']}/${ops.data?['day']}';
      if (boardScope != scope) {
        boardScope = scope;
        expandedTaps.clear();
        expandedMethods.clear();
        previewStepOrder.clear();
        pendingTapOrder = null;
        settlingTasks.clear();
      }
      final part = storeParts(ops)
          .where((p) => p['id'] == selectedPart && p['hidden'] != true)
          .firstOrNull;
      final scoped = groups
          .where((task) => part == null || matchesPart(task, part))
          .where(visibleTask)
          .where(
            (task) =>
                (settlingTasks.contains(task['id'])
                    ? false
                    : status(task) == '완료') ==
                showCompleted,
          )
          .toList();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppViewToolbar(
            key: const ValueKey('work-view-toolbar'),
            leading: widget.toolbarLeading,
            toggle: AppViewToggle<bool>(
              key: const ValueKey('work-view-toggle'),
              values: const [false, true],
              selected: showCompleted,
              labelOf: (value) =>
                  context.t(value ? 'common.done' : 'work.todo'),
              onSelected: (value) => setState(() => showCompleted = value),
            ),
          ),
          if (!ops.canEditTasks)
            Align(
              alignment: Alignment.centerLeft,
              child: FilterChip(
                label: Text(context.t('work.myOnly')),
                selected: mineOnly,
                onSelected: (v) => setState(() => mineOnly = v),
              ),
            ),
          if (widget.partFilter == null) ...[
            _folderBar(),
            const SizedBox(height: 16),
          ],
          Row(
            children: [
              Expanded(
                child: Text(
                  showCompleted
                      ? context.t('manual.completed')
                      : 'TAP · ${context.t('전체 업무')}',
                  style: AppText.caption,
                ),
              ),
              Text('${scoped.length}', style: AppText.caption),
            ],
          ),
          if (ops.readOnly)
            Text(context.t('ui.audit431'), style: AppText.caption),
          const SizedBox(height: 12),
          _board(scoped),
        ],
      );
    },
  );

  Future<void> _reorderTaps(
    List<Json> visible,
    int oldIndex,
    int newIndex,
  ) async {
    if (ops.busy || !ops.canEditTasks) return;
    if (newIndex > oldIndex) newIndex--;
    if (oldIndex == newIndex) return;
    final ordered = [...visible];
    final moving = ordered.removeAt(oldIndex);
    ordered.insert(newIndex, moving);
    final before = newIndex + 1 < ordered.length
        ? ordered[newIndex + 1]['id'] as String
        : null;
    final scope = boardScope;
    setState(
      () => pendingTapOrder = ordered.map((t) => t['id'] as String).toList(),
    );
    if (ops.readOnly) {
      ops.previewMoveTap(
        moving['id'],
        folderOf(moving),
        'keep',
        beforeTaskId: before,
      );
    } else {
      final ok = await ops.act('move_tap', {
        'taskId': moving['id'],
        'folderId': folderOf(moving),
        'status': 'keep',
        'beforeTaskId': ?before,
      });
      if (mounted && boardScope == scope && !ok) {
        notice(actionFailureText(context, ops));
      }
    }
    if (mounted && boardScope == scope) setState(() => pendingTapOrder = null);
  }

  Widget _board(List<Json> tasks) {
    Widget card(Json t, int index) => Padding(
      key: ValueKey('sort-tap-${t['id']}'),
      padding: const EdgeInsets.only(bottom: 12),
      child: ManualFoldGroup(
        header: TapCard(
          holdCompletion: settlingTasks.contains(t['id']),
          completionTrigger:
              (celebratedTaskId == t['id'] || settlingTasks.contains(t['id']))
              ? completionTick
              : null,
          key: ValueKey('tap-${t['id']}'),
          customization: t['manualCustomization'],
          level: 'TAP',
          emoji: t['emoji'] ?? '📋',
          title: manualDisplayText(
            context,
            t['title'],
            translations: ops.data?['manualContentTranslations'],
            templateId: t['templateId'],
          ),
          subtitle:
              '${entityDisplayName(context, ops, 'folder', folderOf(t), folders.where((f) => f['id'] == folderOf(t)).firstOrNull?['name'])} · ${context.t('${t['slot']}')} · ${assigneeLabel(t)}${estimatedDuration(t).isEmpty ? '' : ' · ${estimatedDuration(t)}'}',
          accentColor: assigneeColor(t),
          assigneeBadges: assigneeBadges(t),
          dragHandle: ops.canEditTasks
              ? ReorderableDragStartListener(
                  key: ValueKey('tap-drag-${t['id']}'),
                  index: index,
                  enabled: !ops.busy,
                  child: const SizedBox(
                    width: 48,
                    height: 48,
                    child: Icon(Icons.drag_indicator, color: AppColors.muted),
                  ),
                )
              : null,
          total: total(t),
          done: done(t),
          expanded: expandedTaps.contains(t['id']),
          onOpen: () => setState(() {
            if (!expandedTaps.remove(t['id'])) expandedTaps.add(t['id']);
          }),
          checkEnabled: !ops.busy,
          onCheck: t['preparedOutputMovementId'] != null
              ? null
              : () {
                  if (settlingTasks.contains(t['id'])) return;
                  if (t['preparedItemId'] != null && status(t) != '완료') {
                    _finishPreparation(t);
                  } else {
                    _moveTap(
                      t,
                      folderOf(t),
                      status(t) == '완료' ? 'todo' : 'done',
                    );
                  }
                },
          checked: status(t) == '완료',
        ),
        children: [
          if (expandedTaps.contains(t['id']))
            Padding(
              key: ValueKey('tap-inline-${t['id']}'),
              padding: const EdgeInsets.only(top: 8),
              child: _smallBoard(t),
            ),
        ],
      ),
    );
    return KeyedSubtree(
      key: ValueKey(showCompleted ? 'lane-완료' : 'lane-할일'),
      child: tasks.isEmpty
          ? Padding(
              padding: const EdgeInsets.all(24),
              child: Text(context.t('work.empty'), style: AppText.caption),
            )
          : ops.canEditTasks
          ? ReorderableListView(
              key: const ValueKey('tap-reorder-list'),
              primary: false,
              padding: EdgeInsets.zero,
              buildDefaultDragHandles: false,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              onReorder: (oldIndex, newIndex) =>
                  _reorderTaps(tasks, oldIndex, newIndex),
              children: [
                for (final (index, task) in tasks.indexed) card(task, index),
              ],
            )
          : Column(
              children: [
                for (final (index, task) in tasks.indexed) card(task, index),
              ],
            ),
    );
  }

  Future<void> _completeTap(Json task) async {
    if (status(task) == '완료') {
      await _toggle(task, steps(task).first);
    } else if (ops.readOnly) {
      for (final step in steps(task).where((s) => s['completedAt'] == null)) {
        ops.previewToggleStep(task['id'], step['id']);
      }
      if (mounted &&
          groups.any(
            (row) => row['id'] == task['id'] && row['completedAt'] != null,
          )) {
        celebrate(taskId: task['id']);
      }
    } else {
      num? quantity;
      if (task['assignmentScopeVersion'] == 2 &&
          task['settings']?['completionPolicy']?['kind'] == 'quantity') {
        quantity = await _stepQuantity({
          'title': task['title'],
          'settings': {
            'quantitySpec':
                task['settings']['completionPolicy']['quantitySpec'],
          },
        });
        if (quantity == null || !mounted) return;
      }
      final ok = await ops.act('complete_task', {
        'taskId': task['id'],
        'quantity': ?quantity,
      });
      if (ok) {
        celebrate(taskId: task['id']);
      }
      if (!ok && mounted) notice(actionFailureText(context, ops));
    }
  }

  Future<void> _moveTap(
    Json task,
    String targetFolder,
    String targetStatus, {
    String? beforeTaskId,
  }) async {
    if (task['preparedItemId'] != null &&
        targetStatus == 'done' &&
        task['completedAt'] == null) {
      await _finishPreparation(task);
      return;
    }
    if (task['preparedOutputMovementId'] != null &&
        targetStatus != 'done' &&
        targetStatus != 'keep') {
      notice(context.t('ui.audit1211'));
      return;
    }
    final ownCompleted =
        task['completedAt'] != null &&
        task['completedBy']?['id'] == ops.actor['id'];
    if (!ops.canEditTasks && task['canComplete'] != true && !ownCompleted) {
      notice(context.t('ui.audit1212'));
      return;
    }
    if (ops.readOnly) {
      ops.previewMoveTap(
        task['id'],
        targetFolder,
        targetStatus,
        beforeTaskId: beforeTaskId,
      );
      if (targetStatus == 'done' &&
          mounted &&
          groups.any(
            (row) => row['id'] == task['id'] && row['completedAt'] != null,
          )) {
        celebrate(taskId: task['id']);
      }
      return;
    }
    final payload = <String, dynamic>{
      'taskId': task['id'],
      'folderId': targetFolder,
      'status': targetStatus,
    };
    if (targetStatus == 'done' &&
        task['assignmentScopeVersion'] == 2 &&
        task['settings']?['completionPolicy']?['kind'] == 'quantity') {
      final quantity = await _stepQuantity({
        'title': task['title'],
        'settings': {
          'quantitySpec': task['settings']['completionPolicy']['quantitySpec'],
        },
      });
      if (quantity == null || !mounted) return;
      payload['quantity'] = quantity;
    }
    if (beforeTaskId != null) payload['beforeTaskId'] = beforeTaskId;
    final ok = await ops.act('move_tap', payload);
    if (ok && targetStatus == 'done') {
      celebrate(taskId: task['id']);
    }
    if (!ok && mounted) notice(actionFailureText(context, ops));
  }

  Future<int?> _preparedQuantity(Json task) async {
    final item = ops
        .rows('preparedItems')
        .where((row) => row['id'] == task['preparedItemId'])
        .firstOrNull;
    var quantityText = '${task['plannedQuantity'] ?? 1}';
    final result = await showAppFormSheet<int>(
      context: context,
      builder: (dialog) => AppSheetPanel(
        title: Text(
          context.t(
            'ui.audit1030',
            args: {'p0': item?['name'] ?? task['title']},
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(context.t('ui.audit433')),
            TextFormField(
              initialValue: quantityText,
              onChanged: (value) => quantityText = value,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: context.t(
                  'ui.audit1031',
                  args: {'p0': item?['unit'] ?? context.t('ui.audit1213')},
                ),
              ),
            ),
          ],
        ),
        actions: [
          PressBounce(
            child: TextButton(
              onPressed: () => Navigator.pop(dialog),
              child: Text(context.t('ui.audit33')),
            ),
          ),
          PressBounce(
            child: FilledButton(
              onPressed: () =>
                  Navigator.pop(dialog, int.tryParse(quantityText)),
              child: Text(context.t('ui.audit434')),
            ),
          ),
        ],
      ),
    );
    if (result == null || !mounted) return null;
    if (result < 1 || result > 100000) {
      notice(context.t('ui.audit1214'));
      return null;
    }
    return result;
  }

  Future<void> _finishPreparation(Json task) async {
    final quantity = await _preparedQuantity(task);
    if (quantity == null || !mounted) return;
    if (ops.readOnly) {
      ops.previewCompletePreparation(task['id'], quantity);
      if (mounted &&
          groups.any(
            (row) => row['id'] == task['id'] && row['completedAt'] != null,
          )) {
        celebrate(taskId: task['id']);
      }
      return;
    }
    final ok = await ops.act('complete_preparation', {
      'taskId': task['id'],
      'quantity': quantity,
    });
    if (ok) {
      celebrate(taskId: task['id']);
    }
    if (!ok && mounted) notice(actionFailureText(context, ops));
  }

  Widget _folderBar() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          spacing: 8,
          children: [
            ChoiceChip(
              chipAnimationStyle: AppMotion.chipStyle(context),
              label: Text(context.t('ui.audit370')),
              selected: selectedPart == null,
              onSelected: (_) => setState(() => localPart = null),
            ),
            for (final part in storeParts(
              ops,
            ).where((p) => p['hidden'] != true))
              ChoiceChip(
                chipAnimationStyle: AppMotion.chipStyle(context),
                label: Text(
                  entityDisplayName(
                    context,
                    ops,
                    'part',
                    part['id'],
                    part['name'],
                  ),
                ),
                selected: selectedPart == part['id'],
                onSelected: (_) => setState(() => localPart = part['id']),
              ),
          ],
        ),
      ),
    ],
  );

  Widget _smallBoard(Json task) {
    final all = steps(task);
    String subtitleFor(Json step) {
      if (step['completedAt'] != null) {
        return context.t(
          'ui.audit2128',
          args: {
            'p0': step['completedBy']?['name'] ?? '',
            'p1': stampOf(step['completedAt']),
          },
        );
      }
      final settings = step['settings'] as Json? ?? {};
      if (settings['completionKind'] == 'quantity') {
        final spec = settings['quantitySpec'] as Json? ?? {};
        return context.t('ui.audit2129', args: {'p0': spec['unit'] ?? ''});
      }
      return '';
    }

    Widget card(Json step, int index) => Padding(
      key: ValueKey('sort-small-${step['id']}'),
      padding: const EdgeInsets.only(bottom: 8),
      child: ManualFoldGroup(
        header: TapCard(
          key: ValueKey('small-${step['id']}'),
          completionTrigger: celebratedStepId == step['id']
              ? completionTick
              : null,
          level: 'Task',
          dragHandle:
              ops.canEditTasks && task['settings']?['enforceSequence'] != true
              ? ReorderableDragStartListener(
                  index: index,
                  enabled: !ops.busy,
                  child: const SizedBox(
                    width: 32,
                    height: 48,
                    child: Icon(Icons.drag_indicator),
                  ),
                )
              : null,
          emoji: '✓',
          assigneeBadges: hasAssigned(step) ? assigneeBadges(step) : null,
          accentColor: hasAssigned(step) ? assigneeColor(step) : null,
          title: manualDisplayText(
            context,
            step['title'],
            translations: ops.data?['manualContentTranslations'],
            templateId: task['templateId'],
            stepId: step['id'],
          ),
          subtitle: [
            subtitleFor(step),
            if (hasAssigned(step)) assigneeLabel(step),
            if (step['settings']?['estimatedMinutes'] is int &&
                step['settings']['estimatedMinutes'] > 0)
              context.t(
                'ui.audit2130',
                args: {'p0': step['settings']['estimatedMinutes']},
              ),
          ].where((text) => text.isNotEmpty).join(' · '),

          sequence: index + 1,
          selected: expandedMethods[task['id']] == step['id'],
          expanded: expandedMethods[task['id']] == step['id'],
          onOpen: () => setState(() {
            if (expandedMethods[task['id']] == step['id']) {
              expandedMethods.remove(task['id']);
            } else {
              expandedMethods[task['id']] = step['id'];
            }
          }),
          checked: step['completedAt'] != null,
          locked:
              (step['canComplete'] ?? task['canComplete']) != true ||
              task['preparedOutputMovementId'] != null,
          checkEnabled: !ops.busy,
          onCheck: () => _toggle(task, step),
        ),
        children: [
          if (expandedMethods[task['id']] == step['id'])
            Padding(
              key: ValueKey('method-inline-${task['id']}-${step['id']}'),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: _inlineMethod(task, step),
            ),
        ],
      ),
    );
    Widget list =
        ops.canEditTasks && task['settings']?['enforceSequence'] != true
        ? ReorderableListView(
            primary: false,
            padding: EdgeInsets.zero,
            buildDefaultDragHandles: false,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            onReorder: (oldIndex, newIndex) async {
              if (ops.busy) return;
              final ids = all.map((s) => s['id'] as String).toList();
              if (newIndex > oldIndex) newIndex--;
              ids.insert(newIndex, ids.removeAt(oldIndex));
              if (ops.readOnly) {
                setState(
                  () =>
                      previewStepOrder['${ops.actorId}/${ops.data?['day']}/${task['id']}'] =
                          ids,
                );
                notice(context.t('ui.audit1215'));
              } else {
                final ok = await ops.act('reorder_small_taps', {
                  'taskId': task['id'],
                  'stepIds': ids,
                });
                if (!ok && mounted) notice(actionFailureText(context, ops));
              }
            },
            children: [
              for (final (index, step) in all.indexed) card(step, index),
            ],
          )
        : Column(
            children: [
              for (final (index, step) in all.indexed) card(step, index),
            ],
          );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        list,
        if (task['assignmentScopeVersion'] == 2 &&
            task['settings']?['completionPolicy']?['kind'] == 'quantity' &&
            task['completedAt'] == null &&
            all.every((s) => s['completedAt'] != null))
          FilledButton(
            onPressed: ops.busy || ops.readOnly || task['canComplete'] != true
                ? null
                : () => _completeTap(task),
            child: Text(context.t('ui.audit435')),
          ),
      ],
    );
  }

  Future<void> workIssue(Json task, bool resolve) async {
    if (!resolve) {
      await showAppFormSheet<void>(
        context: context,
        builder: (_) => WorkIssueEditor(ops: ops, task: task),
      );
      return;
    }
    final actor = ops.actorId, workspace = ops.data?['workspaceId'];
    var input = '';
    var severity = 'blocked';
    final reason = await showAppDialog<String>(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (c, update) => AlertDialog(
          title: Text(context.t(resolve ? 'issue.resolve' : 'issue.report')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!resolve)
                DropdownButtonFormField<String>(
                  initialValue: severity,
                  items: [
                    DropdownMenuItem(
                      value: 'blocked',
                      child: Text(context.t('issue.blocked')),
                    ),
                    DropdownMenuItem(
                      value: 'note',
                      child: Text(context.t('issue.note')),
                    ),
                  ],
                  onChanged: (v) => update(() => severity = v!),
                ),
              TextFormField(
                initialValue: input,
                onChanged: (value) => input = value,
                maxLines: 4,
                maxLength: 500,
                decoration: InputDecoration(
                  labelText: context.t('issue.reason'),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c),
              child: Text(context.t('common.cancel')),
            ),
            FilledButton(
              onPressed: () {
                if (input.trim().isNotEmpty) {
                  Navigator.pop(c, input.trim());
                }
              },
              child: Text(context.t('issue.record')),
            ),
          ],
        ),
      ),
    );
    if (reason == null ||
        !mounted ||
        actor != ops.actorId ||
        workspace != ops.data?['workspaceId']) {
      return;
    }
    final ok = await ops.act(
      resolve ? 'resolve_work_issue' : 'flag_work_issue',
      {
        'taskId': task['id'],
        'reason': reason,
        if (!resolve) 'severity': severity,
      },
    );
    if (mounted) {
      notice(ok ? context.t('issue.saved') : actionFailureText(context, ops));
    }
  }

  Widget _actionPhoto(Json step) {
    final value = resolveManualMediaUrl(step['imageUrl'] as String);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          label: '${step['title']} ${context.t('manual.photo')}',
          image: true,
          child: placePhoto(value, ops: ops),
        ),
        PressBounce(
          child: TextButton.icon(
            icon: const Icon(Icons.zoom_in),
            label: Text(context.t('manual.openPhoto')),
            onPressed: () {
              final actor = ops.actorId;
              final workspace = ops.data?['workspaceId'];
              final day = ops.data?['day'];
              showAppSheet<void>(
                context,
                builder: (_) => AppEditorScaffold(
                  title: '${context.t('manual.photo')} · ${step['title']}',
                  body: ListenableBuilder(
                    listenable: ops,
                    builder: (context, _) =>
                        actor != ops.actorId ||
                            workspace != ops.data?['workspaceId'] ||
                            day != ops.data?['day']
                        ? Padding(
                            padding: const EdgeInsets.all(24),
                            child: Information(context.t('manual.changedTask')),
                          )
                        : Center(
                            child: InteractiveViewer(
                              minScale: 1,
                              maxScale: 5,
                              child: placePhoto(value, ops: ops),
                            ),
                          ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  String? _methodBlocked(Json task, Json step) {
    if (task['preparedOutputMovementId'] != null) {
      return context.t('ui.audit1211');
    }
    if (step['completedAt'] != null) {
      if (ops.readOnly && step['preview'] != true) {
        return context.t('ui.audit1217');
      }
      if (!ops.canEditTasks && step['completedBy']?['id'] != ops.actorId) {
        return context.t('work.undoRestricted');
      }
      return null;
    }
    if (task['workIssue']?['status'] == 'open' &&
        task['workIssue']?['blocksCompletion'] != false) {
      return context.t('work.issueBlocked');
    }
    if ((step['canComplete'] ?? task['canComplete']) != true) {
      return context.t('work.blocked');
    }
    final all = steps(task);
    final at = all.indexWhere((s) => s['id'] == step['id']);
    if (task['settings']?['enforceSequence'] == true &&
        all.take(at < 0 ? 0 : at).any((s) => s['completedAt'] == null)) {
      return context.t('work.sequence');
    }
    return null;
  }

  Widget _inlineMethod(Json task, Json step) {
    final blocked = _methodBlocked(task, step);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _manual(task, step),
        const SizedBox(height: 16),
        if (blocked != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(blocked, style: AppText.caption),
          ),
        if (ops.error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              '${actionFailureText(context, ops)}\n${ops.error}',
              style: AppText.caption.copyWith(color: AppColors.accent),
            ),
          ),
        PressBounce(
          child: FilledButton.icon(
            key: ValueKey('method-check-${task['id']}-${step['id']}'),
            onPressed: ops.busy || blocked != null
                ? null
                : () => _toggle(task, step),
            icon: Icon(step['completedAt'] != null ? Icons.undo : Icons.check),
            label: Text(
              context.t(
                ops.busy
                    ? 'common.saving'
                    : step['completedAt'] != null
                    ? 'manual.undoCompletion'
                    : 'work.completeAction',
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _manual(Json task, Json step) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      ManualCustomizationBadge(value: task['manualCustomization']),
      SharedPlaceLinks(ops: ops, row: task),
      TranslatedContent(
        ops: ops,
        kind: 'task',
        entityId: task['id'],
        stepId: step['id'],
        source: step,
        builder: (context, displayed) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${displayed['title']}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text('${displayed['manual'] ?? ''}', style: AppText.body),
            if ('${displayed['tip'] ?? ''}'.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Information(
                  '${context.t('manual.tip')} · ${displayed['tip']}',
                ),
              ),
          ],
        ),
      ),
      if (step['linkedPlace'] is Map)
        LinkedPlaceGuide(
          ops: ops,
          place: Map<String, dynamic>.from(step['linkedPlace']),
        ),
      if ((step['imageUrl'] ?? '').toString().isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(top: AppSpacing.medium),
          child: _actionPhoto(step),
        ),
      if (task['workIssue']?['photo'] is String)
        placePhoto(task['workIssue']['photo'], ops: ops),
      if (task['workIssue'] != null)
        Information(
          '${context.t('issue.report')} · ${task['workIssue']['reason']}\n${task['workIssue']['resolution'] ?? (task['workIssue']['blocksCompletion'] == false ? context.t('issue.note') : context.t('work.issueBlocked'))}',
        ),
      if (task['completedAt'] == null || task['workIssue']?['status'] == 'open')
        Wrap(
          children: [
            TextButton(
              onPressed:
                  ops.readOnly ||
                      task['completedAt'] != null ||
                      (task['canComplete'] != true && !ops.canEditTasks)
                  ? null
                  : () => workIssue(task, false),
              child: Text(context.t('issue.report')),
            ),
            if (ops.canEditTasks && task['workIssue']?['status'] == 'open')
              TextButton(
                onPressed: ops.readOnly ? null : () => workIssue(task, true),
                child: Text(context.t('issue.resolve')),
              ),
          ],
        ),
      for (final ref in (task['knowledgeSnapshots'] as List? ?? []))
        ExpansionTile(
          title: Text(context.t('ui.audit1032', args: {'p0': ref['title']})),
          children: [
            for (final item in (ref['steps'] as List? ?? []))
              ListTile(
                title: Text('${item['title']}'),
                subtitle: Text('${item['manual']}'),
              ),
          ],
        ),
      if (step['evidence'] != null)
        Text(
          context.t('ui.audit1033', args: {'p0': step['evidence']['value']}),
        ),
      if ((step['tags'] as List? ?? []).isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Wrap(
            spacing: 6,
            children: [
              for (final tag in step['tags']) Chip(label: Text('#$tag')),
            ],
          ),
        ),
      if (ops.canEditTasks && step['completedAt'] == null)
        PressBounce(
          child: TextButton.icon(
            icon: const Icon(Icons.edit_outlined),
            label: Text(context.t('manual.editInline')),
            onPressed: ops.readOnly
                ? null
                : () => showAppFormSheet<void>(
                    context: context,
                    builder: (_) =>
                        ManualActionEditor(ops: ops, task: task, step: step),
                  ),
          ),
        ),
      ManualMediaView(step: step, ops: ops, showPhoto: false),
    ],
  );
  Future<bool> _toggle(Json task, Json step) async {
    if (ops.busy) return false;
    final currentTask = groups.where((t) => t['id'] == task['id']).firstOrNull;
    final currentStep = currentTask == null
        ? null
        : steps(currentTask).where((s) => s['id'] == step['id']).firstOrNull;
    if (currentTask == null ||
        currentStep == null ||
        currentStep['completedAt'] != step['completedAt']) {
      notice(context.t('manual.changedTask'));
      return false;
    }
    task = currentTask;
    step = currentStep;
    final openingActor = ops.actorId;
    final openingWorkspace = ops.data?['workspaceId'];
    final openingDay = ops.data?['day'];
    final openingRevision = ops.data?['revision'];
    final checked = step['completedAt'] != null;
    if (!checked &&
        task['workIssue']?['status'] == 'open' &&
        task['workIssue']?['blocksCompletion'] != false) {
      notice(context.t('work.issueBlocked'));
      return false;
    }
    final sequence = steps(task);
    final currentIndex = sequence.indexWhere((s) => s['id'] == step['id']);
    if (!checked &&
        task['settings']?['enforceSequence'] == true &&
        sequence
            .take(currentIndex < 0 ? 0 : currentIndex)
            .any((s) => s['completedAt'] == null)) {
      notice(context.t('work.sequence'));
      return false;
    }
    if (checked && task['preparedOutputMovementId'] != null) {
      notice(context.t('ui.audit1211'));
      return false;
    }
    if (!checked && (step['canComplete'] ?? task['canComplete']) != true) {
      notice(context.t('work.blocked'));
      return false;
    }
    if (checked) {
      if (!ops.canEditTasks && step['completedBy']?['id'] != ops.actor['id']) {
        notice(context.t('work.undoRestricted'));
        return false;
      }
      final confirmed = await showAppDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: Text(context.t('ui.audit436')),
          content: Text(step['title']),
          actions: [
            PressBounce(
              child: TextButton(
                onPressed: () => Navigator.pop(c, false),
                child: Text(context.t('ui.audit33')),
              ),
            ),
            PressBounce(
              child: FilledButton(
                onPressed: () => Navigator.pop(c, true),
                child: Text(context.t('ui.audit220')),
              ),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return false;
      if (openingActor != ops.actorId ||
          openingWorkspace != ops.data?['workspaceId'] ||
          openingDay != ops.data?['day'] ||
          ops.busy) {
        return false;
      }
    }
    if (ops.readOnly) {
      if (checked && step['preview'] != true) {
        notice(context.t('ui.audit1217'));
        return false;
      }
      if (!checked &&
          task['preparedItemId'] != null &&
          steps(task).where((s) => s['completedAt'] == null).length == 1) {
        final quantity = await _preparedQuantity(task);
        if (!mounted ||
            openingActor != ops.actorId ||
            openingWorkspace != ops.data?['workspaceId'] ||
            openingDay != ops.data?['day']) {
          return false;
        }
        if (quantity != null) {
          ops.previewCompletePreparation(task['id'], quantity);
        }
      } else {
        ops.previewToggleStep(task['id'], step['id']);
      }
      if (!checked && mounted) {
        final current = groups
            .where((row) => row['id'] == task['id'])
            .firstOrNull;
        final updated = current == null
            ? null
            : steps(
                current,
              ).where((row) => row['id'] == step['id']).firstOrNull;
        if (updated?['completedAt'] != null) {
          celebrate(
            stepId: step['id'],
            taskId: current?['completedAt'] != null ? task['id'] : null,
          );
        }
      }
      final updatedTask = groups
          .where((t) => t['id'] == task['id'])
          .firstOrNull;
      final updatedStep = updatedTask == null
          ? null
          : steps(updatedTask).where((s) => s['id'] == step['id']).firstOrNull;
      return updatedStep != null &&
          (updatedStep['completedAt'] != null) != checked;
    } else {
      num? quantity;
      if (!checked &&
          task['preparedItemId'] != null &&
          steps(task).where((s) => s['completedAt'] == null).length == 1) {
        quantity = await _preparedQuantity(task);
        if (quantity == null || !mounted) return false;
      } else if (!checked &&
          step['settings']?['completionKind'] == 'quantity') {
        quantity = await _stepQuantity(step);
        if (quantity == null || !mounted) return false;
      }
      String? evidence;
      if (!checked &&
          task['workEvent'] != null &&
          task['knowledge']?['safetyReviewRequired'] == true) {
        var input = '';
        evidence = await showAppDialog<String>(
          context: context,
          builder: (c) => AlertDialog(
            title: Text(context.t('ui.audit1034', args: {'p0': step['title']})),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('${task['settings']?['operatingStandard'] ?? ''}'),
                  TextFormField(
                    initialValue: input,
                    onChanged: (value) => input = value,
                    maxLength: 500,
                    maxLines: 4,
                    decoration: InputDecoration(
                      labelText: context.t('ui.audit437'),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(c),
                child: Text(context.t('ui.audit33')),
              ),
              FilledButton(
                onPressed: () {
                  if (input.trim().isNotEmpty) {
                    Navigator.pop(c, input.trim());
                  }
                },
                child: Text(context.t('ui.audit438')),
              ),
            ],
          ),
        );
        if (evidence == null || !mounted) return false;
      }
      if (openingActor != ops.actorId ||
          openingWorkspace != ops.data?['workspaceId'] ||
          openingDay != ops.data?['day']) {
        return false;
      }
      final success = await ops.act(checked ? 'reopen_step' : 'complete_step', {
        'revision': openingRevision,
        'taskId': task['id'],
        'stepId': step['id'],
        'quantity': ?quantity,
        'evidence': ?evidence,
      });
      if (mounted && !success) notice(actionFailureText(context, ops));
      if (mounted && success && !checked) {
        final current = ops
            .rows('tasks')
            .where((row) => row['id'] == task['id'])
            .firstOrNull;
        celebrate(
          stepId: step['id'],
          taskId: current?['completedAt'] != null ? task['id'] : null,
        );
      }
      return success;
    }
  }

  Future<num?> _stepQuantity(Json step) async {
    final unit = '${step['settings']?['quantitySpec']?['unit'] ?? '개'}';
    final places =
        (step['settings']?['quantitySpec']?['decimalPlaces'] as num?)
            ?.toInt() ??
        0;
    var quantityText = '';
    final result = await showAppFormSheet<num>(
      context: context,
      builder: (dialog) => AppSheetPanel(
        title: Text(context.t('ui.audit1035', args: {'p0': step['title']})),
        content: TextFormField(
          initialValue: quantityText,
          onChanged: (value) => quantityText = value,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: context.t('ui.audit1036', args: {'p0': unit}),
            helperText: places == 0
                ? context.t('ui.audit1037')
                : context.t('ui.audit1038', args: {'p0': places}),
          ),
        ),
        actions: [
          PressBounce(
            child: TextButton(
              onPressed: () => Navigator.pop(dialog),
              child: Text(context.t('ui.audit33')),
            ),
          ),
          PressBounce(
            child: FilledButton(
              onPressed: () =>
                  Navigator.pop(dialog, num.tryParse(quantityText.trim())),
              child: Text(context.t('ui.audit434')),
            ),
          ),
        ],
      ),
    );
    if (result == null || !mounted) return null;
    if (result <= 0 ||
        result > 100000 ||
        result *
                (places == 0
                    ? 1
                    : places == 1
                    ? 10
                    : 100) !=
            (result *
                    (places == 0
                        ? 1
                        : places == 1
                        ? 10
                        : 100))
                .round()) {
      notice(context.t('ui.audit1218'));
      return null;
    }
    return result;
  }
}
