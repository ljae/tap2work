import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tap2work/main.dart';
import 'package:tap2work/state/work_controller.dart';
import 'package:tap2work/ui/app_loading_screen.dart';
import '../test/work_controller_test.dart' show MemoryStore;

void main() {
  testWidgets('capture water loading', (tester) async {
    await (FontLoader(
      'Pretendard',
    )..addFont(rootBundle.load('assets/fonts/PretendardVariable.ttf'))).load();
    final work = WorkController(MemoryStore());
    addTearDown(work.dispose);
    final key = GlobalKey();
    final out = Directory('../.local/water-loading-review')
      ..createSync(recursive: true);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    for (final width in [320, 390, 1200]) {
      tester.view.physicalSize = Size(width.toDouble(), 800);
      await tester.pumpWidget(
        RepaintBoundary(
          key: key,
          child: Tap2workApp(
            controller: work,
            homeOverride: const AppLoadingScreen(showSkeleton: false),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1600));
      await tester.runAsync(() async {
        final image =
            await (key.currentContext!.findRenderObject()!
                    as RenderRepaintBoundary)
                .toImage();
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        File(
          '${out.path}/loading-$width.png',
        ).writeAsBytesSync(bytes!.buffer.asUint8List());
        image.dispose();
      });
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    }
  });
}
