import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:tap2work/main.dart';
import 'package:tap2work/state/work_controller.dart';
import 'package:tap2work/state/operations_controller.dart';
import 'package:tap2work/ui/manual_work_screen.dart';
import '../test/operations_test.dart' show sample, response;
import '../test/work_controller_test.dart' show MemoryStore;

void main() {
  testWidgets('capture manual connection states', (tester) async {
    await (FontLoader(
      'Pretendard',
    )..addFont(rootBundle.load('assets/fonts/PretendardVariable.ttf'))).load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final data = sample();
    data['taskTemplates'] = [
      {
        'id': 'a',
        'title': '브레이크 · 영업 안내와 재개',
        'knowledge': {'scope': 'universal'},
        'workStatus': {'code': 'waiting', 'label': '오늘은 브레이크 타임이 없어요'},
      },
      {
        'id': 'b',
        'title': '국물 배치 · 냉각과 보관',
        'knowledge': {'scope': 'process'},
        'workStatus': {'code': 'event', 'label': '작업을 시작할 때 체크리스트가 만들어져요'},
      },
      {
        'id': 'c',
        'title': '떡 · 개봉과 보관',
        'knowledge': {'scope': 'process'},
        'workStatus': {
          'code': 'incomplete',
          'label': '제품·공정에 맞는 매장 기준을 입력해 주세요',
        },
      },
      {
        'id': 'd',
        'title': '메뉴 · 기본 레시피',
        'workStatus': {'code': 'reference', 'label': '필요할 때 보는 매뉴얼이에요'},
      },
    ];
    final ops = OperationsController(
      client: MockClient((_) async => response(data)),
    );
    addTearDown(ops.dispose);
    await ops.refresh();
    final work = WorkController(MemoryStore());
    addTearDown(work.dispose);
    for (final width in [320.0, 390.0, 1200.0]) {
      tester.view.physicalSize = Size(width, 900);
      final key = GlobalKey();
      await tester.pumpWidget(
        Tap2workApp(
          controller: work,
          homeOverride: MediaQuery(
            data: MediaQueryData(
              textScaler: TextScaler.linear(1.2),
              disableAnimations: true,
            ),
            child: RepaintBoundary(
              key: key,
              child: ManualWorkScreen(ops: ops),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.runAsync(() async {
        final img =
            await (key.currentContext!.findRenderObject()
                    as RenderRepaintBoundary)
                .toImage();
        final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
        final file = File('../.local/manual-work-review/${width.toInt()}.png');
        await file.parent.create(recursive: true);
        await file.writeAsBytes(bytes!.buffer.asUint8List());
        img.dispose();
      });
    }
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
