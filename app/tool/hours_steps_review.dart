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
import '../test/time_band_editor_test.dart' show fixture;
import 'package:tap2work/ui/workplace_screens.dart';
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
    final out = Directory('../.local/hours-review')
      ..createSync(recursive: true);
    final ops = OperationsController(
      client: MockClient(
        (_) async => response({
          ...fixture(),
          'workplace': {
            ...fixture()['workplace'],
            'parts': [
              ...fixture()['workplace']['parts'],
              {'id': 'management', 'name': '관리'},
            ],
          },
        }),
      ),
    );
    await ops.refresh();
    addTearDown(ops.dispose);
    final work = WorkController(MemoryStore());
    addTearDown(work.dispose);
    for (final width in [320.0, 390.0, 1200.0]) {
      tester.view.physicalSize = Size(width, 840);
      for (final entry in {
        'hours': WorkplaceSettings(ops: ops, section: 'hours'),
      }.entries) {
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
            '${out.path}/기본-${width.toInt()}.png',
          ).writeAsBytesSync(bytes!.buffer.asUint8List());
          img.dispose();
        });
        for (final stage in ['영업시간 설정', '인원 배치']) {
          await tester.tap(find.text(stage).first);
          await tester.pumpAndSettle();
          if (stage == '영업시간 설정') {
            await tester.tap(find.text('휴무일'));
            await tester.pumpAndSettle();
            await tester.tap(find.text('개별'));
            await tester.pumpAndSettle();
            await tester.ensureVisible(find.text('휴무일'));
            await tester.pumpAndSettle();
            await tester.runAsync(() async {
              final img =
                  await (key.currentContext!.findRenderObject()
                          as RenderRepaintBoundary)
                      .toImage();
              final bytes = await img.toByteData(
                format: ui.ImageByteFormat.png,
              );
              File(
                '${out.path}/요일선택-${width.toInt()}.png',
              ).writeAsBytesSync(bytes!.buffer.asUint8List());
              img.dispose();
            });
            await tester.tap(find.text('전체'));
            await tester.pumpAndSettle();
            await tester.tap(find.text('2교대 이상'));
            await tester.pumpAndSettle();
            await tester.ensureVisible(find.text('3교대'));
            await tester.tap(find.text('3교대'));
            await tester.pumpAndSettle();
            await tester.ensureVisible(find.text('브레이크 타임'));
            await tester.tap(find.text('브레이크 타임'));
            await tester.pumpAndSettle();
            await tester.ensureVisible(
              find.byKey(const ValueKey('break-label-1')),
            );
            await tester.pumpAndSettle();
          }
          await tester.runAsync(() async {
            final img =
                await (key.currentContext!.findRenderObject()
                        as RenderRepaintBoundary)
                    .toImage();
            final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
            File(
              '${out.path}/$stage-${width.toInt()}.png',
            ).writeAsBytesSync(bytes!.buffer.asUint8List());
            img.dispose();
          });
        }
        expect(tester.takeException(), isNull, reason: entry.key);
        await tester.pumpWidget(const SizedBox());
        await tester.pumpAndSettle();
      }
    }
  });
}
