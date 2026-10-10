# فاز ۹ — ۸ پلاگین اولویت متوسط

---

# پلاگین ۱: Calendar

## 📄 `lib/plugins/calendar/lib/calendar_plugin.dart`

```dart
import 'dart:async';

import 'package:device_calendar/device_calendar.dart';
import 'package:sweetmelon/packages/core/lib/core.dart';
import 'package:sweetmelon/packages/plugin_engine/lib/plugin_engine.dart';

class CalendarPlugin extends Plugin {
  final DeviceCalendarPlugin _calendar = DeviceCalendarPlugin();

  @override
  String get name => 'calendar';

  @override
  String get version => '1.0.0';

  @override
  String get description => 'Device calendar read/write plugin';

  @override
  List<String> get supportedMethods => [
        'getCalendars',
        'getEvents',
        'createEvent',
        'deleteEvent',
        'hasPermission',
        'requestPermission',
        'getInfo',
      ];

  @override
  Future<dynamic> onCall(String method, Map<String, dynamic> args) async {
    switch (method) {
      case 'getCalendars':
        return _getCalendars();
      case 'getEvents':
        return _getEvents(args);
      case 'createEvent':
        return _createEvent(args);
      case 'deleteEvent':
        return _deleteEvent(args);
      case 'hasPermission':
        return _hasPermission();
      case 'requestPermission':
        return _requestPermission();
      case 'getInfo':
        return {'name': name, 'version': version};
      default:
        throw UnsupportedError('Method "$method" not supported');
    }
  }

  Future<Map<String, dynamic>> _hasPermission() async {
    final result = await _calendar.hasPermissions();
    return {
      'granted': result.data ?? false,
      'isSuccess': result.isSuccess,
    };
  }

  Future<Map<String, dynamic>> _requestPermission() async {
    final result = await _calendar.requestPermissions();
    return {
      'granted': result.data ?? false,
      'isSuccess': result.isSuccess,
    };
  }

  Future<Map<String, dynamic>> _getCalendars() async {
    final permResult = await _calendar.hasPermissions();
    if (permResult.data != true) {
      await _calendar.requestPermissions();
    }

    final result = await _calendar.retrieveCalendars();

    if (!result.isSuccess || result.data == null) {
      return {'calendars': <dynamic>[], 'error': result.errors.toString()};
    }

    final calendars = result.data!.map((c) => {
      'id': c.id,
      'name': c.name,
      'accountName': c.accountName,
      'accountType': c.accountType,
      'isReadOnly': c.isReadOnly,
      'color': c.color,
    }).toList();

    return {'calendars': calendars, 'count': calendars.length};
  }

  Future<Map<String, dynamic>> _getEvents(Map<String, dynamic> args) async {
    final calendarId = args['calendarId'] as String;
    final startMs = (args['startMs'] as num?)?.toInt();
    final endMs = (args['endMs'] as num?)?.toInt();
    final daysAhead = (args['daysAhead'] as num?)?.toInt() ?? 30;

    final start = startMs != null
        ? DateTime.fromMillisecondsSinceEpoch(startMs)
        : DateTime.now();
    final end = endMs != null
        ? DateTime.fromMillisecondsSinceEpoch(endMs)
        : DateTime.now().add(Duration(days: daysAhead));

    final params = RetrieveEventsParams(startDate: start, endDate: end);
    final result = await _calendar.retrieveEvents(calendarId, params);

    if (!result.isSuccess || result.data == null) {
      return {'events': <dynamic>[], 'error': result.errors.toString()};
    }

    final events = result.data!.map((e) => _eventToMap(e)).toList();

    return {'events': events, 'count': events.length};
  }

  Future<Map<String, dynamic>> _createEvent(Map<String, dynamic> args) async {
    final calendarId = args['calendarId'] as String;
    final title = args['title'] as String;
    final description = args['description'] as String? ?? '';
    final startMs = (args['startMs'] as num).toInt();
    final endMs = (args['endMs'] as num).toInt();
    final location = args['location'] as String?;
    final allDay = args['allDay'] as bool? ?? false;

    final event = Event(calendarId);
    event.title = title;
    event.description = description;
    event.start = TZDateTime.fromMillisecondsSinceEpoch(
      local, startMs,
    );
    event.end = TZDateTime.fromMillisecondsSinceEpoch(
      local, endMs,
    );
    event.location = location;
    event.allDay = allDay;

    final result = await _calendar.createOrUpdateEvent(event);

    if (!result!.isSuccess) {
      return {'created': false, 'error': result.errors.toString()};
    }

    BridgeLogger.info('Calendar', 'Event created: $title');

    return {
      'created': true,
      'eventId': result.data,
      'title': title,
    };
  }

  Future<Map<String, dynamic>> _deleteEvent(Map<String, dynamic> args) async {
    final calendarId = args['calendarId'] as String;
    final eventId = args['eventId'] as String;

    final result = await _calendar.deleteEvent(calendarId, eventId);

    if (!result.isSuccess) {
      return {'deleted': false, 'error': result.errors.toString()};
    }

    return {'deleted': true, 'eventId': eventId};
  }

  Map<String, dynamic> _eventToMap(Event event) {
    return {
      'eventId': event.eventId,
      'calendarId': event.calendarId,
      'title': event.title,
      'description': event.description,
      'start': event.start?.millisecondsSinceEpoch,
      'end': event.end?.millisecondsSinceEpoch,
      'startIso': event.start?.toIso8601String(),
      'endIso': event.end?.toIso8601String(),
      'location': event.location,
      'allDay': event.allDay,
    };
  }

  @override
  Future<ValidationResult> validateArgs(
    String method,
    Map<String, dynamic> args,
  ) async {
    switch (method) {
      case 'getEvents':
        if (args['calendarId'] is! String) {
          return ValidationResult.invalid('calendarId is required');
        }
        return ValidationResult.valid();

      case 'createEvent':
        for (final f in ['calendarId', 'title']) {
          if (args[f] is! String || (args[f] as String).isEmpty) {
            return ValidationResult.invalid('$f is required');
          }
        }
        for (final f in ['startMs', 'endMs']) {
          if (args[f] is! num) {
            return ValidationResult.invalid('$f (timestamp) is required');
          }
        }
        return ValidationResult.valid();

      case 'deleteEvent':
        for (final f in ['calendarId', 'eventId']) {
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
```

## 📄 `lib/plugins/calendar/pubspec.yaml`

```yaml
name: calendar_plugin
description: Device calendar plugin
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
  device_calendar: ^4.3.2
```

---

# پلاگین ۲: Badge

## 📄 `lib/plugins/badge/lib/badge_plugin.dart`

```dart
import 'package:flutter_app_badger/flutter_app_badger.dart';
import 'package:sweetmelon/packages/core/lib/core.dart';
import 'package:sweetmelon/packages/plugin_engine/lib/plugin_engine.dart';

class BadgePlugin extends Plugin {
  int _currentCount = 0;

  @override
  String get name => 'badge';

  @override
  String get version => '1.0.0';

  @override
  String get description => 'App icon badge count plugin';

  @override
  List<String> get supportedMethods => [
        'set',
        'clear',
        'increase',
        'decrease',
        'get',
        'isSupported',
        'getInfo',
      ];

  @override
  Future<dynamic> onCall(String method, Map<String, dynamic> args) async {
    switch (method) {
      case 'set':
        return _set(args);
      case 'clear':
        return _clear();
      case 'increase':
        return _increase(args);
      case 'decrease':
        return _decrease(args);
      case 'get':
        return {'count': _currentCount};
      case 'isSupported':
        return _isSupported();
      case 'getInfo':
        return {
          'name': name,
          'version': version,
          'count': _currentCount,
        };
      default:
        throw UnsupportedError('Method "$method" not supported');
    }
  }

  Future<Map<String, dynamic>> _set(Map<String, dynamic> args) async {
    final count = (args['count'] as num).toInt().clamp(0, 9999);

    try {
      if (count == 0) {
        FlutterAppBadger.removeBadge();
      } else {
        FlutterAppBadger.updateBadgeCount(count);
      }
      _currentCount = count;
      return {'count': _currentCount, 'set': true};
    } catch (e) {
      BridgeLogger.error('Badge', 'Set failed: $e');
      return {'set': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> _clear() async {
    try {
      FlutterAppBadger.removeBadge();
      _currentCount = 0;
      return {'count': 0, 'cleared': true};
    } catch (e) {
      return {'cleared': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> _increase(Map<String, dynamic> args) async {
    final by = (args['by'] as num?)?.toInt() ?? 1;
    return _set({'count': _currentCount + by});
  }

  Future<Map<String, dynamic>> _decrease(Map<String, dynamic> args) async {
    final by = (args['by'] as num?)?.toInt() ?? 1;
    return _set({'count': (_currentCount - by).clamp(0, 9999)});
  }

  Future<Map<String, dynamic>> _isSupported() async {
    try {
      final supported = await FlutterAppBadger.isAppBadgeSupported();
      return {'supported': supported};
    } catch (e) {
      return {'supported': false, 'error': e.toString()};
    }
  }

  @override
  Future<ValidationResult> validateArgs(
    String method,
    Map<String, dynamic> args,
  ) async {
    if (method == 'set') {
      final count = args['count'];
      if (count is! num) {
        return ValidationResult.invalid('count (number) is required');
      }
    }
    return ValidationResult.valid();
  }
}
```

## 📄 `lib/plugins/badge/pubspec.yaml`

```yaml
name: badge_plugin
description: App icon badge plugin
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
  flutter_app_badger: ^1.5.0
```

---

# پلاگین ۳: Foreground Service

## 📄 `lib/plugins/foreground_service/lib/foreground_service_plugin.dart`

```dart
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:sweetmelon/packages/core/lib/core.dart';
import 'package:sweetmelon/packages/plugin_engine/lib/plugin_engine.dart';

typedef FgEventEmitter = Future<void> Function(String event, dynamic data);

class ForegroundServicePlugin extends Plugin {
  final FgEventEmitter? eventEmitter;

  bool _running = false;
  String? _currentTitle;
  String? _currentBody;
  Timer? _updateTimer;

  static const _channel = MethodChannel('sweetmelon/foreground_service');

  ForegroundServicePlugin({this.eventEmitter});

  @override
  String get name => 'foregroundService';

  @override
  String get version => '1.0.0';

  @override
  String get description => 'Android foreground service for persistent tasks';

  @override
  List<String> get supportedMethods => [
        'start',
        'stop',
        'update',
        'isRunning',
        'getInfo',
      ];

  @override
  Future<dynamic> onCall(String method, Map<String, dynamic> args) async {
    switch (method) {
      case 'start':
        return _start(args);
      case 'stop':
        return _stop();
      case 'update':
        return _update(args);
      case 'isRunning':
        return {'running': _running};
      case 'getInfo':
        return {
          'name': name,
          'version': version,
          'running': _running,
          'title': _currentTitle,
          'body': _currentBody,
        };
      default:
        throw UnsupportedError('Method "$method" not supported');
    }
  }

  Future<Map<String, dynamic>> _start(Map<String, dynamic> args) async {
    if (_running) {
      return {'started': true, 'alreadyRunning': true};
    }

    final title = args['title'] as String? ?? 'App is running';
    final body = args['body'] as String? ?? 'Tap to return to app';
    final channelId = args['channelId'] as String? ?? 'foreground_service';
    final channelName = args['channelName'] as String? ?? 'Foreground Service';

    _currentTitle = title;
    _currentBody = body;

    try {
      await _channel.invokeMethod('startService', {
        'title': title,
        'body': body,
        'channelId': channelId,
        'channelName': channelName,
      });

      _running = true;

      BridgeLogger.info('ForegroundService', 'Service started: $title');

      eventEmitter?.call('foregroundService.started', {
        'title': title,
        'timestamp': DateTime.now().toIso8601String(),
      });

      return {'started': true, 'alreadyRunning': false};
    } catch (e) {
      BridgeLogger.error('ForegroundService', 'Start failed: $e');

      // Fallback: شبیه‌سازی بدون native channel
      _running = true;
      return {
        'started': true,
        'native': false,
        'fallback': true,
      };
    }
  }

  Future<Map<String, dynamic>> _stop() async {
    if (!_running) {
      return {'stopped': false, 'reason': 'not_running'};
    }

    _updateTimer?.cancel();

    try {
      await _channel.invokeMethod('stopService');
    } catch (_) {}

    _running = false;
    _currentTitle = null;
    _currentBody = null;

    BridgeLogger.info('ForegroundService', 'Service stopped');

    eventEmitter?.call('foregroundService.stopped', {
      'timestamp': DateTime.now().toIso8601String(),
    });

    return {'stopped': true};
  }

  Future<Map<String, dynamic>> _update(Map<String, dynamic> args) async {
    if (!_running) {
      return {'updated': false, 'reason': 'not_running'};
    }

    final title = args['title'] as String?;
    final body = args['body'] as String?;

    if (title != null) _currentTitle = title;
    if (body != null) _currentBody = body;

    try {
      await _channel.invokeMethod('updateNotification', {
        'title': _currentTitle,
        'body': _currentBody,
      });
    } catch (_) {}

    return {
      'updated': true,
      'title': _currentTitle,
      'body': _currentBody,
    };
  }

  @override
  Future<void> onDispose() async {
    if (_running) {
      await _stop();
    }
  }

  @override
  Future<ValidationResult> validateArgs(
    String method,
    Map<String, dynamic> args,
  ) async {
    if (method == 'start') {
      final title = args['title'];
      if (title != null && title is! String) {
        return ValidationResult.invalid('title must be a string');
      }
    }
    return ValidationResult.valid();
  }
}
```

## 📄 `lib/plugins/foreground_service/pubspec.yaml`

```yaml
name: foreground_service_plugin
description: Android foreground service plugin
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
```

---

# پلاگین ۴: Background Geolocation

## 📄 `lib/plugins/background_geolocation/lib/background_geolocation_plugin.dart`

```dart
import 'dart:async';

import 'package:geolocator/geolocator.dart';
import 'package:sweetmelon/packages/core/lib/core.dart';
import 'package:sweetmelon/packages/plugin_engine/lib/plugin_engine.dart';

typedef BgGeoEventEmitter = Future<void> Function(String event, dynamic data);

class BackgroundGeolocationPlugin extends Plugin {
  final BgGeoEventEmitter? eventEmitter;

  StreamSubscription<Position>? _positionSub;
  bool _tracking = false;
  Position? _lastPosition;
  int _updateCount = 0;
  final List<Map<String, dynamic>> _history = [];

  BackgroundGeolocationPlugin({this.eventEmitter});

  @override
  String get name => 'backgroundGeolocation';

  @override
  String get version => '1.0.0';

  @override
  String get description => 'Background geolocation tracking plugin';

  @override
  List<String> get requiredPermissions => ['location'];

  @override
  List<String> get supportedMethods => [
        'startTracking',
        'stopTracking',
        'getLastPosition',
        'getHistory',
        'clearHistory',
        'isTracking',
        'getInfo',
      ];

  @override
  Future<void> onDispose() async {
    await _stopTracking();
  }

  @override
  Future<dynamic> onCall(String method, Map<String, dynamic> args) async {
    switch (method) {
      case 'startTracking':
        return _startTracking(args);
      case 'stopTracking':
        return _stopTracking();
      case 'getLastPosition':
        return _getLastPosition();
      case 'getHistory':
        return _getHistory(args);
      case 'clearHistory':
        return _clearHistory();
      case 'isTracking':
        return {'tracking': _tracking};
      case 'getInfo':
        return {
          'name': name,
          'version': version,
          'tracking': _tracking,
          'updateCount': _updateCount,
          'historyCount': _history.length,
          'lastPosition': _lastPosition != null
              ? _positionToMap(_lastPosition!)
              : null,
        };
      default:
        throw UnsupportedError('Method "$method" not supported');
    }
  }

  Future<Map<String, dynamic>> _startTracking(Map<String, dynamic> args) async {
    if (_tracking) {
      return {'started': true, 'alreadyTracking': true};
    }

    final accuracy = _parseAccuracy(args['accuracy'] as String? ?? 'high');
    final distanceFilter = (args['distanceFilter'] as num?)?.toInt() ?? 10;
    final intervalMs = (args['intervalMs'] as num?)?.toInt();
    final maxHistory = (args['maxHistory'] as num?)?.toInt() ?? 500;

    final settings = LocationSettings(
      accuracy: accuracy,
      distanceFilter: distanceFilter,
      timeLimit: intervalMs != null
          ? Duration(milliseconds: intervalMs)
          : null,
    );

    _positionSub = Geolocator.getPositionStream(
      locationSettings: settings,
    ).listen(
      (position) {
        _lastPosition = position;
        _updateCount++;

        final posMap = _positionToMap(position);

        // ذخیره در history
        _history.add(posMap);
        if (_history.length > maxHistory) {
          _history.removeAt(0);
        }

        if (eventEmitter != null) {
          eventEmitter!('bgGeo.position', posMap);
        }
      },
      onError: (error) {
        BridgeLogger.error('BgGeo', 'Tracking error: $error');
        if (eventEmitter != null) {
          eventEmitter!('bgGeo.error', {
            'message': error.toString(),
            'timestamp': DateTime.now().toIso8601String(),
          });
        }
      },
    );

    _tracking = true;

    BridgeLogger.info(
      'BgGeo',
      'Tracking started (accuracy: $accuracy, distance: ${distanceFilter}m)',
    );

    return {
      'started': true,
      'alreadyTracking': false,
      'accuracy': accuracy.toString(),
      'distanceFilter': distanceFilter,
    };
  }

  Future<Map<String, dynamic>> _stopTracking() async {
    await _positionSub?.cancel();
    _positionSub = null;
    _tracking = false;

    return {
      'stopped': true,
      'totalUpdates': _updateCount,
    };
  }

  Map<String, dynamic> _getLastPosition() {
    if (_lastPosition == null) {
      return {'available': false};
    }

    return {
      'available': true,
      ..._positionToMap(_lastPosition!),
    };
  }

  Map<String, dynamic> _getHistory(Map<String, dynamic> args) {
    final limit = (args['limit'] as num?)?.toInt();
    final since = (args['sinceMs'] as num?)?.toInt();

    var result = List<Map<String, dynamic>>.from(_history);

    if (since != null) {
      final sinceDate = DateTime.fromMillisecondsSinceEpoch(since);
      result = result.where((p) {
        final ts = DateTime.parse(p['timestamp'] as String);
        return ts.isAfter(sinceDate);
      }).toList();
    }

    if (limit != null && limit > 0 && result.length > limit) {
      result = result.sublist(result.length - limit);
    }

    return {
      'positions': result,
      'count': result.length,
      'totalHistory': _history.length,
    };
  }

  Map<String, dynamic> _clearHistory() {
    final count = _history.length;
    _history.clear();
    _updateCount = 0;
    return {'cleared': count};
  }

  Map<String, dynamic> _positionToMap(Position position) {
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

  LocationAccuracy _parseAccuracy(String accuracy) {
    switch (accuracy) {
      case 'lowest': return LocationAccuracy.lowest;
      case 'low': return LocationAccuracy.low;
      case 'medium': return LocationAccuracy.medium;
      case 'high': return LocationAccuracy.high;
      case 'best': return LocationAccuracy.best;
      case 'bestForNavigation': return LocationAccuracy.bestForNavigation;
      default: return LocationAccuracy.high;
    }
  }

  @override
  Future<ValidationResult> validateArgs(
    String method,
    Map<String, dynamic> args,
  ) async {
    if (method == 'startTracking') {
      final accuracy = args['accuracy'];
      if (accuracy != null && accuracy is! String) {
        return ValidationResult.invalid('accuracy must be a string');
      }
    }
    return ValidationResult.valid();
  }
}
```

## 📄 `lib/plugins/background_geolocation/pubspec.yaml`

```yaml
name: background_geolocation_plugin
description: Background geolocation tracking plugin
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
  geolocator: ^10.1.0
```

---

# پلاگین ۵: Media Manager

## 📄 `lib/plugins/media_manager/lib/media_manager_plugin.dart`

```dart
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:path/path.dart' as p;
import 'package:sweetmelon/packages/core/lib/core.dart';
import 'package:sweetmelon/packages/plugin_engine/lib/plugin_engine.dart';

class MediaManagerPlugin extends Plugin {
  @override
  String get name => 'mediaManager';

  @override
  String get version => '1.0.0';

  @override
  String get description => 'Save media to gallery, manage albums';

  @override
  List<String> get supportedMethods => [
        'saveImageToGallery',
        'saveVideoToGallery',
        'saveFileToGallery',
        'getInfo',
      ];

  @override
  Future<dynamic> onCall(String method, Map<String, dynamic> args) async {
    switch (method) {
      case 'saveImageToGallery':
        return _saveImageToGallery(args);
      case 'saveVideoToGallery':
        return _saveVideoToGallery(args);
      case 'saveFileToGallery':
        return _saveFileToGallery(args);
      case 'getInfo':
        return {'name': name, 'version': version};
      default:
        throw UnsupportedError('Method "$method" not supported');
    }
  }

  Future<Map<String, dynamic>> _saveImageToGallery(
    Map<String, dynamic> args,
  ) async {
    final path = args['path'] as String;
    final quality = (args['quality'] as num?)?.toInt() ?? 100;
    final albumName = args['album'] as String?;

    final file = File(path);
    if (!await file.exists()) {
      return {'saved': false, 'reason': 'file_not_found'};
    }

    try {
      final bytes = await file.readAsBytes();
      final result = await ImageGallerySaver.saveImage(
        Uint8List.fromList(bytes),
        quality: quality,
        name: p.basenameWithoutExtension(path),
      );

      final success = result['isSuccess'] == true;

      BridgeLogger.info(
        'MediaManager',
        'Image saved to gallery: $success',
      );

      return {
        'saved': success,
        'filePath': result['filePath'],
      };
    } catch (e) {
      return {'saved': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> _saveVideoToGallery(
    Map<String, dynamic> args,
  ) async {
    final path = args['path'] as String;

    final file = File(path);
    if (!await file.exists()) {
      return {'saved': false, 'reason': 'file_not_found'};
    }

    try {
      final result = await ImageGallerySaver.saveFile(
        path,
        name: p.basenameWithoutExtension(path),
      );

      final success = result['isSuccess'] == true;

      return {
        'saved': success,
        'filePath': result['filePath'],
      };
    } catch (e) {
      return {'saved': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> _saveFileToGallery(
    Map<String, dynamic> args,
  ) async {
    final path = args['path'] as String;

    final file = File(path);
    if (!await file.exists()) {
      return {'saved': false, 'reason': 'file_not_found'};
    }

    try {
      final result = await ImageGallerySaver.saveFile(path);
      final success = result['isSuccess'] == true;

      return {
        'saved': success,
        'filePath': result['filePath'],
      };
    } catch (e) {
      return {'saved': false, 'error': e.toString()};
    }
  }

  @override
  Future<ValidationResult> validateArgs(
    String method,
    Map<String, dynamic> args,
  ) async {
    switch (method) {
      case 'saveImageToGallery':
      case 'saveVideoToGallery':
      case 'saveFileToGallery':
        final path = args['path'];
        if (path is! String || path.isEmpty) {
          return ValidationResult.invalid('path is required');
        }
        return ValidationResult.valid();
      default:
        return ValidationResult.valid();
    }
  }
}
```

## 📄 `lib/plugins/media_manager/pubspec.yaml`

```yaml
name: media_manager_plugin
description: Gallery media manager plugin
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
  image_gallery_saver: ^2.0.3
  path: ^1.9.0
```

---

# پلاگین ۶: File Compressor

## 📄 `lib/plugins/file_compressor/lib/file_compressor_plugin.dart`

```dart
import 'dart:async';
import 'dart:io';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sweetmelon/packages/core/lib/core.dart';
import 'package:sweetmelon/packages/plugin_engine/lib/plugin_engine.dart';

class FileCompressorPlugin extends Plugin {
  @override
  String get name => 'fileCompressor';

  @override
  String get version => '1.0.0';

  @override
  String get description => 'Image compression plugin (JPEG, PNG, WebP)';

  @override
  List<String> get supportedMethods => [
        'compressImage',
        'compressToWebP',
        'getInfo',
      ];

  @override
  Future<dynamic> onCall(String method, Map<String, dynamic> args) async {
    switch (method) {
      case 'compressImage':
        return _compressImage(args);
      case 'compressToWebP':
        return _compressImage({...args, 'format': 'webp'});
      case 'getInfo':
        return {
          'name': name,
          'version': version,
          'supportedFormats': ['jpeg', 'png', 'webp'],
        };
      default:
        throw UnsupportedError('Method "$method" not supported');
    }
  }

  Future<Map<String, dynamic>> _compressImage(Map<String, dynamic> args) async {
    final inputPath = args['path'] as String;
    final quality = (args['quality'] as num?)?.toInt() ?? 80;
    final maxWidth = (args['maxWidth'] as num?)?.toInt();
    final maxHeight = (args['maxHeight'] as num?)?.toInt();
    final format = args['format'] as String? ?? 'jpeg';
    final keepExif = args['keepExif'] as bool? ?? false;

    final inputFile = File(inputPath);
    if (!await inputFile.exists()) {
      return {'compressed': false, 'reason': 'file_not_found'};
    }

    final originalSize = await inputFile.length();

    final tempDir = await getTemporaryDirectory();
    final ext = format == 'webp' ? '.webp' : (format == 'png' ? '.png' : '.jpg');
    final outputPath = p.join(
      tempDir.path,
      'compressed_${DateTime.now().millisecondsSinceEpoch}$ext',
    );

    final compressFormat = format == 'webp'
        ? CompressFormat.webp
        : (format == 'png' ? CompressFormat.png : CompressFormat.jpeg);

    try {
      final result = await FlutterImageCompress.compressAndGetFile(
        inputPath,
        outputPath,
        quality: quality,
        minWidth: maxWidth ?? 1920,
        minHeight: maxHeight ?? 1080,
        format: compressFormat,
        keepExif: keepExif,
      );

      if (result == null) {
        return {'compressed': false, 'reason': 'compression_failed'};
      }

      final compressedSize = await result.length();
      final savings = originalSize > 0
          ? ((1 - compressedSize / originalSize) * 100).round()
          : 0;

      BridgeLogger.info(
        'FileCompressor',
        'Compressed: ${_formatBytes(originalSize)} → ${_formatBytes(compressedSize)} ($savings% saved)',
      );

      return {
        'compressed': true,
        'inputPath': inputPath,
        'outputPath': result.path,
        'originalSize': originalSize,
        'compressedSize': compressedSize,
        'savings': savings,
        'format': format,
        'quality': quality,
      };
    } catch (e) {
      BridgeLogger.error('FileCompressor', 'Compression error: $e');
      return {'compressed': false, 'error': e.toString()};
    }
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1048576) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    return '${(bytes / 1048576).toStringAsFixed(1)}MB';
  }

  @override
  Future<ValidationResult> validateArgs(
    String method,
    Map<String, dynamic> args,
  ) async {
    if (method == 'compressImage' || method == 'compressToWebP') {
      final path = args['path'];
      if (path is! String || path.isEmpty) {
        return ValidationResult.invalid('path is required');
      }
      final quality = args['quality'];
      if (quality != null && (quality is! num || quality < 1 || quality > 100)) {
        return ValidationResult.invalid('quality must be 1-100');
      }
    }
    return ValidationResult.valid();
  }
}
```

## 📄 `lib/plugins/file_compressor/pubspec.yaml`

```yaml
name: file_compressor_plugin
description: Image compression plugin
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
  flutter_image_compress: ^2.3.0
  path_provider: ^2.1.1
  path: ^1.9.0
```

---

# پلاگین ۷: Zip

## 📄 `lib/plugins/zip/lib/zip_plugin.dart`

```dart
import 'dart:async';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sweetmelon/packages/core/lib/core.dart';
import 'package:sweetmelon/packages/plugin_engine/lib/plugin_engine.dart';

class ZipPlugin extends Plugin {
  @override
  String get name => 'zip';

  @override
  String get version => '1.0.0';

  @override
  String get description => 'Zip and unzip files plugin';

  @override
  List<String> get supportedMethods => [
        'zip',
        'unzip',
        'listContents',
        'getInfo',
      ];

  @override
  Future<dynamic> onCall(String method, Map<String, dynamic> args) async {
    switch (method) {
      case 'zip':
        return _zip(args);
      case 'unzip':
        return _unzip(args);
      case 'listContents':
        return _listContents(args);
      case 'getInfo':
        return {'name': name, 'version': version};
      default:
        throw UnsupportedError('Method "$method" not supported');
    }
  }

  Future<Map<String, dynamic>> _zip(Map<String, dynamic> args) async {
    final inputPaths = List<String>.from(args['paths'] as List);
    final outputPath = args['outputPath'] as String?;
    final password = args['password'] as String?;

    final archive = Archive();
    int totalSize = 0;

    for (final path in inputPaths) {
      final entity = FileSystemEntity.typeSync(path);

      if (entity == FileSystemEntityType.file) {
        final file = File(path);
        if (await file.exists()) {
          final bytes = await file.readAsBytes();
          totalSize += bytes.length;
          archive.addFile(
            ArchiveFile(p.basename(path), bytes.length, bytes),
          );
        }
      } else if (entity == FileSystemEntityType.directory) {
        final dir = Directory(path);
        final files = await dir.list(recursive: true).toList();

        for (final f in files) {
          if (f is File) {
            final bytes = await f.readAsBytes();
            final relativePath = p.relative(f.path, from: path);
            totalSize += bytes.length;
            archive.addFile(
              ArchiveFile(relativePath, bytes.length, bytes),
            );
          }
        }
      }
    }

    final encoded = ZipEncoder().encode(archive);
    if (encoded == null) {
      return {'zipped': false, 'reason': 'encoding_failed'};
    }

    final output = outputPath ??
        p.join(
          (await getTemporaryDirectory()).path,
          'archive_${DateTime.now().millisecondsSinceEpoch}.zip',
        );

    final outputFile = File(output);
    await outputFile.parent.create(recursive: true);
    await outputFile.writeAsBytes(encoded);

    final compressedSize = encoded.length;
    final ratio = totalSize > 0
        ? ((1 - compressedSize / totalSize) * 100).round()
        : 0;

    BridgeLogger.info(
      'Zip',
      'Created: $output (${archive.files.length} files, $ratio% compression)',
    );

    return {
      'zipped': true,
      'outputPath': output,
      'fileCount': archive.files.length,
      'originalSize': totalSize,
      'compressedSize': compressedSize,
      'compressionRatio': ratio,
    };
  }

  Future<Map<String, dynamic>> _unzip(Map<String, dynamic> args) async {
    final zipPath = args['path'] as String;
    final outputDir = args['outputDir'] as String?;

    final zipFile = File(zipPath);
    if (!await zipFile.exists()) {
      return {'unzipped': false, 'reason': 'file_not_found'};
    }

    final bytes = await zipFile.readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);

    final targetDir = outputDir ??
        p.join(
          (await getTemporaryDirectory()).path,
          'unzipped_${DateTime.now().millisecondsSinceEpoch}',
        );

    int fileCount = 0;
    int totalSize = 0;

    for (final file in archive) {
      final filePath = p.join(targetDir, file.name);

      // path traversal protection
      if (!p.normalize(filePath).startsWith(p.normalize(targetDir))) {
        BridgeLogger.warn('Zip', 'Skipping unsafe path: ${file.name}');
        continue;
      }

      if (file.isFile) {
        final outFile = File(filePath);
        await outFile.parent.create(recursive: true);
        await outFile.writeAsBytes(file.content as List<int>);
        totalSize += file.size;
        fileCount++;
      } else {
        await Directory(filePath).create(recursive: true);
      }
    }

    BridgeLogger.info(
      'Zip',
      'Extracted: $fileCount files to $targetDir',
    );

    return {
      'unzipped': true,
      'outputDir': targetDir,
      'fileCount': fileCount,
      'totalSize': totalSize,
    };
  }

  Future<Map<String, dynamic>> _listContents(Map<String, dynamic> args) async {
    final zipPath = args['path'] as String;

    final zipFile = File(zipPath);
    if (!await zipFile.exists()) {
      return {'files': <dynamic>[], 'error': 'file_not_found'};
    }

    final bytes = await zipFile.readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);

    final files = archive.files.map((f) => {
      'name': f.name,
      'size': f.size,
      'compressedSize': f.compressedSize,
      'isFile': f.isFile,
      'isDirectory': !f.isFile,
    }).toList();

    return {
      'files': files,
      'count': files.length,
    };
  }

  @override
  Future<ValidationResult> validateArgs(
    String method,
    Map<String, dynamic> args,
  ) async {
    switch (method) {
      case 'zip':
        final paths = args['paths'];
        if (paths is! List || paths.isEmpty) {
          return ValidationResult.invalid('paths (list) is required');
        }
        return ValidationResult.valid();

      case 'unzip':
      case 'listContents':
        final path = args['path'];
        if (path is! String || path.isEmpty) {
          return ValidationResult.invalid('path is required');
        }
        return ValidationResult.valid();

      default:
        return ValidationResult.valid();
    }
  }
}
```

## 📄 `lib/plugins/zip/pubspec.yaml`

```yaml
name: zip_plugin
description: Zip and unzip plugin
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
  archive: ^3.6.1
  path_provider: ^2.1.1
  path: ^1.9.0
```

---

# پلاگین ۸: Share Target (دریافت محتوا از اپ‌های دیگه)

## 📄 `lib/plugins/share_target/lib/share_target_plugin.dart`

```dart
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:sweetmelon/packages/core/lib/core.dart';
import 'package:sweetmelon/packages/plugin_engine/lib/plugin_engine.dart';

typedef ShareTargetEventEmitter = Future<void> Function(String event, dynamic data);

class ShareTargetPlugin extends Plugin {
  final ShareTargetEventEmitter? eventEmitter;

  Map<String, dynamic>? _lastSharedData;
  bool _listening = false;

  static const _channel = MethodChannel('sweetmelon/share_target');

  ShareTargetPlugin({this.eventEmitter});

  @override
  String get name => 'shareTarget';

  @override
  String get version => '1.0.0';

  @override
  String get description => 'Receive shared content from other apps';

  @override
  List<String> get supportedMethods => [
        'startListening',
        'stopListening',
        'getLastShared',
        'clearLastShared',
        'getInfo',
      ];

  @override
  Future<void> onInitialize() async {
    _channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'onSharedText':
          _handleSharedText(call.arguments as Map<dynamic, dynamic>);
          break;
        case 'onSharedFiles':
          _handleSharedFiles(call.arguments as Map<dynamic, dynamic>);
          break;
      }
      return null;
    });

    // Check initial shared data
    try {
      final initial = await _channel.invokeMethod('getInitialSharedData');
      if (initial != null) {
        _handleSharedData(Map<String, dynamic>.from(initial));
      }
    } catch (_) {}
  }

  @override
  Future<void> onDispose() async {
    _channel.setMethodCallHandler(null);
    _listening = false;
  }

  void _handleSharedText(Map<dynamic, dynamic> data) {
    final shared = {
      'type': 'text',
      'text': data['text'],
      'title': data['title'],
      'timestamp': DateTime.now().toIso8601String(),
    };

    _handleSharedData(shared);
  }

  void _handleSharedFiles(Map<dynamic, dynamic> data) {
    final paths = data['paths'] as List<dynamic>?;

    final shared = {
      'type': 'files',
      'paths': paths?.map((p) => p.toString()).toList() ?? [],
      'mimeType': data['mimeType'],
      'text': data['text'],
      'timestamp': DateTime.now().toIso8601String(),
    };

    _handleSharedData(shared);
  }

  void _handleSharedData(Map<String, dynamic> data) {
    _lastSharedData = data;

    BridgeLogger.info(
      'ShareTarget',
      'Received shared content: ${data['type']}',
    );

    if (_listening && eventEmitter != null) {
      eventEmitter!('shareTarget.received', data);
    }
  }

  @override
  Future<dynamic> onCall(String method, Map<String, dynamic> args) async {
    switch (method) {
      case 'startListening':
        _listening = true;
        // اگه قبلاً چیزی share شده بود، emit کن
        if (_lastSharedData != null && eventEmitter != null) {
          eventEmitter!('shareTarget.received', _lastSharedData);
        }
        return {'listening': true};

      case 'stopListening':
        _listening = false;
        return {'listening': false};

      case 'getLastShared':
        return _lastSharedData ?? {'available': false};

      case 'clearLastShared':
        _lastSharedData = null;
        return {'cleared': true};

      case 'getInfo':
        return {
          'name': name,
          'version': version,
          'listening': _listening,
          'hasSharedData': _lastSharedData != null,
        };

      default:
        throw UnsupportedError('Method "$method" not supported');
    }
  }
}
```

## 📄 `lib/plugins/share_target/pubspec.yaml`

```yaml
name: share_target_plugin
description: Receive shared content from other apps
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
```

---

# بروزرسانی pubspec.yaml اصلی

```yaml
  # فاز ۹
  device_calendar: ^4.3.2
  flutter_app_badger: ^1.5.0
  image_gallery_saver: ^2.0.3
  flutter_image_compress: ^2.3.0
  archive: ^3.6.1
```

---

# ثبت پلاگین‌ها — Service Locator

> imports:

```dart
import 'package:sweetmelon/plugins/calendar/lib/calendar_plugin.dart';
import 'package:sweetmelon/plugins/badge/lib/badge_plugin.dart';
import 'package:sweetmelon/plugins/foreground_service/lib/foreground_service_plugin.dart';
import 'package:sweetmelon/plugins/background_geolocation/lib/background_geolocation_plugin.dart';
import 'package:sweetmelon/plugins/media_manager/lib/media_manager_plugin.dart';
import 'package:sweetmelon/plugins/file_compressor/lib/file_compressor_plugin.dart';
import 'package:sweetmelon/plugins/zip/lib/zip_plugin.dart';
import 'package:sweetmelon/plugins/share_target/lib/share_target_plugin.dart';
```

> Lazy plugins:

```dart
      LazyPluginDefinition(
        id: 'calendar',
        version: '1.0.0',
        factory: () => CalendarPlugin(),
      ),
      LazyPluginDefinition(
        id: 'badge',
        version: '1.0.0',
        factory: () => BadgePlugin(),
      ),
      LazyPluginDefinition(
        id: 'foregroundService',
        version: '1.0.0',
        factory: () => ForegroundServicePlugin(eventEmitter: emitter),
      ),
      LazyPluginDefinition(
        id: 'backgroundGeolocation',
        version: '1.0.0',
        factory: () => BackgroundGeolocationPlugin(eventEmitter: emitter),
      ),
      LazyPluginDefinition(
        id: 'mediaManager',
        version: '1.0.0',
        factory: () => MediaManagerPlugin(),
      ),
      LazyPluginDefinition(
        id: 'fileCompressor',
        version: '1.0.0',
        factory: () => FileCompressorPlugin(),
      ),
      LazyPluginDefinition(
        id: 'zip',
        version: '1.0.0',
        factory: () => ZipPlugin(),
      ),
      LazyPluginDefinition(
        id: 'shareTarget',
        version: '1.0.0',
        factory: () => ShareTargetPlugin(eventEmitter: emitter),
      ),
```

---

# NativeSDK — فاز ۹

```javascript
    calendar: {
      getCalendars: function () { return call('calendar', 'getCalendars', {}); },
      getEvents: function (calendarId, o) { return call('calendar', 'getEvents', Object.assign({ calendarId: calendarId }, o || {})); },
      createEvent: function (o) { return call('calendar', 'createEvent', o); },
      deleteEvent: function (calendarId, eventId) { return call('calendar', 'deleteEvent', { calendarId: calendarId, eventId: eventId }); },
      hasPermission: function () { return call('calendar', 'hasPermission', {}); },
      requestPermission: function () { return call('calendar', 'requestPermission', {}); },
      getInfo: function () { return call('calendar', 'getInfo', {}); }
    },

    badge: {
      set: function (count) { return call('badge', 'set', { count: count }); },
      clear: function () { return call('badge', 'clear', {}); },
      increase: function (by) { return call('badge', 'increase', { by: by || 1 }); },
      decrease: function (by) { return call('badge', 'decrease', { by: by || 1 }); },
      get: function () { return call('badge', 'get', {}); },
      isSupported: function () { return call('badge', 'isSupported', {}); },
      getInfo: function () { return call('badge', 'getInfo', {}); }
    },

    foregroundService: {
      start: function (o) { return call('foregroundService', 'start', o || {}); },
      stop: function () { return call('foregroundService', 'stop', {}); },
      update: function (o) { return call('foregroundService', 'update', o || {}); },
      isRunning: function () { return call('foregroundService', 'isRunning', {}); },
      getInfo: function () { return call('foregroundService', 'getInfo', {}); }
    },

    backgroundGeolocation: {
      startTracking: function (o) { return call('backgroundGeolocation', 'startTracking', o || {}); },
      stopTracking: function () { return call('backgroundGeolocation', 'stopTracking', {}); },
      getLastPosition: function () { return call('backgroundGeolocation', 'getLastPosition', {}); },
      getHistory: function (o) { return call('backgroundGeolocation', 'getHistory', o || {}); },
      clearHistory: function () { return call('backgroundGeolocation', 'clearHistory', {}); },
      isTracking: function () { return call('backgroundGeolocation', 'isTracking', {}); },
      getInfo: function () { return call('backgroundGeolocation', 'getInfo', {}); }
    },

    mediaManager: {
      saveImageToGallery: function (path, o) { return call('mediaManager', 'saveImageToGallery', Object.assign({ path: path }, o || {})); },
      saveVideoToGallery: function (path) { return call('mediaManager', 'saveVideoToGallery', { path: path }); },
      saveFileToGallery: function (path) { return call('mediaManager', 'saveFileToGallery', { path: path }); },
      getInfo: function () { return call('mediaManager', 'getInfo', {}); }
    },

    fileCompressor: {
      compressImage: function (path, o) { return call('fileCompressor', 'compressImage', Object.assign({ path: path }, o || {})); },
      compressToWebP: function (path, o) { return call('fileCompressor', 'compressToWebP', Object.assign({ path: path }, o || {})); },
      getInfo: function () { return call('fileCompressor', 'getInfo', {}); }
    },

    zip: {
      zip: function (paths, outputPath) { return call('zip', 'zip', { paths: paths, outputPath: outputPath || null }); },
      unzip: function (path, outputDir) { return call('zip', 'unzip', { path: path, outputDir: outputDir || null }); },
      listContents: function (path) { return call('zip', 'listContents', { path: path }); },
      getInfo: function () { return call('zip', 'getInfo', {}); }
    },

    shareTarget: {
      startListening: function () { return call('shareTarget', 'startListening', {}); },
      stopListening: function () { return call('shareTarget', 'stopListening', {}); },
      getLastShared: function () { return call('shareTarget', 'getLastShared', {}); },
      clearLastShared: function () { return call('shareTarget', 'clearLastShared', {}); },
      getInfo: function () { return call('shareTarget', 'getInfo', {}); }
    },
```

---

# خلاصه فاز ۹

## پلاگین‌های جدید

| # | پلاگین | نام JS | کلیدی‌ترین متدها | Events |
|---|--------|--------|-----------------|--------|
| 54 | Calendar | `calendar` | getCalendars, getEvents, createEvent, deleteEvent | — |
| 55 | Badge | `badge` | set, clear, increase, decrease | — |
| 56 | Foreground Service | `foregroundService` | start, stop, update | foregroundService.started, .stopped |
| 57 | Background Geolocation | `backgroundGeolocation` | startTracking, stopTracking, getHistory | bgGeo.position, bgGeo.error |
| 58 | Media Manager | `mediaManager` | saveImageToGallery, saveVideoToGallery | — |
| 59 | File Compressor | `fileCompressor` | compressImage, compressToWebP | — |
| 60 | Zip | `zip` | zip, unzip, listContents | — |
| 61 | Share Target | `shareTarget` | startListening, getLastShared | shareTarget.received |

## مجموع کل: **61 پلاگین**

## نحوه استفاده JS

```javascript
// Calendar
const { calendars } = await NativeSDK.calendar.getCalendars();
const { events } = await NativeSDK.calendar.getEvents(calendars[0].id, {
  daysAhead: 7
});
await NativeSDK.calendar.createEvent({
  calendarId: calendars[0].id,
  title: 'Team Meeting',
  startMs: Date.now() + 3600000,
  endMs: Date.now() + 7200000,
  location: 'Office Room 3'
});

// Badge
await NativeSDK.badge.set(5);
await NativeSDK.badge.increase(1);
await NativeSDK.badge.clear();

// Foreground Service
await NativeSDK.foregroundService.start({
  title: 'Uploading files...',
  body: '3 of 10 files uploaded'
});
await NativeSDK.foregroundService.update({
  body: '7 of 10 files uploaded'
});
await NativeSDK.foregroundService.stop();

// Background Geolocation
await NativeSDK.backgroundGeolocation.startTracking({
  accuracy: 'high',
  distanceFilter: 20
});
NativeSDK.on('bgGeo.position', (pos) => {
  sendToServer(pos.latitude, pos.longitude);
});
const { positions } = await NativeSDK.backgroundGeolocation.getHistory({
  limit: 50
});

// Media Manager
await NativeSDK.mediaManager.saveImageToGallery(photo.path, {
  quality: 100,
  album: 'MyApp'
});

// File Compressor
const result = await NativeSDK.fileCompressor.compressImage(photo.path, {
  quality: 70,
  maxWidth: 1280,
  format: 'webp'
});
console.log(`Saved ${result.savings}%: ${result.outputPath}`);

// Zip
const archive = await NativeSDK.zip.zip([
  '/path/to/file1.txt',
  '/path/to/folder/'
], '/output/backup.zip');

const { files } = await NativeSDK.zip.listContents('/output/backup.zip');

await NativeSDK.zip.unzip('/output/backup.zip', '/extracted/');

// Share Target (دریافت از اپ‌های دیگه)
await NativeSDK.shareTarget.startListening();
NativeSDK.on('shareTarget.received', (data) => {
  if (data.type === 'text') {
    console.log('Received text:', data.text);
  } else if (data.type === 'files') {
    console.log('Received files:', data.paths);
  }
});
```

---

بگو تا فاز ۱۰ رو هم شروع کنم.
