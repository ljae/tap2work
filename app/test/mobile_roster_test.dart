import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'calendar_test.dart' as calendar;

void main() {
  testWidgets(
    'month shows past work and future open plans without history counts',
    (tester) async {
      await calendar.mount(tester, readOnly: false);
      await tester.tap(find.widgetWithText(ChoiceChip, '월간'));
      await tester.pumpAndSettle();
      expect(find.text('업무'), findsWidgets);
      expect(find.text('영업'), findsWidgets);
      expect(find.textContaining('이력 '), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  for (final width in [320.0, 390.0]) {
    testWidgets(
      'four crew fit without horizontal slide and axis scroll reaches dates at $width',
      (tester) async {
        final data = calendar.calendarData();
        data['staffShifts'] = [
          for (var i = 0; i < 4; i++)
            {
              'id': 'phone-$i',
              'tapperId': 'person-$i',
              'partId': ['kitchen', 'hall', 'hall', 'management'][i],
              'date': '2026-09-28',
              'start': '06:00',
              'end': '23:00',
              'label': ['현우', '지우', '민지', '이재훈'][i],
            },
        ];
        await calendar.mount(tester, data: data, readOnly: false, width: width);
        tester.view.physicalSize = Size(width, 700);
        await tester.pumpAndSettle();
        final rects = [
          for (var i = 0; i < 4; i++)
            tester.getRect(
              find.byKey(
                ValueKey(
                  'roster-2026-09-28-${['kitchen', 'hall', 'hall', 'management'][i]}-phone-$i',
                ),
              ),
            ),
        ];
        for (final rect in rects) {
          expect(rect.left, greaterThanOrEqualTo(36));
          expect(rect.right, lessThanOrEqualTo(width));
          expect(rect.width, closeTo(rects.first.width, .01));
        }
        expect(find.text('6시'), findsOneWidget);
        expect(find.text('-'), findsWidgets);
        expect(find.text('06:30'), findsNothing);
        expect(find.text('주방 크루 추가'), findsNothing);
        final date = find.byKey(const ValueKey('roster-day-2026-09-28'));
        final top = tester.getTopLeft(date).dy;
        await tester.dragFrom(const Offset(18, 500), const Offset(0, -350));
        await tester.pumpAndSettle();
        expect(tester.getTopLeft(date).dy, lessThan(top));
        await tester.dragFrom(const Offset(18, 240), const Offset(0, 600));
        await tester.pumpAndSettle();
        expect(tester.getTopLeft(date).dy, closeTo(top, 1));
        expect(tester.takeException(), isNull);
      },
    );
  }
}
