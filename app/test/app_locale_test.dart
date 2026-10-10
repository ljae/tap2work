import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tap2work/data/locale_preference_store.dart';
import 'package:tap2work/domain/locale_policy.dart';
import 'package:tap2work/l10n/app_localizations.dart';
import 'package:tap2work/l10n/messages.dart';
import 'package:tap2work/l10n/workflow_messages.dart';
import 'package:tap2work/main.dart';
import 'package:tap2work/state/app_locale_controller.dart';
import 'package:tap2work/state/work_controller.dart';
import 'package:tap2work/ui/app_language_picker.dart';
import 'package:tap2work/ui/login_screen.dart';
import 'work_controller_test.dart' show MemoryStore;

class MemoryLocales implements LocalePreferenceStore {
  final values = <String, String>{};
  Completer<String?>? readGate;
  @override
  Future<String?> read(String accountKey) async =>
      readGate?.future ?? values[accountKey];
  @override
  Future<void> write(String accountKey, String languageTag) async =>
      values[accountKey] = languageTag;
}

void main() {
  testWidgets('missing app delegate keeps the existing Korean UI fallback', (
    t,
  ) async {
    await t.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        home: Builder(builder: (context) => Text(context.t('nav.work'))),
      ),
    );
    expect(find.text('업무'), findsOneWidget);
  });
  test(
    'all resources cover exactly the eight languages with matching placeholders',
    () {
      expect(LocalePolicy.supportedLanguages, {
        'ko',
        'en',
        'vi',
        'zh-Hans',
        'ja',
        'th',
        'ne',
        'id',
      });
      for (final entry in {...appMessageRows, ...workflowMessageRows}.entries) {
        expect(entry.value.length, 8, reason: entry.key);
        final expected = RegExp(
          r'\{\w+\}',
        ).allMatches(entry.value.first).map((m) => m.group(0)).toSet();
        for (final value in entry.value) {
          expect(value.trim(), isNotEmpty, reason: entry.key);
          expect(
            RegExp(r'\{\w+\}').allMatches(value).map((m) => m.group(0)).toSet(),
            expected,
            reason: entry.key,
          );
        }
      }
      expect(
        AppStrings('en').text('manual.progress', {'done': 2, 'total': 4}),
        '2/4 completed',
      );
      expect(LocalePolicy.effectiveLanguage('zh_CN'), 'zh-Hans');
      expect(LocalePolicy.effectiveLanguage('EN-US'), 'en');
      expect(LocalePolicy.effectiveLanguage('fr'), 'ko');
    },
  );

  test(
    'rapid selections are immediate and earlier remote responses cannot override latest',
    () async {
      final store = MemoryLocales();
      final controller = AppLocaleController(store: store);
      addTearDown(controller.dispose);
      final firstWrite = Completer<void>();
      final remote = <String>[];
      await controller.bindAccount(
        'account-a',
        serverLanguage: 'ko',
        saveRemote: (tag) async {
          remote.add(tag);
          if (tag == 'en') await firstWrite.future;
        },
      );
      final first = controller.selectLanguage('en');
      await pumpEventQueue();
      final latest = controller.selectLanguage('vi');
      expect(controller.languageTag, 'vi');
      controller.adoptServerLanguage('en');
      expect(controller.languageTag, 'vi');
      firstWrite.complete();
      await first;
      await latest;
      expect(remote, ['en', 'vi']);
      expect(store.values['account-a'], 'vi');
      controller.adoptServerLanguage('id');
      expect(controller.languageTag, 'id');
    },
  );

  test(
    'account preferences are isolated and late reads never replace a user selection',
    () async {
      final store = MemoryLocales()..values['account-a'] = 'th';
      final controller = AppLocaleController(store: store);
      addTearDown(controller.dispose);
      await controller.initialize();
      await controller.selectLanguage('en');
      await controller.bindAccount('account-a');
      expect(controller.languageTag, 'th');
      await controller.bindAccount('account-b');
      expect(controller.languageTag, 'en'); // Guest preference, not account-a.
      final gate = Completer<String?>();
      store.readGate = gate;
      final binding = controller.bindAccount('account-c');
      await controller.selectLanguage('ne');
      gate.complete('ja');
      await binding;
      expect(controller.languageTag, 'ne');
      expect(store.values['account-c'], 'ne');
      expect(() => controller.selectLanguage('fr'), throwsArgumentError);
    },
  );

  test(
    'old account queued remote write does not run after account switch',
    () async {
      final controller = AppLocaleController(store: MemoryLocales());
      addTearDown(controller.dispose);
      var oldWrites = 0;
      await controller.bindAccount('old', saveRemote: (_) async => oldWrites++);
      final writing = controller.selectLanguage('ja');
      await controller.bindAccount('new', serverLanguage: 'id');
      await writing;
      expect(oldWrites, 0);
      expect(controller.languageTag, 'id');
    },
  );

  for (final language in LocalePolicy.supportedLanguages) {
    testWidgets(
      'login and Material delegates render $language at 320px with enlarged text',
      (t) async {
        t.view.physicalSize = const Size(320, 1100);
        t.view.devicePixelRatio = 1;
        addTearDown(t.view.resetPhysicalSize);
        addTearDown(t.view.resetDevicePixelRatio);
        t.platformDispatcher.textScaleFactorTestValue = 1.5;
        addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
        final locale = AppLocaleController(store: MemoryLocales());
        addTearDown(locale.dispose);
        await locale.selectLanguage(language);
        final work = WorkController(MemoryStore());
        addTearDown(work.dispose);
        await t.pumpWidget(
          Tap2workApp(
            controller: work,
            localeController: locale,
            homeOverride: LoginScreen(
              signInButtons: const Text('Google / Apple'),
              onPrivacy: () {},
              onPreview: () {},
            ),
          ),
        );
        await t.pumpAndSettle();
        expect(
          find.text(AppStrings(language).text('login.enterStore')),
          findsOneWidget,
        );
        expect(find.text(appLanguageNames[language]!), findsOneWidget);
        final context = t.element(find.byType(LoginScreen));
        expect(AppStrings.of(context).languageTag, language);
        expect(MaterialLocalizations.of(context).cancelButtonLabel, isNotEmpty);
        expect(t.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'picker changes login language immediately and persists without login',
    (t) async {
      final store = MemoryLocales();
      final locale = AppLocaleController(store: store);
      addTearDown(locale.dispose);
      final work = WorkController(MemoryStore());
      addTearDown(work.dispose);
      await t.pumpWidget(
        Tap2workApp(
          controller: work,
          localeController: locale,
          homeOverride: LoginScreen(
            signInButtons: const Text('Google / Apple'),
            onPrivacy: () {},
            onPreview: () {},
          ),
        ),
      );
      await t.pumpAndSettle();
      await t.ensureVisible(find.byType(AppLanguageButton));
      await t.tap(find.byType(AppLanguageButton));
      await t.pumpAndSettle();
      await t.ensureVisible(find.text('Tiếng Việt').last);
      await t.tap(find.text('Tiếng Việt').last);
      await t.pumpAndSettle();
      expect(locale.languageTag, 'vi');
      expect(store.values['guest'], 'vi');
      expect(find.text('Vào cửa hàng'), findsOneWidget);
      expect(t.takeException(), isNull);
    },
  );
}
