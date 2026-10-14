import 'service_messages.dart';
import 'manual_model_messages.dart';
import 'store_messages.dart';
import 'supplemental_messages.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../domain/locale_policy.dart';
import 'messages.dart';
import 'workflow_messages.dart';

const appSupportedLocales = [
  Locale('ko'),
  Locale('en'),
  Locale('vi'),
  Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
  Locale('ja'),
  Locale('th'),
  Locale('ne'),
  Locale('id'),
];
const appLanguageNames = {
  'ko': '한국어',
  'en': 'English',
  'vi': 'Tiếng Việt',
  'zh-Hans': '简体中文',
  'ja': '日本語',
  'th': 'ไทย',
  'ne': 'नेपाली',
  'id': 'Bahasa Indonesia',
};
// Representative flags are visual language cues, never crew nationality.
// Edit display names above and flag associations here for every language control.
const appLanguageCountries = {
  'ko': 'KR',
  'en': 'US',
  'vi': 'VN',
  'zh-Hans': 'CN',
  'ja': 'JP',
  'th': 'TH',
  'ne': 'NP',
  'id': 'ID',
};
const appFontFallbacks = [
  'NotoSansThai',
  'NotoSansDevanagari',
  'NotoSansSC',
  'NotoSansJP',
];

final _manualModelSourceKeys = {
  for (final entry in manualModelMessageRows.entries)
    entry.value.first: entry.key,
};

final _supplementalSourceKeys = {
  for (final entry in supplementalMessageRows.entries)
    entry.value.first: entry.key,
};

class AppStrings {
  AppStrings(String? tag) : languageTag = LocalePolicy.effectiveLanguage(tag);
  final String languageTag;
  static const delegate = _AppStringsDelegate();
  static AppStrings of(BuildContext context) =>
      Localizations.of<AppStrings>(context, AppStrings) ?? AppStrings('ko');
  String text(String key, [Map<String, Object?> params = const {}]) {
    final row =
        serviceMessageRows[key] ??
        manualModelMessageRows[key] ??
        manualModelMessageRows[_manualModelSourceKeys[key]] ??
        appMessageRows[key] ??
        workflowMessageRows[key] ??
        storeMessageRows[key] ??
        supplementalMessageRows[key] ??
        supplementalMessageRows[_supplementalSourceKeys[key]] ??
        storeMessageRows[storeMessageAliases[key]] ??
        appMessageRows[appMessageAliases[key]];
    final index = LocalePolicy.supportedLanguages.toList().indexOf(languageTag);
    var value = row == null ? key : row[index < 0 ? 0 : index];
    for (final entry in params.entries) {
      value = value.replaceAll('{${entry.key}}', '${entry.value}');
    }
    return value;
  }
}

extension AppTranslations on BuildContext {
  String t(String key, {Map<String, Object?> args = const {}}) =>
      AppStrings.of(this).text(key, args);
}

class _AppStringsDelegate extends LocalizationsDelegate<AppStrings> {
  const _AppStringsDelegate();
  @override
  bool isSupported(Locale locale) => LocalePolicy.supportedLanguages.contains(
    locale.languageCode == 'zh' ? 'zh-Hans' : locale.languageCode,
  );
  @override
  Future<AppStrings> load(Locale locale) =>
      SynchronousFuture(AppStrings(locale.toLanguageTag()));
  @override
  bool shouldReload(covariant LocalizationsDelegate<AppStrings> old) => false;
}

/// Localizes the server diagnosis without using a display label as a status code.
String localizedWorkStatus(BuildContext context, Map<String, dynamic>? status) {
  if (status?['code'] == 'scheduled') {
    return context.t(
      'workStatus.message16',
      args: {'p0': (status?['executionIds'] as List? ?? []).length},
    );
  }
  return context.t('${status?['label'] ?? '사용 방법을 확인해 주세요'}');
}
