(function () {
  'use strict';

  var outputEl;
  var logEl;
  var requestCount = 0;
  var eventCount = 0;

  function $(id) {
    return document.getElementById(id);
  }

  function updateBridgeStats() {
    var info = window.NativeSDK ? window.NativeSDK.info() : null;
    $('bridgeState').textContent = info && info.initialized ? 'Ready' : 'Waiting...';
    $('requestCount').textContent = String(info ? info.totalRequests : requestCount);
    $('pendingCount').textContent = String(info ? info.pendingRequests : 0);
    $('eventCount').textContent = String(eventCount);
  }

  function log(message, type) {
    type = type || 'info';

    var item = document.createElement('div');
    item.className = 'log-item log-' + type;

    var now = new Date();
    var time = now.toLocaleTimeString('en-US', {
      hour12: false,
      hour: '2-digit',
      minute: '2-digit',
      second: '2-digit'
    });

    item.textContent = '[' + time + '] ' + message;
    logEl.prepend(item);

    while (logEl.children.length > 250) {
      logEl.removeChild(logEl.lastChild);
    }
  }

  function showOutput(data) {
    outputEl.textContent = JSON.stringify(data, null, 2);
  }

  async function run(label, fn) {
    requestCount += 1;
    updateBridgeStats();
    log('→ ' + label, 'info');

    try {
      var result = await fn();
      showOutput(result);
      log('✓ ' + label, 'success');
      updateBridgeStats();
      return result;
    } catch (err) {
      var msg = err && err.message ? err.message : JSON.stringify(err);
      showOutput({ error: msg, raw: err });
      log('✗ ' + label + ' — ' + msg, 'error');
      updateBridgeStats();
      throw err;
    }
  }

  function parseJsonMaybe(value) {
    if (!value || !value.trim()) return null;
    try {
      return JSON.parse(value);
    } catch (_) {
      return value;
    }
  }

  function bindEvents() {
    // Header
    $('btnBridgeInfo').addEventListener('click', function () {
      showOutput(window.NativeSDK.info());
      updateBridgeStats();
    });

    $('btnClearLog').addEventListener('click', function () {
      logEl.innerHTML = '';
      eventCount = 0;
      updateBridgeStats();
    });

    // Permission
    $('btnPermissionCheck').addEventListener('click', function () {
      run('permission.check', function () {
        return window.NativeSDK.permission.check($('permissionName').value.trim());
      });
    });

    $('btnPermissionRequest').addEventListener('click', function () {
      run('permission.request', function () {
        return window.NativeSDK.permission.request($('permissionName').value.trim());
      });
    });

    $('btnPermissionKnown').addEventListener('click', function () {
      run('permission.getKnownPermissions', function () {
        return window.NativeSDK.permission.getKnownPermissions();
      });
    });

    // App Lifecycle
    $('btnLifecycleState').addEventListener('click', function () {
      run('appLifecycle.getState', function () {
        return window.NativeSDK.appLifecycle.getState();
      });
    });

    $('btnLifecycleEnable').addEventListener('click', function () {
      run('appLifecycle.enableEvents', function () {
        return window.NativeSDK.appLifecycle.enableEvents();
      });
    });

    $('btnLifecycleDisable').addEventListener('click', function () {
      run('appLifecycle.disableEvents', function () {
        return window.NativeSDK.appLifecycle.disableEvents();
      });
    });

    $('btnLifecycleInfo').addEventListener('click', function () {
      run('appLifecycle.getInfo', function () {
        return window.NativeSDK.appLifecycle.getInfo();
      });
    });

    // Device Info
    $('btnDeviceInfo').addEventListener('click', function () {
      run('deviceInfo.getDeviceInfo', function () {
        return window.NativeSDK.deviceInfo.getDeviceInfo();
      });
    });

    $('btnAppInfo').addEventListener('click', function () {
      run('deviceInfo.getAppInfo', function () {
        return window.NativeSDK.deviceInfo.getAppInfo();
      });
    });

    $('btnDeviceAll').addEventListener('click', function () {
      run('deviceInfo.getAll', function () {
        return window.NativeSDK.deviceInfo.getAll();
      });
    });

    // Connectivity
    $('btnConnectivityStatus').addEventListener('click', function () {
      run('connectivity.getStatus', function () {
        return window.NativeSDK.connectivity.getStatus();
      });
    });

    $('btnConnectivityStart').addEventListener('click', function () {
      run('connectivity.startWatch', function () {
        return window.NativeSDK.connectivity.startWatch();
      });
    });

    $('btnConnectivityStop').addEventListener('click', function () {
      run('connectivity.stopWatch', function () {
        return window.NativeSDK.connectivity.stopWatch();
      });
    });

    $('btnConnectivityIsOnline').addEventListener('click', function () {
      run('connectivity.isOnline', function () {
        return window.NativeSDK.connectivity.isOnline();
      });
    });

    // Storage
    $('btnStorageSet').addEventListener('click', function () {
      run('storage.set', function () {
        var key = $('storageKey').value.trim();
        var value = parseJsonMaybe($('storageValue').value);
        return window.NativeSDK.storage.set(key, value);
      });
    });

    $('btnStorageGet').addEventListener('click', function () {
      run('storage.get', function () {
        return window.NativeSDK.storage.get($('storageKey').value.trim());
      });
    });

    $('btnStorageHas').addEventListener('click', function () {
      run('storage.has', function () {
        return window.NativeSDK.storage.has($('storageKey').value.trim());
      });
    });

    $('btnStorageKeys').addEventListener('click', function () {
      run('storage.keys', function () {
        return window.NativeSDK.storage.keys();
      });
    });

    $('btnStorageRemove').addEventListener('click', function () {
      run('storage.remove', function () {
        return window.NativeSDK.storage.remove($('storageKey').value.trim());
      });
    });

    $('btnStorageClear').addEventListener('click', function () {
      run('storage.clear', function () {
        return window.NativeSDK.storage.clear();
      });
    });

    // File System
    $('btnFsDirs').addEventListener('click', function () {
      run('fileSystem.getDirectories', function () {
        return window.NativeSDK.fileSystem.getDirectories();
      });
    });

    $('btnFsWrite').addEventListener('click', function () {
      run('fileSystem.writeFile', function () {
        return window.NativeSDK.fileSystem.writeFile(
          $('filePath').value.trim(),
          $('fileContent').value
        );
      });
    });

    $('btnFsRead').addEventListener('click', function () {
      run('fileSystem.readFile', function () {
        return window.NativeSDK.fileSystem.readFile($('filePath').value.trim());
      });
    });

    $('btnFsExists').addEventListener('click', function () {
      run('fileSystem.fileExists', function () {
        return window.NativeSDK.fileSystem.fileExists($('filePath').value.trim());
      });
    });

    $('btnFsList').addEventListener('click', function () {
      run('fileSystem.listFiles', function () {
        return window.NativeSDK.fileSystem.listFiles('demo', { recursive: true });
      });
    });

    $('btnFsStat').addEventListener('click', function () {
      run('fileSystem.stat', function () {
        return window.NativeSDK.fileSystem.stat($('filePath').value.trim(), { type: 'file' });
      });
    });

    $('btnFsDelete').addEventListener('click', function () {
      run('fileSystem.deleteFile', function () {
        return window.NativeSDK.fileSystem.deleteFile($('filePath').value.trim());
      });
    });

    // HTTP
    $('btnHttpGet').addEventListener('click', function () {
      run('http.get', function () {
        return window.NativeSDK.http.get($('httpUrl').value.trim(), {
          responseType: 'json'
        });
      });
    });

    $('btnHttpPost').addEventListener('click', function () {
      run('http.post', function () {
        return window.NativeSDK.http.post(
          'https://jsonplaceholder.typicode.com/posts',
          {
            title: 'sweetmelon',
            body: 'native post body',
            userId: 1
          },
          {
            bodyType: 'json',
            responseType: 'json',
            headers: {
              'content-type': 'application/json'
            }
          }
        );
      });
    });

    $('btnHttpDownload').addEventListener('click', function () {
      run('http.download', function () {
        return window.NativeSDK.http.download({
          url: 'https://jsonplaceholder.typicode.com/todos/1',
          fileName: 'todo-1.json',
          baseDir: 'temporary'
        });
      });
    });

    // Intent
    $('btnIntentCanOpen').addEventListener('click', function () {
      run('intent.canOpenUrl', function () {
        return window.NativeSDK.intent.canOpenUrl($('intentUrl').value.trim());
      });
    });

    $('btnIntentOpen').addEventListener('click', function () {
      run('intent.openUrl', function () {
        return window.NativeSDK.intent.openUrl($('intentUrl').value.trim(), 'external');
      });
    });

    $('btnIntentInitial').addEventListener('click', function () {
      run('intent.getInitialLink', function () {
        return window.NativeSDK.intent.getInitialLink();
      });
    });

    $('btnIntentLatest').addEventListener('click', function () {
      run('intent.getLatestLink', function () {
        return window.NativeSDK.intent.getLatestLink();
      });
    });

    $('btnIntentListenStart').addEventListener('click', function () {
      run('intent.startListening', function () {
        return window.NativeSDK.intent.startListening();
      });
    });

    $('btnIntentListenStop').addEventListener('click', function () {
      run('intent.stopListening', function () {
        return window.NativeSDK.intent.stopListening();
      });
    });

    // Clipboard
    $('btnClipboardWrite').addEventListener('click', function () {
      run('clipboard.writeText', function () {
        return window.NativeSDK.clipboard.writeText($('clipboardText').value);
      });
    });

    $('btnClipboardRead').addEventListener('click', function () {
      run('clipboard.readText', function () {
        return window.NativeSDK.clipboard.readText();
      });
    });

    $('btnClipboardHas').addEventListener('click', function () {
      run('clipboard.hasText', function () {
        return window.NativeSDK.clipboard.hasText();
      });
    });

    $('btnClipboardClear').addEventListener('click', function () {
      run('clipboard.clear', function () {
        return window.NativeSDK.clipboard.clear();
      });
    });

    // Share
    $('btnShareText').addEventListener('click', function () {
      run('share.shareText', function () {
        return window.NativeSDK.share.shareText($('shareText').value, 'Sweetmelon');
      });
    });

    $('btnShareFile').addEventListener('click', async function () {
      await run('fileSystem.writeFile (prepare share file)', function () {
        return window.NativeSDK.fileSystem.writeFile(
          'share/demo-share.txt',
          'Shared from Sweetmelon WebView at ' + new Date().toISOString()
        );
      });

      await run('fileSystem.getDirectories', function () {
        return window.NativeSDK.fileSystem.getDirectories();
      }).then(function (dirs) {
        var fullPath = (dirs.documents || '') + '/share/demo-share.txt';

        return run('share.shareFiles', function () {
          return window.NativeSDK.share.shareFiles(
            [fullPath],
            'Sharing created file from Native Bridge',
            'Sweetmelon File Share'
          );
        });
      });
    });

    // Camera
    $('btnCameraInfo').addEventListener('click', function () {
      run('camera.getInfo', function () {
        return window.NativeSDK.camera.getInfo();
      });
    });

    $('btnTakePhoto').addEventListener('click', function () {
      run('camera.takePhoto', function () {
        return window.NativeSDK.camera.takePhoto({
          quality: 80
        });
      });
    });

    $('btnPickGallery').addEventListener('click', function () {
      run('camera.pickFromGallery', function () {
        return window.NativeSDK.camera.pickFromGallery({
          multiple: false
        });
      });
    });

    // Geolocation
    $('btnGeoPermission').addEventListener('click', function () {
      run('geolocation.checkPermission', function () {
        return window.NativeSDK.geolocation.checkPermission();
      });
    });

    $('btnGeoRequestPermission').addEventListener('click', function () {
      run('geolocation.requestPermission', function () {
        return window.NativeSDK.geolocation.requestPermission();
      });
    });

    $('btnGeoCurrent').addEventListener('click', function () {
      run('geolocation.getCurrentPosition', function () {
        return window.NativeSDK.geolocation.getCurrentPosition({
          accuracy: 'high'
        });
      });
    });

    $('btnGeoStart').addEventListener('click', function () {
      run('geolocation.watchPosition', function () {
        return window.NativeSDK.geolocation.watchPosition({
          accuracy: 'high',
          distanceFilter: 10
        });
      });
    });

    $('btnGeoStop').addEventListener('click', function () {
      run('geolocation.clearWatch', function () {
        return window.NativeSDK.geolocation.clearWatch();
      });
    });

    $('btnGeoEnabled').addEventListener('click', function () {
      run('geolocation.isLocationEnabled', function () {
        return window.NativeSDK.geolocation.isLocationEnabled();
      });
    });
  }

  function bindNativeEvents() {
    var unsubscribers = [];

    unsubscribers.push(
      window.NativeSDK.on('app.lifecycle.change', function (data) {
        eventCount += 1;
        log('EVENT app.lifecycle.change → ' + JSON.stringify(data), 'event');
        updateBridgeStats();
      })
    );

    unsubscribers.push(
      window.NativeSDK.on('connectivity.change', function (data) {
        eventCount += 1;
        log('EVENT connectivity.change → ' + JSON.stringify(data), 'event');
        updateBridgeStats();
      })
    );

    unsubscribers.push(
      window.NativeSDK.on('connectivity.error', function (data) {
        eventCount += 1;
        log('EVENT connectivity.error → ' + JSON.stringify(data), 'error');
        updateBridgeStats();
      })
    );

    unsubscribers.push(
      window.NativeSDK.on('intent.deepLink', function (data) {
        eventCount += 1;
        log('EVENT intent.deepLink → ' + JSON.stringify(data), 'event');
        updateBridgeStats();
      })
    );

    unsubscribers.push(
      window.NativeSDK.on('intent.error', function (data) {
        eventCount += 1;
        log('EVENT intent.error → ' + JSON.stringify(data), 'error');
        updateBridgeStats();
      })
    );

    unsubscribers.push(
      window.NativeSDK.on('geolocation.position', function (data) {
        eventCount += 1;
        log(
          'EVENT geolocation.position → ' +
            data.latitude +
            ', ' +
            data.longitude,
          'event'
        );
        updateBridgeStats();
      })
    );

    unsubscribers.push(
      window.NativeSDK.on('geolocation.error', function (data) {
        eventCount += 1;
        log('EVENT geolocation.error → ' + JSON.stringify(data), 'error');
        updateBridgeStats();
      })
    );

    window.__nativeSdkUnsubscribers = unsubscribers;
  }

  async function init() {
    outputEl = $('output');
    logEl = $('log');

    updateBridgeStats();
    log('Initializing NativeSDK...', 'info');

    try {
      await window.NativeSDK.waitForReady(10000);
      log('NativeSDK is ready', 'success');
      updateBridgeStats();

      bindEvents();
      bindNativeEvents();

      try {
        await window.NativeSDK.connectivity.startWatch();
      } catch (_) {}

      try {
        await window.NativeSDK.intent.startListening();
      } catch (_) {}
    } catch (err) {
      log('Bridge init failed: ' + err.message, 'error');
      showOutput({ error: err.message });
    }
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
  } else {
    init();
  }
})();
