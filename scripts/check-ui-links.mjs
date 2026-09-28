import { readFile } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const root = fileURLToPath(new URL('..', import.meta.url));
const document = await readFile(path.join(root, 'docs/UI_SETTINGS_RELATIONSHIP_MAP.md'), 'utf8');
const contracts = [
  ['E01', 'app/lib/main.dart', "defaultValue: true", 'app/lib/ui/cloud_workspace.dart', 'CloudWorkspace'],
  ['E02', 'scripts/build-site.mjs', 'review-data', 'app/lib/state/operations_controller.dart', 'readOnly'],
  ['S01', 'app/lib/ui/workplace_screens.dart', "'save_workplace_parts'", 'developer/workplace.mjs', "case 'save_workplace_parts'"],
  ['S02', 'app/lib/ui/workplace_screens.dart', "'save_staff_profile'", 'developer/workplace.mjs', "case 'save_staff_profile'"],
  ['S03', 'app/lib/ui/workplace_screens.dart', "'save_workplace_day'", 'developer/workplace.mjs', "case 'save_workplace_day'"],
  ['S04', 'app/lib/ui/calendar_screen.dart', "'save_roster_slot'", 'developer/workplace.mjs', "'save_roster_slot'"],
  ['S06', 'app/lib/ui/workplace_screens.dart', "'save_order_system'", 'developer/workplace.mjs', "case 'save_order_system'"],
  ['S07', 'app/lib/ui/workplace_screens.dart', "'save_workplace_permissions'", 'developer/workplace.mjs', "case 'save_workplace_permissions'"],
  ['S08', 'app/lib/ui/store_profile_screen.dart', "'save_store_profile'", 'developer/operations.mjs', "case 'save_store_profile'"],
  ['S09', 'app/lib/ui/payroll_settings_screen.dart', "'save_payroll_settings'", 'developer/staff.mjs', "case 'save_payroll_settings'"],
  ['S11', 'app/lib/ui/checklist_editor.dart', 'class ChecklistEditor', 'developer/operations.mjs', "case 'save_checklists'"],
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
if (errors) process.exit(1);
console.log(`UI/settings relationship contract: ${contracts.length} links and manual route verified.`);
