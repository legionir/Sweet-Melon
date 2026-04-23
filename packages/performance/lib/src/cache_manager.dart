import 'dart:async';
import '../../../core/lib/src/utils/logger.dart';

// ============================================================
// CACHE MANAGER — مدیریت کش نتایج پلاگین
// ============================================================

class CacheEntry {
  final dynamic value;
  final DateTime expiresAt;
  int hitCount;

  CacheEntry({
    required this.value,
    required this.expiresAt,
  }) : hitCount = 0;

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}

class CacheManager {
  final Map<String, CacheEntry> _cache = {};
  final int maxEntries;
  Timer? _cleanupTimer;
  
  int _hits = 0;
  int _misses = 0;

  CacheManager({this.maxEntries = 500}) {
    _startCleanupTimer();
  }

  Future<dynamic> get(String key) async {
    final entry = _cache[key];
    
    if (entry == null) {
      _misses++;
      return null;
    }
    
    if (entry.isExpired) {
      _cache.remove(key);
      _misses++;
      return null;
    }
    
    entry.hitCount++;
    _hits++;
    BridgeLogger.debug('Cache', 'Hit: $key');
    return entry.value;
  }

  Future<void> set(
    String key,
    dynamic value, {
    Duration ttl = const Duration(minutes: 5),
  }) async {
    // LRU eviction اگر پر است
    if (_cache.length >= maxEntries) {
      _evictLRU();
    }
    
    _cache[key] = CacheEntry(
      value: value,
      expiresAt: DateTime.now().add(ttl),
    );
    
    BridgeLogger.debug('Cache', 'Set: $key (TTL: ${ttl.inSeconds}s)');
  }

  Future<void> invalidate(String key) async {
    _cache.remove(key);
  }

  Future<void> invalidatePattern(String pattern) async {
    final regex = RegExp(pattern);
    _cache.removeWhere((key, _) => regex.hasMatch(key));
  }

  Future<void> clear() async {
    _cache.clear();
    _hits = 0;
    _misses = 0;
  }

  void _evictLRU() {
    if (_cache.isEmpty) return;
    
    String? lruKey;
    int? minHits;
    
    for (final entry in _cache.entries) {
      if (minHits == null || entry.value.hitCount < minHits) {
        minHits = entry.value.hitCount;
        lruKey = entry.key;
      }
    }
    
    if (lruKey != null) {
      _cache.remove(lruKey);
      BridgeLogger.debug('Cache', 'Evicted LRU: $lruKey');
    }
  }

  void _startCleanupTimer() {
    _cleanupTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _cleanup(),
    );
  }

  void _cleanup() {
    final expired = _cache.entries
        .where((e) => e.value.isExpired)
        .map((e) => e.key)
        .toList();
    
    for (final key in expired) {
      _cache.remove(key);
    }
    
    if (expired.isNotEmpty) {
      BridgeLogger.debug('Cache', 'Cleaned ${expired.length} expired entries');
    }
  }

  CacheStats get stats => CacheStats(
        entries: _cache.length,
        hits: _hits,
        misses: _misses,
        hitRate: (_hits + _misses) > 0 ? _hits / (_hits + _misses) : 0,
      );

  void dispose() {
    _cleanupTimer?.cancel();
    _cache.clear();
  }
}

class CacheStats {
  final int entries;
  final int hits;
  final int misses;
  final double hitRate;

  const CacheStats({
    required this.entries,
    required this.hits,
    required this.misses,
    required this.hitRate,
  });

  Map<String, dynamic> toJson() => {
        'entries': entries,
        'hits': hits,
        'misses': misses,
        'hitRate': hitRate,
      };
}
