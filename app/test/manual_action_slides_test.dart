import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:image/image.dart' as image;
import 'package:tap2work/ui/manual_action_editor.dart';
import 'package:tap2work/state/operations_controller.dart';
import 'package:tap2work/ui/manual_action_slides.dart';
import 'checklist_test.dart' show fixture;
import 'operations_test.dart' show response;
import 'tap_workspace_test.dart' show mountBoard, openCard;

Json taskOf(Json data) => (data['tasks'] as List).first as Json;
Json stepOf(Json data, String id) => (taskOf(data)['steps'] as List)
    .cast<Json>()
    .firstWhere((step) => step['id'] == id);
void saved(Json data, Json payload) {
  final task = taskOf(data), step = stepOf(data, payload['stepId']);
  if (payload['action'] == 'reopen_step') {
    step.remove('completedAt');
    step.remove('completedBy');
  } else {
    step['completedAt'] = '2026-10-10T09:00:00Z';
    step['completedBy'] = data['actor'];
  }
  data['revision'] = (data['revision'] as int) + 1;
  task['completedAt'] =
      (task['steps'] as List).cast<Json>().every(
        (s) => s['completedAt'] != null,
      )
      ? '2026-10-10T09:00:00Z'
      : null;
}

Future<void> openInline(
  WidgetTester tester,
  OperationsController ops, {
  double width = 390,
  double textScale = 1,
  String step = 's1',
}) async {
  await mountBoard(tester, ops, width: width, textScale: textScale);
  await openCard(tester, 'tap-daily-prep');
  await openCard(tester, 'small-$step');
  expect(find.byType(ManualActionSlides), findsNothing);
}

Finder get check => find.byWidgetPredicate(
  (w) => w is FilledButton && w.key.toString().contains('method-check-'),
);
Future<void> checkInline(WidgetTester tester) async {
  await tester.ensureVisible(check);
  await tester.pumpAndSettle();
  await tester.tap(check);
}

void main() {
  testWidgets('Task methods switch inline without navigation or writes', (
    tester,
  ) async {
    final data = fixture();
    final writes = <Json>[];
    final ops = OperationsController(
      client: MockClient((request) async {
        if (request.method == 'POST') {
          writes.add(jsonDecode(request.body) as Json);
        }
        return response(data);
      }),
    );
    addTearDown(ops.dispose);
    await openInline(tester, ops);
    expect(find.text('생재료와 완성식품 도구를 따로 놓아요.'), findsOneWidget);
    expect(find.text('팁 · 색상보다 용도를 확인해요.'), findsOneWidget);
    expect(find.text('작업 장소 보기'), findsOneWidget);
    await openCard(tester, 'small-s2');
    expect(find.text('오염을 제거하고 지정 절차대로 처리해요.'), findsOneWidget);
    expect(find.text('생재료와 완성식품 도구를 따로 놓아요.'), findsNothing);
    await openCard(tester, 'small-s1');
    expect(find.text('생재료와 완성식품 도구를 따로 놓아요.'), findsOneWidget);
    expect(writes, isEmpty);
    expect(stepOf(ops.data!, 's1')['completedAt'], isNull);
  });

  testWidgets(
    'completion waits for saved response and moves to the completed view only after all actions',
    (tester) async {
      final data = fixture();
      final writes = <Json>[];
      final pending = Completer<http.Response>();
      final ops = OperationsController(
        client: MockClient((request) async {
          if (request.method == 'POST') {
            final payload = jsonDecode(request.body) as Json;
            writes.add(payload);
            saved(data, payload);
            if (writes.length == 1) return pending.future;
          }
          return response(data);
        }),
      );
      addTearDown(ops.dispose);
      await openInline(tester, ops);
      await checkInline(tester);
      await tester.pump();
      expect(
        find.byKey(const ValueKey('method-inline-daily-prep-s1')),
        findsOneWidget,
      );
      expect(find.text('저장 중…'), findsOneWidget);
      await checkInline(tester);
      await tester.pump();
      expect(writes.length, 1);
      expect(writes.single['action'], 'complete_step');
      expect(writes.single['taskId'], 'daily-prep');
      expect(writes.single['stepId'], 's1');
      expect(writes.single['revision'], 2);
      pending.complete(response(data));
      await tester.pumpAndSettle();
      expect(stepOf(ops.data!, 's1')['completedAt'], isNotNull);
      await openCard(tester, 'small-s2');
      await checkInline(tester);
      await tester.pumpAndSettle();
      expect(check, findsNothing);
      await tester.tap(find.byKey(const ValueKey('view-toggle-option-true')));
      await tester.pumpAndSettle();
      expect(find.text('완료했어요'), findsOneWidget);
      await checkInline(tester);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, '되돌리기'));
      await tester.pumpAndSettle();
      expect(writes.last['action'], 'reopen_step');
      expect(writes.last['stepId'], 's2');
      await tester.tap(find.byKey(const ValueKey('view-toggle-option-false')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('method-inline-daily-prep-s2')),
        findsOneWidget,
      );
      expect(stepOf(ops.data!, 's2')['completedAt'], isNull);
    },
  );

  testWidgets(
    'failed save keeps action and shows server error; retry succeeds',
    (tester) async {
      final data = fixture();
      var attempts = 0;
      final ops = OperationsController(
        client: MockClient((request) async {
          if (request.method == 'POST') {
            attempts++;
            if (attempts == 1) {
              return response({'error': '담당 변경을 확인해 주세요.'}, 403);
            }
            saved(data, jsonDecode(request.body) as Json);
          }
          return response(data);
        }),
      );
      addTearDown(ops.dispose);
      await openInline(tester, ops);
      await checkInline(tester);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('method-inline-daily-prep-s1')),
        findsOneWidget,
      );
      expect(find.textContaining('담당 변경을 확인해 주세요.'), findsWidgets);
      expect(stepOf(ops.data!, 's1')['completedAt'], isNull);
      await checkInline(tester);
      await tester.pumpAndSettle();
      expect(attempts, 2);
      expect(stepOf(ops.data!, 's1')['completedAt'], isNotNull);
    },
  );

  for (final width in [320.0, 390.0, 1200.0]) {
    testWidgets(
      'long inline method scrolls to its check at $width with enlarged text and no POST',
      (tester) async {
        final data = fixture();
        stepOf(data, 's1')['manual'] = List.filled(
          40,
          '도구와 작업 위치를 확인해요.',
        ).join('\n');
        var writes = 0;
        final ops = OperationsController(
          readOnly: true,
          client: MockClient((request) async {
            if (request.method == 'POST') writes++;
            return response(data);
          }),
        );
        addTearDown(ops.dispose);
        await openInline(tester, ops, width: width, textScale: 1.5);
        await checkInline(tester);
        await tester.pumpAndSettle();
        expect(stepOf(ops.data!, 's1')['completedAt'], isNotNull);
        expect(
          find.byKey(const ValueKey('method-inline-daily-prep-s1')),
          findsOneWidget,
        );
        expect(writes, 0);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'sequence, unresolved issue and role restrictions prevent checks but allow browsing',
    (tester) async {
      final data = fixture(actor: 'crew');
      taskOf(data)['settings'] = {'enforceSequence': true};
      var writes = 0;
      final ops = OperationsController(
        readOnly: true,
        client: MockClient((request) async {
          if (request.method == 'POST') writes++;
          return response(data);
        }),
      );
      addTearDown(ops.dispose);
      await openInline(tester, ops, step: 's2');
      expect(find.text('앞의 행동을 먼저 완료해 주세요.'), findsOneWidget);
      expect(tester.widget<FilledButton>(check).onPressed, isNull);
      await openCard(tester, 'small-s1');
      await tester.pumpAndSettle();
      taskOf(data)['workIssue'] = <String, dynamic>{
        'status': 'open',
        'reason': '도구를 찾을 수 없어요.',
      };
      await ops.refresh();
      await tester.pumpAndSettle();
      expect(find.text('조치 확인 전 완료할 수 없어요.'), findsWidgets);
      expect(tester.widget<FilledButton>(check).onPressed, isNull);
      taskOf(data)['workIssue']['blocksCompletion'] = false;
      await ops.refresh();
      await tester.pumpAndSettle();
      expect(tester.widget<FilledButton>(check).onPressed, isNotNull);
      taskOf(data).remove('workIssue');
      taskOf(data)['canComplete'] = false;
      await ops.refresh();
      await tester.pumpAndSettle();
      expect(tester.widget<FilledButton>(check).onPressed, isNull);
      expect(writes, 0);
    },
  );

  testWidgets(
    'quantity cancel stays and measured completion preserves existing payload',
    (tester) async {
      final data = fixture();
      stepOf(data, 's1')['settings'] = {
        'completionKind': 'quantity',
        'quantitySpec': {'unit': '개', 'decimalPlaces': 0},
      };
      final writes = <Json>[];
      final ops = OperationsController(
        client: MockClient((request) async {
          if (request.method == 'POST') {
            final payload = jsonDecode(request.body) as Json;
            writes.add(payload);
            saved(data, payload);
          }
          return response(data);
        }),
      );
      addTearDown(ops.dispose);
      await openInline(tester, ops);
      await checkInline(tester);
      await tester.pumpAndSettle();
      await tester.tap(find.text('취소'));
      await tester.pumpAndSettle();
      expect(writes, isEmpty);
      expect(
        find.byKey(const ValueKey('method-inline-daily-prep-s1')),
        findsOneWidget,
      );
      await checkInline(tester);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '8');
      await tester.tap(find.widgetWithText(FilledButton, '완료'));
      await tester.pumpAndSettle();
      expect(writes.single['quantity'], 8);
      expect(writes.single['stepId'], 's1');
      expect(stepOf(ops.data!, 's1')['completedAt'], isNotNull);
    },
  );

  testWidgets(
    'changing source hides old content and cannot mutate new source',
    (tester) async {
      final data = fixture();
      data['workspaceId'] = 'store-a';
      var writes = 0;
      final ops = OperationsController(
        client: MockClient((request) async {
          if (request.method == 'POST') writes++;
          return response(data);
        }),
      );
      addTearDown(ops.dispose);
      await openInline(tester, ops);
      data['workspaceId'] = 'store-b';
      await ops.refresh();
      await tester.pumpAndSettle();
      expect(find.text('생재료와 완성식품 도구를 따로 놓아요.'), findsNothing);
      expect(check, findsNothing);
      expect(writes, 0);
    },
  );
  testWidgets(
    'inline photo enlargement never completes and edited manual remains after save failure',
    (tester) async {
      final data = fixture();
      stepOf(data, 's1')['imageUrl'] =
          'data:image/png;base64,${base64Encode(image.encodePng(image.Image(width: 4, height: 4)))}';
      final writes = <Json>[];
      final ops = OperationsController(
        client: MockClient((request) async {
          if (request.method == 'POST') {
            final payload = jsonDecode(request.body) as Json;
            writes.add(payload);
            if (writes.length == 1) {
              return response({'error': '매뉴얼을 저장하지 못했어요.'}, 503);
            }
            stepOf(data, 's1')['manual'] = payload['manual'];
            data['revision'] = 3;
          }
          return response(data);
        }),
      );
      addTearDown(ops.dispose);
      await openInline(tester, ops);
      await tester.ensureVisible(find.text('사진 크게 보기'));
      await tester.tap(find.text('사진 크게 보기'));
      await tester.pumpAndSettle();
      expect(find.byType(InteractiveViewer), findsOneWidget);
      expect(writes, isEmpty);
      await tester.tap(find.byType(CloseButton).last);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('매뉴얼 바로 수정'));
      await tester.tap(find.text('매뉴얼 바로 수정'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('action-editor-manual')),
        '수정한 방법과 완료 기준',
      );
      await tester.enterText(
        find.byKey(const ValueKey('action-editor-imageUrl')),
        '',
      );
      await tester.tap(find.widgetWithText(FilledButton, '저장'));
      await tester.pumpAndSettle();
      expect(find.byType(ManualActionEditor), findsOneWidget);
      expect(find.text('수정한 방법과 완료 기준'), findsOneWidget);
      expect(find.text('매뉴얼을 저장하지 못했어요.'), findsOneWidget);
      expect(writes.single['action'], 'save_step_manual');
      expect(writes.single['stepId'], 's1');
      expect(writes.single['revision'], 2);
      await tester.tap(find.widgetWithText(FilledButton, '저장'));
      await tester.pumpAndSettle();
      expect(find.byType(ManualActionEditor), findsNothing);
      expect(
        find.byKey(const ValueKey('method-inline-daily-prep-s1')),
        findsOneWidget,
      );
      expect(find.text('수정한 방법과 완료 기준'), findsOneWidget);
      expect(stepOf(ops.data!, 's1')['completedAt'], isNull);
      expect(
        writes.every((payload) => payload['action'] == 'save_step_manual'),
        isTrue,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('safety evidence remains required for inline completion', (
    tester,
  ) async {
    final data = fixture();
    taskOf(data)['workEvent'] = {'type': 'manual'};
    taskOf(data)['knowledge'] = {'safetyReviewRequired': true};
    taskOf(data)['settings'] = {'operatingStandard': '매장 기준 확인'};
    final writes = <Json>[];
    final ops = OperationsController(
      client: MockClient((request) async {
        if (request.method == 'POST') {
          final payload = jsonDecode(request.body) as Json;
          writes.add(payload);
          saved(data, payload);
        }
        return response(data);
      }),
    );
    addTearDown(ops.dispose);
    await openInline(tester, ops);
    await checkInline(tester);
    await tester.pumpAndSettle();
    expect(writes, isEmpty);
    await tester.enterText(find.byType(TextField), '실제 상태와 매장 기준을 확인했어요.');
    await tester.tap(find.widgetWithText(FilledButton, '기록하고 완료'));
    await tester.pumpAndSettle();
    expect(writes.single['evidence'], '실제 상태와 매장 기준을 확인했어요.');
    expect(writes.single['action'], 'complete_step');
    expect(stepOf(ops.data!, 's1')['completedAt'], isNotNull);
  });
  testWidgets(
    'inline editor pins opening revision eagerly and asks before discarding changed draft',
    (tester) async {
      final data = fixture();
      var writes = 0;
      final ops = OperationsController(
        client: MockClient((request) async {
          if (request.method == 'POST') writes++;
          return response(data);
        }),
      );
      addTearDown(ops.dispose);
      await openInline(tester, ops);
      await tester.ensureVisible(find.text('매뉴얼 바로 수정'));
      await tester.tap(find.text('매뉴얼 바로 수정'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('action-editor-manual')),
        '보존할 변경',
      );
      ops.data!['revision'] = 99;
      await tester.tap(find.widgetWithText(FilledButton, '저장'));
      await tester.pumpAndSettle();
      expect(writes, 0);
      expect(find.text('다른 변경이 저장됐어요. 최신 매뉴얼을 다시 열어 주세요.'), findsOneWidget);
      expect(find.text('보존할 변경'), findsOneWidget);
      await tester.tap(find.byType(CloseButton).last);
      await tester.pumpAndSettle();
      expect(find.text('매뉴얼 편집을 취소할까요?'), findsOneWidget);
      await tester.tap(find.text('계속 수정'));
      await tester.pumpAndSettle();
      expect(find.byType(ManualActionEditor), findsOneWidget);
      expect(find.text('보존할 변경'), findsOneWidget);
    },
  );
}
