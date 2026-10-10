// No network/live credentials. PGlite executes real scheduling SQL against
// narrow stubs for hosted-only cron/net/Vault/pgcrypto primitives.
import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import { pathToFileURL } from 'node:url';
const argument = process.argv.find(a => a.startsWith('--pglite-module='));
const { PGlite } = await import(argument ? pathToFileURL(argument.slice('--pglite-module='.length)).href : '@electric-sql/pglite');
const db = new PGlite();
try {
  await db.exec(`
    create role anon; create role authenticated; create role service_role bypassrls;
    grant usage on schema public to anon, authenticated, service_role;
    create schema vault; create schema cron; create schema net; create schema extensions;
    create table vault.decrypted_secrets(name text primary key, decrypted_secret text);
    create table public.tap2work_media_deletions(workspace_id uuid primary key, next_attempt_at timestamptz default now());
    create table cron.job(jobid bigserial primary key, jobname text unique, schedule text, command text, username text default current_user, active boolean default true);
    create function cron.schedule(job_name text, schedule text, command text) returns bigint language sql as $$
      insert into cron.job(jobname,schedule,command) values ($1,$2,$3)
      on conflict (jobname) do update set schedule=excluded.schedule, command=excluded.command returning jobid;
    $$;
    create table net.http_calls(id bigserial primary key, url text, body jsonb, headers jsonb, timeout_milliseconds integer);
    create function net.http_post(url text, body jsonb, headers jsonb, timeout_milliseconds integer) returns bigint language sql as $$
      insert into net.http_calls(url,body,headers,timeout_milliseconds) values ($1,$2,$3,$4) returning id;
    $$;
    create function extensions.hmac(data text, key text, type text) returns bytea language plpgsql as $$
    begin
      if data !~ '^tap2work-manual-media-cleanup:[0-9]{10,12}$' or key <> repeat('a',43) or type <> 'sha256' then
        raise exception 'Unexpected HMAC inputs';
      end if;
      return decode(repeat('ab',32),'hex');
    end $$;
  `);
  const raw = await readFile(new URL('../supabase/migrations/20261010020000_manual_media_schedule.sql', import.meta.url), 'utf8');
  const migration = raw.replace(/^create extension if not exists .+;$/gm, '');
  await db.exec(migration);
  await db.exec(migration); // Safe reapplication never activates/duplicates jobs.
  assert.equal((await db.query('select count(*)::integer as count from cron.job')).rows[0].count, 0);
  await assert.rejects(db.query('select public.tap2work_enable_media_cleanup()'), /Vault configuration/);
  for (const role of ['anon', 'authenticated']) {
    await db.exec(`set role ${role}`);
    await assert.rejects(db.query('select public.tap2work_enable_media_cleanup()'), /permission denied/);
    await assert.rejects(db.query('select public.tap2work_request_media_cleanup()'), /permission denied/);
    await db.exec('reset role');
  }
  await db.exec("insert into vault.decrypted_secrets values ('tap2work_media_cleanup_url','https://example.supabase.co/functions/v1/manual-media-cleanup'),('tap2work_media_cleanup_token',repeat('a',43));");
  await db.exec('set role service_role');
  await db.query('select public.tap2work_enable_media_cleanup()');
  await db.query('select public.tap2work_enable_media_cleanup()');
  assert.equal((await db.query('select public.tap2work_request_media_cleanup() as id')).rows[0].id, null);
  await db.exec('reset role');
  const jobs = (await db.query('select * from cron.job')).rows;
  assert.equal(jobs.length, 1); assert.equal(jobs[0].schedule, '*/5 * * * *');
  assert.equal(jobs[0].command, 'select public.tap2work_request_media_cleanup();');
  assert.equal(jobs[0].username, 'postgres');
  assert.equal((await db.query('select count(*)::integer as count from net.http_calls')).rows[0].count, 0);
  await db.exec("insert into public.tap2work_media_deletions(workspace_id) values ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa');");
  await db.exec('set role service_role');
  await db.query('select public.tap2work_request_media_cleanup()');
  await db.exec('reset role');
  const call = (await db.query('select * from net.http_calls')).rows[0];
  assert.deepEqual(call.body, {}); assert.equal(call.timeout_milliseconds, 55000);
  assert.match(call.headers.Authorization, /^Bearer [0-9]{10,12}\.[a-f0-9]{64}$/);
  assert.ok(!JSON.stringify(call).includes('a'.repeat(43)));
  assert.equal(call.url, 'https://example.supabase.co/functions/v1/manual-media-cleanup');
  await db.exec("update vault.decrypted_secrets set decrypted_secret='https://evil.invalid/functions/v1/manual-media-cleanup' where name='tap2work_media_cleanup_url';");
  await assert.rejects(db.query('select public.tap2work_request_media_cleanup()'), /Vault configuration/);
  console.log('Managed cleanup SQL passed: idempotency, service-only calls, explicit activation, fixed cron scope, empty-queue skip and no reusable secret in HTTP headers. Hosted extensions were stubbed.');
} finally { await db.close(); }
