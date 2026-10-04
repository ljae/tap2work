import { StoreError } from './store.mjs';

export const tapOnly = row => row?.assignmentScopeVersion === 2;
const fail = message => { throw new StoreError(message, 400); };
const normalizedAssignment = value => {
  const mode = value?.mode ?? 'legacy';
  return JSON.stringify([mode, mode === 'scheduled' ? value.partId : null,
    [...(mode === 'scheduled' ? value.timeBandIds ?? [] : mode === 'crew' ? value.crewIds ?? [] : [])].sort()]);
};
export function stepPolicyIssues(step, template) {
  const s = step.settings ?? {}, issues = [];
  if (s.assignment && s.assignment.mode !== 'inherit' && normalizedAssignment(s.assignment) !== normalizedAssignment(template.settings?.assignment)) issues.push('담당·시간대');
  if (s.partOverride != null && s.partOverride !== template.partId) issues.push('파트');
  if (s.roleOverride != null && s.roleOverride !== template.requiredRole) issues.push('역할');
  if (s.zoneOverride != null && s.zoneOverride !== template.zone) issues.push('장소');
  if (s.completionKind && s.completionKind !== 'check' || s.quantitySpec != null) issues.push('수량 완료');
  if (s.estimatedMinutes != null) issues.push('예상 시간');
  return issues;
}
export function assertContentOnly(step) {
  if (!step || typeof step !== 'object' || Array.isArray(step)) fail('Task 내용을 확인해 주세요.');
  for (const key of ['assignment','partId','timeBandIds','crewIds','assigneeId','quantitySpec','partOverride','roleOverride','zoneOverride','estimatedMinutes','completionKind']) if (Object.hasOwn(step,key)) fail('Task별 배분은 지원하지 않아요. TAP에서 설정해 주세요.');
  const s = step.settings;
  if (s == null) return;
  if (typeof s !== 'object' || Array.isArray(s)) fail('Task에는 내용과 매뉴얼만 설정할 수 있어요.');
  const harmless = {partOverride:null,roleOverride:null,zoneOverride:null,completionKind:'check',quantitySpec:null,estimatedMinutes:null};
  for (const [key,value] of Object.entries(s)) {
    if (key === 'assignment' && value?.mode === 'inherit' && !(value.timeBandIds?.length || value.crewIds?.length || value.partId)) continue;
    if (Object.hasOwn(harmless,key) && value === harmless[key]) continue;
    fail('Task별 담당·시간대·수량·장소 설정은 지원하지 않아요. TAP 설정에서 변경해 주세요.');
  }
}
export function policyReport(template) {
  const issues = (template.steps ?? []).flatMap(step => stepPolicyIssues(step,template).map(kind => ({stepId:step.id,title:step.title,kind})));
  return {version:tapOnly(template) ? 2 : 1, needsReview:!tapOnly(template) && issues.length > 0, issues};
}
export function convertPolicy(template, {acknowledge = false} = {}) {
  const report = policyReport(template);
  if (report.needsReview && !acknowledge) throw new StoreError('기존 Task별 설정이 있어요. TAP 기준으로 통합할 내용을 먼저 확인해 주세요.',409);
  template.assignmentScopeVersion = 2;
  for (const step of template.steps ?? []) delete step.settings;
  return template;
}
export const contentFields = ['title','manualTitle','manual','tip','tags','imageUrl','videoUrl','sourceUrl','sourceIds','acceptanceText'];
export function contentKey(step) { return JSON.stringify(contentFields.map(key => step[key] ?? (key === 'tags' || key === 'sourceIds' ? [] : ''))); }
export function updateContentRevisions(previous, state) {
  const old = new Map((previous ?? []).flatMap(t => t.steps.map(s => [`${t.id}/${s.id}`,s])));
  for (const t of state.taskTemplates) for (const s of t.steps) {
    const before = old.get(`${t.id}/${s.id}`) ?? [...old.values()].find(row => row.id === s.id && contentKey(row) === contentKey(s));
    if (!before || contentKey(before) !== contentKey(s)) s.contentRevision = before ? (before.contentRevision ?? 1) + 1 : 1;
    else if (before.contentRevision != null) s.contentRevision = before.contentRevision;
  }
  for (const task of state.tasks) for (const step of task.steps ?? []) {
    if (step.completedAt) continue;
    const templateId = step.sourceTemplateId ?? task.templateId;
    const source = state.taskTemplates.find(t => t.id === templateId)?.steps.find(s => s.id === (step.sourceStepId ?? step.id));
    const before = old.get(`${templateId}/${step.sourceStepId ?? step.id}`);
    if (source?.contentRevision != null && contentKey(source) === contentKey(step) && (!before || contentKey(before) !== contentKey(source))) step.contentRevision = source.contentRevision;
  }
}
export function validateQuantity(quantity, spec) {
  const places = spec?.decimalPlaces ?? 0;
  const scaled = quantity * 10 ** places;
  return typeof quantity === 'number' && Number.isFinite(quantity) && quantity > 0 && quantity <= 100000 && Math.abs(Math.round(scaled)-scaled) < 1e-9;
}
