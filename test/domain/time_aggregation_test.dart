import 'package:flutter_test/flutter_test.dart';
import 'package:notsince/features/planner/domain/models.dart';
import 'package:notsince/features/planner/domain/time_aggregation.dart';

void main() {
  final start = DateTime(2026, 10, 12), end = DateTime(2026, 10, 13);
  TimeEntry entry(
    String id,
    SubjectType type,
    int seconds, {
    String? projectId,
    DateTime? at,
  }) => TimeEntry(
    id: id,
    subjectId: id,
    subjectType: type,
    startedAt: at ?? start,
    durationSec: seconds,
    projectId: projectId,
  );
  test('all subject types contribute to one report', () {
    final report = TimeAggregation.between(
      [
        entry('day', SubjectType.day, 60),
        entry('project', SubjectType.project, 120),
        entry('task', SubjectType.task, 180, projectId: 'project'),
        entry('habit', SubjectType.habit, 240),
      ],
      start,
      end,
    );
    expect(report.totalSeconds, 600);
    expect(report.projectSeconds['project'], 300);
    expect(report.topProject, 'project');
    expect(report.percentage('project'), .5);
    expect(report.subjectSeconds['habit:habit'], 240);
  });
  test('sessions are clipped at both report boundaries', () {
    final report = TimeAggregation.between(
      [
        entry('before', SubjectType.day, 7200, at: DateTime(2026, 10, 11, 23)),
        entry('after', SubjectType.day, 7200, at: DateTime(2026, 10, 12, 23)),
        entry('outside', SubjectType.day, 60, at: DateTime(2026, 10, 14)),
      ],
      start,
      end,
    );
    expect(report.totalSeconds, 7200);
  });
  test('half-open periods do not double-count midnight', () {
    final session = entry(
      'night',
      SubjectType.day,
      7200,
      at: DateTime(2026, 10, 12, 23),
    );
    expect(TimeAggregation.between([session], start, end).totalSeconds, 3600);
    expect(
      TimeAggregation.between(
        [session],
        end,
        DateTime(2026, 10, 14),
      ).totalSeconds,
      3600,
    );
  });
  test('an empty report has no top project or NaN percentages', () {
    final report = TimeAggregation.between([], start, end);
    expect(report.topProject, isNull);
    expect(report.percentage('anything'), 0);
  });
}
