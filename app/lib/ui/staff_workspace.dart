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
      return const Information('채용 준비는 사장님 계정에서 볼 수 있어요.');
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
        const Information('공고 초안을 작성하고 복사할 수 있어요. 외부 사이트에는 게시되지 않아요.'),
        const SizedBox(height: 10),
        for (final target in targets)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              '${storeParts(ops).where((p) => p['id'] == (target['partId'] ?? target['roleId'])).firstOrNull?['name'] ?? roles[target['roleId']] ?? target['roleId']} · 목표 ${target['count']}명',
            ),
          ),
        if (ops.readOnly) const Information('공개 미리보기에서는 초안을 저장하지 않아요.'),
        PressBounce(
          child: OutlinedButton.icon(
            icon: const Icon(CupertinoIcons.add),
            label: const Text('공고 초안 만들기'),
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
        if (drafts.isEmpty) const Information('저장된 공고 초안이 없어요.'),
        for (final draft in drafts)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Surface(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${storeParts(ops).where((p) => p['id'] == draft['partId']).firstOrNull?['name'] ?? roles[draft['roleId']] ?? draft['roleId']} · ${draft['headcount']}명',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Text(
                    '초안 · 아직 게시되지 않음',
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
                          child: const Text('수정'),
                        ),
                      ),
                      PressBounce(
                        child: TextButton(
                          onPressed: () => showAppFormSheet<void>(
                            context: context,
                            builder: (dialog) => AppSheetPanel(
                              title: const Text('공고 초안'),
                              content: SingleChildScrollView(
                                child: SelectableText(_draftText(draft)),
                              ),
                              actions: [
                                PressBounce(
                                  child: TextButton(
                                    onPressed: () => Navigator.pop(dialog),
                                    child: const Text('닫기'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          child: const Text('내용 선택·복사'),
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
                                  content: Text(ops.error ?? '보관하지 못했어요.'),
                                ),
                              );
                            }
                          },
                          child: const Text('보관'),
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
      setState(() => error = '필요 인원을 1명 이상 입력해 주세요.');
      return;
    }
    setState(() {
      saving = true;
      error = null;
    });
    if (openingActor != widget.ops.actorId) {
      setState(() {
        saving = false;
        error = '계정이 변경됐어요. 다시 열어 주세요.';
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
      error = ok ? null : widget.ops.error ?? '저장하지 못했어요.';
    });
    if (ok) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) => AppEditorScaffold(
    title: '공고 초안',
    footer: AppSheetFooter(
      children: [
        FilledButton(
          onPressed: !saving && !widget.ops.readOnly ? save : null,
          child: Text(saving ? '저장 중…' : '초안 저장'),
        ),
      ],
    ),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: appEditorWidth),
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Information('아직 게시되지 않는 초안이에요. 비어 있는 조건은 미입력으로 표시해요.'),
            const SizedBox(height: 14),
            AppPillField<String>(
              initialValue: role,
              decoration: const InputDecoration(labelText: '파트'),
              items: [
                for (final part in storeParts(
                  widget.ops,
                ).where((p) => p['hidden'] != true))
                  DropdownMenuItem(
                    value: part['id'] as String,
                    child: Text(part['name']),
                  ),
              ],
              onChanged: (v) => setState(() => role = v ?? role),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: count,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: '필요 인원'),
            ),
            const SizedBox(height: 12),
            AppPillField<String>(
              initialValue: type,
              decoration: const InputDecoration(labelText: '고용형태'),
              items: [
                for (final entry in HiringDrafts.employment.entries)
                  DropdownMenuItem(value: entry.key, child: Text(entry.value)),
              ],
              onChanged: (v) => setState(() => type = v ?? type),
            ),
            const SizedBox(height: 16),
            const Text('근무 요일 · 선택'),
            Wrap(
              spacing: 7,
              children: [
                for (var day = 1; day <= 7; day++)
                  FilterChip(
                    chipAnimationStyle: AppMotion.chipStyle(context),
                    label: Text(
                      const ['월', '화', '수', '목', '금', '토', '일'][day - 1],
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
              decoration: const InputDecoration(labelText: '근무 시간 · 선택'),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: duties,
              maxLines: 3,
              decoration: const InputDecoration(labelText: '하는 일 · 선택'),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: requirements,
              maxLines: 3,
              decoration: const InputDecoration(labelText: '필요 조건 · 선택'),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: note,
              maxLines: 3,
              decoration: const InputDecoration(labelText: '메모 · 선택'),
            ),
            if (error != null) Information('$error\n초안은 그대로 남아 있어요.'),
            const SizedBox(height: 16),
          ],
        ),
      ),
    ),
  );
}
