    // ── فاز ۴ ──

    // Biometrics
    $('btnBioAvailable').onclick = function () { run('bio.isAvailable', function () { return S.biometrics.isAvailable(); }); };
    $('btnBioTypes').onclick = function () { run('bio.types', function () { return S.biometrics.getAvailableBiometrics(); }); };
    $('btnBioAuth').onclick = function () { run('bio.authenticate', function () { return S.biometrics.authenticate({ reason: 'Please verify your identity' }); }); };
    $('btnBioInfo').onclick = function () { run('bio.info', function () { return S.biometrics.getInfo(); }); };

    // QR
    $('btnQrScan').onclick = function () { run('qr.scan', function () { return S.qrScanner.scan({ timeoutMs: 60000 }); }); };
    $('btnQrInfo').onclick = function () { run('qr.info', function () { return S.qrScanner.getInfo(); }); };

    // Audio
    var lastRecPath = null;
    $('btnAudioRecord').onclick = function () { run('audio.record', function () { return S.audio.startRecording(); }); };
    $('btnAudioStopRecord').onclick = async function () {
      var r = await run('audio.stopRecord', function () { return S.audio.stopRecording(); });
      if (r && r.path) lastRecPath = r.path;
    };
    $('btnAudioPlay').onclick = function () {
      run('audio.play', function () {
        return S.audio.play({ path: lastRecPath || '', url: lastRecPath ? null : 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3' });
      });
    };
    $('btnAudioPause').onclick = function () { run('audio.pause', function () { return S.audio.pause(); }); };
    $('btnAudioResume').onclick = function () { run('audio.resume', function () { return S.audio.resume(); }); };
    $('btnAudioStop').onclick = function () { run('audio.stop', function () { return S.audio.stop(); }); };
    $('btnAudioInfo').onclick = function () { run('audio.info', function () { return S.audio.getInfo(); }); };

    // SMS OTP
    $('btnSmsSignature').onclick = function () { run('sms.signature', function () { return S.smsOtp.getAppSignature(); }); };
    $('btnSmsListen').onclick = function () { run('sms.listen', function () { return S.smsOtp.startListening(); }); };
    $('btnSmsStop').onclick = function () { run('sms.stop', function () { return S.smsOtp.stopListening(); }); };
    $('btnSmsLastCode').onclick = function () { run('sms.lastCode', function () { return S.smsOtp.getLastCode(); }); };
    $('btnSmsHint').onclick = function () { run('sms.hint', function () { return S.smsOtp.requestHint(); }); };
    $('btnSmsInfo').onclick = function () { run('sms.info', function () { return S.smsOtp.getInfo(); }); };

    // Download Manager
    $('btnDlStart').onclick = function () {
      run('dl.download', function () {
        return S.downloadManager.download({
          url: $('downloadUrl').value.trim(),
          fileName: 'test-download.bin',
          baseDir: 'temporary'
        });
      });
    };
    $('btnDlCancelAll').onclick = function () { run('dl.cancelAll', function () { return S.downloadManager.cancelAll(); }); };
    $('btnDlActive').onclick = function () { run('dl.active', function () { return S.downloadManager.getActive(); }); };
    $('btnDlInfo').onclick = function () { run('dl.info', function () { return S.downloadManager.getInfo(); }); };

    // Database
    $('btnDbOpen').onclick = function () {
      run('db.open', function () {
        return S.database.open('testdb', {
          version: 1,
          onCreate: [
            'CREATE TABLE IF NOT EXISTS users (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, email TEXT, age INTEGER, created_at TEXT DEFAULT CURRENT_TIMESTAMP)'
          ]
        });
      });
    };
    $('btnDbInsert').onclick = function () {
      run('db.insert', function () {
        return S.database.insert('testdb', 'users', {
          name: 'User ' + Math.floor(Math.random() * 1000),
          email: 'user@example.com',
          age: Math.floor(Math.random() * 50) + 18
        });
      });
    };
    $('btnDbQuery').onclick = function () { run('db.query', function () { return S.database.query('testdb', 'users', { orderBy: 'id DESC', limit: 20 }); }); };
    $('btnDbUpdate').onclick = function () {
      run('db.update', function () {
        return S.database.update('testdb', 'users', { name: 'Updated User' }, { where: 'id = ?', whereArgs: [1] });
      });
    };
    $('btnDbDelete').onclick = function () {
      run('db.delete', function () {
        return S.database.delete('testdb', 'users', { where: 'id = ?', whereArgs: [1] });
      });
    };
    $('btnDbDrop').onclick = function () { run('db.drop', function () { return S.database.deleteDatabase('testdb'); }); };
    $('btnDbInfo').onclick = function () { run('db.info', function () { return S.database.getInfo(); }); };

    // Contacts
    $('btnContactCount').onclick = function () { run('contacts.count', function () { return S.contacts.getCount(); }); };
    $('btnContactAll').onclick = function () { run('contacts.all', function () { return S.contacts.getAll({ limit: 10, withPhoto: false }); }); };
    $('btnContactSearch').onclick = function () { run('contacts.search', function () { return S.contacts.search($('contactQuery').value.trim()); }); };
    $('btnContactPick').onclick = function () { run('contacts.pick', function () { return S.contacts.pickContact(); }); };
    $('btnContactInfo').onclick = function () { run('contacts.info', function () { return S.contacts.getInfo(); }); };

    // Phone Dialer
    $('btnPhoneDial').onclick = function () { run('phone.dial', function () { return S.phoneDialer.dial($('phoneNumber').value.trim()); }); };
    $('btnPhoneCall').onclick = function () { run('phone.call', function () { return S.phoneDialer.directCall($('phoneNumber').value.trim()); }); };
    $('btnPhoneSms').onclick = function () { run('phone.sms', function () { return S.phoneDialer.sendSms($('phoneNumber').value.trim(), 'Hello from Sweetmelon'); }); };
    $('btnPhoneEmail').onclick = function () { run('phone.email', function () { return S.phoneDialer.sendEmail({ to: $('emailTo').value.trim(), subject: 'Hello', body: 'Sent from Sweetmelon bridge' }); }); };
    $('btnPhoneCanDial').onclick = function () { run('phone.canDial', function () { return S.phoneDialer.canDial($('phoneNumber').value.trim()); }); };
    $('btnPhoneInfo').onclick = function () { run('phone.info', function () { return S.phoneDialer.getInfo(); }); };
