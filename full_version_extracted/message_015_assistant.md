

# فاز ۵ — ۸ پلاگین تخصصی پیشرفته

---

# بخش ۱: بروزرسانی `pubspec.yaml`

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

  # فاز ۵
  flutter_blue_plus: ^1.32.12
  nfc_manager: ^3.5.0
  speech_to_text: ^7.0.0
  flutter_tts: ^4.0.2
  video_player: ^2.9.2
  flutter_inappwebview: ^6.1.5
  pdf: ^3.11.1
  printing: ^5.13.3
  encrypt: ^5.0.3
  pointycastle: ^3.9.1
  convert: ^3.1.1

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

# بخش ۲: بروزرسانی AndroidManifest

## 📄 `android/app/src/main/AndroidManifest.xml`

> فقط permission‌های جدید اضافه شدن:

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

    <!-- SMS -->
    <uses-permission android:name="android.permission.RECEIVE_SMS"/>
    <uses-permission android:name="android.permission.READ_SMS"/>

    <!-- Contacts -->
    <uses-permission android:name="android.permission.READ_CONTACTS"/>
    <uses-permission android:name="android.permission.WRITE_CONTACTS"/>

    <!-- Phone -->
    <uses-permission android:name="android.permission.CALL_PHONE"/>
    <uses-permission android:name="android.permission.READ_PHONE_STATE"/>
    <uses-permission android:name="android.permission.READ_CALL_LOG"/>

    <!-- Bluetooth -->
    <uses-permission android:name="android.permission.BLUETOOTH"/>
    <uses-permission android:name="android.permission.BLUETOOTH_ADMIN"/>
    <uses-permission android:name="android.permission.BLUETOOTH_SCAN"/>
    <uses-permission android:name="android.permission.BLUETOOTH_CONNECT"/>
    <uses-permission android:name="android.permission.BLUETOOTH_ADVERTISE"/>

    <!-- NFC -->
    <uses-permission android:name="android.permission.NFC"/>
    <uses-feature android:name="android.hardware.nfc" android:required="false"/>

    <!-- Vibrate -->
    <uses-permission android:name="android.permission.VIBRATE"/>

    <!-- Foreground service -->
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

            <!-- NFC intent -->
            <intent-filter>
                <action android:name="android.nfc.action.NDEF_DISCOVERED"/>
                <category android:name="android.intent.category.DEFAULT"/>
                <data android:mimeType="text/plain"/>
            </intent-filter>
        </activity>

        <meta-data android:name="flutterEmbedding" android:value="2"/>

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
        <intent><action android:name="android.intent.action.PROCESS_TEXT"/><data android:mimeType="text/plain"/></intent>
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

## ۱) Bluetooth BLE Plugin

### 📄 `lib/plugins/bluetooth/lib/bluetooth_plugin.dart`

```dart
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:sweetmelon/packages/core/lib/core.dart';
import 'package:sweetmelon/packages/plugin_engine/lib/plugin_engine.dart';

typedef BleEventEmitter = Future<void> Function(String event, dynamic data);

class BluetoothPlugin extends Plugin {
  final BleEventEmitter? eventEmitter;

  StreamSubscription<List<ScanResult>>? _scanSub;
  StreamSubscription<BluetoothConnectionState>? _connectionSub;
  final Map<String, BluetoothDevice> _connectedDevices = {};
  bool _scanning = false;

  BluetoothPlugin({this.eventEmitter});

  @override
  String get name => 'bluetooth';

  @override
  String get version => '1.0.0';

  @override
  String get description => 'Bluetooth Low Energy (BLE) plugin';

  @override
  List<String> get requiredPermissions => ['bluetooth'];

  @override
  List<String> get supportedMethods => [
        'isAvailable',
        'isOn',
        'startScan',
        'stopScan',
        'connect',
        'disconnect',
        'discoverServices',
        'readCharacteristic',
        'writeCharacteristic',
        'getConnectedDevices',
        'getInfo',
      ];

  @override
  Future<void> onDispose() async {
    await _scanSub?.cancel();
    await _connectionSub?.cancel();
    for (final device in _connectedDevices.values) {
      try {
        await device.disconnect();
      } catch (_) {}
    }
    _connectedDevices.clear();
  }

  @override
  Future<dynamic> onCall(String method, Map<String, dynamic> args) async {
    switch (method) {
      case 'isAvailable':
        return _isAvailable();
      case 'isOn':
        return _isOn();
      case 'startScan':
        return _startScan(args);
      case 'stopScan':
        return _stopScan();
      case 'connect':
        return _connect(args);
      case 'disconnect':
        return _disconnect(args);
      case 'discoverServices':
        return _discoverServices(args);
      case 'readCharacteristic':
        return _readCharacteristic(args);
      case 'writeCharacteristic':
        return _writeCharacteristic(args);
      case 'getConnectedDevices':
        return _getConnectedDevices();
      case 'getInfo':
        return {
          'name': name,
          'version': version,
          'scanning': _scanning,
          'connectedDevices': _connectedDevices.keys.toList(),
        };
      default:
        throw UnsupportedError('Method "$method" not supported');
    }
  }

  Future<Map<String, dynamic>> _isAvailable() async {
    final supported = await FlutterBluePlus.isSupported;
    return {'available': supported};
  }

  Future<Map<String, dynamic>> _isOn() async {
    final state = await FlutterBluePlus.adapterState.first;
    return {
      'on': state == BluetoothAdapterState.on,
      'state': state.name,
    };
  }

  Future<Map<String, dynamic>> _startScan(Map<String, dynamic> args) async {
    if (_scanning) {
      return {'scanning': true, 'alreadyScanning': true};
    }

    final timeoutSec = (args['timeoutSeconds'] as num?)?.toInt() ?? 10;

    _scanning = true;

    _scanSub = FlutterBluePlus.onScanResults.listen((results) {
      for (final result in results) {
        if (eventEmitter != null) {
          eventEmitter!('bluetooth.deviceFound', {
            'deviceId': result.device.remoteId.str,
            'name': result.device.platformName.isNotEmpty
                ? result.device.platformName
                : 'Unknown',
            'rssi': result.rssi,
            'timestamp': DateTime.now().toIso8601String(),
          });
        }
      }
    });

    await FlutterBluePlus.startScan(
      timeout: Duration(seconds: timeoutSec),
    );

    _scanning = false;

    return {'scanning': true, 'alreadyScanning': false, 'timeoutSeconds': timeoutSec};
  }

  Future<Map<String, dynamic>> _stopScan() async {
    await FlutterBluePlus.stopScan();
    await _scanSub?.cancel();
    _scanSub = null;
    _scanning = false;
    return {'scanning': false};
  }

  Future<Map<String, dynamic>> _connect(Map<String, dynamic> args) async {
    final deviceId = args['deviceId'] as String;
    final timeoutSec = (args['timeoutSeconds'] as num?)?.toInt() ?? 15;

    final device = BluetoothDevice.fromId(deviceId);

    await device.connect(
      timeout: Duration(seconds: timeoutSec),
      autoConnect: args['autoConnect'] as bool? ?? false,
    );

    _connectedDevices[deviceId] = device;

    _connectionSub?.cancel();
    _connectionSub = device.connectionState.listen((state) {
      if (eventEmitter != null) {
        eventEmitter!('bluetooth.connectionState', {
          'deviceId': deviceId,
          'state': state.name,
          'connected': state == BluetoothConnectionState.connected,
        });
      }

      if (state == BluetoothConnectionState.disconnected) {
        _connectedDevices.remove(deviceId);
      }
    });

    BridgeLogger.info('Bluetooth', 'Connected to: $deviceId');

    return {'connected': true, 'deviceId': deviceId};
  }

  Future<Map<String, dynamic>> _disconnect(Map<String, dynamic> args) async {
    final deviceId = args['deviceId'] as String;
    final device = _connectedDevices[deviceId];

    if (device == null) {
      return {'disconnected': false, 'reason': 'not_connected'};
    }

    await device.disconnect();
    _connectedDevices.remove(deviceId);

    return {'disconnected': true, 'deviceId': deviceId};
  }

  Future<Map<String, dynamic>> _discoverServices(Map<String, dynamic> args) async {
    final deviceId = args['deviceId'] as String;
    final device = _connectedDevices[deviceId];

    if (device == null) {
      throw StateError('Device "$deviceId" not connected');
    }

    final services = await device.discoverServices();

    return {
      'deviceId': deviceId,
      'services': services.map((s) {
        return {
          'uuid': s.uuid.str,
          'characteristics': s.characteristics.map((c) {
            return {
              'uuid': c.uuid.str,
              'properties': {
                'read': c.properties.read,
                'write': c.properties.write,
                'writeWithoutResponse': c.properties.writeWithoutResponse,
                'notify': c.properties.notify,
                'indicate': c.properties.indicate,
              },
            };
          }).toList(),
        };
      }).toList(),
    };
  }

  Future<Map<String, dynamic>> _readCharacteristic(Map<String, dynamic> args) async {
    final deviceId = args['deviceId'] as String;
    final serviceUuid = args['serviceUuid'] as String;
    final characteristicUuid = args['characteristicUuid'] as String;

    final device = _connectedDevices[deviceId];
    if (device == null) throw StateError('Device not connected');

    final services = await device.discoverServices();
    final service = services.firstWhere(
      (s) => s.uuid.str.toLowerCase() == serviceUuid.toLowerCase(),
      orElse: () => throw StateError('Service not found'),
    );

    final characteristic = service.characteristics.firstWhere(
      (c) => c.uuid.str.toLowerCase() == characteristicUuid.toLowerCase(),
      orElse: () => throw StateError('Characteristic not found'),
    );

    final value = await characteristic.read();

    return {
      'deviceId': deviceId,
      'serviceUuid': serviceUuid,
      'characteristicUuid': characteristicUuid,
      'value': value,
      'valueBase64': base64Encode(Uint8List.fromList(value)),
      'valueString': String.fromCharCodes(value),
    };
  }

  Future<Map<String, dynamic>> _writeCharacteristic(Map<String, dynamic> args) async {
    final deviceId = args['deviceId'] as String;
    final serviceUuid = args['serviceUuid'] as String;
    final characteristicUuid = args['characteristicUuid'] as String;
    final valueBase64 = args['value'] as String;
    final withResponse = args['withResponse'] as bool? ?? true;

    final device = _connectedDevices[deviceId];
    if (device == null) throw StateError('Device not connected');

    final services = await device.discoverServices();
    final service = services.firstWhere(
      (s) => s.uuid.str.toLowerCase() == serviceUuid.toLowerCase(),
    );

    final characteristic = service.characteristics.firstWhere(
      (c) => c.uuid.str.toLowerCase() == characteristicUuid.toLowerCase(),
    );

    final bytes = base64Decode(valueBase64);

    await characteristic.write(
      bytes,
      withoutResponse: !withResponse,
    );

    return {'written': true, 'bytes': bytes.length};
  }

  Map<String, dynamic> _getConnectedDevices() {
    return {
      'devices': _connectedDevices.entries.map((e) {
        return {
          'deviceId': e.key,
          'name': e.value.platformName.isNotEmpty ? e.value.platformName : 'Unknown',
        };
      }).toList(),
      'count': _connectedDevices.length,
    };
  }

  @override
  Future<ValidationResult> validateArgs(String method, Map<String, dynamic> args) async {
    switch (method) {
      case 'connect':
      case 'disconnect':
      case 'discoverServices':
        final id = args['deviceId'];
        if (id is! String || id.isEmpty) {
          return ValidationResult.invalid('deviceId is required');
        }
        return ValidationResult.valid();

      case 'readCharacteristic':
      case 'writeCharacteristic':
        for (final field in ['deviceId', 'serviceUuid', 'characteristicUuid']) {
          final val = args[field];
          if (val is! String || val.isEmpty) {
            return ValidationResult.invalid('$field is required');
          }
        }
        if (method == 'writeCharacteristic') {
          final value = args['value'];
          if (value is! String || value.isEmpty) {
            return ValidationResult.invalid('value (base64) is required');
          }
        }
        return ValidationResult.valid();

      default:
        return ValidationResult.valid();
    }
  }
}
```

### 📄 `lib/plugins/bluetooth/pubspec.yaml`

```yaml
name: bluetooth_plugin
description: Bluetooth BLE plugin
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
  flutter_blue_plus: ^1.32.12
```

---

## ۲) NFC Plugin

### 📄 `lib/plugins/nfc/lib/nfc_plugin.dart`

```dart
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:nfc_manager/nfc_manager.dart';
import 'package:sweetmelon/packages/core/lib/core.dart';
import 'package:sweetmelon/packages/plugin_engine/lib/plugin_engine.dart';

typedef NfcEventEmitter = Future<void> Function(String event, dynamic data);

class NfcPlugin extends Plugin {
  final NfcEventEmitter? eventEmitter;
  bool _sessionActive = false;

  NfcPlugin({this.eventEmitter});

  @override
  String get name => 'nfc';

  @override
  String get version => '1.0.0';

  @override
  String get description => 'NFC read/write plugin';

  @override
  List<String> get supportedMethods => [
        'isAvailable',
        'startSession',
        'stopSession',
        'writeText',
        'writeUri',
        'getInfo',
      ];

  @override
  Future<dynamic> onCall(String method, Map<String, dynamic> args) async {
    switch (method) {
      case 'isAvailable':
        return _isAvailable();
      case 'startSession':
        return _startSession(args);
      case 'stopSession':
        return _stopSession();
      case 'writeText':
        return _writeText(args);
      case 'writeUri':
        return _writeUri(args);
      case 'getInfo':
        return {
          'name': name,
          'version': version,
          'sessionActive': _sessionActive,
        };
      default:
        throw UnsupportedError('Method "$method" not supported');
    }
  }

  Future<Map<String, dynamic>> _isAvailable() async {
    final available = await NfcManager.instance.isAvailable();
    return {'available': available};
  }

  Future<Map<String, dynamic>> _startSession(Map<String, dynamic> args) async {
    if (_sessionActive) {
      return {'started': true, 'alreadyActive': true};
    }

    final completer = Completer<Map<String, dynamic>>();
    final readOnce = args['readOnce'] as bool? ?? true;

    NfcManager.instance.startSession(
      onDiscovered: (NfcTag tag) async {
        final data = _parseTag(tag);

        BridgeLogger.info('NFC', 'Tag discovered: ${data['id']}');

        if (eventEmitter != null) {
          await eventEmitter!('nfc.tagDiscovered', data);
        }

        if (readOnce) {
          NfcManager.instance.stopSession();
          _sessionActive = false;
        }

        if (!completer.isCompleted) {
          completer.complete(data);
        }
      },
      onError: (error) async {
        BridgeLogger.error('NFC', 'Session error: $error');
        _sessionActive = false;

        if (eventEmitter != null) {
          await eventEmitter!('nfc.error', {
            'message': error.message,
            'details': error.details.toString(),
          });
        }

        if (!completer.isCompleted) {
          completer.complete({
            'error': true,
            'message': error.message,
          });
        }
      },
    );

    _sessionActive = true;

    if (readOnce) {
      return completer.future;
    }

    return {'started': true, 'alreadyActive': false, 'mode': 'continuous'};
  }

  Future<Map<String, dynamic>> _stopSession() async {
    NfcManager.instance.stopSession();
    _sessionActive = false;
    return {'stopped': true};
  }

  Future<Map<String, dynamic>> _writeText(Map<String, dynamic> args) async {
    final text = args['text'] as String;
    final completer = Completer<Map<String, dynamic>>();

    NfcManager.instance.startSession(
      onDiscovered: (NfcTag tag) async {
        try {
          final ndef = Ndef.from(tag);
          if (ndef == null || !ndef.isWritable) {
            completer.complete({
              'written': false,
              'reason': ndef == null ? 'not_ndef' : 'not_writable',
            });
            NfcManager.instance.stopSession();
            return;
          }

          final record = NdefRecord.createText(text);
          final message = NdefMessage([record]);
          await ndef.write(message);

          completer.complete({
            'written': true,
            'text': text,
            'bytes': message.byteLength,
          });
        } catch (e) {
          completer.complete({
            'written': false,
            'reason': e.toString(),
          });
        }

        NfcManager.instance.stopSession();
        _sessionActive = false;
      },
      onError: (error) async {
        _sessionActive = false;
        if (!completer.isCompleted) {
          completer.complete({'written': false, 'reason': error.message});
        }
      },
    );

    _sessionActive = true;
    return completer.future;
  }

  Future<Map<String, dynamic>> _writeUri(Map<String, dynamic> args) async {
    final uri = args['uri'] as String;
    final completer = Completer<Map<String, dynamic>>();

    NfcManager.instance.startSession(
      onDiscovered: (NfcTag tag) async {
        try {
          final ndef = Ndef.from(tag);
          if (ndef == null || !ndef.isWritable) {
            completer.complete({'written': false, 'reason': 'not_writable'});
            NfcManager.instance.stopSession();
            return;
          }

          final record = NdefRecord.createUri(Uri.parse(uri));
          final message = NdefMessage([record]);
          await ndef.write(message);

          completer.complete({'written': true, 'uri': uri});
        } catch (e) {
          completer.complete({'written': false, 'reason': e.toString()});
        }

        NfcManager.instance.stopSession();
        _sessionActive = false;
      },
      onError: (error) async {
        _sessionActive = false;
        if (!completer.isCompleted) {
          completer.complete({'written': false, 'reason': error.message});
        }
      },
    );

    _sessionActive = true;
    return completer.future;
  }

  Map<String, dynamic> _parseTag(NfcTag tag) {
    final data = <String, dynamic>{
      'id': null,
      'type': 'unknown',
      'records': <dynamic>[],
      'timestamp': DateTime.now().toIso8601String(),
    };

    final ndef = Ndef.from(tag);
    if (ndef != null) {
      data['type'] = 'ndef';
      data['isWritable'] = ndef.isWritable;
      data['maxSize'] = ndef.maxSize;

      final message = ndef.cachedMessage;
      if (message != null) {
        data['records'] = message.records.map((record) {
          return {
            'typeNameFormat': record.typeNameFormat.index,
            'type': utf8.decode(record.type),
            'payload': base64Encode(record.payload),
            'payloadString': _tryDecodePayload(record),
          };
        }).toList();
      }
    }

    final nfcA = tag.data['nfca'] as Map<String, dynamic>?;
    if (nfcA != null) {
      final identifier = nfcA['identifier'] as List<dynamic>?;
      if (identifier != null) {
        data['id'] = identifier
            .map((b) => (b as int).toRadixString(16).padLeft(2, '0'))
            .join(':');
      }
    }

    final nfcB = tag.data['nfcb'] as Map<String, dynamic>?;
    if (nfcB != null) {
      final identifier = nfcB['identifier'] as List<dynamic>?;
      if (identifier != null) {
        data['id'] = identifier
            .map((b) => (b as int).toRadixString(16).padLeft(2, '0'))
            .join(':');
      }
    }

    return data;
  }

  String? _tryDecodePayload(NdefRecord record) {
    try {
      final payload = record.payload;
      if (payload.isEmpty) return null;

      if (record.typeNameFormat == NdefTypeNameFormat.nfcWellknown) {
        final type = utf8.decode(record.type);

        if (type == 'T') {
          final langLength = payload[0] & 0x3F;
          return utf8.decode(payload.sublist(1 + langLength));
        }

        if (type == 'U') {
          final prefix = _uriPrefixes[payload[0]] ?? '';
          return prefix + utf8.decode(payload.sublist(1));
        }
      }

      return utf8.decode(payload);
    } catch (_) {
      return null;
    }
  }

  static const Map<int, String> _uriPrefixes = {
    0x00: '',
    0x01: 'http://www.',
    0x02: 'https://www.',
    0x03: 'http://',
    0x04: 'https://',
    0x05: 'tel:',
    0x06: 'mailto:',
  };

  @override
  Future<void> onDispose() async {
    if (_sessionActive) {
      NfcManager.instance.stopSession();
      _sessionActive = false;
    }
  }

  @override
  Future<ValidationResult> validateArgs(String method, Map<String, dynamic> args) async {
    switch (method) {
      case 'writeText':
        if (args['text'] is! String || (args['text'] as String).isEmpty) {
          return ValidationResult.invalid('text is required');
        }
        return ValidationResult.valid();
      case 'writeUri':
        if (args['uri'] is! String || (args['uri'] as String).isEmpty) {
          return ValidationResult.invalid('uri is required');
        }
        return ValidationResult.valid();
      default:
        return ValidationResult.valid();
    }
  }
}
```

### 📄 `lib/plugins/nfc/pubspec.yaml`

```yaml
name: nfc_plugin
description: NFC read/write plugin
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
  nfc_manager: ^3.5.0
```

---

## ۳) Speech To Text Plugin

### 📄 `lib/plugins/speech_to_text/lib/speech_to_text_plugin.dart`

```dart
import 'dart:async';

import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:sweetmelon/packages/core/lib/core.dart';
import 'package:sweetmelon/packages/plugin_engine/lib/plugin_engine.dart';

typedef SttEventEmitter = Future<void> Function(String event, dynamic data);

class SpeechToTextPlugin extends Plugin {
  final SttEventEmitter? eventEmitter;
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _available = false;
  bool _listening = false;

  SpeechToTextPlugin({this.eventEmitter});

  @override
  String get name => 'speechToText';

  @override
  String get version => '1.0.0';

  @override
  String get description => 'Speech to text recognition plugin';

  @override
  List<String> get requiredPermissions => ['microphone'];

  @override
  List<String> get supportedMethods => [
        'initialize',
        'startListening',
        'stopListening',
        'cancelListening',
        'isAvailable',
        'getLocales',
        'getInfo',
      ];

  @override
  Future<dynamic> onCall(String method, Map<String, dynamic> args) async {
    switch (method) {
      case 'initialize':
        return _initialize();
      case 'startListening':
        return _startListening(args);
      case 'stopListening':
        return _stopListening();
      case 'cancelListening':
        return _cancelListening();
      case 'isAvailable':
        return {'available': _available};
      case 'getLocales':
        return _getLocales();
      case 'getInfo':
        return {
          'name': name,
          'version': version,
          'available': _available,
          'listening': _listening,
        };
      default:
        throw UnsupportedError('Method "$method" not supported');
    }
  }

  Future<Map<String, dynamic>> _initialize() async {
    _available = await _speech.initialize(
      onStatus: (status) {
        _listening = status == 'listening';
        if (eventEmitter != null) {
          eventEmitter!('speechToText.status', {
            'status': status,
            'listening': _listening,
          });
        }
      },
      onError: (error) {
        BridgeLogger.error('STT', 'Error: ${error.errorMsg}');
        if (eventEmitter != null) {
          eventEmitter!('speechToText.error', {
            'message': error.errorMsg,
            'permanent': error.permanent,
          });
        }
      },
    );

    return {'initialized': _available};
  }

  Future<Map<String, dynamic>> _startListening(Map<String, dynamic> args) async {
    if (!_available) {
      await _initialize();
      if (!_available) {
        return {'started': false, 'reason': 'not_available'};
      }
    }

    final localeId = args['locale'] as String?;
    final listenFor = (args['listenForSeconds'] as num?)?.toInt() ?? 30;
    final pauseFor = (args['pauseForSeconds'] as num?)?.toInt() ?? 3;
    final partialResults = args['partialResults'] as bool? ?? true;

    final completer = Completer<Map<String, dynamic>>();

    await _speech.listen(
      onResult: (result) {
        final data = {
          'text': result.recognizedWords,
          'confidence': result.confidence,
          'finalResult': result.finalResult,
          'alternates': result.alternates.map((a) {
            return {
              'text': a.recognizedWords,
              'confidence': a.confidence,
            };
          }).toList(),
        };

        if (eventEmitter != null) {
          eventEmitter!('speechToText.result', data);
        }

        if (result.finalResult && !completer.isCompleted) {
          completer.complete(data);
        }
      },
      localeId: localeId,
      listenFor: Duration(seconds: listenFor),
      pauseFor: Duration(seconds: pauseFor),
      partialResults: partialResults,
      listenMode: stt.ListenMode.confirmation,
    );

    _listening = true;

    return completer.future.timeout(
      Duration(seconds: listenFor + 5),
      onTimeout: () {
        _speech.stop();
        _listening = false;
        return {'text': '', 'finalResult': true, 'reason': 'timeout'};
      },
    );
  }

  Future<Map<String, dynamic>> _stopListening() async {
    await _speech.stop();
    _listening = false;
    return {'stopped': true};
  }

  Future<Map<String, dynamic>> _cancelListening() async {
    await _speech.cancel();
    _listening = false;
    return {'cancelled': true};
  }

  Future<Map<String, dynamic>> _getLocales() async {
    if (!_available) await _initialize();
    final locales = await _speech.locales();
    return {
      'locales': locales.map((l) {
        return {
          'id': l.localeId,
          'name': l.name,
        };
      }).toList(),
    };
  }

  @override
  Future<void> onDispose() async {
    if (_listening) await _speech.stop();
  }
}
```

### 📄 `lib/plugins/speech_to_text/pubspec.yaml`

```yaml
name: speech_to_text_plugin
description: Speech to text plugin
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
  speech_to_text: ^7.0.0
```

---

## ۴) Text To Speech Plugin

### 📄 `lib/plugins/text_to_speech/lib/text_to_speech_plugin.dart`

```dart
import 'dart:async';

import 'package:flutter_tts/flutter_tts.dart';
import 'package:sweetmelon/packages/core/lib/core.dart';
import 'package:sweetmelon/packages/plugin_engine/lib/plugin_engine.dart';

typedef TtsEventEmitter = Future<void> Function(String event, dynamic data);

class TextToSpeechPlugin extends Plugin {
  final TtsEventEmitter? eventEmitter;
  final FlutterTts _tts = FlutterTts();
  bool _speaking = false;

  TextToSpeechPlugin({this.eventEmitter});

  @override
  String get name => 'textToSpeech';

  @override
  String get version => '1.0.0';

  @override
  String get description => 'Text to speech plugin';

  @override
  List<String> get supportedMethods => [
        'speak',
        'stop',
        'pause',
        'setLanguage',
        'setSpeechRate',
        'setPitch',
        'setVolume',
        'getLanguages',
        'getVoices',
        'isSpeaking',
        'getInfo',
      ];

  @override
  Future<void> onInitialize() async {
    _tts.setStartHandler(() {
      _speaking = true;
      eventEmitter?.call('tts.start', {'speaking': true});
    });

    _tts.setCompletionHandler(() {
      _speaking = false;
      eventEmitter?.call('tts.complete', {'speaking': false});
    });

    _tts.setCancelHandler(() {
      _speaking = false;
      eventEmitter?.call('tts.cancel', {'speaking': false});
    });

    _tts.setErrorHandler((msg) {
      _speaking = false;
      BridgeLogger.error('TTS', 'Error: $msg');
      eventEmitter?.call('tts.error', {'message': msg});
    });

    _tts.setProgressHandler((text, start, end, word) {
      eventEmitter?.call('tts.progress', {
        'text': text,
        'start': start,
        'end': end,
        'word': word,
      });
    });
  }

  @override
  Future<void> onDispose() async {
    await _tts.stop();
  }

  @override
  Future<dynamic> onCall(String method, Map<String, dynamic> args) async {
    switch (method) {
      case 'speak':
        return _speak(args);
      case 'stop':
        return _stop();
      case 'pause':
        return _pause();
      case 'setLanguage':
        return _setLanguage(args);
      case 'setSpeechRate':
        return _setSpeechRate(args);
      case 'setPitch':
        return _setPitch(args);
      case 'setVolume':
        return _setVolume(args);
      case 'getLanguages':
        return _getLanguages();
      case 'getVoices':
        return _getVoices();
      case 'isSpeaking':
        return {'speaking': _speaking};
      case 'getInfo':
        return {
          'name': name,
          'version': version,
          'speaking': _speaking,
        };
      default:
        throw UnsupportedError('Method "$method" not supported');
    }
  }

  Future<Map<String, dynamic>> _speak(Map<String, dynamic> args) async {
    final text = args['text'] as String;
    final language = args['language'] as String?;
    final rate = (args['rate'] as num?)?.toDouble();
    final pitch = (args['pitch'] as num?)?.toDouble();
    final volume = (args['volume'] as num?)?.toDouble();

    if (language != null) await _tts.setLanguage(language);
    if (rate != null) await _tts.setSpeechRate(rate);
    if (pitch != null) await _tts.setPitch(pitch);
    if (volume != null) await _tts.setVolume(volume);

    await _tts.speak(text);
    _speaking = true;

    return {'speaking': true, 'textLength': text.length};
  }

  Future<Map<String, dynamic>> _stop() async {
    await _tts.stop();
    _speaking = false;
    return {'stopped': true};
  }

  Future<Map<String, dynamic>> _pause() async {
    await _tts.pause();
    _speaking = false;
    return {'paused': true};
  }

  Future<Map<String, dynamic>> _setLanguage(Map<String, dynamic> args) async {
    final language = args['language'] as String;
    await _tts.setLanguage(language);
    return {'language': language};
  }

  Future<Map<String, dynamic>> _setSpeechRate(Map<String, dynamic> args) async {
    final rate = (args['rate'] as num).toDouble().clamp(0.0, 2.0);
    await _tts.setSpeechRate(rate);
    return {'rate': rate};
  }

  Future<Map<String, dynamic>> _setPitch(Map<String, dynamic> args) async {
    final pitch = (args['pitch'] as num).toDouble().clamp(0.5, 2.0);
    await _tts.setPitch(pitch);
    return {'pitch': pitch};
  }

  Future<Map<String, dynamic>> _setVolume(Map<String, dynamic> args) async {
    final volume = (args['volume'] as num).toDouble().clamp(0.0, 1.0);
    await _tts.setVolume(volume);
    return {'volume': volume};
  }

  Future<Map<String, dynamic>> _getLanguages() async {
    final languages = await _tts.getLanguages;
    return {'languages': List<String>.from(languages ?? [])};
  }

  Future<Map<String, dynamic>> _getVoices() async {
    final voices = await _tts.getVoices;
    return {
      'voices': (voices as List?)?.map((v) {
            final map = v as Map;
            return {'name': map['name'], 'locale': map['locale']};
          }).toList() ??
          [],
    };
  }

  @override
  Future<ValidationResult> validateArgs(String method, Map<String, dynamic> args) async {
    if (method == 'speak') {
      if (args['text'] is! String || (args['text'] as String).isEmpty) {
        return ValidationResult.invalid('text is required');
      }
    }
    return ValidationResult.valid();
  }
}
```

### 📄 `lib/plugins/text_to_speech/pubspec.yaml`

```yaml
name: text_to_speech_plugin
description: Text to speech plugin
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
  flutter_tts: ^4.0.2
```

---

## ۵) Video Player Plugin

### 📄 `lib/plugins/video_player/lib/video_player_plugin.dart`

```dart
import 'dart:async';
import 'dart:io';

import 'package:sweetmelon/packages/core/lib/core.dart';
import 'package:sweetmelon/packages/plugin_engine/lib/plugin_engine.dart';
import 'package:video_player/video_player.dart' as vp;

typedef VideoEventEmitter = Future<void> Function(String event, dynamic data);

class VideoPlayerPlugin extends Plugin {
  final VideoEventEmitter? eventEmitter;
  final Map<String, _ManagedPlayer> _players = {};

  VideoPlayerPlugin({this.eventEmitter});

  @override
  String get name => 'videoPlayer';

  @override
  String get version => '1.0.0';

  @override
  String get description => 'Video player plugin';

  @override
  List<String> get supportedMethods => [
        'create',
        'play',
        'pause',
        'seekTo',
        'setVolume',
        'setPlaybackSpeed',
        'setLooping',
        'getPosition',
        'getDuration',
        'getState',
        'dispose',
        'disposeAll',
        'getInfo',
      ];

  @override
  Future<void> onDispose() async {
    for (final p in _players.values) {
      await p.controller.dispose();
      p.listener?.cancel();
    }
    _players.clear();
  }

  @override
  Future<dynamic> onCall(String method, Map<String, dynamic> args) async {
    switch (method) {
      case 'create':
        return _create(args);
      case 'play':
        return _play(args);
      case 'pause':
        return _pause(args);
      case 'seekTo':
        return _seekTo(args);
      case 'setVolume':
        return _setVolume(args);
      case 'setPlaybackSpeed':
        return _setPlaybackSpeed(args);
      case 'setLooping':
        return _setLooping(args);
      case 'getPosition':
        return _getPosition(args);
      case 'getDuration':
        return _getDuration(args);
      case 'getState':
        return _getState(args);
      case 'dispose':
        return _disposePlayer(args);
      case 'disposeAll':
        return _disposeAll();
      case 'getInfo':
        return {
          'name': name,
          'version': version,
          'activePlayers': _players.keys.toList(),
        };
      default:
        throw UnsupportedError('Method "$method" not supported');
    }
  }

  Future<Map<String, dynamic>> _create(Map<String, dynamic> args) async {
    final playerId = args['playerId'] as String? ??
        'vp_${DateTime.now().millisecondsSinceEpoch}';
    final url = args['url'] as String?;
    final filePath = args['path'] as String?;
    final autoPlay = args['autoPlay'] as bool? ?? false;
    final looping = args['looping'] as bool? ?? false;
    final volume = (args['volume'] as num?)?.toDouble() ?? 1.0;

    vp.VideoPlayerController controller;

    if (url != null && url.isNotEmpty) {
      controller = vp.VideoPlayerController.networkUrl(Uri.parse(url));
    } else if (filePath != null && filePath.isNotEmpty) {
      controller = vp.VideoPlayerController.file(File(filePath));
    } else {
      throw ArgumentError('Either url or path is required');
    }

    await controller.initialize();
    await controller.setLooping(looping);
    await controller.setVolume(volume);

    StreamSubscription<void>? listener;
    listener = controller.addListener(() {
      if (eventEmitter != null) {
        eventEmitter!('videoPlayer.state', {
          'playerId': playerId,
          'isPlaying': controller.value.isPlaying,
          'isBuffering': controller.value.isBuffering,
          'isCompleted': controller.value.isCompleted,
          'positionMs': controller.value.position.inMilliseconds,
          'durationMs': controller.value.duration.inMilliseconds,
        });
      }
    }) as StreamSubscription<void>?;

    if (autoPlay) {
      await controller.play();
    }

    _players[playerId] = _ManagedPlayer(controller: controller, listener: listener);

    BridgeLogger.info('VideoPlayer', 'Created: $playerId');

    return {
      'playerId': playerId,
      'initialized': true,
      'durationMs': controller.value.duration.inMilliseconds,
      'width': controller.value.size.width,
      'height': controller.value.size.height,
    };
  }

  vp.VideoPlayerController _getController(String playerId) {
    final managed = _players[playerId];
    if (managed == null) throw StateError('Player "$playerId" not found');
    return managed.controller;
  }

  Future<Map<String, dynamic>> _play(Map<String, dynamic> args) async {
    final c = _getController(args['playerId'] as String);
    await c.play();
    return {'playing': true};
  }

  Future<Map<String, dynamic>> _pause(Map<String, dynamic> args) async {
    final c = _getController(args['playerId'] as String);
    await c.pause();
    return {'paused': true};
  }

  Future<Map<String, dynamic>> _seekTo(Map<String, dynamic> args) async {
    final c = _getController(args['playerId'] as String);
    final ms = (args['positionMs'] as num).toInt();
    await c.seekTo(Duration(milliseconds: ms));
    return {'seeked': true, 'positionMs': ms};
  }

  Future<Map<String, dynamic>> _setVolume(Map<String, dynamic> args) async {
    final c = _getController(args['playerId'] as String);
    final v = (args['volume'] as num).toDouble().clamp(0.0, 1.0);
    await c.setVolume(v);
    return {'volume': v};
  }

  Future<Map<String, dynamic>> _setPlaybackSpeed(Map<String, dynamic> args) async {
    final c = _getController(args['playerId'] as String);
    final s = (args['speed'] as num).toDouble().clamp(0.25, 4.0);
    await c.setPlaybackSpeed(s);
    return {'speed': s};
  }

  Future<Map<String, dynamic>> _setLooping(Map<String, dynamic> args) async {
    final c = _getController(args['playerId'] as String);
    final l = args['looping'] as bool? ?? false;
    await c.setLooping(l);
    return {'looping': l};
  }

  Map<String, dynamic> _getPosition(Map<String, dynamic> args) {
    final c = _getController(args['playerId'] as String);
    return {
      'positionMs': c.value.position.inMilliseconds,
      'positionSec': c.value.position.inSeconds,
    };
  }

  Map<String, dynamic> _getDuration(Map<String, dynamic> args) {
    final c = _getController(args['playerId'] as String);
    return {
      'durationMs': c.value.duration.inMilliseconds,
      'durationSec': c.value.duration.inSeconds,
    };
  }

  Map<String, dynamic> _getState(Map<String, dynamic> args) {
    final c = _getController(args['playerId'] as String);
    final v = c.value;
    return {
      'isPlaying': v.isPlaying,
      'isBuffering': v.isBuffering,
      'isCompleted': v.isCompleted,
      'isInitialized': v.isInitialized,
      'positionMs': v.position.inMilliseconds,
      'durationMs': v.duration.inMilliseconds,
      'volume': v.volume,
      'playbackSpeed': v.playbackSpeed,
      'isLooping': v.isLooping,
      'width': v.size.width,
      'height': v.size.height,
    };
  }

  Future<Map<String, dynamic>> _disposePlayer(Map<String, dynamic> args) async {
    final playerId = args['playerId'] as String;
    final managed = _players.remove(playerId);
    if (managed != null) {
      managed.listener?.cancel();
      await managed.controller.dispose();
      return {'disposed': true, 'playerId': playerId};
    }
    return {'disposed': false, 'reason': 'not_found'};
  }

  Future<Map<String, dynamic>> _disposeAll() async {
    final count = _players.length;
    for (final p in _players.values) {
      p.listener?.cancel();
      await p.controller.dispose();
    }
    _players.clear();
    return {'disposed': count};
  }

  @override
  Future<ValidationResult> validateArgs(String method, Map<String, dynamic> args) async {
    final needsPlayerId = [
      'play', 'pause', 'seekTo', 'setVolume', 'setPlaybackSpeed',
      'setLooping', 'getPosition', 'getDuration', 'getState', 'dispose',
    ];

    if (needsPlayerId.contains(method)) {
      if (args['playerId'] is! String || (args['playerId'] as String).isEmpty) {
        return ValidationResult.invalid('playerId is required');
      }
    }

    if (method == 'create') {
      final url = args['url'];
      final path = args['path'];
      if ((url == null || url.toString().isEmpty) &&
          (path == null || path.toString().isEmpty)) {
        return ValidationResult.invalid('url or path is required');
      }
    }

    return ValidationResult.valid();
  }
}

class _ManagedPlayer {
  final vp.VideoPlayerController controller;
  final StreamSubscription<void>? listener;

  _ManagedPlayer({required this.controller, this.listener});
}
```

### 📄 `lib/plugins/video_player/pubspec.yaml`

```yaml
name: video_player_plugin
description: Video player plugin
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
  video_player: ^2.9.2
```

---

## ۶) In-App Browser Plugin

### 📄 `lib/plugins/in_app_browser/lib/in_app_browser_plugin.dart`

```dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:sweetmelon/packages/core/lib/core.dart';
import 'package:sweetmelon/packages/plugin_engine/lib/plugin_engine.dart';
import 'package:sweetmelon/plugins/qr_scanner/lib/qr_scanner_plugin.dart';

typedef BrowserEventEmitter = Future<void> Function(String event, dynamic data);

class InAppBrowserPlugin extends Plugin {
  final BrowserEventEmitter? eventEmitter;

  InAppBrowserPlugin({this.eventEmitter});

  @override
  String get name => 'inAppBrowser';

  @override
  String get version => '1.0.0';

  @override
  String get description => 'In-app browser for external pages, OAuth, etc.';

  @override
  List<String> get supportedMethods => [
        'open',
        'getInfo',
      ];

  @override
  Future<dynamic> onCall(String method, Map<String, dynamic> args) async {
    switch (method) {
      case 'open':
        return _open(args);
      case 'getInfo':
        return {'name': name, 'version': version};
      default:
        throw UnsupportedError('Method "$method" not supported');
    }
  }

  Future<Map<String, dynamic>> _open(Map<String, dynamic> args) async {
    final url = args['url'] as String;
    final title = args['title'] as String? ?? '';
    final closeOnMatch = args['closeOnUrlMatch'] as String?;
    final showToolbar = args['showToolbar'] as bool? ?? true;

    final context = QrScannerPlugin.navigatorKey?.currentContext;
    if (context == null) {
      throw StateError('No navigator context');
    }

    final completer = Completer<Map<String, dynamic>>();

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _InAppBrowserPage(
          url: url,
          title: title,
          showToolbar: showToolbar,
          closeOnUrlMatch: closeOnMatch,
          eventEmitter: eventEmitter,
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

  @override
  Future<ValidationResult> validateArgs(String method, Map<String, dynamic> args) async {
    if (method == 'open') {
      final url = args['url'];
      if (url is! String || url.isEmpty) {
        return ValidationResult.invalid('url is required');
      }
    }
    return ValidationResult.valid();
  }
}

class _InAppBrowserPage extends StatefulWidget {
  final String url;
  final String title;
  final bool showToolbar;
  final String? closeOnUrlMatch;
  final BrowserEventEmitter? eventEmitter;
  final void Function(Map<String, dynamic>) onResult;

  const _InAppBrowserPage({
    required this.url,
    required this.title,
    required this.showToolbar,
    required this.closeOnUrlMatch,
    required this.eventEmitter,
    required this.onResult,
  });

  @override
  State<_InAppBrowserPage> createState() => _InAppBrowserPageState();
}

class _InAppBrowserPageState extends State<_InAppBrowserPage> {
  double _progress = 0;
  String _currentUrl = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: widget.showToolbar
          ? AppBar(
              backgroundColor: const Color(0xFF121A2D),
              title: Text(
                widget.title.isNotEmpty ? widget.title : _currentUrl,
                style: const TextStyle(fontSize: 13, color: Colors.white70),
                overflow: TextOverflow.ellipsis,
              ),
              leading: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => _close('user_closed'),
              ),
            )
          : null,
      body: Column(
        children: [
          if (_progress < 1.0)
            LinearProgressIndicator(
              value: _progress,
              minHeight: 2,
              color: const Color(0xFF6C63FF),
              backgroundColor: Colors.transparent,
            ),
          Expanded(
            child: InAppWebView(
              initialUrlRequest: URLRequest(
                url: WebUri(widget.url),
              ),
              initialSettings: InAppWebViewSettings(
                javaScriptEnabled: true,
                useShouldOverrideUrlLoading: true,
                mediaPlaybackRequiresUserGesture: false,
                clearCache: false,
              ),
              onProgressChanged: (controller, progress) {
                setState(() => _progress = progress / 100);
              },
              onLoadStop: (controller, url) {
                setState(() => _currentUrl = url?.toString() ?? '');

                widget.eventEmitter?.call('inAppBrowser.loadStop', {
                  'url': url?.toString(),
                });

                if (widget.closeOnUrlMatch != null &&
                    url != null &&
                    url.toString().contains(widget.closeOnUrlMatch!)) {
                  _close('url_match', url: url.toString());
                }
              },
              onLoadError: (controller, url, code, message) {
                widget.eventEmitter?.call('inAppBrowser.error', {
                  'url': url?.toString(),
                  'code': code,
                  'message': message,
                });
              },
              shouldOverrideUrlLoading: (controller, action) async {
                return NavigationActionPolicy.ALLOW;
              },
            ),
          ),
        ],
      ),
    );
  }

  void _close(String reason, {String? url}) {
    widget.onResult({
      'closed': true,
      'reason': reason,
      'lastUrl': url ?? _currentUrl,
    });
    Navigator.of(context).pop();
  }
}
```

### 📄 `lib/plugins/in_app_browser/pubspec.yaml`

```yaml
name: in_app_browser_plugin
description: In-app browser plugin
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
  qr_scanner:
    path: ../qr_scanner
```

---

## ۷) PDF Plugin (Viewer + Generator)

### 📄 `lib/plugins/pdf_plugin/lib/pdf_bridge_plugin.dart`

```dart
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:sweetmelon/packages/core/lib/core.dart';
import 'package:sweetmelon/packages/plugin_engine/lib/plugin_engine.dart';

class PdfBridgePlugin extends Plugin {
  @override
  String get name => 'pdf';

  @override
  String get version => '1.0.0';

  @override
  String get description => 'PDF generate, view, print plugin';

  @override
  List<String> get supportedMethods => [
        'generateFromText',
        'generateFromHtml',
        'print',
        'share',
        'getInfo',
      ];

  @override
  Future<dynamic> onCall(String method, Map<String, dynamic> args) async {
    switch (method) {
      case 'generateFromText':
        return _generateFromText(args);
      case 'generateFromHtml':
        return _generateFromHtml(args);
      case 'print':
        return _print(args);
      case 'share':
        return _share(args);
      case 'getInfo':
        return {'name': name, 'version': version};
      default:
        throw UnsupportedError('Method "$method" not supported');
    }
  }

  Future<Map<String, dynamic>> _generateFromText(Map<String, dynamic> args) async {
    final text = args['text'] as String;
    final title = args['title'] as String? ?? 'Document';
    final fileName = args['fileName'] as String? ??
        'doc_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final fontSize = (args['fontSize'] as num?)?.toDouble() ?? 12;

    final doc = pw.Document();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        header: (context) => pw.Container(
          margin: const pw.EdgeInsets.only(bottom: 20),
          child: pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ),
        footer: (context) => pw.Container(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            'Page ${context.pageNumber} / ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 9),
          ),
        ),
        build: (context) => [
          pw.Paragraph(
            text: text,
            style: pw.TextStyle(fontSize: fontSize),
          ),
        ],
      ),
    );

    return _saveDoc(doc, fileName);
  }

  Future<Map<String, dynamic>> _generateFromHtml(Map<String, dynamic> args) async {
    final html = args['html'] as String;
    final fileName = args['fileName'] as String? ??
        'doc_${DateTime.now().millisecondsSinceEpoch}.pdf';

    // html to pdf conversion via printing
    final bytes = await Printing.convertHtml(
      html: html,
      format: PdfPageFormat.a4,
    );

    final dir = await getApplicationDocumentsDirectory();
    final pdfDir = Directory(p.join(dir.path, 'pdfs'));
    await pdfDir.create(recursive: true);

    final file = File(p.join(pdfDir.path, fileName));
    await file.writeAsBytes(bytes);

    return {
      'generated': true,
      'path': file.path,
      'fileName': fileName,
      'size': bytes.length,
    };
  }

  Future<Map<String, dynamic>> _print(Map<String, dynamic> args) async {
    final path = args['path'] as String?;
    final html = args['html'] as String?;
    final name = args['name'] as String? ?? 'Document';

    if (path != null && path.isNotEmpty) {
      final file = File(path);
      if (!await file.exists()) {
        return {'printed': false, 'reason': 'file_not_found'};
      }
      final bytes = await file.readAsBytes();
      await Printing.layoutPdf(
        name: name,
        onLayout: (format) async => bytes,
      );
    } else if (html != null && html.isNotEmpty) {
      await Printing.layoutPdf(
        name: name,
        onLayout: (format) async {
          return await Printing.convertHtml(
            html: html,
            format: format,
          );
        },
      );
    } else {
      return {'printed': false, 'reason': 'no_source'};
    }

    return {'printed': true};
  }

  Future<Map<String, dynamic>> _share(Map<String, dynamic> args) async {
    final path = args['path'] as String;
    final file = File(path);

    if (!await file.exists()) {
      return {'shared': false, 'reason': 'file_not_found'};
    }

    final bytes = await file.readAsBytes();
    await Printing.sharePdf(
      bytes: Uint8List.fromList(bytes),
      filename: p.basename(path),
    );

    return {'shared': true, 'path': path};
  }

  Future<Map<String, dynamic>> _saveDoc(pw.Document doc, String fileName) async {
    final dir = await getApplicationDocumentsDirectory();
    final pdfDir = Directory(p.join(dir.path, 'pdfs'));
    await pdfDir.create(recursive: true);

    final bytes = await doc.save();
    final file = File(p.join(pdfDir.path, fileName));
    await file.writeAsBytes(bytes);

    BridgeLogger.info('PDF', 'Generated: ${file.path} (${bytes.length} bytes)');

    return {
      'generated': true,
      'path': file.path,
      'fileName': fileName,
      'size': bytes.length,
    };
  }

  @override
  Future<ValidationResult> validateArgs(String method, Map<String, dynamic> args) async {
    switch (method) {
      case 'generateFromText':
        if (args['text'] is! String || (args['text'] as String).isEmpty) {
          return ValidationResult.invalid('text is required');
        }
        return ValidationResult.valid();

      case 'generateFromHtml':
        if (args['html'] is! String || (args['html'] as String).isEmpty) {
          return ValidationResult.invalid('html is required');
        }
        return ValidationResult.valid();

      case 'share':
        if (args['path'] is! String || (args['path'] as String).isEmpty) {
          return ValidationResult.invalid('path is required');
        }
        return ValidationResult.valid();

      default:
        return ValidationResult.valid();
    }
  }
}
```

### 📄 `lib/plugins/pdf_plugin/pubspec.yaml`

```yaml
name: pdf_bridge_plugin
description: PDF generate, view, print plugin
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
  pdf: ^3.11.1
  printing: ^5.13.3
  path_provider: ^2.1.1
  path: ^1.9.0
```

---

## ۸) Encryption Plugin

### 📄 `lib/plugins/encryption/lib/encryption_plugin.dart`

```dart
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:encrypt/encrypt.dart' as enc;
import 'package:pointycastle/export.dart';
import 'package:sweetmelon/packages/plugin_engine/lib/plugin_engine.dart';

class EncryptionPlugin extends Plugin {
  @override
  String get name => 'encryption';

  @override
  String get version => '1.0.0';

  @override
  String get description => 'AES/RSA encryption and hashing plugin';

  @override
  List<String> get supportedMethods => [
        'aesEncrypt',
        'aesDecrypt',
        'generateAesKey',
        'hashSha256',
        'hashSha512',
        'hashMd5',
        'hmacSha256',
        'generateRandomBytes',
        'base64Encode',
        'base64Decode',
        'getInfo',
      ];

  @override
  Future<dynamic> onCall(String method, Map<String, dynamic> args) async {
    switch (method) {
      case 'aesEncrypt':
        return _aesEncrypt(args);
      case 'aesDecrypt':
        return _aesDecrypt(args);
      case 'generateAesKey':
        return _generateAesKey(args);
      case 'hashSha256':
        return _hash(args, 'SHA-256');
      case 'hashSha512':
        return _hash(args, 'SHA-512');
      case 'hashMd5':
        return _hash(args, 'MD5');
      case 'hmacSha256':
        return _hmac(args);
      case 'generateRandomBytes':
        return _generateRandomBytes(args);
      case 'base64Encode':
        return _base64Encode(args);
      case 'base64Decode':
        return _base64Decode(args);
      case 'getInfo':
        return {
          'name': name,
          'version': version,
          'algorithms': ['AES-CBC', 'SHA-256', 'SHA-512', 'MD5', 'HMAC-SHA256'],
        };
      default:
        throw UnsupportedError('Method "$method" not supported');
    }
  }

  Map<String, dynamic> _aesEncrypt(Map<String, dynamic> args) {
    final plaintext = args['data'] as String;
    final keyBase64 = args['key'] as String;
    final ivBase64 = args['iv'] as String?;

    final key = enc.Key.fromBase64(keyBase64);
    final iv = ivBase64 != null
        ? enc.IV.fromBase64(ivBase64)
        : enc.IV.fromSecureRandom(16);

    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
    final encrypted = encrypter.encrypt(plaintext, iv: iv);

    return {
      'encrypted': encrypted.base64,
      'iv': iv.base64,
      'algorithm': 'AES-CBC',
    };
  }

  Map<String, dynamic> _aesDecrypt(Map<String, dynamic> args) {
    final encryptedBase64 = args['data'] as String;
    final keyBase64 = args['key'] as String;
    final ivBase64 = args['iv'] as String;

    final key = enc.Key.fromBase64(keyBase64);
    final iv = enc.IV.fromBase64(ivBase64);

    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
    final decrypted = encrypter.decrypt64(encryptedBase64, iv: iv);

    return {
      'decrypted': decrypted,
      'algorithm': 'AES-CBC',
    };
  }

  Map<String, dynamic> _generateAesKey(Map<String, dynamic> args) {
    final bits = (args['bits'] as num?)?.toInt() ?? 256;
    final bytes = bits ~/ 8;

    final random = Random.secure();
    final keyBytes = Uint8List(bytes);
    for (var i = 0; i < bytes; i++) {
      keyBytes[i] = random.nextInt(256);
    }

    final ivBytes = Uint8List(16);
    for (var i = 0; i < 16; i++) {
      ivBytes[i] = random.nextInt(256);
    }

    return {
      'key': base64Encode(keyBytes),
      'iv': base64Encode(ivBytes),
      'bits': bits,
    };
  }

  Map<String, dynamic> _hash(Map<String, dynamic> args, String algorithm) {
    final data = args['data'] as String;
    final bytes = utf8.encode(data);

    Digest digest;

    switch (algorithm) {
      case 'SHA-256':
        digest = SHA256Digest();
        break;
      case 'SHA-512':
        digest = SHA512Digest();
        break;
      case 'MD5':
        digest = MD5Digest();
        break;
      default:
        throw ArgumentError('Unsupported algorithm: $algorithm');
    }

    final result = digest.process(Uint8List.fromList(bytes));
    final hex = result.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

    return {
      'hash': hex,
      'base64': base64Encode(result),
      'algorithm': algorithm,
    };
  }

  Map<String, dynamic> _hmac(Map<String, dynamic> args) {
    final data = args['data'] as String;
    final keyStr = args['key'] as String;

    final keyBytes = utf8.encode(keyStr);
    final dataBytes = utf8.encode(data);

    final hmac = HMac(SHA256Digest(), 64);
    hmac.init(KeyParameter(Uint8List.fromList(keyBytes)));

    final result = hmac.process(Uint8List.fromList(dataBytes));
    final hex = result.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

    return {
      'hmac': hex,
      'base64': base64Encode(result),
      'algorithm': 'HMAC-SHA256',
    };
  }

  Map<String, dynamic> _generateRandomBytes(Map<String, dynamic> args) {
    final length = (args['length'] as num?)?.toInt() ?? 32;
    final random = Random.secure();
    final bytes = Uint8List(length);
    for (var i = 0; i < length; i++) {
      bytes[i] = random.nextInt(256);
    }

    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

    return {
      'hex': hex,
      'base64': base64Encode(bytes),
      'length': length,
    };
  }

  Map<String, dynamic> _base64Encode(Map<String, dynamic> args) {
    final data = args['data'] as String;
    return {'encoded': base64Encode(utf8.encode(data))};
  }

  Map<String, dynamic> _base64Decode(Map<String, dynamic> args) {
    final encoded = args['data'] as String;
    return {'decoded': utf8.decode(base64Decode(encoded))};
  }

  @override
  Future<ValidationResult> validateArgs(String method, Map<String, dynamic> args) async {
    switch (method) {
      case 'aesEncrypt':
        if (args['data'] is! String) return ValidationResult.invalid('data is required');
        if (args['key'] is! String) return ValidationResult.invalid('key (base64) is required');
        return ValidationResult.valid();

      case 'aesDecrypt':
        if (args['data'] is! String) return ValidationResult.invalid('data (encrypted base64) is required');
        if (args['key'] is! String) return ValidationResult.invalid('key (base64) is required');
        if (args['iv'] is! String) return ValidationResult.invalid('iv (base64) is required');
        return ValidationResult.valid();

      case 'hashSha256':
      case 'hashSha512':
      case 'hashMd5':
      case 'base64Encode':
      case 'base64Decode':
        if (args['data'] is! String) return ValidationResult.invalid('data is required');
        return ValidationResult.valid();

      case 'hmacSha256':
        if (args['data'] is! String) return ValidationResult.invalid('data is required');
        if (args['key'] is! String) return ValidationResult.invalid('key is required');
        return ValidationResult.valid();

      default:
        return ValidationResult.valid();
    }
  }
}
```

### 📄 `lib/plugins/encryption/pubspec.yaml`

```yaml
name: encryption_plugin
description: AES/RSA encryption and hashing plugin
version: 1.0.0

environment:
  sdk: ^3.0.0

dependencies:
  flutter:
    sdk: flutter
  plugin_engine:
    path: ../../packages/plugin_engine
  encrypt: ^5.0.3
  pointycastle: ^3.9.1
```

---

# بخش ۴: بروزرسانی Service Locator — فاز ۵

> فقط import‌ها و `_registerPlugins` تغییر می‌کنه. اضافه کن:

```dart
// فاز ۵
import 'package:sweetmelon/plugins/bluetooth/lib/bluetooth_plugin.dart';
import 'package:sweetmelon/plugins/nfc/lib/nfc_plugin.dart';
import 'package:sweetmelon/plugins/speech_to_text/lib/speech_to_text_plugin.dart';
import 'package:sweetmelon/plugins/text_to_speech/lib/text_to_speech_plugin.dart';
import 'package:sweetmelon/plugins/video_player/lib/video_player_plugin.dart';
import 'package:sweetmelon/plugins/in_app_browser/lib/in_app_browser_plugin.dart';
import 'package:sweetmelon/plugins/pdf_plugin/lib/pdf_bridge_plugin.dart';
import 'package:sweetmelon/plugins/encryption/lib/encryption_plugin.dart';
```

> و در `_registerPlugins()` اضافه کن:

```dart
    // ── فاز ۵ ──
    await registry.register(BluetoothPlugin(eventEmitter: emitter));
    await registry.register(NfcPlugin(eventEmitter: emitter));
    await registry.register(SpeechToTextPlugin(eventEmitter: emitter));
    await registry.register(TextToSpeechPlugin(eventEmitter: emitter));
    await registry.register(VideoPlayerPlugin(eventEmitter: emitter));
    await registry.register(InAppBrowserPlugin(eventEmitter: emitter));
    await registry.register(PdfBridgePlugin());
    await registry.register(EncryptionPlugin());
```

---

# بخش ۵: NativeSDK — فاز ۵

> اضافه شدن به `native-sdk.js`:

```javascript
    /* ───── فاز ۵ ───── */

    bluetooth: {
      isAvailable: function () { return call('bluetooth', 'isAvailable', {}); },
      isOn: function () { return call('bluetooth', 'isOn', {}); },
      startScan: function (o) { return call('bluetooth', 'startScan', o || {}, { timeout: 30000 }); },
      stopScan: function () { return call('bluetooth', 'stopScan', {}); },
      connect: function (deviceId, o) { return call('bluetooth', 'connect', Object.assign({ deviceId: deviceId }, o || {}), { timeout: 30000 }); },
      disconnect: function (deviceId) { return call('bluetooth', 'disconnect', { deviceId: deviceId }); },
      discoverServices: function (deviceId) { return call('bluetooth', 'discoverServices', { deviceId: deviceId }); },
      readCharacteristic: function (o) { return call('bluetooth', 'readCharacteristic', o); },
      writeCharacteristic: function (o) { return call('bluetooth', 'writeCharacteristic', o); },
      getConnectedDevices: function () { return call('bluetooth', 'getConnectedDevices', {}); },
      getInfo: function () { return call('bluetooth', 'getInfo', {}); }
    },

    nfc: {
      isAvailable: function () { return call('nfc', 'isAvailable', {}); },
      startSession: function (o) { return call('nfc', 'startSession', o || {}, { timeout: 60000 }); },
      stopSession: function () { return call('nfc', 'stopSession', {}); },
      writeText: function (text) { return call('nfc', 'writeText', { text: text }, { timeout: 60000 }); },
      writeUri: function (uri) { return call('nfc', 'writeUri', { uri: uri }, { timeout: 60000 }); },
      getInfo: function () { return call('nfc', 'getInfo', {}); }
    },

    speechToText: {
      initialize: function () { return call('speechToText', 'initialize', {}); },
      startListening: function (o) { return call('speechToText', 'startListening', o || {}, { timeout: 60000 }); },
      stopListening: function () { return call('speechToText', 'stopListening', {}); },
      cancelListening: function () { return call('speechToText', 'cancelListening', {}); },
      isAvailable: function () { return call('speechToText', 'isAvailable', {}); },
      getLocales: function () { return call('speechToText', 'getLocales', {}); },
      getInfo: function () { return call('speechToText', 'getInfo', {}); }
    },

    textToSpeech: {
      speak: function (text, o) { return call('textToSpeech', 'speak', Object.assign({ text: text }, o || {})); },
      stop: function () { return call('textToSpeech', 'stop', {}); },
      pause: function () { return call('textToSpeech', 'pause', {}); },
      setLanguage: function (l) { return call('textToSpeech', 'setLanguage', { language: l }); },
      setSpeechRate: function (r) { return call('textToSpeech', 'setSpeechRate', { rate: r }); },
      setPitch: function (p) { return call('textToSpeech', 'setPitch', { pitch: p }); },
      setVolume: function (v) { return call('textToSpeech', 'setVolume', { volume: v }); },
      getLanguages: function () { return call('textToSpeech', 'getLanguages', {}); },
      getVoices: function () { return call('textToSpeech', 'getVoices', {}); },
      isSpeaking: function () { return call('textToSpeech', 'isSpeaking', {}); },
      getInfo: function () { return call('textToSpeech', 'getInfo', {}); }
    },

    videoPlayer: {
      create: function (o) { return call('videoPlayer', 'create', o || {}); },
      play: function (id) { return call('videoPlayer', 'play', { playerId: id }); },
      pause: function (id) { return call('videoPlayer', 'pause', { playerId: id }); },
      seekTo: function (id, ms) { return call('videoPlayer', 'seekTo', { playerId: id, positionMs: ms }); },
      setVolume: function (id, v) { return call('videoPlayer', 'setVolume', { playerId: id, volume: v }); },
      setPlaybackSpeed: function (id, s) { return call('videoPlayer', 'setPlaybackSpeed', { playerId: id, speed: s }); },
      setLooping: function (id, l) { return call('videoPlayer', 'setLooping', { playerId: id, looping: l }); },
      getPosition: function (id) { return call('videoPlayer', 'getPosition', { playerId: id }); },
      getDuration: function (id) { return call('videoPlayer', 'getDuration', { playerId: id }); },
      getState: function (id) { return call('videoPlayer', 'getState', { playerId: id }); },
      dispose: function (id) { return call('videoPlayer', 'dispose', { playerId: id }); },
      disposeAll: function () { return call('videoPlayer', 'disposeAll', {}); },
      getInfo: function () { return call('videoPlayer', 'getInfo', {}); }
    },

    inAppBrowser: {
      open: function (url, o) { return call('inAppBrowser', 'open', Object.assign({ url: url }, o || {}), { timeout: 300000 }); },
      getInfo: function () { return call('inAppBrowser', 'getInfo', {}); }
    },

    pdf: {
      generateFromText: function (text, o) { return call('pdf', 'generateFromText', Object.assign({ text: text }, o || {})); },
      generateFromHtml: function (html, o) { return call('pdf', 'generateFromHtml', Object.assign({ html: html }, o || {})); },
      print: function (o) { return call('pdf', 'print', o || {}); },
      share: function (path) { return call('pdf', 'share', { path: path }); },
      getInfo: function () { return call('pdf', 'getInfo', {}); }
    },

    encryption: {
      aesEncrypt: function (data, key, iv) { return call('encryption', 'aesEncrypt', { data: data, key: key, iv: iv || null }); },
      aesDecrypt: function (data, key, iv) { return call('encryption', 'aesDecrypt', { data: data, key: key, iv: iv }); },
      generateAesKey: function (bits) { return call('encryption', 'generateAesKey', { bits: bits || 256 }); },
      hashSha256: function (data) { return call('encryption', 'hashSha256', { data: data }); },
      hashSha512: function (data) { return call('encryption', 'hashSha512', { data: data }); },
      hashMd5: function (data) { return call('encryption', 'hashMd5', { data: data }); },
      hmacSha256: function (data, key) { return call('encryption', 'hmacSha256', { data: data, key: key }); },
      generateRandomBytes: function (len) { return call('encryption', 'generateRandomBytes', { length: len || 32 }); },
      base64Encode: function (data) { return call('encryption', 'base64Encode', { data: data }); },
      base64Decode: function (data) { return call('encryption', 'base64Decode', { data: data }); },
      getInfo: function () { return call('encryption', 'getInfo', {}); }
    }
```

---

# خلاصه نهایی

## مجموع کل پلاگین‌ها: **35 عدد**

| # | پلاگین | فاز |
|---|--------|------|
| 1 | permission | ۱ |
| 2 | appLifecycle | ۱ |
| 3 | deviceInfo | ۱ |
| 4 | connectivity | ۱ |
| 5 | storage | ۱ |
| 6 | fileSystem | ۱ |
| 7 | http | ۱ |
| 8 | intent | ۱ |
| 9 | clipboard | ۱ |
| 10 | share | ۱ |
| 11 | camera | ۱ |
| 12 | geolocation | ۱ |
| 13 | backButton | ۳ |
| 14 | secureStorage | ۳ |
| 15 | notification | ۳ |
| 16 | statusBar | ۳ |
| 17 | orientation | ۳ |
| 18 | haptic | ۳ |
| 19 | keyboard | ۳ |
| 20 | biometrics | ۴ |
| 21 | qrScanner | ۴ |
| 22 | audio | ۴ |
| 23 | smsOtp | ۴ |
| 24 | downloadManager | ۴ |
| 25 | database | ۴ |
| 26 | contacts | ۴ |
| 27 | phoneDialer | ۴ |
| 28 | bluetooth | ۵ |
| 29 | nfc | ۵ |
| 30 | speechToText | ۵ |
| 31 | textToSpeech | ۵ |
| 32 | videoPlayer | ۵ |
| 33 | inAppBrowser | ۵ |
| 34 | pdf | ۵ |
| 35 | encryption | ۵ |

## مجموع Eventها: ۲۵+ event

| Event | پلاگین |
|-------|--------|
| app.lifecycle.change | appLifecycle |
| connectivity.change | connectivity |
| connectivity.error | connectivity |
| intent.deepLink | intent |
| intent.error | intent |
| geolocation.position | geolocation |
| geolocation.error | geolocation |
| backButton.pressed | backButton |
| notification.tap | notification |
| keyboard.change | keyboard |
| qrScanner.scanned | qrScanner |
| audio.playerState | audio |
| audio.position | audio |
| smsOtp.received | smsOtp |
| download.progress | downloadManager |
| download.complete | downloadManager |
| download.error | downloadManager |
| bluetooth.deviceFound | bluetooth |
| bluetooth.connectionState | bluetooth |
| nfc.tagDiscovered | nfc |
| nfc.error | nfc |
| speechToText.result | speechToText |
| speechToText.status | speechToText |
| speechToText.error | speechToText |
| tts.start | textToSpeech |
| tts.complete | textToSpeech |
| tts.cancel | textToSpeech |
| tts.error | textToSpeech |
| tts.progress | textToSpeech |
| videoPlayer.state | videoPlayer |
| inAppBrowser.loadStop | inAppBrowser |
| inAppBrowser.error | inAppBrowser |

---

پروژه الان **35 پلاگین** با **معماری یکسان و تمیز** داره.
با این مجموعه، هر پروژه Angular/React/Vue داخل WebView می‌تونه به **تقریبا همه قابلیت‌های نیتیو Android** دسترسی داشته باشه.
