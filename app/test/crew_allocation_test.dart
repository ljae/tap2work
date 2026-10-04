import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tap2work/state/operations_controller.dart';
import 'package:tap2work/ui/crew_allocation_screen.dart';
import 'calendar_test.dart' as calendar;
import 'operations_test.dart' show response;

Future<OperationsController> mount(
  WidgetTester tester, {
  double width = 390,
  double scale = 1,
  bool conflict = false,
  void Function(Json)? write,
}) async {
  tester.view.physicalSize = Size(width, 1200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final data = calendar.calendarData();
  final ops = OperationsController(
    client: MockClient((r) async {
      if (r.method == 'POST') {
        final body = jsonDecode(r.body) as Json;
        write?.call(body);
        if (conflict) {
          return http.Response(
            jsonEncode({'error': '다른 변경이 있어요.'}),
            409,
            headers: {'content-type': 'application/json'},
          );
        }
        data['revision'] = 13;
        if (body['patterns'] != null) data['crewPatterns'] = body['patterns'];
      }
      return response(data);
    }),
  );
  addTearDown(ops.dispose);
  await ops.refresh();
  await tester.pumpWidget(
    MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(
          size: Size(width, 1200),
          textScaler: TextScaler.linear(scale),
        ),
        child: CrewAllocationScreen(ops: ops, day: DateTime(2026, 9, 28)),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return ops;
}

void main() {
  for (final size in [
    (320.0, 1.0),
    (390.0, 1.0),
    (1200.0, 1.0),
    (320.0, 1.5),
  ]) {
    testWidgets('slot matrix tap saves crew and stable band once at $size', (
      tester,
    ) async {
      Json? sent;
      await mount(
        tester,
        width: size.$1,
        scale: size.$2,
        write: (v) => sent = v,
      );
      await tester.tap(find.widgetWithText(InputChip, '현우').first);
      final cell = find.byKey(const ValueKey('allocation-1-day-1-kitchen'));
      await tester.ensureVisible(cell);
      await tester.tap(find.descendant(of: cell, matching: find.text('미배정')));
      await tester.pumpAndSettle();
      expect(sent, isNull);
      await tester.tap(find.text('기본 배정 저장'));
      await tester.pumpAndSettle();
      expect(sent?['action'], 'save_crew_allocations');
      expect(sent?['revision'], 12);
      final pattern = (sent!['patterns'] as List).single;
      expect(pattern['tapperId'], 'cook');
      expect(pattern['entries'].single, {
        'week': 0,
        'weekday': 1,
        'partId': 'kitchen',
        'timeBandId': 'day-1',
        'start': '09:00',
        'end': '14:00',
      });
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets(
    'long press crew drag previews target and saves only after explicit save',
    (tester) async {
      final writes = <Json>[];
      await mount(tester, width: 1200, write: writes.add);
      final source = find.widgetWithText(InputChip, '현우').first;
      final target = find.byKey(const ValueKey('allocation-1-day-1-kitchen'));
      final gesture = await tester.startGesture(tester.getCenter(source));
      await tester.pump(const Duration(milliseconds: 250));
      await gesture.moveTo(tester.getCenter(target));
      await tester.pump();
      expect(find.text('여기에 배정'), findsOneWidget);
      expect(writes, isEmpty);
      await gesture.up();
      await tester.pumpAndSettle();
      expect(
        find.descendant(of: target, matching: find.text('현우')),
        findsOneWidget,
      );
      await tester.tap(find.text('기본 배정 저장'));
      await tester.pumpAndSettle();
      expect(writes.single['action'], 'save_crew_allocations');
    },
  );
  testWidgets('revision conflict keeps assignment draft', (tester) async {
    await mount(tester, conflict: true);
    await tester.tap(find.widgetWithText(InputChip, '현우').first);
    await tester.tap(find.text('미배정').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('기본 배정 저장'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(InputChip, '현우'), findsNWidgets(2));
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, '기본 배정 저장'))
          .onPressed,
      isNotNull,
    );
    expect(tester.takeException(), isNull);
  });
  testWidgets('employee calendar shows only own shifts', (tester) async {
    final data = calendar.calendarData();
    data['actor'] = {'id': 'cook', 'role': 'cook'};
    data['staffShifts'] = [
      for (final id in ['cook', 'other'])
        {
          'id': id,
          'tapperId': id,
          'partId': 'kitchen',
          'date': '2026-09-28',
          'start': '09:00',
          'end': '14:00',
        },
    ];
    final ops = await calendar.mount(tester, data: data, readOnly: false);
    // Local demo actor selection remains owner until the actor is selected.
    ops.actorId = 'cook';
    ops.notifyListeners();
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('roster-2026-09-28-kitchen-cook')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('roster-2026-09-28-kitchen-other')),
      findsNothing,
    );
    expect(find.text('전체 파트'), findsNothing);
  });
  testWidgets('month day opens exception editor and submits dated override', (
    tester,
  ) async {
    Json? sent;
    await calendar.mount(tester, readOnly: false, write: (v) => sent = v);
    await tester.tap(find.widgetWithText(ChoiceChip, '월간'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('28').last);
    await tester.pumpAndSettle();
    expect(find.text('추가 휴무일'), findsOneWidget);
    await tester.tap(find.text('추가 업무일'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('일정 저장'));
    await tester.pumpAndSettle();
    expect(sent?['action'], 'save_calendar_day');
    expect(sent?['date'], '2026-09-28');
    expect(sent?['mode'], 'open');
    expect(sent?['weekday'], 1);
    expect(sent?['revision'], 12);
  });
}
