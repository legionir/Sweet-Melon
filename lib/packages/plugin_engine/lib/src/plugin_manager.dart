import 'dart:async';
import 'dart:convert';

import 'package:sweetmelon/packages/core/lib/src/protocol/message_protocol.dart';
import 'package:sweetmelon/packages/core/lib/src/utils/logger.dart';
import 'package:sweetmelon/packages/performance/lib/src/cache_manager.dart';
import 'package:sweetmelon/packages/security/lib/security.dart';

import 'plugin_interface.dart';
import 'plugin_registry.dart';

// ============================================================
// PLUGIN MANAGER — the execution pipeline for every bridge request
// ============================================================
//
// Order of checks (each failure produces a protocol error and a stats/trace
// entry):
//   1. plugin resolved           -> PLUGIN_NOT_FOUND
//   2. method supported          -> METHOD_NOT_FOUND
//   3. capability: streaming     -> INVALID_REQUEST
//   4. capability: batch         -> INVALID_REQUEST (batch only)
//   5. rate limit (plugin.method) -> RATE_LIMIT_EXCEEDED
//   6. concurrency limit         -> RATE_LIMIT_EXCEEDED
//   7. permissions               -> PERMISSION_DENIED
//   8. argument validation       -> INVALID_ARGS
//   9. cache read (read-only)    -> success (fromCache)
//  10. execution with timeout    -> TIMEOUT / CANCELLED / EXECUTION_ERROR
//  11. cache write / invalidate
//
// Rate limiting happens after resolution so that unknown plugin names never
// create limiter state (SEC-008). Stats are only kept for known plugin+method
// pairs for the same reason.

class PluginManagerConfig {
  /// Default timeout for a single execution.
  final Duration timeout;

  const PluginManagerConfig({this.timeout = const Duration(seconds: 30)});
}

class PluginManager {
  final PluginRegistry registry;
  final PermissionManager permissionManager;
  final RateLimiter rateLimiter;
  final ExecutionGuard executionGuard;
  final CacheManager cacheManager;
  final PluginManagerConfig config;

  final Map<String, PluginStats> _stats = {};
  final Map<String, int> _inFlight = {};
  final StreamController<PluginTrace> _traceController =
      StreamController<PluginTrace>.broadcast();
  bool _disposed = false;

  PluginManager({
    required this.registry,
    required this.permissionManager,
    required this.rateLimiter,
    required this.executionGuard,
    required this.cacheManager,
    this.config = const PluginManagerConfig(),
  });

  Stream<PluginTrace> get traces => _traceController.stream;

  // ============================================================
  // SINGLE REQUEST
  // ============================================================

  Future<PluginResponse> execute(
    PluginRequest request, {
    bool inBatch = false,
    Duration? timeout,
  }) async {
    final stopwatch = Stopwatch()..start();
    final requestId = request.requestId;

    final plugin = registry.resolve(request.plugin);
    if (plugin == null) {
      return _fail(
        requestId,
        PluginErrorCode.pluginNotFound,
        'Plugin is not available',
        stopwatch,
      );
    }

    final statKey = '${plugin.name}.${request.method}';

    if (!plugin.supportsMethod(request.method)) {
      return _fail(
        requestId,
        PluginErrorCode.methodNotFound,
        'Method is not supported',
        stopwatch,
        plugin: plugin.name,
        method: request.method,
      );
    }

    if (plugin.streamingMethods.contains(request.method) &&
        !plugin.capabilities.supportsStreaming) {
      return _fail(requestId, PluginErrorCode.invalidRequest,
          'Method requires streaming support', stopwatch,
          plugin: plugin.name, method: request.method);
    }

    if (inBatch && !plugin.capabilities.supportsBatch) {
      return _fail(requestId, PluginErrorCode.invalidRequest,
          'Plugin does not support batch calls', stopwatch,
          plugin: plugin.name, method: request.method);
    }

    final rate = rateLimiter.check(statKey);
    if (!rate.allowed) {
      return _fail(
        requestId,
        PluginErrorCode.rateLimitExceeded,
        'Rate limit exceeded. Retry after ${rate.retryAfterMs}ms',
        stopwatch,
        plugin: plugin.name,
        method: request.method,
      );
    }

    for (final permission in plugin.requiredPermissions) {
      final state = await permissionManager.stateOf(permission);
      if (state != PermissionState.granted) {
        // The status lets JS decide between asking again and opening settings.
        return _fail(
          requestId,
          PluginErrorCode.permissionDenied,
          'Permission "$permission" is required',
          stopwatch,
          plugin: plugin.name,
          method: request.method,
          details: {'permission': permission, 'status': state.name},
        );
      }
    }

    try {
      final validation =
          await plugin.validateArgs(request.method, request.args);
      if (!validation.isValid) {
        return _fail(
          requestId,
          PluginErrorCode.invalidArgs,
          validation.errorMessage ?? 'Invalid arguments',
          stopwatch,
          plugin: plugin.name,
          method: request.method,
        );
      }
    } catch (e) {
      BridgeLogger.error('Manager', 'Validation crashed: ${e.runtimeType}');
      return _fail(requestId, PluginErrorCode.invalidArgs, 'Invalid arguments',
          stopwatch,
          plugin: plugin.name, method: request.method);
    }

    final cacheable = plugin.isCacheable(request.method);
    final cacheKey = cacheable ? _buildCacheKey(request) : null;
    if (cacheKey != null) {
      final cached = cacheManager.get(cacheKey);
      if (cached != null) {
        _recordStats(statKey, 0, fromCache: true);
        _trace(
            requestId: requestId,
            plugin: plugin.name,
            method: request.method,
            processingTimeMs: 0,
            success: true,
            fromCache: true);
        return PluginResponse.success(
          requestId: requestId,
          data: cached,
          metadata: ResponseMetadata(
            processingTimeMs: 0,
            pluginVersion: plugin.version,
            fromCache: true,
          ),
        );
      }
    }

    // Checked and incremented synchronously, with no await in between, so the
    // concurrency limit cannot be overshot by interleaved calls.
    final inFlight = _inFlight[plugin.name] ?? 0;
    if (inFlight >= plugin.capabilities.maxConcurrentCalls) {
      return _fail(
        requestId,
        PluginErrorCode.rateLimitExceeded,
        'Too many concurrent calls to this plugin',
        stopwatch,
        plugin: plugin.name,
        method: request.method,
      );
    }
    _inFlight[plugin.name] = inFlight + 1;
    try {
      final result = await executionGuard.execute<dynamic>(
        requestId: requestId,
        timeout: timeout ?? config.timeout,
        fn: () => plugin.onCall(request.method, request.args),
      );

      final elapsed = stopwatch.elapsedMilliseconds;
      if (cacheKey != null && result != null) {
        cacheManager.set(cacheKey, result, ttl: plugin.defaultCacheTtl);
      }
      if (!cacheable && plugin.cacheableMethods.isNotEmpty) {
        // A mutating method changed state: drop every cached read of this plugin.
        cacheManager.invalidatePlugin(plugin.name);
      }

      _recordStats(statKey, elapsed, fromCache: false);
      _trace(
          requestId: requestId,
          plugin: plugin.name,
          method: request.method,
          processingTimeMs: elapsed,
          success: true);
      return PluginResponse.success(
        requestId: requestId,
        data: result,
        metadata: ResponseMetadata(
          processingTimeMs: elapsed,
          pluginVersion: plugin.version,
          fromCache: false,
        ),
      );
    } on ExecutionTimeoutException {
      return _fail(requestId, PluginErrorCode.timeout,
          'Plugin execution timed out', stopwatch,
          plugin: plugin.name, method: request.method);
    } on ExecutionCancelled {
      return _fail(requestId, PluginErrorCode.cancelled,
          'Request was cancelled', stopwatch,
          plugin: plugin.name, method: request.method);
    } on DuplicateRequestException {
      return _fail(requestId, PluginErrorCode.invalidRequest,
          'requestId is already in flight', stopwatch,
          plugin: plugin.name, method: request.method);
    } on PluginException catch (e) {
      // Plugin-authored, user-safe message.
      return _fail(requestId, e.code, e.message, stopwatch,
          plugin: plugin.name, method: request.method);
    } catch (e, stackTrace) {
      // Internal details go to the log only; JS gets a generic message.
      BridgeLogger.error(
        'Manager',
        'Execution failed in ${plugin.name}.${request.method}: '
            '${e.runtimeType}',
        {'stackTrace': stackTrace.toString()},
      );
      return _fail(requestId, PluginErrorCode.executionError,
          'Plugin execution failed', stopwatch,
          plugin: plugin.name, method: request.method);
    } finally {
      final remaining = (_inFlight[plugin.name] ?? 1) - 1;
      if (remaining <= 0) {
        _inFlight.remove(plugin.name);
      } else {
        _inFlight[plugin.name] = remaining;
      }
    }
  }

  // ============================================================
  // BATCH
  // ============================================================

  /// Executes [requests] and returns one response per request, in request
  /// order. If [BatchOptions.timeoutMs] elapses, unfinished requests receive a
  /// TIMEOUT response so the batch always settles.
  Future<List<PluginResponse>> executeBatch(
    List<PluginRequest> requests,
    BatchOptions options,
  ) async {
    BridgeLogger.info(
      'Manager',
      'Batch: ${requests.length} requests (parallel: ${options.parallel})',
    );
    final overall = options.timeoutMs == null
        ? null
        : Duration(milliseconds: options.timeoutMs!);
    final results = <String, PluginResponse>{};
    var stopped = false;

    Future<void> runOne(PluginRequest request) async {
      final response = await execute(request, inBatch: true);
      results[request.requestId] = response;
    }

    if (options.parallel) {
      final futures = requests.map(runOne).toList();
      await _awaitAll(futures, overall);
    } else {
      final sequential = () async {
        for (final request in requests) {
          await runOne(request);
          if (options.stopOnError &&
              results[request.requestId]!.success == false) {
            stopped = true;
            return;
          }
        }
      }();
      await _awaitAll([sequential], overall);
    }

    // Every request gets a response, even if it never finished.
    return [
      for (final request in requests)
        results[request.requestId] ??
            PluginResponse.failure(
              requestId: request.requestId,
              error: stopped
                  ? PluginError(
                      code: PluginErrorCode.cancelled,
                      message: 'Not executed: batch stopped after an error',
                    )
                  : PluginError(
                      code: PluginErrorCode.timeout,
                      message: 'Batch timed out before this request completed',
                    ),
            ),
    ];
  }

  Future<void> _awaitAll(List<Future<void>> futures, Duration? timeout) async {
    final all = Future.wait(futures).then<void>((_) {});
    if (timeout == null) {
      await all;
      return;
    }
    try {
      await all.timeout(timeout);
    } on TimeoutException {
      BridgeLogger.warn('Manager', 'Batch timed out');
    }
  }

  // ============================================================
  // HELPERS
  // ============================================================

  PluginResponse _fail(
    String requestId,
    PluginErrorCode code,
    String message,
    Stopwatch stopwatch, {
    String? plugin,
    String? method,
    Map<String, dynamic>? details,
  }) {
    if (plugin != null && method != null) {
      _recordError('$plugin.$method');
      _trace(
        requestId: requestId,
        plugin: plugin,
        method: method,
        processingTimeMs: stopwatch.elapsedMilliseconds,
        success: false,
        error: code.code,
      );
    }
    return PluginResponse.failure(
      requestId: requestId,
      error: PluginError(
        code: code,
        message: message,
        plugin: plugin,
        method: method,
        details: details,
      ),
    );
  }

  String _buildCacheKey(PluginRequest request) =>
      '${request.plugin}:${request.method}:${_canonicalJson(request.args)}';

  /// Deterministic JSON: object keys sorted recursively. Scalars go through
  /// jsonEncode, so quoting and escaping can never produce ambiguous keys.
  static String _canonicalJson(Object? value) {
    if (value is Map) {
      final keys = value.keys.map((k) => k.toString()).toList()..sort();
      final parts = keys.map(
        (k) => '${jsonEncode(k)}:${_canonicalJson(value[k])}',
      );
      return '{${parts.join(',')}}';
    }
    if (value is List) {
      return '[${value.map(_canonicalJson).join(',')}]';
    }
    return jsonEncode(value);
  }

  void _recordStats(String key, int timeMs, {required bool fromCache}) {
    final stat = _stats.putIfAbsent(key, () => PluginStats(key: key));
    stat.record(timeMs, fromCache: fromCache);
  }

  void _recordError(String key) {
    final stat = _stats.putIfAbsent(key, () => PluginStats(key: key));
    stat.recordError();
  }

  void _trace({
    required String requestId,
    required String plugin,
    required String method,
    required int processingTimeMs,
    required bool success,
    bool fromCache = false,
    String? error,
  }) {
    if (_traceController.isClosed) return;
    _traceController.add(
      PluginTrace(
        traceId: 'trace_$requestId',
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

  /// Snapshot of per-method statistics (known plugin/method pairs only).
  Map<String, PluginStats> get stats => Map.unmodifiable(_stats);

  /// Calls currently executing (excluding cache hits and rejected calls).
  /// Returns to zero when the manager is idle.
  int get activeCalls => _inFlight.values.fold(0, (a, b) => a + b);

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    executionGuard.cancelAll();
    _inFlight.clear();
    unawaited(_traceController.close());
  }
}

// ============================================================
// STATS & TRACE
// ============================================================

class PluginStats {
  final String key;
  int totalCalls = 0;
  int cacheHits = 0;
  int totalTimeMs = 0;
  int errorCount = 0;

  PluginStats({required this.key});

  /// Records a completed call. Errors are recorded separately via
  /// [recordError]; a call that failed is counted in both.
  void record(int timeMs, {required bool fromCache}) {
    totalCalls++;
    totalTimeMs += timeMs;
    if (fromCache) cacheHits++;
  }

  void recordError() {
    errorCount++;
    totalCalls++;
  }

  double get avgTimeMs => totalCalls > 0 ? totalTimeMs / totalCalls : 0;
  double get cacheHitRate => totalCalls > 0 ? cacheHits / totalCalls : 0;

  Map<String, dynamic> toJson() => {
        'key': key,
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
