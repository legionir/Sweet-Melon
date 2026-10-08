// regression: BUG-009 — arguments are validated before a plugin runs. A bad
// argument returns INVALID_ARGS and never reaches the native boundary.
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sweetmelon/packages/core/lib/src/protocol/message_protocol.dart';
import 'package:sweetmelon/packages/security/lib/security.dart';
import 'package:sweetmelon/plugins/camera/lib/camera_plugin.dart';
import 'package:sweetmelon/plugins/geolocation/lib/geolocation_plugin.dart';

import '../helpers/fakes.dart';
import '../helpers/picker_fakes.dart';

void main() {
  group('BUG-009 argument validation before execution', () {
    test('camera: non-numeric quality is INVALID_ARGS; the picker never opens',
        () async {
      final picker = CancellingPicker();
      final h = await EngineHarness.create(
        plugins: [CameraPlugin(picker: picker)],
        grants: {'camera': PermissionState.granted},
      );
      final response = await h.manager.execute(buildRequest(
        requestId: 'v1',
        plugin: 'camera',
        method: 'takePhoto',
        args: {'quality': 'high'},
      ));
      expect(response.error!.code, PluginErrorCode.invalidArgs);
      expect(picker.pickCalls, 0);
    });

    test('camera: fractional maxDurationSeconds is INVALID_ARGS', () async {
      final picker = CancellingPicker();
      final h = await EngineHarness.create(
        plugins: [CameraPlugin(picker: picker)],
        grants: {'camera': PermissionState.granted},
      );
      final response = await h.manager.execute(buildRequest(
        requestId: 'v2',
        plugin: 'camera',
        method: 'recordVideo',
        args: {'maxDurationSeconds': 2.5},
      ));
      expect(response.error!.code, PluginErrorCode.invalidArgs);
      expect(picker.pickCalls, 0);
    });

    test('geolocation: non-string accuracy is INVALID_ARGS; no stream opens',
        () async {
      var opened = 0;
      final plugin = GeolocationPlugin(positionStream: (settings) {
        opened++;
        return const Stream<Position>.empty();
      });
      final h = await EngineHarness.create(
        plugins: [plugin],
        grants: {'location': PermissionState.granted},
      );
      final response = await h.manager.execute(buildRequest(
        requestId: 'g1',
        plugin: 'geolocation',
        method: 'watchPosition',
        args: {'accuracy': 5},
      ));
      expect(response.error!.code, PluginErrorCode.invalidArgs);
      expect(opened, 0);
    });

    test('geolocation: out-of-range timeoutMs is INVALID_ARGS', () async {
      var opened = 0;
      final plugin = GeolocationPlugin(positionStream: (settings) {
        opened++;
        return const Stream<Position>.empty();
      });
      final h = await EngineHarness.create(
        plugins: [plugin],
        grants: {'location': PermissionState.granted},
      );
      final response = await h.manager.execute(buildRequest(
        requestId: 'g2',
        plugin: 'geolocation',
        method: 'watchPosition',
        args: {'timeoutMs': 0},
      ));
      expect(response.error!.code, PluginErrorCode.invalidArgs);
      expect(opened, 0);
    });

    test('control: valid geolocation arguments reach the plugin', () async {
      var opened = 0;
      final plugin = GeolocationPlugin(positionStream: (settings) {
        opened++;
        return const Stream<Position>.empty();
      });
      final h = await EngineHarness.create(
        plugins: [plugin],
        grants: {'location': PermissionState.granted},
      );
      final response = await h.manager.execute(buildRequest(
        requestId: 'g3',
        plugin: 'geolocation',
        method: 'watchPosition',
        args: {'accuracy': 'high', 'timeoutMs': 5000},
      ));
      expect(response.success, isTrue);
      expect(opened, 1);
    });
  });
}
