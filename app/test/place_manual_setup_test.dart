import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:tap2work/main.dart';
import 'package:tap2work/state/operations_controller.dart';
import 'package:tap2work/state/work_controller.dart';
import 'package:tap2work/ui/place_guide.dart';
import 'package:tap2work/ui/manual_setup_screen.dart';
import 'operations_test.dart' show sample, response;
import 'work_controller_test.dart' show MemoryStore;

void main() {
  for (final width in [320.0, 390.0, 1200.0]) {
    testWidgets(
      'places work without a map and submit one shared ID at $width',
      (t) async {
        t.view.physicalSize = Size(width, 1100);
        t.view.devicePixelRatio = 1;
        addTearDown(t.view.resetPhysicalSize);
        addTearDown(t.view.resetDevicePixelRatio);
        t.platformDispatcher.textScaleFactorTestValue = 1.5;
        addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
        Json? payload;
        final state = {...sample(), 'zones': <Json>[]};
        final ops = OperationsController(
          client: MockClient((r) async {
            if (r.method == 'POST') payload = jsonDecode(r.body);
            return response(state);
          }),
        );
        addTearDown(ops.dispose);
        await ops.refresh();
        final work = WorkController(MemoryStore());
        addTearDown(work.dispose);
        await t.pumpWidget(
          Tap2workApp(
            controller: work,
            homeOverride: Scaffold(
              body: SingleChildScrollView(child: PlaceGuide(ops: ops)),
            ),
          ),
        );
        await t.tap(find.text('장소 추가'));
        await t.pumpAndSettle();
        await t.enterText(find.widgetWithText(TextField, '장소 이름'), '비품 창고');
        await t.enterText(find.widgetWithText(TextField, '층·건물 (선택)'), '2층');
        await t.enterText(
          find.widgetWithText(TextField, '찾는 방법'),
          '계단 오른쪽 첫 번째 문',
        );
        await t.ensureVisible(find.text('장소 저장'));
        await t.tap(find.text('장소 저장'));
        await t.pumpAndSettle();
        expect(payload?['action'], 'save_place');
        expect(payload?['place']['floor'], '2층');
        expect(payload?['place'].containsKey('x'), false);
        expect(t.takeException(), isNull);
      },
    );
  }
  testWidgets('customization uses text/icon and differs from completion', (
    t,
  ) async {
    await t.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              ManualCustomizationBadge(value: null),
              ManualCustomizationBadge(value: {'kind': 'modified'}),
              ManualCustomizationBadge(value: {'kind': 'created'}),
            ],
          ),
        ),
      ),
    );
    expect(find.text('우리 매장 수정'), findsOneWidget);
    expect(find.text('직접 추가'), findsOneWidget);
    expect(find.byIcon(Icons.edit_outlined), findsOneWidget);
    expect(find.byIcon(Icons.note_add_outlined), findsOneWidget);
  });
}
