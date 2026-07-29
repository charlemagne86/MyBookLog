# ARCH-2 — Centralized build-time configuration (`AppConfig`)

**Phase:** 3 (Architecture) · **Status:** ✅ Complete (code)
**Related:** [[PROJECT_ANALYSIS]] · [[Remediation-Index]] · [[SEC-2-google-api-key]] · [[ARCH-1-refactor-structure]]

## Problem
Configuration was hardcoded and scattered: the Google Books API key was a literal in `main.dart` (see [[SEC-2-google-api-key]]), and the Supabase URL + publishable key were duplicated as string literals across files. There was no single place to change environment values and no way to keep a secret out of source.

## What was done
Added `lib/src/core/config/app_config.dart`, a single class that reads all configuration from compile-time environment values via `String.fromEnvironment`, supplied at build time with `--dart-define` (or `--dart-define-from-file=env.json`).

- **`googleBooksApiKey`** — read from `GOOGLE_BOOKS_API_KEY` with **no default**. If the build doesn't provide it, the value is empty and book search is disabled gracefully rather than shipping a baked-in key.
- **`hasGoogleBooksApiKey`** getter — the UI (`AddBookPage`) checks this and shows a clear "book search is unavailable — no key configured for this build" message instead of failing a network call.
- **`supabaseUrl` / `supabasePublishableKey`** — read from environment with the real project values as defaults. These are safe to ship in a client (the publishable/anon key is designed to be public and is gated by RLS), so defaulting keeps local runs friction-free while still allowing per-environment overrides.

Supporting files:
- `env.example.json` committed as a template.
- `env.json` added to `.gitignore` so a real key file is never tracked.
- `main.dart` calls `Supabase.initialize(url: AppConfig.supabaseUrl, publishableKey: AppConfig.supabasePublishableKey)`.

## Regression guard
`test/widget_test.dart` includes a test asserting **no Google Books API key is baked into source** (`AppConfig.googleBooksApiKey` is empty when the build defines nothing), locking in the SEC-2 fix so a key can't silently creep back into the default.

## Verification
- `flutter analyze` → clean.
- `flutter test` → the AppConfig regression tests pass.
- Build with `--dart-define=GOOGLE_BOOKS_API_KEY=...` supplies the key at runtime; build without it compiles and runs with search disabled.
