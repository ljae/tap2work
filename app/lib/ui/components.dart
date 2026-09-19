import 'package:flutter/material.dart';

class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key});

  @override
  Widget build(BuildContext context) => Image.asset(
    'assets/branding/tap2work.png',
    width: 104,
    height: 56,
    fit: BoxFit.contain,
    semanticLabel: 'tap2.work 로고',
  );
}

abstract final class AppColors {
  static const paper = Color(0xFFF6F5EF);
  static const white = Color(0xFFFFFEFA);
  static const green = Color(0xFF203D34);
  static const ink = Color(0xFF253E35);
  static const muted = Color(0xFF667269);
  static const lime = Color(0xFFE1F090);
  static const peach = Color(0xFFF2B28B);
  static const line = Color(0xFFDDDED6);
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
      borderRadius: BorderRadius.circular(22),
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
      color: const Color(0xFFEBEDE3),
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
