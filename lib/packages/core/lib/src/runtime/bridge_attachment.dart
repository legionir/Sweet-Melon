import '../bridge/message_bridge.dart';

// ============================================================
// BRIDGE ATTACHMENT — one WebView controller's claim on the bridge
// ============================================================
//
// The MessageBridge is shared (one per app), while a WebView host may be
// disposed or replaced at any time. Page callbacks from a controller can still
// arrive after its host has gone or been superseded by a newer host. An
// attachment makes those callbacks inert unless its executor is still the
// bridge's current one (BUG-011): a late callback must never start or end the
// session of a live page.

class BridgeAttachment {
  final MessageBridge _bridge;
  final JsExecutor _executor;
  bool _detached = false;

  BridgeAttachment({
    required MessageBridge bridge,
    required JsExecutor executor,
  })  : _bridge = bridge,
        _executor = executor {
    bridge.attachJsExecutor(executor);
  }

  /// True while this attachment still owns the bridge's executor.
  bool get isActive => !_detached && _bridge.isCurrentExecutor(_executor);

  /// The previous page is gone: end its session. Ignored when inactive.
  void onPageStarted() {
    if (isActive) _bridge.endSession();
  }

  /// Starts a session for the page that just finished loading and returns its
  /// token, or null when this attachment is no longer active.
  String? startSession() => isActive ? _bridge.startSession() : null;

  /// Releases the executor. Ends the session only if this attachment still
  /// owned the bridge. Safe to call more than once.
  void detach() {
    if (_detached) return;
    _detached = true;
    if (_bridge.detachJsExecutor(_executor)) {
      _bridge.endSession();
    }
  }
}
