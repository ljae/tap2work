import { test } from 'node:test';
import assert from 'node:assert/strict';
import { mkdtemp, rm, readFile, writeFile } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import path from 'node:path';
import { OperationsStore } from '../operations.mjs';

async function setup(t) {
  const dir = await mkdtemp(path.join(tmpdir(), 'tap2work-prepared-'));
  t.after(() => rm(dir, { recursive: true, force: true }));
  const file = path.join(dir, 'state.json');
  let now = new Date('2026-09-19T05:00:00Z');
  const store = new OperationsStore(file, () => now);
  const act = async (actor, action, values = {}) => store.mutate(actor, {
    revision: (await store.snapshot(actor)).revision, action, ...values,
  });
  return { store, act, file, advance: ms => { now = new Date(now.getTime() + ms); } };
}
const balance = state => state.preparedItems.find(i => i.id === 'prepared-bone').onHand;
const prep = state => state.tasks.filter(t => t.preparedItemId === 'prepared-bone' && !t.completedAt);

test('order TAPs contain only order work; first cooking action consumes shared prepared portions once', async t => {
  const { store, act } = await setup(t);
  let state = await store.snapshot('owner');
  const menus = state.tasks.filter(t => t.orderId && ['bowl', 'pork'].includes(t.menuId));
  assert.equal(menus.length, 2);
  assert.ok(menus.every(t => t.steps.length >= 3 && !t.steps.some(s => s.sourceTemplateId)));
  assert.equal(balance(state), 3);
  assert.equal(prep(state).length, 1);
  state = await act('cook', 'complete_step', { taskId: menus[0].id, stepId: menus[0].steps[0].id });
  const firstUse = menus[0].menuQuantity * 2;
  assert.equal(balance(state), 3 - firstUse);
  state = await act('cook', 'move_tap', { taskId: menus[0].id, folderId: 'order-work', status: 'processing' });
  assert.equal(balance(state), 3 - firstUse);
  state = await act('cook', 'complete_task', { taskId: menus[0].id });
  assert.equal(balance(state), 3 - firstUse);
  state = await act('cook', 'move_tap', { taskId: menus[0].id, folderId: 'order-work', status: 'done' });
  assert.equal(balance(state), 3 - firstUse);
  state = await act('cook', 'move_tap', { taskId: menus[1].id, folderId: 'order-work', status: 'processing' });
  const allOrder = state.tasks.filter(t => t.orderId === menus[1].orderId);
  const expected = 3 - firstUse - allOrder.filter(t => t.menuId === 'pork').reduce((n, t) => n + t.menuQuantity * 2, 0);
  assert.equal(balance(state), expected);
  assert.equal(prep(state).length, 1, 'one open preparation TAP despite multiple orders');
  assert.equal(state.preparedMovements.filter(m => m.type === 'order_use' && m.itemId === 'prepared-bone').length, 2);
});

test('actual preparation quantity credits once; short batch generates a new TAP; open work survives midnight', async t => {
  const { store, act, advance } = await setup(t);
  let state = await store.snapshot('owner');
  const first = prep(state)[0];
  await assert.rejects(act('crew', 'complete_preparation', { taskId: first.id, quantity: 1 }), { status: 409 });
  await assert.rejects(act('cook', 'complete_task', { taskId: first.id }), { status: 400 });
  await assert.rejects(act('cook', 'move_tap', { taskId: first.id, folderId: first.folderId, status: 'done' }), { status: 400 });
  state = await act('cook', 'complete_preparation', { taskId: first.id, quantity: 1 });
  assert.equal(balance(state), 4);
  assert.equal(prep(state).length, 1, 'low output creates exactly one next generation');
  const next = prep(state)[0];
  assert.notEqual(next.id, first.id);
  await assert.rejects(act('cook', 'complete_preparation', { taskId: first.id, quantity: 1 }), { status: 409 });
  await assert.rejects(act('cook', 'reopen_step', { taskId: first.id, stepId: first.steps[0].id }), { status: 409 });
  advance(86400000);
  state = await store.snapshot('owner');
  assert.equal(prep(state).length, 1);
  assert.equal(prep(state)[0].id, next.id);
  state = await act('cook', 'complete_preparation', { taskId: next.id, quantity: 10 });
  assert.equal(balance(state), 14);
  assert.equal(prep(state).length, 0);
  assert.equal(state.preparedMovements.filter(m => m.type === 'prepared_output').length, 2);
});

test('a second prepared item maps to a different menu; count and config keep audit and enforce roles/revisions', async t => {
  const { store, act } = await setup(t);
  let state = await store.snapshot('owner');
  const folderId = state.preparedItems[0].folderId;
  const zone = state.preparedItems[0].zone;
  const config = { name: '음료 시럽', unit: '컵', minimum: 2, target: 8, batchQuantity: 5,
    folderId, zone, instructions: '매장 승인 배합으로 시럽 준비', menuUses: [{ menuId: 'water', quantity: 1 }] };
  await assert.rejects(act('crew', 'save_prepared_item', config), { status: 403 });
  await assert.rejects(act('owner', 'save_prepared_item', { ...config, menuUses: [{ menuId: 'missing', quantity: 1 }] }), { status: 400 });
  state = await act('owner', 'save_prepared_item', config);
  const syrup = state.preparedItems.find(i => i.name === config.name);
  assert.ok(syrup);
  assert.equal(state.tasks.filter(t => t.preparedItemId === syrup.id && !t.completedAt).length, 1);
  state = await act('owner', 'count_prepared_item', { id: syrup.id, quantity: 10, reason: '실사' });
  assert.equal(state.tasks.filter(t => t.preparedItemId === syrup.id && !t.completedAt).length, 0);
  const water = state.tasks.find(t => t.menuId === 'water');
  state = await act('cook', 'complete_step', { taskId: water.id, stepId: water.steps[0].id });
  assert.equal(state.preparedItems.find(i => i.id === syrup.id).onHand, 10 - water.menuQuantity);
  assert.ok(state.preparedMovements.some(m => m.itemId === syrup.id && m.type === 'count_correction' && m.reason === '실사'));
  const stale = state.revision;
  await act('owner', 'count_prepared_item', { id: syrup.id, quantity: 2, reason: '폐기' });
  await assert.rejects(store.mutate('owner', { action: 'count_prepared_item', revision: stale, id: syrup.id, quantity: 9, reason: '오래된 화면' }), { status: 409 });
});

test('superseded preparation cannot credit stock or accept hidden Tap edits', async t => {
  const { store, act, file } = await setup(t);
  let state = await store.snapshot('owner');
  const task = prep(state)[0];
  state = await act('owner', 'count_prepared_item', { id: task.preparedItemId, quantity: 20, reason: '실사' });
  assert.ok(!state.tasks.some(row => row.id === task.id));
  const revision = state.revision;
  const steps = task.steps.map(step => step.id);
  for (const [action, values, actor, status] of [
    ['complete_preparation', { quantity: 5 }, 'cook', 409],
    ['complete_step', { stepId: steps[0] }, 'cook', 409],
    ['move_tap', { folderId: task.folderId, status: 'processing' }, 'cook', 404],
    ['reorder_small_taps', { stepIds: [...steps].reverse() }, 'owner', 400],
    ['save_step_manual', { stepId: steps[0], manual: '새 방법' }, 'owner', 409],
    ['reopen_step', { stepId: steps[0] }, 'cook', 409],
  ]) await assert.rejects(act(actor, action, { taskId: task.id, ...values }), { status }, action);
  state = await store.snapshot('owner');
  assert.equal(state.revision, revision);
  assert.equal(balance(state), 20);
  const disk = JSON.parse(await readFile(file, 'utf8'));
  assert.ok(disk.tasks.find(row => row.id === task.id).supersededAt);
  assert.equal(disk.preparedMovements.filter(row => row.taskId === task.id && row.type === 'prepared_output').length, 0);
});

test('migration keeps prior order evidence and does not retroactively consume a current count', async t => {
  const { store, file } = await setup(t);
  let state = await store.snapshot('owner');
  const original = state.tasks.find(t => t.orderId && !t.completedAt);
  const archived = { id: 'legacy-prep-step', title: '기존 사전 준비', sourceTemplateId: 'old-template', completedAt: '2026-09-19T02:00:00Z', completedBy: { id: 'cook' } };
  const disk = JSON.parse(await readFile(file, 'utf8'));
  const task = disk.tasks.find(t => t.id === original.id);
  task.steps.splice(1, 0, archived);
  task.preparedUsageVersion = undefined;
  delete disk.preparedVersion; delete disk.preparedItems; delete disk.preparedMovements;
  delete disk.orderCompositionVersion;
  await writeFile(file, JSON.stringify(disk));
  state = await store.snapshot('owner');
  const upgraded = state.tasks.find(t => t.id === original.id);
  assert.ok(upgraded.archivedPreparationSteps.some(s => s.id === archived.id && s.completedBy.id === 'cook'));
  assert.ok(!upgraded.steps.some(s => s.sourceTemplateId));
  assert.equal(upgraded.preparedUsageVersion, 'before_tracking');
  assert.equal(balance(state), 3);
});
