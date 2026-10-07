import {createHash,randomUUID} from 'node:crypto';
import {mkdirSync,readFileSync,writeFileSync,renameSync,readdirSync,existsSync,rmSync} from 'node:fs';
import {join} from 'node:path';
const hash=v=>createHash('sha256').update(typeof v==='string'?v:JSON.stringify(v)).digest('hex');
const read=p=>JSON.parse(readFileSync(p,'utf8'));
const fail=s=>{throw Error(s);};
const text=(s,max=2000)=>typeof s==='string'&&s.trim()&&s.length<=max?s.trim():fail('Invalid learning text');
const safeText=s=>{s=text(s);if(/-----BEGIN|\b(?:access_token|refresh_token|service_role|SUPABASE_SECRET|password)\b|\beyJ[A-Za-z0-9_-]{20,}\./i.test(s))fail('Learning input contains credential markers');return s;};
const atomic=(p,v)=>{const tmp=p+'.'+randomUUID()+'.tmp';writeFileSync(tmp,JSON.stringify(v,null,2)+'\n',{mode:0o600});renameSync(tmp,p);};
export function sourceUrl(value){
 const u=new URL(value);if(u.protocol!=='https:'||u.username||u.password||/[?&](?:token|key|secret|signature|access_token|api_key|apikey)=/i.test(value))fail('Unsafe source URL');
 if(!u.hostname.includes('.')||/^(?:localhost|127\.|0\.|10\.|192\.168\.|169\.254\.|172\.(?:1[6-9]|2\d|3[01])\.)/.test(u.hostname)||u.hostname.startsWith('['))fail('Private source URL');
 u.hash='';return u.href;
}
const empty=()=>({schemaVersion:1,revision:0,sources:Object.create(null),gaps:Object.create(null),lessons:Object.create(null),receipts:Object.create(null),outcomes:Object.create(null),checks:Object.create(null)});
export class ContentMemory{
 constructor({root,now=()=>Date.now()}={}){if(!root)fail('Memory root required');this.root=root;this.now=now;mkdirSync(join(root,'events'),{recursive:true,mode:0o700});}
 load(){
  const state=empty();
  for(const name of readdirSync(join(this.root,'events')).filter(x=>x.endsWith('.json')).sort()){
   const event=read(join(this.root,'events',name));
   if(event.sequence!==state.revision+1||event.payloadHash!==hash(event.payload))fail('Learning event chain changed');
   this.apply(state,event);state.revision=event.sequence;state.receipts[event.id]=event.payloadHash;
  }
  return state;
 }
 append(id,type,payload){
  safeText(id);const lock=join(this.root,'.lock');
  try{mkdirSync(lock);}catch{fail('Learning memory is locked');}
  try{
   const state=this.load();const payloadHash=hash(payload);
   if(Object.hasOwn(state.receipts,id)){if(state.receipts[id]!==payloadHash)fail('Learning event ID reused with different content');return state;}
   const event={id,type,payload,payloadHash,sequence:state.revision+1,at:new Date(this.now()).toISOString()};
   this.apply(state,event);
   atomic(join(this.root,'events',String(event.sequence).padStart(12,'0')+'-'+hash(id)+'.json'),event);
   return this.load();
  }finally{rmSync(lock,{recursive:true,force:true});}
 }
 apply(state,{type,payload:p,at}){
  if(type==='gap'){
   if(!state.gaps[p.gapId])state.gaps[p.gapId]={...p,status:'open',createdAt:at,lastStudiedAt:null};
  }else if(type==='research'){
   for(const source of p.sources){
    const url=sourceUrl(source.url);
    const current=state.sources[url]??{url,title:source.title,publisher:source.publisher,jurisdiction:source.jurisdiction,observations:{},assessments:{},industries:[],sourceIds:[],correct:0,incorrect:0,status:'candidate',lastRetrievedAt:null};
    current.industries=[...new Set([...current.industries,p.scope.industry])];
    current.sourceIds=[...new Set([...current.sourceIds,...p.scope.sourceIds])];
    current.observations[p.jobId+'/'+source.id]={applicability:source.applicability,evidenceHash:source.evidenceHash,excerpt:source.excerpt,retrievedAt:source.retrievedAt};
    current.lastRetrievedAt=[current.lastRetrievedAt,source.retrievedAt].filter(Boolean).sort((a,b)=>Date.parse(a)-Date.parse(b)).at(-1);
    // Repeated discoveries do not become verified observations or clear disputes.
    state.sources[url]=current;
   }
  }else if(type==='assessment'){
   state.outcomes[p.jobId]={...(state.outcomes[p.jobId]??{}),scope:p.scope,[p.role]:p.result};
   if(p.role==='reviewer'&&p.result.outcome==='changes_required')for(const note of p.result.findings)state.lessons[hash(note)]={note,jobId:p.jobId,kind:'reviewer_finding',at};
   if(p.role==='qa'&&p.result.outcome==='fail')for(const note of p.result.blockers)state.lessons[hash(note)]={note,jobId:p.jobId,kind:'qa_failure',at};
   if(p.role==='coordinator'){
    for(const gap of Object.values(state.gaps))if(gap.industry===p.scope.industry&&gap.gap===p.scope.gap)gap.lastStudiedAt=at;
    for(const gap of p.result.nextGaps){const gapId=hash([p.scope.industry,gap,p.scope.jurisdiction]);if(!state.gaps[gapId])state.gaps[gapId]={gapId,gap,industry:p.scope.industry,jurisdiction:p.scope.jurisdiction,sourceIds:p.scope.sourceIds,priority:20,status:'open',createdAt:at,lastStudiedAt:null};}
   }
  }else if(type==='feedback'){
   const previous=state.outcomes[p.jobId]??{};
   state.outcomes[p.jobId]={...previous,feedback:[...(previous.feedback??[]),{...p,at}]};
   for(const url of p.sourceUrls){
    const source=state.sources[url];if(!source)fail('Unknown feedback source');
    if(['correct','incorrect','revalidated'].includes(p.verdict))source.assessments[p.jobId]={verdict:p.verdict,reason:p.reason,at};
    source.correct=Object.values(source.assessments).filter(x=>x.verdict==='correct').length;
    source.incorrect=Object.values(source.assessments).filter(x=>x.verdict==='incorrect').length;
    if(p.verdict==='incorrect')source.status='disputed';
    if(p.verdict==='revalidated')source.status='provider_checked';
    if(p.verdict==='correct'&&source.status!=='disputed')source.status='provider_checked';
   }
   if(['incorrect','not_helpful','needs_changes'].includes(p.verdict))state.lessons[hash([p.jobId,p.reason])]={note:p.reason,jobId:p.jobId,kind:'provider_feedback',at};
   if(p.gapId&&state.gaps[p.gapId]){
    const gap=state.gaps[p.gapId];if(['incorrect','not_helpful','needs_changes'].includes(p.verdict)){gap.status='open';gap.priority=Math.min(100,gap.priority+20);}else if(p.verdict==='helpful')gap.status='resolved';
   }
  }else if(type==='failure'){
   state.lessons[hash([p.jobId,p.role,p.reason])]={note:p.reason,jobId:p.jobId,kind:'runner_failure',at};
  }else if(type==='source_check'){
   if(!state.sources[p.url])fail('Unknown check source');state.checks[p.url]={...p,at};
  }else fail('Unknown memory event');
 }
 addGap({gap,industry,jurisdiction='KR',sourceIds=[],priority=50,eventId}){
  const clean={gap:safeText(gap),industry:safeText(industry),jurisdiction:text(jurisdiction,100),sourceIds:[...new Set(sourceIds.map(x=>text(x,100)))],priority};
  if(!Number.isInteger(priority)||priority<0||priority>100)fail('Invalid gap priority');
  const gapId=hash([clean.industry,clean.gap,clean.jurisdiction]);this.append(eventId??'gap-'+gapId,'gap',{...clean,gapId});return gapId;
 }
 ingestJob(teamRoot,jobId){
  if(!/^[a-zA-Z0-9][a-zA-Z0-9_-]{0,79}$/.test(jobId))fail('Invalid job ID');
  const dir=join(teamRoot,jobId),job=read(join(dir,'job.json')),scope=read(join(dir,'scope.json'));
  if(scope.mode!=='research')return {ignored:true,reason:'fixture'};
  if(job.scopeHash!==hash(scope)||job.configHash!==hash(read(join(dir,'config.json'))))fail('Job learning input changed');
  for(const event of job.events.filter(e=>e.type==='attempt_failed'))this.append('failure-'+hash([jobId,event.role,event.at,event.reason]),'failure',{jobId,role:event.role,reason:safeText(event.reason)});
  for(const stage of job.stages.filter(s=>s.status==='complete')){
   const bytes=readFileSync(join(dir,'artifacts',stage.role+'.json'));
   if(hash(bytes.toString())!==stage.outputHash)fail('Job learning artifact changed');
   const result=JSON.parse(bytes).result;const eventId='job-'+jobId+'-'+stage.role+'-'+stage.outputHash;
   if(stage.role==='researcher'){
    if(result.sources.some(s=>s.kind!=='external'))fail('Fixture source cannot enter learning memory');
    this.append(eventId,'research',{jobId,scope,sources:result.sources.map(s=>({...s,url:sourceUrl(s.url)}))});
   }else if(['reviewer','qa','coordinator'].includes(stage.role))this.append(eventId,'assessment',{jobId,role:stage.role,result,scope});
  }
  return {ignored:false,revision:this.load().revision};
 }
 feedback({eventId,jobId,verdict,reason,sourceUrls=[],gapId=null}){
  if(!['correct','incorrect','helpful','not_helpful','needs_changes','revalidated'].includes(verdict))fail('Invalid feedback verdict');
  const state=this.load(),outcome=state.outcomes[jobId];
  if(!Object.hasOwn(state.outcomes,jobId))fail('Feedback requires ingested real job');
  for(const value of sourceUrls){const url=sourceUrl(value);if(!state.sources[url]||!Object.keys(state.sources[url].observations).some(key=>key.startsWith(jobId+'/')))fail('Feedback source was not observed in this job');}
  if(gapId!==null){const gap=state.gaps[gapId];if(!gap||gap.gap!==outcome.scope.gap||gap.industry!==outcome.scope.industry)fail('Feedback gap does not match job');}
  if(verdict==='revalidated'&&(!sourceUrls.length||safeText(reason).length<10))fail('Source revalidation requires sources and evidence explanation');
  const payload={jobId:text(jobId,100),verdict,reason:safeText(reason),sourceUrls:[...new Set(sourceUrls.map(sourceUrl))],gapId};
  this.append(text(eventId,100),'feedback',payload);return this.report();
 }
 check({url,status,contentHash=null,excerptMatched=null}){
  url=sourceUrl(url);if(!['reachable','missing','error','blocked','unverifiable'].includes(status))fail('Invalid source status');
  const payload={url,status,contentHash,excerptMatched,checkedOn:new Date(this.now()).toISOString().slice(0,10)};
  this.append('check-'+randomUUID(),'source_check',payload);
 }
 context(scope,{limit=10}={}){
  if(scope.mode==='fixture')return {revision:0,sources:[],lessons:[],metrics:{evaluated:0},scope:'fixture-no-learning'};
  const state=this.load(),now=this.now();
  const sources=Object.values(state.sources).filter(s=>s.industries.includes(scope.industry)&&(s.jurisdiction===scope.jurisdiction||s.sourceIds.some(id=>scope.sourceIds.includes(id)))).sort((a,b)=>(b.correct-b.incorrect*5)-(a.correct-a.incorrect*5)).slice(0,limit).map(s=>({url:s.url,title:s.title,publisher:s.publisher,jurisdiction:s.jurisdiction,crossJurisdiction:s.jurisdiction!==scope.jurisdiction,status:s.status,correct:s.correct,incorrect:s.incorrect,lastRetrievedAt:s.lastRetrievedAt,stale:now-Date.parse(s.lastRetrievedAt)>30*86400000,health:state.checks[s.url]??null,observations:Object.values(s.observations).slice(-2)}));
  const lessons=Object.values(state.lessons).sort((a,b)=>b.at.localeCompare(a.at)).slice(0,limit);
  return {revision:state.revision,sources,lessons,metrics:this.report(state),warning:'Historical observations and operator feedback are not current facts or publication approval. Recheck stale/disputed sources.'};
 }
 selectGap(){
  const state=this.load();
  return Object.values(state.gaps).filter(g=>g.status==='open').sort((a,b)=>{
   const score=g=>g.priority+(g.lastStudiedAt?Math.min(30,(this.now()-Date.parse(g.lastStudiedAt))/86400000):40)+(Object.values(state.sources).some(s=>s.sourceIds.some(id=>g.sourceIds.includes(id))&&(s.status==='disputed'||this.now()-Date.parse(s.lastRetrievedAt)>30*86400000||['missing','blocked'].includes(state.checks[s.url]?.status)||state.checks[s.url]?.excerptMatched===false))?35:0);
   return score(b)-score(a)||a.createdAt.localeCompare(b.createdAt);
  })[0]??null;
 }
 report(state=this.load()){
  const feedback=Object.values(state.outcomes).flatMap(o=>{const values=o.feedback??[];return [values.filter(f=>['correct','incorrect'].includes(f.verdict)).at(-1),values.filter(f=>['helpful','not_helpful'].includes(f.verdict)).at(-1)].filter(Boolean);});
  const count=v=>feedback.filter(f=>f.verdict===v).length;
  const evaluated=count('correct')+count('incorrect'),fieldEvaluated=count('helpful')+count('not_helpful');
  return {unverifiableSources:Object.values(state.checks).filter(x=>x.status==='unverifiable').length,checkedSources:Object.keys(state.checks).length,unmatchedEvidence:Object.values(state.checks).filter(x=>x.excerptMatched===false).length,inaccessibleSources:Object.values(state.checks).filter(x=>['missing','blocked','error'].includes(x.status)).length,revision:state.revision,sources:Object.keys(state.sources).length,disputedSources:Object.values(state.sources).filter(s=>s.status==='disputed').length,openGaps:Object.values(state.gaps).filter(g=>g.status==='open').length,lessons:Object.keys(state.lessons).length,evaluated,correctRate:evaluated?count('correct')/evaluated:null,fieldEvaluated,helpfulRate:fieldEvaluated?count('helpful')/fieldEvaluated:null,notMeasured:evaluated===0||fieldEvaluated===0};
 }
}
