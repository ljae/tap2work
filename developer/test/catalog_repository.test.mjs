import test from 'node:test';
import assert from 'node:assert/strict';
import {validateRelease,releaseHash,canonicalJson,DatabaseCatalogRepository} from '../catalog_repository.mjs';
import {manualCatalog,syncManualCatalog,mutateManualMarket} from '../manual_market.mjs';
import {seedOperations,OperationsStore} from '../operations.mjs';
import {createCloudHandler} from '../supabase_backend.mjs';
const now=new Date('2026-10-07T04:00:00Z');
function next(){const r=structuredClone(manualCatalog);r.entries[0].steps[0].manual+=' 새 방법';return validateRelease(r,{assignId:true});}
test('DB release validates hash independent of JSON key ordering and permits exact legacy seed only',()=>{
 assert.equal(validateRelease(manualCatalog).releaseId,manualCatalog.releaseId);
 const r=next();const reversed=JSON.parse(JSON.stringify(r,(k,v)=>v&&typeof v==='object'&&!Array.isArray(v)?Object.fromEntries(Object.entries(v).reverse()):v));
 assert.equal(validateRelease(reversed).releaseId,r.releaseId);
 r.entries[0].title+='changed';assert.throws(()=>validateRelease(r));
 r.releaseId=manualCatalog.releaseId;assert.throws(()=>validateRelease(r));
});
test('DB taxonomy is validated without bundled classifications and policy-bearing Tasks rejected',()=>{
 const r=structuredClone(manualCatalog);r.taxonomy.industries.push({id:'new-industry',name:'새 업종'});r.entries[0].industryIds=['new-industry'];
 assert.equal(validateRelease(r,{assignId:true}).entries[0].industryIds[0],'new-industry');
 r.entries[0].steps[0].settings={enabled:true};assert.throws(()=>validateRelease(r,{assignId:true}));
});
test('missing DB channel fails closed instead of silently reverting to bundle',async()=>{
 const repository=new DatabaseCatalogRepository(async()=>null);await assert.rejects(repository.readPublished(),{status:503});
});
test('metadata-only updates advance evaluated release without rewriting execution, version or personalization',()=>{
 const state=seedOperations(now);const source=manualCatalog.entries[0];
 mutateManualMarket(state,{action:'import_market_taps',releaseId:manualCatalog.releaseId,operationId:'catalog-test-0001',sourceIds:[source.sourceId],folderId:'general'},{id:'owner',role:'owner'},now);
 const id=Object.keys(state.catalogLinks)[0];const template=state.taskTemplates.find(t=>t.id===id);const before=structuredClone(state.tasks);const version=template.version;
 const r=structuredClone(manualCatalog);r.entries[0].basis+=' newly checked';r.releaseId=releaseHash(r);
 assert.equal(syncManualCatalog(state,now,r),true);assert.equal(state.catalogLinks[id].releaseId,r.releaseId);assert.equal(template.version,version);assert.deepEqual(state.tasks,before);assert.equal(syncManualCatalog(state,now,r),false);
});
test('same Edge handler reads a new DB release, invalidates unchanged, and imports using that release',async()=>{
 let state=seedOperations(now);let published={revision:1,release:manualCatalog};let readInput;
 const handler=createCloudHandler({url:'https://test.supabase.co',serviceKey:'test',sectionStorage:true,clock:()=>now,catalogRepository:{readPublished:async()=>structuredClone(published)},fetcher:async(url,options)=>{
  if(url.endsWith('/auth/v1/user'))return Response.json({id:'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'});
  const input=JSON.parse(options.body);
  if(url.endsWith('tap2work_read_workspace')){readInput=input;if(input.p_revision===state.revision)return Response.json({unchanged:true,revision:state.revision});return Response.json({member:{workspace_id:'w',role:'owner',display_name:'Owner'},payload:state,window:1});}
  if(url.endsWith('tap2work_patch_state')){Object.assign(state,input.p_changes);state.revision++;return Response.json(true);}throw Error(url);
 }});
 const call=(query='',body)=>handler(new Request('https://test.invalid/operations'+query,{method:body?'POST':'GET',headers:{Authorization:'Bearer token','Content-Type':'application/json'},...(body?{body:JSON.stringify(body)}:{})}));
 const a=await(await call()).json();assert.equal(a.manualCatalog.releaseId,manualCatalog.releaseId);
 published={revision:2,release:next()};
 const b=await(await call(`?revision=${a.revision}&window=1&role=owner&workspace=w&catalogRevision=1`)).json();assert.equal(readInput.p_revision,null);assert.equal(b.catalogRevision,2);assert.equal(b.manualCatalog.releaseId,published.release.releaseId);
 const result=await call('',{action:'import_market_taps',revision:b.revision,releaseId:b.manualCatalog.releaseId,operationId:'database-import-001',sourceIds:[b.manualCatalog.entries[0].sourceId],folderId:'general'});
 assert.equal(result.status,200,await result.clone().text());const view=await result.json();assert.ok(view.taskTemplates.some(t=>t.steps?.[0]?.manual===published.release.entries[0].steps[0].manual));
 const unchanged=await(await call(`?revision=${view.revision}&window=1&role=owner&workspace=w&catalogRevision=2`)).json();assert.equal(unchanged.unchanged,true);
});
test('a paused older channel request cannot overwrite a newer workspace catalog, rollback uses increasing revision',async()=>{
 let state=seedOperations(now);
 const source=manualCatalog.entries[0];
 mutateManualMarket(state,{action:'import_market_taps',releaseId:manualCatalog.releaseId,operationId:'interleave-0001',sourceIds:[source.sourceId],folderId:'general'},{id:'owner',role:'owner'},now);
 const persistence={read:async()=>structuredClone(state),save:async(s,revision)=>{assert.equal(revision,state.revision);state=structuredClone(s);}};
 const actor={id:'owner',role:'owner',name:'Owner'};
 const old=new OperationsStore(null,()=>now,{persistence,actor,catalog:manualCatalog,catalogRevision:1});
 const fresh=new OperationsStore(null,()=>now,{persistence,actor,catalog:next(),catalogRevision:2});
 await fresh.snapshot('owner');const before=structuredClone(state);
 await assert.rejects(old.snapshot('owner'),{status:409});assert.deepEqual(state,before);
 const rollback=new OperationsStore(null,()=>now,{persistence,actor,catalog:manualCatalog,catalogRevision:3});
 await rollback.snapshot('owner');assert.equal(state.catalogSync.revision,3);assert.equal(state.catalogLinks[Object.keys(state.catalogLinks)[0]].releaseId,manualCatalog.releaseId);
});
test('fresh DB revision zero seeds exact legacy once; initialized channel cannot be replaced',async()=>{
 const {seedCatalog}=await import('../../scripts/seed-catalog.mjs');let current={revision:0,release:null};let writes=0;
 const fetcher=async(url,options)=>{if(url.endsWith('tap2work_catalog_read'))return Response.json(current);const input=JSON.parse(options.body);writes++;assert.equal(input.p_release.releaseId,manualCatalog.releaseId);current={revision:1,release:input.p_release};return Response.json({revision:1});};
 assert.equal((await seedCatalog({url:'https://example.supabase.co',key:'secret',fetcher})).initialized,true);
 assert.equal((await seedCatalog({url:'https://example.supabase.co',key:'secret',fetcher})).initialized,false);assert.equal(writes,1);
 current.release=next();await assert.rejects(seedCatalog({url:'https://example.supabase.co',key:'secret',fetcher}));assert.equal(writes,1);
});
test('catalog validation runs in Edge runtimes without Node Buffer globals',()=>{
 const buffer=globalThis.Buffer;
 try{
  delete globalThis.Buffer;
  assert.equal(validateRelease(manualCatalog).entries.length,109);
 }finally{globalThis.Buffer=buffer;}
});

test('original database seed remains readable after bundled catalog advances',async()=>{
 const {default:legacy}=await import('../../docs/market/releases/473ae81f07c0e1289ff6e7ed1dc97f133586b93ec71559e5833032f1129ac9c1.json',{with:{type:'json'}});
 const jsonb=JSON.parse(canonicalJson(legacy));
 assert.equal(validateRelease(jsonb).entries.length,86);
 jsonb.entries[0].steps[0].manual+=' tampered';
 assert.throws(()=>validateRelease(jsonb));
});
