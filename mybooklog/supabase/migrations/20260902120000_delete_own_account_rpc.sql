-- PLAIN ENGLISH: Teaches the database one safe, all-or-nothing procedure for
-- a user to permanently delete their own account: their shelf contents,
-- their shelf, their profile row, and finally their login itself. Because
-- it all happens as a single database transaction, a mid-operation failure
-- can never leave a half-deleted account behind.
create or replace function public.delete_own_account()
returns void
language plpgsql security definer set search_path = ''
as $$
declare
  v_uid uuid := auth.uid();
begin
  if v_uid is null then raise exception 'not authenticated' using errcode = '28000'; end if;

  -- Dependency order: children before parents. security definer bypasses
  -- RLS entirely, so these `where` clauses are the only thing scoping each
  -- delete to the caller's own data — do not remove them.
  delete from public.bookshelf_items where bookshelf_user_id = v_uid;
  delete from public.bookshelf where user_id = v_uid;
  delete from public.users where id = v_uid;
  delete from auth.users where id = v_uid;
end;
$$;

revoke all on function public.delete_own_account() from public;
grant execute on function public.delete_own_account() to authenticated;
