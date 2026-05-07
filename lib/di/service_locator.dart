import 'package:camera_plugin/camera_plugin.dart';
import 'package:core/src/bridge/message_bridge.dart';
import 'package:core/src/runtime/webview_host.dart';
import 'package:devtools/src/bridge_inspector.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocation_plugin/geolocation_plugin.dart';
import 'package:get_it/get_it.dart';
import 'package:performance/src/cache_manager.dart';
import 'package:plugin_engine/src/plugin_manager.dart';
import 'package:plugin_engine/src/plugin_registry.dart';
import 'package:security/src/execution_guard.dart';
import 'package:security/src/permission_manager.dart';
import 'package:security/src/rate_limiter.dart';
import 'package:storage_plugin/storage_plugin.dart';

// ============================================================
// DEPENDENCY INJECTION
// ============================================================

final sl = GetIt.instance;

class ServiceLocator {
  static Future<void> init() async {
    if (sl.isRegistered<MessageBridge>()) {
      return;
    }

    // ── Infrastructure ─────────────────────────────────────

    sl.registerLazySingleton<CacheManager>(
      () => CacheManager(maxEntries: 500),
    );

    sl.registerLazySingleton<RateLimiter>(() {
      final limiter = RateLimiter();
      limiter.setDefaultRule(RateLimitRule.perSecond(50));
      limiter.addRule('geolocation.getCurrentPosition', RateLimitRule.perSecond(5));
      limiter.addRule('camera.takePhoto', RateLimitRule.perSecond(3));
      return limiter;
    });

    sl.registerLazySingleton<ExecutionGuard>(
      () => ExecutionGuard(defaultTimeoutMs: 30000),
    );

    sl.registerLazySingleton<PermissionManager>(() {
      final manager = PermissionManager();

      // در این نمونه، provider به صورت صریح تنظیم می‌شود
      // تا رفتار "allow all" پیش‌فرض نداشته باشیم.
      manager.setProvider(
        StaticPermissionProvider(
          grants: const {
            'camera': PermissionStatus.granted,
            'storage': PermissionStatus.granted,
            'location': PermissionStatus.granted,
          },
          defaultStatus:
              kReleaseMode ? PermissionStatus.denied : PermissionStatus.granted,
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

    // اتصال event emitter به registry تا پلاگین‌ها بتوانند به JS رویداد بفرستند
    sl<PluginRegistry>().setEventEmitter(sl<MessageBridge>().emitEvent);

    // ── WebView Config ─────────────────────────────────────

    sl.registerLazySingleton<WebViewHostConfig>(
      () => kReleaseMode
          ? WebViewHostConfig.production()
          : WebViewHostConfig.development(),
    );

    // ── Dev Tools ──────────────────────────────────────────

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