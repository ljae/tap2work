// Authenticated provider API client: token stays in environment, never arguments.
import {readFile} from 'node:fs/promises';
const [command,inputFile]=process.argv.slice(2);
if(!['save_draft','read_draft','review','publish','rollback','read_published'].includes(command)||!inputFile)throw Error('Usage: catalog-admin <action> <input.json>');
const token=process.env.CATALOG_ACCESS_TOKEN;
const url=process.env.SUPABASE_URL;
if(!token||!url)throw Error('Set CATALOG_ACCESS_TOKEN and SUPABASE_URL');
const input=JSON.parse(await readFile(inputFile,'utf8'));
const result=await fetch(`${url}/functions/v1/catalog-admin`,{method:'POST',headers:{Authorization:`Bearer ${token}`,apikey:process.env.SUPABASE_PUBLISHABLE_KEY??'','Content-Type':'application/json'},body:JSON.stringify({...input,action:command})});
const body=await result.json();
if(!result.ok){console.error(body.error??`HTTP ${result.status}`);process.exit(1);}
console.log(JSON.stringify(body,null,2));
