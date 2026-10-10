# پیام ۲/۳: Plugin Lazy Loading + Hot Reload

---

## معماری

```
JS calls: NativeSDK.bluetooth.scan()
  ↓
PluginManager.execute()
  ↓
Plugin registered? ──→ YES ──→ Plugin.isReady?
       │                            │
       NO                      YES → execute
       ↓                            │
LazyPluginLoader                NO → initialize → execute
  ↓
registry.resolve() → null
  ↓
LazyRegistry.canLoad()?
  ↓ YES
Load + Initialize + Register
  ↓
Execute
```

---

## بخش ۱: Lazy Plugin Loader

### 📄 `lib/packages/plugin_engine/lib/src/lazy_plugin_loader.dart`

```dart
import 'dart:async';

import 'package:sweetmelon/packages/core/lib/core.dart';
import 'plugin_interface.dart';
import 'plugin_registry.dart';

/// Factory function for creating plugin instances
typedef PluginFactory = Plugin Function();

/// تعریف یک پلاگین lazy
class LazyPluginDefinition {
  final String id;
  final String version;
  final PluginFactory factory;
  final bool autoInitialize;
  final List<String> dependencies;

  const LazyPluginDefinition({
    required this.id,
    required this.version,
    required this.factory,
    this.autoInitialize = false,
    this.dependencies = const [],
  });
}

/// وضعیت یک پلاگین lazy
enum LazyPluginState {
  unloaded,
  loading,
  loaded,
  failed,
}

class LazyPluginStatus {
  final String id;
  final LazyPluginState state;
  final DateTime? loadedAt;
  final Duration? loadDuration;
  final String? error;

  const LazyPluginStatus({
    required this.id,
    required this.state,
    this.loadedAt,
    this.loadDuration,
    this.error,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'state': state.name,
        'loadedAt': loadedAt?.toIso8601String(),
        'loadDurationMs': loadDuration?.inMilliseconds,
        if (error != null) 'error': error,
      };
}

class LazyPluginLoader {
  final PluginRegistry registry;
  final Map<String, LazyPluginDefinition> _definitions = {};
  final Map<String, LazyPluginStatus> _statuses = {};
  final Map<String, Completer<Plugin>> _loadingCompleters = {};

  LazyPluginLoader({required this.registry});

  /// ثبت یک پلاگین به صورت lazy
  void register(LazyPluginDefinition definition) {
    _definitions[definition.id] = definition;
    _statuses[definition.id] = LazyPluginStatus(
      id: definition.id,
      state: LazyPluginState.unloaded,
    );

    BridgeLogger.debug(
      'LazyLoader',
      'Registered lazy plugin: ${definition.id}@${definition.version}',
    );
  }

  /// ثبت چندین پلاگین
  void registerAll(List<LazyPluginDefinition> definitions) {
    for (final def in definitions) {
      register(def);
    }
  }

  /// آیا این پلاگین قابل load شدن هست؟
  bool canLoad(String pluginId) {
    return _definitions.containsKey(pluginId);
  }

  /// آیا پلاگین load شده؟
  bool isLoaded(String pluginId) {
    return _statuses[pluginId]?.state == LazyPluginState.loaded;
  }

  /// بارگذاری یک پلاگین
  Future<Plugin> load(String pluginId) async {
    // اگه قبلاً load شده، از registry برگردون
    final existing = registry.resolve(pluginId);
    if (existing != null && existing.isReady) {
      return existing;
    }

    // اگه در حال load شدن هست، منتظر بمون
    if (_loadingCompleters.containsKey(pluginId)) {
      BridgeLogger.debug(
        'LazyLoader',
        'Already loading: $pluginId, waiting...',
      );
      return _loadingCompleters[pluginId]!.future;
    }

    final definition = _definitions[pluginId];
    if (definition == null) {
      throw StateError(
        'Plugin "$pluginId" is not registered as lazy plugin',
      );
    }

    // شروع loading
    final completer = Completer<Plugin>();
    _loadingCompleters[pluginId] = completer;

    _statuses[pluginId] = LazyPluginStatus(
      id: pluginId,
      state: LazyPluginState.loading,
    );

    final stopwatch = Stopwatch()..start();

    try {
      BridgeLogger.info('LazyLoader', 'Loading plugin: $pluginId');

      // اول dependency ها رو load کن
      for (final depId in definition.dependencies) {
        if (!isLoaded(depId) && canLoad(depId)) {
          BridgeLogger.debug(
            'LazyLoader',
            'Loading dependency: $depId for $pluginId',
          );
          await load(depId);
        }
      }

      // ساخت instance
      final plugin = definition.factory();

      // ثبت در registry
      await registry.register(plugin);

      stopwatch.stop();

      _statuses[pluginId] = LazyPluginStatus(
        id: pluginId,
        state: LazyPluginState.loaded,
        loadedAt: DateTime.now(),
        loadDuration: stopwatch.elapsed,
      );

      BridgeLogger.info(
        'LazyLoader',
        'Plugin loaded: $pluginId (${stopwatch.elapsedMilliseconds}ms)',
      );

      completer.complete(plugin);
      return plugin;
    } catch (e, stackTrace) {
      stopwatch.stop();

      _statuses[pluginId] = LazyPluginStatus(
        id: pluginId,
        state: LazyPluginState.failed,
        error: e.toString(),
      );

      BridgeLogger.error(
        'LazyLoader',
        'Failed to load plugin: $pluginId — $e',
      );

      completer.completeError(e, stackTrace);
      rethrow;
    } finally {
      _loadingCompleters.remove(pluginId);
    }
  }

  /// Unload کردن پلاگین
  Future<void> unload(String pluginId) async {
    if (!isLoaded(pluginId)) return;

    await registry.unregister(pluginId);

    _statuses[pluginId] = LazyPluginStatus(
      id: pluginId,
      state: LazyPluginState.unloaded,
    );

    BridgeLogger.info('LazyLoader', 'Unloaded plugin: $pluginId');
  }

  /// Reload کردن پلاگین
  Future<Plugin> reload(String pluginId) async {
    BridgeLogger.info('LazyLoader', 'Reloading plugin: $pluginId');
    await unload(pluginId);
    return load(pluginId);
  }

  /// Load کردن همه پلاگین‌هایی که autoInitialize دارن
  Future<void> loadAutoInitPlugins() async {
    final autoPlugins = _definitions.values
        .where((d) => d.autoInitialize)
        .toList();

    BridgeLogger.info(
      'LazyLoader',
      'Auto-loading ${autoPlugins.length} plugins',
    );

    for (final def in autoPlugins) {
      try {
        await load(def.id);
      } catch (e) {
        BridgeLogger.error(
          'LazyLoader',
          'Failed to auto-load: ${def.id} — $e',
        );
      }
    }
  }

  /// Load کردن لیستی از پلاگین‌ها به صورت parallel
  Future<List<Plugin>> loadMany(List<String> pluginIds) async {
    final futures = pluginIds.map((id) async {
      try {
        return await load(id);
      } catch (e) {
        BridgeLogger.error('LazyLoader', 'Failed to load: $id — $e');
        return null;
      }
    }).toList();

    final results = await Future.wait(futures);
    return results.whereType<Plugin>().toList();
  }

  /// Preload بدون block کردن
  void preload(List<String> pluginIds) {
    for (final id in pluginIds) {
      if (!isLoaded(id) && canLoad(id)) {
        load(id).catchError((e) {
          BridgeLogger.warn('LazyLoader', 'Preload failed: $id — $e');
        });
      }
    }
  }

  /// وضعیت همه پلاگین‌ها
  Map<String, LazyPluginStatus> get allStatuses =>
      Map.unmodifiable(_statuses);

  /// لیست پلاگین‌های unloaded
  List<String> get unloadedPlugins => _statuses.entries
      .where((e) => e.value.state == LazyPluginState.unloaded)
      .map((e) => e.key)
      .toList();

  /// لیست پلاگین‌های loaded
  List<String> get loadedPlugins => _statuses.entries
      .where((e) => e.value.state == LazyPluginState.loaded)
      .map((e) => e.key)
      .toList();

  /// آمار
  Map<String, dynamic> get stats => {
        'total': _definitions.length,
        'loaded': loadedPlugins.length,
        'unloaded': unloadedPlugins.length,
        'loading': _loadingCompleters.length,
        'plugins': _statuses.map(
          (key, value) => MapEntry(key, value.toJson()),
        ),
      };

  Future<void> dispose() async {
    for (final id in loadedPlugins) {
      await unload(id);
    }
    _definitions.clear();
    _statuses.clear();
  }
}
```

---

### 📄 بروزرسانی `lib/packages/plugin_engine/lib/plugin_engine.dart`

```dart
library plugin_engine;

export 'src/plugin_interface.dart';
export 'src/plugin_registry.dart';
export 'src/plugin_manager.dart';
export 'src/lazy_plugin_loader.dart';
```

---

## بخش ۲: PluginManager با Lazy Loading Support

### 📄 بروزرسانی `lib/packages/plugin_engine/lib/src/plugin_manager.dart`

> تغییر در method `execute` — اضافه شدن auto-load:

```dart
import 'dart:async';
import 'dart:convert';
import 'plugin_registry.dart';
import 'lazy_plugin_loader.dart';
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
  final CircuitBreakerRegistry circuitBreakers;

  /// Lazy loader — اختیاری
  LazyPluginLoader? lazyLoader;

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
    CircuitBreakerRegistry? circuitBreakers,
    this.lazyLoader,
  }) : circuitBreakers = circuitBreakers ?? CircuitBreakerRegistry();

  /// ست کردن lazy loader
  void setLazyLoader(LazyPluginLoader loader) {
    lazyLoader = loader;
  }

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
    final pluginKey = request.plugin;

    BridgeLogger.info(
      'Manager',
      'Executing: ${request.plugin}.${request.method}',
    );

    try {
      // Circuit Breaker check
      final breaker = circuitBreakers.get(pluginKey);
      if (!breaker.isAllowed) {
        return _errorResponse(
          request.requestId,
          PluginErrorCode.executionError,
          'Circuit breaker open for "${request.plugin}"',
        );
      }

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

      // ═══ Resolve plugin — with lazy loading ═══
      var plugin = registry.resolve(
        request.plugin,
        version: request.version == '1.0.0' ? null : request.version,
      );

      // پلاگین وجود ندارد — بررسی lazy loading
      if (plugin == null && lazyLoader != null) {
        if (lazyLoader!.canLoad(request.plugin)) {
          BridgeLogger.info(
            'Manager',
            'Lazy loading plugin: ${request.plugin}',
          );

          try {
            plugin = await lazyLoader!.load(request.plugin);
          } catch (e) {
            BridgeLogger.error(
              'Manager',
              'Lazy load failed: ${request.plugin} — $e',
            );
            return _errorResponse(
              request.requestId,
              PluginErrorCode.pluginNotFound,
              'Plugin "${request.plugin}" failed to load: $e',
            );
          }
        }
      }

      if (plugin == null) {
        return _errorResponse(
          request.requestId,
          PluginErrorCode.pluginNotFound,
          'Plugin "${request.plugin}" not found',
        );
      }

      // پلاگین هست ولی initialize نشده
      if (!plugin.isReady) {
        BridgeLogger.info(
          'Manager',
          'Auto-initializing plugin: ${request.plugin}',
        );
        await plugin.initialize();
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
            'Permission "$permission" denied',
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

      // Cache check
      final isMutation = cacheManager.isMutationMethod(request.method);

      if (plugin.cacheable && !isMutation) {
        final cacheKey = _buildCacheKey(request);
        final cached = await cacheManager.get(cacheKey);
        if (cached != null) {
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

      // Execute with circuit breaker
      final result = await breaker.execute(() async {
        return await executionGuard.execute(
          requestId: request.requestId,
          timeoutMs: 30000,
          fn: () => plugin!.onCall(request.method, request.args),
        );
      });

      final processingTime =
          DateTime.now().difference(startTime).inMilliseconds;

      if (plugin.cacheable && !isMutation && result != null) {
        final cacheKey = _buildCacheKey(request);
        await cacheManager.set(cacheKey, result, ttl: plugin.defaultCacheTtl);
      }

      if (plugin.cacheable && isMutation) {
        await cacheManager.invalidatePlugin(request.plugin);
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
    } on CircuitBreakerOpenException catch (e) {
      return _errorResponse(
        request.requestId,
        PluginErrorCode.executionError,
        e.toString(),
      );
    } catch (e, stackTrace) {
      final processingTime =
          DateTime.now().difference(startTime).inMilliseconds;

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
    if (options.parallel) {
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
        if (options.stopOnError && !response.success) break;
      }
      return responses;
    }
  }

  Map<String, dynamic> get circuitBreakerStats => circuitBreakers.allStats;
  void resetCircuitBreaker(String plugin) => circuitBreakers.reset(plugin);
  void resetAllCircuitBreakers() => circuitBreakers.resetAll();

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

  void _recordStats(String plugin, String method, int timeMs, bool fromCache) {
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
      _traceController.add(PluginTrace(
        traceId: traceId,
        requestId: requestId,
        plugin: plugin,
        method: method,
        processingTimeMs: processingTimeMs,
        success: success,
        fromCache: fromCache,
        error: error,
      ));
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

## بخش ۳: بروزرسانی Service Locator با Lazy Loading

### 📄 `lib/di/service_locator.dart`

> فقط بخش تغییر یافته:

```dart
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';

import 'package:sweetmelon/packages/core/lib/core.dart';
import 'package:sweetmelon/packages/devtools/lib/devtools.dart';
import 'package:sweetmelon/packages/performance/lib/performance.dart';
import 'package:sweetmelon/packages/security/lib/security.dart';
import 'package:sweetmelon/packages/plugin_engine/lib/plugin_engine.dart';

// ── Eager plugins (always loaded) ──
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
import 'package:sweetmelon/plugins/back_button/lib/back_button_plugin.dart';
import 'package:sweetmelon/plugins/status_bar/lib/status_bar_plugin.dart';
import 'package:sweetmelon/plugins/orientation/lib/orientation_plugin.dart';
import 'package:sweetmelon/plugins/haptic/lib/haptic_plugin.dart';
import 'package:sweetmelon/plugins/keyboard/lib/keyboard_plugin.dart';
import 'package:sweetmelon/plugins/encryption/lib/encryption_plugin.dart';

// ── Lazy plugins (loaded on first call) ──
import 'package:sweetmelon/plugins/camera/lib/camera_plugin.dart';
import 'package:sweetmelon/plugins/geolocation/lib/geolocation_plugin.dart';
import 'package:sweetmelon/plugins/secure_storage/lib/secure_storage_plugin.dart';
import 'package:sweetmelon/plugins/notification/lib/notification_plugin.dart';
import 'package:sweetmelon/plugins/biometrics/lib/biometrics_plugin.dart';
import 'package:sweetmelon/plugins/qr_scanner/lib/qr_scanner_plugin.dart';
import 'package:sweetmelon/plugins/audio/lib/audio_plugin.dart';
import 'package:sweetmelon/plugins/sms_otp/lib/sms_otp_plugin.dart';
import 'package:sweetmelon/plugins/download_manager/lib/download_manager_plugin.dart';
import 'package:sweetmelon/plugins/database/lib/database_plugin.dart';
import 'package:sweetmelon/plugins/contacts/lib/contacts_plugin.dart';
import 'package:sweetmelon/plugins/phone_dialer/lib/phone_dialer_plugin.dart';
import 'package:sweetmelon/plugins/bluetooth/lib/bluetooth_plugin.dart';
import 'package:sweetmelon/plugins/nfc/lib/nfc_plugin.dart';
import 'package:sweetmelon/plugins/speech_to_text/lib/speech_to_text_plugin.dart';
import 'package:sweetmelon/plugins/text_to_speech/lib/text_to_speech_plugin.dart';
import 'package:sweetmelon/plugins/video_player/lib/video_player_plugin.dart';
import 'package:sweetmelon/plugins/in_app_browser/lib/in_app_browser_plugin.dart';
import 'package:sweetmelon/plugins/pdf_plugin/lib/pdf_bridge_plugin.dart';

final sl = GetIt.instance;

class ServiceLocator {
  static bool _initializing = false;

  static Future<void> init() async {
    if (sl.isRegistered<MessageBridge>()) return;
    if (_initializing) return;
    _initializing = true;

    try {
      // ── Core services ──
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

      sl.registerLazySingleton<PermissionManager>(() {
        final manager = PermissionManager(cacheTtl: const Duration(minutes: 3));
        manager.setProvider(NativePermissionProvider(
          fallbackStatus: kReleaseMode
              ? PermissionStatus.denied
              : PermissionStatus.granted,
        ));
        return manager;
      });

      sl.registerLazySingleton<PluginRegistry>(() => PluginRegistry());

      sl.registerLazySingleton<LazyPluginLoader>(
        () => LazyPluginLoader(registry: sl<PluginRegistry>()),
      );

      sl.registerLazySingleton<PluginManager>(() => PluginManager(
            registry: sl<PluginRegistry>(),
            permissionManager: sl<PermissionManager>(),
            rateLimiter: sl<RateLimiter>(),
            executionGuard: sl<ExecutionGuard>(),
            cacheManager: sl<CacheManager>(),
            lazyLoader: sl<LazyPluginLoader>(),
          ));

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

      await _registerEagerPlugins();
      _registerLazyPlugins();
    } finally {
      _initializing = false;
    }
  }

  /// پلاگین‌هایی که همیشه لازمند و فورا load می‌شن
  static Future<void> _registerEagerPlugins() async {
    final registry = sl<PluginRegistry>();
    final emitter = registry.emitEvent;

    await registry.register(
      PermissionPlugin(permissionManager: sl<PermissionManager>()),
    );
    await registry.register(AppLifecyclePlugin(eventEmitter: emitter));
    await registry.register(DeviceInfoBridgePlugin());
    await registry.register(ConnectivityBridgePlugin(eventEmitter: emitter));
    await registry.register(StoragePlugin());
    await registry.register(FileSystemPlugin());
    await registry.register(HttpNativePlugin());
    await registry.register(IntentLinkPlugin(eventEmitter: emitter));
    await registry.register(ClipboardPlugin());
    await registry.register(ShareBridgePlugin());
    await registry.register(BackButtonPlugin(eventEmitter: emitter));
    await registry.register(StatusBarPlugin());
    await registry.register(OrientationPlugin());
    await registry.register(HapticPlugin());
    await registry.register(KeyboardPlugin(eventEmitter: emitter));
    await registry.register(EncryptionPlugin());
  }

  /// پلاگین‌هایی که فقط وقتی call بشن load می‌شن
  static void _registerLazyPlugins() {
    final loader = sl<LazyPluginLoader>();
    final emitter = sl<PluginRegistry>().emitEvent;

    loader.registerAll([
      LazyPluginDefinition(
        id: 'camera',
        version: '1.0.0',
        factory: () => CameraPlugin(),
      ),
      LazyPluginDefinition(
        id: 'geolocation',
        version: '1.0.0',
        factory: () => GeolocationPlugin(eventEmitter: emitter),
      ),
      LazyPluginDefinition(
        id: 'secureStorage',
        version: '1.0.0',
        factory: () => SecureStoragePlugin(),
      ),
      LazyPluginDefinition(
        id: 'notification',
        version: '1.0.0',
        factory: () => NotificationPlugin(eventEmitter: emitter),
      ),
      LazyPluginDefinition(
        id: 'biometrics',
        version: '1.0.0',
        factory: () => BiometricsPlugin(),
      ),
      LazyPluginDefinition(
        id: 'qrScanner',
        version: '1.0.0',
        factory: () => QrScannerPlugin(eventEmitter: emitter),
      ),
      LazyPluginDefinition(
        id: 'audio',
        version: '1.0.0',
        factory: () => AudioPlugin(eventEmitter: emitter),
      ),
      LazyPluginDefinition(
        id: 'smsOtp',
        version: '1.0.0',
        factory: () => SmsOtpPlugin(eventEmitter: emitter),
      ),
      LazyPluginDefinition(
        id: 'downloadManager',
        version: '1.0.0',
        factory: () => DownloadManagerPlugin(eventEmitter: emitter),
      ),
      LazyPluginDefinition(
        id: 'database',
        version: '1.0.0',
        factory: () => DatabasePlugin(),
      ),
      LazyPluginDefinition(
        id: 'contacts',
        version: '1.0.0',
        factory: () => ContactsPlugin(),
      ),
      LazyPluginDefinition(
        id: 'phoneDialer',
        version: '1.0.0',
        factory: () => PhoneDialerPlugin(),
      ),
      LazyPluginDefinition(
        id: 'bluetooth',
        version: '1.0.0',
        factory: () => BluetoothPlugin(eventEmitter: emitter),
      ),
      LazyPluginDefinition(
        id: 'nfc',
        version: '1.0.0',
        factory: () => NfcPlugin(eventEmitter: emitter),
      ),
      LazyPluginDefinition(
        id: 'speechToText',
        version: '1.0.0',
        factory: () => SpeechToTextPlugin(eventEmitter: emitter),
      ),
      LazyPluginDefinition(
        id: 'textToSpeech',
        version: '1.0.0',
        factory: () => TextToSpeechPlugin(eventEmitter: emitter),
      ),
      LazyPluginDefinition(
        id: 'videoPlayer',
        version: '1.0.0',
        factory: () => VideoPlayerPlugin(eventEmitter: emitter),
      ),
      LazyPluginDefinition(
        id: 'inAppBrowser',
        version: '1.0.0',
        factory: () => InAppBrowserPlugin(eventEmitter: emitter),
      ),
      LazyPluginDefinition(
        id: 'pdf',
        version: '1.0.0',
        factory: () => PdfBridgePlugin(),
      ),
    ]);

    BridgeLogger.info(
      'ServiceLocator',
      'Registered ${loader.unloadedPlugins.length} lazy plugins',
    );
  }

  static Future<void> dispose() async {
    if (sl.isRegistered<BridgeInspector>()) sl<BridgeInspector>().dispose();
    if (sl.isRegistered<PluginManager>()) sl<PluginManager>().dispose();
    if (sl.isRegistered<LazyPluginLoader>()) {
      await sl<LazyPluginLoader>().dispose();
    }
    if (sl.isRegistered<PluginRegistry>()) {
      await sl<PluginRegistry>().dispose();
    }
    if (sl.isRegistered<CacheManager>()) sl<CacheManager>().dispose();
    if (sl.isRegistered<MessageBridge>()) sl<MessageBridge>().dispose();
    await sl.reset();
  }
}
```

---

## بخش ۴: Loader Status Plugin — بررسی وضعیت lazy load از JS

### 📄 `lib/plugins/loader_status/lib/loader_status_plugin.dart`

```dart
import 'package:sweetmelon/packages/plugin_engine/lib/plugin_engine.dart';

class LoaderStatusPlugin extends Plugin {
  final LazyPluginLoader loader;

  LoaderStatusPlugin({required this.loader});

  @override
  String get name => '_loader';

  @override
  String get version => '1.0.0';

  @override
  String get description => 'Internal plugin loader status';

  @override
  List<String> get supportedMethods => [
        'getStats',
        'getStatus',
        'preload',
        'unload',
        'reload',
        'getLoadedPlugins',
        'getUnloadedPlugins',
      ];

  @override
  Future<dynamic> onCall(String method, Map<String, dynamic> args) async {
    switch (method) {
      case 'getStats':
        return loader.stats;

      case 'getStatus':
        final pluginId = args['plugin'] as String;
        final status = loader.allStatuses[pluginId];
        if (status == null) {
          return {'plugin': pluginId, 'registered': false};
        }
        return {
          'plugin': pluginId,
          'registered': true,
          ...status.toJson(),
        };

      case 'preload':
        final plugins = List<String>.from(args['plugins'] as List);
        loader.preload(plugins);
        return {'preloading': plugins};

      case 'unload':
        final pluginId = args['plugin'] as String;
        await loader.unload(pluginId);
        return {'unloaded': pluginId};

      case 'reload':
        final pluginId = args['plugin'] as String;
        await loader.reload(pluginId);
        return {'reloaded': pluginId};

      case 'getLoadedPlugins':
        return {'plugins': loader.loadedPlugins};

      case 'getUnloadedPlugins':
        return {'plugins': loader.unloadedPlugins};

      default:
        throw UnsupportedError('Method "$method" not supported');
    }
  }
}
```

---

## بخش ۵: NativeSDK — Loader API

> اضافه شدن به `native-sdk.js`:

```javascript
    _loader: {
      getStats: function () { return call('_loader', 'getStats', {}); },
      getStatus: function (plugin) { return call('_loader', 'getStatus', { plugin: plugin }); },
      preload: function (plugins) { return call('_loader', 'preload', { plugins: plugins }); },
      unload: function (plugin) { return call('_loader', 'unload', { plugin: plugin }); },
      reload: function (plugin) { return call('_loader', 'reload', { plugin: plugin }); },
      getLoadedPlugins: function () { return call('_loader', 'getLoadedPlugins', {}); },
      getUnloadedPlugins: function () { return call('_loader', 'getUnloadedPlugins', {}); }
    },
```

---

## نحوه استفاده

```javascript
// اول camera هنوز load نشده:
const status = await NativeSDK._loader.getStatus('camera');
// { plugin: 'camera', state: 'unloaded' }

// اولین call → auto-load + initialize + execute
const photo = await NativeSDK.camera.takePhoto(); // lazy loaded!

// حالا load شده:
const status2 = await NativeSDK._loader.getStatus('camera');
// { plugin: 'camera', state: 'loaded', loadDurationMs: 45 }

// Preload چند پلاگین برای آینده
await NativeSDK._loader.preload(['bluetooth', 'nfc', 'audio']);

// Unload پلاگینی که دیگه لازم نیست (آزاد کردن حافظه)
await NativeSDK._loader.unload('bluetooth');

// Reload پلاگین با مشکل
await NativeSDK._loader.reload('audio');

// آمار
const stats = await NativeSDK._loader.getStats();
// { total: 19, loaded: 5, unloaded: 14, ... }
```

---

# خلاصه Lazy Loading

## Eager Plugins (16 عدد — همیشه load)
```
permission, appLifecycle, deviceInfo, connectivity,
storage, fileSystem, http, intent, clipboard, share,
backButton, statusBar, orientation, haptic, keyboard, encryption
```

## Lazy Plugins (19 عدد — load on first call)
```
camera, geolocation, secureStorage, notification, biometrics,
qrScanner, audio, smsOtp, downloadManager, database,
contacts, phoneDialer, bluetooth, nfc, speechToText,
textToSpeech, videoPlayer, inAppBrowser, pdf
```

## مزایا
- **زمان startup کمتر** — فقط ۱۶ پلاگین پایه load می‌شه
- **حافظه کمتر** — پلاگین‌های سنگین تا وقتی لازم نشن load نمی‌شن
- **Unload** — پلاگین‌هایی که دیگه لازم نیستن رو می‌شه unload کرد
- **Preload** — می‌شه از قبل چند پلاگین رو آماده کرد
- **Reload** — اگه پلاگینی مشکل داشت، reload بشه

---

در پیام بعدی **Testing Framework** رو کامل می‌فرستم. ادامه بدم؟
