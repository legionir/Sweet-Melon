# Sweet-Melon


# ⚡ Flutter Native Bridge

### پلتفرم ارتباط دوطرفه بین JavaScript و Flutter

[![Flutter](https://img.shields.io/badge/Flutter-3.10%2B-02569B?style=for-the-badge&logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.0%2B-0175C2?style=for-the-badge&logo=dart)](https://dart.dev)
[![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS-lightgrey?style=for-the-badge)](https://flutter.dev)

```
[ JS App Runtime (HTML/JS) ]
          ↓
[ JS SDK (Native Bridge API) ]
          ↓
[ Message Bus / RPC Layer ]
          ↓
[ Flutter Core Runtime ]
          ↓
[ Plugin Engine (Registry + Lifecycle) ]
          ↓
[ Native Adapters (Android/iOS) ]
```

**ارتباط امن، سریع و قابل توسعه بین دنیای JavaScript و قابلیت‌های Native**

[شروع سریع](#-شروع-سریع) •
[مستندات](#-معماری-سیستم) •
[پلاگین‌ها](#-پلاگین‌های-داخلی) •
[CLI](#-cli-tool) •
[مشارکت](#-مشارکت-در-پروژه)


---

## 📋 فهرست مطالب

- [معرفی](#-معرفی)
- [ویژگی‌های کلیدی](#-ویژگی‌های-کلیدی)
- [معماری سیستم](#-معماری-سیستم)
- [اصول طراحی](#-اصول-طراحی)
- [شروع سریع](#-شروع-سریع)
- [نصب و راه‌اندازی](#-نصب-و-راه‌اندازی)
- [JS SDK](#-js-sdk)
- [Plugin Engine](#-plugin-engine)
- [پلاگین‌های داخلی](#-پلاگین‌های-داخلی)
- [Security Layer](#-security-layer)
- [Performance Layer](#-performance-layer)
- [Bridge Inspector](#-bridge-inspector)
- [CLI Tool](#-cli-tool)
- [ساخت پلاگین سفارشی](#-ساخت-پلاگین-سفارشی)
- [Protocol Specification](#-protocol-specification)
- [پیکربندی پیشرفته](#-پیکربندی-پیشرفته)
- [تست‌نویسی](#-تست‌نویسی)
- [عیب‌یابی](#-عیب‌یابی)
- [مشارکت در پروژه](#-مشارکت-در-پروژه)

---

## 🎯 معرفی

Flutter Native Bridge یک پلتفرم enterprise-grade است که امکان ارتباط کامل و امن بین
یک برنامه JavaScript (HTML/JS) و قابلیت‌های native دستگاه (دوربین، GPS، ذخیره‌سازی و...)
را از طریق یک لایه میانی Flutter فراهم می‌کند.

### چرا Flutter Native Bridge؟

| مشکل | راه‌حل ما |
|------|-----------|
| دسترسی JS به Native API ناامن است | لایه امنیتی با Permission Model |
| ارتباط WebView کند و blocking است | RPC async با message-id |
| مدیریت پلاگین‌ها پیچیده است | Plugin Engine با lifecycle کامل |
| دیباگ bridge دشوار است | Bridge Inspector UI داخلی |
| ساخت پلاگین نیاز به boilerplate دارد | CLI برای scaffold خودکار |

---

## ✨ ویژگی‌های کلیدی

### 🔌 Plugin System
- **Hot-pluggable**: ثبت پلاگین در runtime بدون restart
- **Version Isolation**: چندین نسخه از یک پلاگین به صورت همزمان
- **Lifecycle Management**: initialize → call → pause → resume → dispose
- **Method Dispatch**: مسیریابی خودکار بر اساس نام متد

### 🌉 Bridge Communication
- **Async RPC**: تمام فراخوانی‌ها Promise-based
- **Request ID Tracking**: هر پیام یک UUID یکتا دارد
- **Batch Requests**: ارسال چند درخواست در یک round-trip
- **Event System**: ارسال رویداد از Flutter به JS

### 🔒 Security
- **Permission Model**: کنترل دسترسی per-plugin
- **Rate Limiting**: جلوگیری از abuse با window-based limiting
- **Execution Guard**: timeout و ایزولاسیون اجرا
- **Args Validation**: اعتبارسنجی ورودی‌ها قبل از اجرا

### ⚡ Performance
- **LRU Cache**: کش نتایج با TTL قابل تنظیم
- **Parallel Batch**: اجرای موازی درخواست‌های دسته‌ای
- **Lazy Plugin Loading**: بارگذاری پلاگین فقط در صورت نیاز
- **Message Compression**: کاهش حجم داده‌های انتقالی

### 🛠 Developer Experience
- **CLI Tool**: ساخت پلاگین با یک دستور
- **Bridge Inspector**: UI دیباگ داخلی
- **Structured Logging**: لاگ‌های ساختارمند با level و tag
- **Full TypeScript Support**: تایپ‌های JS کامل

---

## 🏗 معماری سیستم

```
┌─────────────────────────────────────────────────────────────────┐
│                        JS Application                            │
│                                                                   │
│   const result = await Native.call({                             │
│     plugin: 'camera',                                            │
│     method: 'takePhoto',                                         │
│     args: { quality: 80 }                                        │
│   });                                                            │
└──────────────────────────┬──────────────────────────────────────┘
                           │ JavaScriptChannel (WebView)
                           │ JSON over postMessage
┌──────────────────────────▼──────────────────────────────────────┐
│                    Message Bridge (Dart)                          │
│                                                                   │
│   • Parse JSON → PluginRequest                                   │
│   • Route to Plugin Manager                                      │
│   • Serialize response → JSON                                    │
│   • Call window.__resolveCall()                                  │
└──────────────────────────┬──────────────────────────────────────┘
                           │
┌──────────────────────────▼──────────────────────────────────────┐
│                    Plugin Manager                                 │
│                                                                   │
│   RateLimit Check                                                │
│        ↓                                                         │
│   Plugin Resolution (Registry)                                   │
│        ↓                                                         │
│   Method Validation                                              │
│        ↓                                                         │
│   Permission Check                                               │
│        ↓                                                         │
│   Args Validation                                                │
│        ↓                                                         │
│   Cache Lookup                                                   │
│        ↓                                                         │
│   Execute with Guard (timeout)                                   │
│        ↓                                                         │
│   Cache Result + Record Stats                                    │
└──────────────────────────┬──────────────────────────────────────┘
                           │
              ┌────────────┼────────────┬────────────┐
              ▼            ▼            ▼            ▼
       ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐
       │  Camera  │ │ Storage  │ │   Geo    │ │ Custom   │
       │  Plugin  │ │  Plugin  │ │  Plugin  │ │ Plugin   │
       └────┬─────┘ └────┬─────┘ └────┬─────┘ └────┬─────┘
            │            │            │            │
       Native APIs   SharedPrefs  Geolocator   Your API
```

### جریان کامل یک درخواست

```
JS App                    Bridge                   Plugin
  │                          │                        │
  │─── Native.call() ───────>│                        │
  │    { plugin, method,     │                        │
  │      args, requestId }   │                        │
  │                          │── rate limit check     │
  │                          │── resolve plugin ─────>│
  │                          │── permission check     │
  │                          │── validate args        │
  │                          │── cache lookup         │
  │                          │── execute() ──────────>│
  │                          │                        │── native call
  │                          │                        │<── result
  │                          │<── response ───────────│
  │<── __resolveCall() ──────│                        │
  │    { success, data }     │                        │
```

---

## 📐 اصول طراحی

### 1. RPC-Based Communication
تمام ارتباط‌ها async و دارای شناسه یکتا هستند:
```
Request  → { requestId: "uuid", plugin, method, args }
Response → { requestId: "uuid", success, data | error }
```

### 2. Plugin Isolation
هر پلاگین کاملاً مستقل است:
- نسخه‌بندی مستقل (SemVer)
- lifecycle جداگانه
- محدوده اجرای مجزا

### 3. No Direct Native Exposure
JS هیچ‌گاه مستقیماً با Native در ارتباط نیست:
```
JS → Standard API → Bridge → Plugin → Native
     (نه بیشتر)
```

### 4. Flutter فقط Runtime Host
Flutter منطق تجاری ندارد، فقط:
- WebView host
- Message routing
- Plugin orchestration

---

## 🚀 شروع سریع

### ۱. نصب Dependencies

```yaml
# pubspec.yaml
dependencies:
  flutter:
    sdk: flutter
  webview_flutter: ^4.4.0
  shared_preferences: ^2.2.2
  path_provider: ^2.1.1
  image_picker: ^1.0.4
  geolocator: ^10.1.0
  uuid: ^4.2.1
  get_it: ^7.6.4
  http: ^1.1.2
```

```bash
flutter pub get
```

### ۲. راه‌اندازی در main.dart

```dart
import 'package:flutter/material.dart';
import 'di/service_locator.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // راه‌اندازی تمام سرویس‌ها
  await ServiceLocator.init();

  runApp(const BridgeApp());
}
```

### ۳. اولین فراخوانی در JS

```html
<!DOCTYPE html>
<html>
<body>
<script>
  // Native SDK به صورت خودکار inject می‌شود

  async function takePhoto() {
    try {
      const photo = await Native.call({
        plugin: 'camera',
        method: 'takePhoto',
        args: { quality: 80 }
      });

      console.log('Photo path:', photo.path);
    } catch (error) {
      console.error('Error:', error.message);
    }
  }

  takePhoto();
</script>
</body>
</html>
```

---

## 📦 نصب و راه‌اندازی

### Android Setup

```xml
<!-- android/app/src/main/AndroidManifest.xml -->
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.INTERNET" />

<application
    android:usesCleartextTraffic="true">
  <!-- برای development -->
</application>
```

```kotlin
// android/app/build.gradle
android {
    compileSdkVersion 34
    defaultConfig {
        minSdkVersion 21
    }
}
```

### iOS Setup

```xml
<!-- ios/Runner/Info.plist -->
<key>NSCameraUsageDescription</key>
<string>نیاز به دسترسی دوربین برای عکاسی</string>

<key>NSPhotoLibraryUsageDescription</key>
<string>نیاز به دسترسی گالری برای انتخاب تصویر</string>

<key>NSLocationWhenInUseUsageDescription</key>
<string>نیاز به موقعیت مکانی برای ارائه خدمات</string>

<key>NSLocationAlwaysUsageDescription</key>
<string>نیاز به موقعیت مکانی در پس‌زمینه</string>
```

### Service Locator Configuration

```dart
// lib/di/service_locator.dart

class ServiceLocator {
  static Future<void> init() async {

    // ── Cache ──────────────────────────────────────────────
    sl.registerLazySingleton<CacheManager>(
      () => CacheManager(maxEntries: 500),
    );

    // ── Rate Limiter ───────────────────────────────────────
    sl.registerLazySingleton<RateLimiter>(() {
      final limiter = RateLimiter();

      // قانون پیش‌فرض: ۵۰ درخواست در ثانیه
      limiter.setDefaultRule(RateLimitRule.perSecond(50));

      // قانون سفارشی برای camera
      limiter.addRule('camera', RateLimitRule.perMinute(20));

      return limiter;
    });

    // ── Execution Guard ────────────────────────────────────
    sl.registerLazySingleton<ExecutionGuard>(
      () => ExecutionGuard(defaultTimeoutMs: 30000),
    );

    // ── Permission Manager ─────────────────────────────────
    sl.registerLazySingleton<PermissionManager>(() {
      final manager = PermissionManager();
      manager.setProvider(MyPermissionProvider());
      return manager;
    });

    // ── Plugin Registry ────────────────────────────────────
    sl.registerLazySingleton<PluginRegistry>(
      () => PluginRegistry(),
    );

    // ── Plugin Manager ─────────────────────────────────────
    sl.registerLazySingleton<PluginManager>(
      () => PluginManager(
        registry: sl<PluginRegistry>(),
        permissionManager: sl<PermissionManager>(),
        rateLimiter: sl<RateLimiter>(),
        executionGuard: sl<ExecutionGuard>(),
        cacheManager: sl<CacheManager>(),
      ),
    );

    // ── Message Bridge ─────────────────────────────────────
    sl.registerLazySingleton<MessageBridge>(() {
      final bridge = MessageBridge();
      final manager = sl<PluginManager>();

      bridge.setMessageHandler(manager.execute);
      bridge.setBatchHandler(manager.executeBatch);

      return bridge;
    });

    // ── ثبت پلاگین‌ها ──────────────────────────────────────
    final registry = sl<PluginRegistry>();
    await registry.register(CameraPlugin());
    await registry.register(StoragePlugin());
    await registry.register(GeolocationPlugin());
  }
}
```

---

## 🌐 JS SDK

### نصب SDK

SDK به صورت خودکار توسط Flutter inject می‌شود.
برای استفاده در پروژه‌های خارجی:

```html
<!-- روش 1: Auto-inject (پیش‌فرض) -->
<!-- هیچ کاری نیاز نیست، Bridge خودکار SDK را inject می‌کند -->

<!-- روش 2: دستی (برای تست) -->
<script src="native-bridge-sdk.js"></script>
```

---

### `Native.call()` — فراخوانی پلاگین

ساده‌ترین و اصلی‌ترین متد برای فراخوانی پلاگین.

```javascript
const result = await Native.call({
  plugin: string,     // نام پلاگین (اجباری)
  method: string,     // نام متد (اجباری)
  args: object,       // آرگومان‌ها (اختیاری، پیش‌فرض: {})
  version: string,    // نسخه پلاگین (اختیاری، پیش‌فرض: 'latest')
  timeout: number     // timeout به ms (اختیاری، پیش‌فرض: 30000)
});
```

**مثال‌ها:**

```javascript
// ── ساده‌ترین فراخوانی ──────────────────────────────────────
const keys = await Native.call({
  plugin: 'storage',
  method: 'keys'
});

// ── با آرگومان ──────────────────────────────────────────────
const photo = await Native.call({
  plugin: 'camera',
  method: 'takePhoto',
  args: {
    quality: 85,
    maxWidth: 1920,
    maxHeight: 1080
  }
});

// ── با نسخه خاص ────────────────────────────────────────────
const result = await Native.call({
  plugin: 'myPlugin',
  method: 'getData',
  version: '2.0.0'
});

// ── با timeout سفارشی ───────────────────────────────────────
const location = await Native.call({
  plugin: 'geolocation',
  method: 'getCurrentPosition',
  args: { accuracy: 'high' },
  timeout: 10000   // 10 ثانیه
});

// ── مدیریت خطا ─────────────────────────────────────────────
try {
  const data = await Native.call({
    plugin: 'camera',
    method: 'takePhoto'
  });
  console.log('Success:', data);
} catch (error) {
  // error = { code, message, requestId }
  switch (error.code) {
    case 'PERMISSION_DENIED':
      showPermissionDialog();
      break;
    case 'TIMEOUT':
      showTimeoutMessage();
      break;
    case 'PLUGIN_NOT_FOUND':
      console.error('Plugin not available');
      break;
    default:
      console.error('Unknown error:', error.message);
  }
}
```

---

### `Native.batch()` — درخواست دسته‌ای

ارسال چند درخواست در یک round-trip برای بهینه‌سازی عملکرد.

```javascript
const results = await Native.batch(
  requests: Array,  // آرایه درخواست‌ها
  options: {
    parallel: boolean,    // اجرای موازی (پیش‌فرض: true)
    stopOnError: boolean, // توقف در صورت خطا (پیش‌فرض: false)
    timeout: number       // timeout کل (اختیاری)
  }
);
// returns: Array<{ success, data | error, requestId }>
```

**مثال‌ها:**

```javascript
// ── اجرای موازی (سریع‌ترین) ────────────────────────────────
const [storageResult, locationResult, cameraInfo] = await Native.batch([
  { plugin: 'storage',     method: 'keys',              args: {} },
  { plugin: 'geolocation', method: 'checkPermission',   args: {} },
  { plugin: 'camera',      method: 'getInfo',           args: {} }
], { parallel: true });

console.log('Storage keys:',    storageResult.data);
console.log('Location perm:',   locationResult.data);
console.log('Camera info:',     cameraInfo.data);

// ── اجرای سریالی ───────────────────────────────────────────
const results = await Native.batch([
  { plugin: 'storage', method: 'set', args: { key: 'step1', value: 'done' } },
  { plugin: 'storage', method: 'set', args: { key: 'step2', value: 'done' } },
  { plugin: 'storage', method: 'set', args: { key: 'step3', value: 'done' } }
], {
  parallel: false,
  stopOnError: true  // اگر یکی خطا داد، بقیه اجرا نشوند
});

// ── بررسی نتایج ────────────────────────────────────────────
results.forEach((result, index) => {
  if (result.success) {
    console.log(`Request ${index}: ✓`, result.data);
  } else {
    console.error(`Request ${index}: ✗`, result.error);
  }
});
```

---

### `Native.on()` — دریافت رویداد از Flutter

```javascript
// ثبت listener
const unsubscribe = Native.on('eventName', (data) => {
  console.log('Event received:', data);
});

// لغو listener
unsubscribe();

// یا مستقیم:
Native.off('eventName', callbackFunction);
```

**مثال‌های کاربردی:**

```javascript
// ── دریافت رویداد موقعیت مکانی ─────────────────────────────
Native.on('location_update', (position) => {
  updateMapMarker(position.latitude, position.longitude);
});

// ── دریافت رویداد شبکه ──────────────────────────────────────
Native.on('network_change', (status) => {
  if (!status.connected) {
    showOfflineBanner();
  }
});

// ── دریافت نوتیفیکیشن ───────────────────────────────────────
Native.on('push_notification', (notification) => {
  showToast(notification.title, notification.body);
});

// ── رویداد lifecycle ────────────────────────────────────────
Native.on('app_foreground', () => refreshData());
Native.on('app_background', () => saveState());
```

---

### `Native.info()` — اطلاعات Bridge

```javascript
const info = Native.info();
// returns:
// {
//   initialized: true,
//   pendingRequests: 2,
//   totalRequests: 145,
//   version: '1.0.0'
// }
```

---

### Debug Utilities

```javascript
// ── وضعیت درخواست‌های در انتظار ────────────────────────────
const pendingIds = window.__bridgeDebug.getPending();
console.log('Pending:', pendingIds);

// ── آمار کامل ───────────────────────────────────────────────
const stats = window.__bridgeDebug.getStats();
// {
//   pending: 2,
//   total: 145,
//   listeners: ['location_update', 'network_change']
// }

// ── پاکسازی درخواست‌های گیر کرده ────────────────────────────
window.__bridgeDebug.clearPending();
```

---

## ⚙️ Plugin Engine

### Plugin Interface

هر پلاگین باید این interface را پیاده‌سازی کند:

```dart
abstract class Plugin {
  // ── شناسه ──────────────────────────────────────────────────
  String get name;          // نام یکتا: 'camera'
  String get version;       // SemVer: '1.0.0'
  String get description;   // توضیح

  // ── قابلیت‌ها ───────────────────────────────────────────────
  List<String> get supportedMethods;    // متدهای پشتیبانی‌شده
  List<String> get requiredPermissions; // مجوزهای لازم

  // ── اجرا ───────────────────────────────────────────────────
  Future<dynamic> onCall(String method, Map<String, dynamic> args);

  // ── lifecycle ──────────────────────────────────────────────
  Future<void> onInitialize();  // هنگام ثبت
  Future<void> onDispose();     // هنگام حذف
  Future<void> onPause();       // هنگام pause اپ
  Future<void> onResume();      // هنگام resume اپ

  // ── اعتبارسنجی ─────────────────────────────────────────────
  Future<ValidationResult> validateArgs(String method, Map args);
}
```

### Plugin Registry

```dart
final registry = PluginRegistry();

// ── ثبت پلاگین ─────────────────────────────────────────────
await registry.register(MyPlugin());

// ── ثبت نسخه جدید (hot-replace) ────────────────────────────
await registry.register(MyPlugin_v2());

// ── حذف پلاگین ─────────────────────────────────────────────
await registry.unregister('myPlugin');
await registry.unregister('myPlugin', version: '1.0.0');

// ── جستجو ───────────────────────────────────────────────────
final plugin = registry.resolve('myPlugin');
final pluginV1 = registry.resolve('myPlugin', version: '1.0.0');

// ── بررسی وجود ──────────────────────────────────────────────
final exists = registry.isRegistered('myPlugin');

// ── لیست همه پلاگین‌ها ──────────────────────────────────────
final plugins = registry.registeredPlugins; // List<String>
final infos = registry.getPluginInfos();    // List<PluginInfo>

// ── گوش دادن به رویدادهای ثبت ───────────────────────────────
registry.events.listen((event) {
  print('${event.type}: ${event.pluginName}@${event.version}');
});
```

### Plugin Manager

```dart
final manager = PluginManager(
  registry: registry,
  permissionManager: permissionManager,
  rateLimiter: rateLimiter,
  executionGuard: executionGuard,
  cacheManager: cacheManager,
);

// ── اجرای یک درخواست ───────────────────────────────────────
final response = await manager.execute(request);

// ── اجرای دسته‌ای ───────────────────────────────────────────
final responses = await manager.executeBatch(
  requests,
  BatchOptions(parallel: true, stopOnError: false),
);

// ── آمار عملکرد ─────────────────────────────────────────────
final stats = manager.stats;
// Map<String, PluginStats>
// {
//   'camera.takePhoto': PluginStats {
//     totalCalls: 45,
//     avgTimeMs: 1250.5,
//     cacheHitRate: 0.0,
//     errorCount: 2
//   }
// }

// ── دریافت trace ها ─────────────────────────────────────────
manager.traces.listen((trace) {
  print('${trace.plugin}.${trace.method}: ${trace.processingTimeMs}ms');
});
```

---

## 📱 پلاگین‌های داخلی

### 📸 Camera Plugin

**نام:** `camera` | **نسخه:** `1.0.0`

#### `takePhoto` — عکاسی با دوربین

```javascript
const photo = await Native.call({
  plugin: 'camera',
  method: 'takePhoto',
  args: {
    quality: 80,        // 0-100 (پیش‌فرض: 80)
    maxWidth: 1920,     // حداکثر عرض (اختیاری)
    maxHeight: 1080     // حداکثر ارتفاع (اختیاری)
  }
});

// Response:
// {
//   path: '/data/user/0/.../image.jpg',
//   name: 'image_20240101.jpg',
//   size: 245120,
//   mimeType: 'image/jpeg',
//   width: 1920,
//   height: 1080
// }
```

#### `pickFromGallery` — انتخاب از گالری

```javascript
// انتخاب تک تصویر
const image = await Native.call({
  plugin: 'camera',
  method: 'pickFromGallery',
  args: { multiple: false }
});

// انتخاب چند تصویر
const result = await Native.call({
  plugin: 'camera',
  method: 'pickFromGallery',
  args: { multiple: true }
});

// Response (multiple: true):
// {
//   images: [
//     { path, name, size },
//     { path, name, size }
//   ]
// }
```

#### `recordVideo` — ضبط ویدیو

```javascript
const video = await Native.call({
  plugin: 'camera',
  method: 'recordVideo',
  args: {
    maxDurationSeconds: 60  // حداکثر مدت (اختیاری)
  }
});

// Response:
// {
//   path: '/data/.../video.mp4',
//   name: 'video.mp4',
//   size: 15728640,
//   mimeType: 'video/mp4'
// }
```

#### `getInfo` — اطلاعات پلاگین

```javascript
const info = await Native.call({
  plugin: 'camera',
  method: 'getInfo'
});

// Response:
// {
//   name: 'camera',
//   version: '1.0.0',
//   supportedMethods: ['takePhoto', 'pickFromGallery', 'recordVideo'],
//   platform: 'android'
// }
```

---

### 💾 Storage Plugin

**نام:** `storage` | **نسخه:** `1.0.0`

#### `set` — ذخیره مقدار

```javascript
// ذخیره string
await Native.call({
  plugin: 'storage',
  method: 'set',
  args: { key: 'username', value: 'Ali' }
});

// ذخیره object
await Native.call({
  plugin: 'storage',
  method: 'set',
  args: {
    key: 'userProfile',
    value: {
      name: 'Ali Ahmadi',
      age: 30,
      preferences: { theme: 'dark' }
    }
  }
});

// Response: true | false
```

#### `get` — دریافت مقدار

```javascript
const value = await Native.call({
  plugin: 'storage',
  method: 'get',
  args: { key: 'userProfile' }
});

// Response: مقدار ذخیره‌شده یا null
// { name: 'Ali Ahmadi', age: 30, ... }
```

#### `remove` — حذف مقدار

```javascript
await Native.call({
  plugin: 'storage',
  method: 'remove',
  args: { key: 'userProfile' }
});
// Response: true | false
```

#### `clear` — پاکسازی همه

```javascript
await Native.call({
  plugin: 'storage',
  method: 'clear'
});
```

#### `keys` — لیست کلیدها

```javascript
const keys = await Native.call({
  plugin: 'storage',
  method: 'keys'
});
// Response: ['username', 'userProfile', 'settings']
```

#### `readFile` — خواندن فایل

```javascript
// خواندن متن
const content = await Native.call({
  plugin: 'storage',
  method: 'readFile',
  args: {
    path: 'data/config.json',
    encoding: 'utf8'  // 'utf8' | 'base64'
  }
});

// خواندن فایل باینری به Base64
const base64 = await Native.call({
  plugin: 'storage',
  method: 'readFile',
  args: {
    path: 'images/photo.jpg',
    encoding: 'base64'
  }
});
```

#### `writeFile` — نوشتن فایل

```javascript
// نوشتن متن
await Native.call({
  plugin: 'storage',
  method: 'writeFile',
  args: {
    path: 'data/config.json',
    content: JSON.stringify({ theme: 'dark' }),
    encoding: 'utf8'
  }
});

// نوشتن فایل باینری از Base64
await Native.call({
  plugin: 'storage',
  method: 'writeFile',
  args: {
    path: 'uploads/image.jpg',
    content: base64String,
    encoding: 'base64'
  }
});
// Response: true | false
```

#### `deleteFile` — حذف فایل

```javascript
await Native.call({
  plugin: 'storage',
  method: 'deleteFile',
  args: { path: 'data/old_file.json' }
});
// Response: true | false
```

#### `fileExists` — بررسی وجود فایل

```javascript
const exists = await Native.call({
  plugin: 'storage',
  method: 'fileExists',
  args: { path: 'data/config.json' }
});
// Response: true | false
```

#### `listFiles` — لیست فایل‌ها

```javascript
const files = await Native.call({
  plugin: 'storage',
  method: 'listFiles',
  args: { path: 'data' }  // پوشه (اختیاری)
});

// Response:
// [
//   {
//     name: 'config.json',
//     path: '/data/config.json',
//     type: 'file',
//     size: 1024,
//     modified: '2024-01-01T12:00:00.000Z'
//   },
//   {
//     name: 'images',
//     path: '/data/images',
//     type: 'directory',
//     size: 0,
//     modified: '2024-01-01T10:00:00.000Z'
//   }
// ]
```

---

### 📍 Geolocation Plugin

**نام:** `geolocation` | **نسخه:** `1.0.0`

#### `getCurrentPosition` — موقعیت فعلی

```javascript
const position = await Native.call({
  plugin: 'geolocation',
  method: 'getCurrentPosition',
  args: {
    accuracy: 'high'  // 'low' | 'medium' | 'high' | 'best'
  }
});

// Response:
// {
//   latitude: 35.6892,
//   longitude: 51.3890,
//   altitude: 1200.5,
//   accuracy: 10.0,
//   heading: 270.0,
//   speed: 0.0,
//   timestamp: '2024-01-01T12:00:00.000Z'
// }
```

#### `watchPosition` — ردیابی مداوم

```javascript
// شروع ردیابی
await Native.call({
  plugin: 'geolocation',
  method: 'watchPosition',
  args: {
    accuracy: 'high',
    distanceFilter: 10  // به‌روزرسانی هر 10 متر (متر)
  }
});

// دریافت رویداد‌های موقعیت
Native.on('location_update', (position) => {
  console.log('New position:', position);
  updateMap(position.latitude, position.longitude);
});

// توقف ردیابی
await Native.call({
  plugin: 'geolocation',
  method: 'clearWatch'
});
```

#### `checkPermission` — بررسی مجوز

```javascript
const status = await Native.call({
  plugin: 'geolocation',
  method: 'checkPermission'
});
// Response: 'granted' | 'denied' | 'whileInUse' | 'always'
```

#### `requestPermission` — درخواست مجوز

```javascript
const status = await Native.call({
  plugin: 'geolocation',
  method: 'requestPermission'
});
// Response: 'granted' | 'denied' | 'whileInUse'
```

#### `isLocationEnabled` — بررسی فعال بودن GPS

```javascript
const enabled = await Native.call({
  plugin: 'geolocation',
  method: 'isLocationEnabled'
});
// Response: true | false
```

---

## 🔒 Security Layer

### Permission Manager

```dart
// تنظیم permission provider سفارشی
class MyPermissionProvider implements PermissionProvider {
  @override
  Future<PermissionStatus> checkPermission(String permission) async {
    switch (permission) {
      case 'camera':
        final status = await Permission.camera.status;
        return _mapStatus(status);
      case 'location':
        final status = await Permission.location.status;
        return _mapStatus(status);
      default:
        return PermissionStatus.granted;
    }
  }

  @override
  Future<PermissionStatus> requestPermission(String permission) async {
    switch (permission) {
      case 'camera':
        final status = await Permission.camera.request();
        return _mapStatus(status);
      default:
        return PermissionStatus.denied;
    }
  }

  PermissionStatus _mapStatus(PermissionStatusValue status) {
    if (status.isGranted) return PermissionStatus.granted;
    if (status.isDenied) return PermissionStatus.denied;
    return PermissionStatus.notDetermined;
  }
}

// استفاده
final manager = PermissionManager();
manager.setProvider(MyPermissionProvider());

// بررسی یک مجوز
final hasCamera = await manager.check('camera');

// بررسی چند مجوز
final results = await manager.checkAll(['camera', 'storage', 'location']);
// { 'camera': true, 'storage': true, 'location': false }

// درخواست مجوز
final granted = await manager.request('camera');

// invalidate cache
manager.invalidateCache('camera');
manager.invalidateCache(); // همه
```

### Rate Limiter

```dart
final limiter = RateLimiter();

// ── قوانین از پیش‌تعریف‌شده ────────────────────────────────
limiter.addRule('camera', RateLimitRule.perMinute(20));
limiter.addRule('geolocation.getCurrentPosition', RateLimitRule.perSecond(1));

// ── قانون سفارشی ─────────────────────────────────────────────
limiter.addRule('myPlugin', RateLimitRule(
  maxCalls: 100,
  window: const Duration(minutes: 5),
));

// ── قانون پیش‌فرض ───────────────────────────────────────────
limiter.setDefaultRule(RateLimitRule.perSecond(50));

// ── بررسی دستی ─────────────────────────────────────────────
final result = await limiter.check('camera', 'takePhoto');
if (!result.allowed) {
  print('Rate limited! Retry after: ${result.retryAfterMs}ms');
}

// ── آمار ────────────────────────────────────────────────────
final stats = limiter.getStats();
// { 'camera.takePhoto': { callsInWindow: 5, maxCalls: 20, windowSeconds: 60 } }

// ── reset ───────────────────────────────────────────────────
limiter.reset('camera.takePhoto');
```

### Execution Guard

```dart
final guard = ExecutionGuard(defaultTimeoutMs: 30000);

// ── اجرا با timeout ─────────────────────────────────────────
final result = await guard.execute(
  requestId: 'unique-id',
  timeoutMs: 5000,
  fn: () => myAsyncOperation(),
);

// ── بررسی اجراهای فعال ─────────────────────────────────────
print('Active executions: ${guard.activeCount}');
print('Active request IDs: ${guard.activeRequests}');
```

### Args Validator

```dart
// تعریف schema
final schema = {
  'quality': ArgSchema(
    type: 'int',
    required: false,
    validator: (value) {
      if (value < 0 || value > 100) {
        return 'Quality must be between 0 and 100';
      }
      return null; // valid
    },
  ),
  'path': ArgSchema(
    type: 'string',
    required: true,
  ),
};

// اعتبارسنجی در پلاگین
@override
Future<ValidationResult> validateArgs(
  String method,
  Map<String, dynamic> args,
) async {
  if (method == 'takePhoto') {
    return ArgsValidator.validate(args, {
      'quality': ArgSchema(type: 'int', required: false),
      'maxWidth': ArgSchema(type: 'double', required: false),
    });
  }
  return ValidationResult.valid();
}
```

---

## ⚡ Performance Layer

### Cache Manager

```dart
final cache = CacheManager(maxEntries: 500);

// ── ذخیره با TTL ─────────────────────────────────────────────
await cache.set(
  'location:Tehran',
  { 'lat': 35.68, 'lng': 51.38 },
  ttl: const Duration(minutes: 10),
);

// ── دریافت ──────────────────────────────────────────────────
final data = await cache.get('location:Tehran');
// null اگر منقضی شده یا وجود ندارد

// ── invalidate ───────────────────────────────────────────────
await cache.invalidate('location:Tehran');

// ── invalidate با pattern ─────────────────────────────────────
await cache.invalidatePattern('location:.*');  // regex

// ── پاکسازی کامل ────────────────────────────────────────────
await cache.clear();

// ── آمار ────────────────────────────────────────────────────
final stats = cache.stats;
// CacheStats {
//   entries: 145,
//   hits: 892,
//   misses: 234,
//   hitRate: 0.79
// }
```

### Batch Options

```dart
// ── موازی (پیش‌فرض) ─────────────────────────────────────────
BatchOptions.defaults()
// parallel: true, stopOnError: false

// ── سریالی ─────────────────────────────────────────────────
BatchOptions(
  parallel: false,
  stopOnError: true,
  timeoutMs: 10000,
)
```

---

## 🔍 Bridge Inspector

ابزار دیداری برای مانیتور کردن تمام ارتباط‌های bridge.

### استفاده در Flutter

```dart
// نمایش Inspector روی WebView
class MyScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // WebView اصلی
          WebViewHost(
            bridge: sl<MessageBridge>(),
            config: WebViewHostConfig.development(),
            initialHtml: myHtml,
          ),

          // Inspector (فقط در development)
          if (kDebugMode)
            DraggableScrollableSheet(
              initialChildSize: 0.4,
              builder: (ctx, scroll) => BridgeInspectorWidget(
                inspector: sl<BridgeInspector>(),
              ),
            ),
        ],
      ),

      // دکمه toggle
      floatingActionButton: FloatingActionButton(
        onPressed: () => toggleInspector(),
        child: const Icon(Icons.bug_report),
      ),
    );
  }
}
```

### استفاده برنامه‌نویسی

```dart
final inspector = BridgeInspector(
  bridge: messageBridge,
  manager: pluginManager,
);

// ── دریافت log stream ────────────────────────────────────────
inspector.logStream.listen((entry) {
  print('${entry.direction}: ${entry.content}');
});

// ── دریافت همه log ها ───────────────────────────────────────
final allLogs = inspector.log;

// ── بررسی خطاها ─────────────────────────────────────────────
final errors = inspector.log.where((e) => e.isError).toList();

// ── گزارش کامل ──────────────────────────────────────────────
final report = inspector.getReport();
// {
//   totalRequests: 234,
//   pluginStats: {
//     'camera.takePhoto': { totalCalls: 12, avgTimeMs: 1250 }
//   },
//   recentErrors: [...]
// }

// ── پاکسازی ─────────────────────────────────────────────────
inspector.clear();
```

### ویژگی‌های Inspector UI

```
┌─────────────────────────────────────────┐
│  🔍 Bridge Inspector            [Clear] │
├─────────────────────────────────────────┤
│  [Filter...          ] [Errors Only ✓]  │
├─────────────────────────────────────────┤
│  ↓ camera.takePhoto           12:34:56 │ ← JS به Flutter
│  ↑ camera.takePhoto ✓         12:34:57 │ ← Flutter به JS
│  ↓ storage.get                12:34:58 │
│  ↑ storage.get ✓              12:34:58 │
│  ↓ unknown.method ✗           12:35:01 │ ← خطا (قرمز)
├─────────────────────────────────────────┤
│  Total: 234  │  Errors: 3  │ Pending: 1│
└─────────────────────────────────────────┘
```

- **رنگ آبی**: درخواست از JS به Flutter
- **رنگ سبز**: پاسخ از Flutter به JS
- **رنگ قرمز**: پیام خطا
- **کلیک روی هر entry**: نمایش JSON کامل
- **Filter**: جستجو در محتوای پیام‌ها

---

## 🛠 CLI Tool

### نصب

```bash
dart pub global activate --source path cli/
```

### دستورات

#### `create-plugin` — ساخت پلاگین جدید

```bash
dart run cli/bin/bridge_cli.dart create-plugin

# خروجی:
# Plugin name: myPlugin
# Version (1.0.0): 1.0.0
# Description: My awesome plugin
#
# 📦 Creating plugin: myPlugin@1.0.0
# ✅ Plugin created at: plugins/myPlugin
#
# Next steps:
#   1. Edit plugins/myPlugin/lib/myplugin_plugin.dart
#   2. Add your methods to supportedMethods
#   3. Register in lib/di/service_locator.dart
```

ساختار تولید شده:

```
plugins/myPlugin/
├── manifest.json          # تعریف متادیتا
├── pubspec.yaml           # وابستگی‌های Dart
├── lib/
│   └── myplugin_plugin.dart  # کد اصلی پلاگین
├── android/
│   └── src/main/kotlin/      # کد Android (اختیاری)
├── ios/
│   └── Classes/              # کد iOS (اختیاری)
└── js/
    └── myplugin.js           # JS wrapper
```

#### `list-plugins` — لیست پلاگین‌ها

```bash
dart run cli/bin/bridge_cli.dart list-plugins

# 📦 Registered Plugins:
#
#   ✓ camera
#   ✓ storage
#   ✓ geolocation
#   ✓ myPlugin
```

---

## 🔧 ساخت پلاگین سفارشی

### گام ۱: ایجاد کلاس پلاگین

```dart
// plugins/my_plugin/lib/my_plugin.dart

class MyPlugin extends Plugin {

  // ── شناسه ────────────────────────────────────────────────────
  @override
  String get name => 'myPlugin';

  @override
  String get version => '1.0.0';

  @override
  String get description => 'My custom plugin';

  // ── متدهای پشتیبانی‌شده ────────────────────────────────────
  @override
  List<String> get supportedMethods => [
    'fetchData',
    'processImage',
    'sendNotification',
  ];

  // ── مجوزهای لازم ───────────────────────────────────────────
  @override
  List<String> get requiredPermissions => ['storage'];

  // ── lifecycle ─────────────────────────────────────────────
  @override
  Future<void> onInitialize() async {
    // اتصال به DB، شروع سرویس، etc.
    await _initDatabase();
  }

  @override
  Future<void> onDispose() async {
    await _closeDatabase();
  }

  // ── اجرا ─────────────────────────────────────────────────
  @override
  Future<dynamic> onCall(
    String method,
    Map<String, dynamic> args,
  ) async {
    switch (method) {
      case 'fetchData':
        return _fetchData(args);
      case 'processImage':
        return _processImage(args);
      case 'sendNotification':
        return _sendNotification(args);
      default:
        throw UnsupportedError('Method "$method" not supported');
    }
  }

  // ── اعتبارسنجی ───────────────────────────────────────────
  @override
  Future<ValidationResult> validateArgs(
    String method,
    Map<String, dynamic> args,
  ) async {
    if (method == 'fetchData') {
      if (!args.containsKey('url')) {
        return ValidationResult.invalid('url is required');
      }

      final url = args['url'] as String?;
      if (url == null || !url.startsWith('https://')) {
        return ValidationResult.invalid('Only HTTPS URLs allowed');
      }
    }

    return ValidationResult.valid();
  }

  // ── پیاده‌سازی متدها ──────────────────────────────────────
  Future<Map<String, dynamic>> _fetchData(
    Map<String, dynamic> args,
  ) async {
    final url = args['url'] as String;
    final response = await http.get(Uri.parse(url));

    return {
      'statusCode': response.statusCode,
      'body': response.body,
      'headers': response.headers,
    };
  }

  Future<Map<String, dynamic>> _processImage(
    Map<String, dynamic> args,
  ) async {
    // پردازش تصویر
    return {'processed': true};
  }

  Future<bool> _sendNotification(
    Map<String, dynamic> args,
  ) async {
    final title = args['title'] as String;
    final body = args['body'] as String;
    // ارسال نوتیفیکیشن
    return true;
  }
}
```

### گام ۲: تعریف manifest.json

```json
{
  "name": "myPlugin",
  "version": "1.0.0",
  "description": "My custom plugin",
  "methods": [
    "fetchData",
    "processImage",
    "sendNotification"
  ],
  "permissions": ["storage"],
  "capabilities": {
    "supportsStreaming": false,
    "supportsBatch": true,
    "supportsCache": true,
    "maxConcurrentCalls": 5
  }
}
```

### گام ۳: JS Wrapper

```javascript
// plugins/my_plugin/js/my_plugin.js

const MyPlugin = {
  /**
   * دریافت داده از URL
   * @param {string} url
   * @returns {Promise<{statusCode, body, headers}>}
   */
  async fetchData(url) {
    return Native.call({
      plugin: 'myPlugin',
      method: 'fetchData',
      args: { url }
    });
  },

  /**
   * پردازش تصویر
   * @param {Object} options
   * @returns {Promise}
   */
  async processImage(options = {}) {
    return Native.call({
      plugin: 'myPlugin',
      method: 'processImage',
      args: options
    });
  },

  /**
   * ارسال نوتیفیکیشن
   * @param {string} title
   * @param {string} body
   * @returns {Promise<boolean>}
   */
  async sendNotification(title, body) {
    return Native.call({
      plugin: 'myPlugin',
      method: 'sendNotification',
      args: { title, body }
    });
  }
};
```

### گام ۴: ثبت پلاگین

```dart
// lib/di/service_locator.dart

static Future<void> _registerPlugins() async {
  final registry = sl<PluginRegistry>();

  // پلاگین‌های پیش‌فرض
  await registry.register(CameraPlugin());
  await registry.register(StoragePlugin());
  await registry.register(GeolocationPlugin());

  // پلاگین سفارشی
  await registry.register(MyPlugin());
}
```

### گام ۵: استفاده در JS

```javascript
// استفاده مستقیم
const data = await Native.call({
  plugin: 'myPlugin',
  method: 'fetchData',
  args: { url: 'https://api.example.com/data' }
});

// یا با wrapper
const data = await MyPlugin.fetchData('https://api.example.com/data');
```

---

## 📜 Protocol Specification

### Request Format

```json
{
  "requestId": "550e8400-e29b-41d4-a716-446655440000",
  "timestamp": "2024-01-01T12:00:00.000Z",
  "plugin": "camera",
  "version": "1.0.0",
  "method": "takePhoto",
  "args": {
    "quality": 80,
    "maxWidth": 1920
  },
  "metadata": {
    "sessionId": "session-123",
    "userId": "user-456",
    "headers": {
      "X-App-Version": "2.0.0"
    }
  }
}
```

### Response Format (Success)

```json
{
  "requestId": "550e8400-e29b-41d4-a716-446655440000",
  "timestamp": "2024-01-01T12:00:01.250Z",
  "success": true,
  "data": {
    "path": "/data/user/0/photo.jpg",
    "size": 245120,
    "mimeType": "image/jpeg"
  },
  "metadata": {
    "processingTimeMs": 1250,
    "pluginVersion": "1.0.0",
    "fromCache": false
  }
}
```

### Response Format (Error)

```json
{
  "requestId": "550e8400-e29b-41d4-a716-446655440000",
  "timestamp": "2024-01-01T12:00:00.050Z",
  "success": false,
  "error": {
    "code": "PERMISSION_DENIED",
    "message": "Camera permission has not been granted",
    "details": {
      "permission": "camera",
      "platform": "android"
    }
  },
  "metadata": {
    "processingTimeMs": 50,
    "pluginVersion": "1.0.0",
    "fromCache": false
  }
}
```

### Batch Request Format

```json
{
  "type": "batch",
  "batchId": "batch-uuid",
  "requests": [
    { "requestId": "req-1", "plugin": "storage", "method": "keys" },
    { "requestId": "req-2", "plugin": "camera",  "method": "getInfo" }
  ],
  "options": {
    "parallel": true,
    "stopOnError": false,
    "timeoutMs": 10000
  }
}
```

### Error Codes

| کد | توضیح | راه‌حل |
|----|-------|---------|
| `PERMISSION_DENIED` | مجوز داده نشده | درخواست مجوز از کاربر |
| `PLUGIN_NOT_FOUND` | پلاگین ثبت نشده | بررسی نام پلاگین |
| `METHOD_NOT_FOUND` | متد پشتیبانی نمی‌شود | بررسی نام متد |
| `INVALID_ARGS` | آرگومان نامعتبر | بررسی schema |
| `TIMEOUT` | زمان منقضی شد | افزایش timeout |
| `RATE_LIMIT_EXCEEDED` | تعداد درخواست زیاد | کاهش فرکانس |
| `EXECUTION_ERROR` | خطا در اجرا | بررسی لاگ‌ها |
| `SANDBOX_VIOLATION` | نقض امنیتی | بررسی policy |
| `NETWORK_ERROR` | خطای شبکه | بررسی اتصال |
| `UNKNOWN` | خطای ناشناس | بررسی لاگ‌ها |

---

## ⚙️ پیکربندی پیشرفته

### WebView Host Config

```dart
// Development
final config = WebViewHostConfig.development();
// enableDebugging: true, defaultTimeoutMs: 60000

// Production
final config = WebViewHostConfig.production();
// enableDebugging: false, defaultTimeoutMs: 30000

// سفارشی
final config = WebViewHostConfig(
  enableDebugging: false,
  allowFileAccess: true,
  defaultTimeoutMs: 45000,
  allowedHosts: ['api.myapp.com', 'cdn.myapp.com'],
);
```

### Logger Configuration

```dart
// تنظیم حداقل سطح لاگ
BridgeLogger.setMinLevel(LogLevel.warn); // فقط warn و error

// اضافه کردن sink سفارشی
BridgeLogger.addSink(ConsoleSink());   // چاپ در کنسول
BridgeLogger.addSink(MemorySink(maxEntries: 1000)); // نگهداری در حافظه
BridgeLogger.addSink(FileSink(pathProvider: () => '/logs/bridge.log'));

// دریافت stream لاگ
BridgeLogger.stream.listen((entry) {
  if (entry.level == LogLevel.error) {
    crashReporter.log(entry.message);
  }
});

// دسترسی به تاریخچه
final history = BridgeLogger.history; // List<LogEntry>

// پاکسازی
BridgeLogger.clear();
```

### Message Bridge Events

```dart
// مانیتور کردن تمام پیام‌ها
bridge.messageStream.listen((message) {
  if (message.direction == BridgeMessageDirection.incoming) {
    analytics.logEvent('bridge_call', {
      'plugin': (message.message as PluginRequest).plugin,
      'method': (message.message as PluginRequest).method,
    });
  }
});

// ارسال رویداد از Flutter به JS
await bridge.emitEvent('user_login', {
  'userId': '123',
  'timestamp': DateTime.now().toIso8601String(),
});

await bridge.emitEvent('push_notification', {
  'title': 'پیام جدید',
  'body': 'یک پیام جدید دارید',
  'data': { 'messageId': '456' }
});
```

---

## 🧪 تست‌نویسی

### تست پلاگین

```dart
import 'package:flutter_test/flutter_test.dart';

class MockPlugin extends Plugin {
  @override
  String get name => 'test';

  @override
  String get version => '1.0.0';

  @override
  List<String> get supportedMethods => ['testMethod'];

  @override
  Future<dynamic> onCall(String method, Map<String, dynamic> args) async {
    return {'method': method, 'args': args, 'success': true};
  }
}

void main() {
  group('Plugin Tests', () {
    late PluginManager manager;
    late PluginRegistry registry;

    setUp(() async {
      registry = PluginRegistry();
      manager = PluginManager(
        registry: registry,
        permissionManager: PermissionManager(),
        rateLimiter: RateLimiter(),
        executionGuard: ExecutionGuard(),
        cacheManager: CacheManager(),
      );
      await registry.register(MockPlugin());
    });

    test('should execute plugin method', () async {
      final request = PluginRequest.create(
        plugin: 'test',
        method: 'testMethod',
        args: {'key': 'value'},
      );

      final response = await manager.execute(request);

      expect(response.success, isTrue);
      expect(response.data['method'], equals('testMethod'));
    });

    test('should handle unknown plugin', () async {
      final request = PluginRequest.create(
        plugin: 'unknown',
        method: 'test',
      );

      final response = await manager.execute(request);

      expect(response.success, isFalse);
      expect(response.error!.code, equals(PluginErrorCode.pluginNotFound));
    });
  });
}
```

### تست Rate Limiter

```dart
test('should enforce rate limits', () async {
  final limiter = RateLimiter();
  limiter.addRule('test', RateLimitRule.perSecond(2));

  final r1 = await limiter.check('test', 'method'); // ✓
  final r2 = await limiter.check('test', 'method'); // ✓
  final r3 = await limiter.check('test', 'method'); // ✗ blocked

  expect(r1.allowed, isTrue);
  expect(r2.allowed, isTrue);
  expect(r3.allowed, isFalse);
  expect(r3.retryAfterMs, greaterThan(0));
});
```

### تست Cache

```dart
test('should cache and expire', () async {
  final cache = CacheManager();

  await cache.set('key', 'value', ttl: const Duration(milliseconds: 100));

  expect(await cache.get('key'), equals('value'));

  await Future.delayed(const Duration(milliseconds: 200));

  expect(await cache.get('key'), isNull);
});
```

### اجرای تست‌ها

```bash
# همه تست‌ها
flutter test

# یک فایل خاص
flutter test test/plugin_manager_test.dart

# با coverage
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
```

---

## 🐛 عیب‌یابی

### مشکل: Bridge آماده نمی‌شود

```javascript
// بررسی وضعیت bridge
console.log('Bridge initialized:', window.__NativeBridgeInitialized);
console.log('Native object:', typeof window.Native);

// راه‌حل: صبر برای آماده شدن
async function waitForBridge(timeout = 5000) {
  const start = Date.now();
  while (!window.__NativeBridgeInitialized) {
    if (Date.now() - start > timeout) {
      throw new Error('Bridge initialization timeout');
    }
    await new Promise(r => setTimeout(r, 100));
  }
}

await waitForBridge();
const result = await Native.call({ plugin: 'storage', method: 'keys' });
```

### مشکل: درخواست timeout می‌شود

```javascript
// افزایش timeout
const result = await Native.call({
  plugin: 'geolocation',
  method: 'getCurrentPosition',
  timeout: 60000  // 60 ثانیه
});

// بررسی درخواست‌های pending
console.log('Pending requests:', window.__bridgeDebug.getPending());

// پاکسازی اجباری
window.__bridgeDebug.clearPending();
```

```dart
// در Flutter: افزایش timeout پیش‌فرض
sl.registerLazySingleton<ExecutionGuard>(
  () => ExecutionGuard(defaultTimeoutMs: 60000),
);
```

### مشکل: Permission Denied

```dart
// بررسی status مجوز
final status = await permissionManager.check('camera');
print('Camera permission: $status');

// invalidate cache و درخواست مجدد
permissionManager.invalidateCache('camera');
final granted = await permissionManager.request('camera');
```

```javascript
// از JS
try {
  await Native.call({ plugin: 'camera', method: 'takePhoto' });
} catch (error) {
  if (error.code === 'PERMISSION_DENIED') {
    // درخواست مجوز از کاربر
    const status = await Native.call({
      plugin: 'geolocation',
      method: 'requestPermission'
    });

    if (status === 'granted') {
      // تلاش مجدد
    }
  }
}
```

### مشکل: Rate Limit

```javascript
try {
  await Native.call({ plugin: 'camera', method: 'takePhoto' });
} catch (error) {
  if (error.code === 'RATE_LIMIT_EXCEEDED') {
    const retryAfter = error.retryAfterMs || 1000;
    await new Promise(r => setTimeout(r, retryAfter));
    // تلاش مجدد
  }
}
```

### مشکل: Plugin not found

```dart
// بررسی ثبت بودن پلاگین
final registered = registry.registeredPlugins;
print('Registered plugins: $registered');

// ثبت مجدد
await registry.register(MyPlugin());
```

### لاگ‌های دیباگ

```dart
// فعال‌سازی لاگ کامل
BridgeLogger.setMinLevel(LogLevel.debug);

// فیلتر بر اساس tag
BridgeLogger.stream
  .where((e) => e.tag == 'Manager')
  .listen((e) => print(e));
```

---

## 📁 ساختار کامل پروژه

```
flutter_native_bridge/
│
├── lib/                              # کد اصلی Flutter
│   ├── main.dart                     # نقطه ورود
│   ├── app.dart                      # Root widget
│   ├── di/
│   │   └── service_locator.dart      # Dependency Injection
│   └── screens/
│       └── home_screen.dart          # صفحه اصلی
│
├── packages/
│   ├── core/                         # هسته اصلی
│   │   └── lib/src/
│   │       ├── bridge/
│   │       │   └── message_bridge.dart
│   │       ├── protocol/
│   │       │   └── message_protocol.dart
│   │       ├── runtime/
│   │       │   └── webview_host.dart
│   │       └── utils/
│   │           └── logger.dart
│   │
│   ├── plugin_engine/               # موتور پلاگین
│   │   └── lib/src/
│   │       ├── plugin_interface.dart
│   │       ├── plugin_registry.dart
│   │       └── plugin_manager.dart
│   │
│   ├── security/                    # لایه امنیتی
│   │   └── lib/src/
│   │       ├── permission_manager.dart
│   │       ├── rate_limiter.dart
│   │       └── execution_guard.dart
│   │
│   ├── performance/                 # بهینه‌سازی
│   │   └── lib/src/
│   │       └── cache_manager.dart
│   │
│   └── devtools/                    # ابزارهای توسعه
│       └── lib/src/
│           └── bridge_inspector.dart
│
├── plugins/                         # پلاگین‌های داخلی
│   ├── camera/
│   │   ├── manifest.json
│   │   ├── pubspec.yaml
│   │   ├── lib/camera_plugin.dart
│   │   └── js/camera.js
│   │
│   ├── storage/
│   │   ├── manifest.json
│   │   ├── lib/storage_plugin.dart
│   │   └── js/storage.js
│   │
│   └── geolocation/
│       ├── manifest.json
│       ├── lib/geolocation_plugin.dart
│       └── js/geolocation.js
│
├── cli/                             # ابزار CLI
│   └── bin/
│       └── bridge_cli.dart
│
├── test/                            # تست‌ها
│   ├── plugin_manager_test.dart
│   ├── protocol_test.dart
│   ├── security_test.dart
│   └── cache_test.dart
│
├── example/                         # مثال‌های کاربردی
│   ├── basic_usage.html
│   ├── advanced_usage.html
│   └── batch_example.html
│
├── docs/                            # مستندات اضافی
│   ├── ARCHITECTURE.md
│   ├── PLUGIN_GUIDE.md
│   └── SECURITY.md
│
├── pubspec.yaml
├── analysis_options.yaml
└── README.md
```

---

## 🤝 مشارکت در پروژه

### گردش کار

```bash
# ۱. Fork و Clone
git clone https://github.com/your-username/flutter_native_bridge.git
cd flutter_native_bridge

# ۲. ساخت branch جدید
git checkout -b feature/my-awesome-feature

# ۳. نصب dependencies
flutter pub get

# ۴. اجرای تست‌ها
flutter test

# ۵. اعمال تغییرات
# ... کدنویسی ...

# ۶. بررسی کیفیت کد
flutter analyze
dart format .

# ۷. Commit
git commit -m "feat: add my awesome feature"

# ۸. Push و PR
git push origin feature/my-awesome-feature
```

### استانداردهای کد

```dart
// ✅ درست: نام‌گذاری واضح
class CameraPlugin extends Plugin {
  Future<Map<String, dynamic>> _takePhoto(
    Map<String, dynamic> args,
  ) async { ... }
}

// ✅ درست: مدیریت خطا
try {
  final result = await plugin.onCall(method, args);
  return PluginResponse.success(requestId: id, data: result);
} catch (e) {
  return PluginResponse.failure(requestId: id, error: ...);
}

// ❌ اشتباه: expose native مستقیم
// JS نباید مستقیماً به native دسترسی داشته باشد
```

### Commit Convention

```
feat: اضافه کردن قابلیت جدید
fix: رفع باگ
docs: بروزرسانی مستندات
test: اضافه کردن تست
refactor: refactoring بدون تغییر رفتار
perf: بهبود عملکرد
security: رفع مشکل امنیتی
```

---

## 📊 Roadmap

### نسخه ۱.۱ (Q2 2024)
- [ ] پلاگین Bluetooth
- [ ] پلاگین Network (HTTP client)
- [ ] پشتیبانی از Web platform
- [ ] Binary encoding برای داده‌های بزرگ

### نسخه ۱.۲ (Q3 2024)
- [ ] Streaming support (long-running operations)
- [ ] Hot reload پلاگین‌ها
- [ ] Plugin marketplace
- [ ] TypeScript definitions

### نسخه ۲.۰ (Q4 2024)
- [ ] Multi-WebView support
- [ ] Shared Worker communication
- [ ] Plugin dependency management
- [ ] Visual plugin editor

---

## 📄 لایسنس

```
MIT License

Copyright (c) 2024 Flutter Native Bridge Contributors

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
```

---


**ساخته شده با ❤️ برای جامعه Flutter**

اگر این پروژه برایتان مفید بود، یک ⭐ بدهید!

[گزارش باگ](../../issues) •
[درخواست قابلیت](../../issues) •
[مستندات کامل](docs/)

```
