import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:sweetmelon/packages/core/lib/src/protocol/message_protocol.dart';
import 'package:sweetmelon/packages/plugin_engine/lib/plugin_engine.dart';

// ============================================================
// CAMERA PLUGIN
// ============================================================
//
// * A user cancelling the picker is reported as CANCELLED (BUG-006), not as a
//   generic execution error.
// * The native picker is single-instance, so the plugin allows exactly one
//   concurrent call; the manager rejects overlapping calls (BUG-006, SM-002).
// * All arguments are validated before the picker is opened.

class CameraPlugin extends Plugin {
  final ImagePicker _picker;

  CameraPlugin({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  @override
  String get name => 'camera';

  @override
  String get version => '1.1.0';

  @override
  String get description => 'Camera and image picker plugin';

  @override
  PluginCapabilities get capabilities => const PluginCapabilities(
        supportsStreaming: false,
        supportsBatch: false,
        supportsCache: false,
        maxConcurrentCalls: 1,
      );

  @override
  List<String> get supportedMethods => const [
        'takePhoto',
        'pickFromGallery',
        'recordVideo',
        'getInfo',
      ];

  @override
  List<String> get requiredPermissions => const ['camera'];

  @override
  Future<dynamic> onCall(String method, Map<String, dynamic> args) async {
    switch (method) {
      case 'takePhoto':
        return _takePhoto(args);
      case 'pickFromGallery':
        return _pickFromGallery(args);
      case 'recordVideo':
        return _recordVideo(args);
      case 'getInfo':
        return _getInfo();
      default:
        throw const PluginException(
          PluginErrorCode.methodNotFound,
          'Method is not supported',
        );
    }
  }

  Future<Map<String, dynamic>> _takePhoto(Map<String, dynamic> args) async {
    final quality = (args['quality'] as num?)?.toInt() ?? 80;
    final maxWidth = (args['maxWidth'] as num?)?.toDouble();
    final maxHeight = (args['maxHeight'] as num?)?.toDouble();

    final image = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: quality,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
    );
    if (image == null) {
      throw const PluginException(
        PluginErrorCode.cancelled,
        'User cancelled photo capture',
      );
    }
    return _xFileToMap(image);
  }

  Future<Map<String, dynamic>> _pickFromGallery(
    Map<String, dynamic> args,
  ) async {
    final multiple = args['multiple'] as bool? ?? false;

    if (multiple) {
      final images = await _picker.pickMultiImage();
      if (images.isEmpty) {
        throw const PluginException(
          PluginErrorCode.cancelled,
          'No images selected',
        );
      }
      final imageList = <Map<String, dynamic>>[];
      for (final img in images) {
        imageList.add(await _xFileToMap(img));
      }
      return {'images': imageList};
    }

    final image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) {
      throw const PluginException(
        PluginErrorCode.cancelled,
        'User cancelled image selection',
      );
    }
    return _xFileToMap(image);
  }

  Future<Map<String, dynamic>> _recordVideo(
    Map<String, dynamic> args,
  ) async {
    final maxDuration = args['maxDurationSeconds'] as int?;

    final video = await _picker.pickVideo(
      source: ImageSource.camera,
      maxDuration: maxDuration != null ? Duration(seconds: maxDuration) : null,
    );
    if (video == null) {
      throw const PluginException(
        PluginErrorCode.cancelled,
        'User cancelled video capture',
      );
    }

    final stat = await File(video.path).stat();
    return {
      'path': video.path,
      'name': video.name,
      'size': stat.size,
      'mimeType': video.mimeType ?? 'video/mp4',
    };
  }

  Map<String, dynamic> _getInfo() {
    return {
      'name': name,
      'version': version,
      'supportedMethods': supportedMethods,
      'platform': Platform.operatingSystem,
    };
  }

  Future<Map<String, dynamic>> _xFileToMap(XFile xFile) async {
    final stat = await File(xFile.path).stat();
    return {
      'path': xFile.path,
      'name': xFile.name,
      'size': stat.size,
      'mimeType': xFile.mimeType ?? 'image/jpeg',
    };
  }

  @override
  Future<ValidationResult> validateArgs(
    String method,
    Map<String, dynamic> args,
  ) async {
    switch (method) {
      case 'takePhoto':
        return _validateTakePhoto(args);
      case 'pickFromGallery':
        final multiple = args['multiple'];
        if (multiple != null && multiple is! bool) {
          return ValidationResult.invalid('multiple must be a boolean');
        }
        return ValidationResult.valid();
      case 'recordVideo':
        return _validateRecordVideo(args);
      default:
        return ValidationResult.valid();
    }
  }

  ValidationResult _validateTakePhoto(Map<String, dynamic> args) {
    final quality = args['quality'];
    if (quality != null) {
      if (quality is! num) {
        return ValidationResult.invalid('quality must be a number');
      }
      if (quality < 0 || quality > 100) {
        return ValidationResult.invalid('quality must be between 0 and 100');
      }
    }
    for (final dimension in const ['maxWidth', 'maxHeight']) {
      final value = args[dimension];
      if (value != null) {
        if (value is! num) {
          return ValidationResult.invalid('$dimension must be a number');
        }
        if (value <= 0 || value > 10000) {
          return ValidationResult.invalid(
            '$dimension must be between 1 and 10000',
          );
        }
      }
    }
    return ValidationResult.valid();
  }

  ValidationResult _validateRecordVideo(Map<String, dynamic> args) {
    final maxDuration = args['maxDurationSeconds'];
    if (maxDuration != null) {
      if (maxDuration is! int) {
        return ValidationResult.invalid('maxDurationSeconds must be an integer');
      }
      if (maxDuration <= 0 || maxDuration > 3600) {
        return ValidationResult.invalid(
          'maxDurationSeconds must be between 1 and 3600',
        );
      }
    }
    return ValidationResult.valid();
  }
}
