import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:tap2work/main.dart';
import 'package:tap2work/state/operations_controller.dart';
import 'package:tap2work/state/work_controller.dart';
import 'operations_test.dart' show sample, response;
import 'checklist_test.dart' show fixture;
import 'work_controller_test.dart' show MemoryStore;

void main() {
  testWidgets(
    'fixed part controls filter the actual board and restore all parts',
    (tester) async {
      final data = fixture();
      data['tasks'][0]['partId'] = 'kitchen';
      data['tasks'][1]['partId'] = 'hall';
      final ops = OperationsController(
        readOnly: true,
        client: MockClient((_) async => response(data)),
      );
      addTearDown(ops.dispose);
      await ops.refresh();
      await tester.pumpWidget(
        Tap2workApp(controller: WorkController(MemoryStore()), operations: ops),
      );
      await tester.pumpAndSettle();
      final kitchen = find.byKey(const ValueKey('tap-daily-prep'));
      final hall = find.byKey(const ValueKey('tap-daily-broth'));
      expect(kitchen, findsOneWidget);
      expect(hall, findsOneWidget);
      await tester.tap(find.widgetWithText(ChoiceChip, '주방'));
      await tester.pumpAndSettle();
      expect(kitchen, findsOneWidget);
      expect(hall, findsNothing);
      await tester.tap(find.widgetWithText(ChoiceChip, '홀'));
      await tester.pumpAndSettle();
      expect(kitchen, findsNothing);
      expect(hall, findsOneWidget);
      await tester.tap(find.widgetWithText(ChoiceChip, '전체파트'));
      await tester.pumpAndSettle();
      expect(kitchen, findsOneWidget);
      expect(hall, findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  for (final width in [320.0, 1200.0]) {
    testWidgets(
      'menu headers are consistent and schedule starts with calendar at $width',
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

        for (var index = 0; index < 4; index++) {
          await tester.tap(find.byKey(ValueKey('floating-menu-$index')));
          await tester.pumpAndSettle();
          if (index == 3) {
            expect(tester.widget<Text>(title).data, '우리매장');
          } else {
            expect(title, findsNothing);
            if (index == 0) {
              expect(find.widgetWithText(ChoiceChip, '전체파트'), findsOneWidget);
              expect(find.textContaining('손잡이를 끌어'), findsNothing);
              expect(find.text('재고 수량 확인하기'), findsNothing);
            }
            if (index == 1) {
              expect(
                find.byKey(const ValueKey('manual-add-folder')),
                findsOneWidget,
              );
              expect(
                find.byKey(const ValueKey('manual-add-tap')),
                findsOneWidget,
              );
              expect(
                find.byKey(const ValueKey('manual-backup')),
                findsOneWidget,
              );
            }
            if (index == 2) {
              expect(
                find.byKey(const ValueKey('schedule-header')),
                findsOneWidget,
              );
              expect(find.text('보기'), findsNothing);
              expect(find.byIcon(Icons.info_outline), findsNothing);
            }
          }
          expect(tester.getRect(search), searchRect);
          expect(find.text('전체 매장 매뉴얼 검색'), findsNothing);
          await tester.enterText(search, '손');
          await tester.pumpAndSettle();
          expect(find.text('손 씻기'), findsWidgets);
          expect(tester.takeException(), isNull);
        }
      },
    );
  }
}
