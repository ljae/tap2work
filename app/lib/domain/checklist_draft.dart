import 'dart:convert';

typedef ChecklistJson = Map<String, dynamic>;
const checklistFolderLimit = 30;
const checklistTaskLimit = 150;
const checklistStepLimit = 30;

/// Time buckets are labels, not clock ranges; the server accepts the same list.
const checklistSlots = ['오픈', '준비', '피크', '브레이크', '마감'];
const checklistRoles = {
  'all': '누구나',
  'crew': '크루',
  'cook': '조리 담당',
  'manager': '매니저',
  'owner': '사장님',
};

/// Validates one group, including activities not mounted in a scrolling form.
String? checklistTaskIssue(ChecklistJson task) {
  bool valid(dynamic value, int max) =>
      value is String && value.trim().isNotEmpty && value.length <= max;
  if (!valid(task['title'], 100)) return '그룹 이름을 1~100자로 입력해 주세요.';
  final steps = task['steps'];
  if (steps is! List || steps.isEmpty || steps.length > checklistStepLimit) {
    return '활동은 1~30개로 구성해 주세요.';
  }
  for (final (index, step) in steps.indexed) {
    if (step is! Map || !valid(step['title'], 100)) {
      return '활동 ${index + 1}의 이름을 입력해 주세요.';
    }
    if (!valid(step['manual'], 700)) {
      return '활동 ${index + 1}의 매뉴얼을 1~700자로 입력해 주세요.';
    }
    for (final field in ['videoUrl', 'imageUrl']) {
      final value = step[field] ?? '';
      if (value is! String) return '영상·사진 링크를 확인해 주세요.';
      if (value.isEmpty) continue;
      final uri = Uri.tryParse(value);
      if (value.length > 2000 ||
          uri == null ||
          uri.scheme != 'https' ||
          uri.host.isEmpty ||
          uri.userInfo.isNotEmpty) {
        return 'HTTPS 영상·사진 링크를 입력해 주세요.';
      }
    }
    if (step['tip'] is! String || (step['tip'] as String).length > 400) {
      return '활동 ${index + 1}의 노하우는 400자 이내로 적어 주세요.';
    }
  }
  return null;
}

/// Validates one activity on its own so an inline editor can block a bad apply.
String? checklistStepIssue(ChecklistJson step) => checklistTaskIssue({
  'title': '그룹',
  'steps': [step],
})?.replaceFirst('활동 1의 ', '');

/// First problem anywhere in the draft, prefixed with the group so the owner can find it.
String? checklistDraftIssue(List<ChecklistJson> templates) {
  for (final task in templates) {
    final issue = checklistTaskIssue(task);
    if (issue != null) {
      final name = (task['title'] as String?)?.trim();
      return name == null || name.isEmpty ? issue : '「$name」 · $issue';
    }
  }
  return null;
}

/// Moves one activity into another group inside the draft. Returns a reason when it cannot.
String? moveChecklistStep({
  required List<ChecklistJson> templates,
  required String fromTaskId,
  required String stepId,
  required String toTaskId,
  int? index,
}) {
  final from = templates.where((t) => t['id'] == fromTaskId).firstOrNull;
  final to = templates.where((t) => t['id'] == toTaskId).firstOrNull;
  if (from == null || to == null) return '그룹을 찾지 못했어요.';
  final source = (from['steps'] as List).cast<ChecklistJson>();
  final step = source.where((s) => s['id'] == stepId).firstOrNull;
  if (step == null) return '활동을 찾지 못했어요.';
  if (from == to) return null;
  if (source.length == 1) return '그룹에는 활동이 하나 이상 남아야 해요.';
  final target = (to['steps'] as List).cast<ChecklistJson>();
  if (target.length >= checklistStepLimit) return '한 그룹의 활동은 최대 30개예요.';
  source.remove(step);
  target.insert(
    index == null ? target.length : index.clamp(0, target.length),
    step,
  );
  from['steps'] = source;
  to['steps'] = target;
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
/// Library place/role hints apply only when this store has that place.
ChecklistImportPlan planChecklistImport({
  required ChecklistJson industry,
  required Set<String> selectedTaskIds,
  required List<ChecklistJson> templates,
  required List<ChecklistJson> folders,
  required String newFolderId,
  required List<String> zoneIds,
}) {
  final missing = missingIndustryTasks(
    industry,
    templates,
  ).where((t) => selectedTaskIds.contains(t['id'])).toList();
  if (missing.isEmpty) throw const FormatException('가져올 그룹을 하나 이상 선택해 주세요.');
  if (templates.length + missing.length > checklistTaskLimit) {
    throw const FormatException('그룹은 최대 150개예요. 가져올 그룹 수를 줄여 주세요.');
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
          'emoji': task['emoji'] ?? '📝',
          'requiredRole': checklistRoles.containsKey(task['requiredRole'])
              ? task['requiredRole']
              : 'all',
          'zone': zoneIds.contains(task['zone'])
              ? task['zone']
              : (zoneIds.firstOrNull ?? 'entrance'),
        },
    ],
  );
}
