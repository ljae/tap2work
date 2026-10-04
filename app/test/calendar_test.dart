import 'package:flutter/cupertino.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:tap2work/domain/part_schedule.dart';
import 'package:tap2work/state/operations_controller.dart';
import 'package:tap2work/ui/calendar_screen.dart';
import 'operations_test.dart' show sample, response;

Json calendarData() => {
  ...sample(),
  'revision': 12,
  'day': '2026-09-28',
  'actor': {'id': 'owner', 'role': 'owner', 'name': '사장'},
  'workplace': {
    'parts': [
      {'id': 'kitchen', 'name': '주방'},
      {'id': 'hall', 'name': '홀'},
      {'id': 'management', 'name': '관리'},
    ],
    'days': {
      for (var d = 1; d <= 7; d++)
        '$d': [
          {
            'id': 'day-$d',
            'name': '오픈',
            'start': '09:00',
            'end': '14:00',
            'headcounts': {'kitchen': 1, 'hall': 0, 'management': 0},
          },
        ],
    },
  },
  'rosterTemplates': [
    for (var d = 1; d <= 7; d++)
      for (final p in ['kitchen', 'hall', 'management'])
        {
          'id': 'band-$d-$p-0',
          'weekday': d,
          'partId': p,
          'name': '오픈',
          'start': '09:00',
          'end': '14:00',
        },
  ],
  'tappers': [
    {
      'id': 'cook',
      'actorId': 'cook',
      'nickname': '현우',
      'active': true,
      'workProfile': {
        'partIds': ['kitchen'],
      },
    },
  ],
  'staffShifts': [],
};
Future<OperationsController> mount(
  WidgetTester tester, {
  bool readOnly = true,
  Json? data,
  void Function(Json)? write,
  double width = 390,
  double scale = 1,
  bool timeline = true,
}) async {
  tester.view.physicalSize = Size(width, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final ops = OperationsController(
    readOnly: readOnly,
    client: MockClient((r) async {
      if (r.method == 'POST') write?.call(jsonDecode(r.body) as Json);
      return response(data ?? calendarData());
    }),
  );
  addTearDown(ops.dispose);
  await ops.refresh();
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: MediaQuery(
          data: MediaQueryData(
            size: Size(width, 1400),
            disableAnimations: tester
                .platformDispatcher
                .accessibilityFeatures
                .disableAnimations,
            textScaler: TextScaler.linear(scale),
          ),
          child: SingleChildScrollView(child: CalendarScreen(operations: ops)),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return ops;
}

void main() {
  for (final width in [320.0, 390.0, 1200.0]) {
    testWidgets(
      'closed days hide timeline; exceptional opening restores it at $width',
      (tester) async {
        final data = calendarData();
        data['workplace']['days']['1'] = <Map<String, Object>>[];
        final ops = await mount(
          tester,
          data: data,
          width: width,
          readOnly: false,
        );
        expect(find.byKey(const ValueKey('roster-closed-day')), findsOneWidget);
        expect(find.byKey(const ValueKey('roster-time-axis')), findsNothing);
        data['workplace']['dateOverrides'] = {
          '2026-09-28': {'closed': false, 'weekday': 2},
        };
        await ops.refresh();
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('roster-closed-day')), findsNothing);
        expect(find.byKey(const ValueKey('roster-time-axis')), findsOneWidget);
        data['workplace']['dateOverrides'] = {
          '2026-09-28': {'closed': true},
        };
        await ops.refresh();
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('roster-closed-day')), findsOneWidget);
        expect(find.byKey(const ValueKey('roster-time-axis')), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final width in [320.0, 390.0, 1200.0]) {
    testWidgets('part cards switch selected date without writes at $width', (
      tester,
    ) async {
      var writes = 0;
      await mount(
        tester,
        width: width,
        scale: 1.5,
        timeline: false,
        write: (_) => writes++,
      );
      expect(find.byKey(const ValueKey('roster-time-axis')), findsOneWidget);
      expect(find.text('미배정'), findsNothing);
      expect(find.widgetWithText(ChoiceChip, '시간표'), findsNothing);
      expect(find.widgetWithText(ChoiceChip, '전체 파트'), findsNothing);
      await tester.tap(find.byKey(const ValueKey('roster-day-2026-09-29')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('roster-time-axis')), findsOneWidget);
      expect(writes, 0);
      expect(tester.takeException(), isNull);
    });
  }

  for (final width in [320.0, 390.0, 1200.0]) {
    testWidgets(
      'fixed time axis, weekday parts and month fit $width with enlarged text',
      (tester) async {
        var writes = 0;
        await mount(tester, width: width, scale: 1.5, write: (_) => writes++);
        final axis = find.byKey(const ValueKey('roster-time-axis'));
        expect(tester.getSize(axis).width, 52);
        final origin = tester.getTopLeft(axis);
        expect(find.text('9/28 월'), findsWidgets);
        final scroll =
            find
                    .byType(SingleChildScrollView)
                    .evaluate()
                    .where(
                      (e) =>
                          (e.widget as SingleChildScrollView).scrollDirection ==
                          Axis.horizontal,
                    )
                    .last
                    .widget
                as SingleChildScrollView;
        scroll.controller!.jumpTo(500);
        await tester.pumpAndSettle();
        expect(tester.getTopLeft(axis), origin);
        expect(find.text('주방'), findsWidgets);
        expect(find.text('홀'), findsWidgets);
        await tester.tap(find.widgetWithText(ChoiceChip, '월간'));
        await tester.pumpAndSettle();
        expect(find.text('2026년 9월'), findsOneWidget);
        expect(tester.takeException(), isNull);
        expect(writes, 0);
      },
    );
  }
  testWidgets(
    'assigned shift saves per-date time adjustment with opening revision',
    (tester) async {
      Json? sent;
      final data = calendarData();
      data['staffShifts'] = [
        {
          'id': 'assigned',
          'tapperId': 'cook',
          'date': '2026-09-28',
          'partId': 'kitchen',
          'start': '09:00',
          'end': '14:00',
        },
      ];
      final ops = await mount(
        tester,
        data: data,
        readOnly: false,
        timeline: false,
        write: (v) => sent = v,
      );
      await tester.tap(
        find.byKey(const ValueKey('roster-2026-09-28-kitchen-assigned')),
      );
      await tester.pumpAndSettle();
      ops.data!['revision'] = 99;
      await tester.tap(find.text('시작 시간 09:00'));
      await tester.pumpAndSettle();
      tester
          .widget<CupertinoPicker>(find.byType(CupertinoPicker).first)
          .scrollController!
          .jumpToItem(10);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, '적용'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, '저장'));
      await tester.pumpAndSettle();
      expect(sent!['action'], 'save_staff_shift');
      expect(sent!['start'], '10:00');
      expect(sent!['partId'], 'kitchen');
      expect(sent!['date'], '2026-09-28');
      expect(sent!['revision'], 12);
      expect(tester.takeException(), isNull);
    },
  );
  test(
    'derived slots preserve overrides and overnight original dates without changing inputs',
    () {
      final data = calendarData();
      data['rosterOverrides'] = [
        {
          'date': '2026-09-28',
          'partId': 'kitchen',
          'templateId': 'removed-template',
          'name': '조정',
          'start': '22:00',
          'end': '02:00',
        },
      ];
      data['staffShifts'] = [
        {
          'id': 'night',
          'date': '2026-09-28',
          'partId': 'hall',
          'tapperId': 'cook',
          'start': '23:00',
          'end': '03:00',
        },
      ];
      final before = jsonEncode(data);
      final slots = slotsForDay(data, DateTime(2026, 9, 28), const [
        WorkPart('kitchen', '주방'),
        WorkPart('hall', '홀'),
      ]);
      final night = slots.firstWhere((s) => s.shiftId == 'night');
      expect(night.date, '2026-09-28');
      expect(night.endMinute, 1620);
      expect(night.overnight, isTrue);
      expect(
        slots.firstWhere((s) => s.templateId == 'removed-template').adjusted,
        isTrue,
      );
      expect(jsonEncode(data), before);
    },
  );
}
