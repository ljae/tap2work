import {test} from 'node:test';
import assert from 'node:assert/strict';
import {OperationsStore,emptyOperations} from '../operations.mjs';
import {manualCatalog,syncManualCatalog,checklistBackup} from '../manual_market.mjs';
import {contentHash,validateCatalog} from '../manual_catalog_schema.mjs';
import {defaultWorkplace} from '../parts.mjs';
import {sectionPatch} from '../section_storage.mjs';
function fixture(role='owner'){
 let now=new Date('2026-10-04T08:00:00Z');
 let state=emptyOperations(now,'owner-1','사장님');
 const actor={id:role==='owner'?'owner-1':`${role}-1`,role,name:'테스트'};
 const store=new OperationsStore(null,()=>now,{actor,persistence:{read:async()=>structuredClone(state),save:async(next,revision)=>{assert.equal(revision,state.revision);state=structuredClone(next);}}});
 const act=async(action,values={})=>store.mutate(actor.id,{action,revision:(await store.snapshot(actor.id)).revision,...values});
 const importTap=(operationId='import-0001')=>act('import_market_taps',{operationId,releaseId:manualCatalog.releaseId,folderId:'general',sourceIds:[manualCatalog.entries[0].sourceId]});
 return {store,actor,act,importTap,raw:()=>state,nextDay:()=>now=new Date(now.getTime()+86400000)};
}
const imported=x=>x.raw().taskTemplates.find(t=>x.raw().catalogLinks?.[t.id]?.mode==='linked');
const save=(t,overrides={})=>({templateId:t.id,title:t.title,emoji:t.emoji,folderId:t.folderId,steps:structuredClone(t.steps),...overrides});
test('market import links immutable content, disables work and retries exactly once even with old revision',async()=>{
 const x=fixture();const before=await x.store.snapshot(x.actor.id);
 const body={action:'import_market_taps',revision:before.revision,operationId:'import-0001',releaseId:manualCatalog.releaseId,folderId:'general',sourceIds:[manualCatalog.entries[0].sourceId]};
 const view=await x.store.mutate(x.actor.id,body);const t=imported(x);
 assert.equal(t.settings.enabled,false);assert.equal(t.assignmentScopeVersion,2);
 assert.equal(t.settings.assignment,undefined);assert.equal(contentHash(t),contentHash(manualCatalog.entries[0]));
 assert.equal(view.manualCatalog.entries[0].installed[0].mode,'linked');assert.deepEqual(x.raw().tasks,[]);
 const revision=x.raw().revision;
 await x.store.mutate(x.actor.id,body);assert.equal(x.raw().revision,revision);assert.equal(x.raw().taskTemplates.length,1);
 await assert.rejects(()=>x.act('import_market_taps',{...body,revision:x.raw().revision,sourceIds:[manualCatalog.entries[1].sourceId]}),{status:409});
 await assert.rejects(()=>x.importTap('import-0002'),{status:400});
 assert.equal(view.catalogOperations,undefined);assert.equal(view.catalogHistory,undefined);
});
test('automatic public update changes definition and manual together, retaining policy and execution snapshots',async()=>{
 const x=fixture();await x.importTap();let t=imported(x);
 await x.act('save_tap_settings',{templateId:t.id,assignmentScopeVersion:2,settings:{...t.settings,enabled:true,enforceSequence:true}});
 t=imported(x);assert.ok(x.raw().tasks.length);
 const executions=structuredClone(x.raw().tasks),settings=structuredClone(t.settings),folders=structuredClone(x.raw().checklistFolders);
 const next=structuredClone(manualCatalog);next.releaseId='public-v2';next.entries[0].title='업데이트한 TAP';next.entries[0].steps[0].manual='업데이트한 매뉴얼';
 const old=structuredClone(x.raw());
 assert.equal(syncManualCatalog(x.raw(),new Date('2026-10-04T09:00:00Z'),next),true);
 assert.equal(t.title,'업데이트한 TAP');assert.equal(t.steps[0].manual,'업데이트한 매뉴얼');assert.deepEqual(t.settings,settings);
 assert.deepEqual(x.raw().tasks,executions);assert.deepEqual(x.raw().checklistFolders,folders);
 assert.equal(x.raw().catalogLinks[t.id].mode,'linked');assert.equal(x.raw().catalogLinks[t.id].releaseId,'public-v2');
 assert.equal(syncManualCatalog(x.raw(),new Date(),next),false);
 assert.deepEqual(sectionPatch(old,x.raw()).removed,[]);assert.ok(sectionPatch(old,x.raw()).changes.catalogLinks);
});
test('editing a linked TAP detaches content while preserving generated work; next generation uses edit',async()=>{
 const x=fixture();await x.importTap();let t=imported(x);
 await x.act('save_tap_settings',{templateId:t.id,assignmentScopeVersion:2,settings:{...t.settings,enabled:true}});
 t=imported(x);const history=structuredClone(x.raw().tasks),draft=save(t,{title:'우리 매장 방식'});draft.steps[0].manual='매장 전용 매뉴얼';
 await x.act('save_manual_tap',draft);
 assert.equal(x.raw().catalogLinks[t.id].mode,'personalized');assert.deepEqual(x.raw().tasks,history);
 const next=structuredClone(manualCatalog);next.entries[0].title='공용 새 제목';
 assert.equal(syncManualCatalog(x.raw(),new Date(),next),false);
 assert.equal(x.raw().taskTemplates[0].title,'우리 매장 방식');
 x.nextDay();await x.store.snapshot(x.actor.id);
 assert.equal(x.raw().tasks.at(-1).title,'우리 매장 방식');assert.equal(x.raw().tasks.at(-1).steps[0].manual,'매장 전용 매뉴얼');
 assert.deepEqual(x.raw().tasks[0],history[0]);
});
test('folder/settings edits remain linked, personalized copy has independent content and disabled policy',async()=>{
 const x=fixture();await x.importTap();let t=imported(x);
 x.raw().checklistFolders.push({id:'close',name:'마감'});
 await x.act('save_manual_tap',save(t,{folderId:'close'}));assert.equal(x.raw().catalogLinks[t.id].mode,'linked');
 await x.act('personalize_market_tap',{templateId:t.id,operationId:'copy-0001'});
 const copy=x.raw().taskTemplates.find(v=>v.id!==t.id);assert.equal(copy.settings.enabled,false);assert.equal(x.raw().catalogLinks[copy.id].mode,'personalized');
 assert.equal(x.raw().catalogLinks[t.id].mode,'linked');assert.deepEqual(copy.steps,x.raw().taskTemplates.find(v=>v.id===t.id).steps);
});
test('new local TAP is disabled, idempotent, content-only, and edits use revision CAS',async()=>{
 const x=fixture();const body={operationId:'create-0001',templateId:null,title:'자체 TAP',emoji:'📝',folderId:'general',steps:[{id:'one',title:'확인',manual:'확인 방법'}]};
 await x.act('save_manual_tap',body);await x.act('save_manual_tap',body);
 assert.equal(x.raw().taskTemplates.length,1);assert.equal(x.raw().taskTemplates[0].settings.enabled,false);
 const revision=x.raw().revision;await x.act('save_manual_tap',save(x.raw().taskTemplates[0],{title:'바꾼 이름'}));
 await assert.rejects(()=>x.act('save_manual_tap',{...save(x.raw().taskTemplates[0]),revision}),{status:409});
 await assert.rejects(()=>x.act('save_manual_tap',{...body,operationId:'create-0002',steps:[{...body.steps[0],settings:{assignment:{mode:'crew',crewIds:['private']}}}]}),{status:400});
});
test('private backup excludes linked TAPs, crew bindings and all execution data; restore adds isolated disabled copies',async()=>{
 const x=fixture();await x.importTap();const t=imported(x);
 await x.act('personalize_market_tap',{templateId:t.id,operationId:'copy-0001'});
 const personal=x.raw().taskTemplates.find(v=>v.id!==t.id);
 personal.settings.assignment={mode:'crew',crewIds:['private-person']};personal.settings.enabled=true;
 const file=JSON.parse(JSON.stringify(checklistBackup(x.raw())));
 assert.equal(file.templates.length,1);assert.equal(file.templates[0].title,personal.title);
 assert.equal(JSON.stringify(file).includes('private-person'),false);assert.equal(file.tasks,undefined);assert.equal(file.catalogLinks,undefined);
 const target=fixture();await target.importTap();const existing=structuredClone(target.raw().taskTemplates);
 await target.act('restore_checklist_backup',{operationId:'restore-0001',backup:file});
 assert.equal(target.raw().taskTemplates.length,2);assert.deepEqual(target.raw().taskTemplates[0],existing[0]);
 const restored=target.raw().taskTemplates[1];assert.equal(restored.title,personal.title);assert.deepEqual(restored.steps.map(s=>s.manual),personal.steps.map(s=>s.manual));
 assert.equal(restored.settings.enabled,false);assert.equal(restored.settings.assignment,undefined);assert.equal(restored.partId,null);assert.equal(restored.zone,null);
 assert.equal(target.raw().catalogLinks[restored.id].mode,'personalized');
 await target.act('restore_checklist_backup',{operationId:'restore-0001',backup:file});assert.equal(target.raw().taskTemplates.length,2);
});
test('malformed and unsafe imports are rejected atomically, including Task policy and dangerous URLs',async()=>{
 const x=fixture();await x.importTap();await x.act('personalize_market_tap',{templateId:imported(x).id,operationId:'copy-0001'});
 const file=JSON.parse(JSON.stringify(checklistBackup(x.raw()))),previous=structuredClone(x.raw());
 for(const mutation of [f=>f.templates[0].steps[0].sourceUrl='javascript:alert(1)',f=>f.templates[0].steps[0].settings={completionKind:'quantity'},f=>f.templates[0].folderId='unknown',f=>f.templates[0].settings.recurrence={mode:'weekly',weekdays:[]}]){
  const bad=structuredClone(file);mutation(bad);
  await assert.rejects(()=>x.act('restore_checklist_backup',{operationId:'restore-unsafe',backup:bad}),{status:400});assert.deepEqual(x.raw(),previous);
 }
 await assert.rejects(()=>x.act('import_market_taps',{operationId:'import-stale',releaseId:'stale',folderId:'general',sourceIds:[manualCatalog.entries[1].sourceId]}),{status:409});
});
test('worker and restricted manager cannot import, edit or export private templates',async()=>{
 for(const role of ['crew','manager']){
  const x=fixture(role);if(role==='manager')x.raw().workplace={...defaultWorkplace(),restrictions:{manager:{tasks:false}}};
  const view=await x.store.snapshot(x.actor.id);assert.equal(view.manualCatalog,undefined);assert.equal(view.checklistBackup,undefined);assert.equal(view.catalogLinks,undefined);
  await assert.rejects(()=>x.importTap(),{status:403});
 }
});
test('catalog validates stable unique IDs and prohibits operational fields inside public Tasks',()=>{
 assert.equal(validateCatalog(manualCatalog.entries).length,64);
 const duplicate=structuredClone(manualCatalog.entries);duplicate[1].sourceId=duplicate[0].sourceId;assert.throws(()=>validateCatalog(duplicate),/Duplicate/);
 const policy=structuredClone(manualCatalog.entries);policy[0].steps[0].settings={enabled:true};assert.throws(()=>validateCatalog(policy),/content only/);
});
test('menu-linked TAP detail aliases do not rename the sales menu or source Task',async()=>{
 const x=fixture();await x.act('save_menu',{name:'판매 메뉴',category:'식사',price:5000});
 const t=x.raw().taskTemplates.find(v=>v.menuManualId),original=structuredClone(t);
 const draft=save(t,{title:'판매 이름 변경 시도',manualTitle:'맞춤 조리 매뉴얼'});draft.steps[0].manualTitle='우리 매장 조리';draft.steps[0].title='원본 변경 시도';draft.steps[0].manual='새 방법';
 await x.act('save_manual_tap',draft);
 const saved=x.raw().taskTemplates.find(v=>v.id===t.id);
 assert.equal(x.raw().sales.menus[0].name,'판매 메뉴');assert.equal(saved.title,original.title);assert.equal(saved.manualTitle,'맞춤 조리 매뉴얼');assert.equal(saved.steps[0].title,original.steps[0].title);assert.equal(saved.steps[0].manualTitle,'우리 매장 조리');
});
