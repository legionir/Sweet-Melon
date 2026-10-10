بذار بررسی دقیق کنم.

---

# بررسی وضعیت README پلاگین‌ها

## پلاگین‌هایی که README دارن ✅

در **فاز جمع‌بندی README** (که بعد از فاز ۱۱ فرستادم)، این پلاگین‌ها README کامل دارن:

| # | پلاگین | وضعیت |
|---|--------|--------|
| 1 | permission | ✅ کامل |
| 2 | appLifecycle | ✅ کامل |
| 3 | deviceInfo | ✅ کامل |
| 4 | connectivity | ✅ کامل |
| 5 | storage | ✅ کامل |
| 6 | fileSystem | ✅ کامل |
| 7 | http | ✅ کامل |
| 8 | intent | ✅ کامل |
| 9 | clipboard | ✅ کامل |
| 10 | share | ✅ کامل |
| 11 | camera | ✅ کامل |
| 12 | geolocation | ✅ کامل |
| 13 | backButton | ✅ کامل |
| 14 | secureStorage | ✅ کامل |
| 15 | notification | ✅ کامل |
| 16 | statusBar | ✅ کامل |
| 17 | orientation | ✅ کامل |
| 18 | haptic | ✅ کامل |
| 19 | keyboard | ✅ کامل |
| 20 | biometrics | ✅ کامل |
| 21 | qrScanner | ✅ کامل |
| 22 | audio | ✅ کامل |
| 23 | smsOtp | ✅ کامل |
| 24 | downloadManager | ✅ کامل |
| 25 | database | ✅ کامل |
| 26 | contacts | ✅ کامل |
| 27 | phoneDialer | ✅ کامل |
| 28 | bluetooth | ✅ کامل |
| 29 | nfc | ✅ کامل |
| 30 | speechToText | ✅ کامل |
| 31 | textToSpeech | ✅ کامل |
| 32 | videoPlayer | ✅ کامل |
| 33 | inAppBrowser | ✅ کامل |
| 34 | pdf | ✅ کامل |
| 35 | encryption | ✅ کامل |

---

## پلاگین‌هایی که README ندارن ❌

اینا فازهای ۶ تا ۱۷+ بودن و README براشون نوشته نشد:

| # | پلاگین | فاز |
|---|--------|------|
| 36 | websocket | ۶ |
| 37 | backgroundTask | ۶ |
| 38 | dialog | ۷ |
| 39 | toast | ۷ |
| 40 | splashScreen | ۷ |
| 41 | pushNotification | ۷/۱۶ |
| 42 | wakeLock | ۷ |
| 43 | cookieManager | ۷ |
| 44 | cacheControl | ۷ |
| 45 | appUpdate | ۷ |
| 46 | filePicker | ۸ |
| 47 | fileOpener | ۸ |
| 48 | sensors | ۸ |
| 49 | screenBrightness | ۸ |
| 50 | flashlight | ۸ |
| 51 | navigationBar | ۸ |
| 52 | privacyScreen | ۸ |
| 53 | nativeSettings | ۸ |
| 54 | calendar | ۹ |
| 55 | badge | ۹ |
| 56 | foregroundService | ۹ |
| 57 | backgroundGeolocation | ۹ |
| 58 | mediaManager | ۹ |
| 59 | fileCompressor | ۹ |
| 60 | zip | ۹ |
| 61 | shareTarget | ۹ |
| 62 | inAppReview | ۱۰ |
| 63 | nativeMarket | ۱۰ |
| 64 | screenshot | ۱۰ |
| 65 | safeArea | ۱۰ |
| 66 | datePicker | ۱۰ |
| 67 | actionSheet | ۱۰ |
| 68 | textZoom | ۱۰ |
| 69 | accessibility | ۱۰ |
| 70 | wifiManager | ۱۱ |
| 71 | rootDetection | ۱۱ |
| 72 | appIntegrity | ۱۱ |
| 73 | alarm | ۱۱ |
| 74 | pedometer | ۱۱ |
| 75 | shakeDetection | ۱۱ |
| 76 | volumeButtons | ۱۱ |
| 77 | simInfo | ۱۱ |
| 78 | kioskMode | ۱۱ |
| 79 | intentLauncher | ۱۱ |
| 80 | emailComposer | ۱۱ |
| 81 | firebaseAnalytics | ۱۶ |
| 82 | firebaseCrashlytics | ۱۶ |
| 83 | firebaseRemoteConfig | ۱۶ |
| 84 | firebaseAuth | ۱۶ |
| 85 | cameraPreview | ۱۷ |
| 86 | documentScanner | ۱۷ |
| 87 | googleMaps | ۱۷ |
| 88 | socialLogin | ۱۷ |
| 89 | inAppPurchase | ۱۷ |
| 90 | oauth2 | ۱۷ |
| 91 | liveUpdater | آخرین |

---

الان همه **۵۶ تا README** نداشته رو می‌نویسم. به خاطر حجم، در چند پیام می‌فرستم.

---

# README‌های فاز ۶

## 📄 `lib/plugins/websocket/README.md`

```markdown
# WebSocket Plugin

Real-time bidirectional communication over WebSocket.

## Plugin Name
`websocket`

## Methods

### `connect`
| Param | Type | Required | Default |
|-------|------|----------|---------|
| `url` | `string` | ✅ | — |
| `id` | `string` | — | auto |
| `protocols` | `string[]` | — | — |
| `headers` | `object` | — | — |
| `autoReconnect` | `bool` | — | `false` |
| `maxReconnectAttempts` | `number` | — | `5` |
| `reconnectDelayMs` | `number` | — | `3000` |
| `pingIntervalMs` | `number` | — | — |

**Returns:**
```json
{ "id": "ws_123", "connected": true, "lensDirection": "back" }
```

### `disconnect`
| Param | Type | Required |
|-------|------|----------|
| `id` | `string` | ✅ |
| `code` | `number` | — |
| `reason` | `string` | — |

### `send`
| Param | Type | Required |
|-------|------|----------|
| `id` | `string` | ✅ |
| `data` | `any` | ✅ |

### `sendJson`
| Param | Type | Required |
|-------|------|----------|
| `id` | `string` | ✅ |
| `data` | `object` | ✅ |

### `getState` / `getConnections` / `disconnectAll`

## Events
| Event | Data |
|-------|------|
| `websocket.connected` | `{ id, url }` |
| `websocket.message` | `{ id, data, type, messageNumber }` |
| `websocket.disconnected` | `{ id, closeCode, closeReason }` |
| `websocket.error` | `{ id, error, type }` |
| `websocket.reconnecting` | `{ id, attempt, maxAttempts, delayMs }` |

## Usage
```javascript
// Connect
const { id } = await NativeSDK.websocket.connect({
  url: 'wss://echo.example.com',
  autoReconnect: true,
  maxReconnectAttempts: 5
});

// Listen
NativeSDK.on('websocket.message', (data) => {
  console.log('Received:', data.data);
});

NativeSDK.on('websocket.disconnected', (data) => {
  console.log('Disconnected:', data.closeCode);
});

// Send
await NativeSDK.websocket.sendJson(id, { action: 'ping' });
await NativeSDK.websocket.send(id, 'Hello!');

// Disconnect
await NativeSDK.websocket.disconnect(id);
```
```

---

## 📄 `lib/plugins/background_task/README.md`

```markdown
# Background Task Plugin

Schedule and run background tasks with custom actions.

## Plugin Name
`backgroundTask`

## Methods

### `register`
| Param | Type | Required |
|-------|------|----------|
| `taskId` | `string` | ✅ |
| `name` | `string` | — |
| `params` | `object` | — |

### `runOnce`
| Param | Type | Required | Default |
|-------|------|----------|---------|
| `taskId` | `string` | ✅ | — |
| `action` | `string` | — | `execute` |
| `params` | `object` | — | — |
| `timeoutMs` | `number` | — | `30000` |

**Actions:** `execute`, `httpSync`, `storageCleanup`, `cacheCleanup`, `compute`

### `startRepeating`
| Param | Type | Required | Default |
|-------|------|----------|---------|
| `taskId` | `string` | ✅ | — |
| `intervalMs` | `number` | ✅ (min 1000) | — |
| `action` | `string` | — | `execute` |
| `immediate` | `bool` | — | `true` |

### `stop` / `stopAll` / `unregister` / `getTaskState` / `getAllTasks`

## Events
| Event | Data |
|-------|------|
| `task.started` | `{ taskId, action, runCount }` |
| `task.completed` | `{ taskId, durationMs, result }` |
| `task.failed` | `{ taskId, error, durationMs }` |

## Usage
```javascript
// Register and run once
await NativeSDK.backgroundTask.register('sync_task', { name: 'Data Sync' });
const result = await NativeSDK.backgroundTask.runOnce('sync_task', {
  action: 'httpSync',
  params: { url: 'https://api.example.com/sync' }
});

// Repeating task (every 5 minutes)
await NativeSDK.backgroundTask.startRepeating('cleanup', 300000, {
  action: 'storageCleanup',
  params: { olderThanDays: 7 }
});

// Listen
NativeSDK.on('task.completed', (data) => {
  console.log('Task done:', data.taskId, data.durationMs + 'ms');
});

// Stop
await NativeSDK.backgroundTask.stop('cleanup');
await NativeSDK.backgroundTask.stopAll();
```
```

---

# README‌های فاز ۷

## 📄 `lib/plugins/dialog/README.md`

```markdown
# Dialog Plugin

Native dialog windows for alerts, confirmations, and prompts.

## Plugin Name
`dialog`

## Methods

### `alert`
| Param | Type | Default |
|-------|------|---------|
| `message` | `string` | ✅ |
| `title` | `string` | — |
| `buttonTitle` | `string` | `"OK"` |

**Returns:** `{ dismissed: true }`

### `confirm`
| Param | Type | Default |
|-------|------|---------|
| `message` | `string` | ✅ |
| `title` | `string` | — |
| `okButtonTitle` | `string` | `"OK"` |
| `cancelButtonTitle` | `string` | `"Cancel"` |

**Returns:** `{ confirmed: true/false }`

### `prompt`
| Param | Type | Default |
|-------|------|---------|
| `message` | `string` | — |
| `title` | `string` | — |
| `placeholder` | `string` | — |
| `defaultValue` | `string` | — |
| `inputType` | `string` | `"text"` |
| `maxLength` | `number` | — |
| `okButtonTitle` | `string` | `"OK"` |
| `cancelButtonTitle` | `string` | `"Cancel"` |

**inputType:** `text`, `number`, `phone`, `email`, `url`, `multiline`, `password`

**Returns:** `{ cancelled: false, value: "user input" }`

## Usage
```javascript
// Alert
await NativeSDK.dialog.alert({
  title: 'Success',
  message: 'Your data has been saved.'
});

// Confirm
const { confirmed } = await NativeSDK.dialog.confirm({
  title: 'Delete',
  message: 'Are you sure you want to delete this item?',
  okButtonTitle: 'Delete',
  cancelButtonTitle: 'Cancel'
});
if (confirmed) deleteItem();

// Prompt
const { cancelled, value } = await NativeSDK.dialog.prompt({
  title: 'Enter Name',
  placeholder: 'Your full name',
  inputType: 'text'
});
if (!cancelled && value) setUserName(value);
```
```

---

## 📄 `lib/plugins/toast/README.md`

```markdown
# Toast Plugin

Native toast notification messages.

## Plugin Name
`toast`

## Methods

### `show`
| Param | Type | Required | Default |
|-------|------|----------|---------|
| `text` | `string` | ✅ | — |
| `duration` | `string` | — | `"short"` |
| `position` | `string` | — | `"bottom"` |
| `backgroundColor` | `string` | — | `"#323232"` |
| `textColor` | `string` | — | `"#FFFFFF"` |

**duration:** `"short"` (2s) or `"long"` (4s)
**position:** `"bottom"` or `"top"`

## Usage
```javascript
// Simple
await NativeSDK.toast.show('Saved successfully!');

// Custom
await NativeSDK.toast.show('Error occurred', {
  duration: 'long',
  position: 'top',
  backgroundColor: '#F44336',
  textColor: '#FFFFFF'
});

await NativeSDK.toast.show('✓ Copied to clipboard', {
  duration: 'short',
  backgroundColor: '#4CAF50'
});
```
```

---

## 📄 `lib/plugins/splash_screen/README.md`

```markdown
# Splash Screen Plugin

Control splash screen visibility and auto-hide behavior.

## Plugin Name
`splashScreen`

## Methods

### `show`
| Param | Type | Default |
|-------|------|---------|
| `fadeInDurationMs` | `number` | `200` |

### `hide`
Hides the splash screen.

### `setAutoHide`
| Param | Type | Default |
|-------|------|---------|
| `enabled` | `bool` | `true` |
| `delayMs` | `number` | `3000` |

### `isVisible`
**Returns:** `{ visible: true/false }`

## Events
| Event | Data |
|-------|------|
| `splash.shown` | `{ timestamp }` |
| `splash.hidden` | `{ timestamp }` |

## Usage
```javascript
// Hide after app is ready
NativeSDK.waitForReady().then(async () => {
  await loadData();           // load your data first
  await NativeSDK.splashScreen.hide();  // then hide splash
});

// Auto-hide after 3 seconds
await NativeSDK.splashScreen.setAutoHide(true, 3000);

// Manual control
await NativeSDK.splashScreen.show();
setTimeout(() => NativeSDK.splashScreen.hide(), 2000);
```
```

---

## 📄 `lib/plugins/push_notification/README.md`

```markdown
# Push Notification Plugin (FCM)

Firebase Cloud Messaging push notifications.

## Plugin Name
`pushNotification`

## Methods

### `register`
Register device and get FCM token.

**Returns:**
```json
{ "registered": true, "token": "fcm_token_here", "permissionGranted": true }
```

### `getToken`
| Param | Type |
|-------|------|
| `vapidKey` | `string` (optional) |

### `requestPermission`
| Param | Type | Default |
|-------|------|---------|
| `alert` | `bool` | `true` |
| `badge` | `bool` | `true` |
| `sound` | `bool` | `true` |

### `subscribe` / `unsubscribe`
| Param | Type | Required |
|-------|------|----------|
| `topic` | `string` | ✅ |

### `getDeliveredNotifications`
### `removeDeliveredNotifications`
| Param | Type |
|-------|------|
| `ids` | `string[]` |

### `removeAllDeliveredNotifications`
### `getInitialMessage` — Get notification that opened the app
### `deleteToken`

## Events
| Event | Data |
|-------|------|
| `push.registered` | `{ token }` |
| `push.received` | `{ title, body, data, foreground }` |
| `push.tap` | `{ title, body, data }` |
| `push.localTap` | `{ id, payload }` |
| `push.tokenRefreshed` | `{ token }` |

## Setup Required
1. Add `google-services.json` to `android/app/`
2. Initialize Firebase in `main.dart`

## Usage
```javascript
// Register and get token
const { token } = await NativeSDK.pushNotification.register();
// Send token to your backend
await sendToServer(token);

// Subscribe to topics
await NativeSDK.pushNotification.subscribe('news');
await NativeSDK.pushNotification.subscribe('promotions');

// Handle incoming notifications
NativeSDK.on('push.received', (data) => {
  showInAppBanner(data.title, data.body);
});

// Handle tap on notification
NativeSDK.on('push.tap', (data) => {
  router.navigate('/notification?id=' + data.data.id);
});

// Check initial notification (app opened from notification)
const initial = await NativeSDK.pushNotification.getInitialMessage();
if (initial.available) {
  router.navigate('/notification', initial.message.data);
}
```
```

---

## 📄 `lib/plugins/wake_lock/README.md`

```markdown
# Wake Lock Plugin

Keep device screen on during active operations.

## Plugin Name
`wakeLock`

## Methods

| Method | Description | Returns |
|--------|-------------|---------|
| `enable` | Keep screen on | `{ enabled: true }` |
| `disable` | Allow screen to sleep | `{ enabled: false }` |
| `toggle` | Toggle current state | current state |
| `isEnabled` | Check current state | `{ enabled: bool }` |

## Usage
```javascript
// Video player — keep screen on
await NativeSDK.wakeLock.enable();
playVideo();

NativeSDK.on('videoPlayer.state', (state) => {
  if (!state.isPlaying) {
    NativeSDK.wakeLock.disable();
  }
});

// Navigation
await NativeSDK.wakeLock.enable();
startNavigation();

// QR Scanner
await NativeSDK.wakeLock.enable();
const result = await NativeSDK.qrScanner.scan();
await NativeSDK.wakeLock.disable();

// Always disable when done
window.addEventListener('beforeunload', () => {
  NativeSDK.wakeLock.disable();
});
```
```

---

## 📄 `lib/plugins/cookie_manager/README.md`

```markdown
# Cookie Manager Plugin

Manage WebView cookies and sessions.

## Plugin Name
`cookieManager`

## Methods

### `setCookie`
| Param | Type | Required | Default |
|-------|------|----------|---------|
| `domain` | `string` | ✅ | — |
| `name` | `string` | ✅ | — |
| `value` | `string` | ✅ | — |
| `path` | `string` | — | `"/"` |
| `secure` | `bool` | — | `false` |
| `httpOnly` | `bool` | — | `false` |

### `clearCookies`
Clear all WebView cookies.

### `clearSession`
Clear session cookies.

## Usage
```javascript
// Set auth cookie for API domain
await NativeSDK.cookieManager.setCookie({
  domain: 'api.myapp.com',
  name: 'auth_token',
  value: 'Bearer eyJhbGc...',
  secure: true,
  httpOnly: true
});

// On logout
await NativeSDK.cookieManager.clearCookies();
router.navigate('/login');

// Clear only session
await NativeSDK.cookieManager.clearSession();
```
```

---

## 📄 `lib/plugins/cache_control/README.md`

```markdown
# Cache Control Plugin

Control WebView and app cache.

## Plugin Name
`cacheControl`

## Methods

### `clearWebViewCache`
Clear WebView HTTP cache and local storage.

### `clearAppCache`
Delete files in app cache directory.

### `getCacheSize`
**Returns:**
```json
{
  "cache": { "bytes": 1234567, "formatted": "1.2MB", "files": 45 },
  "temp": { "bytes": 234567, "formatted": "234KB", "files": 12 },
  "total": { "bytes": 1469134, "formatted": "1.4MB", "files": 57 }
}
```

### `clearAll`
Clear WebView cache + app cache + temp files.

## Usage
```javascript
// Check cache size
const { total } = await NativeSDK.cacheControl.getCacheSize();
console.log('Cache:', total.formatted);  // "1.4MB"

// Clear before forced update
await NativeSDK.cacheControl.clearWebViewCache();
location.reload();

// Full cleanup
const result = await NativeSDK.cacheControl.clearAll();
console.log('Freed:', result.appCache.bytesFreedFormatted);

// Settings page - clear cache button
document.getElementById('clearCacheBtn').onclick = async () => {
  await NativeSDK.cacheControl.clearAll();
  await NativeSDK.toast.show('Cache cleared!');
};
```
```

---

## 📄 `lib/plugins/app_update/README.md`

```markdown
# App Update Plugin

Check for app updates and open store.

## Plugin Name
`appUpdate`

## Methods

### `configure`
| Param | Type | Description |
|-------|------|-------------|
| `updateCheckUrl` | `string` | Your server endpoint |
| `playStoreUrl` | `string` | Play Store URL |

### `getCurrentVersion`
**Returns:**
```json
{ "version": "1.2.0", "buildNumber": "45", "packageName": "com.example.app" }
```

### `checkForUpdate`
| Param | Type |
|-------|------|
| `url` | `string` (override) |

**Server Response Expected:**
```json
{
  "latestVersion": "1.3.0",
  "minVersion": "1.1.0",
  "forceUpdate": false,
  "releaseNotes": "Bug fixes",
  "storeUrl": "https://play.google.com/..."
}
```

**Returns:**
```json
{
  "updateAvailable": true,
  "mustUpdate": false,
  "currentVersion": "1.2.0",
  "latestVersion": "1.3.0",
  "releaseNotes": "Bug fixes"
}
```

### `openStore`
| Param | Type |
|-------|------|
| `url` | `string` (optional) |

### `getLastCheckResult`

## Events
| Event | Data |
|-------|------|
| `appUpdate.available` | full check result |

## Usage
```javascript
await NativeSDK.appUpdate.configure({
  updateCheckUrl: 'https://api.myapp.com/version'
});

const update = await NativeSDK.appUpdate.checkForUpdate();

if (update.mustUpdate) {
  await NativeSDK.dialog.alert({
    title: 'Update Required',
    message: 'Please update the app to continue.'
  });
  await NativeSDK.appUpdate.openStore();
} else if (update.updateAvailable) {
  const { confirmed } = await NativeSDK.dialog.confirm({
    title: 'Update Available',
    message: `Version ${update.latestVersion} is available. Update now?`
  });
  if (confirmed) await NativeSDK.appUpdate.openStore();
}
```
```

---

# README‌های فاز ۸

## 📄 `lib/plugins/file_picker/README.md`

```markdown
# File Picker Plugin

Pick files, images, videos from device storage.

## Plugin Name
`filePicker`

## Methods

### `pickFiles`
| Param | Type | Default |
|-------|------|---------|
| `multiple` | `bool` | `false` |
| `type` | `string` | `"any"` |
| `allowedExtensions` | `string[]` | — |

**type:** `any`, `image`, `video`, `audio`, `media`

### `pickImages` / `pickVideos` / `pickMedia`
Shortcuts for `pickFiles` with type preset.

### `pickDirectory`
Pick a directory path.

**Returns:**
```json
{
  "picked": true,
  "files": [
    { "name": "doc.pdf", "path": "/...", "size": 12345, "extension": "pdf" }
  ],
  "count": 1
}
```

## Usage
```javascript
// Pick any file
const { files } = await NativeSDK.filePicker.pickFiles();

// Pick images only
const { files } = await NativeSDK.filePicker.pickImages({ multiple: true });

// Pick specific extensions
const { files } = await NativeSDK.filePicker.pickFiles({
  allowedExtensions: ['pdf', 'doc', 'docx', 'xlsx'],
  multiple: true
});

// Upload picked file
if (files.length > 0) {
  const file = files[0];
  const formData = new FormData();
  formData.append('file', { uri: file.path, name: file.name });
  await fetch('/upload', { method: 'POST', body: formData });
}

// Pick directory
const { path } = await NativeSDK.filePicker.pickDirectory();
console.log('Selected dir:', path);
```
```

---

## 📄 `lib/plugins/file_opener/README.md`

```markdown
# File Opener Plugin

Open files with appropriate system apps.

## Plugin Name
`fileOpener`

## Methods

### `open`
| Param | Type | Required |
|-------|------|----------|
| `path` | `string` | ✅ |
| `mimeType` | `string` | — (auto-detect) |

### `canOpen`
Check if file can be opened.

### `getMimeType`
Get MIME type from file path.

## Usage
```javascript
// Open PDF
await NativeSDK.fileOpener.open('/storage/docs/report.pdf');

// Open image
await NativeSDK.fileOpener.open('/storage/photo.jpg', 'image/jpeg');

// Check before opening
const { canOpen } = await NativeSDK.fileOpener.canOpen('/path/to/file.xyz');
if (canOpen) {
  await NativeSDK.fileOpener.open('/path/to/file.xyz');
} else {
  await NativeSDK.toast.show('No app can open this file type');
}

// Get MIME type
const { mimeType } = NativeSDK.fileOpener.getMimeType('/file.mp4');
// "video/mp4"

// Workflow: download then open
const dl = await NativeSDK.http.download({ url: 'https://example.com/doc.pdf' });
if (dl.saved) await NativeSDK.fileOpener.open(dl.path);
```
```

---

## 📄 `lib/plugins/sensors/README.md`

```markdown
# Sensors Plugin

Access device motion and orientation sensors.

## Plugin Name
`sensors`

## Methods

| Method | Sensor | Description |
|--------|--------|-------------|
| `startAccelerometer` | Accelerometer | gravity + motion (m/s²) |
| `stopAccelerometer` | — | — |
| `startGyroscope` | Gyroscope | rotation rate (rad/s) |
| `stopGyroscope` | — | — |
| `startMagnetometer` | Magnetometer | magnetic field (μT) |
| `stopMagnetometer` | — | — |
| `startUserAccelerometer` | User Accel | motion without gravity |
| `stopUserAccelerometer` | — | — |
| `stopAll` | — | stop all sensors |
| `getActiveStreams` | — | list active sensors |

**Options for all start methods:**
| Param | Type | Default |
|-------|------|---------|
| `intervalMs` | `number` | `100` |

## Events
| Event | Data |
|-------|------|
| `sensors.accelerometer` | `{ x, y, z, timestamp }` |
| `sensors.gyroscope` | `{ x, y, z, timestamp }` |
| `sensors.magnetometer` | `{ x, y, z, timestamp }` |
| `sensors.userAccelerometer` | `{ x, y, z, timestamp }` |

## Usage
```javascript
// Shake detection (manual)
let lastX = 0, lastY = 0, lastZ = 0;
await NativeSDK.sensors.startAccelerometer({ intervalMs: 50 });
NativeSDK.on('sensors.accelerometer', (data) => {
  const delta = Math.abs(data.x - lastX) + Math.abs(data.y - lastY);
  if (delta > 15) console.log('Shake!');
  lastX = data.x; lastY = data.y; lastZ = data.z;
});

// Compass heading
await NativeSDK.sensors.startMagnetometer({ intervalMs: 200 });
NativeSDK.on('sensors.magnetometer', (data) => {
  const heading = Math.atan2(data.y, data.x) * (180 / Math.PI);
  updateCompass(heading);
});

// Gyroscope for rotation
await NativeSDK.sensors.startGyroscope({ intervalMs: 100 });
NativeSDK.on('sensors.gyroscope', (data) => {
  rotateObject(data.x, data.y, data.z);
});

// Cleanup
await NativeSDK.sensors.stopAll();
```
```

---

## 📄 `lib/plugins/screen_brightness/README.md`

```markdown
# Screen Brightness Plugin

Control device screen brightness.

## Plugin Name
`screenBrightness`

## Methods

| Method | Args | Returns |
|--------|------|---------|
| `get` | — | `{ brightness: 0.8 }` |
| `set` | `brightness: 0.0-1.0` | `{ brightness, set }` |
| `reset` | — | `{ reset: true }` |
| `getSystem` | — | `{ brightness: 0.5 }` |
| `setAutoReset` | `enabled: bool` | `{ autoReset }` |

## Usage
```javascript
// Get current brightness
const { brightness } = await NativeSDK.screenBrightness.get();
console.log('Current:', Math.round(brightness * 100) + '%');

// Max brightness for QR scanner
await NativeSDK.screenBrightness.set(1.0);
const qr = await NativeSDK.qrScanner.scan();
await NativeSDK.screenBrightness.reset();  // restore

// Video player adaptive brightness
NativeSDK.on('app.lifecycle.change', async (state) => {
  if (state.state === 'resumed') {
    await NativeSDK.screenBrightness.set(0.7);
  }
});

// Auto-reset when app closes
await NativeSDK.screenBrightness.setAutoReset(true);
```
```

---

## 📄 `lib/plugins/flashlight/README.md`

```markdown
# Flashlight Plugin

Control device camera flashlight/torch.

## Plugin Name
`flashlight`

## Methods

| Method | Returns |
|--------|---------|
| `enable` | `{ enabled: true }` |
| `disable` | `{ enabled: false }` |
| `toggle` | current state |
| `isAvailable` | `{ available: bool }` |
| `isEnabled` | `{ enabled: bool }` |

## Usage
```javascript
// Check support
const { available } = await NativeSDK.flashlight.isAvailable();
if (!available) {
  await NativeSDK.toast.show('No flashlight available');
  return;
}

// Toggle button
document.getElementById('torchBtn').onclick = async () => {
  const { enabled } = await NativeSDK.flashlight.toggle();
  torchBtn.textContent = enabled ? '🔦 ON' : '🔦 OFF';
};

// Auto off when app goes to background
NativeSDK.on('app.lifecycle.change', async (state) => {
  if (state.state === 'paused') {
    await NativeSDK.flashlight.disable();
  }
});
```
```

---

## 📄 `lib/plugins/navigation_bar/README.md`

```markdown
# Navigation Bar Plugin

Control Android navigation bar appearance.

## Plugin Name
`navigationBar`

## Methods

### `setColor`
| Param | Type | Required |
|-------|------|----------|
| `color` | `string` (#RRGGBB) | ✅ |
| `darkIcons` | `bool` | — |
| `navigationBarColor` | `string` | — |

### `setStyle`
| Param | Type | Values |
|-------|------|--------|
| `style` | `string` | `"light"`, `"dark"`, `"default"` |

### `show` / `hide` / `setTransparent`

## Usage
```javascript
// Match app theme
await NativeSDK.navigationBar.setColor('#1A1A2E', false); // dark icons off

// Light theme
await NativeSDK.navigationBar.setStyle('dark'); // dark icons on white bg

// Transparent for fullscreen
await NativeSDK.navigationBar.setTransparent();

// Video fullscreen
await NativeSDK.statusBar.hide();
await NativeSDK.navigationBar.hide();

// Restore
await NativeSDK.statusBar.show();
await NativeSDK.navigationBar.show();
```
```

---

## 📄 `lib/plugins/privacy_screen/README.md`

```markdown
# Privacy Screen Plugin

Prevent screenshots and hide content in app switcher.

## Plugin Name
`privacyScreen`

## Methods

| Method | Returns |
|--------|---------|
| `enable` | `{ enabled: true }` |
| `disable` | `{ enabled: false }` |
| `isEnabled` | `{ enabled: bool }` |

## Use Cases
- Banking/finance apps
- Medical records
- Password managers
- Private messaging

## Usage
```javascript
// Enable on sensitive screens
router.events.subscribe(event => {
  if (event.url.includes('/account') || event.url.includes('/payment')) {
    NativeSDK.privacyScreen.enable();
  } else {
    NativeSDK.privacyScreen.disable();
  }
});

// Or globally for entire app
NativeSDK.waitForReady().then(() => {
  NativeSDK.privacyScreen.enable();
});
```
```

---

## 📄 `lib/plugins/native_settings/README.md`

```markdown
# Native Settings Plugin

Open Android system settings screens.

## Plugin Name
`nativeSettings`

## Methods

### `open`
| Param | Type | Required |
|-------|------|----------|
| `setting` | `string` | ✅ |

### Shortcut Methods
`openApp`, `openWifi`, `openBluetooth`, `openLocation`, `openNotification`, `openBattery`, `openDisplay`, `openSound`, `openSecurity`, `openDate`, `openAccessibility`, `openStorage`, `openDeveloper`, `openAbout`

### `getAvailableSettings`
Returns all supported setting names.

## Available Settings
`app`, `wifi`, `bluetooth`, `location`, `notification`, `battery`, `display`, `sound`, `security`, `date`, `accessibility`, `storage`, `developer`, `about`, `nfc`, `airplane`, `apn`, `data_usage`, `vpn`, `input_method`, `locale`, `privacy`, `biometric`, `default_apps`

## Usage
```javascript
// Guide user to enable location
const perm = await NativeSDK.permission.check('location');
if (perm.permanentlyDenied) {
  await NativeSDK.dialog.alert({
    message: 'Please enable location in settings'
  });
  await NativeSDK.nativeSettings.openLocation();
}

// Open notification settings
await NativeSDK.nativeSettings.openNotification();

// Open app-specific settings
await NativeSDK.nativeSettings.openApp();

// Generic open
await NativeSDK.nativeSettings.open('wifi');
await NativeSDK.nativeSettings.open('biometric');
```
```

---

# README‌های فاز ۹

## 📄 `lib/plugins/calendar/README.md`

```markdown
# Calendar Plugin

Read and write device calendar events.

## Plugin Name
`calendar`

## Methods

### `getCalendars`
**Returns:**
```json
{
  "calendars": [
    { "id": "1", "name": "Personal", "accountName": "user@gmail.com", "isReadOnly": false }
  ]
}
```

### `getEvents`
| Param | Type | Default |
|-------|------|---------|
| `calendarId` | `string` | ✅ |
| `startMs` | `number` | now |
| `endMs` | `number` | — |
| `daysAhead` | `number` | `30` |

### `createEvent`
| Param | Type | Required |
|-------|------|----------|
| `calendarId` | `string` | ✅ |
| `title` | `string` | ✅ |
| `startMs` | `number` | ✅ |
| `endMs` | `number` | ✅ |
| `description` | `string` | — |
| `location` | `string` | — |
| `allDay` | `bool` | `false` |

### `deleteEvent`
| Param | Type | Required |
|-------|------|----------|
| `calendarId` | `string` | ✅ |
| `eventId` | `string` | ✅ |

### `hasPermission` / `requestPermission`

## Usage
```javascript
// Get calendars
await NativeSDK.calendar.requestPermission();
const { calendars } = await NativeSDK.calendar.getCalendars();
const myCalendar = calendars.find(c => c.name === 'Personal');

// Get upcoming events
const { events } = await NativeSDK.calendar.getEvents(myCalendar.id, {
  daysAhead: 7
});
events.forEach(e => console.log(e.title, new Date(e.startMs)));

// Create event
const { eventId } = await NativeSDK.calendar.createEvent({
  calendarId: myCalendar.id,
  title: 'Team Meeting',
  description: 'Weekly sync',
  startMs: Date.now() + 3600000,
  endMs: Date.now() + 7200000,
  location: 'Conference Room 3'
});

// Delete event
await NativeSDK.calendar.deleteEvent(myCalendar.id, eventId);
```
```

---

## 📄 `lib/plugins/badge/README.md`

```markdown
# Badge Plugin

Manage app icon badge count.

## Plugin Name
`badge`

## Methods

| Method | Args | Returns |
|--------|------|---------|
| `set` | `count: number` | `{ count, set }` |
| `clear` | — | `{ count: 0 }` |
| `increase` | `by?: number` (default 1) | `{ count }` |
| `decrease` | `by?: number` (default 1) | `{ count }` |
| `get` | — | `{ count }` |
| `isSupported` | — | `{ supported: bool }` |

## Usage
```javascript
// Unread message count
const { supported } = await NativeSDK.badge.isSupported();
if (supported) {
  await NativeSDK.badge.set(unreadCount);
}

// New message arrived
NativeSDK.on('push.received', async () => {
  await NativeSDK.badge.increase(1);
});

// User opened app
NativeSDK.on('app.lifecycle.change', async (state) => {
  if (state.state === 'resumed') {
    await NativeSDK.badge.clear();
  }
});
```
```

---

## 📄 `lib/plugins/foreground_service/README.md`

```markdown
# Foreground Service Plugin

Run persistent Android foreground services.

## Plugin Name
`foregroundService`

## Methods

### `start`
| Param | Type | Default |
|-------|------|---------|
| `title` | `string` | `"App is running"` |
| `body` | `string` | `"Tap to return"` |
| `channelId` | `string` | `"foreground_service"` |
| `channelName` | `string` | `"Foreground Service"` |

### `stop`
### `update`
| Param | Type |
|-------|------|
| `title` | `string` |
| `body` | `string` |

### `isRunning`

## Events
| Event | Data |
|-------|------|
| `foregroundService.started` | `{ title, timestamp }` |
| `foregroundService.stopped` | `{ timestamp }` |

## Use Cases
- Background location tracking
- Music/audio playback
- File upload/download
- Real-time sync

## Usage
```javascript
// Location tracking service
await NativeSDK.foregroundService.start({
  title: 'Tracking Location',
  body: 'Your route is being recorded',
  channelId: 'location_tracking',
  channelName: 'Location Tracking'
});

await NativeSDK.backgroundGeolocation.startTracking({ accuracy: 'high' });

// Update notification text
let distanceKm = 0;
NativeSDK.on('bgGeo.position', async (pos) => {
  distanceKm += 0.01;
  await NativeSDK.foregroundService.update({
    body: `Distance: ${distanceKm.toFixed(1)}km`
  });
});

// Stop when done
await NativeSDK.backgroundGeolocation.stopTracking();
await NativeSDK.foregroundService.stop();
```
```

---

## 📄 `lib/plugins/background_geolocation/README.md`

```markdown
# Background Geolocation Plugin

Track device location even when app is in background.

## Plugin Name
`backgroundGeolocation`

## Methods

### `startTracking`
| Param | Type | Default |
|-------|------|---------|
| `accuracy` | `string` | `"high"` |
| `distanceFilter` | `number` (meters) | `10` |
| `intervalMs` | `number` | — |
| `maxHistory` | `number` | `500` |

### `stopTracking`
### `getLastPosition`
### `getHistory`
| Param | Type |
|-------|------|
| `limit` | `number` |
| `sinceMs` | `number` (timestamp) |

### `clearHistory`
### `isTracking`

## Events
| Event | Data |
|-------|------|
| `bgGeo.position` | `{ latitude, longitude, accuracy, speed, heading, timestamp }` |
| `bgGeo.error` | `{ message, timestamp }` |

## Usage
```javascript
// Start tracking (requires ForegroundService for background)
await NativeSDK.foregroundService.start({
  title: 'Tracking your journey'
});

await NativeSDK.backgroundGeolocation.startTracking({
  accuracy: 'high',
  distanceFilter: 20  // update every 20m
});

NativeSDK.on('bgGeo.position', async (pos) => {
  // Send to server
  await NativeSDK.http.post('https://api.myapp.com/location', pos);
  
  // Update map
  updateMapMarker(pos.latitude, pos.longitude);
});

// Get history for route display
const { positions } = await NativeSDK.backgroundGeolocation.getHistory({
  limit: 100
});
drawRoute(positions);

// Stop tracking
await NativeSDK.backgroundGeolocation.stopTracking();
await NativeSDK.foregroundService.stop();
```
```

---

## 📄 `lib/plugins/media_manager/README.md`

```markdown
# Media Manager Plugin

Save media files to device gallery.

## Plugin Name
`mediaManager`

## Methods

### `saveImageToGallery`
| Param | Type | Required | Default |
|-------|------|----------|---------|
| `path` | `string` | ✅ | — |
| `quality` | `number` 0-100 | — | `100` |
| `album` | `string` | — | — |

### `saveVideoToGallery`
| Param | Type | Required |
|-------|------|----------|
| `path` | `string` | ✅ |

### `saveFileToGallery`
| Param | Type | Required |
|-------|------|----------|
| `path` | `string` | ✅ |

## Usage
```javascript
// Take photo and save to gallery
const photo = await NativeSDK.camera.takePhoto({ quality: 90 });
const { saved } = await NativeSDK.mediaManager.saveImageToGallery(photo.path, {
  quality: 90,
  album: 'MyApp'
});
if (saved) await NativeSDK.toast.show('Photo saved!');

// Record video and save
const video = await NativeSDK.camera.recordVideo();
await NativeSDK.mediaManager.saveVideoToGallery(video.path);

// Download image and save
const dl = await NativeSDK.http.download({
  url: 'https://example.com/image.jpg',
  baseDir: 'temporary'
});
if (dl.saved) {
  await NativeSDK.mediaManager.saveImageToGallery(dl.path);
  await NativeSDK.toast.show('Image saved to gallery!');
}
```
```

---

## 📄 `lib/plugins/file_compressor/README.md`

```markdown
# File Compressor Plugin

Compress images before upload or storage.

## Plugin Name
`fileCompressor`

## Methods

### `compressImage`
| Param | Type | Default |
|-------|------|---------|
| `path` | `string` | ✅ |
| `quality` | `number` 1-100 | `80` |
| `maxWidth` | `number` | `1920` |
| `maxHeight` | `number` | `1080` |
| `format` | `string` | `"jpeg"` |
| `keepExif` | `bool` | `false` |

**format:** `"jpeg"`, `"png"`, `"webp"`

### `compressToWebP`
Same as `compressImage` with `format: "webp"`.

**Returns:**
```json
{
  "compressed": true,
  "inputPath": "/original.jpg",
  "outputPath": "/compressed.jpg",
  "originalSize": 2048000,
  "compressedSize": 512000,
  "savings": 75,
  "format": "jpeg"
}
```

## Usage
```javascript
// Before upload
const photo = await NativeSDK.camera.takePhoto({ quality: 100 });
const compressed = await NativeSDK.fileCompressor.compressImage(photo.path, {
  quality: 70,
  maxWidth: 1280,
  format: 'webp'
});
console.log(`Saved ${compressed.savings}%`);  // "Saved 75%"
uploadFile(compressed.outputPath);

// Profile picture - small size
const avatar = await NativeSDK.filePicker.pickImages();
const small = await NativeSDK.fileCompressor.compressImage(avatar.files[0].path, {
  quality: 85,
  maxWidth: 256,
  maxHeight: 256
});
uploadAvatar(small.outputPath);
```
```

---

## 📄 `lib/plugins/zip/README.md`

```markdown
# Zip Plugin

Create and extract ZIP archives.

## Plugin Name
`zip`

## Methods

### `zip`
| Param | Type | Required |
|-------|------|----------|
| `paths` | `string[]` | ✅ |
| `outputPath` | `string` | — (auto) |
| `password` | `string` | — |

**Returns:**
```json
{
  "zipped": true,
  "outputPath": "/tmp/archive.zip",
  "fileCount": 5,
  "originalSize": 1024000,
  "compressedSize": 256000,
  "compressionRatio": 75
}
```

### `unzip`
| Param | Type | Required |
|-------|------|----------|
| `path` | `string` | ✅ |
| `outputDir` | `string` | — (auto) |

### `listContents`
| Param | Type | Required |
|-------|------|----------|
| `path` | `string` | ✅ |

## Usage
```javascript
// Create zip backup
const dirs = await NativeSDK.fileSystem.getDirectories();
const archive = await NativeSDK.zip.zip([
  dirs.documents + '/reports',
  dirs.documents + '/data.json'
], dirs.documents + '/backup.zip');
console.log(`Archive: ${archive.compressionRatio}% compression`);

// Share the zip
await NativeSDK.share.shareFiles([archive.outputPath]);

// Extract update bundle
const dl = await NativeSDK.http.download({ url: 'https://cdn.app.com/update.zip' });
const extracted = await NativeSDK.zip.unzip(dl.path, dirs.documents + '/update');
console.log('Extracted:', extracted.fileCount, 'files');

// List contents without extracting
const { files } = await NativeSDK.zip.listContents('/path/to/archive.zip');
files.forEach(f => console.log(f.name, f.size));
```
```

---

## 📄 `lib/plugins/share_target/README.md`

```markdown
# Share Target Plugin

Receive shared content from other apps.

## Plugin Name
`shareTarget`

## Methods

| Method | Returns |
|--------|---------|
| `startListening` | `{ listening: true }` |
| `stopListening` | `{ listening: false }` |
| `getLastShared` | shared data or `{ available: false }` |
| `clearLastShared` | `{ cleared: true }` |

**Shared Data Format:**
```json
{
  "type": "text",
  "text": "Check out this link!",
  "title": "From Chrome"
}
```
or
```json
{
  "type": "files",
  "paths": ["/path/to/file.jpg"],
  "mimeType": "image/jpeg"
}
```

## Events
| Event | Data |
|-------|------|
| `shareTarget.received` | shared data object |

## Setup (Android)
Add to `AndroidManifest.xml`:
```xml
<intent-filter>
  <action android:name="android.intent.action.SEND"/>
  <category android:name="android.intent.category.DEFAULT"/>
  <data android:mimeType="text/plain"/>
</intent-filter>
<intent-filter>
  <action android:name="android.intent.action.SEND"/>
  <category android:name="android.intent.category.DEFAULT"/>
  <data android:mimeType="image/*"/>
</intent-filter>
```

## Usage
```javascript
await NativeSDK.shareTarget.startListening();

NativeSDK.on('shareTarget.received', async (data) => {
  if (data.type === 'text') {
    // User shared text/URL from another app
    document.getElementById('input').value = data.text;
    await NativeSDK.toast.show('Content received!');
  } else if (data.type === 'files') {
    // User shared image/file
    uploadFiles(data.paths);
  }
});

// Check on app start
const lastShared = await NativeSDK.shareTarget.getLastShared();
if (lastShared.available !== false) {
  handleSharedContent(lastShared);
  await NativeSDK.shareTarget.clearLastShared();
}
```
```

---

# README‌های فاز ۱۰

## 📄 `lib/plugins/in_app_review/README.md`

```markdown
# In-App Review Plugin

Prompt users for app store ratings without leaving the app.

## Plugin Name
`inAppReview`

## Methods

| Method | Returns |
|--------|---------|
| `isAvailable` | `{ available: bool }` |
| `requestReview` | `{ requested: bool }` |
| `openStoreListing` | `{ opened: bool }` |

## Important Notes
- Google limits how often the review dialog can be shown
- Don't call after a button press — trigger naturally after positive actions
- No guarantee the dialog will appear every time

## Usage
```javascript
// After completing a key action
async function onOrderCompleted() {
  const { available } = await NativeSDK.inAppReview.isAvailable();
  if (!available) return;

  // Check if enough time has passed (track in storage)
  const lastReview = await NativeSDK.storage.get('last_review_request');
  const daysSince = lastReview 
    ? (Date.now() - lastReview) / 86400000 
    : Infinity;

  if (daysSince > 30) {  // once per 30 days max
    await NativeSDK.inAppReview.requestReview();
    await NativeSDK.storage.set('last_review_request', Date.now());
  }
}

// Explicit store link (settings page)
await NativeSDK.inAppReview.openStoreListing();
```
```

---

## 📄 `lib/plugins/native_market/README.md`

```markdown
# Native Market Plugin

Link to app store pages.

## Plugin Name
`nativeMarket`

## Methods

### `openStore`
Open this app's Play Store page.
| Param | Type |
|-------|------|
| `packageName` | `string` (optional, defaults to this app) |

### `openDeveloperPage`
| Param | Type | Required |
|-------|------|----------|
| `developerId` | `string` | ✅ |

### `openOtherApp`
Open another app's store page.
| Param | Type | Required |
|-------|------|----------|
| `packageName` | `string` | ✅ |

### `getStoreUrl`
Get Play Store URL without opening.

## Usage
```javascript
// Rate this app
await NativeSDK.nativeMarket.openStore();

// Open other app
await NativeSDK.nativeMarket.openOtherApp('com.whatsapp');

// Developer page
await NativeSDK.nativeMarket.openDeveloperPage('YourCompanyName');

// Get URL for sharing
const { playStore } = NativeSDK.nativeMarket.getStoreUrl();
await NativeSDK.share.shareText('Download our app: ' + playStore);
```
```

---

## 📄 `lib/plugins/screenshot/README.md`

```markdown
# Screenshot Plugin

Capture screenshots of the current view.

## Plugin Name
`screenshot`

## Methods

### `capture`
| Param | Type | Default |
|-------|------|---------|
| `format` | `string` | `"png"` |
| `quality` | `number` 0-100 | `100` |
| `fileName` | `string` | auto |
| `baseDir` | `string` | `"temporary"` |

**format:** `"png"` or `"jpg"`

**Returns:**
```json
{
  "captured": true,
  "path": "/tmp/screenshots/screenshot_1234.png",
  "fileName": "screenshot_1234.png",
  "size": 245678,
  "width": 1080,
  "height": 2400
}
```

## Usage
```javascript
// Simple screenshot
const shot = await NativeSDK.screenshot.capture();
await NativeSDK.share.shareFiles([shot.path]);

// High quality
const shot = await NativeSDK.screenshot.capture({
  format: 'png',
  quality: 100,
  fileName: 'bug_report'
});

// Bug report workflow
document.getElementById('reportBtn').onclick = async () => {
  const shot = await NativeSDK.screenshot.capture({ format: 'jpg' });
  const form = new FormData();
  form.append('screenshot', shot.path);
  form.append('description', userInput.value);
  await fetch('/api/bug-report', { method: 'POST', body: form });
};
```
```

---

## 📄 `lib/plugins/safe_area/README.md`

```markdown
# Safe Area Plugin

Get device safe area insets for notches and system bars.

## Plugin Name
`safeArea`

## Methods

### `getInsets`
**Returns:**
```json
{
  "padding": { "top": 44, "bottom": 34, "left": 0, "right": 0 },
  "viewInsets": { "top": 0, "bottom": 0, "left": 0, "right": 0 },
  "viewPadding": { "top": 44, "bottom": 34, "left": 0, "right": 0 }
}
```

### `getScreenInfo`
**Returns:**
```json
{
  "width": 390,
  "height": 844,
  "physicalWidth": 1170,
  "physicalHeight": 2532,
  "devicePixelRatio": 3.0,
  "orientation": "portrait",
  "textScaleFactor": 1.0
}
```

## Usage
```javascript
// Apply safe area padding to content
const { padding } = await NativeSDK.safeArea.getInsets();
document.body.style.paddingTop = padding.top + 'px';
document.body.style.paddingBottom = padding.bottom + 'px';

// CSS variables approach
const insets = await NativeSDK.safeArea.getInsets();
document.documentElement.style.setProperty('--safe-top', insets.padding.top + 'px');
document.documentElement.style.setProperty('--safe-bottom', insets.padding.bottom + 'px');

// Adjust layout on keyboard show
NativeSDK.on('keyboard.change', async (kb) => {
  const { viewInsets } = await NativeSDK.safeArea.getInsets();
  document.getElementById('main').style.marginBottom = kb.visible 
    ? kb.height + 'px' 
    : insets.padding.bottom + 'px';
});
```
```

---

## 📄 `lib/plugins/date_picker/README.md`

```markdown
# Date Picker Plugin

Native date and time picker dialogs.

## Plugin Name
`datePicker`

## Methods

### `pickDate`
| Param | Type | Default |
|-------|------|---------|
| `initialDateMs` | `number` | today |
| `firstDateMs` | `number` | 100 years ago |
| `lastDateMs` | `number` | 100 years ahead |
| `title` | `string` | — |

**Returns:**
```json
{ "picked": true, "year": 2024, "month": 1, "day": 15, "dateMs": 1705276800000, "formatted": "2024-01-15" }
```

### `pickTime`
| Param | Type | Default |
|-------|------|---------|
| `initialHour` | `number` | current |
| `initialMinute` | `number` | current |
| `use24h` | `bool` | `true` |

**Returns:**
```json
{ "picked": true, "hour": 14, "minute": 30, "formatted": "14:30" }
```

### `pickDateTime`
Combination of pickDate then pickTime.

### `pickDateRange`
| Param | Type |
|-------|------|
| `firstDateMs` | `number` |
| `lastDateMs` | `number` |

**Returns:**
```json
{ "picked": true, "start": { "dateMs": ... }, "end": { "dateMs": ... }, "durationDays": 7 }
```

## Usage
```javascript
// Birthday picker
const birth = await NativeSDK.datePicker.pickDate({
  title: 'Select Birth Date',
  lastDateMs: Date.now(),
  firstDateMs: new Date('1900-01-01').getTime()
});
if (birth.picked) form.birthday = birth.formatted;

// Appointment
const dt = await NativeSDK.datePicker.pickDateTime();
if (dt.picked) {
  scheduleAppointment(dt.dateTimeMs);
}

// Hotel booking
const range = await NativeSDK.datePicker.pickDateRange({
  firstDateMs: Date.now()
});
if (range.picked) {
  console.log(`${range.durationDays} nights`);
  bookHotel(range.start.dateMs, range.end.dateMs);
}
```
```

---

## 📄 `lib/plugins/action_sheet/README.md`

```markdown
# Action Sheet Plugin

Native bottom sheet with action options.

## Plugin Name
`actionSheet`

## Methods

### `show`
| Param | Type | Required |
|-------|------|----------|
| `options` | `array` | ✅ |
| `title` | `string` | — |
| `message` | `string` | — |
| `cancelText` | `string` | `"Cancel"` |
| `destructiveIndex` | `number` | — |

**Option object:**
```json
{ "title": "Delete", "icon": "delete", "subtitle": "Cannot be undone" }
```

**Available icons:** `delete`, `edit`, `share`, `copy`, `camera`, `photo`, `file`, `download`, `upload`, `settings`, `info`, `warning`

**Returns:**
```json
{ "selected": true, "index": 2, "value": "Delete", "option": {...} }
```

## Usage
```javascript
// File actions
const result = await NativeSDK.actionSheet.show({
  title: 'File Options',
  options: [
    { title: 'Open', icon: 'file' },
    { title: 'Share', icon: 'share' },
    { title: 'Download', icon: 'download' },
    { title: 'Delete', icon: 'delete' }
  ],
  destructiveIndex: 3
});

if (result.selected) {
  switch (result.index) {
    case 0: openFile(); break;
    case 1: shareFile(); break;
    case 2: downloadFile(); break;
    case 3: deleteFile(); break;
  }
}

// Photo source picker
const source = await NativeSDK.actionSheet.show({
  options: [
    { title: 'Take Photo', icon: 'camera' },
    { title: 'Choose from Gallery', icon: 'photo' }
  ]
});
if (source.selected) {
  if (source.index === 0) NativeSDK.camera.takePhoto();
  else NativeSDK.camera.pickFromGallery();
}
```
```

---

## 📄 `lib/plugins/text_zoom/README.md`

```markdown
# Text Zoom Plugin

Adjust WebView text size for accessibility.

## Plugin Name
`textZoom`

## Methods

| Method | Args | Returns |
|--------|------|---------|
| `get` | — | `{ zoom: 100 }` |
| `set` | `zoom: 50-300` | `{ zoom }` |
| `increase` | `step?: number` (default 10) | `{ zoom }` |
| `decrease` | `step?: number` (default 10) | `{ zoom }` |
| `reset` | — | `{ zoom: 100 }` |

## Events
| Event | Data |
|-------|------|
| `textZoom.changed` | `{ zoom, timestamp }` |

## Usage
```javascript
// Accessibility settings page
const { zoom } = await NativeSDK.textZoom.get();
zoomSlider.value = zoom;

zoomSlider.oninput = async (e) => {
  await NativeSDK.textZoom.set(parseInt(e.target.value));
};

// Restore on app start
const savedZoom = await NativeSDK.storage.get('text_zoom');
if (savedZoom) await NativeSDK.textZoom.set(savedZoom);

// Save when changed
NativeSDK.on('textZoom.changed', async (data) => {
  await NativeSDK.storage.set('text_zoom', data.zoom);
});

// Quick +/- buttons
document.getElementById('zoomIn').onclick = () => NativeSDK.textZoom.increase(10);
document.getElementById('zoomOut').onclick = () => NativeSDK.textZoom.decrease(10);
```
```

---

## 📄 `lib/plugins/accessibility/README.md`

```markdown
# Accessibility Plugin

Detect and respond to accessibility features.

## Plugin Name
`accessibility`

## Methods

### `isScreenReaderEnabled`
**Returns:** `{ enabled: bool }`

### `announce`
| Param | Type | Required | Default |
|-------|------|----------|---------|
| `message` | `string` | ✅ | — |
| `assertiveness` | `string` | — | `"polite"` |

### `getSettings`
**Returns:**
```json
{
  "screenReaderEnabled": false,
  "boldText": false,
  "reduceMotion": false,
  "highContrast": false,
  "invertColors": false,
  "disableAnimations": false
}
```

### `isBoldTextEnabled` / `isReduceMotionEnabled` / `isHighContrastEnabled`

## Usage
```javascript
// Adapt UI to accessibility settings
const settings = await NativeSDK.accessibility.getSettings();

if (settings.reduceMotion) {
  document.body.classList.add('no-animations');
}

if (settings.highContrast) {
  document.body.classList.add('high-contrast');
}

// Screen reader announcements
const { enabled } = await NativeSDK.accessibility.isScreenReaderEnabled();
if (enabled) {
  await NativeSDK.accessibility.announce('Page loaded: Home screen');
}

// Route changes
router.events.subscribe(event => {
  NativeSDK.accessibility.announce('Navigated to ' + event.url);
});
```
```

---

# README‌های فاز ۱۱

## 📄 `lib/plugins/wifi_manager/README.md`

```markdown
# WiFi Manager Plugin

Get WiFi connection information.

## Plugin Name
`wifiManager`

## Methods

### `getConnectionInfo`
**Returns:**
```json
{
  "connected": true,
  "ip": "192.168.1.100",
  "interfaceName": "wlan0",
  "interfaces": [...]
}
```

### `getIpAddress`
**Returns:** `{ ips: ["192.168.1.100"], primary: "192.168.1.100" }`

### `isEnabled`
**Returns:** `{ enabled: bool }`

## Usage
```javascript
const info = await NativeSDK.wifiManager.getConnectionInfo();
if (info.connected) {
  console.log('IP:', info.ip);
  document.getElementById('ip').textContent = info.ip;
}

// Network-dependent features
const { enabled } = await NativeSDK.wifiManager.isEnabled();
if (!enabled) {
  await NativeSDK.nativeSettings.openWifi();
}
```
```

---

## 📄 `lib/plugins/root_detection/README.md`

```markdown
# Root Detection Plugin

Detect rooted/jailbroken devices for security.

## Plugin Name
`rootDetection`

## Methods

### `isRooted`
**Returns:**
```json
{
  "isRooted": false,
  "platform": "android",
  "riskLevel": "safe",
  "checks": {
    "suBinary": false,
    "rootApps": false,
    "testKeys": false,
    "magisk": false,
    "busybox": false
  }
}
```

**riskLevel:** `"safe"`, `"low"`, `"medium"`, `"high"`

### `getSecurityInfo`
Returns `isRooted` + `isEmulator`, `isDebugMode`, `adbEnabled`.

## Usage
```javascript
// Block on rooted devices (banking/medical)
const { isRooted, riskLevel } = await NativeSDK.rootDetection.isRooted();

if (isRooted) {
  await NativeSDK.dialog.alert({
    title: 'Security Warning',
    message: 'This app cannot run on rooted devices.'
  });
  await NativeSDK.backButton.exitApp();
  return;
}

// Just warn
if (riskLevel === 'medium' || riskLevel === 'high') {
  await NativeSDK.toast.show('⚠️ Running on modified device');
}

// Full security check
const security = await NativeSDK.rootDetection.getSecurityInfo();
await NativeSDK.firebaseCrashlytics.setCustomKeys({
  isRooted: security.isRooted,
  isEmulator: security.isEmulator,
  riskLevel: security.riskLevel
});
```
```

---

## 📄 `lib/plugins/app_integrity/README.md`

```markdown
# App Integrity Plugin

Verify app installation authenticity.

## Plugin Name
`appIntegrity`

## Methods

### `checkIntegrity`
**Returns:**
```json
{
  "verdict": "trusted",
  "genuine": true,
  "playStore": true,
  "install": { "genuine": true },
  "source": { "source": "com.android.vending" }
}
```

**verdict:** `"trusted"` | `"genuine"` | `"untrusted"`

### `isGenuineInstall` / `getInstallSource` / `getSigningInfo`

## Usage
```javascript
const integrity = await NativeSDK.appIntegrity.checkIntegrity();

switch (integrity.verdict) {
  case 'trusted':
    // Play Store install, proceed normally
    break;
  case 'genuine':
    // Signed correctly but not from Play Store (sideloaded)
    await NativeSDK.toast.show('Please install from Play Store');
    break;
  case 'untrusted':
    // Modified or unknown installation
    await NativeSDK.dialog.alert({
      title: 'Security',
      message: 'Please download from the official Play Store.'
    });
    await NativeSDK.nativeMarket.openStore();
    break;
}
```
```

---

## 📄 `lib/plugins/alarm/README.md`

```markdown
# Alarm Plugin

Schedule timer-based alarms with events.

## Plugin Name
`alarm`

## Methods

### `set`
| Param | Type | Required |
|-------|------|----------|
| `alarmId` | `string` | — (auto) |
| `delayMs` | `number` | ✅ (or atMs) |
| `atMs` | `number` | ✅ (or delayMs) |
| `title` | `string` | — |
| `body` | `string` | — |
| `repeating` | `bool` | `false` |
| `intervalMs` | `number` | — (if repeating) |
| `payload` | `any` | — |

### `cancel` / `cancelAll` / `getAlarm` / `getAllAlarms`

## Events
| Event | Data |
|-------|------|
| `alarm.fired` | `{ alarmId, title, body, payload, firedAt }` |

## Usage
```javascript
// One-time alarm (5 minutes from now)
await NativeSDK.alarm.set({
  alarmId: 'break_reminder',
  delayMs: 5 * 60 * 1000,
  title: 'Take a Break!',
  body: 'Time for a 5-minute break.',
  payload: { type: 'break', duration: 5 }
});

// Alarm at specific time
const tomorrow9am = new Date();
tomorrow9am.setDate(tomorrow9am.getDate() + 1);
tomorrow9am.setHours(9, 0, 0, 0);

await NativeSDK.alarm.set({
  alarmId: 'morning_brief',
  atMs: tomorrow9am.getTime(),
  title: 'Morning Briefing',
  payload: { screen: '/briefing' }
});

// Repeating sync every 30 minutes
await NativeSDK.alarm.set({
  alarmId: 'sync',
  delayMs: 0,
  repeating: true,
  intervalMs: 30 * 60 * 1000,
  title: 'Syncing data...'
});

// Handle alarm
NativeSDK.on('alarm.fired', async (data) => {
  if (data.payload?.screen) {
    router.navigate(data.payload.screen);
  }
  await NativeSDK.notification.show({
    title: data.title,
    body: data.body
  });
});
```
```

---

## 📄 `lib/plugins/pedometer/README.md`

```markdown
# Pedometer Plugin

Track steps using device pedometer sensor.

## Plugin Name
`pedometer`

## Methods

| Method | Returns |
|--------|---------|
| `startTracking` | `{ started: bool }` |
| `stopTracking` | `{ stopped: bool, lastSteps: number }` |
| `getStepCount` | `{ steps: number }` |
| `getStatus` | `{ status: "walking"/"stopped" }` |
| `isTracking` | `{ tracking: bool }` |

## Events
| Event | Data |
|-------|------|
| `pedometer.step` | `{ steps, timestamp }` |
| `pedometer.status` | `{ status: "walking"/"stopped", timestamp }` |
| `pedometer.error` | `{ message }` |

## Usage
```javascript
// Daily step counter
await NativeSDK.pedometer.startTracking();

NativeSDK.on('pedometer.step', (data) => {
  document.getElementById('steps').textContent = data.steps.toLocaleString();
  
  const goal = 10000;
  const progress = Math.min(100, (data.steps / goal) * 100);
  progressRing.style.strokeDashoffset = 100 - progress;
});

NativeSDK.on('pedometer.status', (data) => {
  statusLabel.textContent = data.status === 'walking' ? '🚶 Walking' : '⏸ Stopped';
});

// Save daily count
NativeSDK.on('app.lifecycle.change', async (state) => {
  if (state.state === 'paused') {
    const { steps } = await NativeSDK.pedometer.getStepCount();
    await NativeSDK.storage.set('steps_today', steps);
  }
});
```
```

---

## 📄 `lib/plugins/shake_detection/README.md`

```markdown
# Shake Detection Plugin

Detect device shake gesture.

## Plugin Name
`shakeDetection`

## Methods

### `startListening`
| Param | Type | Default |
|-------|------|---------|
| `threshold` | `number` | `15.0` |
| `cooldownMs` | `number` | `1000` |

### `stopListening` / `configure` / `getShakeCount` / `resetCount` / `isListening`

## Events
| Event | Data |
|-------|------|
| `shake.detected` | `{ magnitude, count, timestamp }` |

## Usage
```javascript
// Shake to undo
await NativeSDK.shakeDetection.startListening({ threshold: 12, cooldownMs: 1500 });

NativeSDK.on('shake.detected', async () => {
  await NativeSDK.haptic.mediumImpact();
  
  const { confirmed } = await NativeSDK.dialog.confirm({
    message: 'Undo last action?',
    okButtonTitle: 'Undo'
  });
  if (confirmed) undoLastAction();
});

// Shake to refresh
NativeSDK.on('shake.detected', () => {
  refreshData();
  NativeSDK.haptic.lightImpact();
  NativeSDK.toast.show('Refreshing...');
});

// Stop when not needed
await NativeSDK.shakeDetection.stopListening();
```
```

---

## 📄 `lib/plugins/volume_buttons/README.md`

```markdown
# Volume Buttons Plugin

Capture hardware volume button presses.

## Plugin Name
`volumeButtons`

## Methods

| Method | Returns |
|--------|---------|
| `startListening` | `{ started: bool }` |
| `stopListening` | `{ stopped: bool }` |
| `isListening` | `{ listening: bool }` |

## Events
| Event | Data |
|-------|------|
| `volume.pressed` | `{ direction: "up"/"down", timestamp }` |

## Use Cases
- Camera shutter trigger
- Barcode scanner trigger
- Presentation slide control
- Game controls

## Usage
```javascript
// Camera shutter with volume button
await NativeSDK.volumeButtons.startListening();
NativeSDK.on('volume.pressed', async (data) => {
  if (data.direction === 'up') {
    await NativeSDK.haptic.lightImpact();
    const photo = await NativeSDK.camera.takePhoto({ quality: 90 });
    displayPhoto(photo.path);
  }
});

// QR scanner trigger
NativeSDK.on('volume.pressed', async () => {
  if (scannerActive) {
    const result = await NativeSDK.qrScanner.scan();
    handleScan(result);
  }
});

// Stop when leaving scanner
await NativeSDK.volumeButtons.stopListening();
```
```

---

## 📄 `lib/plugins/sim_info/README.md`

```markdown
# SIM Info Plugin

Read SIM card information.

## Plugin Name
`simInfo`

## Methods

| Method | Returns |
|--------|---------|
| `getSimInfo` | full SIM information |
| `getCarrierName` | `{ carrier: "MTN" }` |
| `getSimCount` | `{ count: 2 }` |

**getSimInfo Returns:**
```json
{
  "available": true,
  "networkOperator": "MCI",
  "simOperator": "MCI",
  "simState": 5,
  "networkCountryIso": "ir",
  "simCountryIso": "ir",
  "simCount": 2
}
```

## Note
Requires `READ_PHONE_STATE` permission.

## Usage
```javascript
const carrier = await NativeSDK.simInfo.getCarrierName();
console.log('Carrier:', carrier.carrier);

const { count } = await NativeSDK.simInfo.getSimCount();
console.log('SIM cards:', count);

const info = await NativeSDK.simInfo.getSimInfo();
if (info.available) {
  document.getElementById('carrier').textContent = info.networkOperator;
  document.getElementById('country').textContent = info.simCountryIso.toUpperCase();
}
```
```

---

## 📄 `lib/plugins/kiosk_mode/README.md`

```markdown
# Kiosk Mode Plugin

Lock device into single-app kiosk mode.

## Plugin Name
`kioskMode`

## Methods

| Method | Returns |
|--------|---------|
| `enable` | `{ enabled: true }` |
| `disable` | `{ enabled: false }` |
| `isEnabled` | `{ enabled: bool }` |

## What it does
- Hides status bar (immersive sticky)
- Locks screen orientation to portrait
- Prevents navigation away from app

## Usage
```javascript
// Retail kiosk
await NativeSDK.kioskMode.enable();

// Admin unlock (hidden gesture)
let tapCount = 0;
document.getElementById('logo').onclick = async () => {
  tapCount++;
  if (tapCount >= 5) {
    const { value } = await NativeSDK.dialog.prompt({
      title: 'Admin Access',
      placeholder: 'Enter PIN',
      inputType: 'number'
    });
    if (value === '1234') {
      await NativeSDK.kioskMode.disable();
      tapCount = 0;
    }
  }
};
```
```

---

## 📄 `lib/plugins/intent_launcher/README.md`

```markdown
# Intent Launcher Plugin

Launch Android intents and system settings.

## Plugin Name
`intentLauncher`

## Methods

### `launch`
| Param | Type | Required |
|-------|------|----------|
| `intent` | `string` | ✅ |

**Known Intents (25+):**
`settings`, `wifi`, `bluetooth`, `location`, `notification`, `battery`, `display`, `sound`, `security`, `date`, `apps`, `developer`, `accessibility`, `storage`, `about`, `vpn`, `data_roaming`, `language`, `keyboard`, `hotspot`, `mobile_data`, `nfc`, `airplane`, `default_apps`, `privacy`

### `launchUrl`
| Param | Type | Default |
|-------|------|---------|
| `url` | `string` | ✅ |
| `mode` | `string` | `"external"` |

### `isAppInstalled`
| Param | Type | Required |
|-------|------|----------|
| `packageName` | `string` | ✅ |

## Usage
```javascript
// Open system settings
await NativeSDK.intentLauncher.launch('wifi');
await NativeSDK.intentLauncher.launch('developer');

// Check if app installed
const { installed } = await NativeSDK.intentLauncher.isAppInstalled('com.whatsapp');
if (installed) {
  await NativeSDK.intentLauncher.launchUrl('whatsapp://send?phone=989123456789');
} else {
  await NativeSDK.intentLauncher.isAppInstalled('com.android.vending')
    ? NativeSDK.nativeMarket.openOtherApp('com.whatsapp')
    : null;
}

// List all known intents
const { knownIntents } = await NativeSDK.intentLauncher.getInfo();
console.log('Available:', knownIntents.length, 'intents');
```
```

---

## 📄 `lib/plugins/email_composer/README.md`

```markdown
# Email Composer Plugin

Open email compose window.

## Plugin Name
`emailComposer`

## Methods

### `compose`
| Param | Type | Required |
|-------|------|----------|
| `to` | `string \| string[]` | ✅ |
| `subject` | `string` | — |
| `body` | `string` | — |
| `cc` | `string \| string[]` | — |
| `bcc` | `string \| string[]` | — |

### `canCompose`
**Returns:** `{ available: bool }`

## Usage
```javascript
// Support email
await NativeSDK.emailComposer.compose({
  to: 'support@myapp.com',
  subject: 'Support Request',
  body: `
App Version: ${appVersion}
Device: ${deviceModel}

Issue Description:
`
});

// Bug report with CC
await NativeSDK.emailComposer.compose({
  to: 'bugs@myapp.com',
  cc: 'team@myapp.com',
  subject: 'Bug Report #' + Date.now(),
  body: await generateBugReport()
});

// Multiple recipients
await NativeSDK.emailComposer.compose({
  to: ['sales@myapp.com', 'info@myapp.com'],
  subject: 'Quote Request'
});

// Check availability first
const { available } = await NativeSDK.emailComposer.canCompose();
if (!available) {
  await NativeSDK.toast.show('No email app installed');
}
```
```

---

# README‌های Firebase

## 📄 `lib/plugins/firebase_analytics/README.md`

```markdown
# Firebase Analytics Plugin

Track events and user behavior with Firebase Analytics.

## Plugin Name
`firebaseAnalytics`

## Methods

### `logEvent`
| Param | Type | Required |
|-------|------|----------|
| `name` | `string` | ✅ |
| `parameters` | `object` | — |

### Predefined Events
| Method | Parameters |
|--------|-----------|
| `setCurrentScreen` | `screenName`, `screenClass` |
| `setUserId` | `id` |
| `setUserProperty` | `name`, `value` |
| `logLogin` | `method` |
| `logSignUp` | `method` |
| `logSearch` | `searchTerm` |
| `logPurchase` | `currency`, `value`, `transactionId`, `items` |
| `logViewItem` | `currency`, `value`, `items` |
| `logAddToCart` | `currency`, `value`, `items` |
| `logBeginCheckout` | `currency`, `value`, `items` |
| `logShare` | `contentType`, `itemId`, `method` |

### `setAnalyticsCollectionEnabled` / `resetAnalyticsData` / `getAppInstanceId`

## Usage
```javascript
// Screen tracking (Angular example)
router.events.subscribe(event => {
  NativeSDK.firebaseAnalytics.setCurrentScreen(event.url, 'WebView');
});

// User identification
await NativeSDK.firebaseAnalytics.setUserId(user.id);
await NativeSDK.firebaseAnalytics.setUserProperty('plan', 'premium');

// Custom events
await NativeSDK.firebaseAnalytics.logEvent('tutorial_complete', {
  tutorial_id: 'onboarding_v2',
  duration_seconds: 45
});

// E-commerce
await NativeSDK.firebaseAnalytics.logPurchase({
  currency: 'USD',
  value: 49.99,
  transactionId: 'txn_' + Date.now(),
  items: [{
    itemId: 'premium_plan',
    itemName: 'Premium Plan',
    price: 49.99,
    quantity: 1
  }]
});
```
```

---

## 📄 `lib/plugins/firebase_crashlytics/README.md`

```markdown
# Firebase Crashlytics Plugin

Crash reporting and diagnostics.

## Plugin Name
`firebaseCrashlytics`

## Methods

### `recordError`
| Param | Type | Required | Default |
|-------|------|----------|---------|
| `message` | `string` | ✅ | — |
| `type` | `string` | — | `"Error"` |
| `fatal` | `bool` | — | `false` |
| `keys` | `object` | — | — |

### `log` — Add log message to crash report
### `setUserId`
### `setCustomKey` / `setCustomKeys`
### `sendUnsentReports` / `deleteUnsentReports`
### `checkForUnsentReports`
### `setCrashlyticsCollectionEnabled`

## Usage
```javascript
// Global error handler
window.addEventListener('error', (event) => {
  NativeSDK.firebaseCrashlytics.recordError(event.message, 'JSError', {
    fatal: false,
    keys: {
      filename: event.filename,
      lineno: event.lineno,
      colno: event.colno
    }
  });
});

// User context
await NativeSDK.firebaseCrashlytics.setUserId(currentUser.id);
await NativeSDK.firebaseCrashlytics.setCustomKeys({
  plan: currentUser.plan,
  version: appVersion,
  screen: currentRoute
});

// Breadcrumbs
await NativeSDK.firebaseCrashlytics.log('User opened checkout');
await NativeSDK.firebaseCrashlytics.log('Payment processing started');

// Try/catch with reporting
try {
  await processPayment();
} catch (error) {
  await NativeSDK.firebaseCrashlytics.recordError(error.message, 'PaymentError');
  await NativeSDK.dialog.alert({ message: 'Payment failed. Please try again.' });
}
```
```

---

## 📄 `lib/plugins/firebase_remote_config/README.md`

```markdown
# Firebase Remote Config Plugin

Control app behavior without releasing new versions.

## Plugin Name
`firebaseRemoteConfig`

## Methods

### `initialize`
| Param | Type | Default |
|-------|------|---------|
| `minimumFetchIntervalMs` | `number` | `3600000` (1hr) |
| `fetchTimeoutMs` | `number` | `60000` |
| `defaults` | `object` | — |

### `fetchAndActivate` — Fetch + activate in one call
### `getString` / `getInt` / `getDouble` / `getBool` / `getJson`
| Param | Type | Required |
|-------|------|----------|
| `key` | `string` | ✅ |

### `getAll` — Get all config values
### `setDefaults` / `getLastFetchStatus`

## Events
| Event | Data |
|-------|------|
| `remoteConfig.updated` | `{ timestamp }` |

## Usage
```javascript
// Initialize with defaults
await NativeSDK.firebaseRemoteConfig.initialize({
  minimumFetchIntervalMs: 3600000,
  defaults: {
    feature_chat: false,
    max_upload_mb: 10,
    api_url: 'https://api.myapp.com',
    welcome_message: 'Welcome!'
  }
});

// Fetch and apply
const { updated } = await NativeSDK.firebaseRemoteConfig.fetchAndActivate();
if (updated) console.log('Config updated');

// Use values
const { value: chatEnabled } = await NativeSDK.firebaseRemoteConfig.getBool('feature_chat');
const { value: apiUrl } = await NativeSDK.firebaseRemoteConfig.getString('api_url');
const { value: maxUpload } = await NativeSDK.firebaseRemoteConfig.getInt('max_upload_mb');

if (chatEnabled) loadChatModule();

// Feature flags (A/B testing)
const { value: variant } = await NativeSDK.firebaseRemoteConfig.getString('onboarding_variant');
switch (variant) {
  case 'A': showOnboardingA(); break;
  case 'B': showOnboardingB(); break;
  default: showOnboardingDefault();
}
```
```

---

## 📄 `lib/plugins/firebase_auth/README.md`

```markdown
# Firebase Auth Plugin

Complete Firebase Authentication integration.

## Plugin Name
`firebaseAuth`

## Methods

### `signInWithEmail`
| Param | Type | Required |
|-------|------|----------|
| `email` | `string` | ✅ |
| `password` | `string` | ✅ |

### `signUpWithEmail`
Same as signInWithEmail + optional `displayName`.

### `signInWithGoogle`
### `signInAnonymously`
### `signOut`
### `sendPasswordResetEmail` — `email` required
### `updatePassword` — `newPassword` required
### `updateProfile` — `displayName`, `photoURL`
### `deleteAccount`
### `sendEmailVerification`
### `getIdToken` — `forceRefresh?: bool`
### `getCurrentUser` / `isSignedIn`
### `reloadUser`

**User Object:**
```json
{
  "uid": "abc123",
  "email": "user@example.com",
  "displayName": "Ali",
  "emailVerified": true,
  "isAnonymous": false,
  "photoURL": null
}
```

## Events
| Event | Data |
|-------|------|
| `auth.stateChanged` | `{ user, signedIn }` |

## Usage
```javascript
// Auth state listener (Angular guard example)
NativeSDK.on('auth.stateChanged', (data) => {
  if (data.signedIn) {
    router.navigate('/home');
  } else {
    router.navigate('/login');
  }
});

// Sign up
const { user, success, errorCode } = await NativeSDK.firebaseAuth.signUpWithEmail(
  'ali@test.com', 'password123', 'Ali Ahmadi'
);
if (!success) showError(errorCode);

// Sign in
const result = await NativeSDK.firebaseAuth.signInWithEmail(email, password);
if (result.success) {
  const { token } = await NativeSDK.firebaseAuth.getIdToken();
  // Use token for API calls
}

// Google sign in
const google = await NativeSDK.firebaseAuth.signInWithGoogle();

// Password reset
await NativeSDK.firebaseAuth.sendPasswordResetEmail('user@example.com');
await NativeSDK.toast.show('Reset email sent!');
```
```

---

# README‌های فاز ۱۷

## 📄 `lib/plugins/camera_preview/README.md`

```markdown
# Camera Preview Plugin

Live camera preview with full control.

## Plugin Name
`cameraPreview`

## Methods

### `start`
| Param | Type | Default |
|-------|------|---------|
| `cameraIndex` | `number` | `0` (back) |
| `resolution` | `string` | `"high"` |
| `enableAudio` | `bool` | `true` |

**resolution:** `low`, `medium`, `high`, `veryHigh`, `ultraHigh`, `max`

### `stop`
### `takePhoto`
| Param | Type | Default |
|-------|------|---------|
| `fileName` | `string` | auto |
| `saveToGallery` | `bool` | `false` |

### `startRecording` / `stopRecording`
### `switchCamera` — Toggle front/back
### `setFlashMode`
**Modes:** `off`, `auto`, `always`, `torch`

### `setZoomLevel`
| Param | Type |
|-------|------|
| `zoom` | `number` |

### `getMinZoomLevel` / `getMaxZoomLevel`
### `setFocusPoint`
| Param | Type |
|-------|------|
| `x` | `number` (0-1) |
| `y` | `number` (0-1) |

### `setExposureMode` — `auto` or `locked`
### `getAvailableCameras` / `getState`

## Events
| Event | Data |
|-------|------|
| `cameraPreview.started` | `{ cameraIndex, lensDirection }` |
| `cameraPreview.stopped` | — |
| `cameraPreview.photoTaken` | `{ path, fileName, size }` |
| `cameraPreview.recordingStarted` | — |
| `cameraPreview.recordingStopped` | `{ path, size }` |

## Usage
```javascript
// Initialize camera
const cameras = await NativeSDK.cameraPreview.getAvailableCameras();
console.log('Cameras:', cameras.count);

await NativeSDK.cameraPreview.start({
  cameraIndex: 0,
  resolution: 'high'
});

// Take photo
const photo = await NativeSDK.cameraPreview.takePhoto({
  fileName: 'avatar_' + Date.now()
});
displayPreview(photo.path);

// Zoom
const { level: maxZoom } = await NativeSDK.cameraPreview.getMaxZoomLevel();
zoomSlider.max = maxZoom;
zoomSlider.oninput = (e) => NativeSDK.cameraPreview.setZoomLevel(+e.target.value);

// Flash toggle
let flashOn = false;
flashBtn.onclick = () => {
  flashOn = !flashOn;
  NativeSDK.cameraPreview.setFlashMode(flashOn ? 'torch' : 'off');
};

// Record video
await NativeSDK.cameraPreview.startRecording();
// ... user records ...
const video = await NativeSDK.cameraPreview.stopRecording();
console.log('Video saved:', video.path);

// Cleanup
await NativeSDK.cameraPreview.stop();
```
```

---

## 📄 `lib/plugins/document_scanner/README.md`

```markdown
# Document Scanner Plugin

Scan documents with automatic edge detection and crop.

## Plugin Name
`documentScanner`

## Methods

### `scan`
| Param | Type | Default |
|-------|------|---------|
| `maxPages` | `number` | `1` |
| `allowGallery` | `bool` | `false` |

**Returns:**
```json
{
  "scanned": true,
  "pages": [
    { "page": 1, "path": "/...", "size": 234567 }
  ],
  "count": 1
}
```

## Usage
```javascript
// Scan single document
const { pages, scanned } = await NativeSDK.documentScanner.scan();
if (scanned) {
  displayDocument(pages[0].path);
}

// Multi-page scan
const { pages } = await NativeSDK.documentScanner.scan({ maxPages: 5 });
if (pages.length > 0) {
  // Create PDF from scanned pages
  const pdf = await NativeSDK.pdf.generateFromHtml({
    html: pages.map(p => `<img src="${p.path}" style="width:100%">`).join(''),
    fileName: 'scanned_document.pdf'
  });
  await NativeSDK.share.shareFiles([pdf.path]);
}

// Scan with gallery import
const { pages } = await NativeSDK.documentScanner.scan({
  maxPages: 3,
  allowGallery: true
});

// Upload scanned document
if (pages.length > 0) {
  const compressed = await NativeSDK.fileCompressor.compressImage(
    pages[0].path, { quality: 85 }
  );
  await uploadToServer(compressed.outputPath);
}
```
```

---

## 📄 `lib/plugins/google_maps/README.md`

```markdown
# Google Maps Plugin

Geocoding, directions, and places search.

## Plugin Name
`googleMaps`

## Setup
```javascript
await NativeSDK.googleMaps.configure({ apiKey: 'YOUR_GOOGLE_MAPS_API_KEY' });
```

## Methods

### `geocode`
| Param | Type | Required |
|-------|------|----------|
| `address` | `string` | ✅ |

**Returns:** `{ found, latitude, longitude, formattedAddress, placeId }`

### `reverseGeocode`
| Param | Type | Required |
|-------|------|----------|
| `latitude` | `number` | ✅ |
| `longitude` | `number` | ✅ |

**Returns:** `{ found, formattedAddress, components }`

### `getDirections`
| Param | Type | Default |
|-------|------|---------|
| `origin` | `string` | ✅ |
| `destination` | `string` | ✅ |
| `mode` | `string` | `"driving"` |

**mode:** `driving`, `walking`, `bicycling`, `transit`

### `searchPlaces`
| Param | Type | Required |
|-------|------|----------|
| `query` | `string` | ✅ |
| `latitude` | `number` | — |
| `longitude` | `number` | — |
| `radius` | `number` | `5000` |

### `getPlaceDetails`
| Param | Type | Required |
|-------|------|----------|
| `placeId` | `string` | ✅ |

### `calculateDistance` — Haversine formula (no API call)
### `getStaticMapUrl` — Generate static map image URL

## Usage
```javascript
await NativeSDK.googleMaps.configure({ apiKey: 'AIza...' });

// Geocode address
const { latitude, longitude } = await NativeSDK.googleMaps.geocode('Tehran, Iran');
showOnMap(latitude, longitude);

// Reverse geocode
const { formattedAddress } = await NativeSDK.googleMaps.reverseGeocode(35.6892, 51.3890);
document.getElementById('address').textContent = formattedAddress;

// Directions
const route = await NativeSDK.googleMaps.getDirections('Tehran', 'Isfahan', 'driving');
console.log(`Distance: ${route.distance.text}, ETA: ${route.duration.text}`);

// Nearby search
const { places } = await NativeSDK.googleMaps.searchPlaces('coffee shop', {
  latitude: 35.6892, longitude: 51.3890, radius: 1000
});
places.forEach(p => addMarker(p.latitude, p.longitude, p.name));

// Distance calculation (no API)
const { distanceKm } = NativeSDK.googleMaps.calculateDistance(35.69, 51.39, 32.65, 51.67);

// Static map for sharing
const { url } = NativeSDK.googleMaps.getStaticMapUrl(35.6892, 51.3890, { zoom: 15 });
```
```

---

## 📄 `lib/plugins/social_login/README.md`

```markdown
# Social Login Plugin

Authenticate with Google and Phone (SMS).

## Plugin Name
`socialLogin`

## Methods

### `signInWithGoogle`
**Returns:**
```json
{ "success": true, "user": { "uid": "...", "email": "...", "displayName": "..." }, "isNewUser": false }
```

### `signInWithPhone`
| Param | Type | Required |
|-------|------|----------|
| `phoneNumber` | `string` | ✅ (E.164 format) |

**Returns:** `{ success: true, codeSent: true, verificationId: "..." }`

### `verifyPhoneCode`
| Param | Type | Required |
|-------|------|----------|
| `code` | `string` | ✅ |
| `verificationId` | `string` | — |

### `signInAnonymously` / `signOut`
### `linkWithGoogle` — Link Google to existing account
### `getCurrentUser` / `isSignedIn` / `getProviders`

## Events
| Event | Data |
|-------|------|
| `socialLogin.signedIn` | `{ provider, user }` |
| `socialLogin.signedOut` | — |

## Usage
```javascript
// Google Sign In
const { success, user, isNewUser } = await NativeSDK.socialLogin.signInWithGoogle();
if (success) {
  if (isNewUser) await createProfile(user);
  router.navigate('/home');
}

// Phone Auth
const step1 = await NativeSDK.socialLogin.signInWithPhone('+989123456789');
if (step1.codeSent) {
  const code = await showOtpDialog();
  const result = await NativeSDK.socialLogin.verifyPhoneCode(code, step1.verificationId);
  if (result.success) router.navigate('/home');
}

// Check current user
const { signedIn, user } = await NativeSDK.socialLogin.getCurrentUser();
if (!signedIn) router.navigate('/login');

// Sign out
await NativeSDK.socialLogin.signOut();
```
```

---

## 📄 `lib/plugins/in_app_purchase/README.md`

```markdown
# In-App Purchase Plugin

Native in-app purchases and subscriptions.

## Plugin Name
`inAppPurchase`

## Methods

### `isAvailable`
**Returns:** `{ available: bool }`

### `getProducts`
| Param | Type | Required |
|-------|------|----------|
| `productIds` | `string[]` | ✅ |

**Returns:**
```json
{
  "products": [
    { "id": "premium_monthly", "title": "Premium Monthly", "price": "$4.99", "rawPrice": 4.99, "currencyCode": "USD" }
  ]
}
```

### `buyProduct` / `buySubscription`
| Param | Type | Required |
|-------|------|----------|
| `productId` | `string` | ✅ |

### `restorePurchases`

## Events
| Event | Data |
|-------|------|
| `purchase.pending` | `{ productId, status }` |
| `purchase.completed` | `{ productId, purchaseId, transactionDate }` |
| `purchase.cancelled` | `{ productId }` |
| `purchase.error` | `{ productId, errorCode, errorMessage }` |

## Usage
```javascript
// Load products
const { available } = await NativeSDK.inAppPurchase.isAvailable();
if (!available) return;

const { products } = await NativeSDK.inAppPurchase.getProducts([
  'premium_monthly',
  'premium_yearly',
  'remove_ads'
]);

// Display products
products.forEach(p => {
  addProductCard(p.title, p.price, p.id);
});

// Handle purchase events FIRST
NativeSDK.on('purchase.completed', async (data) => {
  // Verify with your backend
  const valid = await verifyPurchase(data.productId, data.purchaseId);
  if (valid) {
    await unlockPremium();
    await NativeSDK.toast.show('Purchase successful! 🎉');
  }
});

NativeSDK.on('purchase.error', (data) => {
  NativeSDK.toast.show('Purchase failed: ' + data.errorMessage, { duration: 'long' });
});

// Buy
await NativeSDK.inAppPurchase.buySubscription('premium_monthly');

// Restore
await NativeSDK.inAppPurchase.restorePurchases();
```
```

---

## 📄 `lib/plugins/oauth2/README.md`

```markdown
# OAuth2 Plugin

Generic OAuth2 authentication for any provider.

## Plugin Name
`oauth2`

## Methods

### `authorize`
| Param | Type | Required |
|-------|------|----------|
| `authUrl` | `string` | ✅ |
| `clientId` | `string` | ✅ |
| `redirectUri` | `string` | ✅ |
| `scope` | `string` | — |
| `responseType` | `string` | `"code"` |
| `state` | `string` | — |
| `extraParams` | `object` | — |

**Returns:**
```json
{ "success": true, "code": "auth_code_here", "state": "...", "redirectUrl": "..." }
```

### `exchangeCode`
| Param | Type | Required |
|-------|------|----------|
| `tokenUrl` | `string` | ✅ |
| `code` | `string` | ✅ |
| `clientId` | `string` | ✅ |
| `redirectUri` | `string` | ✅ |
| `clientSecret` | `string` | — |
| `codeVerifier` | `string` | — (PKCE) |

**Returns:** `{ accessToken, refreshToken, expiresIn, tokenType, idToken }`

### `refreshToken`
| Param | Type | Required |
|-------|------|----------|
| `tokenUrl` | `string` | ✅ |
| `refreshToken` | `string` | ✅ |
| `clientId` | `string` | ✅ |

## Usage
```javascript
// GitHub OAuth
const auth = await NativeSDK.oauth2.authorize({
  authUrl: 'https://github.com/login/oauth/authorize',
  clientId: 'your_github_client_id',
  redirectUri: 'sweetmelon://oauth/callback',
  scope: 'user repo'
});

if (auth.success && auth.code) {
  const tokens = await NativeSDK.oauth2.exchangeCode({
    tokenUrl: 'https://github.com/login/oauth/access_token',
    code: auth.code,
    clientId: 'your_github_client_id',
    clientSecret: 'your_secret',
    redirectUri: 'sweetmelon://oauth/callback'
  });
  
  await NativeSDK.secureStorage.set('github_token', tokens.accessToken);
  loadUserProfile(tokens.accessToken);
}

// Discord OAuth with PKCE
const auth = await NativeSDK.oauth2.authorize({
  authUrl: 'https://discord.com/api/oauth2/authorize',
  clientId: 'your_discord_client_id',
  redirectUri: 'sweetmelon://oauth/discord',
  scope: 'identify guilds',
  responseType: 'code'
});

// Refresh token
const newTokens = await NativeSDK.oauth2.refreshToken({
  tokenUrl: 'https://api.example.com/oauth/token',
  refreshToken: await NativeSDK.secureStorage.get('refresh_token'),
  clientId: 'your_client_id'
});
```
```

---

# README — Live Updater

## 📄 `lib/plugins/live_updater/README.md`

```markdown
# Live Updater Plugin

Deploy updates to www assets without Play Store review.

## Plugin Name
`liveUpdater`

## Methods

### `configure`
| Param | Type | Required | Default |
|-------|------|----------|---------|
| `serverUrl` | `string` | ✅ | — |
| `apiKey` | `string` | — | — |
| `channel` | `string` | — | `"production"` |
| `currentVersion` | `string` | — | — |

### `checkForUpdate`
**Returns:**
```json
{ "available": true, "currentVersion": "1.0.0", "newVersion": "1.1.0", "size": 524288 }
```

### `downloadUpdate`
Downloads bundle with progress events.

### `applyUpdate`
Apply downloaded bundle. Requires reload.

**Returns:**
```json
{ "applied": true, "previousVersion": "1.0.0", "newVersion": "1.1.0", "requiresReload": true }
```

### `checkAndApply`
One-step: check + download + apply.
| Param | Type | Default |
|-------|------|---------|
| `silent` | `bool` | `false` |

### `rollback`
Revert to previous version.

### `getCurrentVersion` / `getAvailableUpdate` / `getStatus`
### `getUpdateHistory` / `setChannel` / `reset`

## Events
| Event | Data |
|-------|------|
| `update.available` | `{ version, size, currentVersion }` |
| `update.downloadProgress` | `{ percent, receivedBytes, totalBytes }` |
| `update.downloaded` | `{ version, size }` |
| `update.applied` | `{ previousVersion, newVersion, requiresReload }` |
| `update.rolledBack` | `{ version, requiresReload }` |
| `update.autoRolledBack` | `{ reason, failCount }` |

## Server API Required

```
GET /api/updates/check
Headers:
  X-Current-Version: 1.0.0
  X-Channel: production
  X-Platform: android

Response:
{
  "updateAvailable": true,
  "latestVersion": "1.1.0",
  "bundle": {
    "version": "1.1.0",
    "url": "https://cdn.myapp.com/bundles/1.1.0.zip",
    "checksum": "sha256...",
    "size": 524288
  }
}
```

## Bundle Format
ZIP file containing:
```
1.1.0.zip
├── index.html    ← required
├── css/
├── js/
└── assets/
```

## Usage

### Basic (manual update)
```javascript
await NativeSDK.liveUpdater.configure({
  serverUrl: 'https://updates.myapp.com',
  channel: 'production'
});

const check = await NativeSDK.liveUpdater.checkForUpdate();
if (check.available) {
  
  NativeSDK.on('update.downloadProgress', (data) => {
    progressBar.style.width = data.percent + '%';
  });
  
  await NativeSDK.liveUpdater.downloadUpdate();
  await NativeSDK.liveUpdater.applyUpdate();
  location.reload();
}
```

### Silent background update
```javascript
// Check on startup silently
NativeSDK.waitForReady().then(async () => {
  await NativeSDK.liveUpdater.configure({
    serverUrl: 'https://updates.myapp.com'
  });
  
  const result = await NativeSDK.liveUpdater.checkAndApply({ silent: true });
  if (result.updated) {
    await NativeSDK.toast.show('App updated to v' + result.newVersion);
    setTimeout(() => location.reload(), 2000);
  }
});
```

### Channel management
```javascript
// Beta testers
await NativeSDK.liveUpdater.setChannel('beta');

// Production
await NativeSDK.liveUpdater.setChannel('production');

// Rollback if issues
NativeSDK.on('update.autoRolledBack', async (data) => {
  console.error('Auto-rollback:', data.reason);
  await NativeSDK.firebaseCrashlytics.recordError('Update auto-rolled back', 'UpdateError');
  location.reload();
});
```

## Notes
- Rolled back automatically after 3 consecutive load failures
- Bundle must contain `index.html` in root
- No size limit (but recommend < 10MB for good UX)
- Supports channels: `production`, `staging`, `beta`
```

---

# خلاصه نهایی

## آمار README‌ها

| وضعیت | تعداد |
|--------|-------|
| ✅ از قبل داشتیم (فاز ۱-۵) | 35 |
| ✅ الان نوشتیم (فاز ۶-۱۷+) | 56 |
| **مجموع** | **91** |

## ساختار README هر پلاگین

همه ۹۱ README این ساختار رو دارن:

```markdown
# Plugin Name
توضیح یک‌خطی

## Plugin Name
`jsNamespace`

## Methods
جدول پارامترها

## Events (اگه داره)
جدول eventها

## Usage
نمونه کد واقعی ۵-۱۰ خطی
```
