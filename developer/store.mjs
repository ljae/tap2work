import { readFile, writeFile, rename, mkdir } from 'node:fs/promises';
import path from 'node:path';
import { randomUUID } from 'node:crypto';

export const statuses = ['confirmed', 'proposed', 'deferred', 'superseded'];
export class StoreError extends Error {
  constructor(message, status = 400) { super(message); this.status = status; }
}
function required(value, label, max = 6000) {
  if (typeof value !== 'string' || !value.trim() || value.length > max) {
    throw new StoreError(`${label}: 1~${max}자의 내용을 입력해 주세요.`);
  }
  return value.trim();
}
function decisionFields(input) {
  if (!statuses.includes(input.status)) throw new StoreError('올바른 결정 상태를 선택해 주세요.');
  return {
    category: required(input.category, '분류', 80),
    title: required(input.title, '제목', 200),
    status: input.status,
    decision: required(input.decision, '결정 내용'),
    reason: required(input.reason, '결정 근거'),
  };
}
export class ProjectStore {
  #queue = Promise.resolve();
  constructor(filename) { this.filename = filename; }
  async read() {
    const state = JSON.parse(await readFile(this.filename, 'utf8'));
    if (state.schemaVersion !== 1 || !Number.isInteger(state.revision) ||
        !Array.isArray(state.decisions) || !Array.isArray(state.history) || !Array.isArray(state.milestones)) {
      throw new StoreError('프로젝트 파일 형식을 확인해 주세요. 기존 파일은 덮어쓰지 않았습니다.', 500);
    }
    return state;
  }
  mutate(revision, update) {
    const operation = this.#queue.then(async () => {
      const state = await this.read();
      if (!Number.isInteger(revision) || revision !== state.revision) {
        throw new StoreError('다른 변경이 먼저 저장되었습니다. 새로 읽은 내용을 확인한 뒤 다시 저장해 주세요.', 409);
      }
      const previous = structuredClone(state);
      const now = new Date().toISOString();
      update(state, now);
      state.revision += 1;
      // Preserve a recoverable copy before replacing the canonical file.
      const backupDir = path.join(path.dirname(this.filename), 'history-backups');
      await mkdir(backupDir, { recursive: true });
      await writeFile(path.join(backupDir, `revision-${previous.revision}-${randomUUID()}.json`), JSON.stringify(previous, null, 2) + '\n', { flag: 'wx' });
      const temporary = path.join(path.dirname(this.filename), `.project-state-${randomUUID()}.tmp`);
      await writeFile(temporary, JSON.stringify(state, null, 2) + '\n', { flag: 'wx' });
      await rename(temporary, this.filename);
      return state;
    });
    this.#queue = operation.catch(() => {});
    return operation;
  }
  updateDecision(id, input) {
    const fields = decisionFields(input);
    const changeReason = required(input.changeReason, '이번 변경 이유', 2000);
    return this.mutate(input.revision, (state, now) => {
      const index = state.decisions.findIndex(item => item.id === id);
      if (index < 0) throw new StoreError('결정사항을 찾지 못했습니다.', 404);
      const before = structuredClone(state.decisions[index]);
      const after = { ...before, ...fields, updatedAt: now };
      state.decisions[index] = after;
      state.history.push({ id: `H-${randomUUID()}`, at: now, type: 'decision', title: `${id} · ${after.title} 변경`, detail: changeReason, decisionId: id, before, after, files: ['docs/project-state.json'], verification: '개발자 웹에서 변경 이유와 함께 저장.' });
    });
  }
  addDecision(input) {
    const fields = decisionFields(input);
    const changeReason = required(input.changeReason, '등록 이유', 2000);
    return this.mutate(input.revision, (state, now) => {
      const number = Math.max(0, ...state.decisions.map(item => Number(item.id.replace('D-', '')) || 0)) + 1;
      const decision = { id: `D-${String(number).padStart(3, '0')}`, ...fields, source: '개발자 웹에서 등록', updatedAt: now };
      state.decisions.push(decision);
      state.history.push({ id: `H-${randomUUID()}`, at: now, type: 'decision', title: `${decision.id} · ${decision.title} 등록`, detail: changeReason, decisionId: decision.id, before: null, after: decision, files: ['docs/project-state.json'], verification: '개발자 웹에서 직접 등록.' });
    });
  }
  addHistory(input) {
    const title = required(input.title, '제목', 200);
    const detail = required(input.detail, '기록 내용');
    const verification = required(input.verification, '검증 또는 확인 사항', 2000);
    if (!['note', 'implementation', 'test', 'research'].includes(input.type)) throw new StoreError('올바른 기록 종류를 선택해 주세요.');
    return this.mutate(input.revision, (state, now) => {
      state.history.push({ id: `H-${randomUUID()}`, at: now, type: input.type, title, detail, verification, files: [] });
    });
  }
}
