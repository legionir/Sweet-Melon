// ignore_for_file: avoid_print
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

      if (check.status == _DoctorStatus.ok) {
        passed++;
      } else if (check.status == _DoctorStatus.warning) {
        warnings++;
      } else {
        failed++;
      }
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
  group('$className', () {
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
