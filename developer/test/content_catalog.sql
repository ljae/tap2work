-- Synthetic central-content integration assertions. Run in a rolled-back transaction.
create function pg_temp.expect_catalog_error(p_sql text,p_state text) returns void language plpgsql as $$
begin
  begin execute p_sql;
  exception when others then
    if SQLSTATE=p_state then return; end if;
    raise exception 'Expected %, got %: %',p_state,SQLSTATE,SQLERRM;
  end;
  raise exception 'Expected % but operation succeeded: %',p_state,p_sql;
end $$;

do $$
declare
  author uuid:=gen_random_uuid(); reviewer uuid:=gen_random_uuid(); publisher uuid:=gen_random_uuid(); outsider uuid:=gen_random_uuid(); other_publisher uuid:=gen_random_uuid(); other_editor uuid:=gen_random_uuid();
  release_a jsonb:='{"schemaVersion":2,"releaseId":"aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa","taxonomy":{"industries":[{"id":"food"}],"purposes":[{"id":"quality"}]},"entries":[{"sourceId":"synthetic/tap","steps":[{"id":"synthetic/task","title":"Synthetic A","manual":"Test only"}]}]}';
  release_b jsonb; release_c jsonb; draft jsonb; second_draft jsonb; result jsonb; request_id uuid:=gen_random_uuid(); seed_request uuid:=gen_random_uuid(); did uuid;
  row_count bigint;
begin
  insert into auth.users(id) values(author),(reviewer),(publisher),(outsider),(other_publisher),(other_editor);
  insert into public.tap2work_catalog_roles(user_id,role) values(author,'editor'),(author,'reviewer'),(reviewer,'reviewer'),(publisher,'publisher'),(other_publisher,'publisher'),(other_editor,'editor');
  if public.tap2work_catalog_actor_roles(outsider)->'roles'<>'[]'::jsonb then raise exception 'Unregistered actor received roles'; end if;
  if public.tap2work_catalog_read()->>'revision'<>'0' then raise exception 'Channel is not initially empty'; end if;
  release_b:=jsonb_set(jsonb_set(release_a,'{releaseId}',to_jsonb(repeat('b',64))),'{entries,0,steps,0,title}','"Synthetic B"');
  release_c:=jsonb_set(jsonb_set(release_a,'{releaseId}',to_jsonb(repeat('c',64))),'{entries,0,steps,0,title}','"Synthetic C"');
  perform pg_temp.expect_catalog_error(format('select public.tap2work_catalog_seed(%L,%L::jsonb,%L,%L)',outsider,release_a,repeat('a',64),seed_request),'42501');
  result:=public.tap2work_catalog_seed(null,release_a,repeat('a',64),seed_request);
  if result->>'revision'<>'1' or public.tap2work_catalog_read()->'release' is distinct from release_a then raise exception 'Seed/read roundtrip failed'; end if;
  if public.tap2work_catalog_seed(null,release_a,repeat('a',64),seed_request) is distinct from result then raise exception 'Seed retry changed result'; end if;
  perform pg_temp.expect_catalog_error(format('select public.tap2work_catalog_seed(null,%L::jsonb,%L,%L)',release_b,repeat('b',64),gen_random_uuid()),'40001');
  perform pg_temp.expect_catalog_error(format('select public.tap2work_catalog_draft_save(%L,null,0,%L::jsonb,%L,%L)',outsider,release_b,repeat('b',64),'Test'),'42501');
  perform pg_temp.expect_catalog_error(format('select public.tap2work_catalog_draft_save(%L,null,0,%L::jsonb,%L,%L)',author,release_b,repeat('c',64),'Test'),'22023');
  perform pg_temp.expect_catalog_error(format('select public.tap2work_catalog_draft_save(%L,null,0,%L::jsonb,%L,%L)',author,release_b-'taxonomy',repeat('b',64),'Test'),'22023');
  perform pg_temp.expect_catalog_error(format('select public.tap2work_catalog_draft_save(%L,null,0,%L::jsonb,%L,%L)',author,jsonb_set(release_b,'{schemaVersion}','3'),repeat('b',64),'Incompatible schema'),'22023');
  perform pg_temp.expect_catalog_error(format('select public.tap2work_catalog_draft_save(%L,null,0,%L::jsonb,%L,%L)',author,jsonb_set(release_b,'{entries}',(release_b->'entries')||(release_b->'entries')),repeat('b',64),'Duplicate sources'),'22023');
  draft:=public.tap2work_catalog_draft_save(author,null,0,release_b,repeat('b',64),'Synthetic B change'); did:=(draft->>'draftId')::uuid;
  perform pg_temp.expect_catalog_error(format('select public.tap2work_catalog_draft_read(%L,%L)',outsider,did),'42501');
  if public.tap2work_catalog_draft_read(reviewer,did)->'release' is distinct from release_b then raise exception 'Reviewer could not read exact draft'; end if;
  perform pg_temp.expect_catalog_error(format('select public.tap2work_catalog_publish(%L,%L,1,%L,1,%L,%L)',publisher,did,repeat('b',64),gen_random_uuid(),'Unreviewed'),'42501');
  perform pg_temp.expect_catalog_error(format('select public.tap2work_catalog_review(%L,%L,1,%L,%L,%L)',author,did,repeat('b',64),'approved','Self review'),'42501');
  perform public.tap2work_catalog_review(reviewer,did,1,repeat('b',64),'approved','Synthetic independent review');
  draft:=public.tap2work_catalog_draft_save(author,did,1,release_c,repeat('c',64),'Edit invalidates approval');
  if draft->>'revision'<>'2' or draft->>'state'<>'draft' then raise exception 'Edit did not reset approval'; end if;
  perform pg_temp.expect_catalog_error(format('select public.tap2work_catalog_draft_save(%L,%L,1,%L::jsonb,%L,%L)',author,did,release_b,repeat('b',64),'Stale edit'),'40001');
  perform pg_temp.expect_catalog_error(format('select public.tap2work_catalog_review(%L,%L,1,%L,%L,%L)',reviewer,did,repeat('b',64),'approved','Stale review'),'40001');
  perform pg_temp.expect_catalog_error(format('select public.tap2work_catalog_publish(%L,%L,2,%L,1,%L,%L)',publisher,did,repeat('c',64),request_id,'Approval from old content'),'42501');
  perform public.tap2work_catalog_review(reviewer,did,2,repeat('c',64),'approved','Review exact new revision');
  perform pg_temp.expect_catalog_error(format('select public.tap2work_catalog_publish(%L,%L,2,%L,0,%L,%L)',publisher,did,repeat('c',64),request_id,'Publish C'),'40001');
  if public.tap2work_catalog_read()->>'revision'<>'1' or exists(select 1 from public.tap2work_catalog_releases where release_id=repeat('c',64)) then raise exception 'Stale publication left partial writes'; end if;
  result:=public.tap2work_catalog_publish(publisher,did,2,repeat('c',64),1,request_id,'Publish C');
  if result->>'revision'<>'2' or public.tap2work_catalog_read()->'release' is distinct from release_c then raise exception 'Approved publish failed'; end if;
  if public.tap2work_catalog_publish(publisher,did,2,repeat('c',64),1,request_id,'Publish C') is distinct from result then raise exception 'Publish retry changed result'; end if;
  perform pg_temp.expect_catalog_error(format('select public.tap2work_catalog_publish(%L,%L,2,%L,1,%L,%L)',publisher,did,repeat('c',64),request_id,'Different reason'),'40001');
  perform pg_temp.expect_catalog_error(format('select public.tap2work_catalog_draft_save(%L,%L,2,%L::jsonb,%L,%L)',author,did,release_b,repeat('b',64),'Edit published'),'55000');
  perform pg_temp.expect_catalog_error(format('select public.tap2work_catalog_publish(%L,%L,2,%L,1,%L,%L)',other_publisher,did,repeat('c',64),request_id,'Publish C'),'40001');
  second_draft:=public.tap2work_catalog_draft_save(author,null,0,release_b,repeat('b',64),'Competing approved release');
  perform public.tap2work_catalog_review(reviewer,(second_draft->>'draftId')::uuid,1,repeat('b',64),'approved','Review B');
  perform pg_temp.expect_catalog_error(format('select public.tap2work_catalog_publish(%L,%L,1,%L,1,%L,%L)',publisher,second_draft->>'draftId',repeat('b',64),gen_random_uuid(),'Competing publish'),'40001');
  perform pg_temp.expect_catalog_error(format('update public.tap2work_catalog_releases set payload=%L::jsonb where release_id=%L',release_b,repeat('a',64)),'55000');
  perform pg_temp.expect_catalog_error('delete from public.tap2work_catalog_reviews','55000');
  perform pg_temp.expect_catalog_error('delete from public.tap2work_catalog_publication_events','55000');
  perform pg_temp.expect_catalog_error(format('select public.tap2work_catalog_rollback(%L,%L,2,%L,%L)',publisher,repeat('b',64),gen_random_uuid(),'Never published'),'22023');
  result:=public.tap2work_catalog_rollback(publisher,repeat('a',64),2,gen_random_uuid(),'Restore previous known content');
  if result->>'revision'<>'3' or public.tap2work_catalog_read()->'release' is distinct from release_a then raise exception 'Rollback did not atomically increment revision'; end if;
  select count(*) into row_count from public.tap2work_catalog_publication_events;
  if row_count<>3 then raise exception 'Unexpected publication audit count %',row_count; end if;
  if (select count(*) from public.tap2work_catalog_reviews)<>3 then raise exception 'Old review history was lost'; end if;
  if (select count(*) from public.tap2work_catalog_releases)<>2 then raise exception 'Immutable release history changed'; end if;
  -- An editor cannot evade the independent-review rule by transferring authorship.
  draft:=public.tap2work_catalog_draft_save(author,null,0,release_b,repeat('b',64),'Original contributor');
  draft:=public.tap2work_catalog_draft_save(other_editor,(draft->>'draftId')::uuid,1,release_b,repeat('b',64),'Other editor takes over');
  perform pg_temp.expect_catalog_error(format('select public.tap2work_catalog_review(%L,%L,2,%L,%L,%L)',author,draft->>'draftId',repeat('b',64),'approved','Previous author tries review'),'42501');
  -- Reusing an existing immutable release ID with another body fails without
  -- changing the channel or leaving an audit event.
  draft:=public.tap2work_catalog_draft_save(author,null,0,jsonb_set(release_b,'{releaseId}',to_jsonb(repeat('a',64))),repeat('a',64),'Mismatched existing release body');
  perform public.tap2work_catalog_review(reviewer,(draft->>'draftId')::uuid,1,repeat('a',64),'approved','Synthetic review of conflicting ID');
  perform pg_temp.expect_catalog_error(format('select public.tap2work_catalog_publish(%L,%L,1,%L,3,%L,%L)',publisher,draft->>'draftId',repeat('a',64),gen_random_uuid(),'Attempt conflicting ID'),'22023');
  if public.tap2work_catalog_read()->>'revision'<>'3' then raise exception 'Release mismatch changed active channel'; end if;
  if has_table_privilege('anon','public.tap2work_catalog_releases','select')
    or has_table_privilege('authenticated','public.tap2work_catalog_drafts','insert')
    or has_table_privilege('service_role','public.tap2work_catalog_roles','insert')
    or has_table_privilege('service_role','public.tap2work_catalog_channels','update')
    or has_function_privilege('authenticated','public.tap2work_catalog_publish(uuid,uuid,bigint,text,bigint,uuid,text,text)','execute')
    or has_function_privilege('service_role','public.tap2work_catalog_activate(uuid,text,jsonb,text,bigint,uuid,text,text,uuid,bigint)','execute') then raise exception 'Raw catalog data or internal mutations exposed'; end if;
end $$;
-- Prove grants at runtime, rather than merely asserting catalog privilege metadata.
set local role authenticated;
select pg_temp.expect_catalog_error('select public.tap2work_catalog_read()','42501');
select pg_temp.expect_catalog_error('select * from public.tap2work_catalog_roles','42501');
reset role;
set local role service_role;
select public.tap2work_catalog_read();
select pg_temp.expect_catalog_error('update public.tap2work_catalog_channels set revision=revision+1','42501');
reset role;
select 'central content roles, seed, CAS, independent exact-hash review, publication retries, immutability, rollback and grants passed' as verification;
