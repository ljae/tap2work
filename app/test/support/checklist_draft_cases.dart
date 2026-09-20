import 'dart:convert';
import 'package:tap2work/domain/checklist_draft.dart';

int runChecklistDraftChecks() {
  var checks = 0;
  void check(bool value, String message) {
    checks++;
    if (!value) throw StateError(message);
  }

  ChecklistJson task(String id) => {
    'id': id,
    'title': '업무 $id',
    'steps': [
      {'id': 'one', 'title': '준비', 'manual': '실물과 목록을 대조해요.', 'tip': ''},
      {
        'id': 'two',
        'title': '확인',
        'manual': '빠진 것이 없는지 봐요.',
        'tip': '완료 뒤 표시해요.',
      },
    ],
  };
  final draft = task('long');
  draft['steps'] = List.generate(
    30,
    (i) => {'id': 'step-$i', 'title': '행위 $i', 'manual': '완료 기준 확인', 'tip': ''},
  );
  check(
    checklistTaskIssue(draft) == null,
    'Complete 30-step draft must be accepted.',
  );
  draft['steps'][29]['manual'] = '   ';
  check(
    checklistTaskIssue(draft)?.contains('행위 30') == true,
    'The last, off-screen action must be validated.',
  );
  draft['steps'][29]['manual'] = '확인';
  draft['steps'][29]['tip'] = '길' * 401;
  check(
    checklistTaskIssue(draft)?.contains('400자') == true,
    'Oversized tips must not be silently lost.',
  );
  draft['steps'] = [];
  check(checklistTaskIssue(draft) != null, 'A task needs at least one action.');
  draft['steps'] = [null];
  check(
    checklistTaskIssue(draft) != null,
    'Malformed actions must be rejected.',
  );

  final industry = <String, dynamic>{
    'id': 'cafe',
    'name': '카페',
    'tasks': [task('open'), task('close')],
  };
  final local = <ChecklistJson>[
    {...task('library-cafe-open'), 'title': '내 매장 오픈', 'folderId': 'renamed'},
  ];
  final folders = <ChecklistJson>[
    {'id': 'general', 'name': '기본'},
    {'id': 'renamed', 'name': '우리 바'},
  ];
  final original = jsonEncode([industry, local, folders]);
  final missing = missingIndustryTasks(industry, local);
  check(
    missing.length == 1 && missing.single['id'] == 'close',
    'Deleted industry tasks must be available again.',
  );
  final plan = planChecklistImport(
    industry: industry,
    selectedTaskIds: {'open', 'close'},
    templates: local,
    folders: folders,
    newFolderId: 'new',
    zoneId: 'bar',
  );
  check(
    plan.folder == null && plan.folderId == 'renamed',
    'Reimport must reuse the renamed folder.',
  );
  check(
    plan.tasks.length == 1 && plan.tasks.single['id'] == 'library-cafe-close',
    'Existing custom tasks must not be duplicated.',
  );
  check(
    plan.tasks.single['zone'] == 'bar',
    'Import must carry the chosen store place.',
  );
  check(
    jsonEncode([industry, local, folders]) == original,
    'Import planning must not mutate either original.',
  );
  plan.tasks.single['steps'][0]['manual'] = '다른 안내';
  check(
    jsonEncode(industry) == jsonEncode(jsonDecode(original)[0]),
    'Imported manuals must be independent copies.',
  );
  check(
    local.single['title'] == '내 매장 오픈',
    'Custom titles must survive import.',
  );

  final fresh = planChecklistImport(
    industry: industry,
    selectedTaskIds: {'open'},
    templates: [],
    folders: folders,
    newFolderId: 'new',
    zoneId: 'bar',
  );
  check(
    fresh.tasks.length == 1 && fresh.folder?['id'] == 'new',
    'Selection imports only the requested task.',
  );
  final emptyFolder = planChecklistImport(
    industry: industry,
    selectedTaskIds: {'close'},
    templates: [],
    folders: [
      {'id': 'old', 'name': '카페'},
    ],
    newFolderId: 'new',
    zoneId: 'bar',
  );
  check(
    emptyFolder.folderId == 'old' && emptyFolder.folder == null,
    'Reuse the original empty industry folder.',
  );
  void rejected(ChecklistImportPlan Function() action, String fragment) {
    try {
      action();
      throw StateError('Expected import rejection: $fragment');
    } on FormatException catch (error) {
      check(error.message.contains(fragment), 'Unexpected limit message.');
    }
  }

  rejected(
    () => planChecklistImport(
      industry: industry,
      selectedTaskIds: {},
      templates: [],
      folders: folders,
      newFolderId: 'new',
      zoneId: 'bar',
    ),
    '하나 이상',
  );
  rejected(
    () => planChecklistImport(
      industry: industry,
      selectedTaskIds: {'open'},
      templates: [],
      folders: List.generate(30, (i) => {'id': '$i', 'name': '$i'}),
      newFolderId: 'new',
      zoneId: 'bar',
    ),
    '30개',
  );
  rejected(
    () => planChecklistImport(
      industry: industry,
      selectedTaskIds: {'close'},
      templates: List.generate(150, (i) => task('$i')),
      folders: folders,
      newFolderId: 'new',
      zoneId: 'bar',
    ),
    '150개',
  );
  return checks;
}
