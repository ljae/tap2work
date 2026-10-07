-- Central manual/checklist content. No workspace role grants central editorial access.
-- Release hashes are computed and verified by the server's canonical JS validator.
-- PostgreSQL jsonb serialization is deliberately NOT used to recompute JS hashes.
begin;

create table public.tap2work_catalog_roles (
  user_id uuid not null references auth.users(id) on delete cascade,
  role text not null check (role in ('researcher','editor','reviewer','publisher')),
  granted_at timestamptz not null default now(),
  primary key(user_id,role)
);
create table public.tap2work_catalog_drafts (
  id uuid primary key default gen_random_uuid(),
  author_id uuid not null,
  contributor_ids uuid[] not null,
  revision bigint not null check(revision>0),
  payload_hash text not null check(payload_hash ~ '^[0-9a-f]{64}$'),
  payload jsonb not null,
  summary text not null check(length(trim(summary)) between 1 and 2000),
  state text not null check(state in ('draft','approved','rejected','published')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create table public.tap2work_catalog_reviews (
  id uuid primary key default gen_random_uuid(),
  draft_id uuid not null references public.tap2work_catalog_drafts(id),
  draft_revision bigint not null,
  payload_hash text not null,
  reviewer_id uuid not null,
  outcome text not null check(outcome in ('approved','rejected')),
  reason text not null check(length(trim(reason)) between 1 and 2000),
  created_at timestamptz not null default now(),
  unique(draft_id,draft_revision,reviewer_id)
);
create table public.tap2work_catalog_releases (
  release_id text primary key check(release_id ~ '^[0-9a-f]{64}$'),
  schema_version integer not null check(schema_version=2),
  payload jsonb not null,
  published_by uuid,
  created_at timestamptz not null default now()
);
create table public.tap2work_catalog_channels (
  channel text primary key check(channel ~ '^[a-z][a-z0-9_-]{0,39}$'),
  revision bigint not null default 0 check(revision>=0),
  active_release_id text references public.tap2work_catalog_releases(release_id),
  updated_at timestamptz not null default now(),
  check((revision=0)=(active_release_id is null))
);
insert into public.tap2work_catalog_channels(channel) values('stable');
create table public.tap2work_catalog_publication_events (
  request_id uuid primary key,
  actor_id uuid,
  operation text not null check(operation in ('seed','publish','rollback')),
  channel text not null references public.tap2work_catalog_channels(channel),
  from_release_id text references public.tap2work_catalog_releases(release_id),
  to_release_id text not null references public.tap2work_catalog_releases(release_id),
  expected_revision bigint not null,
  channel_revision bigint not null,
  draft_id uuid,
  draft_revision bigint,
  reason text not null,
  created_at timestamptz not null default now()
);

-- Immutable evidence remains after edits, rollback and account erasure. Actor UUIDs
-- in audit records deliberately have no cascading Auth foreign key.
create function public.tap2work_catalog_immutable() returns trigger
language plpgsql set search_path='' as $$
begin raise exception using errcode='55000',message='Catalog audit and releases are immutable'; end $$;
create trigger immutable_release before update or delete on public.tap2work_catalog_releases
for each row execute function public.tap2work_catalog_immutable();
create trigger immutable_review before update or delete on public.tap2work_catalog_reviews
for each row execute function public.tap2work_catalog_immutable();
create trigger immutable_publication before update or delete on public.tap2work_catalog_publication_events
for each row execute function public.tap2work_catalog_immutable();

create function public.tap2work_catalog_validate(p_release jsonb,p_payload_hash text)
returns void language plpgsql set search_path='' as $$
declare entry jsonb; step jsonb;
begin
  if p_payload_hash is null or p_payload_hash !~ '^[0-9a-f]{64}$'
    or jsonb_typeof(p_release) is distinct from 'object'
    or p_release->'schemaVersion' is distinct from '2'::jsonb
    or p_release->>'releaseId' is distinct from p_payload_hash
    or jsonb_typeof(p_release->'taxonomy') is distinct from 'object'
    or jsonb_typeof(p_release->'taxonomy'->'industries') is distinct from 'array'
    or jsonb_typeof(p_release->'taxonomy'->'purposes') is distinct from 'array'
    or jsonb_typeof(p_release->'entries') is distinct from 'array'
    or octet_length(p_release::text)>8388608 then
    raise exception using errcode='22023',message='Invalid catalog release';
  end if;
  if jsonb_array_length(p_release->'entries') not between 1 and 650
    or jsonb_array_length(p_release->'taxonomy'->'industries')=0
    or jsonb_array_length(p_release->'taxonomy'->'purposes')=0 then
    raise exception using errcode='22023',message='Invalid catalog dimensions';
  end if;
  if exists(select 1 from jsonb_array_elements(p_release->'entries') e
      group by e->>'sourceId' having count(*)>1) then
    raise exception using errcode='22023',message='Duplicate catalog source IDs';
  end if;
  for entry in select value from jsonb_array_elements(p_release->'entries') loop
    if jsonb_typeof(entry) is distinct from 'object' or entry->>'sourceId' is null
      or entry->>'sourceId' !~ '^[a-zA-Z0-9][a-zA-Z0-9_/-]{0,99}$'
      or jsonb_typeof(entry->'steps') is distinct from 'array' then
      raise exception using errcode='22023',message='Invalid catalog entry';
    end if;
    if jsonb_array_length(entry->'steps') not between 1 and 30
      or exists(select 1 from jsonb_array_elements(entry->'steps') s
        group by s->>'id' having count(*)>1) then
      raise exception using errcode='22023',message='Invalid or duplicate catalog Task IDs';
    end if;
    for step in select value from jsonb_array_elements(entry->'steps') loop
      if jsonb_typeof(step) is distinct from 'object' or step->>'id' is null
        or step->>'id' !~ '^[a-zA-Z0-9][a-zA-Z0-9_/-]{0,99}$' then
        raise exception using errcode='22023',message='Invalid catalog Task ID';
      end if;
    end loop;
  end loop;
end $$;

create function public.tap2work_catalog_require_role(p_actor_id uuid,p_roles text[])
returns void language plpgsql stable set search_path='' as $$
begin
  if p_actor_id is null or not exists(select 1 from public.tap2work_catalog_roles
    where user_id=p_actor_id and role=any(p_roles)) then
    raise exception using errcode='42501',message='Central content role required';
  end if;
end $$;

create function public.tap2work_catalog_actor_roles(p_actor_id uuid)
returns jsonb language sql stable security definer set search_path='' as $$
  select jsonb_build_object('roles',coalesce(jsonb_agg(role order by role),'[]'::jsonb))
    from public.tap2work_catalog_roles where user_id=p_actor_id
$$;
create function public.tap2work_catalog_read(p_channel text default 'stable')
returns jsonb language sql stable security definer set search_path='' as $$
  select jsonb_build_object('revision',c.revision,'release',r.payload)
  from public.tap2work_catalog_channels c
  left join public.tap2work_catalog_releases r on r.release_id=c.active_release_id
  where c.channel=p_channel
$$;

create function public.tap2work_catalog_draft_read(p_actor_id uuid,p_draft_id uuid)
returns jsonb language plpgsql stable security definer set search_path='' as $$
declare d public.tap2work_catalog_drafts; reviews jsonb;
begin
  perform public.tap2work_catalog_require_role(p_actor_id,array['researcher','editor','reviewer','publisher']);
  select * into d from public.tap2work_catalog_drafts where id=p_draft_id;
  if not found then return null; end if;
  select coalesce(jsonb_agg(jsonb_build_object('reviewId',id,'revision',draft_revision,
    'payloadHash',payload_hash,'reviewerId',reviewer_id,'outcome',outcome,'reason',reason,
    'createdAt',created_at) order by draft_revision,created_at),'[]'::jsonb) into reviews
    from public.tap2work_catalog_reviews where draft_id=d.id;
  return jsonb_build_object('draftId',d.id,'revision',d.revision,'payloadHash',d.payload_hash,
    'release',d.payload,'state',d.state,'summary',d.summary,'authorId',d.author_id,
    'contributorIds',to_jsonb(d.contributor_ids),'reviews',reviews,'updatedAt',d.updated_at);
end $$;

create function public.tap2work_catalog_draft_save(p_actor_id uuid,p_draft_id uuid,
  p_expected_revision bigint,p_release jsonb,p_payload_hash text,p_summary text)
returns jsonb language plpgsql security definer set search_path='' as $$
declare d public.tap2work_catalog_drafts;
begin
  perform public.tap2work_catalog_require_role(p_actor_id,array['researcher','editor']);
  perform public.tap2work_catalog_validate(p_release,p_payload_hash);
  if p_summary is null or length(trim(p_summary)) not between 1 and 2000 then
    raise exception using errcode='22023',message='Change summary required';
  end if;
  if p_draft_id is null then
    if p_expected_revision is distinct from 0::bigint then
      raise exception using errcode='40001',message='New draft revision must be zero';
    end if;
    insert into public.tap2work_catalog_drafts(author_id,contributor_ids,revision,payload_hash,payload,summary,state)
      values(p_actor_id,array[p_actor_id],1,p_payload_hash,p_release,trim(p_summary),'draft') returning * into d;
  else
    select * into d from public.tap2work_catalog_drafts where id=p_draft_id for update;
    if not found or d.revision is distinct from p_expected_revision then
      raise exception using errcode='40001',message='Catalog draft revision conflict';
    end if;
    if d.state='published' then raise exception using errcode='55000',message='Published draft is frozen; create a new draft'; end if;
    if d.author_id<>p_actor_id then
      perform public.tap2work_catalog_require_role(p_actor_id,array['editor']);
    end if;
    -- Each edit resets approval and binds authorship to the latest content editor.
    update public.tap2work_catalog_drafts set author_id=p_actor_id,contributor_ids=(select array_agg(distinct contributor) from unnest(contributor_ids || array[p_actor_id]) contributor),revision=revision+1,
      payload=p_release,payload_hash=p_payload_hash,summary=trim(p_summary),state='draft',updated_at=now()
      where id=p_draft_id returning * into d;
  end if;
  return jsonb_build_object('draftId',d.id,'revision',d.revision,'payloadHash',d.payload_hash,'state',d.state);
end $$;

create function public.tap2work_catalog_review(p_actor_id uuid,p_draft_id uuid,
  p_expected_revision bigint,p_payload_hash text,p_outcome text,p_reason text)
returns jsonb language plpgsql security definer set search_path='' as $$
declare d public.tap2work_catalog_drafts; rid uuid;
begin
  perform public.tap2work_catalog_require_role(p_actor_id,array['reviewer']);
  if p_outcome is null or p_outcome not in ('approved','rejected') or p_reason is null
    or length(trim(p_reason)) not between 1 and 2000 then
    raise exception using errcode='22023',message='Review outcome and reason required';
  end if;
  select * into d from public.tap2work_catalog_drafts where id=p_draft_id for update;
  if not found or d.revision is distinct from p_expected_revision or d.payload_hash is distinct from p_payload_hash then
    raise exception using errcode='40001',message='Catalog draft revision/hash conflict';
  end if;
  if p_actor_id=any(d.contributor_ids) then raise exception using errcode='42501',message='Author cannot review their own draft'; end if;
  if d.state<>'draft' then raise exception using errcode='55000',message='Draft is not awaiting review'; end if;
  insert into public.tap2work_catalog_reviews(draft_id,draft_revision,payload_hash,reviewer_id,outcome,reason)
    values(d.id,d.revision,d.payload_hash,p_actor_id,p_outcome,trim(p_reason)) returning id into rid;
  update public.tap2work_catalog_drafts set state=p_outcome,updated_at=now() where id=d.id;
  return jsonb_build_object('reviewId',rid,'draftId',d.id,'revision',d.revision,'payloadHash',d.payload_hash,'state',p_outcome);
end $$;

-- Internal transaction helper. requestId identifies the exact actor, intent and
-- expected revisions; retries cannot silently reuse a different request body.
create function public.tap2work_catalog_activate(p_actor_id uuid,p_operation text,
  p_release jsonb,p_payload_hash text,p_expected_revision bigint,p_request_id uuid,
  p_reason text,p_channel text,p_draft_id uuid default null,p_draft_revision bigint default null)
returns jsonb language plpgsql set search_path='' as $$
declare c public.tap2work_catalog_channels; e public.tap2work_catalog_publication_events; existing jsonb;
begin
  perform public.tap2work_catalog_validate(p_release,p_payload_hash);
  if p_request_id is null or p_expected_revision is null or p_reason is null
    or length(trim(p_reason)) not between 1 and 2000 then
    raise exception using errcode='22023',message='Publication request ID, revision and reason required';
  end if;
  perform pg_advisory_xact_lock(hashtextextended(p_request_id::text,761));
  select * into e from public.tap2work_catalog_publication_events where request_id=p_request_id;
  if found then
    if e.actor_id is distinct from p_actor_id or e.operation is distinct from p_operation
      or e.channel is distinct from p_channel or e.to_release_id is distinct from p_payload_hash
      or e.expected_revision is distinct from p_expected_revision or e.draft_id is distinct from p_draft_id
      or e.draft_revision is distinct from p_draft_revision or e.reason is distinct from trim(p_reason) then
      raise exception using errcode='40001',message='Publication request ID reused with different intent';
    end if;
    select payload into existing from public.tap2work_catalog_releases where release_id=p_payload_hash;
    if existing is distinct from p_release then raise exception using errcode='22023',message='Release ID content mismatch'; end if;
    return jsonb_build_object('revision',e.channel_revision,'releaseId',e.to_release_id);
  end if;
  select * into c from public.tap2work_catalog_channels where channel=p_channel for update;
  if not found then raise exception using errcode='22023',message='Unknown catalog channel'; end if;
  if c.revision is distinct from p_expected_revision then
    raise exception using errcode='40001',message='Catalog channel revision conflict';
  end if;
  if p_operation='seed' and c.revision<>0 then
    raise exception using errcode='55000',message='Catalog seed requires an empty channel';
  end if;
  insert into public.tap2work_catalog_releases(release_id,schema_version,payload,published_by)
    values(p_payload_hash,2,p_release,p_actor_id) on conflict(release_id) do nothing;
  select payload into existing from public.tap2work_catalog_releases where release_id=p_payload_hash;
  if existing is distinct from p_release then raise exception using errcode='22023',message='Release ID content mismatch'; end if;
  update public.tap2work_catalog_channels set revision=revision+1,active_release_id=p_payload_hash,updated_at=now()
    where channel=p_channel;
  insert into public.tap2work_catalog_publication_events(request_id,actor_id,operation,channel,
    from_release_id,to_release_id,expected_revision,channel_revision,draft_id,draft_revision,reason)
    values(p_request_id,p_actor_id,p_operation,p_channel,c.active_release_id,p_payload_hash,
      p_expected_revision,c.revision+1,p_draft_id,p_draft_revision,trim(p_reason));
  return jsonb_build_object('revision',c.revision+1,'releaseId',p_payload_hash);
end $$;

create function public.tap2work_catalog_seed(p_actor_id uuid,p_release jsonb,p_payload_hash text,
  p_request_id uuid,p_channel text default 'stable')
returns jsonb language plpgsql security definer set search_path='' as $$
begin
  -- Null actor is reserved for the service-only first-time migration seed.
  -- It cannot overwrite an initialized channel. Human seeds require publisher access.
  if p_actor_id is not null then
    perform public.tap2work_catalog_require_role(p_actor_id,array['publisher']);
  end if;
  return public.tap2work_catalog_activate(p_actor_id,'seed',p_release,p_payload_hash,0,p_request_id,
    'Initial catalog seed',p_channel);
end $$;

create function public.tap2work_catalog_publish(p_actor_id uuid,p_draft_id uuid,
  p_expected_draft_revision bigint,p_payload_hash text,p_expected_channel_revision bigint,
  p_request_id uuid,p_reason text,p_channel text default 'stable')
returns jsonb language plpgsql security definer set search_path='' as $$
declare d public.tap2work_catalog_drafts; result jsonb;
begin
  perform public.tap2work_catalog_require_role(p_actor_id,array['publisher']);
  select * into d from public.tap2work_catalog_drafts where id=p_draft_id for update;
  if not found or d.revision is distinct from p_expected_draft_revision or d.payload_hash is distinct from p_payload_hash then
    raise exception using errcode='40001',message='Catalog draft revision/hash conflict';
  end if;
  if d.state not in ('approved','published') or not exists(select 1 from public.tap2work_catalog_reviews
    where draft_id=d.id and draft_revision=d.revision and payload_hash=d.payload_hash
      and outcome='approved' and not reviewer_id=any(d.contributor_ids)) then
    raise exception using errcode='42501',message='Matching independent review required';
  end if;
  if d.state='published' and not exists(select 1 from public.tap2work_catalog_publication_events where request_id=p_request_id) then
    raise exception using errcode='55000',message='Draft already published';
  end if;
  result:=public.tap2work_catalog_activate(p_actor_id,'publish',d.payload,p_payload_hash,
    p_expected_channel_revision,p_request_id,p_reason,p_channel,d.id,d.revision);
  update public.tap2work_catalog_drafts set state='published',updated_at=now() where id=d.id and state<>'published';
  return result;
end $$;

create function public.tap2work_catalog_rollback(p_actor_id uuid,p_release_id text,
  p_expected_revision bigint,p_request_id uuid,p_reason text,p_channel text default 'stable')
returns jsonb language plpgsql security definer set search_path='' as $$
declare payload jsonb;
begin
  perform public.tap2work_catalog_require_role(p_actor_id,array['publisher']);
  -- Rollback may only return to a release that this same channel actually served.
  select r.payload into payload from public.tap2work_catalog_releases r where r.release_id=p_release_id
    and exists(select 1 from public.tap2work_catalog_publication_events e
      where e.channel=p_channel and e.to_release_id=r.release_id);
  if not found then raise exception using errcode='22023',message='Rollback release was never published on this channel'; end if;
  return public.tap2work_catalog_activate(p_actor_id,'rollback',payload,p_release_id,p_expected_revision,
    p_request_id,p_reason,p_channel);
end $$;

alter table public.tap2work_catalog_roles enable row level security;
alter table public.tap2work_catalog_drafts enable row level security;
alter table public.tap2work_catalog_reviews enable row level security;
alter table public.tap2work_catalog_releases enable row level security;
alter table public.tap2work_catalog_channels enable row level security;
alter table public.tap2work_catalog_publication_events enable row level security;
revoke all on public.tap2work_catalog_roles,public.tap2work_catalog_drafts,public.tap2work_catalog_reviews,
  public.tap2work_catalog_releases,public.tap2work_catalog_channels,public.tap2work_catalog_publication_events
  from public,anon,authenticated,service_role;
grant select on public.tap2work_catalog_roles,public.tap2work_catalog_drafts,public.tap2work_catalog_reviews,
  public.tap2work_catalog_releases,public.tap2work_catalog_channels,public.tap2work_catalog_publication_events to service_role;
-- Role registration is an explicit privileged DB administration step. No content
-- endpoint, workspace owner or research agent can grant itself these roles.
revoke all on function public.tap2work_catalog_immutable(),public.tap2work_catalog_validate(jsonb,text),
  public.tap2work_catalog_require_role(uuid,text[]),
  public.tap2work_catalog_activate(uuid,text,jsonb,text,bigint,uuid,text,text,uuid,bigint),
  public.tap2work_catalog_actor_roles(uuid),public.tap2work_catalog_read(text),
  public.tap2work_catalog_draft_read(uuid,uuid),public.tap2work_catalog_draft_save(uuid,uuid,bigint,jsonb,text,text),
  public.tap2work_catalog_review(uuid,uuid,bigint,text,text,text),
  public.tap2work_catalog_seed(uuid,jsonb,text,uuid,text),
  public.tap2work_catalog_publish(uuid,uuid,bigint,text,bigint,uuid,text,text),
  public.tap2work_catalog_rollback(uuid,text,bigint,uuid,text,text) from public,anon,authenticated,service_role;
grant execute on function public.tap2work_catalog_actor_roles(uuid),public.tap2work_catalog_read(text),
  public.tap2work_catalog_draft_read(uuid,uuid),public.tap2work_catalog_draft_save(uuid,uuid,bigint,jsonb,text,text),
  public.tap2work_catalog_review(uuid,uuid,bigint,text,text,text),
  public.tap2work_catalog_seed(uuid,jsonb,text,uuid,text),
  public.tap2work_catalog_publish(uuid,uuid,bigint,text,bigint,uuid,text,text),
  public.tap2work_catalog_rollback(uuid,text,bigint,uuid,text,text) to service_role;
notify pgrst,'reload schema';
commit;
