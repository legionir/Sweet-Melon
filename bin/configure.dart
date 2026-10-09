// ignore_for_file: avoid_print
import 'dart:io';

import 'package:sweetmelon/cli/config_processor.dart';

/// CLI tool برای پردازش sweetmelon.yaml
/// اجرا: dart run bin/configure.dart
Future<void> main(List<String> args) async {
  print('🍈 Sweetmelon Configuration Tool');
  print('');

  final processor = ConfigProcessor();
  await processor.load();

  processor.printSummary();

  if (args.contains('--dry-run')) {
    print('');
    print('ℹ️  Dry run mode — no files generated');
    await processor.generateDependencyReport();
    return;
  }

  print('');
  print('Generating files...');
  print('');

  await processor.generateServiceLocator();
  await processor.generateAndroidPermissions();
  await processor.generateIosPermissions();
  await processor.generateDependencyReport();

  print('');
  print('🎉 Configuration complete!');
  print('');
  print('Next steps:');
  print('  1. Review generated files');
  print('  2. Update pubspec.yaml dependencies if needed');
  print('  3. Copy iOS permissions to Info.plist');
  print('  4. Run: flutter pub get');
  print('  5. Run: flutter run');
}
