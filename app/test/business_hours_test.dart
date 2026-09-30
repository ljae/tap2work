import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tap2work/ui/time_wheel.dart';
import 'package:tap2work/ui/hours_timetable.dart';
import 'package:tap2work/domain/part_schedule.dart';

void main() {
  testWidgets(
    'wheel requires apply, cancels draft and returns exact half hour',
    (tester) async {
      String value = '09:00';
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (c) => TextButton(
                onPressed: () async {
                  value =
                      await showTimeWheel(c, title: '시작 시간', value: value) ??
                      value;
                },
                child: const Text('열기'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('열기'));
      await tester.pumpAndSettle();
      tester
          .widget<CupertinoPicker>(find.byType(CupertinoPicker).first)
          .scrollController!
          .jumpToItem(23);
      tester
          .widget<CupertinoPicker>(find.byType(CupertinoPicker).last)
          .scrollController!
          .jumpToItem(1);
      await tester.pumpAndSettle();
      await tester.tap(find.text('취소'));
      await tester.pumpAndSettle();
      expect(value, '09:00');
      await tester.tap(find.text('열기'));
      await tester.pumpAndSettle();
      tester
          .widget<CupertinoPicker>(find.byType(CupertinoPicker).first)
          .scrollController!
          .jumpToItem(23);
      tester
          .widget<CupertinoPicker>(find.byType(CupertinoPicker).last)
          .scrollController!
          .jumpToItem(1);
      await tester.pumpAndSettle();
      await tester.tap(find.text('적용'));
      await tester.pumpAndSettle();
      expect(value, '23:30');
      expect(tester.takeException(), isNull);
    },
  );
  for (final width in [320.0, 390.0, 1200.0]) {
    testWidgets('timetable independent resize and readable large text $width', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final days = <String, dynamic>{
        for (var d = 1; d <= 7; d++)
          '$d': d == 1
              ? [
                  {
                    'id': 'a',
                    'name': '오픈',
                    'start': '09:00',
                    'end': '11:00',
                    'headcounts': {'kitchen': 1},
                  },
                  {
                    'id': 'b',
                    'name': '미들',
                    'start': '10:00',
                    'end': '12:00',
                    'headcounts': {'kitchen': 1},
                  },
                ]
              : <Map<String, dynamic>>[],
      };
      List<dynamic>? changed;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MediaQuery(
              data: MediaQueryData(
                textScaler: TextScaler.linear(1.5),
                size: Size(width, 900),
              ),
              child: HoursTimetable(
                days: days,
                parts: const [
                  {'id': 'kitchen', 'name': '주방'},
                ],
                partId: null,
                boundary: '06:00',
                editable: true,
                onChange: (d, id, s, e) => changed = [d, id, s, e],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('오픈'), findsOneWidget);
      final handle = find.bySemanticsLabel('오픈 시작 시간 조정');
      await tester.drag(handle, const Offset(0, 48));
      await tester.pumpAndSettle();
      expect(changed, [1, 'a', '09:30', '11:00']);
      expect(days['1'][1]['start'], '10:00');
      expect(tester.takeException(), isNull);
    });
  }
  test(
    'business-day roster retains actual date and counts next morning coverage',
    () {
      final data = <String, dynamic>{
        'workplace': {'businessDayStart': '06:00'},
        'rosterTemplates': [
          {
            'id': 'band',
            'weekday': 3,
            'partId': 'kitchen',
            'name': '야간',
            'start': '01:00',
            'end': '03:00',
          },
        ],
        'staffShifts': [
          {
            'id': 's',
            'date': '2026-10-01',
            'businessDate': '2026-09-30',
            'partId': 'kitchen',
            'tapperId': 'a',
            'start': '01:00',
            'end': '03:00',
            'status': 'planned',
          },
        ],
        'tappers': [
          {'id': 'a', 'nickname': '크루'},
        ],
      };
      final slots = slotsForDay(data, DateTime(2026, 9, 30), const [
        WorkPart('kitchen', '주방'),
      ]);
      expect(slots.single.date, '2026-09-30');
      expect(slots.single.actualDate, '2026-10-01');
      expect(slots.single.startMinute, 1500);
      expect(
        rosterCoverage(data, DateTime(2026, 9, 28), const [
          WorkPart('kitchen', '주방'),
        ]),
        (needed: 120, covered: 120),
      );
    },
  );
}
