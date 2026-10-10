import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sweetmelon/packages/core/lib/core.dart';

void main() {
  group('AppContext without a mounted navigator', () {
    test('is a singleton', () {
      expect(identical(AppContext(), AppContext()), true);
    });

    test('has no context until a navigator key is attached', () {
      final context = AppContext();

      expect(context.hasContext, false);
      expect(context.context, isNull);
      expect(context.mediaQuery, isNull);
    });

    test('reports the registered navigator key without mounting it', () {
      final context = AppContext();
      final key = GlobalKey<NavigatorState>();

      context.setNavigatorKey(key);

      expect(context.navigatorKey, same(key));
      expect(context.context, isNull);
      expect(context.hasContext, false);
    });

    test('pushPage, showAppDialog and showAppBottomSheet throw StateError', () {
      final context = AppContext();

      expect(
        () => context.pushPage<void>(const SizedBox()),
        throwsA(isA<StateError>()),
      );
      expect(
        () => context.showAppDialog<void>(const SizedBox()),
        throwsA(isA<StateError>()),
      );
      expect(
        () => context.showAppBottomSheet<void>(const SizedBox()),
        throwsA(isA<StateError>()),
      );
    });

    test('popPage is a silent no-op without a context', () {
      final context = AppContext();

      expect(() => context.popPage<int>(1), returnsNormally);
      expect(() => context.popPage<void>(), returnsNormally);
    });

    test('showSnackBar is a silent no-op without a messenger or context', () {
      final context = AppContext();

      expect(
        () => context.showSnackBar(const SnackBar(content: Text('hi'))),
        returnsNormally,
      );
      expect(context.scaffoldMessenger, isNull);
    });

    test('scaffold messenger key is registered but not yet mounted', () {
      final context = AppContext();
      final key = GlobalKey<ScaffoldMessengerState>();

      context.setScaffoldKey(key);

      expect(context.scaffoldMessenger, isNull);
    });
  });
}
