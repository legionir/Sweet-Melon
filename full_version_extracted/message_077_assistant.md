# Server Plugins + README‌های کامل

---

# بخش ۱: چهار پلاگین Server جدید

---

## پلاگین ۱: UDP Server

### 📄 `lib/plugins/udp_server/lib/udp_server_plugin.dart`

```dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:sweetmelon/packages/core/lib/core.dart';
import 'package:sweetmelon/packages/plugin_engine/lib/plugin_engine.dart';

typedef UdpServerEventEmitter = Future<void> Function(String event, dynamic data);

class UdpServerPlugin extends Plugin {
  final UdpServerEventEmitter? eventEmitter;

  final Map<String, _ManagedUdpServer> _servers = {};

  UdpServerPlugin({this.eventEmitter});

  @override
  String get name => 'udpServer';

  @override
  String get version => '1.0.0';

  @override
  String get description => 'UDP server for receiving datagrams and broadcasting';

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
    for (final s in _servers.values) {
      s.socket.close();
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
    final bufferSize = (args['bufferSize'] as num?)?.toInt() ?? 65535;

    if (_servers.containsKey(id)) {
      return {
        'started': true,
        'alreadyRunning': true,
        'id': id,
        'port': _servers[id]!.socket.port,
      };
    }

    try {
      final bindAddress = host == '0.0.0.0'
          ? InternetAddress.anyIPv4
          : InternetAddress(host);

      final socket = await RawDatagramSocket.bind(bindAddress, port);
      socket.broadcastEnabled = enableBroadcast;

      final managed = _ManagedUdpServer(
        id: id,
        socket: socket,
        host: host,
        port: socket.port,
      );

      socket.listen((event) {
        if (event == RawSocketEvent.read) {
          final datagram = socket.receive();
          if (datagram != null) {
            managed.receivedCount++;
            managed.receivedBytes += datagram.data.length;

            final senderAddr = datagram.address.address;
            final senderPort = datagram.port;

            // Track unique clients
            final clientKey = '$senderAddr:$senderPort';
            managed.clients.add(clientKey);

            String decoded;
            try {
              decoded = utf8.decode(datagram.data);
            } catch (_) {
              decoded = base64Encode(datagram.data);
            }

            eventEmitter?.call('udpServer.data', {
              'serverId': id,
              'data': decoded,
              'senderAddress': senderAddr,
              'senderPort': senderPort,
              'bytes': datagram.data.length,
              'timestamp': DateTime.now().toIso8601String(),
            });
          }
        }
      });

      _servers[id] = managed;

      BridgeLogger.info('UdpServer', '[$id] Started on port ${socket.port}');

      eventEmitter?.call('udpServer.started', {
        'id': id,
        'port': socket.port,
        'host': host,
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
    final id = args['serverId'] as String;
    final data = args['data'] as String;
    final targetHost = args['host'] as String;
    final targetPort = (args['port'] as num).toInt();

    final managed = _servers[id];
    if (managed == null) {
      return {'sent': false, 'reason': 'server_not_found'};
    }

    try {
      final bytes = utf8.encode(data);
      final sent = managed.socket.send(
        bytes,
        InternetAddress(targetHost),
        targetPort,
      );

      managed.sentCount++;
      managed.sentBytes += sent;

      return {'sent': true, 'bytes': sent};
    } catch (e) {
      return {'sent': false, 'error': e.toString()};
    }
  }

  Map<String, dynamic> _broadcast(Map<String, dynamic> args) {
    final id = args['serverId'] as String;
    final data = args['data'] as String;
    final targetPort = (args['port'] as num).toInt();
    final broadcastAddress = args['broadcastAddress'] as String? ?? '255.255.255.255';

    final managed = _servers[id];
    if (managed == null) {
      return {'sent': false, 'reason': 'server_not_found'};
    }

    try {
      managed.socket.broadcastEnabled = true;
      final bytes = utf8.encode(data);
      final sent = managed.socket.send(
        bytes,
        InternetAddress(broadcastAddress),
        targetPort,
      );

      managed.sentCount++;
      managed.sentBytes += sent;

      return {'sent': true, 'bytes': sent, 'broadcast': true};
    } catch (e) {
      return {'sent': false, 'error': e.toString()};
    }
  }

  Map<String, dynamic> _stop(Map<String, dynamic> args) {
    final id = args['id'] as String;
    final managed = _servers.remove(id);

    if (managed != null) {
      managed.socket.close();
      BridgeLogger.info('UdpServer', '[$id] Stopped');
      return {'stopped': true, 'id': id};
    }

    return {'stopped': false, 'reason': 'not_found'};
  }

  Map<String, dynamic> _stopAll() {
    final count = _servers.length;
    for (final s in _servers.values) {
      s.socket.close();
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
    final id = args['id'] as String;
    final managed = _servers[id];
    if (managed == null) {
      return {'found': false};
    }
    return {'found': true, ...managed.toJson()};
  }

  @override
  Future<ValidationResult> validateArgs(String method, Map<String, dynamic> args) async {
    switch (method) {
      case 'stop':
      case 'getStats':
        if (args['id'] is! String) return ValidationResult.invalid('id is required');
        return ValidationResult.valid();
      case 'sendTo':
        if (args['serverId'] is! String) return ValidationResult.invalid('serverId required');
        if (args['host'] is! String) return ValidationResult.invalid('host required');
        if (args['port'] is! num) return ValidationResult.invalid('port required');
        if (args['data'] is! String) return ValidationResult.invalid('data required');
        return ValidationResult.valid();
      case 'broadcast':
        if (args['serverId'] is! String) return ValidationResult.invalid('serverId required');
        if (args['port'] is! num) return ValidationResult.invalid('port required');
        if (args['data'] is! String) return ValidationResult.invalid('data required');
        return ValidationResult.valid();
      default:
        return ValidationResult.valid();
    }
  }
}

class _ManagedUdpServer {
  final String id;
  final RawDatagramSocket socket;
  final String host;
  final int port;
  int receivedCount = 0;
  int receivedBytes = 0;
  int sentCount = 0;
  int sentBytes = 0;
  final Set<String> clients = {};
  final DateTime startedAt = DateTime.now();

  _ManagedUdpServer({
    required this.id,
    required this.socket,
    required this.host,
    required this.port,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'host': host,
        'port': port,
        'receivedCount': receivedCount,
        'receivedBytes': receivedBytes,
        'sentCount': sentCount,
        'sentBytes': sentBytes,
        'uniqueClients': clients.length,
        'uptime': DateTime.now().difference(startedAt).inSeconds,
      };
}
```

### 📄 `lib/plugins/udp_server/pubspec.yaml`

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

---

## پلاگین ۲: TCP Server

### 📄 `lib/plugins/tcp_server/lib/tcp_server_plugin.dart`

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

  final Map<String, _ManagedTcpServer> _servers = {};

  TcpServerPlugin({this.eventEmitter});

  @override
  String get name => 'tcpServer';

  @override
  String get version => '1.0.0';

  @override
  String get description => 'TCP server with multi-client support';

  @override
  List<String> get supportedMethods => [
        'start',
        'stop',
        'stopAll',
        'sendToClient',
        'sendToAll',
        'disconnectClient',
        'getClients',
        'getServers',
        'getStats',
        'getInfo',
      ];

  @override
  Future<void> onDispose() async {
    for (final s in _servers.values) {
      await s.close();
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
      case 'getClients':
        return _getClients(args);
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
    final id = args['id'] as String? ?? 'tcp_srv_${DateTime.now().millisecondsSinceEpoch}';
    final maxClients = (args['maxClients'] as num?)?.toInt() ?? 100;

    if (_servers.containsKey(id)) {
      return {
        'started': true,
        'alreadyRunning': true,
        'id': id,
        'port': _servers[id]!.server.port,
      };
    }

    try {
      final bindAddress = host == '0.0.0.0'
          ? InternetAddress.anyIPv4
          : InternetAddress(host);

      final server = await ServerSocket.bind(bindAddress, port);

      final managed = _ManagedTcpServer(
        id: id,
        server: server,
        maxClients: maxClients,
      );

      managed.subscription = server.listen((clientSocket) {
        if (managed.clients.length >= maxClients) {
          clientSocket.write('Server full\n');
          clientSocket.close();
          return;
        }

        managed.clientCounter++;
        final clientId = 'client_${managed.clientCounter}';

        final client = _TcpClient(
          id: clientId,
          socket: clientSocket,
          remoteAddress: clientSocket.remoteAddress.address,
          remotePort: clientSocket.remotePort,
        );

        managed.clients[clientId] = client;

        BridgeLogger.info(
          'TcpServer',
          '[$id] Client connected: $clientId (${client.remoteAddress}:${client.remotePort})',
        );

        eventEmitter?.call('tcpServer.clientConnected', {
          'serverId': id,
          'clientId': clientId,
          'remoteAddress': client.remoteAddress,
          'remotePort': client.remotePort,
          'totalClients': managed.clients.length,
        });

        client.subscription = clientSocket.listen(
          (data) {
            client.receivedBytes += data.length;
            client.messageCount++;

            String decoded;
            try {
              decoded = utf8.decode(data);
            } catch (_) {
              decoded = base64Encode(data);
            }

            eventEmitter?.call('tcpServer.data', {
              'serverId': id,
              'clientId': clientId,
              'data': decoded,
              'bytes': data.length,
              'messageNumber': client.messageCount,
              'timestamp': DateTime.now().toIso8601String(),
            });
          },
          onError: (error) {
            BridgeLogger.error('TcpServer', '[$id] Client error [$clientId]: $error');
            managed.clients.remove(clientId);

            eventEmitter?.call('tcpServer.clientError', {
              'serverId': id,
              'clientId': clientId,
              'error': error.toString(),
            });
          },
          onDone: () {
            managed.clients.remove(clientId);

            BridgeLogger.info('TcpServer', '[$id] Client disconnected: $clientId');

            eventEmitter?.call('tcpServer.clientDisconnected', {
              'serverId': id,
              'clientId': clientId,
              'totalClients': managed.clients.length,
            });
          },
        );
      });

      _servers[id] = managed;

      BridgeLogger.info('TcpServer', '[$id] Started on port ${server.port}');

      eventEmitter?.call('tcpServer.started', {
        'id': id,
        'port': server.port,
        'host': host,
        'maxClients': maxClients,
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

  Map<String, dynamic> _sendToClient(Map<String, dynamic> args) {
    final serverId = args['serverId'] as String;
    final clientId = args['clientId'] as String;
    final data = args['data'] as String;
    final encoding = args['encoding'] as String? ?? 'utf8';

    final managed = _servers[serverId];
    if (managed == null) return {'sent': false, 'reason': 'server_not_found'};

    final client = managed.clients[clientId];
    if (client == null) return {'sent': false, 'reason': 'client_not_found'};

    try {
      if (encoding == 'base64') {
        client.socket.add(base64Decode(data));
      } else {
        client.socket.write(data);
      }

      client.sentBytes += data.length;
      return {'sent': true, 'clientId': clientId};
    } catch (e) {
      return {'sent': false, 'error': e.toString()};
    }
  }

  Map<String, dynamic> _sendToAll(Map<String, dynamic> args) {
    final serverId = args['serverId'] as String;
    final data = args['data'] as String;
    final excludeClient = args['exclude'] as String?;

    final managed = _servers[serverId];
    if (managed == null) return {'sent': 0, 'reason': 'server_not_found'};

    int sentCount = 0;

    for (final entry in managed.clients.entries) {
      if (entry.key == excludeClient) continue;
      try {
        entry.value.socket.write(data);
        entry.value.sentBytes += data.length;
        sentCount++;
      } catch (_) {}
    }

    return {'sent': sentCount, 'totalClients': managed.clients.length};
  }

  Future<Map<String, dynamic>> _disconnectClient(Map<String, dynamic> args) async {
    final serverId = args['serverId'] as String;
    final clientId = args['clientId'] as String;

    final managed = _servers[serverId];
    if (managed == null) return {'disconnected': false, 'reason': 'server_not_found'};

    final client = managed.clients.remove(clientId);
    if (client != null) {
      client.subscription?.cancel();
      await client.socket.close();
      return {'disconnected': true, 'clientId': clientId};
    }

    return {'disconnected': false, 'reason': 'client_not_found'};
  }

  Map<String, dynamic> _getClients(Map<String, dynamic> args) {
    final serverId = args['serverId'] as String;
    final managed = _servers[serverId];

    if (managed == null) return {'clients': <dynamic>[], 'reason': 'server_not_found'};

    return {
      'clients': managed.clients.values.map((c) => c.toJson()).toList(),
      'count': managed.clients.length,
    };
  }

  Future<Map<String, dynamic>> _stop(Map<String, dynamic> args) async {
    final id = args['id'] as String;
    final managed = _servers.remove(id);

    if (managed != null) {
      await managed.close();
      BridgeLogger.info('TcpServer', '[$id] Stopped');
      return {'stopped': true, 'id': id};
    }

    return {'stopped': false, 'reason': 'not_found'};
  }

  Future<Map<String, dynamic>> _stopAll() async {
    final count = _servers.length;
    for (final s in _servers.values) {
      await s.close();
    }
    _servers.clear();
    return {'stopped': count};
  }

  Map<String, dynamic> _getServers() {
    return {
      'servers': _servers.values.map((s) => {
        return {
          'id': s.id,
          'port': s.server.port,
          'clientCount': s.clients.length,
          'maxClients': s.maxClients,
          'uptime': DateTime.now().difference(s.startedAt).inSeconds,
        };
      }).toList(),
      'count': _servers.length,
    };
  }

  Map<String, dynamic> _getStats(Map<String, dynamic> args) {
    final id = args['id'] as String;
    final managed = _servers[id];
    if (managed == null) return {'found': false};

    int totalReceived = 0;
    int totalSent = 0;

    for (final c in managed.clients.values) {
      totalReceived += c.receivedBytes;
      totalSent += c.sentBytes;
    }

    return {
      'found': true,
      'id': id,
      'port': managed.server.port,
      'clients': managed.clients.length,
      'totalReceivedBytes': totalReceived,
      'totalSentBytes': totalSent,
      'totalConnections': managed.clientCounter,
      'uptime': DateTime.now().difference(managed.startedAt).inSeconds,
    };
  }

  @override
  Future<ValidationResult> validateArgs(String method, Map<String, dynamic> args) async {
    switch (method) {
      case 'stop':
      case 'getClients':
      case 'getStats':
        if (args['id'] is! String && args['serverId'] is! String) {
          return ValidationResult.invalid('id or serverId required');
        }
        return ValidationResult.valid();
      case 'sendToClient':
      case 'disconnectClient':
        if (args['serverId'] is! String) return ValidationResult.invalid('serverId required');
        if (args['clientId'] is! String) return ValidationResult.invalid('clientId required');
        return ValidationResult.valid();
      case 'sendToAll':
        if (args['serverId'] is! String) return ValidationResult.invalid('serverId required');
        if (args['data'] is! String) return ValidationResult.invalid('data required');
        return ValidationResult.valid();
      default:
        return ValidationResult.valid();
    }
  }
}

class _ManagedTcpServer {
  final String id;
  final ServerSocket server;
  final int maxClients;
  final Map<String, _TcpClient> clients = {};
  StreamSubscription<Socket>? subscription;
  int clientCounter = 0;
  final DateTime startedAt = DateTime.now();

  _ManagedTcpServer({
    required this.id,
    required this.server,
    required this.maxClients,
  });

  Future<void> close() async {
    for (final c in clients.values) {
      c.subscription?.cancel();
      await c.socket.close();
    }
    clients.clear();
    subscription?.cancel();
    await server.close();
  }
}

class _TcpClient {
  final String id;
  final Socket socket;
  final String remoteAddress;
  final int remotePort;
  StreamSubscription<Uint8List>? subscription;
  int receivedBytes = 0;
  int sentBytes = 0;
  int messageCount = 0;
  final DateTime connectedAt = DateTime.now();

  _TcpClient({
    required this.id,
    required this.socket,
    required this.remoteAddress,
    required this.remotePort,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'remoteAddress': remoteAddress,
        'remotePort': remotePort,
        'receivedBytes': receivedBytes,
        'sentBytes': sentBytes,
        'messageCount': messageCount,
        'connectedSeconds': DateTime.now().difference(connectedAt).inSeconds,
      };
}
```

### 📄 `lib/plugins/tcp_server/pubspec.yaml`

```yaml
name: tcp_server_plugin
description: TCP server with multi-client support
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

## پلاگین ۳: FTP Server

### 📄 `lib/plugins/ftp_server/lib/ftp_server_plugin.dart`

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
```

### 📄 `lib/plugins/ftp_server/pubspec.yaml`

```yaml
name: ftp_server_plugin
description: Simple FTP server plugin
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

---

## پلاگین ۴: SSH Server

### 📄 `lib/plugins/ssh_server/lib/ssh_server_plugin.dart`

```dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:sweetmelon/packages/core/lib/core.dart';
import 'package:sweetmelon/packages/plugin_engine/lib/plugin_engine.dart';

typedef SshServerEventEmitter = Future<void> Function(String event, dynamic data);

class SshServerPlugin extends Plugin {
  final SshServerEventEmitter? eventEmitter;

  ServerSocket? _server;
  bool _running = false;
  int _port = 0;
  String? _username;
  String? _password;
  int _clientCount = 0;
  final Map<String, _SshSession> _sessions = {};
  final List<String> _allowedCommands;
  final bool _sandboxMode;

  SshServerPlugin({
    this.eventEmitter,
    List<String>? allowedCommands,
    bool sandboxMode = true,
  })  : _allowedCommands = allowedCommands ?? [
          'ls', 'pwd', 'whoami', 'date', 'echo',
          'cat', 'head', 'tail', 'wc', 'grep',
          'uname', 'uptime', 'df', 'du', 'free',
          'hostname', 'id', 'env', 'printenv',
        ],
        _sandboxMode = sandboxMode;

  @override
  String get name => 'sshServer';

  @override
  String get version => '1.0.0';

  @override
  String get description => 'Simple SSH-like command server (not real SSH protocol)';

  @override
  List<String> get supportedMethods => [
        'start',
        'stop',
        'getClients',
        'getStats',
        'kickClient',
        'setAllowedCommands',
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
      case 'setAllowedCommands':
        return _setAllowedCommands(args);
      case 'getInfo':
        return {
          'name': name,
          'version': version,
          'running': _running,
          'port': _port,
          'clients': _sessions.length,
          'sandboxMode': _sandboxMode,
          'allowedCommands': _allowedCommands,
          'note': 'This is a simplified command server, not full SSH protocol',
        };
      default:
        throw UnsupportedError('Method "$method" not supported');
    }
  }

  Future<Map<String, dynamic>> _start(Map<String, dynamic> args) async {
    if (_running) {
      return {'started': true, 'alreadyRunning': true, 'port': _port};
    }

    final port = (args['port'] as num?)?.toInt() ?? 2222;
    final host = args['host'] as String? ?? '0.0.0.0';
    _username = args['username'] as String? ?? 'admin';
    _password = args['password'] as String? ?? 'admin';

    try {
      _server = await ServerSocket.bind(
        host == '0.0.0.0' ? InternetAddress.anyIPv4 : InternetAddress(host),
        port,
      );

      _port = _server!.port;
      _running = true;

      _server!.listen(_handleClient);

      BridgeLogger.info('SshServer', 'Started on port $_port');

      eventEmitter?.call('sshServer.started', {
        'port': _port,
        'host': host,
      });

      return {
        'started': true,
        'port': _port,
        'url': '$host:$_port',
      };
    } catch (e) {
      return {'started': false, 'error': e.toString()};
    }
  }

  void _handleClient(Socket client) {
    _clientCount++;
    final sessionId = 'ssh_session_$_clientCount';

    final session = _SshSession(
      id: sessionId,
      socket: client,
      remoteAddress: client.remoteAddress.address,
    );

    _sessions[sessionId] = session;

    BridgeLogger.info('SshServer', 'Client connected: $sessionId');

    eventEmitter?.call('sshServer.clientConnected', {
      'sessionId': sessionId,
      'remoteAddress': session.remoteAddress,
    });

    // Auth prompt
    _write(client, 'Sweetmelon Shell Server\nlogin: ');

    final buffer = StringBuffer();

    client.listen(
      (data) {
        final input = utf8.decode(data).trim();

        if (!session.authenticated) {
          _handleAuth(session, input);
          return;
        }

        if (input.isEmpty) {
          _write(client, '${session.username}@sweetmelon:${session.currentDir}\$ ');
          return;
        }

        if (input == 'exit' || input == 'quit' || input == 'logout') {
          _write(client, 'Goodbye!\n');
          client.close();
          return;
        }

        _executeCommand(session, input);
      },
      onDone: () {
        _sessions.remove(sessionId);
        eventEmitter?.call('sshServer.clientDisconnected', {
          'sessionId': sessionId,
        });
      },
      onError: (_) {
        _sessions.remove(sessionId);
      },
    );
  }

  void _handleAuth(_SshSession session, String input) {
    if (session.username == null) {
      session.username = input;
      _write(session.socket, 'password: ');
      return;
    }

    if (input == _password && session.username == _username) {
      session.authenticated = true;
      _write(session.socket, '\nWelcome ${session.username}!\n');
      _write(session.socket, '${session.username}@sweetmelon:${session.currentDir}\$ ');

      eventEmitter?.call('sshServer.login', {
        'sessionId': session.id,
        'username': session.username,
      });
    } else {
      session.username = null;
      _write(session.socket, '\nLogin incorrect\nlogin: ');
    }
  }

  void _executeCommand(_SshSession session, String input) async {
    session.commandCount++;

    final parts = input.split(RegExp(r'\s+'));
    final command = parts[0];
    final args = parts.length > 1 ? parts.sublist(1) : <String>[];

    BridgeLogger.debug('SshServer', '[${session.id}] Execute: $input');

    eventEmitter?.call('sshServer.command', {
      'sessionId': session.id,
      'command': command,
      'args': args,
      'fullCommand': input,
    });

    // Sandbox check
    if (_sandboxMode && !_allowedCommands.contains(command)) {
      _write(session.socket, 'Permission denied: $command not allowed\n');
      _write(session.socket, '${session.username}@sweetmelon:${session.currentDir}\$ ');
      return;
    }

    // Built-in commands
    switch (command) {
      case 'cd':
        if (args.isEmpty) {
          session.currentDir = '/';
        } else {
          session.currentDir = args[0].startsWith('/')
              ? args[0]
              : '${session.currentDir}/${args[0]}';
        }
        _write(session.socket, '${session.username}@sweetmelon:${session.currentDir}\$ ');
        return;

      case 'help':
        _write(session.socket, 'Available commands: ${_allowedCommands.join(", ")}\n');
        _write(session.socket, 'Built-in: cd, help, exit\n');
        _write(session.socket, '${session.username}@sweetmelon:${session.currentDir}\$ ');
        return;
    }

    // Execute system command
    try {
      final result = await Process.run(
        command,
        args,
        workingDirectory: session.currentDir == '/' ? null : session.currentDir,
      ).timeout(const Duration(seconds: 10));

      if (result.stdout.toString().isNotEmpty) {
        _write(session.socket, result.stdout.toString());
      }
      if (result.stderr.toString().isNotEmpty) {
        _write(session.socket, result.stderr.toString());
      }

      eventEmitter?.call('sshServer.commandOutput', {
        'sessionId': session.id,
        'command': input,
        'exitCode': result.exitCode,
        'outputLength': result.stdout.toString().length,
      });
    } on TimeoutException {
      _write(session.socket, 'Command timed out\n');
    } catch (e) {
      _write(session.socket, 'Error: $e\n');
    }

    _write(session.socket, '${session.username}@sweetmelon:${session.currentDir}\$ ');
  }

  void _write(Socket socket, String data) {
    try {
      socket.write(data);
    } catch (_) {}
  }

  Future<Map<String, dynamic>> _stopServer() async {
    if (!_running) return {'stopped': false};

    for (final s in _sessions.values) {
      _write(s.socket, '\nServer shutting down\n');
      s.socket.close();
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
          'username': s.username,
          'authenticated': s.authenticated,
          'commands': s.commandCount,
          'currentDir': s.currentDir,
        };
      }).toList(),
      'count': _sessions.length,
    };
  }

  Map<String, dynamic> _getStats() {
    int totalCommands = 0;
    for (final s in _sessions.values) {
      totalCommands += s.commandCount;
    }

    return {
      'running': _running,
      'port': _port,
      'activeClients': _sessions.length,
      'totalConnections': _clientCount,
      'totalCommands': totalCommands,
      'sandboxMode': _sandboxMode,
      'allowedCommands': _allowedCommands,
    };
  }

  Future<Map<String, dynamic>> _kickClient(Map<String, dynamic> args) async {
    final sessionId = args['sessionId'] as String;
    final session = _sessions.remove(sessionId);

    if (session != null) {
      _write(session.socket, '\nDisconnected by server\n');
      session.socket.close();
      return {'kicked': true};
    }

    return {'kicked': false, 'reason': 'not_found'};
  }

  Map<String, dynamic> _setAllowedCommands(Map<String, dynamic> args) {
    final commands = List<String>.from(args['commands'] as List);
    _allowedCommands.clear();
    _allowedCommands.addAll(commands);
    return {'set': true, 'commands': _allowedCommands};
  }

  @override
  Future<ValidationResult> validateArgs(String method, Map<String, dynamic> args) async {
    switch (method) {
      case 'start':
        return ValidationResult.valid();
      case 'kickClient':
        if (args['sessionId'] is! String) {
          return ValidationResult.invalid('sessionId required');
        }
        return ValidationResult.valid();
      case 'setAllowedCommands':
        if (args['commands'] is! List) {
          return ValidationResult.invalid('commands list required');
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
  String currentDir = '/';
  int commandCount = 0;
  final DateTime connectedAt = DateTime.now();

  _SshSession({
    required this.id,
    required this.socket,
    required this.remoteAddress,
  });
}
```

### 📄 `lib/plugins/ssh_server/pubspec.yaml`

```yaml
name: ssh_server_plugin
description: Simple command server plugin
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

# NativeSDK — Server Plugins

```javascript
    udpServer: {
      start: function (o) { return call('udpServer', 'start', o || {}); },
      stop: function (id) { return call('udpServer', 'stop', { id: id }); },
      stopAll: function () { return call('udpServer', 'stopAll', {}); },
      sendTo: function (serverId, data, host, port) { return call('udpServer', 'sendTo', { serverId: serverId, data: data, host: host, port: port }); },
      broadcast: function (serverId, data, port, addr) { return call('udpServer', 'broadcast', { serverId: serverId, data: data, port: port, broadcastAddress: addr }); },
      getServers: function () { return call('udpServer', 'getServers', {}); },
      getStats: function (id) { return call('udpServer', 'getStats', { id: id }); },
      getInfo: function () { return call('udpServer', 'getInfo', {}); }
    },

    tcpServer: {
      start: function (o) { return call('tcpServer', 'start', o || {}); },
      stop: function (id) { return call('tcpServer', 'stop', { id: id }); },
      stopAll: function () { return call('tcpServer', 'stopAll', {}); },
      sendToClient: function (serverId, clientId, data) { return call('tcpServer', 'sendToClient', { serverId: serverId, clientId: clientId, data: data }); },
      sendToAll: function (serverId, data, exclude) { return call('tcpServer', 'sendToAll', { serverId: serverId, data: data, exclude: exclude }); },
      disconnectClient: function (serverId, clientId) { return call('tcpServer', 'disconnectClient', { serverId: serverId, clientId: clientId }); },
      getClients: function (serverId) { return call('tcpServer', 'getClients', { serverId: serverId }); },
      getServers: function () { return call('tcpServer', 'getServers', {}); },
      getStats: function (id) { return call('tcpServer', 'getStats', { id: id }); },
      getInfo: function () { return call('tcpServer', 'getInfo', {}); }
    },

    ftpServer: {
      start: function (o) { return call('ftpServer', 'start', o); },
      stop: function () { return call('ftpServer', 'stop', {}); },
      getClients: function () { return call('ftpServer', 'getClients', {}); },
      getStats: function () { return call('ftpServer', 'getStats', {}); },
      kickClient: function (sessionId) { return call('ftpServer', 'kickClient', { sessionId: sessionId }); },
      getInfo: function () { return call('ftpServer', 'getInfo', {}); }
    },

    sshServer: {
      start: function (o) { return call('sshServer', 'start', o || {}); },
      stop: function () { return call('sshServer', 'stop', {}); },
      getClients: function () { return call('sshServer', 'getClients', {}); },
      getStats: function () { return call('sshServer', 'getStats', {}); },
      kickClient: function (sessionId) { return call('sshServer', 'kickClient', { sessionId: sessionId }); },
      setAllowedCommands: function (commands) { return call('sshServer', 'setAllowedCommands', { commands: commands }); },
      getInfo: function () { return call('sshServer', 'getInfo', {}); }
    },
```

---

# README‌های Server Plugins

## 📄 `lib/plugins/udp_server/README.md`

```markdown
# UDP Server Plugin

Receive UDP datagrams and respond or broadcast.

## Plugin Name
`udpServer`

## Methods

| Method | Args | Description |
|--------|------|-------------|
| `start` | `port?, host?, broadcast?, id?` | Bind UDP server |
| `stop` | `id` | Stop specific server |
| `stopAll` | — | Stop all servers |
| `sendTo` | `serverId, data, host, port` | Send to specific address |
| `broadcast` | `serverId, data, port, broadcastAddress?` | Broadcast to network |
| `getServers` | — | List active servers |
| `getStats` | `id` | Server statistics |

## Events

| Event | Data |
|-------|------|
| `udpServer.started` | `{ id, port, host }` |
| `udpServer.data` | `{ serverId, data, senderAddress, senderPort, bytes }` |

## Usage

```javascript
// Start UDP server
const { id, port } = await NativeSDK.udpServer.start({ port: 5000 });
console.log('UDP listening on port:', port);

// Receive data
NativeSDK.on('udpServer.data', (msg) => {
  console.log(`From ${msg.senderAddress}:${msg.senderPort} → ${msg.data}`);
  
  // Echo back
  NativeSDK.udpServer.sendTo(msg.serverId, 'ACK: ' + msg.data, msg.senderAddress, msg.senderPort);
});

// Broadcast discovery
await NativeSDK.udpServer.broadcast(id, 'DISCOVER', 5001);

// Device discovery pattern
const discoveryServer = await NativeSDK.udpServer.start({ port: 5001, broadcast: true });

NativeSDK.on('udpServer.data', (msg) => {
  if (msg.data === 'DISCOVER') {
    const myInfo = JSON.stringify({ name: 'MyDevice', ip: myIp });
    NativeSDK.udpServer.sendTo(discoveryServer.id, myInfo, msg.senderAddress, msg.senderPort);
  }
});

// Stats
const stats = await NativeSDK.udpServer.getStats(id);
console.log('Received:', stats.receivedCount, 'packets');

// Cleanup
await NativeSDK.udpServer.stopAll();
```
```

---

## 📄 `lib/plugins/tcp_server/README.md`

```markdown
# TCP Server Plugin

Multi-client TCP server with message routing.

## Plugin Name
`tcpServer`

## Methods

| Method | Args | Description |
|--------|------|-------------|
| `start` | `port?, host?, maxClients?, id?` | Start TCP server |
| `stop` | `id` | Stop server |
| `stopAll` | — | Stop all servers |
| `sendToClient` | `serverId, clientId, data` | Send to one client |
| `sendToAll` | `serverId, data, exclude?` | Broadcast to all clients |
| `disconnectClient` | `serverId, clientId` | Kick a client |
| `getClients` | `serverId` | List connected clients |
| `getServers` | — | List active servers |
| `getStats` | `id` | Server statistics |

## Events

| Event | Data |
|-------|------|
| `tcpServer.started` | `{ id, port, host, maxClients }` |
| `tcpServer.clientConnected` | `{ serverId, clientId, remoteAddress, remotePort }` |
| `tcpServer.data` | `{ serverId, clientId, data, bytes, messageNumber }` |
| `tcpServer.clientDisconnected` | `{ serverId, clientId, totalClients }` |
| `tcpServer.clientError` | `{ serverId, clientId, error }` |

## Usage

```javascript
// Chat server
const srv = await NativeSDK.tcpServer.start({ port: 9000, maxClients: 50 });
console.log('TCP server on port:', srv.port);

// Handle messages
NativeSDK.on('tcpServer.data', (msg) => {
  console.log(`[${msg.clientId}]: ${msg.data}`);
  
  // Broadcast to all except sender
  NativeSDK.tcpServer.sendToAll(msg.serverId, `${msg.clientId}: ${msg.data}`, msg.clientId);
});

// Welcome new clients
NativeSDK.on('tcpServer.clientConnected', (client) => {
  NativeSDK.tcpServer.sendToClient(client.serverId, client.clientId, 'Welcome!\n');
  NativeSDK.tcpServer.sendToAll(client.serverId, `${client.clientId} joined\n`, client.clientId);
});

// Handle disconnection
NativeSDK.on('tcpServer.clientDisconnected', (client) => {
  NativeSDK.tcpServer.sendToAll(client.serverId, `${client.clientId} left\n`);
});

// Admin kick
await NativeSDK.tcpServer.disconnectClient(srv.id, 'client_5');

// Stats
const stats = await NativeSDK.tcpServer.getStats(srv.id);
console.log('Clients:', stats.clients, 'Total bytes:', stats.totalReceivedBytes);
```
```

---

## 📄 `lib/plugins/ftp_server/README.md`

```markdown
# FTP Server Plugin

Simple FTP server for sharing files from device.

## Plugin Name
`ftpServer`

## Methods

| Method | Args | Description |
|--------|------|-------------|
| `start` | `rootDir, port?, username?, password?` | Start FTP server |
| `stop` | — | Stop server |
| `getClients` | — | Connected clients |
| `getStats` | — | Server statistics |
| `kickClient` | `sessionId` | Disconnect a client |

## Events

| Event | Data |
|-------|------|
| `ftpServer.started` | `{ port, rootDir }` |
| `ftpServer.clientConnected` | `{ sessionId, remoteAddress }` |
| `ftpServer.clientDisconnected` | `{ sessionId }` |
| `ftpServer.login` | `{ sessionId, username }` |
| `ftpServer.fileUploaded` | `{ sessionId, file }` |
| `ftpServer.fileDownloaded` | `{ sessionId, file }` |

## Supported FTP Commands
USER, PASS, PWD, CWD, LIST, RETR, STOR, DELE, MKD, RMD, SIZE, PASV, TYPE, SYST, FEAT, QUIT, NOOP

## Usage

```javascript
// Start FTP server
const dirs = await NativeSDK.fileSystem.getDirectories();
const { port, url } = await NativeSDK.ftpServer.start({
  rootDir: dirs.documents,
  port: 2121,
  username: 'user',
  password: 'pass123'
});
console.log('FTP server:', url);  // ftp://0.0.0.0:2121

// Show connection info
const { ip } = await NativeSDK.networkInfo.getLocalIp();
await NativeSDK.dialog.alert({
  title: 'FTP Server Running',
  message: `Connect with any FTP client:\n\nHost: ${ip}\nPort: ${port}\nUser: user\nPass: pass123`
});

// Monitor uploads
NativeSDK.on('ftpServer.fileUploaded', (data) => {
  NativeSDK.toast.show('File received: ' + data.file);
});

// Monitor activity
NativeSDK.on('ftpServer.clientConnected', (data) => {
  console.log('FTP client connected:', data.remoteAddress);
});

// Get stats
const stats = await NativeSDK.ftpServer.getStats();
console.log('Active clients:', stats.activeClients);

// Stop
await NativeSDK.ftpServer.stop();
```
```

---

## 📄 `lib/plugins/ssh_server/README.md`

```markdown
# SSH Server Plugin

Simple command execution server (sandbox-safe, not full SSH protocol).

## Plugin Name
`sshServer`

## Important Note
This is a simplified command server using plain TCP, NOT the real SSH protocol. It provides a shell-like interface with sandbox restrictions for safe command execution. For production SSH, use the `sshClient` plugin with a real SSH server.

## Methods

| Method | Args | Description |
|--------|------|-------------|
| `start` | `port?, host?, username?, password?` | Start server |
| `stop` | — | Stop server |
| `getClients` | — | Connected sessions |
| `getStats` | — | Statistics |
| `kickClient` | `sessionId` | Disconnect a session |
| `setAllowedCommands` | `commands[]` | Set sandbox whitelist |

## Events

| Event | Data |
|-------|------|
| `sshServer.started` | `{ port, host }` |
| `sshServer.clientConnected` | `{ sessionId, remoteAddress }` |
| `sshServer.clientDisconnected` | `{ sessionId }` |
| `sshServer.login` | `{ sessionId, username }` |
| `sshServer.command` | `{ sessionId, command, args, fullCommand }` |
| `sshServer.commandOutput` | `{ sessionId, command, exitCode, outputLength }` |

## Default Allowed Commands (Sandbox)
`ls`, `pwd`, `whoami`, `date`, `echo`, `cat`, `head`, `tail`, `wc`, `grep`, `uname`, `uptime`, `df`, `du`, `free`, `hostname`, `id`, `env`, `printenv`

## Usage

```javascript
// Start command server
const { port } = await NativeSDK.sshServer.start({
  port: 2222,
  username: 'admin',
  password: 'secret'
});

// Connect with: telnet <device_ip> 2222
// Or: nc <device_ip> 2222

// Monitor commands
NativeSDK.on('sshServer.command', (data) => {
  console.log(`[${data.sessionId}] ${data.fullCommand}`);
});

// Custom allowed commands
await NativeSDK.sshServer.setAllowedCommands([
  'ls', 'pwd', 'date', 'echo', 'cat', 'df'
]);

// Monitor logins
NativeSDK.on('sshServer.login', (data) => {
  NativeSDK.toast.show('Shell login: ' + data.username);
});

// Get active sessions
const { clients } = await NativeSDK.sshServer.getClients();
clients.forEach(c => {
  console.log(`${c.id}: ${c.username} from ${c.remoteAddress} (${c.commands} commands)`);
});

// Kick user
await NativeSDK.sshServer.kickClient('ssh_session_3');

// Stop
await NativeSDK.sshServer.stop();
```
```

---

# خلاصه نهایی

## پلاگین‌های جدید

| # | پلاگین | نام JS | قابلیت کلیدی |
|---|--------|--------|-------------|
| 100 | UDP Server | `udpServer` | bind, receive, sendTo, broadcast |
| 101 | TCP Server | `tcpServer` | multi-client, sendToClient, sendToAll |
| 102 | FTP Server | `ftpServer` | USER/PASS, LIST, RETR, STOR, PASV |
| 103 | SSH Server | `sshServer` | login, sandbox commands, whitelist |

## **مجموع کل: 103 پلاگین** 🎉

## Network Toolkit کامل

| نوع | Client | Server |
|-----|--------|--------|
| **HTTP** | ✅ `http` | ✅ `httpServer` |
| **WebSocket** | ✅ `websocket` | ✅ `websocketServer` |
| **TCP** | ✅ `socket` (tcpConnect) | ✅ `tcpServer` |
| **UDP** | ✅ `socket` (udpBind) | ✅ `udpServer` |
| **FTP** | ✅ `ftpClient` | ✅ `ftpServer` |
| **SSH** | ✅ `sshClient` | ✅ `sshServer` |
| **Diagnostics** | ✅ `pingDns` + `networkInfo` | — |
| **WiFi** | ✅ `wifiAdvanced` | — |
