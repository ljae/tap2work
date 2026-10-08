import {storeSetupCatalog} from '../store_setup.mjs';
import test from 'node:test';
import assert from 'node:assert/strict';
import {createCloudHandler} from '../supabase_backend.mjs';
import {emptyOperations} from '../operations.mjs';
const uid='aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
const a='11111111-1111-1111-1111-111111111111', b='22222222-2222-2222-2222-222222222222', c='33333333-3333-3333-3333-333333333333';
const now=new Date('2026-10-06T04:00:00Z');
function fixture({empty=false}={}) {
 const stores=new Map(empty?[]:[[a,{id:a,name:'A',role:'owner'}],[b,{id:b,name:'B',role:'crew'}]]);
 const states=new Map([...stores].map(([id,w])=>{const s=emptyOperations(now,uid);s.store.name=w.name;return [id,s];}));
 const saved=[],creations=[];const requests=new Map();
 const handler=createCloudHandler({url:'https://example.invalid',serviceKey:'server',sectionStorage:true,clock:()=>now,fetcher:async(url,options)=>{
  if(url.endsWith('/auth/v1/user'))return Response.json({id:uid});
  if(url.includes('/tap2work_workspace_requests?')) {const key=new URL(url).searchParams.get('request_id').slice(3);return Response.json(requests.has(key)?[{workspace_id:requests.get(key)}]:[]);}
  const input=JSON.parse(options.body);
  if(url.endsWith('/tap2work_read_workspace')){
   const id=input.p_workspace_id ?? stores.keys().next().value;const w=stores.get(id);
   if(!id)return Response.json({member:null,workspaces:[]});
   if(!w)return Response.json({forbidden:true,workspaces:[...stores.values()]});
   return Response.json({member:{workspace_id:id,role:w.role,display_name:'User'},payload:structuredClone(states.get(id)),window:1,workspaces:[...stores.values()]});
  }
  if(url.endsWith('/tap2work_create_workspace')){
   creations.push(input);
   if(requests.has(input.p_request_id))return Response.json(requests.get(input.p_request_id));
   requests.set(input.p_request_id,c);states.set(c,input.p_state);stores.set(c,{id:c,name:input.p_state.store.name,role:'owner'});return Response.json(c);
  }
  if(url.endsWith('/tap2work_patch_state')){
   const state=states.get(input.p_workspace_id);
   assert.ok(state);if(state.revision!==input.p_expected_revision)return Response.json(false);
   saved.push(input.p_workspace_id);for(const k of input.p_removed)delete state[k];Object.assign(state,input.p_changes);state.revision++;return Response.json(true);
  }
  throw Error('Unexpected RPC');
 }});
 const request=(body,id)=>handler(new Request(`https://example.invalid/operations${id?'?workspace='+id:''}`,{method:body?'POST':'GET',headers:{Authorization:'Bearer token','Content-Type':'application/json'},...(body?{body:JSON.stringify(body)}:{})}));
 return {request,states,saved,creations};
}
test('selected store scopes reads, roles, renames and writes without leaking another store',async()=>{
 const f=fixture();let r=await f.request(null,a);const owner=await r.json();assert.equal(owner.workspaceId,a);assert.equal(owner.workspaces.length,2);
 r=await f.request({workspaceId:a,action:'save_store_profile',revision:owner.revision,section:'basic',values:{name:'A renamed',industryId:'restaurant',serviceModes:['hall'],note:''}});
 assert.equal(r.status,200,await r.clone().text());const renamed=await r.json();assert.equal(renamed.workspaces.find(w=>w.id===a).name,'A renamed');assert.equal(f.states.get(b).store.name,'B');
 const crew=await(await f.request(null,b)).json();assert.equal(crew.actor.role,'crew');assert.equal(crew.payrollSettings,undefined);
 r=await f.request({workspaceId:b,action:'save_order_system',enabled:true,revision:crew.revision});assert.equal(r.status,403);
 r=await f.request({workspaceId:c,action:'save_order_system',enabled:true,revision:owner.revision});assert.equal(r.status,403);assert.equal((await r.json()).payload,undefined);
 r=await f.request({action:'save_order_system',enabled:true,revision:owner.revision});assert.equal(r.status,409);
});
test('additional store uses authenticated owner, independent blank data and idempotent request identity',async()=>{
 const f=fixture();const input={action:'create_workspace',mode:'blank',name:'새 지점',requestId:'44444444-4444-4444-8444-444444444444',revision:0};
 let r=await f.request(input,'a&view=employee');assert.equal(r.status,403);assert.equal(f.creations.length,0);
 r=await f.request({...input,name:' '});assert.equal(r.status,400);assert.equal(f.creations.length,0);
 r=await f.request(input);assert.equal(r.status,200,await r.clone().text());const created=await r.json();assert.equal(created.workspaceId,c);assert.equal(created.store.name,input.name);assert.equal(created.workspaces.length,3);assert.equal(created.items.length,0);assert.equal(f.creations[0].p_user_id,uid);assert.equal(f.states.get(a).store.name,'A');
 r=await f.request(input);assert.equal(r.status,200);assert.equal((await r.json()).workspaceId,c);assert.equal(f.states.size,3);
});

test('new-store setup validates before creating, persists all sections, and replays after catalog changes',async()=>{
 const f=fixture();const cat=storeSetupCatalog();
 const input={action:'create_workspace',mode:'blank',name:'돈까스점',requestId:'55555555-5555-4555-8555-555555555555',revision:0,setup:{businessTypeId:'donkatsu',serviceModes:['hall'],weekdays:[1,2,3,4,5],opening:'09:00',closing:'21:00',partIds:['kitchen'],headcounts:{kitchen:2},pos:'unset',deliveryPlatforms:[],releaseId:cat.releaseId,sourceIds:['chicken/prep'],enableOperations:true}};
 let r=await f.request({...input,setup:{...input.setup,weekdays:[]}});assert.equal(r.status,400);assert.equal((await r.json()).setupRejected,true);assert.equal(f.creations.length,0);assert.equal(f.states.size,2);
 r=await f.request(input);assert.equal(r.status,200,await r.clone().text());const result=await r.json();assert.equal(result.workspaceId,c);assert.equal(result.store.profile.businessTypeId,'donkatsu');assert.equal(result.taskTemplates.length,1);assert.ok(result.tasks.length>0);assert.equal(f.states.get(a).store.name,'A');assert.equal(result.workplace.days[1][0].headcounts.kitchen,2);
 r=await f.request({...input,setup:{...input.setup,releaseId:'stale-catalog'}});assert.equal(r.status,200,await r.clone().text());assert.equal((await r.json()).workspaceId,c);assert.equal(f.creations.length,1);assert.equal(f.states.get(c).taskTemplates.length,1);
});

test('first workspace receives setup choices before membership and commits one configured store',async()=>{
 const f=fixture({empty:true});const first=await(await f.request()).json();assert.equal(first.needsWorkspace,true);assert.ok(first.storeSetupCatalog.businessTypes.some(t=>t.id==='donkatsu'));
 const input={action:'create_workspace',mode:'blank',name:'한식 첫 매장',revision:0,requestId:'66666666-6666-4666-8666-666666666666',setup:{businessTypeId:'korean',serviceModes:['hall'],weekdays:[1,2,3,4,5],opening:'09:00',closing:'21:00',partIds:['kitchen'],headcounts:{kitchen:1},pos:'none',deliveryPlatforms:[],releaseId:first.storeSetupCatalog.releaseId,sourceIds:['korean/prep'],enableOperations:false}};
 const r=await f.request(input);assert.equal(r.status,200,await r.clone().text());const created=await r.json();assert.equal(created.store.profile.businessTypeId,'korean');assert.equal(created.workspaces.length,1);assert.equal(created.taskTemplates.length,1);assert.equal(f.creations.length,1);
});
