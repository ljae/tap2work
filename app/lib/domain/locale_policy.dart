/// App chrome resources are shipped for these languages. Store-authored text
/// uses a separate versioned translation service and original-content toggle.
class LocalePolicy {
  static const supportedLanguages = {
    'ko',
    'en',
    'vi',
    'zh-Hans',
    'ja',
    'th',
    'ne',
    'id',
  };
  static const fallbackLanguage = 'ko';
  static const defaultStoreTimeZone = 'Asia/Seoul';
  static String effectiveLanguage(String? preferred) {
    final language = preferred
        ?.replaceAll('_', '-')
        .split('-')
        .first
        .toLowerCase();
    final tag = language == 'zh' ? 'zh-Hans' : language;
    return supportedLanguages.contains(tag) ? tag! : fallbackLanguage;
  }
}
