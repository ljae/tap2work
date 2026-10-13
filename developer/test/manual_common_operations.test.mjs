import test from 'node:test';
import assert from 'node:assert/strict';
import catalog from '../../docs/market/current.json' with {type:'json'};
import previous from '../../docs/market/releases/c7eaf2f00bf0c2a095fb75788df356f49637c14366f66fa9681ed4474488a1eb.json' with {type:'json'};
import ownerContent from '../owner_starter_content.json' with {type:'json'};
import {manualCategory} from '../manual_categories.mjs';
import {workEligibility} from '../knowledge_work.mjs';
import {readManualTranslationSources} from '../../scripts/manual-translation-sources.mjs';

test('expanded common content preserves previous source and action identities',()=>{
 for(const old of previous.entries){
  const next=catalog.entries.find(e=>e.sourceId===old.sourceId);
  assert.ok(next,old.sourceId);
  for(const step of old.steps)assert.ok(next.steps.some(s=>s.id===step.id),`${old.sourceId}/${step.id}`);
 }
 const common=catalog.entries.filter(e=>ownerContent.entries.some(o=>e.sourceId===(o.sourceId??`food/${o.id}`)));
 assert.equal(common.length,24);
 assert.equal(common.reduce((n,e)=>n+e.steps.length,0),110);
 for(const entry of common)for(const step of entry.steps){
  assert.ok(step.manual.length>=80,`${entry.sourceId}/${step.id}: detailed method`);
  assert.ok(step.tip.trim(),`${entry.sourceId}/${step.id}: store adaptation`);
 }
});

test('food-specific guides are recipes and pre-opening guides are not daily work',()=>{
 const collections=['korean','snack','bbq','sushi','chicken','pizza','chinese','cafe','bakery','banchan'];
 for(const entry of catalog.entries.filter(e=>collections.includes(e.collectionId)||e.sourceId.startsWith('process/'))){
  assert.equal(manualCategory(entry),'recipe',entry.sourceId);
  assert.equal(entry.knowledge.suggestedUse,'reference');
  assert.equal(workEligibility({}, {...entry,settings:{enabled:true,usage:'routine'}},'2026-10-13')[0],'reference');
 }
 const startup=catalog.entries.filter(e=>e.sourceId.startsWith('startup/'));
 assert.equal(startup.length,6);
 for(const entry of startup){
  assert.equal(manualCategory(entry),'startup');
  assert.equal(entry.steps.length,4);
  assert.equal(workEligibility({}, {...entry,settings:{enabled:true,usage:'routine'}},'2026-10-13')[0],'reference');
  for(const step of entry.steps)assert.ok(step.manual.includes('완료 기준:'),step.title);
 }
});

test('translation sources include the actual dishwashing example and opening details',()=>{
 const {sources}=readManualTranslationSources();
 for(const text of ['설거지 본보기','반납 식기를 종류별로 나누기','잔반은 지정된 통에 버리기','거름망과 배수 상태 확인하기','개업 전 · 가오픈과 최종 준비 확인'])assert.ok(sources.has(text),text);
});
