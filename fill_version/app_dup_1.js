    // فاز ۴ events
    var phase4Events = [
      'qrScanner.scanned',
      'audio.playerState',
      'audio.position',
      'smsOtp.received',
      'download.progress',
      'download.complete',
      'download.error'
    ];

    phase4Events.forEach(function (ev) {
      S.on(ev, function (data) {
        eventCount++;
        var msg = JSON.stringify(data);
        if (msg.length > 120) msg = msg.substring(0, 120) + '...';
        log('EVENT ' + ev + ' → ' + msg, 'event');
        updateStats();
      });
    });
