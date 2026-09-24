import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key});

  @override
  Widget build(BuildContext context) => FittedBox(
    alignment: Alignment.centerLeft,
    fit: BoxFit.scaleDown,
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFEFEAE7),
        border: Border.all(color: const Color(0xFFE5DFDB)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/branding/tap2work.png',
              width: 46,
              height: 46,
              semanticLabel: 'tap2.work 로고',
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 7),
            Image.asset(
              'assets/branding/tap2work_wordmark.png',
              width: 132,
              height: 34,
              fit: BoxFit.contain,
              semanticLabel: 'Tap2.work 워드마크',
            ),
          ],
        ),
      ),
    ),
  );
}

class BrandHeader extends StatelessWidget implements PreferredSizeWidget {
  const BrandHeader({super.key, required this.action});
  final Widget action;

  @override
  Size get preferredSize => const Size.fromHeight(80);

  @override
  Widget build(BuildContext context) => AppBar(
    toolbarHeight: 80,
    backgroundColor: const Color(0xFFF8F6F4),
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    scrolledUnderElevation: 0,
    shape: const Border(bottom: BorderSide(color: Color(0xFFE7E3E0))),
    titleSpacing: 16,
    title: const BrandLogo(),
    actions: [
      Padding(padding: const EdgeInsets.only(right: 16), child: action),
    ],
  );
}

class HeaderAccountButton extends StatelessWidget {
  const HeaderAccountButton({super.key});

  @override
  Widget build(BuildContext context) => Container(
    width: 48,
    height: 48,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: const Color(0xFFE0DBD7)),
      borderRadius: BorderRadius.circular(12),
    ),
    child: const Icon(Icons.person_outline, size: 22, color: AppColors.ink),
  );
}

/// Displays a section of a supplied artwork sheet without altering the file.
class ArtworkCrop extends StatefulWidget {
  const ArtworkCrop({
    super.key,
    required this.asset,
    required this.crop,
    required this.width,
    required this.height,
    required this.semanticLabel,
    this.borderRadius = 0,
  });

  final String asset;
  final Rect crop;
  final double width;
  final double height;
  final String semanticLabel;
  final double borderRadius;

  @override
  State<ArtworkCrop> createState() => _ArtworkCropState();
}

class _ArtworkCropState extends State<ArtworkCrop> {
  ImageStream? _stream;
  late final ImageStreamListener _listener;
  ui.Image? _image;

  @override
  void initState() {
    super.initState();
    _listener = ImageStreamListener((info, _) {
      if (mounted) setState(() => _image = info.image);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resolve();
  }

  @override
  void didUpdateWidget(covariant ArtworkCrop oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.asset != widget.asset) _resolve();
  }

  void _resolve() {
    final next = AssetImage(
      widget.asset,
    ).resolve(createLocalImageConfiguration(context));
    if (_stream != null && _stream!.key == next.key) return;
    _stream?.removeListener(_listener);
    _stream = next;
    _image = null;
    next.addListener(_listener);
  }

  @override
  void dispose() {
    _stream?.removeListener(_listener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: widget.semanticLabel,
      image: true,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        child: SizedBox(
          width: widget.width,
          height: widget.height,
          child: CustomPaint(
            painter: _image == null
                ? null
                : _ArtworkPainter(_image!, widget.crop),
          ),
        ),
      ),
    );
  }
}

class _ArtworkPainter extends CustomPainter {
  const _ArtworkPainter(this.image, this.crop);

  final ui.Image image;
  final Rect crop;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawImageRect(
      image,
      crop,
      Offset.zero & size,
      Paint()..filterQuality = FilterQuality.high,
    );
  }

  @override
  bool shouldRepaint(covariant _ArtworkPainter oldDelegate) =>
      oldDelegate.image != image || oldDelegate.crop != crop;
}

abstract final class AppColors {
  static const paper = Color(0xFFF5F5F7);
  static const white = Color(0xFFFFFFFF);
  static const accent = Color(0xFFE34437);
  static const green = Color(0xFF29364B);
  static const ink = Color(0xFF20232B);
  static const muted = Color(0xFF747985);
  static const lime = Color(0xFFF0F1F4);
  static const peach = Color(0xFFFBEAE7);
  static const line = Color(0xFFE5E5EA);
}

class Surface extends StatelessWidget {
  const Surface({
    super.key,
    required this.child,
    this.color = AppColors.white,
    this.padding = const EdgeInsets.all(22),
  });
  final Widget child;
  final Color color;
  final EdgeInsets padding;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: padding,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: color == AppColors.green ? color : AppColors.line,
      ),
    ),
    child: child,
  );
}

class Eyebrow extends StatelessWidget {
  const Eyebrow(this.text, {super.key, this.color = AppColors.muted});
  final String text;
  final Color color;
  @override
  Widget build(BuildContext context) => Text(
    text,
    style: TextStyle(
      color: color,
      fontSize: 11,
      fontWeight: FontWeight.w600,
      letterSpacing: .8,
    ),
  );
}

class PageHeading extends StatelessWidget {
  const PageHeading(this.kicker, this.title, this.subtitle, {super.key});
  final String kicker;
  final String title;
  final String subtitle;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Eyebrow(kicker),
        const SizedBox(height: 9),
        Text(
          title,
          style: const TextStyle(
            fontSize: 29,
            height: 1.3,
            fontWeight: FontWeight.w700,
            letterSpacing: -1.1,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 14,
            height: 1.6,
            color: AppColors.muted,
          ),
        ),
      ],
    ),
  );
}

class Information extends StatelessWidget {
  const Information(this.text, {super.key});
  final String text;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: const Color(0xFFEEEEF2),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Text(
      text,
      style: const TextStyle(fontSize: 12, height: 1.6, color: AppColors.muted),
    ),
  );
}

class Person extends StatelessWidget {
  const Person({
    super.key,
    required this.name,
    required this.subtitle,
    this.trailing,
  });
  final String name;
  final String subtitle;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      CircleAvatar(
        backgroundColor: AppColors.peach,
        foregroundColor: AppColors.green,
        child: Text(name.characters.first),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 12, color: AppColors.muted),
            ),
          ],
        ),
      ),
      ?trailing,
    ],
  );
}
