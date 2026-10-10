import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../domain/operations_repository.dart';
import '../domain/manual_media_repository.dart';

/// Reads public samples or the existing demo/cloud snapshot API.
/// Provider webhooks belong on the server, never in this client adapter.
class HttpOperationsRepository
    implements OperationsRepository, ManualMediaRepository {
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
    bool useCache = true,
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
    if (useCache &&
        !readOnly &&
        accessToken != null &&
        _syncActor == actorId &&
        _sync != null &&
        (workspaceId == null || _sync!['workspaceId'] == workspaceId)) {
      uri = uri.replace(
        queryParameters: {
          ...uri.queryParameters,
          'revision': '${_sync!['revision']}',
          if (_sync!['catalogRevision'] != null)
            'catalogRevision': '${_sync!['catalogRevision']}',
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

  Uri _mediaEndpoint(String media, String workspaceId) => endpoint.replace(
    queryParameters: {
      ...endpoint.queryParameters,
      'media': media,
      'workspace': workspaceId,
    },
  );

  void _requireMediaSession() {
    if (readOnly || accessToken == null) {
      throw const ManualMediaException('사진 등록은 로그인한 매장에서 사용할 수 있어요.');
    }
  }

  Never _mediaFailure(http.Response response) {
    String message = '사진을 저장하거나 불러오지 못했어요. 다시 시도해 주세요.';
    try {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (body is Map && body['error'] is String) {
        message = body['error'] as String;
      }
    } catch (_) {
      /* Preserve a useful error for non-JSON proxy responses. */
    }
    throw ManualMediaException(message);
  }

  @override
  Future<String> uploadManualPhoto({
    required String actorId,
    required String workspaceId,
    required Uint8List bytes,
  }) async {
    _requireMediaSession();
    if (bytes.isEmpty || bytes.length > 250000) {
      throw const ManualMediaException('사진 용량을 줄인 뒤 다시 시도해 주세요.');
    }
    final response = await _client
        .post(
          _mediaEndpoint('upload', workspaceId),
          headers: {
            ...await _headers(actorId, null),
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'workspaceId': workspaceId,
            'photo': 'data:image/jpeg;base64,${base64Encode(bytes)}',
          }),
        )
        .timeout(const Duration(seconds: 30));
    if (response.statusCode != 200 && response.statusCode != 201) {
      _mediaFailure(response);
    }
    final body = jsonDecode(utf8.decode(response.bodyBytes));
    final reference = body is Map ? body['reference'] : null;
    if (reference is! String ||
        manualMediaWorkspace(reference) != workspaceId) {
      throw const ManualMediaException('사진 저장 응답을 확인하지 못했어요. 다시 시도해 주세요.');
    }
    return reference;
  }

  @override
  Future<Uint8List> loadManualPhoto({
    required String actorId,
    required String workspaceId,
    required String reference,
  }) async {
    _requireMediaSession();
    if (manualMediaWorkspace(reference) != workspaceId) {
      throw const ManualMediaException('다른 매장의 사진을 불러올 수 없어요.');
    }
    final response = await _client
        .get(
          _mediaEndpoint(reference, workspaceId),
          headers: await _headers(actorId, null),
        )
        .timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) _mediaFailure(response);
    if (response.headers['content-type']?.split(';').first != 'image/jpeg' ||
        response.bodyBytes.length > 250000 ||
        response.bodyBytes.length < 4 ||
        response.bodyBytes[0] != 0xff ||
        response.bodyBytes[1] != 0xd8) {
      throw const ManualMediaException('사진 파일을 확인하지 못했어요.');
    }
    return response.bodyBytes;
  }
}
