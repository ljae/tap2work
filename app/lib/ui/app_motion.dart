import 'package:flutter/material.dart';

/// Product motion tokens; inspired by Toss UX, not official Toss timings.
abstract final class AppMotion {
  static const completion = Duration(milliseconds: 440);
  static const completionHold = Duration(milliseconds: 520);
  static const press = Duration(milliseconds: 80);
  static const release = Duration(milliseconds: 260);
  static const quick = Duration(milliseconds: 160);
  static const content = Duration(milliseconds: 240);
  static const sheet = Duration(milliseconds: 360);
  static const exit = Duration(milliseconds: 220);
  static const enterCurve = Curves.easeOutCubic;
  static const exitCurve = Curves.easeInCubic;

  static bool reduced(BuildContext context) =>
      MediaQuery.disableAnimationsOf(context);
  static Duration duration(BuildContext context, Duration value) =>
      reduced(context) ? Duration.zero : value;
  static AnimationStyle panelStyle(BuildContext context) => reduced(context)
      ? AnimationStyle.noAnimation
      : const AnimationStyle(
          duration: sheet,
          reverseDuration: exit,
          curve: enterCurve,
          reverseCurve: exitCurve,
        );
  static AnimationStyle dialogStyle(BuildContext context) => reduced(context)
      ? AnimationStyle.noAnimation
      : const AnimationStyle(
          duration: content,
          reverseDuration: quick,
          curve: enterCurve,
          reverseCurve: exitCurve,
        );

  static ChipAnimationStyle chipStyle(BuildContext context) {
    final style = reduced(context)
        ? AnimationStyle.noAnimation
        : const AnimationStyle(
            duration: quick,
            reverseDuration: quick,
            curve: enterCurve,
          );
    return ChipAnimationStyle(
      enableAnimation: style,
      selectAnimation: style,
      avatarDrawerAnimation: style,
      deleteDrawerAnimation: style,
    );
  }

  static Widget buttonFeedback(
    BuildContext context,
    Set<WidgetState> states,
    Widget? child,
  ) {
    final pressed =
        states.contains(WidgetState.pressed) &&
        !states.contains(WidgetState.disabled);
    return AnimatedScale(
      scale: pressed && !reduced(context) ? .95 : 1,
      duration: duration(context, pressed ? press : release),
      curve: pressed ? Curves.easeOut : Curves.easeOutBack,
      child: child,
    );
  }
}

/// Button themes cover pointer and keyboard activation, including new screens.
class AppMotionScope extends StatelessWidget {
  const AppMotionScope({super.key, required this.child});
  final Widget child;
  static bool contains(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_MotionMarker>() != null;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    ButtonStyle style(ButtonStyle? original) =>
        (original ?? const ButtonStyle()).copyWith(
          backgroundBuilder: AppMotion.buttonFeedback,
          animationDuration: AppMotion.duration(context, AppMotion.quick),
        );
    return _MotionMarker(
      child: Theme(
        data: theme.copyWith(
          expansionTileTheme: theme.expansionTileTheme.copyWith(
            expansionAnimationStyle: AppMotion.dialogStyle(context),
          ),
          filledButtonTheme: FilledButtonThemeData(
            style: style(theme.filledButtonTheme.style),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: style(theme.elevatedButtonTheme.style),
          ),
          outlinedButtonTheme: OutlinedButtonThemeData(
            style: style(theme.outlinedButtonTheme.style),
          ),
          textButtonTheme: TextButtonThemeData(
            style: style(theme.textButtonTheme.style),
          ),
          iconButtonTheme: IconButtonThemeData(
            style: style(theme.iconButtonTheme.style),
          ),
        ),
        child: child,
      ),
    );
  }
}

class _MotionMarker extends InheritedWidget {
  const _MotionMarker({required super.child});
  @override
  bool updateShouldNotify(_MotionMarker oldWidget) => false;
}

/// Animate the current content only: no stale outgoing forms or duplicate actions.
/// Unchanged trigger (e.g. polling) preserves state and does not replay motion.
class AppContentTransition extends StatefulWidget {
  const AppContentTransition({
    super.key,
    required this.trigger,
    required this.child,
  });
  final Object? trigger;
  final Widget child;
  @override
  State<AppContentTransition> createState() => _AppContentTransitionState();
}

class _AppContentTransitionState extends State<AppContentTransition>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller = AnimationController(
    vsync: this,
    duration: AppMotion.content,
    value: 1,
  );
  @override
  void didUpdateWidget(AppContentTransition oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.trigger != oldWidget.trigger) {
      if (AppMotion.reduced(context)) {
        controller.value = 1;
      } else {
        controller.forward(from: 0);
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (AppMotion.reduced(context)) controller.value = 1;
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    child: widget.child,
    builder: (context, child) {
      final value = AppMotion.reduced(context)
          ? 1.0
          : AppMotion.enterCurve.transform(controller.value);
      return Opacity(
        opacity: .3 + .7 * value,
        child: Transform.translate(
          offset: Offset(0, 10 * (1 - value)),
          child: child,
        ),
      );
    },
  );
}

Future<T?> showAppDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
}) => showDialog<T>(
  context: context,
  builder: builder,
  barrierDismissible: barrierDismissible,
  animationStyle: AppMotion.dialogStyle(context),
);

/// Determinate progress follows confirmed data; indeterminate loading is static
/// with reduced motion and never reports a fabricated completion percentage.
class AppLinearProgress extends StatelessWidget {
  const AppLinearProgress({
    super.key,
    this.value,
    this.minHeight,
    this.color,
    this.backgroundColor,
    this.borderRadius,
    this.semanticsLabel,
  });
  final double? value, minHeight;
  final Color? color, backgroundColor;
  final BorderRadiusGeometry? borderRadius;
  final String? semanticsLabel;
  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: value ?? 0, end: value ?? 0),
    duration: AppMotion.duration(context, AppMotion.content),
    curve: AppMotion.enterCurve,
    builder: (context, animated, _) => _loadingSemantics(
      value,
      LinearProgressIndicator(
        value: value == null
            ? (AppMotion.reduced(context) ? .5 : null)
            : animated,
        minHeight: minHeight,
        color: color,
        backgroundColor: backgroundColor,
        borderRadius: borderRadius,
        semanticsLabel: semanticsLabel ?? (value == null ? '처리 중' : null),
        semanticsValue: value == null ? null : '${(value! * 100).round()}',
      ),
    ),
  );
}

class AppCircularProgress extends StatelessWidget {
  const AppCircularProgress({
    super.key,
    this.value,
    this.strokeWidth = 4,
    this.color,
    this.backgroundColor,
  });
  final double? value;
  final double strokeWidth;
  final Color? color, backgroundColor;
  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: value ?? 0, end: value ?? 0),
    duration: AppMotion.duration(context, AppMotion.content),
    curve: AppMotion.enterCurve,
    builder: (context, animated, _) => _loadingSemantics(
      value,
      CircularProgressIndicator(
        value: value == null
            ? (AppMotion.reduced(context) ? .75 : null)
            : animated,
        strokeWidth: strokeWidth,
        color: color,
        backgroundColor: backgroundColor,
        semanticsLabel: value == null ? '처리 중' : '진행률',
        semanticsValue: value == null ? null : '${(value! * 100).round()}',
      ),
    ),
  );
}

Widget _loadingSemantics(double? value, Widget child) => value == null
    ? Semantics(
        label: '처리 중',
        liveRegion: true,
        child: ExcludeSemantics(child: child),
      )
    : child;
