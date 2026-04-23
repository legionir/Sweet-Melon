import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../packages/plugin_engine/lib/src/plugin_interface.dart';

// ============================================================
// STORAGE PLUGIN
// ============================================================

class StoragePlugin extends Plugin {
  SharedPreferences? _prefs;

  @override
  String get name => 'storage';

  @override
  String get version => '1.0.0';

  @override
  List<String> get supportedMethods => [
        'get',
        'set',
        'remove',
        'clear',
        'keys',
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

  // ── SharedPreferences ──────────────────────────────────────

  dynamic _get(Map<String, dynamic> args) {
    final key = args['key'] as String;
    final value = _prefs?.get('bridge_$key');
    
    if (value is String) {
      try {
        return jsonDecode(value);
      } catch (_) {
        return value;
      }
    }
    
    return value;
  }

  Future<bool> _set(Map<String, dynamic> args) async {
    final key = args['key'] as String;
    final value = args['value'];
    
    if (value is String) {
      return await _prefs?.setString('bridge_$key', value) ?? false;
    } else {
      final encoded = jsonEncode(value);
      return await _prefs?.setString('bridge_$key', encoded) ?? false;
    }
  }

  Future<bool> _remove(Map<String, dynamic> args) async {
    final key = args['key'] as String;
    return await _prefs?.remove('bridge_$key') ?? false;
  }

  Future<void> _clear() async {
    final keys = _prefs?.getKeys()
        .where((k) => k.startsWith('bridge_'))
        .toList() ?? [];
    
    for (final key in keys) {
      await _prefs?.remove(key);
    }
  }

  List<String> _keys() {
    return (_prefs?.getKeys()
        .where((k) => k.startsWith('bridge_'))
        .map((k) => k.substring('bridge_'.length))
        .toList()) ?? [];
  }

  // ── File System ────────────────────────────────────────────

  Future<Directory> _getAppDir() async {
    return getApplicationDocumentsDirectory();
  }

  Future<String> _readFile(Map<String, dynamic> args) async {
    final path = args['path'] as String;
    final dir = await _getAppDir();
    final file = _safeFile(dir, path);
    
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
    final dir = await _getAppDir();

    final file = _safeFile(dir, path);
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
    final dir = await _getAppDir();
    final file = _safeFile(dir, path);
    
    if (await file.exists()) {
      await file.delete();
      return true;
    }
    return false;
  }

  Future<bool> _fileExists(Map<String, dynamic> args) async {
    final path = args['path'] as String;
    final dir = await _getAppDir();
    final file = _safeFile(dir, path);
    return file.exists();
  }

  Future<List<Map<String, dynamic>>> _listFiles(
    Map<String, dynamic> args,
  ) async {
    final path = args['path'] as String? ?? '';
    final dir = await _getAppDir();
    final targetDir = _safeDirectory(dir, path);
    
    if (!await targetDir.exists()) return [];
    
    final entities = await targetDir.list().toList();
    
    return Future.wait(
      entities.map((entity) async {
        final stat = await entity.stat();
        return {
          'name': entity.path.split('/').last,
          'path': entity.path.replaceFirst(dir.path, ''),
          'type': entity is Directory ? 'directory' : 'file',
          'size': stat.size,
          'modified': stat.modified.toIso8601String(),
        };
      }),
    );
  }

  File _safeFile(Directory baseDir, String userPath) {
    final sanitized = _sanitizeRelativePath(userPath);
    final targetPath = '${baseDir.path}${Platform.pathSeparator}$sanitized';
    final target = File(targetPath);
    final resolvedBase = baseDir.resolveSymbolicLinksSync();
    final resolvedTargetDir = target.parent.existsSync()
        ? target.parent.resolveSymbolicLinksSync()
        : target.parent.absolute.path;

    if (!_isWithinBase(resolvedBase, resolvedTargetDir)) {
      throw const FileSystemException('Path traversal detected');
    }
    return target;
  }

  Directory _safeDirectory(Directory baseDir, String userPath) {
    final sanitized = _sanitizeRelativePath(userPath);
    final targetPath = '${baseDir.path}${Platform.pathSeparator}$sanitized';
    final target = Directory(targetPath);
    final resolvedBase = baseDir.resolveSymbolicLinksSync();
    final resolvedTarget = target.existsSync()
        ? target.resolveSymbolicLinksSync()
        : target.absolute.path;

    if (!_isWithinBase(resolvedBase, resolvedTarget)) {
      throw const FileSystemException('Path traversal detected');
    }
    return target;
  }

  String _sanitizeRelativePath(String path) {
    final normalized = path.replaceAll('\\', '/').trim();
    if (normalized.startsWith('/') || normalized.contains('..')) {
      throw const FileSystemException('Invalid relative path');
    }
    return normalized;
  }

  bool _isWithinBase(String basePath, String targetPath) {
    final base = basePath.replaceAll('\\', '/');
    final target = targetPath.replaceAll('\\', '/');
    return target == base || target.startsWith('$base/');
  }
}
