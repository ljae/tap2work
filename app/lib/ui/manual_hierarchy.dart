import 'package:flutter/material.dart';
import '../domain/manual_categories.dart';
import '../l10n/app_localizations.dart';
import 'components.dart';

class ManualCategoryPicker extends StatelessWidget {
  const ManualCategoryPicker({
    super.key,
    required this.selected,
    required this.onSelected,
    this.counts = const {},
  });
  final String? selected;
  final ValueChanged<String?> onSelected;
  final Map<String, int> counts;
  static const icons = {
    'startup': Icons.tune_outlined,
    'periodic': Icons.event_repeat_outlined,
    'routine': Icons.checklist_outlined,
    'recipe': Icons.restaurant_menu_outlined,
    'reference': Icons.menu_book_outlined,
  };
  @override
  Widget build(BuildContext context) {
    if (MediaQuery.sizeOf(context).height < 600) {
      return SizedBox(
        height: 48,
        child: Semantics(
          label: context.t('manual.category.label'),
          child: DropdownButton<String>(
            key: const ValueKey('manual-category-select'),
            isExpanded: true,
            value: selected ?? '',
            underline: const SizedBox(),
            items: [
              for (final c in <String?>[null, ...manualCategoryIds])
                DropdownMenuItem(
                  value: c ?? '',
                  child: Text(
                    context.t('manual.category.${c ?? 'all'}'),
                    style: AppText.body,
                  ),
                ),
            ],
            onChanged: (value) => onSelected(value == '' ? null : value),
          ),
        ),
      );
    }
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: MediaQuery.sizeOf(context).width < 600 ? 0 : 16,
        vertical: 8,
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final category in <String?>[null, ...manualCategoryIds])
            ChoiceChip(
              key: ValueKey('manual-category-${category ?? 'all'}'),
              chipAnimationStyle: AppMotion.chipStyle(context),
              avatar: MediaQuery.sizeOf(context).width < 600
                  ? null
                  : Icon(
                      category == null
                          ? Icons.grid_view_outlined
                          : icons[category],
                      size: 18,
                    ),
              selected: selected == category,
              label: Text(
                context.t('manual.category.${category ?? 'all'}'),
                style: AppText.caption,
              ),
              onSelected: (_) => onSelected(category),
            ),
        ],
      ),
    );
  }
}

/// One path follows the same folder, TAP and action IDs across reading/execution.
class ManualHierarchyPath extends StatelessWidget {
  const ManualHierarchyPath({
    super.key,
    this.folder,
    this.tap,
    this.task,
    this.onFolder,
    this.onTap,
    this.onTask,
    this.compact = false,
    this.reference = false,
  });
  final String? folder, tap, task;
  final VoidCallback? onFolder, onTap, onTask;
  final bool compact, reference;
  @override
  Widget build(BuildContext context) {
    final active = task != null
        ? 3
        : tap != null
        ? 2
        : folder != null
        ? 1
        : 0;
    final kinds = ['folder', 'tap', reference ? 'section' : 'task', 'method'];
    final icons = [
      Icons.folder_outlined,
      Icons.layers_outlined,
      reference ? Icons.article_outlined : Icons.checklist_outlined,
      Icons.menu_book_outlined,
    ];
    final callbacks = [onFolder, onTap, onTask, null];
    final caption = reference
        ? context.t('manual.structure.readHint')
        : active == 0
        ? context.t('manual.structure.folderHint')
        : active == 1
        ? context.t('manual.structure.tapHint')
        : active == 2
        ? context.t('manual.structure.taskHint')
        : context.t('manual.structure.methodHint');
    return Surface(
      padding: EdgeInsets.all(compact ? 12 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              for (var i = 0; i < 4; i++) ...[
                if (i > 0)
                  const Icon(
                    Icons.chevron_right,
                    size: 14,
                    color: AppColors.muted,
                  ),
                Expanded(
                  child: Semantics(
                    selected: i == active,
                    child: AnimatedContainer(
                      duration: AppMotion.duration(context, AppMotion.content),
                      curve: AppMotion.enterCurve,
                      decoration: BoxDecoration(
                        color: i == active
                            ? AppColors.green.withValues(alpha: .12)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextButton(
                        onPressed: callbacks[i],
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 2,
                            vertical: 10,
                          ),
                          minimumSize: const Size(48, 56),
                          foregroundColor: i == active
                              ? AppColors.green
                              : AppColors.muted,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(icons[i], size: 20),
                            const SizedBox(height: 6),
                            Text(
                              context.t('manual.structure.${kinds[i]}'),
                              maxLines: 2,
                              textAlign: TextAlign.center,
                              style: AppText.caption.copyWith(
                                color: i == active
                                    ? AppColors.green
                                    : AppColors.muted,
                                fontWeight: i == active
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (!compact) ...[
            const SizedBox(height: 8),
            AnimatedSwitcher(
              duration: AppMotion.duration(context, AppMotion.content),
              reverseDuration: AppMotion.duration(context, AppMotion.quick),
              layoutBuilder: (current, previous) => Stack(
                alignment: Alignment.centerLeft,
                children: [
                  ...previous.map((child) => ExcludeSemantics(child: child)),
                  ?current,
                ],
              ),
              child: Text(
                task ?? tap ?? folder ?? context.t('manual.structure.title'),
                key: ValueKey('$folder/$tap/$task'),
                style: AppText.body.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 4),
            Text(caption, style: AppText.caption),
          ],
        ],
      ),
    );
  }
}

/// A folder opens spatially without changing the saved directory or action IDs.
class ManualFoldGroup extends StatelessWidget {
  const ManualFoldGroup({
    super.key,
    required this.header,
    required this.children,
  });
  final Widget header;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) {
    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        header,
        if (AppMotion.reduced(context))
          body
        else
          AnimatedSize(
            duration: AppMotion.content,
            reverseDuration: AppMotion.quick,
            curve: AppMotion.enterCurve,
            alignment: Alignment.topCenter,
            child: body,
          ),
      ],
    );
  }
}
