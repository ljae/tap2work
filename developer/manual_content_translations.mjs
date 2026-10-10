import { createHash } from 'node:crypto';
import { StoreError } from './store.mjs';
import { supportedLocales } from './localization.mjs';
import { welcomeContent } from './common_guidance.mjs';
const fail = (message, status = 400) => { throw new StoreError(message, status); };
const hash = text => createHash('sha256').update(text).digest('hex');
const slot = (map,key) => { if (!Object.hasOwn(map,key) || !map[key]) Object.defineProperty(map,key,{value:{},writable:true,enumerable:true,configurable:true}); return map[key]; };
function sourceContent(state, source) {
  if (!source || typeof source !== 'object' || Array.isArray(source) || Object.keys(source).some(k => !['kind','id'].includes(k))) fail('번역할 원문을 선택해 주세요.');
  if (source.kind === 'welcome' && source.id == null) { const welcome=welcomeContent(state); return {title:welcome.title,body:welcome.body}; }
  if (source.kind !== 'manual' || typeof source.id !== 'string') fail('번역할 매뉴얼을 선택해 주세요.');
  const template=(state.taskTemplates??[]).find(row=>row.id===source.id&&!row.archivedAt);
  if (!template) fail('매뉴얼을 찾지 못했어요.',404);
  return {title:template.manualTitle??template.title,steps:(template.steps??[]).map(step=>({id:step.id,title:step.manualTitle??step.title,manual:step.manual??'',tip:step.tip??''}))};
}
function sourceField(content,row) {
  if (row.stepId != null) {
    if (typeof row.stepId !== 'string' || !['title','manual','tip'].includes(row.field)) fail('번역할 단계를 확인해 주세요.');
    const step=content.steps?.find(step=>step.id===row.stepId);
    if (!step) fail('원문 단계가 바뀌었어요. 다시 열어 주세요.',409);
    return step[row.field];
  }
  if (!['title','body'].includes(row.field) || typeof content[row.field] !== 'string') fail('번역할 항목을 확인해 주세요.');
  return content[row.field];
}
export function saveManualTranslation(state,input,actor,now) {
  if (!['owner','manager'].includes(actor.role) || actor.role!=='owner' && state.workplace?.restrictions?.[actor.role]?.tasks===false) fail('매뉴얼 편집 권한이 필요해요.',403);
  if (!supportedLocales.includes(input.locale)) fail('지원하는 번역 언어를 선택해 주세요.');
  const content=sourceContent(state,input.source);
  if (!Array.isArray(input.fields) || !input.fields.length || input.fields.length>193) fail('번역 항목은 1–193개로 저장해 주세요.');
  const seen=new Set();let total=0;
  const updates=input.fields.map(row=>{
    if (!row || typeof row!=='object' || Array.isArray(row) || Object.keys(row).some(k=>!['stepId','field','sourceText','text'].includes(k))) fail('번역 항목 형식을 확인해 주세요.');
    const original=sourceField(content,row),key=JSON.stringify([row.stepId??null,row.field]);
    if (seen.has(key)) fail('같은 번역 항목이 중복되었어요.');seen.add(key);
    if (row.sourceText!==original) fail('원문이 변경됐어요. 바뀐 부분을 확인한 뒤 번역을 등록해 주세요.',409);
    const limit=row.field==='title'?360:row.field==='tip'?3600:24000;
    if (typeof row.text!=='string' || row.text.length>limit || original.trim()&&!row.text.trim()) fail('번역의 내용과 길이를 확인해 주세요.');
    total+=row.text.length;if(total>150000)fail('번역 가져오기 크기가 너무 커요.',413);
    return {stepId:row.stepId,field:row.field,cell:{sourceHash:hash(original),sourceText:original,text:row.text.trim(),updatedAt:now.toISOString(),updatedBy:actor.id}};
  });
  const store=state.manualContentTranslations??={manuals:{},welcome:{}};
  let target;
  if(input.source.kind==='welcome')target=slot(store.welcome??={},input.locale);
  else {const manual=slot(store.manuals??={},input.source.id);target=slot(manual,input.locale);}
  for(const update of updates) {
    if(update.stepId==null)target[update.field]=update.cell;
    else {const step=slot(target.steps??={},update.stepId);step[update.field]=update.cell;}
  }
}
export function manualTranslationView(state) {
  const result={manuals:{},welcome:{}};
  const project=(saved,content)=>{
    const locales={};
    for(const [locale,translation] of Object.entries(saved??{})) {
      if(!supportedLocales.includes(locale))continue;
      const view={};
      const cell=(saved,text)=>saved&&typeof saved.text==='string'?{sourceHash:saved.sourceHash,sourceText:saved.sourceText,text:saved.text,current:saved.sourceHash===hash(text)&&saved.sourceText===text}:null;
      for(const field of ['title','body'])if(typeof content[field]==='string'&&translation[field])view[field]=cell(translation[field],content[field]);
      for(const step of content.steps??[])for(const field of ['title','manual','tip']) {
        const value=cell(translation.steps?.[step.id]?.[field],step[field]);
        if(value)slot(view.steps??={},step.id)[field]=value;
      }
      locales[locale]=view;
    }
    return locales;
  };
  const store=state.manualContentTranslations??{};
  result.welcome=project(store.welcome,sourceContent(state,{kind:'welcome'}));
  for(const template of state.taskTemplates??[])if(!template.archivedAt&&store.manuals?.[template.id])Object.defineProperty(result.manuals,template.id,{value:project(store.manuals[template.id],sourceContent(state,{kind:'manual',id:template.id})),enumerable:true});
  return result;
}
