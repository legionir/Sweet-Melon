import 'dart:async';
import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:plugin_engine/src/plugin_interface.dart';

// ============================================================
// CAMERA PLUGIN
// ============================================================

class CameraPlugin extends Plugin {
  final ImagePicker _picker = ImagePicker();

  @override
  String get name => 'camera';

  @override
  String get version => '1.0.0';

  @override
  String get description => 'Camera and image picker plugin';

  @override
  bool get cacheable => false; // نتایج دوربین نباید کش شوند

  @override
  List<String> get supportedMethods => [
        'takePhoto',
        'pickFromGallery',
        'recordVideo',
        'getInfo',
      ];

  @override
  List<String> get requiredPermissions => ['camera', 'storage'];

  @override
  Future<void> onInitialize() async {
    // آماده‌سازی اولیه در صورت نیاز
  }

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
        throw UnsupportedError('Method "$method" not supported');
    }
  }

  // ============================================================
  // METHODS
  // ============================================================

  Future<Map<String, dynamic>> _takePhoto(
    Map<String, dynamic> args,
  ) async {
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
      throw Exception('User cancelled photo capture');
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
        throw Exception('No images selected');
      }

      final imageList = <Map<String, dynamic>>[];
      for (final img in images) {
        imageList.add(await _xFileToMap(img));
      }

      return {'images': imageList};
    } else {
      final image = await _picker.pickImage(
        source: ImageSource.gallery,
      );

      if (image == null) {
        throw Exception('User cancelled');
      }

      return _xFileToMap(image);
    }
  }

  Future<Map<String, dynamic>> _recordVideo(
    Map<String, dynamic> args,
  ) async {
    final maxDuration = args['maxDurationSeconds'] as int?;

    final video = await _picker.pickVideo(
      source: ImageSource.camera,
      maxDuration:
          maxDuration != null ? Duration(seconds: maxDuration) : null,
    );

    if (video == null) {
      throw Exception('User cancelled');
    }

    final file = File(video.path);
    final stat = await file.stat();

    return {
      'path': video.path,
      'name': video.name,
      'size': stat.size,
      'mimeType': 'video/mp4',
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

  // ============================================================
  // HELPERS
  // ============================================================

  Future<Map<String, dynamic>> _xFileToMap(XFile xFile) async {
    final file = File(xFile.path);
    final stat = await file.stat();

    return {
      'path': xFile.path,
      'name': xFile.name,
      'size': stat.size,
      'mimeType': xFile.mimeType ?? 'image/jpeg',
    };
  }

  // ============================================================
  // VALIDATION
  // ============================================================

  @override
  Future<ValidationResult> validateArgs(
    String method,
    Map<String, dynamic> args,
  ) async {
    switch (method) {
      case 'takePhoto':
        return _validateTakePhoto(args);
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
        return ValidationResult.invalid(
          'quality must be a number',
        );
      }
      if (quality < 0 || quality > 100) {
        return ValidationResult.invalid(
          'quality must be between 0 and 100',
        );
      }
    }

    final maxWidth = args['maxWidth'];
    if (maxWidth != null && maxWidth is! num) {
      return ValidationResult.invalid('maxWidth must be a number');
    }

    final maxHeight = args['maxHeight'];
    if (maxHeight != null && maxHeight is! num) {
      return ValidationResult.invalid('maxHeight must be a number');
    }

    return ValidationResult.valid();
  }

  ValidationResult _validateRecordVideo(Map<String, dynamic> args) {
    final maxDuration = args['maxDurationSeconds'];
    if (maxDuration != null) {
      if (maxDuration is! int) {
        return ValidationResult.invalid(
          'maxDurationSeconds must be an integer',
        );
      }
      if (maxDuration <= 0) {
        return ValidationResult.invalid(
          'maxDurationSeconds must be positive',
        );
      }
    }

    return ValidationResult.valid();
  }
}