import { test } from 'node:test';
import assert from 'node:assert/strict';
import { mkdtemp, rm } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import path from 'node:path';
import { OperationsStore } from '../operations.mjs';
import { createConsoleServer } from '../server.mjs';

async function setup(t) {
  const dir = await mkdtemp(path.join(tmpdir(), 'tap2work-ops-test-'));
  t.after(() => rm(dir, { recursive: true, force: true }));
  let now = new Date('2026-09-19T05:00:00Z');
  const file = path.join(dir, 'operations.json');
  const clock = () => now;
  const store = new OperationsStore(file, clock);
  const act = async (actor, action, values = {}) => store.mutate(actor, { revision: (await store.snapshot(actor)).revision, action, ...values });
  return { store, act, file, clock, advance: ms => { now = new Date(now.getTime() + ms); } };
}

test('private owner data and procurement prices are projected by demo role', async t => {
  const { store } = await setup(t);
  const owner = await store.snapshot('owner');
  const manager = await store.snapshot('manager');
  const crew = await store.snapshot('crew');
  // Every seeded 뼈찜 group plus the two inventory checks whose order date has passed.
  assert.equal(owner.tasks.length, owner.taskTemplates.length + 2);
  assert.equal(owner.tasks.filter(task => task.kind === 'stock').length, 2);
  assert.ok(owner.privateSummary);
  assert.equal(manager.privateSummary, undefined);
  assert.equal(crew.privateSummary, undefined);
  assert.equal(crew.items[0].price, undefined);
  assert.ok(manager.items[0].price);
  assert.equal(crew.tasks.find(task => task.requiredRole === 'cook').canComplete, false);
  assert.throws(() => store.snapshot('unknown'), { status: 403 });
});

test('shared completion is attributed, durable, and protected against stale duplicate writes', async t => {
  const { store, file, clock } = await setup(t);
  const before = await store.snapshot('crew');
  const task = before.tasks.find(task => task.requiredRole === 'all' && task.kind === 'routine');
  const payload = { revision: before.revision, action: 'complete_step', taskId: task.id, stepId: task.steps[0].id };
  const results = await Promise.allSettled([store.mutate('crew', payload), store.mutate('manager', payload)]);
  assert.equal(results[0].status, 'fulfilled');
  assert.equal(results[1].reason.status, 409);
  const reopened = await new OperationsStore(file, clock).snapshot('owner');
  assert.equal(reopened.tasks.find(row => row.id === task.id).steps[0].completedBy.name, '지우');
  assert.ok(reopened.tasks.find(row => row.id === task.id).steps[0].completedAt);
});

test('wrong rank cannot complete a task or place an order', async t => {
  const { store, act } = await setup(t);
  const before = await store.snapshot('crew');
  const task = before.tasks.find(task => task.requiredRole === 'cook');
  await assert.rejects(act('crew', 'complete_task', { taskId: task.id }), { status: 403 });
  await assert.rejects(act('crew', 'place_order', { lines: [{ itemId: 'rice', quantity: 1 }] }), { status: 403 });
  await assert.rejects(act('crew', 'update_shift', { shiftId: 's1', status: '휴가' }), { status: 403 });
  assert.equal((await store.snapshot('crew')).revision, before.revision);
});

test('order does not alter stock; receipt applies once and prevents pending duplicate orders', async t => {
  const { act, store } = await setup(t);
  const ordered = await act('owner', 'place_order', { lines: [{ itemId: 'rice', quantity: 2 }, { itemId: 'lettuce', quantity: 3 }] });
  assert.equal(ordered.items.find(i => i.id === 'rice').quantity, 2);
  assert.equal(ordered.orders[0].total, 126500);
  await assert.rejects(act('manager', 'place_order', { lines: [{ itemId: 'rice', quantity: 1 }] }), { status: 409 });
  const received = await act('manager', 'receive_order', { orderId: ordered.orders[0].id });
  assert.equal(received.items.find(i => i.id === 'rice').quantity, 4);
  await assert.rejects(act('owner', 'receive_order', { orderId: ordered.orders[0].id }), { status: 409 });
  const crew = await store.snapshot('crew');
  assert.equal(crew.orders[0].total, undefined);
  assert.equal(crew.orders[0].lines[0].price, undefined);
  assert.equal(crew.orders[0].receivedBy.name, '민지');
});

test('review is fixed to order date, intermediate counts do not postpone it, completion does not repeat', async t => {
  const { act, store, advance } = await setup(t);
  await act('owner', 'review_policy', { itemId: 'rice', reviewDays: 2, minimum: 1 });
  await act('owner', 'place_order', { lines: [{ itemId: 'rice', quantity: 1 }] });
  advance(86400000);
  await act('crew', 'check_stock', { itemId: 'rice', quantity: 1.5 });
  assert.equal((await store.snapshot('crew')).tasks.filter(task => task.itemId === 'rice').length, 0);
  advance(86400000);
  let state = await store.snapshot('crew');
  const task = state.tasks.find(task => task.itemId === 'rice');
  assert.ok(task);
  assert.equal((await store.snapshot('crew')).tasks.filter(task => task.itemId === 'rice').length, 1);
  state = await act('crew', 'complete_task', { taskId: task.id, quantity: 0.5 });
  assert.equal(state.items.find(i => i.id === 'rice').quantity, 0.5);
  assert.equal(state.tasks.find(t => t.id === task.id).completedBy.name, '지우');
  advance(2 * 86400000);
  state = await store.snapshot('crew');
  assert.equal(state.tasks.filter(task => task.itemId === 'rice' && !task.completedAt).length, 0);
  assert.equal(state.items.find(i => i.id === 'rice').reviewState, 'completed');
  await act('owner', 'receive_order', { orderId: state.orders[0].id });
  await act('owner', 'place_order', { lines: [{ itemId: 'rice', quantity: 1 }] });
  advance(2 * 86400000);
  state = await store.snapshot('crew');
  const next = state.tasks.find(task => task.itemId === 'rice' && !task.completedAt);
  assert.ok(next);
  assert.notEqual(next.id, task.id);
});

test('new order replaces older unfinished inventory check without deleting the prior record', async t => {
  const { store, act, advance, file } = await setup(t);
  const before = await store.snapshot('owner');
  const old = before.tasks.find(t => t.itemId === 'tomato');
  const ordered = await act('owner', 'place_order', { lines: [{ itemId: 'tomato', quantity: 4 }] });
  assert.equal(ordered.tasks.some(t => t.id === old.id), false);
  await assert.rejects(act('crew', 'complete_task', { taskId: old.id, quantity: 2 }), { status: 409 });
  advance(2 * 86400000);
  const state = await store.snapshot('crew');
  assert.equal(state.tasks.filter(t => t.itemId === 'tomato').length, 1);
  const { readFile } = await import('node:fs/promises');
  const disk = JSON.parse(await readFile(file, 'utf8'));
  assert.ok(disk.tasks.find(t => t.id === old.id).supersededAt);
});

test('extending the review interval hides unfinished check until the new due date', async t => {
  const { store, act, advance } = await setup(t);
  const before = await store.snapshot('owner');
  const old = before.tasks.find(t => t.itemId === 'tomato');
  const changed = await act('owner', 'review_policy', { itemId: 'tomato', reviewDays: 5, minimum: 3 });
  assert.equal(changed.items.find(i => i.id === 'tomato').reviewState, 'scheduled');
  assert.equal(changed.tasks.some(t => t.id === old.id), false);
  await assert.rejects(act('crew', 'complete_task', { taskId: old.id, quantity: 2 }), { status: 409 });
  advance(2 * 86400000);
  assert.equal((await store.snapshot('crew')).tasks.filter(t => t.id === old.id).length, 1);
});

test('routine work renews at Korean midnight and rejects yesterday completion', async t => {
  const { act, store, advance } = await setup(t);
  const before = await act('owner', 'create_task', { title: '마감 냉장고 확인', requiredRole: 'manager', slot: '마감', zone: 'fridge' });
  const old = before.tasks.find(task => task.title === '마감 냉장고 확인');
  advance(10 * 3600000);
  const after = await store.snapshot('manager');
  assert.equal(after.day, '2026-09-20');
  assert.equal(after.tasks.filter(task => task.title === old.title).length, 1);
  assert.notEqual(after.tasks.find(task => task.title === old.title).id, old.id);
  await assert.rejects(act('manager', 'complete_task', { taskId: old.id }), { status: 409 });
});

test('leave changes and accepted coverage are visible to colleagues without private reasons', async t => {
  const { act, store } = await setup(t);
  const requested = await act('crew', 'offer_cover', { shiftId: 's4' });
  assert.equal(requested.shifts.find(s => s.id === 's4').covering, null);
  await act('owner', 'assign_cover', { requestId: requested.coverRequests[0].id });
  assert.equal((await store.snapshot('cook')).shifts.find(s => s.id === 's4').covering.name, '지우');
  await act('manager', 'update_shift', { shiftId: 's2', status: '휴가' });
  const coworker = await store.snapshot('crew');
  assert.equal(coworker.shifts.find(s => s.id === 's2').status, '휴가');
  assert.equal(coworker.privateSummary, undefined);
});

test('invalid quantities and malformed order lines do not modify state', async t => {
  const { act, store } = await setup(t);
  const before = await store.snapshot('owner');
  for (const quantity of [-1, NaN, Infinity, '3', 100001]) await assert.rejects(act('crew', 'check_stock', { itemId: 'rice', quantity }), { status: 400 });
  await assert.rejects(act('owner', 'place_order', { lines: [null] }), { status: 400 });
  await assert.rejects(act('owner', 'place_order', { lines: [{ itemId: 'rice', quantity: 1 }, { itemId: 'rice', quantity: 2 }] }), { status: 400 });
  assert.equal((await store.snapshot('owner')).revision, before.revision);
});

test('operations HTTP API enforces token, same origin, demo rank, and revisions', async t => {
  const { file, clock } = await setup(t);
  const server = createConsoleServer({ operationsFile: file, operationsClock: clock });
  await new Promise(resolve => server.listen(0, '127.0.0.1', resolve));
  t.after(() => new Promise(resolve => server.close(resolve)));
  const base = `http://127.0.0.1:${server.address().port}`;
  const snapshot = await fetch(`${base}/api/operations`, { headers: { 'x-demo-actor': 'crew' } }).then(r => r.json());
  assert.equal(snapshot.privateSummary, undefined);
  const data = { revision: snapshot.revision, action: 'check_stock', itemId: 'rice', quantity: 4 };
  const post = (headers, value = data) => fetch(`${base}/api/operations`, { method: 'POST', headers: { 'Content-Type': 'application/json', 'x-demo-actor': 'crew', ...headers }, body: JSON.stringify(value) });
  assert.equal((await post({})).status, 403);
  assert.equal((await post({ Origin: 'https://example.com', 'x-demo-token': snapshot.demoToken })).status, 403);
  const headers = { Origin: base, 'x-demo-token': snapshot.demoToken };
  assert.equal((await post(headers)).status, 200);
  assert.equal((await post(headers)).status, 409);
});
