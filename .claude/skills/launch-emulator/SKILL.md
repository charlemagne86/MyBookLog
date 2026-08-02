---
name: launch-emulator
description: Boot the Pixel_10 Android emulator and run the MyBookLog Flutter app on it. Use whenever asked to launch, run, start, or screenshot the MyBookLog app, or to verify a change works in the real app on Android.
---

## Instructions

This machine has two Android SDK installs. **Always use the SDK-bundled
tools, not the `apt` ones** — the `apt` install at `/usr/lib/android-sdk`
ships a stale device-definition database and fails to load the `Pixel_10`
AVD with `Error: Google pixel_10 no longer exists as a device`. The
SDK-bundled tools at `~/Android/Sdk` work correctly.

1. **Set up the environment** (every command in this skill needs this):
   ```bash
   SDK=/home/charlie/Android/Sdk
   export PATH="/home/charlie/Repositories/flutter/bin:$SDK/emulator:$SDK/platform-tools:$SDK/cmdline-tools/latest/bin:$PATH"
   export ANDROID_HOME=$SDK ANDROID_SDK_ROOT=$SDK
   ```

2. **Check if the emulator is already running** before booting another one:
   ```bash
   adb devices
   ```
   If `emulator-5554` (or any `emulator-*`) already shows as `device`, skip
   to step 4.

3. **Boot the AVD** in the background and wait for it to finish booting.
   Booting cold typically takes 60-120s.
   ```bash
   nohup emulator -avd Pixel_10 -no-snapshot-load -no-boot-anim \
     > /tmp/emulator.log 2>&1 &
   disown

   until adb wait-for-device shell \
     'while [[ -z $(getprop sys.boot_completed) ]]; do sleep 1; done;' \
     2>/dev/null; do sleep 2; done
   ```
   Use the Bash tool's `run_in_background: true` for the `nohup emulator`
   launch and a plain (foreground) Bash call with a generous timeout
   (150000ms+) for the `until adb wait-for-device ...` wait loop — don't
   poll it yourself.

4. **Run the app** from the Flutter project directory (note: the Flutter
   project is at `mybooklog/`, one level below the git repo root):
   ```bash
   cd /home/charlie/Repositories/MyBookLog/mybooklog
   nohup flutter run -d emulator-5554 > /tmp/flutter-run.log 2>&1 &
   disown
   ```
   Then poll `/tmp/flutter-run.log` for the "Flutter run key commands"
   banner (or an `Error:`/`Exception` line) before declaring success —
   don't assume launch succeeded just because the process started. This
   typically takes 20-40s after the emulator has booted.

5. **Drive it — screenshot to confirm it actually rendered**, don't just
   confirm the process is alive:
   ```bash
   adb exec-out screencap -p > /tmp/app-screenshot.png
   ```
   Then Read the PNG and look at it. A blank/black frame or an error
   dialog means the launch didn't really work even if `flutter run`
   printed the key-commands banner.

   To check the home-screen launcher icon instead of the in-app UI:
   ```bash
   adb shell input keyevent KEYCODE_HOME
   sleep 1
   adb exec-out screencap -p > /tmp/home-screen.png
   ```

## Useful facts about this app

- Android application ID: `com.example.mybooklog`
- To force-stop and relaunch cleanly: `adb shell am force-stop com.example.mybooklog`
- To hot-reload after a code change instead of a full relaunch, send `r`
  to the backgrounded `flutter run` process's stdin — since it's
  `nohup`'d to a log file, it's simpler to kill and rerun step 4, or use
  `flutter attach -d emulator-5554` if `flutter run` is still the
  foreground owner of the device.
- `flutter run` stays in the foreground of its own process forever
  (interactive key-command REPL) — always background it with
  `nohup ... & disown`, never run it as a blocking foreground call.

## Example

**User:** "Launch the app and confirm the bookshelf screen loads."
**Agent:** Runs steps 1-5 above, reads the resulting screenshot, and
reports what's actually visible on screen (e.g. "My Bookshelf" app bar,
book grid with N books) rather than just "flutter run exited 0".
