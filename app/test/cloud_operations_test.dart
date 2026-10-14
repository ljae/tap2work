import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:tap2work/state/operations_controller.dart';
import 'operations_test.dart' show sample, response;

void main() {
  test(
    'retired order preview does not debit stock; preparation still credits actual output',
    () async {
      final source = sample();
      source['preparedItems'] = [
        {
          'id': 'portion',
          'name': '준비분',
          'unit': '인분',
          'onHand': 2,
          'minimum': 3,
          'target': 10,
          'batchQuantity': 8,
          'generation': 1,
          'folderId': 'orders',
          'zone': 'prep',
          'menuUses': [
            {'menuId': 'bowl', 'quantity': 2},
          ],
        },
      ];
      source['tasks'] = [
        {
          'id': 'menu',
          'kind': 'routine',
          'orderId': 'ticket',
          'orderLineIndex': 0,
          'menuId': 'bowl',
          'menuQuantity': 2,
          'folderId': 'orders',
          'boardStatus': 'todo',
          'steps': [
            {'id': 'check', 'title': '주문 확인', 'manual': '확인'},
          ],
        },
        {
          'id': 'prep',
          'kind': 'routine',
          'preparedItemId': 'portion',
          'folderId': 'orders',
          'boardStatus': 'todo',
          'steps': [
            {'id': 'finish', 'title': '준비', 'manual': '준비'},
          ],
        },
      ];
      var writes = 0;
      final ops = OperationsController(
        readOnly: true,
        client: MockClient((request) async {
          if (request.method == 'POST') writes++;
          return response(source);
        }),
      );
      addTearDown(ops.dispose);
      await ops.refresh();
      ops.previewToggleStep('menu', 'check');
      expect(ops.rows('preparedItems').single['onHand'], 2);
      ops.previewMoveTap('menu', 'orders', 'done');
      expect(ops.rows('preparedItems').single['onHand'], 2);
      ops.previewCompletePreparation('prep', 6);
      expect(ops.rows('preparedItems').single['onHand'], 8);
      expect(
        ops
            .rows('tasks')
            .firstWhere(
              (task) => task['id'] == 'prep',
            )['preparedActualQuantity'],
        6,
      );
      expect(writes, 0);
    },
  );
  test(
    'preview preparation uses batch minimum when target gap is smaller',
    () async {
      final source = sample();
      source['preparedItems'] = [
        {
          'id': 'portion',
          'name': '준비분',
          'unit': '인분',
          'onHand': 2,
          'minimum': 3,
          'target': 10,
          'batchQuantity': 12,
          'generation': 1,
          'folderId': 'orders',
          'zone': 'prep',
          'menuUses': [],
        },
      ];
      source['tasks'] = [
        {
          'id': 'prep',
          'kind': 'routine',
          'preparedItemId': 'portion',
          'folderId': 'orders',
          'boardStatus': 'todo',
          'completedAt': null,
          'steps': <Json>[],
        },
      ];
      final ops = OperationsController(
        readOnly: true,
        client: MockClient((_) async => response(source)),
      );
      addTearDown(ops.dispose);
      await ops.refresh();
      ops.previewCompletePreparation('prep', 1);
      final next = ops
          .rows('tasks')
          .firstWhere((task) => task['id'] == 'preview-prepare-portion-2');
      expect(next['plannedQuantity'], 12);
      expect(next['title'], '준비분 12인분 준비');
    },
  );
  test(
    'cloud uses refreshed session bearer and ignores demo actor switching',
    () async {
      final requests = <dynamic>[];
      final ops = OperationsController(
        endpoint: Uri.parse(
          'https://example.supabase.co/functions/v1/operations',
        ),
        accessToken: () async => 'verified-session',
        client: MockClient((r) async {
          requests.add(r);
          return response({
            ...sample(),
            'actor': {'id': 'user-id', 'role': 'owner', 'name': 'Owner'},
          });
        }),
      );
      addTearDown(ops.dispose);
      await ops.refresh();
      expect(
        requests.single.headers['authorization'],
        'Bearer verified-session',
      );
      expect(requests.single.headers.containsKey('x-demo-actor'), false);
      await ops.selectActor('manager');
      expect(requests.length, 1);
      expect(ops.actorId, 'user-id');
    },
  );
  test(
    'legacy customer tasks cannot be completed through preview helpers',
    () async {
      final source = sample();
      source['tasks'] = [
        {
          'id': 'legacy',
          'orderId': 'old-ticket',
          'kind': 'routine',
          'folderId': 'orders',
          'boardStatus': 'todo',
          'steps': [
            {'id': 'one', 'title': '과거 주문', 'manual': '과거'},
          ],
        },
      ];
      final ops = OperationsController(
        readOnly: true,
        client: MockClient((_) async => response(source)),
      );
      addTearDown(ops.dispose);
      await ops.refresh();
      ops.previewMoveTap('legacy', 'orders', 'done');
      ops.previewToggleStep('legacy', 'one');
      expect(ops.rows('tasks').single['completedAt'], isNull);
      expect(
        (ops.rows('tasks').single['steps'] as List).single['completedAt'],
        isNull,
      );
    },
  );
}
