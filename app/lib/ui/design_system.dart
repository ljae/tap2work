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

/// Shared route for readable, keyboard-safe sheets. Form drafts keep PopScope.
Future<T?> showAppSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
}) => showModalBottomSheet<T>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  isDismissible: false,
  enableDrag: false,
  showDragHandle: false,
  backgroundColor: AppColors.paper,
  constraints: const BoxConstraints(maxWidth: 880),
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
  ),
  clipBehavior: Clip.antiAlias,
  sheetAnimationStyle: AppMotion.panelStyle(context),
  builder: (context) => AnimatedPadding(
    duration: AppMotion.duration(context, AppMotion.quick),
    curve: AppMotion.enterCurve,
    padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
    child: FractionallySizedBox(
      heightFactor: MediaQuery.viewInsetsOf(context).bottom > 0 ? 1 : .94,
      child: MediaQuery.removeViewInsets(
        context: context,
        removeBottom: true,
        child: Theme(
          data: Theme.of(context).copyWith(
            scaffoldBackgroundColor: AppColors.paper,
            appBarTheme: Theme.of(context).appBarTheme.copyWith(
              backgroundColor: AppColors.paper,
              surfaceTintColor: Colors.transparent,
              toolbarHeight: 72,
              titleTextStyle: AppText.section,
              titleSpacing: 16,
            ),
          ),
          child: Column(
            children: [
              ExcludeSemantics(
                child: Padding(
                  padding: const EdgeInsets.only(top: 12, bottom: 4),
                  child: Container(
                    width: 32,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.controlLine,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
              Expanded(child: Builder(builder: builder)),
            ],
          ),
        ),
      ),
    ),
  ),
);

const appEditorWidth = 688.0;

/// A wrapping heading and persistent action area, shared by all form families.
class AppEditorScaffold extends StatelessWidget {
  const AppEditorScaffold({
    super.key,
    required this.title,
    required this.body,
    this.subtitle,
    this.footer,
    this.onClose,
  });
  final String title;
  final String? subtitle;
  final Widget body;
  final Widget? footer;
  final VoidCallback? onClose;
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.paper,
    bottomNavigationBar: footer == null
        ? null
        : SafeArea(top: false, child: footer!),
    body: SafeArea(
      top: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: appEditorWidth),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 12, 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Semantics(
                            header: true,
                            child: Text(title, style: AppText.title),
                          ),
                          if (subtitle != null) ...[
                            const SizedBox(height: 8),
                            Text(subtitle!, style: AppText.caption),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    CloseButton(
                      onPressed: onClose ?? () => Navigator.maybePop(context),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: appEditorWidth),
                child: SizedBox(width: double.infinity, child: body),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class AppSheetFooter extends StatelessWidget {
  const AppSheetFooter({super.key, required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Container(
    decoration: const BoxDecoration(
      color: AppColors.paper,
      border: Border(top: BorderSide(color: AppColors.line)),
    ),
    padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
    child: Center(
      heightFactor: 1,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0) const SizedBox(height: 8),
              children[i],
            ],
          ],
        ),
      ),
    ),
  );
}

/// Keeps related sheet actions aligned while allowing large text to wrap.
class AppSheetActions extends StatelessWidget {
  const AppSheetActions({super.key, required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final scale = MediaQuery.textScalerOf(context).scale(14) / 14;
      final horizontal =
          children.length > 1 && box.maxWidth >= children.length * 130 * scale;
      final theme = Theme.of(context);
      const size = WidgetStatePropertyAll(Size(48, 56));
      return Theme(
        data: theme.copyWith(
          filledButtonTheme: FilledButtonThemeData(
            style: (theme.filledButtonTheme.style ?? const ButtonStyle())
                .copyWith(minimumSize: size),
          ),
          outlinedButtonTheme: OutlinedButtonThemeData(
            style: (theme.outlinedButtonTheme.style ?? const ButtonStyle())
                .copyWith(minimumSize: size),
          ),
          textButtonTheme: TextButtonThemeData(
            style: (theme.textButtonTheme.style ?? const ButtonStyle())
                .copyWith(minimumSize: size),
          ),
        ),
        child: horizontal
            ? IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = 0; i < children.length; i++) ...[
                      if (i > 0) const SizedBox(width: 8),
                      Expanded(child: children[i]),
                    ],
                  ],
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < children.length; i++) ...[
                    if (i > 0) const SizedBox(height: 8),
                    children[i],
                  ],
                ],
              ),
      );
    },
  );
}

/// One semantic group; the same spacing applies to manuals, pay and settings.
class AppFormSection extends StatelessWidget {
  const AppFormSection({
    super.key,
    required this.title,
    required this.children,
    this.description,
  });
  final String title;
  final String? description;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 20),
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(header: true, child: Text(title, style: AppText.section)),
        if (description != null) ...[
          const SizedBox(height: 8),
          Text(description!, style: AppText.caption),
        ],
        for (final child in children) ...[const SizedBox(height: 20), child],
      ],
    ),
  );
}

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
  Widget build(BuildContext context) => AppEditorScaffold(
    title: title is Text ? (title as Text).data ?? '' : '',
    body: SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (title != null && title is! Text) title!,
              content ?? const SizedBox.shrink(),
            ],
          ),
        ),
      ),
    ),
    footer: actions == null
        ? null
        : AppSheetFooter(children: [AppSheetActions(children: actions!)]),
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
