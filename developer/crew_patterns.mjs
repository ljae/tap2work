import { randomUUID } from 'node:crypto';
import { StoreError } from './store.mjs';
import { validRosterDate } from './parts.mjs';
const fail = (s, status = 400) => { throw new StoreError(s, status); };
const dateAt = (date, n) => new Date(Date.parse(`${date}T00:00:00Z`) + n * 86400000).toISOString().slice(0, 10);

// Base assignments stay on each generated shift. Calendar edits change only the
// effective fields, so reapplication is explicit, bounded and atomic.
export function mutateCrewPattern(state, input, actor, now, activity, validShift, validateOverlap, interval) {
  if (!['save_crew_pattern', 'apply_crew_pattern'].includes(input.action)) return false;
  if (!['owner', 'manager'].includes(actor.role)) fail('매니저 이상만 배정할 수 있어요.', 403);
  if (!state.tappers.some(t => t.id === input.tapperId && t.active)) fail('크루를 찾지 못했어요.',404);
  const old = (state.crewPatterns ?? []).find(p => p.tapperId === input.tapperId);
  if (input.action === 'save_crew_pattern') {
    if (![1, 2].includes(input.cycleWeeks) || validRosterDate(input.anchor) !== 1) fail('주기와 A주 시작 월요일을 확인해 주세요.');
    if (!Array.isArray(input.entries) || input.entries.length > 28) fail('주간 배정을 확인해 주세요.');
    const entries = input.entries.map(e => {
      if (!Number.isInteger(e.week) || e.week < 0 || e.week >= input.cycleWeeks || !Number.isInteger(e.weekday) || e.weekday < 1 || e.weekday > 7) fail('배정 요일을 확인해 주세요.');
      const next = validShift({ ...e, tapperId: input.tapperId, date: dateAt(input.anchor, e.week * 7 + e.weekday - 1) }, state);
      return { week: e.week, weekday: e.weekday, partId: next.partId, start: next.start, end: next.end };
    });
    // Validate adjacent weeks, including Sunday overnight crossing the cycle.
    const proposed = [];
    for (let w = 0; w < input.cycleWeeks * 2 + 1; w++) for (const e of entries.filter(e => e.week === w % input.cycleWeeks)) {
      const s = { ...e, id: randomUUID(), tapperId: input.tapperId, date: dateAt(input.anchor, w * 7 + e.weekday - 1) };
      validateOverlap({ staffShifts: proposed }, s); proposed.push(s);
    }
    const pattern = { id: old?.id ?? randomUUID(), tapperId: input.tapperId, cycleWeeks: input.cycleWeeks, anchor: input.anchor, entries };
    state.crewPatterns = [...(state.crewPatterns ?? []).filter(p => p !== old), pattern];
    activity('크루 주간 기본 배정 저장'); return true;
  }
  if (!old) fail('기본 배정을 먼저 저장해 주세요.', 404);
  validRosterDate(input.from); validRosterDate(input.until);
  const count = (Date.parse(input.until) - Date.parse(input.from)) / 86400000 + 1;
  const today = new Date(now.getTime() + 9 * 3600000).toISOString().slice(0, 10);
  if (count < 1 || count > 90 || input.from < today) fail('오늘 이후, 최대 90일 범위를 선택해 주세요.');
  const inRange = date => date >= input.from && date <= input.until;
  const protectedShift = s => s.approvedRequestId || s.status !== 'planned' || interval(s)[0] <= now.getTime() || (state.attendance ?? []).some(e => e.tapperId === s.tapperId && new Date(Date.parse(e.at) + 9 * 3600000).toISOString().slice(0, 10) === s.date);
  const replaced = state.staffShifts.filter(s => s.patternId === old.id && inRange(s.base?.date ?? s.date));
  if (replaced.some(s => protectedShift(s) || !inRange(s.date))) fail('이미 시작한 근무 또는 범위 밖으로 이동한 근무가 있어요. 적용 기간을 다시 확인해 주세요.', 409);
  const next = state.staffShifts.filter(s => !replaced.includes(s));
  for (let n = 0; n < count; n++) {
    const date = dateAt(input.from, n), weekday = validRosterDate(date);
    const offset = Math.floor((Date.parse(date) - Date.parse(old.anchor)) / 604800000);
    const week = ((offset % old.cycleWeeks) + old.cycleWeeks) % old.cycleWeeks;
    for (const e of old.entries.filter(e => e.week === week && e.weekday === weekday)) {
      const shift = validShift({ ...e, date, tapperId: old.tapperId }, state);
      if (interval(shift)[0] <= now.getTime()) continue;
      validateOverlap({ staffShifts: next }, shift);
      next.push({ ...shift, id: randomUUID(), status: 'planned', patternId: old.id, base: { date, partId: shift.partId, start: shift.start, end: shift.end } });
    }
  }
  state.staffShifts = next;
  activity(`크루 기본 배정 적용 · ${input.from}~${input.until}`); return true;
}
