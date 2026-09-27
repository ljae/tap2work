import test from 'node:test';
import assert from 'node:assert/strict';
import { laborEstimate } from '../labor.mjs';
import { ensureStaff, mutateStaff, staffView } from '../staff.mjs';
const week = '2026-09-21';
const review = { scope: 'standard', size: 'fivePlus', averageWeeklyMinutes: 2400, restMinutes: 480, attendance: 'met', holidaysConfirmed: true, holidayDates: [], otherPaidHolidayMinutes: 0, ordinaryHourlyWon: 12000 };
const segment = (day,start,end) => ({start:`2026-09-${day}T${start}:00+09:00`,end:`2026-09-${day}T${end}:00+09:00`});
test('40h, weekly rest, no daily/weekly overtime double count', () => {
  const rows = [21,22,23,24,25].map(d=>segment(d,'09:00','18:00'));
  const r = laborEstimate(rows,review,week,12000);
  assert.equal(r.workedMinutes,2700); assert.equal(r.overtimeMinutes,300);
  assert.equal(r.extensionWon,30000); assert.equal(r.weeklyRestWon,96000); assert.equal(r.totalWon,666000);
});
test('holiday 8h threshold plus night, no duplicate extension',()=>{
  const r=laborEstimate([segment(21,'14:00','23:00')],{...review,holidayDates:['2026-09-21']},week,12000);
  assert.equal(r.holidayWon,60000); assert.equal(r.extensionWon,0); assert.equal(r.nightWon,6000);
});
test('under five keeps weekly rest and removes statutory premiums',()=>{
  const r=laborEstimate([segment(21,'14:00','23:00')],{...review,size:'under5',holidayDates:['2026-09-21']},week,12000);
  assert.equal(r.totalWon,204000); assert.equal(r.nightWon,0); assert.equal(r.holidayWon,0);
});
test('15h eligibility, attendance, unknown conditions and minimum wage alert',()=>{
  assert.equal(laborEstimate([],{...review,averageWeeklyMinutes:899},week,12000).weeklyRestWon,0);
  assert.equal(laborEstimate([],{...review,averageWeeklyMinutes:900,restMinutes:180},week,12000).weeklyRestWon,36000);
  assert.equal(laborEstimate([],{...review,attendance:'unmet'},week,12000).weeklyRestWon,0);
  assert.equal(laborEstimate([],{...review,attendance:'unknown'},week,12000).totalWon,null);
  assert.equal(laborEstimate([],null,week,10000).totalWon,null);
  assert.ok(laborEstimate([],review,week,10000).alerts.some(s=>s.includes('10,320')));
});
test('short-time contractual excess, unpaid breaks and overlapping records',()=>{
  const r=laborEstimate([segment(21,'09:00','12:00'),segment(21,'13:00','16:00'),segment(21,'13:00','16:00')],{...review,shortTime:true,dailyContractMinutes:[240,240,240,240,240,0,0]},week,12000);
  assert.equal(r.workedMinutes,360);assert.equal(r.overtimeMinutes,120);assert.equal(r.extensionWon,12000);
});
test('overnight continuous work preserves daily threshold; week boundary holds total',()=>{
  const row={start:'2026-09-21T20:00:00+09:00',end:'2026-09-22T06:00:00+09:00'};
  const r=laborEstimate([row],review,week,12000);
  assert.equal(r.overtimeMinutes,120);assert.equal(r.nightMinutes,480);
  assert.equal(laborEstimate([{start:'2026-09-21T02:00:00+09:00',end:'2026-09-21T06:00:00+09:00',workday:'2026-09-20'}],review,week,12000).totalWon,null);
  assert.equal(laborEstimate([{start:'2026-09-22T02:00:00+09:00',end:'2026-09-22T06:00:00+09:00',workday:'2026-09-21'}],{...review,holidayDates:['2026-09-22']},week,12000).totalWon,null);
  assert.equal(laborEstimate([{start:'2026-09-20T22:00:00+09:00',end:'2026-09-21T07:00:00+09:00'}],review,week,12000).totalWon,null);
});
test('review permission, validation and private projection',()=>{
  const state={};const now='2026-09-24T09:00:00Z';ensureStaff(state,now);
  const input={action:'save_labor_review',review:{...review,week,tapperId:'tapper-cook',hourlyWon:12000,dailyContractMinutes:[480,480,480,480,480,0,0]}};
  assert.throws(()=>mutateStaff(state,input,{role:'manager'},now,'test',()=>{}),/사장님/);
  assert.throws(()=>mutateStaff(state,{...input,review:{...input.review,restMinutes:0}},{role:'owner'},now,'test',()=>{}),/주휴/);
  mutateStaff(state,input,{role:'owner'},now,'test',()=>{});
  assert.equal(state.laborReviews.length,1);
  assert.ok(staffView(state,{id:'owner',role:'owner'},now).labor);
  assert.equal(staffView(state,{id:'manager',role:'manager'},now).labor,undefined);
});
test('seconds are paid, scheduled leave excluded, reviews persist and conflicts reject', async t=>{
  const short=laborEstimate([{start:'2026-09-21T09:00:30+09:00',end:'2026-09-21T10:00:30+09:00'}],review,week,12000);
  assert.equal(short.workedMinutes,60);assert.equal(short.baseWon,12000);
  const {mkdtemp,rm}=await import('node:fs/promises');const {tmpdir}=await import('node:os');const path=await import('node:path');const {OperationsStore}=await import('../operations.mjs');
  const dir=await mkdtemp(path.join(tmpdir(),'tap-labor-test-'));t.after(()=>rm(dir,{recursive:true,force:true}));
  const store=new OperationsStore(path.join(dir,'state.json'),()=>new Date('2026-09-24T09:00:00Z'));
  const state=await store.snapshot('owner');const payload={action:'save_labor_review',revision:state.revision,review:{...review,week,tapperId:'tapper-cook',hourlyWon:12000,dailyContractMinutes:[480,480,480,480,480,0,0]}};
  const saved=await store.mutate('owner',payload);
  assert.equal(saved.labor.weeks.find(w=>w.week===week).people.find(p=>p.tapperId==='tapper-cook').review.hourlyWon,12000);
  await assert.rejects(store.mutate('owner',payload),{status:409});
  assert.equal((await store.snapshot('crew')).labor,undefined);
});
