-- One identity may belong to many isolated stores. Service API checks membership.
begin;
alter table public.tap2work_members drop constraint if exists tap2work_members_user_id_key;
create index if not exists tap2work_members_user_idx on public.tap2work_members(user_id);
create table if not exists public.tap2work_workspace_requests (
  user_id uuid not null references auth.users(id) on delete cascade,
  request_id uuid not null,
  workspace_id uuid not null references public.tap2work_workspaces(id) on delete cascade,
  primary key(user_id,request_id)
);
alter table public.tap2work_workspace_requests enable row level security;
revoke all on public.tap2work_workspace_requests from public,anon,authenticated;
grant all on public.tap2work_workspace_requests to service_role;

create or replace function public.tap2work_create_workspace(p_user_id uuid,p_name text,p_state jsonb,p_request_id uuid)
returns uuid language plpgsql set search_path='' as $$
declare result uuid;
begin
  perform pg_advisory_xact_lock(hashtextextended(p_user_id::text,0));
  if p_request_id is null or length(trim(p_state->'store'->>'name')) not between 1 and 80 then
    raise exception 'Store name and request identity required';
  end if;
  select workspace_id into result from public.tap2work_workspace_requests where user_id=p_user_id and request_id=p_request_id;
  if result is not null then return result; end if;
  insert into public.tap2work_workspaces(name,created_by) values(trim(p_state->'store'->>'name'),p_user_id) returning id into result;
  insert into public.tap2work_members values(result,p_user_id,'owner',left(coalesce(nullif(trim(p_name),''),'사장님'),80));
  insert into public.tap2work_state values(result,(p_state->>'revision')::bigint,p_state,now());
  insert into public.tap2work_workspace_requests values(p_user_id,p_request_id,result);
  return result;
end $$;

create or replace function public.tap2work_read_workspace(p_user_id uuid,p_revision bigint default null,p_window bigint default null,p_role text default null,p_workspace_id uuid default null)
returns jsonb language plpgsql stable set search_path='' as $$
declare m public.tap2work_members; s public.tap2work_state; current_window bigint; body jsonb; stores jsonb;
begin
  select coalesce(jsonb_agg(jsonb_build_object('id',w.id,'name',w.name,'role',x.role) order by w.created_at,w.id),'[]') into stores
    from public.tap2work_members x join public.tap2work_workspaces w on w.id=x.workspace_id where x.user_id=p_user_id;
  select x.* into m from public.tap2work_members x join public.tap2work_workspaces w on w.id=x.workspace_id
    where x.user_id=p_user_id and (p_workspace_id is null or x.workspace_id=p_workspace_id) order by w.created_at,w.id limit 1;
  if not found then
    return jsonb_build_object('needsWorkspace',p_workspace_id is null,'forbidden',p_workspace_id is not null,'workspaces',stores);
  end if;
  select workspace_id,revision,'{}'::jsonb,updated_at into s from public.tap2work_state where workspace_id=m.workspace_id;
  current_window:=floor(extract(epoch from now())/60)::bigint;
  if p_revision=s.revision and p_window=current_window and p_role=m.role and p_workspace_id=m.workspace_id then
    return jsonb_build_object('unchanged',true,'workspaceId',m.workspace_id,'revision',s.revision,'window',current_window,'workspaces',stores);
  end if;
  select coalesce(jsonb_object_agg(section,value),'{}') into body from public.tap2work_documents where workspace_id=m.workspace_id;
  return jsonb_build_object('member',to_jsonb(m),'payload',body || jsonb_build_object('revision',s.revision),'window',current_window,'workspaces',stores);
end $$;
revoke all on function public.tap2work_create_workspace(uuid,text,jsonb,uuid) from public,anon,authenticated;
grant execute on function public.tap2work_create_workspace(uuid,text,jsonb,uuid) to service_role;

-- Deletion scope covers every membership, independently of the selected store.
-- Single-store response stays compatible with existing clients.
create or replace function public.tap2work_account_context(p_user_id uuid)
returns jsonb language plpgsql set search_path='' as $$
declare m record; s public.tap2work_state; owners jsonb; members jsonb; body jsonb; scope jsonb;
  scopes jsonb:='[]'; payloads jsonb:='{}';
begin
  if exists(select 1 from public.tap2work_workspaces w where w.created_by=p_user_id and not exists(
    select 1 from public.tap2work_members x where x.workspace_id=w.id and x.user_id=p_user_id)) then
    raise exception 'Account workspace ownership needs repair';
  end if;
  for m in select x.*,w.name,w.created_by from public.tap2work_members x join public.tap2work_workspaces w on w.id=x.workspace_id
    where x.user_id=p_user_id order by x.workspace_id loop
    select * into s from public.tap2work_state where workspace_id=m.workspace_id;
    select coalesce(jsonb_agg(user_id order by user_id),'[]') into owners from public.tap2work_members where workspace_id=m.workspace_id and role='owner';
    select coalesce(jsonb_agg(jsonb_build_object('userId',user_id,'role',role) order by user_id),'[]') into members from public.tap2work_members where workspace_id=m.workspace_id;
    select coalesce(jsonb_object_agg(section,value),'{}') into body from public.tap2work_documents where workspace_id=m.workspace_id;
    if body='{}'::jsonb then body:=s.payload; end if;
    scope:=jsonb_build_object('userId',p_user_id,'workspaceId',m.workspace_id,'workspaceName',m.name,'displayName',m.display_name,
      'createdBy',m.created_by,'role',m.role,'revision',s.revision,'owners',owners,'members',members,'ownerCount',jsonb_array_length(owners),'memberCount',jsonb_array_length(members));
    scopes:=scopes || jsonb_build_array(scope);
    payloads:=payloads || jsonb_build_object(m.workspace_id::text,body || jsonb_build_object('revision',s.revision));
  end loop;
  if jsonb_array_length(scopes)=0 then return jsonb_build_object('scope',jsonb_build_object('userId',p_user_id,'workspaceId',null,'ownerCount',0,'memberCount',0)); end if;
  if jsonb_array_length(scopes)=1 then return jsonb_build_object('scope',scopes->0,'payload',payloads->(scopes->0->>'workspaceId')); end if;
  return jsonb_build_object('scope',jsonb_build_object('userId',p_user_id,'workspaces',scopes),'payloads',payloads);
end $$;

create or replace function public.tap2work_erase_account(p_user_id uuid,p_expected_scope jsonb,p_sanitized_payload jsonb,p_delete_workspace boolean)
returns jsonb language plpgsql security definer set search_path='' as $$
declare current_scope jsonb; entry jsonb; clean jsonb; wid uuid; replacement_owner uuid;
begin
  perform pg_advisory_xact_lock(hashtextextended(p_user_id::text,0));
  perform 1 from auth.users where id=p_user_id for update;
  if not found then return jsonb_build_object('deleted',true); end if;
  -- Deterministic lock order across all stores, including their members and CAS rows.
  for wid in select workspace_id from public.tap2work_members where user_id=p_user_id order by workspace_id loop
    perform 1 from public.tap2work_workspaces where id=wid for update;
    perform 1 from public.tap2work_members where workspace_id=wid order by user_id for update;
    perform 1 from public.tap2work_state where workspace_id=wid for update;
  end loop;
  current_scope:=public.tap2work_account_context(p_user_id)->'scope';
  if current_scope is distinct from p_expected_scope then return jsonb_build_object('conflict',true); end if;
  for entry in select value from jsonb_array_elements(coalesce(current_scope->'workspaces',jsonb_build_array(current_scope))) loop
    wid:=(entry->>'workspaceId')::uuid;
    if wid is null then continue; end if;
    if entry->>'role'='owner' and (entry->>'ownerCount')::integer=1 then
      if p_delete_workspace is not true then raise exception 'Workspace confirmation required'; end if;
      delete from public.tap2work_workspaces where id=wid;
    else
      clean:=case when current_scope ? 'workspaces' then p_sanitized_payload->wid::text else p_sanitized_payload end;
      if clean is null or jsonb_typeof(clean)<>'object' or (clean->>'revision')::bigint is distinct from (entry->>'revision')::bigint then raise exception 'Invalid erasure payload'; end if;
      if entry->>'createdBy'=p_user_id::text then
        select user_id into replacement_owner from public.tap2work_members where workspace_id=wid and role='owner' and user_id<>p_user_id order by user_id limit 1;
        if replacement_owner is null then raise exception 'Workspace owner required'; end if;
        update public.tap2work_workspaces set created_by=replacement_owner where id=wid;
      end if;
      delete from public.tap2work_documents where workspace_id=wid;
      insert into public.tap2work_documents(workspace_id,section,value) select wid,key,value from jsonb_each(clean-'revision');
      update public.tap2work_state set revision=revision+1,payload=clean || jsonb_build_object('revision',revision+1),updated_at=now() where workspace_id=wid;
      delete from public.tap2work_members where workspace_id=wid and user_id=p_user_id;
    end if;
  end loop;
  delete from auth.users where id=p_user_id;
  return jsonb_build_object('deleted',true);
end $$;
notify pgrst,'reload schema';
commit;
