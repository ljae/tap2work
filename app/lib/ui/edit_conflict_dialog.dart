import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../domain/edit_conflict.dart';
import 'components.dart';
import '../state/operations_controller.dart';
import 'place_guide.dart';

const _fieldNames = {
  'title': 'welcome.titleField',
  'body': 'welcome.bodyField',
  'sourceLocale': 'welcome.sourceLocale',
  'floor': 'conflict.floor',
  'area': 'conflict.area',
  'description': 'welcome.bodyField',
  'kind': 'conflict.kind',
  'seats': 'conflict.seats',
  'photo': 'manual.photo',
  'selfbar': 'conflict.selfbar',
  'tableBurner': 'conflict.tableBurner',
  'return': 'setup.returnPlace',
  'wash': 'setup.washPlace',
  'dry': 'setup.dryPlace',
  'waste': 'setup.wastePlace',
  'supplies': 'setup.suppliesPlace',
  'name': 'conflict.name',
  'note': 'welcome.bodyField',
  'industryId': '업종',
  'businessTypeId': '세부 업종',
  'serviceModes': '운영 형태',
  'address': '주소',
  'addressSelection': '검색한 주소',
  'addressDetail': '상세 주소',
  'arrivalNote': '찾아오는 방법',
  'devices': 'POS 기기',
  'enabled': '사용 여부',
  'platforms': '배달 플랫폼',
  'configured': '설정 상태',
  'nickname': '별칭(이름)',
  'nationality': 'crew.nationality',
  'guideLocale': 'language.title',
  'rank': 'conflict.role',
  'employmentType': '고용형태',
  'hourlyWon': '시급',
  'payPeriod': '급여 방식',
  'kakaoUrl': '카카오톡 링크',
  'phone': '전화번호',
  'active': '활동 상태',
};

String _value(
  BuildContext context,
  dynamic value, {
  required String field,
  OperationsController? ops,
  dynamic basePhoto,
}) {
  if (field == 'photo' ||
      value is String &&
          (value.startsWith('tap2work-media:') || value.startsWith('data:'))) {
    if (value == null || value == '') return context.t('conflict.photoAbsent');
    return context.t(
      basePhoto != null && value != basePhoto
          ? 'conflict.photoChanged'
          : 'conflict.photoPresent',
    );
  }
  if (['return', 'wash', 'dry', 'waste', 'supplies'].contains(field)) {
    if (value == null || value == '') return context.t('conflict.placeUnset');
    final zone = ops?.rows('zones').where((p) => p['id'] == value).firstOrNull;
    if (zone == null) return context.t('conflict.placeMissing');
    return '${displayedPlace(context, ops!, zone)['name']}';
  }
  if (value == null || value == '') return context.t('conflict.empty');
  if (field == 'sourceLocale' || field == 'guideLocale') {
    return appLanguageNames[value] ?? context.t('conflict.empty');
  }
  if (field == 'rank') {
    return context.t(switch (value) {
      'owner' => 'store.owner',
      'manager' => 'store.manager',
      'cook' => 'store.cook',
      _ => 'store.crew',
    });
  }
  if (field == 'kind') {
    return context.t(switch (value) {
      'storage' => 'place.kindStorage',
      'equipment' => 'place.kindEquipment',
      'area' => 'place.kindArea',
      'entrance' => 'place.kindEntrance',
      'table' => 'place.kindTable',
      _ => 'conflict.setting',
    });
  }
  if (value is bool) {
    return context.t(value ? 'conflict.enabled' : 'conflict.disabled');
  }
  if (value is List) {
    return value.isEmpty
        ? context.t('conflict.empty')
        : value
              .map((v) => _value(context, v, field: field, ops: ops))
              .join(' · ');
  }
  if (value is Map) {
    return value.entries
        .map((e) => _value(context, e.value, field: '${e.key}', ops: ops))
        .join(' / ');
  }
  return '$value';
}

Future<EditConflictChoice> showEditConflictDialog(
  BuildContext context,
  List<EditFieldConflict> conflicts, {
  OperationsController? ops,
}) async {
  return await showAppDialog<EditConflictChoice>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(context.t('conflict.title')),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(context.t('conflict.help')),
                  for (final conflict in conflicts) ...[
                    const SizedBox(height: 16),
                    Text(
                      context.t(
                        _fieldNames[conflict.field] ?? 'conflict.setting',
                      ),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      context.t(
                        'conflict.base',
                        args: {
                          'value': _value(
                            context,
                            conflict.base,
                            field: conflict.field,
                            ops: ops,
                          ),
                        },
                      ),
                    ),
                    Text(
                      context.t(
                        'conflict.latest',
                        args: {
                          'value': _value(
                            context,
                            conflict.latest,
                            field: conflict.field,
                            ops: ops,
                            basePhoto: conflict.base,
                          ),
                        },
                      ),
                    ),
                    Text(
                      context.t(
                        'conflict.draft',
                        args: {
                          'value': _value(
                            context,
                            conflict.draft,
                            field: conflict.field,
                            ops: ops,
                            basePhoto: conflict.base,
                          ),
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(context, EditConflictChoice.keepEditing),
              child: Text(context.t('welcome.keepEditing')),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.pop(context, EditConflictChoice.useLatest),
              child: Text(context.t('conflict.useLatest')),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.pop(context, EditConflictChoice.useDraft),
              child: Text(context.t('conflict.useDraft')),
            ),
          ],
        ),
      ) ??
      EditConflictChoice.keepEditing;
}
