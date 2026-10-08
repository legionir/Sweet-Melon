# Sweet-Melon

A Flutter app that hosts a WebView and gives the web page a small, validated
bridge to native plugins (camera, storage, geolocation). It is a JavaScript-to-native
API bridge, not a general WebView wrapper. The JavaScript side
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

flutter analyze --fatal-warnings      # static analysis (CI uses this)
bash .github/scripts/format_report.sh   # formatting (CI; fails on any unformatted file)
flutter test test/                    # unit, security, regression, integration, performance
flutter test --coverage test/         # same, writes coverage/lcov.info
python3 .github/scripts/coverage_gate.py coverage/lcov.info 55 '(^|/)(gen|generated)/|\.g\.dart$'
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
test/unit/                     unit tests
test/security/                 attacker-input tests (storage paths, sizes)
test/regression/               one file per fixed finding (BUG-, SEC-, SM-)
test/integration/              JSON -> bridge -> manager -> plugin -> response
test/performance/              smoke budgets (bridge, events, cache)
test/helpers/                  fakes shared by the Dart tests
test/js/                       injected SDK tests (Node VM)
integration_test/              on-device end-to-end test (Android emulator)
android/, ios/                 platform projects (ios/Podfile is committed)
.github/workflows/ci.yml       CI pipeline
.github/scripts/               CI helpers (E2E runner, coverage gate, format report)
docs/                          architecture, security, testing, audit plan, worklog
```

## iOS

The iOS project is built in CI on a macOS runner with `flutter build ios --debug
--no-codesign`. CI keeps the CocoaPods integration (Flutter's Swift Package
Manager migration is turned off for the job) and runs `pod install` before the
build. The minimum iOS version is 13.0, matching `ios/Podfile` and the
`IPHONEOS_DEPLOYMENT_TARGET` setting. Running on a device needs a Mac with Xcode
and your own signing team.

## Before release

Identifiers are placeholders inherited from the Flutter template. Before you
publish the app, choose your own values:

- Android `applicationId` in `android/app/build.gradle.kts`
  (currently `com.example.sweet_melon`).
- iOS `PRODUCT_BUNDLE_IDENTIFIER` in `ios/Runner.xcodeproj/project.pbxproj`
  (currently `com.example.sweet_melon`, kept equal to the Android ID).
- Release signing environment variables, as described above.
