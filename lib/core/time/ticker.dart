import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notsince/core/time/clock.dart';

/// A 1 Hz clock, deliberately auto-disposed: it only runs while something is
/// actually displaying a live duration, and stops the moment that leaves the
/// tree. Nothing watches this at a screen root.
final tickProvider = StreamProvider.autoDispose<DateTime>((ref) async* {
  final clock = ref.watch(clockProvider);
  yield clock.now();
  yield* Stream<void>.periodic(const Duration(seconds: 1))
      .map((_) => clock.now());
});
