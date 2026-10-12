import '../l10n/app_localizations.dart';
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.t('ui.audit718'))));
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
    title: Text(context.t('ui.audit222')),
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
                ? context.t('ui.audit1129')
                : v == 'partial_off'
                ? context.t('ui.audit1130')
                : context.t('ui.audit1131'),
            onSelected: (v) => setState(() => kind = v),
          ),
          if (kind != 'leave') ...[
            const SizedBox(height: 16),
            for (final first in [true, false])
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: AppTimeField(
                  label: kind == 'partial_off'
                      ? (first
                            ? context.t('ui.audit719')
                            : context.t('ui.audit720'))
                      : (first
                            ? context.t('ui.audit721')
                            : context.t('ui.audit722')),
                  value: first ? start : end,

                  onChanged: (v) => setState(() => first ? start = v : end = v),
                ),
              ),
          ],
          if (kind == 'partial_off')
            Text(context.t('ui.audit223'), style: AppText.caption),
          const SizedBox(height: 16),
          TextField(
            controller: reason,
            maxLength: 300,
            maxLines: 3,
            decoration: InputDecoration(labelText: context.t('ui.audit224')),
          ),
          Text(context.t('ui.audit225'), style: AppText.caption),
          if (error != null)
            Information(context.t('ui.audit723', args: {'p0': error})),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: saving ? null : () => Navigator.pop(context),
        child: Text(context.t('ui.audit33')),
      ),
      FilledButton(
        onPressed: saving ? null : submit,
        child: Text(
          saving ? context.t('ui.audit724') : context.t('ui.audit725'),
        ),
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
              ? context.t('ui.audit726')
              : decision == 'rejected'
              ? context.t('ui.audit727')
              : context.t('ui.audit728'),
        ),
        content: Text(
          '${row['before']['date']} · ${row['before']['start']}–${row['before']['end']} → ${shiftChangeSummary(row)}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: Text(context.t('ui.audit83')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: Text(context.t('ui.audit226')),
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
        SnackBar(
          content: Text(
            ok
                ? context.t('ui.audit729')
                : ops.error ?? context.t('ui.audit730'),
          ),
        ),
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
          context.t(
            'ui.audit731',
            args: {'p0': rows.where((r) => r['status'] == 'pending').length},
          ),
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
                          ? context.t('ui.audit732')
                          : r['status'] == 'approved'
                          ? context.t('ui.audit733')
                          : r['status'] == 'rejected'
                          ? context.t('ui.audit734')
                          : context.t('ui.audit230'),
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
                                  context.t(
                                    'ui.audit735',
                                    args: {
                                      'p0': vacancy['start'],
                                      'p1': vacancy['end'],
                                      'p2':
                                          ops
                                              .rows('tappers')
                                              .where(
                                                (p) =>
                                                    p['id'] ==
                                                    vacancy['replacementTapperId'],
                                              )
                                              .firstOrNull?['nickname'] ??
                                          context.t('ui.audit765'),
                                    },
                                  ),
                                  style: AppText.caption,
                                )
                              : Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      context.t(
                                        'ui.audit736',
                                        args: {
                                          'p0': vacancy['date'],
                                          'p1': vacancy['start'],
                                          'p2': vacancy['end'],
                                        },
                                      ),
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
                                        child: Text(context.t('ui.audit227')),
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
                              child: Text(context.t('ui.audit228')),
                            ),
                            TextButton(
                              onPressed: () => act(context, r, 'rejected'),
                              child: Text(context.t('ui.audit229')),
                            ),
                          ] else
                            TextButton(
                              onPressed: () => act(context, r, 'cancelled'),
                              child: Text(context.t('ui.audit230')),
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
