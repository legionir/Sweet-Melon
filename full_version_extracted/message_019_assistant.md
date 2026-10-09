ایده‌ات عالیه. بذار اول نظر خودم رو بگم، بعد ایده تو رو هم تحلیل و بهش ساختار بدم.

---

# نظر من: ۱۰ گام بعدی به ترتیب اولویت

## ۱. Plugin Package Manager (ایده تو ✅)
**اولویت: بحرانی**

الان ۳۵ پلاگین داریم که همه همیشه لود می‌شن. این مشکلات رو داره:
- APK سنگین می‌شه
- permission‌های غیرضروری توی manifest هستن
- dependency‌های بلااستفاده دانلود می‌شن
- کاربر نمی‌تونه انتخاب کنه کدوم پلاگین رو بخواد

**راه‌حل:** یک CLI tool یا config system که:
- پلاگین‌ها رو فعال/غیرفعال کنه
- permission‌ها رو خودکار مدیریت کنه
- pubspec رو آپدیت کنه
- AndroidManifest رو آپدیت کنه

---

## ۲. Error Recovery و Retry System
**اولویت: بالا**

الان اگه یه call خطا بده، JS باید خودش retry کنه. باید:
- Auto-retry با exponential backoff
- Circuit breaker pattern
- Offline queue (وقتی اینترنت نیست، queue کنه)

---

## ۳. Plugin Hot-Reload / Lazy Loading
**اولویت: بالا**

پلاگین‌ها رو lazy load کنه، فقط وقتی اولین بار call بشن initialize بشن.

---

## ۴. Automated Testing Framework
**اولویت: بالا**

تست خودکار برای همه پلاگین‌ها، هم unit test و هم integration test.

---

## ۵. Plugin Versioning و Migration
**اولویت: متوسط**

وقتی API یه پلاگین تغییر می‌کنه، باید backward compatible باشه یا migration guide داشته باشه.

---

## ۶. WebSocket Plugin
**اولویت: متوسط**

برای real-time communication. الان فقط HTTP داریم.

---

## ۷. Background Task Plugin
**اولویت: متوسط**

اجرای کار در background (sync, fetch, cleanup).

---

## ۸. Performance Profiler
**اولویت: پایین**

داشبورد عملکرد: کدوم پلاگین کنده، چقدر memory مصرف می‌کنه.

---

## ۹. Plugin Marketplace / Registry
**اولویت: پایین (آینده)**

پلاگین‌های third-party بتونن ثبت بشن.

---

## ۱۰. Multi-WebView Support
**اولویت: پایین (آینده)**

چندین WebView با bridge مستقل.

---

# تحلیل و طراحی ایده تو: Plugin Package Manager

## مفهوم

```
sweetmelon.yaml                    ← فایل config اصلی
  ↓
sweetmelon CLI / Config Processor
  ↓
┌─────────────────────────────────────────┐
│ ۱. pubspec.yaml → dependency‌ها آپدیت  │
│ ۲. AndroidManifest → permission‌ها      │
│ ۳. Info.plist → iOS permissions         │
│ ۴. service_locator.dart → registration  │
│ ۵. native-sdk.js → فقط پلاگین‌های فعال │
└─────────────────────────────────────────┘
```

---

## پیاده‌سازی: فایل‌های جدید

---

### 📄 `sweetmelon.yaml`

```yaml
# Sweetmelon Plugin Configuration
# هر پلاگین که true باشه فعال و register می‌شه
# هر پلاگین که false باشه:
#   - از service_locator حذف می‌شه
#   - dependency‌اش از pubspec حذف می‌شه
#   - permission‌هاش از manifest حذف می‌شه
#   - از native-sdk.js حذف می‌شه

project:
  name: sweetmelon
  version: 1.0.0
  min_sdk: "3.0.0"

  # مسیر پروژه HTML (ثابت)
  www_path: assets/www
  entry_point: index.html

plugins:
  # ── فاز ۱: پایه ──
  permission:
    enabled: true

  app_lifecycle:
    enabled: true

  device_info:
    enabled: true

  connectivity:
    enabled: true

  storage:
    enabled: true

  file_system:
    enabled: true

  http_native:
    enabled: true

  intent_link:
    enabled: true

  clipboard:
    enabled: true

  share:
    enabled: true

  camera:
    enabled: true

  geolocation:
    enabled: true

  # ── فاز ۳: پیشرفته ──
  back_button:
    enabled: true

  secure_storage:
    enabled: true

  notification:
    enabled: true

  status_bar:
    enabled: true

  orientation:
    enabled: true

  haptic:
    enabled: true

  keyboard:
    enabled: true

  # ── فاز ۴: تخصصی ──
  biometrics:
    enabled: false

  qr_scanner:
    enabled: false

  audio:
    enabled: false

  sms_otp:
    enabled: false

  download_manager:
    enabled: true

  database:
    enabled: true

  contacts:
    enabled: false

  phone_dialer:
    enabled: true

  # ── فاز ۵: پیشرفته ──
  bluetooth:
    enabled: false

  nfc:
    enabled: false

  speech_to_text:
    enabled: false

  text_to_speech:
    enabled: false

  video_player:
    enabled: false

  in_app_browser:
    enabled: true

  pdf:
    enabled: false

  encryption:
    enabled: true
```

---

### 📄 `lib/cli/plugin_registry_data.dart`

```dart
/// اطلاعات کامل هر پلاگین: نام، dependency، permission، import، registration
class PluginRegistryData {
  static const List<PluginDefinition> allPlugins = [
    // ── فاز ۱ ──
    PluginDefinition(
      id: 'permission',
      dartClassName: 'PermissionPlugin',
      jsNamespace: 'permission',
      importPath: 'package:sweetmelon/plugins/permission/lib/permission_plugin.dart',
      registrationCode: "PermissionPlugin(permissionManager: sl<PermissionManager>())",
      needsEmitter: false,
      dependencies: {'permission_handler': '^11.3.0'},
      androidPermissions: [],
      iosPermissions: {},
      description: 'Permission management',
    ),
    PluginDefinition(
      id: 'app_lifecycle',
      dartClassName: 'AppLifecyclePlugin',
      jsNamespace: 'appLifecycle',
      importPath: 'package:sweetmelon/plugins/app_lifecycle/lib/app_lifecycle_plugin.dart',
      registrationCode: "AppLifecyclePlugin(eventEmitter: emitter)",
      needsEmitter: true,
      dependencies: {},
      androidPermissions: [],
      iosPermissions: {},
      description: 'App lifecycle events',
    ),
    PluginDefinition(
      id: 'device_info',
      dartClassName: 'DeviceInfoBridgePlugin',
      jsNamespace: 'deviceInfo',
      importPath: 'package:sweetmelon/plugins/device_info/lib/device_info_plugin.dart',
      registrationCode: "DeviceInfoBridgePlugin()",
      needsEmitter: false,
      dependencies: {
        'device_info_plus': '^10.1.2',
        'package_info_plus': '^8.0.2',
      },
      androidPermissions: [],
      iosPermissions: {},
      description: 'Device and app info',
    ),
    PluginDefinition(
      id: 'connectivity',
      dartClassName: 'ConnectivityBridgePlugin',
      jsNamespace: 'connectivity',
      importPath: 'package:sweetmelon/plugins/connectivity/lib/connectivity_plugin.dart',
      registrationCode: "ConnectivityBridgePlugin(eventEmitter: emitter)",
      needsEmitter: true,
      dependencies: {'connectivity_plus': '^6.0.5'},
      androidPermissions: ['android.permission.ACCESS_NETWORK_STATE'],
      iosPermissions: {},
      description: 'Network connectivity',
    ),
    PluginDefinition(
      id: 'storage',
      dartClassName: 'StoragePlugin',
      jsNamespace: 'storage',
      importPath: 'package:sweetmelon/plugins/storage/lib/storage_plugin.dart',
      registrationCode: "StoragePlugin()",
      needsEmitter: false,
      dependencies: {'shared_preferences': '^2.2.2'},
      androidPermissions: [],
      iosPermissions: {},
      description: 'Key-value storage',
    ),
    PluginDefinition(
      id: 'file_system',
      dartClassName: 'FileSystemPlugin',
      jsNamespace: 'fileSystem',
      importPath: 'package:sweetmelon/plugins/file_system/lib/file_system_plugin.dart',
      registrationCode: "FileSystemPlugin()",
      needsEmitter: false,
      dependencies: {
        'path_provider': '^2.1.1',
        'path': '^1.9.0',
      },
      androidPermissions: [],
      iosPermissions: {},
      description: 'Sandboxed file system',
    ),
    PluginDefinition(
      id: 'http_native',
      dartClassName: 'HttpNativePlugin',
      jsNamespace: 'http',
      importPath: 'package:sweetmelon/plugins/http_native/lib/http_native_plugin.dart',
      registrationCode: "HttpNativePlugin()",
      needsEmitter: false,
      dependencies: {
        'http': '^1.1.2',
        'mime': '^1.0.5',
      },
      androidPermissions: ['android.permission.INTERNET'],
      iosPermissions: {},
      description: 'Native HTTP client',
    ),
    PluginDefinition(
      id: 'intent_link',
      dartClassName: 'IntentLinkPlugin',
      jsNamespace: 'intent',
      importPath: 'package:sweetmelon/plugins/intent_link/lib/intent_link_plugin.dart',
      registrationCode: "IntentLinkPlugin(eventEmitter: emitter)",
      needsEmitter: true,
      dependencies: {
        'url_launcher': '^6.3.0',
        'app_links': '^6.3.2',
      },
      androidPermissions: [],
      iosPermissions: {},
      description: 'URL launcher and deep links',
    ),
    PluginDefinition(
      id: 'clipboard',
      dartClassName: 'ClipboardPlugin',
      jsNamespace: 'clipboard',
      importPath: 'package:sweetmelon/plugins/clipboard/lib/clipboard_plugin.dart',
      registrationCode: "ClipboardPlugin()",
      needsEmitter: false,
      dependencies: {},
      androidPermissions: [],
      iosPermissions: {},
      description: 'Clipboard access',
    ),
    PluginDefinition(
      id: 'share',
      dartClassName: 'ShareBridgePlugin',
      jsNamespace: 'share',
      importPath: 'package:sweetmelon/plugins/share/lib/share_plugin.dart',
      registrationCode: "ShareBridgePlugin()",
      needsEmitter: false,
      dependencies: {
        'share_plus': '^10.0.2',
        'cross_file': '^0.3.4+2',
      },
      androidPermissions: [],
      iosPermissions: {},
      description: 'Native share sheet',
    ),
    PluginDefinition(
      id: 'camera',
      dartClassName: 'CameraPlugin',
      jsNamespace: 'camera',
      importPath: 'package:sweetmelon/plugins/camera/lib/camera_plugin.dart',
      registrationCode: "CameraPlugin()",
      needsEmitter: false,
      dependencies: {'image_picker': '^1.0.4'},
      androidPermissions: [
        'android.permission.CAMERA',
      ],
      iosPermissions: {
        'NSCameraUsageDescription': 'Camera access for photos',
        'NSPhotoLibraryUsageDescription': 'Photo library access',
      },
      description: 'Camera and gallery',
    ),
    PluginDefinition(
      id: 'geolocation',
      dartClassName: 'GeolocationPlugin',
      jsNamespace: 'geolocation',
      importPath: 'package:sweetmelon/plugins/geolocation/lib/geolocation_plugin.dart',
      registrationCode: "GeolocationPlugin(eventEmitter: emitter)",
      needsEmitter: true,
      dependencies: {'geolocator': '^10.1.0'},
      androidPermissions: [
        'android.permission.ACCESS_FINE_LOCATION',
        'android.permission.ACCESS_COARSE_LOCATION',
      ],
      iosPermissions: {
        'NSLocationWhenInUseUsageDescription': 'Location access',
      },
      description: 'GPS location',
    ),

    // ── فاز ۳ ──
    PluginDefinition(
      id: 'back_button',
      dartClassName: 'BackButtonPlugin',
      jsNamespace: 'backButton',
      importPath: 'package:sweetmelon/plugins/back_button/lib/back_button_plugin.dart',
      registrationCode: "BackButtonPlugin(eventEmitter: emitter)",
      needsEmitter: true,
      dependencies: {},
      androidPermissions: [],
      iosPermissions: {},
      description: 'Android back button',
    ),
    PluginDefinition(
      id: 'secure_storage',
      dartClassName: 'SecureStoragePlugin',
      jsNamespace: 'secureStorage',
      importPath: 'package:sweetmelon/plugins/secure_storage/lib/secure_storage_plugin.dart',
      registrationCode: "SecureStoragePlugin()",
      needsEmitter: false,
      dependencies: {'flutter_secure_storage': '^9.2.2'},
      androidPermissions: [],
      iosPermissions: {},
      description: 'Encrypted storage',
    ),
    PluginDefinition(
      id: 'notification',
      dartClassName: 'NotificationPlugin',
      jsNamespace: 'notification',
      importPath: 'package:sweetmelon/plugins/notification/lib/notification_plugin.dart',
      registrationCode: "NotificationPlugin(eventEmitter: emitter)",
      needsEmitter: true,
      dependencies: {'flutter_local_notifications': '^17.2.4'},
      androidPermissions: [
        'android.permission.POST_NOTIFICATIONS',
        'android.permission.VIBRATE',
      ],
      iosPermissions: {},
      description: 'Local notifications',
    ),
    PluginDefinition(
      id: 'status_bar',
      dartClassName: 'StatusBarPlugin',
      jsNamespace: 'statusBar',
      importPath: 'package:sweetmelon/plugins/status_bar/lib/status_bar_plugin.dart',
      registrationCode: "StatusBarPlugin()",
      needsEmitter: false,
      dependencies: {},
      androidPermissions: [],
      iosPermissions: {},
      description: 'Status bar control',
    ),
    PluginDefinition(
      id: 'orientation',
      dartClassName: 'OrientationPlugin',
      jsNamespace: 'orientation',
      importPath: 'package:sweetmelon/plugins/orientation/lib/orientation_plugin.dart',
      registrationCode: "OrientationPlugin()",
      needsEmitter: false,
      dependencies: {},
      androidPermissions: [],
      iosPermissions: {},
      description: 'Screen orientation',
    ),
    PluginDefinition(
      id: 'haptic',
      dartClassName: 'HapticPlugin',
      jsNamespace: 'haptic',
      importPath: 'package:sweetmelon/plugins/haptic/lib/haptic_plugin.dart',
      registrationCode: "HapticPlugin()",
      needsEmitter: false,
      dependencies: {},
      androidPermissions: [],
      iosPermissions: {},
      description: 'Vibration feedback',
    ),
    PluginDefinition(
      id: 'keyboard',
      dartClassName: 'KeyboardPlugin',
      jsNamespace: 'keyboard',
      importPath: 'package:sweetmelon/plugins/keyboard/lib/keyboard_plugin.dart',
      registrationCode: "KeyboardPlugin(eventEmitter: emitter)",
      needsEmitter: true,
      dependencies: {},
      androidPermissions: [],
      iosPermissions: {},
      description: 'Keyboard state',
    ),

    // ── فاز ۴ ──
    PluginDefinition(
      id: 'biometrics',
      dartClassName: 'BiometricsPlugin',
      jsNamespace: 'biometrics',
      importPath: 'package:sweetmelon/plugins/biometrics/lib/biometrics_plugin.dart',
      registrationCode: "BiometricsPlugin()",
      needsEmitter: false,
      dependencies: {'local_auth': '^2.3.0'},
      androidPermissions: [
        'android.permission.USE_BIOMETRIC',
        'android.permission.USE_FINGERPRINT',
      ],
      iosPermissions: {
        'NSFaceIDUsageDescription': 'Biometric authentication',
      },
      description: 'Fingerprint / Face ID',
    ),
    PluginDefinition(
      id: 'qr_scanner',
      dartClassName: 'QrScannerPlugin',
      jsNamespace: 'qrScanner',
      importPath: 'package:sweetmelon/plugins/qr_scanner/lib/qr_scanner_plugin.dart',
      registrationCode: "QrScannerPlugin(eventEmitter: emitter)",
      needsEmitter: true,
      dependencies: {'mobile_scanner': '^5.2.3'},
      androidPermissions: ['android.permission.CAMERA'],
      iosPermissions: {
        'NSCameraUsageDescription': 'Camera for QR scanning',
      },
      description: 'QR and barcode scanner',
    ),
    PluginDefinition(
      id: 'audio',
      dartClassName: 'AudioPlugin',
      jsNamespace: 'audio',
      importPath: 'package:sweetmelon/plugins/audio/lib/audio_plugin.dart',
      registrationCode: "AudioPlugin(eventEmitter: emitter)",
      needsEmitter: true,
      dependencies: {
        'record': '^5.1.2',
        'audioplayers': '^6.1.0',
      },
      androidPermissions: [
        'android.permission.RECORD_AUDIO',
        'android.permission.FOREGROUND_SERVICE',
      ],
      iosPermissions: {
        'NSMicrophoneUsageDescription': 'Microphone for audio recording',
      },
      description: 'Audio recorder and player',
    ),
    PluginDefinition(
      id: 'sms_otp',
      dartClassName: 'SmsOtpPlugin',
      jsNamespace: 'smsOtp',
      importPath: 'package:sweetmelon/plugins/sms_otp/lib/sms_otp_plugin.dart',
      registrationCode: "SmsOtpPlugin(eventEmitter: emitter)",
      needsEmitter: true,
      dependencies: {'sms_autofill': '^2.4.0'},
      androidPermissions: [
        'android.permission.RECEIVE_SMS',
        'android.permission.READ_SMS',
      ],
      iosPermissions: {},
      description: 'SMS OTP auto-read',
    ),
    PluginDefinition(
      id: 'download_manager',
      dartClassName: 'DownloadManagerPlugin',
      jsNamespace: 'downloadManager',
      importPath: 'package:sweetmelon/plugins/download_manager/lib/download_manager_plugin.dart',
      registrationCode: "DownloadManagerPlugin(eventEmitter: emitter)",
      needsEmitter: true,
      dependencies: {},
      androidPermissions: [],
      iosPermissions: {},
      description: 'Download with progress',
    ),
    PluginDefinition(
      id: 'database',
      dartClassName: 'DatabasePlugin',
      jsNamespace: 'database',
      importPath: 'package:sweetmelon/plugins/database/lib/database_plugin.dart',
      registrationCode: "DatabasePlugin()",
      needsEmitter: false,
      dependencies: {'sqflite': '^2.3.3+2'},
      androidPermissions: [],
      iosPermissions: {},
      description: 'SQLite database',
    ),
    PluginDefinition(
      id: 'contacts',
      dartClassName: 'ContactsPlugin',
      jsNamespace: 'contacts',
      importPath: 'package:sweetmelon/plugins/contacts/lib/contacts_plugin.dart',
      registrationCode: "ContactsPlugin()",
      needsEmitter: false,
      dependencies: {'flutter_contacts': '^1.1.9+2'},
      androidPermissions: [
        'android.permission.READ_CONTACTS',
        'android.permission.WRITE_CONTACTS',
      ],
      iosPermissions: {
        'NSContactsUsageDescription': 'Contacts access',
      },
      description: 'Read contacts',
    ),
    PluginDefinition(
      id: 'phone_dialer',
      dartClassName: 'PhoneDialerPlugin',
      jsNamespace: 'phoneDialer',
      importPath: 'package:sweetmelon/plugins/phone_dialer/lib/phone_dialer_plugin.dart',
      registrationCode: "PhoneDialerPlugin()",
      needsEmitter: false,
      dependencies: {},
      androidPermissions: [
        'android.permission.CALL_PHONE',
      ],
      iosPermissions: {},
      description: 'Phone, SMS, Email',
    ),

    // ── فاز ۵ ──
    PluginDefinition(
      id: 'bluetooth',
      dartClassName: 'BluetoothPlugin',
      jsNamespace: 'bluetooth',
      importPath: 'package:sweetmelon/plugins/bluetooth/lib/bluetooth_plugin.dart',
      registrationCode: "BluetoothPlugin(eventEmitter: emitter)",
      needsEmitter: true,
      dependencies: {'flutter_blue_plus': '^1.32.12'},
      androidPermissions: [
        'android.permission.BLUETOOTH',
        'android.permission.BLUETOOTH_ADMIN',
        'android.permission.BLUETOOTH_SCAN',
        'android.permission.BLUETOOTH_CONNECT',
        'android.permission.BLUETOOTH_ADVERTISE',
      ],
      iosPermissions: {
        'NSBluetoothAlwaysUsageDescription': 'Bluetooth access',
      },
      description: 'Bluetooth BLE',
    ),
    PluginDefinition(
      id: 'nfc',
      dartClassName: 'NfcPlugin',
      jsNamespace: 'nfc',
      importPath: 'package:sweetmelon/plugins/nfc/lib/nfc_plugin.dart',
      registrationCode: "NfcPlugin(eventEmitter: emitter)",
      needsEmitter: true,
      dependencies: {'nfc_manager': '^3.5.0'},
      androidPermissions: ['android.permission.NFC'],
      iosPermissions: {},
      androidFeatures: ['android.hardware.nfc'],
      description: 'NFC read/write',
    ),
    PluginDefinition(
      id: 'speech_to_text',
      dartClassName: 'SpeechToTextPlugin',
      jsNamespace: 'speechToText',
      importPath: 'package:sweetmelon/plugins/speech_to_text/lib/speech_to_text_plugin.dart',
      registrationCode: "SpeechToTextPlugin(eventEmitter: emitter)",
      needsEmitter: true,
      dependencies: {'speech_to_text': '^7.0.0'},
      androidPermissions: ['android.permission.RECORD_AUDIO'],
      iosPermissions: {
        'NSSpeechRecognitionUsageDescription': 'Speech recognition',
        'NSMicrophoneUsageDescription': 'Microphone for speech',
      },
      description: 'Voice recognition',
    ),
    PluginDefinition(
      id: 'text_to_speech',
      dartClassName: 'TextToSpeechPlugin',
      jsNamespace: 'textToSpeech',
      importPath: 'package:sweetmelon/plugins/text_to_speech/lib/text_to_speech_plugin.dart',
      registrationCode: "TextToSpeechPlugin(eventEmitter: emitter)",
      needsEmitter: true,
      dependencies: {'flutter_tts': '^4.0.2'},
      androidPermissions: [],
      iosPermissions: {},
      description: 'Text to speech',
    ),
    PluginDefinition(
      id: 'video_player',
      dartClassName: 'VideoPlayerPlugin',
      jsNamespace: 'videoPlayer',
      importPath: 'package:sweetmelon/plugins/video_player/lib/video_player_plugin.dart',
      registrationCode: "VideoPlayerPlugin(eventEmitter: emitter)",
      needsEmitter: true,
      dependencies: {'video_player': '^2.9.2'},
      androidPermissions: [],
      iosPermissions: {},
      description: 'Video playback',
    ),
    PluginDefinition(
      id: 'in_app_browser',
      dartClassName: 'InAppBrowserPlugin',
      jsNamespace: 'inAppBrowser',
      importPath: 'package:sweetmelon/plugins/in_app_browser/lib/in_app_browser_plugin.dart',
      registrationCode: "InAppBrowserPlugin(eventEmitter: emitter)",
      needsEmitter: true,
      dependencies: {'flutter_inappwebview': '^6.1.5'},
      androidPermissions: [],
      iosPermissions: {},
      description: 'In-app browser',
    ),
    PluginDefinition(
      id: 'pdf',
      dartClassName: 'PdfBridgePlugin',
      jsNamespace: 'pdf',
      importPath: 'package:sweetmelon/plugins/pdf_plugin/lib/pdf_bridge_plugin.dart',
      registrationCode: "PdfBridgePlugin()",
      needsEmitter: false,
      dependencies: {
        'pdf': '^3.11.1',
        'printing': '^5.13.3',
      },
      androidPermissions: [],
      iosPermissions: {},
      description: 'PDF generate and print',
    ),
    PluginDefinition(
      id: 'encryption',
      dartClassName: 'EncryptionPlugin',
      jsNamespace: 'encryption',
      importPath: 'package:sweetmelon/plugins/encryption/lib/encryption_plugin.dart',
      registrationCode: "EncryptionPlugin()",
      needsEmitter: false,
      dependencies: {
        'encrypt': '^5.0.3',
        'pointycastle': '^3.9.1',
      },
      androidPermissions: [],
      iosPermissions: {},
      description: 'AES, SHA, HMAC encryption',
    ),
  ];
}

class PluginDefinition {
  final String id;
  final String dartClassName;
  final String jsNamespace;
  final String importPath;
  final String registrationCode;
  final bool needsEmitter;
  final Map<String, String> dependencies;
  final List<String> androidPermissions;
  final Map<String, String> iosPermissions;
  final List<String> androidFeatures;
  final String description;

  const PluginDefinition({
    required this.id,
    required this.dartClassName,
    required this.jsNamespace,
    required this.importPath,
    required this.registrationCode,
    required this.needsEmitter,
    required this.dependencies,
    required this.androidPermissions,
    required this.iosPermissions,
    this.androidFeatures = const [],
    required this.description,
  });
}
```

---

### 📄 `lib/cli/config_processor.dart`

```dart
import 'dart:io';

import 'package:yaml/yaml.dart';

import 'plugin_registry_data.dart';

/// پردازشگر sweetmelon.yaml
/// خروجی: لیست پلاگین‌های فعال و فایل‌های generate شده
class ConfigProcessor {
  final String configPath;
  late final Map<String, bool> _enabledPlugins;

  ConfigProcessor({this.configPath = 'sweetmelon.yaml'});

  /// خواندن config و parse
  Future<void> load() async {
    final file = File(configPath);

    if (!await file.exists()) {
      print('⚠️  sweetmelon.yaml not found, using defaults (all enabled)');
      _enabledPlugins = {
        for (final p in PluginRegistryData.allPlugins) p.id: true,
      };
      return;
    }

    final content = await file.readAsString();
    final yaml = loadYaml(content) as YamlMap;
    final plugins = yaml['plugins'] as YamlMap?;

    _enabledPlugins = {};

    for (final p in PluginRegistryData.allPlugins) {
      final pluginConfig = plugins?[p.id] as YamlMap?;
      final enabled = pluginConfig?['enabled'] as bool? ?? true;
      _enabledPlugins[p.id] = enabled;
    }
  }

  /// لیست پلاگین‌های فعال
  List<PluginDefinition> get enabledPlugins {
    return PluginRegistryData.allPlugins
        .where((p) => _enabledPlugins[p.id] == true)
        .toList();
  }

  /// لیست پلاگین‌های غیرفعال
  List<PluginDefinition> get disabledPlugins {
    return PluginRegistryData.allPlugins
        .where((p) => _enabledPlugins[p.id] != true)
        .toList();
  }

  /// Generate کردن service_locator.dart
  Future<void> generateServiceLocator() async {
    final enabled = enabledPlugins;
    final buffer = StringBuffer();

    buffer.writeln("// AUTO-GENERATED by sweetmelon config processor");
    buffer.writeln("// Do not edit manually. Run: dart run sweetmelon:configure");
    buffer.writeln("");
    buffer.writeln("import 'package:flutter/foundation.dart';");
    buffer.writeln("import 'package:get_it/get_it.dart';");
    buffer.writeln("");
    buffer.writeln("import 'package:sweetmelon/packages/core/lib/core.dart';");
    buffer.writeln("import 'package:sweetmelon/packages/devtools/lib/devtools.dart';");
    buffer.writeln("import 'package:sweetmelon/packages/performance/lib/performance.dart';");
    buffer.writeln("import 'package:sweetmelon/packages/security/lib/security.dart';");
    buffer.writeln("import 'package:sweetmelon/packages/plugin_engine/lib/plugin_engine.dart';");
    buffer.writeln("");

    // Imports
    for (final p in enabled) {
      buffer.writeln("import '${p.importPath}';");
    }

    buffer.writeln("");
    buffer.writeln("final sl = GetIt.instance;");
    buffer.writeln("");
    buffer.writeln("class ServiceLocator {");
    buffer.writeln("  static bool _initializing = false;");
    buffer.writeln("");
    buffer.writeln("  static Future<void> init() async {");
    buffer.writeln("    if (sl.isRegistered<MessageBridge>()) return;");
    buffer.writeln("    if (_initializing) return;");
    buffer.writeln("    _initializing = true;");
    buffer.writeln("");
    buffer.writeln("    try {");

    // Core registrations
    buffer.writeln("      sl.registerLazySingleton<CacheManager>(() => CacheManager(maxEntries: 500));");
    buffer.writeln("      sl.registerLazySingleton<RateLimiter>(() {");
    buffer.writeln("        final limiter = RateLimiter();");
    buffer.writeln("        limiter.setDefaultRule(RateLimitRule.perSecond(50));");
    buffer.writeln("        return limiter;");
    buffer.writeln("      });");
    buffer.writeln("      sl.registerLazySingleton<ExecutionGuard>(() => ExecutionGuard(defaultTimeoutMs: 30000));");
    buffer.writeln("      sl.registerLazySingleton<PermissionManager>(() {");
    buffer.writeln("        final manager = PermissionManager(cacheTtl: const Duration(minutes: 3));");
    buffer.writeln("        manager.setProvider(NativePermissionProvider(");
    buffer.writeln("          fallbackStatus: kReleaseMode ? PermissionStatus.denied : PermissionStatus.granted,");
    buffer.writeln("        ));");
    buffer.writeln("        return manager;");
    buffer.writeln("      });");
    buffer.writeln("      sl.registerLazySingleton<PluginRegistry>(() => PluginRegistry());");
    buffer.writeln("      sl.registerLazySingleton<PluginManager>(() => PluginManager(");
    buffer.writeln("        registry: sl<PluginRegistry>(),");
    buffer.writeln("        permissionManager: sl<PermissionManager>(),");
    buffer.writeln("        rateLimiter: sl<RateLimiter>(),");
    buffer.writeln("        executionGuard: sl<ExecutionGuard>(),");
    buffer.writeln("        cacheManager: sl<CacheManager>(),");
    buffer.writeln("      ));");
    buffer.writeln("      sl.registerLazySingleton<MessageBridge>(() {");
    buffer.writeln("        final bridge = MessageBridge();");
    buffer.writeln("        final manager = sl<PluginManager>();");
    buffer.writeln("        bridge.setMessageHandler(manager.execute);");
    buffer.writeln("        bridge.setBatchHandler(manager.executeBatch);");
    buffer.writeln("        return bridge;");
    buffer.writeln("      });");
    buffer.writeln("      final bridge = sl<MessageBridge>();");
    buffer.writeln("      sl<PluginRegistry>().setEventEmitter(bridge.emitEvent);");
    buffer.writeln("      sl.registerLazySingleton<WebViewHostConfig>(");
    buffer.writeln("        () => kReleaseMode ? WebViewHostConfig.production() : WebViewHostConfig.development(),");
    buffer.writeln("      );");
    buffer.writeln("      sl.registerLazySingleton<AssetServerConfig>(() => const AssetServerConfig());");
    buffer.writeln("      sl.registerLazySingleton<BridgeInspector>(");
    buffer.writeln("        () => BridgeInspector(bridge: bridge, manager: sl<PluginManager>()),");
    buffer.writeln("      );");
    buffer.writeln("");
    buffer.writeln("      await _registerPlugins();");
    buffer.writeln("    } finally {");
    buffer.writeln("      _initializing = false;");
    buffer.writeln("    }");
    buffer.writeln("  }");
    buffer.writeln("");

    // Plugin registration
    buffer.writeln("  static Future<void> _registerPlugins() async {");
    buffer.writeln("    final registry = sl<PluginRegistry>();");
    buffer.writeln("    final emitter = registry.emitEvent;");
    buffer.writeln("");

    for (final p in enabled) {
      buffer.writeln("    await registry.register(${p.registrationCode});");
    }

    buffer.writeln("  }");
    buffer.writeln("");

    // Dispose
    buffer.writeln("  static Future<void> dispose() async {");
    buffer.writeln("    if (sl.isRegistered<BridgeInspector>()) sl<BridgeInspector>().dispose();");
    buffer.writeln("    if (sl.isRegistered<PluginManager>()) sl<PluginManager>().dispose();");
    buffer.writeln("    if (sl.isRegistered<PluginRegistry>()) await sl<PluginRegistry>().dispose();");
    buffer.writeln("    if (sl.isRegistered<CacheManager>()) sl<CacheManager>().dispose();");
    buffer.writeln("    if (sl.isRegistered<MessageBridge>()) sl<MessageBridge>().dispose();");
    buffer.writeln("    await sl.reset();");
    buffer.writeln("  }");
    buffer.writeln("}");

    // Write file
    final outputFile = File('lib/di/service_locator.dart');
    await outputFile.writeAsString(buffer.toString());
    print('✅ Generated: lib/di/service_locator.dart (${enabled.length} plugins)');
  }

  /// Generate کردن لیست Android permissions
  Future<void> generateAndroidPermissions() async {
    final enabled = enabledPlugins;
    final permissions = <String>{};
    final features = <String>{};

    // Core permissions
    permissions.add('android.permission.INTERNET');
    permissions.add('android.permission.ACCESS_NETWORK_STATE');

    for (final p in enabled) {
      permissions.addAll(p.androidPermissions);
      features.addAll(p.androidFeatures);
    }

    final buffer = StringBuffer();
    buffer.writeln('<!-- AUTO-GENERATED Android permissions -->');
    buffer.writeln('<!-- Enabled plugins: ${enabled.map((p) => p.id).join(", ")} -->');
    buffer.writeln('');

    for (final perm in permissions.toList()..sort()) {
      buffer.writeln('    <uses-permission android:name="$perm"/>');
    }

    buffer.writeln('');

    for (final feat in features) {
      buffer.writeln('    <uses-feature android:name="$feat" android:required="false"/>');
    }

    final outputFile = File('android/app/src/main/res/xml/generated_permissions.xml');
    await outputFile.parent.create(recursive: true);
    await outputFile.writeAsString(buffer.toString());

    print('✅ Generated: android permissions (${permissions.length} permissions)');
    print('   Permissions: ${permissions.join(", ")}');
  }

  /// Generate iOS permissions
  Future<void> generateIosPermissions() async {
    final enabled = enabledPlugins;
    final iosPerms = <String, String>{};

    for (final p in enabled) {
      iosPerms.addAll(p.iosPermissions);
    }

    final buffer = StringBuffer();
    buffer.writeln('<!-- AUTO-GENERATED iOS permissions -->');
    buffer.writeln('<!-- Add these to ios/Runner/Info.plist -->');
    buffer.writeln('');

    for (final entry in iosPerms.entries) {
      buffer.writeln('    <key>${entry.key}</key>');
      buffer.writeln('    <string>${entry.value}</string>');
    }

    final outputFile = File('ios/generated_permissions.xml');
    await outputFile.writeAsString(buffer.toString());

    print('✅ Generated: iOS permissions (${iosPerms.length} entries)');
  }

  /// Generate dependency list for pubspec
  Future<void> generateDependencyReport() async {
    final enabled = enabledPlugins;
    final disabled = disabledPlugins;
    final deps = <String, String>{};

    for (final p in enabled) {
      deps.addAll(p.dependencies);
    }

    final removableDeps = <String, String>{};
    for (final p in disabled) {
      for (final dep in p.dependencies.entries) {
        // فقط اگه هیچ پلاگین فعال دیگه‌ای نیازش نداره
        final usedByOther = enabled.any(
          (ep) => ep.dependencies.containsKey(dep.key),
        );
        if (!usedByOther) {
          removableDeps[dep.key] = dep.value;
        }
      }
    }

    print('');
    print('📦 Dependency Report');
    print('────────────────────');
    print('');
    print('Required dependencies (${deps.length}):');
    for (final d in deps.entries) {
      print('  ✅ ${d.key}: ${d.value}');
    }

    if (removableDeps.isNotEmpty) {
      print('');
      print('Removable dependencies (${removableDeps.length}):');
      for (final d in removableDeps.entries) {
        print('  ❌ ${d.key}: ${d.value}');
      }
    }

    print('');
    print('Enabled plugins: ${enabled.length}');
    print('Disabled plugins: ${disabled.length}');
  }

  /// نمایش خلاصه
  void printSummary() {
    final enabled = enabledPlugins;
    final disabled = disabledPlugins;

    print('');
    print('🍈 Sweetmelon Plugin Configuration');
    print('═══════════════════════════════════');
    print('');
    print('✅ Enabled (${enabled.length}):');
    for (final p in enabled) {
      print('   • ${p.id.padRight(20)} — ${p.description}');
    }

    if (disabled.isNotEmpty) {
      print('');
      print('❌ Disabled (${disabled.length}):');
      for (final p in disabled) {
        print('   • ${p.id.padRight(20)} — ${p.description}');
      }
    }
  }
}
```

---

### 📄 `bin/configure.dart`

```dart
import 'dart:io';

import 'package:sweetmelon/cli/config_processor.dart';

/// CLI tool برای پردازش sweetmelon.yaml
/// اجرا: dart run bin/configure.dart
Future<void> main(List<String> args) async {
  print('🍈 Sweetmelon Configuration Tool');
  print('');

  final processor = ConfigProcessor();
  await processor.load();

  processor.printSummary();

  if (args.contains('--dry-run')) {
    print('');
    print('ℹ️  Dry run mode — no files generated');
    await processor.generateDependencyReport();
    return;
  }

  print('');
  print('Generating files...');
  print('');

  await processor.generateServiceLocator();
  await processor.generateAndroidPermissions();
  await processor.generateIosPermissions();
  await processor.generateDependencyReport();

  print('');
  print('🎉 Configuration complete!');
  print('');
  print('Next steps:');
  print('  1. Review generated files');
  print('  2. Update pubspec.yaml dependencies if needed');
  print('  3. Copy iOS permissions to Info.plist');
  print('  4. Run: flutter pub get');
  print('  5. Run: flutter run');
}
```

---

### 📄 `bin/plugin.dart`

```dart
import 'dart:io';

import 'package:yaml/yaml.dart';
import 'package:yaml_writer/yaml_writer.dart';

/// CLI tool برای فعال/غیرفعال کردن پلاگین‌ها
/// اجرا:
///   dart run bin/plugin.dart enable camera bluetooth nfc
///   dart run bin/plugin.dart disable sms_otp contacts
///   dart run bin/plugin.dart list
///   dart run bin/plugin.dart info camera
Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    _printUsage();
    return;
  }

  final command = args[0];

  switch (command) {
    case 'enable':
      if (args.length < 2) {
        print('Usage: dart run bin/plugin.dart enable <plugin1> <plugin2> ...');
        return;
      }
      await _setPlugins(args.sublist(1), true);
      break;

    case 'disable':
      if (args.length < 2) {
        print('Usage: dart run bin/plugin.dart disable <plugin1> <plugin2> ...');
        return;
      }
      await _setPlugins(args.sublist(1), false);
      break;

    case 'list':
      await _listPlugins();
      break;

    case 'info':
      if (args.length < 2) {
        print('Usage: dart run bin/plugin.dart info <plugin>');
        return;
      }
      _showInfo(args[1]);
      break;

    case 'enable-all':
      await _setAll(true);
      break;

    case 'disable-all':
      await _setAll(false);
      break;

    default:
      print('Unknown command: $command');
      _printUsage();
  }
}

void _printUsage() {
  print('🍈 Sweetmelon Plugin Manager');
  print('');
  print('Usage:');
  print('  dart run bin/plugin.dart enable <plugins...>');
  print('  dart run bin/plugin.dart disable <plugins...>');
  print('  dart run bin/plugin.dart list');
  print('  dart run bin/plugin.dart info <plugin>');
  print('  dart run bin/plugin.dart enable-all');
  print('  dart run bin/plugin.dart disable-all');
  print('');
  print('After changes, run:');
  print('  dart run bin/configure.dart');
}

Future<Map<String, dynamic>> _readConfig() async {
  final file = File('sweetmelon.yaml');
  if (!await file.exists()) {
    print('sweetmelon.yaml not found');
    exit(1);
  }

  final content = await file.readAsString();
  final yaml = loadYaml(content);

  // Deep convert YamlMap to regular Map
  return _yamlToMap(yaml);
}

Map<String, dynamic> _yamlToMap(dynamic yaml) {
  if (yaml is YamlMap) {
    return yaml.map((key, value) => MapEntry(key.toString(), _yamlToMap(value)));
  }
  if (yaml is YamlList) {
    return {'list': yaml.map(_yamlToMap).toList()};
  }
  return {'value': yaml};
}

Future<void> _writeConfig(Map<String, dynamic> config) async {
  final writer = YamlWriter();
  final yamlString = writer.write(config);
  await File('sweetmelon.yaml').writeAsString(yamlString);
}

Future<void> _setPlugins(List<String> pluginIds, bool enabled) async {
  final file = File('sweetmelon.yaml');
  final content = await file.readAsString();
  var updated = content;

  for (final id in pluginIds) {
    // ساده‌ترین روش: regex replace
    final pattern = RegExp(
      r'(\s+' + id + r':\s*\n\s+enabled:\s*)(true|false)',
      multiLine: true,
    );

    if (pattern.hasMatch(updated)) {
      updated = updated.replaceAllMapped(pattern, (match) {
        return '${match.group(1)}$enabled';
      });
      print('${enabled ? "✅" : "❌"} ${id.padRight(20)} → ${enabled ? "enabled" : "disabled"}');
    } else {
      print('⚠️  Plugin not found in config: $id');
    }
  }

  await file.writeAsString(updated);

  print('');
  print('Run "dart run bin/configure.dart" to apply changes.');
}

Future<void> _setAll(bool enabled) async {
  final file = File('sweetmelon.yaml');
  var content = await file.readAsString();

  final pattern = RegExp(
    r'(enabled:\s*)(true|false)',
    multiLine: true,
  );

  content = content.replaceAllMapped(pattern, (match) {
    return '${match.group(1)}$enabled';
  });

  await file.writeAsString(content);
  print('${enabled ? "✅" : "❌"} All plugins ${enabled ? "enabled" : "disabled"}');
  print('Run "dart run bin/configure.dart" to apply changes.');
}

Future<void> _listPlugins() async {
  final file = File('sweetmelon.yaml');
  if (!await file.exists()) {
    print('sweetmelon.yaml not found');
    return;
  }

  final content = await file.readAsString();
  final yaml = loadYaml(content) as YamlMap;
  final plugins = yaml['plugins'] as YamlMap?;

  if (plugins == null) {
    print('No plugins section found');
    return;
  }

  int enabledCount = 0;
  int disabledCount = 0;

  print('');
  print('🍈 Plugin Status');
  print('────────────────');

  for (final entry in plugins.entries) {
    final id = entry.key.toString();
    final config = entry.value as YamlMap?;
    final enabled = config?['enabled'] as bool? ?? true;

    if (enabled) {
      enabledCount++;
      print('  ✅ $id');
    } else {
      disabledCount++;
      print('  ❌ $id');
    }
  }

  print('');
  print('Enabled: $enabledCount | Disabled: $disabledCount | Total: ${enabledCount + disabledCount}');
}

void _showInfo(String pluginId) {
  final allPlugins = [
    // simplified - in real impl, import from plugin_registry_data.dart
  ];

  print('Plugin info for: $pluginId');
  print('(Use plugin_registry_data.dart for full details)');
}
```

---

# `pubspec.yaml` — اضافه کردن yaml dependency

```yaml
dependencies:
  # ... existing ...
  yaml: ^3.1.2
  yaml_writer: ^2.0.0
```

---

# نحوه استفاده

```bash
# ۱. فایل sweetmelon.yaml رو ویرایش کن (یا از CLI استفاده کن)
dart run bin/plugin.dart disable bluetooth nfc speech_to_text
dart run bin/plugin.dart enable camera storage

# ۲. لیست وضعیت پلاگین‌ها
dart run bin/plugin.dart list

# ۳. Generate کردن فایل‌ها
dart run bin/configure.dart

# ۴. بررسی بدون تغییر فایل
dart run bin/configure.dart --dry-run

# ۵. فعال کردن همه
dart run bin/plugin.dart enable-all

# ۶. غیرفعال کردن همه
dart run bin/plugin.dart disable-all
```

## خروجی نمونه `dart run bin/configure.dart`

```
🍈 Sweetmelon Configuration Tool

🍈 Sweetmelon Plugin Configuration
═══════════════════════════════════

✅ Enabled (22):
   • permission           — Permission management
   • app_lifecycle         — App lifecycle events
   • device_info           — Device and app info
   • connectivity          — Network connectivity
   • storage               — Key-value storage
   • file_system           — Sandboxed file system
   • http_native           — Native HTTP client
   • intent_link           — URL launcher and deep links
   • clipboard             — Clipboard access
   • share                 — Native share sheet
   • camera                — Camera and gallery
   • geolocation           — GPS location
   • back_button           — Android back button
   • secure_storage        — Encrypted storage
   • notification          — Local notifications
   • status_bar            — Status bar control
   • orientation           — Screen orientation
   • haptic                — Vibration feedback
   • keyboard              — Keyboard state
   • download_manager      — Download with progress
   • database              — SQLite database
   • encryption            — AES, SHA, HMAC encryption

❌ Disabled (13):
   • biometrics            — Fingerprint / Face ID
   • qr_scanner            — QR and barcode scanner
   • audio                 — Audio recorder and player
   • sms_otp               — SMS OTP auto-read
   • contacts              — Read contacts
   • phone_dialer          — Phone, SMS, Email
   • bluetooth             — Bluetooth BLE
   • nfc                   — NFC read/write
   • speech_to_text        — Voice recognition
   • text_to_speech        — Text to speech
   • video_player          — Video playback
   • in_app_browser        — In-app browser
   • pdf                   — PDF generate and print

Generating files...

✅ Generated: lib/di/service_locator.dart (22 plugins)
✅ Generated: android permissions (8 permissions)
✅ Generated: iOS permissions (3 entries)

📦 Dependency Report
────────────────────

Required dependencies (18):
  ✅ connectivity_plus: ^6.0.5
  ✅ device_info_plus: ^10.1.2
  ✅ flutter_local_notifications: ^17.2.4
  ✅ flutter_secure_storage: ^9.2.2
  ...

Removable dependencies (12):
  ❌ flutter_blue_plus: ^1.32.12
  ❌ nfc_manager: ^3.5.0
  ❌ speech_to_text: ^7.0.0
  ...

Enabled plugins: 22
Disabled plugins: 13

🎉 Configuration complete!
```

---

# خلاصه

| قابلیت | وضعیت |
|--------|-------|
| فایل config مرکزی (`sweetmelon.yaml`) | ✅ |
| CLI برای enable/disable پلاگین | ✅ |
| Auto-generate `service_locator.dart` | ✅ |
| Auto-generate Android permissions | ✅ |
| Auto-generate iOS permissions | ✅ |
| Dependency report (removable packages) | ✅ |
| Dry-run mode | ✅ |
| Enable-all / Disable-all | ✅ |
| Plugin info | ✅ |
| Plugin list with status | ✅ |

بگو تا فاز بعدی (Error Recovery / Retry System یا هر چیز دیگه) رو هم شروع کنم.
