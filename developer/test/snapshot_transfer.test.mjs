import test from 'node:test';
import assert from 'node:assert/strict';
import {compactSnapshot,snapshotFieldHash} from '../snapshot_transfer.mjs';
import {createCloudHandler} from '../supabase_backend.mjs';
import {seedOperations} from '../operations.mjs';
import {manualCatalog} from '../manual_market.mjs';

test('retention applies only to matching currently authorized fields',()=>{
  const previous={revision:1,manualCatalog:{entries:[{installed:[]}]},taskTemplates:[{id:'a'}]};
  const full=compactSnapshot(previous,new URLSearchParams({sync:'fields-v1'}));
  const query=new URLSearchParams({sync:'fields-v1',fields:JSON.stringify(full.fieldHashes)});
  const same=compactSnapshot({...previous,revision:2},query);
  assert.deepEqual(same.retainedFields,['manualCatalog','taskTemplates']);
  const changed=compactSnapshot({...previous,manualCatalog:{entries:[{installed:['new-tap']}]},revision:3},query);
  assert.ok(changed.manualCatalog);assert.deepEqual(changed.retainedFields,['taskTemplates']);
  const reduced=compactSnapshot({revision:4,taskTemplates:[]},query);
  assert.equal(reduced.manualCatalog,undefined);assert.equal(reduced.retainedFields,undefined);
  assert.deepEqual(compactSnapshot(previous,new URLSearchParams()),previous,'old clients receive complete responses');
  assert.ok(compactSnapshot(previous,new URLSearchParams({sync:'fields-v1',fields:'{bad'})).manualCatalog);
  assert.equal(snapshotFieldHash(previous.manualCatalog),full.fieldHashes.manualCatalog);
});

test('minute-boundary projections preserve timed work while retaining large unchanged fields',async()=>{
  let now=new Date('2026-11-04T04:00:00Z'),state=seedOperations(now),bodyReads=0;
  const uid='aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
  const handler=createCloudHandler({url:'https://test.supabase.co',serviceKey:'test',sectionStorage:true,catalogDatabase:true,clock:()=>now,fetcher:async(url,options={})=>{
    if(url.endsWith('/auth/v1/user'))return Response.json({id:uid});
    if(url.includes('/tap2work_catalog_channels?'))return Response.json([{revision:4,active_release_id:manualCatalog.releaseId}]);
    if(url.includes('/tap2work_catalog_releases?')){bodyReads++;return Response.json([{payload:manualCatalog}]);}
    const input=JSON.parse(options.body);const window=Math.floor(now.getTime()/60000);
    if(url.endsWith('/rpc/tap2work_read_workspace')){
      if(input.p_revision===state.revision&&input.p_window===window&&input.p_role==='owner'&&input.p_workspace_id==='w')return Response.json({unchanged:true,workspaceId:'w',revision:state.revision,window});
      return Response.json({member:{workspace_id:'w',role:'owner',display_name:'Synthetic owner'},payload:state,window});
    }
    if(url.endsWith('/rpc/tap2work_patch_state')){
      if(input.p_expected_revision!==state.revision)return Response.json(false);
      Object.assign(state,input.p_changes);for(const key of input.p_removed??[])delete state[key];state.revision++;
      return Response.json(true);
    }
    throw Error('Unexpected request');
  }});
  const read=async params=>{
    const response=await handler(new Request(`https://test.invalid/operations?${new URLSearchParams({sync:'fields-v1',...params})}`,{headers:{Authorization:'Bearer test'}}));
    const text=await response.text();assert.equal(response.status,200,text);return {body:JSON.parse(text),bytes:Buffer.byteLength(text)};
  };
  const first=await read({});const base=first.body;
  now=new Date(now.getTime()+60000);
  const next=await read({revision:String(base.revision),window:String(base.syncWindow),workspace:'w',role:'owner',catalogRevision:'4',fields:JSON.stringify(base.fieldHashes)});
  assert.equal(next.body.syncWindow,Math.floor(now.getTime()/60000));
  assert.ok(next.body.tasks);assert.ok(next.body.retainedFields.includes('manualCatalog'));
  assert.equal(next.body.manualCatalog,undefined);assert.equal(bodyReads,1);
  assert.ok(next.bytes<first.bytes*0.6,`expected substantial savings: ${first.bytes} -> ${next.bytes}`);
  console.log(`Synthetic minute-boundary response: ${first.bytes} -> ${next.bytes} bytes; catalog downloads=${bodyReads}`);
});

test('upstream quota and availability errors do not impersonate expired credentials',async()=>{
  for(const [upstream,expected] of [[402,402],[503,503],[401,401]]){
    const handler=createCloudHandler({url:'https://test.supabase.co',serviceKey:'test',fetcher:async()=>new Response('{}',{status:upstream})});
    const response=await handler(new Request('https://test.invalid/operations',{headers:{Authorization:'Bearer test'}}));
    assert.equal(response.status,expected);
  }
});
