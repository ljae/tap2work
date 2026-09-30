import { validateAssignment, assignmentPermission } from './work_assignments.mjs';
import { validatePart } from './parts.mjs';
import { StoreError } from './store.mjs';

const fail = message => { throw new StoreError(message, 400); };
export const workTypes = ['general', 'opening', 'closing', 'cleaning', 'order', 'preparation', 'training'];
const roles = ['all', 'crew', 'cook', 'manager', 'owner'];
const integer = (value, min, max, label) => {
  if (!Number.isInteger(value) || value < min || value > max) fail(`${label}을 확인해 주세요.`);
  return value;
};
const bool = (value, label) => { if (typeof value !== 'boolean') fail(`${label}을 선택해 주세요.`); return value; };

export function taskSettings(template) {
  return { ...(template.settings?.assignment ? {assignment: template.settings.assignment} : {}), type: template.settings?.type ?? 'general', enabled: template.settings?.enabled ?? true,
    recurrence: template.settings?.recurrence ?? { mode: 'daily', weekdays: [] },
    allowBulkComplete: template.settings?.allowBulkComplete ?? true,
    enforceSequence: template.settings?.enforceSequence ?? false };
}

export function stepSettings(step) {
  return { ...(step.settings?.assignment ? {assignment: step.settings.assignment} : {}), ...(Object.hasOwn(step.settings ?? {}, 'partOverride') ? {partOverride: step.settings.partOverride} : {}), roleOverride: step.settings?.roleOverride ?? null,
    zoneOverride: step.settings?.zoneOverride ?? null,
    completionKind: step.settings?.completionKind ?? 'check',
    quantitySpec: step.settings?.quantitySpec ?? null,
    estimatedMinutes: step.settings?.estimatedMinutes ?? null };
}

export function validateTaskSettings(value, state) {
  if (!value || typeof value !== 'object' || Array.isArray(value)) fail('TAP 설정을 확인해 주세요.');
  if (!workTypes.includes(value.type)) fail('업무 유형을 선택해 주세요.');
  const recurrence = value.recurrence;
  if (!recurrence || !['daily', 'weekly'].includes(recurrence.mode) || !Array.isArray(recurrence.weekdays)) fail('반복 요일을 확인해 주세요.');
  const weekdays = recurrence.weekdays.map(day => integer(day, 1, 7, '요일'));
  if (new Set(weekdays).size !== weekdays.length || (recurrence.mode === 'weekly' && !weekdays.length)) fail('반복 요일을 하나 이상 선택해 주세요.');
  return { ...(Object.hasOwn(value, 'assignment') ? {assignment: validateAssignment(value.assignment, state)} : {}), type: value.type, enabled: bool(value.enabled, '업무 사용 여부'),
    recurrence: { mode: recurrence.mode, weekdays: recurrence.mode === 'weekly' ? weekdays : [] },
    allowBulkComplete: bool(value.allowBulkComplete, '일괄 완료'),
    enforceSequence: bool(value.enforceSequence, '순서대로 수행') };
}

export function validateStepSettings(value, state) {
  if (!value || typeof value !== 'object' || Array.isArray(value)) fail('Task 설정을 확인해 주세요.');
  const roleOverride = value.roleOverride ?? null;
  if (roleOverride !== null && !roles.includes(roleOverride)) fail('담당 역할을 확인해 주세요.');
  const zoneOverride = value.zoneOverride ?? null;
  if (zoneOverride !== null && !state.zones.some(zone => zone.id === zoneOverride)) fail('장소를 확인해 주세요.');
  const kind = value.completionKind;
  if (!['check', 'quantity'].includes(kind)) fail('완료 방식을 확인해 주세요.');
  let quantitySpec = null;
  if (kind === 'quantity') {
    const spec = value.quantitySpec;
    if (!spec || typeof spec.unit !== 'string' || !spec.unit.trim() || spec.unit.length > 20) fail('수량 단위를 입력해 주세요.');
    if (spec.target != null && (typeof spec.target !== 'number' || !Number.isFinite(spec.target) || spec.target <= 0 || spec.target > 100000)) fail('목표 수량을 확인해 주세요.');
    quantitySpec = { unit: spec.unit.trim(), target: spec.target ?? null,
      decimalPlaces: integer(spec.decimalPlaces ?? 0, 0, 2, '소수 자리') };
  }
  const minutes = value.estimatedMinutes;
  if (minutes != null) integer(minutes, 1, 480, '예상 시간');
  return { ...(Object.hasOwn(value, 'assignment') ? {assignment: validateAssignment(value.assignment, state, true)} : {}), ...(Object.hasOwn(value, 'partOverride') ? {partOverride: validatePart(state, value.partOverride, {allowAll:true})} : {}), roleOverride, zoneOverride, completionKind: kind, quantitySpec, estimatedMinutes: minutes ?? null };
}

export function saveTapSettings(state, input, now = new Date()) {
  const template = state.taskTemplates.find(row => row.id === input.templateId && !row.archivedAt);
  if (!template) throw new StoreError('TAP 양식을 찾지 못했어요.', 404);
  if (!Array.isArray(input.steps) || input.steps.length !== template.steps.length || new Set(input.steps.map(row => row?.id)).size !== template.steps.length) fail('Task 목록을 확인해 주세요.');
  const settings = validateTaskSettings(input.settings, state);
  const steps = input.steps.map(row => {
    const existing = template.steps.find(step => step.id === row?.id);
    if (!existing) fail('Task을 찾지 못했어요.');
    return { id: existing.id, settings: validateStepSettings(row.settings, state) };
  });
  if (!Object.hasOwn(input.settings, 'assignment') && template.settings?.assignment) settings.assignment = structuredClone(template.settings.assignment);
  for (const row of steps) {
    const old = template.steps.find(s => s.id === row.id);
    if (!Object.hasOwn(input.steps.find(s => s.id === row.id).settings, 'assignment') && old.settings?.assignment) row.settings.assignment = structuredClone(old.settings.assignment);
  }
  const assignmentKey = (tap, rows) => {
    const key = (value, fallback) => {
      const mode = value?.mode ?? fallback;
      if (mode === 'scheduled') return [mode,value.partId,[...(value.timeBandIds ?? [])].sort()];
      if (mode === 'crew') return [mode,[...(value.crewIds ?? [])].sort()];
      return [mode];
    };
    return JSON.stringify([key(tap?.assignment,'legacy'), rows.map(s => [s.id,key(s.settings?.assignment,'inherit')]).sort((a,b) => a[0].localeCompare(b[0]))]);
  };
  if (assignmentKey(template.settings, template.steps) !== assignmentKey(settings, steps)) {
    for (const task of state.tasks.filter(t => t.templateId === template.id && t.date === state.day && !t.archivedAt && !t.completedAt && t.boardStatus !== 'processing' && !t.steps?.some(s => s.completedAt))) task.archivedAt = new Date(now).toISOString();
  }
  template.settingsVersion = 1;
  template.settings = settings;
  for (const step of template.steps) step.settings = steps.find(row => row.id === step.id).settings;
  template.version = (template.version ?? 1) + 1;
  return template;
}

export function repeatsOn(template, date) {
  const settings = taskSettings(template);
  if (!settings.enabled) return false;
  if (settings.recurrence.mode === 'daily') return true;
  const day = new Date(`${date}T12:00:00+09:00`).getUTCDay();
  return settings.recurrence.weekdays.includes(day === 0 ? 7 : day);
}

export function canCompleteStep(actor, task, step, state, context) {
  if (state) { const permission = assignmentPermission(state, actor, task, step, context); if (permission !== null) return permission; }
  const settings = stepSettings(step);
  if (['owner', 'manager'].includes(actor.role)) return true;
  if (Object.hasOwn(settings, 'partOverride') || (Object.hasOwn(task, 'partId') && settings.roleOverride == null)) {
    const part = settings.partOverride ?? task.partId;
    return part == null || (actor.partIds ?? []).includes(part);
  }
  const role = settings.roleOverride ?? task.requiredRole;
  return ['owner', 'manager'].includes(actor.role) || role === 'all' || role === actor.role;
}

export function completeStepIssue(actor, task, step, quantity, state) {
  if (!canCompleteStep(actor, task, step, state)) return '이 Task의 담당 역할이 아니에요.';
  if (taskSettings(task).enforceSequence && task.steps.some(row => row.id !== step.id && !row.completedAt && task.steps.indexOf(row) < task.steps.indexOf(step))) return '앞 Task을 먼저 완료해 주세요.';
  const settings = stepSettings(step);
  if (settings.completionKind === 'quantity') {
    const places = settings.quantitySpec?.decimalPlaces ?? 0;
    const scaled = quantity * 10 ** places;
    if (typeof quantity !== 'number' || !Number.isFinite(quantity) || quantity <= 0 || quantity > 100000 || Math.abs(Math.round(scaled) - scaled) > 1e-9) return `실제 수량을 ${places ? `소수 ${places}자리까지` : '정수로'} 입력해 주세요.`;
  }
  return null;
}

export function bulkCompleteIssue(actor, task, state) {
  const pending = (task.steps ?? []).filter(step => !step.completedAt);
  if (!pending.length) return null;
  const settings = taskSettings(task);
  if (!settings.allowBulkComplete || settings.enforceSequence) return 'Task을 하나씩 완료해 주세요.';
  if (pending.some(step => stepSettings(step).completionKind === 'quantity')) return '실제 수량을 Task에서 입력해 주세요.';
  if (pending.some(step => !canCompleteStep(actor, task, step, state))) return '담당 역할별 Task을 각각 완료해 주세요.';
  return null;
}
