import 'package:flutter/material.dart';
import '../domain/crew_allocation.dart';
import 'components.dart';

class CrewHoursBadge extends StatelessWidget {
  const CrewHoursBadge({super.key, required this.name, required this.hours});
  final String name;
  final CrewHoursSummary hours;
  @override
  Widget build(BuildContext context) => Tooltip(
    message: hours.hint ?? '선택 주 기본 배정 시간 · 휴게 미반영',
    child: Container(
      constraints: const BoxConstraints(minWidth: 88),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: hours.restReference || hours.overtimeReference
              ? AppColors.amber
              : AppColors.line,
        ),
      ),
      child: Column(
        children: [
          Text(name, style: AppText.body),
          Text(hours.label, style: AppText.caption),
        ],
      ),
    ),
  );
}

class AllocationPartCard extends StatelessWidget {
  const AllocationPartCard({
    super.key,
    required this.title,
    required this.index,
    required this.children,
    this.ghost = false,
  });
  final String title;
  final int index;
  final List<Widget> children;
  final bool ghost;
  @override
  Widget build(BuildContext context) => AnimatedOpacity(
    opacity: ghost ? .55 : 1,
    duration: AppMotion.duration(context, AppMotion.content),
    child: Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: [
          AppColors.green,
          AppColors.amber,
          AppColors.accent,
        ][index % 3].withValues(alpha: .07),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: AppText.body),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    ),
  );
}

class AllocationEmptySlot extends StatelessWidget {
  const AllocationEmptySlot({super.key, required this.label, this.onTap});
  final String label;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Semantics(
    label: label,
    button: true,
    enabled: onTap != null,
    child: CustomPaint(
      painter: _DashedBorder(),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: const SizedBox(
          height: 48,
          width: double.infinity,
          child: Icon(Icons.add, color: AppColors.muted),
        ),
      ),
    ),
  );
}

class _DashedBorder extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(12)),
      );
    final paint = Paint()
      ..color = AppColors.line
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (final metric in path.computeMetrics()) {
      for (double i = 0; i < metric.length; i += 9) {
        canvas.drawPath(
          metric.extractPath(i, (i + 5).clamp(0, metric.length)),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
