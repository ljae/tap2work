import { test } from 'node:test';
import assert from 'node:assert/strict';
import { mkdtemp, readFile, writeFile, rm } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import path from 'node:path';
import { OperationsStore, seedOperations } from '../operations.mjs';
import { checklistLibrary, checklistSlots, libraryTemplates } from '../checklists.mjs';
import { createConsoleServer } from '../server.mjs';
const OPEN = 'library-bonejjim-staff-open', PREP = 'library-bonejjim-bone-prep', CLOSE = 'library-bonejjim-kitchen-close';
async function setup(t) {
  const dir = await mkdtemp(path.join(tmpdir(), 'tap2work-checklists-'));
  t.after(() => rm(dir, { recursive: true, force: true }));
  const file = path.join(dir, 'ops.json');
  let now = new Date('2026-09-20T14:59:00Z');
  const clock = () => now;
  const store = new OperationsStore(file, clock);
  const act = async (action, values, role = 'owner') => store.mutate(role, { revision: (await store.snapshot(role)).revision, action, ...values });
  return { file, store, act, clock, midnight: () => { now = new Date('2026-09-20T15:00:00Z'); } };
}
const draft = state => ({ folders: state.checklistFolders, templates: state.taskTemplates });
test('global manual index and related words reach crew without private data or duplicate instances', async t => {
  const { store, act } = await setup(t);
  const owner = await store.snapshot('owner');
  const pos = owner.manualSearch.find(row => row.title === '금액 나눠 결제' && row.tapTitle.startsWith('토스'));
  assert.ok(pos?.sourceUrl.startsWith('https://tossplace.gitbook.io/'));
  assert.equal(owner.manualSearch.filter(row => row.id === pos.id).length, 1);
  const orderTap = owner.tasks.find(row => row.orderId && row.steps?.length);
  assert.ok(orderTap && owner.manualSearch.some(row => row.tapTitle === orderTap.title));
  const task = owner.tasks.find(row => row.templateId === PREP);
  const step = task.steps[0];
  const saved = await act('save_step_manual', { taskId: task.id, stepId: step.id, manual: '매장 승인 방법', tags: ['우동사리', '창고 위치'], sourceUrl: 'https://example.com/guide' });
  const result = saved.manualSearch.find(row => row.id === `${task.templateId}/${step.id}`);
  assert.deepEqual(result.tags, ['우동사리', '창고 위치']);
  assert.equal(result.sourceUrl, 'https://example.com/guide');
  assert.deepEqual(saved.tasks.find(row => row.id === task.id).steps[0].manualHistory[0].tags, step.tags ?? []);
  const crew = await store.snapshot('crew');
  assert.equal(crew.taskTemplates, undefined);
  assert.equal(crew.privateSummary, undefined);
  assert.ok(crew.manualSearch.some(row => row.id === result.id));
  await assert.rejects(act('save_step_manual', { taskId: task.id, stepId: step.id, manual: 'x', tags: ['a'.repeat(31)] }), { status: 400 });
  await assert.rejects(act('save_step_manual', { taskId: task.id, stepId: step.id, manual: 'x', tags: Array(21).fill('a') }), { status: 400 });
  const template = saved.taskTemplates.find(row => row.id === task.templateId);
  const changed = structuredClone(saved.taskTemplates);
  changed.find(row => row.id === template.id).steps[0].tags = ['국물 내는 법'];
  const catalogSaved = await act('save_checklists', { folders: saved.checklistFolders, templates: changed });
  assert.deepEqual(catalogSaved.taskTemplates.find(row => row.id === template.id).steps[0].tags, ['국물 내는 법']);
  assert.ok(catalogSaved.manualSearch.some(row => row.id === result.id && row.tags.includes('국물 내는 법')));
});
// The shape written by the first shared demo: three flat routine tasks and no manuals.
function legacySeed(now) {
  const state = seedOperations(now);
  delete state.checklistVersion; delete state.checklistFolders;
  const day = state.day, dueAt = new Date(now).toISOString();
  state.tasks = [
    { id: 'opening', title: '오늘의 공석과 인수인계 읽기', emoji: '👋', slot: '오픈', requiredRole: 'all', zone: 'entrance', dueAt, date: day, kind: 'routine', completedAt: null, completedBy: null },
    { id: 'prep', title: '전처리 도구와 작업대 준비', emoji: '🥣', slot: '준비', requiredRole: 'cook', zone: 'prep', dueAt, date: day, kind: 'routine', completedAt: null, completedBy: null },
    { id: 'close', title: '설거지 구역 정리 확인', emoji: '🫧', slot: '마감', requiredRole: 'crew', zone: 'sink', dueAt, date: day, kind: 'routine', completedAt: null, completedBy: null },
  ];
  state.taskTemplates = structuredClone(state.tasks);
  return state;
}
test('fresh demo starts with the 뼈찜 collection in its own folder, place and role hints applied', async t => {
  const { store } = await setup(t);
  const state = await store.snapshot('owner');
  const bone = checklistLibrary.industries.find(row => row.id === 'bonejjim');
  assert.equal(bone.tasks.length, 11);
  assert.ok(state.checklistFolders.some(f => f.id === 'order-work'));
  assert.ok(state.checklistFolders.some(f => f.id === 'bone-preparation'));
  assert.equal(state.taskTemplates.length, 16);
  assert.ok(state.taskTemplates.every(row => row.version === 1));
  const prep = state.taskTemplates.find(row => row.id === PREP);
  assert.equal(prep.zone, 'prep'); assert.equal(prep.requiredRole, 'cook'); assert.equal(prep.emoji, '🍖');
  assert.ok(state.tasks.find(row => row.templateId === 'library-bonejjim-break').slot === '브레이크');
  assert.ok(checklistSlots.includes('브레이크'));
  // A store without the hinted place falls back to its first place rather than failing.
  const other = libraryTemplates('bonejjim', [{ id: 'only' }]);
  assert.ok(other.templates.every(row => row.zone === 'only'));
  assert.equal((await store.snapshot('crew')).tasks.find(row => row.templateId === PREP).canComplete, false);
});
test('legacy migration preserves completed evidence and upgrades pending manuals once', async t => {
  const { file, store, clock } = await setup(t);
  const old = legacySeed(clock());
  old.tasks[0].completedAt = clock().toISOString(); old.tasks[0].completedBy = { name: '기존 담당' };
  await writeFile(file, JSON.stringify(old));
  const upgraded = await store.snapshot('owner');
  assert.equal(upgraded.tasks.filter(t => t.kind === 'routine' && !t.orderId && !t.preparedItemId).length, 8);
  assert.equal(upgraded.tasks.find(t => t.id === 'opening').steps, undefined);
  assert.equal(upgraded.tasks.find(t => t.id === 'opening').completedBy.name, '기존 담당');
  assert.equal(upgraded.tasks.find(t => t.id === 'prep').steps.length, 3);
  assert.ok(upgraded.checklistFolders.some(f => f.id === 'general'));
  assert.ok(upgraded.checklistFolders.some(f => f.id === 'order-work'));
  assert.deepEqual((await store.snapshot('owner')).revision, upgraded.revision);
});
test('steps have independent actors, cannot be bypassed, duplicated or completed by wrong role', async t => {
  const { store, act, file, clock } = await setup(t);
  const task = (await store.snapshot('owner')).tasks.find(t => t.templateId === PREP);
  await assert.rejects(act('complete_task', { taskId: task.id }, 'crew'), { status: 403 });
  await assert.rejects(act('complete_step', { taskId: task.id, stepId: task.steps[0].id }, 'crew'), { status: 403 });
  await assert.rejects(act('complete_step', { taskId: task.id, stepId: 'missing' }), { status: 404 });
  await act('complete_step', { taskId: task.id, stepId: task.steps[0].id }, 'cook');
  await assert.rejects(act('complete_step', { taskId: task.id, stepId: task.steps[0].id }), { status: 409 });
  for (const step of task.steps.slice(1)) await act('complete_step', { taskId: task.id, stepId: step.id });
  const reopened = (await new OperationsStore(file, clock).snapshot('owner')).tasks.find(t => t.id === task.id);
  assert.ok(reopened.completedAt); assert.equal(reopened.steps[0].completedBy.name, '현우'); assert.equal(reopened.steps[1].completedBy.name, '서연');
});
test('a mis-tapped activity can be reopened by its actor or a leader, only for today, and reopens the group', async t => {
  const { store, act, midnight } = await setup(t);
  const task = (await store.snapshot('owner')).tasks.find(t => t.templateId === OPEN);
  for (const step of task.steps) await act('complete_step', { taskId: task.id, stepId: step.id }, 'crew');
  assert.ok((await store.snapshot('crew')).tasks.find(t => t.id === task.id).completedAt);
  await assert.rejects(act('reopen_step', { taskId: task.id, stepId: task.steps[0].id }, 'cook'), { status: 400 });
  await assert.rejects(act('reopen_step', { taskId: task.id, stepId: 'missing' }, 'crew'), { status: 400 });
  const own = await act('reopen_step', { taskId: task.id, stepId: task.steps[0].id }, 'crew');
  const reopened = own.tasks.find(t => t.id === task.id);
  assert.equal(reopened.completedAt, null); assert.equal(reopened.steps[0].completedAt, undefined); assert.ok(reopened.steps[1].completedAt);
  assert.equal(reopened.canComplete, true);
  await assert.rejects(act('reopen_step', { taskId: task.id, stepId: task.steps[0].id }, 'crew'), { status: 400 });
  const lead = await act('reopen_step', { taskId: task.id, stepId: task.steps[1].id }, 'manager');
  assert.equal(lead.tasks.find(t => t.id === task.id).steps[1].completedAt, undefined);
  assert.match(lead.activity[0].message, /되돌림/);
  await act('complete_step', { taskId: task.id, stepId: task.steps[0].id }, 'cook');
  midnight();
  await assert.rejects(act('reopen_step', { taskId: task.id, stepId: task.steps[0].id }, 'cook'), { status: 409 });
});
test('editing regenerates unstarted work but preserves started and complete snapshots across Korean midnight', async t => {
  const { store, act, midnight, file } = await setup(t);
  let state = await store.snapshot('owner');
  const opening = state.tasks.find(t => t.templateId === OPEN);
  await act('complete_step', { taskId: opening.id, stepId: opening.steps[0].id });
  state = await store.snapshot('owner');
  const prep = state.tasks.find(t => t.templateId === PREP);
  const change = draft(state);
  change.templates.find(t => t.id === OPEN).steps[0].manual = '수정된 인수인계';
  const edited = change.templates.find(t => t.id === PREP); edited.title = '새 준비 업무'; edited.emoji = '🦴';
  const after = await act('save_checklists', change);
  assert.equal(after.tasks.find(t => t.id === opening.id).steps[0].manual, opening.steps[0].manual);
  assert.equal(after.tasks.find(t => t.title === '새 준비 업무').emoji, '🦴');
  assert.equal(after.tasks.some(t => t.id === prep.id), false);
  await assert.rejects(act('complete_step', { taskId: prep.id, stepId: prep.steps[0].id }), { status: 409 });
  assert.ok(JSON.parse(await readFile(file)).tasks.find(t => t.id === prep.id).archivedAt);
  midnight();
  const next = await store.snapshot('crew');
  assert.equal(next.day, '2026-09-21');
  const newOpening = next.tasks.find(t => t.templateId === OPEN);
  assert.equal(newOpening.steps[0].manual, '수정된 인수인계'); assert.equal(newOpening.steps[0].completedAt, undefined);
  await assert.rejects(act('complete_step', { taskId: opening.id, stepId: opening.steps[1].id }), { status: 409 });
});
test('folder moves, order and deletion are shared by every role without rewriting evidence', async t => {
  const { store, act, midnight, file } = await setup(t);
  let state = await store.snapshot('owner');
  const task = state.tasks.find(t => t.templateId === OPEN);
  for (const step of task.steps) await act('complete_step', { taskId: task.id, stepId: step.id });
  state = await store.snapshot('owner');
  state.checklistFolders.push({ id: 'kitchen', name: '주방' });
  const moved = state.taskTemplates.find(t => t.id === 'library-bonejjim-hall-close');
  state.taskTemplates = [moved, ...state.taskTemplates.filter(t => t.id !== moved.id)];
  moved.folderId = 'kitchen';
  await act('save_checklists', draft(state));
  const crew = await store.snapshot('crew');
  assert.equal(crew.taskTemplates, undefined);
  assert.equal(crew.tasks.find(t => t.templateId === 'library-bonejjim-hall-close').folderId, 'kitchen');
  assert.equal(crew.tasks.find(t => t.templateId === 'library-bonejjim-hall-close').displayOrder, 0);
  const empty = await act('save_checklists', { folders: [{ id: 'general', name: '기본' }, { id: 'bone-preparation', name: '뼈찜 조리' }], templates: [] });
  assert.equal(empty.tasks.filter(t => t.kind === 'routine' && !t.orderId && !t.preparedItemId).length, 1);
  assert.equal(empty.tasks.find(t => t.id === task.id).completedAt, (await store.snapshot('owner')).tasks.find(t => t.id === task.id).completedAt);
  assert.ok(empty.tasks.some(t => t.kind === 'stock'));
  midnight(); assert.equal((await store.snapshot('owner')).tasks.filter(t => t.kind === 'routine' && !t.orderId && !t.preparedItemId).length, 0);
  assert.ok(JSON.parse(await readFile(file)).tasks.find(t => t.id === task.id).completedAt);
});
test('deleted then reimported templates get distinct occurrence IDs', async t => {
  const { store, act } = await setup(t);
  const before = await store.snapshot('owner');
  const task = before.tasks.find(t => t.templateId === PREP);
  await act('save_checklists', { folders: before.checklistFolders, templates: [] });
  const after = await act('save_checklists', draft(before));
  const current = after.tasks.find(t => t.templateId === PREP);
  assert.notEqual(current.id, task.id);
  await act('complete_step', { taskId: current.id, stepId: current.steps[0].id });
});
test('stale drafts, forged permissions and invalid checklist data leave state intact', async t => {
  const { store, act } = await setup(t);
  const state = await store.snapshot('owner');
  await assert.rejects(act('save_checklists', draft(state), 'crew'), { status: 403 });
  for (const alter of [s => s.templates[0].steps = [], s => s.templates[0].steps.push(s.templates[0].steps[0]), s => s.templates[0].steps[0].manual = '', s => s.templates[0].steps[0].tip = '가'.repeat(401), s => s.templates[0].steps[0].tip = 123, s => s.templates[0].zone = 'missing', s => s.templates[0].folderId = 'missing', s => s.templates[0].slot = '야식', s => s.folders.push(s.folders[0]), s => s.templates.push(s.templates[0]), s => s.folders = [], s => s.templates[0] = null]) {
    const bad = structuredClone(draft(state)); alter(bad);
    await assert.rejects(act('save_checklists', bad), { status: 400 });
  }
  assert.equal((await store.snapshot('owner')).revision, state.revision);
  const long = structuredClone(draft(state)); long.templates[0].emoji = 'not an emoji';
  assert.equal((await act('save_checklists', long)).taskTemplates[0].emoji, '📝');
  await assert.rejects(store.mutate('owner', { action: 'save_checklists', revision: state.revision, ...draft(state) }), { status: 409 });
});
function fullCatalog(state) {
  const payload = draft(state);
  for (const industry of checklistLibrary.industries) {
    assert.ok(industry.tasks.length >= 2);
    for (const task of industry.tasks) {
      assert.ok(task.steps.length >= 3); assert.ok(task.sourceIds.every(id => checklistLibrary.sources.some(s => s.id === id)));
      assert.ok(task.steps.every(step => step.title && step.manual && step.tip));
      const id = `library-${industry.id}-${task.id}`;
      if (!payload.templates.some(row => row.id === id)) payload.templates.push({ ...task, id, folderId: 'general', requiredRole: 'all', zone: 'entrance' });
    }
  }
  return payload;
}
test('entire catalog validates and saves with sources and detailed instructions', async t => {
  const { store } = await setup(t);
  const state = await store.snapshot('owner');
  const payload = fullCatalog(state);
  const saved = await store.mutate('owner', { action: 'save_checklists', revision: state.revision, ...payload });
  assert.equal(saved.taskTemplates.length, payload.templates.length);
  assert.equal(saved.taskTemplates.length, checklistLibrary.industries.reduce((n, i) => n + i.tasks.length, 0) + 5);
});
test('HTTP accepts checklist drafts larger than the old 64 KiB limit', async t => {
  const { store, file, clock } = await setup(t);
  const state = await store.snapshot('owner');
  const payload = structuredClone(fullCatalog(state));
  const server = createConsoleServer({ operationsFile: file, operationsClock: clock });
  await new Promise(resolve => server.listen(0, '127.0.0.1', resolve)); t.after(() => new Promise(resolve => server.close(resolve)));
  const base = `http://127.0.0.1:${server.address().port}`;
  const snapshot = await fetch(`${base}/api/operations`, { headers: { 'x-demo-actor': 'owner' } }).then(r => r.json());
  for (const template of payload.templates) template.steps[0].manual = '현장 방법과 완료 기준을 확인해요. '.repeat(25);
  const body = JSON.stringify({ action: 'save_checklists', revision: snapshot.revision, ...payload });
  assert.ok(Buffer.byteLength(body) > 65536);
  const response = await fetch(`${base}/api/operations`, { method: 'POST', headers: { 'Content-Type': 'application/json', Origin: base, 'x-demo-actor': 'owner', 'x-demo-token': snapshot.demoToken }, body });
  assert.equal(response.status, 200); assert.equal((await response.json()).taskTemplates.length, payload.templates.length);
});

test('order and prep lanes stay separate; linked orders survive folder editing and synchronize Home', async t => {
  const { store, act } = await setup(t);
  let state = await store.snapshot('owner');
  const order = state.tasks.find(t => t.orderId);
  const preparation = state.tasks.find(t => t.templateId && t.folderId !== order.folderId);
  await assert.rejects(act('move_tap', { taskId: order.id, folderId: order.folderId, status: 'keep', beforeTaskId: preparation.id }), /삽입할 Tap/);
  state = await act('move_tap', { taskId: order.id, folderId: order.folderId, status: 'keep' });
  assert.equal(state.tasks.find(t => t.id === order.id).folderId, order.folderId);
  assert.equal(state.tasks.find(t => t.id === order.id).boardStatus, order.boardStatus);
  state = await act('save_checklists', draft(state));
  assert.ok(state.tasks.some(t => t.id === order.id));
  state = await act('move_tap', { taskId: order.id, folderId: order.folderId, status: 'done' });
  assert.ok(state.tasks.find(t => t.id === order.id).steps.every(s => s.completedAt));
  assert.ok(!state.dashboard.queue.some(t => t.id === order.orderId));
  state = await act('move_tap', { taskId: order.id, folderId: order.folderId, status: 'processing' });
  assert.ok(state.tasks.find(t => t.id === order.id).steps.every(s => !s.completedAt));
  assert.equal(state.dashboard.queue.find(t => t.id === order.orderId).status, '조리 중');
  assert.equal((await store.snapshot('owner')).tasks.filter(t => t.orderId === order.orderId).length, 1);
});
