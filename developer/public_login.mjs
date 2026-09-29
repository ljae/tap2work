// Temporary shared-account entry. No caller-supplied identity or password.
export function createPublicLoginHandler({url, serviceKey, email, enabled = false, origins = ['https://tap2.work', 'https://www.tap2.work'], fetcher = fetch}) {
  return async request => {
    const origin = request.headers.get('origin');
    const headers = {'Content-Type':'application/json', 'Cache-Control':'no-store', Vary:'Origin'};
    if (origins.includes(origin)) Object.assign(headers, {'Access-Control-Allow-Origin':origin, 'Access-Control-Allow-Methods':'POST, OPTIONS', 'Access-Control-Allow-Headers':'apikey, authorization, content-type, x-client-info'});
    const reply = (status, body) => new Response(JSON.stringify(body), {status, headers});
    if (origin && !origins.includes(origin)) return reply(403, {error:'허용된 앱 주소에서 연결해 주세요.'});
    if (request.method === 'OPTIONS') return new Response(null, {status:204, headers});
    if (request.method !== 'POST') return reply(405, {error:'로그인 버튼을 눌러 주세요.'});
    if (!enabled || !email) return reply(503, {error:'공용 로그인이 현재 비활성화되어 있어요.'});
    try {
      // Check an existing account first: generate_link must never create users.
      const lookup = await fetcher(`${url}/rest/v1/rpc/tap2work_public_login_account`, {method:'POST', headers:{apikey:serviceKey, Authorization:`Bearer ${serviceKey}`, 'Content-Type':'application/json'}, body:JSON.stringify({p_email:email})});
      const id = lookup.ok ? await lookup.json() : null;
      if (!id) return reply(503, {error:'공용 계정 연결을 확인해 주세요.'});
      const authHeaders = {apikey:serviceKey, Authorization:`Bearer ${serviceKey}`, 'Content-Type':'application/json'};
      const link = await fetcher(`${url}/auth/v1/admin/generate_link`, {method:'POST', headers:authHeaders, body:JSON.stringify({type:'magiclink', email})});
      if (!link.ok) throw new Error('link');
      const data = await link.json();
      if (data.id !== id || !data.hashed_token) throw new Error('identity');
      const verify = await fetcher(`${url}/auth/v1/verify`, {method:'POST', headers:authHeaders, body:JSON.stringify({type:'magiclink', token_hash:data.hashed_token})});
      if (!verify.ok) throw new Error('verify');
      const session = await verify.json();
      if (session.user?.id !== id || !session.refresh_token) throw new Error('session');
      return reply(200, {refresh_token:session.refresh_token});
    } catch { return reply(502, {error:'로그인 연결이 지연되고 있어요. 다시 시도해 주세요.'}); }
  };
}
