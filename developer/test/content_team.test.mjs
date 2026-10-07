import test from 'node:test';
import assert from 'node:assert/strict';
import { mkdtempSync, rmSync, writeFileSync, readFileSync, mkdirSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { ContentTeam, fixtureArtifact, outputSchema, runCodex } from '../../scripts/content-team.mjs';
const scope = { mode: 'fixture', industry: 'food-service', gap: '인계가 모호한 테스트', jurisdiction: 'KR', sourceIds: [], baseRevision: 0 };
function setup(t) {
  const root = mkdtempSync(join(tmpdir(), 'tap-content-test-')); t.after(() => rmSync(root, { recursive: true, force: true }));
  let now = Date.now(); const team = new ContentTeam({ root, now: () => now });
  team.init('job', scope); return { team, root, advance: () => { now += 901000; } };
}
function advance(team, until = 'coordinator') {
  for (;;) { const packet = team.next('job'); if (packet.role === until) return packet; team.record('job', fixtureArtifact(packet), packet.leaseId); }
}
test('durable five-role pipeline has fixed hashes, retains human review and never publishes', t => {
  const { team, root } = setup(t);
  for (let index = 0; index < 5; index++) {
    const restarted = new ContentTeam({ root }); const packet = restarted.next('job');
    assert.equal(packet.status, 'ready'); assert.equal(packet.inputHash.length, 64);
    restarted.record('job', fixtureArtifact(packet), packet.leaseId);
  }
  assert.equal(team.status('job').status, 'complete'); assert.equal(team.status('job').calls, 5);
  const handoff = JSON.parse(readFileSync(join(root, 'job/artifacts/coordinator.json')));
  assert.equal(handoff.result.publishAllowed, false);
  assert.equal(JSON.parse(readFileSync(join(root, 'job/artifacts/reviewer.json'))).result.humanApproved, false);
  assert.equal(team.next('job').status, 'complete');
});
test('init is idempotent but cannot reuse ID with a different scope', t => {
  const { team } = setup(t); assert.deepEqual(team.init('job', scope), team.status('job'));
  assert.throws(() => team.init('job', { ...scope, gap: 'different' }), /different scope/);
  assert.throws(() => team.init('../escape', scope), /job ID/);
});
test('lease excludes simultaneous work and expires to a bounded failed queue', t => {
  const { team, advance } = setup(t);
  for (let index = 0; index < 3; index++) { assert.equal(team.next('job').status, 'ready'); assert.equal(team.next('job').status, 'leased'); advance(); }
  assert.equal(team.next('job').status, 'failed'); assert.equal(team.status('job').calls, 3);
});
test('late output cannot reuse a replaced lease but correct repeated record is idempotent', t => {
  const { team, advance } = setup(t); const first = team.next('job'); advance(); const second = team.next('job');
  assert.notEqual(first.inputHash, second.inputHash); assert.notEqual(first.leaseId, second.leaseId);
  assert.throws(() => team.record('job', fixtureArtifact(first), first.leaseId), /lease/);
  const artifact = fixtureArtifact(second); team.record('job', artifact, second.leaseId);
  assert.equal(team.record('job', artifact, second.leaseId).status, 'already_recorded');
  artifact.result.unresolved.push('changed'); assert.throws(() => team.record('job', artifact, second.leaseId), /immutable/);
});
test('output contract rejects fake approvals, mismatched inputs and unknown fields', t => {
  const { team } = setup(t); const packet = team.next('job'); const artifact = fixtureArtifact(packet);
  artifact.inputHash = '0'.repeat(64); assert.throws(() => team.record('job', artifact, packet.leaseId), /different job/);
  artifact.inputHash = packet.inputHash; artifact.result.approved = true; assert.throws(() => team.record('job', artifact, packet.leaseId), /unexpected field/);
  delete artifact.result.approved; artifact.result.constructor = 'unexpected'; assert.throws(() => team.record('job', artifact, packet.leaseId), /unexpected field/); delete artifact.result.constructor; team.record('job', artifact, packet.leaseId);
  const reviewer = advance(team, 'reviewer'); const review = fixtureArtifact(reviewer); review.result.humanApproved = true;
  assert.throws(() => team.record('job', review, reviewer.leaseId), /invalid constant/);
});
test('fixture sources cannot become external evidence and excerpt hashes are verified', t => {
  const { team } = setup(t); const packet = team.next('job'); const artifact = fixtureArtifact(packet);
  artifact.result.sources[0].excerpt += 'tampered'; assert.throws(() => team.record('job', artifact, packet.leaseId), /hash mismatch/);
  const another = new ContentTeam({ root: join(team.root, 'research') }); another.init('research', { ...scope, mode: 'research' });
  const real = another.next('research'); assert.throws(() => fixtureArtifact(real), /fixture job/);
  const fake = fixtureArtifact(packet); fake.jobId = real.jobId; fake.inputHash = real.inputHash;
  assert.throws(() => another.record('research', fake, real.leaseId), /Fixture evidence forbidden/);
});
test('unknown evidence references and duplicate IDs prevent downstream drafts', t => {
  const { team } = setup(t); const packet = advance(team, 'editor'); const artifact = fixtureArtifact(packet);
  artifact.result.drafts[0].steps[0].evidenceSourceIds = ['invented']; assert.throws(() => team.record('job', artifact, packet.leaseId), /Unknown evidence/);
  artifact.result.drafts[0].steps[0].evidenceSourceIds = ['fixture-handoff']; artifact.result.drafts[0].steps.push(artifact.result.drafts[0].steps[0]);
  assert.throws(() => team.record('job', artifact, packet.leaseId), /Duplicate Task/);
});
test('tampered durable artifacts, config and scope stop restart', t => {
  const { team, root } = setup(t); const packet = team.next('job'); team.record('job', fixtureArtifact(packet), packet.leaseId);
  writeFileSync(join(root, 'job/artifacts/researcher.json'), '{}'); assert.throws(() => team.next('job'), /Artifact tampered/);
  const another = new ContentTeam({ root: join(root, 'another') }); another.init('job', scope);
  writeFileSync(join(root, 'another/job/scope.json'), '{}'); assert.throws(() => another.status('job'), /input\/config tampered/);
});
test('coordinator cannot prepare when review requests changes', t => {
  const { team } = setup(t); let packet = advance(team, 'reviewer'); const artifact = fixtureArtifact(packet);
  artifact.result.outcome = 'changes_required'; team.record('job', artifact, packet.leaseId);
  packet = advance(team); const handoff = fixtureArtifact(packet);
  assert.throws(() => team.record('job', handoff, packet.leaseId), /requires reviewer/);
  handoff.result.status = 'blocked'; handoff.result.blockers = ['revise draft']; team.record('job', handoff, packet.leaseId);
  assert.equal(team.status('job').status, 'blocked');
});
test('explicit attempt failure retries and cannot exceed queue limit', t => {
  const { team } = setup(t);
  for (let index = 0; index < 3; index++) { const packet = team.next('job'); team.fail('job', packet.leaseId, 'tool unavailable'); }
  assert.equal(team.next('job').status, 'failed');
});
test('credential fields and markers are rejected before persistent storage', t => {
  const { team } = setup(t);
  assert.throws(() => team.init('bad', { ...scope, service_role: 'secret' }), /unexpected field/);
  assert.throws(() => team.init('bad', { ...scope, gap: 'SUPABASE_SERVICE key' }), /credential markers/);
});
test('concurrent lock blocks writers and live-owner lock cannot be reclaimed', t => {
  const { team, root } = setup(t); const lock = join(root, 'job/.lock'); mkdirSync(lock);
  writeFileSync(join(lock, 'owner.json'), JSON.stringify({ pid: process.pid }));
  assert.throws(() => team.next('job'), /locked/); assert.throws(() => team.unlock('job'), /still running/);
});
test('checked-in schemas match runner contracts', () => {
  for (const role of ['researcher', 'editor', 'reviewer', 'qa', 'coordinator']) assert.deepEqual(JSON.parse(readFileSync(new URL(`../../.agents/content-team/${role}.schema.json`, import.meta.url))), outputSchema(role));
});
test('Codex executable launch receives isolated folder, explicit sandbox and sanitized env', async t => {
  const { team, root } = setup(t); const packet = team.next('job'); const executable = join(root, 'fake-codex');
  // Real executable integration fixture, never a model request.
  writeFileSync(executable, `#!/usr/bin/env node\nconst fs=require("fs"); const args=process.argv.slice(2); const out=args[args.indexOf("--output-last-message")+1]; fs.writeFileSync(out,${JSON.stringify(JSON.stringify(fixtureArtifact(packet)))}); fs.writeFileSync(${JSON.stringify(join(packet.runDirectory, 'runner-contract.json'))},JSON.stringify({args,secret:!!process.env.SUPABASE_SERVICE_KEY,cwd:process.cwd()}));\n`, { mode: 0o700 });
  process.env.SUPABASE_SERVICE_KEY = 'fixture-secret';
  try { const artifact = await runCodex(packet, { executable }); team.record('job', artifact, packet.leaseId); }
  finally { delete process.env.SUPABASE_SERVICE_KEY; }
  const contract = JSON.parse(readFileSync(join(packet.runDirectory, 'runner-contract.json')));
  assert.equal(contract.secret, false); assert.notEqual(contract.cwd, packet.runDirectory); assert.ok(contract.cwd.includes("tap2work-content-agent-"));
  assert.equal(contract.args[contract.args.indexOf('--sandbox') + 1], 'read-only'); assert.ok(contract.args.includes('--ignore-user-config'));
});
test('export merges stable source/Task IDs into a validated full release with review metadata preserved', async t => {
  const { team } = setup(t);
  const { manualCatalog } = await import('../manual_market.mjs');
  const baseEntry = manualCatalog.entries.find(entry => entry.references.length);
  const research = new ContentTeam({ root: join(team.root, 'export-tests') });
  research.init('real', { ...scope, mode: 'research', gap: 'Unit export test only; no actual research' });
  for (let index = 0; index < 5; index++) {
    const packet = research.next('real');
    const artifact = fixtureArtifact({ ...packet, scope: { ...packet.scope, mode: 'fixture' } });
    if (packet.role === 'researcher') {
      Object.assign(artifact.result.sources[0], { kind: 'external', url: baseEntry.references[0].url });
      artifact.result.unresolved = [];
    }
    if (packet.role === 'editor') {
      artifact.result.drafts[0].sourceId = baseEntry.sourceId;
      artifact.result.drafts[0].steps[0].id = baseEntry.steps[0].id;
    }
    research.record('real', artifact, packet.leaseId);
  }
  const result = await research.exportRelease('real', manualCatalog);
  const entry = result.draftRequest.release.entries.find(entry => entry.sourceId === baseEntry.sourceId);
  assert.equal(entry.reviewedAt, baseEntry.reviewedAt);
  assert.ok(entry.steps[0].manual.includes('완료 기준'));
  assert.ok(entry.steps[0].manual.includes('예외 대응'));
  assert.equal(entry.steps.length, baseEntry.steps.length);
  assert.equal(result.draftRequest.release.entries.length, manualCatalog.entries.length);
  assert.equal(result.draftRequest.revision, 0);
  assert.equal(result.provenance.publishAllowed, false);
  assert.equal(result.provenance.humanReviewRequired, true);
  assert.equal(result.draftRequest.release.releaseId.length, 64);
  const incomplete = new ContentTeam({ root: join(team.root, 'incomplete') }); incomplete.init('job', scope);
  await assert.rejects(incomplete.exportRelease('job', manualCatalog), /Complete candidate/);
});
test('fixture smoke cannot export a production draft', async t => {
  const { team } = setup(t);
  for (let index = 0; index < 5; index++) { const packet = team.next('job'); team.record('job', fixtureArtifact(packet), packet.leaseId); }
  await assert.rejects(team.exportRelease('job', {}), /Fixture jobs/);
});
