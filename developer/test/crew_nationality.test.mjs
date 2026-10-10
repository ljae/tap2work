import {test} from 'node:test';
import assert from 'node:assert/strict';
import {OperationsStore,seedOperations} from '../operations.mjs';
import {nationalityCodes,nationalityOptions,validNationality} from '../countries.mjs';
const now=new Date('2026-10-10T05:00:00Z');
function fixture(){let state=seedOperations(now);const store=role=>new OperationsStore(null,()=>now,{actor:{id:role,role,name:role},persistence:{read:async()=>structuredClone(state),save:async next=>{state=next;}}});return {store,state:()=>state};}
const values={nickname:'새 크루',rank:'crew',hourlyWon:10320,payPeriod:'monthly',nationality:'VN',guideLocale:'en'};
test('new crew requires real nationality and separately selected language; old missing data stays missing',async()=>{
 const x=fixture(),owner=x.store('owner');let view=await owner.snapshot();
 for(const patch of [{nationality:undefined},{nationality:'XX'},{nationality:'UK'},{guideLocale:undefined},{guideLocale:'fr'}])await assert.rejects(owner.mutate(null,{action:'save_tapper',revision:view.revision,...values,...patch}),{status:400});
 view=await owner.mutate(null,{action:'save_tapper',revision:view.revision,...values});const added=view.tappers.find(t=>t.nickname===values.nickname);assert.equal(added.nationality,'VN');assert.equal(added.guideLocale,'en');
 const old=view.tappers.find(t=>t.actorId==='crew');const {nationality,guideLocale,...oldFields}=values;
 view=await owner.mutate(null,{action:'save_tapper',revision:view.revision,...oldFields,id:old.id});assert.equal(view.tappers.find(t=>t.id===old.id).nationality,undefined);assert.equal(view.tappers.find(t=>t.id===old.id).guideLocale,undefined);
});
test('owner seed never overrides personal guide choice; nationality visible owner/self only',async()=>{
 const x=fixture(),owner=x.store('owner'),crew=x.store('crew');let view=await owner.snapshot();const person=view.tappers.find(t=>t.actorId==='crew');
 view=await owner.mutate(null,{action:'save_tapper',revision:view.revision,...values,id:person.id});assert.equal(x.state().actorPreferences.crew.locale,'en');
 let mine=await crew.snapshot();assert.equal(mine.tappers.find(t=>t.id===person.id).nationality,'VN');assert.equal(mine.languageContext.effectiveLocale,'en');
 mine=await crew.mutate(null,{action:'save_language_preference',revision:mine.revision,locale:'ja'});
 view=await owner.mutate(null,{action:'save_tapper',revision:mine.revision,...values,guideLocale:'vi',id:person.id});assert.equal(x.state().actorPreferences.crew.locale,'ja');
 mine=await crew.snapshot();assert.equal(mine.languageContext.effectiveLocale,'ja');assert.equal(mine.nationalityOptions,undefined);
 const manager=await x.store('manager').snapshot();assert.equal(manager.tappers.find(t=>t.id===person.id).nationality,undefined);assert.equal(manager.tappers.find(t=>t.id===person.id).guideLocale,undefined);
 assert.equal(view.nationalityOptions.length,249);assert.equal(view.nationalityOptions[0].code,'KR');
});
test('country selection contains ISO249 stable codes and localized display names, with no nationality-to-language inference',()=>{
 assert.equal(new Set(nationalityCodes).size,249);assert.equal(validNationality('KR'),true);assert.equal(validNationality('ZZ'),false);assert.equal(validNationality('kr'),false);
 assert.equal(nationalityOptions('en').find(c=>c.code==='VN').name,'Vietnam');assert.equal(nationalityOptions('ko').find(c=>c.code==='VN').name,'베트남');
});
