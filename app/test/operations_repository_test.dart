import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
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
