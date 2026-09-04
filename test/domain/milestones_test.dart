import 'package:flutter_test/flutter_test.dart';
import 'package:notsince/core/time/duration_text.dart';
import 'package:notsince/features/counter/domain/milestones.dart';

void main() {
  group('milestoneLabel', () {
    test('labels the defaults', () {
      expect(kDefaultMilestones.map(milestoneLabel).toList(), [
        '24 hours',
        '1 week',
        '1 month',
        '3 months',
        '6 months',
        '1 year',
      ]);
    });

    test('prefers the largest exact unit', () {
      expect(milestoneLabel(const Duration(days: 365)), '1 year');
      expect(milestoneLabel(const Duration(days: 30)), '1 month');
      expect(milestoneLabel(const Duration(days: 7)), '1 week');
      expect(milestoneLabel(const Duration(days: 3)), '3 days');
      expect(milestoneLabel(const Duration(hours: 24)), '24 hours');
      expect(milestoneLabel(const Duration(hours: 6)), '6 hours');
      expect(milestoneLabel(const Duration(minutes: 90)), '90 minutes');
    });

    test('singularises', () {
      expect(milestoneLabel(const Duration(days: 14)), '2 weeks');
      expect(milestoneLabel(const Duration(days: 60)), '2 months');
    });
  });

  group('duration text', () {
    test('splits days from the hour/minute remainder', () {
      const d = Duration(days: 3, hours: 5, minutes: 9);
      expect(daysOf(d), 3);
      expect(secondaryLine(d), '5 hr 9 min');
    });

    test('runLength falls back through the units', () {
      expect(runLength(const Duration(days: 34)), '34 days');
      expect(runLength(const Duration(days: 1)), '1 day');
      expect(runLength(const Duration(hours: 6)), '6 hours');
      expect(runLength(const Duration(minutes: 12)), '12 minutes');
      expect(runLength(const Duration(seconds: 5)), 'less than a minute');
    });
  });
}
