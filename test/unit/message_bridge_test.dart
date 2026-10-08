import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:sweetmelon/packages/core/lib/src/bridge/message_bridge.dart';
import 'package:sweetmelon/packages/core/lib/src/protocol/message_protocol.dart';

import '../helpers/fakes.dart';

Map<String, dynamic> requestJson({
  required String token,
  String requestId = 'req-1',
}) =>
    {
      'requestId': requestId,
      'token': token,
      'plugin': 'fake',
      'method': 'echo',
      'args': {'x': 1},
      'metadata': {'headers': <String, String>{}},
    };

void main() {
  late MessageBridge bridge;
  late RecordingExecutor exec;

  setUp(() {
    bridge = MessageBridge();
    exec = RecordingExecutor();
    bridge.attachJsExecutor(exec.call);
  });

  tearDown(() {
    bridge.dispose();
  });

  group('session token (SEC-004)', () {
    test('startSession issues a URL-safe token', () {
      final token = bridge.startSession();
      expect(token, matches(RegExp(r'^[A-Za-z0-9_-]{32,}$')));
    });

    test('each session gets a different token', () {
      final a = bridge.startSession();
      final b = bridge.startSession();
      expect(a, isNot(b));
    });

    test('bridge_ready with the wrong token is ignored', () {
      bridge.startSession();
      expect(bridge.onBridgeReady('forged'), isFalse);
      expect(bridge.onBridgeReady(null), isFalse);
      expect(bridge.isReady, isFalse);
    });

    test('bridge_ready with the current token marks the bridge ready', () {
      final token = bridge.startSession();
      expect(bridge.onBridgeReady(token), isTrue);
      expect(bridge.isReady, isTrue);
    });

    test(
        'requests without the session token are dropped before any handler runs',
        () async {
      var handled = 0;
      bridge.setMessageHandler((request) async {
        handled++;
        return PluginResponse.success(
            requestId: request.requestId, data: 1, metadata: null);
      });
      bridge.startSession();
      await bridge
          .handleIncomingMessage(jsonEncode(requestJson(token: 'nope')));
      expect(handled, 0);
    });

    test('a token from a previous page is rejected after navigation', () async {
      final oldToken = bridge.startSession();
      bridge.onBridgeReady(oldToken);
      bridge.endSession();
      var handled = 0;
      bridge.setMessageHandler((request) async {
        handled++;
        return PluginResponse.success(requestId: request.requestId, data: 1);
      });
      await bridge
          .handleIncomingMessage(jsonEncode(requestJson(token: oldToken)));
      expect(handled, 0);
    });
  });

  group('message limits', () {
    test('oversized messages are rejected without parsing (SEC-004)', () async {
      final token = bridge.startSession();
      bridge.onBridgeReady(token);
      var handled = 0;
      bridge.setMessageHandler((request) async {
        handled++;
        return PluginResponse.success(requestId: request.requestId, data: 1);
      });
      final padding = 'x' * (kMaxMessageBytes + 1);
      await bridge.handleIncomingMessage(
        jsonEncode({...requestJson(token: token), 'pad': padding}),
      );
      expect(handled, 0);
    });

    test('malformed JSON is dropped', () async {
      bridge.startSession();
      await expectLater(bridge.handleIncomingMessage('{not json'), completes);
    });

    test('non-object JSON is dropped', () async {
      bridge.startSession();
      await expectLater(bridge.handleIncomingMessage('[1,2,3]'), completes);
    });
  });

  group('request flow', () {
    test('a valid request reaches the handler and its response is delivered',
        () async {
      final token = bridge.startSession();
      bridge.onBridgeReady(token);
      bridge.setMessageHandler((request) async => PluginResponse.success(
            requestId: request.requestId,
            data: {'ok': true},
          ));
      await bridge.handleIncomingMessage(jsonEncode(requestJson(token: token)));
      await Future<void>.delayed(Duration.zero);
      expect(exec.scripts, hasLength(1));
      expect(exec.scripts.single, startsWith('window.__resolveCall('));
      expect(exec.scripts.single, contains('req-1'));
    });

    // Regression: SM-006 — a response that finishes after the page navigated
    // away must not be delivered to the new page.
    test('regression: responses for a previous session are not delivered',
        () async {
      final token = bridge.startSession();
      bridge.onBridgeReady(token);
      final gate = Completer<PluginResponse>();
      bridge.setMessageHandler((request) => gate.future);
      final pending = bridge.handleIncomingMessage(
        jsonEncode(requestJson(token: token)),
      );
      await Future<void>.delayed(Duration.zero);
      bridge.endSession();
      gate.complete(PluginResponse.success(requestId: 'req-1', data: 1));
      await pending;
      expect(exec.scripts, isEmpty);
    });

    test('scripts are queued until the page reports ready, then flushed',
        () async {
      final token = bridge.startSession();
      await bridge.emitEvent('geolocation.position', {'lat': 1});
      expect(exec.scripts, isEmpty);
      expect(bridge.queuedScriptCount, 1);
      bridge.onBridgeReady(token);
      await Future<void>.delayed(Duration.zero);
      expect(exec.scripts, hasLength(1));
      expect(bridge.queuedScriptCount, 0);
    });

    // Regression: BUG-003 — the pre-ready queue is bounded.
    test('regression: the pre-ready script queue is bounded', () async {
      final small = MessageBridge(maxQueuedScripts: 2);
      final local = RecordingExecutor();
      small.attachJsExecutor(local.call);
      final token = small.startSession();
      for (var i = 0; i < 10; i++) {
        await small.emitEvent('x.y', i);
      }
      expect(small.queuedScriptCount, 2);
      small.onBridgeReady(token);
      await Future<void>.delayed(Duration.zero);
      expect(local.scripts, hasLength(2));
      small.dispose();
    });
  });

  group('emitEvent', () {
    test('rejects event names that could break out of the script', () async {
      bridge.onBridgeReady(bridge.startSession());
      await bridge.emitEvent("x');alert(1);//", 1);
      await bridge.emitEvent('../etc', 1);
      await bridge.emitEvent('', 1);
      await Future<void>.delayed(Duration.zero);
      expect(exec.scripts, isEmpty);
    });

    test('accepts dotted names and double-encodes the payload', () async {
      bridge.onBridgeReady(bridge.startSession());
      await bridge.emitEvent('geolocation.position', {'lat': 1.5});
      await Future<void>.delayed(Duration.zero);
      expect(exec.scripts, hasLength(1));
      final script = exec.scripts.single;
      expect(script, startsWith('window.__emitEvent("geolocation.position", '));
      // The payload argument is a JSON string whose content is the JSON object.
      final inner = jsonDecode(script.substring(
        script.indexOf(', ') + 2,
        script.length - ');'.length,
      )) as String;
      expect(jsonDecode(inner), {'lat': 1.5});
    });

    test('drops payloads that cannot be encoded', () async {
      bridge.onBridgeReady(bridge.startSession());
      await bridge.emitEvent('x.y', Object());
      await Future<void>.delayed(Duration.zero);
      expect(exec.scripts, isEmpty);
    });
  });

  test('dispose stops all delivery', () async {
    final token = bridge.startSession();
    bridge.onBridgeReady(token);
    bridge.dispose();
    await bridge.emitEvent('x.y', 1);
    expect(exec.scripts, isEmpty);
    expect(bridge.isDisposed, isTrue);
  });
}
