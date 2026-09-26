import { test } from 'node:test';
import assert from 'node:assert/strict';
import { mkdtemp, readFile, writeFile, rm } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import path from 'node:path';
import { seedSales, salesDashboard } from '../sales.mjs';
import { seedOperations, OperationsStore } from '../operations.mjs';

const now = new Date('2026-09-19T15:10:00Z'); // 9/20 00:10 KST
const line = { menuId: 'one', name: '덮밥', quantity: 3, unitPrice: 10000, discountPerUnit: 1000, returnedQuantity: 1 };
const ticket = (id, overrides = {}) => ({ id, number: id, createdAt: '2026-09-19T15:00:00Z', channel: '매장', status: '완료', payment: '결제', lines: [line], ...overrides });
const fixture = () => ({ source: 'sample', seededAt: now.toISOString(), menus: [{ id: 'one', name: '덮밥', category: '식사' }, { id: 'zero', name: '아직 안 팔린 메뉴', category: '식사' }], tickets: [
  ticket('paid'), ticket('cancelled', { status: '취소' }), ticket('unpaid', { payment: '미결제', status: '접수' }),
  ticket('yesterday', { createdAt: '2026-09-19T14:59:59Z', status: '조리 중', channel: '배달' }),
  ticket('future', { createdAt: '2026-09-19T15:11:00Z' }),
] });
const report = (d, days = 1, channel = '전체') => d.reports.find(r => r.days === days && r.channel === channel);

test('sales reconcile discounts, refunds, cancellation, unpaid tickets, all menus and KST boundary', () => {
  const dashboard = salesDashboard(fixture(), now, true);
  const today = report(dashboard);
  assert.equal(today.startDay, '2026-09-20');
  assert.equal(today.summary.revenue, 18000);
  assert.equal(today.summary.gross, 30000);
  assert.equal(today.summary.discount, 3000);
  assert.equal(today.summary.refund, 9000);
  assert.equal(today.summary.average, 18000);
  assert.equal(today.summary.orderCount, 2);
  assert.equal(today.summary.cancelledCount, 1);
  assert.equal(today.menus[0].orderedQuantity, 6);
  assert.equal(today.menus[0].soldQuantity, 2);
  assert.equal(today.menus[0].pendingQuantity, 3);
  assert.equal(today.menus[1].revenue, 0);
  assert.equal(today.hours[0].revenue, 18000);
  assert.equal(report(dashboard, 7).summary.revenue, 36000);
  assert.equal(report(dashboard, 1, '배달').summary.orderCount, 0);
  assert.equal(report(dashboard, 7, '배달').summary.orderCount, 1);
  assert.deepEqual(dashboard.queue.map(o => o.id), ['yesterday', 'unpaid']);
  assert.equal(dashboard.queue[0].elapsedMinutes, 10);
  assert.equal(dashboard.queue[0].targetMinutes, undefined);
  const real = fixture(); real.source = 'manual'; real.tickets[3].targetMinutes = 25;
  assert.equal(salesDashboard(real, now, true).queue[0].targetMinutes, undefined);
});

test('every sample report reconciles menu and hourly totals including zero orders', () => {
  for (const instant of [now, new Date('2026-09-19T15:00:00Z')]) {
    const sales = seedSales(instant);
    assert.ok(sales.tickets.every(t => Number.isInteger(t.targetMinutes) && t.targetMinutes > 0));
    assert.ok(sales.tickets.every(t => new Date(t.createdAt) <= instant));
    for (const r of salesDashboard(sales, instant, true).reports) {
      assert.equal(r.summary.revenue, r.menus.reduce((n, m) => n + m.revenue, 0));
      assert.equal(r.summary.revenue, r.hours.reduce((n, h) => n + h.revenue, 0));
      assert.equal(r.summary.orderCount, r.hours.reduce((n, h) => n + h.count, 0));
    }
  }
  const empty = salesDashboard({ ...fixture(), tickets: [] }, now, true);
  assert.equal(report(empty).summary.average, 0);
  assert.equal(report(empty).summary.revenue, 0);
  assert.deepEqual(empty.queue, []);
});

test('removed catalog menus keep their historical revenue', () => {
  const sales = fixture(); sales.menus = [];
  assert.equal(report(salesDashboard(sales, now, true)).menus[0].revenue, 18000);
});

test('existing shared demo migrates once, preserves records, and excludes financial data server-side', async t => {
  const dir = await mkdtemp(path.join(tmpdir(), 'tap2work-sales-'));
  t.after(() => rm(dir, { recursive: true, force: true }));
  const file = path.join(dir, 'demo.json');
  const existing = seedOperations(now);
  delete existing.sales;
  existing.activity = [{ message: '기존 기록 보존' }];
  await writeFile(file, JSON.stringify(existing));
  const store = new OperationsStore(file, () => now);
  const owner = await store.snapshot('owner');
  assert.ok(owner.dashboard.showMoney);
  assert.equal(owner.sales, undefined);
  const revision = owner.revision;
  for (const actor of ['crew', 'cook', 'manager']) {
    const view = await store.snapshot(actor);
    assert.equal(view.revision, revision);
    assert.equal(view.dashboard.showMoney, false);
    assert.equal(view.sales, undefined);
    const json = JSON.stringify(view.dashboard);
    for (const name of ['revenue', 'gross', 'discount', 'refund', 'average', 'unitPrice', 'price', 'soldQuantity']) assert.equal(json.includes(`"${name}"`), false, `${actor}: ${name}`);
  }
  const saved = JSON.parse(await readFile(file, 'utf8'));
  assert.deepEqual(saved.activity, existing.activity);
  assert.equal(saved.sales.tickets.length, 168);
  assert.equal((await store.snapshot('owner')).revision, revision);
});
