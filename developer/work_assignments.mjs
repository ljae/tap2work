import { actualDate, bandForPart, businessWindow } from './business_day.mjs';
import { crewPartIds, partForLegacy, validatePart, workplaceBandDays } from './parts.mjs';
import { StoreError } from './store.mjs';

const fail = () => { throw new StoreError('업무 배정 설정을 확인해 주세요.', 400); };
export function validateAssignment(value, state, inherit = false) {
  if (value == null) return inherit ? { mode: 'inherit' } : { mode: 'legacy' };
  if (!value || Array.isArray(value) || !['scheduled', 'crew', 'anyone', 'legacy', ...(inherit ? ['inherit'] : [])].includes(value.mode)) fail();
  const ids = key => {
    const rows = value[key] ?? [];
    if (!Array.isArray(rows) || rows.length > 100 || rows.some(id => typeof id !== 'string' || !id || id.length > 150) || new Set(rows).size !== rows.length) fail();
    return rows;
  };
  const timeBandIds = ids('timeBandIds'), crewIds = ids('crewIds');
  if (value.mode === 'scheduled') {
    const partId = validatePart(state, value.partId);
    const bands = Object.values(workplaceBandDays(state,{includeHours:true})).flat();
    if (!timeBandIds.length || !timeBandIds.every(id => {
      const matches = bands.filter(b => b.id === id);
      return matches.length > 0 && matches.every(b => (b.headcounts?.[partId] ?? (b.custom ? 0 : 1)) > 0);
    })) fail();
    return { mode: value.mode, timeBandIds, partId, crewIds: [] };
  }
  if (value.mode === 'crew' && (!crewIds.length || !crewIds.every(id => state.tappers?.some(p => p.id === id && p.active)))) fail();
  return { mode: value.mode, timeBandIds: [], partId: null, crewIds: value.mode === 'crew' ? crewIds : [] };
}
export const assignmentOf = (task, step) => step?.settings?.assignment && step.settings.assignment.mode !== 'inherit'
  ? step.settings.assignment : task.settings?.assignment ?? { mode: 'legacy' };
const weekday = date => new Date(`${date}T12:00:00+09:00`).getUTCDay() || 7;
const bandsOn = (state, date) => workplaceBandDays(state,{includeHours:true})[weekday(date)] ?? [];
const interval = row => {
  const start = Date.parse(`${row.date}T${row.start}:00+09:00`);
  let end = Date.parse(`${row.date}T${row.end}:00+09:00`);
  if (end <= start) end += 86400000;
  return [start, end];
};
const overlaps = (a,b) => { const [x,y] = interval(a), [z,w] = interval(b); return x < w && z < y; };
const clockFields = (start, end) => {
  const a = new Date(start + 9 * 3600000).toISOString(), b = new Date(end + 9 * 3600000).toISOString();
  return {start:a.slice(11,16),end:b.slice(11,16),startDate:a.slice(0,10),endDate:b.slice(0,10)};
};
// Request-scoped only: mutations must create a fresh context after changing the roster.
export function assignmentContext(state) {
  const people = new Map((state.tappers ?? []).filter(p => p.active).map(p => [p.id,p]));
  return {people, shifts:(state.staffShifts ?? []).filter(s => !['leave','off','OFF','cancelled'].includes(s.status) && people.has(s.tapperId)), views:new WeakMap()};
}

// A TAP is shared per selected band; overriding Tasks are included only in their own bands.
export function assignmentOccurrences(state, template, date) {
  const configs = (template.steps ?? []).map(step => assignmentOf(template, step));
  const ids = [...new Set(configs.filter(c => c.mode === 'scheduled').flatMap(c => c.timeBandIds))];
  const bands = bandsOn(state,date).filter(b => ids.includes(b.id));
  if (!ids.length) return [{ timeBandId: null, steps: template.steps }];
  return bands.map(b => ({ timeBandId: b.id, timeBandName: b.name, assignmentWindow: {id:b.id,name:b.name,date:actualDate(state,date,b.start),start:b.start,end:b.end,...(b.partTimes ? {partTimes:b.partTimes} : {})},
    steps: template.steps.filter(step => { const c = assignmentOf(template,step); return c.mode !== 'scheduled' || c.timeBandIds.includes(b.id); }) }));
}
export function assignmentView(state, task, step, actor, context = assignmentContext(state)) {
  const key = step ?? task;
  if (context.views.has(key)) return context.views.get(key);
  const view = projectAssignment(state, task, step, actor, context);
  context.views.set(key, view);
  return view;
}
function projectAssignment(state, task, step, actor, context) {
  if (step?.completedAt && step.assignmentSnapshot) return { ...structuredClone(step.assignmentSnapshot), isMine: step.assignmentSnapshot.assignees.some(p => p.actorId === actor?.id) };
  if (!step && task.completedAt && task.assignmentSnapshot) return { ...structuredClone(task.assignmentSnapshot), isMine: task.assignmentSnapshot.assignees.some(p => p.actorId === actor?.id) };
  const config = assignmentOf(task,step);
  let mode = config.mode;
  const originalBand = task.assignmentWindow ?? bandsOn(state,task.date).find(b => b.id === task.timeBandId);
  const band = originalBand ? bandForPart(originalBand, config.partId) : null;
  const bandDate = band ? (task.assignmentWindow ? (band.start === originalBand.start ? originalBand.date : actualDate({workplace:{businessDayStart:task.businessDayStart ?? '00:00'}},task.date,band.start)) : actualDate(state,task.date,band.start)) : task.date;
  const window = mode === 'scheduled' && band ? interval({...band,date:bandDate}) : mode === 'anyone' ? businessWindow(state,task.date,task.businessDayStart ?? '00:00') : null;
  let shifts = window ? context.shifts : context.shifts.filter(s => s.date === task.date);
  if (window) shifts = shifts.filter(s => {const [a,b] = interval(s);return a < window[1] && window[0] < b;});
  if (mode === 'scheduled') shifts = shifts.filter(s => band && config.timeBandIds.includes(band.id) && (s.partId ?? partForLegacy(state,s.duty)) === config.partId && (s.timeBandId ? s.timeBandId === band.id : true) && overlaps(s,{...band,date:bandDate}));
  if (mode === 'crew') shifts = shifts.filter(s => config.crewIds.includes(s.tapperId));
  if (mode === 'legacy') shifts = [];
  let assignees = shifts.map(s => { const p = context.people.get(s.tapperId); return { id:p.id,nickname:p.nickname, ...(p.actorId ? {actorId:p.actorId} : {}),...(() => {const [a,b] = interval(s);return clockFields(window ? Math.max(a,window[0]) : a,window ? Math.min(b,window[1]) : b);})() }; });
  if (mode === 'crew') for (const p of [...context.people.values()].filter(p => config.crewIds.includes(p.id))) if (!assignees.some(a => a.id === p.id)) assignees.push({id:p.id,nickname:p.nickname,...(p.actorId ? {actorId:p.actorId} : {}),start:null,end:null});
  if (!step && task.steps?.length) {
    const views = task.steps.map(s => assignmentView(state,task,s,actor,context));
    assignees = views.flatMap(v => v.assignees);
    if (views.some(v => v.mode !== 'legacy') && views.some(v => v.mode !== mode)) mode = 'mixed';
    else if (views.every(v => v.mode === 'legacy')) mode = 'legacy';
  }
  assignees = [...new Map(assignees.map(p => [JSON.stringify([p.id,p.startDate,p.start,p.endDate,p.end]),p])).values()];
  return { mode, assignees, partId:config.partId ?? null,timeBandId:task.timeBandId ?? null,timeBandName:band?.name ?? task.timeBandName ?? null,unassigned:mode !== 'legacy' && !assignees.length,isMine:assignees.some(p => p.actorId === actor?.id) };
}
// null means use the untouched legacy role/part rule.
export function assignmentPermission(state, actor, task, step, context) {
  const config = assignmentOf(task,step);
  if (config.mode === 'legacy') return null;
  if (['owner','manager'].includes(actor.role)) return true;
  const person = state.tappers?.find(p => p.active && p.actorId === actor.id);
  if (!person) return false;
  if (config.mode === 'scheduled') return crewPartIds(state,person).includes(config.partId);
  return assignmentView(state,task,step,actor,context).assignees.some(p => p.id === person.id);
}
export function snapshotAssignments(state, task, step) {
  const row = step ?? task;
  const view = assignmentView(state,task,step);
  if (view.mode === 'legacy') return;
  row.assignmentSnapshot = structuredClone(view);
  delete row.assignmentSnapshot.isMine;
}
