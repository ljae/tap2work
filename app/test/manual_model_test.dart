import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:tap2work/l10n/app_localizations.dart';
import 'package:tap2work/l10n/manual_model_messages.dart';
import 'package:tap2work/domain/manual_categories.dart';
import 'package:tap2work/ui/manual_example_screen.dart';
import 'package:tap2work/ui/manual_hierarchy.dart';
import 'package:tap2work/state/operations_controller.dart';

Json catalog() =>
    jsonDecode(File('../docs/market/current.json').readAsStringSync());
void main() {
  test('every model phrase has all languages and matching placeholders', () {
    for (final entry in manualModelMessageRows.entries) {
      expect(entry.value.length, 8, reason: entry.key);
      List<String> tokens(String value) =>
          RegExp(r'\{[^}]+\}').allMatches(value).map((m) => m[0]!).toList()
            ..sort();
      for (final text in entry.value) {
        expect(text.trim(), isNotEmpty);
        expect(tokens(text), tokens(entry.value.first));
      }
    }
  });
  test(
    'private overrides and public categories agree; menu identity remains recipe',
    () {
      expect(
        manualCategoryOf({
          'manualCategoryOverride': 'periodic',
          'knowledge': {'useCase': 'routine'},
        }),
        'periodic',
      );
      expect(
        manualCategoryOf({
          'menuManualId': 'menu',
          'manualCategoryOverride': 'routine',
        }),
        'recipe',
      );
      expect(manualCategoryOf({'manualCategory': 'startup'}), 'startup');
      expect(
        manualCategoryOf({
          'collectionId': 'business',
          'knowledge': {'suggestedUse': 'routine'},
        }),
        'routine',
      );
    },
  );
  for (final width in [320.0, 390.0, 1200.0]) {
    testWidgets(
      'fictional detail, policy and local basket at $width with reduced motion',
      (t) async {
        t.view.physicalSize = Size(width, 1000);
        t.view.devicePixelRatio = 1;
        addTearDown(t.view.resetPhysicalSize);
        addTearDown(t.view.resetDevicePixelRatio);
        final data = catalog();
        await t.pumpWidget(
          MaterialApp(
            theme: ThemeData.dark(),
            home: MediaQuery(
              data: MediaQueryData(
                size: Size(width, 1000),
                textScaler: const TextScaler.linear(1.5),
                disableAnimations: true,
              ),
              child: ManualExampleScreen(
                profile: data['taxonomy']['exampleStores'][0],
                entries: (data['entries'] as List).cast<Json>(),
              ),
            ),
          ),
        );
        await t.pumpAndSettle();
        expect(find.byType(ManualHierarchyPath), findsOneWidget);
        expect(find.textContaining('26 TAP'), findsOneWidget);
        final folder = find.text('운영 기준 잡기');
        await t.scrollUntilVisible(
          folder,
          160,
          scrollable: find.byType(Scrollable).last,
          maxScrolls: 30,
        );
        await t.pumpAndSettle();
        await t.tap(folder);
        await t.pumpAndSettle();
        final tap = find.text('매장 운영 시간·파트·할 일 연결 기준');
        await t.scrollUntilVisible(
          tap,
          160,
          scrollable: find.byType(Scrollable).last,
          maxScrolls: 30,
        );
        await t.pumpAndSettle();
        await t.tap(tap);
        await t.pumpAndSettle();
        final action = find.text('영업·브레이크와 준비 시간을 구별');
        await t.scrollUntilVisible(
          action,
          160,
          scrollable: find.byType(Scrollable).last,
          maxScrolls: 30,
        );
        await t.pumpAndSettle();
        await t.tap(action);
        await t.pumpAndSettle();
        await t.scrollUntilVisible(
          find.textContaining('09:30'),
          160,
          scrollable: find.byType(Scrollable).last,
          maxScrolls: 30,
        );
        await t.pumpAndSettle();
        expect(find.textContaining('09:30'), findsWidgets);
        expect(find.text('실제로 한 뒤 확인하는 행동'), findsNothing);
        expect(t.takeException(), isNull);
      },
    );
  }
  for (final language in appLanguageNames.keys) {
    testWidgets('category and reference hierarchy in $language', (t) async {
      await t.pumpWidget(
        MaterialApp(
          locale:
              appSupportedLocales[appLanguageNames.keys.toList().indexOf(
                language,
              )],
          supportedLocales: appSupportedLocales,
          localizationsDelegates: const [
            AppStrings.delegate,
            ...GlobalMaterialLocalizations.delegates,
          ],
          home: Scaffold(
            body: Column(
              children: [
                ManualCategoryPicker(selected: 'recipe', onSelected: (_) {}),
                const ManualHierarchyPath(
                  reference: true,
                  folder: 'Folder',
                  tap: 'TAP',
                  task: 'Section',
                ),
              ],
            ),
          ),
        ),
      );
      await t.pumpAndSettle();
      expect(
        find.text(AppStrings(language).text('manual.category.recipe')),
        findsOneWidget,
      );
      expect(
        find.text(AppStrings(language).text('manual.structure.section')),
        findsOneWidget,
      );
      expect(t.takeException(), isNull);
    });
  }
}
