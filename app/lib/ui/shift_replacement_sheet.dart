import '../l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import '../state/operations_controller.dart';
import 'components.dart';

(DateTime, DateTime) _range(Json row) {
  final start = DateTime.parse('${row['date']}T${row['start']}:00+09:00');
  var end = DateTime.parse('${row['date']}T${row['end']}:00+09:00');
  if (!end.isAfter(start)) end = end.add(const Duration(days: 1));
  return (start, end);
}

List<Json> replacementCandidates(
  OperationsController ops,
  Json request,
  Json vacancy,
) {
  final (a, b) = _range(vacancy);
  bool overlaps(Json row) {
    final (c, d) = _range(row);
    return a.isBefore(d) && c.isBefore(b);
  }

  return ops.rows('tappers').where((person) {
    if (person['active'] == false || person['id'] == request['tapperId']) {
      return false;
    }
    final parts = person['workProfile']?['partIds'] as List? ?? [];
    if (parts.isNotEmpty && !parts.contains(vacancy['partId'])) return false;
    if (ops
        .rows('staffShifts')
        .any((s) => s['tapperId'] == person['id'] && overlaps(s))) {
      return false;
    }
    if (ops.rows('attendance').any((e) {
      if (e['tapperId'] != person['id']) return false;
      final at = DateTime.tryParse(e['at'] ?? '');
      if (at == null) return false;
      final kst = at
          .toUtc()
          .add(const Duration(hours: 9))
          .toIso8601String()
          .substring(0, 10);
      return kst == vacancy['date'] || (!at.isBefore(a) && at.isBefore(b));
    })) {
      return false;
    }
    return !ops
        .rows('shiftChangeRequests')
        .any(
          (r) =>
              r['tapperId'] == person['id'] &&
              r['status'] == 'approved' &&
              (r['vacancies'] as List? ?? []).cast<Json>().any(overlaps),
        );
  }).toList();
}

Future<void> showShiftReplacement(
  BuildContext context,
  OperationsController ops,
  Json request,
  Json vacancy,
) => showAppFormSheet<void>(
  context: context,
  builder: (_) =>
      _ReplacementSheet(ops: ops, request: request, vacancy: vacancy),
);

class _ReplacementSheet extends StatefulWidget {
  const _ReplacementSheet({
    required this.ops,
    required this.request,
    required this.vacancy,
  });
  final OperationsController ops;
  final Json request, vacancy;
  @override
  State<_ReplacementSheet> createState() => _ReplacementSheetState();
}

class _ReplacementSheetState extends State<_ReplacementSheet> {
  late final dynamic revision;
  late final String actor;
  @override
  void initState() {
    super.initState();
    revision = widget.ops.data?['revision'];
    actor = widget.ops.actorId;
  }

  String? crewId, error;
  bool saving = false;
  Future<void> save() async {
    if (saving || crewId == null || widget.ops.actorId != actor) return;
    setState(() => saving = true);
    final ok = await widget.ops.act('review_shift_change', {
      'revision': revision,
      'id': widget.request['id'],
      'decision': 'assign_replacement',
      'vacancyId': widget.vacancy['id'],
      'tapperId': crewId,
    });
    if (!mounted) return;
    setState(() {
      saving = false;
      error = ok ? null : widget.ops.error;
    });
    if (ok) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final people = replacementCandidates(
      widget.ops,
      widget.request,
      widget.vacancy,
    );
    return AppSheetPanel(
      title: Text(context.t('ui.audit227')),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '${widget.vacancy['date']} · ${widget.vacancy['start']}–${widget.vacancy['end']}',
            ),
            const SizedBox(height: 16),
            if (people.isEmpty)
              Information(context.t('ui.audit405'))
            else
              AppPicker<String>(
                label: context.t('ui.audit978'),
                value: crewId,
                items: [
                  for (final p in people)
                    DropdownMenuItem(
                      value: p['id'] as String,
                      child: Text(p['nickname']),
                    ),
                ],
                onChanged: (v) {
                  if (!saving) setState(() => crewId = v);
                },
              ),
            const SizedBox(height: 16),
            Text(context.t('ui.audit406'), style: AppText.caption),
            if (error != null)
              Information(context.t('ui.audit979', args: {'p0': error})),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: saving ? null : () => Navigator.pop(context),
          child: Text(context.t('ui.audit83')),
        ),
        FilledButton(
          onPressed: !saving && people.any((p) => p['id'] == crewId)
              ? save
              : null,
          child: Text(
            saving ? context.t('ui.audit980') : context.t('ui.audit981'),
          ),
        ),
      ],
    );
  }
}
