import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:tap2work/main.dart';
import 'package:tap2work/state/operations_controller.dart';
import 'package:tap2work/state/work_controller.dart';
import 'operations_test.dart' show sample, response;
import 'work_controller_test.dart' show MemoryStore;

Json layoutSample([String role = 'owner']) => {
  ...sample(role),
  ...jsonDecode(File('test/fixtures/layout.json').readAsStringSync()) as Json,
};
Future<void> openMap(WidgetTester tester, OperationsController ops) async {
  await ops.refresh();
  await tester.pumpWidget(
    Tap2workApp(controller: WorkController(MemoryStore()), operations: ops),
  );
  await tester.tap(find.byKey(const ValueKey('floating-menu-3')));
  await tester.pumpAndSettle();
}

Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void expectSummary(String id, String label, String value) {
  final card = find.byKey(Key('layout-summary-$id'));
  expect(find.descendant(of: card, matching: find.text(label)), findsOneWidget);
  expect(find.descendant(of: card, matching: find.text(value)), findsOneWidget);
}

void main() {
  testWidgets('drag and resize snap to grid and save only the isolated draft', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    Json? posted;
    final state = layoutSample();
    final ops = OperationsController(
      client: MockClient((r) async {
        if (r.method == 'POST') posted = jsonDecode(r.body) as Json;
        return response(state);
      }),
    );
    addTearDown(ops.dispose);
    await openMap(tester, ops);
    await tapVisible(tester, find.widgetWithText(FilledButton, '배치 설정'));
    await tapVisible(tester, find.widgetWithText(ChoiceChip, '1번 테이블'));
    final zone = find.byKey(const ValueKey('move-zone-table-1'));
    await tester.ensureVisible(zone);
    final unit = tester.getSize(zone).width / 3;
    await tester.drag(zone, Offset(0, unit));
    await tester.pumpAndSettle();
    final handle = find.byKey(const ValueKey('resize-zone-table-1'));
    await tester.drag(handle, Offset(unit, 0));
    await tester.pumpAndSettle();
    expect(ops.rows('zones').firstWhere((z) => z['id'] == 'table-1')['y'], 1);
    await tester.tap(find.byKey(const Key('save-layout')));
    await tester.pumpAndSettle();
    final saved = (posted!['zones'] as List).firstWhere(
      (z) => z['id'] == 'table-1',
    );
    expect(saved['y'], 2);
    expect(saved['width'], 4);
    expect(tester.takeException(), isNull);
  });

  for (final width in [320.0, 390.0, 430.0, 1440.0]) {
    testWidgets('layout counts, editor dialog and draft movement fit $width', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      Json? posted;
      var state = layoutSample();
      final ops = OperationsController(
        client: MockClient((r) async {
          if (r.method == 'POST') {
            posted = jsonDecode(r.body) as Json;
            state = {
              ...state,
              'layout': posted!['layout'],
              'zones': posted!['zones'],
              'revision': 3,
            };
          }
          return response(state);
        }),
      );
      addTearDown(ops.dispose);
      await openMap(tester, ops);
      expectSummary('tables', '테이블', '6개');
      expectSummary('seats', '좌석 정원', '24석');
      await tapVisible(tester, find.widgetWithText(FilledButton, '배치 설정'));
      await tapVisible(tester, find.widgetWithText(ChoiceChip, '1번 테이블'));
      await tapVisible(tester, find.byTooltip('아래로 이동'));
      await tapVisible(tester, find.text('이름·크기·좌석 수정'));
      await tester.enterText(
        find.widgetWithText(TextFormField, '이름'),
        '창가 테이블',
      );
      await tester.enterText(find.widgetWithText(TextFormField, '좌석 수'), '6');
      await tester.tap(find.text('배치에 적용'));
      await tester.pumpAndSettle();
      expectSummary('seats', '좌석 정원', '26석');
      expect(
        ops.rows('zones').firstWhere((z) => z['id'] == 'table-1')['seats'],
        4,
        reason: 'draft is not shared before save',
      );
      await tester.tap(find.byKey(const Key('save-layout')));
      await tester.pumpAndSettle();
      expect(posted!['action'], 'save_layout');
      expect(posted!['revision'], 2);
      final table = (posted!['zones'] as List).firstWhere(
        (z) => z['id'] == 'table-1',
      );
      expect(table['seats'], 6);
      expect(table['y'], 2);
      expect(table['name'], '창가 테이블');
      expectSummary('tables', '테이블', '6개');
      expectSummary('seats', '좌석 정원', '26석');
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'public review supports draft preview but never saves, and cancel discards changes',
    (tester) async {
      var posts = 0;
      final ops = OperationsController(
        readOnly: true,
        client: MockClient((r) async {
          if (r.method == 'POST') posts++;
          return response(layoutSample());
        }),
      );
      addTearDown(ops.dispose);
      await openMap(tester, ops);
      await tapVisible(tester, find.widgetWithText(FilledButton, '배치 설정'));
      await tapVisible(tester, find.widgetWithText(ChoiceChip, '1번 테이블'));
      await tapVisible(tester, find.text('배치에서 삭제'));
      expectSummary('tables', '테이블', '5개');
      expect(
        tester
            .widget<FilledButton>(find.byKey(const Key('save-layout')))
            .onPressed,
        isNull,
      );
      await tester.tap(find.byTooltip('편집 닫기'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('변경 취소'));
      await tester.pumpAndSettle();
      expectSummary('tables', '테이블', '6개');
      expect(posts, 0);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('crew sees map and materials without layout settings', (
    tester,
  ) async {
    final ops = OperationsController(
      client: MockClient((r) async => response(layoutSample('crew'))),
    );
    addTearDown(ops.dispose);
    await openMap(tester, ops);
    expectSummary('seats', '좌석 정원', '24석');
    expect(find.text('배치 설정'), findsNothing);
    expect(find.text('재료 위치와 수량'), findsOneWidget);
    expect(find.text('전체 테이블과 기기'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'stale layout saves carry original revision and preserve draft after conflict',
    (tester) async {
      Json? posted;
      var revision = 2;
      final ops = OperationsController(
        client: MockClient((r) async {
          if (r.method == 'POST') {
            posted = jsonDecode(r.body) as Json;
            return response({'error': '다른 동료가 먼저 업데이트했어요.'}, 409);
          }
          return response({...layoutSample(), 'revision': revision});
        }),
      );
      addTearDown(ops.dispose);
      await openMap(tester, ops);
      await tapVisible(tester, find.widgetWithText(FilledButton, '배치 설정'));
      await tapVisible(tester, find.widgetWithText(ChoiceChip, '1번 테이블'));
      await tapVisible(tester, find.byTooltip('아래로 이동'));
      revision = 3;
      await ops.refresh();
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('save-layout')));
      await tester.pumpAndSettle();
      expect(posted!['revision'], 2);
      expect(find.text('매장 배치 설정'), findsOneWidget);
      expect(find.text('다른 동료가 먼저 업데이트했어요.'), findsWidgets);
      expect(find.text('최신 배치 불러오기'), findsOneWidget);
    },
  );

  testWidgets('adding an item previews counts; overlap cannot be submitted', (
    tester,
  ) async {
    var posts = 0;
    final ops = OperationsController(
      client: MockClient((r) async {
        if (r.method == 'POST') posts++;
        return response(layoutSample());
      }),
    );
    addTearDown(ops.dispose);
    await openMap(tester, ops);
    await tapVisible(tester, find.widgetWithText(FilledButton, '배치 설정'));
    await tapVisible(tester, find.widgetWithText(OutlinedButton, '테이블·기기 추가'));
    await tester.enterText(
      find.widgetWithText(TextFormField, '가로 위치 (칸)'),
      '1',
    );
    await tester.tap(find.text('배치에 적용'));
    await tester.pumpAndSettle();
    expectSummary('tables', '테이블', '7개');
    await tester.tap(find.byKey(const Key('save-layout')));
    await tester.pumpAndSettle();
    expect(posts, 0);
    expect(find.textContaining('위치가 겹쳐요'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'restaurant size and equipment presets save with a free initial position',
    (tester) async {
      Json? submitted;
      var state = layoutSample();
      final ops = OperationsController(
        client: MockClient((r) async {
          if (r.method == 'POST') {
            submitted = jsonDecode(r.body) as Json;
            state = {
              ...state,
              'layout': submitted!['layout'],
              'zones': submitted!['zones'],
              'revision': 3,
            };
          }
          return response(state);
        }),
      );
      addTearDown(ops.dispose);
      await openMap(tester, ops);
      await tapVisible(tester, find.widgetWithText(FilledButton, '배치 설정'));
      await tapVisible(tester, find.text('매장 크기·이름'));
      await tester.enterText(
        find.widgetWithText(TextFormField, '매장 배치 이름'),
        '연남점 1층',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, '가로 칸 수'),
        '20',
      );
      await tester.tap(find.text('크기 적용'));
      await tester.pumpAndSettle();
      await tapVisible(
        tester,
        find.widgetWithText(OutlinedButton, '테이블·기기 추가'),
      );
      await tester.tap(find.byType(DropdownButtonFormField<String>).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('주요 기기').last);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ActionChip, '식기세척기'));
      await tester.tap(find.text('배치에 적용'));
      await tester.pumpAndSettle();
      expectSummary('equipment', '주요 기기', '6대');
      await tester.tap(find.byKey(const Key('save-layout')));
      await tester.pumpAndSettle();
      expect(submitted!['layout']['columns'], 20);
      expect(submitted!['layout']['name'], '연남점 1층');
      final added = (submitted!['zones'] as List).last;
      expect(added['kind'], 'equipment');
      expect(added['name'], '식기세척기');
      expect(added['seats'], 0);
      expect(tester.takeException(), isNull);
    },
  );
}
