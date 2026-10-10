import test from 'node:test';
import assert from 'node:assert/strict';
import { cleanupDeletedWorkspaceMedia } from '../manual_media_cleanup.mjs';
import { createAccountHandler } from '../account_backend.mjs';
const name = 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb.jpg';
function fixture({ storageFailure = false, exists = false } = {}) {
  const calls = [], jobs = [{ workspace_id: 'store-a' }];
  let objects = [{ name }];
  const fetcher = async (url, options = {}) => {
    calls.push({ url, options });
    if (url.includes('/tap2work_media_deletions?')) {
      if (options.method === 'PATCH') return new Response(null, { status: 204 });
      return Response.json(jobs);
    }
    if (url.includes('/tap2work_workspaces?')) return Response.json(exists ? [{ id: 'store-a' }] : []);
    if (storageFailure) return Response.json({ private: 'detail' }, { status: 503 });
    if (url.includes('/object/list/')) return Response.json(objects);
    if (options.method === 'DELETE') { objects = []; return Response.json([]); }
    throw Error('Unexpected cleanup call');
  };
  return { calls, jobs, fetcher, run: () => cleanupDeletedWorkspaceMedia({ url: 'https://example.invalid', headers: { apikey: 'fixture' }, fetcher }) };
}
test('whole-workspace cleanup deletes only the queued prefix, retains tombstone for late uploads', async () => {
  const f = fixture(), result = await f.run();
  assert.deepEqual(result, { pending: false, processed: 1 });
  const deletion = f.calls.find(c => c.options.method === 'DELETE');
  assert.deepEqual(JSON.parse(deletion.options.body).prefixes, [`store-a/${name}`]);
  assert.equal(f.jobs.length, 1);
  const patch = f.calls.find(c => c.options.method === 'PATCH');
  assert.ok(JSON.parse(patch.options.body).next_attempt_at);
  assert.ok(!f.calls.some(c => c.options.method === 'DELETE' && c.url.includes('/rest/')));
});
test('cleanup failure stays queued and live workspaces never have photos removed', async () => {
  for (const options of [{ storageFailure: true }, { exists: true }]) {
    const f = fixture(options), result = await f.run();
    assert.equal(result.pending, true); assert.equal(f.jobs.length, 1);
    assert.ok(!f.calls.some(c => c.options.method === 'DELETE'));
    assert.equal(f.calls.filter(c => c.options.method === 'PATCH').length, 1);
    assert.ok(JSON.parse(f.calls.find(c => c.options.method === 'PATCH').options.body).next_attempt_at);
  }
});
test('erasure CAS failure never touches Storage, successful erase with Storage outage remains durably pending', async () => {
  const uid = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
  for (const conflict of [true, false]) {
    const cleanup = fixture({ storageFailure: true });
    let erased = false;
    const handler = createAccountHandler({ url: 'https://example.invalid', serviceKey: 'fixture', appleRevoker: async () => {}, fetcher: async (url, options) => {
      if (url.endsWith('/auth/v1/user')) return Response.json({ id: uid });
      if (url.endsWith('/tap2work_account_context')) return Response.json({ scope: { workspaceId: 'store-a', role: 'owner', ownerCount: 1, memberCount: 1, revision: 1 } });
      if (url.endsWith('/tap2work_erase_account')) { erased = !conflict; return Response.json(conflict ? { conflict: true } : { deleted: true }); }
      assert.equal(erased, true);
      return cleanup.fetcher(url, options);
    } });
    const request = body => handler(new Request('https://example.invalid/account', { method: 'POST', headers: { Authorization: 'Bearer fixture', 'Content-Type': 'application/json' }, body: JSON.stringify(body) }));
    const preview = await (await request({ action: 'preview_delete' })).json();
    const response = await request({ action: 'delete_account', confirmationToken: preview.confirmationToken, confirmWorkspaceDeletion: true });
    assert.equal(response.status, conflict ? 409 : 200);
    if (conflict) assert.equal(cleanup.calls.length, 0);
    else { assert.deepEqual(await response.json(), { deleted: true, mediaCleanupPending: true }); assert.equal(cleanup.jobs.length, 1); }
  }
});
test('twenty failed cleanup jobs back off so later due workspace deletions can run', async () => {
  const now = new Date('2026-10-10T04:00:00Z');
  const jobs = Array.from({ length: 21 }, (_, index) => ({ workspace_id: `store-${index}`, next_attempt_at: new Date(now.getTime() - 60000).toISOString() }));
  const patches = [];
  const fetcher = async (url, options = {}) => {
    if (url.includes('/tap2work_media_deletions?')) {
      if (options.method === 'PATCH') {
        const id = new URL(url).searchParams.get('workspace_id').slice(3);
        const patch = JSON.parse(options.body);
        Object.assign(jobs.find(j => j.workspace_id === id), patch);
        patches.push({ id, ...patch });
        return new Response(null, { status: 204 });
      }
      return Response.json(jobs.filter(j => Date.parse(j.next_attempt_at) <= now.getTime()).sort((a, b) => a.next_attempt_at.localeCompare(b.next_attempt_at)).slice(0, 20));
    }
    if (url.includes('/tap2work_workspaces?')) return Response.json([]);
    if (url.includes('/object/list/')) {
      const id = JSON.parse(options.body).prefix.slice(0, -1);
      return id === 'store-20' ? Response.json([]) : Response.json({}, { status: 503 });
    }
    throw Error('Unexpected fairness fixture call');
  };
  const run = () => cleanupDeletedWorkspaceMedia({ url: 'https://example.invalid', headers: { apikey: 'fixture' }, fetcher, clock: () => now });
  assert.deepEqual(await run(), { pending: true, processed: 0 });
  assert.equal(patches.length, 20);
  assert.ok(patches.every(p => Date.parse(p.next_attempt_at) === now.getTime() + 300000));
  assert.deepEqual(await run(), { pending: false, processed: 1 });
  assert.equal(patches.at(-1).id, 'store-20');
  assert.equal(jobs.length, 21); // Failed and successful tombstones both remain.
});
test('cleanup backoff update failure is bounded and leaves the durable job retryable', async () => {
  let patches = 0;
  const result = await cleanupDeletedWorkspaceMedia({ url: 'https://example.invalid', headers: { apikey: 'fixture' }, fetcher: async (url, options = {}) => {
    if (url.includes('/tap2work_media_deletions?')) {
      if (options.method === 'PATCH') { patches++; return Response.json({}, { status: 503 }); }
      return Response.json([{ workspace_id: 'store-a' }]);
    }
    if (url.includes('/tap2work_workspaces?')) return Response.json([]);
    return Response.json({}, { status: 503 });
  } });
  assert.deepEqual(result, { pending: true, processed: 0 });
  assert.equal(patches, 1);
});
test('worker deadline leaves remaining durable jobs for the next scheduled invocation', async () => {
  let calls = 0;
  await assert.rejects(cleanupDeletedWorkspaceMedia({ url: 'https://example.invalid', headers: {}, deadline: Date.now() - 1, fetcher: async () => { calls++; return Response.json([]); } }), e => e.status === 503);
  assert.equal(calls, 0);
});
