    /* ───── فاز ۴ ───── */

    biometrics: {
      isAvailable: function () { return call('biometrics', 'isAvailable', {}); },
      getAvailableBiometrics: function () { return call('biometrics', 'getAvailableBiometrics', {}); },
      authenticate: function (options) { return call('biometrics', 'authenticate', options || {}); },
      getInfo: function () { return call('biometrics', 'getInfo', {}); }
    },

    qrScanner: {
      scan: function (options) { return call('qrScanner', 'scan', options || {}, { timeout: 90000 }); },
      getInfo: function () { return call('qrScanner', 'getInfo', {}); }
    },

    audio: {
      startRecording: function (o) { return call('audio', 'startRecording', o || {}); },
      stopRecording: function () { return call('audio', 'stopRecording', {}); },
      isRecording: function () { return call('audio', 'isRecording', {}); },
      play: function (o) { return call('audio', 'play', o || {}); },
      pause: function () { return call('audio', 'pause', {}); },
      resume: function () { return call('audio', 'resume', {}); },
      stop: function () { return call('audio', 'stop', {}); },
      seek: function (ms) { return call('audio', 'seek', { positionMs: ms }); },
      isPlaying: function () { return call('audio', 'isPlaying', {}); },
      getDuration: function () { return call('audio', 'getDuration', {}); },
      getPosition: function () { return call('audio', 'getPosition', {}); },
      setVolume: function (v) { return call('audio', 'setVolume', { volume: v }); },
      getInfo: function () { return call('audio', 'getInfo', {}); }
    },

    smsOtp: {
      getAppSignature: function () { return call('smsOtp', 'getAppSignature', {}); },
      startListening: function () { return call('smsOtp', 'startListening', {}); },
      stopListening: function () { return call('smsOtp', 'stopListening', {}); },
      getLastCode: function () { return call('smsOtp', 'getLastCode', {}); },
      requestHint: function () { return call('smsOtp', 'requestHint', {}); },
      getInfo: function () { return call('smsOtp', 'getInfo', {}); }
    },

    downloadManager: {
      download: function (o) { return call('downloadManager', 'download', o || {}, { timeout: 300000 }); },
      cancel: function (taskId) { return call('downloadManager', 'cancel', { taskId: taskId }); },
      cancelAll: function () { return call('downloadManager', 'cancelAll', {}); },
      getActive: function () { return call('downloadManager', 'getActive', {}); },
      getInfo: function () { return call('downloadManager', 'getInfo', {}); }
    },

    database: {
      open: function (name, options) { var o = options || {}; return call('database', 'open', { name: name, version: o.version || 1, onCreate: o.onCreate || null }); },
      close: function (name) { return call('database', 'close', { name: name }); },
      execute: function (name, sql, params) { return call('database', 'execute', { name: name, sql: sql, params: params || null }); },
      query: function (name, table, options) { var o = options || {}; return call('database', 'query', Object.assign({ name: name, table: table }, o)); },
      insert: function (name, table, values) { return call('database', 'insert', { name: name, table: table, values: values }); },
      update: function (name, table, values, options) { var o = options || {}; return call('database', 'update', { name: name, table: table, values: values, where: o.where || null, whereArgs: o.whereArgs || null }); },
      delete: function (name, table, options) { var o = options || {}; return call('database', 'delete', { name: name, table: table, where: o.where || null, whereArgs: o.whereArgs || null }); },
      rawQuery: function (name, sql, params) { return call('database', 'rawQuery', { name: name, sql: sql, params: params || null }); },
      rawInsert: function (name, sql, params) { return call('database', 'rawInsert', { name: name, sql: sql, params: params || null }); },
      rawUpdate: function (name, sql, params) { return call('database', 'rawUpdate', { name: name, sql: sql, params: params || null }); },
      rawDelete: function (name, sql, params) { return call('database', 'rawDelete', { name: name, sql: sql, params: params || null }); },
      batch: function (name, statements) { return call('database', 'batch', { name: name, statements: statements }); },
      tableExists: function (name, table) { return call('database', 'tableExists', { name: name, table: table }); },
      getOpenDatabases: function () { return call('database', 'getOpenDatabases', {}); },
      deleteDatabase: function (name) { return call('database', 'deleteDatabase', { name: name }); },
      getInfo: function () { return call('database', 'getInfo', {}); }
    },

    contacts: {
      getAll: function (o) { return call('contacts', 'getAll', o || {}); },
      getById: function (id) { return call('contacts', 'getById', { id: id }); },
      search: function (query) { return call('contacts', 'search', { query: query }); },
      getCount: function () { return call('contacts', 'getCount', {}); },
      pickContact: function () { return call('contacts', 'pickContact', {}); },
      getInfo: function () { return call('contacts', 'getInfo', {}); }
    },

    phoneDialer: {
      dial: function (number) { return call('phoneDialer', 'dial', { number: number }); },
      directCall: function (number) { return call('phoneDialer', 'directCall', { number: number }); },
      canDial: function (number) { return call('phoneDialer', 'canDial', { number: number }); },
      sendSms: function (number, body) { return call('phoneDialer', 'sendSms', { number: number, body: body || '' }); },
      sendEmail: function (options) { return call('phoneDialer', 'sendEmail', options || {}); },
      getInfo: function () { return call('phoneDialer', 'getInfo', {}); }
    }
