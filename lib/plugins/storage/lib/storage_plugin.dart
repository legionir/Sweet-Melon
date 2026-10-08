import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sweetmelon/packages/core/lib/src/protocol/message_protocol.dart';
import 'package:sweetmelon/packages/plugin_engine/lib/plugin_engine.dart';

// ============================================================
// STORAGE PLUGIN — key/value and sandboxed file storage
// ============================================================
//
// Security:
//  * Every file path is validated by [normalizeSandboxPath] (no absolute paths,
//    no "..", no backslashes, no NUL, restricted characters, bounded depth)
//    and then resolved against the real (symlink-free) sandbox root (SEC-002).
//  * File reads/writes and stored values have size limits.
//
// Caching:
//  * Only read methods are cacheable. Writes are never answered from cache, and
//    a successful write invalidates the plugin's cache (SM-003, BUG-001).

const int kMaxFileBytes = 5 * 1024 * 1024;
const int kMaxStoredValueBytes = 64 * 1024;
const int kMaxKeyLength = 128;
const int kMaxPathLength = 512;
const int kMaxPathDepth = 16;

final RegExp _segmentPattern = RegExp(r'^[A-Za-z0-9_][A-Za-z0-9_.\- ]{0,127}$');

/// Validates a relative sandbox path and returns its canonical form
/// (segments joined with '/'). Throws [PluginException] on any violation.
String normalizeSandboxPath(String raw, {bool allowEmpty = false}) {
  if (raw.isEmpty) {
    if (allowEmpty) return '';
    throw const PluginException(
      PluginErrorCode.invalidArgs,
      'path cannot be empty',
    );
  }
  if (raw.length > kMaxPathLength) {
    throw const PluginException(
        PluginErrorCode.invalidArgs, 'path is too long');
  }
  if (raw.contains('\u0000') || raw.contains('\\') || raw.startsWith('/')) {
    throw const PluginException(
      PluginErrorCode.sandboxViolation,
      'path must be relative and use "/" separators',
    );
  }
  final segments = raw.split('/');
  if (segments.length > kMaxPathDepth) {
    throw const PluginException(
        PluginErrorCode.invalidArgs, 'path is too deep');
  }
  for (final segment in segments) {
    if (segment == '..' || segment == '.') {
      throw const PluginException(
        PluginErrorCode.sandboxViolation,
        'path traversal is not allowed',
      );
    }
    if (!_segmentPattern.hasMatch(segment)) {
      throw const PluginException(
        PluginErrorCode.invalidArgs,
        'path contains invalid characters',
      );
    }
  }
  return segments.join('/');
}

/// Resolves [relative] inside [root] and verifies that the real location of
/// the nearest existing ancestor is still inside the root (defends against
/// symlinks planted inside the sandbox). [root] must already be canonical.
Future<String> resolveWithinRoot(String root, String relative) async {
  final candidate = relative.isEmpty ? root : '$root/$relative';
  var existing = FileSystemEntity.typeSync(candidate, followLinks: false) !=
          FileSystemEntityType.notFound
      ? candidate
      : null;
  if (existing == null) {
    // Walk up until an existing ancestor is found.
    var probe = candidate;
    while (true) {
      final parent = File(probe).parent.path;
      if (parent == probe) break;
      probe = parent;
      if (FileSystemEntity.typeSync(probe, followLinks: false) !=
          FileSystemEntityType.notFound) {
        existing = probe;
        break;
      }
    }
  }
  if (existing != null) {
    final real = await Directory(existing).exists()
        ? await Directory(existing).resolveSymbolicLinks()
        : await File(existing).resolveSymbolicLinks();
    if (!_isInside(root, real)) {
      throw const PluginException(
        PluginErrorCode.sandboxViolation,
        'path escapes the sandbox',
      );
    }
  }
  return candidate;
}

bool _isInside(String root, String path) =>
    path == root ||
    path.startsWith('$root${Platform.pathSeparator}') ||
    path.startsWith('$root/');

class StoragePlugin extends Plugin {
  static const String _keyPrefix = 'bridge_';

  final Future<SharedPreferences> Function() _prefsProvider;
  final Future<Directory> Function() _rootProvider;

  SharedPreferences? _prefs;
  String? _root;

  StoragePlugin({
    Future<SharedPreferences> Function()? prefsProvider,
    Future<Directory> Function()? rootProvider,
  })  : _prefsProvider = prefsProvider ?? SharedPreferences.getInstance,
        _rootProvider = rootProvider ?? getApplicationDocumentsDirectory;

  @override
  String get name => 'storage';

  @override
  String get version => '1.1.0';

  @override
  String get description => 'Key-value storage and sandboxed file system';

  @override
  PluginCapabilities get capabilities => const PluginCapabilities(
        supportsStreaming: false,
        supportsBatch: true,
        supportsCache: true,
        maxConcurrentCalls: 8,
      );

  @override
  List<String> get supportedMethods => const [
        'get',
        'set',
        'remove',
        'clear',
        'keys',
        'has',
        'readFile',
        'writeFile',
        'deleteFile',
        'fileExists',
        'listFiles',
      ];

  @override
  Set<String> get cacheableMethods => const {
        'get',
        'keys',
        'has',
        'readFile',
        'fileExists',
        'listFiles',
      };

  @override
  Duration get defaultCacheTtl => const Duration(seconds: 30);

  @override
  List<String> get requiredPermissions => const ['storage'];

  @override
  Future<void> onInitialize() async {
    _prefs = await _prefsProvider();
    final root = await _rootProvider();
    _root = await Directory(root.path).resolveSymbolicLinks();
  }

  @override
  Future<void> onDispose() async {
    _prefs = null;
  }

  @override
  Future<dynamic> onCall(String method, Map<String, dynamic> args) async {
    switch (method) {
      case 'get':
        return _get(args);
      case 'set':
        return _set(args);
      case 'remove':
        return _remove(args);
      case 'clear':
        return _clear();
      case 'keys':
        return _keys();
      case 'has':
        return _has(args);
      case 'readFile':
        return _readFile(args);
      case 'writeFile':
        return _writeFile(args);
      case 'deleteFile':
        return _deleteFile(args);
      case 'fileExists':
        return _fileExists(args);
      case 'listFiles':
        return _listFiles(args);
      default:
        throw const PluginException(
          PluginErrorCode.methodNotFound,
          'Method is not supported',
        );
    }
  }

  SharedPreferences get _p {
    final prefs = _prefs;
    if (prefs == null) {
      throw StateError('storage not initialized');
    }
    return prefs;
  }

  String get _sandboxRoot {
    final root = _root;
    if (root == null) throw StateError('storage not initialized');
    return root;
  }

  // ── Key-Value ──────────────────────────────────────────────

  dynamic _get(Map<String, dynamic> args) {
    final raw = _p.getString('$_keyPrefix${args['key']}');
    if (raw == null) return null;
    try {
      return jsonDecode(raw);
    } catch (_) {
      return raw;
    }
  }

  Future<bool> _set(Map<String, dynamic> args) async {
    final encoded = jsonEncode(args['value']);
    if (utf8.encode(encoded).length > kMaxStoredValueBytes) {
      throw const PluginException(
        PluginErrorCode.invalidArgs,
        'value exceeds the stored value size limit',
      );
    }
    return _p.setString('$_keyPrefix${args['key']}', encoded);
  }

  Future<bool> _remove(Map<String, dynamic> args) =>
      _p.remove('$_keyPrefix${args['key']}');

  Future<int> _clear() async {
    var count = 0;
    for (final key in _bridgeKeys()) {
      if (await _p.remove(key)) count++;
    }
    return count;
  }

  List<String> _keys() =>
      _bridgeKeys().map((k) => k.substring(_keyPrefix.length)).toList();

  bool _has(Map<String, dynamic> args) =>
      _p.containsKey('$_keyPrefix${args['key']}');

  List<String> _bridgeKeys() =>
      _p.getKeys().where((k) => k.startsWith(_keyPrefix)).toList();

  // ── File System ────────────────────────────────────────────

  Future<String> _filePath(String rawPath) async {
    final relative = normalizeSandboxPath(rawPath);
    return resolveWithinRoot(_sandboxRoot, relative);
  }

  Future<String> _readFile(Map<String, dynamic> args) async {
    final path = await _filePath(args['path'] as String);
    final file = File(path);
    if (!await file.exists()) {
      throw const PluginException(
          PluginErrorCode.invalidArgs, 'File not found');
    }
    final length = await file.length();
    if (length > kMaxFileBytes) {
      throw const PluginException(
        PluginErrorCode.invalidArgs,
        'file exceeds the size limit',
      );
    }
    if ((args['encoding'] as String? ?? 'utf8') == 'base64') {
      return base64Encode(await file.readAsBytes());
    }
    return file.readAsString();
  }

  Future<bool> _writeFile(Map<String, dynamic> args) async {
    final content = args['content'] as String;
    final encoding = args['encoding'] as String? ?? 'utf8';
    final List<int> bytes;
    if (encoding == 'base64') {
      try {
        bytes = base64Decode(content);
      } on FormatException {
        throw const PluginException(
          PluginErrorCode.invalidArgs,
          'content is not valid base64',
        );
      }
    } else {
      bytes = utf8.encode(content);
    }
    if (bytes.length > kMaxFileBytes) {
      throw const PluginException(
        PluginErrorCode.invalidArgs,
        'content exceeds the size limit',
      );
    }
    final path = await _filePath(args['path'] as String);
    final file = File(path);
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes, flush: true);
    return true;
  }

  Future<bool> _deleteFile(Map<String, dynamic> args) async {
    final path = await _filePath(args['path'] as String);
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
      return true;
    }
    return false;
  }

  Future<bool> _fileExists(Map<String, dynamic> args) async {
    final path = await _filePath(args['path'] as String);
    return File(path).exists();
  }

  Future<List<Map<String, dynamic>>> _listFiles(
    Map<String, dynamic> args,
  ) async {
    final relative = normalizeSandboxPath(
      (args['path'] as String?) ?? '',
      allowEmpty: true,
    );
    final target = await resolveWithinRoot(_sandboxRoot, relative);
    final dir = Directory(target);
    if (!await dir.exists()) return [];
    final results = <Map<String, dynamic>>[];
    await for (final entity in dir.list(followLinks: false)) {
      final stat = await entity.stat();
      final name = entity.path.split(Platform.pathSeparator).last;
      results.add({
        'name': name,
        'path': relative.isEmpty ? name : '$relative/$name',
        'type': entity is Directory ? 'directory' : 'file',
        'size': stat.size,
        'modified': stat.modified.toIso8601String(),
      });
    }
    return results;
  }

  // ── Validation ─────────────────────────────────────────────

  @override
  Future<ValidationResult> validateArgs(
    String method,
    Map<String, dynamic> args,
  ) async {
    try {
      switch (method) {
        case 'get':
        case 'remove':
        case 'has':
          _requireKey(args);
          break;
        case 'set':
          _requireKey(args);
          if (!args.containsKey('value')) {
            return ValidationResult.invalid('value is required');
          }
          break;
        case 'readFile':
        case 'deleteFile':
        case 'fileExists':
          _requireString(args, 'path');
          normalizeSandboxPath(args['path'] as String);
          break;
        case 'writeFile':
          _requireString(args, 'path');
          normalizeSandboxPath(args['path'] as String);
          _requireString(args, 'content');
          final encoding = args['encoding'];
          if (encoding != null && encoding != 'utf8' && encoding != 'base64') {
            return ValidationResult.invalid(
                'encoding must be "utf8" or "base64"');
          }
          break;
        case 'listFiles':
          if (args['path'] != null) {
            _requireString(args, 'path');
            normalizeSandboxPath(args['path'] as String, allowEmpty: true);
          }
          break;
        default:
          break;
      }
    } on PluginException catch (e) {
      return ValidationResult.invalid(e.message);
    }
    return ValidationResult.valid();
  }

  void _requireKey(Map<String, dynamic> args) {
    final key = args['key'];
    if (key is! String || key.isEmpty) {
      throw const PluginException(
        PluginErrorCode.invalidArgs,
        'key is required and must be a non-empty string',
      );
    }
    if (key.length > kMaxKeyLength) {
      throw const PluginException(
          PluginErrorCode.invalidArgs, 'key is too long');
    }
  }

  void _requireString(Map<String, dynamic> args, String field) {
    if (args[field] is! String) {
      throw PluginException(
        PluginErrorCode.invalidArgs,
        '$field is required and must be a string',
      );
    }
  }
}
