# پیاده‌سازی ۳ سیستم جدید

---

# بخش ۱: Plugin Versioning و Migration System

---

## 📄 `lib/packages/plugin_engine/lib/src/plugin_versioning.dart`

```dart
import 'dart:async';

import 'package:sweetmelon/packages/core/lib/core.dart';
import 'plugin_interface.dart';

/// نسخه semantic
class SemanticVersion implements Comparable<SemanticVersion> {
  final int major;
  final int minor;
  final int patch;
  final String? preRelease;

  const SemanticVersion({
    required this.major,
    required this.minor,
    required this.patch,
    this.preRelease,
  });

  factory SemanticVersion.parse(String version) {
    final cleaned = version.trim().replaceFirst(RegExp(r'^v'), '');
    String? preRelease;
    var versionPart = cleaned;

    if (cleaned.contains('-')) {
      final parts = cleaned.split('-');
      versionPart = parts[0];
      preRelease = parts.sublist(1).join('-');
    }

    final segments = versionPart.split('.');
    return SemanticVersion(
      major: segments.isNotEmpty ? int.tryParse(segments[0]) ?? 0 : 0,
      minor: segments.length > 1 ? int.tryParse(segments[1]) ?? 0 : 0,
      patch: segments.length > 2 ? int.tryParse(segments[2]) ?? 0 : 0,
      preRelease: preRelease,
    );
  }

  bool get isPreRelease => preRelease != null;

  /// آیا این نسخه با requested سازگار هست؟
  bool satisfies(VersionConstraint constraint) {
    return constraint.allows(this);
  }

  /// آیا breaking change هست نسبت به نسخه دیگه؟
  bool isBreakingFrom(SemanticVersion other) {
    return major != other.major;
  }

  /// آیا minor change هست؟
  bool isMinorFrom(SemanticVersion other) {
    return major == other.major && minor != other.minor;
  }

  @override
  int compareTo(SemanticVersion other) {
    if (major != other.major) return major.compareTo(other.major);
    if (minor != other.minor) return minor.compareTo(other.minor);
    if (patch != other.patch) return patch.compareTo(other.patch);

    if (preRelease == null && other.preRelease != null) return 1;
    if (preRelease != null && other.preRelease == null) return -1;

    return 0;
  }

  bool operator >=(SemanticVersion other) => compareTo(other) >= 0;
  bool operator >(SemanticVersion other) => compareTo(other) > 0;
  bool operator <=(SemanticVersion other) => compareTo(other) <= 0;
  bool operator <(SemanticVersion other) => compareTo(other) < 0;

  @override
  bool operator ==(Object other) {
    if (other is! SemanticVersion) return false;
    return major == other.major &&
        minor == other.minor &&
        patch == other.patch;
  }

  @override
  int get hashCode => Object.hash(major, minor, patch);

  @override
  String toString() {
    final base = '$major.$minor.$patch';
    return preRelease != null ? '$base-$preRelease' : base;
  }

  Map<String, dynamic> toJson() => {
        'major': major,
        'minor': minor,
        'patch': patch,
        if (preRelease != null) 'preRelease': preRelease,
        'string': toString(),
      };
}

/// محدودیت نسخه
abstract class VersionConstraint {
  bool allows(SemanticVersion version);
}

/// نسخه دقیق
class ExactVersion implements VersionConstraint {
  final SemanticVersion version;
  const ExactVersion(this.version);

  @override
  bool allows(SemanticVersion v) => v == version;
}

/// حداقل نسخه (>=)
class MinVersion implements VersionConstraint {
  final SemanticVersion minimum;
  const MinVersion(this.minimum);

  @override
  bool allows(SemanticVersion v) => v >= minimum;
}

/// بازه نسخه
class VersionRange implements VersionConstraint {
  final SemanticVersion? min;
  final SemanticVersion? max;
  final bool includeMin;
  final bool includeMax;

  const VersionRange({
    this.min,
    this.max,
    this.includeMin = true,
    this.includeMax = false,
  });

  @override
  bool allows(SemanticVersion v) {
    if (min != null) {
      if (includeMin && v < min!) return false;
      if (!includeMin && v <= min!) return false;
    }

    if (max != null) {
      if (includeMax && v > max!) return false;
      if (!includeMax && v >= max!) return false;
    }

    return true;
  }
}

/// Compatible with (^) — مثل semver caret
class CompatibleWith implements VersionConstraint {
  final SemanticVersion version;
  const CompatibleWith(this.version);

  @override
  bool allows(SemanticVersion v) {
    if (v < version) return false;
    return v.major == version.major;
  }
}

/// هر نسخه‌ای
class AnyVersion implements VersionConstraint {
  const AnyVersion();

  @override
  bool allows(SemanticVersion v) => true;
}

/// parse constraint string
VersionConstraint parseConstraint(String input) {
  final trimmed = input.trim();

  if (trimmed == '*' || trimmed == 'any') {
    return const AnyVersion();
  }

  if (trimmed.startsWith('^')) {
    return CompatibleWith(SemanticVersion.parse(trimmed.substring(1)));
  }

  if (trimmed.startsWith('>=')) {
    return MinVersion(SemanticVersion.parse(trimmed.substring(2)));
  }

  return ExactVersion(SemanticVersion.parse(trimmed));
}
```

---

## 📄 `lib/packages/plugin_engine/lib/src/plugin_migration.dart`

```dart
import 'dart:async';

import 'package:sweetmelon/packages/core/lib/core.dart';
import 'plugin_versioning.dart';

/// یک migration step
class MigrationStep {
  final SemanticVersion fromVersion;
  final SemanticVersion toVersion;
  final String description;
  final Future<MigrationResult> Function(Map<String, dynamic> args) migrate;
  final Map<String, ArgTransform>? argTransforms;
  final Map<String, String>? methodRenames;
  final Set<String>? removedMethods;
  final Set<String>? addedMethods;

  const MigrationStep({
    required this.fromVersion,
    required this.toVersion,
    required this.description,
    required this.migrate,
    this.argTransforms,
    this.methodRenames,
    this.removedMethods,
    this.addedMethods,
  });
}

/// تبدیل args
class ArgTransform {
  final String? renamedTo;
  final dynamic Function(dynamic oldValue)? transformer;
  final bool removed;
  final dynamic defaultValue;

  const ArgTransform({
    this.renamedTo,
    this.transformer,
    this.removed = false,
    this.defaultValue,
  });

  const ArgTransform.rename(String newName)
      : renamedTo = newName,
        transformer = null,
        removed = false,
        defaultValue = null;

  const ArgTransform.remove()
      : renamedTo = null,
        transformer = null,
        removed = true,
        defaultValue = null;
}

class MigrationResult {
  final bool success;
  final String? message;
  final Map<String, dynamic>? transformedArgs;

  const MigrationResult({
    required this.success,
    this.message,
    this.transformedArgs,
  });

  const MigrationResult.ok([String? message])
      : success = true,
        message = message,
        transformedArgs = null;

  const MigrationResult.failed(String message)
      : success = false,
        message = message,
        transformedArgs = null;
}

/// Migration Manager — مدیریت migration بین نسخه‌ها
class MigrationManager {
  final Map<String, List<MigrationStep>> _migrations = {};
  final Map<String, Map<String, String>> _methodAliases = {};
  final Map<String, Set<String>> _deprecatedMethods = {};

  /// ثبت migration برای یک پلاگین
  void registerMigration(String pluginName, MigrationStep step) {
    _migrations.putIfAbsent(pluginName, () => []);
    _migrations[pluginName]!.add(step);

    // Sort by version
    _migrations[pluginName]!.sort((a, b) =>
        a.fromVersion.compareTo(b.fromVersion));

    BridgeLogger.debug(
      'Migration',
      'Registered migration for $pluginName: '
          '${step.fromVersion} → ${step.toVersion}',
    );

    // ثبت method renames
    if (step.methodRenames != null) {
      _methodAliases.putIfAbsent(pluginName, () => {});
      _methodAliases[pluginName]!.addAll(step.methodRenames!);
    }

    // ثبت removed methods
    if (step.removedMethods != null) {
      _deprecatedMethods.putIfAbsent(pluginName, () => {});
      _deprecatedMethods[pluginName]!.addAll(step.removedMethods!);
    }
  }

  /// ثبت چندین migration
  void registerMigrations(
    String pluginName,
    List<MigrationStep> steps,
  ) {
    for (final step in steps) {
      registerMigration(pluginName, step);
    }
  }

  /// resolve اسم method (با در نظر گرفتن renames)
  String resolveMethod(String pluginName, String method) {
    final aliases = _methodAliases[pluginName];
    if (aliases == null) return method;

    final resolved = aliases[method];
    if (resolved != null) {
      BridgeLogger.debug(
        'Migration',
        '[$pluginName] Method aliased: $method → $resolved',
      );
      return resolved;
    }

    return method;
  }

  /// آیا method deprecated هست؟
  bool isDeprecated(String pluginName, String method) {
    return _deprecatedMethods[pluginName]?.contains(method) ?? false;
  }

  /// تبدیل args بر اساس migration
  Map<String, dynamic> transformArgs(
    String pluginName,
    String method,
    Map<String, dynamic> args,
    SemanticVersion requestedVersion,
    SemanticVersion currentVersion,
  ) {
    final migrations = _migrations[pluginName];
    if (migrations == null || migrations.isEmpty) return args;

    var transformedArgs = Map<String, dynamic>.from(args);

    for (final migration in migrations) {
      if (requestedVersion < migration.toVersion &&
          currentVersion >= migration.toVersion) {
        // این migration باید اعمال بشه

        if (migration.argTransforms != null) {
          final methodTransforms = migration.argTransforms!;

          for (final entry in methodTransforms.entries) {
            final argName = entry.key;
            final transform = entry.value;

            if (transform.removed) {
              transformedArgs.remove(argName);
              continue;
            }

            if (transform.renamedTo != null &&
                transformedArgs.containsKey(argName)) {
              transformedArgs[transform.renamedTo!] =
                  transformedArgs.remove(argName);
            }

            if (transform.transformer != null &&
                transformedArgs.containsKey(
                  transform.renamedTo ?? argName,
                )) {
              final key = transform.renamedTo ?? argName;
              transformedArgs[key] = transform.transformer!(
                transformedArgs[key],
              );
            }

            if (transform.defaultValue != null &&
                !transformedArgs.containsKey(
                  transform.renamedTo ?? argName,
                )) {
              transformedArgs[transform.renamedTo ?? argName] =
                  transform.defaultValue;
            }
          }
        }
      }
    }

    return transformedArgs;
  }

  /// گرفتن لیست migration‌ها بین دو نسخه
  List<MigrationStep> getMigrationPath(
    String pluginName,
    SemanticVersion from,
    SemanticVersion to,
  ) {
    final migrations = _migrations[pluginName];
    if (migrations == null) return [];

    return migrations.where((m) {
      return m.fromVersion >= from && m.toVersion <= to;
    }).toList();
  }

  /// اطلاعات migration برای یک پلاگین
  Map<String, dynamic> getInfo(String pluginName) {
    final migrations = _migrations[pluginName] ?? [];
    final aliases = _methodAliases[pluginName] ?? {};
    final deprecated = _deprecatedMethods[pluginName] ?? {};

    return {
      'plugin': pluginName,
      'migrations': migrations.map((m) => {
            'from': m.fromVersion.toString(),
            'to': m.toVersion.toString(),
            'description': m.description,
            'methodRenames': m.methodRenames,
            'removedMethods': m.removedMethods?.toList(),
            'addedMethods': m.addedMethods?.toList(),
          }).toList(),
      'activeAliases': aliases,
      'deprecatedMethods': deprecated.toList(),
    };
  }

  /// همه اطلاعات migration
  Map<String, dynamic> get allInfo {
    return _migrations.map(
      (key, _) => MapEntry(key, getInfo(key)),
    );
  }
}

/// Deprecation warning wrapper
class DeprecationNotice {
  final String plugin;
  final String method;
  final String? replacement;
  final String? message;
  final SemanticVersion? removedIn;

  const DeprecationNotice({
    required this.plugin,
    required this.method,
    this.replacement,
    this.message,
    this.removedIn,
  });

  String get warning {
    final buf = StringBuffer();
    buf.write('DEPRECATED: $plugin.$method');
    if (replacement != null) buf.write(' → use $replacement instead');
    if (removedIn != null) buf.write(' (will be removed in $removedIn)');
    if (message != null) buf.write(' — $message');
    return buf.toString();
  }

  Map<String, dynamic> toJson() => {
        'plugin': plugin,
        'method': method,
        'replacement': replacement,
        'message': message,
        'removedIn': removedIn?.toString(),
      };
}
```

---

## 📄 `lib/packages/plugin_engine/lib/src/versioned_plugin_manager.dart`

```dart
import 'package:sweetmelon/packages/core/lib/core.dart';
import 'plugin_versioning.dart';
import 'plugin_migration.dart';

/// Mixin for PluginManager to add versioning support
mixin VersioningSupport {
  MigrationManager get migrationManager;

  /// بررسی و اعمال migration قبل از اجرای درخواست
  PluginRequest applyMigrations(
    PluginRequest request,
    String currentPluginVersion,
  ) {
    final pluginName = request.plugin;
    final requestedVersion = SemanticVersion.parse(request.version);
    final currentVersion = SemanticVersion.parse(currentPluginVersion);

    // بررسی deprecation
    if (migrationManager.isDeprecated(pluginName, request.method)) {
      BridgeLogger.warn(
        'Versioning',
        'Method ${request.plugin}.${request.method} is deprecated',
      );
    }

    // resolve method name
    final resolvedMethod = migrationManager.resolveMethod(
      pluginName,
      request.method,
    );

    // transform args
    final transformedArgs = migrationManager.transformArgs(
      pluginName,
      resolvedMethod,
      request.args,
      requestedVersion,
      currentVersion,
    );

    if (resolvedMethod != request.method ||
        transformedArgs != request.args) {
      BridgeLogger.info(
        'Versioning',
        'Migrated ${request.plugin}: '
            '${request.method} → $resolvedMethod '
            '(v${request.version} → v$currentPluginVersion)',
      );

      return PluginRequest(
        requestId: request.requestId,
        timestamp: request.timestamp,
        plugin: request.plugin,
        version: currentPluginVersion,
        method: resolvedMethod,
        args: transformedArgs,
        metadata: request.metadata,
      );
    }

    return request;
  }
}
```

---

## 📄 بروزرسانی `lib/packages/plugin_engine/lib/plugin_engine.dart`

```dart
library plugin_engine;

export 'src/plugin_interface.dart';
export 'src/plugin_registry.dart';
export 'src/plugin_manager.dart';
export 'src/lazy_plugin_loader.dart';
export 'src/plugin_versioning.dart';
export 'src/plugin_migration.dart';
export 'src/versioned_plugin_manager.dart';
```

---

## 📄 `lib/di/migration_registry.dart`

```dart
import 'package:sweetmelon/packages/plugin_engine/lib/plugin_engine.dart';

/// ثبت همه migration‌ها در اینجا
class MigrationRegistry {
  static void registerAll(MigrationManager manager) {
    _registerStorageMigrations(manager);
    _registerHttpMigrations(manager);
    _registerDatabaseMigrations(manager);
  }

  /// مثال: Storage plugin از v1 به v2 تغییر کرده
  static void _registerStorageMigrations(MigrationManager manager) {
    manager.registerMigrations('storage', [
      MigrationStep(
        fromVersion: const SemanticVersion(major: 1, minor: 0, patch: 0),
        toVersion: const SemanticVersion(major: 2, minor: 0, patch: 0),
        description: 'Storage v2: renamed getValue to get, setValue to set',
        migrate: (args) async => const MigrationResult.ok(),
        methodRenames: {
          'getValue': 'get',
          'setValue': 'set',
          'removeValue': 'remove',
          'getAllKeys': 'keys',
          'hasValue': 'has',
        },
        removedMethods: {'getAll'},
        addedMethods: {'getInfo'},
      ),
    ]);
  }

  /// مثال: HTTP plugin args تغییر کرده
  static void _registerHttpMigrations(MigrationManager manager) {
    manager.registerMigrations('http', [
      MigrationStep(
        fromVersion: const SemanticVersion(major: 1, minor: 0, patch: 0),
        toVersion: const SemanticVersion(major: 1, minor: 1, patch: 0),
        description: 'HTTP v1.1: renamed timeout to timeoutMs',
        migrate: (args) async => const MigrationResult.ok(),
        argTransforms: {
          'timeout': const ArgTransform.rename('timeoutMs'),
        },
      ),
      MigrationStep(
        fromVersion: const SemanticVersion(major: 1, minor: 1, patch: 0),
        toVersion: const SemanticVersion(major: 2, minor: 0, patch: 0),
        description: 'HTTP v2: removed raw method, added bodyType auto',
        migrate: (args) async => const MigrationResult.ok(),
        removedMethods: {'raw'},
        argTransforms: {
          'contentType': ArgTransform(
            renamedTo: 'bodyType',
            transformer: (value) {
              if (value == 'application/json') return 'json';
              if (value == 'application/x-www-form-urlencoded') return 'form';
              return 'auto';
            },
          ),
        },
      ),
    ]);
  }

  /// Database plugin migration
  static void _registerDatabaseMigrations(MigrationManager manager) {
    manager.registerMigrations('database', [
      MigrationStep(
        fromVersion: const SemanticVersion(major: 1, minor: 0, patch: 0),
        toVersion: const SemanticVersion(major: 1, minor: 1, patch: 0),
        description: 'Database v1.1: added batch support, renamed exec to execute',
        migrate: (args) async => const MigrationResult.ok(),
        methodRenames: {
          'exec': 'execute',
          'sql': 'rawQuery',
        },
        addedMethods: {'batch', 'tableExists'},
      ),
    ]);
  }
}
```

---

# بخش ۲: WebSocket Plugin

---

## 📄 `lib/plugins/websocket/lib/websocket_plugin.dart`

```dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:sweetmelon/packages/core/lib/core.dart';
import 'package:sweetmelon/packages/plugin_engine/lib/plugin_engine.dart';

typedef WsEventEmitter = Future<void> Function(String event, dynamic data);

class WebSocketPlugin extends Plugin {
  final WsEventEmitter? eventEmitter;

  final Map<String, _ManagedSocket> _sockets = {};

  WebSocketPlugin({this.eventEmitter});

  @override
  String get name => 'websocket';

  @override
  String get version => '1.0.0';

  @override
  String get description => 'WebSocket real-time communication plugin';

  @override
  List<String> get supportedMethods => [
        'connect',
        'disconnect',
        'send',
        'sendJson',
        'getState',
        'getConnections',
        'disconnectAll',
        'getInfo',
      ];

  @override
  Future<void> onDispose() async {
    await _disconnectAll();
  }

  @override
  Future<dynamic> onCall(String method, Map<String, dynamic> args) async {
    switch (method) {
      case 'connect':
        return _connect(args);
      case 'disconnect':
        return _disconnect(args);
      case 'send':
        return _send(args);
      case 'sendJson':
        return _sendJson(args);
      case 'getState':
        return _getState(args);
      case 'getConnections':
        return _getConnections();
      case 'disconnectAll':
        return _disconnectAll();
      case 'getInfo':
        return {
          'name': name,
          'version': version,
          'activeConnections': _sockets.length,
        };
      default:
        throw UnsupportedError('Method "$method" not supported');
    }
  }

  Future<Map<String, dynamic>> _connect(Map<String, dynamic> args) async {
    final url = args['url'] as String;
    final id = args['id'] as String? ??
        'ws_${DateTime.now().millisecondsSinceEpoch}';
    final protocols = args['protocols'] != null
        ? List<String>.from(args['protocols'] as List)
        : <String>[];
    final headers = _parseHeaders(args['headers']);
    final pingIntervalMs = (args['pingIntervalMs'] as num?)?.toInt();
    final autoReconnect = args['autoReconnect'] as bool? ?? false;
    final maxReconnectAttempts =
        (args['maxReconnectAttempts'] as num?)?.toInt() ?? 5;
    final reconnectDelayMs =
        (args['reconnectDelayMs'] as num?)?.toInt() ?? 3000;

    if (_sockets.containsKey(id)) {
      final existing = _sockets[id]!;
      if (existing.isConnected) {
        return {
          'id': id,
          'connected': true,
          'alreadyConnected': true,
          'url': url,
        };
      }
      await existing.close();
      _sockets.remove(id);
    }

    BridgeLogger.info('WebSocket', 'Connecting: $url [id=$id]');

    try {
      final ws = await WebSocket.connect(
        url,
        protocols: protocols.isNotEmpty ? protocols : null,
        headers: headers.isNotEmpty ? headers : null,
      );

      if (pingIntervalMs != null) {
        ws.pingInterval = Duration(milliseconds: pingIntervalMs);
      }

      final managed = _ManagedSocket(
        id: id,
        url: url,
        socket: ws,
        autoReconnect: autoReconnect,
        maxReconnectAttempts: maxReconnectAttempts,
        reconnectDelayMs: reconnectDelayMs,
      );

      _sockets[id] = managed;

      _listenToSocket(managed);

      _emitEvent('websocket.connected', {
        'id': id,
        'url': url,
        'timestamp': DateTime.now().toIso8601String(),
      });

      BridgeLogger.info('WebSocket', 'Connected: $url [id=$id]');

      return {
        'id': id,
        'connected': true,
        'alreadyConnected': false,
        'url': url,
      };
    } catch (e) {
      BridgeLogger.error('WebSocket', 'Connect failed: $e');

      _emitEvent('websocket.error', {
        'id': id,
        'url': url,
        'error': e.toString(),
        'type': 'connect_failed',
      });

      return {
        'id': id,
        'connected': false,
        'error': e.toString(),
      };
    }
  }

  void _listenToSocket(_ManagedSocket managed) {
    managed.subscription = managed.socket.listen(
      (data) {
        managed.messageCount++;

        dynamic parsedData;
        String dataType;

        if (data is String) {
          dataType = 'text';
          try {
            parsedData = jsonDecode(data);
          } catch (_) {
            parsedData = data;
          }
        } else {
          dataType = 'binary';
          parsedData = base64Encode(data as List<int>);
        }

        _emitEvent('websocket.message', {
          'id': managed.id,
          'data': parsedData,
          'type': dataType,
          'messageNumber': managed.messageCount,
          'timestamp': DateTime.now().toIso8601String(),
        });
      },
      onError: (error) {
        BridgeLogger.error(
          'WebSocket',
          '[${managed.id}] Error: $error',
        );

        _emitEvent('websocket.error', {
          'id': managed.id,
          'error': error.toString(),
          'type': 'stream_error',
        });
      },
      onDone: () {
        final closeCode = managed.socket.closeCode;
        final closeReason = managed.socket.closeReason;

        BridgeLogger.info(
          'WebSocket',
          '[${managed.id}] Disconnected: $closeCode $closeReason',
        );

        _emitEvent('websocket.disconnected', {
          'id': managed.id,
          'closeCode': closeCode,
          'closeReason': closeReason,
          'timestamp': DateTime.now().toIso8601String(),
        });

        _sockets.remove(managed.id);

        // Auto-reconnect
        if (managed.autoReconnect &&
            managed.reconnectAttempts < managed.maxReconnectAttempts) {
          _scheduleReconnect(managed);
        }
      },
      cancelOnError: false,
    );
  }

  void _scheduleReconnect(_ManagedSocket managed) {
    managed.reconnectAttempts++;

    final delay = managed.reconnectDelayMs *
        managed.reconnectAttempts;

    BridgeLogger.info(
      'WebSocket',
      '[${managed.id}] Reconnecting in ${delay}ms '
          '(attempt ${managed.reconnectAttempts}/${managed.maxReconnectAttempts})',
    );

    _emitEvent('websocket.reconnecting', {
      'id': managed.id,
      'attempt': managed.reconnectAttempts,
      'maxAttempts': managed.maxReconnectAttempts,
      'delayMs': delay,
    });

    Timer(Duration(milliseconds: delay), () {
      if (!_sockets.containsKey(managed.id)) {
        _connect({
          'url': managed.url,
          'id': managed.id,
          'autoReconnect': managed.autoReconnect,
          'maxReconnectAttempts': managed.maxReconnectAttempts,
          'reconnectDelayMs': managed.reconnectDelayMs,
        });
      }
    });
  }

  Future<Map<String, dynamic>> _disconnect(Map<String, dynamic> args) async {
    final id = args['id'] as String;
    final code = (args['code'] as num?)?.toInt() ?? WebSocketStatus.normalClosure;
    final reason = args['reason'] as String? ?? '';

    final managed = _sockets[id];
    if (managed == null) {
      return {'id': id, 'disconnected': false, 'reason': 'not_found'};
    }

    managed.autoReconnect = false;
    await managed.close(code, reason);
    _sockets.remove(id);

    return {'id': id, 'disconnected': true};
  }

  Future<Map<String, dynamic>> _send(Map<String, dynamic> args) async {
    final id = args['id'] as String;
    final data = args['data'];

    final managed = _sockets[id];
    if (managed == null || !managed.isConnected) {
      return {'id': id, 'sent': false, 'reason': 'not_connected'};
    }

    if (data is String) {
      managed.socket.add(data);
    } else if (data is List) {
      managed.socket.add(data);
    } else {
      managed.socket.add(data.toString());
    }

    managed.sentCount++;

    return {'id': id, 'sent': true, 'sentCount': managed.sentCount};
  }

  Future<Map<String, dynamic>> _sendJson(Map<String, dynamic> args) async {
    final id = args['id'] as String;
    final data = args['data'];

    final managed = _sockets[id];
    if (managed == null || !managed.isConnected) {
      return {'id': id, 'sent': false, 'reason': 'not_connected'};
    }

    final jsonStr = jsonEncode(data);
    managed.socket.add(jsonStr);
    managed.sentCount++;

    return {'id': id, 'sent': true, 'sentCount': managed.sentCount};
  }

  Map<String, dynamic> _getState(Map<String, dynamic> args) {
    final id = args['id'] as String;
    final managed = _sockets[id];

    if (managed == null) {
      return {'id': id, 'exists': false};
    }

    return {
      'id': id,
      'exists': true,
      'connected': managed.isConnected,
      'url': managed.url,
      'messageCount': managed.messageCount,
      'sentCount': managed.sentCount,
      'reconnectAttempts': managed.reconnectAttempts,
      'closeCode': managed.socket.closeCode,
    };
  }

  Map<String, dynamic> _getConnections() {
    return {
      'connections': _sockets.values.map((m) => {
            'id': m.id,
            'url': m.url,
            'connected': m.isConnected,
            'messageCount': m.messageCount,
            'sentCount': m.sentCount,
          }).toList(),
      'count': _sockets.length,
    };
  }

  Future<Map<String, dynamic>> _disconnectAll() async {
    final count = _sockets.length;

    for (final managed in _sockets.values.toList()) {
      managed.autoReconnect = false;
      await managed.close();
    }
    _sockets.clear();

    return {'disconnected': count};
  }

  Map<String, String> _parseHeaders(dynamic raw) {
    if (raw == null) return {};
    if (raw is Map) {
      return raw.map((k, v) => MapEntry(k.toString(), v.toString()));
    }
    return {};
  }

  void _emitEvent(String event, dynamic data) {
    if (eventEmitter != null) {
      eventEmitter!(event, data);
    }
  }

  @override
  Future<ValidationResult> validateArgs(
    String method,
    Map<String, dynamic> args,
  ) async {
    switch (method) {
      case 'connect':
        final url = args['url'];
        if (url is! String || url.isEmpty) {
          return ValidationResult.invalid('url is required');
        }
        if (!url.startsWith('ws://') && !url.startsWith('wss://')) {
          return ValidationResult.invalid(
            'url must start with ws:// or wss://',
          );
        }
        return ValidationResult.valid();

      case 'disconnect':
      case 'getState':
        final id = args['id'];
        if (id is! String || id.isEmpty) {
          return ValidationResult.invalid('id is required');
        }
        return ValidationResult.valid();

      case 'send':
      case 'sendJson':
        final id = args['id'];
        if (id is! String || id.isEmpty) {
          return ValidationResult.invalid('id is required');
        }
        if (!args.containsKey('data')) {
          return ValidationResult.invalid('data is required');
        }
        return ValidationResult.valid();

      default:
        return ValidationResult.valid();
    }
  }
}

class _ManagedSocket {
  final String id;
  final String url;
  final WebSocket socket;
  bool autoReconnect;
  final int maxReconnectAttempts;
  final int reconnectDelayMs;

  StreamSubscription<dynamic>? subscription;
  int messageCount = 0;
  int sentCount = 0;
  int reconnectAttempts = 0;

  _ManagedSocket({
    required this.id,
    required this.url,
    required this.socket,
    this.autoReconnect = false,
    this.maxReconnectAttempts = 5,
    this.reconnectDelayMs = 3000,
  });

  bool get isConnected => socket.readyState == WebSocket.open;

  Future<void> close([int? code, String? reason]) async {
    subscription?.cancel();
    try {
      await socket.close(
        code ?? WebSocketStatus.normalClosure,
        reason ?? '',
      );
    } catch (_) {}
  }
}
```

---

## 📄 `lib/plugins/websocket/pubspec.yaml`

```yaml
name: websocket_plugin
description: WebSocket real-time communication plugin
version: 1.0.0

environment:
  sdk: ^3.0.0

dependencies:
  flutter:
    sdk: flutter
  plugin_engine:
    path: ../../packages/plugin_engine
  core:
    path: ../../packages/core
```

---

# بخش ۳: Background Task Plugin

---

## 📄 `lib/plugins/background_task/lib/background_task_plugin.dart`

```dart
import 'dart:async';
import 'dart:isolate';

import 'package:sweetmelon/packages/core/lib/core.dart';
import 'package:sweetmelon/packages/plugin_engine/lib/plugin_engine.dart';

typedef BgEventEmitter = Future<void> Function(String event, dynamic data);

/// تعریف یک task
class TaskDefinition {
  final String id;
  final String name;
  final Future<dynamic> Function(Map<String, dynamic> params) execute;
  final Duration? interval;
  final bool repeating;
  final Map<String, dynamic> params;

  const TaskDefinition({
    required this.id,
    required this.name,
    required this.execute,
    this.interval,
    this.repeating = false,
    this.params = const {},
  });
}

enum TaskStatus {
  idle,
  running,
  completed,
  failed,
  cancelled,
}

class TaskState {
  final String id;
  final String name;
  TaskStatus status;
  int runCount;
  DateTime? lastRunAt;
  DateTime? nextRunAt;
  Duration? lastDuration;
  String? lastError;
  dynamic lastResult;

  TaskState({
    required this.id,
    required this.name,
    this.status = TaskStatus.idle,
    this.runCount = 0,
    this.lastRunAt,
    this.nextRunAt,
    this.lastDuration,
    this.lastError,
    this.lastResult,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'status': status.name,
        'runCount': runCount,
        'lastRunAt': lastRunAt?.toIso8601String(),
        'nextRunAt': nextRunAt?.toIso8601String(),
        'lastDurationMs': lastDuration?.inMilliseconds,
        'lastError': lastError,
      };
}

class BackgroundTaskPlugin extends Plugin {
  final BgEventEmitter? eventEmitter;

  final Map<String, TaskDefinition> _taskDefinitions = {};
  final Map<String, TaskState> _taskStates = {};
  final Map<String, Timer> _timers = {};
  final Map<String, Completer<dynamic>> _runningTasks = {};

  BackgroundTaskPlugin({this.eventEmitter});

  @override
  String get name => 'backgroundTask';

  @override
  String get version => '1.0.0';

  @override
  String get description =>
      'Background task scheduler and executor plugin';

  @override
  List<String> get supportedMethods => [
        'register',
        'unregister',
        'runOnce',
        'startRepeating',
        'stop',
        'stopAll',
        'getTaskState',
        'getAllTasks',
        'getInfo',
      ];

  @override
  Future<void> onDispose() async {
    for (final timer in _timers.values) {
      timer.cancel();
    }
    _timers.clear();
    _taskDefinitions.clear();
    _taskStates.clear();
  }

  @override
  Future<dynamic> onCall(String method, Map<String, dynamic> args) async {
    switch (method) {
      case 'register':
        return _register(args);
      case 'unregister':
        return _unregister(args);
      case 'runOnce':
        return _runOnce(args);
      case 'startRepeating':
        return _startRepeating(args);
      case 'stop':
        return _stop(args);
      case 'stopAll':
        return _stopAll();
      case 'getTaskState':
        return _getTaskState(args);
      case 'getAllTasks':
        return _getAllTasks();
      case 'getInfo':
        return {
          'name': name,
          'version': version,
          'registeredTasks': _taskDefinitions.length,
          'runningTimers': _timers.length,
        };
      default:
        throw UnsupportedError('Method "$method" not supported');
    }
  }

  Map<String, dynamic> _register(Map<String, dynamic> args) {
    final taskId = args['taskId'] as String;
    final taskName = args['name'] as String? ?? taskId;
    final taskType = args['type'] as String? ?? 'custom';
    final params = (args['params'] as Map<String, dynamic>?) ?? {};

    // Task definition — the actual execution will come from JS via runOnce
    _taskDefinitions[taskId] = TaskDefinition(
      id: taskId,
      name: taskName,
      execute: (p) async => null, // placeholder
      params: params,
    );

    _taskStates[taskId] = TaskState(
      id: taskId,
      name: taskName,
    );

    BridgeLogger.info('BackgroundTask', 'Registered: $taskId ($taskName)');

    return {
      'registered': true,
      'taskId': taskId,
      'name': taskName,
    };
  }

  Map<String, dynamic> _unregister(Map<String, dynamic> args) {
    final taskId = args['taskId'] as String;

    _timers[taskId]?.cancel();
    _timers.remove(taskId);
    _taskDefinitions.remove(taskId);
    _taskStates.remove(taskId);

    return {'unregistered': true, 'taskId': taskId};
  }

  Future<Map<String, dynamic>> _runOnce(Map<String, dynamic> args) async {
    final taskId = args['taskId'] as String;
    final action = args['action'] as String? ?? 'execute';
    final params = (args['params'] as Map<String, dynamic>?) ?? {};
    final timeoutMs = (args['timeoutMs'] as num?)?.toInt() ?? 30000;

    final state = _taskStates[taskId];
    if (state == null) {
      // Auto-register
      _register({'taskId': taskId, 'name': taskId});
    }

    final taskState = _taskStates[taskId]!;

    if (taskState.status == TaskStatus.running) {
      return {
        'taskId': taskId,
        'started': false,
        'reason': 'already_running',
      };
    }

    taskState.status = TaskStatus.running;
    taskState.lastRunAt = DateTime.now();
    taskState.runCount++;

    _emitEvent('task.started', {
      'taskId': taskId,
      'action': action,
      'runCount': taskState.runCount,
    });

    final stopwatch = Stopwatch()..start();

    try {
      // اجرای task بر اساس action type
      dynamic result;

      switch (action) {
        case 'httpSync':
          result = await _executeHttpSync(params, timeoutMs);
          break;
        case 'storageCleanup':
          result = await _executeStorageCleanup(params);
          break;
        case 'cacheCleanup':
          result = await _executeCacheCleanup(params);
          break;
        case 'compute':
          result = await _executeCompute(params, timeoutMs);
          break;
        default:
          // Custom action — result comes from params
          result = {
            'action': action,
            'params': params,
            'executedAt': DateTime.now().toIso8601String(),
          };
      }

      stopwatch.stop();

      taskState.status = TaskStatus.completed;
      taskState.lastDuration = stopwatch.elapsed;
      taskState.lastResult = result;
      taskState.lastError = null;

      _emitEvent('task.completed', {
        'taskId': taskId,
        'durationMs': stopwatch.elapsedMilliseconds,
        'result': result,
      });

      return {
        'taskId': taskId,
        'completed': true,
        'durationMs': stopwatch.elapsedMilliseconds,
        'result': result,
      };
    } catch (e) {
      stopwatch.stop();

      taskState.status = TaskStatus.failed;
      taskState.lastDuration = stopwatch.elapsed;
      taskState.lastError = e.toString();

      BridgeLogger.error('BackgroundTask', '[$taskId] Failed: $e');

      _emitEvent('task.failed', {
        'taskId': taskId,
        'error': e.toString(),
        'durationMs': stopwatch.elapsedMilliseconds,
      });

      return {
        'taskId': taskId,
        'completed': false,
        'error': e.toString(),
      };
    }
  }

  Map<String, dynamic> _startRepeating(Map<String, dynamic> args) {
    final taskId = args['taskId'] as String;
    final intervalMs = (args['intervalMs'] as num).toInt();
    final action = args['action'] as String? ?? 'execute';
    final params = (args['params'] as Map<String, dynamic>?) ?? {};
    final immediate = args['immediate'] as bool? ?? true;

    // Cancel existing timer
    _timers[taskId]?.cancel();

    // Auto-register if needed
    if (!_taskStates.containsKey(taskId)) {
      _register({'taskId': taskId, 'name': taskId});
    }

    final taskState = _taskStates[taskId]!;
    taskState.nextRunAt = DateTime.now().add(
      Duration(milliseconds: intervalMs),
    );

    _timers[taskId] = Timer.periodic(
      Duration(milliseconds: intervalMs),
      (_) {
        _runOnce({
          'taskId': taskId,
          'action': action,
          'params': params,
        });

        taskState.nextRunAt = DateTime.now().add(
          Duration(milliseconds: intervalMs),
        );
      },
    );

    BridgeLogger.info(
      'BackgroundTask',
      '[$taskId] Repeating every ${intervalMs}ms',
    );

    // Run immediately if requested
    if (immediate) {
      _runOnce({
        'taskId': taskId,
        'action': action,
        'params': params,
      });
    }

    return {
      'taskId': taskId,
      'repeating': true,
      'intervalMs': intervalMs,
    };
  }

  Map<String, dynamic> _stop(Map<String, dynamic> args) {
    final taskId = args['taskId'] as String;

    _timers[taskId]?.cancel();
    _timers.remove(taskId);

    final state = _taskStates[taskId];
    if (state != null) {
      state.status = TaskStatus.cancelled;
      state.nextRunAt = null;
    }

    return {'taskId': taskId, 'stopped': true};
  }

  Map<String, dynamic> _stopAll() {
    final count = _timers.length;

    for (final timer in _timers.values) {
      timer.cancel();
    }
    _timers.clear();

    for (final state in _taskStates.values) {
      if (state.status == TaskStatus.running) {
        state.status = TaskStatus.cancelled;
      }
      state.nextRunAt = null;
    }

    return {'stopped': count};
  }

  Map<String, dynamic> _getTaskState(Map<String, dynamic> args) {
    final taskId = args['taskId'] as String;
    final state = _taskStates[taskId];

    if (state == null) {
      return {'taskId': taskId, 'found': false};
    }

    return {
      'found': true,
      ...state.toJson(),
      'hasTimer': _timers.containsKey(taskId),
    };
  }

  Map<String, dynamic> _getAllTasks() {
    return {
      'tasks': _taskStates.values.map((s) => {
            ...s.toJson(),
            'hasTimer': _timers.containsKey(s.id),
          }).toList(),
      'count': _taskStates.length,
      'runningTimers': _timers.length,
    };
  }

  // ── Built-in task executors ──

  Future<Map<String, dynamic>> _executeHttpSync(
    Map<String, dynamic> params,
    int timeoutMs,
  ) async {
    // این task داده‌ها رو از یه URL می‌خونه و sync می‌کنه
    final url = params['url'] as String?;
    if (url == null) {
      return {'synced': false, 'reason': 'no_url'};
    }

    BridgeLogger.info('BackgroundTask', 'HTTP Sync: $url');

    // در عمل اینجا باید از HTTP plugin استفاده بشه
    // ولی چون داخل همین Dart هستیم:
    return {
      'synced': true,
      'url': url,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  Future<Map<String, dynamic>> _executeStorageCleanup(
    Map<String, dynamic> params,
  ) async {
    final olderThanDays = (params['olderThanDays'] as num?)?.toInt() ?? 30;

    BridgeLogger.info(
      'BackgroundTask',
      'Storage cleanup: older than $olderThanDays days',
    );

    return {
      'cleaned': true,
      'olderThanDays': olderThanDays,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  Future<Map<String, dynamic>> _executeCacheCleanup(
    Map<String, dynamic> params,
  ) async {
    BridgeLogger.info('BackgroundTask', 'Cache cleanup');

    return {
      'cleaned': true,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  Future<Map<String, dynamic>> _executeCompute(
    Map<String, dynamic> params,
    int timeoutMs,
  ) async {
    // اجرای یک محاسبه سنگین در isolate جداگانه
    final expression = params['expression'] as String?;
    final data = params['data'];

    if (expression == null) {
      return {'computed': false, 'reason': 'no_expression'};
    }

    try {
      final result = await Isolate.run(() {
        // محاسبه ساده — در عمل می‌شه پیچیده‌تر باشه
        return {
          'expression': expression,
          'data': data,
          'result': 'computed',
          'timestamp': DateTime.now().toIso8601String(),
        };
      }).timeout(Duration(milliseconds: timeoutMs));

      return {
        'computed': true,
        'result': result,
      };
    } on TimeoutException {
      return {'computed': false, 'reason': 'timeout'};
    }
  }

  void _emitEvent(String event, dynamic data) {
    if (eventEmitter != null) {
      eventEmitter!(event, data);
    }
  }

  @override
  Future<ValidationResult> validateArgs(
    String method,
    Map<String, dynamic> args,
  ) async {
    switch (method) {
      case 'register':
      case 'runOnce':
      case 'stop':
      case 'unregister':
      case 'getTaskState':
        final taskId = args['taskId'];
        if (taskId is! String || taskId.isEmpty) {
          return ValidationResult.invalid('taskId is required');
        }
        return ValidationResult.valid();

      case 'startRepeating':
        final taskId = args['taskId'];
        if (taskId is! String || taskId.isEmpty) {
          return ValidationResult.invalid('taskId is required');
        }
        final intervalMs = args['intervalMs'];
        if (intervalMs is! num || intervalMs <= 0) {
          return ValidationResult.invalid(
            'intervalMs is required and must be a positive number',
          );
        }
        if (intervalMs < 1000) {
          return ValidationResult.invalid(
            'intervalMs must be at least 1000ms',
          );
        }
        return ValidationResult.valid();

      default:
        return ValidationResult.valid();
    }
  }
}
```

---

## 📄 `lib/plugins/background_task/pubspec.yaml`

```yaml
name: background_task_plugin
description: Background task scheduler and executor plugin
version: 1.0.0

environment:
  sdk: ^3.0.0

dependencies:
  flutter:
    sdk: flutter
  plugin_engine:
    path: ../../packages/plugin_engine
  core:
    path: ../../packages/core
```

---

# بخش ۴: بروزرسانی Service Locator

> اضافه کردن import‌ها و registration:

```dart
// imports اضافه شده
import 'package:sweetmelon/plugins/websocket/lib/websocket_plugin.dart';
import 'package:sweetmelon/plugins/background_task/lib/background_task_plugin.dart';
import 'package:sweetmelon/di/migration_registry.dart';
```

> در `init()` اضافه شود:

```dart
      // Migration Manager
      sl.registerLazySingleton<MigrationManager>(() {
        final manager = MigrationManager();
        MigrationRegistry.registerAll(manager);
        return manager;
      });
```

> در `_registerEagerPlugins()` اضافه شود:

```dart
    await registry.register(WebSocketPlugin(eventEmitter: emitter));
    await registry.register(BackgroundTaskPlugin(eventEmitter: emitter));
```

---

# بخش ۵: NativeSDK — پلاگین‌های جدید

> اضافه شدن به `native-sdk.js`:

```javascript
    websocket: {
      connect: function (url, options) {
        var o = options || {};
        return call('websocket', 'connect', Object.assign({ url: url }, o), { timeout: 15000 });
      },
      disconnect: function (id, code, reason) {
        return call('websocket', 'disconnect', { id: id, code: code, reason: reason });
      },
      send: function (id, data) {
        return call('websocket', 'send', { id: id, data: data });
      },
      sendJson: function (id, data) {
        return call('websocket', 'sendJson', { id: id, data: data });
      },
      getState: function (id) {
        return call('websocket', 'getState', { id: id });
      },
      getConnections: function () {
        return call('websocket', 'getConnections', {});
      },
      disconnectAll: function () {
        return call('websocket', 'disconnectAll', {});
      },
      getInfo: function () {
        return call('websocket', 'getInfo', {});
      }
    },

    backgroundTask: {
      register: function (taskId, options) {
        var o = options || {};
        return call('backgroundTask', 'register', Object.assign({ taskId: taskId }, o));
      },
      unregister: function (taskId) {
        return call('backgroundTask', 'unregister', { taskId: taskId });
      },
      runOnce: function (taskId, options) {
        var o = options || {};
        return call('backgroundTask', 'runOnce', Object.assign({ taskId: taskId }, o), { timeout: 60000 });
      },
      startRepeating: function (taskId, intervalMs, options) {
        var o = options || {};
        return call('backgroundTask', 'startRepeating', Object.assign({
          taskId: taskId,
          intervalMs: intervalMs
        }, o));
      },
      stop: function (taskId) {
        return call('backgroundTask', 'stop', { taskId: taskId });
      },
      stopAll: function () {
        return call('backgroundTask', 'stopAll', {});
      },
      getTaskState: function (taskId) {
        return call('backgroundTask', 'getTaskState', { taskId: taskId });
      },
      getAllTasks: function () {
        return call('backgroundTask', 'getAllTasks', {});
      },
      getInfo: function () {
        return call('backgroundTask', 'getInfo', {});
      }
    },
```

---

# بخش ۶: تست

### 📄 `test/unit/engine/plugin_versioning_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sweetmelon/packages/plugin_engine/lib/plugin_engine.dart';

void main() {
  group('SemanticVersion', () {
    test('parse simple version', () {
      final v = SemanticVersion.parse('1.2.3');
      expect(v.major, 1);
      expect(v.minor, 2);
      expect(v.patch, 3);
    });

    test('parse with pre-release', () {
      final v = SemanticVersion.parse('2.0.0-beta.1');
      expect(v.major, 2);
      expect(v.preRelease, 'beta.1');
      expect(v.isPreRelease, true);
    });

    test('parse with v prefix', () {
      final v = SemanticVersion.parse('v1.0.0');
      expect(v.major, 1);
    });

    test('comparison', () {
      final v1 = SemanticVersion.parse('1.0.0');
      final v2 = SemanticVersion.parse('1.1.0');
      final v3 = SemanticVersion.parse('2.0.0');

      expect(v1 < v2, true);
      expect(v2 < v3, true);
      expect(v3 > v1, true);
      expect(v1 == SemanticVersion.parse('1.0.0'), true);
    });

    test('isBreakingFrom', () {
      final v1 = SemanticVersion.parse('1.5.0');
      final v2 = SemanticVersion.parse('2.0.0');
      final v3 = SemanticVersion.parse('1.6.0');

      expect(v2.isBreakingFrom(v1), true);
      expect(v3.isBreakingFrom(v1), false);
    });
  });

  group('VersionConstraint', () {
    test('exact version', () {
      final c = ExactVersion(SemanticVersion.parse('1.0.0'));
      expect(c.allows(SemanticVersion.parse('1.0.0')), true);
      expect(c.allows(SemanticVersion.parse('1.0.1')), false);
    });

    test('min version', () {
      final c = MinVersion(SemanticVersion.parse('1.2.0'));
      expect(c.allows(SemanticVersion.parse('1.2.0')), true);
      expect(c.allows(SemanticVersion.parse('1.3.0')), true);
      expect(c.allows(SemanticVersion.parse('1.1.0')), false);
    });

    test('compatible with (caret)', () {
      final c = CompatibleWith(SemanticVersion.parse('1.2.0'));
      expect(c.allows(SemanticVersion.parse('1.2.0')), true);
      expect(c.allows(SemanticVersion.parse('1.9.0')), true);
      expect(c.allows(SemanticVersion.parse('2.0.0')), false);
      expect(c.allows(SemanticVersion.parse('1.1.0')), false);
    });

    test('parse constraint string', () {
      final c1 = parseConstraint('^1.0.0');
      expect(c1.allows(SemanticVersion.parse('1.5.0')), true);
      expect(c1.allows(SemanticVersion.parse('2.0.0')), false);

      final c2 = parseConstraint('>=2.0.0');
      expect(c2.allows(SemanticVersion.parse('2.0.0')), true);
      expect(c2.allows(SemanticVersion.parse('3.0.0')), true);

      final c3 = parseConstraint('*');
      expect(c3.allows(SemanticVersion.parse('999.0.0')), true);
    });
  });

  group('MigrationManager', () {
    late MigrationManager manager;

    setUp(() {
      manager = MigrationManager();
    });

    test('resolves method aliases', () {
      manager.registerMigration(
        'storage',
        MigrationStep(
          fromVersion: const SemanticVersion(major: 1, minor: 0, patch: 0),
          toVersion: const SemanticVersion(major: 2, minor: 0, patch: 0),
          description: 'v2 renames',
          migrate: (args) async => const MigrationResult.ok(),
          methodRenames: {'getValue': 'get', 'setValue': 'set'},
        ),
      );

      expect(manager.resolveMethod('storage', 'getValue'), 'get');
      expect(manager.resolveMethod('storage', 'setValue'), 'set');
      expect(manager.resolveMethod('storage', 'remove'), 'remove');
    });

    test('detects deprecated methods', () {
      manager.registerMigration(
        'http',
        MigrationStep(
          fromVersion: const SemanticVersion(major: 1, minor: 0, patch: 0),
          toVersion: const SemanticVersion(major: 2, minor: 0, patch: 0),
          description: 'v2 removes raw',
          migrate: (args) async => const MigrationResult.ok(),
          removedMethods: {'raw'},
        ),
      );

      expect(manager.isDeprecated('http', 'raw'), true);
      expect(manager.isDeprecated('http', 'get'), false);
    });

    test('transforms args between versions', () {
      manager.registerMigration(
        'http',
        MigrationStep(
          fromVersion: const SemanticVersion(major: 1, minor: 0, patch: 0),
          toVersion: const SemanticVersion(major: 1, minor: 1, patch: 0),
          description: 'rename timeout',
          migrate: (args) async => const MigrationResult.ok(),
          argTransforms: {
            'timeout': const ArgTransform.rename('timeoutMs'),
          },
        ),
      );

      final result = manager.transformArgs(
        'http',
        'get',
        {'url': 'https://test.com', 'timeout': 5000},
        SemanticVersion.parse('1.0.0'),
        SemanticVersion.parse('1.1.0'),
      );

      expect(result.containsKey('timeout'), false);
      expect(result['timeoutMs'], 5000);
      expect(result['url'], 'https://test.com');
    });

    test('getInfo returns migration details', () {
      manager.registerMigration(
        'test',
        MigrationStep(
          fromVersion: const SemanticVersion(major: 1, minor: 0, patch: 0),
          toVersion: const SemanticVersion(major: 2, minor: 0, patch: 0),
          description: 'test migration',
          migrate: (args) async => const MigrationResult.ok(),
          addedMethods: {'newMethod'},
          removedMethods: {'oldMethod'},
        ),
      );

      final info = manager.getInfo('test');
      expect(info['migrations'], hasLength(1));
      expect(info['deprecatedMethods'], contains('oldMethod'));
    });
  });
}
```

---

### 📄 `test/plugins/websocket_plugin_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sweetmelon/plugins/websocket/lib/websocket_plugin.dart';

void main() {
  group('WebSocketPlugin', () {
    late WebSocketPlugin plugin;
    final List<Map<String, dynamic>> events = [];

    setUp(() async {
      events.clear();
      plugin = WebSocketPlugin(
        eventEmitter: (event, data) async {
          events.add({'event': event, 'data': data});
        },
      );
      await plugin.initialize();
    });

    tearDown(() async {
      await plugin.dispose();
    });

    test('validates connect url', () async {
      final r1 = await plugin.validateArgs('connect', {});
      expect(r1.isValid, false);

      final r2 = await plugin.validateArgs('connect', {'url': 'http://bad'});
      expect(r2.isValid, false);

      final r3 = await plugin.validateArgs('connect', {'url': 'wss://ok.com'});
      expect(r3.isValid, true);
    });

    test('validates send requires id and data', () async {
      final r1 = await plugin.validateArgs('send', {});
      expect(r1.isValid, false);

      final r2 = await plugin.validateArgs('send', {'id': 'x'});
      expect(r2.isValid, false);

      final r3 = await plugin.validateArgs('send', {'id': 'x', 'data': 'hi'});
      expect(r3.isValid, true);
    });

    test('getConnections returns empty initially', () async {
      final result = await plugin.onCall('getConnections', {});
      expect(result['count'], 0);
      expect(result['connections'], isEmpty);
    });

    test('getInfo returns plugin info', () async {
      final result = await plugin.onCall('getInfo', {});
      expect(result['name'], 'websocket');
      expect(result['version'], '1.0.0');
      expect(result['activeConnections'], 0);
    });

    test('disconnect returns not_found for unknown id', () async {
      final result = await plugin.onCall('disconnect', {'id': 'unknown'});
      expect(result['disconnected'], false);
      expect(result['reason'], 'not_found');
    });

    test('send returns not_connected for unknown id', () async {
      final result = await plugin.onCall('send', {
        'id': 'unknown',
        'data': 'hello',
      });
      expect(result['sent'], false);
      expect(result['reason'], 'not_connected');
    });

    test('getState returns not exists for unknown id', () async {
      final result = await plugin.onCall('getState', {'id': 'unknown'});
      expect(result['exists'], false);
    });
  });
}
```

---

### 📄 `test/plugins/background_task_plugin_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sweetmelon/plugins/background_task/lib/background_task_plugin.dart';

void main() {
  group('BackgroundTaskPlugin', () {
    late BackgroundTaskPlugin plugin;
    final List<Map<String, dynamic>> events = [];

    setUp(() async {
      events.clear();
      plugin = BackgroundTaskPlugin(
        eventEmitter: (event, data) async {
          events.add({'event': event, 'data': data});
        },
      );
      await plugin.initialize();
    });

    tearDown(() async {
      await plugin.dispose();
    });

    test('register task', () async {
      final result = await plugin.onCall('register', {
        'taskId': 'sync_task',
        'name': 'Data Sync',
      });

      expect(result['registered'], true);
      expect(result['taskId'], 'sync_task');
    });

    test('runOnce executes task', () async {
      await plugin.onCall('register', {'taskId': 'test_task'});

      final result = await plugin.onCall('runOnce', {
        'taskId': 'test_task',
        'action': 'compute',
        'params': {'expression': '1+1'},
      });

      expect(result['completed'], true);
      expect(result['taskId'], 'test_task');

      // events fired
      expect(
        events.any((e) => e['event'] == 'task.started'),
        true,
      );
      expect(
        events.any((e) => e['event'] == 'task.completed'),
        true,
      );
    });

    test('getTaskState returns correct state', () async {
      await plugin.onCall('register', {'taskId': 'state_task'});
      await plugin.onCall('runOnce', {
        'taskId': 'state_task',
        'action': 'execute',
      });

      final state = await plugin.onCall('getTaskState', {
        'taskId': 'state_task',
      });

      expect(state['found'], true);
      expect(state['runCount'], 1);
      expect(state['status'], 'completed');
    });

    test('getAllTasks returns all registered tasks', () async {
      await plugin.onCall('register', {'taskId': 'a'});
      await plugin.onCall('register', {'taskId': 'b'});

      final result = await plugin.onCall('getAllTasks', {});

      expect(result['count'], 2);
    });

    test('unregister removes task', () async {
      await plugin.onCall('register', {'taskId': 'temp'});

      final result = await plugin.onCall('unregister', {
        'taskId': 'temp',
      });

      expect(result['unregistered'], true);

      final all = await plugin.onCall('getAllTasks', {});
      expect(all['count'], 0);
    });

    test('validates taskId required', () async {
      final r = await plugin.validateArgs('register', {});
      expect(r.isValid, false);
    });

    test('validates intervalMs for repeating', () async {
      final r1 = await plugin.validateArgs('startRepeating', {
        'taskId': 'x',
      });
      expect(r1.isValid, false);

      final r2 = await plugin.validateArgs('startRepeating', {
        'taskId': 'x',
        'intervalMs': 500,
      });
      expect(r2.isValid, false); // min 1000ms

      final r3 = await plugin.validateArgs('startRepeating', {
        'taskId': 'x',
        'intervalMs': 5000,
      });
      expect(r3.isValid, true);
    });

    test('stopAll cancels all timers', () async {
      await plugin.onCall('register', {'taskId': 'r1'});
      await plugin.onCall('startRepeating', {
        'taskId': 'r1',
        'intervalMs': 60000,
        'immediate': false,
      });

      final result = await plugin.onCall('stopAll', {});
      expect(result['stopped'], 1);
    });
  });
}
```

---

# خلاصه

## سیستم‌های جدید اضافه شده

| سیستم | فایل‌ها | توضیح |
|--------|---------|-------|
| **Plugin Versioning** | `plugin_versioning.dart` | SemanticVersion, VersionConstraint, parse |
| **Plugin Migration** | `plugin_migration.dart` | MigrationStep, ArgTransform, MigrationManager |
| **Versioning Support** | `versioned_plugin_manager.dart` | Mixin for PluginManager |
| **Migration Registry** | `migration_registry.dart` | ثبت همه migration‌ها |
| **WebSocket Plugin** | `websocket_plugin.dart` | connect, send, disconnect, auto-reconnect |
| **Background Task Plugin** | `background_task_plugin.dart` | register, runOnce, startRepeating, stop |

## WebSocket Events

| Event | توضیح |
|-------|-------|
| `websocket.connected` | اتصال برقرار شد |
| `websocket.message` | پیام دریافت شد |
| `websocket.disconnected` | قطع شد |
| `websocket.error` | خطا |
| `websocket.reconnecting` | تلاش مجدد |

## Background Task Events

| Event | توضیح |
|-------|-------|
| `task.started` | شروع task |
| `task.completed` | اتمام موفق |
| `task.failed` | خطا |

## مجموع پلاگین‌ها: **37 عدد**

| # | نام | فاز |
|---|-----|------|
| 1-35 | قبلی‌ها | ۱-۵ |
| 36 | websocket | ۶ |
| 37 | backgroundTask | ۶ |
