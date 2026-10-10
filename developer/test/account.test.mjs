import test from 'node:test';
import assert from 'node:assert/strict';
import {createAccountHandler} from '../account_backend.mjs';
import {eraseMemberData} from '../account_erasure.mjs';
import {revokeApple,appleClientSecret} from '../apple_revoke.mjs';
const uid='10000000-0000-0000-0000-000000000001';
const user={id:uid,email:'test@example.invalid',identities:[{provider:'google'}]};
const own={id:'crew-1',actorId:uid,nickname:'Test Crew',phone:'010-test',hourlyWon:15000};
function fixture({role='crew',ownerCount=1,revoker=async()=>{}, conflict=false, unauthorized=false}={}) {
 const calls=[];
 const context={scope:{userId:uid,workspaceId:'store',workspaceName:'Test',role,ownerCount,memberCount:3,revision:1},payload:{revision:1,tappers:[own],attendance:[{tapperId:own.id}]}};
 const handler=createAccountHandler({url:'https://example.invalid',serviceKey:'test-server-secret',appleRevoker:revoker,fetcher:async(url,options)=>{
   calls.push({url,options});
   if(url.endsWith('/user'))return Response.json(user,{status:unauthorized?401:200});
   if(url.endsWith('tap2work_account_context'))return Response.json(context);
   if(url.includes('/tap2work_media_deletions?'))return Response.json([]);
   if(url.endsWith('tap2work_erase_account'))return Response.json(conflict?{conflict:true}:{deleted:true});
   throw Error('Unexpected request');
 }});
 const request=(body,headers={})=>handler(new Request('https://example.invalid/account',{method:'POST',headers:{Authorization:'Bearer test-user','Content-Type':'application/json',...headers},body:JSON.stringify(body)}));
 return {request,calls,context};
}
test('preview is authenticated and exposes only deletion scope',async()=>{
 const f=fixture({role:'owner'}); const r=await f.request({action:'preview_delete'}); const data=await r.json();
 assert.equal(r.status,200);assert.equal(data.destroysWorkspace,true);assert.equal(data.memberCount,3);assert.equal(data.confirmationToken.length,64);assert.equal(data.payload,undefined);assert.equal(f.calls.length,2);
 const denied=fixture({unauthorized:true});assert.equal((await denied.request({action:'preview_delete'})).status,401);assert.equal(denied.calls.length,1);
});
test('sole owner requires confirmation; user identity is never caller-controlled',async()=>{
 const f=fixture({role:'owner'}); const p=await (await f.request({action:'preview_delete'})).json();
 assert.equal((await f.request({action:'delete_account',confirmationToken:p.confirmationToken})).status,400);
 assert.equal((await f.request({action:'delete_account',userId:'other'})).status,400);
 const r=await f.request({action:'delete_account',confirmationToken:p.confirmationToken,confirmWorkspaceDeletion:true});assert.equal(r.status,200);
 const body=JSON.parse(f.calls.find(c=>c.url.endsWith('tap2work_erase_account')).options.body);assert.equal(body.p_user_id,uid);assert.equal(body.p_delete_workspace,true);assert.equal(body.p_sanitized_payload,null);
});
test('stale preview and SQL conflict never report success',async()=>{
 const f=fixture();const p=await (await f.request({action:'preview_delete'})).json();f.context.scope.revision++;
 assert.equal((await f.request({action:'delete_account',confirmationToken:p.confirmationToken})).status,409);
 assert.ok(!f.calls.some(c=>c.url.endsWith('tap2work_erase_account')));
 const g=fixture({conflict:true});const q=await (await g.request({action:'preview_delete'})).json();assert.equal((await g.request({action:'delete_account',confirmationToken:q.confirmationToken})).status,409);
});
test('crew deletes own personal data while keeping store; Apple failure prevents DB erasure',async()=>{
 const f=fixture();const p=await (await f.request({action:'preview_delete'})).json();assert.equal((await f.request({action:'delete_account',confirmationToken:p.confirmationToken})).status,200);
 const body=JSON.parse(f.calls.find(c=>c.url.endsWith('tap2work_erase_account')).options.body);assert.equal(body.p_delete_workspace,false);assert.deepEqual(body.p_sanitized_payload.attendance,[]);
 const g=fixture({revoker:async()=>{throw Error('private provider details');}});const q=await (await g.request({action:'preview_delete'})).json();const failed=await g.request({action:'delete_account',confirmationToken:q.confirmationToken});assert.equal(failed.status,500);assert.ok(!(await failed.text()).includes('private'));assert.ok(!g.calls.some(c=>c.url.endsWith('tap2work_erase_account')));
});
test('untrusted origin is refused before authentication',async()=>{const f=fixture();assert.equal((await f.request({action:'preview_delete'},{Origin:'https://attacker.invalid'})).status,403);assert.equal(f.calls.length,0);});
test('erasure covers historical personal rows and mapped assignment slots without mutating input',()=>{
 const input={revision:8,tappers:[own,{id:'other',nickname:'Other',hourlyWon:9000}],attendance:[{tapperId:'crew-1'},{tapperId:'other'}],shiftChangeRequests:[{tapperId:'crew-1',reason:'private'}],tasks:[{id:'task',completedBy:uid,note:'Test Crew completed'}],operationEditHistory:[{value:{staffShifts:[{tapperId:'crew-1',private:'data'},{tapperId:'other'}]}}],workplace:{bands:[{crewIds:{kitchen:['crew-1','other']}}]}};
 const result=eraseMemberData(input,user);assert.equal(input.tappers[0].hourlyWon,15000);assert.equal(result.tappers[0].hourlyWon,undefined);assert.equal(result.tappers[1].hourlyWon,9000);assert.deepEqual(result.attendance,[{tapperId:'other'}]);assert.deepEqual(result.shiftChangeRequests,[]);assert.equal(result.tasks.length,1);assert.ok(!JSON.stringify(result).includes(uid));assert.ok(!JSON.stringify(result).includes('Test Crew'));assert.deepEqual(result.operationEditHistory[0].value.staffShifts,[{tapperId:'other'}]);assert.deepEqual(result.workplace.bands[0].crewIds.kitchen,[null,'other']);
});
const appleUser={...user,identities:[{provider:'apple',identity_data:{sub:'apple-user'}}]};
const config={bundleId:'com.tap2work.tap2work',serviceId:'web',teamId:'TEAM',keyId:'KEY',privateKey:'mock'};
const jwt=claims=>`head.${Buffer.from(JSON.stringify(claims)).toString('base64url')}.sig`;
test('Apple exchange verifies subject before revoke and never trusts caller tokens alone',async()=>{
 const calls=[];const fetcher=async(url,opts)=>{calls.push({url,body:new URLSearchParams(opts.body)});return url.endsWith('/token')?Response.json({id_token:jwt({sub:'apple-user',aud:config.bundleId,iss:'https://appleid.apple.com',exp:4102444800}),refresh_token:'provider-refresh'}):new Response(null,{status:200});};
 await revokeApple(appleUser,{appleClient:'native',appleCode:'code'},{config,fetcher,secret:async()=> 'signed'});assert.equal(calls.length,2);assert.equal(calls[1].body.get('token'),'provider-refresh');
 await assert.rejects(revokeApple({...appleUser,identities:[{provider:'apple',identity_data:{sub:'other'}}]},{appleClient:'native',appleCode:'code'},{config,fetcher,secret:async()=> 'signed'}),e=>e.status===403);assert.equal(calls.length,3);
});
test('Apple missing configuration/code fails closed; Google does not require Apple',async()=>{
 await revokeApple(user,{},{});
 await assert.rejects(revokeApple(appleUser,{},{}),e=>e.status===503);
 await assert.rejects(revokeApple(appleUser,{appleClient:'native'},{config}),e=>e.status===400);
});
test('Apple client secret is a verifiable short-lived ES256 JWT',async()=>{
 const keys=await crypto.subtle.generateKey({name:'ECDSA',namedCurve:'P-256'},true,['sign','verify']);
 const pk=Buffer.from(await crypto.subtle.exportKey('pkcs8',keys.privateKey)).toString('base64');
 const signed=await appleClientSecret({...config,privateKey:`-----BEGIN PRIVATE KEY-----\n${pk}\n-----END PRIVATE KEY-----`},config.bundleId,new Date('2026-10-05T00:00:00Z'));
 const [head,body,sig]=signed.split('.');const claims=JSON.parse(Buffer.from(body,'base64url'));assert.equal(claims.exp-claims.iat,300);assert.equal(claims.sub,config.bundleId);assert.equal(await crypto.subtle.verify({name:'ECDSA',hash:'SHA-256'},keys.publicKey,Buffer.from(sig,'base64url'),new TextEncoder().encode(`${head}.${body}`)),true);
});

test('production operations rejects legacy shared sessions before reading any store',async()=>{
 const {createCloudHandler}=await import('../supabase_backend.mjs');let count=0;
 const handler=createCloudHandler({url:'https://example.invalid',serviceKey:'server',requireSocialIdentity:true,fetcher:async()=>{count++;return Response.json({...user,identities:[{provider:'email'}]});}});
 const response=await handler(new Request('https://example.invalid/operations',{headers:{Authorization:'Bearer old-shared-session'}}));
 assert.equal(response.status,403);assert.equal(count,1);
});

test('names cannot rewrite schema keys, role values or opaque crew IDs',()=>{
 const result=eraseMemberData({revision:1,tappers:[{id:'crew-1',actorId:uid,nickname:'crew'},{id:'crew-other',rank:'crew',nickname:'Alex'}],staffShifts:[{id:'crew-shift',tapperId:'crew-other',status:'planned'}]},user);
 assert.equal(result.tappers[1].id,'crew-other');assert.equal(result.tappers[1].rank,'crew');assert.equal(result.staffShifts[0].tapperId,'crew-other');assert.equal(result.staffShifts[0].id,'crew-shift');
});

test('multi-store deletion previews every store and scrubs only surviving stores',async()=>{
 const f=fixture({role:'owner'});const first=f.context.scope;
 f.context.scope={userId:uid,workspaces:[first,{...first,workspaceId:'shared',workspaceName:'Shared',ownerCount:2}]};
 f.context.payloads={shared:f.context.payload};delete f.context.payload;
 const preview=await(await f.request({action:'preview_delete'})).json();
 assert.equal(preview.workspaces.length,2);assert.equal(preview.workspaces[0].destroysWorkspace,true);assert.equal(preview.workspaces[1].destroysWorkspace,false);
 assert.equal((await f.request({action:'delete_account',confirmationToken:preview.confirmationToken,confirmWorkspaceDeletion:true})).status,200);
 const sent=JSON.parse(f.calls.find(c=>c.url.endsWith('tap2work_erase_account')).options.body);assert.deepEqual(Object.keys(sent.p_sanitized_payload),['shared']);assert.deepEqual(sent.p_sanitized_payload.shared.attendance,[]);
});
