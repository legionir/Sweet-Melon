import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sweetmelon/packages/core/lib/src/protocol/message_protocol.dart';
import 'package:sweetmelon/packages/plugin_engine/lib/plugin_engine.dart';
import 'package:sweetmelon/plugins/storage/lib/storage_plugin.dart';

void main() {
  group('normalizeSandboxPath (SEC-002)', () {
    test('accepts plain relative paths and returns them unchanged', () {
      expect(normalizeSandboxPath('a.txt'), 'a.txt');
      expect(normalizeSandboxPath('docs/2026/notes v1.txt'),
          'docs/2026/notes v1.txt');
    });

    test('empty path is only allowed when explicitly permitted', () {
      expect(normalizeSandboxPath('', allowEmpty: true), '');
      expect(
        () => normalizeSandboxPath(''),
        throwsA(isA<PluginException>()),
      );
    });

    for (final bad in [
      '/etc/passwd',
      '../secret',
      'a/../../b',
      'a/..',
      './a',
      'a/./b',
      r'a\b',
      'a//b',
      'a/',
      'nul\u0000byte',
      '.',
      '..',
    ]) {
      test('rejects "${bad.replaceAll('\u0000', '\\0')}"', () {
        expect(
          () => normalizeSandboxPath(bad),
          throwsA(isA<PluginException>()),
        );
      });
    }

    test('rejects paths longer than the maximum', () {
      final long = List.filled(600, 'a').join();
      expect(() => normalizeSandboxPath(long), throwsA(isA<PluginException>()));
    });

    test('rejects paths deeper than the maximum depth', () {
      final deep = List.filled(kMaxPathDepth + 1, 'd').join('/');
      expect(() => normalizeSandboxPath(deep), throwsA(isA<PluginException>()));
    });

    test('traversal is reported as SANDBOX_VIOLATION', () {
      try {
        normalizeSandboxPath('../x');
        fail('expected PluginException');
      } on PluginException catch (e) {
        expect(e.code, PluginErrorCode.sandboxViolation);
      }
    });
  });

  group('resolveWithinRoot', () {
    late Directory temp;
    late String root;

    setUp(() {
      temp = Directory.systemTemp.createTempSync('sm_storage_test_');
      Directory('${temp.path}/root').createSync(recursive: true);
      // Canonical root, as the plugin uses (macOS temp dirs are symlinked).
      root = Directory('${temp.path}/root').resolveSymbolicLinksSync();
    });

    tearDown(() {
      temp.deleteSync(recursive: true);
    });

    test('allows a new nested path inside the root', () async {
      final resolved = await resolveWithinRoot(root, 'new/dir/file.txt');
      expect(resolved, '$root/new/dir/file.txt');
    });

    test('allows an existing file inside the root', () async {
      File('$root/inside.txt').writeAsStringSync('ok');
      expect(await resolveWithinRoot(root, 'inside.txt'), '$root/inside.txt');
    });

    test(
        'rejects a symlink inside the root that points outside (regression: SEC-002)',
        () async {
      final outside = Directory('${temp.path}/outside')..createSync();
      Link('$root/escape').createSync(outside.path);
      expect(
        () => resolveWithinRoot(root, 'escape/loot.txt'),
        throwsA(
          isA<PluginException>().having(
            (e) => e.code,
            'code',
            PluginErrorCode.sandboxViolation,
          ),
        ),
      );
    },
        skip: Platform.isWindows
            ? 'symlinks need elevated rights on Windows'
            : false);
  });
}
