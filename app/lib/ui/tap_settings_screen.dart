import 'workplace_screens.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../state/operations_controller.dart';
import 'components.dart';

/// Edits template settings only. Existing task snapshots retain their own rules.
class TapSettingsScreen extends StatefulWidget {
  const TapSettingsScreen({
    super.key,
    required this.ops,
    this.initialTemplateId,
    this.initialStepId,
  });
  final OperationsController ops;
  final String? initialTemplateId, initialStepId;
  @override
  State<TapSettingsScreen> createState() => _TapSettingsScreenState();
}

class _TapSettingsScreenState extends State<TapSettingsScreen> {
  late final int revision;
  late final String openingActor;
  late final List<Json> templates =
      (jsonDecode(jsonEncode(widget.ops.rows('taskTemplates'))) as List)
          .cast<Json>()
          .where(
            (row) =>
                widget.initialTemplateId == null ||
                row['id'] == widget.initialTemplateId,
          )
          .toList();
  String? selectedId;
  bool saving = false;
  String? error;
  final Set<String> invalidTargetSteps = {};
  static const types = {
    'general': '일반',
    'opening': '오픈',
    'closing': '마감',
    'cleaning': '청소·정비',
    'order': '주문·포장',
    'preparation': '준비·수량',
    'training': '교육',
  };
  static const days = ['월', '화', '수', '목', '금', '토', '일'];
  @override
  void initState() {
    super.initState();
    revision = widget.ops.data?['revision'] as int? ?? 0;
    openingActor = widget.ops.actorId;
    selectedId = templates.any((row) => row['id'] == widget.initialTemplateId)
        ? widget.initialTemplateId
        : templates.firstOrNull?['id'];
  }

  Json get template => templates.firstWhere((row) => row['id'] == selectedId);
  Json get settings =>
      template.putIfAbsent(
            'settings',
            () => <String, dynamic>{
              'type': 'general',
              'enabled': true,
              'recurrence': {'mode': 'daily', 'weekdays': <int>[]},
              'allowBulkComplete': true,
              'enforceSequence': false,
            },
          )
          as Json;
  Json stepSettings(Json step) =>
      step.putIfAbsent(
            'settings',
            () => <String, dynamic>{
              'roleOverride': null,
              'zoneOverride': null,
              'completionKind': 'check',
              'quantitySpec': null,
              'estimatedMinutes': null,
            },
          )
          as Json;
  void update(VoidCallback action) => setState(() {
    action();
    error = null;
  });
  Future<void> save() async {
    if (saving || openingActor != widget.ops.actorId) return;
    final task = template;
    final steps = (task['steps'] as List).cast<Json>();
    final recurrence = settings['recurrence'] as Json;
    if (recurrence['mode'] == 'weekly' &&
        (recurrence['weekdays'] as List? ?? []).isEmpty) {
      setState(() => error = '반복 요일을 하나 이상 선택해 주세요.');
      return;
    }
    if (invalidTargetSteps.isNotEmpty) {
      setState(() => error = '목표 수량은 숫자로 입력해 주세요.');
      return;
    }
    for (final step in steps) {
      final config = stepSettings(step);
      if (config['completionKind'] == 'quantity') {
        final spec = config['quantitySpec'] as Json?;
        final target = spec?['target'];
        if (spec == null ||
            '${spec['unit'] ?? ''}'.trim().isEmpty ||
            (target != null &&
                (target is! num || target <= 0 || target > 100000))) {
          setState(() => error = '${step['title']}의 수량·단위를 확인해 주세요.');
          return;
        }
      }
    }
    setState(() {
      saving = true;
      error = null;
    });
    final ok = await widget.ops.act('save_tap_settings', {
      'revision': revision,
      'templateId': task['id'],
      'settings': settings,
      'steps': [
        for (final step in steps)
          {'id': step['id'], 'settings': stepSettings(step)},
      ],
    });
    if (!mounted) return;
    setState(() {
      saving = false;
      error = ok ? null : widget.ops.error ?? '저장하지 못했어요.';
    });
    if (ok) Navigator.pop(context);
  }

  Widget switchRow(String title, bool value, ValueChanged<bool> onChanged) =>
      SwitchListTile.adaptive(
        contentPadding: EdgeInsets.zero,
        title: Text(title),
        value: value,
        onChanged: onChanged,
      );

  Widget stepCard(Json step) {
    final config = stepSettings(step);
    final quantity = config['completionKind'] == 'quantity';
    final zones = widget.ops.rows('zones');
    final role = config['partOverride'] as String?;
    final place = config['zoneOverride'] as String?;
    final spec =
        (config['quantitySpec'] as Json?) ??
        <String, dynamic>{'unit': '', 'target': null, 'decimalPlaces': 0};
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Surface(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${step['title']}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            AppPillField<String>(
              key: ValueKey('kind-${step['id']}'),
              initialValue: config['completionKind'] ?? 'check',
              decoration: const InputDecoration(labelText: '완료 방식'),
              items: const [
                DropdownMenuItem(value: 'check', child: Text('체크')),
                DropdownMenuItem(value: 'quantity', child: Text('실제 수량 입력')),
              ],
              onChanged: (v) => update(() {
                config['completionKind'] = v;
                config['quantitySpec'] = v == 'quantity' ? spec : null;
                if (v != 'quantity') invalidTargetSteps.remove('${step['id']}');
              }),
            ),
            if (quantity) ...[
              const SizedBox(height: 10),
              TextFormField(
                key: ValueKey('unit-${step['id']}'),
                initialValue: '${spec['unit'] ?? ''}',
                decoration: const InputDecoration(labelText: '단위 · 필수'),
                onChanged: (v) => spec['unit'] = v.trim(),
              ),
              TextFormField(
                key: ValueKey('target-${step['id']}'),
                initialValue: spec['target']?.toString() ?? '',
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(labelText: '목표 수량 · 선택'),
                onChanged: (v) {
                  final value = v.trim();
                  spec['target'] = value.isEmpty ? null : num.tryParse(value);
                  final id = '${step['id']}';
                  if (value.isNotEmpty && spec['target'] == null) {
                    invalidTargetSteps.add(id);
                  } else {
                    invalidTargetSteps.remove(id);
                  }
                },
              ),
              AppPillField<int>(
                initialValue: spec['decimalPlaces'] ?? 0,
                decoration: const InputDecoration(labelText: '소수 자리'),
                items: const [
                  DropdownMenuItem(value: 0, child: Text('정수')),
                  DropdownMenuItem(value: 1, child: Text('소수 1자리')),
                  DropdownMenuItem(value: 2, child: Text('소수 2자리')),
                ],
                onChanged: (v) => update(() => spec['decimalPlaces'] = v),
              ),
            ],
            const SizedBox(height: 10),
            AppPillField<String>(
              initialValue: role,
              decoration: const InputDecoration(labelText: '담당 파트'),
              items: [
                const DropdownMenuItem<String>(
                  value: null,
                  child: Text('TAP 설정 따름'),
                ),
                for (final part in storeParts(
                  widget.ops,
                ).where((p) => p['hidden'] != true))
                  DropdownMenuItem(
                    value: part['id'] as String,
                    child: Text(part['name']),
                  ),
              ],
              onChanged: (v) => update(() {
                config['partOverride'] = v;
                config['roleOverride'] = null;
              }),
            ),
            const SizedBox(height: 10),
            AppPillField<String>(
              initialValue: zones.any((row) => row['id'] == place)
                  ? place
                  : null,
              decoration: const InputDecoration(labelText: '장소'),
              items: [
                const DropdownMenuItem<String>(
                  value: null,
                  child: Text('TAP 설정 따름'),
                ),
                for (final zone in zones)
                  DropdownMenuItem(
                    value: '${zone['id']}',
                    child: Text('${zone['name']}'),
                  ),
              ],
              onChanged: (v) => update(() => config['zoneOverride'] = v),
            ),
            const SizedBox(height: 10),
            AppPillField<int>(
              initialValue: config['estimatedMinutes'],
              decoration: const InputDecoration(labelText: '예상 소요 시간'),
              items: const [
                DropdownMenuItem<int>(value: null, child: Text('미설정')),
                DropdownMenuItem(value: 1, child: Text('1분')),
                DropdownMenuItem(value: 2, child: Text('2분')),
                DropdownMenuItem(value: 3, child: Text('3분')),
                DropdownMenuItem(value: 5, child: Text('5분')),
                DropdownMenuItem(value: 8, child: Text('8분')),
                DropdownMenuItem(value: 10, child: Text('10분')),
                DropdownMenuItem(value: 15, child: Text('15분')),
                DropdownMenuItem(value: 20, child: Text('20분')),
                DropdownMenuItem(value: 30, child: Text('30분')),
                DropdownMenuItem(value: 45, child: Text('45분')),
                DropdownMenuItem(value: 60, child: Text('60분')),
                DropdownMenuItem(value: 90, child: Text('90분')),
                DropdownMenuItem(value: 120, child: Text('120분')),
              ],
              onChanged: (v) => update(() => config['estimatedMinutes'] = v),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (templates.isEmpty ||
        (widget.initialStepId != null &&
            !(template['steps'] as List).any(
              (step) => step['id'] == widget.initialStepId,
            ))) {
      return AppEditorScaffold(
        title: 'TAP 설정',
        body: Center(
          child: Information(
            widget.initialTemplateId == null
                ? '먼저 보드 편집에서 TAP을 만들어 주세요.'
                : '연결된 TAP 또는 Task를 찾지 못했어요. 목록을 새로고침해 주세요.',
          ),
        ),
      );
    }
    final task = template;
    final config = settings;
    final recurrence = config['recurrence'] as Json;
    final weekdays = List<int>.from(recurrence['weekdays'] ?? []);
    return AppEditorScaffold(
      title: widget.initialStepId == null ? 'TAP 설정' : 'Task 설정',
      footer: AppSheetFooter(
        children: [
          FilledButton(
            onPressed:
                widget.ops.canEditTasks && !widget.ops.readOnly && !saving
                ? save
                : null,
            child: Text(saving ? '저장 중…' : '다음 업무부터 적용'),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const Information('변경한 설정은 다음에 생성되는 업무부터 적용돼요. 오늘의 완료 기록은 유지돼요.'),
              if (widget.ops.readOnly)
                const Information('공개 미리보기에서는 설정을 저장하지 않아요.'),
              const SizedBox(height: 14),
              if (widget.initialTemplateId != null)
                Text('${task['title']}', style: AppText.title)
              else
                AppPillField<String>(
                  key: const ValueKey('tap-settings-template'),
                  initialValue: selectedId,
                  decoration: const InputDecoration(labelText: 'TAP 선택'),
                  items: [
                    for (final row in templates)
                      DropdownMenuItem(
                        value: '${row['id']}',
                        child: Text(
                          '${row['title']}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: (v) => setState(() {
                    selectedId = v;
                    invalidTargetSteps.clear();
                    error = null;
                  }),
                ),
              if (widget.initialStepId == null) ...[
                const SizedBox(height: 16),
                AppPillField<String>(
                  key: ValueKey('type-$selectedId'),
                  initialValue: config['type'],
                  decoration: const InputDecoration(labelText: '업무 유형'),
                  items: [
                    for (final entry in types.entries)
                      DropdownMenuItem(
                        value: entry.key,
                        child: Text(entry.value),
                      ),
                  ],
                  onChanged: (v) => update(() => config['type'] = v),
                ),
                switchRow(
                  '다음 업무에도 사용',
                  config['enabled'] == true,
                  (v) => update(() => config['enabled'] = v),
                ),
                const Text('반복', style: TextStyle(fontWeight: FontWeight.w700)),
                AppSegmented<String>(
                  segments: const [
                    ButtonSegment(value: 'daily', label: Text('매일')),
                    ButtonSegment(value: 'weekly', label: Text('요일 선택')),
                  ],
                  selected: {recurrence['mode'] ?? 'daily'},
                  onSelectionChanged: (v) => update(() {
                    recurrence['mode'] = v.first;
                    recurrence['weekdays'] = v.first == 'daily' ? <int>[] : [1];
                  }),
                ),
                if (recurrence['mode'] == 'weekly')
                  Wrap(
                    spacing: 6,
                    children: [
                      for (var d = 1; d <= 7; d++)
                        FilterChip(
                          chipAnimationStyle: AppMotion.chipStyle(context),
                          label: Text(days[d - 1]),
                          selected: weekdays.contains(d),
                          onSelected: (_) => update(() {
                            final selected = List<int>.from(
                              recurrence['weekdays'],
                            );
                            selected.contains(d)
                                ? selected.remove(d)
                                : selected.add(d);
                            recurrence['weekdays'] = selected;
                          }),
                        ),
                    ],
                  ),
                switchRow(
                  'TAP에서 한 번에 완료 허용',
                  config['allowBulkComplete'] == true,
                  (v) => update(() => config['allowBulkComplete'] = v),
                ),
                switchRow(
                  'Task 순서대로 수행',
                  config['enforceSequence'] == true,
                  (v) => update(() => config['enforceSequence'] = v),
                ),
                const SizedBox(height: 18),
                Text(
                  'Task · ${(task['steps'] as List).length}개',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
              const SizedBox(height: 10),
              for (final step in (task['steps'] as List).cast<Json>().where(
                (step) =>
                    widget.initialStepId == null ||
                    step['id'] == widget.initialStepId,
              ))
                KeyedSubtree(
                  key: ValueKey('settings-$selectedId-${step['id']}'),
                  child: stepCard(step),
                ),
              if (error != null) Information('$error\n입력 중인 내용은 남아 있어요.'),
              if (widget.ops.data?['revision'] != revision)
                const Information('다른 변경이 저장됐어요. 최신 업무를 확인한 뒤 다시 열어 주세요.'),
              const SizedBox(height: 14),
            ],
          ),
        ),
      ),
    );
  }
}
