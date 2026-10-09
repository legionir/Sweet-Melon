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
