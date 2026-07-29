# ARCH-3 — SQL migrations + auth-aware routing (go_router / Provider)

**Phase:** 3 (Architecture) · **Status:** ✅ Complete (code + DB)
**Related:** [[PROJECT_ANALYSIS]] · [[Remediation-Index]] · [[ARCH-1-refactor-structure]] · [[BUG-2-3-4-auth-ux-session]]

This point covers two related architecture gaps: no versioned database schema, and imperative/ad-hoc navigation with no reactive auth state. Also subsumes **PERF-7** (whole-app rebuild on theme change), which is resolved for free by moving to a state-management package.

## Part A — Database migrations captured as versioned SQL

**Problem:** the Supabase migration table was empty — the entire schema (tables, RLS policies, triggers, functions, the RPC) was built by hand in the dashboard, with no reproducible record.

**What was done:** captured the schema as SQL migration files under `supabase/migrations/`:
- `00000000000000_baseline_schema.sql` — the schema **as it existed before** this remediation (tables, triggers, all RLS policies, and the note that `books_catalog` RLS was disabled at baseline). This is the reproducible starting point.
- Five timestamped remediation migrations that transform the baseline into the current state:
  - `..181707_add_book_to_shelf_rpc_and_catalog_rls` — the `add_book_to_shelf` RPC + enabling RLS on `books_catalog` ([[SEC-3-BUG-1-catalog-rls-and-add-book]]).
  - `..181717_pin_set_updated_at_search_path` — pins `set_updated_at` search_path ([[SEC-6-auth-hardening]]).
  - `..181757_revoke_add_book_rpc_from_anon` — revokes EXECUTE on the RPC from `anon`.
  - `..182251_drop_password_column_and_add_profile_trigger` — drops `encrypted_password` + adds the profile-provisioning trigger ([[SEC-4-drop-password-column]], [[SEC-7-BUG-7-provisioning-trigger]]).
  - `..182811_optimize_bookshelf_items_rls_and_index` — RLS init-plan optimization + FK index ([[PERF-3-4-rls-initplan-and-index]]).
  - `20260717000000_revoke_execute_on_trigger_functions` — revokes PUBLIC `EXECUTE` on the trigger functions `handle_new_user_profile()` and `set_updated_at()` so they can't be called as RPCs (found in the final advisor pass; see [[SEC-7-BUG-7-provisioning-trigger]]).

> **Note on tooling.** The Supabase CLI was not available in this environment, so each migration was applied to the live project via the MCP `apply_migration` tool, and the corresponding `.sql` file was written into `supabase/migrations/` with the matching version timestamp. The repo files and the live database's migration history line up. Going forward, all schema changes should be made as new migration files (which also enables `supabase start` local dev for the integration tests in Section 7).

## Part B — Auth-aware routing with go_router + Provider

**Problem (from [[BUG-2-3-4-auth-ux-session]]):** navigation was imperative `Navigator.push`, persisted sessions were ignored (fixed 2-second splash → always login), and there was no reactive listener on auth state.

**What was done:**
- Added `go_router` (`lib/src/core/router/app_router.dart`). `buildRouter(AuthRepository)` defines routes `/splash`, `/login`, `/signup`, `/shelf` (with nested `/shelf/add`, `/shelf/results`).
- A **redirect** enforces auth: unauthenticated users are sent to `/login`; an authenticated user sitting on an auth screen is sent to `/shelf`; the splash self-transitions once session state is known.
- A `GoRouterRefreshStream` bridges Supabase's `onAuthStateChange` stream into go_router's `refreshListenable`, so **login/logout re-evaluates the redirect automatically** — this is what makes logout return cleanly to login and makes a restored session land on the shelf without manual navigation.
- State/DI via **Provider** (`MultiProvider` in `app.dart`): `AuthRepository`, `BookshelfRepository`, `GoogleBooksService`, and `ThemeProvider`.

### PERF-7 subsumed
Theme changes now flow through `ChangeNotifierProvider<ThemeProvider>` + a `Consumer` around `MaterialApp.router`, replacing the old `AnimatedBuilder`-wraps-the-whole-app pattern. The rebuild is scoped to the `Consumer`, so the "whole-app rebuild on theme change" concern is resolved.

## Verification
- `flutter analyze` → clean; `flutter test` → all pass.
- `flutter build web` → compiles.
- Migration files in `supabase/migrations/` match the applied live-DB history.
- Supabase security & performance advisors re-checked after all migrations — see the final verification note in [[Remediation-Index]]. The only remaining advisories are expected/by-design: `add_book_to_shelf` executable by `authenticated` (that *is* the client RPC; revoked from `anon`), the leaked-password toggle (manual dashboard action, [[SEC-6-auth-hardening]]), and an `unused_index` INFO on the just-created FK index (clears on first use).
