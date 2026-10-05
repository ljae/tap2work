// Render the shipped Flutter screens with the public, fictitious sample data.
// No production accounts, store records, or promotional UI are used.
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
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
  testWidgets('export App Store screenshots of shipped sample screens', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    for (final entry in {
      'Pretendard': 'assets/fonts/PretendardVariable.ttf',
      'MaterialIcons': 'fonts/MaterialIcons-Regular.otf',
      'packages/cupertino_icons/CupertinoIcons':
          'packages/cupertino_icons/assets/CupertinoIcons.ttf',
    }.entries) {
      await (FontLoader(
        entry.key,
      )..addFont(rootBundle.load(entry.value))).load();
    }
    final data =
        jsonDecode(File('../_site/review-data/owner.json').readAsStringSync())
            as Json;
    final out = Directory('../.local/app-store-screenshots')
      ..createSync(recursive: true);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final device in ['iphone', 'ipad']) {
      final ratio = device == 'iphone' ? 3.0 : 2.0;
      tester.view.devicePixelRatio = ratio;
      tester.view.physicalSize = device == 'iphone'
          ? const Size(1284, 2778)
          : const Size(2064, 2752);
      final ops = OperationsController(
        readOnly: true,
        client: MockClient((_) async => response(data)),
      );
      final work = WorkController(MemoryStore());
      await ops.refresh();
      final key = GlobalKey();
      await tester.pumpWidget(
        RepaintBoundary(
          key: key,
          child: Tap2workApp(controller: work, operations: ops),
        ),
      );
      await tester.runAsync(
        () => precacheImage(
          const AssetImage('assets/branding/tap2work.png'),
          key.currentContext!,
        ),
      );
      await tester.pumpAndSettle();
      for (final index in [0, 1, 2, 3]) {
        if (index != 0) {
          await tester.tap(find.byKey(ValueKey('floating-menu-$index')));
          await tester.pumpAndSettle();
        }
        expect(tester.takeException(), isNull);
        await tester.runAsync(() async {
          final boundary =
              key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
          final image = await boundary.toImage(pixelRatio: ratio);
          final png = await image.toByteData(format: ui.ImageByteFormat.png);
          File(
            '${out.path}/$device-${index + 1}.png',
          ).writeAsBytesSync(png!.buffer.asUint8List());
          image.dispose();
        });
      }
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      ops.dispose();
      work.dispose();
    }
    debugDefaultTargetPlatformOverride = null;
  });
}
