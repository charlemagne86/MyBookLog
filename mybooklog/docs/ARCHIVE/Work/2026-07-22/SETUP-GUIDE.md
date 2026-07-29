# Phase 4: Complete Setup Guide

**Detailed step-by-step setup with explanations.**

---

## Overview

Setup takes **20-25 minutes** and requires:
1. Creating Android Emulator (15 min)
2. Activating GitHub Actions (5 min)
3. Verifying everything works (5 min)

This is a **one-time setup**. You'll never need to do it again.

---

## Part 1: Android Emulator Setup (15 minutes)

### Why Android Emulator?

The Android Emulator allows you to:
- Test locally on your Linux machine
- Get instant feedback (5 minutes per test run)
- Debug failures in real-time
- Control which tests to run

### Prerequisites Check

Make sure Flutter is installed:

```bash
flutter doctor
```

Should show:
```
[✓] Flutter (Channel stable, 3.x.x)
[✓] Android toolchain
[✓] Linux toolchain
```

If issues, see troubleshooting below.

### Step 1: Accept Android Licenses (1 min)

```bash
flutter doctor --android-licenses
# Press 'y' for all licenses
```

### Step 2: Download System Image (2-3 min, ~1GB)

```bash
sdkmanager "system-images;android-30;default;x86_64"
```

This downloads Android 30 system image. It's large (~1GB) but only happens once.

### Step 3: Create Virtual Device (1 min)

```bash
avdmanager create avd \
  -n "Pixel_4_API_30" \
  -k "system-images;android-30;default;x86_64" \
  -d "Pixel 4"
```

The command creates a virtual Android device named "Pixel_4_API_30".

Answer prompts with defaults (press Enter for each).

### Step 4: Verify Creation (30 sec)

```bash
emulator -list-avds
```

Should output:
```
Pixel_4_API_30
```

If not listed, go back and check Step 3.

### Step 5: Test Launch (2 min, optional)

To verify it boots:

```bash
emulator -avd Pixel_4_API_30 &
sleep 120  # Wait 2 minutes for boot
adb devices  # Should show emulator
kill %1  # Stop it
```

---

## Part 2: Activate GitHub Actions (5 minutes)

GitHub Actions is already configured. You just need to push the workflows.

### What's GitHub Actions?

GitHub Actions runs tests automatically on their servers:
- Runs on macOS (has iOS Simulator)
- Tests iOS platform
- Triggered by every push
- Free (included in GitHub free tier)

### Step 1: Navigate to Your Repository

```bash
cd /home/charlie/Repositories/MyBookLog/mybooklog
```

### Step 2: Verify Workflows Are Present

```bash
ls -la .github/workflows/
```

Should show:
```
phase4-ios-tests.yml
phase4-tests.yml
test.yml
```

### Step 3: Push to GitHub

```bash
git push
```

This activates the workflows. GitHub now knows about them.

### Step 4: Verify Workflows Started (1-2 min)

1. Go to: https://github.com/YOUR_USERNAME/MyBookLog
2. Click: **Actions** tab
3. Look for: **Phase 4 Tests - iOS** running
4. Should show: Yellow dot (running) or green checkmark (passed)

If you don't see it, workflows may be disabled in Settings → Actions.

---

## Part 3: Verify Everything Works (5 minutes)

### Test 1: Local Android Testing (3 min)

**Start Emulator:**
```bash
emulator -avd Pixel_4_API_30 &
sleep 60  # Wait for boot
```

**Run One Test:**
```bash
cd /home/charlie/Repositories/MyBookLog/mybooklog
flutter test integration_test/performance/app_startup_test.dart --verbose
```

**Expected Output:**
```
✓ app_startup_time_cold_launch: 1850ms (< 2000ms) ✅

════════════════════════════════════════════════════════════
✓ 1 test passed (8 seconds)
════════════════════════════════════════════════════════════
```

If you see ✓, emulator is working!

### Test 2: GitHub Actions iOS Testing (2 min)

1. Go to: GitHub Actions tab (https://github.com/YOUR_USERNAME/MyBookLog/actions)
2. Click: **Phase 4 Tests - iOS**
3. Watch for: Yellow dot (running) → Green checkmark (passed)
4. If passed: iOS testing is working!

---

## Troubleshooting

### "sdkmanager command not found"

**Cause:** Flutter/Android SDK not properly installed

**Solution:**
```bash
flutter doctor  # Check for errors

# If issues, reinstall Flutter:
# See: https://flutter.dev/docs/get-started/install

# Or manually accept licenses:
flutter doctor --android-licenses
```

### "avdmanager command not found"

**Cause:** Same as above

**Solution:** Same as above - ensure Flutter is fully installed

### "Can't create emulator (permission denied)"

**Cause:** Permissions issue in Android SDK directory

**Solution:**
```bash
# Give yourself permissions
chmod -R u+rwx ~/Android/

# Then retry:
avdmanager create avd -n "Pixel_4_API_30" ...
```

### "Emulator won't start"

**Cause:** System image not installed or corrupt

**Solution:**
```bash
# Check if installed:
sdkmanager --list | grep "system-images;android-30"

# If not found, reinstall:
sdkmanager "system-images;android-30;default;x86_64"

# Or create with more memory:
avdmanager create avd \
  -n "Pixel_4_API_30" \
  -k "system-images;android-30;default;x86_64" \
  -d "Pixel 4" \
  -m 2048  # 2GB RAM
```

### "Test times out"

**Cause:** Test is too slow or emulator is slow

**Solution:**
```bash
# Increase timeout:
flutter test integration_test/ \
  --dart-define=FLUTTER_TEST_TIMEOUT=60000 \
  --verbose
```

### "GitHub Actions not running"

**Cause 1:** Workflows are disabled

**Solution:**
1. Go to: GitHub → Settings → Actions
2. Select: "Allow all actions"

**Cause 2:** No push permissions

**Solution:** Ensure you're signed in and have push access to the repo

### "Can't find 'adb' command"

**Cause:** Android SDK tools not in PATH

**Solution:**
```bash
# Use full path:
~/Android/Sdk/platform-tools/adb devices
```

---

## What You've Set Up

After completing all steps:

✅ **Android Emulator**
- Name: Pixel_4_API_30
- Located: ~/Android/Sdk/avd/
- Used for: Local testing

✅ **GitHub Actions Workflows**
- iOS testing: Automatic on push
- Location: .github/workflows/
- Used for: CI/CD

✅ **Hybrid Testing**
- Local: Android (5 min per test)
- Cloud: iOS (10 min per run)
- Combined: 15 min per iteration

---

## Next Steps

### Immediately After Setup

1. Keep the emulator running
2. Run all Phase 4 tests locally:
   ```bash
   flutter test integration_test/ --verbose
   ```

3. Expected: All 29 tests pass
4. Time: 5-10 minutes

### Going Forward

**Daily Workflow:**
```bash
# Start emulator once per day
emulator -avd Pixel_4_API_30 &

# During development, test locally:
flutter test integration_test/ --verbose

# When ready, push:
git push

# GitHub tests iOS automatically
```

**Check Results:**
- GitHub Actions tab shows iOS test results
- Takes 10-15 minutes per run

---

## Quick Reference

### Common Commands

```bash
# Start emulator
emulator -avd Pixel_4_API_30 &

# List devices
flutter devices

# Run all Phase 4 tests
flutter test integration_test/ --verbose

# Run performance tests only
flutter test integration_test/performance/ --verbose

# Run E2E tests only
flutter test integration_test/e2e/ --verbose

# Run specific test
flutter test integration_test/performance/app_startup_test.dart --verbose

# Stop emulator
adb emu kill

# Show emulator list
emulator -list-avds
```

---

## Summary

**Setup:** 25 minutes (one-time)
- Android Emulator: 15 min
- GitHub Actions: 5 min
- Verification: 5 min

**Ongoing:** 15 minutes per iteration
- Local test: 5 min
- Push: 1 min
- GitHub test: 10 min

**Cost:** $0

---

**Next:** [[USER-GUIDE]] (understand daily workflow) or [[REFERENCE]] (commands & troubleshooting)

