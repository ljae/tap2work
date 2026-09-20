import 'package:flutter/material.dart';
import '../domain/checklist_draft.dart';
import '../state/operations_controller.dart';
import 'components.dart';

List<Json> _rows(dynamic value) => (value as List? ?? []).cast<Json>();

/// Built-in industry collections. Only missing groups can be selected; store edits stay intact.
Future<void> showChecklistLibrary(
  BuildContext context, {
  required Json catalog,
  required List<Json> templates,
  required List<Json> folders,
  required List<String> zoneIds,
  required String Function() newFolderId,
  required void Function(ChecklistImportPlan plan) onImport,
}) async {
  final industries = _rows(catalog['industries']);
  final selections = <String, Set<String>>{
    for (final industry in industries)
      industry['id']: missingIndustryTasks(
        industry,
        templates,
      ).map((t) => t['id'] as String).toSet(),
  };
  String query = '';
  String? importError;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (sheetContext) => StatefulBuilder(
      builder: (sheetContext, update) => SizedBox(
        height: MediaQuery.sizeOf(sheetContext).height * .88,
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
          ),
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 4),
                child: Text(
                  '업종별 기본 체크리스트',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text('필요한 그룹만 골라 가져오세요. 이미 수정한 그룹은 그대로 유지해요.'),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    labelText: '업종·그룹 검색',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (v) => update(() => query = v.trim()),
                ),
              ),
              if (importError != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Information(importError!),
                ),
              Expanded(
                child: ListView(
                  children: [
                    for (final industry in industries.where(
                      (i) =>
                          '${i['name']} ${_rows(i['tasks']).map((t) => t['title']).join(' ')}'
                              .contains(query),
                    ))
                      ExpansionTile(
                        key: ValueKey('industry-${industry['id']}'),
                        title: Text(industry['name']),
                        subtitle: Text(
                          '${_rows(industry['tasks']).length}개 그룹 · ${industry['basis'] ?? '출처를 참고한 운영 제안'}',
                        ),
                        children: [
                          for (final task in _rows(industry['tasks']))
                            ExpansionTile(
                              key: ValueKey(libraryTaskId(industry, task)),
                              leading: Checkbox(
                                semanticLabel: '${task['title']} 가져오기',
                                value: selections[industry['id']]!.contains(
                                  task['id'],
                                ),
                                onChanged:
                                    templates.any(
                                      (t) =>
                                          t['id'] ==
                                          libraryTaskId(industry, task),
                                    )
                                    ? null
                                    : (value) => update(() {
                                        if (value == true) {
                                          selections[industry['id']]!.add(
                                            task['id'],
                                          );
                                        } else {
                                          selections[industry['id']]!.remove(
                                            task['id'],
                                          );
                                        }
                                        importError = null;
                                      }),
                              ),
                              title: Text(
                                '${task['emoji'] ?? '📝'} ${task['title']}',
                              ),
                              subtitle: Text(
                                templates.any(
                                      (t) =>
                                          t['id'] ==
                                          libraryTaskId(industry, task),
                                    )
                                    ? '이미 목록에 있어요 · 수정 내용 유지'
                                    : '${task['slot']} · ${_rows(task['steps']).length}개 활동 · 눌러서 매뉴얼 보기',
                              ),
                              childrenPadding: const EdgeInsets.all(16),
                              children: [
                                for (final step in _rows(task['steps']))
                                  ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    title: Text(step['title']),
                                    subtitle: Text(
                                      '${step['manual']}\n💡 ${step['tip']}',
                                    ),
                                  ),
                              ],
                            ),
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                for (final source
                                    in _rows(catalog['sources']).where(
                                      (s) => _rows(industry['tasks']).any(
                                        (t) => (t['sourceIds'] as List? ?? [])
                                            .contains(s['id']),
                                      ),
                                    ))
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: SelectableText(
                                      '참고: ${source['title']}\n${source['url']}',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ),
                                FilledButton.icon(
                                  onPressed: selections[industry['id']]!.isEmpty
                                      ? null
                                      : () {
                                          try {
                                            onImport(
                                              planChecklistImport(
                                                industry: industry,
                                                selectedTaskIds:
                                                    selections[industry['id']]!,
                                                templates: templates,
                                                folders: folders,
                                                newFolderId: newFolderId(),
                                                zoneIds: zoneIds,
                                              ),
                                            );
                                            Navigator.pop(sheetContext);
                                          } on FormatException catch (error) {
                                            update(
                                              () => importError = error.message,
                                            );
                                          }
                                        },
                                  icon: const Icon(Icons.add),
                                  label: Text(
                                    '선택한 ${selections[industry['id']]!.length}개 그룹 가져오기',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
