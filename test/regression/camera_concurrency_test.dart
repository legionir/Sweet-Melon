// regression: CONC-001 — the camera allows one call at a time (maxConcurrentCalls
// is 1, because the image picker cannot present two pickers at once). A second
// call while the first is open is refused with RATE_LIMIT_EXCEEDED, before the
// picker is opened, and the slot is released when the first call finishes.
import 'package:flutter_test/flutter_test.dart';
import 'package:sweetmelon/packages/core/lib/src/protocol/message_protocol.dart';
import 'package:sweetmelon/packages/security/lib/security.dart';
import 'package:sweetmelon/plugins/camera/lib/camera_plugin.dart';

import '../helpers/fakes.dart';
import '../helpers/picker_fakes.dart';

void main() {
  const grants = {'camera': PermissionState.granted};

  test('CONC-001: a second camera call while the first is open is refused',
      () async {
    final picker = BlockingPicker();
    final h = await EngineHarness.create(
      plugins: [CameraPlugin(picker: picker)],
      grants: grants,
    );

    final first = h.manager.execute(
      buildRequest(requestId: 'first', plugin: 'camera', method: 'takePhoto'),
    );
    // The first call is async (permission and argument checks come first).
    // Wait, bounded, until it has reached the picker and holds its slot.
    for (var i = 0; i < 1000 && picker.pickCalls == 0; i++) {
      await Future<void>.delayed(Duration.zero);
    }
    expect(picker.pickCalls, 1);

    final second = await h.manager.execute(
      buildRequest(requestId: 'second', plugin: 'camera', method: 'takePhoto'),
    );
    expect(second.error!.code, PluginErrorCode.rateLimitExceeded);
    expect(
      picker.pickCalls,
      1,
      reason: 'the refused call must not open the picker',
    );

    picker.release();
    final firstResult = await first;
    expect(firstResult.error!.code, PluginErrorCode.cancelled);

    // The slot is free again.
    final third = await h.manager.execute(
      buildRequest(requestId: 'third', plugin: 'camera', method: 'takePhoto'),
    );
    expect(third.error?.code, isNot(PluginErrorCode.rateLimitExceeded));
    expect(picker.pickCalls, 2);
  });
}
