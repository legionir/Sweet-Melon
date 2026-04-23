import 'dart:async';
import 'dart:convert';
import 'package:webview_flutter/webview_flutter.dart';
import '../protocol/message_protocol.dart';
import '../utils/logger.dart';

// ============================================================
// MESSAGE BRIDGE — هسته ارتباط JS ↔ Flutter
// ============================================================

typedef MessageHandler = Future<PluginResponse> Function(PluginRequest request);
typedef BatchHandler = Future<List<PluginResponse>> Function(
  List<PluginRequest> requests,
  BatchOptions options,
);

class MessageBridge {
  WebViewController? _webViewController;
  MessageHandler? _messageHandler;
  BatchHandler? _batchHandler;
  
  // Stream برای observable بودن پیام‌ها
  final _messageStreamController = 
      StreamController<BridgeMessage>.broadcast();
  
  Stream<BridgeMessage> get messageStream => 
      _messageStreamController.stream;

  bool _isReady = false;
  
  // صف پیام‌های pending قبل از آماده شدن bridge
  final List<String> _pendingJsMessages = [];

  // ============================================================
  // SETUP
  // ============================================================

  void setWebViewController(WebViewController controller) {
    _webViewController = controller;
  }

  void setMessageHandler(MessageHandler handler) {
    _messageHandler = handler;
  }

  void setBatchHandler(BatchHandler handler) {
    _batchHandler = handler;
  }

  void onBridgeReady() {
    _isReady = true;
    
    // ارسال پیام‌های pending
    for (final message in _pendingJsMessages) {
      _controller.runJavaScript(message);
    }
    _pendingJsMessages.clear();
  }

  WebViewController get _controller {
    if (_webViewController == null) {
      throw StateError('WebViewController not set');
    }
    return _webViewController!;
  }

  // ============================================================
  // INCOMING — از JS به Flutter
  // ============================================================

  Future<void> handleIncomingMessage(Map<String, dynamic> json) async {
    final startTime = DateTime.now();
    
    try {
      // تشخیص نوع پیام
      if (json.containsKey('type') && json['type'] == 'batch') {
        await _handleBatchRequest(json);
        return;
      }
      
      // پیام معمولی
      final request = PluginRequest.fromJson(json);
      
      // ثبت در stream
      _messageStreamController.add(
        BridgeMessage.incoming(request),
      );
      
      BridgeLogger.info(
        'Bridge',
        'Incoming: ${request.plugin}.${request.method} [${request.requestId}]',
      );

      if (_messageHandler == null) {
        await _sendError(
          request.requestId,
          PluginError(
            code: PluginErrorCode.executionError,
            message: 'No message handler registered',
          ),
        );
        return;
      }

      final response = await _messageHandler!(request);
      
      // محاسبه زمان پردازش
      final processingTime = DateTime.now()
          .difference(startTime)
          .inMilliseconds;
      
      final responseWithMeta = PluginResponse(
        requestId: response.requestId,
        timestamp: response.timestamp,
        success: response.success,
        data: response.data,
        error: response.error,
        metadata: ResponseMetadata(
          processingTimeMs: processingTime,
          pluginVersion: response.metadata.pluginVersion,
          fromCache: response.metadata.fromCache,
        ),
      );
      
      await _sendResponse(responseWithMeta);
      
      // ثبت پاسخ در stream
      _messageStreamController.add(
        BridgeMessage.outgoing(responseWithMeta),
      );
      
    } catch (e, stackTrace) {
      BridgeLogger.error('Bridge', 'Error handling message: $e');
      
      final requestId = json['requestId'] as String? ?? 'unknown';
      await _sendError(
        requestId,
        PluginError(
          code: PluginErrorCode.executionError,
          message: e.toString(),
          stackTrace: stackTrace.toString(),
        ),
      );
    }
  }

  Future<void> _handleBatchRequest(Map<String, dynamic> json) async {
    final batchId = json['batchId'] as String;
    final requestsJson = json['requests'] as List<dynamic>;
    final optionsJson = json['options'] as Map<String, dynamic>?;
    
    final requests = requestsJson
        .map((r) => PluginRequest.fromJson(r as Map<String, dynamic>))
        .toList();
    
    final options = optionsJson != null
        ? BatchOptions(
            parallel: optionsJson['parallel'] as bool? ?? true,
            stopOnError: optionsJson['stopOnError'] as bool? ?? false,
            timeoutMs: optionsJson['timeoutMs'] as int?,
          )
        : BatchOptions.defaults();
    
    BridgeLogger.info(
      'Bridge',
      'Batch request: $batchId (${requests.length} requests)',
    );
    
    List<PluginResponse> responses;
    
    if (_batchHandler != null) {
      responses = await _batchHandler!(requests, options);
    } else {
      // Fallback: اجرای سریالی
      responses = [];
      for (final request in requests) {
        if (_messageHandler != null) {
          try {
            final response = await _messageHandler!(request);
            responses.add(response);
            if (options.stopOnError && !response.success) break;
          } catch (e) {
            responses.add(
              PluginResponse.failure(
                requestId: request.requestId,
                error: PluginError(
                  code: PluginErrorCode.executionError,
                  message: e.toString(),
                ),
              ),
            );
            if (options.stopOnError) break;
          }
        }
      }
    }
    
    await _sendBatchResponse(batchId, responses);
  }

  // ============================================================
  // OUTGOING — از Flutter به JS
  // ============================================================

  Future<void> _sendResponse(PluginResponse response) async {
    final js = '''
      window.__resolveCall(
        '${response.requestId}',
        ${jsonEncode(response.toJson())}
      );
    ''';
    await _runJs(js);
  }

  Future<void> _sendError(String requestId, PluginError error) async {
    final response = PluginResponse.failure(
      requestId: requestId,
      error: error,
    );
    await _sendResponse(response);
  }

  Future<void> _sendBatchResponse(
    String batchId,
    List<PluginResponse> responses,
  ) async {
    final js = '''
      window.__resolveBatch(
        '$batchId',
        ${jsonEncode({'results': responses.map((r) => r.toJson()).toList()})}
      );
    ''';
    await _runJs(js);
  }

  // ارسال رویداد از Flutter به JS
  Future<void> emitEvent(String event, dynamic data) async {
    final js = '''
      window.__emitEvent(
        '$event',
        ${jsonEncode(data)}
      );
    ''';
    await _runJs(js);
  }

  // اجرای مستقیم JS
  Future<void> _runJs(String script) async {
    if (!_isReady) {
      _pendingJsMessages.add(script);
      return;
    }
    
    try {
      await _controller.runJavaScript(script);
    } catch (e) {
      BridgeLogger.error('Bridge', 'JS execution error: $e');
    }
  }

  void dispose() {
    _messageStreamController.close();
  }
}

// ============================================================
// BRIDGE MESSAGE — برای observability
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
