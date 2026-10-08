import 'dart:convert';

// ============================================================
// MESSAGE PROTOCOL — JS <-> Native wire contract
// ============================================================
//
// Every message that crosses the bridge is validated here before any
// plugin logic runs. Validation failures are reported as a typed
// [ProtocolException] carrying the requestId when it is known, so the
// caller can answer the right pending request (or drop the message when no
// safe requestId exists).

/// Protocol version spoken by the JavaScript SDK and this native side.
const int kProtocolVersion = 1;

/// Maximum accepted size of a single message from JavaScript (UTF-8 bytes).
const int kMaxMessageBytes = 2 * 1024 * 1024;

/// Maximum number of requests accepted in one batch.
const int kMaxBatchSize = 50;

/// Maximum accepted size of a batch timeout (10 minutes).
const int kMaxBatchTimeoutMs = 600000;

/// Maximum number of request headers accepted per request.
const int kMaxHeaders = 32;

final RegExp _idPattern = RegExp(r'^[A-Za-z0-9_-]{1,128}$');
final RegExp _namePattern = RegExp(r'^[A-Za-z][A-Za-z0-9_]{0,63}$');

/// Returns true when [value] is a syntactically valid request/batch identifier.
bool isValidRequestId(Object? value) =>
    value is String && _idPattern.hasMatch(value);

/// Thrown when an incoming message does not satisfy the protocol.
class ProtocolException implements Exception {
  final String message;

  /// The request/batch identifier when it could be read and validated.
  final String? requestId;

  const ProtocolException(this.message, {this.requestId});

  @override
  String toString() => 'ProtocolException: $message';
}

// ============================================================
// BASE MESSAGE CONTRACT
// ============================================================

abstract class BaseMessage {
  final String requestId;
  final DateTime timestamp;

  const BaseMessage({
    required this.requestId,
    required this.timestamp,
  });

  Map<String, dynamic> toJson();
}

// ============================================================
// PLUGIN REQUEST
// ============================================================

class PluginRequest extends BaseMessage {
  final String plugin;
  final String version;
  final String method;
  final Map<String, dynamic> args;
  final RequestMetadata metadata;

  const PluginRequest({
    required super.requestId,
    required super.timestamp,
    required this.plugin,
    required this.version,
    required this.method,
    required this.args,
    required this.metadata,
  });

  /// Parses and validates a request received from JavaScript.
  ///
  /// Throws [ProtocolException] for any structural problem.
  factory PluginRequest.fromJson(Map<String, dynamic> json) {
    final requestId = json['requestId'];
    if (!isValidRequestId(requestId)) {
      throw const ProtocolException('requestId is missing or invalid');
    }
    final id = requestId as String;

    return PluginRequest(
      requestId: id,
      timestamp: _optionalTimestamp(json, id) ?? DateTime.now(),
      plugin: _nameField(json, 'plugin', id),
      version: _optionalString(json, 'version', id, maxLength: 32) ?? '1.0.0',
      method: _nameField(json, 'method', id),
      args: _optionalMap(json, 'args', id) ?? const <String, dynamic>{},
      metadata: _parseMetadata(json['metadata'], id),
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'requestId': requestId,
        'timestamp': timestamp.toIso8601String(),
        'plugin': plugin,
        'version': version,
        'method': method,
        'args': args,
        'metadata': metadata.toJson(),
      };

  @override
  String toString() => jsonEncode(toJson());
}

// ============================================================
// PLUGIN RESPONSE
// ============================================================

class PluginResponse extends BaseMessage {
  final bool success;
  final dynamic data;
  final PluginError? error;
  final ResponseMetadata metadata;

  const PluginResponse({
    required super.requestId,
    required super.timestamp,
    required this.success,
    this.data,
    this.error,
    required this.metadata,
  });

  factory PluginResponse.success({
    required String requestId,
    required dynamic data,
    ResponseMetadata? metadata,
  }) {
    return PluginResponse(
      requestId: requestId,
      timestamp: DateTime.now(),
      success: true,
      data: data,
      metadata: metadata ?? ResponseMetadata.defaults(),
    );
  }

  factory PluginResponse.failure({
    required String requestId,
    required PluginError error,
    ResponseMetadata? metadata,
  }) {
    return PluginResponse(
      requestId: requestId,
      timestamp: DateTime.now(),
      success: false,
      error: error,
      metadata: metadata ?? ResponseMetadata.defaults(),
    );
  }

  /// Returns a copy of this response with [meta] as its metadata.
  PluginResponse withMetadata(ResponseMetadata meta) => PluginResponse(
        requestId: requestId,
        timestamp: timestamp,
        success: success,
        data: data,
        error: error,
        metadata: meta,
      );

  @override
  Map<String, dynamic> toJson() => {
        'requestId': requestId,
        'timestamp': timestamp.toIso8601String(),
        'success': success,
        if (data != null) 'data': data,
        if (error != null) 'error': error!.toJson(),
        'metadata': metadata.toJson(),
      };
}

// ============================================================
// ERROR CONTRACT
// ============================================================

/// Error codes shared by JavaScript and native code.
///
/// The code string is part of the public API and must not change.
enum PluginErrorCode {
  permissionDenied('PERMISSION_DENIED', false),
  pluginNotFound('PLUGIN_NOT_FOUND', false),
  methodNotFound('METHOD_NOT_FOUND', false),
  invalidArgs('INVALID_ARGS', false),
  invalidRequest('INVALID_REQUEST', false),
  timeout('TIMEOUT', true),
  rateLimitExceeded('RATE_LIMIT_EXCEEDED', true),
  cancelled('CANCELLED', false),
  executionError('EXECUTION_ERROR', false),
  sandboxViolation('SANDBOX_VIOLATION', false),
  networkError('NETWORK_ERROR', true),
  unknown('UNKNOWN', false);

  final String code;

  /// Whether retrying the same request may succeed without changes.
  final bool retryable;

  const PluginErrorCode(this.code, this.retryable);

  static PluginErrorCode fromString(String code) {
    return PluginErrorCode.values.firstWhere(
      (e) => e.code == code,
      orElse: () => PluginErrorCode.unknown,
    );
  }
}

/// Error object returned to JavaScript.
///
/// Never includes stack traces or internal exception text; those are logged
/// natively only (see SECURITY.md, "Error disclosure").
class PluginError {
  final PluginErrorCode code;
  final String message;
  final bool retryable;
  final String? plugin;
  final String? method;
  final Map<String, dynamic>? details;

  PluginError({
    required this.code,
    required this.message,
    bool? retryable,
    this.plugin,
    this.method,
    this.details,
  }) : retryable = retryable ?? code.retryable;

  factory PluginError.fromJson(Map<String, dynamic> json) {
    return PluginError(
      code: PluginErrorCode.fromString(json['code'] as String? ?? ''),
      message: json['message'] as String? ?? '',
      retryable: json['retryable'] as bool?,
      plugin: json['plugin'] as String?,
      method: json['method'] as String?,
      details: json['details'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() => {
        'code': code.code,
        'message': message,
        'retryable': retryable,
        if (plugin != null) 'plugin': plugin,
        if (method != null) 'method': method,
        if (details != null) 'details': details,
      };
}

// ============================================================
// METADATA
// ============================================================

class RequestMetadata {
  final Map<String, String> headers;

  const RequestMetadata({required this.headers});

  factory RequestMetadata.defaults() => const RequestMetadata(headers: {});

  Map<String, dynamic> toJson() => {'headers': headers};
}

class ResponseMetadata {
  final int processingTimeMs;
  final String? pluginVersion;
  final bool fromCache;

  const ResponseMetadata({
    required this.processingTimeMs,
    this.pluginVersion,
    required this.fromCache,
  });

  factory ResponseMetadata.defaults() => const ResponseMetadata(
        processingTimeMs: 0,
        fromCache: false,
      );

  Map<String, dynamic> toJson() => {
        'processingTimeMs': processingTimeMs,
        if (pluginVersion != null) 'pluginVersion': pluginVersion,
        'fromCache': fromCache,
      };
}

// ============================================================
// BATCH
// ============================================================

class BatchOptions {
  final bool parallel;
  final bool stopOnError;

  /// Per-request timeout in milliseconds, or null for the engine default.
  final int? timeoutMs;

  const BatchOptions({
    required this.parallel,
    required this.stopOnError,
    this.timeoutMs,
  });

  factory BatchOptions.defaults() => const BatchOptions(
        parallel: true,
        stopOnError: false,
      );

  factory BatchOptions.fromJson(Map<String, dynamic> json, String batchId) {
    final parallel = json['parallel'];
    final stopOnError = json['stopOnError'];
    final timeout = json['timeoutMs'];

    if (parallel != null && parallel is! bool) {
      throw ProtocolException('options.parallel must be a boolean',
          requestId: batchId);
    }
    if (stopOnError != null && stopOnError is! bool) {
      throw ProtocolException('options.stopOnError must be a boolean',
          requestId: batchId);
    }
    if (timeout != null &&
        (timeout is! num || timeout <= 0 || timeout > kMaxBatchTimeoutMs)) {
      throw ProtocolException(
        'options.timeoutMs must be between 1 and $kMaxBatchTimeoutMs',
        requestId: batchId,
      );
    }

    return BatchOptions(
      parallel: (parallel as bool?) ?? true,
      stopOnError: (stopOnError as bool?) ?? false,
      timeoutMs: timeout == null ? null : (timeout as num).toInt(),
    );
  }

  Map<String, dynamic> toJson() => {
        'parallel': parallel,
        'stopOnError': stopOnError,
        if (timeoutMs != null) 'timeoutMs': timeoutMs,
      };
}

/// A validated batch envelope received from JavaScript.
class BatchEnvelope {
  final String batchId;
  final List<PluginRequest> requests;
  final BatchOptions options;

  const BatchEnvelope({
    required this.batchId,
    required this.requests,
    required this.options,
  });

  /// Parses and validates a `{type: 'batch'}` message.
  ///
  /// Throws [ProtocolException]; the exception carries [batchId] when valid.
  factory BatchEnvelope.fromJson(Map<String, dynamic> json) {
    final batchIdRaw = json['batchId'];
    if (!isValidRequestId(batchIdRaw)) {
      throw const ProtocolException('batchId is missing or invalid');
    }
    final batchId = batchIdRaw as String;

    final raw = json['requests'];
    if (raw is! List) {
      throw ProtocolException('requests must be an array', requestId: batchId);
    }
    if (raw.isEmpty || raw.length > kMaxBatchSize) {
      throw ProtocolException(
        'requests must contain between 1 and $kMaxBatchSize items',
        requestId: batchId,
      );
    }

    final requests = <PluginRequest>[];
    final seen = <String>{};
    for (final item in raw) {
      if (item is! Map) {
        throw ProtocolException('batch item must be an object',
            requestId: batchId);
      }
      final request = PluginRequest.fromJson(_asJsonMap(item, batchId));
      if (!seen.add(request.requestId)) {
        throw ProtocolException('duplicate requestId in batch',
            requestId: batchId);
      }
      requests.add(request);
    }

    final optionsRaw = _optionalMap(json, 'options', batchId) ?? const {};
    return BatchEnvelope(
      batchId: batchId,
      requests: List.unmodifiable(requests),
      options: BatchOptions.fromJson(optionsRaw, batchId),
    );
  }
}

// ============================================================
// PARSING HELPERS (private)
// ============================================================

Map<String, dynamic> _asJsonMap(
    Map<dynamic, dynamic> value, String? requestId) {
  for (final key in value.keys) {
    if (key is! String) {
      throw ProtocolException('object keys must be strings',
          requestId: requestId);
    }
  }
  return Map<String, dynamic>.from(value);
}

String _nameField(Map<String, dynamic> json, String field, String requestId) {
  final value = json[field];
  if (value is! String || !_namePattern.hasMatch(value)) {
    throw ProtocolException('$field is missing or invalid',
        requestId: requestId);
  }
  return value;
}

String? _optionalString(
  Map<String, dynamic> json,
  String field,
  String requestId, {
  required int maxLength,
}) {
  final value = json[field];
  if (value == null) return null;
  if (value is! String || value.length > maxLength) {
    throw ProtocolException('$field must be a string of at most $maxLength',
        requestId: requestId);
  }
  return value;
}

Map<String, dynamic>? _optionalMap(
  Map<String, dynamic> json,
  String field,
  String requestId,
) {
  final value = json[field];
  if (value == null) return null;
  if (value is! Map) {
    throw ProtocolException('$field must be an object', requestId: requestId);
  }
  return _asJsonMap(value, requestId);
}

DateTime? _optionalTimestamp(Map<String, dynamic> json, String requestId) {
  final value = json['timestamp'];
  if (value == null) return null;
  if (value is! String) {
    throw ProtocolException('timestamp must be an ISO-8601 string',
        requestId: requestId);
  }
  final parsed = DateTime.tryParse(value);
  if (parsed == null) {
    throw ProtocolException('timestamp must be an ISO-8601 string',
        requestId: requestId);
  }
  return parsed;
}

RequestMetadata _parseMetadata(Object? raw, String requestId) {
  if (raw == null) return RequestMetadata.defaults();
  if (raw is! Map) {
    throw ProtocolException('metadata must be an object', requestId: requestId);
  }
  final headersRaw = raw['headers'];
  if (headersRaw == null) return RequestMetadata.defaults();
  if (headersRaw is! Map || headersRaw.length > kMaxHeaders) {
    throw ProtocolException(
      'metadata.headers must be an object of at most $kMaxHeaders entries',
      requestId: requestId,
    );
  }
  final headers = <String, String>{};
  headersRaw.forEach((key, value) {
    if (key is! String || value is! String) {
      throw ProtocolException('metadata.headers must map strings to strings',
          requestId: requestId);
    }
    headers[key] = value;
  });
  return RequestMetadata(headers: headers);
}
