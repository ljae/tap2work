import { test } from 'node:test';
import assert from 'node:assert/strict';
import { OperationsStore, emptyOperations } from '../operations.mjs';
import { defaultWorkplace } from '../parts.mjs';
import { taskSettings, stepSettings } from '../task_settings.mjs';

const scheduled = (...ids) => ({mode:'scheduled',timeBandIds:ids,partId:'kitchen',crewIds:[]});
function fixture(assignment = scheduled('a','b')) {
  let now = new Date('2026-09-30T00:00:00Z');
  let state = emptyOperations(now,'owner');
  state.workplace = defaultWorkplace();
  state.workplace.days[3] = [{id:'a',custom:true,name:'오전',start:'10:00',end:'14:00',headcounts:{kitchen:2}}, {id:'b',custom:true,name:'지원',start:'12:00',end:'16:00',headcounts:{kitchen:1}}];
  for (const [id,part] of [['one','kitchen'],['two','kitchen'],['support','kitchen'],['hall','hall']]) state.tappers.push({id,actorId:id,nickname:id,rank:'crew',active:true,duties:[],workProfile:{partIds:[part],bands:[]}});
  state.staffShifts = [{id:'s1',tapperId:'one',date:state.day,partId:'kitchen',timeBandId:'a',start:'10:00',end:'14:00',status:'planned'}, {id:'s2',tapperId:'two',date:state.day,partId:'kitchen',timeBandId:'b',start:'12:00',end:'16:00',status:'planned'}];
  state.taskTemplates = [{id:'clean',version:1,title:'청소',folderId:'general',slot:'준비',requiredRole:'all',partId:'kitchen',settings:{...taskSettings({}),...(assignment ? {assignment} : {})},steps:[{id:'wash',title:'세척',manual:'씻어요'},{id:'wipe',title:'닦기',manual:'닦아요'}]}];
  const store = id => new OperationsStore(null,()=>now,{actor:{id,name:id,role:id === 'owner' ? 'owner' : id === 'manager' ? 'manager' : 'crew'},persistence:{read:async()=>structuredClone(state),save:async(next,rev)=>{assert.equal(rev,state.revision);state=structuredClone(next);}}});
  const view = (id='owner') => store(id).snapshot();
  const act = async(id,action,values={}) => {const v=await view(id);return store(id).mutate(id,{revision:v.revision,action,...values});};
  const save = async assignment => act('owner','save_tap_settings',{templateId:'clean',settings:{...taskSettings(state.taskTemplates[0]),assignment},steps:state.taskTemplates[0].steps.map(s=>({id:s.id,settings:stepSettings(s)}))});
  return {view,act,save,raw:()=>state, next:date=>{now=new Date(date);}};
}
const tasks = v => v.tasks.filter(t=>t.templateId==='clean');
test('daily band identity generates shared occurrences, explicit ID beats overlap, fallback overlaps, read idempotency',async()=>{
 const x=fixture(); let v=await x.view(); assert.equal(tasks(v).length,2);
 assert.deepEqual(tasks(v).map(t=>t.assignmentView.assignees.map(p=>p.id)),[['one'],['two']]);
 assert.equal(tasks(v)[0].assignmentView.timeBandName,'오전');
 assert.equal(tasks(await x.view('one'))[0].assignmentView.isMine,true);
 const rev=v.revision;assert.equal((await x.view()).revision,rev);
 delete x.raw().staffShifts[0].timeBandId;
 v=await x.view();assert.deepEqual(tasks(v)[1].assignmentView.assignees.map(p=>p.id),['one','two']);
 assert.equal(x.raw().tasks[0].assignmentView,undefined);
 x.next('2026-09-30T15:01:00Z');assert.equal(tasks(await x.view()).length,0); // Thursday has no selected bands.
 x.raw().workplace.days[4]=structuredClone(x.raw().workplace.days[3]); assert.equal(tasks(await x.view()).length,2);
});
test('same eligible part support can complete shared Task; wrong part denied; roles and restrictions preserved',async()=>{
 const x=fixture();const task=tasks(await x.view('support'))[0];assert.equal(task.steps[0].canComplete,true);assert.equal(task.assignmentView.isMine,false);
 await assert.rejects(()=>x.act('hall','complete_step',{taskId:task.id,stepId:'wash'}),{status:403});
 let v=await x.act('support','complete_step',{taskId:task.id,stepId:'wash'});assert.equal(tasks(v)[0].steps[0].completedBy.id,'support');
 await assert.rejects(()=>x.act('one','complete_step',{taskId:task.id,stepId:'wash'}),{status:409});
 x.raw().workplace.restrictions.manager={complete:false};await assert.rejects(()=>x.act('manager','complete_task',{taskId:task.id}),{status:403});
 v=await x.act('owner','complete_task',{taskId:task.id});assert.ok(tasks(v)[0].completedAt);assert.equal(tasks(v)[1].completedAt,null);
});
test('anyone uses today active scheduled crew only, OFF and leave removed; forged projection ignored',async()=>{
 const x=fixture({mode:'anyone'});let t=tasks(await x.view())[0];assert.deepEqual(t.assignmentView.assignees.map(p=>p.id),['one','two']);
 await assert.rejects(()=>x.act('support','complete_step',{taskId:t.id,stepId:'wash',assignmentView:{assignees:[{id:'support'}]}}),{status:403});
 x.raw().staffShifts[0].status='OFF';x.raw().staffShifts[1].status='leave';t=tasks(await x.view('one'))[0];assert.equal(t.steps[0].canComplete,false);assert.equal(t.assignmentView.unassigned,true);
 x.raw().staffShifts[0].status='planned';await x.act('one','complete_step',{taskId:t.id,stepId:'wash'});
});
test('approved leave and replacement update unfinished steps but preserve completed snapshots and history',async()=>{
 const x=fixture();let t=tasks(await x.view())[0];await x.act('one','complete_step',{taskId:t.id,stepId:'wash'});
 const completed=structuredClone(x.raw().tasks.find(r=>r.id===t.id).steps[0]);
 await x.act('one','request_shift_change',{shiftId:'s1',kind:'leave',reason:'휴가'});
 await x.act('owner','review_shift_change',{id:x.raw().shiftChangeRequests[0].id,decision:'approved'});
 t=tasks(await x.view())[0];assert.equal(t.steps[0].assignmentView.assignees[0].id,'one');assert.deepEqual(t.steps[1].assignmentView.assignees,[]);
 await x.act('owner','review_shift_change',{id:x.raw().shiftChangeRequests[0].id,decision:'assign_replacement',vacancyId:x.raw().shiftChangeRequests[0].vacancies[0].id,tapperId:'support'});
 t=tasks(await x.view())[0];assert.equal(t.steps[1].assignmentView.assignees[0].id,'support');assert.deepEqual(x.raw().tasks.find(r=>r.id===t.id).steps[0],completed);
 await x.act('support','complete_step',{taskId:t.id,stepId:'wipe'});const done=structuredClone(x.raw().tasks.find(r=>r.id===t.id));
 x.raw().tappers.find(p=>p.id==='support').active=false;await x.view();assert.deepEqual(x.raw().tasks.find(r=>r.id===t.id),done);
 x.next('2026-10-01T01:00:00Z');await x.view();assert.deepEqual(x.raw().tasks.find(r=>r.id===t.id),done);
});
test('assignment save regenerates today unstarted, preserves started, validates IDs and supports Task overrides',async()=>{
 const x=fixture(null);const old=tasks(await x.view())[0];assert.equal(old.assignmentView,undefined);
 let v=await x.save(scheduled('a','b'));assert.equal(tasks(v).length,2);assert.ok(x.raw().tasks.find(t=>t.id===old.id).archivedAt);
 let t=tasks(v)[0];await x.act('one','complete_step',{taskId:t.id,stepId:'wash'});
 v=await x.save({mode:'crew',crewIds:['hall']});assert.ok(tasks(v).some(row=>row.id===t.id));
 await assert.rejects(()=>x.save(scheduled('missing')),{status:400});
 const y=fixture({mode:'anyone'});y.raw().taskTemplates[0].steps[0].settings={assignment:{mode:'crew',crewIds:['hall']}};
 t=tasks(await y.view('hall'))[0];assert.equal(t.steps[0].canComplete,true);assert.equal(t.steps[1].canComplete,false);
 assert.deepEqual(new Set(t.assignmentView.assignees.map(p=>p.id)),new Set(['hall','one','two']));
 await y.act('hall','complete_step',{taskId:t.id,stepId:'wash'});
 await assert.rejects(()=>y.act('hall','complete_task',{taskId:t.id}),{status:403});
 const z=fixture({mode:'crew',crewIds:['one']});const zt=tasks(await z.view('support'))[0];assert.equal(zt.steps[0].canComplete,false);
 await assert.rejects(()=>z.act('support','complete_step',{taskId:zt.id,stepId:'wash'}),{status:403});
 z.raw().tappers.find(p=>p.id==='one').active=false;const unmatched=tasks(await z.view())[0];assert.equal(unmatched.assignmentView.mode,'crew');assert.equal(unmatched.assignmentView.unassigned,true);
});

test('approved partial OFF projects effective split intervals; pending request does not change assignment',async()=>{
 const x=fixture();const t=tasks(await x.view())[0];
 await x.act('one','request_shift_change',{shiftId:'s1',kind:'partial_off',start:'11:00',end:'12:00',reason:'자리 비움'});
 assert.deepEqual(tasks(await x.view())[0].assignmentView.assignees.map(p=>[p.start,p.end]),[['10:00','14:00']]);
 await x.act('owner','review_shift_change',{id:x.raw().shiftChangeRequests[0].id,decision:'approved'});
 assert.deepEqual(tasks(await x.view())[0].assignmentView.assignees.map(p=>[p.start,p.end]),[['10:00','11:00'],['12:00','14:00']]);
 assert.equal(tasks(await x.view())[0].id,t.id);
});
test('legacy eligibility stays available without actual assignees; scheduled step overrides use distinct bands',async()=>{
 const x=fixture(null);let t=tasks(await x.view('support'))[0];assert.equal(t.steps[0].canComplete,true);assert.equal(t.steps[0].assignmentView,undefined);assert.equal(t.assignmentView,undefined);
 await x.act('support','complete_task',{taskId:t.id});
 const y=fixture(scheduled('a'));y.raw().taskTemplates[0].steps[1].settings={assignment:scheduled('b')};
 const rows=tasks(await y.view());assert.deepEqual(rows.map(t=>t.steps.map(s=>s.id)),[['wash'],['wipe']]);
 assert.deepEqual(rows.map(t=>t.assignmentView.assignees.map(s=>s.id)),[['one'],['two']]);
});
test('disabled and weekly recurrence suppress daily generation; overnight linked segments retain their band',async()=>{
 const x=fixture();x.raw().taskTemplates[0].settings.enabled=false;assert.equal(tasks(await x.view()).length,0);
 x.raw().taskTemplates[0].settings.enabled=true;x.raw().taskTemplates[0].settings.recurrence={mode:'weekly',weekdays:[4]};assert.equal(tasks(await x.view()).length,0);
 x.raw().taskTemplates[0].settings.recurrence={mode:'daily',weekdays:[]};
 x.raw().workplace.days[3][0].start='22:00';x.raw().workplace.days[3][0].end='03:00';
 Object.assign(x.raw().staffShifts[0],{date:'2026-10-01',start:'01:00',end:'03:00'});
 assert.deepEqual(tasks(await x.view())[0].assignmentView.assignees.map(p=>p.id),['one']);
});

test('clips handover to immutable occurrence window and survives band deletion; mixed legacy parent exposes actual override',async()=>{
 const x=fixture(scheduled('a'));Object.assign(x.raw().staffShifts[0],{start:'09:00',end:'18:00'});
 let t=tasks(await x.view())[0];assert.deepEqual(t.assignmentView.assignees.map(p=>[p.start,p.end,p.startDate,p.endDate]),[['10:00','14:00','2026-09-30','2026-09-30']]);
 x.raw().workplace.days[3]=[];t=tasks(await x.view())[0];assert.equal(t.assignmentView.timeBandName,'오전');assert.equal(t.assignmentView.assignees[0].end,'14:00');
 assert.deepEqual(x.raw().tasks.find(r=>r.id===t.id).assignmentWindow,{id:'a',name:'오전',date:'2026-09-30',start:'10:00',end:'14:00'});
 const y=fixture(null);y.raw().taskTemplates[0].steps[0].settings={assignment:{mode:'crew',crewIds:['hall']}};
 t=tasks(await y.view('hall'))[0];assert.equal(t.assignmentView.mode,'mixed');assert.equal(t.assignmentView.isMine,true);assert.equal(t.assignmentView.assignees[0].id,'hall');assert.equal(t.steps[1].assignmentView,undefined);
});
test('anyone uses KST calendar-day overlap including previous night; midnight endpoints carry dates',async()=>{
 const x=fixture({mode:'anyone'});Object.assign(x.raw().staffShifts[0],{date:'2026-09-29',start:'22:00',end:'03:00'});Object.assign(x.raw().staffShifts[1],{start:'22:00',end:'03:00'});
 const t=tasks(await x.view('one'))[0];assert.equal(t.steps[0].canComplete,true);
 assert.deepEqual(t.assignmentView.assignees.map(p=>[p.start,p.end,p.startDate,p.endDate]),[['00:00','03:00','2026-09-30','2026-09-30'],['22:00','00:00','2026-09-30','2026-10-01']]);
 await x.act('one','complete_step',{taskId:t.id,stepId:'wash'});
});

test('scheduled settings reject nonexistent/zero-headcount part-band pairs atomically; only legacy defaults to one',async()=>{
 const x=fixture(null);await x.view();x.raw().workplace.days[3][1].headcounts.kitchen=0;
 const before=structuredClone(x.raw().taskTemplates);
 await assert.rejects(()=>x.save(scheduled('a','b')),{status:400});assert.deepEqual(x.raw().taskTemplates,before);
 await assert.rejects(()=>x.save({...scheduled('a'),partId:'missing'}),{status:400});
 delete x.raw().workplace.days[3][0].headcounts.kitchen;await assert.rejects(()=>x.save(scheduled('a')),{status:400});
 x.raw().workplace.days[3][0].custom=false;await x.save(scheduled('a'));
 const y=fixture(null);await y.view();y.raw().workplace.days[3][1].headcounts.kitchen=0;
 await assert.rejects(()=>y.act('owner','save_tap_settings',{templateId:'clean',settings:taskSettings(y.raw().taskTemplates[0]),steps:y.raw().taskTemplates[0].steps.map(s=>({id:s.id,settings:{...stepSettings(s),assignment:scheduled('b')}}))}),{status:400});
});

test('explicit legacy/inherit defaults do not regenerate old work; partial legacy blocks new bands until next KST day',async()=>{
 const x=fixture(null);const old=tasks(await x.view())[0];
 let view=await x.act('owner','save_tap_settings',{templateId:'clean',settings:{...taskSettings(x.raw().taskTemplates[0]),allowBulkComplete:false,assignment:{mode:'legacy',timeBandIds:[],crewIds:[],partId:null}},steps:x.raw().taskTemplates[0].steps.map(s=>({id:s.id,settings:{...stepSettings(s),assignment:{mode:'inherit'}}}))});
 assert.deepEqual(tasks(view).map(t=>t.id),[old.id]);assert.equal(x.raw().tasks.find(t=>t.id===old.id).archivedAt,undefined);
 await x.act('support','complete_step',{taskId:old.id,stepId:'wash'});
 view=await x.save(scheduled('a','b'));assert.deepEqual(tasks(view).map(t=>t.id),[old.id]);
 assert.equal(tasks(view)[0].steps[0].completedBy.id,'support');assert.equal(tasks(view)[0].assignmentView,undefined);
 assert.deepEqual(tasks(await x.view()).map(t=>t.id),[old.id]);
 x.raw().workplace.days[4]=structuredClone(x.raw().workplace.days[3]);x.next('2026-09-30T15:01:00Z');
 assert.equal(tasks(await x.view()).length,2);assert.ok(x.raw().tasks.find(t=>t.id===old.id).steps[0].completedAt);
});

test('advertised implicit profile-hour bands validate and generate through shared stable-band helper',async()=>{
 const x=fixture(null);x.raw().workplace.days={};x.raw().store.profile={hours:{weekdays:[1,2,3,4,5],opening:'09:00',closing:'18:00'}};
 const advertised=(await x.view()).workplace.days[3][0];assert.ok(advertised.id);
 let view=await x.save(scheduled(advertised.id));let t=tasks(view)[0];assert.equal(t.timeBandId,advertised.id);assert.equal(t.assignmentView.timeBandName,'전체');
 assert.equal(t.assignmentWindow.start,'09:00');assert.equal(t.assignmentWindow.end,'18:00');
 assert.equal(view.workplace.days[4][0].id,advertised.id);
 x.next('2026-09-30T15:01:00Z');view=await x.view();assert.equal(tasks(view).length,1);assert.equal(tasks(view)[0].timeBandId,advertised.id);
});
