

# بازنویسی کامل پروژه - فاز ۱

---

## 📄 android/app/src/main/AndroidManifest.xml

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">

    <uses-permission android:name="android.permission.INTERNET"/>
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/>
    <uses-permission android:name="android.permission.CAMERA"/>
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
    <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>
    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
    <uses-permission android:name="android.permission.RECORD_AUDIO"/>
    <uses-permission android:name="android.permission.VIBRATE"/>

    <application
        android:label="sweetmelon"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher"
        android:usesCleartextTraffic="true"
        android:requestLegacyExternalStorage="true">

        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:launchMode="singleTop"
            android:taskAffinity=""
            android:theme="@style/LaunchTheme"
            android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
            android:hardwareAccelerated="true"
            android:windowSoftInputMode="adjustResize">
            <meta-data
                android:name="io.flutter.embedding.android.NormalTheme"
                android:resource="@style/NormalTheme"/>
            <intent-filter>
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.LAUNCHER"/>
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

    <queries>
        <intent>
            <action android:name="android.intent.action.PROCESS_TEXT"/>
            <data android:mimeType="text/plain"/>
        </intent>
    </queries>
</manifest>
```

---

## 📄 android/app/src/main/res/xml/file_paths.xml

```xml
<?xml version="1.0" encoding="utf-8"?>
<paths>
    <external-path name="external_files" path="."/>
    <cache-path name="cache" path="."/>
    <files-path name="files" path="."/>
</paths>
```

---

## 📄 android/app/src/main/kotlin/com/example/sweet_melon/MainActivity.kt

```kt
package com.example.sweet_melon

import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity()
```

---

## 📄 ios/Runner/Info.plist (بخش‌های اضافه شده)

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <!-- existing keys ... -->

    <key>NSCameraUsageDescription</key>
    <string>This app needs camera access to take photos.</string>
    <key>NSPhotoLibraryUsageDescription</key>
    <string>This app needs photo library access to pick images.</string>
    <key>NSLocationWhenInUseUsageDescription</key>
    <string>This app needs location access.</string>
    <key>NSLocationAlwaysUsageDescription</key>
    <string>This app needs location access in background.</string>
    <key>NSMicrophoneUsageDescription</key>
    <string>This app needs microphone access for video recording.</string>

    <key>NSAppTransportSecurity</key>
    <dict>
        <key>NSAllowsArbitraryLoads</key>
        <true/>
        <key>NSAllowsArbitraryLoadsInWebContent</key>
        <true/>
        <key>NSAllowsLocalNetworking</key>
        <true/>
    </dict>

    <key>io.flutter.embedded_views_preview</key>
    <true/>
</dict>
</plist>
```

---

## 📄 pubspec.yaml

```yaml
name: sweetmelon
description: Flutter Native Bridge - JS to Native communication platform
publish_to: 'none'

version: 1.0.0+1

environment:
  sdk: ^3.0.0

dependencies:
  flutter:
    sdk: flutter

  webview_flutter: ^4.8.0
  webview_flutter_android: ^3.16.0
  webview_flutter_wkwebview: ^3.13.0

  shared_preferences: ^2.2.2
  path_provider: ^2.1.1
  uuid: ^4.2.1
  get_it: ^7.6.4
  http: ^1.1.2
  image_picker: ^1.0.4
  geolocator: ^10.1.0
  permission_handler: ^11.3.0
  mime: ^1.0.5

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0

flutter:
  uses-material-design: true

  assets:
    - assets/www/
```

---

## 📄 lib/main.dart

```dart
import 'package:flutter/material.dart';
import 'app.dart';
import 'di/service_locator.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ServiceLocator.init();
  runApp(const BridgeApp());
}
```

---

## 📄 lib/app.dart

```dart
import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

class BridgeApp extends StatelessWidget {
  const BridgeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Native Bridge',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF6C63FF),
          secondary: Color(0xFF03DAC6),
        ),
        scaffoldBackgroundColor: const Color(0xFF0A0A1A),
      ),
      home: const HomeScreen(),
    );
  }
}
```

---

## 📄 lib/di/service_locator.dart

```dart
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';

import 'package:sweetmelon/packages/core/lib/core.dart';
import 'package:sweetmelon/packages/devtools/lib/devtools.dart';
import 'package:sweetmelon/packages/performance/lib/performance.dart';
import 'package:sweetmelon/packages/security/lib/security.dart';
import 'package:sweetmelon/plugins/storage/lib/storage_plugin.dart';
import 'package:sweetmelon/plugins/geolocation/lib/geolocation_plugin.dart';
import 'package:sweetmelon/plugins/camera/lib/camera_plugin.dart';
import 'package:sweetmelon/packages/plugin_engine/lib/plugin_engine.dart';

final sl = GetIt.instance;

class ServiceLocator {
  static bool _initializing = false;

  static Future<void> init() async {
    if (sl.isRegistered<MessageBridge>()) return;
    if (_initializing) return;
    _initializing = true;

    try {
      sl.registerLazySingleton<CacheManager>(
        () => CacheManager(maxEntries: 500),
      );

      sl.registerLazySingleton<RateLimiter>(() {
        final limiter = RateLimiter();
        limiter.setDefaultRule(RateLimitRule.perSecond(50));
        limiter.addRule(
          'geolocation.getCurrentPosition',
          RateLimitRule.perSecond(5),
        );
        limiter.addRule(
          'camera.takePhoto',
          RateLimitRule.perSecond(3),
        );
        return limiter;
      });

      sl.registerLazySingleton<ExecutionGuard>(
        () => ExecutionGuard(defaultTimeoutMs: 30000),
      );

      sl.registerLazySingleton<PermissionManager>(() {
        final manager = PermissionManager();

        manager.setProvider(
          NativePermissionProvider(
            fallbackStatus: kReleaseMode
                ? PermissionStatus.denied
                : PermissionStatus.granted,
          ),
        );

        manager.addPolicy(
          'camera',
          const PermissionPolicy(required: ['camera', 'storage']),
        );
        manager.addPolicy(
          'storage',
          const PermissionPolicy(required: ['storage']),
        );
        manager.addPolicy(
          'geolocation',
          const PermissionPolicy(required: ['location']),
        );

        return manager;
      });

      sl.registerLazySingleton<PluginRegistry>(
        () => PluginRegistry(),
      );

      sl.registerLazySingleton<PluginManager>(
        () => PluginManager(
          registry: sl<PluginRegistry>(),
          permissionManager: sl<PermissionManager>(),
          rateLimiter: sl<RateLimiter>(),
          executionGuard: sl<ExecutionGuard>(),
          cacheManager: sl<CacheManager>(),
        ),
      );

      sl.registerLazySingleton<MessageBridge>(() {
        final bridge = MessageBridge();
        final manager = sl<PluginManager>();

        bridge.setMessageHandler(manager.execute);
        bridge.setBatchHandler(manager.executeBatch);

        return bridge;
      });

      // اکنون MessageBridge ساخته شده، EventEmitter را ست کن
      final bridge = sl<MessageBridge>();
      sl<PluginRegistry>().setEventEmitter(bridge.emitEvent);

      sl.registerLazySingleton<WebViewHostConfig>(
        () => kReleaseMode
            ? WebViewHostConfig.production()
            : WebViewHostConfig.development(),
      );

      sl.registerLazySingleton<AssetServerConfig>(
        () => const AssetServerConfig(),
      );

      sl.registerLazySingleton<BridgeInspector>(
        () => BridgeInspector(
          bridge: bridge,
          manager: sl<PluginManager>(),
        ),
      );

      await _registerPlugins();
    } finally {
      _initializing = false;
    }
  }

  static Future<void> _registerPlugins() async {
    final registry = sl<PluginRegistry>();
    await registry.register(CameraPlugin());
    await registry.register(StoragePlugin());
    await registry.register(GeolocationPlugin(
      eventEmitter: sl<PluginRegistry>().emitEvent,
    ));
  }

  static Future<void> dispose() async {
    if (sl.isRegistered<BridgeInspector>()) {
      sl<BridgeInspector>().dispose();
    }
    if (sl.isRegistered<PluginManager>()) {
      sl<PluginManager>().dispose();
    }
    if (sl.isRegistered<PluginRegistry>()) {
      await sl<PluginRegistry>().dispose();
    }
    if (sl.isRegistered<CacheManager>()) {
      sl<CacheManager>().dispose();
    }
    if (sl.isRegistered<MessageBridge>()) {
      sl<MessageBridge>().dispose();
    }
    await sl.reset();
  }
}
```

---

## 📄 lib/packages/core/lib/core.dart

```dart
library core;

export 'src/bridge/message_bridge.dart';
export 'src/protocol/message_protocol.dart';
export 'src/runtime/webview_host.dart';
export 'src/runtime/asset_server.dart';
export 'src/utils/logger.dart';
```

---

## 📄 lib/packages/core/lib/src/bridge/message_bridge.dart

```dart
import 'dart:async';
import 'dart:convert';

import 'package:webview_flutter/webview_flutter.dart';

import '../protocol/message_protocol.dart';
import '../utils/logger.dart';

typedef MessageHandler = Future<PluginResponse> Function(PluginRequest request);
typedef BatchHandler = Future<List<PluginResponse>> Function(
  List<PluginRequest> requests,
  BatchOptions options,
);

class MessageBridge {
  WebViewController? _webViewController;
  MessageHandler? _messageHandler;
  BatchHandler? _batchHandler;

  final _messageStreamController =
      StreamController<BridgeMessage>.broadcast();

  Stream<BridgeMessage> get messageStream =>
      _messageStreamController.stream;

  bool _isReady = false;
  final List<String> _pendingJsMessages = [];
  static const int _maxPendingMessages = 200;

  bool _disposed = false;

  void setWebViewController(WebViewController controller) {
    _webViewController = controller;
  }

  void setMessageHandler(MessageHandler handler) {
    _messageHandler = handler;
  }

  void setBatchHandler(BatchHandler handler) {
    _batchHandler = handler;
  }

  /// وقتی صفحه جدید load می‌شود، bridge را reset کن
  void resetBridgeState() {
    _isReady = false;
    _pendingJsMessages.clear();
  }

  void onBridgeReady() {
    _isReady = true;
    BridgeLogger.info('Bridge', 'JS Bridge is ready, flushing ${_pendingJsMessages.length} pending messages');

    final messages = List<String>.from(_pendingJsMessages);
    _pendingJsMessages.clear();

    for (final message in messages) {
      _runJsDirect(message);
    }
  }

  WebViewController get _controller {
    if (_webViewController == null) {
      throw StateError('WebViewController not set');
    }
    return _webViewController!;
  }

  Future<void> handleIncomingMessage(Map<String, dynamic> json) async {
    if (_disposed) return;

    final startTime = DateTime.now();

    try {
      // تشخیص نوع پیام
      final type = json['type'] as String?;

      if (type == 'batch') {
        await _handleBatchRequest(json);
        return;
      }

      // بررسی فیلدهای ضروری قبل از parse
      if (!json.containsKey('plugin') || !json.containsKey('method')) {
        final requestId = json['requestId'] as String? ?? 'unknown';
        await _sendError(
          requestId,
          const PluginError(
            code: PluginErrorCode.invalidArgs,
            message: 'Missing required fields: plugin, method',
          ),
        );
        return;
      }

      final request = PluginRequest.fromJson(json);

      if (!_messageStreamController.isClosed) {
        _messageStreamController.add(BridgeMessage.incoming(request));
      }

      BridgeLogger.info(
        'Bridge',
        'Incoming: ${request.plugin}.${request.method} [${request.requestId}]',
      );

      if (_messageHandler == null) {
        await _sendError(
          request.requestId,
          const PluginError(
            code: PluginErrorCode.executionError,
            message: 'No message handler registered',
          ),
        );
        return;
      }

      final response = await _messageHandler!(request);

      final processingTime =
          DateTime.now().difference(startTime).inMilliseconds;

      final responseWithMeta = PluginResponse(
        requestId: response.requestId,
        timestamp: response.timestamp,
        success: response.success,
        data: response.data,
        error: response.error,
        metadata: ResponseMetadata(
          processingTimeMs: processingTime,
          pluginVersion: response.metadata.pluginVersion,
          fromCache: response.metadata.fromCache,
        ),
      );

      await _sendResponse(responseWithMeta);

      if (!_messageStreamController.isClosed) {
        _messageStreamController.add(BridgeMessage.outgoing(responseWithMeta));
      }
    } catch (e, stackTrace) {
      BridgeLogger.error('Bridge', 'Error handling message: $e');

      final requestId = json['requestId'] as String? ?? 'unknown';
      await _sendError(
        requestId,
        PluginError(
          code: PluginErrorCode.executionError,
          message: e.toString(),
          stackTrace: stackTrace.toString(),
        ),
      );
    }
  }

  Future<void> _handleBatchRequest(Map<String, dynamic> json) async {
    final batchId = json['batchId'] as String;
    final requestsJson = json['requests'] as List<dynamic>;
    final optionsJson = json['options'] as Map<String, dynamic>?;

    final requests = requestsJson
        .map((r) => PluginRequest.fromJson(r as Map<String, dynamic>))
        .toList();

    final options = optionsJson != null
        ? BatchOptions(
            parallel: optionsJson['parallel'] as bool? ?? true,
            stopOnError: optionsJson['stopOnError'] as bool? ?? false,
            timeoutMs: optionsJson['timeoutMs'] as int?,
          )
        : BatchOptions.defaults();

    BridgeLogger.info(
      'Bridge',
      'Batch request: $batchId (${requests.length} requests)',
    );

    List<PluginResponse> responses;

    if (_batchHandler != null) {
      responses = await _batchHandler!(requests, options);
    } else {
      responses = [];
      for (final request in requests) {
        if (_messageHandler != null) {
          try {
            final response = await _messageHandler!(request);
            responses.add(response);
            if (options.stopOnError && !response.success) break;
          } catch (e) {
            responses.add(
              PluginResponse.failure(
                requestId: request.requestId,
                error: PluginError(
                  code: PluginErrorCode.executionError,
                  message: e.toString(),
                ),
              ),
            );
            if (options.stopOnError) break;
          }
        }
      }
    }

    await _sendBatchResponse(batchId, responses);
  }

  Future<void> _sendResponse(PluginResponse response) async {
    final responseJson = jsonEncode(response.toJson());
    final escapedId = _escapeJsString(response.requestId);
    final js = 'window.__resolveCall("$escapedId", $responseJson);';
    await _runJs(js);
  }

  Future<void> _sendError(String requestId, PluginError error) async {
    final response = PluginResponse.failure(
      requestId: requestId,
      error: error,
    );
    await _sendResponse(response);
  }

  Future<void> _sendBatchResponse(
    String batchId,
    List<PluginResponse> responses,
  ) async {
    final escapedId = _escapeJsString(batchId);
    final resultsJson = jsonEncode({
      'results': responses.map((r) => r.toJson()).toList(),
    });
    final js = 'window.__resolveBatch("$escapedId", $resultsJson);';
    await _runJs(js);
  }

  Future<void> emitEvent(String event, dynamic data) async {
    if (_disposed) return;
    final escapedEvent = _escapeJsString(event);
    final dataJson = _sanitizeJsonForJs(jsonEncode(data));
    final js = 'window.__emitEvent("$escapedEvent", $dataJson);';
    await _runJs(js);
  }

  /// Sanitize JSON string for safe embedding in JS
  String _sanitizeJsonForJs(String json) {
    return json
        .replaceAll('</script>', '<\\/script>')
        .replaceAll('<!--', '<\\!--');
  }

  String _escapeJsString(String value) {
    return value
        .replaceAll('\\', '\\\\')
        .replaceAll('"', '\\"')
        .replaceAll("'", "\\'")
        .replaceAll('\n', '\\n')
        .replaceAll('\r', '\\r')
        .replaceAll('\t', '\\t');
  }

  Future<void> _runJs(String script) async {
    if (_disposed) return;

    if (!_isReady) {
      if (_pendingJsMessages.length >= _maxPendingMessages) {
        BridgeLogger.warn(
          'Bridge',
          'Pending message queue full (${_pendingJsMessages.length}), dropping oldest',
        );
        _pendingJsMessages.removeAt(0);
      }
      _pendingJsMessages.add(script);
      return;
    }
    await _runJsDirect(script);
  }

  Future<void> _runJsDirect(String script) async {
    try {
      await _controller.runJavaScript(script);
    } catch (e) {
      BridgeLogger.error('Bridge', 'JS execution error: $e');
    }
  }

  void dispose() {
    _disposed = true;
    _pendingJsMessages.clear();
    if (!_messageStreamController.isClosed) {
      _messageStreamController.close();
    }
  }
}

enum BridgeMessageDirection { incoming, outgoing }

class BridgeMessage {
  final BridgeMessageDirection direction;
  final BaseMessage message;
  final DateTime timestamp;

  const BridgeMessage({
    required this.direction,
    required this.message,
    required this.timestamp,
  });

  factory BridgeMessage.incoming(BaseMessage message) => BridgeMessage(
        direction: BridgeMessageDirection.incoming,
        message: message,
        timestamp: DateTime.now(),
      );

  factory BridgeMessage.outgoing(BaseMessage message) => BridgeMessage(
        direction: BridgeMessageDirection.outgoing,
        message: message,
        timestamp: DateTime.now(),
      );
}
```

---

## 📄 lib/packages/core/lib/src/protocol/message_protocol.dart

```dart
import 'dart:convert';

import 'package:uuid/uuid.dart';

abstract class BaseMessage {
  final String requestId;
  final DateTime timestamp;

  const BaseMessage({
    required this.requestId,
    required this.timestamp,
  });

  Map<String, dynamic> toJson();
}

class PluginRequest extends BaseMessage {
  final String plugin;
  final String version;
  final String method;
  final Map<String, dynamic> args;
  final RequestMetadata metadata;

  const PluginRequest({
    required super.requestId,
    required super.timestamp,
    required this.plugin,
    required this.version,
    required this.method,
    required this.args,
    required this.metadata,
  });

  factory PluginRequest.create({
    required String plugin,
    required String method,
    Map<String, dynamic>? args,
    String version = '1.0.0',
  }) {
    return PluginRequest(
      requestId: const Uuid().v4(),
      timestamp: DateTime.now(),
      plugin: plugin,
      version: version,
      method: method,
      args: args ?? {},
      metadata: RequestMetadata.defaults(),
    );
  }

  factory PluginRequest.fromJson(Map<String, dynamic> json) {
    return PluginRequest(
      requestId: json['requestId'] as String? ??
          const Uuid().v4(),
      timestamp: DateTime.tryParse(
            json['timestamp'] as String? ?? '',
          ) ??
          DateTime.now(),
      plugin: json['plugin'] as String,
      version: json['version'] as String? ?? '1.0.0',
      method: json['method'] as String,
      args: (json['args'] as Map<String, dynamic>?) ?? {},
      metadata: json['metadata'] != null
          ? RequestMetadata.fromJson(
              json['metadata'] as Map<String, dynamic>,
            )
          : RequestMetadata.defaults(),
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'requestId': requestId,
        'timestamp': timestamp.toIso8601String(),
        'plugin': plugin,
        'version': version,
        'method': method,
        'args': args,
        'metadata': metadata.toJson(),
      };

  @override
  String toString() => jsonEncode(toJson());
}

class PluginResponse extends BaseMessage {
  final bool success;
  final dynamic data;
  final PluginError? error;
  final ResponseMetadata metadata;

  const PluginResponse({
    required super.requestId,
    required super.timestamp,
    required this.success,
    this.data,
    this.error,
    required this.metadata,
  });

  factory PluginResponse.success({
    required String requestId,
    required dynamic data,
    ResponseMetadata? metadata,
  }) {
    return PluginResponse(
      requestId: requestId,
      timestamp: DateTime.now(),
      success: true,
      data: data,
      metadata: metadata ?? ResponseMetadata.defaults(),
    );
  }

  factory PluginResponse.failure({
    required String requestId,
    required PluginError error,
    ResponseMetadata? metadata,
  }) {
    return PluginResponse(
      requestId: requestId,
      timestamp: DateTime.now(),
      success: false,
      error: error,
      metadata: metadata ?? ResponseMetadata.defaults(),
    );
  }

  factory PluginResponse.fromJson(Map<String, dynamic> json) {
    return PluginResponse(
      requestId: json['requestId'] as String,
      timestamp: DateTime.tryParse(
            json['timestamp'] as String? ?? '',
          ) ??
          DateTime.now(),
      success: json['success'] as bool? ?? false,
      data: json['data'],
      error: json['error'] != null
          ? PluginError.fromJson(json['error'] as Map<String, dynamic>)
          : null,
      metadata: json['metadata'] != null
          ? ResponseMetadata.fromJson(
              json['metadata'] as Map<String, dynamic>,
            )
          : ResponseMetadata.defaults(),
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'requestId': requestId,
        'timestamp': timestamp.toIso8601String(),
        'success': success,
        if (data != null) 'data': data,
        if (error != null) 'error': error!.toJson(),
        'metadata': metadata.toJson(),
      };
}

enum PluginErrorCode {
  permissionDenied('PERMISSION_DENIED'),
  pluginNotFound('PLUGIN_NOT_FOUND'),
  methodNotFound('METHOD_NOT_FOUND'),
  invalidArgs('INVALID_ARGS'),
  timeout('TIMEOUT'),
  rateLimitExceeded('RATE_LIMIT_EXCEEDED'),
  executionError('EXECUTION_ERROR'),
  sandboxViolation('SANDBOX_VIOLATION'),
  networkError('NETWORK_ERROR'),
  unknown('UNKNOWN');

  final String code;
  const PluginErrorCode(this.code);

  static PluginErrorCode fromString(String code) {
    return PluginErrorCode.values.firstWhere(
      (e) => e.code == code,
      orElse: () => PluginErrorCode.unknown,
    );
  }
}

class PluginError {
  final PluginErrorCode code;
  final String message;
  final Map<String, dynamic>? details;
  final String? stackTrace;

  const PluginError({
    required this.code,
    required this.message,
    this.details,
    this.stackTrace,
  });

  factory PluginError.fromJson(Map<String, dynamic> json) {
    return PluginError(
      code: PluginErrorCode.fromString(json['code'] as String? ?? 'UNKNOWN'),
      message: json['message'] as String? ?? 'Unknown error',
      details: json['details'] as Map<String, dynamic>?,
      stackTrace: json['stackTrace'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'code': code.code,
        'message': message,
        if (details != null) 'details': details,
        if (stackTrace != null) 'stackTrace': stackTrace,
      };
}

class RequestMetadata {
  final String? sessionId;
  final String? userId;
  final Map<String, String> headers;

  const RequestMetadata({
    this.sessionId,
    this.userId,
    required this.headers,
  });

  factory RequestMetadata.defaults() => const RequestMetadata(headers: {});

  factory RequestMetadata.fromJson(Map<String, dynamic> json) {
    return RequestMetadata(
      sessionId: json['sessionId'] as String?,
      userId: json['userId'] as String?,
      headers: Map<String, String>.from(
        (json['headers'] as Map<String, dynamic>?) ?? {},
      ),
    );
  }

  Map<String, dynamic> toJson() => {
        if (sessionId != null) 'sessionId': sessionId,
        if (userId != null) 'userId': userId,
        'headers': headers,
      };
}

class ResponseMetadata {
  final int processingTimeMs;
  final String? pluginVersion;
  final bool fromCache;

  const ResponseMetadata({
    required this.processingTimeMs,
    this.pluginVersion,
    required this.fromCache,
  });

  factory ResponseMetadata.defaults() => const ResponseMetadata(
        processingTimeMs: 0,
        fromCache: false,
      );

  factory ResponseMetadata.fromJson(Map<String, dynamic> json) {
    return ResponseMetadata(
      processingTimeMs: json['processingTimeMs'] as int? ?? 0,
      pluginVersion: json['pluginVersion'] as String?,
      fromCache: json['fromCache'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'processingTimeMs': processingTimeMs,
        if (pluginVersion != null) 'pluginVersion': pluginVersion,
        'fromCache': fromCache,
      };
}

class BatchRequest {
  final String batchId;
  final List<PluginRequest> requests;
  final BatchOptions options;

  const BatchRequest({
    required this.batchId,
    required this.requests,
    required this.options,
  });

  factory BatchRequest.create(List<PluginRequest> requests) {
    return BatchRequest(
      batchId: const Uuid().v4(),
      requests: requests,
      options: BatchOptions.defaults(),
    );
  }

  Map<String, dynamic> toJson() => {
        'batchId': batchId,
        'requests': requests.map((r) => r.toJson()).toList(),
        'options': options.toJson(),
      };
}

class BatchOptions {
  final bool parallel;
  final bool stopOnError;
  final int? timeoutMs;

  const BatchOptions({
    required this.parallel,
    required this.stopOnError,
    this.timeoutMs,
  });

  factory BatchOptions.defaults() => const BatchOptions(
        parallel: true,
        stopOnError: false,
      );

  Map<String, dynamic> toJson() => {
        'parallel': parallel,
        'stopOnError': stopOnError,
        if (timeoutMs != null) 'timeoutMs': timeoutMs,
      };
}
```

---

## 📄 lib/packages/core/lib/src/utils/logger.dart

```dart
import 'dart:async';

import 'package:flutter/foundation.dart';

enum LogLevel {
  debug(0, 'DEBUG'),
  info(1, 'INFO'),
  warn(2, 'WARN'),
  error(3, 'ERROR');

  final int value;
  final String label;
  const LogLevel(this.value, this.label);
}

class LogEntry {
  final LogLevel level;
  final String tag;
  final String message;
  final DateTime timestamp;
  final Map<String, dynamic>? extra;

  const LogEntry({
    required this.level,
    required this.tag,
    required this.message,
    required this.timestamp,
    this.extra,
  });

  Map<String, dynamic> toJson() => {
        'level': level.name,
        'tag': tag,
        'message': message,
        'timestamp': timestamp.toIso8601String(),
        if (extra != null) 'extra': extra,
      };

  @override
  String toString() {
    final time = '${timestamp.hour.toString().padLeft(2, '0')}:'
        '${timestamp.minute.toString().padLeft(2, '0')}:'
        '${timestamp.second.toString().padLeft(2, '0')}.'
        '${timestamp.millisecond.toString().padLeft(3, '0')}';

    return '[${level.label}] [$tag] $time - $message';
  }
}

class BridgeLogger {
  static LogLevel _minLevel = kReleaseMode ? LogLevel.warn : LogLevel.debug;
  static final List<LogEntry> _history = [];
  static StreamController<LogEntry>? _controller;
  static final List<LogSink> _sinks = [
    if (kDebugMode) DebugConsoleSink(),
  ];

  static StreamController<LogEntry> get _streamController {
    _controller ??= StreamController<LogEntry>.broadcast();
    return _controller!;
  }

  static Stream<LogEntry> get stream => _streamController.stream;
  static List<LogEntry> get history => List.unmodifiable(_history);

  static void setMinLevel(LogLevel level) => _minLevel = level;

  static void addSink(LogSink sink) {
    if (!_sinks.contains(sink)) {
      _sinks.add(sink);
    }
  }

  static void removeSink(LogSink sink) => _sinks.remove(sink);

  static void debug(String tag, String message,
      [Map<String, dynamic>? extra]) {
    _log(LogLevel.debug, tag, message, extra);
  }

  static void info(String tag, String message,
      [Map<String, dynamic>? extra]) {
    _log(LogLevel.info, tag, message, extra);
  }

  static void warn(String tag, String message,
      [Map<String, dynamic>? extra]) {
    _log(LogLevel.warn, tag, message, extra);
  }

  static void error(String tag, String message,
      [Map<String, dynamic>? extra]) {
    _log(LogLevel.error, tag, message, extra);
  }

  static void _log(
    LogLevel level,
    String tag,
    String message,
    Map<String, dynamic>? extra,
  ) {
    if (level.value < _minLevel.value) return;

    final entry = LogEntry(
      level: level,
      tag: tag,
      message: message,
      timestamp: DateTime.now(),
      extra: extra,
    );

    _history.add(entry);
    if (_history.length > 1000) _history.removeAt(0);

    if (_controller != null && !_controller!.isClosed) {
      _controller!.add(entry);
    }

    for (final sink in _sinks) {
      try {
        sink.write(entry);
      } catch (_) {
        // Sink error should never crash the app
      }
    }
  }

  static void clear() => _history.clear();

  static void dispose() {
    _controller?.close();
    _controller = null;
  }
}

abstract class LogSink {
  void write(LogEntry entry);
}

/// استفاده از debugPrint به جای print
class DebugConsoleSink implements LogSink {
  @override
  void write(LogEntry entry) {
    debugPrint(entry.toString());
  }
}

class MemorySink implements LogSink {
  final List<LogEntry> entries = [];
  final int maxEntries;

  MemorySink({this.maxEntries = 500});

  @override
  void write(LogEntry entry) {
    entries.add(entry);
    if (entries.length > maxEntries) entries.removeAt(0);
  }
}
```

---

## 📄 lib/packages/core/lib/src/runtime/asset_server.dart

```dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:mime/mime.dart';
import 'package:path_provider/path_provider.dart';

import '../utils/logger.dart';

/// تنظیمات مسیر assets و www
class AssetServerConfig {
  /// مسیر ثابت index.html: assets/www/index.html
  static const String wwwRoot = 'assets/www';

  /// مسیر index.html نسبت به wwwRoot
  final String indexFile;

  /// پسوندهای مجاز برای serve کردن
  final Set<String> allowedExtensions;

  /// حداکثر سایز فایل (bytes)
  final int maxFileSize;

  const AssetServerConfig({
    this.indexFile = 'index.html',
    this.allowedExtensions = const {
      '.html', '.htm', '.css', '.js', '.json', '.xml',
      '.png', '.jpg', '.jpeg', '.gif', '.svg', '.ico', '.webp',
      '.woff', '.woff2', '.ttf', '.eot', '.otf',
      '.mp3', '.mp4', '.wav', '.ogg', '.webm',
      '.map', '.txt', '.csv', '.pdf',
    },
    this.maxFileSize = 50 * 1024 * 1024, // 50MB
  });
}

/// Local HTTP server for serving asset files to WebView
class AssetServer {
  final AssetServerConfig config;
  HttpServer? _server;
  String? _extractedPath;
  int? _port;
  bool _running = false;

  AssetServer({required this.config});

  /// پورت سرور
  int get port => _port ?? 0;

  /// آدرس پایه سرور
  String get baseUrl => 'http://localhost:$_port';

  /// آیا سرور اجرا می‌شود
  bool get isRunning => _running;

  /// آدرس index.html
  String get indexUrl => '$baseUrl/${config.indexFile}';

  /// شروع سرور: assets را extract و HTTP server را start کن
  Future<String> start() async {
    if (_running) return indexUrl;

    // مرحله ۱: extract کردن assets/www به filesystem
    _extractedPath = await _extractAssets();

    // مرحله ۲: شروع HTTP server
    _server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    _port = _server!.port;
    _running = true;

    BridgeLogger.info('AssetServer', 'Started on port $_port');
    BridgeLogger.info('AssetServer', 'Serving from: $_extractedPath');
    BridgeLogger.info('AssetServer', 'Index URL: $indexUrl');

    // Handle requests
    _server!.listen(
      _handleRequest,
      onError: (error) {
        BridgeLogger.error('AssetServer', 'Server error: $error');
      },
    );

    return indexUrl;
  }

  /// Extract assets/www/* to app's temporary directory
  Future<String> _extractAssets() async {
    final tempDir = await getTemporaryDirectory();
    final wwwDir = Directory('${tempDir.path}/www_server');

    // پاک کردن دایرکتوری قبلی
    if (await wwwDir.exists()) {
      await wwwDir.delete(recursive: true);
    }
    await wwwDir.create(recursive: true);

    // خواندن manifest برای پیدا کردن همه assets
    final manifestContent = await rootBundle.loadString('AssetManifest.json');
    final manifest = jsonDecode(manifestContent) as Map<String, dynamic>;

    int fileCount = 0;

    for (final assetKey in manifest.keys) {
      // فقط فایل‌هایی که در assets/www/ هستند
      if (!assetKey.startsWith(AssetServerConfig.wwwRoot)) continue;

      // مسیر نسبی بعد از assets/www/
      final relativePath =
          assetKey.substring('${AssetServerConfig.wwwRoot}/'.length);

      if (relativePath.isEmpty) continue;

      // بررسی پسوند مجاز
      final ext = _getExtension(relativePath);
      if (!config.allowedExtensions.contains(ext)) {
        BridgeLogger.warn(
          'AssetServer',
          'Skipping disallowed file type: $relativePath ($ext)',
        );
        continue;
      }

      try {
        final data = await rootBundle.load(assetKey);
        final targetFile = File('${wwwDir.path}/$relativePath');

        // ساخت پوشه‌های والد
        await targetFile.parent.create(recursive: true);

        // نوشتن فایل
        await targetFile.writeAsBytes(
          data.buffer.asUint8List(),
          flush: true,
        );
        fileCount++;
      } catch (e) {
        BridgeLogger.error(
          'AssetServer',
          'Failed to extract: $relativePath — $e',
        );
      }
    }

    BridgeLogger.info(
      'AssetServer',
      'Extracted $fileCount files to ${wwwDir.path}',
    );

    return wwwDir.path;
  }

  /// Handle incoming HTTP request
  Future<void> _handleRequest(HttpRequest request) async {
    if (_extractedPath == null) {
      request.response
        ..statusCode = HttpStatus.serviceUnavailable
        ..write('Server not ready')
        ..close();
      return;
    }

    // CORS headers
    request.response.headers
      ..set('Access-Control-Allow-Origin', '*')
      ..set('Access-Control-Allow-Methods', 'GET, HEAD, OPTIONS')
      ..set('Access-Control-Allow-Headers', '*')
      ..set('Cache-Control', 'no-cache');

    // OPTIONS request
    if (request.method == 'OPTIONS') {
      request.response
        ..statusCode = HttpStatus.ok
        ..close();
      return;
    }

    // فقط GET و HEAD
    if (request.method != 'GET' && request.method != 'HEAD') {
      request.response
        ..statusCode = HttpStatus.methodNotAllowed
        ..write('Method not allowed')
        ..close();
      return;
    }

    var requestPath = Uri.decodeFull(request.uri.path);
    if (requestPath.startsWith('/')) {
      requestPath = requestPath.substring(1);
    }

    // مسیر خالی → index.html
    if (requestPath.isEmpty) {
      requestPath = config.indexFile;
    }

    // جلوگیری از path traversal
    if (requestPath.contains('..') || requestPath.contains('~')) {
      BridgeLogger.warn(
        'AssetServer',
        'Path traversal attempt blocked: $requestPath',
      );
      request.response
        ..statusCode = HttpStatus.forbidden
        ..write('Forbidden')
        ..close();
      return;
    }

    final filePath = '$_extractedPath/$requestPath';
    final file = File(filePath);

    // بررسی وجود فایل
    if (!await file.exists()) {
      // SPA fallback: اگه فایل نیست، index.html رو برگردون
      final indexPath = '$_extractedPath/${config.indexFile}';
      final indexFile = File(indexPath);

      if (await indexFile.exists()) {
        BridgeLogger.debug(
          'AssetServer',
          'SPA fallback for: $requestPath → ${config.indexFile}',
        );
        await _serveFile(request, indexFile, 'text/html');
      } else {
        request.response
          ..statusCode = HttpStatus.notFound
          ..write('Not Found: $requestPath')
          ..close();
      }
      return;
    }

    // بررسی سایز
    final stat = await file.stat();
    if (stat.size > config.maxFileSize) {
      request.response
        ..statusCode = HttpStatus.requestEntityTooLarge
        ..write('File too large')
        ..close();
      return;
    }

    // تعیین MIME type
    final mimeType = _getMimeType(requestPath);

    await _serveFile(request, file, mimeType);
  }

  Future<void> _serveFile(
    HttpRequest request,
    File file,
    String mimeType,
  ) async {
    try {
      final bytes = await file.readAsBytes();

      request.response
        ..statusCode = HttpStatus.ok
        ..headers.contentType = ContentType.parse(mimeType)
        ..contentLength = bytes.length;

      if (request.method == 'GET') {
        request.response.add(bytes);
      }

      await request.response.close();
    } catch (e) {
      BridgeLogger.error('AssetServer', 'Error serving file: $e');
      request.response
        ..statusCode = HttpStatus.internalServerError
        ..write('Internal Server Error')
        ..close();
    }
  }

  String _getMimeType(String path) {
    final mimeType = lookupMimeType(path);
    if (mimeType != null) return mimeType;

    // Fallback for common types
    final ext = _getExtension(path);
    switch (ext) {
      case '.js':
        return 'application/javascript';
      case '.mjs':
        return 'application/javascript';
      case '.css':
        return 'text/css';
      case '.html':
      case '.htm':
        return 'text/html';
      case '.json':
        return 'application/json';
      case '.svg':
        return 'image/svg+xml';
      case '.woff':
        return 'font/woff';
      case '.woff2':
        return 'font/woff2';
      case '.ttf':
        return 'font/ttf';
      case '.map':
        return 'application/json';
      default:
        return 'application/octet-stream';
    }
  }

  String _getExtension(String path) {
    final lastDot = path.lastIndexOf('.');
    if (lastDot == -1) return '';
    return path.substring(lastDot).toLowerCase();
  }

  /// متوقف کردن سرور
  Future<void> stop() async {
    if (!_running) return;

    await _server?.close(force: true);
    _server = null;
    _port = null;
    _running = false;

    // پاک کردن فایل‌های extract شده
    if (_extractedPath != null) {
      try {
        final dir = Directory(_extractedPath!);
        if (await dir.exists()) {
          await dir.delete(recursive: true);
        }
      } catch (e) {
        BridgeLogger.warn('AssetServer', 'Cleanup error: $e');
      }
      _extractedPath = null;
    }

    BridgeLogger.info('AssetServer', 'Server stopped');
  }
}
```

---

## 📄 lib/packages/core/lib/src/runtime/webview_host.dart

```dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../bridge/message_bridge.dart';
import '../utils/logger.dart';
import 'asset_server.dart';

class WebViewHost extends StatefulWidget {
  /// بارگذاری از URL خارجی
  final String? initialUrl;

  /// بارگذاری HTML inline
  final String? initialHtml;

  /// بارگذاری از assets/www/ با local HTTP server
  final bool loadFromAssets;

  final WebViewHostConfig config;
  final AssetServerConfig assetConfig;
  final MessageBridge bridge;
  final VoidCallback? onPageLoaded;
  final Function(String error)? onError;

  const WebViewHost({
    super.key,
    this.initialUrl,
    this.initialHtml,
    this.loadFromAssets = false,
    required this.config,
    required this.assetConfig,
    required this.bridge,
    this.onPageLoaded,
    this.onError,
  });

  @override
  State<WebViewHost> createState() => _WebViewHostState();
}

class _WebViewHostState extends State<WebViewHost> with WidgetsBindingObserver {
  late final WebViewController _controller;
  AssetServer? _assetServer;
  bool _isReady = false;
  bool _bridgeInjected = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initController();
    _loadContent();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _assetServer?.stop();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      // WebView pause
    } else if (state == AppLifecycleState.resumed) {
      // WebView resume
    }
  }

  void _initController() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(_buildNavigationDelegate())
      ..addJavaScriptChannel(
        'flutterBridge',
        onMessageReceived: _onJsMessage,
      )
      ..addJavaScriptChannel(
        '__bridgeInternal',
        onMessageReceived: _onInternalMessage,
      )
      ..setBackgroundColor(const Color(0xFF0A0A1A));

    // Apply config
    if (widget.config.enableDebugging) {
      // Android debugging
      // WebViewController اجازه setWebContentsDebuggingEnabled رو نمی‌ده مستقیم
      // ولی از طریق platform specific settings قابل تنظیمه
    }

    widget.bridge.setWebViewController(_controller);
  }

  Future<void> _loadContent() async {
    try {
      if (widget.loadFromAssets) {
        await _loadFromAssetServer();
      } else if (widget.initialHtml != null) {
        await _controller.loadHtmlString(widget.initialHtml!);
      } else if (widget.initialUrl != null &&
          widget.initialUrl!.isNotEmpty) {
        await _controller.loadRequest(Uri.parse(widget.initialUrl!));
      }
    } catch (e) {
      BridgeLogger.error('WebView', 'Failed to load content: $e');
      if (mounted) {
        setState(() => _loadError = e.toString());
      }
      widget.onError?.call(e.toString());
    }
  }

  /// شروع AssetServer و load کردن index.html
  Future<void> _loadFromAssetServer() async {
    BridgeLogger.info('WebView', 'Starting asset server...');

    _assetServer = AssetServer(config: widget.assetConfig);
    final url = await _assetServer!.start();

    BridgeLogger.info('WebView', 'Loading from: $url');
    await _controller.loadRequest(Uri.parse(url));
  }

  NavigationDelegate _buildNavigationDelegate() {
    return NavigationDelegate(
      onPageStarted: (url) {
        BridgeLogger.info('WebView', 'Page started: $url');

        // Reset bridge state وقتی صفحه جدید load می‌شود
        widget.bridge.resetBridgeState();
        _bridgeInjected = false;

        if (mounted) {
          setState(() {
            _isReady = false;
            _loadError = null;
          });
        }
      },
      onPageFinished: (url) async {
        BridgeLogger.info('WebView', 'Page finished: $url');
        await _injectBridgeScript();
        if (mounted) {
          setState(() => _isReady = true);
        }
        widget.onPageLoaded?.call();
      },
      onWebResourceError: (error) {
        BridgeLogger.error(
          'WebView',
          'Resource error [${error.errorCode}]: ${error.description}',
        );
        // فقط main frame error رو نشون بده
        if (error.isForMainFrame ?? false) {
          if (mounted) {
            setState(() => _loadError = error.description);
          }
          widget.onError?.call(error.description);
        }
      },
      onNavigationRequest: (request) {
        final uri = Uri.tryParse(request.url);

        // اجازه localhost (asset server)
        if (uri != null && uri.host == 'localhost') {
          return NavigationDecision.navigate;
        }

        // اجازه file URIs
        if (uri != null && uri.scheme == 'file') {
          return NavigationDecision.navigate;
        }

        // اجازه data URIs
        if (uri != null && uri.scheme == 'data') {
          return NavigationDecision.navigate;
        }

        // اجازه about:blank
        if (request.url == 'about:blank') {
          return NavigationDecision.navigate;
        }

        // بررسی allowed hosts
        if (widget.config.allowedHosts.isNotEmpty) {
          if (uri != null &&
              uri.host.isNotEmpty &&
              !widget.config.allowedHosts.contains(uri.host) &&
              uri.host != 'localhost') {
            BridgeLogger.warn(
              'WebView',
              'Blocked navigation to: ${request.url}',
            );
            return NavigationDecision.prevent;
          }
        }

        return NavigationDecision.navigate;
      },
    );
  }

  Future<void> _injectBridgeScript() async {
    if (_bridgeInjected) return;
    _bridgeInjected = true;

    const script = r'''
      (function() {
        'use strict';
        if (window.__NativeBridgeInitialized) return;
        window.__NativeBridgeInitialized = true;
        
        window.__pending = {};
        window.__eventListeners = {};
        window.__requestCount = 0;
        
        function generateId() {
          if (typeof crypto !== 'undefined' && crypto.randomUUID) {
            return crypto.randomUUID();
          }
          return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(
            /[xy]/g,
            function(c) {
              var r = Math.random() * 16 | 0;
              var v = c === 'x' ? r : (r & 0x3 | 0x8);
              return v.toString(16);
            }
          );
        }
        
        window.Native = {
          call: function(options) {
            var plugin = options.plugin;
            var method = options.method;
            var args = options.args || {};
            var version = options.version || '1.0.0';
            var timeout = options.timeout != null ? options.timeout : 30000;

            return new Promise(function(resolve, reject) {
              var id = generateId();
              var timeoutHandle = null;
              
              if (timeout > 0) {
                timeoutHandle = setTimeout(function() {
                  if (window.__pending[id]) {
                    delete window.__pending[id];
                    reject({
                      code: 'TIMEOUT',
                      message: 'Request timed out after ' + timeout + 'ms',
                      requestId: id
                    });
                  }
                }, timeout);
              }
              
              window.__pending[id] = {
                resolve: function(data) {
                  if (timeoutHandle) clearTimeout(timeoutHandle);
                  resolve(data);
                },
                reject: function(error) {
                  if (timeoutHandle) clearTimeout(timeoutHandle);
                  reject(error);
                }
              };
              
              var message = JSON.stringify({
                requestId: id,
                plugin: plugin,
                version: version,
                method: method,
                args: args,
                timestamp: new Date().toISOString(),
                metadata: { headers: {} }
              });
              
              try {
                window.flutterBridge.postMessage(message);
                window.__requestCount++;
              } catch (e) {
                delete window.__pending[id];
                if (timeoutHandle) clearTimeout(timeoutHandle);
                reject({
                  code: 'BRIDGE_ERROR',
                  message: 'Failed to send message: ' + e.message
                });
              }
            });
          },

          batch: function(requests, options) {
            options = options || {};
            var batchId = generateId();

            var mappedRequests = requests.map(function(r) {
              return {
                requestId: generateId(),
                plugin: r.plugin,
                method: r.method,
                args: r.args || {},
                version: r.version || '1.0.0',
                timestamp: new Date().toISOString(),
                metadata: { headers: {} }
              };
            });

            var timeout = options.timeout || 60000;

            return new Promise(function(resolve, reject) {
              var timeoutHandle = setTimeout(function() {
                if (window.__pending[batchId]) {
                  delete window.__pending[batchId];
                  reject({
                    code: 'TIMEOUT',
                    message: 'Batch request timed out'
                  });
                }
              }, timeout);

              window.__pending[batchId] = {
                resolve: function(data) {
                  clearTimeout(timeoutHandle);
                  resolve(data);
                },
                reject: function(error) {
                  clearTimeout(timeoutHandle);
                  reject(error);
                }
              };

              var batchMessage = JSON.stringify({
                type: 'batch',
                batchId: batchId,
                requests: mappedRequests,
                options: {
                  parallel: options.parallel !== false,
                  stopOnError: options.stopOnError || false,
                  timeoutMs: options.timeout
                }
              });

              try {
                window.flutterBridge.postMessage(batchMessage);
              } catch (e) {
                delete window.__pending[batchId];
                clearTimeout(timeoutHandle);
                reject({
                  code: 'BRIDGE_ERROR',
                  message: 'Failed to send batch: ' + e.message
                });
              }
            });
          },

          on: function(event, callback) {
            if (!window.__eventListeners[event]) {
              window.__eventListeners[event] = [];
            }
            window.__eventListeners[event].push(callback);

            return function() {
              window.Native.off(event, callback);
            };
          },

          off: function(event, callback) {
            if (!window.__eventListeners[event]) return;
            window.__eventListeners[event] = 
              window.__eventListeners[event].filter(function(cb) {
                return cb !== callback;
              });
          },
          
          info: function() {
            return {
              initialized: true,
              pendingRequests: Object.keys(window.__pending).length,
              totalRequests: window.__requestCount,
              version: '1.0.0'
            };
          },

          ready: function() {
            return new Promise(function(resolve) {
              if (window.__NativeBridgeInitialized) {
                resolve(window.Native.info());
              } else {
                var check = setInterval(function() {
                  if (window.__NativeBridgeInitialized) {
                    clearInterval(check);
                    resolve(window.Native.info());
                  }
                }, 50);
                setTimeout(function() {
                  clearInterval(check);
                  resolve(null);
                }, 5000);
              }
            });
          }
        };
        
        window.__resolveCall = function(requestId, responseJson) {
          var response;
          try {
            response = typeof responseJson === 'string' 
              ? JSON.parse(responseJson) 
              : responseJson;
          } catch (e) {
            console.error('[Bridge] Failed to parse response:', e);
            return;
          }
            
          var pending = window.__pending[requestId];
          
          if (!pending) {
            console.warn('[Bridge] No pending request for:', requestId);
            return;
          }
          
          delete window.__pending[requestId];
          
          if (response.success) {
            pending.resolve(response.data);
          } else {
            pending.reject(response.error || {
              code: 'UNKNOWN',
              message: 'Unknown error'
            });
          }
        };
        
        window.__resolveBatch = function(batchId, responseJson) {
          var response;
          try {
            response = typeof responseJson === 'string'
              ? JSON.parse(responseJson)
              : responseJson;
          } catch (e) {
            console.error('[Bridge] Failed to parse batch response:', e);
            return;
          }
            
          var pending = window.__pending[batchId];
          if (!pending) return;
          
          delete window.__pending[batchId];
          pending.resolve(response.results);
        };
        
        window.__emitEvent = function(event, dataJson) {
          var data;
          try {
            data = typeof dataJson === 'string'
              ? JSON.parse(dataJson)
              : dataJson;
          } catch (e) {
            console.error('[Bridge] Failed to parse event data:', e);
            return;
          }
            
          var listeners = window.__eventListeners[event] || [];
          listeners.forEach(function(cb) {
            try {
              cb(data);
            } catch (e) {
              console.error('[Bridge] Event listener error:', e);
            }
          });
        };

        window.__bridgeDebug = {
          getPending: function() { return Object.keys(window.__pending); },
          getStats: function() {
            return {
              pending: Object.keys(window.__pending).length,
              total: window.__requestCount,
              listeners: Object.keys(window.__eventListeners)
            };
          },
          clearPending: function() {
            var ids = Object.keys(window.__pending);
            ids.forEach(function(id) {
              if (window.__pending[id] && window.__pending[id].reject) {
                window.__pending[id].reject({
                  code: 'CLEARED',
                  message: 'Pending request cleared manually'
                });
              }
            });
            window.__pending = {};
          }
        };
        
        try {
          window.__bridgeInternal.postMessage(JSON.stringify({
            type: 'bridge_ready',
            timestamp: new Date().toISOString()
          }));
        } catch (e) {
          console.error('[Bridge] Failed to signal ready:', e);
        }
        
        console.log('[NativeBridge] SDK initialized successfully');
      })();
    ''';

    try {
      await _controller.runJavaScript(script);
      BridgeLogger.info('WebView', 'Bridge script injected');
    } catch (e) {
      BridgeLogger.error('WebView', 'Failed to inject bridge script: $e');
    }
  }

  void _onJsMessage(JavaScriptMessage message) {
    try {
      final json = jsonDecode(message.message) as Map<String, dynamic>;
      widget.bridge.handleIncomingMessage(json);
    } catch (e) {
      BridgeLogger.error('WebView', 'Failed to parse JS message: $e');
    }
  }

  void _onInternalMessage(JavaScriptMessage message) {
    try {
      final json = jsonDecode(message.message) as Map<String, dynamic>;
      if (json['type'] == 'bridge_ready') {
        BridgeLogger.info('WebView', 'JS Bridge is ready');
        widget.bridge.onBridgeReady();
      }
    } catch (e) {
      BridgeLogger.error('WebView', 'Internal message error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        WebViewWidget(controller: _controller),

        // Loading overlay
        if (!_isReady && _loadError == null)
          Container(
            color: const Color(0xFF0A0A1A),
            child: const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(
                    color: Color(0xFF6C63FF),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Loading...',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),

        // Error overlay
        if (_loadError != null)
          Container(
            color: const Color(0xFF0A0A1A),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.redAccent,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Failed to load',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _loadError!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        setState(() => _loadError = null);
                        _loadContent();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6C63FF),
                      ),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class WebViewHostConfig {
  final bool enableDebugging;
  final bool allowFileAccess;
  final int defaultTimeoutMs;
  final List<String> allowedHosts;

  const WebViewHostConfig({
    this.enableDebugging = false,
    this.allowFileAccess = false,
    this.defaultTimeoutMs = 30000,
    this.allowedHosts = const [],
  });

  factory WebViewHostConfig.development() => const WebViewHostConfig(
        enableDebugging: true,
        allowFileAccess: true,
        defaultTimeoutMs: 60000,
      );

  factory WebViewHostConfig.production() => const WebViewHostConfig(
        enableDebugging: false,
        allowFileAccess: false,
        defaultTimeoutMs: 30000,
      );
}
```

---

## 📄 lib/packages/core/pubspec.yaml

```yaml
name: core
description: Core module for Flutter Native Bridge
version: 1.0.0

environment:
  sdk: ^3.0.0

dependencies:
  flutter:
    sdk: flutter
  webview_flutter: ^4.8.0
  uuid: ^4.2.1
  path_provider: ^2.1.1
  mime: ^1.0.5
```

---

## 📄 lib/packages/security/lib/security.dart

```dart
library security;

export 'src/execution_guard.dart';
export 'src/permission_manager.dart';
export 'src/rate_limiter.dart';
```

---

## 📄 lib/packages/security/lib/src/permission_manager.dart

```dart
import 'dart:async';
import 'package:sweetmelon/packages/core/lib/core.dart';
import 'package:permission_handler/permission_handler.dart' as ph;

enum PermissionStatus {
  granted,
  denied,
  pending,
  notDetermined,
  permanentlyDenied,
}

abstract class PermissionProvider {
  Future<PermissionStatus> checkPermission(String permission);
  Future<PermissionStatus> requestPermission(String permission);
}

/// Provider استاتیک برای تست
class StaticPermissionProvider implements PermissionProvider {
  final Map<String, PermissionStatus> grants;
  final PermissionStatus defaultStatus;

  const StaticPermissionProvider({
    required this.grants,
    this.defaultStatus = PermissionStatus.denied,
  });

  @override
  Future<PermissionStatus> checkPermission(String permission) async {
    return grants[permission] ?? defaultStatus;
  }

  @override
  Future<PermissionStatus> requestPermission(String permission) async {
    return grants[permission] ?? defaultStatus;
  }
}

/// Provider واقعی که از permission_handler استفاده می‌کند
class NativePermissionProvider implements PermissionProvider {
  final PermissionStatus fallbackStatus;

  const NativePermissionProvider({
    this.fallbackStatus = PermissionStatus.denied,
  });

  @override
  Future<PermissionStatus> checkPermission(String permission) async {
    final phPermission = _mapPermission(permission);
    if (phPermission == null) return fallbackStatus;

    final status = await phPermission.status;
    return _mapStatus(status);
  }

  @override
  Future<PermissionStatus> requestPermission(String permission) async {
    final phPermission = _mapPermission(permission);
    if (phPermission == null) return fallbackStatus;

    final status = await phPermission.request();
    return _mapStatus(status);
  }

  ph.Permission? _mapPermission(String permission) {
    switch (permission) {
      case 'camera':
        return ph.Permission.camera;
      case 'storage':
        return ph.Permission.storage;
      case 'location':
        return ph.Permission.locationWhenInUse;
      case 'locationAlways':
        return ph.Permission.locationAlways;
      case 'microphone':
        return ph.Permission.microphone;
      case 'photos':
        return ph.Permission.photos;
      case 'notification':
        return ph.Permission.notification;
      case 'contacts':
        return ph.Permission.contacts;
      case 'calendar':
        return ph.Permission.calendarFullAccess;
      case 'sensors':
        return ph.Permission.sensors;
      default:
        BridgeLogger.warn(
          'PermissionProvider',
          'Unknown permission: $permission',
        );
        return null;
    }
  }

  PermissionStatus _mapStatus(ph.PermissionStatus status) {
    if (status.isGranted || status.isLimited) {
      return PermissionStatus.granted;
    } else if (status.isPermanentlyDenied) {
      return PermissionStatus.permanentlyDenied;
    } else if (status.isDenied) {
      return PermissionStatus.denied;
    } else if (status.isRestricted) {
      return PermissionStatus.denied;
    }
    return PermissionStatus.notDetermined;
  }
}

class PermissionManager {
  final Map<String, PermissionPolicy> _policies = {};
  final Map<String, PermissionStatus> _cache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  PermissionProvider? _provider;

  /// مدت زمان اعتبار cache
  final Duration cacheTtl;

  PermissionManager({
    this.cacheTtl = const Duration(minutes: 5),
  });

  void setProvider(PermissionProvider provider) {
    _provider = provider;
    _cache.clear();
    _cacheTimestamps.clear();
  }

  void addPolicy(String plugin, PermissionPolicy policy) {
    _policies[plugin] = policy;
  }

  Future<bool> check(String permission) async {
    // بررسی cache با TTL
    if (_cache.containsKey(permission)) {
      final timestamp = _cacheTimestamps[permission];
      if (timestamp != null &&
          DateTime.now().difference(timestamp) < cacheTtl) {
        final cached = _cache[permission]!;
        BridgeLogger.debug(
          'PermissionManager',
          'Permission "$permission" (cached): ${cached.name}',
        );
        return cached == PermissionStatus.granted;
      } else {
        // Cache expired
        _cache.remove(permission);
        _cacheTimestamps.remove(permission);
      }
    }

    if (_provider == null) {
      BridgeLogger.warn(
        'PermissionManager',
        'No provider set, denying permission: $permission',
      );
      return false;
    }

    final status = await _provider!.checkPermission(permission);
    _cache[permission] = status;
    _cacheTimestamps[permission] = DateTime.now();

    BridgeLogger.debug(
      'PermissionManager',
      'Permission "$permission": ${status.name}',
    );

    return status == PermissionStatus.granted;
  }

  Future<bool> request(String permission) async {
    if (_provider == null) {
      BridgeLogger.warn(
        'PermissionManager',
        'No provider set, cannot request: $permission',
      );
      return false;
    }

    final status = await _provider!.requestPermission(permission);
    _cache[permission] = status;
    _cacheTimestamps[permission] = DateTime.now();

    BridgeLogger.info(
      'PermissionManager',
      'Permission requested "$permission": ${status.name}',
    );

    return status == PermissionStatus.granted;
  }

  Future<Map<String, bool>> checkAll(List<String> permissions) async {
    final results = <String, bool>{};
    for (final permission in permissions) {
      results[permission] = await check(permission);
    }
    return results;
  }

  Future<bool> checkPlugin(String pluginName) async {
    final policy = _policies[pluginName];
    if (policy == null) return true;

    for (final permission in policy.required) {
      final granted = await check(permission);
      if (!granted) return false;
    }
    return true;
  }

  void invalidateCache([String? permission]) {
    if (permission != null) {
      _cache.remove(permission);
      _cacheTimestamps.remove(permission);
    } else {
      _cache.clear();
      _cacheTimestamps.clear();
    }
  }

  Map<String, PermissionStatus> get currentStatus => Map.unmodifiable(_cache);

  bool get hasProvider => _provider != null;
}

class PermissionPolicy {
  final List<String> required;
  final List<String> optional;

  const PermissionPolicy({
    required this.required,
    this.optional = const [],
  });

  factory PermissionPolicy.fromJson(Map<String, dynamic> json) {
    return PermissionPolicy(
      required: List<String>.from(json['required'] as List? ?? []),
      optional: List<String>.from(json['optional'] as List? ?? []),
    );
  }

  Map<String, dynamic> toJson() => {
        'required': required,
        'optional': optional,
      };
}
```

---

## 📄 lib/packages/security/lib/src/rate_limiter.dart

```dart
import 'package:sweetmelon/packages/core/lib/core.dart';

class RateLimitResult {
  final bool allowed;
  final int remaining;
  final int retryAfterMs;

  const RateLimitResult({
    required this.allowed,
    required this.remaining,
    required this.retryAfterMs,
  });
}

class RateLimitRule {
  final int maxCalls;
  final Duration window;

  const RateLimitRule({
    required this.maxCalls,
    required this.window,
  });

  factory RateLimitRule.perSecond(int max) => RateLimitRule(
        maxCalls: max,
        window: const Duration(seconds: 1),
      );

  factory RateLimitRule.perMinute(int max) => RateLimitRule(
        maxCalls: max,
        window: const Duration(minutes: 1),
      );
}

class RateLimiter {
  final Map<String, RateLimitRule> _rules = {};
  final Map<String, _BucketState> _buckets = {};
  RateLimitRule _defaultRule = RateLimitRule.perSecond(100);

  void setDefaultRule(RateLimitRule rule) {
    _defaultRule = rule;
  }

  void addRule(String key, RateLimitRule rule) {
    _rules[key] = rule;
    BridgeLogger.debug(
      'RateLimiter',
      'Rule added: $key (${rule.maxCalls} per ${rule.window.inSeconds}s)',
    );
  }

  Future<RateLimitResult> check(String plugin, String method) async {
    final specificKey = '$plugin.$method';
    final pluginKey = plugin;
    final rule = _rules[specificKey] ?? _rules[pluginKey] ?? _defaultRule;

    _buckets[specificKey] ??= _BucketState(rule: rule);
    final bucket = _buckets[specificKey]!;
    final result = bucket.consume();

    if (!result.allowed) {
      BridgeLogger.warn(
        'RateLimiter',
        'Rate limit exceeded for: $specificKey '
            '(retry after ${result.retryAfterMs}ms)',
      );
    }

    return result;
  }

  void reset(String key) => _buckets.remove(key);
  void resetAll() => _buckets.clear();

  Map<String, dynamic> getStats() {
    return _buckets.map(
      (key, bucket) => MapEntry(key, bucket.toJson()),
    );
  }
}

class _BucketState {
  final RateLimitRule rule;
  final List<DateTime> _calls = [];

  _BucketState({required this.rule});

  RateLimitResult consume() {
    final now = DateTime.now();
    final windowStart = now.subtract(rule.window);

    _calls.removeWhere((time) => time.isBefore(windowStart));

    if (_calls.length >= rule.maxCalls) {
      final oldest = _calls.first;
      final retryAfter = oldest.add(rule.window).difference(now);

      return RateLimitResult(
        allowed: false,
        remaining: 0,
        retryAfterMs: retryAfter.inMilliseconds.clamp(0, 60000),
      );
    }

    _calls.add(now);

    return RateLimitResult(
      allowed: true,
      remaining: rule.maxCalls - _calls.length,
      retryAfterMs: 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'callsInWindow': _calls.length,
        'maxCalls': rule.maxCalls,
        'windowSeconds': rule.window.inSeconds,
        'remaining': (rule.maxCalls - _calls.length).clamp(0, rule.maxCalls),
      };
}
```

---

## 📄 lib/packages/security/lib/src/execution_guard.dart

```dart
import 'dart:async';
import 'package:sweetmelon/packages/core/lib/core.dart';

class ExecutionGuard {
  final int defaultTimeoutMs;
  final Map<String, int> _activeExecutions = {};

  ExecutionGuard({this.defaultTimeoutMs = 30000});

  Future<T?> execute<T>({
    required String requestId,
    required Future<T> Function() fn,
    int? timeoutMs,
  }) async {
    final timeout = timeoutMs ?? defaultTimeoutMs;

    if (_activeExecutions.containsKey(requestId)) {
      BridgeLogger.warn(
        'ExecutionGuard',
        'Duplicate request detected: $requestId',
      );
    }

    _activeExecutions[requestId] = DateTime.now().millisecondsSinceEpoch;

    try {
      final result = await fn().timeout(
        Duration(milliseconds: timeout),
        onTimeout: () {
          BridgeLogger.warn(
            'ExecutionGuard',
            'Timeout for: $requestId after ${timeout}ms',
          );
          throw TimeoutException(
            'Execution timeout after ${timeout}ms',
            Duration(milliseconds: timeout),
          );
        },
      );
      return result;
    } finally {
      _activeExecutions.remove(requestId);
    }
  }

  int get activeCount => _activeExecutions.length;
  List<String> get activeRequests => _activeExecutions.keys.toList();
  bool isActive(String requestId) => _activeExecutions.containsKey(requestId);
}

class ArgsValidator {
  static ArgsValidationResult validate(
    Map<String, dynamic> args,
    Map<String, ArgSchema> schema,
  ) {
    final warnings = <String>[];

    for (final entry in schema.entries) {
      final fieldName = entry.key;
      final fieldSchema = entry.value;

      if (fieldSchema.required && !args.containsKey(fieldName)) {
        return ArgsValidationResult.invalid(
          'Required field "$fieldName" is missing',
        );
      }

      if (args.containsKey(fieldName)) {
        final value = args[fieldName];

        if (!fieldSchema.isValidType(value)) {
          return ArgsValidationResult.invalid(
            'Field "$fieldName" has invalid type. '
            'Expected: ${fieldSchema.type}, '
            'Got: ${value.runtimeType}',
          );
        }

        if (fieldSchema.validator != null) {
          final error = fieldSchema.validator!(value);
          if (error != null) {
            return ArgsValidationResult.invalid(error);
          }
        }
      }
    }

    for (final key in args.keys) {
      if (!schema.containsKey(key)) {
        warnings.add('Unknown field: "$key"');
      }
    }

    if (warnings.isNotEmpty) {
      return ArgsValidationResult.validWithWarnings(warnings);
    }

    return ArgsValidationResult.valid();
  }
}

class ArgSchema {
  final String type;
  final bool required;
  final dynamic defaultValue;
  final String? Function(dynamic value)? validator;

  const ArgSchema({
    required this.type,
    this.required = false,
    this.defaultValue,
    this.validator,
  });

  bool isValidType(dynamic value) {
    if (value == null) return !required;
    switch (type) {
      case 'string':
        return value is String;
      case 'int':
        return value is int;
      case 'double':
        return value is double || value is int;
      case 'num':
        return value is num;
      case 'bool':
        return value is bool;
      case 'list':
        return value is List;
      case 'map':
        return value is Map;
      case 'any':
        return true;
      default:
        return true;
    }
  }
}

class ArgsValidationResult {
  final bool isValid;
  final String? errorMessage;
  final List<String> warnings;

  const ArgsValidationResult({
    required this.isValid,
    this.errorMessage,
    this.warnings = const [],
  });

  factory ArgsValidationResult.valid() =>
      const ArgsValidationResult(isValid: true);

  factory ArgsValidationResult.invalid(String message) =>
      ArgsValidationResult(isValid: false, errorMessage: message);

  factory ArgsValidationResult.validWithWarnings(List<String> warnings) =>
      ArgsValidationResult(isValid: true, warnings: warnings);
}
```

---

## 📄 lib/packages/security/pubspec.yaml

```yaml
name: security
description: Security module for Flutter Native Bridge
version: 1.0.0

environment:
  sdk: ^3.0.0

dependencies:
  flutter:
    sdk: flutter
  core:
    path: ../core
  permission_handler: ^11.3.0
```

---

## 📄 lib/packages/performance/lib/performance.dart

```dart
library performance;

export 'src/cache_manager.dart';
```

---

## 📄 lib/packages/performance/lib/src/cache_manager.dart

```dart
import 'dart:async';
import 'package:sweetmelon/packages/core/lib/core.dart';

class CacheEntry {
  final dynamic value;
  final DateTime expiresAt;
  DateTime lastAccessedAt;
  int hitCount;

  CacheEntry({
    required this.value,
    required this.expiresAt,
  })  : lastAccessedAt = DateTime.now(),
        hitCount = 0;

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  void touch() {
    lastAccessedAt = DateTime.now();
    hitCount++;
  }
}

class CacheManager {
  final Map<String, CacheEntry> _cache = {};
  final int maxEntries;
  Timer? _cleanupTimer;

  int _hits = 0;
  int _misses = 0;

  final Set<String> _noCachePatterns = {};

  /// متدهایی که mutation هستند و نباید cache بشن
  final Set<String> _mutationMethods = {
    'set', 'remove', 'clear', 'delete', 'write', 'update',
    'insert', 'create', 'put', 'patch', 'post',
    'deleteFile', 'writeFile',
  };

  CacheManager({this.maxEntries = 500}) {
    _startCleanupTimer();
  }

  /// بررسی mutation بودن method
  bool isMutationMethod(String method) {
    return _mutationMethods.contains(method);
  }

  void addMutationMethod(String method) {
    _mutationMethods.add(method);
  }

  Future<dynamic> get(String key) async {
    final entry = _cache[key];

    if (entry == null) {
      _misses++;
      return null;
    }

    if (entry.isExpired) {
      _cache.remove(key);
      _misses++;
      return null;
    }

    entry.touch();
    _hits++;
    BridgeLogger.debug('Cache', 'Hit: $key');
    return entry.value;
  }

  Future<void> set(
    String key,
    dynamic value, {
    Duration ttl = const Duration(minutes: 5),
  }) async {
    if (_shouldSkipCache(key)) {
      BridgeLogger.debug('Cache', 'Skipped (no-cache): $key');
      return;
    }

    if (_cache.length >= maxEntries) {
      _evictLRU();
    }

    _cache[key] = CacheEntry(
      value: value,
      expiresAt: DateTime.now().add(ttl),
    );

    BridgeLogger.debug('Cache', 'Set: $key (TTL: ${ttl.inSeconds}s)');
  }

  Future<void> invalidate(String key) async {
    _cache.remove(key);
  }

  Future<void> invalidatePlugin(String pluginName) async {
    _cache.removeWhere((key, _) => key.startsWith('$pluginName:'));
    BridgeLogger.debug('Cache', 'Invalidated all keys for plugin: $pluginName');
  }

  Future<void> invalidatePattern(String pattern) async {
    _cache.removeWhere((key, _) => key.contains(pattern));
  }

  Future<void> clear() async {
    _cache.clear();
    _hits = 0;
    _misses = 0;
  }

  void addNoCachePattern(String pattern) {
    _noCachePatterns.add(pattern);
  }

  void removeNoCachePattern(String pattern) {
    _noCachePatterns.remove(pattern);
  }

  void _evictLRU() {
    if (_cache.isEmpty) return;

    String? lruKey;
    DateTime? oldestAccess;

    for (final entry in _cache.entries) {
      if (oldestAccess == null ||
          entry.value.lastAccessedAt.isBefore(oldestAccess)) {
        oldestAccess = entry.value.lastAccessedAt;
        lruKey = entry.key;
      }
    }

    if (lruKey != null) {
      _cache.remove(lruKey);
      BridgeLogger.debug('Cache', 'Evicted LRU: $lruKey');
    }
  }

  void _startCleanupTimer() {
    _cleanupTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _cleanup(),
    );
  }

  void _cleanup() {
    final expired = _cache.entries
        .where((e) => e.value.isExpired)
        .map((e) => e.key)
        .toList();

    for (final key in expired) {
      _cache.remove(key);
    }

    if (expired.isNotEmpty) {
      BridgeLogger.debug('Cache', 'Cleaned ${expired.length} expired entries');
    }
  }

  bool _shouldSkipCache(String key) {
    for (final pattern in _noCachePatterns) {
      if (key.startsWith(pattern) || key.contains(pattern)) {
        return true;
      }
    }
    return false;
  }

  CacheStats get stats => CacheStats(
        entries: _cache.length,
        hits: _hits,
        misses: _misses,
        hitRate: (_hits + _misses) > 0 ? _hits / (_hits + _misses) : 0,
      );

  void dispose() {
    _cleanupTimer?.cancel();
    _cache.clear();
  }
}

class CacheStats {
  final int entries;
  final int hits;
  final int misses;
  final double hitRate;

  const CacheStats({
    required this.entries,
    required this.hits,
    required this.misses,
    required this.hitRate,
  });

  Map<String, dynamic> toJson() => {
        'entries': entries,
        'hits': hits,
        'misses': misses,
        'hitRate': hitRate,
      };
}
```

---

## 📄 lib/packages/performance/pubspec.yaml

```yaml
name: performance
description: Performance module for Flutter Native Bridge
version: 1.0.0

environment:
  sdk: ^3.0.0

dependencies:
  flutter:
    sdk: flutter
  core:
    path: ../core
```

---

## 📄 lib/packages/plugin_engine/lib/plugin_engine.dart

```dart
library plugin_engine;

export 'src/plugin_interface.dart';
export 'src/plugin_registry.dart';
export 'src/plugin_manager.dart';
```

---

## 📄 lib/packages/plugin_engine/lib/src/plugin_interface.dart

```dart
import 'dart:async';

abstract class Plugin {
  String get name;
  String get version;
  String get description => '';
  List<String> get supportedMethods;
  List<String> get requiredPermissions => [];
  bool get cacheable => false;
  Duration get defaultCacheTtl => const Duration(minutes: 5);
  bool get isReady => _initialized;
  bool _initialized = false;

  Future<dynamic> onCall(String method, Map<String, dynamic> args);

  Future<void> initialize() async {
    if (_initialized) return; // جلوگیری از initialize دوباره
    await onInitialize();
    _initialized = true;
  }

  Future<void> dispose() async {
    if (!_initialized) return;
    _initialized = false;
    await onDispose();
  }

  Future<void> onInitialize() async {}
  Future<void> onDispose() async {}
  Future<void> onPause() async {}
  Future<void> onResume() async {}
  bool supportsMethod(String method) => supportedMethods.contains(method);
  Future<ValidationResult> validateArgs(
    String method,
    Map<String, dynamic> args,
  ) async {
    return ValidationResult.valid();
  }

  @override
  String toString() => 'Plugin($name@$version)';
}

class ValidationResult {
  final bool isValid;
  final String? errorMessage;
  final List<String> warnings;

  const ValidationResult({
    required this.isValid,
    this.errorMessage,
    this.warnings = const [],
  });

  factory ValidationResult.valid() => const ValidationResult(isValid: true);

  factory ValidationResult.invalid(String message) => ValidationResult(
        isValid: false,
        errorMessage: message,
      );

  factory ValidationResult.validWithWarnings(List<String> warnings) =>
      ValidationResult(
        isValid: true,
        warnings: warnings,
      );
}

class PluginManifest {
  final String name;
  final String version;
  final String description;
  final List<String> methods;
  final List<String> permissions;
  final Map<String, dynamic> config;
  final PluginCapabilities capabilities;

  const PluginManifest({
    required this.name,
    required this.version,
    required this.description,
    required this.methods,
    required this.permissions,
    required this.config,
    required this.capabilities,
  });

  factory PluginManifest.fromJson(Map<String, dynamic> json) {
    return PluginManifest(
      name: json['name'] as String,
      version: json['version'] as String,
      description: json['description'] as String? ?? '',
      methods: List<String>.from(json['methods'] as List),
      permissions: List<String>.from(
        (json['permissions'] as List?) ?? [],
      ),
      config: (json['config'] as Map<String, dynamic>?) ?? {},
      capabilities: json['capabilities'] != null
          ? PluginCapabilities.fromJson(
              json['capabilities'] as Map<String, dynamic>,
            )
          : PluginCapabilities.defaults(),
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'version': version,
        'description': description,
        'methods': methods,
        'permissions': permissions,
        'config': config,
        'capabilities': capabilities.toJson(),
      };
}

class PluginCapabilities {
  final bool supportsStreaming;
  final bool supportsBatch;
  final bool supportsCache;
  final int maxConcurrentCalls;

  const PluginCapabilities({
    required this.supportsStreaming,
    required this.supportsBatch,
    required this.supportsCache,
    required this.maxConcurrentCalls,
  });

  factory PluginCapabilities.defaults() => const PluginCapabilities(
        supportsStreaming: false,
        supportsBatch: true,
        supportsCache: false,
        maxConcurrentCalls: 10,
      );

  factory PluginCapabilities.fromJson(Map<String, dynamic> json) {
    return PluginCapabilities(
      supportsStreaming: json['supportsStreaming'] as bool? ?? false,
      supportsBatch: json['supportsBatch'] as bool? ?? true,
      supportsCache: json['supportsCache'] as bool? ?? false,
      maxConcurrentCalls: json['maxConcurrentCalls'] as int? ?? 10,
    );
  }

  Map<String, dynamic> toJson() => {
        'supportsStreaming': supportsStreaming,
        'supportsBatch': supportsBatch,
        'supportsCache': supportsCache,
        'maxConcurrentCalls': maxConcurrentCalls,
      };
}
```

---

## 📄 lib/packages/plugin_engine/lib/src/plugin_registry.dart

```dart
import 'dart:async';
import 'package:sweetmelon/packages/core/lib/core.dart';
import 'plugin_interface.dart';

typedef EventEmitter = Future<void> Function(String event, dynamic data);

class PluginRegistry {
  final Map<String, Map<String, Plugin>> _plugins = {};

  final _registrationController =
      StreamController<PluginRegistrationEvent>.broadcast();

  Stream<PluginRegistrationEvent> get events => _registrationController.stream;

  EventEmitter? _eventEmitter;
  bool _disposed = false;

  void setEventEmitter(EventEmitter emitter) {
    _eventEmitter = emitter;
  }

  Future<void> emitEvent(String event, dynamic data) async {
    if (_eventEmitter != null) {
      await _eventEmitter!(event, data);
    } else {
      BridgeLogger.warn(
        'Registry',
        'Event emitter not set, dropping event: $event',
      );
    }
  }

  Future<void> register(Plugin plugin) async {
    if (_disposed) return;

    final name = plugin.name;
    final version = plugin.version;

    BridgeLogger.info('Registry', 'Registering plugin: $name@$version');

    if (!_plugins.containsKey(name)) {
      _plugins[name] = {};
    }

    if (_plugins[name]!.containsKey(version)) {
      BridgeLogger.warn(
        'Registry',
        'Plugin $name@$version already registered, replacing...',
      );
      await _plugins[name]![version]!.dispose();
    }

    await plugin.initialize();
    _plugins[name]![version] = plugin;

    _emitRegistrationEvent(RegistrationEventType.registered, name, version);

    BridgeLogger.info('Registry', 'Plugin $name@$version registered');
  }

  Future<void> unregister(String name, {String? version}) async {
    if (!_plugins.containsKey(name)) {
      BridgeLogger.warn('Registry', 'Plugin $name not found');
      return;
    }

    if (version != null) {
      final plugin = _plugins[name]?[version];
      if (plugin != null) {
        await plugin.dispose();
        _plugins[name]!.remove(version);
      }
    } else {
      for (final plugin in _plugins[name]!.values) {
        await plugin.dispose();
      }
      _plugins.remove(name);
    }

    _emitRegistrationEvent(
      RegistrationEventType.unregistered,
      name,
      version ?? 'all',
    );
  }

  Plugin? resolve(String name, {String? version}) {
    if (!_plugins.containsKey(name)) return null;
    if (version != null) return _plugins[name]![version];
    return _getLatestVersion(name);
  }

  Plugin? _getLatestVersion(String name) {
    final versions = _plugins[name];
    if (versions == null || versions.isEmpty) return null;
    final sortedVersions = versions.keys.toList()..sort(_compareVersions);
    return versions[sortedVersions.last];
  }

  int _compareVersions(String v1, String v2) {
    final parts1 = v1.split('.').map((p) => int.tryParse(p) ?? 0).toList();
    final parts2 = v2.split('.').map((p) => int.tryParse(p) ?? 0).toList();
    for (var i = 0; i < 3; i++) {
      final p1 = i < parts1.length ? parts1[i] : 0;
      final p2 = i < parts2.length ? parts2[i] : 0;
      if (p1 != p2) return p1.compareTo(p2);
    }
    return 0;
  }

  bool isRegistered(String name, {String? version}) {
    if (!_plugins.containsKey(name)) return false;
    if (version != null) return _plugins[name]!.containsKey(version);
    return _plugins[name]!.isNotEmpty;
  }

  List<String> get registeredPlugins => _plugins.keys.toList();

  List<PluginInfo> getPluginInfos() {
    final infos = <PluginInfo>[];
    for (final entry in _plugins.entries) {
      for (final vEntry in entry.value.entries) {
        infos.add(PluginInfo(
          name: entry.key,
          version: vEntry.key,
          isReady: vEntry.value.isReady,
          supportedMethods: vEntry.value.supportedMethods,
          requiredPermissions: vEntry.value.requiredPermissions,
        ));
      }
    }
    return infos;
  }

  void _emitRegistrationEvent(
    RegistrationEventType type,
    String name,
    String version,
  ) {
    if (!_registrationController.isClosed) {
      _registrationController.add(
        PluginRegistrationEvent(
          type: type,
          pluginName: name,
          version: version,
        ),
      );
    }
  }

  Future<void> dispose() async {
    _disposed = true;
    for (final versions in _plugins.values) {
      for (final plugin in versions.values) {
        await plugin.dispose();
      }
    }
    _plugins.clear();
    if (!_registrationController.isClosed) {
      _registrationController.close();
    }
  }
}

enum RegistrationEventType { registered, unregistered, updated }

class PluginRegistrationEvent {
  final RegistrationEventType type;
  final String pluginName;
  final String version;
  final DateTime timestamp;

  PluginRegistrationEvent({
    required this.type,
    required this.pluginName,
    required this.version,
  }) : timestamp = DateTime.now();
}

class PluginInfo {
  final String name;
  final String version;
  final bool isReady;
  final List<String> supportedMethods;
  final List<String> requiredPermissions;

  const PluginInfo({
    required this.name,
    required this.version,
    required this.isReady,
    required this.supportedMethods,
    required this.requiredPermissions,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'version': version,
        'isReady': isReady,
        'methods': supportedMethods,
        'permissions': requiredPermissions,
      };
}
```

---

## 📄 lib/packages/plugin_engine/lib/src/plugin_manager.dart

```dart
import 'dart:async';
import 'dart:convert';
import 'plugin_registry.dart';
import 'package:sweetmelon/packages/core/lib/core.dart';
import 'package:sweetmelon/packages/performance/lib/performance.dart';
import 'package:sweetmelon/packages/security/lib/security.dart';
import 'package:sweetmelon/packages/plugin_engine/lib/plugin_engine.dart';

class PluginManager {
  final PluginRegistry registry;
  final PermissionManager permissionManager;
  final RateLimiter rateLimiter;
  final ExecutionGuard executionGuard;
  final CacheManager cacheManager;

  final Map<String, PluginStats> _stats = {};
  final _traceController = StreamController<PluginTrace>.broadcast();
  bool _disposed = false;

  Stream<PluginTrace> get traces => _traceController.stream;

  PluginManager({
    required this.registry,
    required this.permissionManager,
    required this.rateLimiter,
    required this.executionGuard,
    required this.cacheManager,
  });

  Future<PluginResponse> execute(PluginRequest request) async {
    if (_disposed) {
      return _errorResponse(
        request.requestId,
        PluginErrorCode.executionError,
        'PluginManager is disposed',
      );
    }

    final startTime = DateTime.now();
    final traceId = 'trace_${request.requestId}';

    BridgeLogger.info(
      'Manager',
      'Executing: ${request.plugin}.${request.method}',
    );

    try {
      // Rate limit
      final rateLimitResult = await rateLimiter.check(
        request.plugin,
        request.method,
      );
      if (!rateLimitResult.allowed) {
        return _errorResponse(
          request.requestId,
          PluginErrorCode.rateLimitExceeded,
          'Rate limit exceeded. Retry after ${rateLimitResult.retryAfterMs}ms',
        );
      }

      // Resolve plugin
      final plugin = registry.resolve(
        request.plugin,
        version: request.version == '1.0.0' ? null : request.version,
      );
      if (plugin == null) {
        return _errorResponse(
          request.requestId,
          PluginErrorCode.pluginNotFound,
          'Plugin "${request.plugin}" not found',
        );
      }

      // Method check
      if (!plugin.supportsMethod(request.method)) {
        return _errorResponse(
          request.requestId,
          PluginErrorCode.methodNotFound,
          'Method "${request.method}" not supported by "${request.plugin}"',
        );
      }

      // Permission check
      for (final permission in plugin.requiredPermissions) {
        final hasPermission = await permissionManager.check(permission);
        if (!hasPermission) {
          return _errorResponse(
            request.requestId,
            PluginErrorCode.permissionDenied,
            'Permission "$permission" denied for "${request.plugin}"',
          );
        }
      }

      // Validate args
      final validation = await plugin.validateArgs(
        request.method,
        request.args,
      );
      if (!validation.isValid) {
        return _errorResponse(
          request.requestId,
          PluginErrorCode.invalidArgs,
          validation.errorMessage ?? 'Invalid arguments',
        );
      }

      // Cache check (فقط برای read methods)
      final isMutation = cacheManager.isMutationMethod(request.method);

      if (plugin.cacheable && !isMutation) {
        final cacheKey = _buildCacheKey(request);
        final cached = await cacheManager.get(cacheKey);
        if (cached != null) {
          BridgeLogger.debug('Manager', 'Cache hit: $cacheKey');
          _recordStats(request.plugin, request.method, 0, true);
          return PluginResponse.success(
            requestId: request.requestId,
            data: cached,
            metadata: ResponseMetadata(
              processingTimeMs: 0,
              pluginVersion: plugin.version,
              fromCache: true,
            ),
          );
        }
      }

      // Execute
      final result = await executionGuard.execute(
        requestId: request.requestId,
        timeoutMs: 30000,
        fn: () => plugin.onCall(request.method, request.args),
      );

      final processingTime =
          DateTime.now().difference(startTime).inMilliseconds;

      // Cache result (فقط read methods)
      if (plugin.cacheable && !isMutation && result != null) {
        final cacheKey = _buildCacheKey(request);
        await cacheManager.set(
          cacheKey,
          result,
          ttl: plugin.defaultCacheTtl,
        );
      }

      // Invalidate cache on mutation
      if (plugin.cacheable && isMutation) {
        await cacheManager.invalidatePlugin(request.plugin);
        BridgeLogger.debug(
          'Manager',
          'Cache invalidated for plugin: ${request.plugin} (mutation: ${request.method})',
        );
      }

      _recordStats(request.plugin, request.method, processingTime, false);

      _emitTrace(
        traceId: traceId,
        requestId: request.requestId,
        plugin: request.plugin,
        method: request.method,
        processingTimeMs: processingTime,
        success: true,
      );

      return PluginResponse.success(
        requestId: request.requestId,
        data: result,
        metadata: ResponseMetadata(
          processingTimeMs: processingTime,
          pluginVersion: plugin.version,
          fromCache: false,
        ),
      );
    } catch (e, stackTrace) {
      final processingTime =
          DateTime.now().difference(startTime).inMilliseconds;

      BridgeLogger.error('Manager', 'Execution error: $e');

      _emitTrace(
        traceId: traceId,
        requestId: request.requestId,
        plugin: request.plugin,
        method: request.method,
        processingTimeMs: processingTime,
        success: false,
        error: e.toString(),
      );

      if (e is TimeoutException) {
        return _errorResponse(
          request.requestId,
          PluginErrorCode.timeout,
          'Plugin execution timed out',
        );
      }

      return _errorResponse(
        request.requestId,
        PluginErrorCode.executionError,
        e.toString(),
        stackTrace: stackTrace.toString(),
      );
    }
  }

  Future<List<PluginResponse>> executeBatch(
    List<PluginRequest> requests,
    BatchOptions options,
  ) async {
    BridgeLogger.info(
      'Manager',
      'Batch execution: ${requests.length} requests (parallel: ${options.parallel})',
    );

    if (options.parallel) {
      // استفاده از allSettled pattern
      final futures = requests.map((request) async {
        try {
          return await execute(request);
        } catch (e) {
          return PluginResponse.failure(
            requestId: request.requestId,
            error: PluginError(
              code: PluginErrorCode.executionError,
              message: e.toString(),
            ),
          );
        }
      }).toList();

      final results = await Future.wait(futures);

      // بررسی stopOnError بعد از اتمام parallel
      if (options.stopOnError) {
        final firstError = results.indexWhere((r) => !r.success);
        if (firstError >= 0) {
          return results.sublist(0, firstError + 1);
        }
      }

      return results;
    } else {
      final responses = <PluginResponse>[];
      for (final request in requests) {
        final response = await execute(request);
        responses.add(response);
        if (options.stopOnError && !response.success) {
          BridgeLogger.warn(
            'Manager',
            'Batch stopped due to error in: ${request.requestId}',
          );
          break;
        }
      }
      return responses;
    }
  }

  PluginResponse _errorResponse(
    String requestId,
    PluginErrorCode code,
    String message, {
    String? stackTrace,
  }) {
    return PluginResponse.failure(
      requestId: requestId,
      error: PluginError(
        code: code,
        message: message,
        stackTrace: stackTrace,
      ),
    );
  }

  String _buildCacheKey(PluginRequest request) {
    final sortedArgs = _sortedJsonEncode(request.args);
    return '${request.plugin}:${request.method}:$sortedArgs';
  }

  String _sortedJsonEncode(Map<String, dynamic> map) {
    final sortedKeys = map.keys.toList()..sort();
    final sortedMap = <String, dynamic>{};
    for (final key in sortedKeys) {
      final value = map[key];
      if (value is Map<String, dynamic>) {
        sortedMap[key] = jsonDecode(_sortedJsonEncode(value));
      } else {
        sortedMap[key] = value;
      }
    }
    return jsonEncode(sortedMap);
  }

  void _recordStats(
    String plugin,
    String method,
    int timeMs,
    bool fromCache,
  ) {
    final key = '$plugin.$method';
    _stats[key] ??= PluginStats(plugin: plugin, method: method);
    _stats[key]!.record(timeMs, fromCache);
  }

  void _emitTrace({
    required String traceId,
    required String requestId,
    required String plugin,
    required String method,
    required int processingTimeMs,
    required bool success,
    bool fromCache = false,
    String? error,
  }) {
    if (!_traceController.isClosed) {
      _traceController.add(
        PluginTrace(
          traceId: traceId,
          requestId: requestId,
          plugin: plugin,
          method: method,
          processingTimeMs: processingTimeMs,
          success: success,
          fromCache: fromCache,
          error: error,
        ),
      );
    }
  }

  Map<String, PluginStats> get stats => Map.unmodifiable(_stats);

  void dispose() {
    _disposed = true;
    if (!_traceController.isClosed) {
      _traceController.close();
    }
  }
}

class PluginStats {
  final String plugin;
  final String method;
  int totalCalls = 0;
  int cacheHits = 0;
  int totalTimeMs = 0;
  int errorCount = 0;

  PluginStats({required this.plugin, required this.method});

  void record(int timeMs, bool fromCache) {
    totalCalls++;
    totalTimeMs += timeMs;
    if (fromCache) cacheHits++;
  }

  void recordError() => errorCount++;
  double get avgTimeMs => totalCalls > 0 ? totalTimeMs / totalCalls : 0;
  double get cacheHitRate => totalCalls > 0 ? cacheHits / totalCalls : 0;

  Map<String, dynamic> toJson() => {
        'plugin': plugin,
        'method': method,
        'totalCalls': totalCalls,
        'cacheHits': cacheHits,
        'cacheHitRate': cacheHitRate,
        'avgTimeMs': avgTimeMs,
        'errorCount': errorCount,
      };
}

class PluginTrace {
  final String traceId;
  final String requestId;
  final String plugin;
  final String method;
  final int processingTimeMs;
  final bool success;
  final bool fromCache;
  final String? error;
  final DateTime timestamp;

  PluginTrace({
    required this.traceId,
    required this.requestId,
    required this.plugin,
    required this.method,
    required this.processingTimeMs,
    required this.success,
    this.fromCache = false,
    this.error,
  }) : timestamp = DateTime.now();

  Map<String, dynamic> toJson() => {
        'traceId': traceId,
        'requestId': requestId,
        'plugin': plugin,
        'method': method,
        'processingTimeMs': processingTimeMs,
        'success': success,
        'fromCache': fromCache,
        if (error != null) 'error': error,
        'timestamp': timestamp.toIso8601String(),
      };
}
```

---

## 📄 lib/packages/plugin_engine/pubspec.yaml

```yaml
name: plugin_engine
description: Plugin engine for Flutter Native Bridge
version: 1.0.0

environment:
  sdk: ^3.0.0

dependencies:
  flutter:
    sdk: flutter
  core:
    path: ../core
  security:
    path: ../security
  performance:
    path: ../performance
```

---

## 📄 lib/packages/devtools/lib/devtools.dart

```dart
library devtools;

export 'src/bridge_inspector.dart';
```

---

## 📄 lib/packages/devtools/lib/src/bridge_inspector.dart

```dart
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:sweetmelon/packages/core/lib/core.dart';
import 'package:sweetmelon/packages/plugin_engine/lib/plugin_engine.dart';

class BridgeInspector {
  final MessageBridge bridge;
  final PluginManager manager;

  final List<InspectorEntry> _log = [];
  final _logController = StreamController<InspectorEntry>.broadcast();

  StreamSubscription<BridgeMessage>? _bridgeSub;
  StreamSubscription<PluginTrace>? _traceSub;

  bool _disposed = false;

  Stream<InspectorEntry> get logStream => _logController.stream;
  List<InspectorEntry> get log => List.unmodifiable(_log);

  BridgeInspector({
    required this.bridge,
    required this.manager,
  }) {
    _attachListeners();
  }

  void _attachListeners() {
    _bridgeSub = bridge.messageStream.listen((message) {
      if (_disposed) return;

      final entry = InspectorEntry(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        direction: message.direction == BridgeMessageDirection.incoming
            ? EntryDirection.jsToFlutter
            : EntryDirection.flutterToJs,
        timestamp: message.timestamp,
        content: message.message.toJson(),
      );

      _log.add(entry);
      if (_log.length > 500) _log.removeAt(0);

      if (!_logController.isClosed) {
        _logController.add(entry);
      }
    });

    _traceSub = manager.traces.listen((trace) {
      if (_disposed) return;

      BridgeLogger.debug(
        'Inspector',
        '${trace.plugin}.${trace.method} — '
            '${trace.processingTimeMs}ms '
            '${trace.success ? "OK" : "FAIL"}',
      );
    });
  }

  void clear() => _log.clear();

  Map<String, dynamic> getReport() {
    final stats = manager.stats;
    return {
      'totalRequests': _log.length,
      'pluginStats': stats.map(
        (key, value) => MapEntry(key, value.toJson()),
      ),
      'recentErrors':
          _log.where((e) => e.isError).take(10).map((e) => e.toJson()).toList(),
    };
  }

  void dispose() {
    _disposed = true;
    _bridgeSub?.cancel();
    _traceSub?.cancel();
    if (!_logController.isClosed) {
      _logController.close();
    }
  }
}

enum EntryDirection { jsToFlutter, flutterToJs }

class InspectorEntry {
  final String id;
  final EntryDirection direction;
  final DateTime timestamp;
  final Map<String, dynamic> content;

  const InspectorEntry({
    required this.id,
    required this.direction,
    required this.timestamp,
    required this.content,
  });

  bool get isError => content['success'] == false;

  String get summary {
    final plugin = content['plugin'] as String?;
    final method = content['method'] as String?;
    if (plugin != null && method != null) return '$plugin.$method';
    if (content['success'] == true) return 'response (ok)';
    if (content['success'] == false) return 'response (error)';
    return 'message';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'direction': direction.name,
        'timestamp': timestamp.toIso8601String(),
        'content': content,
        'isError': isError,
      };
}

class BridgeInspectorWidget extends StatefulWidget {
  final BridgeInspector inspector;

  const BridgeInspectorWidget({
    super.key,
    required this.inspector,
  });

  @override
  State<BridgeInspectorWidget> createState() => _BridgeInspectorWidgetState();
}

class _BridgeInspectorWidgetState extends State<BridgeInspectorWidget> {
  final List<InspectorEntry> _entries = [];
  StreamSubscription<InspectorEntry>? _sub;
  String _filter = '';
  bool _showErrors = false;

  @override
  void initState() {
    super.initState();
    _entries.addAll(widget.inspector.log);
    _sub = widget.inspector.logStream.listen((entry) {
      if (mounted) {
        setState(() => _entries.insert(0, entry));
      }
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  List<InspectorEntry> get _filteredEntries {
    var list = List<InspectorEntry>.from(_entries);
    if (_showErrors) {
      list = list.where((e) => e.isError).toList();
    }
    if (_filter.isNotEmpty) {
      final lowerFilter = _filter.toLowerCase();
      list = list.where((e) {
        final content = jsonEncode(e.content).toLowerCase();
        return content.contains(lowerFilter);
      }).toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16213E),
        title: const Text(
          'Bridge Inspector',
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'monospace',
            fontSize: 16,
          ),
        ),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.clear_all, color: Colors.white),
            tooltip: 'Clear log',
            onPressed: () {
              widget.inspector.clear();
              setState(() => _entries.clear());
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildToolbar(),
          Expanded(child: _buildList()),
          _buildStats(),
        ],
      ),
    );
  }

  Widget _buildToolbar() {
    return Container(
      color: const Color(0xFF16213E),
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              style: const TextStyle(color: Colors.white, fontSize: 12),
              decoration: InputDecoration(
                hintText: 'Filter...',
                hintStyle: const TextStyle(color: Colors.white38),
                prefixIcon: const Icon(
                  Icons.search,
                  size: 16,
                  color: Colors.white38,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: const BorderSide(color: Colors.white24),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                isDense: true,
              ),
              onChanged: (v) => setState(() => _filter = v),
            ),
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: const Text('Errors', style: TextStyle(fontSize: 11)),
            selected: _showErrors,
            onSelected: (v) => setState(() => _showErrors = v),
            backgroundColor: Colors.transparent,
            selectedColor: Colors.red.withValues(alpha: 0.3),
            side: BorderSide(
              color: _showErrors ? Colors.red : Colors.white24,
            ),
            labelStyle: TextStyle(
              color: _showErrors ? Colors.red : Colors.white54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList() {
    final entries = _filteredEntries;

    if (entries.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox, color: Colors.white24, size: 48),
            SizedBox(height: 8),
            Text('No messages', style: TextStyle(color: Colors.white38)),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: entries.length,
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemBuilder: (ctx, i) => _EntryTile(entry: entries[i]),
    );
  }

  Widget _buildStats() {
    final errorCount = _entries.where((e) => e.isError).length;

    return Container(
      color: const Color(0xFF0F3460),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Text(
            'Total: ${_entries.length}',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(width: 16),
          Text(
            'Errors: $errorCount',
            style: const TextStyle(
              color: Colors.redAccent,
              fontSize: 11,
              fontFamily: 'monospace',
            ),
          ),
          const Spacer(),
          Text(
            'Filtered: ${_filteredEntries.length}',
            style: const TextStyle(
              color: Colors.white38,
              fontSize: 11,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}

class _EntryTile extends StatefulWidget {
  final InspectorEntry entry;
  const _EntryTile({required this.entry});

  @override
  State<_EntryTile> createState() => _EntryTileState();
}

class _EntryTileState extends State<_EntryTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final isIncoming = widget.entry.direction == EntryDirection.jsToFlutter;
    final isError = widget.entry.isError;

    final borderColor = isError
        ? Colors.red.withValues(alpha: 0.5)
        : isIncoming
            ? Colors.blue.withValues(alpha: 0.3)
            : Colors.green.withValues(alpha: 0.3);

    return InkWell(
      onTap: () => setState(() => _expanded = !_expanded),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: const Color(0xFF16213E),
          border: Border.all(color: borderColor),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Icon(
                    isIncoming ? Icons.arrow_downward : Icons.arrow_upward,
                    size: 14,
                    color: isIncoming ? Colors.blue : Colors.green,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.entry.summary,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isError)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: const Text(
                        'ERR',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  const SizedBox(width: 8),
                  Text(
                    _formatTime(widget.entry.timestamp),
                    style: const TextStyle(
                      color: Colors.white38,
                      fontSize: 10,
                      fontFamily: 'monospace',
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    size: 14,
                    color: Colors.white38,
                  ),
                ],
              ),
            ),
            if (_expanded)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                color: Colors.black26,
                child: SelectableText(
                  const JsonEncoder.withIndent('  ')
                      .convert(widget.entry.content),
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}:'
        '${dt.second.toString().padLeft(2, '0')}';
  }
}
```

---

## 📄 lib/packages/devtools/pubspec.yaml

```yaml
name: devtools
description: Devtools module for Flutter Native Bridge
version: 1.0.0

environment:
  sdk: ^3.0.0

dependencies:
  flutter:
    sdk: flutter
  core:
    path: ../core
  plugin_engine:
    path: ../plugin_engine
```

---

## 📄 lib/plugins/camera/lib/camera_plugin.dart

```dart
import 'dart:async';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:sweetmelon/packages/plugin_engine/lib/plugin_engine.dart';

class CameraPlugin extends Plugin {
  final ImagePicker _picker = ImagePicker();

  @override
  String get name => 'camera';

  @override
  String get version => '1.0.0';

  @override
  String get description => 'Camera and image picker plugin';

  @override
  bool get cacheable => false;

  @override
  List<String> get supportedMethods => [
        'takePhoto',
        'pickFromGallery',
        'recordVideo',
        'getInfo',
      ];

  @override
  List<String> get requiredPermissions => ['camera', 'storage'];

  @override
  Future<void> onInitialize() async {}

  @override
  Future<dynamic> onCall(String method, Map<String, dynamic> args) async {
    switch (method) {
      case 'takePhoto':
        return _takePhoto(args);
      case 'pickFromGallery':
        return _pickFromGallery(args);
      case 'recordVideo':
        return _recordVideo(args);
      case 'getInfo':
        return _getInfo();
      default:
        throw UnsupportedError('Method "$method" not supported');
    }
  }

  Future<Map<String, dynamic>> _takePhoto(Map<String, dynamic> args) async {
    final quality = (args['quality'] as num?)?.toInt() ?? 80;
    final maxWidth = (args['maxWidth'] as num?)?.toDouble();
    final maxHeight = (args['maxHeight'] as num?)?.toDouble();

    final image = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: quality,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
    );

    if (image == null) throw Exception('User cancelled photo capture');
    return _xFileToMap(image);
  }

  Future<Map<String, dynamic>> _pickFromGallery(
    Map<String, dynamic> args,
  ) async {
    final multiple = args['multiple'] as bool? ?? false;

    if (multiple) {
      final images = await _picker.pickMultiImage();
      if (images.isEmpty) throw Exception('No images selected');

      final imageList = <Map<String, dynamic>>[];
      for (final img in images) {
        imageList.add(await _xFileToMap(img));
      }
      return {'images': imageList};
    } else {
      final image = await _picker.pickImage(source: ImageSource.gallery);
      if (image == null) throw Exception('User cancelled');
      return _xFileToMap(image);
    }
  }

  Future<Map<String, dynamic>> _recordVideo(
    Map<String, dynamic> args,
  ) async {
    final maxDuration = args['maxDurationSeconds'] as int?;

    final video = await _picker.pickVideo(
      source: ImageSource.camera,
      maxDuration: maxDuration != null ? Duration(seconds: maxDuration) : null,
    );

    if (video == null) throw Exception('User cancelled');

    final file = File(video.path);
    final stat = await file.stat();

    return {
      'path': video.path,
      'name': video.name,
      'size': stat.size,
      'mimeType': 'video/mp4',
    };
  }

  Map<String, dynamic> _getInfo() {
    return {
      'name': name,
      'version': version,
      'supportedMethods': supportedMethods,
      'platform': Platform.operatingSystem,
    };
  }

  Future<Map<String, dynamic>> _xFileToMap(XFile xFile) async {
    final file = File(xFile.path);
    final stat = await file.stat();
    return {
      'path': xFile.path,
      'name': xFile.name,
      'size': stat.size,
      'mimeType': xFile.mimeType ?? 'image/jpeg',
    };
  }

  @override
  Future<ValidationResult> validateArgs(
    String method,
    Map<String, dynamic> args,
  ) async {
    switch (method) {
      case 'takePhoto':
        return _validateTakePhoto(args);
      case 'recordVideo':
        return _validateRecordVideo(args);
      default:
        return ValidationResult.valid();
    }
  }

  ValidationResult _validateTakePhoto(Map<String, dynamic> args) {
    final quality = args['quality'];
    if (quality != null) {
      if (quality is! num) {
        return ValidationResult.invalid('quality must be a number');
      }
      if (quality < 0 || quality > 100) {
        return ValidationResult.invalid(
          'quality must be between 0 and 100',
        );
      }
    }
    return ValidationResult.valid();
  }

  ValidationResult _validateRecordVideo(Map<String, dynamic> args) {
    final maxDuration = args['maxDurationSeconds'];
    if (maxDuration != null) {
      if (maxDuration is! int) {
        return ValidationResult.invalid(
          'maxDurationSeconds must be an integer',
        );
      }
      if (maxDuration <= 0) {
        return ValidationResult.invalid(
          'maxDurationSeconds must be positive',
        );
      }
    }
    return ValidationResult.valid();
  }
}
```

---

## 📄 lib/plugins/camera/pubspec.yaml

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

## 📄 lib/plugins/geolocation/lib/geolocation_plugin.dart

```dart
import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:sweetmelon/packages/plugin_engine/lib/plugin_engine.dart';
import 'package:sweetmelon/packages/core/lib/core.dart';

typedef PluginEventEmitter = Future<void> Function(String event, dynamic data);

class GeolocationPlugin extends Plugin {
  StreamSubscription<Position>? _positionStream;
  final PluginEventEmitter? eventEmitter;

  GeolocationPlugin({this.eventEmitter});

  @override
  String get name => 'geolocation';

  @override
  String get version => '1.0.0';

  @override
  String get description => 'Geolocation and GPS plugin';

  @override
  bool get cacheable => false;

  @override
  List<String> get supportedMethods => [
        'getCurrentPosition',
        'watchPosition',
        'clearWatch',
        'checkPermission',
        'requestPermission',
        'isLocationEnabled',
      ];

  @override
  List<String> get requiredPermissions => ['location'];

  @override
  Future<dynamic> onCall(String method, Map<String, dynamic> args) async {
    switch (method) {
      case 'getCurrentPosition':
        return _getCurrentPosition(args);
      case 'watchPosition':
        return _watchPosition(args);
      case 'clearWatch':
        return _clearWatch();
      case 'checkPermission':
        return _checkPermission();
      case 'requestPermission':
        return _requestPermission();
      case 'isLocationEnabled':
        return _isLocationEnabled();
      default:
        throw UnsupportedError('Method "$method" not supported');
    }
  }

  Future<Map<String, dynamic>> _getCurrentPosition(
    Map<String, dynamic> args,
  ) async {
    final accuracy = _parseAccuracy(args['accuracy'] as String? ?? 'high');

    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: accuracy,
    );

    return _positionToMap(position);
  }

  Future<String> _watchPosition(Map<String, dynamic> args) async {
    final accuracy = _parseAccuracy(args['accuracy'] as String? ?? 'high');
    final distanceFilter = (args['distanceFilter'] as num?)?.toDouble() ?? 10;

    await _clearWatch();

    final settings = LocationSettings(
      accuracy: accuracy,
      distanceFilter: distanceFilter.toInt(),
    );

    _positionStream = Geolocator.getPositionStream(
      locationSettings: settings,
    ).listen(
      (position) {
        // ارسال موقعیت به JS از طریق event emitter
        final data = _positionToMap(position);

        if (eventEmitter != null) {
          eventEmitter!('geolocation.position', data);
        } else {
          BridgeLogger.warn(
            'Geolocation',
            'No event emitter set, position update dropped',
          );
        }
      },
      onError: (error) {
        BridgeLogger.error('Geolocation', 'Watch error: $error');

        if (eventEmitter != null) {
          eventEmitter!('geolocation.error', {
            'message': error.toString(),
          });
        }
      },
    );

    return 'watch_started';
  }

  Future<String> _clearWatch() async {
    await _positionStream?.cancel();
    _positionStream = null;
    return 'watch_cleared';
  }

  Future<String> _checkPermission() async {
    final permission = await Geolocator.checkPermission();
    return permission.name;
  }

  Future<String> _requestPermission() async {
    final permission = await Geolocator.requestPermission();
    return permission.name;
  }

  Future<bool> _isLocationEnabled() async {
    return Geolocator.isLocationServiceEnabled();
  }

  LocationAccuracy _parseAccuracy(String accuracy) {
    switch (accuracy) {
      case 'lowest':
        return LocationAccuracy.lowest;
      case 'low':
        return LocationAccuracy.low;
      case 'medium':
        return LocationAccuracy.medium;
      case 'high':
        return LocationAccuracy.high;
      case 'best':
        return LocationAccuracy.best;
      case 'bestForNavigation':
        return LocationAccuracy.bestForNavigation;
      default:
        return LocationAccuracy.high;
    }
  }

  Map<String, dynamic> _positionToMap(Position position) {
    return {
      'latitude': position.latitude,
      'longitude': position.longitude,
      'altitude': position.altitude,
      'accuracy': position.accuracy,
      'heading': position.heading,
      'speed': position.speed,
      'speedAccuracy': position.speedAccuracy,
      'timestamp': position.timestamp.toIso8601String(),
    };
  }

  @override
  Future<ValidationResult> validateArgs(
    String method,
    Map<String, dynamic> args,
  ) async {
    switch (method) {
      case 'getCurrentPosition':
      case 'watchPosition':
        return _validatePositionArgs(args);
      default:
        return ValidationResult.valid();
    }
  }

  ValidationResult _validatePositionArgs(Map<String, dynamic> args) {
    final accuracy = args['accuracy'];
    if (accuracy != null && accuracy is! String) {
      return ValidationResult.invalid('accuracy must be a string');
    }

    const validAccuracies = [
      'lowest', 'low', 'medium', 'high', 'best', 'bestForNavigation',
    ];
    if (accuracy != null && !validAccuracies.contains(accuracy)) {
      return ValidationResult.invalid(
        'accuracy must be one of: ${validAccuracies.join(", ")}',
      );
    }

    final distanceFilter = args['distanceFilter'];
    if (distanceFilter != null && distanceFilter is! num) {
      return ValidationResult.invalid('distanceFilter must be a number');
    }

    return ValidationResult.valid();
  }

  @override
  Future<void> onDispose() async {
    await _clearWatch();
  }
}
```

---

## 📄 lib/plugins/geolocation/pubspec.yaml

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
```

---

## 📄 lib/plugins/storage/lib/storage_plugin.dart

```dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sweetmelon/packages/plugin_engine/lib/plugin_engine.dart';

class StoragePlugin extends Plugin {
  SharedPreferences? _prefs;
  static const String _keyPrefix = 'bridge_';

  @override
  String get name => 'storage';

  @override
  String get version => '1.0.0';

  @override
  String get description => 'Key-value storage and file system plugin';

  @override
  bool get cacheable => true;

  @override
  Duration get defaultCacheTtl => const Duration(seconds: 30);

  @override
  List<String> get supportedMethods => [
        'get',
        'set',
        'remove',
        'clear',
        'keys',
        'has',
        'readFile',
        'writeFile',
        'deleteFile',
        'fileExists',
        'listFiles',
      ];

  @override
  List<String> get requiredPermissions => ['storage'];

  @override
  Future<void> onInitialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  @override
  Future<dynamic> onCall(String method, Map<String, dynamic> args) async {
    switch (method) {
      case 'get':
        return _get(args);
      case 'set':
        return _set(args);
      case 'remove':
        return _remove(args);
      case 'clear':
        return _clear();
      case 'keys':
        return _keys();
      case 'has':
        return _has(args);
      case 'readFile':
        return _readFile(args);
      case 'writeFile':
        return _writeFile(args);
      case 'deleteFile':
        return _deleteFile(args);
      case 'fileExists':
        return _fileExists(args);
      case 'listFiles':
        return _listFiles(args);
      default:
        throw UnsupportedError('Method "$method" not supported');
    }
  }

  dynamic _get(Map<String, dynamic> args) {
    final key = args['key'] as String;
    final raw = _prefs?.getString('$_keyPrefix$key');
    if (raw == null) return null;
    try {
      return jsonDecode(raw);
    } catch (_) {
      return raw;
    }
  }

  Future<bool> _set(Map<String, dynamic> args) async {
    final key = args['key'] as String;
    final value = args['value'];
    final encoded = jsonEncode(value);
    return await _prefs?.setString('$_keyPrefix$key', encoded) ?? false;
  }

  Future<bool> _remove(Map<String, dynamic> args) async {
    final key = args['key'] as String;
    return await _prefs?.remove('$_keyPrefix$key') ?? false;
  }

  Future<int> _clear() async {
    final keys = _getBridgeKeys();
    int count = 0;
    for (final key in keys) {
      final removed = await _prefs?.remove(key) ?? false;
      if (removed) count++;
    }
    return count;
  }

  List<String> _keys() {
    return _getBridgeKeys().map((k) => k.substring(_keyPrefix.length)).toList();
  }

  bool _has(Map<String, dynamic> args) {
    final key = args['key'] as String;
    return _prefs?.containsKey('$_keyPrefix$key') ?? false;
  }

  List<String> _getBridgeKeys() {
    return _prefs?.getKeys().where((k) => k.startsWith(_keyPrefix)).toList() ??
        [];
  }

  Future<Directory> _getAppDir() async {
    return getApplicationDocumentsDirectory();
  }

  Future<File> _resolveFile(String path) async {
    final dir = await _getAppDir();
    final resolved = File('${dir.path}/$path');

    // بررسی path traversal
    final resolvedCanonical = resolved.path;
    if (!resolvedCanonical.startsWith(dir.path)) {
      throw const FileSystemException(
        'Invalid path: path traversal detected',
      );
    }
    return resolved;
  }

  Future<String> _readFile(Map<String, dynamic> args) async {
    final path = args['path'] as String;
    final file = await _resolveFile(path);
    if (!await file.exists()) {
      throw FileSystemException('File not found', path);
    }
    final encoding = args['encoding'] as String? ?? 'utf8';
    if (encoding == 'base64') {
      final bytes = await file.readAsBytes();
      return base64Encode(bytes);
    }
    return file.readAsString();
  }

  Future<bool> _writeFile(Map<String, dynamic> args) async {
    final path = args['path'] as String;
    final content = args['content'] as String;
    final encoding = args['encoding'] as String? ?? 'utf8';
    final file = await _resolveFile(path);
    await file.parent.create(recursive: true);
    if (encoding == 'base64') {
      final bytes = base64Decode(content);
      await file.writeAsBytes(bytes);
    } else {
      await file.writeAsString(content);
    }
    return true;
  }

  Future<bool> _deleteFile(Map<String, dynamic> args) async {
    final path = args['path'] as String;
    final file = await _resolveFile(path);
    if (await file.exists()) {
      await file.delete();
      return true;
    }
    return false;
  }

  Future<bool> _fileExists(Map<String, dynamic> args) async {
    final path = args['path'] as String;
    final file = await _resolveFile(path);
    return file.exists();
  }

  Future<List<Map<String, dynamic>>> _listFiles(
    Map<String, dynamic> args,
  ) async {
    final path = args['path'] as String? ?? '';
    final dir = await _getAppDir();
    final targetDir = Directory('${dir.path}/$path');
    if (!targetDir.path.startsWith(dir.path)) {
      throw const FileSystemException(
        'Invalid path: path traversal detected',
      );
    }
    if (!await targetDir.exists()) return [];
    final entities = await targetDir.list().toList();
    final results = <Map<String, dynamic>>[];
    for (final entity in entities) {
      final stat = await entity.stat();
      results.add({
        'name': entity.path.split('/').last,
        'path': entity.path.replaceFirst(dir.path, ''),
        'type': entity is Directory ? 'directory' : 'file',
        'size': stat.size,
        'modified': stat.modified.toIso8601String(),
      });
    }
    return results;
  }

  @override
  Future<ValidationResult> validateArgs(
    String method,
    Map<String, dynamic> args,
  ) async {
    switch (method) {
      case 'get':
      case 'remove':
      case 'has':
        return _validateKeyRequired(args);
      case 'set':
        return _validateSet(args);
      case 'readFile':
      case 'deleteFile':
      case 'fileExists':
        return _validatePathRequired(args);
      case 'writeFile':
        return _validateWriteFile(args);
      default:
        return ValidationResult.valid();
    }
  }

  ValidationResult _validateKeyRequired(Map<String, dynamic> args) {
    if (!args.containsKey('key') || args['key'] is! String) {
      return ValidationResult.invalid(
        'key is required and must be a string',
      );
    }
    if ((args['key'] as String).isEmpty) {
      return ValidationResult.invalid('key cannot be empty');
    }
    return ValidationResult.valid();
  }

  ValidationResult _validateSet(Map<String, dynamic> args) {
    final keyResult = _validateKeyRequired(args);
    if (!keyResult.isValid) return keyResult;
    if (!args.containsKey('value')) {
      return ValidationResult.invalid('value is required');
    }
    return ValidationResult.valid();
  }

  ValidationResult _validatePathRequired(Map<String, dynamic> args) {
    if (!args.containsKey('path') || args['path'] is! String) {
      return ValidationResult.invalid(
        'path is required and must be a string',
      );
    }
    final path = args['path'] as String;
    if (path.isEmpty) {
      return ValidationResult.invalid('path cannot be empty');
    }
    if (path.contains('..')) {
      return ValidationResult.invalid(
        'path cannot contain ".." (path traversal)',
      );
    }
    return ValidationResult.valid();
  }

  ValidationResult _validateWriteFile(Map<String, dynamic> args) {
    final pathResult = _validatePathRequired(args);
    if (!pathResult.isValid) return pathResult;
    if (!args.containsKey('content') || args['content'] is! String) {
      return ValidationResult.invalid(
        'content is required and must be a string',
      );
    }
    final encoding = args['encoding'] as String?;
    if (encoding != null && encoding != 'utf8' && encoding != 'base64') {
      return ValidationResult.invalid(
        'encoding must be "utf8" or "base64"',
      );
    }
    return ValidationResult.valid();
  }
}
```

---

## 📄 lib/plugins/storage/pubspec.yaml

```yaml
name: storage_plugin
description: Storage plugin for Flutter Native Bridge
version: 1.0.0

environment:
  sdk: ^3.0.0

dependencies:
  flutter:
    sdk: flutter
  shared_preferences: ^2.2.2
  path_provider: ^2.1.1
  plugin_engine:
    path: ../../packages/plugin_engine
```

---

## 📄 lib/screens/home_screen.dart

```dart
import 'package:flutter/material.dart';
import 'package:sweetmelon/packages/core/lib/core.dart';
import 'package:sweetmelon/packages/devtools/lib/devtools.dart';
import '../di/service_locator.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _showInspector = false;

  @override
  Widget build(BuildContext context) {
    final bridge = sl<MessageBridge>();
    final config = sl<WebViewHostConfig>();
    final assetConfig = sl<AssetServerConfig>();
    final inspector = sl<BridgeInspector>();

    return Scaffold(
      body: Stack(
        children: [
          WebViewHost(
            // ✅ حالت ۱: بارگذاری از assets/www/index.html
            loadFromAssets: true,
            config: config,
            assetConfig: assetConfig,
            bridge: bridge,
            onPageLoaded: () {
              debugPrint('✅ Page loaded successfully');
            },
            onError: (error) {
              debugPrint('❌ Load error: $error');
            },
          ),

          // Inspector panel
          if (_showInspector)
            DraggableScrollableSheet(
              initialChildSize: 0.5,
              minChildSize: 0.2,
              maxChildSize: 0.9,
              builder: (ctx, controller) => Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A2E),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      blurRadius: 20,
                    ),
                  ],
                ),
                child: BridgeInspectorWidget(inspector: inspector),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.small(
        onPressed: () => setState(() => _showInspector = !_showInspector),
        backgroundColor: const Color(0xFF6C63FF),
        child: Icon(
          _showInspector ? Icons.close : Icons.bug_report,
          color: Colors.white,
        ),
      ),
    );
  }
}
```

---

## 📄 assets/www/index.html

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
  <title>Flutter Native Bridge</title>
  <link rel="stylesheet" href="css/styles.css">
</head>
<body>
<div class="container">
  <header>
    <h1>Native Bridge</h1>
    <p>Flutter ↔ JS Bridge Demo</p>
  </header>

  <div class="progress" id="progress"></div>

  <div class="card">
    <div class="card-title">📷 Camera Plugin</div>
    <div class="btn-grid">
      <button onclick="testTakePhoto()">Take Photo</button>
      <button onclick="testGallery()">Pick Gallery</button>
    </div>
  </div>

  <div class="card">
    <div class="card-title">💾 Storage Plugin</div>
    <div class="btn-grid">
      <button onclick="testSetStorage()">Set Value</button>
      <button onclick="testGetStorage()">Get Value</button>
      <button onclick="testListKeys()">List Keys</button>
      <button onclick="testRemove()">Remove</button>
    </div>
  </div>

  <div class="card">
    <div class="card-title">📍 Geolocation Plugin</div>
    <div class="btn-grid">
      <button onclick="testLocation()">Get Location</button>
      <button onclick="testPermission()">Check Permission</button>
    </div>
  </div>

  <div class="card">
    <div class="card-title">⚡ Batch & Advanced</div>
    <div class="btn-grid">
      <button onclick="testBatch()">Batch Request</button>
      <button onclick="testParallel()">Parallel Calls</button>
      <button onclick="testTimeout()">Test Timeout</button>
      <button onclick="clearLog()">Clear Log</button>
    </div>
  </div>

  <div class="status-bar">
    <div class="status-item">Requests: <span id="reqCount">0</span></div>
    <div class="status-item">Errors: <span id="errCount">0</span></div>
    <div class="status-item">Pending: <span id="pendCount">0</span></div>
  </div>

  <div class="card" style="margin-top: 16px">
    <div class="card-title">📋 Console Log</div>
    <div class="log-container" id="log"></div>
  </div>
</div>

<script src="js/app.js"></script>
</body>
</html>
```

---

## 📄 assets/www/css/styles.css

```css
* {
  box-sizing: border-box;
  margin: 0;
  padding: 0;
}

body {
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
  background: #0a0a1a;
  color: #e0e0e0;
  min-height: 100vh;
  -webkit-tap-highlight-color: transparent;
  -webkit-text-size-adjust: 100%;
}

.container {
  max-width: 600px;
  margin: 0 auto;
  padding: 20px;
  padding-bottom: 80px;
}

header {
  text-align: center;
  padding: 30px 0 20px;
}

header h1 {
  font-size: 24px;
  background: linear-gradient(135deg, #6C63FF, #03DAC6);
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
  background-clip: text;
  font-weight: 800;
}

header p {
  color: #888;
  font-size: 13px;
  margin-top: 8px;
}

.card {
  background: #1a1a2e;
  border: 1px solid #2a2a4a;
  border-radius: 12px;
  padding: 20px;
  margin-bottom: 16px;
}

.card-title {
  font-size: 14px;
  font-weight: 700;
  color: #6C63FF;
  text-transform: uppercase;
  letter-spacing: 1px;
  margin-bottom: 16px;
  display: flex;
  align-items: center;
  gap: 8px;
}

.btn-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 10px;
}

button {
  background: linear-gradient(135deg, rgba(108, 99, 255, 0.13), rgba(108, 99, 255, 0.27));
  border: 1px solid rgba(108, 99, 255, 0.4);
  color: #c0b8ff;
  padding: 12px 16px;
  border-radius: 8px;
  font-size: 13px;
  cursor: pointer;
  transition: all 0.2s;
  font-weight: 600;
  -webkit-appearance: none;
}

button:active {
  transform: scale(0.97);
  background: linear-gradient(135deg, rgba(108, 99, 255, 0.25), rgba(108, 99, 255, 0.4));
}

.log-container {
  background: #0d0d1f;
  border: 1px solid #2a2a4a;
  border-radius: 8px;
  padding: 12px;
  height: 200px;
  overflow-y: auto;
  font-family: 'Courier New', monospace;
  font-size: 11px;
  -webkit-overflow-scrolling: touch;
}

.log-entry {
  padding: 3px 0;
  border-bottom: 1px solid #1a1a2e;
  line-height: 1.6;
  word-break: break-all;
}

.log-entry.success { color: #4CAF50; }
.log-entry.error { color: #f44336; }
.log-entry.info { color: #2196F3; }
.log-entry.pending { color: #FF9800; }

.status-bar {
  display: flex;
  gap: 16px;
  font-size: 12px;
  color: #888;
  margin-top: 16px;
  padding: 12px;
  background: #1a1a2e;
  border-radius: 8px;
}

.status-item span {
  color: #03DAC6;
  font-weight: bold;
}

.progress {
  height: 2px;
  background: #6C63FF;
  width: 0%;
  transition: width 0.3s;
  border-radius: 2px;
  margin-bottom: 16px;
}
```

---

## 📄 assets/www/js/app.js

```javascript
(function() {
  'use strict';

  var errorCount = 0;

  function log(msg, type) {
    type = type || 'info';
    var container = document.getElementById('log');
    if (!container) return;

    var entry = document.createElement('div');
    entry.className = 'log-entry ' + type;

    var now = new Date();
    var time = now.toLocaleTimeString('en-US', {
      hour12: false,
      hour: '2-digit',
      minute: '2-digit',
      second: '2-digit'
    });

    entry.textContent = '[' + time + '] ' + msg;
    container.insertBefore(entry, container.firstChild);

    if (type === 'error') errorCount++;

    // حداکثر ۲۰۰ ردیف log
    while (container.children.length > 200) {
      container.removeChild(container.lastChild);
    }

    updateStats();
  }

  function updateStats() {
    var info = {};
    try {
      if (window.Native && window.Native.info) {
        info = window.Native.info();
      }
    } catch (e) {}

    var reqEl = document.getElementById('reqCount');
    var errEl = document.getElementById('errCount');
    var pendEl = document.getElementById('pendCount');

    if (reqEl) reqEl.textContent = info.totalRequests || 0;
    if (errEl) errEl.textContent = errorCount;
    if (pendEl) pendEl.textContent = info.pendingRequests || 0;
  }

  function showProgress(show) {
    var el = document.getElementById('progress');
    if (el) el.style.width = show ? '60%' : '0%';
  }

  function callPlugin(plugin, method, args, label) {
    args = args || {};
    var display = label || (plugin + '.' + method);

    if (!window.Native) {
      log('Bridge not available yet', 'error');
      return Promise.reject('Bridge not available');
    }

    log('→ Calling ' + display + '...', 'pending');
    showProgress(true);

    return Native.call({ plugin: plugin, method: method, args: args })
      .then(function(result) {
        var t = JSON.stringify(result);
        if (t && t.length > 120) t = t.substring(0, 120) + '...';
        log('✓ ' + display + ': ' + t, 'success');
        return result;
      })
      .catch(function(err) {
        var msg = err.message || err.code || JSON.stringify(err);
        log('✗ ' + display + ': ' + msg, 'error');
        throw err;
      })
      .finally(function() {
        showProgress(false);
        updateStats();
      });
  }

  // ----- Camera -----
  window.testTakePhoto = function() {
    callPlugin('camera', 'takePhoto', { quality: 80 });
  };

  window.testGallery = function() {
    callPlugin('camera', 'pickFromGallery', { multiple: false });
  };

  // ----- Storage -----
  window.testSetStorage = function() {
    callPlugin('storage', 'set', {
      key: 'test_key',
      value: {
        timestamp: Date.now(),
        message: 'Hello from JS!',
        data: [1, 2, 3]
      }
    });
  };

  window.testGetStorage = function() {
    callPlugin('storage', 'get', { key: 'test_key' });
  };

  window.testListKeys = function() {
    callPlugin('storage', 'keys', {});
  };

  window.testRemove = function() {
    callPlugin('storage', 'remove', { key: 'test_key' });
  };

  // ----- Geolocation -----
  window.testLocation = function() {
    callPlugin('geolocation', 'getCurrentPosition', { accuracy: 'high' });
  };

  window.testPermission = function() {
    callPlugin('geolocation', 'checkPermission', {});
  };

  // ----- Batch & Advanced -----
  window.testBatch = function() {
    if (!window.Native) {
      log('Bridge not available', 'error');
      return;
    }

    log('→ Sending batch request...', 'pending');
    showProgress(true);

    Native.batch([
      { plugin: 'storage', method: 'keys', args: {} },
      { plugin: 'geolocation', method: 'checkPermission', args: {} },
      { plugin: 'camera', method: 'getInfo', args: {} }
    ], { parallel: true })
      .then(function(results) {
        log('✓ Batch complete: ' + results.length + ' results', 'success');
      })
      .catch(function(err) {
        log('✗ Batch: ' + JSON.stringify(err), 'error');
      })
      .finally(function() {
        showProgress(false);
        updateStats();
      });
  };

  window.testParallel = function() {
    if (!window.Native) {
      log('Bridge not available', 'error');
      return;
    }

    log('→ Running 5 parallel calls...', 'pending');

    var promises = [];
    for (var i = 0; i < 5; i++) {
      (function(idx) {
        promises.push(
          Native.call({
            plugin: 'storage',
            method: 'get',
            args: { key: 'key_' + idx }
          })
            .then(function(r) { return '✓ key_' + idx; })
            .catch(function(e) { return '✗ key_' + idx; })
        );
      })(i);
    }

    Promise.allSettled(promises).then(function(results) {
      results.forEach(function(r) {
        log(r.value || r.reason, 'info');
      });
      updateStats();
    });
  };

  window.testTimeout = function() {
    if (!window.Native) {
      log('Bridge not available', 'error');
      return;
    }

    log('→ Testing with 1ms timeout...', 'pending');

    Native.call({
      plugin: 'geolocation',
      method: 'getCurrentPosition',
      args: {},
      timeout: 1
    })
      .then(function() {
        log('? Unexpectedly succeeded', 'info');
      })
      .catch(function(err) {
        if (err.code === 'TIMEOUT') {
          log('✓ Timeout handled correctly', 'success');
        } else {
          log('? Unexpected error: ' + JSON.stringify(err), 'error');
        }
      })
      .finally(function() {
        updateStats();
      });
  };

  window.clearLog = function() {
    var container = document.getElementById('log');
    if (container) container.innerHTML = '';
    errorCount = 0;
    updateStats();
  };

  // ----- Event listener -----
  function setupEventListeners() {
    if (window.Native && window.Native.on) {
      Native.on('geolocation.position', function(data) {
        log('📍 Position: ' + data.latitude.toFixed(4) + ', ' + data.longitude.toFixed(4), 'info');
      });

      Native.on('geolocation.error', function(data) {
        log('📍 Error: ' + data.message, 'error');
      });

      Native.on('bridge_event', function(data) {
        log('🔔 Event: ' + JSON.stringify(data), 'info');
      });
    }
  }

  // ----- Init -----
  function init() {
    // منتظر bridge آماده شدن
    var attempts = 0;
    var maxAttempts = 50;

    var check = setInterval(function() {
      attempts++;

      if (window.Native) {
        clearInterval(check);
        setupEventListeners();
        log('Native Bridge initialized (' + attempts * 100 + 'ms)', 'success');
        updateStats();
      } else if (attempts >= maxAttempts) {
        clearInterval(check);
        log('Bridge initialization timeout', 'error');
      }
    }, 100);
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
  } else {
    init();
  }

})();
```

---

## خلاصه تغییرات

### باگ‌های رفع شده:

| # | باگ | فایل | رفع |
|---|-----|------|-----|
| 1 | `_isReady` هرگز reset نمی‌شد | `message_bridge.dart` | اضافه شدن `resetBridgeState()` |
| 2 | `watchPosition` هیچ event ارسال نمی‌کرد | `geolocation_plugin.dart` | اضافه شدن `eventEmitter` |
| 3 | `FileSink` به فایل نمی‌نوشت | `logger.dart` | حذف `FileSink` ناقص، استفاده از `DebugConsoleSink` |
| 4 | Race condition در `ServiceLocator` | `service_locator.dart` | ترتیب instantiation اصلاح شد |
| 5 | XSS در JS injection | `message_bridge.dart` | اضافه شدن `_sanitizeJsonForJs()` |
| 6 | `_pendingJsMessages` بی‌نهایت رشد | `message_bridge.dart` | حد `_maxPendingMessages = 200` |
| 7 | Storage cache مشکل‌دار | `plugin_manager.dart` | تشخیص mutation methods، invalidation |
| 8 | Type cast خطرناک بدون بررسی | `message_bridge.dart` | بررسی `plugin` و `method` قبل از parse |
| 9 | `executeBatch` parallel خطاها | `plugin_manager.dart` | allSettled pattern |
| 10 | `BridgeInspector` بعد dispose | `bridge_inspector.dart` | اضافه شدن `_disposed` flag |
| 11 | Permission cache بدون TTL | `permission_manager.dart` | اضافه شدن `cacheTtl` و `_cacheTimestamps` |
| 12 | `WebViewHostConfig` بلااستفاده | `webview_host.dart` | استفاده از config |
| 13 | `Plugin.initialize` دوباره اجرا | `plugin_interface.dart` | Guard `if (_initialized) return` |
| 14 | `print` در production | `logger.dart` | `debugPrint` + `kReleaseMode` check |
| 15 | Missing permissions در AndroidManifest | `AndroidManifest.xml` | همه permissions اضافه شد |

### نقاط ضعف رفع شده:

| # | ضعف | رفع |
|---|------|-----|
| 1 | `StaticPermissionProvider` در production | `NativePermissionProvider` با `permission_handler` |
| 2 | بدون error boundary در WebView | Error overlay و Retry button |
| 3 | Logger از `print` استفاده می‌کرد | `DebugConsoleSink` با `debugPrint` |

### فایل‌های جدید:

| فایل | توضیح |
|------|-------|
| `asset_server.dart` | HTTP server محلی برای serve کردن فایل‌های www |
| `assets/www/index.html` | فایل HTML اصلی (مسیر ثابت) |
| `assets/www/css/styles.css` | فایل CSS جداگانه |
| `assets/www/js/app.js` | فایل JS جداگانه |
| `file_paths.xml` | Android FileProvider config |

### نحوه استفاده با Angular:

```bash
# 1. Build Angular
ng build --configuration production --output-path /path/to/flutter/assets/www --base-href ./

# 2. حالا مسیر ثابت assets/www/index.html آماده است
# Flutter خودش فایل‌ها رو extract و serve می‌کنه
```
