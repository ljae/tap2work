import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:tap2work/state/operations_controller.dart';
import 'operations_test.dart' show sample, response;
import 'dashboard_test.dart' show dashboard;

void main() {
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
    'preview order completion and reopening update shared Home data without writes',
    () async {
      final d = dashboard();
      final ticket = (d['queue'] as List).first as Json;
      var writes = 0;
      final ops = OperationsController(
        readOnly: true,
        client: MockClient((r) async {
          if (r.method == 'POST') writes++;
          return response({
            ...sample(),
            'dashboard': d,
            'tasks': [
              {
                'id': 'order-tap',
                'kind': 'routine',
                'orderId': ticket['id'],
                'folderId': 'orders',
                'boardStatus': 'processing',
                'steps': [
                  {'id': 's1'},
                ],
              },
            ],
          });
        }),
      );
      addTearDown(ops.dispose);
      await ops.refresh();
      final before = (ops.data!['dashboard']['queue'] as List).length;
      ops.previewMoveTap('order-tap', 'orders', 'done');
      expect((ops.data!['dashboard']['queue'] as List).length, before - 1);
      expect(ops.rows('tasks').single['steps'][0]['completedAt'], isNotNull);
      ops.previewMoveTap('order-tap', 'orders', 'processing');
      expect((ops.data!['dashboard']['queue'] as List).length, before);
      expect(ops.rows('tasks').single['steps'][0]['completedAt'], isNull);
      expect(writes, 0);
    },
  );
  test(
    'preview menu completion keeps siblings open and group moves update every menu without POST',
    () async {
      final d = dashboard();
      final ticket = (d['queue'] as List).first as Json;
      var writes = 0;
      final ops = OperationsController(
        readOnly: true,
        client: MockClient((r) async {
          if (r.method == 'POST') writes++;
          return response({
            ...sample(),
            'dashboard': d,
            'tasks': [
              for (var i = 0; i < 2; i++)
                {
                  'id': 'menu-$i',
                  'kind': 'routine',
                  'orderId': ticket['id'],
                  'folderId': 'orders',
                  'boardStatus': 'todo',
                  'steps': [
                    {'id': 'step', 'title': '조리', 'manual': '확인'},
                  ],
                },
            ],
          });
        }),
      );
      addTearDown(ops.dispose);
      await ops.refresh();
      ops.previewToggleStep('menu-0', 'step');
      expect(
        (ops.data!['dashboard']['queue'] as List).any(
          (t) => t['id'] == ticket['id'],
        ),
        true,
      );
      expect(ops.rows('tasks')[1]['completedAt'], isNull);
      ops.previewMoveTap('menu-1', 'orders', 'done');
      expect(ops.rows('tasks').every((t) => t['completedAt'] != null), true);
      expect(
        (ops.data!['dashboard']['queue'] as List).any(
          (t) => t['id'] == ticket['id'],
        ),
        false,
      );
      ops.previewMoveTap('menu-0', 'orders', 'processing');
      expect(ops.rows('tasks').every((t) => t['completedAt'] == null), true);
      expect(writes, 0);
    },
  );
}
