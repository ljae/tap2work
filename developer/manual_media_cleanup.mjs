import { StoreError } from './store.mjs';
const bucket = 'tap2work-manual-media';
const workspacePattern = /^[a-zA-Z0-9-]{1,80}$/;
// Tombstones are deliberately retained and swept again after success: an upload
// authorized before workspace erasure may finish after the first cleanup pass.
export async function cleanupDeletedWorkspaceMedia({ url, headers, fetcher = fetch, workspaceIds, clock = () => new Date(), maxBatches = 3, deadline = Infinity }) {
  const jsonHeaders = { ...headers, 'Content-Type': 'application/json' };
  const call = async (path, options = {}) => {
    const remaining = deadline - Date.now();
    if (remaining <= 0) throw new StoreError('사진 정리 시간이 지나 다음 실행에서 이어서 처리해요.', 503);
    const response = await fetcher(`${url}${path}`, { ...options, headers: { ...jsonHeaders, ...options.headers }, signal: AbortSignal.timeout(Math.min(10000, Math.ceil(remaining))) });
    if (!response.ok) throw new StoreError('삭제된 매장의 사진 정리를 다시 시도해야 해요.', 503);
    return response.status === 204 ? null : response.json();
  };
  if (workspaceIds?.some(id => !workspacePattern.test(id))) throw new StoreError('사진 정리 범위를 확인해 주세요.');
  if (workspaceIds?.length === 0) return { pending: false, processed: 0 };
  const filter = workspaceIds ? `workspace_id=in.(${workspaceIds.join(',')})` : `next_attempt_at=lte.${encodeURIComponent(clock().toISOString())}`;
  const jobs = await call(`/rest/v1/tap2work_media_deletions?${filter}&select=workspace_id&order=next_attempt_at&limit=20`);
  let pending = false, processed = 0;
  for (const job of jobs) {
    if (Date.now() >= deadline) { pending = true; break; }
    const id = job.workspace_id;
    if (!workspacePattern.test(id)) { pending = true; continue; }
    try {
      const existing = await call(`/rest/v1/tap2work_workspaces?id=eq.${id}&select=id`);
      if (existing.length) throw new StoreError('현재 매장의 사진은 삭제하지 않아요.', 409);
      let complete = false;
      for (let batch = 0; batch < maxBatches; batch++) {
        const objects = await call(`/storage/v1/object/list/${bucket}`, { method: 'POST', body: JSON.stringify({ prefix: `${id}/`, limit: 100, offset: 0, sortBy: { column: 'name', order: 'asc' } }) });
        if (!Array.isArray(objects)) throw new StoreError('사진 목록을 확인하지 못했어요.', 503);
        if (!objects.length) { complete = true; break; }
        if (objects.some(o => typeof o.name !== 'string' || !/^[a-f0-9-]{36}\.jpg$/.test(o.name))) throw new StoreError('사진 정리 경로를 확인해 주세요.', 503);
        await call(`/storage/v1/object/${bucket}`, { method: 'DELETE', body: JSON.stringify({ prefixes: objects.map(o => `${id}/${o.name}`) }) });
      }
      pending ||= !complete;
      await call(`/rest/v1/tap2work_media_deletions?workspace_id=eq.${id}`, { method: 'PATCH', headers: { Prefer: 'return=minimal' }, body: JSON.stringify({ last_attempt_at: clock().toISOString(), next_attempt_at: new Date(clock().getTime() + (complete ? 86400000 : 300000)).toISOString() }) });
      processed++;
    } catch {
      // Keep the committed tombstone, but move a failed prefix out of the
      // current batch so twenty persistent failures cannot starve newer jobs.
      // One best-effort update only: a DB outage leaves it due for the next run.
      pending = true;
      try {
        const attemptedAt = clock();
        await call(`/rest/v1/tap2work_media_deletions?workspace_id=eq.${id}`, { method: 'PATCH', headers: { Prefer: 'return=minimal' }, body: JSON.stringify({ last_attempt_at: attemptedAt.toISOString(), next_attempt_at: new Date(attemptedAt.getTime() + 300000).toISOString() }) });
      } catch { /* No auth session is needed when the retry worker resumes. */ }
    }
  }
  return { pending: pending || jobs.length === 20, processed };
}
