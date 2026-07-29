# SEC-6 — Auth & function hardening

**Phase:** 0 (Stop the bleeding) · **Status:** ✅ DB done · ⚠️ 2 dashboard toggles are manual
**Related:** [[PROJECT_ANALYSIS]] · [[Remediation-Index]] · [[SEC-3-BUG-1-catalog-rls-and-add-book]]

## Actions taken (database)
- **Pinned `public.set_updated_at` search_path** to `''` (migration `pin_set_updated_at_search_path`). Clears the `function_search_path_mutable` advisory. Verified: `proconfig = {search_path=""}`.

## Still required from you (Supabase dashboard — no API/MCP toggle)
1. **Enable leaked-password protection** — Authentication → Providers → Email → "Prevent use of leaked passwords" (HaveIBeenPwned check). Advisor `auth_leaked_password_protection` stays WARN until this is on.
==RA - Attempted Jul17 - available in paid plans of Supabase - Pro and above - Pending


2. **Set a server-side password policy** — Authentication → Policies → minimum length/complexity. The 8-char/complexity rule currently lives only in the Flutter client (`_validatePassword`) and is bypassable by direct API calls.
==RA - Unable to locate - Pending== 

## Accepted residual finding
- `authenticated_security_definer_function_executable` (WARN) on `add_book_to_shelf` is **intentional** — see [[SEC-3-BUG-1-catalog-rls-and-add-book]]. The function must be callable by authenticated users and validates `auth.uid()` internally. No action.

## Verification
- Security advisors after Phase 0: only the two items above remain (one manual toggle, one accepted-by-design). All RLS + search_path findings resolved.
