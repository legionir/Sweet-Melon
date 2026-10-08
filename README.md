# Sweet-Melon

A Flutter app that hosts a WebView and gives the web page a small, validated
bridge to native plugins (camera, storage, geolocation). The JavaScript side
calls `window.Native.call({...})`; the Dart side checks permissions, rate
limits, validates arguments, runs the plugin with a timeout and returns a
structured response.

- Architecture: [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)
- Security model and known limitations: [docs/SECURITY.md](docs/SECURITY.md)
- Tests and how to run them: [docs/TESTING.md](docs/TESTING.md)
- Audit findings and status: [docs/AUDIT_EXECUTION_PLAN.md](docs/AUDIT_EXECUTION_PLAN.md)
- Change journal: [docs/WORKLOG.md](docs/WORKLOG.md)

## Requirements

- Flutter stable (3.27 or newer; the code uses `Color.withValues`)
- Dart SDK `^3.0.0` (bundled with Flutter)
- Android SDK for Android builds; Xcode and a Mac for iOS (see the iOS note below)
- Node.js 20+ to run the injected-SDK tests

## Setup and common commands

```bash
flutter pub get

flutter analyze                       # static analysis
flutter test test/                    # unit, security and regression tests
flutter test --coverage test/         # same, with coverage/lcov.info
node --test test/js/bridge_sdk.test.mjs   # injected JavaScript SDK

flutter run                           # debug app on a device or emulator
flutter build apk --debug
flutter test integration_test/app_test.dart -d <android-device-id>
```

## Release signing

Release builds are never signed with the debug key (SEC-006). To produce a
signed release APK, set these environment variables before running
`flutter build apk --release`:

| Variable | Meaning |
| --- | --- |
| `SWEETMELON_KEYSTORE_PATH` | Path to a `.jks`/`.keystore` file |
| `SWEETMELON_KEYSTORE_PASSWORD` | Keystore password |
| `SWEETMELON_KEY_ALIAS` | Key alias |
| `SWEETMELON_KEY_PASSWORD` | Key password |

Without `SWEETMELON_KEYSTORE_PATH` the release APK is built unsigned. Keystores
and passwords must never be committed.

## Layout

```
lib/
  app.dart, main.dart          application entry
  di/service_locator.dart      dependency wiring (get_it)
  screens/home_screen.dart     demo page hosting the WebView
  packages/
    core/                      protocol, bridge, WebView host, JS SDK, logger
    plugin_engine/             plugin interface, registry, execution manager
    security/                  permissions, rate limiter, execution guard
    performance/               bounded LRU cache with TTL
    devtools/                  debug-only bridge inspector (payloads redacted)
  plugins/
    camera/ geolocation/ storage/
test/                          unit, security and regression tests (Dart)
test/js/                       injected SDK tests (Node VM)
integration_test/              on-device end-to-end test
android/, ios/                 platform projects
.github/workflows/ci.yml       CI pipeline
```

## iOS

The repository does not contain `ios/Podfile`, and the iOS project has not
been built or verified in CI. The `Info.plist` usage strings are in place. See
the blocked item IOS-001 in the audit plan.
