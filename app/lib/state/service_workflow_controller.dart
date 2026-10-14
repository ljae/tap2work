import 'dart:convert';
import 'dart:math';
import 'operations_controller.dart';

/// A scoped command draft. Retries reuse the request ID and opening revision.
/// A read, briefing acknowledgement and actual task completion stay separate.
class ServiceWorkflowDraft {
  ServiceWorkflowDraft(this.ops)
    : actor = ops.actorId,
      workspace = ops.data?['workspaceId'],
      revision = ops.data?['revision'] ?? 0;
  final OperationsController ops;
  final String actor;
  final Object? workspace;
  final Object revision;
  String? _payload, _requestId;
  bool get valid =>
      actor == ops.actorId && workspace == ops.data?['workspaceId'];
  Future<bool> save(String action, Json values) {
    if (!valid || ops.readOnly || ops.busy) return Future.value(false);
    final payload = jsonEncode({'action': action, ...values});
    if (_payload != payload) {
      _payload = payload;
      _requestId =
          'service-${DateTime.now().microsecondsSinceEpoch}-${Random.secure().nextInt(1 << 30)}';
    }
    return ops.act(action, {
      ...values,
      'revision': revision,
      'requestId': _requestId,
    });
  }
}

/// Retain a briefing command across button taps, refreshes and lost responses.
/// A new day or changed briefing starts a new acknowledgement.
class ServiceBriefingAcknowledgement {
  ServiceBriefingAcknowledgement(this.ops);
  final OperationsController ops;
  ServiceWorkflowDraft? _draft;
  String? _key;

  Future<bool> save(Object? day, Object? hash) {
    final key = jsonEncode([day, hash]);
    if (_key != key || _draft == null || !_draft!.valid) {
      _key = key;
      _draft = ServiceWorkflowDraft(ops);
    }
    return _draft!.save('record_service', {
      'kind': 'briefing',
      'note': '',
      'briefingHash': hash,
    });
  }
}

/// Read-only ordering and current-content status for the short shift screen.
class ServiceWorkflowPresentation {
  ServiceWorkflowPresentation(this.ops);
  final OperationsController ops;
  Json get flow => ops.data?['serviceWorkflow'] as Json? ?? {};
  Json get briefing => flow['briefing'] as Json? ?? {};
  List<Json> get records => (flow['records'] as List? ?? []).cast<Json>();

  bool get acknowledged => records.any((row) {
    if (row['kind'] != 'briefing' ||
        row['actor']?['id'] != ops.actorId ||
        row['day'] != flow['day'] ||
        row['briefingNote'] != (briefing['note'] ?? '')) {
      return false;
    }
    final current = (briefing['manuals'] as List? ?? []).cast<Json>();
    final read = (row['manuals'] as List? ?? []).cast<Json>();
    return current.length == read.length &&
        List.generate(current.length, (i) => i).every(
          (i) =>
              current[i]['id'] == read[i]['id'] &&
              current[i]['hash'] == read[i]['hash'] &&
              current[i]['version'] == read[i]['version'],
        );
  });

  bool needsMyConfirmation(Json row) =>
      row['kind'] == 'practice' &&
      row['confirmation'] == null &&
      ops
          .rows('tappers')
          .any(
            (p) =>
                p['id'] == row['buddyCrewId'] &&
                p['active'] == true &&
                p['actorId'] == ops.actorId,
          );

  List<Json> get pendingHandovers {
    final result = records
        .where((r) => r['kind'] == 'handoff' && r['resolution'] == null)
        .toList();
    // Preserve server recency within each priority group.
    return [
      ...result.where((r) => r['canResolve'] == true),
      ...result.where((r) => r['canResolve'] != true),
    ];
  }

  List<Json> get resolvedHandovers => records
      .where((r) => r['kind'] == 'handoff' && r['resolution'] != null)
      .toList();
  List<Json> get pendingConfirmations =>
      records.where(needsMyConfirmation).toList();
  List<Json> get practiceHistory => records
      .where(
        (r) =>
            ['practice', 'feedback'].contains(r['kind']) &&
            !needsMyConfirmation(r),
      )
      .toList();
}
