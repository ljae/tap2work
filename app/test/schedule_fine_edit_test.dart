import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tap2work/domain/part_schedule.dart';
import 'package:tap2work/domain/schedule_layout.dart';
import 'package:tap2work/state/operations_controller.dart';
import 'calendar_test.dart' as calendar;

RosterSlot slot(String id, {String start = '09:00', String end = '14:00'}) =>
    RosterSlot(
      date: '2026-09-28',
      partId: 'hall',
      start: start,
      end: end,
      name: id,
      shiftId: id,
    );

void main() {
  test('one to seven concurrent shifts split at most three ways and cycle', () {
    for (var count = 1; count <= 7; count++) {
      final layout = scheduleLayout([
        for (var i = 0; i < count; i++) slot('$i'),
      ]);
      for (var i = 0; i < count; i++) {
        expect(layout['$i'], (lane: i % 3, count: count.clamp(1, 3)));
      }
    }
    final layout = scheduleLayout([
      slot('a'),
      slot('b'),
      slot('c'),
      slot('later', start: '14:00', end: '16:00'),
    ]);
    expect(layout['later'], (lane: 0, count: 1));
  });
  test(
    'preopening assignment stays on selected date despite business boundary',
    () {
      final data = calendar.calendarData();
      data['workplace']['businessDayStart'] = '09:00';
      data['staffShifts'] = [
        {
          'id': 'early',
          'tapperId': 'cook',
          'partId': 'hall',
          'date': '2026-09-28',
          'businessDate': '2026-09-27',
          'scheduleDate': '2026-09-28',
          'dayOffset': 0,
          'start': '07:00',
          'end': '10:00',
        },
      ];
      final shifts = slotsForDay(data, DateTime(2026, 9, 28), [
        const WorkPart('hall', '홀'),
      ]);
      expect(shifts.firstWhere((s) => s.shiftId == 'early').startMinute, 420);
    },
  );
  for (final width in [320.0, 390.0, 1200.0]) {
    testWidgets(
      'overlap display, hours/break markers and additional crew at $width',
      (tester) async {
        final data = calendar.calendarData();
        data['workplace']['breaks'] = {
          '1': {'start': '12:00', 'end': '13:00'},
        };
        data['staffShifts'] = [
          for (var i = 0; i < 7; i++)
            {
              'id': 's$i',
              'tapperId': 'cook',
              'partId': 'hall',
              'date': '2026-09-28',
              'start': '09:00',
              'end': '14:00',
              'label': '크루 $i',
            },
        ];
        Json? sent;
        await calendar.mount(
          tester,
          write: (v) => sent = v,
          data: data,
          readOnly: false,
          width: width,
          scale: 1.5,
        );
        expect(find.byKey(const ValueKey('roster-break-hall')), findsOneWidget);
        expect(
          find.byKey(const ValueKey('roster-hours-hall-영업 시작')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('roster-hours-hall-영업 종료')),
          findsOneWidget,
        );
        final rects = [
          for (var i = 0; i < 7; i++)
            tester.getRect(find.byKey(ValueKey('roster-2026-09-28-hall-s$i'))),
        ];
        expect(rects[0].width, closeTo(rects[1].width, .001));
        expect(rects[0].left, rects[3].left);
        expect(rects[1].left, rects[4].left);
        expect(rects[2].left, rects[5].left);
        expect(rects[0].left, rects[6].left);
        await tester.ensureVisible(
          find.byKey(const ValueKey('calendar-add-crew')),
        );
        await tester.tap(find.byKey(const ValueKey('calendar-add-crew')));
        await tester.pumpAndSettle();
        expect(find.text('크루 추가 배정'), findsOneWidget);
        await tester.tap(find.text('담당 파트').last);
        await tester.pumpAndSettle();
        await tester.tap(find.text('홀').last);
        await tester.pumpAndSettle();
        // Only registered crew belongs to kitchen, but is still offered for hall.
        await tester.tap(find.text('담당 크루').last);
        await tester.pumpAndSettle();
        expect(find.text('현우'), findsWidgets);
        await tester.tap(find.text('현우').last);
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(FilledButton, '저장'));
        await tester.pumpAndSettle();
        expect(sent?['action'], 'save_staff_shift');
        expect(sent?['partId'], 'hall');
        expect(sent?['tapperId'], 'cook');
        expect(sent?['id'], isNull);
        expect(sent?['revision'], 12);
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets(
    'second hall lane previews its actual width and saves across parts',
    (tester) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      final data = calendar.calendarData();
      data['staffShifts'] = [
        for (var i = 0; i < 2; i++)
          {
            'id': 's$i',
            'tapperId': 'cook',
            'partId': 'hall',
            'date': '2026-09-28',
            'start': '09:00',
            'end': '14:00',
          },
      ];
      Json? sent;
      await calendar.mount(
        tester,
        data: data,
        readOnly: false,
        width: 1200,
        write: (v) => sent = v,
      );
      final source = find.byKey(const ValueKey('roster-2026-09-28-hall-s1'));
      await tester.longPress(source);
      await tester.pumpAndSettle();
      final rect = tester.getRect(source);
      final gesture = await tester.startGesture(
        Offset(rect.center.dx, rect.top + 35),
      );
      await gesture.moveBy(const Offset(0, 25));
      await tester.pump();
      final preview = find.byKey(const ValueKey('roster-drop-preview'));
      expect(preview, findsOneWidget);
      expect(tester.getSize(preview).width, closeTo(rect.width, 1));
      expect(tester.getTopLeft(preview).dx, closeTo(rect.left, 1));
      final target = find.byKey(
        const ValueKey('roster-drop-2026-09-28-kitchen-480'),
      );
      await gesture.moveTo(tester.getCenter(target));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();
      expect(sent, isNull);
      await tester.tap(find.text('오늘'));
      await tester.pumpAndSettle();
      expect(sent?['partId'], 'kitchen');
      expect(sent?['start'], '08:00');
      expect(sent?['scheduleDate'], '2026-09-28');
      expect(sent?['dayOffset'], 0);
      await tester.tap(find.text('24시간 보기'));
      await tester.pumpAndSettle();
      await tester.longPress(source);
      await tester.pumpAndSettle();
      final targetColumn = find.byType(DragTarget<Json>).first;
      final payload = tester
          .widget<Draggable<Json>>(find.byType(Draggable<Json>).last)
          .data!;
      final details = DragTargetDetails<Json>(
        data: payload,
        offset:
            tester.getTopLeft(targetColumn) + const Offset(10, 21 * 60 * .8),
      );
      tester.widget<DragTarget<Json>>(targetColumn).onMove!(details);
      await tester.pumpAndSettle();
      tester.widget<DragTarget<Json>>(targetColumn).onAcceptWithDetails!(
        details,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('오늘'));
      await tester.pumpAndSettle();
      expect(sent?['start'], '21:00');
      expect(sent?['end'], '02:00');
      expect(sent?['dayOffset'], 0);
      expect(tester.takeException(), isNull);
    },
  );
}
