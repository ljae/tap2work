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

test('industry bundle creates linked editable recipes and deduplicated zero-stock ingredients without order integrations',async()=>{
 for(const type of catalog.businessTypes){
  const menus=catalog.bundles[type.id];
  const state=create(setup({businessTypeId:type.id,sourceIds:[],pos:undefined,deliveryPlatforms:undefined,bundleVersion:catalog.bundleVersion,menuIds:menus.map(m=>m.id)}));
  assert.equal(state.sales.menus.length,menus.length);
  assert.equal(state.taskTemplates.length,menus.length);
  assert.equal(state.orders.length,0);assert.equal(state.sales.tickets.length,0);
  assert.equal(new Set(state.items.map(i=>i.name)).size,state.items.length);
  assert.ok(state.items.every(i=>i.quantity===0&&i.lastOrderedAt===null&&i.price===0));
  for(const menu of state.sales.menus){
   assert.ok(menu.ingredientIds.every(id=>state.items.some(i=>i.id===id)));
   const recipe=state.taskTemplates.find(t=>t.menuManualId===menu.id);
   assert.equal(recipe.settings.enabled,false);assert.match(recipe.steps[0].manual,/매장 기준 확인 필요/);
  }
 }
 assert.throws(()=>create(setup({menuIds:['korean-1'],bundleVersion:catalog.bundleVersion})),/기본 메뉴/);
 assert.throws(()=>create(setup({menuIds:[],bundleVersion:'old'})),/기본 메뉴/);
});
test('custom parts receive server identities and staffing refers to the same identities',()=>{
 const state=create(setup({customParts:[{id:'custom-packing',name:'포장'}],partIds:['kitchen','custom-packing'],headcounts:{kitchen:1,'custom-packing':2}}));
 const part=state.workplace.parts.find(p=>p.name==='포장');assert.ok(part);assert.notEqual(part.id,'custom-packing');
 assert.equal(state.workplace.days[1][0].headcounts[part.id],2);
 assert.equal(state.workplace.days[1][0].headcounts['custom-packing'],undefined);
 assert.throws(()=>create(setup({customParts:[{id:'custom-a',name:'주방'}]})),/중복/);
 assert.throws(()=>create(setup({customParts:[{id:'custom-a',name:'포장'},{id:'custom-a',name:'준비'}]})),/추가 파트/);
});
test('standard address stores selection separately from editable detail and invalid metadata rejects',()=>{
 const addressSelection={provider:'kakao-postcode',address:'서울특별시 테스트로 1',roadAddress:'서울특별시 테스트로 1',jibunAddress:'',zonecode:'12345',buildingName:'',bname:''};
 const state=create(setup({address:addressSelection.address,addressSelection,addressDetail:'2층'}));
 assert.equal(state.store.profile.addressDetail,'2층');assert.deepEqual(state.store.profile.addressSelection,addressSelection);
 assert.throws(()=>create(setup({address:'다른 주소',addressSelection})),/검색 결과/);
 saveStoreProfile(state,'basic',{name:'변경',industryId:'restaurant',serviceModes:['hall'],address:'이전 클라이언트 주소'});
 assert.equal(state.store.profile.addressSelection,null);
});

test('donkatsu preview and saved manuals use meat wording and preserve store-specific edits on sync',async()=>{
 const preview=catalog.manualVariants.donkatsu.find(e=>e.sourceId==='chicken/prep');
 assert.ok(preview.steps.some(s=>s.manual.includes('생고기용')));
 const state=create(setup({businessTypeId:'donkatsu',sourceIds:['chicken/prep','chicken/peak']}));
 assert.ok(state.taskTemplates.every(t=>!JSON.stringify(t.steps).includes('생닭용')));
 assert.ok(Object.values(state.catalogLinks).every(l=>l.mode==='personalized'));
 const {syncManualCatalog}=await import('../manual_market.mjs');
 const before=structuredClone(state.taskTemplates);syncManualCatalog(state,now,manualCatalog);
 assert.deepEqual(state.taskTemplates,before);
});
