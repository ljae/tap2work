import 'dart:convert';

typedef ChecklistJson = Map<String, dynamic>;
const checklistFolderLimit = 30;
const checklistTaskLimit = 150;
const checklistStepLimit = 30;

/// Validates the entire draft, including fields not mounted in a scrolling form.
String? checklistTaskIssue(ChecklistJson task) {
  bool valid(dynamic value, int max) =>
      value is String && value.trim().isNotEmpty && value.length <= max;
  if (!valid(task['title'], 100)) return '업무 이름을 1~100자로 입력해 주세요.';
  final steps = task['steps'];
  if (steps is! List || steps.isEmpty || steps.length > checklistStepLimit) {
    return '행위는 1~30개로 구성해 주세요.';
  }
  for (final (index, step) in steps.indexed) {
    if (step is! Map || !valid(step['title'], 100)) {
      return '행위 ${index + 1}의 이름을 입력해 주세요.';
    }
    if (!valid(step['manual'], 700)) {
      return '행위 ${index + 1}의 매뉴얼을 1~700자로 입력해 주세요.';
    }
    if (step['tip'] is! String || (step['tip'] as String).length > 400) {
      return '행위 ${index + 1}의 노하우는 400자 이내로 적어 주세요.';
    }
  }
  return null;
}

String libraryTaskId(ChecklistJson industry, ChecklistJson task) =>
    'library-${industry['id']}-${task['id']}';
List<ChecklistJson> missingIndustryTasks(
  ChecklistJson industry,
  List<ChecklistJson> templates,
) {
  final existing = templates.map((t) => t['id']).toSet();
  return (industry['tasks'] as List)
      .cast<ChecklistJson>()
      .where((t) => !existing.contains(libraryTaskId(industry, t)))
      .toList();
}

class ChecklistImportPlan {
  const ChecklistImportPlan({
    required this.folderId,
    required this.folder,
    required this.tasks,
  });
  final String folderId;
  final ChecklistJson? folder;
  final List<ChecklistJson> tasks;
}

/// Copies only selected missing tasks. Existing store edits remain untouched.
ChecklistImportPlan planChecklistImport({
  required ChecklistJson industry,
  required Set<String> selectedTaskIds,
  required List<ChecklistJson> templates,
  required List<ChecklistJson> folders,
  required String newFolderId,
  required String zoneId,
}) {
  final missing = missingIndustryTasks(
    industry,
    templates,
  ).where((t) => selectedTaskIds.contains(t['id'])).toList();
  if (missing.isEmpty) throw const FormatException('가져올 업무를 하나 이상 선택해 주세요.');
  if (templates.length + missing.length > checklistTaskLimit) {
    throw const FormatException('업무는 최대 150개예요. 가져올 업무 수를 줄여 주세요.');
  }
  final industryIds = (industry['tasks'] as List)
      .cast<ChecklistJson>()
      .map((t) => libraryTaskId(industry, t))
      .toSet();
  final previousFolderIds = templates
      .where((t) => industryIds.contains(t['id']))
      .map((t) => t['folderId'])
      .toSet();
  final existingFolder =
      folders.where((f) => previousFolderIds.contains(f['id'])).firstOrNull ??
      folders.where((f) => f['name'] == industry['name']).firstOrNull;
  if (existingFolder == null && folders.length >= checklistFolderLimit) {
    throw const FormatException('폴더는 최대 30개예요. 사용하지 않는 폴더를 먼저 정리해 주세요.');
  }
  final folderId = existingFolder?['id'] as String? ?? newFolderId;
  return ChecklistImportPlan(
    folderId: folderId,
    folder: existingFolder == null
        ? {'id': folderId, 'name': industry['name']}
        : null,
    tasks: [
      for (final task in missing)
        {
          ...(jsonDecode(jsonEncode(task)) as ChecklistJson),
          'id': libraryTaskId(industry, task),
          'folderId': folderId,
          'requiredRole': 'all',
          'zone': zoneId,
        },
    ],
  );
}
