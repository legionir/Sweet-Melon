import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';

import 'package:sweetmelon/packages/core/lib/core.dart';
import 'package:sweetmelon/packages/devtools/lib/devtools.dart';
import 'package:sweetmelon/packages/performance/lib/performance.dart';
import 'package:sweetmelon/packages/plugin_engine/lib/plugin_engine.dart';
import 'package:sweetmelon/packages/security/lib/security.dart';
import 'package:sweetmelon/plugins/camera/lib/camera_plugin.dart';
import 'package:sweetmelon/plugins/geolocation/lib/geolocation_plugin.dart';
import 'package:sweetmelon/plugins/storage/lib/storage_plugin.dart';

// ============================================================
// DEPENDENCY INJECTION
// ============================================================
//
// Wiring order matters: the registry receives an emitter that forwards to the
// bridge through a closure, which breaks the registry -> bridge -> manager ->
// registry cycle without a late-bound setter.

final sl = GetIt.instance;

class ServiceLocator {
  static Future<void> init() async {
    if (sl.isRegistered<MessageBridge>()) return;

    // ── Infrastructure ─────────────────────────────────────

    sl.registerLazySingleton<CacheManager>(
      () => CacheManager(maxEntries: 500),
    );

    sl.registerLazySingleton<RateLimiter>(() {
      final limiter = RateLimiter(
        defaultRule: const RateLimitRule.perSecond(50),
      );
      limiter.addRule(
        'geolocation.getCurrentPosition',
        const RateLimitRule.perSecond(5),
      );
      limiter.addRule(
        'camera.takePhoto',
        const RateLimitRule.perSecond(3),
      );
      return limiter;
    });

    sl.registerLazySingleton<ExecutionGuard>(() => ExecutionGuard());

    sl.registerLazySingleton<PermissionManager>(
      () => PermissionManager(
        provider: const PermissionHandlerProvider(),
      ),
    );

    // ── Plugin Registry ────────────────────────────────────

    sl.registerLazySingleton<PluginRegistry>(
      () => PluginRegistry(
        emitter: (event, data) => sl<MessageBridge>().emitEvent(event, data),
      ),
    );

    // ── Plugin Manager ─────────────────────────────────────

    sl.registerLazySingleton<PluginManager>(
      () => PluginManager(
        registry: sl<PluginRegistry>(),
        permissionManager: sl<PermissionManager>(),
        rateLimiter: sl<RateLimiter>(),
        executionGuard: sl<ExecutionGuard>(),
        cacheManager: sl<CacheManager>(),
        config: const PluginManagerConfig(
          timeout: Duration(seconds: 30),
        ),
      ),
    );

    // ── Message Bridge ─────────────────────────────────────

    sl.registerLazySingleton<MessageBridge>(() {
      final bridge = MessageBridge();
      final manager = sl<PluginManager>();
      bridge.setMessageHandler((request) => manager.execute(request));
      bridge.setBatchHandler(
        (requests, options) => manager.executeBatch(requests, options),
      );
      return bridge;
    });

    // ── WebView Config ─────────────────────────────────────

    sl.registerLazySingleton<WebViewHostConfig>(
      () => kReleaseMode
          ? WebViewHostConfig.production()
          : WebViewHostConfig.development(),
    );

    // ── Dev Tools (debug UI is only shown in debug builds) ─

    sl.registerLazySingleton<BridgeInspector>(
      () => BridgeInspector(
        bridge: sl<MessageBridge>(),
        manager: sl<PluginManager>(),
      ),
    );

    // ── Register Plugins ───────────────────────────────────
    await _registerPlugins();
  }

  static Future<void> _registerPlugins() async {
    final registry = sl<PluginRegistry>();
    await registry.register(CameraPlugin());
    await registry.register(StoragePlugin());
    await registry.register(GeolocationPlugin());
  }

  static Future<void> dispose() async {
    if (sl.isRegistered<BridgeInspector>()) {
      sl<BridgeInspector>().dispose();
    }
    if (sl.isRegistered<MessageBridge>()) {
      sl<MessageBridge>().dispose();
    }
    if (sl.isRegistered<PluginRegistry>()) {
      await sl<PluginRegistry>().dispose();
    }
    if (sl.isRegistered<PluginManager>()) {
      sl<PluginManager>().dispose();
    }
    if (sl.isRegistered<CacheManager>()) {
      sl<CacheManager>().dispose();
    }
    await sl.reset();
  }
}
