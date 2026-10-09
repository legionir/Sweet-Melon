بله، هر دو گزینه عالی هستن ولی برای کارهای متفاوت:

---

# مقایسه ابزارهای Documentation

| معیار | VitePress | dart doc | Docusaurus | GitBook |
|-------|-----------|---------|------------|---------|
| **هدف** | مستندات عمومی + API + راهنما | فقط Dart API reference | مستندات عمومی | مستندات ساده |
| **زبان** | Markdown + Vue | از کد Dart تولید | Markdown + React | Markdown |
| **سرعت** | خیلی سریع | سریع | سریع | متوسط |
| **سفارشی‌سازی** | زیاد | کم | زیاد | کم |
| **جستجو** | built-in | built-in | Algolia | built-in |
| **Deploy** | GitHub Pages / Vercel | هر جا | GitHub Pages | GitBook.com |
| **مناسب برای** | کل پروژه ✅ | فقط Dart code | کل پروژه | مستندات ساده |
| **Multi-language** | ✅ | ❌ | ✅ | ✅ |
| **Versioning** | ✅ | ❌ | ✅ | ✅ |

## پیشنهاد من

```
VitePress → سایت اصلی مستندات (Guide, Plugins, API, Examples)
dart doc  → فقط API reference خودکار از Dart code
```

---

# ساختار Documentation Site کامل

```
docs/
├── .vitepress/
│   ├── config.ts              ← تنظیمات VitePress
│   └── theme/
│       ├── index.ts           ← تم سفارشی
│       ├── Layout.vue         ← لایوت
│       └── style.css          ← استایل
├── public/
│   ├── logo.svg
│   ├── og-image.png
│   └── favicon.ico
├── index.md                   ← صفحه اصلی
├── guide/
│   ├── introduction.md
│   ├── getting-started.md
│   ├── installation.md
│   ├── configuration.md
│   ├── project-structure.md
│   ├── how-it-works.md
│   └── frameworks/
│       ├── angular.md
│       ├── react.md
│       ├── vue.md
│       └── vanilla.md
├── plugins/
│   ├── overview.md
│   ├── core/
│   │   ├── permission.md
│   │   ├── app-lifecycle.md
│   │   ├── device-info.md
│   │   ├── connectivity.md
│   │   ├── storage.md
│   │   ├── file-system.md
│   │   ├── http.md
│   │   ├── intent.md
│   │   ├── clipboard.md
│   │   └── share.md
│   ├── media/
│   │   ├── camera.md
│   │   ├── camera-preview.md
│   │   ├── audio.md
│   │   ├── video-player.md
│   │   ├── qr-scanner.md
│   │   └── document-scanner.md
│   ├── ui/
│   │   ├── dialog.md
│   │   ├── toast.md
│   │   ├── action-sheet.md
│   │   ├── date-picker.md
│   │   ├── status-bar.md
│   │   ├── navigation-bar.md
│   │   ├── orientation.md
│   │   ├── splash-screen.md
│   │   └── text-zoom.md
│   ├── device/
│   │   ├── geolocation.md
│   │   ├── sensors.md
│   │   ├── bluetooth.md
│   │   ├── nfc.md
│   │   ├── biometrics.md
│   │   └── contacts.md
│   ├── storage/
│   │   ├── secure-storage.md
│   │   ├── database.md
│   │   ├── file-picker.md
│   │   ├── file-compressor.md
│   │   └── zip.md
│   ├── network/
│   │   ├── websocket.md
│   │   ├── download-manager.md
│   │   └── wifi-manager.md
│   ├── security/
│   │   ├── encryption.md
│   │   ├── root-detection.md
│   │   ├── app-integrity.md
│   │   └── privacy-screen.md
│   ├── firebase/
│   │   ├── analytics.md
│   │   ├── crashlytics.md
│   │   ├── auth.md
│   │   ├── remote-config.md
│   │   └── push-notification.md
│   └── advanced/
│       ├── live-updater.md
│       ├── background-task.md
│       ├── in-app-purchase.md
│       ├── oauth2.md
│       ├── social-login.md
│       └── google-maps.md
├── api/
│   ├── native-sdk.md
│   ├── native-resilience.md
│   ├── events.md
│   └── typescript.md
├── advanced/
│   ├── security.md
│   ├── performance.md
│   ├── error-handling.md
│   ├── offline-support.md
│   ├── plugin-development.md
│   └── migration.md
├── cli/
│   ├── overview.md
│   ├── commands.md
│   └── plugin-manager.md
├── deployment/
│   ├── android.md
│   ├── play-store.md
│   ├── proguard.md
│   └── release-checklist.md
├── examples/
│   ├── angular-crud.md
│   ├── react-todo.md
│   ├── offline-first.md
│   └── ecommerce.md
├── changelog.md
└── contributing.md
```

---

# پیاده‌سازی

## مرحله ۱: Setup VitePress

```bash
# ایجاد پوشه docs
cd sweetmelon
mkdir docs && cd docs

# نصب VitePress
npm init -y
npm install -D vitepress vue
```

---

## 📄 `docs/package.json`

```json
{
  "name": "sweetmelon-docs",
  "version": "1.0.0",
  "private": true,
  "scripts": {
    "dev": "vitepress dev",
    "build": "vitepress build",
    "preview": "vitepress preview",
    "deploy": "vitepress build && gh-pages -d .vitepress/dist"
  },
  "devDependencies": {
    "vitepress": "^1.4.0",
    "vue": "^3.5.0",
    "gh-pages": "^6.2.0"
  }
}
```

---

## 📄 `docs/.vitepress/config.ts`

```typescript
import { defineConfig } from 'vitepress';

export default defineConfig({
  title: 'Sweetmelon',
  description: 'Flutter Native Bridge — Run HTML apps with 91 native plugins',
  
  // SEO
  lang: 'en-US',
  head: [
    ['link', { rel: 'icon', href: '/favicon.ico' }],
    ['meta', { property: 'og:type', content: 'website' }],
    ['meta', { property: 'og:title', content: 'Sweetmelon — Flutter Native Bridge' }],
    ['meta', { property: 'og:description', content: 'Run Angular/React/Vue inside Flutter with 91 native plugins' }],
    ['meta', { property: 'og:image', content: '/og-image.png' }],
    ['meta', { name: 'twitter:card', content: 'summary_large_image' }],
  ],

  // Sitemap
  sitemap: {
    hostname: 'https://sweetmelon.dev',
  },

  // Theme
  themeConfig: {
    logo: '/logo.svg',
    siteTitle: 'Sweetmelon',
    
    // Search
    search: {
      provider: 'local',
      options: {
        detailedView: true,
      },
    },

    // Top Nav
    nav: [
      { text: 'Guide', link: '/guide/introduction' },
      { text: 'Plugins', link: '/plugins/overview' },
      { text: 'API', link: '/api/native-sdk' },
      { text: 'CLI', link: '/cli/overview' },
      { text: 'Examples', link: '/examples/angular-crud' },
      {
        text: 'v1.0.0',
        items: [
          { text: 'Changelog', link: '/changelog' },
          { text: 'Contributing', link: '/contributing' },
        ],
      },
    ],

    // Sidebar
    sidebar: {
      '/guide/': [
        {
          text: 'Getting Started',
          items: [
            { text: 'Introduction', link: '/guide/introduction' },
            { text: 'Getting Started', link: '/guide/getting-started' },
            { text: 'Installation', link: '/guide/installation' },
            { text: 'Configuration', link: '/guide/configuration' },
            { text: 'Project Structure', link: '/guide/project-structure' },
            { text: 'How It Works', link: '/guide/how-it-works' },
          ],
        },
        {
          text: 'Framework Integration',
          items: [
            { text: 'Angular', link: '/guide/frameworks/angular' },
            { text: 'React', link: '/guide/frameworks/react' },
            { text: 'Vue', link: '/guide/frameworks/vue' },
            { text: 'Vanilla JS', link: '/guide/frameworks/vanilla' },
          ],
        },
      ],

      '/plugins/': [
        {
          text: 'Overview',
          items: [
            { text: 'All Plugins', link: '/plugins/overview' },
          ],
        },
        {
          text: 'Core',
          collapsed: false,
          items: [
            { text: 'Permission', link: '/plugins/core/permission' },
            { text: 'App Lifecycle', link: '/plugins/core/app-lifecycle' },
            { text: 'Device Info', link: '/plugins/core/device-info' },
            { text: 'Connectivity', link: '/plugins/core/connectivity' },
            { text: 'Storage', link: '/plugins/core/storage' },
            { text: 'File System', link: '/plugins/core/file-system' },
            { text: 'HTTP', link: '/plugins/core/http' },
            { text: 'Intent / Deep Link', link: '/plugins/core/intent' },
            { text: 'Clipboard', link: '/plugins/core/clipboard' },
            { text: 'Share', link: '/plugins/core/share' },
          ],
        },
        {
          text: 'Media',
          collapsed: true,
          items: [
            { text: 'Camera', link: '/plugins/media/camera' },
            { text: 'Camera Preview', link: '/plugins/media/camera-preview' },
            { text: 'Audio', link: '/plugins/media/audio' },
            { text: 'Video Player', link: '/plugins/media/video-player' },
            { text: 'QR Scanner', link: '/plugins/media/qr-scanner' },
            { text: 'Document Scanner', link: '/plugins/media/document-scanner' },
          ],
        },
        {
          text: 'UI',
          collapsed: true,
          items: [
            { text: 'Dialog', link: '/plugins/ui/dialog' },
            { text: 'Toast', link: '/plugins/ui/toast' },
            { text: 'Action Sheet', link: '/plugins/ui/action-sheet' },
            { text: 'Date Picker', link: '/plugins/ui/date-picker' },
            { text: 'Status Bar', link: '/plugins/ui/status-bar' },
            { text: 'Navigation Bar', link: '/plugins/ui/navigation-bar' },
            { text: 'Orientation', link: '/plugins/ui/orientation' },
            { text: 'Splash Screen', link: '/plugins/ui/splash-screen' },
            { text: 'Text Zoom', link: '/plugins/ui/text-zoom' },
          ],
        },
        {
          text: 'Device',
          collapsed: true,
          items: [
            { text: 'Geolocation', link: '/plugins/device/geolocation' },
            { text: 'Sensors', link: '/plugins/device/sensors' },
            { text: 'Bluetooth', link: '/plugins/device/bluetooth' },
            { text: 'NFC', link: '/plugins/device/nfc' },
            { text: 'Biometrics', link: '/plugins/device/biometrics' },
            { text: 'Contacts', link: '/plugins/device/contacts' },
          ],
        },
        {
          text: 'Storage & Files',
          collapsed: true,
          items: [
            { text: 'Secure Storage', link: '/plugins/storage/secure-storage' },
            { text: 'Database', link: '/plugins/storage/database' },
            { text: 'File Picker', link: '/plugins/storage/file-picker' },
            { text: 'File Compressor', link: '/plugins/storage/file-compressor' },
            { text: 'Zip', link: '/plugins/storage/zip' },
          ],
        },
        {
          text: 'Network',
          collapsed: true,
          items: [
            { text: 'WebSocket', link: '/plugins/network/websocket' },
            { text: 'Download Manager', link: '/plugins/network/download-manager' },
            { text: 'WiFi', link: '/plugins/network/wifi-manager' },
          ],
        },
        {
          text: 'Security',
          collapsed: true,
          items: [
            { text: 'Encryption', link: '/plugins/security/encryption' },
            { text: 'Root Detection', link: '/plugins/security/root-detection' },
            { text: 'App Integrity', link: '/plugins/security/app-integrity' },
            { text: 'Privacy Screen', link: '/plugins/security/privacy-screen' },
          ],
        },
        {
          text: 'Firebase',
          collapsed: true,
          items: [
            { text: 'Analytics', link: '/plugins/firebase/analytics' },
            { text: 'Crashlytics', link: '/plugins/firebase/crashlytics' },
            { text: 'Auth', link: '/plugins/firebase/auth' },
            { text: 'Remote Config', link: '/plugins/firebase/remote-config' },
            { text: 'Push Notifications', link: '/plugins/firebase/push-notification' },
          ],
        },
        {
          text: 'Advanced',
          collapsed: true,
          items: [
            { text: 'Live Updater', link: '/plugins/advanced/live-updater' },
            { text: 'Background Task', link: '/plugins/advanced/background-task' },
            { text: 'In-App Purchase', link: '/plugins/advanced/in-app-purchase' },
            { text: 'OAuth2', link: '/plugins/advanced/oauth2' },
            { text: 'Social Login', link: '/plugins/advanced/social-login' },
            { text: 'Google Maps', link: '/plugins/advanced/google-maps' },
          ],
        },
      ],

      '/api/': [
        {
          text: 'API Reference',
          items: [
            { text: 'NativeSDK', link: '/api/native-sdk' },
            { text: 'NativeResilience', link: '/api/native-resilience' },
            { text: 'Events', link: '/api/events' },
            { text: 'TypeScript', link: '/api/typescript' },
          ],
        },
      ],

      '/cli/': [
        {
          text: 'CLI',
          items: [
            { text: 'Overview', link: '/cli/overview' },
            { text: 'Commands', link: '/cli/commands' },
            { text: 'Plugin Manager', link: '/cli/plugin-manager' },
          ],
        },
      ],

      '/advanced/': [
        {
          text: 'Advanced',
          items: [
            { text: 'Security', link: '/advanced/security' },
            { text: 'Performance', link: '/advanced/performance' },
            { text: 'Error Handling', link: '/advanced/error-handling' },
            { text: 'Offline Support', link: '/advanced/offline-support' },
            { text: 'Plugin Development', link: '/advanced/plugin-development' },
            { text: 'Migration', link: '/advanced/migration' },
          ],
        },
      ],

      '/deployment/': [
        {
          text: 'Deployment',
          items: [
            { text: 'Android', link: '/deployment/android' },
            { text: 'Play Store', link: '/deployment/play-store' },
            { text: 'ProGuard', link: '/deployment/proguard' },
            { text: 'Release Checklist', link: '/deployment/release-checklist' },
          ],
        },
      ],
    },

    // Footer
    footer: {
      message: 'Released under the MIT License',
      copyright: 'Copyright © 2024 Sweetmelon',
    },

    // Social links
    socialLinks: [
      { icon: 'github', link: 'https://github.com/your-org/sweetmelon' },
      { icon: 'discord', link: 'https://discord.gg/sweetmelon' },
    ],

    // Edit link
    editLink: {
      pattern: 'https://github.com/your-org/sweetmelon/edit/main/docs/:path',
      text: 'Edit this page on GitHub',
    },

    // Last updated
    lastUpdated: {
      text: 'Updated at',
      formatOptions: {
        dateStyle: 'medium',
        timeStyle: 'short',
      },
    },
  },

  // Markdown
  markdown: {
    lineNumbers: true,
    theme: {
      light: 'github-light',
      dark: 'github-dark',
    },
  },
});
```

---

## 📄 `docs/.vitepress/theme/style.css`

```css
:root {
  --vp-c-brand-1: #6C63FF;
  --vp-c-brand-2: #5B54E6;
  --vp-c-brand-3: #4A45CC;
  --vp-c-brand-soft: rgba(108, 99, 255, 0.14);

  --vp-home-hero-name-color: transparent;
  --vp-home-hero-name-background: linear-gradient(135deg, #6C63FF 10%, #03DAC6 100%);

  --vp-home-hero-image-background-image: linear-gradient(135deg, rgba(108,99,255,0.2) 10%, rgba(3,218,198,0.2) 100%);
  --vp-home-hero-image-filter: blur(44px);
}

.dark {
  --vp-c-bg: #0b1120;
  --vp-c-bg-soft: #131f35;
  --vp-c-bg-mute: #1a2a45;
}

/* Plugin badge */
.plugin-badge {
  display: inline-flex;
  align-items: center;
  gap: 4px;
  padding: 2px 8px;
  border-radius: 12px;
  font-size: 12px;
  font-weight: 600;
}

.badge-core { background: rgba(76,175,80,0.15); color: #4CAF50; }
.badge-media { background: rgba(33,150,243,0.15); color: #2196F3; }
.badge-ui { background: rgba(156,39,176,0.15); color: #9C27B0; }
.badge-device { background: rgba(255,152,0,0.15); color: #FF9800; }
.badge-firebase { background: rgba(255,193,7,0.15); color: #FFC107; }
.badge-advanced { background: rgba(244,67,54,0.15); color: #F44336; }

/* API table */
.api-table {
  width: 100%;
  border-collapse: collapse;
}

.api-table th {
  text-align: left;
  padding: 8px 12px;
  border-bottom: 2px solid var(--vp-c-divider);
  font-size: 13px;
  color: var(--vp-c-text-2);
}

.api-table td {
  padding: 8px 12px;
  border-bottom: 1px solid var(--vp-c-divider);
  font-size: 14px;
}

.api-table code {
  font-size: 13px;
}

/* Plugin card grid */
.plugin-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(200px, 1fr));
  gap: 12px;
  margin: 16px 0;
}

.plugin-card {
  border: 1px solid var(--vp-c-divider);
  border-radius: 12px;
  padding: 16px;
  transition: all 0.2s;
}

.plugin-card:hover {
  border-color: var(--vp-c-brand-1);
  box-shadow: 0 4px 12px rgba(108, 99, 255, 0.1);
}

.plugin-card h3 {
  margin: 0 0 4px;
  font-size: 15px;
}

.plugin-card p {
  margin: 0;
  font-size: 13px;
  color: var(--vp-c-text-2);
}
```

---

## 📄 `docs/index.md` — صفحه اصلی

```markdown
---
layout: home

hero:
  name: "Sweetmelon"
  text: "Flutter Native Bridge"
  tagline: Run Angular, React, or Vue apps inside Flutter with 91+ native plugins
  image:
    src: /logo.svg
    alt: Sweetmelon
  actions:
    - theme: brand
      text: Get Started
      link: /guide/getting-started
    - theme: alt
      text: View Plugins
      link: /plugins/overview
    - theme: alt
      text: GitHub
      link: https://github.com/your-org/sweetmelon

features:
  - icon: 🔌
    title: 91 Native Plugins
    details: Camera, GPS, Bluetooth, NFC, Biometrics, Database, Push Notifications, In-App Purchase, and 83 more.
    link: /plugins/overview
    linkText: Browse all plugins

  - icon: ⚡
    title: Zero Latency Bridge
    details: Optimized JSON protocol with batch calls, caching, rate limiting, and circuit breaker.
    link: /advanced/performance

  - icon: 🔒
    title: Security Built-in
    details: Bridge authentication, message signing, SSL pinning, anti-tampering, and encrypted storage.
    link: /advanced/security

  - icon: 📦
    title: Framework Agnostic
    details: Works with Angular, React, Vue, Svelte, or vanilla HTML/JS. Full TypeScript support.
    link: /guide/frameworks/angular

  - icon: 🚀
    title: Live Updates
    details: Deploy HTML/JS changes instantly without Play Store review. Auto-rollback on failures.
    link: /plugins/advanced/live-updater

  - icon: 🔥
    title: Firebase Ready
    details: Analytics, Crashlytics, FCM Push, Remote Config, and Auth — all accessible from JavaScript.
    link: /plugins/firebase/analytics
---

<style>
:root {
  --vp-home-hero-name-color: transparent;
  --vp-home-hero-name-background: linear-gradient(135deg, #6C63FF 10%, #03DAC6 100%);
}
</style>

## Quick Example

```javascript
// Wait for bridge
await NativeSDK.waitForReady();

// Take a photo
const photo = await NativeSDK.camera.takePhoto({ quality: 90 });

// Save to secure storage
await NativeSDK.secureStorage.set('last_photo', photo.path);

// Show toast
await NativeSDK.toast.show('Photo saved! 📸');

// Listen to connectivity
NativeSDK.on('connectivity.change', (data) => {
  console.log('Online:', data.online);
});
```

## Trusted Architecture

```
┌─────────────────────────────────────┐
│     Your HTML/JS/CSS App            │
│  (Angular, React, Vue, vanilla)     │
├─────────────────────────────────────┤
│         NativeSDK (JS)              │
├─────────────────────────────────────┤
│      Message Bridge (Dart)          │
├─────────────────────────────────────┤
│   Security │ Cache │ Rate Limit     │
├─────────────────────────────────────┤
│     91 Native Plugin Registry       │
├─────────────────────────────────────┤
│     Android / iOS Native APIs       │
└─────────────────────────────────────┘
```
```

---

## 📄 `docs/guide/introduction.md`

```markdown
# Introduction

## What is Sweetmelon?

Sweetmelon is a **Flutter-based native bridge** that lets you run HTML/CSS/JS applications (Angular, React, Vue, or vanilla) inside a Flutter WebView while providing access to **91 native device APIs** through a simple JavaScript SDK.

Think of it as an alternative to **Capacitor** or **Cordova**, but built on Flutter's powerful engine.

## Why Sweetmelon?

### vs Capacitor
| Feature | Sweetmelon | Capacitor |
|---------|-----------|-----------|
| Runtime | Flutter | Native Android/iOS |
| Plugins | 91 built-in | ~80 (community) |
| Live Updates | ✅ Built-in | Via Capgo (paid) |
| Security | ✅ 5 layers | Basic |
| Offline Queue | ✅ Built-in | Manual |
| Plugin Dev | Dart | Java/Kotlin + Swift |

### vs React Native / Flutter
| Feature | Sweetmelon | React Native | Pure Flutter |
|---------|-----------|-------------|-------------|
| UI Technology | HTML/CSS/JS | React | Dart/Widgets |
| Learning Curve | Low (web devs) | Medium | High |
| Web Reuse | ✅ 100% | ❌ | ❌ |
| Native Access | 91 plugins | Many packages | Many packages |
| Performance | Good | Very Good | Excellent |

### When to use Sweetmelon

✅ **Use when:**
- You have an existing web app (Angular/React/Vue)
- Your team knows web technologies
- You need quick native features
- You want live updates without store review
- You need offline-first with sync

❌ **Don't use when:**
- You need maximum performance (games, heavy animations)
- You're building from scratch (consider pure Flutter)
- You need advanced native UI components

## Core Concepts

### 1. Bridge
The communication layer between JavaScript and Dart/Native code.

### 2. Plugins
Self-contained modules that expose native APIs to JavaScript.

### 3. NativeSDK
The JavaScript wrapper that provides a clean API for all plugins.

### 4. Asset Server
A local HTTP server that serves your HTML/CSS/JS files to the WebView.

### 5. Security Manager
Authentication, signing, and protection for the bridge communication.

## Architecture

```
Your Web App (Angular/React/Vue)
        ↓
   NativeSDK.call()
        ↓
   Message Bridge (JSON protocol)
        ↓
   Security Layer (auth + signing)
        ↓
   Plugin Manager (cache + rate limit)
        ↓
   Plugin Registry (91 plugins)
        ↓
   Native APIs (Android/iOS)
```
```

---

## 📄 `docs/guide/getting-started.md`

```markdown
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
```

---

## 📄 `docs/plugins/overview.md`

```markdown
# All Plugins

Sweetmelon includes **91 built-in plugins** organized in categories.

## Core (10 plugins) {#core}

Essential plugins for every app.

<div class="plugin-grid">
  <a href="./core/permission" class="plugin-card">
    <h3>🔐 Permission</h3>
    <p>Manage native permissions</p>
  </a>
  <a href="./core/app-lifecycle" class="plugin-card">
    <h3>📱 App Lifecycle</h3>
    <p>App state events</p>
  </a>
  <a href="./core/device-info" class="plugin-card">
    <h3>📋 Device Info</h3>
    <p>Device & app information</p>
  </a>
  <a href="./core/connectivity" class="plugin-card">
    <h3>🌐 Connectivity</h3>
    <p>Network status monitoring</p>
  </a>
  <a href="./core/storage" class="plugin-card">
    <h3>💾 Storage</h3>
    <p>Key-value storage</p>
  </a>
  <a href="./core/file-system" class="plugin-card">
    <h3>📁 File System</h3>
    <p>Read/write files</p>
  </a>
  <a href="./core/http" class="plugin-card">
    <h3>🔗 HTTP</h3>
    <p>Native HTTP client</p>
  </a>
  <a href="./core/intent" class="plugin-card">
    <h3>🔀 Intent</h3>
    <p>URL launcher & deep links</p>
  </a>
  <a href="./core/clipboard" class="plugin-card">
    <h3>📋 Clipboard</h3>
    <p>Copy & paste</p>
  </a>
  <a href="./core/share" class="plugin-card">
    <h3>📤 Share</h3>
    <p>Native share sheet</p>
  </a>
</div>

## Quick Reference

| Plugin | JS Name | Category | Events |
|--------|---------|----------|--------|
| [Permission](./core/permission) | `permission` | Core | — |
| [App Lifecycle](./core/app-lifecycle) | `appLifecycle` | Core | ✅ |
| [Device Info](./core/device-info) | `deviceInfo` | Core | — |
| [Connectivity](./core/connectivity) | `connectivity` | Core | ✅ |
| [Storage](./core/storage) | `storage` | Core | — |
| [File System](./core/file-system) | `fileSystem` | Core | — |
| [HTTP](./core/http) | `http` | Core | — |
| [Intent](./core/intent) | `intent` | Core | ✅ |
| [Clipboard](./core/clipboard) | `clipboard` | Core | — |
| [Share](./core/share) | `share` | Core | — |
| [Camera](./media/camera) | `camera` | Media | — |
| [Camera Preview](./media/camera-preview) | `cameraPreview` | Media | ✅ |
| [Audio](./media/audio) | `audio` | Media | ✅ |
| [Video Player](./media/video-player) | `videoPlayer` | Media | ✅ |
| [QR Scanner](./media/qr-scanner) | `qrScanner` | Media | ✅ |
| [Document Scanner](./media/document-scanner) | `documentScanner` | Media | — |
| ... | ... | ... | ... |

::: tip Total: 91 plugins
Browse each category in the sidebar for complete API documentation.
:::
```

---

## 📄 `docs/api/events.md`

```markdown
# Events Reference

All events that can be listened to via `NativeSDK.on()`.

## How to use

```javascript
// Subscribe
const unsubscribe = NativeSDK.on('event.name', (data) => {
  console.log(data);
});

// Unsubscribe
unsubscribe();
```

## All Events

### App & System

| Event | Plugin | Data | Description |
|-------|--------|------|-------------|
| `app.lifecycle.change` | appLifecycle | `{ state, previousState }` | App state changed |
| `connectivity.change` | connectivity | `{ online, primary, types }` | Network changed |
| `keyboard.change` | keyboard | `{ visible, height }` | Keyboard show/hide |
| `backButton.pressed` | backButton | `{ intercepted }` | Back button pressed |

### Location

| Event | Plugin | Data | Description |
|-------|--------|------|-------------|
| `geolocation.position` | geolocation | Position object | Position update |
| `geolocation.error` | geolocation | `{ message }` | Location error |
| `bgGeo.position` | backgroundGeolocation | Position object | Background position |

### Media

| Event | Plugin | Data | Description |
|-------|--------|------|-------------|
| `audio.playerState` | audio | `{ state, isPlaying }` | Audio state |
| `audio.position` | audio | `{ positionMs }` | Playback position |
| `cameraPreview.photoTaken` | cameraPreview | `{ path, size }` | Photo captured |
| `qrScanner.scanned` | qrScanner | `{ value, format }` | QR/barcode scanned |

### Notifications

| Event | Plugin | Data | Description |
|-------|--------|------|-------------|
| `notification.tap` | notification | `{ id, payload }` | Notification tapped |
| `push.received` | pushNotification | `{ title, body, data }` | Push received |
| `push.tap` | pushNotification | `{ title, body, data }` | Push tapped |
| `push.tokenRefreshed` | pushNotification | `{ token }` | FCM token changed |

### Hardware

| Event | Plugin | Data | Description |
|-------|--------|------|-------------|
| `bluetooth.deviceFound` | bluetooth | `{ deviceId, name, rssi }` | BLE device found |
| `nfc.tagDiscovered` | nfc | `{ id, type, records }` | NFC tag read |
| `sensors.accelerometer` | sensors | `{ x, y, z }` | Accelerometer data |
| `sensors.gyroscope` | sensors | `{ x, y, z }` | Gyroscope data |
| `shake.detected` | shakeDetection | `{ magnitude, count }` | Device shaken |
| `volume.pressed` | volumeButtons | `{ direction }` | Volume button |
| `pedometer.step` | pedometer | `{ steps }` | Step counted |
| `alarm.fired` | alarm | `{ alarmId, title }` | Alarm triggered |

### Network

| Event | Plugin | Data | Description |
|-------|--------|------|-------------|
| `websocket.message` | websocket | `{ id, data, type }` | WS message |
| `websocket.connected` | websocket | `{ id, url }` | WS connected |
| `websocket.disconnected` | websocket | `{ id, closeCode }` | WS disconnected |
| `download.progress` | downloadManager | `{ taskId, percent }` | Download progress |
| `download.complete` | downloadManager | `{ taskId, path }` | Download done |

### Auth & Purchase

| Event | Plugin | Data | Description |
|-------|--------|------|-------------|
| `auth.stateChanged` | firebaseAuth | `{ user, signedIn }` | Auth state |
| `socialLogin.signedIn` | socialLogin | `{ provider, user }` | Social login |
| `purchase.completed` | inAppPurchase | `{ productId }` | Purchase done |
| `purchase.error` | inAppPurchase | `{ errorMessage }` | Purchase failed |

### Updates

| Event | Plugin | Data | Description |
|-------|--------|------|-------------|
| `update.available` | liveUpdater | `{ version, size }` | Update found |
| `update.downloadProgress` | liveUpdater | `{ percent }` | Downloading |
| `update.applied` | liveUpdater | `{ newVersion }` | Update applied |
| `update.rolledBack` | liveUpdater | `{ version }` | Rolled back |

### Tasks

| Event | Plugin | Data | Description |
|-------|--------|------|-------------|
| `task.started` | backgroundTask | `{ taskId }` | Task started |
| `task.completed` | backgroundTask | `{ taskId, result }` | Task done |
| `task.failed` | backgroundTask | `{ taskId, error }` | Task failed |
```

---

## مرحله ۲: dart doc

```bash
# تولید API reference از Dart code
dart doc .

# خروجی در doc/api/
# می‌تونید لینکش رو در VitePress بذارید
```

## 📄 `dartdoc_options.yaml`

```yaml
dartdoc:
  name: 'Sweetmelon'
  description: 'Flutter Native Bridge API Reference'
  
  categories:
    - name: Core
      markdown: doc/categories/core.md
    - name: Plugins
      markdown: doc/categories/plugins.md
    - name: Security
      markdown: doc/categories/security.md
  
  categoryOrder:
    - Core
    - Plugins
    - Security
    
  exclude:
    - 'test/**'
    - 'bin/**'
    
  showUndocumentedCategories: false
```

---

## مرحله ۳: Deploy

```bash
# Build VitePress
cd docs
npm run build

# Deploy to GitHub Pages
npm run deploy

# یا Vercel/Netlify:
# Just connect the docs/ directory
```

## 📄 `.github/workflows/docs.yml`

```yaml
name: Deploy Documentation

on:
  push:
    branches: [main]
    paths:
      - 'docs/**'

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup Node
        uses: actions/setup-node@v4
        with:
          node-version: 20

      - name: Install dependencies
        working-directory: docs
        run: npm install

      - name: Build VitePress
        working-directory: docs
        run: npm run build

      - name: Generate Dart API docs
        run: dart doc . --output docs/.vitepress/dist/dart-api

      - name: Deploy to GitHub Pages
        uses: peaceiris/actions-gh-pages@v3
        with:
          github_token: ${{ secrets.GITHUB_TOKEN }}
          publish_dir: docs/.vitepress/dist
```

---

# خلاصه

## ساختار نهایی

```
VitePress (سایت اصلی):
  / → صفحه اصلی hero
  /guide/ → راهنمای شروع + frameworks
  /plugins/ → 91 plugin docs (دسته‌بندی شده)
  /api/ → JS API reference + events + types
  /cli/ → CLI commands
  /advanced/ → security, performance, errors
  /deployment/ → Android, Play Store, ProGuard
  /examples/ → Angular, React نمونه‌ها

dart doc (API Reference):
  /dart-api/ → Dart classes, methods, types
```

## دستورات

```bash
# توسعه
cd docs && npm run dev       # http://localhost:5173

# Build
cd docs && npm run build     # .vitepress/dist/

# Deploy
cd docs && npm run deploy    # GitHub Pages

# Dart API
dart doc .                   # doc/api/
```
