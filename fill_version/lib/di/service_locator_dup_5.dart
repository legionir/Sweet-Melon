import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';

import 'package:sweetmelon/packages/core/lib/core.dart';
import 'package:sweetmelon/packages/devtools/lib/devtools.dart';
import 'package:sweetmelon/packages/performance/lib/performance.dart';
import 'package:sweetmelon/packages/security/lib/security.dart';
import 'package:sweetmelon/packages/plugin_engine/lib/plugin_engine.dart';

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
        manager.setProvider(NativePermissionProvider(
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
