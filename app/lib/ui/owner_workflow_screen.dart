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
      '${row['title']} ${(row['steps'] as List? ?? []).map((s) => s['title']).join(' ')}'
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
        title: '${row['title']}',
        footer: AppSheetFooter(
          children: [
            FilledButton(
              onPressed: () => Navigator.pop(c, true),
              child: const Text('내용을 검토했어요 · 선택'),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Information(
              pending
                  ? '사장님 확인 전에는 크루 검색과 자동 할 일에 나오지 않아요.'
                  : flow['assumption'] as String? ?? '',
            ),
            if (row['catalogUpdate'] == true)
              const Information('공용 원본의 새 내용이에요. 검토 후 등록하면 앞으로 생성되는 업무에 적용돼요.'),
            if (row['replacesExisting'] == true)
              const Information(
                '기존 같은 매뉴얼을 상세 내용으로 보완해요. 오늘 기록은 유지하고 새 내용은 내일부터 적용해요.',
              ),
            for (final step in (row['steps'] as List).cast<Json>()) ...[
              const SizedBox(height: 24),
              Text('${step['title']}', style: AppText.section),
              const SizedBox(height: 12),
              Text('${step['manual']}', style: AppText.body),
              if ('${step['tip'] ?? ''}'.isNotEmpty) ...[
                const SizedBox(height: 12),
                Information('${step['tip']}'),
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
        error = '매장 내용이 변경됐어요. 선택한 매뉴얼을 다시 검토해 주세요.';
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
        error = ops.error ?? '저장하지 못했어요. 다시 시도해 주세요.';
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
        title: '사장님의 운영 준비',
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
                    ? '등록하고 있어요'
                    : stage == 0
                    ? '확인 후 ${selected.length}개 우리 매장에 등록'
                    : stage == 1
                    ? '내일 할 일 미리보기'
                    : '오늘 업무로 가기',
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
                    label: Text(['1 매뉴얼 검토', '2 반영 확인', '3 내일 준비'][i]),
                    selected: stage == i,
                    onSelected: saving
                        ? null
                        : (_) => setState(() => stage = i),
                    chipAnimationStyle: AppMotion.chipStyle(context),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            if (!valid) const Information('매장 또는 권한이 변경됐어요. 화면을 닫고 다시 열어 주세요.'),
            if (error != null) Information(error!),
            AppContentTransition(
              trigger: stage,
              child: KeyedSubtree(
                key: ValueKey(stage),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: stage == 0
                      ? [
                          const Text(
                            '기본으로 시작하고,\n우리 매장에 맞춰요.',
                            style: AppText.section,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            '내용을 열어 검토한 매뉴얼만 선택돼요. 등록하면 크루가 검색할 수 있고, 루틴은 일정에 맞춰 할 일로 들어가요. 세부 설정은 나중에 바꿔도 돼요.',
                            style: AppText.body,
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            decoration: const InputDecoration(
                              labelText: '검토할 매뉴얼 찾기',
                              hintText: '전화, 고객, 마감',
                              prefixIcon: Icon(Icons.search),
                            ),
                            onChanged: (v) => setState(() => query = v),
                          ),
                          const SizedBox(height: 16),
                          if (pending.isNotEmpty)
                            const Eyebrow('가져온 매뉴얼 · 사장님 확인 대기'),
                          for (final row in pending) manualCard(row, true),
                          if (candidates.isNotEmpty)
                            const Eyebrow('소규모 식당 기본 제안 · 24개 매뉴얼'),
                          for (final row in candidates) manualCard(row, false),
                          if (pending.isEmpty && candidates.isEmpty)
                            const Information(
                              '해당하는 검토 항목이 없어요. 검색어를 바꾸거나 매뉴얼에서 등록한 내용을 다듬어 주세요.',
                            ),
                        ]
                      : stage == 1
                      ? [
                          const Text('설정은 여기에 반영돼요', style: AppText.section),
                          const SizedBox(height: 16),
                          effect(
                            Icons.search,
                            '매뉴얼 확인 → 매뉴얼 검색',
                            '등록한 응대·전화·작업 방법을 모든 크루가 같은 내용으로 찾아봐요.',
                            '매뉴얼에서 보기',
                            () => Navigator.pop(context, 'manual'),
                          ),
                          effect(
                            Icons.today_outlined,
                            '루틴 일정 → 업무의 할 일',
                            '매일은 영업일마다, 매주·매월은 예정일에 들어가요. 휴무일이면 다음 영업일로 넘어가요.',
                            '오늘 업무에서 보기',
                            () => Navigator.pop(context, 'work'),
                          ),
                          effect(
                            Icons.people_outline,
                            '담당 설정 → 배정된 크루',
                            '파트·교대에 맞는 근무 크루를 연결해요. 담당이 비어 있으면 내일 미리보기에서 확인해 주세요.',
                            '내일 담당 확인',
                            () => setState(() => stage = 2),
                          ),
                          const Information(
                            '영업시간·크루·기존 기록은 유지해요. 필요한 파트가 없으면 담당을 직접 지정할 수 있어요.',
                          ),
                        ]
                      : [
                          Text(
                            '${flow['date'] ?? ''}\n내일 할 일을 먼저 확인해요',
                            style: AppText.section,
                          ),
                          const SizedBox(height: 12),
                          const Information(
                            '예정 업무예요. 여기서 완료 기록은 만들지 않아요. 담당·일정을 바꾸면 내일부터 앞으로 반복되는 업무에 적용돼요.',
                          ),
                          if (flow['closed'] == true)
                            const Information(
                              '내일은 휴무일이에요. 정기 업무는 다음 영업일로 이동해요.',
                            ),
                          if (plans.isEmpty)
                            const Information(
                              '내일 예정된 루틴이 없어요. 매뉴얼 등록과 반복 일정을 확인해 주세요.',
                            ),
                          for (final plan in plans) planCard(plan),
                        ],
                ),
              ),
            ),
          ],
        ),
      );
    },
  );

  Widget manualCard(Json row, bool pending) {
    final key = '${pending ? 'pending' : 'starter'}:${row['id']}';
    final settings = pending ? row['settings'] as Json? ?? {} : row;
    final recurrence = settings['recurrence'] as Json? ?? {};
    final usage = settings['usage'] ?? 'reference';
    final label = usage != 'routine'
        ? '필요할 때 보는 방법'
        : recurrence['mode'] == 'monthly'
        ? '매월 ${recurrence['monthDay']}일'
        : recurrence['mode'] == 'weekly'
        ? '매주 지정 요일'
        : '매 영업일';
    return AppCard(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Icon(
          selected.contains(key)
              ? Icons.check_circle
              : Icons.menu_book_outlined,
          color: selected.contains(key) ? AppColors.green : AppColors.muted,
        ),
        title: Text('${row['title']}'),
        subtitle: Text('$label · ${(row['steps'] as List).length}개 행동'),
        trailing: selected.contains(key)
            ? IconButton(
                tooltip: '선택 해제',
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

  Widget planCard(Json plan) {
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
            Text('${plan['title']}', style: AppText.section),
            const SizedBox(height: 8),
            Text(
              '${plan['timeBandName'] ?? plan['slot']} · ${plan['stepCount']}개 행동',
              style: AppText.caption,
            ),
            const SizedBox(height: 8),
            Text(
              names.isEmpty ? '담당 크루 확인이 필요해요' : '담당 $names',
              style: AppText.body,
            ),
            if (plan['scheduled'] == true)
              const Text('내일부터 변경 예약됨', style: AppText.caption),
            Wrap(
              spacing: 8,
              children: [
                TextButton(
                  onPressed: () => settings(plan),
                  child: const Text('담당·반복 일정 변경'),
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
                  child: const Text('매뉴얼 다듬기'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
