    websocket: {
      connect: function (url, options) {
        var o = options || {};
        return call('websocket', 'connect', Object.assign({ url: url }, o), { timeout: 15000 });
      },
      disconnect: function (id, code, reason) {
        return call('websocket', 'disconnect', { id: id, code: code, reason: reason });
      },
      send: function (id, data) {
        return call('websocket', 'send', { id: id, data: data });
      },
      sendJson: function (id, data) {
        return call('websocket', 'sendJson', { id: id, data: data });
      },
      getState: function (id) {
        return call('websocket', 'getState', { id: id });
      },
      getConnections: function () {
        return call('websocket', 'getConnections', {});
      },
      disconnectAll: function () {
        return call('websocket', 'disconnectAll', {});
      },
      getInfo: function () {
        return call('websocket', 'getInfo', {});
      }
    },

    backgroundTask: {
      register: function (taskId, options) {
        var o = options || {};
        return call('backgroundTask', 'register', Object.assign({ taskId: taskId }, o));
      },
      unregister: function (taskId) {
        return call('backgroundTask', 'unregister', { taskId: taskId });
      },
      runOnce: function (taskId, options) {
        var o = options || {};
        return call('backgroundTask', 'runOnce', Object.assign({ taskId: taskId }, o), { timeout: 60000 });
      },
      startRepeating: function (taskId, intervalMs, options) {
        var o = options || {};
        return call('backgroundTask', 'startRepeating', Object.assign({
          taskId: taskId,
          intervalMs: intervalMs
        }, o));
      },
      stop: function (taskId) {
        return call('backgroundTask', 'stop', { taskId: taskId });
      },
      stopAll: function () {
        return call('backgroundTask', 'stopAll', {});
      },
      getTaskState: function (taskId) {
        return call('backgroundTask', 'getTaskState', { taskId: taskId });
      },
      getAllTasks: function () {
        return call('backgroundTask', 'getAllTasks', {});
      },
      getInfo: function () {
        return call('backgroundTask', 'getInfo', {});
      }
    },
