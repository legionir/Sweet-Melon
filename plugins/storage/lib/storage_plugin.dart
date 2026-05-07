import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:plugin_engine/src/plugin_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ============================================================
// STORAGE PLUGIN
// ============================================================

class StoragePlugin extends Plugin {
  SharedPreferences? _prefs;

  /// پیشوند برای جلوگیری از تداخل کلیدها
  static const String _keyPrefix = 'bridge_';

  @override
  String get name => 'storage';

  @override
  String get version => '1.0.0';

  @override
  String get description => 'Key-value storage and file system plugin';

  @override
  bool get cacheable => true;

  @override
  Duration get defaultCacheTtl => const Duration(seconds: 30);

  @override
  List<String> get supportedMethods => [
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
  List<String> get requiredPermissions => ['storage'];

  @override
  Future<void> onInitialize() async {
    _prefs = await SharedPreferences.getInstance();
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
        throw UnsupportedError('Method "$method" not supported');
    }
  }

  // ============================================================
  // KEY-VALUE STORAGE (SharedPreferences)
  // ============================================================

  dynamic _get(Map<String, dynamic> args) {
    final key = args['key'] as String;
    final raw = _prefs?.getString('$_keyPrefix$key');

    if (raw == null) return null;

    // همیشه به صورت JSON ذخیره شده → همیشه decode
    try {
      return jsonDecode(raw);
    } catch (_) {
      return raw;
    }
  }

  Future<bool> _set(Map<String, dynamic> args) async {
    final key = args['key'] as String;
    final value = args['value'];

    // همیشه به صورت JSON ذخیره کن — تضمین سازگاری get/set
    final encoded = jsonEncode(value);
    return await _prefs?.setString('$_keyPrefix$key', encoded) ?? false;
  }

  Future<bool> _remove(Map<String, dynamic> args) async {
    final key = args['key'] as String;
    return await _prefs?.remove('$_keyPrefix$key') ?? false;
  }

  Future<int> _clear() async {
    final keys = _getBridgeKeys();
    int count = 0;

    for (final key in keys) {
      final removed = await _prefs?.remove(key) ?? false;
      if (removed) count++;
    }

    return count;
  }

  List<String> _keys() {
    return _getBridgeKeys()
        .map((k) => k.substring(_keyPrefix.length))
        .toList();
  }

  bool _has(Map<String, dynamic> args) {
    final key = args['key'] as String;
    return _prefs?.containsKey('$_keyPrefix$key') ?? false;
  }

  /// کلیدهای داخلی با پیشوند bridge_
  List<String> _getBridgeKeys() {
    return _prefs
            ?.getKeys()
            .where((k) => k.startsWith(_keyPrefix))
            .toList() ??
        [];
  }

  // ============================================================
  // FILE SYSTEM
  // ============================================================

  Future<Directory> _getAppDir() async {
    return getApplicationDocumentsDirectory();
  }

  /// ساخت مسیر امن — جلوگیری از path traversal
  Future<File> _resolveFile(String path) async {
    final dir = await _getAppDir();
    final resolved = File('${dir.path}/$path');

    // بررسی path traversal
    if (!resolved.path.startsWith(dir.path)) {
      throw const FileSystemException('Invalid path: path traversal detected');
    }

    return resolved;
  }

  Future<String> _readFile(Map<String, dynamic> args) async {
    final path = args['path'] as String;
    final file = await _resolveFile(path);

    if (!await file.exists()) {
      throw FileSystemException('File not found', path);
    }

    final encoding = args['encoding'] as String? ?? 'utf8';

    if (encoding == 'base64') {
      final bytes = await file.readAsBytes();
      return base64Encode(bytes);
    }

    return file.readAsString();
  }

  Future<bool> _writeFile(Map<String, dynamic> args) async {
    final path = args['path'] as String;
    final content = args['content'] as String;
    final encoding = args['encoding'] as String? ?? 'utf8';

    final file = await _resolveFile(path);
    await file.parent.create(recursive: true);

    if (encoding == 'base64') {
      final bytes = base64Decode(content);
      await file.writeAsBytes(bytes);
    } else {
      await file.writeAsString(content);
    }

    return true;
  }

  Future<bool> _deleteFile(Map<String, dynamic> args) async {
    final path = args['path'] as String;
    final file = await _resolveFile(path);

    if (await file.exists()) {
      await file.delete();
      return true;
    }
    return false;
  }

  Future<bool> _fileExists(Map<String, dynamic> args) async {
    final path = args['path'] as String;
    final file = await _resolveFile(path);
    return file.exists();
  }

  Future<List<Map<String, dynamic>>> _listFiles(
    Map<String, dynamic> args,
  ) async {
    final path = args['path'] as String? ?? '';
    final dir = await _getAppDir();
    final targetDir = Directory('${dir.path}/$path');

    // بررسی path traversal
    if (!targetDir.path.startsWith(dir.path)) {
      throw const FileSystemException(
        'Invalid path: path traversal detected',
      );
    }

    if (!await targetDir.exists()) return [];

    final entities = await targetDir.list().toList();

    final results = <Map<String, dynamic>>[];
    for (final entity in entities) {
      final stat = await entity.stat();
      results.add({
        'name': entity.path.split('/').last,
        'path': entity.path.replaceFirst(dir.path, ''),
        'type': entity is Directory ? 'directory' : 'file',
        'size': stat.size,
        'modified': stat.modified.toIso8601String(),
      });
    }

    return results;
  }

  // ============================================================
  // VALIDATION
  // ============================================================

  @override
  Future<ValidationResult> validateArgs(
    String method,
    Map<String, dynamic> args,
  ) async {
    switch (method) {
      case 'get':
      case 'remove':
      case 'has':
        return _validateKeyRequired(args);
      case 'set':
        return _validateSet(args);
      case 'readFile':
      case 'deleteFile':
      case 'fileExists':
        return _validatePathRequired(args);
      case 'writeFile':
        return _validateWriteFile(args);
      default:
        return ValidationResult.valid();
    }
  }

  ValidationResult _validateKeyRequired(Map<String, dynamic> args) {
    if (!args.containsKey('key') || args['key'] is! String) {
      return ValidationResult.invalid('key is required and must be a string');
    }
    final key = args['key'] as String;
    if (key.isEmpty) {
      return ValidationResult.invalid('key cannot be empty');
    }
    return ValidationResult.valid();
  }

  ValidationResult _validateSet(Map<String, dynamic> args) {
    final keyResult = _validateKeyRequired(args);
    if (!keyResult.isValid) return keyResult;

    if (!args.containsKey('value')) {
      return ValidationResult.invalid('value is required');
    }

    return ValidationResult.valid();
  }

  ValidationResult _validatePathRequired(Map<String, dynamic> args) {
    if (!args.containsKey('path') || args['path'] is! String) {
      return ValidationResult.invalid(
        'path is required and must be a string',
      );
    }
    final path = args['path'] as String;
    if (path.isEmpty) {
      return ValidationResult.invalid('path cannot be empty');
    }
    // بررسی اولیه path traversal
    if (path.contains('..')) {
      return ValidationResult.invalid(
        'path cannot contain ".." (path traversal)',
      );
    }
    return ValidationResult.valid();
  }

  ValidationResult _validateWriteFile(Map<String, dynamic> args) {
    final pathResult = _validatePathRequired(args);
    if (!pathResult.isValid) return pathResult;

    if (!args.containsKey('content') || args['content'] is! String) {
      return ValidationResult.invalid(
        'content is required and must be a string',
      );
    }

    final encoding = args['encoding'] as String?;
    if (encoding != null && encoding != 'utf8' && encoding != 'base64') {
      return ValidationResult.invalid(
        'encoding must be "utf8" or "base64"',
      );
    }

    return ValidationResult.valid();
  }
}