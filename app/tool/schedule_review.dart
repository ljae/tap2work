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
import 'package:tap2work/ui/crew_pattern_screen.dart';
import 'package:tap2work/ui/workplace_screens.dart';
import '../test/calendar_test.dart' show calendarData;
import '../test/operations_test.dart' show response;
import '../test/work_controller_test.dart' show MemoryStore;

void main() {
  testWidgets('schedule and settings visual review', (tester) async {
    for (final e in {
      'Pretendard': 'assets/fonts/PretendardVariable.ttf',
      'MaterialIcons': 'fonts/MaterialIcons-Regular.otf',
      'packages/cupertino_icons/CupertinoIcons':
          'packages/cupertino_icons/assets/CupertinoIcons.ttf',
    }.entries) {
      await (FontLoader(e.key)..addFont(rootBundle.load(e.value))).load();
    }
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    final output = Directory('../.local/schedule-review')
      ..createSync(recursive: true);
    for (final width in [390.0, 1200.0]) {
      for (final scene in ['calendar', 'hours', 'patterns']) {
        tester.view.physicalSize = Size(width, 1000);
        final data = calendarData();
        data['day'] = '2026-10-05';
        data['workplace'] = <String, dynamic>{...data['workplace']};
        data['workplace']['days'] = {
          for (var d = 1; d <= 7; d++)
            '$d': d == 7
                ? []
                : [
                    {
                      'name': '오픈',
                      'start': '09:00',
                      'end': '14:00',
                      'headcounts': {'kitchen': 2, 'hall': 1, 'management': 1},
                    },
                    {'name': '마감', 'start': '14:00', 'end': '22:00'},
                  ],
        };
        data['staffShifts'] = [
          {
            'id': 'fine',
            'tapperId': 'cook',
            'partId': 'kitchen',
            'date': '2026-10-05',
            'start': '09:00',
            'end': '12:00',
            'status': 'planned',
          },
        ];
        final ops = OperationsController(
          readOnly: false,
          client: MockClient((_) async => response(data)),
        );
        await ops.refresh();
        final work = WorkController(MemoryStore()), key = GlobalKey();
        final content = scene == 'hours'
            ? WorkplaceSettings(ops: ops, section: 'hours')
            : scene == 'patterns'
            ? CrewPatternScreen(ops: ops, day: DateTime(2026, 10, 5))
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: CalendarScreen(operations: ops),
              );
        await tester.pumpWidget(
          RepaintBoundary(
            key: key,
            child: Tap2workApp(
              controller: work,
              homeOverride: Scaffold(
                body: MediaQuery(
                  data: MediaQueryData(
                    size: Size(width, 1000),
                    disableAnimations: true,
                  ),
                  child: content,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        if (scene == 'patterns') {
          await tester.tap(find.text('2주 교대'));
          await tester.pumpAndSettle();
        }
        await tester.runAsync(() async {
          final boundary =
              key.currentContext!.findRenderObject() as RenderRepaintBoundary;
          final pic = await boundary.toImage(pixelRatio: 1);
          final bytes = await pic.toByteData(format: ui.ImageByteFormat.png);
          await File(
            '${output.path}/$scene-${width.toInt()}.png',
          ).writeAsBytes(bytes!.buffer.asUint8List());
          pic.dispose();
        });
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        ops.dispose();
        work.dispose();
      }
    }
  });
}
