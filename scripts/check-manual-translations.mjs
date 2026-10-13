import {readManualTranslationSources} from './manual-translation-sources.mjs';
import { readFileSync } from 'node:fs';
import assert from 'node:assert/strict';

const catalog = JSON.parse(readFileSync(new URL('../docs/market/current.json', import.meta.url)));
const ownerStarter = JSON.parse(readFileSync(new URL('../developer/owner_starter_content.json', import.meta.url)));
const firstShiftSource = readFileSync(new URL('../app/lib/domain/lesson.dart', import.meta.url), 'utf8');
const {sources} = readManualTranslationSources();
const tokens = (text, pattern) => [...text.matchAll(pattern)].map(m => m[0]).sort();
for (const locale of ['en', 'vi', 'zh-Hans', 'ja', 'th', 'ne', 'id']) {
  const bundle = JSON.parse(readFileSync(new URL(`../app/assets/manual_translations/${locale}.json`, import.meta.url)));
  assert.equal(bundle.schemaVersion, 1);
  assert.equal(bundle.sourceLocale, 'ko');
  assert.equal(bundle.targetLocale, locale);
  assert.equal(bundle.catalogReleaseId, catalog.releaseId);
  assert.equal(bundle.reviewStatus, 'ai-draft');
  assert.equal(bundle.ownerStarterVersion, ownerStarter.version);
  assert.equal(bundle.firstShiftGuideVersion, 1);
  for (const source of sources) assert.ok(Object.hasOwn(bundle.translations, source), `${locale}: missing source: ${source}`);
  // Installed manuals keep their original text until the owner reviews an update.
  // Retain and validate their translations alongside the latest catalogue.
  for (const source of Object.keys(bundle.translations)) {
    const text = bundle.translations[source];
    assert.equal(typeof text, 'string');
    assert.ok(text.trim(), `${locale}: empty translation: ${source}`);
    assert.deepEqual(tokens(text, /\d+/g), tokens(source, /\d+/g), `${locale}: numeric safety content: ${source}`);
    assert.deepEqual(tokens(text, /\{[^}]+\}/g), tokens(source, /\{[^}]+\}/g), `${locale}: placeholders: ${source}`);
  }
  console.log(`${locale}: ${sources.size} current sources covered; ${Object.keys(bundle.translations).length} current/historical strings validated`);
}
