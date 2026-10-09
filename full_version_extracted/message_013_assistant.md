# فاز ۴ — ۸ پلاگین تخصصی جدید

---

# بخش ۱: بروزرسانی `pubspec.yaml` اصلی

## 📄 `pubspec.yaml`

```yaml
name: sweetmelon
description: Flutter Native Bridge - JS to Native communication platform
publish_to: 'none'

version: 1.0.0+1

environment:
  sdk: ^3.0.0

dependencies:
  flutter:
    sdk: flutter

  webview_flutter: ^4.8.0
  webview_flutter_android: ^3.16.0
  webview_flutter_wkwebview: ^3.13.0

  shared_preferences: ^2.2.2
  path_provider: ^2.1.1
  path: ^1.9.0
  uuid: ^4.2.1
  get_it: ^7.6.4
  http: ^1.1.2
  image_picker: ^1.0.4
  geolocator: ^10.1.0
  permission_handler: ^11.3.0
  mime: ^1.0.5

  connectivity_plus: ^6.0.5
  device_info_plus: ^10.1.2
  package_info_plus: ^8.0.2
  url_launcher: ^6.3.0
  app_links: ^6.3.2
  share_plus: ^10.0.2
  cross_file: ^0.3.4+2

  flutter_secure_storage: ^9.2.2
  flutter_local_notifications: ^17.2.4

  # فاز ۴
  local_auth: ^2.3.0
  mobile_scanner: ^5.2.3
  record: ^5.1.2
  audioplayers: ^6.1.0
  sms_autofill: ^2.4.0
  sqflite: ^2.3.3+2
  flutter_contacts: ^1.1.9+2
  phone_state: ^1.0.4

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0

flutter:
  uses-material-design: true

  assets:
    - assets/www/
```

---

# بخش ۲: بروزرسانی `AndroidManifest.xml`

## 📄 `android/app/src/main/AndroidManifest.xml`

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">

    <!-- Network -->
    <uses-permission android:name="android.permission.INTERNET"/>
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/>

    <!-- Camera / Media -->
    <uses-permission android:name="android.permission.CAMERA"/>
    <uses-permission android:name="android.permission.RECORD_AUDIO"/>

    <!-- Storage -->
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" android:maxSdkVersion="32"/>
    <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" android:maxSdkVersion="28"/>
    <uses-permission android:name="android.permission.READ_MEDIA_IMAGES"/>
    <uses-permission android:name="android.permission.READ_MEDIA_VIDEO"/>
    <uses-permission android:name="android.permission.READ_MEDIA_AUDIO"/>

    <!-- Location -->
    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>

    <!-- Notifications -->
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>

    <!-- Biometrics -->
    <uses-permission android:name="android.permission.USE_BIOMETRIC"/>
    <uses-permission android:name="android.permission.USE_FINGERPRINT"/>

    <!-- SMS / OTP -->
    <uses-permission android:name="android.permission.RECEIVE_SMS"/>
    <uses-permission android:name="android.permission.READ_SMS"/>

    <!-- Contacts -->
    <uses-permission android:name="android.permission.READ_CONTACTS"/>
    <uses-permission android:name="android.permission.WRITE_CONTACTS"/>

    <!-- Phone -->
    <uses-permission android:name="android.permission.CALL_PHONE"/>
    <uses-permission android:name="android.permission.READ_PHONE_STATE"/>
    <uses-permission android:name="android.permission.READ_CALL_LOG"/>

    <!-- Vibrate -->
    <uses-permission android:name="android.permission.VIBRATE"/>

    <!-- Foreground service for audio recording -->
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE"/>

    <application
        android:label="sweetmelon"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher"
        android:usesCleartextTraffic="true"
        android:networkSecurityConfig="@xml/network_security_config"
        android:requestLegacyExternalStorage="true">

        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:launchMode="singleTop"
            android:taskAffinity=""
            android:theme="@style/LaunchTheme"
            android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
            android:hardwareAccelerated="true"
            android:windowSoftInputMode="adjustResize"
            android:enableOnBackInvokedCallback="true">

            <meta-data
                android:name="io.flutter.embedding.android.NormalTheme"
                android:resource="@style/NormalTheme"/>

            <intent-filter>
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.LAUNCHER"/>
            </intent-filter>

            <intent-filter>
                <action android:name="android.intent.action.VIEW"/>
                <category android:name="android.intent.category.DEFAULT"/>
                <category android:name="android.intent.category.BROWSABLE"/>
                <data android:scheme="sweetmelon"/>
            </intent-filter>

            <intent-filter>
                <action android:name="android.intent.action.VIEW"/>
                <category android:name="android.intent.category.DEFAULT"/>
                <category android:name="android.intent.category.BROWSABLE"/>
                <data android:scheme="https" android:host="app.sweetmelon.local"/>
            </intent-filter>
        </activity>

        <meta-data
            android:name="flutterEmbedding"
            android:value="2"/>

        <provider
            android:name="androidx.core.content.FileProvider"
            android:authorities="${applicationId}.fileprovider"
            android:exported="false"
            android:grantUriPermissions="true">
            <meta-data
                android:name="android.support.FILE_PROVIDER_PATHS"
                android:resource="@xml/file_paths"/>
        </provider>
    </application>

    <queries>
        <intent>
            <action android:name="android.intent.action.PROCESS_TEXT"/>
            <data android:mimeType="text/plain"/>
        </intent>
        <intent><action android:name="android.intent.action.VIEW"/><data android:scheme="http"/></intent>
        <intent><action android:name="android.intent.action.VIEW"/><data android:scheme="https"/></intent>
        <intent><action android:name="android.intent.action.VIEW"/><data android:scheme="tel"/></intent>
        <intent><action android:name="android.intent.action.VIEW"/><data android:scheme="sms"/></intent>
        <intent><action android:name="android.intent.action.VIEW"/><data android:scheme="smsto"/></intent>
        <intent><action android:name="android.intent.action.VIEW"/><data android:scheme="mailto"/></intent>
        <intent><action android:name="android.intent.action.VIEW"/><data android:scheme="geo"/></intent>
        <intent><action android:name="android.intent.action.VIEW"/><data android:scheme="market"/></intent>
        <intent><action android:name="android.intent.action.SEND"/><data android:mimeType="text/plain"/></intent>
        <intent><action android:name="android.intent.action.SEND"/><data android:mimeType="*/*"/></intent>
        <intent><action android:name="android.intent.action.DIAL"/><data android:scheme="tel"/></intent>
    </queries>
</manifest>
```

---

# بخش ۳: ۸ پلاگین جدید

---

## ۱) Biometrics Plugin

### 📄 `lib/plugins/biometrics/lib/biometrics_plugin.dart`

```dart
import 'dart:io';

import 'package:local_auth/local_auth.dart';
import 'package:local_auth/error_codes.dart' as auth_error;
import 'package:sweetmelon/packages/core/lib/core.dart';
import 'package:sweetmelon/packages/plugin_engine/lib/plugin_engine.dart';

class BiometricsPlugin extends Plugin {
  final LocalAuthentication _auth = LocalAuthentication();

  @override
  String get name => 'biometrics';

  @override
  String get version => '1.0.0';

  @override
  String get description => 'Biometric authentication plugin (fingerprint / face)';

  @override
  List<String> get supportedMethods => [
        'isAvailable',
        'getAvailableBiometrics',
        'authenticate',
        'getInfo',
      ];

  @override
  Future<dynamic> onCall(String method, Map<String, dynamic> args) async {
    switch (method) {
      case 'isAvailable':
        return _isAvailable();
      case 'getAvailableBiometrics':
        return _getAvailableBiometrics();
      case 'authenticate':
        return _authenticate(args);
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

  Future<Map<String, dynamic>> _isAvailable() async {
    final canAuth = await _auth.canCheckBiometrics;
    final isDeviceSupported = await _auth.isDeviceSupported();

    return {
      'canCheckBiometrics': canAuth,
      'isDeviceSupported': isDeviceSupported,
      'available': canAuth && isDeviceSupported,
    };
  }

  Future<Map<String, dynamic>> _getAvailableBiometrics() async {
    final biometrics = await _auth.getAvailableBiometrics();

    return {
      'biometrics': biometrics.map((b) => b.name).toList(),
      'hasFingerprint': biometrics.contains(BiometricType.fingerprint),
      'hasFace': biometrics.contains(BiometricType.face),
      'hasIris': biometrics.contains(BiometricType.iris),
      'hasStrong': biometrics.contains(BiometricType.strong),
      'hasWeak': biometrics.contains(BiometricType.weak),
    };
  }

  Future<Map<String, dynamic>> _authenticate(Map<String, dynamic> args) async {
    final reason = args['reason'] as String? ?? 'Please authenticate';
    final biometricOnly = args['biometricOnly'] as bool? ?? false;
    final stickyAuth = args['stickyAuth'] as bool? ?? true;
    final sensitiveTransaction = args['sensitiveTransaction'] as bool? ?? true;

    try {
      final authenticated = await _auth.authenticate(
        localizedReason: reason,
        options: AuthenticationOptions(
          biometricOnly: biometricOnly,
          stickyAuth: stickyAuth,
          sensitiveTransaction: sensitiveTransaction,
          useErrorDialogs: true,
        ),
      );

      return {
        'authenticated': authenticated,
        'method': 'biometric',
      };
    } catch (e) {
      String errorCode = 'unknown';
      String errorMessage = e.toString();

      if (e.toString().contains(auth_error.notAvailable)) {
        errorCode = 'not_available';
        errorMessage = 'Biometric authentication not available';
      } else if (e.toString().contains(auth_error.notEnrolled)) {
        errorCode = 'not_enrolled';
        errorMessage = 'No biometrics enrolled on device';
      } else if (e.toString().contains(auth_error.lockedOut)) {
        errorCode = 'locked_out';
        errorMessage = 'Too many attempts, locked out';
      } else if (e.toString().contains(auth_error.permanentlyLockedOut)) {
        errorCode = 'permanently_locked_out';
        errorMessage = 'Permanently locked out';
      }

      BridgeLogger.error('Biometrics', 'Auth error: $errorCode — $errorMessage');

      return {
        'authenticated': false,
        'errorCode': errorCode,
        'errorMessage': errorMessage,
      };
    }
  }

  @override
  Future<ValidationResult> validateArgs(
    String method,
    Map<String, dynamic> args,
  ) async {
    if (method == 'authenticate') {
      final reason = args['reason'];
      if (reason != null && reason is! String) {
        return ValidationResult.invalid('reason must be a string');
      }
    }
    return ValidationResult.valid();
  }
}
```

### 📄 `lib/plugins/biometrics/pubspec.yaml`

```yaml
name: biometrics_plugin
description: Biometric authentication plugin
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
  local_auth: ^2.3.0
```

---

## ۲) QR Scanner Plugin

### 📄 `lib/plugins/qr_scanner/lib/qr_scanner_plugin.dart`

```dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:sweetmelon/packages/core/lib/core.dart';
import 'package:sweetmelon/packages/plugin_engine/lib/plugin_engine.dart';

typedef QrEventEmitter = Future<void> Function(String event, dynamic data);

class QrScannerPlugin extends Plugin {
  final QrEventEmitter? eventEmitter;

  /// نگه‌داشتن context برای نمایش scanner overlay
  static GlobalKey<NavigatorState>? navigatorKey;

  QrScannerPlugin({this.eventEmitter});

  @override
  String get name => 'qrScanner';

  @override
  String get version => '1.0.0';

  @override
  String get description => 'QR and barcode scanner plugin';

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
        return {
          'name': name,
          'version': version,
          'supportedFormats': [
            'qr', 'ean13', 'ean8', 'code128', 'code39',
            'code93', 'upcA', 'upcE', 'itf', 'pdf417',
            'aztec', 'dataMatrix', 'codabar',
          ],
        };
      default:
        throw UnsupportedError('Method "$method" not supported');
    }
  }

  Future<Map<String, dynamic>> _scan(Map<String, dynamic> args) async {
    final completer = Completer<Map<String, dynamic>>();
    final timeoutMs = (args['timeoutMs'] as num?)?.toInt() ?? 60000;

    Timer? timeoutTimer;

    if (timeoutMs > 0) {
      timeoutTimer = Timer(Duration(milliseconds: timeoutMs), () {
        if (!completer.isCompleted) {
          completer.complete({
            'scanned': false,
            'reason': 'timeout',
          });
          _closeScannerOverlay();
        }
      });
    }

    final controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
      torchEnabled: false,
    );

    bool scanProcessed = false;

    void onDetect(BarcodeCapture capture) {
      if (scanProcessed) return;
      if (capture.barcodes.isEmpty) return;

      final barcode = capture.barcodes.first;

      if (barcode.rawValue == null || barcode.rawValue!.isEmpty) return;

      scanProcessed = true;
      timeoutTimer?.cancel();

      final result = {
        'scanned': true,
        'value': barcode.rawValue,
        'format': barcode.format.name,
        'type': _classifyContent(barcode.rawValue!),
        'timestamp': DateTime.now().toIso8601String(),
      };

      controller.dispose();
      _closeScannerOverlay();

      if (!completer.isCompleted) {
        completer.complete(result);
      }

      if (eventEmitter != null) {
        eventEmitter!('qrScanner.scanned', result);
      }
    }

    // Scanner overlay نمایش بده
    _showScannerOverlay(
      controller: controller,
      onDetect: onDetect,
      onCancel: () {
        timeoutTimer?.cancel();
        controller.dispose();
        if (!completer.isCompleted) {
          completer.complete({
            'scanned': false,
            'reason': 'cancelled',
          });
        }
      },
    );

    return completer.future;
  }

  String _classifyContent(String value) {
    final lower = value.toLowerCase();

    if (lower.startsWith('http://') || lower.startsWith('https://')) {
      return 'url';
    }
    if (lower.startsWith('tel:')) return 'phone';
    if (lower.startsWith('mailto:')) return 'email';
    if (lower.startsWith('smsto:') || lower.startsWith('sms:')) return 'sms';
    if (lower.startsWith('wifi:')) return 'wifi';
    if (lower.startsWith('geo:')) return 'geo';
    if (lower.startsWith('begin:vcard')) return 'vcard';

    return 'text';
  }

  void _showScannerOverlay({
    required MobileScannerController controller,
    required void Function(BarcodeCapture) onDetect,
    required VoidCallback onCancel,
  }) {
    final context = navigatorKey?.currentContext;
    if (context == null) {
      BridgeLogger.error('QrScanner', 'No navigator context available');
      onCancel();
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _ScannerOverlayPage(
          controller: controller,
          onDetect: onDetect,
          onCancel: onCancel,
        ),
      ),
    );
  }

  void _closeScannerOverlay() {
    final context = navigatorKey?.currentContext;
    if (context != null) {
      try {
        Navigator.of(context).pop();
      } catch (_) {}
    }
  }
}

class _ScannerOverlayPage extends StatelessWidget {
  final MobileScannerController controller;
  final void Function(BarcodeCapture) onDetect;
  final VoidCallback onCancel;

  const _ScannerOverlayPage({
    required this.controller,
    required this.onDetect,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () {
            onCancel();
            Navigator.of(context).pop();
          },
        ),
        title: const Text(
          'Scan QR / Barcode',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: controller,
            onDetect: onDetect,
          ),
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white54, width: 2),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

### 📄 `lib/plugins/qr_scanner/pubspec.yaml`

```yaml
name: qr_scanner_plugin
description: QR and barcode scanner plugin
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
  mobile_scanner: ^5.2.3
```

---

## ۳) Audio Plugin (Recorder + Player)

### 📄 `lib/plugins/audio/lib/audio_plugin.dart`

```dart
import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:sweetmelon/packages/core/lib/core.dart';
import 'package:sweetmelon/packages/plugin_engine/lib/plugin_engine.dart';

typedef AudioEventEmitter = Future<void> Function(String event, dynamic data);

class AudioPlugin extends Plugin {
  final AudioEventEmitter? eventEmitter;

  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();

  bool _isRecording = false;
  bool _isPlaying = false;
  String? _currentRecordingPath;
  StreamSubscription<PlayerState>? _playerSub;
  StreamSubscription<Duration>? _positionSub;

  AudioPlugin({this.eventEmitter});

  @override
  String get name => 'audio';

  @override
  String get version => '1.0.0';

  @override
  String get description => 'Audio recorder and player plugin';

  @override
  List<String> get requiredPermissions => ['microphone'];

  @override
  List<String> get supportedMethods => [
        'startRecording',
        'stopRecording',
        'isRecording',
        'play',
        'pause',
        'resume',
        'stop',
        'seek',
        'isPlaying',
        'getDuration',
        'getPosition',
        'setVolume',
        'getInfo',
      ];

  @override
  Future<void> onInitialize() async {
    _playerSub = _player.onPlayerStateChanged.listen((state) {
      _isPlaying = state == PlayerState.playing;

      if (eventEmitter != null) {
        eventEmitter!('audio.playerState', {
          'state': state.name,
          'isPlaying': _isPlaying,
          'timestamp': DateTime.now().toIso8601String(),
        });
      }
    });

    _positionSub = _player.onPositionChanged.listen((position) {
      if (eventEmitter != null && _isPlaying) {
        eventEmitter!('audio.position', {
          'positionMs': position.inMilliseconds,
          'positionSec': position.inSeconds,
        });
      }
    });
  }

  @override
  Future<void> onDispose() async {
    await _playerSub?.cancel();
    await _positionSub?.cancel();

    if (_isRecording) {
      await _recorder.stop();
    }
    await _recorder.dispose();
    await _player.dispose();
  }

  @override
  Future<dynamic> onCall(String method, Map<String, dynamic> args) async {
    switch (method) {
      case 'startRecording':
        return _startRecording(args);
      case 'stopRecording':
        return _stopRecording();
      case 'isRecording':
        return {'recording': _isRecording};
      case 'play':
        return _play(args);
      case 'pause':
        return _pause();
      case 'resume':
        return _resume();
      case 'stop':
        return _stop();
      case 'seek':
        return _seek(args);
      case 'isPlaying':
        return {'playing': _isPlaying};
      case 'getDuration':
        return _getDuration();
      case 'getPosition':
        return _getPosition();
      case 'setVolume':
        return _setVolume(args);
      case 'getInfo':
        return {
          'name': name,
          'version': version,
          'recording': _isRecording,
          'playing': _isPlaying,
          'currentRecordingPath': _currentRecordingPath,
        };
      default:
        throw UnsupportedError('Method "$method" not supported');
    }
  }

  Future<Map<String, dynamic>> _startRecording(Map<String, dynamic> args) async {
    if (_isRecording) {
      return {'started': false, 'reason': 'already_recording'};
    }

    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      return {'started': false, 'reason': 'permission_denied'};
    }

    final fileName = args['fileName'] as String? ??
        'recording_${DateTime.now().millisecondsSinceEpoch}.m4a';

    final dir = await getApplicationDocumentsDirectory();
    final recordDir = Directory(p.join(dir.path, 'recordings'));
    await recordDir.create(recursive: true);

    final filePath = p.join(recordDir.path, fileName);
    _currentRecordingPath = filePath;

    final encoder = _parseEncoder(args['encoder'] as String? ?? 'aacLc');
    final bitRate = (args['bitRate'] as num?)?.toInt() ?? 128000;
    final sampleRate = (args['sampleRate'] as num?)?.toInt() ?? 44100;

    await _recorder.start(
      RecordConfig(
        encoder: encoder,
        bitRate: bitRate,
        sampleRate: sampleRate,
      ),
      path: filePath,
    );

    _isRecording = true;

    BridgeLogger.info('Audio', 'Recording started: $filePath');

    return {
      'started': true,
      'path': filePath,
      'fileName': fileName,
    };
  }

  Future<Map<String, dynamic>> _stopRecording() async {
    if (!_isRecording) {
      return {'stopped': false, 'reason': 'not_recording'};
    }

    final path = await _recorder.stop();
    _isRecording = false;

    BridgeLogger.info('Audio', 'Recording stopped: $path');

    if (path != null) {
      final file = File(path);
      final stat = await file.stat();

      return {
        'stopped': true,
        'path': path,
        'fileName': p.basename(path),
        'size': stat.size,
      };
    }

    return {
      'stopped': true,
      'path': _currentRecordingPath,
    };
  }

  Future<Map<String, dynamic>> _play(Map<String, dynamic> args) async {
    final source = args['path'] as String? ?? args['url'] as String?;

    if (source == null || source.isEmpty) {
      return {'playing': false, 'reason': 'no_source'};
    }

    final volume = (args['volume'] as num?)?.toDouble() ?? 1.0;

    await _player.setVolume(volume);

    if (source.startsWith('http://') || source.startsWith('https://')) {
      await _player.play(UrlSource(source));
    } else {
      await _player.play(DeviceFileSource(source));
    }

    _isPlaying = true;

    return {
      'playing': true,
      'source': source,
    };
  }

  Future<Map<String, dynamic>> _pause() async {
    await _player.pause();
    _isPlaying = false;
    return {'paused': true};
  }

  Future<Map<String, dynamic>> _resume() async {
    await _player.resume();
    _isPlaying = true;
    return {'resumed': true};
  }

  Future<Map<String, dynamic>> _stop() async {
    await _player.stop();
    _isPlaying = false;
    return {'stopped': true};
  }

  Future<Map<String, dynamic>> _seek(Map<String, dynamic> args) async {
    final positionMs = (args['positionMs'] as num).toInt();
    await _player.seek(Duration(milliseconds: positionMs));
    return {'seeked': true, 'positionMs': positionMs};
  }

  Future<Map<String, dynamic>> _getDuration() async {
    final duration = await _player.getDuration();
    return {
      'durationMs': duration?.inMilliseconds ?? 0,
      'durationSec': duration?.inSeconds ?? 0,
    };
  }

  Future<Map<String, dynamic>> _getPosition() async {
    final position = await _player.getCurrentPosition();
    return {
      'positionMs': position?.inMilliseconds ?? 0,
      'positionSec': position?.inSeconds ?? 0,
    };
  }

  Future<Map<String, dynamic>> _setVolume(Map<String, dynamic> args) async {
    final volume = (args['volume'] as num).toDouble().clamp(0.0, 1.0);
    await _player.setVolume(volume);
    return {'volume': volume};
  }

  AudioEncoder _parseEncoder(String encoder) {
    switch (encoder) {
      case 'aacLc':
        return AudioEncoder.aacLc;
      case 'aacEld':
        return AudioEncoder.aacEld;
      case 'aacHe':
        return AudioEncoder.aacHe;
      case 'opus':
        return AudioEncoder.opus;
      case 'wav':
        return AudioEncoder.wav;
      case 'flac':
        return AudioEncoder.flac;
      default:
        return AudioEncoder.aacLc;
    }
  }

  @override
  Future<ValidationResult> validateArgs(
    String method,
    Map<String, dynamic> args,
  ) async {
    switch (method) {
      case 'play':
        final path = args['path'] ?? args['url'];
        if (path is! String || path.isEmpty) {
          return ValidationResult.invalid('path or url is required');
        }
        return ValidationResult.valid();

      case 'seek':
        final pos = args['positionMs'];
        if (pos is! num) {
          return ValidationResult.invalid('positionMs is required and must be a number');
        }
        return ValidationResult.valid();

      case 'setVolume':
        final vol = args['volume'];
        if (vol is! num) {
          return ValidationResult.invalid('volume is required and must be a number (0.0 - 1.0)');
        }
        return ValidationResult.valid();

      default:
        return ValidationResult.valid();
    }
  }
}
```

### 📄 `lib/plugins/audio/pubspec.yaml`

```yaml
name: audio_plugin
description: Audio recorder and player plugin
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
  record: ^5.1.2
  audioplayers: ^6.1.0
  path_provider: ^2.1.1
  path: ^1.9.0
```

---

## ۴) SMS / OTP Plugin

### 📄 `lib/plugins/sms_otp/lib/sms_otp_plugin.dart`

```dart
import 'dart:async';

import 'package:sms_autofill/sms_autofill.dart';
import 'package:sweetmelon/packages/core/lib/core.dart';
import 'package:sweetmelon/packages/plugin_engine/lib/plugin_engine.dart';

typedef SmsEventEmitter = Future<void> Function(String event, dynamic data);

class SmsOtpPlugin extends Plugin with CodeAutoFill {
  final SmsEventEmitter? eventEmitter;

  String? _appSignature;
  String? _lastCode;
  bool _listening = false;

  SmsOtpPlugin({this.eventEmitter});

  @override
  String get name => 'smsOtp';

  @override
  String get version => '1.0.0';

  @override
  String get description => 'SMS OTP auto-read plugin';

  @override
  List<String> get supportedMethods => [
        'getAppSignature',
        'startListening',
        'stopListening',
        'getLastCode',
        'requestHint',
        'getInfo',
      ];

  @override
  Future<void> onInitialize() async {
    try {
      _appSignature = await SmsAutoFill().getAppSignature;
      BridgeLogger.info('SmsOtp', 'App signature: $_appSignature');
    } catch (e) {
      BridgeLogger.warn('SmsOtp', 'Failed to get app signature: $e');
    }
  }

  @override
  Future<void> onDispose() async {
    cancel();
    unregisterListener();
    _listening = false;
  }

  @override
  void codeUpdated() {
    final code = this.code;

    if (code != null && code.isNotEmpty) {
      _lastCode = code;
      BridgeLogger.info('SmsOtp', 'Code received: $code');

      if (eventEmitter != null) {
        eventEmitter!('smsOtp.received', {
          'code': code,
          'timestamp': DateTime.now().toIso8601String(),
        });
      }
    }
  }

  @override
  Future<dynamic> onCall(String method, Map<String, dynamic> args) async {
    switch (method) {
      case 'getAppSignature':
        return {'signature': _appSignature};

      case 'startListening':
        return _startListening();

      case 'stopListening':
        return _stopListening();

      case 'getLastCode':
        return {'code': _lastCode};

      case 'requestHint':
        return _requestHint();

      case 'getInfo':
        return {
          'name': name,
          'version': version,
          'listening': _listening,
          'signature': _appSignature,
          'lastCode': _lastCode,
        };

      default:
        throw UnsupportedError('Method "$method" not supported');
    }
  }

  Future<Map<String, dynamic>> _startListening() async {
    if (_listening) {
      return {'listening': true, 'alreadyListening': true};
    }

    listenForCode();
    await SmsAutoFill().listenForCode();
    _listening = true;

    return {'listening': true, 'alreadyListening': false};
  }

  Future<Map<String, dynamic>> _stopListening() async {
    cancel();
    unregisterListener();
    _listening = false;

    return {'listening': false};
  }

  Future<Map<String, dynamic>> _requestHint() async {
    try {
      final hint = await SmsAutoFill().hint;
      return {'hint': hint};
    } catch (e) {
      BridgeLogger.warn('SmsOtp', 'Hint request failed: $e');
      return {'hint': null, 'error': e.toString()};
    }
  }
}
```

### 📄 `lib/plugins/sms_otp/pubspec.yaml`

```yaml
name: sms_otp_plugin
description: SMS OTP auto-read plugin
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
  sms_autofill: ^2.4.0
```

---

## ۵) Download Manager Plugin (با progress event)

### 📄 `lib/plugins/download_manager/lib/download_manager_plugin.dart`

```dart
import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sweetmelon/packages/core/lib/core.dart';
import 'package:sweetmelon/packages/plugin_engine/lib/plugin_engine.dart';

typedef DownloadEventEmitter = Future<void> Function(String event, dynamic data);

class DownloadManagerPlugin extends Plugin {
  final DownloadEventEmitter? eventEmitter;

  final Map<String, _DownloadTask> _activeTasks = {};

  DownloadManagerPlugin({this.eventEmitter});

  @override
  String get name => 'downloadManager';

  @override
  String get version => '1.0.0';

  @override
  String get description => 'Download manager with progress events';

  @override
  List<String> get supportedMethods => [
        'download',
        'cancel',
        'cancelAll',
        'getActive',
        'getInfo',
      ];

  @override
  Future<dynamic> onCall(String method, Map<String, dynamic> args) async {
    switch (method) {
      case 'download':
        return _download(args);
      case 'cancel':
        return _cancel(args);
      case 'cancelAll':
        return _cancelAll();
      case 'getActive':
        return _getActive();
      case 'getInfo':
        return {
          'name': name,
          'version': version,
          'activeDownloads': _activeTasks.length,
        };
      default:
        throw UnsupportedError('Method "$method" not supported');
    }
  }

  Future<Map<String, dynamic>> _download(Map<String, dynamic> args) async {
    final url = args['url'] as String;
    final uri = Uri.parse(url);
    final fileName = args['fileName'] as String? ?? _fileNameFromUri(uri);
    final baseDir = args['baseDir'] as String? ?? 'documents';
    final subPath = args['path'] as String? ?? 'downloads';
    final overwrite = args['overwrite'] as bool? ?? true;
    final taskId = args['taskId'] as String? ??
        'dl_${DateTime.now().millisecondsSinceEpoch}';

    final headers = _parseHeaders(args['headers']);

    final root = await _resolveBaseDir(baseDir);
    final outputPath = p.join(root.path, subPath, fileName);
    final outputFile = File(outputPath);

    if (await outputFile.exists() && !overwrite) {
      return {
        'taskId': taskId,
        'saved': false,
        'reason': 'already_exists',
        'path': outputPath,
      };
    }

    await outputFile.parent.create(recursive: true);

    final client = http.Client();
    final task = _DownloadTask(taskId: taskId, client: client);
    _activeTasks[taskId] = task;

    try {
      final request = http.Request('GET', uri);
      request.headers.addAll(headers);

      final response = await client.send(request);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        _activeTasks.remove(taskId);
        return {
          'taskId': taskId,
          'saved': false,
          'reason': 'http_error',
          'statusCode': response.statusCode,
        };
      }

      final totalBytes = response.contentLength ?? -1;
      var receivedBytes = 0;
      final sink = outputFile.openWrite();

      int lastProgressPercent = -1;

      await for (final chunk in response.stream) {
        if (task.cancelled) {
          await sink.close();
          if (await outputFile.exists()) {
            await outputFile.delete();
          }
          _activeTasks.remove(taskId);
          return {
            'taskId': taskId,
            'saved': false,
            'reason': 'cancelled',
          };
        }

        sink.add(chunk);
        receivedBytes += chunk.length;

        final percent = totalBytes > 0
            ? ((receivedBytes / totalBytes) * 100).round()
            : -1;

        if (percent != lastProgressPercent) {
          lastProgressPercent = percent;

          if (eventEmitter != null) {
            eventEmitter!('download.progress', {
              'taskId': taskId,
              'fileName': fileName,
              'receivedBytes': receivedBytes,
              'totalBytes': totalBytes,
              'percent': percent,
            });
          }
        }
      }

      await sink.flush();
      await sink.close();

      _activeTasks.remove(taskId);

      final mimeType = lookupMimeType(outputPath) ?? 'application/octet-stream';

      final result = {
        'taskId': taskId,
        'saved': true,
        'path': outputPath,
        'fileName': fileName,
        'size': receivedBytes,
        'mimeType': mimeType,
        'baseDir': baseDir,
      };

      if (eventEmitter != null) {
        eventEmitter!('download.complete', result);
      }

      return result;
    } catch (e) {
      _activeTasks.remove(taskId);
      BridgeLogger.error('DownloadManager', 'Download error: $e');

      if (eventEmitter != null) {
        eventEmitter!('download.error', {
          'taskId': taskId,
          'error': e.toString(),
        });
      }

      return {
        'taskId': taskId,
        'saved': false,
        'reason': 'error',
        'error': e.toString(),
      };
    } finally {
      client.close();
    }
  }

  Future<Map<String, dynamic>> _cancel(Map<String, dynamic> args) async {
    final taskId = args['taskId'] as String;
    final task = _activeTasks[taskId];

    if (task == null) {
      return {'taskId': taskId, 'cancelled': false, 'reason': 'not_found'};
    }

    task.cancelled = true;
    task.client.close();

    return {'taskId': taskId, 'cancelled': true};
  }

  Future<Map<String, dynamic>> _cancelAll() async {
    final count = _activeTasks.length;

    for (final task in _activeTasks.values) {
      task.cancelled = true;
      task.client.close();
    }

    _activeTasks.clear();
    return {'cancelled': count};
  }

  Map<String, dynamic> _getActive() {
    return {
      'count': _activeTasks.length,
      'tasks': _activeTasks.keys.toList(),
    };
  }

  Map<String, String> _parseHeaders(dynamic raw) {
    if (raw == null) return {};
    if (raw is Map) {
      return raw.map((k, v) => MapEntry(k.toString(), v.toString()));
    }
    return {};
  }

  String _fileNameFromUri(Uri uri) {
    final name = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : 'download.bin';
    return name.isEmpty ? 'download.bin' : name;
  }

  Future<Directory> _resolveBaseDir(String baseDir) async {
    switch (baseDir) {
      case 'documents':
        return getApplicationDocumentsDirectory();
      case 'cache':
        return getApplicationCacheDirectory();
      case 'temporary':
        return getTemporaryDirectory();
      default:
        return getApplicationDocumentsDirectory();
    }
  }

  @override
  Future<void> onDispose() async {
    await _cancelAll();
  }

  @override
  Future<ValidationResult> validateArgs(
    String method,
    Map<String, dynamic> args,
  ) async {
    switch (method) {
      case 'download':
        final url = args['url'];
        if (url is! String || url.isEmpty) {
          return ValidationResult.invalid('url is required');
        }
        return ValidationResult.valid();

      case 'cancel':
        final taskId = args['taskId'];
        if (taskId is! String || taskId.isEmpty) {
          return ValidationResult.invalid('taskId is required');
        }
        return ValidationResult.valid();

      default:
        return ValidationResult.valid();
    }
  }
}

class _DownloadTask {
  final String taskId;
  final http.Client client;
  bool cancelled;

  _DownloadTask({
    required this.taskId,
    required this.client,
    this.cancelled = false,
  });
}
```

### 📄 `lib/plugins/download_manager/pubspec.yaml`

```yaml
name: download_manager_plugin
description: Download manager with progress events
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
  mime: ^1.0.5
  path_provider: ^2.1.1
  path: ^1.9.0
```

---

## ۶) Database (SQLite) Plugin

### 📄 `lib/plugins/database/lib/database_plugin.dart`

```dart
import 'dart:async';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sweetmelon/packages/core/lib/core.dart';
import 'package:sweetmelon/packages/plugin_engine/lib/plugin_engine.dart';

class DatabasePlugin extends Plugin {
  final Map<String, Database> _databases = {};

  @override
  String get name => 'database';

  @override
  String get version => '1.0.0';

  @override
  String get description => 'SQLite database plugin';

  @override
  List<String> get supportedMethods => [
        'open',
        'close',
        'execute',
        'query',
        'insert',
        'update',
        'delete',
        'rawQuery',
        'rawInsert',
        'rawUpdate',
        'rawDelete',
        'batch',
        'tableExists',
        'getOpenDatabases',
        'deleteDatabase',
        'getInfo',
      ];

  @override
  Future<void> onDispose() async {
    for (final db in _databases.values) {
      if (db.isOpen) await db.close();
    }
    _databases.clear();
  }

  @override
  Future<dynamic> onCall(String method, Map<String, dynamic> args) async {
    switch (method) {
      case 'open':
        return _open(args);
      case 'close':
        return _close(args);
      case 'execute':
        return _execute(args);
      case 'query':
        return _query(args);
      case 'insert':
        return _insert(args);
      case 'update':
        return _update(args);
      case 'delete':
        return _deleteRows(args);
      case 'rawQuery':
        return _rawQuery(args);
      case 'rawInsert':
        return _rawInsert(args);
      case 'rawUpdate':
        return _rawUpdate(args);
      case 'rawDelete':
        return _rawDelete(args);
      case 'batch':
        return _batch(args);
      case 'tableExists':
        return _tableExists(args);
      case 'getOpenDatabases':
        return {'databases': _databases.keys.toList()};
      case 'deleteDatabase':
        return _deleteDatabase(args);
      case 'getInfo':
        return {
          'name': name,
          'version': version,
          'openDatabases': _databases.keys.toList(),
        };
      default:
        throw UnsupportedError('Method "$method" not supported');
    }
  }

  Future<Database> _getDb(String dbName) async {
    final db = _databases[dbName];
    if (db == null || !db.isOpen) {
      throw StateError('Database "$dbName" is not open');
    }
    return db;
  }

  Future<Map<String, dynamic>> _open(Map<String, dynamic> args) async {
    final dbName = args['name'] as String;
    final dbVersion = (args['version'] as num?)?.toInt() ?? 1;
    final createStatements = args['onCreate'] as List<dynamic>?;

    if (_databases.containsKey(dbName) && _databases[dbName]!.isOpen) {
      return {'opened': true, 'alreadyOpen': true, 'name': dbName};
    }

    final dir = await getApplicationDocumentsDirectory();
    final dbPath = p.join(dir.path, 'databases', '$dbName.db');

    final db = await openDatabase(
      dbPath,
      version: dbVersion,
      onCreate: (db, version) async {
        if (createStatements != null) {
          for (final stmt in createStatements) {
            if (stmt is String && stmt.trim().isNotEmpty) {
              await db.execute(stmt);
            }
          }
        }
      },
    );

    _databases[dbName] = db;
    BridgeLogger.info('Database', 'Opened: $dbName (v$dbVersion)');

    return {'opened': true, 'alreadyOpen': false, 'name': dbName, 'path': dbPath};
  }

  Future<Map<String, dynamic>> _close(Map<String, dynamic> args) async {
    final dbName = args['name'] as String;
    final db = _databases.remove(dbName);

    if (db != null && db.isOpen) {
      await db.close();
      return {'closed': true, 'name': dbName};
    }

    return {'closed': false, 'reason': 'not_open'};
  }

  Future<Map<String, dynamic>> _execute(Map<String, dynamic> args) async {
    final db = await _getDb(args['name'] as String);
    final sql = args['sql'] as String;
    final params = _parseParams(args['params']);

    await db.execute(sql, params);
    return {'executed': true};
  }

  Future<Map<String, dynamic>> _query(Map<String, dynamic> args) async {
    final db = await _getDb(args['name'] as String);
    final table = args['table'] as String;
    final where = args['where'] as String?;
    final whereArgs = _parseParams(args['whereArgs']);
    final orderBy = args['orderBy'] as String?;
    final limit = (args['limit'] as num?)?.toInt();
    final offset = (args['offset'] as num?)?.toInt();
    final columns = args['columns'] != null
        ? List<String>.from(args['columns'] as List)
        : null;

    final results = await db.query(
      table,
      columns: columns,
      where: where,
      whereArgs: whereArgs,
      orderBy: orderBy,
      limit: limit,
      offset: offset,
    );

    return {'rows': results, 'count': results.length};
  }

  Future<Map<String, dynamic>> _insert(Map<String, dynamic> args) async {
    final db = await _getDb(args['name'] as String);
    final table = args['table'] as String;
    final values = Map<String, dynamic>.from(args['values'] as Map);

    final id = await db.insert(table, values);
    return {'id': id, 'inserted': true};
  }

  Future<Map<String, dynamic>> _update(Map<String, dynamic> args) async {
    final db = await _getDb(args['name'] as String);
    final table = args['table'] as String;
    final values = Map<String, dynamic>.from(args['values'] as Map);
    final where = args['where'] as String?;
    final whereArgs = _parseParams(args['whereArgs']);

    final count = await db.update(table, values, where: where, whereArgs: whereArgs);
    return {'updated': count};
  }

  Future<Map<String, dynamic>> _deleteRows(Map<String, dynamic> args) async {
    final db = await _getDb(args['name'] as String);
    final table = args['table'] as String;
    final where = args['where'] as String?;
    final whereArgs = _parseParams(args['whereArgs']);

    final count = await db.delete(table, where: where, whereArgs: whereArgs);
    return {'deleted': count};
  }

  Future<Map<String, dynamic>> _rawQuery(Map<String, dynamic> args) async {
    final db = await _getDb(args['name'] as String);
    final sql = args['sql'] as String;
    final params = _parseParams(args['params']);

    final results = await db.rawQuery(sql, params);
    return {'rows': results, 'count': results.length};
  }

  Future<Map<String, dynamic>> _rawInsert(Map<String, dynamic> args) async {
    final db = await _getDb(args['name'] as String);
    final sql = args['sql'] as String;
    final params = _parseParams(args['params']);

    final id = await db.rawInsert(sql, params);
    return {'id': id};
  }

  Future<Map<String, dynamic>> _rawUpdate(Map<String, dynamic> args) async {
    final db = await _getDb(args['name'] as String);
    final sql = args['sql'] as String;
    final params = _parseParams(args['params']);

    final count = await db.rawUpdate(sql, params);
    return {'affected': count};
  }

  Future<Map<String, dynamic>> _rawDelete(Map<String, dynamic> args) async {
    final db = await _getDb(args['name'] as String);
    final sql = args['sql'] as String;
    final params = _parseParams(args['params']);

    final count = await db.rawDelete(sql, params);
    return {'affected': count};
  }

  Future<Map<String, dynamic>> _batch(Map<String, dynamic> args) async {
    final db = await _getDb(args['name'] as String);
    final statements = List<Map<String, dynamic>>.from(args['statements'] as List);

    final batch = db.batch();

    for (final stmt in statements) {
      final type = stmt['type'] as String;
      final sql = stmt['sql'] as String?;
      final table = stmt['table'] as String?;
      final values = stmt['values'] as Map<String, dynamic>?;
      final where = stmt['where'] as String?;
      final whereArgs = _parseParams(stmt['whereArgs']);

      switch (type) {
        case 'execute':
          if (sql != null) batch.execute(sql);
          break;
        case 'insert':
          if (table != null && values != null) batch.insert(table, values);
          break;
        case 'update':
          if (table != null && values != null) {
            batch.update(table, values, where: where, whereArgs: whereArgs);
          }
          break;
        case 'delete':
          if (table != null) {
            batch.delete(table, where: where, whereArgs: whereArgs);
          }
          break;
        case 'rawInsert':
          if (sql != null) batch.rawInsert(sql, _parseParams(stmt['params']));
          break;
        case 'rawUpdate':
          if (sql != null) batch.rawUpdate(sql, _parseParams(stmt['params']));
          break;
        case 'rawDelete':
          if (sql != null) batch.rawDelete(sql, _parseParams(stmt['params']));
          break;
      }
    }

    final results = await batch.commit();
    return {'results': results, 'count': results.length};
  }

  Future<Map<String, dynamic>> _tableExists(Map<String, dynamic> args) async {
    final db = await _getDb(args['name'] as String);
    final table = args['table'] as String;

    final result = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name=?",
      [table],
    );

    return {'exists': result.isNotEmpty, 'table': table};
  }

  Future<Map<String, dynamic>> _deleteDatabase(Map<String, dynamic> args) async {
    final dbName = args['name'] as String;

    // close first
    final db = _databases.remove(dbName);
    if (db != null && db.isOpen) await db.close();

    final dir = await getApplicationDocumentsDirectory();
    final dbPath = p.join(dir.path, 'databases', '$dbName.db');

    await databaseFactory.deleteDatabase(dbPath);

    return {'deleted': true, 'name': dbName};
  }

  List<dynamic>? _parseParams(dynamic raw) {
    if (raw == null) return null;
    if (raw is List) return raw;
    return null;
  }

  @override
  Future<ValidationResult> validateArgs(
    String method,
    Map<String, dynamic> args,
  ) async {
    final needsName = [
      'open', 'close', 'execute', 'query', 'insert', 'update',
      'delete', 'rawQuery', 'rawInsert', 'rawUpdate', 'rawDelete',
      'batch', 'tableExists', 'deleteDatabase',
    ];

    if (needsName.contains(method)) {
      final name = args['name'];
      if (name is! String || name.isEmpty) {
        return ValidationResult.invalid('name (database name) is required');
      }
    }

    switch (method) {
      case 'execute':
      case 'rawQuery':
      case 'rawInsert':
      case 'rawUpdate':
      case 'rawDelete':
        final sql = args['sql'];
        if (sql is! String || sql.isEmpty) {
          return ValidationResult.invalid('sql is required');
        }
        return ValidationResult.valid();

      case 'query':
      case 'delete':
        final table = args['table'];
        if (table is! String || table.isEmpty) {
          return ValidationResult.invalid('table is required');
        }
        return ValidationResult.valid();

      case 'insert':
      case 'update':
        final table = args['table'];
        if (table is! String || table.isEmpty) {
          return ValidationResult.invalid('table is required');
        }
        if (args['values'] is! Map) {
          return ValidationResult.invalid('values is required and must be a map');
        }
        return ValidationResult.valid();

      case 'tableExists':
        final table = args['table'];
        if (table is! String || table.isEmpty) {
          return ValidationResult.invalid('table is required');
        }
        return ValidationResult.valid();

      default:
        return ValidationResult.valid();
    }
  }
}
```

### 📄 `lib/plugins/database/pubspec.yaml`

```yaml
name: database_plugin
description: SQLite database plugin
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
  sqflite: ^2.3.3+2
  path_provider: ^2.1.1
  path: ^1.9.0
```

---

## ۷) Contacts Plugin

### 📄 `lib/plugins/contacts/lib/contacts_plugin.dart`

```dart
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:sweetmelon/packages/plugin_engine/lib/plugin_engine.dart';

class ContactsPlugin extends Plugin {
  @override
  String get name => 'contacts';

  @override
  String get version => '1.0.0';

  @override
  String get description => 'Contacts read plugin';

  @override
  List<String> get requiredPermissions => ['contacts'];

  @override
  List<String> get supportedMethods => [
        'getAll',
        'getById',
        'search',
        'getCount',
        'pickContact',
        'getInfo',
      ];

  @override
  Future<dynamic> onCall(String method, Map<String, dynamic> args) async {
    switch (method) {
      case 'getAll':
        return _getAll(args);
      case 'getById':
        return _getById(args);
      case 'search':
        return _search(args);
      case 'getCount':
        return _getCount();
      case 'pickContact':
        return _pickContact();
      case 'getInfo':
        return {
          'name': name,
          'version': version,
        };
      default:
        throw UnsupportedError('Method "$method" not supported');
    }
  }

  Future<Map<String, dynamic>> _getAll(Map<String, dynamic> args) async {
    final withProperties = args['withProperties'] as bool? ?? true;
    final withPhoto = args['withPhoto'] as bool? ?? false;
    final limit = (args['limit'] as num?)?.toInt();
    final offset = (args['offset'] as num?)?.toInt() ?? 0;

    final hasPermission = await FlutterContacts.requestPermission();
    if (!hasPermission) {
      return {'contacts': <dynamic>[], 'error': 'permission_denied'};
    }

    var contacts = await FlutterContacts.getContacts(
      withProperties: withProperties,
      withPhoto: withPhoto,
    );

    if (offset > 0 && offset < contacts.length) {
      contacts = contacts.sublist(offset);
    }

    if (limit != null && limit > 0 && limit < contacts.length) {
      contacts = contacts.sublist(0, limit);
    }

    return {
      'contacts': contacts.map(_contactToMap).toList(),
      'count': contacts.length,
    };
  }

  Future<Map<String, dynamic>> _getById(Map<String, dynamic> args) async {
    final id = args['id'] as String;

    final hasPermission = await FlutterContacts.requestPermission();
    if (!hasPermission) {
      return {'contact': null, 'error': 'permission_denied'};
    }

    final contact = await FlutterContacts.getContact(
      id,
      withProperties: true,
      withPhoto: false,
    );

    if (contact == null) {
      return {'contact': null, 'found': false};
    }

    return {'contact': _contactToMap(contact), 'found': true};
  }

  Future<Map<String, dynamic>> _search(Map<String, dynamic> args) async {
    final query = (args['query'] as String).toLowerCase().trim();

    final hasPermission = await FlutterContacts.requestPermission();
    if (!hasPermission) {
      return {'contacts': <dynamic>[], 'error': 'permission_denied'};
    }

    final allContacts = await FlutterContacts.getContacts(
      withProperties: true,
      withPhoto: false,
    );

    final filtered = allContacts.where((c) {
      final displayName = c.displayName.toLowerCase();
      if (displayName.contains(query)) return true;

      for (final phone in c.phones) {
        if (phone.number.replaceAll(RegExp(r'\s+'), '').contains(query)) {
          return true;
        }
      }

      for (final email in c.emails) {
        if (email.address.toLowerCase().contains(query)) return true;
      }

      return false;
    }).toList();

    return {
      'contacts': filtered.map(_contactToMap).toList(),
      'count': filtered.length,
      'query': query,
    };
  }

  Future<Map<String, dynamic>> _getCount() async {
    final hasPermission = await FlutterContacts.requestPermission();
    if (!hasPermission) {
      return {'count': 0, 'error': 'permission_denied'};
    }

    final contacts = await FlutterContacts.getContacts();
    return {'count': contacts.length};
  }

  Future<Map<String, dynamic>> _pickContact() async {
    final contact = await FlutterContacts.openExternalPick();

    if (contact == null) {
      return {'contact': null, 'picked': false};
    }

    return {'contact': _contactToMap(contact), 'picked': true};
  }

  Map<String, dynamic> _contactToMap(Contact contact) {
    return {
      'id': contact.id,
      'displayName': contact.displayName,
      'name': {
        'first': contact.name.first,
        'last': contact.name.last,
        'middle': contact.name.middle,
        'prefix': contact.name.prefix,
        'suffix': contact.name.suffix,
        'nickname': contact.name.nickname,
      },
      'phones': contact.phones.map((p) {
        return {
          'number': p.number,
          'label': p.label.name,
          'isPrimary': p.isPrimary,
        };
      }).toList(),
      'emails': contact.emails.map((e) {
        return {
          'address': e.address,
          'label': e.label.name,
          'isPrimary': e.isPrimary,
        };
      }).toList(),
      'organizations': contact.organizations.map((o) {
        return {
          'company': o.company,
          'title': o.title,
          'department': o.department,
        };
      }).toList(),
      'addresses': contact.addresses.map((a) {
        return {
          'address': a.address,
          'label': a.label.name,
        };
      }).toList(),
    };
  }

  @override
  Future<ValidationResult> validateArgs(
    String method,
    Map<String, dynamic> args,
  ) async {
    switch (method) {
      case 'getById':
        final id = args['id'];
        if (id is! String || id.isEmpty) {
          return ValidationResult.invalid('id is required');
        }
        return ValidationResult.valid();

      case 'search':
        final query = args['query'];
        if (query is! String || query.isEmpty) {
          return ValidationResult.invalid('query is required');
        }
        return ValidationResult.valid();

      default:
        return ValidationResult.valid();
    }
  }
}
```

### 📄 `lib/plugins/contacts/pubspec.yaml`

```yaml
name: contacts_plugin
description: Contacts read plugin
version: 1.0.0

environment:
  sdk: ^3.0.0

dependencies:
  flutter:
    sdk: flutter
  plugin_engine:
    path: ../../packages/plugin_engine
  flutter_contacts: ^1.1.9+2
```

---

## ۸) Phone Dialer Plugin

### 📄 `lib/plugins/phone_dialer/lib/phone_dialer_plugin.dart`

```dart
import 'package:url_launcher/url_launcher.dart';
import 'package:sweetmelon/packages/plugin_engine/lib/plugin_engine.dart';

class PhoneDialerPlugin extends Plugin {
  @override
  String get name => 'phoneDialer';

  @override
  String get version => '1.0.0';

  @override
  String get description => 'Phone dialer and call plugin';

  @override
  List<String> get supportedMethods => [
        'dial',
        'directCall',
        'canDial',
        'sendSms',
        'sendEmail',
        'getInfo',
      ];

  @override
  Future<dynamic> onCall(String method, Map<String, dynamic> args) async {
    switch (method) {
      case 'dial':
        return _dial(args);
      case 'directCall':
        return _directCall(args);
      case 'canDial':
        return _canDial(args);
      case 'sendSms':
        return _sendSms(args);
      case 'sendEmail':
        return _sendEmail(args);
      case 'getInfo':
        return {
          'name': name,
          'version': version,
          'supportedSchemes': ['tel', 'sms', 'smsto', 'mailto'],
        };
      default:
        throw UnsupportedError('Method "$method" not supported');
    }
  }

  Future<Map<String, dynamic>> _dial(Map<String, dynamic> args) async {
    final number = args['number'] as String;
    final cleanNumber = _cleanPhoneNumber(number);
    final uri = Uri.parse('tel:$cleanNumber');

    final launched = await launchUrl(uri);

    return {
      'opened': launched,
      'number': cleanNumber,
      'mode': 'dialer',
    };
  }

  Future<Map<String, dynamic>> _directCall(Map<String, dynamic> args) async {
    final number = args['number'] as String;
    final cleanNumber = _cleanPhoneNumber(number);
    final uri = Uri.parse('tel:$cleanNumber');

    final launched = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );

    return {
      'opened': launched,
      'number': cleanNumber,
      'mode': 'direct',
    };
  }

  Future<Map<String, dynamic>> _canDial(Map<String, dynamic> args) async {
    final number = args['number'] as String;
    final cleanNumber = _cleanPhoneNumber(number);
    final uri = Uri.parse('tel:$cleanNumber');

    final can = await canLaunchUrl(uri);

    return {
      'canDial': can,
      'number': cleanNumber,
    };
  }

  Future<Map<String, dynamic>> _sendSms(Map<String, dynamic> args) async {
    final number = args['number'] as String;
    final body = args['body'] as String? ?? '';
    final cleanNumber = _cleanPhoneNumber(number);

    final uri = Uri.parse('sms:$cleanNumber?body=${Uri.encodeComponent(body)}');
    final launched = await launchUrl(uri);

    return {
      'opened': launched,
      'number': cleanNumber,
      'type': 'sms',
    };
  }

  Future<Map<String, dynamic>> _sendEmail(Map<String, dynamic> args) async {
    final to = args['to'] as String;
    final subject = args['subject'] as String? ?? '';
    final body = args['body'] as String? ?? '';
    final cc = args['cc'] as String?;
    final bcc = args['bcc'] as String?;

    final params = <String, String>{};
    if (subject.isNotEmpty) params['subject'] = subject;
    if (body.isNotEmpty) params['body'] = body;
    if (cc != null && cc.isNotEmpty) params['cc'] = cc;
    if (bcc != null && bcc.isNotEmpty) params['bcc'] = bcc;

    final uri = Uri(
      scheme: 'mailto',
      path: to,
      queryParameters: params.isNotEmpty ? params : null,
    );

    final launched = await launchUrl(uri);

    return {
      'opened': launched,
      'to': to,
      'type': 'email',
    };
  }

  String _cleanPhoneNumber(String number) {
    return number.replaceAll(RegExp(r'[^\d+*#]'), '');
  }

  @override
  Future<ValidationResult> validateArgs(
    String method,
    Map<String, dynamic> args,
  ) async {
    switch (method) {
      case 'dial':
      case 'directCall':
      case 'canDial':
        final number = args['number'];
        if (number is! String || number.isEmpty) {
          return ValidationResult.invalid('number is required');
        }
        return ValidationResult.valid();

      case 'sendSms':
        final number = args['number'];
        if (number is! String || number.isEmpty) {
          return ValidationResult.invalid('number is required');
        }
        return ValidationResult.valid();

      case 'sendEmail':
        final to = args['to'];
        if (to is! String || to.isEmpty) {
          return ValidationResult.invalid('to (email) is required');
        }
        return ValidationResult.valid();

      default:
        return ValidationResult.valid();
    }
  }
}
```

### 📄 `lib/plugins/phone_dialer/pubspec.yaml`

```yaml
name: phone_dialer_plugin
description: Phone dialer and call plugin
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

# بخش ۴: بروزرسانی Service Locator

## 📄 `lib/di/service_locator.dart`

> فقط بخش import و `_registerPlugins` تغییر می‌کنه:

```dart
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';

import 'package:sweetmelon/packages/core/lib/core.dart';
import 'package:sweetmelon/packages/devtools/lib/devtools.dart';
import 'package:sweetmelon/packages/performance/lib/performance.dart';
import 'package:sweetmelon/packages/security/lib/security.dart';
import 'package:sweetmelon/packages/plugin_engine/lib/plugin_engine.dart';

// فاز ۱
import 'package:sweetmelon/plugins/permission/lib/permission_plugin.dart';
import 'package:sweetmelon/plugins/app_lifecycle/lib/app_lifecycle_plugin.dart';
import 'package:sweetmelon/plugins/device_info/lib/device_info_plugin.dart';
import 'package:sweetmelon/plugins/connectivity/lib/connectivity_plugin.dart';
import 'package:sweetmelon/plugins/storage/lib/storage_plugin.dart';
import 'package:sweetmelon/plugins/file_system/lib/file_system_plugin.dart';
import 'package:sweetmelon/plugins/http_native/lib/http_native_plugin.dart';
import 'package:sweetmelon/plugins/intent_link/lib/intent_link_plugin.dart';
import 'package:sweetmelon/plugins/clipboard/lib/clipboard_plugin.dart';
import 'package:sweetmelon/plugins/share/lib/share_plugin.dart';
import 'package:sweetmelon/plugins/geolocation/lib/geolocation_plugin.dart';
import 'package:sweetmelon/plugins/camera/lib/camera_plugin.dart';

// فاز ۳
import 'package:sweetmelon/plugins/back_button/lib/back_button_plugin.dart';
import 'package:sweetmelon/plugins/secure_storage/lib/secure_storage_plugin.dart';
import 'package:sweetmelon/plugins/notification/lib/notification_plugin.dart';
import 'package:sweetmelon/plugins/status_bar/lib/status_bar_plugin.dart';
import 'package:sweetmelon/plugins/orientation/lib/orientation_plugin.dart';
import 'package:sweetmelon/plugins/haptic/lib/haptic_plugin.dart';
import 'package:sweetmelon/plugins/keyboard/lib/keyboard_plugin.dart';

// فاز ۴
import 'package:sweetmelon/plugins/biometrics/lib/biometrics_plugin.dart';
import 'package:sweetmelon/plugins/qr_scanner/lib/qr_scanner_plugin.dart';
import 'package:sweetmelon/plugins/audio/lib/audio_plugin.dart';
import 'package:sweetmelon/plugins/sms_otp/lib/sms_otp_plugin.dart';
import 'package:sweetmelon/plugins/download_manager/lib/download_manager_plugin.dart';
import 'package:sweetmelon/plugins/database/lib/database_plugin.dart';
import 'package:sweetmelon/plugins/contacts/lib/contacts_plugin.dart';
import 'package:sweetmelon/plugins/phone_dialer/lib/phone_dialer_plugin.dart';

final sl = GetIt.instance;

class ServiceLocator {
  static bool _initializing = false;

  static Future<void> init() async {
    if (sl.isRegistered<MessageBridge>()) return;
    if (_initializing) return;
    _initializing = true;

    try {
      sl.registerLazySingleton<CacheManager>(
        () => CacheManager(maxEntries: 500),
      );

      sl.registerLazySingleton<RateLimiter>(() {
        final limiter = RateLimiter();
        limiter.setDefaultRule(RateLimitRule.perSecond(50));
        limiter.addRule('geolocation.getCurrentPosition', RateLimitRule.perSecond(5));
        limiter.addRule('camera.takePhoto', RateLimitRule.perSecond(3));
        limiter.addRule('qrScanner.scan', RateLimitRule.perSecond(2));
        return limiter;
      });

      sl.registerLazySingleton<ExecutionGuard>(
        () => ExecutionGuard(defaultTimeoutMs: 30000),
      );

      sl.registerLazySingleton<PermissionManager>(() {
        final manager = PermissionManager(cacheTtl: const Duration(minutes: 3));
        manager.setProvider(NativePermissionProvider(
          fallbackStatus: kReleaseMode ? PermissionStatus.denied : PermissionStatus.granted,
        ));
        manager.addPolicy('camera', const PermissionPolicy(required: ['camera']));
        manager.addPolicy('geolocation', const PermissionPolicy(required: ['location']));
        manager.addPolicy('contacts', const PermissionPolicy(required: ['contacts']));
        manager.addPolicy('audio', const PermissionPolicy(required: ['microphone']));
        return manager;
      });

      sl.registerLazySingleton<PluginRegistry>(() => PluginRegistry());

      sl.registerLazySingleton<PluginManager>(() => PluginManager(
            registry: sl<PluginRegistry>(),
            permissionManager: sl<PermissionManager>(),
            rateLimiter: sl<RateLimiter>(),
            executionGuard: sl<ExecutionGuard>(),
            cacheManager: sl<CacheManager>(),
          ));

      sl.registerLazySingleton<MessageBridge>(() {
        final bridge = MessageBridge();
        final manager = sl<PluginManager>();
        bridge.setMessageHandler(manager.execute);
        bridge.setBatchHandler(manager.executeBatch);
        return bridge;
      });

      final bridge = sl<MessageBridge>();
      sl<PluginRegistry>().setEventEmitter(bridge.emitEvent);

      sl.registerLazySingleton<WebViewHostConfig>(
        () => kReleaseMode ? WebViewHostConfig.production() : WebViewHostConfig.development(),
      );

      sl.registerLazySingleton<AssetServerConfig>(() => const AssetServerConfig());

      sl.registerLazySingleton<BridgeInspector>(
        () => BridgeInspector(bridge: bridge, manager: sl<PluginManager>()),
      );

      await _registerPlugins();
    } finally {
      _initializing = false;
    }
  }

  static Future<void> _registerPlugins() async {
    final registry = sl<PluginRegistry>();
    final emitter = registry.emitEvent;

    // ── فاز ۱ ──
    await registry.register(PermissionPlugin(permissionManager: sl<PermissionManager>()));
    await registry.register(AppLifecyclePlugin(eventEmitter: emitter));
    await registry.register(DeviceInfoBridgePlugin());
    await registry.register(ConnectivityBridgePlugin(eventEmitter: emitter));
    await registry.register(StoragePlugin());
    await registry.register(FileSystemPlugin());
    await registry.register(HttpNativePlugin());
    await registry.register(IntentLinkPlugin(eventEmitter: emitter));
    await registry.register(ClipboardPlugin());
    await registry.register(ShareBridgePlugin());
    await registry.register(CameraPlugin());
    await registry.register(GeolocationPlugin(eventEmitter: emitter));

    // ── فاز ۳ ──
    await registry.register(BackButtonPlugin(eventEmitter: emitter));
    await registry.register(SecureStoragePlugin());
    await registry.register(NotificationPlugin(eventEmitter: emitter));
    await registry.register(StatusBarPlugin());
    await registry.register(OrientationPlugin());
    await registry.register(HapticPlugin());
    await registry.register(KeyboardPlugin(eventEmitter: emitter));

    // ── فاز ۴ ──
    await registry.register(BiometricsPlugin());
    await registry.register(QrScannerPlugin(eventEmitter: emitter));
    await registry.register(AudioPlugin(eventEmitter: emitter));
    await registry.register(SmsOtpPlugin(eventEmitter: emitter));
    await registry.register(DownloadManagerPlugin(eventEmitter: emitter));
    await registry.register(DatabasePlugin());
    await registry.register(ContactsPlugin());
    await registry.register(PhoneDialerPlugin());
  }

  static Future<void> dispose() async {
    if (sl.isRegistered<BridgeInspector>()) sl<BridgeInspector>().dispose();
    if (sl.isRegistered<PluginManager>()) sl<PluginManager>().dispose();
    if (sl.isRegistered<PluginRegistry>()) await sl<PluginRegistry>().dispose();
    if (sl.isRegistered<CacheManager>()) sl<CacheManager>().dispose();
    if (sl.isRegistered<MessageBridge>()) sl<MessageBridge>().dispose();
    await sl.reset();
  }
}
```

---

# بخش ۵: بروزرسانی `app.dart` برای QR Scanner

## 📄 `lib/app.dart`

```dart
import 'package:flutter/material.dart';
import 'package:sweetmelon/plugins/qr_scanner/lib/qr_scanner_plugin.dart';
import 'screens/home_screen.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class BridgeApp extends StatelessWidget {
  const BridgeApp({super.key});

  @override
  Widget build(BuildContext context) {
    // QR Scanner needs navigator context
    QrScannerPlugin.navigatorKey = navigatorKey;

    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Flutter Native Bridge',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF6C63FF),
          secondary: Color(0xFF03DAC6),
        ),
        scaffoldBackgroundColor: const Color(0xFF0A0A1A),
      ),
      home: const HomeScreen(),
    );
  }
}
```

---

# بخش ۶: بروزرسانی NativeSDK — فقط بخش فاز ۴

> این بلوک‌ها باید به آخر object `sdk` در `native-sdk.js` اضافه بشن (قبل از `global.NativeSDK = sdk;`):

## 📄 اضافه شدن به `assets/www/js/native-sdk.js`

```javascript
    /* ───── فاز ۴ ───── */

    biometrics: {
      isAvailable: function () { return call('biometrics', 'isAvailable', {}); },
      getAvailableBiometrics: function () { return call('biometrics', 'getAvailableBiometrics', {}); },
      authenticate: function (options) { return call('biometrics', 'authenticate', options || {}); },
      getInfo: function () { return call('biometrics', 'getInfo', {}); }
    },

    qrScanner: {
      scan: function (options) { return call('qrScanner', 'scan', options || {}, { timeout: 90000 }); },
      getInfo: function () { return call('qrScanner', 'getInfo', {}); }
    },

    audio: {
      startRecording: function (o) { return call('audio', 'startRecording', o || {}); },
      stopRecording: function () { return call('audio', 'stopRecording', {}); },
      isRecording: function () { return call('audio', 'isRecording', {}); },
      play: function (o) { return call('audio', 'play', o || {}); },
      pause: function () { return call('audio', 'pause', {}); },
      resume: function () { return call('audio', 'resume', {}); },
      stop: function () { return call('audio', 'stop', {}); },
      seek: function (ms) { return call('audio', 'seek', { positionMs: ms }); },
      isPlaying: function () { return call('audio', 'isPlaying', {}); },
      getDuration: function () { return call('audio', 'getDuration', {}); },
      getPosition: function () { return call('audio', 'getPosition', {}); },
      setVolume: function (v) { return call('audio', 'setVolume', { volume: v }); },
      getInfo: function () { return call('audio', 'getInfo', {}); }
    },

    smsOtp: {
      getAppSignature: function () { return call('smsOtp', 'getAppSignature', {}); },
      startListening: function () { return call('smsOtp', 'startListening', {}); },
      stopListening: function () { return call('smsOtp', 'stopListening', {}); },
      getLastCode: function () { return call('smsOtp', 'getLastCode', {}); },
      requestHint: function () { return call('smsOtp', 'requestHint', {}); },
      getInfo: function () { return call('smsOtp', 'getInfo', {}); }
    },

    downloadManager: {
      download: function (o) { return call('downloadManager', 'download', o || {}, { timeout: 300000 }); },
      cancel: function (taskId) { return call('downloadManager', 'cancel', { taskId: taskId }); },
      cancelAll: function () { return call('downloadManager', 'cancelAll', {}); },
      getActive: function () { return call('downloadManager', 'getActive', {}); },
      getInfo: function () { return call('downloadManager', 'getInfo', {}); }
    },

    database: {
      open: function (name, options) { var o = options || {}; return call('database', 'open', { name: name, version: o.version || 1, onCreate: o.onCreate || null }); },
      close: function (name) { return call('database', 'close', { name: name }); },
      execute: function (name, sql, params) { return call('database', 'execute', { name: name, sql: sql, params: params || null }); },
      query: function (name, table, options) { var o = options || {}; return call('database', 'query', Object.assign({ name: name, table: table }, o)); },
      insert: function (name, table, values) { return call('database', 'insert', { name: name, table: table, values: values }); },
      update: function (name, table, values, options) { var o = options || {}; return call('database', 'update', { name: name, table: table, values: values, where: o.where || null, whereArgs: o.whereArgs || null }); },
      delete: function (name, table, options) { var o = options || {}; return call('database', 'delete', { name: name, table: table, where: o.where || null, whereArgs: o.whereArgs || null }); },
      rawQuery: function (name, sql, params) { return call('database', 'rawQuery', { name: name, sql: sql, params: params || null }); },
      rawInsert: function (name, sql, params) { return call('database', 'rawInsert', { name: name, sql: sql, params: params || null }); },
      rawUpdate: function (name, sql, params) { return call('database', 'rawUpdate', { name: name, sql: sql, params: params || null }); },
      rawDelete: function (name, sql, params) { return call('database', 'rawDelete', { name: name, sql: sql, params: params || null }); },
      batch: function (name, statements) { return call('database', 'batch', { name: name, statements: statements }); },
      tableExists: function (name, table) { return call('database', 'tableExists', { name: name, table: table }); },
      getOpenDatabases: function () { return call('database', 'getOpenDatabases', {}); },
      deleteDatabase: function (name) { return call('database', 'deleteDatabase', { name: name }); },
      getInfo: function () { return call('database', 'getInfo', {}); }
    },

    contacts: {
      getAll: function (o) { return call('contacts', 'getAll', o || {}); },
      getById: function (id) { return call('contacts', 'getById', { id: id }); },
      search: function (query) { return call('contacts', 'search', { query: query }); },
      getCount: function () { return call('contacts', 'getCount', {}); },
      pickContact: function () { return call('contacts', 'pickContact', {}); },
      getInfo: function () { return call('contacts', 'getInfo', {}); }
    },

    phoneDialer: {
      dial: function (number) { return call('phoneDialer', 'dial', { number: number }); },
      directCall: function (number) { return call('phoneDialer', 'directCall', { number: number }); },
      canDial: function (number) { return call('phoneDialer', 'canDial', { number: number }); },
      sendSms: function (number, body) { return call('phoneDialer', 'sendSms', { number: number, body: body || '' }); },
      sendEmail: function (options) { return call('phoneDialer', 'sendEmail', options || {}); },
      getInfo: function () { return call('phoneDialer', 'getInfo', {}); }
    }
```

---

# بخش ۷: پنل‌های HTML تست فاز ۴

> اضافه شدن به `index.html` قبل از پنل Output:

```html
  <!-- ───── فاز ۴ ───── -->

  <!-- Biometrics -->
  <section class="panel"><div class="panel-title">Biometrics</div>
    <div class="row">
      <button id="btnBioAvailable">Is Available</button>
      <button id="btnBioTypes">Available Types</button>
      <button id="btnBioAuth">Authenticate</button>
      <button id="btnBioInfo">Info</button>
    </div>
  </section>

  <!-- QR Scanner -->
  <section class="panel"><div class="panel-title">QR / Barcode Scanner</div>
    <div class="row">
      <button id="btnQrScan">Scan</button>
      <button id="btnQrInfo">Info</button>
    </div>
  </section>

  <!-- Audio -->
  <section class="panel"><div class="panel-title">Audio</div>
    <div class="row">
      <button id="btnAudioRecord">Start Record</button>
      <button id="btnAudioStopRecord">Stop Record</button>
      <button id="btnAudioPlay">Play Last</button>
      <button id="btnAudioPause">Pause</button>
      <button id="btnAudioResume">Resume</button>
      <button id="btnAudioStop">Stop</button>
      <button id="btnAudioInfo">Info</button>
    </div>
  </section>

  <!-- SMS OTP -->
  <section class="panel"><div class="panel-title">SMS / OTP</div>
    <div class="row">
      <button id="btnSmsSignature">App Signature</button>
      <button id="btnSmsListen">Start Listen</button>
      <button id="btnSmsStop">Stop Listen</button>
      <button id="btnSmsLastCode">Last Code</button>
      <button id="btnSmsHint">Request Hint</button>
      <button id="btnSmsInfo">Info</button>
    </div>
  </section>

  <!-- Download Manager -->
  <section class="panel"><div class="panel-title">Download Manager</div>
    <div class="row">
      <input id="downloadUrl" value="https://speed.hetzner.de/100MB.bin" placeholder="download url" />
    </div>
    <div class="row">
      <button id="btnDlStart">Download</button>
      <button id="btnDlCancelAll">Cancel All</button>
      <button id="btnDlActive">Active</button>
      <button id="btnDlInfo">Info</button>
    </div>
  </section>

  <!-- Database -->
  <section class="panel"><div class="panel-title">Database (SQLite)</div>
    <div class="row">
      <button id="btnDbOpen">Open</button>
      <button id="btnDbInsert">Insert</button>
      <button id="btnDbQuery">Query All</button>
      <button id="btnDbUpdate">Update</button>
      <button id="btnDbDelete">Delete</button>
      <button id="btnDbDrop">Drop DB</button>
      <button id="btnDbInfo">Info</button>
    </div>
  </section>

  <!-- Contacts -->
  <section class="panel"><div class="panel-title">Contacts</div>
    <div class="row">
      <input id="contactQuery" value="" placeholder="search query" />
    </div>
    <div class="row">
      <button id="btnContactCount">Count</button>
      <button id="btnContactAll">Get All (10)</button>
      <button id="btnContactSearch">Search</button>
      <button id="btnContactPick">Pick Contact</button>
      <button id="btnContactInfo">Info</button>
    </div>
  </section>

  <!-- Phone Dialer -->
  <section class="panel"><div class="panel-title">Phone Dialer</div>
    <div class="row">
      <input id="phoneNumber" value="+989123456789" placeholder="phone number" />
      <input id="emailTo" value="test@example.com" placeholder="email" />
    </div>
    <div class="row">
      <button id="btnPhoneDial">Dial</button>
      <button id="btnPhoneCall">Direct Call</button>
      <button id="btnPhoneSms">SMS</button>
      <button id="btnPhoneEmail">Email</button>
      <button id="btnPhoneCanDial">Can Dial?</button>
      <button id="btnPhoneInfo">Info</button>
    </div>
  </section>
```

---

# بخش ۸: بروزرسانی `app.js` — فاز ۴ bindings

> اضافه شدن به تابع `bind()` در `app.js`:

```javascript
    // ── فاز ۴ ──

    // Biometrics
    $('btnBioAvailable').onclick = function () { run('bio.isAvailable', function () { return S.biometrics.isAvailable(); }); };
    $('btnBioTypes').onclick = function () { run('bio.types', function () { return S.biometrics.getAvailableBiometrics(); }); };
    $('btnBioAuth').onclick = function () { run('bio.authenticate', function () { return S.biometrics.authenticate({ reason: 'Please verify your identity' }); }); };
    $('btnBioInfo').onclick = function () { run('bio.info', function () { return S.biometrics.getInfo(); }); };

    // QR
    $('btnQrScan').onclick = function () { run('qr.scan', function () { return S.qrScanner.scan({ timeoutMs: 60000 }); }); };
    $('btnQrInfo').onclick = function () { run('qr.info', function () { return S.qrScanner.getInfo(); }); };

    // Audio
    var lastRecPath = null;
    $('btnAudioRecord').onclick = function () { run('audio.record', function () { return S.audio.startRecording(); }); };
    $('btnAudioStopRecord').onclick = async function () {
      var r = await run('audio.stopRecord', function () { return S.audio.stopRecording(); });
      if (r && r.path) lastRecPath = r.path;
    };
    $('btnAudioPlay').onclick = function () {
      run('audio.play', function () {
        return S.audio.play({ path: lastRecPath || '', url: lastRecPath ? null : 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3' });
      });
    };
    $('btnAudioPause').onclick = function () { run('audio.pause', function () { return S.audio.pause(); }); };
    $('btnAudioResume').onclick = function () { run('audio.resume', function () { return S.audio.resume(); }); };
    $('btnAudioStop').onclick = function () { run('audio.stop', function () { return S.audio.stop(); }); };
    $('btnAudioInfo').onclick = function () { run('audio.info', function () { return S.audio.getInfo(); }); };

    // SMS OTP
    $('btnSmsSignature').onclick = function () { run('sms.signature', function () { return S.smsOtp.getAppSignature(); }); };
    $('btnSmsListen').onclick = function () { run('sms.listen', function () { return S.smsOtp.startListening(); }); };
    $('btnSmsStop').onclick = function () { run('sms.stop', function () { return S.smsOtp.stopListening(); }); };
    $('btnSmsLastCode').onclick = function () { run('sms.lastCode', function () { return S.smsOtp.getLastCode(); }); };
    $('btnSmsHint').onclick = function () { run('sms.hint', function () { return S.smsOtp.requestHint(); }); };
    $('btnSmsInfo').onclick = function () { run('sms.info', function () { return S.smsOtp.getInfo(); }); };

    // Download Manager
    $('btnDlStart').onclick = function () {
      run('dl.download', function () {
        return S.downloadManager.download({
          url: $('downloadUrl').value.trim(),
          fileName: 'test-download.bin',
          baseDir: 'temporary'
        });
      });
    };
    $('btnDlCancelAll').onclick = function () { run('dl.cancelAll', function () { return S.downloadManager.cancelAll(); }); };
    $('btnDlActive').onclick = function () { run('dl.active', function () { return S.downloadManager.getActive(); }); };
    $('btnDlInfo').onclick = function () { run('dl.info', function () { return S.downloadManager.getInfo(); }); };

    // Database
    $('btnDbOpen').onclick = function () {
      run('db.open', function () {
        return S.database.open('testdb', {
          version: 1,
          onCreate: [
            'CREATE TABLE IF NOT EXISTS users (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, email TEXT, age INTEGER, created_at TEXT DEFAULT CURRENT_TIMESTAMP)'
          ]
        });
      });
    };
    $('btnDbInsert').onclick = function () {
      run('db.insert', function () {
        return S.database.insert('testdb', 'users', {
          name: 'User ' + Math.floor(Math.random() * 1000),
          email: 'user@example.com',
          age: Math.floor(Math.random() * 50) + 18
        });
      });
    };
    $('btnDbQuery').onclick = function () { run('db.query', function () { return S.database.query('testdb', 'users', { orderBy: 'id DESC', limit: 20 }); }); };
    $('btnDbUpdate').onclick = function () {
      run('db.update', function () {
        return S.database.update('testdb', 'users', { name: 'Updated User' }, { where: 'id = ?', whereArgs: [1] });
      });
    };
    $('btnDbDelete').onclick = function () {
      run('db.delete', function () {
        return S.database.delete('testdb', 'users', { where: 'id = ?', whereArgs: [1] });
      });
    };
    $('btnDbDrop').onclick = function () { run('db.drop', function () { return S.database.deleteDatabase('testdb'); }); };
    $('btnDbInfo').onclick = function () { run('db.info', function () { return S.database.getInfo(); }); };

    // Contacts
    $('btnContactCount').onclick = function () { run('contacts.count', function () { return S.contacts.getCount(); }); };
    $('btnContactAll').onclick = function () { run('contacts.all', function () { return S.contacts.getAll({ limit: 10, withPhoto: false }); }); };
    $('btnContactSearch').onclick = function () { run('contacts.search', function () { return S.contacts.search($('contactQuery').value.trim()); }); };
    $('btnContactPick').onclick = function () { run('contacts.pick', function () { return S.contacts.pickContact(); }); };
    $('btnContactInfo').onclick = function () { run('contacts.info', function () { return S.contacts.getInfo(); }); };

    // Phone Dialer
    $('btnPhoneDial').onclick = function () { run('phone.dial', function () { return S.phoneDialer.dial($('phoneNumber').value.trim()); }); };
    $('btnPhoneCall').onclick = function () { run('phone.call', function () { return S.phoneDialer.directCall($('phoneNumber').value.trim()); }); };
    $('btnPhoneSms').onclick = function () { run('phone.sms', function () { return S.phoneDialer.sendSms($('phoneNumber').value.trim(), 'Hello from Sweetmelon'); }); };
    $('btnPhoneEmail').onclick = function () { run('phone.email', function () { return S.phoneDialer.sendEmail({ to: $('emailTo').value.trim(), subject: 'Hello', body: 'Sent from Sweetmelon bridge' }); }); };
    $('btnPhoneCanDial').onclick = function () { run('phone.canDial', function () { return S.phoneDialer.canDial($('phoneNumber').value.trim()); }); };
    $('btnPhoneInfo').onclick = function () { run('phone.info', function () { return S.phoneDialer.getInfo(); }); };
```

> و eventهای جدید در `bindEvents()`:

```javascript
    // فاز ۴ events
    var phase4Events = [
      'qrScanner.scanned',
      'audio.playerState',
      'audio.position',
      'smsOtp.received',
      'download.progress',
      'download.complete',
      'download.error'
    ];

    phase4Events.forEach(function (ev) {
      S.on(ev, function (data) {
        eventCount++;
        var msg = JSON.stringify(data);
        if (msg.length > 120) msg = msg.substring(0, 120) + '...';
        log('EVENT ' + ev + ' → ' + msg, 'event');
        updateStats();
      });
    });
```

---

# خلاصه فاز ۴

## مجموع پلاگین‌ها: **27 عدد**

| # | پلاگین | فاز | Eventها |
|---|--------|------|---------|
| 1 | permission | ۱ | — |
| 2 | appLifecycle | ۱ | app.lifecycle.change |
| 3 | deviceInfo | ۱ | — |
| 4 | connectivity | ۱ | connectivity.change, connectivity.error |
| 5 | storage | ۱ | — |
| 6 | fileSystem | ۱ | — |
| 7 | http | ۱ | — |
| 8 | intent | ۱ | intent.deepLink, intent.error |
| 9 | clipboard | ۱ | — |
| 10 | share | ۱ | — |
| 11 | camera | ۱ | — |
| 12 | geolocation | ۱ | geolocation.position, geolocation.error |
| 13 | backButton | ۳ | backButton.pressed |
| 14 | secureStorage | ۳ | — |
| 15 | notification | ۳ | notification.tap |
| 16 | statusBar | ۳ | — |
| 17 | orientation | ۳ | — |
| 18 | haptic | ۳ | — |
| 19 | keyboard | ۳ | keyboard.change |
| 20 | biometrics | ۴ | — |
| 21 | qrScanner | ۴ | qrScanner.scanned |
| 22 | audio | ۴ | audio.playerState, audio.position |
| 23 | smsOtp | ۴ | smsOtp.received |
| 24 | downloadManager | ۴ | download.progress, download.complete, download.error |
| 25 | database | ۴ | — |
| 26 | contacts | ۴ | — |
| 27 | phoneDialer | ۴ | — |

---

اگر بخواهی، در فاز بعدی من می‌تونم اینها رو اضافه کنم:

1. **Bluetooth BLE Plugin**
2. **NFC Plugin**
3. **Speech To Text Plugin**
4. **Text To Speech Plugin**
5. **Video Player Plugin**
6. **In-App Browser Plugin**
7. **PDF Viewer/Generator Plugin**
8. **Encryption Plugin**

بگو تا ادامه بدم.
