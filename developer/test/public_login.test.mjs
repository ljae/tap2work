import test from 'node:test';
import assert from 'node:assert/strict';
import {createPublicLoginHandler} from '../public_login.mjs';
const request = (method='POST', origin='https://tap2.work') => new Request('https://example.test', {method, headers:{origin}, ...(method==='POST'?{body:JSON.stringify({email:'attacker@example.test'})}:{})});
test('public login uses server-selected existing identity and does not send email or passwords', async()=>{
  const calls=[];
  const handler=createPublicLoginHandler({url:'https://backend.test',serviceKey:'secret',email:'fixed@example.test',enabled:true,fetcher:async(url,options)=>{
    calls.push({url,body:JSON.parse(options.body)});
    return Response.json(url.includes('rpc/')?'fixed-id':url.includes('generate_link')?{id:'fixed-id',hashed_token:'hash'}:{user:{id:'fixed-id'},refresh_token:'refresh'});
  }});
  const response=await handler(request());
  assert.equal(response.status,200);assert.equal(response.headers.get('cache-control'),'no-store');
  assert.deepEqual(await response.json(),{refresh_token:'refresh'});
  assert.equal(calls[1].body.email,'fixed@example.test');assert.equal(calls.length,3);
});
test('disabled, foreign-origin and wrong identity fail closed',async()=>{
  const base={url:'https://backend.test',serviceKey:'secret',email:'fixed@example.test'};
  assert.equal((await createPublicLoginHandler(base)(request())).status,503);
  assert.equal((await createPublicLoginHandler({...base,enabled:true})(request('POST','https://bad.test'))).status,403);
  let calls=0;
  const handler=createPublicLoginHandler({...base,enabled:true,fetcher:async()=>Response.json(++calls===1?'fixed-id':{id:'different',hashed_token:'hash'})});
  assert.equal((await handler(request())).status,502);assert.equal(calls,2);
});
