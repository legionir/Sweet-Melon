import 'dart:async';
import 'package:geolocator/geolocator.dart';
import '../../../packages/plugin_engine/lib/src/plugin_interface.dart';

// ============================================================
// GEOLOCATION PLUGIN
// ============================================================

class GeolocationPlugin extends Plugin {
  StreamSubscription<Position>? _positionStream;

  @override
  String get name => 'geolocation';

  @override
  String get version => '1.0.0';

  @override
  List<String> get supportedMethods => [
        'getCurrentPosition',
        'watchPosition',
        'clearWatch',
        'checkPermission',
        'requestPermission',
        'isLocationEnabled',
      ];

  @override
  List<String> get requiredPermissions => ['location'];

  @override
  Future<dynamic> onCall(String method, Map<String, dynamic> args) async {
    switch (method) {
      case 'getCurrentPosition':
        return _getCurrentPosition(args);
      case 'watchPosition':
        return _watchPosition(args);
      case 'clearWatch':
        return _clearWatch();
      case 'checkPermission':
        return _checkPermission();
      case 'requestPermission':
        return _requestPermission();
      case 'isLocationEnabled':
        return _isLocationEnabled();
      default:
        throw UnsupportedError('Method "$method" not supported');
    }
  }

  Future<Map<String, dynamic>> _getCurrentPosition(
    Map<String, dynamic> args,
  ) async {
    final accuracy = _parseAccuracy(
      args['accuracy'] as String? ?? 'high',
    );
    
    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: accuracy,
    );
    
    return _positionToMap(position);
  }

  Future<String> _watchPosition(Map<String, dynamic> args) async {
    final accuracy = _parseAccuracy(
      args['accuracy'] as String? ?? 'high',
    );
    final distanceFilter = (args['distanceFilter'] as num?)?.toDouble() ?? 10;

    await _clearWatch();

    final settings = LocationSettings(
      accuracy: accuracy,
      distanceFilter: distanceFilter.toInt(),
    );

    _positionStream = Geolocator.getPositionStream(
      locationSettings: settings,
    ).listen((position) {
      // رویداد به JS ارسال می‌شود
      // (از طریق bridge event system)
    });

    return 'watch_started';
  }

  Future<void> _clearWatch() async {
    await _positionStream?.cancel();
    _positionStream = null;
  }

  Future<String> _checkPermission() async {
    final permission = await Geolocator.checkPermission();
    return permission.name;
  }

  Future<String> _requestPermission() async {
    final permission = await Geolocator.requestPermission();
    return permission.name;
  }

  Future<bool> _isLocationEnabled() async {
    return Geolocator.isLocationServiceEnabled();
  }

  LocationAccuracy _parseAccuracy(String accuracy) {
    switch (accuracy) {
      case 'low':
        return LocationAccuracy.low;
      case 'medium':
        return LocationAccuracy.medium;
      case 'high':
        return LocationAccuracy.high;
      case 'best':
        return LocationAccuracy.best;
      default:
        return LocationAccuracy.high;
    }
  }

  Map<String, dynamic> _positionToMap(Position position) {
    return {
      'latitude': position.latitude,
      'longitude': position.longitude,
      'altitude': position.altitude,
      'accuracy': position.accuracy,
      'heading': position.heading,
      'speed': position.speed,
      'timestamp': position.timestamp?.toIso8601String(),
    };
  }

  @override
  Future<void> onDispose() async {
    await _clearWatch();
  }
}
