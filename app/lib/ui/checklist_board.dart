import '../l10n/app_localizations.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../domain/checklist_draft.dart';
import '../state/operations_controller.dart';
import 'checklist_editor.dart';
import 'components.dart';

List<Json> rowsOf(dynamic value) => (value as List? ?? []).cast<Json>();
String stampOf(dynamic value) {
  final date = DateTime.tryParse(
    '$value',
  )?.toUtc().add(const Duration(hours: 9));
  return date == null
      ? ''
      : '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
}

/// Today's shared checklist: groups of activities that anyone allowed can tap to confirm.
class ChecklistBoard extends StatefulWidget {
  const ChecklistBoard({super.key, required this.ops, required this.onStock});
  final OperationsController ops;
  final Future<void> Function(Json task) onStock;
  @override
  State<ChecklistBoard> createState() => _ChecklistBoardState();
}

class _ChecklistBoardState extends State<ChecklistBoard> {
  String slot = '전체', folder = 'all-filter';
  bool mineOnly = false;
  final collapsed = <String>{};
  final openManuals = <String>{};
  // Public review cannot write; taps are shown on this device only and never saved.
  final previewChecks = <String, Json>{};
  bool previewNoticeShown = false;

  OperationsController get ops => widget.ops;

  String keyOf(Json task, Json step) => '${task['id']}/${step['id']}';

  /// The step as the viewer sees it, including device-local preview checks.
  Json effective(Json task, Json step) {
    final preview = previewChecks[keyOf(task, step)];
    return preview == null ? step : {...step, ...preview};
  }

  List<Json> stepsOf(Json task) => [
    for (final step in rowsOf(task['steps'])) effective(task, step),
  ];

  bool isComplete(Json task) {
    final steps = stepsOf(task);
    return task['completedAt'] != null ||
        (steps.isNotEmpty && steps.every((s) => s['completedAt'] != null));
  }

  void notice(String message) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));

  String folderOf(Json task) => task['kind'] == 'stock'
      ? 'stock'
      : (task['folderId'] ?? 'general') as String;

  bool mine(Json task) =>
      task['requiredRole'] == 'all' ||
      task['requiredRole'] == ops.actor['role'];

  @override
  Widget build(BuildContext context) {
    final all = ops.rows('tasks');
    final groups = all.where((t) => t['kind'] == 'routine').toList()
      ..sort(
        (a, b) => ((a['displayOrder'] ?? -1) as int).compareTo(
          (b['displayOrder'] ?? -1) as int,
        ),
      );
    final stock = all.where((t) => t['kind'] == 'stock').toList();
    final folders = [
      ...ops.rows('checklistFolders'),
      if (ops.rows('checklistFolders').isEmpty)
        {'id': 'general', 'name': '기본 업무'},
      if (stock.isNotEmpty) {'id': 'stock', 'name': '발주 후 재고 확인'},
    ];
    bool matches(Json t) =>
        (slot == '전체' || t['slot'] == slot) &&
        (!mineOnly || ops.isLeader || mine(t)) &&
        (folder == 'all-filter' || folderOf(t) == folder);
    final visibleGroups = groups.where(matches).toList();
    final visibleStock = stock.where(matches).toList();
    final steps = [for (final g in groups) ...stepsOf(g)];
    final doneSteps = steps.where((s) => s['completedAt'] != null).length;
    int remaining(String s) => groups
        .where((g) => s == '전체' || g['slot'] == s)
        .fold(
          0,
          (n, g) =>
              n +
              rowsOf(g['steps']).where((x) => x['completedAt'] == null).length,
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageHeading(
          'TODAY · TAP TO CHECK',
          context.t('ui.audit213'),
          context.t('ui.audit214'),
        ),
        _Progress(
          done: doneSteps,
          total: steps.length,
          groupsDone: groups.where(isComplete).length,
          groups: groups.length,
        ),
        const SizedBox(height: 14),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final s in ['전체', ...checklistSlots])
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    chipAnimationStyle: AppMotion.chipStyle(context),
                    label: Text(
                      remaining(s) == 0 ? s : '$s ${remaining(s)}',
                      style: const TextStyle(fontSize: 13),
                    ),
                    selected: slot == s,
                    onSelected: (_) => setState(() => slot = s),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (!ops.isLeader)
              FilterChip(
                chipAnimationStyle: AppMotion.chipStyle(context),
                label: Text(context.t('ui.audit215')),
                selected: mineOnly,
                onSelected: (v) => setState(() => mineOnly = v),
              ),
            if (folders.length > 1)
              for (final f in [
                {'id': 'all-filter', 'name': '전체 폴더'},
                ...folders,
              ])
                ChoiceChip(
                  chipAnimationStyle: AppMotion.chipStyle(context),
                  label: Text(f['name']),
                  selected: folder == f['id'],
                  onSelected: (_) => setState(() => folder = f['id']),
                ),
            if (ops.isLeader)
              PressBounce(
                child: OutlinedButton.icon(
                  onPressed: ops.busy
                      ? null
                      : () => showAppSheet(
                          context,
                          builder: (_) => ChecklistEditor(ops: ops),
                        ),
                  icon: const Icon(Icons.tune),
                  label: Text(context.t('ui.audit216')),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        if (visibleGroups.isEmpty && visibleStock.isEmpty)
          Information(context.t('ui.audit217')),
        for (final g in visibleGroups) groupCard(g),
        for (final t in visibleStock) stockCard(t),
      ],
    );
  }

  Future<void> check(Json task, Json step) async {
    if (ops.busy) return;
    if (task['canComplete'] != true) {
      notice(
        context.t(
          'ui.audit1125',
          args: {'p0': checklistRoles[task['requiredRole']]},
        ),
      );
      return;
    }
    HapticFeedback.mediumImpact();
    if (ops.readOnly) {
      setState(() {
        previewChecks[keyOf(task, step)] = {
          'completedAt': DateTime.now().toUtc().toIso8601String(),
          'completedBy': {'id': ops.actor['id'], 'name': ops.actor['name']},
          'preview': true,
        };
      });
      if (!previewNoticeShown) {
        previewNoticeShown = true;
        notice(context.t('ui.audit1126'));
      }
      return;
    }
    await ops.act('complete_step', {
      'taskId': task['id'],
      'stepId': step['id'],
    });
  }

  Future<void> undo(Json task, Json step) async {
    final by = step['completedBy'] as Json?;
    final allowed = ops.isLeader || by?['id'] == ops.actor['id'];
    if (ops.busy) return;
    if (!allowed) {
      notice(
        context.t(
          'ui.audit1127',
          args: {'p0': by?['name'] ?? context.t('ui.audit1249')},
        ),
      );
      return;
    }
    final confirm = await showAppDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(context.t('ui.audit218')),
        content: Text(context.t('ui.audit703', args: {'p0': step['title']})),
        actions: [
          PressBounce(
            child: TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: Text(context.t('ui.audit219')),
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
    if (confirm != true || !mounted) return;
    if (step['preview'] == true) {
      setState(() => previewChecks.remove(keyOf(task, step)));
      return;
    }
    await ops.act('reopen_step', {'taskId': task['id'], 'stepId': step['id']});
  }

  Widget groupCard(Json task) {
    final steps = stepsOf(task);
    final done = steps.where((s) => s['completedAt'] != null).length;
    final complete = isComplete(task);
    final id = task['id'] as String;
    // Finished groups fold away by default; unfinished ones stay open until tapped.
    final isCollapsed = complete
        ? !collapsed.contains('open-$id')
        : collapsed.contains(id);
    final place = ops
        .rows('zones')
        .where((z) => z['id'] == task['zone'])
        .firstOrNull?['name'];
    final canComplete = task['canComplete'] == true;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Surface(
        padding: EdgeInsets.zero,
        color: complete ? AppColors.elevated : AppColors.surface,
        child: Column(
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(22),
              onTap: () => setState(() {
                if (complete) {
                  isCollapsed
                      ? collapsed.add('open-$id')
                      : collapsed.remove('open-$id');
                } else {
                  isCollapsed ? collapsed.remove(id) : collapsed.add(id);
                }
              }),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
                child: Row(
                  children: [
                    const Icon(
                      CupertinoIcons.checkmark_circle,
                      size: 22,
                      color: AppColors.muted,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            task['title'],
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${task['slot']} · ${checklistRoles[task['requiredRole']] ?? '누구나'}${place == null ? '' : ' · $place'}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    _Ring(done: done, total: steps.length),
                    Icon(
                      isCollapsed ? Icons.expand_more : Icons.expand_less,
                      color: AppColors.muted,
                    ),
                  ],
                ),
              ),
            ),
            if (!isCollapsed) ...[
              const Divider(height: 1),
              for (final step in steps)
                activityTile(task, step, canComplete: canComplete),
              if (!canComplete && !complete)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
                  child: Text(
                    context.t(
                      'ui.audit704',
                      args: {'p0': checklistRoles[task['requiredRole']]},
                    ),
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.muted,
                    ),
                  ),
                ),
              if (complete)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 14),
                  child: Text(
                    task['completedAt'] == null
                        ? context.t('ui.audit705')
                        : context.t(
                            'ui.audit706',
                            args: {
                              'p0': task['completedBy']?['name'] ?? '',
                              'p1': stampOf(task['completedAt']),
                            },
                          ),
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.green,
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget activityTile(Json task, Json step, {required bool canComplete}) {
    final key = '${task['id']}/${step['id']}';
    final done = step['completedAt'] != null;
    final open = openManuals.contains(key);
    final by = step['completedBy'] as Json?;
    // Always tappable so a blocked tap explains itself instead of doing nothing.
    final enabled = !ops.busy;
    return Column(
      children: [
        InkWell(
          onTap: () => setState(
            () => open ? openManuals.remove(key) : openManuals.add(key),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 4, 8, 4),
            child: Row(
              children: [
                Semantics(
                  button: true,
                  label: done
                      ? context.t('ui.audit707', args: {'p0': step['title']})
                      : context.t('ui.audit708', args: {'p0': step['title']}),
                  child: InkResponse(
                    radius: 28,
                    onTap: enabled
                        ? () => done ? undo(task, step) : check(task, step)
                        : null,
                    child: Container(
                      width: 48,
                      height: 48,
                      alignment: Alignment.center,
                      child: AnimatedContainer(
                        duration: AppMotion.duration(context, AppMotion.quick),
                        curve: AppMotion.enterCurve,
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: done ? AppColors.green : Colors.transparent,
                          border: Border.all(
                            color: done || canComplete
                                ? AppColors.green
                                : AppColors.line,
                            width: 2,
                          ),
                        ),
                        child: done
                            ? const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 22,
                              )
                            : canComplete
                            ? null
                            : const Icon(
                                Icons.lock_outline,
                                size: 16,
                                color: AppColors.muted,
                              ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        step['title'],
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: done ? AppColors.muted : AppColors.ink,
                        ),
                      ),
                      Text(
                        done
                            ? context.t(
                                'ui.audit709',
                                args: {
                                  'p0': by?['name'] ?? '',
                                  'p1': stampOf(step['completedAt']),
                                  'p2': step['preview'] == true
                                      ? context.t('ui.audit1128')
                                      : '',
                                },
                              )
                            : open
                            ? context.t('ui.audit710')
                            : context.t('ui.audit711'),
                        style: TextStyle(
                          fontSize: 13,
                          color: done ? AppColors.green : AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  open ? Icons.expand_less : Icons.menu_book_outlined,
                  size: 20,
                  color: AppColors.muted,
                ),
              ],
            ),
          ),
        ),
        if (open)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.paper,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step['manual'] ?? '',
                    style: const TextStyle(height: 1.6, fontSize: 13),
                  ),
                  if ((step['tip'] ?? '').isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        '💡 ${step['tip']}',
                        style: const TextStyle(
                          fontSize: 13,
                          height: 1.6,
                          color: AppColors.muted,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget stockCard(Json task) {
    final complete = task['completedAt'] != null;
    final place = ops
        .rows('zones')
        .where((z) => z['id'] == task['zone'])
        .firstOrNull?['name'];
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Surface(
        padding: const EdgeInsets.all(16),
        color: complete ? AppColors.elevated : AppColors.surface,
        child: Row(
          children: [
            const Icon(
              CupertinoIcons.cube_box,
              size: 22,
              color: AppColors.muted,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task['title'],
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    complete
                        ? context.t(
                            'ui.audit712',
                            args: {
                              'p0': task['completedBy']?['name'] ?? '',
                              'p1': stampOf(task['completedAt']),
                            },
                          )
                        : context.t(
                            'ui.audit713',
                            args: {'p0': place == null ? '' : ' · $place'},
                          ),
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
            if (!complete)
              PressBounce(
                child: FilledButton(
                  onPressed:
                      ops.busy || ops.readOnly || task['canComplete'] != true
                      ? null
                      : () => widget.onStock(task),
                  child: Text(context.t('ui.audit221')),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Progress extends StatelessWidget {
  const _Progress({
    required this.done,
    required this.total,
    required this.groupsDone,
    required this.groups,
  });
  final int done, total, groupsDone, groups;
  @override
  Widget build(BuildContext context) => Surface(
    color: AppColors.lime.withValues(alpha: .5),
    padding: const EdgeInsets.all(18),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                total == 0
                    ? context.t('ui.audit714')
                    : done == total
                    ? context.t('ui.audit715')
                    : context.t('ui.audit716', args: {'p0': done, 'p1': total}),
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ),
            Text(
              context.t('ui.audit717', args: {'p0': groupsDone, 'p1': groups}),
              style: const TextStyle(fontSize: 13, color: AppColors.muted),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: AppLinearProgress(
            value: total == 0 ? 0 : done / total,
            minHeight: 10,
            backgroundColor: AppColors.surface,
            color: AppColors.green,
          ),
        ),
      ],
    ),
  );
}

class _Ring extends StatelessWidget {
  const _Ring({required this.done, required this.total});
  final int done, total;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 44,
    height: 44,
    child: Stack(
      alignment: Alignment.center,
      children: [
        AppCircularProgress(
          value: total == 0 ? 0 : done / total,
          strokeWidth: 4,
          backgroundColor: AppColors.line,
          color: AppColors.green,
        ),
        Text(
          '$done/$total',
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        ),
      ],
    ),
  );
}
