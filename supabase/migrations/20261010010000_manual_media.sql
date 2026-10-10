begin;

-- Immutable optimized photos. Access goes through the operations Edge Function,
-- which validates Auth, workspace membership and manager editing restrictions.
-- No public/authenticated object policies: clients cannot bypass JPEG validation.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('tap2work-manual-media', 'tap2work-manual-media', false, 250000, array['image/jpeg'])
on conflict (id) do update set public = false,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

-- Restrictive policies defend this bucket even if another bucket has a broad
-- permissive policy. The service role used only inside the Edge bypasses RLS.
drop policy if exists tap2work_manual_media_service_only on storage.objects;
create policy tap2work_manual_media_service_only on storage.objects
as restrictive for all to anon, authenticated
using (bucket_id <> 'tap2work-manual-media')
with check (bucket_id <> 'tap2work-manual-media');

-- A transactional, durable erasure queue survives auth account deletion and
-- Storage outages. No FK: the workspace itself has already been removed.
create table if not exists public.tap2work_media_deletions (
  workspace_id uuid primary key,
  requested_at timestamptz not null default now(),
  last_attempt_at timestamptz,
  next_attempt_at timestamptz not null default now()
);
alter table public.tap2work_media_deletions enable row level security;
revoke all on public.tap2work_media_deletions from public, anon, authenticated;
grant all on public.tap2work_media_deletions to service_role;

create or replace function public.tap2work_queue_media_erasure()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  insert into public.tap2work_media_deletions(workspace_id) values (old.id)
  on conflict (workspace_id) do update set next_attempt_at = now();
  return old;
end $$;
revoke all on function public.tap2work_queue_media_erasure() from public, anon, authenticated;
drop trigger if exists tap2work_workspace_media_erasure on public.tap2work_workspaces;
create trigger tap2work_workspace_media_erasure
after delete on public.tap2work_workspaces
for each row execute function public.tap2work_queue_media_erasure();

notify pgrst, 'reload schema';

commit;
