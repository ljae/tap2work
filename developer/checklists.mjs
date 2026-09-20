import { readFileSync } from 'node:fs';
import { StoreError } from './store.mjs';

export const checklistLibrary = JSON.parse(readFileSync(new URL('../docs/wiki/checklist-library.json', import.meta.url), 'utf8'));
const fail = message => { throw new StoreError(message, 400); };
const text = (value, max, label) => {
  if (typeof value !== 'string' || !value.trim() || value.length > max) fail(`${label}을 확인해 주세요.`);
  return value.trim();
};
const optionalText = (value, max, label) => {
  if (value == null) return '';
  if (typeof value !== 'string' || value.length > max) fail(`${label}은 ${max}자 이내로 적어 주세요.`);
  return value.trim();
};
const list = (value, min, max, label) => {
  if (!Array.isArray(value) || value.length < min || value.length > max) fail(`${label}은 ${min}~${max}개로 구성해 주세요.`);
  return value;
};
const unique = rows => { if (new Set(rows.map(row => row.id)).size !== rows.length) fail('중복된 항목 ID가 있어요.'); };
export function ensureChecklists(state) {
  if (state.checklistVersion === 1) return false;
  state.checklistFolders = [{ id: 'general', name: '기본 업무' }];
  const basics = checklistLibrary.industries[0]?.tasks ?? [];
  for (const template of state.taskTemplates) {
    template.folderId = 'general'; template.version = 1;
    const base = basics.find(row => row.legacyId === template.id);
    template.steps = structuredClone(base?.steps ?? [{ id: 'step-1', title: template.title, manual: '매장에 정해진 순서대로 진행하고 결과를 확인해요. 모르는 부분은 버디에게 먼저 물어보세요.', tip: '매장에 맞는 방법과 완료 기준을 편집해 주세요.' }]);
    template.sourceIds = base?.sourceIds ?? [];
    // Attach a versioned manual only to work that has not been completed.
    for (const task of state.tasks.filter(row => row.kind === 'routine' && (row.id === template.id || row.id === `daily-${template.id}-${row.date}`))) {
      task.templateId = template.id;
      if (!task.completedAt) {
        task.steps = structuredClone(template.steps); task.folderId = template.folderId; task.version = 1;
      }
    }
  }
  state.checklistVersion = 1;
  return true;
}
export function validateChecklists(input, state) {
  const folders = list(input.folders, 1, 30, '폴더').map(row => ({ id: text(row?.id, 100, '폴더 ID'), name: text(row?.name, 40, '폴더 이름') }));
  unique(folders);
  if (folders.some(row => ['stock', 'all-filter', 'edit', 'delete', 'up', 'down'].includes(row.id))) fail('다른 폴더 ID를 사용해 주세요.');
  if (!folders.some(row => row.id === 'general')) fail('기본 업무 폴더는 유지해 주세요.');
  const templates = list(input.templates, 0, 150, '업무').map(row => {
    if (!row || !['오픈', '준비', '피크', '마감'].includes(row.slot) || !['all', 'crew', 'cook', 'manager', 'owner'].includes(row.requiredRole) || !state.zones.some(zone => zone.id === row.zone) || !folders.some(folder => folder.id === row.folderId)) fail('업무의 시간대·직급·장소·폴더를 확인해 주세요.');
    const steps = list(row.steps, 1, 30, '행위').map(step => ({ id: text(step?.id, 100, '행위 ID'), title: text(step?.title, 100, '행위 이름'), manual: text(step?.manual, 700, '간단 매뉴얼'), tip: optionalText(step?.tip, 400, '노하우') }));
    unique(steps);
    const sourceIds = Array.isArray(row.sourceIds) ? [...new Set(row.sourceIds.filter(id => checklistLibrary.sources.some(source => source.id === id)))] : [];
    return { id: text(row.id, 100, '업무 ID'), title: text(row.title, 100, '업무 이름'), emoji: '📝', folderId: row.folderId, slot: row.slot, requiredRole: row.requiredRole, zone: row.zone, steps, sourceIds };
  });
  unique(templates);
  return { folders, templates };
}
export function saveChecklists(input, state, now) {
  const { folders, templates } = validateChecklists(input, state);
  const old = state.taskTemplates;
  for (const template of templates) {
    const previous = old.find(row => row.id === template.id);
    const content = row => JSON.stringify([row.title, row.slot, row.requiredRole, row.zone, row.steps, row.sourceIds]);
    template.version = previous ? (previous.version ?? 1) + (content(previous) !== content(template) ? 1 : 0) : Math.max(0, ...state.tasks.filter(row => row.templateId === template.id).map(row => row.version ?? 1)) + 1;
  }
  for (const task of state.tasks.filter(row => row.kind === 'routine' && !row.archivedAt)) {
    const next = templates.find(row => row.id === task.templateId);
    const started = task.completedAt || task.steps?.some(step => step.completedAt);
    if (!started && (!next || next.version !== task.version)) task.archivedAt = new Date(now).toISOString();
  }
  state.checklistFolders = folders;
  state.taskTemplates = templates;
}
