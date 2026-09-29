import { mutateShiftRequest } from './shift_requests.mjs';
import { mutateCrewPattern } from './crew_patterns.mjs';
import { payrollSettings, savePayrollSettings, settlementPeriod, roundedWorkMinutes } from './payroll_settings.mjs';
import { validatePart, crewPartIds, partForLegacy } from './parts.mjs';
import { laborView, weekOf } from './labor.mjs';
import { randomUUID } from 'node:crypto';
import { StoreError } from './store.mjs';

const fail = (message, status = 400) => { throw new StoreError(message, status); };
const dateKst = value => new Date(new Date(value).getTime() + 9 * 3600000).toISOString().slice(0, 10);
const clock = value => new Date(new Date(value).getTime() + 9 * 3600000).toISOString().slice(11, 16);
const roles = ['owner', 'manager', 'crew'];
const duties = ['조리', '서빙1', '서빙2', 'cashier'];
const periods = ['monthly', 'weekly', 'daily'];
const employmentTypes = ['정규직', '시간알바', '정규알바'];
const safeText = (value, max, label, required = true) => {
  if (typeof value !== 'string' || value.length > max || (required && !value.trim())) fail(`${label}을 확인해 주세요.`);
  return value.trim();
};
const nonnegative = (value, label) => {
  if (!Number.isSafeInteger(value) || value < 0 || value > 100000000) fail(`${label}은 0 이상의 원 단위 정수로 입력해 주세요.`);
  return value;
};
const iso = value => new Date(value).toISOString();
const minutes = (a, b) => Math.max(0, Math.round((new Date(b) - new Date(a)) / 60000));

export function ensureStaff(state, now) {
  if (state.staffVersion === 1) {
    if (state.staffingSlots) return false;
    state.staffingSlots = staffingSlots(state);
    const occupied = new Set();
    for (const shift of state.staffShifts) {
      const slot = state.staffingSlots.find(slot => slot.duty === shift.duty && slot.start === shift.start && slot.end === shift.end && !occupied.has(`${shift.date}/${slot.id}`));
      if (slot) { shift.slotId = slot.id; occupied.add(`${shift.date}/${slot.id}`); }
    }
    return true;
  }
  state.tappers = [
    { id: 'tapper-owner', actorId: 'owner', rank: 'owner', nickname: '서연', duties: ['cashier'], hourlyWon: 12000, payPeriod: 'monthly', kakaoUrl: '', phone: '', active: true },
    { id: 'tapper-manager', actorId: 'manager', rank: 'manager', nickname: '민지', duties: ['서빙1', 'cashier'], hourlyWon: 11000, payPeriod: 'monthly', kakaoUrl: '', phone: '', active: true },
    { id: 'tapper-cook', actorId: 'cook', rank: 'crew', nickname: '현우', duties: ['조리'], hourlyWon: 10000, payPeriod: 'weekly', kakaoUrl: '', phone: '', active: true },
    { id: 'tapper-crew', actorId: 'crew', rank: 'crew', nickname: '지우', duties: ['서빙2'], hourlyWon: 10000, payPeriod: 'daily', kakaoUrl: '', phone: '', active: true },
    { id: 'tapper-sample', rank: 'crew', nickname: '가은', duties: ['서빙1'], hourlyWon: 10000, payPeriod: 'weekly', kakaoUrl: '', phone: '', active: true },
  ];
  const day = dateKst(now);
  state.staffShifts = [
    ['tapper-manager', '서빙1', '09:00', '18:00'], ['tapper-cook', '조리', '10:00', '19:00'],
    ['tapper-crew', '서빙2', '11:00', '15:00'], ['tapper-sample', '서빙1', '18:00', '22:00'],
  ].map(([tapperId, duty, start, end], index) => ({ id: `staff-shift-${index + 1}`, tapperId, duty, date: day, start, end, status: 'planned' }));
  state.attendance = [];
  state.payAdjustments = [];
  state.payRecords = [];
  state.payPolicy = { rounding: 'nearest_won', breaksPaid: false, statutoryPremiumsConfigured: false };
  state.staffVersion = 1;
  ensureStaff(state, now);
  return true;
}

function validShift(input, state) {
  const tapper = state.tappers.find(row => row.id === input.tapperId && row.active);
  if (!tapper) fail('크루를 찾지 못했어요.', 404);
  const partId = Object.hasOwn(input, 'partId') ? validatePart(state, input.partId) : partForLegacy(state, input.duty);
  if (Object.hasOwn(input, 'partId') ? !crewPartIds(state, tapper).includes(partId) : !duties.includes(input.duty) || !tapper.duties.includes(input.duty)) fail('담당 파트를 확인해 주세요.');
  if (typeof input.date !== 'string' || !/^\d{4}-\d{2}-\d{2}$/.test(input.date) || (!Number.isFinite(Date.parse(`${input.date}T00:00:00Z`)) || new Date(`${input.date}T00:00:00Z`).toISOString().slice(0, 10) !== input.date)) fail('근무 날짜를 확인해 주세요.');
  if (!/^([01]\d|2[0-3]):[0-5]\d$/.test(input.start) || !/^([01]\d|2[0-3]):[0-5]\d$/.test(input.end) || input.start === input.end) fail('근무 시작·종료 시각을 확인해 주세요.');
  if (![input.start, input.end].every(v => ['00', '30'].includes(v.slice(3)))) fail('근무 시간은 30분 단위로 입력해 주세요.');
  const employmentType = input.employmentType ?? tapper.employmentType ?? '시간알바';
  if (!employmentTypes.includes(employmentType)) fail('고용형태를 확인해 주세요.');
  return { ...(Object.hasOwn(input,'label') ? {label:safeText(input.label,100,'근무 이름',false)} : {}), tapperId: tapper.id, partId, duty: input.duty ?? state.workplace?.parts.find(p => p.id === partId)?.duties?.[0] ?? partId, date: input.date, start: input.start, end: input.end, employmentType };
}
function interval(shift) {
  const start = Date.parse(`${shift.date}T${shift.start}:00+09:00`);
  let end = Date.parse(`${shift.date}T${shift.end}:00+09:00`);
  if (end <= start) end += 86400000;
  return [start, end];
}
function validateOverlap(state, candidate, excluded = new Set()) {
  const [a, b] = interval(candidate);
  if (state.staffShifts.some(s => !excluded.has(s.id) && s.tapperId === candidate.tapperId && s.status !== 'leave' && (() => { const [c, d] = interval(s); return a < d && c < b; })())) fail('겹치는 근무가 있어요.', 409);
}
const addDays = (date, count) => new Date(Date.parse(`${date}T00:00:00Z`) + count * 86400000).toISOString().slice(0, 10);

export function mutateStaff(state, input, actor, now, who, activity) {
  const leader = ['owner', 'manager'].includes(actor.role);
  const owner = actor.role === 'owner';
  if (mutateShiftRequest(state,input,actor,now,activity,validShift,validateOverlap,interval)) return true;
  if (mutateCrewPattern(state, input, actor, now, activity, validShift, validateOverlap, interval)) return true;
  switch (input.action) {
    case 'save_payroll_settings': savePayrollSettings(state,input,actor,now); activity('매장 정산 설정 저장', 'pay'); return true;
    case 'save_labor_review': {
      if (!owner) fail('사장님만 인건비 조건을 저장할 수 있어요.', 403);
      const r = input.review;
      if (!r || !state.tappers.some(t => t.id === r.tapperId && t.rank !== 'owner')) fail('직원을 확인해 주세요.');
      if (typeof r.week !== 'string' || !/^\d{4}-\d{2}-\d{2}$/.test(r.week) || !Number.isFinite(Date.parse(r.week)) || new Date(r.week).toISOString().slice(0,10) !== r.week || weekOf(r.week) !== r.week) fail('주 시작일은 월요일로 선택해 주세요.');
      if (!['unknown', 'under5', 'fivePlus'].includes(r.size) || !['unknown', 'standard'].includes(r.scope) || !['unknown', 'met', 'unmet'].includes(r.attendance)) fail('수당 계산 조건을 확인해 주세요.');
      for (const [key, max] of [['hourlyWon',1000000],['ordinaryHourlyWon',1000000],['averageWeeklyMinutes',2400],['restMinutes',480],['otherPaidHolidayMinutes',3360]]) {
        if (!Number.isInteger(r[key]) || r[key] < 0 || r[key] > max) fail('금액과 소정근로·유급휴일 시간을 확인해 주세요.');
      }
      if (r.scope === 'standard' && (r.hourlyWon < 1 || r.ordinaryHourlyWon < 1)) fail('기본시급·통상시급을 1원 이상 입력해 주세요.');
      if (r.averageWeeklyMinutes >= 900 && r.attendance === 'met' && r.restMinutes === 0) fail('주휴 지급시간을 확인해 주세요.');
      if (!Array.isArray(r.dailyContractMinutes) || r.dailyContractMinutes.length !== 7 || r.dailyContractMinutes.some(n => !Number.isInteger(n) || n < 0 || n > 480)) fail('요일별 소정근로시간을 확인해 주세요.');
      if (r.shortTime && r.dailyContractMinutes.reduce((a,b)=>a+b,0) > 2400) fail('주 소정근로시간은 40시간 이내로 확인해 주세요.');
      if (!Array.isArray(r.holidayDates) || r.holidayDates.length > 7 || r.holidayDates.some(d => typeof d !== 'string' || !/^\d{4}-\d{2}-\d{2}$/.test(d) || !Number.isFinite(Date.parse(d)) || new Date(d).toISOString().slice(0,10) !== d || d < r.week || d > addDays(r.week,6))) fail('휴일 날짜를 확인해 주세요.');
      const row = { tapperId: r.tapperId, week: r.week, size: r.size, scope: r.scope, attendance: r.attendance,
        hourlyWon: r.hourlyWon, ordinaryHourlyWon: r.ordinaryHourlyWon, averageWeeklyMinutes: r.averageWeeklyMinutes, restMinutes: r.restMinutes,
        otherPaidHolidayMinutes: r.otherPaidHolidayMinutes, shortTime: r.shortTime === true, dailyContractMinutes: r.dailyContractMinutes,
        holidayDates: [...new Set(r.holidayDates)], holidaysConfirmed: r.holidaysConfirmed === true, updatedAt: iso(now) };
      state.laborReviews = (state.laborReviews ?? []).filter(v => v.week !== row.week || v.tapperId !== row.tapperId);
      state.laborReviews.push(row); activity('주간 인건비 계산 조건 저장', 'pay'); return true;
    }
    case 'save_staffing_slots': {
      if (!leader) fail('매니저 이상만 슬롯을 바꿀 수 있어요.', 403);
      if (!Array.isArray(input.slots) || !input.slots.length || input.slots.length > 12) fail('슬롯은 1–12개로 설정해 주세요.');
      const slots = input.slots.map(slot => {
        if (!duties.includes(slot.duty) || !/^([01]\d|2[0-3]):(00|30)$/.test(slot.start) || !/^([01]\d|2[0-3]):(00|30)$/.test(slot.end) || slot.start >= slot.end) fail('역할과 30분 단위 시작·종료 시간을 확인해 주세요.');
        const weekdays = slot.weekdays ?? [1,2,3,4,5,6,7];
        if (!Array.isArray(weekdays) || weekdays.some(n => !Number.isInteger(n) || n < 1 || n > 7) || new Set(weekdays).size !== weekdays.length) fail('필요 슬롯 요일을 확인해 주세요.');
        return { weekdays, id: typeof slot.id === 'string' && /^slot-[a-zA-Z0-9-]+$/.test(slot.id) ? slot.id : `slot-${randomUUID()}`, duty: slot.duty, start: slot.start, end: slot.end };
      });
      if (new Set(slots.map(s => s.id)).size !== slots.length) fail('중복 슬롯을 확인해 주세요.');
      for (const shift of state.staffShifts) if (shift.slotId && !slots.some(s => s.id === shift.slotId && s.duty === shift.duty && s.start === shift.start && s.end === shift.end)) delete shift.slotId;
      state.staffingSlots = slots; activity('일일 필요 인원 슬롯 저장'); return true;
    }
    case 'assign_staffing_slot': {
      if (!leader) fail('매니저 이상만 배정할 수 있어요.', 403);
      const slot = staffingSlots(state).find(s => s.id === input.slotId);
      if (!slot) fail('슬롯을 확인해 주세요.');
      if (input.tapperId !== null && slot.weekdays && !slot.weekdays.includes(new Date(`${input.date}T00:00:00Z`).getUTCDay() || 7)) fail('해당 요일에 필요하지 않은 슬롯이에요.');
      const row = input.shiftId ? state.staffShifts.find(s => s.id === input.shiftId && s.date === input.date && s.duty === slot.duty && s.start === slot.start && s.end === slot.end) : state.staffShifts.find(s => s.date === input.date && s.slotId === slot.id);
      if (input.shiftId && !row) fail('배정이 변경됐어요. 다시 확인해 주세요.', 409);
      if (input.tapperId === null) {
        if (row) state.staffShifts = state.staffShifts.filter(s => s.id !== row.id);
        activity('슬롯 배정 해제'); return true;
      }
      const next = validShift({ ...slot, date: input.date, tapperId: input.tapperId }, state);
      const source = input.sourceShiftId ? state.staffShifts.find(s => s.id === input.sourceShiftId) : null;
      if (input.sourceShiftId && (!source || source.tapperId !== input.tapperId)) fail('이동할 근무를 다시 확인해 주세요.', 409);
      if (row && row.id !== source?.id) fail('이미 배정된 슬롯이에요. 먼저 배정을 해제해 주세요.', 409);
      validateOverlap(state, next, new Set(source ? [source.id] : []));
      if (source) Object.assign(source, next, { slotId: slot.id });
      else state.staffShifts.push({ id: randomUUID(), ...next, slotId: slot.id, status: 'planned' });
      activity('근무 슬롯 배정'); return true;
    }

    case 'save_tapper': {
      if (!owner) fail('사장님만 직원 정보를 바꿀 수 있어요.', 403);
      const row = input.id ? state.tappers.find(t => t.id === input.id) : null;
      if (input.id && !row) fail('크루를 찾지 못했어요.', 404);
      if (!roles.includes(input.rank) || !periods.includes(input.payPeriod)) fail('직급과 급여방식을 확인해 주세요.');
      if (input.partIds !== undefined) {
        if (!Array.isArray(input.partIds) || !input.partIds.length) fail('파트를 선택해 주세요.');
        input.partIds.forEach(id => validatePart(state, id));
      } else if (!Array.isArray(input.duties) || !input.duties.length || input.duties.some(d => !duties.includes(d))) fail('파트를 선택해 주세요.');
      const kakaoUrl = safeText(input.kakaoUrl ?? '', 250, '카카오톡 링크', false);
      if (kakaoUrl) {
        let url;
        try { url = new URL(kakaoUrl); } catch { fail('HTTPS 카카오톡 링크를 입력해 주세요.'); }
        if (url.protocol !== 'https:') fail('HTTPS 카카오톡 링크를 입력해 주세요.');
      }
      const phone = safeText(input.phone ?? '', 30, '전화번호', false);
      if (phone && !/^\+?[0-9 -]{7,30}$/.test(phone)) fail('전화번호를 확인해 주세요.');
      if (!employmentTypes.includes(input.employmentType ?? row?.employmentType ?? '시간알바')) fail('고용형태를 확인해 주세요.');
      const next = { rank: input.rank, nickname: safeText(input.nickname, 40, '별칭'), duties: [...new Set(input.duties ?? row?.duties ?? [])], ...(input.partIds ? {workProfile: {...row?.workProfile, partIds: [...new Set(input.partIds)], bands: row?.workProfile?.bands ?? []}} : {}), employmentType: input.employmentType ?? row?.employmentType ?? '시간알바',
        hourlyWon: nonnegative(input.hourlyWon, '시급'), payPeriod: input.payPeriod,
        kakaoUrl, phone, active: input.active !== false };
      if (row) Object.assign(row, next); else state.tappers.push({ id: randomUUID(), ...next });
      activity(`${next.nickname} 크루 정보 저장`); return true;
    }
    case 'delete_staff_shift': {
      if (!leader) fail('매니저 이상만 근무표를 바꿀 수 있어요.', 403);
      if (!state.staffShifts.some(s => s.id === input.id)) fail('근무를 찾지 못했어요.', 404);
      state.staffShifts = state.staffShifts.filter(s => s.id !== input.id);
      activity('근무 배정 해제'); return true;
    }
    case 'save_staff_shift': {
      if (!leader) fail('매니저 이상만 근무표를 바꿀 수 있어요.', 403);
      const next = validShift(input, state);
      const row = input.id ? state.staffShifts.find(s => s.id === input.id) : null;
      if (input.id && !row) fail('근무를 찾지 못했어요.', 404);
      validateOverlap(state, next, new Set(row ? [row.id] : []));
      if (row) {
        if (row.tapperId !== next.tapperId) { delete row.patternId; delete row.base; }
        Object.assign(row, next);
      } else state.staffShifts.push({ id: randomUUID(), ...next, status: 'planned' });
      activity(`${state.tappers.find(t => t.id === next.tapperId).nickname} 근무 배정`); return true;
    }
    case 'save_shift_pattern': {
      if (!leader) fail('매니저 이상만 근무표를 바꿀 수 있어요.', 403);
      validShift(input, state);
      const weekdays = input.weekdays ?? [];
      if (!Array.isArray(weekdays) || weekdays.some(n => !Number.isInteger(n) || n < 1 || n > 7) || new Set(weekdays).size !== weekdays.length) fail('반복 요일을 확인해 주세요.');
      const days = input.repeatDays ?? 1;
      if (!Number.isInteger(days) || days < 1 || days > 90 || (days > 1 && !weekdays.length)) fail('반복 기간은 90일 이내로 선택해 주세요.');
      const existing = input.id ? state.staffShifts.find(s => s.id === input.id) : null;
      if (input.id && !existing) fail('근무를 찾지 못했어요.', 404);
      if (existing && days > 1) fail('반복 근무는 각 근무를 선택해 수정해 주세요.');
      const proposed = [];
      for (let n = 0; n < days; n++) {
        const date = addDays(input.date, n);
        if (days > 1 && !weekdays.includes(new Date(`${date}T00:00:00Z`).getUTCDay() || 7)) continue;
        const shift = validShift({ ...input, date }, state);
        const key = `${shift.tapperId}/${shift.date}/${shift.duty}/${shift.start}/${shift.end}`;
        if (!existing && state.staffShifts.some(s => `${s.tapperId}/${s.date}/${s.duty}/${s.start}/${s.end}` === key)) continue;
        validateOverlap(state, shift, new Set(existing ? [existing.id] : []));
        proposed.push(shift);
      }
      if (existing) { Object.assign(existing, proposed[0]); delete existing.slotId; }
      else for (const shift of proposed) state.staffShifts.push({ id: randomUUID(), ...shift, status: 'planned' });
      activity(`근무 ${proposed.length}건 저장`); return true;
    }
    case 'clock_in': case 'break_start': case 'break_end': case 'clock_out': {
      const tapper = state.tappers.find(t => t.actorId === actor.id && t.active);
      if (!tapper) fail('이 데모 역할에 연결된 크루가 없어요.', 403);
      const events = state.attendance.filter(e => e.tapperId === tapper.id && !e.voidedAt);
      const last = events.at(-1)?.type;
      const next = input.action;
      const allowed = next === 'clock_in' ? (!last || last === 'clock_out') : next === 'break_start' ? last === 'clock_in' || last === 'break_end' : next === 'break_end' ? last === 'break_start' : last === 'clock_in' || last === 'break_end';
      if (!allowed) fail('현재 출퇴근 상태에서 이 동작을 할 수 없어요.', 409);
      if (input.eventId && state.attendance.some(e => e.id === input.eventId)) fail('이미 기록된 출퇴근 요청이에요.', 409);
      state.attendance.push({ id: input.eventId || randomUUID(), tapperId: tapper.id, type: next, at: iso(now), recordedBy: who });
      activity(`${tapper.nickname} ${next}`); return true;
    }
    case 'adjust_attendance': {
      if (!owner) fail('사장님만 근태를 보정할 수 있어요.', 403);
      const event = state.attendance.find(e => e.id === input.eventId && !e.voidedAt);
      if (!event) fail('근태 기록을 찾지 못했어요.', 404);
      const adjustedAt = new Date(input.at);
      if (!Number.isFinite(adjustedAt.getTime())) fail('보정 시각을 확인해 주세요.');
      event.voidedAt = iso(now); event.voidedBy = who;
      state.attendance.push({ id: randomUUID(), tapperId: event.tapperId, type: event.type, at: iso(adjustedAt), recordedBy: who, correctionOf: event.id, reason: safeText(input.reason, 200, '보정 사유') });
      activity('근태 기록 보정'); return true;
    }
    case 'add_pay_adjustment': case 'record_payment': {
      if (!owner) fail('사장님만 급여 내역을 바꿀 수 있어요.', 403);
      if (!state.tappers.some(t => t.id === input.tapperId)) fail('크루를 찾지 못했어요.', 404);
      const amount = nonnegative(input.amountWon, '금액');
      const date = input.date && /^\d{4}-\d{2}-\d{2}$/.test(input.date) ? input.date : dateKst(now);
      const row = { id: randomUUID(), tapperId: input.tapperId, date, amountWon: amount, createdAt: iso(now), createdBy: who };
      if (input.action === 'add_pay_adjustment') {
        row.note = safeText(input.note, 200, '추가보수 설명'); state.payAdjustments.push(row);
      } else state.payRecords.push(row);
      activity(`${input.action === 'record_payment' ? '급여 지급 기록' : '추가보수'} ${amount}원`, 'pay'); return true;
    }
    default: return false;
  }
}

function completedSessions(events) {
  const result = [];
  let start, segmentStart, segments = [];
  for (const event of events.filter(e => !e.voidedAt).sort((a, b) => a.at.localeCompare(b.at))) {
    if (event.type === 'clock_in') { start = event.at; segmentStart = event.at; segments = []; }
    if (event.type === 'break_start' && segmentStart) { segments.push({ start: segmentStart, end: event.at }); segmentStart = null; }
    if (event.type === 'break_end' && start) segmentStart = event.at;
    if (event.type === 'clock_out' && start) {
      if (segmentStart) segments.push({ start: segmentStart, end: event.at });
      result.push({ start, end: event.at, segments }); start = null; segmentStart = null;
    }
  }
  return result;
}
function periodStart(day, period) {
  if (period === 'daily') return day;
  if (period === 'monthly') return `${day.slice(0, 7)}-01`;
  const d = new Date(`${day}T00:00:00Z`); d.setUTCDate(d.getUTCDate() - (d.getUTCDay() + 6) % 7); return d.toISOString().slice(0, 10);
}
function rangeMinutes(sessions, startDate, end) {
  const from = new Date(`${startDate}T00:00:00+09:00`).getTime();
  const until = new Date(end).getTime();
  return sessions.reduce((total, session) => total + session.segments.reduce((sum, segment) => {
    const start = Math.max(from, new Date(segment.start).getTime());
    const stop = Math.min(until, new Date(segment.end).getTime());
    return sum + Math.max(0, Math.round((stop - start) / 60000));
  }, 0), 0);
}
export function staffView(state, actor, now) {
  const day = dateKst(now);
  const own = state.tappers.find(t => t.actorId === actor.id);
  const owner = actor.role === 'owner';
  const tappers = (state.tappers ?? []).map(t => {
    const sessions = completedSessions(state.attendance.filter(e => e.tapperId === t.id));
    const policy = payrollSettings(state);
    const period = policy.configured ? settlementPeriod(day,policy) : null;
    const start = period?.start ?? periodStart(day, t.payPeriod);
    const actualMinutes = rangeMinutes(sessions, start, now);
    const weeklyActualMinutes = rangeMinutes(sessions, periodStart(day, 'weekly'), now);
    const monthlyMinutes = rangeMinutes(sessions, periodStart(day, 'monthly'), now);
    const weekEnd = new Date(`${periodStart(day, 'weekly')}T00:00:00Z`);
    weekEnd.setUTCDate(weekEnd.getUTCDate() + 6);
    const plannedMinutes = state.staffShifts.filter(s => s.status !== 'leave' && s.tapperId === t.id && s.date >= periodStart(day, 'weekly') && s.date <= weekEnd.toISOString().slice(0, 10)).reduce((n, s) => {
      const [sh, sm] = s.start.split(':').map(Number), [eh, em] = s.end.split(':').map(Number);
      return n + ((eh * 60 + em - sh * 60 - sm + 1440) % 1440);
    }, 0);
    const adjustments = state.payAdjustments.filter(a => a.tapperId === t.id && a.date >= start && a.date <= day).reduce((n, a) => n + a.amountWon, 0);
    const paid = state.payRecords.filter(p => p.tapperId === t.id && p.date >= start && p.date <= day).reduce((n, p) => n + p.amountWon, 0);
    const settledMinutes = policy.configured ? roundedWorkMinutes(sessions.flatMap(s=>s.segments), Date.parse(`${start}T00:00:00+09:00`), new Date(now).getTime(),policy.roundingMinutes) : actualMinutes;
    const gross = Math.round(settledMinutes * t.hourlyWon / 60) + adjustments;
    const monthAdjustments = state.payAdjustments.filter(a => a.tapperId === t.id && a.date >= periodStart(day, 'monthly') && a.date <= day).reduce((n, a) => n + a.amountWon, 0);
    const view = { ...t, plannedMinutes, actualMinutes, weeklyActualMinutes, payPeriodStart: start,
      attendanceState: state.attendance.filter(e => e.tapperId === t.id && !e.voidedAt).at(-1)?.type ?? 'off_duty' };
    if (owner) Object.assign(view, { payPeriod:policy.configured?policy.cycle:t.payPeriod, payPeriodEnd:period?.end, settledMinutes, adjustments, paid, gross, remaining: gross - paid, monthlyGross: Math.round(monthlyMinutes * t.hourlyWon / 60) + monthAdjustments });
    else { delete view.hourlyWon; delete view.payPeriod; delete view.payPeriodStart; delete view.kakaoUrl; delete view.phone; }
    return view;
  });
  return { ...(owner ? {payrollSettings:payrollSettings(state),labor: laborView(state, id => completedSessions(state.attendance.filter(e => e.tapperId === id)), day)} : {}), staffingSlots: staffingSlots(state), tappers, staffShifts: state.staffShifts, attendance: state.attendance.filter(e => owner || e.tapperId === own?.id),
    payAdjustments: owner ? state.payAdjustments : [], payRecords: owner ? state.payRecords : [], payPolicy: owner ? state.payPolicy : undefined };
}

function staffingSlots(state) {
  return state.staffingSlots ?? [
    { id: 'slot-0', duty: '조리', start: '09:00', end: '18:00' },
    { id: 'slot-1', duty: '서빙1', start: '09:00', end: '18:00' },
    { id: 'slot-2', duty: 'cashier', start: '09:00', end: '18:00' },
  ];
}
