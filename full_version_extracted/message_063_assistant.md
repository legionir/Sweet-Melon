# تحلیل جامع پلاگین‌های Capacitor و مقایسه با Sweetmelon

---

## وضعیت فعلی: چه داریم، چه نداریم

بعد از بررسی دقیق **همه** پلاگین‌هایی که لیست کردی و مقایسه با **90 پلاگین فعلی** Sweetmelon، نتیجه اینه:

---

## ✅ پلاگین‌هایی که **داریم و کاملند** (52 مورد)

| Capacitor Plugin | Sweetmelon Equivalent | وضعیت |
|-----|-----|------|
| Native Biometric | `biometrics` | ✅ کامل |
| In App Browser | `inAppBrowser` | ✅ کامل |
| Navigation Bar | `navigationBar` | ✅ کامل |
| Native Audio | `audio` | ✅ کامل |
| Speech Recognition | `speechToText` | ✅ کامل |
| Flash | `flashlight` | ✅ کامل |
| Camera Preview | `cameraPreview` | ✅ کامل |
| Audio Recorder | `audio` | ✅ ترکیبی |
| NFC | `nfc` | ✅ کامل |
| In App Review | `inAppReview` | ✅ کامل |
| Document Scanner | `documentScanner` | ✅ کامل |
| Shake | `shakeDetection` | ✅ کامل |
| Share Target | `shareTarget` | ✅ کامل |
| Printer | `pdf` | ✅ ترکیبی |
| Native Market | `nativeMarket` | ✅ کامل |
| Screen Orientation | `orientation` | ✅ کامل |
| Uploader | `downloadManager` + `http` | ✅ ترکیبی |
| Is Root | `rootDetection` | ✅ کامل |
| WiFi | `wifiManager` | ✅ پایه |
| File Picker | `filePicker` | ✅ کامل |
| Video Player | `videoPlayer` | ✅ کامل |
| Pedometer | `pedometer` | ✅ کامل |
| Contacts | `contacts` | ✅ کامل |
| Data Storage / SQLite | `database` | ✅ کامل |
| Compass | `sensors` (magnetometer) | ✅ ترکیبی |
| Bluetooth Low Energy | `bluetooth` | ✅ کامل |
| Downloader | `downloadManager` | ✅ کامل |
| App Attest | `appIntegrity` | ✅ پایه |
| PDF Generator | `pdf` | ✅ کامل |
| SIM | `simInfo` | ✅ کامل |
| Intent Launcher | `intentLauncher` | ✅ کامل |
| Keep Awake | `wakeLock` | ✅ کامل |
| File Compressor | `fileCompressor` | ✅ کامل |
| Barometer | `sensors` | ✅ ترکیبی |
| File | `fileSystem` | ✅ کامل |
| Speech Synthesis | `textToSpeech` | ✅ کامل |
| Accelerometer | `sensors` | ✅ ترکیبی |
| Zip | `zip` | ✅ کامل |
| Brightness | `screenBrightness` | ✅ کامل |
| Android Kiosk | `kioskMode` | ✅ پایه |
| Alarm | `alarm` | ✅ کامل |
| Firebase Analytics | `firebaseAnalytics` | ✅ کامل |
| Firebase Crashlytics | `firebaseCrashlytics` | ✅ کامل |
| Firebase Messaging | `pushNotification` | ✅ کامل |
| Firebase Authentication | `firebaseAuth` | ✅ کامل |
| Firebase Remote Config | `firebaseRemoteConfig` | ✅ کامل |
| Privacy Screen | `privacyScreen` | ✅ کامل |
| Volume Buttons | `volumeButtons` | ✅ کامل |
| Social Login | `socialLogin` | ✅ Google + Phone |
| Background Geolocation | `backgroundGeolocation` | ✅ کامل |
| Background Task | `backgroundTask` | ✅ کامل |
| OAuth2 (generic) | `oauth2` | ✅ کامل |

---

## 🟡 پلاگین‌هایی که **داریم ولی ناقصند** (8 مورد)

| Capacitor Plugin | Sweetmelon | چه کم داریم |
|-----|-----|------|
| Native Purchases / IAP | `inAppPurchase` | RevenueCat SDK ندارد، فقط native IAP |
| Health | — | فقط pedometer داریم، Health Connect ندارد |
| Mute | — | detect کردن mute switch ندارد |
| Native Geocoder | `googleMaps` | geocode داره ولی offline geocoding ندارد |
| Fast SQL | `database` | sync protocol و IndexedDB replacement ندارد |
| Media Session | — | lock screen media controls ندارد |
| Photo Library | `camera` + `mediaManager` | browse gallery ندارد |
| App Tracking Transparency | — | ATT API فقط iOS هست |

---

## 🔴 پلاگین‌هایی که **اصلاً نداریم** — به ترتیب اولویت

### اولویت بحرانی (باید ساخته بشن)

| # | پلاگین | توضیح | چرا مهم |
|---|--------|-------|---------|
| 1 | **Updater / Live Update** | بروزرسانی بدون Play Store | بدون اون هر تغییر HTML نیاز به release جدید داره |
| 2 | **Autofill Save Password** | ذخیره پسورد در password manager | UX لاگین بسیار مهم |
| 3 | **Screen Recorder** | ضبط صفحه | پشتیبانی، آموزش، گزارش باگ |
| 4 | **Persistent Account** | حفظ account بعد از reinstall | از دست ندادن اطلاعات کاربر |
| 5 | **Pay (Apple/Google Pay)** | پرداخت سریع | فروشگاهی |

### اولویت بالا

| # | پلاگین | توضیح | چرا مهم |
|---|--------|-------|---------|
| 6 | **Crisp / Live Chat** | چت آنلاین | پشتیبانی مشتری |
| 7 | **WebView Guardian** | تشخیص kill شدن WebView | پایداری اپ |
| 8 | **Twilio Voice / VoIP** | تماس تلفنی اینترنتی | ارتباطات |
| 9 | **Launch Navigator** | باز کردن مسیریاب | حمل‌ونقل |
| 10 | **MQTT** | پروتکل IoT real-time | IoT |
| 11 | **Video Thumbnails** | thumbnail از ویدیو | media apps |
| 12 | **Incoming Call Kit** | UI تماس ورودی | VoIP |

### اولویت متوسط

| # | پلاگین | توضیح | چرا مهم |
|---|--------|-------|---------|
| 13 | **AdMob** | تبلیغات گوگل | درآمدزایی |
| 14 | **iBeacon** | proximity beacon | خرده‌فروشی |
| 15 | **Usage Stats Manager** | آمار استفاده از اپ | analytics |
| 16 | **Android Inline Install** | update بدون خروج از اپ | UX بروزرسانی |
| 17 | **YouTube Player** | پلیر یوتیوب | محتوایی |
| 18 | **Env Manager** | مدیریت environment variables | DevOps |
| 19 | **Light Sensor** | سنسور نور محیط | accessibility |
| 20 | **Proximity Sensor** | سنسور نزدیکی | تماس |

### اولویت پایین

| # | پلاگین | توضیح | چرا مهم |
|---|--------|-------|---------|
| 21 | **LLM Local** | اجرای AI محلی | آینده |
| 22 | **Passkey / WebAuthn** | احراز هویت بدون پسورد | آینده |
| 23 | **WeChat SDK** | اکوسیستم چین | بازار خاص |
| 24 | **FFmpeg** | پردازش ویدیو | media |
| 25 | **AppsFlyer** | attribution | مارکتینگ |
| 26 | **GTM** | Google Tag Manager | analytics |
| 27 | **RealtimeKit** | Cloudflare Calls | video calling |
| 28 | **Intercom** | help desk | support |
| 29 | **Supabase** | backend integration | backend |
| 30 | **SSL Pinning Plugin** | SSL pinning مستقل | امنیت (قبلاً در SecurityManager داریم) |

### اولویت خیلی پایین / تخصصی

| # | پلاگین | توضیح |
|---|--------|-------|
| 31 | Firebase Functions | cloud functions |
| 32 | Firebase Firestore | cloud database |
| 33 | Firebase Storage | cloud storage |
| 34 | Firebase App Check | app verification |
| 35 | Firebase Performance | performance monitoring |
| 36 | Ricoh360 Camera | دوربین خاص |
| 37 | Zebra DataWedge | سخت‌افزار خاص |
| 38 | JW Player | پلیر خاص |
| 39 | IVS Player | Amazon IVS |
| 40 | Mux Player | Mux streaming |
| 41 | Contentsquare | analytics خاص |
| 42 | RudderStack | analytics خاص |
| 43 | Persona | identity verification |
| 44 | Microsoft Intune | enterprise |

---

## 📊 خلاصه آماری

| وضعیت | تعداد |
|--------|-------|
| ✅ داریم و کامل | 52 |
| 🟡 داریم ولی ناقص | 8 |
| 🔴 نداریم — بحرانی | 5 |
| 🔴 نداریم — اولویت بالا | 7 |
| 🔴 نداریم — متوسط | 8 |
| 🔴 نداریم — پایین | 10 |
| 🔴 نداریم — تخصصی | 14 |
| **مجموع Capacitor plugins بررسی شده** | **~150** |
| **پوشش فعلی Sweetmelon** | **~60%** |

---

## 🎯 پیشنهاد: ۳ فاز بعدی

### فاز ۲۱: Critical Missing (1 هفته)
```
1. Live Updater — بروزرسانی HTML بدون store
2. Autofill Password — ذخیره در password manager
3. Screen Recorder — ضبط صفحه
4. Persistent Account — حفظ اکانت بعد reinstall
5. Pay (Google Pay) — پرداخت سریع
6. WebView Guardian — recovery از crash
7. Launch Navigator — باز کردن مسیریاب
```

### فاز ۲۲: Monetization & Communication (1 هفته)
```
8. AdMob — تبلیغات
9. Crisp / Live Chat — پشتیبانی آنلاین
10. MQTT — IoT messaging
11. YouTube Player — embed ویدیو
12. Incoming Call Kit — UI تماس
13. Video Thumbnails — thumbnail ویدیو
14. Usage Stats — آمار استفاده
```

### فاز ۲۳: Enhancement (1 هفته)
```
15. iBeacon — proximity
16. Inline Install — بروزرسانی درون‌اپ
17. Env Manager — environment vars
18. Light/Proximity Sensor — سنسورها
19. Media Session — lock screen controls
20. Health Connect — داده سلامت
21. Photo Library — browse گالری
```

---

## 💡 پیشنهادات ویژه

### ۱. Live Updater — مهم‌ترین پلاگین نداشته
```
بدون این پلاگین، هر تغییر در HTML/CSS/JS نیاز به:
  - build جدید
  - upload به Play Store
  - انتظار review
  - منتظر شدن کاربر برای update

با Live Updater:
  - تغییرات www فوراً deploy می‌شن
  - بدون نیاز به store review
  - rollback خودکار اگه مشکل داشته باشه
  - A/B testing ممکن می‌شه

پیشنهاد: مثل Capgo Updater:
  - backend ساده برای host کردن bundles
  - diff-based updates (فقط فایل‌های تغییرکرده)
  - version management
  - auto-rollback
```

### ۲. پلاگین‌هایی که نباید بسازیم
```
این‌ها خیلی تخصصی‌ان و ساختنشون value ندارد:
  - Ricoh360 Camera — سخت‌افزار خاص
  - Zebra DataWedge — scanner خاص
  - Contentsquare — analytics خاص
  - RudderStack — analytics خاص
  - Microsoft Intune — enterprise خاص
  - WeChat — بازار چین
  - Capacitor+ forks — مربوط به Capacitor
```

### ۳. پلاگین‌هایی که بهتره از package موجود استفاده بشه
```
به جای ساختن از صفر:
  - AdMob → google_mobile_ads package
  - Supabase → supabase_flutter package
  - AppsFlyer → appsflyer_sdk package
  - Intercom → intercom_flutter package
  - Crisp → crisp_sdk package

فقط یک thin wrapper روی bridge بسازیم.
```

---

بگو کدوم فاز رو بسازم یا اگه سوال داری بپرس.
