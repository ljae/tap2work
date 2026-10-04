import { readFile } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const root = fileURLToPath(new URL('..', import.meta.url));
const document = await readFile(path.join(root, 'docs/UI_SETTINGS_RELATIONSHIP_MAP.md'), 'utf8');
const contracts = [
  ['S42', 'app/lib/ui/calendar_screen.dart', 'attendanceHistory()', 'app/lib/domain/attendance_history.dart', 'attendanceSessions'],
  ['S43', 'app/lib/ui/workplace_screens.dart', "'save_attendance_preferences'", 'developer/workplace.mjs', "case 'save_attendance_preferences'"],
  ['S35', 'app/lib/ui/tap_settings_screen.dart', "'assignmentScopeVersion': 2", 'developer/task_settings.mjs', 'assertContentOnly(step)'],
  ['S40', 'app/lib/ui/tap_settings_screen.dart', "'split_tap_policy'", 'developer/operations.mjs', "case 'split_tap_policy'"],
  ['S37', 'app/lib/ui/workplace_screens.dart', "'defaultAssignmentsEnabled': true", 'developer/default_assignments.mjs', 'ensureDefaultAssignments'],
  ['S39', 'app/lib/ui/calendar_screen.dart', "'save_calendar_day'", 'developer/workplace.mjs', "input.action === 'save_calendar_day'"],
  ['S28', 'app/lib/ui/crew_pattern_screen.dart', "'save_crew_pattern'", 'developer/crew_patterns.mjs', "'apply_crew_pattern'"],
  ['S29', 'app/lib/ui/shift_change_panel.dart', "'request_shift_change'", 'developer/shift_requests.mjs', "'review_shift_change'"],
  ['E07', 'app/lib/ui/cloud_workspace.dart', "'setup_shared_employee'", 'developer/supabase_backend.mjs', "query.get('view') === 'employee'"],
  ['S30', 'app/lib/ui/calendar_screen.dart', 'KoreanHolidays', 'app/lib/domain/korean_holidays.dart', 'https://holidays.hyunbin.page/'],

  ['U03', 'app/lib/ui/direct_edit.dart', 'onLongPress:', 'app/lib/ui/calendar_screen.dart', 'DirectEditFrame('],
  ['S25', 'app/lib/ui/tap_workspace.dart', "'edit_work_node'", 'developer/operations.mjs', "case 'edit_work_node'"],
  ['S26', 'app/lib/ui/manual_workspace.dart', "'edit_manual_node'", 'developer/operations.mjs', "case 'edit_manual_node'"],
  ['S27', 'app/lib/ui/calendar_screen.dart', "'delete_roster_slot'", 'developer/workplace.mjs', "'delete_roster_slot'"],
  ['S22', 'app/lib/ui/task_step_editor.dart', "'save_task_step'", 'developer/operations.mjs', "case 'save_task_step'"],
  ['S23', 'app/lib/ui/tap_workspace.dart', "Text('Task 추가')", 'app/lib/ui/task_step_editor.dart', 'class TaskStepEditor'],
  ['S24', 'app/lib/state/operations_controller.dart', 'get canEditTasks', 'developer/operations.mjs', 'result.canEditTasks'],
  ['E06', 'app/lib/main.dart', 'AppStartup', 'app/web/index.html', 'flutter-first-frame'],
  ['U01', 'app/lib/ui/design_system.dart', 'class AppEditorScaffold', 'app/lib/ui/checklist_editor.dart', 'AppSheetFooter('],
  ['U02', 'app/lib/ui/design_system.dart', 'class AppFormSection', 'app/lib/ui/payroll_settings_screen.dart', 'AppFormSection('],
  ['E01', 'app/lib/main.dart', "defaultValue: false", 'app/lib/ui/cloud_workspace.dart', 'CloudWorkspace'],
  ['E02', 'scripts/build-site.mjs', 'review-data', 'app/lib/state/operations_controller.dart', 'readOnly'],
  ['S01', 'app/lib/ui/workplace_screens.dart', "'save_workplace_parts'", 'developer/workplace.mjs', "case 'save_workplace_parts'"],
  ['S02', 'app/lib/ui/workplace_screens.dart', "'save_staff_profile'", 'developer/workplace.mjs', "case 'save_staff_profile'"],
  ['S03', 'app/lib/ui/workplace_screens.dart', "'save_workplace_hours'", 'developer/workplace.mjs', "case 'save_workplace_hours'"],
  ['S04', 'app/lib/ui/calendar_screen.dart', "'save_roster_slot'", 'developer/workplace.mjs', "'save_roster_slot'"],
  ['S06', 'app/lib/ui/workplace_screens.dart', "'save_order_system'", 'developer/workplace.mjs', "case 'save_order_system'"],
  ['S07', 'app/lib/ui/workplace_screens.dart', "'save_workplace_permissions'", 'developer/workplace.mjs', "case 'save_workplace_permissions'"],
  ['S08', 'app/lib/ui/store_profile_screen.dart', "'save_store_profile'", 'developer/operations.mjs', "case 'save_store_profile'"],
  ['S09', 'app/lib/ui/payroll_settings_screen.dart', "'save_payroll_settings'", 'developer/staff.mjs', "case 'save_payroll_settings'"],
  ['S11', 'app/lib/ui/tap_workspace.dart', 'DirectEditFrame(', 'developer/operations.mjs', "case 'edit_work_node'"],
  ['S12', 'app/lib/ui/manual_workspace.dart', 'ManualTaskEditor(', 'app/lib/ui/checklist_editor.dart', 'class ManualTaskEditor'],
  ['S13', 'app/lib/ui/manual_workspace.dart', 'initialTemplateId:', 'app/lib/ui/tap_settings_screen.dart', "'save_tap_settings'"],
  ['S14', 'app/lib/ui/manual_workspace.dart', "'move_manual_node'", 'developer/operations.mjs', "case 'move_manual_node'"],
  ['S16', 'app/lib/ui/catalog_editor.dart', "'save_inventory_item'", 'developer/operations.mjs', "case 'save_inventory_item'"],
  ['S18', 'app/lib/ui/floor_plan.dart', "'save_layout'", 'developer/operations.mjs', "case 'save_layout'"],
];
let errors = 0;
for (const [id, from, trigger, to, target] of contracts) {
  if (!document.includes(`| ${id} |`)) {
    console.error(`${id}: missing relationship row`);
    errors++;
  }
  for (const [filename, needle] of [[from, trigger], [to, target]]) {
    const source = await readFile(path.join(root, filename), 'utf8');
    if (!source.includes(needle)) {
      console.error(`${id}: ${filename} no longer contains ${needle}`);
      errors++;
    }
  }
}

// The actual button path is also covered by a widget test. Keep this cheap
// static guard for code changes that accidentally reconnect it to the board.
const manual = await readFile(path.join(root, 'app/lib/ui/manual_workspace.dart'), 'utf8');
const editButton = manual.match(/label: const Text\('매뉴얼 편집'\)[\s\S]*?if \(mounted\) setState\(\(\) => sync\(force: true\)\);/);
if (!editButton || !editButton[0].includes('ManualTaskEditor(') || editButton[0].includes('ChecklistEditor(')) {
  console.error('S12: manual edit must open ManualTaskEditor for the selected Task');
  errors++;
}
const board = await readFile(path.join(root, 'app/lib/ui/tap_workspace.dart'), 'utf8');
if (board.includes("Text('보드 편집')") || manual.includes("'구조 편집'") || board.includes("Text('TAP 설정')") || !board.includes('buildDefaultDragHandles: false')) {
  console.error('Board must not expose global TAP settings or overlapping default drag handles');
  errors++;
}
if (!manual.includes("Text('TAP 설정')") || manual.includes("initialStepId: selected['sourceStepId']")) {
  console.error('S13: manual settings must target the parent TAP without Task allocation');
  errors++;
}
if (errors) process.exit(1);
console.log(`UI/settings relationship contract: ${contracts.length} links and manual route verified.`);
