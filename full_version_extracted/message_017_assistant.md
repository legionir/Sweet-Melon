عالی. بیا کامل و حرفه‌ای بنویسیم.

---

# README اصلی پروژه

## 📄 `README.md`

```markdown
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

## 📄 License

MIT
```

---

# Plugin READMEs — هر پلاگین جداگانه

---

## 📄 `lib/plugins/permission/README.md`

```markdown
# Permission Plugin

Manage native Android/iOS permissions from JavaScript.

## Plugin Name
`permission`

## Methods

### `check`
Check a single permission status.

**Args:**
| Param | Type | Required | Description |
|-------|------|----------|-------------|
| `permission` | `string` | ✅ | Permission name |

**Returns:**
```json
{
  "permission": "camera",
  "status": "granted",
  "granted": true,
  "permanentlyDenied": false
}
```

### `request`
Request a single permission.

**Args:** Same as `check`.

**Returns:** Same as `check`.

### `checkMany`
Check multiple permissions at once.

**Args:**
| Param | Type | Required | Description |
|-------|------|----------|-------------|
| `permissions` | `string[]` | ✅ | List of permission names |

**Returns:**
```json
{
  "results": {
    "camera": { "status": "granted", "granted": true },
    "location": { "status": "denied", "granted": false }
  }
}
```

### `requestMany`
Request multiple permissions. Args and returns same as `checkMany`.

### `openSettings`
Open app settings page.

**Returns:** `{ "opened": true }`

### `getKnownPermissions`
List all supported permission names.

**Returns:** `{ "permissions": ["camera", "storage", "location", ...] }`

## Known Permission Names
`camera`, `storage`, `manageExternalStorage`, `location`, `locationAlways`,
`microphone`, `photos`, `notification`, `contacts`, `bluetooth`

## Usage
```javascript
// Check
const result = await NativeSDK.permission.check('camera');
if (!result.granted) {
  await NativeSDK.permission.request('camera');
}

// Check multiple
const all = await NativeSDK.permission.checkMany(['camera', 'location', 'microphone']);

// Open settings if permanently denied
if (result.permanentlyDenied) {
  await NativeSDK.permission.openSettings();
}
```
```

---

## 📄 `lib/plugins/app_lifecycle/README.md`

```markdown
# App Lifecycle Plugin

Monitor app lifecycle state changes (pause, resume, background, etc).

## Plugin Name
`appLifecycle`

## Methods

### `getState`
Get current app state.

**Returns:**
```json
{ "state": "resumed" }
```

Possible states: `resumed`, `inactive`, `paused`, `detached`, `hidden`

### `enableEvents`
Enable lifecycle change events.

**Returns:** `{ "enabled": true }`

### `disableEvents`
Disable lifecycle change events.

**Returns:** `{ "enabled": false }`

### `getInfo`
Get plugin info including current state and event status.

## Events

### `app.lifecycle.change`
Fired when app state changes.
```json
{
  "state": "paused",
  "previousState": "resumed",
  "timestamp": "2024-01-15T10:30:00.000Z"
}
```

## Usage
```javascript
// Get current state
const { state } = await NativeSDK.appLifecycle.getState();

// Listen to changes
NativeSDK.on('app.lifecycle.change', (data) => {
  if (data.state === 'paused') {
    saveFormData();
  }
  if (data.state === 'resumed') {
    refreshData();
  }
});
```
```

---

## 📄 `lib/plugins/device_info/README.md`

```markdown
# Device Info Plugin

Get device hardware info and app package info.

## Plugin Name
`deviceInfo`

## Methods

### `getDeviceInfo`
Get device hardware information.

**Returns (Android):**
```json
{
  "platform": "android",
  "brand": "Samsung",
  "manufacturer": "samsung",
  "model": "SM-A525F",
  "isPhysicalDevice": true,
  "version": {
    "sdkInt": 33,
    "release": "13"
  },
  "supportedAbis": ["arm64-v8a", "armeabi-v7a"]
}
```

### `getAppInfo`
**Returns:**
```json
{
  "appName": "sweetmelon",
  "packageName": "com.example.sweet_melon",
  "version": "1.0.0",
  "buildNumber": "1"
}
```

### `getAll`
Returns both device and app info combined.

## Usage
```javascript
const { device, app } = await NativeSDK.deviceInfo.getAll();
console.log(`${device.brand} ${device.model} — v${app.version}`);
```
```

---

## 📄 `lib/plugins/connectivity/README.md`

```markdown
# Connectivity Plugin

Monitor network connectivity status in real-time.

## Plugin Name
`connectivity`

## Methods

### `getStatus`
**Returns:**
```json
{
  "online": true,
  "primary": "wifi",
  "types": ["wifi"],
  "timestamp": "2024-01-15T10:30:00.000Z"
}
```

### `isOnline`
**Returns:** `{ "online": true }`

### `startWatch`
Start monitoring connectivity changes.

### `stopWatch`
Stop monitoring.

## Events

### `connectivity.change`
```json
{
  "online": true,
  "primary": "mobile",
  "types": ["mobile"],
  "timestamp": "..."
}
```

## Usage
```javascript
await NativeSDK.connectivity.startWatch();

NativeSDK.on('connectivity.change', (data) => {
  if (!data.online) {
    showOfflineBanner();
  }
});
```
```

---

## 📄 `lib/plugins/storage/README.md`

```markdown
# Storage Plugin

Simple key-value storage using SharedPreferences.

## Plugin Name
`storage`

## Methods

| Method | Args | Returns |
|--------|------|---------|
| `set` | `key: string, value: any` | `true` |
| `get` | `key: string` | stored value or `null` |
| `has` | `key: string` | `{ exists: bool }` |
| `remove` | `key: string` | `true` |
| `keys` | — | `{ keys: string[] }` |
| `clear` | — | count of removed keys |

## Usage
```javascript
await NativeSDK.storage.set('user', { name: 'Ali', role: 'admin' });
const user = await NativeSDK.storage.get('user');
const { keys } = await NativeSDK.storage.keys();
await NativeSDK.storage.remove('user');
```

## Notes
- Values are JSON-encoded automatically
- Keys are prefixed with `bridge_` internally
- For sensitive data, use `secureStorage` instead
```

---

## 📄 `lib/plugins/file_system/README.md`

```markdown
# File System Plugin

Sandboxed file system access with path traversal protection.

## Plugin Name
`fileSystem`

## Base Directories
| Name | Description |
|------|-------------|
| `documents` | App documents (default) |
| `cache` | App cache |
| `support` | App support |
| `temporary` | Temporary files |

## Methods

### `getDirectories`
**Returns:** paths for all base directories

### `writeFile`
| Param | Type | Required | Default |
|-------|------|----------|---------|
| `path` | `string` | ✅ | — |
| `content` | `string` | ✅ | — |
| `baseDir` | `string` | — | `documents` |
| `encoding` | `string` | — | `utf8` |
| `append` | `bool` | — | `false` |

### `readFile`
| Param | Type | Required | Default |
|-------|------|----------|---------|
| `path` | `string` | ✅ | — |
| `baseDir` | `string` | — | `documents` |
| `encoding` | `string` | — | `utf8` |

### `deleteFile`, `fileExists`, `stat`
All require `path` and optional `baseDir`.

### `listFiles`
| Param | Type | Required | Default |
|-------|------|----------|---------|
| `path` | `string` | — | `""` (root) |
| `baseDir` | `string` | — | `documents` |
| `recursive` | `bool` | — | `false` |

### `createDirectory`, `deleteDirectory`
Require `path`, optional `baseDir` and `recursive`.

## Usage
```javascript
await NativeSDK.fileSystem.writeFile('logs/app.log', 'Hello World');
const { content } = await NativeSDK.fileSystem.readFile('logs/app.log');
const { items } = await NativeSDK.fileSystem.listFiles('logs', { recursive: true });
```

## Security
- Path traversal (`..`) is blocked
- All paths are sandboxed to base directories
```

---

## 📄 `lib/plugins/http_native/README.md`

```markdown
# HTTP Native Plugin

Native HTTP client with full control over headers, body, and downloads.

## Plugin Name
`http`

## Methods

### `get`, `post`, `put`, `patch`, `delete`
| Param | Type | Required | Default |
|-------|------|----------|---------|
| `url` | `string` | ✅ | — |
| `headers` | `object` | — | `{}` |
| `body` | `any` | — | — |
| `bodyType` | `string` | — | `auto` |
| `responseType` | `string` | — | `auto` |
| `query` | `object` | — | — |
| `timeoutMs` | `number` | — | `30000` |

**bodyType:** `auto`, `json`, `form`
**responseType:** `auto`, `json`, `bytes`, `base64`

**Returns:**
```json
{
  "ok": true,
  "statusCode": 200,
  "headers": {},
  "data": { ... }
}
```

### `download`
| Param | Type | Required | Default |
|-------|------|----------|---------|
| `url` | `string` | ✅ | — |
| `fileName` | `string` | — | from URL |
| `baseDir` | `string` | — | `temporary` |
| `path` | `string` | — | `downloads/` |
| `overwrite` | `bool` | — | `true` |

## Usage
```javascript
// GET
const { data } = await NativeSDK.http.get('https://api.example.com/users');

// POST with JSON
const result = await NativeSDK.http.post(
  'https://api.example.com/users',
  { name: 'Ali', email: 'ali@test.com' },
  { bodyType: 'json', responseType: 'json' }
);

// Download
const file = await NativeSDK.http.download({
  url: 'https://example.com/file.pdf',
  fileName: 'report.pdf'
});
```
```

---

## 📄 `lib/plugins/intent_link/README.md`

```markdown
# Intent / Deep Link Plugin

Open URLs, apps, and receive deep links.

## Plugin Name
`intent`

## Methods

### `openUrl`
| Param | Type | Required | Default |
|-------|------|----------|---------|
| `url` | `string` | ✅ | — |
| `mode` | `string` | — | `external` |

**Modes:** `external`, `inApp`, `platform`, `externalNonBrowser`

### `canOpenUrl`
Check if URL can be opened.

### `getInitialLink` / `getLatestLink`
Get deep link that opened the app.

### `startListening` / `stopListening`
Listen for incoming deep links.

## Events

### `intent.deepLink`
```json
{ "url": "sweetmelon://product/123", "timestamp": "..." }
```

## Supported URL Schemes
`https://`, `http://`, `tel:`, `sms:`, `smsto:`, `mailto:`, `geo:`, `market:`, `sweetmelon://`

## Usage
```javascript
await NativeSDK.intent.openUrl('tel:+989123456789');
await NativeSDK.intent.openUrl('mailto:test@example.com');
await NativeSDK.intent.openUrl('https://flutter.dev');

NativeSDK.on('intent.deepLink', (data) => {
  router.navigate(data.url);
});
```
```

---

## 📄 `lib/plugins/clipboard/README.md`

```markdown
# Clipboard Plugin

Read and write system clipboard.

## Plugin Name
`clipboard`

## Methods

| Method | Args | Returns |
|--------|------|---------|
| `writeText` | `text: string` | `{ written: true }` |
| `readText` | — | `{ text: "..." }` |
| `hasText` | — | `{ hasText: true }` |
| `clear` | — | `{ cleared: true }` |

## Usage
```javascript
await NativeSDK.clipboard.writeText('Hello World');
const { text } = await NativeSDK.clipboard.readText();
```
```

---

## 📄 `lib/plugins/share/README.md`

```markdown
# Share Plugin

Native share sheet for text and files.

## Plugin Name
`share`

## Methods

### `shareText`
| Param | Type | Required |
|-------|------|----------|
| `text` | `string` | ✅ |
| `subject` | `string` | — |

### `shareFiles`
| Param | Type | Required |
|-------|------|----------|
| `paths` | `string[]` | ✅ |
| `text` | `string` | — |
| `subject` | `string` | — |

## Usage
```javascript
await NativeSDK.share.shareText('Check out this app!', 'Sweetmelon');

// Share a file (must use absolute path from fileSystem)
const dirs = await NativeSDK.fileSystem.getDirectories();
await NativeSDK.share.shareFiles(
  [dirs.documents + '/reports/report.pdf'],
  'Monthly report attached'
);
```
```

---

## 📄 `lib/plugins/camera/README.md`

```markdown
# Camera Plugin

Take photos and pick images from gallery.

## Plugin Name
`camera`

## Methods

### `takePhoto`
| Param | Type | Default |
|-------|------|---------|
| `quality` | `number (0-100)` | `80` |
| `maxWidth` | `number` | — |
| `maxHeight` | `number` | — |

**Returns:**
```json
{ "path": "/...", "name": "image.jpg", "size": 123456, "mimeType": "image/jpeg" }
```

### `pickFromGallery`
| Param | Type | Default |
|-------|------|---------|
| `multiple` | `bool` | `false` |

### `getInfo`
Returns plugin info.

## Usage
```javascript
const photo = await NativeSDK.camera.takePhoto({ quality: 90 });
console.log('Photo saved at:', photo.path);

const gallery = await NativeSDK.camera.pickFromGallery({ multiple: true });
```
```

---

## 📄 `lib/plugins/geolocation/README.md`

```markdown
# Geolocation Plugin

GPS location with real-time watching.

## Plugin Name
`geolocation`

## Methods

### `getCurrentPosition`
| Param | Type | Default |
|-------|------|---------|
| `accuracy` | `string` | `high` |

Accuracy: `lowest`, `low`, `medium`, `high`, `best`, `bestForNavigation`

**Returns:**
```json
{
  "latitude": 35.6892,
  "longitude": 51.3890,
  "altitude": 1200.0,
  "accuracy": 10.5,
  "speed": 0.0,
  "heading": 180.0,
  "timestamp": "..."
}
```

### `watchPosition`
Start continuous position updates.

### `clearWatch`
Stop watching.

### `checkPermission` / `requestPermission`
### `isLocationEnabled`

## Events

### `geolocation.position`
Fires on each position update during `watchPosition`.

### `geolocation.error`
Fires on location errors.

## Usage
```javascript
const pos = await NativeSDK.geolocation.getCurrentPosition({ accuracy: 'high' });
console.log(`${pos.latitude}, ${pos.longitude}`);

await NativeSDK.geolocation.watchPosition({ distanceFilter: 10 });
NativeSDK.on('geolocation.position', (pos) => {
  updateMap(pos.latitude, pos.longitude);
});
```
```

---

## 📄 `lib/plugins/back_button/README.md`

```markdown
# Back Button Plugin

Intercept Android back button for SPA navigation.

## Plugin Name
`backButton`

## Methods

| Method | Description |
|--------|-------------|
| `enableIntercept` | Start intercepting back button |
| `disableIntercept` | Stop intercepting |
| `getState` | Get current intercept state |
| `exitApp` | Close the app |
| `setExitOnBack` | Exit app when back is pressed (no intercept) |
| `minimizeApp` | Minimize to background |

## Events

### `backButton.pressed`
Fired when back button is pressed (only when intercept is enabled).

## Usage
```javascript
await NativeSDK.backButton.enableIntercept();

NativeSDK.on('backButton.pressed', () => {
  if (canGoBack()) {
    window.history.back();
  } else {
    if (confirm('Exit app?')) {
      NativeSDK.backButton.exitApp();
    }
  }
});
```
```

---

## 📄 `lib/plugins/secure_storage/README.md`

```markdown
# Secure Storage Plugin

AES-encrypted key-value storage for sensitive data (tokens, passwords, etc).

## Plugin Name
`secureStorage`

## Methods

| Method | Args | Returns |
|--------|------|---------|
| `set` | `key, value` | `{ written: true }` |
| `get` | `key` | `{ value: ..., found: bool }` |
| `has` | `key` | `{ exists: bool }` |
| `remove` | `key` | `{ removed: true }` |
| `keys` | — | `{ keys: [], count: n }` |
| `clear` | — | `{ cleared: n }` |

## Usage
```javascript
await NativeSDK.secureStorage.set('auth_token', 'eyJhbGciOiJIUzI1...');
const { value } = await NativeSDK.secureStorage.get('auth_token');
```

## Notes
- Uses Android EncryptedSharedPreferences
- Uses iOS Keychain
- Keys prefixed with `sec_` internally
```

---

## 📄 `lib/plugins/notification/README.md`

```markdown
# Notification Plugin

Display local notifications with channels and actions.

## Plugin Name
`notification`

## Methods

### `show`
| Param | Type | Default |
|-------|------|---------|
| `id` | `number` | random |
| `title` | `string` | `""` |
| `body` | `string` | `""` |
| `channelId` | `string` | `"default"` |
| `channelName` | `string` | `"Default"` |
| `payload` | `string` | — |
| `importance` | `string` | `"high"` |
| `priority` | `string` | `"high"` |
| `ongoing` | `bool` | `false` |
| `silent` | `bool` | `false` |

### `cancel` — cancel by id
### `cancelAll` — cancel all notifications
### `getActive` — list active notifications
### `getPending` — list pending notifications
### `createChannel` — create Android notification channel

## Events

### `notification.tap`
Fired when user taps a notification.
```json
{ "id": 1, "payload": "custom-data", "actionId": null }
```

## Usage
```javascript
await NativeSDK.notification.show({
  title: 'Order Confirmed',
  body: 'Your order #1234 has been confirmed.',
  payload: 'order_1234'
});

NativeSDK.on('notification.tap', (data) => {
  router.navigate('/orders/' + data.payload);
});
```
```

---

## 📄 `lib/plugins/status_bar/README.md`

```markdown
# Status Bar Plugin

Control Android status bar appearance.

## Plugin Name
`statusBar`

## Methods

| Method | Args |
|--------|------|
| `setStyle` | `style: "light"/"dark"`, `backgroundColor?: "#RRGGBB"` |
| `setColor` | `color: "#RRGGBB"`, `navigationBarColor?: "#RRGGBB"` |
| `show` | — |
| `hide` | — |
| `setFullscreen` | Immersive sticky fullscreen |
| `exitFullscreen` | Exit fullscreen |

## Usage
```javascript
await NativeSDK.statusBar.setStyle('dark', '#FFFFFF');
await NativeSDK.statusBar.setFullscreen();
// ...
await NativeSDK.statusBar.exitFullscreen();
```
```

---

## 📄 `lib/plugins/orientation/README.md`

```markdown
# Orientation Plugin

Lock and unlock screen orientation.

## Plugin Name
`orientation`

## Methods

### `lock`
| Param | Type | Default |
|-------|------|---------|
| `orientation` | `string` | `portrait` |

Values: `portrait`, `portraitUp`, `portraitDown`, `landscape`, `landscapeLeft`, `landscapeRight`

### `unlock`
Unlock to all orientations.

## Usage
```javascript
await NativeSDK.orientation.lock('landscape');  // video player
await NativeSDK.orientation.unlock();           // back to normal
```
```

---

## 📄 `lib/plugins/haptic/README.md`

```markdown
# Haptic Plugin

Vibration and haptic feedback.

## Plugin Name
`haptic`

## Methods

| Method | Description |
|--------|-------------|
| `lightImpact` | Light haptic tap |
| `mediumImpact` | Medium haptic tap |
| `heavyImpact` | Heavy haptic tap |
| `selectionClick` | Selection tick |
| `vibrate` | Standard vibration |

## Usage
```javascript
await NativeSDK.haptic.lightImpact();    // subtle feedback
await NativeSDK.haptic.heavyImpact();    // strong feedback
```
```

---

## 📄 `lib/plugins/keyboard/README.md`

```markdown
# Keyboard Plugin

Monitor keyboard visibility and height.

## Plugin Name
`keyboard`

## Methods

| Method | Returns |
|--------|---------|
| `getState` | `{ visible, height }` |
| `startWatch` | `{ watching: true }` |
| `stopWatch` | `{ watching: false }` |
| `hide` | `{ hidden: true }` |

## Events

### `keyboard.change`
```json
{ "visible": true, "height": 280.5, "timestamp": "..." }
```

## Usage
```javascript
await NativeSDK.keyboard.startWatch();
NativeSDK.on('keyboard.change', (data) => {
  document.body.style.paddingBottom = data.visible ? data.height + 'px' : '0';
});
```
```

---

## 📄 `lib/plugins/biometrics/README.md`

```markdown
# Biometrics Plugin

Fingerprint and face recognition authentication.

## Plugin Name
`biometrics`

## Methods

### `isAvailable`
**Returns:** `{ available: true, canCheckBiometrics: true, isDeviceSupported: true }`

### `getAvailableBiometrics`
**Returns:** `{ hasFingerprint: true, hasFace: false, biometrics: ["fingerprint", "strong"] }`

### `authenticate`
| Param | Type | Default |
|-------|------|---------|
| `reason` | `string` | `"Please authenticate"` |
| `biometricOnly` | `bool` | `false` |

**Returns:**
```json
{ "authenticated": true, "method": "biometric" }
```
Or on failure:
```json
{ "authenticated": false, "errorCode": "not_enrolled", "errorMessage": "..." }
```

## Usage
```javascript
const { available } = await NativeSDK.biometrics.isAvailable();
if (available) {
  const { authenticated } = await NativeSDK.biometrics.authenticate({
    reason: 'Verify to access wallet'
  });
  if (authenticated) {
    showWallet();
  }
}
```
```

---

## 📄 `lib/plugins/qr_scanner/README.md`

```markdown
# QR Scanner Plugin

Scan QR codes and barcodes using native camera.

## Plugin Name
`qrScanner`

## Methods

### `scan`
| Param | Type | Default |
|-------|------|---------|
| `timeoutMs` | `number` | `60000` |

**Returns:**
```json
{
  "scanned": true,
  "value": "https://example.com",
  "format": "qr",
  "type": "url",
  "timestamp": "..."
}
```

Content types: `url`, `phone`, `email`, `sms`, `wifi`, `geo`, `vcard`, `text`

Supported formats: QR, EAN-13, EAN-8, Code128, Code39, UPC-A, UPC-E, ITF, PDF417, Aztec, DataMatrix

## Events
### `qrScanner.scanned`

## Usage
```javascript
const result = await NativeSDK.qrScanner.scan({ timeoutMs: 30000 });
if (result.scanned) {
  if (result.type === 'url') {
    NativeSDK.intent.openUrl(result.value);
  }
}
```
```

---

## 📄 `lib/plugins/audio/README.md`

```markdown
# Audio Plugin

Record audio and play audio files/URLs.

## Plugin Name
`audio`

## Recorder Methods

| Method | Args | Returns |
|--------|------|---------|
| `startRecording` | `fileName?, encoder?, bitRate?, sampleRate?` | `{ path }` |
| `stopRecording` | — | `{ path, size }` |
| `isRecording` | — | `{ recording: bool }` |

Encoders: `aacLc`, `aacEld`, `aacHe`, `opus`, `wav`, `flac`

## Player Methods

| Method | Args | Returns |
|--------|------|---------|
| `play` | `path or url` | `{ playing: true }` |
| `pause` | — | `{ paused }` |
| `resume` | — | `{ resumed }` |
| `stop` | — | `{ stopped }` |
| `seek` | `positionMs` | `{ seeked }` |
| `setVolume` | `volume (0-1)` | `{ volume }` |
| `getDuration` | — | `{ durationMs }` |
| `getPosition` | — | `{ positionMs }` |

## Events
- `audio.playerState` — `{ state, isPlaying }`
- `audio.position` — `{ positionMs, positionSec }`

## Usage
```javascript
// Record
await NativeSDK.audio.startRecording({ encoder: 'aacLc' });
// ... user speaks ...
const rec = await NativeSDK.audio.stopRecording();

// Play back
await NativeSDK.audio.play({ path: rec.path });
```
```

---

## 📄 `lib/plugins/sms_otp/README.md`

```markdown
# SMS OTP Plugin

Auto-read SMS OTP codes (Android only).

## Plugin Name
`smsOtp`

## Methods

| Method | Returns |
|--------|---------|
| `getAppSignature` | `{ signature: "abc123" }` |
| `startListening` | `{ listening: true }` |
| `stopListening` | `{ listening: false }` |
| `getLastCode` | `{ code: "123456" }` |
| `requestHint` | `{ hint: "+98912***789" }` |

## Events
### `smsOtp.received`
```json
{ "code": "123456", "timestamp": "..." }
```

## SMS Format Required
```
Your verification code is 123456
FA+9876543210       ← app signature from getAppSignature
```

## Usage
```javascript
const { signature } = await NativeSDK.smsOtp.getAppSignature();
// Send signature to your backend to include in SMS

await NativeSDK.smsOtp.startListening();
NativeSDK.on('smsOtp.received', (data) => {
  otpInput.value = data.code;
  verifyOtp(data.code);
});
```
```

---

## 📄 `lib/plugins/download_manager/README.md`

```markdown
# Download Manager Plugin

Download files with real-time progress events.

## Plugin Name
`downloadManager`

## Methods

### `download`
| Param | Type | Required | Default |
|-------|------|----------|---------|
| `url` | `string` | ✅ | — |
| `fileName` | `string` | — | from URL |
| `baseDir` | `string` | — | `documents` |
| `path` | `string` | — | `downloads/` |
| `taskId` | `string` | — | auto |
| `overwrite` | `bool` | — | `true` |

### `cancel` — cancel by taskId
### `cancelAll`
### `getActive`

## Events
- `download.progress` — `{ taskId, percent, receivedBytes, totalBytes }`
- `download.complete` — `{ taskId, path, size, mimeType }`
- `download.error` — `{ taskId, error }`

## Usage
```javascript
NativeSDK.on('download.progress', (data) => {
  progressBar.style.width = data.percent + '%';
});

const result = await NativeSDK.downloadManager.download({
  url: 'https://example.com/large-file.zip',
  fileName: 'archive.zip'
});
```
```

---

## 📄 `lib/plugins/database/README.md`

```markdown
# Database Plugin

Full SQLite database with CRUD, raw queries, and batch operations.

## Plugin Name
`database`

## Methods

### `open`
| Param | Type | Required |
|-------|------|----------|
| `name` | `string` | ✅ |
| `version` | `number` | — (default 1) |
| `onCreate` | `string[]` | — (SQL statements) |

### `query`
| Param | Type |
|-------|------|
| `name` | database name |
| `table` | table name |
| `where` | SQL where clause |
| `whereArgs` | `any[]` |
| `orderBy` | `string` |
| `limit` | `number` |
| `offset` | `number` |

### `insert`
| Param | Type |
|-------|------|
| `name` | database name |
| `table` | table name |
| `values` | `{ column: value }` |

### `update`, `delete` — similar with `where`/`whereArgs`

### `rawQuery`, `rawInsert`, `rawUpdate`, `rawDelete`
Direct SQL execution.

### `batch`
Execute multiple operations atomically.

### `tableExists`, `deleteDatabase`, `close`

## Usage
```javascript
// Open with table creation
await NativeSDK.database.open('mydb', {
  version: 1,
  onCreate: [
    'CREATE TABLE users (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, email TEXT, age INTEGER)'
  ]
});

// Insert
const { id } = await NativeSDK.database.insert('mydb', 'users', {
  name: 'Ali', email: 'ali@test.com', age: 28
});

// Query
const { rows } = await NativeSDK.database.query('mydb', 'users', {
  where: 'age > ?',
  whereArgs: [25],
  orderBy: 'name ASC',
  limit: 10
});

// Raw query
const result = await NativeSDK.database.rawQuery('mydb',
  'SELECT COUNT(*) as total FROM users WHERE age > ?', [25]
);

// Batch
await NativeSDK.database.batch('mydb', [
  { type: 'insert', table: 'users', values: { name: 'User1' } },
  { type: 'insert', table: 'users', values: { name: 'User2' } },
  { type: 'delete', table: 'users', where: 'age < ?', whereArgs: [18] }
]);
```
```

---

## 📄 `lib/plugins/contacts/README.md`

```markdown
# Contacts Plugin

Read device contacts.

## Plugin Name
`contacts`

## Methods

| Method | Args |
|--------|------|
| `getAll` | `limit?, offset?, withPhoto?, withProperties?` |
| `getById` | `id` |
| `search` | `query` |
| `getCount` | — |
| `pickContact` | Opens native contact picker |

## Contact Object
```json
{
  "id": "123",
  "displayName": "Ali Ahmadi",
  "name": { "first": "Ali", "last": "Ahmadi" },
  "phones": [{ "number": "+989123456789", "label": "mobile" }],
  "emails": [{ "address": "ali@test.com", "label": "work" }]
}
```

## Usage
```javascript
const { contacts } = await NativeSDK.contacts.search('Ali');
const picked = await NativeSDK.contacts.pickContact();
```
```

---

## 📄 `lib/plugins/phone_dialer/README.md`

```markdown
# Phone Dialer Plugin

Make calls, send SMS, send email.

## Plugin Name
`phoneDialer`

## Methods

| Method | Args |
|--------|------|
| `dial` | `number` — opens dialer |
| `directCall` | `number` — starts call |
| `canDial` | `number` |
| `sendSms` | `number, body?` |
| `sendEmail` | `to, subject?, body?, cc?, bcc?` |

## Usage
```javascript
await NativeSDK.phoneDialer.dial('+989123456789');
await NativeSDK.phoneDialer.sendSms('+989123456789', 'Hello!');
await NativeSDK.phoneDialer.sendEmail({
  to: 'support@app.com',
  subject: 'Bug Report',
  body: 'I found a bug...'
});
```
```

---

## 📄 `lib/plugins/bluetooth/README.md`

```markdown
# Bluetooth BLE Plugin

Scan, connect, read/write BLE characteristics.

## Plugin Name
`bluetooth`

## Methods

| Method | Description |
|--------|-------------|
| `isAvailable` | Check BLE support |
| `isOn` | Check if Bluetooth is enabled |
| `startScan` | Start BLE scan |
| `stopScan` | Stop scanning |
| `connect` | Connect to device by ID |
| `disconnect` | Disconnect from device |
| `discoverServices` | List services & characteristics |
| `readCharacteristic` | Read value |
| `writeCharacteristic` | Write value (base64) |
| `getConnectedDevices` | List connected devices |

## Events
- `bluetooth.deviceFound` — `{ deviceId, name, rssi }`
- `bluetooth.connectionState` — `{ deviceId, state, connected }`

## Usage
```javascript
await NativeSDK.bluetooth.startScan({ timeoutSeconds: 10 });
NativeSDK.on('bluetooth.deviceFound', async (device) => {
  if (device.name === 'MySensor') {
    await NativeSDK.bluetooth.connect(device.deviceId);
    const services = await NativeSDK.bluetooth.discoverServices(device.deviceId);
    const value = await NativeSDK.bluetooth.readCharacteristic({
      deviceId: device.deviceId,
      serviceUuid: '180d',
      characteristicUuid: '2a37'
    });
  }
});
```
```

---

## 📄 `lib/plugins/nfc/README.md`

```markdown
# NFC Plugin

Read and write NFC tags.

## Plugin Name
`nfc`

## Methods

| Method | Description |
|--------|-------------|
| `isAvailable` | Check NFC support |
| `startSession` | Start NFC read session |
| `stopSession` | Stop session |
| `writeText` | Write text to NFC tag |
| `writeUri` | Write URL to NFC tag |

## Events
- `nfc.tagDiscovered` — `{ id, type, records, isWritable }`
- `nfc.error` — `{ message }`

## Usage
```javascript
const tag = await NativeSDK.nfc.startSession({ readOnce: true });
console.log('Tag ID:', tag.id);
console.log('Content:', tag.records[0]?.payloadString);

// Write
await NativeSDK.nfc.writeText('Hello NFC');
await NativeSDK.nfc.writeUri('https://example.com');
```
```

---

## 📄 `lib/plugins/speech_to_text/README.md`

```markdown
# Speech to Text Plugin

Voice recognition / dictation.

## Plugin Name
`speechToText`

## Methods

| Method | Description |
|--------|-------------|
| `initialize` | Initialize engine |
| `startListening` | Start voice recognition |
| `stopListening` | Stop recognition |
| `cancelListening` | Cancel |
| `getLocales` | Get supported languages |

### startListening Args
| Param | Type | Default |
|-------|------|---------|
| `locale` | `string` | device default |
| `listenForSeconds` | `number` | `30` |
| `pauseForSeconds` | `number` | `3` |
| `partialResults` | `bool` | `true` |

## Events
- `speechToText.result` — `{ text, confidence, finalResult, alternates }`
- `speechToText.status` — `{ status, listening }`
- `speechToText.error` — `{ message, permanent }`

## Usage
```javascript
await NativeSDK.speechToText.initialize();
const result = await NativeSDK.speechToText.startListening({ locale: 'fa-IR' });
console.log('You said:', result.text);

// Or with events for real-time
NativeSDK.on('speechToText.result', (data) => {
  searchInput.value = data.text;
});
```
```

---

## 📄 `lib/plugins/text_to_speech/README.md`

```markdown
# Text to Speech Plugin

Read text aloud using system TTS engine.

## Plugin Name
`textToSpeech`

## Methods

| Method | Args |
|--------|------|
| `speak` | `text, language?, rate?, pitch?, volume?` |
| `stop` | — |
| `pause` | — |
| `setLanguage` | `language` (e.g. `"en-US"`, `"fa-IR"`) |
| `setSpeechRate` | `rate` (0.0 - 2.0, default 0.5) |
| `setPitch` | `pitch` (0.5 - 2.0, default 1.0) |
| `setVolume` | `volume` (0.0 - 1.0) |
| `getLanguages` | List available languages |
| `getVoices` | List available voices |

## Events
- `tts.start`, `tts.complete`, `tts.cancel`, `tts.error`
- `tts.progress` — `{ text, start, end, word }`

## Usage
```javascript
await NativeSDK.textToSpeech.speak('سلام دنیا', { language: 'fa-IR', rate: 0.5 });

NativeSDK.on('tts.complete', () => {
  console.log('Finished speaking');
});
```
```

---

## 📄 `lib/plugins/video_player/README.md`

```markdown
# Video Player Plugin

Play video from URL or local file (headless — audio only, no visual widget in WebView).

## Plugin Name
`videoPlayer`

## Methods

| Method | Args |
|--------|------|
| `create` | `url or path, autoPlay?, looping?, volume?` |
| `play` | `playerId` |
| `pause` | `playerId` |
| `seekTo` | `playerId, positionMs` |
| `setVolume` | `playerId, volume (0-1)` |
| `setPlaybackSpeed` | `playerId, speed (0.25-4.0)` |
| `setLooping` | `playerId, looping` |
| `getPosition` | `playerId` |
| `getDuration` | `playerId` |
| `getState` | `playerId` — full state object |
| `dispose` | `playerId` |
| `disposeAll` | — |

## Events
### `videoPlayer.state`
```json
{ "playerId": "...", "isPlaying": true, "positionMs": 5000, "durationMs": 120000 }
```

## Usage
```javascript
const player = await NativeSDK.videoPlayer.create({
  url: 'https://example.com/video.mp4',
  autoPlay: true
});

// Control
await NativeSDK.videoPlayer.seekTo(player.playerId, 30000);
await NativeSDK.videoPlayer.setPlaybackSpeed(player.playerId, 1.5);

// Cleanup
await NativeSDK.videoPlayer.dispose(player.playerId);
```
```

---

## 📄 `lib/plugins/in_app_browser/README.md`

```markdown
# In-App Browser Plugin

Open external web pages inside the app (for OAuth, payment, etc).

## Plugin Name
`inAppBrowser`

## Methods

### `open`
| Param | Type | Required | Default |
|-------|------|----------|---------|
| `url` | `string` | ✅ | — |
| `title` | `string` | — | `""` |
| `showToolbar` | `bool` | — | `true` |
| `closeOnUrlMatch` | `string` | — | — |

**Returns** (when browser is closed):
```json
{ "closed": true, "reason": "user_closed", "lastUrl": "..." }
```

## Events
- `inAppBrowser.loadStop` — `{ url }`
- `inAppBrowser.error` — `{ url, code, message }`

## Usage
```javascript
// OAuth flow
const result = await NativeSDK.inAppBrowser.open({
  url: 'https://accounts.google.com/o/oauth2/v2/auth?...',
  title: 'Sign in with Google',
  closeOnUrlMatch: 'myapp://callback'
});

// result.lastUrl contains the callback URL with token
const token = extractTokenFromUrl(result.lastUrl);
```
```

---

## 📄 `lib/plugins/pdf_plugin/README.md`

```markdown
# PDF Plugin

Generate PDF from text or HTML, print and share.

## Plugin Name
`pdf`

## Methods

### `generateFromText`
| Param | Type | Default |
|-------|------|---------|
| `text` | `string` | — |
| `title` | `string` | `"Document"` |
| `fileName` | `string` | auto |
| `fontSize` | `number` | `12` |

**Returns:** `{ generated: true, path: "...", size: 1234 }`

### `generateFromHtml`
| Param | Type |
|-------|------|
| `html` | `string` |
| `fileName` | `string` |

### `print`
| Param | Type | Description |
|-------|------|-------------|
| `path` | `string` | Print existing PDF |
| `html` | `string` | Print from HTML |
| `name` | `string` | Print job name |

### `share`
Share PDF file via native share sheet.

## Usage
```javascript
// Generate from text
const pdf = await NativeSDK.pdf.generateFromText(
  'This is my report content...',
  { title: 'Monthly Report', fontSize: 14 }
);

// Generate from HTML
const invoice = await NativeSDK.pdf.generateFromHtml({
  html: '<h1>Invoice #123</h1><p>Total: $500</p>'
});

// Print
await NativeSDK.pdf.print({ path: pdf.path, name: 'Report' });

// Share
await NativeSDK.pdf.share(pdf.path);
```
```

---

## 📄 `lib/plugins/encryption/README.md`

```markdown
# Encryption Plugin

AES encryption, SHA/MD5 hashing, HMAC, and random bytes.

## Plugin Name
`encryption`

## Methods

### AES Encryption
| Method | Args | Returns |
|--------|------|---------|
| `generateAesKey` | `bits? (128/256)` | `{ key, iv }` (base64) |
| `aesEncrypt` | `data, key, iv?` | `{ encrypted, iv }` (base64) |
| `aesDecrypt` | `data, key, iv` | `{ decrypted }` |

### Hashing
| Method | Args | Returns |
|--------|------|---------|
| `hashSha256` | `data` | `{ hash, base64 }` |
| `hashSha512` | `data` | `{ hash, base64 }` |
| `hashMd5` | `data` | `{ hash, base64 }` |
| `hmacSha256` | `data, key` | `{ hmac, base64 }` |

### Utility
| Method | Args | Returns |
|--------|------|---------|
| `generateRandomBytes` | `length?` | `{ hex, base64 }` |
| `base64Encode` | `data` | `{ encoded }` |
| `base64Decode` | `data` | `{ decoded }` |

## Usage
```javascript
// Generate key
const { key, iv } = await NativeSDK.encryption.generateAesKey(256);

// Encrypt
const { encrypted } = await NativeSDK.encryption.aesEncrypt('Hello World', key, iv);

// Decrypt
const { decrypted } = await NativeSDK.encryption.aesDecrypt(encrypted, key, iv);

// Hash
const { hash } = await NativeSDK.encryption.hashSha256('password123');

// HMAC for API signing
const { hmac } = await NativeSDK.encryption.hmacSha256(
  JSON.stringify(requestBody),
  apiSecret
);
```
```

---

# خلاصه نهایی

## آمار پروژه

| آیتم | تعداد |
|------|-------|
| **پلاگین‌ها** | 35 |
| **Eventها** | 32 |
| **متدهای JS** | 200+ |
| **فایل‌های Dart** | 50+ |
| **فایل‌های JS** | 4 |
| **README فایل‌ها** | 36 (1 اصلی + 35 پلاگین) |

## ساختار فایل README‌ها

```
sweetmelon/
├── README.md                              ← اصلی
├── docs/angular-integration.md
├── lib/plugins/permission/README.md
├── lib/plugins/app_lifecycle/README.md
├── lib/plugins/device_info/README.md
├── lib/plugins/connectivity/README.md
├── lib/plugins/storage/README.md
├── lib/plugins/file_system/README.md
├── lib/plugins/http_native/README.md
├── lib/plugins/intent_link/README.md
├── lib/plugins/clipboard/README.md
├── lib/plugins/share/README.md
├── lib/plugins/camera/README.md
├── lib/plugins/geolocation/README.md
├── lib/plugins/back_button/README.md
├── lib/plugins/secure_storage/README.md
├── lib/plugins/notification/README.md
├── lib/plugins/status_bar/README.md
├── lib/plugins/orientation/README.md
├── lib/plugins/haptic/README.md
├── lib/plugins/keyboard/README.md
├── lib/plugins/biometrics/README.md
├── lib/plugins/qr_scanner/README.md
├── lib/plugins/audio/README.md
├── lib/plugins/sms_otp/README.md
├── lib/plugins/download_manager/README.md
├── lib/plugins/database/README.md
├── lib/plugins/contacts/README.md
├── lib/plugins/phone_dialer/README.md
├── lib/plugins/bluetooth/README.md
├── lib/plugins/nfc/README.md
├── lib/plugins/speech_to_text/README.md
├── lib/plugins/text_to_speech/README.md
├── lib/plugins/video_player/README.md
├── lib/plugins/in_app_browser/README.md
├── lib/plugins/pdf_plugin/README.md
└── lib/plugins/encryption/README.md
```
