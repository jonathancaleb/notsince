import 'package:flutter_test/flutter_test.dart';
import 'package:notsince/core/widgets/habit_plant.dart';
import 'package:notsince/features/notifications/domain/notification_copy.dart';

void main() {
  group('plant stages', () {
    test('starts as a seed and ends in flower', () {
      expect(HabitPlant.stageFor(passed: 0, total: 6), 0);
      expect(HabitPlant.stageFor(passed: 6, total: 6),
          HabitPlant.stageCount - 1);
    });

    test('reaches full flower on the last milestone whatever the count', () {
      // Scaled rather than counted, so a habit with three thresholds still
      // finishes the plant instead of stalling half grown.
      for (final total in [1, 2, 3, 6, 10]) {
        expect(HabitPlant.stageFor(passed: total, total: total),
            HabitPlant.stageCount - 1,
            reason: 'total of $total should finish the plant');
      }
    });

    test('grows monotonically', () {
      var last = -1;
      for (var passed = 0; passed <= 6; passed++) {
        final stage = HabitPlant.stageFor(passed: passed, total: 6);
        expect(stage, greaterThanOrEqualTo(last));
        last = stage;
      }
    });

    test('never goes out of range, even with odd input', () {
      expect(HabitPlant.stageFor(passed: 99, total: 6), HabitPlant.stageCount - 1);
      expect(HabitPlant.stageFor(passed: 0, total: 0), 0);
      expect(HabitPlant.stageFor(passed: 3, total: 0), HabitPlant.stageCount - 1);
    });
  });

  group('notification copy', () {
    test('has a written line for every default milestone', () {
      for (final d in const [
        Duration(hours: 24),
        Duration(days: 7),
        Duration(days: 30),
        Duration(days: 90),
        Duration(days: 180),
        Duration(days: 365),
      ]) {
        final line = NotificationCopy.milestone(d);
        expect(line, isNotEmpty);
        expect(line, isNot(contains('null')));
      }
    });

    test('falls back to something written for a custom threshold', () {
      expect(NotificationCopy.milestone(const Duration(days: 42)),
          contains('6 weeks'));
    });

    test('never congratulates or scolds', () {
      // The whole point of the copy rules: no performance language anywhere.
      const banned = ['well done', 'congrat', 'streak', 'don\'t break',
          'failed', 'keep it up', 'good job'];
      final lines = [
        for (final d in const [
          Duration(hours: 24),
          Duration(days: 7),
          Duration(days: 30),
          Duration(days: 365),
          Duration(days: 42),
        ])
          NotificationCopy.milestone(d),
        NotificationCopy.overdueTask('Call the dentist'),
      ];

      for (final line in lines) {
        for (final word in banned) {
          expect(line.toLowerCase(), isNot(contains(word)),
              reason: '"$line" should not say "$word"');
        }
      }
    });

    test('an overdue line names the task and stays neutral', () {
      final line = NotificationCopy.overdueTask('Call the dentist');
      expect(line, contains('Call the dentist'));
      expect(line, contains('Still there when you are'));
    });
  });
}
