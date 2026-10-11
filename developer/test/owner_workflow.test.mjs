import {test} from 'node:test';
import assert from 'node:assert/strict';
import {OperationsStore,emptyOperations} from '../operations.mjs';
import {recurringOn,validateRecurrence} from '../work_recurrence.mjs';
import {manualCatalog} from '../manual_market.mjs';
import {validateChecklists} from '../checklists.mjs';
const date=new Date('2026-10-11T04:00:00Z');
function fixture(){
 let now=date,state=emptyOperations(now,'owner','사장님');
 state.workplace={parts:[{id:'hall',name:'홀'},{id:'kitchen',name:'주방'},{id:'management',name:'관리'}],days:Object.fromEntries([1,2,3,4,5,6,7].map(d=>[d,[{id:'all',name:'전체',start:'09:00',end:'22:00',headcounts:{hall:1,kitchen:1,management:1}}]]))};
 const actor={id:'owner',role:'owner',name:'사장님'};
 const persistence={read:async()=>structuredClone(state),save:async next=>{state=structuredClone(next);}};
 const store=new OperationsStore(null,()=>now,{actor,persistence});
 const act=async(action,values={})=>store.mutate('owner',{action,revision:(await store.snapshot()).revision,...values});
 return {store,act,raw:()=>state,advance:()=>now=new Date(now.getTime()+86400000),as:role=>new OperationsStore(null,()=>now,{actor:{id:role,role,name:role},persistence})};
}
test('only reviewed owner selection registers starter manuals; roles, duplicate retries, search and work remain separate',async()=>{
 const x=fixture(),before=await x.store.snapshot();
 assert.equal(before.ownerWorkflow.candidates.length,24);assert.equal(before.manualSearch.length,0);
 await assert.rejects(x.act('register_starter_manuals',{ids:['phone-service'],starterVersion:1}),/검토/);
 const body={action:'register_starter_manuals',reviewed:true,ids:['phone-service','food-hall-open','monthly-review'],starterVersion:1};
 const manager=x.as('manager');await assert.rejects(manager.mutate('manager',{...body,revision:(await manager.snapshot()).revision}),/사장님/);
 let view=await x.act(body.action,body);
 assert.equal(view.taskTemplates.length,3);assert.ok(view.manualSearch.some(s=>s.title.includes('전화 받기')));
 assert.ok(view.taskTemplates.every(t=>t.registration.actorId==='owner'));
 assert.ok(view.tasks.every(t=>!['phone-service','monthly-review'].includes(t.starterId)));
 await x.act(body.action,body);assert.equal(x.raw().taskTemplates.length,3);
 const crew=await x.as('crew').snapshot();assert.equal(crew.ownerWorkflow,undefined);assert.equal(crew.taskTemplates.length,3);
});
test('import is invisible to crew/search/print and event execution until owner confirms; editing cannot remove the gate',async()=>{
 const x=fixture();let view=await x.act('import_market_taps',{operationId:'owner-gate-001',sourceIds:['food/service'],releaseId:manualCatalog.releaseId,folderMode:'purpose'});
 const t=view.taskTemplates[0];assert.equal(t.registration.status,'pending');assert.equal(view.manualSearch.length,0);assert.equal(view.manualPrintTemplates.length,0);
 assert.equal((await x.as('crew').snapshot()).taskTemplates.length,0);
 const checked=validateChecklists({folders:x.raw().checklistFolders,templates:x.raw().taskTemplates},x.raw());assert.equal(checked.templates[0].registration.status,'pending');
 view=await x.act('register_owner_manuals',{ids:[t.id],reviewed:true});assert.ok(view.manualSearch.length);assert.equal(view.tasks.length,0);
});
test('weekly and month end recur on next open day, coalesce closures and respect date overrides',()=>{
 const state=emptyOperations(date,'owner','owner');
 state.workplace={};
 const band={id:'a',name:'전체',start:'09:00',end:'22:00',headcounts:{hall:1}};
 state.workplace.days=Object.fromEntries([1,2,3,4,5,6,7].map(d=>[d,d===1?[]:[band]]));
 const weekly={settings:{recurrence:{mode:'weekly',weekdays:[1],holidayPolicy:'next_open'}}};
 assert.equal(recurringOn(state,weekly,'2026-10-12'),false);assert.equal(recurringOn(state,weekly,'2026-10-13'),true);assert.equal(recurringOn(state,weekly,'2026-10-14'),false);
 state.workplace.dateOverrides={'2026-10-13':{closed:true}};assert.equal(recurringOn(state,weekly,'2026-10-14'),true);
 const monthly={settings:{recurrence:{mode:'monthly',monthDay:31,weekdays:[],holidayPolicy:'next_open'}}};
 assert.equal(recurringOn(state,monthly,'2027-02-28'),true);assert.equal(recurringOn(state,monthly,'2027-03-02'),false);
 assert.throws(()=>validateRecurrence({mode:'monthly',monthDay:0}),/반복/);
});
test('tomorrow settings are a read-only projection until due; today snapshot and completed content survive',async()=>{
 const x=fixture();let view=await x.act('register_starter_manuals',{ids:['food-hall-open'],reviewed:true,starterVersion:1});
 const t=view.taskTemplates[0],today=structuredClone(x.raw().tasks);
 const future={...t.settings,usage:'routine',assignment:{mode:'crew',crewIds:[x.raw().tappers[0].id]}};
 view=await x.act('schedule_tap_settings',{templateId:t.id,effectiveFrom:view.ownerWorkflow.date,settings:future,assignmentScopeVersion:2});
 assert.deepEqual(x.raw().tasks,today);assert.equal(x.raw().taskTemplates[0].settings.assignment.mode,t.settings.assignment.mode);
 assert.equal(view.ownerWorkflow.plans[0].scheduled,true);assert.equal(view.ownerWorkflow.plans[0].assignment.assignees.length,1);
 assert.equal(x.raw().tasks.some(t=>t.date===view.ownerWorkflow.date),false);
 await assert.rejects(x.act('schedule_tap_settings',{templateId:t.id,effectiveFrom:'2026-10-10',settings:future}),/날짜/);
 x.advance();view=await x.store.snapshot();assert.equal(view.taskTemplates[0].scheduledSettings,undefined);assert.equal(view.taskTemplates[0].settings.assignment.mode,'crew');assert.deepEqual(x.raw().tasks.filter(t=>t.date===today[0]?.date),today);
});

test('reviewed source updates wait for owner and never rewrite today execution; same-source starter upgrades reuse identity',async()=>{
 const x=fixture();let view=await x.act('import_market_taps',{operationId:'source-update-01',sourceIds:['food/hall-open'],releaseId:manualCatalog.releaseId,folderMode:'purpose'});
 const id=view.taskTemplates[0].id;
 view=await x.act('register_owner_manuals',{ids:[id],reviewed:true});
 await x.act('save_tap_settings',{templateId:id,assignmentScopeVersion:2,settings:{...view.taskTemplates[0].settings,usage:'routine',enabled:true}});
 const tasks=structuredClone(x.raw().tasks),count=x.raw().taskTemplates.length;
 const next=structuredClone(manualCatalog),source=next.entries.find(t=>t.sourceId==='food/hall-open');source.steps[0].manual='새 공용 설명';next.releaseId='owner-reviewed-next';
 const {syncManualCatalog}=await import('../manual_market.mjs');syncManualCatalog(x.raw(),date,next);
 assert.notEqual(x.raw().taskTemplates[0].steps[0].manual,'새 공용 설명');assert.equal(x.raw().catalogLinks[id].availableReleaseId,next.releaseId);
 await x.act('register_starter_manuals',{ids:['food-hall-open'],reviewed:true,starterVersion:1});
 assert.equal(x.raw().taskTemplates.length,count);assert.equal(x.raw().taskTemplates[0].id,id);assert.equal(x.raw().taskTemplates[0].starterId,'food-hall-open');assert.deepEqual(x.raw().tasks,tasks);
});

test('batch with an invalid pending ID commits nothing and stale revisions cannot approve changed content',async()=>{
 const x=fixture(),view=await x.store.snapshot();
 await assert.rejects(x.act('register_owner_selection',{reviewed:true,starterVersion:1,starterIds:['phone-service'],pendingIds:['missing']}),/다시 확인/);
 assert.equal(x.raw().taskTemplates.length,0);
 await x.act('register_starter_manuals',{ids:['guest-welcome'],reviewed:true,starterVersion:1});
 await assert.rejects(x.store.mutate('owner',{action:'register_starter_manuals',revision:view.revision,reviewed:true,starterVersion:1,ids:['phone-service']}),{status:409});
 assert.equal(x.raw().taskTemplates.length,1);
});


test('starter registration preserves purpose-only store folders without requiring a legacy general folder',async()=>{
 const x=fixture();
 x.raw().checklistFolders=[{id:'existing-service',name:'기존 응대'}];
 const view=await x.act('register_owner_selection',{reviewed:true,starterVersion:1,starterIds:['phone-service','food-hall-open'],pendingIds:[]});
 assert.equal(view.taskTemplates.length,2);
 assert.ok(view.manualSearch.some(t=>t.title.includes('전화 받기')));
 assert.ok(x.raw().checklistFolders.some(f=>f.id==='existing-service'));
 assert.equal(x.raw().checklistFolders.some(f=>f.id==='general'),false);
 assert.equal(view.ownerWorkflow.candidates.some(t=>t.id==='food-hall-open'),false);
});
