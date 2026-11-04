import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import '../domain/operations_repository.dart';
import '../domain/manual_media_repository.dart';
import '../domain/content_translation_repository.dart';
import '../domain/crew_invitation_repository.dart';

const _retainedSnapshotFields = {
  'manualCatalog',
  'storeSetupCatalog',
  'checklistLibrary',
  'checklistBackup',
  'manualPrintTemplates',
  'manualSearch',
  'taskTemplates',
  'recommendedTaps',
};
typedef _SnapshotCache = ({
  String workspaceId,
  Map<String, String> hashes,
  Map<String, String> payloads,
});

/// Reads public samples or the existing demo/cloud snapshot API.
/// Provider webhooks belong on the server, never in this client adapter.
class HttpOperationsRepository
    implements
        OperationsRepository,
        ManualMediaRepository,
        TaskIssueMediaRepository,
        CrewInvitationRepository,
        ContentTranslationRepository {
  HttpOperationsRepository({
    http.Client? client,
    required this.endpoint,
    required this.readOnly,
    this.accessToken,
    Uri? sampleBase,
  }) : _client = client ?? http.Client(),
       sampleBase =
           sampleBase ?? (kIsWeb ? Uri.base : Uri.parse('https://tap2.work/'));

  final http.Client _client;
  String? _syncActor;
  Json? _sync;
  Map<String, String> _fieldHashes = {};
  Map<String, String> _fieldPayloads = {};
  final Uri endpoint;
  // Uri.base is a file URI on iOS/Android. Only web previews resolve relative
  // to the hosting page (including review portals hosted in a subdirectory).
  final Uri sampleBase;
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
      final hashes = result.data['fieldHashes'];
      _fieldHashes = {};
      _fieldPayloads = {};
      if (hashes is Map) {
        for (final field in _retainedSnapshotFields) {
          final hash = hashes[field];
          if (hash is String &&
              RegExp(r'^[a-f0-9]{64}$').hasMatch(hash) &&
              result.data.containsKey(field)) {
            _fieldHashes[field] = hash;
            // Own the cached value; optimistic UI edits cannot alter it.
            _fieldPayloads[field] = jsonEncode(result.data[field]);
          }
        }
      }
    }
  }

  _SnapshotCache? _cacheFor(String actorId, String? workspaceId) {
    if (readOnly ||
        accessToken == null ||
        _syncActor != actorId ||
        _sync?['workspaceId'] is! String ||
        (workspaceId != null && _sync!['workspaceId'] != workspaceId)) {
      return null;
    }
    return (
      workspaceId: _sync!['workspaceId'] as String,
      hashes: Map.of(_fieldHashes),
      payloads: Map.of(_fieldPayloads),
    );
  }

  Uri _withFieldCache(Uri uri, _SnapshotCache? cache) {
    if (readOnly || accessToken == null) return uri;
    return uri.replace(
      queryParameters: {
        ...uri.queryParameters,
        'sync': 'fields-v1',
        if (cache != null && cache.hashes.isNotEmpty)
          'fields': jsonEncode(cache.hashes),
      },
    );
  }

  OperationsResult _restoreFields(
    OperationsResult result,
    _SnapshotCache? cache,
  ) {
    final retained = result.data['retainedFields'];
    if (result.statusCode != 200 || retained == null) return result;
    if (retained is! List ||
        cache == null ||
        result.data['workspaceId'] != cache.workspaceId) {
      throw const FormatException('Invalid snapshot cache scope');
    }
    final body = Map<String, dynamic>.of(result.data)..remove('retainedFields');
    final hashes = body['fieldHashes'];
    for (final field in retained) {
      if (field is! String ||
          !_retainedSnapshotFields.contains(field) ||
          body.containsKey(field) ||
          !cache.payloads.containsKey(field) ||
          hashes is! Map ||
          hashes[field] != cache.hashes[field]) {
        throw const FormatException('Invalid retained snapshot field');
      }
      body[field] = jsonDecode(cache.payloads[field]!);
    }
    return OperationsResult(result.statusCode, body);
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
    final cache = useCache ? _cacheFor(actorId, workspaceId) : null;
    var uri = readOnly
        ? sampleBase.resolve('review-data/$actorId.json')
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
    final result = _restoreFields(
      _decode(
        await _client
            .get(
              _withFieldCache(uri, cache),
              headers: await _headers(actorId, demoToken),
            )
            .timeout(const Duration(seconds: 10)),
      ),
      cache,
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
    final cache = values['action'] == 'create_workspace'
        ? null
        : _cacheFor(actorId, values['workspaceId'] as String?);
    final result = _restoreFields(
      _decode(
        await _client
            .post(
              _withFieldCache(endpoint, cache),
              headers: {
                ...await _headers(actorId, demoToken),
                'Content-Type': 'application/json',
              },
              body: jsonEncode(values),
            )
            .timeout(const Duration(seconds: 10)),
      ),
      cache,
    );
    remember(result, actorId);
    return result;
  }

  @override
  void close() => _client.close();

  @override
  Future<OperationsResult> crewInvitation({
    required String actorId,
    required Json values,
  }) async {
    if (readOnly || accessToken == null) {
      throw StateError('로그인한 매장에서 초대를 사용할 수 있어요.');
    }
    return _decode(
      await _client
          .post(
            endpoint.replace(
              queryParameters: {...endpoint.queryParameters, 'invite': 'crew'},
            ),
            headers: {
              ...await _headers(actorId, null),
              'Content-Type': 'application/json',
            },
            body: jsonEncode(values),
          )
          .timeout(const Duration(seconds: 15)),
    );
  }

  @override
  Future<Json> translateContent({
    required String actorId,
    required String workspaceId,
    required String targetLocale,
    required String kind,
    String? id,
  }) async {
    if (readOnly || accessToken == null) {
      return {'status': 'unavailable'};
    }
    final response = await _client
        .post(
          endpoint.replace(
            queryParameters: {
              ...endpoint.queryParameters,
              'translate': 'content',
            },
          ),
          headers: {
            ...await _headers(actorId, null),
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'workspaceId': workspaceId,
            'targetLocale': targetLocale,
            'source': {'kind': kind, 'id': ?id},
          }),
        )
        .timeout(const Duration(seconds: 25));
    if (response.statusCode != 200) {
      throw StateError('Translation unavailable (${response.statusCode})');
    }
    return jsonDecode(utf8.decode(response.bodyBytes)) as Json;
  }

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
  Future<Json> uploadWorkIssuePhoto({
    required String actorId,
    required String workspaceId,
    required String taskId,
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
            'purpose': 'work_issue',
            'taskId': taskId,
            'photo': 'data:image/jpeg;base64,${base64Encode(bytes)}',
          }),
        )
        .timeout(const Duration(seconds: 30));
    if (response.statusCode != 200 && response.statusCode != 201) {
      _mediaFailure(response);
    }
    final body = jsonDecode(utf8.decode(response.bodyBytes));
    if (body is! Map ||
        body['reference'] is! String ||
        manualMediaWorkspace(body['reference']) != workspaceId ||
        body['receipt'] is! String ||
        (body['receipt'] as String).isEmpty) {
      throw const ManualMediaException('사진 저장 응답을 확인하지 못했어요. 다시 시도해 주세요.');
    }
    return {'reference': body['reference'], 'receipt': body['receipt']};
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
