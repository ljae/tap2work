// A privileged administrator explicitly provisions provider identities.
// Workspace owners never inherit these central-content roles automatically.
const args=process.argv.slice(2);
const user=args[args.indexOf('--user')+1],role=args[args.indexOf('--role')+1];
if(!args.includes('--user')||!args.includes('--role')||!args.includes('--execute')||!/^[\da-f]{8}-[\da-f]{4}-[\da-f]{4}-[\da-f]{4}-[\da-f]{12}$/i.test(user??'')||!['researcher','editor','reviewer','publisher'].includes(role))throw Error('Usage: grant-catalog-role --user <Auth UUID> --role <role> --execute');
const ref=process.env.SUPABASE_PROJECT_REF,token=process.env.SUPABASE_ACCESS_TOKEN;
if(!ref||!token)throw Error('Privileged Supabase admin environment required');
const query=`insert into public.tap2work_catalog_roles(user_id,role) select id,'${role}' from auth.users where id='${user}'::uuid on conflict do nothing; select role from public.tap2work_catalog_roles where user_id='${user}'::uuid order by role;`;
const response=await fetch(`https://api.supabase.com/v1/projects/${ref}/database/query`,{method:'POST',headers:{Authorization:`Bearer ${token}`,'Content-Type':'application/json'},body:JSON.stringify({query})});
if(!response.ok)throw Error(`Provider role provisioning failed: HTTP ${response.status}`);
const result=await response.json();if(!result.some(x=>x.role===role))throw Error('Auth account not found');
console.log(`Provider role ${role} registered for the specified existing account.`);
