import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sweetmelon/packages/core/lib/src/protocol/message_protocol.dart';
import 'package:sweetmelon/packages/plugin_engine/lib/plugin_engine.dart';
import 'package:sweetmelon/packages/security/lib/security.dart';
import 'package:sweetmelon/plugins/storage/lib/storage_plugin.dart';

import '../helpers/fakes.dart';

void main() {
  late Directory temp;
  late Directory sandbox;
  late StoragePlugin plugin;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    temp = Directory.systemTemp.createTempSync('sm_storage_sec_');
    sandbox = Directory('${temp.path}/app_docs')..createSync();
    plugin = StoragePlugin(rootProvider: () async => sandbox);
    await plugin.initialize();
  });

  tearDown(() async {
    await plugin.dispose();
    temp.deleteSync(recursive: true);
  });

  Future<PluginErrorCode?> errorOf(String method, Map<String, dynamic> args) async {
    try {
      await plugin.onCall(method, args);
      return null;
    } on PluginException catch (e) {
      return e.code;
    }
  }

  group('path traversal is blocked (SEC-002)', () {
    for (final path in ['../outside.txt', '/etc/hosts', 'a/../../x', r'..\x']) {
      test('writeFile refuses "$path" in validation', () async {
        final v = await plugin.validateArgs(
          'writeFile',
          {'path': path, 'content': 'pwned'},
        );
        expect(v.isValid, isFalse);
      });
    }

    test('writeFile never creates a file outside the sandbox', () async {
      await plugin.validateArgs('writeFile', {'path': '../outside.txt', 'content': 'x'});
      expect(File('${temp.path}/outside.txt').existsSync(), isFalse);
    });

    test('readFile refuses an absolute path', () async {
      final v = await plugin.validateArgs('readFile', {'path': '/etc/passwd'});
      expect(v.isValid, isFalse);
    });

    test('a symlink planted inside the sandbox cannot be used to escape', () async {
      final outside = Directory('${temp.path}/outside')..createSync();
      File('${outside.path}/secret.txt').writeAsStringSync('top secret');
      Link('${sandbox.path}/link').createSync(outside.path);

      expect(await errorOf('readFile', {'path': 'link/secret.txt'}),
          PluginErrorCode.sandboxViolation);
      expect(await errorOf('writeFile', {'path': 'link/new.txt', 'content': 'x'}),
          PluginErrorCode.sandboxViolation);
      expect(File('${outside.path}/new.txt').existsSync(), isFalse);
    }, skip: Platform.isWindows ? 'symlinks need elevated rights on Windows' : false);

    test('listFiles on a traversal path is refused (regression: unvalidated listFiles)',
        () async {
      final v = await plugin.validateArgs('listFiles', {'path': '../'});
      expect(v.isValid, isFalse);
    });
  });

  group('size limits (SEC-002)', () {
    test('writeFile refuses content above the file size limit', () async {
      final big = 'a' * (kMaxFileBytes + 1);
      expect(
        await errorOf('writeFile', {'path': 'big.txt', 'content': big}),
        PluginErrorCode.invalidArgs,
      );
      expect(File('${sandbox.path}/big.txt').existsSync(), isFalse);
    });

    test('set refuses values above the stored value limit', () async {
      final big = 'a' * (kMaxStoredValueBytes + 1);
      expect(
        await errorOf('set', {'key': 'k', 'value': big}),
        PluginErrorCode.invalidArgs,
      );
    });
  });

  test('invalid base64 is a validation-style error, not a crash', () async {
    expect(
      await errorOf('writeFile', {
        'path': 'x.bin',
        'content': '%%%not-base64%%%',
        'encoding': 'base64',
      }),
      PluginErrorCode.invalidArgs,
    );
  });

  test('file round-trip inside the sandbox works', () async {
    expect(
      await plugin.onCall('writeFile', {'path': 'docs/a.txt', 'content': 'hello'}),
      isTrue,
    );
    expect(await plugin.onCall('readFile', {'path': 'docs/a.txt'}), 'hello');
    final listing = await plugin.onCall('listFiles', {'path': 'docs'}) as List;
    expect(listing.single['name'], 'a.txt');
    expect(listing.single['path'], 'docs/a.txt');
  });

  test('key-value round-trip with JSON values', () async {
    await plugin.onCall('set', {'key': 'user', 'value': {'name': 'x'}});
    expect(await plugin.onCall('get', {'key': 'user'}), {'name': 'x'});
    expect(await plugin.onCall('has', {'key': 'user'}), isTrue);
    expect(await plugin.onCall('keys', {}), ['user']);
    expect(await plugin.onCall('remove', {'key': 'user'}), isTrue);
    expect(await plugin.onCall('get', {'key': 'user'}), isNull);
  });

  test('keys are validated for presence and length', () async {
    expect((await plugin.validateArgs('get', {})).isValid, isFalse);
    expect((await plugin.validateArgs('get', {'key': ''})).isValid, isFalse);
    expect(
      (await plugin.validateArgs('get', {'key': 'k' * (kMaxKeyLength + 1)})).isValid,
      isFalse,
    );
  });

  test('through the engine: traversal yields SANDBOX_VIOLATION or INVALID_ARGS, never success',
      () async {
    final harness = await EngineHarness.create(
      plugins: [plugin],
      grants: {'storage': PermissionState.granted},
    );
    final response = await harness.manager.execute(
      buildRequest(
        plugin: 'storage',
        method: 'readFile',
        args: {'path': '../../etc/passwd'},
      ),
    );
    expect(response.success, isFalse);
    expect(
      {PluginErrorCode.invalidArgs, PluginErrorCode.sandboxViolation},
      contains(response.error!.code),
    );
    expect(jsonEncode(response.toJson()), isNot(contains('/etc/passwd')));
  });
}
