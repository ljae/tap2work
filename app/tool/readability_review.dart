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
import 'package:tap2work/ui/components.dart';
import 'package:tap2work/ui/checklist_editor.dart';
import 'package:tap2work/ui/payroll_settings_screen.dart';
import 'package:tap2work/ui/app_loading_screen.dart';
import '../test/operations_test.dart' show response;
import '../test/work_controller_test.dart' show MemoryStore;

void main() {
  testWidgets('capture readable sheets and startup with bundled fonts', (
    tester,
  ) async {
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
    final data =
        jsonDecode(File('../_site/review-data/owner.json').readAsStringSync())
            as Json;
    final ops = OperationsController(
      readOnly: true,
      client: MockClient((_) async => response(data)),
    );
    final work = WorkController(MemoryStore());
    addTearDown(ops.dispose);
    addTearDown(work.dispose);
    await ops.refresh();
    final template = ops
        .rows('taskTemplates')
        .firstWhere(
          (t) => t['archivedAt'] == null && (t['steps'] as List).isNotEmpty,
        );
    final key = GlobalKey();
    final output = Directory('../.local/readability-review')
      ..createSync(recursive: true);
    Future<void> capture(String name) async {
      await tester.runAsync(() async {
        final boundary =
            key.currentContext!.findRenderObject() as RenderRepaintBoundary;
        final image = await boundary.toImage();
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        File(
          '${output.path}/$name.png',
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
      for (final screen in ['manual', 'payroll']) {
        await tester.pumpWidget(
          RepaintBoundary(
            key: key,
            child: Tap2workApp(
              controller: work,
              homeOverride: Builder(
                builder: (context) => Scaffold(
                  body: Center(
                    child: FilledButton(
                      onPressed: () => showAppSheet(
                        context,
                        builder: (_) => screen == 'manual'
                            ? ManualTaskEditor(
                                ops: ops,
                                templateId: template['id'],
                                sourceStepId: template['steps'][0]['id'],
                              )
                            : PayrollSettingsScreen(ops: ops),
                      ),
                      child: const Text('열기'),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('열기'));
        await tester.pumpAndSettle();
        await capture('$screen-${width.toInt()}');
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
      }
      await tester.pumpWidget(
        RepaintBoundary(
          key: key,
          child: Tap2workApp(
            controller: work,
            homeOverride: const AppLoadingScreen(),
          ),
        ),
      );
      await tester.runAsync(() async {
        await precacheImage(
          const AssetImage('assets/branding/tap2work.png'),
          key.currentContext!,
        );
      });
      await tester.pump(const Duration(milliseconds: 500));
      await capture('loading-${width.toInt()}');
      await tester.pumpWidget(const SizedBox.shrink());
    }
  });
}
