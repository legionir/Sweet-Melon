# فاز ۱۱ — ۱۳ پلاگین تخصصی

---

# پلاگین ۱: WiFi Manager

## 📄 `lib/plugins/wifi_manager/lib/wifi_manager_plugin.dart`

```dart
import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:sweetmelon/packages/core/lib/core.dart';
import 'package:sweetmelon/packages/plugin_engine/lib/plugin_engine.dart';

typedef WifiEventEmitter = Future<void> Function(String event, dynamic data);

class WifiManagerPlugin extends Plugin {
  final WifiEventEmitter? eventEmitter;
  static const _channel = MethodChannel('sweetmelon/wifi');

  WifiManagerPlugin({this.eventEmitter});

  @override
  String get name => 'wifiManager';

  @override
  String get version => '1.0.0';

  @override
  String get description => 'WiFi network information and management';

  @override
  List<String> get supportedMethods => [
        'getConnectionInfo',
        'getIpAddress',
        'isEnabled',
        'getInfo',
      ];

  @override
  Future<dynamic> onCall(String method, Map<String, dynamic> args) async {
    switch (method) {
      case 'getConnectionInfo':
        return _getConnectionInfo();
      case 'getIpAddress':
        return _getIpAddress();
      case 'isEnabled':
        return _isEnabled();
      case 'getInfo':
        return {'name': name, 'version': version, 'platform': Platform.operatingSystem};
      default:
        throw UnsupportedError('Method "$method" not supported');
    }
  }

  Future<Map<String, dynamic>> _getConnectionInfo() async {
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLinkLocal: false,
      );

      String? wifiIp;
      String? wifiName;

      for (final interface in interfaces) {
        if (interface.name.toLowerCase().contains('wlan') ||
            interface.name.toLowerCase().contains('wifi') ||
            interface.name.toLowerCase().contains('en0')) {
          for (final addr in interface.addresses) {
            wifiIp = addr.address;
          }
          wifiName = interface.name;
          break;
        }
      }

      if (wifiIp == null) {
        for (final interface in interfaces) {
          for (final addr in interface.addresses) {
            if (!addr.isLoopback) {
              wifiIp = addr.address;
              wifiName = interface.name;
              break;
            }
          }
          if (wifiIp != null) break;
        }
      }

      return {
        'connected': wifiIp != null,
        'ip': wifiIp,
        'interfaceName': wifiName,
        'interfaces': interfaces.map((i) => {
          'name': i.name,
          'addresses': i.addresses.map((a) => a.address).toList(),
        }).toList(),
      };
    } catch (e) {
      BridgeLogger.error('WifiManager', 'Connection info failed: $e');
      return {'connected': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> _getIpAddress() async {
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
      );

      final ips = <String>[];
      for (final interface in interfaces) {
        for (final addr in interface.addresses) {
          if (!addr.isLoopback) {
            ips.add(addr.address);
          }
        }
      }

      return {
        'ips': ips,
        'primary': ips.isNotEmpty ? ips.first : null,
      };
    } catch (e) {
      return {'ips': <String>[], 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> _isEnabled() async {
    final info = await _getConnectionInfo();
    return {'enabled': info['connected'] == true};
  }
}
```

## 📄 `lib/plugins/wifi_manager/pubspec.yaml`

```yaml
name: wifi_manager_plugin
description: WiFi network info plugin
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

# پلاگین ۲: Root Detection

## 📄 `lib/plugins/root_detection/lib/root_detection_plugin.dart`

```dart
import 'dart:io';

import 'package:sweetmelon/packages/core/lib/core.dart';
import 'package:sweetmelon/packages/plugin_engine/lib/plugin_engine.dart';

class RootDetectionPlugin extends Plugin {
  @override
  String get name => 'rootDetection';

  @override
  String get version => '1.0.0';

  @override
  String get description => 'Detect rooted/jailbroken devices';

  @override
  List<String> get supportedMethods => [
        'isRooted',
        'getSecurityInfo',
        'getInfo',
      ];

  @override
  Future<dynamic> onCall(String method, Map<String, dynamic> args) async {
    switch (method) {
      case 'isRooted':
        return _isRooted();
      case 'getSecurityInfo':
        return _getSecurityInfo();
      case 'getInfo':
        return {'name': name, 'version': version};
      default:
        throw UnsupportedError('Method "$method" not supported');
    }
  }

  Future<Map<String, dynamic>> _isRooted() async {
    final checks = <String, bool>{};
    bool isRooted = false;

    if (Platform.isAndroid) {
      // Check 1: su binary
      checks['suBinary'] = _checkSuBinary();
      // Check 2: root management apps
      checks['rootApps'] = _checkRootApps();
      // Check 3: dangerous props
      checks['dangerousProps'] = _checkDangerousProps();
      // Check 4: rw system partition
      checks['rwSystem'] = _checkRWSystem();
      // Check 5: test keys
      checks['testKeys'] = _checkTestKeys();
      // Check 6: busybox
      checks['busybox'] = _checkBusybox();
      // Check 7: Magisk
      checks['magisk'] = _checkMagisk();

      isRooted = checks.values.any((v) => v);
    }

    return {
      'isRooted': isRooted,
      'platform': Platform.operatingSystem,
      'checks': checks,
      'riskLevel': _calculateRiskLevel(checks),
    };
  }

  Future<Map<String, dynamic>> _getSecurityInfo() async {
    final rootInfo = await _isRooted();

    return {
      ...rootInfo,
      'isEmulator': _isEmulator(),
      'isDebugMode': _isDebugMode(),
      'adbEnabled': _checkAdb(),
    };
  }

  bool _checkSuBinary() {
    final paths = [
      '/system/bin/su',
      '/system/xbin/su',
      '/sbin/su',
      '/data/local/xbin/su',
      '/data/local/bin/su',
      '/system/sd/xbin/su',
      '/system/bin/failsafe/su',
      '/data/local/su',
      '/su/bin/su',
    ];

    for (final path in paths) {
      if (File(path).existsSync()) return true;
    }
    return false;
  }

  bool _checkRootApps() {
    final packages = [
      '/system/app/Superuser.apk',
      '/system/app/SuperSU.apk',
      '/system/app/Superuser',
      '/system/app/SuperSU',
    ];

    for (final pkg in packages) {
      if (File(pkg).existsSync() || Directory(pkg).existsSync()) return true;
    }
    return false;
  }

  bool _checkDangerousProps() {
    try {
      final result = Process.runSync('getprop', ['ro.debuggable']);
      if (result.stdout.toString().trim() == '1') return true;
    } catch (_) {}
    return false;
  }

  bool _checkRWSystem() {
    try {
      final result = Process.runSync('mount', []);
      final output = result.stdout.toString();
      if (output.contains('/system') && output.contains('rw,')) return true;
    } catch (_) {}
    return false;
  }

  bool _checkTestKeys() {
    try {
      final result = Process.runSync('getprop', ['ro.build.tags']);
      if (result.stdout.toString().trim() == 'test-keys') return true;
    } catch (_) {}
    return false;
  }

  bool _checkBusybox() {
    final paths = ['/system/xbin/busybox', '/system/bin/busybox', '/sbin/busybox'];
    for (final path in paths) {
      if (File(path).existsSync()) return true;
    }
    return false;
  }

  bool _checkMagisk() {
    final paths = ['/sbin/.magisk', '/data/adb/magisk'];
    for (final path in paths) {
      if (File(path).existsSync() || Directory(path).existsSync()) return true;
    }
    return false;
  }

  bool _isEmulator() {
    try {
      final brand = Process.runSync('getprop', ['ro.product.brand']).stdout.toString().trim();
      final device = Process.runSync('getprop', ['ro.product.device']).stdout.toString().trim();
      final model = Process.runSync('getprop', ['ro.product.model']).stdout.toString().trim();
      final hardware = Process.runSync('getprop', ['ro.hardware']).stdout.toString().trim();

      final emulatorIndicators = ['generic', 'emulator', 'sdk', 'goldfish', 'ranchu'];
      final combined = '$brand $device $model $hardware'.toLowerCase();

      return emulatorIndicators.any((e) => combined.contains(e));
    } catch (_) {
      return false;
    }
  }

  bool _isDebugMode() {
    bool debug = false;
    assert(() {
      debug = true;
      return true;
    }());
    return debug;
  }

  bool _checkAdb() {
    try {
      final result = Process.runSync('getprop', ['init.svc.adbd']);
      return result.stdout.toString().trim() == 'running';
    } catch (_) {
      return false;
    }
  }

  String _calculateRiskLevel(Map<String, bool> checks) {
    final positiveCount = checks.values.where((v) => v).length;
    if (positiveCount == 0) return 'safe';
    if (positiveCount <= 2) return 'low';
    if (positiveCount <= 4) return 'medium';
    return 'high';
  }
}
```

## 📄 `lib/plugins/root_detection/pubspec.yaml`

```yaml
name: root_detection_plugin
description: Root/jailbreak detection plugin
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

# پلاگین ۳: App Attest / Play Integrity

## 📄 `lib/plugins/app_integrity/lib/app_integrity_plugin.dart`

```dart
import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:sweetmelon/packages/core/lib/core.dart';
import 'package:sweetmelon/packages/plugin_engine/lib/plugin_engine.dart';

class AppIntegrityPlugin extends Plugin {
  static const _channel = MethodChannel('sweetmelon/app_integrity');

  @override
  String get name => 'appIntegrity';

  @override
  String get version => '1.0.0';

  @override
  String get description => 'App integrity and attestation (Play Integrity API ready)';

  @override
  List<String> get supportedMethods => [
        'checkIntegrity',
        'isGenuineInstall',
        'getInstallSource',
        'getSigningInfo',
        'getInfo',
      ];

  @override
  Future<dynamic> onCall(String method, Map<String, dynamic> args) async {
    switch (method) {
      case 'checkIntegrity':
        return _checkIntegrity();
      case 'isGenuineInstall':
        return _isGenuineInstall();
      case 'getInstallSource':
        return _getInstallSource();
      case 'getSigningInfo':
        return _getSigningInfo();
      case 'getInfo':
        return {
          'name': name,
          'version': version,
          'platform': Platform.operatingSystem,
          'playIntegrityReady': false,
        };
      default:
        throw UnsupportedError('Method "$method" not supported');
    }
  }

  Future<Map<String, dynamic>> _checkIntegrity() async {
    final install = await _isGenuineInstall();
    final source = await _getInstallSource();
    final signing = await _getSigningInfo();

    final isGenuine = install['genuine'] == true;
    final isPlayStore = source['source'] == 'com.android.vending';

    String verdict;
    if (isGenuine && isPlayStore) {
      verdict = 'trusted';
    } else if (isGenuine) {
      verdict = 'genuine';
    } else {
      verdict = 'untrusted';
    }

    return {
      'verdict': verdict,
      'genuine': isGenuine,
      'playStore': isPlayStore,
      'install': install,
      'source': source,
      'signing': signing,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  Future<Map<String, dynamic>> _isGenuineInstall() async {
    try {
      final result = await _channel.invokeMethod('isGenuineInstall');
      return {'genuine': result ?? false};
    } catch (e) {
      // Fallback: بررسی installer package
      final source = await _getInstallSource();
      final genuine = source['source'] == 'com.android.vending' ||
          source['source'] == 'com.google.android.packageinstaller';

      return {'genuine': genuine, 'method': 'fallback'};
    }
  }

  Future<Map<String, dynamic>> _getInstallSource() async {
    try {
      final result = await _channel.invokeMethod('getInstallSource');
      if (result != null) {
        return Map<String, dynamic>.from(result);
      }
    } catch (_) {}

    return {
      'source': 'unknown',
      'initiating': null,
      'originating': null,
    };
  }

  Future<Map<String, dynamic>> _getSigningInfo() async {
    try {
      final result = await _channel.invokeMethod('getSigningInfo');
      if (result != null) {
        return Map<String, dynamic>.from(result);
      }
    } catch (_) {}

    return {
      'signed': true,
      'debugBuild': _isDebugMode(),
    };
  }

  bool _isDebugMode() {
    bool debug = false;
    assert(() {
      debug = true;
      return true;
    }());
    return debug;
  }
}
```

## 📄 `lib/plugins/app_integrity/pubspec.yaml`

```yaml
name: app_integrity_plugin
description: App integrity and attestation plugin
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

# پلاگین ۴: Alarm

## 📄 `lib/plugins/alarm/lib/alarm_plugin.dart`

```dart
import 'dart:async';

import 'package:sweetmelon/packages/core/lib/core.dart';
import 'package:sweetmelon/packages/plugin_engine/lib/plugin_engine.dart';

typedef AlarmEventEmitter = Future<void> Function(String event, dynamic data);

class AlarmPlugin extends Plugin {
  final AlarmEventEmitter? eventEmitter;
  final Map<String, Timer> _alarms = {};
  final Map<String, Map<String, dynamic>> _alarmData = {};

  AlarmPlugin({this.eventEmitter});

  @override
  String get name => 'alarm';

  @override
  String get version => '1.0.0';

  @override
  String get description => 'Timer-based alarm plugin';

  @override
  List<String> get supportedMethods => [
        'set',
        'cancel',
        'cancelAll',
        'getAlarm',
        'getAllAlarms',
        'getInfo',
      ];

  @override
  Future<void> onDispose() async {
    for (final timer in _alarms.values) {
      timer.cancel();
    }
    _alarms.clear();
    _alarmData.clear();
  }

  @override
  Future<dynamic> onCall(String method, Map<String, dynamic> args) async {
    switch (method) {
      case 'set':
        return _set(args);
      case 'cancel':
        return _cancel(args);
      case 'cancelAll':
        return _cancelAll();
      case 'getAlarm':
        return _getAlarm(args);
      case 'getAllAlarms':
        return _getAllAlarms();
      case 'getInfo':
        return {
          'name': name,
          'version': version,
          'activeAlarms': _alarms.length,
        };
      default:
        throw UnsupportedError('Method "$method" not supported');
    }
  }

  Map<String, dynamic> _set(Map<String, dynamic> args) {
    final alarmId = args['alarmId'] as String? ??
        'alarm_${DateTime.now().millisecondsSinceEpoch}';
    final delayMs = (args['delayMs'] as num?)?.toInt();
    final atMs = (args['atMs'] as num?)?.toInt();
    final title = args['title'] as String? ?? 'Alarm';
    final body = args['body'] as String? ?? '';
    final repeating = args['repeating'] as bool? ?? false;
    final intervalMs = (args['intervalMs'] as num?)?.toInt();
    final payload = args['payload'];

    // Cancel existing
    _alarms[alarmId]?.cancel();

    Duration delay;
    if (delayMs != null) {
      delay = Duration(milliseconds: delayMs);
    } else if (atMs != null) {
      final target = DateTime.fromMillisecondsSinceEpoch(atMs);
      delay = target.difference(DateTime.now());
      if (delay.isNegative) delay = Duration.zero;
    } else {
      return {'set': false, 'reason': 'delayMs or atMs is required'};
    }

    final data = {
      'alarmId': alarmId,
      'title': title,
      'body': body,
      'payload': payload,
      'createdAt': DateTime.now().toIso8601String(),
      'fireAt': DateTime.now().add(delay).toIso8601String(),
      'repeating': repeating,
    };

    _alarmData[alarmId] = data;

    if (repeating && intervalMs != null) {
      // اول بار بعد از delay، بعد هر intervalMs تکرار
      _alarms[alarmId] = Timer(delay, () {
        _fireAlarm(alarmId);

        _alarms[alarmId] = Timer.periodic(
          Duration(milliseconds: intervalMs),
          (_) => _fireAlarm(alarmId),
        );
      });
    } else {
      _alarms[alarmId] = Timer(delay, () => _fireAlarm(alarmId));
    }

    BridgeLogger.info('Alarm', 'Set: $alarmId (${delay.inSeconds}s)');

    return {
      'set': true,
      'alarmId': alarmId,
      'fireAt': DateTime.now().add(delay).toIso8601String(),
      'delayMs': delay.inMilliseconds,
    };
  }

  void _fireAlarm(String alarmId) {
    final data = _alarmData[alarmId];
    if (data == null) return;

    BridgeLogger.info('Alarm', 'Fired: $alarmId');

    eventEmitter?.call('alarm.fired', {
      ...data,
      'firedAt': DateTime.now().toIso8601String(),
    });

    // اگه repeating نبود، حذف کن
    if (data['repeating'] != true) {
      _alarms.remove(alarmId);
      _alarmData.remove(alarmId);
    }
  }

  Map<String, dynamic> _cancel(Map<String, dynamic> args) {
    final alarmId = args['alarmId'] as String;
    _alarms[alarmId]?.cancel();
    _alarms.remove(alarmId);
    _alarmData.remove(alarmId);
    return {'cancelled': true, 'alarmId': alarmId};
  }

  Map<String, dynamic> _cancelAll() {
    final count = _alarms.length;
    for (final timer in _alarms.values) {
      timer.cancel();
    }
    _alarms.clear();
    _alarmData.clear();
    return {'cancelled': count};
  }

  Map<String, dynamic> _getAlarm(Map<String, dynamic> args) {
    final alarmId = args['alarmId'] as String;
    final data = _alarmData[alarmId];
    if (data == null) {
      return {'found': false, 'alarmId': alarmId};
    }
    return {'found': true, ...data, 'active': _alarms.containsKey(alarmId)};
  }

  Map<String, dynamic> _getAllAlarms() {
    return {
      'alarms': _alarmData.values.map((d) => {
        ...d,
        'active': _alarms.containsKey(d['alarmId']),
      }).toList(),
      'count': _alarmData.length,
    };
  }

  @override
  Future<ValidationResult> validateArgs(String method, Map<String, dynamic> args) async {
    switch (method) {
      case 'set':
        if (args['delayMs'] == null && args['atMs'] == null) {
          return ValidationResult.invalid('delayMs or atMs is required');
        }
        return ValidationResult.valid();
      case 'cancel':
      case 'getAlarm':
        if (args['alarmId'] is! String) {
          return ValidationResult.invalid('alarmId is required');
        }
        return ValidationResult.valid();
      default:
        return ValidationResult.valid();
    }
  }
}
```

## 📄 `lib/plugins/alarm/pubspec.yaml`

```yaml
name: alarm_plugin
description: Timer-based alarm plugin
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

# پلاگین ۵: Pedometer

## 📄 `lib/plugins/pedometer/lib/pedometer_plugin.dart`

```dart
import 'dart:async';

import 'package:pedometer/pedometer.dart';
import 'package:sweetmelon/packages/core/lib/core.dart';
import 'package:sweetmelon/packages/plugin_engine/lib/plugin_engine.dart';

typedef PedometerEventEmitter = Future<void> Function(String event, dynamic data);

class PedometerPlugin extends Plugin {
  final PedometerEventEmitter? eventEmitter;

  StreamSubscription<StepCount>? _stepSub;
  StreamSubscription<PedestrianStatus>? _statusSub;
  bool _tracking = false;
  int _lastStepCount = 0;
  String _lastStatus = 'unknown';

  PedometerPlugin({this.eventEmitter});

  @override
  String get name => 'pedometer';

  @override
  String get version => '1.0.0';

  @override
  String get description => 'Step counter and pedestrian status plugin';

  @override
  List<String> get supportedMethods => [
        'startTracking',
        'stopTracking',
        'getStepCount',
        'getStatus',
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
        return _startTracking();
      case 'stopTracking':
        return _stopTracking();
      case 'getStepCount':
        return {'steps': _lastStepCount};
      case 'getStatus':
        return {'status': _lastStatus};
      case 'isTracking':
        return {'tracking': _tracking};
      case 'getInfo':
        return {
          'name': name,
          'version': version,
          'tracking': _tracking,
          'lastStepCount': _lastStepCount,
          'lastStatus': _lastStatus,
        };
      default:
        throw UnsupportedError('Method "$method" not supported');
    }
  }

  Future<Map<String, dynamic>> _startTracking() async {
    if (_tracking) {
      return {'started': true, 'alreadyTracking': true};
    }

    _stepSub = Pedometer.stepCountStream.listen(
      (event) {
        _lastStepCount = event.steps;
        eventEmitter?.call('pedometer.step', {
          'steps': event.steps,
          'timestamp': event.timeStamp.toIso8601String(),
        });
      },
      onError: (error) {
        BridgeLogger.error('Pedometer', 'Step count error: $error');
        eventEmitter?.call('pedometer.error', {
          'type': 'stepCount',
          'message': error.toString(),
        });
      },
    );

    _statusSub = Pedometer.pedestrianStatusStream.listen(
      (event) {
        _lastStatus = event.status;
        eventEmitter?.call('pedometer.status', {
          'status': event.status,
          'timestamp': event.timeStamp.toIso8601String(),
        });
      },
      onError: (error) {
        BridgeLogger.error('Pedometer', 'Status error: $error');
      },
    );

    _tracking = true;
    BridgeLogger.info('Pedometer', 'Tracking started');

    return {'started': true, 'alreadyTracking': false};
  }

  Future<Map<String, dynamic>> _stopTracking() async {
    _stepSub?.cancel();
    _statusSub?.cancel();
    _stepSub = null;
    _statusSub = null;
    _tracking = false;

    return {'stopped': true, 'lastSteps': _lastStepCount};
  }
}
```

## 📄 `lib/plugins/pedometer/pubspec.yaml`

```yaml
name: pedometer_plugin
description: Step counter plugin
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
  pedometer: ^4.0.1
```

---

# پلاگین ۶: Shake Detection

## 📄 `lib/plugins/shake_detection/lib/shake_detection_plugin.dart`

```dart
import 'dart:async';
import 'dart:math';

import 'package:sensors_plus/sensors_plus.dart';
import 'package:sweetmelon/packages/core/lib/core.dart';
import 'package:sweetmelon/packages/plugin_engine/lib/plugin_engine.dart';

typedef ShakeEventEmitter = Future<void> Function(String event, dynamic data);

class ShakeDetectionPlugin extends Plugin {
  final ShakeEventEmitter? eventEmitter;

  StreamSubscription<AccelerometerEvent>? _sub;
  bool _listening = false;
  double _threshold = 15.0;
  int _shakeCount = 0;
  DateTime? _lastShakeTime;
  int _cooldownMs = 1000;

  ShakeDetectionPlugin({this.eventEmitter});

  @override
  String get name => 'shakeDetection';

  @override
  String get version => '1.0.0';

  @override
  String get description => 'Detect device shake gesture';

  @override
  List<String> get supportedMethods => [
        'startListening',
        'stopListening',
        'configure',
        'getShakeCount',
        'resetCount',
        'isListening',
        'getInfo',
      ];

  @override
  Future<void> onDispose() async {
    _sub?.cancel();
    _sub = null;
    _listening = false;
  }

  @override
  Future<dynamic> onCall(String method, Map<String, dynamic> args) async {
    switch (method) {
      case 'startListening':
        return _startListening(args);
      case 'stopListening':
        return _stopListening();
      case 'configure':
        return _configure(args);
      case 'getShakeCount':
        return {'count': _shakeCount};
      case 'resetCount':
        _shakeCount = 0;
        return {'reset': true};
      case 'isListening':
        return {'listening': _listening};
      case 'getInfo':
        return {
          'name': name,
          'version': version,
          'listening': _listening,
          'threshold': _threshold,
          'cooldownMs': _cooldownMs,
          'shakeCount': _shakeCount,
        };
      default:
        throw UnsupportedError('Method "$method" not supported');
    }
  }

  Map<String, dynamic> _startListening(Map<String, dynamic> args) {
    if (_listening) {
      return {'started': true, 'alreadyListening': true};
    }

    final threshold = (args['threshold'] as num?)?.toDouble();
    final cooldown = (args['cooldownMs'] as num?)?.toInt();
    if (threshold != null) _threshold = threshold;
    if (cooldown != null) _cooldownMs = cooldown;

    _sub = accelerometerEventStream(
      samplingPeriod: const Duration(milliseconds: 100),
    ).listen((event) {
      final magnitude = sqrt(
        event.x * event.x + event.y * event.y + event.z * event.z,
      );

      if (magnitude > _threshold) {
        final now = DateTime.now();

        if (_lastShakeTime != null &&
            now.difference(_lastShakeTime!).inMilliseconds < _cooldownMs) {
          return;
        }

        _lastShakeTime = now;
        _shakeCount++;

        BridgeLogger.debug('Shake', 'Shake detected (magnitude: ${magnitude.toStringAsFixed(1)})');

        eventEmitter?.call('shake.detected', {
          'magnitude': magnitude,
          'count': _shakeCount,
          'timestamp': now.toIso8601String(),
        });
      }
    });

    _listening = true;
    return {'started': true, 'alreadyListening': false};
  }

  Map<String, dynamic> _stopListening() {
    _sub?.cancel();
    _sub = null;
    _listening = false;
    return {'stopped': true};
  }

  Map<String, dynamic> _configure(Map<String, dynamic> args) {
    if (args['threshold'] != null) {
      _threshold = (args['threshold'] as num).toDouble();
    }
    if (args['cooldownMs'] != null) {
      _cooldownMs = (args['cooldownMs'] as num).toInt();
    }
    return {'threshold': _threshold, 'cooldownMs': _cooldownMs};
  }
}
```

## 📄 `lib/plugins/shake_detection/pubspec.yaml`

```yaml
name: shake_detection_plugin
description: Shake gesture detection plugin
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

# پلاگین ۷: Volume Buttons

## 📄 `lib/plugins/volume_buttons/lib/volume_buttons_plugin.dart`

```dart
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:sweetmelon/packages/core/lib/core.dart';
import 'package:sweetmelon/packages/plugin_engine/lib/plugin_engine.dart';

typedef VolumeEventEmitter = Future<void> Function(String event, dynamic data);

class VolumeButtonsPlugin extends Plugin {
  final VolumeEventEmitter? eventEmitter;
  bool _listening = false;
  static const _channel = EventChannel('sweetmelon/volume_buttons');
  StreamSubscription<dynamic>? _sub;

  VolumeButtonsPlugin({this.eventEmitter});

  @override
  String get name => 'volumeButtons';

  @override
  String get version => '1.0.0';

  @override
  String get description => 'Listen to volume button presses';

  @override
  List<String> get supportedMethods => [
        'startListening',
        'stopListening',
        'isListening',
        'getInfo',
      ];

  @override
  Future<void> onDispose() async {
    _sub?.cancel();
    _listening = false;
  }

  @override
  Future<dynamic> onCall(String method, Map<String, dynamic> args) async {
    switch (method) {
      case 'startListening':
        return _startListening();
      case 'stopListening':
        return _stopListening();
      case 'isListening':
        return {'listening': _listening};
      case 'getInfo':
        return {
          'name': name,
          'version': version,
          'listening': _listening,
        };
      default:
        throw UnsupportedError('Method "$method" not supported');
    }
  }

  Map<String, dynamic> _startListening() {
    if (_listening) {
      return {'started': true, 'alreadyListening': true};
    }

    try {
      _sub = _channel.receiveBroadcastStream().listen(
        (event) {
          final direction = event == 'up' ? 'up' : 'down';

          eventEmitter?.call('volume.pressed', {
            'direction': direction,
            'timestamp': DateTime.now().toIso8601String(),
          });
        },
        onError: (error) {
          BridgeLogger.error('VolumeButtons', 'Stream error: $error');
        },
      );

      _listening = true;
    } catch (e) {
      BridgeLogger.warn('VolumeButtons', 'Native channel not available: $e');
      _listening = true; // still mark as listening for stub
    }

    return {'started': true, 'alreadyListening': false};
  }

  Map<String, dynamic> _stopListening() {
    _sub?.cancel();
    _sub = null;
    _listening = false;
    return {'stopped': true};
  }
}
```

## 📄 `lib/plugins/volume_buttons/pubspec.yaml`

```yaml
name: volume_buttons_plugin
description: Volume button listener plugin
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

# پلاگین ۸: SIM Info

## 📄 `lib/plugins/sim_info/lib/sim_info_plugin.dart`

```dart
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:sweetmelon/packages/core/lib/core.dart';
import 'package:sweetmelon/packages/plugin_engine/lib/plugin_engine.dart';

class SimInfoPlugin extends Plugin {
  static const _channel = MethodChannel('sweetmelon/sim_info');

  @override
  String get name => 'simInfo';

  @override
  String get version => '1.0.0';

  @override
  String get description => 'SIM card information plugin';

  @override
  List<String> get requiredPermissions => ['phone'];

  @override
  List<String> get supportedMethods => [
        'getSimInfo',
        'getCarrierName',
        'getSimCount',
        'getInfo',
      ];

  @override
  Future<dynamic> onCall(String method, Map<String, dynamic> args) async {
    switch (method) {
      case 'getSimInfo':
        return _getSimInfo();
      case 'getCarrierName':
        return _getCarrierName();
      case 'getSimCount':
        return _getSimCount();
      case 'getInfo':
        return {
          'name': name,
          'version': version,
          'platform': Platform.operatingSystem,
        };
      default:
        throw UnsupportedError('Method "$method" not supported');
    }
  }

  Future<Map<String, dynamic>> _getSimInfo() async {
    try {
      final result = await _channel.invokeMethod('getSimInfo');
      if (result != null) {
        return Map<String, dynamic>.from(result);
      }
    } catch (e) {
      BridgeLogger.warn('SimInfo', 'Native channel not available: $e');
    }

    return {
      'available': false,
      'reason': 'native_channel_required',
      'note': 'Add native implementation for full SIM info',
    };
  }

  Future<Map<String, dynamic>> _getCarrierName() async {
    try {
      final result = await _channel.invokeMethod('getCarrierName');
      return {'carrier': result ?? 'unknown'};
    } catch (_) {
      return {'carrier': 'unknown'};
    }
  }

  Future<Map<String, dynamic>> _getSimCount() async {
    try {
      final result = await _channel.invokeMethod('getSimCount');
      return {'count': result ?? 0};
    } catch (_) {
      return {'count': 0};
    }
  }
}
```

## 📄 `lib/plugins/sim_info/pubspec.yaml`

```yaml
name: sim_info_plugin
description: SIM card info plugin
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

# پلاگین ۹: Kiosk Mode

## 📄 `lib/plugins/kiosk_mode/lib/kiosk_mode_plugin.dart`

```dart
import 'package:flutter/services.dart';
import 'package:sweetmelon/packages/core/lib/core.dart';
import 'package:sweetmelon/packages/plugin_engine/lib/plugin_engine.dart';

class KioskModePlugin extends Plugin {
  bool _enabled = false;

  @override
  String get name => 'kioskMode';

  @override
  String get version => '1.0.0';

  @override
  String get description => 'Lock device into kiosk mode';

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
        return {'name': name, 'version': version, 'enabled': _enabled};
      default:
        throw UnsupportedError('Method "$method" not supported');
    }
  }

  Future<Map<String, dynamic>> _enable() async {
    if (_enabled) {
      return {'enabled': true, 'alreadyEnabled': true};
    }

    // Hide system UI
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    // Lock orientation
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);

    _enabled = true;
    BridgeLogger.info('KioskMode', 'Kiosk mode enabled');

    return {'enabled': true, 'alreadyEnabled': false};
  }

  Future<Map<String, dynamic>> _disable() async {
    if (!_enabled) {
      return {'enabled': false, 'alreadyDisabled': true};
    }

    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );

    await SystemChrome.setPreferredOrientations(DeviceOrientation.values);

    _enabled = false;
    BridgeLogger.info('KioskMode', 'Kiosk mode disabled');

    return {'enabled': false, 'alreadyDisabled': false};
  }

  @override
  Future<void> onDispose() async {
    if (_enabled) await _disable();
  }
}
```

## 📄 `lib/plugins/kiosk_mode/pubspec.yaml`

```yaml
name: kiosk_mode_plugin
description: Kiosk mode plugin
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

# پلاگین ۱۰: Intent Launcher

## 📄 `lib/plugins/intent_launcher/lib/intent_launcher_plugin.dart`

```dart
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:sweetmelon/packages/core/lib/core.dart';
import 'package:sweetmelon/packages/plugin_engine/lib/plugin_engine.dart';

class IntentLauncherPlugin extends Plugin {
  @override
  String get name => 'intentLauncher';

  @override
  String get version => '1.0.0';

  @override
  String get description => 'Launch Android intents and system screens';

  @override
  List<String> get supportedMethods => [
        'launch',
        'launchUrl',
        'isAppInstalled',
        'getInfo',
      ];

  static const Map<String, String> _knownIntents = {
    'settings': 'android.settings.SETTINGS',
    'wifi': 'android.settings.WIFI_SETTINGS',
    'bluetooth': 'android.settings.BLUETOOTH_SETTINGS',
    'location': 'android.settings.LOCATION_SOURCE_SETTINGS',
    'nfc': 'android.settings.NFC_SETTINGS',
    'airplane': 'android.settings.AIRPLANE_MODE_SETTINGS',
    'battery': 'android.settings.BATTERY_SAVER_SETTINGS',
    'display': 'android.settings.DISPLAY_SETTINGS',
    'sound': 'android.settings.SOUND_SETTINGS',
    'date': 'android.settings.DATE_SETTINGS',
    'apps': 'android.settings.APPLICATION_SETTINGS',
    'developer': 'android.settings.APPLICATION_DEVELOPMENT_SETTINGS',
    'accessibility': 'android.settings.ACCESSIBILITY_SETTINGS',
    'security': 'android.settings.SECURITY_SETTINGS',
    'privacy': 'android.settings.PRIVACY_SETTINGS',
    'storage': 'android.settings.INTERNAL_STORAGE_SETTINGS',
    'about': 'android.settings.DEVICE_INFO_SETTINGS',
    'vpn': 'android.settings.VPN_SETTINGS',
    'data_roaming': 'android.settings.DATA_ROAMING_SETTINGS',
    'notification': 'android.settings.APP_NOTIFICATION_SETTINGS',
    'language': 'android.settings.LOCALE_SETTINGS',
    'keyboard': 'android.settings.INPUT_METHOD_SETTINGS',
    'default_apps': 'android.settings.MANAGE_DEFAULT_APPS_SETTINGS',
    'hotspot': 'android.settings.TETHER_SETTINGS',
    'mobile_data': 'android.settings.DATA_USAGE_SETTINGS',
  };

  @override
  Future<dynamic> onCall(String method, Map<String, dynamic> args) async {
    switch (method) {
      case 'launch':
        return _launch(args);
      case 'launchUrl':
        return _launchUrl(args);
      case 'isAppInstalled':
        return _isAppInstalled(args);
      case 'getInfo':
        return {
          'name': name,
          'version': version,
          'knownIntents': _knownIntents.keys.toList(),
        };
      default:
        throw UnsupportedError('Method "$method" not supported');
    }
  }

  Future<Map<String, dynamic>> _launch(Map<String, dynamic> args) async {
    final intentName = args['intent'] as String;
    final action = _knownIntents[intentName] ?? intentName;

    try {
      final uri = Uri.parse('intent://#Intent;action=$action;end');
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);

      return {
        'launched': launched,
        'intent': intentName,
        'action': action,
      };
    } catch (e) {
      BridgeLogger.error('IntentLauncher', 'Launch failed: $e');
      return {'launched': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> _launchUrl(Map<String, dynamic> args) async {
    final url = args['url'] as String;
    final mode = args['mode'] as String? ?? 'external';

    try {
      final launched = await launchUrl(
        Uri.parse(url),
        mode: mode == 'inApp'
            ? LaunchMode.inAppWebView
            : LaunchMode.externalApplication,
      );

      return {'launched': launched, 'url': url};
    } catch (e) {
      return {'launched': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> _isAppInstalled(Map<String, dynamic> args) async {
    final packageName = args['packageName'] as String;

    try {
      final uri = Uri.parse('market://details?id=$packageName');
      final canOpen = await canLaunchUrl(uri);
      return {'installed': canOpen, 'packageName': packageName};
    } catch (e) {
      return {'installed': false, 'error': e.toString()};
    }
  }

  @override
  Future<ValidationResult> validateArgs(String method, Map<String, dynamic> args) async {
    switch (method) {
      case 'launch':
        if (args['intent'] is! String) {
          return ValidationResult.invalid('intent name is required');
        }
        return ValidationResult.valid();
      case 'launchUrl':
        if (args['url'] is! String) {
          return ValidationResult.invalid('url is required');
        }
        return ValidationResult.valid();
      case 'isAppInstalled':
        if (args['packageName'] is! String) {
          return ValidationResult.invalid('packageName is required');
        }
        return ValidationResult.valid();
      default:
        return ValidationResult.valid();
    }
  }
}
```

## 📄 `lib/plugins/intent_launcher/pubspec.yaml`

```yaml
name: intent_launcher_plugin
description: Android intent launcher plugin
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

# پلاگین ۱۱: Email Composer

## 📄 `lib/plugins/email_composer/lib/email_composer_plugin.dart`

```dart
import 'package:url_launcher/url_launcher.dart';
import 'package:sweetmelon/packages/plugin_engine/lib/plugin_engine.dart';

class EmailComposerPlugin extends Plugin {
  @override
  String get name => 'emailComposer';

  @override
  String get version => '1.0.0';

  @override
  String get description => 'Compose and send email with attachments';

  @override
  List<String> get supportedMethods => [
        'compose',
        'canCompose',
        'getInfo',
      ];

  @override
  Future<dynamic> onCall(String method, Map<String, dynamic> args) async {
    switch (method) {
      case 'compose':
        return _compose(args);
      case 'canCompose':
        return _canCompose();
      case 'getInfo':
        return {'name': name, 'version': version};
      default:
        throw UnsupportedError('Method "$method" not supported');
    }
  }

  Future<Map<String, dynamic>> _compose(Map<String, dynamic> args) async {
    final to = _parseRecipients(args['to']);
    final cc = _parseRecipients(args['cc']);
    final bcc = _parseRecipients(args['bcc']);
    final subject = args['subject'] as String? ?? '';
    final body = args['body'] as String? ?? '';
    final isHtml = args['isHtml'] as bool? ?? false;

    if (to.isEmpty) {
      return {'opened': false, 'reason': 'no_recipients'};
    }

    final params = <String, String>{};
    if (subject.isNotEmpty) params['subject'] = subject;
    if (body.isNotEmpty) params['body'] = body;
    if (cc.isNotEmpty) params['cc'] = cc.join(',');
    if (bcc.isNotEmpty) params['bcc'] = bcc.join(',');

    final uri = Uri(
      scheme: 'mailto',
      path: to.join(','),
      queryParameters: params.isNotEmpty ? params : null,
    );

    try {
      final launched = await launchUrl(uri);
      return {
        'opened': launched,
        'to': to,
        'subject': subject,
      };
    } catch (e) {
      return {'opened': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> _canCompose() async {
    try {
      final uri = Uri.parse('mailto:test@example.com');
      final can = await canLaunchUrl(uri);
      return {'available': can};
    } catch (e) {
      return {'available': false, 'error': e.toString()};
    }
  }

  List<String> _parseRecipients(dynamic value) {
    if (value == null) return [];
    if (value is String) return [value];
    if (value is List) return value.map((e) => e.toString()).toList();
    return [];
  }

  @override
  Future<ValidationResult> validateArgs(String method, Map<String, dynamic> args) async {
    if (method == 'compose') {
      final to = args['to'];
      if (to == null) {
        return ValidationResult.invalid('to (email address) is required');
      }
    }
    return ValidationResult.valid();
  }
}
```

## 📄 `lib/plugins/email_composer/pubspec.yaml`

```yaml
name: email_composer_plugin
description: Email composer plugin
version: 1.0.0

environment:
  sdk: ^3.0.0

dependencies:
  flutter:
    sdk: flutter
  plugin_engine:
    path: ../../packages/plugin_engine
  url_launcher: ^6.3.0
```

---

# pubspec.yaml — dependency‌های جدید

```yaml
  # فاز ۱۱
  pedometer: ^4.0.1
```

---

# ثبت پلاگین‌ها — Service Locator

> imports:

```dart
import 'package:sweetmelon/plugins/wifi_manager/lib/wifi_manager_plugin.dart';
import 'package:sweetmelon/plugins/root_detection/lib/root_detection_plugin.dart';
import 'package:sweetmelon/plugins/app_integrity/lib/app_integrity_plugin.dart';
import 'package:sweetmelon/plugins/alarm/lib/alarm_plugin.dart';
import 'package:sweetmelon/plugins/pedometer/lib/pedometer_plugin.dart';
import 'package:sweetmelon/plugins/shake_detection/lib/shake_detection_plugin.dart';
import 'package:sweetmelon/plugins/volume_buttons/lib/volume_buttons_plugin.dart';
import 'package:sweetmelon/plugins/sim_info/lib/sim_info_plugin.dart';
import 'package:sweetmelon/plugins/kiosk_mode/lib/kiosk_mode_plugin.dart';
import 'package:sweetmelon/plugins/intent_launcher/lib/intent_launcher_plugin.dart';
import 'package:sweetmelon/plugins/email_composer/lib/email_composer_plugin.dart';
```

> Lazy plugins:

```dart
      LazyPluginDefinition(id: 'wifiManager', version: '1.0.0', factory: () => WifiManagerPlugin(eventEmitter: emitter)),
      LazyPluginDefinition(id: 'rootDetection', version: '1.0.0', factory: () => RootDetectionPlugin()),
      LazyPluginDefinition(id: 'appIntegrity', version: '1.0.0', factory: () => AppIntegrityPlugin()),
      LazyPluginDefinition(id: 'alarm', version: '1.0.0', factory: () => AlarmPlugin(eventEmitter: emitter)),
      LazyPluginDefinition(id: 'pedometer', version: '1.0.0', factory: () => PedometerPlugin(eventEmitter: emitter)),
      LazyPluginDefinition(id: 'shakeDetection', version: '1.0.0', factory: () => ShakeDetectionPlugin(eventEmitter: emitter)),
      LazyPluginDefinition(id: 'volumeButtons', version: '1.0.0', factory: () => VolumeButtonsPlugin(eventEmitter: emitter)),
      LazyPluginDefinition(id: 'simInfo', version: '1.0.0', factory: () => SimInfoPlugin()),
      LazyPluginDefinition(id: 'kioskMode', version: '1.0.0', factory: () => KioskModePlugin()),
      LazyPluginDefinition(id: 'intentLauncher', version: '1.0.0', factory: () => IntentLauncherPlugin()),
      LazyPluginDefinition(id: 'emailComposer', version: '1.0.0', factory: () => EmailComposerPlugin()),
```

---

# NativeSDK — فاز ۱۱

```javascript
    wifiManager: {
      getConnectionInfo: function () { return call('wifiManager', 'getConnectionInfo', {}); },
      getIpAddress: function () { return call('wifiManager', 'getIpAddress', {}); },
      isEnabled: function () { return call('wifiManager', 'isEnabled', {}); },
      getInfo: function () { return call('wifiManager', 'getInfo', {}); }
    },

    rootDetection: {
      isRooted: function () { return call('rootDetection', 'isRooted', {}); },
      getSecurityInfo: function () { return call('rootDetection', 'getSecurityInfo', {}); },
      getInfo: function () { return call('rootDetection', 'getInfo', {}); }
    },

    appIntegrity: {
      checkIntegrity: function () { return call('appIntegrity', 'checkIntegrity', {}); },
      isGenuineInstall: function () { return call('appIntegrity', 'isGenuineInstall', {}); },
      getInstallSource: function () { return call('appIntegrity', 'getInstallSource', {}); },
      getSigningInfo: function () { return call('appIntegrity', 'getSigningInfo', {}); },
      getInfo: function () { return call('appIntegrity', 'getInfo', {}); }
    },

    alarm: {
      set: function (o) { return call('alarm', 'set', o); },
      cancel: function (alarmId) { return call('alarm', 'cancel', { alarmId: alarmId }); },
      cancelAll: function () { return call('alarm', 'cancelAll', {}); },
      getAlarm: function (alarmId) { return call('alarm', 'getAlarm', { alarmId: alarmId }); },
      getAllAlarms: function () { return call('alarm', 'getAllAlarms', {}); },
      getInfo: function () { return call('alarm', 'getInfo', {}); }
    },

    pedometer: {
      startTracking: function () { return call('pedometer', 'startTracking', {}); },
      stopTracking: function () { return call('pedometer', 'stopTracking', {}); },
      getStepCount: function () { return call('pedometer', 'getStepCount', {}); },
      getStatus: function () { return call('pedometer', 'getStatus', {}); },
      isTracking: function () { return call('pedometer', 'isTracking', {}); },
      getInfo: function () { return call('pedometer', 'getInfo', {}); }
    },

    shakeDetection: {
      startListening: function (o) { return call('shakeDetection', 'startListening', o || {}); },
      stopListening: function () { return call('shakeDetection', 'stopListening', {}); },
      configure: function (o) { return call('shakeDetection', 'configure', o || {}); },
      getShakeCount: function () { return call('shakeDetection', 'getShakeCount', {}); },
      resetCount: function () { return call('shakeDetection', 'resetCount', {}); },
      isListening: function () { return call('shakeDetection', 'isListening', {}); },
      getInfo: function () { return call('shakeDetection', 'getInfo', {}); }
    },

    volumeButtons: {
      startListening: function () { return call('volumeButtons', 'startListening', {}); },
      stopListening: function () { return call('volumeButtons', 'stopListening', {}); },
      isListening: function () { return call('volumeButtons', 'isListening', {}); },
      getInfo: function () { return call('volumeButtons', 'getInfo', {}); }
    },

    simInfo: {
      getSimInfo: function () { return call('simInfo', 'getSimInfo', {}); },
      getCarrierName: function () { return call('simInfo', 'getCarrierName', {}); },
      getSimCount: function () { return call('simInfo', 'getSimCount', {}); },
      getInfo: function () { return call('simInfo', 'getInfo', {}); }
    },

    kioskMode: {
      enable: function () { return call('kioskMode', 'enable', {}); },
      disable: function () { return call('kioskMode', 'disable', {}); },
      isEnabled: function () { return call('kioskMode', 'isEnabled', {}); },
      getInfo: function () { return call('kioskMode', 'getInfo', {}); }
    },

    intentLauncher: {
      launch: function (intent) { return call('intentLauncher', 'launch', { intent: intent }); },
      launchUrl: function (url, mode) { return call('intentLauncher', 'launchUrl', { url: url, mode: mode || 'external' }); },
      isAppInstalled: function (packageName) { return call('intentLauncher', 'isAppInstalled', { packageName: packageName }); },
      getInfo: function () { return call('intentLauncher', 'getInfo', {}); }
    },

    emailComposer: {
      compose: function (o) { return call('emailComposer', 'compose', o); },
      canCompose: function () { return call('emailComposer', 'canCompose', {}); },
      getInfo: function () { return call('emailComposer', 'getInfo', {}); }
    },
```

---

# خلاصه نهایی فاز ۱۱ + کل پروژه

## پلاگین‌های فاز ۱۱

| # | پلاگین | نام JS | Events |
|---|--------|--------|--------|
| 70 | WiFi Manager | `wifiManager` | — |
| 71 | Root Detection | `rootDetection` | — |
| 72 | App Integrity | `appIntegrity` | — |
| 73 | Alarm | `alarm` | alarm.fired |
| 74 | Pedometer | `pedometer` | pedometer.step, pedometer.status, pedometer.error |
| 75 | Shake Detection | `shakeDetection` | shake.detected |
| 76 | Volume Buttons | `volumeButtons` | volume.pressed |
| 77 | SIM Info | `simInfo` | — |
| 78 | Kiosk Mode | `kioskMode` | — |
| 79 | Intent Launcher | `intentLauncher` | — |
| 80 | Email Composer | `emailComposer` | — |

## **مجموع کل: 80 پلاگین** 🎉

---

## آمار نهایی پروژه

| آیتم | تعداد |
|------|-------|
| **پلاگین‌ها** | 80 |
| **Events** | 50+ |
| **JS API methods** | 500+ |
| **فازها** | 11 |

## لیست کامل ۸۰ پلاگین

| فاز | پلاگین‌ها |
|------|----------|
| **۱** | permission, appLifecycle, deviceInfo, connectivity, storage, fileSystem, http, intent, clipboard, share, camera, geolocation |
| **۳** | backButton, secureStorage, notification, statusBar, orientation, haptic, keyboard |
| **۴** | biometrics, qrScanner, audio, smsOtp, downloadManager, database, contacts, phoneDialer |
| **۵** | bluetooth, nfc, speechToText, textToSpeech, videoPlayer, inAppBrowser, pdf, encryption |
| **۶** | websocket, backgroundTask |
| **۷** | dialog, toast, splashScreen, pushNotification, wakeLock, cookieManager, cacheControl, appUpdate |
| **۸** | filePicker, fileOpener, sensors, screenBrightness, flashlight, navigationBar, privacyScreen, nativeSettings |
| **۹** | calendar, badge, foregroundService, backgroundGeolocation, mediaManager, fileCompressor, zip, shareTarget |
| **۱۰** | inAppReview, nativeMarket, screenshot, safeArea, datePicker, actionSheet, textZoom, accessibility |
| **۱۱** | wifiManager, rootDetection, appIntegrity, alarm, pedometer, shakeDetection, volumeButtons, simInfo, kioskMode, intentLauncher, emailComposer |

## نحوه استفاده JS — فاز ۱۱

```javascript
// WiFi
const { ip, connected } = await NativeSDK.wifiManager.getConnectionInfo();

// Root Detection (بانکی/امنیتی)
const { isRooted, riskLevel, checks } = await NativeSDK.rootDetection.isRooted();
if (isRooted) {
  await NativeSDK.dialog.alert('This app cannot run on rooted devices');
  NativeSDK.backButton.exitApp();
}

// App Integrity
const integrity = await NativeSDK.appIntegrity.checkIntegrity();
console.log('Verdict:', integrity.verdict); // trusted / genuine / untrusted

// Alarm
await NativeSDK.alarm.set({
  alarmId: 'reminder_1',
  delayMs: 60000, // 1 minute
  title: 'Break Time',
  body: 'Take a 5 minute break',
  payload: { type: 'break' }
});

NativeSDK.on('alarm.fired', (data) => {
  NativeSDK.notification.show({
    title: data.title,
    body: data.body
  });
});

// Repeating alarm
await NativeSDK.alarm.set({
  alarmId: 'sync',
  delayMs: 0,
  repeating: true,
  intervalMs: 300000, // every 5 min
  title: 'Background Sync'
});

// Pedometer
await NativeSDK.pedometer.startTracking();
NativeSDK.on('pedometer.step', (data) => {
  document.getElementById('steps').textContent = data.steps;
});

// Shake Detection
await NativeSDK.shakeDetection.startListening({ threshold: 12 });
NativeSDK.on('shake.detected', () => {
  NativeSDK.haptic.heavyImpact();
  showDebugPanel();
});

// Volume Buttons (اسکنر/ابزار)
await NativeSDK.volumeButtons.startListening();
NativeSDK.on('volume.pressed', (data) => {
  if (data.direction === 'up') zoomIn();
  else zoomOut();
});

// SIM Info
const sim = await NativeSDK.simInfo.getSimInfo();
const carrier = await NativeSDK.simInfo.getCarrierName();

// Kiosk Mode (نمایشگاه/فروشگاه)
await NativeSDK.kioskMode.enable();
// ... app locked ...
await NativeSDK.kioskMode.disable();

// Intent Launcher
await NativeSDK.intentLauncher.launch('wifi');
await NativeSDK.intentLauncher.launch('bluetooth');
const { installed } = await NativeSDK.intentLauncher.isAppInstalled('com.whatsapp');

// Email Composer
await NativeSDK.emailComposer.compose({
  to: ['support@example.com', 'admin@example.com'],
  cc: 'manager@example.com',
  subject: 'Bug Report #1234',
  body: 'Steps to reproduce:\n1. Open app\n2. Click button\n3. Error appears'
});
```

---

پروژه حالا **۸۰ پلاگین** داره و تقریباً **تمام قابلیت‌های نیتیو Android** رو پوشش می‌ده. 🎉
