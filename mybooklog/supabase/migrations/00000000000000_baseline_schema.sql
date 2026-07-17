-- PLAIN ENGLISH: This file describes the database's original layout — the
-- four filing cabinets the app stores everything in:
--   * users           — one row per person: their name and email.
--   * bookshelf       — one row per person: "this person has a shelf".
--   * books_catalog   — one row per unique book anyone has ever added
--                       (title, author, ISBN, cover picture). Shared by all.
--   * bookshelf_items — the links: "this person's shelf contains this book",
--                       plus whether they've read it and when.
-- It also sets up automatic behaviors (e.g. "when a new account is created,
-- give it an empty shelf") and the privacy rules ("Row Level Security") that
-- make the database itself refuse to show anyone another person's shelf.
--
-- Baseline schema as it existed BEFORE the Phase 0-3 remediation.
-- Reconstructed from the live database (the schema was originally built via the
-- Supabase dashboard, so no prior migrations existed). The remediation
-- migrations that follow transform this baseline into the current state.
--
-- NOTE: `auth.users` and the `auth.uid()` function are provided by Supabase.

-- ---------------------------------------------------------------------------
-- Tables
-- ---------------------------------------------------------------------------
create table if not exists public.users (
  id uuid primary key references auth.users (id),
  username text not null unique,
  first_name text,
  last_name text,
  encrypted_password text not null,               -- dropped in a later migration (SEC-4)
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.bookshelf (
  user_id uuid primary key references auth.users (id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.books_catalog (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  author text,
  isbn text unique,
  thumbnail_uri text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.bookshelf_items (
  bookshelf_user_id uuid not null references public.bookshelf (user_id),
  book_id uuid not null references public.books_catalog (id),
  is_read boolean not null default false,
  marked_read_on timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (bookshelf_user_id, book_id)
);

-- ---------------------------------------------------------------------------
-- Functions & triggers (original definitions)
-- ---------------------------------------------------------------------------
create or replace function public.set_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create or replace function public.handle_new_user_bookshelf()
returns trigger language plpgsql security definer set search_path to 'public' as $$
begin
  insert into public.bookshelf (user_id) values (new.id)
  on conflict (user_id) do nothing;
  return new;
end;
$$;

create trigger set_bookshelf_updated_at before update on public.bookshelf
  for each row execute function public.set_updated_at();
create trigger trg_users_updated_at before update on public.users
  for each row execute function public.set_updated_at();
create trigger on_auth_user_created_bookshelf after insert on auth.users
  for each row execute function public.handle_new_user_bookshelf();

-- ---------------------------------------------------------------------------
-- Row Level Security (note: books_catalog RLS was DISABLED at baseline)
-- ---------------------------------------------------------------------------
alter table public.users enable row level security;
alter table public.bookshelf enable row level security;
alter table public.bookshelf_items enable row level security;

create policy users_select_own on public.users
  for select to authenticated using (id = (select auth.uid()));
create policy users_insert_own on public.users
  for insert to authenticated with check (id = (select auth.uid()));
create policy users_update_own on public.users
  for update to authenticated using (id = (select auth.uid())) with check (id = (select auth.uid()));
create policy users_delete_own on public.users
  for delete to authenticated using (id = (select auth.uid()));

create policy bookshelf_select_own on public.bookshelf
  for select to authenticated using (user_id = (select auth.uid()));
create policy bookshelf_insert_own on public.bookshelf
  for insert to authenticated with check (user_id = (select auth.uid()));
create policy bookshelf_update_own on public.bookshelf
  for update to authenticated using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));
create policy bookshelf_delete_own on public.bookshelf
  for delete to authenticated using (user_id = (select auth.uid()));

-- Original bookshelf_items policies used bare auth.uid() (optimized later, PERF-3).
create policy bookshelf_items_select_own on public.bookshelf_items
  for select to authenticated using (bookshelf_user_id = auth.uid());
create policy bookshelf_items_insert_own on public.bookshelf_items
  for insert to authenticated with check (bookshelf_user_id = auth.uid());
create policy bookshelf_items_update_own on public.bookshelf_items
  for update to authenticated using (bookshelf_user_id = auth.uid()) with check (bookshelf_user_id = auth.uid());
create policy bookshelf_items_delete_own on public.bookshelf_items
  for delete to authenticated using (bookshelf_user_id = auth.uid());

-- books_catalog had a SELECT policy authored but RLS was NOT enabled (SEC-3).
create policy bookshelf_items_catalog_select on public.books_catalog
  for select to authenticated using (
    exists (
      select 1 from public.bookshelf_items bi
      where bi.book_id = books_catalog.id and bi.bookshelf_user_id = auth.uid()
    )
  );
