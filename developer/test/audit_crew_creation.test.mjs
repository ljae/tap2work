import test from 'node:test';
import assert from 'node:assert/strict';
import {OperationsStore,emptyOperations} from '../operations.mjs';
import {crewCreationReplay} from '../staff.mjs';

function fixture(){
 const now=new Date('2026-10-10T05:00:00Z'),actor={id:'owner-audit',role:'owner',name:'사장님'};
 let state=emptyOperations(now,actor.id);
 const store=new OperationsStore(null,()=>now,{actor,persistence:{read:async()=>structuredClone(state),save:async value=>{state=structuredClone(value);}}});
 return {store,actor,state:()=>state};
}
const input={action:'save_tapper',creationRequestId:'audit-creation-123456789',nickname:'가상 크루',rank:'crew',employmentType:'시간알바',hourlyWon:10320,payPeriod:'monthly',kakaoUrl:'',phone:'',active:true,nationality:'VN',guideLocale:'vi'};
test('lost create response replay does not create a duplicate or overwrite later edits',async()=>{
 const x=fixture();const opening=await x.store.snapshot();
 const created=await x.store.mutate(null,{...input,revision:opening.revision});
 const row=created.tappers.find(t=>t.creationRequestId===input.creationRequestId);
 assert.ok(row);assert.equal(row.creationFingerprint,undefined);assert.equal(row.creationActorId,undefined);
 const edited=await x.store.mutate(null,{...input,id:row.id,nickname:'나중에 수정',revision:created.revision});
 const replay=await x.store.mutate(null,{...input,revision:opening.revision});
 assert.equal(replay.revision,edited.revision);assert.equal(replay.tappers.length,2);
 assert.equal(replay.tappers.find(t=>t.id===row.id).nickname,'나중에 수정');
});
test('creation identity cannot be reused for another payload, actor or unauthorized role',async()=>{
 const x=fixture(),opening=await x.store.snapshot();await x.store.mutate(null,{...input,revision:opening.revision});
 await assert.rejects(x.store.mutate(null,{...input,nickname:'다른 입력',revision:opening.revision}),e=>e.status===409&&e.code==='CREATE_REQUEST_MISMATCH');
 assert.throws(()=>crewCreationReplay(x.state(),input,{id:'other',role:'owner'}),e=>e.status===409);
 assert.throws(()=>crewCreationReplay(x.state(),input,{id:x.actor.id,role:'crew'}),e=>e.status===403);
 assert.throws(()=>crewCreationReplay(x.state(),{...input,creationRequestId:'bad'},x.actor),e=>e.status===400);
});
