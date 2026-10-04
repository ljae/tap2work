import {createHash} from 'node:crypto';
import {mediaLink,manualTags} from './checklists.mjs';
const fail=message=>{throw Error(message);};
const text=(v,max,label)=>typeof v==='string'&&v.trim()&&v.length<=max?v.trim():fail(`Invalid ${label}`);
const optional=(v,max)=>v==null?'':typeof v==='string'&&v.length<=max?v.trim():fail('Invalid content');
const id=v=>/^[a-zA-Z0-9][a-zA-Z0-9_/-]{0,99}$/.test(v??'')?v:fail('Invalid source ID');
export const contentFields=['id','title','manualTitle','manual','tip','tags','imageUrl','videoUrl','sourceUrl'];
export function stepContent(s){return {id:s.id,title:s.title,...(s.manualTitle?{manualTitle:s.manualTitle}:{}),manual:s.manual,tip:s.tip??'',tags:s.tags??[],imageUrl:s.imageUrl??'',videoUrl:s.videoUrl??'',sourceUrl:s.sourceUrl??''};}
export function templateContent(t){return {title:t.title,...(t.manualTitle?{manualTitle:t.manualTitle}:{}),emoji:t.emoji??'📝',steps:(t.steps??[]).map(stepContent)};}
export const contentHash=t=>createHash('sha256').update(JSON.stringify(templateContent(t))).digest('hex');
export function validateCatalog(entries){
 if(!Array.isArray(entries)||!entries.length||entries.length>650)fail('Invalid catalogue size');
 const seen=new Set();
 return entries.map(t=>{
  const sourceId=id(t.sourceId);if(seen.has(sourceId))fail('Duplicate TAP source ID');seen.add(sourceId);
  if(!Array.isArray(t.steps)||t.steps.length<1||t.steps.length>30)fail('Invalid Task count');
  const ids=new Set();
  const steps=t.steps.map(s=>{
   if(Object.keys(s).some(k=>!contentFields.includes(k)))fail('Public Tasks contain content only');
   const sid=id(s.id);if(ids.has(sid))fail('Duplicate Task ID');ids.add(sid);
   return {id:sid,title:text(s.title,100,'Task title'),manual:text(s.manual,700,'manual'),tip:optional(s.tip,400),tags:manualTags(s.tags),imageUrl:mediaLink(s.imageUrl),videoUrl:mediaLink(s.videoUrl),sourceUrl:mediaLink(s.sourceUrl)};
  });
  return {sourceId,collectionId:id(t.collectionId),collectionName:text(t.collectionName,80,'collection'),title:text(t.title,100,'TAP title'),emoji:optional(t.emoji,20)||'📝',slot:['오픈','준비','피크','브레이크','마감'].includes(t.slot)?t.slot:'준비',reviewedAt:text(t.reviewedAt,30,'review date'),basis:optional(t.basis,500),steps};
 });
}
