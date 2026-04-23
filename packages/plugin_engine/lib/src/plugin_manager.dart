import 'dart:async';
import 'plugin_interface.dart';
import 'plugin_registry.dart';
import '../../../core/lib/src/protocol/message_protocol.dart';
import '../../../core/lib/src/utils/logger.dart';
import '../../security/lib/src/permission_manager.dart';
import '../../security/lib/src/rate_limiter.dart';
import '../../security/lib/src/execution_guard.dart';
import '../../performance/lib/src/cache_manager.dart';

// ============================================================
// PLUGIN MANAGER — مرکز هماهنگی و اجرا
// ============================================================

class PluginManager {
  final PluginRegistry registry;
  final PermissionManager permissionManager;
  final RateLimiter rateLimiter;
  final ExecutionGuard executionGuard;
  final CacheManager cacheManager;
  
  // آمار عملکرد
  final Map<String, PluginStats> _stats = {};
  
  // Stream برای trace
  final _traceController = 
      StreamController<PluginTrace>.broadcast();
  Stream<PluginTrace> get traces => _traceController.stream;

  PluginManager({
    required this.registry,
    required this.permissionManager,
    required this.rateLimiter,
    required this.executionGuard,
    required this.cacheManager,
  });

  // ============================================================
  // MAIN EXECUTION PIPELINE
  // ============================================================

  Future<PluginResponse> execute(PluginRequest request) async {
    final startTime = DateTime.now();
    final traceId = 'trace_${request.requestId}';
    
    BridgeLogger.info(
      'Manager',
      'Executing: ${request.plugin}.${request.method}',
    );

    try {
      // ── Step 1: Rate Limit Check ─────────────────────────
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

      // ── Step 2: Plugin Resolution ─────────────────────────
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

      // ── Step 3: Method Check ──────────────────────────────
      if (!plugin.supportsMethod(request.method)) {
        return _errorResponse(
          request.requestId,
          PluginErrorCode.methodNotFound,
          'Method "${request.method}" not supported by plugin "${request.plugin}"',
        );
      }

      // ── Step 4: Permission Check ──────────────────────────
      for (final permission in plugin.requiredPermissions) {
        final hasPermission = await permissionManager.check(permission);
        if (!hasPermission) {
          return _errorResponse(
            request.requestId,
            PluginErrorCode.permissionDenied,
            'Permission "$permission" denied for plugin "${request.plugin}"',
          );
        }
      }

      // ── Step 5: Args Validation ───────────────────────────
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

      // ── Step 6: Cache Check ───────────────────────────────
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

      // ── Step 7: Execute with Guard ────────────────────────
      final result = await executionGuard.execute(
        requestId: request.requestId,
        timeoutMs: 30000,
        fn: () => plugin.onCall(request.method, request.args),
      );

      final processingTime = DateTime.now()
          .difference(startTime)
          .inMilliseconds;

      // ── Step 8: Cache Result ──────────────────────────────
      if (result != null) {
        await cacheManager.set(
          cacheKey,
          result,
          ttl: const Duration(minutes: 5),
        );
      }

      // ── Step 9: Record Stats ──────────────────────────────
      _recordStats(
        request.plugin,
        request.method,
        processingTime,
        false,
      );

      // ── Step 10: Emit Trace ───────────────────────────────
      _traceController.add(
        PluginTrace(
          traceId: traceId,
          requestId: request.requestId,
          plugin: request.plugin,
          method: request.method,
          processingTimeMs: processingTime,
          success: true,
          fromCache: false,
        ),
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
      final processingTime = DateTime.now()
          .difference(startTime)
          .inMilliseconds;
      
      BridgeLogger.error(
        'Manager',
        'Execution error: $e\n$stackTrace',
      );

      _traceController.add(
        PluginTrace(
          traceId: traceId,
          requestId: request.requestId,
          plugin: request.plugin,
          method: request.method,
          processingTimeMs: processingTime,
          success: false,
          error: e.toString(),
        ),
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

  // ============================================================
  // BATCH EXECUTION
  // ============================================================

  Future<List<PluginResponse>> executeBatch(
    List<PluginRequest> requests,
    BatchOptions options,
  ) async {
    BridgeLogger.info(
      'Manager',
      'Batch execution: ${requests.length} requests',
    );

    if (options.parallel) {
      // اجرای موازی
      final futures = requests.map(execute).toList();
      return Future.wait(futures);
    } else {
      // اجرای سریالی
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

  // ============================================================
  // HELPERS
  // ============================================================

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
    return '${request.plugin}:${request.method}:${request.args.toString()}';
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

  Map<String, PluginStats> get stats => Map.unmodifiable(_stats);

  void dispose() {
    _traceController.close();
  }
}

// ============================================================
// STATS & TRACE
// ============================================================

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

  double get avgTimeMs => 
      totalCalls > 0 ? totalTimeMs / totalCalls : 0;
  
  double get cacheHitRate => 
      totalCalls > 0 ? cacheHits / totalCalls : 0;

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
