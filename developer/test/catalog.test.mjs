import { test } from 'node:test';
import assert from 'node:assert/strict';
import { OperationsStore, emptyOperations, seedOperations } from '../operations.mjs';

const now = new Date('2026-09-26T05:00:00Z');
function setup({ sample = false, role = 'owner' } = {}) {
  let state = sample ? seedOperations(now) : emptyOperations(now, 'user-1', '사장님');
  const store = new OperationsStore(null, () => now, {
    actor: { id: 'user-1', name: '사장님', role, label: role === 'owner' ? '사장님' : '크루' },
    persistence: { read: async () => structuredClone(state), save: async (next, revision) => {
      assert.equal(revision, state.revision); state = structuredClone(next);
    } },
  });
  const mutate = async (action, values = {}) => {
    const view = await store.snapshot('forged-owner');
    return store.mutate('forged-owner', { action, revision: view.revision, ...values });
  };
  return { store, mutate, raw: () => state };
}

test('blank workspace stays blank across snapshots and catalog edits keep stock counting separate', async () => {
  const { store, mutate } = setup();
  let view = await store.snapshot();
  assert.equal(view.items.length, 0);
  assert.equal(view.tasks.length, 0);
  assert.equal(view.catalogMenus.length, 0);
  assert.equal(view.dashboard.queue.length, 0);
  await mutate('save_store', { name: '실제 식당', note: '주방팀' });
  view = await mutate('save_inventory_item', { name: '배추', unit: '포기', supplier: '시장', zone: '', emoji: '🥬', minimum: 2, orderQuantity: 5, price: 3000, reviewDays: 4 });
  const item = view.items[0];
  assert.equal(item.quantity, 0);
  assert.equal(item.zone, null);
  assert.equal(view.store.name, '실제 식당');
  const staleRevision = view.revision;
  view = await mutate('save_menu', { name: '김치찌개', category: '식사', price: 9000 });
  assert.equal(view.catalogMenus[0].name, '김치찌개');
  assert.equal((await store.snapshot()).tasks.length, 0);
  await assert.rejects(() => store.mutate('user-1', { action: 'save_menu', revision: staleRevision, name: '낡은 편집', category: '식사', price: 1 }), { status: 409 });
});

test('archival retains historical order lines and blocks pending receipt or active ticket', async () => {
  const { mutate, raw } = setup({ sample: true });
  const snapshot = await mutate('save_store', { name: '우리 식당', note: '' });
  const item = snapshot.items[0], menu = snapshot.catalogMenus.find(row => row.id === 'tea');
  raw().orders.push({ id: 'PO-test', status: 'ordered', lines: [{ itemId: item.id }] });
  await assert.rejects(() => mutate('archive_inventory_item', { id: item.id }), { status: 409 });
  raw().orders.pop();
  await assert.rejects(() => mutate('archive_menu', { id: menu.id }), { status: 409 });
  const ticket = raw().sales.tickets.find(row => ['접수', '조리 중', '준비 완료'].includes(row.status) && row.lines.some(line => line.menuId === menu.id));
  for (const row of raw().sales.tickets) if (row.lines.some(line => line.menuId === menu.id)) row.status = '완료';
  const archived = await mutate('archive_menu', { id: menu.id });
  assert.ok(!archived.catalogMenus.find(row => row.id === menu.id && !row.archivedAt));
  assert.equal(ticket.lines[0].name, raw().sales.tickets.find(row => row.id === ticket.id).lines[0].name);
  assert.ok(raw().sales.menus.find(row => row.id === menu.id).archivedAt);
});

test('crew cannot alter identity or catalogs; archived sample backup is not projected', async () => {
  const crew = setup({ role: 'crew' });
  await assert.rejects(() => crew.mutate('save_store', { name: '다른 매장', note: '' }), { status: 403 });
  await assert.rejects(() => crew.mutate('save_menu', { name: '메뉴', category: '식사', price: 1000 }), { status: 403 });
  const owner = setup({ sample: true });
  const view = await owner.mutate('start_blank_from_sample');
  assert.equal(view.items.length, 0);
  assert.equal(view.dashboard.queue.length, 0);
  assert.equal(view.sampleArchive, undefined);
  assert.equal(view.hasSampleArchive, true);
  assert.ok(owner.raw().sampleArchive.state.items.length > 0);
  assert.equal((await owner.store.snapshot()).tasks.length, 0);
});
