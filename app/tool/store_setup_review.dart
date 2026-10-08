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
import 'package:tap2work/ui/store_setup_screen.dart';
import '../test/operations_test.dart' show response, sample;
import '../test/work_controller_test.dart' show MemoryStore;

void main() {
  testWidgets('capture new-store guided setup', (t) async {
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
    final out = Directory('../.local/store-setup-review')
      ..createSync(recursive: true);
    final data = {
      ...sample(),
      'storeSetupCatalog': jsonDecode(
        File('${out.path}/catalog.json').readAsStringSync(),
      ),
    };
    final ops = OperationsController(
      client: MockClient((_) async => response(data)),
    );
    final work = WorkController(MemoryStore());
    addTearDown(ops.dispose);
    addTearDown(work.dispose);
    await ops.refresh();
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetDevicePixelRatio);
    addTearDown(t.view.resetPhysicalSize);
    final key = GlobalKey();
    Future<void> capture(String label, int width) async {
      await t.pumpAndSettle();
      await t.runAsync(() async {
        final img =
            await (key.currentContext!.findRenderObject()
                    as RenderRepaintBoundary)
                .toImage();
        final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
        File(
          '${out.path}/$label-$width.png',
        ).writeAsBytesSync(bytes!.buffer.asUint8List());
        img.dispose();
      });
      expect(t.takeException(), isNull);
    }

    Future<void> next() async {
      await t.tap(find.widgetWithText(FilledButton, '다음'));
      await t.pumpAndSettle();
    }

    for (final width in [320, 390, 1200]) {
      t.view.physicalSize = Size(width.toDouble(), 900);
      await t.pumpWidget(
        RepaintBoundary(
          key: key,
          child: Tap2workApp(
            controller: work,
            homeOverride: Builder(
              builder: (c) => Scaffold(
                body: TextButton(
                  onPressed: () => openStoreSetup(c, ops),
                  child: const Text('등록'),
                ),
              ),
            ),
          ),
        ),
      );
      await t.tap(find.text('등록'));
      await t.pumpAndSettle();
      await t.enterText(
        find.byKey(const ValueKey('new-workspace-name')),
        '연남 돈까스',
      );
      await capture('name', width);
      await next();
      await t.tap(find.widgetWithText(FilterChip, '돈까스'));
      await capture('industry', width);
      await next();
      await next();
      await next();
      await next(); // service, location, days, hours
      await capture('hours', width);
      while (find.text('기본 매뉴얼을 준비했어요').evaluate().isEmpty) {
        await next();
      }
      await capture('manual', width);
      await next();
      await capture('review', width);
      await t.pumpWidget(const SizedBox.shrink());
      await t.pumpAndSettle();
    }
  });
}
