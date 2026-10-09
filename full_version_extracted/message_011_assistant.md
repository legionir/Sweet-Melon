

# فاز ۳ - پلاگین‌های پیشرفته + Angular Integration + DevTools HTML

---

# بخش ۱: پلاگین‌های جدید

---

## 📄 `lib/plugins/back_button/lib/back_button_plugin.dart`

```dart
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:sweetmelon/packages/core/lib/core.dart';
import 'package:sweetmelon/packages/plugin_engine/lib/plugin_engine.dart';

typedef BackButtonEventEmitter = Future<void> Function(
  String event,
  dynamic data,
);

class BackButtonPlugin extends Plugin with WidgetsBindingObserver {
  final BackButtonEventEmitter? eventEmitter;

  bool _interceptEnabled = false;
  bool _exitOnBack = false;

  BackButtonPlugin({this.eventEmitter});

  @override
  String get name => 'backButton';

  @override
  String get version => '1.0.0';

  @override
  String get description => 'Android back button and system navigation plugin';

  @override
  List<String> get supportedMethods => [
        'enableIntercept',
        'disableIntercept',
        'getState',
        'exitApp',
        'setExitOnBack',
        'minimizeApp',
      ];

  MethodChannel? _channel;

  @override
  Future<void> onInitialize() async {
    _channel = const MethodChannel('sweetmelon/back_button');

    _channel!.setMethodCallHandler((call) async {
      if (call.method == 'onBackPressed') {
        await _handleBackPress();
      }
      return null;
    });

    // Flutter 3.x+ predictive back gesture support
    SystemChannels.navigation.setMethodCallHandler((call) async {
      if (call.method == 'popRoute') {
        if (_interceptEnabled) {
          await _handleBackPress();
          return true; // consumed
        }
        return false;
      }
      return null;
    });
  }

  @override
  Future<void> onDispose() async {
    _interceptEnabled = false;
    _channel?.setMethodCallHandler(null);
  }

  Future<void> _handleBackPress() async {
    BridgeLogger.info('BackButton', 'Back pressed (intercept: $_interceptEnabled)');

    if (_interceptEnabled && eventEmitter != null) {
      await eventEmitter!(
        'backButton.pressed',
        {
          'intercepted': true,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    } else if (_exitOnBack) {
      SystemNavigator.pop();
    }
  }

  @override
  Future<dynamic> onCall(String method, Map<String, dynamic> args) async {
    switch (method) {
      case 'enableIntercept':
        _interceptEnabled = true;
        return {'interceptEnabled': true};

      case 'disableIntercept':
        _interceptEnabled = false;
        return {'interceptEnabled': false};

      case 'getState':
        return {
          'interceptEnabled': _interceptEnabled,
          'exitOnBack': _exitOnBack,
        };

      case 'exitApp':
        SystemNavigator.pop();
        return {'exiting': true};

      case 'setExitOnBack':
        _exitOnBack = args['enabled'] as bool? ?? false;
        return {'exitOnBack': _exitOnBack};

      case 'minimizeApp':
        // Move app to background
        await SystemChannels.platform.invokeMethod('SystemNavigator.pop');
        return {'minimized': true};

      default:
        throw UnsupportedError('Method "$method" not supported');
    }
  }
}
```

---

## 📄 `lib/plugins/back_button/pubspec.yaml`

```yaml
name: back_button_plugin
description: Back button and system navigation plugin
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

## 📄 `lib/plugins/secure_storage/lib/secure_storage_plugin.dart`

```dart
import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sweetmelon/packages/plugin_engine/lib/plugin_engine.dart';

class SecureStoragePlugin extends Plugin {
  late final FlutterSecureStorage _storage;

  static const String _keyPrefix = 'sec_';

  @override
  String get name => 'secureStorage';

  @override
  String get version => '1.0.0';

  @override
  String get description => 'Encrypted key-value secure storage plugin';

  @override
  List<String> get supportedMethods => [
        'get',
        'set',
        'remove',
        'has',
        'keys',
        'clear',
        'getInfo',
      ];

  @override
  Future<void> onInitialize() async {
    _storage = const FlutterSecureStorage(
      aOptions: AndroidOptions(
        encryptedSharedPreferences: true,
      ),
      iOptions: IOSOptions(
        accessibility: KeychainAccessibility.first_unlock_this_device,
      ),
    );
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
      case 'has':
        return _has(args);
      case 'keys':
        return _keys();
      case 'clear':
        return _clear();
      case 'getInfo':
        return {
          'name': name,
          'version': version,
          'encrypted': true,
          'prefix': _keyPrefix,
        };
      default:
        throw UnsupportedError('Method "$method" not supported');
    }
  }

  Future<Map<String, dynamic>> _get(Map<String, dynamic> args) async {
    final key = args['key'] as String;
    final raw = await _storage.read(key: '$_keyPrefix$key');

    if (raw == null) {
      return {'key': key, 'value': null, 'found': false};
    }

    dynamic decoded;
    try {
      decoded = jsonDecode(raw);
    } catch (_) {
      decoded = raw;
    }

    return {'key': key, 'value': decoded, 'found': true};
  }

  Future<Map<String, dynamic>> _set(Map<String, dynamic> args) async {
    final key = args['key'] as String;
    final value = args['value'];

    final encoded = jsonEncode(value);
    await _storage.write(key: '$_keyPrefix$key', value: encoded);

    return {'key': key, 'written': true};
  }

  Future<Map<String, dynamic>> _remove(Map<String, dynamic> args) async {
    final key = args['key'] as String;
    await _storage.delete(key: '$_keyPrefix$key');
    return {'key': key, 'removed': true};
  }

  Future<Map<String, dynamic>> _has(Map<String, dynamic> args) async {
    final key = args['key'] as String;
    final value = await _storage.read(key: '$_keyPrefix$key');
    return {'key': key, 'exists': value != null};
  }

  Future<Map<String, dynamic>> _keys() async {
    final all = await _storage.readAll();
    final bridgeKeys = all.keys
        .where((k) => k.startsWith(_keyPrefix))
        .map((k) => k.substring(_keyPrefix.length))
        .toList();

    return {'keys': bridgeKeys, 'count': bridgeKeys.length};
  }

  Future<Map<String, dynamic>> _clear() async {
    final all = await _storage.readAll();
    int count = 0;

    for (final key in all.keys) {
      if (key.startsWith(_keyPrefix)) {
        await _storage.delete(key: key);
        count++;
      }
    }

    return {'cleared': count};
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
        return _validateKey(args);
      case 'set':
        final keyResult = _validateKey(args);
        if (!keyResult.isValid) return keyResult;
        if (!args.containsKey('value')) {
          return ValidationResult.invalid('value is required');
        }
        return ValidationResult.valid();
      default:
        return ValidationResult.valid();
    }
  }

  ValidationResult _validateKey(Map<String, dynamic> args) {
    final key = args['key'];
    if (key is! String || key.isEmpty) {
      return ValidationResult.invalid(
        'key is required and must be a non-empty string',
      );
    }
    return ValidationResult.valid();
  }
}
```

---

## 📄 `lib/plugins/secure_storage/pubspec.yaml`

```yaml
name: secure_storage_plugin
description: Encrypted secure storage plugin
version: 1.0.0

environment:
  sdk: ^3.0.0

dependencies:
  flutter:
    sdk: flutter
  plugin_engine:
    path: ../../packages/plugin_engine
  flutter_secure_storage: ^9.2.2
```

---

## 📄 `lib/plugins/notification/lib/notification_plugin.dart`

```dart
import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:sweetmelon/packages/core/lib/core.dart';
import 'package:sweetmelon/packages/plugin_engine/lib/plugin_engine.dart';

typedef NotificationEventEmitter = Future<void> Function(
  String event,
  dynamic data,
);

class NotificationPlugin extends Plugin {
  final NotificationEventEmitter? eventEmitter;
  late final FlutterLocalNotificationsPlugin _notifications;
  bool _initialized = false;

  final Map<int, Map<String, dynamic>> _activeNotifications = {};

  NotificationPlugin({this.eventEmitter});

  @override
  String get name => 'notification';

  @override
  String get version => '1.0.0';

  @override
  String get description => 'Local notification plugin';

  @override
  List<String> get supportedMethods => [
        'show',
        'cancel',
        'cancelAll',
        'getActive',
        'getPending',
        'createChannel',
        'getInfo',
      ];

  @override
  Future<void> onInitialize() async {
    _notifications = FlutterLocalNotificationsPlugin();

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    final initSettings = const InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    _initialized = await _notifications.initialize(
          initSettings,
          onDidReceiveNotificationResponse: _onNotificationTap,
        ) ??
        false;

    BridgeLogger.info(
      'Notification',
      'Plugin initialized: $_initialized',
    );
  }

  void _onNotificationTap(NotificationResponse response) {
    BridgeLogger.info(
      'Notification',
      'Notification tapped: ${response.id} payload=${response.payload}',
    );

    if (eventEmitter != null) {
      eventEmitter!(
        'notification.tap',
        {
          'id': response.id,
          'actionId': response.actionId,
          'payload': response.payload,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    }
  }

  @override
  Future<dynamic> onCall(String method, Map<String, dynamic> args) async {
    switch (method) {
      case 'show':
        return _show(args);
      case 'cancel':
        return _cancel(args);
      case 'cancelAll':
        return _cancelAll();
      case 'getActive':
        return _getActive();
      case 'getPending':
        return _getPending();
      case 'createChannel':
        return _createChannel(args);
      case 'getInfo':
        return {
          'name': name,
          'version': version,
          'initialized': _initialized,
          'platform': Platform.operatingSystem,
        };
      default:
        throw UnsupportedError('Method "$method" not supported');
    }
  }

  Future<Map<String, dynamic>> _show(Map<String, dynamic> args) async {
    final id = (args['id'] as num?)?.toInt() ?? Random().nextInt(100000);
    final title = args['title'] as String? ?? '';
    final body = args['body'] as String? ?? '';
    final channelId = args['channelId'] as String? ?? 'default';
    final channelName = args['channelName'] as String? ?? 'Default';
    final payload = args['payload'] as String?;
    final importance =
        _parseImportance(args['importance'] as String? ?? 'high');
    final priority = _parsePriority(args['priority'] as String? ?? 'high');
    final ongoing = args['ongoing'] as bool? ?? false;
    final autoCancel = args['autoCancel'] as bool? ?? true;
    final silent = args['silent'] as bool? ?? false;

    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: args['channelDescription'] as String?,
      importance: importance,
      priority: priority,
      ongoing: ongoing,
      autoCancel: autoCancel,
      playSound: !silent,
      enableVibration: !silent,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(id, title, body, details, payload: payload);

    _activeNotifications[id] = {
      'id': id,
      'title': title,
      'body': body,
      'channelId': channelId,
      'payload': payload,
      'timestamp': DateTime.now().toIso8601String(),
    };

    return {'id': id, 'shown': true};
  }

  Future<Map<String, dynamic>> _cancel(Map<String, dynamic> args) async {
    final id = (args['id'] as num).toInt();
    await _notifications.cancel(id);
    _activeNotifications.remove(id);
    return {'id': id, 'cancelled': true};
  }

  Future<Map<String, dynamic>> _cancelAll() async {
    await _notifications.cancelAll();
    final count = _activeNotifications.length;
    _activeNotifications.clear();
    return {'cancelled': count};
  }

  Future<Map<String, dynamic>> _getActive() async {
    if (Platform.isAndroid) {
      final active = await _notifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.getActiveNotifications();

      if (active != null) {
        return {
          'count': active.length,
          'notifications': active.map((n) {
            return {
              'id': n.id,
              'channelId': n.channelId,
              'title': n.title,
              'body': n.body,
            };
          }).toList(),
        };
      }
    }

    return {
      'count': _activeNotifications.length,
      'notifications': _activeNotifications.values.toList(),
    };
  }

  Future<Map<String, dynamic>> _getPending() async {
    final pending = await _notifications.pendingNotificationRequests();
    return {
      'count': pending.length,
      'notifications': pending.map((n) {
        return {
          'id': n.id,
          'title': n.title,
          'body': n.body,
          'payload': n.payload,
        };
      }).toList(),
    };
  }

  Future<Map<String, dynamic>> _createChannel(
    Map<String, dynamic> args,
  ) async {
    if (!Platform.isAndroid) {
      return {'created': false, 'reason': 'not_android'};
    }

    final channelId = args['channelId'] as String;
    final channelName = args['channelName'] as String;
    final description = args['description'] as String?;
    final importance =
        _parseImportance(args['importance'] as String? ?? 'high');

    final channel = AndroidNotificationChannel(
      channelId,
      channelName,
      description: description ?? '',
      importance: importance,
    );

    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    return {'created': true, 'channelId': channelId};
  }

  Importance _parseImportance(String value) {
    switch (value) {
      case 'none':
        return Importance.none;
      case 'min':
        return Importance.min;
      case 'low':
        return Importance.low;
      case 'default':
        return Importance.defaultImportance;
      case 'high':
        return Importance.high;
      case 'max':
        return Importance.max;
      default:
        return Importance.high;
    }
  }

  Priority _parsePriority(String value) {
    switch (value) {
      case 'min':
        return Priority.min;
      case 'low':
        return Priority.low;
      case 'default':
        return Priority.defaultPriority;
      case 'high':
        return Priority.high;
      case 'max':
        return Priority.max;
      default:
        return Priority.high;
    }
  }

  @override
  Future<ValidationResult> validateArgs(
    String method,
    Map<String, dynamic> args,
  ) async {
    switch (method) {
      case 'show':
        final title = args['title'];
        if (title != null && title is! String) {
          return ValidationResult.invalid('title must be a string');
        }
        return ValidationResult.valid();

      case 'cancel':
        final id = args['id'];
        if (id is! num) {
          return ValidationResult.invalid('id is required and must be a number');
        }
        return ValidationResult.valid();

      case 'createChannel':
        final channelId = args['channelId'];
        final channelName = args['channelName'];
        if (channelId is! String || channelId.isEmpty) {
          return ValidationResult.invalid('channelId is required');
        }
        if (channelName is! String || channelName.isEmpty) {
          return ValidationResult.invalid('channelName is required');
        }
        return ValidationResult.valid();

      default:
        return ValidationResult.valid();
    }
  }
}
```

---

## 📄 `lib/plugins/notification/pubspec.yaml`

```yaml
name: notification_plugin
description: Local notification bridge plugin
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
  flutter_local_notifications: ^17.2.4
```

---

## 📄 `lib/plugins/status_bar/lib/status_bar_plugin.dart`

```dart
import 'package:flutter/services.dart';
import 'package:sweetmelon/packages/plugin_engine/lib/plugin_engine.dart';

class StatusBarPlugin extends Plugin {
  SystemUiOverlayStyle _currentStyle = SystemUiOverlayStyle.light;

  @override
  String get name => 'statusBar';

  @override
  String get version => '1.0.0';

  @override
  String get description => 'Status bar and system UI control plugin';

  @override
  List<String> get supportedMethods => [
        'setStyle',
        'setColor',
        'show',
        'hide',
        'setFullscreen',
        'exitFullscreen',
        'getInfo',
      ];

  @override
  Future<dynamic> onCall(String method, Map<String, dynamic> args) async {
    switch (method) {
      case 'setStyle':
        return _setStyle(args);
      case 'setColor':
        return _setColor(args);
      case 'show':
        return _show();
      case 'hide':
        return _hide();
      case 'setFullscreen':
        return _setFullscreen();
      case 'exitFullscreen':
        return _exitFullscreen();
      case 'getInfo':
        return {
          'name': name,
          'version': version,
          'supportedStyles': ['light', 'dark'],
        };
      default:
        throw UnsupportedError('Method "$method" not supported');
    }
  }

  Map<String, dynamic> _setStyle(Map<String, dynamic> args) {
    final style = args['style'] as String? ?? 'light';

    if (style == 'dark') {
      _currentStyle = SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: _parseColor(args['backgroundColor']),
      );
    } else {
      _currentStyle = SystemUiOverlayStyle.light.copyWith(
        statusBarColor: _parseColor(args['backgroundColor']),
      );
    }

    SystemChrome.setSystemUIOverlayStyle(_currentStyle);

    return {'style': style, 'applied': true};
  }

  Map<String, dynamic> _setColor(Map<String, dynamic> args) {
    final color = _parseColor(args['color']) ?? const Color(0x00000000);
    final navColor = _parseColor(args['navigationBarColor']);

    _currentStyle = _currentStyle.copyWith(
      statusBarColor: color,
      systemNavigationBarColor: navColor,
    );

    SystemChrome.setSystemUIOverlayStyle(_currentStyle);

    return {'applied': true};
  }

  Map<String, dynamic> _show() {
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
    return {'visible': true};
  }

  Map<String, dynamic> _hide() {
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: [],
    );
    return {'visible': false};
  }

  Map<String, dynamic> _setFullscreen() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    return {'fullscreen': true};
  }

  Map<String, dynamic> _exitFullscreen() {
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
    return {'fullscreen': false};
  }

  Color? _parseColor(dynamic value) {
    if (value == null) return null;

    if (value is String) {
      var hex = value.replaceAll('#', '').trim();
      if (hex.length == 6) hex = 'FF$hex';
      if (hex.length == 8) {
        final intColor = int.tryParse(hex, radix: 16);
        if (intColor != null) return Color(intColor);
      }
    }

    if (value is int) {
      return Color(value);
    }

    return null;
  }
}
```

---

## 📄 `lib/plugins/status_bar/pubspec.yaml`

```yaml
name: status_bar_plugin
description: Status bar and system UI plugin
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

## 📄 `lib/plugins/orientation/lib/orientation_plugin.dart`

```dart
import 'package:flutter/services.dart';
import 'package:sweetmelon/packages/plugin_engine/lib/plugin_engine.dart';

class OrientationPlugin extends Plugin {
  @override
  String get name => 'orientation';

  @override
  String get version => '1.0.0';

  @override
  String get description => 'Screen orientation control plugin';

  @override
  List<String> get supportedMethods => [
        'lock',
        'unlock',
        'getInfo',
      ];

  @override
  Future<dynamic> onCall(String method, Map<String, dynamic> args) async {
    switch (method) {
      case 'lock':
        return _lock(args);
      case 'unlock':
        return _unlock();
      case 'getInfo':
        return {
          'name': name,
          'version': version,
          'supportedOrientations': [
            'portrait',
            'portraitUp',
            'portraitDown',
            'landscape',
            'landscapeLeft',
            'landscapeRight',
          ],
        };
      default:
        throw UnsupportedError('Method "$method" not supported');
    }
  }

  Future<Map<String, dynamic>> _lock(Map<String, dynamic> args) async {
    final orientation = args['orientation'] as String? ?? 'portrait';

    final orientations = _parseOrientations(orientation);

    await SystemChrome.setPreferredOrientations(orientations);

    return {'locked': true, 'orientation': orientation};
  }

  Future<Map<String, dynamic>> _unlock() async {
    await SystemChrome.setPreferredOrientations(
      DeviceOrientation.values,
    );

    return {'locked': false, 'orientation': 'all'};
  }

  List<DeviceOrientation> _parseOrientations(String orientation) {
    switch (orientation) {
      case 'portrait':
        return [
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
        ];
      case 'portraitUp':
        return [DeviceOrientation.portraitUp];
      case 'portraitDown':
        return [DeviceOrientation.portraitDown];
      case 'landscape':
        return [
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ];
      case 'landscapeLeft':
        return [DeviceOrientation.landscapeLeft];
      case 'landscapeRight':
        return [DeviceOrientation.landscapeRight];
      default:
        return DeviceOrientation.values;
    }
  }

  @override
  Future<ValidationResult> validateArgs(
    String method,
    Map<String, dynamic> args,
  ) async {
    if (method == 'lock') {
      final orientation = args['orientation'];
      if (orientation != null && orientation is! String) {
        return ValidationResult.invalid('orientation must be a string');
      }
    }
    return ValidationResult.valid();
  }
}
```

---

## 📄 `lib/plugins/orientation/pubspec.yaml`

```yaml
name: orientation_plugin
description: Screen orientation control plugin
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

## 📄 `lib/plugins/haptic/lib/haptic_plugin.dart`

```dart
import 'package:flutter/services.dart';
import 'package:sweetmelon/packages/plugin_engine/lib/plugin_engine.dart';

class HapticPlugin extends Plugin {
  @override
  String get name => 'haptic';

  @override
  String get version => '1.0.0';

  @override
  String get description => 'Haptic feedback and vibration plugin';

  @override
  List<String> get supportedMethods => [
        'lightImpact',
        'mediumImpact',
        'heavyImpact',
        'selectionClick',
        'vibrate',
        'getInfo',
      ];

  @override
  Future<dynamic> onCall(String method, Map<String, dynamic> args) async {
    switch (method) {
      case 'lightImpact':
        await HapticFeedback.lightImpact();
        return {'type': 'light', 'triggered': true};

      case 'mediumImpact':
        await HapticFeedback.mediumImpact();
        return {'type': 'medium', 'triggered': true};

      case 'heavyImpact':
        await HapticFeedback.heavyImpact();
        return {'type': 'heavy', 'triggered': true};

      case 'selectionClick':
        await HapticFeedback.selectionClick();
        return {'type': 'selection', 'triggered': true};

      case 'vibrate':
        await HapticFeedback.vibrate();
        return {'type': 'vibrate', 'triggered': true};

      case 'getInfo':
        return {
          'name': name,
          'version': version,
          'supportedTypes': [
            'lightImpact',
            'mediumImpact',
            'heavyImpact',
            'selectionClick',
            'vibrate',
          ],
        };

      default:
        throw UnsupportedError('Method "$method" not supported');
    }
  }
}
```

---

## 📄 `lib/plugins/haptic/pubspec.yaml`

```yaml
name: haptic_plugin
description: Haptic feedback plugin
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

## 📄 `lib/plugins/keyboard/lib/keyboard_plugin.dart`

```dart
import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:sweetmelon/packages/core/lib/core.dart';
import 'package:sweetmelon/packages/plugin_engine/lib/plugin_engine.dart';

typedef KeyboardEventEmitter = Future<void> Function(
  String event,
  dynamic data,
);

class KeyboardPlugin extends Plugin with WidgetsBindingObserver {
  final KeyboardEventEmitter? eventEmitter;

  bool _watchEnabled = false;
  bool _isVisible = false;
  double _keyboardHeight = 0;

  KeyboardPlugin({this.eventEmitter});

  @override
  String get name => 'keyboard';

  @override
  String get version => '1.0.0';

  @override
  String get description => 'Keyboard visibility and height plugin';

  @override
  List<String> get supportedMethods => [
        'getState',
        'startWatch',
        'stopWatch',
        'hide',
        'getInfo',
      ];

  @override
  Future<void> onInitialize() async {
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  Future<void> onDispose() async {
    WidgetsBinding.instance.removeObserver(this);
    _watchEnabled = false;
  }

  @override
  void didChangeMetrics() {
    _checkKeyboardState();
  }

  void _checkKeyboardState() {
    final view = WidgetsBinding.instance.platformDispatcher.views.first;
    final bottomInset = view.viewInsets.bottom / view.devicePixelRatio;

    final wasVisible = _isVisible;
    _isVisible = bottomInset > 50;
    _keyboardHeight = bottomInset;

    if (_watchEnabled && wasVisible != _isVisible && eventEmitter != null) {
      eventEmitter!(
        'keyboard.change',
        {
          'visible': _isVisible,
          'height': _keyboardHeight,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    }
  }

  @override
  Future<dynamic> onCall(String method, Map<String, dynamic> args) async {
    switch (method) {
      case 'getState':
        _checkKeyboardState();
        return {
          'visible': _isVisible,
          'height': _keyboardHeight,
        };

      case 'startWatch':
        _watchEnabled = true;
        return {'watching': true};

      case 'stopWatch':
        _watchEnabled = false;
        return {'watching': false};

      case 'hide':
        FocusManager.instance.primaryFocus?.unfocus();
        return {'hidden': true};

      case 'getInfo':
        return {
          'name': name,
          'version': version,
          'watching': _watchEnabled,
          'visible': _isVisible,
          'height': _keyboardHeight,
        };

      default:
        throw UnsupportedError('Method "$method" not supported');
    }
  }
}
```

---

## 📄 `lib/plugins/keyboard/pubspec.yaml`

```yaml
name: keyboard_plugin
description: Keyboard visibility plugin
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

# بخش ۲: بروزرسانی pubspec.yaml اصلی

## 📄 `pubspec.yaml`

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
  path: ^1.9.0
  uuid: ^4.2.1
  get_it: ^7.6.4
  http: ^1.1.2
  image_picker: ^1.0.4
  geolocator: ^10.1.0
  permission_handler: ^11.3.0
  mime: ^1.0.5

  connectivity_plus: ^6.0.5
  device_info_plus: ^10.1.2
  package_info_plus: ^8.0.2
  url_launcher: ^6.3.0
  app_links: ^6.3.2
  share_plus: ^10.0.2
  cross_file: ^0.3.4+2

  flutter_secure_storage: ^9.2.2
  flutter_local_notifications: ^17.2.4

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

# بخش ۳: بروزرسانی Service Locator با همه پلاگین‌های جدید

## 📄 `lib/di/service_locator.dart`

```dart
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';

import 'package:sweetmelon/packages/core/lib/core.dart';
import 'package:sweetmelon/packages/devtools/lib/devtools.dart';
import 'package:sweetmelon/packages/performance/lib/performance.dart';
import 'package:sweetmelon/packages/security/lib/security.dart';
import 'package:sweetmelon/packages/plugin_engine/lib/plugin_engine.dart';

import 'package:sweetmelon/plugins/permission/lib/permission_plugin.dart';
import 'package:sweetmelon/plugins/app_lifecycle/lib/app_lifecycle_plugin.dart';
import 'package:sweetmelon/plugins/device_info/lib/device_info_plugin.dart';
import 'package:sweetmelon/plugins/connectivity/lib/connectivity_plugin.dart';
import 'package:sweetmelon/plugins/storage/lib/storage_plugin.dart';
import 'package:sweetmelon/plugins/file_system/lib/file_system_plugin.dart';
import 'package:sweetmelon/plugins/http_native/lib/http_native_plugin.dart';
import 'package:sweetmelon/plugins/intent_link/lib/intent_link_plugin.dart';
import 'package:sweetmelon/plugins/clipboard/lib/clipboard_plugin.dart';
import 'package:sweetmelon/plugins/share/lib/share_plugin.dart';
import 'package:sweetmelon/plugins/geolocation/lib/geolocation_plugin.dart';
import 'package:sweetmelon/plugins/camera/lib/camera_plugin.dart';

import 'package:sweetmelon/plugins/back_button/lib/back_button_plugin.dart';
import 'package:sweetmelon/plugins/secure_storage/lib/secure_storage_plugin.dart';
import 'package:sweetmelon/plugins/notification/lib/notification_plugin.dart';
import 'package:sweetmelon/plugins/status_bar/lib/status_bar_plugin.dart';
import 'package:sweetmelon/plugins/orientation/lib/orientation_plugin.dart';
import 'package:sweetmelon/plugins/haptic/lib/haptic_plugin.dart';
import 'package:sweetmelon/plugins/keyboard/lib/keyboard_plugin.dart';

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
        final manager = PermissionManager(
          cacheTtl: const Duration(minutes: 3),
        );

        manager.setProvider(
          NativePermissionProvider(
            fallbackStatus: kReleaseMode
                ? PermissionStatus.denied
                : PermissionStatus.granted,
          ),
        );

        manager.addPolicy(
          'camera',
          const PermissionPolicy(required: ['camera']),
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
    final emitter = registry.emitEvent;

    // فاز ۱ — پایه
    await registry.register(
      PermissionPlugin(permissionManager: sl<PermissionManager>()),
    );
    await registry.register(
      AppLifecyclePlugin(eventEmitter: emitter),
    );
    await registry.register(DeviceInfoBridgePlugin());
    await registry.register(
      ConnectivityBridgePlugin(eventEmitter: emitter),
    );
    await registry.register(StoragePlugin());
    await registry.register(FileSystemPlugin());
    await registry.register(HttpNativePlugin());
    await registry.register(IntentLinkPlugin(eventEmitter: emitter));
    await registry.register(ClipboardPlugin());
    await registry.register(ShareBridgePlugin());
    await registry.register(CameraPlugin());
    await registry.register(GeolocationPlugin(eventEmitter: emitter));

    // فاز ۳ — پیشرفته
    await registry.register(BackButtonPlugin(eventEmitter: emitter));
    await registry.register(SecureStoragePlugin());
    await registry.register(NotificationPlugin(eventEmitter: emitter));
    await registry.register(StatusBarPlugin());
    await registry.register(OrientationPlugin());
    await registry.register(HapticPlugin());
    await registry.register(KeyboardPlugin(eventEmitter: emitter));
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

# بخش ۴: بروزرسانی NativeSDK با پلاگین‌های جدید

## 📄 `assets/www/js/native-sdk.js`

> اضافه کردن namespace های جدید به آخر فایل قبلی  
> **کل فایل کامل:**

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
      Object.assign({ plugin: plugin, method: method, args: args || {} }, extra || {})
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
      return { initialized: false, pendingRequests: 0, totalRequests: 0, version: null };
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

    /* ───── فاز ۱ ───── */

    permission: {
      check: function (p) { return call('permission', 'check', { permission: p }); },
      request: function (p) { return call('permission', 'request', { permission: p }); },
      checkMany: function (ps) { return call('permission', 'checkMany', { permissions: ps }); },
      requestMany: function (ps) { return call('permission', 'requestMany', { permissions: ps }); },
      openSettings: function () { return call('permission', 'openSettings', {}); },
      getKnownPermissions: function () { return call('permission', 'getKnownPermissions', {}); }
    },

    appLifecycle: {
      getState: function () { return call('appLifecycle', 'getState', {}); },
      enableEvents: function () { return call('appLifecycle', 'enableEvents', {}); },
      disableEvents: function () { return call('appLifecycle', 'disableEvents', {}); },
      getInfo: function () { return call('appLifecycle', 'getInfo', {}); }
    },

    deviceInfo: {
      getDeviceInfo: function () { return call('deviceInfo', 'getDeviceInfo', {}); },
      getAppInfo: function () { return call('deviceInfo', 'getAppInfo', {}); },
      getAll: function () { return call('deviceInfo', 'getAll', {}); }
    },

    connectivity: {
      getStatus: function () { return call('connectivity', 'getStatus', {}); },
      isOnline: function () { return call('connectivity', 'isOnline', {}); },
      startWatch: function () { return call('connectivity', 'startWatch', {}); },
      stopWatch: function () { return call('connectivity', 'stopWatch', {}); },
      getInfo: function () { return call('connectivity', 'getInfo', {}); }
    },

    storage: {
      get: function (k) { return call('storage', 'get', { key: k }); },
      set: function (k, v) { return call('storage', 'set', { key: k, value: v }); },
      remove: function (k) { return call('storage', 'remove', { key: k }); },
      clear: function () { return call('storage', 'clear', {}); },
      keys: function () { return call('storage', 'keys', {}); },
      has: function (k) { return call('storage', 'has', { key: k }); }
    },

    fileSystem: {
      getDirectories: function () { return call('fileSystem', 'getDirectories', {}); },
      readFile: function (p, b, e) { return call('fileSystem', 'readFile', { path: p, baseDir: b || 'documents', encoding: e || 'utf8' }); },
      writeFile: function (p, c, o) { o = o || {}; return call('fileSystem', 'writeFile', { path: p, content: c, baseDir: o.baseDir || 'documents', encoding: o.encoding || 'utf8', append: !!o.append }); },
      deleteFile: function (p, b) { return call('fileSystem', 'deleteFile', { path: p, baseDir: b || 'documents' }); },
      fileExists: function (p, b) { return call('fileSystem', 'fileExists', { path: p, baseDir: b || 'documents' }); },
      listFiles: function (p, o) { o = o || {}; return call('fileSystem', 'listFiles', { path: p || '', baseDir: o.baseDir || 'documents', recursive: !!o.recursive }); },
      createDirectory: function (p, o) { o = o || {}; return call('fileSystem', 'createDirectory', { path: p, baseDir: o.baseDir || 'documents', recursive: o.recursive !== false }); },
      deleteDirectory: function (p, o) { o = o || {}; return call('fileSystem', 'deleteDirectory', { path: p, baseDir: o.baseDir || 'documents', recursive: !!o.recursive }); },
      stat: function (p, o) { o = o || {}; return call('fileSystem', 'stat', { path: p, baseDir: o.baseDir || 'documents', type: o.type || 'file' }); }
    },

    http: {
      request: function (o) { return call('http', 'request', o || {}); },
      get: function (u, o) { return call('http', 'get', Object.assign({ url: u }, o || {})); },
      post: function (u, b, o) { return call('http', 'post', Object.assign({ url: u, body: b }, o || {})); },
      put: function (u, b, o) { return call('http', 'put', Object.assign({ url: u, body: b }, o || {})); },
      patch: function (u, b, o) { return call('http', 'patch', Object.assign({ url: u, body: b }, o || {})); },
      delete: function (u, o) { return call('http', 'delete', Object.assign({ url: u }, o || {})); },
      download: function (o) { return call('http', 'download', o || {}); }
    },

    intent: {
      openUrl: function (u, m) { return call('intent', 'openUrl', { url: u, mode: m || 'external' }); },
      canOpenUrl: function (u) { return call('intent', 'canOpenUrl', { url: u }); },
      getInitialLink: function () { return call('intent', 'getInitialLink', {}); },
      getLatestLink: function () { return call('intent', 'getLatestLink', {}); },
      startListening: function () { return call('intent', 'startListening', {}); },
      stopListening: function () { return call('intent', 'stopListening', {}); }
    },

    clipboard: {
      readText: function () { return call('clipboard', 'readText', {}); },
      writeText: function (t) { return call('clipboard', 'writeText', { text: t }); },
      hasText: function () { return call('clipboard', 'hasText', {}); },
      clear: function () { return call('clipboard', 'clear', {}); }
    },

    share: {
      shareText: function (t, s) { return call('share', 'shareText', { text: t, subject: s || null }); },
      shareFiles: function (p, t, s) { return call('share', 'shareFiles', { paths: p, text: t || null, subject: s || null }); }
    },

    camera: {
      getInfo: function () { return call('camera', 'getInfo', {}); },
      takePhoto: function (o) { return call('camera', 'takePhoto', o || {}); },
      pickFromGallery: function (o) { return call('camera', 'pickFromGallery', o || {}); }
    },

    geolocation: {
      checkPermission: function () { return call('geolocation', 'checkPermission', {}); },
      requestPermission: function () { return call('geolocation', 'requestPermission', {}); },
      getCurrentPosition: function (o) { return call('geolocation', 'getCurrentPosition', o || {}); },
      watchPosition: function (o) { return call('geolocation', 'watchPosition', o || {}); },
      clearWatch: function () { return call('geolocation', 'clearWatch', {}); },
      isLocationEnabled: function () { return call('geolocation', 'isLocationEnabled', {}); }
    },

    /* ───── فاز ۳ ───── */

    backButton: {
      enableIntercept: function () { return call('backButton', 'enableIntercept', {}); },
      disableIntercept: function () { return call('backButton', 'disableIntercept', {}); },
      getState: function () { return call('backButton', 'getState', {}); },
      exitApp: function () { return call('backButton', 'exitApp', {}); },
      setExitOnBack: function (enabled) { return call('backButton', 'setExitOnBack', { enabled: !!enabled }); },
      minimizeApp: function () { return call('backButton', 'minimizeApp', {}); }
    },

    secureStorage: {
      get: function (k) { return call('secureStorage', 'get', { key: k }); },
      set: function (k, v) { return call('secureStorage', 'set', { key: k, value: v }); },
      remove: function (k) { return call('secureStorage', 'remove', { key: k }); },
      has: function (k) { return call('secureStorage', 'has', { key: k }); },
      keys: function () { return call('secureStorage', 'keys', {}); },
      clear: function () { return call('secureStorage', 'clear', {}); },
      getInfo: function () { return call('secureStorage', 'getInfo', {}); }
    },

    notification: {
      show: function (o) { return call('notification', 'show', o || {}); },
      cancel: function (id) { return call('notification', 'cancel', { id: id }); },
      cancelAll: function () { return call('notification', 'cancelAll', {}); },
      getActive: function () { return call('notification', 'getActive', {}); },
      getPending: function () { return call('notification', 'getPending', {}); },
      createChannel: function (o) { return call('notification', 'createChannel', o || {}); },
      getInfo: function () { return call('notification', 'getInfo', {}); }
    },

    statusBar: {
      setStyle: function (style, bg) { return call('statusBar', 'setStyle', { style: style, backgroundColor: bg || null }); },
      setColor: function (c, nav) { return call('statusBar', 'setColor', { color: c, navigationBarColor: nav || null }); },
      show: function () { return call('statusBar', 'show', {}); },
      hide: function () { return call('statusBar', 'hide', {}); },
      setFullscreen: function () { return call('statusBar', 'setFullscreen', {}); },
      exitFullscreen: function () { return call('statusBar', 'exitFullscreen', {}); },
      getInfo: function () { return call('statusBar', 'getInfo', {}); }
    },

    orientation: {
      lock: function (o) { return call('orientation', 'lock', { orientation: o || 'portrait' }); },
      unlock: function () { return call('orientation', 'unlock', {}); },
      getInfo: function () { return call('orientation', 'getInfo', {}); }
    },

    haptic: {
      lightImpact: function () { return call('haptic', 'lightImpact', {}); },
      mediumImpact: function () { return call('haptic', 'mediumImpact', {}); },
      heavyImpact: function () { return call('haptic', 'heavyImpact', {}); },
      selectionClick: function () { return call('haptic', 'selectionClick', {}); },
      vibrate: function () { return call('haptic', 'vibrate', {}); },
      getInfo: function () { return call('haptic', 'getInfo', {}); }
    },

    keyboard: {
      getState: function () { return call('keyboard', 'getState', {}); },
      startWatch: function () { return call('keyboard', 'startWatch', {}); },
      stopWatch: function () { return call('keyboard', 'stopWatch', {}); },
      hide: function () { return call('keyboard', 'hide', {}); },
      getInfo: function () { return call('keyboard', 'getInfo', {}); }
    }
  };

  global.NativeSDK = sdk;
})(window);
```

---

# بخش ۵: بروزرسانی HTML — اضافه کردن پنل‌های جدید

## 📄 `assets/www/index.html`

> فقط پنل‌های جدید اضافه می‌شوند بین `</section>` Geolocation و `<section class="panel"><div class="panel-title">Output`

**محتوای کامل:**

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no" />
  <title>Sweetmelon Native Bridge Test Suite</title>
  <link rel="stylesheet" href="css/styles.css" />
</head>
<body>
<div class="container">

  <header class="page-header">
    <div>
      <h1>Sweetmelon Native Bridge</h1>
      <p>Full test suite — 19 plugins</p>
    </div>
    <div class="header-actions">
      <button class="secondary" id="btnBridgeInfo">Bridge Info</button>
      <button class="secondary" id="btnBatchTest">Batch Test</button>
      <button class="secondary" id="btnClearLog">Clear Log</button>
    </div>
  </header>

  <section class="status-grid">
    <div class="status-card"><span class="status-label">Bridge</span><strong id="bridgeState">Waiting...</strong></div>
    <div class="status-card"><span class="status-label">Requests</span><strong id="requestCount">0</strong></div>
    <div class="status-card"><span class="status-label">Pending</span><strong id="pendingCount">0</strong></div>
    <div class="status-card"><span class="status-label">Events</span><strong id="eventCount">0</strong></div>
  </section>

  <!-- Permission -->
  <section class="panel"><div class="panel-title">Permission</div>
    <div class="row">
      <input id="permissionName" value="camera" placeholder="camera / location / notification" />
      <button id="btnPermissionCheck">Check</button>
      <button id="btnPermissionRequest">Request</button>
      <button id="btnPermissionKnown">Known</button>
      <button id="btnPermissionSettings">Settings</button>
    </div>
  </section>

  <!-- App Lifecycle -->
  <section class="panel"><div class="panel-title">App Lifecycle</div>
    <div class="row">
      <button id="btnLifecycleState">Get State</button>
      <button id="btnLifecycleEnable">Enable Events</button>
      <button id="btnLifecycleDisable">Disable Events</button>
      <button id="btnLifecycleInfo">Info</button>
    </div>
  </section>

  <!-- Device Info -->
  <section class="panel"><div class="panel-title">Device Info</div>
    <div class="row">
      <button id="btnDeviceInfo">Device</button>
      <button id="btnAppInfo">App</button>
      <button id="btnDeviceAll">All</button>
    </div>
  </section>

  <!-- Connectivity -->
  <section class="panel"><div class="panel-title">Connectivity</div>
    <div class="row">
      <button id="btnConnectivityStatus">Status</button>
      <button id="btnConnectivityStart">Start Watch</button>
      <button id="btnConnectivityStop">Stop Watch</button>
      <button id="btnConnectivityIsOnline">Online?</button>
    </div>
  </section>

  <!-- Storage -->
  <section class="panel"><div class="panel-title">Storage</div>
    <div class="row">
      <input id="storageKey" value="demo_key" placeholder="key" />
      <input id="storageValue" value='{"hello":"world"}' placeholder="value" />
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

  <!-- File System -->
  <section class="panel"><div class="panel-title">File System</div>
    <div class="row">
      <input id="filePath" value="demo/test.txt" placeholder="path" />
      <input id="fileContent" value="Hello from WebView" placeholder="content" />
    </div>
    <div class="row">
      <button id="btnFsDirs">Dirs</button>
      <button id="btnFsWrite">Write</button>
      <button id="btnFsRead">Read</button>
      <button id="btnFsExists">Exists</button>
      <button id="btnFsList">List</button>
      <button id="btnFsStat">Stat</button>
      <button id="btnFsDelete">Delete</button>
    </div>
  </section>

  <!-- HTTP -->
  <section class="panel"><div class="panel-title">HTTP Native</div>
    <div class="row">
      <input id="httpUrl" value="https://jsonplaceholder.typicode.com/todos/1" placeholder="url" />
    </div>
    <div class="row">
      <button id="btnHttpGet">GET</button>
      <button id="btnHttpPost">POST</button>
      <button id="btnHttpDownload">Download</button>
    </div>
  </section>

  <!-- Intent -->
  <section class="panel"><div class="panel-title">Intent / Deep Link</div>
    <div class="row">
      <input id="intentUrl" value="https://flutter.dev" placeholder="url" />
    </div>
    <div class="row">
      <button id="btnIntentCanOpen">Can Open</button>
      <button id="btnIntentOpen">Open</button>
      <button id="btnIntentInitial">Initial Link</button>
      <button id="btnIntentLatest">Latest</button>
      <button id="btnIntentListenStart">Listen</button>
      <button id="btnIntentListenStop">Stop</button>
    </div>
  </section>

  <!-- Clipboard -->
  <section class="panel"><div class="panel-title">Clipboard</div>
    <div class="row">
      <input id="clipboardText" value="Copied from Sweetmelon" placeholder="text" />
    </div>
    <div class="row">
      <button id="btnClipboardWrite">Write</button>
      <button id="btnClipboardRead">Read</button>
      <button id="btnClipboardHas">Has?</button>
      <button id="btnClipboardClear">Clear</button>
    </div>
  </section>

  <!-- Share -->
  <section class="panel"><div class="panel-title">Share</div>
    <div class="row">
      <input id="shareText" value="Hello from Sweetmelon native share" placeholder="text" />
    </div>
    <div class="row">
      <button id="btnShareText">Share Text</button>
      <button id="btnShareFile">Create & Share File</button>
    </div>
  </section>

  <!-- Camera -->
  <section class="panel"><div class="panel-title">Camera</div>
    <div class="row">
      <button id="btnCameraInfo">Info</button>
      <button id="btnTakePhoto">Photo</button>
      <button id="btnPickGallery">Gallery</button>
    </div>
  </section>

  <!-- Geolocation -->
  <section class="panel"><div class="panel-title">Geolocation</div>
    <div class="row">
      <button id="btnGeoPermission">Check Perm</button>
      <button id="btnGeoRequestPermission">Request Perm</button>
      <button id="btnGeoCurrent">Current Pos</button>
      <button id="btnGeoStart">Watch</button>
      <button id="btnGeoStop">Stop</button>
      <button id="btnGeoEnabled">Enabled?</button>
    </div>
  </section>

  <!-- ───── فاز ۳ ───── -->

  <!-- Back Button -->
  <section class="panel"><div class="panel-title">Back Button</div>
    <div class="row">
      <button id="btnBackEnable">Intercept On</button>
      <button id="btnBackDisable">Intercept Off</button>
      <button id="btnBackState">State</button>
      <button id="btnBackExitOnBack">Exit On Back</button>
      <button id="btnBackMinimize">Minimize</button>
      <button id="btnBackExit">Exit App</button>
    </div>
  </section>

  <!-- Secure Storage -->
  <section class="panel"><div class="panel-title">Secure Storage</div>
    <div class="row">
      <input id="secKey" value="token" placeholder="key" />
      <input id="secValue" value="my-secret-jwt-token-xyz" placeholder="value" />
    </div>
    <div class="row">
      <button id="btnSecSet">Set</button>
      <button id="btnSecGet">Get</button>
      <button id="btnSecHas">Has</button>
      <button id="btnSecKeys">Keys</button>
      <button id="btnSecRemove">Remove</button>
      <button id="btnSecClear">Clear</button>
      <button id="btnSecInfo">Info</button>
    </div>
  </section>

  <!-- Notification -->
  <section class="panel"><div class="panel-title">Notification</div>
    <div class="row">
      <input id="notifTitle" value="Hello" placeholder="title" />
      <input id="notifBody" value="This is a local notification from JS" placeholder="body" />
    </div>
    <div class="row">
      <button id="btnNotifShow">Show</button>
      <button id="btnNotifCancelAll">Cancel All</button>
      <button id="btnNotifActive">Active</button>
      <button id="btnNotifPending">Pending</button>
      <button id="btnNotifChannel">Create Channel</button>
      <button id="btnNotifInfo">Info</button>
    </div>
  </section>

  <!-- Status Bar -->
  <section class="panel"><div class="panel-title">Status Bar</div>
    <div class="row">
      <button id="btnSbDark">Dark</button>
      <button id="btnSbLight">Light</button>
      <button id="btnSbHide">Hide</button>
      <button id="btnSbShow">Show</button>
      <button id="btnSbFullscreen">Fullscreen</button>
      <button id="btnSbExitFs">Exit Fullscreen</button>
    </div>
  </section>

  <!-- Orientation -->
  <section class="panel"><div class="panel-title">Orientation</div>
    <div class="row">
      <button id="btnOrPortrait">Portrait</button>
      <button id="btnOrLandscape">Landscape</button>
      <button id="btnOrUnlock">Unlock</button>
      <button id="btnOrInfo">Info</button>
    </div>
  </section>

  <!-- Haptic -->
  <section class="panel"><div class="panel-title">Haptic</div>
    <div class="row">
      <button id="btnHapLight">Light</button>
      <button id="btnHapMedium">Medium</button>
      <button id="btnHapHeavy">Heavy</button>
      <button id="btnHapClick">Click</button>
      <button id="btnHapVibrate">Vibrate</button>
    </div>
  </section>

  <!-- Keyboard -->
  <section class="panel"><div class="panel-title">Keyboard</div>
    <div class="row">
      <button id="btnKbState">State</button>
      <button id="btnKbWatch">Watch</button>
      <button id="btnKbStopWatch">Stop Watch</button>
      <button id="btnKbHide">Hide</button>
      <button id="btnKbInfo">Info</button>
    </div>
  </section>

  <!-- Output -->
  <section class="panel">
    <div class="panel-title">Output</div>
    <pre id="output" class="output">{}</pre>
  </section>

  <!-- Log -->
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

# بخش ۶: بروزرسانی `app.js` با همه دکمه‌های جدید

## 📄 `assets/www/js/app.js`

```javascript
(function () {
  'use strict';

  var outputEl, logEl, requestCount = 0, eventCount = 0;

  function $(id) { return document.getElementById(id); }

  function updateStats() {
    var info = window.NativeSDK ? window.NativeSDK.info() : null;
    $('bridgeState').textContent = info && info.initialized ? 'Ready' : 'Waiting...';
    $('requestCount').textContent = String(info ? info.totalRequests : requestCount);
    $('pendingCount').textContent = String(info ? info.pendingRequests : 0);
    $('eventCount').textContent = String(eventCount);
  }

  function log(msg, type) {
    type = type || 'info';
    var item = document.createElement('div');
    item.className = 'log-item log-' + type;
    var now = new Date();
    var t = now.toLocaleTimeString('en-US', { hour12: false, hour: '2-digit', minute: '2-digit', second: '2-digit' });
    item.textContent = '[' + t + '] ' + msg;
    logEl.prepend(item);
    while (logEl.children.length > 300) logEl.removeChild(logEl.lastChild);
  }

  function show(data) { outputEl.textContent = JSON.stringify(data, null, 2); }

  function parseJ(v) { if (!v || !v.trim()) return null; try { return JSON.parse(v); } catch (_) { return v; } }

  async function run(label, fn) {
    requestCount++; updateStats(); log('→ ' + label, 'info');
    try {
      var r = await fn(); show(r); log('✓ ' + label, 'success'); updateStats(); return r;
    } catch (e) {
      var m = e && e.message ? e.message : JSON.stringify(e);
      show({ error: m, raw: e }); log('✗ ' + label + ' — ' + m, 'error'); updateStats(); throw e;
    }
  }

  function bind() {
    var S = window.NativeSDK;

    // Header
    $('btnBridgeInfo').onclick = function () { show(S.info()); updateStats(); };
    $('btnClearLog').onclick = function () { logEl.innerHTML = ''; eventCount = 0; updateStats(); };
    $('btnBatchTest').onclick = function () {
      run('batch test (4 calls)', function () {
        return S.batch([
          { plugin: 'storage', method: 'keys', args: {} },
          { plugin: 'deviceInfo', method: 'getAppInfo', args: {} },
          { plugin: 'connectivity', method: 'getStatus', args: {} },
          { plugin: 'clipboard', method: 'hasText', args: {} }
        ], { parallel: true });
      });
    };

    // Permission
    $('btnPermissionCheck').onclick = function () { run('permission.check', function () { return S.permission.check($('permissionName').value.trim()); }); };
    $('btnPermissionRequest').onclick = function () { run('permission.request', function () { return S.permission.request($('permissionName').value.trim()); }); };
    $('btnPermissionKnown').onclick = function () { run('permission.known', function () { return S.permission.getKnownPermissions(); }); };
    $('btnPermissionSettings').onclick = function () { run('permission.settings', function () { return S.permission.openSettings(); }); };

    // App Lifecycle
    $('btnLifecycleState').onclick = function () { run('appLifecycle.getState', function () { return S.appLifecycle.getState(); }); };
    $('btnLifecycleEnable').onclick = function () { run('appLifecycle.enable', function () { return S.appLifecycle.enableEvents(); }); };
    $('btnLifecycleDisable').onclick = function () { run('appLifecycle.disable', function () { return S.appLifecycle.disableEvents(); }); };
    $('btnLifecycleInfo').onclick = function () { run('appLifecycle.info', function () { return S.appLifecycle.getInfo(); }); };

    // Device
    $('btnDeviceInfo').onclick = function () { run('deviceInfo', function () { return S.deviceInfo.getDeviceInfo(); }); };
    $('btnAppInfo').onclick = function () { run('appInfo', function () { return S.deviceInfo.getAppInfo(); }); };
    $('btnDeviceAll').onclick = function () { run('deviceAll', function () { return S.deviceInfo.getAll(); }); };

    // Connectivity
    $('btnConnectivityStatus').onclick = function () { run('connectivity.status', function () { return S.connectivity.getStatus(); }); };
    $('btnConnectivityStart').onclick = function () { run('connectivity.start', function () { return S.connectivity.startWatch(); }); };
    $('btnConnectivityStop').onclick = function () { run('connectivity.stop', function () { return S.connectivity.stopWatch(); }); };
    $('btnConnectivityIsOnline').onclick = function () { run('connectivity.online', function () { return S.connectivity.isOnline(); }); };

    // Storage
    $('btnStorageSet').onclick = function () { run('storage.set', function () { return S.storage.set($('storageKey').value.trim(), parseJ($('storageValue').value)); }); };
    $('btnStorageGet').onclick = function () { run('storage.get', function () { return S.storage.get($('storageKey').value.trim()); }); };
    $('btnStorageHas').onclick = function () { run('storage.has', function () { return S.storage.has($('storageKey').value.trim()); }); };
    $('btnStorageKeys').onclick = function () { run('storage.keys', function () { return S.storage.keys(); }); };
    $('btnStorageRemove').onclick = function () { run('storage.remove', function () { return S.storage.remove($('storageKey').value.trim()); }); };
    $('btnStorageClear').onclick = function () { run('storage.clear', function () { return S.storage.clear(); }); };

    // FileSystem
    $('btnFsDirs').onclick = function () { run('fs.dirs', function () { return S.fileSystem.getDirectories(); }); };
    $('btnFsWrite').onclick = function () { run('fs.write', function () { return S.fileSystem.writeFile($('filePath').value.trim(), $('fileContent').value); }); };
    $('btnFsRead').onclick = function () { run('fs.read', function () { return S.fileSystem.readFile($('filePath').value.trim()); }); };
    $('btnFsExists').onclick = function () { run('fs.exists', function () { return S.fileSystem.fileExists($('filePath').value.trim()); }); };
    $('btnFsList').onclick = function () { run('fs.list', function () { return S.fileSystem.listFiles('demo', { recursive: true }); }); };
    $('btnFsStat').onclick = function () { run('fs.stat', function () { return S.fileSystem.stat($('filePath').value.trim()); }); };
    $('btnFsDelete').onclick = function () { run('fs.delete', function () { return S.fileSystem.deleteFile($('filePath').value.trim()); }); };

    // HTTP
    $('btnHttpGet').onclick = function () { run('http.get', function () { return S.http.get($('httpUrl').value.trim(), { responseType: 'json' }); }); };
    $('btnHttpPost').onclick = function () { run('http.post', function () { return S.http.post('https://jsonplaceholder.typicode.com/posts', { title: 'sweetmelon', body: 'post body', userId: 1 }, { bodyType: 'json', responseType: 'json' }); }); };
    $('btnHttpDownload').onclick = function () { run('http.download', function () { return S.http.download({ url: 'https://jsonplaceholder.typicode.com/todos/1', fileName: 'todo.json', baseDir: 'temporary' }); }); };

    // Intent
    $('btnIntentCanOpen').onclick = function () { run('intent.canOpen', function () { return S.intent.canOpenUrl($('intentUrl').value.trim()); }); };
    $('btnIntentOpen').onclick = function () { run('intent.open', function () { return S.intent.openUrl($('intentUrl').value.trim()); }); };
    $('btnIntentInitial').onclick = function () { run('intent.initial', function () { return S.intent.getInitialLink(); }); };
    $('btnIntentLatest').onclick = function () { run('intent.latest', function () { return S.intent.getLatestLink(); }); };
    $('btnIntentListenStart').onclick = function () { run('intent.listen', function () { return S.intent.startListening(); }); };
    $('btnIntentListenStop').onclick = function () { run('intent.stopListen', function () { return S.intent.stopListening(); }); };

    // Clipboard
    $('btnClipboardWrite').onclick = function () { run('clipboard.write', function () { return S.clipboard.writeText($('clipboardText').value); }); };
    $('btnClipboardRead').onclick = function () { run('clipboard.read', function () { return S.clipboard.readText(); }); };
    $('btnClipboardHas').onclick = function () { run('clipboard.has', function () { return S.clipboard.hasText(); }); };
    $('btnClipboardClear').onclick = function () { run('clipboard.clear', function () { return S.clipboard.clear(); }); };

    // Share
    $('btnShareText').onclick = function () { run('share.text', function () { return S.share.shareText($('shareText').value, 'Sweetmelon'); }); };
    $('btnShareFile').onclick = async function () {
      await run('fs.write (prep share)', function () { return S.fileSystem.writeFile('share/demo.txt', 'Share file at ' + new Date().toISOString()); });
      var dirs = await run('fs.dirs', function () { return S.fileSystem.getDirectories(); });
      await run('share.files', function () { return S.share.shareFiles([(dirs.documents || '') + '/share/demo.txt'], 'Shared file', 'Sweetmelon'); });
    };

    // Camera
    $('btnCameraInfo').onclick = function () { run('camera.info', function () { return S.camera.getInfo(); }); };
    $('btnTakePhoto').onclick = function () { run('camera.photo', function () { return S.camera.takePhoto({ quality: 80 }); }); };
    $('btnPickGallery').onclick = function () { run('camera.gallery', function () { return S.camera.pickFromGallery({ multiple: false }); }); };

    // Geolocation
    $('btnGeoPermission').onclick = function () { run('geo.checkPerm', function () { return S.geolocation.checkPermission(); }); };
    $('btnGeoRequestPermission').onclick = function () { run('geo.requestPerm', function () { return S.geolocation.requestPermission(); }); };
    $('btnGeoCurrent').onclick = function () { run('geo.current', function () { return S.geolocation.getCurrentPosition({ accuracy: 'high' }); }); };
    $('btnGeoStart').onclick = function () { run('geo.watch', function () { return S.geolocation.watchPosition({ accuracy: 'high', distanceFilter: 10 }); }); };
    $('btnGeoStop').onclick = function () { run('geo.stop', function () { return S.geolocation.clearWatch(); }); };
    $('btnGeoEnabled').onclick = function () { run('geo.enabled', function () { return S.geolocation.isLocationEnabled(); }); };

    // ── فاز ۳ ──

    // Back Button
    $('btnBackEnable').onclick = function () { run('back.enableIntercept', function () { return S.backButton.enableIntercept(); }); };
    $('btnBackDisable').onclick = function () { run('back.disableIntercept', function () { return S.backButton.disableIntercept(); }); };
    $('btnBackState').onclick = function () { run('back.state', function () { return S.backButton.getState(); }); };
    $('btnBackExitOnBack').onclick = function () { run('back.exitOnBack', function () { return S.backButton.setExitOnBack(true); }); };
    $('btnBackMinimize').onclick = function () { run('back.minimize', function () { return S.backButton.minimizeApp(); }); };
    $('btnBackExit').onclick = function () { run('back.exit', function () { return S.backButton.exitApp(); }); };

    // Secure Storage
    $('btnSecSet').onclick = function () { run('sec.set', function () { return S.secureStorage.set($('secKey').value.trim(), $('secValue').value); }); };
    $('btnSecGet').onclick = function () { run('sec.get', function () { return S.secureStorage.get($('secKey').value.trim()); }); };
    $('btnSecHas').onclick = function () { run('sec.has', function () { return S.secureStorage.has($('secKey').value.trim()); }); };
    $('btnSecKeys').onclick = function () { run('sec.keys', function () { return S.secureStorage.keys(); }); };
    $('btnSecRemove').onclick = function () { run('sec.remove', function () { return S.secureStorage.remove($('secKey').value.trim()); }); };
    $('btnSecClear').onclick = function () { run('sec.clear', function () { return S.secureStorage.clear(); }); };
    $('btnSecInfo').onclick = function () { run('sec.info', function () { return S.secureStorage.getInfo(); }); };

    // Notification
    $('btnNotifShow').onclick = function () { run('notif.show', function () { return S.notification.show({ title: $('notifTitle').value, body: $('notifBody').value, payload: 'custom-payload-123' }); }); };
    $('btnNotifCancelAll').onclick = function () { run('notif.cancelAll', function () { return S.notification.cancelAll(); }); };
    $('btnNotifActive').onclick = function () { run('notif.active', function () { return S.notification.getActive(); }); };
    $('btnNotifPending').onclick = function () { run('notif.pending', function () { return S.notification.getPending(); }); };
    $('btnNotifChannel').onclick = function () { run('notif.channel', function () { return S.notification.createChannel({ channelId: 'alerts', channelName: 'Alerts', importance: 'high' }); }); };
    $('btnNotifInfo').onclick = function () { run('notif.info', function () { return S.notification.getInfo(); }); };

    // Status Bar
    $('btnSbDark').onclick = function () { run('sb.dark', function () { return S.statusBar.setStyle('dark'); }); };
    $('btnSbLight').onclick = function () { run('sb.light', function () { return S.statusBar.setStyle('light'); }); };
    $('btnSbHide').onclick = function () { run('sb.hide', function () { return S.statusBar.hide(); }); };
    $('btnSbShow').onclick = function () { run('sb.show', function () { return S.statusBar.show(); }); };
    $('btnSbFullscreen').onclick = function () { run('sb.fullscreen', function () { return S.statusBar.setFullscreen(); }); };
    $('btnSbExitFs').onclick = function () { run('sb.exitFs', function () { return S.statusBar.exitFullscreen(); }); };

    // Orientation
    $('btnOrPortrait').onclick = function () { run('or.portrait', function () { return S.orientation.lock('portrait'); }); };
    $('btnOrLandscape').onclick = function () { run('or.landscape', function () { return S.orientation.lock('landscape'); }); };
    $('btnOrUnlock').onclick = function () { run('or.unlock', function () { return S.orientation.unlock(); }); };
    $('btnOrInfo').onclick = function () { run('or.info', function () { return S.orientation.getInfo(); }); };

    // Haptic
    $('btnHapLight').onclick = function () { run('hap.light', function () { return S.haptic.lightImpact(); }); };
    $('btnHapMedium').onclick = function () { run('hap.medium', function () { return S.haptic.mediumImpact(); }); };
    $('btnHapHeavy').onclick = function () { run('hap.heavy', function () { return S.haptic.heavyImpact(); }); };
    $('btnHapClick').onclick = function () { run('hap.click', function () { return S.haptic.selectionClick(); }); };
    $('btnHapVibrate').onclick = function () { run('hap.vibrate', function () { return S.haptic.vibrate(); }); };

    // Keyboard
    $('btnKbState').onclick = function () { run('kb.state', function () { return S.keyboard.getState(); }); };
    $('btnKbWatch').onclick = function () { run('kb.watch', function () { return S.keyboard.startWatch(); }); };
    $('btnKbStopWatch').onclick = function () { run('kb.stopWatch', function () { return S.keyboard.stopWatch(); }); };
    $('btnKbHide').onclick = function () { run('kb.hide', function () { return S.keyboard.hide(); }); };
    $('btnKbInfo').onclick = function () { run('kb.info', function () { return S.keyboard.getInfo(); }); };
  }

  function bindEvents() {
    var S = window.NativeSDK;

    var events = [
      'app.lifecycle.change',
      'connectivity.change',
      'connectivity.error',
      'intent.deepLink',
      'intent.error',
      'geolocation.position',
      'geolocation.error',
      'backButton.pressed',
      'notification.tap',
      'keyboard.change'
    ];

    events.forEach(function (ev) {
      S.on(ev, function (data) {
        eventCount++;
        log('EVENT ' + ev + ' → ' + JSON.stringify(data), 'event');
        updateStats();
      });
    });
  }

  async function init() {
    outputEl = $('output');
    logEl = $('log');
    updateStats();
    log('Initializing NativeSDK...', 'info');

    try {
      await window.NativeSDK.waitForReady(10000);
      log('NativeSDK ready', 'success');
      updateStats();
      bind();
      bindEvents();

      try { await window.NativeSDK.connectivity.startWatch(); } catch (_) {}
      try { await window.NativeSDK.intent.startListening(); } catch (_) {}
      try { await window.NativeSDK.keyboard.startWatch(); } catch (_) {}
    } catch (e) {
      log('Init failed: ' + e.message, 'error');
      show({ error: e.message });
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

# بخش ۷: Angular Integration Guide

## 📄 `docs/angular-integration.md`

```markdown
# Angular Integration Guide

## ۱) Build Angular
```bash
ng build --configuration production \
  --output-path /path/to/flutter/assets/www \
  --base-href ./
```

## ۲) اضافه کردن Bridge SDK

فایل `native-sdk.js` را در `angular.json` اضافه کنید:

```json
"scripts": [
  "src/assets/native-sdk.js"
]
```

یا در `index.html`:

```html
<script src="assets/native-sdk.js"></script>
```

## ۳) سرویس Angular

فایل `src/app/services/native-bridge.service.ts`:

```typescript
import { Injectable, NgZone } from '@angular/core';

declare const NativeSDK: any;

@Injectable({ providedIn: 'root' })
export class NativeBridgeService {
  private ready = false;

  constructor(private zone: NgZone) {}

  async init(): Promise<void> {
    if (this.ready) return;
    await NativeSDK.waitForReady(10000);
    this.ready = true;
  }

  async call<T = any>(plugin: string, method: string, args?: any): Promise<T> {
    await this.init();
    return NativeSDK.call(plugin, method, args || {});
  }

  on(event: string, callback: (data: any) => void): () => void {
    return NativeSDK.on(event, (data: any) => {
      this.zone.run(() => callback(data));
    });
  }

  // Shortcut methods

  get storage() { return NativeSDK.storage; }
  get secureStorage() { return NativeSDK.secureStorage; }
  get http() { return NativeSDK.http; }
  get deviceInfo() { return NativeSDK.deviceInfo; }
  get permission() { return NativeSDK.permission; }
  get connectivity() { return NativeSDK.connectivity; }
  get clipboard() { return NativeSDK.clipboard; }
  get share() { return NativeSDK.share; }
  get notification() { return NativeSDK.notification; }
  get statusBar() { return NativeSDK.statusBar; }
  get orientation() { return NativeSDK.orientation; }
  get haptic() { return NativeSDK.haptic; }
  get keyboard() { return NativeSDK.keyboard; }
  get backButton() { return NativeSDK.backButton; }
  get intent() { return NativeSDK.intent; }
  get fileSystem() { return NativeSDK.fileSystem; }
  get camera() { return NativeSDK.camera; }
  get geolocation() { return NativeSDK.geolocation; }
  get appLifecycle() { return NativeSDK.appLifecycle; }
}
```

## ۴) استفاده در Component

```typescript
import { Component, OnInit, OnDestroy } from '@angular/core';
import { NativeBridgeService } from './services/native-bridge.service';

@Component({
  selector: 'app-root',
  template: `
    <div>
      <p>Online: {{ isOnline }}</p>
      <p>Device: {{ deviceModel }}</p>
      <button (click)="saveData()">Save</button>
      <button (click)="loadData()">Load</button>
    </div>
  `
})
export class AppComponent implements OnInit, OnDestroy {
  isOnline = true;
  deviceModel = '';

  private unsubConnectivity?: () => void;
  private unsubBack?: () => void;

  constructor(private native: NativeBridgeService) {}

  async ngOnInit() {
    // Device info
    const info = await this.native.deviceInfo.getAll();
    this.deviceModel = info.device?.model || 'Unknown';

    // Connectivity watch
    this.unsubConnectivity = this.native.on('connectivity.change', (data) => {
      this.isOnline = data.online;
    });

    // Back button
    await this.native.backButton.enableIntercept();
    this.unsubBack = this.native.on('backButton.pressed', () => {
      // handle back in Angular router
      window.history.back();
    });
  }

  async saveData() {
    await this.native.storage.set('user', { name: 'Ali', role: 'admin' });
    await this.native.haptic.lightImpact();
  }

  async loadData() {
    const data = await this.native.storage.get('user');
    console.log('Loaded:', data);
  }

  ngOnDestroy() {
    this.unsubConnectivity?.();
    this.unsubBack?.();
  }
}
```

## ۵) Routing + Back Button

در `app.module.ts`:

```typescript
import { APP_INITIALIZER } from '@angular/core';

export function initBridge(native: NativeBridgeService) {
  return () => native.init();
}

@NgModule({
  providers: [
    {
      provide: APP_INITIALIZER,
      useFactory: initBridge,
      deps: [NativeBridgeService],
      multi: true
    }
  ]
})
export class AppModule {}
```

## ۶) نکات مهم

- **base-href**: حتما `./` باشد
- **SPA routing**: AssetServer از fallback به `index.html` پشتیبانی می‌کند
- **Zone.js**: eventهای bridge خارج از Angular zone هستند، باید با `NgZone.run` برگردانید
- **Type Safety**: فایل `native-sdk.d.ts` را در `src/typings.d.ts` import کنید
```

---

# خلاصه فاز ۳

## پلاگین‌های جدید اضافه شده

| پلاگین | نام | متدها |
|--------|-----|-------|
| Back Button | `backButton` | enableIntercept, disableIntercept, getState, exitApp, setExitOnBack, minimizeApp |
| Secure Storage | `secureStorage` | get, set, remove, has, keys, clear, getInfo |
| Notification | `notification` | show, cancel, cancelAll, getActive, getPending, createChannel, getInfo |
| Status Bar | `statusBar` | setStyle, setColor, show, hide, setFullscreen, exitFullscreen |
| Orientation | `orientation` | lock, unlock, getInfo |
| Haptic | `haptic` | lightImpact, mediumImpact, heavyImpact, selectionClick, vibrate |
| Keyboard | `keyboard` | getState, startWatch, stopWatch, hide, getInfo |

## Eventهای جدید

| Event | منبع |
|-------|------|
| `backButton.pressed` | BackButtonPlugin |
| `notification.tap` | NotificationPlugin |
| `keyboard.change` | KeyboardPlugin |

## مجموع پلاگین‌ها: **19 عدد**

| # | نام | فاز |
|---|-----|------|
| 1 | permission | ۱ |
| 2 | appLifecycle | ۱ |
| 3 | deviceInfo | ۱ |
| 4 | connectivity | ۱ |
| 5 | storage | ۱ |
| 6 | fileSystem | ۱ |
| 7 | http | ۱ |
| 8 | intent | ۱ |
| 9 | clipboard | ۱ |
| 10 | share | ۱ |
| 11 | camera | ۱ |
| 12 | geolocation | ۱ |
| 13 | backButton | ۳ |
| 14 | secureStorage | ۳ |
| 15 | notification | ۳ |
| 16 | statusBar | ۳ |
| 17 | orientation | ۳ |
| 18 | haptic | ۳ |
| 19 | keyboard | ۳ |

---

اگر بخواهی، در فاز بعدی می‌توانم اضافه کنم:

1. **Biometrics Plugin** (اثرانگشت / Face)
2. **QR Scanner Plugin**
3. **Audio Recorder / Player Plugin**
4. **SMS / OTP Auto-Read Plugin**
5. **Download Manager Plugin** (با progress event)
6. **Database (SQLite) Plugin**
7. **Contacts Plugin**
8. **Phone Dialer Plugin**

بگو تا شروع کنم.
