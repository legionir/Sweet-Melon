عالی.  
در این مرحله، من **بخش دوم** را کامل می‌دهم:

1. **pubspec.yaml برای هر plugin package**
2. **تنظیمات AndroidManifest + network config برای deep link / url launch / http**
3. **تست‌سوئیت کامل HTML/CSS/JS برای همه پلاگین‌ها**
4. **افزودن تست Camera و Geolocation در UI**
5. **فایل `window.NativeSDK` برای استفاده راحت در Angular/React**
6. **فایل Type Definition برای TS/Angular**

---

# 1) فایل‌های `pubspec.yaml` برای هر Plugin Package

> این‌ها مطابق معماری فعلی پوشه‌بندی شما هستند.  
> یعنی در مسیرهای:
> `lib/plugins/<plugin_name>/pubspec.yaml`

---

## 📄 `lib/plugins/permission/pubspec.yaml`

```yaml
name: permission_plugin
description: Permission bridge plugin for Flutter Native Bridge
version: 1.0.0

environment:
  sdk: ^3.0.0

dependencies:
  flutter:
    sdk: flutter
  plugin_engine:
    path: ../../packages/plugin_engine
  security:
    path: ../../packages/security
  permission_handler: ^11.3.0
```

---

## 📄 `lib/plugins/app_lifecycle/pubspec.yaml`

```yaml
name: app_lifecycle_plugin
description: App lifecycle bridge plugin
version: 1.0.0

environment:
  sdk: ^3.0.0

dependencies:
  flutter:
    sdk: flutter
  plugin_engine:
    path: ../../packages/plugin_engine
  core:
    path: ../../packages/core
```

---

## 📄 `lib/plugins/device_info/pubspec.yaml`

```yaml
name: device_info_bridge_plugin
description: Device info and app info bridge plugin
version: 1.0.0

environment:
  sdk: ^3.0.0

dependencies:
  flutter:
    sdk: flutter
  plugin_engine:
    path: ../../packages/plugin_engine
  device_info_plus: ^10.1.2
  package_info_plus: ^8.0.2
```

---

## 📄 `lib/plugins/connectivity/pubspec.yaml`

```yaml
name: connectivity_bridge_plugin
description: Connectivity bridge plugin
version: 1.0.0

environment:
  sdk: ^3.0.0

dependencies:
  flutter:
    sdk: flutter
  plugin_engine:
    path: ../../packages/plugin_engine
  core:
    path: ../../packages/core
  connectivity_plus: ^6.0.5
```

---

## 📄 `lib/plugins/storage/pubspec.yaml`

```yaml
name: storage_plugin
description: Key-value storage plugin for Flutter Native Bridge
version: 1.0.0

environment:
  sdk: ^3.0.0

dependencies:
  flutter:
    sdk: flutter
  shared_preferences: ^2.2.2
  plugin_engine:
    path: ../../packages/plugin_engine
```

---

## 📄 `lib/plugins/file_system/pubspec.yaml`

```yaml
name: file_system_plugin
description: Sandboxed file system plugin
version: 1.0.0

environment:
  sdk: ^3.0.0

dependencies:
  flutter:
    sdk: flutter
  plugin_engine:
    path: ../../packages/plugin_engine
  path_provider: ^2.1.1
  path: ^1.9.0
```

---

## 📄 `lib/plugins/http_native/pubspec.yaml`

```yaml
name: http_native_plugin
description: Native HTTP bridge plugin
version: 1.0.0

environment:
  sdk: ^3.0.0

dependencies:
  flutter:
    sdk: flutter
  plugin_engine:
    path: ../../packages/plugin_engine
  http: ^1.1.2
  mime: ^1.0.5
  path_provider: ^2.1.1
  path: ^1.9.0
```

---

## 📄 `lib/plugins/intent_link/pubspec.yaml`

```yaml
name: intent_link_plugin
description: Intent and deep link bridge plugin
version: 1.0.0

environment:
  sdk: ^3.0.0

dependencies:
  flutter:
    sdk: flutter
  plugin_engine:
    path: ../../packages/plugin_engine
  core:
    path: ../../packages/core
  url_launcher: ^6.3.0
  app_links: ^6.3.2
```

---

## 📄 `lib/plugins/clipboard/pubspec.yaml`

```yaml
name: clipboard_plugin
description: Clipboard bridge plugin
version: 1.0.0

environment:
  sdk: ^3.0.0

dependencies:
  flutter:
    sdk: flutter
  plugin_engine:
    path: ../../packages/plugin_engine
```

---

## 📄 `lib/plugins/share/pubspec.yaml`

```yaml
name: share_bridge_plugin
description: Native share bridge plugin
version: 1.0.0

environment:
  sdk: ^3.0.0

dependencies:
  flutter:
    sdk: flutter
  plugin_engine:
    path: ../../packages/plugin_engine
  share_plus: ^10.0.2
  cross_file: ^0.3.4+2
```

---

## 📄 `lib/plugins/geolocation/pubspec.yaml`

```yaml
name: geolocation_plugin
description: Geolocation plugin for Flutter Native Bridge
version: 1.0.0

environment:
  sdk: ^3.0.0

dependencies:
  flutter:
    sdk: flutter
  geolocator: ^10.1.0
  plugin_engine:
    path: ../../packages/plugin_engine
  core:
    path: ../../packages/core
```

---

## 📄 `lib/plugins/camera/pubspec.yaml`

```yaml
name: camera_plugin
description: Camera plugin for Flutter Native Bridge
version: 1.0.0

environment:
  sdk: ^3.0.0

dependencies:
  flutter:
    sdk: flutter
  image_picker: ^1.0.4
  plugin_engine:
    path: ../../packages/plugin_engine
```

---

# 2) تنظیمات Android برای Deep Link / Intent / HTTP / Share / Native URL Launch

---

## 📄 `android/app/src/main/AndroidManifest.xml`

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">

    <!-- Network -->
    <uses-permission android:name="android.permission.INTERNET"/>
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/>

    <!-- Media / Camera -->
    <uses-permission android:name="android.permission.CAMERA"/>
    <uses-permission android:name="android.permission.RECORD_AUDIO"/>

    <!-- Legacy storage permissions -->
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" android:maxSdkVersion="32"/>
    <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" android:maxSdkVersion="28"/>

    <!-- Android 13+ media permissions -->
    <uses-permission android:name="android.permission.READ_MEDIA_IMAGES"/>
    <uses-permission android:name="android.permission.READ_MEDIA_VIDEO"/>
    <uses-permission android:name="android.permission.READ_MEDIA_AUDIO"/>

    <!-- Location -->
    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>

    <!-- Notifications -->
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>

    <application
        android:label="sweetmelon"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher"
        android:usesCleartextTraffic="true"
        android:networkSecurityConfig="@xml/network_security_config"
        android:requestLegacyExternalStorage="true">

        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:launchMode="singleTop"
            android:taskAffinity=""
            android:theme="@style/LaunchTheme"
            android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
            android:hardwareAccelerated="true"
            android:windowSoftInputMode="adjustResize"
            android:enableOnBackInvokedCallback="true">

            <meta-data
                android:name="io.flutter.embedding.android.NormalTheme"
                android:resource="@style/NormalTheme"/>

            <!-- Launcher -->
            <intent-filter>
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.LAUNCHER"/>
            </intent-filter>

            <!-- Custom deep link -->
            <intent-filter>
                <action android:name="android.intent.action.VIEW"/>
                <category android:name="android.intent.category.DEFAULT"/>
                <category android:name="android.intent.category.BROWSABLE"/>
                <data android:scheme="sweetmelon"/>
            </intent-filter>

            <!-- Example https deep link
                 بعدا host واقعی خودت را جایگزین کن -->
            <intent-filter>
                <action android:name="android.intent.action.VIEW"/>
                <category android:name="android.intent.category.DEFAULT"/>
                <category android:name="android.intent.category.BROWSABLE"/>
                <data
                    android:scheme="https"
                    android:host="app.sweetmelon.local"/>
            </intent-filter>
        </activity>

        <meta-data
            android:name="flutterEmbedding"
            android:value="2"/>

        <provider
            android:name="androidx.core.content.FileProvider"
            android:authorities="${applicationId}.fileprovider"
            android:exported="false"
            android:grantUriPermissions="true">
            <meta-data
                android:name="android.support.FILE_PROVIDER_PATHS"
                android:resource="@xml/file_paths"/>
        </provider>
    </application>

    <!-- Android 11+ package visibility / url_launcher / canLaunchUrl -->
    <queries>
        <intent>
            <action android:name="android.intent.action.PROCESS_TEXT"/>
            <data android:mimeType="text/plain"/>
        </intent>

        <intent>
            <action android:name="android.intent.action.VIEW"/>
            <data android:scheme="http"/>
        </intent>

        <intent>
            <action android:name="android.intent.action.VIEW"/>
            <data android:scheme="https"/>
        </intent>

        <intent>
            <action android:name="android.intent.action.VIEW"/>
            <data android:scheme="tel"/>
        </intent>

        <intent>
            <action android:name="android.intent.action.VIEW"/>
            <data android:scheme="sms"/>
        </intent>

        <intent>
            <action android:name="android.intent.action.VIEW"/>
            <data android:scheme="smsto"/>
        </intent>

        <intent>
            <action android:name="android.intent.action.VIEW"/>
            <data android:scheme="mailto"/>
        </intent>

        <intent>
            <action android:name="android.intent.action.VIEW"/>
            <data android:scheme="geo"/>
        </intent>

        <intent>
            <action android:name="android.intent.action.VIEW"/>
            <data android:scheme="market"/>
        </intent>

        <intent>
            <action android:name="android.intent.action.SEND"/>
            <data android:mimeType="text/plain"/>
        </intent>

        <intent>
            <action android:name="android.intent.action.SEND"/>
            <data android:mimeType="*/*"/>
        </intent>
    </queries>
</manifest>
```

---

## 📄 `android/app/src/main/res/xml/network_security_config.xml`

```xml
<?xml version="1.0" encoding="utf-8"?>
<network-security-config>

    <!-- برای توسعه و لود پروژه‌های html از localhost -->
    <domain-config cleartextTrafficPermitted="true">
        <domain includeSubdomains="true">localhost</domain>
    </domain-config>

    <!-- به دلیل استفاده از AssetServer داخلی و گاهی آدرس‌های http در dev -->
    <base-config cleartextTrafficPermitted="true">
        <trust-anchors>
            <certificates src="system"/>
            <certificates src="user"/>
        </trust-anchors>
    </base-config>

</network-security-config>
```

---

## 📄 `android/app/src/main/res/xml/file_paths.xml`

```xml
<?xml version="1.0" encoding="utf-8"?>
<paths>
    <external-path name="external_files" path="."/>
    <cache-path name="cache" path="."/>
    <files-path name="files" path="."/>
</paths>
```

---

# 3) تست‌سوئیت کامل HTML برای همه پلاگین‌ها

> این تست‌سوئیت روی همان مسیر ثابت شما می‌نشیند:
> `assets/www/index.html`

---

## 📄 `assets/www/index.html`

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta
    name="viewport"
    content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no"
  />
  <title>Sweetmelon Native Bridge Test Suite</title>
  <link rel="stylesheet" href="css/styles.css" />
</head>
<body>
  <div class="container">
    <header class="page-header">
      <div>
        <h1>Sweetmelon Native Bridge</h1>
        <p>Full HTML test suite for JS ↔ Android Native plugins</p>
      </div>
      <div class="header-actions">
        <button class="secondary" id="btnBridgeInfo">Bridge Info</button>
        <button class="secondary" id="btnClearLog">Clear Log</button>
      </div>
    </header>

    <section class="status-grid">
      <div class="status-card">
        <span class="status-label">Bridge</span>
        <strong id="bridgeState">Waiting...</strong>
      </div>
      <div class="status-card">
        <span class="status-label">Requests</span>
        <strong id="requestCount">0</strong>
      </div>
      <div class="status-card">
        <span class="status-label">Pending</span>
        <strong id="pendingCount">0</strong>
      </div>
      <div class="status-card">
        <span class="status-label">Events</span>
        <strong id="eventCount">0</strong>
      </div>
    </section>

    <section class="panel">
      <div class="panel-title">Permission</div>
      <div class="row">
        <input id="permissionName" value="camera" placeholder="camera / location / notification" />
        <button id="btnPermissionCheck">Check</button>
        <button id="btnPermissionRequest">Request</button>
        <button id="btnPermissionKnown">Known Permissions</button>
      </div>
    </section>

    <section class="panel">
      <div class="panel-title">App Lifecycle</div>
      <div class="row">
        <button id="btnLifecycleState">Get State</button>
        <button id="btnLifecycleEnable">Enable Events</button>
        <button id="btnLifecycleDisable">Disable Events</button>
        <button id="btnLifecycleInfo">Get Info</button>
      </div>
    </section>

    <section class="panel">
      <div class="panel-title">Device Info</div>
      <div class="row">
        <button id="btnDeviceInfo">Device Info</button>
        <button id="btnAppInfo">App Info</button>
        <button id="btnDeviceAll">Get All</button>
      </div>
    </section>

    <section class="panel">
      <div class="panel-title">Connectivity</div>
      <div class="row">
        <button id="btnConnectivityStatus">Get Status</button>
        <button id="btnConnectivityStart">Start Watch</button>
        <button id="btnConnectivityStop">Stop Watch</button>
        <button id="btnConnectivityIsOnline">Is Online?</button>
      </div>
    </section>

    <section class="panel">
      <div class="panel-title">Storage</div>
      <div class="row">
        <input id="storageKey" value="demo_key" placeholder="key" />
        <input id="storageValue" value='{"hello":"world"}' placeholder='JSON value' />
      </div>
      <div class="row">
        <button id="btnStorageSet">Set</button>
        <button id="btnStorageGet">Get</button>
        <button id="btnStorageHas">Has</button>
        <button id="btnStorageKeys">Keys</button>
        <button id="btnStorageRemove">Remove</button>
        <button id="btnStorageClear">Clear</button>
      </div>
    </section>

    <section class="panel">
      <div class="panel-title">File System</div>
      <div class="row">
        <input id="filePath" value="demo/test.txt" placeholder="relative file path" />
        <input id="fileContent" value="Hello from WebView + Native file system" placeholder="file content" />
      </div>
      <div class="row">
        <button id="btnFsDirs">Directories</button>
        <button id="btnFsWrite">Write File</button>
        <button id="btnFsRead">Read File</button>
        <button id="btnFsExists">Exists</button>
        <button id="btnFsList">List Files</button>
        <button id="btnFsStat">Stat</button>
        <button id="btnFsDelete">Delete File</button>
      </div>
    </section>

    <section class="panel">
      <div class="panel-title">HTTP Native</div>
      <div class="row">
        <input id="httpUrl" value="https://jsonplaceholder.typicode.com/todos/1" placeholder="https://example.com/api" />
      </div>
      <div class="row">
        <button id="btnHttpGet">GET</button>
        <button id="btnHttpPost">POST</button>
        <button id="btnHttpDownload">Download</button>
      </div>
    </section>

    <section class="panel">
      <div class="panel-title">Intent / Deep Link</div>
      <div class="row">
        <input id="intentUrl" value="https://flutter.dev" placeholder="url / tel: / mailto: / sweetmelon://" />
      </div>
      <div class="row">
        <button id="btnIntentCanOpen">Can Open</button>
        <button id="btnIntentOpen">Open URL</button>
        <button id="btnIntentInitial">Initial Link</button>
        <button id="btnIntentLatest">Latest Link</button>
        <button id="btnIntentListenStart">Start Listen</button>
        <button id="btnIntentListenStop">Stop Listen</button>
      </div>
    </section>

    <section class="panel">
      <div class="panel-title">Clipboard</div>
      <div class="row">
        <input id="clipboardText" value="Copied from Sweetmelon bridge" placeholder="clipboard text" />
      </div>
      <div class="row">
        <button id="btnClipboardWrite">Write</button>
        <button id="btnClipboardRead">Read</button>
        <button id="btnClipboardHas">Has Text?</button>
        <button id="btnClipboardClear">Clear</button>
      </div>
    </section>

    <section class="panel">
      <div class="panel-title">Share</div>
      <div class="row">
        <input id="shareText" value="Hello from Sweetmelon native share" placeholder="share text" />
      </div>
      <div class="row">
        <button id="btnShareText">Share Text</button>
        <button id="btnShareFile">Create & Share File</button>
      </div>
    </section>

    <section class="panel">
      <div class="panel-title">Camera</div>
      <div class="row">
        <button id="btnCameraInfo">Get Info</button>
        <button id="btnTakePhoto">Take Photo</button>
        <button id="btnPickGallery">Pick Gallery</button>
      </div>
    </section>

    <section class="panel">
      <div class="panel-title">Geolocation</div>
      <div class="row">
        <button id="btnGeoPermission">Check Permission</button>
        <button id="btnGeoRequestPermission">Request Permission</button>
        <button id="btnGeoCurrent">Get Current Position</button>
        <button id="btnGeoStart">Start Watch</button>
        <button id="btnGeoStop">Stop Watch</button>
        <button id="btnGeoEnabled">Location Enabled?</button>
      </div>
    </section>

    <section class="panel">
      <div class="panel-title">Output</div>
      <pre id="output" class="output">{}</pre>
    </section>

    <section class="panel">
      <div class="panel-title">Event / Console Log</div>
      <div id="log" class="log"></div>
    </section>
  </div>

  <script src="js/native-sdk.js"></script>
  <script src="js/app.js"></script>
</body>
</html>
```

---

## 📄 `assets/www/css/styles.css`

```css
* {
  box-sizing: border-box;
}

html,
body {
  margin: 0;
  padding: 0;
  background: #0b1020;
  color: #e8ecf3;
  font-family: Inter, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
  min-height: 100%;
}

body {
  padding: 16px;
}

.container {
  max-width: 1100px;
  margin: 0 auto;
}

.page-header {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  gap: 16px;
  margin-bottom: 20px;
}

.page-header h1 {
  margin: 0;
  font-size: 26px;
  background: linear-gradient(135deg, #7b6dff, #21d4c8);
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
}

.page-header p {
  margin: 8px 0 0;
  color: #9aa6b2;
  font-size: 14px;
}

.header-actions {
  display: flex;
  gap: 8px;
  flex-wrap: wrap;
}

.status-grid {
  display: grid;
  grid-template-columns: repeat(4, minmax(120px, 1fr));
  gap: 12px;
  margin-bottom: 20px;
}

.status-card,
.panel {
  background: #121a2d;
  border: 1px solid #21304f;
  border-radius: 14px;
  box-shadow: 0 8px 24px rgba(0, 0, 0, 0.16);
}

.status-card {
  padding: 14px;
}

.status-label {
  display: block;
  font-size: 12px;
  color: #8ea0c0;
  margin-bottom: 6px;
}

.status-card strong {
  font-size: 18px;
}

.panel {
  padding: 16px;
  margin-bottom: 16px;
}

.panel-title {
  font-size: 15px;
  font-weight: 700;
  margin-bottom: 12px;
  color: #8dc3ff;
  letter-spacing: 0.3px;
}

.row {
  display: flex;
  flex-wrap: wrap;
  gap: 10px;
  margin-bottom: 10px;
}

.row:last-child {
  margin-bottom: 0;
}

input,
textarea,
button {
  border-radius: 10px;
  border: 1px solid #2b3b61;
  background: #0f1629;
  color: #e8ecf3;
  font-size: 14px;
}

input,
textarea {
  padding: 12px 14px;
  outline: none;
  min-width: 180px;
  flex: 1;
}

textarea {
  min-height: 120px;
  resize: vertical;
}

button {
  padding: 11px 14px;
  cursor: pointer;
  transition: all 0.18s ease;
  background: linear-gradient(135deg, rgba(123, 109, 255, 0.20), rgba(33, 212, 200, 0.15));
  border-color: #40588f;
  font-weight: 600;
}

button:hover {
  transform: translateY(-1px);
  border-color: #6e8dd8;
}

button.secondary {
  background: #16213a;
}

.output {
  background: #0b1222;
  border: 1px solid #243456;
  border-radius: 10px;
  padding: 14px;
  min-height: 180px;
  overflow: auto;
  white-space: pre-wrap;
  word-break: break-word;
  font-family: ui-monospace, SFMono-Regular, Menlo, Consolas, monospace;
  font-size: 12px;
  line-height: 1.6;
}

.log {
  background: #09101e;
  border: 1px solid #223253;
  border-radius: 10px;
  min-height: 220px;
  max-height: 360px;
  overflow: auto;
  padding: 10px;
}

.log-item {
  font-family: ui-monospace, SFMono-Regular, Menlo, Consolas, monospace;
  font-size: 12px;
  line-height: 1.55;
  padding: 6px 8px;
  border-bottom: 1px solid rgba(255,255,255,0.04);
  word-break: break-word;
}

.log-item:last-child {
  border-bottom: 0;
}

.log-info {
  color: #87b9ff;
}

.log-success {
  color: #6fe3a4;
}

.log-error {
  color: #ff8989;
}

.log-event {
  color: #f8cf6d;
}

@media (max-width: 820px) {
  .status-grid {
    grid-template-columns: repeat(2, minmax(120px, 1fr));
  }

  .page-header {
    flex-direction: column;
  }
}

@media (max-width: 520px) {
  .status-grid {
    grid-template-columns: 1fr 1fr;
  }

  input,
  button {
    width: 100%;
  }

  .row {
    flex-direction: column;
  }
}
```

---

# 4) فایل `window.NativeSDK` برای Angular / React / JS خام

---

## 📄 `assets/www/js/native-sdk.js`

```javascript
(function (global) {
  'use strict';

  function assertBridge() {
    if (!global.Native || typeof global.Native.call !== 'function') {
      throw new Error('Native bridge is not ready');
    }
  }

  function call(plugin, method, args, extra) {
    assertBridge();
    return global.Native.call(
      Object.assign(
        {
          plugin: plugin,
          method: method,
          args: args || {}
        },
        extra || {}
      )
    );
  }

  function batch(requests, options) {
    assertBridge();
    return global.Native.batch(requests, options || {});
  }

  function on(event, callback) {
    assertBridge();
    return global.Native.on(event, callback);
  }

  function off(event, callback) {
    assertBridge();
    return global.Native.off(event, callback);
  }

  function info() {
    if (!global.Native || !global.Native.info) {
      return {
        initialized: false,
        pendingRequests: 0,
        totalRequests: 0,
        version: null
      };
    }
    return global.Native.info();
  }

  function waitForReady(timeoutMs) {
    var timeout = typeof timeoutMs === 'number' ? timeoutMs : 8000;

    return new Promise(function (resolve, reject) {
      if (global.Native && typeof global.Native.call === 'function') {
        resolve(info());
        return;
      }

      var elapsed = 0;
      var step = 50;

      var timer = setInterval(function () {
        elapsed += step;

        if (global.Native && typeof global.Native.call === 'function') {
          clearInterval(timer);
          resolve(info());
          return;
        }

        if (elapsed >= timeout) {
          clearInterval(timer);
          reject(new Error('Native bridge ready timeout'));
        }
      }, step);
    });
  }

  var sdk = {
    call: call,
    batch: batch,
    on: on,
    off: off,
    info: info,
    waitForReady: waitForReady,

    permission: {
      check: function (permission) {
        return call('permission', 'check', { permission: permission });
      },
      request: function (permission) {
        return call('permission', 'request', { permission: permission });
      },
      checkMany: function (permissions) {
        return call('permission', 'checkMany', { permissions: permissions });
      },
      requestMany: function (permissions) {
        return call('permission', 'requestMany', { permissions: permissions });
      },
      openSettings: function () {
        return call('permission', 'openSettings', {});
      },
      getKnownPermissions: function () {
        return call('permission', 'getKnownPermissions', {});
      }
    },

    appLifecycle: {
      getState: function () {
        return call('appLifecycle', 'getState', {});
      },
      enableEvents: function () {
        return call('appLifecycle', 'enableEvents', {});
      },
      disableEvents: function () {
        return call('appLifecycle', 'disableEvents', {});
      },
      getInfo: function () {
        return call('appLifecycle', 'getInfo', {});
      }
    },

    deviceInfo: {
      getDeviceInfo: function () {
        return call('deviceInfo', 'getDeviceInfo', {});
      },
      getAppInfo: function () {
        return call('deviceInfo', 'getAppInfo', {});
      },
      getAll: function () {
        return call('deviceInfo', 'getAll', {});
      }
    },

    connectivity: {
      getStatus: function () {
        return call('connectivity', 'getStatus', {});
      },
      isOnline: function () {
        return call('connectivity', 'isOnline', {});
      },
      startWatch: function () {
        return call('connectivity', 'startWatch', {});
      },
      stopWatch: function () {
        return call('connectivity', 'stopWatch', {});
      },
      getInfo: function () {
        return call('connectivity', 'getInfo', {});
      }
    },

    storage: {
      get: function (key) {
        return call('storage', 'get', { key: key });
      },
      set: function (key, value) {
        return call('storage', 'set', { key: key, value: value });
      },
      remove: function (key) {
        return call('storage', 'remove', { key: key });
      },
      clear: function () {
        return call('storage', 'clear', {});
      },
      keys: function () {
        return call('storage', 'keys', {});
      },
      has: function (key) {
        return call('storage', 'has', { key: key });
      }
    },

    fileSystem: {
      getDirectories: function () {
        return call('fileSystem', 'getDirectories', {});
      },
      readFile: function (path, baseDir, encoding) {
        return call('fileSystem', 'readFile', {
          path: path,
          baseDir: baseDir || 'documents',
          encoding: encoding || 'utf8'
        });
      },
      writeFile: function (path, content, options) {
        var o = options || {};
        return call('fileSystem', 'writeFile', {
          path: path,
          content: content,
          baseDir: o.baseDir || 'documents',
          encoding: o.encoding || 'utf8',
          append: !!o.append
        });
      },
      deleteFile: function (path, baseDir) {
        return call('fileSystem', 'deleteFile', {
          path: path,
          baseDir: baseDir || 'documents'
        });
      },
      fileExists: function (path, baseDir) {
        return call('fileSystem', 'fileExists', {
          path: path,
          baseDir: baseDir || 'documents'
        });
      },
      listFiles: function (path, options) {
        var o = options || {};
        return call('fileSystem', 'listFiles', {
          path: path || '',
          baseDir: o.baseDir || 'documents',
          recursive: !!o.recursive
        });
      },
      createDirectory: function (path, options) {
        var o = options || {};
        return call('fileSystem', 'createDirectory', {
          path: path,
          baseDir: o.baseDir || 'documents',
          recursive: o.recursive !== false
        });
      },
      deleteDirectory: function (path, options) {
        var o = options || {};
        return call('fileSystem', 'deleteDirectory', {
          path: path,
          baseDir: o.baseDir || 'documents',
          recursive: !!o.recursive
        });
      },
      stat: function (path, options) {
        var o = options || {};
        return call('fileSystem', 'stat', {
          path: path,
          baseDir: o.baseDir || 'documents',
          type: o.type || 'file'
        });
      }
    },

    http: {
      request: function (options) {
        return call('http', 'request', options || {});
      },
      get: function (url, options) {
        return call('http', 'get', Object.assign({ url: url }, options || {}));
      },
      post: function (url, body, options) {
        return call(
          'http',
          'post',
          Object.assign(
            {
              url: url,
              body: body
            },
            options || {}
          )
        );
      },
      put: function (url, body, options) {
        return call(
          'http',
          'put',
          Object.assign(
            {
              url: url,
              body: body
            },
            options || {}
          )
        );
      },
      patch: function (url, body, options) {
        return call(
          'http',
          'patch',
          Object.assign(
            {
              url: url,
              body: body
            },
            options || {}
          )
        );
      },
      delete: function (url, options) {
        return call('http', 'delete', Object.assign({ url: url }, options || {}));
      },
      download: function (options) {
        return call('http', 'download', options || {});
      }
    },

    intent: {
      openUrl: function (url, mode) {
        return call('intent', 'openUrl', {
          url: url,
          mode: mode || 'external'
        });
      },
      canOpenUrl: function (url) {
        return call('intent', 'canOpenUrl', { url: url });
      },
      getInitialLink: function () {
        return call('intent', 'getInitialLink', {});
      },
      getLatestLink: function () {
        return call('intent', 'getLatestLink', {});
      },
      startListening: function () {
        return call('intent', 'startListening', {});
      },
      stopListening: function () {
        return call('intent', 'stopListening', {});
      }
    },

    clipboard: {
      readText: function () {
        return call('clipboard', 'readText', {});
      },
      writeText: function (text) {
        return call('clipboard', 'writeText', { text: text });
      },
      hasText: function () {
        return call('clipboard', 'hasText', {});
      },
      clear: function () {
        return call('clipboard', 'clear', {});
      }
    },

    share: {
      shareText: function (text, subject) {
        return call('share', 'shareText', {
          text: text,
          subject: subject || null
        });
      },
      shareFiles: function (paths, text, subject) {
        return call('share', 'shareFiles', {
          paths: paths,
          text: text || null,
          subject: subject || null
        });
      }
    },

    camera: {
      getInfo: function () {
        return call('camera', 'getInfo', {});
      },
      takePhoto: function (options) {
        return call('camera', 'takePhoto', options || {});
      },
      pickFromGallery: function (options) {
        return call('camera', 'pickFromGallery', options || {});
      }
    },

    geolocation: {
      checkPermission: function () {
        return call('geolocation', 'checkPermission', {});
      },
      requestPermission: function () {
        return call('geolocation', 'requestPermission', {});
      },
      getCurrentPosition: function (options) {
        return call('geolocation', 'getCurrentPosition', options || {});
      },
      watchPosition: function (options) {
        return call('geolocation', 'watchPosition', options || {});
      },
      clearWatch: function () {
        return call('geolocation', 'clearWatch', {});
      },
      isLocationEnabled: function () {
        return call('geolocation', 'isLocationEnabled', {});
      }
    }
  };

  global.NativeSDK = sdk;
})(window);
```

---

# 5) Type Definition برای Angular / React / TypeScript

---

## 📄 `assets/www/js/native-sdk.d.ts`

```ts
declare global {
  interface Window {
    NativeSDK: {
      waitForReady(timeoutMs?: number): Promise<any>;
      info(): {
        initialized: boolean;
        pendingRequests: number;
        totalRequests: number;
        version: string | null;
      };

      call(plugin: string, method: string, args?: any, extra?: any): Promise<any>;
      batch(requests: any[], options?: any): Promise<any[]>;
      on(event: string, callback: (data: any) => void): () => void;
      off(event: string, callback: (data: any) => void): void;

      permission: {
        check(permission: string): Promise<any>;
        request(permission: string): Promise<any>;
        checkMany(permissions: string[]): Promise<any>;
        requestMany(permissions: string[]): Promise<any>;
        openSettings(): Promise<any>;
        getKnownPermissions(): Promise<any>;
      };

      appLifecycle: {
        getState(): Promise<any>;
        enableEvents(): Promise<any>;
        disableEvents(): Promise<any>;
        getInfo(): Promise<any>;
      };

      deviceInfo: {
        getDeviceInfo(): Promise<any>;
        getAppInfo(): Promise<any>;
        getAll(): Promise<any>;
      };

      connectivity: {
        getStatus(): Promise<any>;
        isOnline(): Promise<any>;
        startWatch(): Promise<any>;
        stopWatch(): Promise<any>;
        getInfo(): Promise<any>;
      };

      storage: {
        get(key: string): Promise<any>;
        set(key: string, value: any): Promise<any>;
        remove(key: string): Promise<any>;
        clear(): Promise<any>;
        keys(): Promise<any>;
        has(key: string): Promise<any>;
      };

      fileSystem: {
        getDirectories(): Promise<any>;
        readFile(path: string, baseDir?: string, encoding?: string): Promise<any>;
        writeFile(path: string, content: string, options?: any): Promise<any>;
        deleteFile(path: string, baseDir?: string): Promise<any>;
        fileExists(path: string, baseDir?: string): Promise<any>;
        listFiles(path?: string, options?: any): Promise<any>;
        createDirectory(path: string, options?: any): Promise<any>;
        deleteDirectory(path: string, options?: any): Promise<any>;
        stat(path: string, options?: any): Promise<any>;
      };

      http: {
        request(options: any): Promise<any>;
        get(url: string, options?: any): Promise<any>;
        post(url: string, body?: any, options?: any): Promise<any>;
        put(url: string, body?: any, options?: any): Promise<any>;
        patch(url: string, body?: any, options?: any): Promise<any>;
        delete(url: string, options?: any): Promise<any>;
        download(options: any): Promise<any>;
      };

      intent: {
        openUrl(url: string, mode?: string): Promise<any>;
        canOpenUrl(url: string): Promise<any>;
        getInitialLink(): Promise<any>;
        getLatestLink(): Promise<any>;
        startListening(): Promise<any>;
        stopListening(): Promise<any>;
      };

      clipboard: {
        readText(): Promise<any>;
        writeText(text: string): Promise<any>;
        hasText(): Promise<any>;
        clear(): Promise<any>;
      };

      share: {
        shareText(text: string, subject?: string): Promise<any>;
        shareFiles(paths: string[], text?: string, subject?: string): Promise<any>;
      };

      camera: {
        getInfo(): Promise<any>;
        takePhoto(options?: any): Promise<any>;
        pickFromGallery(options?: any): Promise<any>;
      };

      geolocation: {
        checkPermission(): Promise<any>;
        requestPermission(): Promise<any>;
        getCurrentPosition(options?: any): Promise<any>;
        watchPosition(options?: any): Promise<any>;
        clearWatch(): Promise<any>;
        isLocationEnabled(): Promise<any>;
      };
    };
  }
}

export {};
```

---

# 6) فایل JS تست کامل برای همه پلاگین‌ها

---

## 📄 `assets/www/js/app.js`

```javascript
(function () {
  'use strict';

  var outputEl;
  var logEl;
  var requestCount = 0;
  var eventCount = 0;

  function $(id) {
    return document.getElementById(id);
  }

  function updateBridgeStats() {
    var info = window.NativeSDK ? window.NativeSDK.info() : null;
    $('bridgeState').textContent = info && info.initialized ? 'Ready' : 'Waiting...';
    $('requestCount').textContent = String(info ? info.totalRequests : requestCount);
    $('pendingCount').textContent = String(info ? info.pendingRequests : 0);
    $('eventCount').textContent = String(eventCount);
  }

  function log(message, type) {
    type = type || 'info';

    var item = document.createElement('div');
    item.className = 'log-item log-' + type;

    var now = new Date();
    var time = now.toLocaleTimeString('en-US', {
      hour12: false,
      hour: '2-digit',
      minute: '2-digit',
      second: '2-digit'
    });

    item.textContent = '[' + time + '] ' + message;
    logEl.prepend(item);

    while (logEl.children.length > 250) {
      logEl.removeChild(logEl.lastChild);
    }
  }

  function showOutput(data) {
    outputEl.textContent = JSON.stringify(data, null, 2);
  }

  async function run(label, fn) {
    requestCount += 1;
    updateBridgeStats();
    log('→ ' + label, 'info');

    try {
      var result = await fn();
      showOutput(result);
      log('✓ ' + label, 'success');
      updateBridgeStats();
      return result;
    } catch (err) {
      var msg = err && err.message ? err.message : JSON.stringify(err);
      showOutput({ error: msg, raw: err });
      log('✗ ' + label + ' — ' + msg, 'error');
      updateBridgeStats();
      throw err;
    }
  }

  function parseJsonMaybe(value) {
    if (!value || !value.trim()) return null;
    try {
      return JSON.parse(value);
    } catch (_) {
      return value;
    }
  }

  function bindEvents() {
    // Header
    $('btnBridgeInfo').addEventListener('click', function () {
      showOutput(window.NativeSDK.info());
      updateBridgeStats();
    });

    $('btnClearLog').addEventListener('click', function () {
      logEl.innerHTML = '';
      eventCount = 0;
      updateBridgeStats();
    });

    // Permission
    $('btnPermissionCheck').addEventListener('click', function () {
      run('permission.check', function () {
        return window.NativeSDK.permission.check($('permissionName').value.trim());
      });
    });

    $('btnPermissionRequest').addEventListener('click', function () {
      run('permission.request', function () {
        return window.NativeSDK.permission.request($('permissionName').value.trim());
      });
    });

    $('btnPermissionKnown').addEventListener('click', function () {
      run('permission.getKnownPermissions', function () {
        return window.NativeSDK.permission.getKnownPermissions();
      });
    });

    // App Lifecycle
    $('btnLifecycleState').addEventListener('click', function () {
      run('appLifecycle.getState', function () {
        return window.NativeSDK.appLifecycle.getState();
      });
    });

    $('btnLifecycleEnable').addEventListener('click', function () {
      run('appLifecycle.enableEvents', function () {
        return window.NativeSDK.appLifecycle.enableEvents();
      });
    });

    $('btnLifecycleDisable').addEventListener('click', function () {
      run('appLifecycle.disableEvents', function () {
        return window.NativeSDK.appLifecycle.disableEvents();
      });
    });

    $('btnLifecycleInfo').addEventListener('click', function () {
      run('appLifecycle.getInfo', function () {
        return window.NativeSDK.appLifecycle.getInfo();
      });
    });

    // Device Info
    $('btnDeviceInfo').addEventListener('click', function () {
      run('deviceInfo.getDeviceInfo', function () {
        return window.NativeSDK.deviceInfo.getDeviceInfo();
      });
    });

    $('btnAppInfo').addEventListener('click', function () {
      run('deviceInfo.getAppInfo', function () {
        return window.NativeSDK.deviceInfo.getAppInfo();
      });
    });

    $('btnDeviceAll').addEventListener('click', function () {
      run('deviceInfo.getAll', function () {
        return window.NativeSDK.deviceInfo.getAll();
      });
    });

    // Connectivity
    $('btnConnectivityStatus').addEventListener('click', function () {
      run('connectivity.getStatus', function () {
        return window.NativeSDK.connectivity.getStatus();
      });
    });

    $('btnConnectivityStart').addEventListener('click', function () {
      run('connectivity.startWatch', function () {
        return window.NativeSDK.connectivity.startWatch();
      });
    });

    $('btnConnectivityStop').addEventListener('click', function () {
      run('connectivity.stopWatch', function () {
        return window.NativeSDK.connectivity.stopWatch();
      });
    });

    $('btnConnectivityIsOnline').addEventListener('click', function () {
      run('connectivity.isOnline', function () {
        return window.NativeSDK.connectivity.isOnline();
      });
    });

    // Storage
    $('btnStorageSet').addEventListener('click', function () {
      run('storage.set', function () {
        var key = $('storageKey').value.trim();
        var value = parseJsonMaybe($('storageValue').value);
        return window.NativeSDK.storage.set(key, value);
      });
    });

    $('btnStorageGet').addEventListener('click', function () {
      run('storage.get', function () {
        return window.NativeSDK.storage.get($('storageKey').value.trim());
      });
    });

    $('btnStorageHas').addEventListener('click', function () {
      run('storage.has', function () {
        return window.NativeSDK.storage.has($('storageKey').value.trim());
      });
    });

    $('btnStorageKeys').addEventListener('click', function () {
      run('storage.keys', function () {
        return window.NativeSDK.storage.keys();
      });
    });

    $('btnStorageRemove').addEventListener('click', function () {
      run('storage.remove', function () {
        return window.NativeSDK.storage.remove($('storageKey').value.trim());
      });
    });

    $('btnStorageClear').addEventListener('click', function () {
      run('storage.clear', function () {
        return window.NativeSDK.storage.clear();
      });
    });

    // File System
    $('btnFsDirs').addEventListener('click', function () {
      run('fileSystem.getDirectories', function () {
        return window.NativeSDK.fileSystem.getDirectories();
      });
    });

    $('btnFsWrite').addEventListener('click', function () {
      run('fileSystem.writeFile', function () {
        return window.NativeSDK.fileSystem.writeFile(
          $('filePath').value.trim(),
          $('fileContent').value
        );
      });
    });

    $('btnFsRead').addEventListener('click', function () {
      run('fileSystem.readFile', function () {
        return window.NativeSDK.fileSystem.readFile($('filePath').value.trim());
      });
    });

    $('btnFsExists').addEventListener('click', function () {
      run('fileSystem.fileExists', function () {
        return window.NativeSDK.fileSystem.fileExists($('filePath').value.trim());
      });
    });

    $('btnFsList').addEventListener('click', function () {
      run('fileSystem.listFiles', function () {
        return window.NativeSDK.fileSystem.listFiles('demo', { recursive: true });
      });
    });

    $('btnFsStat').addEventListener('click', function () {
      run('fileSystem.stat', function () {
        return window.NativeSDK.fileSystem.stat($('filePath').value.trim(), { type: 'file' });
      });
    });

    $('btnFsDelete').addEventListener('click', function () {
      run('fileSystem.deleteFile', function () {
        return window.NativeSDK.fileSystem.deleteFile($('filePath').value.trim());
      });
    });

    // HTTP
    $('btnHttpGet').addEventListener('click', function () {
      run('http.get', function () {
        return window.NativeSDK.http.get($('httpUrl').value.trim(), {
          responseType: 'json'
        });
      });
    });

    $('btnHttpPost').addEventListener('click', function () {
      run('http.post', function () {
        return window.NativeSDK.http.post(
          'https://jsonplaceholder.typicode.com/posts',
          {
            title: 'sweetmelon',
            body: 'native post body',
            userId: 1
          },
          {
            bodyType: 'json',
            responseType: 'json',
            headers: {
              'content-type': 'application/json'
            }
          }
        );
      });
    });

    $('btnHttpDownload').addEventListener('click', function () {
      run('http.download', function () {
        return window.NativeSDK.http.download({
          url: 'https://jsonplaceholder.typicode.com/todos/1',
          fileName: 'todo-1.json',
          baseDir: 'temporary'
        });
      });
    });

    // Intent
    $('btnIntentCanOpen').addEventListener('click', function () {
      run('intent.canOpenUrl', function () {
        return window.NativeSDK.intent.canOpenUrl($('intentUrl').value.trim());
      });
    });

    $('btnIntentOpen').addEventListener('click', function () {
      run('intent.openUrl', function () {
        return window.NativeSDK.intent.openUrl($('intentUrl').value.trim(), 'external');
      });
    });

    $('btnIntentInitial').addEventListener('click', function () {
      run('intent.getInitialLink', function () {
        return window.NativeSDK.intent.getInitialLink();
      });
    });

    $('btnIntentLatest').addEventListener('click', function () {
      run('intent.getLatestLink', function () {
        return window.NativeSDK.intent.getLatestLink();
      });
    });

    $('btnIntentListenStart').addEventListener('click', function () {
      run('intent.startListening', function () {
        return window.NativeSDK.intent.startListening();
      });
    });

    $('btnIntentListenStop').addEventListener('click', function () {
      run('intent.stopListening', function () {
        return window.NativeSDK.intent.stopListening();
      });
    });

    // Clipboard
    $('btnClipboardWrite').addEventListener('click', function () {
      run('clipboard.writeText', function () {
        return window.NativeSDK.clipboard.writeText($('clipboardText').value);
      });
    });

    $('btnClipboardRead').addEventListener('click', function () {
      run('clipboard.readText', function () {
        return window.NativeSDK.clipboard.readText();
      });
    });

    $('btnClipboardHas').addEventListener('click', function () {
      run('clipboard.hasText', function () {
        return window.NativeSDK.clipboard.hasText();
      });
    });

    $('btnClipboardClear').addEventListener('click', function () {
      run('clipboard.clear', function () {
        return window.NativeSDK.clipboard.clear();
      });
    });

    // Share
    $('btnShareText').addEventListener('click', function () {
      run('share.shareText', function () {
        return window.NativeSDK.share.shareText($('shareText').value, 'Sweetmelon');
      });
    });

    $('btnShareFile').addEventListener('click', async function () {
      await run('fileSystem.writeFile (prepare share file)', function () {
        return window.NativeSDK.fileSystem.writeFile(
          'share/demo-share.txt',
          'Shared from Sweetmelon WebView at ' + new Date().toISOString()
        );
      });

      await run('fileSystem.getDirectories', function () {
        return window.NativeSDK.fileSystem.getDirectories();
      }).then(function (dirs) {
        var fullPath = (dirs.documents || '') + '/share/demo-share.txt';

        return run('share.shareFiles', function () {
          return window.NativeSDK.share.shareFiles(
            [fullPath],
            'Sharing created file from Native Bridge',
            'Sweetmelon File Share'
          );
        });
      });
    });

    // Camera
    $('btnCameraInfo').addEventListener('click', function () {
      run('camera.getInfo', function () {
        return window.NativeSDK.camera.getInfo();
      });
    });

    $('btnTakePhoto').addEventListener('click', function () {
      run('camera.takePhoto', function () {
        return window.NativeSDK.camera.takePhoto({
          quality: 80
        });
      });
    });

    $('btnPickGallery').addEventListener('click', function () {
      run('camera.pickFromGallery', function () {
        return window.NativeSDK.camera.pickFromGallery({
          multiple: false
        });
      });
    });

    // Geolocation
    $('btnGeoPermission').addEventListener('click', function () {
      run('geolocation.checkPermission', function () {
        return window.NativeSDK.geolocation.checkPermission();
      });
    });

    $('btnGeoRequestPermission').addEventListener('click', function () {
      run('geolocation.requestPermission', function () {
        return window.NativeSDK.geolocation.requestPermission();
      });
    });

    $('btnGeoCurrent').addEventListener('click', function () {
      run('geolocation.getCurrentPosition', function () {
        return window.NativeSDK.geolocation.getCurrentPosition({
          accuracy: 'high'
        });
      });
    });

    $('btnGeoStart').addEventListener('click', function () {
      run('geolocation.watchPosition', function () {
        return window.NativeSDK.geolocation.watchPosition({
          accuracy: 'high',
          distanceFilter: 10
        });
      });
    });

    $('btnGeoStop').addEventListener('click', function () {
      run('geolocation.clearWatch', function () {
        return window.NativeSDK.geolocation.clearWatch();
      });
    });

    $('btnGeoEnabled').addEventListener('click', function () {
      run('geolocation.isLocationEnabled', function () {
        return window.NativeSDK.geolocation.isLocationEnabled();
      });
    });
  }

  function bindNativeEvents() {
    var unsubscribers = [];

    unsubscribers.push(
      window.NativeSDK.on('app.lifecycle.change', function (data) {
        eventCount += 1;
        log('EVENT app.lifecycle.change → ' + JSON.stringify(data), 'event');
        updateBridgeStats();
      })
    );

    unsubscribers.push(
      window.NativeSDK.on('connectivity.change', function (data) {
        eventCount += 1;
        log('EVENT connectivity.change → ' + JSON.stringify(data), 'event');
        updateBridgeStats();
      })
    );

    unsubscribers.push(
      window.NativeSDK.on('connectivity.error', function (data) {
        eventCount += 1;
        log('EVENT connectivity.error → ' + JSON.stringify(data), 'error');
        updateBridgeStats();
      })
    );

    unsubscribers.push(
      window.NativeSDK.on('intent.deepLink', function (data) {
        eventCount += 1;
        log('EVENT intent.deepLink → ' + JSON.stringify(data), 'event');
        updateBridgeStats();
      })
    );

    unsubscribers.push(
      window.NativeSDK.on('intent.error', function (data) {
        eventCount += 1;
        log('EVENT intent.error → ' + JSON.stringify(data), 'error');
        updateBridgeStats();
      })
    );

    unsubscribers.push(
      window.NativeSDK.on('geolocation.position', function (data) {
        eventCount += 1;
        log(
          'EVENT geolocation.position → ' +
            data.latitude +
            ', ' +
            data.longitude,
          'event'
        );
        updateBridgeStats();
      })
    );

    unsubscribers.push(
      window.NativeSDK.on('geolocation.error', function (data) {
        eventCount += 1;
        log('EVENT geolocation.error → ' + JSON.stringify(data), 'error');
        updateBridgeStats();
      })
    );

    window.__nativeSdkUnsubscribers = unsubscribers;
  }

  async function init() {
    outputEl = $('output');
    logEl = $('log');

    updateBridgeStats();
    log('Initializing NativeSDK...', 'info');

    try {
      await window.NativeSDK.waitForReady(10000);
      log('NativeSDK is ready', 'success');
      updateBridgeStats();

      bindEvents();
      bindNativeEvents();

      try {
        await window.NativeSDK.connectivity.startWatch();
      } catch (_) {}

      try {
        await window.NativeSDK.intent.startListening();
      } catch (_) {}
    } catch (err) {
      log('Bridge init failed: ' + err.message, 'error');
      showOutput({ error: err.message });
    }
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
  } else {
    init();
  }
})();
```

---

# 7) اگر بخواهی این wrapper را در Angular / React استفاده کنی

## روش پیشنهادی
این فایل‌ها را می‌توانی:
- یا مستقیم در پروژه HTML داخل `assets/www/js/` نگه داری
- یا در Angular/React داخل `public/` / `assets/` کپی کنی

### فایل مهم:
- `native-sdk.js`
- `native-sdk.d.ts`

### نمونه مصرف در Angular/React:
بعد از اینکه WebView صفحه را لود کرد، در کد فرانت:
```js
await window.NativeSDK.waitForReady();
const info = await window.NativeSDK.deviceInfo.getAll();
```

---

# 8) نکات مهم اجرایی

### Deep Link تست
برای تست custom scheme:
- `sweetmelon://home`
- `sweetmelon://product/123`

### تست Intent باز کردن:
- `https://flutter.dev`
- `tel:02112345678`
- `mailto:test@example.com`
- `geo:35.6892,51.3890`

### HTTP بدون HTTPS
الان با این تنظیم:
- `android:usesCleartextTraffic="true"`
- `network_security_config`
امکان لود و درخواست به آدرس‌های `http://...` در محیط dev وجود دارد.

---

# 9) نتیجه این مرحله

بعد از این مرحله، شما دارید:

- هسته bridge
- اجرای پروژه HTML از مسیر ثابت `assets/www/index.html`
- پلاگین‌های پایه:
  - Permission
  - App Lifecycle
  - Device Info
  - Connectivity
  - Storage
  - File System
  - HTTP Native
  - Intent / Deep Link
  - Clipboard
  - Share
- تست کامل UI برای این پلاگین‌ها
- تست Camera و Geolocation
- wrapper استاندارد `NativeSDK` برای Angular/React/TS

---

اگر بخواهی، در پیام بعدی من **مرحله سوم** را هم کامل می‌فرستم:

### مرحله سوم پیشنهادی
1. **افزودن Back Button / System Navigation Plugin**
2. **افزودن Secure Storage Plugin**
3. **افزودن Notification / Push پایه**
4. **نوشتن Angular integration guide**
5. **نوشتن JS event bus استاندارد برای plugin events**
6. **افزودن تست batch برای همه pluginها**
7. **ساخت صفحه devtools داخل خود HTML برای بررسی bridge traffic**

اگر موافقی، من مستقیم **فاز ۳** را هم با کد کامل شروع می‌کنم.
