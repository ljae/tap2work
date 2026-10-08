import {readFileSync,writeFileSync,mkdirSync,existsSync,renameSync,rmSync} from 'node:fs';
import {join,resolve,dirname} from 'node:path';
import {fileURLToPath} from 'node:url';
import {createHash,randomUUID} from 'node:crypto';
import {spawnSync} from 'node:child_process';
import {ContentTeam,runCodex,runAside} from './content-team.mjs';
import {ContentMemory} from '../developer/content_memory.mjs';
import {DatabaseCatalogRepository} from '../developer/catalog_repository.mjs';
import {checkSource} from '../developer/content_source_checks.mjs';
const repository=resolve(dirname(fileURLToPath(import.meta.url)),'..');
const digest=v=>createHash('sha256').update(JSON.stringify(v)).digest('hex');
const read=p=>JSON.parse(readFileSync(p,'utf8'));
const atomic=(p,v)=>{const temp=p+'.'+randomUUID();writeFileSync(temp,JSON.stringify(v,null,2)+'\n',{mode:0o600});renameSync(temp,p);};
export function cycleKey(now,cadence){
 const day=new Intl.DateTimeFormat('en-CA',{timeZone:'Asia/Seoul',year:'numeric',month:'2-digit',day:'2-digit'}).format(new Date(now));
 if(cadence==='daily')return day;
 if(cadence!=='weekly')throw Error('Cadence must be daily or weekly');
 const date=new Date(day+'T00:00:00Z');date.setUTCDate(date.getUTCDate()-(date.getUTCDay()+6)%7);return date.toISOString().slice(0,10);
}
export function createContentRunner({researcher='aside',aside=runAside,codex=runCodex}={}){
 if(!['aside','codex'].includes(researcher))throw Error('Researcher must be aside or codex');
 return packet=>packet.role==='researcher'&&packet.scope.mode==='research'&&researcher==='aside'?aside(packet):codex(packet);
}
export class ContentCycle{
 constructor({root=join(repository,'.local/content-team'),now=()=>Date.now(),runner=createContentRunner(),catalogLoader,sourceChecker=checkSource}={}){
  this.root=resolve(root);this.now=now;this.runner=runner;this.catalogLoader=catalogLoader;this.sourceChecker=sourceChecker;
  this.service=join(this.root,'.service');mkdirSync(this.service,{recursive:true,mode:0o700});
  this.team=new ContentTeam({root:this.root,now});this.memory=this.team.memory;
 }
 configure({cadence='manual',enabled=true,maxCallsPerTick=5}={}){
  if(!['weekly','daily','manual'].includes(cadence)||typeof enabled!=='boolean'||!Number.isInteger(maxCallsPerTick)||maxCallsPerTick<1||maxCallsPerTick>5)throw Error('Invalid cycle configuration');
  const config={schemaVersion:1,cadence,enabled:cadence==='manual'?false:enabled,maxCallsPerTick,timezone:'Asia/Seoul',hour:9,maxSourceChecks:3};
  atomic(join(this.service,'config.json'),config);return config;
 }
 config(){const path=join(this.service,'config.json');return existsSync(path)?read(path):this.configure({cadence:'manual'});}
 async tick({manual=false,requestId=null}={}){
  const config=this.config();if(!config.enabled&&!manual)return {status:'disabled'};
  const lock=join(this.service,'.lock');
  if(existsSync(lock)){
   const owner=read(join(lock,'owner.json'));let alive=true;
   try{process.kill(owner.pid,0);}catch(error){if(error.code==='ESRCH')alive=false;}
   if(alive)return {status:'already_running'};rmSync(lock,{recursive:true,force:true});
  }
  mkdirSync(lock);atomic(join(lock,'owner.json'),{pid:process.pid,at:this.now()});
  try{
   const path=join(this.service,'cycles.json'),cycles=existsSync(path)?read(path):{};
   if(requestId!==null && !/^[a-zA-Z0-9_-]{1,80}$/.test(requestId))throw Error('Invalid manual request ID');
   const key=manual?'manual-'+(requestId??randomUUID()):cycleKey(this.now(),config.cadence);const current=cycles[key];
   if(current?.status==='complete'||current?.status==='blocked'||current?.status==='failed')return {status:current.status,jobId:current.jobId,repeated:true};
   // Resume interrupted earlier work before taking a new gap. No duplicate model calls.
   const pending=Object.values(cycles).find(c=>['running','pending','leased'].includes(c.status));
   let jobId=current?.jobId??pending?.jobId;
   if(!jobId){
    const gap=this.memory.selectGap();if(!gap)return {status:'no_gap'};
    if(!this.catalogLoader)throw Error('Live catalog loader required');
    const published=await this.catalogLoader();
    const targets=published.release.entries.filter(e=>gap.sourceIds.includes(e.sourceId));
    if(!targets.length)throw Error('Queued gap requires existing published sourceIds');
    const state=this.memory.load();
    const candidates=Object.values(state.sources).filter(s=>s.industries.includes(gap.industry)).sort((a,b)=>(state.checks[a.url]?.at??'').localeCompare(state.checks[b.url]?.at??'')).slice(0,config.maxSourceChecks);
    for(const source of candidates)this.memory.check(await this.sourceChecker(source));
    jobId=manual?'request-'+digest([key,gap.gapId,published.revision]).slice(0,32):'cycle-'+key+'-'+digest([gap.gapId,published.revision]).slice(0,10);
    const scope={mode:'research',industry:gap.industry,gap:gap.gap,jurisdiction:gap.jurisdiction,sourceIds:gap.sourceIds,baseRevision:published.revision};
    this.team.init(jobId,scope,{currentContent:targets});
    atomic(join(this.team.dir(jobId),'published-base.json'),published.release);
    atomic(join(this.team.dir(jobId),'target-content.json'),targets);
    cycles[key]={jobId,gapId:gap.gapId,status:'pending',createdAt:new Date(this.now()).toISOString()};atomic(path,cycles);
   }else if(!cycles[key]){cycles[key]={jobId,status:'pending',resumed:true};atomic(path,cycles);}
   let calls=0;
   while(calls<config.maxCallsPerTick){
    if(!manual&&!this.config().enabled)break;
    const packet=this.team.next(jobId);
    if(packet.status!=='ready')break;
    calls++;
    try{this.team.record(jobId,await this.runner(packet),packet.leaseId);}
    catch(error){this.team.fail(jobId,packet.leaseId,error.message);cycles[key]={...cycles[key],status:this.team.status(jobId).status,error:error.message};atomic(path,cycles);throw error;}
   }
   this.memory.ingestJob(this.root,jobId);
   const job=this.team.status(jobId);for(const value of Object.values(cycles))if(value.jobId===jobId)value.status=job.status;cycles[key]={...cycles[key],status:job.status,callsThisTick:calls,updatedAt:new Date(this.now()).toISOString()};atomic(path,cycles);
   // Export remains a candidate; never invokes provider review or publish APIs.
   if(job.status==='complete'&&!existsSync(join(this.team.dir(jobId),'draft-request.json'))){
    try{
     const output=await this.team.exportRelease(jobId,read(join(this.team.dir(jobId),'published-base.json')));
     atomic(join(this.team.dir(jobId),'draft-request.json'),output.draftRequest);atomic(join(this.team.dir(jobId),'draft-request.provenance.json'),output.provenance);
    }catch(error){cycles[key].exportError=error.message;atomic(path,cycles);}
   }
   return {status:job.status,jobId,calls,metrics:this.memory.report(),exportError:cycles[key].exportError??null};
  }finally{rmSync(lock,{recursive:true,force:true});}
 }
}
async function liveCatalog(){
 const url=process.env.SUPABASE_URL,key=process.env.SUPABASE_SECRET_KEY??process.env.SUPABASE_SERVICE_ROLE_KEY;
 if(!url||!key)throw Error('Server-side catalog read environment missing');
 const rest=async(path,options)=>{const response=await fetch(`${url}/rest/v1/${path}`,{...options,headers:{apikey:key,'Content-Type':'application/json',...(key.startsWith('eyJ')?{Authorization:`Bearer ${key}`}:{})}});if(!response.ok)throw Error(`Catalog read HTTP ${response.status}`);return response.json();};
 return new DatabaseCatalogRepository(rest).readPublished();
}
async function cli(){
 const [command,...args]=process.argv.slice(2),options={};for(let i=0;i<args.length;i+=2){if(!args[i].startsWith('--')||!args[i+1])throw Error('Use --name value');options[args[i].slice(2)]=args[i+1];}
 const cycle=new ContentCycle({root:options.root,catalogLoader:liveCatalog,runner:createContentRunner({researcher:options.researcher??'aside'})});
 if(command==='configure')console.log(JSON.stringify(cycle.configure({cadence:options.cadence??'manual',maxCallsPerTick:Number(options['max-calls']??5)})));
 else if(command==='tick')console.log(JSON.stringify(await cycle.tick()));
 else if(command==='run')console.log(JSON.stringify(await cycle.tick({manual:true,requestId:options.request??null}))); 
 else if(command==='status')console.log(JSON.stringify({config:cycle.config(),metrics:cycle.memory.report()},null,2));
 else if(command==='install'||command==='uninstall'){
  if(process.platform!=='darwin')throw Error('launchd install supports macOS; use tick with your scheduler on other hosts');
  const label='work.tap2.content-improvement',path=join(process.env.HOME,'Library/LaunchAgents',label+'.plist');
  const domain='gui/'+process.getuid();
  spawnSync('launchctl',['bootout',domain+'/'+label],{stdio:'ignore'});
  if(command==='uninstall'){if(existsSync(path))rmSync(path);cycle.configure({cadence:'manual'});console.log('Content schedule disabled.');return;}
  const config=cycle.config();if(!config.enabled)throw Error('Configure weekly/daily before install');
  const escape=s=>s.replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;');
  const argv=[process.execPath,'--env-file-if-exists='+join(repository,'.env'),fileURLToPath(import.meta.url),'tick','--root',cycle.root];
  const log=join(cycle.service,'worker.log');
  const plist=`<?xml version="1.0" encoding="UTF-8"?><!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd"><plist version="1.0"><dict><key>Label</key><string>${label}</string><key>ProgramArguments</key><array>${argv.map(x=>'<string>'+escape(x)+'</string>').join('')}</array><key>WorkingDirectory</key><string>${escape(repository)}</string><key>EnvironmentVariables</key><dict><key>PATH</key><string>${escape(process.env.PATH)}</string></dict><key>StartCalendarInterval</key><dict>${config.cadence==='weekly'?'<key>Weekday</key><integer>1</integer>':''}<key>Hour</key><integer>${config.hour}</integer><key>Minute</key><integer>0</integer></dict><key>StandardOutPath</key><string>${escape(log)}</string><key>StandardErrorPath</key><string>${escape(log)}</string></dict></plist>`;
  mkdirSync(dirname(path),{recursive:true});writeFileSync(path,plist,{mode:0o600});
  const result=spawnSync('launchctl',['bootstrap',domain,path],{stdio:'pipe'});if(result.status!==0)throw Error('launchd schedule registration failed');
  console.log(`Registered ${config.cadence} content cycle at 09:00 host local time. No automatic publishing.`);
 }else throw Error('Commands: run, configure, tick, status, install, uninstall');
}
if(process.argv[1]&&resolve(process.argv[1])===fileURLToPath(import.meta.url))cli().catch(error=>{console.error(error.message);process.exitCode=1;});
