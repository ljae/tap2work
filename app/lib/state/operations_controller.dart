import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

typedef Json = Map<String, dynamic>;

/// Public preview, local demo, or verified Supabase workspace transport.
class OperationsController extends ChangeNotifier {
  OperationsController({
    http.Client? client,
    Uri? endpoint,
    bool readOnly = const bool.fromEnvironment('PUBLIC_REVIEW'),
    this.sharedApi,
    this.accessToken,
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
  final Future<String?> Function()? accessToken;
  bool get cloud => accessToken != null;

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
    if (cloud || busy || id == actorId) return;
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
            headers: await _headers(),
          )
          .timeout(const Duration(seconds: 10));
      if (_disposed || generation != _generation) return;
      final body = jsonDecode(utf8.decode(response.bodyBytes)) as Json;
      if (response.statusCode != 200) throw Exception(body['error']);
      _previewTickets.clear();
      data = body;
      if (cloud) actorId = body['actor']['id'];
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
            headers: {...await _headers(), 'Content-Type': 'application/json'},
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

  Future<Map<String, String>> _headers() async {
    if (readOnly) return {};
    if (cloud) {
      final token = await accessToken!();
      if (token == null) throw StateError('로그인이 필요해요.');
      return {'Authorization': 'Bearer $token'};
    }
    return {'x-demo-actor': actorId, 'x-demo-token': _token ?? ''};
  }

  // A preview has one shared in-memory state across Home, Todo and Calendar.
  void previewMoveTap(
    String id,
    String folder,
    String status, {
    String? beforeTaskId,
  }) {
    if (!readOnly || data == null) return;
    final task = rows('tasks').firstWhere((t) => t['id'] == id);
    final moving = task['orderId'] == null
        ? [task]
        : rows('tasks').where((t) => t['orderId'] == task['orderId']).toList();
    for (final task in moving) {
      final wasDone = task['completedAt'] != null;
      final now = DateTime.now().toUtc().toIso8601String();
      for (final step in (task['steps'] as List).cast<Json>()) {
        if (status == 'done' && step['completedAt'] == null) {
          step.addAll({
            'completedAt': now,
            'completedBy': actor,
            'preview': true,
          });
        } else if (wasDone && status != 'done') {
          step.remove('completedAt');
          step.remove('completedBy');
          step.remove('preview');
        }
      }
      task.addAll({
        'folderId': folder,
        'boardStatus': status,
        'completedAt': status == 'done' ? now : null,
        'completedBy': status == 'done' ? actor : null,
        'canComplete': status != 'done',
      });
      _previewConsumePrepared(task);
    }
    String laneStatus(Json row) {
      final group = row['orderId'] == null
          ? [row]
          : rows('tasks').where((t) => t['orderId'] == row['orderId']);
      return group.every((t) => t['completedAt'] != null)
          ? 'done'
          : group.any(
              (t) =>
                  t['completedAt'] != null || t['boardStatus'] == 'processing',
            )
          ? 'processing'
          : 'todo';
    }

    final lane =
        rows('tasks')
            .where(
              (t) =>
                  !moving.contains(t) &&
                  t['kind'] == 'routine' &&
                  laneStatus(t) == status,
            )
            .toList()
          ..sort(
            (a, b) => ((a['displayOrder'] ?? 0) as int).compareTo(
              (b['displayOrder'] ?? 0) as int,
            ),
          );
    final index = beforeTaskId == null
        ? lane.length
        : lane.indexWhere((t) => t['id'] == beforeTaskId);
    lane.insertAll(index < 0 ? lane.length : index, moving);
    for (var i = 0; i < lane.length; i++) {
      lane[i]['displayOrder'] = i;
    }
    _previewOrder(task);
    _emit();
  }

  void previewToggleStep(String taskId, String stepId) {
    if (!readOnly || data == null) return;
    final task = rows('tasks').firstWhere((t) => t['id'] == taskId);
    final steps = (task['steps'] as List).cast<Json>();
    final step = steps.firstWhere((s) => s['id'] == stepId);
    if (step['completedAt'] != null) {
      step.remove('completedAt');
      step.remove('completedBy');
      step.remove('preview');
    } else {
      step.addAll({
        'completedAt': DateTime.now().toUtc().toIso8601String(),
        'completedBy': actor,
        'preview': true,
      });
    }
    final done = steps.every((s) => s['completedAt'] != null);
    task.addAll({
      'completedAt': done ? DateTime.now().toUtc().toIso8601String() : null,
      'completedBy': done ? actor : null,
      'boardStatus': done ? 'done' : 'processing',
      'canComplete': !done,
    });
    _previewConsumePrepared(task);
    _previewOrder(task);
    _emit();
  }

  final _previewTickets = <String, Json>{};
  void _previewConsumePrepared(Json task) {
    if (task['orderId'] == null ||
        task['preparedUsageVersion'] != null ||
        !['processing', 'done'].contains(task['boardStatus'])) {
      return;
    }
    task['preparedUsageVersion'] = 'preview';
    final ticket = (data?['dashboard']?['queue'] as List? ?? [])
        .cast<Json>()
        .where((row) => row['id'] == task['orderId'])
        .firstOrNull;
    final lines = (ticket?['lines'] as List? ?? []).cast<Json>();
    final index = task['orderLineIndex'] as int? ?? 0;
    final menuId =
        task['menuId'] ??
        (index < lines.length ? lines[index]['menuId'] : null);
    final quantity =
        task['menuQuantity'] ??
        (index < lines.length ? lines[index]['quantity'] : 1);
    for (final item in rows('preparedItems')) {
      final use = (item['menuUses'] as List? ?? [])
          .cast<Json>()
          .where((row) => row['menuId'] == menuId)
          .firstOrNull;
      if (use != null) {
        item['onHand'] =
            (item['onHand'] as num).toInt() -
            (use['quantity'] as num).toInt() * (quantity as num).toInt();
      }
    }
    _previewEnsurePreparation();
  }

  void _previewEnsurePreparation() {
    final tasks = rows('tasks');
    for (final item in rows('preparedItems')) {
      final open = tasks
          .where(
            (t) =>
                t['preparedItemId'] == item['id'] &&
                t['completedAt'] == null &&
                t['supersededAt'] == null,
          )
          .firstOrNull;
      if ((item['onHand'] as num) > (item['minimum'] as num)) {
        if (open != null) open['supersededAt'] = 'preview';
        continue;
      }
      if (open != null) continue;
      final generation = ((item['generation'] ?? 0) as num).toInt() + 1;
      item['generation'] = generation;
      final planned = ((item['target'] as num) - (item['onHand'] as num))
          .toInt();
      tasks.add({
        'id': 'preview-prepare-${item['id']}-$generation',
        'preparedItemId': item['id'],
        'title': '${item['name']} $planned${item['unit']} 준비',
        'plannedQuantity': planned,
        'folderId': item['folderId'],
        'zone': item['zone'],
        'slot': '준비',
        'requiredRole': 'cook',
        'kind': 'routine',
        'date': data?['day'],
        'boardStatus': 'todo',
        'completedAt': null,
        'canComplete': true,
        'steps': [
          {'id': 'check', 'title': '준비 기준 확인', 'manual': '매장 기준을 확인하세요.'},
          {
            'id': 'prepare',
            'title': '${item['name']} 만들기',
            'manual': item['instructions'] ?? '매장 절차로 준비하세요.',
          },
          {'id': 'record', 'title': '완성 수량 확인', 'manual': '실제 완성 수량을 입력하세요.'},
        ],
      });
    }
  }

  void previewCompletePreparation(String taskId, int quantity) {
    if (!readOnly || data == null || quantity < 1) return;
    final task = rows('tasks').where((t) => t['id'] == taskId).firstOrNull;
    final item = rows(
      'preparedItems',
    ).where((i) => i['id'] == task?['preparedItemId']).firstOrNull;
    if (task == null || item == null || task['completedAt'] != null) return;
    item['onHand'] = (item['onHand'] as num).toInt() + quantity;
    task['preparedActualQuantity'] = quantity;
    task['preparedOutputMovementId'] = 'preview-$taskId';
    previewMoveTap(taskId, task['folderId'], 'done');
    _previewEnsurePreparation();
    _emit();
  }

  void _previewOrder(Json task) {
    if (task['orderId'] == null || data?['dashboard'] == null) return;
    final dashboard = data!['dashboard'] as Json;
    final queue = (dashboard['queue'] as List).cast<Json>();
    final ticket =
        queue.where((t) => t['id'] == task['orderId']).firstOrNull ??
        _previewTickets[task['orderId']];
    if (ticket == null) return;
    _previewTickets[ticket['id']] = ticket;
    final oldStatus = ticket['status'];
    final group = rows('tasks').where((t) => t['orderId'] == task['orderId']);
    final next = group.every((t) => t['completedAt'] != null)
        ? '완료'
        : group.any(
            (t) => t['completedAt'] != null || t['boardStatus'] == 'processing',
          )
        ? '조리 중'
        : '접수';
    if (oldStatus == next) return;
    ticket['status'] = next;
    final delta = (next == '완료' ? 0 : 1) - (oldStatus == '완료' ? 0 : 1);
    for (final report in (dashboard['reports'] as List).cast<Json>()) {
      final day = DateTime.parse(ticket['createdAt'])
          .toUtc()
          .add(const Duration(hours: 9))
          .toIso8601String()
          .substring(0, 10);
      if (day.compareTo(report['startDay']) < 0 ||
          day.compareTo(report['endDay']) > 0 ||
          (report['channel'] != '전체' &&
              report['channel'] != ticket['channel'])) {
        continue;
      }
      final summary = report['summary'] as Json;
      summary['activeCount'] = (summary['activeCount'] as int) + delta;
      final statuses = report['statuses'] as Json;
      statuses[oldStatus] = (statuses[oldStatus] as int) - 1;
      statuses[next] = (statuses[next] as int) + 1;
      for (final line in (ticket['lines'] as List).cast<Json>()) {
        for (final menu in (report['menus'] as List).cast<Json>().where(
          (m) => m['id'] == line['menuId'],
        )) {
          menu['pendingQuantity'] =
              (menu['pendingQuantity'] as num) +
              delta * (line['quantity'] as num);
        }
      }
    }
    if (next == '완료') {
      queue.removeWhere((t) => t['id'] == ticket['id']);
    } else if (!queue.any((t) => t['id'] == ticket['id'])) {
      queue.add(ticket);
    }
    dashboard['queue'] = queue;
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
