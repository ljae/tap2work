import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:tap2work/data/http_operations_repository.dart';
import 'package:tap2work/domain/operations_repository.dart';
import 'package:tap2work/state/operations_controller.dart';

class MemoryOperations implements OperationsRepository {
  Json? saved;
  bool closed = false;
  @override
  Future<OperationsResult> read({
    required String actorId,
    String? demoToken,
    String? scheduleFrom,
    String? scheduleTo,
    String? workspaceId,
    bool useCache = true,
  }) async => const OperationsResult(200, {'revision': 8, 'tasks': <Json>[]});
  @override
  Future<OperationsResult> write({
    required String actorId,
    String? demoToken,
    required Json values,
  }) async {
    saved = values;
    return const OperationsResult(200, {'revision': 9, 'tasks': <Json>[]});
  }

  @override
  void close() => closed = true;
}

void main() {
  test(
    'HTTP authentication errors stay distinct from transport failures and recover',
    () async {
      var status = 401;
      var message = '로그인이 만료됐어요. 다시 로그인해 주세요.';
      var disconnected = false;
      final controller = OperationsController(
        client: MockClient((_) async {
          if (disconnected) throw http.ClientException('DNS lookup failed');
          return http.Response(
            jsonEncode(
              status == 200
                  ? {'revision': 10, 'tasks': <Json>[]}
                  : {'error': message},
            ),
            status,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }),
      );
      addTearDown(controller.dispose);
      await controller.refresh();
      expect(controller.error, message);
      status = 403;
      message = 'Apple 또는 Google로 다시 로그인해 주세요.';
      await controller.refresh();
      expect(controller.error, message);
      disconnected = true;
      await controller.refresh();
      expect(controller.error, '매장 서버에 연결하지 못했어요. 연결을 확인하고 다시 시도해 주세요.');
      disconnected = false;
      status = 200;
      await controller.refresh();
      expect(controller.error, isNull);
      expect(controller.data!['revision'], 10);
    },
  );

  test(
    'controller works with a repository without HTTP and preserves draft revision',
    () async {
      final repository = MemoryOperations();
      final controller = OperationsController(repository: repository);
      await controller.refresh();
      expect(controller.data!['revision'], 8);
      expect(
        await controller.act('save_step_manual', {
          'revision': 5,
          'manual': '방법',
        }),
        isTrue,
      );
      expect(repository.saved!['revision'], 5);
      expect(repository.saved!['action'], 'save_step_manual');
      expect(controller.data!['revision'], 9);
      controller.dispose();
      expect(repository.closed, isTrue);
    },
  );

  test(
    'public repository rejects writes even when called outside controller',
    () async {
      var requests = 0;
      final repository = HttpOperationsRepository(
        endpoint: Uri.parse('https://example.com/api/operations'),
        readOnly: true,
        client: MockClient((_) async {
          requests++;
          throw StateError('Network must not be called');
        }),
      );
      addTearDown(repository.close);
      await expectLater(
        repository.write(actorId: 'owner', values: {'action': 'order'}),
        throwsStateError,
      );
      expect(requests, 0);
    },
  );
}
