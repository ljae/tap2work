import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/widgets.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

import '../data/http_operations_repository.dart';
import '../domain/operations_repository.dart';
import '../domain/manual_media_repository.dart';
export '../domain/operations_repository.dart' show Json;

/// Public preview, local demo, or verified Supabase workspace transport.
class OperationsController extends ChangeNotifier with WidgetsBindingObserver {
  OperationsController({
    http.Client? client,
    OperationsRepository? repository,
    Uri? endpoint,
    bool readOnly = const bool.fromEnvironment('PUBLIC_REVIEW'),
    this.sharedApi,
    this.accessToken,
    this.loadWorkspace,
    this.saveWorkspace,
  }) : // A shared demo server turns the read-only public build into a live shared client.
       readOnly = sharedApi == null && readOnly,
       endpoint =
           endpoint ??
           Uri.parse(
             '${sharedApi ?? (kIsWeb ? Uri.base.origin : const String.fromEnvironment('OPS_API_BASE', defaultValue: 'http://localhost:3100'))}/api/operations',
           ) {
    _repository =
        repository ??
        HttpOperationsRepository(
          client: client,
          endpoint: this.endpoint,
          readOnly: this.readOnly,
          accessToken: accessToken,
        );
  }
  late final OperationsRepository _repository;
  final Uri endpoint;
  final bool readOnly;
  final Future<String?> Function()? accessToken;
  final Future<String?> Function()? loadWorkspace;
  final Future<void> Function(String)? saveWorkspace;
  String? workspaceId;
  List<Json> workspaces = [];
  bool get cloud => accessToken != null;

  /// Base URL of a shared demo server reached through a tunnel, or null.
  final String? sharedApi;
  String? get sharedApiHost =>
      sharedApi == null ? null : Uri.parse(sharedApi!).host;
  Json? data;
  String actorId = 'owner';
  String? error;
  Json? actionFailure;
  bool busy = false;
  bool _refreshing = false;
  bool _disposed = false;
  int _generation = 0;
  Timer? _timer;
  bool _observing = false;
  bool _foreground = true;
  String? _token;
  String? _scheduleFrom, _scheduleTo;

  void showScheduleRange(String from, String to) {
    if (_scheduleFrom == from && _scheduleTo == to) return;
    _scheduleFrom = from;
    _scheduleTo = to;
    _generation++;
    refresh(force: true);
  }

  List<Json> rows(String key) => (data?[key] as List? ?? []).cast<Json>();
  Json get actor =>
      data?['actor'] as Json? ??
      {'name': '서연', 'label': '사장님', 'role': 'owner', 'emoji': '🌻'};
  bool get isLeader => ['owner', 'manager'].contains(actor['role']);
  bool get canEditTasks => isLeader && data?['canEditTasks'] != false;
  bool get isOwner => actor['role'] == 'owner';

  Future<String> uploadManualPhoto(Uint8List bytes) async {
    final repository = _repository;
    final openingActor = actorId;
    final openingWorkspace = data?['workspaceId'] as String?;
    if (_disposed ||
        readOnly ||
        !cloud ||
        !canEditTasks ||
        openingWorkspace == null ||
        repository is! ManualMediaRepository) {
      throw const ManualMediaException('사진 등록은 편집 권한이 있는 로그인 매장에서 사용할 수 있어요.');
    }
    final result = await (repository as ManualMediaRepository)
        .uploadManualPhoto(
          actorId: openingActor,
          workspaceId: openingWorkspace,
          bytes: bytes,
        );
    if (_disposed ||
        openingActor != actorId ||
        openingWorkspace != data?['workspaceId'] ||
        !canEditTasks) {
      throw const ManualMediaException('권한 또는 매장이 변경됐어요. 다시 열어 주세요.');
    }
    return result;
  }

  Future<Uint8List> loadManualPhoto(String reference) async {
    final repository = _repository;
    final openingActor = actorId;
    final openingWorkspace = data?['workspaceId'] as String?;
    if (_disposed ||
        readOnly ||
        !cloud ||
        openingWorkspace == null ||
        repository is! ManualMediaRepository ||
        manualMediaWorkspace(reference) != openingWorkspace) {
      throw const ManualMediaException('이 매장에서 사진을 불러올 수 없어요.');
    }
    final result = await (repository as ManualMediaRepository).loadManualPhoto(
      actorId: openingActor,
      workspaceId: openingWorkspace,
      reference: reference,
    );
    if (_disposed ||
        openingActor != actorId ||
        openingWorkspace != data?['workspaceId']) {
      throw const ManualMediaException('매장이 변경됐어요. 사진을 다시 열어 주세요.');
    }
    return result;
  }

  Future<void> start() async {
    if (!_observing) {
      WidgetsBinding.instance.addObserver(this);
      _observing = true;
    }
    if (cloud && workspaceId == null && loadWorkspace != null) {
      try {
        workspaceId = await loadWorkspace!();
      } catch (_) {
        /* A local preference must not block login. */
      }
    }
    if (_disposed) return;
    await refresh();
    scheduleRefresh();
  }

  void scheduleRefresh() {
    _timer?.cancel();
    if (_disposed || readOnly || !_foreground) return;
    _timer = Timer(const Duration(seconds: 30), () async {
      await refresh();
      scheduleRefresh();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (_foreground) {
      refresh();
      scheduleRefresh();
    } else {
      _timer?.cancel();
    }
  }

  Future<void> selectWorkspace(String id) async {
    if (!cloud || busy || _disposed || (id == workspaceId && data != null)) {
      return;
    }
    if (!workspaces.any((w) => w['id'] == id)) return;
    workspaceId = id;
    _generation++;
    data = null;
    error = null;
    _scheduleFrom = null;
    _scheduleTo = null;
    _previewTickets.clear();
    _emit();
    await refresh(force: true);
  }

  void _rememberWorkspace(Json body) {
    if (body['workspaces'] is List) {
      workspaces = (body['workspaces'] as List).cast<Json>();
    }
    if (body['workspaceId'] is String) {
      workspaceId = body['workspaceId'] as String;
      if (saveWorkspace != null) {
        unawaited(saveWorkspace!(workspaceId!).catchError((Object _) {}));
      }
    }
  }

  Future<void> selectActor(String id) async {
    if (cloud || busy || id == actorId) return;
    actorId = id;
    _generation++;
    data = null;
    error = null;
    _token = null;
    _scheduleFrom = null;
    _scheduleTo = null;
    _emit();
    await refresh(force: true);
  }

  Future<void> refresh({bool force = false}) async {
    if (_disposed || busy || (_refreshing && !force)) return;
    _refreshing = true;
    if (data == null && error != null) {
      error = null;
      _emit();
    }
    final generation = _generation;
    try {
      final response = await _repository.read(
        actorId: actorId,
        demoToken: _token,
        scheduleFrom: _scheduleFrom,
        scheduleTo: _scheduleTo,
        workspaceId: workspaceId,
        useCache: data != null,
      );
      if (_disposed || generation != _generation) return;
      _rememberWorkspace(response.data);
      if (response.statusCode == 304) {
        error = null;
        return;
      }
      final body = response.data;
      if (response.statusCode != 200) {
        if (cloud && response.statusCode == 403 && body['workspaces'] is List) {
          data = null;
        }
        final message = body['error'];
        error = message is String && message.trim().isNotEmpty
            ? message
            : '매장 정보를 불러오지 못했어요. 잠시 후 다시 시도해 주세요.';
        return;
      }
      _previewTickets.clear();
      data = body;
      if (cloud && body['actor'] is Json) actorId = body['actor']['id'];
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
    actionFailure = null;
    if (readOnly) {
      error = '공개 미리보기에서는 저장하지 않아요. 화면과 발주 구성을 살펴보세요.';
      _emit();
      return false;
    }
    if (busy || (data == null && action != 'create_workspace') || _disposed) {
      return false;
    }
    busy = true;
    error = null;
    _generation++;
    _refreshing = false;
    _emit();
    var success = false;
    var conflict = false;
    String? failure;
    try {
      final response = await _repository.write(
        actorId: actorId,
        demoToken: _token,
        values: {
          ...values,
          'action': action,
          if (cloud && workspaceId != null) 'workspaceId': workspaceId,
          if (_scheduleFrom != null) 'scheduleFrom': _scheduleFrom,
          if (_scheduleTo != null) 'scheduleTo': _scheduleTo,
          'revision': values['revision'] ?? data?['revision'] ?? 0,
        },
      );
      if (_disposed) return false;
      final body = response.data;
      if (response.statusCode == 200) {
        if (action == 'create_workspace') {
          _scheduleFrom = null;
          _scheduleTo = null;
        }
        _rememberWorkspace(body);
        data = body;
        if (cloud && body['actor'] is Json) actorId = body['actor']['id'];
        _token = body['demoToken'] as String?;
        success = true;
      } else {
        actionFailure = body;
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

  // A preview has one shared in-memory state across Home, Todo and Calendar.
  bool previewUpdateManualStep(String templateId, String stepId, Json draft) {
    if (!readOnly || data == null) return false;
    final template = rows('taskTemplates')
        .where((t) => t['id'] == templateId && t['archivedAt'] == null)
        .firstOrNull;
    final step = (template?['steps'] as List? ?? [])
        .cast<Json>()
        .where((s) => s['id'] == stepId)
        .firstOrNull;
    if (step == null) return false;
    step.addAll(draft);
    for (final row in rows('manualSearch')) {
      if (row['templateId'] == templateId && row['sourceStepId'] == stepId) {
        for (final field in [
          'title',
          'manual',
          'tip',
          'tags',
          'imageUrl',
          'videoUrl',
          'sourceUrl',
        ]) {
          row[field] = field == 'title'
              ? step['manualTitle'] ?? step[field]
              : step[field];
        }
      }
    }
    _emit();
    return true;
  }

  bool previewSaveTaskStep(String taskId, String? stepId, Json draft) {
    if (!readOnly || !canEditTasks || data == null) return false;
    final task = rows('tasks').where((t) => t['id'] == taskId).firstOrNull;
    if (task == null ||
        task['completedAt'] != null ||
        task['preparedOutputMovementId'] != null) {
      return false;
    }
    final steps = (task['steps'] as List).cast<Json>();
    final step = stepId == null
        ? <String, dynamic>{
            'id': 'preview-${DateTime.now().microsecondsSinceEpoch}',
            'tip': '',
            'tags': <String>[],
          }
        : steps.where((s) => s['id'] == stepId).firstOrNull;
    if (step == null || step['completedAt'] != null) return false;
    final template = rows('taskTemplates')
        .where(
          (t) =>
              t['id'] == (step['sourceTemplateId'] ?? task['templateId']) &&
              t['archivedAt'] == null,
        )
        .firstOrNull;
    final sourceSteps = (template?['steps'] as List? ?? []).cast<Json>();
    if (stepId == null && (steps.length >= 30 || sourceSteps.length >= 30)) {
      return false;
    }
    step.addAll(draft);
    if (stepId == null) {
      (task['steps'] as List).add(step);
      if (template != null) {
        (template['steps'] as List).add({...step});
        (data!['manualSearch'] as List? ?? []).add({
          ...step,
          'id': "${template['id']}/${step['id']}",
          'templateId': template['id'],
          'sourceStepId': step['id'],
          'tapId': template['id'],
          'tapTitle': template['title'],
          'folderId': template['folderId'],
          'editable': true,
        });
      }
    } else if (template != null) {
      previewUpdateManualStep(
        template['id'],
        step['sourceStepId'] ?? step['id'],
        draft,
      );
    }
    _emit();
    return true;
  }

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
      if (status == 'keep') {
        task['folderId'] = folder;
        continue;
      }
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
        'completedAt': status == 'done' ? (task['completedAt'] ?? now) : null,
        'completedBy': status == 'done' ? (task['completedBy'] ?? actor) : null,
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
          : row['orderId'] != null
          ? 'order'
          : 'todo';
    }

    final destinationLane =
        status == 'done' ||
            (status == 'keep' && moving.every((t) => t['completedAt'] != null))
        ? 'done'
        : task['orderId'] != null
        ? 'order'
        : 'todo';

    final lane =
        rows('tasks')
            .where(
              (t) =>
                  !moving.contains(t) &&
                  t['kind'] == 'routine' &&
                  laneStatus(t) == destinationLane,
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
      final gap = ((item['target'] as num) - (item['onHand'] as num)).toInt();
      final batch = (item['batchQuantity'] as num).toInt();
      final planned = gap > batch ? gap : batch;
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
    if (task == null ||
        item == null ||
        task['completedAt'] != null ||
        task['supersededAt'] != null) {
      return;
    }
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
    if (_observing) WidgetsBinding.instance.removeObserver(this);
    _repository.close();
    super.dispose();
  }
}
