import { tapOnly, assertContentOnly } from './tap_policy.mjs';
import { randomUUID } from 'node:crypto';
import { StoreError } from './store.mjs';
const fail = message => { throw new StoreError(message, 400); };
const get = (rows, id, label) => rows.find(row => row.id === id) ?? fail(`${label}을 찾지 못했어요.`);
function insertBefore(rows, row, beforeId) {
  const index = beforeId == null ? rows.length : rows.findIndex(item => item.id === beforeId);
  if (index < 0) fail('이동 위치를 찾지 못했어요.');
  rows.splice(index, 0, row);
}

// Change the reusable directory only. Today's tasks retain their versioned snapshots.
export function moveManualNode(state, input) {
  const folders = structuredClone(state.checklistFolders);
  const templates = structuredClone(state.taskTemplates);
  if (input.kind === 'group') {
    const source = get(folders, input.id, 'TAP그룹');
    if (input.beforeId === input.id) return;
    folders.splice(folders.indexOf(source), 1);
    insertBefore(folders, source, input.beforeId);
    state.checklistFolders = folders;
    state.bigTapOrder = folders.map(row => row.id);
  } else if (input.kind === 'tap') {
    const source = get(templates, input.id, 'TAP');
    get(folders, input.targetId, 'TAP그룹');
    if (input.beforeId === input.id) return;
    if (input.beforeId != null && get(templates, input.beforeId, 'TAP').folderId !== input.targetId) fail('같은 TAP그룹의 위치를 선택해 주세요.');
    templates.splice(templates.indexOf(source), 1);
    source.folderId = input.targetId;
    insertBefore(templates, source, input.beforeId);
    state.taskTemplates = templates;
  } else if (input.kind === 'task') {
    const source = get(templates, input.sourceTapId, 'TAP');
    const target = get(templates, input.targetId, 'TAP');
    const step = get(source.steps, input.id, 'Task');
    if (source === target && input.beforeId === input.id) return;
    if (source !== target) {
      if (target.steps.length >= 30) fail('한 TAP의 Task는 최대 30개예요.');
      if (target.steps.some(row => row.id === step.id)) step.id = `manual-${randomUUID()}`;
    }
    if (tapOnly(target)) { assertContentOnly(step); delete step.settings; }
    source.steps.splice(source.steps.indexOf(step), 1);
    insertBefore(target.steps, step, input.beforeId);
    source.version = (source.version ?? 1) + 1;
    if (source !== target) target.version = (target.version ?? 1) + 1;
    state.taskTemplates = templates;
  } else fail('이동할 항목을 확인해 주세요.');
}
