-- Isolated synthetic fixtures; no real operational data.
begin;
do $$
declare u uuid:=gen_random_uuid(); other_user uuid:=gen_random_uuid(); a uuid; b uuid; c uuid;
 req uuid:=gen_random_uuid(); context jsonb; result jsonb; body jsonb:='{"revision":1,"store":{"name":"A"},"tappers":[]}';
begin
 insert into auth.users(id,email) values(u,'multi@example.invalid'),(other_user,'other@example.invalid');
 a:=public.tap2work_create_workspace(u,'Owner',body,req);
 if public.tap2work_create_workspace(u,'Owner',body,req)<>a then raise exception 'duplicate creation'; end if;
 b:=public.tap2work_create_workspace(u,'Owner',jsonb_set(body,'{store,name}','"B"'),gen_random_uuid());
 c:=public.tap2work_create_workspace(other_user,'Other',body,gen_random_uuid());
 if (select count(*) from public.tap2work_members where user_id=u)<>2 then raise exception 'multiple memberships missing'; end if;
 result:=public.tap2work_read_workspace(u,null,null,null,b);
 if result->'member'->>'workspace_id'<>b::text or result->'payload'->'store'->>'name'<>'B' or jsonb_array_length(result->'workspaces')<>2 then raise exception 'wrong selected workspace'; end if;
 result:=public.tap2work_read_workspace(u,1,(result->>'window')::bigint,'owner',b);
 if result->>'unchanged'<>'true' or jsonb_array_length(result->'workspaces')<>2 then raise exception 'cache/list contract'; end if;
 result:=public.tap2work_read_workspace(u,null,null,null,c);
 if result->>'forbidden'<>'true' or result ? 'payload' then raise exception 'cross-store leak'; end if;
 perform public.tap2work_patch_state(b,1,'{"store":{"name":"B renamed"}}');
 if (public.tap2work_read_workspace(u,null,null,null,a)->'payload'->'store'->>'name')<>'A' then raise exception 'cross-store mutation'; end if;
 -- One sole-owner store plus one shared store; stale scope must abort all.
 insert into public.tap2work_members values(b,other_user,'owner','Other');
 context:=public.tap2work_account_context(u);
 if jsonb_array_length(context->'scope'->'workspaces')<>2 then raise exception 'incomplete deletion scope'; end if;
 perform public.tap2work_patch_state(b,2,'{"test":true}');
 result:=public.tap2work_erase_account(u,context->'scope',context->'payloads',true);
 if result->>'conflict'<>'true' or not exists(select 1 from public.tap2work_workspaces where id=a) then raise exception 'partial deletion on conflict'; end if;
 context:=public.tap2work_account_context(u);
 perform public.tap2work_erase_account(u,context->'scope',context->'payloads',true);
 if exists(select 1 from auth.users where id=u) or exists(select 1 from public.tap2work_workspaces where id=a) then raise exception 'sole-owned deletion incomplete'; end if;
 if (select created_by from public.tap2work_workspaces where id=b)<>other_user or not exists(select 1 from public.tap2work_state where workspace_id=b) then raise exception 'shared store not preserved'; end if;
 if not exists(select 1 from public.tap2work_workspaces where id=c) then raise exception 'unrelated store deleted'; end if;
 if has_function_privilege('authenticated','public.tap2work_create_workspace(uuid,text,jsonb,uuid)','execute') then raise exception 'public service RPC'; end if;
end $$;
rollback;
