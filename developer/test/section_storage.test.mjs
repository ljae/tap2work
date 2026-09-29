import test from 'node:test';
import assert from 'node:assert/strict';
import {createCloudHandler} from '../supabase_backend.mjs';
import {seedOperations} from '../operations.mjs';
import {sectionPatch} from '../section_storage.mjs';
const uid='aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
const now=new Date('2026-09-29T04:00:00Z');
function fixture(role='owner') {
  let state=seedOperations(now), conflict=false;
  const patches=[],calls=[];
  const handler=createCloudHandler({url:'https://example.supabase.co',serviceKey:'test',sectionStorage:true,clock:()=>now,
    fetcher:async(url,options={})=>{
      calls.push(url);
      if(url.endsWith('/auth/v1/user'))return Response.json({id:uid});
      const input=JSON.parse(options.body);
      if(url.endsWith('/rpc/tap2work_read_workspace')){
        assert.equal(input.p_user_id,uid);
        const window=Math.floor(now.getTime()/60000);
        if(input.p_revision===state.revision&&input.p_window===window&&input.p_role===role&&input.p_workspace_id==='workspace-a')return Response.json({unchanged:true,revision:state.revision,window});
        return Response.json({member:{workspace_id:'workspace-a',role,display_name:'Test'},payload:structuredClone(state),window});
      }
      if(url.endsWith('/rpc/tap2work_patch_state')){
        if(conflict||input.p_expected_revision!==state.revision)return Response.json(false);
        patches.push(input);
        for(const key of input.p_removed)delete state[key];
        Object.assign(state,input.p_changes);state.revision++;
        return Response.json(true);
      }
      throw Error('Unexpected request');
    }});
  const request=(body,query='')=>handler(new Request('https://example.test/operations'+query,{method:body?'POST':'GET',headers:{Authorization:'Bearer test','Content-Type':'application/json'},...(body?{body:JSON.stringify(body)}:{})}));
  return {request,patches,calls,conflict:()=>{conflict=true;}};
}
test('section diff excludes unchanged settings and preserves explicit null/removal',()=>{
  assert.deepEqual(sectionPatch({revision:1,a:{x:1},b:null,c:1},{revision:2,a:{x:1},b:2,d:null}),{changes:{b:2,d:null},removed:['c']});
});
test('every settings domain survives section persistence and independent cloud reads',async()=>{
  const x=fixture();let view=await(await x.request()).json();
  async function save(action,values,assertSaved){
    const response=await x.request({action,revision:view.revision,...values});
    assert.equal(response.status,200,await response.clone().text());
    view=await(await x.request()).json();assertSaved?.(view);
  }
  await save('save_store_profile',{section:'basic',values:{name:'저장 검증 매장',industryId:'restaurant',serviceModes:['hall'],note:'검증'}},v=>assert.equal(v.store.name,'저장 검증 매장'));
  for(const [section,values] of [
    ['pos',{configured:true,enabled:true,devices:[{id:'pos-test',providerId:'okpos',model:'설정',count:1,functions:['orders']}]}],
    ['delivery',{configured:true,enabled:true,platforms:[{id:'delivery-test',providerId:'baemin',acceptanceMode:'direct',handoffMode:'rider',printTicket:true}]}],
    ['hours',{weekdays:[1,2,3],opening:'09:00',closing:'21:00',endsNextDay:false}],
    ['staffing',{declaredCount:4,includesOwner:true,roleTargets:[]}],
  ])await save('save_store_profile',{section,values},v=>assert.ok(v.store.profile[section]));
  await save('save_workplace_parts',{parts:view.workplace.parts.map((p,i)=>({...p,name:i?'홀 '+i:'주방 설정'}))},v=>assert.equal(v.workplace.parts[0].name,'주방 설정'));
  await save('save_workplace_day',{weekday:1,bands:[{name:'운영',start:'10:00',end:'20:00'}]},v=>assert.equal(v.workplace.days[1][0].start,'10:00'));
  await save('save_workplace_permissions',{role:'manager',permissions:{tasks:false}},v=>assert.equal(v.workplace.restrictions.manager.tasks,false));
  await save('save_staff_profile',{tapperId:view.tappers[0].id,partIds:[],bands:['오픈']},v=>assert.deepEqual(v.tappers[0].workProfile.bands,['오픈']));
  await save('save_order_system',{enabled:true},v=>assert.equal(v.orderBoardEnabled,true));
  const beforeCount=x.patches.length;
  await save('save_payroll_settings',{settings:{cycle:'weekly',monthStartDay:1,weekStartDay:2,roundingMinutes:5,businessSize:'under5',includeWeeklyRest:true}},v=>assert.equal(v.payrollSettings.weekStartDay,2));
  const pay=x.patches.slice(beforeCount).at(-1);
  assert.ok(!Object.hasOwn(pay.p_changes,'tasks')&&!Object.hasOwn(pay.p_changes,'attendance'));
  const t=view.taskTemplates.find(t=>!t.archivedAt&&!t.menuManualId);
  await save('save_tap_settings',{templateId:t.id,settings:{type:'general',enabled:true,recurrence:{mode:'daily',weekdays:[]},allowBulkComplete:true,enforceSequence:false},steps:t.steps.map(s=>({id:s.id,settings:{completionKind:'check',estimatedMinutes:5}}))},v=>assert.equal(v.taskTemplates.find(row=>row.id===t.id).steps[0].settings.estimatedMinutes,5));
  await save('save_checklists',{folders:view.checklistFolders,templates:view.taskTemplates});
  const task=view.tasks.find(t=>t.kind==='routine'&&!t.completedAt&&t.steps?.length);
  await save('save_task_step',{taskId:task.id,stepId:task.steps[0].id,title:'DB 저장 Task',manual:'저장된 방법'},v=>assert.equal(v.tasks.find(t=>t.id===task.id).steps[0].title,'DB 저장 Task'));
  await save('save_layout',{layout:view.layout,zones:view.zones},v=>assert.ok(v.layout));
  await save('save_inventory_item',{name:'테스트 재료',unit:'개',supplier:'예시',zone:'',emoji:'🥬',minimum:2,orderQuantity:5,price:3000,reviewDays:4},v=>assert.ok(v.items.some(i=>i.name==='테스트 재료')));
  await save('save_menu',{name:'테스트 메뉴',category:'식사',price:9000},v=>assert.ok(v.catalogMenus.some(i=>i.name==='테스트 메뉴')));
  await save('save_hiring_draft',{roleId:'cook',headcount:2,weekdays:[1,3],responsibilities:'준비'},v=>assert.ok(v.hiringDrafts.length));
  x.conflict();assert.equal((await x.request({action:'save_order_system',revision:view.revision,enabled:false})).status,409);
});
test('conditional cloud reads validate identity each time and return no payload',async()=>{
  const x=fixture();const view=await(await x.request()).json();x.calls.length=0;
  const response=await x.request(null,`?revision=${view.revision}&window=${view.syncWindow}&role=owner&workspace=workspace-a`);
  const body=await response.json();assert.equal(body.unchanged,true);assert.equal(body.payload,undefined);
  assert.equal(x.calls.length,2);assert.ok(x.calls[0].endsWith('/auth/v1/user'));
});
test('section storage retains server role projection and write permissions',async()=>{
  const x=fixture('crew');const view=await(await x.request()).json();
  assert.equal(view.payrollSettings,undefined);assert.equal(view.taskTemplates,undefined);
  const response=await x.request({action:'save_order_system',enabled:true,revision:view.revision});assert.equal(response.status,403);
});
test('section employee view cannot reuse owner cache or write owner settings; preferences retain Korean fallback',async()=>{
 const x=fixture();let view=await(await x.request()).json();
 let response=await x.request({action:'setup_shared_employee',revision:view.revision});assert.equal(response.status,200);view=await response.json();
 const query=`?view=employee&revision=${view.revision}&window=${view.syncWindow}&role=owner&workspace=workspace-a`;
 response=await x.request(null,query);assert.equal(response.status,200);const employee=await response.json();
 assert.equal(employee.unchanged,undefined);assert.equal(employee.actor.role,'crew');assert.equal(employee.canEditTasks,false);assert.equal(employee.canEditSchedule,false);assert.equal(employee.languageContext.effectiveLocale,'ko');assert.equal(employee.payrollSettings,undefined);
 response=await x.request({action:'save_order_system',revision:employee.revision,enabled:true},query);assert.equal(response.status,403);
 const owner=await(await x.request()).json();assert.equal(owner.actor.role,'owner');assert.equal(owner.sharedEmployeeId,view.sharedEmployeeId);
});
