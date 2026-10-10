import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'operations_repository.dart';

enum EditConflictChoice { keepEditing, useLatest, useDraft }

class EditFieldConflict {
  const EditFieldConflict(this.field, this.base, this.latest, this.draft);
  final String field;
  final dynamic base, latest, draft;
}

class EditMerge {
  const EditMerge(this.values, this.conflicts);
  final Json values;
  final List<EditFieldConflict> conflicts;
}

Json copyEditSnapshot(Json value) => jsonDecode(jsonEncode(value)) as Json;

bool sameEditValue(dynamic a, dynamic b) {
  if (a is Map && b is Map) {
    return a.length == b.length &&
        a.keys.every(
          (key) => b.containsKey(key) && sameEditValue(a[key], b[key]),
        );
  }
  if (a is List && b is List) {
    return listEquals(
      a.map(_stableValue).toList(),
      b.map(_stableValue).toList(),
    );
  }
  return a == b;
}

String _stableValue(dynamic value) {
  if (value is Map) {
    final keys = value.keys.cast<String>().toList()..sort();
    return '{${keys.map((key) => '${jsonEncode(key)}:${_stableValue(value[key])}').join(',')}}';
  }
  if (value is List) return '[${value.map(_stableValue).join(',')}]';
  return jsonEncode(value);
}

/// Only explicitly supported editor payloads can opt into a three-way merge.
/// Arrays stay atomic: silently merging ranks, service modes or POS devices is
/// not safe. Server validation remains authoritative after any user choice.
Json? editProjection(String action, Json request, Json snapshot) {
  if (action == 'save_store_profile') {
    final store = snapshot['store'] as Json? ?? {};
    final profile = store['profile'] as Json? ?? {};
    if (request['section'] == 'basic') {
      return {
        'name': store['setup'] == 'blank' ? '' : store['name'] ?? '',
        'note': store['note'] ?? '',
        'industryId': profile['industryId'],
        'businessTypeId': profile['businessTypeId'],
        'serviceModes': profile['serviceModes'] ?? [],
        'address': profile['address'] ?? '',
        'addressSelection': profile['addressSelection'],
        'addressDetail': profile['addressDetail'] ?? '',
        'arrivalNote': profile['arrivalNote'] ?? '',
      };
    }
    return (profile[request['section']] as Json?) ??
        {
          'configured': false,
          'enabled': false,
          request['section'] == 'pos' ? 'devices' : 'platforms': <Json>[],
        };
  }
  if (action == 'save_welcome') {
    final row = snapshot['welcome'] as Json?;
    if (row == null) return null;
    return {
      for (final key in ['title', 'body', 'sourceLocale']) key: row[key],
    };
  }
  if (action == 'save_manual_setup') {
    final config = snapshot['store']?['manualSetup'];
    return {
      for (final key in ['selfbar', 'tableBurner'])
        key: config?['conditions']?[key],
      for (final key in ['return', 'waste', 'wash', 'dry', 'supplies'])
        key: config?['places']?[key],
    };
  }
  if (action == 'save_place') {
    final id = request['place']?['id'];
    final row = (snapshot['zones'] as List? ?? [])
        .whereType<Json>()
        .where((p) => p['id'] == id)
        .firstOrNull;
    if (row == null) return request['editingExisting'] == true ? null : {};
    return {
      for (final key in [
        'kind',
        'name',
        'floor',
        'area',
        'description',
        'photo',
        'seats',
      ])
        key: row[key] ?? (key == 'seats' ? 0 : ''),
    };
  }
  if (action == 'save_tapper') {
    final rows = (snapshot['tappers'] as List? ?? []).cast<Json>();
    final row = rows
        .where(
          (row) => request['id'] != null
              ? row['id'] == request['id']
              : request['creationRequestId'] != null &&
                    row['creationRequestId'] == request['creationRequestId'],
        )
        .firstOrNull;
    if (request['id'] != null && row == null) return null;
    if (row == null) return {};
    return {
      for (final key in [
        'nickname',
        'nationality',
        'guideLocale',
        'rank',
        'employmentType',
        'hourlyWon',
        'payPeriod',
        'kakaoUrl',
        'phone',
        'active',
      ])
        if (request.containsKey(key))
          key:
              row[key] ??
              switch (key) {
                'employmentType' => '시간알바',
                'kakaoUrl' || 'phone' => '',
                'active' => true,
                _ => null,
              },
    };
  }
  throw ArgumentError('Unsupported draft editor: $action');
}

EditMerge mergeEdit(
  Json base,
  Json latest,
  Json draft, {
  EditConflictChoice choice = EditConflictChoice.keepEditing,
}) {
  final merged = <String, dynamic>{};
  final conflicts = <EditFieldConflict>[];
  for (final key in draft.keys) {
    final mineChanged = !sameEditValue(draft[key], base[key]);
    final remoteChanged = !sameEditValue(latest[key], base[key]);
    if (mineChanged &&
        remoteChanged &&
        !sameEditValue(draft[key], latest[key])) {
      conflicts.add(EditFieldConflict(key, base[key], latest[key], draft[key]));
      merged[key] = choice == EditConflictChoice.useLatest
          ? latest[key]
          : draft[key];
    } else {
      merged[key] = mineChanged ? draft[key] : latest[key];
    }
  }
  return EditMerge(merged, conflicts);
}

Json editorDraftValues(String action, Json request) {
  if (action == 'save_store_profile') {
    return copyEditSnapshot(request['values'] as Json);
  }
  if (action == 'save_welcome') {
    return copyEditSnapshot(request['welcome'] as Json);
  }
  if (action == 'save_manual_setup') {
    return {
      for (final key in ['selfbar', 'tableBurner'])
        key: request['setup']?['conditions']?[key],
      for (final key in ['return', 'waste', 'wash', 'dry', 'supplies'])
        key: request['setup']?['places']?[key],
    };
  }
  if (action == 'save_place') {
    return {
      for (final e in (request['place'] as Json).entries)
        if (e.key != 'id' &&
            [
              'kind',
              'name',
              'floor',
              'area',
              'description',
              'photo',
              'seats',
            ].contains(e.key))
          e.key: e.value,
    };
  }
  return {
    for (final e in request.entries)
      if (!['id', 'revision', 'creationRequestId'].contains(e.key))
        e.key: e.value,
  };
}

Json editorMergedRequest(String action, Json request, Json values) {
  if (action == 'save_store_profile') return {...request, 'values': values};
  if (action == 'save_welcome') return {...request, 'welcome': values};
  if (action == 'save_manual_setup') {
    return {
      ...request,
      'setup': {
        'conditions': {
          for (final key in ['selfbar', 'tableBurner']) key: values[key],
        },
        'places': {
          for (final key in ['return', 'waste', 'wash', 'dry', 'supplies'])
            key: values[key],
        },
      },
    };
  }
  if (action == 'save_place') {
    return {
      ...request,
      'place': {...request['place'] as Json, ...values},
    };
  }
  return {...request, ...values};
}
