// Synthetic in-memory trusted identities exercise server contracts. These are
// not real accounts, OAuth logins, supplier orders, or payroll verification.
import {test} from 'node:test';
import assert from 'node:assert/strict';
import {OperationsStore,seedOperations} from '../operations.mjs';
import {ensureStaff} from '../staff.mjs';
import {ensurePartModel} from '../parts.mjs';
import {businessDate,actualDate} from '../business_day.mjs';
import {assertIssuePhotoPermission,issuePhotoReceipt,verifyIssuePhotoReceipt} from '../work_issue_media.mjs';

function fixture(at='2026-09-28T03:00:00Z') {
  let now=new Date(at), state=seedOperations(now);
  ensureStaff(state,now);
  ensurePartModel(state);
  const roles=['owner','manager','cook','crew'];
  for(const person of state.tappers) if(roles.includes(person.actorId)) person.actorId=`audit-${person.actorId}`;
  const stores=Object.fromEntries(roles.map(role=>[role,new OperationsStore(null,()=>now,{
    actor:{id:`audit-${role}`,name:`가상 ${role}`,role,label:role},
    persistence:{read:async()=>structuredClone(state),save:async(next)=>{state=structuredClone(next);}},
  })]));
  return {
    stores,raw:()=>structuredClone(state),edit:fn=>fn(state),setTime:value=>{now=new Date(value);},now:()=>now,
    read:role=>stores[role].snapshot('untrusted-supplied-identity'),
    act:async(role,action,fields={})=>stores[role].mutate('untrusted-supplied-identity',{
      action,revision:(await stores[role].snapshot()).revision,...fields,
    }),
  };
}

test('business closing break does not subtract planned/actual labor or modify pay eligibility evidence',async()=>{
  const f=fixture(),before=await f.read('owner');
  const evidence=(({attendance,staffShifts,laborReviews,payments})=>({attendance,staffShifts,laborReviews,payments}))(f.raw());
  const days=Object.fromEntries(Array.from({length:7},(_,i)=>[i+1,i===1?[]:[{id:'audit-day',name:'전체',start:'10:00',end:'22:00',headcounts:{kitchen:2,hall:1,management:0}}]]));
  const saved=await f.act('owner','save_workplace_hours',{days,breaks:{1:{start:'15:00',end:'17:00'}},businessDayStart:'10:00'});
  assert.deepEqual(saved.labor,before.labor,'business pause is not an attendance break or payroll deduction');
  const after=f.raw();
  for(const key of Object.keys(evidence)) assert.deepEqual(after[key],evidence[key],key);
  assert.equal(saved.rosterTemplates.filter(s=>s.weekday===1).length,3);
  assert.ok(saved.rosterTemplates.filter(s=>s.weekday===1).every(s=>s.start==='10:00'&&s.end==='22:00'));
  assert.equal(saved.rosterTemplates.filter(s=>s.weekday===2).length,0);
});

test('night shift keeps one business date until exact opening and completed evidence survives rollover',async()=>{
  const f=fixture('2026-09-30T14:30:00Z');
  f.edit(s=>{s.workplace.businessDayStart='10:00';});
  let view=await f.read('owner');
  const task=view.tasks.find(t=>t.kind==='routine'&&t.requiredRole==='all'&&t.steps?.length);
  await f.act('owner','complete_step',{taskId:task.id,stepId:task.steps[0].id});
  const completed=f.raw().tasks.find(t=>t.id===task.id).steps[0];
  f.setTime('2026-10-01T00:59:59Z');
  assert.equal(businessDate(f.raw(),f.now()),'2026-09-30');
  assert.equal(actualDate(f.raw(),'2026-09-30','02:00'),'2026-10-01');
  assert.equal((await f.read('owner')).day,'2026-09-30');
  f.setTime('2026-10-01T01:00:00Z');
  view=await f.read('owner');
  assert.equal(view.day,'2026-10-01');
  assert.deepEqual(f.raw().tasks.find(t=>t.id===task.id).steps[0],completed);
  await assert.rejects(f.act('owner','complete_step',{taskId:task.id,stepId:task.steps[0].id}),{status:409});
});

test('count and receipt preserve exact order deadline, duplicate receipt rejects, reorder retains historical checks',async()=>{
  const f=fixture('2026-09-19T14:30:00Z');
  await f.act('owner','review_policy',{itemId:'rice',reviewDays:2,minimum:5});
  let view=await f.act('owner','place_order',{lines:[{itemId:'rice',quantity:10}]});
  const order=view.orders[0],due=view.items.find(i=>i.id==='rice').reviewDueAt;
  const initialQuantity=view.items.find(i=>i.id==='rice').quantity;
  f.setTime('2026-09-20T01:00:00Z');
  view=await f.act('crew','check_stock',{itemId:'rice',quantity:3});
  assert.equal(view.items.find(i=>i.id==='rice').reviewDueAt,due);
  view=await f.act('manager','receive_order',{orderId:order.id});
  assert.equal(view.items.find(i=>i.id==='rice').quantity,13);
  assert.equal(view.items.find(i=>i.id==='rice').reviewDueAt,due);
  await assert.rejects(f.act('manager','receive_order',{orderId:order.id}),{status:409});
  assert.equal((await f.read('owner')).items.find(i=>i.id==='rice').quantity,13);
  assert.equal(initialQuantity,2,'placing an order leaves the known initial stock alone');
  f.setTime(due);
  view=await f.read('owner');
  const oldCheck=view.tasks.find(t=>t.itemId==='rice'&&!t.completedAt);
  assert.ok(oldCheck);
  const second=await f.act('owner','place_order',{lines:[{itemId:'rice',quantity:1}]});
  assert.equal(second.orders.length,2);
  assert.ok(f.raw().tasks.find(t=>t.id===oldCheck.id).supersededAt);
  assert.ok(f.raw().orders.find(o=>o.id===order.id).receivedAt);
  assert.notEqual(second.items.find(i=>i.id==='rice').reviewDueAt,due);
  await assert.rejects(f.act('crew','complete_task',{taskId:oldCheck.id,quantity:0}),{status:409});
});

test('order board visibility toggles preserve tickets, procurement orders and completion evidence',async()=>{
  const f=fixture();
  await f.act('owner','place_order',{lines:[{itemId:'rice',quantity:1}]});
  const before=f.raw();
  for(const enabled of [true,false,true]){
    const view=await f.act('owner','save_order_system',{enabled});
    assert.equal(view.orderBoardEnabled,enabled);
    assert.deepEqual(f.raw().sales,before.sales);
    assert.deepEqual(f.raw().orders,before.orders);
    assert.deepEqual(f.raw().tasks,before.tasks);
    assert.equal(view.store.profile.orderSystem.connectionStatus,'not_connected');
  }
  await assert.rejects(f.act('manager','save_order_system',{enabled:false}),{status:403});
});

test('trusted crew/cook cannot gain editing or payroll access from enabled restriction toggles',async()=>{
  const f=fixture();
  for(const role of ['crew','cook']) {
    await f.act('owner','save_workplace_permissions',{role,permissions:{tasks:true,complete:true,schedule:true,stock:true,orders:true}});
    const view=await f.read(role);
    assert.equal(view.actor.id,`audit-${role}`);
    assert.equal(view.canEditTasks,false);
    assert.equal(view.labor,undefined);
    assert.equal(view.privateSummary,undefined);
    assert.ok(view.items.every(i=>i.price===undefined));
    await assert.rejects(f.act(role,'create_task',{title:'금지',requiredRole:'all',slot:'준비',zone:'sink'}),{status:403});
    await assert.rejects(f.act(role,'place_order',{lines:[{itemId:'rice',quantity:1}]}),{status:403});
    await assert.rejects(f.act(role,'save_workplace_permissions',{role,permissions:{tasks:true}}),{status:403});
  }
  await f.act('owner','save_workplace_permissions',{role:'manager',permissions:{tasks:false,complete:false,stock:false,orders:false}});
  const manager=await f.read('manager');
  assert.equal(manager.canEditTasks,false);
  assert.ok(manager.tasks.every(t=>!t.canComplete));
  assert.equal(manager.labor,undefined);
  await assert.rejects(f.act('manager','check_stock',{itemId:'rice',quantity:1}),{status:403});
  await assert.rejects(f.act('manager','create_task',{title:'금지',requiredRole:'all',slot:'준비',zone:'sink'}),{status:403});
});

test('routine issue note does not block work, blocked issue requires permitted leadership resolution',async()=>{
  const f=fixture();
  let view=await f.read('crew');
  const task=view.tasks.find(t=>t.kind==='routine'&&t.requiredRole==='all'&&t.steps?.length>1);
  view=await f.act('crew','flag_work_issue',{taskId:task.id,stepId:task.steps[0].id,severity:'note',reason:'참고 기록'});
  assert.equal(view.tasks.find(t=>t.id===task.id).workIssue.blocksCompletion,false);
  await f.act('crew','complete_step',{taskId:task.id,stepId:task.steps[0].id});
  await f.act('crew','flag_work_issue',{taskId:task.id,stepId:task.steps[1].id,severity:'blocked',reason:'수행 불가'});
  await assert.rejects(f.act('crew','complete_step',{taskId:task.id,stepId:task.steps[1].id}),{status:409});
  await assert.rejects(f.act('crew','resolve_work_issue',{taskId:task.id,reason:'권한 없는 해제'}),{status:403});
  await f.act('owner','save_workplace_permissions',{role:'manager',permissions:{tasks:false}});
  await assert.rejects(f.act('manager','resolve_work_issue',{taskId:task.id,reason:'권한 꺼짐'}),{status:403});
  await f.act('owner','resolve_work_issue',{taskId:task.id,reason:'조치 확인'});
  view=await f.act('crew','complete_step',{taskId:task.id,stepId:task.steps[1].id});
  assert.ok(view.tasks.find(t=>t.id===task.id).steps[1].completedAt);
});

for(const severity of ['note','blocked']) test(`unresolved ${severity} routine survives business rollover for review, never permits historical completion`,async()=>{
  const f=fixture('2026-09-30T14:30:00Z');
  f.edit(s=>{s.workplace.businessDayStart='10:00';});
  const before=await f.read('crew');
  const task=before.tasks.find(t=>t.kind==='routine'&&t.requiredRole==='all'&&t.steps?.length>1);
  await f.act('crew','complete_step',{taskId:task.id,stepId:task.steps[0].id});
  await f.act('crew','flag_work_issue',{taskId:task.id,stepId:task.steps[1].id,severity,reason:'다음 날 확인이 필요한 가상 기록'});
  const snapshot=f.raw().tasks.find(t=>t.id===task.id);
  f.setTime('2026-10-01T01:00:00Z');
  for(const role of ['manager','crew']) {
    const view=await f.read(role),historical=view.tasks.find(t=>t.id===task.id);
    assert.ok(historical,'unresolved report remains visible');
    assert.equal(historical.workIssue.status,'open');
    assert.equal(historical.date,snapshot.date);
    assert.deepEqual(historical.steps.map(s=>s.completedAt),snapshot.steps.map(s=>s.completedAt));
    assert.equal(historical.canComplete,false);
    assert.ok(historical.steps.every(s=>s.canComplete===false));
    assert.equal(view.labor,undefined);
    assert.equal(view.privateSummary,undefined);
    await assert.rejects(f.act(role,'complete_step',{taskId:task.id,stepId:task.steps[1].id}),{status:409});
  }
  await assert.rejects(f.act('crew','resolve_work_issue',{taskId:task.id,reason:'무권한 해제'}),{status:403});
  await f.act('manager','resolve_work_issue',{taskId:task.id,reason:'다음 영업일 조치 확인'});
  const resolved=f.raw().tasks.find(t=>t.id===task.id);
  assert.equal(resolved.workIssue.status,'resolved');
  assert.equal(resolved.workIssue.reason,snapshot.workIssue.reason);
  assert.equal(resolved.workIssue.resolvedBy.id,'audit-manager');
  assert.deepEqual(resolved.steps,snapshot.steps,'reviewing an old report never rewrites completed or uncompleted actions');
  assert.equal(resolved.date,snapshot.date);
});

test('issue media permission and signed receipts reject other identity, store, task, photo and expiry',async()=>{
  const f=fixture(),view=await f.read('crew');
  const task=view.tasks.find(t=>t.kind==='routine'&&t.requiredRole==='all'&&t.steps?.length);
  const state=f.raw(),member={role:'crew'};
  assert.doesNotThrow(()=>assertIssuePhotoPermission(state,member,'audit-crew',task.id,f.now()));
  assert.throws(()=>assertIssuePhotoPermission(state,member,'audit-crew','unknown',f.now()),{status:403});
  state.workplace.restrictions.crew={complete:false};
  assert.throws(()=>assertIssuePhotoPermission(state,member,'audit-crew',task.id,f.now()),{status:403});
  const photo='tap2work-media:audit-workspace/00000000-0000-4000-8000-000000000001.jpg';
  const key='synthetic-test-key',claim={userId:'audit-crew',workspaceId:'audit-workspace',taskId:task.id,reference:photo};
  const input={taskId:task.id,photo,photoReceipt:issuePhotoReceipt(claim,key,f.now())};
  assert.doesNotThrow(()=>verifyIssuePhotoReceipt(input,claim.userId,claim.workspaceId,key,f.now()));
  for(const [payload,user,workspace,now] of [
    [input,'other',claim.workspaceId,f.now()],
    [input,claim.userId,'other',f.now()],
    [{...input,taskId:'other'},claim.userId,claim.workspaceId,f.now()],
    [{...input,photo:photo.replace('000001','000002')},claim.userId,claim.workspaceId,f.now()],
    [{...input,photoReceipt:input.photoReceipt+'x'},claim.userId,claim.workspaceId,f.now()],
    [input,claim.userId,claim.workspaceId,new Date(f.now().getTime()+8*86400000)],
  ]) assert.throws(()=>verifyIssuePhotoReceipt(payload,user,workspace,key,now),{status:403});
});
