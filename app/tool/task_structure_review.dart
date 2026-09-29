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
import 'package:tap2work/ui/tap_workspace.dart';
import 'package:tap2work/ui/tap_card.dart';
import '../test/checklist_test.dart' show fixture;
import '../test/operations_test.dart' show response;
import '../test/work_controller_test.dart' show MemoryStore;

void main() {
  testWidgets('capture TAP hierarchy and inline editor with real fonts', (
    tester,
  ) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    final fonts = FontLoader('Pretendard');
    fonts.addFont(rootBundle.load('assets/fonts/PretendardVariable.ttf'));
    await fonts.load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    await (FontLoader('packages/cupertino_icons/CupertinoIcons')..addFont(
          rootBundle.load('packages/cupertino_icons/assets/CupertinoIcons.ttf'),
        ))
        .load();
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    final output = Directory('../.local/task-structure-review')
      ..createSync(recursive: true);
    for (final width in [390.0, 1200.0]) {
      tester.view.physicalSize = Size(width, 1000);
      final ops = OperationsController(
        readOnly: true,
        client: MockClient((_) async => response(fixture())),
      );
      final work = WorkController(MemoryStore());
      addTearDown(ops.dispose);
      addTearDown(work.dispose);
      await ops.refresh();
      final key = GlobalKey();
      await tester.pumpWidget(
        RepaintBoundary(
          key: key,
          child: Tap2workApp(
            controller: work,
            homeOverride: Scaffold(
              body: SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: TapWorkspace(ops: ops, onStock: (_) async {}),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      Future<void> capture(String name) async {
        await tester.runAsync(() async {
          final boundary =
              key.currentContext!.findRenderObject() as RenderRepaintBoundary;
          final image = await boundary.toImage();
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          File(
            '${output.path}/$name-${width.toInt()}.png',
          ).writeAsBytesSync(bytes!.buffer.asUint8List());
          image.dispose();
        });
        expect(tester.takeException(), isNull);
      }

      await capture('board');
      tester
          .widget<TapCard>(find.byKey(const ValueKey('tap-daily-prep')))
          .onOpen();
      await tester.pumpAndSettle();
      await capture('tasks');
      await tester.longPress(find.text('도구 나누기'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('도구 나누기'));
      await tester.pumpAndSettle();
      await capture('edit');
      await tester.pumpWidget(const SizedBox.shrink());
    }
  });
}
