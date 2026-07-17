-- PLAIN ENGLISH: This teaches the database a single safe procedure for
-- adding a book to a shelf, called `add_book_to_shelf`. In one all-or-nothing
-- step it: (1) checks the caller is logged in and provided an ISBN and title,
-- (2) files the book into the shared catalog — or updates the existing entry
-- if the ISBN is already known, (3) links it to the caller's shelf, and
-- (4) reports back whether it was already there. Because both writes happen
-- together, a failure can never leave a half-added book. Finally, it turns on
-- the privacy enforcement for the catalog that was accidentally left off.
--
-- SEC-3 + BUG-1: atomic add-book RPC, then lock down books_catalog with RLS.
create or replace function public.add_book_to_shelf(
  p_isbn text, p_title text, p_author text, p_thumbnail_uri text
) returns jsonb
language plpgsql security definer set search_path = ''
as $$
declare
  v_uid uuid := auth.uid();
  v_book_id uuid;
  v_added boolean;
begin
  if v_uid is null then raise exception 'not authenticated' using errcode = '28000'; end if;
  if p_isbn is null or length(btrim(p_isbn)) = 0 then raise exception 'isbn required' using errcode = '22023'; end if;
  if p_title is null or length(btrim(p_title)) = 0 then raise exception 'title required' using errcode = '22023'; end if;

  insert into public.books_catalog (isbn, title, author, thumbnail_uri)
  values (btrim(p_isbn), p_title, p_author, p_thumbnail_uri)
  on conflict (isbn) do update
    set title = excluded.title,
        author = coalesce(excluded.author, public.books_catalog.author),
        thumbnail_uri = coalesce(excluded.thumbnail_uri, public.books_catalog.thumbnail_uri)
  returning id into v_book_id;

  insert into public.bookshelf_items (bookshelf_user_id, book_id)
  values (v_uid, v_book_id)
  on conflict (bookshelf_user_id, book_id) do nothing;
  v_added := found;

  return jsonb_build_object('book_id', v_book_id, 'already_on_shelf', not v_added);
end;
$$;

revoke all on function public.add_book_to_shelf(text, text, text, text) from public;
grant execute on function public.add_book_to_shelf(text, text, text, text) to authenticated;

alter table public.books_catalog enable row level security;
drop policy if exists bookshelf_items_catalog_select on public.books_catalog;
create policy books_catalog_select_authenticated
  on public.books_catalog for select to authenticated using (true);
