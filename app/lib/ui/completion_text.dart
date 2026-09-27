import 'package:flutter/material.dart';

/// Plays only when a successful local completion supplies a new trigger.
class CompletionText extends StatefulWidget {
  const CompletionText({super.key, required this.text, required this.style, this.trigger, this.maxLines = 1});
  final String text;
  final TextStyle style;
  final Object? trigger;
  final int maxLines;
  @override
  State<CompletionText> createState() => _CompletionTextState();
}

class _CompletionTextState extends State<CompletionText> with SingleTickerProviderStateMixin {
  late final AnimationController controller = AnimationController(
    vsync: this, duration: const Duration(milliseconds: 300), value: 1,
  );
  @override
  void didUpdateWidget(covariant CompletionText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.trigger != null && widget.trigger != oldWidget.trigger) {
      if (MediaQuery.disableAnimationsOf(context)) {
        controller.value = 1;
      } else {
        controller.forward(from: 0);
      }
    }
  }

  @override
  void dispose() { controller.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) {
      return Text(widget.text, maxLines: widget.maxLines,
        overflow: TextOverflow.ellipsis, style: widget.style);
    }
    return Semantics(label: widget.text, child: ExcludeSemantics(child: AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final value = controller.value;
        final falling = value < .6;
        final opacity = falling ? 1 - value / .6 : (value - .6) / .4;
        return Transform.translate(offset: Offset(0, falling ? 14 * value / .6 : 0),
          child: Opacity(opacity: opacity.clamp(0, 1), child: Text(widget.text,
            maxLines: widget.maxLines, overflow: TextOverflow.ellipsis, style: widget.style)));
      },
    )));
  }
}
