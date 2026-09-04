import 'package:flutter_test/flutter_test.dart';
import 'package:notsince/features/alarms/domain/alarm_entry.dart';

AlarmEntry alarm({int hour = 7, int minute = 0, List<int> days = const []}) =>
    AlarmEntry(id: 'a', hour: hour, minute: minute, repeatDays: days);

void main() {
  group('nextOccurrence', () {
    test('a one-off alarm fires later today when the time is still ahead', () {
      final now = DateTime(2026, 3, 4, 6, 30); // Wednesday
      expect(alarm().nextOccurrence(now), DateTime(2026, 3, 4, 7));
    });

    test('a one-off alarm rolls to tomorrow once the time has passed', () {
      final now = DateTime(2026, 3, 4, 7, 30);
      expect(alarm().nextOccurrence(now), DateTime(2026, 3, 5, 7));
    });

    test('the exact fire time counts as passed, not as due now', () {
      // Otherwise an alarm would immediately re-arm for the same instant it
      // just rang and fire in a loop.
      final now = DateTime(2026, 3, 4, 7);
      expect(alarm().nextOccurrence(now), DateTime(2026, 3, 5, 7));
    });

    test('a repeating alarm skips days it is not set for', () {
      // Set for Monday and Thursday; today is Wednesday.
      final now = DateTime(2026, 3, 4, 8);
      final next = alarm(days: [DateTime.monday, DateTime.thursday])
          .nextOccurrence(now);
      expect(next, DateTime(2026, 3, 5, 7));
      expect(next!.weekday, DateTime.thursday);
    });

    test('a repeating alarm wraps around the week', () {
      // Set for Monday only; today is Wednesday.
      final now = DateTime(2026, 3, 4, 8);
      final next = alarm(days: [DateTime.monday]).nextOccurrence(now);
      expect(next, DateTime(2026, 3, 9, 7));
      expect(next!.weekday, DateTime.monday);
    });

    test('a daily alarm still fires later the same day', () {
      final now = DateTime(2026, 3, 4, 6);
      final everyDay = alarm(days: const [1, 2, 3, 4, 5, 6, 7]);
      expect(everyDay.nextOccurrence(now), DateTime(2026, 3, 4, 7));
    });

    test('a day set for today but already passed goes to next week', () {
      final now = DateTime(2026, 3, 4, 9); // Wednesday, after 07:00
      final next =
          alarm(days: [DateTime.wednesday]).nextOccurrence(now);
      expect(next, DateTime(2026, 3, 11, 7));
    });

    test('crosses a month boundary', () {
      final now = DateTime(2026, 3, 31, 23, 30);
      expect(alarm(hour: 6).nextOccurrence(now), DateTime(2026, 4, 1, 6));
    });
  });

  group('scheduleId', () {
    test('is stable for the same alarm and differs between alarms', () {
      const a = AlarmEntry(id: 'alpha');
      const b = AlarmEntry(id: 'beta');
      expect(a.scheduleId, a.scheduleId);
      expect(a.scheduleId, isNot(b.scheduleId));
    });

    test('is non-negative, since platform alarm ids must be', () {
      for (final id in ['a', 'zzzz', 'm4k2-9xq', '']) {
        expect(AlarmEntry(id: id).scheduleId, greaterThanOrEqualTo(0));
      }
    });
  });

  group('repeatLabel', () {
    test('names the common patterns', () {
      expect(repeatLabel(const []), 'Once');
      expect(repeatLabel(const [1, 2, 3, 4, 5, 6, 7]), 'Every day');
      expect(repeatLabel(const [1, 2, 3, 4, 5]), 'Weekdays');
      expect(repeatLabel(const [6, 7]), 'Weekends');
    });

    test('lists anything else in weekday order', () {
      expect(repeatLabel(const [4, 1]), 'Mon, Thu');
    });
  });

  test('clockLabel pads to 24-hour time', () {
    expect(clockLabel(7, 5), '07:05');
    expect(clockLabel(23, 59), '23:59');
    expect(clockLabel(0, 0), '00:00');
  });
}
