import 'dart:convert';
import 'package:flutter/services.dart';

/// Public, versioned source-text dictionaries. No runtime translation charge.
/// An edited field only matches when its exact source text is still current.
class BundledManualTranslations {
  static final Map<String, Future<Map<String, String>>> _loads = {};
  static Future<Map<String, String>> load(String locale) =>
      _loads.putIfAbsent(locale, () async {
        if (locale == 'ko') return const {};
        try {
          final data = jsonDecode(
            await rootBundle.loadString(
              'assets/manual_translations/$locale.json',
            ),
          );
          if (data is! Map ||
              data['targetLocale'] != locale ||
              data['translations'] is! Map) {
            return const {};
          }
          return Map<String, String>.from(data['translations'] as Map);
        } catch (_) {
          return const {};
        }
      });
}
