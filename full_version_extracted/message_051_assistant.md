# فاز ۱۶: Firebase Integration

---

## بخش ۱: تنظیمات Firebase

### 📄 بروزرسانی `pubspec.yaml`

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

  # Core
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
  crypto: ^3.0.5

  # Connectivity & Device
  connectivity_plus: ^6.0.5
  device_info_plus: ^10.1.2
  package_info_plus: ^8.0.2
  url_launcher: ^6.3.0
  app_links: ^6.3.2
  share_plus: ^10.0.2
  cross_file: ^0.3.4+2

  # Security & Storage
  flutter_secure_storage: ^9.2.2
  flutter_local_notifications: ^17.2.4

  # Media
  local_auth: ^2.3.0
  mobile_scanner: ^5.2.3
  record: ^5.1.2
  audioplayers: ^6.1.0
  sms_autofill: ^2.4.0
  sqflite: ^2.3.3+2
  flutter_contacts: ^1.1.9+2
  image_gallery_saver: ^2.0.3
  flutter_image_compress: ^2.3.0
  archive: ^3.6.1
  file_picker: ^8.0.0+1
  in_app_review: ^2.0.9
  sensors_plus: ^5.0.1
  screen_brightness: ^1.0.1
  torch_light: ^1.0.0
  pedometer: ^4.0.1
  flutter_app_badger: ^1.5.0
  flutter_tts: ^4.0.2
  speech_to_text: ^7.0.0
  video_player: ^2.9.2
  flutter_inappwebview: ^6.1.5
  pdf: ^3.11.1
  printing: ^5.13.3
  encrypt: ^5.0.3
  pointycastle: ^3.9.1
  device_calendar: ^4.3.2
  flutter_blue_plus: ^1.32.12
  nfc_manager: ^3.5.0

  # Firebase
  firebase_core: ^3.6.0
  firebase_analytics: ^11.3.3
  firebase_crashlytics: ^4.1.3
  firebase_messaging: ^15.1.3
  firebase_remote_config: ^5.1.3
  firebase_auth: ^5.3.1
  google_sign_in: ^6.2.1

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

### 📄 `android/app/build.gradle` — اضافه کردن Firebase

```gradle
plugins {
    id "com.android.application"
    id "kotlin-android"
    id "dev.flutter.flutter-gradle-plugin"
    id "com.google.gms.google-services"
    id "com.google.firebase.crashlytics"
}

android {
    namespace "com.example.sweet_melon"
    compileSdkVersion flutter.compileSdkVersion
    ndkVersion flutter.ndkVersion

    compileOptions {
        sourceCompatibility JavaVersion.VERSION_1_8
        targetCompatibility JavaVersion.VERSION_1_8
    }

    kotlinOptions {
        jvmTarget = '1.8'
    }

    sourceSets {
        main.java.srcDirs += 'src/main/kotlin'
    }

    defaultConfig {
        applicationId "com.example.sweet_melon"
        minSdkVersion 21
        targetSdkVersion flutter.targetSdkVersion
        versionCode flutterVersionCode.toInteger()
        versionName flutterVersionName
        multiDexEnabled true
    }

    buildTypes {
        release {
            signingConfig signingConfigs.debug
            minifyEnabled true
            shrinkResources true
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
        }
    }
}

flutter {
    source '../..'
}

dependencies {
    implementation "org.jetbrains.kotlin:kotlin-stdlib-jdk7:$kotlin_version"
    implementation platform('com.google.firebase:firebase-bom:33.4.0')
    implementation 'com.google.firebase:firebase-analytics'
    implementation 'com.google.firebase:firebase-crashlytics'
    implementation 'com.google.firebase:firebase-messaging'
    implementation 'com.google.firebase:firebase-config'
    implementation 'com.google.firebase:firebase-auth'
    implementation 'com.google.android.gms:play-services-auth:21.2.0'
    implementation 'androidx.multidex:multidex:2.0.1'
}
```

---

### 📄 `android/build.gradle`

```gradle
buildscript {
    ext.kotlin_version = '1.9.10'
    repositories {
        google()
        mavenCentral()
    }

    dependencies {
        classpath 'com.android.tools.build:gradle:8.1.0'
        classpath "org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlin_version"
        classpath 'com.google.gms:google-services:4.4.2'
        classpath 'com.google.firebase:firebase-crashlytics-gradle:3.0.2'
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

rootProject.buildDir = '../build'
subprojects {
    project.buildDir = "${rootProject.buildDir}/${project.name}"
}
subprojects {
    project.evaluationDependsOn(':app')
}

tasks.register("clean", Delete) {
    delete rootProject.buildDir
}
```

---

## بخش ۲: Firebase Analytics Plugin

### 📄 `lib/plugins/firebase_analytics/lib/firebase_analytics_plugin.dart`

```dart
import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:sweetmelon/packages/core/lib/core.dart';
import 'package:sweetmelon/packages/plugin_engine/lib/plugin_engine.dart';

class FirebaseAnalyticsPlugin extends Plugin {
  FirebaseAnalytics? _analytics;
  bool _enabled = true;

  @override
  String get name => 'firebaseAnalytics';

  @override
  String get version => '1.0.0';

  @override
  String get description => 'Firebase Analytics integration';

  @override
  List<String> get supportedMethods => [
        'logEvent',
        'setUserId',
        'setUserProperty',
        'setCurrentScreen',
        'logLogin',
        'logSignUp',
        'logSearch',
        'logSelectContent',
        'logShare',
        'logPurchase',
        'logViewItem',
        'logViewItemList',
        'logAddToCart',
        'logBeginCheckout',
        'logTutorialBegin',
        'logTutorialComplete',
        'logLevelStart',
        'logLevelEnd',
        'setAnalyticsCollectionEnabled',
        'resetAnalyticsData',
        'getAppInstanceId',
        'getInfo',
      ];

  @override
  Future<void> onInitialize() async {
    try {
      _analytics = FirebaseAnalytics.instance;
      BridgeLogger.info('FirebaseAnalytics', 'Initialized');
    } catch (e) {
      BridgeLogger.error('FirebaseAnalytics', 'Init failed: $e');
    }
  }

  @override
  Future<dynamic> onCall(String method, Map<String, dynamic> args) async {
    switch (method) {
      case 'logEvent':
        return _logEvent(args);
      case 'setUserId':
        return _setUserId(args);
      case 'setUserProperty':
        return _setUserProperty(args);
      case 'setCurrentScreen':
        return _setCurrentScreen(args);
      case 'logLogin':
        return _logLogin(args);
      case 'logSignUp':
        return _logSignUp(args);
      case 'logSearch':
        return _logSearch(args);
      case 'logSelectContent':
        return _logSelectContent(args);
      case 'logShare':
        return _logShare(args);
      case 'logPurchase':
        return _logPurchase(args);
      case 'logViewItem':
        return _logViewItem(args);
      case 'logViewItemList':
        return _logViewItemList(args);
      case 'logAddToCart':
        return _logAddToCart(args);
      case 'logBeginCheckout':
        return _logBeginCheckout(args);
      case 'logTutorialBegin':
        await _analytics?.logTutorialBegin();
        return {'logged': true};
      case 'logTutorialComplete':
        await _analytics?.logTutorialComplete();
        return {'logged': true};
      case 'logLevelStart':
        return _logLevelStart(args);
      case 'logLevelEnd':
        return _logLevelEnd(args);
      case 'setAnalyticsCollectionEnabled':
        return _setCollectionEnabled(args);
      case 'resetAnalyticsData':
        await _analytics?.resetAnalyticsData();
        return {'reset': true};
      case 'getAppInstanceId':
        final id = await _analytics?.appInstanceId;
        return {'appInstanceId': id};
      case 'getInfo':
        return {
          'name': name,
          'version': version,
          'enabled': _enabled,
          'initialized': _analytics != null,
        };
      default:
        throw UnsupportedError('Method "$method" not supported');
    }
  }

  Future<Map<String, dynamic>> _logEvent(Map<String, dynamic> args) async {
    final eventName = args['name'] as String;
    final parameters = args['parameters'] as Map<String, dynamic>? ?? {};

    await _analytics?.logEvent(
      name: eventName,
      parameters: _sanitizeParameters(parameters),
    );

    BridgeLogger.debug('FirebaseAnalytics', 'Event: $eventName');
    return {'logged': true, 'event': eventName};
  }

  Future<Map<String, dynamic>> _setUserId(Map<String, dynamic> args) async {
    final id = args['id'] as String?;
    await _analytics?.setUserId(id: id);
    return {'set': true};
  }

  Future<Map<String, dynamic>> _setUserProperty(
    Map<String, dynamic> args,
  ) async {
    final name = args['name'] as String;
    final value = args['value'] as String?;
    await _analytics?.setUserProperty(name: name, value: value);
    return {'set': true, 'name': name};
  }

  Future<Map<String, dynamic>> _setCurrentScreen(
    Map<String, dynamic> args,
  ) async {
    final screenName = args['screenName'] as String;
    final screenClass = args['screenClass'] as String?;
    await _analytics?.logScreenView(
      screenName: screenName,
      screenClass: screenClass,
    );
    return {'set': true, 'screenName': screenName};
  }

  Future<Map<String, dynamic>> _logLogin(Map<String, dynamic> args) async {
    await _analytics?.logLogin(loginMethod: args['method'] as String? ?? 'email');
    return {'logged': true};
  }

  Future<Map<String, dynamic>> _logSignUp(Map<String, dynamic> args) async {
    await _analytics?.logSignUp(signUpMethod: args['method'] as String? ?? 'email');
    return {'logged': true};
  }

  Future<Map<String, dynamic>> _logSearch(Map<String, dynamic> args) async {
    await _analytics?.logSearch(searchTerm: args['searchTerm'] as String);
    return {'logged': true};
  }

  Future<Map<String, dynamic>> _logSelectContent(
    Map<String, dynamic> args,
  ) async {
    await _analytics?.logSelectContent(
      contentType: args['contentType'] as String,
      itemId: args['itemId'] as String,
    );
    return {'logged': true};
  }

  Future<Map<String, dynamic>> _logShare(Map<String, dynamic> args) async {
    await _analytics?.logShare(
      contentType: args['contentType'] as String,
      itemId: args['itemId'] as String,
      method: args['method'] as String? ?? 'unknown',
    );
    return {'logged': true};
  }

  Future<Map<String, dynamic>> _logPurchase(Map<String, dynamic> args) async {
    await _analytics?.logPurchase(
      currency: args['currency'] as String? ?? 'USD',
      value: (args['value'] as num?)?.toDouble() ?? 0,
      transactionId: args['transactionId'] as String?,
      items: _parseItems(args['items']),
    );
    return {'logged': true};
  }

  Future<Map<String, dynamic>> _logViewItem(Map<String, dynamic> args) async {
    await _analytics?.logViewItem(
      currency: args['currency'] as String? ?? 'USD',
      value: (args['value'] as num?)?.toDouble() ?? 0,
      items: _parseItems(args['items']),
    );
    return {'logged': true};
  }

  Future<Map<String, dynamic>> _logViewItemList(
    Map<String, dynamic> args,
  ) async {
    await _analytics?.logViewItemList(
      itemListId: args['itemListId'] as String?,
      itemListName: args['itemListName'] as String?,
      items: _parseItems(args['items']),
    );
    return {'logged': true};
  }

  Future<Map<String, dynamic>> _logAddToCart(
    Map<String, dynamic> args,
  ) async {
    await _analytics?.logAddToCart(
      currency: args['currency'] as String? ?? 'USD',
      value: (args['value'] as num?)?.toDouble() ?? 0,
      items: _parseItems(args['items']),
    );
    return {'logged': true};
  }

  Future<Map<String, dynamic>> _logBeginCheckout(
    Map<String, dynamic> args,
  ) async {
    await _analytics?.logBeginCheckout(
      currency: args['currency'] as String? ?? 'USD',
      value: (args['value'] as num?)?.toDouble() ?? 0,
      items: _parseItems(args['items']),
    );
    return {'logged': true};
  }

  Future<Map<String, dynamic>> _logLevelStart(
    Map<String, dynamic> args,
  ) async {
    await _analytics?.logLevelStart(levelName: args['levelName'] as String? ?? '');
    return {'logged': true};
  }

  Future<Map<String, dynamic>> _logLevelEnd(
    Map<String, dynamic> args,
  ) async {
    await _analytics?.logLevelEnd(
      levelName: args['levelName'] as String? ?? '',
      success: args['success'] as String? ?? 'true',
    );
    return {'logged': true};
  }

  Future<Map<String, dynamic>> _setCollectionEnabled(
    Map<String, dynamic> args,
  ) async {
    final enabled = args['enabled'] as bool? ?? true;
    await _analytics?.setAnalyticsCollectionEnabled(enabled);
    _enabled = enabled;
    return {'enabled': enabled};
  }

  Map<String, Object>? _sanitizeParameters(Map<String, dynamic> params) {
    if (params.isEmpty) return null;
    final result = <String, Object>{};
    params.forEach((key, value) {
      if (value is String) result[key] = value;
      else if (value is int) result[key] = value;
      else if (value is double) result[key] = value;
      else if (value is bool) result[key] = value;
      else result[key] = value.toString();
    });
    return result;
  }

  List<AnalyticsEventItem>? _parseItems(dynamic items) {
    if (items == null) return null;
    if (items is! List) return null;

    return items.map((item) {
      final m = item as Map<String, dynamic>;
      return AnalyticsEventItem(
        itemId: m['itemId'] as String?,
        itemName: m['itemName'] as String?,
        itemCategory: m['itemCategory'] as String?,
        price: (m['price'] as num?)?.toDouble(),
        quantity: (m['quantity'] as num?)?.toInt(),
        currency: m['currency'] as String?,
      );
    }).toList();
  }

  @override
  Future<ValidationResult> validateArgs(
    String method,
    Map<String, dynamic> args,
  ) async {
    switch (method) {
      case 'logEvent':
        if (args['name'] is! String || (args['name'] as String).isEmpty) {
          return ValidationResult.invalid('name is required');
        }
        return ValidationResult.valid();

      case 'setUserId':
        return ValidationResult.valid();

      case 'setUserProperty':
        if (args['name'] is! String || (args['name'] as String).isEmpty) {
          return ValidationResult.invalid('name is required');
        }
        return ValidationResult.valid();

      case 'setCurrentScreen':
        if (args['screenName'] is! String) {
          return ValidationResult.invalid('screenName is required');
        }
        return ValidationResult.valid();

      case 'logSearch':
        if (args['searchTerm'] is! String) {
          return ValidationResult.invalid('searchTerm is required');
        }
        return ValidationResult.valid();

      default:
        return ValidationResult.valid();
    }
  }
}
```

---

## بخش ۳: Firebase Crashlytics Plugin

### 📄 `lib/plugins/firebase_crashlytics/lib/firebase_crashlytics_plugin.dart`

```dart
import 'dart:async';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:sweetmelon/packages/core/lib/core.dart';
import 'package:sweetmelon/packages/plugin_engine/lib/plugin_engine.dart';

class FirebaseCrashlyticsPlugin extends Plugin {
  FirebaseCrashlytics? _crashlytics;

  @override
  String get name => 'firebaseCrashlytics';

  @override
  String get version => '1.0.0';

  @override
  String get description => 'Firebase Crashlytics integration';

  @override
  List<String> get supportedMethods => [
        'recordError',
        'log',
        'setUserId',
        'setCustomKey',
        'setCustomKeys',
        'sendUnsentReports',
        'deleteUnsentReports',
        'setCrashlyticsCollectionEnabled',
        'checkForUnsentReports',
        'crash',
        'getInfo',
      ];

  @override
  Future<void> onInitialize() async {
    try {
      _crashlytics = FirebaseCrashlytics.instance;

      // Flutter error handler
      FlutterError.onError = (details) {
        _crashlytics?.recordFlutterFatalError(details);
      };

      // Async error handler
      PlatformDispatcher.instance.onError = (error, stack) {
        _crashlytics?.recordError(error, stack, fatal: true);
        return true;
      };

      BridgeLogger.info('Crashlytics', 'Initialized');
    } catch (e) {
      BridgeLogger.error('Crashlytics', 'Init failed: $e');
    }
  }

  @override
  Future<dynamic> onCall(String method, Map<String, dynamic> args) async {
    switch (method) {
      case 'recordError':
        return _recordError(args);
      case 'log':
        return _log(args);
      case 'setUserId':
        return _setUserId(args);
      case 'setCustomKey':
        return _setCustomKey(args);
      case 'setCustomKeys':
        return _setCustomKeys(args);
      case 'sendUnsentReports':
        await _crashlytics?.sendUnsentReports();
        return {'sent': true};
      case 'deleteUnsentReports':
        await _crashlytics?.deleteUnsentReports();
        return {'deleted': true};
      case 'setCrashlyticsCollectionEnabled':
        return _setCollectionEnabled(args);
      case 'checkForUnsentReports':
        final has = await _crashlytics?.checkForUnsentReports() ?? false;
        return {'hasUnsentReports': has};
      case 'crash':
        if (!kReleaseMode) {
          _crashlytics?.crash();
          return {'crashed': true};
        }
        return {'crashed': false, 'reason': 'only_in_debug'};
      case 'getInfo':
        return {
          'name': name,
          'version': version,
          'initialized': _crashlytics != null,
          'isCrashlyticsCollectionEnabled':
              _crashlytics?.isCrashlyticsCollectionEnabled ?? false,
        };
      default:
        throw UnsupportedError('Method "$method" not supported');
    }
  }

  Future<Map<String, dynamic>> _recordError(
    Map<String, dynamic> args,
  ) async {
    final message = args['message'] as String;
    final type = args['type'] as String? ?? 'Error';
    final isFatal = args['fatal'] as bool? ?? false;
    final customKeys = args['keys'] as Map<String, dynamic>? ?? {};

    // Set custom keys before recording
    for (final entry in customKeys.entries) {
      if (entry.value is String) {
        await _crashlytics?.setCustomKey(entry.key, entry.value as String);
      } else if (entry.value is int) {
        await _crashlytics?.setCustomKey(entry.key, entry.value as int);
      } else if (entry.value is double) {
        await _crashlytics?.setCustomKey(entry.key, entry.value as double);
      } else if (entry.value is bool) {
        await _crashlytics?.setCustomKey(entry.key, entry.value as bool);
      }
    }

    await _crashlytics?.recordError(
      Exception('$type: $message'),
      null,
      fatal: isFatal,
      reason: message,
    );

    BridgeLogger.info(
      'Crashlytics',
      'Error recorded: $type (fatal: $isFatal)',
    );

    return {'recorded': true, 'fatal': isFatal};
  }

  Future<Map<String, dynamic>> _log(Map<String, dynamic> args) async {
    final message = args['message'] as String;
    await _crashlytics?.log(message);
    return {'logged': true};
  }

  Future<Map<String, dynamic>> _setUserId(Map<String, dynamic> args) async {
    final id = args['id'] as String;
    await _crashlytics?.setUserIdentifier(id);
    return {'set': true};
  }

  Future<Map<String, dynamic>> _setCustomKey(
    Map<String, dynamic> args,
  ) async {
    final key = args['key'] as String;
    final value = args['value'];

    if (value is String) {
      await _crashlytics?.setCustomKey(key, value);
    } else if (value is int) {
      await _crashlytics?.setCustomKey(key, value);
    } else if (value is double) {
      await _crashlytics?.setCustomKey(key, value);
    } else if (value is bool) {
      await _crashlytics?.setCustomKey(key, value);
    } else {
      await _crashlytics?.setCustomKey(key, value.toString());
    }

    return {'set': true, 'key': key};
  }

  Future<Map<String, dynamic>> _setCustomKeys(
    Map<String, dynamic> args,
  ) async {
    final keys = args['keys'] as Map<String, dynamic>;
    for (final entry in keys.entries) {
      await _setCustomKey({'key': entry.key, 'value': entry.value});
    }
    return {'set': true, 'count': keys.length};
  }

  Future<Map<String, dynamic>> _setCollectionEnabled(
    Map<String, dynamic> args,
  ) async {
    final enabled = args['enabled'] as bool? ?? true;
    await _crashlytics?.setCrashlyticsCollectionEnabled(enabled);
    return {'enabled': enabled};
  }

  @override
  Future<ValidationResult> validateArgs(
    String method,
    Map<String, dynamic> args,
  ) async {
    switch (method) {
      case 'recordError':
        if (args['message'] is! String || (args['message'] as String).isEmpty) {
          return ValidationResult.invalid('message is required');
        }
        return ValidationResult.valid();
      case 'log':
        if (args['message'] is! String) {
          return ValidationResult.invalid('message is required');
        }
        return ValidationResult.valid();
      case 'setUserId':
        if (args['id'] is! String) {
          return ValidationResult.invalid('id is required');
        }
        return ValidationResult.valid();
      default:
        return ValidationResult.valid();
    }
  }
}
```

---

## بخش ۴: Firebase Messaging (FCM واقعی)

### 📄 `lib/plugins/push_notification/lib/push_notification_plugin.dart` — بازنویسی کامل

```dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:sweetmelon/packages/core/lib/core.dart';
import 'package:sweetmelon/packages/plugin_engine/lib/plugin_engine.dart';

typedef PushEventEmitter = Future<void> Function(String event, dynamic data);

/// Background message handler — باید top-level function باشه
@pragma('vm:entry-point')
Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
  BridgeLogger.info('FCM', 'Background message: ${message.messageId}');
}

class PushNotificationPlugin extends Plugin {
  final PushEventEmitter? eventEmitter;

  FirebaseMessaging? _messaging;
  FlutterLocalNotificationsPlugin? _localNotifications;

  String? _token;
  bool _permissionGranted = false;
  final List<Map<String, dynamic>> _receivedMessages = [];

  StreamSubscription<RemoteMessage>? _foregroundSub;
  StreamSubscription<RemoteMessage>? _openedSub;
  StreamSubscription<String>? _tokenSub;

  static const _androidChannel = AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    description: 'This channel is used for important notifications.',
    importance: Importance.max,
  );

  PushNotificationPlugin({this.eventEmitter});

  @override
  String get name => 'pushNotification';

  @override
  String get version => '2.0.0';

  @override
  String get description => 'Firebase Cloud Messaging (FCM) push notification plugin';

  @override
  List<String> get requiredPermissions => ['notification'];

  @override
  List<String> get supportedMethods => [
        'register',
        'getToken',
        'requestPermission',
        'checkPermission',
        'getDeliveredNotifications',
        'removeDeliveredNotifications',
        'removeAllDeliveredNotifications',
        'subscribe',
        'unsubscribe',
        'getInitialMessage',
        'deleteToken',
        'setForegroundNotificationPresentationOptions',
        'getInfo',
      ];

  @override
  Future<void> onInitialize() async {
    try {
      _messaging = FirebaseMessaging.instance;

      // Background handler
      FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);

      // Local notifications setup
      _localNotifications = FlutterLocalNotificationsPlugin();

      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );

      await _localNotifications?.initialize(
        const InitializationSettings(
          android: androidSettings,
          iOS: iosSettings,
        ),
        onDidReceiveNotificationResponse: _onLocalNotificationTap,
      );

      // Android high importance channel
      if (Platform.isAndroid) {
        await _localNotifications
            ?.resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.createNotificationChannel(_androidChannel);
      }

      // Listen foreground messages
      _foregroundSub = FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Listen notification opened
      _openedSub = FirebaseMessaging.onMessageOpenedApp.listen(_handleOpenedMessage);

      // Token refresh
      _tokenSub = _messaging?.onTokenRefresh.listen((newToken) {
        _token = newToken;
        BridgeLogger.info('FCM', 'Token refreshed');
        eventEmitter?.call('push.tokenRefreshed', {'token': newToken});
      });

      // Get initial token
      _token = await _messaging?.getToken();
      BridgeLogger.info('FCM', 'Initialized, token: ${_token?.substring(0, 16)}...');
    } catch (e) {
      BridgeLogger.error('FCM', 'Init failed: $e');
    }
  }

  @override
  Future<void> onDispose() async {
    await _foregroundSub?.cancel();
    await _openedSub?.cancel();
    await _tokenSub?.cancel();
  }

  @override
  Future<dynamic> onCall(String method, Map<String, dynamic> args) async {
    switch (method) {
      case 'register':
        return _register();
      case 'getToken':
        return _getToken(args);
      case 'requestPermission':
        return _requestPermission(args);
      case 'checkPermission':
        return _checkPermission();
      case 'getDeliveredNotifications':
        return _getDeliveredNotifications();
      case 'removeDeliveredNotifications':
        return _removeDeliveredNotifications(args);
      case 'removeAllDeliveredNotifications':
        return _removeAllDeliveredNotifications();
      case 'subscribe':
        return _subscribe(args);
      case 'unsubscribe':
        return _unsubscribe(args);
      case 'getInitialMessage':
        return _getInitialMessage();
      case 'deleteToken':
        return _deleteToken();
      case 'setForegroundNotificationPresentationOptions':
        return _setForegroundOptions(args);
      case 'getInfo':
        return {
          'name': name,
          'version': version,
          'token': _token,
          'permissionGranted': _permissionGranted,
          'receivedCount': _receivedMessages.length,
          'fcmReady': _messaging != null,
          'platform': Platform.operatingSystem,
        };
      default:
        throw UnsupportedError('Method "$method" not supported');
    }
  }

  Future<Map<String, dynamic>> _register() async {
    final permResult = await _requestPermission({});
    _token = await _messaging?.getToken();

    BridgeLogger.info('FCM', 'Registered, token: ${_token?.substring(0, 16)}...');

    eventEmitter?.call('push.registered', {
      'token': _token,
      'timestamp': DateTime.now().toIso8601String(),
    });

    return {
      'registered': true,
      'token': _token,
      'permissionGranted': permResult['granted'],
    };
  }

  Future<Map<String, dynamic>> _getToken(Map<String, dynamic> args) async {
    final vapidKey = args['vapidKey'] as String?;
    _token = await _messaging?.getToken(vapidKey: vapidKey);
    return {'token': _token};
  }

  Future<Map<String, dynamic>> _requestPermission(
    Map<String, dynamic> args,
  ) async {
    final alert = args['alert'] as bool? ?? true;
    final badge = args['badge'] as bool? ?? true;
    final sound = args['sound'] as bool? ?? true;
    final provisional = args['provisional'] as bool? ?? false;
    final criticalAlert = args['criticalAlert'] as bool? ?? false;

    try {
      final settings = await _messaging?.requestPermission(
        alert: alert,
        badge: badge,
        sound: sound,
        provisional: provisional,
        criticalAlert: criticalAlert,
      );

      _permissionGranted = settings?.authorizationStatus ==
              AuthorizationStatus.authorized ||
          settings?.authorizationStatus == AuthorizationStatus.provisional;

      return {
        'granted': _permissionGranted,
        'status': settings?.authorizationStatus.name ?? 'unknown',
        'alert': settings?.alert.name,
        'badge': settings?.badge.name,
        'sound': settings?.sound.name,
      };
    } catch (e) {
      return {'granted': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> _checkPermission() async {
    try {
      final settings = await _messaging?.getNotificationSettings();
      final granted = settings?.authorizationStatus == AuthorizationStatus.authorized ||
          settings?.authorizationStatus == AuthorizationStatus.provisional;

      return {
        'granted': granted,
        'status': settings?.authorizationStatus.name ?? 'unknown',
      };
    } catch (e) {
      return {'granted': false, 'error': e.toString()};
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    final data = _messageToMap(message, foreground: true);
    _receivedMessages.add(data);

    if (_receivedMessages.length > 100) _receivedMessages.removeAt(0);

    // نمایش local notification برای foreground
    _showLocalNotification(message);

    eventEmitter?.call('push.received', data);

    BridgeLogger.info(
      'FCM',
      'Foreground message: ${message.notification?.title}',
    );
  }

  void _handleOpenedMessage(RemoteMessage message) {
    final data = _messageToMap(message, foreground: false);
    eventEmitter?.call('push.tap', data);

    BridgeLogger.info('FCM', 'Notification tapped: ${message.messageId}');
  }

  void _onLocalNotificationTap(NotificationResponse response) {
    eventEmitter?.call('push.localTap', {
      'id': response.id,
      'payload': response.payload,
    });
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    final androidDetails = AndroidNotificationDetails(
      _androidChannel.id,
      _androidChannel.name,
      channelDescription: _androidChannel.description,
      importance: Importance.max,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    await _localNotifications?.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(android: androidDetails, iOS: iosDetails),
      payload: jsonEncode(message.data),
    );
  }

  Map<String, dynamic> _messageToMap(
    RemoteMessage message, {
    bool foreground = true,
  }) {
    return {
      'messageId': message.messageId,
      'title': message.notification?.title,
      'body': message.notification?.body,
      'data': message.data,
      'from': message.from,
      'category': message.category,
      'foreground': foreground,
      'receivedAt': DateTime.now().toIso8601String(),
    };
  }

  Map<String, dynamic> _getDeliveredNotifications() {
    return {
      'notifications': _receivedMessages,
      'count': _receivedMessages.length,
    };
  }

  Map<String, dynamic> _removeDeliveredNotifications(
    Map<String, dynamic> args,
  ) {
    final ids = List<String>.from(args['ids'] as List? ?? []);
    _receivedMessages.removeWhere(
      (m) => ids.contains(m['messageId']?.toString()),
    );
    return {'removed': ids.length};
  }

  Map<String, dynamic> _removeAllDeliveredNotifications() {
    final count = _receivedMessages.length;
    _receivedMessages.clear();
    return {'removed': count};
  }

  Future<Map<String, dynamic>> _subscribe(Map<String, dynamic> args) async {
    final topic = args['topic'] as String;
    await _messaging?.subscribeToTopic(topic);
    BridgeLogger.info('FCM', 'Subscribed to: $topic');
    return {'subscribed': true, 'topic': topic};
  }

  Future<Map<String, dynamic>> _unsubscribe(Map<String, dynamic> args) async {
    final topic = args['topic'] as String;
    await _messaging?.unsubscribeFromTopic(topic);
    BridgeLogger.info('FCM', 'Unsubscribed from: $topic');
    return {'unsubscribed': true, 'topic': topic};
  }

  Future<Map<String, dynamic>> _getInitialMessage() async {
    final message = await _messaging?.getInitialMessage();
    if (message == null) return {'message': null, 'available': false};
    return {
      'message': _messageToMap(message, foreground: false),
      'available': true,
    };
  }

  Future<Map<String, dynamic>> _deleteToken() async {
    await _messaging?.deleteToken();
    _token = null;
    return {'deleted': true};
  }

  Future<Map<String, dynamic>> _setForegroundOptions(
    Map<String, dynamic> args,
  ) async {
    final alert = args['alert'] as bool? ?? true;
    final badge = args['badge'] as bool? ?? true;
    final sound = args['sound'] as bool? ?? true;

    await _messaging?.setForegroundNotificationPresentationOptions(
      alert: alert,
      badge: badge,
      sound: sound,
    );

    return {'set': true, 'alert': alert, 'badge': badge, 'sound': sound};
  }

  @override
  Future<ValidationResult> validateArgs(
    String method,
    Map<String, dynamic> args,
  ) async {
    switch (method) {
      case 'subscribe':
      case 'unsubscribe':
        if (args['topic'] is! String || (args['topic'] as String).isEmpty) {
          return ValidationResult.invalid('topic is required');
        }
        return ValidationResult.valid();
      default:
        return ValidationResult.valid();
    }
  }
}
```

---

## بخش ۵: Firebase Remote Config Plugin

### 📄 `lib/plugins/firebase_remote_config/lib/firebase_remote_config_plugin.dart`

```dart
import 'dart:async';

import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:sweetmelon/packages/core/lib/core.dart';
import 'package:sweetmelon/packages/plugin_engine/lib/plugin_engine.dart';

typedef RemoteConfigEventEmitter = Future<void> Function(
  String event,
  dynamic data,
);

class FirebaseRemoteConfigPlugin extends Plugin {
  final RemoteConfigEventEmitter? eventEmitter;

  FirebaseRemoteConfig? _remoteConfig;

  FirebaseRemoteConfigPlugin({this.eventEmitter});

  @override
  String get name => 'firebaseRemoteConfig';

  @override
  String get version => '1.0.0';

  @override
  String get description => 'Firebase Remote Config integration';

  @override
  List<String> get supportedMethods => [
        'initialize',
        'fetchAndActivate',
        'fetch',
        'activate',
        'getString',
        'getInt',
        'getDouble',
        'getBool',
        'getJson',
        'getAll',
        'setDefaults',
        'setConfigSettings',
        'getLastFetchTime',
        'getLastFetchStatus',
        'getInfo',
      ];

  @override
  Future<void> onInitialize() async {
    try {
      _remoteConfig = FirebaseRemoteConfig.instance;
      BridgeLogger.info('RemoteConfig', 'Initialized');
    } catch (e) {
      BridgeLogger.error('RemoteConfig', 'Init failed: $e');
    }
  }

  @override
  Future<dynamic> onCall(String method, Map<String, dynamic> args) async {
    switch (method) {
      case 'initialize':
        return _initialize(args);
      case 'fetchAndActivate':
        return _fetchAndActivate();
      case 'fetch':
        return _fetch(args);
      case 'activate':
        return _activate();
      case 'getString':
        return _getString(args);
      case 'getInt':
        return _getInt(args);
      case 'getDouble':
        return _getDouble(args);
      case 'getBool':
        return _getBool(args);
      case 'getJson':
        return _getJson(args);
      case 'getAll':
        return _getAll();
      case 'setDefaults':
        return _setDefaults(args);
      case 'setConfigSettings':
        return _setConfigSettings(args);
      case 'getLastFetchTime':
        return _getLastFetchTime();
      case 'getLastFetchStatus':
        return _getLastFetchStatus();
      case 'getInfo':
        return {
          'name': name,
          'version': version,
          'initialized': _remoteConfig != null,
          'lastFetchStatus': _remoteConfig?.lastFetchStatus.name,
        };
      default:
        throw UnsupportedError('Method "$method" not supported');
    }
  }

  Future<Map<String, dynamic>> _initialize(Map<String, dynamic> args) async {
    final minimumFetchIntervalMs =
        (args['minimumFetchIntervalMs'] as num?)?.toInt() ?? 3600000;
    final fetchTimeoutMs =
        (args['fetchTimeoutMs'] as num?)?.toInt() ?? 60000;
    final defaults = args['defaults'] as Map<String, dynamic>? ?? {};

    await _remoteConfig?.setConfigSettings(
      RemoteConfigSettings(
        fetchTimeout: Duration(milliseconds: fetchTimeoutMs),
        minimumFetchInterval: Duration(milliseconds: minimumFetchIntervalMs),
      ),
    );

    if (defaults.isNotEmpty) {
      await _remoteConfig?.setDefaults(
        defaults.map((key, value) => MapEntry(key, value)),
      );
    }

    return {
      'initialized': true,
      'minimumFetchIntervalMs': minimumFetchIntervalMs,
      'fetchTimeoutMs': fetchTimeoutMs,
    };
  }

  Future<Map<String, dynamic>> _fetchAndActivate() async {
    try {
      final updated = await _remoteConfig?.fetchAndActivate() ?? false;

      BridgeLogger.info(
        'RemoteConfig',
        'Fetched and activated (updated: $updated)',
      );

      if (updated && eventEmitter != null) {
        await eventEmitter!('remoteConfig.updated', {
          'timestamp': DateTime.now().toIso8601String(),
        });
      }

      return {'fetched': true, 'activated': true, 'updated': updated};
    } catch (e) {
      BridgeLogger.error('RemoteConfig', 'FetchAndActivate error: $e');
      return {'fetched': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> _fetch(Map<String, dynamic> args) async {
    final expirationDurationMs =
        (args['expirationDurationMs'] as num?)?.toInt();

    try {
      if (expirationDurationMs != null) {
        await _remoteConfig?.fetch(
          expiration: Duration(milliseconds: expirationDurationMs),
        );
      } else {
        await _remoteConfig?.fetch();
      }
      return {'fetched': true};
    } catch (e) {
      return {'fetched': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> _activate() async {
    final activated = await _remoteConfig?.activate() ?? false;
    return {'activated': activated};
  }

  Map<String, dynamic> _getString(Map<String, dynamic> args) {
    final key = args['key'] as String;
    final value = _remoteConfig?.getString(key) ?? '';
    return {'key': key, 'value': value};
  }

  Map<String, dynamic> _getInt(Map<String, dynamic> args) {
    final key = args['key'] as String;
    final value = _remoteConfig?.getInt(key) ?? 0;
    return {'key': key, 'value': value};
  }

  Map<String, dynamic> _getDouble(Map<String, dynamic> args) {
    final key = args['key'] as String;
    final value = _remoteConfig?.getDouble(key) ?? 0.0;
    return {'key': key, 'value': value};
  }

  Map<String, dynamic> _getBool(Map<String, dynamic> args) {
    final key = args['key'] as String;
    final value = _remoteConfig?.getBool(key) ?? false;
    return {'key': key, 'value': value};
  }

  Map<String, dynamic> _getJson(Map<String, dynamic> args) {
    final key = args['key'] as String;
    final raw = _remoteConfig?.getString(key) ?? '{}';

    try {
      import 'dart:convert';
      final value = jsonDecode(raw);
      return {'key': key, 'value': value};
    } catch (_) {
      return {'key': key, 'value': null, 'raw': raw};
    }
  }

  Map<String, dynamic> _getAll() {
    final all = _remoteConfig?.getAll() ?? {};
    return {
      'values': all.map(
        (key, value) => MapEntry(key, {
          'source': value.source.name,
          'value': value.asString(),
        }),
      ),
      'count': all.length,
    };
  }

  Future<Map<String, dynamic>> _setDefaults(
    Map<String, dynamic> args,
  ) async {
    final defaults = args['defaults'] as Map<String, dynamic>;
    await _remoteConfig?.setDefaults(
      defaults.map((key, value) => MapEntry(key, value)),
    );
    return {'set': true, 'count': defaults.length};
  }

  Future<Map<String, dynamic>> _setConfigSettings(
    Map<String, dynamic> args,
  ) async {
    final fetchTimeout = (args['fetchTimeoutMs'] as num?)?.toInt() ?? 60000;
    final minimumInterval =
        (args['minimumFetchIntervalMs'] as num?)?.toInt() ?? 3600000;

    await _remoteConfig?.setConfigSettings(
      RemoteConfigSettings(
        fetchTimeout: Duration(milliseconds: fetchTimeout),
        minimumFetchInterval: Duration(milliseconds: minimumInterval),
      ),
    );

    return {
      'set': true,
      'fetchTimeoutMs': fetchTimeout,
      'minimumFetchIntervalMs': minimumInterval,
    };
  }

  Map<String, dynamic> _getLastFetchTime() {
    final time = _remoteConfig?.lastFetchTime;
    return {
      'timestamp': time?.toIso8601String(),
      'ms': time?.millisecondsSinceEpoch,
    };
  }

  Map<String, dynamic> _getLastFetchStatus() {
    final status = _remoteConfig?.lastFetchStatus;
    return {'status': status?.name ?? 'unknown'};
  }

  @override
  Future<ValidationResult> validateArgs(
    String method,
    Map<String, dynamic> args,
  ) async {
    switch (method) {
      case 'getString':
      case 'getInt':
      case 'getDouble':
      case 'getBool':
      case 'getJson':
        if (args['key'] is! String || (args['key'] as String).isEmpty) {
          return ValidationResult.invalid('key is required');
        }
        return ValidationResult.valid();
      case 'setDefaults':
        if (args['defaults'] is! Map) {
          return ValidationResult.invalid('defaults must be a map');
        }
        return ValidationResult.valid();
      default:
        return ValidationResult.valid();
    }
  }
}
```

---

## بخش ۶: Firebase Auth Plugin

### 📄 `lib/plugins/firebase_auth/lib/firebase_auth_plugin.dart`

```dart
import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sweetmelon/packages/core/lib/core.dart';
import 'package:sweetmelon/packages/plugin_engine/lib/plugin_engine.dart';

typedef AuthEventEmitter = Future<void> Function(String event, dynamic data);

class FirebaseAuthPlugin extends Plugin {
  final AuthEventEmitter? eventEmitter;

  FirebaseAuth? _auth;
  GoogleSignIn? _googleSignIn;
  StreamSubscription<User?>? _authStateSub;

  FirebaseAuthPlugin({this.eventEmitter});

  @override
  String get name => 'firebaseAuth';

  @override
  String get version => '1.0.0';

  @override
  String get description => 'Firebase Authentication plugin';

  @override
  List<String> get supportedMethods => [
        'getCurrentUser',
        'signInWithEmail',
        'signUpWithEmail',
        'signInWithGoogle',
        'signInAnonymously',
        'signOut',
        'sendPasswordResetEmail',
        'updatePassword',
        'updateEmail',
        'updateProfile',
        'deleteAccount',
        'reloadUser',
        'sendEmailVerification',
        'signInWithCustomToken',
        'getIdToken',
        'isSignedIn',
        'getInfo',
      ];

  @override
  Future<void> onInitialize() async {
    try {
      _auth = FirebaseAuth.instance;
      _googleSignIn = GoogleSignIn();

      _authStateSub = _auth?.authStateChanges().listen((user) {
        if (eventEmitter != null) {
          eventEmitter!(
            'auth.stateChanged',
            {
              'user': user != null ? _userToMap(user) : null,
              'signedIn': user != null,
              'timestamp': DateTime.now().toIso8601String(),
            },
          );
        }
      });

      BridgeLogger.info('FirebaseAuth', 'Initialized');
    } catch (e) {
      BridgeLogger.error('FirebaseAuth', 'Init failed: $e');
    }
  }

  @override
  Future<void> onDispose() async {
    await _authStateSub?.cancel();
  }

  @override
  Future<dynamic> onCall(String method, Map<String, dynamic> args) async {
    switch (method) {
      case 'getCurrentUser':
        return _getCurrentUser();
      case 'signInWithEmail':
        return _signInWithEmail(args);
      case 'signUpWithEmail':
        return _signUpWithEmail(args);
      case 'signInWithGoogle':
        return _signInWithGoogle();
      case 'signInAnonymously':
        return _signInAnonymously();
      case 'signOut':
        return _signOut();
      case 'sendPasswordResetEmail':
        return _sendPasswordResetEmail(args);
      case 'updatePassword':
        return _updatePassword(args);
      case 'updateEmail':
        return _updateEmail(args);
      case 'updateProfile':
        return _updateProfile(args);
      case 'deleteAccount':
        return _deleteAccount();
      case 'reloadUser':
        return _reloadUser();
      case 'sendEmailVerification':
        return _sendEmailVerification();
      case 'signInWithCustomToken':
        return _signInWithCustomToken(args);
      case 'getIdToken':
        return _getIdToken(args);
      case 'isSignedIn':
        return {'signedIn': _auth?.currentUser != null};
      case 'getInfo':
        return {
          'name': name,
          'version': version,
          'initialized': _auth != null,
          'signedIn': _auth?.currentUser != null,
          'userId': _auth?.currentUser?.uid,
        };
      default:
        throw UnsupportedError('Method "$method" not supported');
    }
  }

  Map<String, dynamic> _getCurrentUser() {
    final user = _auth?.currentUser;
    if (user == null) {
      return {'user': null, 'signedIn': false};
    }
    return {'user': _userToMap(user), 'signedIn': true};
  }

  Future<Map<String, dynamic>> _signInWithEmail(
    Map<String, dynamic> args,
  ) async {
    final email = args['email'] as String;
    final password = args['password'] as String;

    try {
      final credential = await _auth?.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      BridgeLogger.info('FirebaseAuth', 'Signed in: ${credential?.user?.email}');

      return {
        'success': true,
        'user': credential?.user != null ? _userToMap(credential!.user!) : null,
        'isNewUser': credential?.additionalUserInfo?.isNewUser ?? false,
      };
    } on FirebaseAuthException catch (e) {
      return _authError(e);
    }
  }

  Future<Map<String, dynamic>> _signUpWithEmail(
    Map<String, dynamic> args,
  ) async {
    final email = args['email'] as String;
    final password = args['password'] as String;
    final displayName = args['displayName'] as String?;

    try {
      final credential = await _auth?.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (displayName != null && credential?.user != null) {
        await credential!.user!.updateDisplayName(displayName);
        await credential.user!.reload();
      }

      await credential?.user?.sendEmailVerification();

      return {
        'success': true,
        'user': credential?.user != null ? _userToMap(credential!.user!) : null,
        'isNewUser': true,
      };
    } on FirebaseAuthException catch (e) {
      return _authError(e);
    }
  }

  Future<Map<String, dynamic>> _signInWithGoogle() async {
    try {
      final googleAccount = await _googleSignIn?.signIn();
      if (googleAccount == null) {
        return {'success': false, 'reason': 'cancelled'};
      }

      final googleAuth = await googleAccount.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final result = await _auth?.signInWithCredential(credential);

      return {
        'success': true,
        'user': result?.user != null ? _userToMap(result!.user!) : null,
        'isNewUser': result?.additionalUserInfo?.isNewUser ?? false,
        'provider': 'google',
      };
    } on FirebaseAuthException catch (e) {
      return _authError(e);
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> _signInAnonymously() async {
    try {
      final credential = await _auth?.signInAnonymously();
      return {
        'success': true,
        'user': credential?.user != null ? _userToMap(credential!.user!) : null,
        'isAnonymous': true,
      };
    } on FirebaseAuthException catch (e) {
      return _authError(e);
    }
  }

  Future<Map<String, dynamic>> _signOut() async {
    await _googleSignIn?.signOut();
    await _auth?.signOut();
    BridgeLogger.info('FirebaseAuth', 'Signed out');
    return {'success': true};
  }

  Future<Map<String, dynamic>> _sendPasswordResetEmail(
    Map<String, dynamic> args,
  ) async {
    final email = args['email'] as String;
    try {
      await _auth?.sendPasswordResetEmail(email: email);
      return {'success': true, 'email': email};
    } on FirebaseAuthException catch (e) {
      return _authError(e);
    }
  }

  Future<Map<String, dynamic>> _updatePassword(
    Map<String, dynamic> args,
  ) async {
    final newPassword = args['newPassword'] as String;
    try {
      await _auth?.currentUser?.updatePassword(newPassword);
      return {'success': true};
    } on FirebaseAuthException catch (e) {
      return _authError(e);
    }
  }

  Future<Map<String, dynamic>> _updateEmail(
    Map<String, dynamic> args,
  ) async {
    final newEmail = args['newEmail'] as String;
    try {
      await _auth?.currentUser?.verifyBeforeUpdateEmail(newEmail);
      return {'success': true, 'pendingVerification': true};
    } on FirebaseAuthException catch (e) {
      return _authError(e);
    }
  }

  Future<Map<String, dynamic>> _updateProfile(
    Map<String, dynamic> args,
  ) async {
    final displayName = args['displayName'] as String?;
    final photoURL = args['photoURL'] as String?;

    try {
      if (displayName != null) {
        await _auth?.currentUser?.updateDisplayName(displayName);
      }
      if (photoURL != null) {
        await _auth?.currentUser?.updatePhotoURL(photoURL);
      }
      await _auth?.currentUser?.reload();
      return {'success': true};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> _deleteAccount() async {
    try {
      await _auth?.currentUser?.delete();
      return {'success': true};
    } on FirebaseAuthException catch (e) {
      return _authError(e);
    }
  }

  Future<Map<String, dynamic>> _reloadUser() async {
    await _auth?.currentUser?.reload();
    return _getCurrentUser();
  }

  Future<Map<String, dynamic>> _sendEmailVerification() async {
    try {
      await _auth?.currentUser?.sendEmailVerification();
      return {'success': true};
    } on FirebaseAuthException catch (e) {
      return _authError(e);
    }
  }

  Future<Map<String, dynamic>> _signInWithCustomToken(
    Map<String, dynamic> args,
  ) async {
    final token = args['token'] as String;
    try {
      final credential = await _auth?.signInWithCustomToken(token);
      return {
        'success': true,
        'user': credential?.user != null ? _userToMap(credential!.user!) : null,
      };
    } on FirebaseAuthException catch (e) {
      return _authError(e);
    }
  }

  Future<Map<String, dynamic>> _getIdToken(Map<String, dynamic> args) async {
    final forceRefresh = args['forceRefresh'] as bool? ?? false;
    try {
      final token = await _auth?.currentUser?.getIdToken(forceRefresh);
      return {'token': token};
    } catch (e) {
      return {'token': null, 'error': e.toString()};
    }
  }

  Map<String, dynamic> _userToMap(User user) {
    return {
      'uid': user.uid,
      'email': user.email,
      'emailVerified': user.emailVerified,
      'displayName': user.displayName,
      'photoURL': user.photoURL,
      'phoneNumber': user.phoneNumber,
      'isAnonymous': user.isAnonymous,
      'creationTime': user.metadata.creationTime?.toIso8601String(),
      'lastSignInTime': user.metadata.lastSignInTime?.toIso8601String(),
      'providerData': user.providerData.map((p) => {
            'uid': p.uid,
            'email': p.email,
            'displayName': p.displayName,
            'photoURL': p.photoURL,
            'providerId': p.providerId,
            'phoneNumber': p.phoneNumber,
          }).toList(),
    };
  }

  Map<String, dynamic> _authError(FirebaseAuthException e) {
    return {
      'success': false,
      'errorCode': e.code,
      'errorMessage': _localizeError(e.code),
      'originalMessage': e.message,
    };
  }

  String _localizeError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No user found with this email address.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'email-already-in-use':
        return 'This email is already registered.';
      case 'weak-password':
        return 'Password is too weak.';
      case 'invalid-email':
        return 'Invalid email address.';
      case 'network-request-failed':
        return 'Network error. Please check your connection.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'requires-recent-login':
        return 'Please sign in again to perform this action.';
      case 'invalid-credential':
        return 'Invalid credentials.';
      default:
        return 'Authentication error: $code';
    }
  }

  @override
  Future<ValidationResult> validateArgs(
    String method,
    Map<String, dynamic> args,
  ) async {
    switch (method) {
      case 'signInWithEmail':
      case 'signUpWithEmail':
        if (args['email'] is! String || (args['email'] as String).isEmpty) {
          return ValidationResult.invalid('email is required');
        }
        if (args['password'] is! String || (args['password'] as String).isEmpty) {
          return ValidationResult.invalid('password is required');
        }
        return ValidationResult.valid();
      case 'sendPasswordResetEmail':
        if (args['email'] is! String) {
          return ValidationResult.invalid('email is required');
        }
        return ValidationResult.valid();
      default:
        return ValidationResult.valid();
    }
  }
}
```

---

## بخش ۷: ثبت پلاگین‌های Firebase

### 📄 `lib/di/service_locator.dart` — اضافه شده

```dart
// Firebase imports
import 'package:sweetmelon/plugins/firebase_analytics/lib/firebase_analytics_plugin.dart';
import 'package:sweetmelon/plugins/firebase_crashlytics/lib/firebase_crashlytics_plugin.dart';
import 'package:sweetmelon/plugins/firebase_remote_config/lib/firebase_remote_config_plugin.dart';
import 'package:sweetmelon/plugins/firebase_auth/lib/firebase_auth_plugin.dart';
```

> در `_registerPlugins()`:

```dart
    // ── Firebase ──
    await registry.register(FirebaseAnalyticsPlugin());
    await registry.register(FirebaseCrashlyticsPlugin());
    await registry.register(FirebaseAuthPlugin(eventEmitter: emitter));
    await registry.register(FirebaseRemoteConfigPlugin(eventEmitter: emitter));
```

> بروزرسانی push notification:

```dart
    // بروزرسانی PushNotification به نسخه FCM واقعی
    await registry.register(PushNotificationPlugin(eventEmitter: emitter));
```

---

## بخش ۸: main.dart — Firebase Init

### 📄 `lib/main.dart`

```dart
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'app.dart';
import 'di/service_locator.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase init
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await ServiceLocator.init();
  runApp(const BridgeApp());
}
```

---

## بخش ۹: NativeSDK — Firebase

```javascript
    // Firebase Analytics
    firebaseAnalytics: {
      logEvent: function (name, parameters) { return call('firebaseAnalytics', 'logEvent', { name: name, parameters: parameters || {} }); },
      setUserId: function (id) { return call('firebaseAnalytics', 'setUserId', { id: id }); },
      setUserProperty: function (name, value) { return call('firebaseAnalytics', 'setUserProperty', { name: name, value: value }); },
      setCurrentScreen: function (screenName, screenClass) { return call('firebaseAnalytics', 'setCurrentScreen', { screenName: screenName, screenClass: screenClass }); },
      logLogin: function (method) { return call('firebaseAnalytics', 'logLogin', { method: method || 'email' }); },
      logSignUp: function (method) { return call('firebaseAnalytics', 'logSignUp', { method: method || 'email' }); },
      logSearch: function (term) { return call('firebaseAnalytics', 'logSearch', { searchTerm: term }); },
      logPurchase: function (o) { return call('firebaseAnalytics', 'logPurchase', o || {}); },
      logViewItem: function (o) { return call('firebaseAnalytics', 'logViewItem', o || {}); },
      logAddToCart: function (o) { return call('firebaseAnalytics', 'logAddToCart', o || {}); },
      setAnalyticsCollectionEnabled: function (enabled) { return call('firebaseAnalytics', 'setAnalyticsCollectionEnabled', { enabled: enabled }); },
      resetAnalyticsData: function () { return call('firebaseAnalytics', 'resetAnalyticsData', {}); },
      getAppInstanceId: function () { return call('firebaseAnalytics', 'getAppInstanceId', {}); },
      getInfo: function () { return call('firebaseAnalytics', 'getInfo', {}); }
    },

    // Firebase Crashlytics
    firebaseCrashlytics: {
      recordError: function (message, type, options) { return call('firebaseCrashlytics', 'recordError', Object.assign({ message: message, type: type || 'Error' }, options || {})); },
      log: function (message) { return call('firebaseCrashlytics', 'log', { message: message }); },
      setUserId: function (id) { return call('firebaseCrashlytics', 'setUserId', { id: id }); },
      setCustomKey: function (key, value) { return call('firebaseCrashlytics', 'setCustomKey', { key: key, value: value }); },
      setCustomKeys: function (keys) { return call('firebaseCrashlytics', 'setCustomKeys', { keys: keys }); },
      sendUnsentReports: function () { return call('firebaseCrashlytics', 'sendUnsentReports', {}); },
      setCrashlyticsCollectionEnabled: function (enabled) { return call('firebaseCrashlytics', 'setCrashlyticsCollectionEnabled', { enabled: enabled }); },
      getInfo: function () { return call('firebaseCrashlytics', 'getInfo', {}); }
    },

    // Firebase Remote Config
    firebaseRemoteConfig: {
      initialize: function (o) { return call('firebaseRemoteConfig', 'initialize', o || {}); },
      fetchAndActivate: function () { return call('firebaseRemoteConfig', 'fetchAndActivate', {}); },
      fetch: function (o) { return call('firebaseRemoteConfig', 'fetch', o || {}); },
      activate: function () { return call('firebaseRemoteConfig', 'activate', {}); },
      getString: function (key) { return call('firebaseRemoteConfig', 'getString', { key: key }); },
      getInt: function (key) { return call('firebaseRemoteConfig', 'getInt', { key: key }); },
      getDouble: function (key) { return call('firebaseRemoteConfig', 'getDouble', { key: key }); },
      getBool: function (key) { return call('firebaseRemoteConfig', 'getBool', { key: key }); },
      getJson: function (key) { return call('firebaseRemoteConfig', 'getJson', { key: key }); },
      getAll: function () { return call('firebaseRemoteConfig', 'getAll', {}); },
      setDefaults: function (defaults) { return call('firebaseRemoteConfig', 'setDefaults', { defaults: defaults }); },
      getLastFetchStatus: function () { return call('firebaseRemoteConfig', 'getLastFetchStatus', {}); },
      getInfo: function () { return call('firebaseRemoteConfig', 'getInfo', {}); }
    },

    // Firebase Auth
    firebaseAuth: {
      getCurrentUser: function () { return call('firebaseAuth', 'getCurrentUser', {}); },
      signInWithEmail: function (email, password) { return call('firebaseAuth', 'signInWithEmail', { email: email, password: password }); },
      signUpWithEmail: function (email, password, displayName) { return call('firebaseAuth', 'signUpWithEmail', { email: email, password: password, displayName: displayName }); },
      signInWithGoogle: function () { return call('firebaseAuth', 'signInWithGoogle', {}); },
      signInAnonymously: function () { return call('firebaseAuth', 'signInAnonymously', {}); },
      signOut: function () { return call('firebaseAuth', 'signOut', {}); },
      sendPasswordResetEmail: function (email) { return call('firebaseAuth', 'sendPasswordResetEmail', { email: email }); },
      updatePassword: function (newPassword) { return call('firebaseAuth', 'updatePassword', { newPassword: newPassword }); },
      updateProfile: function (o) { return call('firebaseAuth', 'updateProfile', o || {}); },
      deleteAccount: function () { return call('firebaseAuth', 'deleteAccount', {}); },
      sendEmailVerification: function () { return call('firebaseAuth', 'sendEmailVerification', {}); },
      getIdToken: function (forceRefresh) { return call('firebaseAuth', 'getIdToken', { forceRefresh: !!forceRefresh }); },
      isSignedIn: function () { return call('firebaseAuth', 'isSignedIn', {}); },
      getInfo: function () { return call('firebaseAuth', 'getInfo', {}); }
    },
```

---

## بخش ۱۰: تست‌ها

### 📄 `test/plugins/firebase_analytics_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sweetmelon/plugins/firebase_analytics/lib/firebase_analytics_plugin.dart';
import '../helpers/plugin_test_utils.dart';

void main() {
  group('FirebaseAnalyticsPlugin', () {
    late FirebaseAnalyticsPlugin plugin;

    setUp(() async {
      plugin = FirebaseAnalyticsPlugin();
      // Note: Firebase.initializeApp() باید قبل از تست‌ها صدا زده بشه
      // در تست واقعی از firebase_core_test_utils استفاده می‌شه
    });

    test('info', () {
      expect(plugin.name, 'firebaseAnalytics');
      expect(plugin.version, '1.0.0');
      expect(plugin.supportedMethods, isNotEmpty);
    });

    test('validation requires event name', () async {
      final r1 = await plugin.validateArgs('logEvent', {});
      expect(r1.isValid, false);

      final r2 = await plugin.validateArgs('logEvent', {'name': 'test_event'});
      expect(r2.isValid, true);
    });

    test('validation requires screen name', () async {
      final r = await plugin.validateArgs('setCurrentScreen', {});
      expect(r.isValid, false);
    });

    test('validation requires search term', () async {
      final r = await plugin.validateArgs('logSearch', {});
      expect(r.isValid, false);
    });

    test('supports all declared methods', () {
      for (final method in plugin.supportedMethods) {
        expect(plugin.supportsMethod(method), true);
      }
    });
  });
}
```

### 📄 `test/plugins/firebase_auth_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sweetmelon/plugins/firebase_auth/lib/firebase_auth_plugin.dart';
import '../helpers/plugin_test_utils.dart';

void main() {
  group('FirebaseAuthPlugin', () {
    late FirebaseAuthPlugin plugin;

    setUp(() async {
      plugin = FirebaseAuthPlugin();
    });

    test('info', () {
      expect(plugin.name, 'firebaseAuth');
      expect(plugin.version, '1.0.0');
    });

    test('validation requires email and password for signIn', () async {
      final r1 = await plugin.validateArgs('signInWithEmail', {});
      expect(r1.isValid, false);

      final r2 = await plugin.validateArgs('signInWithEmail', {
        'email': 'test@test.com',
      });
      expect(r2.isValid, false);

      final r3 = await plugin.validateArgs('signInWithEmail', {
        'email': 'test@test.com',
        'password': 'pass123',
      });
      expect(r3.isValid, true);
    });

    test('validation requires email for signUp', () async {
      final r = await plugin.validateArgs('signUpWithEmail', {
        'email': 'test@test.com',
        'password': 'pass123',
      });
      expect(r.isValid, true);
    });

    test('validation requires email for password reset', () async {
      final r1 = await plugin.validateArgs('sendPasswordResetEmail', {});
      expect(r1.isValid, false);

      final r2 = await plugin.validateArgs('sendPasswordResetEmail', {
        'email': 'test@test.com',
      });
      expect(r2.isValid, true);
    });

    test('all methods are declared', () {
      final expectedMethods = [
        'getCurrentUser', 'signInWithEmail', 'signUpWithEmail',
        'signInWithGoogle', 'signOut', 'isSignedIn'
      ];
      for (final method in expectedMethods) {
        expect(plugin.supportsMethod(method), true, reason: 'Missing: $method');
      }
    });
  });
}
```

### 📄 `test/plugins/firebase_remote_config_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sweetmelon/plugins/firebase_remote_config/lib/firebase_remote_config_plugin.dart';

void main() {
  group('FirebaseRemoteConfigPlugin', () {
    late FirebaseRemoteConfigPlugin plugin;

    setUp(() async {
      plugin = FirebaseRemoteConfigPlugin();
    });

    test('info', () {
      expect(plugin.name, 'firebaseRemoteConfig');
      expect(plugin.version, '1.0.0');
    });

    test('validation requires key for getters', () async {
      final methods = ['getString', 'getInt', 'getDouble', 'getBool', 'getJson'];
      for (final method in methods) {
        final r = await plugin.validateArgs(method, {});
        expect(r.isValid, false, reason: '$method should require key');

        final r2 = await plugin.validateArgs(method, {'key': 'my_key'});
        expect(r2.isValid, true, reason: '$method with key should be valid');
      }
    });

    test('validation requires map for setDefaults', () async {
      final r = await plugin.validateArgs('setDefaults', {'defaults': 'invalid'});
      expect(r.isValid, false);

      final r2 = await plugin.validateArgs('setDefaults', {
        'defaults': {'key1': 'value1'}
      });
      expect(r2.isValid, true);
    });

    test('supports all declared methods', () {
      for (final method in plugin.supportedMethods) {
        expect(plugin.supportsMethod(method), true);
      }
    });
  });
}
```

---

## خلاصه فاز ۱۶

## پلاگین‌های Firebase

| # | پلاگین | نام JS | قابلیت‌ها |
|---|--------|--------|----------|
| 81 | Firebase Analytics | `firebaseAnalytics` | 20+ روش tracking |
| 82 | Firebase Crashlytics | `firebaseCrashlytics` | Error recording, custom keys |
| 83 | Firebase Remote Config | `firebaseRemoteConfig` | Fetch, activate, get values |
| 84 | Firebase Auth | `firebaseAuth` | Email, Google, Anonymous auth |
| — | Push Notification | `pushNotification` | بازنویسی با FCM واقعی |

## Events جدید

| Event | پلاگین |
|-------|--------|
| `remoteConfig.updated` | firebaseRemoteConfig |
| `auth.stateChanged` | firebaseAuth |
| `push.tokenRefreshed` | pushNotification |

## مجموع کل: **84 پلاگین** 🎉

## نحوه استفاده JS

```javascript
// Analytics
await NativeSDK.firebaseAnalytics.setUserId('user_123');
await NativeSDK.firebaseAnalytics.setCurrentScreen('HomeScreen');
await NativeSDK.firebaseAnalytics.logEvent('button_click', {
  button_name: 'checkout',
  screen: 'cart'
});
await NativeSDK.firebaseAnalytics.logPurchase({
  currency: 'USD',
  value: 49.99,
  transactionId: 'txn_123'
});

// Crashlytics
await NativeSDK.firebaseCrashlytics.setUserId('user_123');
await NativeSDK.firebaseCrashlytics.setCustomKeys({
  plan: 'premium',
  version: '2.0.0'
});
try {
  await riskyOperation();
} catch (e) {
  await NativeSDK.firebaseCrashlytics.recordError(e.message, 'NetworkError');
}

// Remote Config
await NativeSDK.firebaseRemoteConfig.initialize({
  minimumFetchIntervalMs: 3600000,
  defaults: {
    feature_dark_mode: false,
    max_items: 10,
    api_url: 'https://api.example.com'
  }
});
const { updated } = await NativeSDK.firebaseRemoteConfig.fetchAndActivate();
const { value: darkMode } = await NativeSDK.firebaseRemoteConfig.getBool('feature_dark_mode');

NativeSDK.on('remoteConfig.updated', () => {
  location.reload(); // reload با config جدید
});

// Auth
const { user } = await NativeSDK.firebaseAuth.signInWithEmail('ali@test.com', 'password123');
const { user: gUser } = await NativeSDK.firebaseAuth.signInWithGoogle();
const { token } = await NativeSDK.firebaseAuth.getIdToken(false);

NativeSDK.on('auth.stateChanged', (data) => {
  if (data.signedIn) {
    router.navigate('/home');
  } else {
    router.navigate('/login');
  }
});

// Push (FCM واقعی)
const { token } = await NativeSDK.pushNotification.register();
console.log('FCM Token:', token); // ارسال به backend

await NativeSDK.pushNotification.subscribe('promotions');
NativeSDK.on('push.received', (data) => {
  showInAppNotification(data.title, data.body);
});
NativeSDK.on('push.tap', (data) => {
  router.navigate('/notification/' + data.data.id);
});
```

---

بگو تا **فاز ۱۷** (Advanced Plugins: Camera Preview, Document Scanner, Google Maps, Social Login, In-App Purchase, OAuth2) رو شروع کنم.
