import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:tap2work/state/operations_controller.dart';
import 'package:tap2work/main.dart';
import 'package:tap2work/state/work_controller.dart';
import '../test/work_controller_test.dart' show MemoryStore;
import 'package:tap2work/ui/calendar_screen.dart';
import 'package:tap2work/ui/water_search.dart';
import '../test/calendar_test.dart' show calendarData;
import '../test/operations_test.dart' show response;

void main() {
  testWidgets('capture fixed toolbar and cup', (tester) async {
    await (FontLoader(
      'Pretendard',
    )..addFont(rootBundle.load('assets/fonts/PretendardVariable.ttf'))).load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    final ops = OperationsController(
      readOnly: true,
      client: MockClient((_) async => response(calendarData())),
    );
    addTearDown(ops.dispose);
    await ops.refresh();
    final search = TextEditingController();
    addTearDown(search.dispose);
    await (FontLoader('packages/cupertino_icons/CupertinoIcons')..addFont(
          rootBundle.load('packages/cupertino_icons/assets/CupertinoIcons.ttf'),
        ))
        .load();
    final key = GlobalKey();
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    for (final width in [320.0, 390.0, 1600.0]) {
      tester.view.physicalSize = Size(width, 800);
      await tester.pumpWidget(
        Tap2workApp(
          controller: WorkController(MemoryStore()),
          operations: ops,
          homeOverride: Scaffold(
            body: RepaintBoundary(
              key: key,
              child: Column(
                children: [
                  WaterSearch(
                    controller: search,
                    onChanged: (_) {},
                    onClear: () {},
                  ),
                  Expanded(
                    child: CalendarScreen(operations: ops, scrollable: true),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.runAsync(() async {
        final image =
            await (key.currentContext!.findRenderObject()
                    as RenderRepaintBoundary)
                .toImage();
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        Directory('../.local/toolbar-review').createSync(recursive: true);
        File(
          '../.local/toolbar-review/${width.toInt()}.png',
        ).writeAsBytesSync(bytes!.buffer.asUint8List());
        image.dispose();
      });
    }
  });
}
