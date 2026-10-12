import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:tap2work/l10n/app_localizations.dart';
import 'package:tap2work/l10n/supplemental_messages.dart';
import 'package:tap2work/main.dart';
import 'package:tap2work/data/bundled_manual_translations.dart';
import 'package:tap2work/state/app_locale_controller.dart';
import 'package:tap2work/state/operations_controller.dart';
import 'package:tap2work/state/work_controller.dart';
import 'package:tap2work/ui/owner_workflow_screen.dart';
import 'package:tap2work/ui/tap_settings_screen.dart';
import 'app_locale_test.dart' show MemoryLocales;
import 'work_controller_test.dart' show MemoryStore;
import 'owner_workflow_test.dart' as owner;
import 'operations_test.dart' show response;

List<String> placeholders(String text) =>
    RegExp(r'\{p\d+\}').allMatches(text).map((m) => m[0]!).toList()..sort();

void main() {
  test(
    'supplemental UI has eight languages and preserves every placeholder',
    () {
      for (final entry in supplementalMessageRows.entries) {
        expect(entry.value.length, 8, reason: entry.key);
        final expected = placeholders(entry.value.first);
        for (final text in entry.value) {
          expect(text.trim(), isNotEmpty, reason: entry.key);
          expect(placeholders(text), expected, reason: entry.key);
        }
        for (final text in entry.value.skip(1)) {
          expect(RegExp('[가-힣]').hasMatch(text), false, reason: entry.key);
        }
      }
      for (final file in Directory('lib/ui').listSync().whereType<File>()) {
        if (!file.path.endsWith('.dart')) continue;
        for (final match in RegExp(
          r"context\.t\('(ui\.audit\d+)'",
        ).allMatches(file.readAsStringSync())) {
          expect(
            supplementalMessageRows.containsKey(match[1]),
            true,
            reason: '${file.path}: ${match[1]}',
          );
        }
      }
    },
  );

  test('raw enum lookup preserves source labels and unknown store text', () {
    expect(AppStrings('en').text('월'), 'Mon');
    expect(AppStrings('ko').text('월'), '월');
    expect(AppStrings('en').text('가상매장 사용자 작성 이름'), '가상매장 사용자 작성 이름');
  });

  test(
    'reviewed terminology distinguishes requests, deliveries and time bands',
    () {
      expect(AppStrings('en').text('반려'), 'Rejected');
      expect(AppStrings('zh-Hans').text('반려'), '已驳回');
      expect(AppStrings('en').text('입고'), 'Goods receipt');
      expect(AppStrings('en').text('시간대'), 'time band');
      for (final row in supplementalMessageRows.values) {
        expect(
          RegExp(r'(?:[A-Za-z]{3,}[ ,]+){3}[A-Za-z]{3,}').hasMatch(row[5]),
          false,
          reason: 'English prose left in Thai: ${row.first}',
        );
      }
    },
  );

  for (final language in appLanguageNames.keys) {
    testWidgets('owner review and future settings in $language at 320px', (
      t,
    ) async {
      t.view.physicalSize = const Size(320, 1000);
      t.view.devicePixelRatio = 1;
      t.platformDispatcher.textScaleFactorTestValue = 1.5;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
      final locale = AppLocaleController(store: MemoryLocales());
      await locale.selectLanguage(language);
      final work = WorkController(MemoryStore());
      final state = owner.data();
      final starter =
          jsonDecode(
                File(
                  '../developer/owner_starter_content.json',
                ).readAsStringSync(),
              )
              as Map<String, dynamic>;
      final candidate = Map<String, dynamic>.from(
        (starter['entries'] as List).first as Map,
      );
      state['ownerWorkflow']['assumption'] = starter['assumption'];
      state['ownerWorkflow']['candidates'] = [candidate];
      var writes = 0;
      final ops = OperationsController(
        client: MockClient((r) async {
          if (r.method == 'POST') writes++;
          return response(state);
        }),
      );
      addTearDown(locale.dispose);
      addTearDown(work.dispose);
      addTearDown(ops.dispose);
      await ops.refresh();
      await t.runAsync(() => BundledManualTranslations.load(language));
      Future<void> mount(Widget screen) async {
        await t.pumpWidget(
          Tap2workApp(
            controller: work,
            localeController: locale,
            homeOverride: screen,
          ),
        );
        await t.runAsync(() async {
          await BundledManualTranslations.load(language);
          await Future<void>.delayed(Duration.zero);
        });
        await t.pumpAndSettle();
      }

      await mount(OwnerWorkflowScreen(ops: ops));
      final strings = AppStrings(language);
      expect(find.text(strings.text('사장님의 운영 준비')), findsOneWidget);
      final dictionary = language == 'ko'
          ? <String, dynamic>{}
          : (jsonDecode(
                      File(
                        'assets/manual_translations/$language.json',
                      ).readAsStringSync(),
                    )
                    as Map<String, dynamic>)['translations']
                as Map<String, dynamic>;
      final title =
          dictionary[candidate['title']] as String? ??
          candidate['title'] as String;
      for (
        var scroll = 0;
        scroll < 20 && find.text(title).hitTestable().evaluate().isEmpty;
        scroll++
      ) {
        await t.drag(find.byType(ListView).first, const Offset(0, -200));
        await t.runAsync(() async {
          await BundledManualTranslations.load(language);
          await Future<void>.delayed(Duration.zero);
        });
        await t.pumpAndSettle();
      }
      expect(find.text(title), findsOneWidget);
      await t.tap(find.text(title));
      await t.pumpAndSettle();
      expect(find.text(strings.text('내용을 검토했어요 · 선택')), findsOneWidget);
      expect(writes, 0);
      expect(t.takeException(), isNull);
      // Close review and mount the existing settings contract in the same language.
      await t.tap(find.text(strings.text('내용을 검토했어요 · 선택')));
      await t.pumpAndSettle();
      await mount(
        TapSettingsScreen(
          ops: ops,
          initialTemplateId: state['taskTemplates'][0]['id'],
          effectiveFrom: '2026-10-12',
        ),
      );
      expect(find.text(strings.text('내일부터 반복 업무 변경')), findsOneWidget);
      expect(writes, 0);
      expect(t.takeException(), isNull);
    });
  }
}
