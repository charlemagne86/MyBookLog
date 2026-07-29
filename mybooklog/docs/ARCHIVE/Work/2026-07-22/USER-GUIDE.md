# Phase 4: User Guide (Daily Workflow)

**How to use Phase 4 testing in your daily development.**

---

## Your Testing Workflow

### Typical Development Day

```
Morning:
├─ Start emulator
├─ Make code changes
├─ Test locally (Android)
├─ Fix any issues
└─ Commit to git

Afternoon:
├─ Make more changes
├─ Test locally again
├─ Push to GitHub
├─ GitHub tests iOS (automatic)
└─ Check results in Actions tab
```

---

## Step-by-Step: Your First Day

### 1. Start Your Emulator (1 time per day)

```bash
emulator -avd Pixel_4_API_30 &
```

This starts in background. Wait ~60 seconds for full boot.

**Verify it's ready:**
```bash
flutter devices
```

Should show: `emulator-5554` or similar

### 2. Make Code Changes

Edit your code as usual:
```bash
vim lib/src/features/auth/login_screen.dart
```

### 3. Test Locally (Before Committing)

```bash
flutter test integration_test/ --verbose
```

This runs all 29 Phase 4 tests.

**What to expect:**
- 5-10 minutes execution time
- Output shows each test result
- ✅ or ❌ at end

**If tests pass:**
```
✅ All 29 tests passed (8 seconds elapsed)
```

Then you can commit.

**If tests fail:**
```
❌ 1 test failed
Integration test failed: ...
```

Then debug and fix.

### 4. When Ready, Commit and Push

```bash
git add .
git commit -m "Feature: ..."
git push
```

### 5. GitHub Tests Run Automatically

- iOS tests start on GitHub's macOS servers
- Takes 10-15 minutes
- Results appear in Actions tab

**Check results:**
1. Go to: GitHub repo → Actions tab
2. Click: Latest "Phase 4 Tests - iOS"
3. See: ✅ or ❌

---

## Common Workflows

### Workflow 1: Quick Test Before Commit

```bash
# Test just performance (faster)
flutter test integration_test/performance/ --verbose

# Or just E2E (also fast)
flutter test integration_test/e2e/ --verbose

# Or everything
flutter test integration_test/ --verbose
```

### Workflow 2: Debug Failing Test

```bash
# Run specific test with verbose output
flutter test integration_test/performance/app_startup_test.dart --verbose

# Read error message carefully
# Fix the issue
# Run test again
```

### Workflow 3: Performance Check

If you're optimizing search or navigation:

```bash
# Run relevant tests
flutter test integration_test/performance/search_performance_test.dart --verbose

# Check metrics in output
⏱️ Search filter: 85ms (baseline: < 100ms) ✅
```

### Workflow 4: Quick Sanity Check

Before committing, run just one test:

```bash
flutter test integration_test/e2e/complete_user_journey_test.dart --verbose
```

This tests main flow quickly.

---

## Performance Baselines (What to Watch For)

### App Startup
- Target: < 2.0 seconds
- If > 2.2 seconds: Investigate performance issue

### Navigation
- Target: < 500ms
- If > 550ms: May have added slow operations

### Search Performance
- Small dataset: < 100ms
- Large dataset: < 200ms
- If exceeding: Optimize filter logic

### Memory
- Baseline: < 150MB
- If > 165MB: May have memory leak

---

## Reading Test Output

### Successful Test

```
✓ app_startup_time_cold_launch (8s)
  ⏱️ App startup: 1850ms (threshold: 2000ms) ✅

════════════════════════════════════════════════════════════
✓ 1 test passed (8 seconds)
════════════════════════════════════════════════════════════
```

**What this means:**
- ✓ = Test passed
- 8s = Test execution time
- 1850ms = Measured metric
- threshold: 2000ms = Target
- ✅ = Within target

### Failed Test

```
❌ search_filter_large_dataset (6s)
  Expected: <= 200ms, got 215ms ✗

════════════════════════════════════════════════════════════
❌ 1 test failed
════════════════════════════════════════════════════════════
```

**What this means:**
- ❌ = Test failed
- Expected 200ms: Target threshold
- got 215ms: Actual measurement
- ✗ = Exceeds target

**Action:** Optimize search logic or investigate why it's slow

---

## Debugging Tips

### Failing Test, Don't Know Why?

1. **Read the test name** — It usually describes what's being tested
   - `search_filter_large_dataset` → Testing search with many books

2. **Read the error message** — It shows expected vs actual
   - `Expected: <= 200ms, got 215ms`

3. **Look at test code** — Read the test to understand what it does
   - File: `integration_test/performance/search_performance_test.dart`
   - Look for test method name

4. **Check comments** — Tests have BUSINESS LOGIC and TECHNICAL comments
   - Explains why the test exists
   - Explains what it's testing

5. **Run just that test** — To focus your debugging
   ```bash
   flutter test integration_test/performance/search_performance_test.dart --verbose
   ```

### Performance Regression (Test Was Passing, Now Failing)

1. **Check what changed** — `git diff` to see code changes
2. **Look for slow operations** — Loops, queries, API calls
3. **Optimize** — Make changes to improve performance
4. **Re-test** — Run test again to verify improvement
5. **Push** — If passing, commit and push

---

## GitHub Actions (Automatic iOS Testing)

### How It Works

```
You push → GitHub receives → iOS tests start
↓
Runs Phase 4 tests on macOS
↓
Results in 10-15 minutes
↓
You see ✅ or ❌ in Actions tab
```

### Checking Results

1. **Go to Actions tab:**
   https://github.com/YOUR_USERNAME/MyBookLog/actions

2. **Look for "Phase 4 Tests - iOS"** (most recent at top)

3. **Click it** to see details

4. **Scroll down** to see individual test results

### What if iOS Test Fails?

1. **Check the error message** — Same as local tests
2. **Reproduce locally** — Run same test on Android:
   ```bash
   flutter test integration_test/e2e/complete_user_journey_test.dart --verbose
   ```
3. **Fix the issue** — Debug and fix locally
4. **Push again** — New push triggers new iOS test

---

## Best Practices

### ✅ Do This

**Before every commit:**
- Run tests locally
- Verify all 29 pass
- Check performance metrics

**After pushing:**
- Check GitHub Actions tab
- Verify iOS tests pass
- Monitor performance trends

**When optimization needed:**
- Run specific performance test
- Check metric against baseline
- Optimize code
- Re-run test

**When debugging:**
- Read test name (describes what it tests)
- Read error message (shows expected vs actual)
- Read test code (understand what's being tested)
- Read comments (why this test exists)

### ❌ Don't Do This

**Don't ignore failing tests** — They indicate real issues

**Don't push without local testing** — GitHub tests take 10+ min, find issues locally first

**Don't adjust baselines without reason** — Baselines protect against regressions

**Don't skip performance tests** — Performance is a feature

---

## Handling Edge Cases

### "GitHub test passes, but I think it should have more metrics"

→ Tests measure the most important paths. If you want more, that's a future enhancement.

### "My test passes locally but fails on GitHub"

→ Rare, but can happen if:
- Emulator speed differs from GitHub's macOS
- Timing is different
- Try rerunning GitHub test (sometimes network causes issues)

### "I need to run only E2E tests, not performance tests"

```bash
flutter test integration_test/e2e/ --verbose
```

### "I need to run a specific test repeatedly"

```bash
# Run same test 3 times
for i in {1..3}; do
  flutter test integration_test/performance/app_startup_test.dart --verbose
done
```

### "Emulator is slow today"

→ Sometimes emulator needs restart

```bash
# Kill it
adb emu kill

# Restart
emulator -avd Pixel_4_API_30 &
```

---

## Daily Checklist

### Morning (Start of Day)

- [ ] Start emulator: `emulator -avd Pixel_4_API_30 &`
- [ ] Verify ready: `flutter devices`
- [ ] Pull latest: `git pull`

### Before Each Commit

- [ ] Run tests: `flutter test integration_test/ --verbose`
- [ ] All passing? ✅
- [ ] Performance metrics reasonable?

### After Each Push

- [ ] Check GitHub Actions
- [ ] iOS tests running or passed?
- [ ] Monitor trends

### End of Day

- [ ] All tests passing? ✅
- [ ] Push any final changes
- [ ] Emulator can stay running (or `adb emu kill`)

---

## Performance Monitoring

### Weekly Check

Once a week, run all tests and note metrics:

```bash
flutter test integration_test/ --verbose 2>&1 | tee weekly-report.txt
```

This creates `weekly-report.txt` with all output.

**Check for trends:**
- Is startup time increasing?
- Is search getting slower?
- Any memory creep?

If trends worsen, investigate and optimize.

### Monthly Review

Compare metrics to previous month. Look for:
- Performance trends (improving? degrading?)
- Test stability (always passing? sometimes failing?)
- Coverage (still at 85%+?)

---

## Summary

**Your Job:**
1. Code
2. Test locally (5 min)
3. Push
4. Monitor GitHub (automatic)

**Our Job:**
- GitHub tests iOS automatically
- Metrics tracked
- Regressions detected
- Performance monitored

**Result:**
- Confident features
- No performance surprises
- Users happy

---

**Next:** [[REFERENCE]] (commands & troubleshooting) or [[ARCHITECTURE]] (deep dive)

