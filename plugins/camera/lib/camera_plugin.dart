import 'dart:async';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../../packages/plugin_engine/lib/src/plugin_interface.dart';
import '../../../packages/security/lib/src/execution_guard.dart';

// ============================================================
// CAMERA PLUGIN — نمونه پلاگین دوربین
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
    // بررسی دسترسی
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

    final file = File(image.path);
    final bytes = await file.readAsBytes();
    final stat = await file.stat();

    return {
      'path': image.path,
      'name': image.name,
      'size': stat.size,
      'mimeType': 'image/jpeg',
      'width': null, // از image info بگیرید
      'height': null,
    };
  }

  Future<Map<String, dynamic>> _pickFromGallery(
    Map<String, dynamic> args,
  ) async {
    final multiple = args['multiple'] as bool? ?? false;

    if (multiple) {
      final images = await _picker.pickMultiImage();
      
      return {
        'images': await Future.wait(
          images.map((img) async {
            final file = File(img.path);
            final stat = await file.stat();
            return {
              'path': img.path,
              'name': img.name,
              'size': stat.size,
            };
          }),
        ),
      };
    } else {
      final image = await _picker.pickImage(
        source: ImageSource.gallery,
      );
      
      if (image == null) throw Exception('User cancelled');
      
      final file = File(image.path);
      final stat = await file.stat();
      
      return {
        'path': image.path,
        'name': image.name,
        'size': stat.size,
      };
    }
  }

  Future<Map<String, dynamic>> _recordVideo(
    Map<String, dynamic> args,
  ) async {
    final maxDuration = args['maxDurationSeconds'] as int?;

    final video = await _picker.pickVideo(
      source: ImageSource.camera,
      maxDuration: maxDuration != null
          ? Duration(seconds: maxDuration)
          : null,
    );

    if (video == null) throw Exception('User cancelled');

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

  @override
  Future<ValidationResult> validateArgs(
    String method,
    Map<String, dynamic> args,
  ) async {
    if (method == 'takePhoto') {
      final quality = args['quality'];
      if (quality != null && quality is int) {
        if (quality < 0 || quality > 100) {
          return ValidationResult.invalid(
            'Quality must be between 0 and 100',
          );
        }
      }
    }
    return ValidationResult.valid();
  }
}
