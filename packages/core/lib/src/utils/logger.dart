import 'dart:convert';
import 'dart:async';

// ============================================================
// BRIDGE LOGGER — سیستم لاگ ساختارمند
// ============================================================

enum LogLevel {
  debug(0, '🔍 DEBUG'),
  info(1, '✅ INFO '),
  warn(2, '⚠️  WARN '),
  error(3, '❌ ERROR');

  final int value;
  final String label;
  const LogLevel(this.value, this.label);
}

class LogEntry {
  final LogLevel level;
  final String tag;
  final String message;
  final DateTime timestamp;
  final Map<String, dynamic>? extra;

  const LogEntry({
    required this.level,
    required this.tag,
    required this.message,
    required this.timestamp,
    this.extra,
  });

  Map<String, dynamic> toJson() => {
        'level': level.name,
        'tag': tag,
        'message': message,
        'timestamp': timestamp.toIso8601String(),
        if (extra != null) 'extra': extra,
      };

  @override
  String toString() {
    final time =
        '${timestamp.hour.toString().padLeft(2, '0')}:'
        '${timestamp.minute.toString().padLeft(2, '0')}:'
        '${timestamp.second.toString().padLeft(2, '0')}.'
        '${timestamp.millisecond.toString().padLeft(3, '0')}';
    
    return '[${level.label}] [$tag] $time — $message';
  }
}

class BridgeLogger {
  static LogLevel _minLevel = LogLevel.debug;
  static final List<LogEntry> _history = [];
  static final _controller = StreamController<LogEntry>.broadcast();
  static final List<LogSink> _sinks = [ConsoleSink()];
  
  static Stream<LogEntry> get stream => _controller.stream;
  static List<LogEntry> get history => List.unmodifiable(_history);

  static void setMinLevel(LogLevel level) => _minLevel = level;
  
  static void addSink(LogSink sink) => _sinks.add(sink);

  static void debug(String tag, String message, [Map<String, dynamic>? extra]) {
    _log(LogLevel.debug, tag, message, extra);
  }

  static void info(String tag, String message, [Map<String, dynamic>? extra]) {
    _log(LogLevel.info, tag, message, extra);
  }

  static void warn(String tag, String message, [Map<String, dynamic>? extra]) {
    _log(LogLevel.warn, tag, message, extra);
  }

  static void error(String tag, String message, [Map<String, dynamic>? extra]) {
    _log(LogLevel.error, tag, message, extra);
  }

  static void _log(
    LogLevel level,
    String tag,
    String message,
    Map<String, dynamic>? extra,
  ) {
    if (level.value < _minLevel.value) return;

    final entry = LogEntry(
      level: level,
      tag: tag,
      message: message,
      timestamp: DateTime.now(),
      extra: extra,
    );

    _history.add(entry);
    if (_history.length > 1000) _history.removeAt(0);
    
    _controller.add(entry);
    
    for (final sink in _sinks) {
      sink.write(entry);
    }
  }

  static void clear() => _history.clear();
  
  static void dispose() => _controller.close();
}

// ============================================================
// SINKS
// ============================================================

abstract class LogSink {
  void write(LogEntry entry);
}

class ConsoleSink implements LogSink {
  @override
  void write(LogEntry entry) {
    // ignore: avoid_print
    print(entry.toString());
  }
}

class MemorySink implements LogSink {
  final List<LogEntry> entries = [];
  final int maxEntries;

  MemorySink({this.maxEntries = 500});

  @override
  void write(LogEntry entry) {
    entries.add(entry);
    if (entries.length > maxEntries) entries.removeAt(0);
  }
}

class FileSink implements LogSink {
  final String Function() pathProvider;
  final _buffer = StringBuffer();
  Timer? _flushTimer;
  
  FileSink({required this.pathProvider}) {
    _flushTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _flush(),
    );
  }

  @override
  void write(LogEntry entry) {
    _buffer.writeln(jsonEncode(entry.toJson()));
  }

  void _flush() {
    if (_buffer.isEmpty) return;
    // در پروژه واقعی: نوشتن به فایل
    _buffer.clear();
  }

  void dispose() {
    _flush();
    _flushTimer?.cancel();
  }
}
