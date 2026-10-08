#!/usr/bin/env bash
# Creates and boots an x86_64 Android emulator without the emulator-runner
# action's script wrapper. The emulator keeps running in the background for
# later steps.
set -euo pipefail
SDK="${ANDROID_SDK_ROOT:-${ANDROID_HOME:?no Android SDK}}"
CMDLINE="$(ls -d "$SDK"/cmdline-tools/*/bin 2>/dev/null | head -1 || true)"
if [ -z "$CMDLINE" ]; then
  echo "cmdline-tools not found under $SDK" >&2
  exit 1
fi
IMAGE="system-images;android-33;google_apis;x86_64"
yes | "$CMDLINE/sdkmanager" --licenses > /dev/null 2>&1 || true
"$CMDLINE/sdkmanager" "$IMAGE" "emulator" "platform-tools" > sdk-emulator.txt 2>&1 || {
  tail -40 sdk-emulator.txt; exit 1; }
echo no | "$CMDLINE/avdmanager" create avd -n ci -k "$IMAGE" -d pixel --force > avd.txt 2>&1 || {
  tail -40 avd.txt; exit 1; }
nohup "$SDK/emulator/emulator" -avd ci -no-window -no-audio -no-boot-anim \
  -no-snapshot -gpu swiftshader_indirect -memory 2048 > emulator.log 2>&1 &
echo "emulator pid $!"
"$SDK/platform-tools/adb" wait-for-device
for _ in $(seq 1 120); do
  if [ "$("$SDK/platform-tools/adb" shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')" = "1" ]; then
    echo "boot completed"
    "$SDK/platform-tools/adb" devices
    exit 0
  fi
  sleep 5
done
echo "emulator did not finish booting" >&2
tail -60 emulator.log
exit 1
