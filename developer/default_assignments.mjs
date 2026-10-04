import { randomUUID } from 'node:crypto';
import { StoreError } from './store.mjs';
import { actualDate, businessDate, bandForPart } from './business_day.mjs';
import { crewPartIds } from './parts.mjs';

const dateAt = (date, n) => new Date(Date.parse(`${date}T00:00:00Z`) + n * 86400000).toISOString().slice(0, 10);
const weekday = date => new Date(`${date}T00:00:00Z`).getUTCDay() || 7;
const interval = s => {
  const start = Date.parse(`${s.date}T${s.start}:00+09:00`);
  let end = Date.parse(`${s.date}T${s.end}:00+09:00`);
  if (end <= start) end += 86400000;
  return [start, end];
};
const overlaps = (a, b) => { const [x,y] = interval(a), [z,w] = interval(b); return x < w && z < y; };
const fields = s => JSON.stringify([s.tapperId, s.partId, s.date, s.start, s.end, s.timeBandId]);
function candidates(state, date) {
  const exception = state.workplace.dateOverrides?.[date];
  if (exception?.closed) return [];
  const day = exception?.weekday ?? weekday(date);
  return (state.workplace.days[day] ?? []).flatMap(band =>
    Object.entries(band.crewIds ?? {}).flatMap(([partId, ids]) =>
      state.workplace.parts.some(p => p.id === partId && !p.hidden)
        ? ids.flatMap((tapperId, seat) => {
          const person = state.tappers.find(p => p.id === tapperId && p.active);
          if (!person || !crewPartIds(state, person).includes(partId)) return [];
          const times = bandForPart(band, partId);
          return [{ defaultAssignmentKey: `${date}/${band.id}/${partId}/${seat}`, tapperId, partId,
            timeBandId: band.id, date: actualDate(state, date, times.start),
            start: times.start, end: times.end, employmentType: person.employmentType ?? '시간알바',
            duty: state.workplace.parts.find(p => p.id === partId)?.duties?.[0] ?? partId }];
        }) : []));
}

export function validateDefaultAssignments(state) {
  for (const bands of Object.values(state.workplace.days)) for (const band of bands) {
    for (const [part, ids] of Object.entries(band.crewIds ?? {})) {
      const count = band.headcounts?.[part] ?? (band.custom ? 0 : 1);
      if (!Array.isArray(ids) || ids.length > count || ids.some(id => typeof id !== 'string')) throw new StoreError('크루 배정은 필요 인원 이내로 선택해 주세요.', 400);
      for (const id of ids.filter(Boolean)) {
        const person = state.tappers.find(p => p.id === id && p.active);
        if (!person) throw new StoreError('등록된 활성 크루를 선택해 주세요.', 400);
        if (!crewPartIds(state, person).includes(part)) throw new StoreError(`${person.nickname} 크루의 담당 파트를 확인해 주세요.`, 400);
      }
    }
  }
  // Two full weeks catch overnight overlap across the Sunday/Monday boundary.
  const regular = {...state, workplace: {...state.workplace, dateOverrides: {}}};
  const shifts = Array.from({length: 15}, (_, n) => candidates(regular, dateAt('2026-10-05', n))).flat();
  for (let i = 0; i < shifts.length; i++) if (shifts.slice(0, i).some(s => s.tapperId === shifts[i].tapperId && overlaps(s, shifts[i]))) throw new StoreError('같은 크루의 기본 배정 시간이 겹쳐요. 요일·교대·파트를 확인해 주세요.', 409);
}

// Persist the next 90 business days, extending on reads. Calendar edits, deletes,
// attendance, requests and started shifts are explicit exceptions to the default.
export function ensureDefaultAssignments(state, now, {refreshDates = new Set(), restoredIds = new Map()} = {}) {
  if (state.workplace?.defaultAssignmentsEnabled !== true) return false;
  const before = JSON.stringify(state.staffShifts);
  const today = businessDate(state, now);
  const desired = Array.from({length: 90}, (_, n) => candidates(state, dateAt(today, n))).flat();
  const wanted = new Map(desired.map(s => [s.defaultAssignmentKey, s]));
  const protectedShift = s => s.defaultAssignmentEdited || s.status !== 'planned' || s.approvedRequestId || s.replacementForRequestId || interval(s)[0] <= now.getTime() ||
    (state.attendance ?? []).some(a => !a.voidedAt && a.tapperId === s.tapperId && businessDate(state, a.at) === businessDate(state, `${s.date}T${s.start}:00+09:00`)) ||
    (state.shiftChangeRequests ?? []).some(r => r.shiftId === s.id && r.status === 'pending');
  state.staffShifts = state.staffShifts.filter(s => !s.defaultAssignmentKey || protectedShift(s) || wanted.has(s.defaultAssignmentKey));
  // Remove only unchanged generated rows that need updating; retain stable IDs.
  const replace = new Map();
  state.staffShifts = state.staffShifts.filter(s => {
    const next = wanted.get(s.defaultAssignmentKey);
    if (!next || protectedShift(s) || fields(s) === fields(next)) return true;
    replace.set(s.defaultAssignmentKey, s.id); return false;
  });
  const existing = new Set(state.staffShifts.map(s => s.defaultAssignmentKey));
  const suppressed = new Set(state.defaultAssignmentOmissions ?? []);
  const protectedDays = new Set(state.staffShifts.filter(s => s.approvedRequestId || s.replacementForRequestId ||
    (state.shiftChangeRequests ?? []).some(r => r.shiftId === s.id && r.status === 'pending'))
    .map(s => `${s.tapperId}/${s.base?.businessDate ?? businessDate(state, `${s.date}T${s.start}:00+09:00`)}`));
  for (const shift of desired) {
    if (protectedDays.has(`${shift.tapperId}/${shift.defaultAssignmentKey.slice(0,10)}`)) continue;
    if (existing.has(shift.defaultAssignmentKey) || suppressed.has(shift.defaultAssignmentKey) || (interval(shift)[0] <= now.getTime() && !refreshDates.has(shift.defaultAssignmentKey.slice(0,10)))) continue;
    if (state.staffShifts.some(s => s.tapperId === shift.tapperId && (s.status === 'leave' ? s.date === shift.date : overlaps(s, shift)))) continue;
    // An attendance record or protected occurrence for this crew/day also blocks new defaults.
    if ((state.attendance ?? []).some(a => !a.voidedAt && a.tapperId === shift.tapperId && businessDate(state, a.at) === shift.defaultAssignmentKey.slice(0,10))) continue;
    state.staffShifts.push({...shift, id: replace.get(shift.defaultAssignmentKey) ?? restoredIds.get(shift.defaultAssignmentKey) ?? randomUUID(), status: 'planned',
      base: {businessDate: shift.defaultAssignmentKey.slice(0,10), date:shift.date, partId:shift.partId, start:shift.start, end:shift.end, timeBandId:shift.timeBandId}});
  }
  return before !== JSON.stringify(state.staffShifts);
}

// An explicit staffing save replaces fine-tuning for affected weekdays. Reads
// still preserve edits; actual attendance and approved/pending requests survive.
export function refreshDefaultAssignments(state, previous, now, weekdays, actor) {
  if (state.workplace?.defaultAssignmentsEnabled !== true || !weekdays.length) return;
  const today = new Date(new Date(now).getTime() + 9 * 3600000).toISOString().slice(0,10);
  const dates = new Set(Array.from({length:90}, (_,n) => dateAt(today,n)).filter(date => {
    const oldDay = previous.workplace?.dateOverrides?.[date]?.weekday ?? weekday(date);
    const newDay = state.workplace.dateOverrides?.[date]?.weekday ?? weekday(date);
    return weekdays.includes(oldDay) || weekdays.includes(newDay);
  }));
  const shiftDay = s => s.defaultAssignmentKey?.slice(0,10) ?? s.base?.businessDate ?? businessDate(previous, `${s.date}T${s.start}:00+09:00`);
  const protectedShift = s => s.status !== 'planned' || s.approvedRequestId || s.replacementForRequestId ||
    (state.attendance ?? []).some(a => !a.voidedAt && a.tapperId === s.tapperId && businessDate(previous,a.at) === shiftDay(s)) ||
    (state.shiftChangeRequests ?? []).some(r => r.shiftId === s.id && r.status === 'pending');
  const removed = state.staffShifts.filter(s => dates.has(shiftDay(s)) && !protectedShift(s));
  const removedSet = new Set(removed);
  const overrides = (state.rosterOverrides ?? []).filter(s => dates.has(s.date));
  const omissions = (state.defaultAssignmentOmissions ?? []).filter(key => dates.has(key.slice(0,10)));
  state.staffShifts = state.staffShifts.filter(s => !removedSet.has(s));
  state.rosterOverrides = (state.rosterOverrides ?? []).filter(s => !dates.has(s.date));
  state.defaultAssignmentOmissions = (state.defaultAssignmentOmissions ?? []).filter(key => !dates.has(key.slice(0,10)));
  const restoredIds = new Map(removed.filter(s => s.defaultAssignmentKey).map(s => [s.defaultAssignmentKey,s.id]));
  ensureDefaultAssignments(state,now,{refreshDates:dates,restoredIds});
  const current = new Map(state.staffShifts.map(s => [s.id,s]));
  const replaced = removed.filter(s => !s.defaultAssignmentKey || s.defaultAssignmentEdited ||
    !current.has(s.id) || fields(s) !== fields(current.get(s.id)));
  if (replaced.length || overrides.length || omissions.length) {
    (state.operationEditHistory ??= []).push({actor:actor.id,at:new Date(now).toISOString(),value:{
      kind:'staffing_default_refresh',weekdays,staffShifts:structuredClone(replaced),
      rosterOverrides:structuredClone(overrides),defaultAssignmentOmissions:[...omissions],
    }});
  }
}
