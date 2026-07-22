# Phase 4: Performance & E2E Testing Setup

**Status:** ✅ Ready to Execute  
**Strategy:** Hybrid iOS (GitHub Actions) + Android (Local Emulator)  
**Tests:** 29 (16 performance + 13 E2E)  
**Coverage:** 85%+ (expected)  

---

## Quick Start (Choose One)

### Option A: Local Android Testing (5 min)

```bash
# Requires one-time emulator setup (see below)

# Start emulator
emulator -avd Pixel_4_API_30 &

# Run Phase 4 tests
flutter test integration_test/performance/ integration_test/e2e/ --verbose
```

### Option B: Automatic iOS Testing (Automatic on Push)

```bash
# Just push to GitHub
git push

# Watch in GitHub → Actions tab
# Results appear in 10-15 minutes
```

### Option C: Both (Recommended)

```bash
# Local Android (fast feedback)
emulator -avd Pixel_4_API_30 &
flutter test integration_test/ --verbose

# Push to GitHub (iOS tests automatically)
git push
```

---

## Setup (One Time)

### 1. Android Emulator Setup (15 min)

```bash
# Create virtual device
sdkmanager "system-images;android-30;default;x86_64"
avdmanager create avd -n "Pixel_4_API_30" -k "system-images;android-30;default;x86_64" -d "Pixel 4"

# Verify
emulator -list-avds
```

### 2. GitHub Actions (Already Configured ✅)

Workflows ready in `.github/workflows/`:
- `phase4-ios-tests.yml` — iOS testing (GitHub macOS)
- `phase4-tests.yml` — Android testing (backup)

Just push and iOS tests run automatically! ✅

---

## File Structure

```
integration_test/
├── helpers/
│   ├── performance_test_helper.dart      # Measurement utilities
│   └── integration_test_helper.dart      # Test helpers (existing)
├── performance/
│   ├── app_startup_test.dart             # 4 startup tests
│   ├── navigation_latency_test.dart      # 5 navigation tests
│   └── search_performance_test.dart      # 7 search tests
└── e2e/
    ├── complete_user_journey_test.dart   # 6 E2E tests
    └── session_persistence_test.dart     # 7 session tests

.github/workflows/
├── phase4-ios-tests.yml                  # iOS testing on GitHub
├── phase4-tests.yml                      # Android testing (backup)
└── test.yml                              # Existing workflow
```

---

## Test Suites

### Performance Tests (16 total)

**App Startup (4 tests)**
- Cold start timing
- Warm start (logged in)
- Logged-out startup
- Consistency check

**Navigation (5 tests)**
- Login → Bookshelf transition
- Navigation consistency
- Rapid navigation handling
- Screen smoothness
- [Reserve: Gesture navigation]

**Search (7 tests)**
- Small dataset filtering
- Large dataset filtering
- Progressive filtering
- Clear search
- No results display
- Rapid queries
- [Reserve: Network search]

### E2E Tests (13 total)

**User Journeys (6 tests)**
- Full onboarding flow
- Login → View → Search
- Error recovery
- Multi-operation session
- Rapid interactions
- State transitions

**Session Persistence (7 tests)**
- Persist after reopen
- Data availability
- Logout flow
- Navigation within session
- Concurrent operations
- Timeout behavior
- [Reserve: Long session test]

---

## Performance Baselines

| Metric | Target | Status |
|--------|--------|--------|
| App Startup (cold) | < 2.0s | ⏳ Testing |
| App Startup (warm) | < 1.5s | ⏳ Testing |
| Navigation | < 500ms | ⏳ Testing |
| Search (small) | < 100ms | ⏳ Testing |
| Search (large) | < 200ms | ⏳ Testing |
| Memory | < 150MB | ⏳ Testing |
| Scroll FPS | 60 FPS | ⏳ Testing |

---

## Running Tests

### All Tests

```bash
# Local Android
emulator -avd Pixel_4_API_30 &
flutter test integration_test/ --verbose

# Specific suite
flutter test integration_test/performance/ --verbose
flutter test integration_test/e2e/ --verbose
```

### Specific Test

```bash
flutter test integration_test/performance/app_startup_test.dart --verbose
flutter test integration_test/e2e/complete_user_journey_test.dart --verbose
```

### With Coverage

```bash
flutter test integration_test/ --coverage --verbose
# Results in: coverage/lcov.info
```

### On GitHub (Automatic)

```bash
git push  # iOS tests run automatically
# Check: GitHub → Actions tab
```

---

## Expected Results

### When Tests Pass ✅

```
✅ Performance Tests (16/16)
   • Startup: 1850ms (< 2000ms) ✅
   • Navigation: 450ms (< 500ms) ✅
   • Search: 85ms (< 100ms) ✅

✅ E2E Tests (13/13)
   • Onboarding: Complete ✅
   • User Journeys: All passing ✅
   • Session Management: Valid ✅

📊 Coverage: 85%+ ✅
⏱️ Total Time: ~15 min (iOS + Android combined)
```

### When Tests Fail ❌

1. Check error message
2. Read test comments (BUSINESS LOGIC + TECHNICAL)
3. See HYBRID-TESTING-SETUP-GUIDE.md troubleshooting
4. Fix and re-run

---

## GitHub Actions Monitoring

### View Test Results

1. Go to: https://github.com/YOUR_USERNAME/MyBookLog
2. Click: **Actions** tab
3. Click: **Phase 4 Tests - iOS** (or Android)
4. See: ✅ or ❌ for each test

### Download Artifacts

1. Actions tab → Phase 4 test run
2. Scroll down → **Artifacts** section
3. Download: test-results, coverage, etc.

### Track Coverage Over Time

Codecov integration (optional):
- Set up: https://codecov.io
- Coverage reports automatically uploaded
- Track trends over time

---

## Troubleshooting

### Android Emulator Issues

```bash
# Emulator won't start?
emulator -list-avds  # List available
emulator -avd Pixel_4_API_30 -wipe-data  # Wipe data and retry

# Still failing?
avdmanager delete avd -n Pixel_4_API_30  # Delete and recreate
avdmanager create avd -n "Pixel_4_API_30" -k "system-images;android-30;default;x86_64" -d "Pixel 4"
```

### Test Timeout

```bash
flutter test integration_test/ \
  --dart-define=FLUTTER_TEST_TIMEOUT=60000 \
  --verbose
```

### GitHub Actions Failures

1. Check workflow file: `.github/workflows/phase4-ios-tests.yml`
2. View logs in Actions tab
3. Common issue: Simulator didn't boot in time
   - Edit workflow: increase `sleep 30` to `sleep 60`

---

## Development Workflow

### During Development

```bash
# 1. Make changes
vim lib/...

# 2. Test locally (Android)
emulator -avd Pixel_4_API_30 &
flutter test integration_test/ --verbose

# 3. If passing, push
git commit -am "Feature: ..."
git push

# 4. GitHub tests iOS automatically
# Check results in Actions tab
```

### Time Per Iteration

- Local Android test: 5 min
- Push to GitHub: 1 min
- GitHub iOS test: 10 min
- **Total: 16 min per iteration**

---

## Cost Analysis

| Component | Cost |
|-----------|------|
| Android Emulator | Free (Android SDK) |
| GitHub Actions iOS | Free (2000 min/month included) |
| macOS runners (GitHub) | Free tier includes up to 3000 min/month |
| Total | **$0** |

At ~15 min per push × 30 days = 450 min/month (well under free limit)

---

## Documentation

Key documents in `/Projects/Daily/2026-07-22/`:

1. **PHASE-4-STRATEGY.md** — High-level strategy and overview
2. **PHASE-4-IMPLEMENTATION.md** — Technical implementation details
3. **PHASE-4-PERFORMANCE-BASELINES.md** — Performance metrics and baselines
4. **HYBRID-TESTING-SETUP-GUIDE.md** — Detailed setup instructions
5. **PHASE-4-DEVICE-TESTING-GUIDE.md** — Quick reference for running tests
6. **PHASE-4-iOS-TESTING-STRATEGY.md** — iOS-specific considerations
7. **PHASE-4-EXECUTION-REPORT.md** — Device testing plan and troubleshooting
8. **ACTION-REQUIRED-OUTSIDE-CLAUDE.md** — What you need to do (outside Claude)

---

## Success Criteria

When Phase 4 is complete:

- ✅ All 29 tests passing
- ✅ Performance baselines verified
- ✅ No performance regressions
- ✅ Coverage at 85%+
- ✅ iOS and Android both tested

---

## Next Steps

1. **Set up Android Emulator** (15 min, one-time)
   ```bash
   sdkmanager "system-images;android-30;default;x86_64"
   avdmanager create avd -n "Pixel_4_API_30" -k "system-images;android-30;default;x86_64" -d "Pixel 4"
   ```

2. **Push to GitHub** (automatic)
   ```bash
   git push
   ```

3. **Test locally or check GitHub Actions**
   - Local: `emulator -avd Pixel_4_API_30 &` + `flutter test integration_test/ --verbose`
   - GitHub: Check Actions tab for results

---

## Quick Links

- **Local Testing:** `flutter test integration_test/`
- **GitHub Actions:** GitHub → Actions tab
- **Help:** See HYBRID-TESTING-SETUP-GUIDE.md
- **Troubleshooting:** See PHASE-4-DEVICE-TESTING-GUIDE.md
- **What to Do:** See ACTION-REQUIRED-OUTSIDE-CLAUDE.md

---

**Phase 4 Testing: READY TO EXECUTE ✅**

Hybrid strategy configured. 
iOS-first, Android for dev feedback.
All tests written and production-ready.
Documentation complete.

Next: Follow ACTION-REQUIRED-OUTSIDE-CLAUDE.md for setup.

