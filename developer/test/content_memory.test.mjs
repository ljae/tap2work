import test from 'node:test';
import assert from 'node:assert/strict';
import {mkdtempSync,rmSync,readFileSync} from 'node:fs';
import {join} from 'node:path';
import {tmpdir} from 'node:os';
import {ContentTeam,fixtureArtifact} from '../../scripts/content-team.mjs';
import {ContentMemory,sourceUrl} from '../content_memory.mjs';
import {checkSource} from '../content_source_checks.mjs';
import {ContentCycle,cycleKey} from '../../scripts/content-cycle.mjs';
import {manualCatalog} from '../manual_market.mjs';
const scope={mode:'research',industry:'food-service',gap:'누락 없는 인계 방법',jurisdiction:'KR',sourceIds:[manualCatalog.entries[0].sourceId],baseRevision:1};
const url='https://public.example.com/handoff';
// Simulated public evidence is used only in disposable unit-test queues.
function artifact(packet){
 const value=fixtureArtifact({...packet,scope:{...packet.scope,mode:'fixture'}});
 if(packet.role==='researcher'){value.result.sources[0].kind='external';value.result.sources[0].url=url;value.result.sources[0].publisher='unit-test';value.result.sources[0].jurisdiction='KR';}
 if(packet.role==='editor'){value.result.drafts[0].sourceId=scope.sourceIds[0];value.result.drafts[0].steps[0].id=manualCatalog.entries[0].steps[0].id;}
 return value;
}
function setup(t){
 const root=mkdtempSync(join(tmpdir(),'tap-content-memory-'));t.after(()=>rmSync(root,{recursive:true,force:true}));
 let now=Date.parse('2026-10-07T04:00:00Z');const team=new ContentTeam({root,now:()=>now});
 return {root,team,memory:team.memory,advance:days=>{now+=days*86400000;},clock:()=>now};
}
function complete(team,job='real'){team.init(job,scope);for(let i=0;i<5;i++){const packet=team.next(job);team.record(job,artifact(packet),packet.leaseId);}}
test('real jobs accumulate candidate sources and next gaps but no unmeasured accuracy claims',t=>{
 const x=setup(t);complete(x.team);
 assert.equal(x.memory.report().sources,1);assert.equal(x.memory.report().correctRate,null);assert.equal(x.memory.report().helpfulRate,null);
 assert.equal(x.memory.load().sources[url].status,'candidate');
 x.memory.ingestJob(x.root,'real');assert.equal(x.memory.report().sources,1);
 const restarted=new ContentMemory({root:join(x.root,'.learning'),now:x.clock});assert.equal(restarted.report().sources,1);
});
test('fixtures never enter source registry or evaluation metrics',t=>{
 const x=setup(t);x.team.init('fixture',{...scope,mode:'fixture'});for(let i=0;i<5;i++){const p=x.team.next('fixture');x.team.record('fixture',fixtureArtifact(p),p.leaseId);}
 assert.equal(x.memory.report().sources,0);assert.equal(x.memory.report().evaluated,0);
});
test('feedback is idempotent and evaluation counts distinct jobs rather than repeated votes',t=>{
 const x=setup(t);complete(x.team);const gapId=x.memory.addGap({...scope,priority:40});
 const data={eventId:'first-correct',jobId:'real',verdict:'correct',reason:'원문 근거와 적용 조건을 직접 확인함',sourceUrls:[url],gapId};
 x.memory.feedback(data);x.memory.feedback(data);x.memory.feedback({...data,eventId:'same-job-correct-again'});
 assert.equal(x.memory.report().evaluated,1);assert.equal(x.memory.load().sources[url].correct,1);
 assert.throws(()=>x.memory.feedback({...data,reason:'different'}),/reused/);
 x.memory.feedback({...data,eventId:'field-helpful',verdict:'helpful'});assert.equal(x.memory.report().helpfulRate,1);assert.equal(x.memory.load().sources[url].correct,1);assert.equal(x.memory.load().gaps[gapId].status,'resolved');
});
test('incorrect results become lessons, repeated research cannot erase disputes, and new jobs freeze context',t=>{
 const x=setup(t);complete(x.team);x.memory.feedback({eventId:'wrong',jobId:'real',verdict:'incorrect',reason:'인계 책임자 부재 상황의 완료 기준이 틀림',sourceUrls:[url]});
 assert.equal(x.memory.load().sources[url].status,'disputed');assert.equal(x.memory.report().lessons,1);
 x.team.init('next',scope);const first=x.team.next('next');assert.equal(first.learning.sources[0].status,'disputed');assert.equal(first.learning.lessons.length,1);
 x.team.record('next',artifact(first),first.leaseId);assert.equal(x.memory.load().sources[url].status,'disputed');
 x.memory.feedback({eventId:'provider-fixed',jobId:'real',verdict:'revalidated',reason:'정정된 원문과 적용 범위를 독립적으로 재확인함',sourceUrls:[url]});
 const nextStage=x.team.next('next');assert.equal(nextStage.learning.sources[0].status,'disputed'); // frozen original context
 x.team.init('later',scope);assert.equal(x.team.next('later').learning.sources[0].status,'provider_checked');
});
test('stale sources are flagged, unsafe sources and fabricated future retrieval dates are rejected',t=>{
 const x=setup(t);complete(x.team);x.advance(36);assert.equal(x.memory.context(scope).sources[0].stale,true);
 assert.throws(()=>sourceUrl('https://127.0.0.1/private'));assert.throws(()=>sourceUrl('https://public.example.com/?token=secret'));
 x.team.init('future',scope);const p=x.team.next('future'),v=artifact(p);v.result.sources[0].retrievedAt='2099-01-01T00:00:00Z';assert.throws(()=>x.team.record('future',v,p.leaseId),/retrieval date/);
});
test('network check separates reachable quotation from facts, missing evidence and blocked targets',async()=>{
 const source={url,observations:{one:{excerpt:'짧은 검증 근거'}}};const resolver=async()=>[{address:'93.184.216.34'}];
 let result=await checkSource(source,{resolver,fetcher:async()=>new Response('<p>짧은 검증 근거</p>',{headers:{'content-type':'text/html'}})});assert.equal(result.status,'reachable');assert.equal(result.excerptMatched,true);
 result=await checkSource(source,{resolver,fetcher:async()=>new Response('changed',{headers:{'content-type':'text/html'}})});assert.equal(result.excerptMatched,false);
 result=await checkSource(source,{resolver,fetcher:async()=>new Response('',{status:404})});assert.equal(result.status,'missing');
 result=await checkSource(source,{resolver:async()=>[{address:'127.0.0.1'}],fetcher:()=>{throw Error('Must not fetch');}});assert.equal(result.status,'blocked');
 result=await checkSource(source,{resolver,fetcher:async()=>new Response('',{status:302,headers:{location:'http://localhost/private'}})});assert.equal(result.status,'error');
});
test('weekly cycle runs one gap once, records learning, resumes across weeks and never publishes',async t=>{
 const x=setup(t);let calls=0;
 const cycle=new ContentCycle({root:x.root,now:x.clock,runner:async p=>{calls++;return artifact(p);},catalogLoader:async()=>({revision:1,release:manualCatalog})});
 cycle.configure({cadence:'weekly',maxCallsPerTick:1});cycle.memory.addGap({...scope,priority:50});
 const a=await cycle.tick();assert.equal(a.status,'running');assert.equal(calls,1);
 const b=await cycle.tick();assert.equal(b.jobId,a.jobId);assert.equal(calls,2);
 x.advance(7);cycle.configure({cadence:'weekly',maxCallsPerTick:5});const c=await cycle.tick();assert.equal(c.jobId,a.jobId);assert.equal(c.status,'complete');assert.equal(calls,5);
 assert.equal((await cycle.tick()).repeated,true);assert.equal(calls,5);
 const request=JSON.parse(readFileSync(join(x.root,a.jobId,'draft-request.json')));assert.equal(request.revision,0);
 const provenance=JSON.parse(readFileSync(join(x.root,a.jobId,'draft-request.provenance.json')));assert.equal(provenance.publishAllowed,false);
 x.advance(7);const d=await cycle.tick();assert.notEqual(d.jobId,a.jobId);assert.equal(d.status,'complete');
});
test('cycle missing DB, disabled configuration and KST boundaries cannot create stale duplicate jobs',async t=>{
 const x=setup(t);const cycle=new ContentCycle({root:x.root,now:x.clock});assert.equal((await cycle.tick()).status,'disabled');cycle.configure({cadence:'daily'});cycle.memory.addGap({...scope,priority:50});await assert.rejects(cycle.tick(),/catalog loader/);
 assert.equal(cycleKey(Date.parse('2026-10-07T16:00:00Z'),'daily'),'2026-10-08');assert.equal(cycleKey(Date.parse('2026-10-07T16:00:00Z'),'weekly'),'2026-10-05');
});
test('manual request works with scheduling disabled and repeated request ID does not run twice',async t=>{
 const x=setup(t);let calls=0;const cycle=new ContentCycle({root:x.root,now:x.clock,runner:async p=>{calls++;return artifact(p);},catalogLoader:async()=>({revision:1,release:manualCatalog})});
 cycle.configure();cycle.memory.addGap({...scope,priority:50});assert.equal((await cycle.tick()).status,'disabled');
 const a=await cycle.tick({manual:true,requestId:'operator-request-001'});assert.equal(a.status,'complete');assert.equal(calls,5);assert.equal(cycle.config().enabled,false);
 assert.equal((await cycle.tick({manual:true,requestId:'operator-request-001'})).repeated,true);assert.equal(calls,5);
});
test('cross-jurisdiction evidence is retained with a warning rather than silently adopted as local law',t=>{
 const x=setup(t);x.team.init('foreign',scope);
 for(let i=0;i<5;i++){const p=x.team.next('foreign'),a=artifact(p);if(p.role==='researcher')a.result.sources[0].jurisdiction='UK';x.team.record('foreign',a,p.leaseId);}
 const source=x.memory.context(scope).sources[0];assert.equal(source.crossJurisdiction,true);assert.equal(source.jurisdiction,'UK');assert.equal(source.status,'candidate');
});
test('later successful probes replace transient failures and feedback cannot reference another gap',t=>{
 const x=setup(t);complete(x.team);
 x.memory.check({url,status:'reachable',contentHash:'a'.repeat(64),excerptMatched:true});
 x.memory.check({url,status:'error'});x.memory.check({url,status:'reachable',contentHash:'a'.repeat(64),excerptMatched:true});
 assert.equal(x.memory.load().checks[url].status,'reachable');
 const other=x.memory.addGap({...scope,gap:'different field case',priority:50});
 assert.throws(()=>x.memory.feedback({eventId:'wrong-gap',jobId:'real',verdict:'helpful',reason:'평가 대상 확인',gapId:other}),/does not match/);
 assert.throws(()=>x.memory.feedback({eventId:'wrong-source',jobId:'real',verdict:'correct',reason:'원문 확인',sourceUrls:['https://other.example.com']}),/not observed/);
});
test('object prototype names cannot invent evaluated jobs or bypass feedback idempotency',t=>{
 const x=setup(t);assert.throws(()=>x.memory.feedback({eventId:'fake',jobId:'constructor',verdict:'correct',reason:'검증 대상 없음'}),/ingested real job/);
 complete(x.team);const data={eventId:'__proto__',jobId:'real',verdict:'correct',reason:'원문과 적용 조건 확인'};x.memory.feedback(data);x.memory.feedback(data);assert.equal(x.memory.report().evaluated,1);
 assert.throws(()=>x.memory.feedback({...data,reason:'changed'}),/reused/);
});
test('source freshness compares actual instants across different timestamp offsets',t=>{
 const x=setup(t);x.team.init('offset-one',scope);let p=x.team.next('offset-one'),a=artifact(p);a.result.sources[0].retrievedAt='2026-10-07T13:00:00+09:00';x.team.record('offset-one',a,p.leaseId);
 x.advance(1);x.team.init('offset-two',scope);p=x.team.next('offset-two');a=artifact(p);a.result.sources[0].retrievedAt='2026-10-07T05:00:00Z';x.team.record('offset-two',a,p.leaseId);assert.equal(x.memory.load().sources[url].lastRetrievedAt,'2026-10-07T05:00:00Z');
});
