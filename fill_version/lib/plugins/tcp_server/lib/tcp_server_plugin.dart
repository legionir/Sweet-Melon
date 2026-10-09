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
