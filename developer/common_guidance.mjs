import { StoreError } from './store.mjs';
import { canonicalLocale, supportedLocales } from './localization.mjs';
const fail = (message, status = 400) => { throw new StoreError(message, status); };
export function welcomeContent(state) {
  return structuredClone(state.welcome ?? { revision: 1, importantRevision: 1, sourceLocale: 'ko', title: '우리 매장에 오신 것을 환영해요', body: '처음 하는 일은 동료와 함께 확인해 주세요. 모르는 점이나 위험한 상황은 바로 물어봐도 괜찮아요.', updatedAt: null, updatedBy: null });
}
export function guidanceView(state, actor) {
  const welcome = welcomeContent(state);
  const welcomeAcknowledgment = structuredClone(state.welcomeAcknowledgments?.[actor.id] ?? null);
  return { welcome, welcomeAcknowledgment, welcomeNeedsAcknowledgment: !welcomeAcknowledgment || welcomeAcknowledgment.importantRevision < welcome.importantRevision };
}
export function mutateGuidance(state, input, actor, now) {
  if (input.action === 'save_language_preference') {
    const locale = canonicalLocale(input.locale);
    if (!supportedLocales.includes(locale)) fail('지원하는 언어를 선택해 주세요.');
    state.actorPreferences ??= {};
    state.actorPreferences[actor.id] = { ...state.actorPreferences[actor.id], locale };
    return true;
  }
  if (input.action === 'ack_welcome') {
    const welcome = welcomeContent(state);
    if (input.welcomeRevision !== welcome.revision) fail('안내가 바뀌었어요. 최신 내용을 확인해 주세요.', 409);
    state.welcomeAcknowledgments ??= {};
    state.welcomeAcknowledgments[actor.id] = { revision: welcome.revision, importantRevision: welcome.importantRevision, at: now.toISOString() };
    return true;
  }
  if (input.action !== 'save_welcome') return false;
  if (!['owner', 'manager'].includes(actor.role) || actor.role !== 'owner' && state.workplace?.restrictions?.[actor.role]?.tasks === false) fail('매뉴얼 편집 권한이 필요해요.', 403);
  const value = input.welcome;
  if (!value || typeof value.title !== 'string' || !value.title.trim() || value.title.trim().length > 120 || typeof value.body !== 'string' || !value.body.trim() || value.body.trim().length > 8000) fail('제목은 1–120자, 안내는 1–8000자로 입력해 주세요.');
  const sourceLocale = canonicalLocale(value.sourceLocale ?? 'ko');
  if (!supportedLocales.includes(sourceLocale) || input.important != null && typeof input.important !== 'boolean') fail('안내 언어와 중요 변경 여부를 확인해 주세요.');
  const before = welcomeContent(state), revision = before.revision + 1;
  state.welcome = { revision, importantRevision: input.important === true ? revision : before.importantRevision, sourceLocale, title: value.title.trim(), body: value.body.trim(), updatedAt: now.toISOString(), updatedBy: actor.id };
  return true;
}
// Shared reference content only; private schedules, assignments and edit history
// stay behind their existing permission projections.
export function readableTemplates(templates) {
  const pick = (row, keys) => Object.fromEntries(keys.filter(key => row[key] !== undefined).map(key => [key, structuredClone(row[key])]));
  return templates.filter(row => !row.archivedAt).map(row => ({
    ...pick(row, ['id', 'title', 'manualTitle', 'emoji', 'folderId', 'zone', 'partId', 'version', 'manualCustomization', 'sourceLocale', 'knowledge', 'menuManualId']),
    settings: pick(row.settings ?? {}, ['usage', 'enabled', 'type']),
    steps: (row.steps ?? []).map(step => pick(step, ['id', 'title', 'manualTitle', 'manual', 'tip', 'tags', 'imageUrl', 'videoUrl', 'sourceUrl', 'contentRevision'])),
  }));
}
