# Phase 4: Quick Start (10 minutes)

**Just want to get running? Follow this.**

---

## The Setup (20 minutes, one-time)

### Step 1: Create Android Emulator (15 min)

Paste these commands into your terminal:

```bash
sdkmanager "system-images;android-30;default;x86_64"
avdmanager create avd -n "Pixel_4_API_30" -k "system-images;android-30;default;x86_64" -d "Pixel 4"
emulator -list-avds
```

The last command should output: `Pixel_4_API_30`

### Step 2: Activate GitHub Actions (5 min)

```bash
cd /home/charlie/Repositories/MyBookLog/mybooklog
git push
```

That's it. GitHub Actions is now active.

---

## Verify It Works (5 min)

### Test Local (Android)

```bash
# Start emulator
emulator -avd Pixel_4_API_30 &

# Wait for boot
sleep 120

# Run one test
flutter test integration_test/performance/app_startup_test.dart --verbose

# Expected: ✅ Test passes
```

### Test GitHub (iOS)

1. Go to: https://github.com/YOUR_USERNAME/MyBookLog
2. Click: **Actions** tab
3. Look for: **Phase 4 Tests - iOS**
4. Expected: ✅ All tests passing

---

## Your Daily Workflow

```bash
# 1. Make code changes
vim lib/...

# 2. Test locally (Android)
emulator -avd Pixel_4_API_30 &
flutter test integration_test/ --verbose

# 3. Push to GitHub (if tests pass)
git push

# 4. GitHub tests iOS automatically (check Actions tab)
```

---

## Common Commands

```bash
# Start emulator
emulator -avd Pixel_4_API_30 &

# Run all Phase 4 tests (local)
flutter test integration_test/ --verbose

# Run just performance tests
flutter test integration_test/performance/ --verbose

# Run just E2E tests
flutter test integration_test/e2e/ --verbose

# Run specific test
flutter test integration_test/performance/app_startup_test.dart --verbose

# Push to GitHub (iOS tests automatically)
git push

# Stop emulator
adb emu kill
```

---

## Troubleshooting

### "emulator command not found"
```bash
# Add to your PATH or use full path
~/Android/Sdk/emulator/emulator -avd Pixel_4_API_30 &
```

### "Test times out"
```bash
flutter test integration_test/ \
  --dart-define=FLUTTER_TEST_TIMEOUT=60000 \
  --verbose
```

### "GitHub Actions not running"
- Ensure you have push permissions
- Check GitHub Settings → Actions (should be enabled)

### "Need more help?"
→ See [[REFERENCE]] (troubleshooting section)

---

## What You Just Set Up

✅ **Local testing** — Android Emulator on your Linux machine  
✅ **CI/CD testing** — iOS Simulator on GitHub (automatic)  
✅ **29 tests** — Performance + E2E tests  
✅ **Hybrid strategy** — Both platforms covered  
✅ **Zero cost** — Everything is free  

---

## Next Steps

**Immediate:**
- Run the 3 commands above
- Verify both Android and GitHub work

**After Setup:**
- Use commands above for daily development
- iOS tests run automatically on every push
- Check GitHub Actions for results

**Need Details?**
- [[OVERVIEW]] — Understand what was built
- [[SETUP-GUIDE]] — Full setup explanation
- [[USER-GUIDE]] — Complete workflow guide
- [[REFERENCE]] — Commands & troubleshooting

---

## Expected Results

**When tests pass:**
```
✅ Phase 4 Performance Tests (16/16)
✅ Phase 4 E2E Tests (13/13)
✅ Coverage: 85%+
✅ All baselines met
```

---

**Done! You're ready to test. 🚀**

