    /* ───── فاز ۵ ───── */

    bluetooth: {
      isAvailable: function () { return call('bluetooth', 'isAvailable', {}); },
      isOn: function () { return call('bluetooth', 'isOn', {}); },
      startScan: function (o) { return call('bluetooth', 'startScan', o || {}, { timeout: 30000 }); },
      stopScan: function () { return call('bluetooth', 'stopScan', {}); },
      connect: function (deviceId, o) { return call('bluetooth', 'connect', Object.assign({ deviceId: deviceId }, o || {}), { timeout: 30000 }); },
      disconnect: function (deviceId) { return call('bluetooth', 'disconnect', { deviceId: deviceId }); },
      discoverServices: function (deviceId) { return call('bluetooth', 'discoverServices', { deviceId: deviceId }); },
      readCharacteristic: function (o) { return call('bluetooth', 'readCharacteristic', o); },
      writeCharacteristic: function (o) { return call('bluetooth', 'writeCharacteristic', o); },
      getConnectedDevices: function () { return call('bluetooth', 'getConnectedDevices', {}); },
      getInfo: function () { return call('bluetooth', 'getInfo', {}); }
    },

    nfc: {
      isAvailable: function () { return call('nfc', 'isAvailable', {}); },
      startSession: function (o) { return call('nfc', 'startSession', o || {}, { timeout: 60000 }); },
      stopSession: function () { return call('nfc', 'stopSession', {}); },
      writeText: function (text) { return call('nfc', 'writeText', { text: text }, { timeout: 60000 }); },
      writeUri: function (uri) { return call('nfc', 'writeUri', { uri: uri }, { timeout: 60000 }); },
      getInfo: function () { return call('nfc', 'getInfo', {}); }
    },

    speechToText: {
      initialize: function () { return call('speechToText', 'initialize', {}); },
      startListening: function (o) { return call('speechToText', 'startListening', o || {}, { timeout: 60000 }); },
      stopListening: function () { return call('speechToText', 'stopListening', {}); },
      cancelListening: function () { return call('speechToText', 'cancelListening', {}); },
      isAvailable: function () { return call('speechToText', 'isAvailable', {}); },
      getLocales: function () { return call('speechToText', 'getLocales', {}); },
      getInfo: function () { return call('speechToText', 'getInfo', {}); }
    },

    textToSpeech: {
      speak: function (text, o) { return call('textToSpeech', 'speak', Object.assign({ text: text }, o || {})); },
      stop: function () { return call('textToSpeech', 'stop', {}); },
      pause: function () { return call('textToSpeech', 'pause', {}); },
      setLanguage: function (l) { return call('textToSpeech', 'setLanguage', { language: l }); },
      setSpeechRate: function (r) { return call('textToSpeech', 'setSpeechRate', { rate: r }); },
      setPitch: function (p) { return call('textToSpeech', 'setPitch', { pitch: p }); },
      setVolume: function (v) { return call('textToSpeech', 'setVolume', { volume: v }); },
      getLanguages: function () { return call('textToSpeech', 'getLanguages', {}); },
      getVoices: function () { return call('textToSpeech', 'getVoices', {}); },
      isSpeaking: function () { return call('textToSpeech', 'isSpeaking', {}); },
      getInfo: function () { return call('textToSpeech', 'getInfo', {}); }
    },

    videoPlayer: {
      create: function (o) { return call('videoPlayer', 'create', o || {}); },
      play: function (id) { return call('videoPlayer', 'play', { playerId: id }); },
      pause: function (id) { return call('videoPlayer', 'pause', { playerId: id }); },
      seekTo: function (id, ms) { return call('videoPlayer', 'seekTo', { playerId: id, positionMs: ms }); },
      setVolume: function (id, v) { return call('videoPlayer', 'setVolume', { playerId: id, volume: v }); },
      setPlaybackSpeed: function (id, s) { return call('videoPlayer', 'setPlaybackSpeed', { playerId: id, speed: s }); },
      setLooping: function (id, l) { return call('videoPlayer', 'setLooping', { playerId: id, looping: l }); },
      getPosition: function (id) { return call('videoPlayer', 'getPosition', { playerId: id }); },
      getDuration: function (id) { return call('videoPlayer', 'getDuration', { playerId: id }); },
      getState: function (id) { return call('videoPlayer', 'getState', { playerId: id }); },
      dispose: function (id) { return call('videoPlayer', 'dispose', { playerId: id }); },
      disposeAll: function () { return call('videoPlayer', 'disposeAll', {}); },
      getInfo: function () { return call('videoPlayer', 'getInfo', {}); }
    },

    inAppBrowser: {
      open: function (url, o) { return call('inAppBrowser', 'open', Object.assign({ url: url }, o || {}), { timeout: 300000 }); },
      getInfo: function () { return call('inAppBrowser', 'getInfo', {}); }
    },

    pdf: {
      generateFromText: function (text, o) { return call('pdf', 'generateFromText', Object.assign({ text: text }, o || {})); },
      generateFromHtml: function (html, o) { return call('pdf', 'generateFromHtml', Object.assign({ html: html }, o || {})); },
      print: function (o) { return call('pdf', 'print', o || {}); },
      share: function (path) { return call('pdf', 'share', { path: path }); },
      getInfo: function () { return call('pdf', 'getInfo', {}); }
    },

    encryption: {
      aesEncrypt: function (data, key, iv) { return call('encryption', 'aesEncrypt', { data: data, key: key, iv: iv || null }); },
      aesDecrypt: function (data, key, iv) { return call('encryption', 'aesDecrypt', { data: data, key: key, iv: iv }); },
      generateAesKey: function (bits) { return call('encryption', 'generateAesKey', { bits: bits || 256 }); },
      hashSha256: function (data) { return call('encryption', 'hashSha256', { data: data }); },
      hashSha512: function (data) { return call('encryption', 'hashSha512', { data: data }); },
      hashMd5: function (data) { return call('encryption', 'hashMd5', { data: data }); },
      hmacSha256: function (data, key) { return call('encryption', 'hmacSha256', { data: data, key: key }); },
      generateRandomBytes: function (len) { return call('encryption', 'generateRandomBytes', { length: len || 32 }); },
      base64Encode: function (data) { return call('encryption', 'base64Encode', { data: data }); },
      base64Decode: function (data) { return call('encryption', 'base64Decode', { data: data }); },
      getInfo: function () { return call('encryption', 'getInfo', {}); }
    }
