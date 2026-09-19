import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:tap2work/main.dart';
import 'package:tap2work/state/operations_controller.dart';
import 'package:tap2work/state/work_controller.dart';
import 'operations_test.dart' show sample, response;
import 'work_controller_test.dart' show MemoryStore;

Json dashboard() =>
    jsonDecode(File('test/fixtures/dashboard.json').readAsStringSync()) as Json;

void main() {
  for (final width in [320.0, 390.0, 430.0, 1440.0]) {
    testWidgets(
      'dashboard filters, search, full scroll and operations fit $width',
      (tester) async {
        tester.view.physicalSize = Size(width, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final ops = OperationsController(
          client: MockClient(
            (r) async => response({...sample(), 'dashboard': dashboard()}),
          ),
        );
        addTearDown(ops.dispose);
        await ops.refresh();
        await tester.pumpWidget(
          Tap2workApp(
            controller: WorkController(MemoryStore()),
            operations: ops,
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('매장 한눈에'), findsOneWidget);
        expect(find.text('메뉴별 매출 · 주문'), findsOneWidget);
        await tester.tap(find.widgetWithText(ChoiceChip, '최근 7일'));
        await tester.pumpAndSettle();
        expect(find.textContaining('2026-09-13 ~ 2026-09-19'), findsOneWidget);
        await tester.tap(find.widgetWithText(ChoiceChip, '배달'));
        await tester.pumpAndSettle();
        // The independent live queue retains all channels.
        expect(find.textContaining('전체 채널 5건'), findsOneWidget);
        await tester.ensureVisible(find.byType(TextField));
        await tester.enterText(find.byType(TextField), '없는메뉴');
        await tester.pumpAndSettle();
        expect(find.text('검색 조건에 맞는 메뉴가 없어요.'), findsOneWidget);
        await tester.enterText(find.byType(TextField), '');
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.widgetWithText(ChoiceChip, '음료'));
        await tester.tap(find.widgetWithText(ChoiceChip, '음료'));
        await tester.pumpAndSettle();
        expect(find.text('탄산수'), findsOneWidget);
        expect(find.text('오늘의 계절 메뉴'), findsNothing);
        await tester.ensureVisible(find.widgetWithText(ChoiceChip, '준비 완료'));
        await tester.tap(find.widgetWithText(ChoiceChip, '준비 완료'));
        await tester.pumpAndSettle();
        expect(find.text('#오늘-123'), findsOneWidget);
        expect(find.text('#오늘-120'), findsNothing);
        await tester.ensureVisible(find.text('공유 체크리스트'));
        await tester.tap(find.text('공유 체크리스트'));
        await tester.pumpAndSettle();
        expect(find.text('재고 수량 확인하기'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'missing dashboard shows unavailable rather than fabricated zeros',
    (tester) async {
      final ops = OperationsController(
        client: MockClient((r) async => response(sample())),
      );
      addTearDown(ops.dispose);
      await ops.refresh();
      await tester.pumpWidget(
        Tap2workApp(controller: WorkController(MemoryStore()), operations: ops),
      );
      expect(find.textContaining('메뉴·매출 데이터를 아직'), findsOneWidget);
      expect(find.text('순매출'), findsNothing);
    },
  );
}
