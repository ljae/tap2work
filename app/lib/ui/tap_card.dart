import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'components.dart';

/// One card language for a collection, a task and an individual action.
class TapCard extends StatelessWidget {
  const TapCard({
    super.key,
    required this.level,
    required this.title,
    required this.subtitle,
    required this.onOpen,
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
  });

  final String level, title, subtitle, emoji, footer;
  final int done, total;
  final VoidCallback onOpen;
  final VoidCallback? onCheck;
  final bool checked, locked;
  final bool selected;
  final int? sequence;
  final Widget? dragHandle;
  final Color? accentColor;
  final Widget? assigneeBadges;

  @override
  Widget build(BuildContext context) {
    final progress = total == 0 ? 0.0 : (done / total).clamp(0.0, 1.0);
    final complete = checked || (total > 0 && done == total);
    final tint = accentColor ?? AppColors.accent;
    return Material(
      color: complete ? const Color(0xFFF0F2F4) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: selected ? tint : AppColors.line,
          width: selected ? 2 : 1,
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
                Row(
                  children: [
                    if (dragHandle != null) ...[
                      dragHandle!,
                      const SizedBox(width: 2),
                    ],
                    if (onCheck != null) ...[
                      IconButton(
                        tooltip: checked ? '완료 되돌리기' : '완료하기',
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
                      child: InkWell(
                        onTap: onOpen,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.ink,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Semantics(
                      label: level.toLowerCase().contains('small')
                          ? '방법 열기'
                          : 'Small TAP 열기',
                      button: true,
                      child: InkWell(
                        onTap: onOpen,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 2,
                            vertical: 12,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                level.toLowerCase().contains('small')
                                    ? '방법'
                                    : 'Small TAP',
                                style: TextStyle(
                                  fontSize: 10,
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
                Padding(
                  padding: const EdgeInsets.only(left: 4, top: 2),
                  child: Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      height: 1.4,
                      color: AppColors.muted,
                    ),
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
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: complete ? AppColors.muted : tint,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: LinearProgressIndicator(
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
                      fontSize: 12,
                      color: AppColors.muted,
                    ),
                  ),
                ],
                if (footer.isNotEmpty &&
                    level.toLowerCase().contains('small')) ...[
                  const SizedBox(height: 8),
                  Text(
                    footer,
                    style: TextStyle(
                      fontSize: 12,
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
    );
  }
}
