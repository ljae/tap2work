import '../l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import '../state/operations_controller.dart';
import 'components.dart';

class RecommendedTapsScreen extends StatefulWidget {
  const RecommendedTapsScreen({super.key, required this.ops});
  final OperationsController ops;
  @override
  State<RecommendedTapsScreen> createState() => _RecommendedTapsScreenState();
}

class _RecommendedTapsScreenState extends State<RecommendedTapsScreen> {
  late final int revision;
  late final String openingActor;
  @override
  void initState() {
    super.initState();
    revision = widget.ops.data?['revision'] as int? ?? 0;
    openingActor = widget.ops.actorId;
  }

  late final List<Json> rows = widget.ops
      .rows('recommendedTaps')
      .map((row) => {...row})
      .toList();
  final selected = <String>{};
  String? error;
  bool saving = false;

  Future<void> save() async {
    setState(() {
      saving = true;
      error = null;
    });
    if (openingActor != widget.ops.actorId) {
      setState(() {
        saving = false;
        error = context.t('ui.audit1235');
      });
      return;
    }
    final ok = await widget.ops.act('import_recommended_taps', {
      'revision': revision,
      'ids': selected.toList(),
    });
    if (!mounted) return;
    setState(() {
      saving = false;
      error = ok ? null : widget.ops.error ?? context.t('ui.audit1276');
    });
    if (ok) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) => AppEditorScaffold(
    title: context.t('ui.audit973'),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680),
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Information(context.t('ui.audit400')),
            const SizedBox(height: 12),
            if (rows.isEmpty) Information(context.t('ui.audit401')),
            for (final row in rows)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Surface(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text('${row['title']}'),
                        subtitle: Text(
                          row['alreadyAdded'] == true
                              ? context.t('ui.audit974')
                              : 'TAP · ${row['steps'].length} Task',
                        ),
                        value:
                            row['alreadyAdded'] == true ||
                            selected.contains(row['id']),
                        onChanged: row['alreadyAdded'] == true
                            ? null
                            : (v) => setState(() {
                                v == true
                                    ? selected.add(row['id'])
                                    : selected.remove(row['id']);
                              }),
                      ),
                      for (final step in (row['steps'] as List))
                        Padding(
                          padding: const EdgeInsets.only(left: 10, bottom: 3),
                          child: Text(
                            '· $step',
                            style: const TextStyle(color: AppColors.muted),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            if (error != null)
              Information(context.t('ui.audit975', args: {'p0': error})),
            const SizedBox(height: 10),
            PressBounce(
              child: FilledButton(
                onPressed: widget.ops.readOnly || selected.isEmpty || saving
                    ? null
                    : save,
                child: Text(
                  saving
                      ? context.t('ui.audit689')
                      : context.t('ui.audit976', args: {'p0': selected.length}),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
