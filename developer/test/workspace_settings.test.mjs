import { test } from 'node:test';
import assert from 'node:assert/strict';
import { OperationsStore, emptyOperations } from '../operations.mjs';
import { completeStepIssue, bulkCompleteIssue } from '../task_settings.mjs';

function fixture(role = 'owner') {
  let now = new Date('2026-09-27T14:30:00Z'); // Sunday 23:30 Korea.
  let state = emptyOperations(now, 'owner-1', '사장님');
  const actor = { id: role === 'owner' ? 'owner-1' : 'crew-1', name: role === 'owner' ? '사장님' : '크루', role };
  const store = new OperationsStore(null, () => now, { actor, persistence: {
    read: async () => structuredClone(state),
    save: async (next, revision) => { assert.equal(revision, state.revision); state = structuredClone(next); },
  } });
  const act = async (action, values = {}) => {
    const view = await store.snapshot(actor.id);
    return store.mutate(actor.id, { action, revision: view.revision, ...values });
  };
  return { act, store, raw: () => state, next: date => { now = new Date(date); } };
}

test('store profile uses optional sections, preserves other sections, and hides owner-only configuration', async () => {
  const x = fixture();
  await assert.rejects(() => x.act('save_store_profile', { section: 'basic', values: { name: '서울 식당' } }), { status: 400 });
  await x.act('save_store_profile', { section: 'basic', values: { name: '서울 식당', industryId: 'restaurant', serviceModes: ['hall'], note: '주방팀' } });
  assert.equal(x.raw().store.note, '주방팀');
  assert.equal(x.raw().store.profile.pos, undefined);
  await x.act('save_store_profile', { section: 'pos', values: { configured: true, enabled: true,
    devices: [{ id: 'pos-1', providerId: 'okpos', count: 1, functions: ['orders', 'receipt'], guideUrl: '' }] } });
  const saved = await x.act('save_store', { name: '이름만 변경', note: '' });
  assert.equal(saved.store.profile.industryId, 'restaurant');
  assert.equal(saved.store.profile.pos.devices[0].providerId, 'okpos');
  assert.equal(saved.store.note, '');
  await assert.rejects(() => x.act('save_store_profile', { section: 'delivery', values: { configured: true, enabled: true, platforms: [] } }), { status: 400 });
  const crew = fixture('crew');
  await assert.rejects(() => crew.act('save_store_profile', { section: 'basic', values: { name: 'x', industryId: 'cafe' } }), { status: 403 });
  assert.equal((await crew.store.snapshot()).store.profile, undefined);
});

test('settings apply from next Korean day and quantity, order and bulk policy are enforced on server', async () => {
  const x = fixture();
  const first = await x.act('save_checklists', { folders: [{ id: 'general', name: '기본 업무' }], templates: [{
    id: 'clean', title: '마감 청소', emoji: '🧹', folderId: 'general', slot: '마감', requiredRole: 'all', zone: null,
    steps: [{ id: 'wash', title: '설거지', manual: '실제 수량을 세요.', tip: '' },
      { id: 'wipe', title: '닦기', manual: '순서대로 닦아요.', tip: '' }], sourceIds: [],
  }] });
  const today = first.tasks.find(row => row.templateId === 'clean');
  const settings = { type: 'cleaning', enabled: true, recurrence: { mode: 'weekly', weekdays: [1] },
    allowBulkComplete: false, enforceSequence: true };
  await x.act('save_tap_settings', { templateId: 'clean', settings,
    steps: [{ id: 'wash', settings: { completionKind: 'quantity', quantitySpec: { unit: '개', decimalPlaces: 0 } } },
      { id: 'wipe', settings: { completionKind: 'check' } }] });
  assert.equal(x.raw().tasks.find(row => row.id === today.id).settings, undefined);
  x.next('2026-09-27T15:05:00Z'); // Monday 00:05 Korea.
  const monday = await x.store.snapshot();
  const task = monday.tasks.find(row => row.templateId === 'clean');
  assert.ok(task);
  assert.notEqual(task.id, today.id);
  assert.equal(task.settings.enforceSequence, true);
  await assert.rejects(() => x.act('complete_task', { taskId: task.id }), { status: 409 });
  await assert.rejects(() => x.act('move_tap', { taskId: task.id, folderId: 'general', status: 'done' }), { status: 409 });
  await assert.rejects(() => x.act('complete_step', { taskId: task.id, stepId: 'wipe' }), { status: 409 });
  await assert.rejects(() => x.act('complete_step', { taskId: task.id, stepId: 'wash' }), { status: 409 });
  await x.act('complete_step', { taskId: task.id, stepId: 'wash', quantity: 4 });
  const done = await x.act('complete_step', { taskId: task.id, stepId: 'wipe' });
  assert.equal(done.tasks.find(row => row.id === task.id).completedAt != null, true);
  assert.equal(x.raw().tasks.find(row => row.id === task.id).steps[0].actualQuantity, 4);
  assert.equal(x.raw().items.length, 0);
  x.next('2026-09-28T15:05:00Z'); // Tuesday 00:05 Korea.
  assert.equal((await x.store.snapshot()).tasks.some(row => row.templateId === 'clean'), false);
});

test('hiring drafts are owner-only and never create crew records', async () => {
  const x = fixture();
  const view = await x.act('save_hiring_draft', { roleId: 'cook', headcount: 2, weekdays: [1, 3, 5], responsibilities: '조리 준비' });
  assert.equal(view.hiringDrafts[0].status, 'draft');
  assert.equal(view.tappers.length, 1);
  await x.act('archive_hiring_draft', { id: view.hiringDrafts[0].id });
  assert.equal(x.raw().hiringDrafts[0].status, 'archived');
  const crew = fixture('crew');
  await assert.rejects(() => crew.act('save_hiring_draft', { roleId: 'cook', headcount: 1 }), { status: 403 });
  assert.equal((await crew.store.snapshot()).hiringDrafts, undefined);
});

test('configured delivery recommends selectable tasks without importing twice or changing stock', async () => {
  const x = fixture();
  await x.act('save_store_profile', { section: 'delivery', values: { configured: true, enabled: true,
    platforms: [{ id: 'baemin', providerId: 'baemin', acceptanceMode: 'direct', printTicket: false, handoffMode: 'rider' }] } });
  const view = await x.store.snapshot();
  const ids = view.recommendedTaps.map(row => row.id);
  assert.deepEqual(ids, ['delivery-order-review', 'delivery-handoff-review']);
  const imported = await x.act('import_recommended_taps', { ids: [ids[0]] });
  assert.equal(imported.recommendedTaps.find(row => row.id === ids[0]).alreadyAdded, true);
  assert.equal(imported.taskTemplates.length, 1);
  assert.equal(imported.items.length, 0);
  await assert.rejects(() => x.act('import_recommended_taps', { ids: [ids[0]] }), { status: 409 });
  await x.act('save_store_profile', { section: 'delivery', values: { configured: true, enabled: false, platforms: [] } });
  assert.equal((await x.store.snapshot()).taskTemplates.length, 1);
});

test('step role overrides and decimal precision are checked before completion', () => {
  const task = { requiredRole: 'all', settings: { allowBulkComplete: true, enforceSequence: false },
    steps: [{ id: 'weight', completedAt: null, settings: { roleOverride: 'cook', completionKind: 'quantity',
      quantitySpec: { unit: 'kg', decimalPlaces: 2 } } }] };
  const crew = { role: 'crew' }, cook = { role: 'cook' };
  assert.match(completeStepIssue(crew, task, task.steps[0], 1.25), /담당 역할/);
  assert.match(completeStepIssue(cook, task, task.steps[0], 1.234), /소수 2자리/);
  assert.equal(completeStepIssue(cook, task, task.steps[0], 1.01), null);
  assert.match(bulkCompleteIssue(cook, task), /실제 수량/);
});
