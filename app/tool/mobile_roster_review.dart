import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:tap2work/ui/calendar_screen.dart';
import 'package:tap2work/ui/design_tokens.dart';
import 'package:tap2work/state/operations_controller.dart';
import '../test/calendar_test.dart' show calendarData;
import '../test/operations_test.dart' show response;

void main() {
  testWidgets('mobile schedule visual review', (tester) async {
    await (FontLoader(
      'Pretendard',
    )..addFont(rootBundle.load('assets/fonts/PretendardVariable.ttf'))).load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    final output = Directory('../.local/mobile-business-review')
      ..createSync(recursive: true);
    for (final width in [320.0, 390.0, 1200.0]) {
      tester.view.physicalSize = Size(width, 1100);
      final data = calendarData();
      data['workplace']['breaks'] = {
        '1': {'start': '11:00', 'end': '12:00'},
      };
      data['staffShifts'] = [
        for (var i = 0; i < 4; i++)
          {
            'id': 's$i',
            'tapperId': 'crew$i',
            'partId': ['kitchen', 'hall', 'hall', 'management'][i],
            'date': '2026-09-28',
            'start': '09:00',
            'end': '14:00',
            'label': ['현우', '지우', '민지', '이재훈'][i],
          },
      ];
      final ops = OperationsController(
        readOnly: false,
        client: MockClient((_) async => response(data)),
      );
      await ops.refresh();
      final key = GlobalKey();
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark().copyWith(
            scaffoldBackgroundColor: AppColors.paper,
            textTheme: ThemeData.dark().textTheme.apply(
              fontFamily: 'Pretendard',
            ),
          ),
          home: RepaintBoundary(
            key: key,
            child: Scaffold(
              body: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: CalendarScreen(operations: ops),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        final boundary =
            key.currentContext!.findRenderObject() as RenderRepaintBoundary;
        final image = await boundary.toImage();
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        await File(
          '${output.path}/roster-${width.toInt()}.png',
        ).writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      ops.dispose();
    }
  });
}
