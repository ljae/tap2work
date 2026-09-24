import { randomUUID } from 'node:crypto';
import { StoreError } from './store.mjs';

const fail = (message, status = 400) => { throw new StoreError(message, status); };
const dateKst = value => new Date(new Date(value).getTime() + 9 * 3600000).toISOString().slice(0, 10);
const clock = value => new Date(new Date(value).getTime() + 9 * 3600000).toISOString().slice(11, 16);
const roles = ['owner', 'manager', 'crew'];
const duties = ['조리', '서빙1', '서빙2', 'cashier'];
const periods = ['monthly', 'weekly', 'daily'];
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
  if (!tapper) fail('Tapper를 찾지 못했어요.', 404);
  if (!duties.includes(input.duty) || !tapper.duties.includes(input.duty)) fail('담당 R&R을 확인해 주세요.');
  if (typeof input.date !== 'string' || !/^\d{4}-\d{2}-\d{2}$/.test(input.date) || (!Number.isFinite(Date.parse(`${input.date}T00:00:00Z`)) || new Date(`${input.date}T00:00:00Z`).toISOString().slice(0, 10) !== input.date)) fail('근무 날짜를 확인해 주세요.');
  if (!/^([01]\d|2[0-3]):[0-5]\d$/.test(input.start) || !/^([01]\d|2[0-3]):[0-5]\d$/.test(input.end) || input.start === input.end) fail('근무 시작·종료 시각을 확인해 주세요.');
  return { tapperId: tapper.id, duty: input.duty, date: input.date, start: input.start, end: input.end };
}

export function mutateStaff(state, input, actor, now, who, activity) {
  const leader = ['owner', 'manager'].includes(actor.role);
  const owner = actor.role === 'owner';
  switch (input.action) {
    case 'save_staffing_slots': {
      if (!leader) fail('매니저 이상만 슬롯을 바꿀 수 있어요.', 403);
      if (!Array.isArray(input.slots) || !input.slots.length || input.slots.length > 12) fail('슬롯은 1–12개로 설정해 주세요.');
      const slots = input.slots.map(slot => {
        if (!duties.includes(slot.duty) || !/^([01]\d|2[0-3]):[0-5]\d$/.test(slot.start) || !/^([01]\d|2[0-3]):[0-5]\d$/.test(slot.end) || slot.start >= slot.end) fail('역할과 당일 시작·종료 시간을 확인해 주세요.');
        return { id: typeof slot.id === 'string' && /^slot-[a-zA-Z0-9-]+$/.test(slot.id) ? slot.id : `slot-${randomUUID()}`, duty: slot.duty, start: slot.start, end: slot.end };
      });
      if (new Set(slots.map(s => s.id)).size !== slots.length) fail('중복 슬롯을 확인해 주세요.');
      for (const shift of state.staffShifts) if (shift.slotId && !slots.some(s => s.id === shift.slotId && s.duty === shift.duty && s.start === shift.start && s.end === shift.end)) delete shift.slotId;
      state.staffingSlots = slots; activity('일일 필요 인원 슬롯 저장'); return true;
    }
    case 'assign_staffing_slot': {
      if (!leader) fail('매니저 이상만 배정할 수 있어요.', 403);
      const slot = staffingSlots(state).find(s => s.id === input.slotId);
      if (!slot) fail('슬롯을 확인해 주세요.');
      const row = state.staffShifts.find(s => s.date === input.date && s.slotId === slot.id);
      if (input.tapperId === null) {
        if (row) state.staffShifts = state.staffShifts.filter(s => s.id !== row.id);
        activity('슬롯 배정 해제'); return true;
      }
      const next = validShift({ ...slot, date: input.date, tapperId: input.tapperId }, state);
      const source = input.sourceShiftId ? state.staffShifts.find(s => s.id === input.sourceShiftId) : null;
      if (input.sourceShiftId && (!source || source.tapperId !== input.tapperId)) fail('이동할 근무를 다시 확인해 주세요.', 409);
      if (row && row.id !== source?.id) fail('이미 배정된 슬롯이에요. 먼저 배정을 해제해 주세요.', 409);
      const start = Date.parse(`${next.date}T${next.start}:00+09:00`), end = Date.parse(`${next.date}T${next.end}:00+09:00`);
      if (state.staffShifts.some(s => {
        if (s.id === source?.id || s.tapperId !== next.tapperId || s.status === 'leave') return false;
        const a = Date.parse(`${s.date}T${s.start}:00+09:00`);
        let b = Date.parse(`${s.date}T${s.end}:00+09:00`); if (b <= a) b += 86400000;
        return a < end && b > start;
      })) fail('겹치는 근무가 있어요.', 409);
      if (source) Object.assign(source, next, { slotId: slot.id });
      else state.staffShifts.push({ id: randomUUID(), ...next, slotId: slot.id, status: 'planned' });
      activity('근무 슬롯 배정'); return true;
    }

    case 'save_tapper': {
      if (!owner) fail('사장님만 직원 정보를 바꿀 수 있어요.', 403);
      const row = input.id ? state.tappers.find(t => t.id === input.id) : null;
      if (input.id && !row) fail('Tapper를 찾지 못했어요.', 404);
      if (!roles.includes(input.rank) || !periods.includes(input.payPeriod)) fail('직급과 급여방식을 확인해 주세요.');
      if (!Array.isArray(input.duties) || !input.duties.length || input.duties.some(d => !duties.includes(d))) fail('R&R을 선택해 주세요.');
      const kakaoUrl = safeText(input.kakaoUrl ?? '', 250, '카카오톡 링크', false);
      if (kakaoUrl) {
        let url;
        try { url = new URL(kakaoUrl); } catch { fail('HTTPS 카카오톡 링크를 입력해 주세요.'); }
        if (url.protocol !== 'https:') fail('HTTPS 카카오톡 링크를 입력해 주세요.');
      }
      const phone = safeText(input.phone ?? '', 30, '전화번호', false);
      if (phone && !/^\+?[0-9 -]{7,30}$/.test(phone)) fail('전화번호를 확인해 주세요.');
      const next = { rank: input.rank, nickname: safeText(input.nickname, 40, '별칭'), duties: [...new Set(input.duties)],
        hourlyWon: nonnegative(input.hourlyWon, '시급'), payPeriod: input.payPeriod,
        kakaoUrl, phone, active: input.active !== false };
      if (row) Object.assign(row, next); else state.tappers.push({ id: randomUUID(), ...next });
      activity(`${next.nickname} Tapper 정보 저장`); return true;
    }
    case 'save_staff_shift': {
      if (!leader) fail('매니저 이상만 근무표를 바꿀 수 있어요.', 403);
      const next = validShift(input, state);
      const row = input.id ? state.staffShifts.find(s => s.id === input.id) : null;
      if (input.id && !row) fail('근무를 찾지 못했어요.', 404);
      if (row) Object.assign(row, next); else state.staffShifts.push({ id: randomUUID(), ...next, status: 'planned' });
      activity(`${state.tappers.find(t => t.id === next.tapperId).nickname} 근무 배정`); return true;
    }
    case 'clock_in': case 'break_start': case 'break_end': case 'clock_out': {
      const tapper = state.tappers.find(t => t.actorId === actor.id && t.active);
      if (!tapper) fail('이 데모 역할에 연결된 Tapper가 없어요.', 403);
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
      if (!state.tappers.some(t => t.id === input.tapperId)) fail('Tapper를 찾지 못했어요.', 404);
      const amount = nonnegative(input.amountWon, '금액');
      const date = input.date && /^\d{4}-\d{2}-\d{2}$/.test(input.date) ? input.date : dateKst(now);
      const row = { id: randomUUID(), tapperId: input.tapperId, date, amountWon: amount, createdAt: iso(now), createdBy: who };
      if (input.action === 'add_pay_adjustment') {
        row.note = safeText(input.note, 200, '추가보수 설명'); state.payAdjustments.push(row);
      } else state.payRecords.push(row);
      activity(`${input.action === 'record_payment' ? '급여 지급 기록' : '추가보수'} ${amount}원`); return true;
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
    const start = periodStart(day, t.payPeriod);
    const actualMinutes = rangeMinutes(sessions, start, now);
    const weeklyActualMinutes = rangeMinutes(sessions, periodStart(day, 'weekly'), now);
    const monthlyMinutes = rangeMinutes(sessions, periodStart(day, 'monthly'), now);
    const weekEnd = new Date(`${periodStart(day, 'weekly')}T00:00:00Z`);
    weekEnd.setUTCDate(weekEnd.getUTCDate() + 6);
    const plannedMinutes = state.staffShifts.filter(s => s.tapperId === t.id && s.date >= periodStart(day, 'weekly') && s.date <= weekEnd.toISOString().slice(0, 10)).reduce((n, s) => {
      const [sh, sm] = s.start.split(':').map(Number), [eh, em] = s.end.split(':').map(Number);
      return n + ((eh * 60 + em - sh * 60 - sm + 1440) % 1440);
    }, 0);
    const adjustments = state.payAdjustments.filter(a => a.tapperId === t.id && a.date >= start && a.date <= day).reduce((n, a) => n + a.amountWon, 0);
    const paid = state.payRecords.filter(p => p.tapperId === t.id && p.date >= start && p.date <= day).reduce((n, p) => n + p.amountWon, 0);
    const gross = Math.round(actualMinutes * t.hourlyWon / 60) + adjustments;
    const monthAdjustments = state.payAdjustments.filter(a => a.tapperId === t.id && a.date >= periodStart(day, 'monthly') && a.date <= day).reduce((n, a) => n + a.amountWon, 0);
    const view = { ...t, plannedMinutes, actualMinutes, weeklyActualMinutes, payPeriodStart: start,
      attendanceState: state.attendance.filter(e => e.tapperId === t.id && !e.voidedAt).at(-1)?.type ?? 'off_duty' };
    if (owner || t.id === own?.id) Object.assign(view, { adjustments, paid, gross, remaining: gross - paid, monthlyGross: Math.round(monthlyMinutes * t.hourlyWon / 60) + monthAdjustments });
    else { delete view.hourlyWon; delete view.payPeriod; delete view.kakaoUrl; delete view.phone; }
    return view;
  });
  return { staffingSlots: staffingSlots(state), tappers, staffShifts: state.staffShifts, attendance: state.attendance.filter(e => owner || e.tapperId === own?.id),
    payAdjustments: owner ? state.payAdjustments : [], payRecords: owner ? state.payRecords : [], payPolicy: owner ? state.payPolicy : undefined };
}

function staffingSlots(state) {
  return state.staffingSlots ?? [
    { id: 'slot-0', duty: '조리', start: '09:00', end: '18:00' },
    { id: 'slot-1', duty: '서빙1', start: '09:00', end: '18:00' },
    { id: 'slot-2', duty: 'cashier', start: '09:00', end: '18:00' },
  ];
}
