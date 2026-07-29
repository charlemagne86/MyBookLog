# Phase 4: Reference (Commands & Troubleshooting)

**Quick lookup for commands and solutions.**

---

## Emulator Commands

### Emulator Management

```bash
# Start emulator
emulator -avd Pixel_4_API_30 &

# List all virtual devices
emulator -list-avds

# Stop emulator
adb emu kill

# Delete device (if needed)
avdmanager delete avd -n Pixel_4_API_30

# Create new device
avdmanager create avd -n "Pixel_4_API_30" -k "system-images;android-30;default;x86_64" -d "Pixel 4"
```

### Device Status

```bash
# List connected devices
flutter devices

# List just Android devices
adb devices

# Get emulator details
adb shell getprop ro.build.version.release

# Check emulator boot status
adb shell getprop sys.boot_completed
```

---

## Flutter Testing Commands

### Run All Tests

```bash
# All Phase 4 tests
flutter test integration_test/ --verbose

# With coverage
flutter test integration_test/ --coverage --verbose
```

### Run Specific Suites

```bash
# Performance tests only
flutter test integration_test/performance/ --verbose

# E2E tests only
flutter test integration_test/e2e/ --verbose

# Startup tests only
flutter test integration_test/performance/app_startup_test.dart --verbose
```

### Run Specific Tests

```bash
# Named test
flutter test integration_test/performance/app_startup_test.dart -n "app_startup_time_cold_launch" --verbose

# Multiple tests
flutter test integration_test/performance/app_startup_test.dart \
          integration_test/e2e/complete_user_journey_test.dart --verbose
```

### Testing Options

```bash
# Verbose output
flutter test integration_test/ --verbose

# Extended timeout (60 seconds)
flutter test integration_test/ --dart-define=FLUTTER_TEST_TIMEOUT=60000 --verbose

# With profiling
flutter test integration_test/ --profile --verbose

# Stop on first failure
flutter test integration_test/ -x --verbose

# Random order (test independence)
flutter test integration_test/ --test-randomize-ordering-seed=12345 --verbose
```

---

## Git Commands

### Basic Git

```bash
# Check status
git status

# Stage files
git add .

# Commit
git commit -m "Feature: ..."

# Push (triggers GitHub Actions)
git push

# View recent commits
git log --oneline -5

# View changes
git diff

# View staged changes
git diff --cached
```

### Undoing Changes

```bash
# Undo staged changes
git restore --staged <file>

# Undo working directory changes
git restore <file>

# View previous version
git show HEAD:path/to/file

# Revert last commit (creates new commit)
git revert HEAD
```

---

## GitHub Actions

### Monitoring

```bash
# In browser:
# https://github.com/YOUR_USERNAME/MyBookLog/actions
```

### Commands for Workflows

```bash
# List workflows
gh workflow list

# View workflow details
gh workflow view "Phase 4 Tests - iOS"

# Trigger workflow manually
gh workflow run phase4-ios-tests.yml -r main

# View workflow runs
gh run list --workflow=phase4-ios-tests.yml
```

---

## Troubleshooting

### Problem: Emulator Won't Start

**Check if system image is installed:**
```bash
sdkmanager --list | grep "system-images;android-30"
```

**Reinstall system image:**
```bash
sdkmanager "system-images;android-30;default;x86_64"
```

**Create with more memory:**
```bash
avdmanager create avd -n "Pixel_4_API_30" -k "system-images;android-30;default;x86_64" -d "Pixel 4" -m 2048
```

**Check available disk space:**
```bash
df -h ~/Android/Sdk
# Need at least 5GB free
```

---

### Problem: Test Timeout

**Increase timeout:**
```bash
flutter test integration_test/ \
  --dart-define=FLUTTER_TEST_TIMEOUT=60000 \
  --verbose
```

**Run just one test:**
```bash
flutter test integration_test/performance/app_startup_test.dart --verbose
```

**Check emulator is running:**
```bash
flutter devices
# Should list emulator
```

---

### Problem: GitHub Actions Not Running

**Check if enabled:**
- GitHub → Settings → Actions → Check "Allow all actions"

**Check workflow syntax:**
```bash
# GitHub Actions workflow validation
gh workflow view phase4-ios-tests.yml
```

**Check recent runs:**
```bash
gh run list
```

**Manually trigger:**
```bash
gh workflow run phase4-ios-tests.yml -r main
```

---

### Problem: "adb" Command Not Found

**Add to PATH:**
```bash
export PATH=$PATH:~/Android/Sdk/platform-tools
```

**Or use full path:**
```bash
~/Android/Sdk/platform-tools/adb devices
```

**Check Android SDK location:**
```bash
which adb
echo $ANDROID_SDK_ROOT
```

---

### Problem: Permission Denied Errors

**Fix SDK permissions:**
```bash
chmod -R u+rwx ~/Android/
```

**Fix emulator permissions:**
```bash
chmod -R u+rwx ~/Android/Sdk/emulator/
```

---

### Problem: Performance Test Exceeds Baseline

**Investigate what changed:**
```bash
git diff HEAD~1  # Compare to previous commit
```

**Profile the slow operation:**
```bash
flutter run --profile  # Profile mode app
```

**Optimize code** → **Re-test**

**If baseline too strict:**
```bash
# Don't adjust baseline lightly!
# Document why in commit message if you must
```

---

## Performance Metrics Reference

### Baselines

| Metric | Target | Warning | Critical |
|--------|--------|---------|----------|
| App Startup | 2.0s | 2.2s | 2.4s |
| Navigation | 500ms | 550ms | 600ms |
| Search (small) | 100ms | 110ms | 120ms |
| Search (large) | 200ms | 220ms | 240ms |
| Memory | 150MB | 165MB | 180MB |

### What Metrics Mean

- **Target** — Normal, expected performance
- **Warning (Yellow)** — 10% above target, investigate
- **Critical (Red)** — 20% above target, must fix

---

## File Locations

### Tests

```
integration_test/
├── performance/
│   ├── app_startup_test.dart
│   ├── navigation_latency_test.dart
│   └── search_performance_test.dart
├── e2e/
│   ├── complete_user_journey_test.dart
│   └── session_persistence_test.dart
└── helpers/
    └── performance_test_helper.dart
```

### Workflows

```
.github/workflows/
├── phase4-ios-tests.yml       (iOS testing)
├── phase4-tests.yml            (Android testing)
└── test.yml                    (Existing)
```

### Documentation

```
Daily/2026-07-22/
├── INDEX.md                    (Navigation)
├── EXECUTIVE-SUMMARY.md        (For decision-makers)
├── QUICK-START.md              (Fast path)
├── OVERVIEW.md                 (Understanding)
├── SETUP-GUIDE.md              (Detailed setup)
├── USER-GUIDE.md               (Daily workflow)
├── REFERENCE.md                (This file)
├── ARCHITECTURE.md             (Design)
└── PERFORMANCE-BASELINES.md    (Metrics)
```

---

## One-Liners (Copy & Paste)

```bash
# Start fresh testing session
emulator -avd Pixel_4_API_30 & sleep 60 && flutter devices

# Run all tests
flutter test integration_test/ --verbose

# Run and save output
flutter test integration_test/ --verbose 2>&1 | tee test-results.txt

# Run with longer timeout
flutter test integration_test/ --dart-define=FLUTTER_TEST_TIMEOUT=60000 --verbose

# Quick commit and push
git add . && git commit -m "Feature: ..." && git push

# Stop emulator
adb emu kill

# Full setup (run once)
sdkmanager "system-images;android-30;default;x86_64" && \
avdmanager create avd -n "Pixel_4_API_30" -k "system-images;android-30;default;x86_64" -d "Pixel 4" && \
emulator -list-avds
```

---

## Help & Resources

### Quick Links

- **Tests Overview:** [[OVERVIEW]]
- **Setup Help:** [[SETUP-GUIDE]]
- **Daily Workflow:** [[USER-GUIDE]]
- **Architecture:** [[ARCHITECTURE]]

### External Resources

- Flutter Testing: https://flutter.dev/docs/testing
- GitHub Actions: https://docs.github.com/en/actions
- Android Emulator: https://developer.android.com/studio/run/emulator

### Getting Help

**If something fails:**
1. Check this reference document
2. Read the error message carefully
3. Check [[SETUP-GUIDE]] troubleshooting section
4. Ask in team channel with error message

**If you find a bug in tests:**
1. Note the test name and error
2. Check test code for issue
3. File issue or ask for help

---

## Keyboard Shortcuts

### In Terminal

```
Ctrl+C       Stop current process
Ctrl+Z       Suspend process
fg           Resume suspended process
↑/↓          Previous/next command
Ctrl+L       Clear screen
```

### In Emulator

```
Home         Android home button
Back         Android back button
Power        Lock/unlock
Volume+/-    Volume up/down
```

---

## Common Issues & Solutions

| Issue | Solution |
|-------|----------|
| "emulator not found" | Add Android SDK to PATH or use full path |
| "test timeout" | Increase timeout or run single test |
| "GitHub Actions not running" | Enable in Settings → Actions |
| "Permission denied" | Run `chmod -R u+rwx ~/Android/` |
| "Port already in use" | Kill existing emulator: `adb emu kill` |
| "Device offline" | Restart emulator or `adb kill-server` |

---

**Need more help?** See [[SETUP-GUIDE]] or [[USER-GUIDE]]

