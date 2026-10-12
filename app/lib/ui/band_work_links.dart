import '../l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import '../state/operations_controller.dart';
import 'components.dart';
import 'tap_settings_screen.dart';

/// All edits use the same TAP/Task settings API as the work/manual entry point.
class BandWorkLinks extends StatelessWidget {
  const BandWorkLinks({
    super.key,
    required this.ops,
    required this.bandId,
    required this.bandName,
  });
  final OperationsController ops;
  final String bandId, bandName;
  bool linked(Json row) =>
      (row['settings']?['assignment']?['timeBandIds'] as List? ?? []).contains(
        bandId,
      );
  Future<void> edit(BuildContext context, Json tap, {Json? step}) =>
      showAppFormSheet<void>(
        context: context,
        builder: (_) => TapSettingsScreen(
          ops: ops,
          initialTemplateId: tap['id'],
          initialStepId: step?['id'],
          initialTimeBandId: linked(step ?? tap) ? null : bandId,
        ),
      );
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: ops,
    builder: (context, _) {
      final taps = ops
          .rows('taskTemplates')
          .where((t) => t['archivedAt'] == null && t['menuManualId'] == null)
          .toList();
      return AppEditorScaffold(
        title: context.t('ui.audit864', args: {'p0': bandName}),
        body: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Information(context.t('ui.audit321')),
            const SizedBox(height: 16),
            if (taps.isEmpty) Information(context.t('ui.audit322')),
            for (final tap in taps)
              AppFormSection(
                title: '${tap['manualTitle'] ?? tap['title']}',
                children: [
                  OutlinedButton(
                    onPressed: ops.canEditTasks && !ops.readOnly
                        ? () => edit(context, tap)
                        : null,
                    child: Text(
                      linked(tap)
                          ? context.t('ui.audit865')
                          : context.t('ui.audit866'),
                    ),
                  ),
                  for (final step
                      in (tap['steps'] as List? ?? []).whereType<Json>())
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text('${step['manualTitle'] ?? step['title']}'),
                      subtitle: Text(
                        linked(step)
                            ? context.t('ui.audit867')
                            : linked(tap) &&
                                  (step['settings']?['assignment']?['mode'] ??
                                          'inherit') ==
                                      'inherit'
                            ? context.t('ui.audit868')
                            : context.t('ui.audit869'),
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: ops.canEditTasks && !ops.readOnly
                          ? () => edit(context, tap, step: step)
                          : null,
                    ),
                ],
              ),
          ],
        ),
      );
    },
  );
}
