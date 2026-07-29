# BUG-2 / BUG-3 / BUG-4 — Auth UX + session handling

**Phase:** 1 (Correctness) · **Status:** ✅ Complete (client)
**Related:** [[PROJECT_ANALYSIS]] · [[Remediation-Index]] · reactive routing formalized later in [[ARCH-3-migrations-and-routing]]

## BUG-2 — Logout crashed the login screen
`LoginScreen.build` returned a bare `Padding` with no `Scaffold`/`Material`, so pushing it directly (after logout) threw *"No Material widget found"*. It only worked at startup because `SplashScreen` supplied the Scaffold.
- **Fix:** `LoginScreen.build` now returns its own `Scaffold > SafeArea > Padding > SingleChildScrollView > Column`.

## BUG-3 — Login failures were silent
The catch block set nothing (error assignment commented out) and the error `Text` widget was commented out.
- **Fix:** added `_friendlyAuthMessage(AuthException)` mapping (`invalid credentials` → "Incorrect email or password.", `email not confirmed` → confirm-email prompt, else the raw message); the `_login` catch now sets `_errorText` for both `AuthException` and generic/network errors; restored the error `Text` (uses `colorScheme.error`). This also cleared the two pre-existing `unused_field`/`unused_local_variable` analyzer warnings.

## BUG-4 — Persisted sessions were ignored
The app always ran splash → login on a fixed 2s timer, forcing re-login every launch.
- **Fix:** `_SplashScreenState._routeAfterSplash()` waits the 2s, then `pushReplacement`s to `BookshelfScreen` if `Supabase.instance.client.auth.currentSession != null`, else `LoginScreen`. Splash `build` is now purely presentational.
- **Note:** this is the minimal correct fix (session restore respected). The fully **reactive** `onAuthStateChange` routing is delivered with go_router in Phase 3 — see [[ARCH-3-migrations-and-routing]].

## Verification
- `flutter analyze` → **No issues found** (previously 2 warnings).
- `flutter test` → 3/3 pass.
