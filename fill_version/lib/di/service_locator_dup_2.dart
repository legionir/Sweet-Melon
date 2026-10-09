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
