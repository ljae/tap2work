import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

/// Bundled images keep flags consistent offline and across web/native fonts.
/// Adjacent names/parent button labels provide the accessible meaning.
class CountryFlag extends StatelessWidget {
  const CountryFlag({super.key, required this.countryCode, this.size = 28});
  final String? countryCode;
  final double size;

  @override
  Widget build(BuildContext context) {
    final code = countryCode?.toUpperCase();
    final fallback = Icon(Icons.public, size: size);
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: size,
        child: code == null || !RegExp(r'^[A-Z]{2}$').hasMatch(code)
            ? fallback
            : Image.asset(
                'assets/flags/$code.png',
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => fallback,
              ),
      ),
    );
  }
}

/// Native language labels share one catalog across all settings controls.
class LanguageLabel extends StatelessWidget {
  const LanguageLabel({super.key, required this.languageTag});
  final String languageTag;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      CountryFlag(countryCode: appLanguageCountries[languageTag], size: 24),
      const SizedBox(width: 8),
      Flexible(
        child: Text(
          appLanguageNames[languageTag] ?? languageTag,
          style: const TextStyle(fontFamilyFallback: appFontFallbacks),
        ),
      ),
    ],
  );
}
