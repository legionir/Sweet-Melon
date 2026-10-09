    _loader: {
      getStats: function () { return call('_loader', 'getStats', {}); },
      getStatus: function (plugin) { return call('_loader', 'getStatus', { plugin: plugin }); },
      preload: function (plugins) { return call('_loader', 'preload', { plugins: plugins }); },
      unload: function (plugin) { return call('_loader', 'unload', { plugin: plugin }); },
      reload: function (plugin) { return call('_loader', 'reload', { plugin: plugin }); },
      getLoadedPlugins: function () { return call('_loader', 'getLoadedPlugins', {}); },
      getUnloadedPlugins: function () { return call('_loader', 'getUnloadedPlugins', {}); }
    },
