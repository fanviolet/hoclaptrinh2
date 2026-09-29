#!/usr/bin/env bash
set -euo pipefail
package=com.highstackstudio.highstack3d
# Half-resolution emulator keeps software GPU load below system ANR limits.
tap() { adb shell input tap "$(( $1 / 2 ))" "$(( $2 / 2 ))"; }
collect() {
  adb logcat -d > build/android-logcat.txt || true
  adb exec-out screencap -p > build/android-last-screen.png || true
  if [ "${1:-0}" != 0 ]; then
    tail -n 180 build/android-logcat.txt
  fi
}
trap 'collect $?' EXIT
adb shell wm size 540x960
adb shell wm density 160
sleep 20
adb install --no-incremental build/HighStack3D-v0.6.0.apk
adb shell settings put secure immersive_mode_confirmations confirmed
adb logcat -c
activity=$(adb shell cmd package resolve-activity --brief "$package" | tr -d '\r' | tail -n 1)
adb shell am start -W -n "$activity"
sleep 30
adb shell pidof "$package"
adb exec-out screencap -p > build/android-lobby.png
# First tap begins a round; the next drops the first block.
tap 540 1740
sleep 2
tap 540 1740
sleep 12
adb shell pidof "$package"
collect 0
adb exec-out screencap -p > build/android-gameplay.png
# Capture Store, then Ranking and Ads.
tap 105 410
sleep 3
adb exec-out screencap -p > build/android-store.png
tap 540 1710
sleep 2
tap 105 548
sleep 3
adb exec-out screencap -p > build/android-ranking.png
tap 540 1710
sleep 2
tap 105 880
sleep 15
adb exec-out screencap -p > build/android-ads.png
# Return through Settings to verify the reset route in the real APK.
adb shell input keyevent KEYCODE_BACK
sleep 5
tap 975 410
sleep 5
tap 540 365
sleep 5
adb exec-out screencap -p > build/android-reset-lobby.png
adb logcat -d > build/android-logcat.txt
grep -q 'HIGHSTACK_ADS: publisher rewarded unit configured' build/android-logcat.txt
grep -q 'HIGHSTACK_PRIVACY:' build/android-logcat.txt
grep -q 'HIGHSTACK_ADS: App Open unit=' build/android-logcat.txt
test "$(grep -c 'HIGHSTACK_RUN: lobby' build/android-logcat.txt)" -ge 2
grep -q 'HIGHSTACK_RUN: running' build/android-logcat.txt
if grep -E 'FATAL EXCEPTION|SCRIPT ERROR|Parse Error|Fatal signal|E godot.*ERROR:' build/android-logcat.txt; then
  exit 1
fi
echo 'ANDROID_SMOKE: install, activity launch, drop input and process survival passed'
