import {manualCatalog} from '../developer/manual_market.mjs';
import {validateRelease} from '../developer/catalog_repository.mjs';
import {randomUUID} from 'node:crypto';
import {pathToFileURL} from 'node:url';
export async function seedCatalog({url,key,fetcher=fetch}){
 if(!url||!key)throw Error('Set server-side Supabase environment');
 const release=validateRelease(manualCatalog);
 const headers={apikey:key,'Content-Type':'application/json',...(key.startsWith('eyJ')?{Authorization:`Bearer ${key}`}:{})};
 const rpc=async(name,body)=>{
  const r=await fetcher(`${url}/rest/v1/rpc/${name}`,{method:'POST',headers,body:JSON.stringify(body)});
  if(!r.ok)throw Error(`Catalog initialization failed: HTTP ${r.status}`);
  return r.json();
 };
 const existing=await rpc('tap2work_catalog_read',{p_channel:'stable'});
 if(existing?.revision>0 && existing?.release){
  if(existing.release.releaseId!==release.releaseId)throw Error('Initialized channel differs; use reviewed publishing instead of seed.');
  return {initialized:false,revision:existing.revision};
 }
 const r=await rpc('tap2work_catalog_seed',{p_actor_id:null,p_release:release,p_payload_hash:release.releaseId,p_request_id:randomUUID(),p_channel:'stable'});
 return {initialized:true,revision:r.revision};
}
if(process.argv[1] && import.meta.url===pathToFileURL(process.argv[1]).href){
 const result=await seedCatalog({url:process.env.SUPABASE_URL,key:process.env.SUPABASE_SECRET_KEY??process.env.SUPABASE_SERVICE_ROLE_KEY});
 console.log(result.initialized?`Seeded ${manualCatalog.entries.length} existing TAPs, revision ${result.revision}.`:'Catalog already initialized; no change.');
}
