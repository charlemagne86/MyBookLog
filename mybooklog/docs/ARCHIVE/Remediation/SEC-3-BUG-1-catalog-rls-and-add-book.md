# SEC-3 + BUG-1 — Catalog RLS + atomic add-book RPC

**Phase:** 0 (Stop the bleeding) · **Status:** ✅ Complete (DB + client)
**Related:** [[PROJECT_ANALYSIS]] · [[Remediation-Index]]

## Problems fixed together
- **SEC-3:** `public.books_catalog` had Row Level Security **disabled** — anyone with the anon key could read/modify/delete all rows.
- **BUG-1:** the client always **inserted a new catalog row** on add, so a second user adding an already-catalogued ISBN hit the `books_catalog_isbn_unique` violation → "Failed to add book". These are coupled: naively enabling RLS would have broken adds entirely (no INSERT policy, blind dedup check).

## Actions taken (database — applied via migrations)
1. **`add_book_to_shelf(p_isbn, p_title, p_author, p_thumbnail_uri)` RPC** — `SECURITY DEFINER`, `search_path = ''`. It:
   - rejects unauthenticated callers (`auth.uid()` null) and blank isbn/title;
   - **upserts** the catalog row `on conflict (isbn)` — reusing the shared row if the book already exists;
   - links it to the caller's shelf `on conflict do nothing`;
   - returns `jsonb { book_id, already_on_shelf }` so the client can show the right message.
   - Migration: `add_book_to_shelf_rpc_and_catalog_rls`.
2. **Enabled RLS** on `books_catalog`; dropped the stale `bookshelf_items_catalog_select` policy; added `books_catalog_select_authenticated` (SELECT, `to authenticated`, `using (true)` — catalog metadata is non-sensitive). **No INSERT/UPDATE/DELETE policies** — all writes go through the RPC.
3. **Revoked EXECUTE from `anon`** (migration `revoke_add_book_rpc_from_anon`); granted only to `authenticated`.

## Actions taken (client — `lib/main.dart`)
- Replaced the client-side dedup query + two direct inserts in `_addSelectedBook` with a single `supabase.rpc('add_book_to_shelf', params: {...})` call, reading `already_on_shelf` to preserve the "already on your bookshelf" message.

## Verification
- Supabase **security advisors**: the three `books_catalog` RLS findings (`rls_disabled_in_public`, `policy_exists_rls_disabled`, `rls_disabled` critical) are **gone**.
- DB state check: `catalog_rls_enabled = true`, `catalog_policies = 1`, `rpc_exists = 1`.
- `flutter analyze` — clean (no new issues).

## Accepted residual finding
- Advisor `authenticated_security_definer_function_executable` (WARN) remains **by design**: the RPC is *meant* to be callable by signed-in users and guards internally on `auth.uid()`. Documented in [[SEC-6-auth-hardening]].
