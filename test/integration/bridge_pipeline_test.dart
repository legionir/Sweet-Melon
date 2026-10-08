// integration: a JavaScript-shaped JSON message goes through the real
// MessageBridge (size limit, JSON shape, session token, protocol validation)
// into the real PluginManager, a plugin, and back out as a script for the
// WebView. Only the WebView itself is replaced by a recording executor.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:sweetmelon/packages/core/lib/src/bridge/message_bridge.dart';
import 'package:sweetmelon/packages/core/lib/src/protocol/message_protocol.dart';

import '../helpers/fakes.dart';

Map<String, dynamic> _request(
  String id, {
  String? token,
  String plugin = 'fake',
  String method = 'echo',
}) {
  return {
    'token': token,
    'requestId': id,
    'plugin': plugin,
    'method': method,
    'args': {'value': id},
    'metadata': {'headers': <String, String>{}},
  };
}

void main() {
  late FakePlugin plugin;
  late MessageBridge bridge;
  late List<String> scripts;
  late String token;

  setUp(() async {
    plugin = FakePlugin();
    final harness = await EngineHarness.create(plugins: [plugin]);
    bridge = MessageBridge();
    bridge.setMessageHandler(harness.manager.execute);
    bridge.setBatchHandler(harness.manager.executeBatch);
    scripts = [];
    bridge.attachJsExecutor((script) async => scripts.add(script));
    token = bridge.startSession();
    expect(bridge.onBridgeReady(token), isTrue);
  });

  tearDown(() => bridge.dispose());

  test('request round trip reaches the plugin and the response is delivered',
      () async {
    await bridge.handleIncomingMessage(
      jsonEncode(_request('int_1', token: token)),
    );
    expect(plugin.calls, 1);
    expect(scripts.any((s) => s.contains('int_1')), isTrue);
  });

  test('message with a forged token is dropped: no execution, no response',
      () async {
    await bridge.handleIncomingMessage(
      jsonEncode(_request('int_2', token: 'forged-token')),
    );
    expect(plugin.calls, 0);
    expect(scripts.any((s) => s.contains('int_2')), isFalse);
  });

  test('unknown plugin gets a PLUGIN_NOT_FOUND response', () async {
    await bridge.handleIncomingMessage(
      jsonEncode(_request('int_3', token: token, plugin: 'nope')),
    );
    expect(plugin.calls, 0);
    expect(scripts.any((s) => s.contains('PLUGIN_NOT_FOUND')), isTrue);
  });

  test('malformed JSON is dropped without a response or an exception',
      () async {
    await bridge.handleIncomingMessage('{not json');
    await bridge.handleIncomingMessage('[1,2,3]');
    expect(plugin.calls, 0);
    expect(scripts, isEmpty);
  });

  test('oversized message is rejected before it is parsed', () async {
    final oversized = 'x' * (kMaxMessageBytes + 1);
    await bridge.handleIncomingMessage(oversized);
    expect(plugin.calls, 0);
    expect(scripts, isEmpty);
  });

  test('batch envelope: every item is executed and answered', () async {
    final envelope = {
      'type': 'batch',
      'token': token,
      'batchId': 'int_batch',
      'requests': [
        _request('int_b1'),
        _request('int_b2'),
      ],
      'options': {'parallel': false, 'stopOnError': false},
    };
    await bridge.handleIncomingMessage(jsonEncode(envelope));
    expect(plugin.calls, 2);
    expect(scripts.any((s) => s.contains('int_batch')), isTrue);
    expect(scripts.any((s) => s.contains('int_b1')), isTrue);
    expect(scripts.any((s) => s.contains('int_b2')), isTrue);
  });
}
