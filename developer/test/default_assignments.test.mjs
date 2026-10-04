import { test } from 'node:test';
import assert from 'node:assert/strict';
import { mkdtemp, rm } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import path from 'node:path';
import { OperationsStore } from '../operations.mjs';
async function setup(t) {
  const dir = await mkdtemp(path.join(tmpdir(), 'default-crew-'));
  t.after(() => rm(dir, {recursive:true,force:true}));
  let now = new Date('2026-10-04T00:00:00Z');
  const store = new OperationsStore(path.join(dir,'state.json'), () => now);
  const act = async (action, body={}, actor='owner') => store.mutate(actor,{revision:(await store.snapshot(actor)).revision,action,...body});
  const days = Object.fromEntries([1,2,3,4,5,6,7].map(d => [d,d===7?[]:[{id:'open',name:'오픈',start:'09:00',end:'18:00',headcounts:{kitchen:1,hall:0,management:0},crewIds:{kitchen:['tapper-cook']}}]]));
  return {store,act,days,advance:date=>now=new Date(date)};
}
test('hours and crew save atomically, generate future defaults and extend without duplicate writes', async t => {
  const {store,act,days,advance}=await setup(t);
  let state = await act('save_workplace_hours',{days,defaultAssignmentsEnabled:true});
  const generated=state.staffShifts.filter(s=>s.defaultAssignmentKey);
  assert.ok(generated.length>60);
  assert.equal(generated.find(s=>s.date==='2026-10-05').tapperId,'tapper-cook');
  const stable=await store.snapshot('owner'); assert.equal(stable.revision,state.revision);
  assert.deepEqual(stable.staffShifts,state.staffShifts);
  advance('2026-10-12T00:00:00Z');
  state=await store.snapshot('owner');
  assert.ok(state.staffShifts.some(s=>s.date==='2027-01-08'));
  assert.equal(new Set(state.staffShifts.map(s=>s.id)).size,state.staffShifts.length);
});
test('reject invalid, duplicate, over-capacity and overnight overlapping defaults with no partial writes', async t => {
  const {store,act,days}=await setup(t);
  const before=await store.snapshot('owner');
  for (const ids of [['missing'],['tapper-crew'],['tapper-cook','tapper-cook']]) {
    const draft=structuredClone(days);draft[1][0].crewIds.kitchen=ids;
    await assert.rejects(act('save_workplace_hours',{days:draft,defaultAssignmentsEnabled:true}));
    assert.deepEqual((await store.snapshot('owner')).workplace,before.workplace);
  }
  const draft=structuredClone(days);draft[7]=[{...structuredClone(days[1][0]),start:'22:00',end:'10:00'}];
  await assert.rejects(act('save_workplace_hours',{days:draft,defaultAssignmentsEnabled:true}),/겹쳐요/);
  await assert.rejects(act('save_workplace_hours',{days,defaultAssignmentsEnabled:true},'manager'),{status:403});
  await act('save_workplace_hours',{days,defaultAssignmentsEnabled:true});
  await assert.rejects(store.mutate('owner',{revision:before.revision,action:'save_workplace_hours',days}),{status:409});
});
test('default changes preserve edited, deleted and requested dates, update untouched future rows',async t=>{
  const {store,act,days}=await setup(t);
  let state=await act('save_workplace_hours',{days,defaultAssignmentsEnabled:true});
  const at=date=>state.staffShifts.find(s=>s.defaultAssignmentKey&&s.date===date);
  const edited=at('2026-10-05'),deleted=at('2026-10-06'),pending=at('2026-10-07'),untouched=at('2026-10-08');
  await act('save_staff_shift',{...edited,start:'10:00'});
  await act('delete_staff_shift',{id:deleted.id});
  await act('request_shift_change',{shiftId:pending.id,kind:'leave',reason:'개인 일정'},'cook');
  for(const rows of Object.values(days)) for(const b of rows) b.end='19:00';
  state=await act('save_workplace_hours',{days,defaultAssignmentsEnabled:true});
  assert.equal(state.staffShifts.find(s=>s.id===edited.id).start,'10:00');
  assert.equal(state.staffShifts.find(s=>s.id===edited.id).end,'18:00');
  assert.ok(!state.staffShifts.some(s=>s.defaultAssignmentKey===deleted.defaultAssignmentKey));
  assert.equal(state.staffShifts.find(s=>s.id===pending.id).end,'18:00');
  assert.equal(state.staffShifts.find(s=>s.id===untouched.id).end,'19:00');
  assert.equal((await store.snapshot('owner')).defaultAssignmentOmissions,undefined);
});
test('monthly closing removes default occurrence and reopening restores from current defaults',async t=>{
  const {act,days}=await setup(t);
  await act('save_workplace_hours',{days,defaultAssignmentsEnabled:true});
  let state=await act('save_calendar_day',{date:'2026-10-05',mode:'closed'});
  assert.ok(!state.staffShifts.some(s=>s.date==='2026-10-05'));
  state=await act('save_calendar_day',{date:'2026-10-05',mode:'open',weekday:1});
  assert.equal(state.staffShifts.filter(s=>s.date==='2026-10-05').length,1);
  state=await act('save_calendar_day',{date:'2026-10-11',mode:'open',weekday:1});
  assert.equal(state.staffShifts.filter(s=>s.date==='2026-10-11').length,1);
});
test('night defaults use Korean business date and configured part times',async t=>{
  const {act,days}=await setup(t);
  for(const rows of Object.values(days)) for(const b of rows){b.start='22:00';b.end='05:00';b.partTimes={kitchen:{start:'01:00',end:'04:00'}};}
  const state=await act('save_workplace_hours',{days,businessDayStart:'06:00',defaultAssignmentsEnabled:true});
  const s=state.staffShifts.find(s=>s.defaultAssignmentKey?.startsWith('2026-10-05/'));
  assert.equal(s.date,'2026-10-06');assert.equal(s.businessDate,'2026-10-05');assert.equal(s.start,'01:00');
});
