import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:tap2work/state/operations_controller.dart';
import 'package:tap2work/ui/direct_edit.dart';
import 'manual_workspace_test.dart' show directoryData, mount, click;
import 'operations_test.dart' show response;

void main() {
  testWidgets(
    'generated today rows enter shared edit mode without offering invalid edits',
    (tester) async {
      final data = directoryData();
      (data['manualSearch'] as List).add({
        'id': 'today/prep',
        'tapId': 'today',
        'title': '오늘 준비',
        'tapTitle': '준비 업무',
        'folderId': 'general',
        'editable': false,
        'manual': '오늘 생성된 작업',
      });
      final ops = OperationsController(
        readOnly: true,
        client: MockClient((_) async => response(data)),
      );
      addTearDown(ops.dispose);
      await mount(tester, ops);
      final today = find.byKey(
        const ValueKey('manual-content-frame-today/prep'),
      );
      await tester.longPress(today);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('manual-edit-done')), findsOneWidget);
      expect(tester.widget<DirectEditFrame>(today).active, isFalse);
      expect(
        find.descendant(of: today, matching: find.byTooltip('위치 이동')),
        findsNothing,
      );
      expect(find.textContaining('조회 전용'), findsWidgets);
      expect(
        tester
            .widget<DirectEditFrame>(
              find.byKey(const ValueKey('manual-tree-frame-tap:a')),
            )
            .active,
        isTrue,
      );
    },
  );

  testWidgets(
    'long press on content enables directory editing and a direct move action',
    (tester) async {
      final ops = OperationsController(
        readOnly: true,
        client: MockClient((_) async => response(directoryData())),
      );
      addTearDown(ops.dispose);
      await mount(tester, ops);
      await click(tester, 'manual-node-tap:a');
      await tester.longPress(
        find.byKey(const ValueKey('manual-content-frame-a/s1')),
      );
      await tester.pumpAndSettle();
      for (final id in ['group:general', 'tap:a', 'task:s1:a']) {
        expect(
          tester
              .widget<DirectEditFrame>(
                find.byKey(ValueKey('manual-tree-frame-$id')),
              )
              .active,
          isTrue,
        );
        expect(find.byKey(ValueKey('manual-actions-$id')), findsOneWidget);
      }
      final move = find.descendant(
        of: find.byKey(const ValueKey('manual-drag-task:s1:a')),
        matching: find.byTooltip('위치 이동'),
      );
      expect(move, findsOneWidget);
      await tester.tap(move);
      await tester.pumpAndSettle();
      expect(find.text('마감 / 정리 TAP · 맨 아래'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('phone pane navigation retains editing until done', (
    tester,
  ) async {
    final ops = OperationsController(
      readOnly: true,
      client: MockClient((_) async => response(directoryData())),
    );
    addTearDown(ops.dispose);
    await mount(tester, ops, width: 320);
    await click(tester, 'manual-node-tap:a');
    await tester.longPress(find.byKey(const ValueKey('manual-node-task:s1:a')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('매뉴얼 2'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<DirectEditFrame>(
            find.byKey(const ValueKey('manual-content-frame-a/s1')),
          )
          .active,
      isTrue,
    );
    expect(find.byTooltip('위치 이동'), findsWidgets);
    await tester.tap(find.text('디렉토리'));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('manual-actions-task:s1:a')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('manual-edit-done')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('manual-actions-task:s1:a')),
      findsNothing,
    );
    expect(find.byKey(const ValueKey('manual-edit-done')), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
