# 🍈 Sweetmelon — Flutter Native Bridge

**A powerful bridge between JavaScript (HTML/CSS/JS projects) and Android Native APIs, built with Flutter.**

> Run Angular, React, Vue or any HTML project inside a Flutter WebView and access **35 native plugins** through a unified JavaScript SDK.

---

## 🏗 Architecture

```
┌─────────────────────────────────────────────────┐
│                   JS / HTML App                  │
│  (Angular, React, Vue, or vanilla HTML/JS/CSS)  │
├─────────────────────────────────────────────────┤
│               window.NativeSDK                   │
│          (native-sdk.js — JS wrapper)            │
├─────────────────────────────────────────────────┤
│              window.Native.call()                │
│        (Bridge SDK injected by Flutter)          │
├─────────────────────────────────────────────────┤
│              Message Bridge (Dart)               │
│     JSON message protocol over JS channels       │
├─────────────────────────────────────────────────┤
│              Plugin Manager (Dart)               │
│  Permission • Rate Limit • Cache • Execution     │
├─────────────────────────────────────────────────┤
│              Plugin Registry (Dart)              │
│         35 Plugins registered at startup         │
├─────────────────────────────────────────────────┤
│            Android / iOS Native APIs             │
└─────────────────────────────────────────────────┘
```

---

## 📦 Project Structure

```
sweetmelon/
├── android/                          # Android native config
├── ios/                              # iOS native config
├── assets/
│   └── www/                          # ← Your HTML project goes here
│       ├── index.html                # Entry point (fixed path)
│       ├── css/styles.css            # Styles
│       └── js/
│           ├── native-sdk.js         # NativeSDK wrapper
│           ├── native-sdk.d.ts       # TypeScript definitions
│           └── app.js                # Test suite
├── lib/
│   ├── main.dart                     # App entry
│   ├── app.dart                      # MaterialApp
│   ├── di/service_locator.dart       # Dependency injection
│   ├── screens/home_screen.dart      # Main screen with WebView
│   ├── packages/
│   │   ├── core/                     # Bridge, protocol, WebView host, logger
│   │   ├── plugin_engine/            # Plugin interface, registry, manager
│   │   ├── security/                 # Permissions, rate limiter, execution guard
│   │   ├── performance/              # Cache manager
│   │   └── devtools/                 # Bridge inspector
│   └── plugins/
│       ├── permission/               # Permission management
│       ├── app_lifecycle/            # App state events
│       ├── device_info/              # Device & app info
│       ├── connectivity/             # Network status
│       ├── storage/                  # Key-value storage
│       ├── file_system/              # File read/write
│       ├── http_native/              # HTTP client
│       ├── intent_link/              # URL launcher & deep links
│       ├── clipboard/                # Clipboard access
│       ├── share/                    # Native share sheet
│       ├── camera/                   # Camera & gallery
│       ├── geolocation/              # GPS location
│       ├── back_button/              # Android back button
│       ├── secure_storage/           # Encrypted storage
│       ├── notification/             # Local notifications
│       ├── status_bar/               # Status bar control
│       ├── orientation/              # Screen orientation
│       ├── haptic/                   # Vibration feedback
│       ├── keyboard/                 # Keyboard state
│       ├── biometrics/               # Fingerprint / Face ID
│       ├── qr_scanner/               # QR & barcode scanner
│       ├── audio/                    # Audio recorder & player
│       ├── sms_otp/                  # SMS OTP auto-read
│       ├── download_manager/         # Download with progress
│       ├── database/                 # SQLite database
│       ├── contacts/                 # Contacts access
│       ├── phone_dialer/             # Phone, SMS, Email
│       ├── bluetooth/                # Bluetooth BLE
│       ├── nfc/                      # NFC read/write
│       ├── speech_to_text/           # Voice recognition
│       ├── text_to_speech/           # Text-to-speech
│       ├── video_player/             # Video playback
│       ├── in_app_browser/           # In-app web browser
│       ├── pdf_plugin/               # PDF generate & print
│       └── encryption/               # AES, SHA, HMAC
└── docs/
    └── angular-integration.md        # Angular guide
```

---

## 🚀 Quick Start

### 1. Place your HTML project

Put your built HTML/CSS/JS project in:
```
assets/www/index.html     ← entry point (fixed)
assets/www/css/            ← styles
assets/www/js/             ← scripts
assets/www/images/         ← images
```

### 2. Include NativeSDK

Add to your `index.html`:
```html
<script src="js/native-sdk.js"></script>
```

### 3. Use in JavaScript

```javascript
// Wait for bridge to be ready
await NativeSDK.waitForReady();

// Call any plugin
const info = await NativeSDK.deviceInfo.getAll();
console.log(info.device.model);

// Listen to events
NativeSDK.on('connectivity.change', (data) => {
  console.log('Online:', data.online);
});
```

### 4. Run

```bash
flutter run
```

---

## 🔌 All 35 Plugins

| # | Plugin | JS Name | Description |
|---|--------|---------|-------------|
| 1 | Permission | `permission` | Check & request native permissions |
| 2 | App Lifecycle | `appLifecycle` | App state (pause/resume/background) |
| 3 | Device Info | `deviceInfo` | Device model, OS, app version |
| 4 | Connectivity | `connectivity` | Network status & monitoring |
| 5 | Storage | `storage` | Key-value storage (SharedPreferences) |
| 6 | File System | `fileSystem` | Sandboxed file read/write/list |
| 7 | HTTP | `http` | Native HTTP client with download |
| 8 | Intent | `intent` | URL launcher & deep links |
| 9 | Clipboard | `clipboard` | Read/write clipboard |
| 10 | Share | `share` | Native share sheet |
| 11 | Camera | `camera` | Take photo & pick from gallery |
| 12 | Geolocation | `geolocation` | GPS location & watch |
| 13 | Back Button | `backButton` | Android back button intercept |
| 14 | Secure Storage | `secureStorage` | Encrypted key-value storage |
| 15 | Notification | `notification` | Local notifications |
| 16 | Status Bar | `statusBar` | Status bar style & visibility |
| 17 | Orientation | `orientation` | Lock screen orientation |
| 18 | Haptic | `haptic` | Vibration feedback |
| 19 | Keyboard | `keyboard` | Keyboard state & visibility |
| 20 | Biometrics | `biometrics` | Fingerprint / Face ID |
| 21 | QR Scanner | `qrScanner` | QR & barcode scanning |
| 22 | Audio | `audio` | Record & play audio |
| 23 | SMS OTP | `smsOtp` | Auto-read SMS OTP |
| 24 | Download Manager | `downloadManager` | Download with progress |
| 25 | Database | `database` | SQLite database |
| 26 | Contacts | `contacts` | Read contacts |
| 27 | Phone Dialer | `phoneDialer` | Call, SMS, Email |
| 28 | Bluetooth | `bluetooth` | BLE scan, connect, read/write |
| 29 | NFC | `nfc` | NFC tag read/write |
| 30 | Speech to Text | `speechToText` | Voice recognition |
| 31 | Text to Speech | `textToSpeech` | Read text aloud |
| 32 | Video Player | `videoPlayer` | Play video (URL/file) |
| 33 | In-App Browser | `inAppBrowser` | Open external pages |
| 34 | PDF | `pdf` | Generate & print PDF |
| 35 | Encryption | `encryption` | AES, SHA, HMAC, random |

---

## 📡 All Events

| Event | Source Plugin |
|-------|-------------|
| `app.lifecycle.change` | appLifecycle |
| `connectivity.change` | connectivity |
| `connectivity.error` | connectivity |
| `intent.deepLink` | intent |
| `intent.error` | intent |
| `geolocation.position` | geolocation |
| `geolocation.error` | geolocation |
| `backButton.pressed` | backButton |
| `notification.tap` | notification |
| `keyboard.change` | keyboard |
| `qrScanner.scanned` | qrScanner |
| `audio.playerState` | audio |
| `audio.position` | audio |
| `smsOtp.received` | smsOtp |
| `download.progress` | downloadManager |
| `download.complete` | downloadManager |
| `download.error` | downloadManager |
| `bluetooth.deviceFound` | bluetooth |
| `bluetooth.connectionState` | bluetooth |
| `nfc.tagDiscovered` | nfc |
| `nfc.error` | nfc |
| `speechToText.result` | speechToText |
| `speechToText.status` | speechToText |
| `speechToText.error` | speechToText |
| `tts.start` | textToSpeech |
| `tts.complete` | textToSpeech |
| `tts.cancel` | textToSpeech |
| `tts.error` | textToSpeech |
| `tts.progress` | textToSpeech |
| `videoPlayer.state` | videoPlayer |
| `inAppBrowser.loadStop` | inAppBrowser |
| `inAppBrowser.error` | inAppBrowser |

---

## 🔧 Angular Integration

See [docs/angular-integration.md](docs/angular-integration.md)

Quick:
```bash
ng build --configuration production --output-path /path/to/assets/www --base-href ./
```

```typescript
// In Angular component:
const info = await (window as any).NativeSDK.deviceInfo.getAll();
```

---

## 📋 JS API Quick Reference

```javascript
// Core
NativeSDK.waitForReady(timeoutMs?)
NativeSDK.call(plugin, method, args?, extra?)
NativeSDK.batch(requests[], options?)
NativeSDK.on(event, callback)         // returns unsubscribe function
NativeSDK.off(event, callback)
NativeSDK.info()

// Plugin shorthand
NativeSDK.storage.get(key)
NativeSDK.storage.set(key, value)
NativeSDK.http.get(url, options?)
NativeSDK.camera.takePhoto(options?)
// ... etc for all 35 plugins
```

---

## 🛡 Security Features

- **Permission Management** — real native permission_handler
- **Rate Limiting** — per-plugin, per-method rate limits
- **Execution Guard** — timeout protection for all calls
- **Cache Manager** — LRU cache with TTL, mutation-aware
- **Sandbox** — file system path traversal protection
- **Encrypted Storage** — AES-encrypted SharedPreferences

---

## Documentation

- Architecture: [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)
- Security model and known limitations: [docs/SECURITY.md](docs/SECURITY.md)
- Tests and how to run them: [docs/TESTING.md](docs/TESTING.md)
- Audit findings and status: [docs/AUDIT_EXECUTION_PLAN.md](docs/AUDIT_EXECUTION_PLAN.md)
- Change journal: [docs/WORKLOG.md](docs/WORKLOG.md)

---

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
test/regression/               regression tests; each file names the findings it covers
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
