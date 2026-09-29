import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

/// Public dates only. Never uses the authenticated operations client.
class KoreanHolidays {
  static final Map<int, Future<Map<String, String>>> _requests = {};
  static Future<Map<String, String>>? _bundled;
  static Map<String, String> parse(String text) {
    final decoded = jsonDecode(text) as Map<String, dynamic>;
    final map = decoded.values.every((v) => v is Map)
        ? <String, dynamic>{
            for (final year in decoded.values)
              ...(year as Map<String, dynamic>),
          }
        : decoded;
    return map.map((date, names) {
      if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(date) ||
          names is! List ||
          names.isEmpty ||
          names.any((n) => n is! String || n.length > 100)) {
        throw const FormatException('Invalid holiday calendar');
      }
      return MapEntry(date, names.join(' · '));
    });
  }

  static Future<Map<String, String>> bundled() =>
      _bundled ??= rootBundle.loadString('assets/calendar/kr.json').then(parse);
  static Future<Map<String, String>> year(int year) =>
      _requests.putIfAbsent(year, () async {
        final client = http.Client();
        try {
          final response = await client
              .get(Uri.parse('https://holidays.hyunbin.page/$year.json'))
              .timeout(const Duration(seconds: 4));
          if (response.statusCode != 200) {
            throw const FormatException('Holiday calendar unavailable');
          }
          final dates = parse(utf8.decode(response.bodyBytes));
          if (dates.isEmpty || dates.keys.any((d) => !d.startsWith('$year-'))) {
            throw const FormatException('Invalid calendar year');
          }
          return dates;
        } finally {
          client.close();
        }
      });
}
