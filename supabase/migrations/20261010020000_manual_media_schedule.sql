begin;

-- Hosted Supabase managed scheduling; secrets are provisioned separately in
-- Vault and Edge. Applying this migration does not activate a cron job.
create extension if not exists pg_cron;
create extension if not exists pg_net;
create extension if not exists pgcrypto with schema extensions;
-- Vault is installed by hosted Supabase. Fail clearly before activation if the
-- platform lacks it, rather than copying credentials into a cron command.
do $$ begin
  if to_regclass('vault.decrypted_secrets') is null then
    raise exception 'Supabase Vault is required for manual media cleanup';
  end if;
end $$;

create or replace function public.tap2work_request_media_cleanup()
returns bigint language plpgsql security definer set search_path = '' as $$
declare endpoint text; token text; request_id bigint; stamp text; signature text;
begin
  select decrypted_secret into endpoint from vault.decrypted_secrets where name='tap2work_media_cleanup_url';
  select decrypted_secret into token from vault.decrypted_secrets where name='tap2work_media_cleanup_token';
  if endpoint is null or endpoint !~ '^https://[a-z0-9]+\.supabase\.co/functions/v1/manual-media-cleanup$'
     or token is null or length(token) not between 43 and 256 or token !~ '^[A-Za-z0-9_-]+$' then
    raise exception 'Manual media cleanup Vault configuration is missing or invalid';
  end if;
  -- Do not start Edge invocations for an empty/not-yet-due queue.
  if not exists(select 1 from public.tap2work_media_deletions where next_attempt_at <= now()) then return null; end if;
  -- Never enqueue the reusable Vault secret: pg_net queue headers may be
  -- readable by database roles. The MAC expires after five minutes.
  stamp := floor(extract(epoch from now()))::bigint::text;
  signature := encode(extensions.hmac('tap2work-manual-media-cleanup:' || stamp, token, 'sha256'), 'hex');
  select net.http_post(
    url := endpoint,
    headers := jsonb_build_object('Content-Type','application/json','Authorization','Bearer ' || stamp || '.' || signature),
    body := '{}'::jsonb,
    timeout_milliseconds := 55000
  ) into request_id;
  return request_id;
end $$;
alter function public.tap2work_request_media_cleanup() owner to postgres;
revoke all on function public.tap2work_request_media_cleanup() from public, anon, authenticated;
grant execute on function public.tap2work_request_media_cleanup() to service_role;

-- Call only after the Edge endpoint, matching secret and Vault URL/token are
-- deployed and verified. Named cron.schedule updates its job idempotently.
create or replace function public.tap2work_enable_media_cleanup()
returns bigint language plpgsql security definer set search_path = '' as $$
declare endpoint text; token text; job_id bigint;
begin
  select decrypted_secret into endpoint from vault.decrypted_secrets where name='tap2work_media_cleanup_url';
  select decrypted_secret into token from vault.decrypted_secrets where name='tap2work_media_cleanup_token';
  if endpoint is null or endpoint !~ '^https://[a-z0-9]+\.supabase\.co/functions/v1/manual-media-cleanup$'
     or token is null or length(token) not between 43 and 256 or token !~ '^[A-Za-z0-9_-]+$' then
    raise exception 'Manual media cleanup Vault configuration is missing or invalid';
  end if;
  select cron.schedule('tap2work-manual-media-cleanup', '*/5 * * * *',
    'select public.tap2work_request_media_cleanup();') into job_id;
  return job_id;
end $$;
alter function public.tap2work_enable_media_cleanup() owner to postgres;
revoke all on function public.tap2work_enable_media_cleanup() from public, anon, authenticated;
grant execute on function public.tap2work_enable_media_cleanup() to service_role;

notify pgrst, 'reload schema';
commit;
