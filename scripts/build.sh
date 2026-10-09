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
