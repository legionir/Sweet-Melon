import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';

import 'package:sweetmelon/packages/core/lib/core.dart';
import 'package:sweetmelon/packages/devtools/lib/devtools.dart';
import 'package:sweetmelon/packages/performance/lib/performance.dart';
import 'package:sweetmelon/packages/security/lib/security.dart';
import 'package:sweetmelon/packages/plugin_engine/lib/plugin_engine.dart';
import 'package:sweetmelon/di/migration_registry.dart';

// ── Eager plugins (always loaded) ──
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
import 'package:sweetmelon/plugins/back_button/lib/back_button_plugin.dart';
import 'package:sweetmelon/plugins/status_bar/lib/status_bar_plugin.dart';
import 'package:sweetmelon/plugins/orientation/lib/orientation_plugin.dart';
import 'package:sweetmelon/plugins/haptic/lib/haptic_plugin.dart';
import 'package:sweetmelon/plugins/keyboard/lib/keyboard_plugin.dart';
import 'package:sweetmelon/plugins/encryption/lib/encryption_plugin.dart';
import 'package:sweetmelon/plugins/websocket/lib/websocket_plugin.dart';
import 'package:sweetmelon/plugins/background_task/lib/background_task_plugin.dart';
import 'package:sweetmelon/plugins/dialog/lib/dialog_plugin.dart';
import 'package:sweetmelon/plugins/toast/lib/toast_plugin.dart';
import 'package:sweetmelon/plugins/splash_screen/lib/splash_screen_plugin.dart';
import 'package:sweetmelon/plugins/push_notification/lib/push_notification_plugin.dart';
import 'package:sweetmelon/plugins/wake_lock/lib/wake_lock_plugin.dart';
import 'package:sweetmelon/plugins/cookie_manager/lib/cookie_manager_plugin.dart';
import 'package:sweetmelon/plugins/cache_control/lib/cache_control_plugin.dart';
import 'package:sweetmelon/plugins/app_update/lib/app_update_plugin.dart';
import 'package:sweetmelon/plugins/file_picker/lib/file_picker_plugin.dart';
import 'package:sweetmelon/plugins/file_opener/lib/file_opener_plugin.dart';
import 'package:sweetmelon/plugins/navigation_bar/lib/navigation_bar_plugin.dart';
import 'package:sweetmelon/plugins/privacy_screen/lib/privacy_screen_plugin.dart';
import 'package:sweetmelon/plugins/native_settings/lib/native_settings_plugin.dart';
import 'package:sweetmelon/plugins/safe_area/lib/safe_area_plugin.dart';
import 'package:sweetmelon/plugins/date_picker/lib/date_picker_plugin.dart';
import 'package:sweetmelon/plugins/action_sheet/lib/action_sheet_plugin.dart';
import 'package:sweetmelon/plugins/text_zoom/lib/text_zoom_plugin.dart';
import 'package:sweetmelon/plugins/accessibility/lib/accessibility_plugin.dart';
import 'package:sweetmelon/plugins/firebase_analytics/lib/firebase_analytics_plugin.dart';
import 'package:sweetmelon/plugins/firebase_crashlytics/lib/firebase_crashlytics_plugin.dart';
import 'package:sweetmelon/plugins/firebase_remote_config/lib/firebase_remote_config_plugin.dart';
import 'package:sweetmelon/plugins/firebase_auth/lib/firebase_auth_plugin.dart';

// ── Lazy plugins (loaded on first call) ──
import 'package:sweetmelon/plugins/camera/lib/camera_plugin.dart';
import 'package:sweetmelon/plugins/geolocation/lib/geolocation_plugin.dart';
import 'package:sweetmelon/plugins/secure_storage/lib/secure_storage_plugin.dart';
import 'package:sweetmelon/plugins/notification/lib/notification_plugin.dart';
import 'package:sweetmelon/plugins/biometrics/lib/biometrics_plugin.dart';
import 'package:sweetmelon/plugins/qr_scanner/lib/qr_scanner_plugin.dart';
import 'package:sweetmelon/plugins/audio/lib/audio_plugin.dart';
import 'package:sweetmelon/plugins/sms_otp/lib/sms_otp_plugin.dart';
import 'package:sweetmelon/plugins/download_manager/lib/download_manager_plugin.dart';
import 'package:sweetmelon/plugins/database/lib/database_plugin.dart';
import 'package:sweetmelon/plugins/contacts/lib/contacts_plugin.dart';
import 'package:sweetmelon/plugins/phone_dialer/lib/phone_dialer_plugin.dart';
import 'package:sweetmelon/plugins/bluetooth/lib/bluetooth_plugin.dart';
import 'package:sweetmelon/plugins/nfc/lib/nfc_plugin.dart';
import 'package:sweetmelon/plugins/speech_to_text/lib/speech_to_text_plugin.dart';
import 'package:sweetmelon/plugins/text_to_speech/lib/text_to_speech_plugin.dart';
import 'package:sweetmelon/plugins/video_player/lib/video_player_plugin.dart';
import 'package:sweetmelon/plugins/in_app_browser/lib/in_app_browser_plugin.dart';
import 'package:sweetmelon/plugins/pdf_plugin/lib/pdf_bridge_plugin.dart';
import 'package:sweetmelon/plugins/sensors/lib/sensors_plugin.dart';
import 'package:sweetmelon/plugins/screen_brightness/lib/screen_brightness_plugin.dart';
import 'package:sweetmelon/plugins/flashlight/lib/flashlight_plugin.dart';
import 'package:sweetmelon/plugins/calendar/lib/calendar_plugin.dart';
import 'package:sweetmelon/plugins/badge/lib/badge_plugin.dart';
import 'package:sweetmelon/plugins/foreground_service/lib/foreground_service_plugin.dart';
import 'package:sweetmelon/plugins/background_geolocation/lib/background_geolocation_plugin.dart';
import 'package:sweetmelon/plugins/media_manager/lib/media_manager_plugin.dart';
import 'package:sweetmelon/plugins/file_compressor/lib/file_compressor_plugin.dart';
import 'package:sweetmelon/plugins/zip/lib/zip_plugin.dart';
import 'package:sweetmelon/plugins/share_target/lib/share_target_plugin.dart';
import 'package:sweetmelon/plugins/in_app_review/lib/in_app_review_plugin.dart';
import 'package:sweetmelon/plugins/native_market/lib/native_market_plugin.dart';
import 'package:sweetmelon/plugins/screenshot/lib/screenshot_plugin.dart';
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

final sl = GetIt.instance;

class ServiceLocator {
  static bool _initializing = false;

  static Future<void> init() async {
    if (sl.isRegistered<MessageBridge>()) return;
    if (_initializing) return;
    _initializing = true;

    try {
      // ── Core services ──
      sl.registerLazySingleton<CacheManager>(
        () => CacheManager(maxEntries: 500),
      );

      sl.registerLazySingleton<RateLimiter>(() {
        final limiter = RateLimiter();
        limiter.setDefaultRule(RateLimitRule.perSecond(50));
        return limiter;
      });

      sl.registerLazySingleton<ExecutionGuard>(
        () => ExecutionGuard(defaultTimeoutMs: 30000),
      );

      sl.registerLazySingleton<PermissionManager>(() {
        final manager = PermissionManager(cacheTtl: const Duration(minutes: 3));
        manager.setProvider(const NativePermissionProvider(
          fallbackStatus: kReleaseMode
              ? PermissionStatus.denied
              : PermissionStatus.granted,
        ));
        return manager;
      });

      sl.registerLazySingleton<PluginRegistry>(() => PluginRegistry());

      sl.registerLazySingleton<LazyPluginLoader>(
        () => LazyPluginLoader(registry: sl<PluginRegistry>()),
      );

      sl.registerLazySingleton<PluginManager>(() => PluginManager(
            registry: sl<PluginRegistry>(),
            permissionManager: sl<PermissionManager>(),
            rateLimiter: sl<RateLimiter>(),
            executionGuard: sl<ExecutionGuard>(),
            cacheManager: sl<CacheManager>(),
            lazyLoader: sl<LazyPluginLoader>(),
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
        () => kReleaseMode
            ? WebViewHostConfig.production()
            : WebViewHostConfig.development(),
      );

      sl.registerLazySingleton<AssetServerConfig>(
        () => const AssetServerConfig(),
      );

      sl.registerLazySingleton<BridgeInspector>(
        () => BridgeInspector(
          bridge: bridge,
          manager: sl<PluginManager>(),
        ),
      );

      // Migration Manager
      sl.registerLazySingleton<MigrationManager>(() {
        final manager = MigrationManager();
        MigrationRegistry.registerAll(manager);
        return manager;
      });

      await _registerEagerPlugins();
      _registerLazyPlugins();
    } finally {
      _initializing = false;
    }
  }

  /// پلاگین‌هایی که همیشه لازمند و فورا load می‌شن
  static Future<void> _registerEagerPlugins() async {
    final registry = sl<PluginRegistry>();
    final emitter = registry.emitEvent;

    await registry.register(
      PermissionPlugin(permissionManager: sl<PermissionManager>()),
    );
    await registry.register(AppLifecyclePlugin(eventEmitter: emitter));
    await registry.register(DeviceInfoBridgePlugin());
    await registry.register(ConnectivityBridgePlugin(eventEmitter: emitter));
    await registry.register(StoragePlugin());
    await registry.register(FileSystemPlugin());
    await registry.register(HttpNativePlugin());
    await registry.register(IntentLinkPlugin(eventEmitter: emitter));
    await registry.register(ClipboardPlugin());
    await registry.register(ShareBridgePlugin());
    await registry.register(BackButtonPlugin(eventEmitter: emitter));
    await registry.register(StatusBarPlugin());
    await registry.register(OrientationPlugin());
    await registry.register(HapticPlugin());
    await registry.register(KeyboardPlugin(eventEmitter: emitter));
    await registry.register(EncryptionPlugin());
    await registry.register(WebSocketPlugin(eventEmitter: emitter));
    await registry.register(BackgroundTaskPlugin(eventEmitter: emitter));
    await registry.register(DialogPlugin());
    await registry.register(ToastPlugin());
    await registry.register(SplashScreenPlugin(eventEmitter: emitter));
    await registry.register(PushNotificationPlugin(eventEmitter: emitter));
    await registry.register(WakeLockPlugin());
    await registry.register(CookieManagerPlugin());
    await registry.register(CacheControlPlugin());
    await registry.register(AppUpdatePlugin(eventEmitter: emitter));
    await registry.register(FilePickerPlugin());
    await registry.register(FileOpenerPlugin());
    await registry.register(NavigationBarPlugin());
    await registry.register(PrivacyScreenPlugin());
    await registry.register(NativeSettingsPlugin());
    await registry.register(SafeAreaPlugin());
    await registry.register(DatePickerPlugin());
    await registry.register(ActionSheetPlugin());
    await registry.register(TextZoomPlugin(eventEmitter: emitter));
    await registry.register(AccessibilityPlugin(eventEmitter: emitter));
    await registry.register(FirebaseAnalyticsPlugin());
    await registry.register(FirebaseCrashlyticsPlugin());
    await registry.register(FirebaseAuthPlugin(eventEmitter: emitter));
    await registry.register(FirebaseRemoteConfigPlugin(eventEmitter: emitter));
  }

  /// پلاگین‌هایی که فقط وقتی call بشن load می‌شن
  static void _registerLazyPlugins() {
    final loader = sl<LazyPluginLoader>();
    final emitter = sl<PluginRegistry>().emitEvent;

    loader.registerAll([
      LazyPluginDefinition(
        id: 'camera',
        version: '1.0.0',
        factory: () => CameraPlugin(),
      ),
      LazyPluginDefinition(
        id: 'geolocation',
        version: '1.0.0',
        factory: () => GeolocationPlugin(eventEmitter: emitter),
      ),
      LazyPluginDefinition(
        id: 'secureStorage',
        version: '1.0.0',
        factory: () => SecureStoragePlugin(),
      ),
      LazyPluginDefinition(
        id: 'notification',
        version: '1.0.0',
        factory: () => NotificationPlugin(eventEmitter: emitter),
      ),
      LazyPluginDefinition(
        id: 'biometrics',
        version: '1.0.0',
        factory: () => BiometricsPlugin(),
      ),
      LazyPluginDefinition(
        id: 'qrScanner',
        version: '1.0.0',
        factory: () => QrScannerPlugin(eventEmitter: emitter),
      ),
      LazyPluginDefinition(
        id: 'audio',
        version: '1.0.0',
        factory: () => AudioPlugin(eventEmitter: emitter),
      ),
      LazyPluginDefinition(
        id: 'smsOtp',
        version: '1.0.0',
        factory: () => SmsOtpPlugin(eventEmitter: emitter),
      ),
      LazyPluginDefinition(
        id: 'downloadManager',
        version: '1.0.0',
        factory: () => DownloadManagerPlugin(eventEmitter: emitter),
      ),
      LazyPluginDefinition(
        id: 'database',
        version: '1.0.0',
        factory: () => DatabasePlugin(),
      ),
      LazyPluginDefinition(
        id: 'contacts',
        version: '1.0.0',
        factory: () => ContactsPlugin(),
      ),
      LazyPluginDefinition(
        id: 'phoneDialer',
        version: '1.0.0',
        factory: () => PhoneDialerPlugin(),
      ),
      LazyPluginDefinition(
        id: 'bluetooth',
        version: '1.0.0',
        factory: () => BluetoothPlugin(eventEmitter: emitter),
      ),
      LazyPluginDefinition(
        id: 'nfc',
        version: '1.0.0',
        factory: () => NfcPlugin(eventEmitter: emitter),
      ),
      LazyPluginDefinition(
        id: 'speechToText',
        version: '1.0.0',
        factory: () => SpeechToTextPlugin(eventEmitter: emitter),
      ),
      LazyPluginDefinition(
        id: 'textToSpeech',
        version: '1.0.0',
        factory: () => TextToSpeechPlugin(eventEmitter: emitter),
      ),
      LazyPluginDefinition(
        id: 'videoPlayer',
        version: '1.0.0',
        factory: () => VideoPlayerPlugin(eventEmitter: emitter),
      ),
      LazyPluginDefinition(
        id: 'inAppBrowser',
        version: '1.0.0',
        factory: () => InAppBrowserPlugin(eventEmitter: emitter),
      ),
      LazyPluginDefinition(
        id: 'pdf',
        version: '1.0.0',
        factory: () => PdfBridgePlugin(),
      ),
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
      LazyPluginDefinition(
        id: 'inAppReview',
        version: '1.0.0',
        factory: () => InAppReviewPlugin(),
      ),
      LazyPluginDefinition(
        id: 'nativeMarket',
        version: '1.0.0',
        factory: () => NativeMarketPlugin(),
      ),
      LazyPluginDefinition(
        id: 'screenshot',
        version: '1.0.0',
        factory: () => ScreenshotPlugin(),
      ),
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
    ]);

    BridgeLogger.info(
      'ServiceLocator',
      'Registered ${loader.unloadedPlugins.length} lazy plugins',
    );
  }

  static Future<void> dispose() async {
    if (sl.isRegistered<BridgeInspector>()) sl<BridgeInspector>().dispose();
    if (sl.isRegistered<PluginManager>()) sl<PluginManager>().dispose();
    if (sl.isRegistered<LazyPluginLoader>()) {
      await sl<LazyPluginLoader>().dispose();
    }
    if (sl.isRegistered<PluginRegistry>()) {
      await sl<PluginRegistry>().dispose();
    }
    if (sl.isRegistered<CacheManager>()) sl<CacheManager>().dispose();
    if (sl.isRegistered<MessageBridge>()) sl<MessageBridge>().dispose();
    await sl.reset();
  }
}
