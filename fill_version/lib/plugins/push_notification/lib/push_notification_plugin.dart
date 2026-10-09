import 'dart:async';
import 'dart:convert';

import 'package:sweetmelon/packages/core/lib/core.dart';
import 'package:sweetmelon/packages/plugin_engine/lib/plugin_engine.dart';

typedef PushEventEmitter = Future<void> Function(String event, dynamic data);

/// این پلاگین از MethodChannel استفاده می‌کنه
/// برای اتصال واقعی به FCM باید firebase_messaging اضافه بشه
/// اینجا ساختار آماده شده تا وقتی dependency اضافه شد فقط implementation عوض بشه
class PushNotificationPlugin extends Plugin {
  final PushEventEmitter? eventEmitter;

  String? _token;
  bool _permissionGranted = false;
  final List<Map<String, dynamic>> _receivedMessages = [];

  PushNotificationPlugin({this.eventEmitter});

  @override
  String get name => 'pushNotification';

  @override
  String get version => '1.0.0';

  @override
  String get description => 'Push notification plugin (FCM ready)';

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
        'getInfo',
      ];

  @override
  Future<void> onInitialize() async {
    BridgeLogger.info('PushNotification', 'Plugin initialized (FCM stub)');
    // وقتی firebase_messaging اضافه شد:
    // FirebaseMessaging.instance.onMessage.listen(_handleForegroundMessage);
    // FirebaseMessaging.instance.onMessageOpenedApp.listen(_handleOpenedMessage);
  }

  @override
  Future<dynamic> onCall(String method, Map<String, dynamic> args) async {
    switch (method) {
      case 'register':
        return _register();
      case 'getToken':
        return _getToken();
      case 'requestPermission':
        return _requestPermission();
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
      case 'getInfo':
        return {
          'name': name,
          'version': version,
          'token': _token,
          'permissionGranted': _permissionGranted,
          'receivedCount': _receivedMessages.length,
          'fcmReady': false, // true وقتی firebase_messaging اضافه شد
        };
      default:
        throw UnsupportedError('Method "$method" not supported');
    }
  }

  Future<Map<String, dynamic>> _register() async {
    // Stub — وقتی FCM اضافه شد:
    // await FirebaseMessaging.instance.requestPermission();
    // _token = await FirebaseMessaging.instance.getToken();

    _permissionGranted = true;
    _token = 'fcm_token_placeholder_${DateTime.now().millisecondsSinceEpoch}';

    BridgeLogger.info('PushNotification', 'Registered, token: $_token');

    eventEmitter?.call('push.registered', {
      'token': _token,
      'timestamp': DateTime.now().toIso8601String(),
    });

    return {
      'registered': true,
      'token': _token,
    };
  }

  Future<Map<String, dynamic>> _getToken() async {
    // وقتی FCM اضافه شد:
    // _token = await FirebaseMessaging.instance.getToken();
    return {'token': _token};
  }

  Future<Map<String, dynamic>> _requestPermission() async {
    // Stub
    _permissionGranted = true;
    return {
      'granted': true,
      'status': 'authorized',
    };
  }

  Future<Map<String, dynamic>> _checkPermission() async {
    return {
      'granted': _permissionGranted,
      'status': _permissionGranted ? 'authorized' : 'denied',
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
      (m) => ids.contains(m['id']?.toString()),
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
    // FirebaseMessaging.instance.subscribeToTopic(topic);
    BridgeLogger.info('PushNotification', 'Subscribed to: $topic');
    return {'subscribed': true, 'topic': topic};
  }

  Future<Map<String, dynamic>> _unsubscribe(Map<String, dynamic> args) async {
    final topic = args['topic'] as String;
    // FirebaseMessaging.instance.unsubscribeFromTopic(topic);
    BridgeLogger.info('PushNotification', 'Unsubscribed from: $topic');
    return {'unsubscribed': true, 'topic': topic};
  }

  /// Called when a foreground message is received (from FCM)
  void handleForegroundMessage(Map<String, dynamic> message) {
    _receivedMessages.add({
      'id': message['messageId'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      'title': message['title'],
      'body': message['body'],
      'data': message['data'],
      'receivedAt': DateTime.now().toIso8601String(),
    });

    if (_receivedMessages.length > 100) {
      _receivedMessages.removeAt(0);
    }

    eventEmitter?.call('push.received', {
      'title': message['title'],
      'body': message['body'],
      'data': message['data'],
      'foreground': true,
    });
  }

  /// Called when user taps a notification
  void handleNotificationTap(Map<String, dynamic> message) {
    eventEmitter?.call('push.tap', {
      'title': message['title'],
      'body': message['body'],
      'data': message['data'],
    });
  }

  @override
  Future<ValidationResult> validateArgs(
    String method,
    Map<String, dynamic> args,
  ) async {
    switch (method) {
      case 'subscribe':
      case 'unsubscribe':
        final topic = args['topic'];
        if (topic is! String || topic.isEmpty) {
          return ValidationResult.invalid('topic is required');
        }
        return ValidationResult.valid();
      default:
        return ValidationResult.valid();
    }
  }
}
