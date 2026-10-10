# فاز ۱۰ — ۸ پلاگین بهبود تجربه کاربری

---

# پلاگین ۱: In-App Review

## 📄 `lib/plugins/in_app_review/lib/in_app_review_plugin.dart`

```dart
import 'package:in_app_review/in_app_review.dart';
import 'package:sweetmelon/packages/core/lib/core.dart';
import 'package:sweetmelon/packages/plugin_engine/lib/plugin_engine.dart';

class InAppReviewPlugin extends Plugin {
  final InAppReview _review = InAppReview.instance;

  @override
  String get name => 'inAppReview';

  @override
  String get version => '1.0.0';

  @override
  String get description => 'In-app review and rating prompt';

  @override
  List<String> get supportedMethods => [
        'isAvailable',
        'requestReview',
        'openStoreListing',
        'getInfo',
      ];

  @override
  Future<dynamic> onCall(String method, Map<String, dynamic> args) async {
    switch (method) {
      case 'isAvailable':
        return _isAvailable();
      case 'requestReview':
        return _requestReview();
      case 'openStoreListing':
        return _openStoreListing(args);
      case 'getInfo':
        return {'name': name, 'version': version};
      default:
        throw UnsupportedError('Method "$method" not supported');
    }
  }

  Future<Map<String, dynamic>> _isAvailable() async {
    try {
      final available = await _review.isAvailable();
      return {'available': available};
    } catch (e) {
      return {'available': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> _requestReview() async {
    try {
      final available = await _review.isAvailable();
      if (!available) {
        return {'requested': false, 'reason': 'not_available'};
      }

      await _review.requestReview();
      BridgeLogger.info('InAppReview', 'Review dialog requested');

      return {'requested': true};
    } catch (e) {
      BridgeLogger.error('InAppReview', 'Request failed: $e');
      return {'requested': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> _openStoreListing(
    Map<String, dynamic> args,
  ) async {
    final appStoreId = args['appStoreId'] as String?;

    try {
      await _review.openStoreListing(appStoreId: appStoreId);
      return {'opened': true};
    } catch (e) {
      return {'opened': false, 'error': e.toString()};
    }
  }
}
```

## 📄 `lib/plugins/in_app_review/pubspec.yaml`

```yaml
name: in_app_review_plugin
description: In-app review plugin
version: 1.0.0

environment:
  sdk: ^3.0.0

dependencies:
  flutter:
    sdk: flutter
  plugin_engine:
    path: ../../packages/plugin_engine
  core:
    path: ../../packages/core
  in_app_review: ^2.0.9
```

---

# پلاگین ۲: Native Market

## 📄 `lib/plugins/native_market/lib/native_market_plugin.dart`

```dart
import 'dart:io';

import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:sweetmelon/packages/core/lib/core.dart';
import 'package:sweetmelon/packages/plugin_engine/lib/plugin_engine.dart';

class NativeMarketPlugin extends Plugin {
  PackageInfo? _packageInfo;

  @override
  String get name => 'nativeMarket';

  @override
  String get version => '1.0.0';

  @override
  String get description => 'Link to app stores and market pages';

  @override
  List<String> get supportedMethods => [
        'openStore',
        'openDeveloperPage',
        'openOtherApp',
        'getStoreUrl',
        'getInfo',
      ];

  @override
  Future<void> onInitialize() async {
    _packageInfo = await PackageInfo.fromPlatform();
  }

  @override
  Future<dynamic> onCall(String method, Map<String, dynamic> args) async {
    switch (method) {
      case 'openStore':
        return _openStore(args);
      case 'openDeveloperPage':
        return _openDeveloperPage(args);
      case 'openOtherApp':
        return _openOtherApp(args);
      case 'getStoreUrl':
        return _getStoreUrl(args);
      case 'getInfo':
        return {
          'name': name,
          'version': version,
          'packageName': _packageInfo?.packageName,
        };
      default:
        throw UnsupportedError('Method "$method" not supported');
    }
  }

  Future<Map<String, dynamic>> _openStore(Map<String, dynamic> args) async {
    final packageName = args['packageName'] as String? ??
        _packageInfo?.packageName ??
        '';

    if (packageName.isEmpty) {
      return {'opened': false, 'reason': 'no_package_name'};
    }

    final marketUri = Uri.parse('market://details?id=$packageName');
    final webUri = Uri.parse(
      'https://play.google.com/store/apps/details?id=$packageName',
    );

    try {
      if (await canLaunchUrl(marketUri)) {
        await launchUrl(marketUri, mode: LaunchMode.externalApplication);
        return {'opened': true, 'via': 'market'};
      }

      await launchUrl(webUri, mode: LaunchMode.externalApplication);
      return {'opened': true, 'via': 'web'};
    } catch (e) {
      return {'opened': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> _openDeveloperPage(
    Map<String, dynamic> args,
  ) async {
    final developerId = args['developerId'] as String;

    final marketUri = Uri.parse(
      'market://dev?id=$developerId',
    );
    final webUri = Uri.parse(
      'https://play.google.com/store/apps/dev?id=$developerId',
    );

    try {
      if (await canLaunchUrl(marketUri)) {
        await launchUrl(marketUri, mode: LaunchMode.externalApplication);
        return {'opened': true, 'via': 'market'};
      }

      await launchUrl(webUri, mode: LaunchMode.externalApplication);
      return {'opened': true, 'via': 'web'};
    } catch (e) {
      return {'opened': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> _openOtherApp(
    Map<String, dynamic> args,
  ) async {
    final packageName = args['packageName'] as String;
    return _openStore({'packageName': packageName});
  }

  Map<String, dynamic> _getStoreUrl(Map<String, dynamic> args) {
    final packageName = args['packageName'] as String? ??
        _packageInfo?.packageName ??
        '';

    return {
      'playStore':
          'https://play.google.com/store/apps/details?id=$packageName',
      'market': 'market://details?id=$packageName',
      'packageName': packageName,
    };
  }

  @override
  Future<ValidationResult> validateArgs(
    String method,
    Map<String, dynamic> args,
  ) async {
    switch (method) {
      case 'openDeveloperPage':
        if (args['developerId'] is! String) {
          return ValidationResult.invalid('developerId is required');
        }
        return ValidationResult.valid();
      case 'openOtherApp':
        if (args['packageName'] is! String) {
          return ValidationResult.invalid('packageName is required');
        }
        return ValidationResult.valid();
      default:
        return ValidationResult.valid();
    }
  }
}
```

## 📄 `lib/plugins/native_market/pubspec.yaml`

```yaml
name: native_market_plugin
description: App store and market link plugin
version: 1.0.0

environment:
  sdk: ^3.0.0

dependencies:
  flutter:
    sdk: flutter
  plugin_engine:
    path: ../../packages/plugin_engine
  core:
    path: ../../packages/core
  url_launcher: ^6.3.0
  package_info_plus: ^8.0.2
```

---

# پلاگین ۳: Screenshot

## 📄 `lib/plugins/screenshot/lib/screenshot_plugin.dart`

```dart
import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sweetmelon/packages/core/lib/core.dart';
import 'package:sweetmelon/packages/plugin_engine/lib/plugin_engine.dart';
import 'package:sweetmelon/plugins/qr_scanner/lib/qr_scanner_plugin.dart';

class ScreenshotPlugin extends Plugin {
  @override
  String get name => 'screenshot';

  @override
  String get version => '1.0.0';

  @override
  String get description => 'Capture screenshots of the current view';

  @override
  List<String> get supportedMethods => [
        'capture',
        'getInfo',
      ];

  @override
  Future<dynamic> onCall(String method, Map<String, dynamic> args) async {
    switch (method) {
      case 'capture':
        return _capture(args);
      case 'getInfo':
        return {'name': name, 'version': version};
      default:
        throw UnsupportedError('Method "$method" not supported');
    }
  }

  Future<Map<String, dynamic>> _capture(Map<String, dynamic> args) async {
    final quality = (args['quality'] as num?)?.toInt() ?? 100;
    final format = args['format'] as String? ?? 'png';
    final fileName = args['fileName'] as String? ??
        'screenshot_${DateTime.now().millisecondsSinceEpoch}';
    final baseDir = args['baseDir'] as String? ?? 'temporary';

    try {
      final context = QrScannerPlugin.navigatorKey?.currentContext;
      if (context == null) {
        return {'captured': false, 'reason': 'no_context'};
      }

      final renderObject = context.findRenderObject();
      if (renderObject == null || renderObject is! RenderRepaintBoundary) {
        return {'captured': false, 'reason': 'no_render_object'};
      }

      final boundary = renderObject;
      final pixelRatio = ui.PlatformDispatcher.instance.views.first.devicePixelRatio;
      final image = await boundary.toImage(pixelRatio: pixelRatio);
      final byteData = await image.toByteData(
        format: format == 'jpg' || format == 'jpeg'
            ? ui.ImageByteFormat.rawRgba
            : ui.ImageByteFormat.png,
      );

      if (byteData == null) {
        return {'captured': false, 'reason': 'byte_conversion_failed'};
      }

      final ext = format == 'jpg' || format == 'jpeg' ? '.jpg' : '.png';
      final dir = await _resolveDir(baseDir);
      final screenshotDir = Directory(p.join(dir.path, 'screenshots'));
      await screenshotDir.create(recursive: true);

      final filePath = p.join(screenshotDir.path, '$fileName$ext');
      final file = File(filePath);
      await file.writeAsBytes(byteData.buffer.asUint8List());

      final stat = await file.stat();

      BridgeLogger.info('Screenshot', 'Captured: $filePath');

      return {
        'captured': true,
        'path': filePath,
        'fileName': '$fileName$ext',
        'size': stat.size,
        'width': image.width,
        'height': image.height,
        'format': format,
      };
    } catch (e) {
      BridgeLogger.error('Screenshot', 'Capture failed: $e');
      return {'captured': false, 'error': e.toString()};
    }
  }

  Future<Directory> _resolveDir(String baseDir) async {
    switch (baseDir) {
      case 'documents':
        return getApplicationDocumentsDirectory();
      case 'cache':
        return getApplicationCacheDirectory();
      case 'temporary':
      default:
        return getTemporaryDirectory();
    }
  }
}
```

## 📄 `lib/plugins/screenshot/pubspec.yaml`

```yaml
name: screenshot_plugin
description: Screenshot capture plugin
version: 1.0.0

environment:
  sdk: ^3.0.0

dependencies:
  flutter:
    sdk: flutter
  plugin_engine:
    path: ../../packages/plugin_engine
  core:
    path: ../../packages/core
  qr_scanner:
    path: ../qr_scanner
  path_provider: ^2.1.1
  path: ^1.9.0
```

---

# پلاگین ۴: Safe Area

## 📄 `lib/plugins/safe_area/lib/safe_area_plugin.dart`

```dart
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:sweetmelon/packages/plugin_engine/lib/plugin_engine.dart';
import 'package:sweetmelon/plugins/qr_scanner/lib/qr_scanner_plugin.dart';

class SafeAreaPlugin extends Plugin {
  @override
  String get name => 'safeArea';

  @override
  String get version => '1.0.0';

  @override
  String get description => 'Get safe area insets (notch, status bar, etc)';

  @override
  List<String> get supportedMethods => [
        'getInsets',
        'getScreenInfo',
        'getInfo',
      ];

  @override
  Future<dynamic> onCall(String method, Map<String, dynamic> args) async {
    switch (method) {
      case 'getInsets':
        return _getInsets();
      case 'getScreenInfo':
        return _getScreenInfo();
      case 'getInfo':
        return {'name': name, 'version': version};
      default:
        throw UnsupportedError('Method "$method" not supported');
    }
  }

  Map<String, dynamic> _getInsets() {
    final context = QrScannerPlugin.navigatorKey?.currentContext;

    if (context != null) {
      final mediaQuery = MediaQuery.of(context);
      final padding = mediaQuery.padding;
      final viewInsets = mediaQuery.viewInsets;
      final viewPadding = mediaQuery.viewPadding;

      return {
        'padding': {
          'top': padding.top,
          'bottom': padding.bottom,
          'left': padding.left,
          'right': padding.right,
        },
        'viewInsets': {
          'top': viewInsets.top,
          'bottom': viewInsets.bottom,
          'left': viewInsets.left,
          'right': viewInsets.right,
        },
        'viewPadding': {
          'top': viewPadding.top,
          'bottom': viewPadding.bottom,
          'left': viewPadding.left,
          'right': viewPadding.right,
        },
      };
    }

    final view = ui.PlatformDispatcher.instance.views.first;
    final dpr = view.devicePixelRatio;
    final padding = view.padding;
    final viewInsets = view.viewInsets;

    return {
      'padding': {
        'top': padding.top / dpr,
        'bottom': padding.bottom / dpr,
        'left': padding.left / dpr,
        'right': padding.right / dpr,
      },
      'viewInsets': {
        'top': viewInsets.top / dpr,
        'bottom': viewInsets.bottom / dpr,
        'left': viewInsets.left / dpr,
        'right': viewInsets.right / dpr,
      },
    };
  }

  Map<String, dynamic> _getScreenInfo() {
    final view = ui.PlatformDispatcher.instance.views.first;
    final dpr = view.devicePixelRatio;
    final size = view.physicalSize;

    final context = QrScannerPlugin.navigatorKey?.currentContext;
    final orientation = context != null
        ? MediaQuery.of(context).orientation.name
        : 'unknown';

    return {
      'width': size.width / dpr,
      'height': size.height / dpr,
      'physicalWidth': size.width,
      'physicalHeight': size.height,
      'devicePixelRatio': dpr,
      'orientation': orientation,
      'textScaleFactor': context != null
          ? MediaQuery.of(context).textScaler.scale(1.0)
          : 1.0,
    };
  }
}
```

## 📄 `lib/plugins/safe_area/pubspec.yaml`

```yaml
name: safe_area_plugin
description: Safe area insets plugin
version: 1.0.0

environment:
  sdk: ^3.0.0

dependencies:
  flutter:
    sdk: flutter
  plugin_engine:
    path: ../../packages/plugin_engine
  qr_scanner:
    path: ../qr_scanner
```

---

# پلاگین ۵: Date/Time Picker

## 📄 `lib/plugins/date_picker/lib/date_picker_plugin.dart`

```dart
import 'package:flutter/material.dart';
import 'package:sweetmelon/packages/plugin_engine/lib/plugin_engine.dart';
import 'package:sweetmelon/plugins/qr_scanner/lib/qr_scanner_plugin.dart';

class DatePickerPlugin extends Plugin {
  @override
  String get name => 'datePicker';

  @override
  String get version => '1.0.0';

  @override
  String get description => 'Native date and time picker dialogs';

  @override
  List<String> get supportedMethods => [
        'pickDate',
        'pickTime',
        'pickDateTime',
        'pickDateRange',
        'getInfo',
      ];

  BuildContext? get _context => QrScannerPlugin.navigatorKey?.currentContext;

  @override
  Future<dynamic> onCall(String method, Map<String, dynamic> args) async {
    switch (method) {
      case 'pickDate':
        return _pickDate(args);
      case 'pickTime':
        return _pickTime(args);
      case 'pickDateTime':
        return _pickDateTime(args);
      case 'pickDateRange':
        return _pickDateRange(args);
      case 'getInfo':
        return {'name': name, 'version': version};
      default:
        throw UnsupportedError('Method "$method" not supported');
    }
  }

  Future<Map<String, dynamic>> _pickDate(Map<String, dynamic> args) async {
    final context = _context;
    if (context == null) {
      return {'picked': false, 'reason': 'no_context'};
    }

    final initialMs = (args['initialDateMs'] as num?)?.toInt();
    final firstMs = (args['firstDateMs'] as num?)?.toInt();
    final lastMs = (args['lastDateMs'] as num?)?.toInt();
    final title = args['title'] as String?;

    final now = DateTime.now();
    final initialDate = initialMs != null
        ? DateTime.fromMillisecondsSinceEpoch(initialMs)
        : now;
    final firstDate = firstMs != null
        ? DateTime.fromMillisecondsSinceEpoch(firstMs)
        : DateTime(now.year - 100);
    final lastDate = lastMs != null
        ? DateTime.fromMillisecondsSinceEpoch(lastMs)
        : DateTime(now.year + 100);

    final result = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      helpText: title,
    );

    if (result == null) {
      return {'picked': false, 'reason': 'cancelled'};
    }

    return {
      'picked': true,
      'year': result.year,
      'month': result.month,
      'day': result.day,
      'dateMs': result.millisecondsSinceEpoch,
      'dateIso': result.toIso8601String(),
      'formatted': '${result.year}-${result.month.toString().padLeft(2, '0')}-${result.day.toString().padLeft(2, '0')}',
    };
  }

  Future<Map<String, dynamic>> _pickTime(Map<String, dynamic> args) async {
    final context = _context;
    if (context == null) {
      return {'picked': false, 'reason': 'no_context'};
    }

    final initialHour = (args['initialHour'] as num?)?.toInt() ??
        TimeOfDay.now().hour;
    final initialMinute = (args['initialMinute'] as num?)?.toInt() ??
        TimeOfDay.now().minute;
    final use24h = args['use24h'] as bool? ?? true;
    final title = args['title'] as String?;

    final result = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: initialHour, minute: initialMinute),
      builder: use24h
          ? (context, child) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(alwaysUse24HourFormat: true),
                child: child!,
              )
          : null,
      helpText: title,
    );

    if (result == null) {
      return {'picked': false, 'reason': 'cancelled'};
    }

    return {
      'picked': true,
      'hour': result.hour,
      'minute': result.minute,
      'formatted': '${result.hour.toString().padLeft(2, '0')}:${result.minute.toString().padLeft(2, '0')}',
    };
  }

  Future<Map<String, dynamic>> _pickDateTime(Map<String, dynamic> args) async {
    final dateResult = await _pickDate(args);
    if (dateResult['picked'] != true) return dateResult;

    final timeResult = await _pickTime(args);
    if (timeResult['picked'] != true) return timeResult;

    final date = DateTime(
      dateResult['year'] as int,
      dateResult['month'] as int,
      dateResult['day'] as int,
      timeResult['hour'] as int,
      timeResult['minute'] as int,
    );

    return {
      'picked': true,
      'year': date.year,
      'month': date.month,
      'day': date.day,
      'hour': date.hour,
      'minute': date.minute,
      'dateTimeMs': date.millisecondsSinceEpoch,
      'dateTimeIso': date.toIso8601String(),
      'formatted':
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} '
          '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}',
    };
  }

  Future<Map<String, dynamic>> _pickDateRange(Map<String, dynamic> args) async {
    final context = _context;
    if (context == null) {
      return {'picked': false, 'reason': 'no_context'};
    }

    final now = DateTime.now();
    final firstMs = (args['firstDateMs'] as num?)?.toInt();
    final lastMs = (args['lastDateMs'] as num?)?.toInt();

    final result = await showDateRangePicker(
      context: context,
      firstDate: firstMs != null
          ? DateTime.fromMillisecondsSinceEpoch(firstMs)
          : DateTime(now.year - 10),
      lastDate: lastMs != null
          ? DateTime.fromMillisecondsSinceEpoch(lastMs)
          : DateTime(now.year + 10),
    );

    if (result == null) {
      return {'picked': false, 'reason': 'cancelled'};
    }

    return {
      'picked': true,
      'start': {
        'dateMs': result.start.millisecondsSinceEpoch,
        'dateIso': result.start.toIso8601String(),
      },
      'end': {
        'dateMs': result.end.millisecondsSinceEpoch,
        'dateIso': result.end.toIso8601String(),
      },
      'durationDays': result.duration.inDays,
    };
  }
}
```

## 📄 `lib/plugins/date_picker/pubspec.yaml`

```yaml
name: date_picker_plugin
description: Date and time picker plugin
version: 1.0.0

environment:
  sdk: ^3.0.0

dependencies:
  flutter:
    sdk: flutter
  plugin_engine:
    path: ../../packages/plugin_engine
  qr_scanner:
    path: ../qr_scanner
```

---

# پلاگین ۶: Action Sheet

## 📄 `lib/plugins/action_sheet/lib/action_sheet_plugin.dart`

```dart
import 'package:flutter/material.dart';
import 'package:sweetmelon/packages/plugin_engine/lib/plugin_engine.dart';
import 'package:sweetmelon/plugins/qr_scanner/lib/qr_scanner_plugin.dart';

class ActionSheetPlugin extends Plugin {
  @override
  String get name => 'actionSheet';

  @override
  String get version => '1.0.0';

  @override
  String get description => 'Bottom sheet action selector plugin';

  @override
  List<String> get supportedMethods => [
        'show',
        'getInfo',
      ];

  BuildContext? get _context => QrScannerPlugin.navigatorKey?.currentContext;

  @override
  Future<dynamic> onCall(String method, Map<String, dynamic> args) async {
    switch (method) {
      case 'show':
        return _show(args);
      case 'getInfo':
        return {'name': name, 'version': version};
      default:
        throw UnsupportedError('Method "$method" not supported');
    }
  }

  Future<Map<String, dynamic>> _show(Map<String, dynamic> args) async {
    final context = _context;
    if (context == null) {
      return {'selected': false, 'reason': 'no_context'};
    }

    final title = args['title'] as String?;
    final message = args['message'] as String?;
    final options = List<Map<String, dynamic>>.from(
      (args['options'] as List).map(
        (o) => o is String ? {'title': o} : Map<String, dynamic>.from(o as Map),
      ),
    );
    final cancelText = args['cancelText'] as String? ?? 'Cancel';
    final destructiveIndex = (args['destructiveIndex'] as num?)?.toInt();

    final result = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ActionSheetWidget(
        title: title,
        message: message,
        options: options,
        cancelText: cancelText,
        destructiveIndex: destructiveIndex,
      ),
    );

    if (result == null) {
      return {'selected': false, 'reason': 'cancelled'};
    }

    return {
      'selected': true,
      'index': result,
      'value': options[result]['title'],
      'option': options[result],
    };
  }

  @override
  Future<ValidationResult> validateArgs(
    String method,
    Map<String, dynamic> args,
  ) async {
    if (method == 'show') {
      final options = args['options'];
      if (options is! List || options.isEmpty) {
        return ValidationResult.invalid('options (non-empty list) is required');
      }
    }
    return ValidationResult.valid();
  }
}

class _ActionSheetWidget extends StatelessWidget {
  final String? title;
  final String? message;
  final List<Map<String, dynamic>> options;
  final String cancelText;
  final int? destructiveIndex;

  const _ActionSheetWidget({
    this.title,
    this.message,
    required this.options,
    required this.cancelText,
    this.destructiveIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A2E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Title / Message
            if (title != null || message != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
                child: Column(
                  children: [
                    if (title != null)
                      Text(
                        title!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    if (message != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          message!,
                          style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                  ],
                ),
              ),

            const Divider(color: Colors.white12, height: 1),

            // Options
            ...options.asMap().entries.map((entry) {
              final index = entry.key;
              final option = entry.value;
              final isDestructive = index == destructiveIndex;
              final icon = option['icon'] as String?;

              return InkWell(
                onTap: () => Navigator.of(context).pop(index),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.white12, width: 0.5),
                    ),
                  ),
                  child: Row(
                    children: [
                      if (icon != null) ...[
                        Icon(
                          _parseIcon(icon),
                          color: isDestructive ? Colors.red : Colors.white70,
                          size: 22,
                        ),
                        const SizedBox(width: 16),
                      ],
                      Expanded(
                        child: Text(
                          option['title'] as String? ?? '',
                          style: TextStyle(
                            color: isDestructive ? Colors.red : Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      if (option['subtitle'] != null)
                        Text(
                          option['subtitle'] as String,
                          style: const TextStyle(
                            color: Colors.white38,
                            fontSize: 13,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }),

            // Cancel
            InkWell(
              onTap: () => Navigator.of(context).pop(null),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                width: double.infinity,
                child: Text(
                  cancelText,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  IconData _parseIcon(String name) {
    switch (name) {
      case 'delete': return Icons.delete_outline;
      case 'edit': return Icons.edit_outlined;
      case 'share': return Icons.share_outlined;
      case 'copy': return Icons.copy_outlined;
      case 'camera': return Icons.camera_alt_outlined;
      case 'photo': return Icons.photo_outlined;
      case 'file': return Icons.attach_file;
      case 'download': return Icons.download_outlined;
      case 'upload': return Icons.upload_outlined;
      case 'settings': return Icons.settings_outlined;
      case 'info': return Icons.info_outline;
      case 'warning': return Icons.warning_amber_outlined;
      default: return Icons.circle_outlined;
    }
  }
}
```

## 📄 `lib/plugins/action_sheet/pubspec.yaml`

```yaml
name: action_sheet_plugin
description: Bottom sheet action selector plugin
version: 1.0.0

environment:
  sdk: ^3.0.0

dependencies:
  flutter:
    sdk: flutter
  plugin_engine:
    path: ../../packages/plugin_engine
  qr_scanner:
    path: ../qr_scanner
```

---

# پلاگین ۷: Text Zoom

## 📄 `lib/plugins/text_zoom/lib/text_zoom_plugin.dart`

```dart
import 'package:webview_flutter/webview_flutter.dart';
import 'package:sweetmelon/packages/core/lib/core.dart';
import 'package:sweetmelon/packages/plugin_engine/lib/plugin_engine.dart';

typedef TextZoomEventEmitter = Future<void> Function(String event, dynamic data);

class TextZoomPlugin extends Plugin {
  final TextZoomEventEmitter? eventEmitter;

  double _currentZoom = 100;
  static const double _minZoom = 50;
  static const double _maxZoom = 300;

  TextZoomPlugin({this.eventEmitter});

  @override
  String get name => 'textZoom';

  @override
  String get version => '1.0.0';

  @override
  String get description => 'WebView text zoom for accessibility';

  @override
  List<String> get supportedMethods => [
        'get',
        'set',
        'increase',
        'decrease',
        'reset',
        'getInfo',
      ];

  @override
  Future<dynamic> onCall(String method, Map<String, dynamic> args) async {
    switch (method) {
      case 'get':
        return {'zoom': _currentZoom};
      case 'set':
        return _setZoom(args);
      case 'increase':
        return _increase(args);
      case 'decrease':
        return _decrease(args);
      case 'reset':
        return _setZoom({'zoom': 100});
      case 'getInfo':
        return {
          'name': name,
          'version': version,
          'zoom': _currentZoom,
          'minZoom': _minZoom,
          'maxZoom': _maxZoom,
        };
      default:
        throw UnsupportedError('Method "$method" not supported');
    }
  }

  Future<Map<String, dynamic>> _setZoom(Map<String, dynamic> args) async {
    final zoom = (args['zoom'] as num).toDouble().clamp(_minZoom, _maxZoom);
    _currentZoom = zoom;

    eventEmitter?.call('textZoom.changed', {
      'zoom': _currentZoom,
      'timestamp': DateTime.now().toIso8601String(),
    });

    BridgeLogger.info('TextZoom', 'Zoom set to: $_currentZoom%');

    return {'zoom': _currentZoom};
  }

  Future<Map<String, dynamic>> _increase(Map<String, dynamic> args) async {
    final step = (args['step'] as num?)?.toDouble() ?? 10;
    return _setZoom({'zoom': _currentZoom + step});
  }

  Future<Map<String, dynamic>> _decrease(Map<String, dynamic> args) async {
    final step = (args['step'] as num?)?.toDouble() ?? 10;
    return _setZoom({'zoom': _currentZoom - step});
  }

  @override
  Future<ValidationResult> validateArgs(
    String method,
    Map<String, dynamic> args,
  ) async {
    if (method == 'set') {
      final zoom = args['zoom'];
      if (zoom is! num) {
        return ValidationResult.invalid('zoom (number, 50-300) is required');
      }
    }
    return ValidationResult.valid();
  }
}
```

## 📄 `lib/plugins/text_zoom/pubspec.yaml`

```yaml
name: text_zoom_plugin
description: Text zoom accessibility plugin
version: 1.0.0

environment:
  sdk: ^3.0.0

dependencies:
  flutter:
    sdk: flutter
  plugin_engine:
    path: ../../packages/plugin_engine
  core:
    path: ../../packages/core
  webview_flutter: ^4.8.0
```

---

# پلاگین ۸: Screen Reader / Accessibility

## 📄 `lib/plugins/accessibility/lib/accessibility_plugin.dart`

```dart
import 'dart:async';

import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:sweetmelon/packages/core/lib/core.dart';
import 'package:sweetmelon/packages/plugin_engine/lib/plugin_engine.dart';

typedef A11yEventEmitter = Future<void> Function(String event, dynamic data);

class AccessibilityPlugin extends Plugin {
  final A11yEventEmitter? eventEmitter;

  AccessibilityPlugin({this.eventEmitter});

  @override
  String get name => 'accessibility';

  @override
  String get version => '1.0.0';

  @override
  String get description => 'Accessibility and screen reader plugin';

  @override
  List<String> get supportedMethods => [
        'isScreenReaderEnabled',
        'announce',
        'isBoldTextEnabled',
        'isReduceMotionEnabled',
        'isHighContrastEnabled',
        'getSettings',
        'getInfo',
      ];

  @override
  Future<dynamic> onCall(String method, Map<String, dynamic> args) async {
    switch (method) {
      case 'isScreenReaderEnabled':
        return _isScreenReaderEnabled();
      case 'announce':
        return _announce(args);
      case 'isBoldTextEnabled':
        return _isBoldTextEnabled();
      case 'isReduceMotionEnabled':
        return _isReduceMotionEnabled();
      case 'isHighContrastEnabled':
        return _isHighContrastEnabled();
      case 'getSettings':
        return _getSettings();
      case 'getInfo':
        return {'name': name, 'version': version};
      default:
        throw UnsupportedError('Method "$method" not supported');
    }
  }

  Future<Map<String, dynamic>> _isScreenReaderEnabled() async {
    final binding = SemanticsBinding.instance;
    final enabled = binding.platformDispatcher.semanticsEnabled;

    return {'enabled': enabled};
  }

  Future<Map<String, dynamic>> _announce(Map<String, dynamic> args) async {
    final message = args['message'] as String;
    final assertiveness = args['assertiveness'] as String? ?? 'polite';

    try {
      await SemanticsService.announce(
        message,
        assertiveness == 'assertive'
            ? TextDirection.ltr
            : TextDirection.ltr,
      );

      BridgeLogger.info('Accessibility', 'Announced: $message');

      return {'announced': true, 'message': message};
    } catch (e) {
      return {'announced': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> _isBoldTextEnabled() async {
    final binding = SemanticsBinding.instance;
    final boldText = binding.platformDispatcher.accessibilityFeatures.boldText;
    return {'enabled': boldText};
  }

  Future<Map<String, dynamic>> _isReduceMotionEnabled() async {
    final binding = SemanticsBinding.instance;
    final reduceMotion =
        binding.platformDispatcher.accessibilityFeatures.reduceMotion;
    return {'enabled': reduceMotion};
  }

  Future<Map<String, dynamic>> _isHighContrastEnabled() async {
    final binding = SemanticsBinding.instance;
    final highContrast =
        binding.platformDispatcher.accessibilityFeatures.highContrast;
    return {'enabled': highContrast};
  }

  Future<Map<String, dynamic>> _getSettings() async {
    final binding = SemanticsBinding.instance;
    final features = binding.platformDispatcher.accessibilityFeatures;
    final semanticsEnabled = binding.platformDispatcher.semanticsEnabled;

    return {
      'screenReaderEnabled': semanticsEnabled,
      'boldText': features.boldText,
      'reduceMotion': features.reduceMotion,
      'highContrast': features.highContrast,
      'invertColors': features.invertColors,
      'disableAnimations': features.disableAnimations,
      'reduceTransparency': features.reduceTransparency,
      'onOffSwitchLabels': features.onOffSwitchLabels,
    };
  }

  @override
  Future<ValidationResult> validateArgs(
    String method,
    Map<String, dynamic> args,
  ) async {
    if (method == 'announce') {
      final message = args['message'];
      if (message is! String || message.isEmpty) {
        return ValidationResult.invalid('message is required');
      }
    }
    return ValidationResult.valid();
  }
}
```

## 📄 `lib/plugins/accessibility/pubspec.yaml`

```yaml
name: accessibility_plugin
description: Accessibility and screen reader plugin
version: 1.0.0

environment:
  sdk: ^3.0.0

dependencies:
  flutter:
    sdk: flutter
  plugin_engine:
    path: ../../packages/plugin_engine
  core:
    path: ../../packages/core
```

---

# pubspec.yaml اصلی — dependency جدید

```yaml
  # فاز ۱۰
  in_app_review: ^2.0.9
```

---

# ثبت پلاگین‌ها

> imports:

```dart
import 'package:sweetmelon/plugins/in_app_review/lib/in_app_review_plugin.dart';
import 'package:sweetmelon/plugins/native_market/lib/native_market_plugin.dart';
import 'package:sweetmelon/plugins/screenshot/lib/screenshot_plugin.dart';
import 'package:sweetmelon/plugins/safe_area/lib/safe_area_plugin.dart';
import 'package:sweetmelon/plugins/date_picker/lib/date_picker_plugin.dart';
import 'package:sweetmelon/plugins/action_sheet/lib/action_sheet_plugin.dart';
import 'package:sweetmelon/plugins/text_zoom/lib/text_zoom_plugin.dart';
import 'package:sweetmelon/plugins/accessibility/lib/accessibility_plugin.dart';
```

> Eager plugins:

```dart
    await registry.register(SafeAreaPlugin());
    await registry.register(DatePickerPlugin());
    await registry.register(ActionSheetPlugin());
    await registry.register(TextZoomPlugin(eventEmitter: emitter));
    await registry.register(AccessibilityPlugin(eventEmitter: emitter));
```

> Lazy plugins:

```dart
      LazyPluginDefinition(
        id: 'inAppReview',
        version: '1.0.0',
        factory: () => InAppReviewPlugin(),
      ),
      LazyPluginDefinition(
        id: 'nativeMarket',
        version: '1.0.0',
        factory: () => NativeMarketPlugin(),
      ),
      LazyPluginDefinition(
        id: 'screenshot',
        version: '1.0.0',
        factory: () => ScreenshotPlugin(),
      ),
```

---

# NativeSDK — فاز ۱۰

```javascript
    inAppReview: {
      isAvailable: function () { return call('inAppReview', 'isAvailable', {}); },
      requestReview: function () { return call('inAppReview', 'requestReview', {}); },
      openStoreListing: function (appStoreId) { return call('inAppReview', 'openStoreListing', { appStoreId: appStoreId }); },
      getInfo: function () { return call('inAppReview', 'getInfo', {}); }
    },

    nativeMarket: {
      openStore: function (packageName) { return call('nativeMarket', 'openStore', { packageName: packageName }); },
      openDeveloperPage: function (developerId) { return call('nativeMarket', 'openDeveloperPage', { developerId: developerId }); },
      openOtherApp: function (packageName) { return call('nativeMarket', 'openOtherApp', { packageName: packageName }); },
      getStoreUrl: function (packageName) { return call('nativeMarket', 'getStoreUrl', { packageName: packageName }); },
      getInfo: function () { return call('nativeMarket', 'getInfo', {}); }
    },

    screenshot: {
      capture: function (o) { return call('screenshot', 'capture', o || {}); },
      getInfo: function () { return call('screenshot', 'getInfo', {}); }
    },

    safeArea: {
      getInsets: function () { return call('safeArea', 'getInsets', {}); },
      getScreenInfo: function () { return call('safeArea', 'getScreenInfo', {}); },
      getInfo: function () { return call('safeArea', 'getInfo', {}); }
    },

    datePicker: {
      pickDate: function (o) { return call('datePicker', 'pickDate', o || {}); },
      pickTime: function (o) { return call('datePicker', 'pickTime', o || {}); },
      pickDateTime: function (o) { return call('datePicker', 'pickDateTime', o || {}); },
      pickDateRange: function (o) { return call('datePicker', 'pickDateRange', o || {}); },
      getInfo: function () { return call('datePicker', 'getInfo', {}); }
    },

    actionSheet: {
      show: function (o) { return call('actionSheet', 'show', o); },
      getInfo: function () { return call('actionSheet', 'getInfo', {}); }
    },

    textZoom: {
      get: function () { return call('textZoom', 'get', {}); },
      set: function (zoom) { return call('textZoom', 'set', { zoom: zoom }); },
      increase: function (step) { return call('textZoom', 'increase', { step: step || 10 }); },
      decrease: function (step) { return call('textZoom', 'decrease', { step: step || 10 }); },
      reset: function () { return call('textZoom', 'reset', {}); },
      getInfo: function () { return call('textZoom', 'getInfo', {}); }
    },

    accessibility: {
      isScreenReaderEnabled: function () { return call('accessibility', 'isScreenReaderEnabled', {}); },
      announce: function (message, assertiveness) { return call('accessibility', 'announce', { message: message, assertiveness: assertiveness || 'polite' }); },
      isBoldTextEnabled: function () { return call('accessibility', 'isBoldTextEnabled', {}); },
      isReduceMotionEnabled: function () { return call('accessibility', 'isReduceMotionEnabled', {}); },
      isHighContrastEnabled: function () { return call('accessibility', 'isHighContrastEnabled', {}); },
      getSettings: function () { return call('accessibility', 'getSettings', {}); },
      getInfo: function () { return call('accessibility', 'getInfo', {}); }
    },
```

---

# خلاصه فاز ۱۰

## پلاگین‌های جدید

| # | پلاگین | نام JS | متدهای کلیدی |
|---|--------|--------|-------------|
| 62 | In-App Review | `inAppReview` | requestReview, openStoreListing |
| 63 | Native Market | `nativeMarket` | openStore, openDeveloperPage, openOtherApp |
| 64 | Screenshot | `screenshot` | capture |
| 65 | Safe Area | `safeArea` | getInsets, getScreenInfo |
| 66 | Date Picker | `datePicker` | pickDate, pickTime, pickDateTime, pickDateRange |
| 67 | Action Sheet | `actionSheet` | show (bottom sheet with options) |
| 68 | Text Zoom | `textZoom` | get, set, increase, decrease, reset |
| 69 | Accessibility | `accessibility` | isScreenReaderEnabled, announce, getSettings |

## مجموع کل: **69 پلاگین** 🎉

## نحوه استفاده JS

```javascript
// In-App Review
const { available } = await NativeSDK.inAppReview.isAvailable();
if (available) {
  await NativeSDK.inAppReview.requestReview();
}

// Native Market
await NativeSDK.nativeMarket.openStore();
await NativeSDK.nativeMarket.openOtherApp('com.whatsapp');

// Screenshot
const shot = await NativeSDK.screenshot.capture({
  format: 'png',
  quality: 100
});
// shot.path → فایل اسکرین‌شات

// Safe Area
const { padding } = await NativeSDK.safeArea.getInsets();
document.body.style.paddingTop = padding.top + 'px';

const screen = await NativeSDK.safeArea.getScreenInfo();
console.log(`Screen: ${screen.width}x${screen.height} @${screen.devicePixelRatio}x`);

// Date Picker
const date = await NativeSDK.datePicker.pickDate({
  title: 'Select birth date'
});
if (date.picked) {
  console.log(date.formatted); // "2024-01-15"
}

const time = await NativeSDK.datePicker.pickTime({ use24h: true });
if (time.picked) {
  console.log(time.formatted); // "14:30"
}

const range = await NativeSDK.datePicker.pickDateRange();
if (range.picked) {
  console.log(`${range.durationDays} days selected`);
}

// Action Sheet
const result = await NativeSDK.actionSheet.show({
  title: 'Choose action',
  message: 'What would you like to do?',
  options: [
    { title: 'Take Photo', icon: 'camera' },
    { title: 'Choose from Gallery', icon: 'photo' },
    { title: 'Upload File', icon: 'file' },
    { title: 'Delete', icon: 'delete' }
  ],
  destructiveIndex: 3,
  cancelText: 'Cancel'
});

if (result.selected) {
  console.log(`Selected: ${result.value} (index ${result.index})`);
}

// Text Zoom (دسترس‌پذیری)
await NativeSDK.textZoom.set(120); // 120%
await NativeSDK.textZoom.increase(10); // +10%
await NativeSDK.textZoom.reset(); // back to 100%

// Accessibility
const a11y = await NativeSDK.accessibility.getSettings();
if (a11y.screenReaderEnabled) {
  await NativeSDK.accessibility.announce('Page loaded successfully');
}

if (a11y.reduceMotion) {
  disableAnimations();
}
```

---

بگو تا **فاز ۱۱** (پلاگین‌های تخصصی) رو هم شروع کنم.
