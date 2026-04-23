import 'dart:async';
import 'plugin_interface.dart';
import '../../../core/lib/src/utils/logger.dart';

// ============================================================
// PLUGIN REGISTRY — ثبت و مدیریت پلاگین‌ها
// ============================================================

class PluginRegistry {
  final Map<String, Map<String, Plugin>> _plugins = {};
  // _plugins[name][version] = plugin
  
  final _registrationController = 
      StreamController<PluginRegistrationEvent>.broadcast();
  
  Stream<PluginRegistrationEvent> get events => 
      _registrationController.stream;

  // ============================================================
  // REGISTRATION
  // ============================================================

  Future<void> register(Plugin plugin) async {
    final name = plugin.name;
    final version = plugin.version;

    BridgeLogger.info(
      'Registry',
      'Registering plugin: $name@$version',
    );

    if (!_plugins.containsKey(name)) {
      _plugins[name] = {};
    }

    if (_plugins[name]!.containsKey(version)) {
      BridgeLogger.warn(
        'Registry',
        'Plugin $name@$version already registered, replacing...',
      );
      
      // dispose قدیمی
      await _plugins[name]![version]!.dispose();
    }

    // Initialize پلاگین
    await plugin.initialize();
    _plugins[name]![version] = plugin;

    _registrationController.add(
      PluginRegistrationEvent(
        type: RegistrationEventType.registered,
        pluginName: name,
        version: version,
      ),
    );

    BridgeLogger.info('Registry', 'Plugin $name@$version registered');
  }

  Future<void> unregister(String name, {String? version}) async {
    if (!_plugins.containsKey(name)) {
      BridgeLogger.warn('Registry', 'Plugin $name not found');
      return;
    }

    if (version != null) {
      final plugin = _plugins[name]?[version];
      if (plugin != null) {
        await plugin.dispose();
        _plugins[name]!.remove(version);
      }
    } else {
      // حذف تمام نسخه‌ها
      for (final plugin in _plugins[name]!.values) {
        await plugin.dispose();
      }
      _plugins.remove(name);
    }

    _registrationController.add(
      PluginRegistrationEvent(
        type: RegistrationEventType.unregistered,
        pluginName: name,
        version: version ?? 'all',
      ),
    );
  }

  // ============================================================
  // RESOLUTION
  // ============================================================

  Plugin? resolve(String name, {String? version}) {
    if (!_plugins.containsKey(name)) return null;
    
    if (version != null) {
      return _plugins[name]![version];
    }
    
    // بازگرداندن آخرین نسخه
    return _getLatestVersion(name);
  }

  Plugin? _getLatestVersion(String name) {
    final versions = _plugins[name];
    if (versions == null || versions.isEmpty) return null;
    
    // مرتب‌سازی بر اساس semver
    final sortedVersions = versions.keys.toList()
      ..sort((a, b) => _compareVersions(a, b));
    
    return versions[sortedVersions.last];
  }

  int _compareVersions(String v1, String v2) {
    final parts1 = v1.split('.').map(int.tryParse).toList();
    final parts2 = v2.split('.').map(int.tryParse).toList();
    
    for (var i = 0; i < 3; i++) {
      final p1 = (i < parts1.length ? parts1[i] : 0) ?? 0;
      final p2 = (i < parts2.length ? parts2[i] : 0) ?? 0;
      if (p1 != p2) return p1.compareTo(p2);
    }
    return 0;
  }

  // ============================================================
  // QUERIES
  // ============================================================

  bool isRegistered(String name, {String? version}) {
    if (!_plugins.containsKey(name)) return false;
    if (version != null) return _plugins[name]!.containsKey(version);
    return _plugins[name]!.isNotEmpty;
  }

  List<String> get registeredPlugins => _plugins.keys.toList();

  List<PluginInfo> getPluginInfos() {
    final infos = <PluginInfo>[];
    
    for (final entry in _plugins.entries) {
      for (final vEntry in entry.value.entries) {
        infos.add(PluginInfo(
          name: entry.key,
          version: vEntry.key,
          isReady: vEntry.value.isReady,
          supportedMethods: vEntry.value.supportedMethods,
          requiredPermissions: vEntry.value.requiredPermissions,
        ));
      }
    }
    
    return infos;
  }

  Future<void> dispose() async {
    for (final versions in _plugins.values) {
      for (final plugin in versions.values) {
        await plugin.dispose();
      }
    }
    _plugins.clear();
    _registrationController.close();
  }
}

// ============================================================
// EVENTS & INFO
// ============================================================

enum RegistrationEventType { registered, unregistered, updated }

class PluginRegistrationEvent {
  final RegistrationEventType type;
  final String pluginName;
  final String version;
  final DateTime timestamp;

  PluginRegistrationEvent({
    required this.type,
    required this.pluginName,
    required this.version,
  }) : timestamp = DateTime.now();
}

class PluginInfo {
  final String name;
  final String version;
  final bool isReady;
  final List<String> supportedMethods;
  final List<String> requiredPermissions;

  const PluginInfo({
    required this.name,
    required this.version,
    required this.isReady,
    required this.supportedMethods,
    required this.requiredPermissions,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'version': version,
        'isReady': isReady,
        'methods': supportedMethods,
        'permissions': requiredPermissions,
      };
}
