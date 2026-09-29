import 'package:flutter/material.dart';
import '../domain/part_schedule.dart';
import '../state/operations_controller.dart';
import 'components.dart';

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
  final result = await showAppFormSheet<Json>(
    context: context,
    builder: (_) => _RequestSheet(shift: shift),
  );
  if (result == null || !context.mounted || actor != ops.actorId) return;
  final ok = await ops.act('request_shift_change', {
    'revision': revision,
    'shiftId': shiftId,
    ...result,
  });
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok ? '신청했어요. 승인 전에는 원래 근무가 유지돼요.' : ops.error ?? '신청하지 못했어요.',
        ),
      ),
    );
  }
}

class _RequestSheet extends StatefulWidget {
  const _RequestSheet({required this.shift});
  final Json shift;
  @override
  State<_RequestSheet> createState() => _RequestSheetState();
}

class _RequestSheetState extends State<_RequestSheet> {
  String kind = 'leave';
  late String start = widget.shift['start'], end = widget.shift['end'];
  final reason = TextEditingController();
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
            values: const ['leave', 'shorten'],
            selected: kind,
            labelOf: (v) => v == 'leave' ? '휴무 신청' : '단축 근무',
            onSelected: (v) => setState(() => kind = v),
          ),
          if (kind == 'shorten') ...[
            const SizedBox(height: 16),
            for (final first in [true, false])
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: AppPicker<String>(
                  label: first ? '변경 시작' : '변경 종료',
                  value: first ? start : end,
                  items: [
                    for (var m = 0; m < 1440; m += 30)
                      DropdownMenuItem(
                        value: rosterClock(m),
                        child: Text(rosterClock(m)),
                      ),
                  ],
                  onChanged: (v) =>
                      setState(() => first ? start = v! : end = v!),
                ),
              ),
          ],
          const SizedBox(height: 16),
          TextField(
            controller: reason,
            maxLength: 300,
            maxLines: 3,
            decoration: const InputDecoration(labelText: '신청 이유'),
          ),
          const Text('사장님 승인 후 근무표에 반영돼요.', style: AppText.caption),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('취소'),
      ),
      FilledButton(
        onPressed: () => Navigator.pop(context, {
          'kind': kind,
          'start': start,
          'end': end,
          'reason': reason.text,
        }),
        child: const Text('신청'),
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
          '${row['before']['date']} · ${row['before']['start']}–${row['before']['end']} → ${row['kind'] == 'leave' ? '휴무' : '${row['after']['start']}–${row['after']['end']}'}',
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
                      '${r['before']['start']}–${r['before']['end']} → ${r['kind'] == 'leave' ? '휴무' : '${r['after']['start']}–${r['after']['end']}'}',
                    ),
                    Text('${r['reason']}', style: AppText.caption),
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
