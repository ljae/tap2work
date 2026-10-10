import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:tap2work/domain/manual_translation_import.dart';
import 'package:tap2work/state/operations_controller.dart';
import 'package:tap2work/ui/manual_translation_editor.dart';
import 'operations_test.dart' show response;

void main() {
  const source = {'title': '접시 확인', 'manual': '잔반을 먼저 버려요'};
  final fields = [
    {
      'stepId': 'step-a',
      'field': 'title',
      'sourceText': source['title'],
      'text': 'Check plates',
    },
    {
      'stepId': 'step-a',
      'field': 'manual',
      'sourceText': source['manual'],
      'text': 'Discard leftovers first',
    },
  ];
  Map<String, String> parse(List<Object?> values, {String locale = 'en'}) =>
      parseManualTranslationImport(
        jsonEncode({'locale': locale, 'fields': values}),
        locale: 'en',
        source: source,
        stepId: 'step-a',
      );
  test('import accepts exact source and enforces field limits', () {
    expect(parse(fields), {
      'title': 'Check plates',
      'manual': 'Discard leftovers first',
    });
    expect(
      () => parse([
        {...fields[0], 'text': 'x' * 361},
      ]),
      throwsFormatException,
    );
  });
  test(
    'import rejects wrong language, source, step and duplicate before returning any draft',
    () {
      expect(() => parse(fields, locale: 'vi'), throwsFormatException);
      for (final invalid in [
        {...fields[1], 'sourceText': 'old source'},
        {...fields[1], 'stepId': 'another-step'},
        {...fields[1], 'field': 'photoUrl'},
        {...fields[0]},
      ]) {
        expect(() => parse([fields[0], invalid]), throwsFormatException);
      }
    },
  );
  testWidgets('save pins opening revision despite refreshed snapshot', (
    tester,
  ) async {
    Json? sent;
    final data = <String, dynamic>{
      'workspaceId': 'a',
      'revision': 10,
      'actor': {'id': 'owner', 'role': 'owner'},
    };
    final ops = OperationsController(
      accessToken: () async => 'test',
      client: MockClient((request) async {
        if (request.method == 'POST') sent = jsonDecode(request.body) as Json;
        return response(data);
      }),
    );
    addTearDown(ops.dispose);
    ops.data = data;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => ManualTranslationEditor(
                    ops: ops,
                    kind: 'manual',
                    entityId: 'manual-a',
                    stepId: 'step-a',
                    locale: 'en',
                    source: source,
                    initial: const {},
                  ),
                ),
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    ops.data = {...data, 'revision': 11};
    await tester.enterText(find.byType(TextField).first, 'Check plates');
    await tester.pump();
    await tester.tap(find.text('저장'));
    await tester.pumpAndSettle();
    expect(sent?['revision'], 10);
    expect(sent?['source'], {'kind': 'manual', 'id': 'manual-a'});
    expect(sent?['fields'], [
      {...fields[0]},
    ]);
  });
}
