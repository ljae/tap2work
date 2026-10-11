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
import 'package:tap2work/ui/shared_welcome_screen.dart';
import '../test/operations_test.dart' show response;
import '../test/shared_welcome_test.dart' show welcomeData;
import '../test/work_controller_test.dart' show MemoryStore;

void main() {
  testWidgets('capture welcome at phone and desktop sizes', (tester) async {
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
      for (final changed in [false, true]) {
        tester.view.physicalSize = Size(width, 844);
        final data = welcomeData(actor: 'crew');
        data['store'] = {'name': '예시 식당'};
        data['welcome']['title'] = '우리 매장에 오신 것을 환영해요';
        data['welcome']['body'] =
            '처음 하는 일은 동료와 함께 확인해 주세요. 모르는 점이나 위험한 상황은 바로 물어봐도 괜찮아요.';
        if (changed) data['welcomeAcknowledgment'] = {'importantRevision': 0};
        data['zones'] = [
          {
            'id': 'wash',
            'name': '세척 구역',
            'floor': '1층',
            'description': '주방 안쪽',
          },
        ];
        final ops = OperationsController(
          accessToken: () async => 'review',
          client: MockClient((_) async => response(data)),
        );
        await ops.refresh();
        final key = GlobalKey();
        await tester.pumpWidget(
          Tap2workApp(
            controller: work,
            homeOverride: RepaintBoundary(
              key: key,
              child: SharedWelcomeScreen(ops: ops),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.runAsync(() async {
          final picture =
              await (key.currentContext!.findRenderObject()
                      as RenderRepaintBoundary)
                  .toImage();
          final bytes = await picture.toByteData(
            format: ui.ImageByteFormat.png,
          );
          Directory('../.local/welcome-review').createSync(recursive: true);
          File(
            '../.local/welcome-review/${changed ? 'changed' : 'first'}-${width.toInt()}.png',
          ).writeAsBytesSync(bytes!.buffer.asUint8List());
          picture.dispose();
        });
        await tester.pumpWidget(const SizedBox.shrink());
        ops.dispose();
      }
    }
  });
}
