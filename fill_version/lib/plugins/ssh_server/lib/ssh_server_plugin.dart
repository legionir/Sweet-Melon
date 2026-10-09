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
