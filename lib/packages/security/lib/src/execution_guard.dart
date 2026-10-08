import 'dart:async';

// ============================================================
// EXECUTION GUARD — timeout and in-flight tracking
// ============================================================
//
// * Every execution has a timeout taken from the caller (no hard-coded value).
// * In-flight request IDs are tracked; a duplicate ID is rejected while the
//   first one is still running (prevents replay/confusion in the JS layer).
// * [cancelAll] completes every pending execution with [ExecutionCancelled]
//   so that nothing waits forever when the bridge is torn down.

class ExecutionTimeoutException implements Exception {
  final String requestId;
  const ExecutionTimeoutException(this.requestId);
  @override
  String toString() => 'ExecutionTimeoutException($requestId)';
}

class ExecutionCancelled implements Exception {
  const ExecutionCancelled();
  @override
  String toString() => 'ExecutionCancelled';
}

class DuplicateRequestException implements Exception {
  final String requestId;
  const DuplicateRequestException(this.requestId);
  @override
  String toString() => 'DuplicateRequestException($requestId)';
}

class ExecutionGuard {
  final Map<String, Completer<void>> _active = {};

  int get activeCount => _active.length;
  List<String> get activeRequests => List.unmodifiable(_active.keys);

  /// Runs [fn] with a timeout. Throws [ExecutionTimeoutException],
  /// [ExecutionCancelled], [DuplicateRequestException] or the error from [fn].
  Future<T> execute<T>({
    required String requestId,
    required Duration timeout,
    required Future<T> Function() fn,
  }) async {
    if (_active.containsKey(requestId)) {
      throw DuplicateRequestException(requestId);
    }
    final cancel = Completer<void>();
    _active[requestId] = cancel;
    try {
      final work = fn();
      return await Future.any<T>([
        work,
        cancel.future.then<T>((_) => throw const ExecutionCancelled()),
      ]).timeout(
        timeout,
        onTimeout: () {
          throw ExecutionTimeoutException(requestId);
        },
      );
    } finally {
      _active.remove(requestId);
    }
  }

  /// Cancels every in-flight execution.
  void cancelAll() {
    final pending = _active.values.toList();
    _active.clear();
    for (final c in pending) {
      if (!c.isCompleted) c.complete();
    }
  }
}
