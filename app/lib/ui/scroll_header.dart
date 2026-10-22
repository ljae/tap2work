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
  bool userScrolling = false;

  void reveal() {
    travel = 0;
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
      // Wheel scrolling sends UserScrollNotification before this event.
      if (event.dragDetails != null) userScrolling = true;
      travel = 0;
    }
    if (event is UserScrollNotification) {
      // Includes wheel/trackpad scrolling, which has no drag details.
      userScrolling = event.direction != ScrollDirection.idle;
    }
    if (event is ScrollUpdateNotification &&
        (event.dragDetails != null || userScrolling)) {
      final delta = event.scrollDelta ?? 0;
      if (delta.sign != travel.sign) travel = 0;
      travel += delta;
      if (event.metrics.pixels <= event.metrics.minScrollExtent) {
        reveal();
      } else if (travel > 18) {
        hidden.value = true;
      } else if (travel < -12) {
        reveal();
      }
    }
    if (event is OverscrollNotification && event.overscroll < 0) reveal();
    if (event is ScrollEndNotification) userScrolling = false;
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
