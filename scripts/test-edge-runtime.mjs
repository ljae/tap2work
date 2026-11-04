// Portable Edge smoke: no production credentials/network or operational data.
import {createCloudHandler} from '../developer/supabase_backend.mjs';
import {manualCatalog} from '../developer/manual_market.mjs';
import {seedOperations} from '../developer/operations.mjs';
const originalBuffer=globalThis.Buffer;
try{
 delete globalThis.Buffer;
 let state=seedOperations(new Date('2026-10-07T04:00:00Z'));
 const handler=createCloudHandler({url:'https://example.supabase.co',serviceKey:'fixture',sectionStorage:true,catalogDatabase:true,
  clock:()=>new Date('2026-10-07T04:00:00Z'),fetcher:async(url,options)=>{
   if(url.endsWith('/auth/v1/user'))return Response.json({id:'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'});
   if(url.includes('/tap2work_catalog_channels?'))return Response.json([{revision:1,active_release_id:manualCatalog.releaseId}]);
   if(url.includes('/tap2work_catalog_releases?'))return Response.json([{payload:manualCatalog}]);
   if(url.endsWith('/tap2work_read_workspace'))return Response.json({member:{workspace_id:'fixture',role:'owner',display_name:'Test'},payload:state,window:1});
   if(url.endsWith('/tap2work_patch_state')){const input=JSON.parse(options.body);Object.assign(state,input.p_changes);state.revision++;return Response.json(true);}
   throw Error('Unexpected fixture request');
  }});
 const response=await handler(new Request('https://example.invalid/operations?sync=fields-v1',{headers:{Authorization:'Bearer fixture'}}));
 const result=await response.json();
 if(response.status!==200||result.manualCatalog?.entries.length!==manualCatalog.entries.length||!result.taskTemplates?.length)throw Error(`Authenticated Edge smoke failed (${response.status})`);
 const query=new URLSearchParams({sync:'fields-v1',fields:JSON.stringify(result.fieldHashes)});
 const compact=await handler(new Request(`https://example.invalid/operations?${query}`,{headers:{Authorization:'Bearer fixture'}}));
 const retained=await compact.json();
 if(compact.status!==200||!retained.retainedFields?.includes('manualCatalog')||retained.manualCatalog!==undefined||!retained.tasks)throw Error('Compact Edge read failed');
 console.log('Authenticated DB-backed Edge read passed without Node globals.');
}finally{if(originalBuffer!==undefined)globalThis.Buffer=originalBuffer;}
