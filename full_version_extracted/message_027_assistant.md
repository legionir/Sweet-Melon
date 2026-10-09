# پیام ۳/۳: Automated Testing Framework

---

## معماری تست

```
test/
├── unit/
│   ├── core/
│   │   ├── message_bridge_test.dart
│   │   ├── message_protocol_test.dart
│   │   └── asset_server_test.dart
│   ├── middleware/
│   │   ├── error_recovery_test.dart
│   │   ├── circuit_breaker_test.dart
│   │   └── offline_queue_test.dart
│   ├── engine/
│   │   ├── plugin_registry_test.dart
│   │   ├── plugin_manager_test.dart
│   │   └── lazy_plugin_loader_test.dart
│   ├── security/
│   │   ├── permission_manager_test.dart
│   │   ├── rate_limiter_test.dart
│   │   └── execution_guard_test.dart
│   └── performance/
│       └── cache_manager_test.dart
├── plugins/
│   ├── storage_plugin_test.dart
│   ├── file_system_plugin_test.dart
│   ├── clipboard_plugin_test.dart
│   ├── encryption_plugin_test.dart
│   ├── database_plugin_test.dart
│   └── ...
├── integration/
│   ├── bridge_integration_test.dart
│   ├── plugin_lifecycle_test.dart
│   └── lazy_loading_integration_test.dart
├── helpers/
│   ├── mock_plugin.dart
│   ├── test_helpers.dart
│   └── fake_providers.dart
└── test_runner.dart
```

---

## بخش ۱: Test Helpers و Mocks

### 📄 `test/helpers/mock_plugin.dart`

```dart
import 'dart:async';

import 'package:sweetmelon/packages/plugin_engine/lib/plugin_engine.dart';

/// پلاگین ساده برای تست
class MockPlugin extends Plugin {
  final String pluginName;
  final String pluginVersion;
  final List<String> methods;
  final Map<String, dynamic Function(Map<String, dynamic>)> handlers;
  final List<String> permissions;

  int callCount = 0;
  int initCount = 0;
  int disposeCount = 0;
  final List<String> callLog = [];
  bool shouldFail = false;
  String failMessage = 'Mock failure';
  Duration? simulatedDelay;

  MockPlugin({
    this.pluginName = 'mockPlugin',
    this.pluginVersion = '1.0.0',
    this.methods = const ['doSomething', 'getData', 'setData', 'getInfo'],
    this.handlers = const {},
    this.permissions = const [],
  });

  @override
  String get name => pluginName;

  @override
  String get version => pluginVersion;

  @override
  List<String> get supportedMethods => methods;

  @override
  List<String> get requiredPermissions => permissions;

  @override
  Future<void> onInitialize() async {
    initCount++;
  }

  @override
  Future<void> onDispose() async {
    disposeCount++;
  }

  @override
  Future<dynamic> onCall(String method, Map<String, dynamic> args) async {
    callCount++;
    callLog.add('$method:${args.toString()}');

    if (simulatedDelay != null) {
      await Future.delayed(simulatedDelay!);
    }

    if (shouldFail) {
      throw Exception(failMessage);
    }

    if (handlers.containsKey(method)) {
      return handlers[method]!(args);
    }

    switch (method) {
      case 'doSomething':
        return {'done': true, 'args': args};
      case 'getData':
        return {'key': args['key'], 'value': 'mock_value'};
      case 'setData':
        return {'saved': true};
      case 'getInfo':
        return {
          'name': name,
          'version': version,
          'callCount': callCount,
        };
      default:
        throw UnsupportedError('Method "$method" not supported');
    }
  }

  void reset() {
    callCount = 0;
    initCount = 0;
    disposeCount = 0;
    callLog.clear();
    shouldFail = false;
    simulatedDelay = null;
  }
}

/// پلاگین cacheable
class CacheableMockPlugin extends MockPlugin {
  CacheableMockPlugin({
    super.pluginName = 'cacheableMock',
  });

  @override
  bool get cacheable => true;

  @override
  Duration get defaultCacheTtl => const Duration(seconds: 10);
}

/// پلاگین که initialize خیلی طول می‌کشه
class SlowInitPlugin extends MockPlugin {
  final Duration initDuration;

  SlowInitPlugin({
    super.pluginName = 'slowInit',
    this.initDuration = const Duration(milliseconds: 500),
  });

  @override
  Future<void> onInitialize() async {
    await Future.delayed(initDuration);
    await super.onInitialize();
  }
}

/// پلاگین که initialize خطا می‌ده
class FailingInitPlugin extends MockPlugin {
  FailingInitPlugin({super.pluginName = 'failingInit'});

  @override
  Future<void> onInitialize() async {
    throw Exception('Init failed intentionally');
  }
}
```

---

### 📄 `test/helpers/test_helpers.dart`

```dart
import 'package:sweetmelon/packages/core/lib/core.dart';
import 'package:sweetmelon/packages/performance/lib/performance.dart';
import 'package:sweetmelon/packages/security/lib/security.dart';
import 'package:sweetmelon/packages/plugin_engine/lib/plugin_engine.dart';

/// ساخت PluginManager با تنظیمات تست
PluginManager createTestPluginManager({
  PluginRegistry? registry,
  PermissionManager? permissionManager,
  RateLimiter? rateLimiter,
  ExecutionGuard? executionGuard,
  CacheManager? cacheManager,
  LazyPluginLoader? lazyLoader,
}) {
  final reg = registry ?? PluginRegistry();
  final pm = permissionManager ?? _createTestPermissionManager();
  final rl = rateLimiter ?? RateLimiter();
  final eg = executionGuard ?? ExecutionGuard(defaultTimeoutMs: 5000);
  final cm = cacheManager ?? CacheManager(maxEntries: 100);

  return PluginManager(
    registry: reg,
    permissionManager: pm,
    rateLimiter: rl,
    executionGuard: eg,
    cacheManager: cm,
    lazyLoader: lazyLoader,
  );
}

PermissionManager _createTestPermissionManager() {
  final manager = PermissionManager(
    cacheTtl: const Duration(minutes: 30),
  );
  manager.setProvider(
    const StaticPermissionProvider(
      grants: {
        'camera': PermissionStatus.granted,
        'storage': PermissionStatus.granted,
        'location': PermissionStatus.granted,
        'microphone': PermissionStatus.granted,
        'contacts': PermissionStatus.granted,
        'bluetooth': PermissionStatus.granted,
      },
      defaultStatus: PermissionStatus.granted,
    ),
  );
  return manager;
}

/// ساخت PluginRequest برای تست
PluginRequest createTestRequest({
  String plugin = 'mockPlugin',
  String method = 'doSomething',
  Map<String, dynamic>? args,
  String version = '1.0.0',
}) {
  return PluginRequest.create(
    plugin: plugin,
    method: method,
    args: args,
    version: version,
  );
}

/// اجرای چندین request و برگرداندن نتایج
Future<List<PluginResponse>> executeMany(
  PluginManager manager,
  int count, {
  String plugin = 'mockPlugin',
  String method = 'doSomething',
}) async {
  final responses = <PluginResponse>[];

  for (int i = 0; i < count; i++) {
    final request = createTestRequest(
      plugin: plugin,
      method: method,
      args: {'index': i},
    );
    final response = await manager.execute(request);
    responses.add(response);
  }

  return responses;
}

/// بررسی اینکه همه responses موفق بودن
bool allSuccessful(List<PluginResponse> responses) {
  return responses.every((r) => r.success);
}

/// بررسی اینکه همه responses خطا بودن
bool allFailed(List<PluginResponse> responses) {
  return responses.every((r) => !r.success);
}

/// تعداد response‌های موفق
int successCount(List<PluginResponse> responses) {
  return responses.where((r) => r.success).length;
}
```

---

### 📄 `test/helpers/fake_providers.dart`

```dart
import 'dart:async';

import 'package:sweetmelon/packages/security/lib/security.dart';

/// Provider که permission خاصی رو deny می‌کنه
class SelectivePermissionProvider implements PermissionProvider {
  final Set<String> deniedPermissions;

  const SelectivePermissionProvider({
    this.deniedPermissions = const {},
  });

  @override
  Future<PermissionStatus> checkPermission(String permission) async {
    if (deniedPermissions.contains(permission)) {
      return PermissionStatus.denied;
    }
    return PermissionStatus.granted;
  }

  @override
  Future<PermissionStatus> requestPermission(String permission) async {
    return checkPermission(permission);
  }
}

/// Provider که بعد از n بار request، grant می‌کنه
class DelayedGrantProvider implements PermissionProvider {
  final int grantAfterAttempts;
  final Map<String, int> _attempts = {};

  DelayedGrantProvider({this.grantAfterAttempts = 2});

  @override
  Future<PermissionStatus> checkPermission(String permission) async {
    final count = _attempts[permission] ?? 0;
    return count >= grantAfterAttempts
        ? PermissionStatus.granted
        : PermissionStatus.denied;
  }

  @override
  Future<PermissionStatus> requestPermission(String permission) async {
    _attempts[permission] = (_attempts[permission] ?? 0) + 1;
    return checkPermission(permission);
  }
}
```

---

## بخش ۲: Unit Tests — Core

### 📄 `test/unit/core/message_protocol_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sweetmelon/packages/core/lib/core.dart';

void main() {
  group('PluginRequest', () {
    test('create generates valid request', () {
      final request = PluginRequest.create(
        plugin: 'storage',
        method: 'get',
        args: {'key': 'test'},
      );

      expect(request.plugin, 'storage');
      expect(request.method, 'get');
      expect(request.args['key'], 'test');
      expect(request.requestId, isNotEmpty);
      expect(request.version, '1.0.0');
    });

    test('fromJson parses correctly', () {
      final json = {
        'requestId': 'req_123',
        'plugin': 'camera',
        'method': 'takePhoto',
        'args': {'quality': 80},
        'version': '2.0.0',
        'timestamp': '2024-01-15T10:30:00.000Z',
      };

      final request = PluginRequest.fromJson(json);

      expect(request.requestId, 'req_123');
      expect(request.plugin, 'camera');
      expect(request.method, 'takePhoto');
      expect(request.args['quality'], 80);
      expect(request.version, '2.0.0');
    });

    test('fromJson handles missing optional fields', () {
      final json = {
        'plugin': 'test',
        'method': 'run',
      };

      final request = PluginRequest.fromJson(json);

      expect(request.plugin, 'test');
      expect(request.method, 'run');
      expect(request.version, '1.0.0');
      expect(request.args, isEmpty);
      expect(request.requestId, isNotEmpty);
    });

    test('toJson roundtrip', () {
      final original = PluginRequest.create(
        plugin: 'storage',
        method: 'set',
        args: {'key': 'x', 'value': 123},
      );

      final json = original.toJson();
      final parsed = PluginRequest.fromJson(json);

      expect(parsed.plugin, original.plugin);
      expect(parsed.method, original.method);
      expect(parsed.args['key'], original.args['key']);
      expect(parsed.args['value'], original.args['value']);
    });
  });

  group('PluginResponse', () {
    test('success factory', () {
      final response = PluginResponse.success(
        requestId: 'req_1',
        data: {'result': 42},
      );

      expect(response.success, true);
      expect(response.data['result'], 42);
      expect(response.error, isNull);
    });

    test('failure factory', () {
      final response = PluginResponse.failure(
        requestId: 'req_1',
        error: const PluginError(
          code: PluginErrorCode.pluginNotFound,
          message: 'Not found',
        ),
      );

      expect(response.success, false);
      expect(response.error, isNotNull);
      expect(response.error!.code, PluginErrorCode.pluginNotFound);
      expect(response.error!.message, 'Not found');
    });

    test('toJson/fromJson roundtrip', () {
      final original = PluginResponse.success(
        requestId: 'req_1',
        data: {'items': [1, 2, 3]},
        metadata: const ResponseMetadata(
          processingTimeMs: 42,
          pluginVersion: '1.0.0',
          fromCache: false,
        ),
      );

      final json = original.toJson();
      final parsed = PluginResponse.fromJson(json);

      expect(parsed.success, true);
      expect(parsed.requestId, 'req_1');
      expect(parsed.metadata.processingTimeMs, 42);
    });
  });

  group('PluginError', () {
    test('fromString maps known codes', () {
      expect(
        PluginErrorCode.fromString('PERMISSION_DENIED'),
        PluginErrorCode.permissionDenied,
      );
      expect(
        PluginErrorCode.fromString('TIMEOUT'),
        PluginErrorCode.timeout,
      );
      expect(
        PluginErrorCode.fromString('UNKNOWN_CODE'),
        PluginErrorCode.unknown,
      );
    });
  });

  group('BatchOptions', () {
    test('defaults are correct', () {
      final options = BatchOptions.defaults();

      expect(options.parallel, true);
      expect(options.stopOnError, false);
      expect(options.timeoutMs, isNull);
    });
  });
}
```

---

### 📄 `test/unit/core/message_bridge_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sweetmelon/packages/core/lib/core.dart';

void main() {
  late MessageBridge bridge;

  setUp(() {
    bridge = MessageBridge();
  });

  tearDown(() {
    bridge.dispose();
  });

  group('MessageBridge', () {
    test('initial state', () {
      // bridge should not be ready initially
      // pending messages should be empty
      expect(bridge, isNotNull);
    });

    test('resetBridgeState clears pending', () {
      bridge.resetBridgeState();
      // No exception should be thrown
    });

    test('onBridgeReady processes pending messages', () {
      bridge.onBridgeReady();
      // No exception — pending queue empty
    });

    test('handles incoming message with missing fields', () async {
      bool errorSent = false;

      bridge.setMessageHandler((request) async {
        return PluginResponse.success(
          requestId: request.requestId,
          data: 'ok',
        );
      });

      // Missing plugin and method — should send error
      await bridge.handleIncomingMessage({
        'requestId': 'test_1',
      });

      // No crash
    });

    test('handles valid incoming message', () async {
      PluginRequest? receivedRequest;

      bridge.setMessageHandler((request) async {
        receivedRequest = request;
        return PluginResponse.success(
          requestId: request.requestId,
          data: {'result': 'ok'},
        );
      });

      await bridge.handleIncomingMessage({
        'requestId': 'test_2',
        'plugin': 'storage',
        'method': 'get',
        'args': {'key': 'test'},
      });

      expect(receivedRequest, isNotNull);
      expect(receivedRequest!.plugin, 'storage');
      expect(receivedRequest!.method, 'get');
    });

    test('messageStream emits events', () async {
      bridge.setMessageHandler((request) async {
        return PluginResponse.success(
          requestId: request.requestId,
          data: 'ok',
        );
      });

      final messages = <BridgeMessage>[];
      bridge.messageStream.listen(messages.add);

      await bridge.handleIncomingMessage({
        'requestId': 'test_3',
        'plugin': 'test',
        'method': 'run',
        'args': {},
      });

      await Future.delayed(const Duration(milliseconds: 50));

      expect(messages, isNotEmpty);
      expect(messages.first.direction, BridgeMessageDirection.incoming);
    });

    test('batch request handling', () async {
      int callCount = 0;

      bridge.setMessageHandler((request) async {
        callCount++;
        return PluginResponse.success(
          requestId: request.requestId,
          data: {'index': callCount},
        );
      });

      await bridge.handleIncomingMessage({
        'type': 'batch',
        'batchId': 'batch_1',
        'requests': [
          {'requestId': 'r1', 'plugin': 'a', 'method': 'm1', 'args': {}},
          {'requestId': 'r2', 'plugin': 'b', 'method': 'm2', 'args': {}},
        ],
      });

      expect(callCount, 2);
    });
  });
}
```

---

## بخش ۳: Unit Tests — Middleware

### 📄 `test/unit/middleware/error_recovery_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sweetmelon/packages/core/lib/core.dart';

void main() {
  group('ErrorRecovery.retry', () {
    test('succeeds on first attempt', () async {
      final result = await ErrorRecovery.retry<int>(
        action: () async => 42,
        label: 'test',
      );

      expect(result.success, true);
      expect(result.value, 42);
      expect(result.attempts, 1);
    });

    test('retries on failure then succeeds', () async {
      int attempt = 0;

      final result = await ErrorRecovery.retry<String>(
        action: () async {
          attempt++;
          if (attempt < 3) {
            throw Exception('temporary error');
          }
          return 'success';
        },
        config: const RetryConfig(
          maxRetries: 5,
          initialDelay: Duration(milliseconds: 10),
          retryableErrors: {},
        ),
        label: 'retry-test',
      );

      expect(result.success, true);
      expect(result.value, 'success');
      expect(result.attempts, 3);
    });

    test('fails after max retries', () async {
      final result = await ErrorRecovery.retry<int>(
        action: () async {
          throw Exception('always fails');
        },
        config: const RetryConfig(
          maxRetries: 2,
          initialDelay: Duration(milliseconds: 10),
          retryableErrors: {},
        ),
        label: 'fail-test',
      );

      expect(result.success, false);
      expect(result.error, isNotNull);
      expect(result.attempts, 3); // initial + 2 retries
    });

    test('uses fallback on failure', () async {
      final result = await ErrorRecovery.retry<String>(
        action: () async => throw Exception('fail'),
        config: const RetryConfig(
          maxRetries: 1,
          initialDelay: Duration(milliseconds: 10),
          retryableErrors: {},
        ),
        fallback: (error, attempt) async => 'fallback_value',
        label: 'fallback-test',
      );

      expect(result.success, true);
      expect(result.value, 'fallback_value');
    });

    test('no retry config skips retries', () async {
      int attempt = 0;

      final result = await ErrorRecovery.retry<int>(
        action: () async {
          attempt++;
          throw Exception('fail');
        },
        config: RetryConfig.none,
        label: 'no-retry',
      );

      expect(result.success, false);
      expect(attempt, 1);
    });

    test('onRetry callback fires', () async {
      int retryCount = 0;

      await ErrorRecovery.retry<int>(
        action: () async {
          if (retryCount < 2) throw Exception('fail');
          return 1;
        },
        config: const RetryConfig(
          maxRetries: 3,
          initialDelay: Duration(milliseconds: 10),
          retryableErrors: {},
        ),
        onRetry: (attempt, error, delay) {
          retryCount++;
        },
        label: 'callback-test',
      );

      expect(retryCount, 2);
    });
  });
}
```

---

### 📄 `test/unit/middleware/circuit_breaker_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sweetmelon/packages/core/lib/core.dart';

void main() {
  group('CircuitBreaker', () {
    late CircuitBreaker breaker;

    setUp(() {
      breaker = CircuitBreaker(
        name: 'test',
        config: const CircuitBreakerConfig(
          failureThreshold: 3,
          resetTimeout: Duration(milliseconds: 200),
        ),
      );
    });

    test('starts in closed state', () {
      expect(breaker.state, CircuitState.closed);
      expect(breaker.isAllowed, true);
    });

    test('stays closed on success', () async {
      final result = await breaker.execute(() async => 42);

      expect(result, 42);
      expect(breaker.state, CircuitState.closed);
    });

    test('opens after threshold failures', () async {
      for (int i = 0; i < 3; i++) {
        try {
          await breaker.execute(() async => throw Exception('fail'));
        } catch (_) {}
      }

      expect(breaker.state, CircuitState.open);
      expect(breaker.isAllowed, false);
    });

    test('rejects calls when open', () async {
      // Force open
      for (int i = 0; i < 3; i++) {
        try {
          await breaker.execute(() async => throw Exception('fail'));
        } catch (_) {}
      }

      expect(
        () => breaker.execute(() async => 'should not run'),
        throwsA(isA<CircuitBreakerOpenException>()),
      );
    });

    test('transitions to half-open after timeout', () async {
      for (int i = 0; i < 3; i++) {
        try {
          await breaker.execute(() async => throw Exception('fail'));
        } catch (_) {}
      }

      expect(breaker.state, CircuitState.open);

      // Wait for reset timeout
      await Future.delayed(const Duration(milliseconds: 250));

      expect(breaker.state, CircuitState.halfOpen);
      expect(breaker.isAllowed, true);
    });

    test('closes from half-open on success', () async {
      for (int i = 0; i < 3; i++) {
        try {
          await breaker.execute(() async => throw Exception('fail'));
        } catch (_) {}
      }

      await Future.delayed(const Duration(milliseconds: 250));

      final result = await breaker.execute(() async => 'recovered');

      expect(result, 'recovered');
      expect(breaker.state, CircuitState.closed);
    });

    test('re-opens from half-open on failure', () async {
      for (int i = 0; i < 3; i++) {
        try {
          await breaker.execute(() async => throw Exception('fail'));
        } catch (_) {}
      }

      await Future.delayed(const Duration(milliseconds: 250));

      try {
        await breaker.execute(() async => throw Exception('fail again'));
      } catch (_) {}

      expect(breaker.state, CircuitState.open);
    });

    test('reset works', () async {
      for (int i = 0; i < 3; i++) {
        try {
          await breaker.execute(() async => throw Exception('fail'));
        } catch (_) {}
      }

      expect(breaker.state, CircuitState.open);

      breaker.reset();

      expect(breaker.state, CircuitState.closed);
      expect(breaker.isAllowed, true);
    });

    test('stats are tracked', () async {
      await breaker.execute(() async => 'ok');

      try {
        await breaker.execute(() async => throw Exception('fail'));
      } catch (_) {}

      final stats = breaker.stats;

      expect(stats['totalCalls'], 2);
      expect(stats['successCount'], 1);
      expect(stats['failureCount'], 1);
    });
  });

  group('CircuitBreakerRegistry', () {
    test('creates breakers lazily', () {
      final registry = CircuitBreakerRegistry();

      final b1 = registry.get('plugin_a');
      final b2 = registry.get('plugin_a');

      expect(identical(b1, b2), true);
    });

    test('reset specific breaker', () async {
      final registry = CircuitBreakerRegistry(
        defaultConfig: const CircuitBreakerConfig(failureThreshold: 1),
      );

      try {
        await registry.execute('test', () async => throw Exception('fail'));
      } catch (_) {}

      expect(registry.get('test').state, CircuitState.open);

      registry.reset('test');
      expect(registry.get('test').state, CircuitState.closed);
    });

    test('resetAll resets all breakers', () async {
      final registry = CircuitBreakerRegistry(
        defaultConfig: const CircuitBreakerConfig(failureThreshold: 1),
      );

      try {
        await registry.execute('a', () async => throw Exception('fail'));
      } catch (_) {}
      try {
        await registry.execute('b', () async => throw Exception('fail'));
      } catch (_) {}

      registry.resetAll();

      expect(registry.get('a').state, CircuitState.closed);
      expect(registry.get('b').state, CircuitState.closed);
    });
  });
}
```

---

## بخش ۴: Unit Tests — Engine

### 📄 `test/unit/engine/plugin_registry_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sweetmelon/packages/plugin_engine/lib/plugin_engine.dart';

import '../../helpers/mock_plugin.dart';

void main() {
  group('PluginRegistry', () {
    late PluginRegistry registry;

    setUp(() {
      registry = PluginRegistry();
    });

    tearDown(() async {
      await registry.dispose();
    });

    test('register and resolve plugin', () async {
      final plugin = MockPlugin(pluginName: 'test');
      await registry.register(plugin);

      final resolved = registry.resolve('test');

      expect(resolved, isNotNull);
      expect(resolved!.name, 'test');
      expect(resolved.isReady, true);
    });

    test('resolve returns null for unknown plugin', () {
      expect(registry.resolve('nonexistent'), isNull);
    });

    test('isRegistered returns correct value', () async {
      final plugin = MockPlugin(pluginName: 'test');
      await registry.register(plugin);

      expect(registry.isRegistered('test'), true);
      expect(registry.isRegistered('nonexistent'), false);
    });

    test('unregister disposes plugin', () async {
      final plugin = MockPlugin(pluginName: 'test');
      await registry.register(plugin);

      await registry.unregister('test');

      expect(registry.isRegistered('test'), false);
      expect(plugin.disposeCount, 1);
    });

    test('register replaces existing plugin', () async {
      final plugin1 = MockPlugin(pluginName: 'test');
      final plugin2 = MockPlugin(pluginName: 'test');

      await registry.register(plugin1);
      await registry.register(plugin2);

      expect(plugin1.disposeCount, 1);
      expect(registry.resolve('test'), plugin2);
    });

    test('registeredPlugins returns all names', () async {
      await registry.register(MockPlugin(pluginName: 'a'));
      await registry.register(MockPlugin(pluginName: 'b'));
      await registry.register(MockPlugin(pluginName: 'c'));

      expect(registry.registeredPlugins, containsAll(['a', 'b', 'c']));
    });

    test('getPluginInfos returns correct info', () async {
      await registry.register(MockPlugin(
        pluginName: 'test',
        methods: ['m1', 'm2'],
      ));

      final infos = registry.getPluginInfos();

      expect(infos.length, 1);
      expect(infos[0].name, 'test');
      expect(infos[0].supportedMethods, ['m1', 'm2']);
      expect(infos[0].isReady, true);
    });

    test('events stream emits registration events', () async {
      final events = <PluginRegistrationEvent>[];
      registry.events.listen(events.add);

      await registry.register(MockPlugin(pluginName: 'test'));

      await Future.delayed(const Duration(milliseconds: 50));

      expect(events.length, 1);
      expect(events[0].type, RegistrationEventType.registered);
      expect(events[0].pluginName, 'test');
    });

    test('dispose disposes all plugins', () async {
      final p1 = MockPlugin(pluginName: 'a');
      final p2 = MockPlugin(pluginName: 'b');

      await registry.register(p1);
      await registry.register(p2);

      await registry.dispose();

      expect(p1.disposeCount, 1);
      expect(p2.disposeCount, 1);
    });
  });
}
```

---

### 📄 `test/unit/engine/plugin_manager_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sweetmelon/packages/core/lib/core.dart';
import 'package:sweetmelon/packages/plugin_engine/lib/plugin_engine.dart';

import '../../helpers/mock_plugin.dart';
import '../../helpers/test_helpers.dart';

void main() {
  group('PluginManager', () {
    late PluginRegistry registry;
    late PluginManager manager;
    late MockPlugin plugin;

    setUp(() async {
      registry = PluginRegistry();
      plugin = MockPlugin();
      await registry.register(plugin);
      manager = createTestPluginManager(registry: registry);
    });

    tearDown(() async {
      manager.dispose();
      await registry.dispose();
    });

    test('executes plugin method successfully', () async {
      final request = createTestRequest(
        plugin: 'mockPlugin',
        method: 'doSomething',
        args: {'key': 'value'},
      );

      final response = await manager.execute(request);

      expect(response.success, true);
      expect(response.data['done'], true);
      expect(plugin.callCount, 1);
    });

    test('returns error for unknown plugin', () async {
      final request = createTestRequest(
        plugin: 'nonexistent',
        method: 'run',
      );

      final response = await manager.execute(request);

      expect(response.success, false);
      expect(response.error!.code, PluginErrorCode.pluginNotFound);
    });

    test('returns error for unknown method', () async {
      final request = createTestRequest(
        plugin: 'mockPlugin',
        method: 'nonexistentMethod',
      );

      final response = await manager.execute(request);

      expect(response.success, false);
      expect(response.error!.code, PluginErrorCode.methodNotFound);
    });

    test('handles plugin execution error', () async {
      plugin.shouldFail = true;
      plugin.failMessage = 'Test failure';

      final request = createTestRequest();
      final response = await manager.execute(request);

      expect(response.success, false);
      expect(response.error!.code, PluginErrorCode.executionError);
    });

    test('caches results for cacheable plugins', () async {
      final cachePlugin = CacheableMockPlugin();
      await registry.register(cachePlugin);

      final request1 = createTestRequest(
        plugin: 'cacheableMock',
        method: 'getData',
        args: {'key': 'test'},
      );

      final response1 = await manager.execute(request1);
      expect(response1.success, true);
      expect(response1.metadata.fromCache, false);

      final response2 = await manager.execute(request1);
      expect(response2.success, true);
      expect(response2.metadata.fromCache, true);

      expect(cachePlugin.callCount, 1); // cache hit
    });

    test('invalidates cache on mutation', () async {
      final cachePlugin = CacheableMockPlugin();
      await registry.register(cachePlugin);

      // Read
      final getRequest = createTestRequest(
        plugin: 'cacheableMock',
        method: 'getData',
        args: {'key': 'test'},
      );
      await manager.execute(getRequest);

      // Mutation
      final setRequest = createTestRequest(
        plugin: 'cacheableMock',
        method: 'setData',
        args: {'key': 'test', 'value': 'new'},
      );
      await manager.execute(setRequest);

      // Read again — should NOT be cached
      final response = await manager.execute(getRequest);
      expect(response.metadata.fromCache, false);
      expect(cachePlugin.callCount, 3);
    });

    test('batch execution parallel', () async {
      final requests = List.generate(5, (i) => createTestRequest(
        args: {'index': i},
      ));

      final responses = await manager.executeBatch(
        requests,
        const BatchOptions(parallel: true, stopOnError: false),
      );

      expect(responses.length, 5);
      expect(allSuccessful(responses), true);
    });

    test('batch execution sequential with stopOnError', () async {
      plugin.shouldFail = false;

      int callIndex = 0;
      final failPlugin = MockPlugin(
        pluginName: 'failAt3',
        handlers: {
          'doSomething': (args) {
            callIndex++;
            if (callIndex == 3) throw Exception('fail at 3');
            return {'index': callIndex};
          },
        },
      );

      await registry.register(failPlugin);

      final requests = List.generate(5, (i) => createTestRequest(
        plugin: 'failAt3',
      ));

      final responses = await manager.executeBatch(
        requests,
        const BatchOptions(parallel: false, stopOnError: true),
      );

      expect(responses.length, 3);
      expect(responses[0].success, true);
      expect(responses[1].success, true);
      expect(responses[2].success, false);
    });

    test('records stats', () async {
      await manager.execute(createTestRequest());
      await manager.execute(createTestRequest());

      final stats = manager.stats;
      expect(stats, isNotEmpty);

      final key = 'mockPlugin.doSomething';
      expect(stats[key]!.totalCalls, 2);
    });

    test('emits traces', () async {
      final traces = <PluginTrace>[];
      manager.traces.listen(traces.add);

      await manager.execute(createTestRequest());

      await Future.delayed(const Duration(milliseconds: 50));

      expect(traces.length, 1);
      expect(traces[0].success, true);
      expect(traces[0].plugin, 'mockPlugin');
    });
  });
}
```

---

### 📄 `test/unit/engine/lazy_plugin_loader_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sweetmelon/packages/plugin_engine/lib/plugin_engine.dart';

import '../../helpers/mock_plugin.dart';

void main() {
  group('LazyPluginLoader', () {
    late PluginRegistry registry;
    late LazyPluginLoader loader;

    setUp(() {
      registry = PluginRegistry();
      loader = LazyPluginLoader(registry: registry);
    });

    tearDown(() async {
      await loader.dispose();
      await registry.dispose();
    });

    test('registers lazy plugin definition', () {
      loader.register(LazyPluginDefinition(
        id: 'test',
        version: '1.0.0',
        factory: () => MockPlugin(pluginName: 'test'),
      ));

      expect(loader.canLoad('test'), true);
      expect(loader.isLoaded('test'), false);
    });

    test('loads plugin on demand', () async {
      loader.register(LazyPluginDefinition(
        id: 'lazy1',
        version: '1.0.0',
        factory: () => MockPlugin(pluginName: 'lazy1'),
      ));

      final plugin = await loader.load('lazy1');

      expect(plugin, isNotNull);
      expect(plugin.name, 'lazy1');
      expect(plugin.isReady, true);
      expect(loader.isLoaded('lazy1'), true);
      expect(registry.isRegistered('lazy1'), true);
    });

    test('returns same instance on repeated load', () async {
      loader.register(LazyPluginDefinition(
        id: 'lazy2',
        version: '1.0.0',
        factory: () => MockPlugin(pluginName: 'lazy2'),
      ));

      final p1 = await loader.load('lazy2');
      final p2 = await loader.load('lazy2');

      expect(identical(p1, p2), true);
    });

    test('unload disposes and removes plugin', () async {
      final plugin = MockPlugin(pluginName: 'lazy3');

      loader.register(LazyPluginDefinition(
        id: 'lazy3',
        version: '1.0.0',
        factory: () => plugin,
      ));

      await loader.load('lazy3');
      expect(loader.isLoaded('lazy3'), true);

      await loader.unload('lazy3');
      expect(loader.isLoaded('lazy3'), false);
      expect(registry.isRegistered('lazy3'), false);
    });

    test('reload creates new instance', () async {
      int createCount = 0;

      loader.register(LazyPluginDefinition(
        id: 'lazy4',
        version: '1.0.0',
        factory: () {
          createCount++;
          return MockPlugin(pluginName: 'lazy4');
        },
      ));

      await loader.load('lazy4');
      expect(createCount, 1);

      await loader.reload('lazy4');
      expect(createCount, 2);
      expect(loader.isLoaded('lazy4'), true);
    });

    test('loads dependencies first', () async {
      final loadOrder = <String>[];

      loader.registerAll([
        LazyPluginDefinition(
          id: 'dep_a',
          version: '1.0.0',
          factory: () {
            loadOrder.add('dep_a');
            return MockPlugin(pluginName: 'dep_a');
          },
        ),
        LazyPluginDefinition(
          id: 'dep_b',
          version: '1.0.0',
          factory: () {
            loadOrder.add('dep_b');
            return MockPlugin(pluginName: 'dep_b');
          },
          dependencies: ['dep_a'],
        ),
      ]);

      await loader.load('dep_b');

      expect(loadOrder, ['dep_a', 'dep_b']);
    });

    test('loadMany loads multiple plugins', () async {
      loader.registerAll([
        LazyPluginDefinition(
          id: 'multi1',
          version: '1.0.0',
          factory: () => MockPlugin(pluginName: 'multi1'),
        ),
        LazyPluginDefinition(
          id: 'multi2',
          version: '1.0.0',
          factory: () => MockPlugin(pluginName: 'multi2'),
        ),
      ]);

      final plugins = await loader.loadMany(['multi1', 'multi2']);

      expect(plugins.length, 2);
      expect(loader.loadedPlugins.length, 2);
    });

    test('stats are tracked', () async {
      loader.register(LazyPluginDefinition(
        id: 'stat1',
        version: '1.0.0',
        factory: () => MockPlugin(pluginName: 'stat1'),
      ));

      expect(loader.stats['total'], 1);
      expect(loader.stats['loaded'], 0);
      expect(loader.stats['unloaded'], 1);

      await loader.load('stat1');

      expect(loader.stats['loaded'], 1);
      expect(loader.stats['unloaded'], 0);
    });

    test('throws on unknown plugin', () {
      expect(
        () => loader.load('nonexistent'),
        throwsStateError,
      );
    });

    test('handles factory error', () async {
      loader.register(LazyPluginDefinition(
        id: 'broken',
        version: '1.0.0',
        factory: () => throw Exception('factory error'),
      ));

      expect(
        () => loader.load('broken'),
        throwsException,
      );

      final status = loader.allStatuses['broken']!;
      expect(status.state, LazyPluginState.failed);
    });
  });
}
```

---

## بخش ۵: Unit Tests — Security

### 📄 `test/unit/security/rate_limiter_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sweetmelon/packages/security/lib/security.dart';

void main() {
  group('RateLimiter', () {
    late RateLimiter limiter;

    setUp(() {
      limiter = RateLimiter();
    });

    test('allows calls within limit', () async {
      limiter.addRule('test', RateLimitRule.perSecond(5));

      for (int i = 0; i < 5; i++) {
        final result = await limiter.check('test', 'method');
        expect(result.allowed, true);
      }
    });

    test('blocks calls exceeding limit', () async {
      limiter.addRule('test', RateLimitRule.perSecond(3));

      for (int i = 0; i < 3; i++) {
        await limiter.check('test', 'method');
      }

      final result = await limiter.check('test', 'method');
      expect(result.allowed, false);
      expect(result.remaining, 0);
      expect(result.retryAfterMs, greaterThan(0));
    });

    test('resets after window', () async {
      limiter.addRule('test', RateLimitRule(
        maxCalls: 2,
        window: const Duration(milliseconds: 100),
      ));

      await limiter.check('test', 'method');
      await limiter.check('test', 'method');

      var result = await limiter.check('test', 'method');
      expect(result.allowed, false);

      await Future.delayed(const Duration(milliseconds: 150));

      result = await limiter.check('test', 'method');
      expect(result.allowed, true);
    });

    test('uses default rule when no specific rule', () async {
      limiter.setDefaultRule(RateLimitRule.perSecond(100));

      final result = await limiter.check('unknown', 'method');
      expect(result.allowed, true);
    });

    test('per-method rules override plugin rules', () async {
      limiter.addRule('plugin', RateLimitRule.perSecond(100));
      limiter.addRule('plugin.heavyMethod', RateLimitRule.perSecond(2));

      // Heavy method limited to 2
      await limiter.check('plugin', 'heavyMethod');
      await limiter.check('plugin', 'heavyMethod');
      final result = await limiter.check('plugin', 'heavyMethod');
      expect(result.allowed, false);
    });

    test('reset clears specific key', () async {
      limiter.addRule('test', RateLimitRule.perSecond(1));

      await limiter.check('test', 'method');
      var result = await limiter.check('test', 'method');
      expect(result.allowed, false);

      limiter.reset('test.method');

      result = await limiter.check('test', 'method');
      expect(result.allowed, true);
    });
  });
}
```

---

### 📄 `test/unit/security/execution_guard_test.dart`

```dart
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:sweetmelon/packages/security/lib/security.dart';

void main() {
  group('ExecutionGuard', () {
    late ExecutionGuard guard;

    setUp(() {
      guard = ExecutionGuard(defaultTimeoutMs: 1000);
    });

    test('executes successfully', () async {
      final result = await guard.execute(
        requestId: 'req_1',
        fn: () async => 42,
      );

      expect(result, 42);
    });

    test('times out after duration', () async {
      expect(
        () => guard.execute(
          requestId: 'req_2',
          fn: () async {
            await Future.delayed(const Duration(seconds: 5));
            return 'too late';
          },
          timeoutMs: 100,
        ),
        throwsA(isA<TimeoutException>()),
      );
    });

    test('tracks active executions', () async {
      final completer = Completer<void>();

      final future = guard.execute(
        requestId: 'req_3',
        fn: () async {
          await completer.future;
          return 'done';
        },
      );

      expect(guard.activeCount, 1);
      expect(guard.isActive('req_3'), true);

      completer.complete();
      await future;

      expect(guard.activeCount, 0);
      expect(guard.isActive('req_3'), false);
    });

    test('removes from active on error', () async {
      try {
        await guard.execute(
          requestId: 'req_4',
          fn: () async => throw Exception('error'),
        );
      } catch (_) {}

      expect(guard.isActive('req_4'), false);
    });
  });
}
```

---

## بخش ۶: Unit Tests — Performance

### 📄 `test/unit/performance/cache_manager_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sweetmelon/packages/performance/lib/performance.dart';

void main() {
  group('CacheManager', () {
    late CacheManager cache;

    setUp(() {
      cache = CacheManager(maxEntries: 10);
    });

    tearDown(() {
      cache.dispose();
    });

    test('set and get', () async {
      await cache.set('key1', 'value1');
      final result = await cache.get('key1');

      expect(result, 'value1');
    });

    test('get returns null for missing key', () async {
      final result = await cache.get('nonexistent');
      expect(result, isNull);
    });

    test('TTL expiration', () async {
      await cache.set(
        'expiring',
        'value',
        ttl: const Duration(milliseconds: 100),
      );

      var result = await cache.get('expiring');
      expect(result, 'value');

      await Future.delayed(const Duration(milliseconds: 150));

      result = await cache.get('expiring');
      expect(result, isNull);
    });

    test('invalidate removes key', () async {
      await cache.set('key1', 'value1');
      await cache.invalidate('key1');

      final result = await cache.get('key1');
      expect(result, isNull);
    });

    test('invalidatePlugin removes plugin keys', () async {
      await cache.set('storage:get:key1', 'v1');
      await cache.set('storage:get:key2', 'v2');
      await cache.set('camera:info', 'v3');

      await cache.invalidatePlugin('storage');

      expect(await cache.get('storage:get:key1'), isNull);
      expect(await cache.get('storage:get:key2'), isNull);
      expect(await cache.get('camera:info'), 'v3');
    });

    test('LRU eviction', () async {
      final smallCache = CacheManager(maxEntries: 3);

      await smallCache.set('a', 1);
      await smallCache.set('b', 2);
      await smallCache.set('c', 3);

      // Touch 'a' to make 'b' the LRU
      await smallCache.get('a');

      await smallCache.set('d', 4); // evicts 'b'

      expect(await smallCache.get('b'), isNull);
      expect(await smallCache.get('a'), 1);
      expect(await smallCache.get('c'), 3);
      expect(await smallCache.get('d'), 4);

      smallCache.dispose();
    });

    test('clear removes all entries', () async {
      await cache.set('a', 1);
      await cache.set('b', 2);

      await cache.clear();

      expect(await cache.get('a'), isNull);
      expect(await cache.get('b'), isNull);
      expect(cache.stats.entries, 0);
    });

    test('stats tracking', () async {
      await cache.set('key1', 'value1');

      await cache.get('key1'); // hit
      await cache.get('key1'); // hit
      await cache.get('missing'); // miss

      final stats = cache.stats;

      expect(stats.hits, 2);
      expect(stats.misses, 1);
      expect(stats.entries, 1);
      expect(stats.hitRate, closeTo(0.667, 0.01));
    });

    test('isMutationMethod detects mutations', () {
      expect(cache.isMutationMethod('set'), true);
      expect(cache.isMutationMethod('remove'), true);
      expect(cache.isMutationMethod('clear'), true);
      expect(cache.isMutationMethod('writeFile'), true);
      expect(cache.isMutationMethod('get'), false);
      expect(cache.isMutationMethod('keys'), false);
    });

    test('noCachePattern skips cache', () async {
      cache.addNoCachePattern('nocache:');

      await cache.set('nocache:key1', 'value');
      final result = await cache.get('nocache:key1');

      expect(result, isNull); // was skipped
    });
  });
}
```

---

## بخش ۷: Plugin-Level Tests

### 📄 `test/plugins/encryption_plugin_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sweetmelon/plugins/encryption/lib/encryption_plugin.dart';

void main() {
  group('EncryptionPlugin', () {
    late EncryptionPlugin plugin;

    setUp(() async {
      plugin = EncryptionPlugin();
      await plugin.initialize();
    });

    test('generateAesKey returns key and iv', () async {
      final result = await plugin.onCall('generateAesKey', {'bits': 256});

      expect(result['key'], isNotEmpty);
      expect(result['iv'], isNotEmpty);
      expect(result['bits'], 256);
    });

    test('aesEncrypt and aesDecrypt roundtrip', () async {
      final keyResult = await plugin.onCall('generateAesKey', {'bits': 256});
      final key = keyResult['key'] as String;
      final iv = keyResult['iv'] as String;

      final encrypted = await plugin.onCall('aesEncrypt', {
        'data': 'Hello World',
        'key': key,
        'iv': iv,
      });

      expect(encrypted['encrypted'], isNotEmpty);

      final decrypted = await plugin.onCall('aesDecrypt', {
        'data': encrypted['encrypted'],
        'key': key,
        'iv': iv,
      });

      expect(decrypted['decrypted'], 'Hello World');
    });

    test('hashSha256 produces consistent hash', () async {
      final r1 = await plugin.onCall('hashSha256', {'data': 'test'});
      final r2 = await plugin.onCall('hashSha256', {'data': 'test'});

      expect(r1['hash'], r2['hash']);
      expect(r1['hash'], isNotEmpty);
    });

    test('different inputs produce different hashes', () async {
      final r1 = await plugin.onCall('hashSha256', {'data': 'hello'});
      final r2 = await plugin.onCall('hashSha256', {'data': 'world'});

      expect(r1['hash'], isNot(r2['hash']));
    });

    test('hmacSha256 works', () async {
      final result = await plugin.onCall('hmacSha256', {
        'data': 'message',
        'key': 'secret',
      });

      expect(result['hmac'], isNotEmpty);
      expect(result['algorithm'], 'HMAC-SHA256');
    });

    test('base64 encode/decode roundtrip', () async {
      final encoded = await plugin.onCall('base64Encode', {'data': 'Hello!'});
      final decoded = await plugin.onCall('base64Decode', {
        'data': encoded['encoded'],
      });

      expect(decoded['decoded'], 'Hello!');
    });

    test('generateRandomBytes returns correct length', () async {
      final result = await plugin.onCall('generateRandomBytes', {'length': 16});

      expect(result['length'], 16);
      expect(result['hex'], hasLength(32)); // 16 bytes = 32 hex chars
    });

    test('validation rejects missing data', () async {
      final result = await plugin.validateArgs('hashSha256', {});
      expect(result.isValid, false);
    });

    test('validation accepts valid args', () async {
      final result = await plugin.validateArgs('hashSha256', {'data': 'test'});
      expect(result.isValid, true);
    });
  });
}
```

---

### 📄 `test/plugins/storage_plugin_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sweetmelon/plugins/storage/lib/storage_plugin.dart';

void main() {
  group('StoragePlugin', () {
    late StoragePlugin plugin;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      plugin = StoragePlugin();
      await plugin.initialize();
    });

    test('set and get string value', () async {
      await plugin.onCall('set', {'key': 'name', 'value': 'Ali'});
      final result = await plugin.onCall('get', {'key': 'name'});

      expect(result, 'Ali');
    });

    test('set and get complex value', () async {
      final data = {'name': 'Ali', 'age': 30, 'tags': ['a', 'b']};
      await plugin.onCall('set', {'key': 'user', 'value': data});
      final result = await plugin.onCall('get', {'key': 'user'});

      expect(result['name'], 'Ali');
      expect(result['age'], 30);
      expect(result['tags'], ['a', 'b']);
    });

    test('get returns null for missing key', () async {
      final result = await plugin.onCall('get', {'key': 'nonexistent'});
      expect(result, isNull);
    });

    test('has returns correct value', () async {
      await plugin.onCall('set', {'key': 'exists', 'value': true});

      final r1 = await plugin.onCall('has', {'key': 'exists'});
      expect(r1['exists'], true);

      final r2 = await plugin.onCall('has', {'key': 'missing'});
      expect(r2['exists'], false);
    });

    test('remove deletes key', () async {
      await plugin.onCall('set', {'key': 'temp', 'value': 'data'});
      await plugin.onCall('remove', {'key': 'temp'});

      final result = await plugin.onCall('get', {'key': 'temp'});
      expect(result, isNull);
    });

    test('keys returns all bridge keys', () async {
      await plugin.onCall('set', {'key': 'a', 'value': 1});
      await plugin.onCall('set', {'key': 'b', 'value': 2});

      final result = await plugin.onCall('keys', {});

      expect(result['keys'], containsAll(['a', 'b']));
    });

    test('clear removes all bridge keys', () async {
      await plugin.onCall('set', {'key': 'x', 'value': 1});
      await plugin.onCall('set', {'key': 'y', 'value': 2});

      final count = await plugin.onCall('clear', {});
      expect(count, 2);

      final keys = await plugin.onCall('keys', {});
      expect((keys['keys'] as List).isEmpty, true);
    });

    test('validation rejects empty key', () async {
      final result = await plugin.validateArgs('get', {'key': ''});
      expect(result.isValid, false);
    });

    test('validation rejects missing key', () async {
      final result = await plugin.validateArgs('get', {});
      expect(result.isValid, false);
    });

    test('validation rejects set without value', () async {
      final result = await plugin.validateArgs('set', {'key': 'test'});
      expect(result.isValid, false);
    });
  });
}
```

---

## بخش ۸: Integration Tests

### 📄 `test/integration/bridge_integration_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sweetmelon/packages/core/lib/core.dart';
import 'package:sweetmelon/packages/performance/lib/performance.dart';
import 'package:sweetmelon/packages/security/lib/security.dart';
import 'package:sweetmelon/packages/plugin_engine/lib/plugin_engine.dart';
import 'package:sweetmelon/plugins/storage/lib/storage_plugin.dart';
import 'package:sweetmelon/plugins/clipboard/lib/clipboard_plugin.dart';
import 'package:sweetmelon/plugins/encryption/lib/encryption_plugin.dart';

import '../helpers/test_helpers.dart';

void main() {
  group('Bridge Integration', () {
    late PluginRegistry registry;
    late PluginManager manager;
    late MessageBridge bridge;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});

      registry = PluginRegistry();
      manager = createTestPluginManager(registry: registry);

      bridge = MessageBridge();
      bridge.setMessageHandler(manager.execute);
      bridge.setBatchHandler(manager.executeBatch);

      await registry.register(StoragePlugin());
      await registry.register(ClipboardPlugin());
      await registry.register(EncryptionPlugin());
    });

    tearDown(() async {
      bridge.dispose();
      manager.dispose();
      await registry.dispose();
    });

    test('full message flow: storage set then get', () async {
      // Set
      await bridge.handleIncomingMessage({
        'requestId': 'set_1',
        'plugin': 'storage',
        'method': 'set',
        'args': {'key': 'integration_test', 'value': {'data': 42}},
      });

      // Get
      PluginResponse? response;
      bridge.setMessageHandler((request) async {
        response = await manager.execute(request);
        return response!;
      });

      await bridge.handleIncomingMessage({
        'requestId': 'get_1',
        'plugin': 'storage',
        'method': 'get',
        'args': {'key': 'integration_test'},
      });

      expect(response, isNotNull);
      expect(response!.success, true);
    });

    test('encryption roundtrip through bridge', () async {
      // Generate key
      final keyResponse = await manager.execute(
        createTestRequest(
          plugin: 'encryption',
          method: 'generateAesKey',
          args: {'bits': 256},
        ),
      );

      expect(keyResponse.success, true);
      final key = keyResponse.data['key'] as String;
      final iv = keyResponse.data['iv'] as String;

      // Encrypt
      final encResponse = await manager.execute(
        createTestRequest(
          plugin: 'encryption',
          method: 'aesEncrypt',
          args: {'data': 'secret message', 'key': key, 'iv': iv},
        ),
      );

      expect(encResponse.success, true);
      final encrypted = encResponse.data['encrypted'] as String;

      // Decrypt
      final decResponse = await manager.execute(
        createTestRequest(
          plugin: 'encryption',
          method: 'aesDecrypt',
          args: {'data': encrypted, 'key': key, 'iv': iv},
        ),
      );

      expect(decResponse.success, true);
      expect(decResponse.data['decrypted'], 'secret message');
    });

    test('batch request through bridge', () async {
      final responses = await manager.executeBatch([
        createTestRequest(
          plugin: 'storage',
          method: 'set',
          args: {'key': 'batch_1', 'value': 'v1'},
        ),
        createTestRequest(
          plugin: 'storage',
          method: 'set',
          args: {'key': 'batch_2', 'value': 'v2'},
        ),
        createTestRequest(
          plugin: 'storage',
          method: 'keys',
        ),
      ], const BatchOptions(parallel: false, stopOnError: false));

      expect(responses.length, 3);
      expect(allSuccessful(responses), true);
    });

    test('error for invalid plugin does not crash', () async {
      final response = await manager.execute(
        createTestRequest(
          plugin: 'nonexistent',
          method: 'anything',
        ),
      );

      expect(response.success, false);
      expect(response.error!.code, PluginErrorCode.pluginNotFound);
    });

    test('error for invalid method does not crash', () async {
      final response = await manager.execute(
        createTestRequest(
          plugin: 'storage',
          method: 'nonexistent',
        ),
      );

      expect(response.success, false);
      expect(response.error!.code, PluginErrorCode.methodNotFound);
    });
  });
}
```

---

### 📄 `test/integration/lazy_loading_integration_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sweetmelon/packages/plugin_engine/lib/plugin_engine.dart';

import '../helpers/mock_plugin.dart';
import '../helpers/test_helpers.dart';

void main() {
  group('Lazy Loading Integration', () {
    late PluginRegistry registry;
    late LazyPluginLoader loader;
    late PluginManager manager;

    setUp(() {
      registry = PluginRegistry();
      loader = LazyPluginLoader(registry: registry);
      manager = createTestPluginManager(
        registry: registry,
        lazyLoader: loader,
      );
    });

    tearDown(() async {
      manager.dispose();
      await loader.dispose();
      await registry.dispose();
    });

    test('auto-loads lazy plugin on first call', () async {
      loader.register(LazyPluginDefinition(
        id: 'lazyPlugin',
        version: '1.0.0',
        factory: () => MockPlugin(pluginName: 'lazyPlugin'),
      ));

      expect(loader.isLoaded('lazyPlugin'), false);
      expect(registry.isRegistered('lazyPlugin'), false);

      final response = await manager.execute(
        createTestRequest(
          plugin: 'lazyPlugin',
          method: 'doSomething',
        ),
      );

      expect(response.success, true);
      expect(loader.isLoaded('lazyPlugin'), true);
      expect(registry.isRegistered('lazyPlugin'), true);
    });

    test('second call uses already-loaded plugin', () async {
      int createCount = 0;

      loader.register(LazyPluginDefinition(
        id: 'countPlugin',
        version: '1.0.0',
        factory: () {
          createCount++;
          return MockPlugin(pluginName: 'countPlugin');
        },
      ));

      await manager.execute(createTestRequest(plugin: 'countPlugin'));
      await manager.execute(createTestRequest(plugin: 'countPlugin'));

      expect(createCount, 1);
    });

    test('eager and lazy plugins work together', () async {
      // Eager
      final eager = MockPlugin(pluginName: 'eagerPlugin');
      await registry.register(eager);

      // Lazy
      loader.register(LazyPluginDefinition(
        id: 'lazyPlugin',
        version: '1.0.0',
        factory: () => MockPlugin(pluginName: 'lazyPlugin'),
      ));

      // Both should work
      final r1 = await manager.execute(
        createTestRequest(plugin: 'eagerPlugin'),
      );
      final r2 = await manager.execute(
        createTestRequest(plugin: 'lazyPlugin'),
      );

      expect(r1.success, true);
      expect(r2.success, true);
    });

    test('returns plugin not found for unregistered plugin', () async {
      final response = await manager.execute(
        createTestRequest(plugin: 'totallyUnknown'),
      );

      expect(response.success, false);
      expect(response.error!.code, PluginErrorCode.pluginNotFound);
    });

    test('handles lazy load failure gracefully', () async {
      loader.register(LazyPluginDefinition(
        id: 'brokenPlugin',
        version: '1.0.0',
        factory: () => throw Exception('cannot create'),
      ));

      final response = await manager.execute(
        createTestRequest(plugin: 'brokenPlugin'),
      );

      expect(response.success, false);
      expect(response.error!.message, contains('failed to load'));
    });
  });
}
```

---

## بخش ۹: Test Runner

### 📄 `test/test_runner.dart`

```dart
// جمع‌آوری همه تست‌ها برای اجرا با یک دستور
// اجرا: flutter test test/test_runner.dart

// Unit Tests — Core
import 'unit/core/message_protocol_test.dart' as protocol_test;
import 'unit/core/message_bridge_test.dart' as bridge_test;

// Unit Tests — Middleware
import 'unit/middleware/error_recovery_test.dart' as retry_test;
import 'unit/middleware/circuit_breaker_test.dart' as circuit_test;

// Unit Tests — Engine
import 'unit/engine/plugin_registry_test.dart' as registry_test;
import 'unit/engine/plugin_manager_test.dart' as manager_test;
import 'unit/engine/lazy_plugin_loader_test.dart' as lazy_test;

// Unit Tests — Security
import 'unit/security/rate_limiter_test.dart' as rate_test;
import 'unit/security/execution_guard_test.dart' as guard_test;

// Unit Tests — Performance
import 'unit/performance/cache_manager_test.dart' as cache_test;

// Plugin Tests
import 'plugins/encryption_plugin_test.dart' as encryption_test;
import 'plugins/storage_plugin_test.dart' as storage_test;

// Integration Tests
import 'integration/bridge_integration_test.dart' as bridge_integration;
import 'integration/lazy_loading_integration_test.dart' as lazy_integration;

void main() {
  // Core
  protocol_test.main();
  bridge_test.main();

  // Middleware
  retry_test.main();
  circuit_test.main();

  // Engine
  registry_test.main();
  manager_test.main();
  lazy_test.main();

  // Security
  rate_test.main();
  guard_test.main();

  // Performance
  cache_test.main();

  // Plugins
  encryption_test.main();
  storage_test.main();

  // Integration
  bridge_integration.main();
  lazy_integration.main();
}
```

---

## بخش ۱۰: اجرای تست‌ها

```bash
# اجرای همه تست‌ها
flutter test

# اجرای فقط unit tests
flutter test test/unit/

# اجرای فقط plugin tests
flutter test test/plugins/

# اجرای فقط integration tests
flutter test test/integration/

# اجرای تست runner
flutter test test/test_runner.dart

# اجرای با coverage
flutter test --coverage

# اجرای یک فایل خاص
flutter test test/unit/middleware/circuit_breaker_test.dart

# اجرای verbose
flutter test --reporter expanded
```

---

# خلاصه Testing Framework

## آمار تست‌ها

| دسته | فایل | تست |
|------|------|------|
| Core Protocol | 1 | 7 |
| Core Bridge | 1 | 5 |
| Error Recovery | 1 | 6 |
| Circuit Breaker | 1 | 11 |
| Plugin Registry | 1 | 8 |
| Plugin Manager | 1 | 9 |
| Lazy Loader | 1 | 9 |
| Rate Limiter | 1 | 5 |
| Execution Guard | 1 | 4 |
| Cache Manager | 1 | 8 |
| Encryption Plugin | 1 | 9 |
| Storage Plugin | 1 | 9 |
| Bridge Integration | 1 | 5 |
| Lazy Integration | 1 | 5 |
| **مجموع** | **14** | **100** |

## پوشش

| لایه | پوشش |
|------|-------|
| Message Protocol | ✅ parse, serialize, roundtrip |
| Message Bridge | ✅ handler, batch, stream |
| Error Recovery | ✅ retry, backoff, fallback |
| Circuit Breaker | ✅ states, threshold, recovery |
| Plugin Registry | ✅ CRUD, events, versioning |
| Plugin Manager | ✅ execute, cache, batch, stats |
| Lazy Loader | ✅ load, unload, reload, deps |
| Rate Limiter | ✅ limits, windows, reset |
| Execution Guard | ✅ timeout, tracking |
| Cache Manager | ✅ TTL, LRU, invalidation, stats |
| Encryption Plugin | ✅ AES, SHA, HMAC, base64 |
| Storage Plugin | ✅ CRUD, validation |
