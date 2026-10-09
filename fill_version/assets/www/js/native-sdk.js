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
      Object.assign(
        {
          plugin: plugin,
          method: method,
          args: args || {}
        },
        extra || {}
      )
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
      return {
        initialized: false,
        pendingRequests: 0,
        totalRequests: 0,
        version: null
      };
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

    permission: {
      check: function (permission) {
        return call('permission', 'check', { permission: permission });
      },
      request: function (permission) {
        return call('permission', 'request', { permission: permission });
      },
      checkMany: function (permissions) {
        return call('permission', 'checkMany', { permissions: permissions });
      },
      requestMany: function (permissions) {
        return call('permission', 'requestMany', { permissions: permissions });
      },
      openSettings: function () {
        return call('permission', 'openSettings', {});
      },
      getKnownPermissions: function () {
        return call('permission', 'getKnownPermissions', {});
      }
    },

    appLifecycle: {
      getState: function () {
        return call('appLifecycle', 'getState', {});
      },
      enableEvents: function () {
        return call('appLifecycle', 'enableEvents', {});
      },
      disableEvents: function () {
        return call('appLifecycle', 'disableEvents', {});
      },
      getInfo: function () {
        return call('appLifecycle', 'getInfo', {});
      }
    },

    deviceInfo: {
      getDeviceInfo: function () {
        return call('deviceInfo', 'getDeviceInfo', {});
      },
      getAppInfo: function () {
        return call('deviceInfo', 'getAppInfo', {});
      },
      getAll: function () {
        return call('deviceInfo', 'getAll', {});
      }
    },

    connectivity: {
      getStatus: function () {
        return call('connectivity', 'getStatus', {});
      },
      isOnline: function () {
        return call('connectivity', 'isOnline', {});
      },
      startWatch: function () {
        return call('connectivity', 'startWatch', {});
      },
      stopWatch: function () {
        return call('connectivity', 'stopWatch', {});
      },
      getInfo: function () {
        return call('connectivity', 'getInfo', {});
      }
    },

    storage: {
      get: function (key) {
        return call('storage', 'get', { key: key });
      },
      set: function (key, value) {
        return call('storage', 'set', { key: key, value: value });
      },
      remove: function (key) {
        return call('storage', 'remove', { key: key });
      },
      clear: function () {
        return call('storage', 'clear', {});
      },
      keys: function () {
        return call('storage', 'keys', {});
      },
      has: function (key) {
        return call('storage', 'has', { key: key });
      }
    },

    fileSystem: {
      getDirectories: function () {
        return call('fileSystem', 'getDirectories', {});
      },
      readFile: function (path, baseDir, encoding) {
        return call('fileSystem', 'readFile', {
          path: path,
          baseDir: baseDir || 'documents',
          encoding: encoding || 'utf8'
        });
      },
      writeFile: function (path, content, options) {
        var o = options || {};
        return call('fileSystem', 'writeFile', {
          path: path,
          content: content,
          baseDir: o.baseDir || 'documents',
          encoding: o.encoding || 'utf8',
          append: !!o.append
        });
      },
      deleteFile: function (path, baseDir) {
        return call('fileSystem', 'deleteFile', {
          path: path,
          baseDir: baseDir || 'documents'
        });
      },
      fileExists: function (path, baseDir) {
        return call('fileSystem', 'fileExists', {
          path: path,
          baseDir: baseDir || 'documents'
        });
      },
      listFiles: function (path, options) {
        var o = options || {};
        return call('fileSystem', 'listFiles', {
          path: path || '',
          baseDir: o.baseDir || 'documents',
          recursive: !!o.recursive
        });
      },
      createDirectory: function (path, options) {
        var o = options || {};
        return call('fileSystem', 'createDirectory', {
          path: path,
          baseDir: o.baseDir || 'documents',
          recursive: o.recursive !== false
        });
      },
      deleteDirectory: function (path, options) {
        var o = options || {};
        return call('fileSystem', 'deleteDirectory', {
          path: path,
          baseDir: o.baseDir || 'documents',
          recursive: !!o.recursive
        });
      },
      stat: function (path, options) {
        var o = options || {};
        return call('fileSystem', 'stat', {
          path: path,
          baseDir: o.baseDir || 'documents',
          type: o.type || 'file'
        });
      }
    },

    http: {
      request: function (options) {
        return call('http', 'request', options || {});
      },
      get: function (url, options) {
        return call('http', 'get', Object.assign({ url: url }, options || {}));
      },
      post: function (url, body, options) {
        return call(
          'http',
          'post',
          Object.assign(
            {
              url: url,
              body: body
            },
            options || {}
          )
        );
      },
      put: function (url, body, options) {
        return call(
          'http',
          'put',
          Object.assign(
            {
              url: url,
              body: body
            },
            options || {}
          )
        );
      },
      patch: function (url, body, options) {
        return call(
          'http',
          'patch',
          Object.assign(
            {
              url: url,
              body: body
            },
            options || {}
          )
        );
      },
      delete: function (url, options) {
        return call('http', 'delete', Object.assign({ url: url }, options || {}));
      },
      download: function (options) {
        return call('http', 'download', options || {});
      }
    },

    intent: {
      openUrl: function (url, mode) {
        return call('intent', 'openUrl', {
          url: url,
          mode: mode || 'external'
        });
      },
      canOpenUrl: function (url) {
        return call('intent', 'canOpenUrl', { url: url });
      },
      getInitialLink: function () {
        return call('intent', 'getInitialLink', {});
      },
      getLatestLink: function () {
        return call('intent', 'getLatestLink', {});
      },
      startListening: function () {
        return call('intent', 'startListening', {});
      },
      stopListening: function () {
        return call('intent', 'stopListening', {});
      }
    },

    clipboard: {
      readText: function () {
        return call('clipboard', 'readText', {});
      },
      writeText: function (text) {
        return call('clipboard', 'writeText', { text: text });
      },
      hasText: function () {
        return call('clipboard', 'hasText', {});
      },
      clear: function () {
        return call('clipboard', 'clear', {});
      }
    },

    share: {
      shareText: function (text, subject) {
        return call('share', 'shareText', {
          text: text,
          subject: subject || null
        });
      },
      shareFiles: function (paths, text, subject) {
        return call('share', 'shareFiles', {
          paths: paths,
          text: text || null,
          subject: subject || null
        });
      }
    },

    camera: {
      getInfo: function () {
        return call('camera', 'getInfo', {});
      },
      takePhoto: function (options) {
        return call('camera', 'takePhoto', options || {});
      },
      pickFromGallery: function (options) {
        return call('camera', 'pickFromGallery', options || {});
      }
    },

    geolocation: {
      checkPermission: function () {
        return call('geolocation', 'checkPermission', {});
      },
      requestPermission: function () {
        return call('geolocation', 'requestPermission', {});
      },
      getCurrentPosition: function (options) {
        return call('geolocation', 'getCurrentPosition', options || {});
      },
      watchPosition: function (options) {
        return call('geolocation', 'watchPosition', options || {});
      },
      clearWatch: function () {
        return call('geolocation', 'clearWatch', {});
      },
      isLocationEnabled: function () {
        return call('geolocation', 'isLocationEnabled', {});
      }
    }
  };

  global.NativeSDK = sdk;
})(window);
