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
              ((b['headcounts'] as Map?)?[current['partId']] ?? 1) > 0,
        )
        .toList();
    final ids = List<String>.from(current['timeBandIds'] ?? []);
    final crewIds = List<String>.from(current['crewIds'] ?? []);
    final modes = {
      if (inherit) 'inherit': 'TAP 따름',
      'scheduled': '시간대·파트 자동 배정',
      'crew': '특정 크루 지정',
      'anyone': '누구나 · 오늘 근무 크루',
      'legacy': '기존 파트 규칙',
    };
    void change(String key, dynamic v) => onChanged({...current, key: v});
    return LayoutBuilder(
      builder: (context, box) => AppFormSection(
        title: '업무 담당',
        children: [
          AppPillField<String>(
            key: ValueKey('assignment-mode-$inherit-$mode'),
            initialValue: mode,
            decoration: const InputDecoration(labelText: '담당 방식'),
            items: [
              for (final e in modes.entries)
                DropdownMenuItem(value: e.key, child: Text(e.value)),
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
              decoration: const InputDecoration(labelText: '담당 파트'),
              items: [
                for (final p in parts)
                  DropdownMenuItem(
                    value: p['id'] as String,
                    child: Text(p['name']),
                  ),
              ],
              onChanged: (v) => onChanged({
                ...current,
                'partId': v,
                'timeBandIds': <String>[],
              }),
            ),
            const Text('시간대 · 여러 개 선택 가능', style: AppText.caption),
            if (bands.isEmpty)
              const Information('영업시간 설정에서 시간대를 저장한 뒤 연결해 주세요.'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final b in bands)
                  FilterChip(
                    label: _AssignmentLabel(
                      box.maxWidth,
                      "${b['name']} ${b['start']}–${b['end']} · ${(b['weekdays'] as List).map((d) => ['월', '화', '수', '목', '금', '토', '일'][(d as int) - 1]).join('·')}",
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
              const Information('선택한 파트에서 사용할 수 없는 시간대가 있어요.'),
              TextButton(
                onPressed: () => change(
                  'timeBandIds',
                  ids.where((id) => bands.any((b) => b['id'] == id)).toList(),
                ),
                child: const Text('사용할 수 없는 연결 해제'),
              ),
            ],
            const Text(
              '시간대마다 공동 업무를 만들어요. 실제 근무자를 담당자로 표시하며 같은 파트의 다른 크루도 지원 완료할 수 있어요.',
              style: AppText.caption,
            ),
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
            const Text('선택한 크루가 함께 맡고 한 명이 완료하면 끝나요.', style: AppText.caption),
          ],
          if (mode == 'anyone')
            const Text(
              '그날 실제 근무가 배정된 크루의 공용 업무예요. 휴무만 있는 크루는 제외해요.',
              style: AppText.caption,
            ),
          if (mode == 'legacy')
            const Text(
              '시간대에 연결하지 않은 기존 업무예요. 기존 파트의 완료 기준을 유지해요.',
              style: AppText.caption,
            ),
          if (mode == 'inherit')
            const Text('이 Task는 TAP의 담당 방식을 따라요.', style: AppText.caption),
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
