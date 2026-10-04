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
import 'settings_sheet_audit_test.dart' show sheetData;
import 'dashboard_test.dart' show dashboard;
import 'package:tap2work/ui/store_dashboard.dart';
import 'operations_test.dart' show response;
import 'work_controller_test.dart' show MemoryStore;

void main() {
  const capture = bool.fromEnvironment('UI_AUDIT_CAPTURE');
  for (final width in [320.0, 390.0, 1200.0]) {
    for (var index = 0; index < 4; index++) {
      testWidgets(
        'destination $index at $width large text keyboard reduced motion',
        (tester) async {
          tester.view.physicalSize = Size(width, 840);
          tester.view.devicePixelRatio = 1;
          tester.platformDispatcher.textScaleFactorTestValue = 1.5;
          tester.platformDispatcher.accessibilityFeaturesTestValue =
              const FakeAccessibilityFeatures(disableAnimations: true);
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          addTearDown(tester.view.resetViewInsets);
          addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
          addTearDown(
            tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
          );
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
          final data = sheetData();
          final ops = OperationsController(
            readOnly: true,
            client: MockClient((request) async {
              expect(request.method, 'GET', reason: 'Audit must not write');
              return response(data);
            }),
          );
          final work = WorkController(MemoryStore());
          addTearDown(ops.dispose);
          addTearDown(work.dispose);
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
          await tester.tap(find.byKey(ValueKey('floating-menu-$index')));
          await tester.pumpAndSettle();
          if (index != 2) {
            expect(
              tester
                  .widget<Text>(find.byKey(const ValueKey('menu-title')))
                  .data,
              ['업무', '매뉴얼', '근무표', '우리매장'][index],
            );
          }
          Future<void> snapshot(String state) async {
            if (capture) {
              await tester.runAsync(() async {
                final out = Directory('../.local/ui-ux-audit-2026-09-30')
                  ..createSync(recursive: true);
                final image =
                    await (key.currentContext!.findRenderObject()
                            as RenderRepaintBoundary)
                        .toImage();
                final bytes = await image.toByteData(
                  format: ui.ImageByteFormat.png,
                );
                File(
                  '${out.path}/destination-$index-${width.toInt()}-$state.png',
                ).writeAsBytesSync(bytes!.buffer.asUint8List());
                image.dispose();
              });
            }
            expect(
              tester.takeException(),
              isNull,
              reason: '$index/$width/$state',
            );
          }

          await snapshot('initial');
          final search = find.byKey(const ValueKey('global-manual-search'));
          if (index == 2) {
            expect(search, findsNothing);
            expect(find.byKey(const ValueKey('menu-title')), findsNothing);
            expect(
              find.byKey(const ValueKey('roster-time-axis')),
              findsOneWidget,
            );
            await tester.pumpWidget(const SizedBox());
            await tester.pumpAndSettle();
            return;
          }
          await tester.tap(search);
          await tester.enterText(search, '손');
          tester.view.viewInsets = const FakeViewPadding(bottom: 280);
          await tester.pumpAndSettle();
          if (index == 1 && width < 700) {
            final results = find.text('매뉴얼 1');
            if (results.evaluate().isNotEmpty) {
              await tester.tap(results);
              await tester.pumpAndSettle();
            }
          }
          expect(find.text('손 씻기'), findsWidgets);
          await snapshot('keyboard');
          await tester.pumpWidget(const SizedBox());
          await tester.pumpAndSettle();
        },
      );
    }
  }
  for (final width in [320.0, 390.0, 1200.0]) {
    testWidgets('long dashboard KPI wraps without shrinking at $width', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 840);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 1.5;
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      await (FontLoader('Pretendard')
            ..addFont(rootBundle.load('assets/fonts/PretendardVariable.ttf')))
          .load();
      final data = sheetData();
      data['dashboard'] = dashboard();
      for (final report in data['dashboard']['reports'] as List) {
        report['summary']['revenue'] = 1234567890123;
      }
      final ops = OperationsController(
        client: MockClient((_) async => response(data)),
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
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: StoreDashboard(operations: ops, onNavigate: (_) {}),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final kpi = find.text('1,234,567,890,123원');
      await tester.ensureVisible(kpi);
      await tester.pumpAndSettle();
      expect(
        find.ancestor(of: kpi, matching: find.byType(FittedBox)),
        findsNothing,
      );
      expect(tester.widget<Text>(kpi).style!.fontSize, 24);
      final paragraph = tester.renderObject<RenderParagraph>(kpi);
      expect(paragraph.didExceedMaxLines, isFalse);
      expect(tester.takeException(), isNull);
      if (capture) {
        await tester.runAsync(() async {
          final out = Directory('../.local/ui-ux-audit-2026-09-30')
            ..createSync(recursive: true);
          final image =
              await (key.currentContext!.findRenderObject()
                      as RenderRepaintBoundary)
                  .toImage();
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          File(
            '${out.path}/kpi-${width.toInt()}-large.png',
          ).writeAsBytesSync(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }
    });
  }
}
