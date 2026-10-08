# Architecture

## Overview

```
 JavaScript page (top frame only)
   window.Native.call / batch / on
          │  JSON text over the `flutterBridge` channel (token on every message)
          ▼
 WebViewHost (Flutter)  ── NavigationPolicy (allow-list, scheme filter)
          │  JsExecutor (runJavaScript) and channel callbacks
          ▼
 MessageBridge (core)   ── sessions, token check, size limit, protocol validation,
          │               bounded script queue, batch envelope handling
          ▼
 PluginManager          ── resolve → rate limit → concurrency → permissions →
          │               validate → cache → execute (timeout) → stats/trace
          ├── PluginRegistry (plugin instances, lifecycle)
          ├── PermissionManager (OS permissions, 5 s TTL cache)
          ├── RateLimiter (sliding window, bounded keys)
          ├── ExecutionGuard (timeout, duplicate ids, cancel-all)
          └── CacheManager (bounded LRU, TTL, JSON copies)
          ▼
 Plugins: storage, camera, geolocation (Plugin subclasses)
```

## Packages (`lib/packages`)

### core
- `protocol/message_protocol.dart` — the wire format. `PluginRequest`,
  `PluginResponse`, `BatchEnvelope`, `PluginError`, `PluginErrorCode`. Parsing
  is strict and throws `ProtocolException` on any violation. Error codes are a
  public contract (`PERMISSION_DENIED`, `PLUGIN_NOT_FOUND`, `METHOD_NOT_FOUND`,
  `INVALID_ARGS`, `INVALID_REQUEST`, `TIMEOUT`, `RATE_LIMIT_EXCEEDED`,
  `CANCELLED`, `EXECUTION_ERROR`, `SANDBOX_VIOLATION`, `NETWORK_ERROR`,
  `UNKNOWN`).
- `bridge/message_bridge.dart` — the only component that knows the page's
  message format. It depends on the `JsExecutor` typedef, not on the WebView.
  - A **session** starts when a page finishes loading (`startSession`) and ends
    when navigation starts (`endSession`). Each session has a random token.
  - Messages are rejected unless they carry the current token (constant-time
    comparison). Messages larger than 2 MiB are rejected before parsing.
  - Responses for a session that has ended are dropped (`_sendResponse` checks
    the session id).
  - Scripts produced before the page reports `bridge_ready` are queued, up to
    256 entries. The queue never grows past that bound.
  - `emitEvent` validates the event name and double-encodes the payload, which
    is what the SDK expects.
- `runtime/bridge_sdk.dart` — the JavaScript injected into each top-level page.
  It is a Dart raw string. The Node test reads the same template, so there is
  one copy of the code.
- `runtime/navigation_policy.dart` — decides which navigations are allowed.
  Default deny for remote hosts. `about:blank` is the only `about:` URL allowed.
  Only `https` (and `http` in debugging) to allow-listed hosts is allowed.
  `javascript:`, `file:`, `intent:`, `content:`, `data:` are always blocked.
- `runtime/webview_host.dart` — the Flutter widget. It configures the
  controller, applies the navigation policy, injects the SDK with a fresh token
  per page, and detaches from the bridge on dispose.
- `utils/logger.dart` — levelled logging with sinks. Logs never include
  payload data.

### plugin_engine
- `plugin_interface.dart` — `Plugin` base class, `PluginCapabilities`,
  `PluginException` (a deliberate, user-safe error), `ValidationResult`.
  Plugins declare `cacheableMethods` and `streamingMethods`; the manager
  enforces these.
- `plugin_registry.dart` — registers and disposes plugins; attaches the event
  emitter when a plugin is registered.
- `plugin_manager.dart` — the execution pipeline (below), batch handling, stats
  and traces.

Pipeline, in order. Each failure returns one protocol error and records one
stats entry and one trace:

1. Plugin resolved (`PLUGIN_NOT_FOUND`). Unknown names create no state.
2. Method supported (`METHOD_NOT_FOUND`).
3. Streaming methods need `supportsStreaming` (`INVALID_REQUEST`).
4. Inside a batch, `supportsBatch` must be true (`INVALID_REQUEST`).
5. Rate limit on `plugin.method` (`RATE_LIMIT_EXCEEDED`).
6. Permissions; a non-granted state is returned as `status` in details
   (`PERMISSION_DENIED`).
7. Argument validation (`INVALID_ARGS`).
8. Cache read for cacheable methods.
9. Concurrency check and increment (`RATE_LIMIT_EXCEEDED`). This is done
   synchronously, with no `await` between the check and the increment.
10. Execution under `ExecutionGuard` with the configured timeout (`TIMEOUT`,
    `CANCELLED`). `PluginException` passes its code and message through.
    Any other exception is logged with its stack trace and reported as
    `EXECUTION_ERROR` with the message `Plugin execution failed`.
11. Cache write for cacheable methods. A successful non-cacheable call
    invalidates the plugin's cache entries.

### security
- `permission_manager.dart` — `PermissionHandlerProvider` maps `camera` and
  `location` to `permission_handler`. `storage` refers to the app sandbox and
  needs no runtime grant. Results are cached for 5 seconds.
- `rate_limiter.dart` — sliding window per key. Keys are created only for
  resolved plugin methods. The number of keys is capped (1024) and idle keys
  are pruned.
- `execution_guard.dart` — per-call timeout, duplicate request-id rejection,
  `cancelAll` for teardown.

### performance
- `cache_manager.dart` — `LinkedHashMap` LRU with TTL. `get` and `set` are
  O(1). Values are stored as JSON text and decoded on each read, so callers
  cannot change cached data. Overwriting a key does not evict other entries.

### devtools
- `bridge_inspector.dart` — debug-only log of bridge traffic. Bounded to 500
  entries. `args` and `data` are replaced with `[redacted]` before storage. The
  UI is only shown when `kDebugMode` is true.

## Plugins (`lib/plugins`)

- **storage** — key/value (`SharedPreferences`, JSON values, 64 KiB limit) and
  files under the application documents directory. Paths go through
  `normalizeSandboxPath` and `resolveWithinRoot` (see SECURITY.md). Files are
  limited to 5 MiB. Read methods are cacheable; write methods are not.
- **camera** — `image_picker`. One concurrent call (the native picker cannot
  present two at once). User cancellation returns `CANCELLED`.
- **geolocation** — one-shot `getCurrentPosition` and multiple named
  `watchPosition` streams (max 4). Positions are delivered as
  `geolocation.position` events with a `watchId`; errors as `geolocation.error`.
  Every stream is cancelled on `clearWatch`, when the stream ends, or on
  dispose.

## Composition (`lib/di/service_locator.dart`)

`get_it` singletons, created lazily. The registry gets an emitter closure that
calls the bridge, which breaks the registry → bridge → manager → registry
cycle without a late setter. Plugins are registered during `ServiceLocator.init`.

## Threading and lifecycle

Everything runs on the Flutter UI isolate. `MessageBridge.dispose` ends the
session, which drops all queued and pending responses. `PluginManager.dispose`
cancels in-flight executions. `WebViewHost.dispose` detaches from the bridge.
