import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:sweetmelon/packages/core/lib/src/protocol/message_protocol.dart';
import 'package:sweetmelon/packages/plugin_engine/lib/plugin_engine.dart';
import 'package:sweetmelon/packages/security/lib/security.dart';

import '../helpers/fakes.dart';

const _allowAll = {
  'location': PermissionState.granted,
  'camera': PermissionState.granted,
  'storage': PermissionState.granted,
};

void main() {
  group('pipeline', () {
    test('successful call returns data and records stats', () async {
      final h = await EngineHarness.create(
        plugins: [FakePlugin()],
        grants: _allowAll,
      );
      final response = await h.manager.execute(buildRequest(args: {'x': 1}));
      expect(response.success, isTrue);
      expect(response.data, {
        'method': 'echo',
        'args': {'x': 1}
      });
      final stats = h.manager.stats['fake.echo']!;
      expect(stats.totalCalls, 1);
      expect(stats.errorCount, 0);
    });

    test(
        'unknown plugin yields PLUGIN_NOT_FOUND and creates no limiter state (SEC-008)',
        () async {
      final h = await EngineHarness.create(plugins: [FakePlugin()]);
      for (var i = 0; i < 20; i++) {
        final r = await h.manager.execute(
          buildRequest(requestId: 'r$i', plugin: 'unknown$i'),
        );
        expect(r.error!.code, PluginErrorCode.pluginNotFound);
      }
      expect(h.rateLimiter.trackedKeys, 0);
      expect(h.manager.stats, isEmpty);
    });

    test('unknown method yields METHOD_NOT_FOUND and counts an error (SM-005)',
        () async {
      final h = await EngineHarness.create(plugins: [FakePlugin()]);
      final r = await h.manager.execute(buildRequest(method: 'nope'));
      expect(r.error!.code, PluginErrorCode.methodNotFound);
      expect(h.manager.stats['fake.nope']!.errorCount, 1);
    });

    test('missing permission yields PERMISSION_DENIED before the plugin runs',
        () async {
      final plugin = FakePlugin(permissions: ['camera']);
      final h = await EngineHarness.create(plugins: [plugin]);
      final r = await h.manager.execute(buildRequest());
      expect(r.error!.code, PluginErrorCode.permissionDenied);
      expect(plugin.calls, 0);
      expect(h.manager.stats['fake.echo']!.errorCount, 1);
    });

    // PERM-001: the denial carries the status so JS can choose its next step.
    test('permission denial reports the permission and its status (PERM-001)',
        () async {
      final plugin = FakePlugin(permissions: ['camera']);
      final h = await EngineHarness.create(
        plugins: [plugin],
        grants: {'camera': PermissionState.permanentlyDenied},
      );
      final r = await h.manager.execute(buildRequest());
      expect(r.error!.details, {
        'permission': 'camera',
        'status': 'permanentlyDenied',
      });
    });

    test('activeCalls returns to zero when the manager is idle (STAT-001)',
        () async {
      final h = await EngineHarness.create(plugins: [FakePlugin()]);
      expect(h.manager.activeCalls, 0);
      await h.manager.execute(buildRequest());
      expect(h.manager.activeCalls, 0);
    });

    test('validation failure yields INVALID_ARGS and the plugin is not called',
        () async {
      final plugin = FakePlugin(
        validator: (m, a) async => ValidationResult.invalid('bad input'),
      );
      final h = await EngineHarness.create(plugins: [plugin]);
      final r = await h.manager.execute(buildRequest());
      expect(r.error!.code, PluginErrorCode.invalidArgs);
      expect(r.error!.message, 'bad input');
      expect(plugin.calls, 0);
    });

    test('rate limit yields RATE_LIMIT_EXCEEDED with a retry hint', () async {
      final limiter =
          RateLimiter(defaultRule: const RateLimitRule.perSecond(1));
      final h = await EngineHarness.create(
        plugins: [FakePlugin()],
        rateLimiter: limiter,
      );
      await h.manager.execute(buildRequest(requestId: 'a'));
      final second = await h.manager.execute(buildRequest(requestId: 'b'));
      expect(second.error!.code, PluginErrorCode.rateLimitExceeded);
      expect(second.error!.message, contains('Retry after'));
      expect(h.manager.stats['fake.echo']!.errorCount, 1);
    });
  });

  group('error contract (SEC-003, SM-010)', () {
    test('internal exceptions are reported as a generic message', () async {
      final plugin = FakePlugin(
        impl: (m, a) async => throw StateError('secret path /data/user/0/xyz'),
      );
      final h = await EngineHarness.create(plugins: [plugin]);
      final r = await h.manager.execute(buildRequest());
      expect(r.success, isFalse);
      expect(r.error!.code, PluginErrorCode.executionError);
      expect(r.error!.message, 'Plugin execution failed');
      expect(r.toJson().toString(), isNot(contains('secret path')));
      expect(r.toJson().toString(), isNot(contains('StackTrace')));
    });

    test('PluginException message and code are passed through', () async {
      final plugin = FakePlugin(
        impl: (m, a) async => throw const PluginException(
          PluginErrorCode.cancelled,
          'User cancelled',
        ),
      );
      final h = await EngineHarness.create(plugins: [plugin]);
      final r = await h.manager.execute(buildRequest());
      expect(r.error!.code, PluginErrorCode.cancelled);
      expect(r.error!.message, 'User cancelled');
      expect(h.manager.stats['fake.echo']!.errorCount, 1);
    });
  });

  group('execution limits', () {
    test('timeout from configuration is honoured (SM-004)', () async {
      final plugin = FakePlugin(
        impl: (m, a) => Completer<dynamic>().future,
      );
      final h = await EngineHarness.create(
        plugins: [plugin],
        timeout: const Duration(milliseconds: 30),
      );
      final r = await h.manager.execute(buildRequest());
      expect(r.error!.code, PluginErrorCode.timeout);
    });

    test('maxConcurrentCalls is enforced at runtime (SM-002)', () async {
      final gate = Completer<dynamic>();
      final plugin = FakePlugin(
        impl: (m, a) => gate.future,
        capabilities: const PluginCapabilities(
          supportsStreaming: false,
          supportsBatch: true,
          supportsCache: false,
          maxConcurrentCalls: 1,
        ),
      );
      final h = await EngineHarness.create(plugins: [plugin]);
      final first = h.manager.execute(buildRequest(requestId: 'first'));
      await Future<void>.delayed(Duration.zero);
      final second = await h.manager.execute(buildRequest(requestId: 'second'));
      expect(second.error!.code, PluginErrorCode.rateLimitExceeded);
      gate.complete('done');
      expect((await first).success, isTrue);
    });

    test('duplicate in-flight requestId is rejected', () async {
      final gate = Completer<dynamic>();
      final plugin = FakePlugin(impl: (m, a) => gate.future);
      final h = await EngineHarness.create(plugins: [plugin]);
      final first = h.manager.execute(buildRequest(requestId: 'same'));
      await Future<void>.delayed(Duration.zero);
      final dup = await h.manager.execute(buildRequest(requestId: 'same'));
      expect(dup.error!.code, PluginErrorCode.invalidRequest);
      gate.complete(1);
      await first;
    });

    test('streaming method needs the streaming capability', () async {
      final plugin = FakePlugin(
        streaming: {'watch'},
        capabilities: const PluginCapabilities(
          supportsStreaming: false,
          supportsBatch: true,
          supportsCache: false,
          maxConcurrentCalls: 4,
        ),
      );
      final h = await EngineHarness.create(plugins: [plugin]);
      final r = await h.manager.execute(buildRequest(method: 'watch'));
      expect(r.error!.code, PluginErrorCode.invalidRequest);
      expect(plugin.calls, 0);
    });
  });

  group('caching (SM-003, BUG-001)', () {
    test('read-only results are served from cache on the second call',
        () async {
      final plugin = FakePlugin(cacheable: {'get'});
      final h = await EngineHarness.create(plugins: [plugin]);
      final first = await h.manager
          .execute(buildRequest(method: 'get', args: {'key': 'a'}));
      final second = await h.manager.execute(
          buildRequest(requestId: 'r2', method: 'get', args: {'key': 'a'}));
      expect(first.metadata.fromCache, isFalse);
      expect(second.metadata.fromCache, isTrue);
      expect(plugin.calls, 1);
    });

    // Regression: a write must execute, never be answered from cache.
    test('regression: a write method always executes, even with cached reads',
        () async {
      final plugin = FakePlugin(cacheable: {'get'});
      final h = await EngineHarness.create(plugins: [plugin]);
      await h.manager.execute(buildRequest(method: 'get', args: {'key': 'a'}));
      final write = await h.manager.execute(
        buildRequest(requestId: 'w', method: 'set', args: {'key': 'a'}),
      );
      expect(write.metadata.fromCache, isFalse);
      expect(plugin.calls, 2);
    });

    // Regression: a successful write invalidates the plugin's cached reads.
    test('regression: a successful write invalidates cached reads', () async {
      final plugin = FakePlugin(cacheable: {'get'});
      final h = await EngineHarness.create(plugins: [plugin]);
      await h.manager.execute(buildRequest(method: 'get', args: {'key': 'a'}));
      await h.manager.execute(
        buildRequest(requestId: 'w', method: 'set', args: {'key': 'a'}),
      );
      final afterWrite = await h.manager.execute(
        buildRequest(requestId: 'r3', method: 'get', args: {'key': 'a'}),
      );
      expect(afterWrite.metadata.fromCache, isFalse);
      expect(plugin.calls, 3);
    });

    test('cache keys do not depend on argument key order', () async {
      final plugin = FakePlugin(cacheable: {'get'});
      final h = await EngineHarness.create(plugins: [plugin]);
      await h.manager
          .execute(buildRequest(method: 'get', args: {'a': 1, 'b': 2}));
      final again = await h.manager.execute(
        buildRequest(requestId: 'r2', method: 'get', args: {'b': 2, 'a': 1}),
      );
      expect(again.metadata.fromCache, isTrue);
    });

    test('a plugin without cacheable methods never caches', () async {
      final plugin = FakePlugin();
      final h = await EngineHarness.create(plugins: [plugin]);
      await h.manager.execute(buildRequest());
      await h.manager.execute(buildRequest(requestId: 'r2'));
      expect(plugin.calls, 2);
    });
  });

  group('batch', () {
    test('results are returned in request order', () async {
      final h = await EngineHarness.create(plugins: [FakePlugin()]);
      final results = await h.manager.executeBatch(
        [buildRequest(requestId: 'a'), buildRequest(requestId: 'b')],
        BatchOptions.defaults(),
      );
      expect(results.map((r) => r.requestId), ['a', 'b']);
    });

    test('plugin without batch support fails only that item', () async {
      final plugin = FakePlugin(
        capabilities: const PluginCapabilities(
          supportsStreaming: false,
          supportsBatch: false,
          supportsCache: false,
          maxConcurrentCalls: 4,
        ),
      );
      final h = await EngineHarness.create(plugins: [plugin]);
      final results = await h.manager.executeBatch(
        [buildRequest(requestId: 'a')],
        BatchOptions.defaults(),
      );
      expect(results.single.error!.code, PluginErrorCode.invalidRequest);
    });

    // Regression: BUG-002 — a hanging item must not leave the batch unsettled.
    test('regression: batch timeout settles every item', () async {
      final plugin = FakePlugin(impl: (m, a) => Completer<dynamic>().future);
      final h = await EngineHarness.create(plugins: [plugin]);
      final results = await h.manager.executeBatch(
        [buildRequest(requestId: 'a'), buildRequest(requestId: 'b')],
        const BatchOptions(parallel: true, stopOnError: false, timeoutMs: 50),
      );
      expect(results.map((r) => r.requestId), ['a', 'b']);
      expect(results.every((r) => !r.success), isTrue);
      expect(results.every((r) => r.error!.code == PluginErrorCode.timeout),
          isTrue);
    });

    test('sequential stopOnError marks later items as not executed', () async {
      final plugin = FakePlugin(
        impl: (m, a) async => throw const PluginException(
          PluginErrorCode.invalidArgs,
          'nope',
        ),
      );
      final h = await EngineHarness.create(plugins: [plugin]);
      final results = await h.manager.executeBatch(
        [buildRequest(requestId: 'a'), buildRequest(requestId: 'b')],
        const BatchOptions(parallel: false, stopOnError: true),
      );
      expect(results[0].error!.code, PluginErrorCode.invalidArgs);
      expect(results[1].error!.code, PluginErrorCode.cancelled);
      expect(results[1].error!.message, contains('Not executed'));
      expect(plugin.calls, 1);
    });
  });

  group('traces and lifecycle', () {
    test('every request emits a trace, including failures', () async {
      final h = await EngineHarness.create(plugins: [FakePlugin()]);
      final traces = <PluginTrace>[];
      final sub = h.manager.traces.listen(traces.add);
      await h.manager.execute(buildRequest(requestId: 'ok'));
      await h.manager.execute(buildRequest(requestId: 'bad', method: 'nope'));
      await Future<void>.delayed(Duration.zero);
      await sub.cancel();
      expect(traces.map((t) => t.success), [true, false]);
      expect(traces.last.error, 'METHOD_NOT_FOUND');
    });

    test('dispose cancels in-flight executions', () async {
      final plugin = FakePlugin(impl: (m, a) => Completer<dynamic>().future);
      final h = await EngineHarness.create(plugins: [plugin]);
      final pending = h.manager.execute(buildRequest(requestId: 'x'));
      await Future<void>.delayed(Duration.zero);
      h.manager.dispose();
      final r = await pending;
      expect(r.error!.code, PluginErrorCode.cancelled);
    });
  });

  group('registry', () {
    test('rejects invalid and duplicate names', () async {
      final registry = PluginRegistry();
      await expectLater(
        registry.register(FakePlugin(name: 'Bad-Name')),
        throwsArgumentError,
      );
      await registry.register(FakePlugin(name: 'good'));
      await expectLater(
        registry.register(FakePlugin(name: 'good')),
        throwsStateError,
      );
    });

    test('unregister disposes and removes the plugin', () async {
      final registry = PluginRegistry();
      await registry.register(FakePlugin(name: 'gone'));
      expect(await registry.unregister('gone'), isTrue);
      expect(registry.resolve('gone'), isNull);
      expect(await registry.unregister('gone'), isFalse);
    });
  });
}
