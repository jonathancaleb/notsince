import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notsince/features/counter/application/progress_provider.dart';
import 'package:notsince/features/counter/application/tracker_controller.dart';

/// The oldest threshold a counter has reached but not yet acknowledged.
///
/// Deliberately computed from elapsed time rather than observed at the moment
/// of crossing, so a milestone reached while the app was closed still surfaces
/// on next open. This recomputes every tick but only notifies listeners when
/// the value actually changes, so the banner does not rebuild once a second.
final pendingMilestoneProvider =
    Provider.autoDispose.family<Duration?, String>((ref, id) {
  final tracker = ref.watch(trackerProvider(id));
  if (tracker == null) return null;

  final elapsed = tracker.elapsedAt(ref.watch(nowProvider));
  for (final milestone in tracker.sortedMilestones) {
    if (milestone > Duration.zero &&
        elapsed >= milestone &&
        !tracker.acknowledged.contains(milestone)) {
      return milestone;
    }
  }
  return null;
});
