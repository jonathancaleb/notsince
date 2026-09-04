import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notsince/features/counter/application/tracker_controller.dart';
import 'package:notsince/core/time/clock.dart';
import 'package:notsince/core/time/ticker.dart';
import 'package:notsince/features/counter/domain/tracker_progress.dart';

/// Current time, live while watched. Falls back to a single clock read before
/// the first tick arrives so nothing ever renders an empty duration.
final nowProvider = Provider.autoDispose<DateTime>((ref) {
  return ref.watch(tickProvider).value ?? ref.watch(clockProvider).now();
});

final progressProvider =
    Provider.autoDispose.family<TrackerProgress?, String>((ref, id) {
  final tracker = ref.watch(trackerProvider(id));
  if (tracker == null) return null;
  return computeProgress(tracker, ref.watch(nowProvider));
});
