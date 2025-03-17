import 'dart:async';
import 'dart:math' show Random;

import 'package:retry_controller/retry_controller.dart';

final controller = RetryController<bool>(
  strategy: RetryStrategy.fixed(
    maxAttempts: 4,
    delay: const Duration(seconds: 1),
  ),
);

Future<void> main() async {
  controller.status.listen(print);
  final res = await controller.execute(onAction: _onAction);

  print(res.status);
}

FutureOr<bool?> _onAction() {
  final res = Random().nextBool();
  print('New action request: ${controller.attempt}, result: $res');
  return (res) ? true : null;
}
