import 'dart:async' show Completer, Timer, StreamController;

import 'result.dart';
import 'types.dart';
import 'strategy.dart';

/// Manages retries for an action based on a given [RetryStrategy].
///
/// Supports both automatic and manual retry modes, provides status updates,
/// and allows customization of retry logic.
final class RetryController<T extends Object> {
  /// The strategy defining how retries are handled.
  final RetryStrategy strategy;

  /// The retry mode: [RetryMode.auto] or [RetryMode.manual].
  final RetryMode mode;

  /// Callback function triggered after each retry attempt.
  final StatusCallback? onStatus;

  /// Stream controller for status updates.
  StreamController<RetryStatus>? _statusController;

  /// Exposes the status stream.
  Stream<RetryStatus> get status => _statusController!.stream;

  /// Current attempt number.
  int _currentAttempt = 0;

  /// Timer for scheduling retry attempts.
  Timer? _timer;

  /// Holds the completion state of the retry operation.
  Completer<ActionResult<T>>? _completer;

  /// Cached action for manual retries.
  RetryAction<T>? _retryAction;

  /// Creates a [RetryController] with the specified [strategy], [mode], and optional [onStatus] callback.
  RetryController({
    required this.strategy,
    this.mode = RetryMode.auto,
    this.onStatus,
  });

  /// Checks if a retry process is currently active.
  bool get isActive => _timer != null;

  /// Returns the current attempt number.
  int get attempt => _currentAttempt;

  /// Starts the retry process for the given action.
  ///
  /// If an operation is already active, it returns an [ActionResult.skip()].
  Future<ActionResult<T>> execute({required RetryAction<T> onAction}) async {
    if (isActive) return ActionResult.skip();

    if (_currentAttempt + 1 > strategy.maxAttempts) {
      stop();
    }

    if (_currentAttempt == 0) {
      _retryAction ??= onAction;
      _statusController = StreamController<RetryStatus>.broadcast();
      _completer = Completer<ActionResult<T>>();
    }

    if (strategy.shouldRetry(_currentAttempt + 1, null)) {
      _tryAction(onAction: onAction);
    } else {
      stop();
      execute(onAction: onAction);
    }

    return _completer!.future;
  }

  /// Attempts to perform the action and retries if necessary.
  Future<void> _tryAction({required RetryAction<T> onAction}) async {
    _currentAttempt++;
    try {
      final actionRes = await onAction();
      if (actionRes != null) {
        _completer?.complete(ActionResult.success(actionRes));
        _onStatus(RetryStatus.success);
      } else {
        _tryNewAttempt(onAction, null);
      }
    } catch (error) {
      _tryNewAttempt(onAction, error);
    }
  }

  /// Checks if there are remaining attempts.
  bool get _hasNextAttempt => _currentAttempt + 1 <= strategy.maxAttempts;

  /// Schedules the next retry attempt with a delay.
  void _tryNewAttempt(RetryAction<T> onAction, Object? error) {
    _timer = Timer(strategy.attemptDelay(_currentAttempt), () {
      final status = _hasNextAttempt ? RetryStatus.attempt : RetryStatus.fail;
      if (status == RetryStatus.fail) {
        _completer?.complete(ActionResult.fail());
        _onStatus(status);
      } else {
        _onStatus(status);
        _timer?.cancel();
        _timer = null;

        if (mode == RetryMode.auto &&
            strategy.shouldRetry(_currentAttempt, error)) {
          _tryAction(onAction: onAction);
        }
      }
    });
  }

  /// Manually continues a retry attempt in [RetryMode.manual].
  ///
  /// Throws an error if called before `execute()`.
  void resume() {
    if (mode != RetryMode.manual) {
      throw ArgumentError('Resume is only allowed in manual mode');
    }
    if (_retryAction == null || _completer == null) {
      throw ArgumentError('Call execute() before using resume()');
    }
    _tryAction(onAction: _retryAction!);
  }

  /// Triggers the status callback, sends status to the stream, and stops retries on success.
  void _onStatus(RetryStatus status) {
    _statusController?.add(status);
    onStatus?.call(status);

    if (status != RetryStatus.attempt) {
      stop();
    }
  }

  /// Stops the retry process and resets the state.
  void stop() {
    _currentAttempt = 0;
    _statusController?.close();
    _timer?.cancel();
    _timer = null;
    _completer = null;
    _retryAction = null;
  }
}
