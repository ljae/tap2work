import { test } from 'node:test';
import assert from 'node:assert/strict';
import { createCloudHandler } from '../supabase_backend.mjs';
const uid='aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
function fixture(options={}) {
 let calls=[], cache=new Map(), providerCalls=0, allowed=true, membership=true, failure=false, revokeDuringProvider=false, malformed=false;
 const state={store:{},welcome:{revision:1,importantRevision:1,sourceLocale:'ko',title:'우리 매장',body:'동료에게 물어봐요'},taskTemplates:[{id:'manual-a',title:'원문',steps:[{id:'step-a',title:'단계',manual:'매장 안내',tip:'함께 해요'}]}],tasks:[]};
 const handler=createCloudHandler({url:'https://db.test',serviceKey:'test',translationEnabled:true,translationApiKey:'secret-test',...options,fetcher:async(url,init={})=>{
   calls.push({url,init});
   if(url.endsWith('/auth/v1/user'))return Response.json({id:uid});
   if(url.includes('/tap2work_members?'))return Response.json(membership?[{workspace_id:'workspace-a',role:'crew'}]:[]);
   if(url.includes('/tap2work_state?'))return Response.json([{payload:structuredClone(state)}]);
   if(url.includes('/tap2work_content_translations?')){
     if(init.method==='POST'){const row=JSON.parse(init.body);cache.set(row.source_hash+'/'+row.target_locale,row.translated);return new Response(null,{status:204});}
     const query=new URL(url).searchParams;const hit=cache.get(query.get('source_hash').slice(3)+'/'+query.get('target_locale').slice(3));return Response.json(hit?[{translated:hit}]:[]);
   }
   if(url.endsWith('/rpc/tap2work_reserve_translation'))return Response.json(allowed);
   if(url==='https://translation.googleapis.com/language/translate/v2') {providerCalls++;if(revokeDuringProvider)membership=false;if(malformed)return Response.json({data:{translations:[]}});if(failure)return Response.json({error:'private provider details'},{status:503});const input=JSON.parse(init.body);assert.equal(init.headers['X-Goog-Api-Key'],'secret-test');return Response.json({data:{translations:input.q.map(t=>({translatedText:'translated:'+t}))}});}
   throw Error('unexpected route '+url);
 }});
 const request=async(input={workspaceId:'workspace-a',targetLocale:'vi',source:{kind:'welcome'}},headers={})=>handler(new Request('https://db.test/functions/v1/operations?translate=content',{method:'POST',headers:{Authorization:'Bearer token','Content-Type':'application/json',...headers},body:JSON.stringify(input)}));
 return {state,request,calls,providerCalls:()=>providerCalls,setAllowed:v=>allowed=v,setMembership:v=>membership=v,setFailure:v=>failure=v,setRevoke:v=>revokeDuringProvider=v,setMalformed:v=>malformed=v};
}
test('authenticated translation uses stored allowlisted text, persists scoped hash cache and invalidates edits',async()=>{
 const x=fixture();let r=await x.request();assert.equal(r.status,200);assert.equal(r.headers.get('cache-control'),'no-store');let a=await r.json();
 assert.equal(a.status,'translated');assert.equal(a.cached,false);assert.equal(a.translated.body,'translated:동료에게 물어봐요');assert.equal(a.targetLocale,'vi');assert.deepEqual(a.source,{kind:'welcome'});
 const cached=await(await x.request()).json();assert.equal(cached.cached,true);assert.equal(x.providerCalls(),1);
 x.state.welcome.body='변경된 원문';const next=await(await x.request()).json();assert.notEqual(next.sourceHash,a.sourceHash);assert.equal(x.providerCalls(),2);assert.equal(next.original.body,'변경된 원문');
 assert.ok(!x.calls.some(c=>/save_state|patch_state/.test(c.url)));
});
test('translation rejects cross-workspace, arbitrary text/URL, unsupported locale and large request before paid provider',async()=>{
 const x=fixture();
 for(const input of [{workspaceId:'other',targetLocale:'vi',source:{kind:'welcome'}},{workspaceId:'workspace-a',targetLocale:'vi',source:{kind:'welcome',url:'https://internal.test'}},{workspaceId:'workspace-a',targetLocale:'vi',source:{kind:'welcome'},text:'arbitrary'},{workspaceId:'workspace-a',targetLocale:'fr',source:{kind:'welcome'}}]) assert.ok((await x.request(input)).status>=400);
 assert.equal((await x.request({text:'x'.repeat(3000)})).status,413);assert.equal(x.providerCalls(),0);
});
test('missing provider, budget denial and provider failure truthfully return original fallback',async()=>{
 for(const options of [{translationEnabled:false},{translationApiKey:null}]) {const x=fixture(options);const result=await(await x.request()).json();assert.equal(result.status,'unavailable');assert.equal(result.translated,null);assert.equal(x.providerCalls(),0);}
 const x=fixture();x.setAllowed(false);assert.equal((await(await x.request()).json()).status,'rate_limited');assert.equal(x.providerCalls(),0);
 x.setAllowed(true);x.setFailure(true);const result=await(await x.request()).json();assert.equal(result.status,'unavailable');assert.equal(result.original.body,x.state.welcome.body);assert.equal(JSON.stringify(result).includes('private provider'),false);
});
test('manual translation retains step IDs, autodetects undeclared source, maps Simplified Chinese and bypasses same-locale welcome',async()=>{
 const x=fixture();const result=await(await x.request({workspaceId:'workspace-a',targetLocale:'zh-Hans',source:{kind:'manual',id:'manual-a'}})).json();
 assert.equal(result.status,'translated');assert.equal(result.sourceLocale,'auto');assert.equal(result.translated.steps[0].id,'step-a');assert.equal(result.original.steps[0].id,'step-a');
 const provider=x.calls.find(c=>c.url.startsWith('https://translation.googleapis'));const input=JSON.parse(provider.init.body);assert.equal(input.target,'zh-CN');assert.equal(input.source,undefined);assert.equal(input.format,'text');
 assert.equal((await(await x.request({workspaceId:'workspace-a',targetLocale:'ko',source:{kind:'welcome'}})).json()).status,'original');assert.equal(x.providerCalls(),1);
});

test('provider failure modes, source bounds and revocation never persist a false successful translation',async()=>{
 const oversized=fixture();oversized.state.welcome.body='x'.repeat(8001);
 assert.equal((await(await oversized.request()).json()).status,'unavailable');assert.equal(oversized.providerCalls(),0);
 const malformed=fixture();malformed.setMalformed(true);assert.equal((await(await malformed.request()).json()).status,'unavailable');assert.equal(malformed.calls.some(c=>c.url.includes('/tap2work_content_translations?')&&c.init.method==='POST'),false);
 const revoked=fixture();revoked.setRevoke(true);assert.equal((await revoked.request()).status,403);assert.equal(revoked.calls.some(c=>c.url.includes('/tap2work_content_translations?')&&c.init.method==='POST'),false);
 const missing=fixture();assert.equal((await missing.request({workspaceId:'workspace-a',targetLocale:'en',source:{kind:'manual',id:'missing'}})).status,404);assert.equal(missing.providerCalls(),0);
});
