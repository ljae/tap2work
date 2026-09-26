import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:tap2work/state/operations_controller.dart';
import 'package:tap2work/ui/tap_card.dart';
import 'package:tap2work/ui/tap_workspace.dart';
import 'checklist_test.dart' show fixture;
import 'operations_test.dart' show response;

Future<void> mountBoard(
  WidgetTester tester,
  OperationsController ops, {
  double width = 1200,
}) async {
  tester.view.physicalSize = Size(width, 1500);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await ops.refresh();
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: TapWorkspace(ops: ops, onStock: (_) async {}),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> openGroup(WidgetTester tester, String name) async {
  await tester.ensureVisible(find.widgetWithText(ChoiceChip, name).first);
  await tester.tap(find.widgetWithText(ChoiceChip, name).first);
  await tester.pumpAndSettle();
}

Future<void> openCard(WidgetTester tester, String key) async {
  final card = find.byKey(ValueKey(key));
  await tester.ensureVisible(card);
  tester.widget<TapCard>(card).onOpen();
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'TAP surface fills with progress and completed cards become pale',
    (tester) async {
      Future<Color> surface(int done) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: TapCard(
                level: 'TAP',
                title: '준비',
                subtitle: '샘플',
                total: 4,
                done: done,
                onOpen: () {},
                checked: done == 4,
              ),
            ),
          ),
        );
        expect(
          find.descendant(
            of: find.byType(TapCard),
            matching: find.byType(FractionallySizedBox),
          ),
          done > 0 && done < 4 ? findsOneWidget : findsNothing,
        );
        return tester
            .widget<Material>(
              find
                  .descendant(
                    of: find.byType(TapCard),
                    matching: find.byType(Material),
                  )
                  .first,
            )
            .color!;
      }

      final empty = await surface(0);
      final partial = await surface(2);
      final complete = await surface(4);
      expect(empty, Colors.white);
      expect(partial, Colors.white);
      expect(complete, const Color(0xFFF0F2F4));
    },
  );
  testWidgets('phone TAP controls keep drag, check and open separate', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var opened = 0;
    var checked = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TapCard(
            level: 'TAP',
            title: '긴 제목의 주문 처리 업무를 확인하는 카드',
            subtitle: '조리 · 가능한 담당자',
            dragHandle: const SizedBox(
              width: 32,
              height: 48,
              child: Icon(Icons.drag_indicator),
            ),
            assigneeBadges: const Text('현우 · 민지'),
            onOpen: () => opened++,
            onCheck: () => checked++,
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.text('현우 · 민지'), findsOneWidget);
    await tester.tap(find.byTooltip('완료하기'));
    expect(checked, 1);
    expect(opened, 0);
    await tester.tap(find.text('Small TAP'));
    expect(opened, 1);
    expect(checked, 1);
  });

  testWidgets('large text phone cards keep independent 48px actions', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var opened = 0;
    var checked = 0;
    const title = '긴 제목의 주문 처리 업무를 확인하는 카드';
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: Scaffold(
            body: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: TapCard(
                  level: 'TAP',
                  title: title,
                  subtitle: '조리 · 가능한 담당자',
                  dragHandle: const SizedBox(
                    width: 48,
                    height: 48,
                    child: Icon(Icons.drag_indicator),
                  ),
                  onOpen: () => opened++,
                  onCheck: () => checked++,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    final check = find.byTooltip('완료하기');
    final open = find.byWidgetPredicate(
      (widget) =>
          widget is Semantics && widget.properties.label == 'Small TAP 열기',
    );
    for (final control in [check, open]) {
      final size = tester.getSize(control);
      expect(size.width, greaterThanOrEqualTo(48));
      expect(size.height, greaterThanOrEqualTo(48));
    }
    await tester.tap(check);
    expect(checked, 1);
    expect(opened, 0);
    await tester.tap(open);
    expect(opened, 1);
    expect(checked, 1);
    expect(find.byTooltip(title), findsOneWidget);
  });

  testWidgets(
    'active Tappers supply role names and stable person colors at phone width',
    (tester) async {
      final data = fixture();
      data['tappers'] = [
        {
          'id': 'cook-1',
          'nickname': '현우',
          'rank': 'crew',
          'duties': ['조리'],
          'active': true,
        },
        {
          'id': 'cook-2',
          'nickname': '서진',
          'rank': 'crew',
          'duties': ['조리 보조'],
          'active': true,
        },
        {
          'id': 'cook-off',
          'nickname': '휴직',
          'rank': 'crew',
          'duties': ['조리'],
          'active': false,
        },
      ];
      final ops = OperationsController(
        readOnly: true,
        client: MockClient((_) async => response(data)),
      );
      addTearDown(ops.dispose);
      await mountBoard(tester, ops, width: 320);
      expect(find.text('현우'), findsWidgets);
      expect(find.text('서진'), findsWidgets);
      expect(find.text('휴직'), findsNothing);
      final card = tester.widget<TapCard>(
        find.byKey(const ValueKey('tap-daily-broth')),
      );
      expect(card.subtitle, contains('가능한 담당자'));
      expect(card.assigneeBadges, isNotNull);
      final badges = card.assigneeBadges! as Wrap;
      final colors = badges.children.map((entry) {
        final dot = (entry as Row).children.first as Container;
        return (dot.decoration! as BoxDecoration).color;
      }).toSet();
      expect(colors.length, 2);
      expect(colors, contains(card.accentColor));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'menu TAPs render in one order group and its touch action moves them together',
    (tester) async {
      final data = fixture();
      final first =
          (data['tasks'] as List).firstWhere((t) => t['kind'] == 'routine')
              as Json;
      final second = jsonDecode(jsonEncode(first)) as Json;
      first.addAll({
        'orderId': 'order-17',
        'orderNumber': 'A-17',
        'orderChannel': '배달',
        'orderPlatform': '배달의민족',
        'customerRequest': '수저 제외',
        'orderCreatedAt': '2026-09-24T09:00:00Z',
        'orderTargetMinutes': 25,
      });
      for (final step in first['steps'] as List) {
        (step as Json)['completedAt'] = '2026-09-24T09:00:00Z';
      }
      first['completedAt'] = '2026-09-24T09:00:00Z';
      second.addAll({
        'id': 'second-menu',
        'title': '추가 메뉴',
        'orderId': 'order-17',
        'orderNumber': 'A-17',
        'orderCreatedAt': '2026-09-24T09:00:00Z',
        'orderTargetMinutes': 25,
      });
      (data['tasks'] as List).add(second);
      data['dashboard'] = {
        'queue': [
          {
            'id': 'order-17',
            'status': '접수',
            'elapsedMinutes': 8,
            'targetMinutes': 25,
          },
        ],
        'reports': [],
      };
      var writes = 0;
      final ops = OperationsController(
        readOnly: true,
        client: MockClient((r) async {
          if (r.method == 'POST') writes++;
          return response(data);
        }),
      );
      addTearDown(ops.dispose);
      await mountBoard(tester, ops, width: 390);
      expect(find.textContaining('주문 A-17 ·'), findsOneWidget);
      expect(
        find.textContaining('9/24 18:00 접수 · 경과 8분 · 목표 25분(가상) · 17분 남음'),
        findsOneWidget,
      );
      expect(find.text('주문처리중'), findsOneWidget);
      expect(find.text('할일'), findsOneWidget);
      expect(find.text('완료'), findsWidgets);
      expect(find.text('2/4'), findsOneWidget);
      expect(find.textContaining('🩵 배달의민족'), findsOneWidget);
      final orderLane = tester.widget<DragTarget<String>>(
        find.byKey(const ValueKey('lane-주문처리중')),
      );
      final prepLane = tester.widget<DragTarget<String>>(
        find.byKey(const ValueKey('lane-할일')),
      );
      expect(
        orderLane.onWillAcceptWithDetails!(
          DragTargetDetails(data: 'daily-broth', offset: Offset.zero),
        ),
        isFalse,
      );
      expect(
        prepLane.onWillAcceptWithDetails!(
          DragTargetDetails(data: 'daily-prep', offset: Offset.zero),
        ),
        isFalse,
      );
      expect(find.text('2/4'), findsOneWidget);
      expect(find.byKey(const ValueKey('tap-daily-prep')), findsOneWidget);
      expect(find.byKey(const ValueKey('tap-second-menu')), findsOneWidget);
      await tester.tap(find.byTooltip('요청사항 보기'));
      await tester.pumpAndSettle();
      expect(find.text('수저 제외'), findsOneWidget);
      await tester.tap(find.text('확인'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byTooltip('주문 그룹 이동'));
      await tester.tap(find.byTooltip('주문 그룹 이동'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('전체 완료'));
      await tester.pumpAndSettle();
      expect(
        ops
            .rows('tasks')
            .where((t) => t['orderId'] == 'order-17')
            .every((t) => t['completedAt'] != null),
        true,
      );
      expect(writes, 0);
      expect(tester.takeException(), isNull);
    },
  );

  for (final width in [320.0, 390.0, 1200.0]) {
    testWidgets('root shows Taps immediately and opens manual at $width', (
      tester,
    ) async {
      final ops = OperationsController(
        readOnly: true,
        client: MockClient((_) async => response(fixture())),
      );
      addTearDown(ops.dispose);
      await mountBoard(tester, ops, width: width);
      expect(find.text('할일'), findsOneWidget);
      expect(find.text('5분 계획'), findsNothing);
      expect(
        tester
            .widget<TapCard>(find.byKey(const ValueKey('tap-daily-prep')))
            .level,
        'TAP',
      );
      expect(find.text('Small TAP'), findsWidgets);
      await openCard(tester, 'tap-daily-prep');
      expect(find.text('TAP 목록으로'), findsOneWidget);
      expect(find.text('Small TAP 2개 보기'), findsNothing);
      expect(
        tester.widget<TapCard>(find.byKey(const ValueKey('small-s1'))).level,
        'SMALL TAP',
      );
      expect(
        tester.widget<TapCard>(find.byKey(const ValueKey('small-s1'))).sequence,
        1,
      );
      expect(
        tester.widget<TapCard>(find.byKey(const ValueKey('small-s1'))).selected,
        isTrue,
      );
      expect(find.text('방법 보기'), findsNWidgets(2));
      if (width < 700) {
        expect(find.text('생재료와 완성식품 도구를 따로 놓아요.'), findsNothing);
      }
      await openCard(tester, 'small-s1');
      expect(find.text('생재료와 완성식품 도구를 따로 놓아요.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('opening a TAP preserves its board grouping', (tester) async {
    final ops = OperationsController(
      readOnly: true,
      client: MockClient((_) async => response(fixture())),
    );
    addTearDown(ops.dispose);
    await mountBoard(tester, ops);
    await openGroup(tester, '기본 업무  ·  2');
    await openCard(tester, 'tap-daily-prep');
    expect(find.text('BIG TAP · 업무 그룹 필터'), findsNothing);
    expect(find.byKey(const ValueKey('small-s1')), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, 'TAP 목록으로'));
    await tester.pumpAndSettle();
    expect(find.text('TAP'), findsWidgets);
    expect(find.text('BIG TAP · 업무 그룹 필터'), findsOneWidget);
    expect(find.byKey(const ValueKey('tap-daily-prep')), findsOneWidget);
    await openGroup(tester, '전체 TAP');
    await openCard(tester, 'tap-daily-prep');
    await tester.tap(find.widgetWithText(TextButton, 'TAP 목록으로'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, '전체 TAP'))
          .selected,
      isTrue,
    );
  });

  testWidgets(
    'preview completion rolls up through parents and undo sends no POST',
    (tester) async {
      var writes = 0;
      final ops = OperationsController(
        readOnly: true,
        client: MockClient((request) async {
          if (request.method == 'POST') writes++;
          return response(fixture());
        }),
      );
      addTearDown(ops.dispose);
      await mountBoard(tester, ops);
      await openGroup(tester, '기본 업무  ·  2');
      await openCard(tester, 'tap-daily-prep');
      await tester.tap(
        find.descendant(
          of: find.byKey(const ValueKey('small-s1')),
          matching: find.byType(IconButton),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester.widget<TapCard>(find.byKey(const ValueKey('small-s1'))).checked,
        isTrue,
      );
      await tester.tap(find.widgetWithText(TextButton, 'TAP 목록으로'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TapCard>(find.byKey(const ValueKey('tap-daily-prep')))
            .done,
        1,
      );
      await openGroup(tester, '전체 TAP');
      await tester.pumpAndSettle();
      expect(find.textContaining('기본 업무'), findsWidgets);
      await openGroup(tester, '기본 업무  ·  2');
      await openCard(tester, 'tap-daily-prep');
      await tester.tap(
        find.descendant(
          of: find.byKey(const ValueKey('small-s1')),
          matching: find.byType(IconButton),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, '되돌리기'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<TapCard>(find.byKey(const ValueKey('small-s1'))).checked,
        isFalse,
      );
      expect(writes, 0);
    },
  );

  testWidgets(
    'role restrictions remain visible and empty folder can be opened',
    (tester) async {
      final ops = OperationsController(
        readOnly: true,
        client: MockClient((_) async => response(fixture(actor: 'crew'))),
      );
      addTearDown(ops.dispose);
      await mountBoard(tester, ops);
      await openGroup(tester, '마감 폴더  ·  0');
      expect(find.text('아직 카드가 없어요'), findsNWidgets(3));
      await openGroup(tester, '전체 TAP');
      await tester.pumpAndSettle();
      await openGroup(tester, '기본 업무  ·  2');
      await openCard(tester, 'tap-daily-broth');
      tester.widget<TapCard>(find.byKey(const ValueKey('small-b1'))).onCheck!();
      await tester.pumpAndSettle();
      expect(
        ops
            .rows('tasks')
            .firstWhere(
              (task) => task['id'] == 'daily-broth',
            )['steps'][0]['completedAt'],
        isNull,
      );
      expect(find.textContaining('담당 Tap이에요'), findsOneWidget);
    },
  );

  testWidgets('live completion uses the original task and step IDs', (
    tester,
  ) async {
    final state = fixture();
    Json? sent;
    final ops = OperationsController(
      client: MockClient((request) async {
        if (request.method == 'POST') {
          sent = jsonDecode(request.body) as Json;
          state['tasks'][0]['steps'][0]['completedAt'] = '2026-09-23T13:00:00Z';
        }
        return response(state);
      }),
    );
    addTearDown(ops.dispose);
    await mountBoard(tester, ops);
    await openGroup(tester, '기본 업무  ·  2');
    await openCard(tester, 'tap-daily-prep');
    await tester.tap(
      find.descendant(
        of: find.byKey(const ValueKey('small-s1')),
        matching: find.byType(IconButton),
      ),
    );
    await tester.pumpAndSettle();
    expect(sent?['action'], 'complete_step');
    expect(sent?['taskId'], 'daily-prep');
    expect(sent?['stepId'], 's1');
    expect(sent?['revision'], state['revision']);
    expect(
      tester.widget<TapCard>(find.byKey(const ValueKey('small-s1'))).checked,
      isTrue,
    );
  });
}
