    filePicker: {
      pickFiles: function (o) { return call('filePicker', 'pickFiles', o || {}); },
      pickImages: function (o) { return call('filePicker', 'pickImages', o || {}); },
      pickVideos: function (o) { return call('filePicker', 'pickVideos', o || {}); },
      pickMedia: function (o) { return call('filePicker', 'pickMedia', o || {}); },
      pickDirectory: function () { return call('filePicker', 'pickDirectory', {}); },
      getInfo: function () { return call('filePicker', 'getInfo', {}); }
    },

    fileOpener: {
      open: function (path, mimeType) { return call('fileOpener', 'open', { path: path, mimeType: mimeType }); },
      canOpen: function (path) { return call('fileOpener', 'canOpen', { path: path }); },
      getMimeType: function (path) { return call('fileOpener', 'getMimeType', { path: path }); },
      getInfo: function () { return call('fileOpener', 'getInfo', {}); }
    },

    sensors: {
      startAccelerometer: function (o) { return call('sensors', 'startAccelerometer', o || {}); },
      stopAccelerometer: function () { return call('sensors', 'stopAccelerometer', {}); },
      startGyroscope: function (o) { return call('sensors', 'startGyroscope', o || {}); },
      stopGyroscope: function () { return call('sensors', 'stopGyroscope', {}); },
      startMagnetometer: function (o) { return call('sensors', 'startMagnetometer', o || {}); },
      stopMagnetometer: function () { return call('sensors', 'stopMagnetometer', {}); },
      startUserAccelerometer: function (o) { return call('sensors', 'startUserAccelerometer', o || {}); },
      stopUserAccelerometer: function () { return call('sensors', 'stopUserAccelerometer', {}); },
      stopAll: function () { return call('sensors', 'stopAll', {}); },
      getActiveStreams: function () { return call('sensors', 'getActiveStreams', {}); },
      getInfo: function () { return call('sensors', 'getInfo', {}); }
    },

    screenBrightness: {
      get: function () { return call('screenBrightness', 'get', {}); },
      set: function (brightness) { return call('screenBrightness', 'set', { brightness: brightness }); },
      reset: function () { return call('screenBrightness', 'reset', {}); },
      getSystem: function () { return call('screenBrightness', 'getSystem', {}); },
      setAutoReset: function (enabled) { return call('screenBrightness', 'setAutoReset', { enabled: enabled }); },
      getInfo: function () { return call('screenBrightness', 'getInfo', {}); }
    },

    flashlight: {
      enable: function () { return call('flashlight', 'enable', {}); },
      disable: function () { return call('flashlight', 'disable', {}); },
      toggle: function () { return call('flashlight', 'toggle', {}); },
      isAvailable: function () { return call('flashlight', 'isAvailable', {}); },
      isEnabled: function () { return call('flashlight', 'isEnabled', {}); },
      getInfo: function () { return call('flashlight', 'getInfo', {}); }
    },

    navigationBar: {
      setColor: function (color, darkIcons) { return call('navigationBar', 'setColor', { color: color, darkIcons: darkIcons || false }); },
      setStyle: function (style) { return call('navigationBar', 'setStyle', { style: style }); },
      show: function () { return call('navigationBar', 'show', {}); },
      hide: function () { return call('navigationBar', 'hide', {}); },
      setTransparent: function () { return call('navigationBar', 'setTransparent', {}); },
      getInfo: function () { return call('navigationBar', 'getInfo', {}); }
    },

    privacyScreen: {
      enable: function () { return call('privacyScreen', 'enable', {}); },
      disable: function () { return call('privacyScreen', 'disable', {}); },
      isEnabled: function () { return call('privacyScreen', 'isEnabled', {}); },
      getInfo: function () { return call('privacyScreen', 'getInfo', {}); }
    },

    nativeSettings: {
      open: function (setting) { return call('nativeSettings', 'open', { setting: setting }); },
      openApp: function () { return call('nativeSettings', 'openApp', {}); },
      openWifi: function () { return call('nativeSettings', 'openWifi', {}); },
      openBluetooth: function () { return call('nativeSettings', 'openBluetooth', {}); },
      openLocation: function () { return call('nativeSettings', 'openLocation', {}); },
      openNotification: function () { return call('nativeSettings', 'openNotification', {}); },
      openBattery: function () { return call('nativeSettings', 'openBattery', {}); },
      openDisplay: function () { return call('nativeSettings', 'openDisplay', {}); },
      openSound: function () { return call('nativeSettings', 'openSound', {}); },
      openSecurity: function () { return call('nativeSettings', 'openSecurity', {}); },
      openDate: function () { return call('nativeSettings', 'openDate', {}); },
      openAccessibility: function () { return call('nativeSettings', 'openAccessibility', {}); },
      openStorage: function () { return call('nativeSettings', 'openStorage', {}); },
      openDeveloper: function () { return call('nativeSettings', 'openDeveloper', {}); },
      openAbout: function () { return call('nativeSettings', 'openAbout', {}); },
      getAvailableSettings: function () { return call('nativeSettings', 'getAvailableSettings', {}); },
      getInfo: function () { return call('nativeSettings', 'getInfo', {}); }
    },
