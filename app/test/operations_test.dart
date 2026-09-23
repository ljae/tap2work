import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tap2work/main.dart';
import 'package:tap2work/state/operations_controller.dart';
import 'package:tap2work/state/work_controller.dart';
import 'work_controller_test.dart' show MemoryStore;

Json sample([String actor = 'owner']) => {
  'revision': 2,
  'day': '2026-09-19',
  'demoToken': 'test-token',
  'actor': {
    'id': actor,
    'name': actor == 'owner' ? '서연' : '지우',
    'role': actor,
    'label': actor == 'owner' ? '사장님' : '크루',
    'emoji': '🌻',
  },
  if (actor == 'owner')
    'privateSummary': {'laborEstimate': 326000, 'note': '비공개 메모'},
  'items': [
    {
      'id': 'rice',
      'name': '쌀',
      'emoji': '🍚',
      'unit': '포',
      'quantity': 1,
      'minimum': 2,
      'orderQuantity': 3,
      if (actor == 'owner') 'price': 58000,
      'supplier': '우리식자재',
      'zone': 'storage',
      'reviewDays': 7,
      'lastOrderedAt': '2026-09-16T05:00:00Z',
      'lastCheckedAt': null,
    },
  ],
  'tasks': [
    {
      'id': 'stock-rice',
      'itemId': 'rice',
      'title': '쌀 재고 확인',
      'emoji': '🍚',
      'slot': '준비',
      'requiredRole': 'all',
      'zone': 'storage',
      'kind': 'stock',
      'completedAt': null,
      'canComplete': true,
    },
  ],
  'shifts': [
    {
      'id': 's4',
      'person': '가은',
      'role': '크루',
      'time': '18:00–22:00',
      'status': '휴가',
      'covering': null,
    },
  ],
  'coverRequests': [],
  'orders': [],
  'activity': [],
  'zones': [
    for (final (index, id) in [
      'storage',
      'fridge',
      'prep',
      'stove',
      'sink',
      'pass',
      'entrance',
      'exit',
    ].indexed)
      {
        'id': id,
        'name': {
          'storage': '창고',
          'fridge': '냉장고',
          'prep': '전처리대',
          'stove': '조리 구역',
          'sink': '세척대',
          'pass': '배식대',
          'entrance': '입구',
          'exit': '비상구',
        }[id],
        'emoji': '📦',
        'description': '현장에서 확인해요',
        'x': index.isEven ? .04 : .55,
        'y': .04 + (index ~/ 2) * .24,
      },
  ],
};
http.Response response(Json value, [int code = 200]) => http.Response(
  jsonEncode(value),
  code,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

void main() {
  test('public review loads role samples and never submits mutations', () async {
    final requests = <http.Request>[];
    final ops = OperationsController(
      readOnly: true,
      client: MockClient((request) async {
        requests.add(request);
        return response(sample(request.url.path.endsWith('crew.json') ? 'crew' : 'owner'));
      }),
    );
    addTearDown(ops.dispose);
    await ops.start();
    expect(requests.single.url.path, endsWith('review-data/owner.json'));
    await ops.selectActor('crew');
    expect(requests.last.url.path, endsWith('review-data/crew.json'));
    expect(ops.isOwner, false);
    expect(await ops.act('place_order', {'lines': []}), false);
    expect(requests.every((request) => request.method == 'GET'), true);
    expect(requests, hasLength(2));
    expect(ops.error, contains('공개 미리보기'));
  });

  testWidgets('public review shows its boundary and disables order submission', (tester) async {
    final ops = OperationsController(
      readOnly: true,
      client: MockClient((request) async => response(sample())),
    );
    addTearDown(ops.dispose);
    await ops.refresh();
    await tester.pumpWidget(Tap2workApp(controller: WorkController(MemoryStore()), operations: ops));
    expect(find.textContaining('공개 미리보기 · 샘플 데이터'), findsOneWidget);
    await tester.tap(find.descendant(of: find.byType(NavigationBar), matching: find.text('재고/발주')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('부족한 재료 담기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('발주함 보기 (1)'));
    await tester.pumpAndSettle();
    final submit = tester.widget<FilledButton>(find.widgetWithText(FilledButton, '미리보기 · 저장 불가'));
    expect(submit.onPressed, isNull);
    expect(tester.takeException(), isNull);
  });
  test(
    'role switching fetches a new projection, and actions carry revision and token',
    () async {
      final requests = <http.Request>[];
      final ops = OperationsController(
        client: MockClient((request) async {
          requests.add(request);
          return response(sample(request.headers['x-demo-actor']!));
        }),
      );
      addTearDown(ops.dispose);
      await ops.refresh();
      expect(ops.isOwner, true);
      await ops.selectActor('crew');
      expect(ops.data!.containsKey('privateSummary'), false);
      expect(
        await ops.act('check_stock', {'itemId': 'rice', 'quantity': 3}),
        true,
      );
      final post = requests.last;
      expect(post.headers['x-demo-token'], 'test-token');
      expect(jsonDecode(post.body)['revision'], 2);
      expect(post.headers['x-demo-actor'], 'crew');
    },
  );

  test(
    'conflict refreshes current shared state and never pretends success',
    () async {
      var reads = 0;
      final ops = OperationsController(
        client: MockClient((request) async {
          if (request.method == 'POST') {
            return response({'error': '다른 동료가 먼저 확인했어요'}, 409);
          }
          reads++;
          return response({...sample(), 'revision': reads + 1});
        }),
      );
      addTearDown(ops.dispose);
      await ops.refresh();
      expect(
        await ops.act('check_stock', {'itemId': 'rice', 'quantity': 4}),
        false,
      );
      expect(ops.data!['revision'], 3);
      expect(ops.error, '다른 동료가 먼저 확인했어요');
    },
  );

  test(
    'an open form retains its revision even if background refresh sees a newer edit',
    () async {
      Json? submitted;
      final ops = OperationsController(
        client: MockClient((request) async {
          if (request.method == 'POST') {
            submitted = jsonDecode(request.body) as Json;
            return response({'error': '최신 내용을 확인해 주세요'}, 409);
          }
          return response({...sample(), 'revision': 5});
        }),
      );
      addTearDown(ops.dispose);
      await ops.refresh();
      expect(
        await ops.act('check_stock', {
          'itemId': 'rice',
          'quantity': 3,
          'revision': 2,
        }),
        false,
      );
      expect(submitted!['revision'], 2);
      expect(ops.data!['revision'], 5);
    },
  );

  test(
    'network failure preserves last confirmed state without optimistic completion',
    () async {
      final ops = OperationsController(
        client: MockClient((request) async {
          if (request.method == 'POST') throw http.ClientException('offline');
          return response(sample());
        }),
      );
      addTearDown(ops.dispose);
      await ops.refresh();
      expect(
        await ops.act('check_stock', {'itemId': 'rice', 'quantity': 4}),
        false,
      );
      expect(ops.rows('items').first['quantity'], 1);
      expect(ops.busy, false);
      expect(ops.error, contains('저장 결과'));
    },
  );

  for (final width in [320.0, 390.0, 430.0]) {
    testWidgets('five operations tabs and order dialog fit a $width phone', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final ops = OperationsController(
        client: MockClient((request) async => response(sample())),
      );
      await ops.refresh();
      addTearDown(ops.dispose);
      await tester.pumpWidget(
        Tap2workApp(controller: WorkController(MemoryStore()), operations: ops),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      for (final label in ['할 일', '우리 팀', '매장 지도', '재고/발주']) {
        await tester.tap(
          find.descendant(
            of: find.byType(NavigationBar),
            matching: find.text(label),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: '$width / $label');
      }
      await tester.tap(find.text('부족한 재료 담기'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('발주함 보기 (1)'));
      await tester.pumpAndSettle();
      expect(find.text('한 번에 데모 발주'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('닫기'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('stock count confirmation submits the typed quantity', (
    tester,
  ) async {
    Json? submitted;
    final ops = OperationsController(
      client: MockClient((request) async {
        if (request.method == 'POST') {
          submitted = jsonDecode(request.body) as Json;
        }
        return response(sample());
      }),
    );
    await ops.refresh();
    addTearDown(ops.dispose);
    await tester.pumpWidget(
      Tap2workApp(controller: WorkController(MemoryStore()), operations: ops),
    );
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('할 일'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('재고 수량 확인하기'));
    await tester.tap(find.text('재고 수량 확인하기'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.descendant(of: find.byType(AlertDialog), matching: find.byType(TextField)),
      '3.5',
    );
    await tester.tap(find.text('확인하고 저장'));
    await tester.pumpAndSettle();
    expect(submitted!['quantity'], 3.5);
    expect(submitted!['taskId'], 'stock-rice');
    expect(tester.takeException(), isNull);
  });
}
