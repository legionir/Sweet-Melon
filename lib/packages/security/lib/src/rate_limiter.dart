import 'dart:collection';

// ============================================================
// RATE LIMITER — sliding window per key
// ============================================================
//
// Keys are only created for plugin/method pairs that the plugin manager has
// already resolved (SEC-008). The number of tracked keys is capped and idle
// keys are pruned, so the map cannot grow without bound.

class RateLimitResult {
  final bool allowed;
  final int retryAfterMs;

  const RateLimitResult.allow()
      : allowed = true,
        retryAfterMs = 0;

  const RateLimitResult.deny(this.retryAfterMs) : allowed = false;
}

class RateLimitRule {
  final int maxCalls;
  final Duration window;

  const RateLimitRule({required this.maxCalls, required this.window})
      : assert(maxCalls > 0);

  const RateLimitRule.perSecond(int maxCalls)
      : this(maxCalls: maxCalls, window: const Duration(seconds: 1));
}

class RateLimiter {
  final RateLimitRule defaultRule;
  final int maxTrackedKeys;
  final Map<String, RateLimitRule> _rules = {};
  final LinkedHashMap<String, Queue<int>> _buckets = LinkedHashMap();
  final int Function() _clock;

  RateLimiter({
    this.defaultRule = const RateLimitRule.perSecond(50),
    this.maxTrackedKeys = 1024,
    int Function()? clock,
  })  : assert(maxTrackedKeys > 0),
        _clock = clock ?? (() => DateTime.now().millisecondsSinceEpoch);

  void addRule(String key, RateLimitRule rule) => _rules[key] = rule;

  RateLimitRule ruleFor(String key) => _rules[key] ?? defaultRule;

  /// Checks and, if allowed, records one call for [key].
  RateLimitResult check(String key) {
    final now = _clock();
    final rule = ruleFor(key);
    final windowMs = rule.window.inMilliseconds;

    var bucket = _buckets.remove(key);
    if (bucket == null) {
      _pruneIfNeeded(now);
      bucket = Queue<int>();
    }
    // Re-insert at the end to keep LRU order.
    _buckets[key] = bucket;

    while (bucket.isNotEmpty && now - bucket.first >= windowMs) {
      bucket.removeFirst();
    }

    if (bucket.length >= rule.maxCalls) {
      final retryAfter = windowMs - (now - bucket.first);
      return RateLimitResult.deny(retryAfter < 1 ? 1 : retryAfter);
    }

    bucket.addLast(now);
    return const RateLimitResult.allow();
  }

  /// Number of keys currently tracked.
  int get trackedKeys => _buckets.length;

  void reset() => _buckets.clear();

  void _pruneIfNeeded(int now) {
    // Drop fully idle buckets first.
    final idle = <String>[];
    for (final entry in _buckets.entries) {
      final window = ruleFor(entry.key).window.inMilliseconds;
      final q = entry.value;
      if (q.isEmpty || now - q.last >= window) {
        idle.add(entry.key);
      }
    }
    for (final key in idle) {
      _buckets.remove(key);
    }
    // Still full: evict the least recently used keys.
    while (_buckets.length >= maxTrackedKeys) {
      _buckets.remove(_buckets.keys.first);
    }
  }
}
