import 'dart:convert';
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
import '../test/operations_test.dart' show response;
import '../test/work_controller_test.dart' show MemoryStore;

void main() {
  testWidgets('capture Toss UI with bundled font at phone and desktop widths', (
    tester,
  ) async {
    final fonts = FontLoader('Pretendard');
    for (final weight in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
      fonts.addFont(rootBundle.load('assets/fonts/Pretendard-$weight.otf'));
    }
    await fonts.load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    await (FontLoader('packages/cupertino_icons/CupertinoIcons')..addFont(
          rootBundle.load('packages/cupertino_icons/assets/CupertinoIcons.ttf'),
        ))
        .load();
    debugDisableShadows = false;
    addTearDown(() => debugDisableShadows = true);
    final data =
        jsonDecode(File('../_site/review-data/owner.json').readAsStringSync())
            as Json;
    final ops = OperationsController(
      readOnly: true,
      client: MockClient((_) async => response(data)),
    );
    addTearDown(ops.dispose);
    await ops.refresh();
    final captureKey = GlobalKey();
    Future<void> capture(String name) async {
      await tester.runAsync(() async {
        final boundary =
            captureKey.currentContext!.findRenderObject()!
                as RenderRepaintBoundary;
        final image = await boundary.toImage();
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        File(
          '../.local/toss-ui-review/$name.png',
        ).writeAsBytesSync(bytes!.buffer.asUint8List());
        image.dispose();
      });
      expect(tester.takeException(), isNull);
    }

    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    for (final width in [390.0, 1200.0]) {
      tester.view.physicalSize = Size(width, 900);
      await tester.pumpWidget(
        RepaintBoundary(
          key: captureKey,
          child: Tap2workApp(
            controller: WorkController(MemoryStore()),
            operations: ops,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await capture('work-${width.toInt()}');
      await tester.tap(find.byKey(const ValueKey('floating-menu-3')));
      await tester.pumpAndSettle();
      await capture('store-${width.toInt()}');
      await tester.ensureVisible(find.text('매장 설정'));
      await tester.tap(find.text('매장 설정'));
      await tester.pumpAndSettle();
      await capture('sheet-${width.toInt()}');
      await tester.tap(find.byType(CloseButton));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('floating-menu-1')));
      await tester.pumpAndSettle();
      await capture('manual-${width.toInt()}');
      await tester.tap(find.byKey(const ValueKey('floating-menu-2')));
      await tester.pumpAndSettle();
      await capture('weekly-${width.toInt()}');
      await tester.tap(find.text('인건비').first);
      await tester.pumpAndSettle();
      await capture('labor-${width.toInt()}');

      await tester.pumpWidget(const SizedBox.shrink());
    }
    debugDisableShadows = true;
  });
}
