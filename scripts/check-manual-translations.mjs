import { readFileSync } from 'node:fs';
import assert from 'node:assert/strict';

const catalog = JSON.parse(readFileSync(new URL('../docs/market/current.json', import.meta.url)));
const sources = new Set([
  '우리 매장에 오신 것을 환영해요',
  '처음 하는 일은 동료와 함께 확인해 주세요. 모르는 점이나 위험한 상황은 바로 물어봐도 괜찮아요.',
]);
for (const entry of catalog.entries) {
  sources.add(entry.title);
  for (const step of entry.steps ?? []) {
    for (const key of ['title', 'manual', 'tip']) {
      if (typeof step[key] === 'string' && step[key].trim()) sources.add(step[key]);
    }
  }
}
const tokens = (text, pattern) => [...text.matchAll(pattern)].map(m => m[0]).sort();
for (const locale of ['en', 'vi', 'zh-Hans', 'ja', 'th', 'ne', 'id']) {
  const bundle = JSON.parse(readFileSync(new URL(`../app/assets/manual_translations/${locale}.json`, import.meta.url)));
  assert.equal(bundle.schemaVersion, 1);
  assert.equal(bundle.sourceLocale, 'ko');
  assert.equal(bundle.targetLocale, locale);
  assert.equal(bundle.catalogReleaseId, catalog.releaseId);
  assert.equal(bundle.reviewStatus, 'ai-draft');
  assert.deepEqual(Object.keys(bundle.translations).sort(), [...sources].sort(), `${locale}: catalog source coverage`);
  for (const source of sources) {
    const text = bundle.translations[source];
    assert.equal(typeof text, 'string');
    assert.ok(text.trim(), `${locale}: empty translation: ${source}`);
    assert.deepEqual(tokens(text, /\d+/g), tokens(source, /\d+/g), `${locale}: numeric safety content: ${source}`);
    assert.deepEqual(tokens(text, /\{[^}]+\}/g), tokens(source, /\{[^}]+\}/g), `${locale}: placeholders: ${source}`);
  }
  console.log(`${locale}: ${sources.size} prepared strings; source keys, numbers and placeholders verified`);
}
