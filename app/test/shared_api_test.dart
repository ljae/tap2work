import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:tap2work/domain/shared_api.dart';
import 'package:tap2work/state/operations_controller.dart';
import 'operations_test.dart' show sample, response;

void main() {
  test(
    'shared api resolves from the link, then memory, and can be switched off',
    () {
      final page = Uri.parse('http://tap2.work/app/');
      expect(resolveSharedApi(base: page), isNull);
      expect(
        resolveSharedApi(
          base: page.replace(
            queryParameters: {'api': 'https://demo.trycloudflare.com/'},
          ),
        ),
        'https://demo.trycloudflare.com',
      );
      expect(
        resolveSharedApi(base: page, stored: 'https://demo.trycloudflare.com'),
        'https://demo.trycloudflare.com',
      );
      expect(
        resolveSharedApi(
          base: page.replace(queryParameters: {'api': 'off'}),
          stored: 'https://demo.trycloudflare.com',
        ),
        isNull,
      );
      expect(
        sharedApiCleared(page.replace(queryParameters: {'api': 'off'})),
        isTrue,
      );
      expect(sharedApiCleared(page), isFalse);
      for (final bad in [
        'http://demo.trycloudflare.com',
        'ftp://x.example',
        'https://user:pw@x.example',
        'https://x.example/?q=1',
        'https://x.example/#frag',
        'not a url',
        '',
      ]) {
        expect(normalizeSharedApi(bad), isNull, reason: bad);
      }
      expect(
        normalizeSharedApi('http://localhost:3100/'),
        'http://localhost:3100',
      );
      expect(
        normalizeSharedApi('https://x.example/base//'),
        'https://x.example/base',
      );
    },
  );
  test('a shared server turns the public build into a live client', () async {
    final requests = <String>[];
    final data = sample('crew');
    final ops = OperationsController(
      readOnly: true,
      sharedApi: 'https://demo.trycloudflare.com',
      client: MockClient((request) async {
        requests.add(
          '${request.method} ${request.url} ${request.headers['x-demo-actor']}',
        );
        if (request.method == 'POST') {
          expect(request.headers['x-demo-token'], 'test-token');
          data['tasks'][0]['completedAt'] = '2026-09-19T05:00:00Z';
        }
        return response(data);
      }),
    );
    addTearDown(ops.dispose);
    expect(ops.readOnly, isFalse);
    expect(ops.sharedApiHost, 'demo.trycloudflare.com');
    ops.actorId = 'crew';
    await ops.refresh();
    expect(
      requests.single,
      'GET https://demo.trycloudflare.com/api/operations crew',
    );
    expect(
      await ops.act('check_stock', {'itemId': 'rice', 'quantity': 2}),
      isTrue,
    );
    expect(
      requests.last,
      'POST https://demo.trycloudflare.com/api/operations crew',
    );
    expect(
      jsonDecode(jsonEncode(ops.data))['tasks'][0]['completedAt'],
      isNotNull,
    );
    final plain = OperationsController(
      readOnly: true,
      client: MockClient((_) async => response(sample())),
    );
    addTearDown(plain.dispose);
    expect(plain.readOnly, isTrue);
  });
}
