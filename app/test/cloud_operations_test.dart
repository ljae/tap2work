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
}
