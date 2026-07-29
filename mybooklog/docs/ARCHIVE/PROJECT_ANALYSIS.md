# MyBookLog — Project Analysis & Production-Readiness Report

**Date:** 2026-07-16
**Scope analyzed:** All Dart source (`mybooklog/lib/`, 2,529 lines), theming system, Supabase project `asqdogadhpwqpeekvxny` (schema, RLS policies, indexes, security & performance advisors), git repository state and history.

---

## Table of Contents

1. [Executive Summary](#1-executive-summary)
2. [Security Findings](#2-security-findings)
3. [Functional Bugs & Gaps](#3-functional-bugs--gaps)
4. [Performance Findings](#4-performance-findings)
5. [Architecture & Code Quality](#5-architecture--code-quality)
6. [Step-by-Step Remediation Plan](#6-step-by-step-remediation-plan)
7. [Automated Testing Framework Plan](#7-automated-testing-framework-plan)

---

## 1. Executive Summary

MyBookLog is a functional MVP with a genuinely pleasant visual design — a coherent "oatmeal & sage" theme system, thoughtful micro-interactions (haptics, long-press lift animations), and a working end-to-end flow: sign up → log in → search Google Books → add to shelf → mark read → remove.

It is **not production-ready**. The blocking issues, in order of urgency:

| # | Issue | Severity |
|---|-------|----------|
| 1 | Chrome browser profile (cookies, account data) committed and pushed to public GitHub | 🔴 Critical |
| 2 | Google Books API key hardcoded in source, in public git history | 🔴 Critical |
| 3 | `books_catalog` table has RLS disabled — anyone with the anon key can read/modify/delete every row | 🔴 Critical |
| 4 | Unsalted SHA-256 password hashes stored in `public.users` (duplicate credential store) | 🔴 Critical |
| 5 | Adding a book that another user already added **always fails** (unique ISBN violation) | 🟠 High |
| 6 | Logging out crashes the login screen (no `Scaffold`/`Material` ancestor) | 🟠 High |
| 7 | Failed logins show no error message (error display is commented out) | 🟠 High |
| 8 | The only test in the repo is the default counter test — it fails | 🟠 High |
| 9 | Entire app lives in one 2,050-line `main.dart` with no models, services, or state management | 🟡 Medium |

The good news: the app's scope is small, the DB schema is fundamentally sound (proper FKs, composite PK on shelf items, mostly-correct RLS policies), and every issue below has a concrete, bounded fix. Section 6 sequences them into five phases; Phase 0 (secret rotation + history purge + RLS) should be done **immediately**, before anything else.

---

## 2. Security Findings

### 🔴 SEC-1: Chrome browser profile committed & pushed to public GitHub

> **⚠️ UPDATE (2026-07-16) — severity downgraded after direct inspection.** The committed databases were extracted from git and inspected table-by-table: **every sensitive table is empty.** This is the *throwaway* Chrome profile Flutter auto-creates for `flutter run -d chrome`, not a personal browser — no cookies, no saved passwords, no payment data, no signed-in Google account, and browsing history of exactly one URL (`localhost` dev server). **No accounts, credentials, or cookies were actually compromised**, and the credential-rotation / "sign out of Google everywhere" advice below is **not required**. The item remains valid only as repo hygiene (purge the junk files). Full evidence: [[CHROME_PROFILE_LEAK_ASSESSMENT]]. The original text is retained below for the record.

- **What:** 169 files under `mybooklog/.dart_tool/` are tracked in git, including a full Chrome device profile: `mybooklog/.dart_tool/chrome-device/Default/Cookies`, `Cookies-journal`, `Account Web Data`, `Affiliation Database`, GCM Store, Favicons, browsing-topics data, and extension state. The repo is pushed to `https://github.com/charlemagne86/MyBookLog.git`.
- **Why it matters:** The `Cookies` SQLite database can contain live session cookies for any site visited in that Chrome-for-Flutter-web profile (Google accounts included). Anyone who cloned the public repo may hold those sessions. `.gitignore` lists `.dart_tool/`, but the files were committed before the rule existed — gitignore does not untrack already-tracked files.
- **Fix:**
  1. Assume the sessions are compromised: sign out of Google (and any other site used in that profile) on all devices → this invalidates the leaked cookies. Change passwords for any account whose credentials may have been autofilled/synced in that profile.
  2. Untrack the junk: `git rm -r --cached mybooklog/.dart_tool mybooklog/build mybooklog/android/local.properties && git commit`.
  3. Purge history (the files remain fetchable from old commits otherwise): use [`git filter-repo`](https://github.com/newren/git-filter-repo):
     ```bash
     git filter-repo --path mybooklog/.dart_tool --path mybooklog/build \
                     --path mybooklog/android/local.properties --invert-paths
     git push origin --force --all && git push origin --force --tags
     ```
  4. Note: force-pushing does not scrub GitHub's caches of old commit SHAs. Contact GitHub Support to remove cached views, or (simplest, given the repo's age) delete and recreate the repository from the cleaned clone.

### 🔴 SEC-2: Google Books API key hardcoded in source & public git history

> **✅ UPDATE (2026-07-16) — code remediated; key rotation still required.** The hardcoded key and Supabase literals were removed from `main.dart` and moved into a new `AppConfig` (`lib/src/core/config/app_config.dart`) that reads from `--dart-define`; `env.example.json` added, `env.json` gitignored. **You must still rotate the key in Google Cloud Console** (create restricted replacement, delete the leaked one) — code changes don't undo a public secret. Details: [[SEC-2-google-api-key]].

- **What:** `mybooklog/lib/main.dart:14` — `const String _googleBooksApiKey = 'AIzaSy…';` — committed and pushed.
- **Why it matters:** Anyone can use the key. Even "free" APIs keyed to your Google Cloud project can rack up quota abuse, get your project flagged, or be cross-used against other APIs if the key is unrestricted.
- **Fix:**
  1. In Google Cloud console: create a **new** key restricted to the Books API (and app restrictions where possible), then delete the leaked key. Rotation is mandatory — history purging alone is insufficient once a secret is public.
  2. Move the key out of source: pass at build time via `--dart-define=GOOGLE_BOOKS_API_KEY=...` and read with `String.fromEnvironment`, wrapped in an `AppConfig` class (see ARCH-2).

### 🔴 SEC-3: `books_catalog` has RLS disabled

> **✅ UPDATE (2026-07-16) — resolved (DB + client).** RLS enabled on `books_catalog` with a SELECT-only policy for authenticated users; all writes now go through a new `SECURITY DEFINER` RPC `add_book_to_shelf` (upsert-by-ISBN + shelf link, EXECUTE revoked from anon). The client's `_addSelectedBook` calls the RPC instead of inserting directly, which also fixes **BUG-1**. The three `books_catalog` RLS advisories are cleared. Details: [[SEC-3-BUG-1-catalog-rls-and-add-book]].

- **What:** Supabase advisor (critical): RLS is **off** on `public.books_catalog`, even though a SELECT policy (`bookshelf_items_catalog_select`) was written for it. The other three tables (`users`, `bookshelf`, `bookshelf_items`) have RLS enabled with correct owner-scoped policies.
- **Why it matters:** With RLS off, the table is fully exposed through PostgREST to the `anon` and `authenticated` roles — anyone holding the (public, shipped-in-the-app) anon key can read, modify, or delete **all 32 catalog rows** without logging in.
- **Fix — coupled with BUG-1, do not enable RLS naively:**
  - The app currently does a client-side dedup check on `books_catalog` by ISBN and then inserts catalog rows directly. Once RLS is enabled, the existing SELECT policy only shows a user *their own shelf's* books, so the dedup check goes blind, and there is **no INSERT policy at all**, so adding books breaks entirely.
  - Correct design: move catalog writes server-side into a `SECURITY DEFINER` RPC that atomically upserts the catalog row and shelf row (full SQL in [Phase 0, step 5](#phase-0--stop-the-bleeding-immediately)). Then enable RLS with catalog SELECT for authenticated users and no direct INSERT/UPDATE/DELETE.

### 🔴 SEC-4: Unsalted SHA-256 password hash stored in `public.users`

> **✅ UPDATE (2026-07-16) — resolved.** `encrypted_password` column dropped; `_hashPassword` and the `crypto` dependency removed; sign-up no longer writes any password material (Supabase Auth is the sole credential store). Details: [[SEC-4-drop-password-column]].

- **What:** Sign-up (`main.dart:343-347`, `426-437`) computes `sha256(password)` client-side and stores it in `public.users.encrypted_password` — alongside Supabase Auth, which already stores the real (bcrypt-hashed) credential.
- **Why it matters:**
  - Unsalted SHA-256 is trivially reversed with rainbow tables/GPU brute force for typical passwords.
  - It is a second credential store that serves **no purpose** — nothing in the app reads it.
  - Combined with any RLS slip on `users`, this leaks crackable password material for every user.
- **Fix:** Drop the column (`ALTER TABLE public.users DROP COLUMN encrypted_password;`), delete `_hashPassword` and the `crypto` dependency. Supabase Auth is the single credential authority.

### 🟠 SEC-5: Supabase personal access token in plaintext `.mcp.json`

- **What:** `.mcp.json` at the repo root contains a `sbp_…` personal access token. **Verified never committed** (it's gitignored with a clear comment — good), but it grants management-level access to your Supabase account and sits in plaintext on disk.
- **Fix:** Rotate the token at supabase.com/dashboard/account/tokens as a precaution, keep the gitignore rule, and consider an env var (`SUPABASE_ACCESS_TOKEN` in your shell profile) instead of the file.

### 🟡 SEC-6: Auth hardening (Supabase advisors)

> **✅ UPDATE (2026-07-16) — partially resolved.** `set_updated_at` search_path pinned to `''` (advisory cleared). The two remaining items — **leaked-password protection** and **server-side password policy** — are Supabase dashboard toggles with no API/MCP equivalent and remain **manual actions for you**. Details: [[SEC-6-auth-hardening]].

- **Leaked-password protection disabled** — enable the HaveIBeenPwned check: Dashboard → Authentication → Providers → Email → "Prevent use of leaked passwords".
- **Server-side password policy** — the 8-char/complexity rule exists only in Flutter (`main.dart:364-378`); anyone calling the auth API directly bypasses it. Set minimum length/complexity in Dashboard → Authentication → Policies.
- **`public.set_updated_at` has a mutable `search_path`** (advisor WARN) — a definer-context function without a pinned path is a privilege-escalation vector:
  ```sql
  ALTER FUNCTION public.set_updated_at() SET search_path = '';
  ```

### 🟡 SEC-7: Sign-up flow breaks under email confirmation & can orphan auth users

> **✅ UPDATE (2026-07-16) — resolved.** Added `handle_new_user_profile()` + `on_auth_user_created_profile` trigger; sign-up passes names via `signUp(data:)` and does no client-side profile write, so provisioning works without a session and can't orphan the auth user. Details: [[SEC-7-BUG-7-provisioning-trigger]].

- **What:** `_submit` (`main.dart:381-467`) calls `auth.signUp` then upserts the `public.users` profile. If email confirmation is enabled, `signUp` returns a user but **no session** — the upsert then runs unauthenticated, fails the `users_insert_own` RLS policy, and the user sees an error even though the auth account was created. Any profile-insert failure similarly leaves an orphaned auth user with no profile row.
- **Fix:** Create the profile server-side with a trigger on `auth.users` (the same trigger can create the `bookshelf` row — see BUG-7), and pass `first_name`/`last_name` via `signUp`'s `data:` (user metadata) so the trigger can copy them. The client then does zero table writes at sign-up.

---

## 3. Functional Bugs & Gaps

### Bugs (all verified in code)

**🟠 BUG-1: Adding a book another user already added always fails.**
`_addSelectedBook` (`main.dart:1564-1705`) checks whether the *current user* already shelves the ISBN, then unconditionally **inserts a new `books_catalog` row** (`:1659-1669`). `isbn` has a unique index (`books_catalog_isbn_unique`), so the second user to add any given book hits a unique violation → "Failed to add book". The fix (reuse the existing catalog id, ideally via the RPC in Phase 0) also resolves the RLS coupling in SEC-3.
> ✅ **FIXED (2026-07-16):** client now calls the `add_book_to_shelf` RPC (upsert-by-ISBN). See [[SEC-3-BUG-1-catalog-rls-and-add-book]].

**🟠 BUG-2: Logout crashes the login screen.**
`_onLogout` (`main.dart:906-922`) does `pushReplacement(LoginScreen())`, but `LoginScreen.build` (`:213-328`) returns a bare `Padding` — no `Scaffold`. Its `TextField`s then throw *"No Material widget found"*. It only renders at startup because `SplashScreen` wraps it in a `Scaffold` (`:98-130`). Fix: give `LoginScreen` its own `Scaffold` and simplify the splash to not embed it.
> ✅ **FIXED (2026-07-16):** `LoginScreen` now has its own `Scaffold`. See [[BUG-2-3-4-auth-ux-session]].

**🟠 BUG-3: Failed logins are silent.**
The `catch` in `_login` (`main.dart:200-208`) sets nothing (`_errorText` assignment commented out), and the error display widget is commented out (`:255-268`). Wrong password → spinner stops, nothing happens. Also, the generic `$e` messages elsewhere leak raw exception internals to users — map `AuthException` to friendly text instead.
> ✅ **FIXED (2026-07-16):** error text restored + `_friendlyAuthMessage` mapping added. See [[BUG-2-3-4-auth-ux-session]].

**🟠 BUG-4: Persisted sessions are ignored.**
`supabase_flutter` auto-restores the session, but the app unconditionally shows splash → login after a fixed 2-second timer (`:87-92`). A logged-in user must re-enter credentials every launch (and re-auth works only because Supabase still had a session). Fix: after init, route on `Supabase.instance.client.auth.currentSession` and subscribe to `onAuthStateChange` for signed-in/signed-out transitions.
> ✅ **FIXED (2026-07-16):** splash routes on `currentSession`; reactive `onAuthStateChange`/go_router arrives in Phase 3. See [[BUG-2-3-4-auth-ux-session]].

**🟠 BUG-5: The only test is broken.**
`test/widget_test.dart` is the untouched Flutter counter template: it pumps `MyApp` (which requires `Supabase.initialize` → throws) and asserts on a counter UI that doesn't exist. `flutter test` fails out of the box. Replaced under the testing plan (Section 7).
> ✅ **FIXED (2026-07-16):** replaced with 3 passing tests (incl. SEC-2 regression). See [[BUG-5-6-deadcode-and-test]].

**🟡 BUG-6: Dead code with duplicated credentials.**
`lib/main_root_backup.dart` is a leftover Supabase "todos" demo containing a second hardcoded copy of the project URL/key. Delete it (git history preserves it if ever needed).
> ✅ **FIXED (2026-07-16):** file deleted. See [[BUG-5-6-deadcode-and-test]].

**🟡 BUG-7: `bookshelf` row creation is a fragile client-side upsert at login.**
`main.dart:184-187` upserts the user's `bookshelf` row on every login. `bookshelf_items.bookshelf_user_id` FK-references `bookshelf.user_id`, so shelf writes depend on this having run at least once — an implicit ordering dependency, and a wasted round-trip per login. Fix: a DB trigger on `auth.users` creates both the `public.users` profile and the `bookshelf` row (see Phase 1 SQL).
> ✅ **FIXED (2026-07-16):** client login upsert removed; both rows provisioned by `auth.users` triggers. See [[SEC-7-BUG-7-provisioning-trigger]].

**🟡 BUG-8: Dark theme is fully built but unreachable.**
`AppTheme.darkTheme` and `ThemeProvider` (toggle + notifier) exist and are wired into `MaterialApp`, but no UI ever calls `toggleTheme()`, and the choice isn't persisted. Add a toggle (app bar action or settings) + `shared_preferences` persistence.

**🟢 BUG-9: "Forgot password" is a stub** (`main.dart:270-286`) — shows a "not implemented" snackbar. Supabase's `resetPasswordForEmail` + deep-link handling makes this a small, well-trodden feature.

### Functional gaps / enhancement candidates (brief, for future roadmap)

- Password reset & email-verification UX (resend link, "check your inbox" screen)
- Book detail view (tap a shelf tile → description, page count, published date)
- Reading states beyond read/unread: currently-reading, ratings, notes, started/finished dates
- Sort & filter the shelf (by title, author, date added, read status)
- Barcode/ISBN scanning for instant add (`mobile_scanner`)
- Pull-to-refresh on the shelf; pagination for large shelves
- Offline cache of the shelf (the core "am I re-reading this?" check should work in a bookstore basement with no signal — arguably the app's #1 use case)
- Profile screen (name, email, delete account — account deletion is required by app stores)
- Accessibility pass: semantic labels on icon buttons, larger touch targets, contrast check in dark mode
- Localization scaffolding (`flutter_localizations`) if ever needed

---

## 4. Performance Findings

**🟡 PERF-1: Shelf load makes two sequential round-trips.**
`_fetchBooks` (`main.dart:660-731`) fetches `bookshelf_items`, collects ids, then fetches `books_catalog` and merges client-side. The FK already exists, so PostgREST can do it in one embedded query:
```dart
final rows = await supabase
    .from('bookshelf_items')
    .select('*, books_catalog(id, title, author, thumbnail_uri)')
    .eq('bookshelf_user_id', user.id);
```
> ✅ **FIXED (2026-07-16):** `_fetchBooks` now uses the single embedded query. See [[PERF-1-2-5-6-client-perf]].

**🟡 PERF-2: Full shelf refetch after every mutation.**
Toggling read status or removing a book re-downloads the entire shelf (`_toggleBookReadStatus`/`_removeBookFromShelf` both end in `await _fetchBooks()`). Update the local `_books` list on success (or optimistically) instead; keep refetch for pull-to-refresh.
> ✅ **FIXED (2026-07-16):** both mutations patch local `_books` state; refetch removed. See [[PERF-1-2-5-6-client-perf]].

**🟡 PERF-3: RLS policies re-evaluate `auth.uid()` per row.**
Advisor WARN on all four `bookshelf_items` policies — they use bare `auth.uid()` while the `users`/`bookshelf` policies already use the correct `(select auth.uid())` form. At scale this becomes a per-row function call. Fix by recreating the four policies with the subselect form (SQL in Phase 2).
> ✅ **FIXED (2026-07-16):** four policies recreated with `(select auth.uid())`; advisories cleared. See [[PERF-3-4-rls-initplan-and-index]].

**🟡 PERF-4: Missing index on `bookshelf_items.book_id`.**
Advisor INFO — the FK to `books_catalog` has no covering index (the composite PK covers `bookshelf_user_id` lookups only). Affects deletes on `books_catalog` and any book→shelves lookups:
```sql
CREATE INDEX bookshelf_items_book_id_idx ON public.bookshelf_items (book_id);
```
> ✅ **FIXED (2026-07-16):** index created. See [[PERF-3-4-rls-initplan-and-index]].

**🟡 PERF-5: Uncached, cleartext book covers.**
`Image.network` is used with no cache, no `loadingBuilder`, no `errorBuilder` (`main.dart:1789-1794`, `:1990-1994`). Covers re-download on every rebuild/scroll. Worse: Google Books returns `http://` thumbnail URLs, which **Android and iOS block in release builds** (cleartext policy) — covers will silently fail to load in production. Fix: rewrite `http://` → `https://` at normalization time (`_normalizeGoogleBooksItems`, `main.dart:1297-1327`) and switch to `cached_network_image` with placeholder + error widgets.
> ✅ **FIXED (2026-07-16):** `cached_network_image` + `_toHttps()` at ingest and display. See [[PERF-1-2-5-6-client-perf]].

**🟢 PERF-6: No timeout or debounce on Google Books calls.**
`http.get` calls (`:1146`, `:1403`, `:1495`) have no `.timeout(...)` — a stalled connection spins forever. Add `~10s` timeouts; consider debouncing the infinite-scroll trigger.
> ✅ **FIXED (2026-07-16):** 10s `.timeout()` on all three calls (debounce deferred as an enhancement). See [[PERF-1-2-5-6-client-perf]].

**🟢 PERF-7: Whole-app rebuild on theme change.**
`AnimatedBuilder` around `MaterialApp` (`main.dart:53-66`) rebuilds the full tree on toggle. Fine at this scale; resolved for free by moving to a state-management package (ARCH-1).

> ✅ **FIXED (2026-07-16):** theme now flows through `ChangeNotifierProvider<ThemeProvider>` + a `Consumer` scoped around `MaterialApp.router`, replacing the whole-app `AnimatedBuilder`. Covered in [[ARCH-3-migrations-and-routing]].

---

## 5. Architecture & Code Quality

> **✅ UPDATE (2026-07-16) — Phase 3 implemented.** The monolith was split into the layered `lib/src/` structure below with typed models, injected repositories/services, `go_router`, and Provider; `AppConfig` centralizes build-time config; the schema is captured as versioned SQL migrations. Per-item notes are inline below. Details: [[ARCH-1-refactor-structure]], [[ARCH-2-appconfig]], [[ARCH-3-migrations-and-routing]].

**🟡 ARCH-1: 2,050-line `main.dart` monolith.** Seven screens, the Google Books client, parsing helpers, and widgets in one file. No models (`Map<String, dynamic>` everywhere with stringly-typed keys), no service/repository layer (every screen calls `Supabase.instance.client` directly — untestable), raw `setState` + a hand-rolled `ChangeNotifier`. Target structure:

```
lib/src/
  core/
    config/app_config.dart        # --dart-define wrapper (SEC-2)
    theme/                        # existing app_colors/app_theme/theme_provider move here
    widgets/                      # shared widgets (book tile, async image)
  data/
    models/book.dart, shelf_item.dart, user_profile.dart
    services/google_books_service.dart
    repositories/auth_repository.dart, bookshelf_repository.dart
  features/
    auth/    (splash, login, signup, forgot-password screens)
    bookshelf/ (shelf screen + tile widgets)
    book_search/ (add-book + results screens)
```
Repositories take a `SupabaseClient`/`http.Client` in the constructor (dependency injection) — this is the prerequisite for the testing plan in Section 7. `go_router` for auth-aware routing (redirect based on session), Riverpod (or Provider, if preferred) for state.

> ✅ **FIXED (2026-07-16):** `main.dart` is now 15 lines; the app lives in `lib/src/{core,data,features}` with typed `BookSearchResult`/`ShelfBook` models, `AuthRepository`/`BookshelfRepository`/`GoogleBooksService` injected via Provider, and go_router. Structure and verification: [[ARCH-1-refactor-structure]].

**🟡 ARCH-2: Configuration & secrets.** Supabase URL + publishable key are fine to ship in a client, but they're hardcoded in two files, and the Google key must not be in source at all. One `AppConfig` reading `String.fromEnvironment`, values supplied via `--dart-define` / `--dart-define-from-file=env.json` (gitignored).

> ✅ **FIXED (2026-07-16):** `lib/src/core/config/app_config.dart` reads all config from `String.fromEnvironment`. The Google key has **no default** (search disables gracefully if absent), Supabase URL/key default to the project values; `env.example.json` committed, `env.json` gitignored. A test asserts no key is baked into source. Details: [[ARCH-2-appconfig]].

**🟡 ARCH-3: No database migrations.** The Supabase migration table is empty — the entire schema was built via the dashboard. There is no reproducible record of tables, policies, triggers, or the RPC. Adopt the Supabase CLI: `supabase init`, `supabase db pull` to capture the current schema into `supabase/migrations/`, commit it, and make all future schema changes via migration files (enables local dev with `supabase start` and the integration tests in Section 7).

> ✅ **FIXED (2026-07-16):** `supabase/migrations/` now holds a `00000000000000_baseline_schema.sql` (pre-remediation state) plus five timestamped migrations for every DB change in Phases 0–2. The CLI wasn't available here, so each was applied via MCP `apply_migration` and written to a matching file; repo files and live migration history align. Details: [[ARCH-3-migrations-and-routing]].

**🟡 ARCH-4: Repo hygiene.** 444 tracked files; ~170 are `.dart_tool`/`build` junk plus `android/local.properties` (machine-local SDK paths) — removal covered in SEC-1. Nine local and nine remote branches with divergent naming (`User-Authentication-Attempt-#1`, `Themeing`, …) — prune merged branches. `analysis_options.yaml` uses default `flutter_lints`; once code is split, tighten (e.g. `very_good_analysis` or hand-picked strict rules) and add `dart format` to CI.

> ✅ **PARTIALLY FIXED (2026-07-16):** `analysis_options.yaml` was tightened — `strict-casts`/`strict-raw-types`, `use_build_context_synchronously` and `unawaited_futures` promoted to **errors**, plus `prefer_single_quotes`, `require_trailing_commas`, `avoid_print`, `directives_ordering`. The whole tree is `flutter analyze`-clean and `dart format`-clean under these rules. **Still manual (git history):** purging the `.dart_tool`/`build`/`local.properties` files from history and pruning stale branches — these are git operations tied to SEC-1 and left for you.

**🟢 ARCH-5: Data-model duplication.** `public.users.username` stores the email, duplicating `auth.users.email` (drift risk; also the UI label "Username (email)" is confusing — it's just email). The `bookshelf` table is currently a pure 1:1 satellite of `users`; it's justifiable only if multiple shelves per user are planned — otherwise `bookshelf_items.bookshelf_user_id` could FK `users` directly. Not urgent; decide before the schema is frozen in migrations.

> ℹ️ **DECISION DEFERRED (2026-07-16) — intentionally not changed.** This is a schema-design judgement call, not a defect. The baseline schema (including the `users.username` = email and the 1:1 `bookshelf` satellite) is now captured verbatim in `00000000000000_baseline_schema.sql`, so the current shape is recorded and reproducible. Collapsing `bookshelf` into `users` or dropping `username` is a data migration to weigh against future multi-shelf plans; left as a conscious decision for you rather than forced during remediation.

---

## 6. Step-by-Step Remediation Plan

### Phase 0 — Stop the bleeding (immediately)

1. **Invalidate leaked Chrome sessions** (SEC-1): sign out of Google/other accounts used in that profile everywhere; change potentially-synced passwords.
2. **Rotate the Google Books API key** (SEC-2): create restricted replacement, delete old key, temporarily keep new key out of git (env/`--dart-define`) even before the full config refactor.
3. **Rotate the Supabase personal access token** (SEC-5).
4. **Purge git history** (SEC-1): untrack `.dart_tool`, `build/`, `local.properties`; run `git filter-repo`; force-push; delete/recreate the GitHub repo or ask GitHub Support to drop cached commits. Verify with a fresh clone: `git ls-files | grep -c dart_tool` → 0.
5. **Fix catalog writes + enable RLS together** (SEC-3 + BUG-1):
   ```sql
   -- One atomic server-side entry point for adding books
   CREATE OR REPLACE FUNCTION public.add_book_to_shelf(
     p_isbn text, p_title text, p_author text, p_thumbnail_uri text
   ) RETURNS uuid
   LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
   AS $$
   DECLARE v_book_id uuid;
   BEGIN
     IF auth.uid() IS NULL THEN RAISE EXCEPTION 'not authenticated'; END IF;
     INSERT INTO public.books_catalog (isbn, title, author, thumbnail_uri)
     VALUES (p_isbn, p_title, p_author, p_thumbnail_uri)
     ON CONFLICT (isbn) DO UPDATE SET updated_at = now()   -- reuse existing row
     RETURNING id INTO v_book_id;
     INSERT INTO public.bookshelf_items (bookshelf_user_id, book_id)
     VALUES (auth.uid(), v_book_id)
     ON CONFLICT DO NOTHING;                               -- duplicate add = no-op
     RETURN v_book_id;
   END $$;

   ALTER TABLE public.books_catalog ENABLE ROW LEVEL SECURITY;
   DROP POLICY IF EXISTS bookshelf_items_catalog_select ON public.books_catalog;
   CREATE POLICY books_catalog_select_authenticated ON public.books_catalog
     FOR SELECT TO authenticated USING (true);   -- catalog metadata is not sensitive
   -- no INSERT/UPDATE/DELETE policies: writes only via the RPC
   ```
   In `_addSelectedBook`, replace the dedup-check + two inserts with one call:
   `await supabase.rpc('add_book_to_shelf', params: {...})`, and detect "already on shelf" beforehand from the already-loaded local shelf (or return a flag from the RPC).
6. **Auth hardening** (SEC-6): enable leaked-password protection; set server-side password policy; pin `set_updated_at` search_path.

### Phase 1 — Correctness

1. Drop `public.users.encrypted_password`; remove `_hashPassword` + `crypto` dependency (SEC-4).
2. Give `LoginScreen` its own `Scaffold`; simplify `SplashScreen` (BUG-2).
3. Restore & humanize login error messages; map `AuthException` codes to friendly text app-wide (BUG-3).
4. Session-aware startup: route on `currentSession`, subscribe to `onAuthStateChange` (BUG-4).
5. Server-side provisioning trigger (SEC-7 + BUG-7):
   ```sql
   CREATE OR REPLACE FUNCTION public.handle_new_user()
   RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path = '' AS $$
   BEGIN
     INSERT INTO public.users (id, username, first_name, last_name)
     VALUES (NEW.id, NEW.email,
             NEW.raw_user_meta_data->>'first_name',
             NEW.raw_user_meta_data->>'last_name');
     INSERT INTO public.bookshelf (user_id) VALUES (NEW.id);
     RETURN NEW;
   END $$;
   CREATE TRIGGER on_auth_user_created AFTER INSERT ON auth.users
     FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
   ```
   Then remove the client-side `users` upsert (pass names via `signUp(data: {...})`) and the per-login `bookshelf` upsert.
6. Delete `lib/main_root_backup.dart` (BUG-6).
7. Replace the broken widget test with a real smoke test (kicks off Section 7).

### Phase 2 — Performance

1. Embedded join for `_fetchBooks` (PERF-1).
2. Local/optimistic state updates for toggle-read and remove (PERF-2).
3. Recreate the four `bookshelf_items` policies with `(select auth.uid())` (PERF-3).
4. `CREATE INDEX bookshelf_items_book_id_idx ON public.bookshelf_items (book_id);` (PERF-4).
5. `http://`→`https://` thumbnail rewrite in `_normalizeGoogleBooksItems` + `cached_network_image` with placeholder/error widgets (PERF-5).
6. `.timeout(const Duration(seconds: 10))` on all Google Books calls (PERF-6).
7. Re-run both Supabase advisors — target: zero ERROR/WARN findings.

### Phase 3 — Architecture

1. Split `main.dart` into the `lib/src/` structure (ARCH-1) — mechanical move first (screens into files), then introduce models, then repositories with injected clients.
2. `AppConfig` + `--dart-define` for all config; delete hardcoded literals (ARCH-2).
3. `go_router` with a session-based redirect; Riverpod/Provider for auth + shelf state (subsumes PERF-7).
4. `supabase init` + `db pull`; commit `supabase/migrations/`; all further schema changes as migrations (ARCH-3).
5. Prune merged branches; tighten lints (ARCH-4).

### Phase 4 — Production polish

1. Theme toggle UI + `shared_preferences` persistence (BUG-8).
2. Forgot-password flow with `resetPasswordForEmail` + deep link (BUG-9).
3. Error reporting (Sentry `sentry_flutter` or Firebase Crashlytics).
4. CI (defined in Section 7).
5. Store readiness: app icons/splash per platform, Android signing config, iOS bundle setup, privacy policy + account-deletion flow (store requirement), version bump discipline.

---

## 7. Automated Testing Framework Plan

### Prerequisite

Meaningful widget/unit tests require the Phase 3 refactor (repositories injected into screens). Until then, only pure-function unit tests and golden tests are practical — start with those; they need zero refactoring.

### Layout

```
test/
  unit/            # pure logic, no Flutter binding
  widget/          # per-screen tests with mocked repositories
  goldens/         # light/dark golden images of key screens
integration_test/  # end-to-end flows on device/emulator
```

### Layer 1 — Unit tests (start immediately)

Extract these already-pure helpers out of `main.dart` into `lib/src/` and test exhaustively:
- `_extractPreferredIsbnFromIndustryIdentifiers` (`main.dart:1271-1295`) — ISBN_13 preferred, ISBN_10 fallback, malformed/missing entries
- `_normalizeGoogleBooksItems` (`:1297-1327`) — missing volumeInfo, missing thumbnails, http→https rewrite once added
- `_bookIdentityKey` / `_bookVolumeKey` dedup keys (`:1451-1477`)
- `_validatePassword` (`:364-378`) — boundary cases (7/8 chars, each missing character class)
- `_isBookReadValue` (`:734-738`) — bool/int/string inputs
- `GoogleBooksService` (post-refactor) against a mocked `http.Client`, including timeout & non-200 paths

### Layer 2 — Widget tests (after repositories exist)

- Mock **repository interfaces** with `mocktail` — never mock `SupabaseClient` itself (huge API surface, brittle).
- Per screen: login (error shown on failure, spinner while pending, navigation on success), signup (validation messages), shelf (empty state, grid renders N items, search filter <3 chars inert, long-press menu actions call repo), search results (selection, infinite-scroll trigger, duplicate-add message).
- Wrap under test in `MaterialApp(theme: AppTheme.lightTheme)` via a shared `pumpApp` helper.

### Layer 3 — Golden tests

- Goldens of shelf tile (`_BookOnShelf` read/unread/menu-target states), login, and search-result card in **both** `AppTheme.lightTheme` and `darkTheme` — this is what actually guards the theming system, including the currently-unreachable dark theme. Use `alchemist` (CI-stable) or `golden_toolkit`.

### Layer 4 — Integration / E2E

- `integration_test` (SDK) driving the real app against a **local Supabase stack** (`supabase start`, from the Phase-3 migrations) or a dedicated throwaway test project — never production.
- Core journey: sign up → log in → search (Google Books stubbed with a fake `http.Client` or a recorded fixture to keep tests hermetic) → add book → duplicate-add rejected → mark read → badge appears → remove → logout → session-restore on relaunch.
- Optional: `patrol` if native permission dialogs/deep links (password reset) need driving.

### CI — GitHub Actions

`.github/workflows/ci.yml` on push/PR:
1. `flutter pub get`
2. `dart format --set-exit-if-changed .`
3. `flutter analyze` (zero tolerance)
4. `flutter test --coverage` (unit + widget + goldens); upload coverage, gate at a modest threshold (e.g. 60%) and ratchet up
5. Integration tests on a nightly schedule or `e2e` label (emulator jobs are slow/flaky on PRs)

### First 5 tests to write (this week, no refactor needed)

1. `_extractPreferredIsbnFromIndustryIdentifiers`: prefers ISBN_13 over ISBN_10 when both present
2. Same helper: returns null for empty/garbage identifier lists
3. `_validatePassword`: rejects 7-char and no-special-char passwords, accepts `Passw0rd!`
4. `_normalizeGoogleBooksItems`: skips items without `volumeInfo`, defaults title/authors
5. Replace `widget_test.dart` with a golden/smoke test of `_BookOnShelf` (read vs unread) — deletes the failing counter test

---

*Report generated by Claude Code on 2026-07-16. DB findings sourced from live Supabase advisors and `pg_policies`/`pg_indexes` inspection; all code findings reference `mybooklog/lib/main.dart` line numbers at commit `8ba1034`.*
