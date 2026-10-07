import 'dart:ui' as ui;
import 'design_tokens.dart';
export 'design_tokens.dart';
export 'design_system.dart';
import 'design_system.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Shared icon and label treatment for fixed screen toolbars.
class AppToolbarButton extends StatelessWidget {
  const AppToolbarButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.selected,
  });
  final bool? selected;
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  @override
  Widget build(BuildContext context) => Semantics(
    selected: selected,
    child: Tooltip(
      message: label,
      child: TextButton.icon(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          textStyle: AppText.caption,
          foregroundColor: selected == false
              ? AppColors.muted
              : AppColors.green,
          backgroundColor: selected == true
              ? AppColors.lime
              : Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        ),
        icon: Icon(icon, size: 18),
        label: Text(label, style: const TextStyle(fontSize: 13)),
      ),
    ),
  );
}

/// Separates navigation, display options and editing actions in one toolbar.
class AppToolbarDivider extends StatelessWidget {
  const AppToolbarDivider({super.key});
  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(horizontal: 8),
    child: SizedBox(
      height: 18,
      child: VerticalDivider(width: 1, color: AppColors.line),
    ),
  );
}

class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key, this.compact = false});
  final bool compact;

  @override
  Widget build(BuildContext context) => FittedBox(
    fit: BoxFit.scaleDown,
    alignment: Alignment.centerLeft,
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.asset(
            'assets/branding/tap2work.png',
            width: 48,
            height: 48,
            cacheWidth: (48 * MediaQuery.devicePixelRatioOf(context)).ceil(),
            fit: BoxFit.contain,
            semanticLabel: 'TAP Work 로고',
          ),
        ),
        if (!compact) ...[
          const SizedBox(width: 10),
          const Text(
            'TAP Work',
            maxLines: 1,
            style: TextStyle(
              color: AppColors.ink,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ],
    ),
  );
}

class BrandHeader extends StatelessWidget implements PreferredSizeWidget {
  const BrandHeader({super.key, required this.action, this.compact = false});
  final bool compact;
  final Widget action;

  @override
  Size get preferredSize => const Size.fromHeight(72);

  @override
  Widget build(BuildContext context) => AppBar(
    toolbarHeight: 72,
    backgroundColor: AppColors.paper,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    scrolledUnderElevation: 0,

    titleSpacing: 24,
    title: BrandLogo(compact: compact),
    actions: [
      Padding(padding: const EdgeInsets.only(right: 24), child: action),
    ],
  );
}

class HeaderAccountButton extends StatelessWidget {
  const HeaderAccountButton({super.key});

  @override
  Widget build(BuildContext context) => Container(
    width: 48,
    height: 48,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: AppColors.surface,
      border: Border.all(color: AppColors.line),
      borderRadius: BorderRadius.circular(14),
    ),
    child: const Icon(
      CupertinoIcons.person_crop_circle,
      size: 24,
      color: AppColors.ink,
    ),
  );
}

/// Displays a section of a supplied artwork sheet without altering the file.
class ArtworkCrop extends StatefulWidget {
  const ArtworkCrop({
    super.key,
    required this.asset,
    required this.crop,
    required this.width,
    required this.height,
    required this.semanticLabel,
    this.borderRadius = 0,
  });

  final String asset;
  final Rect crop;
  final double width;
  final double height;
  final String semanticLabel;
  final double borderRadius;

  @override
  State<ArtworkCrop> createState() => _ArtworkCropState();
}

class _ArtworkCropState extends State<ArtworkCrop> {
  ImageStream? _stream;
  late final ImageStreamListener _listener;
  ui.Image? _image;

  @override
  void initState() {
    super.initState();
    _listener = ImageStreamListener((info, _) {
      if (mounted) setState(() => _image = info.image);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resolve();
  }

  @override
  void didUpdateWidget(covariant ArtworkCrop oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.asset != widget.asset) _resolve();
  }

  void _resolve() {
    final next = AssetImage(
      widget.asset,
    ).resolve(createLocalImageConfiguration(context));
    if (_stream != null && _stream!.key == next.key) return;
    _stream?.removeListener(_listener);
    _stream = next;
    _image = null;
    next.addListener(_listener);
  }

  @override
  void dispose() {
    _stream?.removeListener(_listener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: widget.semanticLabel,
      image: true,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        child: SizedBox(
          width: widget.width,
          height: widget.height,
          child: CustomPaint(
            painter: _image == null
                ? null
                : _ArtworkPainter(_image!, widget.crop),
          ),
        ),
      ),
    );
  }
}

class _ArtworkPainter extends CustomPainter {
  const _ArtworkPainter(this.image, this.crop);

  final ui.Image image;
  final Rect crop;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawImageRect(
      image,
      crop,
      Offset.zero & size,
      Paint()..filterQuality = FilterQuality.high,
    );
  }

  @override
  bool shouldRepaint(covariant _ArtworkPainter oldDelegate) =>
      oldDelegate.image != image || oldDelegate.crop != crop;
}

class FloatingMenuItem {
  const FloatingMenuItem(this.label, this.icon);
  final String label;
  final IconData icon;
}

class FloatingMenu extends StatelessWidget {
  const FloatingMenu({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
    required this.items,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final List<FloatingMenuItem> items;

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Center(
        widthFactor: 1,
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border.all(color: AppColors.line),
              borderRadius: BorderRadius.circular(22),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1C193B3A),
                  blurRadius: 24,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(5),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = 0; i < items.length; i++)
                      Expanded(
                        child: Semantics(
                          selected: i == selectedIndex,
                          button: true,
                          child: PressBounce(
                            child: InkWell(
                              key: ValueKey('floating-menu-$i'),
                              onTap: () => onSelected(i),
                              borderRadius: BorderRadius.circular(17),
                              child: AnimatedContainer(
                                duration: AppMotion.duration(
                                  context,
                                  AppMotion.quick,
                                ),
                                curve: AppMotion.enterCurve,
                                constraints: const BoxConstraints(
                                  minHeight: 60,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: i == selectedIndex
                                      ? AppColors.lime
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(17),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      items[i].icon,
                                      size: 21,
                                      color: i == selectedIndex
                                          ? AppColors.ink
                                          : AppColors.muted,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      items[i].label,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: i == selectedIndex
                                            ? AppColors.ink
                                            : AppColors.muted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class Surface extends StatelessWidget {
  const Surface({
    super.key,
    required this.child,
    this.color = AppColors.surface,
    this.padding = const EdgeInsets.all(24),
  });
  final Widget child;
  final Color color;
  final EdgeInsets padding;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: padding,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(20),
      boxShadow: appCardShadow,
    ),
    child: child,
  );
}

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.margin = const EdgeInsets.only(bottom: 16),
  });
  final Widget child;
  final EdgeInsetsGeometry margin;
  @override
  Widget build(BuildContext context) => Container(
    margin: margin,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(20),
      boxShadow: appCardShadow,
    ),
    child: Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: child,
    ),
  );
}

class Eyebrow extends StatelessWidget {
  const Eyebrow(this.text, {super.key, this.color = AppColors.muted});
  final String text;
  final Color color;
  @override
  Widget build(BuildContext context) => Text(
    text,
    style: TextStyle(
      color: color,
      fontSize: 13,
      fontWeight: FontWeight.w600,
      letterSpacing: .8,
    ),
  );
}

class PageHeading extends StatelessWidget {
  const PageHeading(this.kicker, this.title, this.subtitle, {super.key});
  final String kicker;
  final String title;
  final String subtitle;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Semantics(
      header: true,
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 24,
          height: 1.3,
          fontWeight: FontWeight.w700,
          color: AppColors.ink,
        ),
      ),
    ),
  );
}

class SectionHeading extends StatelessWidget {
  const SectionHeading(this.title, this.subtitle, {super.key});
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(header: true, child: Text(title, style: AppText.section)),
        const SizedBox(height: 5),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 13,
            height: 1.55,
            color: AppColors.muted,
          ),
        ),
      ],
    ),
  );
}

class AppStatusPill extends StatelessWidget {
  const AppStatusPill({
    super.key,
    required this.label,
    required this.icon,
    this.attention = false,
  });

  final String label;
  final IconData icon;
  final bool attention;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
    decoration: BoxDecoration(
      color: attention ? AppColors.accentSoft : AppColors.lime,
      borderRadius: BorderRadius.circular(10),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ExcludeSemantics(
          child: Icon(
            icon,
            size: 16,
            color: attention ? AppColors.accent : AppColors.green,
          ),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: attention ? AppColors.accent : AppColors.green,
            ),
          ),
        ),
      ],
    ),
  );
}

class AppPicker<T> extends StatelessWidget {
  const AppPicker({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });
  final String label;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;

  @override
  Widget build(BuildContext context) => AppPillField<T>(
    initialValue: value,
    decoration: InputDecoration(labelText: label),
    items: items,
    onChanged: onChanged,
  );
}

/// Chip defaults force one line; form choices must retain their full meaning.
class _WrappingChoiceLabel extends StatelessWidget {
  const _WrappingChoiceLabel(
    this.child,
    this.availableWidth, {
    this.hasAvatar = false,
  });
  final Widget child;
  final double availableWidth;
  final bool hasAvatar;
  @override
  Widget build(BuildContext context) {
    final theme = ChipTheme.of(context);
    // Reserve chip chrome before its dry layout measures the label height.
    final chrome =
        (theme.padding ?? const EdgeInsets.all(4)).horizontal +
        (theme.labelPadding ?? const EdgeInsets.symmetric(horizontal: 8))
            .horizontal +
        (hasAvatar || theme.showCheckmark != false ? 48 : 0);
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: (availableWidth - chrome).clamp(1, double.infinity),
      ),
      child: DefaultTextStyle(
        style: DefaultTextStyle.of(context).style,
        softWrap: true,
        child: child,
      ),
    );
  }
}

/// One selection language across filters, forms, and workspace tabs.
class AppPillField<T> extends StatelessWidget {
  const AppPillField({
    super.key,
    this.initialValue,
    this.decoration = const InputDecoration(),
    required this.items,
    this.onChanged,
    this.isExpanded = true,
    this.validator,
  });
  final T? initialValue;
  final InputDecoration decoration;
  final List<DropdownMenuItem<T>>? items;
  final ValueChanged<T?>? onChanged;
  final bool isExpanded;
  final String? Function(T?)? validator;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (decoration.labelText != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              decoration.labelText!,
              style: AppText.body.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 216),
          child: SingleChildScrollView(
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final item in items ?? <DropdownMenuItem<T>>[])
                  ChoiceChip(
                    chipAnimationStyle: AppMotion.chipStyle(context),
                    label: _WrappingChoiceLabel(item.child, box.maxWidth),
                    selected: item.value == initialValue,
                    onSelected: onChanged == null || !item.enabled
                        ? null
                        : (_) => onChanged!(item.value),
                  ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

class AppSegmented<T> extends StatelessWidget {
  const AppSegmented({
    super.key,
    required this.segments,
    required this.selected,
    this.onSelectionChanged,
    this.showSelectedIcon = false,
    this.style,
  });
  final List<ButtonSegment<T>> segments;
  final Set<T> selected;
  final ValueChanged<Set<T>>? onSelectionChanged;
  final bool showSelectedIcon;
  final ButtonStyle? style;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) => Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final segment in segments)
          ChoiceChip(
            chipAnimationStyle: AppMotion.chipStyle(context),
            label: _WrappingChoiceLabel(
              segment.label ?? const SizedBox(),
              box.maxWidth,
              hasAvatar: segment.icon != null,
            ),
            avatar: segment.icon,
            selected: selected.contains(segment.value),
            onSelected: onSelectionChanged == null || !segment.enabled
                ? null
                : (_) => onSelectionChanged!({segment.value}),
          ),
      ],
    ),
  );
}

class AppChoiceGroup<T> extends StatelessWidget {
  const AppChoiceGroup({
    super.key,
    required this.values,
    required this.selected,
    required this.labelOf,
    required this.onSelected,
  });
  final List<T> values;
  final T selected;
  final String Function(T) labelOf;
  final ValueChanged<T> onSelected;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) => Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final value in values)
          ChoiceChip(
            chipAnimationStyle: AppMotion.chipStyle(context),
            label: _WrappingChoiceLabel(Text(labelOf(value)), box.maxWidth),
            selected: selected == value,
            onSelected: (_) => onSelected(value),
          ),
      ],
    ),
  );
}

class Information extends StatelessWidget {
  const Information(this.text, {super.key});
  final String text;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ExcludeSemantics(
          child: Icon(
            CupertinoIcons.info_circle,
            size: 19,
            color: AppColors.muted,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              height: 1.55,
              color: AppColors.ink,
            ),
          ),
        ),
      ],
    ),
  );
}

class Person extends StatelessWidget {
  const Person({
    super.key,
    required this.name,
    required this.subtitle,
    this.trailing,
  });
  final String name;
  final String subtitle;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      CircleAvatar(
        backgroundColor: AppColors.peach,
        foregroundColor: AppColors.green,
        child: Text(name.characters.first),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 13, color: AppColors.muted),
            ),
          ],
        ),
      ),
      ?trailing,
    ],
  );
}
