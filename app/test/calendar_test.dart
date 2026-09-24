import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:tap2work/state/operations_controller.dart';
import 'package:tap2work/ui/calendar_screen.dart';
import 'operations_test.dart' show sample, response;

Json calendarData() => {
  ...sample(),
  'day': '2026-09-24',
  'actor': {'id': 'owner', 'role': 'owner', 'name': '사장'},
  'staffingSlots': [
    {'id': 'slot-0', 'duty': '조리', 'start': '09:00', 'end': '18:00'},
    {'id': 'slot-1', 'duty': '서빙1', 'start': '09:00', 'end': '18:00'},
    {'id': 'slot-2', 'duty': 'cashier', 'start': '09:00', 'end': '18:00'},
  ],
  'tappers': [
    {
      'id': 'cook',
      'nickname': '현우',
      'active': true,
      'duties': ['조리'],
    },
    {
      'id': 'manager',
      'nickname': '민지',
      'active': true,
      'duties': ['서빙1'],
    },
  ],
  'staffShifts': [],
};
void main() {
  for (final width in [320.0, 390.0, 1200.0]) {
    testWidgets(
      'weekly and monthly staffing calendar fits $width and keeps preview read-only',
      (tester) async {
        tester.view.physicalSize = Size(width, 1600);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        var writes = 0;
        final ops = OperationsController(
          readOnly: true,
          client: MockClient((r) async {
            if (r.method == 'POST') writes++;
            return response(calendarData());
          }),
        );
        addTearDown(ops.dispose);
        await ops.refresh();
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: CalendarScreen(operations: ops),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('배정 0 · 빈 슬롯 3'), findsOneWidget);
        expect(find.text('빈 슬롯'), findsNWidgets(3));
        expect(find.text('하루 3명 · 슬롯 설정'), findsOneWidget);
        await tester.tap(find.byKey(const Key('calendar-day-2026-09-25')));
        await tester.pumpAndSettle();
        expect(find.text('9월 25일 금요일'), findsOneWidget);
        if (width < 600) {
          await tester.tap(find.text('시간표'));
          await tester.pumpAndSettle();
        }
        expect(find.text('06:00'), findsOneWidget);
        expect(find.text('23:00'), findsOneWidget);
        await tester.tap(find.text('월간'));
        await tester.pumpAndSettle();
        expect(find.text('빈 슬롯'), findsNWidgets(90));
        expect(find.text('2026년 9월'), findsOneWidget);
        expect(tester.takeException(), isNull);
        expect(writes, 0);
      },
    );
  }
  testWidgets('phone empty slot opens assignment and saves selected crew', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final writes = <Json>[];
    final ops = OperationsController(
      client: MockClient((r) async {
        if (r.method == 'POST') writes.add(jsonDecode(r.body) as Json);
        return response(calendarData());
      }),
    );
    addTearDown(ops.dispose);
    await ops.refresh();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(child: CalendarScreen(operations: ops)),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('빈 슬롯').first);
    await tester.pumpAndSettle();
    expect(find.textContaining('가능 여부는 직접 확인해 주세요'), findsOneWidget);
    await tester.tap(find.text('현우').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('저장').last);
    await tester.pumpAndSettle();
    expect(writes.single['action'], 'save_shift_pattern');
    expect(writes.single['date'], '2026-09-24');
    expect(writes.single['tapperId'], 'cook');
    expect(writes.single['duty'], '조리');
    expect(tester.takeException(), isNull);
  });
  testWidgets('tapping the weekly grid saves a bounded shift with revision', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 1500);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final writes = <Json>[];
    final ops = OperationsController(
      client: MockClient((r) async {
        if (r.method == 'POST') writes.add(jsonDecode(r.body) as Json);
        return response(calendarData());
      }),
    );
    addTearDown(ops.dispose);
    await ops.refresh();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(child: CalendarScreen(operations: ops)),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final day = find.byKey(const Key('week-grid-day-2026-09-21'));
    final cell = find.descendant(of: day, matching: find.byType(InkWell)).first;
    await tester.ensureVisible(cell);
    await tester.tap(cell);
    await tester.pumpAndSettle();
    await tester.tap(find.text('현우 · 조리').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('저장').last);
    await tester.pumpAndSettle();
    expect(writes.single['action'], 'save_shift_pattern');
    expect(writes.single['date'], '2026-09-21');
    expect(writes.single['tapperId'], 'cook');
    expect(writes.single['employmentType'], '시간알바');
    expect(writes.single['revision'], calendarData()['revision']);
    expect(tester.takeException(), isNull);
  });
  testWidgets('dropping crew at a 30-minute row prefills the shift time', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 1500);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final writes = <Json>[];
    final ops = OperationsController(
      client: MockClient((r) async {
        if (r.method == 'POST') writes.add(jsonDecode(r.body) as Json);
        return response(calendarData());
      }),
    );
    addTearDown(ops.dispose);
    await ops.refresh();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(child: CalendarScreen(operations: ops)),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final target = find.byKey(const Key('week-grid-day-2026-09-21'));
    await tester.ensureVisible(target);
    final widget = tester.widget<DragTarget<Json>>(target);
    widget.onAcceptWithDetails!(
      DragTargetDetails<Json>(
        data: calendarData()['tappers'][0],
        offset: tester.getTopLeft(target) + const Offset(20, 300),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('저장').last);
    await tester.pumpAndSettle();
    expect(writes.single['start'], '11:00');
    expect(writes.single['end'], '20:00');
  });
}
