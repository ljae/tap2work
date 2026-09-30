import 'time_wheel.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../domain/part_schedule.dart';
import '../state/operations_controller.dart';
import 'components.dart';
import 'workplace_screens.dart';

class CrewPatternScreen extends StatefulWidget {
  const CrewPatternScreen({super.key, required this.ops, required this.day});
  final OperationsController ops;
  final DateTime day;
  @override
  State<CrewPatternScreen> createState() => _CrewPatternScreenState();
}

class _CrewPatternScreenState extends State<CrewPatternScreen> {
  OperationsController get ops => widget.ops;
  late final String actor;
  late int revision;
  String? crewId;
  int cycle = 1, week = 0;
  late DateTime anchor = widget.day.subtract(
    Duration(days: widget.day.weekday - 1),
  );
  late DateTime from = widget.day;
  late DateTime until = from.add(const Duration(days: 27));
  List<Json> entries = [];
  bool dirty = false, saving = false;
  String? error;
  bool get editable =>
      ops.isLeader &&
      ops.data?['canEditSchedule'] != false &&
      !ops.readOnly &&
      !saving &&
      !ops.busy &&
      ops.actorId == actor;
  List<Json> get people =>
      ops.rows('tappers').where((p) => p['active'] != false).toList();
  @override
  void initState() {
    super.initState();
    actor = ops.actorId;
    revision = ops.data?['revision'] ?? 0;
    final today = DateTime.tryParse(ops.data?['day'] ?? '') ?? DateTime.now();
    if (from.isBefore(today)) {
      from = today;
      until = from.add(const Duration(days: 27));
    }
    if (people.isNotEmpty) load(people.first['id']);
  }

  void load(String id) {
    crewId = id;
    final pattern = ops
        .rows('crewPatterns')
        .where((p) => p['tapperId'] == id)
        .firstOrNull;
    entries = (jsonDecode(jsonEncode(pattern?['entries'] ?? [])) as List)
        .cast<Json>();
    cycle = pattern?['cycleWeeks'] ?? 1;
    week = 0;
    anchor =
        DateTime.tryParse(pattern?['anchor'] ?? '') ??
        widget.day.subtract(Duration(days: widget.day.weekday - 1));
    dirty = false;
    error = null;
  }

  Future<void> close() async {
    if (dirty) {
      final discard = await showAppDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text('변경을 버릴까요?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('계속 편집'),
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
    if (mounted) {
      setState(() => dirty = false);
      Navigator.pop(context);
    }
  }

  Future<void> date(String target) async {
    final initial = target == 'anchor'
        ? anchor
        : target == 'from'
        ? from
        : until;
    final chosen = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (chosen == null || !mounted) return;
    setState(() {
      if (target == 'anchor') {
        anchor = chosen.subtract(Duration(days: chosen.weekday - 1));
        dirty = true;
      } else if (target == 'from') {
        from = chosen;
        if (until.isBefore(from)) until = from;
      } else {
        until = chosen;
      }
    });
  }

  Future<void> add(int weekday, [Json? existing]) async {
    final person = people.where((p) => p['id'] == crewId).first;
    final ids = person['workProfile']?['partIds'] as List? ?? [];
    final parts = storeParts(ops)
        .where(
          (p) => p['hidden'] != true && (ids.isEmpty || ids.contains(p['id'])),
        )
        .toList();
    if (parts.isEmpty) {
      setState(() => error = '배정 가능한 파트를 먼저 설정해 주세요.');
      return;
    }
    var part = existing?['partId'] as String? ?? parts.first['id'] as String;
    if (!parts.any((p) => p['id'] == part)) part = parts.first['id'];
    final bands =
        ((ops.data?['workplace']?['days']?['$weekday'] as List?) ?? [])
            .cast<Json>()
            .where((b) => b['id'] is String)
            .toList();
    String bandId = existing?['timeBandId'] as String? ?? '';
    if (!bands.any((b) => b['id'] == bandId)) bandId = '';
    var start = existing?['start'] as String? ?? '09:00',
        end = existing?['end'] as String? ?? '18:00';
    final result = await showAppFormSheet<Json>(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (c, update) => AppSheetPanel(
          title: Text(
            '${const ['월', '화', '수', '목', '금', '토', '일'][weekday - 1]}요일 배정',
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppPicker<String>(
                  label: '파트',
                  value: part,
                  items: [
                    for (final p in parts)
                      DropdownMenuItem(
                        value: p['id'] as String,
                        child: Text(p['name']),
                      ),
                  ],
                  onChanged: (v) => update(() {
                    part = v!;
                    final band = bands
                        .where((b) => b['id'] == bandId)
                        .firstOrNull;
                    if (band != null) {
                      start =
                          band['partTimes']?[part]?['start'] ?? band['start'];
                      end = band['partTimes']?[part]?['end'] ?? band['end'];
                    }
                  }),
                ),
                const SizedBox(height: 16),
                AppPicker<String>(
                  label: '영업 시간대',
                  value: bandId,
                  items: [
                    const DropdownMenuItem(value: '', child: Text('직접 시간 지정')),
                    for (final b in bands)
                      DropdownMenuItem(
                        value: b['id'] as String,
                        child: Text(
                          '${b['name']} · ${b['partTimes']?[part]?['start'] ?? b['start']}–${b['partTimes']?[part]?['end'] ?? b['end']}',
                        ),
                      ),
                  ],
                  onChanged: (v) => update(() {
                    bandId = v!;
                    final band = bands.where((b) => b['id'] == v).firstOrNull;
                    if (band != null) {
                      start =
                          band['partTimes']?[part]?['start'] ?? band['start'];
                      end = band['partTimes']?[part]?['end'] ?? band['end'];
                    }
                  }),
                ),
                const SizedBox(height: 16),
                for (final isStart in [true, false])
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: AppTimeField(
                      label: isStart ? '시작' : '종료',
                      value: isStart ? start : end,

                      onChanged: (v) =>
                          update(() => isStart ? start = v : end = v),
                    ),
                  ),
                if (end.compareTo(start) < 0)
                  const Text('종료는 다음 날이에요.', style: AppText.caption),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: start == end
                  ? null
                  : () => Navigator.pop(c, {
                      'week': week,
                      'weekday': weekday,
                      'partId': part,
                      if (bandId.isNotEmpty) 'timeBandId': bandId,
                      'start': start,
                      'end': end,
                    }),
              child: const Text('반영'),
            ),
          ],
        ),
      ),
    );
    if (result != null && mounted) {
      setState(() {
        if (existing != null) entries.remove(existing);
        entries.add(result);
        dirty = true;
      });
    }
  }

  Future<void> save() async {
    if (!editable || crewId == null) return;
    setState(() => saving = true);
    final ok = await ops.act('save_crew_pattern', {
      'revision': revision,
      'tapperId': crewId,
      'cycleWeeks': cycle,
      'anchor': rosterDate(anchor),
      'entries': entries.where((e) => e['week'] < cycle).toList(),
    });
    if (!mounted) return;
    setState(() {
      saving = false;
      error = ok ? null : ops.error;
      if (ok) {
        revision = ops.data!['revision'];
        dirty = false;
      }
    });
  }

  Future<void> apply() async {
    if (!editable || dirty || crewId == null) return;
    final pattern = ops
        .rows('crewPatterns')
        .where((p) => p['tapperId'] == crewId)
        .firstOrNull;
    if (pattern == null) {
      setState(() => error = '기본 배정을 먼저 저장해 주세요.');
      return;
    }
    final replaced = ops
        .rows('staffShifts')
        .where(
          (s) =>
              s['patternId'] == pattern['id'] &&
              '${s['base']?['date'] ?? s['date']}'.compareTo(
                    rosterDate(from),
                  ) >=
                  0 &&
              '${s['base']?['date'] ?? s['date']}'.compareTo(
                    rosterDate(until),
                  ) <=
                  0,
        )
        .length;
    final yes = await showAppDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('기본 배정을 적용할까요?'),
        content: Text(
          '${rosterDate(from)} ~ ${rosterDate(until)}\n${people.where((p) => p['id'] == crewId).first['nickname']} · 기존 반복 근무 $replaced건 중 보호되지 않은 날짜 갱신\n\n승인된 OFF·대체 배정·출퇴근·대기 신청이 있는 날짜는 유지해요. 나머지 날짜의 반복 배정과 미세조정만 초기화해요. 별도 근무는 보존해요. 시간이 겹치면 전체 적용을 멈춰요.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('적용·초기화'),
          ),
        ],
      ),
    );
    if (yes != true || !mounted || !editable) return;
    setState(() => saving = true);
    final ok = await ops.act('apply_crew_pattern', {
      'revision': revision,
      'tapperId': crewId,
      'from': rosterDate(from),
      'until': rosterDate(until),
    });
    if (!mounted) return;
    setState(() {
      saving = false;
      error = ok ? null : ops.error;
      if (ok) revision = ops.data!['revision'];
    });
    if (ok) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('선택한 기간에 배정했어요.')));
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !dirty,
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop) close();
    },
    child: AppEditorScaffold(
      title: '크루별 근무 배정',
      onClose: close,
      footer: AppSheetFooter(
        children: [
          FilledButton(
            onPressed: editable && crewId != null ? save : null,
            child: Text(saving ? '저장 중…' : '기본 배정 저장'),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              if (people.isEmpty) const Information('크루를 먼저 등록해 주세요.'),
              AppPicker<String>(
                label: '크루',
                value: crewId,
                items: [
                  for (final p in people)
                    DropdownMenuItem(
                      value: p['id'] as String,
                      child: Text(p['nickname']),
                    ),
                ],
                onChanged: (v) {
                  if (!dirty && !saving) setState(() => load(v!));
                },
              ),
              if (dirty)
                const Text('저장한 뒤 다른 크루를 선택할 수 있어요.', style: AppText.caption),
              const SizedBox(height: 24),
              AppChoiceGroup<int>(
                values: const [1, 2],
                selected: cycle,
                labelOf: (n) => n == 1 ? '매주 동일' : '2주 교대',
                onSelected: (n) => setState(() {
                  cycle = n;
                  week = 0;
                  dirty = true;
                }),
              ),
              if (cycle == 2) ...[
                TextButton(
                  onPressed: () => date('anchor'),
                  child: Text('A주 시작 월요일 · ${rosterDate(anchor)}'),
                ),
                AppChoiceGroup<int>(
                  values: const [0, 1],
                  selected: week,
                  labelOf: (n) => n == 0 ? 'A주' : 'B주',
                  onSelected: (n) => setState(() => week = n),
                ),
              ],
              const SizedBox(height: 16),
              for (var d = 1; d <= 7; d++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Surface(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${const ['월', '화', '수', '목', '금', '토', '일'][d - 1]}요일',
                              ),
                            ),
                            IconButton(
                              tooltip: '요일 배정 추가',
                              onPressed: editable ? () => add(d) : null,
                              icon: const Icon(Icons.add),
                            ),
                          ],
                        ),
                        if (!entries.any(
                          (e) => e['week'] == week && e['weekday'] == d,
                        ))
                          const Text('배정 없음', style: AppText.caption),
                        for (final e in entries.where(
                          (e) => e['week'] == week && e['weekday'] == d,
                        ))
                          Row(
                            children: [
                              Expanded(
                                child: TextButton(
                                  onPressed: editable ? () => add(d, e) : null,
                                  child: Text(
                                    '${partLabel(ops, e['partId'])} · ${e['start']}–${e['end']}',
                                  ),
                                ),
                              ),
                              IconButton(
                                tooltip: '요일 배정 삭제',
                                onPressed: editable
                                    ? () => setState(() {
                                        entries.remove(e);
                                        dirty = true;
                                      })
                                    : null,
                                icon: const Icon(Icons.delete_outline),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              const Text('근무표에 적용', style: AppText.title),
              const SizedBox(height: 8),
              const Text(
                '선택한 기간에 기본 배정을 넣어요. 승인된 OFF·대체 배정·출퇴근·대기 신청이 있는 날짜는 유지해요. 나머지 반복 근무의 날짜별 조정은 초기화돼요.',
                style: AppText.caption,
              ),
              Wrap(
                spacing: 8,
                children: [
                  TextButton(
                    onPressed: () => date('from'),
                    child: Text('시작 ${rosterDate(from)}'),
                  ),
                  TextButton(
                    onPressed: () => date('until'),
                    child: Text('종료 ${rosterDate(until)}'),
                  ),
                ],
              ),
              OutlinedButton(
                onPressed: editable && !dirty ? apply : null,
                child: const Text('적용 범위 확인'),
              ),
              if (error != null) Information('$error\n입력한 내용은 유지돼요.'),
            ],
          ),
        ),
      ),
    ),
  );
}
