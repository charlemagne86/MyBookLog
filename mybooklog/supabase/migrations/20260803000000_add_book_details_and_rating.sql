-- PLAIN ENGLISH: The bookshelf's new "book details" panel needs more than a
-- title, author, and cover to be useful — a summary, page count, publisher,
-- category, and Google's own rating. This adds columns to hold that data
-- (captured once, when a book is added, rather than re-fetched from Google
-- every time the panel opens — so the panel opens instantly and still works
-- offline). It also adds a `rating` column so a user's own 1-5 star rating
-- for a book on their shelf is actually saved, not just shown in the UI.
--
-- TECHNICAL:
-- 1. books_catalog gets the richer, shared-across-users book metadata.
--    published_date is stored as text, not a real date/timestamp column,
--    because Google returns dates at varying granularity ("2016",
--    "2016-10", "2016-10-25") that a date type can't represent uniformly.
-- 2. bookshelf_items gets `rating`, a per-user/per-book value, constrained
--    to 1-5 (or null, meaning "not rated"). No RLS change needed — the
--    existing bookshelf_items_update_own policy already scopes updates to
--    the row's own owner.
-- 3. add_book_to_shelf is recreated with the new catalog fields as
--    parameters (a signature change, so the old 4-arg version is dropped
--    first) and the same revoke/grant lockdown as before is re-applied.

alter table public.books_catalog
  add column if not exists description text,
  add column if not exists page_count integer,
  add column if not exists published_date text,
  add column if not exists publisher text,
  add column if not exists categories text[],
  add column if not exists google_average_rating numeric(2, 1),
  add column if not exists google_ratings_count integer;

alter table public.bookshelf_items
  add column if not exists rating smallint;

alter table public.bookshelf_items
  drop constraint if exists bookshelf_items_rating_check;
alter table public.bookshelf_items
  add constraint bookshelf_items_rating_check check (rating between 1 and 5);

drop function if exists public.add_book_to_shelf(text, text, text, text);

create or replace function public.add_book_to_shelf(
  p_isbn text,
  p_title text,
  p_author text,
  p_thumbnail_uri text,
  p_description text default null,
  p_page_count integer default null,
  p_published_date text default null,
  p_publisher text default null,
  p_categories text[] default null,
  p_google_average_rating numeric default null,
  p_google_ratings_count integer default null
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

  insert into public.books_catalog (
    isbn, title, author, thumbnail_uri, description, page_count,
    published_date, publisher, categories, google_average_rating,
    google_ratings_count
  )
  values (
    btrim(p_isbn), p_title, p_author, p_thumbnail_uri, p_description,
    p_page_count, p_published_date, p_publisher, p_categories,
    p_google_average_rating, p_google_ratings_count
  )
  on conflict (isbn) do update
    set title = excluded.title,
        author = coalesce(excluded.author, public.books_catalog.author),
        thumbnail_uri = coalesce(excluded.thumbnail_uri, public.books_catalog.thumbnail_uri),
        description = coalesce(excluded.description, public.books_catalog.description),
        page_count = coalesce(excluded.page_count, public.books_catalog.page_count),
        published_date = coalesce(excluded.published_date, public.books_catalog.published_date),
        publisher = coalesce(excluded.publisher, public.books_catalog.publisher),
        categories = coalesce(excluded.categories, public.books_catalog.categories),
        google_average_rating = coalesce(excluded.google_average_rating, public.books_catalog.google_average_rating),
        google_ratings_count = coalesce(excluded.google_ratings_count, public.books_catalog.google_ratings_count)
  returning id into v_book_id;

  insert into public.bookshelf_items (bookshelf_user_id, book_id)
  values (v_uid, v_book_id)
  on conflict (bookshelf_user_id, book_id) do nothing;
  v_added := found;

  return jsonb_build_object('book_id', v_book_id, 'already_on_shelf', not v_added);
end;
$$;

revoke all on function public.add_book_to_shelf(
  text, text, text, text, text, integer, text, text, text[], numeric, integer
) from public;
grant execute on function public.add_book_to_shelf(
  text, text, text, text, text, integer, text, text, text[], numeric, integer
) to authenticated;
