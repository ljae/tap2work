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
import '../test/settings_sheet_audit_test.dart' show sheetData, sheetCases;
import '../test/operations_test.dart' show response;
import '../test/work_controller_test.dart' show MemoryStore;

void main() {
  testWidgets('capture every settings sheet family', (tester) async {
    for (final e in {
      'Pretendard': 'assets/fonts/PretendardVariable.ttf',
      'MaterialIcons': 'fonts/MaterialIcons-Regular.otf',
      'packages/cupertino_icons/CupertinoIcons':
          'packages/cupertino_icons/assets/CupertinoIcons.ttf',
    }.entries) {
      await (FontLoader(e.key)..addFont(rootBundle.load(e.value))).load();
    }
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    final out = Directory('../.local/settings-sheet-review')
      ..createSync(recursive: true);
    final ops = OperationsController(
      client: MockClient((_) async => response(sheetData())),
    );
    await ops.refresh();
    addTearDown(ops.dispose);
    final work = WorkController(MemoryStore());
    addTearDown(work.dispose);
    for (final width in [320.0, 390.0, 1200.0]) {
      tester.view.physicalSize = Size(width, 840);
      for (final entry in sheetCases(ops).entries) {
        final key = GlobalKey();
        await tester.pumpWidget(
          RepaintBoundary(
            key: key,
            child: Tap2workApp(
              controller: work,
              homeOverride: Builder(
                builder: (context) => Scaffold(
                  body: TextButton(
                    onPressed: () =>
                        showAppSheet(context, builder: (_) => entry.value),
                    child: const Text('열기'),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('열기'));
        await tester.pumpAndSettle();
        await tester.runAsync(() async {
          final img =
              await (key.currentContext!.findRenderObject()
                      as RenderRepaintBoundary)
                  .toImage();
          final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
          File(
            '${out.path}/${entry.key}-${width.toInt()}.png',
          ).writeAsBytesSync(bytes!.buffer.asUint8List());
          img.dispose();
        });
        expect(tester.takeException(), isNull, reason: entry.key);
        await tester.pumpWidget(const SizedBox());
        await tester.pumpAndSettle();
      }
    }
  });
}
