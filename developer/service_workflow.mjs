import {businessDate} from './business_day.mjs';
import {createHash, randomUUID} from 'node:crypto';
import {StoreError} from './store.mjs';
import {contentHash} from './manual_catalog_schema.mjs';
import {serviceGuides} from './service_guides.mjs';

const fail = (message, status = 400) => {throw new StoreError(message, status);};
const leader = (state, actor) => actor.role === 'owner' || actor.role === 'manager' && state.workplace?.restrictions?.manager?.tasks !== false;
const short = (value, max = 500, required = true) => {
  if (typeof value !== 'string' || value.trim().length > max || required && !value.trim()) fail('짧은 내용을 입력해 주세요.');
  return value.trim();
};
const canonical = value => Array.isArray(value) ? value.map(canonical) : value && typeof value === 'object'
  ? Object.fromEntries(Object.keys(value).sort().map(key => [key, canonical(value[key])])) : value;
const fingerprint = input => createHash('sha256').update(JSON.stringify(canonical(Object.fromEntries(Object.entries(input).filter(([key]) => key !== 'revision'))))).digest('hex');
const actions = new Set(['register_service_guide', 'save_service_briefing', 'record_service', 'confirm_service_practice', 'resolve_service_handoff']);
const manual = (state, id) => {
  const row = state.taskTemplates.find(t => t.id === id && !t.archivedAt && t.registration?.status !== 'pending');
  if (!row) fail('등록된 매뉴얼을 확인해 주세요.', 404);
  return row;
};
const crew = (state, id) => {
  const row = state.tappers.find(t => t.id === id && t.active);
  if (!row) fail('현재 근무 크루를 확인해 주세요.', 409);
  return row;
};
const records = state => state.serviceRecords ?? [];
export function serviceRequestReplay(state, input, actor) {
  if (!actions.has(input.action) || !input.requestId) return false;
  const old = (state.serviceReceipts ?? []).find(r => r.requestId === input.requestId && r.actorId === actor.id);
  if (!old) return false;
  if (old.hash !== fingerprint(input)) fail('같은 요청 번호에 다른 내용을 사용할 수 없어요.', 409);
  return true;
}
export function serviceWorkflowView(state, actor) {
  const editable = leader(state, actor), rows = records(state);
  const confirmation = id => rows.find(r => r.kind === 'practice_confirmation' && r.practiceId === id);
  const resolution = id => rows.find(r => r.kind === 'handoff_resolution' && r.handoffId === id);
  const current = (state.serviceBriefing?.manualIds ?? []).map(id => state.taskTemplates.find(t => t.id === id && !t.archivedAt && t.registration?.status !== 'pending')).filter(Boolean);
  return {
    day: state.day, ownShifts: (state.staffShifts ?? []).filter(s => state.tappers.some(t => t.id === s.tapperId && t.active && t.actorId === actor.id) && !['leave','off','OFF','cancelled'].includes(s.status) && businessDate(state, `${s.date}T${s.start}:00+09:00`) === state.day).map(s => ({id:s.id,date:s.date,start:s.start,end:s.end,partId:s.partId,partName:state.workplace?.parts?.find(p => p.id === s.partId)?.name ?? ''})), briefing: {...structuredClone(state.serviceBriefing ?? {manualIds: [], note: ''}), hash: briefingHash(state),
      manuals: current.map(t => ({id: t.id, title: t.title, version: t.version, hash: contentHash(t)}))},
    guides: actor.role === 'owner' ? serviceGuides.filter(g => !state.taskTemplates.some(t => t.serviceGuideId === g.id && !t.archivedAt)).map(g => ({...structuredClone(g), hash: contentHash(g)})) : [],
    records: rows.filter(r => r.kind === 'handoff' || r.kind === 'practice' && (editable || r.actor.id === actor.id || crewActor(state, r.buddyCrewId) === actor.id)
      || ['briefing', 'feedback'].includes(r.kind) && (editable || r.actor.id === actor.id))
      .map(r => {
        const value = structuredClone(r);
        if (r.kind === 'practice') value.confirmation = structuredClone(confirmation(r.id) ?? null);
        if (r.kind === 'handoff') {
          value.resolution = structuredClone(resolution(r.id) ?? null);
          value.canResolve = !value.resolution && (editable || crewActor(state, r.assigneeId) === actor.id);
          value.assignee = state.tappers.find(t => t.id === r.assigneeId && t.active)?.nickname ?? null;
        }
        return value;
      }).sort((a, b) => b.at.localeCompare(a.at)),
    manuals: state.taskTemplates.filter(t => !t.archivedAt && t.registration?.status !== 'pending').map(t => ({id: t.id, title: t.title, version: t.version, hash: contentHash(t)})),
    canConfigure: editable,
  };
}
const crewActor = (state, id) => state.tappers.find(t => t.id === id && t.active)?.actorId;
export function mutateServiceWorkflow(state, input, actor, now) {
  if (!actions.has(input.action)) return false;
  if (!/^[A-Za-z0-9_-]{1,80}$/.test(input.requestId ?? '')) fail('저장 요청 번호를 확인해 주세요.');
  if ((state.serviceReceipts ?? []).length >= 5000 || records(state).length >= 5000) fail('기록 보관 공간을 확인해 주세요.', 409);
  const actorStamp = {id: actor.id, name: actor.name, role: actor.label};
  const event = value => ({id: randomUUID(), day: state.day, at: now.toISOString(), actor: actorStamp, ...value});
  let entry;
  if (input.action === 'register_service_guide') {
    if (actor.role !== 'owner') fail('사장님이 내용을 확인한 뒤 등록해 주세요.', 403);
    const guide = serviceGuides.find(g => g.id === input.guideId);
    if (!guide || input.reviewedHash !== contentHash(guide)) fail('최신 CS 안내를 확인해 주세요.', 409);
    if (state.taskTemplates.some(t => t.serviceGuideId === guide.id && !t.archivedAt)) fail('이미 등록한 안내예요.', 409);
    const folderId = 'service-training';
    if (!state.checklistFolders.some(f => f.id === folderId)) state.checklistFolders.push({id: folderId, name: 'CS 연습'});
    state.taskTemplates.push({...structuredClone(guide), id: randomUUID(), serviceGuideId: guide.id, folderId, version: 1,
      slot: '준비', requiredRole: 'all', zone: null, sourceIds: [], assignmentScopeVersion: 2,
      registration: {status: 'registered', at: now.toISOString(), by: actorStamp},
      knowledge: {scope: 'store', topics: ['CS'], menuNames: [], ingredientNames: [], suggestedUse: 'reference', useCase: 'training'},
      settings: {type: 'general', usage: 'reference', enabled: false, recurrence: {mode: 'daily', weekdays: []}, assignment: {mode: 'anyone'}, allowBulkComplete: false, enforceSequence: false, completionPolicy: {kind: 'check', quantitySpec: null}, estimatedMinutes: null},
    });
  } else if (input.action === 'save_service_briefing') {
    if (!leader(state, actor)) fail('매뉴얼 편집 권한이 필요해요.', 403);
    if (!Array.isArray(input.manualIds) || input.manualIds.length > 3 || new Set(input.manualIds).size !== input.manualIds.length) fail('안내는 최대 3개를 선택해 주세요.');
    for (const id of input.manualIds) manual(state, id);
    state.serviceBriefing = {manualIds: [...input.manualIds], note: short(input.note ?? '', 300, false), updatedAt: now.toISOString(), updatedBy: actorStamp};
  } else if (input.action === 'record_service') {
    if (!['briefing', 'practice', 'handoff', 'feedback'].includes(input.kind)) fail('기록 종류를 확인해 주세요.');
    const note = short(input.note ?? '', 500, input.kind !== 'briefing');
    entry = event({kind: input.kind, note});
    if (input.kind === 'briefing') {
      const ids = (state.serviceBriefing?.manualIds ?? []).filter(id => state.taskTemplates.some(t => t.id === id && !t.archivedAt && t.registration?.status !== 'pending'));
      const refs = ids.map(id => {const t = manual(state, id); return {id, version: t.version, hash: contentHash(t)};});
      if (input.briefingHash !== fingerprint({manuals: refs, note: state.serviceBriefing?.note ?? ''})) fail('시작 안내가 바뀌었어요. 다시 확인해 주세요.', 409);
      entry.manuals = refs;
      entry.briefingNote = state.serviceBriefing?.note ?? '';
    }
    if (input.templateId) {
      const t = manual(state, input.templateId);
      if (input.manualHash !== contentHash(t)) fail('매뉴얼이 바뀌었어요. 최신 내용을 확인해 주세요.', 409);
      entry.manual = {id: t.id, version: t.version, hash: contentHash(t), title: t.title};
    }
    if (input.kind === 'practice') {
      if (!entry.manual) fail('연습할 매뉴얼을 선택해 주세요.');
      const buddy = crew(state, input.buddyCrewId);
      if (!buddy.actorId || buddy.actorId === actor.id) fail('본인 이외의 연결된 버디를 선택해 주세요.');
      entry.buddyCrewId = buddy.id;
    }
    if (input.kind === 'handoff') {
      entry.nextAction = short(input.nextAction, 300);
      entry.assigneeId = input.assigneeId == null ? null : crew(state, input.assigneeId).id;
      entry.phase = input.phase === 'closing' ? 'closing' : 'handoff';
    }
    if (input.kind === 'feedback') {
      if (!['unknown', 'staffing', 'stock', 'equipment', 'handoff', 'manual'].includes(input.cause)) fail('문제 분류를 확인해 주세요.');
      entry.cause = input.cause;
      if (!['unmeasured', 'helpful', 'needs_changes'].includes(input.outcome ?? 'unmeasured')) fail('결과를 확인해 주세요.');
      entry.outcome = input.outcome ?? 'unmeasured';
    }
  } else if (input.action === 'confirm_service_practice') {
    const practice = records(state).find(r => r.id === input.practiceId && r.kind === 'practice');
    if (!practice) fail('연습 기록을 찾지 못했어요.', 404);
    if (practice.actor.id === actor.id || crewActor(state, practice.buddyCrewId) !== actor.id) fail('지정된 버디가 별도로 확인해 주세요.', 403);
    if (records(state).some(r => r.practiceId === practice.id)) fail('이미 버디가 확인했어요.', 409);
    if (contentHash(manual(state, practice.manual.id)) !== practice.manual.hash) fail('연습 후 매뉴얼이 바뀌었어요. 새 내용으로 연습해 주세요.', 409);
    entry = event({kind: 'practice_confirmation', practiceId: practice.id, note: short(input.note, 300)});
  } else if (input.action === 'resolve_service_handoff') {
    const handoff = records(state).find(r => r.id === input.handoffId && r.kind === 'handoff');
    if (!handoff) fail('인계 기록을 찾지 못했어요.', 404);
    if (!leader(state, actor) && crewActor(state, handoff.assigneeId) !== actor.id) fail('담당 크루 또는 권한 있는 리더가 처리해 주세요.', 403);
    if (records(state).some(r => r.handoffId === handoff.id)) fail('이미 처리된 인계예요.', 409);
    entry = event({kind: 'handoff_resolution', handoffId: handoff.id, note: short(input.note, 300)});
  }
  if (entry) (state.serviceRecords ??= []).push(entry);
  (state.serviceReceipts ??= []).push({requestId: input.requestId, actorId: actor.id, hash: fingerprint(input)});
  return true;
}
export function briefingHash(state) {
  return fingerprint({manuals: (state.serviceBriefing?.manualIds ?? []).filter(id => state.taskTemplates.some(t => t.id === id && !t.archivedAt && t.registration?.status !== 'pending')).map(id => {
    const t = manual(state, id); return {id, version: t.version, hash: contentHash(t)};
  }), note: state.serviceBriefing?.note ?? ''});
}
