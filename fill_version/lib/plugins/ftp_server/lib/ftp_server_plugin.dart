import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:sweetmelon/packages/core/lib/core.dart';
import 'package:sweetmelon/packages/plugin_engine/lib/plugin_engine.dart';

typedef FtpServerEventEmitter = Future<void> Function(String event, dynamic data);

class FtpServerPlugin extends Plugin {
  final FtpServerEventEmitter? eventEmitter;

  ServerSocket? _server;
  String? _rootDir;
  String? _username;
  String? _password;
  int _port = 0;
  bool _running = false;
  int _clientCount = 0;
  final Map<String, _FtpSession> _sessions = {};

  FtpServerPlugin({this.eventEmitter});

  @override
  String get name => 'ftpServer';

  @override
  String get version => '1.0.0';

  @override
  String get description => 'Simple FTP server for file sharing';

  @override
  List<String> get supportedMethods => [
        'start',
        'stop',
        'getClients',
        'getStats',
        'kickClient',
        'getInfo',
      ];

  @override
  Future<void> onDispose() async {
    await _stopServer();
  }

  @override
  Future<dynamic> onCall(String method, Map<String, dynamic> args) async {
    switch (method) {
      case 'start':
        return _start(args);
      case 'stop':
        return _stopServer();
      case 'getClients':
        return _getClients();
      case 'getStats':
        return _getStats();
      case 'kickClient':
        return _kickClient(args);
      case 'getInfo':
        return {
          'name': name,
          'version': version,
          'running': _running,
          'port': _port,
          'clients': _sessions.length,
        };
      default:
        throw UnsupportedError('Method "$method" not supported');
    }
  }

  Future<Map<String, dynamic>> _start(Map<String, dynamic> args) async {
    if (_running) {
      return {
        'started': true,
        'alreadyRunning': true,
        'port': _port,
      };
    }

    final port = (args['port'] as num?)?.toInt() ?? 2121;
    final host = args['host'] as String? ?? '0.0.0.0';
    _rootDir = args['rootDir'] as String;
    _username = args['username'] as String? ?? 'anonymous';
    _password = args['password'] as String? ?? '';

    if (_rootDir == null || !await Directory(_rootDir!).exists()) {
      return {'started': false, 'reason': 'rootDir does not exist'};
    }

    try {
      _server = await ServerSocket.bind(
        host == '0.0.0.0' ? InternetAddress.anyIPv4 : InternetAddress(host),
        port,
      );

      _port = _server!.port;
      _running = true;

      _server!.listen(_handleClient);

      BridgeLogger.info('FtpServer', 'Started on port $_port, root: $_rootDir');

      eventEmitter?.call('ftpServer.started', {
        'port': _port,
        'rootDir': _rootDir,
      });

      return {
        'started': true,
        'alreadyRunning': false,
        'port': _port,
        'rootDir': _rootDir,
        'url': 'ftp://$host:$_port',
      };
    } catch (e) {
      return {'started': false, 'error': e.toString()};
    }
  }

  void _handleClient(Socket client) {
    _clientCount++;
    final sessionId = 'ftp_client_$_clientCount';

    final session = _FtpSession(
      id: sessionId,
      socket: client,
      rootDir: _rootDir!,
      remoteAddress: client.remoteAddress.address,
    );

    _sessions[sessionId] = session;

    BridgeLogger.info('FtpServer', 'Client connected: $sessionId');

    eventEmitter?.call('ftpServer.clientConnected', {
      'sessionId': sessionId,
      'remoteAddress': session.remoteAddress,
    });

    // Send welcome
    _send(client, '220 Sweetmelon FTP Server Ready');

    client.listen(
      (data) {
        final command = utf8.decode(data).trim();
        _processCommand(session, command);
      },
      onDone: () {
        _sessions.remove(sessionId);
        eventEmitter?.call('ftpServer.clientDisconnected', {
          'sessionId': sessionId,
        });
      },
      onError: (e) {
        _sessions.remove(sessionId);
      },
    );
  }

  void _processCommand(_FtpSession session, String raw) {
    if (raw.isEmpty) return;

    final parts = raw.split(' ');
    final command = parts[0].toUpperCase();
    final argument = parts.length > 1 ? parts.sublist(1).join(' ') : '';

    BridgeLogger.debug('FtpServer', '[${session.id}] $command $argument');

    session.commandCount++;

    switch (command) {
      case 'USER':
        if (argument == _username || _username == 'anonymous') {
          session.username = argument;
          _send(session.socket, '331 Password required');
        } else {
          _send(session.socket, '530 Invalid username');
        }
        break;

      case 'PASS':
        if (_password!.isEmpty || argument == _password) {
          session.authenticated = true;
          _send(session.socket, '230 Login successful');

          eventEmitter?.call('ftpServer.login', {
            'sessionId': session.id,
            'username': session.username,
          });
        } else {
          _send(session.socket, '530 Login incorrect');
        }
        break;

      case 'PWD':
        if (!session.authenticated) {
          _send(session.socket, '530 Not logged in');
          return;
        }
        _send(session.socket, '257 "${session.currentDir}"');
        break;

      case 'CWD':
        if (!session.authenticated) {
          _send(session.socket, '530 Not logged in');
          return;
        }
        final newDir = _resolveDir(session, argument);
        if (Directory(newDir).existsSync()) {
          session.currentDir = argument.startsWith('/')
              ? argument
              : p.join(session.currentDir, argument);
          _send(session.socket, '250 Directory changed');
        } else {
          _send(session.socket, '550 Directory not found');
        }
        break;

      case 'LIST':
        if (!session.authenticated) {
          _send(session.socket, '530 Not logged in');
          return;
        }
        _handleList(session);
        break;

      case 'TYPE':
        _send(session.socket, '200 Type set to ${argument.toUpperCase()}');
        break;

      case 'SYST':
        _send(session.socket, '215 UNIX Type: L8');
        break;

      case 'FEAT':
        _send(session.socket, '211-Features:\r\n PASV\r\n UTF8\r\n211 End');
        break;

      case 'QUIT':
        _send(session.socket, '221 Goodbye');
        session.socket.close();
        break;

      case 'NOOP':
        _send(session.socket, '200 OK');
        break;

      case 'PASV':
        _handlePasv(session);
        break;

      case 'RETR':
        _handleRetr(session, argument);
        break;

      case 'STOR':
        _handleStor(session, argument);
        break;

      case 'DELE':
        _handleDele(session, argument);
        break;

      case 'MKD':
        _handleMkd(session, argument);
        break;

      case 'RMD':
        _handleRmd(session, argument);
        break;

      case 'SIZE':
        _handleSize(session, argument);
        break;

      default:
        _send(session.socket, '502 Command not implemented');
    }
  }

  void _handleList(_FtpSession session) async {
    if (session.dataSocket == null) {
      _send(session.socket, '425 Use PASV first');
      return;
    }

    _send(session.socket, '150 Opening data connection');

    final dir = _resolveDir(session, session.currentDir);
    final directory = Directory(dir);

    if (!directory.existsSync()) {
      _send(session.socket, '550 Directory not found');
      return;
    }

    final entities = directory.listSync();
    final buffer = StringBuffer();

    for (final entity in entities) {
      final stat = entity.statSync();
      final isDir = entity is Directory;
      final name = p.basename(entity.path);
      final size = stat.size;
      final date = stat.modified;
      final dateStr = '${_monthName(date.month)} ${date.day.toString().padLeft(2)} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

      buffer.writeln(
        '${isDir ? "drwxr-xr-x" : "-rw-r--r--"} 1 owner group ${size.toString().padLeft(12)} $dateStr $name',
      );
    }

    try {
      final dataClient = await session.dataSocket!.first;
      dataClient.write(buffer.toString());
      await dataClient.close();
    } catch (_) {}

    session.dataSocket?.close();
    session.dataSocket = null;

    _send(session.socket, '226 Transfer complete');
  }

  void _handlePasv(_FtpSession session) async {
    try {
      final dataServer = await ServerSocket.bind(
        InternetAddress.anyIPv4,
        0,
      );

      session.dataSocket = dataServer;

      final port = dataServer.port;
      final p1 = port ~/ 256;
      final p2 = port % 256;

      _send(session.socket, '227 Entering Passive Mode (127,0,0,1,$p1,$p2)');
    } catch (e) {
      _send(session.socket, '425 Cannot open data connection');
    }
  }

  void _handleRetr(_FtpSession session, String filename) async {
    if (!session.authenticated) {
      _send(session.socket, '530 Not logged in');
      return;
    }

    final filePath = _resolveFile(session, filename);
    final file = File(filePath);

    if (!file.existsSync()) {
      _send(session.socket, '550 File not found');
      return;
    }

    if (session.dataSocket == null) {
      _send(session.socket, '425 Use PASV first');
      return;
    }

    _send(session.socket, '150 Opening data connection');

    try {
      final dataClient = await session.dataSocket!.first;
      final bytes = await file.readAsBytes();
      dataClient.add(bytes);
      await dataClient.close();
      session.transferredBytes += bytes.length;
    } catch (_) {}

    session.dataSocket?.close();
    session.dataSocket = null;

    _send(session.socket, '226 Transfer complete');

    eventEmitter?.call('ftpServer.fileDownloaded', {
      'sessionId': session.id,
      'file': filename,
    });
  }

  void _handleStor(_FtpSession session, String filename) async {
    if (!session.authenticated) {
      _send(session.socket, '530 Not logged in');
      return;
    }

    if (session.dataSocket == null) {
      _send(session.socket, '425 Use PASV first');
      return;
    }

    _send(session.socket, '150 Ready to receive');

    final filePath = _resolveFile(session, filename);
    final file = File(filePath);
    await file.parent.create(recursive: true);

    try {
      final dataClient = await session.dataSocket!.first;
      final sink = file.openWrite();
      int totalBytes = 0;

      await for (final chunk in dataClient) {
        sink.add(chunk);
        totalBytes += chunk.length;
      }

      await sink.flush();
      await sink.close();
      session.transferredBytes += totalBytes;
    } catch (_) {}

    session.dataSocket?.close();
    session.dataSocket = null;

    _send(session.socket, '226 Transfer complete');

    eventEmitter?.call('ftpServer.fileUploaded', {
      'sessionId': session.id,
      'file': filename,
    });
  }

  void _handleDele(_FtpSession session, String filename) {
    if (!session.authenticated) {
      _send(session.socket, '530 Not logged in');
      return;
    }

    final filePath = _resolveFile(session, filename);
    final file = File(filePath);

    if (file.existsSync()) {
      file.deleteSync();
      _send(session.socket, '250 File deleted');
    } else {
      _send(session.socket, '550 File not found');
    }
  }

  void _handleMkd(_FtpSession session, String dirname) {
    if (!session.authenticated) {
      _send(session.socket, '530 Not logged in');
      return;
    }

    final dirPath = _resolveDir(session, dirname);
    Directory(dirPath).createSync(recursive: true);
    _send(session.socket, '257 "$dirname" created');
  }

  void _handleRmd(_FtpSession session, String dirname) {
    if (!session.authenticated) {
      _send(session.socket, '530 Not logged in');
      return;
    }

    final dirPath = _resolveDir(session, dirname);
    final dir = Directory(dirPath);

    if (dir.existsSync()) {
      dir.deleteSync(recursive: true);
      _send(session.socket, '250 Directory removed');
    } else {
      _send(session.socket, '550 Directory not found');
    }
  }

  void _handleSize(_FtpSession session, String filename) {
    final filePath = _resolveFile(session, filename);
    final file = File(filePath);

    if (file.existsSync()) {
      _send(session.socket, '213 ${file.lengthSync()}');
    } else {
      _send(session.socket, '550 File not found');
    }
  }

  // ── Helpers ──

  void _send(Socket socket, String message) {
    try {
      socket.write('$message\r\n');
    } catch (_) {}
  }

  String _resolveDir(_FtpSession session, String path) {
    if (path.startsWith('/')) {
      return p.normalize(p.join(_rootDir!, path.substring(1)));
    }
    return p.normalize(p.join(_rootDir!, session.currentDir.substring(1), path));
  }

  String _resolveFile(_FtpSession session, String filename) {
    return _resolveDir(session, filename);
  }

  String _monthName(int month) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return months[month - 1];
  }

  Future<Map<String, dynamic>> _stopServer() async {
    if (!_running) return {'stopped': false, 'reason': 'not_running'};

    for (final s in _sessions.values) {
      s.socket.close();
      s.dataSocket?.close();
    }
    _sessions.clear();

    await _server?.close();
    _server = null;
    _running = false;

    return {'stopped': true};
  }

  Map<String, dynamic> _getClients() {
    return {
      'clients': _sessions.values.map((s) => {
        return {
          'id': s.id,
          'remoteAddress': s.remoteAddress,
          'authenticated': s.authenticated,
          'username': s.username,
          'currentDir': s.currentDir,
          'commands': s.commandCount,
          'transferred': s.transferredBytes,
        };
      }).toList(),
      'count': _sessions.length,
    };
  }

  Map<String, dynamic> _getStats() {
    int totalTransferred = 0;
    for (final s in _sessions.values) {
      totalTransferred += s.transferredBytes;
    }

    return {
      'running': _running,
      'port': _port,
      'activeClients': _sessions.length,
      'totalConnections': _clientCount,
      'totalTransferredBytes': totalTransferred,
      'rootDir': _rootDir,
    };
  }

  Future<Map<String, dynamic>> _kickClient(Map<String, dynamic> args) async {
    final sessionId = args['sessionId'] as String;
    final session = _sessions.remove(sessionId);

    if (session != null) {
      _send(session.socket, '421 Kicked by server');
      session.socket.close();
      return {'kicked': true, 'sessionId': sessionId};
    }

    return {'kicked': false, 'reason': 'not_found'};
  }

  @override
  Future<ValidationResult> validateArgs(String method, Map<String, dynamic> args) async {
    switch (method) {
      case 'start':
        if (args['rootDir'] is! String) {
          return ValidationResult.invalid('rootDir is required');
        }
        return ValidationResult.valid();
      case 'kickClient':
        if (args['sessionId'] is! String) {
          return ValidationResult.invalid('sessionId required');
        }
        return ValidationResult.valid();
      default:
        return ValidationResult.valid();
    }
  }
}

class _FtpSession {
  final String id;
  final Socket socket;
  final String rootDir;
  final String remoteAddress;
  String currentDir = '/';
  String? username;
  bool authenticated = false;
  ServerSocket? dataSocket;
  int commandCount = 0;
  int transferredBytes = 0;

  _FtpSession({
    required this.id,
    required this.socket,
    required this.rootDir,
    required this.remoteAddress,
  });
}
