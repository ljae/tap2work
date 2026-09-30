import 'time_wheel.dart';
import 'package:flutter/material.dart';
import '../state/operations_controller.dart';
import 'components.dart';
import 'shift_replacement_sheet.dart';

Future<void> requestShiftChange(
  BuildContext context,
  OperationsController ops,
  String shiftId,
) async {
  final shift = ops
      .rows('staffShifts')
      .where((s) => s['id'] == shiftId)
      .firstOrNull;
  if (shift == null) return;
  final revision = ops.data?['revision'], actor = ops.actorId;
  await showAppFormSheet<Json>(
    context: context,
    builder: (_) =>
        _RequestSheet(shift: shift, ops: ops, revision: revision, actor: actor),
  );
}

class _RequestSheet extends StatefulWidget {
  const _RequestSheet({
    required this.shift,
    required this.ops,
    required this.revision,
    required this.actor,
  });
  final Json shift;
  final OperationsController ops;
  final dynamic revision;
  final String actor;
  @override
  State<_RequestSheet> createState() => _RequestSheetState();
}

class _RequestSheetState extends State<_RequestSheet> {
  String kind = 'leave';
  late String start = widget.shift['start'], end = widget.shift['end'];
  final reason = TextEditingController();
  bool saving = false;
  String? error;
  Future<void> submit() async {
    if (saving || widget.ops.actorId != widget.actor || widget.ops.readOnly) {
      return;
    }
    setState(() => saving = true);
    final ok = await widget.ops.act('request_shift_change', {
      'revision': widget.revision,
      'shiftId': widget.shift['id'],
      'kind': kind,
      'start': start,
      'end': end,
      'reason': reason.text,
    });
    if (!mounted) return;
    setState(() {
      saving = false;
      error = ok ? null : widget.ops.error;
    });
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('신청했어요. 승인 전에는 원래 근무가 유지돼요.')),
      );
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AppSheetPanel(
    title: const Text('내 근무 변경 신청'),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${widget.shift['date']} · ${widget.shift['start']}–${widget.shift['end']}',
          ),
          const SizedBox(height: 16),
          AppChoiceGroup<String>(
            values: const ['leave', 'partial_off', 'shorten'],
            selected: kind,
            labelOf: (v) => v == 'leave'
                ? '휴무 신청'
                : v == 'partial_off'
                ? '일부 시간 OFF'
                : '단축 근무',
            onSelected: (v) => setState(() => kind = v),
          ),
          if (kind != 'leave') ...[
            const SizedBox(height: 16),
            for (final first in [true, false])
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: AppTimeField(
                  label: kind == 'partial_off'
                      ? (first ? 'OFF 시작' : 'OFF 종료')
                      : (first ? '변경 시작' : '변경 종료'),
                  value: first ? start : end,

                  onChanged: (v) => setState(() => first ? start = v : end = v),
                ),
              ),
          ],
          if (kind == 'partial_off')
            const Text(
              '선택한 시간만 쉬고, 앞뒤 시간은 계속 근무해요. 야간 근무의 이른 시각은 다음 날이에요.',
              style: AppText.caption,
            ),
          const SizedBox(height: 16),
          TextField(
            controller: reason,
            maxLength: 300,
            maxLines: 3,
            decoration: const InputDecoration(labelText: '신청 이유'),
          ),
          const Text('사장님 승인 후 근무표에 반영돼요.', style: AppText.caption),
          if (error != null) Information('$error\n입력한 내용은 유지돼요.'),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: saving ? null : () => Navigator.pop(context),
        child: const Text('취소'),
      ),
      FilledButton(
        onPressed: saving ? null : submit,
        child: Text(saving ? '신청 중…' : '신청'),
      ),
    ],
  );
}

class ShiftChangePanel extends StatelessWidget {
  const ShiftChangePanel({super.key, required this.ops});
  final OperationsController ops;
  Future<void> act(BuildContext context, Json row, String decision) async {
    final revision = ops.data?['revision'], actor = ops.actorId;
    final yes = await showAppDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(
          decision == 'approved'
              ? '변경을 승인할까요?'
              : decision == 'rejected'
              ? '신청을 반려할까요?'
              : '신청을 취소할까요?',
        ),
        content: Text(
          '${row['before']['date']} · ${row['before']['start']}–${row['before']['end']} → ${shiftChangeSummary(row)}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('닫기'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('확인'),
          ),
        ],
      ),
    );
    if (yes != true || !context.mounted || actor != ops.actorId) return;
    final ok = await ops.act(
      decision == 'cancelled' ? 'cancel_shift_change' : 'review_shift_change',
      {'revision': revision, 'id': row['id'], 'decision': decision},
    );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ok ? '처리했어요.' : ops.error ?? '처리하지 못했어요.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final rows = ops.rows('shiftChangeRequests').reversed.toList();
    if (rows.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        title: Text(
          '근무 변경 신청 · 대기 ${rows.where((r) => r['status'] == 'pending').length}건',
        ),
        children: [
          for (final r in rows)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Surface(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${ops.rows('tappers').where((p) => p['id'] == r['tapperId']).firstOrNull?['nickname'] ?? '크루'} · ${r['before']['date']}',
                      style: AppText.body,
                    ),
                    Text(
                      r['status'] == 'pending'
                          ? '승인 대기 · 기존 근무 유지'
                          : r['status'] == 'approved'
                          ? '승인 완료 · 근무표 반영'
                          : r['status'] == 'rejected'
                          ? '반려 · 기존 근무 유지'
                          : '신청 취소',
                      style: AppText.caption.copyWith(
                        color: r['status'] == 'approved'
                            ? AppColors.green
                            : AppColors.amber,
                      ),
                    ),
                    Text(
                      '${r['before']['start']}–${r['before']['end']} → ${shiftChangeSummary(r)}',
                    ),
                    Text('${r['reason']}', style: AppText.caption),
                    if (r['status'] == 'approved')
                      for (final vacancy
                          in (r['vacancies'] as List? ?? []).cast<Json>())
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: vacancy['replacementShiftId'] != null
                              ? Text(
                                  '${vacancy['start']}–${vacancy['end']} · 대체 배정 완료 · ${ops.rows('tappers').where((p) => p['id'] == vacancy['replacementTapperId']).firstOrNull?['nickname'] ?? '크루'}',
                                  style: AppText.caption,
                                )
                              : Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${vacancy['date']} ${vacancy['start']}–${vacancy['end']} · 대체 미배정',
                                      style: AppText.caption,
                                    ),
                                    if (ops.isOwner &&
                                        !ops.readOnly &&
                                        !ops.busy)
                                      OutlinedButton(
                                        onPressed: () => showShiftReplacement(
                                          context,
                                          ops,
                                          r,
                                          vacancy,
                                        ),
                                        child: const Text('대체 크루 배정'),
                                      ),
                                  ],
                                ),
                        ),
                    if (r['status'] == 'pending' && !ops.readOnly && !ops.busy)
                      Wrap(
                        spacing: 8,
                        children: [
                          if (ops.isOwner) ...[
                            FilledButton(
                              onPressed: () => act(context, r, 'approved'),
                              child: const Text('승인'),
                            ),
                            TextButton(
                              onPressed: () => act(context, r, 'rejected'),
                              child: const Text('반려'),
                            ),
                          ] else
                            TextButton(
                              onPressed: () => act(context, r, 'cancelled'),
                              child: const Text('신청 취소'),
                            ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

String shiftChangeSummary(Json row) {
  if (row['kind'] == 'leave') return '휴무';
  if (row['kind'] == 'partial_off') {
    final vacancies = (row['vacancies'] as List? ?? []).cast<Json>();
    final segments = (row['segments'] as List? ?? []).cast<Json>();
    return '${vacancies.map((v) => "${v['start']}–${v['end']} OFF").join(', ')} · 근무 ${segments.map((s) => "${s['start']}–${s['end']}").join(' / ')}';
  }
  return "${row['after']['start']}–${row['after']['end']}";
}
