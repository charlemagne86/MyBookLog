-- PLAIN ENGLISH: Two speed improvements, no behavior change. First, the
-- privacy rules on shelf entries used to re-ask "who is the current user?"
-- for every single row they checked; now they ask once per query. Second, we
-- add an index — like a book's alphabetical index — so finding which shelves
-- contain a given book no longer requires reading the whole table.
--
-- PERF-3: evaluate auth.uid() once per statement via scalar subquery.
drop policy if exists bookshelf_items_select_own on public.bookshelf_items;
create policy bookshelf_items_select_own on public.bookshelf_items
  for select to authenticated using (bookshelf_user_id = (select auth.uid()));

drop policy if exists bookshelf_items_insert_own on public.bookshelf_items;
create policy bookshelf_items_insert_own on public.bookshelf_items
  for insert to authenticated with check (bookshelf_user_id = (select auth.uid()));

drop policy if exists bookshelf_items_update_own on public.bookshelf_items;
create policy bookshelf_items_update_own on public.bookshelf_items
  for update to authenticated
  using (bookshelf_user_id = (select auth.uid()))
  with check (bookshelf_user_id = (select auth.uid()));

drop policy if exists bookshelf_items_delete_own on public.bookshelf_items;
create policy bookshelf_items_delete_own on public.bookshelf_items
  for delete to authenticated using (bookshelf_user_id = (select auth.uid()));

-- PERF-4: cover the FK to books_catalog.
create index if not exists bookshelf_items_book_id_idx
  on public.bookshelf_items (book_id);
