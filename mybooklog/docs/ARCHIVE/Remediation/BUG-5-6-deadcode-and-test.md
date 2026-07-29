# BUG-5 / BUG-6 — Dead code + broken test

**Phase:** 1 (Correctness) · **Status:** ✅ Complete
**Related:** [[PROJECT_ANALYSIS]] · [[Remediation-Index]] · full suite in [[ARCH-3-migrations-and-routing]] / Section 7

## BUG-6 — Dead code
- Deleted `lib/main_root_backup.dart` (a leftover Supabase "todos" demo that also carried a second hardcoded copy of the project URL/key). Git history retains it if ever needed.

## BUG-5 — Broken default test
`test/widget_test.dart` was the untouched Flutter counter template: it pumped `MyApp` (requires `Supabase.initialize` → throws) and asserted on a counter UI that never existed, so `flutter test` failed out of the box.
- **Replaced** with three tests that need no Supabase/network:
  1. **SEC-2 regression:** asserts `AppConfig.googleBooksApiKey` is empty (no secret baked into the binary).
  2. Supabase config sanity (URL contains `supabase.co`, publishable key non-empty).
  3. A widget test that renders a `Scaffold` under `AppTheme.lightTheme`.
- The comprehensive unit/widget/golden suite (Section 7 of [[PROJECT_ANALYSIS]]) is deferred to Phase 3, which extracts the pure helpers (ISBN parsing, normalization, password validation) into public, importable units.

## Verification
- `flutter test` → **3/3 pass** (was 0 passing / suite errored before).
- `flutter analyze` → clean.
