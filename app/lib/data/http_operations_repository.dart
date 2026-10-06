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
  String? _syncActor;
  Json? _sync;
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

  void remember(OperationsResult result, String actorId) {
    if (result.statusCode == 200 && result.data['syncWindow'] != null) {
      _syncActor = actorId;
      _sync = result.data;
    }
  }

  @override
  Future<OperationsResult> read({
    required String actorId,
    String? demoToken,
    String? scheduleFrom,
    String? scheduleTo,
    String? workspaceId,
  }) async {
    var uri = readOnly
        ? Uri.base.resolve('review-data/$actorId.json')
        : endpoint;
    if (!readOnly && workspaceId != null) {
      uri = uri.replace(
        queryParameters: {...uri.queryParameters, 'workspace': workspaceId},
      );
    }
    if (!readOnly && scheduleFrom != null && scheduleTo != null) {
      uri = uri.replace(
        queryParameters: {
          ...uri.queryParameters,
          'scheduleFrom': scheduleFrom,
          'scheduleTo': scheduleTo,
        },
      );
    }
    if (!readOnly &&
        accessToken != null &&
        _syncActor == actorId &&
        _sync != null &&
        (workspaceId == null || _sync!['workspaceId'] == workspaceId)) {
      uri = uri.replace(
        queryParameters: {
          ...uri.queryParameters,
          'revision': '${_sync!['revision']}',
          'window': '${_sync!['syncWindow']}',
          'role': '${_sync!['actor']['role']}',
          'workspace': '${_sync!['workspaceId']}',
        },
      );
    }
    final result = _decode(
      await _client
          .get(uri, headers: await _headers(actorId, demoToken))
          .timeout(const Duration(seconds: 10)),
    );
    if (result.statusCode == 200 && result.data['unchanged'] == true) {
      return OperationsResult(304, result.data);
    }
    remember(result, actorId);
    return result;
  }

  @override
  Future<OperationsResult> write({
    required String actorId,
    String? demoToken,
    required Json values,
  }) async {
    if (readOnly) throw StateError('공개 미리보기에서는 저장할 수 없어요.');
    final result = _decode(
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
    remember(result, actorId);
    return result;
  }

  @override
  void close() => _client.close();
}
