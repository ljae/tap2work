import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:tap2work/domain/korean_holidays.dart';
import 'package:tap2work/state/operations_controller.dart';
import 'package:tap2work/ui/crew_pattern_screen.dart';
import 'package:tap2work/ui/shift_change_panel.dart';
import 'calendar_test.dart' as calendar;
import 'operations_test.dart' show response;

void main() {
  test(
    'holiday cache includes substitute holidays and parses yearly responses',
    () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      final bundled = await KoreanHolidays.bundled();
      expect(bundled['2026-10-05'], contains('대체공휴일'));
      expect(
        KoreanHolidays.parse('{"2026-10-03":["개천절"]}')['2026-10-03'],
        '개천절',
      );
      expect(
        () => KoreanHolidays.parse('{"invalid":["x"]}'),
        throwsFormatException,
      );
    },
  );
  testWidgets('weekly cells create and delete draft entries before saving', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final data = calendar.calendarData();
    final writes = <Json>[];
    final ops = OperationsController(
      readOnly: false,
      client: MockClient((r) async {
        if (r.method == 'POST') writes.add(jsonDecode(r.body) as Json);
        return response(data);
      }),
    );
    addTearDown(ops.dispose);
    await ops.refresh();
    await tester.pumpWidget(
      MaterialApp(
        home: CrewPatternScreen(ops: ops, day: DateTime(2026, 9, 28)),
      ),
    );
    final cell = find.byKey(const ValueKey('crew-cell-2-600'));
    await tester.ensureVisible(cell);
    await tester.tap(cell);
    await tester.pumpAndSettle();
    expect(find.text('화요일 배정'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, '반영'));
    await tester.pumpAndSettle();
    expect(writes, isEmpty);
    expect(find.text('10:00–11:00'), findsOneWidget);
    await tester.tap(find.text('기본 배정 저장'));
    await tester.pumpAndSettle();
    final entry = (writes.single['entries'] as List).single;
    expect(entry['weekday'], 2);
    expect(entry['start'], '10:00');
    expect(entry['end'], '11:00');
    expect(writes.single['revision'], 12);
    await tester.tap(find.text('10:00–11:00'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('배정 삭제'));
    await tester.pumpAndSettle();
    expect(find.text('10:00–11:00'), findsNothing);
    await tester.tap(find.text('기본 배정 저장'));
    await tester.pumpAndSettle();
    expect(writes.last['entries'], isEmpty);
    expect(tester.takeException(), isNull);
  });
  testWidgets('partial vacancy assigns only the uncovered time', (
    tester,
  ) async {
    final data = calendar.calendarData();
    data['staffShifts'] = [
      {
        'id': 'a',
        'tapperId': 'cook',
        'partId': 'kitchen',
        'date': '2026-09-28',
        'start': '09:00',
        'end': '10:00',
      },
    ];
    Json? written;
    await calendar.mount(
      tester,
      data: data,
      readOnly: false,
      width: 1200,
      write: (v) => written = v,
    );
    final gap = find.byKey(
      const ValueKey('roster-2026-09-28-kitchen-band-1-kitchen-0-10:00'),
    );
    await tester.tap(gap);
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, '저장'))
          .onPressed,
      isNull,
    );
    await tester.tap(find.widgetWithText(ChoiceChip, '현우'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, '저장'));
    await tester.pumpAndSettle();
    expect(written?['action'], 'save_staff_shift');
    expect(written?['start'], '10:00');
    expect(written?['end'], '14:00');
    expect(written?['revision'], 12);
    expect(written?['templateId'], isNull);
  });
  testWidgets(
    'drag ghost predicts saved time and resizing keeps opening revision',
    (tester) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      final data = calendar.calendarData();
      data['staffShifts'] = [
        {
          'id': 'resize',
          'tapperId': 'cook',
          'partId': 'kitchen',
          'date': '2026-09-28',
          'start': '09:00',
          'end': '10:00',
          'status': 'planned',
        },
      ];
      final writes = <Json>[];
      await calendar.mount(
        tester,
        data: data,
        readOnly: false,
        width: 1200,
        write: writes.add,
      );
      final source = find.byKey(
        const ValueKey('roster-2026-09-28-kitchen-resize'),
      );
      await tester.longPress(source);
      await tester.pumpAndSettle();
      final handle = find.byKey(const ValueKey('resize-resize-2026-09-28'));
      final resize = await tester.startGesture(tester.getCenter(handle));
      await resize.moveBy(const Offset(0, 48));
      await tester.pump();
      expect(writes, isEmpty);
      await resize.up();
      await tester.pumpAndSettle();
      expect(writes.last['end'], '10:30');
      expect(writes.last['revision'], 12);
      final target = find.byKey(
        const ValueKey('roster-drop-2026-09-28-kitchen-660'),
      );
      final drag = await tester.startGesture(
        tester.getTopLeft(source) + const Offset(25, 20),
      );
      await drag.moveTo(tester.getCenter(target));
      await tester.pump();
      expect(find.byKey(const ValueKey('roster-drop-preview')), findsOneWidget);
      expect(find.textContaining('11:00–12:00'), findsOneWidget);
      expect(writes.length, 1);
      await drag.up();
      await tester.pumpAndSettle();
      expect(writes.last['start'], '11:00');
      expect(tester.takeException(), isNull);
    },
  );
  for (final width in [320.0, 390.0, 1200.0]) {
    testWidgets('crew pattern screen fits $width and saves A/B identifiers', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 1100);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final data = calendar.calendarData();
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
          home: MediaQuery(
            data: MediaQueryData(
              size: Size(width, 1100),
              textScaler: const TextScaler.linear(1.5),
            ),
            child: CrewPatternScreen(ops: ops, day: DateTime(2026, 9, 28)),
          ),
        ),
      );
      await tester.tap(find.text('2주 교대'));
      await tester.pumpAndSettle();
      expect(find.text('A주'), findsOneWidget);
      expect(find.text('B주'), findsOneWidget);
      await tester.tap(find.text('기본 배정 저장'));
      await tester.pumpAndSettle();
      expect(written?['action'], 'save_crew_pattern');
      expect(written?['cycleWeeks'], 2);
      expect(written?['tapperId'], 'cook');
      expect(written?['revision'], 12);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets(
    'employee submits own leave request while pending and approved statuses are distinct',
    (tester) async {
      final data = calendar.calendarData();
      data['staffShifts'] = [
        {
          'id': 'own',
          'tapperId': 'cook',
          'date': '2026-10-05',
          'start': '09:00',
          'end': '18:00',
          'partId': 'kitchen',
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
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (c) => TextButton(
                onPressed: () => requestShiftChange(c, ops, 'own'),
                child: const Text('신청 열기'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('신청 열기'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '개인 일정');
      await tester.tap(find.widgetWithText(FilledButton, '신청'));
      await tester.pumpAndSettle();
      expect(written?['action'], 'request_shift_change');
      expect(written?['kind'], 'leave');
      expect(written?['shiftId'], 'own');
      expect(written?['revision'], 12);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'pending and approved changes show distinct states without altering effective times',
    (tester) async {
      final data = calendar.calendarData();
      final before = {'date': '2026-10-05', 'start': '09:00', 'end': '18:00'};
      data['shiftChangeRequests'] = [
        for (final status in ['pending', 'approved'])
          {
            'id': status,
            'tapperId': 'cook',
            'status': status,
            'kind': 'shorten',
            'before': before,
            'after': {'start': '10:00', 'end': '16:00'},
            'reason': '개인 일정',
          },
      ];
      final ops = OperationsController(
        readOnly: true,
        client: MockClient((_) async => response(data)),
      );
      addTearDown(ops.dispose);
      await ops.refresh();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(child: ShiftChangePanel(ops: ops)),
          ),
        ),
      );
      await tester.tap(find.text('근무 변경 신청 · 대기 1건'));
      await tester.pumpAndSettle();
      expect(find.text('승인 대기 · 기존 근무 유지'), findsOneWidget);
      expect(find.text('승인 완료 · 근무표 반영'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, '승인'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  for (final size in [
    (320.0, 1.0),
    (390.0, 1.0),
    (1200.0, 1.0),
    (320.0, 1.5),
  ]) {
    testWidgets(
      'calendar settings buttons align at $size and open shared hours',
      (tester) async {
        await calendar.mount(
          tester,
          width: size.$1,
          scale: size.$2,
          readOnly: false,
        );
        final crew = find.byKey(const ValueKey('calendar-crew-pattern-button'));
        final hours = find.byKey(const ValueKey('calendar-hours-button'));
        expect(tester.getSize(crew), tester.getSize(hours));
        final a = tester.getRect(crew), b = tester.getRect(hours);
        if (a.top == b.top) {
          expect(b.left - a.right, 8);
        } else {
          expect(a.left, b.left);
          expect(b.top - a.bottom, 8);
        }
        await tester.tap(hours);
        await tester.pumpAndSettle();
        expect(find.text('영업시간·필요 인원'), findsOneWidget);
        expect(find.text('시간설정'), findsOneWidget);
        await tester.tap(find.text('시간설정'));
        await tester.pumpAndSettle();
        expect(find.text('2교대 이상'), findsOneWidget);
        expect(find.text('3교대'), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
