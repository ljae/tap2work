// Isolated SQL harness; no live DB or credentials. Same optional PGlite module
// argument as test-content-catalog-sql.mjs.
import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import { pathToFileURL } from 'node:url';
const argument = process.argv.find(a => a.startsWith('--pglite-module='));
const { PGlite } = await import(argument ? pathToFileURL(argument.slice('--pglite-module='.length)).href : '@electric-sql/pglite');
const db = new PGlite();
try {
  await db.exec(`
    create role anon; create role authenticated; create role service_role bypassrls;
    create schema storage;
    grant usage on schema storage, public to anon, authenticated, service_role;
    create table storage.buckets(id text primary key, name text, public boolean, file_size_limit bigint, allowed_mime_types text[]);
    create table storage.objects(id uuid primary key default gen_random_uuid(), bucket_id text, name text);
    alter table storage.objects enable row level security;
    grant all on storage.objects to anon, authenticated, service_role;
    create policy unrelated_broad_policy on storage.objects for all to anon, authenticated using(true) with check(true);
    create table public.tap2work_workspaces(id uuid primary key);
  `);
  await db.exec(await readFile(new URL('../supabase/migrations/20261010010000_manual_media.sql', import.meta.url), 'utf8'));
  const bucket = (await db.query("select * from storage.buckets where id='tap2work-manual-media'")).rows[0];
  assert.equal(bucket.public, false); assert.equal(Number(bucket.file_size_limit), 250000);
  assert.deepEqual(bucket.allowed_mime_types, ['image/jpeg']);
  await db.exec("insert into storage.objects(bucket_id,name) values ('tap2work-manual-media','private.jpg'),('other-bucket','public.jpg');");
  for (const role of ['anon', 'authenticated']) {
    await db.exec(`set role ${role}`);
    assert.equal((await db.query('select count(*)::integer as count from storage.objects')).rows[0].count, 1);
    await assert.rejects(db.exec("insert into storage.objects(bucket_id,name) values ('tap2work-manual-media','forged.jpg')"), /row-level security/);
    await assert.rejects(db.query('select * from public.tap2work_media_deletions'), /permission denied/);
    await db.exec('reset role');
  }
  const wid = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
  await db.exec(`insert into public.tap2work_workspaces values ('${wid}')`);
  await db.exec('begin');
  await db.exec(`delete from public.tap2work_workspaces where id='${wid}'`);
  await db.exec('rollback');
  assert.equal((await db.query('select count(*)::integer as count from public.tap2work_media_deletions')).rows[0].count, 0);
  await db.exec(`delete from public.tap2work_workspaces where id='${wid}'`);
  await db.exec(await readFile(new URL('../supabase/migrations/20261010010000_manual_media.sql', import.meta.url), 'utf8'));
  await db.exec('set role service_role');
  assert.equal((await db.query('select workspace_id from public.tap2work_media_deletions')).rows[0].workspace_id, wid);
  assert.equal((await db.query("select count(*)::integer as count from storage.objects where bucket_id='tap2work-manual-media'")).rows[0].count, 1);
  console.log('Private bucket limits, broad-policy isolation, service access and transactional deletion queue passed.');
} finally { await db.close(); }
