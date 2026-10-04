import { test } from 'node:test';
import assert from 'node:assert/strict';
import { OperationsStore, emptyOperations } from '../operations.mjs';
import { defaultWorkplace } from '../parts.mjs';
import { assignmentOccurrences, assignmentOf } from '../work_assignments.mjs';
import { taskSettings } from '../task_settings.mjs';
import { policyReport, assertContentOnly } from '../tap_policy.mjs';

function fixture(scope=2) {
 let now=new Date('2026-09-30T02:00:00Z');
 let state=emptyOperations(now,'owner');
 state.workplace=defaultWorkplace();
 state.workplace.days[3]=[{id:'a',name:'오전',custom:true,start:'09:00',end:'13:00',headcounts:{kitchen:2}},{id:'b',name:'오후',custom:true,start:'12:00',end:'17:00',headcounts:{kitchen:1}}];
 const assignment={mode:'scheduled',partId:'kitchen',timeBandIds:['a','b'],crewIds:[]};
 state.taskTemplates=[{id:'clean',assignmentScopeVersion:scope,title:'장비 점검',slot:'오픈',requiredRole:'all',partId:'kitchen',zone:null,folderId:'general',version:1,settings:{...taskSettings({}),assignment},steps:[{id:'one',title:'준비',manual:'도구를 준비해요.',tip:'',contentRevision:1},{id:'two',title:'확인',manual:'상태를 확인해요.',tip:'',contentRevision:1}]}];
 state.tappers.push({id:'k',actorId:'k',nickname:'크루',rank:'crew',active:true,workProfile:{partIds:['kitchen']}});
 state.staffShifts=[{id:'shift',tapperId:'k',date:state.day,partId:'kitchen',timeBandId:'a',start:'09:00',end:'13:00',status:'planned'}];
 const store=new OperationsStore(null,()=>now,{actor:{id:'owner',name:'사장님',role:'owner'},persistence:{read:async()=>structuredClone(state),save:async(next,rev)=>{assert.equal(rev,state.revision);state=structuredClone(next);}}});
 const act=async(action,input={})=>store.mutate('owner',{revision:(await store.snapshot()).revision,action,...input});
 return {store,act,raw:()=>state,next:date=>now=new Date(date)};
}
const clean=v=>v.tasks.filter(t=>t.templateId==='clean');
test('TAP-only occurrences contain all Tasks per band and ignore polluted step allocation',async()=>{
 const x=fixture();x.raw().taskTemplates[0].steps[1].settings={assignment:{mode:'crew',crewIds:['wrong']},partOverride:'hall'};
 const v=await x.store.snapshot();assert.equal(clean(v).length,2);
 assert.deepEqual(clean(v).map(t=>t.steps.map(s=>s.id)),[['one','two'],['one','two']]);
 for(const task of clean(v))assert.deepEqual(task.steps.map(s=>s.assignmentView.assignees),[task.assignmentView.assignees,task.assignmentView.assignees]);
 assert.equal(assignmentOf(x.raw().taskTemplates[0],x.raw().taskTemplates[0].steps[1]).mode,'scheduled');
});
test('new allocation cannot be injected by full checklist save or TAP settings',async()=>{
 const x=fixture();const v=await x.store.snapshot();const templates=structuredClone(v.taskTemplates);templates[0].steps[0].settings={assignment:{mode:'crew',crewIds:['k']}};
 const before=structuredClone(x.raw());
 await assert.rejects(()=>x.act('save_checklists',{folders:v.checklistFolders,templates}),{status:400});
 await assert.rejects(()=>x.act('save_tap_settings',{templateId:'clean',assignmentScopeVersion:2,settings:templates[0].settings,steps:templates[0].steps}),{status:400});
 assert.deepEqual(x.raw(),before);
});
test('v2 quantity is recorded once on TAP after all Task checks, precision enforced',async()=>{
 const x=fixture();await x.act('save_tap_settings',{templateId:'clean',assignmentScopeVersion:2,settings:{...x.raw().taskTemplates[0].settings,allowBulkComplete:false,enforceSequence:true,completionPolicy:{kind:'quantity',quantitySpec:{unit:'kg',decimalPlaces:2}},estimatedMinutes:20}});
 const t=clean(await x.store.snapshot())[0];
 await assert.rejects(()=>x.act('complete_step',{taskId:t.id,stepId:'two'}),{status:409});
 await x.act('complete_step',{taskId:t.id,stepId:'one'});
 const checked=await x.act('complete_step',{taskId:t.id,stepId:'two'});assert.equal(clean(checked)[0].completedAt,null);assert.equal(clean(checked)[0].canComplete,true);
 await assert.rejects(()=>x.act('complete_task',{taskId:t.id,quantity:1.234}),{status:409});
 const done=await x.act('complete_task',{taskId:t.id,quantity:1.25});assert.equal(clean(done)[0].actualQuantity,1.25);assert.ok(clean(done)[0].completedAt);
 await assert.rejects(()=>x.act('complete_task',{taskId:t.id,quantity:5}),{status:409});
 assert.deepEqual(x.raw().items,[]);assert.deepEqual(x.raw().orders,[]);
});
test('content edits increment shared Task/manual revision without changing TAP policy or siblings',async()=>{
 const x=fixture();const v=await x.store.snapshot();const task=clean(v)[0];const settings=structuredClone(x.raw().taskTemplates[0].settings);const sibling=structuredClone(x.raw().taskTemplates[0].steps[1]);const other=structuredClone(x.raw().tasks.find(t=>t.templateId==='clean' && t.timeBandId==='b'));
 await x.act('save_task_step',{taskId:task.id,stepId:'one',title:'준비 개선',manual:'도구와 위치를 먼저 확인해요.'});
 const source=x.raw().taskTemplates[0];assert.equal(source.steps[0].contentRevision,2);assert.equal(source.steps[0].manual,'도구와 위치를 먼저 확인해요.');assert.deepEqual(source.steps[1],sibling);assert.deepEqual(source.settings,settings);
 assert.deepEqual(x.raw().tasks.find(t=>t.id===other.id),other);
});
test('migration preview is read only, acknowledgement required, history and started snapshot preserved',async()=>{
 const x=fixture(1);x.raw().taskTemplates[0].steps[0].settings={assignment:{mode:'crew',crewIds:['k']}};
 const v=await x.store.snapshot();const t=clean(v)[0];await x.act('complete_step',{taskId:t.id,stepId:'one'});
 const before=structuredClone(x.raw());const preview=await x.act('preview_tap_policy_migration',{templateId:'clean'});assert.ok(preview.tapPolicyPreview.needsReview);assert.deepEqual(x.raw(),before);
 const input={templateId:'clean',assignmentScopeVersion:2,settings:x.raw().taskTemplates[0].settings};
 await assert.rejects(()=>x.act('save_tap_settings',input),{status:409});
 await x.act('save_tap_settings',{...input,acknowledgeLegacyPolicy:true});
 assert.equal(x.raw().taskTemplates[0].assignmentScopeVersion,2);assert.ok(x.raw().taskTemplates[0].steps.every(s=>!s.settings));assert.equal(x.raw().tapPolicyHistory.length,1);
 assert.deepEqual(x.raw().tasks.find(row=>row.id===t.id),before.tasks.find(row=>row.id===t.id));assert.equal((await x.store.snapshot()).tapPolicyHistory,undefined);
});
test('calendar closed and extra operating day use effective bands, no Task allocation',()=>{
 const x=fixture();const s=x.raw(),tap=s.taskTemplates[0];s.workplace.dateOverrides={'2026-09-30':{closed:true},'2026-10-01':{closed:false,weekday:3}};
 assert.deepEqual(assignmentOccurrences(s,tap,'2026-09-30'),[]);
 assert.deepEqual(assignmentOccurrences(s,tap,'2026-10-01').map(t=>t.steps.map(s=>s.id)),[['one','two'],['one','two']]);
 s.workplace.parts.find(p=>p.id==='kitchen').hidden=true;assert.deepEqual(assignmentOccurrences(s,tap,'2026-10-01'),[]);
});
test('legacy policy report distinguishes harmless defaults and quantities needing review',()=>{
 const x=fixture(1),t=x.raw().taskTemplates[0];t.steps[0].settings={assignment:{mode:'inherit'},completionKind:'check',partOverride:null};assert.equal(policyReport(t).needsReview,false);
 t.steps[0].settings.quantitySpec={unit:'g',target:100};assert.equal(policyReport(t).needsReview,true);assert.throws(()=>assertContentOnly(t.steps[0]),{status:400});
 assert.throws(()=>assertContentOnly({id:'x',partId:'kitchen'}),{status:400});
});
test('split preserves each legacy quantity policy and snapshots, starts next day and retry is idempotent',async()=>{
 const x=fixture(1);x.raw().taskTemplates[0].steps[0].settings={assignment:{mode:'crew',crewIds:['k']},completionKind:'quantity',quantitySpec:{unit:'kg',target:2,decimalPlaces:2},estimatedMinutes:25};
 const initial=await x.store.snapshot(),before=structuredClone(x.raw().tasks);
 await assert.rejects(()=>x.store.mutate('owner',{revision:initial.revision-1,action:'split_tap_policy',templateId:'clean',operationId:'split-one'}),{status:409});
 const split=await x.act('split_tap_policy',{templateId:'clean',operationId:'split-one'});
 const replacements=x.raw().taskTemplates.filter(t=>t.policyLineage?.templateId==='clean');assert.equal(replacements.length,2);
 assert.deepEqual(x.raw().tasks,before);assert.ok(x.raw().taskTemplates.find(t=>t.id==='clean').archivedAt);
 assert.equal(replacements[0].settings.assignment.mode,'crew');assert.equal(replacements[0].settings.completionPolicy.quantitySpec.target,2);assert.equal(replacements[0].settings.estimatedMinutes,25);
 assert.ok(replacements.every(t=>t.assignmentScopeVersion===2 && !t.steps[0].settings));
 const after=structuredClone(x.raw());await x.store.mutate('owner',{revision:initial.revision,action:'split_tap_policy',templateId:'clean',operationId:'split-one'});assert.deepEqual(x.raw(),after);
 x.next('2026-10-01T02:00:00Z');const tomorrow=await x.store.snapshot();assert.ok(tomorrow.tasks.some(t=>t.templateId===replacements[0].id));assert.ok(!tomorrow.tasks.some(t=>t.templateId==='clean'&&t.date===tomorrow.day&&!t.archivedAt));
 assert.equal(split.tapPolicyHistory,undefined);
});
test('legacy policies cannot be changed or added through compatibility saves',async()=>{
 const x=fixture(1);x.raw().taskTemplates[0].steps[0].settings={completionKind:'quantity',quantitySpec:{unit:'kg',target:2,decimalPlaces:0}};
 const v=await x.store.snapshot();await assert.rejects(()=>x.act('save_tap_settings',{templateId:'clean',settings:x.raw().taskTemplates[0].settings,steps:[{id:'one',settings:{completionKind:'check'}},{id:'two',settings:{}}]}),{status:400});
 const templates=structuredClone(v.taskTemplates);templates[0].steps.push({id:'new',title:'추가',manual:'추가 설명',settings:{assignment:{mode:'crew',crewIds:['k']}}});
 await assert.rejects(()=>x.act('save_checklists',{folders:v.checklistFolders,templates}),{status:400});
 const y=fixture();await assert.rejects(()=>y.act('save_tap_settings',{templateId:'clean',steps:{},settings:y.raw().taskTemplates[0].settings}),{status:400});
});
test('crew and restricted managers cannot write TAP policy or invoke migration',async()=>{
 const x=fixture(1);await x.store.snapshot();x.raw().workplace.restrictions={manager:{tasks:false}};
 const persistence={read:async()=>structuredClone(x.raw()),save:async()=>assert.fail('unauthorized write')};
 for(const role of ['crew','manager']) {
  const store=new OperationsStore(null,()=>new Date('2026-09-30T02:00:00Z'),{actor:{id:'owner',name:'권한 테스트',role},persistence});
  for(const action of ['preview_tap_policy_migration','split_tap_policy','save_tap_settings'])await assert.rejects(()=>store.mutate('owner',{revision:x.raw().revision,action,templateId:'clean',operationId:'forbidden',assignmentScopeVersion:2,settings:x.raw().taskTemplates[0].settings}),{status:403});
 }
});
