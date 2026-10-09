import 'dart:math';
import 'package:flutter/material.dart';
import '../state/operations_controller.dart';
import 'components.dart';
import 'tap_settings_screen.dart';

/// A manager sees the server's execution diagnosis, not a guessed OFF warning.
class ManualWorkScreen extends StatefulWidget {
  const ManualWorkScreen({super.key, required this.ops});
  final OperationsController ops;
  @override
  State<ManualWorkScreen> createState() => _ManualWorkScreenState();
}

class _ManualWorkScreenState extends State<ManualWorkScreen> {
  String filter = 'all';
  @override
  Widget build(BuildContext context) {
    final rows = widget.ops
        .rows('taskTemplates')
        .where(
          (t) =>
              t['archivedAt'] == null &&
              (filter == 'all' ||
                  [
                    'unclassified',
                    'incomplete',
                    'missing',
                    'replacement',
                  ].contains(t['workStatus']?['code'])),
        )
        .toList();
    return AppEditorScaffold(
      title: '매뉴얼 · 업무 연결',
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          if (widget.ops.error != null) Information(widget.ops.error!),
          const Information(
            '매뉴얼을 모두 매일 체크할 필요는 없어요. 참고용은 그대로 두고 필요한 업무만 연결하세요.',
          ),
          Wrap(
            spacing: 8,
            children: [
              for (final value in ['all', 'needs'])
                ChoiceChip(
                  label: Text(value == 'all' ? '전체' : '설정 확인'),
                  selected: filter == value,
                  onSelected: (_) => setState(() => filter = value),
                ),
            ],
          ),
          for (final t in rows)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${t['title']}', style: AppText.section),
                    const SizedBox(height: 8),
                    Text(
                      '${t['workStatus']?['label'] ?? '사용 방법을 확인해 주세요'}',
                      style: AppText.caption,
                    ),
                    if (t['knowledge']?['scope'] != null)
                      Text(
                        {
                              'universal': '업종 공통',
                              'food': '외식 공통',
                              'process': '공정 공통',
                              'menu': '메뉴·업종별',
                              'store': '매장 전용',
                            }[t['knowledge']['scope']] ??
                            '',
                        style: AppText.caption,
                      ),
                    Wrap(
                      spacing: 8,
                      children: [
                        TextButton(
                          onPressed: widget.ops.readOnly
                              ? null
                              : () async {
                                  await showAppSheet(
                                    context,
                                    builder: (_) => TapSettingsScreen(
                                      ops: widget.ops,
                                      initialTemplateId: t['id'],
                                    ),
                                  );
                                  if (mounted) setState(() {});
                                },
                          child: const Text('연결 설정'),
                        ),
                        if (t['workStatus']?['code'] == 'replacement')
                          TextButton(
                            onPressed:
                                (widget.ops.readOnly ||
                                    t['workStatus']?['replacementsAvailable'] !=
                                        true)
                                ? null
                                : () async {
                                    final accepted = await showAppDialog<bool>(
                                      context: context,
                                      builder: (c) => AlertDialog(
                                        title: const Text('공통 업무로 정리할까요?'),
                                        content: const Text(
                                          '기존 매뉴얼은 보관하고 진행 중·완료 기록은 유지해요. 새 매뉴얼은 업무 사용을 끈 상태로 가져와요. 매장에서 수정한 내용은 기존 보관본에서 확인할 수 있어요.',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(c, false),
                                            child: const Text('취소'),
                                          ),
                                          FilledButton(
                                            onPressed: () =>
                                                Navigator.pop(c, true),
                                            child: const Text('나누어 가져오기'),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (accepted != true || !mounted) return;
                                    await widget.ops.act('replace_mixed_break', {
                                      'templateId': t['id'],
                                      'releaseId': widget
                                          .ops
                                          .data?['manualCatalog']?['releaseId'],
                                      'operationId': 'split-${t['id']}',
                                    });
                                    if (mounted) setState(() {});
                                  },
                            child: const Text('새 구성 적용'),
                          ),
                        if (t['workStatus']?['code'] == 'event')
                          FilledButton(
                            onPressed: widget.ops.readOnly
                                ? null
                                : () async {
                                    await showAppSheet(
                                      context,
                                      builder: (_) => StartManualWork(
                                        ops: widget.ops,
                                        template: t,
                                      ),
                                    );
                                    if (mounted) setState(() {});
                                  },
                            child: const Text('작업 시작'),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          if (rows.isEmpty) const Information('확인이 필요한 매뉴얼이 없어요.'),
        ],
      ),
    );
  }
}

class StartManualWork extends StatefulWidget {
  const StartManualWork({super.key, required this.ops, required this.template});
  final OperationsController ops;
  final Json template;
  @override
  State<StartManualWork> createState() => _StartManualWorkState();
}

class _StartManualWorkState extends State<StartManualWork> {
  final subject = TextEditingController();
  late final String requestId =
      'work-${DateTime.now().microsecondsSinceEpoch}-${Random.secure().nextInt(1 << 30)}';
  late final actor = widget.ops.actorId;
  late final workspace = widget.ops.data?['workspaceId'];
  String? submitted, error;
  bool saving = false;
  @override
  void dispose() {
    subject.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if (saving ||
        widget.ops.actorId != actor ||
        widget.ops.data?['workspaceId'] != workspace) {
      return;
    }
    if (subject.text.trim().isEmpty) {
      setState(() => error = '제품·배치 이름을 입력해 주세요.');
      return;
    }
    submitted ??= subject.text.trim();
    setState(() {
      saving = true;
      error = null;
    });
    final ok = await widget.ops.act('start_manual_work', {
      'templateId': widget.template['id'],
      'requestId': requestId,
      'subject': submitted,
    });
    if (!mounted) return;
    setState(() {
      saving = false;
      error = ok ? null : widget.ops.error;
    });
    if (ok) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) => AppEditorScaffold(
    title: '작업 시작',
    body: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text('${widget.template['title']}', style: AppText.title),
        const SizedBox(height: 16),
        const Information('이번 제품·배치에 필요한 체크리스트가 업무에 추가돼요. 다른 배치는 따로 시작하세요.'),
        TextField(
          controller: subject,
          enabled: !saving && submitted == null,
          maxLength: 80,
          decoration: const InputDecoration(
            labelText: '제품·배치 또는 로트',
            hintText: '예: 오전 육수 1차 · 10L',
          ),
        ),
        if (widget.template['settings']?['operatingStandard']
            case final String standard)
          Text(standard),
        if (error != null) Information(error!),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: saving || widget.ops.readOnly ? null : save,
          child: Text(
            saving
                ? '만들고 있어요'
                : submitted == null
                ? '체크리스트 만들기'
                : '같은 작업 다시 요청',
          ),
        ),
      ],
    ),
  );
}
