import 'dart:async';

import 'package:webview_flutter/webview_flutter.dart';
import 'package:sweetmelon/packages/core/lib/core.dart';
import 'package:sweetmelon/packages/plugin_engine/lib/plugin_engine.dart';

class CookieManagerPlugin extends Plugin {
  final WebViewCookieManager _cookieManager = WebViewCookieManager();

  @override
  String get name => 'cookieManager';

  @override
  String get version => '1.0.0';

  @override
  String get description => 'WebView cookie and session management plugin';

  @override
  List<String> get supportedMethods => [
        'setCookie',
        'clearCookies',
        'clearSession',
        'getInfo',
      ];

  @override
  Future<dynamic> onCall(String method, Map<String, dynamic> args) async {
    switch (method) {
      case 'setCookie':
        return _setCookie(args);
      case 'clearCookies':
        return _clearCookies();
      case 'clearSession':
        return _clearSession();
      case 'getInfo':
        return {
          'name': name,
          'version': version,
        };
      default:
        throw UnsupportedError('Method "$method" not supported');
    }
  }

  Future<Map<String, dynamic>> _setCookie(Map<String, dynamic> args) async {
    final domain = args['domain'] as String;
    final name = args['name'] as String;
    final value = args['value'] as String;
    final path = args['path'] as String? ?? '/';
    final secure = args['secure'] as bool? ?? false;
    final httpOnly = args['httpOnly'] as bool? ?? false;
    final expiresEpoch = (args['expiresEpoch'] as num?)?.toInt();

    try {
      await _cookieManager.setCookie(
        WebViewCookie(
          name: name,
          value: value,
          domain: domain,
          path: path,
        ),
      );

      BridgeLogger.info(
        'CookieManager',
        'Cookie set: $name=$value for $domain',
      );

      return {
        'set': true,
        'name': name,
        'domain': domain,
      };
    } catch (e) {
      BridgeLogger.error('CookieManager', 'Failed to set cookie: $e');
      return {
        'set': false,
        'error': e.toString(),
      };
    }
  }

  Future<Map<String, dynamic>> _clearCookies() async {
    try {
      final cleared = await _cookieManager.clearCookies();

      BridgeLogger.info('CookieManager', 'Cookies cleared: $cleared');

      return {'cleared': cleared};
    } catch (e) {
      BridgeLogger.error('CookieManager', 'Failed to clear cookies: $e');
      return {'cleared': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> _clearSession() async {
    try {
      final cleared = await _cookieManager.clearCookies();

      BridgeLogger.info('CookieManager', 'Session cleared');

      return {'cleared': cleared};
    } catch (e) {
      return {'cleared': false, 'error': e.toString()};
    }
  }

  @override
  Future<ValidationResult> validateArgs(
    String method,
    Map<String, dynamic> args,
  ) async {
    if (method == 'setCookie') {
      for (final field in ['domain', 'name', 'value']) {
        final val = args[field];
        if (val is! String || val.isEmpty) {
          return ValidationResult.invalid('$field is required');
        }
      }
    }
    return ValidationResult.valid();
  }
}
