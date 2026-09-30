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
        title: '$bandName · 연결 업무',
        body: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Information(
              'TAP 전체 또는 개별 Task를 선택해 이 시간대의 담당 파트를 설정해 주세요. 변경은 같은 업무 설정에 저장돼요.',
            ),
            const SizedBox(height: 16),
            if (taps.isEmpty) const Information('먼저 업무 또는 매뉴얼에서 TAP을 추가해 주세요.'),
            for (final tap in taps)
              AppFormSection(
                title: '${tap['manualTitle'] ?? tap['title']}',
                children: [
                  OutlinedButton(
                    onPressed: ops.canEditTasks && !ops.readOnly
                        ? () => edit(context, tap)
                        : null,
                    child: Text(linked(tap) ? 'TAP 연결 수정' : 'TAP 전체 연결'),
                  ),
                  for (final step
                      in (tap['steps'] as List? ?? []).whereType<Json>())
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text('${step['manualTitle'] ?? step['title']}'),
                      subtitle: Text(
                        linked(step)
                            ? '이 시간대에 별도 연결'
                            : linked(tap) &&
                                  (step['settings']?['assignment']?['mode'] ??
                                          'inherit') ==
                                      'inherit'
                            ? 'TAP 연결 따름'
                            : 'Task 개별 설정',
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
