// Firebase imports
import 'package:sweetmelon/plugins/firebase_analytics/lib/firebase_analytics_plugin.dart';
import 'package:sweetmelon/plugins/firebase_crashlytics/lib/firebase_crashlytics_plugin.dart';
import 'package:sweetmelon/plugins/firebase_remote_config/lib/firebase_remote_config_plugin.dart';
import 'package:sweetmelon/plugins/firebase_auth/lib/firebase_auth_plugin.dart';

    // ── Firebase ──
    await registry.register(FirebaseAnalyticsPlugin());
    await registry.register(FirebaseCrashlyticsPlugin());
    await registry.register(FirebaseAuthPlugin(eventEmitter: emitter));
    await registry.register(FirebaseRemoteConfigPlugin(eventEmitter: emitter));

    // بروزرسانی PushNotification به نسخه FCM واقعی
    await registry.register(PushNotificationPlugin(eventEmitter: emitter));
