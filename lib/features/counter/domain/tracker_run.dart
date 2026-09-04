/// A completed run: one stretch of time between a start and a reset.
///
/// Stored rather than derived so that a run's length stays correct even if the
/// user later edits the start time of the *current* run in settings.
class TrackerRun {
  const TrackerRun({required this.startedAt, required this.endedAt});

  final DateTime startedAt;
  final DateTime endedAt;

  Duration get length => endedAt.difference(startedAt);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TrackerRun &&
          other.startedAt == startedAt &&
          other.endedAt == endedAt;

  @override
  int get hashCode => Object.hash(startedAt, endedAt);
}
