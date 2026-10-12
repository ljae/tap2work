import '../l10n/app_localizations.dart';
import '../l10n/manual_text_scope.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../state/operations_controller.dart';
import 'components.dart';
import 'tap_settings_screen.dart';
import 'manual_tap_editor.dart';

Future<String?> openOwnerWorkflow(
  BuildContext context,
  OperationsController ops,
) => showAppSheet<String>(
  context,
  builder: (_) => OwnerWorkflowScreen(ops: ops),
);

class OwnerWorkflowScreen extends StatefulWidget {
  const OwnerWorkflowScreen({super.key, required this.ops});
  final OperationsController ops;
  @override
  State<OwnerWorkflowScreen> createState() => _OwnerWorkflowScreenState();
}

class _OwnerWorkflowScreenState extends State<OwnerWorkflowScreen> {
  final selected = <String>{};
  late final String actor = widget.ops.actorId;
  late final Object? workspace = widget.ops.data?['workspaceId'];
  int stage = 0;
  String query = '';
  bool matches(Json row) =>
      query.trim().isEmpty ||
      '${row['title']} ${manualDisplayText(context, '${row['title']}')} ${(row['steps'] as List? ?? []).map((s) => '${s['title']} ${manualDisplayText(context, '${s['title']}')}').join(' ')}'
          .contains(query.trim());
  bool saving = false;
  String? error;
  final reviewed = <String, String>{};
  OperationsController get ops => widget.ops;
  Json get flow => ops.data?['ownerWorkflow'] as Json? ?? {};
  List<Json> rows(String key) => (flow[key] as List? ?? []).cast<Json>();
  bool get valid =>
      ops.actorId == actor &&
      ops.data?['workspaceId'] == workspace &&
      ops.actor['role'] == 'owner';

  Future<void> review(Json row, bool pending) async {
    final key = '${pending ? 'pending' : 'starter'}:${row['id']}';
    final confirmed = await showAppSheet<bool>(
      context,
      builder: (c) => AppEditorScaffold(
        title: manualDisplayText(c, '${row['title']}'),
        footer: AppSheetFooter(
          children: [
            FilledButton(
              onPressed: () => Navigator.pop(c, true),
              child: Text(context.t('ui.audit53')),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Information(
              pending
                  ? context.t('ui.audit579')
                  : manualDisplayText(c, flow['assumption'] as String? ?? ''),
            ),
            if (row['catalogUpdate'] == true)
              Information(context.t('ui.audit54')),
            if (row['replacesExisting'] == true)
              Information(context.t('ui.audit55')),
            for (final step in (row['steps'] as List).cast<Json>()) ...[
              const SizedBox(height: 24),
              Text(
                manualDisplayText(c, '${step['title']}'),
                style: AppText.section,
              ),
              const SizedBox(height: 12),
              Text(
                manualDisplayText(c, '${step['manual']}'),
                style: AppText.body,
              ),
              if ('${step['tip'] ?? ''}'.isNotEmpty) ...[
                const SizedBox(height: 12),
                Information(manualDisplayText(c, '${step['tip']}')),
              ],
            ],
          ],
        ),
      ),
    );
    if (confirmed == true && mounted && valid) {
      setState(() {
        selected.add(key);
        reviewed[key] = jsonEncode(row);
      });
    }
  }

  Future<void> register() async {
    if (!valid || saving || selected.isEmpty) return;
    // Review is tied to the displayed revision; no silent confirmation of changed content.
    final revision = ops.data?['revision'] as int? ?? 0;
    if (selected.any((id) {
      final list = rows(id.startsWith('pending:') ? 'pending' : 'candidates');
      final row = list.where((r) => r['id'] == id.substring(8)).firstOrNull;
      return row == null || reviewed[id] != jsonEncode(row);
    })) {
      setState(() {
        error = context.t('ui.audit1237');
        selected.clear();
      });
      return;
    }
    setState(() {
      saving = true;
      error = null;
    });
    final ok = await ops.act('register_owner_selection', {
      'revision': revision,
      'reviewed': true,
      'starterVersion': flow['version'],
      'starterIds': selected
          .where((s) => s.startsWith('starter:'))
          .map((s) => s.substring(8))
          .toList(),
      'pendingIds': selected
          .where((s) => s.startsWith('pending:'))
          .map((s) => s.substring(8))
          .toList(),
    });
    if (!mounted) return;
    setState(() {
      saving = false;
      if (ok) {
        selected.clear();
        stage = 1;
      } else {
        error = ops.error ?? context.t('ui.audit1139');
      }
    });
  }

  Future<void> settings(Json plan) async {
    await showAppSheet<void>(
      context,
      builder: (_) => TapSettingsScreen(
        ops: ops,
        initialTemplateId: plan['templateId'],
        effectiveFrom: flow['date'],
      ),
    );
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: ops,
    builder: (context, _) {
      final pending = rows('pending').where(matches).toList(),
          candidates = rows('candidates').where(matches).toList(),
          plans = rows('plans');
      return AppEditorScaffold(
        title: context.t('ui.audit580'),
        footer: AppSheetFooter(
          children: [
            FilledButton(
              onPressed: saving || !valid || (stage == 0 && ops.readOnly)
                  ? null
                  : stage == 0
                  ? (selected.isEmpty ? null : register)
                  : stage == 1
                  ? () => setState(() => stage = 2)
                  : () => Navigator.pop(context, 'work'),
              child: Text(
                saving
                    ? context.t('ui.audit581')
                    : stage == 0
                    ? context.t('ui.audit582', args: {'p0': selected.length})
                    : stage == 1
                    ? context.t('ui.audit583')
                    : context.t('ui.audit584'),
              ),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Wrap(
              spacing: 8,
              children: [
                for (var i = 0; i < 3; i++)
                  ChoiceChip(
                    label: Text(
                      [
                        context.t('ui.audit585'),
                        context.t('ui.audit586'),
                        context.t('ui.audit587'),
                      ][i],
                    ),
                    selected: stage == i,
                    onSelected: saving
                        ? null
                        : (_) => setState(() => stage = i),
                    chipAnimationStyle: AppMotion.chipStyle(context),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            if (!valid) Information(context.t('ui.audit56')),
            if (error != null) Information(context.t(error!)),
            AppContentTransition(
              trigger: stage,
              child: KeyedSubtree(
                key: ValueKey(stage),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: stage == 0
                      ? [
                          Text(context.t('ui.audit57'), style: AppText.section),
                          const SizedBox(height: 12),
                          Text(context.t('ui.audit58'), style: AppText.body),
                          const SizedBox(height: 16),
                          TextField(
                            decoration: InputDecoration(
                              labelText: context.t('ui.audit59'),
                              hintText: context.t('ui.audit60'),
                              prefixIcon: Icon(Icons.search),
                            ),
                            onChanged: (v) => setState(() => query = v),
                          ),
                          const SizedBox(height: 16),
                          if (pending.isNotEmpty)
                            Eyebrow(context.t('ui.audit61')),
                          for (final row in pending)
                            manualCard(context, row, true),
                          if (candidates.isNotEmpty)
                            Eyebrow(context.t('ui.audit62')),
                          for (final row in candidates)
                            manualCard(context, row, false),
                          if (pending.isEmpty && candidates.isEmpty)
                            Information(context.t('ui.audit63')),
                        ]
                      : stage == 1
                      ? [
                          Text(context.t('ui.audit64'), style: AppText.section),
                          const SizedBox(height: 16),
                          effect(
                            Icons.search,
                            context.t('ui.audit65'),
                            context.t('ui.audit66'),
                            context.t('ui.audit67'),
                            () => Navigator.pop(context, 'manual'),
                          ),
                          effect(
                            Icons.today_outlined,
                            context.t('ui.audit68'),
                            context.t('ui.audit69'),
                            context.t('ui.audit70'),
                            () => Navigator.pop(context, 'work'),
                          ),
                          effect(
                            Icons.people_outline,
                            context.t('ui.audit71'),
                            context.t('ui.audit72'),
                            context.t('ui.audit73'),
                            () => setState(() => stage = 2),
                          ),
                          Information(context.t('ui.audit74')),
                        ]
                      : [
                          Text(
                            context.t(
                              'ui.audit588',
                              args: {'p0': flow['date'] ?? ''},
                            ),
                            style: AppText.section,
                          ),
                          const SizedBox(height: 12),
                          Information(context.t('ui.audit75')),
                          if (flow['closed'] == true)
                            Information(context.t('ui.audit76')),
                          if (plans.isEmpty)
                            Information(context.t('ui.audit77')),
                          for (final plan in plans) planCard(context, plan),
                        ],
                ),
              ),
            ),
          ],
        ),
      );
    },
  );

  Widget manualCard(BuildContext context, Json row, bool pending) {
    final key = '${pending ? 'pending' : 'starter'}:${row['id']}';
    final settings = pending ? row['settings'] as Json? ?? {} : row;
    final recurrence = settings['recurrence'] as Json? ?? {};
    final usage = settings['usage'] ?? 'reference';
    final label = usage != 'routine'
        ? context.t('ui.audit1238')
        : recurrence['mode'] == 'monthly'
        ? context.t('ui.audit1004', args: {'p0': recurrence['monthDay']})
        : recurrence['mode'] == 'weekly'
        ? context.t('ui.audit1239')
        : context.t('ui.audit1240');
    return AppCard(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Icon(
          selected.contains(key)
              ? Icons.check_circle
              : Icons.menu_book_outlined,
          color: selected.contains(key) ? AppColors.green : AppColors.muted,
        ),
        title: Text(manualDisplayText(context, '${row['title']}')),
        subtitle: Text(
          context.t(
            'ui.audit589',
            args: {'p0': label, 'p1': (row['steps'] as List).length},
          ),
        ),
        trailing: selected.contains(key)
            ? IconButton(
                tooltip: context.t('ui.audit590'),
                onPressed: saving
                    ? null
                    : () => setState(() => selected.remove(key)),
                icon: const Icon(Icons.close),
              )
            : const Icon(Icons.chevron_right),
        onTap: saving ? null : () => review(row, pending),
      ),
    );
  }

  Widget effect(
    IconData icon,
    String title,
    String detail,
    String action,
    VoidCallback onTap,
  ) => AppCard(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.green),
          const SizedBox(height: 12),
          Text(title, style: AppText.section),
          const SizedBox(height: 8),
          Text(detail, style: AppText.body),
          TextButton(onPressed: onTap, child: Text(action)),
        ],
      ),
    ),
  );

  Widget planCard(BuildContext context, Json plan) {
    final assignment = plan['assignment'] as Json? ?? {};
    final names = (assignment['assignees'] as List? ?? [])
        .map((p) => p['nickname'])
        .join(', ');
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              manualDisplayText(context, '${plan['title']}'),
              style: AppText.section,
            ),
            const SizedBox(height: 8),
            Text(
              context.t(
                'ui.audit589',
                args: {
                  'p0': plan['timeBandName'] ?? plan['slot'],
                  'p1': plan['stepCount'],
                },
              ),
              style: AppText.caption,
            ),
            const SizedBox(height: 8),
            Text(
              names.isEmpty
                  ? context.t('ui.audit591')
                  : context.t('ui.audit592', args: {'p0': names}),
              style: AppText.body,
            ),
            if (plan['scheduled'] == true)
              Text(context.t('ui.audit78'), style: AppText.caption),
            Wrap(
              spacing: 8,
              children: [
                TextButton(
                  onPressed: () => settings(plan),
                  child: Text(context.t('ui.audit79')),
                ),
                TextButton(
                  onPressed: () async {
                    await showAppSheet<void>(
                      context,
                      builder: (_) => ManualTapEditor(
                        ops: ops,
                        templateId: plan['templateId'],
                      ),
                    );
                    if (mounted) setState(() {});
                  },
                  child: Text(context.t('ui.audit80')),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
