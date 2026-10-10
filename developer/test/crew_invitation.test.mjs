import test from 'node:test';
import assert from 'node:assert/strict';
import {createCloudHandler} from '../supabase_backend.mjs';
import {invitationHash} from '../crew_invitation.mjs';
import {emptyOperations} from '../operations.mjs';
const uid='aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',wid='bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb';
function fixture(){
 const calls=[];let result={id:'created',expiresAt:'2026-10-17T12:00:00Z',tapperId:'target'},social=true;
 const handler=createCloudHandler({url:'https://example.supabase.co',serviceKey:'fixture',sectionStorage:true,requireSocialIdentity:true,fetcher:async(url,options)=>{
  if(url.endsWith('/auth/v1/user'))return Response.json({id:uid,identities:social?[{provider:'google'}]:[]});
  assert.ok(url.endsWith('/rpc/tap2work_crew_invitation'),'invite routing must precede ordinary workspace bootstrap/catalog reads');calls.push(JSON.parse(options.body));return Response.json(result);
 }});
 return {calls,setResult:value=>result=value,setSocial:value=>social=value,request:input=>handler(new Request('https://example.invalid/operations?invite=crew',{method:'POST',headers:{Authorization:'Bearer session','Content-Type':'application/json'},body:JSON.stringify(input)}))};
}
test('authenticated invite route binds identity, stores only token hash, and returns an explicit shareable code',async()=>{
 const f=fixture();const response=await f.request({action:'create',workspaceId:wid,tapperId:'target',revision:4,userId:'forged'});assert.equal(response.status,200);
 const body=await response.json();assert.match(body.code,/^[A-F0-9]{4}(?:-[A-F0-9]{4}){5}$/);assert.equal(f.calls[0].p_user_id,uid);assert.equal(f.calls[0].p_token_hash,invitationHash(body.code));assert.ok(!JSON.stringify(f.calls).includes(body.code));assert.ok(body.link.startsWith('https://tap2.work/?invite='));
});
test('recipient must sign in socially and explicitly confirm acceptance; domain failures retain stable codes',async()=>{
 const f=fixture(),code='ABCD'.repeat(6);assert.equal((await f.request({action:'accept',code})).status,400);assert.equal(f.calls.length,0);
 f.setSocial(false);assert.equal((await f.request({action:'preview',code})).status,403);assert.equal(f.calls.length,0);
 f.setSocial(true);f.setResult({errorCode:'INVITATION_USED',status:409});const response=await f.request({action:'accept',code,confirm:true});assert.equal(response.status,409);assert.equal((await response.json()).code,'INVITATION_USED');
 assert.equal(f.calls[0].p_workspace_id,null);assert.equal(f.calls[0].p_user_id,uid);
});
test('malformed IDs/codes cannot reach service RPC and code normalization is stable',async()=>{
 const f=fixture();for(const input of [{action:'create',workspaceId:'other',tapperId:'x',revision:1},{action:'preview',code:'1234'},{action:'revoke',workspaceId:wid,inviteId:'bad',revision:1},{action:'create',workspaceId:wid,tapperId:'x'}])assert.equal((await f.request(input)).status,400);
 assert.equal(f.calls.length,0);assert.equal(invitationHash('abcd-abcd-abcd-abcd-abcd-abcd'),invitationHash('ABCD'.repeat(6)));
});
test('authenticated roster edits use the atomic membership/state CAS RPC with verified owner identity',async()=>{
 const now=new Date('2026-10-10T05:00:00Z');let state=emptyOperations(now,uid);const writes=[];
 const handler=createCloudHandler({url:'https://example.supabase.co',serviceKey:'fixture',sectionStorage:true,clock:()=>now,fetcher:async(url,options={})=>{
  if(url.endsWith('/auth/v1/user'))return Response.json({id:uid});
  const input=JSON.parse(options.body);
  if(url.endsWith('/rpc/tap2work_read_workspace'))return Response.json({member:{workspace_id:wid,role:'owner',display_name:'Owner'},payload:structuredClone(state),window:1});
  if(url.endsWith('/rpc/tap2work_patch_state')||url.endsWith('/rpc/tap2work_patch_crew_state')){
   writes.push({url,input});if(input.p_expected_revision!==state.revision)return Response.json(false);
   for(const key of input.p_removed)delete state[key];Object.assign(state,input.p_changes);state.revision++;return Response.json(true);
  }
  throw Error('Unexpected fixture request');
 }});
 const request=body=>handler(new Request('https://example.invalid/operations',{method:body?'POST':'GET',headers:{Authorization:'Bearer session','Content-Type':'application/json'},...(body?{body:JSON.stringify(body)}:{})}));
 const opening=await(await request()).json();writes.length=0;
 const result=await request({action:'save_tapper',revision:opening.revision,nickname:'Synthetic crew',rank:'crew',employmentType:'시간알바',hourlyWon:10320,payPeriod:'monthly',nationality:'VN',guideLocale:'vi',creationRequestId:'contract-test-creation-001',userId:'forged'});
 assert.equal(result.status,200,await result.clone().text());assert.ok(writes.length);
 assert.ok(writes.every(w=>w.url.endsWith('/rpc/tap2work_patch_crew_state')&&w.input.p_user_id===uid));
 assert.ok(writes.at(-1).input.p_changes.tappers.some(t=>t.nickname==='Synthetic crew'));
});
