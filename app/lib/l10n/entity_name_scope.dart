import 'package:flutter/widgets.dart';
import '../state/operations_controller.dart';
import 'app_localizations.dart';
import 'manual_text_scope.dart';
import 'entity_name_messages.dart';

/// Display only: stable IDs and editable source names remain unchanged.
String entityDisplayName(
  BuildContext context,
  OperationsController? ops,
  String kind,
  dynamic id,
  dynamic source, {
  String? locale,
}) {
  final text = source?.toString() ?? '';
  final language = locale ?? AppStrings.of(context).languageTag;
  if (language == 'ko') return text;
  final cell =
      ops?.data?['manualContentTranslations']?[kind == 'part'
          ? 'parts'
          : 'folders']?[id]?[language]?['name'];
  if (cell is Map &&
      cell['current'] != false &&
      cell['sourceText'] == text &&
      cell['text'] is String &&
      (cell['text'] as String).trim().isNotEmpty) {
    return cell['text'];
  }
  final index = [
    'ko',
    'en',
    'vi',
    'zh-Hans',
    'ja',
    'th',
    'ne',
    'id',
  ].indexOf(language);
  final row = entityNameRows[text];
  if (row != null && index >= 0) return row[index];
  return locale == null ? manualDisplayText(context, text) : text;
}
