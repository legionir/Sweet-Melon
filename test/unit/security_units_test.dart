import 'package:flutter_test/flutter_test.dart';
import 'package:sweetmelon/packages/performance/lib/src/cache_manager.dart';
import 'package:sweetmelon/packages/security/lib/security.dart';
import 'package:sweetmelon/plugins/geolocation/lib/geolocation_plugin.dart';

import '../helpers/fakes.dart';

void main() {
  group('RateLimiter', () {
    test('allows up to the limit then denies with a positive retry hint', () {
      final clock = FakeClock();
      final limiter = RateLimiter(
        defaultRule: const RateLimitRule.perSecond(3),
        clock: clock.millis,
      );
      expect(limiter.check('a.b').allowed, isTrue);
      expect(limiter.check('a.b').allowed, isTrue);
      expect(limiter.check('a.b').allowed, isTrue);
      final denied = limiter.check('a.b');
      expect(denied.allowed, isFalse);
      expect(denied.retryAfterMs, inInclusiveRange(1, 1000));
    });

    test('window slides: calls are allowed again after the window passes', () {
      final clock = FakeClock();
      final limiter = RateLimiter(
        defaultRule: const RateLimitRule.perSecond(1),
        clock: clock.millis,
      );
      expect(limiter.check('k').allowed, isTrue);
      expect(limiter.check('k').allowed, isFalse);
      clock.advance(const Duration(seconds: 1));
      expect(limiter.check('k').allowed, isTrue);
    });

    test('per-key rules override the default', () {
      final clock = FakeClock();
      final limiter = RateLimiter(
        defaultRule: const RateLimitRule.perSecond(10),
        clock: clock.millis,
      )..addRule('camera.takePhoto', const RateLimitRule.perSecond(1));
      expect(limiter.check('camera.takePhoto').allowed, isTrue);
      expect(limiter.check('camera.takePhoto').allowed, isFalse);
      expect(limiter.check('storage.get').allowed, isTrue);
    });

    // Regression: BUG-009 — `.clamp` results were assigned to int fields.
    // The retry value must be a plain int and never exceed the window.
    test('regression: retryAfterMs is an int within the window', () {
      final clock = FakeClock();
      final limiter = RateLimiter(
        defaultRule: const RateLimitRule.perSecond(1),
        clock: clock.millis,
      );
      limiter.check('x');
      clock.advance(const Duration(milliseconds: 250));
      final denied = limiter.check('x');
      expect(denied.retryAfterMs, isA<int>());
      expect(denied.retryAfterMs, lessThanOrEqualTo(1000));
      expect(denied.retryAfterMs, greaterThanOrEqualTo(1));
    });

    // Regression: SEC-008 — the number of tracked keys is bounded.
    test('regression: tracked keys are capped and idle keys are pruned', () {
      final clock = FakeClock();
      final limiter = RateLimiter(
        defaultRule: const RateLimitRule.perSecond(5),
        maxTrackedKeys: 4,
        clock: clock.millis,
      );
      for (var i = 0; i < 50; i++) {
        limiter.check('plugin$i.method');
        clock.advance(const Duration(seconds: 2));
      }
      expect(limiter.trackedKeys, lessThanOrEqualTo(4));
    });
  });

  group('CacheManager', () {
    test('returns a fresh copy: mutating the result does not change the cache',
        () {
      final cache = CacheManager(maxEntries: 10);
      cache.set('k', {'list': [1, 2]}, ttl: const Duration(seconds: 10));
      final first = cache.get('k') as Map<String, dynamic>;
      (first['list'] as List).add(99);
      final second = cache.get('k') as Map<String, dynamic>;
      expect(second['list'], [1, 2]);
    });

    // Regression: PERF-001 — overwriting a key must not evict another entry.
    test('regression: overwriting a key does not evict other entries', () {
      final cache = CacheManager(maxEntries: 2);
      cache.set('a', 1, ttl: const Duration(minutes: 1));
      cache.set('b', 2, ttl: const Duration(minutes: 1));
      cache.set('a', 3, ttl: const Duration(minutes: 1));
      expect(cache.get('a'), 3);
      expect(cache.get('b'), 2);
      expect(cache.stats.evictions, 0);
    });

    test('evicts the least recently used entry when full', () {
      final cache = CacheManager(maxEntries: 2);
      cache.set('a', 1, ttl: const Duration(minutes: 1));
      cache.set('b', 2, ttl: const Duration(minutes: 1));
      expect(cache.get('a'), 1); // a becomes most recent
      cache.set('c', 3, ttl: const Duration(minutes: 1));
      expect(cache.get('b'), isNull);
      expect(cache.get('a'), 1);
      expect(cache.get('c'), 3);
      expect(cache.stats.evictions, 1);
    });

    test('expired entries are not returned', () {
      final clock = FakeClock();
      final cache = CacheManager(maxEntries: 5, now: clock.call);
      cache.set('k', 'v', ttl: const Duration(seconds: 5));
      clock.advance(const Duration(seconds: 6));
      expect(cache.get('k'), isNull);
    });

    test('invalidatePlugin removes only that plugin entries', () {
      final cache = CacheManager(maxEntries: 10);
      cache.set('storage:get:{}', 1, ttl: const Duration(minutes: 1));
      cache.set('storage:keys:{}', 2, ttl: const Duration(minutes: 1));
      cache.set('camera:info:{}', 3, ttl: const Duration(minutes: 1));
      cache.invalidatePlugin('storage');
      expect(cache.get('storage:get:{}'), isNull);
      expect(cache.get('storage:keys:{}'), isNull);
      expect(cache.get('camera:info:{}'), 3);
    });

    test('values that cannot be encoded are refused', () {
      final cache = CacheManager(maxEntries: 5);
      expect(cache.set('k', Object(), ttl: const Duration(seconds: 1)), isFalse);
      expect(cache.get('k'), isNull);
    });

    test('performance: 20k set/get operations on a 1k-entry cache stay fast', () {
      final cache = CacheManager(maxEntries: 1000);
      final watch = Stopwatch()..start();
      for (var i = 0; i < 20000; i++) {
        cache.set('p:$i', {'i': i}, ttl: const Duration(minutes: 1));
        cache.get('p:${i ~/ 2}');
      }
      watch.stop();
      expect(cache.length, lessThanOrEqualTo(1000));
      // Generous budget so slow CI runners do not flake; the old O(n) LRU
      // took orders of magnitude longer at this size.
      expect(watch.elapsedMilliseconds, lessThan(5000));
    });
  });

  group('ExecutionGuard', () {
    test('returns the value of a fast execution', () async {
      final guard = ExecutionGuard();
      final value = await guard.execute<int>(
        requestId: 'r1',
        timeout: const Duration(seconds: 1),
        fn: () async => 7,
      );
      expect(value, 7);
      expect(guard.activeCount, 0);
    });

    test('times out slow executions and clears the in-flight entry', () async {
      final guard = ExecutionGuard();
      await expectLater(
        guard.execute<void>(
          requestId: 'slow',
          timeout: const Duration(milliseconds: 20),
          fn: () => Future<void>.delayed(const Duration(seconds: 5)),
        ),
        throwsA(isA<ExecutionTimeoutException>()),
      );
      expect(guard.activeCount, 0);
    });

    test('rejects a duplicate requestId while the first is in flight', () async {
      final guard = ExecutionGuard();
      final gate = Completer<void>();
      final first = guard.execute<void>(
        requestId: 'dup',
        timeout: const Duration(seconds: 5),
        fn: () => gate.future,
      );
      await expectLater(
        guard.execute<void>(
          requestId: 'dup',
          timeout: const Duration(seconds: 5),
          fn: () async {},
        ),
        throwsA(isA<DuplicateRequestException>()),
      );
      gate.complete();
      await first;
    });

    test('cancelAll completes pending executions with ExecutionCancelled',
        () async {
      final guard = ExecutionGuard();
      final pending = guard.execute<void>(
        requestId: 'p',
        timeout: const Duration(seconds: 5),
        fn: () => Completer<void>().future,
      );
      guard.cancelAll();
      await expectLater(pending, throwsA(isA<ExecutionCancelled>()));
      expect(guard.activeCount, 0);
    });
  });

  group('PermissionManager (SEC-005)', () {
    test('caches a grant until the TTL expires, then asks again', () async {
      final clock = FakeClock();
      final provider = FakePermissionProvider({'camera': PermissionState.granted});
      final manager = PermissionManager(
        provider: provider,
        cacheTtl: const Duration(seconds: 60),
        now: clock.call,
      );
      expect(await manager.check('camera'), isTrue);
      expect(await manager.check('camera'), isTrue);
      expect(provider.statusCalls, 1);

      clock.advance(const Duration(seconds: 61));
      provider.states['camera'] = PermissionState.denied;
      expect(await manager.check('camera'), isFalse);
      expect(provider.statusCalls, 2);
    });

    test('unknown permission is denied', () async {
      final manager = PermissionManager(provider: FakePermissionProvider());
      expect(await manager.check('microphone'), isFalse);
    });

    test('invalidateAll forces a fresh check', () async {
      final provider = FakePermissionProvider({'location': PermissionState.granted});
      final manager = PermissionManager(provider: provider);
      await manager.check('location');
      manager.invalidateAll();
      await manager.check('location');
      expect(provider.statusCalls, 2);
    });
  });

  group('GeolocationPlugin.validatePositionArgs', () {
    test('accepts known accuracy levels and numeric distance filter', () {
      expect(
        GeolocationPlugin.validatePositionArgs({'accuracy': 'best', 'distanceFilter': 5})
            .isValid,
        isTrue,
      );
    });

    test('timeoutMs must be between 1 and 60000 (BUG-013)', () {
      expect(
        GeolocationPlugin.validatePositionArgs({'timeoutMs': 5000}).isValid,
        isTrue,
      );
      expect(
        GeolocationPlugin.validatePositionArgs({'timeoutMs': 0}).isValid,
        isFalse,
      );
      expect(
        GeolocationPlugin.validatePositionArgs({'timeoutMs': 60001}).isValid,
        isFalse,
      );
      expect(
        GeolocationPlugin.validatePositionArgs({'timeoutMs': 'soon'}).isValid,
        isFalse,
      );
    });

    test('rejects unknown accuracy and out-of-range distance filter', () {
      expect(
        GeolocationPlugin.validatePositionArgs({'accuracy': 'ultra'}).isValid,
        isFalse,
      );
      expect(
        GeolocationPlugin.validatePositionArgs({'distanceFilter': -1}).isValid,
        isFalse,
      );
    });
  });
}
