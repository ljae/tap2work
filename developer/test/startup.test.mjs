import test from 'node:test';
import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import vm from 'node:vm';

const html = await readFile(new URL('../../app/web/index.html', import.meta.url), 'utf8');
const script = html.match(/<script>\s*([\s\S]*?)<\/script>/)[1];
const bootstrap = (await readFile(new URL('../../app/web/flutter_bootstrap.js', import.meta.url), 'utf8')).replace(/\{\{[^}]+\}\}/g, '');
function page() {
  const nodes = new Map();
  const listeners = new Map();
  const timers = new Map();
  let sequence = 0, reloads = 0;
  function node(id) {
    if (!nodes.has(id)) nodes.set(id, { textContent: '', hidden: id === 'boot-retry', classes: [], removed: false,
      classList: { add(value) { node(id).classes.push(value); } },
      remove() { this.removed = true; },
      addEventListener(event, callback) { listeners.set(`${id}:${event}`, callback); },
    });
    return nodes.get(id);
  }
  const context = {
    document: { getElementById: node, querySelector: node, createElement: () => ({}), head: { appendChild() {} } },
    window: { addEventListener(event, callback) { listeners.set(event, callback); } },
    location: { reload() { reloads++; } },
    setTimeout(callback, delay) { const id = ++sequence; timers.set(id, { callback, delay }); return id; },
    clearTimeout(id) { timers.delete(id); },
  };
  vm.runInNewContext(script, context);
  return { context, node, listeners, timers, get reloads() { return reloads; } };
}

test('web boot stays visible until first Flutter frame and offers slow retry', () => {
  const p = page();
  assert.equal(p.node('app-boot').removed, false);
  [...p.timers.values()].find(t => t.delay === 12000).callback();
  assert.match(p.node('boot-message').textContent, /늦어지고/);
  assert.equal(p.node('boot-retry').hidden, false);
  p.listeners.get('boot-retry:click')();
  assert.equal(p.reloads, 1);
  p.listeners.get('flutter-first-frame')();
  assert.deepEqual(p.node('app-boot').classes, ['leaving']);
  assert.equal([...p.timers.values()].some(t => t.delay === 12000), false);
  [...p.timers.values()].find(t => t.delay === 260).callback();
  assert.equal(p.node('app-boot').removed, true);
});

test('web engine failure keeps actionable error instead of an endless loader', async () => {
  const p = page();
  p.context._flutter = { loader: { async load({ onEntrypointLoaded }) {
    await onEntrypointLoaded({ async initializeEngine() { throw Error('offline'); } });
  } } };
  await vm.runInNewContext(bootstrap, p.context);
  assert.match(p.node('boot-title').textContent, /불러오지 못/);
  assert.equal(p.node('boot-retry').hidden, false);
  assert.equal(p.node('.boot-track').hidden, true);
  assert.equal(p.node('app-boot').removed, false);
});

test('web bootstrap download failure exposes retry', async () => {
  const p = page();
  p.context._flutter = { loader: { async load() { throw Error('download'); } } };
  await vm.runInNewContext(bootstrap, p.context);
  assert.equal(p.node('boot-retry').hidden, false);
});
