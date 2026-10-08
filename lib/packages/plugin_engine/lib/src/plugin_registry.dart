import 'plugin_interface.dart';

// ============================================================
// PLUGIN REGISTRY — owns plugin instances and their lifecycle
// ============================================================

class PluginRegistry {
  final PluginEventEmitter? emitter;
  final Map<String, Plugin> _plugins = {};
  bool _disposed = false;

  PluginRegistry({this.emitter});

  static final RegExp _namePattern = RegExp(r'^[a-z][a-z0-9_]{0,63}$');

  /// Registers and initializes a plugin. Throws [ArgumentError] for invalid
  /// or duplicate names.
  Future<void> register(Plugin plugin) async {
    _ensureNotDisposed();
    if (!_namePattern.hasMatch(plugin.name)) {
      throw ArgumentError.value(plugin.name, 'name', 'invalid plugin name');
    }
    if (_plugins.containsKey(plugin.name)) {
      throw StateError('Plugin "${plugin.name}" is already registered');
    }
    final emit = emitter;
    if (emit != null) plugin.attachEmitter(emit);
    await plugin.initialize();
    _plugins[plugin.name] = plugin;
  }

  /// Unregisters and disposes a plugin. Returns false if it was not registered.
  Future<bool> unregister(String name) async {
    final plugin = _plugins.remove(name);
    if (plugin == null) return false;
    await plugin.dispose();
    return true;
  }

  /// Returns the plugin registered under [name], or null.
  Plugin? resolve(String name) => _plugins[name];

  List<String> get registeredPlugins => List.unmodifiable(_plugins.keys);

  /// Disposes every plugin. Errors from one plugin do not block the others.
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    final plugins = _plugins.values.toList();
    _plugins.clear();
    for (final plugin in plugins) {
      try {
        await plugin.dispose();
      } catch (_) {
        // Logged by the plugin itself; disposal must continue.
      }
    }
  }

  void _ensureNotDisposed() {
    if (_disposed) throw StateError('PluginRegistry is disposed');
  }
}
