import {readFileSync} from 'node:fs';
import {addDishwashingExample} from '../developer/dishwashing_example.mjs';
export function manualTranslationSources(catalog,ownerStarter,firstShiftSource) {
 const sources=new Set(['우리 매장에 오신 것을 환영해요','처음 하는 일은 동료와 함께 확인해 주세요. 모르는 점이나 위험한 상황은 바로 물어봐도 괜찮아요.']);
 const add=text=>{if(typeof text==='string'&&/[가-힣]/.test(text)&&text.trim())sources.add(text);};
 add(ownerStarter.assumption);
 for(const match of firstShiftSource.matchAll(/'([^'\n]*)'/g))add(match[1]);
 for(const entry of [...catalog.entries,...ownerStarter.entries]) {
  add(entry.title);add(entry.summary);add(entry.applicability);add(entry.collectionName);add(entry.basis);add(entry.jurisdiction);
  for(const ref of entry.references??[]){add(ref.title);add(ref.scope);}
  add(entry.knowledge?.exampleFolder);add(entry.knowledge?.cadenceHint);
  for(const step of entry.steps??[])for(const key of ['title','manual','tip'])add(step[key]);
 }
 const walk=value=>{if(typeof value==='string')add(value);else if(Array.isArray(value))value.forEach(walk);else if(value&&typeof value==='object')Object.values(value).forEach(walk);};
 walk(catalog.taxonomy.exampleStores);
 for(const row of [...catalog.taxonomy.industries,...catalog.taxonomy.purposes])add(row.name);
 return sources;
}
export function readManualTranslationSources() {
 const catalog=JSON.parse(readFileSync(new URL('../docs/market/current.json',import.meta.url)));
 const ownerStarter=JSON.parse(readFileSync(new URL('../developer/owner_starter_content.json',import.meta.url)));
 const firstShiftSource=readFileSync(new URL('../app/lib/domain/lesson.dart',import.meta.url),'utf8');
 const sources=manualTranslationSources(catalog,ownerStarter,firstShiftSource);
 // Collect the same example definitions used by setup without touching a store.
 const example={taskTemplates:[],checklistFolders:[]};
 addDishwashingExample(example,{role:'owner'},new Date('2026-10-13T00:00:00Z'));
 for(const folder of example.checklistFolders)sources.add(folder.name);
 for(const template of example.taskTemplates){
  sources.add(template.title);
  for(const step of template.steps)for(const key of ['title','manual','tip'])if(step[key])sources.add(step[key]);
 }
 return {catalog,ownerStarter,sources};
}
