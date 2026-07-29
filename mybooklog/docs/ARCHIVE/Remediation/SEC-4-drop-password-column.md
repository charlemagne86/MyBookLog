# SEC-4 — Removed unsalted SHA-256 password store

**Phase:** 1 (Correctness) · **Status:** ✅ Complete (DB + client)
**Related:** [[PROJECT_ANALYSIS]] · [[Remediation-Index]] · [[SEC-7-BUG-7-provisioning-trigger]]

## Problem
Sign-up hashed the password with **unsalted SHA-256** and stored it in `public.users.encrypted_password` — a redundant, trivially-crackable credential store beside Supabase Auth. Nothing read it.

## Actions taken
- **DB (migration `drop_password_column_and_add_profile_trigger`):** `alter table public.users drop column if exists encrypted_password;` (the column was `NOT NULL`, so it had to be dropped before the new profile trigger could insert rows).
- **Client (`lib/main.dart`):**
  - Deleted the `_hashPassword` method.
  - Removed `import 'package:crypto/crypto.dart';` (kept `dart:convert`, still used for `jsonDecode`).
  - Removed the `encrypted_password` field from the sign-up write (the whole client-side `users` write was removed — see [[SEC-7-BUG-7-provisioning-trigger]]).
- **pubspec.yaml:** removed the now-unused `crypto` dependency.

## Verification
- `flutter analyze` → **No issues found**.
- `flutter test` → 3/3 pass (incl. a SEC-2 regression test).
- `information_schema.columns` no longer lists `encrypted_password` on `public.users`.
