import 'dart:async';

/// Helper class for managing field dependencies without artificial delays
class FieldDependencyHelper {
  final List<Completer<void>> _pendingOperations = [];
  final List<StreamSubscription> _subscriptions = [];

  /// Execute a callback after field updates are complete
  Future<void> executeAfterFieldUpdate(
    Future<void> Function() fieldUpdate,
    void Function() callback,
  ) async {
    final completer = Completer<void>();
    _pendingOperations.add(completer);

    try {
      await fieldUpdate();
      
      // Use a microtask to ensure the field update is processed
      Timer.run(() {
        try {
          callback();
        } catch (e) {
          completer.completeError(e);
          return;
        }
        completer.complete();
      });
    } catch (e) {
      completer.completeError(e);
    }

    return completer.future;
  }

  /// Execute multiple cascading field updates in sequence
  Future<void> executeCascadingFieldUpdates(
    List<Future<void> Function()> fieldUpdates,
  ) async {
    for (final update in fieldUpdates) {
      await update();
      // Use microtask to ensure each update is processed before the next
      await _yieldToEventLoop();
    }
  }

  /// Wait for a specific condition to be true with timeout
  Future<bool> waitForCondition(
    bool Function() condition, {
    Duration timeout = const Duration(seconds: 5),
    Duration interval = const Duration(milliseconds: 10),
  }) async {
    final stopwatch = Stopwatch()..start();
    
    while (!condition() && stopwatch.elapsed < timeout) {
      await Future.delayed(interval);
    }
    
    stopwatch.stop();
    return condition();
  }

  /// Create a stream subscription that auto-disposes
  StreamSubscription<T> createAutoDisposeSubscription<T>(
    Stream<T> stream,
    void Function(T) onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    final subscription = stream.listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
    
    _subscriptions.add(subscription);
    return subscription;
  }

  /// Dispose all resources
  void dispose() {
    for (final completer in _pendingOperations) {
      if (!completer.isCompleted) {
        completer.complete();
      }
    }
    _pendingOperations.clear();

    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    _subscriptions.clear();
  }

  /// Yield to the event loop to allow UI updates
  Future<void> _yieldToEventLoop() async {
    final completer = Completer<void>();
    Timer.run(() => completer.complete());
    return completer.future;
  }
}