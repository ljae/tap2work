-- Authenticated workspace storage. Raw operational/payroll payloads are server-only.
begin;
create table if not exists public.tap2work_workspaces (
  id uuid primary key default gen_random_uuid(),
  name text not null check (length(name) between 1 and 80),
  created_by uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now()
);
create table if not exists public.tap2work_members (
  workspace_id uuid not null references public.tap2work_workspaces(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  role text not null check (role in ('owner','manager','cook','crew')),
  display_name text not null check (length(display_name) between 1 and 80),
  primary key (workspace_id, user_id),
  unique(user_id)
);
create table if not exists public.tap2work_state (
  workspace_id uuid primary key references public.tap2work_workspaces(id) on delete cascade,
  revision bigint not null check (revision > 0),
  payload jsonb not null check (jsonb_typeof(payload) = 'object'),
  updated_at timestamptz not null default now()
);
alter table public.tap2work_workspaces enable row level security;
alter table public.tap2work_members enable row level security;
alter table public.tap2work_state enable row level security;
revoke all on public.tap2work_workspaces, public.tap2work_members, public.tap2work_state from anon, authenticated;
grant select on public.tap2work_workspaces, public.tap2work_members to authenticated;
grant all on public.tap2work_workspaces, public.tap2work_members, public.tap2work_state to service_role;
drop policy if exists own_membership on public.tap2work_members;
create policy own_membership on public.tap2work_members for select to authenticated using (user_id = (select auth.uid()));
drop policy if exists joined_workspace on public.tap2work_workspaces;
create policy joined_workspace on public.tap2work_workspaces for select to authenticated using (exists(select 1 from public.tap2work_members m where m.workspace_id = id and m.user_id = (select auth.uid())));

create or replace function public.tap2work_bootstrap(p_user_id uuid, p_name text, p_state jsonb)
returns uuid language plpgsql set search_path = '' as $$
declare found_id uuid;
begin
  perform pg_advisory_xact_lock(hashtextextended(p_user_id::text, 0));
  select workspace_id into found_id from public.tap2work_members where user_id = p_user_id;
  if found_id is not null then return found_id; end if;
  insert into public.tap2work_workspaces(name, created_by) values ('우리 매장', p_user_id) returning id into found_id;
  insert into public.tap2work_members values(found_id, p_user_id, 'owner', left(coalesce(nullif(trim(p_name),''),'사장님'),80));
  insert into public.tap2work_state values(found_id, (p_state->>'revision')::bigint, p_state, now());
  return found_id;
end $$;
create or replace function public.tap2work_save_state(p_workspace_id uuid, p_expected_revision bigint, p_payload jsonb)
returns boolean language plpgsql set search_path = '' as $$
begin
  if (p_payload->>'revision')::bigint <> p_expected_revision + 1 then raise exception 'Invalid revision'; end if;
  if octet_length(p_payload::text) > 8388608 then raise exception 'Workspace limit exceeded'; end if;
  update public.tap2work_state set payload=p_payload, revision=p_expected_revision+1, updated_at=now()
    where workspace_id=p_workspace_id and revision=p_expected_revision;
  return found;
end $$;
revoke all on function public.tap2work_bootstrap(uuid,text,jsonb), public.tap2work_save_state(uuid,bigint,jsonb) from public, anon, authenticated;
grant execute on function public.tap2work_bootstrap(uuid,text,jsonb), public.tap2work_save_state(uuid,bigint,jsonb) to service_role;
notify pgrst, 'reload schema';
commit;
