import 'dart:io';

import 'package:yaml/yaml.dart';
import 'package:yaml_writer/yaml_writer.dart';

/// CLI tool برای فعال/غیرفعال کردن پلاگین‌ها
/// اجرا:
///   dart run bin/plugin.dart enable camera bluetooth nfc
///   dart run bin/plugin.dart disable sms_otp contacts
///   dart run bin/plugin.dart list
///   dart run bin/plugin.dart info camera
Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    _printUsage();
    return;
  }

  final command = args[0];

  switch (command) {
    case 'enable':
      if (args.length < 2) {
        print('Usage: dart run bin/plugin.dart enable <plugin1> <plugin2> ...');
        return;
      }
      await _setPlugins(args.sublist(1), true);
      break;

    case 'disable':
      if (args.length < 2) {
        print('Usage: dart run bin/plugin.dart disable <plugin1> <plugin2> ...');
        return;
      }
      await _setPlugins(args.sublist(1), false);
      break;

    case 'list':
      await _listPlugins();
      break;

    case 'info':
      if (args.length < 2) {
        print('Usage: dart run bin/plugin.dart info <plugin>');
        return;
      }
      _showInfo(args[1]);
      break;

    case 'enable-all':
      await _setAll(true);
      break;

    case 'disable-all':
      await _setAll(false);
      break;

    default:
      print('Unknown command: $command');
      _printUsage();
  }
}

void _printUsage() {
  print('🍈 Sweetmelon Plugin Manager');
  print('');
  print('Usage:');
  print('  dart run bin/plugin.dart enable <plugins...>');
  print('  dart run bin/plugin.dart disable <plugins...>');
  print('  dart run bin/plugin.dart list');
  print('  dart run bin/plugin.dart info <plugin>');
  print('  dart run bin/plugin.dart enable-all');
  print('  dart run bin/plugin.dart disable-all');
  print('');
  print('After changes, run:');
  print('  dart run bin/configure.dart');
}

Future<Map<String, dynamic>> _readConfig() async {
  final file = File('sweetmelon.yaml');
  if (!await file.exists()) {
    print('sweetmelon.yaml not found');
    exit(1);
  }

  final content = await file.readAsString();
  final yaml = loadYaml(content);

  // Deep convert YamlMap to regular Map
  return _yamlToMap(yaml);
}

Map<String, dynamic> _yamlToMap(dynamic yaml) {
  if (yaml is YamlMap) {
    return yaml.map((key, value) => MapEntry(key.toString(), _yamlToMap(value)));
  }
  if (yaml is YamlList) {
    return {'list': yaml.map(_yamlToMap).toList()};
  }
  return {'value': yaml};
}

Future<void> _writeConfig(Map<String, dynamic> config) async {
  final writer = YamlWriter();
  final yamlString = writer.write(config);
  await File('sweetmelon.yaml').writeAsString(yamlString);
}

Future<void> _setPlugins(List<String> pluginIds, bool enabled) async {
  final file = File('sweetmelon.yaml');
  final content = await file.readAsString();
  var updated = content;

  for (final id in pluginIds) {
    // ساده‌ترین روش: regex replace
    final pattern = RegExp(
      r'(\s+' + id + r':\s*\n\s+enabled:\s*)(true|false)',
      multiLine: true,
    );

    if (pattern.hasMatch(updated)) {
      updated = updated.replaceAllMapped(pattern, (match) {
        return '${match.group(1)}$enabled';
      });
      print('${enabled ? "✅" : "❌"} ${id.padRight(20)} → ${enabled ? "enabled" : "disabled"}');
    } else {
      print('⚠️  Plugin not found in config: $id');
    }
  }

  await file.writeAsString(updated);

  print('');
  print('Run "dart run bin/configure.dart" to apply changes.');
}

Future<void> _setAll(bool enabled) async {
  final file = File('sweetmelon.yaml');
  var content = await file.readAsString();

  final pattern = RegExp(
    r'(enabled:\s*)(true|false)',
    multiLine: true,
  );

  content = content.replaceAllMapped(pattern, (match) {
    return '${match.group(1)}$enabled';
  });

  await file.writeAsString(content);
  print('${enabled ? "✅" : "❌"} All plugins ${enabled ? "enabled" : "disabled"}');
  print('Run "dart run bin/configure.dart" to apply changes.');
}

Future<void> _listPlugins() async {
  final file = File('sweetmelon.yaml');
  if (!await file.exists()) {
    print('sweetmelon.yaml not found');
    return;
  }

  final content = await file.readAsString();
  final yaml = loadYaml(content) as YamlMap;
  final plugins = yaml['plugins'] as YamlMap?;

  if (plugins == null) {
    print('No plugins section found');
    return;
  }

  int enabledCount = 0;
  int disabledCount = 0;

  print('');
  print('🍈 Plugin Status');
  print('────────────────');

  for (final entry in plugins.entries) {
    final id = entry.key.toString();
    final config = entry.value as YamlMap?;
    final enabled = config?['enabled'] as bool? ?? true;

    if (enabled) {
      enabledCount++;
      print('  ✅ $id');
    } else {
      disabledCount++;
      print('  ❌ $id');
    }
  }

  print('');
  print('Enabled: $enabledCount | Disabled: $disabledCount | Total: ${enabledCount + disabledCount}');
}

void _showInfo(String pluginId) {
  final allPlugins = [
    // simplified - in real impl, import from plugin_registry_data.dart
  ];

  print('Plugin info for: $pluginId');
  print('(Use plugin_registry_data.dart for full details)');
}
