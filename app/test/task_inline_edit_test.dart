import 'dart:convert';
import 'dart:ui' show PointerDeviceKind;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:tap2work/state/operations_controller.dart';
import 'package:tap2work/ui/direct_edit.dart';
import 'package:tap2work/ui/tap_card.dart';
import 'checklist_test.dart' show fixture;
import 'operations_test.dart' show response;
import 'tap_workspace_test.dart' show mountBoard, openCard;

void main() {
  for (final width in [320.0, 390.0, 1200.0]) {
    testWidgets('work is execution and reference only at $width', (
      tester,
    ) async {
      final state = fixture();
      final original = jsonEncode(state['taskTemplates']);
      var posts = 0;
      final ops = OperationsController(
        readOnly: true,
        client: MockClient((r) async {
          if (r.method == 'POST') posts++;
          return response(state);
        }),
      );
      addTearDown(ops.dispose);
      await mountBoard(tester, ops, width: width);
      expect(find.byType(DirectEditFrame), findsNothing);
      expect(find.text('TAP 추가'), findsNothing);
      await tester.longPress(find.byKey(const ValueKey('tap-daily-prep')));
      await tester.pumpAndSettle();
      expect(find.text('편집 완료'), findsNothing);
      if (find.byKey(const ValueKey('tap-daily-prep')).evaluate().isNotEmpty) {
        await openCard(tester, 'tap-daily-prep');
      }
      await tester.longPress(find.text('도구 나누기'));
      await tester.pumpAndSettle();
      expect(find.text('TAP 규칙'), findsNothing);
      expect(find.text('Task 추가'), findsNothing);
      final card = tester.widget<TapCard>(
        find.byKey(const ValueKey('small-s1')),
      );
      expect(card.onEdit, isNull);
      expect(card.onCheck, isNotNull);
      expect(find.byType(ReorderableDragStartListener), findsWidgets);
      if (find.text('생재료와 완성식품 도구를 따로 놓아요.').evaluate().isEmpty) {
        card.onOpen();
        await tester.pumpAndSettle();
      }
      expect(find.text('생재료와 완성식품 도구를 따로 놓아요.'), findsOneWidget);
      expect(jsonEncode(ops.data!['taskTemplates']), original);
      expect(posts, 0);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets(
    'phone touch handles reorder TAP and Task without editing content',
    (tester) async {
      final state = fixture();
      final sent = <Json>[];
      final original = jsonEncode(state['taskTemplates']);
      final ops = OperationsController(
        client: MockClient((r) async {
          if (r.method == 'POST') sent.add(jsonDecode(r.body) as Json);
          return response(state);
        }),
      );
      addTearDown(ops.dispose);
      await mountBoard(tester, ops, width: 390);
      final handle = find.byWidgetPredicate(
        (w) => w is Draggable<String> && w.data == 'daily-broth',
      );
      final target = find.byKey(const ValueKey('tap-daily-prep'));
      final gesture = await tester.startGesture(
        tester.getCenter(handle),
        kind: PointerDeviceKind.touch,
      );
      await gesture.moveTo(tester.getTopLeft(target) + const Offset(30, 5));
      await tester.pump(const Duration(milliseconds: 100));
      await gesture.up();
      await tester.pumpAndSettle();
      expect(sent.last['action'], 'move_tap');
      expect(sent.last['status'], 'keep');
      expect(sent.last['beforeTaskId'], 'daily-prep');
      await openCard(tester, 'tap-daily-prep');
      final handles = find.byType(ReorderableDragStartListener);
      await tester.drag(
        handles.first,
        const Offset(0, 230),
        kind: PointerDeviceKind.touch,
      );
      await tester.pumpAndSettle();
      expect(sent.last['action'], 'reorder_small_taps');
      expect(sent.last['stepIds'], ['s2', 's1']);
      expect(jsonEncode(ops.data!['taskTemplates']), original);
    },
  );
  testWidgets(
    'priority drop preserves status and rejects another status lane',
    (tester) async {
      Json? sent;
      final state = fixture();
      final ops = OperationsController(
        client: MockClient((r) async {
          if (r.method == 'POST') sent = jsonDecode(r.body) as Json;
          return response(state);
        }),
      );
      addTearDown(ops.dispose);
      await mountBoard(tester, ops);
      final details = DragTargetDetails<String>(
        data: 'daily-prep',
        offset: Offset.zero,
      );
      final done = tester.widget<DragTarget<String>>(
        find.byKey(const ValueKey('lane-완료')),
      );
      expect(done.onWillAcceptWithDetails!(details), false);
      final todo = tester.widget<DragTarget<String>>(
        find.byKey(const ValueKey('lane-할일')),
      );
      expect(todo.onWillAcceptWithDetails!(details), true);
      todo.onAcceptWithDetails!(details);
      await tester.pumpAndSettle();
      expect(sent?['action'], 'move_tap');
      expect(sent?['status'], 'keep');
      expect(sent?['folderId'], state['tasks'][0]['folderId'] ?? 'general');
    },
  );
  testWidgets('permission and fixed sequence disable Task priority dragging', (
    tester,
  ) async {
    final state = fixture()..['canEditTasks'] = false;
    final ops = OperationsController(
      readOnly: true,
      client: MockClient((_) async => response(state)),
    );
    addTearDown(ops.dispose);
    await mountBoard(tester, ops);
    await openCard(tester, 'tap-daily-prep');
    expect(find.byType(ReorderableDragStartListener), findsNothing);
    state['canEditTasks'] = true;
    state['tasks'][0]['settings'] = {'enforceSequence': true};
    await ops.refresh();
    await tester.pumpAndSettle();
    expect(find.byType(ReorderableDragStartListener), findsNothing);
  });
}
