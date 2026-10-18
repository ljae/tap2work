// Render review candidates from the real widgets and a public, fictional sample.
// These are Flutter-rendered captures, not evidence of physical device testing.
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tap2work/main.dart';
import 'package:tap2work/state/operations_controller.dart';
import 'package:tap2work/state/work_controller.dart';
import '../test/work_controller_test.dart' show MemoryStore;

void main() {
  testWidgets('capture four current destinations for iPhone and iPad', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    final directory = Directory('../.local/app-store-screenshots');
    directory.createSync(recursive: true);
    // Fetch the public sample before running this tool; widget tests deliberately
    // disable real HTTP. Never use a private workspace export for store images.
    final sample = jsonDecode(
      File('${directory.path}/owner.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    for (final font in {
      'Pretendard': 'assets/fonts/PretendardVariable.ttf',
      'MaterialIcons': 'fonts/MaterialIcons-Regular.otf',
      'packages/cupertino_icons/CupertinoIcons':
          'packages/cupertino_icons/assets/CupertinoIcons.ttf',
      'NotoSansSC': 'assets/fonts/print/NotoSansSC-Regular.ttf',
      'NotoSansJP': 'assets/fonts/print/NotoSansJP-Regular.ttf',
    }.entries) {
      await (FontLoader(font.key)..addFont(rootBundle.load(font.value))).load();
    }
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    for (final device in [
      (name: 'iphone', size: const Size(428, 926), ratio: 3.0),
      (name: 'ipad', size: const Size(1032, 1376), ratio: 2.0),
    ]) {
      tester.view.devicePixelRatio = device.ratio;
      tester.view.physicalSize = device.size * device.ratio;
      final ops = OperationsController(
        readOnly: true,
        client: MockClient(
          (_) async => http.Response(
            jsonEncode(sample),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          ),
        ),
      );
      final work = WorkController(MemoryStore());
      final captureKey = GlobalKey();
      await ops.refresh();
      await tester.pumpWidget(
        RepaintBoundary(
          key: captureKey,
          child: Tap2workApp(
            controller: work,
            operations: ops,
            onAccountPressed: (_) async {},
          ),
        ),
      );
      await tester.runAsync(
        () => precacheImage(
          const AssetImage('assets/branding/tap2work.png'),
          captureKey.currentContext!,
        ),
      );
      await tester.pumpAndSettle();
      final continueWork = find.byKey(const ValueKey('shared-welcome-work'));
      if (continueWork.evaluate().isNotEmpty) {
        await tester.tap(continueWork);
        await tester.pumpAndSettle();
      }
      for (var index = 0; index < 4; index++) {
        await tester.tap(find.byKey(ValueKey('floating-menu-$index')));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.runAsync(() async {
          final boundary =
              captureKey.currentContext!.findRenderObject()!
                  as RenderRepaintBoundary;
          final image = await boundary.toImage(pixelRatio: device.ratio);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          await File(
            '${directory.path}/${device.name}-${index + 1}.png',
          ).writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }
      await tester.pumpWidget(const SizedBox.shrink());
      ops.dispose();
      work.dispose();
    }
    debugDefaultTargetPlatformOverride = null;
  });
}
