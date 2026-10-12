import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:tap2work/l10n/entity_name_messages.dart';
import 'package:tap2work/l10n/entity_name_scope.dart';
import 'package:tap2work/l10n/app_localizations.dart';
import 'package:tap2work/state/operations_controller.dart';
import 'operations_test.dart' show response;
import 'checklist_test.dart' show fixture;
import 'manual_workspace_test.dart' show directoryData;
import 'package:tap2work/ui/manual_workspace.dart';
import 'package:tap2work/ui/manual_translation_editor.dart';
import 'dart:convert';

void main() {
  test('every built-in folder and part has all eight nonempty languages', () {
    for (final row in entityNameRows.entries) {
      expect(row.value.length, 8);
      expect(row.value.first, row.key);
      for (final value in row.value.skip(1)) {
        expect(value.trim(), isNotEmpty);
        expect(RegExp('[가-힣]').hasMatch(value), false, reason: row.key);
      }
    }
  });
  testWidgets(
    'display names use exact identity and source while IDs stay intact',
    (t) async {
      final state = fixture();
      state['manualContentTranslations'] = {
        'parts': {
          'custom': {
            'en': {
              'name': {
                'sourceText': '맞춤 파트',
                'text': 'Custom station',
                'current': true,
              },
            },
          },
        },
        'folders': {
          'custom': {
            'en': {
              'name': {
                'sourceText': '맞춤 폴더',
                'text': 'Custom folder',
                'current': true,
              },
            },
          },
        },
      };
      final ops = OperationsController(
        client: MockClient((_) async => response(state)),
      );
      addTearDown(ops.dispose);
      await ops.refresh();
      await t.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              expect(
                entityDisplayName(
                  context,
                  ops,
                  'part',
                  'custom',
                  '맞춤 파트',
                  locale: 'en',
                ),
                'Custom station',
              );
              expect(
                entityDisplayName(
                  context,
                  ops,
                  'folder',
                  'custom',
                  '맞춤 폴더',
                  locale: 'en',
                ),
                'Custom folder',
              );
              expect(
                entityDisplayName(
                  context,
                  ops,
                  'part',
                  'other',
                  '맞춤 파트',
                  locale: 'en',
                ),
                '맞춤 파트',
              );
              expect(
                entityDisplayName(
                  context,
                  ops,
                  'part',
                  'custom',
                  '새 파트',
                  locale: 'en',
                ),
                '새 파트',
              );
              expect(
                entityDisplayName(
                  context,
                  ops,
                  'part',
                  'custom',
                  '맞춤 파트',
                  locale: 'ko',
                ),
                '맞춤 파트',
              );
              for (final language in appLanguageNames.keys) {
                final index = appLanguageNames.keys.toList().indexOf(language);
                expect(
                  entityDisplayName(
                    context,
                    ops,
                    'part',
                    'kitchen',
                    '주방',
                    locale: language,
                  ),
                  entityNameRows['주방']![index],
                );
              }
              return const SizedBox();
            },
          ),
        ),
      );
      expect(
        state['manualContentTranslations']['parts']['custom']['en']['name']['sourceText'],
        '맞춤 파트',
      );
    },
  );
  testWidgets(
    'translated folder tree opens rename with original and saves exact ID',
    (t) async {
      t.view.physicalSize = const Size(1200, 900);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      final state = directoryData();
      state['checklistFolders'][0]['name'] = '주문처리';
      Map<String, dynamic>? sent;
      final ops = OperationsController(
        client: MockClient((r) async {
          if (r.method == 'POST') sent = jsonDecode(r.body);
          return response(state);
        }),
      );
      addTearDown(ops.dispose);
      await ops.refresh();
      await t.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: child!,
          ),
          localizationsDelegates: const [AppStrings.delegate],
          home: Scaffold(
            body: ManualWorkspace(ops: ops, query: ''),
          ),
        ),
      );
      await t.pumpAndSettle();
      expect(find.text('Order handling'), findsOneWidget);
      final name = find.byKey(const ValueKey('manual-rename-group:general'));
      await t.longPress(name);
      await t.pumpAndSettle();
      await t.tap(name);
      await t.pumpAndSettle();
      final input = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextField),
      );
      expect(t.widget<TextField>(input).controller!.text, '주문처리');
      await t.enterText(input, '새 원문');
      await t.tap(find.text(AppStrings('en').text('저장')));
      await t.pumpAndSettle();
      expect(sent?['id'], 'general');
      expect(sent?['kind'], 'group');
      expect(sent?['name'], '새 원문');
      expect(t.takeException(), isNull);
    },
  );
  testWidgets(
    'part name translation editor pins name source, identity and opening revision',
    (t) async {
      final state = fixture();
      Map<String, dynamic>? sent;
      final ops = OperationsController(
        client: MockClient((r) async {
          if (r.method == 'POST') sent = jsonDecode(r.body);
          return response(state);
        }),
      );
      addTearDown(ops.dispose);
      await ops.refresh();
      await t.pumpWidget(
        MaterialApp(
          home: ManualTranslationEditor(
            ops: ops,
            kind: 'part',
            entityId: 'kitchen',
            locale: 'en',
            source: const {'name': '주방'},
            initial: const {'name': 'Kitchen'},
          ),
        ),
      );
      await t.pumpAndSettle();
      await t.enterText(find.byType(TextField).first, 'Kitchen station');
      await t.tap(find.text(AppStrings('ko').text('common.save')));
      await t.pumpAndSettle();
      expect(sent?['source'], {'kind': 'part', 'id': 'kitchen'});
      expect(sent?['fields'], [
        {'field': 'name', 'sourceText': '주방', 'text': 'Kitchen station'},
      ]);
      expect(sent?['revision'], state['revision']);
    },
  );
}
