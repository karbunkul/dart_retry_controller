import 'package:meta/meta.dart';
import 'package:retry_controller/src/types.dart';

/// Represents the result of a retry operation.
@immutable
final class ActionResult<T extends Object> {
  /// The status of the retry operation.
  final RetryStatus status;

  /// The resulting data, if the action was successful.
  final T? data;

  /// Private constructor to enforce factory method usage.
  const ActionResult._({required this.status, this.data});

  /// Creates a result indicating that a retry attempt is in progress.
  factory ActionResult.skip() => ActionResult._(status: RetryStatus.attempt);

  /// Creates a result indicating that all retry attempts have failed.
  factory ActionResult.fail() => ActionResult._(status: RetryStatus.fail);

  /// Creates a result indicating a successful action with returned data.
  factory ActionResult.success(T data) {
    return ActionResult._(status: RetryStatus.success, data: data);
  }
}
