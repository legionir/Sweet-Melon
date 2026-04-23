import 'package:flutter_test/flutter_test.dart';
import '../packages/plugin_engine/lib/src/plugin_interface.dart';
import '../packages/plugin_engine/lib/src/plugin_registry.dart';
import '../packages/plugin_engine/lib/src/plugin_manager.dart';
import '../packages/security/lib/src/permission_manager.dart';
import '../packages/security/lib/src/rate_limiter.dart';
import '../packages/security/lib/src/execution_guard.dart';
import '../packages/performance/lib/src/cache_manager.dart';
import '../packages/core/lib/src/protocol/message_protocol.dart';

// ── Mock Plugin ─────────────────────────────────────────────

class MockPlugin extends Plugin {
  final String _name;
  final String _version;
  final Map<String, dynamic> Function(String, Map<String, dynamic>) _handler;

  MockPlugin({
    String name = 'mock',
    String version = '1.0.0',
    required Map<String, dynamic> Function(String, Map<String, dynamic>) handler,
  })  : _name = name,
        _version = version,
        _handler = handler;

  @override
  String get name => _name;

  @override
  String get version => _version;

  @override
  List<String> get supportedMethods => ['testMethod', 'slowMethod'];

  @override
  Future<dynamic> onCall(String method, Map<String, dynamic> args) async {
    if (method == 'slowMethod') {
      await Future.delayed(const Duration(seconds: 2));
    }
    return _handler(method, args);
  }
}

// ── Test Suite ───────────────────────────────────────────────

void main() {
  late PluginRegistry registry;
  late PluginManager manager;
  late MockPlugin mockPlugin;

  setUp(() async {
    registry = PluginRegistry();
    
    mockPlugin = MockPlugin(
      handler: (method, args) => {'method': method, 'args': args},
    );

    manager = PluginManager(
      registry: registry,
      permissionManager: PermissionManager(),
      rateLimiter: RateLimiter(),
      executionGuard: ExecutionGuard(defaultTimeoutMs: 5000),
      cacheManager: CacheManager(),
    );

    await registry.register(mockPlugin);
  });

  tearDown(() async {
    await registry.dispose();
    manager.dispose();
  });

  // ────────────────────────────────────────────────────────────

  group('Plugin Registration', () {
    test('should register plugin', () {
      expect(registry.isRegistered('mock'), isTrue);
    });

    test('should resolve latest version', () {
      final plugin = registry.resolve('mock');
      expect(plugin, isNotNull);
      expect(plugin!.name, equals('mock'));
    });

    test('should return null for unknown plugin', () {
      final plugin = registry.resolve('nonexistent');
      expect(plugin, isNull);
    });

    test('should register multiple versions', () async {
      final v2 = MockPlugin(
        name: 'mock',
        version: '2.0.0',
        handler: (m, a) => {'v': '2.0.0'},
      );
      
      await registry.register(v2);
      
      final plugin = registry.resolve('mock');
      expect(plugin!.version, equals('2.0.0'));
    });
  });

  group('Plugin Execution', () {
    test('should execute successfully', () async {
      final request = PluginRequest.create(
        plugin: 'mock',
        method: 'testMethod',
        args: {'key': 'value'},
      );

      final response = await manager.execute(request);
      
      expect(response.success, isTrue);
      expect(response.data['method'], equals('testMethod'));
    });

    test('should return error for unknown plugin', () async {
      final request = PluginRequest.create(
        plugin: 'unknown',
        method: 'test',
      );

      final response = await manager.execute(request);
      
      expect(response.success, isFalse);
      expect(
        response.error!.code,
        equals(PluginErrorCode.pluginNotFound),
      );
    });

    test('should return error for unknown method', () async {
      final request = PluginRequest.create(
        plugin: 'mock',
        method: 'nonExistentMethod',
      );

      final response = await manager.execute(request);
      
      expect(response.success, isFalse);
      expect(
        response.error!.code,
        equals(PluginErrorCode.methodNotFound),
      );
    });

    test('should include processing time in metadata', () async {
      final request = PluginRequest.create(
        plugin: 'mock',
        method: 'testMethod',
      );

      final response = await manager.execute(request);
      
      expect(response.metadata.processingTimeMs, greaterThanOrEqualTo(0));
    });
  });

  group('Rate Limiting', () {
    test('should enforce rate limits', () async {
      final limiter = RateLimiter();
      limiter.addRule('mock.testMethod', RateLimitRule.perSecond(2));
      
      final restrictedManager = PluginManager(
        registry: registry,
        permissionManager: PermissionManager(),
        rateLimiter: limiter,
        executionGuard: ExecutionGuard(),
        cacheManager: CacheManager(),
      );

      // 2 calls باید موفق باشند
      final r1 = await restrictedManager.execute(
        PluginRequest.create(plugin: 'mock', method: 'testMethod'),
      );
      final r2 = await restrictedManager.execute(
        PluginRequest.create(plugin: 'mock', method: 'testMethod'),
      );
      
      // سومی باید block شود
      final r3 = await restrictedManager.execute(
        PluginRequest.create(plugin: 'mock', method: 'testMethod'),
      );

      expect(r1.success, isTrue);
      expect(r2.success, isTrue);
      expect(r3.success, isFalse);
      expect(
        r3.error!.code,
        equals(PluginErrorCode.rateLimitExceeded),
      );
      
      restrictedManager.dispose();
    });
  });

  group('Cache', () {
    test('should cache results', () async {
      final cache = CacheManager();
      
      await cache.set('test_key', {'cached': true});
      final result = await cache.get('test_key');
      
      expect(result, isNotNull);
      expect(result['cached'], isTrue);
    });

    test('should expire cached entries', () async {
      final cache = CacheManager();
      
      await cache.set(
        'test_key',
        {'cached': true},
        ttl: const Duration(milliseconds: 100),
      );
      
      await Future.delayed(const Duration(milliseconds: 200));
      
      final result = await cache.get('test_key');
      expect(result, isNull);
    });
  });

  group('Batch Execution', () {
    test('should execute batch in parallel', () async {
      final requests = List.generate(
        3,
        (i) => PluginRequest.create(
          plugin: 'mock',
          method: 'testMethod',
          args: {'index': i},
        ),
      );

      final responses = await manager.executeBatch(
        requests,
        BatchOptions.defaults(),
      );

      expect(responses.length, equals(3));
      expect(responses.every((r) => r.success), isTrue);
    });

    test('should stop on error when configured', () async {
      final failPlugin = MockPlugin(
        name: 'failing',
        handler: (m, a) => throw Exception('Always fails'),
      );
      
      await registry.register(failPlugin);

      final requests = [
        PluginRequest.create(plugin: 'failing', method: 'testMethod'),
        PluginRequest.create(plugin: 'mock', method: 'testMethod'),
      ];

      final responses = await manager.executeBatch(
        requests,
        BatchOptions(parallel: false, stopOnError: true),
      );

      // فقط اولی اجرا شده
      expect(responses.length, equals(1));
    });
  });

  group('Protocol Serialization', () {
    test('should serialize/deserialize request', () {
      final original = PluginRequest.create(
        plugin: 'camera',
        method: 'takePhoto',
        args: {'quality': 80},
      );

      final json = original.toJson();
      final restored = PluginRequest.fromJson(json);

      expect(restored.plugin, equals(original.plugin));
      expect(restored.method, equals(original.method));
      expect(restored.requestId, equals(original.requestId));
      expect(restored.args['quality'], equals(80));
    });

    test('should serialize/deserialize response', () {
      final original = PluginResponse.success(
        requestId: 'test-id',
        data: {'path': '/photo.jpg'},
      );

      final json = original.toJson();
      final restored = PluginResponse.fromJson(json);

      expect(restored.requestId, equals('test-id'));
      expect(restored.success, isTrue);
      expect(restored.data['path'], equals('/photo.jpg'));
    });

    test('should handle error response', () {
      final response = PluginResponse.failure(
        requestId: 'test-id',
        error: const PluginError(
          code: PluginErrorCode.permissionDenied,
          message: 'Camera permission denied',
        ),
      );

      expect(response.success, isFalse);
      expect(response.error!.code, equals(PluginErrorCode.permissionDenied));
    });
  });
}
