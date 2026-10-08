import 'dart:async';

import 'package:geolocator/geolocator.dart';
import 'package:sweetmelon/packages/core/lib/src/protocol/message_protocol.dart';
import 'package:sweetmelon/packages/plugin_engine/lib/plugin_engine.dart';

// ============================================================
// GEOLOCATION PLUGIN
// ============================================================
//
// * watchPosition starts a named watch and returns its watchId. Every position
//   is delivered to JavaScript as a `geolocation.position` event carrying the
//   watchId (BUG-005, SM-009). Errors arrive as `geolocation.error`.
// * Several watches can run at once, up to [maxWatches]. Each watch is removed
//   when cancelled, when its stream ends, or when the plugin is disposed, so
//   no subscription outlives its owner (SM-011).

typedef PositionStreamFactory = Stream<Position> Function(
  LocationSettings settings,
);

const int kMaxWatches = 4;

const List<String> kAccuracyLevels = [
  'lowest',
  'low',
  'medium',
  'high',
  'best',
  'bestForNavigation',
];

class GeolocationPlugin extends Plugin {
  final PositionStreamFactory _positionStream;
  final Map<int, StreamSubscription<Position>> _watches = {};
  int _nextWatchId = 1;

  GeolocationPlugin({PositionStreamFactory? positionStream})
      : _positionStream = positionStream ??
            ((settings) => Geolocator.getPositionStream(
                  locationSettings: settings,
                ));

  @override
  String get name => 'geolocation';

  @override
  String get version => '1.1.0';

  @override
  String get description => 'Geolocation and GPS plugin';

  @override
  PluginCapabilities get capabilities => const PluginCapabilities(
        supportsStreaming: true,
        supportsBatch: true,
        supportsCache: false,
        maxConcurrentCalls: 4,
      );

  @override
  Set<String> get streamingMethods => const {'watchPosition'};

  @override
  List<String> get supportedMethods => const [
        'getCurrentPosition',
        'watchPosition',
        'clearWatch',
        'checkPermission',
        'requestPermission',
        'isLocationEnabled',
      ];

  @override
  List<String> get requiredPermissions => const ['location'];

  /// Number of active watches (for tests and diagnostics).
  int get activeWatchCount => _watches.length;

  @override
  Future<dynamic> onCall(String method, Map<String, dynamic> args) async {
    switch (method) {
      case 'getCurrentPosition':
        return _getCurrentPosition(args);
      case 'watchPosition':
        return _watchPosition(args);
      case 'clearWatch':
        return _clearWatch(args);
      case 'checkPermission':
        return (await Geolocator.checkPermission()).name;
      case 'requestPermission':
        return (await Geolocator.requestPermission()).name;
      case 'isLocationEnabled':
        return Geolocator.isLocationServiceEnabled();
      default:
        throw const PluginException(
          PluginErrorCode.methodNotFound,
          'Method is not supported',
        );
    }
  }

  Future<Map<String, dynamic>> _getCurrentPosition(
    Map<String, dynamic> args,
  ) async {
    final accuracy = _parseAccuracy(args['accuracy'] as String? ?? 'high');
    final timeoutMs = (args['timeoutMs'] as num?)?.toInt();
    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: accuracy,
      timeLimit: timeoutMs == null ? null : Duration(milliseconds: timeoutMs),
    );
    return positionToMap(position);
  }

  Map<String, dynamic> _watchPosition(Map<String, dynamic> args) {
    if (_watches.length >= kMaxWatches) {
      throw const PluginException(
        PluginErrorCode.rateLimitExceeded,
        'Too many active watches',
      );
    }
    final accuracy = _parseAccuracy(args['accuracy'] as String? ?? 'high');
    final distanceFilter = (args['distanceFilter'] as num?)?.toInt() ?? 10;

    final watchId = _nextWatchId++;
    final timeoutMs = (args['timeoutMs'] as num?)?.toInt();
    final settings = LocationSettings(
      accuracy: accuracy,
      distanceFilter: distanceFilter,
      timeLimit: timeoutMs == null ? null : Duration(milliseconds: timeoutMs),
    );

    final subscription = _positionStream(settings).listen(
      (position) {
        emit('position', {
          'watchId': watchId,
          ...positionToMap(position),
        });
      },
      onError: (Object error) {
        // Raw error text stays out of JS; only a stable code is sent.
        emit('error', {
          'watchId': watchId,
          'code': 'LOCATION_ERROR',
        });
        _removeWatch(watchId);
      },
      onDone: () => _removeWatch(watchId),
      cancelOnError: true,
    );
    _watches[watchId] = subscription;
    return {'watchId': watchId};
  }

  Future<Map<String, dynamic>> _clearWatch(Map<String, dynamic> args) async {
    final watchId = args['watchId'];
    if (watchId == null) {
      final count = _watches.length;
      await _cancelAll();
      return {'cleared': count};
    }
    if (watchId is! int) {
      throw const PluginException(
        PluginErrorCode.invalidArgs,
        'watchId must be an integer',
      );
    }
    final cleared = await _removeWatch(watchId);
    return {'cleared': cleared ? 1 : 0};
  }

  Future<bool> _removeWatch(int watchId) async {
    final subscription = _watches.remove(watchId);
    if (subscription == null) return false;
    await subscription.cancel();
    return true;
  }

  Future<void> _cancelAll() async {
    final subscriptions = _watches.values.toList();
    _watches.clear();
    for (final s in subscriptions) {
      await s.cancel();
    }
  }

  static LocationAccuracy _parseAccuracy(String accuracy) {
    switch (accuracy) {
      case 'lowest':
        return LocationAccuracy.lowest;
      case 'low':
        return LocationAccuracy.low;
      case 'medium':
        return LocationAccuracy.medium;
      case 'best':
        return LocationAccuracy.best;
      case 'bestForNavigation':
        return LocationAccuracy.bestForNavigation;
      default:
        return LocationAccuracy.high;
    }
  }

  /// Converts a [Position] to a JSON-safe map.
  static Map<String, dynamic> positionToMap(Position position) {
    return {
      'latitude': position.latitude,
      'longitude': position.longitude,
      'altitude': position.altitude,
      'accuracy': position.accuracy,
      'heading': position.heading,
      'speed': position.speed,
      'speedAccuracy': position.speedAccuracy,
      'timestamp': position.timestamp.toIso8601String(),
    };
  }

  @override
  Future<ValidationResult> validateArgs(
    String method,
    Map<String, dynamic> args,
  ) async {
    switch (method) {
      case 'getCurrentPosition':
      case 'watchPosition':
        return validatePositionArgs(args);
      case 'clearWatch':
        final watchId = args['watchId'];
        if (watchId != null && watchId is! int) {
          return ValidationResult.invalid('watchId must be an integer');
        }
        return ValidationResult.valid();
      default:
        return ValidationResult.valid();
    }
  }

  /// Validates accuracy and distanceFilter. Public for unit tests.
  static ValidationResult validatePositionArgs(Map<String, dynamic> args) {
    final accuracy = args['accuracy'];
    if (accuracy != null) {
      if (accuracy is! String) {
        return ValidationResult.invalid('accuracy must be a string');
      }
      if (!kAccuracyLevels.contains(accuracy)) {
        return ValidationResult.invalid(
          'accuracy must be one of: ${kAccuracyLevels.join(', ')}',
        );
      }
    }
    final timeoutMs = args['timeoutMs'];
    if (timeoutMs != null) {
      if (timeoutMs is! num) {
        return ValidationResult.invalid('timeoutMs must be a number');
      }
      if (timeoutMs < 1 || timeoutMs > 60000) {
        return ValidationResult.invalid(
            'timeoutMs must be between 1 and 60000');
      }
    }
    final distanceFilter = args['distanceFilter'];
    if (distanceFilter != null) {
      if (distanceFilter is! num) {
        return ValidationResult.invalid('distanceFilter must be a number');
      }
      if (distanceFilter < 0 || distanceFilter > 100000) {
        return ValidationResult.invalid(
          'distanceFilter must be between 0 and 100000',
        );
      }
    }
    return ValidationResult.valid();
  }

  @override
  Future<void> onDispose() async {
    await _cancelAll();
  }
}
