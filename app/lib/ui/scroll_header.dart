import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
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
  Offset? lastDragPosition;
  Duration? lastWheelTime;

  void reveal() {
    travel = 0;
    lastDragPosition = null;
    lastWheelTime = null;
    hidden.value = false;
  }

  @override
  void didUpdateWidget(covariant AppScrollHeaderScope oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.resetKey != oldWidget.resetKey) reveal();
  }

  bool get protectedNavigation =>
      MediaQuery.accessibleNavigationOf(context) ||
      MediaQuery.viewInsetsOf(context).bottom > 0;

  void applyInput(double delta) {
    if (protectedNavigation) {
      reveal();
      return;
    }
    if (delta == 0) return;
    if (delta.sign != travel.sign) travel = 0;
    travel += delta;
    if (travel > 18) {
      hidden.value = true;
    } else if (travel < -12) {
      hidden.value = false;
    }
  }

  void startDrag(DragStartDetails details) {
    travel = 0;
    lastDragPosition = details.globalPosition;
  }

  void updateDrag(DragUpdateDetails details) {
    // Global coordinates stay stable while the header resizes the viewport.
    // Local deltas can include the moving list's transform during that resize.
    final previous = lastDragPosition;
    lastDragPosition = details.globalPosition;
    applyInput(
      previous == null
          ? -(details.primaryDelta ?? details.delta.dy)
          : previous.dy - details.globalPosition.dy,
    );
  }

  void onPointerSignal(PointerSignalEvent event) {
    if (event is! PointerScrollEvent ||
        event.scrollDelta.dy.abs() <= event.scrollDelta.dx.abs()) {
      return;
    }
    final previous = lastWheelTime;
    if (previous == null ||
        event.timeStamp - previous > const Duration(milliseconds: 240)) {
      travel = 0;
    }
    lastWheelTime = event.timeStamp;
    // A wheel/trackpad gesture produces many small ticks, each with its own
    // ScrollStart/End. Read input once, even when a short list cannot move.
    applyInput(event.scrollDelta.dy);
  }

  bool onScroll(ScrollNotification event) {
    if (event.metrics.axis != Axis.vertical) return false;
    if (event is ScrollStartNotification && event.dragDetails != null) {
      startDrag(event.dragDetails!);
    } else if (event is ScrollUpdateNotification && event.dragDetails != null) {
      updateDrag(event.dragDetails!);
    } else if (event is OverscrollNotification && event.dragDetails != null) {
      updateDrag(event.dragDetails!);
    } else if (event is ScrollEndNotification) {
      lastDragPosition = null;
    }
    // Ballistic bounces, programmatic jumps and layout corrections contain no
    // drag details and therefore cannot reopen or collapse the header.
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
    child: Listener(
      onPointerSignal: onPointerSignal,
      child: NotificationListener<ScrollNotification>(
        onNotification: onScroll,
        child: widget.child,
      ),
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
    final scope = context.findAncestorStateOfType<_AppScrollHeaderScopeState>();
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onVerticalDragStart: scope?.startDrag,
      onVerticalDragUpdate: scope?.updateDrag,
      child: ValueListenableBuilder<bool>(
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
      ),
    );
  }
}
