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
   if(url.endsWith('/tap2work_catalog_read'))return Response.json({revision:1,release:manualCatalog});
   if(url.endsWith('/tap2work_read_workspace'))return Response.json({member:{workspace_id:'fixture',role:'owner',display_name:'Test'},payload:state,window:1});
   if(url.endsWith('/tap2work_patch_state')){const input=JSON.parse(options.body);Object.assign(state,input.p_changes);state.revision++;return Response.json(true);}
   throw Error('Unexpected fixture request');
  }});
 const response=await handler(new Request('https://example.invalid/operations',{headers:{Authorization:'Bearer fixture'}}));
 const result=await response.json();
 if(response.status!==200||result.manualCatalog?.entries.length!==manualCatalog.entries.length||!result.taskTemplates?.length)throw Error(`Authenticated Edge smoke failed (${response.status})`);
 console.log('Authenticated DB-backed Edge read passed without Node globals.');
}finally{if(originalBuffer!==undefined)globalThis.Buffer=originalBuffer;}
