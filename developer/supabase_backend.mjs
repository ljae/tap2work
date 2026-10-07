import {DatabaseCatalogRepository} from './catalog_repository.mjs';
import { OperationsStore, seedOperations, emptyOperations } from './operations.mjs';
import { sectionPatch } from './section_storage.mjs';
import { ensureStaff } from './staff.mjs';
import { StoreError } from './store.mjs';

// Both Edge Functions and Node tests use this handler; demo actor headers are ignored.
export function createCloudHandler({ url, serviceKey, origins = ['https://tap2.work', 'https://www.tap2.work'], fetcher = fetch, clock = () => new Date(), sectionStorage = false, requireSocialIdentity = false, catalogDatabase = false, catalogRepository = null }) {
  if (!url || !serviceKey) throw new Error('Supabase server configuration is missing');
  const headers = { apikey: serviceKey, ...(serviceKey.startsWith('eyJ') ? { Authorization: `Bearer ${serviceKey}` } : {}), 'Content-Type': 'application/json' };
  async function rest(path, options = {}) {
    const response = await fetcher(`${url}/rest/v1/${path}`, { ...options, headers: { ...headers, ...options.headers } });
    if (!response.ok) throw new StoreError('클라우드 저장소를 준비하지 못했어요. 관리자에게 연결 상태를 확인해 주세요.', 503);
    return response.status === 204 ? null : response.json();
  }
  const catalogs = catalogRepository ?? (catalogDatabase ? new DatabaseCatalogRepository(rest) : null);
  return async request => {
    const origin = request.headers.get('origin');
    const cors = { 'Content-Type': 'application/json; charset=utf-8', 'Cache-Control': 'no-store', Vary: 'Origin' };
    if (origin && origins.includes(origin)) Object.assign(cors, { 'Access-Control-Allow-Origin': origin, 'Access-Control-Allow-Methods': 'GET, POST, OPTIONS', 'Access-Control-Allow-Headers': 'authorization, apikey, content-type, x-client-info' });
    const reply = (status, data) => new Response(JSON.stringify(data), { status, headers: cors });
    if (origin && !origins.includes(origin)) return reply(403, { error: '허용된 앱 주소에서 연결해 주세요.' });
    if (request.method === 'OPTIONS') return new Response(null, { status: 204, headers: cors });
    try {
      if (!['GET', 'POST'].includes(request.method)) throw new StoreError('지원하지 않는 요청이에요.', 405);
      const authorization = request.headers.get('authorization');
      if (!authorization?.startsWith('Bearer ')) throw new StoreError('로그인 후 이용해 주세요.', 401);
      // Ask Auth to validate the session, including token expiry/revocation policy.
      const auth = await fetcher(`${url}/auth/v1/user`, { headers: { apikey: serviceKey, Authorization: authorization } });
      if (!auth.ok) throw new StoreError('로그인이 만료됐어요. 다시 로그인해 주세요.', 401);
      const user = await auth.json();
      if (!/^[\da-f-]{36}$/i.test(user.id ?? '')) throw new StoreError('사용자를 확인하지 못했어요.', 401);
      if (requireSocialIdentity && !user.identities?.some(i => ['apple','google'].includes(i.provider))) throw new StoreError('Apple 또는 Google로 다시 로그인해 주세요.', 403);
      const query = new URL(request.url).searchParams;
      const catalogSnapshot = catalogs ? await catalogs.readPublished() : null;
      const catalogMatches = !catalogSnapshot || query.get('catalogRevision') === String(catalogSnapshot.revision);
      let input;
      if (request.method === 'POST') {
        if (!request.headers.get('content-type')?.startsWith('application/json')) throw new StoreError('JSON 요청이 필요해요.',415);
        const raw = await request.text();
        if (new TextEncoder().encode(raw).length > 2 * 1024 * 1024) throw new StoreError('요청 크기가 너무 커요.',413);
        try { input=JSON.parse(raw); } catch { throw new StoreError('요청 형식을 확인해 주세요.'); }
        if (!input || typeof input !== 'object' || Array.isArray(input)) throw new StoreError('요청 형식을 확인해 주세요.');
      }
      if (input?.action === 'create_workspace' && query.get('view') === 'employee') throw new StoreError('내 계정 화면에서 매장을 추가해 주세요.',403);
      let selectedWorkspace = input?.action === 'create_workspace' ? null : input?.workspaceId ?? query.get('workspace');
      if (selectedWorkspace != null && (typeof selectedWorkspace !== 'string' || !/^[a-zA-Z0-9-]{1,80}$/.test(selectedWorkspace))) throw new StoreError('매장 선택을 확인해 주세요.');
      const readWorkspace = () => rest('rpc/tap2work_read_workspace', {method:'POST', body:JSON.stringify({
        p_user_id:user.id,
        p_revision:catalogMatches && request.method === 'GET' && !query.has('scheduleFrom') && !query.has('scheduleTo') && query.get('view') !== 'employee' && /^\d+$/.test(query.get('revision') ?? '') ? Number(query.get('revision')) : null,
        p_window:request.method === 'GET' && /^\d+$/.test(query.get('window') ?? '') ? Number(query.get('window')) : null,
        p_role:request.method === 'GET' ? query.get('role') : null,
        p_workspace_id: selectedWorkspace,
      })});
      let document = sectionStorage ? await readWorkspace() : null;
      if (document?.forbidden) return reply(403, {error:'이 매장에 접근할 권한이 없어요. 다른 매장을 선택해 주세요.',workspaces:document.workspaces});
      if (document?.unchanged) return reply(200, {...document,...(catalogSnapshot?{catalogRevision:catalogSnapshot.revision}: {})});
      let memberships = sectionStorage ? (document.member ? [document.member] : []) : await rest(`tap2work_members?user_id=eq.${user.id}&select=workspace_id,role,display_name`);
      let createdWorkspace = false;
      if (input?.action === 'create_workspace' && input.requestId != null && sectionStorage) {
        const name = typeof input.name === 'string' ? input.name.trim() : '';
        if (!name || name.length > 80 || !/^[\da-f]{8}-[\da-f]{4}-[\da-f]{4}-[\da-f]{4}-[\da-f]{12}$/i.test(input.requestId) || input.mode !== 'blank') throw new StoreError('매장 이름을 1~80자로 입력해 주세요.');
        const ownerName=String(user.user_metadata?.display_name || '사장님').trim().slice(0,80) || '사장님';
        const initial=emptyOperations(clock(),user.id,ownerName);
        initial.store.name=name;
        selectedWorkspace=await rest('rpc/tap2work_create_workspace',{method:'POST',body:JSON.stringify({p_user_id:user.id,p_name:ownerName,p_state:initial,p_request_id:input.requestId})});
        document=await readWorkspace();
        memberships=document.member ? [document.member] : [];
        createdWorkspace=true;
      }
      if (!memberships.length) {
        if (request.method === 'GET') return reply(200, { needsWorkspace: true, authenticated: true });
        const setup = input;
        if (setup?.action !== 'create_workspace' || !['blank', 'sample'].includes(setup.mode) || setup.revision !== 0) throw new StoreError('시작 방식을 선택해 주세요.');
        const ownerName = String(user.user_metadata?.display_name || '사장님').trim().slice(0, 80) || '사장님';
        const initial = setup.mode === 'blank' ? emptyOperations(clock(), user.id, ownerName) : seedOperations(clock());
        if (setup.mode === 'sample') {
          ensureStaff(initial, clock());
          Object.assign(initial.tappers.find(t => t.actorId === 'owner'), { actorId: user.id, nickname: ownerName });
          initial.store.setup = 'sample';
        }
        await rest('rpc/tap2work_bootstrap', { method: 'POST', body: JSON.stringify({ p_user_id: user.id, p_name: ownerName, p_state: initial }) });
        createdWorkspace = true;
        if (sectionStorage) document = await readWorkspace();
        memberships = sectionStorage ? [document.member] : await rest(`tap2work_members?user_id=eq.${user.id}&select=workspace_id,role,display_name`);
      }
      if (request.method === 'POST' && !createdWorkspace && !selectedWorkspace && (document?.workspaces?.length ?? memberships.length) > 1) throw new StoreError('매장을 선택한 뒤 다시 저장해 주세요.',409);
      const member = selectedWorkspace && !sectionStorage ? memberships.find(m=>m.workspace_id===selectedWorkspace) : memberships[0];
      if (!member) throw new StoreError('매장 권한이 없어요.', 403);
      const actor = { id: user.id, name: member.display_name, role: member.role, label: {owner:'사장님',manager:'매니저',cook:'조리 담당',crew:'크루'}[member.role] };
      let original = document?.payload;
      const employeeMode = query.get('view') === 'employee';
      if (employeeMode) {
        if (member.role !== 'owner') throw new StoreError('화면 전환 권한이 없어요.',403);
        const payload = original ?? (await rest(`tap2work_state?workspace_id=eq.${member.workspace_id}&select=payload`))[0]?.payload;
        const employee = payload?.tappers?.find(t => t.id === payload.sharedEmployeeId && t.active && t.rank === 'crew');
        if (!employee) throw new StoreError('직원 화면을 먼저 연결해 주세요.',409);
        Object.assign(actor,{id:employee.actorId,name:employee.nickname,role:'crew',label:'단기 계약 크루'});
      }
      const persistence = {
        async read() {
          if (sectionStorage) return structuredClone(original);
          const rows = await rest(`tap2work_state?workspace_id=eq.${member.workspace_id}&select=payload`);
          if (!rows[0]) throw new StoreError('매장을 찾지 못했어요.', 404);
          return rows[0].payload;
        },
        async save(state, revision) {
          const patch = sectionStorage ? sectionPatch(original, state) : null;
          const saved = await rest(sectionStorage ? 'rpc/tap2work_patch_state' : 'rpc/tap2work_save_state', { method:'POST', body:JSON.stringify({
            p_workspace_id:member.workspace_id, p_expected_revision:revision,
            ...(sectionStorage ? {p_changes:patch.changes,p_removed:patch.removed} : {p_payload:state}),
          }) });
          if (saved && sectionStorage) original = structuredClone(state);
          if (!saved) throw new StoreError('동료가 먼저 수정했어요. 새로고침 후 다시 시도해 주세요.', 409);
        },
      };
      const store = new OperationsStore(null, clock, { persistence, actor, ...(catalogSnapshot?{catalog:catalogSnapshot.release,catalogRevision:catalogSnapshot.revision}:{}) });
      let result;
      if (request.method === 'GET' || createdWorkspace) result = await store.snapshot(user.id, Object.fromEntries(query));
      else result = await store.mutate(user.id, input);
      return reply(200, { ...result, ...(catalogSnapshot?{catalogRevision:catalogSnapshot.revision,catalogReleaseId:catalogSnapshot.release.releaseId}:{}), canSwitchEmployee: member.role === 'owner', employeeMode, workspaceId: member.workspace_id, ...(document?.workspaces ? {workspaces: document.workspaces.map(w=>w.id===member.workspace_id?{...w,name:result.store?.name ?? w.name}:w)} : {}), ...(sectionStorage ? {syncWindow: document.window} : {}) });
    } catch (error) {
      return reply(error instanceof StoreError ? error.status : 500, { error: error instanceof StoreError ? error.message : '요청을 처리하지 못했어요. 다시 시도해 주세요.' });
    }
  };
}
