import 'models.dart';

class TimeReport {
  const TimeReport(this.totalSeconds, this.projectSeconds, this.subjectSeconds);
  final int totalSeconds;
  final Map<String, int> projectSeconds;
  final Map<String, int> subjectSeconds;
  String? get topProject => projectSeconds.isEmpty
      ? null
      : (projectSeconds.entries.toList()
              ..sort((a, b) => b.value.compareTo(a.value)))
            .first
            .key;
  double percentage(String projectId) =>
      totalSeconds == 0 ? 0 : (projectSeconds[projectId] ?? 0) / totalSeconds;
}

abstract final class TimeAggregation {
  /// Half-open interval clipping splits sessions crossing midnight correctly.
  static TimeReport between(
    Iterable<TimeEntry> entries,
    DateTime start,
    DateTime end,
  ) {
    var total = 0;
    final projects = <String, int>{}, subjects = <String, int>{};
    for (final entry in entries) {
      final from = entry.startedAt.isBefore(start) ? start : entry.startedAt;
      final to = entry.endedAt.isAfter(end) ? end : entry.endedAt;
      if (!to.isAfter(from)) continue;
      final seconds = to.difference(from).inSeconds;
      total += seconds;
      final key = '${entry.subjectType.name}:${entry.subjectId}';
      subjects[key] = (subjects[key] ?? 0) + seconds;
      final project =
          entry.projectId ??
          (entry.subjectType == SubjectType.project ? entry.subjectId : null);
      if (project != null) {
        projects[project] = (projects[project] ?? 0) + seconds;
      }
    }
    return TimeReport(total, projects, subjects);
  }
}
