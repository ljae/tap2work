import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'components.dart';

/// A quiet waterline follows focus beside a small, friendly water cup.
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
        hintText: '매뉴얼 검색',
        hintStyle: AppText.body.copyWith(color: AppColors.muted),
        prefixIcon: Padding(
          padding: const EdgeInsets.all(10),
          child: ExcludeSemantics(
            child: SizedBox(
              width: 32,
              height: 32,
              child: CustomPaint(painter: _WaterCup()),
            ),
          ),
        ),
        suffixIcon: widget.controller.text.isEmpty
            ? const Icon(Icons.search_rounded, size: 22, color: AppColors.muted)
            : IconButton(
                tooltip: '검색 지우기',
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

/// Decorative vector artwork: no logo tile or light background.
class _WaterCup extends CustomPainter {
  const _WaterCup();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 32, size.height / 32);
    final cup = Path()
      ..moveTo(6, 5)
      ..lineTo(26, 5)
      ..lineTo(23.8, 25)
      ..quadraticBezierTo(23.4, 29, 19.5, 29)
      ..lineTo(12.5, 29)
      ..quadraticBezierTo(8.6, 29, 8.2, 25)
      ..close();
    canvas.save();
    canvas.clipPath(cup);
    canvas.drawPath(
      cup,
      Paint()..color = AppColors.green.withValues(alpha: .06),
    );
    final water = Path()
      ..moveTo(5, 14)
      ..cubicTo(11, 10, 18, 17, 27, 12)
      ..lineTo(27, 31)
      ..lineTo(5, 31)
      ..close();
    canvas.drawPath(
      water,
      Paint()..color = AppColors.green.withValues(alpha: .26),
    );
    canvas.restore();
    canvas.drawPath(
      cup,
      Paint()
        ..color = const Color(0xFFB6E5D6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..strokeJoin = StrokeJoin.round,
    );
    final face = Paint()
      ..color = const Color(0xFFB6E5D6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(12.5, 19), const Offset(12.5, 20), face);
    canvas.drawLine(const Offset(19.5, 19), const Offset(19.5, 20), face);
    canvas.drawPath(
      Path()
        ..moveTo(14, 23)
        ..quadraticBezierTo(16, 25, 18, 23),
      face,
    );
    final cheek = Paint()..color = AppColors.accent.withValues(alpha: .65);
    canvas.drawOval(const Rect.fromLTWH(9.5, 21, 3, 1.6), cheek);
    canvas.drawOval(const Rect.fromLTWH(19.5, 21, 3, 1.6), cheek);
    canvas.drawLine(
      const Offset(9.5, 8),
      const Offset(10, 12),
      face..color = AppColors.white.withValues(alpha: .4),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_WaterCup oldDelegate) => false;
}
