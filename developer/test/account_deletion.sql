-- Synthetic fixtures only. Run in an isolated database after the three migrations.
begin;
do $$
declare owner_id uuid:=gen_random_uuid(); crew_id uuid:=gen_random_uuid(); second_owner uuid:=gen_random_uuid();
  solo uuid:=gen_random_uuid(); wid uuid; context jsonb; result jsonb; sanitized jsonb;
begin
 insert into auth.users(id,email) values(owner_id,'owner@example.invalid'),(crew_id,'crew@example.invalid'),(second_owner,'second@example.invalid'),(solo,'solo@example.invalid');
 insert into auth.sessions(user_id) values(owner_id),(crew_id),(solo);
 insert into auth.identities(user_id) values(owner_id),(crew_id),(solo);
 wid:=public.tap2work_bootstrap(owner_id,'Owner','{"revision":1,"tappers":[],"private":"legacy PII"}');
 insert into public.tap2work_members values(wid,crew_id,'crew','Crew');
 context:=public.tap2work_account_context(crew_id);
 -- A stale confirmation must leave Auth and store unchanged.
 perform public.tap2work_patch_state(wid,1,'{"private":"changed"}');
 result:=public.tap2work_erase_account(crew_id,context->'scope','{"revision":1}',false);
 if result->>'conflict'<>'true' or not exists(select 1 from auth.users where id=crew_id) then raise exception 'stale scope deleted user'; end if;
 context:=public.tap2work_account_context(crew_id);
 -- Invalid sanitized payload rolls back, including identity deletion.
 begin
   perform public.tap2work_erase_account(crew_id,context->'scope','{}',false);
   raise exception 'missing revision accepted';
 exception when raise_exception then
   if sqlerrm='missing revision accepted' then raise; end if;
 end;
 if not exists(select 1 from auth.users where id=crew_id) then raise exception 'invalid payload removed user'; end if;
 result:=public.tap2work_erase_account(crew_id,context->'scope','{"revision":2,"tappers":[],"private":"scrubbed"}',false);
 if result->>'deleted'<>'true' then raise exception 'crew delete failed'; end if;
 if exists(select 1 from auth.users where id=crew_id) or exists(select 1 from auth.sessions where user_id=crew_id) or exists(select 1 from auth.identities where user_id=crew_id) then raise exception 'auth cascade failed'; end if;
 if not exists(select 1 from public.tap2work_workspaces where id=wid) or (select revision from public.tap2work_state where workspace_id=wid)<>3 then raise exception 'crew damaged store'; end if;
 if (select payload->>'private' from public.tap2work_state where workspace_id=wid)<>'scrubbed' or (select value#>>'{}' from public.tap2work_documents where workspace_id=wid and section='private')<>'scrubbed' then raise exception 'legacy/document erasure diverged'; end if;
 -- Deleting the original creator must transfer ownership, never cascade store.
 insert into public.tap2work_members values(wid,second_owner,'owner','Second');
 context:=public.tap2work_account_context(owner_id);
 perform public.tap2work_erase_account(owner_id,context->'scope',context->'payload',false);
 if (select created_by from public.tap2work_workspaces where id=wid)<>second_owner then raise exception 'creator transfer failed'; end if;
 -- Sole owner confirmation protects every membership; other Auth users survive.
 insert into public.tap2work_members values(wid,solo,'crew','Solo');
 context:=public.tap2work_account_context(second_owner);
 begin
   perform public.tap2work_erase_account(second_owner,context->'scope',null,false);
   raise exception 'confirmation bypass';
 exception when raise_exception then
   if sqlerrm='confirmation bypass' then raise; end if;
 end;
 perform public.tap2work_erase_account(second_owner,context->'scope',null,true);
 if exists(select 1 from public.tap2work_workspaces where id=wid) or exists(select 1 from public.tap2work_members where workspace_id=wid) or exists(select 1 from public.tap2work_documents where workspace_id=wid) then raise exception 'store cascade incomplete'; end if;
 if not exists(select 1 from auth.users where id=solo) then raise exception 'other crew Auth deleted'; end if;
 -- Account with no store still deletes its Auth sessions/identity.
 context:=public.tap2work_account_context(solo);
 perform public.tap2work_erase_account(solo,context->'scope',null,false);
 if exists(select 1 from auth.users where id=solo) then raise exception 'empty account delete failed'; end if;
 if has_function_privilege('authenticated','public.tap2work_erase_account(uuid,jsonb,jsonb,boolean)','execute') or has_function_privilege('anon','public.tap2work_account_context(uuid)','execute') then raise exception 'public erasure exposed'; end if;
 if not has_function_privilege('service_role','public.tap2work_erase_account(uuid,jsonb,jsonb,boolean)','execute') then raise exception 'service grant missing'; end if;
end $$;
rollback;
