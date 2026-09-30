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
import '../test/support/ui_ux_audit_cases.dart' show sheetData, sheetCases;
import '../test/operations_test.dart' show response;
import '../test/work_controller_test.dart' show MemoryStore;

void main() {
  testWidgets('capture settings with large text and keyboard', (tester) async {
    for (final e in {
      'Pretendard': 'assets/fonts/PretendardVariable.ttf',
      'MaterialIcons': 'fonts/MaterialIcons-Regular.otf',
      'packages/cupertino_icons/CupertinoIcons':
          'packages/cupertino_icons/assets/CupertinoIcons.ttf',
    }.entries) {
      await (FontLoader(e.key)..addFont(rootBundle.load(e.value))).load();
    }
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.5;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    final out = Directory('../.local/ui-ux-audit-2026-09-30/settings')
      ..createSync(recursive: true);
    final ops = OperationsController(
      client: MockClient((_) async => response(sheetData(longNames: true))),
    );
    await ops.refresh();
    addTearDown(ops.dispose);
    final work = WorkController(MemoryStore());
    addTearDown(work.dispose);
    for (final width in [320.0, 390.0, 1200.0]) {
      tester.view.physicalSize = Size(width, 840);
      for (final entry in sheetCases(ops).entries) {
        const families = String.fromEnvironment('UI_AUDIT_FAMILIES');
        if (families.isNotEmpty && !families.split(',').contains(entry.key)) {
          continue;
        }
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
        for (final state in ['large', 'keyboard-bottom']) {
          if (state == 'keyboard-bottom') {
            tester.view.viewInsets = const FakeViewPadding(bottom: 280);
            await tester.pumpAndSettle();
            final scroll = find.byType(Scrollable);
            if (scroll.evaluate().isNotEmpty) {
              await tester.drag(scroll.first, const Offset(0, -1200));
              await tester.pumpAndSettle();
            }
          }
          await tester.runAsync(() async {
            final img =
                await (key.currentContext!.findRenderObject()
                        as RenderRepaintBoundary)
                    .toImage();
            final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
            File(
              '${out.path}/${entry.key}-${width.toInt()}-$state.png',
            ).writeAsBytesSync(bytes!.buffer.asUint8List());
            img.dispose();
          });
          if (state == 'keyboard-bottom') {
            final footer = find.byType(AppSheetFooter);
            if (footer.evaluate().isNotEmpty) {
              expect(
                tester.getRect(footer.last).bottom,
                lessThanOrEqualTo(560),
                reason: entry.key,
              );
            }
          }
          expect(tester.takeException(), isNull, reason: '${entry.key}/$state');
        }
        tester.view.resetViewInsets();
        await tester.pumpWidget(const SizedBox());
        await tester.pumpAndSettle();
      }
    }
  });
}
