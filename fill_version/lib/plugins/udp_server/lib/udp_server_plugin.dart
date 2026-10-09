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
