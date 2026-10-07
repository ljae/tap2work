import test from 'node:test';
import assert from 'node:assert/strict';
import {createCatalogAdminHandler} from '../catalog_admin.mjs';
import {manualCatalog} from '../manual_market.mjs';
const id='aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
function fixture({allowed=true}={}){
 const calls=[];
 const handler=createCatalogAdminHandler({url:'https://test.supabase.co',serviceKey:'secret',fetcher:async(url,o)=>{
  if(url.endsWith('/auth/v1/user'))return Response.json({id});
  calls.push({url,input:JSON.parse(o.body)});
  if(!allowed)return Response.json({code:'42501'},{status:403});
  return Response.json({ok:true});
 }});
 return {calls,request:(input,token='token')=>handler(new Request('https://test.invalid/catalog-admin',{method:'POST',headers:{Authorization:`Bearer ${token}`,'Content-Type':'application/json'},body:JSON.stringify(input)}))};
}
test('provider draft normalizes valid content and ignores forged actor identity',async()=>{
 const f=fixture();const r=await f.request({action:'save_draft',actorId:'forged',release:manualCatalog,summary:'updated',revision:0});assert.equal(r.status,200);assert.equal(f.calls[0].input.p_actor_id,id);assert.equal(f.calls[0].input.p_release.releaseId,f.calls[0].input.p_payload_hash);
});
test('store owner without provider grant cannot publish or create drafts',async()=>{
 const f=fixture({allowed:false});assert.equal((await f.request({action:'save_draft',release:manualCatalog,summary:'x'})).status,403);
 assert.equal((await f.request({action:'publish',draftId:id,payloadHash:'a'.repeat(64),revision:1,channelRevision:1,requestId:id})).status,403);
});
test('malformed release and Task policy cannot reach provider DB writes',async()=>{
 const f=fixture();const r=structuredClone(manualCatalog);r.entries[0].steps[0].settings={enabled:true};assert.equal((await f.request({action:'save_draft',release:r,summary:'bad'})).status,400);assert.equal(f.calls.length,0);
});
