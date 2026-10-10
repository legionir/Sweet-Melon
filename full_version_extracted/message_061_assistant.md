# بررسی تطبیقی: پلاگین‌های موجود vs لیست Capacitor

---

## ✅ پلاگین‌هایی که قبلاً ساختیم (50 مورد)

| # | ما ساختیم | معادل Capacitor | وضعیت |
|---|-----------|---------------|-------|
| 1 | `permission` | Permission | ✅ کامل |
| 2 | `appLifecycle` | App | ✅ کامل |
| 3 | `deviceInfo` | Device | ✅ کامل |
| 4 | `connectivity` | Network | ✅ کامل |
| 5 | `storage` | Preferences | ✅ کامل |
| 6 | `fileSystem` | File | ✅ کامل |
| 7 | `http` | Http | ✅ کامل |
| 8 | `intent` | Intent Launcher | ✅ کامل |
| 9 | `clipboard` | Clipboard | ✅ کامل |
| 10 | `share` | Share | ✅ کامل |
| 11 | `camera` | Camera | ✅ کامل |
| 12 | `geolocation` | Geolocation | ✅ کامل |
| 13 | `backButton` | — | ✅ کامل |
| 14 | `secureStorage` | Secure Storage | ✅ کامل |
| 15 | `notification` | Local Notifications | ✅ کامل |
| 16 | `statusBar` | Status Bar | ✅ کامل |
| 17 | `orientation` | Screen Orientation | ✅ کامل |
| 18 | `haptic` | Haptics | ✅ کامل |
| 19 | `keyboard` | Keyboard | ✅ کامل |
| 20 | `biometrics` | Native Biometric | ✅ کامل |
| 21 | `qrScanner` | Barcode Scanner | ✅ کامل |
| 22 | `audio` | Audio Recorder | ✅ کامل |
| 23 | `smsOtp` | Read SMS | ✅ کامل |
| 24 | `downloadManager` | Downloader | ✅ کامل |
| 25 | `database` | Data Storage SQLite | ✅ کامل |
| 26 | `contacts` | Contacts | ✅ کامل |
| 27 | `phoneDialer` | — | ✅ کامل |
| 28 | `bluetooth` | Bluetooth LE | ✅ کامل |
| 29 | `nfc` | NFC | ✅ کامل |
| 30 | `speechToText` | Speech Recognition | ✅ کامل |
| 31 | `textToSpeech` | Speech Synthesis | ✅ کامل |
| 32 | `videoPlayer` | Video Player | ✅ کامل |
| 33 | `inAppBrowser` | In App Browser | ✅ کامل |
| 34 | `pdf` | PDF Generator | ✅ کامل |
| 35 | `encryption` | — | ✅ کامل |
| 36 | `websocket` | WebSocket | ✅ کامل |
| 37 | `backgroundTask` | Background Task | ✅ کامل |
| 38 | `dialog` | — | ✅ کامل |
| 39 | `toast` | Pretty Toast | ✅ کامل |
| 40 | `splashScreen` | Splash Screen | ✅ کامل |
| 41 | `pushNotification` | Firebase Messaging | ✅ FCM |
| 42 | `wakeLock` | Keep Awake | ✅ کامل |
| 43 | `cookieManager` | — | ✅ کامل |
| 44 | `cacheControl` | — | ✅ کامل |
| 45 | `appUpdate` | Updater (partial) | ✅ partial |
| 46 | `filePicker` | File Picker | ✅ کامل |
| 47 | `fileOpener` | — | ✅ کامل |
| 48 | `sensors` | Accelerometer | ✅ کامل |
| 49 | `screenBrightness` | Brightness | ✅ کامل |
| 50 | `flashlight` | Flash | ✅ کامل |
| 51 | `navigationBar` | Navigation Bar | ✅ کامل |
| 52 | `privacyScreen` | Privacy Screen | ✅ کامل |
| 53 | `nativeSettings` | — | ✅ کامل |
| 54 | `calendar` | Calendar | ✅ کامل |
| 55 | `badge` | Badge | ✅ کامل |
| 56 | `foregroundService` | — | ✅ کامل |
| 57 | `backgroundGeolocation` | Background Geo | ✅ کامل |
| 58 | `mediaManager` | Photo Library (partial) | ✅ partial |
| 59 | `fileCompressor` | File Compressor | ✅ کامل |
| 60 | `zip` | Zip | ✅ کامل |
| 61 | `shareTarget` | Share Target | ✅ کامل |
| 62 | `inAppReview` | In App Review | ✅ کامل |
| 63 | `nativeMarket` | Native Market | ✅ کامل |
| 64 | `screenshot` | — | ✅ کامل |
| 65 | `safeArea` | Safe Area | ✅ کامل |
| 66 | `datePicker` | — | ✅ کامل |
| 67 | `actionSheet` | Action Sheet | ✅ کامل |
| 68 | `textZoom` | Text Zoom | ✅ کامل |
| 69 | `accessibility` | Screen Reader | ✅ کامل |
| 70 | `wifiManager` | WiFi | ✅ کامل |
| 71 | `rootDetection` | Is Root | ✅ کامل |
| 72 | `appIntegrity` | App Attest | ✅ کامل |
| 73 | `alarm` | Alarm | ✅ کامل |
| 74 | `pedometer` | Pedometer | ✅ کامل |
| 75 | `shakeDetection` | Shake | ✅ کامل |
| 76 | `volumeButtons` | Volume Buttons | ✅ کامل |
| 77 | `simInfo` | SIM | ✅ کامل |
| 78 | `kioskMode` | Android Kiosk | ✅ کامل |
| 79 | `intentLauncher` | Intent Launcher | ✅ کامل |
| 80 | `emailComposer` | — | ✅ کامل |
| 81 | `firebaseAnalytics` | Firebase Analytics | ✅ کامل |
| 82 | `firebaseCrashlytics` | Firebase Crashlytics | ✅ کامل |
| 83 | `firebaseRemoteConfig` | Firebase Remote Config | ✅ کامل |
| 84 | `firebaseAuth` | Firebase Auth | ✅ کامل |
| 85 | `cameraPreview` | Camera Preview | ✅ کامل |
| 86 | `documentScanner` | Document Scanner | ✅ کامل |
| 87 | `googleMaps` | Native Geocoder + Launch Nav | ✅ partial |
| 88 | `socialLogin` | Social Login | ✅ Google+Phone |
| 89 | `inAppPurchase` | Purchases | ✅ کامل |
| 90 | `oauth2` | — | ✅ کامل |

---

## ❌ پلاگین‌هایی که هنوز نداریم — اولویت‌بندی شده

---

### 🔴 اولویت ۱ — ارزش تجاری بالا / نیاز واقعی اکثر اپ‌ها

| # | نام پلاگین | Capacitor equivalent | توضیح | چرا مهم |
|---|-----------|---------------------|-------|---------|
| 1 | **Launch Navigator** | Launch Navigator | باز کردن مسیریاب (Waze, Google Maps) | هر اپ مکان‌محور نیاز داره |
| 2 | **Uploader** | Uploader | آپلود فایل بزرگ با progress و background | فرم‌ها، فایل، رسانه |
| 3 | **Media Session** | Media Session | کنترل پخش از lock screen و notification | اپ‌های پادکست/موسیقی |
| 4 | **Pay** | Pay | Apple Pay + Google Pay | پرداخت سریع |
| 5 | **App Tracking Transparency** | ATT | درخواست اجازه ردیابی iOS | الزامی iOS |
| 6 | **Compass** | Compass | قطب‌نما و جهت | نقشه، AR، بازی |
| 7 | **Health** | Health | HealthKit + Health Connect | اپ‌های سلامت |
| 8 | **Native Audio** | Native Audio | پخش صدای کم‌延迟 برای بازی | UX بازی |
| 9 | **Photo Library** | Photo Library | ذخیره/مدیریت عکس در گالری | تکمیل camera |
| 10 | **iBeacon** | iBeacon | تشخیص beacon | خرده‌فروشی، موزه |

---

### 🟠 اولویت ۲ — ارزش بالا برای نوع خاصی از اپ‌ها

| # | نام پلاگین | توضیح | کاربرد |
|---|-----------|-------|--------|
| 11 | **Firebase Firestore** | Cloud Firestore database | backend real-time |
| 12 | **Firebase Storage** | Cloud file storage | آپلود فایل cloud |
| 13 | **Firebase Performance** | Performance monitoring | مانیتورینگ |
| 14 | **Firebase Functions** | Cloud Functions callable | backend logic |
| 15 | **Persistent Account** | حفظ حساب بعد از reinstall | UX کاربر |
| 16 | **Screen Recorder** | ضبط صفحه | آموزش، bug report |
| 17 | **Printer** | پرینت نیتیو | فاکتور، گزارش |
| 18 | **Barometer** | فشارسنج + ارتفاع | سلامت، ورزش |
| 19 | **Light Sensor** | سنسور نور | UX adaptive |
| 20 | **Proximity** | تشخیص نزدیکی | تماس تلفنی |

---

### 🟡 اولویت ۳ — SDK Integration / سرویس‌های شخص ثالث

| # | نام پلاگین | توضیح |
|---|-----------|-------|
| 21 | **AdMob** | تبلیغات Google |
| 22 | **GTM** | Google Tag Manager |
| 23 | **MQTT** | IoT messaging |
| 24 | **Supabase** | Auth + Database |
| 25 | **Intercom** | پشتیبانی چت |
| 26 | **Crisp** | پشتیبانی چت |
| 27 | **Twilio Voice** | تماس VoIP |
| 28 | **Twilio Video** | ویدیو کال |
| 29 | **AppsFlyer** | Attribution analytics |
| 30 | **Facebook Analytics** | Meta analytics |
| 31 | **StreamCall** | ویدیو calling |
| 32 | **RealtimeKit** | Cloudflare Calls |
| 33 | **RudderStack** | Analytics |
| 34 | **Persona** | احراز هویت |

---

### 🟢 اولویت ۴ — خاص / نیچ

| # | نام پلاگین | توضیح |
|---|-----------|-------|
| 35 | **LLM** | AI محلی |
| 36 | **Passkey** | WebAuthn |
| 37 | **WeChat** | SDK وی‌چت |
| 38 | **Watch** | Apple Watch |
| 39 | **Live Activities** | iOS Dynamic Island |
| 40 | **FFmpeg** | پردازش ویدیو |
| 41 | **YouTube Player** | پلیر YouTube |
| 42 | **JW Player** | پلیر JW |
| 43 | **Mux Player** | پلیر Mux |
| 44 | **IVS Player** | پلیر Amazon |
| 45 | **reCAPTCHA** | CAPTCHA |
| 36 | **Age Range** | تشخیص سن |
| 37 | **Age Signals** | Google Play |
| 38 | **Install Referrer** | Referrer tracking |
| 39 | **WebView Guardian** | تشخیص crash WebView |
| 40 | **WebView Crash** | بازیابی crash |
| 41 | **WebView Version** | بررسی نسخه WebView |
| 42 | **Live Reload** | ابزار dev |
| 43 | **Env** | متغیرهای محیطی |
| 44 | **Ricoh360** | دوربین ۳۶۰ |
| 45 | **Zebra DataWedge** | بارکد اسکنر سخت‌افزاری |

---

## 📊 خلاصه آماری

| دسته | تعداد |
|------|-------|
| ✅ **ساخته شده** | 90 |
| 🔴 **اولویت ۱ (فوری)** | 10 |
| 🟠 **اولویت ۲ (مهم)** | 10 |
| 🟡 **اولویت ۳ (سرویس شخص ثالث)** | 14 |
| 🟢 **اولویت ۴ (نیچ)** | 15 |
| **مجموع هدف** | **~139** |

---

## 🎯 پیشنهاد: ۱۰ پلاگین بعدی که باید ساخته بشن

| ترتیب | پلاگین | Dependency مورد نیاز | سختی |
|-------|--------|---------------------|------|
| 1 | **Launch Navigator** | `url_launcher` (already have) | ساده |
| 2 | **Uploader** | `http` + native channel | متوسط |
| 3 | **Media Session** | `audio_service` | متوسط |
| 4 | **Pay** | `pay` (Google/Apple Pay) | متوسط |
| 5 | **Compass** | `flutter_compass` | ساده |
| 6 | **Health** | `health` | متوسط |
| 7 | **Native Audio** | `just_audio` | ساده |
| 8 | **Photo Library** | `photo_manager` | ساده |
| 9 | **iBeacon** | `beacons_plugin` | متوسط |
| 10 | **Firebase Firestore** | `cloud_firestore` | ساده |

---

## 🔧 نکات مهم

### پلاگین‌هایی که partial هستن و نیاز به ارتقا دارن:

1. **`googleMaps`** — باید `launchNavigator` جدا بشه (باز کردن مسیریاب)
2. **`camera`** — `mediaManager` باید کامل‌تر بشه (browse gallery)
3. **`appUpdate`** — فقط version check داره، OTA update نداره
4. **`socialLogin`** — فقط Google و Phone، باید Facebook و Apple اضافه بشه
5. **`audio`** — `record` و `audioplayers`، باید `audio_service` برای background

### پلاگین‌هایی که با اسم متفاوت داریم:

| Capacitor | ما | نیاز به تغییر |
|-----------|-----|--------------|
| Preferences | storage | ✅ همونه |
| Data Storage SQLite | database | ✅ همونه |
| Barcode Scanner | qrScanner | ✅ همونه |
| Pretty Toast | toast | ✅ همونه |
| Keep Awake | wakeLock | ✅ همونه |
| Is Root | rootDetection | ✅ همونه |
| Native Geocoder | googleMaps | ⚠️ باید جدا بشه |
| Launch Navigator | — | ❌ نداریم |

---

بگو کدوم ۱۰ تا رو بسازم.
