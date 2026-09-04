import 'package:notsince/features/counter/domain/tracker.dart';

/// Derived, never stored.
class TrackerProgress {
  const TrackerProgress({
    required this.elapsed,
    required this.nextMilestone,
    required this.progress,
  });

  final Duration elapsed;

  /// The first threshold not yet passed, or null once all have been passed.
  final Duration? nextMilestone;

  /// 0.0–1.0 toward [nextMilestone]. Full once every milestone is behind.
  final double progress;

  bool get allMilestonesPassed => nextMilestone == null;
}

TrackerProgress computeProgress(Tracker tracker, DateTime now) {
  final elapsed = tracker.elapsedAt(now);
  final safeElapsed = elapsed.isNegative ? Duration.zero : elapsed;

  Duration? next;
  for (final milestone in tracker.sortedMilestones) {
    if (milestone > Duration.zero && safeElapsed < milestone) {
      next = milestone;
      break;
    }
  }

  final progress = next == null
      ? 1.0
      : (safeElapsed.inSeconds / next.inSeconds).clamp(0.0, 1.0);

  return TrackerProgress(
    elapsed: safeElapsed,
    nextMilestone: next,
    progress: progress,
  );
}

/// Thresholds already reached, ascending.
List<Duration> crossedMilestones(Tracker tracker, DateTime now) {
  final elapsed = tracker.elapsedAt(now);
  return tracker.sortedMilestones
      .where((m) => m > Duration.zero && elapsed >= m)
      .toList();
}
