import '../l10n/entity_name_scope.dart';
import '../l10n/app_localizations.dart';
import 'workplace_screens.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../state/operations_controller.dart';
import '../state/work_controller.dart';
import 'calendar_screen.dart';
import 'components.dart';

class StaffWorkspace extends StatefulWidget {
  const StaffWorkspace({super.key, required this.ops, required this.work});
  final OperationsController ops;
  final WorkController work;
  @override
  State<StaffWorkspace> createState() => _StaffWorkspaceState();
}

class _StaffWorkspaceState extends State<StaffWorkspace> {
  @override
  Widget build(BuildContext context) =>
      CalendarScreen(operations: widget.ops, scrollable: true);
}

class HiringDrafts extends StatelessWidget {
  const HiringDrafts({super.key, required this.ops});
  final OperationsController ops;
  static const roles = {
    'crew': '크루',
    'cook': '조리',
    'cashier': '계산',
    'service': '홀 응대',
    'dishwashing': '설거지',
    'prep': '재료 준비',
    'manager': '매니저',
  };
  static const employment = {
    'unset': '미입력',
    'regular': '정규직',
    'hourly': '시간 알바',
    'regular-hourly': '정규 알바',
  };

  @override
  Widget build(BuildContext context) {
    if (!ops.isOwner) {
      return Information(context.t('ui.audit149'));
    }
    final drafts = ops
        .rows('hiringDrafts')
        .where((row) => row['status'] == 'draft')
        .toList();
    final targets =
        ((ops.data?['store']?['profile']?['staffing']?['roleTargets']
                    as List?) ??
                [])
            .cast<Json>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Information(context.t('ui.audit150')),
        const SizedBox(height: 10),
        for (final target in targets)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              context.t(
                'ui.audit640',
                args: {
                  'p0':
                      storeParts(ops)
                          .where(
                            (p) =>
                                p['id'] ==
                                (target['partId'] ?? target['roleId']),
                          )
                          .firstOrNull?['name'] ??
                      roles[target['roleId']] ??
                      target['roleId'],
                  'p1': target['count'],
                },
              ),
            ),
          ),
        if (ops.readOnly) Information(context.t('ui.audit151')),
        PressBounce(
          child: OutlinedButton.icon(
            icon: const Icon(CupertinoIcons.add),
            label: Text(context.t('ui.audit152')),
            onPressed: ops.readOnly
                ? null
                : () => showAppSheet(
                    context,
                    builder: (_) => HiringDraftEditor(
                      ops: ops,
                      defaultRole:
                          targets.firstOrNull?['partId'] ??
                          targets.firstOrNull?['roleId'],
                      defaultCount: targets.firstOrNull?['count'] ?? 1,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 12),
        if (drafts.isEmpty) Information(context.t('ui.audit153')),
        for (final draft in drafts)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Surface(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.t(
                      'ui.audit641',
                      args: {
                        'p0':
                            storeParts(ops)
                                .where((p) => p['id'] == draft['partId'])
                                .firstOrNull?['name'] ??
                            roles[draft['roleId']] ??
                            draft['roleId'],
                        'p1': draft['headcount'],
                      },
                    ),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    context.t('ui.audit154'),
                    style: TextStyle(color: AppColors.muted),
                  ),
                  Wrap(
                    spacing: 8,
                    children: [
                      PressBounce(
                        child: TextButton(
                          onPressed: () => showAppSheet(
                            context,
                            builder: (_) =>
                                HiringDraftEditor(ops: ops, existing: draft),
                          ),
                          child: Text(context.t('ui.audit155')),
                        ),
                      ),
                      PressBounce(
                        child: TextButton(
                          onPressed: () => showAppFormSheet<void>(
                            context: context,
                            builder: (dialog) => AppSheetPanel(
                              title: Text(context.t('ui.audit156')),
                              content: SingleChildScrollView(
                                child: SelectableText(_draftText(draft)),
                              ),
                              actions: [
                                PressBounce(
                                  child: TextButton(
                                    onPressed: () => Navigator.pop(dialog),
                                    child: Text(context.t('ui.audit83')),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          child: Text(context.t('ui.audit157')),
                        ),
                      ),
                      PressBounce(
                        child: TextButton(
                          onPressed: () async {
                            final ok = await ops.act('archive_hiring_draft', {
                              'id': draft['id'],
                            });
                            if (context.mounted && !ok) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    ops.error ?? context.t('ui.audit642'),
                                  ),
                                ),
                              );
                            }
                          },
                          child: Text(context.t('ui.audit158')),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  String _draftText(Json draft) =>
      '''공고 초안 · 아직 게시되지 않음
파트: ${storeParts(ops).where((p) => p['id'] == draft['partId']).firstOrNull?['name'] ?? roles[draft['roleId']] ?? draft['roleId']}
인원: ${draft['headcount']}명
고용형태: ${employment[draft['employmentType']] ?? '미입력'}
근무 요일: ${(draft['weekdays'] as List? ?? []).isEmpty ? '미입력' : (draft['weekdays'] as List).join(', ')}
근무 시간: ${'${draft['timeRange'] ?? ''}'.isEmpty ? '미입력' : draft['timeRange']}
하는 일: ${'${draft['responsibilities'] ?? ''}'.isEmpty ? '미입력' : draft['responsibilities']}
필요 조건: ${'${draft['requirements'] ?? ''}'.isEmpty ? '미입력' : draft['requirements']}
메모: ${'${draft['note'] ?? ''}'.isEmpty ? '미입력' : draft['note']}''';
}

class HiringDraftEditor extends StatefulWidget {
  const HiringDraftEditor({
    super.key,
    required this.ops,
    this.existing,
    this.defaultRole,
    this.defaultCount = 1,
  });
  final OperationsController ops;
  final Json? existing;
  final String? defaultRole;
  final int defaultCount;
  @override
  State<HiringDraftEditor> createState() => _HiringDraftEditorState();
}

class _HiringDraftEditorState extends State<HiringDraftEditor> {
  late final int revision;
  late final String openingActor;
  @override
  void initState() {
    super.initState();
    revision = widget.ops.data?['revision'] as int? ?? 0;
    openingActor = widget.ops.actorId;
  }

  late String role =
      widget.existing?['partId'] ??
      (storeParts(widget.ops).any((p) => p['id'] == widget.defaultRole)
          ? widget.defaultRole
          : null) ??
      storeParts(widget.ops).first['id'];
  late String type = widget.existing?['employmentType'] ?? 'unset';
  late final TextEditingController count = TextEditingController(
    text: '${widget.existing?['headcount'] ?? widget.defaultCount}',
  );
  late final TextEditingController time = TextEditingController(
    text: '${widget.existing?['timeRange'] ?? ''}',
  );
  late final TextEditingController duties = TextEditingController(
    text: '${widget.existing?['responsibilities'] ?? ''}',
  );
  late final TextEditingController requirements = TextEditingController(
    text: '${widget.existing?['requirements'] ?? ''}',
  );
  late final TextEditingController note = TextEditingController(
    text: '${widget.existing?['note'] ?? ''}',
  );
  late final List<int> days = List<int>.from(
    widget.existing?['weekdays'] ?? [],
  );
  bool saving = false;
  String? error;

  @override
  void dispose() {
    for (final c in [count, time, duties, requirements, note]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> save() async {
    final headcount = int.tryParse(count.text);
    if (headcount == null || headcount < 1) {
      setState(() => error = context.t('ui.audit1245'));
      return;
    }
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
    final ok = await widget.ops.act('save_hiring_draft', {
      'revision': revision,
      if (widget.existing != null) 'id': widget.existing!['id'],
      'partId': role,
      'headcount': headcount,
      'employmentType': type,
      'weekdays': days,
      'timeRange': time.text.trim(),
      'responsibilities': duties.text.trim(),
      'requirements': requirements.text.trim(),
      'note': note.text.trim(),
    });
    if (!mounted) return;
    setState(() {
      saving = false;
      error = ok ? null : widget.ops.error ?? context.t('ui.audit760');
    });
    if (ok) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) => AppEditorScaffold(
    title: context.t('ui.audit156'),
    footer: AppSheetFooter(
      children: [
        FilledButton(
          onPressed: !saving && !widget.ops.readOnly ? save : null,
          child: Text(
            saving ? context.t('ui.audit532') : context.t('ui.audit643'),
          ),
        ),
      ],
    ),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: appEditorWidth),
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Information(context.t('ui.audit159')),
            const SizedBox(height: 14),
            AppPillField<String>(
              initialValue: role,
              decoration: InputDecoration(labelText: context.t('ui.audit160')),
              items: [
                for (final part in storeParts(
                  widget.ops,
                ).where((p) => p['hidden'] != true))
                  DropdownMenuItem(
                    value: part['id'] as String,
                    child: Text(
                      entityDisplayName(
                        context,
                        widget.ops,
                        'part',
                        part['id'],
                        part['name'],
                      ),
                    ),
                  ),
              ],
              onChanged: (v) => setState(() => role = v ?? role),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: count,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: context.t('ui.audit161')),
            ),
            const SizedBox(height: 12),
            AppPillField<String>(
              initialValue: type,
              decoration: InputDecoration(labelText: context.t('ui.audit162')),
              items: [
                for (final entry in HiringDrafts.employment.entries)
                  DropdownMenuItem(value: entry.key, child: Text(entry.value)),
              ],
              onChanged: (v) => setState(() => type = v ?? type),
            ),
            const SizedBox(height: 16),
            Text(context.t('ui.audit163')),
            Wrap(
              spacing: 7,
              children: [
                for (var day = 1; day <= 7; day++)
                  FilterChip(
                    chipAnimationStyle: AppMotion.chipStyle(context),
                    label: Text(
                      [
                        context.t('ui.audit523'),
                        context.t('ui.audit524'),
                        context.t('ui.audit525'),
                        context.t('ui.audit526'),
                        context.t('ui.audit527'),
                        context.t('ui.audit528'),
                        context.t('ui.audit529'),
                      ][day - 1],
                    ),
                    selected: days.contains(day),
                    onSelected: (_) => setState(
                      () =>
                          days.contains(day) ? days.remove(day) : days.add(day),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            TextField(
              controller: time,
              decoration: InputDecoration(labelText: context.t('ui.audit164')),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: duties,
              maxLines: 3,
              decoration: InputDecoration(labelText: context.t('ui.audit165')),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: requirements,
              maxLines: 3,
              decoration: InputDecoration(labelText: context.t('ui.audit166')),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: note,
              maxLines: 3,
              decoration: InputDecoration(labelText: context.t('ui.audit167')),
            ),
            if (error != null)
              Information(context.t('ui.audit535', args: {'p0': error})),
            const SizedBox(height: 16),
          ],
        ),
      ),
    ),
  );
}
