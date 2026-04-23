import 'dart:async';
import '../../../core/lib/src/utils/logger.dart';

// ============================================================
// RATE LIMITER — محدودسازی نرخ درخواست
// ============================================================

class RateLimitResult {
  final bool allowed;
  final int remaining;
  final int retryAfterMs;

  const RateLimitResult({
    required this.allowed,
    required this.remaining,
    required this.retryAfterMs,
  });
}

class RateLimitRule {
  final int maxCalls;
  final Duration window;

  const RateLimitRule({
    required this.maxCalls,
    required this.window,
  });

  factory RateLimitRule.perSecond(int max) => RateLimitRule(
        maxCalls: max,
        window: const Duration(seconds: 1),
      );

  factory RateLimitRule.perMinute(int max) => RateLimitRule(
        maxCalls: max,
        window: const Duration(minutes: 1),
      );
}

class RateLimiter {
  final Map<String, RateLimitRule> _rules = {};
  final Map<String, _BucketState> _buckets = {};
  
  RateLimitRule _defaultRule = RateLimitRule.perSecond(100);

  void setDefaultRule(RateLimitRule rule) {
    _defaultRule = rule;
  }

  void addRule(String key, RateLimitRule rule) {
    _rules[key] = rule;
    BridgeLogger.debug(
      'RateLimiter',
      'Rule added: $key (${rule.maxCalls} per ${rule.window.inSeconds}s)',
    );
  }

  Future<RateLimitResult> check(String plugin, String method) async {
    final key = '$plugin.$method';
    final rule = _rules[key] ?? _rules[plugin] ?? _defaultRule;
    
    _buckets[key] ??= _BucketState(rule: rule);
    final bucket = _buckets[key]!;
    
    return bucket.consume();
  }

  void reset(String key) {
    _buckets.remove(key);
  }

  Map<String, dynamic> getStats() {
    return _buckets.map(
      (key, bucket) => MapEntry(key, bucket.toJson()),
    );
  }
}

class _BucketState {
  final RateLimitRule rule;
  final List<DateTime> _calls = [];

  _BucketState({required this.rule});

  RateLimitResult consume() {
    final now = DateTime.now();
    final windowStart = now.subtract(rule.window);
    
    // پاکسازی calls قدیمی
    _calls.removeWhere((time) => time.isBefore(windowStart));
    
    if (_calls.length >= rule.maxCalls) {
      final oldest = _calls.first;
      final retryAfter = oldest.add(rule.window).difference(now);
      
      return RateLimitResult(
        allowed: false,
        remaining: 0,
        retryAfterMs: retryAfter.inMilliseconds.clamp(0, 60000),
      );
    }
    
    _calls.add(now);
    
    return RateLimitResult(
      allowed: true,
      remaining: rule.maxCalls - _calls.length,
      retryAfterMs: 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'callsInWindow': _calls.length,
        'maxCalls': rule.maxCalls,
        'windowSeconds': rule.window.inSeconds,
      };
}
