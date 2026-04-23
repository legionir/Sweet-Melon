import 'package:flutter_test/flutter_test.dart';
import '../packages/plugin_engine/lib/src/plugin_interface.dart';
import '../packages/plugin_engine/lib/src/plugin_registry.dart';
import '../packages/plugin_engine/lib/src/plugin_manager.dart';
import '../packages/security/lib/src/permission_manager.dart';
import '../packages/security/lib/src/rate_limiter.dart';
import '../packages/security/lib/src/execution_guard.dart';
import '../packages/performance/lib/src/cache_manager.dart';
import '../packages/core/lib/src/protocol/message_protocol.dart';

class LifecycleProbePlugin extends Plugin {
  bool initialized = false;
  bool disposed = false;

  @override
  String get name => 'lifecycle_probe';

  @override
  String get version => '1.0.0';

  @override
  List<String> get supportedMethods => ['ping'];

  @override
  Future<void> onInitialize() async {
    initialized = true;
  }

  @override
  Future<void> onDispose() async {
    disposed = true;
  }

  @override
  Future<dynamic> onCall(String method, Map<String, dynamic> args) async {
    return {'ok': true};
  }
}

class CountingPlugin extends Plugin {
  int calls = 0;

  @override
  String get name => 'counting';

  @override
  String get version => '1.0.0';

  @override
  List<String> get supportedMethods => ['sum'];

  @override
  Future<dynamic> onCall(String method, Map<String, dynamic> args) async {
    calls++;
    final a = args['a'] as int;
    final b = args['b'] as int;
    return {'result': a + b};
  }
}

void main() {
  group('Integration: lifecycle + cache behavior', () {
    test('registry.dispose should dispose registered plugins', () async {
      final registry = PluginRegistry();
      final plugin = LifecycleProbePlugin();

      await registry.register(plugin);
      expect(plugin.initialized, isTrue);
      expect(plugin.disposed, isFalse);

      await registry.dispose();
      expect(plugin.disposed, isTrue);
      expect(registry.registeredPlugins, isEmpty);
    });

    test('manager cache key should be deterministic for map key order', () async {
      final registry = PluginRegistry();
      final plugin = CountingPlugin();
      await registry.register(plugin);

      final manager = PluginManager(
        registry: registry,
        permissionManager: PermissionManager(),
        rateLimiter: RateLimiter(),
        executionGuard: ExecutionGuard(defaultTimeoutMs: 3000),
        cacheManager: CacheManager(),
      );

      final r1 = await manager.execute(
        PluginRequest.create(
          plugin: 'counting',
          method: 'sum',
          args: {'a': 1, 'b': 2},
        ),
      );

      final r2 = await manager.execute(
        PluginRequest.create(
          plugin: 'counting',
          method: 'sum',
          args: {'b': 2, 'a': 1},
        ),
      );

      expect(r1.success, isTrue);
      expect(r2.success, isTrue);
      expect(r1.data['result'], equals(3));
      expect(r2.data['result'], equals(3));
      expect(plugin.calls, equals(1));
      expect(r2.metadata.fromCache, isTrue);

      manager.dispose();
      await registry.dispose();
    });
  });
}
