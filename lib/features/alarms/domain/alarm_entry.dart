import 'package:notsince/features/alarms/domain/ringtone.dart';

/// One alarm.
///
/// Named `AlarmEntry` rather than `Alarm` because the `alarm` plugin exports a
/// class of that name; keeping them distinct means the domain never gets
/// silently swapped for the plugin's own type at a call site.
///
/// Persisted directly by Hive without annotations (see core/hive/hive_adapters.dart),
/// so every persisted value is a final constructor parameter with a default and
/// every derived value is a getter.
class AlarmEntry {
  const AlarmEntry({
    this.id = '',
    this.label = 'Alarm',
    this.hour = 7,
    this.minute = 0,
    this.repeatDays = const [],
    this.soundId = kDefaultRingtoneId,
    this.isEnabled = true,
    this.snoozeMinutes = 5,
    this.sortIndex = 0,
  });

  final String id;
  final String label;

  /// Wall-clock time, not a DateTime: an alarm set for 07:00 means 07:00 every
  /// day it fires, which a stored instant cannot express across DST or a
  /// change of date.
  final int hour;
  final int minute;

  /// `DateTime.monday`..`DateTime.sunday` (1–7). Empty means a one-off alarm
  /// that fires at the next occurrence of [hour]:[minute] and then disables
  /// itself.
  final List<int> repeatDays;

  final String soundId;
  final bool isEnabled;
  final int snoozeMinutes;
  final int sortIndex;

  bool get repeats => repeatDays.isNotEmpty;

  /// A stable 32-bit id for the platform alarm scheduler, which keys alarms by
  /// int rather than by string.
  int get scheduleId => id.hashCode & 0x7FFFFFFF;

  /// The next instant this alarm should ring, at or after [from].
  ///
  /// Walks forward day by day rather than doing modular arithmetic on
  /// weekdays, because constructing each candidate as a local `DateTime` lets
  /// the platform resolve DST for us instead of us assuming every day is 24
  /// hours long.
  DateTime? nextOccurrence(DateTime from) {
    for (var offset = 0; offset <= 7; offset++) {
      final day = DateTime(from.year, from.month, from.day + offset);
      final candidate = DateTime(day.year, day.month, day.day, hour, minute);
      if (!candidate.isAfter(from)) continue;
      if (!repeats || repeatDays.contains(candidate.weekday)) return candidate;
    }
    return null;
  }

  AlarmEntry copyWith({
    String? id,
    String? label,
    int? hour,
    int? minute,
    List<int>? repeatDays,
    String? soundId,
    bool? isEnabled,
    int? snoozeMinutes,
    int? sortIndex,
  }) {
    return AlarmEntry(
      id: id ?? this.id,
      label: label ?? this.label,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      repeatDays: repeatDays ?? this.repeatDays,
      soundId: soundId ?? this.soundId,
      isEnabled: isEnabled ?? this.isEnabled,
      snoozeMinutes: snoozeMinutes ?? this.snoozeMinutes,
      sortIndex: sortIndex ?? this.sortIndex,
    );
  }
}

/// "Every day", "Weekdays", "Mon, Thu", or "Once".
String repeatLabel(List<int> days) {
  if (days.isEmpty) return 'Once';

  final set = {...days};
  if (set.length == 7) return 'Every day';
  if (set.length == 5 && set.every((d) => d <= DateTime.friday)) {
    return 'Weekdays';
  }
  if (set.length == 2 &&
      set.contains(DateTime.saturday) &&
      set.contains(DateTime.sunday)) {
    return 'Weekends';
  }

  const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  final sorted = set.toList()..sort();
  return sorted.map((d) => names[d - 1]).join(', ');
}

/// "07:00"
String clockLabel(int hour, int minute) =>
    '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
