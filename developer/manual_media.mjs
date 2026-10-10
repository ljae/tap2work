import { assertIssuePhotoPermission, issuePhotoReceipt } from './work_issue_media.mjs';
import { randomUUID } from 'node:crypto';
import { StoreError } from './store.mjs';
import { manualMediaPrefix, parseManualMediaReference } from './manual_media_reference.mjs';

export const manualMediaBucket = 'tap2work-manual-media';
export const manualPhotoMaxBytes = 250000;
export const manualPhotoMaxDimension = 1280;
const maxRequestBytes = 340000;
const fail = (message, status = 400) => { throw new StoreError(message, status); };

// Validate references on every cloud mutation, including nested backup imports.
// Scope never comes from a photo string; it comes from the verified membership.
export function validateManualMediaScope(input, workspaceId) {
  const pending = [input];
  while (pending.length) {
    const value = pending.pop();
    if (typeof value === 'string' && value.startsWith(manualMediaPrefix)) {
      const photo = parseManualMediaReference(value);
      if (!photo) fail('사진 참조를 확인해 주세요.');
      if (photo.workspaceId !== workspaceId) fail('다른 매장의 비공개 사진은 가져올 수 없어요. 이 매장에서 사진을 다시 등록해 주세요.', 403);
    } else if (value && typeof value === 'object') {
      for (const child of Object.values(value)) pending.push(child);
    }
  }
}

// Explicit backup restore transfers contents, not another store's private files.
// The caller supplies authenticated workspace scope (null for the local demo).
export function stripForeignBackupPhotos(input, workspaceId) {
  if (input?.action !== 'restore_checklist_backup' || !input.backup) return 0;
  let removed = 0;
  const pending = [input.backup];
  while (pending.length) {
    const value = pending.pop();
    if (!value || typeof value !== 'object') continue;
    for (const [key, child] of Object.entries(value)) {
      const photo = ['imageUrl', 'photo'].includes(key) ? parseManualMediaReference(child) : null;
      if (photo && photo.workspaceId !== workspaceId) { value[key] = ''; removed++; }
      else if (child && typeof child === 'object') pending.push(child);
    }
  }
  return removed;
}

async function boundedBytes(stream, limit) {
  if (!stream) return new Uint8Array();
  const reader = stream.getReader(), chunks = [];
  let length = 0;
  try {
    for (;;) {
      const { done, value } = await reader.read();
      if (done) break;
      length += value.length;
      if (length > limit) { await reader.cancel(); fail('사진은 최적화 후 250KB 이내로 등록해 주세요.', 413); }
      chunks.push(value);
    }
  } finally { reader.releaseLock(); }
  const bytes = new Uint8Array(length);
  let offset = 0;
  for (const chunk of chunks) { bytes.set(chunk, offset); offset += chunk.length; }
  return bytes;
}

export function validateOptimizedJpeg(photo) {
  if (typeof photo !== 'string' || !photo.startsWith('data:image/jpeg;base64,')) fail('최적화한 JPG 사진을 선택해 주세요.', 415);
  const base64 = photo.slice(23);
  if (!base64 || base64.length > Math.ceil(manualPhotoMaxBytes / 3) * 4) fail('사진은 최적화 후 250KB 이내로 등록해 주세요.', 413);
  if (!/^(?:[A-Za-z0-9+/]{4})*(?:[A-Za-z0-9+/]{2}==|[A-Za-z0-9+/]{3}=)?$/.test(base64)) fail('사진 파일을 확인해 주세요.');
  const raw = atob(base64);
  if (raw.length > manualPhotoMaxBytes) fail('사진은 최적화 후 250KB 이내로 등록해 주세요.', 413);
  const bytes = Uint8Array.from(raw, c => c.charCodeAt(0));
  const invalid = () => fail('사진을 다시 최적화해 주세요. 유효한 JPG 파일이 필요해요.');
  if (bytes.length < 20 || bytes[0] !== 0xff || bytes[1] !== 0xd8) invalid();
  let offset = 2, width, height, scans = 0;
  // Validate marker bounds and dimensions without platform image decoders.
  // APP1 (EXIF/XMP), APP13 (IPTC), comments and unknown APP metadata are rejected.
  while (offset < bytes.length) {
    if (bytes[offset++] !== 0xff) invalid();
    while (bytes[offset] === 0xff) offset++;
    const marker = bytes[offset++];
    if (marker === 0xd9) {
      if (!width || !height || !scans || offset !== bytes.length) invalid();
      return { bytes, width, height };
    }
    if (marker == null || marker === 0 || marker === 0xd8 || (marker >= 0xd0 && marker <= 0xd7)) invalid();
    const size = (bytes[offset] << 8) | bytes[offset + 1];
    if (size < 2 || offset + size > bytes.length) invalid();
    if (marker === 0xfe || (marker >= 0xe1 && marker <= 0xef && marker !== 0xe2 && marker !== 0xee)) fail('위치·촬영 정보가 제거된 최적화 사진을 등록해 주세요.');
    if (marker >= 0xc0 && marker <= 0xcf && ![0xc4, 0xc8, 0xcc].includes(marker)) {
      if (![0xc0, 0xc2].includes(marker) || width || size < 8 || bytes[offset + 2] !== 8) invalid();
      height = (bytes[offset + 3] << 8) | bytes[offset + 4];
      width = (bytes[offset + 5] << 8) | bytes[offset + 6];
      const components = bytes[offset + 7];
      if (![1, 3].includes(components) || size !== 8 + 3 * components) invalid();
      if (!width || !height || width > manualPhotoMaxDimension || height > manualPhotoMaxDimension) fail('사진의 긴 변을 1280px 이내로 줄여 주세요.');
    }
    offset += size;
    if (marker === 0xda) {
      if (!width) invalid();
      scans++;
      // Entropy data may contain stuffed FF00 bytes or restart markers.
      while (offset < bytes.length) {
        if (bytes[offset] !== 0xff) { offset++; continue; }
        const next = bytes[offset + 1];
        if (next === 0 || (next >= 0xd0 && next <= 0xd7)) { offset += 2; continue; }
        break;
      }
    }
  }
  invalid();
}

export function createManualMediaHandler({ url, headers, rest, fetcher, sectionStorage, signingKey = headers.apikey, clock = () => new Date() }) {
  return async ({ request, user, query, cors }) => {
    const upload = request.method === 'POST' && query.get('media') === 'upload';
    if (!upload && request.method !== 'GET') fail('지원하지 않는 사진 요청이에요.', 405);
    let input;
    if (upload) {
      if (!request.headers.get('content-type')?.startsWith('application/json')) fail('JSON 요청이 필요해요.', 415);
      const length = request.headers.get('content-length');
      if (length && Number(length) > maxRequestBytes) fail('사진 요청 크기가 너무 커요.', 413);
      const bytes = await boundedBytes(request.body, maxRequestBytes);
      try { input = JSON.parse(new TextDecoder('utf-8', { fatal: true }).decode(bytes)); } catch { fail('사진 요청 형식을 확인해 주세요.'); }
      if (!input || typeof input !== 'object' || Array.isArray(input)) fail('사진 요청 형식을 확인해 주세요.');
    }
    const workspaceId = upload ? input.workspaceId : query.get('workspace');
    if (typeof workspaceId !== 'string' || !/^[a-zA-Z0-9-]{1,80}$/.test(workspaceId)) fail('사진을 사용할 매장을 선택해 주세요.');
    const members = await rest(`tap2work_members?user_id=eq.${user.id}&workspace_id=eq.${workspaceId}&select=workspace_id,role`);
    const member = members.find(m => m.workspace_id === workspaceId);
    if (!member) fail('이 매장 사진에 접근할 권한이 없어요.', 403);
    if (upload) {
      const issue = input.purpose === 'work_issue';
      if (input.purpose != null && !issue) fail('사진 사용 목적을 확인해 주세요.');
      const readDocument = async () => sectionStorage
        ? await rest('rpc/tap2work_read_workspace', { method:'POST', body:JSON.stringify({p_user_id:user.id,p_workspace_id:workspaceId,p_revision:null,p_window:null,p_role:null}) })
        : {payload:(await rest(`tap2work_state?workspace_id=eq.${workspaceId}&select=payload`))[0]?.payload};
      if (issue) {
        if(typeof input.taskId !== 'string' || input.taskId.length>300) fail('담당 업무를 확인해 주세요.');
        const document = await readDocument();
        if(document.forbidden || !document.payload) fail('매장 접근이 변경됐어요.',403);
        assertIssuePhotoPermission(document.payload,member,user.id,input.taskId,clock());
      } else {
        if (query.get('view') === 'employee' || !['owner','manager'].includes(member.role)) fail('사장님 또는 권한 있는 매니저만 사진을 등록할 수 있어요.',403);
        if (member.role === 'manager') {
          const document = await readDocument();
          if(document.forbidden || !document.payload || document.payload.workplace?.restrictions?.manager?.tasks === false) fail('사장님이 이 직책의 매뉴얼 편집 권한을 껐어요.',403);
        }
      }
      const photo = validateOptimizedJpeg(input.photo);
      const path = `${workspaceId}/${randomUUID()}.jpg`;
      const response = await fetcher(`${url}/storage/v1/object/${manualMediaBucket}/${path}`, {
        method: 'POST', headers: { ...headers, 'Content-Type': 'image/jpeg', 'x-upsert': 'false', 'Cache-Control': 'no-store' }, body: photo.bytes,
      });
      if (!response.ok) fail('사진을 저장하지 못했어요. 연결 상태를 확인한 뒤 다시 시도해 주세요.', 503);
      // Erasure may commit while Storage is writing. Recheck membership after
      // the upload, compensate immediately, and rely on retained workspace
      // deletion tombstones if this process/compensation fails.
      const currentMembers = await rest(`tap2work_members?user_id=eq.${user.id}&workspace_id=eq.${workspaceId}&select=workspace_id,role`);
      let stillAllowed = currentMembers.some(m => m.workspace_id === workspaceId && m.role === member.role);
      if (stillAllowed && issue) {
        try { const document = await readDocument(); assertIssuePhotoPermission(document.payload,currentMembers.find(m=>m.workspace_id===workspaceId),user.id,input.taskId,clock()); } catch { stillAllowed = false; }
      }
      if (!stillAllowed) {
        try {
          await fetcher(`${url}/storage/v1/object/${manualMediaBucket}`, { method: 'DELETE', headers, body: JSON.stringify({ prefixes: [path] }) });
        } catch { /* durable workspace erasure worker retries removed stores */ }
        fail('매장 접근이 변경되어 사진을 등록하지 않았어요.', 403);
      }
      // Attachment uses the existing state revision/CAS; failed attachment must
      // never delete this immutable object, which another/history reference may use.
      return new Response(JSON.stringify({ reference: `${manualMediaPrefix}${path}`, ...(issue ? {receipt:issuePhotoReceipt({userId:user.id,workspaceId,taskId:input.taskId,reference:`${manualMediaPrefix}${path}`},signingKey,clock())} : {}), contentType: 'image/jpeg', bytes: photo.bytes.length, width: photo.width, height: photo.height }), { status: 201, headers: cors });
    }
    const photo = parseManualMediaReference(query.get('media'));
    if (!photo) fail('사진 참조를 확인해 주세요.');
    if (photo.workspaceId !== workspaceId) fail('다른 매장의 사진을 볼 수 없어요.', 403);
    const response = await fetcher(`${url}/storage/v1/object/authenticated/${manualMediaBucket}/${photo.path}`, { headers });
    if (!response.ok) fail(response.status === 404 || response.status === 400 ? '사진을 찾지 못했어요.' : '사진을 불러오지 못했어요.', response.status === 404 || response.status === 400 ? 404 : 503);
    const bytes = await boundedBytes(response.body, manualPhotoMaxBytes);
    return new Response(bytes, { status: 200, headers: { ...cors, 'Content-Type': 'image/jpeg', 'Content-Length': String(bytes.length), 'X-Content-Type-Options': 'nosniff' } });
  };
}
