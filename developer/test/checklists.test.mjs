import { test } from 'node:test';
import assert from 'node:assert/strict';
import { mkdtemp, readFile, writeFile, rm } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import path from 'node:path';
import { OperationsStore, seedOperations } from '../operations.mjs';
import { checklistLibrary } from '../checklists.mjs';
import { createConsoleServer } from '../server.mjs';
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
test('legacy migration preserves completed evidence and upgrades pending manuals once', async t => {
  const { file, store, clock } = await setup(t);
  const old = seedOperations(clock());
  old.taskTemplates = structuredClone(old.tasks);
  old.tasks[0].completedAt = clock().toISOString(); old.tasks[0].completedBy = { name: '기존 담당' };
  await writeFile(file, JSON.stringify(old));
  const upgraded = await store.snapshot('owner');
  assert.equal(upgraded.tasks.filter(t => t.kind === 'routine').length, 3);
  assert.equal(upgraded.tasks.find(t => t.id === 'opening').steps, undefined);
  assert.equal(upgraded.tasks.find(t => t.id === 'opening').completedBy.name, '기존 담당');
  assert.equal(upgraded.tasks.find(t => t.id === 'prep').steps.length, 3);
  assert.deepEqual((await store.snapshot('owner')).revision, upgraded.revision);
});
test('steps have independent actors, cannot be bypassed, duplicated or completed by wrong role', async t => {
  const { store, act, file, clock } = await setup(t);
  const task = (await store.snapshot('owner')).tasks.find(t => t.templateId === 'prep');
  await assert.rejects(act('complete_task', { taskId: task.id }), { status: 400 });
  await assert.rejects(act('complete_step', { taskId: task.id, stepId: task.steps[0].id }, 'crew'), { status: 403 });
  await assert.rejects(act('complete_step', { taskId: task.id, stepId: 'missing' }), { status: 404 });
  await act('complete_step', { taskId: task.id, stepId: task.steps[0].id }, 'cook');
  await assert.rejects(act('complete_step', { taskId: task.id, stepId: task.steps[0].id }), { status: 409 });
  for (const step of task.steps.slice(1)) await act('complete_step', { taskId: task.id, stepId: step.id });
  const reopened = (await new OperationsStore(file, clock).snapshot('owner')).tasks.find(t => t.id === task.id);
  assert.ok(reopened.completedAt); assert.equal(reopened.steps[0].completedBy.name, '현우'); assert.equal(reopened.steps[1].completedBy.name, '서연');
});
test('editing regenerates unstarted work but preserves started and complete snapshots across Korean midnight', async t => {
  const { store, act, midnight, file } = await setup(t);
  let state = await store.snapshot('owner');
  const opening = state.tasks.find(t => t.templateId === 'opening');
  await act('complete_step', { taskId: opening.id, stepId: opening.steps[0].id });
  state = await store.snapshot('owner');
  const prep = state.tasks.find(t => t.templateId === 'prep');
  const change = draft(state);
  change.templates.find(t => t.id === 'opening').steps[0].manual = '수정된 인수인계';
  change.templates.find(t => t.id === 'prep').title = '새 준비 업무';
  const after = await act('save_checklists', change);
  assert.equal(after.tasks.find(t => t.id === opening.id).steps[0].manual, opening.steps[0].manual);
  assert.ok(after.tasks.find(t => t.title === '새 준비 업무'));
  assert.equal(after.tasks.some(t => t.id === prep.id), false);
  await assert.rejects(act('complete_step', { taskId: prep.id, stepId: prep.steps[0].id }), { status: 409 });
  assert.ok(JSON.parse(await readFile(file)).tasks.find(t => t.id === prep.id).archivedAt);
  midnight();
  const next = await store.snapshot('crew');
  assert.equal(next.day, '2026-09-21');
  const newOpening = next.tasks.find(t => t.templateId === 'opening');
  assert.equal(newOpening.steps[0].manual, '수정된 인수인계'); assert.equal(newOpening.steps[0].completedAt, undefined);
  await assert.rejects(act('complete_step', { taskId: opening.id, stepId: opening.steps[1].id }), { status: 409 });
});
test('folder moves, order and deletion are shared by every role without rewriting evidence', async t => {
  const { store, act, midnight, file } = await setup(t);
  let state = await store.snapshot('owner');
  const task = state.tasks.find(t => t.templateId === 'opening');
  for (const step of task.steps) await act('complete_step', { taskId: task.id, stepId: step.id });
  state = await store.snapshot('owner');
  state.checklistFolders.push({ id: 'kitchen', name: '주방' });
  state.taskTemplates.reverse(); state.taskTemplates[0].folderId = 'kitchen';
  await act('save_checklists', draft(state));
  const crew = await store.snapshot('crew');
  assert.equal(crew.taskTemplates, undefined);
  assert.equal(crew.tasks.find(t => t.templateId === 'close').folderId, 'kitchen');
  assert.equal(crew.tasks.find(t => t.templateId === 'close').displayOrder, 0);
  const empty = await act('save_checklists', { folders: [{ id: 'general', name: '기본' }], templates: [] });
  assert.equal(empty.tasks.filter(t => t.kind === 'routine').length, 1);
  assert.equal(empty.tasks.find(t => t.id === task.id).completedAt, (await store.snapshot('owner')).tasks.find(t => t.id === task.id).completedAt);
  assert.ok(empty.tasks.some(t => t.kind === 'stock'));
  midnight(); assert.equal((await store.snapshot('owner')).tasks.filter(t => t.kind === 'routine').length, 0);
  assert.ok(JSON.parse(await readFile(file)).tasks.find(t => t.id === task.id).completedAt);
});
test('deleted then reimported templates get distinct occurrence IDs', async t => {
  const { store, act } = await setup(t);
  const before = await store.snapshot('owner');
  const task = before.tasks.find(t => t.templateId === 'prep');
  await act('save_checklists', { folders: before.checklistFolders, templates: [] });
  const after = await act('save_checklists', draft(before));
  const current = after.tasks.find(t => t.templateId === 'prep');
  assert.notEqual(current.id, task.id);
  await act('complete_step', { taskId: current.id, stepId: current.steps[0].id });
});
test('stale drafts, forged permissions and invalid checklist data leave state intact', async t => {
  const { store, act } = await setup(t);
  const state = await store.snapshot('owner');
  await assert.rejects(act('save_checklists', draft(state), 'crew'), { status: 403 });
  for (const alter of [s => s.templates[0].steps = [], s => s.templates[0].steps.push(s.templates[0].steps[0]), s => s.templates[0].steps[0].manual = '', s => s.templates[0].steps[0].tip = '가'.repeat(401), s => s.templates[0].steps[0].tip = 123, s => s.templates[0].zone = 'missing', s => s.templates[0].folderId = 'missing', s => s.folders.push(s.folders[0]), s => s.templates.push(s.templates[0]), s => s.folders = [], s => s.templates[0] = null]) {
    const bad = structuredClone(draft(state)); alter(bad);
    await assert.rejects(act('save_checklists', bad), { status: 400 });
  }
  assert.equal((await store.snapshot('owner')).revision, state.revision);
  await act('save_checklists', draft(state));
  await assert.rejects(store.mutate('owner', { action: 'save_checklists', revision: state.revision, ...draft(state) }), { status: 409 });
});
test('entire catalog validates and saves with sources and detailed instructions', async t => {
  const { store, file, clock } = await setup(t);
  const state = await store.snapshot('owner');
  const payload = draft(state);
  for (const industry of checklistLibrary.industries) {
    assert.ok(industry.tasks.length >= 2);
    for (const task of industry.tasks) {
      assert.ok(task.steps.length >= 3); assert.ok(task.sourceIds.every(id => checklistLibrary.sources.some(s => s.id === id)));
      assert.ok(task.steps.every(step => step.title && step.manual && step.tip));
      payload.templates.push({ ...task, id: `library-${industry.id}-${task.id}`, folderId: 'general', requiredRole: 'all', zone: 'entrance' });
    }
  }
  const saved = await store.mutate('owner', { action: 'save_checklists', revision: state.revision, ...payload });
  assert.equal(saved.taskTemplates.length, payload.templates.length);
});
test('HTTP accepts checklist drafts larger than the old 64 KiB limit', async t => {
  const { store, file, clock } = await setup(t);
  const state = await store.snapshot('owner');
  const payload = draft(state);
  for (const industry of checklistLibrary.industries) for (const task of industry.tasks) {
    payload.templates.push({ ...task, id: `library-${industry.id}-${task.id}`, folderId: 'general', requiredRole: 'all', zone: 'entrance' });
  }
  const server = createConsoleServer({ operationsFile: file, operationsClock: clock });
  await new Promise(resolve => server.listen(0, '127.0.0.1', resolve)); t.after(() => new Promise(resolve => server.close(resolve)));
  const base = `http://127.0.0.1:${server.address().port}`;
  const snapshot = await fetch(`${base}/api/operations`, { headers: { 'x-demo-actor': 'owner' } }).then(r => r.json());
  payload.templates = structuredClone(payload.templates);
  for (const template of payload.templates) template.steps[0].manual = '현장 방법과 완료 기준을 확인해요. '.repeat(25);
  const body = JSON.stringify({ action: 'save_checklists', revision: snapshot.revision, ...payload });
  assert.ok(Buffer.byteLength(body) > 65536);
  const response = await fetch(`${base}/api/operations`, { method: 'POST', headers: { 'Content-Type': 'application/json', Origin: base, 'x-demo-actor': 'owner', 'x-demo-token': snapshot.demoToken }, body });
  assert.equal(response.status, 200); assert.equal((await response.json()).taskTemplates.length, payload.templates.length);
});
