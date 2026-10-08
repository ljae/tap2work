import test from 'node:test';
import assert from 'node:assert/strict';
import {OperationsStore,emptyOperations} from '../operations.mjs';
import {manualCatalog} from '../manual_market.mjs';
import {workEligibility,workStatus} from '../knowledge_work.mjs';
const now=new Date('2026-10-08T03:00:00Z');
function fixture(){
 let date=now, state=emptyOperations(now,'owner','사장님');
 const actor={id:'owner',name:'사장님',role:'owner'};
 const store=new OperationsStore(null,()=>date,{actor,persistence:{read:async()=>structuredClone(state),save:async next=>{state=structuredClone(next);}}});
 const act=async(action,input={})=>{const view=await store.snapshot();return store.mutate('owner',{action,revision:view.revision,...input});};
 const importSource=async source=>{await act('import_market_taps',{sourceIds:[source],releaseId:manualCatalog.releaseId,operationId:`import-${source.replaceAll('/','-')}`,folderMode:'purpose'});return state.taskTemplates.find(t=>state.catalogLinks[t.id]?.sourceId===source);};
 return {store,act,importSource,raw:()=>state,next:()=>date=new Date(date.getTime()+86400000)};
}
test('common break is menu/time independent and old mixed source has replacements',()=>{
 const common=manualCatalog.entries.find(e=>e.sourceId==='common/break-service');
 assert.equal(common.knowledge.scope,'universal');assert.doesNotMatch(JSON.stringify(common.steps),/등뼈|14:00|16:00/);
 assert.equal(manualCatalog.entries.find(e=>e.sourceId==='bonejjim/break').knowledge.supersededBy.length,3);
});
test('reference, missing configuration and no-break day are distinct; existing implicit enabled still runs',()=>{
 const state=emptyOperations(now,'owner','사장님');
 const base={id:'test',steps:[{id:'s'}],slot:'준비'};
 assert.equal(workEligibility(state,base,'2026-10-08')[0],'ready');
 assert.equal(workEligibility(state,{...base,settings:{enabled:false}},'2026-10-08')[0],'unclassified');
 assert.equal(workEligibility(state,{...base,settings:{usage:'reference',enabled:false}},'2026-10-08')[0],'reference');
 assert.equal(workEligibility(state,{...base,slot:'브레이크'},'2026-10-08')[0],'waiting');
 assert.equal(workStatus(state,base,'2026-10-08').code,'missing');
});
test('event requires store standard, generates once, keeps different batches and snapshots, requires evidence',async()=>{
 const x=fixture(), t=await x.importSource('process/broth-storage');
 const settings={...t.settings,usage:'event',eventKind:'batch',assignment:{mode:'anyone'}};
 await assert.rejects(x.act('save_tap_settings',{templateId:t.id,assignmentScopeVersion:2,settings}),/매장 기준/);
 await x.act('save_tap_settings',{templateId:t.id,assignmentScopeVersion:2,settings:{...settings,operatingStandard:'제품 지침과 검증된 매장 냉각 기준을 확인하고 실제 측정값 기록'}});
 const input={templateId:t.id,requestId:'batch-first-123',subject:'오전 1차'};
 const view=await x.act('start_manual_work',input);
 await x.store.mutate('owner',{action:'start_manual_work',revision:0,...input});
 assert.equal(x.raw().tasks.filter(t=>t.workEvent).length,1);
 await assert.rejects(x.act('start_manual_work',{...input,subject:'오후'}),/내용이 달라/);
 await x.act('start_manual_work',{...input,requestId:'batch-second-123',subject:'오전 2차'});
 const task=view.tasks.find(t=>t.workEvent);
 await assert.rejects(x.act('complete_task',{taskId:task.id}),/하나씩/);
 await assert.rejects(x.act('complete_step',{taskId:task.id,stepId:'step-1'}),/기록/);
 await x.act('complete_step',{taskId:task.id,stepId:'step-1',evidence:'10:00 시작, 제품과 배치 확인'});
 assert.equal(x.raw().tasks.find(t=>t.id===task.id).steps[0].evidence.value,'10:00 시작, 제품과 배치 확인');
 x.next();assert.equal((await x.store.snapshot()).tasks.filter(t=>t.workEvent).length,2);
 await x.act('complete_step',{taskId:task.id,stepId:'step-2',evidence:'매장 기준의 측정 시점과 결과 확인'});
 assert.equal(x.raw().tasks.find(t=>t.id===task.id).date,'2026-10-08');
});
test('new scheduled knowledge shows only on break days and references do not generate work',async()=>{
 const x=fixture(),t=await x.importSource('common/break-service');
 await x.act('save_tap_settings',{templateId:t.id,assignmentScopeVersion:2,settings:{...t.settings,usage:'routine'}});
 assert.equal((await x.store.snapshot()).tasks.some(task=>task.templateId===t.id),false);
 await x.act('save_tap_settings',{templateId:t.id,assignmentScopeVersion:2,settings:{...t.settings,usage:'reference'}});
 assert.equal((await x.store.snapshot()).taskTemplates.find(v=>v.id===t.id).workStatus.code,'reference');
});
test('explicit split reuses installed common knowledge and preserves original history',async()=>{
 const x=fixture(),old=await x.importSource('bonejjim/break');
 await x.importSource('common/break-service');
 const input={templateId:old.id,operationId:'split-user-request-123',releaseId:manualCatalog.releaseId};
 await x.act('replace_mixed_break',input);
 await x.store.mutate('owner',{action:'replace_mixed_break',revision:0,...input});
 assert.ok(x.raw().taskTemplates.find(t=>t.id===old.id).archivedAt);
 assert.equal(x.raw().catalogHistory.find(h=>h.kind==='split-break').template.steps.length,5);
 assert.equal(x.raw().taskTemplates.filter(t=>!t.archivedAt&&x.raw().catalogLinks[t.id]?.sourceId==='common/break-service').length,1);
});
test('metadata survives editing and linked knowledge stays frozen in event snapshots',async()=>{
 const x=fixture(), t=await x.importSource('process/broth-storage'),ref=await x.importSource('common/prep');
 await x.act('save_tap_settings',{templateId:t.id,assignmentScopeVersion:2,settings:{...t.settings,usage:'event',eventKind:'batch',assignment:{mode:'anyone'},operatingStandard:'매장에 확인된 냉각·보관 기준을 적용하고 기록',knowledgeIds:[ref.id]}});
 await x.act('start_manual_work',{templateId:t.id,requestId:'snapshot-batch-123',subject:'배치1'});
 const task=x.raw().tasks.find(t=>t.workEvent),original=task.knowledgeSnapshots[0].title;
 await x.act('save_manual_tap',{templateId:ref.id,operationId:'edit-reference-123',title:'바뀐 제목',emoji:ref.emoji,folderId:ref.folderId,steps:ref.steps});
 assert.equal(x.raw().tasks.find(t=>t.workEvent).knowledgeSnapshots[0].title,original);
 assert.equal(x.raw().taskTemplates.find(t=>t.id===ref.id).knowledge.scope,'food');
});
test('exceptions block completion until an explicit manager resolution',async()=>{
 const x=fixture(),t=await x.importSource('bonejjim/evening-prep');
 await x.act('save_tap_settings',{templateId:t.id,assignmentScopeVersion:2,settings:{...t.settings,usage:'event',eventKind:'batch',operatingStandard:'제품별 매장 전처리·보관 기준 확인'}});
 const view=await x.act('start_manual_work',{templateId:t.id,requestId:'issue-batch-123',subject:'저녁 준비'}),task=view.tasks.find(t=>t.workEvent);
 await x.act('flag_work_issue',{taskId:task.id,reason:'보관 이력 확인 불가, 사용 보류'});
 await assert.rejects(x.act('complete_step',{taskId:task.id,stepId:'step-1',evidence:'확인'}),/조치/);
 await x.act('resolve_work_issue',{taskId:task.id,reason:'대상 식품 폐기 확인, 새 배치 준비'});
 assert.equal(x.raw().tasks.find(t=>t.id===task.id).workIssue.status,'resolved');
});
test('invalid event requests and quantity-only policies fail explicitly',async()=>{
 const x=fixture(),t=await x.importSource('common/prep');
 await assert.rejects(x.act('start_manual_work',{templateId:t.id,subject:'x'}),{status:400});
 await assert.rejects(x.act('save_tap_settings',{templateId:t.id,assignmentScopeVersion:2,settings:{...t.settings,usage:'event',eventKind:'batch',completionPolicy:{kind:'quantity',quantitySpec:{unit:'개',decimalPlaces:0,target:null}}}}),/항목별/);
});
test('personalizing a safety manual preserves its review requirement and starts as reference',async()=>{
 const x=fixture(),t=await x.importSource('process/rice-cake-storage');
 await x.act('personalize_market_tap',{templateId:t.id,operationId:'personalize-safety-123'});
 const copy=x.raw().taskTemplates.find(v=>v.id!==t.id&&x.raw().catalogLinks[v.id]?.mode==='personalized');
 assert.equal(copy.knowledge.safetyReviewRequired,true);assert.equal(copy.settings.usage,'reference');
 await assert.rejects(x.act('save_tap_settings',{templateId:copy.id,assignmentScopeVersion:2,settings:{...copy.settings,usage:'event',eventKind:'opened'}}),/매장 기준/);
});
