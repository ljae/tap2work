import 'package:shared_preferences/shared_preferences.dart';

abstract interface class LocalePreferenceStore {
  Future<String?> read(String accountKey);
  Future<void> write(String accountKey, String languageTag);
}

class DeviceLocalePreferenceStore implements LocalePreferenceStore {
  String key(String accountKey) => 'tap2work.language:$accountKey';
  @override
  Future<String?> read(String accountKey) async =>
      (await SharedPreferences.getInstance()).getString(key(accountKey));
  @override
  Future<void> write(String accountKey, String languageTag) async {
    if (!await (await SharedPreferences.getInstance()).setString(
      key(accountKey),
      languageTag,
    )) {
      throw StateError('Language preference could not be saved.');
    }
  }
}
