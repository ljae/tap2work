import { test } from 'node:test';
import assert from 'node:assert/strict';
import { mkdtemp, readFile, writeFile, rm } from 'node:fs/promises';
import path from 'node:path';
import { tmpdir } from 'node:os';
import { OperationsStore, seedOperations } from '../operations.mjs';

async function setup(t) {
  const dir = await mkdtemp(path.join(tmpdir(), 'tap2work-layout-'));
  t.after(() => rm(dir, { recursive: true, force: true }));
  const filename = path.join(dir, 'ops.json');
  const clock = () => new Date('2026-09-19T05:00:00Z');
  const store = new OperationsStore(filename, clock);
  const save = async (view, actor = 'owner') => store.mutate(actor, { action: 'save_layout', revision: view.revision, layout: view.layout, zones: view.zones });
  return { store, filename, clock, save };
}

test('legacy layout upgrades once with original IDs and notes; counts include full dining room', async t => {
  const { store, filename, clock } = await setup(t);
  const legacy = seedOperations(clock());
  legacy.zones[0].name = '내 창고'; legacy.zones[0].description = '기존에 저장한 안내';
  await writeFile(filename, JSON.stringify(legacy));
  const first = await store.snapshot('owner');
  assert.equal(first.zones.find(z => z.id === 'storage').name, '내 창고');
  assert.equal(first.zones.find(z => z.id === 'storage').description, '기존에 저장한 안내');
  assert.equal(first.zones.filter(z => z.kind === 'table').length, 6);
  assert.equal(first.zones.reduce((n, z) => n + z.seats, 0), 24);
  const again = await store.snapshot('crew');
  assert.equal(again.revision, first.revision);
  assert.deepEqual(again.zones, first.zones);
  assert.deepEqual(first.items.map(i => i.zone), legacy.items.map(i => i.zone));
});

test('owner/manager can add, reposition, resize and delete tables with durable shared counts', async t => {
  const { store, filename, clock, save } = await setup(t);
  const view = await store.snapshot('owner');
  view.layout.name = '홀과 주방'; view.layout.columns = 20;
  view.zones.push({ id: 'table-new', name: '7번 테이블', description: '', kind: 'table', x: 17, y: 0, width: 2, height: 2, seats: 2 });
  const saved = await save(view, 'manager');
  assert.equal(saved.zones.filter(z => z.kind === 'table').length, 7);
  assert.equal(saved.layout.updatedBy.name, '민지');
  const reopened = await new OperationsStore(filename, clock).snapshot('crew');
  assert.equal(reopened.layout.name, '홀과 주방');
  assert.equal(reopened.zones.reduce((n, z) => n + z.seats, 0), 26);
  const table = saved.zones.find(z => z.id === 'table-new');
  table.x = 16; table.y = 3; table.width = 4; table.seats = 6;
  const moved = await save(saved);
  assert.equal(moved.zones.find(z => z.id === 'table-new').width, 4);
  moved.zones = moved.zones.filter(z => z.id !== 'table-new');
  assert.equal((await save(moved)).zones.filter(z => z.kind === 'table').length, 6);
});

test('crew cannot save and stale drafts cannot overwrite concurrent operations', async t => {
  const { store, save } = await setup(t);
  const stale = await store.snapshot('owner');
  await assert.rejects(save(stale, 'crew'), { status: 403 });
  await assert.rejects(save(stale, 'cook'), { status: 403 });
  const first = await save(stale);
  stale.layout.name = '덮어쓰기 시도';
  await assert.rejects(save(stale), { status: 409 });
  assert.equal((await store.snapshot('owner')).layout.name, first.layout.name);
});

test('invalid geometry, duplicate IDs/names, kinds, seat counts and capacity fail without saving', async t => {
  const { store, save, filename } = await setup(t);
  const original = await store.snapshot('owner');
  const before = await readFile(filename, 'utf8');
  const changes = [
    v => v.zones[0].x = -1,
    v => v.zones[0].x = .5,
    v => v.zones[0].width = 31,
    v => v.zones[0].height = NaN,
    v => v.layout.columns = 7,
    v => v.layout.rows = 31,
    v => v.zones[0].x = 15,
    v => v.zones[1].x = 0,
    v => v.zones[1].id = v.zones[0].id,
    v => v.zones[0].kind = 'unsupported',
    v => v.zones.find(z => z.id === 'table-1').seats = 0,
    v => v.zones.find(z => z.id === 'table-1').seats = 21,
    v => v.zones.find(z => z.id === 'table-1').name = '2번 테이블',
    v => v.zones = Array(81).fill(v.zones[0]),
  ];
  for (const change of changes) {
    const v = structuredClone(original); change(v);
    await assert.rejects(save(v), { status: 400 });
    assert.equal(await readFile(filename, 'utf8'), before);
  }
});

test('referenced inventory/task places cannot be deleted or turned into tables', async t => {
  const { store, save } = await setup(t);
  const original = await store.snapshot('owner');
  for (const id of ['storage', 'fridge', 'prep', 'sink', 'entrance']) {
    const deleted = structuredClone(original); deleted.zones = deleted.zones.filter(z => z.id !== id);
    await assert.rejects(save(deleted), { status: 400 });
  }
  const converted = structuredClone(original); Object.assign(converted.zones.find(z => z.id === 'fridge'), { kind: 'table', seats: 4 });
  await assert.rejects(save(converted), { status: 400 });
  original.zones.find(z => z.id === 'fridge').name = '새 냉장고 이름';
  assert.equal((await save(original)).zones.find(z => z.id === 'fridge').name, '새 냉장고 이름');
});

test('area backgrounds can overlap and removed unreferenced route points do not break snapshots', async t => {
  const { store, save } = await setup(t);
  const view = await store.snapshot('owner');
  view.zones = view.zones.filter(z => z.id !== 'exit');
  view.zones.push({ id: 'hall', name: '홀', kind: 'area', description: '', x: 8, y: 0, width: 8, height: 12, seats: 0 });
  const saved = await save(view);
  assert.equal(saved.zones.some(z => z.id === 'exit'), false);
  assert.ok((await store.snapshot('crew')).zones.some(z => z.id === 'hall'));
});
