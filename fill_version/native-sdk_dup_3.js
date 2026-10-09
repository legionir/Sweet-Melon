    dialog: {
      alert: function (options) {
        var o = typeof options === 'string' ? { message: options } : options || {};
        return call('dialog', 'alert', o);
      },
      confirm: function (options) {
        var o = typeof options === 'string' ? { message: options } : options || {};
        return call('dialog', 'confirm', o);
      },
      prompt: function (options) {
        return call('dialog', 'prompt', options || {});
      },
      getInfo: function () { return call('dialog', 'getInfo', {}); }
    },

    toast: {
      show: function (text, options) {
        var o = options || {};
        return call('toast', 'show', Object.assign({ text: text }, o));
      },
      getInfo: function () { return call('toast', 'getInfo', {}); }
    },

    splashScreen: {
      show: function (options) { return call('splashScreen', 'show', options || {}); },
      hide: function () { return call('splashScreen', 'hide', {}); },
      setAutoHide: function (enabled, delayMs) {
        return call('splashScreen', 'setAutoHide', { enabled: enabled, delayMs: delayMs || 3000 });
      },
      isVisible: function () { return call('splashScreen', 'isVisible', {}); },
      getInfo: function () { return call('splashScreen', 'getInfo', {}); }
    },

    pushNotification: {
      register: function () { return call('pushNotification', 'register', {}); },
      getToken: function () { return call('pushNotification', 'getToken', {}); },
      requestPermission: function () { return call('pushNotification', 'requestPermission', {}); },
      checkPermission: function () { return call('pushNotification', 'checkPermission', {}); },
      getDeliveredNotifications: function () { return call('pushNotification', 'getDeliveredNotifications', {}); },
      removeDeliveredNotifications: function (ids) { return call('pushNotification', 'removeDeliveredNotifications', { ids: ids }); },
      removeAllDeliveredNotifications: function () { return call('pushNotification', 'removeAllDeliveredNotifications', {}); },
      subscribe: function (topic) { return call('pushNotification', 'subscribe', { topic: topic }); },
      unsubscribe: function (topic) { return call('pushNotification', 'unsubscribe', { topic: topic }); },
      getInfo: function () { return call('pushNotification', 'getInfo', {}); }
    },

    wakeLock: {
      enable: function () { return call('wakeLock', 'enable', {}); },
      disable: function () { return call('wakeLock', 'disable', {}); },
      toggle: function () { return call('wakeLock', 'toggle', {}); },
      isEnabled: function () { return call('wakeLock', 'isEnabled', {}); },
      getInfo: function () { return call('wakeLock', 'getInfo', {}); }
    },

    cookieManager: {
      setCookie: function (options) { return call('cookieManager', 'setCookie', options || {}); },
      clearCookies: function () { return call('cookieManager', 'clearCookies', {}); },
      clearSession: function () { return call('cookieManager', 'clearSession', {}); },
      getInfo: function () { return call('cookieManager', 'getInfo', {}); }
    },

    cacheControl: {
      clearWebViewCache: function () { return call('cacheControl', 'clearWebViewCache', {}); },
      clearAppCache: function () { return call('cacheControl', 'clearAppCache', {}); },
      getCacheSize: function () { return call('cacheControl', 'getCacheSize', {}); },
      clearAll: function () { return call('cacheControl', 'clearAll', {}); },
      getInfo: function () { return call('cacheControl', 'getInfo', {}); }
    },

    appUpdate: {
      configure: function (options) { return call('appUpdate', 'configure', options || {}); },
      getCurrentVersion: function () { return call('appUpdate', 'getCurrentVersion', {}); },
      checkForUpdate: function (options) { return call('appUpdate', 'checkForUpdate', options || {}); },
      openStore: function (options) { return call('appUpdate', 'openStore', options || {}); },
      getLastCheckResult: function () { return call('appUpdate', 'getLastCheckResult', {}); },
      getInfo: function () { return call('appUpdate', 'getInfo', {}); }
    },
