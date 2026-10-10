import '../l10n/app_localizations.dart';
import 'manual_setup_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'components.dart';
import 'completion_text.dart';

/// One card language for a collection, a task and an individual action.
class TapCard extends StatelessWidget {
  const TapCard({
    super.key,
    required this.level,
    required this.title,
    required this.subtitle,
    required this.onOpen,
    this.onEdit,
    this.emoji = '📁',
    this.done = 0,
    this.total = 0,
    this.footer = '',
    this.onCheck,
    this.checked = false,
    this.locked = false,
    this.selected = false,
    this.sequence,
    this.dragHandle,
    this.accentColor,
    this.assigneeBadges,
    this.completionTrigger,
    this.holdCompletion = false,
    this.customization,
  });

  final String level, title, subtitle, emoji, footer;
  final int done, total;
  final VoidCallback onOpen;
  final VoidCallback? onCheck, onEdit;
  final bool checked, locked;
  final bool selected;
  final int? sequence;
  final Widget? dragHandle;
  final Color? accentColor;
  final Widget? assigneeBadges;
  final Object? completionTrigger;
  final bool holdCompletion;
  final dynamic customization;

  @override
  Widget build(BuildContext context) {
    final progress = total == 0 ? 0.0 : (done / total).clamp(0.0, 1.0);
    final complete = checked || (total > 0 && done == total);
    final tint = accentColor ?? AppColors.accent;
    final largeText = MediaQuery.textScalerOf(context).scale(16) > 20;
    final openLabel = level.toLowerCase() == 'task'
        ? context.t('work.openManual')
        : context.t('work.openTask');
    // Keep the title beside its check action; secondary movement goes below
    // when a narrow card or enlarged type would squeeze the title.
    return LayoutBuilder(
      builder: (context, constraints) {
        final separateDrag =
            dragHandle != null &&
            subtitle.isNotEmpty &&
            (constraints.maxWidth < 360 || largeText);
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: appCardShadow,
          ),
          child: Material(
            color: complete ? const Color(0xFF222528) : AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: selected ? tint : Colors.transparent,
                width: selected ? 2 : 0,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                if (!complete && progress > 0)
                  Positioned.fill(
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: progress,
                      child: ColoredBox(color: tint.withValues(alpha: .18)),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ManualCustomizationBadge(value: customization),
                      Row(
                        children: [
                          if (dragHandle != null && !separateDrag) ...[
                            dragHandle!,
                            const SizedBox(width: 2),
                          ],
                          if (onCheck != null) ...[
                            IconButton(
                              tooltip: checked
                                  ? context.t('manual.undoCompletion')
                                  : context.t('work.completeAction'),
                              constraints: const BoxConstraints(
                                minWidth: 48,
                                minHeight: 48,
                              ),
                              onPressed: onCheck,
                              icon: Icon(
                                checked
                                    ? Icons.check_circle
                                    : locked
                                    ? Icons.lock_outline
                                    : Icons.radio_button_unchecked,
                              ),
                              color: checked ? AppColors.muted : tint,
                            ),
                          ],
                          Expanded(
                            child: Tooltip(
                              excludeFromSemantics: true,
                              triggerMode: TooltipTriggerMode.manual,
                              message: title,
                              child: InkWell(
                                onTap: onEdit ?? onOpen,
                                mouseCursor: onEdit == null
                                    ? SystemMouseCursors.click
                                    : SystemMouseCursors.text,
                                child: Container(
                                  constraints: const BoxConstraints(
                                    minHeight: 48,
                                  ),
                                  alignment: Alignment.centerLeft,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  child: CompletionText(
                                    text: title,
                                    trigger: completionTrigger,
                                    holdAfterFall: holdCompletion,
                                    maxLines: 3,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.ink,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Semantics(
                            label: openLabel,
                            button: true,
                            child: InkWell(
                              onTap: onOpen,
                              child: Container(
                                constraints: const BoxConstraints(
                                  minWidth: 48,
                                  minHeight: 48,
                                ),
                                alignment: Alignment.center,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 2,
                                  vertical: 12,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (!largeText)
                                      Text(
                                        level.toLowerCase() == 'task'
                                            ? context.t('nav.manual')
                                            : context.t('work.content'),
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: tint,
                                        ),
                                      ),
                                    Icon(
                                      CupertinoIcons.chevron_right,
                                      size: 15,
                                      color: tint,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (subtitle.isNotEmpty || separateDrag)
                        Padding(
                          padding: const EdgeInsets.only(left: 4, top: 2),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  subtitle,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    height: 1.4,
                                    color: AppColors.muted,
                                  ),
                                ),
                              ),
                              if (separateDrag) dragHandle!,
                            ],
                          ),
                        ),
                      if (assigneeBadges != null) ...[
                        const SizedBox(height: 5),
                        assigneeBadges!,
                      ],
                      if (total > 0) ...[
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Text(
                              '$done/$total',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: complete ? AppColors.muted : tint,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: AppLinearProgress(
                                value: progress,
                                minHeight: 5,
                                semanticsLabel: '$done/$total 활동 완료',
                                color: complete ? AppColors.muted : tint,
                                backgroundColor: complete
                                    ? Colors.white
                                    : AppColors.paper,
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (checked || locked) ...[
                        const SizedBox(height: 6),
                        Text(
                          checked ? '완료' : '담당자 확인',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                      if (footer.isNotEmpty &&
                          level.toLowerCase() == 'task') ...[
                        const SizedBox(height: 8),
                        Text(
                          footer,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: tint,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
