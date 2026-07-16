-- Trigger functions must never be callable as PostgREST RPCs. The baseline
-- handle_new_user_bookshelf() was already locked to the trigger owner
-- (service_role only), but handle_new_user_profile() (added in the SEC-7
-- remediation) and set_updated_at() kept their default PUBLIC EXECUTE grant,
-- exposing them at /rest/v1/rpc/. Revoking EXECUTE does not affect trigger
-- firing (triggers run in the definer/owner context, not via role grants).
revoke execute on function public.handle_new_user_profile() from public, anon, authenticated;
revoke execute on function public.set_updated_at() from public, anon, authenticated;
