import 'dart:async' show FutureOr;

/// A function that performs an action and may need to be retried.
///
/// It should return a result of type [T] or `null` if the attempt was unsuccessful.
/// The function can also return a [Future] resolving to [T] or `null`.
typedef RetryAction<T extends Object> = FutureOr<T?> Function();

/// A callback function that receives status updates during the retry process.
typedef StatusCallback = void Function(RetryStatus status);

/// Defines retry modes.
///
/// - [auto]: Automatically retries based on the given strategy.
/// - [manual]: Requires a manual trigger to continue retries.
enum RetryMode { auto, manual }

/// Represents the status of a retry attempt.
///
/// - [success]: The action was successful.
/// - [fail]: The action failed after exhausting all retry attempts.
/// - [attempt]: A retry attempt was made.
/// - [canceled]: The retry process was manually or programmatically canceled before completion.
enum RetryStatus { success, fail, attempt, canceled }
