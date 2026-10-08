# Testing

## Commands

```bash
flutter pub get
flutter analyze --fatal-warnings
flutter test test/ --coverage --reporter expanded
node --test test/js/bridge_sdk.test.mjs
flutter test integration_test/app_test.dart -d <android-device-id>   # emulator/device only
```

CI runs the first three on every push and pull request, plus an Android debug
and release build, and the on-device test on an Android emulator. See
`.github/workflows/ci.yml`.

## What is covered

| Area | File(s) | What it checks |
| --- | --- | --- |
| Protocol | `test/unit/protocol_test.dart` | identifiers, request/batch validation, error codes, error JSON without stack traces |
| Navigation | `test/unit/navigation_policy_test.dart` | allow-list, scheme filter (SEC-001), sub-frames |
| Sandbox paths | `test/unit/storage_path_test.dart` | syntax rules (SEC-002), symlink containment |
| Guards, cache, rate limit, permissions | `test/unit/security_units_test.dart` | sliding window, bounded keys (SEC-008), LRU (PERF-001), TTL (SEC-005), guard timeouts and duplicate ids |
| Bridge | `test/unit/message_bridge_test.dart` | token checks (SEC-004), size limit, stale-session responses (SM-006), bounded queue (BUG-003), event encoding (BUG-004) |
| Engine | `test/unit/plugin_manager_test.dart` | pipeline order, error contract (SEC-003), capabilities (CONC-001, streaming, batch), cache invalidation (BUG-001, SM-003), batch timeouts (BUG-002), stats (STAT-001), traces, registry |
| Storage security | `test/security/storage_security_test.dart` | traversal, symlink escape, size limits, end-to-end through the engine |
| Injected SDK | `test/js/bridge_sdk.test.mjs` | the shipped SDK template run in a Node VM: install rules, iframe refusal, token in every message, call/batch resolution and errors, timeouts, events, listener isolation |
| Device | `integration_test/app_test.dart` | app boot, WebView host present, storage round-trip and traversal rejection on Android |

**Status:** the device test is **failing in CI** on the last run. The app boots
and the first test passes on the emulator, but the `flutter test` process stops
before it reports a summary. See the final status in
`docs/AUDIT_EXECUTION_PLAN.md` section 16.

Each regression test is labelled `regression:` in its name and refers to the
finding it protects (BUG-, SEC-, SM-, PERF-, CONC-, STAT-).

## What is not covered yet

- A device test that drives the page's JavaScript through the real WebView
  bridge. The on-device test calls the engine directly. The JavaScript path is
  covered by the Node VM tests and the bridge unit tests.
- Camera and geolocation on real devices (they need hardware and permissions).
  The camera plugin and the geolocation watch are not unit-tested against their
  native APIs; validation logic is tested.
- iOS builds (IOS-001).
- A coverage threshold gate. Coverage is produced and uploaded as an artifact.
- Formatting checks (`dart format`) in CI.

## Adding a test

- Put Dart unit tests next to the area they cover in `test/unit/`, or in
  `test/security/` when the test is about an attacker-controlled input.
- Use `test/helpers/fakes.dart` for plugins, permission providers, clocks and
  the script recorder.
- For a bug fix, add a test whose name starts with `regression:` and names the
  finding ID.
