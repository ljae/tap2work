import { test } from 'node:test';
import assert from 'node:assert/strict';
import { createCloudHandler } from '../supabase_backend.mjs';
import { seedOperations } from '../operations.mjs';
const uid='aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
const now=new Date('2026-09-24T05:00:00Z');
function setup(role='owner') {
  let state=seedOperations(now), conflict=false;
  const calls=[];
  const handler=createCloudHandler({url:'https://example.supabase.co',serviceKey:'sb_secret_test',clock:()=>now,fetcher:async (url,init={})=>{
    calls.push({url,...init});
    if(url.endsWith('/auth/v1/user')) return Response.json({id:uid});
    if(url.includes('/tap2work_members?')) return Response.json([{workspace_id:'workspace-a',role,display_name:'테스트'}]);
    if(url.includes('/tap2work_state?')) {assert.ok(url.includes('workspace_id=eq.workspace-a'));return Response.json([{payload:structuredClone(state)}]);}
    if(url.endsWith('/rpc/tap2work_save_state')) {const input=JSON.parse(init.body);assert.equal(input.p_workspace_id,'workspace-a');if(conflict||input.p_expected_revision!==state.revision)return Response.json(false);state=input.p_payload;return Response.json(true);}
    throw Error('Unexpected request');
  }});
  const request=(body,headers={})=>handler(new Request('https://example.supabase.co/functions/v1/operations',{method:body?'POST':'GET',headers:{Authorization:'Bearer user-session','Content-Type':'application/json',...headers},...(body?{body:JSON.stringify(body)}:{})}));
  return {request,handler,calls,setConflict:()=>{conflict=true;}};
}
test('cloud rejects missing authentication and foreign origins before fetching data',async()=>{
 const {handler,calls}=setup();
 assert.equal((await handler(new Request('https://example.test'))).status,401);
 assert.equal((await handler(new Request('https://example.test',{headers:{Origin:'https://evil.test'}}))).status,403);
 assert.equal(calls.length,0);
});
test('verified crew membership ignores forged owner headers and cannot edit layout',async()=>{
 const {request}=setup('crew');
 let response=await request(null,{'x-demo-actor':'owner'}), state=await response.json();
 assert.equal(response.status,200);assert.equal(state.actor.id,uid);assert.equal(state.actor.role,'crew');assert.equal(state.privateSummary,undefined);assert.equal(state.actors.length,1);
 response=await request({action:'save_layout',revision:state.revision,layout:state.layout,zones:state.zones,actor:'owner'});
 assert.equal(response.status,403);
});
test('cloud persists completion and reports compare-and-swap conflicts',async()=>{
 const {request,setConflict}=setup();
 let state=await (await request()).json();const task=state.tasks.find(t=>t.orderId);
 const response=await request({action:'move_tap',revision:state.revision,taskId:task.id,folderId:task.folderId,status:'done'});
 assert.equal(response.status,200);state=await response.json();
 assert.ok(state.tasks.find(t=>t.id===task.id).steps.every(s=>s.completedAt));
 assert.ok(!state.dashboard.queue.some(t=>t.id===task.orderId));
 setConflict();
 assert.equal((await request({action:'move_tap',revision:state.revision,taskId:task.id,folderId:task.folderId,status:'todo'})).status,409);
});
test('new account chooses blank workspace explicitly; GET alone creates nothing',async()=>{
 let state=null, member=null, bootstrap=0;const unexpected=[];
 const handler=createCloudHandler({url:'https://example.supabase.co',serviceKey:'sb_secret_test',clock:()=>now,fetcher:async(url,init={})=>{
  if(url.endsWith('/auth/v1/user'))return Response.json({id:uid,user_metadata:{display_name:'실제 사장'}});
  if(url.includes('/tap2work_members?'))return Response.json(member?[member]:[]);
  if(url.endsWith('/rpc/tap2work_bootstrap')){bootstrap++;const input=JSON.parse(init.body);state=input.p_state;member={workspace_id:'workspace-a',role:'owner',display_name:'실제 사장'};return Response.json('workspace-a');}
  if(url.includes('/tap2work_state?'))return Response.json([{payload:structuredClone(state)}]);
  if(url.endsWith('/rpc/tap2work_save_state')){const input=JSON.parse(init.body);if(input.p_expected_revision!==state.revision)return Response.json(false);state=input.p_payload;return Response.json(true);}
  unexpected.push(url);throw Error('Unexpected request');
 }});
 const headers={Authorization:'Bearer session','Content-Type':'application/json'};
 let response=await handler(new Request('https://example.supabase.co/functions/v1/operations',{headers}));
 assert.equal((await response.json()).needsWorkspace,true);assert.equal(bootstrap,0);
 response=await handler(new Request('https://example.supabase.co/functions/v1/operations',{method:'POST',headers,body:JSON.stringify({action:'create_workspace',mode:'blank',revision:0})}));
 assert.equal(response.status,200,`${await response.clone().text()} ${unexpected.join(',')}`);const view=await response.json();assert.equal(bootstrap,1);
 assert.equal(view.items.length,0);assert.equal(view.catalogMenus.length,0);assert.equal(view.tappers.length,1);
 assert.equal(view.demo,false);assert.equal(view.authenticated,true);
});
test('settings survive independent cloud reads and reject stale writes',async()=>{
 const {request}=setup();
 let state=await (await request()).json();
 const settings={cycle:'weekly',monthStartDay:25,weekStartDay:3,roundingMinutes:5,businessSize:'fivePlus',includeWeeklyRest:false};
 const save=async(body)=>{const response=await request({...body,revision:state.revision});assert.equal(response.status,200);state=await (await request()).json();};
 await save({action:'save_payroll_settings',settings});
 assert.deepEqual(state.payrollSettings,{...settings,configured:true});
 await save({action:'save_order_system',enabled:true});
 assert.equal(state.orderBoardEnabled,true);
 await save({action:'save_workplace_day',weekday:1,bands:[{name:'영업',start:'09:00',end:'21:00'}]});
 assert.equal(state.workplace.days[1][0].start,'09:00');
 assert.equal(state.payrollSettings.roundingMinutes,5);
 assert.equal((await request({action:'save_order_system',enabled:false,revision:state.revision-1})).status,409);
 assert.equal((await (await request()).json()).orderBoardEnabled,true);
});
test('shared owner can enter fixed employee projection, employee mode denies owner writes and real crew cannot escalate',async()=>{
 const {request,handler}=setup();
 let state=await (await request()).json();
 let r=await request({action:'setup_shared_employee',revision:state.revision});assert.equal(r.status,200);state=await r.json();
 const crew=state.tappers.find(t=>t.id===state.sharedEmployeeId);assert.equal(crew.contractType,'short_term');
 const endpoint='https://example.supabase.co/functions/v1/operations?view=employee';
 const headers={Authorization:'Bearer session','Content-Type':'application/json'};
 r=await handler(new Request(endpoint,{headers}));assert.equal(r.status,200);const employee=await r.json();
 assert.equal(employee.actor.role,'crew');assert.equal(employee.actor.id,crew.actorId);assert.equal(employee.canEditSchedule,false);assert.equal(employee.labor,undefined);
 r=await handler(new Request(endpoint,{method:'POST',headers,body:JSON.stringify({action:'save_order_system',enabled:true,revision:employee.revision})}));assert.equal(r.status,403);
 const actual=setup('crew');r=await actual.handler(new Request(endpoint,{headers}));assert.equal(r.status,403);
});
