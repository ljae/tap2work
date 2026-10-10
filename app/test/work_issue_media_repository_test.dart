import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tap2work/data/http_operations_repository.dart';
import 'package:tap2work/domain/manual_media_repository.dart';
import 'package:tap2work/state/operations_controller.dart';

const workspace = '11111111-1111-4111-8111-111111111111';
const reference =
    'tap2work-media:$workspace/33333333-3333-4333-8333-333333333333.jpg';
final jpeg = Uint8List.fromList([0xff, 0xd8, 0xff, 0xd9]);
http.Response response(Map<String, dynamic> value) =>
    http.Response(jsonEncode(value), 201);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'issue upload binds task and authenticated session and requires receipt',
    () async {
      for (final valid in [true, false]) {
        final repository = HttpOperationsRepository(
          endpoint: Uri.parse('https://example.test/operations'),
          readOnly: false,
          accessToken: () async => 'session',
          client: MockClient((request) async {
            expect(request.headers['Authorization'], 'Bearer session');
            expect(request.headers.containsKey('x-demo-actor'), false);
            expect(jsonDecode(request.body), {
              'workspaceId': workspace,
              'purpose': 'work_issue',
              'taskId': 'assigned-task',
              'photo': 'data:image/jpeg;base64,${base64Encode(jpeg)}',
            });
            return response({
              'reference': reference,
              if (valid) 'receipt': 'signed-receipt',
            });
          }),
        );
        final upload = repository.uploadWorkIssuePhoto(
          actorId: 'crew',
          workspaceId: workspace,
          taskId: 'assigned-task',
          bytes: jpeg,
        );
        if (valid) {
          expect(await upload, {
            'reference': reference,
            'receipt': 'signed-receipt',
          });
        } else {
          await expectLater(upload, throwsA(isA<ManualMediaException>()));
        }
        repository.close();
      }
    },
  );
  test(
    'late issue photo cannot attach after actor or workspace changes',
    () async {
      final pending = Completer<http.Response>();
      final ops = OperationsController(
        accessToken: () async => 'session',
        client: MockClient((_) => pending.future),
      );
      addTearDown(ops.dispose);
      ops.workspaceId = workspace;
      ops.data = {
        'workspaceId': workspace,
        'actor': {'role': 'crew'},
      };
      final upload = ops.uploadWorkIssuePhoto(jpeg, 'assigned-task');
      ops.workspaceId = 'another-store';
      pending.complete(
        response({'reference': reference, 'receipt': 'signed-receipt'}),
      );
      await expectLater(upload, throwsA(isA<ManualMediaException>()));
    },
  );
}
