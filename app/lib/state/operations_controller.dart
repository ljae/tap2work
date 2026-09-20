import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

typedef Json = Map<String, dynamic>;

/// Local shared demo only. Actor selection is deliberately NOT authentication.
class OperationsController extends ChangeNotifier {
  OperationsController({
    http.Client? client,
    Uri? endpoint,
    bool readOnly = const bool.fromEnvironment('PUBLIC_REVIEW'),
    this.sharedApi,
  }) : _client = client ?? http.Client(),
       // A shared demo server turns the read-only public build into a live shared client.
       readOnly = sharedApi == null && readOnly,
       endpoint =
           endpoint ??
           Uri.parse(
             '${sharedApi ?? (kIsWeb ? Uri.base.origin : const String.fromEnvironment('OPS_API_BASE', defaultValue: 'http://localhost:3100'))}/api/operations',
           );
  final http.Client _client;
  final Uri endpoint;
  final bool readOnly;

  /// Base URL of a shared demo server reached through a tunnel, or null.
  final String? sharedApi;
  String? get sharedApiHost =>
      sharedApi == null ? null : Uri.parse(sharedApi!).host;
  Json? data;
  String actorId = 'owner';
  String? error;
  bool busy = false;
  bool _refreshing = false;
  bool _disposed = false;
  int _generation = 0;
  Timer? _timer;
  String? _token;

  List<Json> rows(String key) => (data?[key] as List? ?? []).cast<Json>();
  Json get actor =>
      data?['actor'] as Json? ??
      {'name': '서연', 'label': '사장님', 'role': 'owner', 'emoji': '🌻'};
  bool get isLeader => ['owner', 'manager'].contains(actor['role']);
  bool get isOwner => actor['role'] == 'owner';

  Future<void> start() async {
    await refresh();
    if (!_disposed && !readOnly) {
      _timer ??= Timer.periodic(const Duration(seconds: 5), (_) => refresh());
    }
  }

  Future<void> selectActor(String id) async {
    if (busy || id == actorId) return;
    actorId = id;
    _generation++;
    data = null;
    error = null;
    _token = null;
    _emit();
    await refresh(force: true);
  }

  Future<void> refresh({bool force = false}) async {
    if (_disposed || busy || (_refreshing && !force)) return;
    _refreshing = true;
    final generation = _generation;
    try {
      final response = await _client
          .get(
            readOnly ? Uri.base.resolve('review-data/$actorId.json') : endpoint,
            headers: readOnly ? {} : {'x-demo-actor': actorId},
          )
          .timeout(const Duration(seconds: 10));
      if (_disposed || generation != _generation) return;
      final body = jsonDecode(utf8.decode(response.bodyBytes)) as Json;
      if (response.statusCode != 200) throw Exception(body['error']);
      data = body;
      _token = body['demoToken'] as String?;
      error = null;
    } catch (_) {
      if (generation == _generation && !_disposed) {
        error = '매장 서버에 연결하지 못했어요. 연결을 확인하고 다시 시도해 주세요.';
      }
    } finally {
      if (generation == _generation) {
        _refreshing = false;
        _emit();
      }
    }
  }

  Future<bool> act(String action, Json values) async {
    if (readOnly) {
      error = '공개 미리보기에서는 저장하지 않아요. 화면과 발주 구성을 살펴보세요.';
      _emit();
      return false;
    }
    if (busy || data == null || _disposed) return false;
    busy = true;
    error = null;
    _generation++;
    _refreshing = false;
    _emit();
    var success = false;
    var conflict = false;
    String? failure;
    try {
      final response = await _client
          .post(
            endpoint,
            headers: {
              'Content-Type': 'application/json',
              'x-demo-actor': actorId,
              'x-demo-token': _token ?? '',
            },
            body: jsonEncode({
              ...values,
              'action': action,
              'revision': values['revision'] ?? data!['revision'],
            }),
          )
          .timeout(const Duration(seconds: 10));
      final body = jsonDecode(utf8.decode(response.bodyBytes)) as Json;
      if (response.statusCode == 200) {
        data = body;
        _token = body['demoToken'] as String?;
        success = true;
      } else {
        failure = body['error'] as String? ?? '저장하지 못했어요.';
        conflict = response.statusCode == 409 || response.statusCode == 403;
      }
    } catch (_) {
      failure = '저장 결과를 확인하지 못했어요. 새로고침으로 내역을 확인한 뒤 다시 시도해 주세요.';
    }
    busy = false;
    if (conflict) await refresh();
    error = failure;
    _emit();
    return success;
  }

  void _emit() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _client.close();
    super.dispose();
  }
}
