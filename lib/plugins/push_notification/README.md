# Push Notification Plugin (FCM)

Firebase Cloud Messaging push notifications.

## Plugin Name
`pushNotification`

## Methods

### `register`
Register device and get FCM token.

**Returns:**
```json
{ "registered": true, "token": "fcm_token_here", "permissionGranted": true }
```

### `getToken`
| Param | Type |
|-------|------|
| `vapidKey` | `string` (optional) |

### `requestPermission`
| Param | Type | Default |
|-------|------|---------|
| `alert` | `bool` | `true` |
| `badge` | `bool` | `true` |
| `sound` | `bool` | `true` |

### `subscribe` / `unsubscribe`
| Param | Type | Required |
|-------|------|----------|
| `topic` | `string` | ✅ |

### `getDeliveredNotifications`
### `removeDeliveredNotifications`
| Param | Type |
|-------|------|
| `ids` | `string[]` |

### `removeAllDeliveredNotifications`
### `getInitialMessage` — Get notification that opened the app
### `deleteToken`

## Events
| Event | Data |
|-------|------|
| `push.registered` | `{ token }` |
| `push.received` | `{ title, body, data, foreground }` |
| `push.tap` | `{ title, body, data }` |
| `push.localTap` | `{ id, payload }` |
| `push.tokenRefreshed` | `{ token }` |

## Setup Required
1. Add `google-services.json` to `android/app/`
2. Initialize Firebase in `main.dart`

## Usage
```javascript
// Register and get token
const { token } = await NativeSDK.pushNotification.register();
// Send token to your backend
await sendToServer(token);

// Subscribe to topics
await NativeSDK.pushNotification.subscribe('news');
await NativeSDK.pushNotification.subscribe('promotions');

// Handle incoming notifications
NativeSDK.on('push.received', (data) => {
  showInAppBanner(data.title, data.body);
});

// Handle tap on notification
NativeSDK.on('push.tap', (data) => {
  router.navigate('/notification?id=' + data.data.id);
});

// Check initial notification (app opened from notification)
const initial = await NativeSDK.pushNotification.getInitialMessage();
if (initial.available) {
  router.navigate('/notification', initial.message.data);
}
```
