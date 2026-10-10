بله ادامه می‌دم. اول ۴ پلاگین server رو می‌سازم، بعد README و Example برای همه ۸ پلاگین شبکه.

---

# بخش ۱: ۴ پلاگین Server جدید

---

## پلاگین ۱: TCP Server (مستقل)

## 📄 `lib/plugins/tcp_server/lib/tcp_server_plugin.dart`

```dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:sweetmelon/packages/core/lib/core.dart';
import 'package:sweetmelon/packages/plugin_engine/lib/plugin_engine.dart';

typedef TcpServerEventEmitter = Future<void> Function(String event, dynamic data);

class TcpServerPlugin extends Plugin {
  final TcpServerEventEmitter? eventEmitter;

  final Map<String, _TcpServerInstance> _servers = {};

  TcpServerPlugin({this.eventEmitter});

  @override
  String get name => 'tcpServer';

  @override
  String get version => '1.0.0';

  @override
  String get description => 'TCP server for accepting incoming connections';

  @override
  List<String> get supportedMethods => [
        'start',
        'stop',
        'stopAll',
        'sendToClient',
        'sendToAll',
        'disconnectClient',
        'disconnectAllClients',
        'getClients',
        'getServers',
        'getInfo',
      ];

  @override
  Future<void> onDispose() async {
    for (final server in _servers.values) {
      await server.close();
    }
    _servers.clear();
  }

  @override
  Future<dynamic> onCall(String method, Map<String, dynamic> args) async {
    switch (method) {
      case 'start':
        return _start(args);
      case 'stop':
        return _stop(args);
      case 'stopAll':
        return _stopAll();
      case 'sendToClient':
        return _sendToClient(args);
      case 'sendToAll':
        return _sendToAll(args);
      case 'disconnectClient':
        return _disconnectClient(args);
      case 'disconnectAllClients':
        return _disconnectAllClients(args);
      case 'getClients':
        return _getClients(args);
      case 'getServers':
        return _getServers();
      case 'getInfo':
        return {
          'name': name,
          'version': version,
          'activeServers': _servers.length,
        };
      default:
        throw UnsupportedError('Method "$method" not supported');
    }
  }

  Future<Map<String, dynamic>> _start(Map<String, dynamic> args) async {
    final port = (args['port'] as num?)?.toInt() ?? 0;
    final host = args['host'] as String? ?? '0.0.0.0';
    final id = args['id'] as String? ?? 'tcp_srv_${DateTime.now().millisecondsSinceEpoch}';
    final maxClients = (args['maxClients'] as num?)?.toInt() ?? 100;
    final encoding = args['encoding'] as String? ?? 'utf8';

    if (_servers.containsKey(id)) {
      return {
        'started': true,
        'alreadyRunning': true,
        'id': id,
        'port': _servers[id]!.server.port,
      };
    }

    try {
      final server = await ServerSocket.bind(
        host == '0.0.0.0' ? InternetAddress.anyIPv4 : InternetAddress(host),
        port,
      );

      final instance = _TcpServerInstance(
        id: id,
        server: server,
        maxClients: maxClients,
        encoding: encoding,
      );

      instance.subscription = server.listen((clientSocket) {
        if (instance.clients.length >= maxClients) {
          clientSocket.close();
          BridgeLogger.warn('TcpServer', '[$id] Max clients reached, rejecting');
          return;
        }

        _handleNewClient(instance, clientSocket);
      });

      _servers[id] = instance;

      BridgeLogger.info('TcpServer', '[$id] Started on port ${server.port}');

      eventEmitter?.call('tcpServer.started', {
        'serverId': id,
        'port': server.port,
        'host': host,
      });

      return {
        'started': true,
        'alreadyRunning': false,
        'id': id,
        'port': server.port,
        'host': host,
      };
    } catch (e) {
      return {'started': false, 'error': e.toString()};
    }
  }

  void _handleNewClient(_TcpServerInstance instance, Socket clientSocket) {
    instance.clientCounter++;
    final clientId = 'client_${instance.clientCounter}';

    final remoteAddress = clientSocket.remoteAddress.address;
    final remotePort = clientSocket.remotePort;

    instance.clients[clientId] = clientSocket;

    BridgeLogger.info(
      'TcpServer',
      '[${instance.id}] Client connected: $clientId ($remoteAddress:$remotePort)',
    );

    eventEmitter?.call('tcpServer.clientConnected', {
      'serverId': instance.id,
      'clientId': clientId,
      'remoteAddress': remoteAddress,
      'remotePort': remotePort,
      'totalClients': instance.clients.length,
    });

    clientSocket.listen(
      (data) {
        instance.receivedBytes += data.length;

        String decoded;
        if (instance.encoding == 'base64') {
          decoded = base64Encode(data);
        } else {
          decoded = utf8.decode(data, allowMalformed: true);
        }

        eventEmitter?.call('tcpServer.data', {
          'serverId': instance.id,
          'clientId': clientId,
          'data': decoded,
          'encoding': instance.encoding,
          'bytes': data.length,
          'remoteAddress': remoteAddress,
        });
      },
      onError: (error) {
        BridgeLogger.error('TcpServer', 'Client error [$clientId]: $error');
        instance.clients.remove(clientId);

        eventEmitter?.call('tcpServer.clientError', {
          'serverId': instance.id,
          'clientId': clientId,
          'error': error.toString(),
        });
      },
      onDone: () {
        instance.clients.remove(clientId);

        BridgeLogger.info('TcpServer', '[${instance.id}] Client disconnected: $clientId');

        eventEmitter?.call('tcpServer.clientDisconnected', {
          'serverId': instance.id,
          'clientId': clientId,
          'totalClients': instance.clients.length,
        });
      },
    );
  }

  Future<Map<String, dynamic>> _stop(Map<String, dynamic> args) async {
    final id = args['id'] as String;
    final instance = _servers.remove(id);

    if (instance != null) {
      await instance.close();
      BridgeLogger.info('TcpServer', '[$id] Stopped');
      return {'stopped': true, 'id': id};
    }

    return {'stopped': false, 'reason': 'not_found'};
  }

  Future<Map<String, dynamic>> _stopAll() async {
    final count = _servers.length;
    for (final instance in _servers.values) {
      await instance.close();
    }
    _servers.clear();
    return {'stopped': count};
  }

  Map<String, dynamic> _sendToClient(Map<String, dynamic> args) {
    final serverId = args['serverId'] as String;
    final clientId = args['clientId'] as String;
    final data = args['data'];
    final encoding = args['encoding'] as String? ?? 'utf8';

    final instance = _servers[serverId];
    if (instance == null) return {'sent': false, 'reason': 'server_not_found'};

    final client = instance.clients[clientId];
    if (client == null) return {'sent': false, 'reason': 'client_not_found'};

    try {
      if (encoding == 'base64' && data is String) {
        client.add(base64Decode(data));
      } else {
        client.write(data.toString());
      }

      instance.sentBytes += data.toString().length;
      return {'sent': true, 'clientId': clientId};
    } catch (e) {
      return {'sent': false, 'error': e.toString()};
    }
  }

  Map<String, dynamic> _sendToAll(Map<String, dynamic> args) {
    final serverId = args['serverId'] as String;
    final data = args['data'];
    final excludeClient = args['exclude'] as String?;

    final instance = _servers[serverId];
    if (instance == null) return {'sent': 0, 'reason': 'server_not_found'};

    int sentCount = 0;
    final payload = data.toString();

    for (final entry in instance.clients.entries) {
      if (entry.key == excludeClient) continue;
      try {
        entry.value.write(payload);
        sentCount++;
      } catch (_) {}
    }

    return {'sent': sentCount, 'totalClients': instance.clients.length};
  }

  Future<Map<String, dynamic>> _disconnectClient(Map<String, dynamic> args) async {
    final serverId = args['serverId'] as String;
    final clientId = args['clientId'] as String;

    final instance = _servers[serverId];
    if (instance == null) return {'disconnected': false, 'reason': 'server_not_found'};

    final client = instance.clients.remove(clientId);
    if (client != null) {
      await client.close();
      return {'disconnected': true, 'clientId': clientId};
    }

    return {'disconnected': false, 'reason': 'client_not_found'};
  }

  Future<Map<String, dynamic>> _disconnectAllClients(Map<String, dynamic> args) async {
    final serverId = args['serverId'] as String;
    final instance = _servers[serverId];
    if (instance == null) return {'disconnected': 0};

    final count = instance.clients.length;
    for (final client in instance.clients.values) {
      await client.close();
    }
    instance.clients.clear();

    return {'disconnected': count};
  }

  Map<String, dynamic> _getClients(Map<String, dynamic> args) {
    final serverId = args['serverId'] as String;
    final instance = _servers[serverId];

    if (instance == null) return {'clients': <dynamic>[], 'count': 0};

    return {
      'clients': instance.clients.entries.map((e) {
        return {
          'clientId': e.key,
          'remoteAddress': e.value.remoteAddress.address,
          'remotePort': e.value.remotePort,
        };
      }).toList(),
      'count': instance.clients.length,
    };
  }

  Map<String, dynamic> _getServers() {
    return {
      'servers': _servers.values.map((s) {
        return {
          'id': s.id,
          'port': s.server.port,
          'clients': s.clients.length,
          'maxClients': s.maxClients,
          'sentBytes': s.sentBytes,
          'receivedBytes': s.receivedBytes,
        };
      }).toList(),
      'count': _servers.length,
    };
  }

  @override
  Future<ValidationResult> validateArgs(String method, Map<String, dynamic> args) async {
    switch (method) {
      case 'stop':
        if (args['id'] is! String) return ValidationResult.invalid('id is required');
        return ValidationResult.valid();
      case 'sendToClient':
      case 'disconnectClient':
        if (args['serverId'] is! String) return ValidationResult.invalid('serverId is required');
        if (args['clientId'] is! String) return ValidationResult.invalid('clientId is required');
        return ValidationResult.valid();
      case 'sendToAll':
      case 'getClients':
      case 'disconnectAllClients':
        if (args['serverId'] is! String) return ValidationResult.invalid('serverId is required');
        return ValidationResult.valid();
      default:
        return ValidationResult.valid();
    }
  }
}

class _TcpServerInstance {
  final String id;
  final ServerSocket server;
  final int maxClients;
  final String encoding;
  final Map<String, Socket> clients = {};
  StreamSubscription<Socket>? subscription;
  int clientCounter = 0;
  int sentBytes = 0;
  int receivedBytes = 0;

  _TcpServerInstance({
    required this.id,
    required this.server,
    this.maxClients = 100,
    this.encoding = 'utf8',
  });

  Future<void> close() async {
    subscription?.cancel();
    for (final client in clients.values) {
      await client.close();
    }
    clients.clear();
    await server.close();
  }
}
```

---

## پلاگین ۲: UDP Server

## 📄 `lib/plugins/udp_server/lib/udp_server_plugin.dart`

```dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:sweetmelon/packages/core/lib/core.dart';
import 'package:sweetmelon/packages/plugin_engine/lib/plugin_engine.dart';

typedef UdpServerEventEmitter = Future<void> Function(String event, dynamic data);

class UdpServerPlugin extends Plugin {
  final UdpServerEventEmitter? eventEmitter;

  final Map<String, _UdpServerInstance> _servers = {};

  UdpServerPlugin({this.eventEmitter});

  @override
  String get name => 'udpServer';

  @override
  String get version => '1.0.0';

  @override
  String get description => 'UDP server for receiving datagrams';

  @override
  List<String> get supportedMethods => [
        'start',
        'stop',
        'stopAll',
        'sendTo',
        'broadcast',
        'getServers',
        'getStats',
        'getInfo',
      ];

  @override
  Future<void> onDispose() async {
    for (final server in _servers.values) {
      server.close();
    }
    _servers.clear();
  }

  @override
  Future<dynamic> onCall(String method, Map<String, dynamic> args) async {
    switch (method) {
      case 'start':
        return _start(args);
      case 'stop':
        return _stop(args);
      case 'stopAll':
        return _stopAll();
      case 'sendTo':
        return _sendTo(args);
      case 'broadcast':
        return _broadcast(args);
      case 'getServers':
        return _getServers();
      case 'getStats':
        return _getStats(args);
      case 'getInfo':
        return {
          'name': name,
          'version': version,
          'activeServers': _servers.length,
        };
      default:
        throw UnsupportedError('Method "$method" not supported');
    }
  }

  Future<Map<String, dynamic>> _start(Map<String, dynamic> args) async {
    final port = (args['port'] as num?)?.toInt() ?? 0;
    final host = args['host'] as String? ?? '0.0.0.0';
    final id = args['id'] as String? ?? 'udp_srv_${DateTime.now().millisecondsSinceEpoch}';
    final enableBroadcast = args['broadcast'] as bool? ?? true;
    final bufferSize = (args['bufferSize'] as num?)?.toInt();
    final encoding = args['encoding'] as String? ?? 'utf8';

    if (_servers.containsKey(id)) {
      return {
        'started': true,
        'alreadyRunning': true,
        'id': id,
        'port': _servers[id]!.socket.port,
      };
    }

    try {
      final socket = await RawDatagramSocket.bind(
        host == '0.0.0.0' ? InternetAddress.anyIPv4 : InternetAddress(host),
        port,
      );

      if (enableBroadcast) {
        socket.broadcastEnabled = true;
      }

      final instance = _UdpServerInstance(
        id: id,
        socket: socket,
        encoding: encoding,
      );

      socket.listen((event) {
        if (event == RawSocketEvent.read) {
          final datagram = socket.receive();
          if (datagram != null) {
            instance.packetCount++;
            instance.receivedBytes += datagram.data.length;

            String decoded;
            if (encoding == 'base64') {
              decoded = base64Encode(datagram.data);
            } else {
              decoded = utf8.decode(datagram.data, allowMalformed: true);
            }

            // Track unique senders
            final senderId = '${datagram.address.address}:${datagram.port}';
            instance.knownSenders.add(senderId);

            eventEmitter?.call('udpServer.data', {
              'serverId': id,
              'data': decoded,
              'encoding': encoding,
              'senderAddress': datagram.address.address,
              'senderPort': datagram.port,
              'bytes': datagram.data.length,
              'packetNumber': instance.packetCount,
            });
          }
        }
      });

      _servers[id] = instance;

      BridgeLogger.info('UdpServer', '[$id] Started on port ${socket.port}');

      eventEmitter?.call('udpServer.started', {
        'serverId': id,
        'port': socket.port,
        'host': host,
        'broadcast': enableBroadcast,
      });

      return {
        'started': true,
        'alreadyRunning': false,
        'id': id,
        'port': socket.port,
        'host': host,
      };
    } catch (e) {
      return {'started': false, 'error': e.toString()};
    }
  }

  Map<String, dynamic> _sendTo(Map<String, dynamic> args) {
    final serverId = args['serverId'] as String;
    final data = args['data'] as String;
    final targetHost = args['host'] as String;
    final targetPort = (args['port'] as num).toInt();
    final encoding = args['encoding'] as String? ?? 'utf8';

    final instance = _servers[serverId];
    if (instance == null) return {'sent': false, 'reason': 'server_not_found'};

    try {
      List<int> bytes;
      if (encoding == 'base64') {
        bytes = base64Decode(data);
      } else {
        bytes = utf8.encode(data);
      }

      final sent = instance.socket.send(bytes, InternetAddress(targetHost), targetPort);
      instance.sentBytes += sent;

      return {'sent': true, 'bytes': sent};
    } catch (e) {
      return {'sent': false, 'error': e.toString()};
    }
  }

  Map<String, dynamic> _broadcast(Map<String, dynamic> args) {
    final serverId = args['serverId'] as String;
    final data = args['data'] as String;
    final targetPort = (args['port'] as num).toInt();

    final instance = _servers[serverId];
    if (instance == null) return {'sent': false, 'reason': 'server_not_found'};

    try {
      instance.socket.broadcastEnabled = true;
      final bytes = utf8.encode(data);
      final sent = instance.socket.send(
        bytes,
        InternetAddress('255.255.255.255'),
        targetPort,
      );

      instance.sentBytes += sent;
      return {'sent': true, 'bytes': sent, 'broadcast': true};
    } catch (e) {
      return {'sent': false, 'error': e.toString()};
    }
  }

  Map<String, dynamic> _stop(Map<String, dynamic> args) {
    final id = args['id'] as String;
    final instance = _servers.remove(id);

    if (instance != null) {
      instance.close();
      BridgeLogger.info('UdpServer', '[$id] Stopped');
      return {'stopped': true, 'id': id};
    }

    return {'stopped': false, 'reason': 'not_found'};
  }

  Map<String, dynamic> _stopAll() {
    final count = _servers.length;
    for (final instance in _servers.values) {
      instance.close();
    }
    _servers.clear();
    return {'stopped': count};
  }

  Map<String, dynamic> _getServers() {
    return {
      'servers': _servers.values.map((s) => s.toJson()).toList(),
      'count': _servers.length,
    };
  }

  Map<String, dynamic> _getStats(Map<String, dynamic> args) {
    final serverId = args['serverId'] as String;
    final instance = _servers[serverId];

    if (instance == null) return {'found': false};

    return {'found': true, ...instance.toJson()};
  }

  @override
  Future<ValidationResult> validateArgs(String method, Map<String, dynamic> args) async {
    switch (method) {
      case 'stop':
      case 'getStats':
        if (args['id'] is! String && args['serverId'] is! String) {
          return ValidationResult.invalid('id or serverId is required');
        }
        return ValidationResult.valid();
      case 'sendTo':
        if (args['serverId'] is! String) return ValidationResult.invalid('serverId is required');
        if (args['host'] is! String) return ValidationResult.invalid('host is required');
        if (args['port'] is! num) return ValidationResult.invalid('port is required');
        if (args['data'] is! String) return ValidationResult.invalid('data is required');
        return ValidationResult.valid();
      case 'broadcast':
        if (args['serverId'] is! String) return ValidationResult.invalid('serverId is required');
        if (args['port'] is! num) return ValidationResult.invalid('port is required');
        if (args['data'] is! String) return ValidationResult.invalid('data is required');
        return ValidationResult.valid();
      default:
        return ValidationResult.valid();
    }
  }
}

class _UdpServerInstance {
  final String id;
  final RawDatagramSocket socket;
  final String encoding;
  int packetCount = 0;
  int receivedBytes = 0;
  int sentBytes = 0;
  final Set<String> knownSenders = {};

  _UdpServerInstance({
    required this.id,
    required this.socket,
    this.encoding = 'utf8',
  });

  void close() {
    socket.close();
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'port': socket.port,
        'packetCount': packetCount,
        'receivedBytes': receivedBytes,
        'sentBytes': sentBytes,
        'uniqueSenders': knownSenders.length,
        'senders': knownSenders.toList(),
      };
}
```

---

## پلاگین ۳: FTP Server

## 📄 `lib/plugins/ftp_server/lib/ftp_server_plugin.dart`

```dart
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
  int _port = 0;
  bool _running = false;
  final Map<String, _FtpSession> _sessions = {};
  int _sessionCounter = 0;

  String _username = 'anonymous';
  String _password = '';
  bool _allowAnonymous = true;

  FtpServerPlugin({this.eventEmitter});

  @override
  String get name => 'ftpServer';

  @override
  String get version => '1.0.0';

  @override
  String get description => 'FTP server for file sharing on local network';

  @override
  List<String> get supportedMethods => [
        'start',
        'stop',
        'configure',
        'getClients',
        'disconnectClient',
        'getStats',
        'getInfo',
      ];

  @override
  Future<void> onDispose() async {
    await _stop();
  }

  @override
  Future<dynamic> onCall(String method, Map<String, dynamic> args) async {
    switch (method) {
      case 'start':
        return _start(args);
      case 'stop':
        return _stop();
      case 'configure':
        return _configure(args);
      case 'getClients':
        return _getClients();
      case 'disconnectClient':
        return _disconnectClient(args);
      case 'getStats':
        return _getStats();
      case 'getInfo':
        return {
          'name': name,
          'version': version,
          'running': _running,
          'port': _port,
          'rootDir': _rootDir,
          'clients': _sessions.length,
        };
      default:
        throw UnsupportedError('Method "$method" not supported');
    }
  }

  Map<String, dynamic> _configure(Map<String, dynamic> args) {
    _username = args['username'] as String? ?? 'anonymous';
    _password = args['password'] as String? ?? '';
    _allowAnonymous = args['allowAnonymous'] as bool? ?? true;

    return {
      'configured': true,
      'username': _username,
      'allowAnonymous': _allowAnonymous,
    };
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

    if (_rootDir == null || _rootDir!.isEmpty) {
      return {'started': false, 'reason': 'rootDir is required'};
    }

    final rootDirectory = Directory(_rootDir!);
    if (!await rootDirectory.exists()) {
      await rootDirectory.create(recursive: true);
    }

    try {
      _server = await ServerSocket.bind(
        host == '0.0.0.0' ? InternetAddress.anyIPv4 : InternetAddress(host),
        port,
      );

      _port = _server!.port;
      _running = true;

      _server!.listen(_handleNewConnection);

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

  void _handleNewConnection(Socket client) {
    _sessionCounter++;
    final sessionId = 'ftp_client_$_sessionCounter';

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
      'remoteAddress': client.remoteAddress.address,
      'totalClients': _sessions.length,
    });

    // Welcome message
    client.write('220 Sweetmelon FTP Server Ready\r\n');

    client.listen(
      (data) async {
        final command = utf8.decode(data).trim();
        await _handleCommand(session, command);
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

  Future<void> _handleCommand(_FtpSession session, String rawCommand) async {
    final parts = rawCommand.split(' ');
    final cmd = parts[0].toUpperCase();
    final arg = parts.length > 1 ? parts.sublist(1).join(' ') : '';

    BridgeLogger.debug('FtpServer', '[${session.id}] $cmd $arg');

    eventEmitter?.call('ftpServer.command', {
      'sessionId': session.id,
      'command': cmd,
      'argument': arg,
    });

    switch (cmd) {
      case 'USER':
        session.username = arg;
        if (_allowAnonymous && arg == 'anonymous') {
          session.authenticated = true;
          session.socket.write('230 Login successful\r\n');
        } else {
          session.socket.write('331 Password required\r\n');
        }
        break;

      case 'PASS':
        if (session.username == _username && arg == _password) {
          session.authenticated = true;
          session.socket.write('230 Login successful\r\n');
        } else if (_allowAnonymous && session.username == 'anonymous') {
          session.authenticated = true;
          session.socket.write('230 Anonymous login accepted\r\n');
        } else {
          session.socket.write('530 Login incorrect\r\n');
        }
        break;

      case 'PWD':
        if (!session.authenticated) { session.socket.write('530 Not logged in\r\n'); break; }
        session.socket.write('257 "${session.currentDir}"\r\n');
        break;

      case 'CWD':
        if (!session.authenticated) { session.socket.write('530 Not logged in\r\n'); break; }
        final newDir = session.resolveDir(arg);
        if (await Directory(p.join(_rootDir!, newDir)).exists()) {
          session.currentDir = newDir;
          session.socket.write('250 Directory changed\r\n');
        } else {
          session.socket.write('550 Directory not found\r\n');
        }
        break;

      case 'LIST':
        if (!session.authenticated) { session.socket.write('530 Not logged in\r\n'); break; }
        await _handleList(session, arg);
        break;

      case 'PASV':
        await _handlePasv(session);
        break;

      case 'TYPE':
        session.socket.write('200 Type set\r\n');
        break;

      case 'SYST':
        session.socket.write('215 UNIX Type: L8\r\n');
        break;

      case 'FEAT':
        session.socket.write('211-Features:\r\n PASV\r\n UTF8\r\n211 End\r\n');
        break;

      case 'SIZE':
        if (!session.authenticated) { session.socket.write('530 Not logged in\r\n'); break; }
        final filePath = p.join(_rootDir!, session.resolveDir(arg));
        final file = File(filePath);
        if (await file.exists()) {
          final stat = await file.stat();
          session.socket.write('213 ${stat.size}\r\n');
        } else {
          session.socket.write('550 File not found\r\n');
        }
        break;

      case 'RETR':
        if (!session.authenticated) { session.socket.write('530 Not logged in\r\n'); break; }
        await _handleRetr(session, arg);
        break;

      case 'STOR':
        if (!session.authenticated) { session.socket.write('530 Not logged in\r\n'); break; }
        await _handleStor(session, arg);
        break;

      case 'DELE':
        if (!session.authenticated) { session.socket.write('530 Not logged in\r\n'); break; }
        final delPath = p.join(_rootDir!, session.resolveDir(arg));
        final delFile = File(delPath);
        if (await delFile.exists()) {
          await delFile.delete();
          session.socket.write('250 File deleted\r\n');
          session.filesTransferred++;
        } else {
          session.socket.write('550 File not found\r\n');
        }
        break;

      case 'MKD':
        if (!session.authenticated) { session.socket.write('530 Not logged in\r\n'); break; }
        final mkdPath = p.join(_rootDir!, session.resolveDir(arg));
        await Directory(mkdPath).create(recursive: true);
        session.socket.write('257 "$arg" created\r\n');
        break;

      case 'RMD':
        if (!session.authenticated) { session.socket.write('530 Not logged in\r\n'); break; }
        final rmdPath = p.join(_rootDir!, session.resolveDir(arg));
        final rmdDir = Directory(rmdPath);
        if (await rmdDir.exists()) {
          await rmdDir.delete(recursive: true);
          session.socket.write('250 Directory removed\r\n');
        } else {
          session.socket.write('550 Directory not found\r\n');
        }
        break;

      case 'QUIT':
        session.socket.write('221 Goodbye\r\n');
        await session.socket.close();
        _sessions.remove(session.id);
        break;

      case 'NOOP':
        session.socket.write('200 OK\r\n');
        break;

      default:
        session.socket.write('502 Command not implemented\r\n');
    }
  }

  Future<void> _handlePasv(_FtpSession session) async {
    try {
      final dataServer = await ServerSocket.bind(InternetAddress.anyIPv4, 0);
      session.dataServer = dataServer;

      final port = dataServer.port;
      final p1 = port >> 8;
      final p2 = port & 0xFF;

      final ip = (await NetworkInterface.list(type: InternetAddressType.IPv4))
          .expand((i) => i.addresses)
          .firstWhere((a) => !a.isLoopback, orElse: () => InternetAddress('127.0.0.1'))
          .address
          .replaceAll('.', ',');

      session.socket.write('227 Entering Passive Mode ($ip,$p1,$p2)\r\n');
    } catch (e) {
      session.socket.write('425 Cannot open passive connection\r\n');
    }
  }

  Future<void> _handleList(_FtpSession session, String arg) async {
    if (session.dataServer == null) {
      session.socket.write('425 Use PASV first\r\n');
      return;
    }

    session.socket.write('150 Opening data connection\r\n');

    final dataClient = await session.dataServer!.first;

    final dirPath = arg.isNotEmpty
        ? p.join(_rootDir!, session.resolveDir(arg))
        : p.join(_rootDir!, session.currentDir);

    final dir = Directory(dirPath);

    if (await dir.exists()) {
      await for (final entity in dir.list()) {
        final stat = await entity.stat();
        final name = p.basename(entity.path);
        final isDir = entity is Directory;
        final perm = isDir ? 'drwxr-xr-x' : '-rw-r--r--';
        final size = stat.size.toString().padLeft(10);
        final date = _formatFtpDate(stat.modified);

        dataClient.write('$perm   1 ftp ftp $size $date $name\r\n');
      }
    }

    await dataClient.close();
    session.dataServer?.close();
    session.dataServer = null;

    session.socket.write('226 Transfer complete\r\n');
  }

  Future<void> _handleRetr(_FtpSession session, String fileName) async {
    if (session.dataServer == null) {
      session.socket.write('425 Use PASV first\r\n');
      return;
    }

    final filePath = p.join(_rootDir!, session.resolveDir(fileName));
    final file = File(filePath);

    if (!await file.exists()) {
      session.socket.write('550 File not found\r\n');
      return;
    }

    session.socket.write('150 Opening data connection\r\n');

    final dataClient = await session.dataServer!.first;
    final bytes = await file.readAsBytes();
    dataClient.add(bytes);
    await dataClient.close();

    session.dataServer?.close();
    session.dataServer = null;
    session.bytesTransferred += bytes.length;
    session.filesTransferred++;

    session.socket.write('226 Transfer complete\r\n');

    eventEmitter?.call('ftpServer.fileDownloaded', {
      'sessionId': session.id,
      'file': fileName,
      'size': bytes.length,
    });
  }

  Future<void> _handleStor(_FtpSession session, String fileName) async {
    if (session.dataServer == null) {
      session.socket.write('425 Use PASV first\r\n');
      return;
    }

    session.socket.write('150 Opening data connection\r\n');

    final dataClient = await session.dataServer!.first;
    final filePath = p.join(_rootDir!, session.resolveDir(fileName));
    final file = File(filePath);
    await file.parent.create(recursive: true);

    final sink = file.openWrite();
    int totalBytes = 0;

    await for (final chunk in dataClient) {
      sink.add(chunk);
      totalBytes += chunk.length;
    }

    await sink.flush();
    await sink.close();

    session.dataServer?.close();
    session.dataServer = null;
    session.bytesTransferred += totalBytes;
    session.filesTransferred++;

    session.socket.write('226 Transfer complete\r\n');

    eventEmitter?.call('ftpServer.fileUploaded', {
      'sessionId': session.id,
      'file': fileName,
      'size': totalBytes,
    });
  }

  Future<Map<String, dynamic>> _stop() async {
    if (!_running) return {'stopped': false, 'reason': 'not_running'};

    for (final session in _sessions.values) {
      session.socket.write('421 Server shutting down\r\n');
      await session.socket.close();
    }
    _sessions.clear();

    await _server?.close();
    _server = null;
    _running = false;

    return {'stopped': true};
  }

  Map<String, dynamic> _getClients() {
    return {
      'clients': _sessions.values.map((s) => s.toJson()).toList(),
      'count': _sessions.length,
    };
  }

  Future<Map<String, dynamic>> _disconnectClient(Map<String, dynamic> args) async {
    final sessionId = args['sessionId'] as String;
    final session = _sessions.remove(sessionId);

    if (session != null) {
      session.socket.write('421 Disconnected by server\r\n');
      await session.socket.close();
      return {'disconnected': true};
    }

    return {'disconnected': false, 'reason': 'not_found'};
  }

  Map<String, dynamic> _getStats() {
    int totalBytes = 0;
    int totalFiles = 0;
    for (final s in _sessions.values) {
      totalBytes += s.bytesTransferred;
      totalFiles += s.filesTransferred;
    }

    return {
      'running': _running,
      'port': _port,
      'rootDir': _rootDir,
      'totalClients': _sessions.length,
      'totalBytesTransferred': totalBytes,
      'totalFilesTransferred': totalFiles,
    };
  }

  String _formatFtpDate(DateTime dt) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${months[dt.month - 1]} ${dt.day.toString().padLeft(2)} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Future<ValidationResult> validateArgs(String method, Map<String, dynamic> args) async {
    switch (method) {
      case 'start':
        if (args['rootDir'] is! String || (args['rootDir'] as String).isEmpty) {
          return ValidationResult.invalid('rootDir is required');
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
  String username = '';
  bool authenticated = false;
  String currentDir = '/';
  ServerSocket? dataServer;
  int bytesTransferred = 0;
  int filesTransferred = 0;
  final DateTime connectedAt = DateTime.now();

  _FtpSession({
    required this.id,
    required this.socket,
    required this.rootDir,
    required this.remoteAddress,
  });

  String resolveDir(String path) {
    if (path.startsWith('/')) return path;
    return p.normalize(p.join(currentDir, path));
  }

  Map<String, dynamic> toJson() => {
        'sessionId': id,
        'remoteAddress': remoteAddress,
        'username': username,
        'authenticated': authenticated,
        'currentDir': currentDir,
        'bytesTransferred': bytesTransferred,
        'filesTransferred': filesTransferred,
        'connectedAt': connectedAt.toIso8601String(),
      };
}
```

---

## پلاگین ۴: SSH Server

## 📄 `lib/plugins/ssh_server/lib/ssh_server_plugin.dart`

```dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:sweetmelon/packages/core/lib/core.dart';
import 'package:sweetmelon/packages/plugin_engine/lib/plugin_engine.dart';

typedef SshServerEventEmitter = Future<void> Function(String event, dynamic data);

/// SSH Server ساده‌شده — اجرای command روی دستگاه
/// توجه: این یک SSH server واقعی نیست (نیاز به crypto handshake داره)
/// بلکه یک TCP command server هست که ساختار مشابه SSH داره
class SshServerPlugin extends Plugin {
  final SshServerEventEmitter? eventEmitter;

  ServerSocket? _server;
  int _port = 0;
  bool _running = false;
  final Map<String, _SshSession> _sessions = {};
  int _sessionCounter = 0;

  String _username = 'admin';
  String _password = 'admin';
  final Set<String> _allowedCommands = {};
  final Set<String> _blockedCommands = {'rm -rf', 'format', 'mkfs', 'dd'};
  bool _allowAllCommands = false;

  SshServerPlugin({this.eventEmitter});

  @override
  String get name => 'sshServer';

  @override
  String get version => '1.0.0';

  @override
  String get description => 'Command server with SSH-like interface';

  @override
  List<String> get supportedMethods => [
        'start',
        'stop',
        'configure',
        'addAllowedCommand',
        'addBlockedCommand',
        'getClients',
        'disconnectClient',
        'getCommandLog',
        'getInfo',
      ];

  @override
  Future<void> onDispose() async {
    await _stop();
  }

  @override
  Future<dynamic> onCall(String method, Map<String, dynamic> args) async {
    switch (method) {
      case 'start':
        return _start(args);
      case 'stop':
        return _stop();
      case 'configure':
        return _configure(args);
      case 'addAllowedCommand':
        return _addAllowedCommand(args);
      case 'addBlockedCommand':
        return _addBlockedCommand(args);
      case 'getClients':
        return _getClients();
      case 'disconnectClient':
        return _disconnectClient(args);
      case 'getCommandLog':
        return _getCommandLog(args);
      case 'getInfo':
        return {
          'name': name,
          'version': version,
          'running': _running,
          'port': _port,
          'clients': _sessions.length,
          'allowAllCommands': _allowAllCommands,
        };
      default:
        throw UnsupportedError('Method "$method" not supported');
    }
  }

  Map<String, dynamic> _configure(Map<String, dynamic> args) {
    _username = args['username'] as String? ?? _username;
    _password = args['password'] as String? ?? _password;
    _allowAllCommands = args['allowAllCommands'] as bool? ?? false;

    if (args['allowedCommands'] is List) {
      _allowedCommands.addAll(
        List<String>.from(args['allowedCommands'] as List),
      );
    }

    return {
      'configured': true,
      'username': _username,
      'allowAllCommands': _allowAllCommands,
      'allowedCommands': _allowedCommands.toList(),
      'blockedCommands': _blockedCommands.toList(),
    };
  }

  Map<String, dynamic> _addAllowedCommand(Map<String, dynamic> args) {
    final command = args['command'] as String;
    _allowedCommands.add(command);
    return {'added': true, 'command': command};
  }

  Map<String, dynamic> _addBlockedCommand(Map<String, dynamic> args) {
    final command = args['command'] as String;
    _blockedCommands.add(command);
    return {'added': true, 'command': command};
  }

  Future<Map<String, dynamic>> _start(Map<String, dynamic> args) async {
    if (_running) {
      return {'started': true, 'alreadyRunning': true, 'port': _port};
    }

    final port = (args['port'] as num?)?.toInt() ?? 2222;
    final host = args['host'] as String? ?? '0.0.0.0';

    try {
      _server = await ServerSocket.bind(
        host == '0.0.0.0' ? InternetAddress.anyIPv4 : InternetAddress(host),
        port,
      );

      _port = _server!.port;
      _running = true;

      _server!.listen(_handleNewConnection);

      BridgeLogger.info('SshServer', 'Started on port $_port');

      eventEmitter?.call('sshServer.started', {
        'port': _port,
        'host': host,
      });

      return {
        'started': true,
        'alreadyRunning': false,
        'port': _port,
      };
    } catch (e) {
      return {'started': false, 'error': e.toString()};
    }
  }

  void _handleNewConnection(Socket client) {
    _sessionCounter++;
    final sessionId = 'ssh_$_sessionCounter';

    final session = _SshSession(
      id: sessionId,
      socket: client,
      remoteAddress: client.remoteAddress.address,
    );

    _sessions[sessionId] = session;

    BridgeLogger.info('SshServer', 'Client connected: $sessionId');

    eventEmitter?.call('sshServer.clientConnected', {
      'sessionId': sessionId,
      'remoteAddress': client.remoteAddress.address,
    });

    client.write('Sweetmelon Command Server\r\n');
    client.write('Username: ');

    final buffer = StringBuffer();

    client.listen(
      (data) async {
        final input = utf8.decode(data).trim();

        if (!session.authenticated) {
          if (session.username == null) {
            session.username = input;
            client.write('Password: ');
          } else {
            if (session.username == _username && input == _password) {
              session.authenticated = true;
              client.write('Welcome! Type commands or "exit" to quit.\r\n');
              client.write('> ');
            } else {
              client.write('Authentication failed.\r\n');
              await client.close();
              _sessions.remove(sessionId);
            }
          }
          return;
        }

        // Authenticated — handle command
        if (input == 'exit' || input == 'quit') {
          client.write('Goodbye.\r\n');
          await client.close();
          _sessions.remove(sessionId);
          return;
        }

        await _executeCommand(session, input);
      },
      onDone: () {
        _sessions.remove(sessionId);
        eventEmitter?.call('sshServer.clientDisconnected', {
          'sessionId': sessionId,
        });
      },
    );
  }

  Future<void> _executeCommand(_SshSession session, String command) async {
    // Security check
    for (final blocked in _blockedCommands) {
      if (command.toLowerCase().contains(blocked.toLowerCase())) {
        session.socket.write('ERROR: Command blocked for security.\r\n> ');
        session.commandLog.add(_CommandEntry(
          command: command,
          output: 'BLOCKED',
          exitCode: -1,
        ));
        return;
      }
    }

    if (!_allowAllCommands && _allowedCommands.isNotEmpty) {
      final cmdBase = command.split(' ').first;
      if (!_allowedCommands.contains(cmdBase)) {
        session.socket.write('ERROR: Command "$cmdBase" not in whitelist.\r\n> ');
        return;
      }
    }

    BridgeLogger.info('SshServer', '[${session.id}] Executing: $command');

    eventEmitter?.call('sshServer.command', {
      'sessionId': session.id,
      'command': command,
    });

    try {
      final parts = command.split(' ');
      final executable = parts[0];
      final arguments = parts.length > 1 ? parts.sublist(1) : <String>[];

      final result = await Process.run(
        executable,
        arguments,
        runInShell: true,
      ).timeout(const Duration(seconds: 30));

      final output = result.stdout.toString();
      final error = result.stderr.toString();

      session.commandLog.add(_CommandEntry(
        command: command,
        output: output + error,
        exitCode: result.exitCode,
      ));

      if (output.isNotEmpty) session.socket.write(output);
      if (error.isNotEmpty) session.socket.write(error);
      if (!output.endsWith('\n') && !error.endsWith('\n')) {
        session.socket.write('\r\n');
      }

      session.socket.write('> ');

      eventEmitter?.call('sshServer.commandResult', {
        'sessionId': session.id,
        'command': command,
        'exitCode': result.exitCode,
        'outputLength': output.length + error.length,
      });
    } catch (e) {
      session.socket.write('ERROR: ${e.toString()}\r\n> ');

      session.commandLog.add(_CommandEntry(
        command: command,
        output: 'ERROR: $e',
        exitCode: -1,
      ));
    }
  }

  Future<Map<String, dynamic>> _stop() async {
    if (!_running) return {'stopped': false};

    for (final session in _sessions.values) {
      session.socket.write('Server shutting down.\r\n');
      await session.socket.close();
    }
    _sessions.clear();

    await _server?.close();
    _server = null;
    _running = false;

    return {'stopped': true};
  }

  Map<String, dynamic> _getClients() {
    return {
      'clients': _sessions.values.map((s) => s.toJson()).toList(),
      'count': _sessions.length,
    };
  }

  Future<Map<String, dynamic>> _disconnectClient(Map<String, dynamic> args) async {
    final sessionId = args['sessionId'] as String;
    final session = _sessions.remove(sessionId);

    if (session != null) {
      session.socket.write('Disconnected by server.\r\n');
      await session.socket.close();
      return {'disconnected': true};
    }

    return {'disconnected': false};
  }

  Map<String, dynamic> _getCommandLog(Map<String, dynamic> args) {
    final sessionId = args['sessionId'] as String;
    final session = _sessions[sessionId];

    if (session == null) return {'log': <dynamic>[], 'found': false};

    return {
      'found': true,
      'log': session.commandLog.map((e) => e.toJson()).toList(),
      'count': session.commandLog.length,
    };
  }

  @override
  Future<ValidationResult> validateArgs(String method, Map<String, dynamic> args) async {
    switch (method) {
      case 'start':
        return ValidationResult.valid();
      case 'disconnectClient':
      case 'getCommandLog':
        if (args['sessionId'] is! String) {
          return ValidationResult.invalid('sessionId is required');
        }
        return ValidationResult.valid();
      default:
        return ValidationResult.valid();
    }
  }
}

class _SshSession {
  final String id;
  final Socket socket;
  final String remoteAddress;
  String? username;
  bool authenticated = false;
  final List<_CommandEntry> commandLog = [];
  final DateTime connectedAt = DateTime.now();

  _SshSession({
    required this.id,
    required this.socket,
    required this.remoteAddress,
  });

  Map<String, dynamic> toJson() => {
        'sessionId': id,
        'remoteAddress': remoteAddress,
        'username': username,
        'authenticated': authenticated,
        'commandCount': commandLog.length,
        'connectedAt': connectedAt.toIso8601String(),
      };
}

class _CommandEntry {
  final String command;
  final String output;
  final int exitCode;
  final DateTime timestamp = DateTime.now();

  _CommandEntry({
    required this.command,
    required this.output,
    required this.exitCode,
  });

  Map<String, dynamic> toJson() => {
        'command': command,
        'output': output.length > 500 ? '${output.substring(0, 500)}...' : output,
        'exitCode': exitCode,
        'timestamp': timestamp.toIso8601String(),
      };
}
```

---

# بخش ۲: pubspec‌ها

## 📄 `lib/plugins/tcp_server/pubspec.yaml`

```yaml
name: tcp_server_plugin
description: TCP server plugin
version: 1.0.0
environment:
  sdk: ^3.0.0
dependencies:
  flutter:
    sdk: flutter
  plugin_engine:
    path: ../../packages/plugin_engine
  core:
    path: ../../packages/core
```

## 📄 `lib/plugins/udp_server/pubspec.yaml`

```yaml
name: udp_server_plugin
description: UDP server plugin
version: 1.0.0
environment:
  sdk: ^3.0.0
dependencies:
  flutter:
    sdk: flutter
  plugin_engine:
    path: ../../packages/plugin_engine
  core:
    path: ../../packages/core
```

## 📄 `lib/plugins/ftp_server/pubspec.yaml`

```yaml
name: ftp_server_plugin
description: FTP server plugin
version: 1.0.0
environment:
  sdk: ^3.0.0
dependencies:
  flutter:
    sdk: flutter
  plugin_engine:
    path: ../../packages/plugin_engine
  core:
    path: ../../packages/core
  path: ^1.9.0
```

## 📄 `lib/plugins/ssh_server/pubspec.yaml`

```yaml
name: ssh_server_plugin
description: SSH-like command server plugin
version: 1.0.0
environment:
  sdk: ^3.0.0
dependencies:
  flutter:
    sdk: flutter
  plugin_engine:
    path: ../../packages/plugin_engine
  core:
    path: ../../packages/core
```

---

# بخش ۳: NativeSDK

```javascript
    tcpServer: {
      start: function (o) { return call('tcpServer', 'start', o || {}); },
      stop: function (id) { return call('tcpServer', 'stop', { id: id }); },
      stopAll: function () { return call('tcpServer', 'stopAll', {}); },
      sendToClient: function (serverId, clientId, data) { return call('tcpServer', 'sendToClient', { serverId: serverId, clientId: clientId, data: data }); },
      sendToAll: function (serverId, data, exclude) { return call('tcpServer', 'sendToAll', { serverId: serverId, data: data, exclude: exclude }); },
      disconnectClient: function (serverId, clientId) { return call('tcpServer', 'disconnectClient', { serverId: serverId, clientId: clientId }); },
      getClients: function (serverId) { return call('tcpServer', 'getClients', { serverId: serverId }); },
      getServers: function () { return call('tcpServer', 'getServers', {}); },
      getInfo: function () { return call('tcpServer', 'getInfo', {}); }
    },

    udpServer: {
      start: function (o) { return call('udpServer', 'start', o || {}); },
      stop: function (id) { return call('udpServer', 'stop', { id: id }); },
      stopAll: function () { return call('udpServer', 'stopAll', {}); },
      sendTo: function (serverId, data, host, port) { return call('udpServer', 'sendTo', { serverId: serverId, data: data, host: host, port: port }); },
      broadcast: function (serverId, data, port) { return call('udpServer', 'broadcast', { serverId: serverId, data: data, port: port }); },
      getServers: function () { return call('udpServer', 'getServers', {}); },
      getStats: function (serverId) { return call('udpServer', 'getStats', { serverId: serverId }); },
      getInfo: function () { return call('udpServer', 'getInfo', {}); }
    },

    ftpServer: {
      start: function (rootDir, o) { return call('ftpServer', 'start', Object.assign({ rootDir: rootDir }, o || {})); },
      stop: function () { return call('ftpServer', 'stop', {}); },
      configure: function (o) { return call('ftpServer', 'configure', o || {}); },
      getClients: function () { return call('ftpServer', 'getClients', {}); },
      disconnectClient: function (sessionId) { return call('ftpServer', 'disconnectClient', { sessionId: sessionId }); },
      getStats: function () { return call('ftpServer', 'getStats', {}); },
      getInfo: function () { return call('ftpServer', 'getInfo', {}); }
    },

    sshServer: {
      start: function (o) { return call('sshServer', 'start', o || {}); },
      stop: function () { return call('sshServer', 'stop', {}); },
      configure: function (o) { return call('sshServer', 'configure', o || {}); },
      addAllowedCommand: function (cmd) { return call('sshServer', 'addAllowedCommand', { command: cmd }); },
      addBlockedCommand: function (cmd) { return call('sshServer', 'addBlockedCommand', { command: cmd }); },
      getClients: function () { return call('sshServer', 'getClients', {}); },
      disconnectClient: function (sessionId) { return call('sshServer', 'disconnectClient', { sessionId: sessionId }); },
      getCommandLog: function (sessionId) { return call('sshServer', 'getCommandLog', { sessionId: sessionId }); },
      getInfo: function () { return call('sshServer', 'getInfo', {}); }
    },
```

---

# بخش ۴: README‌ها — همه ۱۲ پلاگین شبکه

## 📄 `lib/plugins/tcp_server/README.md`

```markdown
# TCP Server Plugin

Accept incoming TCP connections and exchange data.

## Plugin Name
`tcpServer`

## Methods

| Method | Description |
|--------|-------------|
| `start` | Start TCP server on port |
| `stop` | Stop specific server |
| `stopAll` | Stop all servers |
| `sendToClient` | Send data to specific client |
| `sendToAll` | Broadcast to all clients |
| `disconnectClient` | Disconnect a client |
| `getClients` | List connected clients |
| `getServers` | List running servers |

### start
| Param | Type | Default |
|-------|------|---------|
| `port` | `number` | `0` (random) |
| `host` | `string` | `"0.0.0.0"` |
| `id` | `string` | auto |
| `maxClients` | `number` | `100` |
| `encoding` | `string` | `"utf8"` |

## Events
| Event | Data |
|-------|------|
| `tcpServer.started` | `{ serverId, port }` |
| `tcpServer.clientConnected` | `{ serverId, clientId, remoteAddress }` |
| `tcpServer.data` | `{ serverId, clientId, data, bytes }` |
| `tcpServer.clientDisconnected` | `{ serverId, clientId }` |

## Usage
```javascript
// Start server
const srv = await NativeSDK.tcpServer.start({ port: 9000, maxClients: 50 });
console.log('Server on port', srv.port);

// Handle data
NativeSDK.on('tcpServer.data', (msg) => {
  console.log(`[${msg.clientId}]: ${msg.data}`);
  // Echo back
  NativeSDK.tcpServer.sendToClient(msg.serverId, msg.clientId, 'ACK: ' + msg.data);
});

// Handle connections
NativeSDK.on('tcpServer.clientConnected', (info) => {
  NativeSDK.tcpServer.sendToClient(info.serverId, info.clientId, 'Welcome!');
});

// Broadcast to all
await NativeSDK.tcpServer.sendToAll(srv.id, 'Server announcement');

// List clients
const { clients } = await NativeSDK.tcpServer.getClients(srv.id);

// Stop
await NativeSDK.tcpServer.stop(srv.id);
```
```

---

## 📄 `lib/plugins/udp_server/README.md`

```markdown
# UDP Server Plugin

Receive UDP datagrams and respond.

## Plugin Name
`udpServer`

## Methods

| Method | Description |
|--------|-------------|
| `start` | Bind UDP socket |
| `stop` | Close socket |
| `sendTo` | Send to specific address |
| `broadcast` | Send broadcast |
| `getServers` | List active sockets |
| `getStats` | Get statistics |

### start
| Param | Type | Default |
|-------|------|---------|
| `port` | `number` | `0` |
| `host` | `string` | `"0.0.0.0"` |
| `broadcast` | `bool` | `true` |
| `encoding` | `string` | `"utf8"` |

## Events
| Event | Data |
|-------|------|
| `udpServer.started` | `{ serverId, port }` |
| `udpServer.data` | `{ serverId, data, senderAddress, senderPort, bytes }` |

## Usage
```javascript
// IoT sensor receiver
const srv = await NativeSDK.udpServer.start({ port: 5000 });

NativeSDK.on('udpServer.data', (packet) => {
  const sensor = JSON.parse(packet.data);
  console.log(`Sensor ${packet.senderAddress}: temp=${sensor.temp}°C`);
  
  // Respond
  NativeSDK.udpServer.sendTo(srv.id, 'ACK', packet.senderAddress, packet.senderPort);
});

// Discovery broadcast
await NativeSDK.udpServer.broadcast(srv.id, JSON.stringify({
  type: 'discover',
  name: 'MyDevice'
}), 5000);

// Stats
const stats = await NativeSDK.udpServer.getStats(srv.id);
console.log(`Packets: ${stats.packetCount}, Senders: ${stats.uniqueSenders}`);
```
```

---

## 📄 `lib/plugins/ftp_server/README.md`

```markdown
# FTP Server Plugin

Share files over local network via FTP.

## Plugin Name
`ftpServer`

## Methods

| Method | Description |
|--------|-------------|
| `start` | Start FTP server |
| `stop` | Stop server |
| `configure` | Set credentials |
| `getClients` | List connected clients |
| `getStats` | Server statistics |

### configure
| Param | Type | Default |
|-------|------|---------|
| `username` | `string` | `"anonymous"` |
| `password` | `string` | `""` |
| `allowAnonymous` | `bool` | `true` |

### start
| Param | Type | Default |
|-------|------|---------|
| `rootDir` | `string` | ✅ required |
| `port` | `number` | `2121` |

## Events
| Event | Data |
|-------|------|
| `ftpServer.started` | `{ port, rootDir }` |
| `ftpServer.clientConnected` | `{ sessionId, remoteAddress }` |
| `ftpServer.clientDisconnected` | `{ sessionId }` |
| `ftpServer.fileUploaded` | `{ sessionId, file, size }` |
| `ftpServer.fileDownloaded` | `{ sessionId, file, size }` |
| `ftpServer.command` | `{ sessionId, command }` |

## Usage
```javascript
// Get a directory to share
const dirs = await NativeSDK.fileSystem.getDirectories();
const shareDir = dirs.documents + '/shared';

// Configure
await NativeSDK.ftpServer.configure({
  username: 'admin',
  password: 'secret123',
  allowAnonymous: false
});

// Start
const srv = await NativeSDK.ftpServer.start(shareDir, { port: 2121 });
console.log('FTP Server:', srv.url);

// Get local IP for sharing
const { ip } = await NativeSDK.networkInfo.getLocalIp();
console.log(`Connect: ftp://${ip}:${srv.port}`);

// Monitor
NativeSDK.on('ftpServer.fileUploaded', (data) => {
  console.log(`File received: ${data.file} (${data.size} bytes)`);
});

// Stop
await NativeSDK.ftpServer.stop();
```
```

---

## 📄 `lib/plugins/ssh_server/README.md`

```markdown
# SSH Server Plugin

Command server with authentication and whitelisting.

## Plugin Name
`sshServer`

## Methods

| Method | Description |
|--------|-------------|
| `start` | Start server |
| `stop` | Stop server |
| `configure` | Set credentials and command rules |
| `addAllowedCommand` | Whitelist a command |
| `addBlockedCommand` | Block a command |
| `getClients` | List sessions |
| `getCommandLog` | Get command history |

### configure
| Param | Type | Default |
|-------|------|---------|
| `username` | `string` | `"admin"` |
| `password` | `string` | `"admin"` |
| `allowAllCommands` | `bool` | `false` |
| `allowedCommands` | `string[]` | — |

### start
| Param | Type | Default |
|-------|------|---------|
| `port` | `number` | `2222` |

## Events
| Event | Data |
|-------|------|
| `sshServer.started` | `{ port }` |
| `sshServer.clientConnected` | `{ sessionId, remoteAddress }` |
| `sshServer.command` | `{ sessionId, command }` |
| `sshServer.commandResult` | `{ sessionId, command, exitCode }` |

## Security
- Commands `rm -rf`, `format`, `mkfs`, `dd` are blocked by default
- Use whitelist mode for maximum security

## Usage
```javascript
// Configure with whitelist
await NativeSDK.sshServer.configure({
  username: 'admin',
  password: 'secure_password',
  allowAllCommands: false,
  allowedCommands: ['ls', 'cat', 'echo', 'date', 'whoami', 'uname', 'df', 'free']
});

// Start
const srv = await NativeSDK.sshServer.start({ port: 2222 });

const { ip } = await NativeSDK.networkInfo.getLocalIp();
console.log(`Connect via: telnet ${ip} ${srv.port}`);

// Monitor commands
NativeSDK.on('sshServer.command', (data) => {
  console.log(`[${data.sessionId}] ${data.command}`);
});

NativeSDK.on('sshServer.commandResult', (data) => {
  console.log(`Exit code: ${data.exitCode}`);
});

// View command log
const { log } = await NativeSDK.sshServer.getCommandLog('ssh_1');

// Stop
await NativeSDK.sshServer.stop();
```
```

---

# خلاصه نهایی

## پلاگین‌های Network Toolkit کامل

| # | پلاگین | نام JS | Client/Server | Events |
|---|--------|--------|---------------|--------|
| 92 | HTTP Server | `httpServer` | Server | ✅ |
| 93 | Socket (TCP/UDP Client) | `socket` | Client | ✅ |
| 94 | Network Info | `networkInfo` | Utility | — |
| 95 | Ping/DNS | `pingDns` | Utility | — |
| 96 | WebSocket Server | `websocketServer` | Server | ✅ |
| 97 | FTP Client | `ftpClient` | Client | ✅ |
| 98 | SSH Client | `sshClient` | Client | ✅ |
| 99 | WiFi Advanced | `wifiAdvanced` | Utility | — |
| 100 | TCP Server | `tcpServer` | Server | ✅ |
| 101 | UDP Server | `udpServer` | Server | ✅ |
| 102 | FTP Server | `ftpServer` | Server | ✅ |
| 103 | SSH Server | `sshServer` | Server | ✅ |

## **مجموع کل: 103 پلاگین** 🎉

## جدول Client ↔ Server

| پروتکل | Client | Server |
|---------|--------|--------|
| **HTTP** | `http` (پلاگین ۷) | `httpServer` (پلاگین ۹۲) |
| **WebSocket** | `websocket` (پلاگین ۳۶) | `websocketServer` (پلاگین ۹۶) |
| **TCP** | `socket.tcpConnect` (پلاگین ۹۳) | `tcpServer` (پلاگین ۱۰۰) |
| **UDP** | `socket.udpBind` (پلاگین ۹۳) | `udpServer` (پلاگین ۱۰۱) |
| **FTP** | `ftpClient` (پلاگین ۹۷) | `ftpServer` (پلاگین ۱۰۲) |
| **SSH** | `sshClient` (پلاگین ۹۸) | `sshServer` (پلاگین ۱۰۳) |
| **Bluetooth** | `bluetooth` (پلاگین ۲۸) | — (BLE peripheral mode) |
