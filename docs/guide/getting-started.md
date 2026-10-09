# Getting Started

## Prerequisites

- Flutter SDK 3.0+
- Android Studio / VS Code
- Node.js 18+ (for web app build)
- Android device or emulator (API 21+)

## Step 1: Create Project

```bash
# Option A: Use CLI
dart run bin/sweetmelon.dart create project my_app
cd my_app

# Option B: Manual
flutter create --org com.example my_app
cd my_app
# Copy Sweetmelon files...
```

## Step 2: Configure Plugins

Edit `sweetmelon.yaml`:

```yaml
plugins:
  permission:
    enabled: true
  storage:
    enabled: true
  http:
    enabled: true
  # ... enable what you need
```

Apply configuration:

```bash
dart run bin/sweetmelon.dart configure
```

## Step 3: Add Your Web App

Place your built web app in `assets/www/`:

```bash
# Angular
ng build --configuration production \
  --output-path assets/www \
  --base-href ./

# React
GENERATE_SOURCEMAP=false npm run build
cp -r build/* assets/www/

# Vue
npm run build
cp -r dist/* assets/www/

# Vanilla HTML
# Just put files in assets/www/
```

**Important:** Include `native-sdk.js` in your HTML:

```html
<script src="js/native-sdk.js"></script>
```

## Step 4: Use NativeSDK

```javascript
// Wait for bridge to be ready
await NativeSDK.waitForReady();

// Now use any plugin
const info = await NativeSDK.deviceInfo.getAll();
console.log('Device:', info.device.model);

// Store data
await NativeSDK.storage.set('user', { name: 'Ali' });

// Listen to events
NativeSDK.on('connectivity.change', (data) => {
  console.log('Online:', data.online);
});
```

## Step 5: Run

```bash
flutter run
```

## Next Steps

- [Configuration →](/guide/configuration)
- [Browse all 91 plugins →](/plugins/overview)
- [Angular integration →](/guide/frameworks/angular)
- [Security guide →](/advanced/security)
