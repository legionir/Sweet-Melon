// regression: BUG-008 — a user cancelling the camera or picker is reported as
// CANCELLED with the documented message. It is not an execution error, it does
// not leave the plugin busy, and it does not leave stale state behind.
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sweetmelon/packages/core/lib/src/protocol/message_protocol.dart';
import 'package:sweetmelon/packages/security/lib/security.dart';
import 'package:sweetmelon/plugins/camera/lib/camera_plugin.dart';

import '../helpers/fakes.dart';

/// Fake picker for the native boundary. Every picker call returns what the user
/// selected: nothing for single pickers, [selection] for the multi picker.
/// `noSuchMethod` forwards any other member, so the fake does not depend on the
/// exact parameter lists of the image_picker version.
class CancellingPicker implements ImagePicker {
  int pickCalls = 0;
  final List<XFile> selection;

  CancellingPicker({this.selection = const []});

  @override
  dynamic noSuchMethod(Invocation invocation) {
    final name = invocation.memberName;
    if (name == #pickMultiImage) {
      pickCalls++;
      return Future<List<XFile>>.value(selection);
    }
    if (name == #pickImage || name == #pickVideo) {
      pickCalls++;
      return Future<XFile?>.value(null);
    }
    return super.noSuchMethod(invocation);
  }
}

void main() {
  const grants = {'camera': PermissionState.granted};

  Future<EngineHarness> harness(CancellingPicker picker) {
    return EngineHarness.create(
      plugins: [CameraPlugin(picker: picker)],
      grants: grants,
    );
  }

  group('BUG-008 picker cancellation', () {
    test('takePhoto cancel returns CANCELLED with the documented message',
        () async {
      final picker = CancellingPicker();
      final h = await harness(picker);
      final response = await h.manager.execute(
        buildRequest(requestId: 'p1', plugin: 'camera', method: 'takePhoto'),
      );
      expect(response.success, isFalse);
      expect(response.error!.code, PluginErrorCode.cancelled);
      expect(response.error!.message, 'User cancelled photo capture');
      expect(picker.pickCalls, 1);
    });

    test('recordVideo cancel returns CANCELLED', () async {
      final h = await harness(CancellingPicker());
      final response = await h.manager.execute(
        buildRequest(requestId: 'v1', plugin: 'camera', method: 'recordVideo'),
      );
      expect(response.error!.code, PluginErrorCode.cancelled);
      expect(response.error!.message, 'User cancelled video capture');
    });

    test('empty multi-selection returns CANCELLED', () async {
      final h = await harness(CancellingPicker());
      final response = await h.manager.execute(
        buildRequest(
          requestId: 'g1',
          plugin: 'camera',
          method: 'pickFromGallery',
          args: {'multiple': true},
        ),
      );
      expect(response.error!.code, PluginErrorCode.cancelled);
      expect(response.error!.message, 'No images selected');
    });

    test('cancel does not leave the plugin busy (no stale in-flight state)',
        () async {
      final h = await harness(CancellingPicker());
      for (var i = 0; i < 3; i++) {
        final response = await h.manager.execute(
          buildRequest(
            requestId: 'repeat_$i',
            plugin: 'camera',
            method: 'takePhoto',
          ),
        );
        // maxConcurrentCalls is 1: a leaked in-flight slot would show up as a
        // rejection instead of the cancellation.
        expect(response.error!.code, PluginErrorCode.cancelled,
            reason: 'attempt $i');
      }
    });

    test('cancel is not reported as an execution error',
        () async {
      final h = await harness(CancellingPicker());
      final response = await h.manager.execute(
        buildRequest(requestId: 'c1', plugin: 'camera', method: 'takePhoto'),
      );
      expect(response.data, isNull);
      expect(response.error!.code, isNot(PluginErrorCode.executionError));
    });
  });
}
