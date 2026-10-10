import test from 'node:test';
import assert from 'node:assert/strict';
import { createHmac } from 'node:crypto';
import { createMediaCleanupHandler } from '../manual_media_cleanup_backend.mjs';
const token = 'a'.repeat(43);
const sign = (secret = token, stamp = Math.floor(Date.now() / 1000)) => `Bearer ${stamp}.${createHmac('sha256', secret).update(`tap2work-manual-media-cleanup:${stamp}`).digest('hex')}`;
function fixture(options = {}) {
  const calls = [];
  const handler = createMediaCleanupHandler({ url: 'https://example.supabase.co', serviceKey: 'sb_secret_server', cleanupSecret: token,
    cleanup: async input => { calls.push(input); return { pending: false, processed: 0 }; }, ...options });
  const request = (body = {}, headers = {}, query = '') => handler(new Request(`https://example.supabase.co/functions/v1/manual-media-cleanup${query}`, {
    method: 'POST', headers: { 'Content-Type': 'application/json', Authorization: sign(), ...headers }, body: JSON.stringify(body),
  }));
  return { calls, handler, request };
}
test('dedicated cron bearer is required; user, anon and server credentials cannot substitute', async () => {
  const f = fixture();
  for (const authorization of ['', 'Bearer user-jwt', 'Bearer publishable-key', 'Bearer sb_secret_server', `Bearer ${token}`, sign('b'.repeat(43)), sign(token, Math.floor(Date.now()/1000)-301), sign(token, Math.floor(Date.now()/1000)+31)]) {
    assert.equal((await f.request({}, { Authorization: authorization })).status, 401);
  }
  assert.equal(f.calls.length, 0);
  assert.equal((await fixture({ cleanupSecret: undefined }).request()).status, 503);
  assert.equal((await fixture({ cleanupSecret: 'weak' }).request()).status, 503);
});
test('cron can invoke only an empty-body fixed-scope cleanup with bounded deadline', async () => {
  const f = fixture();
  for (const input of [{ workspaceIds: ['live-store'] }, { prefixes: ['live-store/'] }, { maxBatches: 9999 }, [], null]) {
    assert.equal((await f.request(input)).status, 400);
  }
  assert.equal((await f.request({}, {}, '?workspace=live-store')).status, 400);
  assert.equal((await f.request({}, { Origin: 'https://tap2.work' })).status, 400);
  assert.equal((await f.request({}, { 'Content-Type': 'text/plain' })).status, 415);
  assert.equal(f.calls.length, 0);
  const start = Date.now();
  const response = await f.request();
  assert.equal(response.status, 200);
  assert.equal(response.headers.get('cache-control'), 'no-store');
  assert.equal(response.headers.get('access-control-allow-origin'), null);
  assert.deepEqual(await response.json(), { pending: false, processed: 0 });
  assert.equal(f.calls.length, 1);
  assert.equal(f.calls[0].workspaceIds, undefined);
  assert.ok(f.calls[0].deadline >= start + 44000 && f.calls[0].deadline <= Date.now() + 45000);
  assert.equal(f.calls[0].headers.apikey, 'sb_secret_server');
});
test('cron rejects oversized/invalid input and hides worker failures or secrets', async () => {
  const f = fixture();
  assert.equal((await f.request({ value: 'x'.repeat(1024) })).status, 413);
  assert.equal((await f.handler(new Request('https://example.supabase.co/functions/v1/manual-media-cleanup', { method: 'GET' }))).status, 405);
  const failed = fixture({ cleanup: async () => { throw Error('private database info'); } });
  const response = await failed.request();
  assert.equal(response.status, 503);
  assert.ok(!(await response.text()).includes('private database info'));
  assert.equal(f.calls.length, 0);
});
test('scheduled endpoint performs real queue reads only after authenticating dedicated secret', async () => {
  const calls = [];
  const handler = createMediaCleanupHandler({ url: 'https://example.supabase.co', serviceKey: 'sb_secret_server', cleanupSecret: token, fetcher: async (url, options) => {
    calls.push({ url, options });
    assert.ok(url.includes('/tap2work_media_deletions?'));
    return Response.json([]);
  } });
  const response = await handler(new Request('https://example.supabase.co/functions/v1/manual-media-cleanup', {
    method: 'POST', headers: { 'Content-Type': 'application/json', Authorization: sign() }, body: '{}',
  }));
  assert.equal(response.status, 200);
  assert.equal(calls.length, 1);
  assert.ok(!calls[0].url.includes(token));
});
