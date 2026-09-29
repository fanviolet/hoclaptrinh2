#!/usr/bin/env bash
set -euo pipefail
package=com.highstackstudio.highstack3d
# Half-resolution emulator keeps software GPU load below system ANR limits.
tap() { adb shell input tap "$(( $1 / 2 ))" "$(( $2 / 2 ))"; }
collect() {
  adb logcat -d > build/android-ads-qa-logcat.txt || true
  adb exec-out screencap -p > build/android-ads-qa-last.png || true
}
trap collect EXIT
wait_log() {
  for attempt in $(seq 1 40); do
    adb logcat -d > build/android-ads-qa-progress.txt
    if grep -q "$1" build/android-ads-qa-progress.txt; then return 0; fi
    sleep 3
  done
  echo "Missing QA signal: $1"
  return 1
}
# Production APK was tested separately. Only Google's demo inventory is shown here.
adb uninstall "$package"
adb install --no-incremental build/HighStack3D-AdsQA.apk
adb logcat -c
activity=$(adb shell cmd package resolve-activity --brief "$package" | tr -d '\r' | tail -n 1)
adb shell am start -W -n "$activity"
wait_log 'HIGHSTACK_APP_OPEN: loaded'
wait_log 'HIGHSTACK_ADS: rewarded ad loaded'
adb shell input keyevent KEYCODE_HOME
sleep 35
adb shell am start -W -n "$activity"
wait_log 'HIGHSTACK_APP_OPEN: show at foreground entry'
# Allow the demo creative to finish rendering on the software-GPU emulator.
sleep 30
adb exec-out screencap -p > build/android-app-open-qa.png
# Google's App Open demo uses the observed top-right Continue to app control.
# Android Back is not its dismissal control. Never tap the install/creative area.
tap 1030 44
wait_log 'HIGHSTACK_APP_OPEN: closed'
sleep 3
tap 105 880
sleep 4
adb exec-out screencap -p > build/android-reward-menu-qa.png
tap 540 575
wait_log 'rewarded video ad showed full screen content'
sleep 12
adb exec-out screencap -p > build/android-rewarded-qa.png
collect
! grep -E 'FATAL EXCEPTION|SCRIPT ERROR|Parse Error|Fatal signal|E godot.*ERROR:' build/android-ads-qa-logcat.txt
echo 'ANDROID_ADS_QA: demo App Open loaded/shown/dismissed; demo Rewarded loaded/shown'
