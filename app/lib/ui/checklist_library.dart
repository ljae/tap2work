import '../l10n/app_localizations.dart';
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
    sheetAnimationStyle: AppMotion.panelStyle(context),
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
              Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 4),
                child: Text(
                  context.t('ui.audit1052'),
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(context.t('ui.audit1053')),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    labelText: context.t('ui.audit471'),
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
                          context.t(
                            'ui.audit1054',
                            args: {
                              'p0': _rows(industry['tasks']).length,
                              'p1':
                                  industry['basis'] ??
                                  context.t('ui.audit1229'),
                            },
                          ),
                        ),
                        children: [
                          for (final task in _rows(industry['tasks']))
                            ExpansionTile(
                              key: ValueKey(libraryTaskId(industry, task)),
                              leading: Checkbox(
                                semanticLabel: context.t(
                                  'ui.audit1055',
                                  args: {'p0': task['title']},
                                ),
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
                              title: Text(task['title']),
                              subtitle: Text(
                                templates.any(
                                      (t) =>
                                          t['id'] ==
                                          libraryTaskId(industry, task),
                                    )
                                    ? context.t('ui.audit1056')
                                    : context.t(
                                        'ui.audit1057',
                                        args: {
                                          'p0': task['slot'],
                                          'p1': _rows(task['steps']).length,
                                        },
                                      ),
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
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ),
                                PressBounce(
                                  child: FilledButton.icon(
                                    onPressed:
                                        selections[industry['id']]!.isEmpty
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
                                                () =>
                                                    importError = error.message,
                                              );
                                            }
                                          },
                                    icon: const Icon(Icons.add),
                                    label: Text(
                                      context.t(
                                        'ui.audit1058',
                                        args: {
                                          'p0': selections[industry['id']]!
                                              .length,
                                        },
                                      ),
                                    ),
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
