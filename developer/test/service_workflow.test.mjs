import test from 'node:test';
import assert from 'node:assert/strict';
import {OperationsStore, seedOperations} from '../operations.mjs';

function fixture() {
  let now = new Date('2026-10-14T03:00:00Z'), state = seedOperations(now);
  const store = new OperationsStore(null, () => now, {persistence: {
    read: async () => structuredClone(state), save: async next => {state = structuredClone(next);},
  }});
  let sequence = 0;
  return {store, raw: () => state, advance: () => {now = new Date(now.getTime() + 86400000);},
    act: async (actor, action, values = {}) => store.mutate(actor, {
      action, revision: (await store.snapshot(actor)).revision, requestId: `test-${++sequence}`, ...values,
    })};
}

test('retired order execution never generates tasks, never mutates legacy evidence and leaves procurement available', async () => {
  const f = fixture(); await f.store.snapshot('owner');
  const legacy = {id: 'legacy-customer', orderId: 'legacy-ticket', date: '2026-09-01', kind: 'routine', folderId: 'order-work', title: '과거 주문', steps: [{id: 'old', completedAt: '2026-09-01T00:00:00Z'}], workIssue: {status: 'open'}};
  f.raw().tasks.push(legacy);
  f.raw().store.profile ??= {};
  f.raw().store.profile.orderSystem = {enabled: true, connectionStatus: 'not_connected'};
  const before = structuredClone(legacy), sales = structuredClone(f.raw().sales);
  for (const actor of ['owner', 'crew']) {
    const view = await f.store.snapshot(actor);
    assert.equal(view.orderBoardEnabled, false);
    assert.equal(view.store.profile.orderSystem, undefined);
    assert.deepEqual(view.dashboard.queue, []);
    assert.ok(view.tasks.every(t => !t.orderId));
    assert.equal(view.serviceRecords, undefined); assert.equal(view.serviceReceipts, undefined);
  }
  await assert.rejects(f.act('owner', 'save_order_system', {enabled: true}), {status: 410});
  await assert.rejects(f.act('owner', 'complete_step', {taskId: legacy.id, stepId: 'old'}), {status: 410});
  f.advance(); await f.store.snapshot('owner');
  assert.deepEqual(f.raw().tasks.find(t => t.id === legacy.id), before);
  assert.deepEqual(f.raw().sales, sales);
  const ordered = await f.act('owner', 'place_order', {lines: [{itemId: 'rice', quantity: 1}]});
  assert.equal(ordered.orders[0].status, 'ordered');
  const quantity = ordered.items.find(i => i.id === 'rice').quantity;
  const received = await f.act('owner', 'receive_order', {orderId: ordered.orders[0].id});
  assert.equal(received.items.find(i => i.id === 'rice').quantity, quantity + 1);
});

test('CS guides require owner review, are reference-only and cannot overwrite store edits', async () => {
  const f = fixture(), view = await f.store.snapshot('owner'), guide = view.serviceWorkflow.guides[0];
  await assert.rejects(f.act('crew', 'register_service_guide', {guideId: guide.id, reviewedHash: guide.hash}), {status: 403});
  await assert.rejects(f.act('owner', 'register_service_guide', {guideId: guide.id, reviewedHash: 'stale'}), {status: 409});
  const saved = await f.act('owner', 'register_service_guide', {guideId: guide.id, reviewedHash: guide.hash});
  const template = saved.taskTemplates.find(t => t.serviceGuideId === guide.id);
  assert.equal(template.settings.usage, 'reference'); assert.equal(template.settings.enabled, false);
  assert.ok(!saved.tasks.some(t => t.templateId === template.id));
  assert.ok(saved.manualSearch.some(t => t.templateId === template.id));
  assert.ok(saved.manualPrintTemplates.some(t => t.id === template.id));
  const edited = structuredClone(saved.taskTemplates);
  edited.find(t => t.id === template.id).steps[0].manual = '우리 매장 수정';
  await f.act('owner', 'save_checklists', {folders: saved.checklistFolders, templates: edited});
  assert.equal(f.raw().taskTemplates.find(t => t.id === template.id).serviceGuideId, guide.id);
  await f.store.snapshot('owner');
  assert.equal(f.raw().taskTemplates.find(t => t.id === template.id).steps[0].manual, '우리 매장 수정');
  await assert.rejects(f.act('owner', 'register_service_guide', {guideId: guide.id, reviewedHash: guide.hash}), {status: 409});
});

test('briefing acknowledgement freezes the viewed content and retry is idempotent across revisions', async () => {
  const f = fixture(); let view = await f.store.snapshot('owner');
  const ref = view.serviceWorkflow.manuals[0];
  view = await f.act('owner', 'save_service_briefing', {manualIds: [ref.id], note: '오늘 변경'});
  const tasks = structuredClone(f.raw().tasks);
  const request = {action: 'record_service', requestId: 'ack-once', revision: view.revision, kind: 'briefing', note: '', briefingHash: view.serviceWorkflow.briefing.hash};
  await f.store.mutate('crew', request);
  const record = structuredClone(f.raw().serviceRecords[0]);
  await f.act('owner', 'save_service_briefing', {manualIds: [], note: '새 안내'});
  await f.store.mutate('crew', request);
  assert.equal(f.raw().serviceRecords.length, 1);
  assert.deepEqual(f.raw().serviceRecords[0], record);
  assert.deepEqual(record.manuals[0], {id: ref.id, version: ref.version, hash: ref.hash});
  assert.deepEqual(f.raw().tasks, tasks);
  await assert.rejects(f.act('crew', 'record_service', {kind: 'briefing', note: '', briefingHash: request.briefingHash}), {status: 409});
  await assert.rejects(f.store.mutate('crew', {...request, note: 'different'}), {status: 409});
});

test('archived briefing manuals stop appearing without breaking the workspace', async () => {
  const f = fixture(); const view = await f.store.snapshot('owner'), ref = view.serviceWorkflow.manuals[0];
  await f.act('owner', 'save_service_briefing', {manualIds: [ref.id], note: ''});
  f.raw().taskTemplates.find(t => t.id === ref.id).archivedAt = '2026-10-14T03:00:00Z';
  assert.deepEqual((await f.store.snapshot('owner')).serviceWorkflow.briefing.manuals, []);
});

test('start briefing uses only own effective shifts with Korean business-day boundaries', async () => {
  const f = fixture(); await f.store.snapshot('crew');
  f.raw().workplace.businessDayStart = '10:00';
  f.raw().staffShifts.push(
    {id:'own-night',tapperId:'tapper-crew',date:'2026-10-15',start:'02:00',end:'04:00',partId:'hall',status:'planned'},
    {id:'other-night',tapperId:'tapper-cook',date:'2026-10-15',start:'02:00',end:'04:00',partId:'kitchen',status:'planned'},
    {id:'own-off',tapperId:'tapper-crew',date:'2026-10-14',start:'20:00',end:'22:00',partId:'hall',status:'leave'},
  );
  const shifts = (await f.store.snapshot('crew')).serviceWorkflow.ownShifts;
  assert.ok(shifts.some(s => s.id === 'own-night'));
  assert.ok(shifts.every(s => !['other-night','own-off'].includes(s.id)));
  assert.ok(shifts.every(s => !Object.hasOwn(s,'hourlyWon')));
});

test('unfinished handovers carry into the next business day; only recipient or authorized leader resolves', async () => {
  const f = fixture(); await f.act('crew', 'record_service', {kind: 'handoff', phase: 'closing', note: '不足', nextAction: '깨끗한 컵 보충', assigneeId: 'tapper-cook'});
  const handoff = f.raw().serviceRecords[0], tasks = structuredClone(f.raw().tasks);
  await assert.rejects(f.act('crew', 'resolve_service_handoff', {handoffId: handoff.id, note: '처리'}), {status: 403});
  f.advance(); const view = await f.store.snapshot('cook');
  assert.equal(view.serviceWorkflow.records.find(r => r.id === handoff.id).canResolve, true);
  await f.act('cook', 'resolve_service_handoff', {handoffId: handoff.id, note: '보충하고 다음 담당 확인'});
  assert.equal(f.raw().serviceRecords[0].at, handoff.at);
  assert.ok((await f.store.snapshot('crew')).serviceWorkflow.records[0].resolution);
  for (const task of tasks) assert.equal(f.raw().tasks.find(t => t.id === task.id).completedAt, task.completedAt);
});

test('self practice and buddy confirmation are distinct; changed manuals require new practice', async () => {
  const f = fixture(); const view = await f.store.snapshot('crew'), ref = view.serviceWorkflow.manuals[0];
  await f.act('crew', 'record_service', {kind: 'practice', templateId: ref.id, manualHash: ref.hash, buddyCrewId: 'tapper-cook', note: '시범 후 따라 해봄'});
  const practice = f.raw().serviceRecords[0];
  await assert.rejects(f.act('crew', 'confirm_service_practice', {practiceId: practice.id, note: '스스로 확인'}), {status: 403});
  await assert.rejects(f.act('manager', 'confirm_service_practice', {practiceId: practice.id, note: '버디 아님'}), {status: 403});
  const confirmed = await f.act('cook', 'confirm_service_practice', {practiceId: practice.id, note: '실제 안내를 관찰'});
  assert.equal(confirmed.serviceWorkflow.records[0].confirmation.actor.id, 'cook');
  assert.equal(f.raw().serviceRecords[0].actor.id, 'crew');
  await assert.rejects(f.act('cook', 'confirm_service_practice', {practiceId: practice.id, note: '중복'}), {status: 409});
  await f.act('crew', 'record_service', {kind: 'practice', templateId: ref.id, manualHash: ref.hash, buddyCrewId: 'tapper-cook', note: '다시 연습'});
  f.raw().taskTemplates.find(t => t.id === ref.id).steps[0].manual += '변경';
  await assert.rejects(f.act('cook', 'confirm_service_practice', {practiceId: f.raw().serviceRecords.at(-1).id, note: '구판 확인'}), {status: 409});
});

test('feedback is version-linked and private to its author and authorized leaders; counts are not satisfaction', async () => {
  const f = fixture(); let view = await f.store.snapshot('crew'); const ref = view.serviceWorkflow.manuals[0];
  await f.act('crew', 'record_service', {kind: 'feedback', templateId: ref.id, manualHash: ref.hash, note: '품절 전달 누락', cause: 'stock'});
  const record = f.raw().serviceRecords[0]; assert.equal(record.outcome, 'unmeasured'); assert.equal(record.manual.hash, ref.hash);
  assert.equal((await f.store.snapshot('cook')).serviceWorkflow.records.length, 0);
  assert.equal((await f.store.snapshot('owner')).serviceWorkflow.records.length, 1);
  f.raw().workplace.restrictions ??= {};
  f.raw().workplace.restrictions.manager = {tasks: false};
  assert.equal((await f.store.snapshot('manager')).serviceWorkflow.records.length, 0);
  await assert.rejects(f.act('manager', 'save_service_briefing', {manualIds: [], note: 'x'}), {status: 403});
  await assert.rejects(f.act('crew', 'record_service', {kind: 'feedback', templateId: ref.id, manualHash: 'stale', note: 'x', cause: 'manual'}), {status: 409});
  view = await f.store.snapshot('owner');
  assert.equal(view.serviceReceipts, undefined); assert.equal(view.serviceRecords, undefined);
  assert.equal(view.serviceWorkflow.satisfaction, undefined);
});


test('retirement preserves ordinary packing manuals while archiving known legacy order samples', async () => {
  const f = fixture(); await f.store.snapshot('owner');
  const original = structuredClone(f.raw().taskTemplates.find(t => !t.archivedAt));
  const ids = ['food-packing', 'custom-packing', 'packing'];
  for (const id of [...ids, 'demo-bone-order']) f.raw().taskTemplates.push({...structuredClone(original), id});
  await f.store.snapshot('owner');
  for (const id of ids) assert.equal(f.raw().taskTemplates.find(t => t.id === id).archivedAt, undefined, id);
  assert.ok(f.raw().taskTemplates.find(t => t.id === 'demo-bone-order').archivedAt);
});
