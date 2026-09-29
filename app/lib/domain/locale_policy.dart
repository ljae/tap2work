/// Persist BCP-47 preferences separately from languages with shipped resources.
/// Only Korean is shipped now. Do not add a language picker before translations.
class LocalePolicy {
  static const supportedLanguages = {'ko'};
  static const fallbackLanguage = 'ko';
  static const defaultStoreTimeZone = 'Asia/Seoul';
  static String effectiveLanguage(String? preferred) {
    final language = preferred?.split('-').first.toLowerCase();
    return supportedLanguages.contains(language) ? language! : fallbackLanguage;
  }
}
