# SEC-2 — Google Books API key removed from source

**Phase:** 0 (Stop the bleeding) · **Status:** ✅ Code complete · ⚠️ Key rotation is a manual user action
**Related:** [[PROJECT_ANALYSIS]] · [[Remediation-Index]] · builds on [[ARCH-2-appconfig]]

## Problem
The Google Books API key was hardcoded at `lib/main.dart:14` and present in public git history — usable by anyone who viewed the repo.

## Actions taken
1. **Created `lib/src/core/config/app_config.dart`** — an `AppConfig` class that reads all configuration from compile-time environment variables via `String.fromEnvironment`:
   - `GOOGLE_BOOKS_API_KEY` — **no default** (must be injected; `hasGoogleBooksApiKey` reports whether it was supplied).
   - `SUPABASE_URL` / `SUPABASE_PUBLISHABLE_KEY` — defaulted to the current public values (publishable/anon keys are designed to ship in clients and are protected by RLS).
2. **Removed the hardcoded key and the two Supabase literals** from `main.dart` (`const _googleBooksApiKey` deleted; `Supabase.initialize` now uses `AppConfig`).
3. **Repointed all three Google Books URLs** (search, load-more, exact-volume lookup) to `AppConfig.googleBooksApiKey`.
4. **Added `env.example.json`** (committed template) and **gitignored `env.json`** (real secrets) in `mybooklog/.gitignore`.

## How to build now
```bash
flutter run --dart-define-from-file=env.json
# or: flutter run --dart-define=GOOGLE_BOOKS_API_KEY=xxx
```

## Still required from you (cannot be done from code)
- **Rotate the key in Google Cloud Console**: create a new key restricted to the Books API, put it in `env.json`, then **delete the leaked key**. History purging alone does not undo a public secret.
==RA Jul 17 - Done==

## Verification
- `flutter analyze` — no new issues; no remaining reference to the literal key (`grep AIzaSy lib/` returns nothing).
