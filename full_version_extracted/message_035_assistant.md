# فاز ۸ — ۸ پلاگین اولویت بالا

---

# پلاگین ۱: File Picker

## 📄 `lib/plugins/file_picker/lib/file_picker_plugin.dart`

```dart
import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart' as fp;
import 'package:sweetmelon/packages/core/lib/core.dart';
import 'package:sweetmelon/packages/plugin_engine/lib/plugin_engine.dart';

class FilePickerPlugin extends Plugin {
  @override
  String get name => 'filePicker';

  @override
  String get version => '1.0.0';

  @override
  String get description => 'Pick files, images, videos from device';

  @override
  List<String> get supportedMethods => [
        'pickFiles',
        'pickImages',
        'pickVideos',
        'pickMedia',
        'pickDirectory',
        'getInfo',
      ];

  @override
  Future<dynamic> onCall(String method, Map<String, dynamic> args) async {
    switch (method) {
      case 'pickFiles':
        return _pickFiles(args);
      case 'pickImages':
        return _pickFiles({...args, 'type': 'image'});
      case 'pickVideos':
        return _pickFiles({...args, 'type': 'video'});
      case 'pickMedia':
        return _pickFiles({...args, 'type': 'media'});
      case 'pickDirectory':
        return _pickDirectory();
      case 'getInfo':
        return {'name': name, 'version': version};
      default:
        throw UnsupportedError('Method "$method" not supported');
    }
  }

  Future<Map<String, dynamic>> _pickFiles(Map<String, dynamic> args) async {
    final allowMultiple = args['multiple'] as bool? ?? false;
    final typeStr = args['type'] as String? ?? 'any';
    final allowedExtensions = args['allowedExtensions'] != null
        ? List<String>.from(args['allowedExtensions'] as List)
        : null;
    final withData = args['withData'] as bool? ?? false;

    final fileType = _parseFileType(typeStr);

    try {
      final result = await fp.FilePicker.platform.pickFiles(
        allowMultiple: allowMultiple,
        type: allowedExtensions != null ? fp.FileType.custom : fileType,
        allowedExtensions: allowedExtensions,
        withData: withData,
        withReadStream: false,
      );

      if (result == null || result.files.isEmpty) {
        return {'picked': false, 'reason': 'cancelled', 'files': <dynamic>[]};
      }

      final files = <Map<String, dynamic>>[];

      for (final file in result.files) {
        final fileInfo = <String, dynamic>{
          'name': file.name,
          'size': file.size,
          'extension': file.extension,
          'path': file.path,
        };

        if (file.path != null) {
          final f = File(file.path!);
          if (await f.exists()) {
            final stat = await f.stat();
            fileInfo['modified'] = stat.modified.toIso8601String();
          }
        }

        files.add(fileInfo);
      }

      return {
        'picked': true,
        'files': files,
        'count': files.length,
      };
    } catch (e) {
      BridgeLogger.error('FilePicker', 'Pick error: $e');
      return {'picked': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> _pickDirectory() async {
    try {
      final path = await fp.FilePicker.platform.getDirectoryPath();

      if (path == null) {
        return {'picked': false, 'reason': 'cancelled'};
      }

      return {
        'picked': true,
        'path': path,
      };
    } catch (e) {
      return {'picked': false, 'error': e.toString()};
    }
  }

  fp.FileType _parseFileType(String type) {
    switch (type) {
      case 'image':
        return fp.FileType.image;
      case 'video':
        return fp.FileType.video;
      case 'audio':
        return fp.FileType.audio;
      case 'media':
        return fp.FileType.media;
      case 'any':
      default:
        return fp.FileType.any;
    }
  }

  @override
  Future<ValidationResult> validateArgs(
    String method,
    Map<String, dynamic> args,
  ) async {
    if (method == 'pickFiles') {
      final ext = args['allowedExtensions'];
      if (ext != null && ext is! List) {
        return ValidationResult.invalid('allowedExtensions must be a list');
      }
    }
    return ValidationResult.valid();
  }
}
```

## 📄 `lib/plugins/file_picker/pubspec.yaml`

```yaml
name: file_picker_plugin
description: File picker plugin
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
  file_picker: ^8.0.0+1
```

---

# پلاگین ۲: File Opener

## 📄 `lib/plugins/file_opener/lib/file_opener_plugin.dart`

```dart
import 'dart:async';
import 'dart:io';

import 'package:mime/mime.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:sweetmelon/packages/core/lib/core.dart';
import 'package:sweetmelon/packages/plugin_engine/lib/plugin_engine.dart';

class FileOpenerPlugin extends Plugin {
  @override
  String get name => 'fileOpener';

  @override
  String get version => '1.0.0';

  @override
  String get description => 'Open files with system default app';

  @override
  List<String> get supportedMethods => [
        'open',
        'canOpen',
        'getMimeType',
        'getInfo',
      ];

  @override
  Future<dynamic> onCall(String method, Map<String, dynamic> args) async {
    switch (method) {
      case 'open':
        return _open(args);
      case 'canOpen':
        return _canOpen(args);
      case 'getMimeType':
        return _getMimeType(args);
      case 'getInfo':
        return {'name': name, 'version': version};
      default:
        throw UnsupportedError('Method "$method" not supported');
    }
  }

  Future<Map<String, dynamic>> _open(Map<String, dynamic> args) async {
    final path = args['path'] as String;
    final mimeType = args['mimeType'] as String?;

    final file = File(path);
    if (!await file.exists()) {
      return {'opened': false, 'reason': 'file_not_found', 'path': path};
    }

    final resolvedMime = mimeType ?? lookupMimeType(path) ?? 'application/octet-stream';

    try {
      // Android: استفاده از intent
      final uri = Uri.file(path);
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      BridgeLogger.info('FileOpener', 'Opening: $path ($resolvedMime)');

      return {
        'opened': launched,
        'path': path,
        'mimeType': resolvedMime,
      };
    } catch (e) {
      BridgeLogger.error('FileOpener', 'Open failed: $e');
      return {
        'opened': false,
        'error': e.toString(),
        'path': path,
      };
    }
  }

  Future<Map<String, dynamic>> _canOpen(Map<String, dynamic> args) async {
    final path = args['path'] as String;
    final file = File(path);

    if (!await file.exists()) {
      return {'canOpen': false, 'reason': 'file_not_found'};
    }

    try {
      final uri = Uri.file(path);
      final can = await canLaunchUrl(uri);
      return {'canOpen': can, 'path': path};
    } catch (e) {
      return {'canOpen': false, 'error': e.toString()};
    }
  }

  Map<String, dynamic> _getMimeType(Map<String, dynamic> args) {
    final path = args['path'] as String;
    final mime = lookupMimeType(path) ?? 'application/octet-stream';
    return {'path': path, 'mimeType': mime};
  }

  @override
  Future<ValidationResult> validateArgs(
    String method,
    Map<String, dynamic> args,
  ) async {
    switch (method) {
      case 'open':
      case 'canOpen':
      case 'getMimeType':
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

## 📄 `lib/plugins/file_opener/pubspec.yaml`

```yaml
name: file_opener_plugin
description: Open files with system apps
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
  mime: ^1.0.5
  url_launcher: ^6.3.0
```

---

# پلاگین ۳: Motion / Sensors

## 📄 `lib/plugins/sensors/lib/sensors_plugin.dart`

```dart
import 'dart:async';

import 'package:sensors_plus/sensors_plus.dart';
import 'package:sweetmelon/packages/core/lib/core.dart';
import 'package:sweetmelon/packages/plugin_engine/lib/plugin_engine.dart';

typedef SensorEventEmitter = Future<void> Function(String event, dynamic data);

class SensorsPlugin extends Plugin {
  final SensorEventEmitter? eventEmitter;

  StreamSubscription<AccelerometerEvent>? _accelSub;
  StreamSubscription<GyroscopeEvent>? _gyroSub;
  StreamSubscription<MagnetometerEvent>? _magnetSub;
  StreamSubscription<UserAccelerometerEvent>? _userAccelSub;

  final Map<String, bool> _activeStreams = {};

  SensorsPlugin({this.eventEmitter});

  @override
  String get name => 'sensors';

  @override
  String get version => '1.0.0';

  @override
  String get description => 'Device sensors: accelerometer, gyroscope, magnetometer';

  @override
  List<String> get supportedMethods => [
        'startAccelerometer',
        'stopAccelerometer',
        'startGyroscope',
        'stopGyroscope',
        'startMagnetometer',
        'stopMagnetometer',
        'startUserAccelerometer',
        'stopUserAccelerometer',
        'stopAll',
        'getActiveStreams',
        'getInfo',
      ];

  @override
  Future<void> onDispose() async {
    await _cancelAll();
  }

  @override
  Future<dynamic> onCall(String method, Map<String, dynamic> args) async {
    switch (method) {
      case 'startAccelerometer':
        return _startAccelerometer(args);
      case 'stopAccelerometer':
        return _stopAccelerometer();
      case 'startGyroscope':
        return _startGyroscope(args);
      case 'stopGyroscope':
        return _stopGyroscope();
      case 'startMagnetometer':
        return _startMagnetometer(args);
      case 'stopMagnetometer':
        return _stopMagnetometer();
      case 'startUserAccelerometer':
        return _startUserAccelerometer(args);
      case 'stopUserAccelerometer':
        return _stopUserAccelerometer();
      case 'stopAll':
        return _stopAll();
      case 'getActiveStreams':
        return {'streams': _activeStreams};
      case 'getInfo':
        return {
          'name': name,
          'version': version,
          'activeStreams': _activeStreams,
          'availableSensors': [
            'accelerometer',
            'gyroscope',
            'magnetometer',
            'userAccelerometer',
          ],
        };
      default:
        throw UnsupportedError('Method "$method" not supported');
    }
  }

  Duration _parseInterval(Map<String, dynamic> args) {
    final ms = (args['intervalMs'] as num?)?.toInt() ?? 100;
    return Duration(milliseconds: ms.clamp(16, 5000));
  }

  // ── Accelerometer ──

  Map<String, dynamic> _startAccelerometer(Map<String, dynamic> args) {
    if (_activeStreams['accelerometer'] == true) {
      return {'started': true, 'alreadyStarted': true};
    }

    final interval = _parseInterval(args);

    _accelSub = accelerometerEventStream(
      samplingPeriod: interval,
    ).listen((event) {
      eventEmitter?.call('sensors.accelerometer', {
        'x': event.x,
        'y': event.y,
        'z': event.z,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
    });

    _activeStreams['accelerometer'] = true;
    return {'started': true, 'sensor': 'accelerometer'};
  }

  Map<String, dynamic> _stopAccelerometer() {
    _accelSub?.cancel();
    _accelSub = null;
    _activeStreams.remove('accelerometer');
    return {'stopped': true, 'sensor': 'accelerometer'};
  }

  // ── Gyroscope ──

  Map<String, dynamic> _startGyroscope(Map<String, dynamic> args) {
    if (_activeStreams['gyroscope'] == true) {
      return {'started': true, 'alreadyStarted': true};
    }

    final interval = _parseInterval(args);

    _gyroSub = gyroscopeEventStream(
      samplingPeriod: interval,
    ).listen((event) {
      eventEmitter?.call('sensors.gyroscope', {
        'x': event.x,
        'y': event.y,
        'z': event.z,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
    });

    _activeStreams['gyroscope'] = true;
    return {'started': true, 'sensor': 'gyroscope'};
  }

  Map<String, dynamic> _stopGyroscope() {
    _gyroSub?.cancel();
    _gyroSub = null;
    _activeStreams.remove('gyroscope');
    return {'stopped': true, 'sensor': 'gyroscope'};
  }

  // ── Magnetometer ──

  Map<String, dynamic> _startMagnetometer(Map<String, dynamic> args) {
    if (_activeStreams['magnetometer'] == true) {
      return {'started': true, 'alreadyStarted': true};
    }

    final interval = _parseInterval(args);

    _magnetSub = magnetometerEventStream(
      samplingPeriod: interval,
    ).listen((event) {
      eventEmitter?.call('sensors.magnetometer', {
        'x': event.x,
        'y': event.y,
        'z': event.z,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
    });

    _activeStreams['magnetometer'] = true;
    return {'started': true, 'sensor': 'magnetometer'};
  }

  Map<String, dynamic> _stopMagnetometer() {
    _magnetSub?.cancel();
    _magnetSub = null;
    _activeStreams.remove('magnetometer');
    return {'stopped': true, 'sensor': 'magnetometer'};
  }

  // ── User Accelerometer (without gravity) ──

  Map<String, dynamic> _startUserAccelerometer(Map<String, dynamic> args) {
    if (_activeStreams['userAccelerometer'] == true) {
      return {'started': true, 'alreadyStarted': true};
    }

    final interval = _parseInterval(args);

    _userAccelSub = userAccelerometerEventStream(
      samplingPeriod: interval,
    ).listen((event) {
      eventEmitter?.call('sensors.userAccelerometer', {
        'x': event.x,
        'y': event.y,
        'z': event.z,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
    });

    _activeStreams['userAccelerometer'] = true;
    return {'started': true, 'sensor': 'userAccelerometer'};
  }

  Map<String, dynamic> _stopUserAccelerometer() {
    _userAccelSub?.cancel();
    _userAccelSub = null;
    _activeStreams.remove('userAccelerometer');
    return {'stopped': true, 'sensor': 'userAccelerometer'};
  }

  // ── Stop All ──

  Future<void> _cancelAll() async {
    _accelSub?.cancel();
    _gyroSub?.cancel();
    _magnetSub?.cancel();
    _userAccelSub?.cancel();
    _accelSub = null;
    _gyroSub = null;
    _magnetSub = null;
    _userAccelSub = null;
    _activeStreams.clear();
  }

  Map<String, dynamic> _stopAll() {
    final count = _activeStreams.length;
    _cancelAll();
    return {'stopped': count};
  }
}
```

## 📄 `lib/plugins/sensors/pubspec.yaml`

```yaml
name: sensors_plugin
description: Device sensors plugin
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
  sensors_plus: ^5.0.1
```

---

# پلاگین ۴: Screen Brightness

## 📄 `lib/plugins/screen_brightness/lib/screen_brightness_plugin.dart`

```dart
import 'package:screen_brightness/screen_brightness.dart';
import 'package:sweetmelon/packages/core/lib/core.dart';
import 'package:sweetmelon/packages/plugin_engine/lib/plugin_engine.dart';

class ScreenBrightnessPlugin extends Plugin {
  @override
  String get name => 'screenBrightness';

  @override
  String get version => '1.0.0';

  @override
  String get description => 'Control device screen brightness';

  @override
  List<String> get supportedMethods => [
        'get',
        'set',
        'reset',
        'getSystem',
        'setAutoReset',
        'getInfo',
      ];

  @override
  Future<dynamic> onCall(String method, Map<String, dynamic> args) async {
    switch (method) {
      case 'get':
        return _getBrightness();
      case 'set':
        return _setBrightness(args);
      case 'reset':
        return _resetBrightness();
      case 'getSystem':
        return _getSystemBrightness();
      case 'setAutoReset':
        return _setAutoReset(args);
      case 'getInfo':
        return {'name': name, 'version': version};
      default:
        throw UnsupportedError('Method "$method" not supported');
    }
  }

  Future<Map<String, dynamic>> _getBrightness() async {
    try {
      final brightness = await ScreenBrightness().current;
      return {'brightness': brightness};
    } catch (e) {
      return {'brightness': -1, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> _setBrightness(Map<String, dynamic> args) async {
    final value = (args['brightness'] as num).toDouble().clamp(0.0, 1.0);

    try {
      await ScreenBrightness().setScreenBrightness(value);
      BridgeLogger.info('ScreenBrightness', 'Set to: $value');
      return {'brightness': value, 'set': true};
    } catch (e) {
      return {'set': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> _resetBrightness() async {
    try {
      await ScreenBrightness().resetScreenBrightness();
      return {'reset': true};
    } catch (e) {
      return {'reset': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> _getSystemBrightness() async {
    try {
      final brightness = await ScreenBrightness().system;
      return {'brightness': brightness};
    } catch (e) {
      return {'brightness': -1, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> _setAutoReset(Map<String, dynamic> args) async {
    final enabled = args['enabled'] as bool? ?? true;
    try {
      await ScreenBrightness().setAutoReset(enabled);
      return {'autoReset': enabled};
    } catch (e) {
      return {'autoReset': false, 'error': e.toString()};
    }
  }

  @override
  Future<ValidationResult> validateArgs(
    String method,
    Map<String, dynamic> args,
  ) async {
    if (method == 'set') {
      final b = args['brightness'];
      if (b is! num) {
        return ValidationResult.invalid('brightness (0.0-1.0) is required');
      }
    }
    return ValidationResult.valid();
  }
}
```

## 📄 `lib/plugins/screen_brightness/pubspec.yaml`

```yaml
name: screen_brightness_plugin
description: Screen brightness control plugin
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
  screen_brightness: ^1.0.1
```

---

# پلاگین ۵: Flashlight / Torch

## 📄 `lib/plugins/flashlight/lib/flashlight_plugin.dart`

```dart
import 'package:sweetmelon/packages/core/lib/core.dart';
import 'package:sweetmelon/packages/plugin_engine/lib/plugin_engine.dart';
import 'package:torch_light/torch_light.dart';

class FlashlightPlugin extends Plugin {
  bool _isOn = false;

  @override
  String get name => 'flashlight';

  @override
  String get version => '1.0.0';

  @override
  String get description => 'Flashlight / torch control plugin';

  @override
  List<String> get supportedMethods => [
        'enable',
        'disable',
        'toggle',
        'isAvailable',
        'isEnabled',
        'getInfo',
      ];

  @override
  Future<dynamic> onCall(String method, Map<String, dynamic> args) async {
    switch (method) {
      case 'enable':
        return _enable();
      case 'disable':
        return _disable();
      case 'toggle':
        return _isOn ? _disable() : _enable();
      case 'isAvailable':
        return _isAvailable();
      case 'isEnabled':
        return {'enabled': _isOn};
      case 'getInfo':
        return {
          'name': name,
          'version': version,
          'enabled': _isOn,
        };
      default:
        throw UnsupportedError('Method "$method" not supported');
    }
  }

  Future<Map<String, dynamic>> _enable() async {
    try {
      await TorchLight.enableTorch();
      _isOn = true;
      return {'enabled': true};
    } catch (e) {
      BridgeLogger.error('Flashlight', 'Enable failed: $e');
      return {'enabled': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> _disable() async {
    try {
      await TorchLight.disableTorch();
      _isOn = false;
      return {'enabled': false};
    } catch (e) {
      BridgeLogger.error('Flashlight', 'Disable failed: $e');
      return {'enabled': _isOn, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> _isAvailable() async {
    try {
      final available = await TorchLight.isTorchAvailable();
      return {'available': available};
    } catch (e) {
      return {'available': false, 'error': e.toString()};
    }
  }

  @override
  Future<void> onDispose() async {
    if (_isOn) {
      try {
        await TorchLight.disableTorch();
      } catch (_) {}
      _isOn = false;
    }
  }
}
```

## 📄 `lib/plugins/flashlight/pubspec.yaml`

```yaml
name: flashlight_plugin
description: Flashlight / torch plugin
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
  torch_light: ^1.0.0
```

---

# پلاگین ۶: Navigation Bar

## 📄 `lib/plugins/navigation_bar/lib/navigation_bar_plugin.dart`

```dart
import 'package:flutter/services.dart';
import 'package:sweetmelon/packages/plugin_engine/lib/plugin_engine.dart';

class NavigationBarPlugin extends Plugin {
  @override
  String get name => 'navigationBar';

  @override
  String get version => '1.0.0';

  @override
  String get description => 'Android navigation bar color and visibility control';

  @override
  List<String> get supportedMethods => [
        'setColor',
        'setStyle',
        'show',
        'hide',
        'setTransparent',
        'getInfo',
      ];

  @override
  Future<dynamic> onCall(String method, Map<String, dynamic> args) async {
    switch (method) {
      case 'setColor':
        return _setColor(args);
      case 'setStyle':
        return _setStyle(args);
      case 'show':
        return _show();
      case 'hide':
        return _hide();
      case 'setTransparent':
        return _setTransparent();
      case 'getInfo':
        return {'name': name, 'version': version};
      default:
        throw UnsupportedError('Method "$method" not supported');
    }
  }

  Map<String, dynamic> _setColor(Map<String, dynamic> args) {
    final colorStr = args['color'] as String;
    final color = _parseColor(colorStr);
    final darkIcons = args['darkIcons'] as bool? ?? false;

    if (color == null) {
      return {'set': false, 'reason': 'invalid_color'};
    }

    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        systemNavigationBarColor: color,
        systemNavigationBarIconBrightness:
            darkIcons ? Brightness.dark : Brightness.light,
      ),
    );

    return {'set': true, 'color': colorStr};
  }

  Map<String, dynamic> _setStyle(Map<String, dynamic> args) {
    final style = args['style'] as String? ?? 'default';

    Brightness iconBrightness;
    Color? bgColor;

    switch (style) {
      case 'light':
        iconBrightness = Brightness.light;
        bgColor = const Color(0xFF000000);
        break;
      case 'dark':
        iconBrightness = Brightness.dark;
        bgColor = const Color(0xFFFFFFFF);
        break;
      default:
        iconBrightness = Brightness.light;
        bgColor = null;
    }

    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        systemNavigationBarColor: bgColor,
        systemNavigationBarIconBrightness: iconBrightness,
      ),
    );

    return {'set': true, 'style': style};
  }

  Map<String, dynamic> _show() {
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
    return {'visible': true};
  }

  Map<String, dynamic> _hide() {
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: [SystemUiOverlay.top],
    );
    return {'visible': false};
  }

  Map<String, dynamic> _setTransparent() {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        systemNavigationBarColor: Color(0x00000000),
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );
    return {'transparent': true};
  }

  Color? _parseColor(String? value) {
    if (value == null) return null;
    var hex = value.replaceAll('#', '').trim();
    if (hex.length == 6) hex = 'FF$hex';
    if (hex.length == 8) {
      final v = int.tryParse(hex, radix: 16);
      if (v != null) return Color(v);
    }
    return null;
  }

  @override
  Future<ValidationResult> validateArgs(
    String method,
    Map<String, dynamic> args,
  ) async {
    if (method == 'setColor') {
      final color = args['color'];
      if (color is! String || color.isEmpty) {
        return ValidationResult.invalid('color (#RRGGBB) is required');
      }
    }
    return ValidationResult.valid();
  }
}
```

## 📄 `lib/plugins/navigation_bar/pubspec.yaml`

```yaml
name: navigation_bar_plugin
description: Android navigation bar plugin
version: 1.0.0

environment:
  sdk: ^3.0.0

dependencies:
  flutter:
    sdk: flutter
  plugin_engine:
    path: ../../packages/plugin_engine
```

---

# پلاگین ۷: Privacy Screen

## 📄 `lib/plugins/privacy_screen/lib/privacy_screen_plugin.dart`

```dart
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:sweetmelon/packages/core/lib/core.dart';
import 'package:sweetmelon/packages/plugin_engine/lib/plugin_engine.dart';

class PrivacyScreenPlugin extends Plugin {
  bool _enabled = false;
  static const _channel = MethodChannel('sweetmelon/privacy_screen');

  @override
  String get name => 'privacyScreen';

  @override
  String get version => '1.0.0';

  @override
  String get description =>
      'Prevent screenshots and hide content in app switcher';

  @override
  List<String> get supportedMethods => [
        'enable',
        'disable',
        'isEnabled',
        'getInfo',
      ];

  @override
  Future<dynamic> onCall(String method, Map<String, dynamic> args) async {
    switch (method) {
      case 'enable':
        return _enable();
      case 'disable':
        return _disable();
      case 'isEnabled':
        return {'enabled': _enabled};
      case 'getInfo':
        return {
          'name': name,
          'version': version,
          'enabled': _enabled,
          'platform': Platform.operatingSystem,
        };
      default:
        throw UnsupportedError('Method "$method" not supported');
    }
  }

  Future<Map<String, dynamic>> _enable() async {
    if (_enabled) {
      return {'enabled': true, 'alreadyEnabled': true};
    }

    try {
      // Android: FLAG_SECURE
      if (Platform.isAndroid) {
        await _channel.invokeMethod('enablePrivacy');
      }

      _enabled = true;
      BridgeLogger.info('PrivacyScreen', 'Privacy screen enabled');

      return {'enabled': true, 'alreadyEnabled': false};
    } catch (e) {
      BridgeLogger.error('PrivacyScreen', 'Enable failed: $e');
      return {'enabled': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> _disable() async {
    if (!_enabled) {
      return {'enabled': false, 'alreadyDisabled': true};
    }

    try {
      if (Platform.isAndroid) {
        await _channel.invokeMethod('disablePrivacy');
      }

      _enabled = false;
      BridgeLogger.info('PrivacyScreen', 'Privacy screen disabled');

      return {'enabled': false, 'alreadyDisabled': false};
    } catch (e) {
      BridgeLogger.error('PrivacyScreen', 'Disable failed: $e');
      return {'enabled': _enabled, 'error': e.toString()};
    }
  }

  @override
  Future<void> onDispose() async {
    if (_enabled) {
      await _disable();
    }
  }
}
```

## 📄 `android/app/src/main/kotlin/com/example/sweet_melon/MainActivity.kt`

```kt
package com.example.sweet_melon

import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val PRIVACY_CHANNEL = "sweetmelon/privacy_screen"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            PRIVACY_CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "enablePrivacy" -> {
                    window.setFlags(
                        WindowManager.LayoutParams.FLAG_SECURE,
                        WindowManager.LayoutParams.FLAG_SECURE
                    )
                    result.success(true)
                }
                "disablePrivacy" -> {
                    window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }
}
```

## 📄 `lib/plugins/privacy_screen/pubspec.yaml`

```yaml
name: privacy_screen_plugin
description: Privacy screen protection plugin
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

# پلاگین ۸: Native Settings

## 📄 `lib/plugins/native_settings/lib/native_settings_plugin.dart`

```dart
import 'dart:io';

import 'package:url_launcher/url_launcher.dart';
import 'package:sweetmelon/packages/core/lib/core.dart';
import 'package:sweetmelon/packages/plugin_engine/lib/plugin_engine.dart';

class NativeSettingsPlugin extends Plugin {
  @override
  String get name => 'nativeSettings';

  @override
  String get version => '1.0.0';

  @override
  String get description => 'Open native system settings screens';

  @override
  List<String> get supportedMethods => [
        'open',
        'openApp',
        'openWifi',
        'openBluetooth',
        'openLocation',
        'openNotification',
        'openBattery',
        'openDisplay',
        'openSound',
        'openSecurity',
        'openDate',
        'openAccessibility',
        'openStorage',
        'openDeveloper',
        'openAbout',
        'getAvailableSettings',
        'getInfo',
      ];

  static const Map<String, String> _androidSettingsMap = {
    'app': 'android.settings.APPLICATION_DETAILS_SETTINGS',
    'wifi': 'android.settings.WIFI_SETTINGS',
    'bluetooth': 'android.settings.BLUETOOTH_SETTINGS',
    'location': 'android.settings.LOCATION_SOURCE_SETTINGS',
    'notification': 'android.settings.APP_NOTIFICATION_SETTINGS',
    'battery': 'android.settings.BATTERY_SAVER_SETTINGS',
    'display': 'android.settings.DISPLAY_SETTINGS',
    'sound': 'android.settings.SOUND_SETTINGS',
    'security': 'android.settings.SECURITY_SETTINGS',
    'date': 'android.settings.DATE_SETTINGS',
    'accessibility': 'android.settings.ACCESSIBILITY_SETTINGS',
    'storage': 'android.settings.INTERNAL_STORAGE_SETTINGS',
    'developer': 'android.settings.APPLICATION_DEVELOPMENT_SETTINGS',
    'about': 'android.settings.DEVICE_INFO_SETTINGS',
    'nfc': 'android.settings.NFC_SETTINGS',
    'airplane': 'android.settings.AIRPLANE_MODE_SETTINGS',
    'apn': 'android.settings.APN_SETTINGS',
    'data_usage': 'android.settings.DATA_USAGE_SETTINGS',
    'vpn': 'android.settings.VPN_SETTINGS',
    'input_method': 'android.settings.INPUT_METHOD_SETTINGS',
    'locale': 'android.settings.LOCALE_SETTINGS',
    'privacy': 'android.settings.PRIVACY_SETTINGS',
    'biometric': 'android.settings.BIOMETRIC_ENROLL',
    'default_apps': 'android.settings.MANAGE_DEFAULT_APPS_SETTINGS',
  };

  @override
  Future<dynamic> onCall(String method, Map<String, dynamic> args) async {
    switch (method) {
      case 'open':
        return _openSetting(args['setting'] as String);
      case 'openApp':
        return _openSetting('app');
      case 'openWifi':
        return _openSetting('wifi');
      case 'openBluetooth':
        return _openSetting('bluetooth');
      case 'openLocation':
        return _openSetting('location');
      case 'openNotification':
        return _openSetting('notification');
      case 'openBattery':
        return _openSetting('battery');
      case 'openDisplay':
        return _openSetting('display');
      case 'openSound':
        return _openSetting('sound');
      case 'openSecurity':
        return _openSetting('security');
      case 'openDate':
        return _openSetting('date');
      case 'openAccessibility':
        return _openSetting('accessibility');
      case 'openStorage':
        return _openSetting('storage');
      case 'openDeveloper':
        return _openSetting('developer');
      case 'openAbout':
        return _openSetting('about');
      case 'getAvailableSettings':
        return {'settings': _androidSettingsMap.keys.toList()};
      case 'getInfo':
        return {
          'name': name,
          'version': version,
          'platform': Platform.operatingSystem,
          'availableSettings': _androidSettingsMap.keys.toList(),
        };
      default:
        throw UnsupportedError('Method "$method" not supported');
    }
  }

  Future<Map<String, dynamic>> _openSetting(String setting) async {
    if (!Platform.isAndroid) {
      return {'opened': false, 'reason': 'android_only'};
    }

    final action = _androidSettingsMap[setting];
    if (action == null) {
      return {
        'opened': false,
        'reason': 'unknown_setting',
        'setting': setting,
        'availableSettings': _androidSettingsMap.keys.toList(),
      };
    }

    try {
      final uri = Uri.parse('android.intent.action.VIEW');
      // استفاده از intent
      final intent = Uri.parse(
        'intent://#Intent;action=$action;end',
      );

      final launched = await launchUrl(
        intent,
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        // fallback: باز کردن تنظیمات عمومی
        await launchUrl(
          Uri.parse('app-settings:'),
          mode: LaunchMode.externalApplication,
        );
      }

      BridgeLogger.info('NativeSettings', 'Opened: $setting');

      return {'opened': true, 'setting': setting};
    } catch (e) {
      BridgeLogger.error('NativeSettings', 'Open failed: $e');

      // Fallback: باز کردن تنظیمات اپ
      try {
        await launchUrl(
          Uri.parse('app-settings:'),
          mode: LaunchMode.externalApplication,
        );
        return {'opened': true, 'setting': 'app', 'fallback': true};
      } catch (_) {}

      return {'opened': false, 'error': e.toString()};
    }
  }

  @override
  Future<ValidationResult> validateArgs(
    String method,
    Map<String, dynamic> args,
  ) async {
    if (method == 'open') {
      final setting = args['setting'];
      if (setting is! String || setting.isEmpty) {
        return ValidationResult.invalid('setting name is required');
      }
    }
    return ValidationResult.valid();
  }
}
```

## 📄 `lib/plugins/native_settings/pubspec.yaml`

```yaml
name: native_settings_plugin
description: Open native system settings
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
  url_launcher: ^6.3.0
```

---

# بروزرسانی pubspec.yaml اصلی

> اضافه شدن dependency‌های جدید:

```yaml
  # فاز ۸
  file_picker: ^8.0.0+1
  sensors_plus: ^5.0.1
  screen_brightness: ^1.0.1
  torch_light: ^1.0.0
```

---

# ثبت پلاگین‌ها

> اضافه به Service Locator — imports:

```dart
import 'package:sweetmelon/plugins/file_picker/lib/file_picker_plugin.dart';
import 'package:sweetmelon/plugins/file_opener/lib/file_opener_plugin.dart';
import 'package:sweetmelon/plugins/sensors/lib/sensors_plugin.dart';
import 'package:sweetmelon/plugins/screen_brightness/lib/screen_brightness_plugin.dart';
import 'package:sweetmelon/plugins/flashlight/lib/flashlight_plugin.dart';
import 'package:sweetmelon/plugins/navigation_bar/lib/navigation_bar_plugin.dart';
import 'package:sweetmelon/plugins/privacy_screen/lib/privacy_screen_plugin.dart';
import 'package:sweetmelon/plugins/native_settings/lib/native_settings_plugin.dart';
```

> اضافه به `_registerEagerPlugins()`:

```dart
    await registry.register(FilePickerPlugin());
    await registry.register(FileOpenerPlugin());
    await registry.register(NavigationBarPlugin());
    await registry.register(PrivacyScreenPlugin());
    await registry.register(NativeSettingsPlugin());
```

> اضافه به lazy plugins:

```dart
      LazyPluginDefinition(
        id: 'sensors',
        version: '1.0.0',
        factory: () => SensorsPlugin(eventEmitter: emitter),
      ),
      LazyPluginDefinition(
        id: 'screenBrightness',
        version: '1.0.0',
        factory: () => ScreenBrightnessPlugin(),
      ),
      LazyPluginDefinition(
        id: 'flashlight',
        version: '1.0.0',
        factory: () => FlashlightPlugin(),
      ),
```

---

# NativeSDK — فاز ۸

> اضافه شدن به `native-sdk.js`:

```javascript
    filePicker: {
      pickFiles: function (o) { return call('filePicker', 'pickFiles', o || {}); },
      pickImages: function (o) { return call('filePicker', 'pickImages', o || {}); },
      pickVideos: function (o) { return call('filePicker', 'pickVideos', o || {}); },
      pickMedia: function (o) { return call('filePicker', 'pickMedia', o || {}); },
      pickDirectory: function () { return call('filePicker', 'pickDirectory', {}); },
      getInfo: function () { return call('filePicker', 'getInfo', {}); }
    },

    fileOpener: {
      open: function (path, mimeType) { return call('fileOpener', 'open', { path: path, mimeType: mimeType }); },
      canOpen: function (path) { return call('fileOpener', 'canOpen', { path: path }); },
      getMimeType: function (path) { return call('fileOpener', 'getMimeType', { path: path }); },
      getInfo: function () { return call('fileOpener', 'getInfo', {}); }
    },

    sensors: {
      startAccelerometer: function (o) { return call('sensors', 'startAccelerometer', o || {}); },
      stopAccelerometer: function () { return call('sensors', 'stopAccelerometer', {}); },
      startGyroscope: function (o) { return call('sensors', 'startGyroscope', o || {}); },
      stopGyroscope: function () { return call('sensors', 'stopGyroscope', {}); },
      startMagnetometer: function (o) { return call('sensors', 'startMagnetometer', o || {}); },
      stopMagnetometer: function () { return call('sensors', 'stopMagnetometer', {}); },
      startUserAccelerometer: function (o) { return call('sensors', 'startUserAccelerometer', o || {}); },
      stopUserAccelerometer: function () { return call('sensors', 'stopUserAccelerometer', {}); },
      stopAll: function () { return call('sensors', 'stopAll', {}); },
      getActiveStreams: function () { return call('sensors', 'getActiveStreams', {}); },
      getInfo: function () { return call('sensors', 'getInfo', {}); }
    },

    screenBrightness: {
      get: function () { return call('screenBrightness', 'get', {}); },
      set: function (brightness) { return call('screenBrightness', 'set', { brightness: brightness }); },
      reset: function () { return call('screenBrightness', 'reset', {}); },
      getSystem: function () { return call('screenBrightness', 'getSystem', {}); },
      setAutoReset: function (enabled) { return call('screenBrightness', 'setAutoReset', { enabled: enabled }); },
      getInfo: function () { return call('screenBrightness', 'getInfo', {}); }
    },

    flashlight: {
      enable: function () { return call('flashlight', 'enable', {}); },
      disable: function () { return call('flashlight', 'disable', {}); },
      toggle: function () { return call('flashlight', 'toggle', {}); },
      isAvailable: function () { return call('flashlight', 'isAvailable', {}); },
      isEnabled: function () { return call('flashlight', 'isEnabled', {}); },
      getInfo: function () { return call('flashlight', 'getInfo', {}); }
    },

    navigationBar: {
      setColor: function (color, darkIcons) { return call('navigationBar', 'setColor', { color: color, darkIcons: darkIcons || false }); },
      setStyle: function (style) { return call('navigationBar', 'setStyle', { style: style }); },
      show: function () { return call('navigationBar', 'show', {}); },
      hide: function () { return call('navigationBar', 'hide', {}); },
      setTransparent: function () { return call('navigationBar', 'setTransparent', {}); },
      getInfo: function () { return call('navigationBar', 'getInfo', {}); }
    },

    privacyScreen: {
      enable: function () { return call('privacyScreen', 'enable', {}); },
      disable: function () { return call('privacyScreen', 'disable', {}); },
      isEnabled: function () { return call('privacyScreen', 'isEnabled', {}); },
      getInfo: function () { return call('privacyScreen', 'getInfo', {}); }
    },

    nativeSettings: {
      open: function (setting) { return call('nativeSettings', 'open', { setting: setting }); },
      openApp: function () { return call('nativeSettings', 'openApp', {}); },
      openWifi: function () { return call('nativeSettings', 'openWifi', {}); },
      openBluetooth: function () { return call('nativeSettings', 'openBluetooth', {}); },
      openLocation: function () { return call('nativeSettings', 'openLocation', {}); },
      openNotification: function () { return call('nativeSettings', 'openNotification', {}); },
      openBattery: function () { return call('nativeSettings', 'openBattery', {}); },
      openDisplay: function () { return call('nativeSettings', 'openDisplay', {}); },
      openSound: function () { return call('nativeSettings', 'openSound', {}); },
      openSecurity: function () { return call('nativeSettings', 'openSecurity', {}); },
      openDate: function () { return call('nativeSettings', 'openDate', {}); },
      openAccessibility: function () { return call('nativeSettings', 'openAccessibility', {}); },
      openStorage: function () { return call('nativeSettings', 'openStorage', {}); },
      openDeveloper: function () { return call('nativeSettings', 'openDeveloper', {}); },
      openAbout: function () { return call('nativeSettings', 'openAbout', {}); },
      getAvailableSettings: function () { return call('nativeSettings', 'getAvailableSettings', {}); },
      getInfo: function () { return call('nativeSettings', 'getInfo', {}); }
    },
```

---

# خلاصه فاز ۸

## پلاگین‌های جدید

| # | پلاگین | نام JS | متدها | Events |
|---|--------|--------|-------|--------|
| 46 | File Picker | `filePicker` | pickFiles, pickImages, pickVideos, pickMedia, pickDirectory | — |
| 47 | File Opener | `fileOpener` | open, canOpen, getMimeType | — |
| 48 | Sensors | `sensors` | start/stop Accelerometer, Gyroscope, Magnetometer, UserAccelerometer | sensors.accelerometer, sensors.gyroscope, sensors.magnetometer, sensors.userAccelerometer |
| 49 | Screen Brightness | `screenBrightness` | get, set, reset, getSystem, setAutoReset | — |
| 50 | Flashlight | `flashlight` | enable, disable, toggle, isAvailable | — |
| 51 | Navigation Bar | `navigationBar` | setColor, setStyle, show, hide, setTransparent | — |
| 52 | Privacy Screen | `privacyScreen` | enable, disable, isEnabled | — |
| 53 | Native Settings | `nativeSettings` | open (24 settings), openApp, openWifi, ... | — |

## مجموع کل: **53 پلاگین**

## نحوه استفاده JS

```javascript
// File Picker
const { files } = await NativeSDK.filePicker.pickFiles({
  multiple: true,
  type: 'any',
  allowedExtensions: ['pdf', 'doc', 'xlsx']
});

const images = await NativeSDK.filePicker.pickImages({ multiple: true });

// File Opener
await NativeSDK.fileOpener.open('/path/to/file.pdf');
const { mimeType } = NativeSDK.fileOpener.getMimeType('/path/to/file.pdf');

// Sensors
await NativeSDK.sensors.startAccelerometer({ intervalMs: 50 });
NativeSDK.on('sensors.accelerometer', (data) => {
  console.log('Accel:', data.x, data.y, data.z);
});

await NativeSDK.sensors.startGyroscope({ intervalMs: 100 });
NativeSDK.on('sensors.gyroscope', (data) => {
  updateRotation(data.x, data.y, data.z);
});

await NativeSDK.sensors.stopAll();

// Screen Brightness
const { brightness } = await NativeSDK.screenBrightness.get();
await NativeSDK.screenBrightness.set(0.8);
await NativeSDK.screenBrightness.reset();

// Flashlight
await NativeSDK.flashlight.enable();
await NativeSDK.flashlight.toggle();

// Navigation Bar
await NativeSDK.navigationBar.setColor('#1A1A2E');
await NativeSDK.navigationBar.hide();
await NativeSDK.navigationBar.setTransparent();

// Privacy Screen (بانکی/امنیتی)
await NativeSDK.privacyScreen.enable();  // block screenshots
await NativeSDK.privacyScreen.disable();

// Native Settings
await NativeSDK.nativeSettings.openWifi();
await NativeSDK.nativeSettings.openBluetooth();
await NativeSDK.nativeSettings.openNotification();
await NativeSDK.nativeSettings.open('battery');
await NativeSDK.nativeSettings.open('developer');

const { settings } = await NativeSDK.nativeSettings.getAvailableSettings();
// ['app', 'wifi', 'bluetooth', 'location', 'notification', ...]
```

---

بگو تا فاز ۹ رو هم شروع کنم.
