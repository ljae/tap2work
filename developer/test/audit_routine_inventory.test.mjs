import test from 'node:test';
import assert from 'node:assert/strict';
import { OperationsStore, seedOperations } from '../operations.mjs';
import { inventoryReadiness } from '../inventory_readiness.mjs';
import { assertIssuePhotoPermission, issuePhotoReceipt, verifyIssuePhotoReceipt } from '../work_issue_media.mjs';
const now = new Date('2026-10-10T03:00:00Z');
function fixture(){let state=seedOperations(now);const store=new OperationsStore(null,()=>now,{persistence:{read:async()=>structuredClone(state),save:async next=>{state=structuredClone(next);}}});return {store,raw:()=>state,act:async(action,args={},actor='owner')=>{const v=await store.snapshot(actor);return store.mutate(actor,{action,revision:v.revision,...args});}};}
test('routine blocked report prevents completion; a note allows work and remains resolvable after completion',async()=>{
 const x=fixture();let view=await x.store.snapshot('owner');const t=view.tasks.find(t=>t.kind==='routine'&&t.steps.length>1);
 await x.act('flag_work_issue',{taskId:t.id,reason:'배수구 막힘',severity:'blocked'});
 await assert.rejects(x.act('complete_step',{taskId:t.id,stepId:t.steps[0].id}),{code:'WORK_ISSUE_BLOCKED'});
 await assert.rejects(x.act('flag_work_issue',{taskId:t.id,reason:'단순 주의로 변경',severity:'note'}),{status:409});
 await x.act('resolve_work_issue',{taskId:t.id,reason:'현장 담당자가 조치 확인'});
 await x.act('flag_work_issue',{taskId:t.id,reason:'다음 교대에 안내',severity:'note'});
 for(const step of t.steps) await x.act('complete_step',{taskId:t.id,stepId:step.id});
 assert.ok(x.raw().tasks.find(row=>row.id===t.id).completedAt);
 await x.act('resolve_work_issue',{taskId:t.id,reason:'다음 교대 전달 완료'});
 const saved=x.raw().tasks.find(row=>row.id===t.id);assert.equal(saved.workIssue.status,'resolved');assert.equal(saved.workIssue.blocksCompletion,false);assert.equal(saved.workIssueHistory[0].reason,'배수구 막힘');
});
test('an open note cannot hide a later blocking report; unknown severity is rejected',async()=>{
 const x=fixture(),v=await x.store.snapshot('owner'),t=v.tasks.find(t=>t.kind==='routine');
 await x.act('flag_work_issue',{taskId:t.id,reason:'주의 사항',severity:'note'});
 await x.act('flag_work_issue',{taskId:t.id,reason:'이제 수행 불가',severity:'blocked'});
 const saved=x.raw().tasks.find(row=>row.id===t.id);assert.equal(saved.workIssue.blocksCompletion,true);assert.equal(saved.workIssueHistory[0].blocksCompletion,false);
 await assert.rejects(x.act('flag_work_issue',{taskId:t.id,reason:'x',severity:'fake'}),{status:400});
});
test('starter unknown zero is not shortage; counted zero and confirmed order policy remain shortage',()=>{
 const draft={quantity:0,minimum:5,orderQuantity:10,unit:'봉',supplier:'공급처 미설정',setupNeedsReview:true,lastCheckedAt:null};
 assert.equal(inventoryReadiness(draft).inventoryStatus,'quantity_unknown');
 assert.equal(inventoryReadiness({...draft,lastCheckedAt:now.toISOString()}).inventoryStatus,'policy_unknown');
 const counted={...draft,setupNeedsReview:false,supplier:'가상 공급처',lastCheckedAt:now.toISOString()};
 assert.equal(inventoryReadiness(counted).inventoryStatus,'low');assert.equal(inventoryReadiness(counted).orderReady,true);
 assert.equal(inventoryReadiness({...counted,quantity:6}).inventoryStatus,'sufficient');
});
test('server prevents ordering unreviewed or uncounted items and new-item zero needs count',async()=>{
 const x=fixture();await x.store.snapshot('owner');const original=x.raw().items[0];original.setupNeedsReview=true;original.quantity=0;original.lastCheckedAt=null;
 await assert.rejects(x.act('place_order',{lines:[{itemId:original.id,quantity:1}]}),{code:'INVENTORY_NOT_READY'});
 await x.act('check_stock',{itemId:original.id,quantity:0});
 await assert.rejects(x.act('place_order',{lines:[{itemId:original.id,quantity:1}]}),{code:'INVENTORY_NOT_READY'});
 const fields={id:original.id,name:original.name,unit:original.unit,supplier:original.supplier,minimum:3,orderQuantity:4,price:1000,reviewDays:3};await x.act('save_inventory_item',fields);
 await x.act('place_order',{lines:[{itemId:original.id,quantity:4}]});const before=x.raw().items[0];assert.equal(before.quantity,0);const deadline=before.lastOrderedAt;
 await x.act('receive_order',{orderId:x.raw().orders[0].id});assert.equal(x.raw().items[0].quantity,4);assert.equal(x.raw().items[0].lastOrderedAt,deadline);
 await x.act('save_inventory_item',{...fields,id:undefined,name:'가상 새 재료'});const created=x.raw().items.find(i=>i.name==='가상 새 재료');assert.equal(inventoryReadiness(created).quantityConfirmed,false);
 await assert.rejects(x.act('place_order',{lines:[{itemId:created.id,quantity:1}]}),{code:'INVENTORY_NOT_READY'});
});
test('issue photo receipt is bound to authenticated actor, store, task, photo and expiry',()=>{
 const reference='tap2work-media:store-a/12345678-1234-1234-1234-123456789abc.jpg',claim={userId:'crew-a',workspaceId:'store-a',taskId:'task-a',reference};
 const receipt=issuePhotoReceipt(claim,'test-key',now),input={taskId:'task-a',photo:reference,photoReceipt:receipt};
 verifyIssuePhotoReceipt(input,'crew-a','store-a','test-key',now);
 for(const [user,workspace,key,date,value] of [['crew-b','store-a','test-key',now,input],['crew-a','store-b','test-key',now,input],['crew-a','store-a','bad-key',now,input],['crew-a','store-a','test-key',new Date(now.getTime()+8*86400000),input],['crew-a','store-a','test-key',now,{...input,taskId:'other'}],['crew-a','store-a','test-key',now,{...input,photoReceipt:receipt+'a'}]]) assert.throws(()=>verifyIssuePhotoReceipt(value,user,workspace,key,date),{status:403});
});
test('issue photo upload obeys existing task assignment and disabled completion permissions',()=>{
 const state={tasks:[{id:'t',date:'2026-10-10',requiredRole:'crew',steps:[{id:'s'}]}],tappers:[],workplace:{}};
 assertIssuePhotoPermission(state,{role:'crew'},'a','t',now);
 assert.throws(()=>assertIssuePhotoPermission(state,{role:'cook'},'a','t',now),{status:403});
 state.workplace.restrictions={crew:{complete:false}};assert.throws(()=>assertIssuePhotoPermission(state,{role:'crew'},'a','t',now),{status:403});
 state.tasks[0].completedAt=now.toISOString();assert.throws(()=>assertIssuePhotoPermission(state,{role:'owner'},'a','t',now),{status:403});
});
test('stock count records quantity without completing a blocked inventory task',async()=>{
 const x=fixture();let view=await x.store.snapshot('owner');const item=x.raw().items[0];item.lastOrderedAt=new Date(now.getTime()-3*86400000).toISOString();item.reviewDays=3;item.lastOrderId='old-check';
 view=await x.store.snapshot('owner');const task=view.tasks.find(t=>t.kind==='stock'&&t.itemId===item.id);
 await x.act('flag_work_issue',{taskId:task.id,reason:'수량을 확인하기 어려운 상태',severity:'blocked'});
 await x.act('check_stock',{itemId:item.id,quantity:0});assert.equal(x.raw().items[0].quantity,0);assert.equal(x.raw().tasks.find(t=>t.id===task.id).completedAt,null);
 await x.act('resolve_work_issue',{taskId:task.id,reason:'실물 확인 가능 상태로 조치'});await x.act('check_stock',{itemId:item.id,quantity:0});assert.ok(x.raw().tasks.find(t=>t.id===task.id).completedAt);
});
test('an assigned legacy step uses the same permission for an issue report and its photo',async()=>{
 const x=fixture();await x.store.snapshot('owner');const task={id:'step-role-issue',date:'2026-10-10',kind:'routine',requiredRole:'cook',title:'가상 혼합 담당',steps:[{id:'crew-step',title:'크루 행동',settings:{roleOverride:'crew'}}]};x.raw().tasks.push(task);
 assertIssuePhotoPermission(x.raw(),{role:'crew'},'crew',task.id,now);
 const view=await x.act('flag_work_issue',{taskId:task.id,stepId:'crew-step',reason:'담당 행동 확인 요청',severity:'note'},'crew');
 assert.equal(view.tasks.find(t=>t.id===task.id).workIssue.actor.id,'crew');
});
