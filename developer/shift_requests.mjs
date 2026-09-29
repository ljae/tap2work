import { randomUUID } from 'node:crypto';
import { StoreError } from './store.mjs';
const fail=(m,s=400)=>{throw new StoreError(m,s);};
export const shiftVersion=s=>JSON.stringify([s.id,s.tapperId,s.date,s.partId,s.start,s.end,s.status]);
export function mutateShiftRequest(state,input,actor,now,activity,validShift,validateOverlap,interval) {
  if(input.action==='setup_shared_employee') {
    if(actor.role!=='owner') fail('사장님만 직원 화면을 설정할 수 있어요.',403);
    if(state.sharedEmployeeId) return true;
    const id=randomUUID();
    state.tappers.push({id,actorId:`shared-employee-${id}`,nickname:'단기 계약 크루',rank:'crew',contractType:'short_term',employmentType:'시간알바',duties:[],workProfile:{partIds:[],bands:[]},hourlyWon:0,payPeriod:'monthly',phone:'',kakaoUrl:'',active:true});
    state.sharedEmployeeId=id; activity('공용 계정의 단기 계약 직원 화면 연결'); return true;
  }
  if(!['request_shift_change','review_shift_change','cancel_shift_change'].includes(input.action)) return false;
  const own=state.tappers.find(t=>t.actorId===actor.id && t.active);
  state.shiftChangeRequests ??= [];
  if(input.action==='request_shift_change') {
    const shift=state.staffShifts.find(s=>s.id===input.shiftId);
    if(!own || !shift || shift.tapperId!==own.id) fail('본인에게 배정된 근무만 신청할 수 있어요.',403);
    if(shift.status!=='planned' || interval(shift)[0]<=now.getTime()) fail('시작 전 근무만 신청할 수 있어요.');
    if(state.shiftChangeRequests.some(r=>r.shiftId===shift.id && r.status==='pending')) fail('이미 신청 중인 근무예요.',409);
    if(!['leave','shorten'].includes(input.kind)) fail('변경 종류를 선택해 주세요.');
    if(typeof input.reason!=='string' || !input.reason.trim() || input.reason.length>300) fail('신청 이유를 1–300자로 입력해 주세요.');
    const after=input.kind==='leave'?{...shift,status:'leave'}:{...shift,...validShift({...shift,start:input.start,end:input.end},state)};
    if(input.kind==='shorten') {
      const [a,b]=interval(shift),[c,d]=interval(after);
      if(c<a || d>b || c===a && d===b) fail('기존 근무 안에서 시간을 줄여 주세요.');
    }
    state.shiftChangeRequests.push({id:randomUUID(),shiftId:shift.id,tapperId:own.id,kind:input.kind,reason:input.reason.trim(),status:'pending',before:structuredClone(shift),after,version:shiftVersion(shift),requestedAt:now.toISOString()});
    activity('본인 근무 변경 신청'); return true;
  }
  const row=state.shiftChangeRequests.find(r=>r.id===input.id);
  if(!row || row.status!=='pending') fail('처리할 신청을 다시 확인해 주세요.',409);
  if(input.action==='cancel_shift_change') {
    if(row.tapperId!==own?.id) fail('본인 신청만 취소할 수 있어요.',403);
    row.status='cancelled';row.reviewedAt=now.toISOString();activity('근무 변경 신청 취소');return true;
  }
  if(actor.role!=='owner') fail('사장님만 신청을 승인할 수 있어요.',403);
  if(!['approved','rejected'].includes(input.decision)) fail('승인 또는 반려를 선택해 주세요.');
  if(input.decision==='approved') {
    const shift=state.staffShifts.find(s=>s.id===row.shiftId);
    if(!shift || shiftVersion(shift)!==row.version) fail('신청 이후 근무가 바뀌었어요. 반려 후 다시 신청해 주세요.',409);
    if(interval(shift)[0]<=now.getTime()) fail('이미 시작한 근무는 승인할 수 없어요.',409);
    if(row.kind==='shorten') {validShift(row.after,state);validateOverlap(state,row.after,new Set([shift.id]));}
    Object.assign(shift,row.after,{approvedRequestId:row.id});
  }
  Object.assign(row,{status:input.decision,reviewedAt:now.toISOString(),reviewedBy:actor.id});
  activity(input.decision==='approved'?'근무 변경 승인·반영':'근무 변경 반려');return true;
}
