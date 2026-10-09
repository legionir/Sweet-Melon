import 'package:flutter_test/flutter_test.dart';
import 'package:sweetmelon/plugins/cache_control/lib/cache_control_plugin.dart';

void main() {
  group('CacheControlPlugin', () {
    late CacheControlPlugin plugin;

    setUp(() async {
      plugin = CacheControlPlugin();
      await plugin.initialize();
    });

    test('getInfo returns plugin info', () async {
      final r = await plugin.onCall('getInfo', {});
      expect(r['name'], 'cacheControl');
    });

    test('supports all declared methods', () {
      expect(plugin.supportsMethod('clearWebViewCache'), true);
      expect(plugin.supportsMethod('clearAppCache'), true);
      expect(plugin.supportsMethod('getCacheSize'), true);
      expect(plugin.supportsMethod('clearAll'), true);
    });
  });
}
