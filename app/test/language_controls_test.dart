import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:tap2work/main.dart';
import 'package:tap2work/l10n/app_localizations.dart';
import 'package:tap2work/state/app_locale_controller.dart';
import 'package:tap2work/state/operations_controller.dart';
import 'package:tap2work/state/work_controller.dart';
import 'package:tap2work/ui/country_flag.dart';
import 'operations_test.dart' show sample, response;
import 'app_locale_test.dart' show MemoryLocales;
import 'work_controller_test.dart' show MemoryStore;

void main() {
  test('all selectable nationalities have bundled offline PNG flags', () {
    final source = File('../developer/countries.mjs').readAsStringSync();
    final codes = RegExp(
      "nationalityCodes = '([^']+)'",
    ).firstMatch(source)!.group(1)!.split(' ');
    expect(codes.length, 249);
    for (final code in codes) {
      final bytes = File('assets/flags/$code.png').readAsBytesSync();
      expect(bytes.take(8), [137, 80, 78, 71, 13, 10, 26, 10], reason: code);
    }
  });

  for (final tag in appLanguageNames.keys) {
    testWidgets('header switches to $tag at 320px and 1.5x text', (t) async {
      t.view.physicalSize = const Size(320, 1000);
      t.view.devicePixelRatio = 1;
      t.platformDispatcher.textScaleFactorTestValue = 1.5;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
      final store = MemoryLocales();
      final locale = AppLocaleController(store: store);
      final ops = OperationsController(
        endpoint: Uri.parse(
          'https://example.supabase.co/functions/v1/operations',
        ),
        accessToken: () async => 'session',
        client: MockClient((_) async => response(sample())),
      );
      final work = WorkController(MemoryStore());
      addTearDown(locale.dispose);
      addTearDown(ops.dispose);
      addTearDown(work.dispose);
      await ops.refresh();
      await t.pumpWidget(
        Tap2workApp(
          controller: work,
          operations: ops,
          localeController: locale,
        ),
      );
      await t.pumpAndSettle();
      final button = find.byKey(const ValueKey('header-language-button'));
      expect(t.getSize(button).width, greaterThanOrEqualTo(48));
      await t.tap(button);
      await t.pumpAndSettle();
      final option = find.byKey(ValueKey('app-language-$tag'));
      await t.ensureVisible(option);
      await t.tap(option);
      await t.pumpAndSettle();
      expect(locale.languageTag, tag);
      expect(store.values.values, contains(tag));
      expect(find.byKey(ValueKey('app-language-$tag')), findsNothing);
      final flag = t.widget<CountryFlag>(
        find.descendant(of: button, matching: find.byType(CountryFlag)),
      );
      expect(flag.countryCode, appLanguageCountries[tag]);
      expect(
        find.byTooltip(
          '${AppStrings(tag).text('language.title')} · ${appLanguageNames[tag]}',
        ),
        findsOneWidget,
      );
      final search = t.widget<TextField>(
        find.byKey(const ValueKey('global-manual-search')),
      );
      expect(
        search.decoration!.hintText,
        AppStrings(tag).text('manual.search'),
      );
      expect(t.takeException(), isNull);
    });
  }
}
