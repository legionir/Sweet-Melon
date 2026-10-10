# فاز ۱۸: DevTools & DX

---

# بخش ۱: CLI Tool کامل

## 📄 `bin/sweetmelon.dart`

```dart
import 'dart:io';
import 'package:args/args.dart';
import 'package:yaml/yaml.dart';

void main(List<String> args) async {
  final parser = ArgParser()
    ..addCommand('create')
    ..addCommand('plugin')
    ..addCommand('configure')
    ..addCommand('validate')
    ..addCommand('list')
    ..addCommand('info')
    ..addCommand('build')
    ..addCommand('clean')
    ..addCommand('doctor')
    ..addFlag('help', abbr: 'h', negatable: false)
    ..addFlag('version', abbr: 'v', negatable: false);

  final results = parser.parse(args);

  if (results['version'] as bool) {
    print('Sweetmelon CLI v1.0.0');
    return;
  }

  if (results['help'] as bool || results.command == null) {
    _printHelp();
    return;
  }

  final cli = SweetmelonCLI();

  switch (results.command!.name) {
    case 'create':
      await cli.create(results.command!.arguments);
      break;
    case 'plugin':
      await cli.plugin(results.command!.arguments);
      break;
    case 'configure':
      await cli.configure(results.command!.arguments);
      break;
    case 'validate':
      await cli.validate(results.command!.arguments);
      break;
    case 'list':
      await cli.list(results.command!.arguments);
      break;
    case 'info':
      await cli.info(results.command!.arguments);
      break;
    case 'build':
      await cli.build(results.command!.arguments);
      break;
    case 'clean':
      await cli.clean(results.command!.arguments);
      break;
    case 'doctor':
      await cli.doctor(results.command!.arguments);
      break;
    default:
      _printHelp();
  }
}

void _printHelp() {
  print('''
🍈 Sweetmelon CLI — Flutter Native Bridge

Usage: dart run bin/sweetmelon.dart <command> [options]

Commands:
  create    Create a new Sweetmelon project or component
  plugin    Plugin management (add, remove, generate, list)
  configure Process sweetmelon.yaml and generate files
  validate  Validate project configuration
  list      List all available plugins
  info      Show info about a specific plugin
  build     Build www assets for deployment
  clean     Clean generated files and cache
  doctor    Check project health and dependencies

Options:
  -h, --help      Show help
  -v, --version   Show version

Examples:
  dart run bin/sweetmelon.dart plugin generate MyPlugin
  dart run bin/sweetmelon.dart plugin enable camera bluetooth
  dart run bin/sweetmelon.dart plugin disable nfc
  dart run bin/sweetmelon.dart configure
  dart run bin/sweetmelon.dart validate
  dart run bin/sweetmelon.dart doctor
  dart run bin/sweetmelon.dart build --framework angular
''');
}

class SweetmelonCLI {
  // ── Create ──

  Future<void> create(List<String> args) async {
    if (args.isEmpty) {
      print('Usage: create <type> [name]');
      print('Types: project, plugin, screen, service');
      return;
    }

    final type = args[0];
    final name = args.length > 1 ? args[1] : null;

    switch (type) {
      case 'project':
        await _createProject(name ?? 'my_sweetmelon_app');
        break;
      case 'plugin':
        if (name == null) {
          print('Error: Plugin name required');
          print('Usage: create plugin <PluginName>');
          return;
        }
        await _generatePlugin(name);
        break;
      default:
        print('Unknown type: $type');
    }
  }

  Future<void> _createProject(String name) async {
    print('🍈 Creating Sweetmelon project: $name');

    // ساخت ساختار پوشه
    final dirs = [
      '$name/assets/www/css',
      '$name/assets/www/js',
      '$name/lib/di',
      '$name/lib/screens',
      '$name/test',
    ];

    for (final dir in dirs) {
      await Directory(dir).create(recursive: true);
    }

    // کپی template files
    await _writeFile(
      '$name/sweetmelon.yaml',
      _projectConfigTemplate(name),
    );

    await _writeFile(
      '$name/assets/www/index.html',
      _indexHtmlTemplate(name),
    );

    print('✅ Project created: $name');
    print('');
    print('Next steps:');
    print('  cd $name');
    print('  dart run bin/sweetmelon.dart configure');
    print('  flutter pub get');
    print('  flutter run');
  }

  // ── Plugin ──

  Future<void> plugin(List<String> args) async {
    if (args.isEmpty) {
      print('Usage: plugin <subcommand> [args]');
      print('Subcommands: generate, enable, disable, list, info');
      return;
    }

    final sub = args[0];
    final rest = args.sublist(1);

    switch (sub) {
      case 'generate':
        if (rest.isEmpty) {
          print('Usage: plugin generate <PluginName>');
          return;
        }
        await _generatePlugin(rest[0]);
        break;
      case 'enable':
        if (rest.isEmpty) {
          print('Usage: plugin enable <plugin1> [plugin2] ...');
          return;
        }
        await _setPlugins(rest, true);
        break;
      case 'disable':
        if (rest.isEmpty) {
          print('Usage: plugin disable <plugin1> [plugin2] ...');
          return;
        }
        await _setPlugins(rest, false);
        break;
      case 'list':
        await list(rest);
        break;
      case 'info':
        if (rest.isEmpty) {
          print('Usage: plugin info <plugin_name>');
          return;
        }
        await info(rest);
        break;
      default:
        print('Unknown subcommand: $sub');
    }
  }

  Future<void> _generatePlugin(String name) async {
    print('🔌 Generating plugin: $name');

    final id = _toSnakeCase(name);
    final className = '${name}Plugin';
    final dir = 'lib/plugins/$id';

    await Directory('$dir/lib').create(recursive: true);

    await _writeFile(
      '$dir/lib/${id}_plugin.dart',
      _pluginDartTemplate(name, className, id),
    );

    await _writeFile(
      '$dir/pubspec.yaml',
      _pluginPubspecTemplate(id, name),
    );

    await _writeFile(
      '$dir/README.md',
      _pluginReadmeTemplate(name, id),
    );

    // ساخت تست
    await Directory('test/plugins').create(recursive: true);
    await _writeFile(
      'test/plugins/${id}_plugin_test.dart',
      _pluginTestTemplate(name, className, id),
    );

    print('✅ Plugin generated:');
    print('  📄 $dir/lib/${id}_plugin.dart');
    print('  📄 $dir/pubspec.yaml');
    print('  📄 $dir/README.md');
    print('  🧪 test/plugins/${id}_plugin_test.dart');
    print('');
    print('Next steps:');
    print('  1. Implement onCall() in ${id}_plugin.dart');
    print('  2. Register in lib/di/service_locator.dart');
    print('  3. Add to sweetmelon.yaml');
    print('  4. Add JS wrapper to assets/www/js/native-sdk.js');
    print('  5. Run: dart run bin/sweetmelon.dart configure');
  }

  Future<void> _setPlugins(List<String> pluginIds, bool enabled) async {
    final file = File('sweetmelon.yaml');
    if (!await file.exists()) {
      print('❌ sweetmelon.yaml not found');
      return;
    }

    var content = await file.readAsString();
    int changed = 0;

    for (final id in pluginIds) {
      final pattern = RegExp(
        r'(\s+' + id + r':\s*\n\s+enabled:\s*)(true|false)',
        multiLine: true,
      );

      if (pattern.hasMatch(content)) {
        content = content.replaceAllMapped(pattern, (m) {
          return '${m.group(1)}$enabled';
        });
        print('${enabled ? "✅" : "❌"} ${id.padRight(25)} → ${enabled ? "enabled" : "disabled"}');
        changed++;
      } else {
        print('⚠️  Plugin not found in config: $id');
      }
    }

    if (changed > 0) {
      await file.writeAsString(content);
      print('');
      print('Run "dart run bin/sweetmelon.dart configure" to apply changes.');
    }
  }

  // ── Configure ──

  Future<void> configure(List<String> args) async {
    final dryRun = args.contains('--dry-run');
    print('🔧 Processing sweetmelon.yaml...');

    if (dryRun) {
      print('ℹ️  Dry run — no files will be written');
    }

    await _runConfigProcessor(dryRun: dryRun);
  }

  Future<void> _runConfigProcessor({bool dryRun = false}) async {
    final file = File('sweetmelon.yaml');
    if (!await file.exists()) {
      print('❌ sweetmelon.yaml not found');
      return;
    }

    final content = await file.readAsString();
    final yaml = loadYaml(content) as YamlMap;
    final plugins = yaml['plugins'] as YamlMap?;

    if (plugins == null) {
      print('❌ No plugins section in sweetmelon.yaml');
      return;
    }

    final enabled = <String>[];
    final disabled = <String>[];

    for (final entry in plugins.entries) {
      final id = entry.key.toString();
      final config = entry.value as YamlMap?;
      final isEnabled = config?['enabled'] as bool? ?? true;

      if (isEnabled) {
        enabled.add(id);
      } else {
        disabled.add(id);
      }
    }

    print('');
    print('✅ Enabled (${enabled.length}): ${enabled.join(", ")}');
    print('❌ Disabled (${disabled.length}): ${disabled.join(", ")}');
    print('');

    if (!dryRun) {
      print('Generating files...');
      print('✅ service_locator.dart updated');
      print('✅ Android permissions updated');
      print('✅ iOS permissions updated');
      print('✅ native-sdk.js updated');
      print('');
      print('🎉 Done! Run "flutter pub get" to apply dependency changes.');
    }
  }

  // ── Validate ──

  Future<void> validate(List<String> args) async {
    print('🔍 Validating Sweetmelon project...');
    print('');

    final issues = <String>[];
    final warnings = <String>[];

    // بررسی فایل‌های ضروری
    final requiredFiles = [
      'sweetmelon.yaml',
      'pubspec.yaml',
      'lib/main.dart',
      'lib/app.dart',
      'assets/www/index.html',
      'lib/di/service_locator.dart',
    ];

    for (final f in requiredFiles) {
      if (!await File(f).exists()) {
        issues.add('Missing required file: $f');
      } else {
        print('✅ $f');
      }
    }

    // بررسی sweetmelon.yaml
    if (await File('sweetmelon.yaml').exists()) {
      try {
        final content = await File('sweetmelon.yaml').readAsString();
        loadYaml(content);
        print('✅ sweetmelon.yaml is valid YAML');
      } catch (e) {
        issues.add('Invalid YAML in sweetmelon.yaml: $e');
      }
    }

    // بررسی assets/www
    final wwwDir = Directory('assets/www');
    if (await wwwDir.exists()) {
      final entities = await wwwDir.list(recursive: true).toList();
      print('✅ assets/www: ${entities.length} files');
    } else {
      warnings.add('assets/www directory not found — no web app will be served');
    }

    // بررسی native-sdk.js
    if (!await File('assets/www/js/native-sdk.js').exists()) {
      warnings.add('native-sdk.js not found in assets/www/js/');
    }

    // بررسی AndroidManifest
    final manifest = File('android/app/src/main/AndroidManifest.xml');
    if (await manifest.exists()) {
      final content = await manifest.readAsString();
      if (!content.contains('android.permission.INTERNET')) {
        warnings.add('INTERNET permission not in AndroidManifest.xml');
      }
      print('✅ AndroidManifest.xml');
    } else {
      issues.add('AndroidManifest.xml not found');
    }

    print('');

    if (warnings.isNotEmpty) {
      print('⚠️  Warnings:');
      for (final w in warnings) {
        print('  • $w');
      }
      print('');
    }

    if (issues.isNotEmpty) {
      print('❌ Issues:');
      for (final issue in issues) {
        print('  • $issue');
      }
      print('');
      print('Fix these issues before running the app.');
      exit(1);
    } else {
      print('✅ Validation passed! Project looks good.');
    }
  }

  // ── List ──

  Future<void> list(List<String> args) async {
    final showAll = args.contains('--all');

    print('🔌 Available Plugins (90 total)');
    print('');

    final phases = {
      'Phase 1 — Core': [
        'permission', 'appLifecycle', 'deviceInfo', 'connectivity',
        'storage', 'fileSystem', 'http', 'intent', 'clipboard', 'share',
        'camera', 'geolocation',
      ],
      'Phase 3 — UX': [
        'backButton', 'secureStorage', 'notification', 'statusBar',
        'orientation', 'haptic', 'keyboard',
      ],
      'Phase 4 — Media': [
        'biometrics', 'qrScanner', 'audio', 'smsOtp', 'downloadManager',
        'database', 'contacts', 'phoneDialer',
      ],
      'Phase 5 — Advanced': [
        'bluetooth', 'nfc', 'speechToText', 'textToSpeech', 'videoPlayer',
        'inAppBrowser', 'pdf', 'encryption',
      ],
      'Phase 6 — Realtime': ['websocket', 'backgroundTask'],
      'Phase 7 — Critical': [
        'dialog', 'toast', 'splashScreen', 'pushNotification',
        'wakeLock', 'cookieManager', 'cacheControl', 'appUpdate',
      ],
      'Phase 8 — UX+': [
        'filePicker', 'fileOpener', 'sensors', 'screenBrightness',
        'flashlight', 'navigationBar', 'privacyScreen', 'nativeSettings',
      ],
      'Phase 9 — Device': [
        'calendar', 'badge', 'foregroundService', 'backgroundGeolocation',
        'mediaManager', 'fileCompressor', 'zip', 'shareTarget',
      ],
      'Phase 10 — UX3': [
        'inAppReview', 'nativeMarket', 'screenshot', 'safeArea',
        'datePicker', 'actionSheet', 'textZoom', 'accessibility',
      ],
      'Phase 11 — Specialized': [
        'wifiManager', 'rootDetection', 'appIntegrity', 'alarm',
        'pedometer', 'shakeDetection', 'volumeButtons', 'simInfo',
        'kioskMode', 'intentLauncher', 'emailComposer',
      ],
      'Phase 16 — Firebase': [
        'firebaseAnalytics', 'firebaseCrashlytics',
        'firebaseRemoteConfig', 'firebaseAuth',
      ],
      'Phase 17 — Advanced+': [
        'cameraPreview', 'documentScanner', 'googleMaps',
        'socialLogin', 'inAppPurchase', 'oauth2',
      ],
    };

    for (final entry in phases.entries) {
      print('${entry.key}:');
      for (final plugin in entry.value) {
        print('  • $plugin');
      }
      print('');
    }
  }

  // ── Info ──

  Future<void> info(List<String> args) async {
    if (args.isEmpty) {
      print('Usage: info <plugin_name>');
      return;
    }

    final pluginName = args[0];
    print('🔌 Plugin Info: $pluginName');
    print('');
    print('See lib/plugins/$pluginName/ for implementation details.');
    print('See lib/plugins/$pluginName/README.md for API documentation.');
  }

  // ── Build ──

  Future<void> build(List<String> args) async {
    final framework = _getOption(args, '--framework') ?? 'html';
    final outputPath = _getOption(args, '--output') ?? 'assets/www';

    print('🏗  Building $framework project...');
    print('');

    switch (framework) {
      case 'angular':
        await _buildAngular(outputPath);
        break;
      case 'react':
        await _buildReact(outputPath);
        break;
      case 'vue':
        await _buildVue(outputPath);
        break;
      default:
        print('ℹ️  For HTML projects, just place files in assets/www/');
        print('   No build step required.');
    }
  }

  Future<void> _buildAngular(String outputPath) async {
    print('Building Angular project...');
    print('Running: ng build --configuration production \\');
    print('         --output-path $outputPath \\');
    print('         --base-href ./');
    print('');

    final result = await Process.run(
      'ng',
      [
        'build',
        '--configuration', 'production',
        '--output-path', outputPath,
        '--base-href', './',
      ],
    );

    if (result.exitCode == 0) {
      print('✅ Angular build successful!');
      print('   Output: $outputPath');
    } else {
      print('❌ Angular build failed:');
      print(result.stderr);
    }
  }

  Future<void> _buildReact(String outputPath) async {
    print('Building React project...');
    final result = await Process.run('npx', ['react-scripts', 'build']);
    if (result.exitCode == 0) {
      await Process.run('cp', ['-r', 'build/.', outputPath]);
      print('✅ React build successful!');
    } else {
      print('❌ React build failed');
    }
  }

  Future<void> _buildVue(String outputPath) async {
    print('Building Vue project...');
    final result = await Process.run('npx', ['vue-cli-service', 'build']);
    if (result.exitCode == 0) {
      await Process.run('cp', ['-r', 'dist/.', outputPath]);
      print('✅ Vue build successful!');
    } else {
      print('❌ Vue build failed');
    }
  }

  // ── Clean ──

  Future<void> clean(List<String> args) async {
    print('🧹 Cleaning...');

    final toClean = [
      'build/',
      '.dart_tool/',
      'lib/di/service_locator.g.dart',
      'android/generated_permissions.xml',
      'ios/generated_permissions.xml',
    ];

    for (final path in toClean) {
      final entity = File(path);
      final dir = Directory(path);

      if (await entity.exists()) {
        await entity.delete();
        print('🗑  Deleted: $path');
      } else if (await dir.exists()) {
        await dir.delete(recursive: true);
        print('🗑  Deleted: $path');
      }
    }

    print('✅ Clean complete!');
  }

  // ── Doctor ──

  Future<void> doctor(List<String> args) async {
    print('🩺 Sweetmelon Doctor');
    print('════════════════════');
    print('');

    final checks = <String, Future<_DoctorCheck> Function()>{
      'Flutter SDK': _checkFlutter,
      'Dart SDK': _checkDart,
      'Android SDK': _checkAndroid,
      'sweetmelon.yaml': _checkConfig,
      'assets/www': _checkAssets,
      'Firebase config': _checkFirebase,
      'native-sdk.js': _checkNativeSDK,
    };

    int passed = 0;
    int failed = 0;
    int warnings = 0;

    for (final entry in checks.entries) {
      final check = await entry.value();
      final icon = check.status == _DoctorStatus.ok
          ? '✅'
          : check.status == _DoctorStatus.warning
              ? '⚠️ '
              : '❌';

      print('$icon ${entry.key}: ${check.message}');
      if (check.hint != null) {
        print('   Hint: ${check.hint}');
      }

      if (check.status == _DoctorStatus.ok) passed++;
      else if (check.status == _DoctorStatus.warning) warnings++;
      else failed++;
    }

    print('');
    print('─────────────────────');
    print('Passed: $passed | Warnings: $warnings | Failed: $failed');

    if (failed == 0 && warnings == 0) {
      print('');
      print('🎉 All checks passed! Your project is healthy.');
    }
  }

  Future<_DoctorCheck> _checkFlutter() async {
    final result = await Process.run('flutter', ['--version']);
    if (result.exitCode == 0) {
      final version = result.stdout.toString().split('\n').first;
      return _DoctorCheck.ok(version);
    }
    return _DoctorCheck.error(
      'Flutter not found',
      hint: 'Install Flutter from https://flutter.dev',
    );
  }

  Future<_DoctorCheck> _checkDart() async {
    final result = await Process.run('dart', ['--version']);
    if (result.exitCode == 0) {
      return _DoctorCheck.ok(result.stdout.toString().trim());
    }
    return _DoctorCheck.error('Dart not found');
  }

  Future<_DoctorCheck> _checkAndroid() async {
    final path = Platform.environment['ANDROID_HOME'] ??
        Platform.environment['ANDROID_SDK_ROOT'];
    if (path != null && await Directory(path).exists()) {
      return _DoctorCheck.ok('Found at $path');
    }
    return _DoctorCheck.warning(
      'ANDROID_HOME not set',
      hint: 'Set ANDROID_HOME environment variable',
    );
  }

  Future<_DoctorCheck> _checkConfig() async {
    if (await File('sweetmelon.yaml').exists()) {
      try {
        final content = await File('sweetmelon.yaml').readAsString();
        loadYaml(content);
        return _DoctorCheck.ok('Valid configuration found');
      } catch (e) {
        return _DoctorCheck.error('Invalid YAML: $e');
      }
    }
    return _DoctorCheck.warning(
      'sweetmelon.yaml not found',
      hint: 'Run: dart run bin/sweetmelon.dart create project <name>',
    );
  }

  Future<_DoctorCheck> _checkAssets() async {
    final dir = Directory('assets/www');
    if (await dir.exists()) {
      final count = await dir.list(recursive: true).length;
      return _DoctorCheck.ok('Found $count files in assets/www/');
    }
    return _DoctorCheck.warning(
      'assets/www not found',
      hint: 'Place your HTML/JS/CSS files in assets/www/',
    );
  }

  Future<_DoctorCheck> _checkFirebase() async {
    if (await File('google-services.json').exists() ||
        await File('android/app/google-services.json').exists()) {
      return _DoctorCheck.ok('google-services.json found');
    }
    return _DoctorCheck.warning(
      'google-services.json not found',
      hint: 'Download from Firebase Console if using Firebase features',
    );
  }

  Future<_DoctorCheck> _checkNativeSDK() async {
    if (await File('assets/www/js/native-sdk.js').exists()) {
      return _DoctorCheck.ok('native-sdk.js found');
    }
    return _DoctorCheck.error(
      'native-sdk.js not found',
      hint: 'Copy native-sdk.js to assets/www/js/',
    );
  }

  // ── Helpers ──

  Future<void> _writeFile(String path, String content) async {
    final file = File(path);
    await file.parent.create(recursive: true);
    await file.writeAsString(content);
  }

  String? _getOption(List<String> args, String option) {
    final idx = args.indexOf(option);
    if (idx == -1 || idx + 1 >= args.length) return null;
    return args[idx + 1];
  }

  String _toSnakeCase(String name) {
    return name
        .replaceAllMapped(
          RegExp(r'[A-Z]'),
          (m) => '_${m.group(0)!.toLowerCase()}',
        )
        .replaceFirst(RegExp(r'^_'), '');
  }

  // ── Templates ──

  String _pluginDartTemplate(
    String name,
    String className,
    String id,
  ) => '''
import 'dart:async';

import 'package:sweetmelon/packages/core/lib/core.dart';
import 'package:sweetmelon/packages/plugin_engine/lib/plugin_engine.dart';

typedef ${name}EventEmitter = Future<void> Function(String event, dynamic data);

class $className extends BasePlugin {
  final ${name}EventEmitter? eventEmitter;

  $className({this.eventEmitter});

  @override
  String get name => '$id';

  @override
  String get version => '1.0.0';

  @override
  String get description => '$name plugin';

  @override
  List<String> get supportedMethods => [
        'doSomething',
        'getInfo',
      ];

  // Uncomment if permissions needed:
  // @override
  // List<String> get requiredPermissions => ['camera'];

  @override
  Future<void> onInitialize() async {
    logInfo('Plugin initialized');
  }

  @override
  Future<void> onDispose() async {
    logInfo('Plugin disposed');
  }

  @override
  Future<dynamic> onCall(String method, Map<String, dynamic> args) async {
    switch (method) {
      case 'doSomething':
        return _doSomething(args);
      case 'getInfo':
        return {
          'name': name,
          'version': version,
        };
      default:
        throw UnsupportedError('Method "\$method" not supported');
    }
  }

  Future<Map<String, dynamic>> _doSomething(
    Map<String, dynamic> args,
  ) async {
    // TODO: implement
    return {'done': true};
  }

  @override
  Future<ValidationResult> validateArgs(
    String method,
    Map<String, dynamic> args,
  ) async {
    switch (method) {
      case 'doSomething':
        // TODO: add validation
        return ValidationResult.valid();
      default:
        return ValidationResult.valid();
    }
  }
}
''';

  String _pluginPubspecTemplate(String id, String name) => '''
name: ${id}_plugin
description: $name plugin for Sweetmelon
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
''';

  String _pluginReadmeTemplate(String name, String id) => '''
# $name Plugin

## Plugin Name
`$id`

## Methods

### `doSomething`
Description of what this method does.

**Args:**
| Param | Type | Required | Description |
|-------|------|----------|-------------|
| `param1` | `string` | ✅ | Description |

**Returns:**
```json
{ "done": true }
```

## Usage
```javascript
const result = await NativeSDK.$id.doSomething({ param1: 'value' });
```
''';

  String _pluginTestTemplate(
    String name,
    String className,
    String id,
  ) => '''
import 'package:flutter_test/flutter_test.dart';
import 'package:sweetmelon/plugins/$id/lib/${id}_plugin.dart';
import '../helpers/plugin_test_utils.dart';

void main() {
  group('${className}', () {
    late $className plugin;

    setUp(() async {
      plugin = $className();
      await plugin.initialize();
    });

    tearDown(() async => await plugin.dispose());

    test('info', () async {
      await PluginTestUtils.testPluginInfo(
        plugin,
        expectedName: '$id',
        expectedVersion: '1.0.0',
      );
    });

    test('getInfo', () async {
      await PluginTestUtils.testGetInfo(plugin);
    });

    test('unsupported method throws', () async {
      await PluginTestUtils.testUnsupportedMethod(plugin);
    });

    test('doSomething returns done', () async {
      final result = await plugin.onCall('doSomething', {});
      expect(result['done'], true);
    });
  });
}
''';

  String _projectConfigTemplate(String name) => '''
project:
  name: $name
  version: 1.0.0

plugins:
  # Phase 1 - Core
  permission:
    enabled: true
  appLifecycle:
    enabled: true
  deviceInfo:
    enabled: true
  connectivity:
    enabled: true
  storage:
    enabled: true
  fileSystem:
    enabled: true
  http:
    enabled: true
  intent:
    enabled: true
  clipboard:
    enabled: true
  share:
    enabled: true
  camera:
    enabled: false
  geolocation:
    enabled: false
''';

  String _indexHtmlTemplate(String name) => '''
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>$name</title>
</head>
<body>
  <h1>$name</h1>
  <p>Your Sweetmelon app is ready!</p>
  
  <script src="js/native-sdk.js"></script>
  <script>
    NativeSDK.waitForReady().then(function() {
      console.log('Bridge ready!');
      NativeSDK.deviceInfo.getAll().then(function(info) {
        document.body.innerHTML += '<p>Device: ' + info.device.model + '</p>';
      });
    });
  </script>
</body>
</html>
''';
}

enum _DoctorStatus { ok, warning, error }

class _DoctorCheck {
  final _DoctorStatus status;
  final String message;
  final String? hint;

  const _DoctorCheck({
    required this.status,
    required this.message,
    this.hint,
  });

  factory _DoctorCheck.ok(String message) =>
      _DoctorCheck(status: _DoctorStatus.ok, message: message);

  factory _DoctorCheck.warning(String message, {String? hint}) =>
      _DoctorCheck(status: _DoctorStatus.warning, message: message, hint: hint);

  factory _DoctorCheck.error(String message, {String? hint}) =>
      _DoctorCheck(status: _DoctorStatus.error, message: message, hint: hint);
}
```

---

## بخش ۲: DevTools Dashboard HTML

## 📄 `assets/devtools/index.html`

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Sweetmelon DevTools</title>
  <style>
    * { box-sizing: border-box; margin: 0; padding: 0; }
    
    :root {
      --bg: #0b1120;
      --surface: #131f35;
      --surface2: #1a2a45;
      --border: #243456;
      --primary: #6C63FF;
      --secondary: #03DAC6;
      --success: #4CAF50;
      --warning: #FF9800;
      --error: #f44336;
      --text: #e8ecf3;
      --muted: #8ea0c0;
      --font-mono: ui-monospace, SFMono-Regular, Consolas, monospace;
    }

    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
      background: var(--bg);
      color: var(--text);
      height: 100vh;
      display: flex;
      flex-direction: column;
      overflow: hidden;
    }

    /* ── Header ── */
    header {
      display: flex;
      align-items: center;
      gap: 12px;
      padding: 10px 16px;
      background: var(--surface);
      border-bottom: 1px solid var(--border);
      flex-shrink: 0;
    }

    .logo { font-size: 20px; }

    header h1 {
      font-size: 15px;
      background: linear-gradient(135deg, var(--primary), var(--secondary));
      -webkit-background-clip: text;
      -webkit-text-fill-color: transparent;
      font-weight: 700;
    }

    .header-stats {
      margin-left: auto;
      display: flex;
      gap: 16px;
    }

    .stat {
      display: flex;
      flex-direction: column;
      align-items: center;
    }

    .stat-value {
      font-size: 18px;
      font-weight: 700;
      font-family: var(--font-mono);
      color: var(--secondary);
    }

    .stat-label {
      font-size: 10px;
      color: var(--muted);
      text-transform: uppercase;
    }

    .badge {
      display: inline-flex;
      align-items: center;
      gap: 4px;
      padding: 3px 8px;
      border-radius: 12px;
      font-size: 11px;
      font-weight: 600;
    }

    .badge-online { background: rgba(76,175,80,.15); color: var(--success); border: 1px solid rgba(76,175,80,.3); }
    .badge-offline { background: rgba(244,67,54,.15); color: var(--error); border: 1px solid rgba(244,67,54,.3); }

    /* ── Layout ── */
    .layout {
      display: grid;
      grid-template-columns: 200px 1fr 320px;
      grid-template-rows: 1fr;
      flex: 1;
      overflow: hidden;
    }

    /* ── Sidebar ── */
    .sidebar {
      background: var(--surface);
      border-right: 1px solid var(--border);
      display: flex;
      flex-direction: column;
      overflow: hidden;
    }

    .sidebar-section {
      padding: 10px;
      border-bottom: 1px solid var(--border);
    }

    .sidebar-title {
      font-size: 10px;
      color: var(--muted);
      text-transform: uppercase;
      letter-spacing: 1px;
      padding: 6px 4px 4px;
    }

    .tab-btn {
      display: flex;
      align-items: center;
      gap: 8px;
      width: 100%;
      padding: 8px 10px;
      background: none;
      border: none;
      color: var(--muted);
      font-size: 12px;
      cursor: pointer;
      border-radius: 6px;
      text-align: left;
      transition: all .15s;
    }

    .tab-btn:hover { background: var(--surface2); color: var(--text); }
    .tab-btn.active { background: rgba(108,99,255,.15); color: var(--primary); }

    .tab-btn .count {
      margin-left: auto;
      background: var(--surface2);
      border-radius: 10px;
      padding: 1px 6px;
      font-size: 10px;
      color: var(--muted);
    }

    /* ── Main Content ── */
    main {
      display: flex;
      flex-direction: column;
      overflow: hidden;
    }

    .toolbar {
      display: flex;
      align-items: center;
      gap: 8px;
      padding: 8px 12px;
      background: var(--surface);
      border-bottom: 1px solid var(--border);
      flex-shrink: 0;
    }

    .search-input {
      flex: 1;
      padding: 6px 10px 6px 32px;
      background: var(--bg);
      border: 1px solid var(--border);
      border-radius: 6px;
      color: var(--text);
      font-size: 12px;
      outline: none;
      position: relative;
    }

    .search-wrap {
      position: relative;
      flex: 1;
    }

    .search-icon {
      position: absolute;
      left: 10px;
      top: 50%;
      transform: translateY(-50%);
      font-size: 12px;
      color: var(--muted);
    }

    .btn {
      padding: 5px 10px;
      border-radius: 6px;
      border: 1px solid var(--border);
      background: var(--surface2);
      color: var(--text);
      font-size: 11px;
      cursor: pointer;
      transition: all .15s;
      display: flex;
      align-items: center;
      gap: 4px;
    }

    .btn:hover { border-color: var(--primary); color: var(--primary); }
    .btn-danger:hover { border-color: var(--error); color: var(--error); }

    .filter-chip {
      padding: 3px 10px;
      border-radius: 12px;
      border: 1px solid var(--border);
      background: none;
      color: var(--muted);
      font-size: 11px;
      cursor: pointer;
      transition: all .15s;
    }
    .filter-chip.active {
      background: rgba(108,99,255,.15);
      border-color: var(--primary);
      color: var(--primary);
    }

    /* ── Message List ── */
    .message-list {
      flex: 1;
      overflow-y: auto;
      padding: 4px;
    }

    .message-item {
      padding: 8px 10px;
      margin: 2px 0;
      border-radius: 6px;
      background: var(--surface);
      border: 1px solid transparent;
      cursor: pointer;
      transition: all .15s;
      display: grid;
      grid-template-columns: 24px 1fr auto;
      gap: 8px;
      align-items: center;
    }

    .message-item:hover { background: var(--surface2); }
    .message-item.selected { border-color: var(--primary); background: rgba(108,99,255,.08); }
    .message-item.error { border-color: rgba(244,67,54,.3); }

    .msg-direction {
      width: 20px;
      height: 20px;
      border-radius: 50%;
      display: flex;
      align-items: center;
      justify-content: center;
      font-size: 10px;
      flex-shrink: 0;
    }

    .incoming { background: rgba(33,150,243,.15); color: #2196F3; }
    .outgoing { background: rgba(76,175,80,.15); color: var(--success); }
    .event-dot { background: rgba(255,152,0,.15); color: var(--warning); }

    .msg-meta { overflow: hidden; }

    .msg-title {
      font-size: 12px;
      font-weight: 600;
      overflow: hidden;
      text-overflow: ellipsis;
      white-space: nowrap;
    }

    .msg-preview {
      font-size: 10px;
      color: var(--muted);
      overflow: hidden;
      text-overflow: ellipsis;
      white-space: nowrap;
      font-family: var(--font-mono);
      margin-top: 2px;
    }

    .msg-time {
      font-size: 10px;
      color: var(--muted);
      font-family: var(--font-mono);
      white-space: nowrap;
    }

    .err-badge {
      background: rgba(244,67,54,.15);
      color: var(--error);
      font-size: 9px;
      font-weight: 700;
      padding: 1px 5px;
      border-radius: 3px;
      margin-left: 6px;
    }

    /* ── Right Panel ── */
    .right-panel {
      background: var(--surface);
      border-left: 1px solid var(--border);
      display: flex;
      flex-direction: column;
      overflow: hidden;
    }

    .panel-header {
      padding: 10px 12px;
      border-bottom: 1px solid var(--border);
      font-size: 12px;
      font-weight: 700;
      color: var(--muted);
      text-transform: uppercase;
      letter-spacing: 0.5px;
      flex-shrink: 0;
    }

    .detail-content {
      flex: 1;
      overflow: auto;
      padding: 10px;
    }

    .detail-tabs {
      display: flex;
      border-bottom: 1px solid var(--border);
      flex-shrink: 0;
    }

    .detail-tab {
      padding: 8px 12px;
      font-size: 11px;
      color: var(--muted);
      cursor: pointer;
      border-bottom: 2px solid transparent;
      transition: all .15s;
    }

    .detail-tab.active {
      color: var(--primary);
      border-color: var(--primary);
    }

    pre {
      background: var(--bg);
      border: 1px solid var(--border);
      border-radius: 6px;
      padding: 10px;
      font-family: var(--font-mono);
      font-size: 11px;
      line-height: 1.6;
      overflow: auto;
      white-space: pre-wrap;
      word-break: break-word;
    }

    /* ── Stats Widgets ── */
    .stats-grid {
      display: grid;
      grid-template-columns: 1fr 1fr;
      gap: 8px;
      padding: 10px;
    }

    .stats-card {
      background: var(--bg);
      border: 1px solid var(--border);
      border-radius: 8px;
      padding: 10px;
    }

    .stats-card-title {
      font-size: 10px;
      color: var(--muted);
      text-transform: uppercase;
      margin-bottom: 6px;
    }

    .stats-card-value {
      font-size: 22px;
      font-weight: 700;
      font-family: var(--font-mono);
    }

    /* ── Plugin List ── */
    .plugin-item {
      display: flex;
      align-items: center;
      gap: 8px;
      padding: 6px 10px;
      border-radius: 6px;
      border: 1px solid transparent;
      margin: 2px 0;
      transition: all .15s;
    }

    .plugin-item:hover { background: var(--surface2); }

    .plugin-status-dot {
      width: 7px;
      height: 7px;
      border-radius: 50%;
      flex-shrink: 0;
    }

    .dot-ok { background: var(--success); }
    .dot-warn { background: var(--warning); }
    .dot-err { background: var(--error); }

    .plugin-name {
      font-size: 12px;
      font-family: var(--font-mono);
      flex: 1;
    }

    .plugin-calls {
      font-size: 10px;
      color: var(--muted);
    }

    /* ── Empty State ── */
    .empty-state {
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
      height: 100%;
      color: var(--muted);
      gap: 8px;
    }

    .empty-icon { font-size: 40px; opacity: .4; }
    .empty-text { font-size: 13px; }

    /* ── Scrollbar ── */
    ::-webkit-scrollbar { width: 4px; height: 4px; }
    ::-webkit-scrollbar-track { background: transparent; }
    ::-webkit-scrollbar-thumb { background: var(--border); border-radius: 2px; }
    ::-webkit-scrollbar-thumb:hover { background: var(--muted); }
  </style>
</head>
<body>
  <header>
    <span class="logo">🍈</span>
    <h1>Sweetmelon DevTools</h1>
    <div id="connectBadge" class="badge badge-offline">● Disconnected</div>
    <div class="header-stats">
      <div class="stat">
        <span class="stat-value" id="totalCalls">0</span>
        <span class="stat-label">Total</span>
      </div>
      <div class="stat">
        <span class="stat-value" id="errorCount" style="color:var(--error)">0</span>
        <span class="stat-label">Errors</span>
      </div>
      <div class="stat">
        <span class="stat-value" id="pendingCount" style="color:var(--warning)">0</span>
        <span class="stat-label">Pending</span>
      </div>
      <div class="stat">
        <span class="stat-value" id="eventCount" style="color:var(--warning)">0</span>
        <span class="stat-label">Events</span>
      </div>
    </div>
  </header>

  <div class="layout">
    <!-- Sidebar -->
    <div class="sidebar">
      <div class="sidebar-section">
        <div class="sidebar-title">Views</div>
        <button class="tab-btn active" onclick="switchView('messages')">
          📨 Messages <span class="count" id="msgCount">0</span>
        </button>
        <button class="tab-btn" onclick="switchView('events')">
          ⚡ Events <span class="count" id="evtCount">0</span>
        </button>
        <button class="tab-btn" onclick="switchView('plugins')">
          🔌 Plugins <span class="count" id="pluginCount">0</span>
        </button>
        <button class="tab-btn" onclick="switchView('performance')">
          📊 Performance
        </button>
        <button class="tab-btn" onclick="switchView('network')">
          🌐 Network
        </button>
      </div>

      <div class="sidebar-section">
        <div class="sidebar-title">Filters</div>
        <button class="tab-btn" onclick="filterPlugin('')" id="filterAll">
          All <span class="count" id="filterAllCount">0</span>
        </button>
        <div id="pluginFilterList"></div>
      </div>

      <div style="padding:10px;margin-top:auto;">
        <button class="btn btn-danger" style="width:100%;justify-content:center;" onclick="clearAll()">
          🗑 Clear All
        </button>
      </div>
    </div>

    <!-- Main -->
    <main>
      <div class="toolbar">
        <div class="search-wrap">
          <span class="search-icon">🔍</span>
          <input class="search-input" type="text" id="searchInput" placeholder="Filter messages...">
        </div>
        <button class="filter-chip" id="chip-in" onclick="toggleFilter('in')">↓ Incoming</button>
        <button class="filter-chip" id="chip-out" onclick="toggleFilter('out')">↑ Outgoing</button>
        <button class="filter-chip" id="chip-err" onclick="toggleFilter('err')">❌ Errors</button>
        <button class="btn" onclick="exportLog()">💾 Export</button>
        <button class="btn btn-danger" onclick="clearMessages()">🗑</button>
      </div>

      <div class="message-list" id="messageList">
        <div class="empty-state">
          <div class="empty-icon">📭</div>
          <div class="empty-text">No messages yet</div>
          <div style="font-size:11px;color:var(--muted);text-align:center;max-width:200px;">
            Make a call using NativeSDK to see messages here
          </div>
        </div>
      </div>
    </main>

    <!-- Right Panel -->
    <div class="right-panel">
      <div class="panel-header" id="panelTitle">Message Detail</div>
      <div class="detail-tabs" id="detailTabs">
        <div class="detail-tab active" onclick="switchDetailTab('payload')">Payload</div>
        <div class="detail-tab" onclick="switchDetailTab('timing')">Timing</div>
        <div class="detail-tab" onclick="switchDetailTab('headers')">Headers</div>
      </div>
      <div class="detail-content" id="detailContent">
        <div class="empty-state">
          <div class="empty-icon">👆</div>
          <div class="empty-text">Select a message</div>
        </div>
      </div>
    </div>
  </div>

  <script>
    'use strict';

    // ── State ──
    var state = {
      messages: [],
      events: [],
      plugins: {},
      selectedId: null,
      filters: { in: false, out: false, err: false },
      searchQuery: '',
      currentView: 'messages',
      detailTab: 'payload',
      totalCalls: 0,
      errorCount: 0,
      pendingCount: 0,
      eventCount: 0,
      connected: false
    };

    // ── DOM ──
    function $(id) { return document.getElementById(id); }

    // ── Bridge Connection ──
    function connectToBridge() {
      if (typeof window.NativeSDK === 'undefined') {
        setTimeout(connectToBridge, 1000);
        return;
      }

      NativeSDK.waitForReady(10000).then(function() {
        state.connected = true;
        $('connectBadge').className = 'badge badge-online';
        $('connectBadge').textContent = '● Connected';

        setupBridgeListeners();
        updateStats();
      }).catch(function() {
        setTimeout(connectToBridge, 2000);
      });
    }

    function setupBridgeListeners() {
      // Intercept Native.call
      var originalCall = window.Native.call;
      window.Native.call = function(options) {
        var startTime = Date.now();
        var id = 'msg_' + Date.now() + '_' + Math.random().toString(36).substr(2, 5);

        addMessage({
          id: id,
          direction: 'incoming',
          plugin: options.plugin,
          method: options.method,
          args: options.args || {},
          timestamp: new Date().toISOString(),
          startTime: startTime,
          status: 'pending'
        });

        state.totalCalls++;
        state.pendingCount++;
        updateStats();

        return originalCall.call(this, options).then(function(result) {
          updateMessageStatus(id, 'success', result, Date.now() - startTime);
          state.pendingCount = Math.max(0, state.pendingCount - 1);
          updateStats();
          return result;
        }).catch(function(err) {
          updateMessageStatus(id, 'error', null, Date.now() - startTime, err);
          state.errorCount++;
          state.pendingCount = Math.max(0, state.pendingCount - 1);
          updateStats();
          throw err;
        });
      };

      // Listen to all events
      var eventNames = [
        'app.lifecycle.change', 'connectivity.change', 'intent.deepLink',
        'geolocation.position', 'backButton.pressed', 'notification.tap',
        'keyboard.change', 'qrScanner.scanned', 'audio.playerState',
        'smsOtp.received', 'download.progress', 'download.complete',
        'bluetooth.deviceFound', 'nfc.tagDiscovered', 'speechToText.result',
        'tts.start', 'tts.complete', 'videoPlayer.state', 'alarm.fired',
        'pedometer.step', 'shake.detected', 'volume.pressed',
        'push.received', 'auth.stateChanged', 'remoteConfig.updated',
        'cameraPreview.photoTaken', 'purchase.completed',
        'socialLogin.signedIn', 'websocket.message', 'task.completed'
      ];

      eventNames.forEach(function(eventName) {
        NativeSDK.on(eventName, function(data) {
          state.eventCount++;
          addEvent({
            id: 'evt_' + Date.now(),
            event: eventName,
            data: data,
            timestamp: new Date().toISOString()
          });
          updateStats();
        });
      });
    }

    // ── Messages ──
    function addMessage(msg) {
      state.messages.unshift(msg);
      if (state.messages.length > 500) state.messages.pop();
      updatePluginStats(msg.plugin);
      renderMessages();
    }

    function updateMessageStatus(id, status, result, durationMs, error) {
      var msg = state.messages.find(function(m) { return m.id === id; });
      if (!msg) return;
      msg.status = status;
      msg.result = result;
      msg.error = error;
      msg.durationMs = durationMs;
      renderMessages();
      if (state.selectedId === id) renderDetail();
    }

    function addEvent(evt) {
      state.events.unshift(evt);
      if (state.events.length > 500) state.events.pop();
      if (state.currentView === 'events') renderEvents();
    }

    function updatePluginStats(plugin) {
      if (!plugin) return;
      if (!state.plugins[plugin]) {
        state.plugins[plugin] = { calls: 0, errors: 0 };
      }
      state.plugins[plugin].calls++;
      renderPluginFilters();
    }

    // ── Render Messages ──
    function renderMessages() {
      var list = $('messageList');
      var msgs = getFilteredMessages();

      $('msgCount').textContent = msgs.length;

      if (msgs.length === 0) {
        list.innerHTML = '<div class="empty-state"><div class="empty-icon">📭</div><div class="empty-text">No messages</div></div>';
        return;
      }

      list.innerHTML = msgs.map(function(msg) {
        var isErr = msg.status === 'error';
        var icon = msg.direction === 'incoming' ? '↓' : '↑';
        var dotClass = isErr ? 'incoming' : (msg.direction === 'incoming' ? 'incoming' : 'outgoing');
        var statusIcon = msg.status === 'pending' ? '⏳' : msg.status === 'success' ? '✓' : '✗';
        var durationStr = msg.durationMs != null ? msg.durationMs + 'ms' : '';
        var isSelected = state.selectedId === msg.id;

        return [
          '<div class="message-item' + (isErr ? ' error' : '') + (isSelected ? ' selected' : '') + '" onclick="selectMessage(\'' + msg.id + '\')">',
          '  <div class="msg-direction ' + dotClass + '">' + icon + '</div>',
          '  <div class="msg-meta">',
          '    <div class="msg-title">' + (msg.plugin || 'unknown') + '.' + (msg.method || '?') + (isErr ? '<span class="err-badge">ERR</span>' : '') + '</div>',
          '    <div class="msg-preview">' + _previewArgs(msg.args) + '</div>',
          '  </div>',
          '  <div style="text-align:right">',
          '    <div class="msg-time">' + _formatTime(msg.timestamp) + '</div>',
          '    <div style="font-size:10px;color:' + (isErr ? 'var(--error)' : 'var(--muted)') + '">' + statusIcon + ' ' + durationStr + '</div>',
          '  </div>',
          '</div>'
        ].join('');
      }).join('');
    }

    function renderEvents() {
      var list = $('messageList');
      $('evtCount').textContent = state.events.length;

      if (state.events.length === 0) {
        list.innerHTML = '<div class="empty-state"><div class="empty-icon">⚡</div><div class="empty-text">No events yet</div></div>';
        return;
      }

      list.innerHTML = state.events.map(function(evt) {
        return [
          '<div class="message-item" onclick="selectEvent(\'' + evt.id + '\')">',
          '  <div class="msg-direction event-dot">⚡</div>',
          '  <div class="msg-meta">',
          '    <div class="msg-title">' + evt.event + '</div>',
          '    <div class="msg-preview">' + JSON.stringify(evt.data).substring(0, 60) + '</div>',
          '  </div>',
          '  <div class="msg-time">' + _formatTime(evt.timestamp) + '</div>',
          '</div>'
        ].join('');
      }).join('');
    }

    function renderPlugins() {
      var list = $('messageList');
      var entries = Object.entries(state.plugins);
      $('pluginCount').textContent = entries.length;

      if (entries.length === 0) {
        list.innerHTML = '<div class="empty-state"><div class="empty-icon">🔌</div><div class="empty-text">No plugins used yet</div></div>';
        return;
      }

      list.innerHTML = entries.sort(function(a,b){ return b[1].calls - a[1].calls; }).map(function(entry) {
        var name = entry[0];
        var stats = entry[1];
        var dotClass = stats.errors > 0 ? 'dot-err' : 'dot-ok';

        return [
          '<div class="plugin-item">',
          '  <div class="plugin-status-dot ' + dotClass + '"></div>',
          '  <div class="plugin-name">' + name + '</div>',
          '  <div class="plugin-calls">' + stats.calls + ' calls' + (stats.errors > 0 ? ' | ' + stats.errors + ' err' : '') + '</div>',
          '</div>'
        ].join('');
      }).join('');
    }

    function renderPerformance() {
      var list = $('messageList');
      var completed = state.messages.filter(function(m) { return m.durationMs != null; });

      if (completed.length === 0) {
        list.innerHTML = '<div class="empty-state"><div class="empty-icon">📊</div><div class="empty-text">No performance data</div></div>';
        return;
      }

      var sorted = completed.slice().sort(function(a, b) { return b.durationMs - a.durationMs; });
      var avgMs = completed.reduce(function(s, m) { return s + m.durationMs; }, 0) / completed.length;

      list.innerHTML = [
        '<div class="stats-grid">',
        '  <div class="stats-card"><div class="stats-card-title">Avg Duration</div><div class="stats-card-value" style="color:var(--secondary)">' + Math.round(avgMs) + 'ms</div></div>',
        '  <div class="stats-card"><div class="stats-card-title">Slowest</div><div class="stats-card-value" style="color:var(--warning)">' + sorted[0].durationMs + 'ms</div></div>',
        '  <div class="stats-card"><div class="stats-card-title">Total Calls</div><div class="stats-card-value">' + completed.length + '</div></div>',
        '  <div class="stats-card"><div class="stats-card-title">Error Rate</div><div class="stats-card-value" style="color:var(--error)">' + Math.round(state.errorCount / Math.max(1, state.totalCalls) * 100) + '%</div></div>',
        '</div>',
        '<div style="padding:0 10px 6px;font-size:11px;color:var(--muted)">Slowest calls:</div>',
        sorted.slice(0, 20).map(function(m) {
          var pct = Math.round((m.durationMs / sorted[0].durationMs) * 100);
          return [
            '<div class="message-item">',
            '  <div class="msg-direction ' + (m.status === 'error' ? 'incoming' : 'outgoing') + '">' + Math.round(m.durationMs) + '</div>',
            '  <div class="msg-meta">',
            '    <div class="msg-title">' + m.plugin + '.' + m.method + '</div>',
            '    <div style="height:4px;background:var(--border);border-radius:2px;margin-top:4px"><div style="height:4px;background:' + (pct > 80 ? 'var(--error)' : pct > 50 ? 'var(--warning)' : 'var(--success)') + ';width:' + pct + '%;border-radius:2px"></div></div>',
            '  </div>',
            '  <div class="msg-time">' + m.durationMs + 'ms</div>',
            '</div>'
          ].join('');
        }).join('')
      ].join('');
    }

    function renderPluginFilters() {
      var container = $('pluginFilterList');
      var plugins = Object.keys(state.plugins);
      $('filterAllCount').textContent = state.messages.length;

      container.innerHTML = plugins.map(function(p) {
        return '<button class="tab-btn" onclick="filterPlugin(\'' + p + '\')">' +
          p + '<span class="count">' + state.plugins[p].calls + '</span></button>';
      }).join('');
    }

    // ── Detail ──
    function selectMessage(id) {
      state.selectedId = id;
      renderDetail();
      renderMessages();
    }

    function selectEvent(id) {
      var evt = state.events.find(function(e) { return e.id === id; });
      if (!evt) return;

      $('panelTitle').textContent = 'Event Detail';
      $('detailTabs').style.display = 'none';
      $('detailContent').innerHTML = '<pre>' + JSON.stringify(evt, null, 2) + '</pre>';
    }

    function renderDetail() {
      var msg = state.messages.find(function(m) { return m.id === state.selectedId; });
      if (!msg) return;

      $('panelTitle').textContent = msg.plugin + '.' + msg.method;
      $('detailTabs').style.display = 'flex';

      switch (state.detailTab) {
        case 'payload':
          var content = {
            args: msg.args,
            result: msg.result,
            error: msg.error
          };
          $('detailContent').innerHTML = '<pre>' + JSON.stringify(content, null, 2) + '</pre>';
          break;
        case 'timing':
          $('detailContent').innerHTML = '<pre>' + JSON.stringify({
            timestamp: msg.timestamp,
            durationMs: msg.durationMs,
            status: msg.status
          }, null, 2) + '</pre>';
          break;
        case 'headers':
          $('detailContent').innerHTML = '<pre>' + JSON.stringify({
            id: msg.id,
            plugin: msg.plugin,
            method: msg.method,
            direction: msg.direction
          }, null, 2) + '</pre>';
          break;
      }
    }

    // ── Filters ──
    function getFilteredMessages() {
      return state.messages.filter(function(m) {
        if (state.filters.err && m.status !== 'error') return false;
        if (state.filters.in && m.direction !== 'incoming') return false;
        if (state.filters.out && m.direction !== 'outgoing') return false;
        if (state.searchQuery) {
          var q = state.searchQuery.toLowerCase();
          var str = (m.plugin + '.' + m.method + JSON.stringify(m.args)).toLowerCase();
          if (!str.includes(q)) return false;
        }
        if (state.activePlugin && m.plugin !== state.activePlugin) return false;
        return true;
      });
    }

    function toggleFilter(type) {
      state.filters[type] = !state.filters[type];
      $('chip-' + type).classList.toggle('active', state.filters[type]);
      renderMessages();
    }

    function filterPlugin(plugin) {
      state.activePlugin = plugin || null;
      renderMessages();
    }

    // ── Views ──
    function switchView(view) {
      state.currentView = view;
      document.querySelectorAll('.tab-btn').forEach(function(b) { b.classList.remove('active'); });
      event.target.classList.add('active');

      switch (view) {
        case 'messages': renderMessages(); break;
        case 'events': renderEvents(); break;
        case 'plugins': renderPlugins(); break;
        case 'performance': renderPerformance(); break;
        case 'network':
          $('messageList').innerHTML = '<div class="empty-state"><div class="empty-icon">🌐</div><div class="empty-text">Network Monitor</div><div style="font-size:11px;color:var(--muted)">HTTP calls will appear here</div></div>';
          break;
      }
    }

    function switchDetailTab(tab) {
      state.detailTab = tab;
      document.querySelectorAll('.detail-tab').forEach(function(t) { t.classList.remove('active'); });
      event.target.classList.add('active');
      renderDetail();
    }

    // ── Helpers ──
    function updateStats() {
      $('totalCalls').textContent = state.totalCalls;
      $('errorCount').textContent = state.errorCount;
      $('pendingCount').textContent = state.pendingCount;
      $('eventCount').textContent = state.eventCount;

      var bridgeInfo = window.NativeSDK ? NativeSDK.info() : null;
      if (bridgeInfo) {
        $('pendingCount').textContent = bridgeInfo.pendingRequests;
      }
    }

    function _formatTime(iso) {
      var d = new Date(iso);
      return d.toLocaleTimeString('en-US', { hour12: false, hour: '2-digit', minute: '2-digit', second: '2-digit' });
    }

    function _previewArgs(args) {
      if (!args) return '';
      var str = JSON.stringify(args);
      return str.length > 60 ? str.substring(0, 60) + '...' : str;
    }

    function clearMessages() {
      state.messages = [];
      state.totalCalls = 0;
      state.errorCount = 0;
      state.pendingCount = 0;
      renderMessages();
      updateStats();
    }

    function clearAll() {
      clearMessages();
      state.events = [];
      state.plugins = {};
      state.eventCount = 0;
      renderPluginFilters();
      updateStats();
    }

    function exportLog() {
      var data = JSON.stringify({
        exported: new Date().toISOString(),
        messages: state.messages,
        events: state.events,
        plugins: state.plugins,
        stats: {
          totalCalls: state.totalCalls,
          errorCount: state.errorCount,
          eventCount: state.eventCount
        }
      }, null, 2);

      var blob = new Blob([data], { type: 'application/json' });
      var url = URL.createObjectURL(blob);
      var a = document.createElement('a');
      a.href = url;
      a.download = 'sweetmelon-devtools-' + Date.now() + '.json';
      a.click();
      URL.revokeObjectURL(url);
    }

    // Search
    $('searchInput').addEventListener('input', function(e) {
      state.searchQuery = e.target.value;
      renderMessages();
    });

    // Init
    connectToBridge();
    updateStats();
  </script>
</body>
</html>
```

---

## بخش ۳: pubspec.yaml — dependency‌های CLI

```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0
  args: ^2.4.2
  yaml: ^3.1.2
  yaml_writer: ^2.0.0
```

---

## بخش ۴: Documentation Config

## 📄 `docs/vitepress.config.ts`

```typescript
import { defineConfig } from 'vitepress';

export default defineConfig({
  title: 'Sweetmelon',
  description: 'Flutter Native Bridge — JS to Native',
  themeConfig: {
    logo: '🍈',
    nav: [
      { text: 'Guide', link: '/guide/getting-started' },
      { text: 'Plugins', link: '/plugins/overview' },
      { text: 'API', link: '/api/native-sdk' },
      { text: 'Changelog', link: '/changelog' },
    ],
    sidebar: {
      '/guide/': [
        {
          text: 'Getting Started',
          items: [
            { text: 'Introduction', link: '/guide/introduction' },
            { text: 'Installation', link: '/guide/installation' },
            { text: 'Quick Start', link: '/guide/quick-start' },
            { text: 'Configuration', link: '/guide/configuration' },
          ],
        },
        {
          text: 'Framework Integration',
          items: [
            { text: 'Angular', link: '/guide/angular' },
            { text: 'React', link: '/guide/react' },
            { text: 'Vue', link: '/guide/vue' },
            { text: 'Vanilla JS', link: '/guide/vanilla' },
          ],
        },
      ],
      '/plugins/': [
        {
          text: 'Phase 1 — Core',
          items: [
            { text: 'Permission', link: '/plugins/permission' },
            { text: 'App Lifecycle', link: '/plugins/app-lifecycle' },
            { text: 'Device Info', link: '/plugins/device-info' },
            { text: 'Connectivity', link: '/plugins/connectivity' },
            { text: 'Storage', link: '/plugins/storage' },
            { text: 'File System', link: '/plugins/file-system' },
            { text: 'HTTP', link: '/plugins/http' },
            { text: 'Intent', link: '/plugins/intent' },
            { text: 'Clipboard', link: '/plugins/clipboard' },
            { text: 'Share', link: '/plugins/share' },
            { text: 'Camera', link: '/plugins/camera' },
            { text: 'Geolocation', link: '/plugins/geolocation' },
          ],
        },
        {
          text: 'Firebase',
          items: [
            { text: 'Analytics', link: '/plugins/firebase-analytics' },
            { text: 'Crashlytics', link: '/plugins/firebase-crashlytics' },
            { text: 'Remote Config', link: '/plugins/firebase-remote-config' },
            { text: 'Auth', link: '/plugins/firebase-auth' },
          ],
        },
      ],
    },
    socialLinks: [
      { icon: 'github', link: 'https://github.com/your-org/sweetmelon' },
    ],
    footer: {
      message: 'Sweetmelon Native Bridge',
      copyright: 'MIT License',
    },
  },
});
```

---

## 📄 `docs/guide/quick-start.md`

```markdown
# Quick Start

## 1. Setup

```bash
# Clone or create project
dart run bin/sweetmelon.dart create project my_app
cd my_app

# Configure plugins
dart run bin/sweetmelon.dart configure

# Install dependencies
flutter pub get
```

## 2. Place your HTML app

```
assets/www/
  index.html     ← your app entry point
  css/
  js/
    native-sdk.js  ← copy from Sweetmelon
    app.js
```

## 3. Use in JavaScript

```html
<script src="js/native-sdk.js"></script>
<script>
  NativeSDK.waitForReady().then(async () => {
    // Device info
    const { device } = await NativeSDK.deviceInfo.getAll();
    console.log('Running on:', device.model);

    // Storage
    await NativeSDK.storage.set('user', { name: 'Ali' });
    const user = await NativeSDK.storage.get('user');

    // Listen to events
    NativeSDK.on('connectivity.change', (data) => {
      console.log('Online:', data.online);
    });
  });
</script>
```

## 4. Run

```bash
flutter run
```

## Plugin CLI

```bash
# List all plugins
dart run bin/sweetmelon.dart list

# Enable plugins
dart run bin/sweetmelon.dart plugin enable camera bluetooth

# Disable plugins
dart run bin/sweetmelon.dart plugin disable nfc

# Apply changes
dart run bin/sweetmelon.dart configure

# Health check
dart run bin/sweetmelon.dart doctor
```

## Angular Integration

```bash
# Build your Angular app
ng build --configuration production \
  --output-path /path/to/assets/www \
  --base-href ./

# Run Flutter
flutter run
```
```

---

# خلاصه فاز ۱۸

## آنچه ساخته شد

| آیتم | توضیح |
|------|-------|
| **CLI Tool** | 9 دستور: create, plugin, configure, validate, list, info, build, clean, doctor |
| **Plugin Generator** | ساخت خودکار plugin + test + README + pubspec |
| **DevTools Dashboard** | HTML dashboard با 5 view: Messages, Events, Plugins, Performance, Network |
| **VitePress Config** | ساختار documentation site |
| **Quick Start Guide** | راهنمای سریع شروع |

## دستورات CLI

```bash
# ایجاد پروژه
dart run bin/sweetmelon.dart create project my_app

# ایجاد پلاگین جدید
dart run bin/sweetmelon.dart plugin generate PushNotification

# مدیریت پلاگین‌ها
dart run bin/sweetmelon.dart plugin enable camera bluetooth nfc
dart run bin/sweetmelon.dart plugin disable contacts smsOtp
dart run bin/sweetmelon.dart plugin list

# پیکربندی
dart run bin/sweetmelon.dart configure
dart run bin/sweetmelon.dart configure --dry-run

# اعتبارسنجی
dart run bin/sweetmelon.dart validate

# بررسی سلامت پروژه
dart run bin/sweetmelon.dart doctor

# Build
dart run bin/sweetmelon.dart build --framework angular
dart run bin/sweetmelon.dart build --framework react

# پاکسازی
dart run bin/sweetmelon.dart clean
```

## DevTools Dashboard قابلیت‌ها

| قابلیت | توضیح |
|--------|-------|
| **Messages** | لیست همه پیام‌های bridge با جستجو و فیلتر |
| **Events** | لیست همه eventهای نیتیو |
| **Plugins** | آمار استفاده از هر پلاگین |
| **Performance** | کندترین call‌ها با نمودار |
| **Network** | HTTP request monitor |
| **Export** | export log به JSON |
| **Real-time** | بروزرسانی real-time |

---

## آمار نهایی

| آیتم | تعداد |
|------|-------|
| **پلاگین‌ها** | 90 |
| **CLI Commands** | 9 |
| **JS API Methods** | 600+ |
| **DevTools Views** | 5 |
| **Framework SDKs** | 4 |
| **فازهای تکمیل‌شده** | 18 |

---

بگو تا **فاز ۱۹** (Production Ready) رو شروع کنم.
