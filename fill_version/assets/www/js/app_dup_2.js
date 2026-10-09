(function () {
  'use strict';

  var outputEl, logEl, requestCount = 0, eventCount = 0;

  function $(id) { return document.getElementById(id); }

  function updateStats() {
    var info = window.NativeSDK ? window.NativeSDK.info() : null;
    $('bridgeState').textContent = info && info.initialized ? 'Ready' : 'Waiting...';
    $('requestCount').textContent = String(info ? info.totalRequests : requestCount);
    $('pendingCount').textContent = String(info ? info.pendingRequests : 0);
    $('eventCount').textContent = String(eventCount);
  }

  function log(msg, type) {
    type = type || 'info';
    var item = document.createElement('div');
    item.className = 'log-item log-' + type;
    var now = new Date();
    var t = now.toLocaleTimeString('en-US', { hour12: false, hour: '2-digit', minute: '2-digit', second: '2-digit' });
    item.textContent = '[' + t + '] ' + msg;
    logEl.prepend(item);
    while (logEl.children.length > 300) logEl.removeChild(logEl.lastChild);
  }

  function show(data) { outputEl.textContent = JSON.stringify(data, null, 2); }

  function parseJ(v) { if (!v || !v.trim()) return null; try { return JSON.parse(v); } catch (_) { return v; } }

  async function run(label, fn) {
    requestCount++; updateStats(); log('→ ' + label, 'info');
    try {
      var r = await fn(); show(r); log('✓ ' + label, 'success'); updateStats(); return r;
    } catch (e) {
      var m = e && e.message ? e.message : JSON.stringify(e);
      show({ error: m, raw: e }); log('✗ ' + label + ' — ' + m, 'error'); updateStats(); throw e;
    }
  }

  function bind() {
    var S = window.NativeSDK;

    // Header
    $('btnBridgeInfo').onclick = function () { show(S.info()); updateStats(); };
    $('btnClearLog').onclick = function () { logEl.innerHTML = ''; eventCount = 0; updateStats(); };
    $('btnBatchTest').onclick = function () {
      run('batch test (4 calls)', function () {
        return S.batch([
          { plugin: 'storage', method: 'keys', args: {} },
          { plugin: 'deviceInfo', method: 'getAppInfo', args: {} },
          { plugin: 'connectivity', method: 'getStatus', args: {} },
          { plugin: 'clipboard', method: 'hasText', args: {} }
        ], { parallel: true });
      });
    };

    // Permission
    $('btnPermissionCheck').onclick = function () { run('permission.check', function () { return S.permission.check($('permissionName').value.trim()); }); };
    $('btnPermissionRequest').onclick = function () { run('permission.request', function () { return S.permission.request($('permissionName').value.trim()); }); };
    $('btnPermissionKnown').onclick = function () { run('permission.known', function () { return S.permission.getKnownPermissions(); }); };
    $('btnPermissionSettings').onclick = function () { run('permission.settings', function () { return S.permission.openSettings(); }); };

    // App Lifecycle
    $('btnLifecycleState').onclick = function () { run('appLifecycle.getState', function () { return S.appLifecycle.getState(); }); };
    $('btnLifecycleEnable').onclick = function () { run('appLifecycle.enable', function () { return S.appLifecycle.enableEvents(); }); };
    $('btnLifecycleDisable').onclick = function () { run('appLifecycle.disable', function () { return S.appLifecycle.disableEvents(); }); };
    $('btnLifecycleInfo').onclick = function () { run('appLifecycle.info', function () { return S.appLifecycle.getInfo(); }); };

    // Device
    $('btnDeviceInfo').onclick = function () { run('deviceInfo', function () { return S.deviceInfo.getDeviceInfo(); }); };
    $('btnAppInfo').onclick = function () { run('appInfo', function () { return S.deviceInfo.getAppInfo(); }); };
    $('btnDeviceAll').onclick = function () { run('deviceAll', function () { return S.deviceInfo.getAll(); }); };

    // Connectivity
    $('btnConnectivityStatus').onclick = function () { run('connectivity.status', function () { return S.connectivity.getStatus(); }); };
    $('btnConnectivityStart').onclick = function () { run('connectivity.start', function () { return S.connectivity.startWatch(); }); };
    $('btnConnectivityStop').onclick = function () { run('connectivity.stop', function () { return S.connectivity.stopWatch(); }); };
    $('btnConnectivityIsOnline').onclick = function () { run('connectivity.online', function () { return S.connectivity.isOnline(); }); };

    // Storage
    $('btnStorageSet').onclick = function () { run('storage.set', function () { return S.storage.set($('storageKey').value.trim(), parseJ($('storageValue').value)); }); };
    $('btnStorageGet').onclick = function () { run('storage.get', function () { return S.storage.get($('storageKey').value.trim()); }); };
    $('btnStorageHas').onclick = function () { run('storage.has', function () { return S.storage.has($('storageKey').value.trim()); }); };
    $('btnStorageKeys').onclick = function () { run('storage.keys', function () { return S.storage.keys(); }); };
    $('btnStorageRemove').onclick = function () { run('storage.remove', function () { return S.storage.remove($('storageKey').value.trim()); }); };
    $('btnStorageClear').onclick = function () { run('storage.clear', function () { return S.storage.clear(); }); };

    // FileSystem
    $('btnFsDirs').onclick = function () { run('fs.dirs', function () { return S.fileSystem.getDirectories(); }); };
    $('btnFsWrite').onclick = function () { run('fs.write', function () { return S.fileSystem.writeFile($('filePath').value.trim(), $('fileContent').value); }); };
    $('btnFsRead').onclick = function () { run('fs.read', function () { return S.fileSystem.readFile($('filePath').value.trim()); }); };
    $('btnFsExists').onclick = function () { run('fs.exists', function () { return S.fileSystem.fileExists($('filePath').value.trim()); }); };
    $('btnFsList').onclick = function () { run('fs.list', function () { return S.fileSystem.listFiles('demo', { recursive: true }); }); };
    $('btnFsStat').onclick = function () { run('fs.stat', function () { return S.fileSystem.stat($('filePath').value.trim()); }); };
    $('btnFsDelete').onclick = function () { run('fs.delete', function () { return S.fileSystem.deleteFile($('filePath').value.trim()); }); };

    // HTTP
    $('btnHttpGet').onclick = function () { run('http.get', function () { return S.http.get($('httpUrl').value.trim(), { responseType: 'json' }); }); };
    $('btnHttpPost').onclick = function () { run('http.post', function () { return S.http.post('https://jsonplaceholder.typicode.com/posts', { title: 'sweetmelon', body: 'post body', userId: 1 }, { bodyType: 'json', responseType: 'json' }); }); };
    $('btnHttpDownload').onclick = function () { run('http.download', function () { return S.http.download({ url: 'https://jsonplaceholder.typicode.com/todos/1', fileName: 'todo.json', baseDir: 'temporary' }); }); };

    // Intent
    $('btnIntentCanOpen').onclick = function () { run('intent.canOpen', function () { return S.intent.canOpenUrl($('intentUrl').value.trim()); }); };
    $('btnIntentOpen').onclick = function () { run('intent.open', function () { return S.intent.openUrl($('intentUrl').value.trim()); }); };
    $('btnIntentInitial').onclick = function () { run('intent.initial', function () { return S.intent.getInitialLink(); }); };
    $('btnIntentLatest').onclick = function () { run('intent.latest', function () { return S.intent.getLatestLink(); }); };
    $('btnIntentListenStart').onclick = function () { run('intent.listen', function () { return S.intent.startListening(); }); };
    $('btnIntentListenStop').onclick = function () { run('intent.stopListen', function () { return S.intent.stopListening(); }); };

    // Clipboard
    $('btnClipboardWrite').onclick = function () { run('clipboard.write', function () { return S.clipboard.writeText($('clipboardText').value); }); };
    $('btnClipboardRead').onclick = function () { run('clipboard.read', function () { return S.clipboard.readText(); }); };
    $('btnClipboardHas').onclick = function () { run('clipboard.has', function () { return S.clipboard.hasText(); }); };
    $('btnClipboardClear').onclick = function () { run('clipboard.clear', function () { return S.clipboard.clear(); }); };

    // Share
    $('btnShareText').onclick = function () { run('share.text', function () { return S.share.shareText($('shareText').value, 'Sweetmelon'); }); };
    $('btnShareFile').onclick = async function () {
      await run('fs.write (prep share)', function () { return S.fileSystem.writeFile('share/demo.txt', 'Share file at ' + new Date().toISOString()); });
      var dirs = await run('fs.dirs', function () { return S.fileSystem.getDirectories(); });
      await run('share.files', function () { return S.share.shareFiles([(dirs.documents || '') + '/share/demo.txt'], 'Shared file', 'Sweetmelon'); });
    };

    // Camera
    $('btnCameraInfo').onclick = function () { run('camera.info', function () { return S.camera.getInfo(); }); };
    $('btnTakePhoto').onclick = function () { run('camera.photo', function () { return S.camera.takePhoto({ quality: 80 }); }); };
    $('btnPickGallery').onclick = function () { run('camera.gallery', function () { return S.camera.pickFromGallery({ multiple: false }); }); };

    // Geolocation
    $('btnGeoPermission').onclick = function () { run('geo.checkPerm', function () { return S.geolocation.checkPermission(); }); };
    $('btnGeoRequestPermission').onclick = function () { run('geo.requestPerm', function () { return S.geolocation.requestPermission(); }); };
    $('btnGeoCurrent').onclick = function () { run('geo.current', function () { return S.geolocation.getCurrentPosition({ accuracy: 'high' }); }); };
    $('btnGeoStart').onclick = function () { run('geo.watch', function () { return S.geolocation.watchPosition({ accuracy: 'high', distanceFilter: 10 }); }); };
    $('btnGeoStop').onclick = function () { run('geo.stop', function () { return S.geolocation.clearWatch(); }); };
    $('btnGeoEnabled').onclick = function () { run('geo.enabled', function () { return S.geolocation.isLocationEnabled(); }); };

    // ── فاز ۳ ──

    // Back Button
    $('btnBackEnable').onclick = function () { run('back.enableIntercept', function () { return S.backButton.enableIntercept(); }); };
    $('btnBackDisable').onclick = function () { run('back.disableIntercept', function () { return S.backButton.disableIntercept(); }); };
    $('btnBackState').onclick = function () { run('back.state', function () { return S.backButton.getState(); }); };
    $('btnBackExitOnBack').onclick = function () { run('back.exitOnBack', function () { return S.backButton.setExitOnBack(true); }); };
    $('btnBackMinimize').onclick = function () { run('back.minimize', function () { return S.backButton.minimizeApp(); }); };
    $('btnBackExit').onclick = function () { run('back.exit', function () { return S.backButton.exitApp(); }); };

    // Secure Storage
    $('btnSecSet').onclick = function () { run('sec.set', function () { return S.secureStorage.set($('secKey').value.trim(), $('secValue').value); }); };
    $('btnSecGet').onclick = function () { run('sec.get', function () { return S.secureStorage.get($('secKey').value.trim()); }); };
    $('btnSecHas').onclick = function () { run('sec.has', function () { return S.secureStorage.has($('secKey').value.trim()); }); };
    $('btnSecKeys').onclick = function () { run('sec.keys', function () { return S.secureStorage.keys(); }); };
    $('btnSecRemove').onclick = function () { run('sec.remove', function () { return S.secureStorage.remove($('secKey').value.trim()); }); };
    $('btnSecClear').onclick = function () { run('sec.clear', function () { return S.secureStorage.clear(); }); };
    $('btnSecInfo').onclick = function () { run('sec.info', function () { return S.secureStorage.getInfo(); }); };

    // Notification
    $('btnNotifShow').onclick = function () { run('notif.show', function () { return S.notification.show({ title: $('notifTitle').value, body: $('notifBody').value, payload: 'custom-payload-123' }); }); };
    $('btnNotifCancelAll').onclick = function () { run('notif.cancelAll', function () { return S.notification.cancelAll(); }); };
    $('btnNotifActive').onclick = function () { run('notif.active', function () { return S.notification.getActive(); }); };
    $('btnNotifPending').onclick = function () { run('notif.pending', function () { return S.notification.getPending(); }); };
    $('btnNotifChannel').onclick = function () { run('notif.channel', function () { return S.notification.createChannel({ channelId: 'alerts', channelName: 'Alerts', importance: 'high' }); }); };
    $('btnNotifInfo').onclick = function () { run('notif.info', function () { return S.notification.getInfo(); }); };

    // Status Bar
    $('btnSbDark').onclick = function () { run('sb.dark', function () { return S.statusBar.setStyle('dark'); }); };
    $('btnSbLight').onclick = function () { run('sb.light', function () { return S.statusBar.setStyle('light'); }); };
    $('btnSbHide').onclick = function () { run('sb.hide', function () { return S.statusBar.hide(); }); };
    $('btnSbShow').onclick = function () { run('sb.show', function () { return S.statusBar.show(); }); };
    $('btnSbFullscreen').onclick = function () { run('sb.fullscreen', function () { return S.statusBar.setFullscreen(); }); };
    $('btnSbExitFs').onclick = function () { run('sb.exitFs', function () { return S.statusBar.exitFullscreen(); }); };

    // Orientation
    $('btnOrPortrait').onclick = function () { run('or.portrait', function () { return S.orientation.lock('portrait'); }); };
    $('btnOrLandscape').onclick = function () { run('or.landscape', function () { return S.orientation.lock('landscape'); }); };
    $('btnOrUnlock').onclick = function () { run('or.unlock', function () { return S.orientation.unlock(); }); };
    $('btnOrInfo').onclick = function () { run('or.info', function () { return S.orientation.getInfo(); }); };

    // Haptic
    $('btnHapLight').onclick = function () { run('hap.light', function () { return S.haptic.lightImpact(); }); };
    $('btnHapMedium').onclick = function () { run('hap.medium', function () { return S.haptic.mediumImpact(); }); };
    $('btnHapHeavy').onclick = function () { run('hap.heavy', function () { return S.haptic.heavyImpact(); }); };
    $('btnHapClick').onclick = function () { run('hap.click', function () { return S.haptic.selectionClick(); }); };
    $('btnHapVibrate').onclick = function () { run('hap.vibrate', function () { return S.haptic.vibrate(); }); };

    // Keyboard
    $('btnKbState').onclick = function () { run('kb.state', function () { return S.keyboard.getState(); }); };
    $('btnKbWatch').onclick = function () { run('kb.watch', function () { return S.keyboard.startWatch(); }); };
    $('btnKbStopWatch').onclick = function () { run('kb.stopWatch', function () { return S.keyboard.stopWatch(); }); };
    $('btnKbHide').onclick = function () { run('kb.hide', function () { return S.keyboard.hide(); }); };
    $('btnKbInfo').onclick = function () { run('kb.info', function () { return S.keyboard.getInfo(); }); };
  }

  function bindEvents() {
    var S = window.NativeSDK;

    var events = [
      'app.lifecycle.change',
      'connectivity.change',
      'connectivity.error',
      'intent.deepLink',
      'intent.error',
      'geolocation.position',
      'geolocation.error',
      'backButton.pressed',
      'notification.tap',
      'keyboard.change'
    ];

    events.forEach(function (ev) {
      S.on(ev, function (data) {
        eventCount++;
        log('EVENT ' + ev + ' → ' + JSON.stringify(data), 'event');
        updateStats();
      });
    });
  }

  async function init() {
    outputEl = $('output');
    logEl = $('log');
    updateStats();
    log('Initializing NativeSDK...', 'info');

    try {
      await window.NativeSDK.waitForReady(10000);
      log('NativeSDK ready', 'success');
      updateStats();
      bind();
      bindEvents();

      try { await window.NativeSDK.connectivity.startWatch(); } catch (_) {}
      try { await window.NativeSDK.intent.startListening(); } catch (_) {}
      try { await window.NativeSDK.keyboard.startWatch(); } catch (_) {}
    } catch (e) {
      log('Init failed: ' + e.message, 'error');
      show({ error: e.message });
    }
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
  } else {
    init();
  }
})();
