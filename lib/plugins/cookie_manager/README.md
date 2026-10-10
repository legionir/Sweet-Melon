# Cookie Manager Plugin

Manage WebView cookies and sessions.

## Plugin Name
`cookieManager`

## Methods

### `setCookie`
| Param | Type | Required | Default |
|-------|------|----------|---------|
| `domain` | `string` | ✅ | — |
| `name` | `string` | ✅ | — |
| `value` | `string` | ✅ | — |
| `path` | `string` | — | `"/"` |
| `secure` | `bool` | — | `false` |
| `httpOnly` | `bool` | — | `false` |

### `clearCookies`
Clear all WebView cookies.

### `clearSession`
Clear session cookies.

### `getInfo`

**Returns:** `{ name, version }`

## Usage
```javascript
// Set auth cookie for API domain
await NativeSDK.cookieManager.setCookie({
  domain: 'api.myapp.com',
  name: 'auth_token',
  value: 'Bearer eyJhbGc...',
  secure: true,
  httpOnly: true
});

// On logout
await NativeSDK.cookieManager.clearCookies();
router.navigate('/login');

// Clear only session
await NativeSDK.cookieManager.clearSession();
```
