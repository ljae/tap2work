import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:tap2work/main.dart';
import 'package:tap2work/state/operations_controller.dart';
import 'package:tap2work/state/work_controller.dart';
import 'operations_test.dart' show sample, response;
import 'work_controller_test.dart' show MemoryStore;

void main() {
  for (final width in [320.0, 1200.0]) {
    testWidgets(
      'all menu titles and manual searches share one layout at $width',
      (tester) async {
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final data = sample();
        data['manualSearch'] = [
          {
            'title': '손 씻기',
            'tapTitle': '준비',
            'manual': '손을 씻어요.',
            'tags': <String>[],
          },
        ];
        final ops = OperationsController(
          readOnly: true,
          client: MockClient((_) async => response(data)),
        );
        addTearDown(ops.dispose);
        await ops.refresh();
        await tester.pumpWidget(
          Tap2workApp(
            controller: WorkController(MemoryStore()),
            operations: ops,
          ),
        );
        await tester.pumpAndSettle();
        final search = find.byKey(const ValueKey('global-manual-search'));
        final title = find.byKey(const ValueKey('menu-title'));
        final searchRect = tester.getRect(search);
        final titleRect = tester.getRect(title);
        for (var index = 0; index < 4; index++) {
          await tester.tap(find.byKey(ValueKey('floating-menu-$index')));
          await tester.pumpAndSettle();
          expect(
            tester.widget<Text>(title).data,
            ['업무', '매뉴얼', '직원', '우리매장'][index],
          );
          expect(tester.getRect(search), searchRect);
          expect(tester.getRect(title).topLeft, titleRect.topLeft);
          expect(find.text('전체 매장 매뉴얼 검색'), findsNothing);
          await tester.enterText(search, '손');
          await tester.pumpAndSettle();
          expect(find.text('손 씻기'), findsOneWidget);
          expect(tester.takeException(), isNull);
        }
      },
    );
  }
}
