import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'app_motion.dart';

/// One scroll policy for the brand, search and destination toolbars.
/// Horizontal gestures, programmatic jumps and layout changes do not toggle it.
class AppScrollHeaderScope extends StatefulWidget {
  const AppScrollHeaderScope({
    super.key,
    required this.resetKey,
    required this.child,
  });
  final Object? resetKey;
  final Widget child;

  static void reveal(BuildContext context) =>
      context.findAncestorStateOfType<_AppScrollHeaderScopeState>()?.reveal();

  @override
  State<AppScrollHeaderScope> createState() => _AppScrollHeaderScopeState();
}

class _AppScrollHeaderScopeState extends State<AppScrollHeaderScope> {
  final hidden = ValueNotifier(false);
  double travel = 0;
  bool pendingUserScroll = false;

  void reveal() {
    travel = 0;
    pendingUserScroll = false;
    hidden.value = false;
  }

  @override
  void didUpdateWidget(covariant AppScrollHeaderScope oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.resetKey != oldWidget.resetKey) reveal();
  }

  bool onScroll(ScrollNotification event) {
    if (event.metrics.axis != Axis.vertical) return false;
    if (MediaQuery.accessibleNavigationOf(context) ||
        MediaQuery.viewInsetsOf(context).bottom > 0) {
      reveal();
      return false;
    }
    if (event is ScrollStartNotification) {
      travel = 0;
    }
    if (event is UserScrollNotification) {
      // A wheel tick announces its direction before its one position update.
      // Consume this once, so inertia/layout corrections cannot reuse it.
      pendingUserScroll = event.direction != ScrollDirection.idle;
    }
    double? delta;
    if (event is ScrollUpdateNotification) {
      final drag = event.dragDetails;
      delta = drag != null
          ? -(drag.primaryDelta ?? drag.delta.dy)
          : pendingUserScroll
          ? event.scrollDelta
          : null;
      pendingUserScroll = false;
    }
    if (event is OverscrollNotification) {
      final drag = event.dragDetails;
      delta = drag != null
          ? -(drag.primaryDelta ?? drag.delta.dy)
          : pendingUserScroll
          ? event.overscroll
          : null;
      pendingUserScroll = false;
    }
    if (delta != null && delta != 0) {
      if (delta.sign != travel.sign) travel = 0;
      travel += delta;
      // Only input direction changes visibility. Resizing a viewport can clamp
      // its offset to zero or reverse a ballistic bounce without new input.
      if (travel > 18) {
        hidden.value = true;
      } else if (travel < -12) {
        reveal();
      }
    }
    if (event is ScrollEndNotification) pendingUserScroll = false;
    return false;
  }

  @override
  void dispose() {
    hidden.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _HeaderVisibility(
    hidden: hidden,
    child: NotificationListener<ScrollNotification>(
      onNotification: onScroll,
      child: widget.child,
    ),
  );
}

class _HeaderVisibility extends InheritedWidget {
  const _HeaderVisibility({required this.hidden, required super.child});
  final ValueNotifier<bool> hidden;
  @override
  bool updateShouldNotify(_HeaderVisibility oldWidget) =>
      hidden != oldWidget.hidden;
}

/// Retains text inputs and toolbar state while returning their height to content.
class AppScrollHeader extends StatelessWidget {
  const AppScrollHeader({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final visibility = context
        .dependOnInheritedWidgetOfExactType<_HeaderVisibility>();
    if (visibility == null) return child;
    return ValueListenableBuilder<bool>(
      valueListenable: visibility.hidden,
      child: child,
      builder: (context, hidden, child) => ExcludeFocus(
        excluding: hidden,
        child: ExcludeSemantics(
          excluding: hidden,
          child: IgnorePointer(
            ignoring: hidden,
            child: TweenAnimationBuilder<double>(
              tween: Tween(end: hidden ? 0 : 1),
              duration: AppMotion.duration(context, AppMotion.content),
              curve: AppMotion.enterCurve,
              child: child,
              builder: (context, heightFactor, child) => ClipRect(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  heightFactor: heightFactor,
                  child: child,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
