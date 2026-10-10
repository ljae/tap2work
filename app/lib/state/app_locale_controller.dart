import 'package:flutter/material.dart';
import '../data/locale_preference_store.dart';
import '../domain/locale_policy.dart';

class AppLocaleController extends ChangeNotifier {
  AppLocaleController({LocalePreferenceStore? store})
    : _store = store ?? DeviceLocalePreferenceStore();
  static final instance = AppLocaleController();
  final LocalePreferenceStore _store;
  String _languageTag = 'ko';
  String _accountKey = 'guest';
  String _guestLanguageTag = 'ko';
  int _generation = 0, _selection = 0;
  bool _disposed = false;
  Future<void>? _initialization;
  Future<void> _writes = Future.value();
  Future<void> Function(String tag)? _saveRemote;
  int? _pendingSelection;
  String? lastError;
  String get languageTag => _languageTag;
  String get accountKey => _accountKey;
  Locale get locale => _languageTag == 'zh-Hans'
      ? const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans')
      : Locale(_languageTag);

  Future<void> initialize() => _initialization ??= bindAccount(null);

  /// Call when the authenticated account changes; server preferences are
  /// adopted without creating a write. Refresh uses adoptServerLanguage.
  Future<void> bindAccount(
    String? accountKey, {
    String? serverLanguage,
    Future<void> Function(String tag)? saveRemote,
  }) async {
    final generation = ++_generation;
    final selection = _selection;
    _accountKey = accountKey ?? 'guest';
    _saveRemote = saveRemote;
    _pendingSelection = null;
    lastError = null;
    try {
      final saved = await _store.read(_accountKey);
      if (_disposed || generation != _generation || selection != _selection) {
        return;
      }
      final next = serverLanguage ?? saved ?? _guestLanguageTag;
      _apply(LocalePolicy.effectiveLanguage(next));
      if (_accountKey == 'guest') _guestLanguageTag = _languageTag;
    } catch (_) {
      if (!_disposed && generation == _generation) {
        lastError = 'language.localSaveFailed';
        notifyListeners();
      }
    }
  }

  void adoptServerLanguage(String? tag) {
    if (tag == null || _disposed || _pendingSelection != null) return;
    _apply(LocalePolicy.effectiveLanguage(tag));
  }

  void _apply(String tag) {
    if (_languageTag == tag || _disposed) return;
    _languageTag = tag;
    notifyListeners();
  }

  /// Changes UI immediately; serial persistence keeps rapid selections in
  /// order and pins remote writes to the authenticated account generation.
  Future<void> selectLanguage(String tag) {
    final normalized = LocalePolicy.effectiveLanguage(tag);
    final base = tag.replaceAll('_', '-').split('-').first.toLowerCase();
    if (!LocalePolicy.supportedLanguages.contains(
      base == 'zh' ? 'zh-Hans' : base,
    )) {
      throw ArgumentError.value(tag, 'tag', 'Unsupported app language');
    }
    final generation = _generation;
    final selection = ++_selection;
    _pendingSelection = selection;
    final accountKey = _accountKey;
    final remote = _saveRemote;
    lastError = null;
    _apply(normalized);
    if (accountKey == 'guest') _guestLanguageTag = normalized;
    _writes = _writes.catchError((Object _) {}).then((_) async {
      try {
        await _store.write(accountKey, normalized);
        if (!_disposed && generation == _generation) {
          await remote?.call(normalized);
        }
      } catch (_) {
        if (!_disposed &&
            generation == _generation &&
            selection == _selection) {
          lastError = 'language.localSaveFailed';
          notifyListeners();
        }
      } finally {
        if (!_disposed &&
            generation == _generation &&
            selection == _selection) {
          _pendingSelection = null;
        }
      }
    });
    return _writes;
  }

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    super.dispose();
  }
}

class AppLocaleScope extends InheritedNotifier<AppLocaleController> {
  const AppLocaleScope({
    super.key,
    required AppLocaleController controller,
    required super.child,
  }) : super(notifier: controller);
  static AppLocaleController controllerOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppLocaleScope>()?.notifier ??
      AppLocaleController.instance;
}
