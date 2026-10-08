import 'dart:async';
import 'dart:convert';
import 'dart:math';

import '../protocol/message_protocol.dart';
import '../utils/logger.dart';

// ============================================================
// MESSAGE BRIDGE — core of the JS <-> Flutter communication
// ============================================================
//
// Responsibilities:
//  * Session management: each page load gets a random token. Messages without
//    the current token are rejected; responses for an older session are dropped.
//  * Validation at the boundary (size, JSON shape, protocol).
//  * Dispatch to the plugin pipeline (via [MessageHandler] / [BatchHandler]).
//  * Delivery of responses and events into the WebView via [JsExecutor].
//
// The bridge does not depend on webview_flutter. The WebView host supplies a
// [JsExecutor] and forwards raw channel messages.

typedef MessageHandler = Future<PluginResponse> Function(PluginRequest request);

typedef BatchHandler = Future<List<PluginResponse>> Function(
  List<PluginRequest> requests,
  BatchOptions options,
);

/// Executes a script in the page. Implemented by the WebView host.
typedef JsExecutor = Future<void> Function(String script);

final RegExp _eventNamePattern = RegExp(r'^[A-Za-z][A-Za-z0-9_.-]{0,127}$');

class MessageBridge {
  static const int defaultMaxQueuedScripts = 256;

  final int maxQueuedScripts;
  final Random _random;

  JsExecutor? _executor;
  MessageHandler? _messageHandler;
  BatchHandler? _batchHandler;

  final StreamController<BridgeMessage> _messageStreamController =
      StreamController<BridgeMessage>.broadcast();

  String? _sessionToken;
  int _sessionId = 0;
  bool _isReady = false;
  bool _disposed = false;
  final List<String> _queuedScripts = [];

  MessageBridge({
    this.maxQueuedScripts = defaultMaxQueuedScripts,
    Random? random,
  })  : assert(maxQueuedScripts > 0),
        _random = random ?? Random.secure();

  Stream<BridgeMessage> get messageStream => _messageStreamController.stream;

  /// True after the current page session reported `bridge_ready` with a valid token.
  bool get isReady => _isReady;

  /// Monotonic identifier of the current page session.
  int get sessionId => _sessionId;

  int get queuedScriptCount => _queuedScripts.length;

  bool get isDisposed => _disposed;

  // ============================================================
  // SETUP
  // ============================================================

  void setMessageHandler(MessageHandler handler) {
    _messageHandler = handler;
  }

  void setBatchHandler(BatchHandler handler) {
    _batchHandler = handler;
  }

  void attachJsExecutor(JsExecutor executor) {
    _executor = executor;
  }

  /// Detaches [executor] if it is the current one. Returns true when detached.
  bool detachJsExecutor(JsExecutor executor) {
    if (_executor != executor) return false;
    _executor = null;
    return true;
  }

  // ============================================================
  // SESSION LIFECYCLE
  // ============================================================

  /// Starts a new page session and returns its token.
  ///
  /// Invalidates the previous token, marks the bridge not ready and drops
  /// scripts queued for the previous page.
  String startSession() {
    _invalidateSession();
    _sessionToken = _newToken();
    return _sessionToken!;
  }

  /// Ends the current page session without starting a new one (page
  /// navigation, WebView disposal).
  void endSession() => _invalidateSession();

  /// Called when the page reports `bridge_ready`. Returns false when the token
  /// does not belong to the current session.
  bool onBridgeReady(String? token) {
    if (_disposed || !_tokenMatches(token)) {
      BridgeLogger.warn('Bridge', 'Ignored bridge_ready with invalid token');
      return false;
    }
    _isReady = true;
    final queued = List<String>.from(_queuedScripts);
    _queuedScripts.clear();
    for (final script in queued) {
      unawaited(_execute(script));
    }
    return true;
  }

  void _invalidateSession() {
    _sessionId++;
    _sessionToken = null;
    _isReady = false;
    _queuedScripts.clear();
  }

  String _newToken() {
    final bytes = List<int>.generate(32, (_) => _random.nextInt(256));
    return base64Url.encode(bytes).replaceAll('=', '');
  }

  bool _tokenMatches(Object? candidate) {
    final expected = _sessionToken;
    if (expected == null || candidate is! String) return false;
    if (candidate.length != expected.length) return false;
    var diff = 0;
    for (var i = 0; i < expected.length; i++) {
      diff |= expected.codeUnitAt(i) ^ candidate.codeUnitAt(i);
    }
    return diff == 0;
  }

  // ============================================================
  // INCOMING — from JS to Flutter
  // ============================================================

  /// Handles one raw message from the JavaScript channel. Never throws.
  Future<void> handleIncomingMessage(String raw) async {
    if (_disposed) return;
    final session = _sessionId;

    final size = utf8.encode(raw).length;
    if (size > kMaxMessageBytes) {
      BridgeLogger.warn('Bridge', 'Rejected oversized message ($size bytes)');
      return;
    }

    final Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException {
      BridgeLogger.warn('Bridge', 'Rejected malformed JSON message');
      return;
    }
    if (decoded is! Map) {
      BridgeLogger.warn('Bridge', 'Rejected message that is not an object');
      return;
    }
    final Map<String, dynamic> json;
    try {
      json = Map<String, dynamic>.from(decoded);
    } on TypeError {
      BridgeLogger.warn('Bridge', 'Rejected message with non-string keys');
      return;
    }

    if (!_tokenMatches(json['token'])) {
      // No response: the sender is not an authenticated page session.
      BridgeLogger.warn('Bridge', 'Rejected message with invalid session token');
      return;
    }

    try {
      if (json['type'] == 'batch') {
        await _handleBatch(json, session);
      } else {
        await _handleRequest(json, session);
      }
    } catch (e, stackTrace) {
      // Defensive: nothing above should throw, but a bridge failure must never
      // surface as an unhandled zone error.
      BridgeLogger.error('Bridge', 'Unexpected bridge failure: ${e.runtimeType}',
          {'stackTrace': stackTrace.toString()});
    }
  }

  Future<void> _handleRequest(Map<String, dynamic> json, int session) async {
    PluginRequest request;
    try {
      request = PluginRequest.fromJson(json);
    } on ProtocolException catch (e) {
      BridgeLogger.warn('Bridge', 'Malformed request: ${e.message}');
      final id = e.requestId;
      if (id != null) {
        await _sendResponse(
          session,
          PluginResponse.failure(
            requestId: id,
            error: PluginError(
              code: PluginErrorCode.invalidRequest,
              message: e.message,
            ),
          ),
        );
      }
      return;
    }

    _emit(BridgeMessage.incoming(request));
    BridgeLogger.info(
      'Bridge',
      'Incoming: ${request.plugin}.${request.method} [${request.requestId}]',
    );

    PluginResponse response;
    final handler = _messageHandler;
    if (handler == null) {
      response = PluginResponse.failure(
        requestId: request.requestId,
        error: PluginError(
          code: PluginErrorCode.executionError,
          message: 'No message handler registered',
        ),
      );
    } else {
      try {
        response = await handler(request);
      } catch (e, stackTrace) {
        BridgeLogger.error('Bridge', 'Handler failure: ${e.runtimeType}',
            {'stackTrace': stackTrace.toString()});
        response = PluginResponse.failure(
          requestId: request.requestId,
          error: PluginError(
            code: PluginErrorCode.executionError,
            message: 'Internal error',
          ),
        );
      }
    }
    if (response.requestId != request.requestId) {
      BridgeLogger.error('Bridge', 'Handler answered a different requestId');
      response = PluginResponse.failure(
        requestId: request.requestId,
        error: PluginError(
          code: PluginErrorCode.executionError,
          message: 'Internal error',
        ),
      );
    }

    await _sendResponse(session, response);
    _emit(BridgeMessage.outgoing(response));
  }

  Future<void> _handleBatch(Map<String, dynamic> json, int session) async {
    BatchEnvelope envelope;
    try {
      envelope = BatchEnvelope.fromJson(json);
    } on ProtocolException catch (e) {
      BridgeLogger.warn('Bridge', 'Malformed batch: ${e.message}');
      final id = e.requestId;
      if (id != null) {
        await _sendBatchResponse(
          session,
          id,
          const [],
          error: PluginError(
            code: PluginErrorCode.invalidRequest,
            message: e.message,
          ),
        );
      }
      return;
    }

    final batchId = envelope.batchId;
    BridgeLogger.info(
      'Bridge',
      'Batch $batchId: ${envelope.requests.length} requests',
    );

    final handler = _batchHandler;
    if (handler == null) {
      await _sendBatchResponse(
        session,
        batchId,
        const [],
        error: PluginError(
          code: PluginErrorCode.executionError,
          message: 'No batch handler registered',
        ),
      );
      return;
    }

    List<PluginResponse> responses;
    try {
      responses = await handler(envelope.requests, envelope.options);
    } catch (e, stackTrace) {
      BridgeLogger.error('Bridge', 'Batch failure: ${e.runtimeType}',
          {'stackTrace': stackTrace.toString()});
      await _sendBatchResponse(
        session,
        batchId,
        const [],
        error: PluginError(
          code: PluginErrorCode.executionError,
          message: 'Internal error',
        ),
      );
      return;
    }

    // Results are returned in request order; any request without a result
    // gets an explicit failure so the JS side never waits on a missing item.
    final byId = <String, PluginResponse>{
      for (final r in responses)
        if (r.requestId.isNotEmpty) r.requestId: r,
    };
    final ordered = <PluginResponse>[
      for (final request in envelope.requests)
        byId[request.requestId] ??
            PluginResponse.failure(
              requestId: request.requestId,
              error: PluginError(
                code: PluginErrorCode.executionError,
                message: 'No result produced for request',
              ),
            ),
    ];
    await _sendBatchResponse(session, batchId, ordered);
  }

  // ============================================================
  // OUTGOING — from Flutter to JS
  // ============================================================

  Future<void> _sendResponse(int session, PluginResponse response) async {
    if (session != _sessionId) {
      BridgeLogger.debug(
        'Bridge',
        'Dropped response of a previous page session [${response.requestId}]',
      );
      return;
    }
    final payload = _encodeOrFallback(response);
    await _runJs(
      'window.__resolveCall(${jsonEncode(response.requestId)}, $payload);',
    );
  }

  Future<void> _sendBatchResponse(
    int session,
    String batchId,
    List<PluginResponse> results, {
    PluginError? error,
  }) async {
    if (session != _sessionId) {
      BridgeLogger.debug('Bridge', 'Dropped batch of a previous page session');
      return;
    }
    final String payload;
    try {
      payload = jsonEncode({
        'results': results.map((r) => r.toJson()).toList(),
        if (error != null) 'error': error.toJson(),
      });
    } catch (_) {
      BridgeLogger.error('Bridge', 'Batch response not serializable');
      final fallback = jsonEncode({
        'results': <Map<String, dynamic>>[],
        'error': PluginError(
          code: PluginErrorCode.executionError,
          message: 'Response could not be serialized',
        ).toJson(),
      });
      await _runJs(
        'window.__resolveBatch(${jsonEncode(batchId)}, $fallback);',
      );
      return;
    }
    await _runJs(
      'window.__resolveBatch(${jsonEncode(batchId)}, $payload);',
    );
  }

  /// Emits an event to the page. Payloads that cannot be encoded are dropped.
  Future<void> emitEvent(String event, Object? data) async {
    if (_disposed) return;
    if (!_eventNamePattern.hasMatch(event)) {
      BridgeLogger.warn('Bridge', 'Refused to emit invalid event name');
      return;
    }
    final String encoded;
    try {
      encoded = jsonEncode(data);
    } catch (_) {
      BridgeLogger.error('Bridge', 'Event payload not serializable: $event');
      return;
    }
    // The SDK expects the payload as JSON text, so it is encoded twice.
    await _runJs(
      'window.__emitEvent(${jsonEncode(event)}, ${jsonEncode(encoded)});',
    );
  }

  String _encodeOrFallback(PluginResponse response) {
    try {
      return jsonEncode(response.toJson());
    } catch (_) {
      BridgeLogger.error(
        'Bridge',
        'Response not serializable [${response.requestId}]',
      );
      return jsonEncode(
        PluginResponse.failure(
          requestId: response.requestId,
          error: PluginError(
            code: PluginErrorCode.executionError,
            message: 'Response could not be serialized',
          ),
        ).toJson(),
      );
    }
  }

  // ============================================================
  // EXECUTION HELPERS
  // ============================================================

  Future<void> _runJs(String script) async {
    if (_disposed || _executor == null) return;
    if (!_isReady) {
      if (_queuedScripts.length >= maxQueuedScripts) {
        BridgeLogger.warn('Bridge', 'Script queue full; dropping script');
        return;
      }
      _queuedScripts.add(script);
      return;
    }
    await _execute(script);
  }

  Future<void> _execute(String script) async {
    final executor = _executor;
    if (executor == null) return;
    try {
      await executor(script);
    } catch (e) {
      BridgeLogger.error('Bridge', 'JS execution failed: ${e.runtimeType}');
    }
  }

  void _emit(BridgeMessage message) {
    if (!_messageStreamController.isClosed) {
      _messageStreamController.add(message);
    }
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _invalidateSession();
    _executor = null;
    _messageHandler = null;
    _batchHandler = null;
    unawaited(_messageStreamController.close());
  }
}

// ============================================================
// BRIDGE MESSAGE
// ============================================================

enum BridgeMessageDirection { incoming, outgoing }

class BridgeMessage {
  final BridgeMessageDirection direction;
  final BaseMessage message;
  final DateTime timestamp;

  const BridgeMessage({
    required this.direction,
    required this.message,
    required this.timestamp,
  });

  factory BridgeMessage.incoming(BaseMessage message) => BridgeMessage(
        direction: BridgeMessageDirection.incoming,
        message: message,
        timestamp: DateTime.now(),
      );

  factory BridgeMessage.outgoing(BaseMessage message) => BridgeMessage(
        direction: BridgeMessageDirection.outgoing,
        message: message,
        timestamp: DateTime.now(),
      );
}
