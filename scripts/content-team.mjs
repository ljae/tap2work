import { createHash, randomUUID } from 'node:crypto';
import { mkdirSync, readFileSync, writeFileSync, renameSync, rmSync, existsSync, realpathSync, mkdtempSync } from 'node:fs';
import { resolve, dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { spawn } from 'node:child_process';
import { tmpdir } from 'node:os';
import {ContentMemory,sourceUrl} from '../developer/content_memory.mjs';

const repo = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const teamRoot = join(repo, '.agents/content-team');
const sha = value => createHash('sha256').update(value).digest('hex');
const bytes = path => readFileSync(path);
const json = path => JSON.parse(bytes(path));
const error = message => { throw Error(message); };
const id = value => typeof value === 'string' && /^[a-zA-Z0-9][a-zA-Z0-9_-]{0,79}$/.test(value) ? value : error('Invalid job ID');
const atomic = (path, value) => {
  const temp = `${path}.${randomUUID()}.tmp`;
  writeFileSync(temp, JSON.stringify(value, null, 2) + '\n', { mode: 0o600 });
  renameSync(temp, path);
};
const manifest = () => json(join(teamRoot, 'manifest.json'));

// This schema subset is intentionally shared with Codex --output-schema.
const str = { type: 'string', minLength: 1, maxLength: 8000 };
const list = item => ({ type: 'array', items: item, maxItems: 100 });
const strings = list(str);
const obj = properties => ({ type: 'object', properties, required: Object.keys(properties), additionalProperties: false });
const source = obj({ id: str, kind: { type: 'string', enum: ['external', 'fixture'] }, title: str,
  url: { type: 'string', maxLength: 2000 }, publisher: str, retrievedAt: {type:'string',pattern:'^\\d{4}-\\d{2}-\\d{2}T\\d{2}:\\d{2}:\\d{2}(?:\\.\\d{1,3})?(?:Z|[+-]\\d{2}:\\d{2})$'}, jurisdiction: str,
  applicability: str, excerpt: str, evidenceHash: { type: 'string', pattern: '^[a-f0-9]{64}$' } });
const step = obj({ id: str, title: str, manual: str, completionCriteria: str, exceptionAction: str, evidenceSourceIds: strings });
const results = {
  researcher: obj({ gaps: strings, sources: list(source), claims: list(obj({ statement: str, sourceIds: strings })), unresolved: strings }),
  editor: obj({ drafts: list(obj({ sourceId: str, title: str, applicability: str, steps: list(step) })), changeSummary: str, evidenceSourceIds: strings, requiresHumanReview: { type: 'boolean', const: true } }),
  reviewer: obj({ outcome: { type: 'string', enum: ['candidate', 'changes_required'] }, findings: strings, requiredHumanChecks: strings, humanApproved: { type: 'boolean', const: false } }),
  qa: obj({ outcome: { type: 'string', enum: ['pass', 'fail'] }, checks: strings, blockers: strings }),
  coordinator: obj({ status: { type: 'string', enum: ['prepared', 'blocked'] }, handoff: str, nextGaps: strings, blockers: strings, publishAllowed: { type: 'boolean', const: false } }),
};
export function outputSchema(role) {
  if (!results[role]) error('Unknown role');
  return obj({ schemaVersion: { type: 'integer', const: 1 }, jobId: str, role: { type: 'string', const: role }, inputHash: { type: 'string', pattern: '^[a-f0-9]{64}$' }, result: results[role] });
}
function validate(schema, value, path = '$') {
  if ('const' in schema && value !== schema.const) error(`${path}: invalid constant`);
  if (schema.enum && !schema.enum.includes(value)) error(`${path}: invalid enum`);
  if (schema.type === 'object') {
    if (!value || typeof value !== 'object' || Array.isArray(value)) error(`${path}: object required`);
    for (const key of schema.required) if (!(key in value)) error(`${path}.${key}: required`);
    for (const key of Object.keys(value)) {
      if (!Object.hasOwn(schema.properties, key)) error(`${path}.${key}: unexpected field`);
      validate(schema.properties[key], value[key], `${path}.${key}`);
    }
  }
  if (schema.type === 'array') {
    if (!Array.isArray(value) || value.length > schema.maxItems) error(`${path}: invalid list`);
    value.forEach((item, index) => validate(schema.items, item, `${path}[${index}]`));
  }
  if (schema.type === 'string') {
    if (typeof value !== 'string' || (schema.minLength && !value.trim()) || value.length > (schema.maxLength ?? Infinity)) error(`${path}: invalid string`);
    if (schema.pattern && !new RegExp(schema.pattern).test(value)) error(`${path}: invalid pattern`);
  }
}
function sanitized(scope) {
  validate(obj({ mode: { type: 'string', enum: ['research', 'fixture'] }, industry: str, gap: str, jurisdiction: str,
    sourceIds: strings, baseRevision: { type: 'integer' } }), scope);
  if (!Number.isSafeInteger(scope.baseRevision) || scope.baseRevision < 0) error('Invalid baseRevision');
  const serialized = JSON.stringify(scope);
  if (/-----BEGIN|\b(?:service_role|SUPABASE_SERVICE|password|access_token|refresh_token|secret_key)\b|\beyJ[A-Za-z0-9_-]{20,}\./i.test(serialized)) error('Scope contains credential markers');
  return scope;
}

export class ContentTeam {
  constructor({ root = join(repo, '.local/content-team'), now = () => Date.now() } = {}) {
    this.root = resolve(root); this.now = now;
    mkdirSync(this.root, { recursive: true, mode: 0o700 });
    this.memory = new ContentMemory({root:join(this.root,'.learning'),now:this.now});
  }
  dir(jobId) { return join(this.root, id(jobId)); }
  withLock(jobId, action) {
    const directory = this.dir(jobId); mkdirSync(directory, { recursive: true, mode: 0o700 });
    const lock = join(directory, '.lock');
    try { mkdirSync(lock); } catch { error('Job is locked; concurrent writer refused'); }
    atomic(join(lock, 'owner.json'), { pid: process.pid, createdAt: this.now() });
    try { return action(directory); } finally { rmSync(lock, { recursive: true, force: true }); }
  }
  init(jobId, scope, {currentContent=null}={}) {
    sanitized(scope);
    return this.withLock(jobId, directory => {
      const path = join(directory, 'job.json');
      if (existsSync(path)) {
        const previous = json(path);
        if (previous.scopeHash !== sha(JSON.stringify(scope))) error('Job ID already has different scope');
        if(currentContent!==null && sha(JSON.stringify(json(join(directory,'config.json')).learningSnapshot?.currentContent??[]))!==sha(JSON.stringify(currentContent)))error('Job ID already has different current content');
        this.verify(directory, previous); return previous;
      }
      const team = manifest();
      const learningSnapshot=this.memory.context(scope);
      if(currentContent!==null){if(!Array.isArray(currentContent))error('Current content must be an array');learningSnapshot.currentContent=structuredClone(currentContent);}
      const config = { learningSnapshot, schemas: Object.fromEntries(team.roles.map(role => [role.id, outputSchema(role.id)])), manifest: team, manifestHash: sha(bytes(join(teamRoot, 'manifest.json'))), prompts: {} };
      for (const role of team.roles) config.prompts[role.id] = bytes(join(teamRoot, 'prompts/common.md')).toString() + '\n' + bytes(join(teamRoot, role.prompt)).toString();
      const job = { schemaVersion: 1, jobId, scopeHash: sha(JSON.stringify(scope)), configHash: sha(JSON.stringify(config)),
        calls: 0, status: 'pending', stages: team.roles.map(role => ({ role: role.id, status: 'pending', attempts: 0 })), events: [{ type: 'initialized', at: new Date(this.now()).toISOString() }] };
      atomic(join(directory, 'scope.json'), scope); atomic(join(directory, 'config.json'), config); atomic(path, job);
      return job;
    });
  }
  verify(directory, job) {
    if (sha(JSON.stringify(json(join(directory, 'scope.json')))) !== job.scopeHash || sha(JSON.stringify(json(join(directory, 'config.json')))) !== job.configHash) error('Job input/config tampered');
    for (const stage of job.stages) if (stage.status === 'complete' && sha(bytes(join(directory, 'artifacts', `${stage.role}.json`))) !== stage.outputHash) error(`Artifact tampered: ${stage.role}`);
  }
  packet(directory, job, stage) {
    const config = json(join(directory, 'config.json'));
    const role = config.manifest.roles.find(value => value.id === stage.role);
    const dependencies = role.dependsOn.map(name => {
      const dependency = job.stages.find(value => value.role === name);
      if (dependency.status !== 'complete') error('Dependency incomplete');
      return { role: name, hash: dependency.outputHash, artifact: json(join(directory, 'artifacts', `${name}.json`)) };
    });
    const inputs = { runStartedAt:stage.runStartedAt, retryGuidance:job.events.filter(e=>e.type==='attempt_failed'&&e.role===stage.role).slice(-2).map(e=>e.reason), scopeHash: job.scopeHash, configHash: job.configHash, role: stage.role, dependencies: dependencies.map(({ role, hash }) => ({ role, hash })) };
    return { schemaVersion: 1, jobId: job.jobId, role: stage.role, runStartedAt:inputs.runStartedAt, retryGuidance:inputs.retryGuidance, inputHash: sha(JSON.stringify(inputs)),
      scope: json(join(directory, 'scope.json')), learning:config.learningSnapshot??{revision:0,sources:[],lessons:[]}, dependencies, prompt: config.prompts[stage.role], outputSchema: config.schemas[stage.role] };
  }
  next(jobId) {
    return this.withLock(jobId, directory => {
      const job = json(join(directory, 'job.json')); this.verify(directory, job);
      if (['complete', 'blocked', 'failed'].includes(job.status)) return { status: job.status, jobId };
      const config = json(join(directory, 'config.json')).manifest;
      const stage = job.stages.find(value => value.status !== 'complete');
      if (stage.status === 'leased' && stage.leaseUntil > this.now()) return { status: 'leased', jobId, role: stage.role, leaseUntil: stage.leaseUntil };
      if (stage.status === 'leased') job.events.push({ type: 'lease_expired', role: stage.role, at: new Date(this.now()).toISOString() });
      if (stage.attempts >= config.maxAttempts || job.calls >= config.maxCallsPerJob) {
        stage.status = 'failed'; job.status = 'failed'; atomic(join(directory, 'job.json'), job);
        return { status: 'failed', jobId, role: stage.role };
      }
      stage.runStartedAt = new Date(this.now()).toISOString();
      const packet = this.packet(directory, job, stage);
      stage.status = 'leased'; stage.attempts += 1; stage.inputHash = packet.inputHash;
      stage.leaseId = randomUUID(); stage.leaseUntil = this.now() + config.leaseSeconds * 1000;
      job.calls += 1; job.status = 'running';
      job.events.push({ type: 'leased', role: stage.role, attempt: stage.attempts, at: new Date(this.now()).toISOString() });
      const runDirectory = join(directory, 'runs', `${stage.role}-${stage.attempts}`);
      mkdirSync(join(runDirectory, 'input'), { recursive: true, mode: 0o700 });
      for (const dependency of packet.dependencies) atomic(join(runDirectory, 'input', `${dependency.role}.json`), dependency.artifact);
      atomic(join(runDirectory, 'scope.json'), packet.scope);
      atomic(join(runDirectory, 'packet.json'), packet);
      atomic(join(runDirectory, 'output-schema.json'), packet.outputSchema);
      writeFileSync(join(runDirectory, 'AGENTS.md'), packet.prompt + '\nReturn only the output JSON. Read packet.json first.\n', { mode: 0o600 });
      atomic(join(directory, 'job.json'), job);
      return { status: 'ready', ...packet, leaseId: stage.leaseId, runDirectory };
    });
  }
  checkArtifact(directory, job, artifact, packet) {
    validate(packet.outputSchema, artifact);
    if (artifact.jobId !== job.jobId || artifact.inputHash !== packet.inputHash) error('Artifact bound to a different job/input');
    const research = artifact.role === 'researcher' ? artifact.result : packet.dependencies.find(value => value.role === 'researcher')?.artifact.result;
    const sources = research?.sources ?? [];
    const sourceIds = new Set(sources.map(value => value.id));
    if (sourceIds.size !== sources.length) error('Duplicate evidence source ID');
    for (const source of sources) {
      if (sha(source.excerpt) !== source.evidenceHash) error('Evidence excerpt hash mismatch');
      if (!/^\d{4}-\d{2}-\d{2}T/.test(source.retrievedAt) || !Number.isFinite(Date.parse(source.retrievedAt))) error('Invalid evidence retrieval date: timezone ISO timestamp required');
      if(Date.parse(source.retrievedAt)>this.now()+300000)error('Invalid evidence retrieval date: future observation forbidden');
      if (source.kind === 'fixture' && packet.scope.mode !== 'fixture') error('Fixture evidence forbidden in research job');
      if (source.kind === 'external') { try{sourceUrl(source.url);}catch{error('Invalid evidence URL');} }
      if (source.kind === 'fixture' && source.url !== '') error('Fixture cannot claim external URL');
    }
    const references = references => { for (const reference of references) if (!sourceIds.has(reference)) error('Unknown evidence source ID'); };
    for (const claim of research?.claims ?? []) { if (!claim.sourceIds.length) error('Claims require evidence'); references(claim.sourceIds); }
    if (artifact.role === 'editor') {
      references(artifact.result.evidenceSourceIds);
      const seen = new Set();
      for (const draft of artifact.result.drafts) {
        if (seen.has(draft.sourceId)) error('Duplicate draft source ID'); seen.add(draft.sourceId);
        if (!draft.steps.length) error('Draft requires steps');
        const steps = new Set();
        for (const step of draft.steps) { if (steps.has(step.id)) error('Duplicate Task ID'); steps.add(step.id); references(step.evidenceSourceIds); }
      }
    }
    if (artifact.role === 'coordinator' && artifact.result.status === 'prepared') {
      const review = packet.dependencies.find(value => value.role === 'reviewer').artifact.result;
      const qa = packet.dependencies.find(value => value.role === 'qa').artifact.result;
      if (review.outcome !== 'candidate' || qa.outcome !== 'pass') error('Prepared handoff requires reviewer candidate and QA pass');
    }
  }
  record(jobId, artifact, leaseId) {
    return this.withLock(jobId, directory => {
      const job = json(join(directory, 'job.json')); this.verify(directory, job);
      const stage = job.stages.find(value => value.role === artifact.role);
      if (!stage) error('Unknown role');
      const outputBytes = JSON.stringify(artifact, null, 2) + '\n';
      if (stage.status === 'complete') {
        if (sha(outputBytes) !== stage.outputHash) error('Completed artifact is immutable');
        return { status: 'already_recorded', outputHash: stage.outputHash };
      }
      if (stage.status !== 'leased' || stage.leaseId !== leaseId || stage.leaseUntil <= this.now()) error('Missing or expired lease');
      const packet = this.packet(directory, job, stage); this.checkArtifact(directory, job, artifact, packet);
      const artifactDirectory = join(directory, 'artifacts'); mkdirSync(artifactDirectory, { recursive: true, mode: 0o700 });
      atomic(join(artifactDirectory, `${stage.role}.json`), artifact);
      stage.outputHash = sha(outputBytes); stage.status = 'complete'; delete stage.leaseId; delete stage.leaseUntil;
      job.events.push({ type: 'recorded', role: stage.role, outputHash: stage.outputHash, at: new Date(this.now()).toISOString() });
      if (stage.role === 'coordinator') job.status = artifact.result.status === 'prepared' ? 'complete' : 'blocked';
      atomic(join(directory, 'job.json'), job);
      try{this.memory.ingestJob(this.root,jobId);}catch(cause){job.events.push({type:'learning_sync_failed',reason:cause.message,at:new Date(this.now()).toISOString()});atomic(join(directory,'job.json'),job);}
      return { status: job.status, role: stage.role, outputHash: stage.outputHash };
    });
  }
  fail(jobId, leaseId, reason) {
    return this.withLock(jobId, directory => {
      const job = json(join(directory, 'job.json')); this.verify(directory, job);
      const stage = job.stages.find(value => value.leaseId === leaseId && value.status === 'leased');
      if (!stage) error('Unknown lease');
      stage.status = stage.attempts >= json(join(directory, 'config.json')).manifest.maxAttempts ? 'failed' : 'pending';
      delete stage.leaseId; delete stage.leaseUntil;
      job.status = stage.status === 'failed' ? 'failed' : 'pending';
      job.events.push({ type: 'attempt_failed', role: stage.role, reason: String(reason).slice(0, 500), at: new Date(this.now()).toISOString() });
      atomic(join(directory, 'job.json'), job);
      try{this.memory.ingestJob(this.root,jobId);}catch{}
      return { status: job.status, role: stage.role };
    });
  }
  async exportRelease(jobId, base) {
    const job = this.status(jobId), directory = this.dir(jobId);
    if (job.status !== 'complete') error('Complete candidate pipeline required before export');
    if (json(join(directory, 'scope.json')).mode !== 'research') error('Fixture jobs cannot export production drafts');
    const read = role => json(join(directory, 'artifacts', `${role}.json`)).result;
    const research = read('researcher'), edited = read('editor'), review = read('reviewer'), qa = read('qa'), coordinator = read('coordinator');
    if (review.outcome !== 'candidate' || qa.outcome !== 'pass' || coordinator.status !== 'prepared') error('Candidate review and QA pass required');
    if (!edited.drafts.length) error('At least one content draft required');
    const { validateRelease, releaseHash } = await import('../developer/catalog_repository.mjs');
    const release = validateRelease(base);
    const baseHash = releaseHash(release);
    for (const draft of edited.drafts) {
      const entry = release.entries.find(value => value.sourceId === draft.sourceId);
      if (!entry) error('New TAP requires provider author to supply full catalog metadata; existing sourceId required');
      entry.title = draft.title; entry.applicability = draft.applicability;
      for (const change of draft.steps) {
        const manual = `${change.manual}\n\n완료 기준\n${change.completionCriteria}\n\n예외 대응\n${change.exceptionAction}`;
        if (manual.length > 700) error('Manual with completion criteria and exception action exceeds 700 characters');
        const source = research.sources.find(value => change.evidenceSourceIds.includes(value.id));
        if (!source || source.kind !== 'external') error('Exported Task requires external evidence');
        const step = entry.steps.find(value => value.id === change.id);
        if (step) Object.assign(step, { title: change.title, manual, sourceUrl: source.url });
        else entry.steps.push({ id: change.id, title: change.title, manual, tip: '', tags: [], imageUrl: '', videoUrl: '', sourceUrl: source.url });
        for (const evidenceId of change.evidenceSourceIds) {
          const evidence = research.sources.find(value => value.id === evidenceId);
          if (!evidence || evidence.kind !== 'external') error('Exported evidence must be external');
          if (!entry.references.some(value => value.url === evidence.url)) entry.references.push({ title: evidence.title, url: evidence.url, checkedAt: evidence.retrievedAt.slice(0, 10), scope: evidence.applicability });
        }
      }
      // reviewedAt remains the existing catalog value. Agent candidate is not human approval.
    }
    const validated = validateRelease(release, { assignId: true });
    if (validated.releaseId === baseHash) error('Draft contains no content changes');
    return { draftRequest: { release: validated, summary: edited.changeSummary, revision: 0 },
      provenance: { jobId, baseReleaseId: base.releaseId, baseHash, scopeHash: job.scopeHash,
        outputHashes: Object.fromEntries(job.stages.map(stage => [stage.role, stage.outputHash])),
        humanReviewRequired: true, requiredHumanChecks: review.requiredHumanChecks, publishAllowed: false } };
  }
  unlock(jobId) {
    const lock = join(this.dir(jobId), '.lock');
    if (!existsSync(lock)) return { status: 'unlocked' };
    const ownerPath = join(lock, 'owner.json');
    if (!existsSync(ownerPath)) error('Unknown lock owner; inspect interrupted filesystem write');
    const owner = json(ownerPath);
    try { process.kill(owner.pid, 0); error('Lock owner is still running'); }
    catch (cause) { if (cause.code !== 'ESRCH') throw cause; }
    rmSync(lock, { recursive: true, force: true });
    return { status: 'unlocked', recoveredPid: owner.pid };
  }
  status(jobId) {
    const directory = this.dir(jobId), job = json(join(directory, 'job.json')); this.verify(directory, job); return job;
  }
}

export function fixtureArtifact(packet) {
  if (packet.scope.mode !== 'fixture') error('Fixture runner requires fixture job');
  const excerpt = 'LOCAL FIXTURE: 인계할 미완료 항목과 다음 담당을 기록한다. 외부 조사 근거가 아니다.';
  const result = {
    researcher: { gaps: [packet.scope.gap], sources: [{ id: 'fixture-handoff', kind: 'fixture', title: '로컬 인계 테스트', url: '', publisher: 'tap2work test fixture', retrievedAt: '2026-10-07T00:00:00Z', jurisdiction: 'test-only', applicability: '실제 매장에 적용하지 않는 테스트', excerpt, evidenceHash: sha(excerpt) }], claims: [{ statement: '테스트 계약은 미완료 항목과 담당을 기록한다.', sourceIds: ['fixture-handoff'] }], unresolved: ['실제 현장·외부 근거 조사는 수행하지 않음'] },
    editor: { drafts: [{ sourceId: 'fixture-handoff', title: '미완료 항목 인계', applicability: '테스트 전용', steps: [{ id: 'handoff-note', title: '인계할 항목 기록', manual: '미완료 항목과 다음 담당을 테스트 메모에 적는다.', completionCriteria: '항목과 담당이 메모에 존재함', exceptionAction: '담당이 없으면 테스트 조율자에게 미지정으로 전달', evidenceSourceIds: ['fixture-handoff'] }] }], changeSummary: '실제 현장 검토 전의 fixture 초안', evidenceSourceIds: ['fixture-handoff'], requiresHumanReview: true },
    reviewer: { outcome: 'candidate', findings: ['로컬 테스트 계약만 확인'], requiredHumanChecks: ['실제 근거와 현장 적용 조건 확인 필요'], humanApproved: false },
    qa: { outcome: 'pass', checks: ['로컬 artifact 계약과 근거 ID 연결 확인'], blockers: [] },
    coordinator: { status: 'prepared', handoff: 'fixture 결과. 생산 DB 등록/발행 금지. 실제 조사는 별도 research job으로 진행.', nextGaps: ['인계 담당 부재'], blockers: [], publishAllowed: false },
  }[packet.role];
  return { schemaVersion: 1, jobId: packet.jobId, role: packet.role, inputHash: packet.inputHash, result };
}

export async function runCodex(packet, { maxSeconds = manifest().maxRunnerSeconds, executable = 'codex' } = {}) {
  // No repo ancestors, operating state, inherited Supabase/service keys or user MCP config.
  const runnerEnv = Object.fromEntries(['PATH', 'HOME', 'TMPDIR', 'LANG', 'LC_ALL', 'CODEX_HOME'].filter(key => process.env[key]).map(key => [key, process.env[key]]));
  const isolated = mkdtempSync(join(tmpdir(), 'tap2work-content-agent-'));
  mkdirSync(join(isolated, 'input'), { mode: 0o700 });
  const { runDirectory, leaseId, status, ...safePacket } = packet;
  atomic(join(isolated, 'packet.json'), safePacket);
  atomic(join(isolated, 'scope.json'), packet.scope);
  atomic(join(isolated, 'output-schema.json'), packet.outputSchema);
  writeFileSync(join(isolated, 'AGENTS.md'), packet.prompt + '\nReturn only the output JSON. Read packet.json first.\n', { mode: 0o600 });
  for (const dependency of packet.dependencies) atomic(join(isolated, 'input', `${dependency.role}.json`), dependency.artifact);
  const output = join(isolated, 'response.json');
  const args = ['--search', '--ask-for-approval', 'never', 'exec', '--ignore-user-config', '--ephemeral', '--sandbox', 'read-only', '--skip-git-repo-check', '--cd', isolated,
    '--output-schema', join(isolated, 'output-schema.json'), '--output-last-message', output, '--color', 'never', '-'];
  try {
    await new Promise((resolveRun, rejectRun) => {
      const child = spawn(executable, args, { cwd: isolated, env: runnerEnv, detached: process.platform !== 'win32', stdio: ['pipe', 'ignore', 'pipe'] });
      let diagnostic = '';
      child.stderr.on('data', data => { diagnostic = (diagnostic + data.toString()).slice(-8000); });
      const safeDiagnostic = () => diagnostic.replace(/\bsk-[a-zA-Z0-9_-]{8,}|\beyJ[a-zA-Z0-9_-]{20,}(?:\.[a-zA-Z0-9_-]+){1,2}/g, '[REDACTED]').replace(/(?:Bearer|apikey[=:])\s*[^\s]+/gi, '[REDACTED]').slice(-1200);
      const timer = setTimeout(() => {
        try { if (process.platform !== 'win32' && child.pid) process.kill(-child.pid, 'SIGKILL'); else child.kill('SIGKILL'); } catch { child.kill('SIGKILL'); }
        rejectRun(Error('Runner exceeded job deadline'));
      }, maxSeconds * 1000);
      child.on('error', cause => { clearTimeout(timer); rejectRun(cause); });
      child.on('close', code => { clearTimeout(timer); code === 0 ? resolveRun() : rejectRun(Error(`Runner exited ${code}: ${safeDiagnostic()}`)); });
      child.stdin.on('error', () => {});
      child.stdin.end('Read AGENTS.md and packet.json. Produce one JSON artifact following output-schema.json. Scope includes manuals, checklists and industry menu/ingredient/recipe research drafts. You have no production credentials or publication authority.');
    });
    if (bytes(output).length > 1024 * 1024) error('Artifact exceeds 1MB');
    const artifact = json(output);
    atomic(join(runDirectory, 'response.json'), artifact);
    return artifact;
  } finally { rmSync(isolated, { recursive: true, force: true }); }
}

// Aside is an explicit research runner; subsequent editing/review retain the same queue.
export async function runAside(packet, {executable='aside', maxSeconds=manifest().maxRunnerSeconds}={}) {
  if (packet.role !== 'researcher' || packet.scope.mode !== 'research') error('Aside is available for research-mode researcher only');
  const env = Object.fromEntries(['PATH','HOME','TMPDIR','LANG','LC_ALL'].filter(key=>process.env[key]).map(key=>[key,process.env[key]]));
  const call = args => new Promise((resolveRun,rejectRun)=> {
    const child=spawn(executable,args,{env,stdio:['ignore','pipe','pipe'],detached:process.platform!=='win32'});
    let output='', diagnostic='';
    const stop=()=>{try {if(process.platform!=='win32'&&child.pid) process.kill(-child.pid,'SIGKILL');else child.kill('SIGKILL');}catch{child.kill('SIGKILL');}};
    const timer=setTimeout(()=>{stop();rejectRun(Error('Aside research deadline exceeded'));},maxSeconds*1000);
    child.stdout.on('data',data=>{output+=data.toString();if(output.length>1024*1024){stop();rejectRun(Error('Aside output exceeds 1MB'));}});
    child.stderr.on('data',data=>{diagnostic=(diagnostic+data).slice(-500);});
    child.on('error',cause=>{clearTimeout(timer);rejectRun(cause);});
    child.on('close',code=>{clearTimeout(timer);code===0?resolveRun(output):rejectRun(Error(`Aside exited ${code}; research not recorded`));});
  });
  const guide=await call(['guide']);
  if (!guide.includes('aside exec')) error('Aside guide unavailable; update CLI and retry');
  const {runDirectory,leaseId,status,...safe}=packet;
  const prompt = `Read-only public web research. Do not use private browser history, credentials, messages, purchases or modify files. You are already executing inside Aside CLI. Use your provided browser tools directly; do not invoke another aside command or spawn another CLI session.\nRead this sanitized research packet and return ONLY one JSON envelope matching outputSchema. Research industry major menu candidates, ingredients, recipe sequence, manual and checklist actions. Link each claim to sources actually opened. Record household/product-specific limitations; never invent quantities, cooking temperatures, shelf life or source verification. Do not publish.\n${JSON.stringify(safe)}`;
  const raw=await call(['exec',prompt]);
  // Preserve failed results for inspection; never guess a successful envelope.
  writeFileSync(join(runDirectory,'aside-response.txt'),raw,{mode:0o600});
  const clean=raw.replace(/\x1b\[[0-9;]*m/g,'');
  let artifact;
  for(let start=clean.lastIndexOf('{');start>=0;start=clean.lastIndexOf('{',start-1)) {
    try {
      const tail=clean.slice(start), end=tail.lastIndexOf('}');
      const candidate=JSON.parse(tail.slice(0,end+1));
      if(candidate.jobId===packet.jobId && candidate.role==='researcher'){artifact=candidate;break;}
    } catch { /* CLI may include progress before the final JSON. */ }
    if(start===0) break;
  }
  if(!artifact) error('Aside did not return the required research JSON; inspect aside-response.txt');
  // Compute hashes from returned excerpt bytes, then the normal team validator applies.
  for(const source of artifact.result?.sources??[]) source.evidenceHash=sha(source.excerpt);
  return artifact;
}

async function cli() {
  const [command, ...args] = process.argv.slice(2);
  const options = {};
  for (let index = 0; index < args.length; index += 2) {
    if (!args[index]?.startsWith('--') || !args[index + 1]) error('Use --name value arguments');
    options[args[index].slice(2)] = args[index + 1];
  }
  const team = new ContentTeam({ root: options.root });
  let result;
  if (command === 'init') result = team.init(options.job, json(resolve(options.scope)));
  else if (command === 'next') result = team.next(options.job);
  else if (command === 'unlock') result = team.unlock(options.job);
  else if (command === 'status' || command === 'validate') result = team.status(options.job);
  else if (command === 'record') {
    const file = realpathSync(resolve(options.artifact));
    if (bytes(file).length > 1024 * 1024) error('Artifact exceeds 1MB');
    result = team.record(options.job, json(file), options.lease);
  } else if (command === 'export-release') {
    if (!options.out || !options.base) error('Export requires --base and --out');
    if (resolve(options.out) === resolve(options.base)) error('Export cannot overwrite base release');
    result = await team.exportRelease(options.job, json(resolve(options.base)));
    if (existsSync(resolve(options.out)) || existsSync(resolve(options.out) + '.provenance.json')) error('Output already exists; choose a new path');
    atomic(resolve(options.out), result.draftRequest);
    atomic(resolve(options.out) + '.provenance.json', result.provenance);
  }
  else if (command === 'fail') result = team.fail(options.job, options.lease, options.reason ?? 'Runner failed');
  else if (command === 'run') {
    if (!['codex', 'fixture', 'aside'].includes(options.runner)) error('Choose --runner codex, aside or fixture');
    const packet = team.next(options.job);
    if (packet.status !== 'ready') result = packet;
    else try { result = team.record(options.job, options.runner === 'fixture' ? fixtureArtifact(packet) : options.runner === 'aside' ? await runAside(packet) : await runCodex(packet), packet.leaseId); }
    catch (cause) { team.fail(options.job, packet.leaseId, cause.message); throw cause; }
  } else if (command === 'smoke') {
    const jobId = options.job ?? `fixture-${Date.now()}`;
    team.init(jobId, json(join(teamRoot, 'samples/gap.json')));
    for (let index = 0; index < manifest().roles.length; index += 1) {
      const packet = team.next(jobId);
      if (packet.status === 'ready') team.record(jobId, fixtureArtifact(packet), packet.leaseId);
    }
    result = team.status(jobId);
  } else error('Commands: init, next, record, fail, status, validate, unlock, export-release, run, smoke');
  process.stdout.write(JSON.stringify(result, null, 2) + '\n');
}
if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) cli().catch(cause => { process.stderr.write(cause.message + '\n'); process.exitCode = 1; });
