import { composeManual } from './manual_setup.mjs';
import { StoreError } from './store.mjs';
import { assignmentOccurrences } from './work_assignments.mjs';
import { businessDate } from './business_day.mjs';

export const eventKinds = ['batch', 'opened', 'thawed', 'received'];
const fail = message => { throw new StoreError(message, 400); };
export function knowledgeFields(value) {
  if (value == null) return undefined;
  if (!value || !['universal','food','process','menu','store'].includes(value.scope)) fail('매뉴얼 적용 범위를 확인해 주세요.');
  const array = (v, max=20) => {
    if (!Array.isArray(v) || v.length>max || v.some(x=>typeof x!=='string'||!x.trim()||x.length>100)) fail('매뉴얼 연결을 확인해 주세요.');
    return [...new Set(v)];
  };
  if (value.useCase != null && !['training','routine','periodic','startup'].includes(value.useCase)) fail('매뉴얼 용도를 확인해 주세요.');
  const use=value.suggestedUse??'reference';
  if (!['reference','routine','event'].includes(use)) fail('권장 사용 방법을 확인해 주세요.');
  if (value.eventKind != null && !eventKinds.includes(value.eventKind)) fail('작업 종류를 확인해 주세요.');
  return {...(value.useCase?{useCase:value.useCase}:{}),scope:value.scope,topics:array(value.topics??[]),menuNames:array(value.menuNames??[]),ingredientNames:array(value.ingredientNames??[]),requiresBreak:value.requiresBreak===true,suggestedUse:use,eventKind:value.eventKind??null,safetyReviewRequired:value.safetyReviewRequired===true,supersededBy:array(value.supersededBy??[])};
}
export function usageFields(value) {
  if (value.usage == null) return {};
  if (!['reference','routine','event'].includes(value.usage)) fail('매뉴얼 사용 방법을 선택해 주세요.');
  if (value.usage==='event' && !eventKinds.includes(value.eventKind)) fail('작업 종류를 선택해 주세요.');
  if (value.operatingStandard != null && (typeof value.operatingStandard!=='string'||value.operatingStandard.length>1000)) fail('매장 기준은 1,000자 이내로 적어 주세요.');
  if (value.knowledgeIds != null && (!Array.isArray(value.knowledgeIds)||value.knowledgeIds.length>10||value.knowledgeIds.some(x=>typeof x!=='string'||x.length>100))) fail('연결할 매뉴얼을 확인해 주세요.');
  return {usage:value.usage,eventKind:value.usage==='event'?value.eventKind:null,operatingStandard:value.operatingStandard?.trim()??'',knowledgeIds:[...new Set(value.knowledgeIds??[])]};
}
export function breakOn(state,date) {
  const d=new Date(`${date}T12:00:00+09:00`).getUTCDay()||7;
  return state.workplace?.breaks?.[d]??null;
}
export function workEligibility(state,t,date) {
  const s=t.settings??{};
  if (t.archivedAt) return ['archived','보관된 매뉴얼이에요'];
  if (s.usage==='reference') return ['reference','필요할 때 보는 매뉴얼이에요'];
  if (s.enabled===false) return ['unclassified','업무 연결 방법을 선택해 주세요'];
  if (!t.steps?.length) return ['incomplete','확인할 행동을 추가해 주세요'];
  if (t.knowledge?.safetyReviewRequired && !s.operatingStandard?.trim()) return ['incomplete','제품·공정에 맞는 매장 기준을 입력해 주세요'];
  if ((s.knowledgeIds??[]).some(id=>!state.taskTemplates.some(k=>k.id===id&&!k.archivedAt))) return ['incomplete','연결된 참고 매뉴얼을 다시 확인해 주세요'];
  if (s.usage==='event') return ['event','작업을 시작할 때 체크리스트가 만들어져요'];
  if (t.menuManualId) return ['reference','메뉴 조리 시 참고하는 매뉴얼이에요'];
  if (t.generationNotBeforeBusinessDate>date) return ['waiting','적용 시작일을 기다리고 있어요'];
  if ((t.knowledge?.requiresBreak || t.slot==='브레이크')&&!breakOn(state,date)) return ['waiting','오늘은 브레이크 타임이 없어요'];
  const weekday=new Date(`${date}T12:00:00+09:00`).getUTCDay()||7;
  if (s.recurrence?.mode==='weekly'&&!s.recurrence.weekdays.includes(weekday)) return ['waiting','선택한 반복 요일에 생성돼요'];
  if (!assignmentOccurrences(state,t,date).length) return ['incomplete','오늘 적용할 파트·시간대를 확인해 주세요'];
  return ['ready','오늘 업무에 연결돼요'];
}
export function workStatus(state,t,date,catalog) {
  let [code,label]=workEligibility(state,t,date);
  if(t.knowledge?.supersededBy?.length || t.id==='library-bonejjim-break' || state.catalogLinks?.[t.id]?.sourceId==='bonejjim/break'){code='replacement';label='공통 업무로 정리된 새 구성을 확인해 주세요';}
  const tasks=state.tasks.filter(x=>x.templateId===t.id&&!x.archivedAt&&!x.supersededAt&&(x.date===date||x.workEvent&&!x.completedAt));
  if (code==='ready') {code=tasks.length?'scheduled':'missing';label=tasks.length?`오늘 업무 ${tasks.length}개에 연결됐어요`:'생성할 업무를 찾지 못했어요. 새로고침해 주세요';}
  const replacementIds=t.knowledge?.supersededBy??['common/break-service','food/service-reset','bonejjim/evening-prep'];
  return {code,label,replacementsAvailable:code==='replacement'&&replacementIds.every(id=>catalog?.entries.some(e=>e.sourceId===id)),executionIds:tasks.map(x=>x.id),breakTime:breakOn(state,date)};
}
export function eventReplay(state,input,actor) {
  if (input.action!=='start_manual_work') return false;
  const existing=state.tasks.find(t=>t.workEvent && t.workEvent.requestId===input.requestId);
  if (!existing) return false;
  if (existing.workEvent.actorId!==actor.id||existing.templateId!==input.templateId||existing.workEvent.subject!==input.subject?.trim()) throw new StoreError('같은 작업 요청의 내용이 달라요.',409);
  return true;
}
export function startManualWork(state,input,actor,now) {
  if (!/^[a-zA-Z0-9-]{8,100}$/.test(input.requestId??'')) fail('작업 요청 ID를 확인해 주세요.');
  const original=state.taskTemplates.find(t=>t.id===input.templateId&&!t.archivedAt);
  const t=original?composeManual(state,original):null;
  if (!t) fail('매뉴얼을 찾지 못했어요.');
  const [code,label]=workEligibility(state,t,businessDate(state,now));
  if (code!=='event') fail(label);
  if (typeof input.subject!=='string'||!input.subject.trim()||input.subject.trim().length>80) fail('제품·배치 또는 로트 이름을 80자 이내로 적어 주세요.');
  const assignment=t.settings?.assignment;
  if (assignment?.mode==='scheduled') fail('작업할 때 확인하는 업무는 담당 크루 또는 직접 맡기를 선택해 주세요.');
  const linked=(t.settings.knowledgeIds??[]).map(id=>state.taskTemplates.find(k=>k.id===id&&!k.archivedAt));
  if (linked.some(x=>!x)) fail('연결된 매뉴얼을 다시 확인해 주세요.');
  state.tasks.push({...structuredClone(t),id:`event-${input.requestId}`,templateId:t.id,kind:'routine',date:businessDate(state,now),dueAt:now.toISOString(),boardStatus:'todo',completedAt:null,completedBy:null,
    title:`${t.title} · ${input.subject.trim()}`,knowledgeSnapshots:linked.map(k=>({id:k.id,version:k.version,title:k.title,steps:structuredClone(k.steps)})),
    workEvent:{requestId:input.requestId,kind:t.settings.eventKind,subject:input.subject.trim(),actorId:actor.id,occurredAt:now.toISOString()},
    settings:{...structuredClone(t.settings),allowBulkComplete:false},
    steps:t.steps.map(s=>({...structuredClone(s),manual:`${s.manual}${t.settings.operatingStandard?'\n매장 기준: '+t.settings.operatingStandard:''}`,completedAt:null,completedBy:null}))});
}

export function knowledgeSnapshots(state,t) {
  return (t.settings?.knowledgeIds??[]).map(id=>state.taskTemplates.find(k=>k.id===id&&!k.archivedAt)).filter(Boolean).map(k=>({id:k.id,version:k.version,title:k.title,steps:structuredClone(k.steps)}));
}
