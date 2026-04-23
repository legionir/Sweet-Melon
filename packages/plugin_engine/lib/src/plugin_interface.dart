import 'dart:async';
import '../../../core/lib/src/protocol/message_protocol.dart';

// ============================================================
// PLUGIN INTERFACE — قرارداد اصلی هر پلاگین
// ============================================================

abstract class Plugin {
  /// نام یکتای پلاگین
  String get name;

  /// نسخه پلاگین (Semantic Versioning)
  String get version;

  /// توضیحات پلاگین
  String get description => '';

  /// متدهای پشتیبانی‌شده
  List<String> get supportedMethods;

  /// Permission‌های مورد نیاز
  List<String> get requiredPermissions => [];

  /// آیا پلاگین آماده است
  bool get isReady => _initialized;
  bool _initialized = false;

  /// اجرای یک متد
  Future<dynamic> onCall(String method, Map<String, dynamic> args);

  // ============================================================
  // LIFECYCLE
  // ============================================================

  /// راه‌اندازی اولیه
  Future<void> initialize() async {
    await onInitialize();
    _initialized = true;
  }

  /// پاکسازی
  Future<void> dispose() async {
    _initialized = false;
    await onDispose();
  }

  // hook‌های lifecycle — override کنید
  Future<void> onInitialize() async {}
  Future<void> onDispose() async {}
  Future<void> onPause() async {}
  Future<void> onResume() async {}

  // ============================================================
  // VALIDATION
  // ============================================================

  bool supportsMethod(String method) => supportedMethods.contains(method);

  /// Validate آرگومان‌ها (override برای validation سفارشی)
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
// VALIDATION RESULT
// ============================================================

class ValidationResult {
  final bool isValid;
  final String? errorMessage;
  final List<String> warnings;

  const ValidationResult({
    required this.isValid,
    this.errorMessage,
    this.warnings = const [],
  });

  factory ValidationResult.valid() => const ValidationResult(isValid: true);

  factory ValidationResult.invalid(String message) => ValidationResult(
        isValid: false,
        errorMessage: message,
      );
}

// ============================================================
// PLUGIN MANIFEST
// ============================================================

class PluginManifest {
  final String name;
  final String version;
  final String description;
  final List<String> methods;
  final List<String> permissions;
  final Map<String, dynamic> config;
  final PluginCapabilities capabilities;

  const PluginManifest({
    required this.name,
    required this.version,
    required this.description,
    required this.methods,
    required this.permissions,
    required this.config,
    required this.capabilities,
  });

  factory PluginManifest.fromJson(Map<String, dynamic> json) {
    return PluginManifest(
      name: json['name'] as String,
      version: json['version'] as String,
      description: json['description'] as String? ?? '',
      methods: List<String>.from(json['methods'] as List),
      permissions: List<String>.from(
        (json['permissions'] as List?) ?? [],
      ),
      config: (json['config'] as Map<String, dynamic>?) ?? {},
      capabilities: json['capabilities'] != null
          ? PluginCapabilities.fromJson(
              json['capabilities'] as Map<String, dynamic>,
            )
          : PluginCapabilities.defaults(),
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'version': version,
        'description': description,
        'methods': methods,
        'permissions': permissions,
        'config': config,
        'capabilities': capabilities.toJson(),
      };
}

class PluginCapabilities {
  final bool supportsStreaming;
  final bool supportsBatch;
  final bool supportsCache;
  final int maxConcurrentCalls;

  const PluginCapabilities({
    required this.supportsStreaming,
    required this.supportsBatch,
    required this.supportsCache,
    required this.maxConcurrentCalls,
  });

  factory PluginCapabilities.defaults() => const PluginCapabilities(
        supportsStreaming: false,
        supportsBatch: true,
        supportsCache: false,
        maxConcurrentCalls: 10,
      );

  factory PluginCapabilities.fromJson(Map<String, dynamic> json) {
    return PluginCapabilities(
      supportsStreaming: json['supportsStreaming'] as bool? ?? false,
      supportsBatch: json['supportsBatch'] as bool? ?? true,
      supportsCache: json['supportsCache'] as bool? ?? false,
      maxConcurrentCalls: json['maxConcurrentCalls'] as int? ?? 10,
    );
  }

  Map<String, dynamic> toJson() => {
        'supportsStreaming': supportsStreaming,
        'supportsBatch': supportsBatch,
        'supportsCache': supportsCache,
        'maxConcurrentCalls': maxConcurrentCalls,
      };
}
