import test from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { createCloudHandler } from '../supabase_backend.mjs';
import { validateOptimizedJpeg, validateManualMediaScope, stripForeignBackupPhotos } from '../manual_media.mjs';
import { parseManualMediaReference } from '../manual_media_reference.mjs';
import { manualImageLink, mediaLink } from '../checklists.mjs';
import { validateCatalog } from '../manual_catalog_schema.mjs';
import { manualCatalog } from '../manual_market.mjs';
import { placePhoto } from '../place_guide.mjs';
import { workplaceDefaults } from '../workplace.mjs';
import { seedOperations } from '../operations.mjs';
const uid = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
const reference = 'tap2work-media:store-a/bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb.jpg';
const jpeg = readFileSync(new URL('./fixtures/optimized-photo.jpg', import.meta.url));
const dataUrl = bytes => `data:image/jpeg;base64,${bytes.toString('base64')}`;
const photo = dataUrl(jpeg);
function fixture({ role = 'owner', allowed = true, sectionStorage = false, membership = true, storageStatus = 200, conflict = false } = {}) {
  const calls = [], objects = new Map();
  let state = seedOperations(new Date('2026-10-10T04:00:00Z'));
  state.workplace = { ...(state.workplace ?? workplaceDefaults()), restrictions: { manager: { tasks: allowed } } };
  const member = { workspace_id: 'store-a', role, display_name: 'Fixture' };
  const handler = createCloudHandler({ url: 'https://example.invalid', serviceKey: 'sb_secret_fixture', sectionStorage, manualMediaEnabled: true,
    clock: () => new Date('2026-10-10T04:00:00Z'), fetcher: async (url, options = {}) => {
      calls.push({ url, options });
      if (url.endsWith('/auth/v1/user')) return Response.json({ id: uid });
      if (url.includes('/tap2work_members?')) return Response.json(membership ? [member] : []);
      if (url.includes('/tap2work_state?')) return Response.json([{ payload: structuredClone(state) }]);
      if (url.endsWith('/tap2work_read_workspace')) return Response.json({ member, payload: structuredClone(state), window: 1 });
      if (url.endsWith('/tap2work_save_state') || url.endsWith('/tap2work_patch_state')) {
        const input = JSON.parse(options.body);
        if (conflict) return Response.json(false);
        if (input.p_payload) state = input.p_payload;
        return Response.json(true);
      }
      if (url.includes('/storage/v1/object/')) {
        if (storageStatus !== 200) return Response.json({ error: 'private server detail' }, { status: storageStatus });
        const path = url.split('tap2work-manual-media/')[1];
        if (options.method === 'POST') { objects.set(path, options.body); return Response.json({ Key: path }); }
        return new Response(objects.get(path) ?? jpeg, { headers: { 'Content-Type': 'image/jpeg' } });
      }
      throw Error(`Unexpected fixture URL ${url}`);
    } });
  const request = (query, body, headers = {}) => handler(new Request(`https://example.invalid/operations?${query}`, {
    method: body === undefined ? 'GET' : 'POST', headers: { Authorization: 'Bearer user', 'Content-Type': 'application/json', ...headers },
    ...(body === undefined ? {} : { body: JSON.stringify(body) }),
  }));
  return { request, calls, objects, handler };
}
test('optimized JPEG upload is authenticated, private, immutable and returns a stable reference', async () => {
  const f = fixture();
  const response = await f.request('media=upload', { workspaceId: 'store-a', photo });
  assert.equal(response.status, 201, await response.clone().text());
  const result = await response.json();
  assert.equal(parseManualMediaReference(result.reference).workspaceId, 'store-a');
  assert.equal(result.bytes, jpeg.length); assert.equal(result.width, 4); assert.equal(result.height, 4);
  const upload = f.calls.find(c => c.options.method === 'POST' && c.url.includes('/storage/'));
  assert.equal(upload.options.headers['x-upsert'], 'false');
  assert.equal(upload.options.headers['Content-Type'], 'image/jpeg');
  assert.ok(!JSON.stringify(result).includes('secret'));
  assert.ok(!f.calls.some(c => c.url.includes('save_state') || c.url.includes('catalog')));
});
test('crew/cook, revoked manager permission, no membership and employee projection cannot upload', async () => {
  for (const opts of [{ role: 'crew' }, { role: 'cook' }, { role: 'manager', allowed: false }, { role: 'manager', allowed: false, sectionStorage: true }, { membership: false }]) {
    const f = fixture(opts);
    assert.equal((await f.request('media=upload', { workspaceId: 'store-a', photo }, { 'x-demo-actor': 'owner' })).status, 403);
    assert.ok(!f.calls.some(c => c.url.includes('/storage/')));
  }
  const f = fixture();
  assert.equal((await f.request('media=upload&view=employee', { workspaceId: 'store-a', photo })).status, 403);
  assert.equal((await f.handler(new Request('https://example.invalid/operations?media=upload', { method: 'POST' }))).status, 401);
});
test('authorized manager uploads through both storage models and crew can read same-workspace photo', async () => {
  for (const sectionStorage of [false, true]) {
    const f = fixture({ role: 'manager', sectionStorage });
    assert.equal((await f.request('media=upload', { workspaceId: 'store-a', photo })).status, 201);
  }
  const f = fixture({ role: 'crew' });
  const response = await f.request(`media=${encodeURIComponent(reference)}&workspace=store-a`);
  assert.equal(response.status, 200);
  assert.equal(response.headers.get('content-type'), 'image/jpeg');
  assert.equal(response.headers.get('cache-control'), 'no-store');
  assert.equal(response.headers.get('x-content-type-options'), 'nosniff');
  assert.deepEqual(new Uint8Array(await response.arrayBuffer()), new Uint8Array(jpeg));
});
test('cross-workspace reads/uploads, malformed references and arbitrary remote URLs never fetch objects', async () => {
  const f = fixture();
  assert.equal((await f.request('media=upload', { workspaceId: 'store-b', photo })).status, 403);
  assert.equal((await f.request(`media=${encodeURIComponent(reference)}&workspace=store-b`)).status, 403);
  assert.equal((await f.request(`media=${encodeURIComponent(reference.replace('store-a', 'store-b'))}&workspace=store-a`)).status, 403);
  for (const value of ['https://internal.invalid/photo.jpg', 'tap2work-media:store-a/../private.jpg', 'upload']) {
    assert.equal((await f.request(`media=${encodeURIComponent(value)}&workspace=store-a`)).status, 400);
  }
  assert.ok(!f.calls.some(c => c.url.includes('/storage/')));
});
test('upload refuses excess bytes, non-JPEG, malformed JPEG, metadata and excessive dimensions', async () => {
  const f = fixture();
  assert.equal((await f.request('media=upload', { workspaceId: 'store-a', photo: dataUrl(Buffer.alloc(250001)) })).status, 413);
  assert.equal((await f.request('media=upload', { workspaceId: 'store-a', photo: photo.replace('image/jpeg', 'image/png') })).status, 415);
  assert.equal((await f.request('media=upload', { workspaceId: 'store-a', photo: dataUrl(Buffer.from('not a jpeg')) })).status, 400);
  const withExif = Buffer.concat([jpeg.subarray(0, 2), Buffer.from([0xff, 0xe1, 0, 8, 0x45, 0x78, 0x69, 0x66, 0, 0]), jpeg.subarray(2)]);
  assert.throws(() => validateOptimizedJpeg(dataUrl(withExif)), e => e.status === 400);
  const wide = Buffer.from(jpeg), sof = wide.indexOf(Buffer.from([0xff, 0xc0]));
  wide[sof + 7] = 0x10; wide[sof + 8] = 0;
  assert.throws(() => validateOptimizedJpeg(dataUrl(wide)), e => e.status === 400);
  assert.throws(() => validateOptimizedJpeg(dataUrl(jpeg.subarray(0, jpeg.length - 1))), e => e.status === 400);
  assert.throws(() => validateOptimizedJpeg(dataUrl(Buffer.concat([jpeg, Buffer.from('trailing metadata')]))), e => e.status === 400);
  assert.ok(!f.calls.some(c => c.url.includes('/storage/')));
});
test('JSON upload body is bounded before allocation, including chunked requests', async () => {
  const f = fixture();
  const request = new Request('https://example.invalid/operations?media=upload', { method: 'POST', headers: { Authorization: 'Bearer user', 'Content-Type': 'application/json' }, body: ' '.repeat(340001) });
  assert.equal((await f.handler(request)).status, 413);
  assert.ok(!f.calls.some(c => c.url.includes('/storage/')));
});
test('private refs are accepted only by image validators and scope check protects nested backups', async () => {
  assert.equal(manualImageLink(reference), reference); assert.equal(placePhoto(reference), reference);
  assert.equal(mediaLink('https://example.invalid/a.jpg'), 'https://example.invalid/a.jpg');
  assert.throws(() => mediaLink(reference), e => e.status === 400);
  validateManualMediaScope({ backup: { templates: [{ steps: [{ imageUrl: reference }] }] } }, 'store-a');
  assert.throws(() => validateManualMediaScope({ backup: { templates: [{ steps: [{ imageUrl: reference }] }] } }, 'store-b'), e => e.status === 403);
});
test('cloud mutation blocks cross-workspace reference before persisting and CAS conflict keeps uploaded object', async () => {
  const f = fixture({ conflict: true });
  let response = await f.request('media=upload', { workspaceId: 'store-a', photo });
  const { reference: uploaded } = await response.json();
  response = await f.request('', { workspaceId: 'store-a', action: 'save_place', revision: 1, place: { id: 'test-place', kind: 'area', name: 'Photo', photo: uploaded } });
  assert.equal(response.status, 409);
  assert.equal(f.objects.size, 1);
  assert.ok(!f.calls.some(c => c.options.method === 'DELETE'));
  response = await f.request('', { workspaceId: 'store-a', action: 'save_manual_tap', revision: 1, backup: { steps: [{ imageUrl: reference.replace('store-a', 'store-b') }] } });
  assert.equal(response.status, 403);
});
test('Storage failure exposes a retryable message without upstream secrets', async () => {
  const f = fixture({ storageStatus: 500 });
  const response = await f.request('media=upload', { workspaceId: 'store-a', photo });
  assert.equal(response.status, 503); assert.ok(!(await response.text()).includes('private server'));
});

test('public catalogue never accepts private store photo references', () => {
  const entry = structuredClone(manualCatalog.entries[0]);
  entry.steps[0].imageUrl = reference;
  assert.throws(() => validateCatalog([entry]), e => e.status === 400);
});
test('default upload gate fails closed unless explicitly enabled', async () => {
  const handler = createCloudHandler({ url: 'https://example.invalid', serviceKey: 'fixture',
    fetcher: async () => Response.json({ id: uid }) });
  const response = await handler(new Request('https://example.invalid/operations?media=upload', {
    method: 'POST', headers: { Authorization: 'Bearer fixture', 'Content-Type': 'application/json' }, body: JSON.stringify({ workspaceId: 'store-a', photo }),
  }));
  assert.equal(response.status, 503);
});
test('post-upload membership removal compensates the new object instead of returning a usable reference', async () => {
  let memberReads = 0;
  const calls = [];
  const handler = createCloudHandler({ url: 'https://example.invalid', serviceKey: 'fixture', manualMediaEnabled: true, fetcher: async (url, options = {}) => {
    calls.push({ url, options });
    if (url.endsWith('/auth/v1/user')) return Response.json({ id: uid });
    if (url.includes('/tap2work_members?')) return Response.json(++memberReads === 1 ? [{ workspace_id: 'store-a', role: 'owner' }] : []);
    return Response.json({});
  } });
  const response = await handler(new Request('https://example.invalid/operations?media=upload', {
    method: 'POST', headers: { Authorization: 'Bearer fixture', 'Content-Type': 'application/json' }, body: JSON.stringify({ workspaceId: 'store-a', photo }),
  }));
  assert.equal(response.status, 403);
  const compensation = calls.find(c => c.options.method === 'DELETE');
  assert.equal(JSON.parse(compensation.options.body).prefixes.length, 1);
  assert.ok(JSON.parse(compensation.options.body).prefixes[0].startsWith('store-a/'));
});

test('explicit backup restore strips only foreign private image fields, preserving same-store refs and HTTPS', () => {
  const input = { action: 'restore_checklist_backup', backup: { templates: [{ steps: [
    { imageUrl: reference, title: 'same store' },
    { imageUrl: reference.replace('store-a', 'store-b'), title: 'other store' },
    { imageUrl: 'https://example.invalid/photo.jpg', title: 'external' },
  ] }] } };
  assert.equal(stripForeignBackupPhotos(input, 'store-a'), 1);
  assert.deepEqual(input.backup.templates[0].steps.map(s => s.imageUrl), [reference, '', 'https://example.invalid/photo.jpg']);
  validateManualMediaScope(input, 'store-a');
  assert.equal(stripForeignBackupPhotos(input, null), 1);
  const edit = { action: 'save_manual_tap', backup: { imageUrl: reference } };
  assert.equal(stripForeignBackupPhotos(edit, 'store-b'), 0);
  assert.throws(() => validateManualMediaScope(edit, 'store-b'), e => e.status === 403);
});
test('local demo explicitly rejects cloud media routes without pretending to authenticate', async t => {
  const { createConsoleServer } = await import('../server.mjs');
  const server = createConsoleServer();
  await new Promise(resolve => server.listen(0, '127.0.0.1', resolve));
  t.after(() => new Promise(resolve => server.close(resolve)));
  const base = `http://127.0.0.1:${server.address().port}`;
  const response = await fetch(`${base}/api/operations?media=upload`, { method: 'POST', headers: { 'Content-Type': 'application/json', 'x-demo-actor': 'owner' }, body: JSON.stringify({ workspaceId: 'store-a', photo }) });
  assert.equal(response.status, 501);
  assert.match((await response.json()).error, /샘플/);
});
