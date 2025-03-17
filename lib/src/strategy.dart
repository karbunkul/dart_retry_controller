import 'package:meta/meta.dart';

/// Defines a strategy for handling retries.
///
/// Implementations control how many times an action is retried
/// and the delay between attempts.
abstract class RetryStrategy {
  /// Maximum number of retry attempts.
  final int maxAttempts;

  /// Creates a fixed delay retry strategy.
  ///
  /// Retries the action up to [maxAttempts] times with a constant delay of [delay].
  factory RetryStrategy.fixed({
    required int maxAttempts,
    required Duration delay,
  }) {
    return _FixedRetryStrategy(maxAttempts: maxAttempts, delay: delay);
  }

  /// Creates a retry strategy with a specified number of attempts.
  const RetryStrategy({required this.maxAttempts});

  /// Returns the delay before the next attempt.
  Duration attemptDelay(int attempt);

  /// Determines whether another attempt should be made.
  bool shouldRetry(int attempt, Object? error) {
    return attempt < maxAttempts;
  }
}

/// A retry strategy with a fixed delay between attempts.
@immutable
final class _FixedRetryStrategy extends RetryStrategy {
  /// Constant delay duration between retries.
  final Duration delay;

  /// Creates a fixed retry strategy with the given [maxAttempts] and [delay].
  const _FixedRetryStrategy({required super.maxAttempts, required this.delay});

  /// Returns the same fixed delay for all retry attempts.
  @override
  Duration attemptDelay(_) => delay;
}
