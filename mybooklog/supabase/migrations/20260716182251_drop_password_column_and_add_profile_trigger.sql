-- PLAIN ENGLISH: Two fixes. First, delete a leftover column that stored a
-- second, weaker copy of users' passwords — Supabase's login system already
-- stores them properly, so this copy was pure risk. Second, teach the
-- database to create each new user's profile row automatically at the moment
-- their account is created (copying their name from the signup form), so the
-- app never has to write to the profile table itself.
--
-- SEC-4: remove the redundant SHA-256 password store.
alter table public.users drop column if exists encrypted_password;

-- SEC-7 + BUG-7: provision the user profile server-side on signup.
create or replace function public.handle_new_user_profile()
returns trigger language plpgsql security definer set search_path = ''
as $$
begin
  insert into public.users (id, username, first_name, last_name)
  values (new.id, new.email,
          new.raw_user_meta_data ->> 'first_name',
          new.raw_user_meta_data ->> 'last_name')
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created_profile on auth.users;
create trigger on_auth_user_created_profile
  after insert on auth.users
  for each row execute function public.handle_new_user_profile();
