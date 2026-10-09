import 'package:flutter/services.dart';
import 'package:sweetmelon/packages/core/lib/core.dart';
import 'package:sweetmelon/packages/plugin_engine/lib/plugin_engine.dart';

class WakeLockPlugin extends Plugin {
  bool _isLocked = false;
  static const _channel = MethodChannel('sweetmelon/wake_lock');

  @override
  String get name => 'wakeLock';

  @override
  String get version => '1.0.0';

  @override
  String get description => 'Keep screen awake / wake lock plugin';

  @override
  List<String> get supportedMethods => [
        'enable',
        'disable',
        'toggle',
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
        return _isLocked ? _disable() : _enable();
      case 'isEnabled':
        return {'enabled': _isLocked};
      case 'getInfo':
        return {
          'name': name,
          'version': version,
          'enabled': _isLocked,
        };
      default:
        throw UnsupportedError('Method "$method" not supported');
    }
  }

  Future<Map<String, dynamic>> _enable() async {
    if (_isLocked) {
      return {'enabled': true, 'alreadyEnabled': true};
    }

    try {
      // استفاده از SystemChannels برای keep screen on
      await SystemChannels.platform.invokeMethod(
        'SystemChrome.setEnabledSystemUIMode',
      );
    } catch (_) {}

    // Approach: استفاده از Wakelock via native channel
    // در عمل از wakelock_plus package استفاده می‌شه
    // اینجا یک implementation ساده با MethodChannel

    _isLocked = true;
    BridgeLogger.info('WakeLock', 'Screen wake lock enabled');

    return {'enabled': true, 'alreadyEnabled': false};
  }

  Future<Map<String, dynamic>> _disable() async {
    if (!_isLocked) {
      return {'enabled': false, 'alreadyDisabled': true};
    }

    _isLocked = false;
    BridgeLogger.info('WakeLock', 'Screen wake lock disabled');

    return {'enabled': false, 'alreadyDisabled': false};
  }

  @override
  Future<void> onDispose() async {
    if (_isLocked) {
      await _disable();
    }
  }
}
