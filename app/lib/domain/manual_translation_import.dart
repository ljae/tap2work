import 'dart:convert';

int manualTranslationLimit(String field) => field == 'title'
    ? 360
    : field == 'tip'
    ? 3600
    : 24000;

/// Validate the complete import before changing any editor draft.
Map<String, String> parseManualTranslationImport(
  String input, {
  required String locale,
  required Map<String, dynamic> source,
  String? stepId,
}) {
  final decoded = jsonDecode(input);
  if (decoded is! Map ||
      decoded['locale'] != locale ||
      decoded['fields'] is! List) {
    throw const FormatException();
  }
  final imported = <String, String>{};
  for (final value in decoded['fields'] as List) {
    if (value is! Map ||
        !['title', 'manual', 'tip', 'body'].contains(value['field']) ||
        source[value['field']] is! String ||
        (source[value['field']] as String).trim().isEmpty ||
        value['stepId'] != stepId ||
        value['sourceText'] != source[value['field']] ||
        value['text'] is! String ||
        (value['text'] as String).length >
            manualTranslationLimit(value['field'] as String) ||
        imported.containsKey(value['field'])) {
      throw const FormatException();
    }
    imported[value['field'] as String] = value['text'] as String;
  }
  if (imported.isEmpty) throw const FormatException();
  return imported;
}
