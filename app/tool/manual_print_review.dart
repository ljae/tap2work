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
import 'package:tap2work/ui/components.dart';
import 'package:tap2work/ui/manual_print_screen.dart';
import '../test/manual_print_test.dart' show printFixture, FakePdf;
import '../test/operations_test.dart' show response;
import '../test/work_controller_test.dart' show MemoryStore;

void main() {
  testWidgets('capture phone print form and export actions', (tester) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await (FontLoader(
      'Pretendard',
    )..addFont(rootBundle.load('assets/fonts/PretendardVariable.ttf'))).load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    await (FontLoader('packages/cupertino_icons/CupertinoIcons')..addFont(
          rootBundle.load('packages/cupertino_icons/assets/CupertinoIcons.ttf'),
        ))
        .load();
    final data = printFixture();
    final ops = OperationsController(
      client: MockClient((_) async => response(data)),
    );
    final work = WorkController(MemoryStore());
    addTearDown(ops.dispose);
    addTearDown(work.dispose);
    await ops.refresh();
    final key = GlobalKey();
    final out = Directory('../.local/manual-print-review')
      ..createSync(recursive: true);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    for (final width in [320.0, 390.0]) {
      tester.view.physicalSize = Size(width, 900);
      for (final name in ['form', 'ready']) {
        final screen = ManualPrintScreen(ops: ops, repository: FakePdf());
        await tester.pumpWidget(
          RepaintBoundary(
            key: key,
            child: Tap2workApp(
              controller: work,
              homeOverride: Builder(
                builder: (c) => Scaffold(
                  body: TextButton(
                    onPressed: () => showAppSheet(c, builder: (_) => screen),
                    child: const Text('열기'),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('열기'));
        await tester.pumpAndSettle();
        if (name == 'ready') {
          await tester.tap(find.byKey(const ValueKey('manual-print-generate')));
          await tester.pumpAndSettle();
        }
        await tester.runAsync(() async {
          final image =
              await (key.currentContext!.findRenderObject()
                      as RenderRepaintBoundary)
                  .toImage();
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          File(
            '${out.path}/$name-${width.toInt()}.png',
          ).writeAsBytesSync(bytes!.buffer.asUint8List());
          image.dispose();
        });
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
      }
    }
  });
}
