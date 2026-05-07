import 'dart:async';

import 'package:core/src/utils/logger.dart';

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

  /// بررسی اجازه ارسال درخواست
  Future<RateLimitResult> check(String plugin, String method) async {
    final specificKey = '$plugin.$method';
    final pluginKey = plugin;

    // اول rule خاص متد، بعد rule پلاگین، بعد پیش‌فرض
    final rule = _rules[specificKey] ?? _rules[pluginKey] ?? _defaultRule;

    _buckets[specificKey] ??= _BucketState(rule: rule);
    final bucket = _buckets[specificKey]!;

    final result = bucket.consume();

    if (!result.allowed) {
      BridgeLogger.warn(
        'RateLimiter',
        'Rate limit exceeded for: $specificKey '
            '(retry after ${result.retryAfterMs}ms)',
      );
    }

    return result;
  }

  /// ریست کردن یک bucket
  void reset(String key) {
    _buckets.remove(key);
  }

  /// ریست کردن تمام bucket‌ها
  void resetAll() {
    _buckets.clear();
  }

  /// آمار وضعیت فعلی
  Map<String, dynamic> getStats() {
    return _buckets.map(
      (key, bucket) => MapEntry(key, bucket.toJson()),
    );
  }
}

// ============================================================
// INTERNAL — Sliding Window Bucket
// ============================================================

class _BucketState {
  final RateLimitRule rule;
  final List<DateTime> _calls = [];

  _BucketState({required this.rule});

  RateLimitResult consume() {
    final now = DateTime.now();
    final windowStart = now.subtract(rule.window);

    // پاکسازی calls خارج از window
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
        'remaining': (rule.maxCalls - _calls.length).clamp(0, rule.maxCalls),
      };
}