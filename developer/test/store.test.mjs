import { test } from 'node:test';
import assert from 'node:assert/strict';
import { mkdtemp, writeFile, readFile, readdir, rm } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import path from 'node:path';
import { ProjectStore } from '../store.mjs';
import { createConsoleServer } from '../server.mjs';

const fixture = {
  schemaVersion: 1, revision: 1, product: { name: 'test' }, milestones: [], history: [],
  decisions: [{ id: 'D-001', category: '교육', title: '교육 자료', status: 'proposed', decision: '아직 미정', reason: '매장 확인 필요', source: 'test', updatedAt: '2026-09-19' }],
};
const update = { revision: 1, category: '교육', title: '교육 자료', status: 'confirmed', decision: '사진과 짧은 설명', reason: '제작과 갱신이 쉬움', changeReason: '테스트 매장의 제작 여건 확인' };
async function setup(t) {
  const dir = await mkdtemp(path.join(tmpdir(), 'tap2work-console-test-'));
  t.after(() => rm(dir, { recursive: true, force: true }));
  const filename = path.join(dir, 'project-state.json');
  await writeFile(filename, JSON.stringify(fixture));
  return { dir, filename, store: new ProjectStore(filename) };
}

test('saving a decision persists before/after history and a recoverable previous file', async t => {
  const { store, filename, dir } = await setup(t);
  const result = await store.updateDecision('D-001', update);
  assert.equal(result.revision, 2);
  const disk = JSON.parse(await readFile(filename, 'utf8'));
  assert.equal(disk.decisions[0].status, 'confirmed');
  assert.equal(disk.history[0].before.status, 'proposed');
  assert.equal(disk.history[0].after.decision, update.decision);
  assert.equal(disk.history[0].detail, update.changeReason);
  const backups = await readdir(path.join(dir, 'history-backups'));
  const previous = JSON.parse(await readFile(path.join(dir, 'history-backups', backups[0]), 'utf8'));
  assert.deepEqual(previous, fixture);
});

test('two clients cannot silently overwrite one another', async t => {
  const { store } = await setup(t);
  const results = await Promise.allSettled([
    store.updateDecision('D-001', update),
    store.updateDecision('D-001', { ...update, decision: '다른 창의 변경' }),
  ]);
  assert.equal(results[0].status, 'fulfilled');
  assert.equal(results[1].status, 'rejected');
  assert.equal(results[1].reason.status, 409);
  assert.equal((await store.read()).history.length, 1);
});

test('invalid and missing changes leave the original file untouched', async t => {
  const { store } = await setup(t);
  await assert.rejects(store.updateDecision('D-999', update), { status: 404 });
  assert.throws(() => store.updateDecision('D-001', { ...update, changeReason: '' }), { status: 400 });
  assert.throws(() => store.updateDecision('D-001', { ...update, status: 'unknown' }), { status: 400 });
  assert.deepEqual(await store.read(), fixture);
});

test('new decisions receive stable IDs and new history entries preserve prior records', async t => {
  const { store } = await setup(t);
  const added = await store.addDecision(update);
  assert.equal(added.decisions[1].id, 'D-002');
  const final = await store.addHistory({ revision: 2, type: 'test', title: '실제 테스트', detail: '저장 왕복 확인', verification: '파일을 다시 읽음' });
  assert.equal(final.history.length, 2);
  assert.equal(final.history[0].after.id, 'D-002');
});

test('HTTP workflow requires same-origin session token and handles revision conflicts', async t => {
  const { filename } = await setup(t);
  const server = createConsoleServer({ stateFile: filename, appRoot: path.join(path.dirname(filename), 'missing-build') });
  await new Promise(resolve => server.listen(0, '127.0.0.1', resolve));
  t.after(() => new Promise(resolve => server.close(resolve)));
  const base = `http://127.0.0.1:${server.address().port}`;
  const session = await fetch(`${base}/api/session`).then(res => res.json());
  assert.equal((await fetch(`${base}/api/project`).then(res => res.json())).revision, 1);
  assert.equal((await fetch(`${base}/api/preview`).then(res => res.json())).ready, false);
  const patch = (headers, value = update) => fetch(`${base}/api/decisions/D-001`, { method: 'PATCH', headers: { 'Content-Type': 'application/json', ...headers }, body: JSON.stringify(value) });
  assert.equal((await patch({ Origin: base })).status, 403);
  assert.equal((await patch({ Origin: 'https://example.com', 'X-Tab2work-Token': session.token })).status, 403);
  const headers = { Origin: base, 'X-Tab2work-Token': session.token };
  assert.equal((await patch(headers)).status, 200);
  assert.equal((await patch(headers)).status, 409);
  const state = await fetch(`${base}/api/project`).then(res => res.json());
  assert.equal(state.decisions[0].decision, update.decision);
  assert.equal(state.history.length, 1);
  assert.equal((await fetch(`${base}/app/%2e%2e%2fproject-state.json`)).status, 400);
});
