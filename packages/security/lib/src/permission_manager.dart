import 'dart:async';

import 'package:core/core.dart';

// ============================================================
// PERMISSION MANAGER
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

class StaticPermissionProvider implements PermissionProvider {
  final Map<String, PermissionStatus> grants;
  final PermissionStatus defaultStatus;

  const StaticPermissionProvider({
    required this.grants,
    this.defaultStatus = PermissionStatus.denied,
  });

  @override
  Future<PermissionStatus> checkPermission(String permission) async {
    return grants[permission] ?? defaultStatus;
  }

  @override
  Future<PermissionStatus> requestPermission(String permission) async {
    return grants[permission] ?? defaultStatus;
  }
}

class PermissionManager {
  final Map<String, PermissionPolicy> _policies = {};
  final Map<String, PermissionStatus> _cache = {};
  PermissionProvider? _provider;

  void setProvider(PermissionProvider provider) {
    _provider = provider;
    _cache.clear();
  }

  void addPolicy(String plugin, PermissionPolicy policy) {
    _policies[plugin] = policy;
  }

  Future<bool> check(String permission) async {
    if (_cache.containsKey(permission)) {
      final cached = _cache[permission]!;
      BridgeLogger.debug(
        'PermissionManager',
        'Permission "$permission" (cached): ${cached.name}',
      );
      return cached == PermissionStatus.granted;
    }

    if (_provider == null) {
      BridgeLogger.warn(
        'PermissionManager',
        'No provider set, denying permission: $permission',
      );
      return false;
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
    if (_provider == null) {
      BridgeLogger.warn(
        'PermissionManager',
        'No provider set, cannot request: $permission',
      );
      return false;
    }

    final status = await _provider!.requestPermission(permission);
    _cache[permission] = status;

    BridgeLogger.info(
      'PermissionManager',
      'Permission requested "$permission": ${status.name}',
    );

    return status == PermissionStatus.granted;
  }

  Future<Map<String, bool>> checkAll(List<String> permissions) async {
    final results = <String, bool>{};
    for (final permission in permissions) {
      results[permission] = await check(permission);
    }
    return results;
  }

  Future<bool> checkPlugin(String pluginName) async {
    final policy = _policies[pluginName];
    if (policy == null) return true;

    for (final permission in policy.required) {
      final granted = await check(permission);
      if (!granted) return false;
    }
    return true;
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

  bool get hasProvider => _provider != null;
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

  Map<String, dynamic> toJson() => {
        'required': required,
        'optional': optional,
      };
}