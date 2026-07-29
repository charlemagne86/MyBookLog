# SEC-7 + BUG-7 — Server-side user provisioning

**Phase:** 1 (Correctness) · **Status:** ✅ Complete (DB + client)
**Related:** [[PROJECT_ANALYSIS]] · [[Remediation-Index]] · [[SEC-4-drop-password-column]]

## Problems
- **SEC-7:** sign-up created the `public.users` profile client-side *after* `signUp`. Under email-confirmation there is no session, so the write failed RLS (`auth.uid()` null) and could orphan the auth user.
- **BUG-7:** the `bookshelf` row was upserted client-side on every login — a redundant round-trip and an implicit ordering dependency for the `bookshelf_items` FK.

## Actions taken (DB)
- Added `public.handle_new_user_profile()` (`SECURITY DEFINER`, `search_path=''`) + trigger `on_auth_user_created_profile` on `auth.users`. It inserts the `public.users` row from `new.email` and `new.raw_user_meta_data` (`first_name`/`last_name`), `on conflict (id) do nothing`. Migration: `drop_password_column_and_add_profile_trigger`.
- The `bookshelf` row was **already** provisioned server-side by the pre-existing `on_auth_user_created_bookshelf` trigger — confirmed during analysis, so only the client redundancy needed removing.
- **Follow-up hardening (migration `revoke_execute_on_trigger_functions`):** the final security-advisor pass flagged that the new `handle_new_user_profile()` (a `SECURITY DEFINER` trigger function) kept its default PUBLIC `EXECUTE` grant, so `anon`/`authenticated` could invoke it directly at `/rest/v1/rpc/`. Revoked `EXECUTE` from `public, anon, authenticated` on both `handle_new_user_profile()` and `set_updated_at()`, matching the baseline `handle_new_user_bookshelf()` (service_role only). Revoking does not affect trigger firing. Both advisories are now cleared.

## Actions taken (client — `lib/main.dart`)
- Sign-up now passes names as auth metadata: `signUp(email, password, data: {first_name, last_name})` and performs **no** `public.users` write.
- Removed the login-time `bookshelf` upsert entirely.

## Result
The client makes zero table writes during auth; both `users` and `bookshelf` rows are created atomically by triggers when the auth user is created — correct even under email confirmation, and impossible to orphan.

## Verification
- `flutter analyze` clean; `flutter test` 3/3.
- Triggers confirmed present on `auth.users`: `on_auth_user_created_profile`, `on_auth_user_created_bookshelf`.
