import {test} from 'node:test';
import assert from 'node:assert/strict';
import {receiptReplay,receiveInventoryOrder} from '../inventory_receipts.mjs';

const actor={id:'synthetic-owner',name:'가상 사장',role:'owner',label:'사장님'};
const at=new Date('2026-10-10T01:00:00Z');
function fixture() {
  return {workplace:{restrictions:{}},items:[
    {id:'rice',quantity:2,lastOrderedAt:'2026-10-09T01:00:00Z',lastOrderId:'order-1',reviewDueAt:'2026-10-12T01:00:00Z',reviewDays:3},
    {id:'oil',quantity:1,lastOrderId:'order-1'},
  ],orders:[{id:'order-1',status:'ordered',createdAt:'2026-10-09T01:00:00Z',lines:[
    {itemId:'rice',name:'쌀',quantity:10,unit:'봉'},
    {itemId:'oil',name:'기름',quantity:0.3,unit:'L'},
  ],receivedAt:null}],tasks:[{id:'check',dueAt:'2026-10-12T01:00:00Z',orderId:'order-1'}]};
}
const input=(lines,receiptId='receipt-0001')=>({action:'receive_order',orderId:'order-1',receiptId,lines});
const apply=(state,request,who=actor,now=at)=>receiveInventoryOrder(state,request,who,now);

test('partial batches increment only received amounts, keep order deadlines, finish only when every line arrives',()=>{
  const state=fixture(),before=structuredClone(state);
  apply(state,input([{itemId:'rice',quantity:3},{itemId:'oil',quantity:0}]));
  assert.equal(state.items[0].quantity,5);
  assert.equal(state.items[1].quantity,1);
  assert.equal(state.orders[0].status,'ordered');
  assert.equal(state.orders[0].receivedAt,null);
  assert.equal(state.orders[0].lines[0].receivedQuantity,3);
  assert.deepEqual(state.orders[0].receiptHistory[0].lines,[{itemId:'rice',name:'쌀',unit:'봉',quantity:3}]);
  apply(state,input([{itemId:'oil',quantity:0.1}],'receipt-0002'));
  apply(state,input([{itemId:'rice',quantity:7},{itemId:'oil',quantity:0.2}],'receipt-0003'),actor,new Date('2026-10-11T01:00:00Z'));
  assert.equal(state.items[0].quantity,12);
  assert.equal(state.items[1].quantity,1.3);
  assert.equal(state.orders[0].status,'received');
  assert.equal(state.orders[0].receivedAt,'2026-10-11T01:00:00.000Z');
  assert.equal(state.orders[0].receiptHistory.length,3);
  assert.deepEqual(state.orders[0].receiptHistory.map(r=>r.receivedBy.id),Array(3).fill(actor.id));
  assert.deepEqual(state.tasks,before.tasks);
  for(const key of ['lastOrderedAt','lastOrderId','reviewDueAt','reviewDays']) assert.equal(state.items[0][key],before.items[0][key]);
});

test('exact batch replay is idempotent before/after final receipt and rejects changed body/actor/order',()=>{
  const state=fixture(),request=input([{itemId:'rice',quantity:3}]);
  apply(state,request);
  const snapshot=structuredClone(state);
  assert.equal(receiptReplay(state,{...request,revision:1},actor),true);
  apply(state,request);
  assert.deepEqual(state,snapshot);
  for(const changed of [{...request,lines:[{itemId:'rice',quantity:4}]},{...request,orderId:'other'},{...request,lines:undefined}]) assert.throws(()=>receiptReplay(state,changed,actor),{status:409});
  assert.throws(()=>receiptReplay(state,request,{...actor,id:'another-owner'}),{status:409});
  const last=input(undefined,'receipt-final');
  apply(state,last);
  const final=structuredClone(state);
  assert.equal(receiptReplay(state,last,actor),true);
  apply(state,last);
  assert.deepEqual(state,final);
  assert.throws(()=>apply(state,input(undefined,'receipt-other')),{status:409});
});

test('legacy request receives only the remainder and legacy fully received order rejects a second receipt',()=>{
  const state=fixture();
  apply(state,input([{itemId:'rice',quantity:3}]));
  apply(state,{orderId:'order-1'});
  assert.equal(state.items[0].quantity,12);
  assert.equal(state.items[1].quantity,1.3);
  assert.equal(state.orders[0].receiptHistory[1].lines[0].quantity,7);
  assert.throws(()=>apply(state,{orderId:'order-1'}),{status:409});
  const legacy=fixture();legacy.orders[0].status='received';
  assert.throws(()=>apply(legacy,{orderId:'order-1'}),{status:409});
});

test('invalid or over-remaining batch is atomic, including stock capacity, duplicate and missing items',()=>{
  for(const lines of [
    [{itemId:'rice',quantity:1},{itemId:'oil',quantity:1}],
    [{itemId:'rice',quantity:0}],
    [{itemId:'rice',quantity:-1}],
    [{itemId:'rice',quantity:NaN}],
    [{itemId:'rice',quantity:Infinity}],
    [{itemId:'rice',quantity:'1'}],
    [{itemId:'rice',quantity:100001}],
    [{itemId:'rice',quantity:1},{itemId:'rice',quantity:2}],
    [{itemId:'missing',quantity:1}], [], null,
  ]) {
    const state=fixture(),before=structuredClone(state);
    assert.throws(()=>apply(state,input(lines)));
    assert.deepEqual(state,before);
  }
  const overflow=fixture();overflow.items[0].quantity=100000;
  const before=structuredClone(overflow);
  assert.throws(()=>apply(overflow,input([{itemId:'rice',quantity:1}])));
  assert.deepEqual(overflow,before);
  const missing=fixture();missing.items[1].archivedAt=at.toISOString();
  const original=structuredClone(missing);
  assert.throws(()=>apply(missing,input([{itemId:'rice',quantity:1},{itemId:'oil',quantity:0.1}])));
  assert.deepEqual(missing,original);
});

test('receipt identity validation and current role permissions also apply to replay',()=>{
  const state=fixture(),request=input([{itemId:'rice',quantity:1}]);
  assert.throws(()=>apply(state,{...request,receiptId:''}),{status:400});
  for(const role of ['crew','cook']) assert.throws(()=>apply(state,request,{...actor,role}),{status:403});
  const manager={...actor,role:'manager'};
  apply(state,request,manager);
  state.workplace.restrictions.manager={orders:false};
  assert.throws(()=>receiptReplay(state,request,manager),{status:403});
  assert.throws(()=>apply(state,input(undefined,'receipt-next'),manager),{status:403});
});

test('OperationsStore replay succeeds with the original stale revision without adding stock/history twice',async()=>{
  const {OperationsStore,seedOperations}=await import('../operations.mjs');
  let state=seedOperations(at);
  const store=new OperationsStore(null,()=>at,{actor,persistence:{read:async()=>structuredClone(state),save:async(next)=>{state=structuredClone(next);}}});
  let view=await store.snapshot();
  view=await store.mutate(null,{action:'place_order',revision:view.revision,lines:[{itemId:'rice',quantity:10}]});
  const oldRevision=view.revision,orderId=view.orders[0].id,stock=view.items.find(row=>row.id==='rice').quantity;
  const request={action:'receive_order',revision:oldRevision,orderId,receiptId:'integration-receipt',lines:[{itemId:'rice',quantity:3}]};
  view=await store.mutate(null,request);
  const revision=view.revision;
  view=await store.mutate(null,request);
  assert.equal(view.revision,revision);
  assert.equal(view.items.find(row=>row.id==='rice').quantity,stock+3);
  assert.equal(view.orders[0].receiptHistory.length,1);
  assert.equal(view.orders[0].status,'ordered');
  await assert.rejects(store.mutate(null,{...request,lines:[{itemId:'rice',quantity:4}]}),{status:409});
  view=await store.mutate(null,{action:'receive_order',revision,orderId,receiptId:'integration-final'});
  assert.equal(view.items.find(row=>row.id==='rice').quantity,stock+10);
  assert.equal(view.orders[0].status,'received');
  const finalRevision=view.revision;
  view=await store.mutate(null,{action:'receive_order',revision,orderId,receiptId:'integration-final'});
  assert.equal(view.revision,finalRevision);
  assert.equal(view.orders[0].receiptHistory.length,2);
});
