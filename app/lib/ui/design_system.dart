import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'design_tokens.dart';
import 'app_motion.dart';
export 'app_motion.dart';

/// Paint-only feedback keeps the button's original focus, semantics and gesture.
class PressBounce extends StatefulWidget {
  const PressBounce({super.key, required this.child});
  final Widget child;
  @override
  State<PressBounce> createState() => _PressBounceState();
}

class _PressBounceState extends State<PressBounce> {
  Offset? origin;
  bool pressed = false;
  void setPressed(bool value) {
    if (pressed != value) setState(() => pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final child = widget.child;
    if (AppMotionScope.contains(context) &&
        (child is ButtonStyleButton || child is IconButton)) {
      return child;
    }
    final enabled = switch (child) {
      ButtonStyleButton button => button.enabled,
      IconButton button => button.onPressed != null,
      ChoiceChip chip => chip.onSelected != null,
      FilterChip chip => chip.onSelected != null,
      InkWell ink => ink.onTap != null || ink.onLongPress != null,
      _ => true,
    };
    final reduce = MediaQuery.disableAnimationsOf(context);
    return Listener(
      onPointerDown: enabled
          ? (event) {
              if (event.buttons != 1) return;
              origin = event.position;
              setPressed(true);
            }
          : null,
      onPointerMove: (event) {
        if (origin != null && (event.position - origin!).distance > 18) {
          setPressed(false);
        }
      },
      onPointerUp: (_) {
        origin = null;
        setPressed(false);
      },
      onPointerCancel: (_) {
        origin = null;
        setPressed(false);
      },
      child: AnimatedContainer(
        duration: reduce
            ? Duration.zero
            : (pressed ? AppMotion.press : AppMotion.release),
        curve: pressed ? Curves.easeOut : Curves.easeOutBack,
        transformAlignment: Alignment.center,
        transform: Matrix4.diagonal3Values(
          pressed && enabled && !reduce ? .95 : 1,
          pressed && enabled && !reduce ? .95 : 1,
          1,
        ),
        child: child,
      ),
    );
  }
}

/// Form sheets close through the form's back/save controls, preserving PopScope.
Future<T?> showAppSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
}) => showModalBottomSheet<T>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  isDismissible: false,
  enableDrag: false,
  // Flutter's built-in handle exposes a semantic dismiss action that calls
  // pop directly. The decorative handle below cannot bypass draft PopScope.
  showDragHandle: false,
  backgroundColor: AppColors.surface,
  constraints: const BoxConstraints(maxWidth: 960),
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
  ),
  clipBehavior: Clip.antiAlias,
  sheetAnimationStyle: AppMotion.panelStyle(context),
  builder: (context) => FractionallySizedBox(
    heightFactor: .92,
    child: Column(
      children: [
        ExcludeSemantics(
          child: Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 20),
            child: Container(
              width: 32,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFF686F78),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
        Expanded(child: builder(context)),
      ],
    ),
  ),
);

class AppPageRoute<T> extends CupertinoPageRoute<T> {
  AppPageRoute({
    required super.builder,
    super.settings,
    this.reduceMotion = false,
  });
  final bool reduceMotion;
  @override
  Duration get transitionDuration =>
      reduceMotion ? Duration.zero : AppMotion.sheet;
  @override
  Duration get reverseTransitionDuration =>
      reduceMotion ? Duration.zero : AppMotion.exit;
  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => MediaQuery.disableAnimationsOf(context)
      ? child
      : super.buildTransitions(context, animation, secondaryAnimation, child);
}

Future<T?> showAppFormSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
}) => showAppSheet<T>(context, builder: builder);

class AppSheetPanel extends StatelessWidget {
  const AppSheetPanel({super.key, this.title, this.content, this.actions});
  final Widget? title, content;
  final List<Widget>? actions;
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.surface,
    body: SafeArea(
      top: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
              child: DefaultTextStyle(style: AppText.title, child: title!),
            ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: content ?? const SizedBox.shrink(),
            ),
          ),
          if (actions != null)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Wrap(
                alignment: WrapAlignment.end,
                spacing: 8,
                runSpacing: 8,
                children: actions!,
              ),
            ),
        ],
      ),
    ),
  );
}

/// Card-shaped loading rows; static when reduced motion is on.
class WorkspaceSkeleton extends StatelessWidget {
  const WorkspaceSkeleton({super.key});
  @override
  Widget build(BuildContext context) {
    final rows = ListView.separated(
      padding: const EdgeInsets.all(24),
      itemCount: 4,
      separatorBuilder: (_, _) => const SizedBox(height: 32),
      itemBuilder: (_, _) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Shimmer.fromColors(
          enabled: !MediaQuery.disableAnimationsOf(context),
          baseColor: const Color(0xFF222528),
          highlightColor: const Color(0xFF34383D),
          period: const Duration(milliseconds: 1500),
          child: Row(
            children: [
              const CircleAvatar(
                radius: 22,
                backgroundColor: Color(0xFF222528),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 16,
                      decoration: BoxDecoration(
                        color: const Color(0xFF222528),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 10),
                    FractionallySizedBox(
                      widthFactor: .65,
                      child: Container(
                        height: 13,
                        decoration: BoxDecoration(
                          color: const Color(0xFF222528),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
    return Semantics(
      label: '매장 정보 불러오는 중',
      liveRegion: true,
      child: ExcludeSemantics(child: RepaintBoundary(child: rows)),
    );
  }
}
