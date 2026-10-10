import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:tap2work/domain/attendance_history.dart';
import 'package:tap2work/state/operations_controller.dart';
import 'package:tap2work/ui/team_screen.dart';
import 'package:tap2work/ui/workplace_screens.dart';
import 'calendar_test.dart' show calendarData, mount;
import 'operations_test.dart' show response;

Json event(String type, String at, {String crew = 'c', bool voided = false}) =>
    {
      'tapperId': crew,
      'type': type,
      'at': at,
      if (voided) 'voidedAt': '2026-09-28T00:00:00Z',
    };

void main() {
  test(
    'sessions keep overnight, breaks, corrections, missing and orphan records',
    () {
      final sessions = attendanceSessions([
        event('clock_out', '2026-09-22T01:00:00Z'),
        event('clock_in', '2026-09-21T14:00:00Z'),
        event('break_start', '2026-09-21T16:00:00Z'),
        event('break_end', '2026-09-21T16:30:00Z'),
        event('clock_out', '2026-09-21T20:00:00Z', voided: true),
        event('clock_in', '2026-09-22T14:00:00Z'),
        event('clock_in', '2026-09-23T14:00:00Z'),
        event('clock_out', '2026-09-21T04:00:00Z', crew: 'orphan'),
      ]);
      expect(sessions.length, 4);
      expect(sessions.first.hasClockIn, false);
      final overnight = sessions[1];
      expect(overnight.day.day, 21);
      expect(overnight.events.length, 4);
      expect(overnight.hasClockOut, true);
      expect(koreanAttendanceTime(overnight.events.last['at']).day, 22);
      expect(sessions[2].hasClockOut, false);
      expect(sessions[3].hasClockOut, false);
    },
  );

  for (final width in [320.0, 390.0, 1200.0]) {
    testWidgets('past is actual history and today stays planned at $width', (
      tester,
    ) async {
      final data = calendarData();
      data['attendance'] = [
        event('clock_in', '2026-09-21T00:00:00Z'),
        event('clock_out', '2026-09-21T05:00:00Z'),
        event('clock_in', '2026-09-21T07:00:00Z'),
      ];
      var writes = 0;
      await mount(
        tester,
        width: width,
        scale: 1.5,
        data: data,
        write: (_) => writes++,
      );
      await tester.tap(find.byTooltip('이전'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('attendance-history')), findsOneWidget);
      expect(find.text('09:00'), findsOneWidget);
      expect(find.text('14:00'), findsOneWidget);
      expect(find.text('퇴근 미기록'), findsOneWidget);
      expect(find.byKey(const ValueKey('roster-time-axis')), findsNothing);
      await tester.tap(find.byKey(const ValueKey('roster-day-2026-09-22')));
      await tester.pumpAndSettle();
      expect(find.text('기록된 출퇴근 이력이 없어요.'), findsOneWidget);
      await tester.ensureVisible(find.text('오늘'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('오늘'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('attendance-history')), findsNothing);
      expect(find.byKey(const ValueKey('roster-time-axis')), findsOneWidget);
      expect(writes, 0);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'registration omits part and band, details link opens staffing table',
    (tester) async {
      tester.view.physicalSize = const Size(1000, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final writes = <Json>[];
      final ops = OperationsController(
        client: MockClient((r) async {
          if (r.method == 'POST') writes.add(jsonDecode(r.body));
          return response({
            ...calendarData(),
            'nationalityOptions': [
              {'code': 'VN', 'name': '베트남'},
              {'code': 'KR', 'name': '대한민국'},
            ],
          });
        }),
      );
      addTearDown(ops.dispose);
      await ops.refresh();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(child: TeamScreen(operations: ops)),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('크루 등록'));
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find.byType(StatefulBuilder),
          matching: find.byType(FilterChip),
        ),
        findsNothing,
      );
      await tester.enterText(find.byType(TextField).first, '새 크루');
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<FilledButton>(find.widgetWithText(FilledButton, '저장'))
            .onPressed,
        isNull,
      );
      await tester.tap(find.byKey(const ValueKey('crew-nationality')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('베트남').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('crew-guide-language')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('English').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('저장'));
      await tester.pumpAndSettle();
      expect(writes.single['action'], 'save_tapper');
      expect(writes.single['nationality'], 'VN');
      expect(writes.single['guideLocale'], 'en');
      expect(writes.single.containsKey('partIds'), false);
      expect(writes.single.containsKey('bands'), false);
      await tester.tap(find.text('현우').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('크루 배정'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('staffing-matrix')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('auto attendance method is a saved preference, not activation', (
    tester,
  ) async {
    final writes = <Json>[];
    final data = calendarData();
    data['workplace']['attendancePreferences'] = {
      'method': 'wifi',
      'status': 'not_connected',
    };
    final ops = OperationsController(
      client: MockClient((r) async {
        if (r.method == 'POST') writes.add(jsonDecode(r.body));
        return response(data);
      }),
    );
    addTearDown(ops.dispose);
    await ops.refresh();
    await tester.pumpWidget(
      MaterialApp(
        home: WorkplaceSettings(ops: ops, section: 'verification'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('매장 Wi-Fi 연결'), findsOneWidget);
    await tester.tap(find.text('매장 도착 위치').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('저장'));
    await tester.pumpAndSettle();
    expect(writes.single['action'], 'save_attendance_preferences');
    expect(writes.single['method'], 'location');
    expect(writes.single.containsKey('enabled'), false);
  });
}
