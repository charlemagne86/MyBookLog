# PERF-3 / PERF-4 — RLS init-plan + FK index

**Phase:** 2 (Performance) · **Status:** ✅ Complete (DB)
**Related:** [[PROJECT_ANALYSIS]] · [[Remediation-Index]] · [[PERF-1-2-5-6-client-perf]]

## PERF-3 — `auth.uid()` re-evaluated per row
All four `bookshelf_items` policies used bare `auth.uid()`, which Postgres re-evaluates for every row (advisory `auth_rls_initplan`).
- **Fix (migration `optimize_bookshelf_items_rls_and_index`):** dropped and recreated `bookshelf_items_{select,insert,update,delete}_own` using `(select auth.uid())`, which is evaluated once per statement. Matches the pattern the `users`/`bookshelf` policies already used.

## PERF-4 — Unindexed foreign key
`bookshelf_items.book_id` (FK to `books_catalog`) had no covering index (advisory `unindexed_foreign_keys`).
- **Fix:** `create index bookshelf_items_book_id_idx on public.bookshelf_items (book_id)`.

## Verification
- Supabase **performance advisors** after the migration: the four `auth_rls_initplan` warnings and the `unindexed_foreign_keys` finding are **gone**.
- One `unused_index` **INFO** now appears for the new index — expected, because it was just created and hasn't served a query yet. It will be exercised once the app deletes catalog rows / looks up shelves by book. No action.
