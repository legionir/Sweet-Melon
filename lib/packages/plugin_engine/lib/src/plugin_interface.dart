import 'dart:async';

import 'package:sweetmelon/packages/core/lib/src/protocol/message_protocol.dart'
    show PluginErrorCode;

// ============================================================
// PLUGIN INTERFACE — the contract every native plugin implements
// ============================================================

/// Sends an event to JavaScript (bound to MessageBridge.emitEvent).
typedef PluginEventEmitter = Future<void> Function(String event, Object? data);

abstract class Plugin {
  /// Unique plugin name (lower-case, [a-z][a-z0-9_]*).
  String get name;

  /// Plugin version (semantic versioning).
  String get version;

  /// Human-readable description.
  String get description => '';

  /// Methods this plugin serves. Anything else is rejected with METHOD_NOT_FOUND.
  List<String> get supportedMethods;

  /// Permissions that must be granted before any method is executed.
  List<String> get requiredPermissions => const [];

  /// Capabilities enforced by the plugin manager at runtime.
  PluginCapabilities get capabilities => const PluginCapabilities.defaults();

  /// Methods that start a stream of events. Requires
  /// [PluginCapabilities.supportsStreaming].
  Set<String> get streamingMethods => const {};

  /// Methods whose successful results may be cached. Only read-only methods
  /// should be listed here. Empty by default: nothing is cached unless a plugin
  /// opts in explicitly.
  Set<String> get cacheableMethods => const {};

  /// TTL for cached results.
  Duration get defaultCacheTtl => const Duration(seconds: 30);

  /// Whether the plugin has completed [initialize].
  bool get isReady => _initialized;
  bool _initialized = false;

  PluginEventEmitter? _emitter;

  /// Called by the registry on registration. Events are delivered to JS only
  /// through the bridge's emitEvent (validated name, encoded payload).
  void attachEmitter(PluginEventEmitter emitter) => _emitter = emitter;

  /// Emits an event to JavaScript. Dropped silently when no emitter is
  /// attached (e.g. in unit tests) or after dispose.
  void emit(String event, Object? data) {
    final emitter = _emitter;
    if (emitter == null || !_initialized) return;
    unawaited(emitter('$name.$event', data));
  }

  /// Executes a method. Implementations may throw; the manager converts
  /// exceptions to protocol errors without exposing internal details to JS.
  Future<dynamic> onCall(String method, Map<String, dynamic> args);

  // ============================================================
  // LIFECYCLE
  // ============================================================

  Future<void> initialize() async {
    await onInitialize();
    _initialized = true;
  }

  Future<void> dispose() async {
    _initialized = false;
    await onDispose();
  }

  /// Hook for subclasses.
  Future<void> onInitialize() async {}

  /// Hook for subclasses. Must release streams, subscriptions and timers.
  Future<void> onDispose() async {}

  // ============================================================
  // VALIDATION
  // ============================================================

  bool supportsMethod(String method) => supportedMethods.contains(method);

  bool isCacheable(String method) =>
      capabilities.supportsCache && cacheableMethods.contains(method);

  /// Validates arguments before execution (override for custom validation).
  Future<ValidationResult> validateArgs(
    String method,
    Map<String, dynamic> args,
  ) async {
    return ValidationResult.valid();
  }

  @override
  String toString() => 'Plugin($name@$version)';
}

// ============================================================
// PLUGIN EXCEPTION — a deliberate, user-safe error from a plugin
// ============================================================

/// Thrown by plugins for expected failures (e.g. user cancelled). The [message]
/// is written by the plugin author and is safe to expose to JavaScript.
/// Any other exception is reported to JS as a generic execution error.
class PluginException implements Exception {
  final PluginErrorCode code;
  final String message;

  const PluginException(this.code, this.message);

  @override
  String toString() => 'PluginException(${code.code}: $message)';
}

// ============================================================
// VALIDATION RESULT
// ============================================================

class ValidationResult {
  final bool isValid;
  final String? errorMessage;

  const ValidationResult({required this.isValid, this.errorMessage});

  factory ValidationResult.valid() => const ValidationResult(isValid: true);

  factory ValidationResult.invalid(String message) =>
      ValidationResult(isValid: false, errorMessage: message);
}

// ============================================================
// CAPABILITIES — enforced by PluginManager
// ============================================================

class PluginCapabilities {
  /// Plugin emits events over time (e.g. location watch). Required for
  /// methods that start a stream.
  final bool supportsStreaming;

  /// Plugin may be invoked inside a batch request.
  final bool supportsBatch;

  /// Plugin results may be cached (only for [Plugin.cacheableMethods]).
  final bool supportsCache;

  /// Maximum number of simultaneous in-flight calls to this plugin.
  final int maxConcurrentCalls;

  const PluginCapabilities({
    required this.supportsStreaming,
    required this.supportsBatch,
    required this.supportsCache,
    required this.maxConcurrentCalls,
  }) : assert(maxConcurrentCalls > 0);

  const PluginCapabilities.defaults()
      : supportsStreaming = false,
        supportsBatch = true,
        supportsCache = false,
        maxConcurrentCalls = 8;
}
