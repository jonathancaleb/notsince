import 'package:notsince/features/counter/domain/milestones.dart';
import 'package:notsince/features/counter/domain/tracker_run.dart';

/// One tracked commitment.
///
/// Persisted directly by Hive without annotations (see lib/hive/hive_adapters.dart),
/// which is why every persisted value is a final constructor parameter with a
/// default and every derived value is a getter: the adapter generator persists
/// the former and ignores the latter. The defaults are also what makes adding a
/// field backward compatible — records written before a field existed read back
/// with its default rather than failing.
class Tracker {
  const Tracker({
    this.id = '',
    required this.name,
    required this.startedAt,
    this.emoji = '⭐',
    this.colorIndex = 0,
    this.sortIndex = 0,
    this.milestones = kDefaultMilestones,
    this.history = const [],
    this.acknowledged = const {},
    this.schemaVersion = 2,
  });

  /// Stable identity. Empty only for records written by the single-tracker
  /// schema, which the repository migrates on open.
  final String id;

  /// What is being tracked, e.g. "Drinking".
  final String name;

  /// When the current count began.
  final DateTime startedAt;

  /// How this counter is recognised at a glance when swiping between several.
  final String emoji;

  /// Index into the crayon palette. Stored as an index rather than a colour so
  /// the palette can be retuned without rewriting saved data.
  final int colorIndex;

  /// Position in the pager. Contiguous, ascending.
  final int sortIndex;

  /// Configurable thresholds, ascending.
  final List<Duration> milestones;

  /// Completed runs, oldest first.
  final List<TrackerRun> history;

  /// Milestones already acknowledged **in the current run**. Cleared on reset,
  /// so the same threshold can be met again in the next run.
  final Set<Duration> acknowledged;

  final int schemaVersion;

  Duration elapsedAt(DateTime now) => now.difference(startedAt);

  /// Thresholds sorted ascending, defensive against hand-edited settings.
  List<Duration> get sortedMilestones =>
      [...milestones]..sort((a, b) => a.compareTo(b));

  Tracker copyWith({
    String? id,
    String? name,
    DateTime? startedAt,
    String? emoji,
    int? colorIndex,
    int? sortIndex,
    List<Duration>? milestones,
    List<TrackerRun>? history,
    Set<Duration>? acknowledged,
  }) {
    return Tracker(
      id: id ?? this.id,
      name: name ?? this.name,
      startedAt: startedAt ?? this.startedAt,
      emoji: emoji ?? this.emoji,
      colorIndex: colorIndex ?? this.colorIndex,
      sortIndex: sortIndex ?? this.sortIndex,
      milestones: milestones ?? this.milestones,
      history: history ?? this.history,
      acknowledged: acknowledged ?? this.acknowledged,
      schemaVersion: schemaVersion,
    );
  }
}
