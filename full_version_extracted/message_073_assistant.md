نه، اکثر این‌ها رو **نداریم** یا **ناقص** داریم. بذار دقیق بررسی کنم:

---

# بررسی وضعیت فعلی

| قابلیت | وضعیت | توضیح |
|--------|--------|-------|
| **WebSocket Client** | ✅ داریم | اتصال، ارسال، دریافت، auto-reconnect |
| **WebSocket Server** | ❌ نداریم | ساخت WebSocket server روی دستگاه |
| **HTTP Client** | ✅ داریم | GET, POST, PUT, DELETE, download |
| **HTTP/HTTPS Server** | ❌ نداریم | ساخت HTTP server روی دستگاه |
| **Bluetooth Client** | ✅ داریم | scan, connect, read, write BLE |
| **Bluetooth Server** | ❌ نداریم | advertise, accept connection |
| **WiFi Info** | 🟡 ناقص | فقط IP و connection info |
| **WiFi Scan** | ❌ نداریم | لیست شبکه‌ها، اتصال |
| **WiFi Hotspot** | ❌ نداریم | ساخت hotspot |
| **WiFi Direct** | ❌ نداریم | P2P بدون router |
| **FTP Client** | ❌ نداریم | اتصال به FTP server |
| **FTP Server** | ❌ نداریم | ساخت FTP server روی دستگاه |
| **SSH Client** | ❌ نداریم | اتصال SSH |
| **SSH Server** | ❌ نداریم | — |
| **Network Interfaces** | 🟡 ناقص | فقط IP — بدون جزئیات interface |
| **Port Scanner** | ❌ نداریم | — |
| **DNS Lookup** | ❌ نداریم | — |
| **Ping** | ❌ نداریم | — |
| **TCP Socket** | ❌ نداریم | raw TCP connection |
| **UDP Socket** | ❌ نداریم | raw UDP |
| **mDNS/Bonjour** | ❌ نداریم | service discovery |

---

# پیشنهاد: Network Toolkit — ۸ پلاگین جدید

## اولویت‌بندی

| # | پلاگین | اولویت | کاربرد |
|---|--------|--------|--------|
| 1 | **HTTP Server** | بالا | serve فایل، REST API محلی، proxy |
| 2 | **TCP/UDP Socket** | بالا | ارتباط سطح پایین، IoT، gaming |
| 3 | **Network Info** | بالا | interfaces, IPs, gateway, DNS, subnet |
| 4 | **Ping/DNS** | متوسط | network diagnostics |
| 5 | **WebSocket Server** | متوسط | P2P ارتباط بین دستگاه‌ها |
| 6 | **FTP Client** | متوسط | انتقال فایل به server |
| 7 | **SSH Client** | پایین | مدیریت سرور |
| 8 | **WiFi Advanced** | پایین | scan, hotspot, direct |

---

بسازمشون؟
