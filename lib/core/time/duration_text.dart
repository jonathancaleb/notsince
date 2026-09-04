/// Whole days elapsed — the primary unit on the home screen.
int daysOf(Duration d) => d.inDays;

/// Hours and minutes within the current day, the secondary line.
String secondaryLine(Duration d) {
  final hours = d.inHours.remainder(24);
  final minutes = d.inMinutes.remainder(60);
  return '$hours hr $minutes min';
}

/// Compact length of a finished run, e.g. "34 days", "6 hours", "12 minutes".
String runLength(Duration d) {
  if (d.inDays >= 1) return _plural(d.inDays, 'day');
  if (d.inHours >= 1) return _plural(d.inHours, 'hour');
  if (d.inMinutes >= 1) return _plural(d.inMinutes, 'minute');
  return 'less than a minute';
}

/// "4 Sep 2026, 14:05"
String dateTimeLabel(DateTime dt) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  final hh = dt.hour.toString().padLeft(2, '0');
  final mm = dt.minute.toString().padLeft(2, '0');
  return '${dt.day} ${months[dt.month - 1]} ${dt.year}, $hh:$mm';
}

String _plural(int n, String unit) => '$n $unit${n == 1 ? '' : 's'}';
