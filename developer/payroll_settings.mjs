import { StoreError } from './store.mjs';
const dayMs = 86400000;
export function payrollSettings(state) {
  return state.payrollSettings ?? {cycle:'monthly', monthStartDay:1, weekStartDay:1, roundingMinutes:0, businessSize:'unknown', includeWeeklyRest:true, configured:false};
}
export function savePayrollSettings(state, input, actor, now) {
  if (actor.role !== 'owner') throw new StoreError('사장님만 정산 설정을 바꿀 수 있어요.',403);
  const p=input.settings;
  if (!p || !['monthly','weekly'].includes(p.cycle) || !Number.isInteger(p.monthStartDay) || p.monthStartDay<1 || p.monthStartDay>31 || !Number.isInteger(p.weekStartDay) || p.weekStartDay<1 || p.weekStartDay>7 || ![0,1,5,10,30].includes(p.roundingMinutes) || !['under5','fivePlus'].includes(p.businessSize) || typeof p.includeWeeklyRest !== 'boolean') throw new StoreError('정산 주기·시작일·반올림·사업장 규모를 확인해 주세요.',400);
  state.payrollSettingsHistory ??= [];
  state.payrollSettingsHistory.push({at:now.toISOString(), by:actor.id, previous:structuredClone(payrollSettings(state))});
  state.payrollSettings={cycle:p.cycle,monthStartDay:p.monthStartDay,weekStartDay:p.weekStartDay,roundingMinutes:p.roundingMinutes,businessSize:p.businessSize,includeWeeklyRest:p.includeWeeklyRest,configured:true};
}
export function settlementPeriod(day, policy) {
  const d=new Date(`${day}T00:00:00Z`);
  let start,end;
  if(policy.cycle==='weekly') {
    const offset=((d.getUTCDay()||7)-policy.weekStartDay+7)%7;
    start=new Date(d.getTime()-offset*dayMs);end=new Date(start.getTime()+7*dayMs);
  } else {
    const boundary=(y,m)=>new Date(Date.UTC(y,m,Math.min(policy.monthStartDay,new Date(Date.UTC(y,m+1,0)).getUTCDate())));
    start=boundary(d.getUTCFullYear(),d.getUTCMonth());
    if(start>d) start=boundary(d.getUTCFullYear(),d.getUTCMonth()-1);
    end=boundary(start.getUTCFullYear(),start.getUTCMonth()+1);
  }
  return {start:start.toISOString().slice(0,10),end:new Date(end-dayMs).toISOString().slice(0,10),until:end.toISOString().slice(0,10)};
}
// Union actual intervals, split by Korean date, then round daily net minutes.
// Never alter attendance evidence, breaks, premium thresholds or eligibility.
export function roundedWorkMinutes(segments, from, until, unit=0) {
  const rows=segments.map(s=>[Math.max(from,Date.parse(s.start)),Math.min(until,Date.parse(s.end))]).filter(([a,b])=>b>a).sort((a,b)=>a[0]-b[0]);
  const merged=[];
  for(const row of rows) {const last=merged.at(-1);if(last&&row[0]<=last[1])last[1]=Math.max(last[1],row[1]);else merged.push([...row]);}
  const daily=new Map();
  for(const [begin,end] of merged) for(let at=begin;at<end;) {
    const day=new Date(at+9*3600000).toISOString().slice(0,10);
    const next=Math.min(end,Date.parse(`${day}T00:00:00+09:00`)+dayMs);
    daily.set(day,(daily.get(day)??0)+(next-at)/60000);at=next;
  }
  return [...daily.values()].reduce((n,m)=>n+(unit ? Math.round(m/unit)*unit : m),0);
}
export function applyPayrollEstimate(result, segments, policy, week, rate) {
  if(!policy.configured)return result;
  const from=Date.parse(`${week}T00:00:00+09:00`);
  const settledMinutes=roundedWorkMinutes(segments,from,from+7*dayMs,policy.roundingMinutes);
  const baseWon=Math.round(settledMinutes*rate/60);
  const weeklyRestAccruedWon=result.weeklyRestWon;
  const weeklyRestWon=policy.includeWeeklyRest ? weeklyRestAccruedWon : 0;
  const totalWon=result.status==='estimate' || (!policy.includeWeeklyRest && result.extensionWon!==null && result.nightWon!==null && result.holidayWon!==null && result.paidHolidayWon!==null && !result.alerts.some(a=>a.includes('합계를 보류'))) ? baseWon+result.extensionWon+result.nightWon+result.holidayWon+weeklyRestWon+result.paidHolidayWon : null;
  return {...result,baseWon,settledMinutes,weeklyRestAccruedWon,weeklyRestWon,weeklyRestIncluded:policy.includeWeeklyRest,weeklyRestWeeks:weeklyRestAccruedWon===null?null:weeklyRestAccruedWon>0?1:0,totalWon,status:totalWon===null?'needs_review':'estimate'};
}
