import release from '../docs/market/current.json' with {type:'json'};
import {randomUUID,createHash} from 'node:crypto';
import {StoreError} from './store.mjs';
import {validateChecklists} from './checklists.mjs';
import {assertContentOnly} from './tap_policy.mjs';
import {taskSettings,saveTapSettings} from './task_settings.mjs';
import {contentHash,templateContent,stepContent} from './manual_catalog_schema.mjs';
const fail=(s,status=400)=>{throw new StoreError(s,status);};
export const manualCatalog=release;
const uid=()=>`market-${randomUUID()}`;
const blankSettings=()=>({type:'general',enabled:false,recurrence:{mode:'daily',weekdays:[]},allowBulkComplete:true,enforceSequence:false,completionPolicy:{kind:'check',quantitySpec:null},estimatedMinutes:null});
function receipt(state,input,actor,fn){
 if(typeof input.operationId!=='string'||!/^[a-zA-Z0-9-]{8,100}$/.test(input.operationId))fail('요청 ID를 확인해 주세요.');
 const {revision,operationId,...body}=input;
 const hash=createHash('sha256').update(JSON.stringify(body)).digest('hex');
 const previous=state.catalogOperations?.[operationId];
 if(previous){if(previous.actorId!==actor.id||previous.hash!==hash)fail('같은 요청 ID의 내용이 달라요.',409);return previous.ids;}
 const ids=fn();
 (state.catalogOperations??={})[operationId]={hash,ids,actorId:actor.id};
 return ids;
}
export function reconcileCatalogLinks(state,now){
 let changed=false;
 for(const [id,link] of Object.entries(state.catalogLinks??{})){
  const template=state.taskTemplates.find(t=>t.id===id);
  if(link.mode==='linked' && (!template || contentHash(template)!==link.contentHash)){
   link.mode=template?'personalized':'removed';link.detachedAt=new Date(now).toISOString();changed=true;
  }
 }
 return changed;
}
export function syncManualCatalog(state,now,catalog=release){
 let changed=reconcileCatalogLinks(state,now);
 for(const [id,link] of Object.entries(state.catalogLinks??{})){
  if(link.mode!=='linked')continue;
  const source=catalog.entries.find(t=>t.sourceId===link.sourceId);
  const template=state.taskTemplates.find(t=>t.id===id&&!t.archivedAt);
  if(!source||!template||contentHash(source)===link.contentHash)continue;
  const previous=structuredClone(template);
  template.title=source.title;template.emoji=source.emoji;
  template.steps=source.steps.map(step=>{
   const old=previous.steps.find(s=>s.id===step.id);
   return {...structuredClone(stepContent(step)),contentRevision:(old?.contentRevision??0)+(JSON.stringify(stepContent(old??{}))===JSON.stringify(stepContent(step))?0:1)};
  });
  template.version=(template.version??1)+1;
  link.releaseId=catalog.releaseId;link.contentHash=contentHash(template);link.updatedAt=new Date(now).toISOString();
  (state.catalogHistory??=[]).push({kind:'update',at:link.updatedAt,template:previous,sourceId:link.sourceId});
  changed=true;
 }
 return changed;
}
export function catalogView(state){return {...release,entries:release.entries.map(source=>({...source,installed:Object.entries(state.catalogLinks??{}).filter(([id,l])=>l.sourceId===source.sourceId&&l.mode!=='removed'&&state.taskTemplates.some(t=>t.id===id&&!t.archivedAt)).map(([templateId,l])=>({templateId,mode:l.mode,releaseId:l.releaseId}))}))};}
function addTemplates(state,drafts){
 const checked=validateChecklists({folders:state.checklistFolders,templates:[...state.taskTemplates,...drafts]},state);
 const ids=new Set(drafts.map(t=>t.id));
 state.taskTemplates.push(...checked.templates.filter(t=>ids.has(t.id)).map(t=>({...t,version:1,settings:blankSettings()})));
}
export function checklistBackup(state){
 const templates=state.taskTemplates.filter(t=>!t.archivedAt && state.catalogLinks?.[t.id]?.mode!=='linked').map(t=>({
  ...templateContent(t),folderId:t.folderId,slot:t.slot,
  settings:{...taskSettings(t),enabled:false,assignment:undefined},
 }));
 const ids=new Set(templates.map(t=>t.folderId));
 return {format:'tap2work-checklists',schemaVersion:1,sourceRevision:state.revision,externalMedia:'links_only',folders:state.checklistFolders.filter(f=>ids.has(f.id)).map(f=>({id:f.id,name:f.name})),templates};
}
export function mutateManualMarket(state,input,actor,now){
 if(!['import_market_taps','personalize_market_tap','restore_checklist_backup','save_manual_tap'].includes(input.action))return false;
 if(!['owner','manager'].includes(actor.role))fail('매니저 이상만 매뉴얼을 바꿀 수 있어요.',403);
 if(input.action==='save_manual_tap'){
  if(input.templateId==null){
   receipt(state,input,actor,()=>{
    const draft={id:uid(),title:input.title,emoji:input.emoji,folderId:input.folderId,slot:'준비',requiredRole:'all',partId:null,zone:null,steps:input.steps,sourceIds:[]};
    addTemplates(state,[draft]);return [draft.id];
   });return true;
  }
  const template=state.taskTemplates.find(t=>t.id===input.templateId&&!t.archivedAt);
  if(!template)fail('TAP을 찾지 못했어요.',404);
  const draft={...template,...(input.manualTitle!=null?{manualTitle:input.manualTitle}:{}),title:input.title,emoji:input.emoji,folderId:input.folderId,steps:input.steps};
  const checked=validateChecklists({folders:state.checklistFolders,templates:state.taskTemplates.map(t=>t===template?draft:t)},state).templates.find(t=>t.id===template.id);
  Object.assign(template,checked,{version:(template.version??1)+1});
  reconcileCatalogLinks(state,now);
  return true;
 }
 receipt(state,input,actor,()=>{
  if(input.action==='import_market_taps'){
   if(input.releaseId!==release.releaseId)fail('공용 목록이 업데이트됐어요. 다시 확인해 주세요.',409);
   if(!Array.isArray(input.sourceIds)||!input.sourceIds.length||new Set(input.sourceIds).size!==input.sourceIds.length)fail('가져올 TAP을 골라 주세요.');
   if(input.folderMode!=null && !['purpose','existing'].includes(input.folderMode))fail('그룹 분류 방식을 확인해 주세요.');
   if(input.folderMode!=='purpose'&&!state.checklistFolders.some(f=>f.id===input.folderId))fail('대상 그룹을 선택해 주세요.');
   const sources=input.sourceIds.map(id=>release.entries.find(t=>t.sourceId===id)??fail('공용 TAP을 찾지 못했어요.'));
   if(sources.some(s=>Object.entries(state.catalogLinks??{}).some(([id,l])=>l.sourceId===s.sourceId&&l.mode==='linked'&&state.taskTemplates.some(t=>t.id===id&&!t.archivedAt))))fail('이미 공용 연결로 가져온 TAP이 있어요.');
   const folders=structuredClone(state.checklistFolders);
   const destinations=new Map();
   for(const source of sources){
    if(input.folderMode!=='purpose'){destinations.set(source.sourceId,input.folderId);continue;}
    const purpose=release.taxonomy.purposes.find(p=>p.id===source.purposeId);
    let folder=folders.find(f=>f.name===purpose.name);
    if(!folder){folder={id:uid(),name:purpose.name};folders.push(folder);}
    destinations.set(source.sourceId,folder.id);
   }
   if(folders.length>30)fail('그룹이 많아요. 기존 그룹을 선택해 가져와 주세요.');
   state.checklistFolders=folders;
   const drafts=sources.map(s=>({id:uid(),title:s.title,emoji:s.emoji,folderId:destinations.get(s.sourceId),slot:s.slot,requiredRole:'all',partId:null,zone:null,steps:structuredClone(s.steps),sourceIds:[]}));
   addTemplates(state,drafts);
   drafts.forEach((t,i)=>{const actual=state.taskTemplates.find(v=>v.id===t.id);(state.catalogLinks??={})[t.id]={mode:'linked',sourceId:sources[i].sourceId,releaseId:release.releaseId,contentHash:contentHash(actual),importedAt:new Date(now).toISOString()};});
   return drafts.map(t=>t.id);
  }
  if(input.action==='personalize_market_tap'){
   const source=state.taskTemplates.find(t=>t.id===input.templateId&&!t.archivedAt);if(!source)fail('TAP을 찾지 못했어요.',404);
   const draft={...structuredClone(source),id:uid(),title:`${source.title.slice(0,90)} · 개인화`,menuManualId:undefined};
   addTemplates(state,[draft]);
   (state.catalogLinks??={})[draft.id]={mode:'personalized',sourceId:state.catalogLinks?.[source.id]?.sourceId??null,createdAt:new Date(now).toISOString()};
   return [draft.id];
  }
  const file=input.backup;
  if(file?.format!=='tap2work-checklists'||file.schemaVersion!==1||!Array.isArray(file.templates)||!file.templates.length||file.templates.length>650||!Array.isArray(file.folders)||file.folders.length>30)fail('지원하는 체크리스트 백업 파일인지 확인해 주세요.');
  if(new TextEncoder().encode(JSON.stringify(file)).length>2_000_000)fail('백업 파일은 2MB 이내로 가져와 주세요.');
  const folders=structuredClone(state.checklistFolders),mapping=new Map();
  for(const f of file.folders){if(typeof f.id!=='string'||mapping.has(f.id))fail('백업 그룹 ID를 확인해 주세요.');const existing=folders.find(v=>v.name===f.name);const id=existing?.id??uid();mapping.set(f.id,id);if(!existing)folders.push({id,name:f.name});}
  const drafts=file.templates.map(t=>{
   if(!Array.isArray(t.steps))fail('Task 목록을 확인해 주세요.');
   t.steps.forEach(assertContentOnly);
   if(!mapping.has(t.folderId))fail('백업 그룹 연결을 확인해 주세요.');
   return {id:uid(),title:t.manualTitle??t.title,emoji:t.emoji,folderId:mapping.get(t.folderId),slot:t.slot,requiredRole:'all',partId:null,zone:null,steps:t.steps.map(stepContent),sourceIds:[]};
  });
  const checked=validateChecklists({folders,templates:[...state.taskTemplates,...drafts]},state);
  state.checklistFolders=checked.folders;
  addTemplates(state,drafts);
  drafts.forEach((t,i)=>{
   const settings={...blankSettings(),...file.templates[i].settings,assignment:undefined,enabled:false};
   delete settings.assignment;
   saveTapSettings(state,{templateId:t.id,assignmentScopeVersion:2,settings},now);
   (state.catalogLinks??={})[t.id]={mode:'personalized',restoredAt:new Date(now).toISOString()};
  });
  return drafts.map(t=>t.id);
 });
 return true;
}

// Only successful creation receipts may bypass a stale revision; authorization is
// checked by the caller first. A changed payload or actor must never replay it.
export function manualMarketReplay(state,input,actor){
 if(!['import_market_taps','personalize_market_tap','restore_checklist_backup','save_manual_tap'].includes(input.action))return false;
 const previous=state.catalogOperations?.[input.operationId];if(!previous)return false;
 const {revision,operationId,...body}=input;
 const hash=createHash('sha256').update(JSON.stringify(body)).digest('hex');
 if(previous.actorId!==actor.id||previous.hash!==hash)fail('같은 요청 ID의 내용이 달라요.',409);
 return true;
}
