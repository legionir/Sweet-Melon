# بررسی کامل پروژه Flutter Native Bridge

---

## 🔴 باگ‌ها و نقاط ضعف

### ۱. باگ‌های Critical

**باگ ۱: `_isReady` در `MessageBridge` هرگز reset نمی‌شود**
```dart
// message_bridge.dart
void onBridgeReady() {
  _isReady = true;
  // اگر WebView reload بشه، _isReady هنوز true هست
  // ولی JS bridge دوباره باید inject بشه
  // pending messages پاک می‌شن ولی حالت قبلی ممکنه مشکل‌ساز بشه
}
```

**باگ ۲: Memory Leak در `GeolocationPlugin`**
```dart
// geolocation_plugin.dart - watchPosition
_positionStream = Geolocator.getPositionStream(...).listen(
  (position) {
    // اینجا هیچ کاری نمی‌کنه! event به JS ارسال نمی‌شه
    // کاملاً بی‌فایده است
  },
  onError: (error) {}, // error هم handle نمی‌شه
);
```

**باگ ۳: `FileSink` در Logger هیچ‌وقت به فایل نمی‌نویسد**
```dart
// logger.dart
void _flush() {
  if (_buffer.isEmpty) return;
  _buffer.clear(); // فقط buffer رو پاک می‌کنه، به فایل نمی‌نویسه!
}
```

**باگ ۴: Race Condition در `ServiceLocator`**
```dart
// service_locator.dart
sl<PluginRegistry>().setEventEmitter(sl<MessageBridge>().emitEvent);
// این خط بعد از registerLazySingleton<MessageBridge> هست
// ولی MessageBridge هنوز instantiate نشده (lazy)
// وقتی اولین بار استفاده بشه درست کار می‌کنه
// ولی ترتیب وابستگی‌ها مبهم است
```

**باگ ۵: XSS در JS Injection**
```dart
// message_bridge.dart
Future<void> emitEvent(String event, dynamic data) async {
  final escapedEvent = _escapeJsString(event);
  final dataJson = jsonEncode(data);
  // dataJson مستقیم داخل JS قرار می‌گیره
  // اگه data حاوی </script> باشه مشکل‌ساز می‌شه
  final js = 'window.__emitEvent("$escapedEvent", $dataJson);';
  await _runJs(js);
}
```

**باگ ۶: `_pendingJsMessages` بی‌نهایت رشد می‌کند**
```dart
// message_bridge.dart
Future<void> _runJs(String script) async {
  if (!_isReady) {
    _pendingJsMessages.add(script); // هیچ حد مجازی ندارد
    return;
  }
  // ...
}
```

**باگ ۷: `StoragePlugin` cache اشتباه کار می‌کند**
```dart
// storage_plugin.dart
@override
bool get cacheable => true;
// ولی set/remove/clear هم cache می‌شن!
// یعنی بعد از set، مقدار قدیمی از cache برگردونده می‌شه
// cache invalidation وجود ندارد
```

**باگ ۸: Type Cast خطرناک**
```dart
// message_bridge.dart
Future<void> handleIncomingMessage(Map<String, dynamic> json) async {
  if (json.containsKey('type') && json['type'] == 'batch') {
    await _handleBatchRequest(json);
    return;
  }
  // اگه 'type' وجود داشته باشه ولی 'plugin' نداشته باشه:
  final request = PluginRequest.fromJson(json); // crash می‌کنه
```

**باگ ۹: `PluginManager.executeBatch` با parallel=true خطاها رو نادیده می‌گیره**
```dart
// plugin_manager.dart
if (options.parallel) {
  return Future.wait(requests.map(execute).toList());
  // اگه یکی fail بشه، Future.wait کل چیز رو fail می‌کنه
  // stopOnError رعایت نمی‌شه در حالت parallel
}
```

**باگ ۱۰: `BridgeInspector` بعد از dispose هنوز event می‌فرسته**
```dart
// bridge_inspector.dart
_bridgeSub = bridge.messageStream.listen((message) {
  // ...
  if (!_logController.isClosed) {
    _logController.add(entry); // بررسی می‌کنه ولی...
  }
});
// اگه dispose بشه و بعد event بیاد، _log.add() بدون چک اضافه می‌شه
```

---

### ۲. باگ‌های Medium

**باگ ۱۱: `PermissionManager` cache مشکل دارد**
```dart
// permission_manager.dart
Future<bool> check(String permission) async {
  if (_cache.containsKey(permission)) {
    return cached == PermissionStatus.granted;
    // cache هیچ‌وقت expire نمی‌شه
    // اگه کاربر permission رو revoke کنه، هنوز granted برمی‌گردونه
  }
```

**باگ ۱۲: `RateLimiter` در concurrent calls thread-safe نیست**
```dart
// rate_limiter.dart
RateLimitResult consume() {
  final now = DateTime.now();
  final windowStart = now.subtract(rule.window);
  _calls.removeWhere((time) => time.isBefore(windowStart));
  // در Dart isolate single-thread هست ولی async gaps می‌تونه مشکل‌ساز بشه
```

**باگ ۱۳: `WebViewHostConfig` در `webview_host.dart` استفاده نمی‌شه**
```dart
// webview_host.dart
// enableDebugging و allowFileAccess در config هست
// ولی هیچ‌کدوم در WebViewController apply نمی‌شن!
_controller = WebViewController()
  ..setJavaScriptMode(JavaScriptMode.unrestricted)
  // config.enableDebugging → هیچ‌جا استفاده نشده
  // config.allowFileAccess → هیچ‌جا استفاده نشده
```

**باگ ۱۴: `Plugin._initialized` private field مشکل دارد**
```dart
// plugin_interface.dart
abstract class Plugin {
  bool _initialized = false;
  // این field در subclass‌ها قابل دسترسی نیست
  // ولی isReady از اون می‌خونه - ok هست
  // ولی اگه initialize دوبار صدا زده بشه، onInitialize دوبار اجرا می‌شه
```

**باگ ۱۵: `PluginRegistry` event emitter null safety**
```dart
// plugin_registry.dart
Future<void> emitEvent(String event, dynamic data) async {
  if (_eventEmitter != null) {
    await _eventEmitter!(event, data); // ok
  }
  // ولی setEventEmitter قبل از register صدا زده می‌شه
  // پلاگین‌ها در initialize می‌تونن event emit کنن - null می‌شه
```

---

### ۳. نقاط ضعف معماری

**ضعف ۱: Sub-package‌ها pubspec.yaml جداگانه دارن ولی در workspace اصلی path dependency تعریف نشده**

```yaml
# pubspec.yaml اصلی - این‌ها تعریف نشدن:
# core:
#   path: lib/packages/core
# security:
#   path: lib/packages/security
# ...
# ولی import می‌شن با 'package:sweetmelon/packages/...'
# این یعنی sub-packages به عنوان package مستقل کار نمی‌کنن
```

**ضعف ۲: `StaticPermissionProvider` در production همه چیز رو granted می‌ده**
```dart
// service_locator.dart
manager.setProvider(
  const StaticPermissionProvider(
    grants: {
      'camera': PermissionStatus.granted, // hardcode!
      'storage': PermissionStatus.granted,
      'location': PermissionStatus.granted,
    },
```

**ضعف ۳: هیچ Error Boundary در WebView وجود ندارد**

**ضعف ۴: `BridgeLogger` از `print` استفاده می‌کند که در production خطرناک است**

**ضعف ۵: هیچ تستی نوشته نشده**

---

## 📦 لیست پلاگین‌های مورد نیاز (اولویت‌بندی شده)

### 🔴 اولویت ۱ - بحرانی (باید همین الان اضافه بشن)

```yaml
# pubspec.yaml

dependencies:
  # ۱. Permission Handler واقعی - جایگزین StaticPermissionProvider
  permission_handler: ^11.3.0
  
  # ۲. WebView پیشرفته‌تر برای load کردن پروژه‌های Angular/React
  webview_flutter: ^4.8.0  # آپدیت به آخرین نسخه
  
  # ۳. File Picker برای باز کردن پروژه‌های HTML/JS/CSS
  file_picker: ^8.0.0+1
  
  # ۴. Connectivity برای مدیریت شبکه
  connectivity_plus: ^6.0.3
```

### 🟠 اولویت ۲ - مهم

```yaml
  # ۵. Dio - HTTP client قوی‌تر (جایگزین http ساده)
  dio: ^5.4.3
  
  # ۶. Flutter Secure Storage - برای ذخیره‌سازی امن token و داده‌های حساس
  flutter_secure_storage: ^9.0.0
  
  # ۷. Archive - برای extract کردن فایل‌های zip (پروژه Angular build شده)
  archive: ^3.4.10
  
  # ۸. Crypto - برای hash و signature verification
  crypto: ^3.0.3
  
  # ۹. RxDart - برای reactive programming در bridge
  rxdart: ^0.27.7
```

### 🟡 اولویت ۳ - توصیه شده

```yaml
  # ۱۰. Hive - database سریع‌تر از SharedPreferences
  hive_flutter: ^1.1.0
  
  # ۱۱. Logger - جایگزین print
  logger: ^2.3.0
  
  # ۱۲. Drift - SQLite ORM برای storage پیچیده
  drift: ^2.18.0
  
  # ۱۳. Flutter Local Notifications
  flutter_local_notifications: ^17.1.2
  
  # ۱۴. Device Info Plus
  device_info_plus: ^10.1.0
  
  # ۱۵. Package Info Plus
  package_info_plus: ^8.0.0

dev_dependencies:
  # ۱۶. Build Runner برای code generation
  build_runner: ^2.4.9
  
  # ۱۷. Mockito برای testing
  mockito: ^5.4.4
  
  # ۱۸. Flutter Test - تست‌نویسی
  flutter_test:
    sdk: flutter
```

### 🟢 اولویت ۴ - بهبود تجربه توسعه

```yaml
  # ۱۹. Freezed - immutable models
  freezed_annotation: ^2.4.1
  
  # ۲۰. Json Serializable
  json_annotation: ^4.8.1
  
  # ۲۱. Very Good Analysis - linting قوی‌تر
  
dev_dependencies:
  freezed: ^2.5.2
  json_serializable: ^6.7.1
  very_good_analysis: ^6.0.0
```

---

## 🚀 اجرای پروژه‌های Angular/React/Vue

### مشکل اصلی

الان WebView فقط یک HTML ساده inline اجرا می‌کند. برای اجرای پروژه‌های build شده (Angular، React، Vue) باید این معماری پیاده‌سازی بشه:

### روش ۱: Load از Assets (بهترین برای production)

**مرحله ۱: ساختار پوشه**
```
assets/
  web/
    index.html
    main.js
    styles.css
    chunk.123.js
    ...
```

**مرحله ۲: pubspec.yaml**
```yaml
flutter:
  assets:
    - assets/web/
    - assets/web/index.html
    # برای Angular build output:
    # ng build --output-path=assets/web --base-href=/
```

**مرحله ۳: WebViewHost را تغییر دهید**
```dart
// lib/packages/core/lib/src/runtime/webview_host.dart

class WebViewHost extends StatefulWidget {
  final String? initialUrl;
  final String? initialHtml;
  final String? assetPath;      // 👈 اضافه کن
  final String? localDirectory; // 👈 اضافه کن
  // ...
}

class _WebViewHostState extends State<WebViewHost> {
  
  void _initController() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      // برای Android - باید file access فعال بشه
      ..setBackgroundColor(Colors.transparent)
      ..addJavaScriptChannel('flutterBridge', onMessageReceived: _onJsMessage)
      ..addJavaScriptChannel('__bridgeInternal', onMessageReceived: _onInternalMessage);

    widget.bridge.setWebViewController(_controller);
    _loadContent();
  }

  Future<void> _loadContent() async {
    if (widget.assetPath != null) {
      // روش ۱: از assets
      await _loadFromAssets(widget.assetPath!);
    } else if (widget.localDirectory != null) {
      // روش ۲: از فایل‌های extract شده
      await _loadFromDirectory(widget.localDirectory!);
    } else if (widget.initialHtml != null) {
      await _controller.loadHtmlString(widget.initialHtml!);
    } else if (widget.initialUrl != null && widget.initialUrl!.isNotEmpty) {
      await _controller.loadRequest(Uri.parse(widget.initialUrl!));
    }
  }

  Future<void> _loadFromAssets(String assetPath) async {
    // برای webview_flutter v4+ می‌تونیم مستقیم load کنیم
    await _controller.loadFlutterAsset(assetPath);
  }

  Future<void> _loadFromDirectory(String dirPath) async {
    final file = File('$dirPath/index.html');
    if (await file.exists()) {
      await _controller.loadRequest(
        Uri.file('$dirPath/index.html'),
      );
    }
  }
}
```

**مرحله ۴: AndroidManifest.xml باید آپدیت بشه**
```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <!-- اضافه کن -->
    <uses-permission android:name="android.permission.INTERNET"/>
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/>
    <uses-permission android:name="android.permission.CAMERA"/>
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
    <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>
    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
    
    <application
        android:label="sweetmelon"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher"
        android:usesCleartextTraffic="true"> <!-- برای dev -->
```

### روش ۲: Load از zip فایل (پویا - Dynamic Loading)

```dart
// lib/services/web_app_loader.dart

import 'package:archive/archive.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

class WebAppLoader {
  final Dio _dio = Dio();
  
  /// دانلود و extract کردن پروژه Angular/React از server
  Future<String> loadFromUrl(String zipUrl) async {
    final appDir = await getApplicationDocumentsDirectory();
    final webDir = Directory('${appDir.path}/web_app');
    
    // اگه قبلاً extract شده، همون رو برگردون
    final indexFile = File('${webDir.path}/index.html');
    if (await indexFile.exists()) {
      return webDir.path;
    }
    
    // دانلود zip
    final zipPath = '${appDir.path}/web_app.zip';
    await _dio.download(zipUrl, zipPath);
    
    // Extract
    await _extractZip(zipPath, webDir.path);
    
    return webDir.path;
  }
  
  /// Load از assets (پروژه Angular که build شده و داخل assets گذاشتیم)
  Future<String> loadFromAssets(String assetPrefix) async {
    final appDir = await getApplicationDocumentsDirectory();
    final webDir = Directory('${appDir.path}/web_app');
    await webDir.create(recursive: true);
    
    // copy از assets به filesystem
    // این لازمه چون WebView نمی‌تونه مستقیم از assets چندین فایل بخونه
    final manifestContent = await rootBundle.loadString('AssetManifest.json');
    final manifest = jsonDecode(manifestContent) as Map<String, dynamic>;
    
    final webAssets = manifest.keys
        .where((key) => key.startsWith(assetPrefix))
        .toList();
    
    for (final assetKey in webAssets) {
      final relativePath = assetKey.replaceFirst(assetPrefix, '');
      final targetFile = File('${webDir.path}/$relativePath');
      await targetFile.parent.create(recursive: true);
      
      final data = await rootBundle.load(assetKey);
      await targetFile.writeAsBytes(data.buffer.asUint8List());
    }
    
    return webDir.path;
  }
  
  Future<void> _extractZip(String zipPath, String targetDir) async {
    final bytes = await File(zipPath).readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);
    
    for (final file in archive) {
      final filename = file.name;
      if (file.isFile) {
        final outFile = File('$targetDir/$filename');
        await outFile.parent.create(recursive: true);
        await outFile.writeAsBytes(file.content as List<int>);
      }
    }
  }
}
```

### روش ۳: استفاده از `flutter_inappwebview` (قوی‌ترین روش)

```yaml
dependencies:
  flutter_inappwebview: ^6.0.0
```

```dart
// این پکیج قابلیت‌های بسیار بیشتری داره:
// - Load از local files
// - JavaScript injection پیشرفته
// - Cookie management
// - Custom scheme handler
// - Service Worker support (برای PWA های Angular)

import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class AdvancedWebViewHost extends StatefulWidget {
  // ...
}

class _AdvancedWebViewHostState extends State<AdvancedWebViewHost> {
  InAppWebViewController? _controller;
  
  @override
  Widget build(BuildContext context) {
    return InAppWebView(
      initialUrlRequest: URLRequest(
        url: WebUri.uri(Uri.parse('http://localhost:8080')),
      ),
      // یا load از local file:
      initialData: InAppWebViewInitialData(
        data: htmlContent,
        mimeType: 'text/html',
        encoding: 'utf-8',
        baseUrl: WebUri('file:///android_asset/'),
      ),
      initialSettings: InAppWebViewSettings(
        javaScriptEnabled: true,
        allowFileAccess: true,
        allowFileAccessFromFileURLs: true,
        allowUniversalAccessFromFileURLs: true,
        // مهم برای Angular routing:
        useHybridComposition: true,
      ),
      onWebViewCreated: (controller) {
        _controller = controller;
        // inject bridge
        controller.addJavaScriptHandler(
          handlerName: 'flutterBridge',
          callback: (args) async {
            // handle message
          },
        );
      },
    );
  }
}
```

### مرحله نهایی: Angular Build Configuration

برای اینکه Angular با این bridge کار کنه:

```typescript
// src/app/native-bridge.service.ts
declare global {
  interface Window {
    Native: {
      call: (options: {
        plugin: string;
        method: string;
        args?: Record<string, unknown>;
        timeout?: number;
      }) => Promise<unknown>;
      batch: (requests: Array<{plugin: string; method: string; args?: unknown}>) => Promise<unknown[]>;
      on: (event: string, callback: (data: unknown) => void) => () => void;
    };
    flutterBridge: {
      postMessage: (message: string) => void;
    };
  }
}

@Injectable({ providedIn: 'root' })
export class NativeBridgeService {
  call<T>(plugin: string, method: string, args?: Record<string, unknown>): Promise<T> {
    if (!window.Native) {
      return Promise.reject('Native bridge not available');
    }
    return window.Native.call({ plugin, method, args }) as Promise<T>;
  }
}
```

```bash
# Angular build برای production
ng build --configuration production \
  --output-path assets/web \
  --base-href ./ \
  --deploy-url ./
```

---

## خلاصه اقدامات فوری

```
۱. اضافه کردن permission_handler واقعی
۲. Fix کردن GeolocationPlugin.watchPosition
۳. Fix کردن StoragePlugin cache invalidation  
۴. اضافه کردن flutter_inappwebview
۵. اضافه کردن archive برای zip support
۶. Fix کردن AndroidManifest permissions
۷. پیاده‌سازی WebAppLoader service
۸. تست‌نویسی
```
