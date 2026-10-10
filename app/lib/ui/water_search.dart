import '../l10n/app_localizations.dart';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'components.dart';

/// A quiet waterline follows focus beside a simple green search icon.
class WaterSearch extends StatefulWidget {
  const WaterSearch({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  @override
  State<WaterSearch> createState() => _WaterSearchState();
}

class _WaterSearchState extends State<WaterSearch> {
  final focus = FocusNode();
  @override
  void initState() {
    super.initState();
    focus.addListener(changed);
  }

  void changed() => setState(() {});
  @override
  void dispose() {
    focus.removeListener(changed);
    focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(end: focus.hasFocus ? 1 : 0),
    duration: AppMotion.duration(context, AppMotion.sheet),
    curve: AppMotion.enterCurve,
    builder: (context, value, child) => ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: CustomPaint(
        foregroundPainter: _Waterline(value),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Color.lerp(AppColors.surface, AppColors.lime, value * .45),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Color.lerp(AppColors.line, AppColors.green, value)!,
            ),
          ),
          child: child,
        ),
      ),
    ),
    child: TextField(
      key: const ValueKey('global-manual-search'),
      controller: widget.controller,
      focusNode: focus,
      onChanged: widget.onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: context.t('manual.search'),
        hintStyle: AppText.body.copyWith(color: AppColors.muted),
        prefixIcon: const Icon(
          CupertinoIcons.search,
          key: ValueKey('manual-search-icon'),
          size: 22,
          color: AppColors.green,
        ),
        suffixIcon: widget.controller.text.isEmpty
            ? null
            : IconButton(
                tooltip: context.t('manual.clearSearch'),
                onPressed: widget.onClear,
                icon: const Icon(Icons.close, size: 20),
              ),
        filled: false,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
      ),
    ),
  );
}

class _Waterline extends CustomPainter {
  const _Waterline(this.focus);
  final double focus;
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()..moveTo(0, size.height - 3);
    for (double x = 0; x <= size.width; x += 2) {
      path.lineTo(
        x,
        size.height -
            3 -
            math.sin(x / size.width * math.pi * 4 + focus * math.pi) *
                (1 + focus * 1.5),
      );
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = AppColors.green.withValues(alpha: .16 + focus * .25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(_Waterline oldDelegate) => focus != oldDelegate.focus;
}
