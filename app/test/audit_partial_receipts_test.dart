import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:tap2work/main.dart';
import 'package:tap2work/state/operations_controller.dart';
import 'package:tap2work/state/work_controller.dart';
import 'operations_test.dart' show sample, response;
import 'work_controller_test.dart' show MemoryStore;

Json receiptFixture() => {
  ...sample(),
  'orders': [
    {
      'id': 'synthetic-order',
      'status': 'ordered',
      'createdAt': '2026-10-10T01:00:00Z',
      'placedBy': {'name': '가상 사장'},
      'lines': [
        {
          'itemId': 'rice',
          'name': '쌀',
          'unit': '포',
          'quantity': 10,
          'receivedQuantity': 3,
        },
        {'itemId': 'oil', 'name': '기름', 'unit': 'L', 'quantity': 2},
      ],
    },
  ],
};

Future<void> openReceipt(WidgetTester tester, OperationsController ops) async {
  await ops.refresh();
  await tester.pumpWidget(
    Tap2workApp(controller: WorkController(MemoryStore()), operations: ops),
  );
  await tester.tap(find.byKey(const ValueKey('floating-menu-3')));
  await tester.pumpAndSettle();
  await tester.ensureVisible(find.text('재고와 발주'));
  await tester.tap(find.text('재고와 발주'));
  await tester.pumpAndSettle();
  await tester.ensureVisible(find.text('받은 수량 반영'));
  await tester.tap(find.text('받은 수량 반영'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'receipt form starts at zero, validates remainder, and sends only the entered batch',
    (tester) async {
      Json? sent;
      final ops = OperationsController(
        client: MockClient((request) async {
          if (request.method == 'POST') sent = jsonDecode(request.body) as Json;
          return response(receiptFixture());
        }),
      );
      addTearDown(ops.dispose);
      await openReceipt(tester, ops);
      final submit = find.widgetWithText(FilledButton, '받은 수량 반영');
      expect(
        tester
            .widget<TextField>(find.byKey(const ValueKey('receipt-rice')))
            .controller!
            .text,
        '0',
      );
      await tester.tap(submit);
      await tester.pumpAndSettle();
      expect(sent, isNull);
      await tester.enterText(find.byKey(const ValueKey('receipt-rice')), '8');
      await tester.tap(submit);
      await tester.pumpAndSettle();
      expect(sent, isNull);
      await tester.enterText(find.byKey(const ValueKey('receipt-rice')), '2.5');
      await tester.tap(submit);
      await tester.pumpAndSettle();
      expect(sent!['action'], 'receive_order');
      expect(sent!['receiptId'], matches(RegExp(r'^[a-f0-9]{32}$')));
      expect(sent!['lines'], [
        {'itemId': 'rice', 'quantity': 2.5},
        {'itemId': 'oil', 'quantity': 0.0},
      ]);
      expect(find.byType(AlertDialog), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'unknown response preserves receipt ID and quantity through close/reopen retry',
    (tester) async {
      final sent = <Json>[];
      final ops = OperationsController(
        client: MockClient((request) async {
          if (request.method == 'POST') {
            sent.add(jsonDecode(request.body) as Json);
            if (sent.length == 1) {
              throw Exception('synthetic lost response after commit');
            }
          }
          return response(receiptFixture());
        }),
      );
      addTearDown(ops.dispose);
      await openReceipt(tester, ops);
      await tester.enterText(find.byKey(const ValueKey('receipt-rice')), '2');
      await tester.tap(find.widgetWithText(FilledButton, '받은 수량 반영'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(
        tester
            .widget<TextField>(find.byKey(const ValueKey('receipt-rice')))
            .enabled,
        false,
      );
      await tester.tap(find.widgetWithText(TextButton, '닫기'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('받은 수량 반영'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextField>(find.byKey(const ValueKey('receipt-rice')))
            .controller!
            .text,
        '2',
      );
      await tester.tap(find.widgetWithText(FilledButton, '같은 수량으로 다시 확인'));
      await tester.pumpAndSettle();
      expect(sent, hasLength(2));
      expect(sent[1]['receiptId'], sent[0]['receiptId']);
      expect(sent[1]['lines'], sent[0]['lines']);
      expect(find.byType(AlertDialog), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
