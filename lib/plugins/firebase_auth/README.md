# Firebase Auth Plugin

Complete Firebase Authentication integration.

## Plugin Name
`firebaseAuth`

## Methods

### `signInWithEmail`
| Param | Type | Required |
|-------|------|----------|
| `email` | `string` | ✅ |
| `password` | `string` | ✅ |

### `signUpWithEmail`
Same as signInWithEmail + optional `displayName`.

### `signInWithGoogle`
### `signInAnonymously`
### `signOut`
### `sendPasswordResetEmail` — `email` required
### `updatePassword` — `newPassword` required
### `updateProfile` — `displayName`, `photoURL`
### `deleteAccount`
### `sendEmailVerification`
### `getIdToken` — `forceRefresh?: bool`
### `getCurrentUser` / `isSignedIn`
### `reloadUser`

**User Object:**
```json
{
  "uid": "abc123",
  "email": "user@example.com",
  "displayName": "Ali",
  "emailVerified": true,
  "isAnonymous": false,
  "photoURL": null
}
```

## Events
| Event | Data |
|-------|------|
| `auth.stateChanged` | `{ user, signedIn }` |

## Usage
```javascript
// Auth state listener (Angular guard example)
NativeSDK.on('auth.stateChanged', (data) => {
  if (data.signedIn) {
    router.navigate('/home');
  } else {
    router.navigate('/login');
  }
});

// Sign up
const { user, success, errorCode } = await NativeSDK.firebaseAuth.signUpWithEmail(
  'ali@test.com', 'password123', 'Ali Ahmadi'
);
if (!success) showError(errorCode);

// Sign in
const result = await NativeSDK.firebaseAuth.signInWithEmail(email, password);
if (result.success) {
  const { token } = await NativeSDK.firebaseAuth.getIdToken();
  // Use token for API calls
}

// Google sign in
const google = await NativeSDK.firebaseAuth.signInWithGoogle();

// Password reset
await NativeSDK.firebaseAuth.sendPasswordResetEmail('user@example.com');
await NativeSDK.toast.show('Reset email sent!');
```
