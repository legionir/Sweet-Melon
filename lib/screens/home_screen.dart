import 'package:core/src/bridge/message_bridge.dart';
import 'package:core/src/runtime/webview_host.dart';
import 'package:devtools/src/bridge_inspector.dart';
import 'package:flutter/material.dart';

import '../di/service_locator.dart';

// ============================================================
// HOME SCREEN
// ============================================================

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _showInspector = false;

  @override
  Widget build(BuildContext context) {
    final bridge = sl<MessageBridge>();
    final config = sl<WebViewHostConfig>();
    final inspector = sl<BridgeInspector>();

    return Scaffold(
      body: Stack(
        children: [
          WebViewHost(
            initialHtml: _buildDemoHtml(),
            config: config,
            bridge: bridge,
            onPageLoaded: () {
              debugPrint('Page loaded successfully');
            },
          ),

          // Inspector overlay
          if (_showInspector)
            DraggableScrollableSheet(
              initialChildSize: 0.5,
              minChildSize: 0.2,
              maxChildSize: 0.9,
              builder: (ctx, controller) => Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A2E),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.5),
                      blurRadius: 20,
                    ),
                  ],
                ),
                child: BridgeInspectorWidget(inspector: inspector),
              ),
            ),
        ],
      ),

      // FAB برای inspector
      floatingActionButton: FloatingActionButton.small(
        onPressed: () => setState(() => _showInspector = !_showInspector),
        backgroundColor: const Color(0xFF6C63FF),
        child: Icon(
          _showInspector ? Icons.close : Icons.bug_report,
          color: Colors.white,
        ),
      ),
    );
  }

  // ── Demo HTML App ──────────────────────────────────────────

  String _buildDemoHtml() => '''
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Flutter Native Bridge Demo</title>
  <style>
    * { box-sizing: border-box; margin: 0; padding: 0; }
    
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
      background: #0a0a1a;
      color: #e0e0e0;
      min-height: 100vh;
    }
    
    .container {
      max-width: 600px;
      margin: 0 auto;
      padding: 20px;
    }
    
    header {
      text-align: center;
      padding: 30px 0 20px;
    }
    
    header h1 {
      font-size: 24px;
      background: linear-gradient(135deg, #6C63FF, #03DAC6);
      -webkit-background-clip: text;
      -webkit-text-fill-color: transparent;
      font-weight: 800;
    }
    
    header p {
      color: #888;
      font-size: 13px;
      margin-top: 8px;
    }
    
    .card {
      background: #1a1a2e;
      border: 1px solid #2a2a4a;
      border-radius: 12px;
      padding: 20px;
      margin-bottom: 16px;
    }
    
    .card-title {
      font-size: 14px;
      font-weight: 700;
      color: #6C63FF;
      text-transform: uppercase;
      letter-spacing: 1px;
      margin-bottom: 16px;
      display: flex;
      align-items: center;
      gap: 8px;
    }
    
    .btn-grid {
      display: grid;
      grid-template-columns: 1fr 1fr;
      gap: 10px;
    }
    
    button {
      background: linear-gradient(135deg, #6C63FF22, #6C63FF44);
      border: 1px solid #6C63FF66;
      color: #c0b8ff;
      padding: 12px 16px;
      border-radius: 8px;
      font-size: 13px;
      cursor: pointer;
      transition: all 0.2s;
      font-weight: 600;
    }
    
    button:hover {
      background: linear-gradient(135deg, #6C63FF44, #6C63FF66);
      transform: translateY(-1px);
    }
    
    button:active {
      transform: translateY(0);
    }
    
    button:disabled {
      opacity: 0.5;
      cursor: not-allowed;
      transform: none;
    }
    
    .log-container {
      background: #0d0d1f;
      border: 1px solid #2a2a4a;
      border-radius: 8px;
      padding: 12px;
      height: 200px;
      overflow-y: auto;
      font-family: monospace;
      font-size: 11px;
    }
    
    .log-entry {
      padding: 3px 0;
      border-bottom: 1px solid #1a1a2e;
      line-height: 1.6;
    }
    
    .log-entry.success { color: #4CAF50; }
    .log-entry.error { color: #f44336; }
    .log-entry.info { color: #2196F3; }
    .log-entry.pending { color: #FF9800; }
    
    .status-bar {
      display: flex;
      gap: 16px;
      font-size: 12px;
      color: #888;
      margin-top: 16px;
      padding: 12px;
      background: #1a1a2e;
      border-radius: 8px;
    }
    
    .status-item span {
      color: #03DAC6;
      font-weight: bold;
    }
    
    .progress {
      height: 2px;
      background: #6C63FF;
      width: 0%;
      transition: width 0.3s;
      border-radius: 2px;
      margin-bottom: 16px;
    }
  </style>
</head>
<body>
<div class="container">
  <header>
    <h1>Native Bridge</h1>
    <p>Flutter JS Bridge Demo Application</p>
  </header>

  <div class="progress" id="progress"></div>

  <!-- CAMERA -->
  <div class="card">
    <div class="card-title">Camera Plugin</div>
    <div class="btn-grid">
      <button onclick="testTakePhoto()">Take Photo</button>
      <button onclick="testGallery()">Pick Gallery</button>
    </div>
  </div>

  <!-- STORAGE -->
  <div class="card">
    <div class="card-title">Storage Plugin</div>
    <div class="btn-grid">
      <button onclick="testSetStorage()">Set Value</button>
      <button onclick="testGetStorage()">Get Value</button>
      <button onclick="testListKeys()">List Keys</button>
      <button onclick="testRemove()">Remove</button>
    </div>
  </div>

  <!-- GEOLOCATION -->
  <div class="card">
    <div class="card-title">Geolocation Plugin</div>
    <div class="btn-grid">
      <button onclick="testLocation()">Get Location</button>
      <button onclick="testPermission()">Check Permission</button>
    </div>
  </div>

  <!-- BATCH -->
  <div class="card">
    <div class="card-title">Batch and Advanced</div>
    <div class="btn-grid">
      <button onclick="testBatch()">Batch Request</button>
      <button onclick="testParallel()">Parallel Calls</button>
      <button onclick="testTimeout()">Test Timeout</button>
      <button onclick="clearLog()">Clear Log</button>
    </div>
  </div>

  <!-- STATS -->
  <div class="status-bar">
    <div class="status-item">
      Requests: <span id="reqCount">0</span>
    </div>
    <div class="status-item">
      Errors: <span id="errCount">0</span>
    </div>
    <div class="status-item">
      Pending: <span id="pendCount">0</span>
    </div>
  </div>

  <!-- LOG -->
  <div class="card" style="margin-top:16px">
    <div class="card-title">Console Log</div>
    <div class="log-container" id="log"></div>
  </div>
</div>

<script>
  // ============================================================
  // LOG SYSTEM
  // ============================================================

  var errorCount = 0;
  
  function log(msg, type) {
    type = type || 'info';
    var container = document.getElementById('log');
    var entry = document.createElement('div');
    entry.className = 'log-entry ' + type;
    
    var now = new Date();
    var time = now.toLocaleTimeString('en-US', { 
      hour12: false,
      hour: '2-digit',
      minute: '2-digit',
      second: '2-digit'
    });
    
    entry.textContent = '[' + time + '] ' + msg;
    container.insertBefore(entry, container.firstChild);
    
    if (type === 'error') errorCount++;
    updateStats();
  }

  function updateStats() {
    var info = (window.Native && window.Native.info) ? window.Native.info() : {};
    document.getElementById('reqCount').textContent = info.totalRequests || 0;
    document.getElementById('errCount').textContent = errorCount;
    document.getElementById('pendCount').textContent = info.pendingRequests || 0;
  }

  function clearLog() {
    document.getElementById('log').innerHTML = '';
    errorCount = 0;
    updateStats();
  }

  function showProgress(show) {
    var bar = document.getElementById('progress');
    bar.style.width = show ? '60%' : '0%';
  }

  // ============================================================
  // WRAPPER
  // ============================================================

  function callPlugin(plugin, method, args, label) {
    args = args || {};
    var display = label || (plugin + '.' + method);
    log('-> Calling ' + display + '...', 'pending');
    showProgress(true);
    
    return Native.call({ plugin: plugin, method: method, args: args })
      .then(function(result) {
        var text = JSON.stringify(result);
        if (text && text.length > 100) text = text.substring(0, 100) + '...';
        log('OK ' + display + ': ' + text, 'success');
        return result;
      })
      .catch(function(err) {
        var detail = err.message || err.code || JSON.stringify(err);
        log('FAIL ' + display + ': ' + detail, 'error');
        throw err;
      })
      .finally(function() {
        showProgress(false);
        updateStats();
      });
  }

  // ============================================================
  // CAMERA TESTS
  // ============================================================

  function testTakePhoto() {
    callPlugin('camera', 'takePhoto', { quality: 80 });
  }

  function testGallery() {
    callPlugin('camera', 'pickFromGallery', { multiple: false });
  }

  // ============================================================
  // STORAGE TESTS
  // ============================================================

  function testSetStorage() {
    var value = { 
      timestamp: Date.now(), 
      message: 'Hello from JS!',
      data: [1, 2, 3]
    };
    callPlugin('storage', 'set', { key: 'test_key', value: value });
  }

  function testGetStorage() {
    callPlugin('storage', 'get', { key: 'test_key' });
  }

  function testListKeys() {
    callPlugin('storage', 'keys', {});
  }

  function testRemove() {
    callPlugin('storage', 'remove', { key: 'test_key' });
  }

  // ============================================================
  // GEOLOCATION TESTS
  // ============================================================

  function testLocation() {
    callPlugin('geolocation', 'getCurrentPosition', { accuracy: 'high' });
  }

  function testPermission() {
    callPlugin('geolocation', 'checkPermission', {});
  }

  // ============================================================
  // BATCH TESTS
  // ============================================================

  function testBatch() {
    log('-> Sending batch request...', 'pending');
    showProgress(true);
    
    Native.batch([
      { plugin: 'storage', method: 'keys', args: {} },
      { plugin: 'geolocation', method: 'checkPermission', args: {} },
      { plugin: 'camera', method: 'getInfo', args: {} }
    ], { parallel: true })
    .then(function(results) {
      log('OK Batch complete: ' + results.length + ' results', 'success');
      results.forEach(function(r, i) {
        var status = r.success ? 'OK' : 'FAIL';
        var detail = JSON.stringify(r.data || r.error);
        if (detail && detail.length > 80) detail = detail.substring(0, 80) + '...';
        log('  [' + i + '] ' + status + ' ' + detail, r.success ? 'success' : 'error');
      });
    })
    .catch(function(err) {
      log('FAIL Batch failed: ' + JSON.stringify(err), 'error');
    })
    .finally(function() {
      showProgress(false);
      updateStats();
    });
  }

  function testParallel() {
    log('-> Running 5 parallel calls...', 'pending');
    
    var promises = [];
    for (var i = 0; i < 5; i++) {
      (function(idx) {
        promises.push(
          Native.call({ plugin: 'storage', method: 'get', args: { key: 'key_' + idx } })
            .then(function() { return 'OK key_' + idx; })
            .catch(function(e) { return 'FAIL key_' + idx + ': ' + (e.code || ''); })
        );
      })(i);
    }
    
    Promise.allSettled(promises).then(function(results) {
      results.forEach(function(r) {
        log(r.value || r.reason, 'info');
      });
      updateStats();
    });
  }

  function testTimeout() {
    log('-> Testing with 1ms timeout (should fail)...', 'pending');
    
    Native.call({
      plugin: 'geolocation',
      method: 'getCurrentPosition',
      args: {},
      timeout: 1
    })
    .then(function() {
      log('? Unexpectedly succeeded', 'info');
    })
    .catch(function(err) {
      if (err.code === 'TIMEOUT') {
        log('OK Timeout handled correctly: ' + err.message, 'success');
      } else {
        log('? Unexpected error: ' + JSON.stringify(err), 'error');
      }
    })
    .finally(function() {
      updateStats();
    });
  }

  // ============================================================
  // EVENTS
  // ============================================================

  if (window.Native && window.Native.on) {
    Native.on('bridge_event', function(data) {
      log('Event: ' + JSON.stringify(data), 'info');
    });
  }

  // Init
  window.addEventListener('load', function() {
    setTimeout(function() {
      log('Native Bridge initialized', 'success');
      var info = (window.Native && window.Native.info) ? window.Native.info() : {};
      log('Bridge version: ' + JSON.stringify(info), 'info');
      updateStats();
    }, 500);
  });
</script>
</body>
</html>
  ''';
}