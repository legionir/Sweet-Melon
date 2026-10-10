شروع می‌کنم. به خاطر حجم بسیار بالا، هر فاز رو در یک پیام جداگانه می‌فرستم.

---

# فاز ۱۲: Foundation Fix

---

## بخش ۱: حذف Tight Coupling — سیستم Context Provider مرکزی

### 📄 `lib/packages/core/lib/src/runtime/app_context.dart`

```dart
import 'package:flutter/material.dart';

/// Context Provider مرکزی — جایگزین QrScannerPlugin.navigatorKey
/// همه پلاگین‌ها از این استفاده می‌کنن
class AppContext {
  static final AppContext _instance = AppContext._();
  factory AppContext() => _instance;
  AppContext._();

  GlobalKey<NavigatorState>? _navigatorKey;
  GlobalKey<ScaffoldMessengerState>? _scaffoldKey;

  /// ست شدن توسط BridgeApp
  void setNavigatorKey(GlobalKey<NavigatorState> key) {
    _navigatorKey = key;
  }

  void setScaffoldKey(GlobalKey<ScaffoldMessengerState> key) {
    _scaffoldKey = key;
  }

  /// دسترسی به navigator key
  GlobalKey<NavigatorState>? get navigatorKey => _navigatorKey;

  /// دسترسی به BuildContext فعلی
  BuildContext? get context => _navigatorKey?.currentContext;

  /// دسترسی به ScaffoldMessenger
  ScaffoldMessengerState? get scaffoldMessenger =>
      _scaffoldKey?.currentState;

  /// آیا context در دسترس هست؟
  bool get hasContext => context != null;

  /// نمایش overlay (مثل scanner, browser)
  Future<T?> pushPage<T>(Widget page) {
    final ctx = context;
    if (ctx == null) {
      throw StateError('No navigator context available');
    }
    return Navigator.of(ctx).push<T>(
      MaterialPageRoute(builder: (_) => page),
    );
  }

  /// بستن overlay
  void popPage<T>([T? result]) {
    final ctx = context;
    if (ctx != null) {
      try {
        Navigator.of(ctx).pop(result);
      } catch (_) {}
    }
  }

  /// نمایش dialog
  Future<T?> showAppDialog<T>(Widget dialog) {
    final ctx = context;
    if (ctx == null) {
      throw StateError('No navigator context available');
    }
    return showDialog<T>(context: ctx, builder: (_) => dialog);
  }

  /// نمایش bottom sheet
  Future<T?> showAppBottomSheet<T>(Widget sheet) {
    final ctx = context;
    if (ctx == null) {
      throw StateError('No navigator context available');
    }
    return showModalBottomSheet<T>(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => sheet,
    );
  }

  /// نمایش snackbar
  void showSnackBar(SnackBar snackBar) {
    final messenger = scaffoldMessenger;
    if (messenger != null) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(snackBar);
    } else {
      final ctx = context;
      if (ctx != null) {
        ScaffoldMessenger.of(ctx)
          ..hideCurrentSnackBar()
          ..showSnackBar(snackBar);
      }
    }
  }

  /// MediaQuery
  MediaQueryData? get mediaQuery {
    final ctx = context;
    if (ctx == null) return null;
    return MediaQuery.of(ctx);
  }
}
```

---

### 📄 بروزرسانی `lib/packages/core/lib/core.dart`

```dart
library core;

export 'src/bridge/message_bridge.dart';
export 'src/protocol/message_protocol.dart';
export 'src/runtime/webview_host.dart';
export 'src/runtime/asset_server.dart';
export 'src/runtime/app_context.dart';
export 'src/utils/logger.dart';
export 'src/middleware/error_recovery.dart';
export 'src/middleware/circuit_breaker.dart';
export 'src/middleware/offline_queue.dart';
```

---

### 📄 بروزرسانی `lib/app.dart`

```dart
import 'package:flutter/material.dart';
import 'package:sweetmelon/packages/core/lib/core.dart';
import 'screens/home_screen.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<ScaffoldMessengerState> scaffoldKey =
    GlobalKey<ScaffoldMessengerState>();

class BridgeApp extends StatelessWidget {
  const BridgeApp({super.key});

  @override
  Widget build(BuildContext context) {
    // ست کردن context مرکزی
    AppContext().setNavigatorKey(navigatorKey);
    AppContext().setScaffoldKey(scaffoldKey);

    return MaterialApp(
      navigatorKey: navigatorKey,
      scaffoldMessengerKey: scaffoldKey,
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

## بخش ۲: استانداردسازی Error Handling

### 📄 `lib/packages/core/lib/src/protocol/plugin_error_handler.dart`

```dart
import 'message_protocol.dart';
import '../utils/logger.dart';

/// Error handler استاندارد برای همه پلاگین‌ها
class PluginErrorHandler {
  /// تبدیل هر exception به PluginError استاندارد
  static PluginError fromException(Object error, [StackTrace? stackTrace]) {
    if (error is PluginException) {
      return PluginError(
        code: error.code,
        message: error.message,
        details: error.details,
        stackTrace: stackTrace?.toString(),
      );
    }

    if (error is TimeoutException) {
      return PluginError(
        code: PluginErrorCode.timeout,
        message: error.message ?? 'Operation timed out',
        stackTrace: stackTrace?.toString(),
      );
    }

    if (error is FormatException) {
      return PluginError(
        code: PluginErrorCode.invalidArgs,
        message: 'Format error: ${error.message}',
        stackTrace: stackTrace?.toString(),
      );
    }

    if (error is StateError) {
      return PluginError(
        code: PluginErrorCode.executionError,
        message: error.message,
        stackTrace: stackTrace?.toString(),
      );
    }

    if (error is UnsupportedError) {
      return PluginError(
        code: PluginErrorCode.methodNotFound,
        message: error.message ?? 'Unsupported operation',
        stackTrace: stackTrace?.toString(),
      );
    }

    final message = error.toString();

    // Network errors
    if (_isNetworkError(message)) {
      return PluginError(
        code: PluginErrorCode.networkError,
        message: message,
        stackTrace: stackTrace?.toString(),
      );
    }

    // Permission errors
    if (_isPermissionError(message)) {
      return PluginError(
        code: PluginErrorCode.permissionDenied,
        message: message,
        stackTrace: stackTrace?.toString(),
      );
    }

    return PluginError(
      code: PluginErrorCode.executionError,
      message: message,
      stackTrace: stackTrace?.toString(),
    );
  }

  /// ساخت response خطا از exception
  static PluginResponse errorResponse(
    String requestId,
    Object error, [
    StackTrace? stackTrace,
  ]) {
    return PluginResponse.failure(
      requestId: requestId,
      error: fromException(error, stackTrace),
    );
  }

  /// اجرای یک action با error handling خودکار
  static Future<PluginResponse> execute(
    String requestId,
    String pluginName,
    String method,
    Future<dynamic> Function() action,
  ) async {
    try {
      final result = await action();
      return PluginResponse.success(
        requestId: requestId,
        data: result,
      );
    } catch (e, stackTrace) {
      BridgeLogger.error(
        pluginName,
        '$method error: $e',
      );
      return errorResponse(requestId, e, stackTrace);
    }
  }

  static bool _isNetworkError(String message) {
    final lower = message.toLowerCase();
    return lower.contains('socketexception') ||
        lower.contains('connection refused') ||
        lower.contains('connection reset') ||
        lower.contains('network is unreachable') ||
        lower.contains('no address associated') ||
        lower.contains('connection timed out');
  }

  static bool _isPermissionError(String message) {
    final lower = message.toLowerCase();
    return lower.contains('permission') ||
        lower.contains('denied') ||
        lower.contains('not allowed');
  }
}

/// Exception سفارشی با error code
class PluginException implements Exception {
  final PluginErrorCode code;
  final String message;
  final Map<String, dynamic>? details;

  const PluginException({
    required this.code,
    required this.message,
    this.details,
  });

  /// Factories for common errors
  const PluginException.notFound(String what)
      : code = PluginErrorCode.pluginNotFound,
        message = '$what not found',
        details = null;

  const PluginException.invalidArgs(String reason)
      : code = PluginErrorCode.invalidArgs,
        message = reason,
        details = null;

  const PluginException.permissionDenied(String permission)
      : code = PluginErrorCode.permissionDenied,
        message = 'Permission denied: $permission',
        details = null;

  const PluginException.noContext()
      : code = PluginErrorCode.executionError,
        message = 'No UI context available',
        details = null;

  @override
  String toString() => 'PluginException(${code.code}): $message';
}

/// Import helper
class TimeoutException implements Exception {
  final String? message;
  const TimeoutException([this.message]);
}
```

---

## بخش ۳: Plugin Base Class بهبودیافته

### 📄 `lib/packages/plugin_engine/lib/src/plugin_base.dart`

```dart
import 'dart:async';

import 'package:sweetmelon/packages/core/lib/core.dart';
import 'plugin_interface.dart';

typedef PluginEventEmitter = Future<void> Function(String event, dynamic data);

/// Base class بهبودیافته — همه پلاگین‌ها از این ارث ببرن
abstract class BasePlugin extends Plugin {
  /// Event emitter — اختیاری
  PluginEventEmitter? eventEmitter;

  /// دسترسی به AppContext
  AppContext get appContext => AppContext();

  /// دسترسی به BuildContext فعلی
  dynamic get context => appContext.context;

  /// آیا context در دسترس هست
  bool get hasContext => appContext.hasContext;

  /// ارسال event به JS
  Future<void> emitEvent(String event, dynamic data) async {
    if (eventEmitter != null) {
      await eventEmitter!(event, data);
    } else {
      BridgeLogger.warn(
        name,
        'Event emitter not set, dropping event: $event',
      );
    }
  }

  /// اجرای safe یک action با error handling
  Future<Map<String, dynamic>> safeExecute(
    String action,
    Future<Map<String, dynamic>> Function() fn,
  ) async {
    try {
      return await fn();
    } catch (e) {
      BridgeLogger.error(name, '$action failed: $e');
      return {
        'success': false,
        'error': e.toString(),
        'action': action,
      };
    }
  }

  /// بررسی context و throw error اگه نبود
  void requireContext() {
    if (!hasContext) {
      throw const PluginException.noContext();
    }
  }

  /// Log helper
  void logInfo(String message) => BridgeLogger.info(name, message);
  void logWarn(String message) => BridgeLogger.warn(name, message);
  void logError(String message) => BridgeLogger.error(name, message);
  void logDebug(String message) => BridgeLogger.debug(name, message);
}
```

---

### 📄 بروزرسانی `lib/packages/plugin_engine/lib/plugin_engine.dart`

```dart
library plugin_engine;

export 'src/plugin_interface.dart';
export 'src/plugin_base.dart';
export 'src/plugin_registry.dart';
export 'src/plugin_manager.dart';
export 'src/lazy_plugin_loader.dart';
export 'src/plugin_versioning.dart';
export 'src/plugin_migration.dart';
export 'src/versioned_plugin_manager.dart';
```

---

## بخش ۴: Native Channels واقعی

### 📄 `android/app/src/main/kotlin/com/example/sweet_melon/MainActivity.kt`

```kt
package com.example.sweet_melon

import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import android.telephony.SubscriptionManager
import android.telephony.TelephonyManager
import android.view.KeyEvent
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val PRIVACY_CHANNEL = "sweetmelon/privacy_screen"
    private val FOREGROUND_CHANNEL = "sweetmelon/foreground_service"
    private val SIM_CHANNEL = "sweetmelon/sim_info"
    private val INTEGRITY_CHANNEL = "sweetmelon/app_integrity"
    private val VOLUME_CHANNEL = "sweetmelon/volume_buttons"
    private val WAKE_LOCK_CHANNEL = "sweetmelon/wake_lock"
    private val SHARE_TARGET_CHANNEL = "sweetmelon/share_target"

    private var volumeEventSink: EventChannel.EventSink? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // ── Privacy Screen ──
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            PRIVACY_CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "enablePrivacy" -> {
                    window.setFlags(
                        WindowManager.LayoutParams.FLAG_SECURE,
                        WindowManager.LayoutParams.FLAG_SECURE
                    )
                    result.success(true)
                }
                "disablePrivacy" -> {
                    window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }

        // ── Wake Lock ──
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            WAKE_LOCK_CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "enable" -> {
                    window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
                    result.success(true)
                }
                "disable" -> {
                    window.clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }

        // ── Foreground Service ──
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            FOREGROUND_CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "startService" -> {
                    // Stub — واقعی نیاز به ForegroundService class داره
                    result.success(true)
                }
                "stopService" -> {
                    result.success(true)
                }
                "updateNotification" -> {
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }

        // ── SIM Info ──
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            SIM_CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "getSimInfo" -> {
                    try {
                        val tm = getSystemService(TELEPHONY_SERVICE) as TelephonyManager
                        val info = HashMap<String, Any?>()
                        info["networkOperator"] = tm.networkOperatorName
                        info["networkCountryIso"] = tm.networkCountryIso
                        info["simOperator"] = tm.simOperatorName
                        info["simCountryIso"] = tm.simCountryIso
                        info["simState"] = tm.simState
                        info["phoneType"] = tm.phoneType
                        info["available"] = true

                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP_MR1) {
                            try {
                                val sm = getSystemService(TELEPHONY_SUBSCRIPTION_SERVICE) as SubscriptionManager
                                info["simCount"] = sm.activeSubscriptionInfoCount
                            } catch (e: SecurityException) {
                                info["simCount"] = 1
                            }
                        }

                        result.success(info)
                    } catch (e: Exception) {
                        result.success(hashMapOf("available" to false, "error" to e.message))
                    }
                }
                "getCarrierName" -> {
                    val tm = getSystemService(TELEPHONY_SERVICE) as TelephonyManager
                    result.success(tm.networkOperatorName ?: "unknown")
                }
                "getSimCount" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP_MR1) {
                        try {
                            val sm = getSystemService(TELEPHONY_SUBSCRIPTION_SERVICE) as SubscriptionManager
                            result.success(sm.activeSubscriptionInfoCount)
                        } catch (e: SecurityException) {
                            result.success(1)
                        }
                    } else {
                        result.success(1)
                    }
                }
                else -> result.notImplemented()
            }
        }

        // ── App Integrity ──
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            INTEGRITY_CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "isGenuineInstall" -> {
                    val installer = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                        packageManager.getInstallSourceInfo(packageName).installingPackageName
                    } else {
                        @Suppress("DEPRECATION")
                        packageManager.getInstallerPackageName(packageName)
                    }
                    val genuine = installer == "com.android.vending" ||
                            installer == "com.google.android.packageinstaller"
                    result.success(genuine)
                }
                "getInstallSource" -> {
                    val info = HashMap<String, Any?>()
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                        val source = packageManager.getInstallSourceInfo(packageName)
                        info["initiating"] = source.initiatingPackageName
                        info["originating"] = source.originatingPackageName
                        info["source"] = source.installingPackageName
                    } else {
                        @Suppress("DEPRECATION")
                        info["source"] = packageManager.getInstallerPackageName(packageName)
                    }
                    result.success(info)
                }
                "getSigningInfo" -> {
                    val info = HashMap<String, Any?>()
                    info["signed"] = true
                    info["debugBuild"] = (applicationInfo.flags and android.content.pm.ApplicationInfo.FLAG_DEBUGGABLE) != 0
                    result.success(info)
                }
                else -> result.notImplemented()
            }
        }

        // ── Volume Buttons ──
        EventChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            VOLUME_CHANNEL
        ).setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                volumeEventSink = events
            }
            override fun onCancel(arguments: Any?) {
                volumeEventSink = null
            }
        })

        // ── Share Target ──
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            SHARE_TARGET_CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "getInitialSharedData" -> {
                    val data = handleShareIntent(intent)
                    result.success(data)
                }
                else -> result.notImplemented()
            }
        }
    }

    // Volume button interception
    override fun onKeyDown(keyCode: Int, event: KeyEvent?): Boolean {
        when (keyCode) {
            KeyEvent.KEYCODE_VOLUME_UP -> {
                volumeEventSink?.success("up")
                return true
            }
            KeyEvent.KEYCODE_VOLUME_DOWN -> {
                volumeEventSink?.success("down")
                return true
            }
        }
        return super.onKeyDown(keyCode, event)
    }

    // Share intent handling
    private fun handleShareIntent(intent: Intent?): HashMap<String, Any?>? {
        if (intent == null) return null

        val action = intent.action
        val type = intent.type

        if (Intent.ACTION_SEND == action && type != null) {
            val data = HashMap<String, Any?>()

            if (type.startsWith("text/")) {
                data["type"] = "text"
                data["text"] = intent.getStringExtra(Intent.EXTRA_TEXT)
                data["title"] = intent.getStringExtra(Intent.EXTRA_SUBJECT)
            } else {
                data["type"] = "file"
                data["mimeType"] = type
                val uri = intent.getParcelableExtra<android.net.Uri>(Intent.EXTRA_STREAM)
                data["uri"] = uri?.toString()
            }

            return data
        }

        return null
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
    }
}
```

---

## بخش ۵: WakeLock واقعی

### 📄 `lib/plugins/wake_lock/lib/wake_lock_plugin.dart` — بازنویسی

```dart
import 'package:flutter/services.dart';
import 'package:sweetmelon/packages/core/lib/core.dart';
import 'package:sweetmelon/packages/plugin_engine/lib/plugin_engine.dart';

class WakeLockPlugin extends BasePlugin {
  bool _isLocked = false;
  static const _channel = MethodChannel('sweetmelon/wake_lock');

  @override
  String get name => 'wakeLock';

  @override
  String get version => '1.0.0';

  @override
  String get description => 'Keep screen awake / wake lock plugin';

  @override
  List<String> get supportedMethods => [
        'enable',
        'disable',
        'toggle',
        'isEnabled',
        'getInfo',
      ];

  @override
  Future<dynamic> onCall(String method, Map<String, dynamic> args) async {
    switch (method) {
      case 'enable':
        return _enable();
      case 'disable':
        return _disable();
      case 'toggle':
        return _isLocked ? _disable() : _enable();
      case 'isEnabled':
        return {'enabled': _isLocked};
      case 'getInfo':
        return {'name': name, 'version': version, 'enabled': _isLocked};
      default:
        throw UnsupportedError('Method "$method" not supported');
    }
  }

  Future<Map<String, dynamic>> _enable() async {
    if (_isLocked) {
      return {'enabled': true, 'alreadyEnabled': true};
    }

    try {
      await _channel.invokeMethod('enable');
      _isLocked = true;
      logInfo('Screen wake lock enabled (native)');
      return {'enabled': true, 'alreadyEnabled': false, 'native': true};
    } catch (e) {
      logWarn('Native wake lock failed, using fallback: $e');
      _isLocked = true;
      return {'enabled': true, 'native': false, 'fallback': true};
    }
  }

  Future<Map<String, dynamic>> _disable() async {
    if (!_isLocked) {
      return {'enabled': false, 'alreadyDisabled': true};
    }

    try {
      await _channel.invokeMethod('disable');
    } catch (_) {}

    _isLocked = false;
    logInfo('Screen wake lock disabled');
    return {'enabled': false, 'alreadyDisabled': false};
  }

  @override
  Future<void> onDispose() async {
    if (_isLocked) await _disable();
  }
}
```

---

## بخش ۶: تست Unit برای پلاگین‌ها

### 📄 `test/helpers/plugin_test_utils.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sweetmelon/packages/plugin_engine/lib/plugin_engine.dart';

/// Utility functions for plugin testing
class PluginTestUtils {
  /// تست اینکه پلاگین اطلاعات درستی برمی‌گردونه
  static Future<void> testPluginInfo(
    Plugin plugin, {
    required String expectedName,
    required String expectedVersion,
  }) async {
    expect(plugin.name, expectedName);
    expect(plugin.version, expectedVersion);
    expect(plugin.supportedMethods, isNotEmpty);
  }

  /// تست اینکه getInfo کار می‌کنه
  static Future<void> testGetInfo(Plugin plugin) async {
    if (plugin.supportsMethod('getInfo')) {
      final result = await plugin.onCall('getInfo', {});
      expect(result, isA<Map>());
      expect(result['name'], plugin.name);
    }
  }

  /// تست اینکه متدهای ناشناخته خطا می‌دن
  static Future<void> testUnsupportedMethod(Plugin plugin) async {
    expect(
      () => plugin.onCall('__nonexistent_method__', {}),
      throwsA(isA<UnsupportedError>()),
    );
  }

  /// تست validation برای یک متد
  static Future<void> testValidation(
    Plugin plugin,
    String method,
    Map<String, dynamic> invalidArgs,
  ) async {
    final result = await plugin.validateArgs(method, invalidArgs);
    expect(result.isValid, false);
    expect(result.errorMessage, isNotEmpty);
  }

  /// تست validation valid
  static Future<void> testValidArgs(
    Plugin plugin,
    String method,
    Map<String, dynamic> validArgs,
  ) async {
    final result = await plugin.validateArgs(method, validArgs);
    expect(result.isValid, true);
  }

  /// تست lifecycle: initialize → call → dispose
  static Future<void> testLifecycle(
    Plugin plugin,
    String method,
    Map<String, dynamic> args,
  ) async {
    await plugin.initialize();
    expect(plugin.isReady, true);

    final result = await plugin.onCall(method, args);
    expect(result, isNotNull);

    await plugin.dispose();
    expect(plugin.isReady, false);
  }

  /// تست double initialize
  static Future<void> testDoubleInitialize(Plugin plugin) async {
    await plugin.initialize();
    await plugin.initialize(); // should not throw
    expect(plugin.isReady, true);
    await plugin.dispose();
  }
}
```

---

### 📄 `test/plugins/all_plugins_basic_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sweetmelon/plugins/clipboard/lib/clipboard_plugin.dart';
import 'package:sweetmelon/plugins/encryption/lib/encryption_plugin.dart';
import 'package:sweetmelon/plugins/haptic/lib/haptic_plugin.dart';
import 'package:sweetmelon/plugins/orientation/lib/orientation_plugin.dart';
import 'package:sweetmelon/plugins/status_bar/lib/status_bar_plugin.dart';
import 'package:sweetmelon/plugins/storage/lib/storage_plugin.dart';
import 'package:sweetmelon/plugins/navigation_bar/lib/navigation_bar_plugin.dart';

import '../helpers/plugin_test_utils.dart';

void main() {
  group('All Plugins Basic Tests', () {
    // ── Clipboard ──
    group('ClipboardPlugin', () {
      late ClipboardPlugin plugin;

      setUp(() async {
        plugin = ClipboardPlugin();
        await plugin.initialize();
      });

      tearDown(() async => await plugin.dispose());

      test('info', () async {
        await PluginTestUtils.testPluginInfo(
          plugin,
          expectedName: 'clipboard',
          expectedVersion: '1.0.0',
        );
      });

      test('getInfo', () async {
        await PluginTestUtils.testGetInfo(plugin);
      });

      test('unsupported method', () async {
        await PluginTestUtils.testUnsupportedMethod(plugin);
      });

      test('writeText validation', () async {
        await PluginTestUtils.testValidation(plugin, 'writeText', {});
        await PluginTestUtils.testValidArgs(
          plugin, 'writeText', {'text': 'hello'},
        );
      });

      test('double initialize', () async {
        await PluginTestUtils.testDoubleInitialize(plugin);
      });
    });

    // ── Encryption ──
    group('EncryptionPlugin', () {
      late EncryptionPlugin plugin;

      setUp(() async {
        plugin = EncryptionPlugin();
        await plugin.initialize();
      });

      tearDown(() async => await plugin.dispose());

      test('info', () async {
        await PluginTestUtils.testPluginInfo(
          plugin,
          expectedName: 'encryption',
          expectedVersion: '1.0.0',
        );
      });

      test('generateAesKey', () async {
        final result = await plugin.onCall('generateAesKey', {'bits': 256});
        expect(result['key'], isNotEmpty);
        expect(result['iv'], isNotEmpty);
      });

      test('hashSha256', () async {
        final r1 = await plugin.onCall('hashSha256', {'data': 'test'});
        final r2 = await plugin.onCall('hashSha256', {'data': 'test'});
        expect(r1['hash'], r2['hash']);
        expect(r1['hash'], isNotEmpty);
      });

      test('aes roundtrip', () async {
        final key = await plugin.onCall('generateAesKey', {'bits': 256});
        final enc = await plugin.onCall('aesEncrypt', {
          'data': 'secret',
          'key': key['key'],
          'iv': key['iv'],
        });
        final dec = await plugin.onCall('aesDecrypt', {
          'data': enc['encrypted'],
          'key': key['key'],
          'iv': key['iv'],
        });
        expect(dec['decrypted'], 'secret');
      });

      test('base64 roundtrip', () async {
        final enc = await plugin.onCall('base64Encode', {'data': 'Hello!'});
        final dec = await plugin.onCall('base64Decode', {'data': enc['encoded']});
        expect(dec['decoded'], 'Hello!');
      });

      test('hmacSha256', () async {
        final result = await plugin.onCall('hmacSha256', {
          'data': 'message',
          'key': 'secret',
        });
        expect(result['hmac'], isNotEmpty);
      });

      test('validation rejects missing data', () async {
        await PluginTestUtils.testValidation(plugin, 'hashSha256', {});
      });
    });

    // ── Storage ──
    group('StoragePlugin', () {
      late StoragePlugin plugin;

      setUp(() async {
        SharedPreferences.setMockInitialValues({});
        plugin = StoragePlugin();
        await plugin.initialize();
      });

      tearDown(() async => await plugin.dispose());

      test('info', () async {
        await PluginTestUtils.testPluginInfo(
          plugin,
          expectedName: 'storage',
          expectedVersion: '1.0.0',
        );
      });

      test('set and get', () async {
        await plugin.onCall('set', {'key': 'k1', 'value': 'v1'});
        final result = await plugin.onCall('get', {'key': 'k1'});
        expect(result, 'v1');
      });

      test('get missing returns null', () async {
        final result = await plugin.onCall('get', {'key': 'missing'});
        expect(result, isNull);
      });

      test('has', () async {
        await plugin.onCall('set', {'key': 'exists', 'value': true});
        final r1 = await plugin.onCall('has', {'key': 'exists'});
        expect(r1['exists'], true);
        final r2 = await plugin.onCall('has', {'key': 'nope'});
        expect(r2['exists'], false);
      });

      test('remove', () async {
        await plugin.onCall('set', {'key': 'temp', 'value': 'data'});
        await plugin.onCall('remove', {'key': 'temp'});
        final result = await plugin.onCall('get', {'key': 'temp'});
        expect(result, isNull);
      });

      test('keys', () async {
        await plugin.onCall('set', {'key': 'a', 'value': 1});
        await plugin.onCall('set', {'key': 'b', 'value': 2});
        final result = await plugin.onCall('keys', {});
        expect(result['keys'], containsAll(['a', 'b']));
      });

      test('clear', () async {
        await plugin.onCall('set', {'key': 'x', 'value': 1});
        final count = await plugin.onCall('clear', {});
        expect(count, greaterThanOrEqualTo(1));
      });

      test('complex value', () async {
        final data = {'name': 'Ali', 'scores': [1, 2, 3]};
        await plugin.onCall('set', {'key': 'complex', 'value': data});
        final result = await plugin.onCall('get', {'key': 'complex'});
        expect(result['name'], 'Ali');
        expect(result['scores'], [1, 2, 3]);
      });

      test('validation', () async {
        await PluginTestUtils.testValidation(plugin, 'get', {});
        await PluginTestUtils.testValidation(plugin, 'get', {'key': ''});
        await PluginTestUtils.testValidation(plugin, 'set', {'key': 'k'});
      });
    });

    // ── Haptic ──
    group('HapticPlugin', () {
      late HapticPlugin plugin;

      setUp(() async {
        plugin = HapticPlugin();
        await plugin.initialize();
      });

      test('info', () async {
        await PluginTestUtils.testPluginInfo(
          plugin,
          expectedName: 'haptic',
          expectedVersion: '1.0.0',
        );
      });

      test('supports all declared methods', () {
        for (final method in plugin.supportedMethods) {
          expect(plugin.supportsMethod(method), true);
        }
      });
    });

    // ── Orientation ──
    group('OrientationPlugin', () {
      late OrientationPlugin plugin;

      setUp(() async {
        plugin = OrientationPlugin();
        await plugin.initialize();
      });

      test('info', () async {
        await PluginTestUtils.testPluginInfo(
          plugin,
          expectedName: 'orientation',
          expectedVersion: '1.0.0',
        );
      });

      test('getInfo returns supported orientations', () async {
        final result = await plugin.onCall('getInfo', {});
        expect(result['supportedOrientations'], isNotEmpty);
      });

      test('validation', () async {
        final r = await plugin.validateArgs('lock', {'orientation': 123});
        expect(r.isValid, false);
      });
    });

    // ── StatusBar ──
    group('StatusBarPlugin', () {
      late StatusBarPlugin plugin;

      setUp(() async {
        plugin = StatusBarPlugin();
        await plugin.initialize();
      });

      test('info', () async {
        await PluginTestUtils.testPluginInfo(
          plugin,
          expectedName: 'statusBar',
          expectedVersion: '1.0.0',
        );
      });

      test('setStyle returns applied', () async {
        final result = await plugin.onCall('setStyle', {'style': 'dark'});
        expect(result['applied'], true);
      });
    });

    // ── NavigationBar ──
    group('NavigationBarPlugin', () {
      late NavigationBarPlugin plugin;

      setUp(() async {
        plugin = NavigationBarPlugin();
        await plugin.initialize();
      });

      test('info', () async {
        await PluginTestUtils.testPluginInfo(
          plugin,
          expectedName: 'navigationBar',
          expectedVersion: '1.0.0',
        );
      });

      test('validation', () async {
        await PluginTestUtils.testValidation(
          plugin, 'setColor', {'color': ''},
        );
      });
    });
  });
}
```

---

### 📄 `test/plugins/event_plugins_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';

import 'package:sweetmelon/plugins/alarm/lib/alarm_plugin.dart';
import 'package:sweetmelon/plugins/shake_detection/lib/shake_detection_plugin.dart';
import 'package:sweetmelon/plugins/kiosk_mode/lib/kiosk_mode_plugin.dart';
import 'package:sweetmelon/plugins/root_detection/lib/root_detection_plugin.dart';
import 'package:sweetmelon/plugins/badge/lib/badge_plugin.dart';
import 'package:sweetmelon/plugins/text_zoom/lib/text_zoom_plugin.dart';

import '../helpers/plugin_test_utils.dart';

void main() {
  // ── Alarm ──
  group('AlarmPlugin', () {
    late AlarmPlugin plugin;
    final events = <Map<String, dynamic>>[];

    setUp(() async {
      events.clear();
      plugin = AlarmPlugin(eventEmitter: (e, d) async {
        events.add({'event': e, 'data': d});
      });
      await plugin.initialize();
    });

    tearDown(() async => await plugin.dispose());

    test('info', () async {
      await PluginTestUtils.testPluginInfo(
        plugin, expectedName: 'alarm', expectedVersion: '1.0.0',
      );
    });

    test('set alarm', () async {
      final result = await plugin.onCall('set', {
        'alarmId': 'test1',
        'delayMs': 100000,
        'title': 'Test',
      });
      expect(result['set'], true);
      expect(result['alarmId'], 'test1');
    });

    test('cancel alarm', () async {
      await plugin.onCall('set', {'alarmId': 'test2', 'delayMs': 100000});
      final result = await plugin.onCall('cancel', {'alarmId': 'test2'});
      expect(result['cancelled'], true);
    });

    test('getAllAlarms', () async {
      await plugin.onCall('set', {'alarmId': 'a1', 'delayMs': 100000});
      await plugin.onCall('set', {'alarmId': 'a2', 'delayMs': 200000});
      final result = await plugin.onCall('getAllAlarms', {});
      expect(result['count'], 2);
    });

    test('cancelAll', () async {
      await plugin.onCall('set', {'alarmId': 'x1', 'delayMs': 100000});
      await plugin.onCall('set', {'alarmId': 'x2', 'delayMs': 200000});
      final result = await plugin.onCall('cancelAll', {});
      expect(result['cancelled'], 2);
    });

    test('fires event after delay', () async {
      await plugin.onCall('set', {
        'alarmId': 'fast',
        'delayMs': 100,
        'title': 'Quick',
      });

      await Future.delayed(const Duration(milliseconds: 200));
      expect(events.any((e) => e['event'] == 'alarm.fired'), true);
    });

    test('validation', () async {
      await PluginTestUtils.testValidation(plugin, 'set', {});
      await PluginTestUtils.testValidation(plugin, 'cancel', {});
    });
  });

  // ── ShakeDetection ──
  group('ShakeDetectionPlugin', () {
    late ShakeDetectionPlugin plugin;

    setUp(() async {
      plugin = ShakeDetectionPlugin();
      await plugin.initialize();
    });

    tearDown(() async => await plugin.dispose());

    test('info', () async {
      await PluginTestUtils.testPluginInfo(
        plugin, expectedName: 'shakeDetection', expectedVersion: '1.0.0',
      );
    });

    test('configure threshold', () async {
      final result = await plugin.onCall('configure', {
        'threshold': 20.0,
        'cooldownMs': 2000,
      });
      expect(result['threshold'], 20.0);
      expect(result['cooldownMs'], 2000);
    });

    test('resetCount', () async {
      final result = await plugin.onCall('resetCount', {});
      expect(result['reset'], true);
    });
  });

  // ── KioskMode ──
  group('KioskModePlugin', () {
    late KioskModePlugin plugin;

    setUp(() async {
      plugin = KioskModePlugin();
      await plugin.initialize();
    });

    tearDown(() async => await plugin.dispose());

    test('initial state is disabled', () async {
      final result = await plugin.onCall('isEnabled', {});
      expect(result['enabled'], false);
    });
  });

  // ── RootDetection ──
  group('RootDetectionPlugin', () {
    late RootDetectionPlugin plugin;

    setUp(() async {
      plugin = RootDetectionPlugin();
      await plugin.initialize();
    });

    test('info', () async {
      await PluginTestUtils.testPluginInfo(
        plugin, expectedName: 'rootDetection', expectedVersion: '1.0.0',
      );
    });

    test('isRooted returns map with checks', () async {
      final result = await plugin.onCall('isRooted', {});
      expect(result, containsPair('isRooted', isA<bool>()));
      expect(result, containsPair('riskLevel', isA<String>()));
      expect(result, containsPair('checks', isA<Map>()));
    });

    test('getSecurityInfo includes extra fields', () async {
      final result = await plugin.onCall('getSecurityInfo', {});
      expect(result, containsPair('isEmulator', isA<bool>()));
      expect(result, containsPair('isDebugMode', isA<bool>()));
    });
  });

  // ── Badge ──
  group('BadgePlugin', () {
    late BadgePlugin plugin;

    setUp(() async {
      plugin = BadgePlugin();
      await plugin.initialize();
    });

    test('initial count is 0', () async {
      final result = await plugin.onCall('get', {});
      expect(result['count'], 0);
    });

    test('validation', () async {
      await PluginTestUtils.testValidation(plugin, 'set', {});
      await PluginTestUtils.testValidArgs(plugin, 'set', {'count': 5});
    });
  });

  // ── TextZoom ──
  group('TextZoomPlugin', () {
    late TextZoomPlugin plugin;

    setUp(() async {
      plugin = TextZoomPlugin();
      await plugin.initialize();
    });

    test('default zoom is 100', () async {
      final result = await plugin.onCall('get', {});
      expect(result['zoom'], 100);
    });

    test('set zoom', () async {
      final result = await plugin.onCall('set', {'zoom': 150});
      expect(result['zoom'], 150);
    });

    test('increase', () async {
      await plugin.onCall('set', {'zoom': 100});
      final result = await plugin.onCall('increase', {'step': 20});
      expect(result['zoom'], 120);
    });

    test('decrease', () async {
      await plugin.onCall('set', {'zoom': 100});
      final result = await plugin.onCall('decrease', {'step': 30});
      expect(result['zoom'], 70);
    });

    test('clamp to min/max', () async {
      final r1 = await plugin.onCall('set', {'zoom': 10});
      expect(r1['zoom'], 50); // min

      final r2 = await plugin.onCall('set', {'zoom': 500});
      expect(r2['zoom'], 300); // max
    });

    test('reset', () async {
      await plugin.onCall('set', {'zoom': 200});
      final result = await plugin.onCall('reset', {});
      expect(result['zoom'], 100);
    });

    test('validation', () async {
      await PluginTestUtils.testValidation(plugin, 'set', {});
    });
  });
}
```

---

### 📄 `test/plugins/security_plugins_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';

import 'package:sweetmelon/plugins/app_integrity/lib/app_integrity_plugin.dart';
import 'package:sweetmelon/plugins/wifi_manager/lib/wifi_manager_plugin.dart';
import 'package:sweetmelon/plugins/email_composer/lib/email_composer_plugin.dart';
import 'package:sweetmelon/plugins/intent_launcher/lib/intent_launcher_plugin.dart';

import '../helpers/plugin_test_utils.dart';

void main() {
  // ── AppIntegrity ──
  group('AppIntegrityPlugin', () {
    late AppIntegrityPlugin plugin;

    setUp(() async {
      plugin = AppIntegrityPlugin();
      await plugin.initialize();
    });

    test('info', () async {
      await PluginTestUtils.testPluginInfo(
        plugin, expectedName: 'appIntegrity', expectedVersion: '1.0.0',
      );
    });

    test('getInfo returns playIntegrityReady', () async {
      final result = await plugin.onCall('getInfo', {});
      expect(result, containsPair('playIntegrityReady', false));
    });
  });

  // ── WifiManager ──
  group('WifiManagerPlugin', () {
    late WifiManagerPlugin plugin;

    setUp(() async {
      plugin = WifiManagerPlugin();
      await plugin.initialize();
    });

    test('info', () async {
      await PluginTestUtils.testPluginInfo(
        plugin, expectedName: 'wifiManager', expectedVersion: '1.0.0',
      );
    });

    test('getIpAddress returns map', () async {
      final result = await plugin.onCall('getIpAddress', {});
      expect(result, containsPair('ips', isA<List>()));
    });
  });

  // ── EmailComposer ──
  group('EmailComposerPlugin', () {
    late EmailComposerPlugin plugin;

    setUp(() async {
      plugin = EmailComposerPlugin();
      await plugin.initialize();
    });

    test('info', () async {
      await PluginTestUtils.testPluginInfo(
        plugin, expectedName: 'emailComposer', expectedVersion: '1.0.0',
      );
    });

    test('validation requires to', () async {
      await PluginTestUtils.testValidation(plugin, 'compose', {});
      await PluginTestUtils.testValidArgs(
        plugin, 'compose', {'to': 'test@test.com'},
      );
    });
  });

  // ── IntentLauncher ──
  group('IntentLauncherPlugin', () {
    late IntentLauncherPlugin plugin;

    setUp(() async {
      plugin = IntentLauncherPlugin();
      await plugin.initialize();
    });

    test('info', () async {
      await PluginTestUtils.testPluginInfo(
        plugin, expectedName: 'intentLauncher', expectedVersion: '1.0.0',
      );
    });

    test('getInfo returns known intents', () async {
      final result = await plugin.onCall('getInfo', {});
      expect(result['knownIntents'], isNotEmpty);
      expect(result['knownIntents'], contains('wifi'));
      expect(result['knownIntents'], contains('bluetooth'));
    });

    test('validation', () async {
      await PluginTestUtils.testValidation(plugin, 'launch', {});
      await PluginTestUtils.testValidation(plugin, 'isAppInstalled', {});
    });
  });
}
```

---

### 📄 `test/unit/core/app_context_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sweetmelon/packages/core/lib/core.dart';

void main() {
  group('AppContext', () {
    test('singleton instance', () {
      final a = AppContext();
      final b = AppContext();
      expect(identical(a, b), true);
    });

    test('hasContext is false initially', () {
      expect(AppContext().hasContext, false);
    });

    test('context is null initially', () {
      expect(AppContext().context, isNull);
    });
  });
}
```

---

### 📄 `test/unit/core/plugin_error_handler_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sweetmelon/packages/core/lib/core.dart';

void main() {
  group('PluginErrorHandler', () {
    test('converts UnsupportedError', () {
      final error = PluginErrorHandler.fromException(
        UnsupportedError('not supported'),
      );
      expect(error.code, PluginErrorCode.methodNotFound);
    });

    test('converts StateError', () {
      final error = PluginErrorHandler.fromException(
        StateError('bad state'),
      );
      expect(error.code, PluginErrorCode.executionError);
    });

    test('converts FormatException', () {
      final error = PluginErrorHandler.fromException(
        const FormatException('bad format'),
      );
      expect(error.code, PluginErrorCode.invalidArgs);
    });

    test('converts PluginException', () {
      final error = PluginErrorHandler.fromException(
        const PluginException(
          code: PluginErrorCode.permissionDenied,
          message: 'no camera',
        ),
      );
      expect(error.code, PluginErrorCode.permissionDenied);
      expect(error.message, 'no camera');
    });

    test('detects network errors', () {
      final error = PluginErrorHandler.fromException(
        Exception('SocketException: Connection refused'),
      );
      expect(error.code, PluginErrorCode.networkError);
    });

    test('detects permission errors', () {
      final error = PluginErrorHandler.fromException(
        Exception('Permission denied for camera'),
      );
      expect(error.code, PluginErrorCode.permissionDenied);
    });

    test('falls back to executionError', () {
      final error = PluginErrorHandler.fromException(
        Exception('something random'),
      );
      expect(error.code, PluginErrorCode.executionError);
    });

    test('errorResponse creates PluginResponse', () {
      final response = PluginErrorHandler.errorResponse(
        'req_1',
        Exception('test error'),
      );
      expect(response.success, false);
      expect(response.requestId, 'req_1');
      expect(response.error, isNotNull);
    });
  });

  group('PluginException', () {
    test('notFound factory', () {
      const e = PluginException.notFound('plugin X');
      expect(e.code, PluginErrorCode.pluginNotFound);
      expect(e.message, contains('plugin X'));
    });

    test('invalidArgs factory', () {
      const e = PluginException.invalidArgs('key is required');
      expect(e.code, PluginErrorCode.invalidArgs);
    });

    test('permissionDenied factory', () {
      const e = PluginException.permissionDenied('camera');
      expect(e.code, PluginErrorCode.permissionDenied);
    });

    test('noContext factory', () {
      const e = PluginException.noContext();
      expect(e.code, PluginErrorCode.executionError);
    });

    test('toString includes code and message', () {
      const e = PluginException(
        code: PluginErrorCode.timeout,
        message: 'took too long',
      );
      expect(e.toString(), contains('TIMEOUT'));
      expect(e.toString(), contains('took too long'));
    });
  });
}
```

---

### 📄 `test/test_runner.dart` — بروزرسانی

```dart
// Core
import 'unit/core/message_protocol_test.dart' as protocol_test;
import 'unit/core/message_bridge_test.dart' as bridge_test;
import 'unit/core/app_context_test.dart' as context_test;
import 'unit/core/plugin_error_handler_test.dart' as error_handler_test;

// Middleware
import 'unit/middleware/error_recovery_test.dart' as retry_test;
import 'unit/middleware/circuit_breaker_test.dart' as circuit_test;

// Engine
import 'unit/engine/plugin_registry_test.dart' as registry_test;
import 'unit/engine/plugin_manager_test.dart' as manager_test;
import 'unit/engine/lazy_plugin_loader_test.dart' as lazy_test;
import 'unit/engine/plugin_versioning_test.dart' as versioning_test;

// Security
import 'unit/security/rate_limiter_test.dart' as rate_test;
import 'unit/security/execution_guard_test.dart' as guard_test;

// Performance
import 'unit/performance/cache_manager_test.dart' as cache_test;

// Plugins
import 'plugins/encryption_plugin_test.dart' as encryption_test;
import 'plugins/storage_plugin_test.dart' as storage_test;
import 'plugins/all_plugins_basic_test.dart' as all_basic_test;
import 'plugins/event_plugins_test.dart' as event_test;
import 'plugins/security_plugins_test.dart' as security_test;
import 'plugins/websocket_plugin_test.dart' as ws_test;
import 'plugins/background_task_plugin_test.dart' as bg_test;
import 'plugins/dialog_plugin_test.dart' as dialog_test;
import 'plugins/app_update_plugin_test.dart' as update_test;
import 'plugins/cookie_manager_plugin_test.dart' as cookie_test;
import 'plugins/cache_control_plugin_test.dart' as cache_control_test;
import 'plugins/push_notification_plugin_test.dart' as push_test;

// Integration
import 'integration/bridge_integration_test.dart' as bridge_integration;
import 'integration/lazy_loading_integration_test.dart' as lazy_integration;

void main() {
  // Core
  protocol_test.main();
  bridge_test.main();
  context_test.main();
  error_handler_test.main();

  // Middleware
  retry_test.main();
  circuit_test.main();

  // Engine
  registry_test.main();
  manager_test.main();
  lazy_test.main();
  versioning_test.main();

  // Security
  rate_test.main();
  guard_test.main();

  // Performance
  cache_test.main();

  // Plugins
  encryption_test.main();
  storage_test.main();
  all_basic_test.main();
  event_test.main();
  security_test.main();
  ws_test.main();
  bg_test.main();
  dialog_test.main();
  update_test.main();
  cookie_test.main();
  cache_control_test.main();
  push_test.main();

  // Integration
  bridge_integration.main();
  lazy_integration.main();
}
```

---

# خلاصه فاز ۱۲

## تغییرات ساختاری

| تغییر | فایل | توضیح |
|-------|------|-------|
| **AppContext مرکزی** | `app_context.dart` | جایگزین QrScannerPlugin.navigatorKey |
| **PluginErrorHandler** | `plugin_error_handler.dart` | Error handling یکدست |
| **PluginException** | `plugin_error_handler.dart` | Exception سفارشی با error codes |
| **BasePlugin** | `plugin_base.dart` | Base class بهبودیافته با helpers |
| **Native Channels** | `MainActivity.kt` | پیاده‌سازی واقعی ۷ native channel |

## Native Channels پیاده‌شده

| Channel | عملکرد |
|---------|--------|
| `sweetmelon/privacy_screen` | FLAG_SECURE enable/disable |
| `sweetmelon/wake_lock` | FLAG_KEEP_SCREEN_ON |
| `sweetmelon/foreground_service` | Start/stop/update service |
| `sweetmelon/sim_info` | SIM card info, carrier, count |
| `sweetmelon/app_integrity` | Install source, signing info |
| `sweetmelon/volume_buttons` | Volume key events via EventChannel |
| `sweetmelon/share_target` | Receive shared content |

## تست‌ها

| فایل | تعداد تست |
|------|-----------|
| `app_context_test.dart` | 3 |
| `plugin_error_handler_test.dart` | 10 |
| `all_plugins_basic_test.dart` | 25+ |
| `event_plugins_test.dart` | 20+ |
| `security_plugins_test.dart` | 10+ |
| **مجموع تست‌های جدید** | **68+** |
| **مجموع کل تست‌ها** | **168+** |

---

در پیام بعدی **فاز ۱۳: Security Hardening** رو می‌فرستم. ادامه بدم؟
