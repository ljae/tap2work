-- Service-only account erasure: confirm a fresh scope and commit all DB changes
-- together, including Auth identities/sessions through auth.users cascades.
begin;
create or replace function public.tap2work_account_context(p_user_id uuid)
returns jsonb language plpgsql set search_path='' as $$
declare m public.tap2work_members; w public.tap2work_workspaces; s public.tap2work_state;
  owners jsonb; members jsonb; body jsonb;
begin
  select * into m from public.tap2work_members where user_id=p_user_id;
  if m.workspace_id is null then
    if exists(select 1 from public.tap2work_workspaces where created_by=p_user_id) then
      raise exception 'Account workspace ownership needs repair';
    end if;
    return jsonb_build_object('scope',jsonb_build_object('userId',p_user_id,'workspaceId',null,'ownerCount',0,'memberCount',0));
  end if;
  if exists(select 1 from public.tap2work_workspaces where created_by=p_user_id and id<>m.workspace_id) then
    raise exception 'Account workspace ownership needs repair';
  end if;
  select * into w from public.tap2work_workspaces where id=m.workspace_id;
  select * into s from public.tap2work_state where workspace_id=m.workspace_id;
  select coalesce(jsonb_agg(user_id order by user_id),'[]') into owners from public.tap2work_members where workspace_id=m.workspace_id and role='owner';
  select coalesce(jsonb_agg(jsonb_build_object('userId',user_id,'role',role) order by user_id),'[]') into members from public.tap2work_members where workspace_id=m.workspace_id;
  select coalesce(jsonb_object_agg(section,value),'{}') into body from public.tap2work_documents where workspace_id=m.workspace_id;
  if body='{}'::jsonb then body:=s.payload; end if;
  return jsonb_build_object('scope',jsonb_build_object('userId',p_user_id,'workspaceId',m.workspace_id,
    'workspaceName',w.name,'displayName',m.display_name,'createdBy',w.created_by,'role',m.role,'revision',s.revision,
    'owners',owners,'members',members,'ownerCount',jsonb_array_length(owners),'memberCount',jsonb_array_length(members)),
    'payload',body || jsonb_build_object('revision',s.revision));
end $$;

create or replace function public.tap2work_erase_account(p_user_id uuid,p_expected_scope jsonb,p_sanitized_payload jsonb,p_delete_workspace boolean)
returns jsonb language plpgsql set search_path='' as $$
declare m public.tap2work_members; current_scope jsonb; replacement_owner uuid;
begin
  perform pg_advisory_xact_lock(hashtextextended(p_user_id::text,0));
  -- Lock identity, membership and workspace to serialize deletion / ownership changes.
  perform 1 from auth.users where id=p_user_id for update;
  if not found then return jsonb_build_object('deleted',true); end if;
  select * into m from public.tap2work_members where user_id=p_user_id;
  if m.workspace_id is not null then
    perform 1 from public.tap2work_workspaces where id=m.workspace_id for update;
    perform 1 from public.tap2work_members where workspace_id=m.workspace_id order by user_id for update;
    perform 1 from public.tap2work_state where workspace_id=m.workspace_id for update;
  end if;
  current_scope:=public.tap2work_account_context(p_user_id)->'scope';
  if current_scope is distinct from p_expected_scope then return jsonb_build_object('conflict',true); end if;
  if m.workspace_id is not null then
    if m.role='owner' and (current_scope->>'ownerCount')::integer=1 then
      if p_delete_workspace is not true then raise exception 'Workspace confirmation required'; end if;
      delete from public.tap2work_workspaces where id=m.workspace_id;
    else
      if p_delete_workspace is true then raise exception 'Workspace deletion not permitted'; end if;
      if p_sanitized_payload is null or jsonb_typeof(p_sanitized_payload)<>'object'
        or (p_sanitized_payload->>'revision')::bigint is distinct from (current_scope->>'revision')::bigint then
        raise exception 'Invalid erasure payload';
      end if;
      -- Never let created_by ON DELETE CASCADE remove a surviving shared store.
      if current_scope->>'createdBy'=p_user_id::text then
        select user_id into replacement_owner from public.tap2work_members
          where workspace_id=m.workspace_id and role='owner' and user_id<>p_user_id order by user_id limit 1;
        if replacement_owner is null then raise exception 'Workspace owner required'; end if;
        update public.tap2work_workspaces set created_by=replacement_owner where id=m.workspace_id;
      end if;
      delete from public.tap2work_documents where workspace_id=m.workspace_id;
      insert into public.tap2work_documents(workspace_id,section,value)
        select m.workspace_id,key,value from jsonb_each(p_sanitized_payload-'revision');
      -- Scrub the legacy recovery snapshot too; it must not retain erased PII.
      update public.tap2work_state set revision=revision+1,
        payload=p_sanitized_payload || jsonb_build_object('revision',revision+1),updated_at=now()
        where workspace_id=m.workspace_id;
      delete from public.tap2work_members where user_id=p_user_id;
    end if;
  end if;
  delete from auth.users where id=p_user_id;
  return jsonb_build_object('deleted',true);
end $$;

revoke all on function public.tap2work_account_context(uuid),public.tap2work_erase_account(uuid,jsonb,jsonb,boolean) from public,anon,authenticated;
grant execute on function public.tap2work_account_context(uuid),public.tap2work_erase_account(uuid,jsonb,jsonb,boolean) to service_role;
-- auth.users deletion is available only inside this narrow service RPC.
alter function public.tap2work_erase_account(uuid,jsonb,jsonb,boolean) security definer;
notify pgrst,'reload schema';
commit;
