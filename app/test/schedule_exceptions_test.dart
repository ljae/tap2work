import 'package:tap2work/ui/time_wheel.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:tap2work/state/operations_controller.dart';
import 'package:tap2work/ui/crew_pattern_screen.dart';
import 'package:tap2work/ui/shift_change_panel.dart';
import 'package:tap2work/ui/shift_replacement_sheet.dart';
import 'calendar_test.dart' show calendarData;
import 'operations_test.dart' show response;

void main() {
  testWidgets(
    'partial OFF form sends selected interval, retains draft on conflict',
    (tester) async {
      final data = calendarData();
      data['staffShifts'] = [
        {
          'id': 'own',
          'tapperId': 'cook',
          'date': '2026-10-05',
          'partId': 'kitchen',
          'timeBandId': 'mon',
          'start': '09:00',
          'end': '18:00',
          'status': 'planned',
        },
      ];
      Json? written;
      final ops = OperationsController(
        readOnly: false,
        client: MockClient((r) async {
          if (r.method == 'POST') {
            written = jsonDecode(r.body) as Json;
            return response({'error': '근무가 바뀌었어요.'}, 409);
          }
          return response(data);
        }),
      );
      addTearDown(ops.dispose);
      await ops.refresh();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (c) => TextButton(
                onPressed: () => requestShiftChange(c, ops, 'own'),
                child: const Text('열기'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('열기'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('일부 시간 OFF'));
      await tester.pumpAndSettle();
      final fields = find.byType(AppTimeField);
      (tester.widget<AppTimeField>(fields.at(0))).onChanged!('12:00');
      (tester.widget<AppTimeField>(fields.at(1))).onChanged!('14:00');
      await tester.pump();
      await tester.enterText(find.byType(TextField), '개인 일정');
      await tester.tap(find.widgetWithText(FilledButton, '신청'));
      await tester.pumpAndSettle();
      expect(written?['kind'], 'partial_off');
      expect(written?['start'], '12:00');
      expect(written?['end'], '14:00');
      expect(written?['revision'], 12);
      expect(find.text('개인 일정'), findsOneWidget);
      expect(find.textContaining('입력한 내용은 유지돼요.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  for (final width in [320.0, 390.0, 1200.0]) {
    testWidgets(
      'approved vacancy opens eligible crew picker and saves linked replacement at $width',
      (tester) async {
        tester.view.physicalSize = Size(width, 1100);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final data = calendarData();
        data['tappers'] = [
          ...(data['tappers'] as List),
          for (final id in ['available', 'busy', 'wrong', 'off'])
            {
              'id': id,
              'nickname': id,
              'active': true,
              'workProfile': {
                'partIds': [id == 'wrong' ? 'hall' : 'kitchen'],
              },
            },
        ];
        final vacancy = {
          'id': 'vacant',
          'date': '2026-10-05',
          'start': '12:00',
          'end': '14:00',
          'partId': 'kitchen',
          'timeBandId': 'mon',
        };
        final request = {
          'id': 'request',
          'tapperId': 'cook',
          'status': 'approved',
          'kind': 'partial_off',
          'before': {'date': '2026-10-05', 'start': '09:00', 'end': '18:00'},
          'segments': [
            {'start': '09:00', 'end': '12:00'},
            {'start': '14:00', 'end': '18:00'},
          ],
          'vacancies': [vacancy],
          'reason': '개인 일정',
        };
        data['shiftChangeRequests'] = [
          request,
          {
            'id': 'other',
            'tapperId': 'off',
            'status': 'approved',
            'kind': 'leave',
            'before': {'date': '2026-10-05', 'start': '12:00', 'end': '14:00'},
            'vacancies': [vacancy],
            'reason': '휴무',
          },
        ];
        data['staffShifts'] = [
          {
            'tapperId': 'busy',
            'date': '2026-10-05',
            'start': '13:00',
            'end': '15:00',
            'status': 'planned',
          },
        ];
        Json? written;
        final ops = OperationsController(
          readOnly: false,
          client: MockClient((r) async {
            if (r.method == 'POST') written = jsonDecode(r.body) as Json;
            return response(data);
          }),
        );
        addTearDown(ops.dispose);
        await ops.refresh();
        expect(
          replacementCandidates(ops, request, vacancy).map((p) => p['id']),
          ['available'],
        );
        await tester.pumpWidget(
          MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(
                size: Size(width, 1100),
                textScaler: const TextScaler.linear(1.5),
              ),
              child: Scaffold(
                body: SingleChildScrollView(child: ShiftChangePanel(ops: ops)),
              ),
            ),
          ),
        );
        await tester.tap(find.text('근무 변경 신청 · 대기 0건'));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('대체 크루 배정').last);
        await tester.tap(find.text('대체 크루 배정').last);
        await tester.pumpAndSettle();
        await tester.tap(find.text('available'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('대체 배정 저장'));
        await tester.pumpAndSettle();
        expect(written?['action'], 'review_shift_change');
        expect(written?['decision'], 'assign_replacement');
        expect(written?['id'], 'request');
        expect(written?['vacancyId'], 'vacant');
        expect(written?['tapperId'], 'available');
        expect(written?['revision'], 12);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('pattern editor chooses stable time band alongside part', (
    tester,
  ) async {
    final data = calendarData();
    data['workplace'] = <String, dynamic>{
      ...data['workplace'] as Map<String, dynamic>,
    };
    data['workplace']['days'] = {
      '1': [
        {'id': 'mon', 'name': '오전', 'start': '09:00', 'end': '14:00'},
      ],
    };
    Json? written;
    final ops = OperationsController(
      readOnly: false,
      client: MockClient((r) async {
        if (r.method == 'POST') written = jsonDecode(r.body) as Json;
        return response(data);
      }),
    );
    addTearDown(ops.dispose);
    await ops.refresh();
    await tester.pumpWidget(
      MaterialApp(
        home: CrewPatternScreen(ops: ops, day: DateTime(2026, 10, 5)),
      ),
    );
    await tester.tap(find.byTooltip('요일 배정 추가').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('오전 · 09:00–14:00'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, '반영'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('기본 배정 저장'));
    await tester.pumpAndSettle();
    final entry = (written?['entries'] as List).single;
    expect(entry['timeBandId'], 'mon');
    expect(entry['partId'], 'kitchen');
    expect(entry['end'], '14:00');
    expect(tester.takeException(), isNull);
  });
}
