import 'package:flutter_test/flutter_test.dart';
import 'package:sweetmelon/packages/core/lib/core.dart';

void main() {
  group('WorkerMessage and WorkerResult', () {
    test('keep the fields they were created with', () {
      const message = WorkerMessage<int>(id: 'm1', type: 'sum', data: 42);
      const ok = WorkerResult<String>(id: 'm1', success: true, data: 'done');
      const failed = WorkerResult<String>(
        id: 'm2',
        success: false,
        error: 'boom',
      );

      expect(message.id, 'm1');
      expect(message.type, 'sum');
      expect(message.data, 42);
      expect(ok.success, true);
      expect(ok.data, 'done');
      expect(ok.error, isNull);
      expect(failed.success, false);
      expect(failed.data, isNull);
      expect(failed.error, 'boom');
    });
  });

  group('WorkerPool', () {
    test('reports idle stats before initialization', () {
      final pool = WorkerPool(poolSize: 3);

      expect(pool.stats, {
        'poolSize': 3,
        'initialized': false,
        'activeWorkers': 0,
      });
    });

    test('initialize activates every worker once', () async {
      final pool = WorkerPool(poolSize: 2);

      await pool.initialize();
      await pool.initialize();

      expect(pool.stats['initialized'], true);
      expect(pool.stats['activeWorkers'], 2);
      pool.dispose();
    });

    test('compute runs the task off the main isolate', () async {
      final pool = WorkerPool();

      final result = await pool.compute((int x) => x * x, 7);

      expect(result, 49);
      pool.dispose();
    });

    test('processJson returns the parsed length of the input', () async {
      final pool = WorkerPool();

      expect(await pool.processJson('{"a":1}'), 7);
      pool.dispose();
    });

    test('processBytes runs the processor on the byte list', () async {
      final pool = WorkerPool();

      final result = await pool.processBytes(
        (bytes) => bytes.reversed.toList(),
        [1, 2, 3],
      );

      expect(result, [3, 2, 1]);
      pool.dispose();
    });

    test('compute fails with TimeoutException when the task is too slow',
        () async {
      final pool = WorkerPool();

      await expectLater(
        pool.compute(
          (int x) {
            final watch = Stopwatch()..start();
            while (watch.elapsedMilliseconds < 2000) {}
            return x;
          },
          1,
          timeout: const Duration(milliseconds: 1),
        ),
        throwsA(isA<Exception>()),
      );
      pool.dispose();
    });

    test('dispose resets state so the pool can be re-initialized', () async {
      final pool = WorkerPool(poolSize: 2);
      await pool.initialize();

      pool.dispose();
      expect(pool.stats['initialized'], false);
      expect(pool.stats['activeWorkers'], 0);

      await pool.initialize();
      expect(pool.stats['activeWorkers'], 2);
      pool.dispose();
    });
  });

  group('ComputeHelper', () {
    test('encodeJsonHeavy and decodeJsonHeavy round-trip a map', () async {
      final encoded = await ComputeHelper.encodeJsonHeavy({'a': 1, 'b': 'x'});
      final decoded = await ComputeHelper.decodeJsonHeavy(encoded);

      expect(encoded, '{"a":1,"b":"x"}');
      expect(decoded, {'a': 1, 'b': 'x'});
    });

    test('processBatch maps every item in a separate isolate', () async {
      final doubled = await ComputeHelper.processBatch<int>(
        [1, 2, 3],
        (x) => x * 2,
      );

      expect(doubled, [2, 4, 6]);
    });

    test('processBatch returns an empty list for empty input', () async {
      final result = await ComputeHelper.processBatch<String>(
        const [],
        (s) => s.toUpperCase(),
      );

      expect(result, isEmpty);
    });
  });
}
