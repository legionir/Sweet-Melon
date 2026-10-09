# Network Toolkit — ۸ پلاگین شبکه

---

# پلاگین ۱: HTTP Server

## 📄 `lib/plugins/http_server/lib/http_server_plugin.dart`

```dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;
import 'package:sweetmelon/packages/core/lib/core.dart';
import 'package:sweetmelon/packages/plugin_engine/lib/plugin_engine.dart';

typedef HttpServerEventEmitter = Future<void> Function(String event, dynamic data);

class HttpServerPlugin extends Plugin {
  final HttpServerEventEmitter? eventEmitter;

  final Map<String, _ManagedServer> _servers = {};
  final Map<String, List<_RouteHandler>> _routes = {};

  HttpServerPlugin({this.eventEmitter});

  @override
  String get name => 'httpServer';

  @override
  String get version => '1.0.0';

  @override
  String get description => 'Local HTTP/HTTPS server plugin';

  @override
  List<String> get supportedMethods => [
        'start',
        'stop',
        'stopAll',
        'addRoute',
        'removeRoute',
        'serveDirectory',
        'getServers',
        'getRequests',
        'getInfo',
      ];

  @override
  Future<void> onDispose() async {
    await _stopAll();
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
      case 'addRoute':
        return _addRoute(args);
      case 'removeRoute':
        return _removeRoute(args);
      case 'serveDirectory':
        return _serveDirectory(args);
      case 'getServers':
        return _getServers();
      case 'getRequests':
        return _getRequests(args);
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
    final id = args['id'] as String? ?? 'server_${DateTime.now().millisecondsSinceEpoch}';
    final port = (args['port'] as num?)?.toInt() ?? 0;
    final host = args['host'] as String? ?? '0.0.0.0';
    final enableCors = args['cors'] as bool? ?? true;

    if (_servers.containsKey(id)) {
      final existing = _servers[id]!;
      return {
        'started': true,
        'alreadyRunning': true,
        'id': id,
        'port': existing.server.port,
        'url': 'http://$host:${existing.server.port}',
      };
    }

    try {
      final server = await HttpServer.bind(
        host == '0.0.0.0' ? InternetAddress.anyIPv4 : InternetAddress(host),
        port,
      );

      final managed = _ManagedServer(
        id: id,
        server: server,
        enableCors: enableCors,
      );

      _servers[id] = managed;
      _routes[id] ??= [];

      server.listen(
        (request) => _handleRequest(id, request, managed),
        onError: (error) {
          BridgeLogger.error('HttpServer', '[$id] Error: $error');
          eventEmitter?.call('httpServer.error', {
            'serverId': id,
            'error': error.toString(),
          });
        },
      );

      BridgeLogger.info('HttpServer', '[$id] Started on port ${server.port}');

      eventEmitter?.call('httpServer.started', {
        'serverId': id,
        'port': server.port,
        'host': host,
      });

      return {
        'started': true,
        'alreadyRunning': false,
        'id': id,
        'port': server.port,
        'url': 'http://$host:${server.port}',
      };
    } catch (e) {
      BridgeLogger.error('HttpServer', 'Start failed: $e');
      return {'started': false, 'error': e.toString()};
    }
  }

  Future<void> _handleRequest(
    String serverId,
    HttpRequest request,
    _ManagedServer managed,
  ) async {
    managed.requestCount++;

    final method = request.method.toUpperCase();
    final path = request.uri.path;

    // CORS
    if (managed.enableCors) {
      request.response.headers
        ..set('Access-Control-Allow-Origin', '*')
        ..set('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS, PATCH')
        ..set('Access-Control-Allow-Headers', '*');

      if (method == 'OPTIONS') {
        request.response
          ..statusCode = HttpStatus.ok
          ..close();
        return;
      }
    }

    // Route matching
    final routes = _routes[serverId] ?? [];

    for (final route in routes) {
      if (_matchRoute(route, method, path)) {
        await _executeRoute(route, request);
        return;
      }
    }

    // Static file serving
    if (managed.staticDir != null) {
      await _serveStaticFile(request, managed.staticDir!);
      return;
    }

    // Emit request event for JS handling
    final body = await _readBody(request);

    eventEmitter?.call('httpServer.request', {
      'serverId': serverId,
      'method': method,
      'path': path,
      'query': request.uri.queryParameters,
      'headers': request.headers.toString(),
      'body': body,
      'remoteAddress': request.connectionInfo?.remoteAddress.address,
    });

    // Default 404
    request.response
      ..statusCode = HttpStatus.notFound
      ..headers.contentType = ContentType.json
      ..write(jsonEncode({'error': 'Not Found', 'path': path}))
      ..close();
  }

  bool _matchRoute(_RouteHandler route, String method, String path) {
    if (route.method != '*' && route.method != method) return false;

    if (route.path == path) return true;

    // Simple wildcard
    if (route.path.endsWith('*')) {
      final prefix = route.path.substring(0, route.path.length - 1);
      return path.startsWith(prefix);
    }

    // Pattern matching with :params
    final routeSegments = route.path.split('/');
    final pathSegments = path.split('/');

    if (routeSegments.length != pathSegments.length) return false;

    for (int i = 0; i < routeSegments.length; i++) {
      if (routeSegments[i].startsWith(':')) continue;
      if (routeSegments[i] != pathSegments[i]) return false;
    }

    return true;
  }

  Future<void> _executeRoute(_RouteHandler route, HttpRequest request) async {
    try {
      final body = await _readBody(request);

      // Extract path params
      final params = <String, String>{};
      final routeSegments = route.path.split('/');
      final pathSegments = request.uri.path.split('/');
      for (int i = 0; i < routeSegments.length && i < pathSegments.length; i++) {
        if (routeSegments[i].startsWith(':')) {
          params[routeSegments[i].substring(1)] = pathSegments[i];
        }
      }

      request.response
        ..statusCode = route.statusCode
        ..headers.contentType = ContentType.parse(route.contentType);

      if (route.responseBody != null) {
        if (route.responseBody is Map || route.responseBody is List) {
          request.response.write(jsonEncode(route.responseBody));
        } else {
          request.response.write(route.responseBody.toString());
        }
      } else {
        request.response.write(jsonEncode({
          'path': request.uri.path,
          'method': request.method,
          'params': params,
          'query': request.uri.queryParameters,
          'body': body,
        }));
      }

      request.response.close();
    } catch (e) {
      request.response
        ..statusCode = HttpStatus.internalServerError
        ..write(jsonEncode({'error': e.toString()}))
        ..close();
    }
  }

  Future<String?> _readBody(HttpRequest request) async {
    try {
      final body = await utf8.decoder.bind(request).join();
      return body.isNotEmpty ? body : null;
    } catch (_) {
      return null;
    }
  }

  Future<void> _serveStaticFile(HttpRequest request, String baseDir) async {
    var filePath = request.uri.path;
    if (filePath == '/' || filePath.isEmpty) filePath = '/index.html';

    // Path traversal protection
    if (filePath.contains('..')) {
      request.response
        ..statusCode = HttpStatus.forbidden
        ..write('Forbidden')
        ..close();
      return;
    }

    final fullPath = p.join(baseDir, filePath.substring(1));
    final file = File(fullPath);

    if (await file.exists()) {
      final mimeType = lookupMimeType(fullPath) ?? 'application/octet-stream';
      final bytes = await file.readAsBytes();

      request.response
        ..statusCode = HttpStatus.ok
        ..headers.contentType = ContentType.parse(mimeType)
        ..contentLength = bytes.length
        ..add(bytes)
        ..close();
    } else {
      // SPA fallback
      final indexPath = p.join(baseDir, 'index.html');
      final indexFile = File(indexPath);

      if (await indexFile.exists()) {
        final bytes = await indexFile.readAsBytes();
        request.response
          ..statusCode = HttpStatus.ok
          ..headers.contentType = ContentType.html
          ..add(bytes)
          ..close();
      } else {
        request.response
          ..statusCode = HttpStatus.notFound
          ..write('Not Found')
          ..close();
      }
    }
  }

  Map<String, dynamic> _addRoute(Map<String, dynamic> args) {
    final serverId = args['serverId'] as String;
    final routeMethod = (args['method'] as String? ?? 'GET').toUpperCase();
    final routePath = args['path'] as String;
    final statusCode = (args['statusCode'] as num?)?.toInt() ?? 200;
    final contentType = args['contentType'] as String? ?? 'application/json';
    final responseBody = args['response'];

    _routes[serverId] ??= [];
    _routes[serverId]!.add(_RouteHandler(
      method: routeMethod,
      path: routePath,
      statusCode: statusCode,
      contentType: contentType,
      responseBody: responseBody,
    ));

    BridgeLogger.info('HttpServer', '[$serverId] Route added: $routeMethod $routePath');

    return {
      'added': true,
      'method': routeMethod,
      'path': routePath,
    };
  }

  Map<String, dynamic> _removeRoute(Map<String, dynamic> args) {
    final serverId = args['serverId'] as String;
    final routePath = args['path'] as String;

    final routes = _routes[serverId];
    if (routes != null) {
      routes.removeWhere((r) => r.path == routePath);
      return {'removed': true, 'path': routePath};
    }

    return {'removed': false, 'reason': 'server_not_found'};
  }

  Future<Map<String, dynamic>> _serveDirectory(Map<String, dynamic> args) async {
    final serverId = args['serverId'] as String;
    final directory = args['directory'] as String;

    final managed = _servers[serverId];
    if (managed == null) {
      return {'set': false, 'reason': 'server_not_found'};
    }

    if (!await Directory(directory).exists()) {
      return {'set': false, 'reason': 'directory_not_found'};
    }

    managed.staticDir = directory;

    BridgeLogger.info('HttpServer', '[$serverId] Serving: $directory');

    return {
      'set': true,
      'directory': directory,
      'url': 'http://localhost:${managed.server.port}',
    };
  }

  Future<Map<String, dynamic>> _stop(Map<String, dynamic> args) async {
    final id = args['id'] as String;
    final managed = _servers.remove(id);
    _routes.remove(id);

    if (managed != null) {
      await managed.server.close(force: true);
      BridgeLogger.info('HttpServer', '[$id] Stopped');
      return {'stopped': true, 'id': id};
    }

    return {'stopped': false, 'reason': 'not_found'};
  }

  Future<Map<String, dynamic>> _stopAll() async {
    final count = _servers.length;
    for (final managed in _servers.values) {
      await managed.server.close(force: true);
    }
    _servers.clear();
    _routes.clear();
    return {'stopped': count};
  }

  Map<String, dynamic> _getServers() {
    return {
      'servers': _servers.values.map((s) => {
        return {
          'id': s.id,
          'port': s.server.port,
          'requestCount': s.requestCount,
          'hasStaticDir': s.staticDir != null,
          'routeCount': _routes[s.id]?.length ?? 0,
        };
      }).toList(),
      'count': _servers.length,
    };
  }

  Map<String, dynamic> _getRequests(Map<String, dynamic> args) {
    final serverId = args['serverId'] as String;
    final managed = _servers[serverId];
    if (managed == null) {
      return {'found': false};
    }
    return {
      'found': true,
      'requestCount': managed.requestCount,
    };
  }

  @override
  Future<ValidationResult> validateArgs(String method, Map<String, dynamic> args) async {
    switch (method) {
      case 'stop':
      case 'getRequests':
        if (args['id'] is! String && args['serverId'] is! String) {
          return ValidationResult.invalid('id or serverId is required');
        }
        return ValidationResult.valid();
      case 'addRoute':
        if (args['serverId'] is! String) {
          return ValidationResult.invalid('serverId is required');
        }
        if (args['path'] is! String) {
          return ValidationResult.invalid('path is required');
        }
        return ValidationResult.valid();
      case 'serveDirectory':
        if (args['serverId'] is! String) {
          return ValidationResult.invalid('serverId is required');
        }
        if (args['directory'] is! String) {
          return ValidationResult.invalid('directory is required');
        }
        return ValidationResult.valid();
      default:
        return ValidationResult.valid();
    }
  }
}

class _ManagedServer {
  final String id;
  final HttpServer server;
  final bool enableCors;
  String? staticDir;
  int requestCount = 0;

  _ManagedServer({
    required this.id,
    required this.server,
    this.enableCors = true,
    this.staticDir,
  });
}

class _RouteHandler {
  final String method;
  final String path;
  final int statusCode;
  final String contentType;
  final dynamic responseBody;

  const _RouteHandler({
    required this.method,
    required this.path,
    this.statusCode = 200,
    this.contentType = 'application/json',
    this.responseBody,
  });
}
```

## 📄 `lib/plugins/http_server/pubspec.yaml`

```yaml
name: http_server_plugin
description: Local HTTP/HTTPS server plugin
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
  mime: ^1.0.5
  path: ^1.9.0
```

---

# پلاگین ۲: TCP/UDP Socket

## 📄 `lib/plugins/socket/lib/socket_plugin.dart`

```dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:sweetmelon/packages/core/lib/core.dart';
import 'package:sweetmelon/packages/plugin_engine/lib/plugin_engine.dart';

typedef SocketEventEmitter = Future<void> Function(String event, dynamic data);

class SocketPlugin extends Plugin {
  final SocketEventEmitter? eventEmitter;

  final Map<String, _TcpConnection> _tcpConnections = {};
  final Map<String, RawDatagramSocket> _udpSockets = {};
  ServerSocket? _tcpServer;
  String? _tcpServerId;
  StreamSubscription<Socket>? _tcpServerSub;

  SocketPlugin({this.eventEmitter});

  @override
  String get name => 'socket';

  @override
  String get version => '1.0.0';

  @override
  String get description => 'Raw TCP and UDP socket plugin';

  @override
  List<String> get supportedMethods => [
        'tcpConnect',
        'tcpSend',
        'tcpClose',
        'tcpStartServer',
        'tcpStopServer',
        'udpBind',
        'udpSend',
        'udpBroadcast',
        'udpClose',
        'getConnections',
        'closeAll',
        'getInfo',
      ];

  @override
  Future<void> onDispose() async {
    await _closeAll();
  }

  @override
  Future<dynamic> onCall(String method, Map<String, dynamic> args) async {
    switch (method) {
      case 'tcpConnect':
        return _tcpConnect(args);
      case 'tcpSend':
        return _tcpSend(args);
      case 'tcpClose':
        return _tcpClose(args);
      case 'tcpStartServer':
        return _tcpStartServer(args);
      case 'tcpStopServer':
        return _tcpStopServer();
      case 'udpBind':
        return _udpBind(args);
      case 'udpSend':
        return _udpSend(args);
      case 'udpBroadcast':
        return _udpBroadcast(args);
      case 'udpClose':
        return _udpClose(args);
      case 'getConnections':
        return _getConnections();
      case 'closeAll':
        return _closeAll();
      case 'getInfo':
        return {
          'name': name,
          'version': version,
          'tcpConnections': _tcpConnections.length,
          'udpSockets': _udpSockets.length,
          'tcpServerRunning': _tcpServer != null,
        };
      default:
        throw UnsupportedError('Method "$method" not supported');
    }
  }

  // ── TCP Client ──

  Future<Map<String, dynamic>> _tcpConnect(Map<String, dynamic> args) async {
    final host = args['host'] as String;
    final port = (args['port'] as num).toInt();
    final id = args['id'] as String? ?? 'tcp_${DateTime.now().millisecondsSinceEpoch}';
    final timeoutMs = (args['timeoutMs'] as num?)?.toInt() ?? 10000;
    final encoding = args['encoding'] as String? ?? 'utf8';

    try {
      final socket = await Socket.connect(
        host,
        port,
        timeout: Duration(milliseconds: timeoutMs),
      );

      final conn = _TcpConnection(
        id: id,
        socket: socket,
        host: host,
        port: port,
      );

      conn.subscription = socket.listen(
        (data) {
          conn.receivedBytes += data.length;

          String decoded;
          if (encoding == 'base64') {
            decoded = base64Encode(data);
          } else {
            decoded = utf8.decode(data, allowMalformed: true);
          }

          eventEmitter?.call('socket.tcpData', {
            'connectionId': id,
            'data': decoded,
            'encoding': encoding,
            'bytes': data.length,
          });
        },
        onError: (error) {
          eventEmitter?.call('socket.tcpError', {
            'connectionId': id,
            'error': error.toString(),
          });
        },
        onDone: () {
          _tcpConnections.remove(id);
          eventEmitter?.call('socket.tcpClosed', {
            'connectionId': id,
          });
        },
      );

      _tcpConnections[id] = conn;

      BridgeLogger.info('Socket', 'TCP connected: $host:$port [$id]');

      return {
        'connected': true,
        'id': id,
        'host': host,
        'port': port,
        'localPort': socket.port,
      };
    } catch (e) {
      return {'connected': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> _tcpSend(Map<String, dynamic> args) async {
    final id = args['id'] as String;
    final data = args['data'];
    final encoding = args['encoding'] as String? ?? 'utf8';

    final conn = _tcpConnections[id];
    if (conn == null) {
      return {'sent': false, 'reason': 'not_connected'};
    }

    try {
      if (encoding == 'base64' && data is String) {
        conn.socket.add(base64Decode(data));
      } else {
        conn.socket.write(data.toString());
      }

      conn.sentBytes += data.toString().length;

      return {'sent': true, 'id': id};
    } catch (e) {
      return {'sent': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> _tcpClose(Map<String, dynamic> args) async {
    final id = args['id'] as String;
    final conn = _tcpConnections.remove(id);

    if (conn != null) {
      conn.subscription?.cancel();
      await conn.socket.close();
      return {'closed': true, 'id': id};
    }

    return {'closed': false, 'reason': 'not_found'};
  }

  // ── TCP Server ──

  Future<Map<String, dynamic>> _tcpStartServer(Map<String, dynamic> args) async {
    final port = (args['port'] as num?)?.toInt() ?? 0;
    final host = args['host'] as String? ?? '0.0.0.0';

    if (_tcpServer != null) {
      return {
        'started': true,
        'alreadyRunning': true,
        'port': _tcpServer!.port,
      };
    }

    try {
      _tcpServer = await ServerSocket.bind(
        host == '0.0.0.0' ? InternetAddress.anyIPv4 : InternetAddress(host),
        port,
      );

      _tcpServerId = 'tcp_server_${_tcpServer!.port}';

      _tcpServerSub = _tcpServer!.listen((clientSocket) {
        final clientId = 'client_${clientSocket.remoteAddress.address}_${clientSocket.remotePort}';

        BridgeLogger.info('Socket', 'TCP client connected: $clientId');

        eventEmitter?.call('socket.tcpClientConnected', {
          'clientId': clientId,
          'remoteAddress': clientSocket.remoteAddress.address,
          'remotePort': clientSocket.remotePort,
        });

        final conn = _TcpConnection(
          id: clientId,
          socket: clientSocket,
          host: clientSocket.remoteAddress.address,
          port: clientSocket.remotePort,
        );

        conn.subscription = clientSocket.listen(
          (data) {
            eventEmitter?.call('socket.tcpServerData', {
              'clientId': clientId,
              'data': utf8.decode(data, allowMalformed: true),
              'bytes': data.length,
            });
          },
          onDone: () {
            _tcpConnections.remove(clientId);
            eventEmitter?.call('socket.tcpClientDisconnected', {
              'clientId': clientId,
            });
          },
        );

        _tcpConnections[clientId] = conn;
      });

      BridgeLogger.info('Socket', 'TCP server started on port ${_tcpServer!.port}');

      return {
        'started': true,
        'alreadyRunning': false,
        'port': _tcpServer!.port,
        'host': host,
      };
    } catch (e) {
      return {'started': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> _tcpStopServer() async {
    if (_tcpServer == null) {
      return {'stopped': false, 'reason': 'not_running'};
    }

    await _tcpServerSub?.cancel();
    await _tcpServer?.close();
    _tcpServer = null;
    _tcpServerId = null;

    return {'stopped': true};
  }

  // ── UDP ──

  Future<Map<String, dynamic>> _udpBind(Map<String, dynamic> args) async {
    final port = (args['port'] as num?)?.toInt() ?? 0;
    final id = args['id'] as String? ?? 'udp_${DateTime.now().millisecondsSinceEpoch}';
    final host = args['host'] as String? ?? '0.0.0.0';
    final broadcast = args['broadcast'] as bool? ?? false;

    try {
      final socket = await RawDatagramSocket.bind(
        host == '0.0.0.0' ? InternetAddress.anyIPv4 : InternetAddress(host),
        port,
      );

      if (broadcast) {
        socket.broadcastEnabled = true;
      }

      socket.listen((event) {
        if (event == RawSocketEvent.read) {
          final datagram = socket.receive();
          if (datagram != null) {
            eventEmitter?.call('socket.udpData', {
              'socketId': id,
              'data': utf8.decode(datagram.data, allowMalformed: true),
              'senderAddress': datagram.address.address,
              'senderPort': datagram.port,
              'bytes': datagram.data.length,
            });
          }
        }
      });

      _udpSockets[id] = socket;

      BridgeLogger.info('Socket', 'UDP bound: port ${socket.port} [$id]');

      return {
        'bound': true,
        'id': id,
        'port': socket.port,
      };
    } catch (e) {
      return {'bound': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> _udpSend(Map<String, dynamic> args) async {
    final id = args['id'] as String;
    final data = args['data'] as String;
    final targetHost = args['host'] as String;
    final targetPort = (args['port'] as num).toInt();

    final socket = _udpSockets[id];
    if (socket == null) {
      return {'sent': false, 'reason': 'not_bound'};
    }

    try {
      final bytes = utf8.encode(data);
      final sent = socket.send(bytes, InternetAddress(targetHost), targetPort);

      return {'sent': true, 'bytes': sent};
    } catch (e) {
      return {'sent': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> _udpBroadcast(Map<String, dynamic> args) async {
    final id = args['id'] as String;
    final data = args['data'] as String;
    final targetPort = (args['port'] as num).toInt();

    final socket = _udpSockets[id];
    if (socket == null) {
      return {'sent': false, 'reason': 'not_bound'};
    }

    try {
      socket.broadcastEnabled = true;
      final bytes = utf8.encode(data);
      final sent = socket.send(
        bytes,
        InternetAddress('255.255.255.255'),
        targetPort,
      );

      return {'sent': true, 'bytes': sent, 'broadcast': true};
    } catch (e) {
      return {'sent': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> _udpClose(Map<String, dynamic> args) async {
    final id = args['id'] as String;
    final socket = _udpSockets.remove(id);

    if (socket != null) {
      socket.close();
      return {'closed': true, 'id': id};
    }

    return {'closed': false, 'reason': 'not_found'};
  }

  // ── Management ──

  Map<String, dynamic> _getConnections() {
    return {
      'tcp': _tcpConnections.values.map((c) => {
        return {
          'id': c.id,
          'host': c.host,
          'port': c.port,
          'sentBytes': c.sentBytes,
          'receivedBytes': c.receivedBytes,
        };
      }).toList(),
      'udp': _udpSockets.entries.map((e) => {
        return {
          'id': e.key,
          'port': e.value.port,
        };
      }).toList(),
      'tcpServer': _tcpServer != null
          ? {'port': _tcpServer!.port, 'clients': _tcpConnections.length}
          : null,
    };
  }

  Future<Map<String, dynamic>> _closeAll() async {
    final tcpCount = _tcpConnections.length;
    final udpCount = _udpSockets.length;

    for (final conn in _tcpConnections.values) {
      conn.subscription?.cancel();
      await conn.socket.close();
    }
    _tcpConnections.clear();

    for (final socket in _udpSockets.values) {
      socket.close();
    }
    _udpSockets.clear();

    await _tcpStopServer();

    return {'closedTcp': tcpCount, 'closedUdp': udpCount};
  }

  @override
  Future<ValidationResult> validateArgs(String method, Map<String, dynamic> args) async {
    switch (method) {
      case 'tcpConnect':
        if (args['host'] is! String) return ValidationResult.invalid('host is required');
        if (args['port'] is! num) return ValidationResult.invalid('port is required');
        return ValidationResult.valid();
      case 'tcpSend':
      case 'tcpClose':
        if (args['id'] is! String) return ValidationResult.invalid('id is required');
        return ValidationResult.valid();
      case 'udpSend':
        if (args['id'] is! String) return ValidationResult.invalid('id is required');
        if (args['host'] is! String) return ValidationResult.invalid('host is required');
        if (args['port'] is! num) return ValidationResult.invalid('port is required');
        if (args['data'] is! String) return ValidationResult.invalid('data is required');
        return ValidationResult.valid();
      default:
        return ValidationResult.valid();
    }
  }
}

class _TcpConnection {
  final String id;
  final Socket socket;
  final String host;
  final int port;
  StreamSubscription<Uint8List>? subscription;
  int sentBytes = 0;
  int receivedBytes = 0;

  _TcpConnection({
    required this.id,
    required this.socket,
    required this.host,
    required this.port,
  });
}
```

## 📄 `lib/plugins/socket/pubspec.yaml`

```yaml
name: socket_plugin
description: Raw TCP and UDP socket plugin
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

# پلاگین ۳: Network Info

## 📄 `lib/plugins/network_info/lib/network_info_plugin.dart`

```dart
import 'dart:async';
import 'dart:io';

import 'package:sweetmelon/packages/core/lib/core.dart';
import 'package:sweetmelon/packages/plugin_engine/lib/plugin_engine.dart';

class NetworkInfoPlugin extends Plugin {
  @override
  String get name => 'networkInfo';

  @override
  String get version => '1.0.0';

  @override
  String get description => 'Network interfaces, IPs, and diagnostics';

  @override
  List<String> get supportedMethods => [
        'getInterfaces',
        'getIpAddresses',
        'getLocalIp',
        'getExternalIp',
        'getGateway',
        'isPortOpen',
        'getHostname',
        'getInfo',
      ];

  @override
  Future<dynamic> onCall(String method, Map<String, dynamic> args) async {
    switch (method) {
      case 'getInterfaces':
        return _getInterfaces();
      case 'getIpAddresses':
        return _getIpAddresses();
      case 'getLocalIp':
        return _getLocalIp();
      case 'getExternalIp':
        return _getExternalIp();
      case 'getGateway':
        return _getGateway();
      case 'isPortOpen':
        return _isPortOpen(args);
      case 'getHostname':
        return _getHostname();
      case 'getInfo':
        return {'name': name, 'version': version};
      default:
        throw UnsupportedError('Method "$method" not supported');
    }
  }

  Future<Map<String, dynamic>> _getInterfaces() async {
    try {
      final interfaces = await NetworkInterface.list(
        includeLoopback: false,
        includeLinkLocal: false,
      );

      final result = interfaces.map((iface) {
        return {
          'name': iface.name,
          'index': iface.index,
          'addresses': iface.addresses.map((addr) {
            return {
              'address': addr.address,
              'type': addr.type == InternetAddressType.IPv4 ? 'IPv4' : 'IPv6',
              'isLoopback': addr.isLoopback,
              'isLinkLocal': addr.isLinkLocal,
              'isMulticast': addr.isMulticast,
              'host': addr.host,
            };
          }).toList(),
        };
      }).toList();

      return {'interfaces': result, 'count': result.length};
    } catch (e) {
      return {'interfaces': <dynamic>[], 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> _getIpAddresses() async {
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLoopback: false,
      );

      final ipv4 = <String>[];
      final ipv6 = <String>[];

      for (final iface in interfaces) {
        for (final addr in iface.addresses) {
          if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
            ipv4.add(addr.address);
          }
        }
      }

      // Also get IPv6
      final v6Interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv6,
        includeLoopback: false,
      );

      for (final iface in v6Interfaces) {
        for (final addr in iface.addresses) {
          if (!addr.isLoopback && !addr.isLinkLocal) {
            ipv6.add(addr.address);
          }
        }
      }

      return {
        'ipv4': ipv4,
        'ipv6': ipv6,
        'primary': ipv4.isNotEmpty ? ipv4.first : null,
      };
    } catch (e) {
      return {'ipv4': <String>[], 'ipv6': <String>[], 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> _getLocalIp() async {
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLoopback: false,
      );

      String? wifiIp;
      String? mobileIp;
      String? anyIp;

      for (final iface in interfaces) {
        for (final addr in iface.addresses) {
          if (addr.isLoopback) continue;

          final name = iface.name.toLowerCase();

          if (name.contains('wlan') || name.contains('wifi') || name.contains('en0')) {
            wifiIp = addr.address;
          } else if (name.contains('rmnet') || name.contains('pdp') || name.contains('cellular')) {
            mobileIp = addr.address;
          }

          anyIp ??= addr.address;
        }
      }

      return {
        'ip': wifiIp ?? mobileIp ?? anyIp,
        'wifiIp': wifiIp,
        'mobileIp': mobileIp,
        'type': wifiIp != null ? 'wifi' : (mobileIp != null ? 'mobile' : 'other'),
      };
    } catch (e) {
      return {'ip': null, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> _getExternalIp() async {
    try {
      final client = HttpClient();
      final request = await client.getUrl(
        Uri.parse('https://api.ipify.org?format=json'),
      );
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      client.close();

      final data = jsonDecode(body) as Map<String, dynamic>;

      return {
        'externalIp': data['ip'],
        'source': 'ipify.org',
      };
    } catch (e) {
      // Fallback
      try {
        final client = HttpClient();
        final request = await client.getUrl(
          Uri.parse('https://ifconfig.me/ip'),
        );
        final response = await request.close();
        final ip = await response.transform(utf8.decoder).join();
        client.close();

        return {
          'externalIp': ip.trim(),
          'source': 'ifconfig.me',
        };
      } catch (_) {
        return {'externalIp': null, 'error': e.toString()};
      }
    }
  }

  Future<Map<String, dynamic>> _getGateway() async {
    try {
      // Android: از routing table gateway رو بخون
      final result = await Process.run('ip', ['route', 'show', 'default']);
      final output = result.stdout.toString().trim();

      // default via 192.168.1.1 dev wlan0
      final match = RegExp(r'default via (\S+)').firstMatch(output);

      if (match != null) {
        return {
          'gateway': match.group(1),
          'available': true,
        };
      }

      return {'gateway': null, 'available': false};
    } catch (e) {
      return {'gateway': null, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> _isPortOpen(Map<String, dynamic> args) async {
    final host = args['host'] as String;
    final port = (args['port'] as num).toInt();
    final timeoutMs = (args['timeoutMs'] as num?)?.toInt() ?? 3000;

    try {
      final socket = await Socket.connect(
        host,
        port,
        timeout: Duration(milliseconds: timeoutMs),
      );
      await socket.close();

      return {'host': host, 'port': port, 'open': true};
    } catch (e) {
      return {'host': host, 'port': port, 'open': false};
    }
  }

  Future<Map<String, dynamic>> _getHostname() async {
    try {
      return {'hostname': Platform.localHostname};
    } catch (e) {
      return {'hostname': null, 'error': e.toString()};
    }
  }

  @override
  Future<ValidationResult> validateArgs(String method, Map<String, dynamic> args) async {
    if (method == 'isPortOpen') {
      if (args['host'] is! String) return ValidationResult.invalid('host is required');
      if (args['port'] is! num) return ValidationResult.invalid('port is required');
    }
    return ValidationResult.valid();
  }
}
```

## 📄 `lib/plugins/network_info/pubspec.yaml`

```yaml
name: network_info_plugin
description: Network interfaces and diagnostics
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

# پلاگین ۴: Ping / DNS

## 📄 `lib/plugins/ping_dns/lib/ping_dns_plugin.dart`

```dart
import 'dart:async';
import 'dart:io';

import 'package:sweetmelon/packages/core/lib/core.dart';
import 'package:sweetmelon/packages/plugin_engine/lib/plugin_engine.dart';

class PingDnsPlugin extends Plugin {
  @override
  String get name => 'pingDns';

  @override
  String get version => '1.0.0';

  @override
  String get description => 'Ping hosts and DNS lookup';

  @override
  List<String> get supportedMethods => [
        'ping',
        'dnsLookup',
        'reverseDns',
        'traceroute',
        'isReachable',
        'getInfo',
      ];

  @override
  Future<dynamic> onCall(String method, Map<String, dynamic> args) async {
    switch (method) {
      case 'ping':
        return _ping(args);
      case 'dnsLookup':
        return _dnsLookup(args);
      case 'reverseDns':
        return _reverseDns(args);
      case 'traceroute':
        return _traceroute(args);
      case 'isReachable':
        return _isReachable(args);
      case 'getInfo':
        return {'name': name, 'version': version};
      default:
        throw UnsupportedError('Method "$method" not supported');
    }
  }

  Future<Map<String, dynamic>> _ping(Map<String, dynamic> args) async {
    final host = args['host'] as String;
    final count = (args['count'] as num?)?.toInt() ?? 4;
    final timeoutMs = (args['timeoutMs'] as num?)?.toInt() ?? 5000;

    try {
      final result = await Process.run(
        'ping',
        ['-c', '$count', '-W', '${timeoutMs ~/ 1000}', host],
      );

      final output = result.stdout.toString();
      final success = result.exitCode == 0;

      // Parse ping output
      double? avgMs;
      double? minMs;
      double? maxMs;
      int? packetLoss;

      final rttMatch = RegExp(
        r'rtt min/avg/max/mdev = ([\d.]+)/([\d.]+)/([\d.]+)/([\d.]+)',
      ).firstMatch(output);

      if (rttMatch != null) {
        minMs = double.tryParse(rttMatch.group(1) ?? '');
        avgMs = double.tryParse(rttMatch.group(2) ?? '');
        maxMs = double.tryParse(rttMatch.group(3) ?? '');
      }

      final lossMatch = RegExp(r'(\d+)% packet loss').firstMatch(output);
      if (lossMatch != null) {
        packetLoss = int.tryParse(lossMatch.group(1) ?? '');
      }

      return {
        'host': host,
        'reachable': success,
        'count': count,
        'avgMs': avgMs,
        'minMs': minMs,
        'maxMs': maxMs,
        'packetLoss': packetLoss,
        'output': output,
      };
    } catch (e) {
      // Fallback: TCP connect test
      return _isReachable({'host': host, 'timeoutMs': timeoutMs});
    }
  }

  Future<Map<String, dynamic>> _dnsLookup(Map<String, dynamic> args) async {
    final host = args['host'] as String;

    try {
      final addresses = await InternetAddress.lookup(host);

      final results = addresses.map((addr) {
        return {
          'address': addr.address,
          'host': addr.host,
          'type': addr.type == InternetAddressType.IPv4 ? 'IPv4' : 'IPv6',
          'isLoopback': addr.isLoopback,
        };
      }).toList();

      return {
        'host': host,
        'resolved': true,
        'addresses': results,
        'primary': results.isNotEmpty ? results.first['address'] : null,
        'count': results.length,
      };
    } on SocketException catch (e) {
      return {
        'host': host,
        'resolved': false,
        'error': e.message,
      };
    }
  }

  Future<Map<String, dynamic>> _reverseDns(Map<String, dynamic> args) async {
    final ip = args['ip'] as String;

    try {
      final address = InternetAddress(ip);
      final result = await address.reverse();

      return {
        'ip': ip,
        'hostname': result.host,
        'resolved': true,
      };
    } catch (e) {
      return {
        'ip': ip,
        'hostname': null,
        'resolved': false,
        'error': e.toString(),
      };
    }
  }

  Future<Map<String, dynamic>> _traceroute(Map<String, dynamic> args) async {
    final host = args['host'] as String;
    final maxHops = (args['maxHops'] as num?)?.toInt() ?? 15;

    try {
      final result = await Process.run(
        'traceroute',
        ['-m', '$maxHops', '-w', '2', host],
      ).timeout(const Duration(seconds: 30));

      final output = result.stdout.toString();
      final lines = output.split('\n').where((l) => l.trim().isNotEmpty).toList();

      final hops = <Map<String, dynamic>>[];

      for (int i = 1; i < lines.length; i++) {
        final line = lines[i].trim();
        final hopMatch = RegExp(
          r'^\s*(\d+)\s+(\S+)\s+\((\S+)\)\s+([\d.]+)\s*ms',
        ).firstMatch(line);

        if (hopMatch != null) {
          hops.add({
            'hop': int.parse(hopMatch.group(1) ?? '0'),
            'host': hopMatch.group(2),
            'ip': hopMatch.group(3),
            'rttMs': double.tryParse(hopMatch.group(4) ?? ''),
          });
        } else if (line.contains('* * *')) {
          final hopNum = RegExp(r'^\s*(\d+)').firstMatch(line);
          hops.add({
            'hop': int.parse(hopNum?.group(1) ?? '${i}'),
            'host': '*',
            'ip': '*',
            'rttMs': null,
            'timeout': true,
          });
        }
      }

      return {
        'host': host,
        'hops': hops,
        'hopCount': hops.length,
        'completed': result.exitCode == 0,
      };
    } catch (e) {
      return {'host': host, 'hops': <dynamic>[], 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> _isReachable(Map<String, dynamic> args) async {
    final host = args['host'] as String;
    final port = (args['port'] as num?)?.toInt() ?? 80;
    final timeoutMs = (args['timeoutMs'] as num?)?.toInt() ?? 3000;

    try {
      final socket = await Socket.connect(
        host,
        port,
        timeout: Duration(milliseconds: timeoutMs),
      );
      await socket.close();

      return {'host': host, 'port': port, 'reachable': true};
    } catch (e) {
      return {'host': host, 'port': port, 'reachable': false};
    }
  }

  @override
  Future<ValidationResult> validateArgs(String method, Map<String, dynamic> args) async {
    switch (method) {
      case 'ping':
      case 'dnsLookup':
      case 'traceroute':
      case 'isReachable':
        if (args['host'] is! String) return ValidationResult.invalid('host is required');
        return ValidationResult.valid();
      case 'reverseDns':
        if (args['ip'] is! String) return ValidationResult.invalid('ip is required');
        return ValidationResult.valid();
      default:
        return ValidationResult.valid();
    }
  }
}
```

## 📄 `lib/plugins/ping_dns/pubspec.yaml`

```yaml
name: ping_dns_plugin
description: Ping and DNS lookup plugin
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

# پلاگین ۵: WebSocket Server

## 📄 `lib/plugins/websocket_server/lib/websocket_server_plugin.dart`

```dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:sweetmelon/packages/core/lib/core.dart';
import 'package:sweetmelon/packages/plugin_engine/lib/plugin_engine.dart';

typedef WsServerEventEmitter = Future<void> Function(String event, dynamic data);

class WebSocketServerPlugin extends Plugin {
  final WsServerEventEmitter? eventEmitter;

  HttpServer? _httpServer;
  final Map<String, WebSocket> _clients = {};
  int _clientCounter = 0;
  int _port = 0;

  WebSocketServerPlugin({this.eventEmitter});

  @override
  String get name => 'websocketServer';

  @override
  String get version => '1.0.0';

  @override
  String get description => 'WebSocket server for P2P communication';

  @override
  List<String> get supportedMethods => [
        'start',
        'stop',
        'sendToClient',
        'sendToAll',
        'disconnectClient',
        'getClients',
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
      case 'sendToClient':
        return _sendToClient(args);
      case 'sendToAll':
        return _sendToAll(args);
      case 'disconnectClient':
        return _disconnectClient(args);
      case 'getClients':
        return _getClients();
      case 'getInfo':
        return {
          'name': name,
          'version': version,
          'running': _httpServer != null,
          'port': _port,
          'clientCount': _clients.length,
        };
      default:
        throw UnsupportedError('Method "$method" not supported');
    }
  }

  Future<Map<String, dynamic>> _start(Map<String, dynamic> args) async {
    if (_httpServer != null) {
      return {
        'started': true,
        'alreadyRunning': true,
        'port': _port,
        'url': 'ws://0.0.0.0:$_port',
      };
    }

    final port = (args['port'] as num?)?.toInt() ?? 0;
    final host = args['host'] as String? ?? '0.0.0.0';

    try {
      _httpServer = await HttpServer.bind(
        host == '0.0.0.0' ? InternetAddress.anyIPv4 : InternetAddress(host),
        port,
      );
      _port = _httpServer!.port;

      _httpServer!.listen((request) async {
        if (WebSocketTransformer.isUpgradeRequest(request)) {
          final ws = await WebSocketTransformer.upgrade(request);
          _handleNewClient(ws, request);
        } else {
          request.response
            ..statusCode = HttpStatus.ok
            ..headers.contentType = ContentType.json
            ..write(jsonEncode({
              'server': 'Sweetmelon WebSocket Server',
              'clients': _clients.length,
              'port': _port,
            }))
            ..close();
        }
      });

      BridgeLogger.info('WsServer', 'Started on port $_port');

      eventEmitter?.call('wsServer.started', {
        'port': _port,
        'host': host,
      });

      return {
        'started': true,
        'alreadyRunning': false,
        'port': _port,
        'url': 'ws://$host:$_port',
      };
    } catch (e) {
      return {'started': false, 'error': e.toString()};
    }
  }

  void _handleNewClient(WebSocket ws, HttpRequest request) {
    _clientCounter++;
    final clientId = 'client_$_clientCounter';

    _clients[clientId] = ws;

    final remoteAddress = request.connectionInfo?.remoteAddress.address ?? 'unknown';
    final remotePort = request.connectionInfo?.remotePort ?? 0;

    BridgeLogger.info('WsServer', 'Client connected: $clientId ($remoteAddress:$remotePort)');

    eventEmitter?.call('wsServer.clientConnected', {
      'clientId': clientId,
      'remoteAddress': remoteAddress,
      'remotePort': remotePort,
      'totalClients': _clients.length,
    });

    ws.listen(
      (data) {
        dynamic parsed;
        String dataType;

        if (data is String) {
          dataType = 'text';
          try {
            parsed = jsonDecode(data);
          } catch (_) {
            parsed = data;
          }
        } else {
          dataType = 'binary';
          parsed = base64Encode(data as List<int>);
        }

        eventEmitter?.call('wsServer.message', {
          'clientId': clientId,
          'data': parsed,
          'type': dataType,
        });
      },
      onDone: () {
        _clients.remove(clientId);
        BridgeLogger.info('WsServer', 'Client disconnected: $clientId');

        eventEmitter?.call('wsServer.clientDisconnected', {
          'clientId': clientId,
          'totalClients': _clients.length,
        });
      },
      onError: (error) {
        BridgeLogger.error('WsServer', 'Client error [$clientId]: $error');
        _clients.remove(clientId);
      },
    );
  }

  Future<Map<String, dynamic>> _stop() async {
    if (_httpServer == null) {
      return {'stopped': false, 'reason': 'not_running'};
    }

    for (final ws in _clients.values) {
      await ws.close(WebSocketStatus.goingAway, 'Server shutting down');
    }
    _clients.clear();

    await _httpServer?.close(force: true);
    _httpServer = null;

    BridgeLogger.info('WsServer', 'Stopped');

    return {'stopped': true};
  }

  Map<String, dynamic> _sendToClient(Map<String, dynamic> args) {
    final clientId = args['clientId'] as String;
    final data = args['data'];

    final ws = _clients[clientId];
    if (ws == null) {
      return {'sent': false, 'reason': 'client_not_found'};
    }

    if (data is Map || data is List) {
      ws.add(jsonEncode(data));
    } else {
      ws.add(data.toString());
    }

    return {'sent': true, 'clientId': clientId};
  }

  Map<String, dynamic> _sendToAll(Map<String, dynamic> args) {
    final data = args['data'];
    final excludeClient = args['exclude'] as String?;

    final payload = (data is Map || data is List) ? jsonEncode(data) : data.toString();

    int sentCount = 0;
    for (final entry in _clients.entries) {
      if (entry.key == excludeClient) continue;
      entry.value.add(payload);
      sentCount++;
    }

    return {'sent': sentCount, 'totalClients': _clients.length};
  }

  Future<Map<String, dynamic>> _disconnectClient(Map<String, dynamic> args) async {
    final clientId = args['clientId'] as String;
    final ws = _clients.remove(clientId);

    if (ws != null) {
      await ws.close(WebSocketStatus.normalClosure, 'Disconnected by server');
      return {'disconnected': true, 'clientId': clientId};
    }

    return {'disconnected': false, 'reason': 'not_found'};
  }

  Map<String, dynamic> _getClients() {
    return {
      'clients': _clients.keys.toList(),
      'count': _clients.length,
    };
  }

  @override
  Future<ValidationResult> validateArgs(String method, Map<String, dynamic> args) async {
    switch (method) {
      case 'sendToClient':
      case 'disconnectClient':
        if (args['clientId'] is! String) {
          return ValidationResult.invalid('clientId is required');
        }
        return ValidationResult.valid();
      case 'sendToAll':
        if (!args.containsKey('data')) {
          return ValidationResult.invalid('data is required');
        }
        return ValidationResult.valid();
      default:
        return ValidationResult.valid();
    }
  }
}
```

## 📄 `lib/plugins/websocket_server/pubspec.yaml`

```yaml
name: websocket_server_plugin
description: WebSocket server plugin
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

# پلاگین ۶: FTP Client

## 📄 `lib/plugins/ftp_client/lib/ftp_client_plugin.dart`

```dart
import 'dart:async';
import 'dart:io';

import 'package:sweetmelon/packages/core/lib/core.dart';
import 'package:sweetmelon/packages/plugin_engine/lib/plugin_engine.dart';

typedef FtpEventEmitter = Future<void> Function(String event, dynamic data);

class FtpClientPlugin extends Plugin {
  final FtpEventEmitter? eventEmitter;

  Socket? _controlSocket;
  bool _connected = false;
  String? _host;
  int _port = 21;
  String _lastResponse = '';

  FtpClientPlugin({this.eventEmitter});

  @override
  String get name => 'ftpClient';

  @override
  String get version => '1.0.0';

  @override
  String get description => 'FTP client for file transfer';

  @override
  List<String> get supportedMethods => [
        'connect',
        'disconnect',
        'login',
        'listFiles',
        'downloadFile',
        'uploadFile',
        'deleteFile',
        'makeDirectory',
        'removeDirectory',
        'getCurrentDirectory',
        'changeDirectory',
        'getInfo',
      ];

  @override
  Future<void> onDispose() async {
    await _disconnect();
  }

  @override
  Future<dynamic> onCall(String method, Map<String, dynamic> args) async {
    switch (method) {
      case 'connect':
        return _connect(args);
      case 'disconnect':
        return _disconnect();
      case 'login':
        return _login(args);
      case 'listFiles':
        return _listFiles(args);
      case 'downloadFile':
        return _downloadFile(args);
      case 'uploadFile':
        return _uploadFile(args);
      case 'deleteFile':
        return _deleteFile(args);
      case 'makeDirectory':
        return _makeDirectory(args);
      case 'removeDirectory':
        return _removeDirectory(args);
      case 'getCurrentDirectory':
        return _getCurrentDirectory();
      case 'changeDirectory':
        return _changeDirectory(args);
      case 'getInfo':
        return {
          'name': name,
          'version': version,
          'connected': _connected,
          'host': _host,
          'port': _port,
        };
      default:
        throw UnsupportedError('Method "$method" not supported');
    }
  }

  Future<Map<String, dynamic>> _connect(Map<String, dynamic> args) async {
    _host = args['host'] as String;
    _port = (args['port'] as num?)?.toInt() ?? 21;
    final timeoutMs = (args['timeoutMs'] as num?)?.toInt() ?? 10000;

    try {
      _controlSocket = await Socket.connect(
        _host!,
        _port,
        timeout: Duration(milliseconds: timeoutMs),
      );

      _connected = true;

      final response = await _readResponse();

      BridgeLogger.info('FTP', 'Connected to $_host:$_port');

      return {
        'connected': true,
        'host': _host,
        'port': _port,
        'response': response,
      };
    } catch (e) {
      _connected = false;
      return {'connected': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> _login(Map<String, dynamic> args) async {
    final username = args['username'] as String? ?? 'anonymous';
    final password = args['password'] as String? ?? '';

    if (!_connected) return {'loggedIn': false, 'reason': 'not_connected'};

    try {
      await _sendCommand('USER $username');
      final userResponse = await _readResponse();

      if (userResponse.startsWith('331')) {
        await _sendCommand('PASS $password');
        final passResponse = await _readResponse();

        if (passResponse.startsWith('230')) {
          return {'loggedIn': true, 'response': passResponse};
        }

        return {'loggedIn': false, 'response': passResponse};
      }

      return {'loggedIn': false, 'response': userResponse};
    } catch (e) {
      return {'loggedIn': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> _listFiles(Map<String, dynamic> args) async {
    if (!_connected) return {'files': <dynamic>[], 'reason': 'not_connected'};

    final path = args['path'] as String? ?? '.';

    try {
      // Enter passive mode
      await _sendCommand('PASV');
      final pasvResponse = await _readResponse();
      final dataPort = _parsePasvPort(pasvResponse);

      if (dataPort == null) {
        return {'files': <dynamic>[], 'error': 'PASV failed'};
      }

      final dataSocket = await Socket.connect(_host!, dataPort);

      await _sendCommand('LIST $path');
      await _readResponse();

      final data = StringBuffer();
      await for (final chunk in dataSocket) {
        data.write(String.fromCharCodes(chunk));
      }
      await dataSocket.close();

      await _readResponse(); // transfer complete

      final lines = data.toString().split('\n').where((l) => l.trim().isNotEmpty);
      final files = lines.map((line) => _parseFtpLine(line)).toList();

      return {'files': files, 'count': files.length, 'path': path};
    } catch (e) {
      return {'files': <dynamic>[], 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> _downloadFile(Map<String, dynamic> args) async {
    if (!_connected) return {'downloaded': false, 'reason': 'not_connected'};

    final remotePath = args['remotePath'] as String;
    final localPath = args['localPath'] as String;

    try {
      await _sendCommand('TYPE I'); // binary mode
      await _readResponse();

      await _sendCommand('PASV');
      final pasvResponse = await _readResponse();
      final dataPort = _parsePasvPort(pasvResponse);

      if (dataPort == null) {
        return {'downloaded': false, 'error': 'PASV failed'};
      }

      final dataSocket = await Socket.connect(_host!, dataPort);

      await _sendCommand('RETR $remotePath');
      await _readResponse();

      final file = File(localPath);
      await file.parent.create(recursive: true);
      final sink = file.openWrite();

      int totalBytes = 0;

      await for (final chunk in dataSocket) {
        sink.add(chunk);
        totalBytes += chunk.length;
      }

      await sink.flush();
      await sink.close();
      await dataSocket.close();

      await _readResponse();

      eventEmitter?.call('ftp.downloaded', {
        'remotePath': remotePath,
        'localPath': localPath,
        'size': totalBytes,
      });

      return {
        'downloaded': true,
        'localPath': localPath,
        'size': totalBytes,
      };
    } catch (e) {
      return {'downloaded': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> _uploadFile(Map<String, dynamic> args) async {
    if (!_connected) return {'uploaded': false, 'reason': 'not_connected'};

    final localPath = args['localPath'] as String;
    final remotePath = args['remotePath'] as String;

    final file = File(localPath);
    if (!await file.exists()) {
      return {'uploaded': false, 'reason': 'file_not_found'};
    }

    try {
      await _sendCommand('TYPE I');
      await _readResponse();

      await _sendCommand('PASV');
      final pasvResponse = await _readResponse();
      final dataPort = _parsePasvPort(pasvResponse);

      if (dataPort == null) {
        return {'uploaded': false, 'error': 'PASV failed'};
      }

      final dataSocket = await Socket.connect(_host!, dataPort);

      await _sendCommand('STOR $remotePath');
      await _readResponse();

      final bytes = await file.readAsBytes();
      dataSocket.add(bytes);
      await dataSocket.flush();
      await dataSocket.close();

      await _readResponse();

      eventEmitter?.call('ftp.uploaded', {
        'localPath': localPath,
        'remotePath': remotePath,
        'size': bytes.length,
      });

      return {
        'uploaded': true,
        'remotePath': remotePath,
        'size': bytes.length,
      };
    } catch (e) {
      return {'uploaded': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> _deleteFile(Map<String, dynamic> args) async {
    if (!_connected) return {'deleted': false, 'reason': 'not_connected'};
    final path = args['path'] as String;
    await _sendCommand('DELE $path');
    final response = await _readResponse();
    return {'deleted': response.startsWith('250'), 'response': response};
  }

  Future<Map<String, dynamic>> _makeDirectory(Map<String, dynamic> args) async {
    if (!_connected) return {'created': false, 'reason': 'not_connected'};
    final path = args['path'] as String;
    await _sendCommand('MKD $path');
    final response = await _readResponse();
    return {'created': response.startsWith('257'), 'response': response};
  }

  Future<Map<String, dynamic>> _removeDirectory(Map<String, dynamic> args) async {
    if (!_connected) return {'removed': false, 'reason': 'not_connected'};
    final path = args['path'] as String;
    await _sendCommand('RMD $path');
    final response = await _readResponse();
    return {'removed': response.startsWith('250'), 'response': response};
  }

  Future<Map<String, dynamic>> _getCurrentDirectory() async {
    if (!_connected) return {'path': null, 'reason': 'not_connected'};
    await _sendCommand('PWD');
    final response = await _readResponse();
    final match = RegExp(r'"(.+)"').firstMatch(response);
    return {'path': match?.group(1) ?? '/', 'response': response};
  }

  Future<Map<String, dynamic>> _changeDirectory(Map<String, dynamic> args) async {
    if (!_connected) return {'changed': false, 'reason': 'not_connected'};
    final path = args['path'] as String;
    await _sendCommand('CWD $path');
    final response = await _readResponse();
    return {'changed': response.startsWith('250'), 'response': response};
  }

  Future<Map<String, dynamic>> _disconnect() async {
    if (!_connected) return {'disconnected': false};

    try {
      await _sendCommand('QUIT');
      await _readResponse();
    } catch (_) {}

    _controlSocket?.close();
    _controlSocket = null;
    _connected = false;

    return {'disconnected': true};
  }

  // ── Helpers ──

  Future<void> _sendCommand(String command) async {
    _controlSocket?.write('$command\r\n');
    await _controlSocket?.flush();
  }

  Future<String> _readResponse() async {
    final completer = Completer<String>();
    final buffer = StringBuffer();

    late StreamSubscription sub;
    sub = _controlSocket!.listen(
      (data) {
        buffer.write(String.fromCharCodes(data));
        final content = buffer.toString();

        if (content.contains('\r\n') && RegExp(r'^\d{3} ', multiLine: true).hasMatch(content)) {
          sub.cancel();
          _lastResponse = content.trim();
          completer.complete(_lastResponse);
        }
      },
      onError: (e) {
        if (!completer.isCompleted) completer.completeError(e);
      },
    );

    return completer.future.timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        sub.cancel();
        return buffer.toString().trim();
      },
    );
  }

  int? _parsePasvPort(String response) {
    final match = RegExp(r'\((\d+),(\d+),(\d+),(\d+),(\d+),(\d+)\)').firstMatch(response);
    if (match == null) return null;
    final p1 = int.parse(match.group(5)!);
    final p2 = int.parse(match.group(6)!);
    return p1 * 256 + p2;
  }

  Map<String, dynamic> _parseFtpLine(String line) {
    final parts = line.trim().split(RegExp(r'\s+'));
    if (parts.length < 9) {
      return {'raw': line.trim()};
    }

    return {
      'permissions': parts[0],
      'type': parts[0].startsWith('d') ? 'directory' : 'file',
      'size': int.tryParse(parts[4]) ?? 0,
      'date': '${parts[5]} ${parts[6]} ${parts[7]}',
      'name': parts.sublist(8).join(' '),
    };
  }

  @override
  Future<ValidationResult> validateArgs(String method, Map<String, dynamic> args) async {
    switch (method) {
      case 'connect':
        if (args['host'] is! String) return ValidationResult.invalid('host is required');
        return ValidationResult.valid();
      case 'downloadFile':
        if (args['remotePath'] is! String) return ValidationResult.invalid('remotePath is required');
        if (args['localPath'] is! String) return ValidationResult.invalid('localPath is required');
        return ValidationResult.valid();
      case 'uploadFile':
        if (args['localPath'] is! String) return ValidationResult.invalid('localPath is required');
        if (args['remotePath'] is! String) return ValidationResult.invalid('remotePath is required');
        return ValidationResult.valid();
      default:
        return ValidationResult.valid();
    }
  }
}
```

## 📄 `lib/plugins/ftp_client/pubspec.yaml`

```yaml
name: ftp_client_plugin
description: FTP client plugin
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

# پلاگین ۷: SSH Client

## 📄 `lib/plugins/ssh_client/lib/ssh_client_plugin.dart`

```dart
import 'dart:async';
import 'dart:io';

import 'package:dartssh2/dartssh2.dart';
import 'package:sweetmelon/packages/core/lib/core.dart';
import 'package:sweetmelon/packages/plugin_engine/lib/plugin_engine.dart';

typedef SshEventEmitter = Future<void> Function(String event, dynamic data);

class SshClientPlugin extends Plugin {
  final SshEventEmitter? eventEmitter;

  final Map<String, SSHClient> _connections = {};

  SshClientPlugin({this.eventEmitter});

  @override
  String get name => 'sshClient';

  @override
  String get version => '1.0.0';

  @override
  String get description => 'SSH client for remote server management';

  @override
  List<String> get supportedMethods => [
        'connect',
        'disconnect',
        'execute',
        'upload',
        'download',
        'getConnections',
        'disconnectAll',
        'getInfo',
      ];

  @override
  Future<void> onDispose() async {
    await _disconnectAll();
  }

  @override
  Future<dynamic> onCall(String method, Map<String, dynamic> args) async {
    switch (method) {
      case 'connect':
        return _connect(args);
      case 'disconnect':
        return _disconnect(args);
      case 'execute':
        return _execute(args);
      case 'upload':
        return _upload(args);
      case 'download':
        return _download(args);
      case 'getConnections':
        return {'connections': _connections.keys.toList(), 'count': _connections.length};
      case 'disconnectAll':
        return _disconnectAll();
      case 'getInfo':
        return {
          'name': name,
          'version': version,
          'activeConnections': _connections.length,
        };
      default:
        throw UnsupportedError('Method "$method" not supported');
    }
  }

  Future<Map<String, dynamic>> _connect(Map<String, dynamic> args) async {
    final host = args['host'] as String;
    final port = (args['port'] as num?)?.toInt() ?? 22;
    final username = args['username'] as String;
    final password = args['password'] as String?;
    final privateKey = args['privateKey'] as String?;
    final id = args['id'] as String? ?? 'ssh_${DateTime.now().millisecondsSinceEpoch}';

    try {
      final socket = await SSHSocket.connect(host, port);

      final client = SSHClient(
        socket,
        username: username,
        onPasswordRequest: () => password ?? '',
        identities: privateKey != null
            ? [
                ...SSHKeyPair.fromPem(privateKey),
              ]
            : null,
      );

      await client.authenticated;

      _connections[id] = client;

      BridgeLogger.info('SSH', 'Connected to $host:$port [$id]');

      return {
        'connected': true,
        'id': id,
        'host': host,
        'port': port,
      };
    } catch (e) {
      BridgeLogger.error('SSH', 'Connect failed: $e');
      return {'connected': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> _disconnect(Map<String, dynamic> args) async {
    final id = args['id'] as String;
    final client = _connections.remove(id);

    if (client != null) {
      client.close();
      return {'disconnected': true, 'id': id};
    }

    return {'disconnected': false, 'reason': 'not_found'};
  }

  Future<Map<String, dynamic>> _execute(Map<String, dynamic> args) async {
    final id = args['id'] as String;
    final command = args['command'] as String;

    final client = _connections[id];
    if (client == null) {
      return {'success': false, 'reason': 'not_connected'};
    }

    try {
      final result = await client.run(command);
      final stdout = result.map((e) => String.fromCharCodes(e)).join();

      eventEmitter?.call('ssh.output', {
        'connectionId': id,
        'command': command,
        'output': stdout,
      });

      return {
        'success': true,
        'command': command,
        'output': stdout,
      };
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> _upload(Map<String, dynamic> args) async {
    final id = args['id'] as String;
    final localPath = args['localPath'] as String;
    final remotePath = args['remotePath'] as String;

    final client = _connections[id];
    if (client == null) {
      return {'uploaded': false, 'reason': 'not_connected'};
    }

    final file = File(localPath);
    if (!await file.exists()) {
      return {'uploaded': false, 'reason': 'file_not_found'};
    }

    try {
      final sftp = await client.sftp();
      final remoteFile = await sftp.open(
        remotePath,
        mode: SftpFileOpenMode.create | SftpFileOpenMode.write | SftpFileOpenMode.truncate,
      );

      final bytes = await file.readAsBytes();
      await remoteFile.write(Stream.value(bytes));
      await remoteFile.close();

      return {
        'uploaded': true,
        'localPath': localPath,
        'remotePath': remotePath,
        'size': bytes.length,
      };
    } catch (e) {
      return {'uploaded': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> _download(Map<String, dynamic> args) async {
    final id = args['id'] as String;
    final remotePath = args['remotePath'] as String;
    final localPath = args['localPath'] as String;

    final client = _connections[id];
    if (client == null) {
      return {'downloaded': false, 'reason': 'not_connected'};
    }

    try {
      final sftp = await client.sftp();
      final remoteFile = await sftp.open(remotePath);
      final data = await remoteFile.readBytes();
      await remoteFile.close();

      final file = File(localPath);
      await file.parent.create(recursive: true);
      await file.writeAsBytes(data);

      return {
        'downloaded': true,
        'remotePath': remotePath,
        'localPath': localPath,
        'size': data.length,
      };
    } catch (e) {
      return {'downloaded': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> _disconnectAll() async {
    final count = _connections.length;
    for (final client in _connections.values) {
      client.close();
    }
    _connections.clear();
    return {'disconnected': count};
  }

  @override
  Future<ValidationResult> validateArgs(String method, Map<String, dynamic> args) async {
    switch (method) {
      case 'connect':
        if (args['host'] is! String) return ValidationResult.invalid('host is required');
        if (args['username'] is! String) return ValidationResult.invalid('username is required');
        return ValidationResult.valid();
      case 'execute':
        if (args['id'] is! String) return ValidationResult.invalid('id is required');
        if (args['command'] is! String) return ValidationResult.invalid('command is required');
        return ValidationResult.valid();
      default:
        return ValidationResult.valid();
    }
  }
}
```

## 📄 `lib/plugins/ssh_client/pubspec.yaml`

```yaml
name: ssh_client_plugin
description: SSH client plugin
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
  dartssh2: ^2.8.2
```

---

# پلاگین ۸: WiFi Advanced

## 📄 `lib/plugins/wifi_advanced/lib/wifi_advanced_plugin.dart`

```dart
import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:sweetmelon/packages/core/lib/core.dart';
import 'package:sweetmelon/packages/plugin_engine/lib/plugin_engine.dart';

typedef WifiAdvEventEmitter = Future<void> Function(String event, dynamic data);

class WifiAdvancedPlugin extends Plugin {
  final WifiAdvEventEmitter? eventEmitter;
  static const _channel = MethodChannel('sweetmelon/wifi_advanced');

  WifiAdvancedPlugin({this.eventEmitter});

  @override
  String get name => 'wifiAdvanced';

  @override
  String get version => '1.0.0';

  @override
  String get description => 'Advanced WiFi: scan, connect, hotspot, direct';

  @override
  List<String> get supportedMethods => [
        'scan',
        'getConnectionInfo',
        'getIpConfig',
        'getSignalStrength',
        'getDhcpInfo',
        'getFrequency',
        'isWifiEnabled',
        'getInfo',
      ];

  @override
  Future<dynamic> onCall(String method, Map<String, dynamic> args) async {
    switch (method) {
      case 'scan':
        return _scan();
      case 'getConnectionInfo':
        return _getConnectionInfo();
      case 'getIpConfig':
        return _getIpConfig();
      case 'getSignalStrength':
        return _getSignalStrength();
      case 'getDhcpInfo':
        return _getDhcpInfo();
      case 'getFrequency':
        return _getFrequency();
      case 'isWifiEnabled':
        return _isWifiEnabled();
      case 'getInfo':
        return {'name': name, 'version': version};
      default:
        throw UnsupportedError('Method "$method" not supported');
    }
  }

  Future<Map<String, dynamic>> _scan() async {
    try {
      final result = await _channel.invokeMethod('scanWifi');
      if (result != null) {
        return Map<String, dynamic>.from(result);
      }
    } catch (e) {
      BridgeLogger.warn('WifiAdvanced', 'Native scan not available: $e');
    }

    // Fallback: network interface info
    return _getConnectionInfo();
  }

  Future<Map<String, dynamic>> _getConnectionInfo() async {
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLoopback: false,
      );

      String? wifiIp;
      String? interfaceName;
      final allInterfaces = <Map<String, dynamic>>[];

      for (final iface in interfaces) {
        final ifaceInfo = <String, dynamic>{
          'name': iface.name,
          'addresses': iface.addresses.map((a) => a.address).toList(),
        };

        allInterfaces.add(ifaceInfo);

        for (final addr in iface.addresses) {
          if (addr.isLoopback) continue;
          final name = iface.name.toLowerCase();
          if (name.contains('wlan') || name.contains('wifi') || name.contains('en0')) {
            wifiIp = addr.address;
            interfaceName = iface.name;
          }
        }
      }

      // Subnet calculation
      String? subnet;
      if (wifiIp != null) {
        final parts = wifiIp.split('.');
        if (parts.length == 4) {
          subnet = '${parts[0]}.${parts[1]}.${parts[2]}.0/24';
        }
      }

      return {
        'connected': wifiIp != null,
        'ip': wifiIp,
        'interfaceName': interfaceName,
        'subnet': subnet,
        'interfaces': allInterfaces,
      };
    } catch (e) {
      return {'connected': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> _getIpConfig() async {
    try {
      final result = await Process.run('ip', ['addr', 'show']);
      final output = result.stdout.toString();

      // Parse wlan interface
      final wlanMatch = RegExp(
        r'inet (\d+\.\d+\.\d+\.\d+)/(\d+).*?(?:wlan|wifi|en0)',
        dotAll: true,
      ).firstMatch(output);

      String? ip;
      String? cidr;
      String? broadcast;

      if (wlanMatch != null) {
        ip = wlanMatch.group(1);
        cidr = wlanMatch.group(2);
      }

      // Gateway
      final routeResult = await Process.run('ip', ['route', 'show', 'default']);
      final routeOutput = routeResult.stdout.toString();
      final gatewayMatch = RegExp(r'default via (\S+)').firstMatch(routeOutput);

      // DNS
      String? dns;
      try {
        final resolvConf = await File('/etc/resolv.conf').readAsString();
        final dnsMatch = RegExp(r'nameserver (\S+)').firstMatch(resolvConf);
        dns = dnsMatch?.group(1);
      } catch (_) {}

      return {
        'ip': ip,
        'cidr': cidr,
        'gateway': gatewayMatch?.group(1),
        'dns': dns,
        'broadcast': broadcast,
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> _getSignalStrength() async {
    try {
      final result = await Process.run('cat', ['/proc/net/wireless']);
      final output = result.stdout.toString();

      final match = RegExp(r'wlan\d?\s+\d+\s+([-\d.]+)\s+([-\d.]+)\s+([-\d.]+)')
          .firstMatch(output);

      if (match != null) {
        final level = double.tryParse(match.group(2) ?? '') ?? 0;
        return {
          'level': level,
          'quality': _signalQuality(level),
          'unit': 'dBm',
        };
      }

      return {'level': null, 'quality': 'unknown'};
    } catch (e) {
      return {'level': null, 'error': e.toString()};
    }
  }

  String _signalQuality(double dbm) {
    if (dbm >= -50) return 'excellent';
    if (dbm >= -60) return 'good';
    if (dbm >= -70) return 'fair';
    if (dbm >= -80) return 'weak';
    return 'very_weak';
  }

  Future<Map<String, dynamic>> _getDhcpInfo() async {
    try {
      final result = await _channel.invokeMethod('getDhcpInfo');
      if (result != null) {
        return Map<String, dynamic>.from(result);
      }
    } catch (_) {}

    // Fallback
    return _getIpConfig();
  }

  Future<Map<String, dynamic>> _getFrequency() async {
    try {
      final result = await _channel.invokeMethod('getFrequency');
      if (result != null) {
        final freq = result as int;
        return {
          'frequency': freq,
          'band': freq > 5000 ? '5GHz' : '2.4GHz',
          'unit': 'MHz',
        };
      }
    } catch (_) {}

    return {'frequency': null, 'band': 'unknown'};
  }

  Future<Map<String, dynamic>> _isWifiEnabled() async {
    final info = await _getConnectionInfo();
    return {'enabled': info['connected'] == true};
  }
}
```

## 📄 `lib/plugins/wifi_advanced/pubspec.yaml`

```yaml
name: wifi_advanced_plugin
description: Advanced WiFi plugin
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

# pubspec.yaml — dependency جدید

```yaml
  # Network Toolkit
  dartssh2: ^2.8.2
```

---

# NativeSDK — Network Toolkit

```javascript
    httpServer: {
      start: function (o) { return call('httpServer', 'start', o || {}); },
      stop: function (id) { return call('httpServer', 'stop', { id: id }); },
      stopAll: function () { return call('httpServer', 'stopAll', {}); },
      addRoute: function (serverId, method, path, response) {
        return call('httpServer', 'addRoute', { serverId: serverId, method: method, path: path, response: response });
      },
      removeRoute: function (serverId, path) { return call('httpServer', 'removeRoute', { serverId: serverId, path: path }); },
      serveDirectory: function (serverId, directory) { return call('httpServer', 'serveDirectory', { serverId: serverId, directory: directory }); },
      getServers: function () { return call('httpServer', 'getServers', {}); },
      getInfo: function () { return call('httpServer', 'getInfo', {}); }
    },

    socket: {
      tcpConnect: function (host, port, o) { return call('socket', 'tcpConnect', Object.assign({ host: host, port: port }, o || {})); },
      tcpSend: function (id, data, encoding) { return call('socket', 'tcpSend', { id: id, data: data, encoding: encoding }); },
      tcpClose: function (id) { return call('socket', 'tcpClose', { id: id }); },
      tcpStartServer: function (o) { return call('socket', 'tcpStartServer', o || {}); },
      tcpStopServer: function () { return call('socket', 'tcpStopServer', {}); },
      udpBind: function (o) { return call('socket', 'udpBind', o || {}); },
      udpSend: function (id, data, host, port) { return call('socket', 'udpSend', { id: id, data: data, host: host, port: port }); },
      udpBroadcast: function (id, data, port) { return call('socket', 'udpBroadcast', { id: id, data: data, port: port }); },
      udpClose: function (id) { return call('socket', 'udpClose', { id: id }); },
      getConnections: function () { return call('socket', 'getConnections', {}); },
      closeAll: function () { return call('socket', 'closeAll', {}); },
      getInfo: function () { return call('socket', 'getInfo', {}); }
    },

    networkInfo: {
      getInterfaces: function () { return call('networkInfo', 'getInterfaces', {}); },
      getIpAddresses: function () { return call('networkInfo', 'getIpAddresses', {}); },
      getLocalIp: function () { return call('networkInfo', 'getLocalIp', {}); },
      getExternalIp: function () { return call('networkInfo', 'getExternalIp', {}); },
      getGateway: function () { return call('networkInfo', 'getGateway', {}); },
      isPortOpen: function (host, port) { return call('networkInfo', 'isPortOpen', { host: host, port: port }); },
      getHostname: function () { return call('networkInfo', 'getHostname', {}); },
      getInfo: function () { return call('networkInfo', 'getInfo', {}); }
    },

    pingDns: {
      ping: function (host, o) { return call('pingDns', 'ping', Object.assign({ host: host }, o || {}), { timeout: 30000 }); },
      dnsLookup: function (host) { return call('pingDns', 'dnsLookup', { host: host }); },
      reverseDns: function (ip) { return call('pingDns', 'reverseDns', { ip: ip }); },
      traceroute: function (host, o) { return call('pingDns', 'traceroute', Object.assign({ host: host }, o || {}), { timeout: 60000 }); },
      isReachable: function (host, port) { return call('pingDns', 'isReachable', { host: host, port: port || 80 }); },
      getInfo: function () { return call('pingDns', 'getInfo', {}); }
    },

    websocketServer: {
      start: function (o) { return call('websocketServer', 'start', o || {}); },
      stop: function () { return call('websocketServer', 'stop', {}); },
      sendToClient: function (clientId, data) { return call('websocketServer', 'sendToClient', { clientId: clientId, data: data }); },
      sendToAll: function (data, exclude) { return call('websocketServer', 'sendToAll', { data: data, exclude: exclude }); },
      disconnectClient: function (clientId) { return call('websocketServer', 'disconnectClient', { clientId: clientId }); },
      getClients: function () { return call('websocketServer', 'getClients', {}); },
      getInfo: function () { return call('websocketServer', 'getInfo', {}); }
    },

    ftpClient: {
      connect: function (host, o) { return call('ftpClient', 'connect', Object.assign({ host: host }, o || {})); },
      disconnect: function () { return call('ftpClient', 'disconnect', {}); },
      login: function (username, password) { return call('ftpClient', 'login', { username: username, password: password }); },
      listFiles: function (path) { return call('ftpClient', 'listFiles', { path: path || '.' }); },
      downloadFile: function (remotePath, localPath) { return call('ftpClient', 'downloadFile', { remotePath: remotePath, localPath: localPath }); },
      uploadFile: function (localPath, remotePath) { return call('ftpClient', 'uploadFile', { localPath: localPath, remotePath: remotePath }); },
      deleteFile: function (path) { return call('ftpClient', 'deleteFile', { path: path }); },
      makeDirectory: function (path) { return call('ftpClient', 'makeDirectory', { path: path }); },
      removeDirectory: function (path) { return call('ftpClient', 'removeDirectory', { path: path }); },
      getCurrentDirectory: function () { return call('ftpClient', 'getCurrentDirectory', {}); },
      changeDirectory: function (path) { return call('ftpClient', 'changeDirectory', { path: path }); },
      getInfo: function () { return call('ftpClient', 'getInfo', {}); }
    },

    sshClient: {
      connect: function (host, username, o) { return call('sshClient', 'connect', Object.assign({ host: host, username: username }, o || {})); },
      disconnect: function (id) { return call('sshClient', 'disconnect', { id: id }); },
      execute: function (id, command) { return call('sshClient', 'execute', { id: id, command: command }); },
      upload: function (id, localPath, remotePath) { return call('sshClient', 'upload', { id: id, localPath: localPath, remotePath: remotePath }); },
      download: function (id, remotePath, localPath) { return call('sshClient', 'download', { id: id, remotePath: remotePath, localPath: localPath }); },
      getConnections: function () { return call('sshClient', 'getConnections', {}); },
      disconnectAll: function () { return call('sshClient', 'disconnectAll', {}); },
      getInfo: function () { return call('sshClient', 'getInfo', {}); }
    },

    wifiAdvanced: {
      scan: function () { return call('wifiAdvanced', 'scan', {}); },
      getConnectionInfo: function () { return call('wifiAdvanced', 'getConnectionInfo', {}); },
      getIpConfig: function () { return call('wifiAdvanced', 'getIpConfig', {}); },
      getSignalStrength: function () { return call('wifiAdvanced', 'getSignalStrength', {}); },
      getDhcpInfo: function () { return call('wifiAdvanced', 'getDhcpInfo', {}); },
      getFrequency: function () { return call('wifiAdvanced', 'getFrequency', {}); },
      isWifiEnabled: function () { return call('wifiAdvanced', 'isWifiEnabled', {}); },
      getInfo: function () { return call('wifiAdvanced', 'getInfo', {}); }
    },
```

---

# خلاصه Network Toolkit

## ۸ پلاگین جدید

| # | پلاگین | نام JS | قابلیت‌ها | Events |
|---|--------|--------|----------|--------|
| 92 | HTTP Server | `httpServer` | start, stop, addRoute, serveDirectory, CORS | httpServer.request, httpServer.started |
| 93 | Socket (TCP/UDP) | `socket` | tcpConnect, tcpServer, udpBind, udpBroadcast | socket.tcpData, socket.udpData, socket.tcpClientConnected |
| 94 | Network Info | `networkInfo` | getInterfaces, getIpAddresses, getLocalIp, getExternalIp, getGateway, isPortOpen | — |
| 95 | Ping/DNS | `pingDns` | ping, dnsLookup, reverseDns, traceroute, isReachable | — |
| 96 | WebSocket Server | `websocketServer` | start, sendToClient, sendToAll, disconnectClient | wsServer.message, wsServer.clientConnected |
| 97 | FTP Client | `ftpClient` | connect, login, list, download, upload, delete, mkdir | ftp.downloaded, ftp.uploaded |
| 98 | SSH Client | `sshClient` | connect, execute, upload (SFTP), download (SFTP) | ssh.output |
| 99 | WiFi Advanced | `wifiAdvanced` | scan, ipConfig, signalStrength, dhcpInfo, frequency | — |

## **مجموع کل: 99 پلاگین** 🎉

## نحوه استفاده

```javascript
// HTTP Server — ساخت REST API محلی
const { port } = await NativeSDK.httpServer.start({ port: 8080 });
await NativeSDK.httpServer.addRoute('server_1', 'GET', '/api/status', { status: 'ok' });
await NativeSDK.httpServer.serveDirectory('server_1', '/path/to/files');

// TCP Socket
const tcp = await NativeSDK.socket.tcpConnect('192.168.1.100', 3000);
await NativeSDK.socket.tcpSend(tcp.id, 'Hello server!');
NativeSDK.on('socket.tcpData', (data) => console.log('Received:', data.data));

// UDP Broadcast
const udp = await NativeSDK.socket.udpBind({ port: 5000, broadcast: true });
await NativeSDK.socket.udpBroadcast(udp.id, 'Discovery!', 5000);

// Network Info
const { interfaces } = await NativeSDK.networkInfo.getInterfaces();
const { ip } = await NativeSDK.networkInfo.getLocalIp();
const { externalIp } = await NativeSDK.networkInfo.getExternalIp();
const { gateway } = await NativeSDK.networkInfo.getGateway();
const { open } = await NativeSDK.networkInfo.isPortOpen('google.com', 443);

// Ping / DNS
const ping = await NativeSDK.pingDns.ping('google.com', { count: 4 });
console.log(`Avg: ${ping.avgMs}ms, Loss: ${ping.packetLoss}%`);

const dns = await NativeSDK.pingDns.dnsLookup('github.com');
console.log('IPs:', dns.addresses);

const trace = await NativeSDK.pingDns.traceroute('google.com');
trace.hops.forEach(h => console.log(`${h.hop}: ${h.ip} (${h.rttMs}ms)`));

// WebSocket Server — P2P بین دستگاه‌ها
const ws = await NativeSDK.websocketServer.start({ port: 9090 });
NativeSDK.on('wsServer.message', (msg) => {
  // echo back
  NativeSDK.websocketServer.sendToClient(msg.clientId, { echo: msg.data });
});

// FTP
await NativeSDK.ftpClient.connect('ftp.example.com');
await NativeSDK.ftpClient.login('admin', 'password');
const { files } = await NativeSDK.ftpClient.listFiles('/public');
await NativeSDK.ftpClient.downloadFile('/public/data.csv', '/local/data.csv');
await NativeSDK.ftpClient.disconnect();

// SSH
const ssh = await NativeSDK.sshClient.connect('server.example.com', 'root', {
  password: 'pass123'
});
const { output } = await NativeSDK.sshClient.execute(ssh.id, 'ls -la /var/www');
console.log(output);
await NativeSDK.sshClient.upload(ssh.id, '/local/config.json', '/etc/app/config.json');
await NativeSDK.sshClient.disconnect(ssh.id);

// WiFi
const wifi = await NativeSDK.wifiAdvanced.getConnectionInfo();
const ipConfig = await NativeSDK.wifiAdvanced.getIpConfig();
const signal = await NativeSDK.wifiAdvanced.getSignalStrength();
console.log(`WiFi: ${wifi.ip}, Gateway: ${ipConfig.gateway}, Signal: ${signal.quality}`);
```
