import {test} from 'node:test';
import assert from 'node:assert/strict';
import {mkdtemp,rm} from 'node:fs/promises';
import {tmpdir} from 'node:os';
import path from 'node:path';
import {OperationsStore} from '../operations.mjs';
async function setup(t){const dir=await mkdtemp(path.join(tmpdir(),'direct-edit-'));t.after(()=>rm(dir,{recursive:true,force:true}));const store=new OperationsStore(path.join(dir,'state.json'),()=>new Date('2026-09-28T03:00:00Z'));return {store,act:async(action,values={},actor='owner')=>store.mutate(actor,{action,revision:(await store.snapshot(actor)).revision,...values})};}
test('direct work rename/delete persists source, protects completion, stale and unauthorized edits',async t=>{
 const {store,act}=await setup(t);let s=await store.snapshot('owner');const task=s.tasks.find(t=>t.templateId&&t.steps.length>1&&!t.orderId&&!t.preparedItemId);const [first,second]=task.steps;
 s=await act('edit_work_node',{taskId:task.id,stepId:first.id,operation:'rename',name:'새 작업'});
 assert.equal(s.tasks.find(t=>t.id===task.id).steps[0].title,'새 작업');assert.equal(s.taskTemplates.find(t=>t.id===task.templateId).steps[0].title,'새 작업');
 await assert.rejects(store.mutate('owner',{action:'edit_work_node',revision:s.revision-1,taskId:task.id,operation:'delete'}),{status:409});
 await assert.rejects(act('edit_work_node',{taskId:task.id,operation:'rename',name:'bad'},'crew'),{status:403});
 await act('complete_step',{taskId:task.id,stepId:first.id});
 await assert.rejects(act('edit_work_node',{taskId:task.id,stepId:first.id,operation:'delete'}),{status:409});
 await assert.rejects(act('edit_work_node',{taskId:task.id,operation:'delete'}),{status:400});
 s=await act('edit_work_node',{taskId:task.id,stepId:second.id,operation:'delete'});
 assert.ok(!s.tasks.find(t=>t.id===task.id).steps.some(x=>x.id===second.id));assert.ok(s.tasks.find(t=>t.id===task.id).steps[0].completedAt);assert.equal(s.operationEditHistory,undefined);
});
test('manual rename/delete/add is scoped to definitions and prevents orphaned folders',async t=>{
 const {store,act}=await setup(t);const before=await store.snapshot('owner');const template=before.taskTemplates.find(t=>!t.menuManualId);
 let s=await act('edit_manual_node',{kind:'tap',id:template.id,operation:'rename',name:'변경된 TAP'});
 assert.deepEqual(s.tasks,before.tasks);assert.equal(s.taskTemplates.find(t=>t.id===template.id).title,'변경된 TAP');
 await assert.rejects(act('edit_manual_node',{kind:'group',id:template.folderId,operation:'delete'}),{status:400});
 s=await act('edit_manual_node',{kind:'group',operation:'add',name:'새 그룹'});const folder=s.checklistFolders.find(f=>f.name==='새 그룹');
 s=await act('edit_manual_node',{kind:'tap',parentId:folder.id,operation:'add',name:'새 TAP'});const tap=s.taskTemplates.find(t=>t.title==='새 TAP');assert.equal(tap.steps.length,0);
 assert.ok(!s.tasks.some(t=>t.templateId===tap.id));
 s=await act('edit_manual_node',{kind:'task',parentId:tap.id,operation:'add',name:'첫 Task'});
 const step=s.taskTemplates.find(t=>t.id===tap.id).steps[0];
 const executions=structuredClone(s.tasks);
 s=await act('edit_manual_node',{kind:'task',parentId:tap.id,id:step.id,operation:'delete'});
 assert.deepEqual(s.taskTemplates.find(t=>t.id===tap.id).steps,[]);assert.deepEqual(s.tasks,executions);
 s=await act('edit_manual_node',{kind:'tap',id:tap.id,operation:'rename',name:'빈 TAP'});
 assert.equal(s.taskTemplates.find(t=>t.id===tap.id).title,'빈 TAP');
 await act('edit_manual_node',{kind:'tap',id:tap.id,operation:'delete'});s=await act('edit_manual_node',{kind:'group',id:folder.id,operation:'delete'});assert.ok(!s.checklistFolders.some(f=>f.id===folder.id));
});
test('role restrictions remove projected edit permission and reject all direct mutations',async t=>{
 const {store,act}=await setup(t);
 await act('save_workplace_permissions',{role:'manager',permissions:{tasks:false,schedule:false}});
 const s=await store.snapshot('manager');assert.equal(s.canEditTasks,false);assert.equal(s.canEditSchedule,false);
 for(const action of ['edit_work_node','edit_manual_node','delete_roster_slot','save_staff_shift'])await assert.rejects(act(action,{},'manager'),{status:403});
});
test('roster labels and per-date deletion preserve crew and original hours, reset restores requirement',async t=>{
 const {store,act}=await setup(t);let s=await act('save_workplace_day',{weekday:1,bands:[{name:'오픈',start:'09:00',end:'14:00'}]});const template=s.rosterTemplates.find(r=>r.weekday===1);const ref={date:'2026-09-28',partId:template.partId,templateId:template.id};
 s=await act('save_roster_slot',{...ref,name:'지원 근무',start:'10:00',end:'15:00'});assert.equal(s.rosterOverrides.find(r=>r.templateId===template.id).name,'지원 근무');
 s=await act('delete_roster_slot',ref);assert.equal(s.rosterOverrides.find(r=>r.templateId===template.id).hidden,true);assert.equal(s.rosterTemplates.find(r=>r.id===template.id).start,'09:00');
 s=await act('reset_roster_slot',ref);assert.ok(!s.rosterOverrides.some(r=>r.templateId===template.id));
 const old=s.staffShifts[0];const crew=s.tappers.find(r=>r.id===old.tapperId);s=await act('save_staff_shift',{...old,label:'마감 지원'});
 assert.equal(s.staffShifts.find(r=>r.id===old.id).label,'마감 지원');assert.equal(s.tappers.find(r=>r.id===crew.id).nickname,crew.nickname);
});

test('menu manual aliases preserve sales names through body save and catalog sync',async t=>{
 const {store,act}=await setup(t);let s=await store.snapshot('owner');
 const template=s.taskTemplates.find(t=>t.menuManualId);assert.ok(template);
 const step=template.steps[0], menus=structuredClone(s.catalogMenus);
 s=await act('edit_manual_node',{kind:'tap',id:template.id,operation:'rename',name:'조리 가이드'});
 s=await act('edit_manual_node',{kind:'task',parentId:template.id,id:step.id,operation:'rename',name:'완성 순서'});
 const check=()=>{const tap=s.taskTemplates.find(t=>t.id===template.id);assert.equal(tap.title,template.title);assert.equal(tap.steps[0].title,step.title);assert.equal(tap.manualTitle,'조리 가이드');assert.equal(tap.steps[0].manualTitle,'완성 순서');const row=s.manualSearch.find(r=>r.id===`${template.id}/${step.id}`);assert.equal(row.tapTitle,'조리 가이드');assert.equal(row.title,'완성 순서');assert.deepEqual(s.catalogMenus,menus);};
 check();
 const templates=structuredClone(s.taskTemplates);const edited=templates.find(t=>t.id===template.id);
 delete edited.manualTitle;delete edited.steps[0].manualTitle;edited.steps[0].manual='매뉴얼 내용 수정';
 s=await act('save_checklists',{folders:s.checklistFolders,templates});check();
 s=await store.snapshot('owner');check();
 const menu=menus.find(m=>m.id===template.menuManualId);
 s=await act('save_menu',{...menu,name:'판매 메뉴 새 이름'});
 const synced=s.taskTemplates.find(t=>t.id===template.id);assert.equal(synced.title,'판매 메뉴 새 이름');assert.equal(synced.manualTitle,'조리 가이드');assert.equal(synced.steps[0].manualTitle,'완성 순서');
 assert.equal(s.manualSearch.find(r=>r.id===`${template.id}/${step.id}`).title,'완성 순서');
 await assert.rejects(act('edit_manual_node',{kind:'tap',id:template.id,operation:'delete'}),{status:400});
 await assert.rejects(act('edit_manual_node',{kind:'tap',id:template.id,operation:'rename',name:'권한 없음'},'crew'),{status:403});
});
