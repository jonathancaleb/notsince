import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Indirection so time-dependent logic is testable without waiting.
abstract interface class Clock {
  DateTime now();
}

final class SystemClock implements Clock {
  const SystemClock();

  @override
  DateTime now() => DateTime.now();
}

final clockProvider = Provider<Clock>((ref) => const SystemClock());
