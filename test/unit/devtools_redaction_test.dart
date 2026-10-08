// regression: SEC-007 — the debug inspector must not retain request or response
// payloads (args/data) in its log.
import 'package:flutter_test/flutter_test.dart';
import 'package:sweetmelon/packages/devtools/lib/devtools.dart';

void main() {
  group('BridgeInspector.redact (SEC-007)', () {
    test('replaces args and data and keeps routing fields', () {
      final out = BridgeInspector.redact({
        'plugin': 'storage',
        'method': 'readFile',
        'args': {'path': 'private/notes.txt'},
        'data': 'file contents',
      });
      expect(out['args'], '[redacted]');
      expect(out['data'], '[redacted]');
      expect(out['plugin'], 'storage');
      expect(out['method'], 'readFile');
    });

    test('does not mutate the input map', () {
      final input = <String, dynamic>{
        'args': {'key': 'token'},
      };
      BridgeInspector.redact(input);
      expect(input['args'], {'key': 'token'});
    });
  });
}
