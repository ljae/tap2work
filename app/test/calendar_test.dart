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
        expect(find.textContaining('배정 0 · 빈 슬롯 3'), findsOneWidget);
        expect(find.text('빈 슬롯'), findsNWidgets(3));
        expect(find.text('하루 3명 · 슬롯 설정'), findsOneWidget);
        await tester.tap(find.byKey(const Key('calendar-day-2026-09-25')));
        await tester.pumpAndSettle();
        expect(find.textContaining('9월 25일 금요일'), findsOneWidget);
        expect(find.text('06:00'), findsOneWidget);
        expect(find.text('주간 시간표 · 06:00–24:00'), findsNothing);
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
    final data = calendarData();
    (data['staffingSlots'] as List).first['start'] = '10:00';
    (data['staffingSlots'] as List).first['end'] = '14:00';
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
    expect(writes.single['start'], '10:00');
    expect(writes.single['end'], '14:00');
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'selected day shows filled, leave and extra shifts in one timeline',
    (tester) async {
      tester.view.physicalSize = const Size(320, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final data = calendarData();
      data['staffShifts'] = [
        {
          'id': 'assigned',
          'slotId': 'slot-0',
          'date': '2026-09-24',
          'tapperId': 'cook',
          'duty': '조리',
          'start': '09:00',
          'end': '18:00',
        },
        {
          'id': 'leave',
          'slotId': 'slot-1',
          'date': '2026-09-24',
          'tapperId': 'manager',
          'duty': '서빙1',
          'start': '09:00',
          'end': '18:00',
          'status': 'leave',
        },
        {
          'id': 'extra',
          'date': '2026-09-24',
          'tapperId': 'manager',
          'duty': '서빙1',
          'start': '18:00',
          'end': '22:00',
        },
        {
          'id': 'overnight',
          'date': '2026-09-24',
          'tapperId': 'cook',
          'duty': '조리',
          'start': '23:00',
          'end': '02:00',
        },
      ];
      final ops = OperationsController(
        readOnly: true,
        client: MockClient((_) async => response(data)),
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
      expect(find.textContaining('배정 1 · 빈 슬롯 2'), findsOneWidget);
      expect(find.text('빈 슬롯'), findsNWidgets(2));
      expect(find.text('추가 근무'), findsOneWidget);
      expect(find.text('23:00–02:00'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('overlapping required R&R slots use separate visible columns', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final data = calendarData();
    (data['staffingSlots'] as List).add({
      'id': 'slot-overlap',
      'duty': '조리',
      'start': '10:00',
      'end': '14:00',
    });
    final ops = OperationsController(
      readOnly: true,
      client: MockClient((_) async => response(data)),
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
    expect(find.text('빈 슬롯'), findsNWidgets(4));
    final first = tester.getRect(find.byKey(const Key('roster-block-slot-0')));
    final second = tester.getRect(
      find.byKey(const Key('roster-block-slot-overlap')),
    );
    expect(first.right <= second.left || second.right <= first.left, isTrue);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'previous overnight shift appears in morning with original edit date',
    (tester) async {
      tester.view.physicalSize = const Size(390, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final data = calendarData();
      data['staffShifts'] = [
        {
          'id': 'overnight-prior',
          'date': '2026-09-23',
          'tapperId': 'cook',
          'duty': '조리',
          'start': '22:00',
          'end': '08:00',
        },
      ];
      final ops = OperationsController(
        client: MockClient((_) async => response(data)),
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
      expect(find.text('전날부터'), findsOneWidget);
      expect(find.text('22:00–08:00'), findsOneWidget);
      await tester.tap(find.text('전날부터'));
      await tester.pumpAndSettle();
      expect(find.textContaining('2026-09-23 근무'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('tapping a blank day timeline cell prefills role and time', (
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
    await tester.tap(find.byKey(const Key('calendar-day-2026-09-21')));
    await tester.pumpAndSettle();
    final cell = find.byKey(const Key('roster-cell-2026-09-21-조리-0'));
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
    expect(writes.single['duty'], '조리');
    expect(writes.single['start'], '06:00');
    expect(writes.single['end'], '15:00');
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
    await tester.tap(find.byKey(const Key('calendar-day-2026-09-21')));
    await tester.pumpAndSettle();
    final target = find.byKey(const Key('roster-lane-2026-09-21-조리'));
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
