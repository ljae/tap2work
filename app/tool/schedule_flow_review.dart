import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:tap2work/main.dart';
import 'package:tap2work/state/operations_controller.dart';
import 'package:tap2work/state/work_controller.dart';
import 'package:tap2work/ui/calendar_screen.dart';
import 'package:tap2work/ui/crew_allocation_screen.dart';
import 'package:tap2work/ui/workplace_screens.dart';
import '../test/calendar_test.dart' show calendarData;
import '../test/operations_test.dart' show response;
import '../test/work_controller_test.dart' show MemoryStore;

void main() {
  testWidgets('review schedule flow at phone and desktop sizes', (
    tester,
  ) async {
    for (final e in {
      'Pretendard': 'assets/fonts/PretendardVariable.ttf',
      'MaterialIcons': 'fonts/MaterialIcons-Regular.otf',
      'packages/cupertino_icons/CupertinoIcons':
          'packages/cupertino_icons/assets/CupertinoIcons.ttf',
    }.entries) {
      await (FontLoader(e.key)..addFont(rootBundle.load(e.value))).load();
    }
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final data = calendarData();
    data['workplace']['days'] = {
      for (var d = 1; d <= 7; d++)
        '$d': d == 7
            ? []
            : [
                {
                  'id': 'open',
                  'name': '오픈',
                  'start': '06:00',
                  'end': '15:00',
                  'headcounts': {'kitchen': 1, 'hall': 1, 'management': 1},
                },
                {
                  'id': 'close',
                  'name': '마감',
                  'start': '15:00',
                  'end': '22:00',
                  'headcounts': {'kitchen': 1, 'hall': 1, 'management': 0},
                },
              ],
    };
    data['workplace']['breaks'] = {
      '1': {'start': '15:00', 'end': '17:00'},
    };
    data['tappers'] = [
      for (final p in [
        ('cook', '현우', 'kitchen'),
        ('crew', '민지', 'hall'),
        ('manager', '수진', 'management'),
      ])
        {
          'id': p.$1,
          'nickname': p.$2,
          'active': true,
          'workProfile': {
            'partIds': [p.$3],
          },
        },
    ];
    data['staffShifts'] = [
      for (final p in [
        ('cook', 'kitchen'),
        ('crew', 'hall'),
        ('manager', 'management'),
      ])
        {
          'id': p.$1,
          'tapperId': p.$1,
          'partId': p.$2,
          'date': '2026-09-28',
          'start': '09:00',
          'end': p.$1 == 'manager' ? '14:00' : '18:00',
        },
    ];
    data['crewPatterns'] = [
      {
        'tapperId': 'cook',
        'cycleWeeks': 1,
        'anchor': '2026-09-28',
        'entries': [
          {
            'week': 0,
            'weekday': 1,
            'partId': 'kitchen',
            'timeBandId': 'open',
            'start': '06:00',
            'end': '15:00',
          },
        ],
      },
    ];
    final ops = OperationsController(
      client: MockClient((_) async => response(data)),
    );
    await ops.refresh();
    addTearDown(ops.dispose);
    final work = WorkController(MemoryStore());
    addTearDown(work.dispose);
    final dir = Directory('../.local/schedule-flow-review')
      ..createSync(recursive: true);
    for (final width in [320.0, 390.0, 1200.0]) {
      tester.view.physicalSize = Size(width, 900);
      for (final name in [
        'hours',
        'allocation',
        'ghost',
        'calendar',
        'month',
      ]) {
        final key = GlobalKey();
        final screen = name == 'hours'
            ? WorkplaceSettings(ops: ops, section: 'hours')
            : (name == 'allocation' || name == 'ghost')
            ? CrewAllocationScreen(ops: ops, day: DateTime(2026, 9, 28))
            : Scaffold(
                body: SafeArea(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: CalendarScreen(operations: ops),
                  ),
                ),
              );
        await tester.pumpWidget(
          RepaintBoundary(
            key: key,
            child: Tap2workApp(controller: work, homeOverride: screen),
          ),
        );
        await tester.pumpAndSettle();
        if (name == 'hours') {
          await tester.tap(find.text('전체'));
          await tester.pumpAndSettle();
        }
        if (name == 'ghost') {
          await tester.tap(find.text('이전 스케줄 불러오기'));
          await tester.pumpAndSettle();
        }
        if (name == 'month') {
          await tester.tap(find.widgetWithText(ChoiceChip, '월간'));
          await tester.pumpAndSettle();
        }
        expect(tester.takeException(), isNull);
        await tester.runAsync(() async {
          final img =
              await (key.currentContext!.findRenderObject()
                      as RenderRepaintBoundary)
                  .toImage();
          final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
          File(
            '${dir.path}/$name-${width.toInt()}.png',
          ).writeAsBytesSync(bytes!.buffer.asUint8List());
          img.dispose();
        });
        await tester.pumpWidget(const SizedBox());
        await tester.pumpAndSettle();
      }
    }
  });
}
