import { test } from 'node:test';
import assert from 'node:assert/strict';
import { mkdtemp, rm, readFile, writeFile } from 'node:fs/promises';
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
  assert.equal(owner.tasks.length, owner.taskTemplates.filter(template => !template.archivedAt).length + 2 + owner.tasks.filter(task => task.orderId).length + owner.tasks.filter(task => task.preparedItemId).length);
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

// fetch() drops a custom Host header, so tunnel requests are simulated with node:http.
async function raw(base, method, route, headers = {}, payload) {
  const { request } = await import('node:http');
  const { port } = new URL(base);
  return new Promise((resolve, reject) => {
    const req = request({ host: '127.0.0.1', port, method, path: route, headers: { Host: 'demo.trycloudflare.com', ...headers } }, res => {
      let text = ''; res.setEncoding('utf8'); res.on('data', chunk => text += chunk);
      res.on('end', () => resolve({ status: res.statusCode, headers: res.headers, json: () => JSON.parse(text) }));
    });
    req.on('error', reject);
    if (payload) req.write(payload);
    req.end();
  });
}
test('shared demo mode exposes only the operations API to allowed browser origins through a tunnel host', async t => {
  const { file, clock } = await setup(t);
  const server = createConsoleServer({ operationsFile: file, operationsClock: clock, publicOrigins: ['http://tap2.work'] });
  await new Promise(resolve => server.listen(0, '127.0.0.1', resolve));
  t.after(() => new Promise(resolve => server.close(resolve)));
  const base = `http://127.0.0.1:${server.address().port}`;
  const preflight = await raw(base, 'OPTIONS', '/api/operations', { Origin: 'http://tap2.work', 'Access-Control-Request-Method': 'POST' });
  assert.equal(preflight.status, 204);
  assert.equal(preflight.headers['access-control-allow-origin'], 'http://tap2.work');
  assert.match(preflight.headers['access-control-allow-headers'], /x-demo-token/);
  const snapshot = await raw(base, 'GET', '/api/operations', { Origin: 'http://tap2.work', 'x-demo-actor': 'crew' });
  assert.equal(snapshot.status, 200);
  assert.equal(snapshot.headers['access-control-allow-origin'], 'http://tap2.work');
  const view = snapshot.json();
  const task = view.tasks.find(row => row.requiredRole === 'all' && row.kind === 'routine');
  const post = origin => raw(base, 'POST', '/api/operations', { 'Content-Type': 'application/json', Origin: origin, 'x-demo-actor': 'crew', 'x-demo-token': view.demoToken }, JSON.stringify({ revision: view.revision, action: 'complete_step', taskId: task.id, stepId: task.steps[0].id }));
  assert.equal((await post('https://evil.example')).status, 403);
  const denied = await raw(base, 'GET', '/api/operations', { Origin: 'https://evil.example', 'x-demo-actor': 'crew' });
  assert.equal(denied.headers['access-control-allow-origin'], undefined);
  assert.equal((await post('http://tap2.work')).status, 200);
  // A colleague on another device sees the same shared check.
  const colleague = (await raw(base, 'GET', '/api/operations', { Origin: 'http://tap2.work', 'x-demo-actor': 'owner' })).json();
  assert.equal(colleague.tasks.find(row => row.id === task.id).steps[0].completedBy.name, '지우');
  for (const route of ['/api/project', '/api/session', '/api/preview', '/', '/app/']) {
    assert.equal((await raw(base, 'GET', route)).status, 403, route);
  }
  const closed = createConsoleServer({ operationsFile: file, operationsClock: clock, publicOrigins: [] });
  await new Promise(resolve => closed.listen(0, '127.0.0.1', resolve));
  t.after(() => new Promise(resolve => closed.close(resolve)));
  assert.equal((await raw(`http://127.0.0.1:${closed.address().port}`, 'GET', '/api/operations')).status, 403);
});

test('menu TAPs complete independently, move atomically as an order, and survive Korean midnight', async t => {
  const { store, act, advance } = await setup(t);
  let state = await store.snapshot('owner');
  const first = state.tasks.find(t => t.orderId && state.tasks.filter(s => s.orderId === t.orderId).length > 1);
  assert.ok(first, 'sample must include a multiple-menu ticket');
  const members = state.tasks.filter(s => s.orderId === first.orderId);
  assert.ok(members.every(t => t.steps.length >= 3));
  state = await act('cook', 'complete_task', { taskId: first.id });
  assert.ok(state.dashboard.queue.some(t => t.id === first.orderId), 'one menu must not complete the ticket');
  advance(86400000);
  state = await store.snapshot('owner');
  assert.equal(state.tasks.filter(s => s.orderId === first.orderId).length, members.length);
  state = await act('cook', 'move_tap', { taskId: members[1].id, status: 'done', folderId: 'order-work' });
  assert.ok(state.tasks.filter(s => s.orderId === first.orderId).every(t => t.completedAt));
  assert.ok(!state.dashboard.queue.some(t => t.id === first.orderId));
  state = await act('cook', 'move_tap', { taskId: first.id, status: 'processing', folderId: 'order-work' });
  assert.ok(state.tasks.filter(s => s.orderId === first.orderId).every(t => !t.completedAt));
  assert.equal(state.dashboard.queue.find(t => t.id === first.orderId).status, '조리 중');
});

test('saved order Small Tap order survives snapshots and store reload', async t => {
  const { store, act, file, clock } = await setup(t);
  const before = await store.snapshot('owner');
  const task = before.tasks.find(row => row.orderId && !row.completedAt);
  const reversed = task.steps.map(step => step.id).reverse();
  const saved = await act('owner', 'reorder_small_taps', { taskId: task.id, stepIds: reversed });
  assert.deepEqual(saved.tasks.find(row => row.id === task.id).steps.map(step => step.id), reversed);
  assert.deepEqual((await store.snapshot('owner')).tasks.find(row => row.id === task.id).steps.map(step => step.id), reversed);
  assert.deepEqual((await new OperationsStore(file, clock).snapshot('owner')).tasks.find(row => row.id === task.id).steps.map(step => step.id), reversed);
});

test('pay audit amounts stay visible to owner only, including legacy activity', async t => {
  const { store, act, file, clock } = await setup(t);
  const first = await store.snapshot('owner');
  const tapperId = first.tappers[0].id;
  await act('owner', 'record_payment', { tapperId, amountWon: 123456 });
  await act('owner', 'add_pay_adjustment', { tapperId, amountWon: 76543, note: '추가 근무' });
  const owner = await store.snapshot('owner');
  assert.ok(owner.activity.some(row => row.message.includes('123456원')));
  assert.ok(owner.activity.some(row => row.message.includes('76543원')));
  const disk = JSON.parse(await readFile(file, 'utf8'));
  disk.activity.unshift({ id: 'legacy-pay', at: clock().toISOString(), actor: { id: 'owner' }, message: '급여 지급 기록 98765원' });
  await writeFile(file, JSON.stringify(disk));
  for (const role of ['manager', 'cook', 'crew']) {
    const view = await new OperationsStore(file, clock).snapshot(role);
    assert.equal(view.payRecords.length, 0, role);
    assert.equal(view.payAdjustments.length, 0, role);
    assert.ok(!view.activity.some(row => /(?:급여 지급 기록|추가보수)/.test(row.message)), role);
  }
  assert.ok((await new OperationsStore(file, clock).snapshot('owner')).activity.some(row => row.id === 'legacy-pay'));
});

test('staffing slots reject overlap, occupied targets, invalid dates, wrong roles and stale assignments', async t => {
  const { store, act } = await setup(t);
  let state = await store.snapshot('owner');
  const slot = state.staffingSlots.find(s => s.duty === '조리');
  const payload = { slotId: slot.id, tapperId: 'tapper-cook', date: '2026-09-21' };
  await assert.rejects(act('crew', 'assign_staffing_slot', payload), { status: 403 });
  await assert.rejects(act('owner', 'assign_staffing_slot', { ...payload, date: '2026-02-30' }), { status: 400 });
  state = await act('owner', 'assign_staffing_slot', payload);
  const shift = state.staffShifts.find(s => s.slotId === slot.id && s.date === payload.date);
  assert.ok(shift);
  await assert.rejects(act('owner', 'assign_staffing_slot', payload), { status: 409 });
  const oldRevision = state.revision;
  state = await act('manager', 'assign_staffing_slot', { ...payload, date: '2026-09-22', sourceShiftId: shift.id });
  assert.equal(state.staffShifts.filter(s => s.id === shift.id).length, 1);
  assert.equal(state.staffShifts.find(s => s.id === shift.id).date, '2026-09-22');
  await assert.rejects(store.mutate('owner', { ...payload, revision: oldRevision, action: 'assign_staffing_slot' }), { status: 409 });
  await assert.rejects(act('owner', 'assign_staffing_slot', { ...payload, date: '2026-09-19' }), { status: 409 });
  state = await act('owner', 'assign_staffing_slot', { ...payload, date: '2026-09-22', tapperId: null });
  assert.ok(!state.staffShifts.some(s => s.id === shift.id));
  state = await act('owner', 'save_staffing_slots', { slots: [slot] });
  assert.equal(state.staffingSlots.length, 1);
  assert.ok(state.staffShifts.some(s => s.tapperId === 'tapper-manager'), 'configuration preserves existing shifts');
});

test('repeat shifts are bounded, idempotent, and check overnight overlap for every date', async t => {
  const { store, act } = await setup(t);
  const input = { tapperId: 'tapper-sample', duty: '서빙1', date: '2026-09-28', start: '23:00', end: '02:00', employmentType: '시간알바', repeatDays: 7, weekdays: [1, 3, 5] };
  await assert.rejects(act('crew', 'save_shift_pattern', input), { status: 403 });
  await assert.rejects(act('owner', 'save_shift_pattern', { ...input, repeatDays: 91 }), { status: 400 });
  await assert.rejects(act('owner', 'save_shift_pattern', { ...input, start: '23:15' }), { status: 400 });
  let state = await act('owner', 'save_shift_pattern', input);
  const created = state.staffShifts.filter(s => s.tapperId === input.tapperId && s.date >= input.date);
  assert.deepEqual(created.map(s => s.date), ['2026-09-28', '2026-09-30', '2026-10-02']);
  assert.ok(created.every(s => s.employmentType === '시간알바'));
  state = await act('owner', 'save_shift_pattern', input);
  assert.equal(state.staffShifts.filter(s => s.tapperId === input.tapperId && s.date >= input.date).length, 3);
  await assert.rejects(act('owner', 'save_shift_pattern', { ...input, date: '2026-09-29', start: '01:00', end: '04:00', repeatDays: 1, weekdays: [] }), { status: 409 });
  const manager = await store.snapshot('manager');
  assert.equal(manager.tappers[0].gross, undefined);
  assert.equal(manager.tappers[0].hourlyWon, undefined);
  assert.equal(manager.tappers[0].payPeriodStart, undefined);
});

test('customer channels own packing steps and preserve ticket requests', async t => {
  const { store } = await setup(t);
  const state = await store.snapshot('owner');
  const delivery = state.tasks.find(t => t.orderChannel === '배달' && t.customerRequest);
  assert.ok(delivery);
  assert.equal(delivery.orderPlatform, '배달의민족');
  assert.ok(delivery.steps.some(s => s.id === 'pack-check'));
  assert.equal(delivery.steps.length, 4);
  assert.match(delivery.steps.find(s => s.id === 'handoff').title, /기사 전달/);
  assert.ok(!state.tasks.some(t => /(?:^|-)packing$/.test(t.templateId ?? '') && !t.archivedAt));
});

test('channel migration preserves a completed menu snapshot while upgrading its unfinished sibling', async t => {
  const { store, file } = await setup(t);
  const first = await store.snapshot('owner');
  const menu = first.tasks.find(t => t.orderChannel === '배달' && t.customerRequest);
  const disk = JSON.parse(await readFile(file, 'utf8'));
  const siblings = disk.tasks.filter(t => t.orderId === menu.orderId);
  assert.equal(siblings.length, 2);
  for (const task of siblings) {
    task.steps = task.steps.filter(s => s.id !== 'pack-check');
    task.steps.find(s => s.id === 'handoff').title = '주문번호 대조·전달';
  }
  siblings[1].steps = ['cook-check', 'handoff', 'order-check'].map(id => siblings[1].steps.find(step => step.id === id));
  siblings[0].completedAt = first.serverTime;
  siblings[0].completedBy = { id: 'cook', name: '현우' };
  await writeFile(file, JSON.stringify(disk));
  const migrated = await store.snapshot('owner');
  const completed = migrated.tasks.find(t => t.id === siblings[0].id);
  const unfinished = migrated.tasks.find(t => t.id === siblings[1].id);
  assert.equal(completed.steps.length, 3);
  assert.equal(completed.completedAt, siblings[0].completedAt);
  assert.equal(unfinished.steps.length, 4);
  assert.deepEqual(unfinished.steps.map(step => step.id), ['cook-check', 'pack-check', 'handoff', 'order-check']);
  assert.match(unfinished.steps.find(s => s.id === 'handoff').title, /기사 전달/);
});

test('manual text and external media links persist with revision checks and reusable recipe updates', async t => {
  const { store, act } = await setup(t);
  const state = await store.snapshot('owner');
  const task = state.tasks.find(t => t.templateId && t.steps?.length);
  const step = task.steps[0];
  const payload = { taskId: task.id, stepId: step.id, manual: '매장 승인 레시피 문서 확인', videoUrl: 'https://example.com/video', imageUrl: 'https://example.com/photos' };
  await assert.rejects(act('crew', 'save_step_manual', payload), { status: 403 });
  await assert.rejects(act('owner', 'save_step_manual', { ...payload, videoUrl: 'javascript:alert(1)' }), { status: 400 });
  const next = await act('owner', 'save_step_manual', payload);
  assert.equal(next.tasks.find(t => t.id === task.id).steps[0].imageUrl, payload.imageUrl);
  assert.equal(next.taskTemplates.find(t => t.id === task.templateId).steps[0].videoUrl, payload.videoUrl);
  assert.equal(next.tasks.find(t => t.id === task.id).steps[0].manualHistory[0].manual, step.manual);
  await assert.rejects(store.mutate('owner', { ...payload, action: 'save_step_manual', revision: state.revision }), { status: 409 });
  await act('owner', 'complete_step', { taskId: task.id, stepId: step.id });
  await assert.rejects(act('owner', 'save_step_manual', payload), { status: 409 });
});
