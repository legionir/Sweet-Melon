شروع می‌کنم. به خاطر حجم بالا، به ۳ پیام تقسیم می‌کنم.

---

# پیام ۱/۳: Error Recovery و Retry System

---

## معماری

```
JS Call
  ↓
NativeSDK.call()
  ↓
RetryManager (JS)                    ← Auto-retry + exponential backoff
  ↓
CircuitBreaker (JS)                  ← Circuit breaker per plugin
  ↓
OfflineQueue (JS)                    ← Queue when offline
  ↓
window.Native.call()                 ← Bridge
  ↓
PluginManager (Dart)
  ↓
ErrorRecoveryMiddleware (Dart)       ← Server-side retry + fallback
  ↓
Plugin.onCall()
```

---

## بخش ۱: Dart — Error Recovery Middleware

### 📄 `lib/packages/core/lib/src/middleware/error_recovery.dart`

```dart
import 'dart:async';

import '../utils/logger.dart';

typedef RecoverableAction<T> = Future<T> Function();
typedef FallbackProvider<T> = Future<T> Function(Object error, int attempt);

class RetryConfig {
  final int maxRetries;
  final Duration initialDelay;
  final double backoffMultiplier;
  final Duration maxDelay;
  final Set<Type> retryableErrors;

  const RetryConfig({
    this.maxRetries = 3,
    this.initialDelay = const Duration(milliseconds: 200),
    this.backoffMultiplier = 2.0,
    this.maxDelay = const Duration(seconds: 10),
    this.retryableErrors = const {
      TimeoutException,
      IOException,
    },
  });

  static const RetryConfig none = RetryConfig(maxRetries: 0);

  static const RetryConfig light = RetryConfig(
    maxRetries: 2,
    initialDelay: Duration(milliseconds: 100),
  );

  static const RetryConfig standard = RetryConfig(
    maxRetries: 3,
    initialDelay: Duration(milliseconds: 300),
  );

  static const RetryConfig aggressive = RetryConfig(
    maxRetries: 5,
    initialDelay: Duration(milliseconds: 500),
    maxDelay: Duration(seconds: 30),
  );
}

class RetryResult<T> {
  final T? value;
  final Object? error;
  final int attempts;
  final Duration totalDuration;
  final bool success;

  const RetryResult({
    this.value,
    this.error,
    required this.attempts,
    required this.totalDuration,
    required this.success,
  });
}

class ErrorRecovery {
  static Future<RetryResult<T>> retry<T>({
    required RecoverableAction<T> action,
    RetryConfig config = const RetryConfig(),
    FallbackProvider<T>? fallback,
    String? label,
    void Function(int attempt, Object error, Duration nextDelay)? onRetry,
  }) async {
    final stopwatch = Stopwatch()..start();
    Object? lastError;
    int attempt = 0;

    while (attempt <= config.maxRetries) {
      attempt++;

      try {
        final result = await action();
        stopwatch.stop();

        if (attempt > 1) {
          BridgeLogger.info(
            'Retry',
            '${label ?? "action"} succeeded after $attempt attempts',
          );
        }

        return RetryResult<T>(
          value: result,
          attempts: attempt,
          totalDuration: stopwatch.elapsed,
          success: true,
        );
      } catch (e) {
        lastError = e;

        final isRetryable = _isRetryable(e, config.retryableErrors);
        final hasMoreRetries = attempt <= config.maxRetries;

        if (!isRetryable || !hasMoreRetries) {
          break;
        }

        final delay = _calculateDelay(attempt, config);

        BridgeLogger.warn(
          'Retry',
          '${label ?? "action"} failed (attempt $attempt/${config.maxRetries + 1}), '
              'retrying in ${delay.inMilliseconds}ms: $e',
        );

        onRetry?.call(attempt, e, delay);

        await Future.delayed(delay);
      }
    }

    // All retries exhausted — try fallback
    if (fallback != null) {
      try {
        BridgeLogger.info(
          'Retry',
          '${label ?? "action"} using fallback after $attempt attempts',
        );

        final result = await fallback(lastError!, attempt);
        stopwatch.stop();

        return RetryResult<T>(
          value: result,
          attempts: attempt,
          totalDuration: stopwatch.elapsed,
          success: true,
        );
      } catch (fallbackError) {
        lastError = fallbackError;
      }
    }

    stopwatch.stop();

    return RetryResult<T>(
      error: lastError,
      attempts: attempt,
      totalDuration: stopwatch.elapsed,
      success: false,
    );
  }

  static bool _isRetryable(Object error, Set<Type> retryableTypes) {
    if (retryableTypes.isEmpty) return true;

    for (final type in retryableTypes) {
      if (error.runtimeType == type) return true;
    }

    // TimeoutException check
    if (error is TimeoutException) return true;

    // Check if error message contains network-related text
    final msg = error.toString().toLowerCase();
    if (msg.contains('timeout') ||
        msg.contains('connection') ||
        msg.contains('socket') ||
        msg.contains('network')) {
      return true;
    }

    return false;
  }

  static Duration _calculateDelay(int attempt, RetryConfig config) {
    final delayMs = config.initialDelay.inMilliseconds *
        _pow(config.backoffMultiplier, attempt - 1);

    final clampedMs = delayMs.clamp(0, config.maxDelay.inMilliseconds);

    // Add jitter (±20%)
    final jitter = (clampedMs * 0.2 * (DateTime.now().millisecond % 10 / 10))
        .round();

    return Duration(milliseconds: clampedMs.round() + jitter);
  }

  static double _pow(double base, int exponent) {
    double result = 1;
    for (int i = 0; i < exponent; i++) {
      result *= base;
    }
    return result;
  }
}
```

---

### 📄 `lib/packages/core/lib/src/middleware/circuit_breaker.dart`

```dart
import 'dart:async';

import '../utils/logger.dart';

enum CircuitState {
  closed,    // عادی — درخواست‌ها رد می‌شن
  open,      // خطا زیاد — همه درخواست‌ها block
  halfOpen,  // یه درخواست تست — اگه ok شد، بسته بشه
}

class CircuitBreakerConfig {
  final int failureThreshold;
  final Duration resetTimeout;
  final int halfOpenMaxAttempts;

  const CircuitBreakerConfig({
    this.failureThreshold = 5,
    this.resetTimeout = const Duration(seconds: 30),
    this.halfOpenMaxAttempts = 1,
  });
}

class CircuitBreaker {
  final String name;
  final CircuitBreakerConfig config;

  CircuitState _state = CircuitState.closed;
  int _failureCount = 0;
  int _halfOpenAttempts = 0;
  DateTime? _lastFailureTime;
  int _successCount = 0;
  int _totalCalls = 0;

  CircuitBreaker({
    required this.name,
    this.config = const CircuitBreakerConfig(),
  });

  CircuitState get state {
    if (_state == CircuitState.open) {
      final elapsed = DateTime.now().difference(_lastFailureTime!);
      if (elapsed >= config.resetTimeout) {
        _state = CircuitState.halfOpen;
        _halfOpenAttempts = 0;
        BridgeLogger.info(
          'CircuitBreaker',
          '[$name] Transitioning to half-open',
        );
      }
    }
    return _state;
  }

  bool get isAllowed {
    final currentState = state;

    switch (currentState) {
      case CircuitState.closed:
        return true;
      case CircuitState.open:
        return false;
      case CircuitState.halfOpen:
        return _halfOpenAttempts < config.halfOpenMaxAttempts;
    }
  }

  Future<T> execute<T>(Future<T> Function() action) async {
    if (!isAllowed) {
      final retryAfter = _lastFailureTime!
          .add(config.resetTimeout)
          .difference(DateTime.now());

      throw CircuitBreakerOpenException(
        name: name,
        retryAfterMs: retryAfter.inMilliseconds.clamp(0, 60000),
      );
    }

    _totalCalls++;

    if (state == CircuitState.halfOpen) {
      _halfOpenAttempts++;
    }

    try {
      final result = await action();
      _onSuccess();
      return result;
    } catch (e) {
      _onFailure();
      rethrow;
    }
  }

  void _onSuccess() {
    _successCount++;

    if (_state == CircuitState.halfOpen) {
      _state = CircuitState.closed;
      _failureCount = 0;
      BridgeLogger.info(
        'CircuitBreaker',
        '[$name] Circuit closed (recovered)',
      );
    } else {
      // Reset failure count on success in closed state
      if (_failureCount > 0) {
        _failureCount = (_failureCount - 1).clamp(0, config.failureThreshold);
      }
    }
  }

  void _onFailure() {
    _failureCount++;
    _lastFailureTime = DateTime.now();

    if (_state == CircuitState.halfOpen) {
      _state = CircuitState.open;
      BridgeLogger.warn(
        'CircuitBreaker',
        '[$name] Circuit re-opened (half-open test failed)',
      );
      return;
    }

    if (_failureCount >= config.failureThreshold) {
      _state = CircuitState.open;
      BridgeLogger.warn(
        'CircuitBreaker',
        '[$name] Circuit opened after $_failureCount failures',
      );
    }
  }

  void reset() {
    _state = CircuitState.closed;
    _failureCount = 0;
    _halfOpenAttempts = 0;
    _lastFailureTime = null;
  }

  Map<String, dynamic> get stats => {
        'name': name,
        'state': _state.name,
        'failureCount': _failureCount,
        'successCount': _successCount,
        'totalCalls': _totalCalls,
        'failureThreshold': config.failureThreshold,
        'resetTimeoutMs': config.resetTimeout.inMilliseconds,
      };
}

class CircuitBreakerOpenException implements Exception {
  final String name;
  final int retryAfterMs;

  const CircuitBreakerOpenException({
    required this.name,
    required this.retryAfterMs,
  });

  @override
  String toString() =>
      'CircuitBreaker [$name] is open. Retry after ${retryAfterMs}ms';
}

/// Manager for multiple circuit breakers (per plugin)
class CircuitBreakerRegistry {
  final CircuitBreakerConfig defaultConfig;
  final Map<String, CircuitBreaker> _breakers = {};
  final Map<String, CircuitBreakerConfig> _configs = {};

  CircuitBreakerRegistry({
    this.defaultConfig = const CircuitBreakerConfig(),
  });

  void setConfig(String name, CircuitBreakerConfig config) {
    _configs[name] = config;
    if (_breakers.containsKey(name)) {
      _breakers[name] = CircuitBreaker(name: name, config: config);
    }
  }

  CircuitBreaker get(String name) {
    return _breakers.putIfAbsent(
      name,
      () => CircuitBreaker(
        name: name,
        config: _configs[name] ?? defaultConfig,
      ),
    );
  }

  Future<T> execute<T>(String name, Future<T> Function() action) {
    return get(name).execute(action);
  }

  void reset(String name) => _breakers[name]?.reset();

  void resetAll() {
    for (final b in _breakers.values) {
      b.reset();
    }
  }

  Map<String, dynamic> get allStats => _breakers.map(
        (key, value) => MapEntry(key, value.stats),
      );
}
```

---

### 📄 `lib/packages/core/lib/src/middleware/offline_queue.dart`

```dart
import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import '../protocol/message_protocol.dart';
import '../utils/logger.dart';

enum QueueItemStatus {
  pending,
  processing,
  completed,
  failed,
  expired,
}

class QueueItem {
  final String id;
  final PluginRequest request;
  final DateTime createdAt;
  final DateTime? expiresAt;
  QueueItemStatus status;
  int attempts;
  String? lastError;

  QueueItem({
    required this.id,
    required this.request,
    required this.createdAt,
    this.expiresAt,
    this.status = QueueItemStatus.pending,
    this.attempts = 0,
    this.lastError,
  });

  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'plugin': request.plugin,
        'method': request.method,
        'status': status.name,
        'attempts': attempts,
        'createdAt': createdAt.toIso8601String(),
        'expiresAt': expiresAt?.toIso8601String(),
        'lastError': lastError,
      };
}

typedef QueueExecutor = Future<PluginResponse> Function(PluginRequest request);
typedef QueueEventCallback = void Function(String event, dynamic data);

class OfflineQueueConfig {
  final int maxQueueSize;
  final Duration defaultTtl;
  final Duration processInterval;
  final int maxRetries;
  final bool persistQueue;

  const OfflineQueueConfig({
    this.maxQueueSize = 200,
    this.defaultTtl = const Duration(hours: 1),
    this.processInterval = const Duration(seconds: 5),
    this.maxRetries = 3,
    this.persistQueue = false,
  });
}

class OfflineQueue {
  final OfflineQueueConfig config;
  final QueueExecutor executor;
  final QueueEventCallback? onEvent;

  final Queue<QueueItem> _queue = Queue<QueueItem>();
  final List<QueueItem> _completed = [];
  final List<QueueItem> _failed = [];

  Timer? _processTimer;
  bool _processing = false;
  bool _online = true;
  bool _paused = false;

  OfflineQueue({
    required this.executor,
    this.config = const OfflineQueueConfig(),
    this.onEvent,
  });

  /// آیا آنلاین هستیم
  bool get isOnline => _online;

  /// ست کردن وضعیت آنلاین
  void setOnline(bool online) {
    final wasOffline = !_online;
    _online = online;

    BridgeLogger.info(
      'OfflineQueue',
      'Connection status: ${online ? "ONLINE" : "OFFLINE"}',
    );

    if (online && wasOffline && _queue.isNotEmpty) {
      BridgeLogger.info(
        'OfflineQueue',
        'Back online — processing ${_queue.length} queued items',
      );
      _emitEvent('queue.online', {
        'pendingCount': _queue.length,
      });
      _processQueue();
    }

    if (!online) {
      _emitEvent('queue.offline', {
        'pendingCount': _queue.length,
      });
    }
  }

  /// اضافه کردن به صف
  String enqueue(PluginRequest request, {Duration? ttl}) {
    if (_queue.length >= config.maxQueueSize) {
      // حذف قدیمی‌ترین
      final removed = _queue.removeFirst();
      BridgeLogger.warn(
        'OfflineQueue',
        'Queue full, removing oldest: ${removed.request.plugin}.${removed.request.method}',
      );
    }

    final item = QueueItem(
      id: 'q_${DateTime.now().millisecondsSinceEpoch}_${_queue.length}',
      request: request,
      createdAt: DateTime.now(),
      expiresAt: DateTime.now().add(ttl ?? config.defaultTtl),
    );

    _queue.add(item);

    BridgeLogger.info(
      'OfflineQueue',
      'Enqueued: ${request.plugin}.${request.method} [${item.id}] '
          '(queue size: ${_queue.length})',
    );

    _emitEvent('queue.enqueued', item.toJson());

    // اگه آنلاینیم، فورا process کن
    if (_online && !_paused) {
      _processQueue();
    }

    return item.id;
  }

  /// شروع processing timer
  void start() {
    _processTimer?.cancel();
    _processTimer = Timer.periodic(
      config.processInterval,
      (_) {
        if (_online && !_paused && _queue.isNotEmpty) {
          _processQueue();
        }
      },
    );
  }

  /// توقف
  void pause() {
    _paused = true;
  }

  /// ادامه
  void resume() {
    _paused = false;
    if (_online && _queue.isNotEmpty) {
      _processQueue();
    }
  }

  /// پردازش صف
  Future<void> _processQueue() async {
    if (_processing || _paused) return;
    _processing = true;

    try {
      while (_queue.isNotEmpty && _online && !_paused) {
        final item = _queue.first;

        // بررسی انقضا
        if (item.isExpired) {
          _queue.removeFirst();
          item.status = QueueItemStatus.expired;
          _failed.add(item);

          BridgeLogger.warn(
            'OfflineQueue',
            'Expired: ${item.request.plugin}.${item.request.method} [${item.id}]',
          );

          _emitEvent('queue.expired', item.toJson());
          continue;
        }

        // پردازش
        item.status = QueueItemStatus.processing;
        item.attempts++;

        try {
          final response = await executor(item.request);

          if (response.success) {
            _queue.removeFirst();
            item.status = QueueItemStatus.completed;
            _completed.add(item);

            _emitEvent('queue.completed', {
              ...item.toJson(),
              'response': response.toJson(),
            });
          } else {
            _handleItemFailure(item, response.error?.message ?? 'Unknown error');
          }
        } catch (e) {
          _handleItemFailure(item, e.toString());
        }
      }
    } finally {
      _processing = false;
    }
  }

  void _handleItemFailure(QueueItem item, String error) {
    item.lastError = error;

    if (item.attempts >= config.maxRetries) {
      _queue.removeFirst();
      item.status = QueueItemStatus.failed;
      _failed.add(item);

      BridgeLogger.error(
        'OfflineQueue',
        'Failed permanently: ${item.request.plugin}.${item.request.method} '
            'after ${item.attempts} attempts: $error',
      );

      _emitEvent('queue.failed', item.toJson());
    } else {
      item.status = QueueItemStatus.pending;
      // move to back of queue
      _queue.removeFirst();
      _queue.add(item);

      BridgeLogger.warn(
        'OfflineQueue',
        'Retrying later: ${item.request.plugin}.${item.request.method} '
            '(attempt ${item.attempts}/${config.maxRetries})',
      );
    }
  }

  void _emitEvent(String event, dynamic data) {
    onEvent?.call(event, data);
  }

  /// خالی کردن صف
  void clear() {
    _queue.clear();
    _completed.clear();
    _failed.clear();
  }

  /// حذف یک آیتم
  bool remove(String itemId) {
    final before = _queue.length;
    _queue.removeWhere((item) => item.id == itemId);
    return _queue.length < before;
  }

  /// وضعیت
  Map<String, dynamic> get stats => {
        'pending': _queue.length,
        'completed': _completed.length,
        'failed': _failed.length,
        'online': _online,
        'paused': _paused,
        'processing': _processing,
        'maxQueueSize': config.maxQueueSize,
      };

  /// لیست آیتم‌های pending
  List<Map<String, dynamic>> get pendingItems =>
      _queue.map((i) => i.toJson()).toList();

  void dispose() {
    _processTimer?.cancel();
    _queue.clear();
  }
}
```

---

### 📄 بروزرسانی `lib/packages/core/lib/core.dart`

```dart
library core;

export 'src/bridge/message_bridge.dart';
export 'src/protocol/message_protocol.dart';
export 'src/runtime/webview_host.dart';
export 'src/runtime/asset_server.dart';
export 'src/utils/logger.dart';
export 'src/middleware/error_recovery.dart';
export 'src/middleware/circuit_breaker.dart';
export 'src/middleware/offline_queue.dart';
```

---

### 📄 بروزرسانی `lib/packages/plugin_engine/lib/src/plugin_manager.dart` — اضافه شدن CircuitBreaker

> فقط تغییرات کلیدی:

```dart
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
  final CircuitBreakerRegistry circuitBreakers;

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
  }) : circuitBreakers = circuitBreakers ?? CircuitBreakerRegistry();

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
        final stats = breaker.stats;
        return _errorResponse(
          request.requestId,
          PluginErrorCode.executionError,
          'Circuit breaker open for "${request.plugin}". '
              'Too many failures (${stats['failureCount']}). '
              'Retry later.',
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
          fn: () => plugin.onCall(request.method, request.args),
        );
      });

      final processingTime =
          DateTime.now().difference(startTime).inMilliseconds;

      // Cache result
      if (plugin.cacheable && !isMutation && result != null) {
        final cacheKey = _buildCacheKey(request);
        await cacheManager.set(cacheKey, result, ttl: plugin.defaultCacheTtl);
      }

      // Invalidate cache on mutation
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

  /// دسترسی به circuit breaker stats
  Map<String, dynamic> get circuitBreakerStats => circuitBreakers.allStats;

  /// reset circuit breaker
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

## بخش ۲: JS — Retry + Circuit Breaker + Offline Queue

### 📄 `assets/www/js/native-resilience.js`

```javascript
(function (global) {
  'use strict';

  // ═══════════════════════════════════════
  //  Retry Manager
  // ═══════════════════════════════════════

  var RetryManager = {
    defaultConfig: {
      maxRetries: 3,
      initialDelayMs: 200,
      backoffMultiplier: 2.0,
      maxDelayMs: 10000,
      retryableCodes: ['TIMEOUT', 'EXECUTION_ERROR', 'NETWORK_ERROR']
    },

    _pluginConfigs: {},

    setConfig: function (plugin, config) {
      this._pluginConfigs[plugin] = Object.assign({}, this.defaultConfig, config);
    },

    getConfig: function (plugin) {
      return this._pluginConfigs[plugin] || this.defaultConfig;
    },

    executeWithRetry: function (fn, options) {
      options = options || {};
      var config = Object.assign(
        {},
        this.defaultConfig,
        this._pluginConfigs[options.plugin] || {},
        options
      );

      return this._retry(fn, config, 0);
    },

    _retry: function (fn, config, attempt) {
      var self = this;

      return fn().catch(function (error) {
        attempt++;

        var isRetryable = self._isRetryable(error, config.retryableCodes);
        var hasMoreRetries = attempt <= config.maxRetries;

        if (!isRetryable || !hasMoreRetries) {
          throw error;
        }

        var delay = self._calculateDelay(attempt, config);

        if (config.onRetry) {
          config.onRetry(attempt, error, delay);
        }

        console.warn(
          '[Retry] Attempt ' + attempt + '/' + config.maxRetries +
          ', retrying in ' + delay + 'ms: ' +
          (error.message || error.code || JSON.stringify(error))
        );

        return new Promise(function (resolve) {
          setTimeout(resolve, delay);
        }).then(function () {
          return self._retry(fn, config, attempt);
        });
      });
    },

    _isRetryable: function (error, retryableCodes) {
      if (!error) return false;
      var code = error.code || '';
      return retryableCodes.indexOf(code) !== -1;
    },

    _calculateDelay: function (attempt, config) {
      var delay = config.initialDelayMs * Math.pow(config.backoffMultiplier, attempt - 1);
      delay = Math.min(delay, config.maxDelayMs);
      var jitter = delay * 0.2 * Math.random();
      return Math.round(delay + jitter);
    }
  };

  // ═══════════════════════════════════════
  //  Circuit Breaker (JS side)
  // ═══════════════════════════════════════

  function CircuitBreaker(name, config) {
    this.name = name;
    this.config = Object.assign({
      failureThreshold: 5,
      resetTimeoutMs: 30000,
      halfOpenMaxAttempts: 1
    }, config || {});

    this.state = 'closed';
    this.failureCount = 0;
    this.successCount = 0;
    this.totalCalls = 0;
    this.halfOpenAttempts = 0;
    this.lastFailureTime = null;
  }

  CircuitBreaker.prototype.isAllowed = function () {
    this._checkState();

    switch (this.state) {
      case 'closed': return true;
      case 'open': return false;
      case 'halfOpen': return this.halfOpenAttempts < this.config.halfOpenMaxAttempts;
      default: return true;
    }
  };

  CircuitBreaker.prototype._checkState = function () {
    if (this.state === 'open' && this.lastFailureTime) {
      var elapsed = Date.now() - this.lastFailureTime;
      if (elapsed >= this.config.resetTimeoutMs) {
        this.state = 'halfOpen';
        this.halfOpenAttempts = 0;
        console.log('[CircuitBreaker] [' + this.name + '] → half-open');
      }
    }
  };

  CircuitBreaker.prototype.execute = function (fn) {
    var self = this;

    if (!this.isAllowed()) {
      var retryAfter = this.lastFailureTime
        ? Math.max(0, this.config.resetTimeoutMs - (Date.now() - this.lastFailureTime))
        : this.config.resetTimeoutMs;

      return Promise.reject({
        code: 'CIRCUIT_OPEN',
        message: 'Circuit breaker [' + this.name + '] is open. Retry after ' + retryAfter + 'ms',
        retryAfterMs: retryAfter
      });
    }

    this.totalCalls++;

    if (this.state === 'halfOpen') {
      this.halfOpenAttempts++;
    }

    return fn().then(function (result) {
      self._onSuccess();
      return result;
    }).catch(function (error) {
      self._onFailure();
      throw error;
    });
  };

  CircuitBreaker.prototype._onSuccess = function () {
    this.successCount++;
    if (this.state === 'halfOpen') {
      this.state = 'closed';
      this.failureCount = 0;
      console.log('[CircuitBreaker] [' + this.name + '] → closed (recovered)');
    } else if (this.failureCount > 0) {
      this.failureCount = Math.max(0, this.failureCount - 1);
    }
  };

  CircuitBreaker.prototype._onFailure = function () {
    this.failureCount++;
    this.lastFailureTime = Date.now();

    if (this.state === 'halfOpen') {
      this.state = 'open';
      console.warn('[CircuitBreaker] [' + this.name + '] → open (half-open test failed)');
      return;
    }

    if (this.failureCount >= this.config.failureThreshold) {
      this.state = 'open';
      console.warn('[CircuitBreaker] [' + this.name + '] → open after ' + this.failureCount + ' failures');
    }
  };

  CircuitBreaker.prototype.reset = function () {
    this.state = 'closed';
    this.failureCount = 0;
    this.halfOpenAttempts = 0;
    this.lastFailureTime = null;
  };

  CircuitBreaker.prototype.getStats = function () {
    return {
      name: this.name,
      state: this.state,
      failureCount: this.failureCount,
      successCount: this.successCount,
      totalCalls: this.totalCalls
    };
  };

  // ═══════════════════════════════════════
  //  Circuit Breaker Registry
  // ═══════════════════════════════════════

  var CircuitBreakerRegistry = {
    _breakers: {},
    _defaultConfig: {},

    setDefaultConfig: function (config) {
      this._defaultConfig = config;
    },

    get: function (name) {
      if (!this._breakers[name]) {
        this._breakers[name] = new CircuitBreaker(name, this._defaultConfig);
      }
      return this._breakers[name];
    },

    reset: function (name) {
      if (this._breakers[name]) {
        this._breakers[name].reset();
      }
    },

    resetAll: function () {
      Object.keys(this._breakers).forEach(function (key) {
        this._breakers[key].reset();
      }.bind(this));
    },

    getAllStats: function () {
      var stats = {};
      Object.keys(this._breakers).forEach(function (key) {
        stats[key] = this._breakers[key].getStats();
      }.bind(this));
      return stats;
    }
  };

  // ═══════════════════════════════════════
  //  Offline Queue
  // ═══════════════════════════════════════

  var OfflineQueue = {
    _queue: [],
    _completed: [],
    _failed: [],
    _online: true,
    _paused: false,
    _processing: false,
    _timer: null,
    _eventListeners: {},

    config: {
      maxQueueSize: 200,
      defaultTtlMs: 3600000,
      processIntervalMs: 5000,
      maxRetries: 3
    },

    init: function (config) {
      Object.assign(this.config, config || {});
      this._startTimer();

      // اتصال به connectivity events
      if (global.NativeSDK) {
        global.NativeSDK.on('connectivity.change', function (data) {
          this.setOnline(data.online);
        }.bind(this));
      }
    },

    setOnline: function (online) {
      var wasOffline = !this._online;
      this._online = online;

      if (online && wasOffline && this._queue.length > 0) {
        console.log('[OfflineQueue] Back online — processing ' + this._queue.length + ' items');
        this._emit('online', { pendingCount: this._queue.length });
        this._processQueue();
      }

      if (!online) {
        this._emit('offline', { pendingCount: this._queue.length });
      }
    },

    enqueue: function (plugin, method, args, options) {
      options = options || {};

      if (this._queue.length >= this.config.maxQueueSize) {
        var removed = this._queue.shift();
        console.warn('[OfflineQueue] Queue full, removing:', removed.plugin + '.' + removed.method);
      }

      var item = {
        id: 'q_' + Date.now() + '_' + Math.random().toString(36).substr(2, 5),
        plugin: plugin,
        method: method,
        args: args || {},
        createdAt: Date.now(),
        expiresAt: Date.now() + (options.ttlMs || this.config.defaultTtlMs),
        status: 'pending',
        attempts: 0,
        lastError: null
      };

      this._queue.push(item);
      this._emit('enqueued', item);

      if (this._online && !this._paused) {
        this._processQueue();
      }

      return item.id;
    },

    _startTimer: function () {
      var self = this;
      if (this._timer) clearInterval(this._timer);
      this._timer = setInterval(function () {
        if (self._online && !self._paused && self._queue.length > 0) {
          self._processQueue();
        }
      }, this.config.processIntervalMs);
    },

    _processQueue: async function () {
      if (this._processing || this._paused) return;
      this._processing = true;

      try {
        while (this._queue.length > 0 && this._online && !this._paused) {
          var item = this._queue[0];

          if (Date.now() > item.expiresAt) {
            this._queue.shift();
            item.status = 'expired';
            this._failed.push(item);
            this._emit('expired', item);
            continue;
          }

          item.status = 'processing';
          item.attempts++;

          try {
            var result = await global.NativeSDK.call(
              item.plugin,
              item.method,
              item.args
            );

            this._queue.shift();
            item.status = 'completed';
            this._completed.push(item);
            this._emit('completed', { item: item, result: result });
          } catch (error) {
            item.lastError = error.message || error.code || JSON.stringify(error);

            if (item.attempts >= this.config.maxRetries) {
              this._queue.shift();
              item.status = 'failed';
              this._failed.push(item);
              this._emit('failed', item);
            } else {
              item.status = 'pending';
              this._queue.push(this._queue.shift());
            }
          }
        }
      } finally {
        this._processing = false;
      }
    },

    pause: function () { this._paused = true; },
    resume: function () { this._paused = false; this._processQueue(); },
    clear: function () { this._queue = []; this._completed = []; this._failed = []; },

    remove: function (itemId) {
      var idx = this._queue.findIndex(function (i) { return i.id === itemId; });
      if (idx !== -1) { this._queue.splice(idx, 1); return true; }
      return false;
    },

    getStats: function () {
      return {
        pending: this._queue.length,
        completed: this._completed.length,
        failed: this._failed.length,
        online: this._online,
        paused: this._paused,
        processing: this._processing
      };
    },

    getPending: function () {
      return this._queue.map(function (i) {
        return { id: i.id, plugin: i.plugin, method: i.method, attempts: i.attempts, status: i.status };
      });
    },

    on: function (event, callback) {
      if (!this._eventListeners[event]) this._eventListeners[event] = [];
      this._eventListeners[event].push(callback);
      return function () { this.off(event, callback); }.bind(this);
    },

    off: function (event, callback) {
      if (!this._eventListeners[event]) return;
      this._eventListeners[event] = this._eventListeners[event].filter(function (cb) {
        return cb !== callback;
      });
    },

    _emit: function (event, data) {
      var listeners = this._eventListeners[event] || [];
      listeners.forEach(function (cb) { try { cb(data); } catch (_) {} });
    },

    dispose: function () {
      if (this._timer) clearInterval(this._timer);
      this._queue = [];
    }
  };

  // ═══════════════════════════════════════
  //  Resilient Call — wraps everything
  // ═══════════════════════════════════════

  function resilientCall(plugin, method, args, options) {
    options = options || {};
    var enableRetry = options.retry !== false;
    var enableCircuitBreaker = options.circuitBreaker !== false;
    var queueIfOffline = options.queueIfOffline === true;

    var breaker = enableCircuitBreaker
      ? CircuitBreakerRegistry.get(plugin)
      : null;

    var callFn = function () {
      var execFn = function () {
        return global.NativeSDK.call(plugin, method, args, options);
      };

      if (breaker) {
        return breaker.execute(execFn);
      }
      return execFn();
    };

    var wrappedFn;

    if (enableRetry) {
      wrappedFn = function () {
        return RetryManager.executeWithRetry(callFn, {
          plugin: plugin,
          maxRetries: options.maxRetries,
          onRetry: options.onRetry
        });
      };
    } else {
      wrappedFn = callFn;
    }

    return wrappedFn().catch(function (error) {
      if (queueIfOffline && !OfflineQueue._online) {
        console.log('[Resilient] Queuing offline: ' + plugin + '.' + method);
        var itemId = OfflineQueue.enqueue(plugin, method, args, {
          ttlMs: options.queueTtlMs
        });
        return { queued: true, queueItemId: itemId };
      }
      throw error;
    });
  }

  // ═══════════════════════════════════════
  //  Export
  // ═══════════════════════════════════════

  global.NativeResilience = {
    RetryManager: RetryManager,
    CircuitBreaker: CircuitBreakerRegistry,
    OfflineQueue: OfflineQueue,
    resilientCall: resilientCall,

    init: function (config) {
      config = config || {};

      if (config.retry) {
        RetryManager.defaultConfig = Object.assign(
          RetryManager.defaultConfig,
          config.retry
        );
      }

      if (config.circuitBreaker) {
        CircuitBreakerRegistry.setDefaultConfig(config.circuitBreaker);
      }

      if (config.offlineQueue) {
        OfflineQueue.init(config.offlineQueue);
      } else {
        OfflineQueue.init();
      }

      console.log('[NativeResilience] Initialized');
    },

    getStats: function () {
      return {
        circuitBreakers: CircuitBreakerRegistry.getAllStats(),
        offlineQueue: OfflineQueue.getStats(),
        retryConfig: RetryManager.defaultConfig
      };
    }
  };

})(window);
```

---

### 📄 بروزرسانی `assets/www/index.html`

> اضافه کردن قبل از `app.js`:

```html
<script src="js/native-resilience.js"></script>
```

---

### نحوه استفاده در JS

```javascript
// ۱. Init resilience
NativeResilience.init({
  retry: {
    maxRetries: 3,
    initialDelayMs: 300,
    backoffMultiplier: 2
  },
  circuitBreaker: {
    failureThreshold: 5,
    resetTimeoutMs: 30000
  },
  offlineQueue: {
    maxQueueSize: 100,
    processIntervalMs: 5000
  }
});

// ۲. Resilient call (auto-retry + circuit breaker)
var data = await NativeResilience.resilientCall('http', 'get', {
  url: 'https://api.example.com/data'
});

// ۳. Queue if offline
await NativeResilience.resilientCall('storage', 'set', {
  key: 'sync_data',
  value: { data: 123 }
}, {
  queueIfOffline: true,
  queueTtlMs: 3600000
});

// ۴. Listen to queue events
NativeResilience.OfflineQueue.on('completed', function(data) {
  console.log('Queue item completed:', data.item.plugin);
});

// ۵. Stats
console.log(NativeResilience.getStats());

// ۶. Per-plugin retry config
NativeResilience.RetryManager.setConfig('http', {
  maxRetries: 5,
  initialDelayMs: 500
});

// ۷. Manual circuit breaker control
NativeResilience.CircuitBreaker.reset('http');
NativeResilience.CircuitBreaker.resetAll();
```

---

در پیام بعدی **Plugin Lazy Loading** و بعد از اون **Testing Framework** رو می‌فرستم.

ادامه بدم؟
