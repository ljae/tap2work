import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:tap2work/state/operations_controller.dart';
import 'package:tap2work/ui/tap_card.dart';
import 'package:tap2work/ui/task_step_editor.dart';
import 'checklist_test.dart' show fixture;
import 'operations_test.dart' show response;
import 'tap_workspace_test.dart' show mountBoard, openCard;

void main() {
  for (final width in [320.0, 390.0, 1200.0]) {
    testWidgets(
      'inline edit and append are focused, isolated and preview-only at $width',
      (tester) async {
        var posts = 0;
        final ops = OperationsController(
          readOnly: true,
          client: MockClient((r) async {
            if (r.method == 'POST') posts++;
            return response(fixture());
          }),
        );
        addTearDown(ops.dispose);
        await mountBoard(tester, ops, width: width);
        expect(find.text('보드 편집'), findsOneWidget);
        expect(find.text('TAP 설정'), findsNothing);
        await openCard(tester, 'tap-daily-prep');
        expect(find.text('TAP 편집'), findsOneWidget);
        expect(find.text('보드 편집'), findsNothing);
        final last = find.byKey(const ValueKey('small-s2'));
        final add = find.byKey(const ValueKey('add-task-step'));
        expect(
          tester.getTopLeft(add).dy,
          greaterThan(tester.getBottomLeft(last).dy),
        );
        final originalSibling = jsonEncode(
          (ops.rows('tasks').first['steps'] as List)[1],
        );
        await tester.tap(find.text('도구 나누기'));
        await tester.pumpAndSettle();
        expect(find.byType(TaskStepEditor), findsOneWidget);
        final editable = find.descendant(
          of: find.byKey(const ValueKey('task-step-title')),
          matching: find.byType(EditableText),
        );
        expect(tester.widget<EditableText>(editable).focusNode.hasFocus, true);
        await tester.enterText(
          find.byKey(const ValueKey('task-step-title')),
          '도구 분리 확인',
        );
        final save = find.widgetWithText(FilledButton, '저장');
        await tester.ensureVisible(save);
        await tester.tap(save);
        await tester.pumpAndSettle();
        expect(
          (ops.rows('tasks').first['steps'] as List).first['title'],
          '도구 분리 확인',
        );
        expect(
          (ops.rows('taskTemplates').first['steps'] as List).first['title'],
          '도구 분리 확인',
        );
        expect(
          jsonEncode((ops.rows('tasks').first['steps'] as List)[1]),
          originalSibling,
        );
        await tester.ensureVisible(add);
        await tester.tap(add);
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(const ValueKey('task-step-title')),
          '마지막 확인',
        );
        await tester.enterText(
          find.byKey(const ValueKey('task-step-manual')),
          '도구가 제자리에 있는지 확인해요.',
        );
        await tester.ensureVisible(save);
        await tester.tap(save);
        await tester.pumpAndSettle();
        expect(
          (ops.rows('tasks').first['steps'] as List).last['title'],
          '마지막 확인',
        );
        expect(
          (ops.rows('taskTemplates').first['steps'] as List).last['title'],
          '마지막 확인',
        );
        expect(posts, 0);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('large text and keyboard leave inline editor scrollable', (
    tester,
  ) async {
    final ops = OperationsController(
      readOnly: true,
      client: MockClient((_) async => response(fixture())),
    );
    addTearDown(ops.dispose);
    addTearDown(tester.view.resetViewInsets);
    await mountBoard(tester, ops, width: 320, textScale: 2);
    await openCard(tester, 'tap-daily-prep');
    await tester.ensureVisible(find.text('도구 나누기'));
    await tester.tap(find.text('도구 나누기'));
    await tester.pumpAndSettle();
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    await tester.pumpAndSettle();
    final save = find.widgetWithText(FilledButton, '저장');
    await tester.ensureVisible(save);
    await tester.pumpAndSettle();
    expect(tester.getBottomLeft(save).dy, lessThanOrEqualTo(1200));
    expect(tester.takeException(), isNull);
  });

  testWidgets('save uses opening revision and keeps draft on conflict', (
    tester,
  ) async {
    final state = fixture();
    final opening = state['revision'];
    Json? posted;
    final ops = OperationsController(
      client: MockClient((r) async {
        if (r.method == 'POST') {
          posted = jsonDecode(r.body) as Json;
          return response({'error': '다른 사람이 먼저 변경했어요.'}, 409);
        }
        return response(state);
      }),
    );
    addTearDown(ops.dispose);
    await mountBoard(tester, ops);
    await openCard(tester, 'tap-daily-prep');
    await tester.tap(find.text('도구 나누기'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('task-step-title')),
      '보존할 초안',
    );
    state['revision'] = (opening as int) + 1;
    await ops.refresh();
    await tester.pumpAndSettle();
    final save = find.widgetWithText(FilledButton, '저장');
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(posted, containsPair('action', 'save_task_step'));
    expect(posted, containsPair('revision', opening));
    expect(posted, containsPair('taskId', 'daily-prep'));
    expect(posted, containsPair('stepId', 's1'));
    expect(find.text('보존할 초안'), findsOneWidget);
    expect(find.text('다른 사람이 먼저 변경했어요.'), findsOneWidget);
    expect(find.byType(TaskStepEditor), findsOneWidget);
  });

  testWidgets(
    'restricted manager cannot edit, append or reorder but can read manual',
    (tester) async {
      final state = fixture(actor: 'manager')..['canEditTasks'] = false;
      final ops = OperationsController(
        readOnly: true,
        client: MockClient((_) async => response(state)),
      );
      addTearDown(ops.dispose);
      await mountBoard(tester, ops);
      expect(find.text('보드 편집'), findsNothing);
      await openCard(tester, 'tap-daily-prep');
      expect(find.text('TAP 편집'), findsNothing);
      expect(find.byKey(const ValueKey('add-task-step')), findsNothing);
      expect(find.byType(ReorderableDragStartListener), findsNothing);
      expect(
        tester.widget<TapCard>(find.byKey(const ValueKey('small-s1'))).onEdit,
        isNull,
      );
      await tester.tap(find.text('도구 나누기'));
      await tester.pumpAndSettle();
      expect(find.text('생재료와 완성식품 도구를 따로 놓아요.'), findsOneWidget);
      expect(find.text('매뉴얼 바로 수정'), findsNothing);
    },
  );

  testWidgets(
    'completed Task is immutable and manual actions do not overlap drag handle',
    (tester) async {
      final state = fixture();
      (state['tasks'] as List).first['steps'][0]['completedAt'] =
          '2026-09-29T00:00:00Z';
      final ops = OperationsController(
        readOnly: true,
        client: MockClient((_) async => response(state)),
      );
      addTearDown(ops.dispose);
      await mountBoard(tester, ops, width: 320);
      await openCard(tester, 'tap-daily-prep');
      final card = find.byKey(const ValueKey('small-s1'));
      expect(tester.widget<TapCard>(card).onEdit, isNull);
      final drag = find.descendant(
        of: card,
        matching: find.byType(ReorderableDragStartListener),
      );
      final open = find.descendant(
        of: card,
        matching: find.byWidgetPredicate(
          (w) => w is Semantics && w.properties.label == '매뉴얼 열기',
        ),
      );
      expect(tester.getRect(drag).overlaps(tester.getRect(open)), false);
      await tester.tap(open);
      await tester.pumpAndSettle();
      expect(find.text('생재료와 완성식품 도구를 따로 놓아요.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
