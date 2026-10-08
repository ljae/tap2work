import 'work_assignment_field.dart';
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
    this.initialTimeBandId,
  });
  final OperationsController ops;
  final String? initialTemplateId, initialStepId, initialTimeBandId;
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
                row['archivedAt'] == null &&
                (widget.initialTemplateId == null ||
                    row['id'] == widget.initialTemplateId),
          )
          .toList();
  String? selectedId;
  bool saving = false,
      dirty = false,
      leaving = false,
      acknowledgeLegacy = false;
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
    if (selectedId != null &&
        widget.initialTimeBandId != null &&
        (widget.initialStepId == null ||
            (template['steps'] as List).any(
              (s) => s['id'] == widget.initialStepId,
            ))) {
      dirty = true;
      final target = settings;
      final old = target['assignment'] as Json? ?? {};
      final band = assignmentBands(
        widget.ops,
      ).where((b) => b['id'] == widget.initialTimeBandId).firstOrNull;
      final availableParts = storeParts(widget.ops)
          .where(
            (p) =>
                p['hidden'] != true &&
                ((band?['headcounts'] as Map?)?[p['id']] ?? 1) > 0,
          )
          .toList();
      final partId = availableParts.any((p) => p['id'] == old['partId'])
          ? old['partId']
          : availableParts.any((p) => p['id'] == template['partId'])
          ? template['partId']
          : availableParts.firstOrNull?['id'];
      target['assignment'] = {
        ...old,
        'mode': 'scheduled',
        'timeBandIds': {
          if (partId == old['partId'])
            ...List<String>.from(old['timeBandIds'] ?? []),
          widget.initialTimeBandId!,
        }.toList(),
        'partId': partId,
      };
    }
  }

  Json get template => templates.firstWhere((row) => row['id'] == selectedId);
  Json get settings {
    final value =
        template.putIfAbsent('settings', () => <String, dynamic>{}) as Json;
    value.putIfAbsent('type', () => 'general');
    value.putIfAbsent('enabled', () => true);
    value.putIfAbsent(
      'recurrence',
      () => <String, dynamic>{'mode': 'daily', 'weekdays': <int>[]},
    );
    value.putIfAbsent('allowBulkComplete', () => true);
    value.putIfAbsent('enforceSequence', () => false);
    return value;
  }

  Json get completionPolicy =>
      settings.putIfAbsent(
            'completionPolicy',
            () => <String, dynamic>{'kind': 'check', 'quantitySpec': null},
          )
          as Json;
  void update(VoidCallback action) => setState(() {
    action();
    dirty = true;
    error = null;
  });
  Future<void> close() async {
    if (saving) return;
    if (dirty) {
      final discard = await showAppDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text('변경을 버릴까요?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('계속 수정'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(c, true),
              child: const Text('변경 버리기'),
            ),
          ],
        ),
      );
      if (discard != true || !mounted) return;
    }
    setState(() => leaving = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.pop(context);
    });
  }

  Future<void> save() async {
    if (saving || openingActor != widget.ops.actorId) return;
    final task = template;
    final recurrence = settings['recurrence'] as Json;
    if (settings['usage'] != 'event' &&
        settings['usage'] != 'reference' &&
        recurrence['mode'] == 'weekly' &&
        (recurrence['weekdays'] as List? ?? []).isEmpty) {
      setState(() => error = '반복 요일을 하나 이상 선택해 주세요.');
      return;
    }
    if (invalidTargetSteps.isNotEmpty) {
      setState(() => error = '목표 수량은 숫자로 입력해 주세요.');
      return;
    }
    if (completionPolicy['kind'] == 'quantity') {
      final spec = completionPolicy['quantitySpec'] as Json?;
      final target = spec?['target'];
      if (spec == null ||
          '${spec['unit'] ?? ''}'.trim().isEmpty ||
          (target != null &&
              (target is! num || target <= 0 || target > 100000))) {
        setState(() => error = 'TAP의 수량·단위를 확인해 주세요.');
        return;
      }
    }
    if (task['policyReport']?['needsReview'] == true && !acknowledgeLegacy) {
      setState(() => error = '기존 Task 설정의 통합 내용을 확인해 주세요.');
      return;
    }
    setState(() {
      saving = true;
      error = null;
    });
    final ok = await widget.ops.act('save_tap_settings', {
      'revision': revision,
      'templateId': task['id'],
      'settings': settings,
      'assignmentScopeVersion': 2,
      'acknowledgeLegacyPolicy': acknowledgeLegacy,
      'zone': task['zone'],
    });
    if (!mounted) return;
    setState(() {
      saving = false;
      error = ok ? null : widget.ops.error ?? '저장하지 못했어요.';
    });
    if (ok) {
      setState(() => leaving = true);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.pop(context);
      });
    }
  }

  Future<void> splitLegacy() async {
    if (saving || openingActor != widget.ops.actorId) return;
    final confirmed = await showAppDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Task별 별도 TAP으로 분리할까요?'),
        content: const Text(
          '기존 Task 설정을 각 TAP으로 옮겨 다음 영업일부터 사용해요. 오늘 업무와 기존 기록은 유지해요.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('계속 수정'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('TAP으로 분리'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => saving = true);
    final ok = await widget.ops.act('split_tap_policy', {
      'revision': revision,
      'templateId': template['id'],
      'operationId': 'split-${template['id']}-$revision',
    });
    if (!mounted) return;
    setState(() {
      saving = false;
      error = ok ? null : widget.ops.error;
    });
    if (ok) {
      setState(() => leaving = true);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.pop(context);
      });
    }
  }

  Widget switchRow(String title, bool value, ValueChanged<bool> onChanged) =>
      SwitchListTile.adaptive(
        contentPadding: EdgeInsets.zero,
        title: Text(title),
        value: value,
        onChanged: onChanged,
      );

  Widget tapConstraints() {
    final step = <String, dynamic>{'id': 'tap-policy', 'title': 'TAP 완료 기준'};
    final config = completionPolicy;
    final quantity = config['kind'] == 'quantity';
    final zones = widget.ops.rows('zones');
    final place = template['zone'] as String?;
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
              initialValue: config['kind'] ?? 'check',
              decoration: const InputDecoration(labelText: '완료 방식'),
              items: const [
                DropdownMenuItem(value: 'check', child: Text('체크')),
                DropdownMenuItem(value: 'quantity', child: Text('실제 수량 입력')),
              ],
              onChanged: (v) => update(() {
                config['kind'] = v;
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
                onChanged: (v) => update(() => spec['unit'] = v.trim()),
              ),
              TextFormField(
                key: ValueKey('target-${step['id']}'),
                initialValue: spec['target']?.toString() ?? '',
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(labelText: '목표 수량 · 선택'),
                onChanged: (v) => update(() {
                  final value = v.trim();
                  spec['target'] = value.isEmpty ? null : num.tryParse(value);
                  final id = '${step['id']}';
                  if (value.isNotEmpty && spec['target'] == null) {
                    invalidTargetSteps.add(id);
                  } else {
                    invalidTargetSteps.remove(id);
                  }
                }),
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
              initialValue: zones.any((row) => row['id'] == place)
                  ? place
                  : null,
              decoration: const InputDecoration(labelText: '장소'),
              items: [
                const DropdownMenuItem<String>(
                  value: null,
                  child: Text('장소 미설정'),
                ),
                for (final zone in zones)
                  DropdownMenuItem(
                    value: '${zone['id']}',
                    child: Text('${zone['name']}'),
                  ),
              ],
              onChanged: (v) => update(() => template['zone'] = v),
            ),
            const SizedBox(height: 10),
            AppPillField<int>(
              initialValue: settings['estimatedMinutes'],
              decoration: const InputDecoration(labelText: '예상 소요 시간'),
              items: [
                if (settings['estimatedMinutes'] != null &&
                    ![
                      1,
                      2,
                      3,
                      5,
                      8,
                      10,
                      15,
                      20,
                      30,
                      45,
                      60,
                      90,
                      120,
                    ].contains(settings['estimatedMinutes']))
                  DropdownMenuItem<int>(
                    value: settings['estimatedMinutes'] as int,
                    child: Text('${settings['estimatedMinutes']}분'),
                  ),
                const DropdownMenuItem<int>(value: null, child: Text('미설정')),
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
              onChanged: (v) => update(() => settings['estimatedMinutes'] = v),
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
                ? '업무 화면의 TAP 추가로 만들어 주세요.'
                : '연결된 TAP 또는 Task를 찾지 못했어요. 목록을 새로고침해 주세요.',
          ),
        ),
      );
    }
    final task = template;
    final config = settings;
    final recurrence = config['recurrence'] as Json;
    final weekdays = List<int>.from(recurrence['weekdays'] ?? []);
    return PopScope(
      canPop: leaving,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) close();
      },
      child: AppEditorScaffold(
        onClose: close,
        title: 'TAP 설정',
        footer: AppSheetFooter(
          children: [
            if (error != null) Information('$error\n입력 중인 내용은 남아 있어요.'),
            FilledButton(
              onPressed:
                  widget.ops.canEditTasks && !widget.ops.readOnly && !saving
                  ? save
                  : null,
              child: Text(saving ? '저장 중…' : '설정 저장'),
            ),
          ],
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: appEditorWidth),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                const Information(
                  '담당 변경은 오늘 아직 시작하지 않은 업무에도 적용돼요. 진행 중·완료 업무는 유지하고, 나머지 규칙은 다음 업무부터 적용해요.',
                ),
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
                ...[
                  const SizedBox(height: 16),
                  if (config['usage'] != 'reference')
                    WorkAssignmentField(
                      ops: widget.ops,
                      value: config['assignment'] as Json?,
                      onChanged: (v) => update(() => config['assignment'] = v),
                    ),
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
                  AppPillField<String>(
                    key: ValueKey('usage-$selectedId'),
                    initialValue:
                        config['usage'] ??
                        (config['enabled'] == true
                            ? 'routine'
                            : 'unclassified'),
                    decoration: const InputDecoration(labelText: '매뉴얼 사용 방법'),
                    items: const [
                      DropdownMenuItem(
                        value: 'unclassified',
                        child: Text('아직 선택하지 않음'),
                      ),
                      DropdownMenuItem(
                        value: 'reference',
                        child: Text('필요할 때 보기'),
                      ),
                      DropdownMenuItem(
                        value: 'routine',
                        child: Text('정기적으로 확인'),
                      ),
                      DropdownMenuItem(value: 'event', child: Text('작업할 때 확인')),
                    ],
                    onChanged: (v) => update(() {
                      if (v == 'unclassified') {
                        config['usage'] = null;
                        config['enabled'] = false;
                      } else {
                        config['usage'] = v;
                        config['enabled'] = v != 'reference';
                      }
                      if (v == 'event') {
                        config['eventKind'] ??=
                            task['knowledge']?['eventKind'] ?? 'batch';
                        config['allowBulkComplete'] = false;
                        config['completionPolicy'] = {
                          'kind': 'check',
                          'quantitySpec': null,
                        };
                        if (config['assignment']?['mode'] == 'scheduled') {
                          config['assignment'] = {'mode': 'anyone'};
                        }
                      }
                    }),
                  ),
                  if (task['workStatus']?['label'] != null)
                    Information('현재 저장 상태 · ${task['workStatus']['label']}'),
                  if (config['usage'] == 'event') ...[
                    const Information(
                      '제품·배치별로 작업을 시작하면 업무가 만들어져요. 시간대 배정 대신 담당 크루 또는 직접 맡기를 선택하세요.',
                    ),
                    AppPillField<String>(
                      initialValue: config['eventKind'] ?? 'batch',
                      decoration: const InputDecoration(labelText: '작업 발생 시점'),
                      items: const [
                        DropdownMenuItem(
                          value: 'batch',
                          child: Text('제조·준비 배치'),
                        ),
                        DropdownMenuItem(value: 'opened', child: Text('제품 개봉')),
                        DropdownMenuItem(value: 'thawed', child: Text('해동')),
                        DropdownMenuItem(value: 'received', child: Text('입고')),
                      ],
                      onChanged: (v) => update(() => config['eventKind'] = v),
                    ),
                  ],
                  if (task['knowledge']?['safetyReviewRequired'] == true)
                    TextFormField(
                      key: ValueKey('standard-$selectedId'),
                      initialValue: config['operatingStandard'] ?? '',
                      maxLength: 1000,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: '제품·공정별 매장 기준',
                        hintText: '근거, 제품 상태, 시간·온도, 보관 조건과 이상 시 조치',
                      ),
                      onChanged: (v) =>
                          update(() => config['operatingStandard'] = v),
                    ),
                  if (config['usage'] != 'reference')
                    ExpansionTile(
                      title: const Text('연결할 참고 매뉴얼'),
                      children: [
                        for (final other
                            in widget.ops
                                .rows('taskTemplates')
                                .where(
                                  (t) =>
                                      t['id'] != selectedId &&
                                      t['archivedAt'] == null,
                                ))
                          CheckboxListTile(
                            title: Text('${other['title']}'),
                            value: (config['knowledgeIds'] as List? ?? [])
                                .contains(other['id']),
                            onChanged: (v) => update(() {
                              final ids = List<String>.from(
                                config['knowledgeIds'] ?? [],
                              );
                              if (v == true) {
                                ids.add(other['id']);
                              } else {
                                ids.remove(other['id']);
                              }
                              config['knowledgeIds'] = ids;
                            }),
                          ),
                      ],
                    ),
                  if (config['usage'] != 'event' &&
                      config['usage'] != 'reference') ...[
                    const Text(
                      '반복',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    AppSegmented<String>(
                      segments: const [
                        ButtonSegment(value: 'daily', label: Text('매일')),
                        ButtonSegment(value: 'weekly', label: Text('요일 선택')),
                      ],
                      selected: {recurrence['mode'] ?? 'daily'},
                      onSelectionChanged: (v) => update(() {
                        recurrence['mode'] = v.first;
                        recurrence['weekdays'] = v.first == 'daily'
                            ? <int>[]
                            : [1];
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
                  ],
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
                if (task['policyReport']?['needsReview'] == true) ...[
                  Information(
                    (task['policyReport']['issues'] as List)
                        .map((row) => '${row['title']} · ${row['kind']}')
                        .join('\n'),
                  ),
                  TextButton(
                    onPressed:
                        saving ||
                            widget.ops.readOnly ||
                            !widget.ops.canEditTasks
                        ? null
                        : splitLegacy,
                    child: const Text('Task별 별도 TAP으로 분리'),
                  ),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('기존 Task 설정을 TAP 기준으로 통합'),
                    subtitle: const Text('기존 설정은 복구 이력에 보관하고 진행·완료 업무는 유지해요.'),
                    value: acknowledgeLegacy,
                    onChanged: (value) =>
                        update(() => acknowledgeLegacy = value == true),
                  ),
                ],
                tapConstraints(),
                const Information('모든 Task는 이 TAP의 시간대·파트와 규칙을 함께 따라요.'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
