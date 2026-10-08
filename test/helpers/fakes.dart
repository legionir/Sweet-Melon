import 'dart:async';

import 'package:sweetmelon/packages/core/lib/src/protocol/message_protocol.dart';
import 'package:sweetmelon/packages/performance/lib/performance.dart';
import 'package:sweetmelon/packages/plugin_engine/lib/plugin_engine.dart';
import 'package:sweetmelon/packages/security/lib/security.dart';

/// Builds a validated request exactly as the bridge would.
PluginRequest buildRequest({
  String requestId = 'req_1',
  String plugin = 'fake',
  String method = 'echo',
  Map<String, dynamic> args = const {},
}) {
  return PluginRequest.fromJson({
    'requestId': requestId,
    'plugin': plugin,
    'method': method,
    'args': args,
    'metadata': {'headers': <String, String>{}},
  });
}

typedef CallImpl = Future<dynamic> Function(
  String method,
  Map<String, dynamic> args,
);

/// Configurable plugin used by engine tests.
class FakePlugin extends Plugin {
  final String _name;
  final CallImpl _impl;
  final Set<String> _cacheable;
  final List<String> _permissions;
  final PluginCapabilities _caps;
  final Set<String> _streaming;
  final Future<ValidationResult> Function(
    String method,
    Map<String, dynamic> args,
  )? _validator;

  int calls = 0;

  FakePlugin({
    String name = 'fake',
    CallImpl? impl,
    Set<String> cacheable = const {},
    List<String> permissions = const [],
    PluginCapabilities? capabilities,
    Set<String> streaming = const {},
    Future<ValidationResult> Function(String, Map<String, dynamic>)? validator,
    List<String> methods = const ['echo', 'set', 'get', 'watch', 'boom'],
  })  : _name = name,
        _impl = impl ?? ((m, a) async => {'method': m, 'args': a}),
        _cacheable = cacheable,
        _permissions = permissions,
        _caps = capabilities ??
            const PluginCapabilities(
              supportsStreaming: true,
              supportsBatch: true,
              supportsCache: true,
              maxConcurrentCalls: 8,
            ),
        _streaming = streaming,
        _validator = validator,
        _methods = methods;

  final List<String> _methods;

  @override
  String get name => _name;

  @override
  String get version => '0.0.1-test';

  @override
  List<String> get supportedMethods => _methods;

  @override
  List<String> get requiredPermissions => _permissions;

  @override
  PluginCapabilities get capabilities => _caps;

  @override
  Set<String> get cacheableMethods => _cacheable;

  @override
  Set<String> get streamingMethods => _streaming;

  @override
  Duration get defaultCacheTtl => const Duration(seconds: 30);

  @override
  Future<dynamic> onCall(String method, Map<String, dynamic> args) {
    calls++;
    return _impl(method, args);
  }

  @override
  Future<ValidationResult> validateArgs(
    String method,
    Map<String, dynamic> args,
  ) {
    final validator = _validator;
    if (validator == null) return super.validateArgs(method, args);
    return validator(method, args);
  }
}

/// Permission provider with a fixed answer per permission.
class FakePermissionProvider implements PermissionProvider {
  final Map<String, PermissionState> states;
  int statusCalls = 0;

  FakePermissionProvider([Map<String, PermissionState>? states])
      : states = states ?? {};

  @override
  Future<PermissionState> status(String permission) async {
    statusCalls++;
    return states[permission] ?? PermissionState.denied;
  }

  @override
  Future<PermissionState> request(String permission) async {
    return states[permission] = PermissionState.granted;
  }
}

/// Clock whose time is controlled by the test.
class FakeClock {
  DateTime now;
  FakeClock([DateTime? start]) : now = start ?? DateTime(2026, 10, 8);

  DateTime call() => now;
  int millis() => now.millisecondsSinceEpoch;

  void advance(Duration by) => now = now.add(by);
}

/// Records every script the bridge asks the WebView to run.
class RecordingExecutor {
  final List<String> scripts = [];
  Completer<void>? gate;

  Future<void> call(String script) async {
    final g = gate;
    if (g != null) await g.future;
    scripts.add(script);
  }
}

/// Builds a PluginManager around the given plugins with generous limits so
/// that individual tests can focus on one behaviour.
class EngineHarness {
  final PluginRegistry registry;
  final PermissionManager permissions;
  final RateLimiter rateLimiter;
  final ExecutionGuard guard;
  final CacheManager cache;
  final PluginManager manager;

  EngineHarness._({
    required this.registry,
    required this.permissions,
    required this.rateLimiter,
    required this.guard,
    required this.cache,
    required this.manager,
  });

  static Future<EngineHarness> create({
    required List<Plugin> plugins,
    Map<String, PermissionState> grants = const {},
    Duration timeout = const Duration(seconds: 2),
    RateLimiter? rateLimiter,
    CacheManager? cache,
    FakeClock? clock,
  }) async {
    final registry = PluginRegistry();
    for (final p in plugins) {
      await registry.register(p);
    }
    final permissions = PermissionManager(
      provider: FakePermissionProvider(grants),
      now: clock?.call,
    );
    final limiter = rateLimiter ??
        RateLimiter(
          defaultRule: const RateLimitRule.perSecond(100000),
          clock: clock?.millis,
        );
    final guard = ExecutionGuard();
    final cacheManager =
        cache ?? CacheManager(maxEntries: 50, now: clock?.call);
    final manager = PluginManager(
      registry: registry,
      permissionManager: permissions,
      rateLimiter: limiter,
      executionGuard: guard,
      cacheManager: cacheManager,
      config: PluginManagerConfig(timeout: timeout),
    );
    return EngineHarness._(
      registry: registry,
      permissions: permissions,
      rateLimiter: limiter,
      guard: guard,
      cache: cacheManager,
      manager: manager,
    );
  }
}
