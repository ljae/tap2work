-- Keep the workspace label consistent with the owner-edited store identity.
begin;
create or replace function public.tap2work_bootstrap(p_user_id uuid, p_name text, p_state jsonb)
returns uuid language plpgsql set search_path = '' as $$
declare found_id uuid;
begin
  perform pg_advisory_xact_lock(hashtextextended(p_user_id::text, 0));
  select workspace_id into found_id from public.tap2work_members where user_id = p_user_id;
  if found_id is not null then return found_id; end if;
  insert into public.tap2work_workspaces(name, created_by)
    values (left(coalesce(nullif(trim(p_state->'store'->>'name'), ''), '새 매장'), 80), p_user_id)
    returning id into found_id;
  insert into public.tap2work_members values(found_id, p_user_id, 'owner', left(coalesce(nullif(trim(p_name),''),'사장님'),80));
  insert into public.tap2work_state values(found_id, (p_state->>'revision')::bigint, p_state, now());
  return found_id;
end $$;

create or replace function public.tap2work_save_state(p_workspace_id uuid, p_expected_revision bigint, p_payload jsonb)
returns boolean language plpgsql set search_path = '' as $$
declare saved boolean;
begin
  if (p_payload->>'revision')::bigint <> p_expected_revision + 1 then raise exception 'Invalid revision'; end if;
  if octet_length(p_payload::text) > 8388608 then raise exception 'Workspace limit exceeded'; end if;
  update public.tap2work_state set payload=p_payload, revision=p_expected_revision+1, updated_at=now()
    where workspace_id=p_workspace_id and revision=p_expected_revision;
  saved := found;
  if saved then
    update public.tap2work_workspaces set name=left(coalesce(nullif(trim(p_payload->'store'->>'name'), ''), name), 80)
      where id=p_workspace_id;
  end if;
  return saved;
end $$;
revoke all on function public.tap2work_bootstrap(uuid,text,jsonb), public.tap2work_save_state(uuid,bigint,jsonb) from public, anon, authenticated;
grant execute on function public.tap2work_bootstrap(uuid,text,jsonb), public.tap2work_save_state(uuid,bigint,jsonb) to service_role;
notify pgrst, 'reload schema';
commit;
