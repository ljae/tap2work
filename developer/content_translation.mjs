import { createHash } from 'node:crypto';
import { StoreError } from './store.mjs';
import { welcomeContent } from './common_guidance.mjs';
import { supportedLocales } from './localization.mjs';
import { composeManual } from './manual_setup.mjs';
const fail = (message, status = 400) => { throw new StoreError(message, status); };
const googleLocale = locale => locale === 'zh-Hans' ? 'zh-CN' : locale;
const text = value => typeof value === 'string' ? value : '';
export function translationSource(state, source) {
  if (source.kind === 'welcome') {
    const welcome = welcomeContent(state);
    return { sourceLocale: welcome.sourceLocale, original: { title: welcome.title, body: welcome.body } };
  }
  let row = (source.kind === 'manual' ? state.taskTemplates : state.tasks)?.find(row => row.id === source.id && !row.archivedAt && !row.supersededAt);
  if (!row) fail('번역할 매장 안내를 찾지 못했어요.', 404);
  if (source.kind === 'manual') row = composeManual(state, row);
  return { sourceLocale: supportedLocales.includes(row.sourceLocale) ? row.sourceLocale : 'auto', original: {
    title: text(row.manualTitle ?? row.title),
    steps: (row.steps ?? []).map(step => ({ id: step.id, title: text(step.manualTitle ?? step.title), manual: text(step.manual), tip: text(step.tip) })),
  } };
}
function fields(original) {
  const rows = [[original, 'title']];
  if ('body' in original) rows.push([original, 'body']);
  for (const step of original.steps ?? []) for (const key of ['title', 'manual', 'tip']) rows.push([step, key]);
  return rows.filter(([row, key]) => row[key].trim());
}
async function readInput(request) {
  if (request.method !== 'POST') fail('POST 요청이 필요해요.', 405);
  if (!request.headers.get('content-type')?.startsWith('application/json')) fail('JSON 요청이 필요해요.', 415);
  const reader = request.body?.getReader();
  let raw = '', size = 0;
  const decoder = new TextDecoder();
  if (reader) try { for (;;) { const { done, value } = await reader.read(); if (done) break; size += value.length; if (size > 2048) { await reader.cancel(); fail('번역 요청이 너무 커요.', 413); } raw += decoder.decode(value, { stream: true }); } } finally { reader.releaseLock(); }
  raw += decoder.decode();
  let input; try { input = JSON.parse(raw); } catch { fail('번역 요청을 확인해 주세요.'); }
  if (!input || typeof input !== 'object' || Array.isArray(input) || Object.keys(input).some(k => !['workspaceId','targetLocale','source'].includes(k))) fail('번역할 매장 안내를 선택해 주세요.');
  const { workspaceId, targetLocale, source } = input;
  if (typeof workspaceId !== 'string' || !/^[a-zA-Z0-9-]{1,80}$/.test(workspaceId) || !supportedLocales.includes(targetLocale)) fail('매장과 번역 언어를 확인해 주세요.');
  if (!source || typeof source !== 'object' || Array.isArray(source) || Object.keys(source).some(k => !['kind','id'].includes(k)) || !['welcome','manual','task'].includes(source.kind) || (source.kind !== 'welcome' && (typeof source.id !== 'string' || !source.id || source.id.length > 200)) || (source.kind === 'welcome' && source.id != null)) fail('번역할 안내를 확인해 주세요.');
  return input;
}
export function createContentTranslationHandler({ rest, sectionStorage, fetcher = fetch, apiKey, enabled = false, clock = () => new Date() }) {
  return async ({ request, user, cors }) => {
    const { workspaceId, targetLocale, source } = await readInput(request);
    const members = await rest(`tap2work_members?user_id=eq.${user.id}&workspace_id=eq.${workspaceId}&select=workspace_id,role`);
    if (!members.some(member => member.workspace_id === workspaceId)) fail('이 매장 안내에 접근할 권한이 없어요.', 403);
    const document = sectionStorage
      ? await rest('rpc/tap2work_read_workspace', { method: 'POST', body: JSON.stringify({ p_user_id: user.id, p_workspace_id: workspaceId, p_revision: null, p_window: null, p_role: null }) })
      : { payload: (await rest(`tap2work_state?workspace_id=eq.${workspaceId}&select=payload`))[0]?.payload };
    if (document.forbidden || !document.payload) fail('이 매장 안내에 접근할 권한이 없어요.', 403);
    const { original, sourceLocale } = translationSource(document.payload, source);
    const sourceHash = createHash('sha256').update(JSON.stringify({ version: 1, source, sourceLocale, original })).digest('hex');
    const base = { source, sourceHash, sourceLocale, targetLocale, original, translated: null, cached: false };
    const reply = (status, extra = {}) => new Response(JSON.stringify({ ...base, status, ...extra }), { headers: cors });
    if (sourceLocale === targetLocale) return reply('original');
    const strings = fields(original).map(([row,key]) => row[key]);
    const characters = strings.reduce((n,value) => n + value.length, 0);
    if (!enabled || !apiKey || !strings.length || characters > 20000 || strings.some(value => value.length > 8000) || (original.steps?.length ?? 0) > 64) return reply('unavailable');
    // Cache is private, workspace scoped and content addressed. It never stores
    // a client-selected URL or increments the operations CAS revision.
    let cached;
    try { cached = await rest(`tap2work_content_translations?workspace_id=eq.${workspaceId}&source_hash=eq.${sourceHash}&target_locale=eq.${targetLocale}&created_at=gte.${encodeURIComponent(new Date(clock().getTime() - 30 * 86400000).toISOString())}&select=translated`); } catch { return reply('unavailable'); }
    if (cached[0]?.translated) return reply('translated', { translated: cached[0].translated, cached: true });
    let allowed;
    try { allowed = await rest('rpc/tap2work_reserve_translation', { method: 'POST', body: JSON.stringify({ p_workspace_id: workspaceId, p_user_id: user.id, p_characters: characters }) }); } catch { return reply('unavailable'); }
    if (!allowed) return reply('rate_limited');
    const translated = structuredClone(original), output = fields(translated);
    // One timeout covers all batches; no retries can amplify a paid request.
    const signal = AbortSignal.timeout(12000);
    try {
      let offset = 0;
      while (offset < strings.length) {
        const batch = []; let length = 0;
        while (offset + batch.length < strings.length && batch.length < 64) {
          const value = strings[offset + batch.length];
          if (batch.length && length + value.length > 10000) break;
          batch.push(value); length += value.length;
        }
        const response = await fetcher('https://translation.googleapis.com/language/translate/v2', {
          method: 'POST', signal, headers: { 'Content-Type': 'application/json', 'X-Goog-Api-Key': apiKey },
          body: JSON.stringify({ q: batch, target: googleLocale(targetLocale), format: 'text', ...(sourceLocale === 'auto' ? {} : { source: googleLocale(sourceLocale) }) }),
        });
        if (!response.ok) return reply(response.status === 429 ? 'rate_limited' : 'unavailable');
        const rows = (await response.json())?.data?.translations;
        if (!Array.isArray(rows) || rows.length !== batch.length || rows.some(row => typeof row.translatedText !== 'string' || !row.translatedText.trim() || row.translatedText.length > 24000)) return reply('unavailable');
        rows.forEach((row,index) => { const [object,key] = output[offset + index]; object[key] = row.translatedText; });
        offset += batch.length;
      }
      // FK + current membership recheck protect deletion/revocation races.
      const current = await rest(`tap2work_members?user_id=eq.${user.id}&workspace_id=eq.${workspaceId}&select=workspace_id,role`);
      if (!current.some(member => member.workspace_id === workspaceId)) fail('매장 접근이 변경되었어요.', 403);
      await rest('tap2work_content_translations?on_conflict=workspace_id,source_hash,target_locale', { method: 'POST', headers: { Prefer: 'resolution=merge-duplicates,return=minimal' }, body: JSON.stringify({ workspace_id: workspaceId, source_hash: sourceHash, target_locale: targetLocale, translated, created_at: clock().toISOString() }) });
      return reply('translated', { translated });
    } catch (error) {
      if (error instanceof StoreError && error.status === 403) throw error;
      return reply('unavailable');
    }
  };
}
