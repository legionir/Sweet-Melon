#!/usr/bin/env bash
# Runs the on-device integration test on the already-booted emulator.
#
# The test runs in its own session (setsid) and writes its exit code to a file,
# so the result is recorded even if the parent shell is terminated. A process
# sampler writes the top consumers every 15 s to e2e-proc.log.
set -uo pipefail
SDK="${ANDROID_SDK_ROOT:-$ANDROID_HOME}"
ADB="$SDK/platform-tools/adb"
DEVICE="$("$ADB" devices | awk 'NR>1 && $2=="device" {print $1; exit}')"
echo "device=$DEVICE"
if [ -z "$DEVICE" ]; then
  echo "No booted Android device found" > e2e.txt
  python3 .github/scripts/annotate_output.py e2e.txt
  exit 1
fi

rm -f e2e.rc
( while sleep 15; do
    echo "== $(date +%T) $(free -m | sed -n 2p)"
    ps -eo pid,ppid,pcpu,rss,etime,args --sort=-rss | head -6 | cut -c1-160
  done ) > e2e-proc.log 2>&1 &
SAMPLER=$!

setsid bash -c 'flutter test integration_test/app_test.dart -d "$1" > e2e.txt 2>&1 < /dev/null; echo $? > e2e.rc' _ "$DEVICE" &

# Wait up to 30 minutes for the test session to finish.
for _ in $(seq 1 180); do
  [ -f e2e.rc ] && break
  sleep 10
done
kill "$SAMPLER" 2>/dev/null || true

rc="$(cat e2e.rc 2>/dev/null || echo missing)"
echo "flutter test exit code: $rc" | tee -a e2e.txt
python3 .github/scripts/annotate_output.py e2e.txt 60
if [ "$rc" != "0" ]; then echo "E2E failed (exit code $rc)"; exit 1; fi
if grep -q "Some tests failed\|tests passed, [1-9][0-9]* failed\|BUILD FAILED\|Failing tests" e2e.txt; then
  echo "E2E output reports failure"; exit 1
fi
# Each test prints one E2E_OK marker when its last expectation has run.
markers="$(grep -c "E2E_OK:" e2e.txt || true)"
echo "E2E_OK markers: $markers (expected 2)"
if [ "$markers" -ne 2 ]; then echo "E2E markers missing"; exit 1; fi
echo "E2E passed"
