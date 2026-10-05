import { test } from 'node:test';
import assert from 'node:assert/strict';
import { mkdtemp, rm } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import path from 'node:path';
import { OperationsStore } from '../operations.mjs';
async function setup(t) {
  const dir = await mkdtemp(path.join(tmpdir(), 'tap2work-workplace-'));
  t.after(() => rm(dir, { recursive:true, force:true }));
  const store = new OperationsStore(path.join(dir,'state.json'), () => new Date('2026-09-28T03:00:00Z'));
  const act = async (actor, action, values={}) => store.mutate(actor, {revision:(await store.snapshot(actor)).revision,action,...values});
  return {store,act};
}
test('parts preserve IDs, reject removal and stale drafts, and save staff selections', async t => {
  const {store,act}=await setup(t);
  const before=await store.snapshot('owner');
  const parts=before.workplace.parts;
  const next=await act('owner','save_workplace_parts',{parts:[...parts,{name:'포장'}]});
  assert.equal(next.workplace.parts.length,4);
  assert.equal(next.workplace.parts[0].id,parts[0].id);
  await assert.rejects(store.mutate('owner',{action:'save_workplace_parts',revision:before.revision,parts}),{status:409});
  await assert.rejects(act('owner','save_workplace_parts',{parts:parts.slice(1)}),{status:400});
  const saved=await act('owner','save_staff_profile',{tapperId:'tapper-crew',partIds:[next.workplace.parts[3].id],bands:['오픈']});
  assert.deepEqual(saved.tappers.find(t=>t.id==='tapper-crew').workProfile.bands,['오픈']);
  await assert.rejects(act('crew','save_staff_profile',{tapperId:'tapper-crew',partIds:[],bands:[]}),{status:403});
});
test('day bands keep stable metadata, allow overlaps and apply independently without changing assigned shifts', async t => {
  const {store,act}=await setup(t);
  const before=await store.snapshot('owner');
  const bands=[{name:'오픈',start:'09:00',end:'13:30'},{name:'마감',start:'13:30',end:'22:00'}];
  let next=await act('owner','save_workplace_day',{weekday:7,bands});
  assert.deepEqual(next.workplace.days['7'], bands.map((band,index) => ({...band,id:`legacy-band-7-${index}`,legacyIndex:index,headcounts:{}})));
  const savedIds = next.workplace.days['7'].map(b => b.id);
  assert.equal(next.workplace.days['1'],undefined);
  next=await act('owner','save_workplace_day',{weekday:7,bands,allDays:true});
  assert.equal(Object.keys(next.workplace.days).length,7);
  assert.deepEqual(next.staffShifts,before.staffShifts);
  assert.deepEqual(next.workplace.days['7'].map(b => b.id), savedIds);
  next=await act('owner','save_workplace_day',{weekday:1,bands:[bands[0],{...bands[1],start:'12:30'}]});
  assert.equal(next.workplace.days['1'][1].start,'12:30');
  next=await act('owner','save_workplace_day',{weekday:1,bands:[{name:'야간',start:'22:00',end:'06:00'}]});
  assert.equal(next.workplace.days['1'][0].end,'06:00');
  assert.deepEqual(next.staffShifts,before.staffShifts);
  await assert.rejects(act('owner','save_workplace_day',{weekday:1,bands:[{...bands[0],start:'09:15'}]}),{status:400});
  await assert.rejects(act('owner','save_workplace_day',{weekday:1,bands:[{...bands[0],end:'09:00'}]}),{status:400});
});
test('role restrictions are enforced on the server and completion projection; pay stays owner-only', async t => {
  const {store,act}=await setup(t);
  await act('owner','save_workplace_permissions',{role:'crew',permissions:{complete:false,stock:false}});
  const crew=await store.snapshot('crew');
  assert.equal(crew.workplace.restrictions,undefined);
  assert.equal(crew.labor,undefined);
  assert.ok(crew.tasks.every(t=>!t.canComplete));
  const task=crew.tasks.find(t=>t.kind==='routine'&&t.requiredRole==='all');
  await assert.rejects(act('crew','complete_task',{taskId:task.id}),{status:403});
  await assert.rejects(act('crew','save_workplace_permissions',{role:'crew',permissions:{complete:true}}),{status:403});
  await act('owner','save_workplace_permissions',{role:'crew',permissions:{complete:true}});
  assert.ok((await store.snapshot('crew')).tasks.some(t=>t.canComplete));
});
test('demo invitations rotate and revoke, remain owner-only, and cannot issue owner rank', async t => {
  const {store,act}=await setup(t);
  const first=await act('owner','create_demo_invite',{role:'hourly'});
  const second=await act('owner','create_demo_invite',{role:'hourly'});
  assert.notEqual(first.demoInvites[0].code,second.demoInvites[0].code);
  assert.equal(second.demoInvites.length,1);
  assert.equal(second.demoInvites[0].expiresAt,'2026-10-05T03:00:00.000Z');
  assert.equal((await store.snapshot('crew')).demoInvites,undefined);
  await assert.rejects(act('owner','create_demo_invite',{role:'owner'}),{status:400});
  const revoked=await act('owner','revoke_demo_invite',{role:'hourly'});
  assert.deepEqual(revoked.demoInvites,[]);
});
test('hours generate per-part weekday slots; date overrides, reset, revisions and assigned shifts are isolated', async t => {
  const {store,act}=await setup(t);
  let view=await act('owner','save_workplace_day',{weekday:1,bands:[{name:'오픈',start:'09:00',end:'13:00'},{name:'마감',start:'13:00',end:'22:00'}]});
  const templates=view.rosterTemplates.filter(t=>t.weekday===1);
  assert.equal(templates.length,6);
  const template=templates.find(t=>t.partId==='kitchen');
  const original=view.staffShifts;
  const change={date:'2026-09-28',partId:'kitchen',templateId:template.id,start:'10:00',end:'14:00'};
  view=await act('manager','save_roster_slot',change);
  assert.equal(view.rosterOverrides[0].start,'10:00');
  assert.deepEqual(view.staffShifts,original);
  assert.equal(view.rosterTemplates.find(t=>t.id===template.id).start,'09:00');
  await assert.rejects(act('crew','save_roster_slot',change),{status:403});
  await assert.rejects(act('owner','save_roster_slot',{...change,date:'2026-09-29'}),{status:409});
  await assert.rejects(act('owner','save_roster_slot',{...change,start:'09:15'}),{status:400});
  view=await act('owner','reset_roster_slot',change);
  assert.equal(view.rosterOverrides.length,0);
  await assert.rejects(store.mutate('owner',{...change,action:'save_roster_slot',revision:view.revision-1}),{status:409});
});
test('custom parts control assignment and task permissions independently from rank, including overnight overlap', async t => {
  const {store,act}=await setup(t);
  let view=await store.snapshot('owner');
  view=await act('owner','save_workplace_parts',{parts:[...view.workplace.parts,{name:'포장'}]});
  const partId=view.workplace.parts.at(-1).id;
  await act('owner','save_staff_profile',{tapperId:'tapper-crew',partIds:[partId],bands:[]});
  const shift={tapperId:'tapper-crew',partId,date:'2026-10-05',start:'22:00',end:'02:00'};
  view=await act('manager','save_staff_shift',shift);
  assert.equal(view.staffShifts.at(-1).partId,partId);
  await assert.rejects(act('manager','save_staff_shift',{...shift,date:'2026-10-06',start:'01:00',end:'03:00'}),{status:409});
  view=await act('manager','save_staff_shift',{...shift,id:view.staffShifts.at(-1).id,partId:'kitchen'});
  assert.equal(view.staffShifts.at(-1).partId,'kitchen');
  const id=view.staffShifts.at(-1).id;
  await assert.rejects(act('crew','delete_staff_shift',{id}),{status:403});
  view=await act('manager','delete_staff_shift',{id});
  assert.ok(!view.staffShifts.some(s=>s.id===id));
});
test('order board is opt-in, projected to crew, owner-only and never pretends a live connection', async t => {
  const {store,act}=await setup(t);
  const original=await store.snapshot('owner');
  assert.equal(original.orderBoardEnabled,false);
  await assert.rejects(act('manager','save_order_system',{enabled:true}),{status:403});
  await act('owner','save_order_system',{enabled:true});
  const crew=await store.snapshot('crew');
  assert.equal(crew.orderBoardEnabled,true);
  assert.equal(crew.store.profile.orderSystem.connectionStatus,'not_connected');
  const off=await act('owner','save_order_system',{enabled:false});
  assert.equal(off.orderBoardEnabled,false);
  assert.equal(off.tasks.length,original.tasks.length);
});
test('part task completion follows custom membership, not legacy role, and keeps pay private', async t => {
  const {store,act}=await setup(t);
  let view=await store.snapshot('owner');
  view=await act('owner','save_workplace_parts',{parts:[...view.workplace.parts,{name:'포장'}]});
  const partId=view.workplace.parts.at(-1).id;
  view=await act('owner','save_staff_profile',{tapperId:'tapper-crew',partIds:[partId],bands:[]});
  const template={id:'custom-part-check',title:'포장 확인',emoji:'📦',folderId:view.checklistFolders[0].id,slot:'준비',requiredRole:'cook',partId,zone:null,steps:[{id:'check',title:'수량 확인',manual:'수량을 확인해요.'}]};
  view=await act('owner','save_checklists',{folders:view.checklistFolders,templates:[...view.taskTemplates.filter(t=>!t.archivedAt),template]});
  const task=view.tasks.find(t=>t.templateId===template.id);
  assert.ok(task);
  const crew=await store.snapshot('crew');
  assert.equal(crew.tasks.find(t=>t.id===task.id).canComplete,true);
  assert.equal(crew.labor,undefined);
  assert.equal((await store.snapshot('cook')).tasks.find(t=>t.id===task.id).canComplete,false);
  await assert.rejects(act('cook','complete_step',{taskId:task.id,stepId:'check'}),{status:403});
  const done=await act('crew','complete_step',{taskId:task.id,stepId:'check'});
  assert.ok(done.tasks.find(t=>t.id===task.id).completedAt);
});

test('business breaks persist atomically, leave requirement seats unchanged, preserve assignments and reject invalid bounds', async t => {
  const {store,act}=await setup(t);
  const before=await store.snapshot('owner');
  const days=Object.fromEntries(Array.from({length:7},(_,i)=>[i+1,i===6?[]:[{id:'daytime',name:'전체',start:'06:00',end:'22:00',headcounts:{kitchen:2,hall:0,management:0}}]]));
  const saved=await act('owner','save_workplace_hours',{days,breaks:{1:{start:'15:00',end:'17:00'}}});
  assert.deepEqual(saved.workplace.breaks,{1:{start:'15:00',end:'17:00'}});
  const slots=saved.rosterTemplates.filter(s=>s.weekday===1);
  assert.equal(slots.length,2);
  assert.deepEqual(slots.map(s=>[s.start,s.end]),[['06:00','22:00'],['06:00','22:00']]);
  assert.equal(new Set(slots.map(s=>s.id)).size,2);
  assert.deepEqual(saved.staffShifts,before.staffShifts);
  for(const breaks of [{7:{start:'15:00',end:'17:00'}},{1:{start:'05:00',end:'17:00'}},{1:{start:'15:15',end:'17:00'}}]) {
    await assert.rejects(act('owner','save_workplace_hours',{days,breaks}),{status:400});
    assert.equal((await store.snapshot('owner')).revision,saved.revision);
  }
  await assert.rejects(act('crew','save_workplace_hours',{days,breaks:{}}),{status:403});
  await assert.rejects(store.mutate('owner',{action:'save_workplace_hours',revision:before.revision,days,breaks:{}}),{status:409});
  const restored=await act('owner','save_workplace_hours',{days,breaks:{}});
  assert.equal(restored.rosterTemplates.filter(s=>s.weekday===1).length,2);
});

test('crew registration can omit assignment; editing preserves existing work profile', async t => {
  const {store,act}=await setup(t);
  const values={nickname:'신규 크루',rank:'crew',employmentType:'시간알바',hourlyWon:10320,payPeriod:'monthly',kakaoUrl:'',phone:''};
  const added=await act('owner','save_tapper',values);
  const person=added.tappers.find(p=>p.nickname===values.nickname);
  assert.deepEqual(person.workProfile,{partIds:[],bands:[]});
  const before=await store.snapshot('owner');
  const original=before.tappers.find(p=>p.id==='tapper-crew');
  const updated=await act('owner','save_tapper',{...values,id:original.id});
  assert.deepEqual(updated.tappers.find(p=>p.id===original.id).workProfile,original.workProfile);
  await assert.rejects(act('crew','save_tapper',values),{status:403});
  await assert.rejects(act('owner','save_tapper',{...values,duties:['invalid']}),{status:400});
});

test('automatic attendance preferences validate method and never activate or create clock events', async t => {
  const {store,act}=await setup(t);
  const before=await store.snapshot('owner');
  for (const method of ['location','wifi']) {
    const saved=await act('owner','save_attendance_preferences',{method,enabled:true,status:'active'});
    assert.deepEqual(saved.workplace.attendancePreferences,{method,status:'not_connected'});
    assert.deepEqual(saved.attendance,before.attendance);
    assert.deepEqual(saved.staffShifts,before.staffShifts);
  }
  await assert.rejects(act('crew','save_attendance_preferences',{method:'wifi'}),{status:403});
  await assert.rejects(act('owner','save_attendance_preferences',{method:'invalid'}),{status:400});
  await assert.rejects(store.mutate('owner',{revision:before.revision,action:'save_attendance_preferences',method:'location'}),{status:409});
});

test('fine assignments allow other crews, any active part and explicit preopening or overnight dates', async t => {
  const {store,act}=await setup(t);
  const initial=await store.snapshot('owner');
  const profiles=structuredClone(initial.tappers.map(p=>p.workProfile));
  for (const [index, tapperId] of ['tapper-crew','tapper-cook','tapper-manager','tapper-sample'].entries()) {
    await act('manager','save_staff_shift',{tapperId,partId:'kitchen',date:'2026-10-05',scheduleDate:'2026-10-05',dayOffset:0,start:'05:00',end:'08:00'});
  }
  let view=await store.snapshot('owner');
  const rows=view.staffShifts.filter(s=>s.scheduleDate==='2026-10-05');
  assert.equal(rows.length,4);
  assert.ok(rows.every(s=>s.date==='2026-10-05'));
  assert.deepEqual(view.tappers.map(p=>p.workProfile),profiles);
  await act('manager','save_staff_shift',{tapperId:'tapper-crew',partId:'hall',date:'2026-10-05',scheduleDate:'2026-10-05',dayOffset:1,start:'01:00',end:'03:00'});
  view=await store.snapshot('owner');
  assert.equal(view.staffShifts.at(-1).date,'2026-10-06');
  await assert.rejects(act('manager','save_staff_shift',{tapperId:'tapper-crew',partId:'hall',date:'2026-10-05',scheduleDate:'2026-10-05',dayOffset:0,start:'06:00',end:'09:00'}),{status:409});
  await assert.rejects(act('crew','save_staff_shift',{tapperId:'tapper-crew',partId:'hall',date:'2026-10-07',start:'06:00',end:'09:00'}),{status:403});
  await assert.rejects(store.mutate('owner',{action:'save_staff_shift',revision:initial.revision,tapperId:'tapper-crew',partId:'hall',date:'2026-10-07',start:'06:00',end:'09:00'}),{status:409});
});
