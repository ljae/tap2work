import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:tap2work/state/operations_controller.dart';
import 'manual_workspace_test.dart' as manual;
import 'manual_market_test.dart' as market;
import 'operations_test.dart' show response;

void main() {
  testWidgets('phone drag scrolls a long directory at the bottom edge', (
    tester,
  ) async {
    final data = manual.directoryData();
    for (var i = 0; i < 40; i++) {
      data['taskTemplates'].add({
        'id': 'extra-$i',
        'title': '추가 $i',
        'folderId': 'general',
        'steps': [],
      });
    }
    final ops = OperationsController(
      readOnly: true,
      client: MockClient((_) async => response(data)),
    );
    addTearDown(ops.dispose);
    await manual.mount(tester, ops, width: 390);
    await tester.longPress(
      find.byKey(const ValueKey('manual-node-group:general')),
    );
    await tester.pumpAndSettle();
    final source = find.byKey(const ValueKey('manual-drag-tap:a'));
    final scroll = tester.state<ScrollableState>(
      find.descendant(
        of: find.byKey(const ValueKey('manual-directory')),
        matching: find.byType(Scrollable),
      ),
    );
    final rect = tester.getRect(find.byKey(const ValueKey('manual-directory')));
    final gesture = await tester.startGesture(tester.getCenter(source));
    await gesture.moveBy(const Offset(0, 25));
    await gesture.moveTo(Offset(rect.right - 30, rect.bottom - 8));
    await tester.pump(const Duration(milliseconds: 400));
    expect(scroll.position.pixels, greaterThan(0));
    await gesture.cancel();
    await tester.pumpAndSettle();
    final offset = scroll.position.pixels;
    await tester.pump(const Duration(milliseconds: 400));
    expect(scroll.position.pixels, offset);
    expect(tester.takeException(), isNull);
  });
  for (final width in [320.0, 390.0]) {
    for (final kind in ['tap', 'task']) {
      testWidgets('phone $kind drag sends move and exposes done at $width', (
        tester,
      ) async {
        Json? sent;
        final ops = OperationsController(
          client: MockClient((r) async {
            if (r.method == 'POST') sent = jsonDecode(r.body);
            return response(manual.directoryData());
          }),
        );
        addTearDown(ops.dispose);
        await manual.mount(tester, ops, width: width);
        await tester.longPress(
          find.byKey(const ValueKey('manual-node-group:general')),
        );
        await tester.pumpAndSettle();
        if (kind == 'task') await manual.click(tester, 'manual-node-tap:a');
        final source = find.byKey(
          ValueKey(
            kind == 'tap' ? 'manual-drag-tap:a' : 'manual-drag-task:s1:a',
          ),
        );
        final target = find.byKey(
          ValueKey(
            kind == 'tap' ? 'manual-node-group:close' : 'manual-node-tap:b',
          ),
        );
        await tester.ensureVisible(source);
        final start = tester.getCenter(source), end = tester.getCenter(target);
        await tester.dragFrom(start, end - start);
        await tester.pumpAndSettle();
        expect(sent?['action'], 'move_manual_node');
        expect(sent?['kind'], kind);
        expect(sent?['targetId'], kind == 'tap' ? 'close' : 'b');
        expect(sent?['revision'], 2);
        await tester.ensureVisible(find.text('편집 완료'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('편집 완료'));
        await tester.pumpAndSettle();
        expect(find.byType(Draggable<Json>), findsNothing);
        expect(find.byKey(const ValueKey('manual-edit-done')), findsNothing);
        expect(tester.takeException(), isNull);
      });
    }
    testWidgets(
      'market and edit done remain visible in a short phone pane at $width',
      (tester) async {
        final ops = OperationsController(
          client: MockClient((_) async => response(market.fixture())),
        );
        addTearDown(ops.dispose);
        await manual.mount(tester, ops, width: width);
        expect(find.byKey(const ValueKey('manual-edit-done')), findsNothing);
        expect(find.text('전체 편집'), findsNothing);
        tester.view.physicalSize = Size(width, 360);
        await tester.pumpAndSettle();
        await tester.longPress(
          find.byKey(const ValueKey('manual-node-group:general')),
        );
        await tester.pumpAndSettle();
        expect(find.text('매뉴얼 마켓').hitTestable(), findsOneWidget);
        await tester.ensureVisible(find.text('편집 완료'));
        await tester.pumpAndSettle();
        expect(find.text('편집 완료').hitTestable(), findsOneWidget);
        final titleY = tester
            .getCenter(find.byKey(const ValueKey('manual-header')))
            .dy;
        for (final key in [
          'manual-market-button',
          'manual-print-button',
          'manual-edit-done',
        ]) {
          expect(
            tester.getCenter(find.byKey(ValueKey(key))).dy,
            closeTo(titleY, 1),
          );
        }
        await tester.ensureVisible(
          find.byKey(const ValueKey('manual-market-button')),
        );
        await tester.pumpAndSettle();
        expect(find.text('매뉴얼 마켓').hitTestable(), findsOneWidget);
        await tester.tap(find.byKey(const ValueKey('manual-market-button')));
        await tester.pumpAndSettle();
        expect(find.text('내 업종이나 필요한 업무 검색'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets(
    'chosen market checklist appears in operating directory after import',
    (tester) async {
      final data = market.fixture();
      Json? sent;
      final ops = OperationsController(
        client: MockClient((r) async {
          if (r.method == 'POST') {
            sent = jsonDecode(r.body);
            data['revision'] = 3;
            data['catalogLinks']['new-tap'] = {
              'mode': 'linked',
              'sourceId': 'common/0',
            };
            data['taskTemplates'].add({
              'id': 'new-tap',
              'title': '가져온 운영 체크리스트',
              'folderId': 'general',
              'steps': [],
            });
            data['manualSearch'].add({
              'id': 'new-tap/new-task',
              'templateId': 'new-tap',
              'tapId': 'new-tap',
              'sourceStepId': 'new-task',
              'tapTitle': '가져온 운영 체크리스트',
              'title': '새 확인 항목',
              'folderId': 'general',
              'folderName': '오픈',
              'manual': '확인 방법',
              'editable': true,
            });
          }
          return response(data);
        }),
      );
      addTearDown(ops.dispose);
      await manual.mount(tester, ops, width: 390);
      await tester.ensureVisible(
        find.byKey(const ValueKey('manual-market-button')),
      );
      await tester.tap(find.byKey(const ValueKey('manual-market-button')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '공용 TAP 0');
      await tester.pumpAndSettle();
      await tester.tap(find.byType(Checkbox).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('담은 1개 확인'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('선택한 1개 가져오기'));
      await tester.pumpAndSettle();
      expect(sent?['action'], 'import_market_taps');
      expect(sent?['sourceIds'], ['common/0']);
      expect(find.text('가져온 운영 체크리스트'), findsOneWidget);
      expect(find.text('새 확인 항목').hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
