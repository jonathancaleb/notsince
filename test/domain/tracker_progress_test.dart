import 'package:flutter_test/flutter_test.dart';
import 'package:notsince/features/counter/domain/milestones.dart';
import 'package:notsince/features/counter/domain/tracker.dart';
import 'package:notsince/features/counter/domain/tracker_progress.dart';

final _start = DateTime(2026, 1, 1, 12);

Tracker _tracker({List<Duration>? milestones}) => Tracker(
      name: 'Drinking',
      startedAt: _start,
      milestones: milestones ?? kDefaultMilestones,
    );

void main() {
  group('computeProgress', () {
    test('picks the first unpassed threshold as next', () {
      final p = computeProgress(_tracker(), _start.add(const Duration(days: 3)));
      expect(p.nextMilestone, const Duration(days: 7));
    });

    test('measures progress as elapsed over the next threshold', () {
      // Per spec: currentDuration / nextMilestone, not the distance between
      // the previous and next thresholds.
      final p = computeProgress(_tracker(), _start.add(const Duration(days: 1)));
      expect(p.nextMilestone, const Duration(days: 7));
      expect(p.progress, closeTo(1 / 7, 0.0001));
    });

    test('a threshold reached exactly is passed, not pending', () {
      final p = computeProgress(_tracker(), _start.add(const Duration(days: 7)));
      expect(p.nextMilestone, const Duration(days: 30));
    });

    test('reports full progress once every threshold is behind', () {
      final p =
          computeProgress(_tracker(), _start.add(const Duration(days: 400)));
      expect(p.nextMilestone, isNull);
      expect(p.allMilestonesPassed, isTrue);
      expect(p.progress, 1.0);
    });

    test('clamps a start time in the future to zero elapsed', () {
      final p =
          computeProgress(_tracker(), _start.subtract(const Duration(days: 2)));
      expect(p.elapsed, Duration.zero);
      expect(p.progress, 0.0);
    });

    test('handles an empty milestone list', () {
      final p = computeProgress(
        _tracker(milestones: const []),
        _start.add(const Duration(days: 5)),
      );
      expect(p.nextMilestone, isNull);
      expect(p.elapsed, const Duration(days: 5));
    });

    test('sorts unordered thresholds before choosing', () {
      final p = computeProgress(
        _tracker(milestones: const [Duration(days: 30), Duration(days: 7)]),
        _start.add(const Duration(days: 3)),
      );
      expect(p.nextMilestone, const Duration(days: 7));
    });
  });

  group('crossedMilestones', () {
    test('returns reached thresholds ascending', () {
      final crossed =
          crossedMilestones(_tracker(), _start.add(const Duration(days: 35)));
      expect(crossed, const [
        Duration(hours: 24),
        Duration(days: 7),
        Duration(days: 30),
      ]);
    });

    test('is empty at the very start', () {
      expect(crossedMilestones(_tracker(), _start), isEmpty);
    });
  });
}
