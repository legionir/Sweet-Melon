#!/bin/bash
set -e

echo "🍈 Sweetmelon Project Assembler"
echo "════════════════════════════════"
echo ""
echo "This script helps you verify your project structure."
echo ""

# بررسی ساختار
REQUIRED_DIRS=(
  "lib/packages/core/lib/src/bridge"
  "lib/packages/core/lib/src/protocol"
  "lib/packages/core/lib/src/runtime"
  "lib/packages/core/lib/src/utils"
  "lib/packages/core/lib/src/middleware"
  "lib/packages/core/lib/src/security"
  "lib/packages/core/lib/src/performance"
  "lib/packages/plugin_engine/lib/src"
  "lib/packages/security/lib/src"
  "lib/packages/performance/lib/src"
  "lib/packages/devtools/lib/src"
  "lib/di"
  "lib/screens"
  "assets/www/js"
  "assets/www/css"
)

echo "📁 Checking directory structure..."
MISSING=0
for dir in "${REQUIRED_DIRS[@]}"; do
  if [ -d "$dir" ]; then
    echo "  ✅ $dir"
  else
    echo "  ❌ $dir (MISSING)"
    MISSING=$((MISSING + 1))
  fi
done

echo ""

# بررسی فایل‌های ضروری
REQUIRED_FILES=(
  "pubspec.yaml"
  "sweetmelon.yaml"
  "lib/main.dart"
  "lib/app.dart"
  "lib/di/service_locator.dart"
  "lib/packages/core/lib/core.dart"
  "lib/packages/core/lib/src/bridge/message_bridge.dart"
  "lib/packages/core/lib/src/protocol/message_protocol.dart"
  "lib/packages/core/lib/src/protocol/plugin_error_handler.dart"
  "lib/packages/core/lib/src/runtime/webview_host.dart"
  "lib/packages/core/lib/src/runtime/asset_server.dart"
  "lib/packages/core/lib/src/runtime/app_context.dart"
  "lib/packages/core/lib/src/utils/logger.dart"
  "lib/packages/core/lib/src/security/security_manager.dart"
  "lib/packages/plugin_engine/lib/plugin_engine.dart"
  "lib/packages/plugin_engine/lib/src/plugin_interface.dart"
  "lib/packages/plugin_engine/lib/src/plugin_base.dart"
  "lib/packages/plugin_engine/lib/src/plugin_registry.dart"
  "lib/packages/plugin_engine/lib/src/plugin_manager.dart"
  "lib/packages/plugin_engine/lib/src/lazy_plugin_loader.dart"
  "lib/packages/security/lib/src/permission_manager.dart"
  "lib/packages/security/lib/src/rate_limiter.dart"
  "lib/packages/security/lib/src/execution_guard.dart"
  "lib/packages/performance/lib/src/cache_manager.dart"
  "assets/www/index.html"
  "assets/www/js/native-sdk.js"
  "android/app/src/main/AndroidManifest.xml"
)

echo "📄 Checking required files..."
for file in "${REQUIRED_FILES[@]}"; do
  if [ -f "$file" ]; then
    echo "  ✅ $file"
  else
    echo "  ❌ $file (MISSING)"
    MISSING=$((MISSING + 1))
  fi
done

echo ""

# بررسی پلاگین‌ها
echo "🔌 Checking plugins..."
PLUGIN_COUNT=0
for dir in lib/plugins/*/; do
  if [ -d "$dir" ]; then
    PLUGIN_NAME=$(basename "$dir")
    DART_FILE="$dir/lib/${PLUGIN_NAME}_plugin.dart"
    
    if [ -f "$DART_FILE" ]; then
      echo "  ✅ $PLUGIN_NAME"
      PLUGIN_COUNT=$((PLUGIN_COUNT + 1))
    else
      # بعضی پلاگین‌ها اسم فایل متفاوت دارن
      DART_FILES=$(find "$dir/lib" -name "*.dart" 2>/dev/null | head -1)
      if [ -n "$DART_FILES" ]; then
        echo "  ✅ $PLUGIN_NAME ($(basename $DART_FILES))"
        PLUGIN_COUNT=$((PLUGIN_COUNT + 1))
      else
        echo "  ❌ $PLUGIN_NAME (no dart file)"
        MISSING=$((MISSING + 1))
      fi
    fi
  fi
done

echo ""

# بررسی تست‌ها
echo "🧪 Checking tests..."
TEST_COUNT=$(find test -name "*_test.dart" 2>/dev/null | wc -l)
echo "  Found $TEST_COUNT test files"

echo ""
echo "═══════════════════════════════"
echo "Summary:"
echo "  Plugins found: $PLUGIN_COUNT"
echo "  Test files: $TEST_COUNT"
echo "  Missing items: $MISSING"

if [ $MISSING -eq 0 ]; then
  echo ""
  echo "✅ Project structure looks complete!"
  echo ""
  echo "Next: flutter pub get && flutter run"
else
  echo ""
  echo "⚠️  $MISSING items missing. Review and fix before running."
fi
