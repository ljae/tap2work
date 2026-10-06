import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:tap2work/state/operations_controller.dart';
import 'package:tap2work/ui/manual_tap_editor.dart';
import 'package:tap2work/ui/checklist_editor.dart';
import 'manual_workspace_test.dart' show mount, click, directoryData;
import 'operations_test.dart' show response;

void main() {
  for (final width in [320.0, 390.0]) {
    for (final kind in ['group', 'tap', 'task']) {
      testWidgets('$kind authoring menu is complete on $width phone', (
        tester,
      ) async {
        final data = directoryData();
        final ops = OperationsController(
          client: MockClient((_) async => response(data)),
        );
        addTearDown(ops.dispose);
        await mount(tester, ops, width: width);
        await tester.longPress(
          find.byKey(const ValueKey('manual-node-group:general')),
        );
        await tester.pumpAndSettle();
        if (kind == 'task') await click(tester, 'manual-node-tap:a');
        final key = kind == 'group'
            ? 'group:general'
            : kind == 'tap'
            ? 'tap:a'
            : 'task:s1:a';
        await click(tester, 'manual-actions-$key');
        expect(find.text('이름 변경'), findsOneWidget);
        expect(find.text('위치 이동'), findsOneWidget);
        if (kind != 'group') expect(find.text('삭제'), findsOneWidget);
        if (kind == 'group') {
          await tester.tap(find.text('TAP 추가'));
          await tester.pumpAndSettle();
          expect(find.byType(ManualTapEditor), findsOneWidget);
          expect(
            tester
                .widget<ManualTapEditor>(find.byType(ManualTapEditor))
                .folderId,
            'general',
          );
        } else {
          await tester.tap(find.text('상세 수정'));
          await tester.pumpAndSettle();
          expect(
            find.byType(kind == 'tap' ? ManualTapEditor : ManualTaskEditor),
            findsOneWidget,
          );
        }
        expect(tester.takeException(), isNull);
      });
    }
  }
  testWidgets('configured store exposes empty folders while authoring', (
    tester,
  ) async {
    final data = directoryData()
      ..['manualBusinessProfile'] = {'industryId': 'food'};
    data['checklistFolders'].add({'id': 'empty', 'name': '새 폴더'});
    final ops = OperationsController(
      client: MockClient((_) async => response(data)),
    );
    addTearDown(ops.dispose);
    await mount(tester, ops, width: 320);
    expect(find.byKey(const ValueKey('manual-node-group:empty')), findsNothing);
    await tester.longPress(
      find.byKey(const ValueKey('manual-node-group:general')),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('manual-node-group:empty')),
      findsOneWidget,
    );
    await click(tester, 'manual-actions-group:empty');
    expect(find.text('TAP 추가'), findsOneWidget);
    expect(find.text('삭제'), findsOneWidget);
  });
  testWidgets(
    'phone adds full Task content to the selected TAP with revision',
    (tester) async {
      final data = directoryData();
      data['taskTemplates'][0]['emoji'] = '📋';
      Json? posted;
      final ops = OperationsController(
        client: MockClient((r) async {
          if (r.method == 'POST') posted = jsonDecode(r.body) as Json;
          return response(data);
        }),
      );
      addTearDown(ops.dispose);
      await mount(tester, ops, width: 320);
      await tester.longPress(
        find.byKey(const ValueKey('manual-node-group:general')),
      );
      await tester.pumpAndSettle();
      await click(tester, 'manual-actions-tap:a');
      await tester.tap(find.text('Task 추가'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Task 이름'),
        '마무리 확인',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, '간단 매뉴얼 · 방법과 완료 기준'),
        '작업대와 도구를 확인해요.',
      );
      final apply = find.text('초안에 적용');
      await tester.ensureVisible(apply);
      await tester.tap(apply);
      await tester.pumpAndSettle();
      final save = find.widgetWithText(FilledButton, '매뉴얼 저장');
      await tester.ensureVisible(save);
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(
        posted?['action'],
        'save_manual_tap',
        reason: tester
            .widgetList<Text>(find.byType(Text))
            .map((t) => t.data)
            .join(' | '),
      );
      expect(posted?['templateId'], 'a');
      expect(posted?['revision'], 2);
      expect((posted?['steps'] as List).last['title'], '마무리 확인');
      expect((posted?['steps'] as List).last['manual'], '작업대와 도구를 확인해요.');
      expect(data['taskTemplates'][0]['steps'], hasLength(2));
      expect(tester.takeException(), isNull);
    },
  );
}
