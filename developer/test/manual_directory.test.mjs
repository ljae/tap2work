import { test } from 'node:test';
import assert from 'node:assert/strict';
import { OperationsStore, emptyOperations } from '../operations.mjs';
import { moveManualNode } from '../manual_directory.mjs';
function fixture(role='owner') {
 const now=new Date('2026-09-27T08:00:00Z');
 let state=emptyOperations(now,'owner-1','사장님');
 state.checklistFolders=[{id:'general',name:'기본 업무'},{id:'close',name:'마감'}];
 state.bigTapOrder=['general','close'];
 const step=(id)=>({id,title:id,manual:`${id} 매뉴얼`,tip:'팁',tags:['위생'],settings:{completionKind:'check'}});
 const tap=(id,folderId,steps)=>({id,title:id,folderId,slot:'준비',requiredRole:'all',zone:null,version:1,steps:steps.map(step)});
 state.taskTemplates=[tap('a','general',['s1','s2']),tap('b','close',['s3'])];
 const actor={id:role==='owner'?'owner-1':'crew-1',role,name:'체험'};
 const store=new OperationsStore(null,()=>now,{actor,persistence:{read:async()=>structuredClone(state),save:async(next,revision)=>{assert.equal(revision,state.revision);state=structuredClone(next);}}});
 const act=async(values)=>{const view=await store.snapshot(actor.id);return store.mutate(actor.id,{action:'move_manual_node',revision:view.revision,...values});};
 return {store,act,raw:()=>state,actor};
}
test('manual directory moves preserve Task manual/settings and today snapshots',async()=>{
 const x=fixture(); await x.store.snapshot(x.actor.id);
 const previous=structuredClone(x.raw().tasks);
 const step=structuredClone(x.raw().taskTemplates[0].steps[0]);
 const view=await x.act({kind:'task',sourceTapId:'a',id:'s1',targetId:'b',beforeId:'s3'});
 assert.deepEqual(x.raw().taskTemplates[1].steps[0],step);
 assert.deepEqual(x.raw().tasks,previous);
 assert.equal(view.manualSearch.find(r=>r.id==='b/s1').folderName,'마감');
 assert.equal(view.manualSearch.find(r=>r.id==='b/s1').templateId,'b');
 assert.equal(x.raw().taskTemplates[0].version,2);
 await x.act({kind:'tap',id:'b',targetId:'general',beforeId:'a'});
 assert.equal(x.raw().taskTemplates[0].id,'b');
 assert.equal(x.raw().taskTemplates[0].folderId,'general');
 await x.act({kind:'group',id:'close',beforeId:'general'});
 assert.deepEqual(x.raw().bigTapOrder,['close','general']);
});
test('manual directory rejects missing targets without partial edits, and resolves ID collisions',()=>{
 const x=fixture(); const state=structuredClone(x.raw());
 const previous=structuredClone(state);

 assert.throws(()=>moveManualNode(state,{kind:'task',sourceTapId:'a',id:'s1',targetId:'b',beforeId:'missing'}),/이동 위치/);
 assert.deepEqual(state,previous);
 state.taskTemplates[1].steps.push(structuredClone(state.taskTemplates[0].steps[0]));
 const collision=structuredClone(state);
 moveManualNode(state,{kind:'task',sourceTapId:'a',id:'s1',targetId:'b'});
 assert.equal(state.taskTemplates[1].steps.at(-1).manual,collision.taskTemplates[0].steps[0].manual);
 assert.notEqual(state.taskTemplates[1].steps.at(-1).id,'s1');
 assert.equal(new Set(state.taskTemplates[1].steps.map(r=>r.id)).size,3);
});
test('manual directory enforces role and opening revision; crew can search hierarchy',async()=>{
 const crew=fixture('crew');
 const view=await crew.store.snapshot(crew.actor.id);
 assert.equal(view.taskTemplates,undefined);
 assert.equal(view.manualSearch.find(r=>r.id==='a/s1').folderId,'general');
 await assert.rejects(()=>crew.act({kind:'group',id:'close',beforeId:'general'}),{status:403});
 const owner=fixture();
 const opening=await owner.store.snapshot(owner.actor.id);
 await owner.act({kind:'group',id:'close',beforeId:'general'});
 await assert.rejects(()=>owner.store.mutate(owner.actor.id,{action:'move_manual_node',revision:opening.revision,kind:'group',id:'general',beforeId:'close'}),{status:409});
});
test('Task reordering stays linked to the same manual and validates before persisting',async()=>{
 const x=fixture();
 await x.act({kind:'task',sourceTapId:'a',id:'s2',targetId:'a',beforeId:'s1'});
 assert.deepEqual(x.raw().taskTemplates[0].steps.map(s=>s.id),['s2','s1']);
 assert.equal(x.raw().taskTemplates[0].steps[0].manual,'s2 매뉴얼');
 await assert.rejects(()=>x.act({kind:'tap',id:'a',targetId:'close',beforeId:'a-missing'}),{status:400});
});

test('last Task moves out and back into an empty TAP without losing definitions',async()=>{
 const x=fixture();const before=await x.store.snapshot(x.actor.id);const executions=structuredClone(x.raw().tasks);
 await x.act({kind:'task',sourceTapId:'b',id:'s3',targetId:'a'});
 assert.deepEqual(x.raw().taskTemplates.find(t=>t.id==='b').steps,[]);
 await x.act({kind:'tap',id:'b',targetId:'general'});
 const view=await x.act({kind:'task',sourceTapId:'a',id:'s3',targetId:'b'});
 assert.equal(view.manualSearch.find(r=>r.id==='b/s3').folderId,'general');
 assert.deepEqual(x.raw().tasks,executions);
 assert.equal(before.taskTemplates.length,view.taskTemplates.length);
});
