import 'package:flutter_test/flutter_test.dart';
import 'package:sweetmelon/packages/core/lib/src/protocol/message_protocol.dart';

void main() {
  group('isValidRequestId', () {
    test('accepts ids made of letters, digits, underscore and hyphen', () {
      expect(isValidRequestId('abc'), isTrue);
      expect(isValidRequestId('a-b_9'), isTrue);
      expect(isValidRequestId('0' * 128), isTrue);
    });

    test('rejects empty, too long, non-string and special characters', () {
      expect(isValidRequestId(''), isFalse);
      expect(isValidRequestId('0' * 129), isFalse);
      expect(isValidRequestId(42), isFalse);
      expect(isValidRequestId(null), isFalse);
      expect(isValidRequestId('a b'), isFalse);
      expect(isValidRequestId('a/b'), isFalse);
      expect(isValidRequestId('a.b'), isFalse);
    });

    // Regression: the pattern used to contain `\\-`, which allowed a literal
    // backslash inside request ids.
    test('regression: backslash is not a valid request id character', () {
      expect(isValidRequestId(r'a\b'), isFalse);
      expect(isValidRequestId(r'a\'), isFalse);
    });
  });

  group('PluginRequest.fromJson', () {
    Map<String, dynamic> valid() => {
          'requestId': 'req-1',
          'plugin': 'storage',
          'method': 'get',
          'args': {'key': 'a'},
          'metadata': {'headers': <String, String>{}},
        };

    test('parses a valid request', () {
      final request = PluginRequest.fromJson(valid());
      expect(request.requestId, 'req-1');
      expect(request.plugin, 'storage');
      expect(request.method, 'get');
      expect(request.args, {'key': 'a'});
    });

    test('rejects a missing requestId', () {
      final json = valid()..remove('requestId');
      expect(
        () => PluginRequest.fromJson(json),
        throwsA(isA<ProtocolException>()),
      );
    });

    test('rejects a plugin name that is not an identifier', () {
      final json = valid()..['plugin'] = '../storage';
      expect(
        () => PluginRequest.fromJson(json),
        throwsA(isA<ProtocolException>()),
      );
    });

    test('rejects non-map args', () {
      final json = valid()..['args'] = 'not a map';
      expect(
        () => PluginRequest.fromJson(json),
        throwsA(isA<ProtocolException>()),
      );
    });
  });

  group('BatchEnvelope.fromJson', () {
    Map<String, dynamic> request(String id) => {
          'requestId': id,
          'plugin': 'storage',
          'method': 'get',
          'args': <String, dynamic>{},
        };

    test('parses a valid envelope', () {
      final envelope = BatchEnvelope.fromJson({
        'batchId': 'batch-1',
        'requests': [request('r1'), request('r2')],
        'options': {'parallel': false, 'stopOnError': true},
      });
      expect(envelope.batchId, 'batch-1');
      expect(envelope.requests.map((r) => r.requestId), ['r1', 'r2']);
      expect(envelope.options.parallel, isFalse);
      expect(envelope.options.stopOnError, isTrue);
    });

    test('rejects an empty batch', () {
      expect(
        () => BatchEnvelope.fromJson({'batchId': 'b', 'requests': []}),
        throwsA(isA<ProtocolException>()),
      );
    });

    test('rejects more than kMaxBatchSize requests', () {
      expect(
        () => BatchEnvelope.fromJson({
          'batchId': 'b',
          'requests': [
            for (var i = 0; i <= kMaxBatchSize; i++) request('r$i'),
          ],
        }),
        throwsA(isA<ProtocolException>()),
      );
    });

    test('rejects a timeout above the maximum', () {
      expect(
        () => BatchEnvelope.fromJson({
          'batchId': 'b',
          'requests': [request('r1')],
          'options': {'timeoutMs': kMaxBatchTimeoutMs + 1},
        }),
        throwsA(isA<ProtocolException>()),
      );
    });
  });

  group('PluginErrorCode', () {
    test('code strings are stable and retryable flags are correct', () {
      expect(PluginErrorCode.timeout.code, 'TIMEOUT');
      expect(PluginErrorCode.timeout.retryable, isTrue);
      expect(PluginErrorCode.invalidArgs.code, 'INVALID_ARGS');
      expect(PluginErrorCode.invalidArgs.retryable, isFalse);
    });

    test('fromString maps known codes and falls back to unknown', () {
      expect(PluginErrorCode.fromString('PERMISSION_DENIED'),
          PluginErrorCode.permissionDenied);
      expect(PluginErrorCode.fromString('NOPE'), PluginErrorCode.unknown);
    });
  });

  test('PluginResponse.failure serializes the error without stack traces', () {
    final response = PluginResponse.failure(
      requestId: 'r1',
      error: PluginError(
        code: PluginErrorCode.executionError,
        message: 'Plugin execution failed',
      ),
    );
    final json = response.toJson();
    expect(json['success'], isFalse);
    final error = json['error'] as Map<String, dynamic>;
    expect(error['code'], 'EXECUTION_ERROR');
    expect(error.containsKey('stackTrace'), isFalse);
  });
}
