import 'dart:async';
import '../../../core/lib/src/utils/logger.dart';

// ============================================================
// PERMISSION MANAGER — مدیریت مجوزها
// ============================================================

enum PermissionStatus {
  granted,
  denied,
  pending,
  notDetermined,
}

abstract class PermissionProvider {
  Future<PermissionStatus> checkPermission(String permission);
  Future<PermissionStatus> requestPermission(String permission);
}

class PermissionManager {
  final Map<String, PermissionPolicy> _policies = {};
  final Map<String, PermissionStatus> _cache = {};
  PermissionProvider? _provider;

  void setProvider(PermissionProvider provider) {
    _provider = provider;
  }

  void addPolicy(String plugin, PermissionPolicy policy) {
    _policies[plugin] = policy;
  }

  Future<bool> check(String permission) async {
    // بررسی cache
    if (_cache.containsKey(permission)) {
      return _cache[permission] == PermissionStatus.granted;
    }

    if (_provider == null) {
      BridgeLogger.warn(
        'PermissionManager',
        'No provider set, defaulting to granted for: $permission',
      );
      return true;
    }

    final status = await _provider!.checkPermission(permission);
    _cache[permission] = status;

    BridgeLogger.debug(
      'PermissionManager',
      'Permission "$permission": ${status.name}',
    );

    return status == PermissionStatus.granted;
  }

  Future<bool> request(String permission) async {
    if (_provider == null) return true;

    final status = await _provider!.requestPermission(permission);
    _cache[permission] = status;

    return status == PermissionStatus.granted;
  }

  Future<Map<String, bool>> checkAll(List<String> permissions) async {
    final results = <String, bool>{};
    
    for (final permission in permissions) {
      results[permission] = await check(permission);
    }
    
    return results;
  }

  void invalidateCache([String? permission]) {
    if (permission != null) {
      _cache.remove(permission);
    } else {
      _cache.clear();
    }
  }

  Map<String, PermissionStatus> get currentStatus => 
      Map.unmodifiable(_cache);
}

class PermissionPolicy {
  final List<String> required;
  final List<String> optional;

  const PermissionPolicy({
    required this.required,
    this.optional = const [],
  });

  factory PermissionPolicy.fromJson(Map<String, dynamic> json) {
    return PermissionPolicy(
      required: List<String>.from(json['required'] as List? ?? []),
      optional: List<String>.from(json['optional'] as List? ?? []),
    );
  }
}
