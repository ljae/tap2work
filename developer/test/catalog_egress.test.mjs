import test from 'node:test';
import assert from 'node:assert/strict';
import {DatabaseCatalogRepository,validateRelease} from '../catalog_repository.mjs';
import {manualCatalog} from '../manual_market.mjs';
import {createCloudHandler} from '../supabase_backend.mjs';

function fixture(){
  let release=manualCatalog,revision=4,unavailable=false,bodyReads=0,bodyBytes=0,headerReads=0;
  const releases=new Map([[release.releaseId,release]]);
  const rest=async path=>{
    if(unavailable)throw Error('network unavailable');
    if(path.startsWith('tap2work_catalog_channels?')){
      headerReads++;return [{revision,active_release_id:release.releaseId}];
    }
    let response;
    if(path==='rpc/tap2work_catalog_read')response={revision,release};
    else if(path.startsWith('tap2work_catalog_releases?')){
      const id=new URLSearchParams(path.split('?')[1]).get('release_id').slice(3);
      response=[{payload:releases.get(id)}];
    }else throw Error(`Unexpected path ${path}`);
    bodyReads++;bodyBytes+=Buffer.byteLength(JSON.stringify(response));
    return structuredClone(response);
  };
  return {rest,repository:new DatabaseCatalogRepository(rest),
    stats:()=>({bodyReads,bodyBytes,headerReads}),
    publish(next){release=next;revision++;releases.set(next.releaseId,next);},
    offline(){unavailable=true;},
  };
}

test('ten catalog reads download one immutable release and revalidate its version',async()=>{
  const x=fixture();
  for(let i=0;i<10;i++)assert.equal((await x.repository.readPublished()).revision,4);
  assert.equal(x.stats().bodyReads,1,'unchanged catalogs must not be downloaded repeatedly');
  assert.equal(x.stats().headerReads,10);
});

test('cold unchanged requests never download the catalog body',async()=>{
  const x=fixture();const uid='aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
  for(let i=0;i<10;i++){
    const handler=createCloudHandler({url:'https://test.supabase.co',serviceKey:'test',sectionStorage:true,catalogDatabase:true,fetcher:async url=>{
      if(url.endsWith('/auth/v1/user'))return Response.json({id:uid});
      if(url.endsWith('/rpc/tap2work_read_workspace'))return Response.json({unchanged:true,workspaceId:'w',revision:1,window:1});
      return Response.json(await x.rest(url.split('/rest/v1/')[1]));
    }});
    const response=await handler(new Request('https://test.invalid/operations?revision=1&window=1&role=owner&workspace=w&catalogRevision=4',{headers:{Authorization:'Bearer test'}}));
    assert.equal(response.status,200);assert.equal((await response.json()).unchanged,true);
  }
  assert.equal(x.stats().bodyBytes,0,'an unchanged reply must not hide an upstream full download');
});

test('publication and rollback are immediate and immutable cached data cannot be mutated',async()=>{
  const x=fixture();const first=await x.repository.readPublished();
  first.release.entries[0].title='caller changed its copy';
  assert.equal((await x.repository.readPublished()).release.entries[0].title,manualCatalog.entries[0].title);
  const changed=structuredClone(manualCatalog);changed.entries[0].title+=' updated';
  const next=validateRelease(changed,{assignId:true});x.publish(next);
  const published=await x.repository.readPublished();assert.equal(published.revision,5);assert.equal(published.release.releaseId,next.releaseId);
  x.publish(manualCatalog);
  const rollback=await x.repository.readPublished();assert.equal(rollback.revision,6);assert.equal(rollback.release.releaseId,manualCatalog.releaseId);
  assert.equal(x.stats().bodyReads,2);
  x.offline();await assert.rejects(x.repository.readPublished(),/network unavailable/);
});

test('concurrent catalog requests share an in-flight immutable download',async()=>{
  const x=fixture();await Promise.all(Array.from({length:8},()=>x.repository.readPublished()));
  assert.equal(x.stats().bodyReads,1);
});
