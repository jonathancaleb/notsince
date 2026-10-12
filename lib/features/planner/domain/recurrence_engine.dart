import 'models.dart';

abstract final class RecurrenceEngine {
  static DateTime? next(DateTime completedDate, RecurrenceRule rule) {
    final date = calendarDay(completedDate);
    if (!rule.repeats) return null;
    if (rule.weekdays.isEmpty) {
      return DateTime(date.year, date.month, date.day + rule.intervalDays);
    }
    for (var offset = 1; offset <= 7; offset++) {
      final candidate = DateTime(date.year, date.month, date.day + offset);
      if (rule.weekdays.contains(candidate.weekday)) return candidate;
    }
    return null;
  }
}
