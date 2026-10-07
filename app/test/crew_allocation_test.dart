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
  Json? initialData,
}) async {
  tester.view.physicalSize = Size(width, 1200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final data = initialData ?? calendar.calendarData();
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
    testWidgets('touch time block saves crew and stable band once at $size', (
      tester,
    ) async {
      Json? sent;
      await mount(
        tester,
        width: size.$1,
        scale: size.$2,
        write: (v) => sent = v,
      );

      final cell = find.byKey(const ValueKey('empty-normal-오픈-kitchen-0'));
      await tester.ensureVisible(cell);
      await tester.pumpAndSettle();
      await tester.tap(cell);
      await tester.pumpAndSettle();
      expect(find.text('예상 5/15h'), findsOneWidget);
      await tester.tap(find.text('현우').last);
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
  testWidgets('multiple weekdays use touch sheet and one atomic save', (
    tester,
  ) async {
    Json? sent;
    await mount(tester, write: (v) => sent = v);
    await tester.tap(find.byKey(const ValueKey('scope-day-3')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('empty-normal-오픈-kitchen-0')));
    await tester.pumpAndSettle();
    expect(find.text('예상 10/15h'), findsOneWidget);
    await tester.tap(find.text('현우').last);
    await tester.pumpAndSettle();
    expect(find.byType(Table), findsNothing);
    expect(find.byType(LongPressDraggable<Json>), findsNothing);
    expect(find.text('미배정'), findsNothing);
    await tester.tap(find.text('기본 배정 저장'));
    await tester.pumpAndSettle();
    expect((sent!['patterns'][0]['entries'] as List).map((e) => e['weekday']), [
      1,
      3,
    ]);
  });
  testWidgets(
    'previous schedule is ghost until confirmed and retained on conflict',
    (tester) async {
      final data = calendar.calendarData();
      data['crewPatterns'] = [
        {
          'tapperId': 'cook',
          'anchor': '2026-09-28',
          'cycleWeeks': 1,
          'hoursVersion': 0,
          'entries': <Json>[],
          'previous': {
            'anchor': '2026-09-28',
            'cycleWeeks': 1,
            'entries': [
              {
                'week': 0,
                'weekday': 1,
                'partId': 'kitchen',
                'timeBandId': 'day-1',
                'start': '09:00',
                'end': '14:00',
              },
            ],
          },
        },
      ];
      final writes = <Json>[];
      await mount(tester, initialData: data, conflict: true, write: writes.add);
      await tester.tap(find.text('이전 스케줄 불러오기'));
      await tester.pumpAndSettle();
      expect(writes, isEmpty);
      expect(find.widgetWithText(ActionChip, '현우'), findsOneWidget);
      await tester.tap(find.text('배정 확정'));
      await tester.pumpAndSettle();
      expect(writes.single['patterns'][0]['entries'], hasLength(1));
      expect(find.text('배정 확정'), findsOneWidget);
      await tester.tap(find.text('미리보기 취소'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(ActionChip, '현우'), findsNothing);
    },
  );
  testWidgets('revision conflict keeps assignment draft', (tester) async {
    await mount(tester, conflict: true);
    await tester.tap(find.byKey(const ValueKey('empty-normal-오픈-kitchen-0')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('현우').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('기본 배정 저장'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(ActionChip, '현우'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, '기본 배정 저장'))
          .onPressed,
      isNotNull,
    );
    expect(tester.takeException(), isNull);
  });
  for (final closed in [true, false]) {
    testWidgets('monthly default and no-op guard for closed=$closed', (
      tester,
    ) async {
      final data = calendar.calendarData();
      if (closed) data['workplace']['days']['1'] = <Map<String, Object>>[];
      final writes = <Json>[];
      await calendar.mount(
        tester,
        data: data,
        readOnly: false,
        write: writes.add,
      );
      await tester.ensureVisible(find.widgetWithText(TextButton, '월간'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, '월간'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('28').last);
      await tester.pumpAndSettle();
      final expected = closed ? '추가 영업일 지정' : '추가 휴무일 지정';
      expect(
        tester
            .widget<ListTile>(find.widgetWithText(ListTile, expected))
            .selected,
        true,
      );
      await tester.tap(find.text(closed ? '추가 휴무일 지정' : '추가 영업일 지정'));
      await tester.tap(find.text('일정 저장'));
      await tester.pumpAndSettle();
      expect(writes, isEmpty);
      expect(
        find.text(closed ? '이미 휴무일이에요. 변경하지 않았어요.' : '이미 영업일이에요. 변경하지 않았어요.'),
        findsOneWidget,
      );
      await tester.tap(find.text(expected));
      await tester.tap(find.text('일정 저장'));
      await tester.pumpAndSettle();
      expect(writes.single['mode'], closed ? 'open' : 'closed');
    });
  }
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
    await tester.ensureVisible(find.widgetWithText(TextButton, '월간'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, '월간'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('28').last);
    await tester.pumpAndSettle();
    expect(find.text('추가 휴무일 지정'), findsOneWidget);

    await tester.tap(find.text('일정 저장'));
    await tester.pumpAndSettle();
    expect(sent?['action'], 'save_calendar_day');
    expect(sent?['date'], '2026-09-28');
    expect(sent?['mode'], 'closed');
    expect(sent?['revision'], 12);
  });
}
