import 'package:flutter/material.dart';
import '../state/operations_controller.dart';
import 'components.dart';
import 'manual_tap_editor.dart';

class ManualMarketScreen extends StatefulWidget {
  const ManualMarketScreen({super.key, required this.ops, this.folderId});
  final OperationsController ops;
  final String? folderId;
  @override
  State<ManualMarketScreen> createState() => _ManualMarketScreenState();
}

class _ManualMarketScreenState extends State<ManualMarketScreen> {
  late final int revision;
  late final String actor;
  late final Object? workspace;
  @override
  void initState() {
    super.initState();
    revision = widget.ops.data?['revision'] ?? 0;
    actor = widget.ops.actorId;
    workspace = widget.ops.data?['workspaceId'];
  }

  late final Json catalog = widget.ops.data?['manualCatalog'] ?? {};
  late String folder = widget.folderId ?? 'general';
  final selected = <String>{};
  String query = '';
  String? error;
  bool saving = false;
  final operationId = 'import-${DateTime.now().microsecondsSinceEpoch}';
  Future<void> save() async {
    if (widget.ops.actorId != actor ||
        widget.ops.data?['workspaceId'] != workspace ||
        !widget.ops.canEditTasks) {
      setState(() => error = '권한 또는 매장이 변경됐어요. 다시 열어 주세요.');
      return;
    }
    setState(() => saving = true);
    final ok = await widget.ops.act('import_market_taps', {
      'revision': revision,
      'operationId': operationId,
      'releaseId': catalog['releaseId'],
      'folderId': folder,
      'sourceIds': selected.toList(),
    });
    if (!mounted) return;
    setState(() => saving = false);
    if (ok) {
      final messenger = ScaffoldMessenger.of(context);
      Navigator.pop(context);
      messenger.showSnackBar(
        const SnackBar(
          content: Text('가져왔어요. TAP 상세에서 파트·시간대와 사용 여부를 설정해 주세요.'),
        ),
      );
    } else {
      setState(() => error = widget.ops.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final entries = (catalog['entries'] as List? ?? []).cast<Json>();
    return AppEditorScaffold(
      title: '매뉴얼 마켓',
      footer: AppSheetFooter(
        children: [
          const Text(
            '공용 연결 TAP은 자동 업데이트돼요. 가져온 뒤 파트·시간대를 설정하고 사용을 켜 주세요.',
            style: AppText.caption,
          ),
          if (error != null) Information(error!),
          FilledButton(
            onPressed: saving || widget.ops.readOnly || selected.isEmpty
                ? null
                : save,
            child: Text(saving ? '가져오는 중…' : '선택한 ${selected.length}개 가져오기'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          TextField(
            decoration: const InputDecoration(
              labelText: '업종·TAP·Task 검색',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (v) => setState(() => query = v.trim().toLowerCase()),
          ),
          const SizedBox(height: 16),
          AppPicker<String>(
            label: '가져올 그룹',
            value: folder,
            items: widget.ops
                .rows('checklistFolders')
                .map(
                  (f) => DropdownMenuItem(
                    value: f['id'] as String,
                    child: Text(f['name']),
                  ),
                )
                .toList(),
            onChanged: saving ? null : (v) => setState(() => folder = v!),
          ),
          const SizedBox(height: 16),
          if (entries.isEmpty)
            const Information('공용 목록을 불러오지 못했어요. 매뉴얼 목록을 새로고침하고 다시 열어 주세요.'),
          for (final entry in entries.where(
            (e) =>
                '${e['collectionName']} ${e['title']} ${(e['steps'] as List).map((s) => s['title']).join(' ')}'
                    .toLowerCase()
                    .contains(query),
          ))
            Builder(
              builder: (context) {
                final installed = (entry['installed'] as List? ?? [])
                    .cast<Json>();
                final linked = installed
                    .where((v) => v['mode'] == 'linked')
                    .firstOrNull;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Surface(
                    padding: const EdgeInsets.all(8),
                    child: ExpansionTile(
                      key: ValueKey('market-${entry['sourceId']}'),
                      tilePadding: const EdgeInsets.symmetric(horizontal: 8),
                      leading: Checkbox(
                        value:
                            linked != null ||
                            selected.contains(entry['sourceId']),
                        onChanged: linked != null || saving
                            ? null
                            : (v) => setState(() {
                                if (v == true) {
                                  selected.add(entry['sourceId']);
                                } else {
                                  selected.remove(entry['sourceId']);
                                }
                              }),
                      ),
                      title: Text(entry['title']),
                      subtitle: Text(
                        '${entry['collectionName']} · ${(entry['steps'] as List).length}개 Task\n${linked != null
                            ? '공용 연결 · 자동 업데이트'
                            : installed.isNotEmpty
                            ? '개인화 사본 사용 중'
                            : '가져오기 가능'}',
                        style: AppText.caption,
                      ),
                      children: [
                        for (final step
                            in (entry['steps'] as List).cast<Json>())
                          ListTile(
                            title: Text(step['title']),
                            subtitle: Text(
                              '${step['manual']}\n${step['tip'] ?? ''}',
                            ),
                          ),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            '자료 검토일 ${entry['reviewedAt']} · ${entry['basis']}',
                            style: AppText.caption,
                          ),
                        ),
                        if (linked != null)
                          TextButton(
                            onPressed: () => showAppSheet(
                              context,
                              builder: (_) => ManualTapEditor(
                                ops: widget.ops,
                                templateId: linked['templateId'],
                              ),
                            ),
                            child: const Text('내 TAP 상세 열기'),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
