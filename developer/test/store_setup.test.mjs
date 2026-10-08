import test from 'node:test';
import assert from 'node:assert/strict';
import {emptyOperations,OperationsStore} from '../operations.mjs';
import {applyStoreSetup,storeSetupCatalog} from '../store_setup.mjs';
import {saveStoreProfile} from '../store_profile.mjs';
import {manualCatalog} from '../manual_market.mjs';
const now=new Date('2026-10-08T04:00:00Z');
const actor={id:'owner',name:'사장님',role:'owner'};
const catalog=storeSetupCatalog();
const setup=(overrides={})=>({businessTypeId:'chicken',serviceModes:['takeout','delivery'],weekdays:[1,2,3,4,5],opening:'19:00',closing:'02:00',partIds:['kitchen','management'],headcounts:{kitchen:2,management:1},shiftCount:2,breakTime:{start:'23:00',end:'23:30'},pos:'okpos',deliveryPlatforms:['baemin'],releaseId:catalog.releaseId,sourceIds:['common/prep','chicken/prep','delivery/open'],enableOperations:false,...overrides});
function create(values=setup(), release=manualCatalog){const state=emptyOperations(now,actor.id);applyStoreSetup(state,{name:'새 매장',requestId:'test-new-store',setup:values},actor,now,release);return state;}
test('registration shares hours, overnight shift, staffing and manual source contracts',async()=>{
 const state=create();
 assert.equal(state.store.profile.businessTypeId,'chicken');
 assert.equal(state.store.profile.industryId,'restaurant');
 assert.equal(state.store.profile.hours,undefined);
 assert.equal(state.store.profile.staffing,undefined);
 assert.equal(state.workplace.days[1][0].start,'19:00');
 assert.equal(state.workplace.days[1][1].end,'02:00');
 assert.equal(state.workplace.days[1][0].end,state.workplace.days[1][1].start);
 assert.deepEqual(state.workplace.days[6],[]);
 assert.deepEqual(state.workplace.breaks[1],{start:'23:00',end:'23:30'});
 assert.deepEqual(state.workplace.days[1][1].headcounts,{kitchen:2,management:1});
 assert.equal(state.workplace.parts.find(p=>p.id==='hall').hidden,true);
 assert.equal(state.tappers.length,1); assert.equal(state.staffShifts.length,0);
 assert.equal(state.taskTemplates.length,3);
 assert.ok(state.taskTemplates.every(t=>!t.settings.enabled&&t.steps.length));
 assert.equal(Object.keys(state.catalogLinks).length,3);
 assert.ok(!state.checklistFolders.some(f=>f.id==='general'));
 assert.equal(state.manualBusinessProfile.specialization,'치킨');
 const store=new OperationsStore(null,()=>now,{actor,persistence:{read:async()=>structuredClone(state),save:async()=>true}});
 const snapshot=await store.snapshot('owner');
 assert.equal(snapshot.store.profile.businessTypeId,'chicken');
 assert.equal(snapshot.tasks.length,0);
 assert.equal(snapshot.storeSetupCatalog.businessTypes.length,14);
});
test('presets distinguish Korean from frying and never activate legal or unrelated TAPs',()=>{
 const korean=create(setup({businessTypeId:'korean',sourceIds:['korean/prep'],enableOperations:true}));
 assert.equal(korean.taskTemplates[0].title,'반찬 소분과 배식 준비');
 assert.equal(korean.taskTemplates[0].settings.enabled,true);
 const cutlet=create(setup({businessTypeId:'donkatsu',sourceIds:['chicken/prep']}));
 assert.equal(cutlet.manualBusinessProfile.specialization,'돈까스');
 assert.throws(()=>create(setup({businessTypeId:'korean',sourceIds:['chicken/prep']})),/기본 매뉴얼/);
 assert.throws(()=>create(setup({sourceIds:['legal/employment']})),/기본 매뉴얼/);
 assert.throws(()=>create(setup({sourceIds:['business/office']})),/기본 매뉴얼/);
 const none=create(setup({sourceIds:[]}));assert.equal(none.taskTemplates.length,0);assert.equal(none.manualBusinessProfile.industryId,'food');
});
test('invalid configuration rejects rather than silently choosing defaults',()=>{
 for(const patch of [{weekdays:[]},{weekdays:[1,1]},{opening:'08:15'},{opening:'19:00',closing:'19:00'},{partIds:[]},{headcounts:{kitchen:-1,management:0}},{shiftCount:4},{breakTime:{start:'12:00',end:'13:00'}},{serviceModes:['hall'],deliveryPlatforms:['baemin']},{deliveryPlatforms:['unknown']},{sourceIds:['missing']},{releaseId:'stale'}])assert.throws(()=>create(setup(patch)));
});
test('setup uses injected published catalog and stable generic industry metadata',()=>{
 const release=structuredClone(manualCatalog);release.releaseId='new-release';release.entries.find(e=>e.sourceId==='chicken/prep').title='새 발행 튀김 준비';
 const state=create(setup({releaseId:release.releaseId,sourceIds:['chicken/prep']}),release);
 assert.equal(state.taskTemplates[0].title,'새 발행 튀김 준비');
 saveStoreProfile(state,'basic',{name:'한식점',industryId:'restaurant',businessTypeId:'korean',serviceModes:['hall']});
 assert.equal(state.store.profile.businessTypeId,'korean');assert.equal(state.taskTemplates[0].title,'새 발행 튀김 준비');
 assert.throws(()=>saveStoreProfile(state,'basic',{name:'카페',industryId:'cafe',businessTypeId:'korean'}));
});
