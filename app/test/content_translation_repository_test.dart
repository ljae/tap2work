import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tap2work/data/http_operations_repository.dart';

void main() {
  test(
    'translation sends source IDs with authentication, never raw text',
    () async {
      final repo = HttpOperationsRepository(
        endpoint: Uri.parse('https://example.invalid/operations'),
        readOnly: false,
        accessToken: () async => 'test-token',
        client: MockClient((request) async {
          expect(request.url.queryParameters, {'translate': 'content'});
          expect(request.headers['Authorization'], 'Bearer test-token');
          expect(jsonDecode(request.body), {
            'workspaceId': 'store-a',
            'targetLocale': 'ne',
            'source': {'kind': 'task', 'id': 'task-a'},
          });
          return http.Response(
            jsonEncode({
              'status': 'translated',
              'original': {'title': '준비'},
              'translated': {'title': 'Preparation'},
            }),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }),
      );
      final result = await repo.translateContent(
        actorId: 'owner',
        workspaceId: 'store-a',
        targetLocale: 'ne',
        kind: 'task',
        id: 'task-a',
      );
      expect(result['status'], 'translated');
      repo.close();
    },
  );
  test('public preview never sends content to translation provider', () async {
    var calls = 0;
    final repo = HttpOperationsRepository(
      endpoint: Uri.parse('https://example.invalid'),
      readOnly: true,
      client: MockClient((_) async {
        calls++;
        return http.Response('{}', 200);
      }),
    );
    expect(
      (await repo.translateContent(
        actorId: 'owner',
        workspaceId: 'store-a',
        targetLocale: 'th',
        kind: 'welcome',
      ))['status'],
      'unavailable',
    );
    expect(calls, 0);
    repo.close();
  });
  test('failed translation is not accepted as translated output', () async {
    final repo = HttpOperationsRepository(
      endpoint: Uri.parse('https://example.invalid'),
      readOnly: false,
      accessToken: () async => 'test',
      client: MockClient(
        (_) async => http.Response('{"error":"unavailable"}', 503),
      ),
    );
    await expectLater(
      repo.translateContent(
        actorId: 'owner',
        workspaceId: 'store-a',
        targetLocale: 'th',
        kind: 'welcome',
      ),
      throwsStateError,
    );
    repo.close();
  });
}
