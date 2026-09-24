import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:tap2work/state/operations_controller.dart';
import 'package:tap2work/ui/tap_card.dart';
import 'package:tap2work/ui/tap_workspace.dart';
import 'checklist_test.dart' show fixture;
import 'operations_test.dart' show response;

Future<void> mountBoard(
  WidgetTester tester,
  OperationsController ops, {
  double width = 1200,
}) async {
  tester.view.physicalSize = Size(width, 1500);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await ops.refresh();
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: TapWorkspace(ops: ops, onStock: (_) async {}),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> openGroup(WidgetTester tester, String name) async {
  await tester.ensureVisible(find.widgetWithText(ChoiceChip, name).first);
  await tester.tap(find.widgetWithText(ChoiceChip, name).first);
  await tester.pumpAndSettle();
}

Future<void> openCard(WidgetTester tester, String key) async {
  final card = find.byKey(ValueKey(key));
  await tester.ensureVisible(card);
  await tester.tap(card);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'menu TAPs render in one order group and its touch action moves them together',
    (tester) async {
      final data = fixture();
      final first =
          (data['tasks'] as List).firstWhere((t) => t['kind'] == 'routine')
              as Json;
      final second = jsonDecode(jsonEncode(first)) as Json;
      first.addAll({'orderId': 'order-17', 'orderNumber': 'A-17'});
      second.addAll({
        'id': 'second-menu',
        'title': '추가 메뉴',
        'orderId': 'order-17',
        'orderNumber': 'A-17',
      });
      (data['tasks'] as List).add(second);
      var writes = 0;
      final ops = OperationsController(
        readOnly: true,
        client: MockClient((r) async {
          if (r.method == 'POST') writes++;
          return response(data);
        }),
      );
      addTearDown(ops.dispose);
      await mountBoard(tester, ops, width: 390);
      expect(find.text('주문 A-17 · 2 메뉴 ↕'), findsOneWidget);
      await tester.ensureVisible(find.byTooltip('주문 그룹 이동'));
      await tester.tap(find.byTooltip('주문 그룹 이동'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('전체 완료'));
      await tester.pumpAndSettle();
      expect(
        ops
            .rows('tasks')
            .where((t) => t['orderId'] == 'order-17')
            .every((t) => t['completedAt'] != null),
        true,
      );
      expect(writes, 0);
      expect(tester.takeException(), isNull);
    },
  );

  for (final width in [320.0, 390.0, 1200.0]) {
    testWidgets('root shows Taps immediately and opens manual at $width', (
      tester,
    ) async {
      final ops = OperationsController(
        readOnly: true,
        client: MockClient((_) async => response(fixture())),
      );
      addTearDown(ops.dispose);
      await mountBoard(tester, ops, width: width);
      expect(find.text('할일'), findsOneWidget);
      expect(find.text('5분 계획'), findsNothing);
      expect(
        tester
            .widget<TapCard>(find.byKey(const ValueKey('tap-daily-prep')))
            .level,
        'TAP',
      );
      await openCard(tester, 'tap-daily-prep');
      expect(
        tester.widget<TapCard>(find.byKey(const ValueKey('small-s1'))).level,
        'SMALL TAP',
      );
      if (width < 700) {
        expect(find.text('생재료와 완성식품 도구를 따로 놓아요.'), findsNothing);
      }
      await openCard(tester, 'small-s1');
      expect(find.text('생재료와 완성식품 도구를 따로 놓아요.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'preview completion rolls up through parents and undo sends no POST',
    (tester) async {
      var writes = 0;
      final ops = OperationsController(
        readOnly: true,
        client: MockClient((request) async {
          if (request.method == 'POST') writes++;
          return response(fixture());
        }),
      );
      addTearDown(ops.dispose);
      await mountBoard(tester, ops);
      await openGroup(tester, '기본 업무  ·  2');
      await openCard(tester, 'tap-daily-prep');
      await tester.tap(
        find.descendant(
          of: find.byKey(const ValueKey('small-s1')),
          matching: find.byType(IconButton),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester.widget<TapCard>(find.byKey(const ValueKey('small-s1'))).checked,
        isTrue,
      );
      await tester.tap(find.widgetWithText(TextButton, '기본 업무'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TapCard>(find.byKey(const ValueKey('tap-daily-prep')))
            .done,
        1,
      );
      await tester.tap(find.widgetWithText(TextButton, '전체 보드'));
      await tester.pumpAndSettle();
      expect(find.textContaining('기본 업무'), findsWidgets);
      await openGroup(tester, '기본 업무  ·  2');
      await openCard(tester, 'tap-daily-prep');
      await tester.tap(
        find.descendant(
          of: find.byKey(const ValueKey('small-s1')),
          matching: find.byType(IconButton),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, '되돌리기'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<TapCard>(find.byKey(const ValueKey('small-s1'))).checked,
        isFalse,
      );
      expect(writes, 0);
    },
  );

  testWidgets(
    'role restrictions remain visible and empty folder can be opened',
    (tester) async {
      final ops = OperationsController(
        readOnly: true,
        client: MockClient((_) async => response(fixture(actor: 'crew'))),
      );
      addTearDown(ops.dispose);
      await mountBoard(tester, ops);
      await openGroup(tester, '마감 폴더  ·  0');
      expect(find.text('아직 카드가 없어요'), findsNWidgets(3));
      await tester.tap(find.widgetWithText(TextButton, '전체 보드'));
      await tester.pumpAndSettle();
      await openGroup(tester, '기본 업무  ·  2');
      await openCard(tester, 'tap-daily-broth');
      await tester.tap(
        find.descendant(
          of: find.byKey(const ValueKey('small-b1')),
          matching: find.byType(IconButton),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester.widget<TapCard>(find.byKey(const ValueKey('small-b1'))).checked,
        isFalse,
      );
      expect(find.textContaining('담당 Tap이에요'), findsOneWidget);
    },
  );

  testWidgets('live completion uses the original task and step IDs', (
    tester,
  ) async {
    final state = fixture();
    Json? sent;
    final ops = OperationsController(
      client: MockClient((request) async {
        if (request.method == 'POST') {
          sent = jsonDecode(request.body) as Json;
          state['tasks'][0]['steps'][0]['completedAt'] = '2026-09-23T13:00:00Z';
        }
        return response(state);
      }),
    );
    addTearDown(ops.dispose);
    await mountBoard(tester, ops);
    await openGroup(tester, '기본 업무  ·  2');
    await openCard(tester, 'tap-daily-prep');
    await tester.tap(
      find.descendant(
        of: find.byKey(const ValueKey('small-s1')),
        matching: find.byType(IconButton),
      ),
    );
    await tester.pumpAndSettle();
    expect(sent?['action'], 'complete_step');
    expect(sent?['taskId'], 'daily-prep');
    expect(sent?['stepId'], 's1');
    expect(sent?['revision'], state['revision']);
    expect(
      tester.widget<TapCard>(find.byKey(const ValueKey('small-s1'))).checked,
      isTrue,
    );
  });
}
