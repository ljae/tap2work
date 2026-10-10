import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tap2work/data/http_operations_repository.dart';
import 'package:tap2work/domain/manual_media_repository.dart';
import 'package:tap2work/domain/checklist_draft.dart';
import 'package:tap2work/state/operations_controller.dart';

const workspace = '11111111-1111-4111-8111-111111111111';
const otherWorkspace = '22222222-2222-4222-8222-222222222222';
const reference =
    'tap2work-media:$workspace/33333333-3333-4333-8333-333333333333.jpg';
final jpeg = Uint8List.fromList([0xff, 0xd8, 0xff, 0xd9]);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'photo upload and read authenticate and never replace operations cache',
    () async {
      final requests = <http.Request>[];
      final repository = HttpOperationsRepository(
        endpoint: Uri.parse('https://example.test/functions/v1/operations'),
        readOnly: false,
        accessToken: () async => 'test-session',
        client: MockClient((request) async {
          requests.add(request);
          if (request.method == 'POST') {
            expect(jsonDecode(request.body), {
              'workspaceId': workspace,
              'photo': 'data:image/jpeg;base64,${base64Encode(jpeg)}',
            });
            return http.Response(jsonEncode({'reference': reference}), 201);
          }
          return http.Response.bytes(
            jpeg,
            200,
            headers: {'content-type': 'image/jpeg'},
          );
        }),
      );
      addTearDown(repository.close);
      expect(
        await repository.uploadManualPhoto(
          actorId: 'owner',
          workspaceId: workspace,
          bytes: jpeg,
        ),
        reference,
      );
      expect(
        await repository.loadManualPhoto(
          actorId: 'crew',
          workspaceId: workspace,
          reference: reference,
        ),
        jpeg,
      );
      expect(
        requests.map((r) => r.headers['Authorization']),
        everyElement('Bearer test-session'),
      );
      expect(
        requests.map((r) => r.headers.containsKey('x-demo-actor')),
        everyElement(false),
      );
      expect(requests.first.url.queryParameters['media'], 'upload');
      expect(requests.last.url.queryParameters['workspace'], workspace);
    },
  );

  test(
    'private references are photo-only; cross-workspace reads never request',
    () async {
      var count = 0;
      final repository = HttpOperationsRepository(
        endpoint: Uri.parse('https://example.test/operations'),
        readOnly: false,
        accessToken: () async => 'session',
        client: MockClient((_) async {
          count++;
          return http.Response('', 500);
        }),
      );
      addTearDown(repository.close);
      await expectLater(
        repository.loadManualPhoto(
          actorId: 'owner',
          workspaceId: otherWorkspace,
          reference: reference,
        ),
        throwsA(isA<ManualMediaException>()),
      );
      expect(count, 0);
      final step = {
        'title': '정리',
        'manual': '지정 위치에 놓아요.',
        'tip': '',
        'imageUrl': reference,
      };
      expect(checklistStepIssue(step), isNull);
      expect(checklistStepIssue({...step, 'videoUrl': reference}), isNotNull);
      expect(
        checklistStepIssue({...step, 'imageUrl': '$reference/../../secret'}),
        isNotNull,
      );
    },
  );

  test('read-only and demo uploads are denied before network', () async {
    for (final readOnly in [true, false]) {
      var count = 0;
      final repository = HttpOperationsRepository(
        endpoint: Uri.parse('https://example.test/operations'),
        readOnly: readOnly,
        client: MockClient((_) async {
          count++;
          return http.Response('', 500);
        }),
      );
      await expectLater(
        repository.uploadManualPhoto(
          actorId: 'owner',
          workspaceId: workspace,
          bytes: jpeg,
        ),
        throwsA(isA<ManualMediaException>()),
      );
      expect(count, 0);
      repository.close();
    }
  });

  test(
    'upload failure preserves server error and rejects foreign response',
    () async {
      for (final status in [403, 200]) {
        final repository = HttpOperationsRepository(
          endpoint: Uri.parse('https://example.test/operations'),
          readOnly: false,
          accessToken: () async => 'session',
          client: MockClient(
            (_) async => http.Response(
              jsonEncode(
                status == 403
                    ? {'error': '매장 권한이 없어요.'}
                    : {
                        'reference': reference.replaceFirst(
                          workspace,
                          otherWorkspace,
                        ),
                      },
              ),
              status,
              headers: {'content-type': 'application/json; charset=utf-8'},
            ),
          ),
        );
        await expectLater(
          repository.uploadManualPhoto(
            actorId: 'owner',
            workspaceId: workspace,
            bytes: jpeg,
          ),
          throwsA(isA<ManualMediaException>()),
        );
        repository.close();
      }
    },
  );

  test(
    'workspace changes during upload discard result without snapshot mutation',
    () async {
      final pending = Completer<http.Response>();
      final ops = OperationsController(
        readOnly: false,
        accessToken: () async => 'session',
        client: MockClient((_) => pending.future),
      );
      addTearDown(ops.dispose);
      ops.data = {
        'revision': 9,
        'workspaceId': workspace,
        'actor': {'role': 'owner'},
      };
      final upload = ops.uploadManualPhoto(jpeg);
      ops.data = {
        'revision': 12,
        'workspaceId': otherWorkspace,
        'actor': {'role': 'owner'},
      };
      pending.complete(
        http.Response(jsonEncode({'reference': reference}), 201),
      );
      await expectLater(upload, throwsA(isA<ManualMediaException>()));
      expect(ops.data!['revision'], 12);
      expect(ops.data!['workspaceId'], otherWorkspace);
    },
  );
}
