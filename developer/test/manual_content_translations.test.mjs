import {test} from 'node:test';
import assert from 'node:assert/strict';
import {OperationsStore,seedOperations} from '../operations.mjs';
import {saveManualTranslation,manualTranslationView} from '../manual_content_translations.mjs';
const now=new Date('2026-10-10T05:00:00Z'),owner={id:'owner',role:'owner'};
function fixture(){return {taskTemplates:[{id:'manual-1',title:'매뉴얼',steps:[{id:'a',title:'행동',manual:'방법',tip:'팁'}]}],workplace:{restrictions:{manager:{tasks:true}}}};}
const input=(fields,locale='vi')=>({source:{kind:'manual',id:'manual-1'},locale,fields});
const field=(field,sourceText,text,stepId)=>({field,sourceText,text,...(stepId?{stepId}:{})});
test('store-entered translations invalidate only changed fields and sanitize editor identity for crew',()=>{
 const state=fixture();saveManualTranslation(state,input([field('title','매뉴얼','Manual'),field('title','행동','Action','a'),field('manual','방법','Method','a'),field('tip','팁','Tip','a')]),owner,now);
 state.taskTemplates[0].steps[0].manual='바뀐 방법';
 const view=manualTranslationView(state).manuals['manual-1'].vi;
 assert.equal(view.title.current,true);assert.equal(view.steps.a.title.current,true);assert.equal(view.steps.a.tip.current,true);assert.equal(view.steps.a.manual.current,false);
 assert.equal(view.steps.a.manual.text,'Method');assert.equal(view.title.updatedBy,undefined);assert.equal(view.title.updatedAt,undefined);
 saveManualTranslation(state,input([field('manual','바뀐 방법','Updated method','a')]),owner,now);
 assert.equal(manualTranslationView(state).manuals['manual-1'].vi.steps.a.manual.current,true);
 assert.equal(manualTranslationView(state).manuals['manual-1'].vi.steps.a.tip.text,'Tip');
});
test('manual import is atomic with exact source, supported locales and role permissions',()=>{
 const state=fixture();const rows=[field('title','매뉴얼','Manual'),field('manual','stale','Method','a')];
 assert.throws(()=>saveManualTranslation(state,input(rows),owner,now),{status:409});assert.equal(state.manualContentTranslations,undefined);
 for(const role of ['crew','cook'])assert.throws(()=>saveManualTranslation(state,input([rows[0]]),{id:role,role},now),{status:403});
 state.workplace.restrictions.manager.tasks=false;assert.throws(()=>saveManualTranslation(state,input([rows[0]]),{id:'manager',role:'manager'},now),{status:403});
 assert.throws(()=>saveManualTranslation(state,input([rows[0]],'fr'),owner,now),{status:400});
 assert.throws(()=>saveManualTranslation(state,input([rows[0],rows[0]]),owner,now),{status:400});
 assert.throws(()=>saveManualTranslation(state,input([field('manual','방법','','a')]),owner,now),{status:400});
});
test('welcome supports independent title/body translations in all eight guide languages',()=>{
 const state=fixture();state.welcome={title:'환영',body:'안내',sourceLocale:'ko',revision:1,importantRevision:1};
 for(const locale of ['ko','en','vi','zh-Hans','ja','th','ne','id'])saveManualTranslation(state,{source:{kind:'welcome'},locale,fields:[field('title','환영','Welcome'),field('body','안내','Guide')]},owner,now);
 state.welcome.body='새 안내';const view=manualTranslationView(state).welcome;
 for(const locale of Object.keys(view)){assert.equal(view[locale].title.current,true);assert.equal(view[locale].body.current,false);}
});
test('translation save uses normal operation CAS and shared read without changing IDs or completion',async()=>{
 let data=seedOperations(now);const make=role=>new OperationsStore(null,()=>now,{actor:{id:role,role,name:role},persistence:{read:async()=>structuredClone(data),save:async next=>{data=next;}}});
 const store=make('owner'),crew=make('crew');let view=await store.snapshot();const template=view.taskTemplates[0],before=view.tasks.map(t=>[t.id,t.completedAt,(t.steps??[]).map(s=>[s.id,s.completedAt])]);
 const payload={action:'save_manual_translation',revision:view.revision,source:{kind:'manual',id:template.id},locale:'vi',fields:[field('title',template.manualTitle??template.title,'Translated title')]};
 view=await store.mutate(null,payload);const shared=await crew.snapshot();assert.equal(shared.manualContentTranslations.manuals[template.id].vi.title.text,'Translated title');
 assert.deepEqual(view.tasks.map(t=>[t.id,t.completedAt,(t.steps??[]).map(s=>[s.id,s.completedAt])]),before);
 await assert.rejects(store.mutate(null,payload),{status:409});
});
