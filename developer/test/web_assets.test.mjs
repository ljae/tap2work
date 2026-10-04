import test from 'node:test';
import assert from 'node:assert/strict';
import { mkdtemp, readFile, writeFile, rm } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { versionWebAssets } from '../../scripts/version-web-assets.mjs';

async function fixture(t, main, bootstrapExtra = '') {
  const directory = await mkdtemp(join(tmpdir(), 'tap2work-assets-'));
  t.after(() => rm(directory, { recursive: true, force: true }));
  await writeFile(join(directory, 'main.dart.js'), main);
  await writeFile(join(directory, 'flutter_bootstrap.js'), `_flutter.buildConfig={"builds":[{"mainJsPath":"main.dart.js"}]};${bootstrapExtra}`);
  await writeFile(join(directory, 'index.html'), '<base href="/app/"><link href="main.dart.js" rel="preload"><script src="flutter_bootstrap.js"></script>');
  return directory;
}

test('a main-only release invalidates HTML, loader and entrypoint together', async t => {
  const first = await fixture(t, 'old app');
  const next = await fixture(t, 'new app');
  const oldNames = await versionWebAssets(first);
  const newNames = await versionWebAssets(next);
  assert.notEqual(oldNames.mainName, newNames.mainName);
  assert.notEqual(oldNames.bootstrapName, newNames.bootstrapName);
  const html = await readFile(join(next, 'index.html'), 'utf8');
  assert.ok(html.includes(newNames.mainName));
  assert.ok(html.includes(newNames.bootstrapName));
  assert.ok(html.includes('<base href="/app/">'));
  const loader = await readFile(join(next, newNames.bootstrapName), 'utf8');
  assert.ok(loader.includes(`"mainJsPath":"${newNames.mainName}"`));
  assert.equal(await readFile(join(next, newNames.mainName), 'utf8'), 'new app');
  assert.equal(await readFile(join(next, 'main.dart.js'), 'utf8'), 'new app');
});

test('identical builds are deterministic and loader-only changes invalidate HTML', async t => {
  const a = await versionWebAssets(await fixture(t, 'same'));
  const b = await versionWebAssets(await fixture(t, 'same'));
  const c = await versionWebAssets(await fixture(t, 'same', '/* loader update */'));
  assert.deepEqual(a, b);
  assert.equal(a.mainName, c.mainName);
  assert.notEqual(a.bootstrapName, c.bootstrapName);
});

test('unexpected Flutter output blocks publication rather than silently caching', async t => {
  const directory = await fixture(t, 'same');
  await writeFile(join(directory, 'flutter_bootstrap.js'), 'new format');
  await assert.rejects(versionWebAssets(directory), /format changed/);
});


test('reused Flutter HTML can be versioned repeatedly and follows changed main output', async t => {
  const directory = await fixture(t, 'first');
  const initial = await versionWebAssets(directory);
  assert.deepEqual(await versionWebAssets(directory),initial);
  await writeFile(join(directory,'main.dart.js'),'changed');
  const next = await versionWebAssets(directory);
  assert.notEqual(next.mainName,initial.mainName);
  const html = await readFile(join(directory,'index.html'),'utf8');
  assert.ok(html.includes(next.mainName) && html.includes(next.bootstrapName));
  assert.ok(!html.includes(initial.mainName) && !html.includes(initial.bootstrapName));
});
