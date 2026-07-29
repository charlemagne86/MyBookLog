# Phases 0–3 Remediation — Completion Summary

**Date:** 2026-07-17 · **Status:** ✅ Complete & verified
**Related:** [[PROJECT_ANALYSIS]] · [[Remediation-Index]]

This note records the completion of the Phase 0–3 remediation plan from [[PROJECT_ANALYSIS]]. SEC-1 (the Chrome cookie/profile leak) was validated separately as a false positive and excluded by request — see [[CHROME_PROFILE_LEAK_ASSESSMENT]].

## Outcome

All Phase 0–3 code and database remediations are implemented and verified. The only outstanding items are **manual dashboard/console actions the tooling cannot perform** (listed at the bottom).

## Verification (final pass)

| Check | Result |
|---|---|
| `flutter analyze` | **No issues found** (under tightened lints) |
| `flutter test` | **10/10 passed** |
| `dart format --set-exit-if-changed` | Clean (0 changed) |
| `flutter build web` | **✓ Built build/web** |
| Supabase security advisors | Only expected/by-design items remain (below) |
| Supabase performance advisors | Only `unused_index` INFO on the fresh FK index (clears on first use) |

## Work completed this session (Phase 3 / ARCH)

- Fixed the last analyzer lint (`curly_braces` in `book_search_result.dart`).
- Confirmed the full refactor compiles, tests pass, and the web build succeeds.

### New vault docs written (`Projects/Remediation/`)
- [[ARCH-1-refactor-structure]] — 2,050-line `main.dart` → 15-line entry + layered `lib/src/{core,data,features}` with typed models, injected repositories/services.
- [[ARCH-2-appconfig]] — build-time `AppConfig` via `--dart-define`; API key never baked into source (regression-tested).
- [[ARCH-3-migrations-and-routing]] — schema captured as versioned SQL migrations; go_router + Provider auth-aware routing (subsumes PERF-7).

### PROJECT_ANALYSIS.md callouts added
✅ UPDATE callouts on PERF-7 and ARCH-1 through ARCH-5.
- **ARCH-4** — partial: lints tightened; git-history purge + branch pruning left manual.
- **ARCH-5** — deliberately deferred as a schema-design decision (baseline captured in migrations).

### Remediation-Index.md
Every Phase 0–3 item marked ✅, with a status block spelling out what remains manual.

## Issue caught in the final advisor pass (and fixed)

The SEC-7 trigger function `handle_new_user_profile()` had kept its default PUBLIC `EXECUTE` grant, so it was callable as an RPC by `anon`/`authenticated`. Added migration `20260717000000_revoke_execute_on_trigger_functions` to revoke `EXECUTE` on it (and on `set_updated_at()`), matching the baseline `handle_new_user_bookshelf()` (service_role only). Revoking does not affect trigger firing. Both advisories are now **cleared**. Recorded in [[SEC-7-BUG-7-provisioning-trigger]].

## Full remediation status by phase

- **Phase 0 — Stop the bleeding:** [[SEC-2-google-api-key]], [[SEC-3-BUG-1-catalog-rls-and-add-book]], [[SEC-6-auth-hardening]] ✅
- **Phase 1 — Correctness:** [[SEC-4-drop-password-column]], [[BUG-2-3-4-auth-ux-session]], [[SEC-7-BUG-7-provisioning-trigger]], [[BUG-5-6-deadcode-and-test]] ✅
- **Phase 2 — Performance:** [[PERF-1-2-5-6-client-perf]], [[PERF-3-4-rls-initplan-and-index]] ✅
- **Phase 3 — Architecture:** [[ARCH-1-refactor-structure]], [[ARCH-2-appconfig]], [[ARCH-3-migrations-and-routing]] ✅

## Remaining manual actions (cannot be done by tooling)

- **SEC-2** — rotate the leaked Google Books key in Google Cloud Console.
- **SEC-6** — enable leaked-password protection + set a server-side password policy (Supabase dashboard toggles; still shows as the one expected security advisory).
- **SEC-5** — optionally rotate the Supabase personal access token.
- **SEC-1 / ARCH-4** — purge `.dart_tool`/`build`/`local.properties` from git history and prune stale branches (git operations; SEC-1 excluded by earlier validation).

## Expected remaining advisories (by design — no action)

- `add_book_to_shelf` executable by `authenticated` — that *is* the client RPC (revoked from `anon`).
- Leaked-password protection disabled — the manual SEC-6 toggle above.
- `unused_index` INFO on `bookshelf_items_book_id_idx` — clears once the index serves its first query.

Phase 4 (production polish — theme toggle UI, forgot-password, error reporting, CI, store-readiness) is future work.
