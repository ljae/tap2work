import test from 'node:test';
import assert from 'node:assert/strict';
import {OperationsStore,emptyOperations} from '../operations.mjs';
import {composeManual} from '../manual_setup.mjs';
const now=new Date('2026-10-10T03:00:00Z');
function fixture(){let state=emptyOperations(now,'owner','가상사장님');const store=new OperationsStore(null,()=>now,{actor:{id:'owner',name:'가상사장님',role:'owner'},persistence:{read:async()=>structuredClone(state),save:async s=>{state=structuredClone(s)}}});return {store,raw:()=>state,act:async(action,args={})=>{const v=await store.snapshot();return store.mutate('owner',{action,revision:v.revision,...args})}};}
test('opt-in example adds four reusable manuals once, with no automatic work or invented store photos',async()=>{
 const x=fixture();let v=await x.act('add_dishwashing_example');assert.equal(v.taskTemplates.length,4);assert.equal(v.tasks.length,0);
 assert.deepEqual(v.taskTemplates.map(t=>t.settings.usage),['routine','routine','routine','reference']);
 assert.ok(v.taskTemplates.every(t=>!t.settings.enabled));
 assert.ok(v.taskTemplates.flatMap(t=>t.steps).every(s=>s.manual.length<=700&&!s.imageUrl));
 await x.act('add_dishwashing_example');assert.equal(x.raw().taskTemplates.length,4);
});
test('linked places and photo project into the action; edits and backups preserve keys, old config saves keep new links',async()=>{
 const x=fixture();await x.act('add_dishwashing_example');
 for(const id of ['return','waste','wash','dry']) await x.act('save_place',{place:{id,kind:'storage',name:'가상 '+id,floor:'1층',area:'실제 매장에서 확인',description:'이 장소의 안내',photo:id==='return'?'https://example.invalid/test.jpg':''}});
 await x.act('save_manual_setup',{setup:{conditions:{selfbar:false},places:{return:'return',waste:'waste',wash:'wash',dry:'dry'}}});
 let t=x.raw().taskTemplates[0];let action=composeManual(x.raw(),t).steps[0];assert.equal(action.linkedPlace.zoneId,'return');assert.equal(action.linkedPlace.photo,'https://example.invalid/test.jpg');assert.equal(action.linkedPlace.floor,'1층');
 await x.act('save_manual_tap',{templateId:t.id,title:t.title,emoji:t.emoji,folderId:t.folderId,steps:t.steps.map(s=>{const {placeKey,...fields}=s;return {...fields,manual:s.manual+' 매장 수정.'}})});
 t=x.raw().taskTemplates[0];assert.equal(t.steps[0].placeKey,'return');assert.equal(t.manualCustomization.kind,'created');
 const view=await x.store.snapshot();assert.equal(view.checklistBackup.templates[0].steps[0].placeKey,'return');
 await x.act('save_manual_setup',{setup:{conditions:{selfbar:true},places:{waste:'waste'}}});assert.equal(x.raw().store.manualSetup.places.return,'return');
 await x.act('save_place',{place:{...x.raw().zones.find(z=>z.id==='return'),name:'수정된 반납대'}});assert.equal(composeManual(x.raw(),t).steps[0].linkedPlace.name,'수정된 반납대');
});
test('same issue request can replay stale revision, but modified payload cannot duplicate or overwrite',async()=>{
 const x=fixture();await x.act('add_dishwashing_example');const t=x.raw().taskTemplates[0];
 let v=await x.act('save_tap_settings',{templateId:t.id,assignmentScopeVersion:2,settings:{...t.settings,enabled:true,usage:'routine',assignment:{mode:'anyone'}}});const task=v.tasks.find(row=>row.templateId===t.id);
 const input={action:'flag_work_issue',taskId:task.id,requestId:'issue-request-12345',severity:'note',reason:'교대에 전달'};const revision=v.revision;
 await x.store.mutate('owner',{...input,revision});await x.store.mutate('owner',{...input,revision});assert.equal(x.raw().tasks.find(t=>t.id===task.id).workIssueHistory.length,0);
 await assert.rejects(x.store.mutate('owner',{...input,revision,reason:'내용을 바꾸어 덮어쓰기'}),{code:'ISSUE_REQUEST_CHANGED'});
});
test('explicit null clears optional dishwashing place while omitted new fields retain links',async()=>{
 const x=fixture();await x.act('save_place',{place:{id:'dry',kind:'storage',name:'건조대',photo:''}});
 await x.act('save_manual_setup',{setup:{places:{dry:'dry'}}});
 await x.act('save_manual_setup',{setup:{places:{waste:null}}});assert.equal(x.raw().store.manualSetup.places.dry,'dry');
 await x.act('save_manual_setup',{setup:{places:{dry:null}}});assert.equal(x.raw().store.manualSetup.places.dry,null);
});
test('configuration changes retain an open routine exception and its displayed action snapshot',async()=>{
 const x=fixture();const {manualCatalog}=await import('../manual_market.mjs');
 let view=await x.act('import_market_taps',{sourceIds:['food/hall-open'],releaseId:manualCatalog.releaseId,operationId:'issue-composition-123',folderMode:'purpose'});let t=view.taskTemplates[0];
 view=await x.act('save_tap_settings',{templateId:t.id,assignmentScopeVersion:2,settings:{...t.settings,usage:'routine',enabled:true,assignment:{mode:'anyone'}}});const task=view.tasks.find(v=>v.templateId===t.id);assert.ok(task);
 await x.act('flag_work_issue',{taskId:task.id,reason:'사용하기 어려운 구역',severity:'blocked'});const original=structuredClone(x.raw().tasks.find(t=>t.id===task.id).steps);
 view=await x.act('save_manual_setup',{setup:{conditions:{selfbar:false}}});assert.ok(view.tasks.find(t=>t.id===task.id));assert.deepEqual(x.raw().tasks.find(t=>t.id===task.id).steps,original);
 await x.act('resolve_work_issue',{taskId:task.id,reason:'담당자 현장 조치'});assert.equal(x.raw().tasks.find(t=>t.id===task.id).workIssue.status,'resolved');
});
