import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'design_tokens.dart';

/// Decorative activity loop, never a measured loading percentage.
class TapWaterLoading extends StatefulWidget {
  const TapWaterLoading({super.key, this.animate = true});
  final bool animate;
  @override
  State<TapWaterLoading> createState() => _TapWaterLoadingState();
}

class _TapWaterLoadingState extends State<TapWaterLoading>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3200),
  );
  void sync() {
    if (widget.animate &&
        !MediaQuery.disableAnimationsOf(context) &&
        TickerMode.valuesOf(context).enabled) {
      if (!controller.isAnimating) controller.repeat();
    } else {
      controller.stop();
      controller.value = .55;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    sync();
  }

  @override
  void didUpdateWidget(TapWaterLoading oldWidget) {
    super.didUpdateWidget(oldWidget);
    sync();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: RepaintBoundary(
      child: SizedBox(
        width: 160,
        height: 180,
        child: CustomPaint(painter: TapWaterPainter(controller)),
      ),
    ),
  );
}

class TapWaterPainter extends CustomPainter {
  TapWaterPainter(this.phase) : super(repaint: phase);
  final Animation<double> phase;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 160, size.height / 180);
    final t = phase.value;
    final opacity = t < .84 ? 1.0 : ((1 - t) / .16).clamp(0.0, 1.0);
    final level =
        151 - 59 * Curves.easeInOut.transform((t / .84).clamp(0.0, 1.0));
    final outline = Paint()
      ..color = AppColors.muted
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final tap = Path()
      ..moveTo(131, 23)
      ..lineTo(99, 23)
      ..quadraticBezierTo(77, 23, 77, 48)
      ..lineTo(91, 48)
      ..quadraticBezierTo(91, 37, 103, 37)
      ..lineTo(131, 37);
    canvas.drawPath(tap, outline);
    canvas.drawLine(
      const Offset(40, 166),
      const Offset(120, 166),
      Paint()
        ..color = AppColors.line
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
    final cup = Path()
      ..moveTo(43, 82)
      ..lineTo(117, 82)
      ..lineTo(108, 145)
      ..quadraticBezierTo(106, 159, 94, 159)
      ..lineTo(66, 159)
      ..quadraticBezierTo(54, 159, 52, 145)
      ..close();
    canvas.save();
    canvas.clipPath(cup);
    canvas.drawPath(
      cup,
      Paint()..color = AppColors.green.withValues(alpha: .06),
    );
    final wave = Path()..moveTo(40, level);
    for (double x = 40; x <= 120; x += 2) {
      wave.lineTo(x, level + 2.2 * math.sin(x / 12 + t * math.pi * 4));
    }
    wave
      ..lineTo(120, 162)
      ..lineTo(40, 162)
      ..close();
    canvas.drawPath(
      wave,
      Paint()..color = AppColors.green.withValues(alpha: .8 * opacity),
    );
    canvas.drawCircle(
      Offset(93, level + 18),
      3,
      Paint()..color = Colors.white.withValues(alpha: .55 * opacity),
    );
    canvas.drawCircle(
      Offset(84, level + 29),
      2,
      Paint()..color = Colors.white.withValues(alpha: .4 * opacity),
    );
    canvas.restore();
    canvas.drawPath(cup, outline);
    canvas.drawLine(
      const Offset(57, 101),
      const Offset(61, 131),
      Paint()
        ..color = AppColors.muted.withValues(alpha: .5)
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
    for (var i = 0; i < 2; i++) {
      final fall = (t * 4 + i * .5) % 1;
      final y = 53 + fall * 29;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(84, y), width: 4, height: 7),
          const Radius.circular(3),
        ),
        Paint()
          ..color = AppColors.green.withValues(
            alpha: opacity * math.sin(fall * math.pi),
          ),
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(TapWaterPainter oldDelegate) => oldDelegate.phase != phase;
}
