#!/usr/bin/env bash
# Runs the on-device integration test on the already-booted emulator.
set -uo pipefail
SDK="${ANDROID_SDK_ROOT:-$ANDROID_HOME}"
DEVICE="$("$SDK/platform-tools/adb" devices | awk 'NR>1 && $2=="device" {print $1; exit}')"
echo "device=$DEVICE"
if [ -z "$DEVICE" ]; then
  echo "No booted Android device found" > e2e.txt
  python3 .github/scripts/annotate_output.py e2e.txt
  exit 1
fi
rc=0
timeout 1500 flutter test integration_test/app_test.dart -d "$DEVICE" > e2e.txt 2>&1 || rc=$?
echo "flutter test exit code: $rc" | tee -a e2e.txt
cat e2e.txt
python3 .github/scripts/annotate_output.py e2e.txt 60
if [ "$rc" -ne 0 ]; then echo "E2E failed with exit code $rc"; exit "$rc"; fi
if grep -q "Some tests failed\|tests passed, [1-9][0-9]* failed\|BUILD FAILED" e2e.txt; then echo "E2E output reports failure"; exit 1; fi
if ! grep -q "All tests passed" e2e.txt; then echo "E2E did not report 'All tests passed'"; exit 1; fi
echo "E2E passed"
