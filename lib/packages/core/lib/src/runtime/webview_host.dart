import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../bridge/message_bridge.dart';
import '../utils/logger.dart';

// ============================================================
// WEBVIEW HOST — مرکز اصلی اجرای JS App
// ============================================================

class WebViewHost extends StatefulWidget {
  final String initialUrl;
  final String? initialHtml;
  final WebViewHostConfig config;
  final MessageBridge bridge;
  final VoidCallback? onPageLoaded;
  final Function(String error)? onError;

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
  bool _isReady = false;

  @override
  void initState() {
    super.initState();
    _initController();
  }

  void _initController() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(_buildNavigationDelegate())
      ..addJavaScriptChannel(
        'flutterBridge',
        onMessageReceived: _onJsMessage,
      )
      ..addJavaScriptChannel(
        '__bridgeInternal',
        onMessageReceived: _onInternalMessage,
      );

    // تزریق controller به bridge
    widget.bridge.setWebViewController(_controller);

    if (widget.initialHtml != null) {
      _controller.loadHtmlString(widget.initialHtml!);
    } else if (widget.initialUrl.isNotEmpty) {
      _controller.loadRequest(Uri.parse(widget.initialUrl));
    }
  }

  NavigationDelegate _buildNavigationDelegate() {
    return NavigationDelegate(
      onPageStarted: (url) {
        BridgeLogger.info('WebView', 'Page started: $url');
      },
      onPageFinished: (url) async {
        BridgeLogger.info('WebView', 'Page finished: $url');
        await _injectBridgeScript();
        if (mounted) {
          setState(() => _isReady = true);
        }
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
        // امنیت: فقط اجازه navigation به hostهای مجاز
        if (widget.config.allowedHosts.isNotEmpty) {
          final uri = Uri.tryParse(request.url);
          if (uri != null &&
              uri.host.isNotEmpty &&
              !widget.config.allowedHosts.contains(uri.host)) {
            BridgeLogger.warn(
              'WebView',
              'Blocked navigation to: ${request.url}',
            );
            return NavigationDecision.prevent;
          }
        }
        return NavigationDecision.navigate;
      },
    );
  }

  // ── تزریق JS SDK به WebView ───────────────────────────────

  Future<void> _injectBridgeScript() async {
    const script = r'''
      (function() {
        'use strict';

        // ============================================================
        // NATIVE BRIDGE CORE
        // ============================================================
        
        if (window.__NativeBridgeInitialized) return;
        window.__NativeBridgeInitialized = true;
        
        window.__pending = {};
        window.__eventListeners = {};
        window.__requestCount = 0;
        
        // ============================================================
        // BRIDGE UTILITIES
        // ============================================================
        
        function generateId() {
          if (typeof crypto !== 'undefined' && crypto.randomUUID) {
            return crypto.randomUUID();
          }
          return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(
            /[xy]/g,
            function(c) {
              var r = Math.random() * 16 | 0;
              var v = c === 'x' ? r : (r & 0x3 | 0x8);
              return v.toString(16);
            }
          );
        }
        
        // ============================================================
        // NATIVE API
        // ============================================================
        
        window.Native = {
          call: function(options) {
            var plugin = options.plugin;
            var method = options.method;
            var args = options.args || {};
            var version = options.version || '1.0.0';
            var timeout = options.timeout != null ? options.timeout : 30000;

            return new Promise(function(resolve, reject) {
              var id = generateId();
              var timeoutHandle = null;
              
              if (timeout > 0) {
                timeoutHandle = setTimeout(function() {
                  if (window.__pending[id]) {
                    delete window.__pending[id];
                    reject({
                      code: 'TIMEOUT',
                      message: 'Request timed out after ' + timeout + 'ms',
                      requestId: id
                    });
                  }
                }, timeout);
              }
              
              window.__pending[id] = {
                resolve: function(data) {
                  clearTimeout(timeoutHandle);
                  resolve(data);
                },
                reject: function(error) {
                  clearTimeout(timeoutHandle);
                  reject(error);
                }
              };
              
              var message = JSON.stringify({
                requestId: id,
                plugin: plugin,
                version: version,
                method: method,
                args: args,
                timestamp: new Date().toISOString(),
                metadata: { headers: {} }
              });
              
              window.flutterBridge.postMessage(message);
              window.__requestCount++;
            });
          },

          batch: function(requests, options) {
            options = options || {};
            var batchId = generateId();

            var mappedRequests = requests.map(function(r) {
              return {
                requestId: generateId(),
                plugin: r.plugin,
                method: r.method,
                args: r.args || {},
                version: r.version || '1.0.0',
                timestamp: new Date().toISOString(),
                metadata: { headers: {} }
              };
            });

            var batchMessage = JSON.stringify({
              type: 'batch',
              batchId: batchId,
              requests: mappedRequests,
              options: {
                parallel: options.parallel !== false,
                stopOnError: options.stopOnError || false,
                timeoutMs: options.timeout
              }
            });
            
            return new Promise(function(resolve, reject) {
              window.__pending[batchId] = { resolve: resolve, reject: reject };
              window.flutterBridge.postMessage(batchMessage);
            });
          },

          on: function(event, callback) {
            if (!window.__eventListeners[event]) {
              window.__eventListeners[event] = [];
            }
            window.__eventListeners[event].push(callback);

            var self = this;
            return function() { self.off(event, callback); };
          },

          off: function(event, callback) {
            if (!window.__eventListeners[event]) return;
            window.__eventListeners[event] = 
              window.__eventListeners[event].filter(function(cb) {
                return cb !== callback;
              });
          },
          
          info: function() {
            return {
              initialized: true,
              pendingRequests: Object.keys(window.__pending).length,
              totalRequests: window.__requestCount,
              version: '1.0.0'
            };
          }
        };
        
        // ============================================================
        // RESPONSE HANDLER — پاسخ از Flutter
        // ============================================================
        
        window.__resolveCall = function(requestId, responseJson) {
          var response = typeof responseJson === 'string' 
            ? JSON.parse(responseJson) 
            : responseJson;
            
          var pending = window.__pending[requestId];
          
          if (!pending) {
            console.warn('[Bridge] No pending request for:', requestId);
            return;
          }
          
          delete window.__pending[requestId];
          
          if (response.success) {
            pending.resolve(response.data);
          } else {
            pending.reject(response.error);
          }
        };
        
        // ============================================================
        // BATCH RESPONSE HANDLER
        // ============================================================
        
        window.__resolveBatch = function(batchId, responseJson) {
          var response = typeof responseJson === 'string'
            ? JSON.parse(responseJson)
            : responseJson;
            
          var pending = window.__pending[batchId];
          if (!pending) return;
          
          delete window.__pending[batchId];
          pending.resolve(response.results);
        };
        
        // ============================================================
        // EVENT EMITTER از Flutter به JS
        // ============================================================
        
        window.__emitEvent = function(event, dataJson) {
          var data = typeof dataJson === 'string'
            ? JSON.parse(dataJson)
            : dataJson;
            
          var listeners = window.__eventListeners[event] || [];
          listeners.forEach(function(cb) {
            try {
              cb(data);
            } catch (e) {
              console.error('[Bridge] Event listener error:', e);
            }
          });
        };

        // ============================================================
        // DEBUG HELPERS
        // ============================================================
        
        window.__bridgeDebug = {
          getPending: function() { return Object.keys(window.__pending); },
          getStats: function() {
            return {
              pending: Object.keys(window.__pending).length,
              total: window.__requestCount,
              listeners: Object.keys(window.__eventListeners)
            };
          },
          clearPending: function() {
            var ids = Object.keys(window.__pending);
            ids.forEach(function(id) {
              if (window.__pending[id] && window.__pending[id].reject) {
                window.__pending[id].reject({
                  code: 'CLEARED',
                  message: 'Pending request cleared manually'
                });
              }
            });
            window.__pending = {};
          }
        };
        
        // اطلاع‌رسانی آماده بودن Bridge
        window.__bridgeInternal.postMessage(JSON.stringify({
          type: 'bridge_ready',
          timestamp: new Date().toISOString()
        }));
        
        console.log('[NativeBridge] SDK initialized successfully');
        
      })();
    ''';

    await _controller.runJavaScript(script);
    BridgeLogger.info('WebView', 'Bridge script injected');
  }

  // ── دریافت پیام از JS ─────────────────────────────────────

  void _onJsMessage(JavaScriptMessage message) {
    try {
      final json = jsonDecode(message.message) as Map<String, dynamic>;
      widget.bridge.handleIncomingMessage(json);
    } catch (e) {
      BridgeLogger.error('WebView', 'Failed to parse JS message: $e');
    }
  }

  void _onInternalMessage(JavaScriptMessage message) {
    try {
      final json = jsonDecode(message.message) as Map<String, dynamic>;
      if (json['type'] == 'bridge_ready') {
        BridgeLogger.info('WebView', 'JS Bridge is ready');
        widget.bridge.onBridgeReady();
      }
    } catch (e) {
      BridgeLogger.error('WebView', 'Internal message error: $e');
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
  final bool enableDebugging;
  final bool allowFileAccess;
  final int defaultTimeoutMs;
  final List<String> allowedHosts;

  const WebViewHostConfig({
    this.enableDebugging = false,
    this.allowFileAccess = false,
    this.defaultTimeoutMs = 30000,
    this.allowedHosts = const [],
  });

  factory WebViewHostConfig.development() => const WebViewHostConfig(
        enableDebugging: true,
        defaultTimeoutMs: 60000,
      );

  factory WebViewHostConfig.production() => const WebViewHostConfig(
        enableDebugging: false,
        defaultTimeoutMs: 30000,
      );
}