import { hasAttendance, requestedRanges, rangeFields } from './schedule_exceptions.mjs';
import { randomUUID } from 'node:crypto';
import { StoreError } from './store.mjs';
const fail=(m,s=400)=>{throw new StoreError(m,s);};
export const shiftVersion=s=>JSON.stringify([s.id,s.tapperId,s.date,s.partId,s.start,s.end,s.status,s.timeBandId]);
export function mutateShiftRequest(state,input,actor,now,activity,validShift,validateOverlap,interval) {
  if(input.action==='setup_shared_employee') {
    if(actor.role!=='owner') fail('사장님만 직원 화면을 설정할 수 있어요.',403);
    if(state.sharedEmployeeId) return true;
    const id=randomUUID();
    state.tappers.push({id,actorId:`shared-employee-${id}`,nickname:'단기 계약 크루',rank:'crew',contractType:'short_term',employmentType:'시간알바',duties:[],workProfile:{partIds:[],bands:[]},hourlyWon:0,payPeriod:'monthly',phone:'',kakaoUrl:'',active:true});
    state.sharedEmployeeId=id; activity('공용 계정의 단기 계약 직원 화면 연결'); return true;
  }
  if (!['request_shift_change', 'review_shift_change', 'cancel_shift_change'].includes(input.action)) return false;
  const own = state.tappers.find(t => t.actorId === actor.id && t.active);
  state.shiftChangeRequests ??= [];
  if (input.action === 'request_shift_change') {
    const shift = state.staffShifts.find(s => s.id === input.shiftId);
    if (!own || !shift || shift.tapperId !== own.id) fail('본인에게 배정된 근무만 신청할 수 있어요.', 403);
    if (shift.status !== 'planned' || interval(shift)[0] <= now.getTime() || hasAttendance(state, shift, interval)) fail('출퇴근 기록이 없는 시작 전 근무만 신청할 수 있어요.');
    if (state.shiftChangeRequests.some(r => r.shiftId === shift.id && r.status === 'pending')) fail('이미 신청 중인 근무예요.', 409);
    if (!['leave', 'shorten', 'partial_off'].includes(input.kind)) fail('변경 종류를 선택해 주세요.');
    if (typeof input.reason !== 'string' || !input.reason.trim() || input.reason.length > 300) fail('신청 이유를 1–300자로 입력해 주세요.');
    const { work, vacant } = requestedRanges(shift, input, interval);
    const segments = work.map(([a,b]) => ({ ...shift, ...rangeFields(a,b) }));
    const after = segments[0] ?? { ...shift, status: 'leave' };
    state.shiftChangeRequests.push({ id: randomUUID(), shiftId: shift.id, tapperId: own.id, kind: input.kind, reason: input.reason.trim(), status: 'pending', before: structuredClone(shift), after, segments, vacancies: vacant.map(([a,b]) => ({ id: randomUUID(), ...rangeFields(a,b), partId: shift.partId, ...(shift.timeBandId ? {timeBandId: shift.timeBandId} : {}) })), version: shiftVersion(shift), requestedAt: now.toISOString() });
    activity('본인 근무 변경 신청'); return true;
  }
  const row = state.shiftChangeRequests.find(r => r.id === input.id);
  if (!row) fail('처리할 신청을 다시 확인해 주세요.', 409);
  if (input.action === 'review_shift_change' && input.decision === 'assign_replacement') {
    if (actor.role !== 'owner') fail('사장님만 대체 크루를 배정할 수 있어요.', 403);
    if (row.status !== 'approved') fail('승인된 빈 구간에만 대체 배정할 수 있어요.', 409);
    const vacant = row.vacancies?.find(v => v.id === input.vacancyId);
    if (!vacant || vacant.replacementShiftId) fail('이미 배정됐거나 변경된 빈 구간이에요.', 409);
    if (input.tapperId === row.tapperId) fail('다른 크루를 선택해 주세요.');
    const candidate = { ...validShift({ ...vacant, tapperId: input.tapperId }, state), ...(vacant.timeBandId ? {timeBandId: vacant.timeBandId} : {}) };
    if (interval(candidate)[0] <= now.getTime() || hasAttendance(state, candidate, interval)) fail('시작 전이고 출퇴근 기록이 없는 크루를 선택해 주세요.', 409);
    validateOverlap(state, candidate);
    const [a,b] = interval(candidate);
    if ((state.shiftChangeRequests ?? []).some(r => r.status === 'approved' && r.tapperId === candidate.tapperId && (r.vacancies ?? []).some(v => {const [c,d] = interval(v); return a < d && c < b;})) || state.staffShifts.some(s => s.tapperId === candidate.tapperId && s.status === 'leave' && (() => {const [c,d] = interval(s); return a < d && c < b;})())) fail('승인된 OFF 시간과 겹쳐요.', 409);
    const replacement = { ...candidate, id: randomUUID(), status: 'planned', replacementForRequestId: row.id, replacementForShiftId: row.shiftId, vacancyId: vacant.id };
    state.staffShifts.push(replacement);
    vacant.replacementShiftId = replacement.id;
    vacant.replacementTapperId = replacement.tapperId;
    activity('승인된 빈 구간에 대체 크루 배정'); return true;
  }
  if (row.status !== 'pending') fail('처리할 신청을 다시 확인해 주세요.', 409);
  if (input.action === 'cancel_shift_change') {
    if (row.tapperId !== own?.id) fail('본인 신청만 취소할 수 있어요.', 403);
    row.status = 'cancelled'; row.reviewedAt = now.toISOString(); activity('근무 변경 신청 취소'); return true;
  }
  if (actor.role !== 'owner') fail('사장님만 신청을 승인할 수 있어요.', 403);
  if (!['approved', 'rejected'].includes(input.decision)) fail('승인 또는 반려를 선택해 주세요.');
  if (input.decision === 'approved') {
    const shift = state.staffShifts.find(s => s.id === row.shiftId);
    const matchesVersion = shift && (shiftVersion(shift) === row.version || (!shift.timeBandId && !row.before.timeBandId && JSON.stringify(JSON.parse(shiftVersion(shift)).slice(0, 7)) === row.version));
    if (!matchesVersion) fail('신청 이후 근무가 바뀌었어요. 반려 후 다시 신청해 주세요.', 409);
    if (interval(shift)[0] <= now.getTime() || hasAttendance(state, shift, interval)) fail('이미 시작했거나 출퇴근 기록이 있는 근무는 승인할 수 없어요.', 409);
    // Upgrade pending requests created before segment/vacancy support.
    const ranges = requestedRanges(row.before, {kind: row.kind, start: row.kind === 'partial_off' ? row.vacancies[0].start : row.after.start, end: row.kind === 'partial_off' ? row.vacancies[0].end : row.after.end}, interval);
    const segments = ranges.work.map(([a,b]) => ({ ...shift, ...rangeFields(a,b), status: 'planned', approvedRequestId: row.id }));
    for (const segment of segments) { validShift(segment, state); validateOverlap(state, segment, new Set([shift.id])); }
    row.vacancies ??= ranges.vacant.map(([a,b]) => ({id: randomUUID(), ...rangeFields(a,b), partId: shift.partId, ...(shift.timeBandId ? {timeBandId: shift.timeBandId} : {})}));
    if (segments.length) {
      Object.assign(shift, segments[0]);
      for (const segment of segments.slice(1)) state.staffShifts.push({...segment, id: randomUUID(), sourceShiftId: row.shiftId});
    } else Object.assign(shift, {status: 'leave', approvedRequestId: row.id});
    row.appliedShiftIds = state.staffShifts.filter(s => s.approvedRequestId === row.id).map(s => s.id);
  }
  Object.assign(row, {status: input.decision, reviewedAt: now.toISOString(), reviewedBy: actor.id});
  activity(input.decision === 'approved' ? '근무 변경 승인·반영' : '근무 변경 반려'); return true;
}
