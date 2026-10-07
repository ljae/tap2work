import {validateRelease} from './catalog_repository.mjs';
import {StoreError} from './store.mjs';

// Provider identity is independent from any store membership or demo role.
export function createCatalogAdminHandler({url,serviceKey,fetcher=fetch,origins=['https://tap2.work']}){
 if(!url||!serviceKey)throw Error('Catalog server configuration missing');
 const serverHeaders={apikey:serviceKey,'Content-Type':'application/json',...(serviceKey.startsWith('eyJ')?{Authorization:`Bearer ${serviceKey}`}:{})};
 async function rest(path,body){
  const response=await fetcher(`${url}/rest/v1/${path}`,{headers:serverHeaders,...(body?{method:'POST',body:JSON.stringify(body)}:{})});
  if(!response.ok){
   let data={};try{data=await response.json();}catch{}
   const status=data.code==='42501'?403:data.code==='40001'?409:data.code==='22023'?400:503;
   throw new StoreError(status===409?'초안이나 발행본이 바뀌었어요. 다시 확인해 주세요.':status===403?'공용 콘텐츠 권한이 없어요.':'공용 콘텐츠 요청을 처리하지 못했어요.',status);
  }
  return response.status===204?null:response.json();
 }
 return async request=>{
  const origin=request.headers.get('origin');
  const headers={'Content-Type':'application/json; charset=utf-8','Cache-Control':'no-store',...(origin&&origins.includes(origin)?{'Access-Control-Allow-Origin':origin,'Access-Control-Allow-Headers':'authorization,apikey,content-type','Access-Control-Allow-Methods':'POST,OPTIONS',Vary:'Origin'}:{})};
  const reply=(status,data)=>new Response(JSON.stringify(data),{status,headers});
  try{
   if(origin&&!origins.includes(origin))throw new StoreError('허용된 주소에서 연결해 주세요.',403);
   if(request.method==='OPTIONS')return new Response(null,{status:204,headers});
   if(request.method!=='POST')throw new StoreError('POST 요청이 필요해요.',405);
   const authorization=request.headers.get('authorization');
   if(!authorization?.startsWith('Bearer '))throw new StoreError('로그인 후 이용해 주세요.',401);
   const auth=await fetcher(`${url}/auth/v1/user`,{headers:{apikey:serviceKey,Authorization:authorization}});
   if(!auth.ok)throw new StoreError('로그인이 만료됐어요.',401);
   const user=await auth.json();
   if(!/^[\da-f-]{36}$/i.test(user.id??''))throw new StoreError('사용자를 확인하지 못했어요.',401);
   if(!request.headers.get('content-type')?.startsWith('application/json'))throw new StoreError('JSON 요청이 필요해요.',415);
   const raw=await request.text();
   if(new TextEncoder().encode(raw).length>2*1024*1024)throw new StoreError('요청 크기가 너무 커요.',413);
   let input;try{input=JSON.parse(raw);}catch{throw new StoreError('요청 형식을 확인해 주세요.',400);}
   if(!input||typeof input!=='object'||Array.isArray(input))throw new StoreError('요청 형식을 확인해 주세요.',400);
   const uuid=v=>typeof v==='string'&&/^[\da-f]{8}-[\da-f]{4}-[\da-f]{4}-[\da-f]{4}-[\da-f]{12}$/i.test(v);
   const number=v=>Number.isSafeInteger(v)&&v>=0;
   const hash=v=>typeof v==='string'&&/^[0-9a-f]{64}$/.test(v);
   if(['read_draft','review','publish'].includes(input.action)&&!uuid(input.draftId))throw new StoreError('초안 ID를 확인해 주세요.',400);
   if(input.action==='save_draft'&&input.draftId!=null&&!uuid(input.draftId))throw new StoreError('초안 ID를 확인해 주세요.',400);
   if(['review','publish'].includes(input.action)&&(!number(input.revision)||!hash(input.payloadHash)))throw new StoreError('초안 버전과 해시를 확인해 주세요.',400);
   if(['publish','rollback'].includes(input.action)&&(!number(input.channelRevision)||!uuid(input.requestId)))throw new StoreError('발행 버전과 요청 ID를 확인해 주세요.',400);
   if(input.action==='rollback'&&!hash(input.releaseId))throw new StoreError('발행본 ID를 확인해 주세요.',400);
   const actor={p_actor_id:user.id};
   const channel=input.channel??'stable';
   if(!/^[a-z][a-z0-9-]{0,49}$/.test(channel))throw new StoreError('발행 채널을 확인해 주세요.',400);
   let result;
   switch(input.action){
    case 'save_draft': {
     const release=validateRelease(input.release,{assignId:true});
     result=await rest('rpc/tap2work_catalog_draft_save',{...actor,p_draft_id:input.draftId??null,p_expected_revision:input.revision??0,p_release:release,p_payload_hash:release.releaseId,p_summary:input.summary});break;
    }
    case 'read_draft':result=await rest('rpc/tap2work_catalog_draft_read',{...actor,p_draft_id:input.draftId});break;
    case 'review':result=await rest('rpc/tap2work_catalog_review',{...actor,p_draft_id:input.draftId,p_expected_revision:input.revision,p_payload_hash:input.payloadHash,p_outcome:input.outcome,p_reason:input.reason});break;
    case 'publish':result=await rest('rpc/tap2work_catalog_publish',{...actor,p_draft_id:input.draftId,p_expected_draft_revision:input.revision,p_payload_hash:input.payloadHash,p_expected_channel_revision:input.channelRevision,p_request_id:input.requestId,p_reason:input.reason,p_channel:channel});break;
    case 'rollback':result=await rest('rpc/tap2work_catalog_rollback',{...actor,p_release_id:input.releaseId,p_expected_channel_revision:input.channelRevision,p_request_id:input.requestId,p_reason:input.reason,p_channel:channel});break;
    case 'read_published': result=await rest('rpc/tap2work_catalog_read',{p_channel:channel});break;
    default:throw new StoreError('지원하지 않는 공용 콘텐츠 작업이에요.',400);
   }
   return reply(200,result);
  }catch(error){return reply(error instanceof StoreError?error.status:500,{error:error instanceof StoreError?error.message:'공용 콘텐츠 요청을 처리하지 못했어요.'});}
 };
}
