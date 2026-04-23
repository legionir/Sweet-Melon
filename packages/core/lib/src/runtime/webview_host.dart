import 'dart:convert';
import 'dart:io';
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
    if (widget.config.enableDebugging && Platform.isAndroid) {
      WebViewController.enableDebugging(true);
    }

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

    // تزریق Bridge API به WebView
    widget.bridge.setWebViewController(_controller);

    if (widget.initialHtml != null) {
      _controller.loadHtmlString(widget.initialHtml!);
    } else if (widget.initialUrl.isNotEmpty) {
      _controller.loadRequest(Uri.parse(widget.initialUrl));
    }
  }

  NavigationDelegate _buildNavigationDelegate() {
    return NavigationDelegate(
      onNavigationRequest: (request) {
        final uri = Uri.tryParse(request.url);
        if (uri == null) {
          BridgeLogger.warn('WebView', 'Blocked invalid URL: ${request.url}');
          return NavigationDecision.prevent;
        }

        if (!widget.config.allowFileAccess && uri.scheme == 'file') {
          BridgeLogger.warn('WebView', 'Blocked file:// navigation: ${request.url}');
          return NavigationDecision.prevent;
        }

        if (widget.config.allowedHosts.isNotEmpty &&
            (uri.scheme == 'http' || uri.scheme == 'https')) {
          final isAllowed = widget.config.allowedHosts.contains(uri.host);
          if (!isAllowed) {
            BridgeLogger.warn('WebView', 'Blocked host: ${uri.host}');
            return NavigationDecision.prevent;
          }
        }

        return NavigationDecision.navigate;
      },
      onPageStarted: (url) {
        BridgeLogger.info('WebView', 'Page started: $url');
      },
      onPageFinished: (url) async {
        BridgeLogger.info('WebView', 'Page finished: $url');
        await _injectBridgeScript();
        setState(() => _isReady = true);
        widget.onPageLoaded?.call();
      },
      onWebResourceError: (error) {
        BridgeLogger.error(
          'WebView',
          'Resource error: ${error.description}',
        );
        widget.onError?.call(error.description);
      },
    );
  }

  // تزریق JS SDK به WebView
  Future<void> _injectBridgeScript() async {
    final script = _buildBridgeScript();
    await _controller.runJavaScript(script);
    BridgeLogger.info('WebView', 'Bridge script injected');
  }

  String _buildBridgeScript() {
    final defaultTimeoutMs = widget.config.defaultTimeoutMs;
    const template = r'''
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
        // NATIVE API — سطح بالا برای توسعه‌دهنده
        // ============================================================
        
        window.Native = {
          /**
           * فراخوانی یک متد از یک پلاگین
           * @param {Object} options
           * @param {string} options.plugin - نام پلاگین
           * @param {string} options.method - نام متد
           * @param {Object} options.args - آرگومان‌ها
           * @param {string} options.version - نسخه پلاگین
           * @param {number} options.timeout - زمان انتظار (ms)
           * @returns {Promise}
           */
          call({ plugin, method, args = {}, version = '1.0.0', timeout = 30000 }) {
            return new Promise((resolve, reject) => {
              const id = generateId();
              let timeoutHandle = null;
              
              if (timeout > 0) {
                timeoutHandle = setTimeout(() => {
                  if (window.__pending[id]) {
                    delete window.__pending[id];
                    reject({
                      code: 'TIMEOUT',
                      message: `Request timed out after ${timeout}ms`,
                      requestId: id
                    });
                  }
                }, timeout);
              }
              
              window.__pending[id] = {
                resolve: (data) => {
                  clearTimeout(timeoutHandle);
                  resolve(data);
                },
                reject: (error) => {
                  clearTimeout(timeoutHandle);
                  reject(error);
                }
              };
              
              const message = JSON.stringify({
                requestId: id,
                plugin,
                version,
                method,
                args,
                timestamp: new Date().toISOString(),
                metadata: {
                  headers: {}
                }
              });
              
              window.flutterBridge.postMessage(message);
              window.__requestCount++;
            });
          },

          /**
           * ارسال چند درخواست به صورت دسته‌ای
           * @param {Array} requests
           * @param {Object} options
           * @returns {Promise<Array>}
           */
          batch(requests, options = {}) {
            const batchId = generateId();
            const timeout = typeof options.timeout === 'number'
              ? options.timeout
              : __DEFAULT_TIMEOUT_MS__;
            const batchMessage = JSON.stringify({
              type: 'batch',
              batchId,
              requests: requests.map(r => ({
                requestId: generateId(),
                ...r,
                timestamp: new Date().toISOString(),
                metadata: { headers: {} }
              })),
              options: {
                parallel: options.parallel !== false,
                stopOnError: options.stopOnError || false,
                timeoutMs: timeout
              }
            });
            
            return new Promise((resolve, reject) => {
              let timeoutHandle = null;
              if (timeout > 0) {
                timeoutHandle = setTimeout(() => {
                  if (window.__pending[batchId]) {
                    delete window.__pending[batchId];
                    reject({
                      code: 'TIMEOUT',
                      message: `Batch timed out after ${timeout}ms`,
                      batchId
                    });
                  }
                }, timeout);
              }

              window.__pending[batchId] = {
                resolve: (data) => {
                  clearTimeout(timeoutHandle);
                  resolve(data);
                },
                reject: (error) => {
                  clearTimeout(timeoutHandle);
                  reject(error);
                }
              };
              window.flutterBridge.postMessage(batchMessage);
            });
          },

          /**
           * گوش دادن به رویدادهای Native
           * @param {string} event - نام رویداد
           * @param {Function} callback
           */
          on(event, callback) {
            if (!window.__eventListeners[event]) {
              window.__eventListeners[event] = [];
            }
            window.__eventListeners[event].push(callback);
            return () => this.off(event, callback);
          },

          off(event, callback) {
            if (!window.__eventListeners[event]) return;
            window.__eventListeners[event] = 
              window.__eventListeners[event].filter(cb => cb !== callback);
          },
          
          /**
           * اطلاعات bridge
           */
          info() {
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
          const response = typeof responseJson === 'string' 
            ? JSON.parse(responseJson) 
            : responseJson;
            
          const pending = window.__pending[requestId];
          
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
          const response = typeof responseJson === 'string'
            ? JSON.parse(responseJson)
            : responseJson;
            
          const pending = window.__pending[batchId];
          if (!pending) return;
          
          delete window.__pending[batchId];
          pending.resolve(response.results);
        };
        
        // ============================================================
        // EVENT EMITTER از Flutter به JS
        // ============================================================
        
        window.__emitEvent = function(event, dataJson) {
          const data = typeof dataJson === 'string'
            ? JSON.parse(dataJson)
            : dataJson;
            
          const listeners = window.__eventListeners[event] || [];
          listeners.forEach(cb => {
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
          getPending: () => Object.keys(window.__pending),
          getStats: () => ({
            pending: Object.keys(window.__pending).length,
            total: window.__requestCount,
            listeners: Object.keys(window.__eventListeners)
          }),
          clearPending: () => {
            const ids = Object.keys(window.__pending);
            ids.forEach(id => {
              window.__pending[id]?.reject({
                code: 'CLEARED',
                message: 'Pending request cleared manually'
              });
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
    return template.replaceAll('__DEFAULT_TIMEOUT_MS__', '$defaultTimeoutMs');
  }

  // دریافت پیام از JS
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
          const Center(
            child: CircularProgressIndicator(),
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
