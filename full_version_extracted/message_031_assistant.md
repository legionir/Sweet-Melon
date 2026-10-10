# لیست پلاگین‌های باقی‌مانده — به ترتیب اولویت

بعد از بررسی دقیق لیست Capacitor، Capgo، و لیست قبلی خودمان، اینها پلاگین‌هایی هستند که **هنوز نساختیم** و برای یک پلتفرم کامل Android لازمند:

---

## 🔴 اولویت بحرانی — فاز ۷ (باید فوری ساخته بشن)

| # | پلاگین | توضیح | چرا بحرانی |
|---|--------|-------|------------|
| 1 | **Dialog / Alert** | نمایش alert، confirm، prompt نیتیو | هر اپ نیاز داره، JS alert در WebView محدوده |
| 2 | **Toast** | نمایش toast message نیتیو | UX پایه — هر اپ لازم داره |
| 3 | **Splash Screen** | مدیریت splash screen (نمایش/مخفی) | تجربه اولیه کاربر |
| 4 | **Push Notification (FCM)** | دریافت push از Firebase Cloud Messaging | اپ واقعی بدون push ناقصه |
| 5 | **Keep Awake / Wake Lock** | روشن نگه داشتن صفحه | ویدیو، اسکن، ناوبری |
| 6 | **Cookie / Session Manager** | مدیریت cookie و session در WebView | لاگین، auth، backend |
| 7 | **WebView Cache Control** | پاک کردن cache، preload، بروزرسانی فایل‌ها | مشکل نسخه، سرعت |
| 8 | **App Update** | بررسی نسخه جدید، in-app update | نگهداری و انتشار |

---

## 🟠 اولویت بالا — فاز ۸

| # | پلاگین | توضیح | کاربرد |
|---|--------|-------|--------|
| 9 | **File Picker** | انتخاب فایل از دستگاه (هر نوع فایل) | آپلود فرم، اسناد |
| 10 | **File Opener** | باز کردن فایل با اپ مناسب (PDF، عکس، ...) | نمایش اسناد |
| 11 | **Motion / Sensors** | شتاب‌سنج، ژیروسکوپ، قطب‌نما، نور، proximity | بازی، سلامت، AR |
| 12 | **Screen Brightness** | کنترل روشنایی صفحه | QR اسکنر، ویدیو |
| 13 | **Flashlight / Torch** | روشن/خاموش کردن فلش دوربین | اسکنر، ابزار |
| 14 | **Navigation Bar** | کنترل نوار ناوبری Android (رنگ، نمایش) | UI حرفه‌ای |
| 15 | **Privacy Screen** | جلوگیری از اسکرین‌شات در recent apps | بانکی، امنیتی |
| 16 | **Native Settings** | باز کردن صفحات تنظیمات سیستم | WiFi، Bluetooth، ... |

---

## 🟡 اولویت متوسط — فاز ۹

| # | پلاگین | توضیح | کاربرد |
|---|--------|-------|--------|
| 17 | **Calendar** | خواندن/ثبت رویداد در تقویم | رزرو، یادآوری |
| 18 | **Badge** | تغییر badge آیکون اپ | نوتیفیکیشن |
| 19 | **Foreground Service** | اجرای سرویس دائمی | لوکیشن، دانلود |
| 20 | **Background Geolocation** | لوکیشن در background | حمل‌ونقل، ردیابی |
| 21 | **Media Manager** | ساخت آلبوم، ذخیره ویدیو/عکس در گالری | رسانه‌ای |
| 22 | **File Compressor** | فشرده‌سازی تصویر (PNG, JPEG, WebP) | آپلود بهینه |
| 23 | **Zip** | فشرده و باز کردن فایل zip | بکاپ، بسته‌بندی |
| 24 | **Share Target** | دریافت محتوا از اپ‌های دیگه (receive share) | اپ‌های ارتباطی |

---

## 🟢 اولویت پایین — فاز ۱۰

| # | پلاگین | توضیح | کاربرد |
|---|--------|-------|--------|
| 25 | **In-App Review** | درخواست امتیاز در Play Store بدون خروج | بازخورد کاربر |
| 26 | **Native Market** | لینک مستقیم به Play Store | بروزرسانی، اپ‌های مرتبط |
| 27 | **Screenshot** | گرفتن اسکرین‌شات از WebView | گزارش، اشتراک |
| 28 | **Safe Area** | دریافت اطلاعات safe area (notch, ...) | UI responsive |
| 29 | **Date/Time Picker** | نمایش date/time picker نیتیو | فرم‌ها |
| 30 | **Action Sheet** | نمایش action sheet نیتیو (bottom sheet) | منوها، انتخاب |
| 31 | **Text Zoom** | تغییر سایز متن WebView | دسترس‌پذیری |
| 32 | **Screen Reader / Accessibility** | اطلاع از TalkBack، خواندن متن | دسترس‌پذیری |

---

## 🔵 اولویت تخصصی — فاز ۱۱+

| # | پلاگین | توضیح | کاربرد |
|---|--------|-------|--------|
| 33 | **WiFi Manager** | مدیریت WiFi (اسکن، اتصال) | IoT |
| 34 | **Root Detection** | تشخیص root بودن دستگاه | امنیتی |
| 35 | **App Attest / Integrity** | تأیید اصالت دستگاه (Play Integrity) | امنیتی |
| 36 | **Alarm** | ست کردن آلارم نیتیو | یادآوری |
| 37 | **Pedometer** | شمارش قدم | سلامت |
| 38 | **Shake Detection** | تشخیص تکان دادن دستگاه | UX خاص |
| 39 | **Volume Buttons** | شنود دکمه‌های صدا | ابزار، اسکنر |
| 40 | **SIM Info** | اطلاعات سیم‌کارت | احراز هویت |
| 41 | **iBeacon** | تشخیص beacon | خرده‌فروشی، موزه |
| 42 | **Kiosk Mode** | قفل دستگاه در حالت kiosk | نمایشگاه، فروشگاه |
| 43 | **Intent Launcher** | لانچ intent سیستمی خاص | تنظیمات، اپ‌ها |
| 44 | **UDP / MQTT** | ارتباط شبکه‌ای سطح پایین | IoT |
| 45 | **Email Composer** | compose ایمیل با ضمیمه | پشتیبانی |

---

## خلاصه آماری

| وضعیت | تعداد |
|--------|-------|
| ✅ ساخته شده | 37 |
| 🔴 فاز ۷ (بحرانی) | 8 |
| 🟠 فاز ۸ (بالا) | 8 |
| 🟡 فاز ۹ (متوسط) | 8 |
| 🟢 فاز ۱۰ (پایین) | 8 |
| 🔵 فاز ۱۱+ (تخصصی) | 13 |
| **مجموع هدف** | **82** |

---

## پیشنهاد ترتیب ساخت

```
فاز ۷ (فوری):
  Dialog → Toast → Splash Screen → FCM Push →
  Wake Lock → Cookie Manager → Cache Control → App Update

فاز ۸ (بعدی):
  File Picker → File Opener → Sensors →
  Screen Brightness → Flashlight → Navigation Bar →
  Privacy Screen → Native Settings

فاز ۹ (بعد از stabilize):
  Calendar → Badge → Foreground Service →
  Background Geo → Media Manager →
  File Compressor → Zip → Share Target

فاز ۱۰ (بهبود):
  In-App Review → Native Market → Screenshot →
  Safe Area → Date Picker → Action Sheet →
  Text Zoom → Accessibility

فاز ۱۱+ (تخصصی بر اساس نیاز):
  WiFi → Root Detection → App Attest → Alarm →
  Pedometer → Shake → Volume → SIM →
  iBeacon → Kiosk → Intent Launcher → UDP/MQTT →
  Email Composer
```

بگو تا فاز ۷ رو شروع کنم.
