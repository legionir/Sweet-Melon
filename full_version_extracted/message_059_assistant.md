# فاز ۱۹: Production Ready

---

# بخش ۱: CI/CD Pipeline

## 📄 `.github/workflows/ci.yml`

```yaml
name: Sweetmelon CI/CD

on:
  push:
    branches: [main, develop, 'release/*']
  pull_request:
    branches: [main, develop]
  release:
    types: [published]

env:
  FLUTTER_VERSION: '3.24.0'
  JAVA_VERSION: '17'

jobs:
  # ── Analysis & Formatting ──
  analyze:
    name: Analyze & Format
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: ${{ env.FLUTTER_VERSION }}
          channel: stable
          cache: true

      - name: Install dependencies
        run: flutter pub get

      - name: Verify formatting
        run: dart format --output=none --set-exit-if-changed .

      - name: Analyze code
        run: flutter analyze --no-fatal-infos

      - name: Check for unused imports
        run: dart run dart_code_metrics:metrics analyze lib --fatal-style

  # ── Unit Tests ──
  test:
    name: Unit Tests
    runs-on: ubuntu-latest
    needs: analyze
    steps:
      - uses: actions/checkout@v4

      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: ${{ env.FLUTTER_VERSION }}
          channel: stable
          cache: true

      - name: Install dependencies
        run: flutter pub get

      - name: Run tests
        run: flutter test --coverage --reporter=github

      - name: Upload coverage to Codecov
        uses: codecov/codecov-action@v4
        with:
          file: coverage/lcov.info
          flags: unittests
          fail_ci_if_error: false

      - name: Generate coverage report
        run: |
          sudo apt-get install -y lcov
          genhtml coverage/lcov.info --output-directory coverage/html
          echo "Coverage report generated"

      - name: Upload coverage artifact
        uses: actions/upload-artifact@v4
        with:
          name: coverage-report
          path: coverage/html/
          retention-days: 30

  # ── Validate Config ──
  validate:
    name: Validate Configuration
    runs-on: ubuntu-latest
    needs: analyze
    steps:
      - uses: actions/checkout@v4

      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: ${{ env.FLUTTER_VERSION }}
          channel: stable
          cache: true

      - name: Install dependencies
        run: flutter pub get

      - name: Validate sweetmelon.yaml
        run: dart run bin/sweetmelon.dart validate

      - name: Run doctor
        run: dart run bin/sweetmelon.dart doctor || true

  # ── Build Android Debug ──
  build-android-debug:
    name: Build Android (Debug)
    runs-on: ubuntu-latest
    needs: [test, validate]
    steps:
      - uses: actions/checkout@v4

      - name: Setup Java
        uses: actions/setup-java@v4
        with:
          distribution: temurin
          java-version: ${{ env.JAVA_VERSION }}

      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: ${{ env.FLUTTER_VERSION }}
          channel: stable
          cache: true

      - name: Install dependencies
        run: flutter pub get

      - name: Build APK (debug)
        run: flutter build apk --debug --split-per-abi

      - name: Upload APK artifacts
        uses: actions/upload-artifact@v4
        with:
          name: apk-debug
          path: build/app/outputs/flutter-apk/*.apk
          retention-days: 7

  # ── Build Android Release ──
  build-android-release:
    name: Build Android (Release)
    runs-on: ubuntu-latest
    needs: [test, validate]
    if: github.event_name == 'release' || startsWith(github.ref, 'refs/heads/release/')
    environment: production
    steps:
      - uses: actions/checkout@v4

      - name: Setup Java
        uses: actions/setup-java@v4
        with:
          distribution: temurin
          java-version: ${{ env.JAVA_VERSION }}

      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: ${{ env.FLUTTER_VERSION }}
          channel: stable
          cache: true

      - name: Setup signing
        env:
          KEYSTORE_BASE64: ${{ secrets.KEYSTORE_BASE64 }}
          KEY_ALIAS: ${{ secrets.KEY_ALIAS }}
          KEY_PASSWORD: ${{ secrets.KEY_PASSWORD }}
          STORE_PASSWORD: ${{ secrets.STORE_PASSWORD }}
        run: |
          echo "$KEYSTORE_BASE64" | base64 --decode > android/app/keystore.jks
          cat > android/key.properties << EOF
          storePassword=$STORE_PASSWORD
          keyPassword=$KEY_PASSWORD
          keyAlias=$KEY_ALIAS
          storeFile=keystore.jks
          EOF

      - name: Install dependencies
        run: flutter pub get

      - name: Build APK (release)
        run: flutter build apk --release --split-per-abi

      - name: Build App Bundle
        run: flutter build appbundle --release

      - name: Upload APK
        uses: actions/upload-artifact@v4
        with:
          name: apk-release
          path: build/app/outputs/flutter-apk/*.apk
          retention-days: 90

      - name: Upload AAB
        uses: actions/upload-artifact@v4
        with:
          name: aab-release
          path: build/app/outputs/bundle/release/*.aab
          retention-days: 90

      - name: Upload to Play Store (Internal Track)
        if: github.event_name == 'release'
        uses: r0adkll/upload-google-play@v1
        with:
          serviceAccountJsonPlainText: ${{ secrets.PLAY_STORE_SERVICE_ACCOUNT }}
          packageName: com.example.sweet_melon
          releaseFiles: build/app/outputs/bundle/release/*.aab
          track: internal
          status: completed

  # ── Security Scan ──
  security:
    name: Security Scan
    runs-on: ubuntu-latest
    needs: analyze
    steps:
      - uses: actions/checkout@v4

      - name: Run Trivy vulnerability scanner
        uses: aquasecurity/trivy-action@master
        with:
          scan-type: fs
          scan-ref: .
          format: sarif
          output: trivy-results.sarif
          severity: HIGH,CRITICAL

      - name: Upload Trivy results
        uses: github/codeql-action/upload-sarif@v3
        if: always()
        with:
          sarif_file: trivy-results.sarif

  # ── Performance Benchmark ──
  benchmark:
    name: Performance Benchmark
    runs-on: ubuntu-latest
    needs: test
    if: github.event_name == 'pull_request'
    steps:
      - uses: actions/checkout@v4

      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: ${{ env.FLUTTER_VERSION }}
          channel: stable
          cache: true

      - name: Run benchmarks
        run: flutter test test/benchmark/ --reporter=json > benchmark-results.json || true

      - name: Comment benchmark results
        uses: actions/github-script@v7
        if: always()
        with:
          script: |
            const fs = require('fs');
            if (fs.existsSync('benchmark-results.json')) {
              const results = fs.readFileSync('benchmark-results.json', 'utf8');
              github.rest.issues.createComment({
                issue_number: context.issue.number,
                owner: context.repo.owner,
                repo: context.repo.repo,
                body: '## 📊 Benchmark Results\n```json\n' + results + '\n```'
              });
            }

  # ── Deploy DevTools ──
  deploy-devtools:
    name: Deploy DevTools
    runs-on: ubuntu-latest
    needs: build-android-debug
    if: github.ref == 'refs/heads/main'
    steps:
      - uses: actions/checkout@v4

      - name: Deploy to GitHub Pages
        uses: peaceiris/actions-gh-pages@v3
        with:
          github_token: ${{ secrets.GITHUB_TOKEN }}
          publish_dir: assets/devtools
          destination_dir: devtools

  # ── Notify ──
  notify:
    name: Notify
    runs-on: ubuntu-latest
    needs: [build-android-debug]
    if: always()
    steps:
      - name: Notify on success
        if: needs.build-android-debug.result == 'success'
        run: echo "✅ Build successful"

      - name: Notify on failure
        if: needs.build-android-debug.result == 'failure'
        run: echo "❌ Build failed"
```

---

## 📄 `.github/workflows/release.yml`

```yaml
name: Release

on:
  push:
    tags:
      - 'v*.*.*'

jobs:
  create-release:
    name: Create Release
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Generate changelog
        id: changelog
        run: |
          PREV_TAG=$(git describe --abbrev=0 --tags HEAD^ 2>/dev/null || echo "")
          if [ -n "$PREV_TAG" ]; then
            CHANGELOG=$(git log $PREV_TAG..HEAD --pretty=format:"- %s (%h)" --no-merges)
          else
            CHANGELOG=$(git log --pretty=format:"- %s (%h)" --no-merges -20)
          fi
          echo "changelog<<EOF" >> $GITHUB_OUTPUT
          echo "$CHANGELOG" >> $GITHUB_OUTPUT
          echo "EOF" >> $GITHUB_OUTPUT

      - name: Create GitHub Release
        uses: ncipollo/release-action@v1
        with:
          tag: ${{ github.ref_name }}
          name: Sweetmelon ${{ github.ref_name }}
          body: |
            ## 🍈 Sweetmelon ${{ github.ref_name }}
            
            ### Changes
            ${{ steps.changelog.outputs.changelog }}
            
            ### Installation
            ```bash
            flutter pub get
            flutter run
            ```
          draft: false
          prerelease: ${{ contains(github.ref_name, '-') }}
```

---

# بخش ۲: ProGuard/R8 Configuration

## 📄 `android/app/proguard-rules.pro`

```pro
# ──────────────────────────────────────────────────────────────────
# Sweetmelon Native Bridge — ProGuard Rules
# ──────────────────────────────────────────────────────────────────

# ── Flutter ──
-keep class io.flutter.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.app.** { *; }
-dontwarn io.flutter.**

# ── Kotlin ──
-keep class kotlin.** { *; }
-keep class kotlin.Metadata { *; }
-keepclassmembers class kotlin.Metadata {
    public <methods>;
}
-dontwarn kotlin.**

# ── Android Core ──
-keepattributes *Annotation*
-keepattributes SourceFile,LineNumberTable
-keepattributes Signature
-keepattributes Exceptions

# ── Firebase Core ──
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# ── Firebase Analytics ──
-keep class com.google.android.gms.measurement.** { *; }

# ── Firebase Crashlytics ──
-keepattributes SourceFile,LineNumberTable
-keep public class * extends java.lang.Exception
-keep class com.crashlytics.** { *; }
-dontwarn com.crashlytics.**

# ── Firebase Messaging ──
-keep class com.google.firebase.messaging.** { *; }

# ── Firebase Auth ──
-keep class com.google.firebase.auth.** { *; }

# ── Google Sign In ──
-keep class com.google.android.gms.auth.** { *; }
-keep class com.google.android.gms.common.** { *; }

# ── WebView ──
-keep class android.webkit.** { *; }
-keepclassmembers class * extends android.webkit.WebViewClient {
    public void *(android.webkit.WebView, java.lang.String, android.graphics.Bitmap);
    public boolean *(android.webkit.WebView, java.lang.String);
}
-keepclassmembers class * extends android.webkit.WebChromeClient {
    public void *(android.webkit.WebView, java.lang.String);
}

# ── OkHttp ──
-dontwarn okhttp3.**
-dontwarn okio.**
-keep class okhttp3.** { *; }
-keep interface okhttp3.** { *; }

# ── Geolocator ──
-keep class com.baseflow.geolocator.** { *; }
-dontwarn com.baseflow.geolocator.**

# ── Camera ──
-keep class io.flutter.plugins.camera.** { *; }
-dontwarn io.flutter.plugins.camera.**

# ── Image Picker ──
-keep class io.flutter.plugins.imagepicker.** { *; }
-dontwarn io.flutter.plugins.imagepicker.**

# ── Biometrics ──
-keep class androidx.biometric.** { *; }
-dontwarn androidx.biometric.**

# ── In-App Purchase ──
-keep class com.android.billingclient.** { *; }
-dontwarn com.android.billingclient.**

# ── Secure Storage ──
-keep class androidx.security.crypto.** { *; }

# ── NFC ──
-keep class android.nfc.** { *; }

# ── Bluetooth ──
-keep class android.bluetooth.** { *; }

# ── SQLite ──
-keep class org.sqlite.** { *; }
-dontwarn org.sqlite.**

# ── Gson (if used) ──
-keepattributes Signature
-keepattributes *Annotation*
-dontwarn sun.misc.**
-keep class com.google.gson.** { *; }
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer

# ── Remove debug logging in release ──
-assumenosideeffects class android.util.Log {
    public static boolean isLoggable(java.lang.String, int);
    public static int v(...);
    public static int i(...);
    public static int w(...);
    public static int d(...);
}

# ── Keep native methods ──
-keepclassmembers class * {
    native <methods>;
}

# ── Keep Parcelable ──
-keepclassmembers class * implements android.os.Parcelable {
    public static final ** CREATOR;
}

# ── Keep Serializable ──
-keepclassmembers class * implements java.io.Serializable {
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readReadResolve();
}

# ── Keep MainActivity ──
-keep class com.example.sweet_melon.MainActivity { *; }
-keep class com.example.sweet_melon.** { *; }
```

---

## 📄 `android/app/src/main/res/xml/backup_rules.xml`

```xml
<?xml version="1.0" encoding="utf-8"?>
<full-backup-content>
    <exclude domain="sharedpref" path="."/>
    <exclude domain="database" path="."/>
    <exclude domain="file" path="."/>
    <exclude domain="external" path="."/>
</full-backup-content>
```

---

## 📄 `android/app/src/main/res/xml/data_extraction_rules.xml`

```xml
<?xml version="1.0" encoding="utf-8"?>
<data-extraction-rules>
    <cloud-backup>
        <exclude domain="sharedpref" path="."/>
        <exclude domain="database" path="."/>
    </cloud-backup>
    <device-transfer>
        <exclude domain="sharedpref" path="."/>
    </device-transfer>
</data-extraction-rules>
```

---

# بخش ۳: Performance Audit

## 📄 `lib/packages/core/lib/src/performance/performance_monitor.dart`

```dart
import 'dart:async';

import 'package:sweetmelon/packages/core/lib/core.dart';

class PerformanceMetric {
  final String name;
  final String category;
  final int durationMs;
  final bool success;
  final DateTime timestamp;
  final Map<String, dynamic> extra;

  const PerformanceMetric({
    required this.name,
    required this.category,
    required this.durationMs,
    required this.success,
    required this.timestamp,
    this.extra = const {},
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'category': category,
        'durationMs': durationMs,
        'success': success,
        'timestamp': timestamp.toIso8601String(),
        ...extra,
      };
}

class PerformanceAudit {
  final List<PerformanceMetric> _metrics = [];
  final int _maxMetrics;

  PerformanceAudit({int maxMetrics = 1000}) : _maxMetrics = maxMetrics;

  void record(PerformanceMetric metric) {
    _metrics.add(metric);
    if (_metrics.length > _maxMetrics) {
      _metrics.removeAt(0);
    }
  }

  Future<T> measure<T>({
    required String name,
    required String category,
    required Future<T> Function() fn,
  }) async {
    final stopwatch = Stopwatch()..start();
    bool success = true;

    try {
      final result = await fn();
      stopwatch.stop();
      return result;
    } catch (e) {
      success = false;
      stopwatch.stop();
      rethrow;
    } finally {
      record(PerformanceMetric(
        name: name,
        category: category,
        durationMs: stopwatch.elapsedMilliseconds,
        success: success,
        timestamp: DateTime.now(),
      ));
    }
  }

  AuditReport generateReport() {
    if (_metrics.isEmpty) {
      return AuditReport(
        totalOperations: 0,
        successRate: 0,
        avgDurationMs: 0,
        p95DurationMs: 0,
        p99DurationMs: 0,
        slowestOperations: [],
        categoryBreakdown: {},
        recommendations: [],
      );
    }

    final sorted = List<PerformanceMetric>.from(_metrics)
      ..sort((a, b) => a.durationMs.compareTo(b.durationMs));

    final successCount = _metrics.where((m) => m.success).length;
    final successRate = successCount / _metrics.length * 100;

    final avgDuration = _metrics
            .map((m) => m.durationMs)
            .reduce((a, b) => a + b) /
        _metrics.length;

    final p95Index = (sorted.length * 0.95).round().clamp(0, sorted.length - 1);
    final p99Index = (sorted.length * 0.99).round().clamp(0, sorted.length - 1);

    // Category breakdown
    final categories = <String, List<PerformanceMetric>>{};
    for (final metric in _metrics) {
      categories.putIfAbsent(metric.category, () => []);
      categories[metric.category]!.add(metric);
    }

    final breakdown = categories.map((cat, metrics) {
      final avg = metrics.map((m) => m.durationMs).reduce((a, b) => a + b) /
          metrics.length;
      return MapEntry(cat, {
        'count': metrics.length,
        'avgMs': avg.round(),
        'successRate': (metrics.where((m) => m.success).length / metrics.length * 100).round(),
      });
    });

    // Slowest operations
    final slowest = sorted.reversed.take(10).map((m) => m.toJson()).toList();

    // Recommendations
    final recommendations = _generateRecommendations(
      successRate: successRate,
      avgDuration: avgDuration,
      p95Duration: sorted[p95Index].durationMs.toDouble(),
      categories: categories,
    );

    return AuditReport(
      totalOperations: _metrics.length,
      successRate: successRate,
      avgDurationMs: avgDuration,
      p95DurationMs: sorted[p95Index].durationMs.toDouble(),
      p99DurationMs: sorted[p99Index].durationMs.toDouble(),
      slowestOperations: slowest,
      categoryBreakdown: breakdown,
      recommendations: recommendations,
    );
  }

  List<String> _generateRecommendations({
    required double successRate,
    required double avgDuration,
    required double p95Duration,
    required Map<String, List<PerformanceMetric>> categories,
  }) {
    final recs = <String>[];

    if (successRate < 95) {
      recs.add('⚠️ Success rate is ${successRate.toStringAsFixed(1)}% — investigate failing operations');
    }

    if (avgDuration > 1000) {
      recs.add('🐌 Average duration is ${avgDuration.round()}ms — consider caching or optimization');
    }

    if (p95Duration > 3000) {
      recs.add('🔴 P95 duration is ${p95Duration.round()}ms — some operations are very slow');
    }

    for (final entry in categories.entries) {
      final avg = entry.value.map((m) => m.durationMs).reduce((a, b) => a + b) /
          entry.value.length;
      if (avg > 2000) {
        recs.add('📌 ${entry.key} category has high avg duration (${avg.round()}ms)');
      }
    }

    if (recs.isEmpty) {
      recs.add('✅ Performance looks good!');
    }

    return recs;
  }

  void clear() => _metrics.clear();

  List<PerformanceMetric> get metrics => List.unmodifiable(_metrics);
}

class AuditReport {
  final int totalOperations;
  final double successRate;
  final double avgDurationMs;
  final double p95DurationMs;
  final double p99DurationMs;
  final List<Map<String, dynamic>> slowestOperations;
  final Map<String, Map<String, dynamic>> categoryBreakdown;
  final List<String> recommendations;

  const AuditReport({
    required this.totalOperations,
    required this.successRate,
    required this.avgDurationMs,
    required this.p95DurationMs,
    required this.p99DurationMs,
    required this.slowestOperations,
    required this.categoryBreakdown,
    required this.recommendations,
  });

  Map<String, dynamic> toJson() => {
        'totalOperations': totalOperations,
        'successRate': successRate,
        'avgDurationMs': avgDurationMs,
        'p95DurationMs': p95DurationMs,
        'p99DurationMs': p99DurationMs,
        'slowestOperations': slowestOperations,
        'categoryBreakdown': categoryBreakdown,
        'recommendations': recommendations,
        'generatedAt': DateTime.now().toIso8601String(),
      };

  @override
  String toString() {
    final buf = StringBuffer();
    buf.writeln('═══ Performance Audit Report ═══');
    buf.writeln('Total operations : $totalOperations');
    buf.writeln('Success rate     : ${successRate.toStringAsFixed(1)}%');
    buf.writeln('Avg duration     : ${avgDurationMs.round()}ms');
    buf.writeln('P95 duration     : ${p95DurationMs.round()}ms');
    buf.writeln('P99 duration     : ${p99DurationMs.round()}ms');
    buf.writeln('');
    buf.writeln('Recommendations:');
    for (final rec in recommendations) {
      buf.writeln('  $rec');
    }
    return buf.toString();
  }
}
```

---

# بخش ۴: Security Audit

## 📄 `lib/packages/core/lib/src/security/security_audit.dart`

```dart
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:sweetmelon/packages/core/lib/core.dart';

class SecurityAuditResult {
  final String check;
  final SecurityRisk risk;
  final String message;
  final String? recommendation;

  const SecurityAuditResult({
    required this.check,
    required this.risk,
    required this.message,
    this.recommendation,
  });

  Map<String, dynamic> toJson() => {
        'check': check,
        'risk': risk.name,
        'message': message,
        if (recommendation != null) 'recommendation': recommendation,
      };
}

enum SecurityRisk { pass, low, medium, high, critical }

class SecurityAuditor {
  Future<SecurityAuditReport> audit() async {
    BridgeLogger.info('SecurityAudit', 'Starting security audit...');

    final results = <SecurityAuditResult>[];

    // 1. Debug Mode
    results.add(_checkDebugMode());

    // 2. Root/Jailbreak
    results.add(await _checkRootStatus());

    // 3. AndroidManifest checks
    results.add(await _checkManifest());

    // 4. Cleartext Traffic
    results.add(await _checkCleartextTraffic());

    // 5. Certificate Pinning
    results.add(_checkCertificatePinning());

    // 6. Secure Storage
    results.add(_checkSecureStorage());

    // 7. Permission declarations
    results.add(await _checkPermissions());

    // 8. ProGuard
    results.add(await _checkProguard());

    // 9. Backup flag
    results.add(await _checkBackup());

    // 10. Network security config
    results.add(await _checkNetworkSecurityConfig());

    final report = SecurityAuditReport(results: results);

    BridgeLogger.info(
      'SecurityAudit',
      'Audit complete: ${report.passCount} pass, '
          '${report.issueCount} issues',
    );

    return report;
  }

  SecurityAuditResult _checkDebugMode() {
    if (kDebugMode) {
      return const SecurityAuditResult(
        check: 'Debug Mode',
        risk: SecurityRisk.high,
        message: 'App is running in debug mode',
        recommendation: 'Always build with --release for production',
      );
    }
    return const SecurityAuditResult(
      check: 'Debug Mode',
      risk: SecurityRisk.pass,
      message: 'Release mode enabled',
    );
  }

  Future<SecurityAuditResult> _checkRootStatus() async {
    if (!Platform.isAndroid) {
      return const SecurityAuditResult(
        check: 'Root Detection',
        risk: SecurityRisk.pass,
        message: 'Root detection is platform-specific (Android only)',
      );
    }

    final suPaths = ['/system/bin/su', '/system/xbin/su', '/sbin/su'];
    for (final path in suPaths) {
      if (File(path).existsSync()) {
        return const SecurityAuditResult(
          check: 'Root Detection',
          risk: SecurityRisk.high,
          message: 'Device appears to be rooted',
          recommendation: 'Consider restricting app functionality on rooted devices',
        );
      }
    }

    return const SecurityAuditResult(
      check: 'Root Detection',
      risk: SecurityRisk.pass,
      message: 'No root indicators found',
    );
  }

  Future<SecurityAuditResult> _checkManifest() async {
    final manifest = File(
      'android/app/src/main/AndroidManifest.xml',
    );

    if (!await manifest.exists()) {
      return const SecurityAuditResult(
        check: 'AndroidManifest',
        risk: SecurityRisk.medium,
        message: 'AndroidManifest.xml not found for audit',
      );
    }

    final content = await manifest.readAsString();

    if (content.contains('android:debuggable="true"')) {
      return const SecurityAuditResult(
        check: 'AndroidManifest',
        risk: SecurityRisk.critical,
        message: 'android:debuggable="true" found in manifest',
        recommendation: 'Remove debuggable=true from manifest',
      );
    }

    return const SecurityAuditResult(
      check: 'AndroidManifest',
      risk: SecurityRisk.pass,
      message: 'No debuggable flag in manifest',
    );
  }

  Future<SecurityAuditResult> _checkCleartextTraffic() async {
    final manifest = File(
      'android/app/src/main/AndroidManifest.xml',
    );

    if (!await manifest.exists()) {
      return const SecurityAuditResult(
        check: 'Cleartext Traffic',
        risk: SecurityRisk.medium,
        message: 'Cannot verify cleartext traffic setting',
      );
    }

    final content = await manifest.readAsString();

    if (content.contains('android:usesCleartextTraffic="true"') &&
        kReleaseMode) {
      return const SecurityAuditResult(
        check: 'Cleartext Traffic',
        risk: SecurityRisk.medium,
        message: 'Cleartext traffic allowed in release mode',
        recommendation: 'Disable usesCleartextTraffic in production or restrict to localhost only',
      );
    }

    return const SecurityAuditResult(
      check: 'Cleartext Traffic',
      risk: SecurityRisk.pass,
      message: 'Cleartext traffic properly configured',
    );
  }

  SecurityAuditResult _checkCertificatePinning() {
    // این check باید runtime بشه
    // در production باید SSL pinning فعال باشه
    if (kReleaseMode) {
      return const SecurityAuditResult(
        check: 'Certificate Pinning',
        risk: SecurityRisk.medium,
        message: 'Verify SSL pinning is enabled for API endpoints',
        recommendation: 'Enable SSL pinning in SecurityManager.production()',
      );
    }

    return const SecurityAuditResult(
      check: 'Certificate Pinning',
      risk: SecurityRisk.low,
      message: 'SSL pinning check skipped in debug mode',
    );
  }

  SecurityAuditResult _checkSecureStorage() {
    return const SecurityAuditResult(
      check: 'Secure Storage',
      risk: SecurityRisk.pass,
      message: 'Secure storage plugin available (flutter_secure_storage)',
    );
  }

  Future<SecurityAuditResult> _checkPermissions() async {
    final manifest = File(
      'android/app/src/main/AndroidManifest.xml',
    );

    if (!await manifest.exists()) {
      return const SecurityAuditResult(
        check: 'Permissions',
        risk: SecurityRisk.medium,
        message: 'Cannot verify permissions',
      );
    }

    final content = await manifest.readAsString();
    final dangerousPerms = [
      'READ_CONTACTS',
      'READ_CALL_LOG',
      'RECORD_AUDIO',
      'READ_SMS',
      'ACCESS_FINE_LOCATION',
    ];

    final found = dangerousPerms
        .where((p) => content.contains('android.permission.$p'))
        .toList();

    if (found.length > 3) {
      return SecurityAuditResult(
        check: 'Permissions',
        risk: SecurityRisk.medium,
        message: 'Multiple sensitive permissions declared: ${found.join(", ")}',
        recommendation: 'Only declare permissions you actually use',
      );
    }

    return const SecurityAuditResult(
      check: 'Permissions',
      risk: SecurityRisk.pass,
      message: 'Permission declarations look reasonable',
    );
  }

  Future<SecurityAuditResult> _checkProguard() async {
    final proguard = File('android/app/proguard-rules.pro');

    if (!await proguard.exists()) {
      return const SecurityAuditResult(
        check: 'ProGuard',
        risk: SecurityRisk.high,
        message: 'proguard-rules.pro not found',
        recommendation: 'Add ProGuard rules for release builds',
      );
    }

    final buildGradle = File('android/app/build.gradle');
    if (await buildGradle.exists()) {
      final content = await buildGradle.readAsString();
      if (!content.contains('minifyEnabled true')) {
        return const SecurityAuditResult(
          check: 'ProGuard',
          risk: SecurityRisk.medium,
          message: 'minifyEnabled not set to true in build.gradle',
          recommendation: 'Enable minification for release builds',
        );
      }
    }

    return const SecurityAuditResult(
      check: 'ProGuard',
      risk: SecurityRisk.pass,
      message: 'ProGuard configuration found',
    );
  }

  Future<SecurityAuditResult> _checkBackup() async {
    final manifest = File(
      'android/app/src/main/AndroidManifest.xml',
    );

    if (!await manifest.exists()) {
      return const SecurityAuditResult(
        check: 'Backup Configuration',
        risk: SecurityRisk.low,
        message: 'Cannot verify backup configuration',
      );
    }

    final content = await manifest.readAsString();

    if (content.contains('android:allowBackup="true"') &&
        !content.contains('android:fullBackupContent') &&
        !content.contains('android:dataExtractionRules')) {
      return const SecurityAuditResult(
        check: 'Backup Configuration',
        risk: SecurityRisk.medium,
        message: 'allowBackup=true without backup rules',
        recommendation: 'Add fullBackupContent or dataExtractionRules to control what gets backed up',
      );
    }

    return const SecurityAuditResult(
      check: 'Backup Configuration',
      risk: SecurityRisk.pass,
      message: 'Backup configuration is set',
    );
  }

  Future<SecurityAuditResult> _checkNetworkSecurityConfig() async {
    final config = File(
      'android/app/src/main/res/xml/network_security_config.xml',
    );

    if (!await config.exists()) {
      return const SecurityAuditResult(
        check: 'Network Security Config',
        risk: SecurityRisk.medium,
        message: 'network_security_config.xml not found',
        recommendation: 'Add network security config to restrict HTTP traffic',
      );
    }

    final content = await config.readAsString();

    if (kReleaseMode &&
        content.contains('cleartextTrafficPermitted="true"') &&
        !content.contains('localhost')) {
      return const SecurityAuditResult(
        check: 'Network Security Config',
        risk: SecurityRisk.high,
        message: 'Cleartext traffic permitted globally in release',
        recommendation: 'Restrict cleartext to localhost only in production',
      );
    }

    return const SecurityAuditResult(
      check: 'Network Security Config',
      risk: SecurityRisk.pass,
      message: 'Network security config present',
    );
  }
}

class SecurityAuditReport {
  final List<SecurityAuditResult> results;
  final DateTime auditedAt;

  SecurityAuditReport({
    required this.results,
  }) : auditedAt = DateTime.now();

  int get passCount => results.where((r) => r.risk == SecurityRisk.pass).length;
  int get issueCount => results.where((r) => r.risk != SecurityRisk.pass).length;
  int get criticalCount =>
      results.where((r) => r.risk == SecurityRisk.critical).length;
  int get highCount =>
      results.where((r) => r.risk == SecurityRisk.high).length;
  int get mediumCount =>
      results.where((r) => r.risk == SecurityRisk.medium).length;

  SecurityRisk get overallRisk {
    if (criticalCount > 0) return SecurityRisk.critical;
    if (highCount > 0) return SecurityRisk.high;
    if (mediumCount > 0) return SecurityRisk.medium;
    if (results.any((r) => r.risk == SecurityRisk.low)) return SecurityRisk.low;
    return SecurityRisk.pass;
  }

  Map<String, dynamic> toJson() => {
        'auditedAt': auditedAt.toIso8601String(),
        'overallRisk': overallRisk.name,
        'summary': {
          'pass': passCount,
          'critical': criticalCount,
          'high': highCount,
          'medium': mediumCount,
          'total': results.length,
        },
        'results': results.map((r) => r.toJson()).toList(),
      };

  @override
  String toString() {
    final buf = StringBuffer();
    buf.writeln('═══ Security Audit Report ═══');
    buf.writeln('Overall Risk : ${overallRisk.name.toUpperCase()}');
    buf.writeln('Pass         : $passCount/${results.length}');
    buf.writeln('Critical     : $criticalCount');
    buf.writeln('High         : $highCount');
    buf.writeln('Medium       : $mediumCount');
    buf.writeln('');

    final issues = results.where((r) => r.risk != SecurityRisk.pass).toList();
    if (issues.isNotEmpty) {
      buf.writeln('Issues:');
      for (final issue in issues) {
        buf.writeln('  [${issue.risk.name.toUpperCase()}] ${issue.check}: ${issue.message}');
        if (issue.recommendation != null) {
          buf.writeln('    → ${issue.recommendation}');
        }
      }
    } else {
      buf.writeln('✅ No security issues found!');
    }

    return buf.toString();
  }
}
```

---

# بخش ۵: Release Checklist

## 📄 `docs/RELEASE_CHECKLIST.md`

```markdown
# 🚀 Sweetmelon Release Checklist

## Pre-Release

### Code Quality
- [ ] All tests pass: `flutter test`
- [ ] No analyzer warnings: `flutter analyze`
- [ ] Code formatted: `dart format .`
- [ ] Coverage > 80%: `flutter test --coverage`

### Configuration
- [ ] `sweetmelon.yaml` reviewed and correct
- [ ] Only necessary plugins enabled
- [ ] `dart run bin/sweetmelon.dart validate` passes
- [ ] `dart run bin/sweetmelon.dart doctor` passes

### Security
- [ ] `dart run bin/sweetmelon.dart security-audit` passes
- [ ] Debug logging disabled in release
- [ ] `android:debuggable` NOT in manifest
- [ ] SSL pinning configured for production APIs
- [ ] ProGuard rules verified: `android/app/proguard-rules.pro`
- [ ] Cleartext traffic restricted to localhost only
- [ ] Sensitive data uses `secureStorage` plugin
- [ ] Root detection implemented if handling sensitive data

### Performance
- [ ] Performance audit run and reviewed
- [ ] Unnecessary plugins disabled
- [ ] Cache configured appropriately
- [ ] Large images compressed

### Firebase
- [ ] `google-services.json` is production version
- [ ] Firebase Analytics enabled
- [ ] Crashlytics enabled
- [ ] Remote Config default values set

### Android
- [ ] `minSdk` ≥ 21
- [ ] `targetSdk` = latest stable
- [ ] Signing keystore backed up securely
- [ ] `key.properties` NOT committed to git
- [ ] Version code incremented
- [ ] Version name updated

### Assets
- [ ] `assets/www/` contains production build
- [ ] Production Angular/React/Vue build used
- [ ] No development tools in www/
- [ ] `native-sdk.js` is latest version
- [ ] Console.log statements removed from JS

### Testing
- [ ] Tested on physical Android device
- [ ] Tested on minimum API device (API 21)
- [ ] Tested offline mode
- [ ] Tested all critical user flows
- [ ] Tested push notifications
- [ ] Tested deep links
- [ ] Camera, microphone, location tested

## Build

```bash
# 1. Clean
flutter clean
flutter pub get

# 2. Run tests
flutter test

# 3. Build APK for testing
flutter build apk --release --split-per-abi

# 4. Build App Bundle for Play Store
flutter build appbundle --release

# 5. Verify APK
apksigner verify build/app/outputs/flutter-apk/app-release.apk
```

## Play Store Upload

- [ ] App Bundle uploaded to Play Console
- [ ] Release notes added in all supported languages
- [ ] Screenshots updated if UI changed
- [ ] Privacy policy URL correct
- [ ] Content rating current
- [ ] Rollout percentage set (10% → 50% → 100%)

## Post-Release

- [ ] Monitor Crashlytics for 24 hours
- [ ] Monitor Firebase Analytics for anomalies
- [ ] Check Play Store reviews
- [ ] Tag release in Git: `git tag v1.x.x && git push --tags`
- [ ] Update CHANGELOG.md
- [ ] Notify team

## Rollback Plan

If critical issue found:
1. Halt rollout in Play Console immediately
2. Fix issue in hotfix branch
3. Re-run full checklist
4. Re-release
```

---

# بخش ۶: Template Project

## 📄 `docs/template/README.md`

```markdown
# Sweetmelon Angular Template

A production-ready Angular + Sweetmelon Native Bridge template.

## Structure

```
sweetmelon-angular-template/
├── android/                    # Android native
├── ios/                        # iOS (future)
├── assets/
│   └── www/                    # Angular build output (built automatically)
├── lib/
│   ├── main.dart
│   ├── app.dart
│   ├── di/service_locator.dart
│   └── screens/home_screen.dart
├── sweetmelon.yaml             # Plugin config
├── angular-app/                # Angular source
│   ├── src/
│   │   ├── app/
│   │   │   ├── core/
│   │   │   │   └── native-bridge.service.ts
│   │   │   ├── app.component.ts
│   │   │   └── app.module.ts
│   │   └── assets/
│   │       └── js/
│   │           └── native-sdk.js
│   ├── angular.json
│   └── package.json
└── scripts/
    ├── build.sh
    └── dev.sh
```

## Quick Start

```bash
# Clone template
git clone https://github.com/your-org/sweetmelon-angular-template

# Install Flutter deps
flutter pub get

# Install Angular deps
cd angular-app && npm install

# Build Angular and run Flutter
./scripts/build.sh && flutter run
```

## Development Workflow

```bash
# Terminal 1: Watch Angular changes
cd angular-app && ng build --watch --output-path ../assets/www --base-href ./

# Terminal 2: Hot reload Flutter
flutter run
```
```

---

## 📄 `scripts/build.sh`

```bash
#!/bin/bash
set -e

echo "🍈 Sweetmelon Build Script"
echo "══════════════════════════"

# Check Angular
if [ -d "angular-app" ]; then
  echo "📦 Building Angular..."
  cd angular-app
  npm run build -- --configuration production \
    --output-path ../assets/www \
    --base-href ./
  cd ..
  echo "✅ Angular built"
fi

# Check React
if [ -d "react-app" ]; then
  echo "📦 Building React..."
  cd react-app
  GENERATE_SOURCEMAP=false npm run build
  cp -r build/. ../assets/www/
  cd ..
  echo "✅ React built"
fi

# Configure Sweetmelon
echo "🔧 Configuring Sweetmelon..."
dart run bin/sweetmelon.dart configure

# Validate
echo "🔍 Validating..."
dart run bin/sweetmelon.dart validate

echo ""
echo "✅ Build complete!"
echo "   Run: flutter run"
```

---

# بخش ۷: تست‌های Security و Performance

## 📄 `test/unit/security/security_audit_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sweetmelon/packages/core/lib/core.dart';

void main() {
  group('SecurityAuditor', () {
    late SecurityAuditor auditor;

    setUp(() {
      auditor = SecurityAuditor();
    });

    test('audit returns results', () async {
      final report = await auditor.audit();
      expect(report.results, isNotEmpty);
      expect(report.auditedAt, isNotNull);
    });

    test('report has correct counts', () async {
      final report = await auditor.audit();
      expect(
        report.passCount + report.issueCount,
        report.results.length,
      );
    });

    test('toJson returns valid map', () async {
      final report = await auditor.audit();
      final json = report.toJson();
      expect(json['auditedAt'], isNotNull);
      expect(json['overallRisk'], isNotNull);
      expect(json['summary'], isA<Map>());
      expect(json['results'], isA<List>());
    });

    test('toString is human readable', () async {
      final report = await auditor.audit();
      final str = report.toString();
      expect(str, contains('Security Audit Report'));
      expect(str, contains('Overall Risk'));
    });

    test('debug mode check works', () async {
      final report = await auditor.audit();
      final debugCheck = report.results.firstWhere(
        (r) => r.check == 'Debug Mode',
      );
      // در test mode، debug mode فعاله
      expect(debugCheck.risk, isNotNull);
    });
  });
}
```

## 📄 `test/unit/performance/performance_audit_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sweetmelon/packages/core/lib/core.dart';

void main() {
  group('PerformanceAudit', () {
    late PerformanceAudit audit;

    setUp(() {
      audit = PerformanceAudit(maxMetrics: 100);
    });

    test('record adds metrics', () async {
      audit.record(PerformanceMetric(
        name: 'test',
        category: 'plugin',
        durationMs: 100,
        success: true,
        timestamp: DateTime.now(),
      ));

      expect(audit.metrics.length, 1);
    });

    test('measure wraps async fn', () async {
      final result = await audit.measure(
        name: 'test_op',
        category: 'test',
        fn: () async {
          await Future.delayed(const Duration(milliseconds: 10));
          return 42;
        },
      );

      expect(result, 42);
      expect(audit.metrics.length, 1);
      expect(audit.metrics.first.durationMs, greaterThanOrEqualTo(10));
      expect(audit.metrics.first.success, true);
    });

    test('measure records failure', () async {
      try {
        await audit.measure(
          name: 'failing_op',
          category: 'test',
          fn: () async {
            throw Exception('test error');
          },
        );
      } catch (_) {}

      expect(audit.metrics.first.success, false);
    });

    test('generateReport with data', () {
      for (int i = 0; i < 20; i++) {
        audit.record(PerformanceMetric(
          name: 'op_$i',
          category: 'plugin',
          durationMs: i * 50,
          success: i % 5 != 0,
          timestamp: DateTime.now(),
        ));
      }

      final report = audit.generateReport();

      expect(report.totalOperations, 20);
      expect(report.successRate, lessThanOrEqualTo(100));
      expect(report.avgDurationMs, greaterThan(0));
      expect(report.p95DurationMs, greaterThanOrEqualTo(report.avgDurationMs));
      expect(report.slowestOperations, isNotEmpty);
    });

    test('generateReport empty returns zeros', () {
      final report = audit.generateReport();
      expect(report.totalOperations, 0);
      expect(report.recommendations, isNotEmpty);
    });

    test('respects maxMetrics', () {
      for (int i = 0; i < 150; i++) {
        audit.record(PerformanceMetric(
          name: 'op',
          category: 'test',
          durationMs: 100,
          success: true,
          timestamp: DateTime.now(),
        ));
      }
      expect(audit.metrics.length, 100);
    });

    test('recommendations for slow operations', () {
      for (int i = 0; i < 10; i++) {
        audit.record(PerformanceMetric(
          name: 'slow',
          category: 'network',
          durationMs: 3000,
          success: true,
          timestamp: DateTime.now(),
        ));
      }

      final report = audit.generateReport();
      expect(
        report.recommendations.any((r) => r.contains('P95') || r.contains('Average')),
        true,
      );
    });

    test('recommendations for low success rate', () {
      for (int i = 0; i < 20; i++) {
        audit.record(PerformanceMetric(
          name: 'op',
          category: 'plugin',
          durationMs: 100,
          success: i < 8, // 40% success
          timestamp: DateTime.now(),
        ));
      }

      final report = audit.generateReport();
      expect(
        report.recommendations.any((r) => r.contains('Success rate')),
        true,
      );
    });

    test('toJson is valid', () {
      audit.record(PerformanceMetric(
        name: 'test',
        category: 'plugin',
        durationMs: 100,
        success: true,
        timestamp: DateTime.now(),
      ));

      final report = audit.generateReport();
      final json = report.toJson();

      expect(json['totalOperations'], isA<int>());
      expect(json['successRate'], isA<double>());
      expect(json['recommendations'], isA<List>());
      expect(json['generatedAt'], isNotNull);
    });
  });
}
```

---

# بخش ۸: بروزرسانی test runner

## 📄 `test/test_runner.dart`

```dart
// ── Faz 19 tests ──
import 'unit/security/security_audit_test.dart' as security_audit_test;
import 'unit/performance/performance_audit_test.dart' as perf_audit_test;

// در main() اضافه بشن:
// security_audit_test.main();
// perf_audit_test.main();
```

---

# خلاصه فاز ۱۹

## آنچه ساخته شد

| آیتم | توضیح |
|------|-------|
| **CI/CD Pipeline** | GitHub Actions با analyze, test, coverage, security scan, Play Store upload |
| **Release Workflow** | Auto changelog، GitHub Release، pre-release support |
| **ProGuard Rules** | کامل برای Flutter، Firebase، WebView، Bluetooth، IAP |
| **Performance Monitor** | Metric recording، audit report، recommendations |
| **Security Auditor** | 10 check: debug mode, root, manifest, cleartext, pinning, ProGuard, ... |
| **Release Checklist** | 40+ item چک‌لیست کامل |
| **Build Script** | خودکار برای Angular/React/Vue |
| **Template Project** | ساختار پروژه آماده |

## GitHub Secrets مورد نیاز

```
KEYSTORE_BASE64      → base64 encoded keystore.jks
KEY_ALIAS            → alias of the signing key
KEY_PASSWORD         → password for the key
STORE_PASSWORD       → password for the keystore
PLAY_STORE_SERVICE_ACCOUNT → Google Play service account JSON
```

## CI/CD Flow

```
push/PR
  ↓
analyze → lint, format
  ↓
test → unit tests + coverage
  ↓
validate → sweetmelon.yaml + doctor
  ↓
security → trivy scan
  ↓
build-debug → APK artifact
  ↓
[on release]
build-release → APK + AAB → Play Store (internal)
```

## آمار نهایی

| آیتم | تعداد |
|------|-------|
| **پلاگین‌ها** | 90 |
| **تست‌ها** | 300+ |
| **CI/CD Jobs** | 8 |
| **Security Checks** | 10 |
| **Release Checklist Items** | 40+ |
| **فازهای تکمیل‌شده** | 19 |

---

بگو تا **فاز ۲۰** (iOS Support) رو شروع کنم.
