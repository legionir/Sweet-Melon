(function() {
  'use strict';

  var errorCount = 0;

  function log(msg, type) {
    type = type || 'info';
    var container = document.getElementById('log');
    if (!container) return;

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

    // حداکثر ۲۰۰ ردیف log
    while (container.children.length > 200) {
      container.removeChild(container.lastChild);
    }

    updateStats();
  }

  function updateStats() {
    var info = {};
    try {
      if (window.Native && window.Native.info) {
        info = window.Native.info();
      }
    } catch (e) {}

    var reqEl = document.getElementById('reqCount');
    var errEl = document.getElementById('errCount');
    var pendEl = document.getElementById('pendCount');

    if (reqEl) reqEl.textContent = info.totalRequests || 0;
    if (errEl) errEl.textContent = errorCount;
    if (pendEl) pendEl.textContent = info.pendingRequests || 0;
  }

  function showProgress(show) {
    var el = document.getElementById('progress');
    if (el) el.style.width = show ? '60%' : '0%';
  }

  function callPlugin(plugin, method, args, label) {
    args = args || {};
    var display = label || (plugin + '.' + method);

    if (!window.Native) {
      log('Bridge not available yet', 'error');
      return Promise.reject('Bridge not available');
    }

    log('→ Calling ' + display + '...', 'pending');
    showProgress(true);

    return Native.call({ plugin: plugin, method: method, args: args })
      .then(function(result) {
        var t = JSON.stringify(result);
        if (t && t.length > 120) t = t.substring(0, 120) + '...';
        log('✓ ' + display + ': ' + t, 'success');
        return result;
      })
      .catch(function(err) {
        var msg = err.message || err.code || JSON.stringify(err);
        log('✗ ' + display + ': ' + msg, 'error');
        throw err;
      })
      .finally(function() {
        showProgress(false);
        updateStats();
      });
  }

  // ----- Camera -----
  window.testTakePhoto = function() {
    callPlugin('camera', 'takePhoto', { quality: 80 });
  };

  window.testGallery = function() {
    callPlugin('camera', 'pickFromGallery', { multiple: false });
  };

  // ----- Storage -----
  window.testSetStorage = function() {
    callPlugin('storage', 'set', {
      key: 'test_key',
      value: {
        timestamp: Date.now(),
        message: 'Hello from JS!',
        data: [1, 2, 3]
      }
    });
  };

  window.testGetStorage = function() {
    callPlugin('storage', 'get', { key: 'test_key' });
  };

  window.testListKeys = function() {
    callPlugin('storage', 'keys', {});
  };

  window.testRemove = function() {
    callPlugin('storage', 'remove', { key: 'test_key' });
  };

  // ----- Geolocation -----
  window.testLocation = function() {
    callPlugin('geolocation', 'getCurrentPosition', { accuracy: 'high' });
  };

  window.testPermission = function() {
    callPlugin('geolocation', 'checkPermission', {});
  };

  // ----- Batch & Advanced -----
  window.testBatch = function() {
    if (!window.Native) {
      log('Bridge not available', 'error');
      return;
    }

    log('→ Sending batch request...', 'pending');
    showProgress(true);

    Native.batch([
      { plugin: 'storage', method: 'keys', args: {} },
      { plugin: 'geolocation', method: 'checkPermission', args: {} },
      { plugin: 'camera', method: 'getInfo', args: {} }
    ], { parallel: true })
      .then(function(results) {
        log('✓ Batch complete: ' + results.length + ' results', 'success');
      })
      .catch(function(err) {
        log('✗ Batch: ' + JSON.stringify(err), 'error');
      })
      .finally(function() {
        showProgress(false);
        updateStats();
      });
  };

  window.testParallel = function() {
    if (!window.Native) {
      log('Bridge not available', 'error');
      return;
    }

    log('→ Running 5 parallel calls...', 'pending');

    var promises = [];
    for (var i = 0; i < 5; i++) {
      (function(idx) {
        promises.push(
          Native.call({
            plugin: 'storage',
            method: 'get',
            args: { key: 'key_' + idx }
          })
            .then(function(r) { return '✓ key_' + idx; })
            .catch(function(e) { return '✗ key_' + idx; })
        );
      })(i);
    }

    Promise.allSettled(promises).then(function(results) {
      results.forEach(function(r) {
        log(r.value || r.reason, 'info');
      });
      updateStats();
    });
  };

  window.testTimeout = function() {
    if (!window.Native) {
      log('Bridge not available', 'error');
      return;
    }

    log('→ Testing with 1ms timeout...', 'pending');

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
          log('✓ Timeout handled correctly', 'success');
        } else {
          log('? Unexpected error: ' + JSON.stringify(err), 'error');
        }
      })
      .finally(function() {
        updateStats();
      });
  };

  window.clearLog = function() {
    var container = document.getElementById('log');
    if (container) container.innerHTML = '';
    errorCount = 0;
    updateStats();
  };

  // ----- Event listener -----
  function setupEventListeners() {
    if (window.Native && window.Native.on) {
      Native.on('geolocation.position', function(data) {
        log('📍 Position: ' + data.latitude.toFixed(4) + ', ' + data.longitude.toFixed(4), 'info');
      });

      Native.on('geolocation.error', function(data) {
        log('📍 Error: ' + data.message, 'error');
      });

      Native.on('bridge_event', function(data) {
        log('🔔 Event: ' + JSON.stringify(data), 'info');
      });
    }
  }

  // ----- Init -----
  function init() {
    // منتظر bridge آماده شدن
    var attempts = 0;
    var maxAttempts = 50;

    var check = setInterval(function() {
      attempts++;

      if (window.Native) {
        clearInterval(check);
        setupEventListeners();
        log('Native Bridge initialized (' + attempts * 100 + 'ms)', 'success');
        updateStats();
      } else if (attempts >= maxAttempts) {
        clearInterval(check);
        log('Bridge initialization timeout', 'error');
      }
    }, 100);
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
  } else {
    init();
  }

})();
