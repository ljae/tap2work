import library from '../docs/wiki/checklist-library.json' with { type: 'json' };
import { StoreError } from './store.mjs';

export const checklistLibrary = library;
export const checklistSlots = ['오픈', '준비', '피크', '브레이크', '마감'];
export const checklistRoles = ['all', 'crew', 'cook', 'manager', 'owner'];
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
// A group icon is one short emoji (ZWJ sequences such as 🧑‍🍳 span several code points); longer text would break the card header.
const emoji = value => (typeof value === 'string' && value.trim() && !/\s/.test(value.trim()) && [...value.trim()].length <= 10) ? value.trim() : '📝';

/// Copies one library collection into store templates. Zone/role hints apply only when the store has that place.
export function libraryTemplates(industryId, zones, folderId = industryId) {
  const industry = checklistLibrary.industries.find(row => row.id === industryId);
  if (!industry) return { folder: null, templates: [] };
  return {
    folder: { id: folderId, name: industry.name },
    templates: industry.tasks.map(task => ({
      id: `library-${industry.id}-${task.id}`, title: task.title, emoji: emoji(task.emoji), folderId, slot: task.slot,
      requiredRole: checklistRoles.includes(task.requiredRole) ? task.requiredRole : 'all',
      zone: zones.some(zone => zone.id === task.zone) ? task.zone : zones[0]?.id,
      version: 1, steps: structuredClone(task.steps), sourceIds: [...task.sourceIds],
    })),
  };
}
export function ensureChecklists(state) {
  if (state.checklistVersion === 1) return false;
  state.checklistFolders = [{ id: 'general', name: '기본 업무' }];
  const basics = checklistLibrary.industries.find(row => row.id === 'common')?.tasks ?? [];
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
    if (!row || !checklistSlots.includes(row.slot) || !checklistRoles.includes(row.requiredRole) || !state.zones.some(zone => zone.id === row.zone) || !folders.some(folder => folder.id === row.folderId)) fail('업무의 시간대·직급·장소·폴더를 확인해 주세요.');
    const steps = list(row.steps, 1, 30, '행위').map(step => ({ id: text(step?.id, 100, '행위 ID'), title: text(step?.title, 100, '행위 이름'), manual: text(step?.manual, 700, '간단 매뉴얼'), tip: optionalText(step?.tip, 400, '노하우') }));
    unique(steps);
    const sourceIds = Array.isArray(row.sourceIds) ? [...new Set(row.sourceIds.filter(id => checklistLibrary.sources.some(source => source.id === id)))] : [];
    return { id: text(row.id, 100, '업무 ID'), title: text(row.title, 100, '업무 이름'), emoji: emoji(row.emoji), folderId: row.folderId, slot: row.slot, requiredRole: row.requiredRole, zone: row.zone, steps, sourceIds };
  });
  unique(templates);
  return { folders, templates };
}
export function saveChecklists(input, state, now) {
  const { folders, templates } = validateChecklists(input, state);
  const old = state.taskTemplates;
  for (const template of templates) {
    const previous = old.find(row => row.id === template.id);
    const content = row => JSON.stringify([row.title, row.emoji, row.slot, row.requiredRole, row.zone, row.steps, row.sourceIds]);
    template.version = previous ? (previous.version ?? 1) + (content(previous) !== content(template) ? 1 : 0) : Math.max(0, ...state.tasks.filter(row => row.templateId === template.id).map(row => row.version ?? 1)) + 1;
  }
  for (const task of state.tasks.filter(row => row.kind === 'routine' && !row.orderId && !row.archivedAt)) {
    const next = templates.find(row => row.id === task.templateId);
    const started = task.completedAt || task.steps?.some(step => step.completedAt);
    if (!started && (!next || next.version !== task.version)) task.archivedAt = new Date(now).toISOString();
  }
  state.checklistFolders = folders;
  state.taskTemplates = templates;
}
/// Undo one mis-tapped activity. Only the person who tapped it or a leader may reopen it, and only for today's work.
export function reopenStep(task, stepId, actor, isLeader) {
  const step = task.steps?.find(row => row.id === stepId);
  if (task.kind !== 'routine' || !step) fail('행위를 찾지 못했어요.');
  if (!step.completedAt) fail('아직 확인하지 않은 행위예요.');
  if (step.completedBy?.id !== actor.id && !isLeader) fail(`${step.completedBy?.name ?? '동료'}님이 확인한 행위는 본인이나 매니저만 되돌릴 수 있어요.`);
  delete step.completedAt; delete step.completedBy;
  task.completedAt = null; task.completedBy = null;
}
