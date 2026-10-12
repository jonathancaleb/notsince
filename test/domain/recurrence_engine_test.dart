import 'package:flutter_test/flutter_test.dart';
import 'package:notsince/features/planner/domain/models.dart';
import 'package:notsince/features/planner/domain/recurrence_engine.dart';

void main() {
  test('non-recurring tasks produce no next occurrence', () {
    expect(
      RecurrenceEngine.next(DateTime(2026, 10, 12), const RecurrenceRule()),
      isNull,
    );
  });
  test('daily recurrence crosses month and year boundaries', () {
    expect(
      RecurrenceEngine.next(
        DateTime(2026, 12, 31, 23),
        const RecurrenceRule(intervalDays: 1),
      ),
      DateTime(2027, 1, 1),
    );
  });
  test('weekdays skips the weekend', () {
    expect(
      RecurrenceEngine.next(
        DateTime(2026, 10, 16),
        const RecurrenceRule(weekdays: [1, 2, 3, 4, 5]),
      ),
      DateTime(2026, 10, 19),
    );
  });
  test('custom recurrence chooses the next selected day', () {
    expect(
      RecurrenceEngine.next(
        DateTime(2026, 10, 12),
        const RecurrenceRule(weekdays: [1, 4]),
      ),
      DateTime(2026, 10, 15),
    );
    expect(
      RecurrenceEngine.next(
        DateTime(2026, 10, 15),
        const RecurrenceRule(weekdays: [4]),
      ),
      DateTime(2026, 10, 22),
    );
  });
  test('invalid weekdays cannot create an infinite recurrence', () {
    expect(
      RecurrenceEngine.next(
        DateTime(2026, 10, 12),
        const RecurrenceRule(weekdays: [0, 8]),
      ),
      isNull,
    );
  });
  test('interval recurrence advances by calendar days', () {
    expect(
      RecurrenceEngine.next(
        DateTime(2026, 2, 27),
        const RecurrenceRule(intervalDays: 3),
      ),
      DateTime(2026, 3, 2),
    );
  });
}
