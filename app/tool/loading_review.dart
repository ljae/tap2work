import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tap2work/main.dart';
import 'package:tap2work/state/work_controller.dart';
import 'package:tap2work/ui/app_loading_screen.dart';
import '../test/work_controller_test.dart' show MemoryStore;

void main() {
  testWidgets('capture loading stages at phone and desktop widths', (
    tester,
  ) async {
    await (FontLoader(
      'Pretendard',
    )..addFont(rootBundle.load('assets/fonts/PretendardVariable.ttf'))).load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    final work = WorkController(MemoryStore());
    addTearDown(work.dispose);
    for (final width in [320.0, 390.0, 1200.0]) {
      tester.view.physicalSize = Size(width, 560);
      for (final stage in ['startup', 'store', 'error']) {
        final key = GlobalKey();
        await tester.pumpWidget(
          Tap2workApp(
            controller: work,
            homeOverride: MediaQuery(
              data: const MediaQueryData(
                textScaler: TextScaler.linear(1.5),
                disableAnimations: true,
              ),
              child: RepaintBoundary(
                key: key,
                child: AppLoadingScreen(
                  showSkeleton: stage == 'store',
                  title: stage == 'startup'
                      ? '앱을 준비하고 있어요'
                      : '저장된 매장을 불러오고 있어요',
                  message: stage == 'startup'
                      ? '로그인 상태와 저장된 매장 연결을 확인해요.'
                      : '업무와 매뉴얼, 근무표를 확인하고 있어요.',
                  error: stage == 'error'
                      ? '매장 서버에 연결하지 못했어요. 연결을 확인하고 다시 시도해 주세요.'
                      : null,
                  onRetry: () {},
                ),
              ),
            ),
          ),
        );
        await tester.pump();
        expect(tester.takeException(), isNull);
        await tester.runAsync(() async {
          final image =
              await (key.currentContext!.findRenderObject()
                      as RenderRepaintBoundary)
                  .toImage();
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          Directory('../.local/loading-review').createSync(recursive: true);
          File(
            '../.local/loading-review/$stage-${width.toInt()}.png',
          ).writeAsBytesSync(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }
    }
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
