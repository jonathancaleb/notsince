/// Milestones are plain [Duration] thresholds. There is no milestone entity,
/// no id and no stored label: a threshold is its own identity, and its label is
/// derived at render time. That keeps "user-configurable thresholds" to simple
/// list editing.
const List<Duration> kDefaultMilestones = [
  Duration(hours: 24),
  Duration(days: 7),
  Duration(days: 30),
  Duration(days: 90),
  Duration(days: 180),
  Duration(days: 365),
];

/// Calendar-ish units, fixed-length so a milestone stays a pure [Duration].
const Duration kMonth = Duration(days: 30);
const Duration kYear = Duration(days: 365);

/// Human label for a threshold, e.g. "1 week", "3 months", "1 year".
String milestoneLabel(Duration d) {
  if (d.inSeconds <= 0) return 'now';

  if (d.inMinutes % kYear.inMinutes == 0) {
    return _plural(d.inMinutes ~/ kYear.inMinutes, 'year');
  }
  if (d.inMinutes % kMonth.inMinutes == 0) {
    return _plural(d.inMinutes ~/ kMonth.inMinutes, 'month');
  }
  if (d.inMinutes % const Duration(days: 7).inMinutes == 0) {
    return _plural(d.inMinutes ~/ const Duration(days: 7).inMinutes, 'week');
  }
  // Under two days reads in hours, so the first default threshold is
  // "24 hours" rather than the technically-equal but weaker "1 day".
  if (d < const Duration(days: 2) && d.inMinutes % 60 == 0) {
    return _plural(d.inHours, 'hour');
  }
  if (d.inMinutes % const Duration(days: 1).inMinutes == 0) {
    return _plural(d.inDays, 'day');
  }
  if (d.inMinutes % 60 == 0) return _plural(d.inHours, 'hour');
  return _plural(d.inMinutes, 'minute');
}

String _plural(int n, String unit) => '$n $unit${n == 1 ? '' : 's'}';
