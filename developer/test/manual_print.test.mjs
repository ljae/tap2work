import {test} from 'node:test';
import assert from 'node:assert/strict';
import {OperationsStore,emptyOperations} from '../operations.mjs';
import {printSourceHash,manualPrintView} from '../manual_print.mjs';
import {defaultWorkplace} from '../parts.mjs';
import {sectionPatch} from '../section_storage.mjs';
const now=new Date('2026-10-05T01:00:00Z');
function fixture(role='owner',restricted=false){
 let state=emptyOperations(now,'owner','Owner');
 state.taskTemplates=[{id:'print-tap',title:'준비',emoji:'',folderId:'general',version:1,slot:'준비',requiredRole:'all',partId:'kitchen',zone:null,settings:{enabled:false},steps:[{id:'s1',title:'손 씻기',manual:'손을 씻어요.',tip:'물기 제거'}]}];
 state.workplace=defaultWorkplace();
 if(restricted)state.workplace.restrictions.manager={tasks:false};
 const actor={id:role,role,name:role};
 const store=new OperationsStore(null,()=>now,{actor,persistence:{read:async()=>structuredClone(state),save:async(next,rev)=>{assert.equal(rev,state.revision);state=structuredClone(next);}}});
 return {store,actor,raw:()=>state,change:fn=>fn(state),view:()=>store.snapshot(actor.id)};
}
const body=(v,locale='en')=>({action:'save_manual_print_translation',revision:v.revision,templateId:'print-tap',sourceHash:v.manualPrintTemplates[0].sourceHash,locale,title:'Preparation',steps:[{id:'s1',title:'Wash hands',manual:'Wash your hands.',tip:'Dry your hands.'}]});
test('print translation persists separately, preserves definitions and executions, and invalidates after source content changes',async()=>{
 const x=fixture(),v=await x.view(),before=structuredClone(x.raw());
 const result=await x.store.mutate(x.actor.id,body(v));
 assert.deepEqual(x.raw().taskTemplates,before.taskTemplates);assert.deepEqual(x.raw().tasks,before.tasks);
 assert.equal(result.manualPrintTranslations,undefined);
 const source=result.manualPrintTemplates[0];assert.equal(source.translations.en.sourceHash,source.sourceHash);
 assert.deepEqual(Object.keys(sectionPatch(before,x.raw()).changes).sort(),['activity','manualPrintTranslations']);
 x.change(s=>s.taskTemplates[0].steps[0].manual='새 방법');
 const changed=await x.view();assert.notEqual(changed.manualPrintTemplates[0].sourceHash,source.translations.en.sourceHash);
 await assert.rejects(()=>x.store.mutate(x.actor.id,{...body(changed),sourceHash:source.sourceHash}),/원문이 변경/);
});
test('five print locales, content completeness, stale revision, and permissions are validated',async()=>{
 for(const locale of ['en','vi','zh-Hans','ja']){const x=fixture();const v=await x.view();const result=await x.store.mutate(x.actor.id,body(v,locale));assert.ok(result.manualPrintTemplates[0].translations[locale]);}
 const x=fixture(),v=await x.view();
 for(const patch of [{locale:'xx'},{steps:[]},{steps:[{id:'s1',title:'A',manual:'',tip:''}]},{steps:[{id:'unknown',title:'A',manual:'B',tip:'C'}]},{title:'x'.repeat(101)}])await assert.rejects(()=>x.store.mutate(x.actor.id,{...body(v),...patch}));
 await assert.rejects(()=>x.store.mutate(x.actor.id,{...body(v),revision:v.revision-1}),/먼저 업데이트/);
 for(const [role,restricted] of [['cook',false],['manager',true]]){const y=fixture(role,restricted),v=await y.view();await assert.rejects(()=>y.store.mutate(y.actor.id,body(v)),e=>e.status===403);}
});
test('source identity excludes layout and policies but includes manual aliases and links; archived manuals not exposed',()=>{
 const t={id:'x',title:'원래 이름',manualTitle:'표시 이름',steps:[{id:'a',title:'작업',manual:'방법',tip:''}]};
 const hash=printSourceHash(t);assert.equal(printSourceHash({...t,folderId:'other',zone:'z',settings:{enabled:true}}),hash);
 assert.notEqual(printSourceHash({...t,manualTitle:'변경'}),hash);
 assert.notEqual(printSourceHash({...t,steps:[{...t.steps[0],sourceUrl:'https://example.com'}]}),hash);
 const state={taskTemplates:[t,{...t,id:'archived',archivedAt:'today'}],checklistFolders:[],manualPrintTranslations:{archived:{en:{title:'old'}}}};
 assert.equal(manualPrintView(state).length,1);
});
