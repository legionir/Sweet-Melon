import 'dart:async';
import '../../../core/lib/src/utils/logger.dart';

// ============================================================
// EXECUTION GUARD — محافظ اجرا با timeout و ایزولاسیون
// ============================================================

class ExecutionGuard {
  final int defaultTimeoutMs;
  final Map<String, int> _activeExecutions = {};

  ExecutionGuard({this.defaultTimeoutMs = 30000});

  Future<T?> execute<T>({
    required String requestId,
    required Future<T> Function() fn,
    int? timeoutMs,
  }) async {
    final timeout = timeoutMs ?? defaultTimeoutMs;
    
    _activeExecutions[requestId] = DateTime.now().millisecondsSinceEpoch;
    
    try {
      final result = await fn().timeout(
        Duration(milliseconds: timeout),
        onTimeout: () {
          BridgeLogger.warn(
            'ExecutionGuard',
            'Timeout for: $requestId after ${timeout}ms',
          );
          throw TimeoutException(
            'Execution timeout',
            Duration(milliseconds: timeout),
          );
        },
      );
      
      return result;
    } finally {
      _activeExecutions.remove(requestId);
    }
  }

  int get activeCount => _activeExecutions.length;
  
  List<String> get activeRequests => _activeExecutions.keys.toList();
}

// ============================================================
// ARGS VALIDATOR — اعتبارسنجی آرگومان‌ها
// ============================================================

class ArgsValidator {
  static ValidationResult validate(
    Map<String, dynamic> args,
    Map<String, ArgSchema> schema,
  ) {
    for (final entry in schema.entries) {
      final fieldName = entry.key;
      final fieldSchema = entry.value;
      
      if (fieldSchema.required && !args.containsKey(fieldName)) {
        return ValidationResult.invalid(
          'Required field "$fieldName" is missing',
        );
      }
      
      if (args.containsKey(fieldName)) {
        final value = args[fieldName];
        
        if (!fieldSchema.isValidType(value)) {
          return ValidationResult.invalid(
            'Field "$fieldName" has invalid type. Expected: ${fieldSchema.type}',
          );
        }
        
        if (fieldSchema.validator != null) {
          final error = fieldSchema.validator!(value);
          if (error != null) {
            return ValidationResult.invalid(error);
          }
        }
      }
    }
    
    return ValidationResult.valid();
  }
}

class ArgSchema {
  final String type;
  final bool required;
  final String? Function(dynamic value)? validator;

  const ArgSchema({
    required this.type,
    this.required = false,
    this.validator,
  });

  bool isValidType(dynamic value) {
    switch (type) {
      case 'string':
        return value is String;
      case 'int':
        return value is int;
      case 'double':
        return value is double || value is int;
      case 'bool':
        return value is bool;
      case 'list':
        return value is List;
      case 'map':
        return value is Map;
      case 'any':
        return true;
      default:
        return true;
    }
  }
}

class ValidationResult {
  final bool isValid;
  final String? errorMessage;

  const ValidationResult({
    required this.isValid,
    this.errorMessage,
  });

  factory ValidationResult.valid() => 
      const ValidationResult(isValid: true);

  factory ValidationResult.invalid(String message) => 
      ValidationResult(isValid: false, errorMessage: message);
}
