// regression: BUG-005 (watch events carry positions), BUG-013 (timeoutMs maps to
// the location time limit), SM-009 / SM-011 (watch subscriptions are removed on
// clearWatch, on stream error, and on dispose; the watch count is bounded).
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sweetmelon/packages/plugin_engine/lib/plugin_engine.dart';
import 'package:sweetmelon/plugins/geolocation/lib/geolocation_plugin.dart';

Position _position(double lat) => Position(
      latitude: lat,
      longitude: 4.5,
      timestamp: DateTime.utc(2026, 10, 8),
      accuracy: 5,
      altitude: 0,
      heading: 0,
      speed: 0,
      speedAccuracy: 0,
      altitudeAccuracy: 0,
      headingAccuracy: 0,
    );

void main() {
  late StreamController<Position> source;
  late List<LocationSettings> settingsSeen;
  late List<(String, Object?)> events;
  late GeolocationPlugin plugin;

  setUp(() async {
    source = StreamController<Position>();
    settingsSeen = [];
    events = [];
    plugin = GeolocationPlugin(positionStream: (settings) {
      settingsSeen.add(settings);
      return source.stream;
    });
    plugin.attachEmitter((event, data) async => events.add((event, data)));
    await plugin.initialize();
  });

  tearDown(() async {
    await plugin.dispose();
    await source.close();
  });

  test('watchPosition emits each position with its watchId (BUG-005)',
      () async {
    final result = await plugin.onCall('watchPosition', {});
    expect(result, {'watchId': 1});

    source.add(_position(45.3));
    source.add(_position(45.4));
    await pumpEventQueue();

    final positions = events.where((e) => e.$1 == 'geolocation.position');
    expect(positions.length, 2);
    final first = positions.first.$2 as Map;
    expect(first['watchId'], 1);
    expect(first['latitude'], 45.3);
  });

  test('timeoutMs becomes the location time limit (BUG-013)', () async {
    await plugin.onCall('watchPosition', {'timeoutMs': 5000});
    expect(settingsSeen.single.timeLimit, const Duration(seconds: 5));
  });

  test('clearWatch cancels the platform subscription (SM-011)', () async {
    final result = await plugin.onCall('watchPosition', {});
    final watchId = (result as Map)['watchId'];
    expect(plugin.activeWatchCount, 1);
    expect(source.hasListener, isTrue);

    final cleared = await plugin.onCall('clearWatch', {'watchId': watchId});
    expect(cleared, {'cleared': 1});
    expect(plugin.activeWatchCount, 0);
    expect(source.hasListener, isFalse);
  });

  test('a stream error emits a stable code and removes the watch (SM-009)',
      () async {
    await plugin.onCall('watchPosition', {});
    source.addError(StateError('raw platform detail'));
    await pumpEventQueue();

    final errors = events.where((e) => e.$1 == 'geolocation.error').toList();
    expect(errors.length, 1);
    expect(errors.single.$2, {'watchId': 1, 'code': 'LOCATION_ERROR'});
    expect(plugin.activeWatchCount, 0);
  });

  test('watches are bounded to kMaxWatches (SM-009)', () async {
    for (var i = 0; i < kMaxWatches; i++) {
      await plugin.onCall('watchPosition', {});
    }
    expect(
      () => plugin.onCall('watchPosition', {}),
      throwsA(isA<PluginException>()),
    );
    expect(plugin.activeWatchCount, kMaxWatches);
  });

  test('dispose cancels every watch (SM-011)', () async {
    await plugin.onCall('watchPosition', {});
    await plugin.dispose();
    expect(plugin.activeWatchCount, 0);
    expect(source.hasListener, isFalse);
  });
}
