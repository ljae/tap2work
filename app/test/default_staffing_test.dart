import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:tap2work/state/operations_controller.dart';
import 'package:tap2work/ui/workplace_screens.dart';
import 'calendar_test.dart' show calendarData;
import 'operations_test.dart' show response;

void main() {
  for (final width in [320.0, 390.0, 1200.0]) {
    testWidgets(
      'crew dropdown persists defaults on selected weekdays at $width',
      (tester) async {
        tester.view.physicalSize = Size(width, 1100);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final data = calendarData();
        final writes = <Json>[];
        final ops = OperationsController(
          client: MockClient((r) async {
            if (r.method == 'POST') writes.add(jsonDecode(r.body) as Json);
            return response(data);
          }),
        );
        addTearDown(ops.dispose);
        await ops.refresh();
        await tester.pumpWidget(
          MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(
                size: Size(width, 1100),
                textScaler: const TextScaler.linear(1.5),
              ),
              child: WorkplaceSettings(ops: ops, section: 'hours'),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('개별'));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('scope-day-3')));
        await tester.pumpAndSettle();
        await tester.tap(find.text('인원 배치').first);
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('staffing-matrix')), findsOneWidget);
        final cell = find.byKey(const ValueKey('staffing-count-0-kitchen'));
        await tester.ensureVisible(cell);
        await tester.tap(cell);
        await tester.pumpAndSettle();
        final dropdown = find.byType(DropdownButtonFormField<String>).first;
        await tester.ensureVisible(dropdown);
        await tester.tap(dropdown);
        await tester.pumpAndSettle();
        await tester.tap(find.text('현우').last);
        await tester.pumpAndSettle();
        expect(writes, isEmpty);
        await tester.tap(find.text('적용'));
        await tester.pumpAndSettle();
        expect(
          find.descendant(of: cell, matching: find.text('현우')),
          findsOneWidget,
        );
        await tester.tap(cell);
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip('인원 늘리기'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('취소'));
        await tester.pumpAndSettle();
        expect(
          find.descendant(of: cell, matching: find.text('1 / 1명')),
          findsOneWidget,
        );
        await tester.tap(find.text('일주일 설정 저장'));
        await tester.pumpAndSettle();
        expect(writes.single['action'], 'save_workplace_hours');
        expect(writes.single['defaultAssignmentsEnabled'], true);
        expect(writes.single['revision'], 12);
        for (final d in ['1', '3']) {
          expect(writes.single['days'][d][0]['crewIds']['kitchen'], ['cook']);
        }
        expect(writes.single['days']['2'][0]['crewIds'], isNull);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
