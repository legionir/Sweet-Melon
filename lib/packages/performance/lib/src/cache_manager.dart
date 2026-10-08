import 'dart:collection';
import 'dart:convert';

// ============================================================
// CACHE MANAGER — bounded LRU with TTL
// ============================================================
//
// * O(1) get/set/evict (LinkedHashMap keeps insertion = recency order).
// * Values are stored as JSON text and decoded on every read, so cached data
//   can never be mutated by a caller (PERF-001).
// * Overwriting an existing key never evicts another entry.
// * Keys are "plugin:method:args"; [invalidatePlugin] removes all keys of one
//   plugin, which the plugin manager calls after every mutating method.

class CacheEntry {
  final String encoded;
  final DateTime expiresAt;

  const CacheEntry(this.encoded, this.expiresAt);

  bool isExpiredAt(DateTime now) => !now.isBefore(expiresAt);
}

class CacheStats {
  final int entries;
  final int hits;
  final int misses;
  final int evictions;

  const CacheStats({
    required this.entries,
    required this.hits,
    required this.misses,
    required this.evictions,
  });

  double get hitRate => (hits + misses) == 0 ? 0 : hits / (hits + misses);

  Map<String, dynamic> toJson() => {
        'entries': entries,
        'hits': hits,
        'misses': misses,
        'evictions': evictions,
        'hitRate': hitRate,
      };
}

class CacheManager {
  final int maxEntries;
  final DateTime Function() _now;
  final LinkedHashMap<String, CacheEntry> _entries = LinkedHashMap();
  int _hits = 0;
  int _misses = 0;
  int _evictions = 0;
  bool _disposed = false;

  CacheManager({this.maxEntries = 500, DateTime Function()? now})
      : assert(maxEntries > 0),
        _now = now ?? DateTime.now;

  /// Returns a fresh decoded copy of the cached value, or null.
  Object? get(String key) {
    if (_disposed) return null;
    final entry = _entries.remove(key);
    if (entry == null) {
      _misses++;
      return null;
    }
    if (entry.isExpiredAt(_now())) {
      _misses++;
      return null;
    }
    // Re-insert to mark as most recently used.
    _entries[key] = entry;
    _hits++;
    return jsonDecode(entry.encoded);
  }

  /// Stores a JSON-encodable [value]. Returns false if it cannot be encoded
  /// or the cache is disposed.
  bool set(String key, Object? value, {required Duration ttl}) {
    if (_disposed) return false;
    final String encoded;
    try {
      encoded = jsonEncode(value);
    } catch (_) {
      return false;
    }
    _entries.remove(key);
    _entries[key] = CacheEntry(encoded, _now().add(ttl));
    while (_entries.length > maxEntries) {
      _entries.remove(_entries.keys.first);
      _evictions++;
    }
    return true;
  }

  void invalidate(String key) => _entries.remove(key);

  /// Removes every entry belonging to [pluginName].
  void invalidatePlugin(String pluginName) => invalidatePattern('$pluginName:');

  /// Removes every entry whose key starts with [prefix].
  void invalidatePattern(String prefix) {
    _entries.removeWhere((key, _) => key.startsWith(prefix));
  }

  void clear() => _entries.clear();

  int get length => _entries.length;

  CacheStats get stats => CacheStats(
        entries: _entries.length,
        hits: _hits,
        misses: _misses,
        evictions: _evictions,
      );

  void dispose() {
    _disposed = true;
    _entries.clear();
  }
}
