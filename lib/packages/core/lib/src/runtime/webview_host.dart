import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../bridge/message_bridge.dart';
import '../utils/logger.dart';
import 'bridge_sdk.dart';
import 'navigation_policy.dart';

// ============================================================
// WEBVIEW HOST — the only component that touches the WebView
// ============================================================
//
// Lifecycle:
//  * onPageStarted  -> bridge.endSession(): previous page loses its token.
//  * onPageFinished -> bridge.startSession(): new token, SDK injected with it.
//  * page sends bridge_ready with the token -> bridge becomes ready and flushes.
//  * dispose        -> detach from the bridge and end the session.
//
// Trust boundary: the JavaScript channels are visible to every frame of the
// WebView. The host therefore (a) restricts navigation with [NavigationPolicy],
// (b) only installs the SDK in the top frame, and (c) relies on the session
// token enforced by [MessageBridge]. See docs/SECURITY.md.

const String _bridgeChannel = 'flutterBridge';
const String _internalChannel = '__bridgeInternal';
const int _maxInternalMessageLength = 1024;

class WebViewHost extends StatefulWidget {
  final String initialUrl;
  final String? initialHtml;
  final WebViewHostConfig config;
  final MessageBridge bridge;
  final VoidCallback? onPageLoaded;
  final void Function(String error)? onError;

  const WebViewHost({
    super.key,
    this.initialUrl = '',
    this.initialHtml,
    required this.config,
    required this.bridge,
    this.onPageLoaded,
    this.onError,
  });

  @override
  State<WebViewHost> createState() => _WebViewHostState();
}

class _WebViewHostState extends State<WebViewHost> {
  late final WebViewController _controller;
  late final JsExecutor _jsExecutor;
  late final NavigationPolicy _navigationPolicy;
  bool _isReady = false;

  @override
  void initState() {
    super.initState();
    _navigationPolicy = NavigationPolicy(
      allowedHosts:
          widget.config.allowedHosts.map((h) => h.toLowerCase()).toSet(),
      allowInsecureHttp: widget.config.enableDebugging,
    );
    _initController();
  }

  void _initController() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(_buildNavigationDelegate())
      ..addJavaScriptChannel(
        _bridgeChannel,
        onMessageReceived: _onJsMessage,
      )
      ..addJavaScriptChannel(
        _internalChannel,
        onMessageReceived: _onInternalMessage,
      );

    _jsExecutor = _controller.runJavaScript;
    widget.bridge.attachJsExecutor(_jsExecutor);

    if (widget.initialHtml != null) {
      unawaited(_controller.loadHtmlString(widget.initialHtml!));
    } else if (widget.initialUrl.isNotEmpty) {
      unawaited(_controller.loadRequest(Uri.parse(widget.initialUrl)));
    }
  }

  @override
  void dispose() {
    if (widget.bridge.detachJsExecutor(_jsExecutor)) {
      widget.bridge.endSession();
    }
    super.dispose();
  }

  NavigationDelegate _buildNavigationDelegate() {
    return NavigationDelegate(
      onPageStarted: (url) {
        BridgeLogger.info('WebView', 'Page started: $url');
        widget.bridge.endSession();
        if (mounted) setState(() => _isReady = false);
      },
      onPageFinished: (url) async {
        BridgeLogger.info('WebView', 'Page finished: $url');
        await _injectBridgeScript();
        if (mounted) setState(() => _isReady = true);
        widget.onPageLoaded?.call();
      },
      onWebResourceError: (error) {
        BridgeLogger.error(
          'WebView',
          'Resource error: ${error.description}',
        );
        widget.onError?.call(error.description);
      },
      onNavigationRequest: (request) {
        final verdict = _navigationPolicy.evaluate(
          request.url,
          isMainFrame: request.isMainFrame,
        );
        if (!verdict.allowed) {
          BridgeLogger.warn(
            'WebView',
            'Blocked navigation (${verdict.reason}): ${request.url}',
          );
          return NavigationDecision.prevent;
        }
        return NavigationDecision.navigate;
      },
    );
  }

  // ── Injection ─────────────────────────────────────────────

  Future<void> _injectBridgeScript() async {
    try {
      final token = widget.bridge.startSession();
      await _controller.runJavaScript(buildBridgeSdk(token));
      BridgeLogger.info('WebView', 'Bridge SDK injected');
    } catch (e) {
      BridgeLogger.error(
          'WebView', 'Bridge SDK injection failed: ${e.runtimeType}');
    }
  }

  // ── Messages from JS ──────────────────────────────────────

  void _onJsMessage(JavaScriptMessage message) {
    unawaited(widget.bridge.handleIncomingMessage(message.message));
  }

  void _onInternalMessage(JavaScriptMessage message) {
    if (message.message.length > _maxInternalMessageLength) {
      BridgeLogger.warn('WebView', 'Oversized internal message ignored');
      return;
    }
    try {
      final decoded = jsonDecode(message.message);
      if (decoded is Map && decoded['type'] == 'bridge_ready') {
        final token = decoded['token'];
        if (widget.bridge.onBridgeReady(token is String ? token : null)) {
          BridgeLogger.info('WebView', 'JS Bridge is ready');
        }
      }
    } catch (e) {
      BridgeLogger.error('WebView', 'Internal message error: ${e.runtimeType}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        WebViewWidget(controller: _controller),
        if (!_isReady)
          Container(
            color: const Color(0xFF0A0A1A),
            child: const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF6C63FF),
              ),
            ),
          ),
      ],
    );
  }
}

// ============================================================
// CONFIG
// ============================================================

class WebViewHostConfig {
  /// Enables debug tooling (inspector UI, plain http for allowed hosts).
  final bool enableDebugging;

  /// Hosts that the WebView may navigate to over https. Empty means the
  /// WebView can only show the application's own (about:blank) content.
  final List<String> allowedHosts;

  const WebViewHostConfig({
    this.enableDebugging = false,
    this.allowedHosts = const [],
  });

  factory WebViewHostConfig.development() => const WebViewHostConfig(
        enableDebugging: true,
      );

  factory WebViewHostConfig.production() => const WebViewHostConfig();
}
