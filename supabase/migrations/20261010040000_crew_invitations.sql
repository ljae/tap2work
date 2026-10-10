begin;
create table if not exists public.tap2work_crew_invitations (
 id uuid primary key default gen_random_uuid(),
 workspace_id uuid not null references public.tap2work_workspaces(id) on delete cascade,
 tapper_id text not null,
 target_role text not null check(target_role in ('crew','cook','manager')),
 token_hash text not null unique check(token_hash ~ '^[a-f0-9]{64}$'),
 created_by uuid references auth.users(id) on delete set null,
 created_at timestamptz not null default now(),
 expires_at timestamptz not null default now()+interval '7 days',
 accepted_by uuid references auth.users(id) on delete set null,
 accepted_at timestamptz,
 revoked_at timestamptz
);
create index if not exists tap2work_crew_invites_store on public.tap2work_crew_invitations(workspace_id,tapper_id);
alter table public.tap2work_crew_invitations enable row level security;
revoke all on public.tap2work_crew_invitations from public,anon,authenticated;
grant all on public.tap2work_crew_invitations to service_role;

-- All identity comes from Auth validation in the service handler. Membership,
-- current manager permission, target rank and source revision are checked again
-- under workspace/state locks. No client can invoke this RPC directly.
create or replace function public.tap2work_crew_invitation(
 p_action text, p_user_id uuid, p_workspace_id uuid default null,
 p_tapper_id text default null, p_invite_id uuid default null,
 p_token_hash text default null, p_expected_revision bigint default null
) returns jsonb language plpgsql security definer set search_path='' as $$
declare
 invite public.tap2work_crew_invitations;
 wid uuid := p_workspace_id;
 role_name text;
 body jsonb;
 person jsonb;
 people jsonb;
 target text := p_tapper_id;
 current_revision bigint;
 target_role_name text;
 linked_user uuid;
 saved boolean;
 activity jsonb;
 stamp timestamptz := now();
 result jsonb;
begin
 if p_action is null or p_action not in ('create','list','preview','accept','revoke','unlink') then
  return jsonb_build_object('errorCode','INVALID_INVITATION_ACTION','status',400);
 end if;
 if not exists(select 1 from auth.users where id=p_user_id) then
  return jsonb_build_object('errorCode','AUTH_REQUIRED','status',401);
 end if;
 if p_action in ('preview','accept') then
  if p_token_hash is null or p_token_hash !~ '^[a-f0-9]{64}$' then
   return jsonb_build_object('errorCode','INVITATION_UNAVAILABLE','status',404);
  end if;
  select * into invite from public.tap2work_crew_invitations where token_hash=p_token_hash;
  if not found then return jsonb_build_object('errorCode','INVITATION_UNAVAILABLE','status',404); end if;
  wid:=invite.workspace_id; target:=invite.tapper_id;
 end if;
 perform 1 from public.tap2work_workspaces where id=wid for update;
 if not found then return jsonb_build_object('errorCode','INVITATION_UNAVAILABLE','status',404); end if;
 select revision into current_revision from public.tap2work_state where workspace_id=wid for update;
 select coalesce(jsonb_object_agg(section,value),'{}') into body from public.tap2work_documents where workspace_id=wid;
 select role into role_name from public.tap2work_members where workspace_id=wid and user_id=p_user_id;
 if p_action not in ('preview','accept') then
  if role_name is null or not (role_name='owner' or (role_name='manager' and body#>'{workplace,restrictions,manager,crew}'='true'::jsonb)) then
   return jsonb_build_object('errorCode','INVITATION_FORBIDDEN','status',403);
  end if;
 end if;
 if p_action='list' then
  select coalesce(jsonb_agg(jsonb_build_object('id',i.id,'tapperId',i.tapper_id,'createdAt',i.created_at,'expiresAt',i.expires_at,
   'status',case when i.revoked_at is not null then 'revoked' when i.accepted_at is not null then 'accepted' when i.expires_at<=stamp then 'expired' else 'pending' end)
   order by i.created_at desc),'[]') into result
   from public.tap2work_crew_invitations i where workspace_id=wid and (role_name='owner' or i.target_role in ('crew','cook'));
  return jsonb_build_object('invitations',result,'revision',current_revision);
 end if;
 if p_action='revoke' then
  select * into invite from public.tap2work_crew_invitations where id=p_invite_id and workspace_id=wid for update;
  if not found then return jsonb_build_object('errorCode','INVITATION_UNAVAILABLE','status',404); end if;
  target:=invite.tapper_id;
 end if;
 select value into person from jsonb_array_elements(coalesce(body->'tappers','[]')) where value->>'id'=target;
 if person is null then return jsonb_build_object('errorCode','CREW_UNAVAILABLE','status',404); end if;
 target_role_name:=person->>'rank';
 if target_role_name not in ('crew','cook','manager') or target_role_name is null or (role_name='manager' and p_action not in ('preview','accept') and target_role_name not in ('crew','cook')) then
  return jsonb_build_object('errorCode','INVITATION_FORBIDDEN','status',403);
 end if;
 if p_action in ('preview','accept') then
  select * into invite from public.tap2work_crew_invitations where id=invite.id for update;
  if invite.revoked_at is not null or (invite.accepted_at is null and invite.expires_at<=stamp) then
   return jsonb_build_object('errorCode','INVITATION_UNAVAILABLE','status',410);
  end if;
  if invite.accepted_at is not null then
   if invite.accepted_by=p_user_id and person->>'actorId'=p_user_id::text and role_name is not null then
    return jsonb_build_object('accepted',true,'workspaceId',wid);
   end if;
   return jsonb_build_object('errorCode','INVITATION_USED','status',409);
  end if;
  if not exists(select 1 from public.tap2work_members issuer where issuer.workspace_id=wid and issuer.user_id=invite.created_by and
    (issuer.role='owner' or (issuer.role='manager' and invite.target_role in ('crew','cook') and body#>'{workplace,restrictions,manager,crew}'='true'::jsonb))) then
   return jsonb_build_object('errorCode','INVITATION_UNAVAILABLE','status',410);
  end if;
  if person->>'active'='false' or nullif(person->>'actorId','') is not null or target_role_name<>invite.target_role then
   return jsonb_build_object('errorCode','CREW_CHANGED','status',409);
  end if;
  if role_name is not null or exists(select 1 from jsonb_array_elements(body->'tappers') t where t->>'actorId'=p_user_id::text) then
   return jsonb_build_object('errorCode','ALREADY_JOINED','status',409);
  end if;
  if p_action='preview' then
   return jsonb_build_object('workspaceName',body#>>'{store,name}','crewName',person->>'nickname','role',target_role_name,'expiresAt',invite.expires_at);
  end if;
  insert into public.tap2work_members(workspace_id,user_id,role,display_name) values(wid,p_user_id,target_role_name,left(person->>'nickname',80));
  select jsonb_agg(case when t->>'id'=target then t||jsonb_build_object('actorId',p_user_id,'connectedAt',stamp) else t end) into people from jsonb_array_elements(body->'tappers') t;
  update public.tap2work_crew_invitations set accepted_by=p_user_id,accepted_at=stamp where id=invite.id;
  activity:=jsonb_build_object('id',gen_random_uuid(),'at',stamp,'actor',jsonb_build_object('id',p_user_id,'name',person->>'nickname','role','크루'),'message','크루가 본인 계정 연결을 확인했어요.','kind','crew_connection');
 elsif p_action='create' then
  if p_expected_revision is distinct from current_revision then return jsonb_build_object('errorCode','REVISION_CONFLICT','status',409); end if;
  if person->>'active'='false' or nullif(person->>'actorId','') is not null then return jsonb_build_object('errorCode','CREW_CHANGED','status',409); end if;
  if p_token_hash is null or p_token_hash !~ '^[a-f0-9]{64}$' then return jsonb_build_object('errorCode','INVALID_INVITATION','status',400); end if;
  update public.tap2work_crew_invitations set revoked_at=stamp where workspace_id=wid and tapper_id=target and accepted_at is null and revoked_at is null;
  insert into public.tap2work_crew_invitations(workspace_id,tapper_id,target_role,token_hash,created_by,expires_at)
   values(wid,target,target_role_name,p_token_hash,p_user_id,stamp+interval '7 days') returning * into invite;
  return jsonb_build_object('id',invite.id,'expiresAt',invite.expires_at,'tapperId',target);
 elsif p_action='revoke' then
  if p_expected_revision is distinct from current_revision then return jsonb_build_object('errorCode','REVISION_CONFLICT','status',409); end if;
  if invite.accepted_at is not null then return jsonb_build_object('errorCode','USE_UNLINK','status',409); end if;
  update public.tap2work_crew_invitations set revoked_at=coalesce(revoked_at,stamp) where id=invite.id;
  return jsonb_build_object('revoked',true);
 elsif p_action='unlink' then
  if p_expected_revision is distinct from current_revision then return jsonb_build_object('errorCode','REVISION_CONFLICT','status',409); end if;
  if nullif(person->>'actorId','') is null then return jsonb_build_object('unlinked',true); end if;
  linked_user:=(person->>'actorId')::uuid;
  if exists(select 1 from public.tap2work_members where workspace_id=wid and user_id=linked_user and (role='owner' or (role_name='manager' and role='manager'))) then
   return jsonb_build_object('errorCode','INVITATION_FORBIDDEN','status',403);
  end if;
  delete from public.tap2work_members where workspace_id=wid and user_id=linked_user;
  select jsonb_agg(case when t->>'id'=target then (t-'actorId'-'connectedAt')||jsonb_build_object('disconnectedAt',stamp) else t end) into people from jsonb_array_elements(body->'tappers') t;
  update public.tap2work_crew_invitations set revoked_at=coalesce(revoked_at,stamp) where workspace_id=wid and tapper_id=target;
  activity:=jsonb_build_object('id',gen_random_uuid(),'at',stamp,'actor',jsonb_build_object('id',p_user_id,'name',(select display_name from public.tap2work_members where workspace_id=wid and user_id=p_user_id),'role',role_name),'message','크루 계정 연결을 해제했어요. 이전 업무 기록은 유지돼요.','kind','crew_connection');
 end if;
 select public.tap2work_patch_state(wid,current_revision,jsonb_build_object('tappers',people,'activity',jsonb_build_array(activity)||coalesce(body->'activity','[]')),'{}') into saved;
 if saved is not true then raise exception 'Invitation workspace CAS failed'; end if;
 return jsonb_build_object(case when p_action='accept' then 'accepted' else 'unlinked' end,true,'workspaceId',wid);
end $$;
revoke all on function public.tap2work_crew_invitation(text,uuid,uuid,text,uuid,text,bigint) from public,anon,authenticated;
grant execute on function public.tap2work_crew_invitation(text,uuid,uuid,text,uuid,text,bigint) to service_role;

-- Roster access edits and their workspace CAS must commit together. A disabled
-- crew member keeps historical actor IDs but loses authenticated membership.
-- Re-enabling their roster record never silently grants membership again.
create or replace function public.tap2work_patch_crew_state(
 p_user_id uuid,p_workspace_id uuid,p_expected_revision bigint,p_changes jsonb,p_removed text[] default '{}'
) returns boolean language plpgsql security definer set search_path='' as $$
declare old_people jsonb;new_people jsonb;old_person jsonb;new_person jsonb;m record;current_revision bigint;saved boolean;
begin
 select revision into current_revision from public.tap2work_state where workspace_id=p_workspace_id for update;
 if current_revision is distinct from p_expected_revision then return false; end if;
 if not exists(select 1 from public.tap2work_members where workspace_id=p_workspace_id and user_id=p_user_id and role='owner') then raise exception 'Crew access edit forbidden'; end if;
 select value into old_people from public.tap2work_documents where workspace_id=p_workspace_id and section='tappers';
 new_people:=case when 'tappers'=any(p_removed) then '[]'::jsonb else coalesce(p_changes->'tappers',old_people) end;
 if jsonb_typeof(new_people)<>'array' then raise exception 'Invalid crew records'; end if;
 for m in select * from public.tap2work_members where workspace_id=p_workspace_id order by user_id loop
  select value into old_person from jsonb_array_elements(coalesce(old_people,'[]')) where value->>'actorId'=m.user_id::text;
  select value into new_person from jsonb_array_elements(new_people) where value->>'actorId'=m.user_id::text;
  if old_person is null and new_person is null then continue; end if;
  if m.role='owner' then
   if new_person is null or new_person->>'rank'<>'owner' or new_person->>'active'='false' then raise exception 'Owner transfer requires a separate process'; end if;
  elsif new_person is not null and new_person->>'rank'='owner' then raise exception 'Owner escalation forbidden';
  elsif new_person is null or new_person->>'active'='false' then
   delete from public.tap2work_members where workspace_id=p_workspace_id and user_id=m.user_id;
   update public.tap2work_crew_invitations set revoked_at=coalesce(revoked_at,now()) where workspace_id=p_workspace_id and tapper_id=old_person->>'id';
  else
   if new_person->>'rank' not in ('crew','cook','manager') or new_person->>'rank' is null then raise exception 'Invalid crew role'; end if;
   update public.tap2work_members set role=new_person->>'rank',display_name=left(new_person->>'nickname',80) where workspace_id=p_workspace_id and user_id=m.user_id;
  end if;
 end loop;
 select public.tap2work_patch_state(p_workspace_id,p_expected_revision,p_changes,p_removed) into saved;
 if saved is not true then raise exception 'Crew access CAS failed'; end if;
 return true;
end $$;
revoke all on function public.tap2work_patch_crew_state(uuid,uuid,bigint,jsonb,text[]) from public,anon,authenticated;
grant execute on function public.tap2work_patch_crew_state(uuid,uuid,bigint,jsonb,text[]) to service_role;
notify pgrst,'reload schema';
commit;
