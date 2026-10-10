عالی.  
من این مرحله را **مطابق معماری فعلی پروژه** و فقط با **فایل‌های جدید/تغییریافته** می‌دهم تا مستقیم بتوانی وارد پروژه کنی.

> در این پاسخ:
> - 10 پلاگین در همان معماری `Plugin / PluginRegistry / PluginManager / MessageBridge`
> - ثبت آن‌ها در `ServiceLocator`
> - تغییر لازم در `PermissionManager`
> - بازنویسی `StoragePlugin` برای key-value
> - ساخت `FileSystemPlugin`
> - event-based pluginها برای JS

---

# 1) بروزرسانی `pubspec.yaml`

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

# 2) ارتقای PermissionManager برای استفاده هم توسط موتور و هم توسط JS Plugin

## 📄 `lib/packages/security/lib/src/permission_manager.dart`

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
      case 'manageExternalStorage':
        return ph.Permission.manageExternalStorage;
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
      case 'bluetooth':
        return ph.Permission.bluetooth;
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
    final status = await checkStatus(permission);
    return status == PermissionStatus.granted;
  }

  Future<bool> request(String permission) async {
    final status = await requestStatus(permission);
    return status == PermissionStatus.granted;
  }

  Future<PermissionStatus> checkStatus(String permission) async {
    if (_cache.containsKey(permission)) {
      final timestamp = _cacheTimestamps[permission];
      if (timestamp != null &&
          DateTime.now().difference(timestamp) < cacheTtl) {
        final cached = _cache[permission]!;
        BridgeLogger.debug(
          'PermissionManager',
          'Permission "$permission" (cached): ${cached.name}',
        );
        return cached;
      } else {
        _cache.remove(permission);
        _cacheTimestamps.remove(permission);
      }
    }

    if (_provider == null) {
      BridgeLogger.warn(
        'PermissionManager',
        'No provider set, denying permission: $permission',
      );
      return PermissionStatus.denied;
    }

    final status = await _provider!.checkPermission(permission);
    _cache[permission] = status;
    _cacheTimestamps[permission] = DateTime.now();

    BridgeLogger.debug(
      'PermissionManager',
      'Permission "$permission": ${status.name}',
    );

    return status;
  }

  Future<PermissionStatus> requestStatus(String permission) async {
    if (_provider == null) {
      BridgeLogger.warn(
        'PermissionManager',
        'No provider set, cannot request: $permission',
      );
      return PermissionStatus.denied;
    }

    final status = await _provider!.requestPermission(permission);
    _cache[permission] = status;
    _cacheTimestamps[permission] = DateTime.now();

    BridgeLogger.info(
      'PermissionManager',
      'Permission requested "$permission": ${status.name}',
    );

    return status;
  }

  Future<Map<String, bool>> checkAll(List<String> permissions) async {
    final results = <String, bool>{};
    for (final permission in permissions) {
      results[permission] = await check(permission);
    }
    return results;
  }

  Future<Map<String, PermissionStatus>> checkManyStatuses(
    List<String> permissions,
  ) async {
    final results = <String, PermissionStatus>{};
    for (final permission in permissions) {
      results[permission] = await checkStatus(permission);
    }
    return results;
  }

  Future<Map<String, PermissionStatus>> requestManyStatuses(
    List<String> permissions,
  ) async {
    final results = <String, PermissionStatus>{};
    for (final permission in permissions) {
      results[permission] = await requestStatus(permission);
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

  Future<bool> openSettings() async {
    return ph.openAppSettings();
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

# 3) ثبت همه پلاگین‌ها در Service Locator

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

    await registry.register(
      PermissionPlugin(permissionManager: sl<PermissionManager>()),
    );

    await registry.register(
      AppLifecyclePlugin(eventEmitter: registry.emitEvent),
    );

    await registry.register(
      DeviceInfoBridgePlugin(),
    );

    await registry.register(
      ConnectivityBridgePlugin(eventEmitter: registry.emitEvent),
    );

    await registry.register(
      StoragePlugin(),
    );

    await registry.register(
      FileSystemPlugin(),
    );

    await registry.register(
      HttpNativePlugin(),
    );

    await registry.register(
      IntentLinkPlugin(eventEmitter: registry.emitEvent),
    );

    await registry.register(
      ClipboardPlugin(),
    );

    await registry.register(
      ShareBridgePlugin(),
    );

    await registry.register(
      CameraPlugin(),
    );

    await registry.register(
      GeolocationPlugin(eventEmitter: registry.emitEvent),
    );
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

# 4) Permission Plugin

## 📄 `lib/plugins/permission/lib/permission_plugin.dart`

```dart
import 'package:sweetmelon/packages/plugin_engine/lib/plugin_engine.dart';
import 'package:sweetmelon/packages/security/lib/security.dart' as sec;

class PermissionPlugin extends Plugin {
  final sec.PermissionManager permissionManager;

  PermissionPlugin({
    required this.permissionManager,
  });

  static const List<String> _knownPermissions = [
    'camera',
    'storage',
    'manageExternalStorage',
    'location',
    'locationAlways',
    'microphone',
    'photos',
    'notification',
    'contacts',
    'bluetooth',
  ];

  @override
  String get name => 'permission';

  @override
  String get version => '1.0.0';

  @override
  String get description => 'Permission bridge for JS';

  @override
  List<String> get supportedMethods => [
        'check',
        'request',
        'checkMany',
        'requestMany',
        'openSettings',
        'getKnownPermissions',
      ];

  @override
  Future<dynamic> onCall(String method, Map<String, dynamic> args) async {
    switch (method) {
      case 'check':
        return _check(args);
      case 'request':
        return _request(args);
      case 'checkMany':
        return _checkMany(args);
      case 'requestMany':
        return _requestMany(args);
      case 'openSettings':
        return _openSettings();
      case 'getKnownPermissions':
        return {'permissions': _knownPermissions};
      default:
        throw UnsupportedError('Method "$method" not supported');
    }
  }

  Future<Map<String, dynamic>> _check(Map<String, dynamic> args) async {
    final permission = args['permission'] as String;
    final status = await permissionManager.checkStatus(permission);
    return _statusPayload(permission, status);
  }

  Future<Map<String, dynamic>> _request(Map<String, dynamic> args) async {
    final permission = args['permission'] as String;
    final status = await permissionManager.requestStatus(permission);
    return _statusPayload(permission, status);
  }

  Future<Map<String, dynamic>> _checkMany(Map<String, dynamic> args) async {
    final permissions = List<String>.from(args['permissions'] as List);
    final statuses = await permissionManager.checkManyStatuses(permissions);

    return {
      'results': statuses.map(
        (key, value) => MapEntry(
          key,
          {
            'status': value.name,
            'granted': value == sec.PermissionStatus.granted,
          },
        ),
      ),
    };
  }

  Future<Map<String, dynamic>> _requestMany(Map<String, dynamic> args) async {
    final permissions = List<String>.from(args['permissions'] as List);
    final statuses = await permissionManager.requestManyStatuses(permissions);

    return {
      'results': statuses.map(
        (key, value) => MapEntry(
          key,
          {
            'status': value.name,
            'granted': value == sec.PermissionStatus.granted,
          },
        ),
      ),
    };
  }

  Future<Map<String, dynamic>> _openSettings() async {
    final opened = await permissionManager.openSettings();
    return {'opened': opened};
  }

  Map<String, dynamic> _statusPayload(
    String permission,
    sec.PermissionStatus status,
  ) {
    return {
      'permission': permission,
      'status': status.name,
      'granted': status == sec.PermissionStatus.granted,
      'permanentlyDenied':
          status == sec.PermissionStatus.permanentlyDenied,
    };
  }

  @override
  Future<ValidationResult> validateArgs(
    String method,
    Map<String, dynamic> args,
  ) async {
    switch (method) {
      case 'check':
      case 'request':
        final permission = args['permission'];
        if (permission is! String || permission.isEmpty) {
          return ValidationResult.invalid(
            'permission is required and must be a non-empty string',
          );
        }
        return ValidationResult.valid();

      case 'checkMany':
      case 'requestMany':
        final permissions = args['permissions'];
        if (permissions is! List || permissions.isEmpty) {
          return ValidationResult.invalid(
            'permissions is required and must be a non-empty list',
          );
        }
        if (permissions.any((e) => e is! String || e.isEmpty)) {
          return ValidationResult.invalid(
            'all permissions must be non-empty strings',
          );
        }
        return ValidationResult.valid();

      default:
        return ValidationResult.valid();
    }
  }
}
```

---

# 5) App Lifecycle Plugin

## 📄 `lib/plugins/app_lifecycle/lib/app_lifecycle_plugin.dart`

```dart
import 'package:flutter/widgets.dart';
import 'package:sweetmelon/packages/core/lib/core.dart';
import 'package:sweetmelon/packages/plugin_engine/lib/plugin_engine.dart';

typedef LifecycleEventEmitter = Future<void> Function(
  String event,
  dynamic data,
);

class AppLifecyclePlugin extends Plugin with WidgetsBindingObserver {
  final LifecycleEventEmitter? eventEmitter;

  AppLifecycleState? _currentState;
  bool _eventsEnabled = true;

  AppLifecyclePlugin({
    this.eventEmitter,
  });

  @override
  String get name => 'appLifecycle';

  @override
  String get version => '1.0.0';

  @override
  String get description => 'App lifecycle state bridge';

  @override
  List<String> get supportedMethods => [
        'getState',
        'enableEvents',
        'disableEvents',
        'getInfo',
      ];

  @override
  Future<void> onInitialize() async {
    WidgetsBinding.instance.addObserver(this);
    _currentState = WidgetsBinding.instance.lifecycleState;
  }

  @override
  Future<void> onDispose() async {
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final previous = _currentState;
    _currentState = state;

    BridgeLogger.info(
      'AppLifecycle',
      'State changed: ${previous?.name ?? "unknown"} -> ${state.name}',
    );

    if (_eventsEnabled && eventEmitter != null) {
      eventEmitter!(
        'app.lifecycle.change',
        {
          'state': state.name,
          'previousState': previous?.name,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    }
  }

  @override
  Future<dynamic> onCall(String method, Map<String, dynamic> args) async {
    switch (method) {
      case 'getState':
        return {
          'state': (_currentState ?? AppLifecycleState.resumed).name,
        };

      case 'enableEvents':
        _eventsEnabled = true;
        return {'enabled': true};

      case 'disableEvents':
        _eventsEnabled = false;
        return {'enabled': false};

      case 'getInfo':
        return {
          'state': (_currentState ?? AppLifecycleState.resumed).name,
          'eventsEnabled': _eventsEnabled,
          'supportedStates': AppLifecycleState.values
              .map((e) => e.name)
              .toList(),
        };

      default:
        throw UnsupportedError('Method "$method" not supported');
    }
  }
}
```

---

# 6) Device Info Plugin

## 📄 `lib/plugins/device_info/lib/device_info_plugin.dart`

```dart
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart' as dip;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:sweetmelon/packages/plugin_engine/lib/plugin_engine.dart';

class DeviceInfoBridgePlugin extends Plugin {
  final dip.DeviceInfoPlugin _deviceInfo = dip.DeviceInfoPlugin();

  @override
  String get name => 'deviceInfo';

  @override
  String get version => '1.0.0';

  @override
  String get description => 'Device and app info plugin';

  @override
  List<String> get supportedMethods => [
        'getDeviceInfo',
        'getAppInfo',
        'getAll',
      ];

  @override
  Future<dynamic> onCall(String method, Map<String, dynamic> args) async {
    switch (method) {
      case 'getDeviceInfo':
        return _getDeviceInfo();
      case 'getAppInfo':
        return _getAppInfo();
      case 'getAll':
        return {
          'device': await _getDeviceInfo(),
          'app': await _getAppInfo(),
        };
      default:
        throw UnsupportedError('Method "$method" not supported');
    }
  }

  Future<Map<String, dynamic>> _getDeviceInfo() async {
    final common = {
      'platform': Platform.operatingSystem,
      'platformVersion': Platform.operatingSystemVersion,
      'locale': Platform.localeName,
      'numberOfProcessors': Platform.numberOfProcessors,
      'pathSeparator': Platform.pathSeparator,
    };

    if (Platform.isAndroid) {
      final info = await _deviceInfo.androidInfo;
      return {
        ...common,
        'brand': info.brand,
        'manufacturer': info.manufacturer,
        'model': info.model,
        'device': info.device,
        'product': info.product,
        'hardware': info.hardware,
        'board': info.board,
        'id': info.id,
        'isPhysicalDevice': info.isPhysicalDevice,
        'supportedAbis': info.supportedAbis,
        'version': {
          'sdkInt': info.version.sdkInt,
          'release': info.version.release,
          'incremental': info.version.incremental,
          'securityPatch': info.version.securityPatch,
        },
      };
    }

    if (Platform.isIOS) {
      final info = await _deviceInfo.iosInfo;
      return {
        ...common,
        'name': info.name,
        'systemName': info.systemName,
        'systemVersion': info.systemVersion,
        'model': info.model,
        'localizedModel': info.localizedModel,
        'identifierForVendor': info.identifierForVendor,
        'isPhysicalDevice': info.isPhysicalDevice,
      };
    }

    return common;
  }

  Future<Map<String, dynamic>> _getAppInfo() async {
    final info = await PackageInfo.fromPlatform();
    return {
      'appName': info.appName,
      'packageName': info.packageName,
      'version': info.version,
      'buildNumber': info.buildNumber,
      'buildSignature': info.buildSignature,
    };
  }
}
```

---

# 7) Connectivity Plugin

## 📄 `lib/plugins/connectivity/lib/connectivity_plugin.dart`

```dart
import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart' as cp;
import 'package:sweetmelon/packages/core/lib/core.dart';
import 'package:sweetmelon/packages/plugin_engine/lib/plugin_engine.dart';

typedef ConnectivityEventEmitter = Future<void> Function(
  String event,
  dynamic data,
);

class ConnectivityBridgePlugin extends Plugin {
  final cp.Connectivity _connectivity = cp.Connectivity();
  final ConnectivityEventEmitter? eventEmitter;

  StreamSubscription<dynamic>? _subscription;

  ConnectivityBridgePlugin({
    this.eventEmitter,
  });

  @override
  String get name => 'connectivity';

  @override
  String get version => '1.0.0';

  @override
  String get description => 'Network connectivity plugin';

  @override
  List<String> get supportedMethods => [
        'getStatus',
        'isOnline',
        'startWatch',
        'stopWatch',
        'getInfo',
      ];

  @override
  Future<dynamic> onCall(String method, Map<String, dynamic> args) async {
    switch (method) {
      case 'getStatus':
        return _getStatus();
      case 'isOnline':
        final status = await _getStatus();
        return {'online': status['online']};
      case 'startWatch':
        return _startWatch();
      case 'stopWatch':
        return _stopWatch();
      case 'getInfo':
        return {
          'watching': _subscription != null,
          'eventName': 'connectivity.change',
        };
      default:
        throw UnsupportedError('Method "$method" not supported');
    }
  }

  Future<Map<String, dynamic>> _getStatus() async {
    final dynamic raw = await _connectivity.checkConnectivity();
    final results = _normalizeResults(raw);
    return _buildPayload(results);
  }

  Future<Map<String, dynamic>> _startWatch() async {
    if (_subscription != null) {
      return {
        'watching': true,
        'alreadyWatching': true,
      };
    }

    _subscription = _connectivity.onConnectivityChanged.listen(
      (dynamic raw) async {
        final results = _normalizeResults(raw);
        final payload = _buildPayload(results);

        BridgeLogger.info(
          'Connectivity',
          'Connectivity changed: ${payload['types']}',
        );

        if (eventEmitter != null) {
          await eventEmitter!('connectivity.change', payload);
        }
      },
      onError: (error) async {
        BridgeLogger.error('Connectivity', 'Watch error: $error');
        if (eventEmitter != null) {
          await eventEmitter!(
            'connectivity.error',
            {
              'message': error.toString(),
              'timestamp': DateTime.now().toIso8601String(),
            },
          );
        }
      },
    );

    final initial = await _getStatus();
    if (eventEmitter != null) {
      await eventEmitter!('connectivity.change', initial);
    }

    return {
      'watching': true,
      'alreadyWatching': false,
    };
  }

  Future<Map<String, dynamic>> _stopWatch() async {
    await _subscription?.cancel();
    _subscription = null;
    return {'watching': false};
  }

  List<cp.ConnectivityResult> _normalizeResults(dynamic raw) {
    if (raw is cp.ConnectivityResult) {
      return [raw];
    }

    if (raw is List<cp.ConnectivityResult>) {
      return raw;
    }

    if (raw is List) {
      return raw.whereType<cp.ConnectivityResult>().toList();
    }

    return [cp.ConnectivityResult.none];
  }

  Map<String, dynamic> _buildPayload(List<cp.ConnectivityResult> results) {
    final normalized = results.isEmpty
        ? [cp.ConnectivityResult.none]
        : results;

    final online = normalized.any((e) => e != cp.ConnectivityResult.none);

    return {
      'online': online,
      'primary': _pickPrimary(normalized).name,
      'types': normalized.map((e) => e.name).toList(),
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  cp.ConnectivityResult _pickPrimary(List<cp.ConnectivityResult> results) {
    const priority = [
      cp.ConnectivityResult.wifi,
      cp.ConnectivityResult.mobile,
      cp.ConnectivityResult.ethernet,
      cp.ConnectivityResult.bluetooth,
      cp.ConnectivityResult.vpn,
      cp.ConnectivityResult.other,
      cp.ConnectivityResult.none,
    ];

    for (final item in priority) {
      if (results.contains(item)) return item;
    }

    return cp.ConnectivityResult.none;
  }

  @override
  Future<void> onDispose() async {
    await _subscription?.cancel();
    _subscription = null;
  }
}
```

---

# 8) Storage Plugin بازنویسی شده فقط برای Key-Value

## 📄 `lib/plugins/storage/lib/storage_plugin.dart`

```dart
import 'dart:convert';

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
  String get description => 'Key-value storage plugin';

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
        'getInfo',
      ];

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
      case 'getInfo':
        return {
          'name': name,
          'version': version,
          'prefix': _keyPrefix,
          'keysCount': _getBridgeKeys().length,
        };
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
    var count = 0;

    for (final key in keys) {
      final removed = await _prefs?.remove(key) ?? false;
      if (removed) count++;
    }

    return count;
  }

  Map<String, dynamic> _keys() {
    final keys = _getBridgeKeys()
        .map((k) => k.substring(_keyPrefix.length))
        .toList();

    return {'keys': keys};
  }

  Map<String, dynamic> _has(Map<String, dynamic> args) {
    final key = args['key'] as String;
    return {'exists': _prefs?.containsKey('$_keyPrefix$key') ?? false};
  }

  List<String> _getBridgeKeys() {
    return _prefs?.getKeys().where((k) => k.startsWith(_keyPrefix)).toList() ??
        [];
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
        final keyResult = _validateKeyRequired(args);
        if (!keyResult.isValid) return keyResult;
        if (!args.containsKey('value')) {
          return ValidationResult.invalid('value is required');
        }
        return ValidationResult.valid();
      default:
        return ValidationResult.valid();
    }
  }

  ValidationResult _validateKeyRequired(Map<String, dynamic> args) {
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

# 9) File System Plugin

## 📄 `lib/plugins/file_system/lib/file_system_plugin.dart`

```dart
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sweetmelon/packages/plugin_engine/lib/plugin_engine.dart';

class FileSystemPlugin extends Plugin {
  @override
  String get name => 'fileSystem';

  @override
  String get version => '1.0.0';

  @override
  String get description => 'Sandboxed internal file system plugin';

  @override
  List<String> get supportedMethods => [
        'getDirectories',
        'readFile',
        'writeFile',
        'deleteFile',
        'fileExists',
        'listFiles',
        'createDirectory',
        'deleteDirectory',
        'stat',
        'getInfo',
      ];

  @override
  Future<dynamic> onCall(String method, Map<String, dynamic> args) async {
    switch (method) {
      case 'getDirectories':
        return _getDirectories();
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
      case 'createDirectory':
        return _createDirectory(args);
      case 'deleteDirectory':
        return _deleteDirectory(args);
      case 'stat':
        return _stat(args);
      case 'getInfo':
        return {
          'name': name,
          'version': version,
          'supportedBaseDirs': ['documents', 'cache', 'support', 'temporary'],
          'encodings': ['utf8', 'base64'],
        };
      default:
        throw UnsupportedError('Method "$method" not supported');
    }
  }

  Future<Map<String, dynamic>> _getDirectories() async {
    final documents = await getApplicationDocumentsDirectory();
    final cache = await getApplicationCacheDirectory();
    final support = await getApplicationSupportDirectory();
    final temporary = await getTemporaryDirectory();

    return {
      'documents': documents.path,
      'cache': cache.path,
      'support': support.path,
      'temporary': temporary.path,
    };
  }

  Future<Map<String, dynamic>> _readFile(Map<String, dynamic> args) async {
    final file = await _resolveFile(
      args['path'] as String,
      baseDir: args['baseDir'] as String? ?? 'documents',
    );

    if (!await file.exists()) {
      throw FileSystemException('File not found', file.path);
    }

    final encoding = args['encoding'] as String? ?? 'utf8';

    if (encoding == 'base64') {
      final bytes = await file.readAsBytes();
      return {
        'path': file.path,
        'encoding': 'base64',
        'content': base64Encode(bytes),
      };
    }

    return {
      'path': file.path,
      'encoding': 'utf8',
      'content': await file.readAsString(),
    };
  }

  Future<Map<String, dynamic>> _writeFile(Map<String, dynamic> args) async {
    final file = await _resolveFile(
      args['path'] as String,
      baseDir: args['baseDir'] as String? ?? 'documents',
    );

    final content = args['content'] as String;
    final encoding = args['encoding'] as String? ?? 'utf8';
    final append = args['append'] as bool? ?? false;

    await file.parent.create(recursive: true);

    if (encoding == 'base64') {
      final bytes = base64Decode(content);
      if (append && await file.exists()) {
        await file.writeAsBytes(bytes, mode: FileMode.append);
      } else {
        await file.writeAsBytes(bytes, mode: FileMode.write);
      }
    } else {
      if (append) {
        await file.writeAsString(content, mode: FileMode.append);
      } else {
        await file.writeAsString(content, mode: FileMode.write);
      }
    }

    final stat = await file.stat();

    return {
      'success': true,
      'path': file.path,
      'size': stat.size,
      'modified': stat.modified.toIso8601String(),
    };
  }

  Future<Map<String, dynamic>> _deleteFile(Map<String, dynamic> args) async {
    final file = await _resolveFile(
      args['path'] as String,
      baseDir: args['baseDir'] as String? ?? 'documents',
    );

    if (!await file.exists()) {
      return {'deleted': false, 'reason': 'not_found'};
    }

    await file.delete();

    return {'deleted': true};
  }

  Future<Map<String, dynamic>> _fileExists(Map<String, dynamic> args) async {
    final file = await _resolveFile(
      args['path'] as String,
      baseDir: args['baseDir'] as String? ?? 'documents',
    );

    return {'exists': await file.exists()};
  }

  Future<Map<String, dynamic>> _listFiles(Map<String, dynamic> args) async {
    final dir = await _resolveDirectory(
      args['path'] as String? ?? '',
      baseDir: args['baseDir'] as String? ?? 'documents',
    );

    if (!await dir.exists()) {
      return {'items': <dynamic>[]};
    }

    final recursive = args['recursive'] as bool? ?? false;
    final baseRoot = await _resolveBaseDir(args['baseDir'] as String? ?? 'documents');

    final entities = await dir.list(
      recursive: recursive,
      followLinks: false,
    ).toList();

    final items = <Map<String, dynamic>>[];

    for (final entity in entities) {
      final stat = await entity.stat();
      items.add({
        'name': p.basename(entity.path),
        'path': entity.path,
        'relativePath': p.relative(entity.path, from: baseRoot.path),
        'type': entity is Directory ? 'directory' : 'file',
        'size': stat.size,
        'modified': stat.modified.toIso8601String(),
      });
    }

    return {'items': items};
  }

  Future<Map<String, dynamic>> _createDirectory(
    Map<String, dynamic> args,
  ) async {
    final dir = await _resolveDirectory(
      args['path'] as String,
      baseDir: args['baseDir'] as String? ?? 'documents',
    );

    final recursive = args['recursive'] as bool? ?? true;
    await dir.create(recursive: recursive);

    return {
      'created': true,
      'path': dir.path,
    };
  }

  Future<Map<String, dynamic>> _deleteDirectory(
    Map<String, dynamic> args,
  ) async {
    final relativePath = args['path'] as String;
    if (relativePath.trim().isEmpty) {
      throw const FileSystemException(
        'Refusing to delete root base directory',
      );
    }

    final dir = await _resolveDirectory(
      relativePath,
      baseDir: args['baseDir'] as String? ?? 'documents',
    );

    if (!await dir.exists()) {
      return {'deleted': false, 'reason': 'not_found'};
    }

    final recursive = args['recursive'] as bool? ?? false;
    await dir.delete(recursive: recursive);

    return {'deleted': true};
  }

  Future<Map<String, dynamic>> _stat(Map<String, dynamic> args) async {
    final path = args['path'] as String;
    final type = args['type'] as String? ?? 'file';

    if (type == 'directory') {
      final dir = await _resolveDirectory(
        path,
        baseDir: args['baseDir'] as String? ?? 'documents',
      );

      if (!await dir.exists()) {
        return {'exists': false};
      }

      final stat = await dir.stat();
      return {
        'exists': true,
        'type': 'directory',
        'path': dir.path,
        'size': stat.size,
        'modified': stat.modified.toIso8601String(),
      };
    }

    final file = await _resolveFile(
      path,
      baseDir: args['baseDir'] as String? ?? 'documents',
    );

    if (!await file.exists()) {
      return {'exists': false};
    }

    final stat = await file.stat();
    return {
      'exists': true,
      'type': 'file',
      'path': file.path,
      'size': stat.size,
      'modified': stat.modified.toIso8601String(),
    };
  }

  Future<Directory> _resolveBaseDir(String baseDir) async {
    switch (baseDir) {
      case 'documents':
        return getApplicationDocumentsDirectory();
      case 'cache':
        return getApplicationCacheDirectory();
      case 'support':
        return getApplicationSupportDirectory();
      case 'temporary':
      case 'temp':
        return getTemporaryDirectory();
      default:
        throw FileSystemException('Unsupported baseDir: $baseDir');
    }
  }

  Future<File> _resolveFile(
    String relativePath, {
    required String baseDir,
  }) async {
    final root = await _resolveBaseDir(baseDir);
    final safePath = _normalizeRelativePath(relativePath);
    return File(p.join(root.path, safePath));
  }

  Future<Directory> _resolveDirectory(
    String relativePath, {
    required String baseDir,
  }) async {
    final root = await _resolveBaseDir(baseDir);
    final safePath = _normalizeRelativePath(relativePath);
    return Directory(p.join(root.path, safePath));
  }

  String _normalizeRelativePath(String input) {
    final normalized = p.normalize(
      input.replaceAll('\\', '/').trim(),
    );

    if (normalized.isEmpty || normalized == '.') {
      return '';
    }

    if (p.isAbsolute(normalized) ||
        normalized.startsWith('..') ||
        normalized.contains('../') ||
        normalized == '..') {
      throw const FileSystemException(
        'Invalid path: path traversal detected',
      );
    }

    return normalized;
  }

  @override
  Future<ValidationResult> validateArgs(
    String method,
    Map<String, dynamic> args,
  ) async {
    switch (method) {
      case 'readFile':
      case 'deleteFile':
      case 'fileExists':
        return _validatePathRequired(args);

      case 'writeFile':
        final pathResult = _validatePathRequired(args);
        if (!pathResult.isValid) return pathResult;

        final content = args['content'];
        if (content is! String) {
          return ValidationResult.invalid(
            'content is required and must be a string',
          );
        }

        final encoding = args['encoding'];
        if (encoding != null && encoding != 'utf8' && encoding != 'base64') {
          return ValidationResult.invalid(
            'encoding must be "utf8" or "base64"',
          );
        }

        return ValidationResult.valid();

      case 'createDirectory':
      case 'deleteDirectory':
      case 'stat':
        return _validatePathRequired(args);

      default:
        return ValidationResult.valid();
    }
  }

  ValidationResult _validatePathRequired(Map<String, dynamic> args) {
    final path = args['path'];
    if (path is! String || path.isEmpty) {
      return ValidationResult.invalid(
        'path is required and must be a non-empty string',
      );
    }

    if (path.contains('..')) {
      return ValidationResult.invalid(
        'path cannot contain ".."',
      );
    }

    return ValidationResult.valid();
  }
}
```

---

# 10) HTTP Native Plugin

## 📄 `lib/plugins/http_native/lib/http_native_plugin.dart`

```dart
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sweetmelon/packages/plugin_engine/lib/plugin_engine.dart';

class HttpNativePlugin extends Plugin {
  @override
  String get name => 'http';

  @override
  String get version => '1.0.0';

  @override
  String get description => 'Native HTTP client plugin';

  @override
  List<String> get supportedMethods => [
        'request',
        'get',
        'post',
        'put',
        'patch',
        'delete',
        'download',
      ];

  @override
  Future<dynamic> onCall(String method, Map<String, dynamic> args) async {
    switch (method) {
      case 'request':
        return _request(
          (args['method'] as String? ?? 'GET').toUpperCase(),
          args,
        );
      case 'get':
        return _request('GET', args);
      case 'post':
        return _request('POST', args);
      case 'put':
        return _request('PUT', args);
      case 'patch':
        return _request('PATCH', args);
      case 'delete':
        return _request('DELETE', args);
      case 'download':
        return _download(args);
      default:
        throw UnsupportedError('Method "$method" not supported');
    }
  }

  Future<Map<String, dynamic>> _request(
    String method,
    Map<String, dynamic> args,
  ) async {
    final url = args['url'] as String;
    final uri = _buildUri(
      url,
      args['query'] as Map<String, dynamic>?,
    );

    _validateUrlScheme(uri);

    final headers = _parseHeaders(args['headers']);
    final timeoutMs = (args['timeoutMs'] as num?)?.toInt() ?? 30000;
    final body = args['body'];
    final bodyType = args['bodyType'] as String? ?? 'auto';
    final responseType = args['responseType'] as String? ?? 'auto';

    final client = http.Client();

    try {
      final request = http.Request(method, uri);
      request.headers.addAll(headers);

      if (body != null) {
        _applyBody(
          request: request,
          body: body,
          bodyType: bodyType,
        );
      }

      final streamed = await client
          .send(request)
          .timeout(Duration(milliseconds: timeoutMs));

      final response = await http.Response.fromStream(streamed);

      return {
        'ok': response.statusCode >= 200 && response.statusCode < 300,
        'statusCode': response.statusCode,
        'headers': response.headers,
        'url': response.request?.url.toString() ?? uri.toString(),
        'data': _decodeResponseBody(response, responseType),
      };
    } finally {
      client.close();
    }
  }

  Future<Map<String, dynamic>> _download(Map<String, dynamic> args) async {
    final url = args['url'] as String;
    final uri = _buildUri(
      url,
      args['query'] as Map<String, dynamic>?,
    );

    _validateUrlScheme(uri);

    final headers = _parseHeaders(args['headers']);
    final timeoutMs = (args['timeoutMs'] as num?)?.toInt() ?? 60000;
    final overwrite = args['overwrite'] as bool? ?? true;
    final baseDir = args['baseDir'] as String? ?? 'temporary';
    final explicitPath = args['path'] as String?;
    final fileName = args['fileName'] as String? ?? _fileNameFromUri(uri);

    final root = await _resolveBaseDir(baseDir);

    final relative = explicitPath?.trim().isNotEmpty == true
        ? _safeRelativePath(explicitPath!)
        : p.join('downloads', fileName);

    final outputFile = File(p.join(root.path, relative));

    if (await outputFile.exists() && !overwrite) {
      return {
        'saved': false,
        'reason': 'already_exists',
        'path': outputFile.path,
      };
    }

    await outputFile.parent.create(recursive: true);

    final client = http.Client();

    try {
      final response = await client
          .get(uri, headers: headers)
          .timeout(Duration(milliseconds: timeoutMs));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return {
          'saved': false,
          'statusCode': response.statusCode,
          'reason': 'http_error',
        };
      }

      await outputFile.writeAsBytes(response.bodyBytes, flush: true);

      final mimeType = response.headers['content-type'] ??
          lookupMimeType(outputFile.path) ??
          'application/octet-stream';

      return {
        'saved': true,
        'statusCode': response.statusCode,
        'path': outputFile.path,
        'fileName': p.basename(outputFile.path),
        'size': response.bodyBytes.length,
        'mimeType': mimeType,
        'baseDir': baseDir,
      };
    } finally {
      client.close();
    }
  }

  Uri _buildUri(
    String url,
    Map<String, dynamic>? query,
  ) {
    final uri = Uri.parse(url);

    if (query == null || query.isEmpty) {
      return uri;
    }

    final merged = Map<String, String>.from(uri.queryParameters);
    query.forEach((key, value) {
      if (value != null) {
        merged[key] = value.toString();
      }
    });

    return uri.replace(queryParameters: merged);
  }

  void _validateUrlScheme(Uri uri) {
    if (uri.scheme != 'http' && uri.scheme != 'https') {
      throw ArgumentError('Only http and https URLs are supported');
    }
  }

  Map<String, String> _parseHeaders(dynamic raw) {
    if (raw == null) return {};
    if (raw is Map) {
      return raw.map(
        (key, value) => MapEntry(key.toString(), value.toString()),
      );
    }
    return {};
  }

  void _applyBody({
    required http.Request request,
    required dynamic body,
    required String bodyType,
  }) {
    if (bodyType == 'json' || (bodyType == 'auto' && (body is Map || body is List))) {
      request.headers.putIfAbsent('content-type', () => 'application/json');
      request.body = jsonEncode(body);
      return;
    }

    if (bodyType == 'form' && body is Map) {
      request.headers.putIfAbsent(
        'content-type',
        () => 'application/x-www-form-urlencoded',
      );
      request.bodyFields = body.map(
        (key, value) => MapEntry(key.toString(), value.toString()),
      );
      return;
    }

    if (body is String) {
      request.body = body;
      return;
    }

    request.body = body.toString();
  }

  dynamic _decodeResponseBody(http.Response response, String responseType) {
    final contentType = response.headers['content-type'] ?? '';

    if (responseType == 'base64') {
      return base64Encode(response.bodyBytes);
    }

    if (responseType == 'json' ||
        (responseType == 'auto' && contentType.contains('application/json'))) {
      try {
        return jsonDecode(response.body);
      } catch (_) {
        return response.body;
      }
    }

    if (responseType == 'bytes') {
      return base64Encode(response.bodyBytes);
    }

    return response.body;
  }

  Future<Directory> _resolveBaseDir(String baseDir) async {
    switch (baseDir) {
      case 'documents':
        return getApplicationDocumentsDirectory();
      case 'cache':
        return getApplicationCacheDirectory();
      case 'support':
        return getApplicationSupportDirectory();
      case 'temporary':
      case 'temp':
        return getTemporaryDirectory();
      default:
        throw FileSystemException('Unsupported baseDir: $baseDir');
    }
  }

  String _fileNameFromUri(Uri uri) {
    final name = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : 'download.bin';
    return name.isEmpty ? 'download.bin' : name;
  }

  String _safeRelativePath(String input) {
    final normalized = p.normalize(input.replaceAll('\\', '/').trim());

    if (normalized.isEmpty || normalized == '.') {
      throw const FileSystemException('Invalid path');
    }

    if (p.isAbsolute(normalized) ||
        normalized.startsWith('..') ||
        normalized.contains('../') ||
        normalized == '..') {
      throw const FileSystemException('Path traversal detected');
    }

    return normalized;
  }

  @override
  Future<ValidationResult> validateArgs(
    String method,
    Map<String, dynamic> args,
  ) async {
    switch (method) {
      case 'request':
      case 'get':
      case 'post':
      case 'put':
      case 'patch':
      case 'delete':
      case 'download':
        final url = args['url'];
        if (url is! String || url.isEmpty) {
          return ValidationResult.invalid(
            'url is required and must be a non-empty string',
          );
        }
        return ValidationResult.valid();
      default:
        return ValidationResult.valid();
    }
  }
}
```

---

# 11) Intent / Deep Link Plugin

## 📄 `lib/plugins/intent_link/lib/intent_link_plugin.dart`

```dart
import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:sweetmelon/packages/core/lib/core.dart';
import 'package:sweetmelon/packages/plugin_engine/lib/plugin_engine.dart';
import 'package:url_launcher/url_launcher.dart';

typedef IntentEventEmitter = Future<void> Function(
  String event,
  dynamic data,
);

class IntentLinkPlugin extends Plugin {
  final IntentEventEmitter? eventEmitter;

  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSub;

  String? _latestLink;

  IntentLinkPlugin({
    this.eventEmitter,
  });

  @override
  String get name => 'intent';

  @override
  String get version => '1.0.0';

  @override
  String get description => 'Intent launcher and deep link plugin';

  @override
  List<String> get supportedMethods => [
        'openUrl',
        'canOpenUrl',
        'getInitialLink',
        'getLatestLink',
        'startListening',
        'stopListening',
      ];

  @override
  Future<void> onInitialize() async {
    try {
      final initial = await _appLinks.getInitialLink();
      if (initial != null) {
        _latestLink = initial.toString();
      }
    } catch (e) {
      BridgeLogger.warn('Intent', 'Failed to read initial link: $e');
    }
  }

  @override
  Future<void> onDispose() async {
    await _linkSub?.cancel();
    _linkSub = null;
  }

  @override
  Future<dynamic> onCall(String method, Map<String, dynamic> args) async {
    switch (method) {
      case 'openUrl':
        return _openUrl(args);
      case 'canOpenUrl':
        return _canOpenUrl(args);
      case 'getInitialLink':
        return _getInitialLink();
      case 'getLatestLink':
        return {'url': _latestLink};
      case 'startListening':
        return _startListening();
      case 'stopListening':
        return _stopListening();
      default:
        throw UnsupportedError('Method "$method" not supported');
    }
  }

  Future<Map<String, dynamic>> _openUrl(Map<String, dynamic> args) async {
    final url = args['url'] as String;
    final uri = Uri.parse(url);

    final modeName = args['mode'] as String? ?? 'external';
    final mode = _parseLaunchMode(modeName);

    final opened = await launchUrl(uri, mode: mode);

    return {
      'opened': opened,
      'url': uri.toString(),
      'mode': modeName,
    };
  }

  Future<Map<String, dynamic>> _canOpenUrl(Map<String, dynamic> args) async {
    final url = args['url'] as String;
    final uri = Uri.parse(url);

    final canOpen = await canLaunchUrl(uri);
    return {
      'canOpen': canOpen,
      'url': uri.toString(),
    };
  }

  Future<Map<String, dynamic>> _getInitialLink() async {
    final uri = await _appLinks.getInitialLink();
    final value = uri?.toString();
    if (value != null) {
      _latestLink = value;
    }

    return {'url': value};
  }

  Future<Map<String, dynamic>> _startListening() async {
    if (_linkSub != null) {
      return {
        'listening': true,
        'alreadyListening': true,
      };
    }

    _linkSub = _appLinks.uriLinkStream.listen(
      (uri) async {
        _latestLink = uri.toString();

        BridgeLogger.info('Intent', 'Deep link received: $_latestLink');

        if (eventEmitter != null) {
          await eventEmitter!(
            'intent.deepLink',
            {
              'url': _latestLink,
              'timestamp': DateTime.now().toIso8601String(),
            },
          );
        }
      },
      onError: (error) async {
        BridgeLogger.error('Intent', 'Deep link stream error: $error');
        if (eventEmitter != null) {
          await eventEmitter!(
            'intent.error',
            {
              'message': error.toString(),
              'timestamp': DateTime.now().toIso8601String(),
            },
          );
        }
      },
    );

    return {
      'listening': true,
      'alreadyListening': false,
    };
  }

  Future<Map<String, dynamic>> _stopListening() async {
    await _linkSub?.cancel();
    _linkSub = null;
    return {'listening': false};
  }

  LaunchMode _parseLaunchMode(String mode) {
    switch (mode) {
      case 'platform':
        return LaunchMode.platformDefault;
      case 'inApp':
        return LaunchMode.inAppWebView;
      case 'externalNonBrowser':
        return LaunchMode.externalNonBrowserApplication;
      case 'external':
      default:
        return LaunchMode.externalApplication;
    }
  }

  @override
  Future<ValidationResult> validateArgs(
    String method,
    Map<String, dynamic> args,
  ) async {
    switch (method) {
      case 'openUrl':
      case 'canOpenUrl':
        final url = args['url'];
        if (url is! String || url.isEmpty) {
          return ValidationResult.invalid(
            'url is required and must be a non-empty string',
          );
        }
        return ValidationResult.valid();
      default:
        return ValidationResult.valid();
    }
  }
}
```

---

# 12) Clipboard Plugin

## 📄 `lib/plugins/clipboard/lib/clipboard_plugin.dart`

```dart
import 'package:flutter/services.dart';
import 'package:sweetmelon/packages/plugin_engine/lib/plugin_engine.dart';

class ClipboardPlugin extends Plugin {
  @override
  String get name => 'clipboard';

  @override
  String get version => '1.0.0';

  @override
  String get description => 'Clipboard text plugin';

  @override
  List<String> get supportedMethods => [
        'readText',
        'writeText',
        'hasText',
        'clear',
      ];

  @override
  Future<dynamic> onCall(String method, Map<String, dynamic> args) async {
    switch (method) {
      case 'readText':
        final data = await Clipboard.getData(Clipboard.kTextPlain);
        return {'text': data?.text};
      case 'writeText':
        final text = args['text'] as String;
        await Clipboard.setData(ClipboardData(text: text));
        return {'written': true};
      case 'hasText':
        final data = await Clipboard.getData(Clipboard.kTextPlain);
        return {'hasText': (data?.text?.isNotEmpty ?? false)};
      case 'clear':
        await Clipboard.setData(const ClipboardData(text: ''));
        return {'cleared': true};
      default:
        throw UnsupportedError('Method "$method" not supported');
    }
  }

  @override
  Future<ValidationResult> validateArgs(
    String method,
    Map<String, dynamic> args,
  ) async {
    if (method == 'writeText') {
      final text = args['text'];
      if (text is! String) {
        return ValidationResult.invalid(
          'text is required and must be a string',
        );
      }
    }
    return ValidationResult.valid();
  }
}
```

---

# 13) Share Plugin

## 📄 `lib/plugins/share/lib/share_plugin.dart`

```dart
import 'dart:io';

import 'package:cross_file/cross_file.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sweetmelon/packages/plugin_engine/lib/plugin_engine.dart';

class ShareBridgePlugin extends Plugin {
  @override
  String get name => 'share';

  @override
  String get version => '1.0.0';

  @override
  String get description => 'Native share plugin';

  @override
  List<String> get supportedMethods => [
        'shareText',
        'shareFiles',
      ];

  @override
  Future<dynamic> onCall(String method, Map<String, dynamic> args) async {
    switch (method) {
      case 'shareText':
        return _shareText(args);
      case 'shareFiles':
        return _shareFiles(args);
      default:
        throw UnsupportedError('Method "$method" not supported');
    }
  }

  Future<Map<String, dynamic>> _shareText(Map<String, dynamic> args) async {
    final text = args['text'] as String;
    final subject = args['subject'] as String?;

    await Share.share(text, subject: subject);

    return {
      'shared': true,
      'type': 'text',
    };
  }

  Future<Map<String, dynamic>> _shareFiles(Map<String, dynamic> args) async {
    final rawPaths = List<String>.from(args['paths'] as List);
    final subject = args['subject'] as String?;
    final text = args['text'] as String?;

    final files = <XFile>[];

    for (final path in rawPaths) {
      final file = File(path);
      if (!await file.exists()) {
        throw FileSystemException('File not found', path);
      }
      files.add(XFile(file.path));
    }

    await Share.shareXFiles(
      files,
      subject: subject,
      text: text,
    );

    return {
      'shared': true,
      'type': 'files',
      'count': files.length,
    };
  }

  @override
  Future<ValidationResult> validateArgs(
    String method,
    Map<String, dynamic> args,
  ) async {
    switch (method) {
      case 'shareText':
        final text = args['text'];
        if (text is! String || text.isEmpty) {
          return ValidationResult.invalid(
            'text is required and must be a non-empty string',
          );
        }
        return ValidationResult.valid();

      case 'shareFiles':
        final paths = args['paths'];
        if (paths is! List || paths.isEmpty) {
          return ValidationResult.invalid(
            'paths is required and must be a non-empty list',
          );
        }
        if (paths.any((e) => e is! String || e.isEmpty)) {
          return ValidationResult.invalid(
            'all paths must be non-empty strings',
          );
        }
        return ValidationResult.valid();

      default:
        return ValidationResult.valid();
    }
  }
}
```

---

# 14) Geolocation Plugin با همان معماری EventEmitter

> اگر این فایل را قبلاً اصلاح کرده‌ای، همین نسخه را نگه دار.

## 📄 `lib/plugins/geolocation/lib/geolocation_plugin.dart`

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
      'lowest',
      'low',
      'medium',
      'high',
      'best',
      'bestForNavigation',
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

# 15) استفاده در JS

بعد از این مرحله، JS می‌تواند این‌ها را صدا بزند:

```js
Native.call({ plugin: 'permission', method: 'check', args: { permission: 'camera' } })
Native.call({ plugin: 'appLifecycle', method: 'getState', args: {} })
Native.call({ plugin: 'deviceInfo', method: 'getAll', args: {} })
Native.call({ plugin: 'connectivity', method: 'getStatus', args: {} })
Native.call({ plugin: 'storage', method: 'set', args: { key: 'x', value: 123 } })
Native.call({ plugin: 'fileSystem', method: 'writeFile', args: { path: 'docs/a.txt', content: 'hello' } })
Native.call({ plugin: 'http', method: 'get', args: { url: 'https://example.com' } })
Native.call({ plugin: 'intent', method: 'openUrl', args: { url: 'https://google.com' } })
Native.call({ plugin: 'clipboard', method: 'writeText', args: { text: 'hello' } })
Native.call({ plugin: 'share', method: 'shareText', args: { text: 'Hello world' } })
```

و برای eventها:

```js
Native.on('app.lifecycle.change', console.log)
Native.on('connectivity.change', console.log)
Native.on('intent.deepLink', console.log)
Native.on('geolocation.position', console.log)
```

---

# 16) نکات مهم

### نام پلاگین‌ها
- permission
- appLifecycle
- deviceInfo
- connectivity
- storage
- fileSystem
- http
- intent
- clipboard
- share

### پلاگین‌های event-based
- `appLifecycle`
- `connectivity`
- `intent`
- `geolocation`

### Storage و File System
من عمداً این دو را جدا کردم:
- `storage` = key-value
- `fileSystem` = فایل و پوشه

این تفکیک برای معماری فعلی‌ات خیلی بهتر و تمیزتر است.

---

اگر بخواهی، در پیام بعدی من همین الان **مرحله بعد** را هم کامل می‌دهم:

1. **فایل‌های pubspec برای هر plugin package**  
2. **اصلاح AndroidManifest برای deep link / intent filter / share / network**  
3. **نمونه کامل HTML/JS برای تست همه این 10 پلاگین**  
4. **اضافه کردن Plugin های دوربین و geolocation به UI تست**  
5. **نوشتن یک `window.NativeSDK` لایه آماده برای Angular/React**  

اگر خواستی، من مستقیم **بخش بعدی: AndroidManifest + HTML test suite + SDK wrapper** را می‌فرستم.
