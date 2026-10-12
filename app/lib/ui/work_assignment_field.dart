import '../l10n/entity_name_scope.dart';
import '../l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import '../state/operations_controller.dart';
import 'components.dart';

List<Json> assignmentBands(OperationsController ops) {
  final grouped = <String, Json>{};
  final days = ops.data?['workplace']?['days'] as Map? ?? {};
  for (final entry in days.entries) {
    for (final band in (entry.value as List? ?? []).whereType<Map>()) {
      final id = band['id'];
      if (id is! String) continue;
      final row = grouped.putIfAbsent(
        id,
        () => <String, dynamic>{
          ...band.cast<String, dynamic>(),
          'weekdays': <int>[],
        },
      );
      (row['weekdays'] as List).add(int.parse('${entry.key}'));
    }
  }
  return grouped.values.toList();
}

/// Uses the same settings.assignment value regardless of the entry point.
class WorkAssignmentField extends StatelessWidget {
  const WorkAssignmentField({
    super.key,
    required this.ops,
    required this.value,
    required this.onChanged,
    this.inherit = false,
  });
  final OperationsController ops;
  final Json? value;
  final ValueChanged<Json> onChanged;
  final bool inherit;
  @override
  Widget build(BuildContext context) {
    final current =
        value ?? <String, dynamic>{'mode': inherit ? 'inherit' : 'legacy'};
    final mode = current['mode'] ?? (inherit ? 'inherit' : 'legacy');
    final parts = (ops.data?['workplace']?['parts'] as List? ?? [])
        .whereType<Json>()
        .where((p) => p['hidden'] != true)
        .toList();
    final bands = assignmentBands(ops)
        .where(
          (b) =>
              current['partId'] == null ||
              ((b['headcounts'] as Map?)?[current['partId']] ??
                      (b['custom'] == true ? 0 : 1)) >
                  0,
        )
        .toList();
    final ids = List<String>.from(current['timeBandIds'] ?? []);
    final crewIds = List<String>.from(current['crewIds'] ?? []);
    final modes = {
      if (inherit) 'inherit': 'TAP 따름',
      'scheduled': '시간대·파트 자동 배정',
      'crew': '특정 크루 지정',
      'anyone': '누구나 · 오늘 근무 크루',
      if (mode == 'legacy') 'legacy': '기존 파트 규칙',
    };
    void change(String key, dynamic v) => onChanged({...current, key: v});
    return LayoutBuilder(
      builder: (context, box) => AppFormSection(
        title: context.t('ui.audit1045'),
        children: [
          AppPillField<String>(
            key: ValueKey('assignment-mode-$inherit-$mode'),
            initialValue: mode,
            decoration: InputDecoration(labelText: context.t('ui.audit453')),
            items: [
              for (final e in modes.entries)
                DropdownMenuItem(value: e.key, child: Text(context.t(e.value))),
            ],
            onChanged: (v) {
              if (v != null) {
                onChanged({
                  'mode': v,
                  'partId': parts.firstOrNull?['id'],
                  'timeBandIds': <String>[],
                  'crewIds': <String>[],
                });
              }
            },
          ),
          if (mode == 'scheduled') ...[
            AppPillField<String>(
              key: ValueKey('assignment-part-${current['partId']}'),
              initialValue: parts.any((p) => p['id'] == current['partId'])
                  ? current['partId']
                  : null,
              decoration: InputDecoration(labelText: context.t('ui.audit39')),
              items: [
                for (final p in parts)
                  DropdownMenuItem(
                    value: p['id'] as String,
                    child: Text(
                      entityDisplayName(
                        context,
                        ops,
                        'part',
                        p['id'],
                        p['name'],
                      ),
                    ),
                  ),
              ],
              onChanged: (v) => onChanged({
                ...current,
                'partId': v,
                'timeBandIds': <String>[],
              }),
            ),
            Text(context.t('ui.audit454'), style: AppText.caption),
            if (bands.isEmpty) Information(context.t('ui.audit455')),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final b in bands)
                  FilterChip(
                    label: _AssignmentLabel(
                      box.maxWidth,
                      context.t(
                        'ui.audit2131',
                        args: {
                          'p0': b['name'],
                          'p1':
                              b['partTimes']?[current['partId']]?['start'] ??
                              b['start'],
                          'p2':
                              b['partTimes']?[current['partId']]?['end'] ??
                              b['end'],
                          'p3': (b['weekdays'] as List)
                              .map(
                                (d) => [
                                  '월',
                                  '화',
                                  '수',
                                  '목',
                                  '금',
                                  '토',
                                  '일',
                                ][(d as int) - 1],
                              )
                              .join('·'),
                        },
                      ),
                    ),
                    selected: ids.contains(b['id']),
                    onSelected: (selected) {
                      final next = [...ids];
                      selected ? next.add(b['id']) : next.remove(b['id']);
                      change('timeBandIds', next);
                    },
                  ),
              ],
            ),
            if (ids.any((id) => !bands.any((b) => b['id'] == id))) ...[
              Information(context.t('ui.audit456')),
              TextButton(
                onPressed: () => change(
                  'timeBandIds',
                  ids.where((id) => bands.any((b) => b['id'] == id)).toList(),
                ),
                child: Text(context.t('ui.audit457')),
              ),
            ],
            Text(context.t('ui.audit458'), style: AppText.caption),
          ],
          if (mode == 'crew') ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final person
                    in ops.rows('tappers').where((p) => p['active'] == true))
                  FilterChip(
                    label: _AssignmentLabel(
                      box.maxWidth,
                      '${person['nickname']}',
                    ),
                    selected: crewIds.contains(person['id']),
                    onSelected: (selected) {
                      final next = [...crewIds];
                      selected
                          ? next.add(person['id'])
                          : next.remove(person['id']);
                      change('crewIds', next);
                    },
                  ),
              ],
            ),
            Text(context.t('ui.audit459'), style: AppText.caption),
          ],
          if (mode == 'anyone')
            Text(context.t('ui.audit460'), style: AppText.caption),
          if (mode == 'legacy')
            Text(context.t('ui.audit461'), style: AppText.caption),
          if (mode == 'inherit')
            Text(context.t('ui.audit462'), style: AppText.caption),
        ],
      ),
    );
  }
}

class _AssignmentLabel extends StatelessWidget {
  const _AssignmentLabel(this.width, this.text);
  final double width;
  final String text;
  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: BoxConstraints(maxWidth: (width - 100).clamp(48, 540)),
    child: DefaultTextStyle(
      style: DefaultTextStyle.of(context).style,
      softWrap: true,
      overflow: TextOverflow.visible,
      child: Text(text),
    ),
  );
}
