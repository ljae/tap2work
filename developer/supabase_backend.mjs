import { OperationsStore, seedOperations, emptyOperations } from './operations.mjs';
import { ensureStaff } from './staff.mjs';
import { StoreError } from './store.mjs';

// Both Edge Functions and Node tests use this handler; demo actor headers are ignored.
export function createCloudHandler({ url, serviceKey, origins = ['https://tap2.work', 'https://www.tap2.work'], fetcher = fetch, clock = () => new Date() }) {
  if (!url || !serviceKey) throw new Error('Supabase server configuration is missing');
  const headers = { apikey: serviceKey, ...(serviceKey.startsWith('eyJ') ? { Authorization: `Bearer ${serviceKey}` } : {}), 'Content-Type': 'application/json' };
  async function rest(path, options = {}) {
    const response = await fetcher(`${url}/rest/v1/${path}`, { ...options, headers: { ...headers, ...options.headers } });
    if (!response.ok) throw new StoreError('클라우드 저장소를 준비하지 못했어요. 관리자에게 연결 상태를 확인해 주세요.', 503);
    return response.status === 204 ? null : response.json();
  }
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
      let memberships = await rest(`tap2work_members?user_id=eq.${user.id}&select=workspace_id,role,display_name`);
      let createdWorkspace = false;
      if (!memberships.length) {
        if (request.method === 'GET') return reply(200, { needsWorkspace: true, authenticated: true });
        if (!request.headers.get('content-type')?.startsWith('application/json')) throw new StoreError('JSON 요청이 필요해요.', 415);
        const raw = await request.text();
        if (new TextEncoder().encode(raw).length > 1024) throw new StoreError('요청 크기가 너무 커요.', 413);
        let setup; try { setup = JSON.parse(raw); } catch { throw new StoreError('요청 형식을 확인해 주세요.'); }
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
        memberships = await rest(`tap2work_members?user_id=eq.${user.id}&select=workspace_id,role,display_name`);
      }
      const member = memberships[0];
      if (!member) throw new StoreError('매장 권한이 없어요.', 403);
      const actor = { id: user.id, name: member.display_name, role: member.role, label: {owner:'사장님',manager:'매니저',cook:'조리 담당',crew:'크루'}[member.role] };
      const persistence = {
        async read() {
          const rows = await rest(`tap2work_state?workspace_id=eq.${member.workspace_id}&select=payload`);
          if (!rows[0]) throw new StoreError('매장을 찾지 못했어요.', 404);
          return rows[0].payload;
        },
        async save(state, revision) {
          const saved = await rest('rpc/tap2work_save_state', { method: 'POST', body: JSON.stringify({ p_workspace_id: member.workspace_id, p_expected_revision: revision, p_payload: state }) });
          if (!saved) throw new StoreError('동료가 먼저 수정했어요. 새로고침 후 다시 시도해 주세요.', 409);
        },
      };
      const store = new OperationsStore(null, clock, { persistence, actor });
      let result;
      if (request.method === 'GET' || createdWorkspace) result = await store.snapshot(user.id);
      else {
        if (!request.headers.get('content-type')?.startsWith('application/json')) throw new StoreError('JSON 요청이 필요해요.', 415);
        const text = await request.text();
        if (new TextEncoder().encode(text).length > 2 * 1024 * 1024) throw new StoreError('요청 크기가 너무 커요.', 413);
        let input; try { input = JSON.parse(text); } catch { throw new StoreError('요청 형식을 확인해 주세요.'); }
        if (!input || typeof input !== 'object' || Array.isArray(input)) throw new StoreError('요청 형식을 확인해 주세요.');
        result = await store.mutate(user.id, input);
      }
      return reply(200, { ...result, workspaceId: member.workspace_id });
    } catch (error) {
      return reply(error instanceof StoreError ? error.status : 500, { error: error instanceof StoreError ? error.message : '요청을 처리하지 못했어요. 다시 시도해 주세요.' });
    }
  };
}
