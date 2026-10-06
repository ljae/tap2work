import { test } from 'node:test';
import assert from 'node:assert/strict';
import { mkdtemp, rm } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import path from 'node:path';
import { OperationsStore } from '../operations.mjs';
import { refreshDefaultAssignments } from '../default_assignments.mjs';
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
  for (const ids of [['missing'],['tapper-cook','tapper-cook']]) {
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
test('default changes reset fine edits and omissions while preserving pending requests',async t=>{
  const {store,act,days}=await setup(t);
  let state=await act('save_workplace_hours',{days,defaultAssignmentsEnabled:true});
  const at=date=>state.staffShifts.find(s=>s.defaultAssignmentKey&&s.date===date);
  const edited=at('2026-10-05'),deleted=at('2026-10-06'),pending=at('2026-10-07'),untouched=at('2026-10-08');
  await act('save_staff_shift',{...edited,start:'10:00'});
  await act('delete_staff_shift',{id:deleted.id});
  await act('request_shift_change',{shiftId:pending.id,kind:'leave',reason:'개인 일정'},'cook');
  for(const rows of Object.values(days)) for(const b of rows) b.end='19:00';
  state=await act('save_workplace_hours',{days,defaultAssignmentsEnabled:true});
  assert.equal(state.staffShifts.find(s=>s.id===edited.id).start,'09:00');
  assert.equal(state.staffShifts.find(s=>s.id===edited.id).end,'19:00');
  assert.ok(state.staffShifts.some(s=>s.defaultAssignmentKey===deleted.defaultAssignmentKey));
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

 test('staffing establishes parts without editing the legacy crew registration profile',async t=>{
  const {store,act,days}=await setup(t);
  const before=(await store.snapshot('owner')).tappers.find(p=>p.id==='tapper-crew').workProfile;
  for(const rows of Object.values(days)) for(const b of rows) b.crewIds.kitchen=['tapper-crew'];
  const state=await act('save_workplace_hours',{days,defaultAssignmentsEnabled:true});
  const shift=state.staffShifts.find(s=>s.defaultAssignmentKey && s.date==='2026-10-05');
  assert.equal(shift.tapperId,'tapper-crew');
  assert.equal(shift.partId,'kitchen');
  await act('save_staff_shift',{...shift,start:'10:00'});
  assert.deepEqual((await store.snapshot('owner')).tappers.find(p=>p.id==='tapper-crew').workProfile,before);
});

test('reapplying selected weekdays resets existing fine edits even when defaults are unchanged',async t=>{
  const {store,act,days}=await setup(t);
  let state=await act('save_workplace_hours',{days,defaultAssignmentsEnabled:true});
  const mon=state.staffShifts.find(s=>s.defaultAssignmentKey&&s.date==='2026-10-05');
  const tue=state.staffShifts.find(s=>s.defaultAssignmentKey&&s.date==='2026-10-06');
  await act('save_staff_shift',{...mon,start:'10:00'});
  await act('save_staff_shift',{...tue,start:'11:00'});
  assert.equal((await store.snapshot('owner')).staffShifts.find(s=>s.id===mon.id).start,'10:00');
  const reordered=JSON.parse(JSON.stringify(days,(_,value)=> value && typeof value==='object' && !Array.isArray(value) ? Object.fromEntries(Object.entries(value).reverse()) : value));
  state=await act('save_workplace_hours',{days:reordered,defaultAssignmentsEnabled:true,resetScheduleWeekdays:[1]});
  assert.equal(state.staffShifts.find(s=>s.id===mon.id).start,'09:00');
  assert.equal(state.staffShifts.find(s=>s.id===tue.id).start,'11:00');
  assert.equal(state.operationEditHistory,undefined);
  await assert.rejects(act('save_workplace_hours',{days,defaultAssignmentsEnabled:true,resetScheduleWeekdays:[8]}),{status:400});
});

test('today refresh replaces legacy planned crew despite elapsed scheduled start; clock history and past survive',async t=>{
  const {store,act,days,advance}=await setup(t);
  let state=await store.snapshot('owner');
  const original=state.staffShifts.find(s=>s.tapperId==='tapper-cook');
  days[7]=[{...structuredClone(days[1][0]),start:'08:00',crewIds:{kitchen:['tapper-crew']}}];
  state=await act('save_workplace_hours',{days,defaultAssignmentsEnabled:true});
  assert.ok(!state.staffShifts.some(s=>s.id===original.id));
  assert.equal(state.staffShifts.find(s=>s.defaultAssignmentKey?.startsWith('2026-10-04/')).tapperId,'tapper-crew');
  await act('clock_in',{},'crew');
  const recorded=await store.snapshot('owner');
  advance('2026-10-05T05:00:00Z');
  state=await act('save_workplace_hours',{days,defaultAssignmentsEnabled:true,resetScheduleWeekdays:[1,7]});
  assert.deepEqual(state.attendance,recorded.attendance);
  assert.deepEqual(state.staffShifts.filter(s=>s.date==='2026-10-04'),recorded.staffShifts.filter(s=>s.date==='2026-10-04'));
  await act('clock_in',{},'cook');
  const active=await store.snapshot('owner');
  const current=active.staffShifts.find(s=>s.date==='2026-10-05'&&s.tapperId==='tapper-cook');
  days[1][0].crewIds.kitchen=['tapper-crew'];
  state=await act('save_workplace_hours',{days,defaultAssignmentsEnabled:true});
  assert.deepEqual(state.staffShifts.find(s=>s.id===current.id),current);
  assert.deepEqual(state.attendance,active.attendance);
});

test('voided attendance does not suppress regenerated plans and unchanged reapply adds no archive',async t=>{
  const {act,days}=await setup(t);
  const state=await act('save_workplace_hours',{days,defaultAssignmentsEnabled:true});
  state.attendance=[{tapperId:'tapper-cook',type:'clock_in',at:'2026-10-05T01:00:00Z',voidedAt:'2026-10-05T02:00:00Z'}];
  state.operationEditHistory=[];
  const before=structuredClone(state);
  refreshDefaultAssignments(state,before,new Date('2026-10-04T00:00:00Z'),[1],{id:'owner'});
  assert.ok(state.staffShifts.some(s=>s.defaultAssignmentKey?.startsWith('2026-10-05/')));
  assert.equal(state.operationEditHistory.length,0);
  assert.deepEqual(state.attendance,before.attendance);
});

test('staffing save without weekday scope resets unchanged defaults for older clients',async t=>{
  const {act,days}=await setup(t);
  let state=await act('save_workplace_hours',{days,defaultAssignmentsEnabled:true});
  const original=state.staffShifts.find(s=>s.defaultAssignmentKey&&s.date==='2026-10-05');
  await act('save_staff_shift',{...original,start:'11:00'});
  state=await act('save_workplace_hours',{days,defaultAssignmentsEnabled:true});
  assert.equal(state.staffShifts.find(s=>s.id===original.id).start,'09:00');
});

test('night staffing refresh includes the current business date after midnight',async t=>{
  const {act,days,advance}=await setup(t);
  for(const rows of Object.values(days)) for(const b of rows){b.start='22:00';b.end='05:00';}
  let state=await act('save_workplace_hours',{days,businessDayStart:'22:00',defaultAssignmentsEnabled:true});
  const original=state.staffShifts.find(s=>s.defaultAssignmentKey?.startsWith('2026-10-05/'));
  await act('save_staff_shift',{...original,end:'04:00'});
  advance('2026-10-05T16:00:00Z'); // Tuesday 01:00 KST, still Monday's business day.
  state=await act('save_workplace_hours',{days,businessDayStart:'22:00',defaultAssignmentsEnabled:true,resetScheduleWeekdays:[1]});
  assert.equal(state.day,'2026-10-05');
  assert.equal(state.staffShifts.find(s=>s.id===original.id).end,'05:00');
});

test('recurring defaults have no expiry; distant reads and saves reset all future exceptions',async t=>{
  const {store,act,days}=await setup(t);
  await act('save_workplace_hours',{days,defaultAssignmentsEnabled:true});
  const range={scheduleFrom:'2028-10-02',scheduleTo:'2028-10-08'};
  let state=await store.snapshot('owner',range);
  const far=state.staffShifts.find(s=>s.defaultAssignmentKey?.startsWith('2028-10-02/'));
  const deleted=state.staffShifts.find(s=>s.defaultAssignmentKey?.startsWith('2028-10-03/'));
  assert.equal(far.start,'09:00');
  await act('save_staff_shift',{...far,start:'11:00'});
  await act('delete_staff_shift',{id:deleted.id});
  state=await store.snapshot('owner',range);
  assert.equal(state.staffShifts.find(s=>s.id===far.id).start,'11:00');
  assert.ok(!state.staffShifts.some(s=>s.defaultAssignmentKey===deleted.defaultAssignmentKey));
  const stable=await store.snapshot('owner',range);
  assert.equal(stable.revision,state.revision);
  assert.deepEqual(stable.staffShifts,state.staffShifts);
  state=await act('save_workplace_hours',{days,defaultAssignmentsEnabled:true,resetScheduleWeekdays:[1,2]});
  assert.equal(state.staffShifts.find(s=>s.id===far.id).start,'09:00');
  assert.ok(state.staffShifts.some(s=>s.defaultAssignmentKey===deleted.defaultAssignmentKey));
  // Subsequent normal reads must retain distant generated rows and their IDs.
  assert.deepEqual((await store.snapshot('owner')).staffShifts,state.staffShifts);
  const latest=structuredClone(days);latest[1][0].end='20:00';
  state=await act('save_workplace_hours',{days:latest,defaultAssignmentsEnabled:true});
  assert.equal(state.staffShifts.find(s=>s.id===far.id).end,'20:00');
  assert.throws(()=>store.snapshot('owner',{scheduleFrom:'2028-02-30',scheduleTo:'2028-03-01'}),{status:400});
  assert.throws(()=>store.snapshot('owner',{scheduleFrom:'2028-01-01',scheduleTo:'2028-12-31'}),{status:400});
});


test('Mon-Sat 19:00 to next-day 10:00 persists hours and overnight crew on reopen',async t=>{
  const {store,act,days}=await setup(t);
  for(const rows of Object.values(days)) if(rows.length) {
    const base=structuredClone(rows[0]);
    rows.splice(0,rows.length,
      {...base,id:'evening',start:'19:00',end:'02:30'},
      {...base,id:'night',start:'02:30',end:'10:00'});
  }
  const state=await act('save_workplace_hours',{days,businessDayStart:'19:00',defaultAssignmentsEnabled:true,resetScheduleWeekdays:[1,2,3,4,5,6]});
  for(const date of ['2026-10-05','2026-10-06','2026-10-07','2026-10-08','2026-10-09','2026-10-10']) {
    const shifts=state.staffShifts.filter(s=>s.defaultAssignmentKey?.startsWith(date+'/'));
    assert.equal(shifts.length,2);
    assert.deepEqual(shifts.map(s=>[s.start,s.end]),[['19:00','02:30'],['02:30','10:00']]);
    assert.equal(shifts[0].date,date);
    assert.ok(shifts[1].date>date);
    assert.ok(shifts.every(s=>s.businessDate===date));
  }
  assert.deepEqual(state.workplace.days[7],[]);
  const reopened=await store.snapshot('owner');
  assert.deepEqual(reopened.workplace.days,state.workplace.days);
  assert.deepEqual(reopened.staffShifts,state.staffShifts);
});
