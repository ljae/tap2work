import { test } from 'node:test';
import assert from 'node:assert/strict';
import { OperationsStore, seedOperations } from '../operations.mjs';
import { eraseMemberData } from '../account_erasure.mjs';
const now = new Date('2026-10-10T05:00:00Z');
function fixture() {
  let state = seedOperations(now);
  const store = (role = 'owner', id = role) => new OperationsStore(null, () => now, { actor: { id, role, name: role }, persistence: { read: async () => structuredClone(state), save: async next => { state = structuredClone(next); } } });
  return { store, state: () => state };
}
test('welcome is shared, acknowledgments private, routine edits do not re-prompt but important edits do', async () => {
  const x = fixture(), owner = x.store(), crew = x.store('crew');
  let view = await crew.snapshot();
  assert.equal(view.welcomeNeedsAcknowledgment,true);
  view = await crew.mutate(null,{action:'ack_welcome',revision:view.revision,welcomeRevision:view.welcome.revision,actorId:'owner'});
  assert.equal(view.welcomeNeedsAcknowledgment,false);
  let admin = await owner.snapshot();
  assert.equal(admin.welcomeAcknowledgment,null);
  const save = important => owner.mutate(null,{action:'save_welcome',revision:admin.revision,welcome:{title:'매장 공통 안내',body:'모든 크루가 함께 확인해요',sourceLocale:'ko'},important});
  admin = await save(false);
  view = await crew.snapshot(); assert.deepEqual(view.welcome,admin.welcome); assert.equal(view.welcomeNeedsAcknowledgment,false);
  admin = await save(true);
  view = await crew.snapshot(); assert.equal(view.welcomeNeedsAcknowledgment,true);
  assert.equal(view.welcomeAcknowledgments,undefined); assert.equal(view.actorPreferences,undefined);
  await assert.rejects(crew.mutate(null,{action:'ack_welcome',revision:view.revision,welcomeRevision:1}),error => error.status===409);
  await assert.rejects(owner.mutate(null,{action:'save_welcome',revision:view.revision-1,welcome:{title:'overwrite',body:'old'}}),error => error.status===409);
});
test('welcome editing follows task permission while every actor can save only their own supported language', async () => {
  const x=fixture(); let state=await x.store().snapshot();
  for (const role of ['crew','cook']) await assert.rejects(x.store(role).mutate(null,{action:'save_welcome',revision:state.revision,welcome:{title:'x',body:'y'}}),error=>error.status===403);
  x.state().workplace.restrictions.manager={tasks:false};
  await assert.rejects(x.store('manager').mutate(null,{action:'save_welcome',revision:state.revision,welcome:{title:'x',body:'y'}}),error=>error.status===403);
  const owner=x.store('owner','owner-no-crew');
  for(const locale of ['ko','en','vi','zh-Hans','ja','th','ne','id']) {
    state=await owner.snapshot();state=await owner.mutate(null,{action:'save_language_preference',revision:state.revision,locale,actorId:'crew'});
    assert.equal(state.languageContext.effectiveLocale,locale);assert.equal(x.state().actorPreferences.crew,undefined);
  }
  await assert.rejects(owner.mutate(null,{action:'save_language_preference',revision:state.revision,locale:'xx'}),error=>error.status===400);
});
test('crew sees shared read-only manual contents and shared progress with private configuration omitted',async()=>{
 const x=fixture(),owner=await x.store().snapshot(),crew=await x.store('crew').snapshot();
 assert.ok(crew.taskTemplates.length);assert.equal(crew.canEditTasks,false);assert.equal(crew.checklistBackup,undefined);assert.equal(crew.manualCatalog,undefined);
 const template=crew.taskTemplates[0],same=owner.taskTemplates.find(t=>t.id===template.id);
 assert.equal(template.title,same.title);assert.equal(template.steps[0].manual,same.steps[0].manual);assert.equal(template.settings.completionPolicy,undefined);assert.equal(template.assignmentSnapshot,undefined);
 assert.deepEqual(crew.tasks.map(t=>[t.id,t.completedAt]),owner.tasks.map(t=>[t.id,t.completedAt]));
});
test('account erasure deletes actor preference and welcome acknowledgement object keys',()=>{
 const result=eraseMemberData({tappers:[],actorPreferences:{user:{locale:'vi'},other:{locale:'ja'}},welcomeAcknowledgments:{user:{revision:2},other:{revision:1}}},{id:'user'});
 assert.deepEqual(result.actorPreferences,{other:{locale:'ja'}});assert.deepEqual(result.welcomeAcknowledgments,{other:{revision:1}});
});
