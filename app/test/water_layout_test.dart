import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:tap2work/state/operations_controller.dart';
import 'package:tap2work/ui/calendar_screen.dart';
import 'package:tap2work/ui/water_search.dart';
import 'calendar_test.dart' show calendarData;
import 'operations_test.dart' show response;

void main() {
  for (final width in [320.0, 1200.0]) {
    testWidgets('date and parts pin below fixed view controls at $width', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final ops = OperationsController(
        readOnly: true,
        client: MockClient((_) async => response(calendarData())),
      );
      addTearDown(ops.dispose);
      await ops.refresh();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MediaQuery(
              data: const MediaQueryData(
                disableAnimations: true,
                textScaler: TextScaler.linear(1.5),
              ),
              child: CalendarScreen(operations: ops, scrollable: true),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final controls = find.byKey(const ValueKey('schedule-header'));
      final date = find.byKey(const ValueKey('roster-date-heading'));
      final part = find.byKey(const ValueKey('roster-part-heading-kitchen'));
      final body = find.byKey(const ValueKey('roster-timeline'));
      final initialControls = tester.getRect(controls);
      final weekly = tester.getRect(find.text('주간'));
      final today = tester.getRect(find.text('오늘'));
      final fullDay = tester.getRect(find.text('24시간 보기'));
      expect(weekly.center.dy, closeTo(today.center.dy, 1));
      expect(fullDay.center.dy, closeTo(today.center.dy, 1));
      expect(tester.getRect(find.text('이전')).left, lessThan(weekly.left));
      expect(tester.getRect(find.text('다음')).right, lessThan(weekly.left));
      final scroll = tester
          .widget<CustomScrollView>(
            find.byKey(const ValueKey('schedule-scroll')),
          )
          .controller!;
      await tester.ensureVisible(find.text('24시간 보기'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('24시간 보기'));
      await tester.pumpAndSettle();
      scroll.jumpTo(400);
      await tester.pumpAndSettle();
      final pinnedDate = tester.getTopLeft(date);
      final pinnedPart = tester.getTopLeft(part);
      final movingBody = tester.getTopLeft(body);
      expect(pinnedDate.dy, closeTo(initialControls.bottom + 4, .1));
      scroll.jumpTo(500);
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(date), pinnedDate);
      expect(tester.getTopLeft(part), pinnedPart);
      expect(tester.getTopLeft(body).dy, closeTo(movingBody.dy - 100, .1));
      expect(tester.getRect(controls), initialControls);
      expect(part.hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('brand search remains functional with reduced motion', (
    tester,
  ) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    String query = '';
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: StatefulBuilder(
              builder: (context, setState) => WaterSearch(
                controller: controller,
                onChanged: (value) => setState(() => query = value),
                onClear: () => setState(() {
                  controller.clear();
                  query = '';
                }),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.enterText(find.byType(TextField), '청소');
    await tester.pumpAndSettle();
    expect(query, '청소');
    await tester.tap(find.byTooltip('검색 지우기'));
    await tester.pumpAndSettle();
    expect(query, isEmpty);
    expect(controller.text, isEmpty);
    expect(tester.takeException(), isNull);
  });
}
