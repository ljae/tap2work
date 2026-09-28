import 'package:tap2work/ui/workplace_screens.dart';
import 'package:tap2work/ui/payroll_settings_screen.dart';
import 'package:tap2work/ui/team_screen.dart';
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
  testWidgets('capture screenshot redesign and settings with bundled fonts', (
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
    Directory('../.local/reference-ui-review').createSync(recursive: true);
    data['demoInvites'] = [
      {
        'role': 'hourly',
        'code': 'DEMO2026',
        'expiresAt': '2026-10-05T00:00:00Z',
      },
    ];
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
          '../.local/reference-ui-review/$name.png',
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
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 60));
      await capture('store-transition-${width.toInt()}');
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

      final theme = Theme.of(tester.element(find.byType(Scaffold).first));
      for (final section in [
        'payroll',
        'hours',
        'parts',
        'permissions',
        'invite',
        'people',
      ]) {
        await tester.pumpWidget(
          RepaintBoundary(
            key: captureKey,
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: theme,
              home: section == 'payroll'
                  ? PayrollSettingsScreen(ops: ops)
                  : section == 'people'
                  ? Scaffold(
                      appBar: AppBar(title: const Text('직원')),
                      body: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: TeamScreen(operations: ops),
                      ),
                    )
                  : WorkplaceSettings(
                      key: ValueKey(section),
                      ops: ops,
                      section: section,
                    ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        if (section == 'hours') {
          await tester.tap(find.text('3교대'));
          await tester.pumpAndSettle();
        }
        await capture('$section-${width.toInt()}');
      }
      await tester.pumpWidget(const SizedBox.shrink());
    }
    debugDisableShadows = true;
  });
}
