import {contentHash,stepContent} from './manual_catalog_schema.mjs';
import starter from './owner_starter_content.json' with {type:'json'};
import { StoreError } from './store.mjs';
import {workplaceBandDays} from './parts.mjs';
import { randomUUID } from 'node:crypto';
import { validateChecklists } from './checklists.mjs';
import { taskSettings, saveTapSettings } from './task_settings.mjs';
import { effectiveTemplate } from './work_recurrence.mjs';
import { workEligibility } from './knowledge_work.mjs';
import { assignmentOccurrences, assignmentView, effectiveWorkplaceBands } from './work_assignments.mjs';
import { shiftDate } from './business_day.mjs';
const fail=(s,status=400)=>{throw new StoreError(s,status);};
export const registeredManual=t=>t.registration?.status!=='pending';
export function ownerWorkflowView(state,actor,catalog) {
  if(actor.role!=='owner')return null;
  const date=shiftDate(state.day,1), plans=[];
  for(const source of state.taskTemplates.filter(t=>!t.archivedAt&&registeredManual(t))) {
    const t=effectiveTemplate(source,date);
    if(workEligibility(state,t,date)[0]!=='ready')continue;
    for(const occurrence of assignmentOccurrences(state,t,date)) {
      const view=assignmentView(state,{...t,...occurrence,date},null,actor);
      plans.push({templateId:t.id,title:t.title,emoji:t.emoji,slot:t.slot,stepCount:t.steps.length,timeBandName:occurrence.timeBandName??null,assignment:view,recurrence:t.settings?.recurrence??{mode:'daily',weekdays:[]},scheduled:!!source.scheduledSettings});
    }
  }
  return {version:starter.version,assumption:starter.assumption,date,closed:!effectiveWorkplaceBands(state,date).length,plans,
    candidates:starter.entries.filter(e=>!state.taskTemplates.some(t=>t.starterId===e.id&&!t.archivedAt)).map(e=>({...e,replacesExisting:!!e.sourceId&&state.taskTemplates.some(t=>!t.archivedAt&&state.catalogLinks?.[t.id]?.sourceId===e.sourceId)})),
    pending:state.taskTemplates.filter(t=>!t.archivedAt&&(!registeredManual(t)||state.catalogLinks?.[t.id]?.availableReleaseId)).map(t=>{
      const link=state.catalogLinks?.[t.id],source=link?.availableReleaseId?catalog?.entries.find(e=>e.sourceId===link.sourceId):null;
      return source?{...t,title:source.title,steps:source.steps,catalogUpdate:true}:t;
    })};
}
export function mutateOwnerWorkflow(state,input,actor,now,catalog) {
  if(!['register_owner_selection','register_owner_manuals','register_starter_manuals','schedule_tap_settings'].includes(input.action))return false;
  if(actor.role!=='owner')fail('사장님이 내용을 확인한 뒤 등록해 주세요.',403);
  if(input.action==='register_owner_selection') {
    if(!Array.isArray(input.starterIds)||!Array.isArray(input.pendingIds)||!input.starterIds.length&&!input.pendingIds.length)fail('검토한 매뉴얼을 선택해 주세요.');
    if(input.starterIds.length)mutateOwnerWorkflow(state,{...input,action:'register_starter_manuals',ids:input.starterIds},actor,now,catalog);
    if(input.pendingIds.length)mutateOwnerWorkflow(state,{...input,action:'register_owner_manuals',ids:input.pendingIds},actor,now,catalog);
    return true;
  }
  if(input.action==='schedule_tap_settings') {
    const date=shiftDate(state.day,1);
    if(input.effectiveFrom!==date)fail('내일 날짜가 바뀌었어요. 미리보기를 다시 열어 주세요.',409);
    const original=state.taskTemplates.find(t=>t.id===input.templateId&&!t.archivedAt);
    if(!original||!registeredManual(original))fail('등록된 매뉴얼을 선택해 주세요.');
    const draft=structuredClone(state), t=draft.taskTemplates.find(t=>t.id===original.id);
    Object.assign(t,effectiveTemplate(t,date));
    saveTapSettings(draft,{...input,action:'save_tap_settings'},now);
    original.scheduledSettings={effectiveFrom:date,settings:structuredClone(t.settings),zone:t.zone,version:(original.version??1)+1,at:now.toISOString(),actorId:actor.id};
    return true;
  }
  if(input.reviewed!==true)fail('매뉴얼의 내용을 검토하고 확인해 주세요.');
  if(!Array.isArray(input.ids)||!input.ids.length||input.ids.length>100||new Set(input.ids).size!==input.ids.length)fail('검토한 매뉴얼을 선택해 주세요.');
  const registration={status:'registered',at:now.toISOString(),actorId:actor.id};
  if(input.action==='register_owner_manuals') {
    const rows=input.ids.map(id=>state.taskTemplates.find(t=>t.id===id&&!t.archivedAt)??fail('매뉴얼을 다시 확인해 주세요.',409));
    for(const t of rows){
      const link=state.catalogLinks?.[t.id];
      if(link?.availableReleaseId){
        const source=catalog?.entries.find(e=>e.sourceId===link.sourceId);if(!source)fail('최신 공용 매뉴얼을 다시 확인해 주세요.',409);
        (state.catalogHistory??=[]).push({kind:'owner-update',at:now.toISOString(),template:structuredClone(t),sourceId:link.sourceId});
        t.title=source.title;t.emoji=source.emoji;t.steps=source.steps.map(stepContent);t.knowledge=structuredClone(source.knowledge);t.version=(t.version??1)+1;
        link.releaseId=catalog.releaseId;link.contentHash=contentHash(t);delete link.availableReleaseId;
      }
      t.registration={...registration,contentHash:contentHash(t)};
    }
    return true;
  }
  if(input.starterVersion!==starter.version)fail('기본 매뉴얼이 바뀌었어요. 다시 검토해 주세요.',409);
  const entries=input.ids.map(id=>starter.entries.find(e=>e.id===id)??fail('기본 매뉴얼을 찾지 못했어요.'));
  const additions=entries.filter(e=>!state.taskTemplates.some(t=>t.starterId===e.id&&!t.archivedAt));
  for(const e of additions) {
    const folderId=e.usage==='reference'?'owner-service':'owner-routine';
    if(!state.checklistFolders.some(f=>f.id===folderId))state.checklistFolders.push({id:folderId,name:e.usage==='reference'?'응대·작업 방법':'기본 운영 루틴'});
    const existing=e.sourceId?state.taskTemplates.find(t=>!t.archivedAt&&state.catalogLinks?.[t.id]?.sourceId===e.sourceId):null;
    const t={id:existing?.id??`owner-${randomUUID()}`,starterId:e.id,title:e.title,emoji:e.emoji,folderId,slot:e.slot,requiredRole:'all',partId:null,zone:null,steps:structuredClone(e.steps),sourceIds:[],assignmentScopeVersion:2,version:(existing?.version??0)+1};
    if(existing)t.steps=t.steps.map((step,i)=>({...step,id:existing.steps[i]?.id??step.id}));
    const checked=validateChecklists({folders:state.checklistFolders,templates:[...state.taskTemplates.filter(row=>row!==existing),t]},state).templates.at(-1);
    Object.assign(t,checked,{starterId:e.id,registration:structuredClone(registration),knowledge:{scope:'store',topics:[],menuNames:[],ingredientNames:[],suggestedUse:e.usage,useCase:e.recurrence.mode==='daily'?(e.usage==='routine'?'routine':'training'):'periodic'},generationNotBeforeBusinessDate:existing?shiftDate(state.day,1):state.day});
    const bands=[...new Map(Object.values(workplaceBandDays(state,{includeHours:true})).flat().filter(b=>(b.headcounts?.[e.partId]??0)>0).map(b=>[b.id,b])).values()];
    // Keep existing crews and hours. Roster-based ownership is resolved at execution time.
    const part=state.workplace?.parts?.find(p=>p.id===e.partId&&!p.hidden);
    const chosen=e.slot==='오픈'?bands.slice(0,1):e.slot==='마감'?bands.slice(-1):bands;
    const assignment=part&&chosen.length?{mode:'scheduled',partId:e.partId,timeBandIds:chosen.map(b=>b.id),crewIds:[]}:{mode:'anyone'};
    t.settings={type:e.slot==='오픈'?'opening':e.slot==='마감'?'closing':'general',usage:e.usage,enabled:e.usage==='routine',recurrence:structuredClone(e.recurrence),assignment,allowBulkComplete:false,enforceSequence:false,completionPolicy:{kind:'check',quantitySpec:null},estimatedMinutes:null};
    if(existing){Object.assign(existing,t);const link=state.catalogLinks[existing.id];link.mode='personalized';link.detachedAt=now.toISOString();} else state.taskTemplates.push(t);
  }
  return true;
}
