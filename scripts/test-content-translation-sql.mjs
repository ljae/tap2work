// Isolated PGlite verification; never reads credentials or contacts production.
import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import { pathToFileURL } from 'node:url';
const argument=process.argv.find(a=>a.startsWith('--pglite-module='));
const {PGlite}=await import(argument?pathToFileURL(argument.slice('--pglite-module='.length)).href:'@electric-sql/pglite');
const db=new PGlite();
const wid='aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',other='bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb',uid='cccccccc-cccc-cccc-cccc-cccccccccccc',second='dddddddd-dddd-dddd-dddd-dddddddddddd';
try {
 await db.exec(`create role anon; create role authenticated; create role service_role bypassrls;
 create schema auth; create table auth.users(id uuid primary key);
 create table public.tap2work_workspaces(id uuid primary key);
 create table public.tap2work_members(workspace_id uuid references public.tap2work_workspaces(id) on delete cascade,user_id uuid references auth.users(id) on delete cascade);
 insert into auth.users values ('${uid}'),('${second}'); insert into public.tap2work_workspaces values ('${wid}'),('${other}');
 insert into public.tap2work_members values ('${wid}','${uid}'),('${wid}','${second}');`);
 const migration=await readFile(new URL('../supabase/migrations/20261010030000_content_translation.sql',import.meta.url),'utf8');
 await db.exec(migration);await db.exec(migration); // Explicit rerun idempotency.
 for(const role of ['anon','authenticated']){
  await db.exec(`set role ${role}`);
  await assert.rejects(db.query('select * from public.tap2work_content_translations'),/permission denied/);
  await assert.rejects(db.query('select * from public.tap2work_translation_budgets'),/permission denied/);
  await assert.rejects(db.query('select public.tap2work_reserve_translation($1,$2,100)',[wid,uid]),/permission denied/);
  await db.exec('reset role');
 }
 await db.exec('set role service_role');
 const reserve=async(workspace,user,chars)=>(await db.query('select public.tap2work_reserve_translation($1,$2,$3) as allowed',[workspace,user,chars])).rows[0].allowed;
 assert.equal(await reserve(other,uid,100),false);assert.equal(await reserve(wid,uid,20001),false);
 for(let i=0;i<20;i++)assert.equal(await reserve(wid,uid,100),true);
 assert.equal(await reserve(wid,uid,100),false); // Atomic per-actor minute ceiling.
 assert.equal(await reserve(wid,second,100),true);
 await db.query("update public.tap2work_translation_budgets set minute_start=now()-interval '2 minutes',day_characters=99999 where scope=$1",[uid]);
 assert.equal(await reserve(wid,uid,2),false);assert.equal(await reserve(wid,uid,1),true);
 await db.query("update public.tap2work_translation_budgets set minute_start=now()-interval '2 minutes',day_characters=199999 where scope='*'");
 assert.equal(await reserve(wid,second,2),false);assert.equal(await reserve(wid,second,1),true);
 const hash='a'.repeat(64);
 await db.query('insert into public.tap2work_content_translations(workspace_id,source_hash,target_locale,translated) values ($1,$2,$3,$4)',[wid,hash,'vi',{title:'private store text'}]);
 await db.exec('reset role');
 await db.query('delete from auth.users where id=$1',[uid]);
 assert.equal((await db.query('select count(*)::integer as n from public.tap2work_translation_budgets where user_id=$1',[uid])).rows[0].n,0);
 await db.exec('begin');await db.query('delete from public.tap2work_workspaces where id=$1',[wid]);await db.exec('rollback');
 assert.equal((await db.query('select count(*)::integer as n from public.tap2work_content_translations')).rows[0].n,1);
 await db.query('delete from public.tap2work_workspaces where id=$1',[wid]);
 for(const table of ['tap2work_content_translations','tap2work_translation_budgets'])assert.equal((await db.query(`select count(*)::integer as n from public.${table}`)).rows[0].n,0);
 console.log('Translation SQL: idempotency, service-only access, membership, atomic minute/daily budgets and transactional account/workspace deletion passed.');
} finally {await db.close();}
