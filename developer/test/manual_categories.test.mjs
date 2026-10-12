import {test} from 'node:test';
import assert from 'node:assert/strict';
import {manualCategory,manualCategoryIds} from '../manual_categories.mjs';
import {manualCatalog,mutateManualMarket,syncManualCatalog,checklistBackup} from '../manual_market.mjs';
import {validateExampleStores} from '../fictional_store_schema.mjs';
import {seedOperations,OperationsStore} from '../operations.mjs';
import {workEligibility} from '../knowledge_work.mjs';
const now=new Date('2026-10-12T02:00:00Z'),actor={id:'protected-owner',name:'Owner',role:'owner'};
test('five categories preserve explicit classification and separate recipes from execution',()=>{
 assert.deepEqual(manualCategoryIds,['startup','periodic','routine','recipe','reference']);
 assert.equal(manualCategory({menuManualId:'menu',manualCategoryOverride:'routine'}),'recipe');
 assert.equal(manualCategory({manualCategoryOverride:'periodic',knowledge:{useCase:'routine'}}),'periodic');
 assert.equal(manualCategory({knowledge:{useCase:'training'}}),'reference');
 assert.equal(manualCategory({sourceId:'food/equipment'}),'periodic');
 assert.equal(manualCategory({collectionId:'business',knowledge:{suggestedUse:'routine'}}),'routine');
});
test('fictional store has coherent detailed folders, methods, capacity and saved policies',()=>{
 const entries=manualCatalog.entries.filter(e=>e.knowledge?.exampleStoreId==='soldam'),profile=manualCatalog.taxonomy.exampleStores[0];
 assert.equal(entries.length,26);assert.equal(entries.reduce((n,e)=>n+e.steps.length,0),108);
 assert.equal(new Set(entries.map(e=>e.knowledge.exampleFolder)).size,15);
 assert.equal(profile.places.filter(p=>p.type==='table').reduce((n,p)=>n+p.seats,0),20);
 validateExampleStores([profile],manualCatalog.entries);
 const broken=structuredClone(profile);broken.tapSettings[0].settings.enabled=true;
 assert.throws(()=>validateExampleStores([broken],manualCatalog.entries),{status:400});
 const outside=structuredClone(profile);outside.places[0].x=50;
 assert.throws(()=>validateExampleStores([outside],manualCatalog.entries),{status:400});
});
test('references cannot become daily checks; periodic work requires weekly/monthly selection',()=>{
 const state=seedOperations(now),base=state.taskTemplates[0];
 for(const category of ['startup','recipe','reference']){
  const template={...base,registration:{status:'registered'},manualCategoryOverride:category,settings:{...base.settings,enabled:true,usage:'routine'}};
  assert.equal(workEligibility(state,template,state.day)[0],'reference');
 }
 const periodic={...base,registration:{status:'registered'},manualCategoryOverride:'periodic',settings:{...base.settings,enabled:true,usage:'routine',recurrence:{mode:'daily',weekdays:[]}}};
 assert.equal(workEligibility(state,periodic,state.day)[0],'incomplete');
});
test('import of example adds definitions atomically without replacing protected manuals or history',async()=>{
 let state=seedOperations(now);
 const store=new OperationsStore(null,()=>now,{actor,persistence:{read:async()=>structuredClone(state),save:async next=>{state=next;}}});
 const opening=await store.snapshot();const before=structuredClone(state);
 const sources=manualCatalog.entries.filter(e=>e.knowledge?.exampleStoreId==='soldam').map(e=>e.sourceId);
 await store.mutate(null,{action:'import_market_taps',revision:opening.revision,operationId:'fictional-import-protected',releaseId:manualCatalog.releaseId,sourceIds:sources,folderMode:'example'});
 for(const old of before.taskTemplates)assert.deepEqual(state.taskTemplates.find(t=>t.id===old.id),old);
 assert.deepEqual(state.tasks,before.tasks);
 const added=state.taskTemplates.filter(t=>!before.taskTemplates.some(old=>old.id===t.id));assert.equal(added.length,26);
 assert.ok(added.every(t=>t.registration.status==='pending'&&t.settings.enabled===false));
 const prep=added.find(t=>state.catalogLinks[t.id].sourceId==='soldam/production-prep');
 assert.equal(prep.settings.knowledgeIds.length,3);
 assert.ok(prep.settings.knowledgeIds.every(id=>added.some(t=>t.id===id)));
});
test('classification edits preserve source content, policy and snapshot and survive public metadata sync',()=>{
 const state=seedOperations(now),template=state.taskTemplates.find(t=>!t.menuManualId),before=structuredClone(template),history=structuredClone(state.tasks);
 mutateManualMarket(state,{action:'save_manual_tap',templateId:template.id,title:template.title,emoji:template.emoji,folderId:template.folderId,steps:template.steps,manualCategory:'periodic'},actor,now);
 assert.equal(template.manualCategoryOverride,'periodic');assert.deepEqual(template.steps.map(s=>[s.id,s.title,s.manual,s.tip??'']),before.steps.map(s=>[s.id,s.title,s.manual,s.tip??'']));assert.deepEqual(template.settings,before.settings);assert.deepEqual(state.tasks,history);
 syncManualCatalog(state,now);assert.equal(template.manualCategoryOverride,'periodic');
 (state.catalogLinks??={})[template.id]={mode:'personalized'};
 assert.equal(checklistBackup(state).templates.find(t=>t.id===template.id)?.manualCategoryOverride,'periodic');
});
