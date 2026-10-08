// performance smoke tests (PERF-001, SEC-004, ARCH-004).
//
// The budgets are deliberately generous: they catch accidental quadratic work
// or unbounded growth, not small timing changes, so they do not flake on CI.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:sweetmelon/packages/core/lib/src/bridge/message_bridge.dart';
import 'package:sweetmelon/packages/performance/lib/performance.dart';

import '../helpers/fakes.dart';

void main() {
  test('bridge: 500 request round trips stay within the smoke budget',
      () async {
    final plugin = FakePlugin();
    final harness = await EngineHarness.create(plugins: [plugin]);
    final bridge = MessageBridge();
    bridge.setMessageHandler(harness.manager.execute);
    final scripts = <String>[];
    bridge.attachJsExecutor((script) async => scripts.add(script));
    final token = bridge.startSession();
    expect(bridge.onBridgeReady(token), isTrue);

    final watch = Stopwatch()..start();
    for (var i = 0; i < 500; i++) {
      await bridge.handleIncomingMessage(jsonEncode({
        'token': token,
        'requestId': 'req_perf_$i',
        'plugin': 'fake',
        'method': 'echo',
        'args': {'i': i},
        'metadata': {'headers': <String, String>{}},
      }));
    }
    watch.stop();

    expect(plugin.calls, 500);
    expect(scripts.length, greaterThanOrEqualTo(500));
    expect(watch.elapsed, lessThan(const Duration(seconds: 20)));
    bridge.dispose();
  });

  test('bridge: 1000 events are delivered to the page in order', () async {
    final bridge = MessageBridge();
    final scripts = <String>[];
    bridge.attachJsExecutor((script) async => scripts.add(script));
    final token = bridge.startSession();
    expect(bridge.onBridgeReady(token), isTrue);

    final watch = Stopwatch()..start();
    for (var i = 0; i < 1000; i++) {
      await bridge.emitEvent('tick', i);
    }
    watch.stop();

    expect(scripts.length, greaterThanOrEqualTo(1000));
    expect(scripts.last.contains('999'), isTrue);
    expect(watch.elapsed, lessThan(const Duration(seconds: 20)));
    bridge.dispose();
  });

  test('cache: 10000 operations on a 1000-entry cache stay bounded', () {
    final cache = CacheManager(maxEntries: 1000);
    final watch = Stopwatch()..start();
    for (var i = 0; i < 10000; i++) {
      cache.set('p:k$i', i, ttl: const Duration(seconds: 30));
      cache.get('p:k${i ~/ 2}');
    }
    watch.stop();

    expect(cache.length, lessThanOrEqualTo(1000));
    expect(watch.elapsed, lessThan(const Duration(seconds: 10)));
  });

  // Regression: PERF-001 — overwriting an existing key must not evict an
  // unrelated entry.
  test('regression PERF-001: overwriting a key does not evict another entry',
      () {
    final cache = CacheManager(maxEntries: 3);
    const ttl = Duration(seconds: 30);
    cache.set('p:a', 1, ttl: ttl);
    cache.set('p:b', 2, ttl: ttl);
    cache.set('p:c', 3, ttl: ttl);

    cache.set('p:a', 10, ttl: ttl);

    expect(cache.get('p:a'), 10);
    expect(cache.get('p:b'), 2);
    expect(cache.get('p:c'), 3);
    expect(cache.length, 3);
  });
}
