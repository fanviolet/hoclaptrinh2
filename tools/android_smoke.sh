#!/usr/bin/env bash
set -euo pipefail
package=com.highstackstudio.highstack3d
collect() {
  adb logcat -d > build/android-logcat.txt || true
  adb exec-out screencap -p > build/android-last-screen.png || true
  if [ "${1:-0}" != 0 ]; then
    tail -n 180 build/android-logcat.txt
  fi
}
trap 'collect $?' EXIT
adb install --no-incremental build/HighStack3D-v0.5.0.apk
adb shell settings put secure immersive_mode_confirmations confirmed
adb logcat -c
activity=$(adb shell cmd package resolve-activity --brief "$package" | tr -d '\r' | tail -n 1)
adb shell am start -W -n "$activity"
sleep 15
adb shell pidof "$package"
adb shell input tap 540 1740
sleep 12
adb shell pidof "$package"
collect 0
adb exec-out screencap -p > build/android-gameplay.png
# Capture Store, then Ranking and Ads.
adb shell input tap 105 410
sleep 3
adb exec-out screencap -p > build/android-store.png
adb shell input tap 540 1710
sleep 2
adb shell input tap 105 548
sleep 3
adb exec-out screencap -p > build/android-ranking.png
adb shell input tap 540 1710
sleep 2
adb shell input tap 105 880
sleep 15
adb exec-out screencap -p > build/android-ads.png
# Open only our opt-in rewarded button, never any advertiser destination.
adb shell input tap 540 545
sleep 15
adb exec-out screencap -p > build/android-ad-playing.png
adb logcat -d > build/android-logcat.txt
if grep -E 'FATAL EXCEPTION|SCRIPT ERROR|Parse Error|Fatal signal|E godot.*ERROR:' build/android-logcat.txt; then
  exit 1
fi
echo 'ANDROID_SMOKE: install, activity launch, drop input and process survival passed'
