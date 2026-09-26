import 'dart:convert';
import 'package:http/http.dart' as http;
import '../domain/operations_repository.dart';

/// Reads public samples or the existing demo/cloud snapshot API.
/// Provider webhooks belong on the server, never in this client adapter.
class HttpOperationsRepository implements OperationsRepository {
  HttpOperationsRepository({
    http.Client? client,
    required this.endpoint,
    required this.readOnly,
    this.accessToken,
  }) : _client = client ?? http.Client();

  final http.Client _client;
  final Uri endpoint;
  final bool readOnly;
  final Future<String?> Function()? accessToken;

  Future<Map<String, String>> _headers(
    String actorId,
    String? demoToken,
  ) async {
    if (readOnly) return {};
    if (accessToken != null) {
      final token = await accessToken!();
      if (token == null) throw StateError('로그인이 필요해요.');
      return {'Authorization': 'Bearer $token'};
    }
    return {'x-demo-actor': actorId, 'x-demo-token': demoToken ?? ''};
  }

  OperationsResult _decode(http.Response response) => OperationsResult(
    response.statusCode,
    jsonDecode(utf8.decode(response.bodyBytes)) as Json,
  );

  @override
  Future<OperationsResult> read({
    required String actorId,
    String? demoToken,
  }) async => _decode(
    await _client
        .get(
          readOnly ? Uri.base.resolve('review-data/$actorId.json') : endpoint,
          headers: await _headers(actorId, demoToken),
        )
        .timeout(const Duration(seconds: 10)),
  );

  @override
  Future<OperationsResult> write({
    required String actorId,
    String? demoToken,
    required Json values,
  }) async {
    if (readOnly) throw StateError('공개 미리보기에서는 저장할 수 없어요.');
    return _decode(
      await _client
          .post(
            endpoint,
            headers: {
              ...await _headers(actorId, demoToken),
              'Content-Type': 'application/json',
            },
            body: jsonEncode(values),
          )
          .timeout(const Duration(seconds: 10)),
    );
  }

  @override
  void close() => _client.close();
}
