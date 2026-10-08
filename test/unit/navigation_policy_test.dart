import 'package:flutter_test/flutter_test.dart';
import 'package:sweetmelon/packages/core/lib/src/runtime/navigation_policy.dart';

void main() {
  const policy = NavigationPolicy(allowedHosts: {'app.example.com'});

  group('main frame', () {
    test('allows about:blank used for application HTML', () {
      expect(policy.evaluate('about:blank', isMainFrame: true).allowed, isTrue);
    });

    test('allows https on an allow-listed host', () {
      expect(
        policy
            .evaluate('https://app.example.com/page', isMainFrame: true)
            .allowed,
        isTrue,
      );
    });

    test('blocks https on a host that is not allow-listed', () {
      final verdict =
          policy.evaluate('https://evil.example.net/', isMainFrame: true);
      expect(verdict.allowed, isFalse);
      expect(verdict.reason, 'host not in allow-list');
    });

    test('blocks plain http by default', () {
      expect(
        policy.evaluate('http://app.example.com/', isMainFrame: true).allowed,
        isFalse,
      );
    });

    test('allows http only when explicitly enabled (development)', () {
      const dev = NavigationPolicy(
        allowedHosts: {'localhost'},
        allowInsecureHttp: true,
      );
      expect(dev.evaluate('http://localhost:8080/', isMainFrame: true).allowed,
          isTrue);
    });
  });

  group('dangerous schemes (SEC-001)', () {
    for (final url in [
      'javascript:alert(1)',
      'file:///etc/passwd',
      'intent://scan/#Intent;scheme=zxing;end',
      'data:text/html,<script>alert(1)</script>',
      'content://com.android.providers/whatever',
      'about:srcdoc',
    ]) {
      test('blocks $url', () {
        expect(policy.evaluate(url, isMainFrame: true).allowed, isFalse);
        expect(policy.evaluate(url, isMainFrame: false).allowed, isFalse);
      });
    }

    test('blocks malformed URLs', () {
      expect(
          policy.evaluate('http://[::1', isMainFrame: true).allowed, isFalse);
    });

    test('blocks URLs without a host', () {
      expect(
          policy.evaluate('https:///path', isMainFrame: true).allowed, isFalse);
    });
  });

  group('sub-frames', () {
    test('sub-frame to a non-allow-listed host is blocked with its own reason',
        () {
      final verdict =
          policy.evaluate('https://ads.example.org/', isMainFrame: false);
      expect(verdict.allowed, isFalse);
      expect(verdict.reason, 'sub-frame host not allowed');
    });

    test('sub-frame to an allow-listed host is allowed', () {
      expect(
        policy
            .evaluate('https://app.example.com/embed', isMainFrame: false)
            .allowed,
        isTrue,
      );
    });
  });

  test('host comparison is case-insensitive for the URL side', () {
    expect(
      policy.evaluate('https://APP.example.com/', isMainFrame: true).allowed,
      isTrue,
    );
  });

  test('an empty allow-list blocks every remote host', () {
    const none = NavigationPolicy();
    expect(none.evaluate('https://app.example.com/', isMainFrame: true).allowed,
        isFalse);
    expect(none.evaluate('about:blank', isMainFrame: true).allowed, isTrue);
  });
}
