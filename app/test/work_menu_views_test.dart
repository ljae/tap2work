import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tap2work/main.dart';
import 'package:tap2work/state/operations_controller.dart';
import 'package:tap2work/state/work_controller.dart';
import 'package:tap2work/ui/manual_hierarchy.dart';
import 'package:tap2work/ui/tap_card.dart';
import 'checklist_test.dart' show fixture;
import 'manual_workspace_test.dart' show directoryData;
import 'operations_test.dart' show response;
import 'tap_workspace_test.dart' show mountBoard, openCard;
import 'work_controller_test.dart' show MemoryStore;

const captureViews = bool.fromEnvironment('CAPTURE_WORK_MENU');

void main() {
  setUpAll(() async {
    if (!captureViews) return;
    for (final font in {
      'Pretendard': 'assets/fonts/PretendardVariable.ttf',
      'MaterialIcons': 'fonts/MaterialIcons-Regular.otf',
      'packages/cupertino_icons/CupertinoIcons':
          'packages/cupertino_icons/assets/CupertinoIcons.ttf',
    }.entries) {
      await (FontLoader(font.key)..addFont(rootBundle.load(font.value))).load();
    }
  });
  for (final width in [320.0, 390.0, 1200.0]) {
    for (final scale in [1.0, 1.5]) {
      testWidgets('view toggles share their action row at $width / $scale', (
        t,
      ) async {
        t.view.physicalSize = Size(width, 1000);
        t.view.devicePixelRatio = 1;
        t.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(t.view.resetPhysicalSize);
        addTearDown(t.view.resetDevicePixelRatio);
        addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
        final data = fixture();
        final directory = directoryData();
        data['taskTemplates'] = directory['taskTemplates'];
        data['manualSearch'] = directory['manualSearch'];
        data['ownerWorkflow'] = {'pending': []};
        (data['taskTemplates'] as List).add({
          'id': 'rice-recipe',
          'title': '볶음밥 레시피',
          'folderId': 'general',
          'knowledge': {'useCase': 'recipe'},
          'steps': [
            {'id': 'rice-1', 'title': '재료 준비', 'manual': '매장 레시피의 기준량을 확인해요.'},
          ],
        });
        var writes = 0;
        final ops = OperationsController(
          readOnly: true,
          client: MockClient((r) async {
            if (r.method == 'POST') writes++;
            return response(data);
          }),
        );
        final work = WorkController(MemoryStore());
        addTearDown(ops.dispose);
        addTearDown(work.dispose);
        await ops.refresh();
        final boundary = GlobalKey();
        await t.pumpWidget(
          RepaintBoundary(
            key: boundary,
            child: Tap2workApp(controller: work, operations: ops),
          ),
        );
        await t.pumpAndSettle();
        Future<void> capture(String name) async {
          if (!captureViews) return;
          await t.runAsync(() async {
            final render =
                boundary.currentContext!.findRenderObject()!
                    as RenderRepaintBoundary;
            final image = await render.toImage();
            final bytes = await image.toByteData(
              format: ui.ImageByteFormat.png,
            );
            final dir = Directory('../.local/work-menu-20261021/captures')
              ..createSync(recursive: true);
            File(
              '${dir.path}/$name-${width.toInt()}-$scale.png',
            ).writeAsBytesSync(bytes!.buffer.asUint8List());
            image.dispose();
          });
        }

        final workToggle = find.byKey(const ValueKey('work-view-toggle'));
        final service = find.text('근무 준비·인계');
        final serviceRect = t.getRect(service),
            toggleRect = t.getRect(workToggle);
        expect(serviceRect.center.dy, closeTo(toggleRect.center.dy, 1));
        expect(serviceRect.right, lessThanOrEqualTo(toggleRect.left));
        expect(find.textContaining('운영 준비 · 내일 미리보기'), findsNothing);
        final first = find.byKey(const ValueKey('tap-daily-prep'));
        final second = find.byKey(const ValueKey('tap-daily-broth'));
        expect(t.getRect(first).left, t.getRect(second).left);
        expect(t.getRect(first).width, closeTo(width - 48, 1));
        await capture('work');
        await openCard(t, 'tap-daily-prep');
        await openCard(t, 'small-s1');
        expect(
          find.byKey(const ValueKey('method-inline-daily-prep-s1')),
          findsOneWidget,
        );
        await capture('method');
        // View changes never complete work or send a request.
        await t.ensureVisible(workToggle);
        await t.tap(find.byKey(const ValueKey('view-toggle-option-true')));
        await t.pumpAndSettle();
        expect(find.text('완료했어요'), findsOneWidget);
        expect(first, findsNothing);
        await t.tap(find.byKey(const ValueKey('view-toggle-option-false')));
        await t.pumpAndSettle();
        expect(first, findsOneWidget);
        await t.tap(find.byKey(const ValueKey('floating-menu-1')));
        await t.pumpAndSettle();
        expect(find.byType(ManualCategoryPicker), findsNothing);
        final manualToggle = find.byKey(const ValueKey('manual-view-toggle'));
        final review = find.textContaining('사장님 검토');
        expect(
          t.getRect(review).center.dy,
          closeTo(t.getRect(manualToggle).center.dy, 1),
        );
        expect(
          t.getRect(review).right,
          lessThanOrEqualTo(t.getRect(manualToggle).left),
        );
        await capture('manual');
        await t.tap(find.byKey(const ValueKey('view-toggle-option-true')));
        await t.pumpAndSettle();
        expect(find.text('볶음밥 레시피'), findsOneWidget);
        expect(find.byKey(const ValueKey('manual-node-tap:a')), findsNothing);
        await capture('recipe');
        await t.tap(find.byKey(const ValueKey('view-toggle-option-false')));
        await t.pumpAndSettle();
        expect(find.text('볶음밥 레시피'), findsNothing);
        expect(writes, 0);
        expect(t.takeException(), isNull);
      });
    }
  }

  for (final succeeds in [true, false]) {
    testWidgets(
      'TAP order remains at drop position while saving, success=$succeeds',
      (t) async {
        final data = fixture();
        final pending = Completer<http.Response>();
        final posts = <Json>[];
        final ops = OperationsController(
          client: MockClient((r) async {
            if (r.method == 'POST') {
              posts.add(jsonDecode(r.body) as Json);
              return pending.future;
            }
            return response(data);
          }),
        );
        addTearDown(ops.dispose);
        await mountBoard(t, ops, width: 390);
        final first = find.byKey(const ValueKey('tap-daily-prep'));
        final second = find.byKey(const ValueKey('tap-daily-broth'));
        final sizeBefore = t.getSize(first);
        t
            .widget<ReorderableListView>(
              find.byKey(const ValueKey('tap-reorder-list')),
            )
            .onReorder(1, 0);
        await t.pump();
        expect(t.getSize(first), sizeBefore);
        expect(t.widget<TapCard>(first).checkEnabled, false);
        expect(t.getTopLeft(second).dy, lessThan(t.getTopLeft(first).dy));
        expect(posts.single['status'], 'keep');
        expect(posts.single['revision'], data['revision']);
        if (succeeds) {
          data['tasks'][0]['displayOrder'] = 1;
          data['tasks'][1]['displayOrder'] = 0;
          pending.complete(response(data));
        } else {
          pending.complete(response({'error': '저장에 실패했어요.'}, 503));
        }
        await t.pumpAndSettle();
        expect(t.getTopLeft(second).dy < t.getTopLeft(first).dy, succeeds);
        expect(t.widget<TapCard>(first).checked, false);
        expect(t.widget<TapCard>(second).checked, false);
        expect(t.takeException(), isNull);
      },
    );
  }

  testWidgets('quantity TAP stays in to do until its final quantity is saved', (
    t,
  ) async {
    final data = fixture();
    data['tasks'][0]['assignmentScopeVersion'] = 2;
    data['tasks'][0]['settings'] = {
      'completionPolicy': {'kind': 'quantity'},
    };
    for (final step in data['tasks'][0]['steps']) {
      step['completedAt'] = '2026-10-21T01:00:00Z';
    }
    final ops = OperationsController(
      readOnly: true,
      client: MockClient((_) async => response(data)),
    );
    addTearDown(ops.dispose);
    await mountBoard(t, ops);
    await openCard(t, 'tap-daily-prep');
    expect(find.byKey(const ValueKey('tap-daily-prep')), findsOneWidget);
    expect(find.byType(FilledButton), findsOneWidget);
  });
}
