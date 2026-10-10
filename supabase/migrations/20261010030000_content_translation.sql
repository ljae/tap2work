begin;
-- Store text stays service-only. Workspace deletion removes all cached content
-- and quota rows transactionally; user deletion removes their quota record.
create table if not exists public.tap2work_content_translations (
  workspace_id uuid not null references public.tap2work_workspaces(id) on delete cascade,
  source_hash text not null check (source_hash ~ '^[a-f0-9]{64}$'),
  target_locale text not null check (target_locale in ('ko','en','vi','zh-Hans','ja','th','ne','id')),
  translated jsonb not null check (jsonb_typeof(translated) = 'object' and octet_length(translated::text) <= 500000),
  created_at timestamptz not null default now(),
  primary key (workspace_id, source_hash, target_locale)
);
create table if not exists public.tap2work_translation_budgets (
  workspace_id uuid not null references public.tap2work_workspaces(id) on delete cascade,
  scope text not null,
  user_id uuid references auth.users(id) on delete cascade,
  minute_start timestamptz not null,
  minute_requests integer not null,
  day_start timestamptz not null,
  day_characters integer not null,
  primary key(workspace_id, scope),
  check ((scope = '*' and user_id is null) or (user_id is not null and scope = user_id::text))
);
alter table public.tap2work_content_translations enable row level security;
alter table public.tap2work_translation_budgets enable row level security;
revoke all on public.tap2work_content_translations, public.tap2work_translation_budgets from public, anon, authenticated;
grant all on public.tap2work_content_translations, public.tap2work_translation_budgets to service_role;

create or replace function public.tap2work_reserve_translation(p_workspace_id uuid, p_user_id uuid, p_characters integer)
returns boolean language plpgsql security definer set search_path = '' as $$
declare
  stamp timestamptz := now();
  minute_stamp timestamptz := date_trunc('minute', stamp);
  day_stamp timestamptz := date_trunc('day', stamp at time zone 'UTC') at time zone 'UTC';
  row public.tap2work_translation_budgets%rowtype;
begin
  if p_characters < 1 or p_characters > 20000 or p_characters is null then return false; end if;
  -- Serializes reservations across isolates and users of this workspace.
  perform pg_advisory_xact_lock(hashtextextended('translation:' || p_workspace_id::text, 0));
  if not exists(select 1 from public.tap2work_members where workspace_id = p_workspace_id and user_id = p_user_id) then return false; end if;
  for row in select * from public.tap2work_translation_budgets where workspace_id = p_workspace_id and scope in ('*', p_user_id::text) loop
    if row.minute_start = minute_stamp and row.minute_requests >= (case when row.scope = '*' then 120 else 20 end) then return false; end if;
    if row.day_start = day_stamp and row.day_characters + p_characters > (case when row.scope = '*' then 200000 else 100000 end) then return false; end if;
  end loop;
  insert into public.tap2work_translation_budgets(workspace_id,scope,user_id,minute_start,minute_requests,day_start,day_characters)
  values (p_workspace_id,'*',null,minute_stamp,1,day_stamp,p_characters),
         (p_workspace_id,p_user_id::text,p_user_id,minute_stamp,1,day_stamp,p_characters)
  on conflict (workspace_id,scope) do update set
    minute_requests = case when tap2work_translation_budgets.minute_start = minute_stamp then tap2work_translation_budgets.minute_requests + 1 else 1 end,
    minute_start = minute_stamp,
    day_characters = case when tap2work_translation_budgets.day_start = day_stamp then tap2work_translation_budgets.day_characters + p_characters else p_characters end,
    day_start = day_stamp;
  -- Bound each maintenance pass. Old hashes cannot be served for new content.
  delete from public.tap2work_content_translations where (workspace_id,source_hash,target_locale) in (
    select workspace_id,source_hash,target_locale from public.tap2work_content_translations
    where workspace_id = p_workspace_id and created_at < stamp - interval '30 days' limit 200
  );
  return true;
end $$;
revoke all on function public.tap2work_reserve_translation(uuid,uuid,integer) from public, anon, authenticated;
grant execute on function public.tap2work_reserve_translation(uuid,uuid,integer) to service_role;
notify pgrst, 'reload schema';
commit;
