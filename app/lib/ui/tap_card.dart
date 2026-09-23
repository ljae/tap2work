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
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: const BorderSide(color: AppColors.line),
    ),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onOpen,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(emoji, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    level,
                    style: const TextStyle(
                      fontSize: 10,
                      letterSpacing: 1.1,
                      fontWeight: FontWeight.w700,
                      color: AppColors.muted,
                    ),
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 12,
                  color: AppColors.muted,
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 12,
                height: 1.6,
                color: AppColors.muted,
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
                      color: checked ? AppColors.green : AppColors.muted,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      checked
                          ? '완료'
                          : locked
                          ? '담당자 확인'
                          : '마쳤으면 탭',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.muted,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.menu_book_outlined,
                    size: 16,
                    color: AppColors.muted,
                  ),
                ],
              )
            else ...[
              ExcludeSemantics(
                child: LinearProgressIndicator(
                  value: total == 0 ? 0 : done / total,
                  minHeight: 3,
                  borderRadius: BorderRadius.circular(3),
                  color: AppColors.green,
                  backgroundColor: AppColors.paper,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                footer,
                style: const TextStyle(fontSize: 11, color: AppColors.muted),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}
