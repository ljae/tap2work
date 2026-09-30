import 'time_wheel.dart';
import 'package:flutter/material.dart';
import '../state/operations_controller.dart';
import 'components.dart';

/// Returns a draft; the parent saves all weekdays with its opening revision.
class TimeBandEditor extends StatefulWidget {
  const TimeBandEditor({
    super.key,
    required this.parts,
    required this.openDays,
    required this.initialDays,
    this.band,
  });
  final List<Json> parts;
  final Set<int> openDays, initialDays;
  final Json? band;
  @override
  State<TimeBandEditor> createState() => _TimeBandEditorState();
}

class _TimeBandEditorState extends State<TimeBandEditor> {
  late final name = TextEditingController(text: widget.band?['name'] ?? '');
  late String start = widget.band?['start'] ?? '09:00',
      end = widget.band?['end'] ?? '10:00';
  late final days = {...widget.initialDays};
  late final selected = <String>{
    for (final p in widget.parts)
      if (widget.band != null &&
          (widget.band?['headcounts']?[p['id']] ??
                  (widget.band?['custom'] == true ? 0 : 1)) >
              0)
        p['id'],
  };
  String? error;
  bool dirty = false, leaving = false;
  @override
  void dispose() {
    name.dispose();
    super.dispose();
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
    if (!mounted) return;
    setState(() => leaving = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.pop(context);
    });
  }

  Future<void> time(bool first) async {
    final value = await showTimeWheel(
      context,
      title: first ? '시작 시간' : '종료 시간',
      value: first ? start : end,
    );
    if (value == null || !mounted) return;
    setState(() {
      if (first) {
        start = value;
      } else {
        end = value;
      }
      dirty = true;
      error = null;
    });
  }

  void apply() {
    if (name.text.trim().isEmpty ||
        name.text.trim().length > 40 ||
        selected.isEmpty ||
        days.isEmpty ||
        start == end) {
      setState(() => error = '이름, 파트, 적용 요일과 서로 다른 시작·종료 시간을 확인해 주세요.');
      return;
    }
    final counts = <String, dynamic>{
      ...?(widget.band?['headcounts'] as Map?)?.cast<String, dynamic>(),
    };
    for (final p in widget.parts) {
      counts[p['id']] = selected.contains(p['id'])
          ? ((counts[p['id']] as int? ?? 0) > 0 ? counts[p['id']] : 1)
          : 0;
    }
    final result = <String, dynamic>{
      'days': days.toList(),
      'band': {
        ...?(widget.band),
        'custom': true,
        'name': name.text.trim(),
        'start': start,
        'end': end,
        'headcounts': counts,
      },
    };
    setState(() => leaving = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.pop(context, result);
    });
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: leaving,
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop) close();
    },
    child: AppEditorScaffold(
      title: widget.band == null ? '새 시간대' : '시간대 수정',
      onClose: close,
      footer: AppSheetFooter(
        children: [
          if (error != null)
            Text(
              error!,
              style: AppText.caption.copyWith(color: AppColors.accent),
            ),
          FilledButton(
            onPressed: leaving ? null : apply,
            child: const Text('시간대 적용'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          AppFormSection(
            title: '시간대',
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final v in ['오픈', '미들', '마감'])
                    ActionChip(
                      label: Text(v),
                      onPressed: () => setState(() {
                        name.text = v;
                        dirty = true;
                      }),
                    ),
                ],
              ),
              TextField(
                controller: name,
                maxLength: 40,
                decoration: const InputDecoration(labelText: '시간대 이름'),
                onChanged: (_) => setState(() => dirty = true),
              ),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  OutlinedButton(
                    onPressed: () => time(true),
                    child: Text('시작 $start'),
                  ),
                  OutlinedButton(
                    onPressed: () => time(false),
                    child: Text('종료 $end'),
                  ),
                ],
              ),
              if (end.compareTo(start) < 0) const Text('종료는 다음 날이에요.'),
            ],
          ),
          AppFormSection(
            title: '파트',
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final p in widget.parts)
                    FilterChip(
                      label: Text(p['name']),
                      selected: selected.contains(p['id']),
                      onSelected: (v) => setState(() {
                        v ? selected.add(p['id']) : selected.remove(p['id']);
                        dirty = true;
                      }),
                    ),
                ],
              ),
              const Text('선택한 파트에 필요 인원을 추가해요. 인원수는 적용 후 조정할 수 있어요.'),
            ],
          ),
          AppFormSection(
            title: '적용 요일',
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (var d = 1; d <= 7; d++)
                    FilterChip(
                      label: Text(
                        '${['월', '화', '수', '목', '금', '토', '일'][d - 1]}${widget.openDays.contains(d) ? '' : ' · 휴무'}',
                      ),
                      selected: days.contains(d),
                      onSelected: widget.openDays.contains(d)
                          ? (v) => setState(() {
                              v ? days.add(d) : days.remove(d);
                              dirty = true;
                            })
                          : null,
                    ),
                ],
              ),
              const Text('휴무일은 영업시간 화면에서 먼저 해제해 주세요.'),
            ],
          ),
          const Text('적용 후 일주일 설정 저장을 누르면 근무표의 필요 인원에 반영돼요. 이미 배정한 근무는 유지돼요.'),
        ],
      ),
    ),
  );
}
