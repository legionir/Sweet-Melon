// regression: BUG-007 — stopOnError semantics for batches.
//
// Documented behaviour (docs/SECURITY.md, "Parallel batches and stopOnError"):
//  * sequential batch, stopOnError=true: the first failure stops dispatch; every
//    later request gets CANCELLED ("Not executed ...") and is never executed;
//  * sequential batch, stopOnError=false: every request is executed;
//  * parallel batch: stopOnError is not applied (calls are already dispatched).
//  * a sequential batch that times out must not dispatch later requests after it
//    has settled.
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:sweetmelon/packages/core/lib/src/protocol/message_protocol.dart';
import 'package:sweetmelon/packages/plugin_engine/lib/plugin_engine.dart';

import '../helpers/fakes.dart';

FakePlugin _plugin({Duration slowFor = Duration.zero}) => FakePlugin(
      impl: (m, a) async {
        if (a['slow'] == true) {
          await Future<void>.delayed(slowFor);
        }
        if (a['fail'] == true) {
          throw const PluginException(PluginErrorCode.invalidArgs, 'nope');
        }
        return {'ok': true};
      },
    );

void main() {
  group('BUG-007 batch stopOnError', () {
    test('sequential, stopOnError=true: failure stops dispatch of the rest',
        () async {
      final plugin = _plugin();
      final h = await EngineHarness.create(plugins: [plugin]);
      final results = await h.manager.executeBatch(
        [
          buildRequest(requestId: 'a'),
          buildRequest(requestId: 'b', args: {'fail': true}),
          buildRequest(requestId: 'c'),
          buildRequest(requestId: 'd'),
        ],
        const BatchOptions(parallel: false, stopOnError: true),
      );
      expect(results.map((r) => r.requestId), ['a', 'b', 'c', 'd']);
      expect(results[0].success, isTrue);
      expect(results[1].error!.code, PluginErrorCode.invalidArgs);
      expect(results[2].error!.code, PluginErrorCode.cancelled);
      expect(results[3].error!.code, PluginErrorCode.cancelled);
      expect(plugin.calls, 2, reason: 'c and d must never be executed');
    });

    test('sequential, stopOnError=false: every request runs after a failure',
        () async {
      final plugin = _plugin();
      final h = await EngineHarness.create(plugins: [plugin]);
      final results = await h.manager.executeBatch(
        [
          buildRequest(requestId: 'a'),
          buildRequest(requestId: 'b', args: {'fail': true}),
          buildRequest(requestId: 'c'),
        ],
        const BatchOptions(parallel: false, stopOnError: false),
      );
      expect(results[0].success, isTrue);
      expect(results[1].error!.code, PluginErrorCode.invalidArgs);
      expect(results[2].success, isTrue);
      expect(plugin.calls, 3);
    });

    test('sequential, stopOnError=true with no failure runs everything',
        () async {
      final plugin = _plugin();
      final h = await EngineHarness.create(plugins: [plugin]);
      final results = await h.manager.executeBatch(
        [buildRequest(requestId: 'a'), buildRequest(requestId: 'b')],
        const BatchOptions(parallel: false, stopOnError: true),
      );
      expect(results.every((r) => r.success), isTrue);
      expect(plugin.calls, 2);
    });

    test('parallel batch: stopOnError is not applied (documented limitation)',
        () async {
      final plugin = _plugin();
      final h = await EngineHarness.create(plugins: [plugin]);
      final results = await h.manager.executeBatch(
        [
          buildRequest(requestId: 'a', args: {'fail': true}),
          buildRequest(requestId: 'b'),
        ],
        const BatchOptions(parallel: true, stopOnError: true),
      );
      expect(results[0].error!.code, PluginErrorCode.invalidArgs);
      expect(results[1].success, isTrue);
      expect(plugin.calls, 2);
    });

    // Regression: BUG-007 — the sequential loop kept running after the batch
    // timed out and dispatched later requests after the batch had settled.
    test('regression: timed-out sequential batch dispatches nothing later',
        () async {
      final plugin = _plugin(slowFor: const Duration(milliseconds: 150));
      final h = await EngineHarness.create(plugins: [plugin]);
      final results = await h.manager.executeBatch(
        [
          buildRequest(requestId: 'a', args: {'slow': true}),
          buildRequest(requestId: 'b'),
          buildRequest(requestId: 'c'),
        ],
        const BatchOptions(parallel: false, stopOnError: false, timeoutMs: 50),
      );
      expect(results.every((r) => r.error?.code == PluginErrorCode.timeout),
          isTrue);
      // Let the slow item finish; the loop must not continue afterwards.
      await Future<void>.delayed(const Duration(milliseconds: 400));
      expect(plugin.calls, 1, reason: 'b and c were never dispatched');
    });
  });
}
