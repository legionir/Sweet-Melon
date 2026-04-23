# گزارش ممیزی کد Sweet-Melon (فایل‌به‌فایل)

تاریخ بررسی: 2026-04-23

## روش بررسی
- بازبینی استاتیک فایل‌به‌فایل با تمرکز روی: خطاهای کامپایل، باگ منطقی، امنیت، نگهداشت‌پذیری، تست‌پذیری.
- تلاش برای اجرای ابزارهای تحلیل/تست انجام شد اما ابزار Dart/Flutter در محیط موجود نبود.

---

## 1) `pubspec.yaml`
### نواقص
1. وابستگی `mustache_template` در کد CLI استفاده شده اما در `pubspec.yaml` اصلاً تعریف نشده است؛ build/runtime برای CLI شکست می‌خورد.
2. پکیج‌های `args` و `path` در `dev_dependencies` تعریف شده‌اند، درحالی‌که CLI آن‌ها را در runtime استفاده می‌کند و باید در `dependencies` باشند.

### اثر
- اجرای `dart run cli/bin/bridge_cli.dart` در محیط واقعی می‌تواند به خطای import resolution یا runtime failure برسد.

---

## 2) `cli/bin/bridge_cli.dart`
### نواقص بحرانی
1. باگ ورودی نسخه: در خط خواندن `version`، از `stdin.readLineSync()` دوبار خوانده می‌شود؛ بار اول برای check و بار دوم برای مقدار واقعی. این باعث می‌شود ورودی نسخه اشتباه مصرف شود.
2. importهای بلااستفاده: `mustache_template` و `path` عملاً هیچ استفاده‌ای ندارند.
3. پارامتر `ArgResults args` در `_createPlugin` استفاده نشده است.
4. متغیر `content` در `_listPlugins` خوانده می‌شود ولی هرگز استفاده نمی‌شود.
5. تبدیل نام در `_toPascalCase` برای ورودی‌های ناسالم (مثل قطعه خالی بعد از split) می‌تواند خطای Range بدهد (`w[0]`).

### اثر
- UX خراب در ساخت plugin.
- افزایش warning/عدم انطباق lint.
- ریسک crash برای نام‌های مرزی.

---

## 3) `lib/main.dart`
### وضعیت
- ساختار اولیه درست است، اما کنترل خطا برای `ServiceLocator.init()` وجود ندارد.

### ریسک
- اگر init شکست بخورد، اپ بدون fallback یا لاگ کاربرپسند متوقف می‌شود.

---

## 4) `lib/app.dart`
### نواقص
1. importهای بلااستفاده: `di/service_locator.dart` و `logger.dart`.
2. `ColorScheme.dark(...)` بدون `const` (قابل بهینه‌سازی جزئی).

### اثر
- نویز lint و کاهش کیفیت نگهداشت.

---

## 5) `lib/di/service_locator.dart`
### نواقص
1. `init()` غیر-idempotent است؛ اگر دوباره صدا زده شود، به خطای `GetIt` (already registered) می‌رسد.
2. هیچ teardown مرکزی برای dispose کردن singletonهایی که resource دارند (مثل `CacheManager`, `MessageBridge`, `BridgeInspector`) دیده نمی‌شود.
3. `WebViewHostConfig` ثبت می‌شود، اما بسیاری از فیلدهای آن در `WebViewHost` استفاده عملی ندارند.

### اثر
- ریسک نشت منابع و مشکل در تست/Hot Restart.

---

## 6) `lib/screens/home_screen.dart`
### نواقص
1. import بلااستفاده: `dart:convert`.
2. HTML/JS بسیار بزرگ inline داخل Dart string است؛ نگهداشت را سخت و امکان lint/format JS را از بین می‌برد.
3. callbackهای `onclick` خام بدون لایه abstraction؛ تست‌پذیری UI پایین.

### اثر
- بدهی فنی و سختی debug بلندمدت.

---

## 7) `packages/core/lib/src/protocol/message_protocol.dart`
### نواقص
1. cast مستقیم `args` در `fromJson` به `Map<String, dynamic>` ممکن است با payloadهای dynamic از JS crash دهد.
2. `PluginResponse` در حالت error می‌تواند بدون جزئیات استاندارد برگردد (وابسته به caller)؛ schema انعطاف‌پذیر ولی سخت برای contract سخت‌گیر.

### اثر
- ریسک خطاهای runtime در داده‌های ناسازگار.

---

## 8) `packages/core/lib/src/bridge/message_bridge.dart`
### نواقص
1. `_handleBatchRequest` اعتبارسنجی قوی روی `batchId/requests` ندارد؛ payload مخرب یا ناقص می‌تواند exception بسازد.
2. در `onBridgeReady` ارسال pending messageها مستقیم با `_controller.runJavaScript` انجام می‌شود و fail موردی هر پیام مدیریت دقیق ندارد.
3. timeout-level برای batch درخواست‌ها (بر اساس `options.timeoutMs`) در این لایه enforce نمی‌شود.

### اثر
- ناپایداری در سناریوهای edge/bad input.

---

## 9) `packages/core/lib/src/runtime/webview_host.dart`
### نواقص مهم
1. import بلااستفاده: `message_protocol.dart`.
2. فیلدهای config (`allowFileAccess`, `allowedHosts`, `enableDebugging`, `defaultTimeoutMs`) عملاً enforce نشده‌اند.
3. در JS SDK، `batch()` timeout ندارد؛ اگر پاسخ نرسد `window.__pending[batchId]` می‌تواند نشت کند.
4. `window.flutterBridge.postMessage` بدون guard وجود bridge channel؛ در شرایط race می‌تواند fail بدهد.
5. `widget.bridge.handleIncomingMessage(json)` بدون `await` در `_onJsMessage` صدا زده می‌شود (fire-and-forget)، که trace خطا را سخت می‌کند.

### اثر
- افزایش ریسک memory leak و رفتار غیرقابل پیش‌بینی در شرایط ناپایدار شبکه/وب‌ویو.

---

## 10) `packages/core/lib/src/utils/logger.dart`
### نواقص
1. `BridgeLogger.dispose()` فقط stream را می‌بندد؛ sinkهایی مثل `FileSink` مدیریت lifecycle مرکزی ندارند.
2. `FileSink._flush()` فقط buffer را clear می‌کند و واقعاً فایل نمی‌نویسد (اگر صرفاً placeholder نیست باید تکمیل شود).

### اثر
- احتمال رفتار ناقص logging در production.

---

## 11) `packages/plugin_engine/lib/src/plugin_interface.dart`
### نواقص
1. API کلی خوب است، اما mutable state (`_initialized`) در abstract class بدون ایمن‌سازی concurrent access.
2. مستندسازی contract خطاها (چه Exceptionهایی مجاز هستند) کامل نیست.

### اثر
- ریسک race condition در pluginهای پیچیده.

---

## 12) `packages/plugin_engine/lib/src/plugin_registry.dart`
### نواقص مهم
1. `dispose()` فقط stream را می‌بندد و pluginهای ثبت‌شده dispose نمی‌شوند.
2. مقایسه نسخه ساده‌سازی‌شده است و pre-release/build metadata واقعی SemVer را پشتیبانی نمی‌کند.

### اثر
- نشت منابع plugin و resolve نادقیق نسخه در آینده.

---

## 13) `packages/plugin_engine/lib/src/plugin_manager.dart`
### نواقص بحرانی
1. کلید cache بر پایه `request.args.toString()` است؛ ترتیب map در همه سناریوها deterministic نیست و collision/miss کاذب می‌دهد.
2. timeout اجرای plugin روی `30000` hardcode شده و از request/config پویا نمی‌آید.
3. `errorCount` در `PluginStats` تعریف شده ولی در مسیرهای failure هرگز افزایش داده نمی‌شود.
4. `traceId` صرفاً مشتق از requestId است؛ اگر نیاز به uniqueness cross-system باشد کافی نیست.

### اثر
- رفتار cache غیرقابل اتکا، observability ناقص، و محدودیت انعطاف runtime.

---

## 14) `packages/security/lib/src/permission_manager.dart`
### نقیصه امنیتی
1. اگر provider تنظیم نشده باشد، `check()` به صورت پیش‌فرض `granted` برمی‌گرداند.

### اثر
- **Fail-open امنیتی**: مسیرهای حساس بدون کنترل مجوز واقعی اجرا می‌شوند.

---

## 15) `packages/security/lib/src/rate_limiter.dart`
### نواقص
1. design کلی مناسب است، اما cleanup برای bucketهای بی‌استفاده وجود ندارد (رشد حافظه در کلیدهای زیاد).
2. `retryAfterMs` با clamp ثابت 60s بریده می‌شود؛ برای windowهای بزرگ‌تر اطلاع دقیق از retry از دست می‌رود.

### اثر
- نشت تدریجی حافظه و telemetry نادقیق.

---

## 16) `packages/security/lib/src/execution_guard.dart`
### نواقص
1. کلاس‌های `ArgsValidator/ValidationResult` اینجا تکراری هستند (نام `ValidationResult` با لایه plugin هم‌نام است) و می‌تواند باعث ابهام API شود.
2. cancellation واقعی task فقط timeout exception می‌دهد؛ کار داخلی async ممکن است همچنان ادامه یابد.

### اثر
- ابهام معماری و رفتار نیمه-cancel.

---

## 17) `packages/performance/lib/src/cache_manager.dart`
### نواقص
1. پیاده‌سازی "LRU" واقعی نیست؛ eviction بر اساس `hitCount` است نه recency.
2. thread-safety/concurrency guard ندارد (در Flutter isolate تک‌ریسمانی معمولاً ok، ولی async interleaving همچنان وجود دارد).

### اثر
- کارایی کمتر از انتظار و رفتار cache غیرمطابق نام.

---

## 18) `packages/devtools/lib/src/bridge_inspector.dart`
### نواقص مهم
1. subscriptionهای `bridge.messageStream.listen` و `manager.traces.listen` ذخیره/لغو نمی‌شوند؛ در `dispose()` فقط stream داخلی بسته می‌شود.
2. در `_buildStats` متغیر `report` ساخته می‌شود ولی استفاده نمی‌شود.

### اثر
- memory leak و lint warnings.

---

## 19) `plugins/camera/lib/camera_plugin.dart`
### نواقص
1. import بلااستفاده: `execution_guard.dart`.
2. در `_takePhoto`، `bytes` خوانده می‌شود اما استفاده نمی‌شود (هزینه I/O اضافه).
3. `validateArgs` فقط زمانی validation می‌کند که quality از نوع `int` باشد؛ اگر `double/string` ارسال شود عملاً reject صریح نمی‌شود.

### اثر
- کارایی پایین‌تر و اعتبارسنجی ناقص.

---

## 20) `plugins/storage/lib/storage_plugin.dart`
### نواقص امنیتی/منطقی
1. **Path Traversal** محتمل: الحاق مستقیم `${dir.path}/$path` بدون normalize + check boundary.
2. import بلااستفاده: `execution_guard.dart`.
3. `_set` برای valueهای non-JSON-encodable ممکن است exception بدهد و هندل نشده باشد.
4. در `_listFiles`، `entity.path.split('/')` وابسته به separator یونیکس است.

### اثر
- ریسک دسترسی خارج از sandbox اپ و ناپایداری cross-platform.

---

## 21) `plugins/geolocation/lib/geolocation_plugin.dart`
### نواقص
1. import بلااستفاده: `execution_guard.dart`.
2. `watchPosition` stream را راه می‌اندازد ولی event واقعی به JS emit نمی‌کند (TODO باقی مانده).

### اثر
- API ناقص نسبت به انتظار `watch`.

---

## 22) `test/plugin_manager_test.dart`
### نواقص
1. پوشش تست خوب است اما یکپارچگی WebView/Bridge/Plugins واقعی را پوشش نمی‌دهد.
2. importهای نسبی به `../packages/...` شکننده‌اند؛ بهتر است package import یا test harness استاندارد.
3. assertionی برای افزایش `errorCount` وجود ندارد (باگ شناخته‌شده manager پنهان می‌ماند).

---

## 23) `README.md`
### نواقص مستندسازی
1. README بسیار مفصل است اما بخشی از ادعاها (مثل featureهای کامل امنیت/کارایی) با implementation فعلی هم‌تراز نیستند.
2. نمونه‌ها نیازمند هم‌ترازسازی با رفتار واقعی کد (مثلاً timeout و event watch) هستند.

---

## جمع‌بندی اولویت‌بندی
### P0 (فوری)
- fail-open در `PermissionManager`.
- path traversal احتمالی در `StoragePlugin`.
- باگ ورودی نسخه در CLI.
- mismatch وابستگی‌های pubspec با importهای CLI.

### P1 (مهم)
- dispose ناقص در `PluginRegistry` و `BridgeInspector`.
- cache key ناپایدار در `PluginManager`.
- enforce نشدن config امنیتی در `WebViewHost`.
- batch pending leak در JS SDK.

### P2 (بهبود کیفیت)
- حذف import/متغیرهای بلااستفاده.
- اصلاح ادعای LRU یا rename استراتژی.
- افزایش پوشش تست یکپارچه.
- هم‌ترازسازی README با کد واقعی.

