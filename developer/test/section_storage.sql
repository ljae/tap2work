-- Executed after the migration inside a transaction that is always rolled back.
do $$
declare uid uuid := gen_random_uuid(); wid uuid; body jsonb; ok boolean; old_time timestamptz;
begin
  insert into auth.users(id,email) values(uid,'storage-test-'||uid||'@example.invalid');
  wid := public.tap2work_bootstrap(uid,'Synthetic storage test',jsonb_build_object('revision',1,'store',jsonb_build_object('name','Test'),'workplace',jsonb_build_object('parts',jsonb_build_array()),'attendance',jsonb_build_array('untouched')));
  body := public.tap2work_read_workspace(uid);
  if body->'payload'->>'revision'<>'1' or body->'member'->>'role'<>'owner' then raise exception 'bootstrap roundtrip failed'; end if;
  select updated_at into old_time from public.tap2work_documents where workspace_id=wid and section='attendance';
  ok := public.tap2work_patch_state(wid,1,'{"workplace":{"parts":[{"id":"kitchen","name":"주방"}]}}');
  if not ok then raise exception 'patch failed'; end if;
  if public.tap2work_patch_state(wid,1,'{"workplace":{}}') then raise exception 'stale accepted'; end if;
  body := public.tap2work_read_workspace(uid);
  if body->'payload'->'workplace'->'parts'->0->>'name'<>'주방' or body->'payload'->>'revision'<>'2' then raise exception 'roundtrip failed'; end if;
  if (select updated_at from public.tap2work_documents where workspace_id=wid and section='attendance') is distinct from old_time then raise exception 'unrelated write'; end if;
  if (public.tap2work_read_workspace(uid,2,(body->>'window')::bigint,'owner',wid)->>'unchanged')::boolean is not true then raise exception 'conditional read failed'; end if;
  if public.tap2work_read_workspace(uid,2,(body->>'window')::bigint-1,'owner',wid) ? 'unchanged' then raise exception 'time invalidation failed'; end if;
  if public.tap2work_read_workspace(uid,2,(body->>'window')::bigint,'crew',wid) ? 'unchanged' then raise exception 'role invalidation failed'; end if;
  if has_table_privilege('authenticated','public.tap2work_documents','select') or has_function_privilege('authenticated','public.tap2work_read_workspace(uuid,bigint,bigint,text,uuid)','execute') then raise exception 'raw data exposed'; end if;
end $$;
select 'section roundtrip, CAS, unchanged, role/time isolation and grants passed' as verification;
