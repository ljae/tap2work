-- Service-only section documents. Keep the legacy snapshot as a recovery copy.
begin;
create table if not exists public.tap2work_documents (
  workspace_id uuid not null references public.tap2work_workspaces(id) on delete cascade,
  section text not null check (length(section) between 1 and 100 and section <> 'revision'),
  value jsonb not null,
  size_bytes integer generated always as (octet_length(value::text)) stored,
  updated_at timestamptz not null default now(),
  primary key (workspace_id, section)
);
alter table public.tap2work_documents enable row level security;
revoke all on public.tap2work_documents from public, anon, authenticated;
grant all on public.tap2work_documents to service_role;
-- Backfill only missing workspaces; reruns never restore stale legacy data.
insert into public.tap2work_documents(workspace_id, section, value)
select s.workspace_id, e.key, e.value from public.tap2work_state s
cross join lateral jsonb_each(s.payload - 'revision') e
where not exists(select 1 from public.tap2work_documents d where d.workspace_id=s.workspace_id)
on conflict do nothing;

create or replace function public.tap2work_seed_documents()
returns trigger language plpgsql set search_path='' as $$
begin
  insert into public.tap2work_documents(workspace_id, section, value)
  select new.workspace_id, e.key, e.value from jsonb_each(new.payload - 'revision') e
  on conflict(workspace_id,section) do update set value=excluded.value, updated_at=now()
  where public.tap2work_documents.value is distinct from excluded.value;
  return new;
end $$;
-- CREATE OR REPLACE TRIGGER avoids a destructive drop on rerun.
create or replace trigger tap2work_seed_documents after insert on public.tap2work_state
for each row execute function public.tap2work_seed_documents();

create or replace function public.tap2work_read_workspace(p_user_id uuid, p_revision bigint default null, p_window bigint default null, p_role text default null, p_workspace_id uuid default null)
returns jsonb language plpgsql stable set search_path='' as $$
declare m public.tap2work_members; s public.tap2work_state; current_window bigint; body jsonb;
begin
  select * into m from public.tap2work_members where user_id=p_user_id;
  if not found then return jsonb_build_object('needsWorkspace',true); end if;
  select workspace_id, revision, '{}'::jsonb, updated_at into s from public.tap2work_state where workspace_id=m.workspace_id;
  current_window := floor(extract(epoch from now())/60)::bigint;
  if p_revision=s.revision and p_window=current_window and p_role=m.role and p_workspace_id=m.workspace_id then
    return jsonb_build_object('unchanged',true,'workspaceId',m.workspace_id,'revision',s.revision,'window',current_window);
  end if;
  select coalesce(jsonb_object_agg(section,value),'{}'::jsonb) into body from public.tap2work_documents where workspace_id=m.workspace_id;
  return jsonb_build_object('member',to_jsonb(m),'payload',body || jsonb_build_object('revision',s.revision),'window',current_window);
end $$;

create or replace function public.tap2work_patch_state(p_workspace_id uuid, p_expected_revision bigint, p_changes jsonb, p_removed text[] default '{}')
returns boolean language plpgsql set search_path='' as $$
declare current_revision bigint; total_bytes bigint;
begin
  if jsonb_typeof(p_changes) <> 'object' or p_changes ? 'revision' or 'revision'=any(p_removed) then raise exception 'Invalid section patch'; end if;
  select revision into current_revision from public.tap2work_state where workspace_id=p_workspace_id for update;
  if current_revision is null or current_revision<>p_expected_revision then return false; end if;
  if exists(select 1 from jsonb_object_keys(p_changes) k where k=any(p_removed)) then raise exception 'Conflicting section patch'; end if;
  select coalesce(sum(size_bytes),0) into total_bytes from public.tap2work_documents
    where workspace_id=p_workspace_id and not (section=any(p_removed)) and not (p_changes ? section);
  if total_bytes+octet_length(p_changes::text)>8388608 then raise exception 'Workspace limit exceeded'; end if;
  insert into public.tap2work_documents(workspace_id,section,value)
  select p_workspace_id,key,value from jsonb_each(p_changes)
  on conflict(workspace_id,section) do update set value=excluded.value,updated_at=now()
    where public.tap2work_documents.value is distinct from excluded.value;
  delete from public.tap2work_documents where workspace_id=p_workspace_id and section=any(p_removed);
  update public.tap2work_state set revision=current_revision+1,updated_at=now() where workspace_id=p_workspace_id;
  if p_changes ? 'store' then
    update public.tap2work_workspaces set name=left(coalesce(nullif(trim(p_changes->'store'->>'name'),''),name),80) where id=p_workspace_id;
  end if;
  return true;
end $$;
revoke all on function public.tap2work_seed_documents(), public.tap2work_read_workspace(uuid,bigint,bigint,text,uuid), public.tap2work_patch_state(uuid,bigint,jsonb,text[]) from public,anon,authenticated;
grant execute on function public.tap2work_read_workspace(uuid,bigint,bigint,text,uuid), public.tap2work_patch_state(uuid,bigint,jsonb,text[]) to service_role;
notify pgrst,'reload schema';
commit;
