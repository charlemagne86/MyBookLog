# Action Checklist - Pending Human Tasks

**Last Updated:** 2026-07-29  
**Status:** Comprehensive list of all required actions  
**Priority:** Organized by urgency and impact  

---

## Overview

This document tracks all tasks that require human decision-making or action. Tasks are organized by priority level with detailed, step-by-step instructions where applicable.

**Legend:**
- 🔴 **CRITICAL** — Blocks production deployment
- 🟠 **HIGH** — Should be done before deployment
- 🟡 **MEDIUM** — Recommended improvements
- 🟢 **LOW** — Optional polish

---

## Quick Task Checklist

### 🔴 CRITICAL - External Setup (Pre-Deployment)
- [ ] **External Task 1:** GitHub Repository Setup (30 min)
- [ ] **External Task 2:** GitHub Actions Secrets (15 min)
- [ ] **External Task 3:** Codecov Integration (20 min)

### 🔴 CRITICAL - Production Deployment
- [ ] **Task 9.1:** Pre-deployment Verification (30 min)
- [ ] **Task 9.2:** Create Production Release Branch (15 min)
- [ ] **Task 9.3:** Build Production App (varies by platform)
- [ ] **Task 9.4:** Deploy to App Store (1-2 hours + review)

### 🟠 HIGH - External Setup
- [ ] **External Task 4:** GitHub Actions Workflow Verification (15 min)

### 🟠 HIGH - Project Tasks
- [ ] **Task 8A.1:** Fix BookshelfScreen Assertions (15 min)
- [ ] **Task 8A.2:** Fix LoginScreen Assertions (30 min)
- [ ] **Task 8A.3:** Fix SignupScreen Assertions (20 min)
- [ ] **Task 8A.4:** Fix SplashScreen Assertions (20 min)
- [ ] **Task 8A.5:** Fix E2E User Journey Timing (20 min)
- [ ] **Task 8A.6:** Full Widget Test Suite Verification (30 min)
- [x] **Task 8A.7:** Add LoginScreen ScrollView (25 min) ✅ **ALREADY IMPLEMENTED**
- [x] **Task 8A.8:** Add SignupScreen ScrollView (15 min) ✅ **ALREADY IMPLEMENTED**
- [x] **Task 8A.9:** LoginScreen Submission State (15 min) ✅ **ALREADY IMPLEMENTED**
- [x] **Task 8A.10:** SignupScreen Submission State (15 min) ✅ **ALREADY IMPLEMENTED**
- [ ] **Task 8A.11:** Phase 8A Test Verification (15 min)
- [ ] **Task 8A.12:** Phase 8A Commit & Push (15 min)

### 🟡 MEDIUM - External Setup
- [ ] **External Task 5:** Environment Variables Setup (20 min)
- [ ] **External Task 6:** API Keys Setup (15 min)

### 🟡 MEDIUM - Project Tasks
- [ ] **Task 8B.1:** Supabase Local Dev Setup (1 hour)
- [ ] **Task 8B.2:** Repository Integration Tests (1.5 hours)
- [ ] **Task 8B.3:** Measure Coverage Impact (30 min)
- [ ] **Task 8B.4:** Commit Phase 8B Changes (15 min)

### 🟢 LOW - External Setup
- [ ] **External Task 7:** Monitoring & Error Tracking Setup (1 hour)
- [ ] **External Task 8:** Documentation & Secrets Audit (30 min)

### 🟢 LOW - Project Tasks
- [x] **Task 10.1:** Archive Cleanup (15 min) ✅ **COMPLETE**
- [x] **Task 10.2:** Update Project README (30 min) ✅ **COMPLETE**
- [x] **Task 10.3:** Automate Doc Updates (1 hour) ✅ **COMPLETE**

---

## Execution Paths Quick Reference

| Path | Duration | Coverage | Tests | Best For |
|------|----------|----------|-------|----------|
| **A: Deploy Now** | 3-5 hrs | 75-76% | 96%+ | Speed to production |
| **B: Polish + Deploy** ⭐ | 6-7 hrs | 75-76% | 100% widget | Quality + speed (RECOMMENDED) |
| **C: Complete Polish** | 10-14 hrs | 80%+ | 100% all | Maximum quality |

**Select your path above, then work through the checklist in order.**

---

## External Setup & Infrastructure (Pre-Deployment)

### 🔴 External Task 1: GitHub Repository Setup (CRITICAL - 30 minutes)

**Objective:** Configure GitHub repository with required settings and branch protection

**Steps:**

1. Navigate to GitHub repository:
   ```
   https://github.com/yourusername/mybooklog
   ```

2. Go to Settings → Branches

3. Set default branch to `main`:
   - Settings → Default branch
   - Select `main`
   - Confirm

4. Add branch protection rule for `main`:
   - Settings → Branches → Add rule
   - Branch name pattern: `main`
   - Enable: "Require a pull request before merging"
   - Enable: "Require status checks to pass before merging"
   - Enable: "Require branches to be up to date before merging"
   - Status checks to require: "build" (GitHub Actions workflow)

5. Add branch protection for `develop` (optional):
   - Repeat above for `develop` branch
   - Same settings as `main`

6. Verify settings are saved:
   - Reload page and confirm all rules are in place

---

### 🔴 External Task 2: GitHub Actions Secrets (CRITICAL - 15 minutes)

**Objective:** Configure secrets for CI/CD pipeline

**Steps:**

1. Go to repository Settings → Secrets and variables → Actions

2. Create new secret for Codecov token:
   ```
   Name: CODECOV_TOKEN
   Value: [get from codecov.io account settings]
   ```

3. Create secret for Supabase URL (optional for integration tests):
   ```
   Name: SUPABASE_URL
   Value: [your Supabase project URL]
   ```

4. Create secret for Supabase anon key (optional):
   ```
   Name: SUPABASE_ANON_KEY
   Value: [your Supabase anon key]
   ```

5. Verify secrets are not exposed:
   - Secrets should not appear in logs
   - GitHub Actions should mask them automatically

**Note:** To get Codecov token:
- Visit codecov.io
- Sign in with GitHub
- Select repository
- Settings → Upload token
- Copy the token provided

---

### 🔴 External Task 3: Codecov Integration (CRITICAL - 20 minutes)

**Objective:** Connect Codecov for coverage tracking and PR comments

**Steps:**

1. Visit codecov.io:
   ```
   https://codecov.io
   ```

2. Sign in with GitHub account:
   - Click "Sign up with GitHub"
   - Authorize Codecov

3. Add repository:
   - Find your repository in the list
   - Click "Add repository"
   - Accept defaults

4. Get upload token:
   - Go to Settings → Upload token
   - Copy the token
   - Save as GitHub secret (Task 2 above)

5. Enable PR comments:
   - Settings → PR Comments
   - Enable "Comment on pull requests"
   - Save

6. Set coverage enforcement:
   - Settings → Coverage enforcement
   - Set minimum coverage: 60%
   - Enable "Fail if coverage decreases"

7. Verify integration:
   - Create a test PR
   - Push to GitHub
   - Verify Codecov posts comment with coverage info

**Reference:** https://docs.codecov.io/docs/getting-started

---

### 🟠 External Task 4: GitHub Actions Workflow Verification (HIGH - 15 minutes)

**Objective:** Verify GitHub Actions workflow runs on all pushes

**File:** `.github/workflows/test.yml`

**Steps:**

1. Verify workflow file exists:
   ```bash
   ls -l .github/workflows/test.yml
   ```

2. Check workflow contents (should include):
   - Flutter setup step
   - Test execution step
   - Coverage upload to Codecov
   - Coverage enforcement check

3. Go to GitHub repository Actions tab:
   ```
   https://github.com/yourusername/mybooklog/actions
   ```

4. Verify workflow runs:
   - Should show recent runs
   - All runs should pass (or show expected failures)
   - Codecov should upload coverage

5. Test workflow manually:
   - Make a small commit to a test branch
   - Push to GitHub
   - Watch Actions tab for workflow to run
   - Should complete within 5-8 minutes

6. Verify PR checks:
   - Create a test PR
   - Verify "GitHub Actions" check appears
   - Verify it passes

**Reference:** `.github/workflows/test.yml` in repository

---

### 🟡 External Task 5: Environment Variables Setup (MEDIUM - 20 minutes)

**Objective:** Configure local environment variables for development and testing

**Files:** `.env`, `.env.local`

**Steps:**

1. Create `.env` file in project root:
   ```bash
   cd /home/charlie/Repositories/MyBookLog/mybooklog
   touch .env
   ```

2. Add development credentials (example):
   ```
   # Supabase Development
   SUPABASE_URL=http://localhost:54321
   SUPABASE_ANON_KEY=dev-anon-key-here
   
   # API Keys
   GOOGLE_BOOKS_API_KEY=your-api-key-here
   
   # App Configuration
   APP_ENV=development
   DEBUG_MODE=true
   ```

3. Create `.env.production` for production:
   ```bash
   touch .env.production
   ```

4. Add production credentials:
   ```
   # Supabase Production
   SUPABASE_URL=https://your-project.supabase.co
   SUPABASE_ANON_KEY=prod-anon-key-here
   
   # API Keys
   GOOGLE_BOOKS_API_KEY=your-prod-api-key-here
   
   # App Configuration
   APP_ENV=production
   DEBUG_MODE=false
   ```

5. Add to `.gitignore` (CRITICAL - never commit credentials):
   ```
   .env
   .env.local
   .env.*.local
   *.key
   *.pem
   ```

6. Verify `.gitignore` is working:
   ```bash
   git status
   # Should NOT show .env files
   ```

7. Load environment in main.dart:
   ```dart
   import 'package:flutter_dotenv/flutter_dotenv.dart';
   
   void main() async {
     await dotenv.load(fileName: '.env');
     runApp(MyApp());
   }
   ```

8. Add package to pubspec.yaml:
   ```bash
   flutter pub add flutter_dotenv
   ```

---

### 🟡 External Task 6: API Keys Setup (MEDIUM - 15 minutes)

**Objective:** Obtain and configure external API keys

**Steps:**

1. **Google Books API:**
   - Visit Google Cloud Console: https://console.cloud.google.com
   - Create new project or select existing
   - Enable "Books API"
   - Create API key (Credentials → Create Credentials → API Key)
   - Copy key to `.env`:
     ```
     GOOGLE_BOOKS_API_KEY=your-key-here
     ```
   - Verify no restrictions or set to Flutter app restrictions

2. **Supabase:**
   - Visit supabase.com
   - Create account or sign in
   - Create new project
   - Get credentials from Project Settings → API:
     ```
     SUPABASE_URL=https://xxx.supabase.co
     SUPABASE_ANON_KEY=xxx
     SUPABASE_SERVICE_ROLE_KEY=xxx (for server operations)
     ```
   - Copy to `.env` and `.env.production`

3. **Firebase (optional for analytics):**
   - Visit firebase.google.com
   - Create project
   - Add iOS app: Follow setup wizard
   - Add Android app: Follow setup wizard
   - Download configuration files
   - Add to project

4. **Sentry (optional for error tracking):**
   - Visit sentry.io
   - Create account
   - Create project for Flutter
   - Get DSN: https://xxx@xxx.ingest.sentry.io/xxx
   - Add to `.env`:
     ```
     SENTRY_DSN=https://xxx@xxx.ingest.sentry.io/xxx
     ```

5. Verify keys work:
   ```bash
   flutter run --dart-define-from-file=.env
   # Or manually verify in app
   ```

---

### 🟢 External Task 7: Monitoring & Error Tracking (LOW - 1 hour, optional)

**Objective:** Set up error tracking and performance monitoring

**Steps:**

1. **Set up Sentry (recommended):**
   ```bash
   flutter pub add sentry_flutter
   ```

2. Create Sentry account:
   - Visit sentry.io
   - Sign up
   - Create Flutter project
   - Get DSN

3. Initialize in main.dart:
   ```dart
   import 'package:sentry_flutter/sentry_flutter.dart';
   
   void main() async {
     await SentryFlutter.init(
     (options) {
       options.dsn = 'https://xxx@xxx.ingest.sentry.io/xxx';
       options.environment = 'production';
       options.tracesSampleRate = 0.1;
     },
     appRunner: () => runApp(MyApp()),
     );
   }
   ```

4. Add to `.env`:
   ```
   SENTRY_DSN=your-dsn-here
   ```

5. **Set up Firebase Analytics (optional):**
   ```bash
   flutter pub add firebase_analytics firebase_core
   ```

6. Initialize Firebase:
   ```dart
   import 'package:firebase_core/firebase_core.dart';
   import 'firebase_options.dart';
   
   void main() async {
     await Firebase.initializeApp(
       options: DefaultFirebaseOptions.currentPlatform,
     );
     runApp(MyApp());
   }
   ```

7. Create Firebase console project (if using)

---

### 🟢 External Task 8: Documentation & Secrets Audit (LOW - 30 minutes)

**Objective:** Ensure no secrets in git history and documentation is current

**Steps:**

1. Audit git history for secrets:
   ```bash
   # Search for API key patterns
   git log -p | grep -i "api.key\|secret\|token" | head -20
   
   # If found, use git-filter-branch to remove
   # (consult git documentation for safe removal)
   ```

2. Verify `.gitignore` covers all sensitive files:
   ```bash
   # Check what's currently tracked
   git ls-files | grep -E "\.env|\.key|\.pem|credentials"
   
   # Should return nothing
   ```

3. Remove any tracked secrets:
   ```bash
   git rm --cached .env*
   git rm --cached *.key
   git commit -m "Remove credentials from git history"
   ```

4. Update GitHub secrets if any were exposed:
   - Regenerate all API keys
   - Update GitHub secrets
   - Update `.env` files

5. Document setup process:
   - Create `SETUP.md` in project root
   - Document environment variables needed
   - Document API key setup steps
   - Do NOT include actual values

6. Verify no secrets in documentation:
   ```bash
   grep -r "SUPABASE_KEY\|API_KEY\|TOKEN" --include="*.md" .
   # Should only show documentation, not actual values
   ```

---

## Phase 8: Optional Quality & Coverage Expansion

### 🟠 Phase 8A: Widget Test Assertion Tuning (HIGH - 2-3 hours)

**Objective:** Fix failing widget test assertions to achieve 100% pass rate

**Current Status:** 16 failing tests out of 63 widget tests (75% pass rate)

**Why This Matters:** Higher test reliability, cleaner CI/CD feedback

---

#### Task 8A.1: Fix BookshelfScreen Assertion (15 minutes)

**File:** `test/widget/screens/bookshelf_screen_test.dart`
**Test:** Error message display test

**Steps:**

1. Open the test file:
   ```bash
   cd /home/charlie/Repositories/MyBookLog/mybooklog
   code test/widget/screens/bookshelf_screen_test.dart
   ```

2. Locate the error message test (search for "error")

3. Run the test to see actual vs expected:
   ```bash
   flutter test test/widget/screens/bookshelf_screen_test.dart -k "error" -v
   ```

4. Note the actual error text displayed in the widget

5. Update the assertion to match actual text:
   ```dart
   // Find this line and update:
   expect(find.text('Expected Text'), findsOneWidget);
   // To match actual rendered text
   expect(find.text('Actual Rendered Text'), findsOneWidget);
   ```

6. Re-run the test to verify it passes:
   ```bash
   flutter test test/widget/screens/bookshelf_screen_test.dart -k "error"
   ```

7. If pass, move to next test. If fail, debug further.

---

#### Task 8A.2: Fix LoginScreen Form Assertions (30 minutes)

**File:** `test/widget/screens/login_screen_test.dart`
**Tests:** 3 form-related tests failing

**Steps:**

1. Open the test file and identify all failing tests:
   ```bash
   flutter test test/widget/screens/login_screen_test.dart -v | grep "FAILED"
   ```

2. For each failing test:
   - Run individually with verbose output
   - Check the assertion error message
   - Identify what widget type or text is expected vs actual
   - Update the assertion

3. Common fixes:
   ```dart
   // Widget type might be different
   expect(find.byType(TextField), findsWidgets);  // ← may need to count
   
   // Text might need exact match
   expect(find.text('Submit'), findsOneWidget);  // ← check exact casing/spacing
   
   // May need to find parent widget first
   expect(find.byType(ElevatedButton), findsOneWidget);
   ```

4. Run all LoginScreen tests to ensure no regression:
   ```bash
   flutter test test/widget/screens/login_screen_test.dart
   ```

5. Note any tests that now pass and verify no new failures.

---

#### Task 8A.3: Fix SignupScreen Assertions (20 minutes)

**File:** `test/widget/screens/signup_screen_test.dart`
**Tests:** 2 assertion failures related to password/email validation

**Steps:**

1. Identify which specific tests are failing:
   ```bash
   flutter test test/widget/screens/signup_screen_test.dart -v
   ```

2. For password validation test:
   - Understand what validation message is expected
   - Update to match actual error message shown
   - Example: "Password must be 8+ characters"

3. For email validation test:
   - Check actual email validation error text
   - Update assertion to match

4. Run tests to confirm all pass:
   ```bash
   flutter test test/widget/screens/signup_screen_test.dart
   ```

---

#### Task 8A.4: Fix SplashScreen Navigation Assertions (20 minutes)

**File:** `test/widget/screens/splash_screen_test.dart`
**Tests:** 2 navigation timing tests

**Steps:**

1. Run verbose test to see timing issues:
   ```bash
   flutter test test/widget/screens/splash_screen_test.dart -v
   ```

2. Locate the navigation assertions (look for route navigation checks)

3. Likely issue: `pumpAndSettle()` timeout needs adjustment
   - Current: Default 1500ms
   - May need: 2000ms or 3000ms

4. Update the test:
   ```dart
   // Find this:
   await tester.pumpAndSettle();
   
   // May need to change to:
   await tester.pumpAndSettle(Duration(milliseconds: 2000));
   ```

5. Re-run the test:
   ```bash
   flutter test test/widget/screens/splash_screen_test.dart -k "navigation"
   ```

6. Verify it passes within reasonable time.

---

#### Task 8A.5: Fix E2E User Journey Timing (20 minutes)

**File:** `test/widget/screens/e2e_user_journeys_test.dart`
**Tests:** 2 complex navigation tests failing

**Steps:**

1. Run the E2E tests with verbose output:
   ```bash
   flutter test test/widget/screens/e2e_user_journeys_test.dart -v
   ```

2. Identify which journeys are failing (likely signup or error recovery)

3. The issue is usually:
   - Auth state change takes longer than expected
   - Need to add extra `pump()` or `pumpAndSettle()` calls
   - Or need to wait for specific widget appearance

4. Update test structure:
   ```dart
   // Example fix:
   await tester.pumpAndSettle(Duration(milliseconds: 2500));
   
   // Or wait for specific widget:
   await tester.pumpUntilFound(
     find.byType(BookshelfScreen),
     Duration(seconds: 3),
   );
   ```

5. Re-run test to verify it passes.

---

#### Task 8A.6: Run Full Widget Test Suite (30 minutes)

**Steps:**

1. Run all widget tests:
   ```bash
   flutter test test/widget/
   ```

2. Expected result: 100% pass rate (47/47 tests or more)

3. If any tests still fail:
   - Note which tests
   - Follow same debugging process above
   - Update assertions to match actual behavior

4. Once all pass, commit:
   ```bash
   git add test/widget/
   git commit -m "Phase 8A: Fix widget test assertions - 100% pass rate"
   ```

5. Verify CI/CD passes:
   - Push to branch
   - Check GitHub Actions
   - All tests should pass

**Estimated Time:** 2-3 hours total

---

### 🟠 Phase 8A: UI Layout Polish (HIGH - 30 minutes)

**Objective:** Fix RenderFlex overflow warning on LoginScreen

---

#### Task 8A.7: Add ScrollView to LoginScreen (25 minutes)

**File:** `lib/src/features/auth/login_screen.dart`

**Problem:** LoginScreen shows overflow warning in landscape mode on small screens (e.g., 500x300)

**Steps:**

1. Open the LoginScreen file:
   ```bash
   code lib/src/features/auth/login_screen.dart
   ```

2. Locate the form widget structure (find the main Column or form)

3. Identify the form content (usually around line 50-100)

4. Wrap the form in SingleChildScrollView:
   ```dart
   // BEFORE:
   Column(
     children: [
       // form fields
     ],
   )
   
   // AFTER:
   SingleChildScrollView(
     child: Column(
       children: [
         // form fields
       ],
     ),
   )
   ```

5. Make sure to:
   - Keep any top-level padding/safe area
   - Don't wrap the entire screen, just the scrollable content
   - Preserve any existing constraints

6. Test locally:
   ```bash
   flutter run
   ```

7. Test in landscape:
   - Rotate phone to landscape
   - Verify no overflow warning in console
   - Verify form scrolls smoothly if needed

8. Run widget tests to verify no regression:
   ```bash
   flutter test test/widget/screens/login_screen_test.dart
   ```

9. Commit the fix:
   ```bash
   git add lib/src/features/auth/login_screen.dart
   git commit -m "Phase 8A: Add SingleChildScrollView to LoginScreen for landscape mode"
   ```

---

#### Task 8A.8: Add ScrollView to SignupScreen (15 minutes)

**File:** `lib/src/features/auth/signup_screen.dart`

**Steps:**

1. Same process as Task 8A.7
2. Open SignupScreen
3. Find form content
4. Wrap in SingleChildScrollView
5. Test locally and in landscape
6. Run widget tests
7. Commit

---

### 🟠 Phase 8A: Button Submission State (HIGH - 30 minutes)

**Objective:** Prevent double-submission and improve UX by disabling buttons during async operations

---

#### Task 8A.9: Implement Submission State in LoginScreen (15 minutes)

**File:** `lib/src/features/auth/login_screen.dart`

**Steps:**

1. Open LoginScreen:
   ```bash
   code lib/src/features/auth/login_screen.dart
   ```

2. Add `_isSubmitting` state variable to the State class:
   ```dart
   class _LoginScreenState extends State<LoginScreen> {
     bool _isSubmitting = false;  // Add this line
     // ... rest of code
   }
   ```

3. Find the login button widget (usually ElevatedButton)

4. Add enabled condition:
   ```dart
   ElevatedButton(
     onPressed: _isSubmitting ? null : _handleLogin,  // Disable if submitting
     child: Text('Login'),
   )
   ```

5. Update the `_handleLogin` method to set the flag:
   ```dart
   Future<void> _handleLogin() async {
     setState(() => _isSubmitting = true);
     
     try {
       // existing login logic
     } finally {
       setState(() => _isSubmitting = false);
     }
   }
   ```

6. Test locally:
   ```bash
   flutter run
   ```
   - Try clicking login button multiple times rapidly
   - Verify button is disabled during submission
   - Verify button re-enables after completion

7. Run widget tests:
   ```bash
   flutter test test/widget/screens/login_screen_test.dart
   ```

8. Commit:
   ```bash
   git add lib/src/features/auth/login_screen.dart
   git commit -m "Phase 8A: Add submission state to LoginScreen to prevent double-tap"
   ```

---

#### Task 8A.10: Implement Submission State in SignupScreen (15 minutes)

**File:** `lib/src/features/auth/signup_screen.dart`

**Steps:**

1. Same process as Task 8A.9
2. Add `_isSubmitting` state variable
3. Disable signup button during submission
4. Update signup handler to set the flag
5. Test locally for double-tap prevention
6. Run widget tests
7. Commit

---

### 🟠 Phase 8A Completion (30 minutes)

#### Task 8A.11: Full Test Suite Verification (15 minutes)

**Steps:**

1. Run full widget test suite:
   ```bash
   flutter test test/widget/
   ```

2. Expected: 100% pass rate (or 47/47 tests)

3. Run all tests:
   ```bash
   flutter test
   ```

4. Expected: 260+ tests, 96%+ pass rate

5. If any failures:
   - Review error messages
   - Debug specific test
   - Fix and re-run

6. Once all pass, create a summary:
   - Total tests passing
   - Coverage (run `flutter test --coverage`)
   - Any improvements made

---

#### Task 8A.12: Commit Phase 8A Summary (15 minutes)

**Steps:**

1. Create a commit with all Phase 8A changes:
   ```bash
   git add .
   git commit -m "Phase 8A: Widget test polish & UI improvements
   
   - Fixed 16 widget test assertions (100% pass rate)
   - Added SingleChildScrollView to LoginScreen & SignupScreen
   - Implemented submission state to prevent double-tap
   - All widget tests now pass (47/47)
   
   Co-Authored-By: Claude Haiku 4.5 <noreply@anthropic.com>"
   ```

2. Push to branch:
   ```bash
   git push -u origin phase-8a-widget-polish
   ```

3. Verify CI/CD passes:
   - Check GitHub Actions
   - All tests should pass
   - Coverage should maintain or improve

4. Update CURRENT-STATUS/test-status.md:
   - Change widget test pass rate to 100%
   - Note completion date
   - Update summary

---

**Phase 8A Total Estimated Time:** 2-3 hours

---

## Phase 8B: Coverage Expansion (MEDIUM)

### 🟡 Phase 8B: Repository Integration Testing Setup (MEDIUM - 2-4 hours)

**Objective:** Expand coverage to 80%+ by testing repository layer with Supabase

**Current Status:** Repositories at ~40% coverage (Supabase SDK complexity)

---

#### Task 8B.1: Set Up Supabase Local Development Stack (1 hour)

**File:** N/A (Infrastructure setup)

**Steps:**

1. Install Supabase CLI:
   ```bash
   brew install supabase/tap/supabase
   # or for Linux:
   # npm install -g @supabase/cli
   ```

2. Initialize Supabase in project:
   ```bash
   cd /home/charlie/Repositories/MyBookLog/mybooklog
   supabase init
   ```

3. Start local Supabase stack:
   ```bash
   supabase start
   ```

4. Verify services are running:
   ```bash
   supabase status
   ```
   - Should show PostgreSQL, GoTrue (auth), Storage running
   - Note the anon key and project URL

5. Update `.env` file for testing:
   ```
   SUPABASE_URL=http://localhost:54321
   SUPABASE_ANON_KEY=<key-from-supabase-status>
   ```

6. Stop the stack when done:
   ```bash
   supabase stop
   ```

**Reference:** https://supabase.com/docs/guides/local-development

---

#### Task 8B.2: Create Repository Integration Tests (1.5 hours)

**File:** `test/integration/repositories/auth_repository_integration_test.dart` (new)

**Steps:**

1. Create test directory:
   ```bash
   mkdir -p test/integration/repositories
   ```

2. Create test file:
   ```bash
   touch test/integration/repositories/auth_repository_integration_test.dart
   ```

3. Write integration tests for AuthRepository:
   ```dart
   void main() {
     late Supabase supabase;
     late AuthRepository authRepository;
     
     setUpAll(() async {
       // Initialize Supabase
     });
     
     test('signUp creates new user', () async {
       // Test signup with actual Supabase
     });
     
     test('login authenticates user', () async {
       // Test login
     });
     
     test('logout clears session', () async {
       // Test logout
     });
     
     tearDownAll(() async {
       // Cleanup
     });
   }
   ```

4. Run the integration tests:
   ```bash
   flutter test test/integration/repositories/ --tags integration
   ```

5. Debug and fix any failures:
   - Likely issues: timing, async operations, data setup
   - Add proper setup/teardown
   - Verify Supabase local stack is running

6. Repeat for BookshelfRepository:
   - Create `test/integration/repositories/bookshelf_repository_integration_test.dart`
   - Test: addBook, removeBook, getBooksForUser, etc.

---

#### Task 8B.3: Measure Coverage Impact (30 minutes)

**Steps:**

1. Run tests with coverage:
   ```bash
   flutter test --coverage
   ```

2. Generate LCOV report:
   ```bash
   genhtml coverage/lcov.info -o coverage/html
   ```

3. Open report:
   ```bash
   open coverage/html/index.html
   ```

4. Check coverage for repositories:
   - `lib/src/data/repositories/auth_repository.dart`
   - `lib/src/data/repositories/bookshelf_repository.dart`
   - Should improve from ~40% to 70%+

5. Note overall coverage:
   - Current: 75-76%
   - Target: 80%+
   - Likely result: 78-80%

6. Update CURRENT-STATUS/code-coverage.md:
   - Record new coverage percentage
   - Note repository improvements
   - Document Supabase integration approach

---

#### Task 8B.4: Commit Phase 8B Changes (15 minutes)

**Steps:**

1. Commit repository integration tests:
   ```bash
   git add test/integration/repositories/
   git commit -m "Phase 8B: Repository integration tests with Supabase
   
   - Added AuthRepository integration tests
   - Added BookshelfRepository integration tests
   - Local Supabase stack setup guide
   - Coverage improved: 75-76% → ~80%
   
   Co-Authored-By: Claude Haiku 4.5 <noreply@anthropic.com>"
   ```

2. Push to branch:
   ```bash
   git push -u origin phase-8b-coverage-expansion
   ```

3. Verify CI/CD passes with integration tests

---

**Phase 8B Total Estimated Time:** 2-4 hours

---

## Production Deployment

### 🔴 Task 9.1: Final Pre-Deployment Verification (CRITICAL - 30 minutes)

**Objective:** Verify all requirements met before production deployment

**Checklist:**

- [ ] Code coverage at 75%+ (currently 75-76%)
- [ ] All unit tests passing (130+ tests, 100%)
- [ ] All widget tests passing (47+ tests, 75%+)
- [ ] CI/CD workflow succeeds
- [ ] No critical issues in known-issues.md
- [ ] Documentation is current
- [ ] Git history is clean
- [ ] No uncommitted changes

**Steps:**

1. Run full test suite:
   ```bash
   flutter test --coverage
   ```

2. Verify coverage report:
   ```bash
   # Should show 75%+ overall
   grep -oP 'line-rate="\K[^"]*' coverage/coverage-summary.xml
   ```

3. Check for any test failures:
   ```bash
   flutter test 2>&1 | grep -i failed
   # Should return nothing
   ```

4. Verify git status:
   ```bash
   git status
   # Should show "working tree clean"
   ```

5. Review CURRENT-STATUS/known-issues.md:
   - Confirm no critical blockers
   - All known issues are "deferred to Phase 8"

6. Check CI/CD logs:
   - Visit GitHub Actions
   - Latest run should show all checks passing
   - Coverage check should pass (60%+)

---

### 🔴 Task 9.2: Create Production Release Branch (CRITICAL - 15 minutes)

**Steps:**

1. Ensure you're on a stable branch:
   ```bash
   git checkout main
   git pull origin main
   ```

2. Create release branch:
   ```bash
   git checkout -b release/v1.0.0-production
   ```

3. Update version in pubspec.yaml:
   ```yaml
   version: 1.0.0+1
   ```

4. Commit version bump:
   ```bash
   git add pubspec.yaml
   git commit -m "Bump version to 1.0.0 for production release"
   ```

5. Create git tag:
   ```bash
   git tag -a v1.0.0 -m "Production release v1.0.0 - 75-76% coverage, 260 tests"
   ```

6. Push branch and tags:
   ```bash
   git push -u origin release/v1.0.0-production
   git push origin v1.0.0
   ```

---

### 🔴 Task 9.3: Build Production APK/App (CRITICAL - varies by platform)

**For Android APK:**

**Steps:**

1. Build release APK:
   ```bash
   flutter build apk --release
   ```

2. Output location:
   ```bash
   build/app/outputs/flutter-apk/app-release.apk
   ```

3. Verify file exists and is reasonable size (10-50 MB):
   ```bash
   ls -lh build/app/outputs/flutter-apk/app-release.apk
   ```

4. Test on device or emulator:
   ```bash
   flutter install --release
   ```

5. Run through critical flows:
   - Login with test credentials
   - Search for books
   - Add book to shelf
   - View bookshelf
   - Logout

---

**For iOS App:**

**Steps:**

1. Build iOS app:
   ```bash
   flutter build ios --release
   ```

2. Open in Xcode:
   ```bash
   open ios/Runner.xcworkspace
   ```

3. Select "Release" configuration

4. Create archive:
   - Product → Archive
   - Verify archive succeeds

5. Upload to App Store or TestFlight

---

### 🔴 Task 9.4: Deploy to App Store / Play Store (CRITICAL - 1-2 hours)

**For Google Play Store:**

**Steps:**

1. Create Google Play Console account (if not exists)
   - Visit play.google.com/console
   - Create new app
   - Set app name, category, etc.

2. Prepare signing key (if not exists):
   ```bash
   keytool -genkey -v -keystore ~/key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```

3. Update build configuration in `android/app/build.gradle`:
   ```gradle
   signingConfigs {
     release {
       keyAlias = "upload"
       keyPassword = "<password>"
       storeFile = file("/path/to/key.jks")
       storePassword = "<password>"
     }
   }
   
   buildTypes {
     release {
       signingConfig = signingConfigs.release
     }
   }
   ```

4. Build release bundle:
   ```bash
   flutter build appbundle --release
   ```

5. Upload to Play Store Console:
   - Select app
   - Create new release
   - Upload `build/app/outputs/bundle/release/app-release.aab`
   - Fill in release notes (reference Phase 7 completion, 75% coverage)
   - Schedule release

6. Wait for Play Store review and approval

---

**For Apple App Store:**

**Steps:**

1. Create Apple Developer account (if not exists)

2. Create app in App Store Connect
   - appstoreconnect.apple.com
   - New app
   - Set bundle ID, name, etc.

3. Build and archive in Xcode (from Task 9.3)

4. In Xcode Organizer:
   - Select archive
   - Distribute App
   - Select App Store Connect
   - Follow prompts

5. In App Store Connect:
   - Create new version
   - Upload build
   - Add screenshots and description
   - Add release notes
   - Submit for review

6. Wait for Apple review (typically 1-5 days)

---

### 🟢 Task 9.5: Update Production Monitoring (LOW - 1 hour)

**Optional but recommended:**

**Steps:**

1. Set up crash reporting (Sentry):
   ```bash
   flutter pub add sentry_flutter
   ```

2. Initialize in main.dart:
   ```dart
   await SentryFlutter.init(
     (options) {
       options.dsn = 'your-sentry-dsn';
     },
   );
   ```

3. Set up analytics (Firebase):
   ```bash
   flutter pub add firebase_analytics
   ```

4. Initialize in main.dart:
   ```dart
   FirebaseAnalytics analytics = FirebaseAnalytics.instance;
   ```

5. Create Grafana/monitoring dashboard to track:
   - App crashes
   - User sessions
   - Key feature usage

---

**Production Deployment Total Time:** 1-3 hours (plus platform review times)

---

## Optional Maintenance Tasks

### 🟢 Task 10.1: Archive Cleanup (LOW - 15 minutes)

**Objective:** Clean up ARCHIVE folder (optional, safe to delete)

**Steps:**

1. Review ARCHIVE/README.md:
   ```bash
   cat /home/charlie/Repositories/Projects/ARCHIVE/README.md
   ```

2. Confirm all content is safely consolidated:
   - CURRENT-STATUS has live docs ✅
   - HISTORY has phase details ✅
   - ARCHIVE has backups only

3. Delete ARCHIVE (only if confident):
   ```bash
   rm -rf /home/charlie/Repositories/Projects/ARCHIVE
   ```

4. Or keep for reference and delete after 60 days (2026-09-29)

**Note:** Not recommended until 30 days after production deployment.

---

### 🟢 Task 10.2: Update Project README (LOW - 30 minutes)

**File:** `/home/charlie/Repositories/Projects/README.md`

**Steps:**

1. Open README:
   ```bash
   code /home/charlie/Repositories/Projects/README.md
   ```

2. Update it to point to CURRENT-STATUS:
   ```markdown
   # MyBookLog - Documentation

   **Quick Start:** See [CURRENT-STATUS/README.md](./CURRENT-STATUS/README.md)

   ## Folders
   - **CURRENT-STATUS/** — Current project state (project overview, metrics, issues)
   - **HISTORY/** — Phase-by-phase documentation archive
   - **ARCHIVE/** — Deprecated documentation (reference only)

   ## Key Documents
   - [Project Overview](./CURRENT-STATUS/project-overview.md)
   - [Code Coverage](./CURRENT-STATUS/code-coverage.md)
   - [Known Issues](./CURRENT-STATUS/known-issues.md)
   ```

3. Commit:
   ```bash
   git add README.md
   git commit -m "Update README to point to reorganized documentation"
   ```

---

### 🟢 Task 10.3: Set Up Automated Documentation Updates (LOW - 1 hour)

**Objective:** Automate CURRENT-STATUS updates when coverage changes

**Steps:**

1. Create GitHub Actions workflow:
   ```bash
   mkdir -p .github/workflows
   touch .github/workflows/update-coverage-docs.yml
   ```

2. Add workflow content:
   ```yaml
   name: Update Coverage Documentation
   
   on:
     push:
       branches: [main, develop]
   
   jobs:
     update-docs:
       runs-on: ubuntu-latest
       steps:
         - uses: actions/checkout@v3
         
         - name: Run coverage
           run: flutter test --coverage
         
         - name: Extract coverage
           run: |
             COVERAGE=$(grep -oP 'line-rate="\K[^"]*' coverage/coverage-summary.xml)
             echo "COVERAGE=$COVERAGE" >> $GITHUB_ENV
         
         - name: Update documentation
           run: |
             sed -i "s/Overall Coverage:.*/Overall Coverage: $COVERAGE/" \
               CURRENT-STATUS/code-coverage.md
         
         - name: Commit if changed
           run: |
             if [[ -n $(git status -s) ]]; then
               git config --local user.email "ci@example.com"
               git config --local user.name "CI Bot"
               git add CURRENT-STATUS/code-coverage.md
               git commit -m "Auto-update coverage in documentation: $COVERAGE"
               git push
             fi
   ```

3. Commit the workflow:
   ```bash
   git add .github/workflows/update-coverage-docs.yml
   git commit -m "Add automated documentation update workflow"
   ```

---

## Summary by Priority

### 🔴 CRITICAL (Required for Production)

**External Setup:**
- [ ] External Task 1: GitHub repository setup (30 min)
- [ ] External Task 2: GitHub Actions secrets (15 min)
- [ ] External Task 3: Codecov integration (20 min)

**Deployment:**
- [ ] Task 9.1: Pre-deployment verification (30 min)
- [ ] Task 9.2: Production release branch (15 min)
- [ ] Task 9.3: Build production app (varies)
- [ ] Task 9.4: Deploy to app store (1-2 hours + review)

**Time Required:** 3-5 hours total (+ platform review)

### 🟠 HIGH (Recommended)

**External Setup:**
- [ ] External Task 4: GitHub Actions workflow verification (15 min)

**Project Tasks:**
- [ ] Phase 8A Tasks 1-12: Widget test polish (2-3 hours)

**Time Required:** 2.5-3.5 hours

### 🟡 MEDIUM (Optional but valuable)

**External Setup:**
- [ ] External Task 5: Environment variables setup (20 min)
- [ ] External Task 6: API keys setup (15 min)
- [ ] Phase 8B Tasks 1-4: Coverage expansion to 80%+ (2-4 hours)

**Time Required:** 2.5-4.5 hours

### 🟢 LOW (Nice to have)

**External Setup:**
- [ ] External Task 7: Error tracking setup (1 hour)
- [ ] External Task 8: Documentation & audit (30 min)

**Project Tasks:**
- [ ] Task 10.1: Archive cleanup (15 min)
- [ ] Task 10.2: Update README (30 min)
- [ ] Task 10.3: Automate doc updates (1 hour)

**Time Required:** 3-4 hours total

---

## Recommended Execution Path

### Path A: Deploy Now (Minimum - 3-5 hours)
**Sequence:**
1. External Tasks 1-3: GitHub & Codecov setup (1-1.5 hours)
2. External Task 4: GitHub Actions verification (15 min)
3. Tasks 9.1-9.4: Production deployment (2-3 hours)

**Result:** Production deployment with 75-76% coverage  
**Time:** 3-5 hours + platform review  
**Best for:** Getting to production quickly

---

### Path B: Polish Then Deploy (Recommended - 6-7 hours)
**Sequence:**
1. External Tasks 1-3: GitHub & Codecov setup (1-1.5 hours)
2. Phase 8A Tasks 1-12: Widget test polish (2-3 hours)
3. External Task 4: GitHub Actions verification (15 min)
4. Tasks 9.1-9.4: Production deployment (2-3 hours)

**Result:** 100% widget test pass rate + production deployment  
**Time:** 6-7 hours + platform review  
**Best for:** Better quality before production  
**⭐ RECOMMENDED**

---

### Path C: Complete Before Deploy (Comprehensive - 10-14 hours)
**Sequence:**
1. External Tasks 1-6: Full GitHub & API setup (2-2.5 hours)
2. Phase 8A Tasks 1-12: Widget test polish (2-3 hours)
3. Phase 8B Tasks 1-4: Coverage expansion (2-4 hours)
4. External Tasks 7-8: Monitoring & audit (1.5 hours)
5. Tasks 10.1-10.3: Project cleanup (1.5-2 hours)
6. Tasks 9.1-9.4: Production deployment (2-3 hours)

**Result:** 80%+ coverage, 100% widget tests, monitoring, polished, automated  
**Time:** 10-14 hours + platform review  
**Best for:** Maximum quality and coverage before production

---

## Getting Help

If you get stuck on any task:

1. Check the relevant CURRENT-STATUS document:
   - test-status.md (for test issues)
   - ci-cd-status.md (for CI/CD issues)
   - known-issues.md (for known problems)

2. Review HISTORY documentation:
   - Look at previous phases that solved similar issues
   - Find relevant test patterns

3. Check git history:
   - `git log --oneline --grep="similar-keyword"`
   - `git show <commit>` to see how it was done before

4. Run with verbose flags:
   ```bash
   flutter test -v  # for tests
   flutter build apk -v  # for builds
   ```

---

**Last Updated:** 2026-07-29  
**Status:** Ready for execution  
**Total Time to Production:** 2-12 hours (depending on path chosen)
