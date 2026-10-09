# فاز ۱۷: Advanced Plugins

---

# پلاگین ۱: Camera Preview

## 📄 `lib/plugins/camera_preview/lib/camera_preview_plugin.dart`

```dart
import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sweetmelon/packages/core/lib/core.dart';
import 'package:sweetmelon/packages/plugin_engine/lib/plugin_engine.dart';

typedef CameraPreviewEventEmitter = Future<void> Function(
  String event,
  dynamic data,
);

class CameraPreviewPlugin extends Plugin {
  final CameraPreviewEventEmitter? eventEmitter;

  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _initialized = false;
  bool _recording = false;
  int _currentCameraIndex = 0;
  String? _lastPhotoPath;

  CameraPreviewPlugin({this.eventEmitter});

  @override
  String get name => 'cameraPreview';

  @override
  String get version => '1.0.0';

  @override
  String get description => 'Native camera preview with custom controls';

  @override
  List<String> get requiredPermissions => ['camera', 'microphone'];

  @override
  List<String> get supportedMethods => [
        'start',
        'stop',
        'takePhoto',
        'startRecording',
        'stopRecording',
        'switchCamera',
        'setFlashMode',
        'setZoomLevel',
        'getMinZoomLevel',
        'getMaxZoomLevel',
        'setFocusPoint',
        'setExposureMode',
        'getAvailableCameras',
        'getState',
        'getInfo',
      ];

  @override
  Future<void> onInitialize() async {
    try {
      _cameras = await availableCameras();
      BridgeLogger.info(
        'CameraPreview',
        'Found ${_cameras?.length ?? 0} cameras',
      );
    } catch (e) {
      BridgeLogger.error('CameraPreview', 'Init failed: $e');
    }
  }

  @override
  Future<void> onDispose() async {
    await _stopController();
  }

  @override
  Future<dynamic> onCall(String method, Map<String, dynamic> args) async {
    switch (method) {
      case 'start':
        return _start(args);
      case 'stop':
        return _stop();
      case 'takePhoto':
        return _takePhoto(args);
      case 'startRecording':
        return _startRecording(args);
      case 'stopRecording':
        return _stopRecording();
      case 'switchCamera':
        return _switchCamera();
      case 'setFlashMode':
        return _setFlashMode(args);
      case 'setZoomLevel':
        return _setZoomLevel(args);
      case 'getMinZoomLevel':
        return _getMinZoomLevel();
      case 'getMaxZoomLevel':
        return _getMaxZoomLevel();
      case 'setFocusPoint':
        return _setFocusPoint(args);
      case 'setExposureMode':
        return _setExposureMode(args);
      case 'getAvailableCameras':
        return _getAvailableCameras();
      case 'getState':
        return _getState();
      case 'getInfo':
        return {
          'name': name,
          'version': version,
          'camerasCount': _cameras?.length ?? 0,
          'initialized': _initialized,
          'recording': _recording,
        };
      default:
        throw UnsupportedError('Method "$method" not supported');
    }
  }

  Future<Map<String, dynamic>> _start(Map<String, dynamic> args) async {
    if (_cameras == null || _cameras!.isEmpty) {
      return {'started': false, 'reason': 'no_cameras'};
    }

    final cameraIndex = (args['cameraIndex'] as num?)?.toInt() ?? 0;
    final resolutionStr = args['resolution'] as String? ?? 'high';
    final enableAudio = args['enableAudio'] as bool? ?? true;

    _currentCameraIndex = cameraIndex.clamp(0, _cameras!.length - 1);
    final camera = _cameras![_currentCameraIndex];
    final resolution = _parseResolution(resolutionStr);

    try {
      await _stopController();

      _controller = CameraController(
        camera,
        resolution,
        enableAudio: enableAudio,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _controller!.initialize();
      _initialized = true;

      BridgeLogger.info('CameraPreview', 'Started: ${camera.name}');

      eventEmitter?.call('cameraPreview.started', {
        'cameraIndex': _currentCameraIndex,
        'cameraName': camera.name,
        'lensDirection': camera.lensDirection.name,
        'resolution': resolutionStr,
      });

      return {
        'started': true,
        'cameraIndex': _currentCameraIndex,
        'cameraName': camera.name,
        'lensDirection': camera.lensDirection.name,
        'sensorOrientation': camera.sensorOrientation,
      };
    } catch (e) {
      BridgeLogger.error('CameraPreview', 'Start failed: $e');
      return {'started': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> _stop() async {
    await _stopController();

    eventEmitter?.call('cameraPreview.stopped', {
      'timestamp': DateTime.now().toIso8601String(),
    });

    return {'stopped': true};
  }

  Future<void> _stopController() async {
    if (_recording) {
      try {
        await _controller?.stopVideoRecording();
      } catch (_) {}
      _recording = false;
    }
    await _controller?.dispose();
    _controller = null;
    _initialized = false;
  }

  Future<Map<String, dynamic>> _takePhoto(Map<String, dynamic> args) async {
    if (!_initialized || _controller == null) {
      return {'captured': false, 'reason': 'not_initialized'};
    }

    final fileName = args['fileName'] as String? ??
        'photo_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final saveToGallery = args['saveToGallery'] as bool? ?? false;

    try {
      final xFile = await _controller!.takePicture();

      final dir = await getApplicationDocumentsDirectory();
      final photoDir = Directory(p.join(dir.path, 'camera'));
      await photoDir.create(recursive: true);

      final targetPath = p.join(photoDir.path, fileName);
      final file = File(xFile.path);
      await file.copy(targetPath);
      await file.delete();

      final stat = await File(targetPath).stat();
      _lastPhotoPath = targetPath;

      BridgeLogger.info('CameraPreview', 'Photo taken: $targetPath');

      eventEmitter?.call('cameraPreview.photoTaken', {
        'path': targetPath,
        'fileName': fileName,
        'size': stat.size,
      });

      return {
        'captured': true,
        'path': targetPath,
        'fileName': fileName,
        'size': stat.size,
      };
    } catch (e) {
      return {'captured': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> _startRecording(
    Map<String, dynamic> args,
  ) async {
    if (!_initialized || _controller == null) {
      return {'started': false, 'reason': 'not_initialized'};
    }
    if (_recording) {
      return {'started': false, 'reason': 'already_recording'};
    }

    try {
      await _controller!.startVideoRecording();
      _recording = true;

      eventEmitter?.call('cameraPreview.recordingStarted', {
        'timestamp': DateTime.now().toIso8601String(),
      });

      return {'started': true};
    } catch (e) {
      return {'started': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> _stopRecording() async {
    if (!_recording || _controller == null) {
      return {'stopped': false, 'reason': 'not_recording'};
    }

    try {
      final xFile = await _controller!.stopVideoRecording();
      _recording = false;

      final dir = await getApplicationDocumentsDirectory();
      final videoDir = Directory(p.join(dir.path, 'camera'));
      await videoDir.create(recursive: true);

      final fileName =
          'video_${DateTime.now().millisecondsSinceEpoch}.mp4';
      final targetPath = p.join(videoDir.path, fileName);
      final file = File(xFile.path);
      await file.copy(targetPath);
      await file.delete();

      final stat = await File(targetPath).stat();

      eventEmitter?.call('cameraPreview.recordingStopped', {
        'path': targetPath,
        'size': stat.size,
      });

      return {
        'stopped': true,
        'path': targetPath,
        'fileName': fileName,
        'size': stat.size,
      };
    } catch (e) {
      _recording = false;
      return {'stopped': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> _switchCamera() async {
    if (_cameras == null || _cameras!.length < 2) {
      return {'switched': false, 'reason': 'no_other_camera'};
    }

    _currentCameraIndex = (_currentCameraIndex + 1) % _cameras!.length;

    final wasRecording = _recording;
    await _stop();
    final result = await _start({
      'cameraIndex': _currentCameraIndex,
    });

    return {
      'switched': true,
      'cameraIndex': _currentCameraIndex,
      'lensDirection': _cameras![_currentCameraIndex].lensDirection.name,
      ...result,
    };
  }

  Future<Map<String, dynamic>> _setFlashMode(
    Map<String, dynamic> args,
  ) async {
    if (_controller == null) {
      return {'set': false, 'reason': 'not_initialized'};
    }

    final mode = _parseFlashMode(args['mode'] as String? ?? 'auto');

    try {
      await _controller!.setFlashMode(mode);
      return {'set': true, 'mode': mode.name};
    } catch (e) {
      return {'set': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> _setZoomLevel(
    Map<String, dynamic> args,
  ) async {
    if (_controller == null) {
      return {'set': false, 'reason': 'not_initialized'};
    }

    final zoom = (args['zoom'] as num).toDouble();

    try {
      await _controller!.setZoomLevel(zoom);
      return {'set': true, 'zoom': zoom};
    } catch (e) {
      return {'set': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> _getMinZoomLevel() async {
    if (_controller == null) return {'level': 1.0};
    final min = await _controller!.getMinZoomLevel();
    return {'level': min};
  }

  Future<Map<String, dynamic>> _getMaxZoomLevel() async {
    if (_controller == null) return {'level': 1.0};
    final max = await _controller!.getMaxZoomLevel();
    return {'level': max};
  }

  Future<Map<String, dynamic>> _setFocusPoint(
    Map<String, dynamic> args,
  ) async {
    if (_controller == null) {
      return {'set': false, 'reason': 'not_initialized'};
    }

    final x = (args['x'] as num).toDouble();
    final y = (args['y'] as num).toDouble();

    try {
      await _controller!.setFocusPoint(Offset(x, y));
      return {'set': true, 'x': x, 'y': y};
    } catch (e) {
      return {'set': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> _setExposureMode(
    Map<String, dynamic> args,
  ) async {
    if (_controller == null) {
      return {'set': false, 'reason': 'not_initialized'};
    }

    final mode = args['mode'] as String? ?? 'auto';

    try {
      await _controller!.setExposureMode(
        mode == 'locked' ? ExposureMode.locked : ExposureMode.auto,
      );
      return {'set': true, 'mode': mode};
    } catch (e) {
      return {'set': false, 'error': e.toString()};
    }
  }

  Map<String, dynamic> _getAvailableCameras() {
    return {
      'cameras': _cameras?.map((c) => {
            'name': c.name,
            'lensDirection': c.lensDirection.name,
            'sensorOrientation': c.sensorOrientation,
          }).toList() ?? [],
      'count': _cameras?.length ?? 0,
    };
  }

  Map<String, dynamic> _getState() {
    return {
      'initialized': _initialized,
      'recording': _recording,
      'currentCameraIndex': _currentCameraIndex,
      'lastPhotoPath': _lastPhotoPath,
      'hasController': _controller != null,
    };
  }

  ResolutionPreset _parseResolution(String resolution) {
    switch (resolution) {
      case 'low':
        return ResolutionPreset.low;
      case 'medium':
        return ResolutionPreset.medium;
      case 'high':
        return ResolutionPreset.high;
      case 'veryHigh':
        return ResolutionPreset.veryHigh;
      case 'ultraHigh':
        return ResolutionPreset.ultraHigh;
      case 'max':
        return ResolutionPreset.max;
      default:
        return ResolutionPreset.high;
    }
  }

  FlashMode _parseFlashMode(String mode) {
    switch (mode) {
      case 'off':
        return FlashMode.off;
      case 'auto':
        return FlashMode.auto;
      case 'always':
        return FlashMode.always;
      case 'torch':
        return FlashMode.torch;
      default:
        return FlashMode.auto;
    }
  }
}
```

## 📄 `lib/plugins/camera_preview/pubspec.yaml`

```yaml
name: camera_preview_plugin
description: Native camera preview plugin
version: 1.0.0

environment:
  sdk: ^3.0.0

dependencies:
  flutter:
    sdk: flutter
  plugin_engine:
    path: ../../packages/plugin_engine
  core:
    path: ../../packages/core
  camera: ^0.11.0+2
  path_provider: ^2.1.1
  path: ^1.9.0
```

---

# پلاگین ۲: Document Scanner

## 📄 `lib/plugins/document_scanner/lib/document_scanner_plugin.dart`

```dart
import 'dart:async';
import 'dart:io';

import 'package:cunning_document_scanner/cunning_document_scanner.dart';
import 'package:sweetmelon/packages/core/lib/core.dart';
import 'package:sweetmelon/packages/plugin_engine/lib/plugin_engine.dart';

class DocumentScannerPlugin extends Plugin {
  @override
  String get name => 'documentScanner';

  @override
  String get version => '1.0.0';

  @override
  String get description => 'Document scanning with auto-crop';

  @override
  List<String> get requiredPermissions => ['camera'];

  @override
  List<String> get supportedMethods => [
        'scan',
        'getInfo',
      ];

  @override
  Future<dynamic> onCall(String method, Map<String, dynamic> args) async {
    switch (method) {
      case 'scan':
        return _scan(args);
      case 'getInfo':
        return {'name': name, 'version': version};
      default:
        throw UnsupportedError('Method "$method" not supported');
    }
  }

  Future<Map<String, dynamic>> _scan(Map<String, dynamic> args) async {
    final maxPages = (args['maxPages'] as num?)?.toInt() ?? 1;
    final isGalleryImportAllowed = args['allowGallery'] as bool? ?? false;

    try {
      final images = await CunningDocumentScanner.getPictures(
        noOfPages: maxPages,
        isGalleryImportAllowed: isGalleryImportAllowed,
      );

      if (images == null || images.isEmpty) {
        return {'scanned': false, 'reason': 'cancelled', 'pages': <dynamic>[]};
      }

      final pages = <Map<String, dynamic>>[];

      for (int i = 0; i < images.length; i++) {
        final path = images[i];
        final file = File(path);

        if (await file.exists()) {
          final stat = await file.stat();
          pages.add({
            'page': i + 1,
            'path': path,
            'size': stat.size,
          });
        }
      }

      BridgeLogger.info(
        'DocumentScanner',
        'Scanned ${pages.length} pages',
      );

      return {
        'scanned': true,
        'pages': pages,
        'count': pages.length,
      };
    } catch (e) {
      BridgeLogger.error('DocumentScanner', 'Scan failed: $e');
      return {'scanned': false, 'error': e.toString()};
    }
  }
}
```

## 📄 `lib/plugins/document_scanner/pubspec.yaml`

```yaml
name: document_scanner_plugin
description: Document scanner plugin
version: 1.0.0

environment:
  sdk: ^3.0.0

dependencies:
  flutter:
    sdk: flutter
  plugin_engine:
    path: ../../packages/plugin_engine
  core:
    path: ../../packages/core
  cunning_document_scanner: ^1.2.2
```

---

# پلاگین ۳: Google Maps

## 📄 `lib/plugins/google_maps/lib/google_maps_plugin.dart`

```dart
import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;
import 'package:sweetmelon/packages/core/lib/core.dart';
import 'package:sweetmelon/packages/plugin_engine/lib/plugin_engine.dart';

class GoogleMapsPlugin extends Plugin {
  String? _apiKey;

  @override
  String get name => 'googleMaps';

  @override
  String get version => '1.0.0';

  @override
  String get description => 'Google Maps geocoding, directions, and places';

  @override
  List<String> get supportedMethods => [
        'configure',
        'geocode',
        'reverseGeocode',
        'getDirections',
        'searchPlaces',
        'getPlaceDetails',
        'calculateDistance',
        'getStaticMapUrl',
        'getInfo',
      ];

  @override
  Future<dynamic> onCall(String method, Map<String, dynamic> args) async {
    switch (method) {
      case 'configure':
        return _configure(args);
      case 'geocode':
        return _geocode(args);
      case 'reverseGeocode':
        return _reverseGeocode(args);
      case 'getDirections':
        return _getDirections(args);
      case 'searchPlaces':
        return _searchPlaces(args);
      case 'getPlaceDetails':
        return _getPlaceDetails(args);
      case 'calculateDistance':
        return _calculateDistance(args);
      case 'getStaticMapUrl':
        return _getStaticMapUrl(args);
      case 'getInfo':
        return {
          'name': name,
          'version': version,
          'configured': _apiKey != null,
        };
      default:
        throw UnsupportedError('Method "$method" not supported');
    }
  }

  Map<String, dynamic> _configure(Map<String, dynamic> args) {
    _apiKey = args['apiKey'] as String;
    BridgeLogger.info('GoogleMaps', 'Configured with API key');
    return {'configured': true};
  }

  Future<Map<String, dynamic>> _geocode(Map<String, dynamic> args) async {
    _requireApiKey();
    final address = args['address'] as String;

    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/geocode/json'
        '?address=${Uri.encodeComponent(address)}'
        '&key=$_apiKey',
      );

      final response = await http.get(url);
      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (data['status'] == 'OK' && (data['results'] as List).isNotEmpty) {
        final result = (data['results'] as List).first;
        final location = result['geometry']['location'];

        return {
          'found': true,
          'latitude': location['lat'],
          'longitude': location['lng'],
          'formattedAddress': result['formatted_address'],
          'placeId': result['place_id'],
        };
      }

      return {'found': false, 'status': data['status']};
    } catch (e) {
      return {'found': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> _reverseGeocode(
    Map<String, dynamic> args,
  ) async {
    _requireApiKey();
    final lat = (args['latitude'] as num).toDouble();
    final lng = (args['longitude'] as num).toDouble();

    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/geocode/json'
        '?latlng=$lat,$lng'
        '&key=$_apiKey',
      );

      final response = await http.get(url);
      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (data['status'] == 'OK' && (data['results'] as List).isNotEmpty) {
        final result = (data['results'] as List).first;
        return {
          'found': true,
          'formattedAddress': result['formatted_address'],
          'placeId': result['place_id'],
          'components': _parseAddressComponents(
            result['address_components'] as List,
          ),
        };
      }

      return {'found': false, 'status': data['status']};
    } catch (e) {
      return {'found': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> _getDirections(
    Map<String, dynamic> args,
  ) async {
    _requireApiKey();
    final origin = args['origin'] as String;
    final destination = args['destination'] as String;
    final mode = args['mode'] as String? ?? 'driving';

    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/directions/json'
        '?origin=${Uri.encodeComponent(origin)}'
        '&destination=${Uri.encodeComponent(destination)}'
        '&mode=$mode'
        '&key=$_apiKey',
      );

      final response = await http.get(url);
      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (data['status'] == 'OK') {
        final route = (data['routes'] as List).first;
        final leg = (route['legs'] as List).first;

        return {
          'found': true,
          'distance': leg['distance'],
          'duration': leg['duration'],
          'startAddress': leg['start_address'],
          'endAddress': leg['end_address'],
          'polyline': route['overview_polyline']?['points'],
          'steps': (leg['steps'] as List).map((s) => {
                'instruction': s['html_instructions'],
                'distance': s['distance'],
                'duration': s['duration'],
                'travelMode': s['travel_mode'],
              }).toList(),
        };
      }

      return {'found': false, 'status': data['status']};
    } catch (e) {
      return {'found': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> _searchPlaces(
    Map<String, dynamic> args,
  ) async {
    _requireApiKey();
    final query = args['query'] as String;
    final lat = (args['latitude'] as num?)?.toDouble();
    final lng = (args['longitude'] as num?)?.toDouble();
    final radius = (args['radius'] as num?)?.toInt() ?? 5000;

    try {
      var url = 'https://maps.googleapis.com/maps/api/place/textsearch/json'
          '?query=${Uri.encodeComponent(query)}'
          '&key=$_apiKey';

      if (lat != null && lng != null) {
        url += '&location=$lat,$lng&radius=$radius';
      }

      final response = await http.get(Uri.parse(url));
      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (data['status'] == 'OK') {
        final places = (data['results'] as List).map((p) => {
              'name': p['name'],
              'address': p['formatted_address'],
              'placeId': p['place_id'],
              'latitude': p['geometry']?['location']?['lat'],
              'longitude': p['geometry']?['location']?['lng'],
              'rating': p['rating'],
              'totalRatings': p['user_ratings_total'],
              'types': p['types'],
              'openNow': p['opening_hours']?['open_now'],
            }).toList();

        return {'found': true, 'places': places, 'count': places.length};
      }

      return {'found': false, 'status': data['status']};
    } catch (e) {
      return {'found': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> _getPlaceDetails(
    Map<String, dynamic> args,
  ) async {
    _requireApiKey();
    final placeId = args['placeId'] as String;

    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/details/json'
        '?place_id=$placeId'
        '&key=$_apiKey',
      );

      final response = await http.get(url);
      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (data['status'] == 'OK') {
        final result = data['result'] as Map<String, dynamic>;
        return {
          'found': true,
          'name': result['name'],
          'address': result['formatted_address'],
          'phone': result['formatted_phone_number'],
          'website': result['website'],
          'rating': result['rating'],
          'totalRatings': result['user_ratings_total'],
          'latitude': result['geometry']?['location']?['lat'],
          'longitude': result['geometry']?['location']?['lng'],
          'types': result['types'],
          'openingHours': result['opening_hours']?['weekday_text'],
        };
      }

      return {'found': false, 'status': data['status']};
    } catch (e) {
      return {'found': false, 'error': e.toString()};
    }
  }

  Map<String, dynamic> _calculateDistance(Map<String, dynamic> args) {
    final lat1 = (args['lat1'] as num).toDouble();
    final lng1 = (args['lng1'] as num).toDouble();
    final lat2 = (args['lat2'] as num).toDouble();
    final lng2 = (args['lng2'] as num).toDouble();

    const earthRadius = 6371000.0; // meters
    final dLat = _toRadians(lat2 - lat1);
    final dLng = _toRadians(lng2 - lng1);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) * cos(_toRadians(lat2)) *
            sin(dLng / 2) * sin(dLng / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    final distance = earthRadius * c;

    return {
      'distanceMeters': distance.round(),
      'distanceKm': (distance / 1000).toStringAsFixed(2),
      'distanceMiles': (distance / 1609.344).toStringAsFixed(2),
    };
  }

  Map<String, dynamic> _getStaticMapUrl(Map<String, dynamic> args) {
    _requireApiKey();
    final lat = (args['latitude'] as num).toDouble();
    final lng = (args['longitude'] as num).toDouble();
    final zoom = (args['zoom'] as num?)?.toInt() ?? 14;
    final width = (args['width'] as num?)?.toInt() ?? 600;
    final height = (args['height'] as num?)?.toInt() ?? 400;
    final mapType = args['mapType'] as String? ?? 'roadmap';

    final url = 'https://maps.googleapis.com/maps/api/staticmap'
        '?center=$lat,$lng'
        '&zoom=$zoom'
        '&size=${width}x$height'
        '&maptype=$mapType'
        '&markers=color:red|$lat,$lng'
        '&key=$_apiKey';

    return {'url': url};
  }

  double _toRadians(double degrees) => degrees * pi / 180;

  Map<String, String?> _parseAddressComponents(List components) {
    final result = <String, String?>{};
    for (final comp in components) {
      final types = comp['types'] as List;
      if (types.contains('country')) {
        result['country'] = comp['long_name'];
        result['countryCode'] = comp['short_name'];
      }
      if (types.contains('administrative_area_level_1')) {
        result['state'] = comp['long_name'];
      }
      if (types.contains('locality')) {
        result['city'] = comp['long_name'];
      }
      if (types.contains('postal_code')) {
        result['postalCode'] = comp['long_name'];
      }
      if (types.contains('route')) {
        result['street'] = comp['long_name'];
      }
    }
    return result;
  }

  void _requireApiKey() {
    if (_apiKey == null || _apiKey!.isEmpty) {
      throw const PluginException(
        code: PluginErrorCode.invalidArgs,
        message: 'Google Maps API key not configured. Call configure() first.',
      );
    }
  }

  @override
  Future<ValidationResult> validateArgs(
    String method,
    Map<String, dynamic> args,
  ) async {
    switch (method) {
      case 'configure':
        if (args['apiKey'] is! String) {
          return ValidationResult.invalid('apiKey is required');
        }
        return ValidationResult.valid();
      case 'geocode':
        if (args['address'] is! String) {
          return ValidationResult.invalid('address is required');
        }
        return ValidationResult.valid();
      case 'reverseGeocode':
        if (args['latitude'] is! num || args['longitude'] is! num) {
          return ValidationResult.invalid('latitude and longitude required');
        }
        return ValidationResult.valid();
      case 'getDirections':
        if (args['origin'] is! String || args['destination'] is! String) {
          return ValidationResult.invalid('origin and destination required');
        }
        return ValidationResult.valid();
      case 'searchPlaces':
        if (args['query'] is! String) {
          return ValidationResult.invalid('query is required');
        }
        return ValidationResult.valid();
      case 'getPlaceDetails':
        if (args['placeId'] is! String) {
          return ValidationResult.invalid('placeId is required');
        }
        return ValidationResult.valid();
      case 'calculateDistance':
        for (final f in ['lat1', 'lng1', 'lat2', 'lng2']) {
          if (args[f] is! num) {
            return ValidationResult.invalid('$f is required');
          }
        }
        return ValidationResult.valid();
      default:
        return ValidationResult.valid();
    }
  }
}
```

## 📄 `lib/plugins/google_maps/pubspec.yaml`

```yaml
name: google_maps_plugin
description: Google Maps geocoding and places plugin
version: 1.0.0

environment:
  sdk: ^3.0.0

dependencies:
  flutter:
    sdk: flutter
  plugin_engine:
    path: ../../packages/plugin_engine
  core:
    path: ../../packages/core
  http: ^1.1.2
```

---

# پلاگین ۴: Social Login

## 📄 `lib/plugins/social_login/lib/social_login_plugin.dart`

```dart
import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sweetmelon/packages/core/lib/core.dart';
import 'package:sweetmelon/packages/plugin_engine/lib/plugin_engine.dart';

typedef SocialLoginEventEmitter = Future<void> Function(
  String event,
  dynamic data,
);

class SocialLoginPlugin extends Plugin {
  final SocialLoginEventEmitter? eventEmitter;

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  SocialLoginPlugin({this.eventEmitter});

  @override
  String get name => 'socialLogin';

  @override
  String get version => '1.0.0';

  @override
  String get description => 'Social login (Google, phone, anonymous)';

  @override
  List<String> get supportedMethods => [
        'signInWithGoogle',
        'signInWithPhone',
        'verifyPhoneCode',
        'signInAnonymously',
        'linkWithGoogle',
        'linkWithPhone',
        'signOut',
        'getCurrentUser',
        'isSignedIn',
        'getProviders',
        'getInfo',
      ];

  @override
  Future<dynamic> onCall(String method, Map<String, dynamic> args) async {
    switch (method) {
      case 'signInWithGoogle':
        return _signInWithGoogle();
      case 'signInWithPhone':
        return _signInWithPhone(args);
      case 'verifyPhoneCode':
        return _verifyPhoneCode(args);
      case 'signInAnonymously':
        return _signInAnonymously();
      case 'linkWithGoogle':
        return _linkWithGoogle();
      case 'linkWithPhone':
        return _linkWithPhone(args);
      case 'signOut':
        return _signOut();
      case 'getCurrentUser':
        return _getCurrentUser();
      case 'isSignedIn':
        return {'signedIn': FirebaseAuth.instance.currentUser != null};
      case 'getProviders':
        return _getProviders();
      case 'getInfo':
        return {'name': name, 'version': version};
      default:
        throw UnsupportedError('Method "$method" not supported');
    }
  }

  Future<Map<String, dynamic>> _signInWithGoogle() async {
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) {
        return {'success': false, 'reason': 'cancelled'};
      }

      final auth = await account.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: auth.accessToken,
        idToken: auth.idToken,
      );

      final result = await FirebaseAuth.instance
          .signInWithCredential(credential);

      final user = _userToMap(result.user);

      eventEmitter?.call('socialLogin.signedIn', {
        'provider': 'google',
        'user': user,
      });

      return {
        'success': true,
        'provider': 'google',
        'user': user,
        'isNewUser': result.additionalUserInfo?.isNewUser ?? false,
        'googleUser': {
          'email': account.email,
          'displayName': account.displayName,
          'photoUrl': account.photoUrl,
        },
      };
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  String? _verificationId;

  Future<Map<String, dynamic>> _signInWithPhone(
    Map<String, dynamic> args,
  ) async {
    final phoneNumber = args['phoneNumber'] as String;
    final completer = Completer<Map<String, dynamic>>();

    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (credential) async {
          final result = await FirebaseAuth.instance
              .signInWithCredential(credential);

          if (!completer.isCompleted) {
            completer.complete({
              'success': true,
              'provider': 'phone',
              'autoVerified': true,
              'user': _userToMap(result.user),
            });
          }
        },
        verificationFailed: (e) {
          if (!completer.isCompleted) {
            completer.complete({
              'success': false,
              'errorCode': e.code,
              'errorMessage': e.message,
            });
          }
        },
        codeSent: (verificationId, resendToken) {
          _verificationId = verificationId;
          if (!completer.isCompleted) {
            completer.complete({
              'success': true,
              'codeSent': true,
              'verificationId': verificationId,
              'message': 'SMS code sent to $phoneNumber',
            });
          }
        },
        codeAutoRetrievalTimeout: (verificationId) {
          _verificationId = verificationId;
        },
      );
    } catch (e) {
      if (!completer.isCompleted) {
        completer.complete({
          'success': false,
          'error': e.toString(),
        });
      }
    }

    return completer.future;
  }

  Future<Map<String, dynamic>> _verifyPhoneCode(
    Map<String, dynamic> args,
  ) async {
    final code = args['code'] as String;
    final verificationId = args['verificationId'] as String? ?? _verificationId;

    if (verificationId == null) {
      return {'success': false, 'reason': 'no_verification_id'};
    }

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: code,
      );

      final result = await FirebaseAuth.instance
          .signInWithCredential(credential);

      eventEmitter?.call('socialLogin.signedIn', {
        'provider': 'phone',
        'user': _userToMap(result.user),
      });

      return {
        'success': true,
        'provider': 'phone',
        'user': _userToMap(result.user),
      };
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> _signInAnonymously() async {
    try {
      final result = await FirebaseAuth.instance.signInAnonymously();
      return {
        'success': true,
        'provider': 'anonymous',
        'user': _userToMap(result.user),
      };
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> _linkWithGoogle() async {
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) {
        return {'success': false, 'reason': 'cancelled'};
      }

      final auth = await account.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: auth.accessToken,
        idToken: auth.idToken,
      );

      await FirebaseAuth.instance.currentUser?.linkWithCredential(credential);

      return {'success': true, 'linked': 'google'};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> _linkWithPhone(
    Map<String, dynamic> args,
  ) async {
    return _signInWithPhone(args);
  }

  Future<Map<String, dynamic>> _signOut() async {
    try {
      await _googleSignIn.signOut();
      await FirebaseAuth.instance.signOut();

      eventEmitter?.call('socialLogin.signedOut', {
        'timestamp': DateTime.now().toIso8601String(),
      });

      return {'success': true};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Map<String, dynamic> _getCurrentUser() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return {'user': null, 'signedIn': false};
    return {'user': _userToMap(user), 'signedIn': true};
  }

  Map<String, dynamic> _getProviders() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return {'providers': <dynamic>[]};
    return {
      'providers': user.providerData.map((p) => p.providerId).toList(),
    };
  }

  Map<String, dynamic>? _userToMap(User? user) {
    if (user == null) return null;
    return {
      'uid': user.uid,
      'email': user.email,
      'displayName': user.displayName,
      'photoURL': user.photoURL,
      'phoneNumber': user.phoneNumber,
      'emailVerified': user.emailVerified,
      'isAnonymous': user.isAnonymous,
    };
  }

  @override
  Future<ValidationResult> validateArgs(
    String method,
    Map<String, dynamic> args,
  ) async {
    switch (method) {
      case 'signInWithPhone':
      case 'linkWithPhone':
        if (args['phoneNumber'] is! String) {
          return ValidationResult.invalid('phoneNumber is required');
        }
        return ValidationResult.valid();
      case 'verifyPhoneCode':
        if (args['code'] is! String) {
          return ValidationResult.invalid('code is required');
        }
        return ValidationResult.valid();
      default:
        return ValidationResult.valid();
    }
  }
}
```

## 📄 `lib/plugins/social_login/pubspec.yaml`

```yaml
name: social_login_plugin
description: Social login plugin (Google, Phone)
version: 1.0.0

environment:
  sdk: ^3.0.0

dependencies:
  flutter:
    sdk: flutter
  plugin_engine:
    path: ../../packages/plugin_engine
  core:
    path: ../../packages/core
  firebase_auth: ^5.3.1
  google_sign_in: ^6.2.1
```

---

# پلاگین ۵: In-App Purchase

## 📄 `lib/plugins/in_app_purchase/lib/in_app_purchase_plugin.dart`

```dart
import 'dart:async';

import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:sweetmelon/packages/core/lib/core.dart';
import 'package:sweetmelon/packages/plugin_engine/lib/plugin_engine.dart';

typedef PurchaseEventEmitter = Future<void> Function(String event, dynamic data);

class InAppPurchasePlugin extends Plugin {
  final PurchaseEventEmitter? eventEmitter;

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _purchaseSub;
  bool _available = false;

  InAppPurchasePlugin({this.eventEmitter});

  @override
  String get name => 'inAppPurchase';

  @override
  String get version => '1.0.0';

  @override
  String get description => 'In-app purchase and subscription plugin';

  @override
  List<String> get supportedMethods => [
        'isAvailable',
        'getProducts',
        'buyProduct',
        'buySubscription',
        'restorePurchases',
        'completePurchase',
        'getPurchaseHistory',
        'getInfo',
      ];

  @override
  Future<void> onInitialize() async {
    _available = await _iap.isAvailable();

    _purchaseSub = _iap.purchaseStream.listen(
      _handlePurchaseUpdate,
      onError: (error) {
        BridgeLogger.error('InAppPurchase', 'Stream error: $error');
        eventEmitter?.call('purchase.error', {
          'message': error.toString(),
        });
      },
    );

    BridgeLogger.info('InAppPurchase', 'Available: $_available');
  }

  @override
  Future<void> onDispose() async {
    await _purchaseSub?.cancel();
  }

  void _handlePurchaseUpdate(List<PurchaseDetails> purchases) {
    for (final purchase in purchases) {
      final data = _purchaseToMap(purchase);

      switch (purchase.status) {
        case PurchaseStatus.pending:
          eventEmitter?.call('purchase.pending', data);
          break;
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          eventEmitter?.call('purchase.completed', data);
          // Auto-complete
          if (purchase.pendingCompletePurchase) {
            _iap.completePurchase(purchase);
          }
          break;
        case PurchaseStatus.error:
          eventEmitter?.call('purchase.error', {
            ...data,
            'errorMessage': purchase.error?.message,
            'errorCode': purchase.error?.code,
          });
          break;
        case PurchaseStatus.canceled:
          eventEmitter?.call('purchase.cancelled', data);
          break;
      }
    }
  }

  @override
  Future<dynamic> onCall(String method, Map<String, dynamic> args) async {
    switch (method) {
      case 'isAvailable':
        return {'available': _available};
      case 'getProducts':
        return _getProducts(args);
      case 'buyProduct':
        return _buyProduct(args);
      case 'buySubscription':
        return _buySubscription(args);
      case 'restorePurchases':
        return _restorePurchases();
      case 'completePurchase':
        return _completePurchase(args);
      case 'getPurchaseHistory':
        return {'note': 'Use purchase events for history'};
      case 'getInfo':
        return {
          'name': name,
          'version': version,
          'available': _available,
        };
      default:
        throw UnsupportedError('Method "$method" not supported');
    }
  }

  Future<Map<String, dynamic>> _getProducts(
    Map<String, dynamic> args,
  ) async {
    final ids = Set<String>.from(args['productIds'] as List);

    try {
      final response = await _iap.queryProductDetails(ids);

      if (response.notFoundIDs.isNotEmpty) {
        BridgeLogger.warn(
          'InAppPurchase',
          'Not found: ${response.notFoundIDs.join(", ")}',
        );
      }

      final products = response.productDetails.map((p) => {
            'id': p.id,
            'title': p.title,
            'description': p.description,
            'price': p.price,
            'rawPrice': p.rawPrice,
            'currencyCode': p.currencyCode,
            'currencySymbol': p.currencySymbol,
          }).toList();

      return {
        'products': products,
        'count': products.length,
        'notFound': response.notFoundIDs.toList(),
        'error': response.error?.message,
      };
    } catch (e) {
      return {'products': <dynamic>[], 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> _buyProduct(
    Map<String, dynamic> args,
  ) async {
    final productId = args['productId'] as String;

    try {
      final response = await _iap.queryProductDetails({productId});

      if (response.productDetails.isEmpty) {
        return {'initiated': false, 'reason': 'product_not_found'};
      }

      final product = response.productDetails.first;
      final purchaseParam = PurchaseParam(productDetails: product);

      final initiated = await _iap.buyNonConsumable(
        purchaseParam: purchaseParam,
      );

      return {'initiated': initiated, 'productId': productId};
    } catch (e) {
      return {'initiated': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> _buySubscription(
    Map<String, dynamic> args,
  ) async {
    final productId = args['productId'] as String;

    try {
      final response = await _iap.queryProductDetails({productId});

      if (response.productDetails.isEmpty) {
        return {'initiated': false, 'reason': 'product_not_found'};
      }

      final product = response.productDetails.first;
      final purchaseParam = PurchaseParam(productDetails: product);

      final initiated = await _iap.buyNonConsumable(
        purchaseParam: purchaseParam,
      );

      return {'initiated': initiated, 'productId': productId};
    } catch (e) {
      return {'initiated': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> _restorePurchases() async {
    try {
      await _iap.restorePurchases();
      return {'restoring': true};
    } catch (e) {
      return {'restoring': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> _completePurchase(
    Map<String, dynamic> args,
  ) async {
    return {'completed': true, 'note': 'Auto-completed via stream'};
  }

  Map<String, dynamic> _purchaseToMap(PurchaseDetails purchase) {
    return {
      'productId': purchase.productID,
      'purchaseId': purchase.purchaseID,
      'status': purchase.status.name,
      'transactionDate': purchase.transactionDate,
      'pendingComplete': purchase.pendingCompletePurchase,
    };
  }

  @override
  Future<ValidationResult> validateArgs(
    String method,
    Map<String, dynamic> args,
  ) async {
    switch (method) {
      case 'getProducts':
        final ids = args['productIds'];
        if (ids is! List || ids.isEmpty) {
          return ValidationResult.invalid('productIds (list) is required');
        }
        return ValidationResult.valid();
      case 'buyProduct':
      case 'buySubscription':
        if (args['productId'] is! String) {
          return ValidationResult.invalid('productId is required');
        }
        return ValidationResult.valid();
      default:
        return ValidationResult.valid();
    }
  }
}
```

## 📄 `lib/plugins/in_app_purchase/pubspec.yaml`

```yaml
name: in_app_purchase_plugin
description: In-app purchase plugin
version: 1.0.0

environment:
  sdk: ^3.0.0

dependencies:
  flutter:
    sdk: flutter
  plugin_engine:
    path: ../../packages/plugin_engine
  core:
    path: ../../packages/core
  in_app_purchase: ^3.2.0
```

---

# پلاگین ۶: OAuth2

## 📄 `lib/plugins/oauth2/lib/oauth2_plugin.dart`

```dart
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:http/http.dart' as http;
import 'package:sweetmelon/packages/core/lib/core.dart';
import 'package:sweetmelon/packages/plugin_engine/lib/plugin_engine.dart';

class OAuth2Plugin extends Plugin {
  @override
  String get name => 'oauth2';

  @override
  String get version => '1.0.0';

  @override
  String get description => 'Generic OAuth2 authentication plugin';

  @override
  List<String> get supportedMethods => [
        'authorize',
        'exchangeCode',
        'refreshToken',
        'getInfo',
      ];

  @override
  Future<dynamic> onCall(String method, Map<String, dynamic> args) async {
    switch (method) {
      case 'authorize':
        return _authorize(args);
      case 'exchangeCode':
        return _exchangeCode(args);
      case 'refreshToken':
        return _refreshToken(args);
      case 'getInfo':
        return {'name': name, 'version': version};
      default:
        throw UnsupportedError('Method "$method" not supported');
    }
  }

  Future<Map<String, dynamic>> _authorize(Map<String, dynamic> args) async {
    final authUrl = args['authUrl'] as String;
    final clientId = args['clientId'] as String;
    final redirectUri = args['redirectUri'] as String;
    final scope = args['scope'] as String? ?? '';
    final responseType = args['responseType'] as String? ?? 'code';
    final state = args['state'] as String?;
    final extraParams = args['extraParams'] as Map<String, dynamic>? ?? {};

    final params = {
      'client_id': clientId,
      'redirect_uri': redirectUri,
      'response_type': responseType,
      if (scope.isNotEmpty) 'scope': scope,
      if (state != null) 'state': state,
      ...extraParams.map((k, v) => MapEntry(k, v.toString())),
    };

    final queryString = params.entries
        .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');

    final fullUrl = '$authUrl?$queryString';

    BridgeLogger.info('OAuth2', 'Starting authorization: $authUrl');

    final context = AppContext().context;
    if (context == null) {
      return {'success': false, 'reason': 'no_context'};
    }

    final completer = Completer<Map<String, dynamic>>();

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _OAuth2WebViewPage(
          url: fullUrl,
          redirectUri: redirectUri,
          onResult: (result) {
            if (!completer.isCompleted) {
              completer.complete(result);
            }
          },
        ),
      ),
    );

    return completer.future;
  }

  Future<Map<String, dynamic>> _exchangeCode(
    Map<String, dynamic> args,
  ) async {
    final tokenUrl = args['tokenUrl'] as String;
    final code = args['code'] as String;
    final clientId = args['clientId'] as String;
    final clientSecret = args['clientSecret'] as String?;
    final redirectUri = args['redirectUri'] as String;
    final codeVerifier = args['codeVerifier'] as String?;

    try {
      final body = {
        'grant_type': 'authorization_code',
        'code': code,
        'client_id': clientId,
        'redirect_uri': redirectUri,
        if (clientSecret != null) 'client_secret': clientSecret,
        if (codeVerifier != null) 'code_verifier': codeVerifier,
      };

      final response = await http.post(
        Uri.parse(tokenUrl),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: body,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return {
          'success': true,
          'accessToken': data['access_token'],
          'refreshToken': data['refresh_token'],
          'expiresIn': data['expires_in'],
          'tokenType': data['token_type'],
          'scope': data['scope'],
          'idToken': data['id_token'],
        };
      }

      return {
        'success': false,
        'statusCode': response.statusCode,
        'error': response.body,
      };
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> _refreshToken(
    Map<String, dynamic> args,
  ) async {
    final tokenUrl = args['tokenUrl'] as String;
    final refreshToken = args['refreshToken'] as String;
    final clientId = args['clientId'] as String;
    final clientSecret = args['clientSecret'] as String?;

    try {
      final body = {
        'grant_type': 'refresh_token',
        'refresh_token': refreshToken,
        'client_id': clientId,
        if (clientSecret != null) 'client_secret': clientSecret,
      };

      final response = await http.post(
        Uri.parse(tokenUrl),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: body,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return {
          'success': true,
          'accessToken': data['access_token'],
          'refreshToken': data['refresh_token'] ?? refreshToken,
          'expiresIn': data['expires_in'],
        };
      }

      return {
        'success': false,
        'statusCode': response.statusCode,
        'error': response.body,
      };
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  @override
  Future<ValidationResult> validateArgs(
    String method,
    Map<String, dynamic> args,
  ) async {
    switch (method) {
      case 'authorize':
        for (final f in ['authUrl', 'clientId', 'redirectUri']) {
          if (args[f] is! String || (args[f] as String).isEmpty) {
            return ValidationResult.invalid('$f is required');
          }
        }
        return ValidationResult.valid();
      case 'exchangeCode':
        for (final f in ['tokenUrl', 'code', 'clientId', 'redirectUri']) {
          if (args[f] is! String) {
            return ValidationResult.invalid('$f is required');
          }
        }
        return ValidationResult.valid();
      case 'refreshToken':
        for (final f in ['tokenUrl', 'refreshToken', 'clientId']) {
          if (args[f] is! String) {
            return ValidationResult.invalid('$f is required');
          }
        }
        return ValidationResult.valid();
      default:
        return ValidationResult.valid();
    }
  }
}

class _OAuth2WebViewPage extends StatelessWidget {
  final String url;
  final String redirectUri;
  final void Function(Map<String, dynamic>) onResult;

  const _OAuth2WebViewPage({
    required this.url,
    required this.redirectUri,
    required this.onResult,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF121A2D),
        title: const Text('Sign In', style: TextStyle(fontSize: 14)),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            onResult({'success': false, 'reason': 'cancelled'});
            Navigator.of(context).pop();
          },
        ),
      ),
      body: InAppWebView(
        initialUrlRequest: URLRequest(url: WebUri(url)),
        initialSettings: InAppWebViewSettings(
          javaScriptEnabled: true,
          clearCache: true,
        ),
        onLoadStop: (controller, loadedUrl) {
          if (loadedUrl != null &&
              loadedUrl.toString().startsWith(redirectUri)) {
            final uri = Uri.parse(loadedUrl.toString());
            final code = uri.queryParameters['code'];
            final state = uri.queryParameters['state'];
            final error = uri.queryParameters['error'];

            if (error != null) {
              onResult({
                'success': false,
                'error': error,
                'errorDescription': uri.queryParameters['error_description'],
              });
            } else if (code != null) {
              onResult({
                'success': true,
                'code': code,
                'state': state,
                'redirectUrl': loadedUrl.toString(),
              });
            } else {
              // fragment response (implicit flow)
              final fragment = uri.fragment;
              final fragmentParams = Uri.splitQueryString(fragment);

              onResult({
                'success': fragmentParams.containsKey('access_token'),
                'accessToken': fragmentParams['access_token'],
                'tokenType': fragmentParams['token_type'],
                'expiresIn': fragmentParams['expires_in'],
                'state': fragmentParams['state'],
              });
            }

            Navigator.of(context).pop();
          }
        },
      ),
    );
  }
}
```

## 📄 `lib/plugins/oauth2/pubspec.yaml`

```yaml
name: oauth2_plugin
description: Generic OAuth2 authentication plugin
version: 1.0.0

environment:
  sdk: ^3.0.0

dependencies:
  flutter:
    sdk: flutter
  plugin_engine:
    path: ../../packages/plugin_engine
  core:
    path: ../../packages/core
  flutter_inappwebview: ^6.1.5
  http: ^1.1.2
```

---

# بروزرسانی pubspec.yaml اصلی

```yaml
  # فاز ۱۷
  camera: ^0.11.0+2
  cunning_document_scanner: ^1.2.2
  in_app_purchase: ^3.2.0
```

---

# NativeSDK — فاز ۱۷

```javascript
    cameraPreview: {
      start: function (o) { return call('cameraPreview', 'start', o || {}); },
      stop: function () { return call('cameraPreview', 'stop', {}); },
      takePhoto: function (o) { return call('cameraPreview', 'takePhoto', o || {}); },
      startRecording: function (o) { return call('cameraPreview', 'startRecording', o || {}); },
      stopRecording: function () { return call('cameraPreview', 'stopRecording', {}); },
      switchCamera: function () { return call('cameraPreview', 'switchCamera', {}); },
      setFlashMode: function (mode) { return call('cameraPreview', 'setFlashMode', { mode: mode }); },
      setZoomLevel: function (zoom) { return call('cameraPreview', 'setZoomLevel', { zoom: zoom }); },
      getMinZoomLevel: function () { return call('cameraPreview', 'getMinZoomLevel', {}); },
      getMaxZoomLevel: function () { return call('cameraPreview', 'getMaxZoomLevel', {}); },
      setFocusPoint: function (x, y) { return call('cameraPreview', 'setFocusPoint', { x: x, y: y }); },
      getAvailableCameras: function () { return call('cameraPreview', 'getAvailableCameras', {}); },
      getState: function () { return call('cameraPreview', 'getState', {}); },
      getInfo: function () { return call('cameraPreview', 'getInfo', {}); }
    },

    documentScanner: {
      scan: function (o) { return call('documentScanner', 'scan', o || {}, { timeout: 120000 }); },
      getInfo: function () { return call('documentScanner', 'getInfo', {}); }
    },

    googleMaps: {
      configure: function (apiKey) { return call('googleMaps', 'configure', { apiKey: apiKey }); },
      geocode: function (address) { return call('googleMaps', 'geocode', { address: address }); },
      reverseGeocode: function (lat, lng) { return call('googleMaps', 'reverseGeocode', { latitude: lat, longitude: lng }); },
      getDirections: function (origin, destination, mode) { return call('googleMaps', 'getDirections', { origin: origin, destination: destination, mode: mode || 'driving' }); },
      searchPlaces: function (query, o) { return call('googleMaps', 'searchPlaces', Object.assign({ query: query }, o || {})); },
      getPlaceDetails: function (placeId) { return call('googleMaps', 'getPlaceDetails', { placeId: placeId }); },
      calculateDistance: function (lat1, lng1, lat2, lng2) { return call('googleMaps', 'calculateDistance', { lat1: lat1, lng1: lng1, lat2: lat2, lng2: lng2 }); },
      getStaticMapUrl: function (lat, lng, o) { return call('googleMaps', 'getStaticMapUrl', Object.assign({ latitude: lat, longitude: lng }, o || {})); },
      getInfo: function () { return call('googleMaps', 'getInfo', {}); }
    },

    socialLogin: {
      signInWithGoogle: function () { return call('socialLogin', 'signInWithGoogle', {}, { timeout: 60000 }); },
      signInWithPhone: function (phoneNumber) { return call('socialLogin', 'signInWithPhone', { phoneNumber: phoneNumber }, { timeout: 120000 }); },
      verifyPhoneCode: function (code, verificationId) { return call('socialLogin', 'verifyPhoneCode', { code: code, verificationId: verificationId }); },
      signInAnonymously: function () { return call('socialLogin', 'signInAnonymously', {}); },
      linkWithGoogle: function () { return call('socialLogin', 'linkWithGoogle', {}, { timeout: 60000 }); },
      signOut: function () { return call('socialLogin', 'signOut', {}); },
      getCurrentUser: function () { return call('socialLogin', 'getCurrentUser', {}); },
      isSignedIn: function () { return call('socialLogin', 'isSignedIn', {}); },
      getProviders: function () { return call('socialLogin', 'getProviders', {}); },
      getInfo: function () { return call('socialLogin', 'getInfo', {}); }
    },

    inAppPurchase: {
      isAvailable: function () { return call('inAppPurchase', 'isAvailable', {}); },
      getProducts: function (productIds) { return call('inAppPurchase', 'getProducts', { productIds: productIds }); },
      buyProduct: function (productId) { return call('inAppPurchase', 'buyProduct', { productId: productId }, { timeout: 120000 }); },
      buySubscription: function (productId) { return call('inAppPurchase', 'buySubscription', { productId: productId }, { timeout: 120000 }); },
      restorePurchases: function () { return call('inAppPurchase', 'restorePurchases', {}); },
      getInfo: function () { return call('inAppPurchase', 'getInfo', {}); }
    },

    oauth2: {
      authorize: function (o) { return call('oauth2', 'authorize', o, { timeout: 120000 }); },
      exchangeCode: function (o) { return call('oauth2', 'exchangeCode', o); },
      refreshToken: function (o) { return call('oauth2', 'refreshToken', o); },
      getInfo: function () { return call('oauth2', 'getInfo', {}); }
    },
```

---

# خلاصه فاز ۱۷

## پلاگین‌های جدید

| # | پلاگین | نام JS | قابلیت کلیدی |
|---|--------|--------|-------------|
| 85 | Camera Preview | `cameraPreview` | start, stop, takePhoto, recording, switchCamera, zoom, flash, focus |
| 86 | Document Scanner | `documentScanner` | scan multi-page documents with auto-crop |
| 87 | Google Maps | `googleMaps` | geocode, reverseGeocode, directions, places, distance |
| 88 | Social Login | `socialLogin` | Google, Phone (SMS), Anonymous, link accounts |
| 89 | In-App Purchase | `inAppPurchase` | getProducts, buy, subscribe, restore |
| 90 | OAuth2 | `oauth2` | authorize, exchangeCode, refreshToken |

## Events جدید

| Event | پلاگین |
|-------|--------|
| `cameraPreview.started` | cameraPreview |
| `cameraPreview.stopped` | cameraPreview |
| `cameraPreview.photoTaken` | cameraPreview |
| `cameraPreview.recordingStarted` | cameraPreview |
| `cameraPreview.recordingStopped` | cameraPreview |
| `socialLogin.signedIn` | socialLogin |
| `socialLogin.signedOut` | socialLogin |
| `purchase.pending` | inAppPurchase |
| `purchase.completed` | inAppPurchase |
| `purchase.cancelled` | inAppPurchase |
| `purchase.error` | inAppPurchase |

## **مجموع کل: 90 پلاگین** 🎉

## نحوه استفاده JS

```javascript
// Camera Preview
await NativeSDK.cameraPreview.start({
  cameraIndex: 0,
  resolution: 'high',
  enableAudio: true
});
const photo = await NativeSDK.cameraPreview.takePhoto();
await NativeSDK.cameraPreview.switchCamera();
await NativeSDK.cameraPreview.setFlashMode('torch');
await NativeSDK.cameraPreview.setZoomLevel(2.5);
await NativeSDK.cameraPreview.stop();

// Document Scanner
const { pages } = await NativeSDK.documentScanner.scan({
  maxPages: 3,
  allowGallery: true
});
// pages[0].path → scanned image

// Google Maps
await NativeSDK.googleMaps.configure('YOUR_API_KEY');

const { latitude, longitude } = await NativeSDK.googleMaps.geocode('Tehran, Iran');
const { formattedAddress } = await NativeSDK.googleMaps.reverseGeocode(35.6892, 51.3890);
const directions = await NativeSDK.googleMaps.getDirections('Tehran', 'Isfahan', 'driving');
const { places } = await NativeSDK.googleMaps.searchPlaces('restaurant', {
  latitude: 35.6892,
  longitude: 51.3890,
  radius: 1000
});
const dist = NativeSDK.googleMaps.calculateDistance(35.69, 51.39, 32.65, 51.67);

// Social Login
const { user } = await NativeSDK.socialLogin.signInWithGoogle();
console.log('Welcome', user.displayName);

// Phone auth
const result = await NativeSDK.socialLogin.signInWithPhone('+989123456789');
if (result.codeSent) {
  const code = prompt('Enter SMS code');
  await NativeSDK.socialLogin.verifyPhoneCode(code, result.verificationId);
}

await NativeSDK.socialLogin.signOut();

// In-App Purchase
const { products } = await NativeSDK.inAppPurchase.getProducts([
  'premium_monthly',
  'premium_yearly',
  'remove_ads'
]);

NativeSDK.on('purchase.completed', (data) => {
  // verify on backend
  verifyPurchase(data.productId, data.purchaseId);
});

await NativeSDK.inAppPurchase.buySubscription('premium_monthly');

// OAuth2 (مثلا GitHub)
const auth = await NativeSDK.oauth2.authorize({
  authUrl: 'https://github.com/login/oauth/authorize',
  clientId: 'YOUR_CLIENT_ID',
  redirectUri: 'sweetmelon://oauth/callback',
  scope: 'user repo'
});

if (auth.success && auth.code) {
  const tokens = await NativeSDK.oauth2.exchangeCode({
    tokenUrl: 'https://github.com/login/oauth/access_token',
    code: auth.code,
    clientId: 'YOUR_CLIENT_ID',
    clientSecret: 'YOUR_SECRET',
    redirectUri: 'sweetmelon://oauth/callback'
  });
  
  // tokens.accessToken → use for API calls
}
```

---

## آمار نهایی تا اینجا

| آیتم | تعداد |
|------|-------|
| **پلاگین‌ها** | 90 |
| **Events** | 70+ |
| **JS API Methods** | 600+ |
| **Test files** | 40+ |
| **Total tests** | 280+ |
| **Framework SDKs** | 4 |
| **Security layers** | 5 |
| **فازهای تکمیل‌شده** | 17 |

---

بگو تا **فاز ۱۸** (DevTools & DX) رو شروع کنم.
