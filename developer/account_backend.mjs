import {StoreError} from './store.mjs';
import {eraseMemberData} from './account_erasure.mjs';
import {revokeApple} from './apple_revoke.mjs';

async function fingerprint(scope) {
  return Array.from(new Uint8Array(await crypto.subtle.digest('SHA-256',new TextEncoder().encode(JSON.stringify(scope))))).map(x=>x.toString(16).padStart(2,'0')).join('');
}

export function createAccountHandler({url, serviceKey, apple, fetcher=fetch, appleRevoker=revokeApple, origins=['https://tap2.work','https://www.tap2.work']}) {
  if (!url || !serviceKey) throw new Error('Account server configuration is missing');
  return async request => {
    const origin=request.headers.get('origin');
    const headers={'Content-Type':'application/json; charset=utf-8','Cache-Control':'no-store',Vary:'Origin'};
    if(origins.includes(origin)) Object.assign(headers,{'Access-Control-Allow-Origin':origin,'Access-Control-Allow-Methods':'POST, OPTIONS','Access-Control-Allow-Headers':'authorization, apikey, content-type, x-client-info'});
    const reply=(status,data)=>new Response(JSON.stringify(data),{status,headers});
    if(origin&&!origins.includes(origin))return reply(403,{error:'허용된 앱 주소에서 연결해 주세요.'});
    if(request.method==='OPTIONS')return new Response(null,{status:204,headers});
    try {
      if(request.method!=='POST')throw new StoreError('지원하지 않는 요청이에요.',405);
      const authorization=request.headers.get('authorization');
      if(!authorization?.startsWith('Bearer '))throw new StoreError('로그인 후 이용해 주세요.',401);
      const verified=await fetcher(`${url}/auth/v1/user`,{headers:{apikey:serviceKey,Authorization:authorization},signal:AbortSignal.timeout(10000)});
      if(!verified.ok)throw new StoreError('다시 로그인해 주세요.',401);
      const user=await verified.json();
      if(!/^[\da-f-]{36}$/i.test(user.id??''))throw new StoreError('계정을 확인하지 못했어요.',401);
      if(!request.headers.get('content-type')?.startsWith('application/json'))throw new StoreError('JSON 요청이 필요해요.',415);
      const raw=await request.text();
      if(new TextEncoder().encode(raw).length>20000)throw new StoreError('요청 크기가 너무 커요.',413);
      let input;try{input=JSON.parse(raw);}catch{throw new StoreError('요청 형식을 확인해 주세요.',400);}
      if(!input||Array.isArray(input)||!['preview_delete','delete_account'].includes(input.action))throw new StoreError('요청을 확인해 주세요.',400);
      const allowed=['action','confirmationToken','confirmWorkspaceDeletion','appleCode','appleRefreshToken','appleClient'];
      if(Object.keys(input).some(k=>!allowed.includes(k)))throw new StoreError('요청에 허용되지 않은 값이 있어요.',400);
      const serverHeaders={apikey:serviceKey,...(serviceKey.startsWith('eyJ')?{Authorization:`Bearer ${serviceKey}`} : {}),'Content-Type':'application/json'};
      async function rpc(name, body) {
        const result=await fetcher(`${url}/rest/v1/rpc/${name}`,{method:'POST',headers:serverHeaders,body:JSON.stringify(body),signal:AbortSignal.timeout(15000)});
        if(!result.ok)throw new StoreError('계정 삭제 정보를 처리하지 못했어요. 다시 시도해 주세요.',503);
        return result.json();
      }
      const context=await rpc('tap2work_account_context',{p_user_id:user.id});
      if(!context?.scope)throw new StoreError('계정 정보를 확인하지 못했어요.',409);
      const scope=context.scope, token=await fingerprint(scope);
      const scopes=scope.workspaces ?? (scope.workspaceId ? [scope] : []);
      const destroys=s=>s.role==='owner'&&s.ownerCount===1;
      const destroysWorkspace=scopes.some(destroys);
      const workspaces=scopes.map(s=>({name:s.workspaceName,destroysWorkspace:destroys(s),memberCount:s.memberCount}));
      if(input.action==='preview_delete')return reply(200,{confirmationToken:token,destroysWorkspace,workspaceName:scopes.filter(destroys).map(s=>s.workspaceName).join(' · ') || scope.workspaceName,memberCount:scopes.filter(destroys).reduce((n,s)=>n+s.memberCount,0) || scope.memberCount,workspaces,hasApple:user.identities?.some(i=>i.provider==='apple')===true});
      if(input.confirmationToken!==token)throw new StoreError('매장 정보가 변경됐어요. 삭제 범위를 다시 확인해 주세요.',409);
      if(destroysWorkspace&&input.confirmWorkspaceDeletion!==true)throw new StoreError('매장과 소속 크루의 접근 삭제를 확인해 주세요.',400);
      await appleRevoker(user,input,{config:apple,fetcher});
      const sanitized=scope.workspaces
        ? Object.fromEntries(scopes.filter(s=>!destroys(s)).map(s=>[s.workspaceId,eraseMemberData(context.payloads[s.workspaceId],{...user,displayName:s.displayName})]))
        : scope.workspaceId&&!destroysWorkspace?eraseMemberData(context.payload,{...user,displayName:scope.displayName}):null;
      const result=await rpc('tap2work_erase_account',{p_user_id:user.id,p_expected_scope:scope,p_sanitized_payload:sanitized,p_delete_workspace:destroysWorkspace});
      if(result?.conflict)throw new StoreError('동료가 먼저 수정했어요. 삭제 범위를 다시 확인해 주세요.',409);
      if(result?.deleted!==true)throw new StoreError('계정 삭제를 완료하지 못했어요.',503);
      return reply(200,{deleted:true});
    } catch(error) {
      return reply(error instanceof StoreError?error.status:500,{error:error instanceof StoreError?error.message:'계정 삭제를 처리하지 못했어요. 다시 시도해 주세요.'});
    }
  };
}
