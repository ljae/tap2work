import 'package:flutter/material.dart';

/// Plays only when a successful local completion supplies a new trigger.
class CompletionText extends StatefulWidget {
  const CompletionText({
    super.key,
    required this.text,
    required this.style,
    this.trigger,
    this.maxLines = 1,
    this.holdAfterFall = false,
  });
  final String text;
  final TextStyle style;
  final Object? trigger;
  final int maxLines;
  final bool holdAfterFall;
  @override
  State<CompletionText> createState() => _CompletionTextState();
}

class _CompletionTextState extends State<CompletionText>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 440),
      value: widget.trigger == null ? 1 : 0,
    );
    if (widget.trigger != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (MediaQuery.disableAnimationsOf(context)) {
          controller.value = 1;
        } else {
          controller.forward();
        }
      });
    }
  }

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
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) {
      return Text(
        widget.text,
        maxLines: widget.maxLines,
        overflow: TextOverflow.ellipsis,
        style: widget.style,
      );
    }
    return Semantics(
      label: widget.text,
      child: ExcludeSemantics(
        child: AnimatedBuilder(
          animation: controller,
          builder: (context, _) {
            final value = controller.value;
            final falling = value < .68;
            final opacity = falling
                ? 1 - value / .68
                : widget.holdAfterFall
                ? 0.0
                : (value - .68) / .32;
            return Transform.translate(
              offset: Offset(0, falling ? 18 * value / .68 : 0),
              child: Opacity(
                opacity: opacity.clamp(0, 1),
                child: Text(
                  widget.text,
                  maxLines: widget.maxLines,
                  overflow: TextOverflow.ellipsis,
                  style: widget.style,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
