import test from 'node:test';
import assert from 'node:assert/strict';
import { emptyOperations, OperationsStore } from '../operations.mjs';
import { applyStoreSetup, storeSetupCatalog } from '../store_setup.mjs';
import { manualCatalog } from '../manual_market.mjs';
import { validateRelease } from '../catalog_repository.mjs';

// PostgreSQL jsonb serializes object keys by byte length, then bytes. Ordinary
// structuredClone mocks retain insertion order and miss this persistence bug.
function jsonbRoundTrip(value) {
  if (Array.isArray(value)) return value.map(jsonbRoundTrip);
  if (value && typeof value === 'object') {
    return Object.fromEntries(Object.keys(value)
      .sort((a, b) => Buffer.byteLength(a) - Buffer.byteLength(b) || Buffer.compare(Buffer.from(a), Buffer.from(b)))
      .map(key => [key, jsonbRoundTrip(value[key])]));
  }
  return value;
}

function fixture() {
  const now = new Date('2026-10-10T05:00:00Z');
  const actor = { id: 'audit-owner', name: '사장님', role: 'owner' };
  const catalog = validateRelease(manualCatalog);
  const setupCatalog = storeSetupCatalog(catalog);
  let state = emptyOperations(now, actor.id, actor.name);
  applyStoreSetup(state, {
    name: '회귀 검증 음식점', requestId: 'jsonb-audit-setup',
    setup: {
      businessTypeId: 'chicken', serviceModes: ['takeout', 'delivery'],
      weekdays: [1, 2, 3, 4, 5], opening: '19:00', closing: '02:00',
      partIds: ['kitchen', 'management'], headcounts: { kitchen: 2, management: 1 },
      shiftCount: 2, releaseId: setupCatalog.releaseId,
      sourceIds: ['common/prep', 'chicken/prep', 'delivery/open'], enableOperations: false,
    },
  }, actor, now, catalog);
  state = jsonbRoundTrip(state);
  const store = new OperationsStore(null, () => now, {
    actor, catalog, catalogRevision: 2,
    persistence: {
      read: async () => structuredClone(state),
      save: async (next, revision) => {
        assert.equal(revision, state.revision);
        state = jsonbRoundTrip(next);
      },
    },
  });
  return { store, state: () => state };
}

test('JSONB round trips keep unchanged reads stable and allow the solo owner to acknowledge welcome', async () => {
  const { store } = fixture();
  const opening = await store.snapshot();
  for (let i = 0; i < 3; i++) {
    assert.equal((await store.snapshot()).revision, opening.revision);
  }
  const acknowledged = await store.mutate(null, {
    action: 'ack_welcome', revision: opening.revision,
    welcomeRevision: opening.welcome.revision,
  });
  assert.equal(acknowledged.revision, opening.revision + 1);
  assert.equal(acknowledged.welcomeNeedsAcknowledgment, false);
  assert.equal((await store.snapshot()).revision, acknowledged.revision);
});

test('JSONB stability preserves real catalog changes and stale-write protection', async () => {
  const { store, state } = fixture();
  const opening = await store.snapshot();
  const source = store.catalog.entries.find(entry => entry.sourceId === 'common/prep');
  source.knowledge = { ...source.knowledge, topics: [...source.knowledge.topics, '새 운영 기준'] };
  const changed = await store.snapshot();
  assert.equal(changed.revision, opening.revision + 1);
  const installed = Object.entries(state().catalogLinks).find(([, link]) => link.sourceId === source.sourceId)[0];
  assert.deepEqual(state().taskTemplates.find(template => template.id === installed).knowledge, source.knowledge);
  assert.equal((await store.snapshot()).revision, changed.revision);
  await assert.rejects(store.mutate(null, {
    action: 'ack_welcome', revision: opening.revision,
    welcomeRevision: opening.welcome.revision,
  }), error => error.status === 409);
  const saved = await store.mutate(null, { action: 'save_store', revision: changed.revision, name: '변경된 매장 이름' });
  await assert.rejects(store.mutate(null, { action: 'save_store', revision: changed.revision, name: '오래된 초안' }), error => error.status === 409);
  assert.equal((await store.snapshot()).store.name, saved.store.name);
});
