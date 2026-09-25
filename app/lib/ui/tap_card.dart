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
  });

  final String level, title, subtitle, emoji, footer;
  final int done, total;
  final VoidCallback onOpen;
  final VoidCallback? onCheck;
  final bool checked, locked;

  @override
  Widget build(BuildContext context) {
    final progress = total == 0 ? 0.0 : (done / total).clamp(0.0, 1.0);
    final complete = checked || (total > 0 && done == total);
    const foreground = AppColors.ink;
    const secondary = AppColors.muted;
    return Material(
      color: complete ? const Color(0xFFF0F2F4) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: AppColors.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          if (!complete && progress > 0)
            Positioned.fill(
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: progress,
                child: const ColoredBox(color: Color(0x66E98B76)),
              ),
            ),
          InkWell(
            onTap: onOpen,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (total > 0) ...[
                    Row(
                      children: [
                        Text(
                          '$done/$total',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: complete
                                ? AppColors.muted
                                : done > 0
                                ? AppColors.accent
                                : AppColors.muted,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: LinearProgressIndicator(
                            value: done / total,
                            minHeight: 5,
                            semanticsLabel: '$done/$total 활동 완료',
                            color: complete
                                ? AppColors.muted
                                : AppColors.accent,
                            backgroundColor: complete
                                ? Colors.white
                                : AppColors.paper,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                  Row(
                    children: [
                      Icon(
                        level.toLowerCase().contains('small')
                            ? CupertinoIcons.checkmark_circle
                            : level.toLowerCase().contains('tap')
                            ? CupertinoIcons.list_bullet
                            : CupertinoIcons.folder,
                        size: 20,
                        color: secondary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          level,
                          style: TextStyle(
                            fontSize: 12,
                            letterSpacing: .4,
                            fontWeight: FontWeight.w700,
                            color: secondary,
                          ),
                        ),
                      ),
                      Icon(
                        CupertinoIcons.chevron_right,
                        size: 17,
                        color: secondary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      height: 1.45,
                      color: foreground,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.55,
                      color: secondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (onCheck != null)
                    Row(
                      children: [
                        Semantics(
                          label: '$title ${checked ? '확인 되돌리기' : '확인'}',
                          button: true,
                          child: IconButton(
                            tooltip: checked ? '완료 되돌리기' : '완료하기',
                            onPressed: onCheck,
                            icon: Icon(
                              checked
                                  ? Icons.check_circle
                                  : locked
                                  ? Icons.lock_outline
                                  : Icons.radio_button_unchecked,
                            ),
                            color: AppColors.muted,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            checked
                                ? '완료'
                                : locked
                                ? '담당자 확인'
                                : '마쳤으면 탭',
                            style: TextStyle(fontSize: 13, color: secondary),
                          ),
                        ),
                        Icon(
                          Icons.menu_book_outlined,
                          size: 16,
                          color: secondary,
                        ),
                      ],
                    )
                  else ...[
                    Text(
                      footer,
                      style: TextStyle(fontSize: 12, color: secondary),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
