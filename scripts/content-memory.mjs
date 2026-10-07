import {readFileSync} from 'node:fs';
import {join,resolve} from 'node:path';
import {ContentMemory} from '../developer/content_memory.mjs';
import {checkSource} from '../developer/content_source_checks.mjs';
const [command,...args]=process.argv.slice(2),options={};
for(let i=0;i<args.length;i+=2){if(!args[i].startsWith('--')||!args[i+1])throw Error('Use --name value');options[args[i].slice(2)]=args[i+1];}
const teamRoot=resolve(options.root??'.local/content-team'),memory=new ContentMemory({root:join(teamRoot,'.learning')});
const input=()=>JSON.parse(readFileSync(options.file,'utf8'));
let result;
if(command==='status')result=memory.report();
else if(command==='sources')result=Object.values(memory.load().sources);
else if(command==='add-gap')result={gapId:memory.addGap(input())};
else if(command==='feedback')result=memory.feedback(input());
else if(command==='ingest')result=memory.ingestJob(teamRoot,options.job);
else if(command==='check-sources'){
 const limit=Number(options.limit??5);if(!Number.isInteger(limit)||limit<1||limit>10)throw Error('Limit must be 1–10');
 const state=memory.load();const sources=Object.values(state.sources).sort((a,b)=>(state.checks[a.url]?.at??'').localeCompare(state.checks[b.url]?.at??'')).slice(0,limit);
 result=[];for(const source of sources){const checked=await checkSource(source);memory.check(checked);result.push(checked);}
}else throw Error('Commands: status, sources, add-gap, feedback, ingest, check-sources');
console.log(JSON.stringify(result,null,2));
