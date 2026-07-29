# Remediation Index

Tracking implementation of the Phase 0–3 remediation plan from [[PROJECT_ANALYSIS]]. One note per point; each records the actions taken. SEC-1 (cookie leak) was handled separately in [[CHROME_PROFILE_LEAK_ASSESSMENT]] and excluded here by request.

## Phase 0 — Stop the bleeding
- [[SEC-2-google-api-key]] — ✅ key out of source (rotation manual)
- [[SEC-3-BUG-1-catalog-rls-and-add-book]] — ✅ catalog RLS + atomic add-book RPC
- [[SEC-6-auth-hardening]] — ✅ search_path pinned (2 dashboard toggles manual)

## Phase 1 — Correctness
- [[SEC-4-drop-password-column]] — ✅ `encrypted_password` dropped, hashing code removed
- [[BUG-2-3-4-auth-ux-session]] — ✅ login Scaffold, error messages, session-aware startup
- [[SEC-7-BUG-7-provisioning-trigger]] — ✅ profile trigger; client-side upserts removed
- [[BUG-5-6-deadcode-and-test]] — ✅ dead code deleted, real tests replace the stub

## Phase 2 — Performance
- [[PERF-1-2-5-6-client-perf]] — ✅ embedded join, local state, https+cached images, HTTP timeout
- [[PERF-3-4-rls-initplan-and-index]] — ✅ `(select auth.uid())` policies + FK index

## Phase 3 — Architecture
- [[ARCH-1-refactor-structure]] — ✅ `main.dart` split into layered `lib/src/`
- [[ARCH-2-appconfig]] — ✅ build-time `AppConfig` via `--dart-define`
- [[ARCH-3-migrations-and-routing]] — ✅ SQL migrations captured; go_router + Provider (subsumes PERF-7)

## Status — Phases 0–3 complete
All Phase 0–3 code and database remediations are implemented and verified (`flutter analyze` clean, all tests pass, `flutter build web` succeeds, Supabase advisors re-checked). The only outstanding items are **manual dashboard/console actions** the tooling can't perform: rotate the Google Books key (SEC-2), enable leaked-password protection + set a server-side password policy (SEC-6), and optionally rotate the Supabase PAT (SEC-5). Phase 4 (production polish) is future work.

## Legend
✅ complete · ⚠️ has a manual follow-up the user must do · ⏳ pending
