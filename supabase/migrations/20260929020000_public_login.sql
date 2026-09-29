begin;
-- Service-only existence check; no user creation and no raw Auth data exposed.
create or replace function public.tap2work_public_login_account(p_email text)
returns uuid language sql stable security definer set search_path = '' as $$
  select id from auth.users where lower(email) = lower(p_email) and deleted_at is null limit 1;
$$;
revoke all on function public.tap2work_public_login_account(text) from public, anon, authenticated;
grant execute on function public.tap2work_public_login_account(text) to service_role;
commit;
