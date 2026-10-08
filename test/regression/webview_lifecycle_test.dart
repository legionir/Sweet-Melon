// regression: BUG-011 — a WebView host must release the shared MessageBridge
// when it is disposed, and its late callbacks must not change the session of a
// live page. The host delegates this to BridgeAttachment, which is tested here
// together with the real MessageBridge (no WebView platform is needed).
import 'package:flutter_test/flutter_test.dart';
import 'package:sweetmelon/packages/core/lib/src/bridge/message_bridge.dart';
import 'package:sweetmelon/packages/core/lib/src/runtime/bridge_attachment.dart';

class _Executor {
  final List<String> scripts = [];
  Future<void> call(String script) async => scripts.add(script);
}

void main() {
  late MessageBridge bridge;
  late _Executor first;
  late _Executor second;

  setUp(() {
    bridge = MessageBridge();
    first = _Executor();
    second = _Executor();
  });

  tearDown(() => bridge.dispose());

  group('BUG-011 WebView host lifecycle', () {
    test('detach ends the session: the old token is rejected', () {
      final host = BridgeAttachment(bridge: bridge, executor: first.call);
      final token = host.startSession();
      expect(token, isNotNull);

      host.detach();

      expect(bridge.onBridgeReady(token), isFalse);
      expect(bridge.isReady, isFalse);
      expect(host.isActive, isFalse);
    });

    test('repeated detach is safe and changes nothing', () {
      final host = BridgeAttachment(bridge: bridge, executor: first.call);
      host.startSession();
      host.detach();
      final sessionAfterFirst = bridge.sessionId;

      host.detach();
      host.detach();

      expect(bridge.sessionId, sessionAfterFirst);
      expect(bridge.isCurrentExecutor(first.call), isFalse);
    });

    test('no script reaches the WebView after detach', () async {
      final host = BridgeAttachment(bridge: bridge, executor: first.call);
      final token = host.startSession()!;
      expect(bridge.onBridgeReady(token), isTrue);

      await bridge.emitEvent('before', 1);
      expect(first.scripts.length, 1);

      host.detach();
      await bridge.emitEvent('after', 2);
      expect(first.scripts.length, 1, reason: 'nothing runs after detach');
    });

    test('late page-finished after detach does not start a session', () {
      final host = BridgeAttachment(bridge: bridge, executor: first.call);
      host.detach();
      final sessionBefore = bridge.sessionId;

      expect(host.startSession(), isNull);
      expect(bridge.sessionId, sessionBefore);
    });

    test('late callbacks of a superseded host cannot end the live session', () {
      final oldHost = BridgeAttachment(bridge: bridge, executor: first.call);
      oldHost.startSession();
      final newHost = BridgeAttachment(bridge: bridge, executor: second.call);
      final liveToken = newHost.startSession()!;

      oldHost.onPageStarted();
      expect(bridge.onBridgeReady(liveToken), isTrue,
          reason: 'the live page must keep its session');
    });

    test('a superseded host cannot start a session on the bridge', () {
      final oldHost = BridgeAttachment(bridge: bridge, executor: first.call);
      BridgeAttachment(bridge: bridge, executor: second.call);
      expect(oldHost.isActive, isFalse);
      expect(oldHost.startSession(), isNull);
    });

    test('detaching a superseded host leaves the new executor attached', () {
      final oldHost = BridgeAttachment(bridge: bridge, executor: first.call);
      final newHost = BridgeAttachment(bridge: bridge, executor: second.call);

      oldHost.detach();

      expect(newHost.isActive, isTrue);
      expect(bridge.isCurrentExecutor(second.call), isTrue);
    });

    test('a host can still start a session right after it is attached', () {
      final host = BridgeAttachment(bridge: bridge, executor: first.call);
      expect(host.isActive, isTrue);
      expect(host.startSession(), isNotNull);
    });
  });
}
