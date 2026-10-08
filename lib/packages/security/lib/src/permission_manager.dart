import 'package:permission_handler/permission_handler.dart';

// ============================================================
// PERMISSION MANAGER — OS-backed permission checks with a short TTL cache
// ============================================================
//
// SEC-005: permission results are never trusted forever. Each cached answer
// expires after [cacheTtl], so a permission revoked in system settings is
// observed again on the next call.

enum PermissionState { granted, denied, permanentlyDenied, unsupported }

/// Abstraction over the OS permission API (injectable for tests).
abstract class PermissionProvider {
  Future<PermissionState> status(String permission);
  Future<PermissionState> request(String permission);
}

/// Maps the logical permission names used by plugins to OS permissions.
/// `storage` refers to the application sandbox, which needs no runtime grant.
class PermissionHandlerProvider implements PermissionProvider {
  const PermissionHandlerProvider();

  static Permission? _map(String name) {
    switch (name) {
      case 'camera':
        return Permission.camera;
      case 'location':
        return Permission.locationWhenInUse;
      default:
        return null;
    }
  }

  @override
  Future<PermissionState> status(String permission) async {
    final p = _map(permission);
    if (p == null) {
      return _isSandboxed(permission)
          ? PermissionState.granted
          : PermissionState.unsupported;
    }
    return _fromStatus(await p.status);
  }

  @override
  Future<PermissionState> request(String permission) async {
    final p = _map(permission);
    if (p == null) {
      return _isSandboxed(permission)
          ? PermissionState.granted
          : PermissionState.unsupported;
    }
    return _fromStatus(await p.request());
  }

  static bool _isSandboxed(String permission) => permission == 'storage';

  static PermissionState _fromStatus(PermissionStatus s) {
    if (s.isGranted || s.isLimited) return PermissionState.granted;
    if (s.isPermanentlyDenied) return PermissionState.permanentlyDenied;
    return PermissionState.denied;
  }
}

class PermissionManager {
  final PermissionProvider _provider;
  final Duration cacheTtl;
  final DateTime Function() _now;
  final Map<String, _Cached> _cache = {};

  PermissionManager({
    required PermissionProvider provider,
    this.cacheTtl = const Duration(seconds: 5),
    DateTime Function()? now,
  })  : _provider = provider,
        _now = now ?? DateTime.now;

  /// True if [permission] is currently granted. Unknown permissions are denied.
  Future<bool> check(String permission) async =>
      (await stateOf(permission)) == PermissionState.granted;

  /// Current state of [permission], from the cache when it is still fresh.
  Future<PermissionState> stateOf(String permission) async {
    final cached = _cache[permission];
    if (cached != null && _now().isBefore(cached.expiresAt)) {
      return cached.state;
    }
    final state = await _provider.status(permission);
    _store(permission, state);
    return state;
  }

  /// Asks the user for [permission] and caches the result.
  Future<bool> request(String permission) async {
    final state = await _provider.request(permission);
    _store(permission, state);
    return state == PermissionState.granted;
  }

  /// Drops every cached answer (e.g. after returning from system settings).
  void invalidateAll() => _cache.clear();

  void _store(String permission, PermissionState state) {
    _cache[permission] = _Cached(state, _now().add(cacheTtl));
  }
}

class _Cached {
  final PermissionState state;
  final DateTime expiresAt;
  const _Cached(this.state, this.expiresAt);
}
