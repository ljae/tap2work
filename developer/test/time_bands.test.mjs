import { test } from 'node:test';
import assert from 'node:assert/strict';
import { mkdtemp, rm } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import path from 'node:path';
import { OperationsStore } from '../operations.mjs';
import { rosterTemplates, workplaceBands } from '../parts.mjs';

async function setup(t) {
  const dir = await mkdtemp(path.join(tmpdir(), 'tap2work-bands-'));
  t.after(() => rm(dir, {recursive:true, force:true}));
  const store = new OperationsStore(path.join(dir, 'state.json'), () => new Date('2026-09-28T03:00:00Z'));
  const act = async (actor, action, values) => store.mutate(actor, {revision:(await store.snapshot(actor)).revision, action, ...values});
  return {store, act};
}
const band = (id, count = 1) => ({id, custom:true, name:'피크', start:'10:00', end:'14:00', headcounts:{kitchen:count}});
const week = rows => Object.fromEntries(Array.from({length:7}, (_, i) => [i+1, i === 0 ? rows : []]));

test('overlapping bands sum headcounts, export stable metadata and preserve shifts and overrides', async t => {
  const {store, act} = await setup(t);
  const before = await store.snapshot('owner');
  let state = await act('owner','save_workplace_hours',{days:week([band('custom-a',2),band('custom-b',3)])});
  assert.equal(state.rosterTemplates.length,5);
  assert.ok(state.rosterTemplates.every(r => r.partId === 'kitchen' && r.bandId));
  const ids = state.rosterTemplates.map(r => r.id).sort();
  const target = state.rosterTemplates[0];
  state = await act('manager','save_roster_slot',{date:'2026-09-28',partId:'kitchen',templateId:target.id,start:'09:00',end:'15:00'});
  const overrides = state.rosterOverrides;
  state = await act('owner','save_workplace_hours',{days:week([band('custom-b',3),{...band('custom-a',2), name:'수정', start:'09:30'}])});
  assert.deepEqual(state.rosterTemplates.map(r => r.id).sort(),ids);
  assert.deepEqual(state.staffShifts,before.staffShifts);
  assert.deepEqual(state.rosterOverrides,overrides);
  state = await act('owner','save_workplace_hours',{days:week([band('custom-b',3)])});
  assert.deepEqual(state.rosterOverrides,overrides);
  assert.equal(state.workplace.days[1][0].id,'custom-b');
  assert.equal((await store.snapshot('crew')).workplace.days[1][0].id,'custom-b');
});

test('legacy IDs survive metadata upgrade, reorder, rename and deletion of adjacent bands', () => {
  const rows = [{name:'오픈',start:'09:00',end:'12:00'}, {name:'마감',start:'12:00',end:'22:00',headcounts:{kitchen:2}}];
  const state = {workplace:{parts:[{id:'kitchen'}],days:week(rows)}};
  const old = rosterTemplates(state).map(r => r.id);
  const upgraded = workplaceBands(rows,1);
  assert.equal(upgraded[0].id,'legacy-band-1-0');
  state.workplace.days[1] = upgraded.reverse();
  assert.deepEqual(rosterTemplates(state).map(r => r.id).sort(),old.sort());
  state.workplace.days[1] = [{...upgraded[0],name:'늦은 마감',end:'23:00'}];
  assert.deepEqual(rosterTemplates(state).map(r => r.id),['band-1-kitchen-1','band-1-kitchen-1-seat-1']);
});

test('band validation and permissions are atomic; stale save and same crew overlap remain prohibited', async t => {
  const {store,act} = await setup(t);
  const state = await act('owner','save_workplace_hours',{days:week([band('custom-a')])});
  for (const rows of [[band('duplicate'),band('duplicate')], [{...band('bad'),start:'09:15'}], [band('bad',13)], [band('bad',0)], [{...band('bad'),headcounts:{missing:1}}], [null]]) {
    await assert.rejects(act('owner','save_workplace_hours',{days:week(rows)}),{status:400});
    assert.equal((await store.snapshot('owner')).revision,state.revision);
  }
  await assert.rejects(act('manager','save_workplace_hours',{days:week([])}),{status:403});
  await assert.rejects(store.mutate('owner',{revision:state.revision-1,action:'save_workplace_hours',days:week([])}),{status:409});
  const shift = {tapperId:'tapper-cook',partId:'kitchen',date:'2026-10-05',start:'10:00',end:'14:00'};
  await act('manager','save_staff_shift',shift);
  await assert.rejects(act('manager','save_staff_shift',{...shift,start:'11:00',end:'15:00'}),{status:409});
  await act('owner','save_workplace_hours',{days:week([{...band('overnight'),start:'22:00',end:'02:00'},band('day')])});
});

test('equivalent legacy weekday bands share link ID but retain weekday-local slot indices', async () => {
  const { workplaceBandDays, ensurePartModel } = await import('../parts.mjs');
  const a = {name:'오픈',start:'09:00',end:'12:00'};
  const b = {name:'피크',start:'12:00',end:'14:00'};
  const state = {workplace:{parts:[{id:'kitchen'}],days:{1:[a,b,a],2:[b,a,a]}}};
  const before = rosterTemplates(state).map(r=>r.id);
  ensurePartModel(state);
  const days = workplaceBandDays(state);
  assert.equal(days[1][0].id, days[2][1].id);
  assert.equal(days[1][1].id, days[2][0].id);
  assert.equal(days[1][2].id, days[2][2].id);
  assert.notEqual(days[1][0].id, days[1][2].id);
  assert.equal(days[1][0].legacyIndex,0);
  assert.equal(days[2][1].legacyIndex,1);
  assert.deepEqual(rosterTemplates(state).map(r=>r.id),before);
  assert.equal(ensurePartModel(state),false);
});

test('single-day compatibility API preserves band IDs and allows independent overlapping bands', async t => {
  const {act} = await setup(t);
  let state = await act('owner','save_workplace_day',{weekday:1,bands:[band('custom-a'),band('custom-b')]});
  const ids = state.rosterTemplates.filter(r=>r.weekday===1).map(r=>r.id);
  state = await act('owner','save_workplace_day',{weekday:1,bands:[{...band('custom-b'),name:'새 이름'},band('custom-a')]});
  assert.deepEqual(state.rosterTemplates.filter(r=>r.weekday===1).map(r=>r.id).sort(),ids.sort());
});
