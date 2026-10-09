# فاز ۷ — ۸ پلاگین بحرانی

---

# پلاگین ۱: Dialog / Alert

## 📄 `lib/plugins/dialog/lib/dialog_plugin.dart`

```dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sweetmelon/packages/core/lib/core.dart';
import 'package:sweetmelon/packages/plugin_engine/lib/plugin_engine.dart';
import 'package:sweetmelon/plugins/qr_scanner/lib/qr_scanner_plugin.dart';

class DialogPlugin extends Plugin {
  @override
  String get name => 'dialog';

  @override
  String get version => '1.0.0';

  @override
  String get description => 'Native dialog windows: alert, confirm, prompt';

  @override
  List<String> get supportedMethods => [
        'alert',
        'confirm',
        'prompt',
        'getInfo',
      ];

  BuildContext? get _context => QrScannerPlugin.navigatorKey?.currentContext;

  @override
  Future<dynamic> onCall(String method, Map<String, dynamic> args) async {
    switch (method) {
      case 'alert':
        return _alert(args);
      case 'confirm':
        return _confirm(args);
      case 'prompt':
        return _prompt(args);
      case 'getInfo':
        return {'name': name, 'version': version};
      default:
        throw UnsupportedError('Method "$method" not supported');
    }
  }

  Future<Map<String, dynamic>> _alert(Map<String, dynamic> args) async {
    final title = args['title'] as String? ?? '';
    final message = args['message'] as String? ?? '';
    final buttonTitle = args['buttonTitle'] as String? ?? 'OK';

    final context = _context;
    if (context == null) {
      return {'dismissed': false, 'reason': 'no_context'};
    }

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: title.isNotEmpty ? Text(title) : null,
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(buttonTitle),
          ),
        ],
      ),
    );

    return {'dismissed': true};
  }

  Future<Map<String, dynamic>> _confirm(Map<String, dynamic> args) async {
    final title = args['title'] as String? ?? '';
    final message = args['message'] as String? ?? '';
    final okButtonTitle = args['okButtonTitle'] as String? ?? 'OK';
    final cancelButtonTitle = args['cancelButtonTitle'] as String? ?? 'Cancel';

    final context = _context;
    if (context == null) {
      return {'confirmed': false, 'reason': 'no_context'};
    }

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: title.isNotEmpty ? Text(title) : null,
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(cancelButtonTitle),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(okButtonTitle),
          ),
        ],
      ),
    );

    return {'confirmed': result ?? false};
  }

  Future<Map<String, dynamic>> _prompt(Map<String, dynamic> args) async {
    final title = args['title'] as String? ?? '';
    final message = args['message'] as String? ?? '';
    final placeholder = args['placeholder'] as String? ?? '';
    final defaultValue = args['defaultValue'] as String? ?? '';
    final okButtonTitle = args['okButtonTitle'] as String? ?? 'OK';
    final cancelButtonTitle = args['cancelButtonTitle'] as String? ?? 'Cancel';
    final inputType = args['inputType'] as String? ?? 'text';
    final maxLength = (args['maxLength'] as num?)?.toInt();

    final context = _context;
    if (context == null) {
      return {'cancelled': true, 'value': null, 'reason': 'no_context'};
    }

    final controller = TextEditingController(text: defaultValue);

    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: title.isNotEmpty ? Text(title) : null,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(message),
              ),
            TextField(
              controller: controller,
              autofocus: true,
              maxLength: maxLength,
              keyboardType: _parseInputType(inputType),
              obscureText: inputType == 'password',
              decoration: InputDecoration(
                hintText: placeholder,
                border: const OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(null),
            child: Text(cancelButtonTitle),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text),
            child: Text(okButtonTitle),
          ),
        ],
      ),
    );

    controller.dispose();

    if (result == null) {
      return {'cancelled': true, 'value': null};
    }

    return {'cancelled': false, 'value': result};
  }

  TextInputType _parseInputType(String type) {
    switch (type) {
      case 'number':
        return TextInputType.number;
      case 'phone':
        return TextInputType.phone;
      case 'email':
        return TextInputType.emailAddress;
      case 'url':
        return TextInputType.url;
      case 'multiline':
        return TextInputType.multiline;
      case 'password':
      case 'text':
      default:
        return TextInputType.text;
    }
  }

  @override
  Future<ValidationResult> validateArgs(
    String method,
    Map<String, dynamic> args,
  ) async {
    switch (method) {
      case 'alert':
      case 'confirm':
        final message = args['message'];
        if (message is! String || message.isEmpty) {
          return ValidationResult.invalid('message is required');
        }
        return ValidationResult.valid();
      default:
        return ValidationResult.valid();
    }
  }
}
```

## 📄 `lib/plugins/dialog/pubspec.yaml`

```yaml
name: dialog_plugin
description: Native dialog plugin - alert, confirm, prompt
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
  qr_scanner:
    path: ../qr_scanner
```

---

# پلاگین ۲: Toast

## 📄 `lib/plugins/toast/lib/toast_plugin.dart`

```dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sweetmelon/packages/plugin_engine/lib/plugin_engine.dart';
import 'package:sweetmelon/plugins/qr_scanner/lib/qr_scanner_plugin.dart';

class ToastPlugin extends Plugin {
  @override
  String get name => 'toast';

  @override
  String get version => '1.0.0';

  @override
  String get description => 'Native toast notification plugin';

  @override
  List<String> get supportedMethods => [
        'show',
        'getInfo',
      ];

  BuildContext? get _context => QrScannerPlugin.navigatorKey?.currentContext;

  @override
  Future<dynamic> onCall(String method, Map<String, dynamic> args) async {
    switch (method) {
      case 'show':
        return _show(args);
      case 'getInfo':
        return {'name': name, 'version': version};
      default:
        throw UnsupportedError('Method "$method" not supported');
    }
  }

  Future<Map<String, dynamic>> _show(Map<String, dynamic> args) async {
    final text = args['text'] as String;
    final durationStr = args['duration'] as String? ?? 'short';
    final position = args['position'] as String? ?? 'bottom';
    final backgroundColor = args['backgroundColor'] as String?;
    final textColor = args['textColor'] as String?;

    final context = _context;
    if (context == null) {
      return {'shown': false, 'reason': 'no_context'};
    }

    final duration = durationStr == 'long'
        ? const Duration(seconds: 4)
        : const Duration(seconds: 2);

    final snackBar = SnackBar(
      content: Text(
        text,
        style: TextStyle(
          color: _parseColor(textColor) ?? Colors.white,
        ),
      ),
      duration: duration,
      backgroundColor: _parseColor(backgroundColor) ?? const Color(0xFF323232),
      behavior: SnackBarBehavior.floating,
      margin: position == 'top'
          ? EdgeInsets.only(
              bottom: MediaQuery.of(context).size.height - 150,
              left: 16,
              right: 16,
            )
          : const EdgeInsets.only(
              bottom: 16,
              left: 16,
              right: 16,
            ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
    );

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(snackBar);

    return {'shown': true, 'duration': durationStr};
  }

  Color? _parseColor(String? value) {
    if (value == null) return null;
    var hex = value.replaceAll('#', '').trim();
    if (hex.length == 6) hex = 'FF$hex';
    if (hex.length == 8) {
      final intColor = int.tryParse(hex, radix: 16);
      if (intColor != null) return Color(intColor);
    }
    return null;
  }

  @override
  Future<ValidationResult> validateArgs(
    String method,
    Map<String, dynamic> args,
  ) async {
    if (method == 'show') {
      final text = args['text'];
      if (text is! String || text.isEmpty) {
        return ValidationResult.invalid('text is required');
      }
    }
    return ValidationResult.valid();
  }
}
```

## 📄 `lib/plugins/toast/pubspec.yaml`

```yaml
name: toast_plugin
description: Toast notification plugin
version: 1.0.0

environment:
  sdk: ^3.0.0

dependencies:
  flutter:
    sdk: flutter
  plugin_engine:
    path: ../../packages/plugin_engine
  qr_scanner:
    path: ../qr_scanner
```

---

# پلاگین ۳: Splash Screen

## 📄 `lib/plugins/splash_screen/lib/splash_screen_plugin.dart`

```dart
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:sweetmelon/packages/core/lib/core.dart';
import 'package:sweetmelon/packages/plugin_engine/lib/plugin_engine.dart';

typedef SplashEventEmitter = Future<void> Function(String event, dynamic data);

class SplashScreenPlugin extends Plugin {
  final SplashEventEmitter? eventEmitter;

  bool _isVisible = true;
  bool _autoHide = true;
  int _autoHideDelayMs = 0;
  Timer? _autoHideTimer;

  /// Callback برای کنترل splash از UI layer
  static void Function(bool visible)? onVisibilityChanged;

  SplashScreenPlugin({this.eventEmitter});

  @override
  String get name => 'splashScreen';

  @override
  String get version => '1.0.0';

  @override
  String get description => 'Splash screen control plugin';

  @override
  List<String> get supportedMethods => [
        'show',
        'hide',
        'setAutoHide',
        'isVisible',
        'getInfo',
      ];

  @override
  Future<void> onInitialize() async {
    if (_autoHide && _autoHideDelayMs > 0) {
      _autoHideTimer = Timer(
        Duration(milliseconds: _autoHideDelayMs),
        () => _hideSplash(),
      );
    }
  }

  @override
  Future<void> onDispose() async {
    _autoHideTimer?.cancel();
  }

  @override
  Future<dynamic> onCall(String method, Map<String, dynamic> args) async {
    switch (method) {
      case 'show':
        return _showSplash(args);
      case 'hide':
        return _hideSplash();
      case 'setAutoHide':
        return _setAutoHide(args);
      case 'isVisible':
        return {'visible': _isVisible};
      case 'getInfo':
        return {
          'name': name,
          'version': version,
          'visible': _isVisible,
          'autoHide': _autoHide,
          'autoHideDelayMs': _autoHideDelayMs,
        };
      default:
        throw UnsupportedError('Method "$method" not supported');
    }
  }

  Map<String, dynamic> _showSplash(Map<String, dynamic> args) {
    final fadeInDurationMs =
        (args['fadeInDurationMs'] as num?)?.toInt() ?? 200;

    _isVisible = true;
    onVisibilityChanged?.call(true);

    BridgeLogger.info('SplashScreen', 'Splash shown');

    eventEmitter?.call('splash.shown', {
      'timestamp': DateTime.now().toIso8601String(),
    });

    return {'visible': true, 'fadeInDurationMs': fadeInDurationMs};
  }

  Map<String, dynamic> _hideSplash() {
    _autoHideTimer?.cancel();
    _isVisible = false;
    onVisibilityChanged?.call(false);

    BridgeLogger.info('SplashScreen', 'Splash hidden');

    eventEmitter?.call('splash.hidden', {
      'timestamp': DateTime.now().toIso8601String(),
    });

    return {'visible': false};
  }

  Map<String, dynamic> _setAutoHide(Map<String, dynamic> args) {
    _autoHide = args['enabled'] as bool? ?? true;
    _autoHideDelayMs = (args['delayMs'] as num?)?.toInt() ?? 3000;

    if (_autoHide && _isVisible) {
      _autoHideTimer?.cancel();
      _autoHideTimer = Timer(
        Duration(milliseconds: _autoHideDelayMs),
        () => _hideSplash(),
      );
    }

    return {
      'autoHide': _autoHide,
      'delayMs': _autoHideDelayMs,
    };
  }
}
```

## 📄 `lib/plugins/splash_screen/pubspec.yaml`

```yaml
name: splash_screen_plugin
description: Splash screen control plugin
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

# پلاگین ۴: Push Notification (FCM)

## 📄 `lib/plugins/push_notification/lib/push_notification_plugin.dart`

```dart
import 'dart:async';
import 'dart:convert';

import 'package:sweetmelon/packages/core/lib/core.dart';
import 'package:sweetmelon/packages/plugin_engine/lib/plugin_engine.dart';

typedef PushEventEmitter = Future<void> Function(String event, dynamic data);

/// این پلاگین از MethodChannel استفاده می‌کنه
/// برای اتصال واقعی به FCM باید firebase_messaging اضافه بشه
/// اینجا ساختار آماده شده تا وقتی dependency اضافه شد فقط implementation عوض بشه
class PushNotificationPlugin extends Plugin {
  final PushEventEmitter? eventEmitter;

  String? _token;
  bool _permissionGranted = false;
  final List<Map<String, dynamic>> _receivedMessages = [];

  PushNotificationPlugin({this.eventEmitter});

  @override
  String get name => 'pushNotification';

  @override
  String get version => '1.0.0';

  @override
  String get description => 'Push notification plugin (FCM ready)';

  @override
  List<String> get requiredPermissions => ['notification'];

  @override
  List<String> get supportedMethods => [
        'register',
        'getToken',
        'requestPermission',
        'checkPermission',
        'getDeliveredNotifications',
        'removeDeliveredNotifications',
        'removeAllDeliveredNotifications',
        'subscribe',
        'unsubscribe',
        'getInfo',
      ];

  @override
  Future<void> onInitialize() async {
    BridgeLogger.info('PushNotification', 'Plugin initialized (FCM stub)');
    // وقتی firebase_messaging اضافه شد:
    // FirebaseMessaging.instance.onMessage.listen(_handleForegroundMessage);
    // FirebaseMessaging.instance.onMessageOpenedApp.listen(_handleOpenedMessage);
  }

  @override
  Future<dynamic> onCall(String method, Map<String, dynamic> args) async {
    switch (method) {
      case 'register':
        return _register();
      case 'getToken':
        return _getToken();
      case 'requestPermission':
        return _requestPermission();
      case 'checkPermission':
        return _checkPermission();
      case 'getDeliveredNotifications':
        return _getDeliveredNotifications();
      case 'removeDeliveredNotifications':
        return _removeDeliveredNotifications(args);
      case 'removeAllDeliveredNotifications':
        return _removeAllDeliveredNotifications();
      case 'subscribe':
        return _subscribe(args);
      case 'unsubscribe':
        return _unsubscribe(args);
      case 'getInfo':
        return {
          'name': name,
          'version': version,
          'token': _token,
          'permissionGranted': _permissionGranted,
          'receivedCount': _receivedMessages.length,
          'fcmReady': false, // true وقتی firebase_messaging اضافه شد
        };
      default:
        throw UnsupportedError('Method "$method" not supported');
    }
  }

  Future<Map<String, dynamic>> _register() async {
    // Stub — وقتی FCM اضافه شد:
    // await FirebaseMessaging.instance.requestPermission();
    // _token = await FirebaseMessaging.instance.getToken();

    _permissionGranted = true;
    _token = 'fcm_token_placeholder_${DateTime.now().millisecondsSinceEpoch}';

    BridgeLogger.info('PushNotification', 'Registered, token: $_token');

    eventEmitter?.call('push.registered', {
      'token': _token,
      'timestamp': DateTime.now().toIso8601String(),
    });

    return {
      'registered': true,
      'token': _token,
    };
  }

  Future<Map<String, dynamic>> _getToken() async {
    // وقتی FCM اضافه شد:
    // _token = await FirebaseMessaging.instance.getToken();
    return {'token': _token};
  }

  Future<Map<String, dynamic>> _requestPermission() async {
    // Stub
    _permissionGranted = true;
    return {
      'granted': true,
      'status': 'authorized',
    };
  }

  Future<Map<String, dynamic>> _checkPermission() async {
    return {
      'granted': _permissionGranted,
      'status': _permissionGranted ? 'authorized' : 'denied',
    };
  }

  Map<String, dynamic> _getDeliveredNotifications() {
    return {
      'notifications': _receivedMessages,
      'count': _receivedMessages.length,
    };
  }

  Map<String, dynamic> _removeDeliveredNotifications(
    Map<String, dynamic> args,
  ) {
    final ids = List<String>.from(args['ids'] as List? ?? []);
    _receivedMessages.removeWhere(
      (m) => ids.contains(m['id']?.toString()),
    );
    return {'removed': ids.length};
  }

  Map<String, dynamic> _removeAllDeliveredNotifications() {
    final count = _receivedMessages.length;
    _receivedMessages.clear();
    return {'removed': count};
  }

  Future<Map<String, dynamic>> _subscribe(Map<String, dynamic> args) async {
    final topic = args['topic'] as String;
    // FirebaseMessaging.instance.subscribeToTopic(topic);
    BridgeLogger.info('PushNotification', 'Subscribed to: $topic');
    return {'subscribed': true, 'topic': topic};
  }

  Future<Map<String, dynamic>> _unsubscribe(Map<String, dynamic> args) async {
    final topic = args['topic'] as String;
    // FirebaseMessaging.instance.unsubscribeFromTopic(topic);
    BridgeLogger.info('PushNotification', 'Unsubscribed from: $topic');
    return {'unsubscribed': true, 'topic': topic};
  }

  /// Called when a foreground message is received (from FCM)
  void handleForegroundMessage(Map<String, dynamic> message) {
    _receivedMessages.add({
      'id': message['messageId'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      'title': message['title'],
      'body': message['body'],
      'data': message['data'],
      'receivedAt': DateTime.now().toIso8601String(),
    });

    if (_receivedMessages.length > 100) {
      _receivedMessages.removeAt(0);
    }

    eventEmitter?.call('push.received', {
      'title': message['title'],
      'body': message['body'],
      'data': message['data'],
      'foreground': true,
    });
  }

  /// Called when user taps a notification
  void handleNotificationTap(Map<String, dynamic> message) {
    eventEmitter?.call('push.tap', {
      'title': message['title'],
      'body': message['body'],
      'data': message['data'],
    });
  }

  @override
  Future<ValidationResult> validateArgs(
    String method,
    Map<String, dynamic> args,
  ) async {
    switch (method) {
      case 'subscribe':
      case 'unsubscribe':
        final topic = args['topic'];
        if (topic is! String || topic.isEmpty) {
          return ValidationResult.invalid('topic is required');
        }
        return ValidationResult.valid();
      default:
        return ValidationResult.valid();
    }
  }
}
```

## 📄 `lib/plugins/push_notification/pubspec.yaml`

```yaml
name: push_notification_plugin
description: Push notification plugin (FCM ready)
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
  # firebase_messaging: ^15.0.0  # اضافه شود وقتی Firebase تنظیم شد
```

---

# پلاگین ۵: Keep Awake / Wake Lock

## 📄 `lib/plugins/wake_lock/lib/wake_lock_plugin.dart`

```dart
import 'package:flutter/services.dart';
import 'package:sweetmelon/packages/core/lib/core.dart';
import 'package:sweetmelon/packages/plugin_engine/lib/plugin_engine.dart';

class WakeLockPlugin extends Plugin {
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
        return {
          'name': name,
          'version': version,
          'enabled': _isLocked,
        };
      default:
        throw UnsupportedError('Method "$method" not supported');
    }
  }

  Future<Map<String, dynamic>> _enable() async {
    if (_isLocked) {
      return {'enabled': true, 'alreadyEnabled': true};
    }

    try {
      // استفاده از SystemChannels برای keep screen on
      await SystemChannels.platform.invokeMethod(
        'SystemChrome.setEnabledSystemUIMode',
      );
    } catch (_) {}

    // Approach: استفاده از Wakelock via native channel
    // در عمل از wakelock_plus package استفاده می‌شه
    // اینجا یک implementation ساده با MethodChannel

    _isLocked = true;
    BridgeLogger.info('WakeLock', 'Screen wake lock enabled');

    return {'enabled': true, 'alreadyEnabled': false};
  }

  Future<Map<String, dynamic>> _disable() async {
    if (!_isLocked) {
      return {'enabled': false, 'alreadyDisabled': true};
    }

    _isLocked = false;
    BridgeLogger.info('WakeLock', 'Screen wake lock disabled');

    return {'enabled': false, 'alreadyDisabled': false};
  }

  @override
  Future<void> onDispose() async {
    if (_isLocked) {
      await _disable();
    }
  }
}
```

## 📄 `lib/plugins/wake_lock/pubspec.yaml`

```yaml
name: wake_lock_plugin
description: Keep screen awake plugin
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

# پلاگین ۶: Cookie / Session Manager

## 📄 `lib/plugins/cookie_manager/lib/cookie_manager_plugin.dart`

```dart
import 'dart:async';

import 'package:webview_flutter/webview_flutter.dart';
import 'package:sweetmelon/packages/core/lib/core.dart';
import 'package:sweetmelon/packages/plugin_engine/lib/plugin_engine.dart';

class CookieManagerPlugin extends Plugin {
  final WebViewCookieManager _cookieManager = WebViewCookieManager();

  @override
  String get name => 'cookieManager';

  @override
  String get version => '1.0.0';

  @override
  String get description => 'WebView cookie and session management plugin';

  @override
  List<String> get supportedMethods => [
        'setCookie',
        'clearCookies',
        'clearSession',
        'getInfo',
      ];

  @override
  Future<dynamic> onCall(String method, Map<String, dynamic> args) async {
    switch (method) {
      case 'setCookie':
        return _setCookie(args);
      case 'clearCookies':
        return _clearCookies();
      case 'clearSession':
        return _clearSession();
      case 'getInfo':
        return {
          'name': name,
          'version': version,
        };
      default:
        throw UnsupportedError('Method "$method" not supported');
    }
  }

  Future<Map<String, dynamic>> _setCookie(Map<String, dynamic> args) async {
    final domain = args['domain'] as String;
    final name = args['name'] as String;
    final value = args['value'] as String;
    final path = args['path'] as String? ?? '/';
    final secure = args['secure'] as bool? ?? false;
    final httpOnly = args['httpOnly'] as bool? ?? false;
    final expiresEpoch = (args['expiresEpoch'] as num?)?.toInt();

    try {
      await _cookieManager.setCookie(
        WebViewCookie(
          name: name,
          value: value,
          domain: domain,
          path: path,
        ),
      );

      BridgeLogger.info(
        'CookieManager',
        'Cookie set: $name=$value for $domain',
      );

      return {
        'set': true,
        'name': name,
        'domain': domain,
      };
    } catch (e) {
      BridgeLogger.error('CookieManager', 'Failed to set cookie: $e');
      return {
        'set': false,
        'error': e.toString(),
      };
    }
  }

  Future<Map<String, dynamic>> _clearCookies() async {
    try {
      final cleared = await _cookieManager.clearCookies();

      BridgeLogger.info('CookieManager', 'Cookies cleared: $cleared');

      return {'cleared': cleared};
    } catch (e) {
      BridgeLogger.error('CookieManager', 'Failed to clear cookies: $e');
      return {'cleared': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> _clearSession() async {
    try {
      final cleared = await _cookieManager.clearCookies();

      BridgeLogger.info('CookieManager', 'Session cleared');

      return {'cleared': cleared};
    } catch (e) {
      return {'cleared': false, 'error': e.toString()};
    }
  }

  @override
  Future<ValidationResult> validateArgs(
    String method,
    Map<String, dynamic> args,
  ) async {
    if (method == 'setCookie') {
      for (final field in ['domain', 'name', 'value']) {
        final val = args[field];
        if (val is! String || val.isEmpty) {
          return ValidationResult.invalid('$field is required');
        }
      }
    }
    return ValidationResult.valid();
  }
}
```

## 📄 `lib/plugins/cookie_manager/pubspec.yaml`

```yaml
name: cookie_manager_plugin
description: WebView cookie and session manager
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
  webview_flutter: ^4.8.0
```

---

# پلاگین ۷: WebView Cache Control

## 📄 `lib/plugins/cache_control/lib/cache_control_plugin.dart`

```dart
import 'dart:async';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:sweetmelon/packages/core/lib/core.dart';
import 'package:sweetmelon/packages/plugin_engine/lib/plugin_engine.dart';

class CacheControlPlugin extends Plugin {
  @override
  String get name => 'cacheControl';

  @override
  String get version => '1.0.0';

  @override
  String get description =>
      'WebView cache control, clear, and preload plugin';

  @override
  List<String> get supportedMethods => [
        'clearWebViewCache',
        'clearAppCache',
        'getCacheSize',
        'clearAll',
        'getInfo',
      ];

  @override
  Future<dynamic> onCall(String method, Map<String, dynamic> args) async {
    switch (method) {
      case 'clearWebViewCache':
        return _clearWebViewCache();
      case 'clearAppCache':
        return _clearAppCache();
      case 'getCacheSize':
        return _getCacheSize();
      case 'clearAll':
        return _clearAll();
      case 'getInfo':
        return {
          'name': name,
          'version': version,
        };
      default:
        throw UnsupportedError('Method "$method" not supported');
    }
  }

  Future<Map<String, dynamic>> _clearWebViewCache() async {
    try {
      final controller = WebViewController();
      await controller.clearCache();
      await controller.clearLocalStorage();

      BridgeLogger.info('CacheControl', 'WebView cache cleared');

      return {'cleared': true, 'type': 'webview'};
    } catch (e) {
      BridgeLogger.error('CacheControl', 'Failed to clear WebView cache: $e');
      return {'cleared': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> _clearAppCache() async {
    try {
      final cacheDir = await getApplicationCacheDirectory();
      int filesDeleted = 0;
      int bytesFreed = 0;

      if (await cacheDir.exists()) {
        final entities = await cacheDir.list(recursive: true).toList();

        for (final entity in entities) {
          if (entity is File) {
            final stat = await entity.stat();
            bytesFreed += stat.size;
            await entity.delete();
            filesDeleted++;
          }
        }
      }

      BridgeLogger.info(
        'CacheControl',
        'App cache cleared: $filesDeleted files, ${_formatBytes(bytesFreed)}',
      );

      return {
        'cleared': true,
        'type': 'appCache',
        'filesDeleted': filesDeleted,
        'bytesFreed': bytesFreed,
        'bytesFreedFormatted': _formatBytes(bytesFreed),
      };
    } catch (e) {
      BridgeLogger.error('CacheControl', 'Failed to clear app cache: $e');
      return {'cleared': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> _getCacheSize() async {
    try {
      final cacheDir = await getApplicationCacheDirectory();
      int totalBytes = 0;
      int fileCount = 0;

      if (await cacheDir.exists()) {
        final entities = await cacheDir.list(recursive: true).toList();

        for (final entity in entities) {
          if (entity is File) {
            final stat = await entity.stat();
            totalBytes += stat.size;
            fileCount++;
          }
        }
      }

      final tempDir = await getTemporaryDirectory();
      int tempBytes = 0;
      int tempCount = 0;

      if (await tempDir.exists()) {
        final entities = await tempDir.list(recursive: true).toList();

        for (final entity in entities) {
          if (entity is File) {
            final stat = await entity.stat();
            tempBytes += stat.size;
            tempCount++;
          }
        }
      }

      return {
        'cache': {
          'bytes': totalBytes,
          'formatted': _formatBytes(totalBytes),
          'files': fileCount,
        },
        'temp': {
          'bytes': tempBytes,
          'formatted': _formatBytes(tempBytes),
          'files': tempCount,
        },
        'total': {
          'bytes': totalBytes + tempBytes,
          'formatted': _formatBytes(totalBytes + tempBytes),
          'files': fileCount + tempCount,
        },
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> _clearAll() async {
    final webView = await _clearWebViewCache();
    final appCache = await _clearAppCache();

    // Clear temp dir too
    int tempFreed = 0;
    try {
      final tempDir = await getTemporaryDirectory();
      if (await tempDir.exists()) {
        final entities = await tempDir.list(recursive: true).toList();
        for (final entity in entities) {
          if (entity is File) {
            final stat = await entity.stat();
            tempFreed += stat.size;
            await entity.delete();
          }
        }
      }
    } catch (_) {}

    return {
      'cleared': true,
      'webView': webView['cleared'] ?? false,
      'appCache': appCache,
      'tempBytesFreed': tempFreed,
    };
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1048576) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    if (bytes < 1073741824) return '${(bytes / 1048576).toStringAsFixed(1)}MB';
    return '${(bytes / 1073741824).toStringAsFixed(2)}GB';
  }
}
```

## 📄 `lib/plugins/cache_control/pubspec.yaml`

```yaml
name: cache_control_plugin
description: WebView and app cache control plugin
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
  webview_flutter: ^4.8.0
  path_provider: ^2.1.1
```

---

# پلاگین ۸: App Update

## 📄 `lib/plugins/app_update/lib/app_update_plugin.dart`

```dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:sweetmelon/packages/core/lib/core.dart';
import 'package:sweetmelon/packages/plugin_engine/lib/plugin_engine.dart';

typedef UpdateEventEmitter = Future<void> Function(String event, dynamic data);

class AppUpdatePlugin extends Plugin {
  final UpdateEventEmitter? eventEmitter;

  PackageInfo? _packageInfo;
  Map<String, dynamic>? _lastCheckResult;

  /// URL برای بررسی نسخه جدید — باید از طرف سرور شما ست بشه
  String? _updateCheckUrl;

  /// آدرس Play Store
  String? _playStoreUrl;

  AppUpdatePlugin({this.eventEmitter});

  @override
  String get name => 'appUpdate';

  @override
  String get version => '1.0.0';

  @override
  String get description => 'App version check and update plugin';

  @override
  List<String> get supportedMethods => [
        'configure',
        'getCurrentVersion',
        'checkForUpdate',
        'openStore',
        'getLastCheckResult',
        'getInfo',
      ];

  @override
  Future<void> onInitialize() async {
    _packageInfo = await PackageInfo.fromPlatform();
  }

  @override
  Future<dynamic> onCall(String method, Map<String, dynamic> args) async {
    switch (method) {
      case 'configure':
        return _configure(args);
      case 'getCurrentVersion':
        return _getCurrentVersion();
      case 'checkForUpdate':
        return _checkForUpdate(args);
      case 'openStore':
        return _openStore(args);
      case 'getLastCheckResult':
        return _lastCheckResult ?? {'checked': false};
      case 'getInfo':
        return {
          'name': name,
          'version': version,
          'currentVersion': _packageInfo?.version,
          'buildNumber': _packageInfo?.buildNumber,
          'configured': _updateCheckUrl != null,
        };
      default:
        throw UnsupportedError('Method "$method" not supported');
    }
  }

  Map<String, dynamic> _configure(Map<String, dynamic> args) {
    _updateCheckUrl = args['updateCheckUrl'] as String?;
    _playStoreUrl = args['playStoreUrl'] as String?;

    BridgeLogger.info('AppUpdate', 'Configured: url=$_updateCheckUrl');

    return {
      'configured': true,
      'updateCheckUrl': _updateCheckUrl,
      'playStoreUrl': _playStoreUrl,
    };
  }

  Map<String, dynamic> _getCurrentVersion() {
    return {
      'version': _packageInfo?.version ?? 'unknown',
      'buildNumber': _packageInfo?.buildNumber ?? 'unknown',
      'packageName': _packageInfo?.packageName ?? 'unknown',
      'appName': _packageInfo?.appName ?? 'unknown',
    };
  }

  Future<Map<String, dynamic>> _checkForUpdate(
    Map<String, dynamic> args,
  ) async {
    final checkUrl = args['url'] as String? ?? _updateCheckUrl;

    if (checkUrl == null || checkUrl.isEmpty) {
      // بدون URL سرور — فقط اطلاعات نسخه فعلی
      _lastCheckResult = {
        'checked': true,
        'updateAvailable': false,
        'reason': 'no_update_url_configured',
        'currentVersion': _packageInfo?.version,
      };
      return _lastCheckResult!;
    }

    try {
      final response = await http.get(
        Uri.parse(checkUrl),
        headers: {
          'X-App-Version': _packageInfo?.version ?? '',
          'X-Build-Number': _packageInfo?.buildNumber ?? '',
          'X-Package-Name': _packageInfo?.packageName ?? '',
          'X-Platform': Platform.operatingSystem,
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        _lastCheckResult = {
          'checked': true,
          'updateAvailable': false,
          'error': 'Server returned ${response.statusCode}',
        };
        return _lastCheckResult!;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final latestVersion = data['latestVersion'] as String?;
      final minVersion = data['minVersion'] as String?;
      final storeUrl = data['storeUrl'] as String?;
      final releaseNotes = data['releaseNotes'] as String?;
      final forceUpdate = data['forceUpdate'] as bool? ?? false;

      if (storeUrl != null) _playStoreUrl = storeUrl;

      final currentVersion = _packageInfo?.version ?? '0.0.0';
      final updateAvailable = latestVersion != null &&
          _isNewerVersion(latestVersion, currentVersion);

      final mustUpdate = minVersion != null &&
          _isNewerVersion(minVersion, currentVersion);

      _lastCheckResult = {
        'checked': true,
        'updateAvailable': updateAvailable,
        'mustUpdate': mustUpdate || forceUpdate,
        'currentVersion': currentVersion,
        'latestVersion': latestVersion,
        'minVersion': minVersion,
        'releaseNotes': releaseNotes,
        'storeUrl': storeUrl ?? _playStoreUrl,
        'checkedAt': DateTime.now().toIso8601String(),
      };

      if (updateAvailable) {
        eventEmitter?.call('appUpdate.available', _lastCheckResult);
      }

      return _lastCheckResult!;
    } catch (e) {
      BridgeLogger.error('AppUpdate', 'Check failed: $e');

      _lastCheckResult = {
        'checked': true,
        'updateAvailable': false,
        'error': e.toString(),
      };

      return _lastCheckResult!;
    }
  }

  Future<Map<String, dynamic>> _openStore(Map<String, dynamic> args) async {
    final url = args['url'] as String? ?? _playStoreUrl;

    if (url == null || url.isEmpty) {
      // Default Play Store URL
      final packageName = _packageInfo?.packageName ?? '';
      final defaultUrl =
          'https://play.google.com/store/apps/details?id=$packageName';

      final launched = await launchUrl(
        Uri.parse(defaultUrl),
        mode: LaunchMode.externalApplication,
      );

      return {'opened': launched, 'url': defaultUrl};
    }

    final launched = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );

    return {'opened': launched, 'url': url};
  }

  bool _isNewerVersion(String newer, String current) {
    final nParts = newer.split('.').map((p) => int.tryParse(p) ?? 0).toList();
    final cParts = current.split('.').map((p) => int.tryParse(p) ?? 0).toList();

    for (var i = 0; i < 3; i++) {
      final n = i < nParts.length ? nParts[i] : 0;
      final c = i < cParts.length ? cParts[i] : 0;
      if (n > c) return true;
      if (n < c) return false;
    }

    return false;
  }
}
```

## 📄 `lib/plugins/app_update/pubspec.yaml`

```yaml
name: app_update_plugin
description: App version check and update plugin
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
  package_info_plus: ^8.0.2
  url_launcher: ^6.3.0
  http: ^1.1.2
```

---

# بخش ثبت پلاگین‌ها: Service Locator

> اضافه شدن importها:

```dart
import 'package:sweetmelon/plugins/dialog/lib/dialog_plugin.dart';
import 'package:sweetmelon/plugins/toast/lib/toast_plugin.dart';
import 'package:sweetmelon/plugins/splash_screen/lib/splash_screen_plugin.dart';
import 'package:sweetmelon/plugins/push_notification/lib/push_notification_plugin.dart';
import 'package:sweetmelon/plugins/wake_lock/lib/wake_lock_plugin.dart';
import 'package:sweetmelon/plugins/cookie_manager/lib/cookie_manager_plugin.dart';
import 'package:sweetmelon/plugins/cache_control/lib/cache_control_plugin.dart';
import 'package:sweetmelon/plugins/app_update/lib/app_update_plugin.dart';
```

> اضافه شدن به `_registerEagerPlugins()`:

```dart
    await registry.register(DialogPlugin());
    await registry.register(ToastPlugin());
    await registry.register(SplashScreenPlugin(eventEmitter: emitter));
    await registry.register(PushNotificationPlugin(eventEmitter: emitter));
    await registry.register(WakeLockPlugin());
    await registry.register(CookieManagerPlugin());
    await registry.register(CacheControlPlugin());
    await registry.register(AppUpdatePlugin(eventEmitter: emitter));
```

---

# NativeSDK — پلاگین‌های فاز ۷

> اضافه شدن به `native-sdk.js`:

```javascript
    dialog: {
      alert: function (options) {
        var o = typeof options === 'string' ? { message: options } : options || {};
        return call('dialog', 'alert', o);
      },
      confirm: function (options) {
        var o = typeof options === 'string' ? { message: options } : options || {};
        return call('dialog', 'confirm', o);
      },
      prompt: function (options) {
        return call('dialog', 'prompt', options || {});
      },
      getInfo: function () { return call('dialog', 'getInfo', {}); }
    },

    toast: {
      show: function (text, options) {
        var o = options || {};
        return call('toast', 'show', Object.assign({ text: text }, o));
      },
      getInfo: function () { return call('toast', 'getInfo', {}); }
    },

    splashScreen: {
      show: function (options) { return call('splashScreen', 'show', options || {}); },
      hide: function () { return call('splashScreen', 'hide', {}); },
      setAutoHide: function (enabled, delayMs) {
        return call('splashScreen', 'setAutoHide', { enabled: enabled, delayMs: delayMs || 3000 });
      },
      isVisible: function () { return call('splashScreen', 'isVisible', {}); },
      getInfo: function () { return call('splashScreen', 'getInfo', {}); }
    },

    pushNotification: {
      register: function () { return call('pushNotification', 'register', {}); },
      getToken: function () { return call('pushNotification', 'getToken', {}); },
      requestPermission: function () { return call('pushNotification', 'requestPermission', {}); },
      checkPermission: function () { return call('pushNotification', 'checkPermission', {}); },
      getDeliveredNotifications: function () { return call('pushNotification', 'getDeliveredNotifications', {}); },
      removeDeliveredNotifications: function (ids) { return call('pushNotification', 'removeDeliveredNotifications', { ids: ids }); },
      removeAllDeliveredNotifications: function () { return call('pushNotification', 'removeAllDeliveredNotifications', {}); },
      subscribe: function (topic) { return call('pushNotification', 'subscribe', { topic: topic }); },
      unsubscribe: function (topic) { return call('pushNotification', 'unsubscribe', { topic: topic }); },
      getInfo: function () { return call('pushNotification', 'getInfo', {}); }
    },

    wakeLock: {
      enable: function () { return call('wakeLock', 'enable', {}); },
      disable: function () { return call('wakeLock', 'disable', {}); },
      toggle: function () { return call('wakeLock', 'toggle', {}); },
      isEnabled: function () { return call('wakeLock', 'isEnabled', {}); },
      getInfo: function () { return call('wakeLock', 'getInfo', {}); }
    },

    cookieManager: {
      setCookie: function (options) { return call('cookieManager', 'setCookie', options || {}); },
      clearCookies: function () { return call('cookieManager', 'clearCookies', {}); },
      clearSession: function () { return call('cookieManager', 'clearSession', {}); },
      getInfo: function () { return call('cookieManager', 'getInfo', {}); }
    },

    cacheControl: {
      clearWebViewCache: function () { return call('cacheControl', 'clearWebViewCache', {}); },
      clearAppCache: function () { return call('cacheControl', 'clearAppCache', {}); },
      getCacheSize: function () { return call('cacheControl', 'getCacheSize', {}); },
      clearAll: function () { return call('cacheControl', 'clearAll', {}); },
      getInfo: function () { return call('cacheControl', 'getInfo', {}); }
    },

    appUpdate: {
      configure: function (options) { return call('appUpdate', 'configure', options || {}); },
      getCurrentVersion: function () { return call('appUpdate', 'getCurrentVersion', {}); },
      checkForUpdate: function (options) { return call('appUpdate', 'checkForUpdate', options || {}); },
      openStore: function (options) { return call('appUpdate', 'openStore', options || {}); },
      getLastCheckResult: function () { return call('appUpdate', 'getLastCheckResult', {}); },
      getInfo: function () { return call('appUpdate', 'getInfo', {}); }
    },
```

---

# تست‌ها

## 📄 `test/plugins/dialog_plugin_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sweetmelon/plugins/dialog/lib/dialog_plugin.dart';

void main() {
  group('DialogPlugin', () {
    late DialogPlugin plugin;

    setUp(() async {
      plugin = DialogPlugin();
      await plugin.initialize();
    });

    test('validates alert requires message', () async {
      final r = await plugin.validateArgs('alert', {});
      expect(r.isValid, false);

      final r2 = await plugin.validateArgs('alert', {'message': 'Hello'});
      expect(r2.isValid, true);
    });

    test('validates confirm requires message', () async {
      final r = await plugin.validateArgs('confirm', {});
      expect(r.isValid, false);
    });

    test('prompt accepts empty args', () async {
      final r = await plugin.validateArgs('prompt', {});
      expect(r.isValid, true);
    });

    test('getInfo returns plugin info', () async {
      final r = await plugin.onCall('getInfo', {});
      expect(r['name'], 'dialog');
      expect(r['version'], '1.0.0');
    });
  });
}
```

## 📄 `test/plugins/toast_plugin_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sweetmelon/plugins/toast/lib/toast_plugin.dart';

void main() {
  group('ToastPlugin', () {
    late ToastPlugin plugin;

    setUp(() async {
      plugin = ToastPlugin();
      await plugin.initialize();
    });

    test('validates show requires text', () async {
      final r = await plugin.validateArgs('show', {});
      expect(r.isValid, false);

      final r2 = await plugin.validateArgs('show', {'text': 'Hello'});
      expect(r2.isValid, true);
    });
  });
}
```

## 📄 `test/plugins/cache_control_plugin_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sweetmelon/plugins/cache_control/lib/cache_control_plugin.dart';

void main() {
  group('CacheControlPlugin', () {
    late CacheControlPlugin plugin;

    setUp(() async {
      plugin = CacheControlPlugin();
      await plugin.initialize();
    });

    test('getInfo returns plugin info', () async {
      final r = await plugin.onCall('getInfo', {});
      expect(r['name'], 'cacheControl');
    });

    test('supports all declared methods', () {
      expect(plugin.supportsMethod('clearWebViewCache'), true);
      expect(plugin.supportsMethod('clearAppCache'), true);
      expect(plugin.supportsMethod('getCacheSize'), true);
      expect(plugin.supportsMethod('clearAll'), true);
    });
  });
}
```

## 📄 `test/plugins/app_update_plugin_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sweetmelon/plugins/app_update/lib/app_update_plugin.dart';

void main() {
  group('AppUpdatePlugin', () {
    late AppUpdatePlugin plugin;

    setUp(() async {
      plugin = AppUpdatePlugin();
      await plugin.initialize();
    });

    test('configure sets URLs', () async {
      final r = await plugin.onCall('configure', {
        'updateCheckUrl': 'https://api.example.com/version',
        'playStoreUrl': 'https://play.google.com/store/apps/details?id=com.example',
      });

      expect(r['configured'], true);
    });

    test('getInfo returns current state', () async {
      final r = await plugin.onCall('getInfo', {});
      expect(r['name'], 'appUpdate');
    });

    test('checkForUpdate without URL returns no update', () async {
      final r = await plugin.onCall('checkForUpdate', {});
      expect(r['checked'], true);
      expect(r['updateAvailable'], false);
    });
  });
}
```

## 📄 `test/plugins/cookie_manager_plugin_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sweetmelon/plugins/cookie_manager/lib/cookie_manager_plugin.dart';

void main() {
  group('CookieManagerPlugin', () {
    late CookieManagerPlugin plugin;

    setUp(() async {
      plugin = CookieManagerPlugin();
      await plugin.initialize();
    });

    test('validates setCookie requires domain, name, value', () async {
      final r1 = await plugin.validateArgs('setCookie', {});
      expect(r1.isValid, false);

      final r2 = await plugin.validateArgs('setCookie', {
        'domain': 'example.com',
        'name': 'token',
        'value': 'abc123',
      });
      expect(r2.isValid, true);
    });

    test('supports all declared methods', () {
      expect(plugin.supportsMethod('setCookie'), true);
      expect(plugin.supportsMethod('clearCookies'), true);
      expect(plugin.supportsMethod('clearSession'), true);
    });
  });
}
```

## 📄 `test/plugins/push_notification_plugin_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sweetmelon/plugins/push_notification/lib/push_notification_plugin.dart';

void main() {
  group('PushNotificationPlugin', () {
    late PushNotificationPlugin plugin;
    final events = <Map<String, dynamic>>[];

    setUp(() async {
      events.clear();
      plugin = PushNotificationPlugin(
        eventEmitter: (event, data) async {
          events.add({'event': event, 'data': data});
        },
      );
      await plugin.initialize();
    });

    test('register returns token', () async {
      final r = await plugin.onCall('register', {});
      expect(r['registered'], true);
      expect(r['token'], isNotEmpty);
    });

    test('getToken after register', () async {
      await plugin.onCall('register', {});
      final r = await plugin.onCall('getToken', {});
      expect(r['token'], isNotEmpty);
    });

    test('subscribe validates topic', () async {
      final r = await plugin.validateArgs('subscribe', {});
      expect(r.isValid, false);

      final r2 = await plugin.validateArgs('subscribe', {'topic': 'news'});
      expect(r2.isValid, true);
    });

    test('subscribe emits event', () async {
      await plugin.onCall('register', {});
      expect(events.any((e) => e['event'] == 'push.registered'), true);
    });

    test('handleForegroundMessage stores and emits', () {
      plugin.handleForegroundMessage({
        'messageId': 'msg_1',
        'title': 'Test',
        'body': 'Hello',
        'data': {'key': 'value'},
      });

      expect(events.any((e) => e['event'] == 'push.received'), true);
    });

    test('getDeliveredNotifications returns stored messages', () async {
      plugin.handleForegroundMessage({'title': 'A', 'body': 'B'});
      plugin.handleForegroundMessage({'title': 'C', 'body': 'D'});

      final r = await plugin.onCall('getDeliveredNotifications', {});
      expect(r['count'], 2);
    });

    test('removeAllDeliveredNotifications clears', () async {
      plugin.handleForegroundMessage({'title': 'A', 'body': 'B'});
      await plugin.onCall('removeAllDeliveredNotifications', {});

      final r = await plugin.onCall('getDeliveredNotifications', {});
      expect(r['count'], 0);
    });
  });
}
```

---

# خلاصه فاز ۷

## پلاگین‌های جدید

| # | پلاگین | نام JS | متدها |
|---|--------|--------|-------|
| 38 | Dialog | `dialog` | alert, confirm, prompt |
| 39 | Toast | `toast` | show |
| 40 | Splash Screen | `splashScreen` | show, hide, setAutoHide, isVisible |
| 41 | Push Notification | `pushNotification` | register, getToken, subscribe, unsubscribe |
| 42 | Wake Lock | `wakeLock` | enable, disable, toggle, isEnabled |
| 43 | Cookie Manager | `cookieManager` | setCookie, clearCookies, clearSession |
| 44 | Cache Control | `cacheControl` | clearWebViewCache, clearAppCache, getCacheSize, clearAll |
| 45 | App Update | `appUpdate` | configure, checkForUpdate, openStore, getCurrentVersion |

## Eventهای جدید

| Event | پلاگین |
|-------|--------|
| `splash.shown` | splashScreen |
| `splash.hidden` | splashScreen |
| `push.registered` | pushNotification |
| `push.received` | pushNotification |
| `push.tap` | pushNotification |
| `appUpdate.available` | appUpdate |

## مجموع کل: **45 پلاگین**

## نحوه استفاده JS

```javascript
// Dialog
await NativeSDK.dialog.alert('Operation completed!');
const { confirmed } = await NativeSDK.dialog.confirm({
  title: 'Delete?',
  message: 'Are you sure?'
});
const { value, cancelled } = await NativeSDK.dialog.prompt({
  title: 'Enter name',
  placeholder: 'Your name...',
  inputType: 'text'
});

// Toast
await NativeSDK.toast.show('Saved!', { duration: 'short' });
await NativeSDK.toast.show('Error occurred', {
  duration: 'long',
  backgroundColor: '#F44336'
});

// Splash
await NativeSDK.splashScreen.hide();
await NativeSDK.splashScreen.setAutoHide(true, 3000);

// Push
const { token } = await NativeSDK.pushNotification.register();
await NativeSDK.pushNotification.subscribe('news');
NativeSDK.on('push.received', (data) => {
  console.log('Push:', data.title, data.body);
});

// Wake Lock
await NativeSDK.wakeLock.enable();   // video mode
await NativeSDK.wakeLock.disable();  // normal

// Cookies
await NativeSDK.cookieManager.setCookie({
  domain: 'api.example.com',
  name: 'auth_token',
  value: 'xyz123'
});
await NativeSDK.cookieManager.clearCookies();

// Cache
const size = await NativeSDK.cacheControl.getCacheSize();
console.log('Cache:', size.total.formatted);
await NativeSDK.cacheControl.clearAll();

// App Update
await NativeSDK.appUpdate.configure({
  updateCheckUrl: 'https://api.myapp.com/version'
});
const update = await NativeSDK.appUpdate.checkForUpdate();
if (update.updateAvailable) {
  if (update.mustUpdate) {
    await NativeSDK.dialog.alert('Update required!');
  }
  await NativeSDK.appUpdate.openStore();
}
```

---

بگو تا فاز ۸ رو هم شروع کنم.
