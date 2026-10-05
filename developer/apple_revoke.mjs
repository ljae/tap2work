import {StoreError} from './store.mjs';

const encode = value => btoa(typeof value === 'string' ? value : String.fromCharCode(...value))
  .replaceAll('+','-').replaceAll('/','_').replaceAll('=','');

export async function appleClientSecret(config, clientId, now = new Date()) {
  const seconds = Math.floor(now.getTime()/1000);
  const head = encode(JSON.stringify({alg:'ES256',kid:config.keyId}));
  const claims = encode(JSON.stringify({iss:config.teamId,iat:seconds,exp:seconds+300,aud:'https://appleid.apple.com',sub:clientId}));
  const pem = config.privateKey.replaceAll('\\n','\n').replace(/-----[^-]+-----|\s/g,'');
  const key = await crypto.subtle.importKey('pkcs8',Uint8Array.from(atob(pem),c=>c.charCodeAt(0)),{name:'ECDSA',namedCurve:'P-256'},false,['sign']);
  const signature = await crypto.subtle.sign({name:'ECDSA',hash:'SHA-256'},key,new TextEncoder().encode(`${head}.${claims}`));
  return `${head}.${claims}.${encode(new Uint8Array(signature))}`;
}

export async function revokeApple(user, input, {config, fetcher = fetch, clock = () => new Date(), secret = appleClientSecret}) {
  const identity = user.identities?.find(row => row.provider === 'apple');
  if (!identity) return;
  const clientId = input.appleClient === 'native' ? config?.bundleId : input.appleClient === 'web' ? config?.serviceId : null;
  if (!clientId || !config?.teamId || !config?.keyId || !config?.privateKey) {
    throw new StoreError('Apple 계정 삭제 연결을 준비 중이에요. 잠시 후 다시 시도하거나 개인정보 문의로 요청해 주세요.',503);
  }
  const code = input.appleCode, refresh = input.appleRefreshToken;
  if ((!code && !refresh) || (code && refresh) || [code,refresh].some(v=>v && (typeof v !== 'string'||v.length>8192))) {
    throw new StoreError('Apple로 다시 본인 확인한 뒤 계정 삭제를 진행해 주세요.',400);
  }
  const clientSecret = await secret(config, clientId, clock());
  const form = new URLSearchParams({client_id:clientId,client_secret:clientSecret,
    grant_type:code?'authorization_code':'refresh_token', ...(code?{code}:{refresh_token:refresh})});
  const response = await fetcher('https://appleid.apple.com/auth/token', {method:'POST',headers:{'Content-Type':'application/x-www-form-urlencoded'},body:form.toString(),signal:AbortSignal.timeout(15000)});
  if (!response.ok) throw new StoreError('Apple 본인 확인이 만료됐어요. 다시 확인해 주세요.',409);
  const tokens = await response.json();
  // This ID token comes directly from Apple's TLS token endpoint, not the caller.
  let claims;
  try { claims=JSON.parse(atob(tokens.id_token.split('.')[1].replaceAll('-','+').replaceAll('_','/'))); } catch { throw new StoreError('Apple 계정을 확인하지 못했어요.',502); }
  const sub = identity.identity_data?.sub ?? identity.id;
  if (claims.sub !== sub || claims.aud !== clientId || claims.iss !== 'https://appleid.apple.com' || !Number.isFinite(claims.exp) || claims.exp*1000 <= clock().getTime()) {
    throw new StoreError('현재 로그인한 계정과 같은 Apple 계정을 선택해 주세요.',403);
  }
  const token = tokens.refresh_token ?? refresh ?? tokens.access_token;
  if (!token) throw new StoreError('Apple 연결 해제 정보를 받지 못했어요.',502);
  const revoked = await fetcher('https://appleid.apple.com/auth/revoke', {method:'POST',headers:{'Content-Type':'application/x-www-form-urlencoded'},
    body:new URLSearchParams({client_id:clientId,client_secret:clientSecret,token,token_type_hint:tokens.refresh_token||refresh?'refresh_token':'access_token'}).toString(),signal:AbortSignal.timeout(15000)});
  if (!revoked.ok) throw new StoreError('Apple 연결을 해제하지 못했어요. 다시 시도해 주세요.',502);
}
