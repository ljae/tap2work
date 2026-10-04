import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:tap2work/state/operations_controller.dart';
import 'package:tap2work/ui/labor_panel.dart';
import 'package:tap2work/ui/calendar_screen.dart';
import 'operations_test.dart' show response;
import 'calendar_test.dart' show calendarData;

void main() {
  testWidgets('pay review retains inputs on revision conflict', (tester) async {
    tester.view.physicalSize = const Size(390, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    Json? sent;
    final ops = OperationsController(
      client: MockClient((r) async {
        if (r.method == 'POST') {
          sent = jsonDecode(r.body) as Json;
          return http.Response(
            jsonEncode({'error': '다른 변경이 있어요. 다시 확인해 주세요.'}),
            409,
            headers: {'content-type': 'application/json'},
          );
        }
        return response(calendarData());
      }),
    );
    addTearDown(ops.dispose);
    await ops.refresh();
    final revision = ops.data!['revision'];
    await tester.pumpWidget(
      MaterialApp(
        home: LaborReviewEditor(
          ops: ops,
          week: '2026-09-21',
          person: {
            'tapperId': 'cook',
            'nickname': '현우',
            'hourlyWon': 12000,
            'review': {
              'scope': 'standard',
              'size': 'fivePlus',
              'averageWeeklyMinutes': 2400,
              'restMinutes': 480,
              'attendance': 'met',
              'holidaysConfirmed': true,
            },
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('이번 주 조건 저장'),
      450,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('이번 주 조건 저장'));
    await tester.pumpAndSettle();
    expect(sent!['revision'], revision);
    expect(sent!['review']['restMinutes'], 480);
    expect(find.byType(LaborReviewEditor), findsOneWidget);
    expect(find.textContaining('다른 변경'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  for (final width in [320.0, 390.0, 1200.0]) {
    testWidgets('weekly capacity and pay details fit $width', (tester) async {
      tester.view.physicalSize = Size(width, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final data = calendarData();
      data['day'] = '2026-09-21';
      data['rosterTemplates'] = [
        {
          'id': 'slot-0',
          'weekday': 1,
          'partId': 'kitchen',
          'name': '오픈',
          'duty': '조리',
          'start': '09:00',
          'end': '18:00',
        },
        {
          'id': 'slot-1',
          'weekday': 1,
          'partId': 'kitchen',
          'name': '오픈',
          'duty': '조리',
          'start': '09:00',
          'end': '18:00',
        },
      ];
      data['staffShifts'] = [
        {
          'id': 'a',
          'tapperId': 'cook',
          'duty': '조리',
          'date': '2026-09-21',
          'start': '09:00',
          'end': '18:00',
          'status': 'planned',
        },
      ];
      final estimate = {
        'baseWon': 90000,
        'totalWon': null,
        'extensionWon': null,
        'nightWon': null,
        'holidayWon': null,
        'weeklyRestWon': null,
        'paidHolidayWon': null,
        'workedMinutes': 540,
        'overtimeMinutes': 60,
        'nightMinutes': 0,
        'alerts': ['계산 조건을 설정해 주세요.'],
      };
      data['labor'] = {
        'weeks': [
          {
            'week': '2026-09-21',
            'people': [
              {
                'tapperId': 'cook',
                'nickname': '현우',
                'hourlyWon': 10000,
                'planned': estimate,
                'actual': estimate,
              },
            ],
          },
        ],
      };
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
      expect(find.text('파트별'), findsNothing);
      expect(find.byKey(const ValueKey('roster-time-axis')), findsOneWidget);
      // One cook cannot fulfill two simultaneous requirements.
      expect(find.textContaining('미배정'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(child: LaborPanel(ops: ops)),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('계산 조건 1명 확인 필요'), findsOneWidget);
      await tester.tap(find.text('현우'));
      await tester.pumpAndSettle();
      expect(find.text('주간 확인 목록'), findsOneWidget);
      expect(find.text('주휴수당'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
