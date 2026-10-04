import { actualDate, businessDate } from './business_day.mjs';
import { hasAttendance, timeBandFields } from './schedule_exceptions.mjs';
import { randomUUID } from 'node:crypto';
import { StoreError } from './store.mjs';
import { validRosterDate } from './parts.mjs';
const fail = (s, status = 400) => { throw new StoreError(s, status); };
const dateAt = (date, n) => new Date(Date.parse(`${date}T00:00:00Z`) + n * 86400000).toISOString().slice(0, 10);

// Base assignments stay on each generated shift. Calendar edits change only the
// effective fields, so reapplication is explicit, bounded and atomic.
export function mutateCrewPattern(state, input, actor, now, activity, validShift, validateOverlap, interval) {
  if (!['save_crew_pattern', 'apply_crew_pattern', 'save_crew_allocations', 'apply_crew_allocations'].includes(input.action)) return false;
  if (!['owner', 'manager'].includes(actor.role)) fail('매니저 이상만 배정할 수 있어요.', 403);
  if (input.action === 'save_crew_allocations' || input.action === 'apply_crew_allocations') {
    const saving = input.action === 'save_crew_allocations';
    const rows = saving ? input.patterns : (state.crewPatterns ?? []).filter(p => state.tappers.some(t => t.id === p.tapperId && t.active));
    if (!Array.isArray(rows) || !rows.length || rows.length > state.tappers.length || new Set(rows.map(p => p.tapperId)).size !== rows.length) fail('배정할 크루를 확인해 주세요.');
    // OperationsStore commits only after every member passes validation.
    for (const row of rows) mutateCrewPattern(state, {
      ...row, action: saving ? 'save_crew_pattern' : 'apply_crew_pattern',
      from: input.from, until: input.until,
    }, actor, now, activity, validShift, validateOverlap, interval);
    return true;
  }
  if (!state.tappers.some(t => t.id === input.tapperId && t.active)) fail('크루를 찾지 못했어요.',404);
  const old = (state.crewPatterns ?? []).find(p => p.tapperId === input.tapperId);
  if (input.action === 'save_crew_pattern') {
    if (![1, 2].includes(input.cycleWeeks) || validRosterDate(input.anchor) !== 1) fail('주기와 A주 시작 월요일을 확인해 주세요.');
    if (!Array.isArray(input.entries) || input.entries.length > 28) fail('주간 배정을 확인해 주세요.');
    const entries = input.entries.map(e => {
      if (!Number.isInteger(e.week) || e.week < 0 || e.week >= input.cycleWeeks || !Number.isInteger(e.weekday) || e.weekday < 1 || e.weekday > 7) fail('배정 요일을 확인해 주세요.');
      const next = validShift({ ...e, tapperId: input.tapperId, date: dateAt(input.anchor, e.week * 7 + e.weekday - 1) }, state);
      return { ...timeBandFields(state, e, e.weekday), week: e.week, weekday: e.weekday, partId: next.partId, start: next.start, end: next.end };
    });
    // Validate adjacent weeks, including Sunday overnight crossing the cycle.
    const proposed = [];
    for (let w = 0; w < input.cycleWeeks * 2 + 1; w++) for (const e of entries.filter(e => e.week === w % input.cycleWeeks)) {
      const s = { ...e, id: randomUUID(), tapperId: input.tapperId, date: actualDate(state,dateAt(input.anchor, w * 7 + e.weekday - 1),e.start) };
      validateOverlap({ staffShifts: proposed }, s); proposed.push(s);
    }
    const pattern = { id: old?.id ?? randomUUID(), tapperId: input.tapperId, cycleWeeks: input.cycleWeeks, anchor: input.anchor, entries, hoursVersion: state.workplace?.hoursVersion ?? 0, version: (old?.version ?? 0) + 1, appliedVersion: old?.appliedVersion, appliedHoursVersion: old?.appliedHoursVersion };
    state.crewPatterns = [...(state.crewPatterns ?? []).filter(p => p !== old), pattern];
    activity('크루 주간 기본 배정 저장'); return true;
  }
  if (!old) fail('기본 배정을 먼저 저장해 주세요.', 404);
  validRosterDate(input.from); validRosterDate(input.until);
  const count = (Date.parse(input.until) - Date.parse(input.from)) / 86400000 + 1;
  const today = businessDate(state,now);
  if (count < 1 || count > 90 || input.from < today) fail('오늘 이후, 최대 90일 범위를 선택해 주세요.');
  const inRange = date => date >= input.from && date <= input.until;
  const protectedShift = s => s.approvedRequestId || s.replacementForRequestId || s.status !== 'planned' || interval(s)[0] <= now.getTime() || hasAttendance(state, s, interval) || (state.shiftChangeRequests ?? []).some(r => r.shiftId === s.id && r.status === 'pending');
  const candidates = state.staffShifts.filter(s => s.patternId === old.id && inRange(s.base?.businessDate ?? s.base?.date ?? s.date));
  // Keep the whole occurrence date, even if its pattern times were later changed.
  // Also protect incoming crew replacements that belong to a different pattern.
  const preservedDates = new Set((state.attendance ?? []).filter(e => e.tapperId === old.tapperId).map(e => businessDate(state,e.at)));
  for (const s of state.staffShifts.filter(s => s.tapperId === old.tapperId)) {
    if (protectedShift(s) || s.patternId === old.id && !inRange(s.base?.businessDate ?? s.base?.date ?? s.date)) {
      preservedDates.add(businessDate(state,`${s.date}T${s.start}:00+09:00`));
      if (s.patternId === old.id) preservedDates.add(s.base?.businessDate ?? s.base?.date ?? s.date);
    }
  }
  const protectedIntervals = state.staffShifts.filter(s => s.tapperId === old.tapperId && protectedShift(s)).map(interval);
  const replaced = candidates.filter(s => !preservedDates.has(s.base?.businessDate ?? s.base?.date ?? s.date) && !protectedIntervals.some(([a,b]) => {const [c,d] = interval(s); return c < b && a < d;}));
  const next = state.staffShifts.filter(s => !replaced.includes(s));
  for (let n = 0; n < count; n++) {
    const date = dateAt(input.from, n), weekday = validRosterDate(date);
    if (preservedDates.has(date)) continue;
    const offset = Math.floor((Date.parse(date) - Date.parse(old.anchor)) / 604800000);
    const week = ((offset % old.cycleWeeks) + old.cycleWeeks) % old.cycleWeeks;
    const exception = state.workplace?.dateOverrides?.[date];
    if (exception?.closed === true) continue;
    const sourceDay = exception?.weekday ?? weekday;
    if (!exception && state.workplace?.days?.[weekday]?.length === 0) continue;
    for (const e of old.entries.filter(e => e.week === week && e.weekday === sourceDay)) {
      const shift = { ...validShift({ ...e, date:actualDate(state,date,e.start), tapperId: old.tapperId }, state), ...timeBandFields(state, e, sourceDay) };
      const [start, end] = interval(shift);
      if (start <= now.getTime() || protectedIntervals.some(([a,b]) => start < b && a < end)) continue;
      validateOverlap({ staffShifts: next }, shift);
      next.push({ ...shift, id: randomUUID(), status: 'planned', patternId: old.id, base: { ...timeBandFields(state, e, sourceDay), businessDate:date, date:shift.date, partId: shift.partId, start: shift.start, end: shift.end } });
    }
  }
  state.staffShifts = next;
  old.appliedVersion = old.version ?? 0;
  old.appliedHoursVersion = state.workplace?.hoursVersion ?? 0;
  old.appliedRange = {from: input.from, until: input.until};
  activity(`크루 기본 배정 적용 · ${input.from}~${input.until}`); return true;
}
