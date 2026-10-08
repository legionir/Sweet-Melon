# Worklog

Permanent journal of the Sweet-Melon audit, hardening, test and CI work.
Every significant iteration records: timestamp, phase, finding, decision, files
changed, tests executed and result.

---

## 2026-10-08

### Phase
Repository Audit (baseline)

### Environment / Baseline
- Branch: `arena/a3bec261-sweet-melon` (from `main` @ `feca87b`).
- Git status before changes: clean working tree.
- Remotes: `origin` = https://github.com/legionir/Sweet-Melon.git.
- Repository type: Flutter application (single root package `sweetmelon`) with
  in-tree "packages" under `lib/packages/*` and `lib/plugins/*`.
- Tracked files: 108. No `.gitignore`, no `test/` directory, no `.github/`
  directory, no CI workflow, no `pubspec.lock`.
- Build status: **not runnable in the audit sandbox** — no Flutter/Dart SDK is
  installed and `pub.dev` / `storage.googleapis.com` are not reachable from the
  sandbox (allowed hosts: github.com, registry.npmjs.org, pypi.org). Verification
  therefore runs on GitHub Actions (see `.github/workflows/ci.yml`).
- Test status: **0 tests** existed.
- Lint / static analysis status: never executed in the repository (no CI).
- Dependency status: `http` declared but unused; `uuid` only used by dead
  factories; `image_picker`, `geolocator`, `webview_flutter` in use.
- Existing CI status: none.
- TODO/FIXME/HACK/XXX: only two `TODO` comments, both in
  `android/app/build.gradle.kts` (application id and release signing).

### Findings (summary; full list in `docs/AUDIT_EXECUTION_PLAN.md`)
- Trust boundary: `flutterBridge` JavaScript channel is exposed to every frame;
  no session token; navigation is unrestricted when `allowedHosts` is empty.
- Storage: `listFiles` skips `..` validation and symlinks are not contained.
- Cache: write operations (`set`, `remove`, `writeFile`, …) are cacheable and
  never invalidate the cache.
- Bridge: batch failures never resolve the JS promise; `_isReady` survives page
  reloads; unbounded pending-script queue.
- Stats: `errorCount` is never incremented.
- Capabilities `supportsStreaming`, `supportsCache`, `maxConcurrentCalls` are
  metadata only.
- Permissions: camera/storage/location always granted by `StaticPermissionProvider`.
- Geolocation `watchPosition` discards every position update.
- Android: release signed with debug key; duplicate unused `MainActivity`;
  manifest lacks CAMERA/LOCATION permissions; iOS lacks usage descriptions.
- No `.gitignore`, no tests, no CI, empty README.

### Decision
Work item order follows the plan: P0 security/data-integrity first, then P1
bridge/plugin correctness, then tests, CI, documentation. Dart code is verified
through CI; every Dart change is covered by tests in `test/`.

### Files
- docs/AUDIT_EXECUTION_PLAN.md (created)
- docs/WORKLOG.md (created)

### Tests
- None executed yet (baseline).

### Result
BASELINE RECORDED

---

## 2026-10-08 — Implementation pass 1 (engine, security, plugins, tests, CI, docs)

### Verification environment
- The Flutter and Dart SDKs are not installed here and cannot be downloaded
  (only GitHub, npm, PyPI are reachable). Dart code is therefore **not compiled
  locally**. Compilation, analysis and tests run in GitHub Actions. Node is
  available locally and was used for the JS SDK test design.

### Decisions (recorded instead of asking)
- Removed `FileSink`/`MemorySink`: the file sink never wrote anything; a
  documented console sink is the only sink. (ARCH-003)
- Removed the event emitter from `PluginRegistry`'s public API in favour of an
  emitter passed at construction; plugins emit through `Plugin.emit`. (BUG-005)
- Renamed the navigation verdict type to `NavigationVerdict`: `webview_flutter`
  exports a `NavigationDecision` enum and the names would clash.
- `ValidationResult` is the single validation type; the error code is set by
  the manager from `PluginErrorCode` (ARCH-006).
- Permission TTL 5 s (plan). Heap 4 GiB (plan).
- Release signing: `SWEETMELON_KEYSTORE_*` environment variables; no keystore
  means an unsigned release. R8 minification was considered and not enabled,
  to avoid release-only breakage without a device to verify on.
- `RECORD_AUDIO` was considered for Android and not added: the picker is an
  intent and does not need it. iOS keeps the microphone usage string because
  video capture on iOS needs it.

### Identity check: MainActivity (ARCH-002 / ARCH-005)
- `android/app/build.gradle.kts` sets `namespace = "com.example.sweet_melon"`,
  and the manifest uses `.MainActivity`.
- The file deleted under `com/example/sweetmelon/` declared
  `package com.example.sweetmelon`, which does not match the namespace. It was
  the wrong one.
- The file kept, `com/example/sweet_melon/MainActivity.kt`, matches the manifest.
- Deletion confirmed correct.

### Changes
- `pubspec.yaml`: removed `http`, `uuid`; added `permission_handler`,
  `integration_test` (dev). Nested per-package pubspecs removed (ARCH-001).
- Protocol: strict validation, identifiers without backslash (regex bug fixed:
  `\\-` inside the class had let a backslash through — regression test added).
- Bridge: sessions, token, size limit, bounded queue, stale-response drop,
  batch envelope handling, double-encoded events. (SEC-004, BUG-002/003/004)
- WebView host: navigation policy, top-frame SDK, session start/end on page
  start/finish, detach on dispose. (SEC-001, BUG-011)
- Engine: pipeline with capability enforcement, concurrency limit, permission
  status in details, cache read-only + invalidation, error contract, stats and
  traces on every failure path, batch timeout that settles every item.
  (SEC-003, SM-002..005, SM-010, CONC-001, PERM-001, STAT-001, BUG-001/002/007)
- Security: sliding-window rate limiter with bounded keys (BUG-012, SEC-008);
  execution guard with timeouts, duplicate ids, cancel-all (CONC-002);
  permission manager with OS provider and TTL (SEC-005).
- Cache: O(1) LRU, JSON copies, no eviction on overwrite (PERF-001).
- Storage: sandbox path validation, symlink containment, size limits, cache
  only for read methods (SEC-002, SEC-009, BUG-001).
- Camera: `CANCELLED` on user cancel, single concurrent call, validation
  (BUG-006/008, CONC-001). Camera validation is not unit-tested yet.
- Geolocation: watch streams with `watchId`, events, max 4 watches, cleanup,
  `timeoutMs` (BUG-005, BUG-013, SM-009, SM-011).
- Devtools: bounded queue (PERF-002), payload redaction (SEC-007), no
  `removeAt(0)`, precomputed search text, debug-only UI (SEC-007).
- DI: rewired for the new constructors; `ServiceLocator.dispose` order fixed.
- Android: CAMERA, location permissions; release signing from env (SEC-006,
  BUG-010); heap 4 GiB (PERF-002).
- iOS: usage strings; removed the leftover "Hello World" display name (BUG-010,
  DOC-003).

### Tests written (not yet executed)
- `test/unit/protocol_test.dart`, `navigation_policy_test.dart`,
  `storage_path_test.dart`, `security_units_test.dart`,
  `message_bridge_test.dart`, `plugin_manager_test.dart`
- `test/security/storage_security_test.dart`
- `test/js/bridge_sdk.test.mjs` (Node VM over the shipped Dart template).
  **Executed locally with Node 22: 16/16 pass.** One test initially encoded the
  payload twice; it was corrected to match `MessageBridge.emitEvent` (the SDK
  receives JSON text). The SDK itself was not changed for that.
- `integration_test/app_test.dart` (emulator)
- Helpers: `test/helpers/fakes.dart`

### CI
- `.github/workflows/ci.yml`: analyze + unit/security tests with coverage, Node
  SDK tests, Android debug + release builds, Android emulator run of the
  integration test.

### Docs
- README, docs/ARCHITECTURE.md, docs/SECURITY.md, docs/TESTING.md written.
- Plan updated: statuses `[~]` for implemented work awaiting CI; SM-001..012
  mapping and deviations added (sections 5a and 5b).

### Status
- Implementation: written. Verification: **pending CI**. No item may be marked
  `[x]` until the pushed commit's workflow runs green.

### CI verification log (GitHub Actions, branch arena/a3bec261-sweet-melon)

The Flutter SDK is not available in the sandbox, so every Dart and Android
result below comes from CI. Job logs cannot be downloaded from the sandbox
(the log storage host is unreachable), so diagnostics were moved into
check-run annotations by `.github/scripts/annotate_output.py`.

Failures found and fixed, in order:
1. `ci.yml` did not parse: an unquoted step name contained `:`. Quoted.
2. Analyzer: missing `dart:async` (Completer), missing `CacheManager` import in
   `test/helpers/fakes.dart`, missing `package:flutter/foundation.dart` for
   `kDebugMode` in `home_screen.dart`. Fixed.
3. Steps were using `cmd; rc=$?`. GitHub runs `bash -e`, so the script stopped
   before the diagnostic step. Changed to `cmd || rc=$?`.
4. Android: Flutter's current minimums are Gradle 8.14, AGP 8.11.1 and Kotlin
   2.2.20. The repo pinned Gradle 8.10.2, AGP 8.7.0 and Kotlin 1.8.22. Bumped to
   the minimums; this is a toolchain requirement, not a preference.
5. E2E step: the first failure was the same Gradle error, but the step still
   reported success. Added explicit checks for failure text and for
   `All tests passed`.

Result at this point (commit history on the branch):
- JavaScript SDK tests: pass (16/16 locally with Node 22, and in CI).
- analyze (`--fatal-warnings`) and unit/security/regression tests: pass in CI.
- Android debug and release build: pass in CI.
- Android emulator integration test: see the latest run; the step is gated on
  an explicit `All tests passed` line.

### Final CI status for this session (latest run on the branch)

| Job | Result | Evidence |
| --- | --- | --- |
| Injected JavaScript SDK (Node VM) | PASS | 16/16 tests |
| Analyze, unit, security and regression tests | PASS | `flutter analyze --fatal-warnings`; `flutter test test/` |
| Android build (debug and release) | PASS | debug APK and unsigned release APK built |
| Android end-to-end (emulator) | FAIL | app boots; first test passes; `flutter test` stops before the summary |

Overall: **NOT COMPLETE**. Open items:
- E2E on the emulator (TEST-003, CI-001, 8.11, 8.12). Diagnosis so far is in
  the plan's section 16. Not reproduced locally.
- Coverage gate script (TEST-002).
- Formatter check (`dart format`) is not in CI.
- BUG-005 (geolocation event path), BUG-009 (camera validation), BUG-011
  (dispose path), SEC-007 (inspector redaction): implemented, no automated test.
- BUG-010 iOS: usage strings present, iOS not built (IOS-001 blocked: no
  Podfile, no macOS host).
- Plan statuses: 44 `[x]`, 17 `[~]`, 1 `[ ]` (the legend line).

Rejected or corrected during this pass:
- A manual emulator start (own step) was tried: the system image download was
  too slow in the sandbox runner (the sdkmanager timeout hit at ~60%). Reverted to
  android-emulator-runner.
- Gradle wrapper, AGP, and Kotlin were raised to Flutter's minimums (Gradle 8.14,
  AGP 8.11.1, Kotlin 2.2.20). Not a preference; the build fails otherwise.
- A test that double-encoded the SDK payload was corrected to match the native
  side. The SDK was not changed for that.
