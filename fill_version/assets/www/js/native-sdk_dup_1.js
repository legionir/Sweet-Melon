(function (global) {
  'use strict';

  function assertBridge() {
    if (!global.Native || typeof global.Native.call !== 'function') {
      throw new Error('Native bridge is not ready');
    }
  }

  function call(plugin, method, args, extra) {
    assertBridge();
    return global.Native.call(
      Object.assign({ plugin: plugin, method: method, args: args || {} }, extra || {})
    );
  }

  function batch(requests, options) {
    assertBridge();
    return global.Native.batch(requests, options || {});
  }

  function on(event, callback) {
    assertBridge();
    return global.Native.on(event, callback);
  }

  function off(event, callback) {
    assertBridge();
    return global.Native.off(event, callback);
  }

  function info() {
    if (!global.Native || !global.Native.info) {
      return { initialized: false, pendingRequests: 0, totalRequests: 0, version: null };
    }
    return global.Native.info();
  }

  function waitForReady(timeoutMs) {
    var timeout = typeof timeoutMs === 'number' ? timeoutMs : 8000;
    return new Promise(function (resolve, reject) {
      if (global.Native && typeof global.Native.call === 'function') {
        resolve(info());
        return;
      }
      var elapsed = 0;
      var step = 50;
      var timer = setInterval(function () {
        elapsed += step;
        if (global.Native && typeof global.Native.call === 'function') {
          clearInterval(timer);
          resolve(info());
          return;
        }
        if (elapsed >= timeout) {
          clearInterval(timer);
          reject(new Error('Native bridge ready timeout'));
        }
      }, step);
    });
  }

  var sdk = {
    call: call,
    batch: batch,
    on: on,
    off: off,
    info: info,
    waitForReady: waitForReady,

    /* ───── فاز ۱ ───── */

    permission: {
      check: function (p) { return call('permission', 'check', { permission: p }); },
      request: function (p) { return call('permission', 'request', { permission: p }); },
      checkMany: function (ps) { return call('permission', 'checkMany', { permissions: ps }); },
      requestMany: function (ps) { return call('permission', 'requestMany', { permissions: ps }); },
      openSettings: function () { return call('permission', 'openSettings', {}); },
      getKnownPermissions: function () { return call('permission', 'getKnownPermissions', {}); }
    },

    appLifecycle: {
      getState: function () { return call('appLifecycle', 'getState', {}); },
      enableEvents: function () { return call('appLifecycle', 'enableEvents', {}); },
      disableEvents: function () { return call('appLifecycle', 'disableEvents', {}); },
      getInfo: function () { return call('appLifecycle', 'getInfo', {}); }
    },

    deviceInfo: {
      getDeviceInfo: function () { return call('deviceInfo', 'getDeviceInfo', {}); },
      getAppInfo: function () { return call('deviceInfo', 'getAppInfo', {}); },
      getAll: function () { return call('deviceInfo', 'getAll', {}); }
    },

    connectivity: {
      getStatus: function () { return call('connectivity', 'getStatus', {}); },
      isOnline: function () { return call('connectivity', 'isOnline', {}); },
      startWatch: function () { return call('connectivity', 'startWatch', {}); },
      stopWatch: function () { return call('connectivity', 'stopWatch', {}); },
      getInfo: function () { return call('connectivity', 'getInfo', {}); }
    },

    storage: {
      get: function (k) { return call('storage', 'get', { key: k }); },
      set: function (k, v) { return call('storage', 'set', { key: k, value: v }); },
      remove: function (k) { return call('storage', 'remove', { key: k }); },
      clear: function () { return call('storage', 'clear', {}); },
      keys: function () { return call('storage', 'keys', {}); },
      has: function (k) { return call('storage', 'has', { key: k }); }
    },

    fileSystem: {
      getDirectories: function () { return call('fileSystem', 'getDirectories', {}); },
      readFile: function (p, b, e) { return call('fileSystem', 'readFile', { path: p, baseDir: b || 'documents', encoding: e || 'utf8' }); },
      writeFile: function (p, c, o) { o = o || {}; return call('fileSystem', 'writeFile', { path: p, content: c, baseDir: o.baseDir || 'documents', encoding: o.encoding || 'utf8', append: !!o.append }); },
      deleteFile: function (p, b) { return call('fileSystem', 'deleteFile', { path: p, baseDir: b || 'documents' }); },
      fileExists: function (p, b) { return call('fileSystem', 'fileExists', { path: p, baseDir: b || 'documents' }); },
      listFiles: function (p, o) { o = o || {}; return call('fileSystem', 'listFiles', { path: p || '', baseDir: o.baseDir || 'documents', recursive: !!o.recursive }); },
      createDirectory: function (p, o) { o = o || {}; return call('fileSystem', 'createDirectory', { path: p, baseDir: o.baseDir || 'documents', recursive: o.recursive !== false }); },
      deleteDirectory: function (p, o) { o = o || {}; return call('fileSystem', 'deleteDirectory', { path: p, baseDir: o.baseDir || 'documents', recursive: !!o.recursive }); },
      stat: function (p, o) { o = o || {}; return call('fileSystem', 'stat', { path: p, baseDir: o.baseDir || 'documents', type: o.type || 'file' }); }
    },

    http: {
      request: function (o) { return call('http', 'request', o || {}); },
      get: function (u, o) { return call('http', 'get', Object.assign({ url: u }, o || {})); },
      post: function (u, b, o) { return call('http', 'post', Object.assign({ url: u, body: b }, o || {})); },
      put: function (u, b, o) { return call('http', 'put', Object.assign({ url: u, body: b }, o || {})); },
      patch: function (u, b, o) { return call('http', 'patch', Object.assign({ url: u, body: b }, o || {})); },
      delete: function (u, o) { return call('http', 'delete', Object.assign({ url: u }, o || {})); },
      download: function (o) { return call('http', 'download', o || {}); }
    },

    intent: {
      openUrl: function (u, m) { return call('intent', 'openUrl', { url: u, mode: m || 'external' }); },
      canOpenUrl: function (u) { return call('intent', 'canOpenUrl', { url: u }); },
      getInitialLink: function () { return call('intent', 'getInitialLink', {}); },
      getLatestLink: function () { return call('intent', 'getLatestLink', {}); },
      startListening: function () { return call('intent', 'startListening', {}); },
      stopListening: function () { return call('intent', 'stopListening', {}); }
    },

    clipboard: {
      readText: function () { return call('clipboard', 'readText', {}); },
      writeText: function (t) { return call('clipboard', 'writeText', { text: t }); },
      hasText: function () { return call('clipboard', 'hasText', {}); },
      clear: function () { return call('clipboard', 'clear', {}); }
    },

    share: {
      shareText: function (t, s) { return call('share', 'shareText', { text: t, subject: s || null }); },
      shareFiles: function (p, t, s) { return call('share', 'shareFiles', { paths: p, text: t || null, subject: s || null }); }
    },

    camera: {
      getInfo: function () { return call('camera', 'getInfo', {}); },
      takePhoto: function (o) { return call('camera', 'takePhoto', o || {}); },
      pickFromGallery: function (o) { return call('camera', 'pickFromGallery', o || {}); }
    },

    geolocation: {
      checkPermission: function () { return call('geolocation', 'checkPermission', {}); },
      requestPermission: function () { return call('geolocation', 'requestPermission', {}); },
      getCurrentPosition: function (o) { return call('geolocation', 'getCurrentPosition', o || {}); },
      watchPosition: function (o) { return call('geolocation', 'watchPosition', o || {}); },
      clearWatch: function () { return call('geolocation', 'clearWatch', {}); },
      isLocationEnabled: function () { return call('geolocation', 'isLocationEnabled', {}); }
    },

    /* ───── فاز ۳ ───── */

    backButton: {
      enableIntercept: function () { return call('backButton', 'enableIntercept', {}); },
      disableIntercept: function () { return call('backButton', 'disableIntercept', {}); },
      getState: function () { return call('backButton', 'getState', {}); },
      exitApp: function () { return call('backButton', 'exitApp', {}); },
      setExitOnBack: function (enabled) { return call('backButton', 'setExitOnBack', { enabled: !!enabled }); },
      minimizeApp: function () { return call('backButton', 'minimizeApp', {}); }
    },

    secureStorage: {
      get: function (k) { return call('secureStorage', 'get', { key: k }); },
      set: function (k, v) { return call('secureStorage', 'set', { key: k, value: v }); },
      remove: function (k) { return call('secureStorage', 'remove', { key: k }); },
      has: function (k) { return call('secureStorage', 'has', { key: k }); },
      keys: function () { return call('secureStorage', 'keys', {}); },
      clear: function () { return call('secureStorage', 'clear', {}); },
      getInfo: function () { return call('secureStorage', 'getInfo', {}); }
    },

    notification: {
      show: function (o) { return call('notification', 'show', o || {}); },
      cancel: function (id) { return call('notification', 'cancel', { id: id }); },
      cancelAll: function () { return call('notification', 'cancelAll', {}); },
      getActive: function () { return call('notification', 'getActive', {}); },
      getPending: function () { return call('notification', 'getPending', {}); },
      createChannel: function (o) { return call('notification', 'createChannel', o || {}); },
      getInfo: function () { return call('notification', 'getInfo', {}); }
    },

    statusBar: {
      setStyle: function (style, bg) { return call('statusBar', 'setStyle', { style: style, backgroundColor: bg || null }); },
      setColor: function (c, nav) { return call('statusBar', 'setColor', { color: c, navigationBarColor: nav || null }); },
      show: function () { return call('statusBar', 'show', {}); },
      hide: function () { return call('statusBar', 'hide', {}); },
      setFullscreen: function () { return call('statusBar', 'setFullscreen', {}); },
      exitFullscreen: function () { return call('statusBar', 'exitFullscreen', {}); },
      getInfo: function () { return call('statusBar', 'getInfo', {}); }
    },

    orientation: {
      lock: function (o) { return call('orientation', 'lock', { orientation: o || 'portrait' }); },
      unlock: function () { return call('orientation', 'unlock', {}); },
      getInfo: function () { return call('orientation', 'getInfo', {}); }
    },

    haptic: {
      lightImpact: function () { return call('haptic', 'lightImpact', {}); },
      mediumImpact: function () { return call('haptic', 'mediumImpact', {}); },
      heavyImpact: function () { return call('haptic', 'heavyImpact', {}); },
      selectionClick: function () { return call('haptic', 'selectionClick', {}); },
      vibrate: function () { return call('haptic', 'vibrate', {}); },
      getInfo: function () { return call('haptic', 'getInfo', {}); }
    },

    keyboard: {
      getState: function () { return call('keyboard', 'getState', {}); },
      startWatch: function () { return call('keyboard', 'startWatch', {}); },
      stopWatch: function () { return call('keyboard', 'stopWatch', {}); },
      hide: function () { return call('keyboard', 'hide', {}); },
      getInfo: function () { return call('keyboard', 'getInfo', {}); }
    }
  };

  global.NativeSDK = sdk;
})(window);
