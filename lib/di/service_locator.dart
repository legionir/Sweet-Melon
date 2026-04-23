import 'package:get_it/get_it.dart';
import '../../packages/core/lib/src/bridge/message_bridge.dart';
import '../../packages/core/lib/src/runtime/webview_host.dart';
import '../../packages/plugin_engine/lib/src/plugin_registry.dart';
import '../../packages/plugin_engine/lib/src/plugin_manager.dart';
import '../../packages/security/lib/src/permission_manager.dart';
import '../../packages/security/lib/src/rate_limiter.dart';
import '../../packages/security/lib/src/execution_guard.dart';
import '../../packages/performance/lib/src/cache_manager.dart';
import '../../packages/devtools/lib/src/bridge_inspector.dart';
import '../../plugins/camera/lib/camera_plugin.dart';
import '../../plugins/storage/lib/storage_plugin.dart';
import '../../plugins/geolocation/lib/geolocation_plugin.dart';

// ============================================================
// DEPENDENCY INJECTION
// ============================================================

final sl = GetIt.instance;

class ServiceLocator {
  static Future<void> init() async {
    // ── Infrastructure ─────────────────────────────────────
    
    sl.registerLazySingleton<CacheManager>(
      () => CacheManager(maxEntries: 500),
    );
    
    sl.registerLazySingleton<RateLimiter>(() {
      final limiter = RateLimiter();
      limiter.setDefaultRule(RateLimitRule.perSecond(50));
      return limiter;
    });
    
    sl.registerLazySingleton<ExecutionGuard>(
      () => ExecutionGuard(defaultTimeoutMs: 30000),
    );
    
    sl.registerLazySingleton<PermissionManager>(
      () => PermissionManager(),
    );

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

    // ── WebView Config ─────────────────────────────────────
    
    sl.registerLazySingleton<WebViewHostConfig>(
      () => WebViewHostConfig.development(),
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
}
