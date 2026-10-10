import '../l10n/app_localizations.dart';
import '../l10n/manual_text_scope.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../state/operations_controller.dart';
import 'components.dart';

/// An execution view over existing Task IDs, never a second completion store.
class ManualActionSlides extends StatefulWidget {
  const ManualActionSlides({
    super.key,
    required this.ops,
    required this.task,
    required this.steps,
    required this.initialStepId,
    required this.bodyBuilder,
    required this.onToggle,
    this.onCompleteQuantity,
  });

  final OperationsController ops;
  final Json task;
  final List<Json> steps;
  final String initialStepId;
  final Widget Function(Json task, Json step) bodyBuilder;
  final Future<bool> Function(Json task, Json step) onToggle;
  final Future<void> Function(Json task)? onCompleteQuantity;

  @override
  State<ManualActionSlides> createState() => _ManualActionSlidesState();
}

class _ManualActionSlidesState extends State<ManualActionSlides> {
  // Pin identity and order for this open view. A refresh must not turn the
  // current page into another Task or another store's similarly named ID.
  late final List<String> ids;
  late final String actor;
  late final Object? workspace, day;
  late int index;
  late final PageController pages;

  @override
  void initState() {
    super.initState();
    ids = widget.steps.map((step) => step['id'] as String).toList();
    actor = widget.ops.actorId;
    workspace = widget.ops.data?['workspaceId'];
    day = widget.ops.data?['day'];
    index = ids.indexOf(widget.initialStepId).clamp(0, ids.length - 1);
    pages = PageController(initialPage: index);
  }

  bool saving = false;
  String? failure;

  bool get sameSource =>
      widget.ops.actorId == actor &&
      widget.ops.data?['workspaceId'] == workspace &&
      widget.ops.data?['day'] == day;
  Json? get task => sameSource
      ? widget.ops
            .rows('tasks')
            .where((t) => t['id'] == widget.task['id'])
            .firstOrNull
      : null;
  Json? stepOf(Json? task, String id) => (task?['steps'] as List? ?? [])
      .whereType<Json>()
      .where((step) => step['id'] == id)
      .firstOrNull;

  @override
  void dispose() {
    pages.dispose();
    super.dispose();
  }

  void move(int next) {
    if (saving || next < 0 || next >= ids.length || !pages.hasClients) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      pages.jumpToPage(next);
    } else {
      pages.animateToPage(
        next,
        duration: AppMotion.sheet,
        curve: AppMotion.enterCurve,
      );
    }
  }

  String? blocked(Json? task, Json? step) {
    if (task == null || step == null) return context.t('manual.changedTask');
    if (task['preparedOutputMovementId'] != null) {
      return '완성 수량이 반영됐어요. 실제 수량 보정을 사용해 주세요.';
    }
    if (step['completedAt'] != null) {
      if (widget.ops.readOnly && step['preview'] != true) {
        return '기존 확인 기록은 체험에서 변경할 수 없어요.';
      }
      if (!widget.ops.canEditTasks && step['completedBy']?['id'] != actor) {
        return context.t('work.undoRestricted');
      }
      return null;
    }
    if (task['workIssue']?['status'] == 'open') {
      return context.t('work.issueBlocked');
    }
    if ((step['canComplete'] ?? task['canComplete']) != true) {
      return context.t('work.blocked');
    }
    final current = (task['steps'] as List? ?? []).whereType<Json>().toList();
    final at = current.indexWhere((row) => row['id'] == step['id']);
    if (task['settings']?['enforceSequence'] == true &&
        current
            .take(at < 0 ? 0 : at)
            .any((row) => row['completedAt'] == null)) {
      return context.t('work.sequence');
    }
    return null;
  }

  Future<void> toggle(Json task, Json step) async {
    if (saving || widget.ops.busy || blocked(task, step) != null) return;
    final openingIndex = index;
    final wasDone = step['completedAt'] != null;
    setState(() {
      saving = true;
      failure = null;
    });
    bool saved = false;
    try {
      saved = await widget.onToggle(task, step);
    } catch (_) {
      if (mounted) failure = context.t('work.saveFailed');
    }
    if (!mounted) return;
    setState(() {
      saving = false;
      if (!saved) failure ??= widget.ops.error;
    });
    // Navigation itself is read-only. Only this successful explicit check can
    // advance, and the final completion and every undo remain on their page.
    if (saved &&
        sameSource &&
        !wasDone &&
        index == openingIndex &&
        stepOf(this.task, ids[index])?['completedAt'] != null) {
      move(index + 1);
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.ops,
    builder: (context, _) {
      final currentTask = task;
      final step = stepOf(currentTask, ids[index]);
      final done = step?['completedAt'] != null;
      final reason = blocked(currentTask, step);
      final busy = saving || widget.ops.busy;
      return CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.arrowLeft): () =>
              move(index - 1),
          const SingleActivator(LogicalKeyboardKey.arrowRight): () =>
              move(index + 1),
        },
        child: Focus(
          autofocus: true,
          child: AppEditorScaffold(
            title: manualDisplayText(
              context,
              widget.task['title'] as String,
              translations: widget.ops.data?['manualContentTranslations'],
              templateId: widget.task['templateId'],
            ),
            subtitle:
                '${context.t('work.actions', args: {'current': index + 1, 'total': ids.length})}${widget.ops.readOnly ? ' · ${context.t('work.preview')}' : ''}',
            onClose: () => Navigator.pop(context),
            body: PageView.builder(
              key: const ValueKey('manual-action-pages'),
              controller: pages,
              physics: saving ? const NeverScrollableScrollPhysics() : null,
              itemCount: ids.length,
              onPageChanged: (value) => setState(() {
                index = value;
                failure = null;
              }),
              itemBuilder: (context, page) {
                final row = stepOf(currentTask, ids[page]);
                return SingleChildScrollView(
                  key: PageStorageKey(
                    'manual-action/${widget.task['id']}/${ids[page]}',
                  ),
                  padding: const EdgeInsets.all(AppSpacing.large),
                  child: currentTask == null || row == null
                      ? Information(context.t('manual.changedTask'))
                      : widget.bodyBuilder(currentTask, row),
                );
              },
            ),
            footer: AppSheetFooter(
              children: [
                if (failure != null)
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      failure!,
                      style: const TextStyle(color: AppColors.accent),
                    ),
                  ),
                if (reason != null) Text(reason, style: AppText.caption),
                if (done)
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      context.t('manual.completed'),
                      style: AppText.caption,
                    ),
                  ),
                PressBounce(
                  child: FilledButton.icon(
                    key: const ValueKey('manual-action-check'),
                    onPressed:
                        busy ||
                            reason != null ||
                            currentTask == null ||
                            step == null
                        ? null
                        : () => toggle(currentTask, step),
                    icon: Icon(
                      done
                          ? CupertinoIcons.arrow_uturn_left
                          : CupertinoIcons.check_mark,
                    ),
                    label: Text(
                      saving
                          ? context.t('common.saving')
                          : done
                          ? context.t('manual.undoCompletion')
                          : context.t('manual.checkComplete'),
                    ),
                  ),
                ),
                if (currentTask != null &&
                    widget.onCompleteQuantity != null &&
                    currentTask['assignmentScopeVersion'] == 2 &&
                    currentTask['settings']?['completionPolicy']?['kind'] ==
                        'quantity' &&
                    currentTask['completedAt'] == null &&
                    (currentTask['steps'] as List? ?? [])
                        .whereType<Json>()
                        .every((s) => s['completedAt'] != null))
                  PressBounce(
                    child: FilledButton(
                      onPressed:
                          busy ||
                              widget.ops.readOnly ||
                              currentTask['canComplete'] != true
                          ? null
                          : () => widget.onCompleteQuantity!(currentTask),
                      child: Text(context.t('manual.enterQuantity')),
                    ),
                  ),
                Row(
                  children: [
                    Expanded(
                      child: PressBounce(
                        child: TextButton.icon(
                          key: const ValueKey('manual-action-previous'),
                          onPressed: saving || index == 0
                              ? null
                              : () => move(index - 1),
                          icon: const Icon(
                            CupertinoIcons.chevron_back,
                            size: 18,
                          ),
                          label: Text(context.t('common.previous')),
                        ),
                      ),
                    ),
                    Expanded(
                      child: PressBounce(
                        child: TextButton.icon(
                          key: const ValueKey('manual-action-next'),
                          onPressed: saving || index == ids.length - 1
                              ? null
                              : () => move(index + 1),
                          icon: const Icon(
                            CupertinoIcons.chevron_forward,
                            size: 18,
                          ),
                          label: Text(context.t('common.next')),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
