import {createHash} from 'node:crypto';
import {StoreError} from './store.mjs';
const fail=(m,status=400)=>{throw new StoreError(m,status);};
export const printLocales=['en','vi','zh-Hans','ja'];
export function printContent(t){return {title:t.manualTitle??t.title,steps:(t.steps??[]).map(s=>({id:s.id,title:s.manualTitle??s.title,manual:s.manual??'',tip:s.tip??'',sourceUrl:s.sourceUrl??'',imageUrl:s.imageUrl??'',videoUrl:s.videoUrl??''}))};}
export function printSourceHash(t){return createHash('sha256').update(JSON.stringify(printContent(t))).digest('hex');}
export function manualPrintView(state){
 return (state.taskTemplates??[]).filter(t=>!t.archivedAt&&(t.folderId!=='order-work'||t.menuManualId)).map(t=>({
  id:t.id,title:t.manualTitle??t.title,sourceHash:printSourceHash(t),version:t.version??1,
  folderId:t.folderId??'general',folderName:state.checklistFolders.find(f=>f.id===t.folderId)?.name??'기본 업무',
  partId:t.settings?.assignment?.mode==='scheduled'?t.settings.assignment.partId:t.partId??null,
  zoneId:t.zone??null,menuManualId:t.menuManualId??null,
  translations:state.manualPrintTranslations?.[t.id]??{},
 }));
}
export function saveManualPrintTranslation(state,input,actor,now){
 if(!['owner','manager'].includes(actor.role))fail('매뉴얼 편집 권한이 필요해요.',403);
 const t=state.taskTemplates.find(t=>t.id===input.templateId&&!t.archivedAt);
 if(!t)fail('매뉴얼을 찾지 못했어요.',404);
 if(!printLocales.includes(input.locale))fail('지원하는 인쇄 언어를 선택해 주세요.');
 if(input.sourceHash!==printSourceHash(t))fail('원문이 변경됐어요. 최신 원문을 열어 번역을 확인해 주세요.',409);
 const clean=(v,max,required=false)=>{if(typeof v!=='string'||v.length>max||(required&&!v.trim()))fail('번역의 필수 내용과 길이를 확인해 주세요.');return v.trim();};
 const title=clean(input.title,100,true);
 if(!Array.isArray(input.steps)||input.steps.length!==t.steps.length||new Set(input.steps.map(s=>s?.id)).size!==t.steps.length)fail('모든 Task의 번역을 확인해 주세요.');
 const steps=t.steps.map(source=>{
  const row=input.steps.find(s=>s?.id===source.id);if(!row)fail('Task 원문과 번역이 일치하지 않아요.');
  return {id:source.id,title:clean(row.title,100,true),manual:clean(row.manual,3000,Boolean(source.manual?.trim())),tip:clean(row.tip,1200,Boolean(source.tip?.trim()))};
 });
 (state.manualPrintTranslations??={})[t.id]??={};
 state.manualPrintTranslations[t.id][input.locale]={sourceHash:input.sourceHash,title,steps,reviewedAt:new Date(now).toISOString()};
}
