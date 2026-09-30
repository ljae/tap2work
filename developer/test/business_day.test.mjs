import {test} from 'node:test';
import assert from 'node:assert/strict';
import {businessDate, actualDate} from '../business_day.mjs';
import {assignmentOccurrences, assignmentView} from '../work_assignments.mjs';
import {rosterTemplates,defaultWorkplace} from '../parts.mjs';
import {mutateWorkplace} from '../workplace.mjs';
const state=()=>({workplace:{...defaultWorkplace(),businessDayStart:'06:00',days:{3:[{id:'night',name:'야간',start:'22:00',end:'03:00',headcounts:{kitchen:1,hall:1},partTimes:{kitchen:{start:'01:00',end:'04:00'}}}]}},store:{profile:{}},tappers:[{id:'a',actorId:'a',nickname:'야간 크루',active:true}],staffShifts:[{id:'s',tapperId:'a',partId:'kitchen',timeBandId:'night',date:'2026-10-01',start:'01:00',end:'04:00',status:'planned'}]});
test('business midnight, boundary exact, year rollover and actual dates',()=>{
 const s=state();assert.equal(businessDate(s,'2026-10-01T05:59:59+09:00'),'2026-09-30');assert.equal(businessDate(s,'2026-10-01T06:00:00+09:00'),'2026-10-01');assert.equal(businessDate(s,'2027-01-01T01:00:00+09:00'),'2026-12-31');assert.equal(actualDate(s,'2026-09-30','01:00'),'2026-10-01');assert.equal(actualDate(s,'2026-09-30','06:00'),'2026-09-30');
});
test('part override preserves band ID, roster requirement and assignment actual interval',()=>{
 const s=state(),template={settings:{assignment:{mode:'scheduled',timeBandIds:['night'],partId:'kitchen'}},steps:[{id:'step'}]};
 const slots=rosterTemplates(s);assert.equal(slots.find(r=>r.partId==='kitchen').start,'01:00');assert.equal(slots.find(r=>r.partId==='hall').start,'22:00');assert.ok(slots.every(r=>r.bandId==='night'));
 const [occurrence]=assignmentOccurrences(s,template,'2026-09-30');const task={...template,...occurrence,date:'2026-09-30',businessDayStart:'06:00'};
 const v=assignmentView(s,task,task.steps[0],{id:'a'});assert.equal(v.isMine,true);assert.equal(v.assignees[0].startDate,'2026-10-01');assert.equal(v.assignees[0].end,'04:00');
 s.workplace.businessDayStart='00:00';assert.equal(assignmentView(s,task,task.steps[0],{id:'a'}).isMine,true);
});
test('anyone uses operational window, excludes crew after next boundary',()=>{
 const s=state();s.staffShifts.push({id:'late',tapperId:'a',partId:'kitchen',date:'2026-10-01',start:'06:00',end:'08:00',status:'planned'});
 const task={date:'2026-09-30',businessDayStart:'06:00',settings:{assignment:{mode:'anyone'}}};
 const v=assignmentView(s,task,null,{id:'a'});assert.equal(v.assignees.length,1);assert.equal(v.assignees[0].start,'01:00');
});
test('atomic hours saves validate boundary and per-part half-hours without mutating attendance/shifts',()=>{
 const s=state();s.attendance=[{at:'2026-10-01T01:02:00+09:00'}];const before=JSON.stringify([s.staffShifts,s.attendance]);const days=Object.fromEntries(Array.from({length:7},(_,i)=>[i+1,s.workplace.days[i+1]??[]]));
 assert.throws(()=>mutateWorkplace(s,{action:'save_workplace_hours',days,businessDayStart:'06:15'},{role:'owner'},new Date(),()=>{}));
 mutateWorkplace(s,{action:'save_workplace_hours',days,businessDayStart:'05:30'},{role:'owner'},new Date(),()=>{});assert.equal(s.workplace.businessDayStart,'05:30');assert.equal(JSON.stringify([s.staffShifts,s.attendance]),before);assert.equal(s.workplace.days[3][0].partTimes.kitchen.start,'01:00');
});

import {OperationsStore,emptyOperations} from '../operations.mjs';
test('API regenerates by business day, retains completed history and reapplies next-morning pattern without duplicates',async()=>{
 let now=new Date('2026-09-28T01:00:00Z');let data=emptyOperations(now,'owner');
 Object.assign(data,state());data.tappers[0].duties=[];data.tappers[0].workProfile={partIds:['kitchen']};data.staffShifts=[];
 data.taskTemplates=[{id:'daily',version:1,title:'공동',folderId:'general',requiredRole:'all',settings:{assignment:{mode:'anyone'}},steps:[{id:'s',title:'확인'}]}];
 const store=new OperationsStore(null,()=>now,{actor:{id:'owner',name:'owner',role:'owner'},persistence:{read:async()=>structuredClone(data),save:async(next)=>{data=structuredClone(next);}}});
 const act=async(action,fields)=>{const v=await store.snapshot();return store.mutate('owner',{revision:v.revision,action,...fields});};
 await act('save_crew_pattern',{tapperId:'a',cycleWeeks:1,anchor:'2026-09-28',entries:[{week:0,weekday:3,partId:'kitchen',timeBandId:'night',start:'01:00',end:'04:00'}]});
 await act('apply_crew_pattern',{tapperId:'a',from:'2026-09-30',until:'2026-09-30'});
 assert.equal(data.staffShifts.length,1);assert.equal(data.staffShifts[0].date,'2026-10-01');
 await act('apply_crew_pattern',{tapperId:'a',from:'2026-09-30',until:'2026-09-30'});assert.equal(data.staffShifts.length,1);
 now=new Date('2026-09-30T20:59:00Z');let view=await store.snapshot();assert.equal(view.day,'2026-09-30');assert.equal(view.staffShifts[0].businessDate,'2026-09-30');
 const task=view.tasks.find(t=>t.templateId==='daily');assert.equal(task.assignmentView.assignees[0].id,'a');
 await act('complete_task',{taskId:task.id});const completed=structuredClone(data.tasks.find(t=>t.id===task.id));
 now=new Date('2026-09-30T21:00:00Z');view=await store.snapshot();assert.equal(view.day,'2026-10-01');assert.deepEqual(data.tasks.find(t=>t.id===task.id),completed);assert.notEqual(view.tasks.find(t=>t.templateId==='daily').id,task.id);
});
