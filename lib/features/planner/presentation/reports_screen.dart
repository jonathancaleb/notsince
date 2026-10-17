import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notsince/core/time/clock.dart';
import 'package:notsince/core/time/ticker.dart';
import 'package:notsince/features/counter/application/tracker_controller.dart';
import 'package:notsince/features/garden/growth_engine.dart';
import 'package:notsince/core/widgets/soft_card.dart';

import '../data/planner_store.dart';
import '../domain/models.dart';
import '../domain/time_aggregation.dart';
import 'planner_screen.dart';

class ReportsView extends ConsumerStatefulWidget {
  const ReportsView({super.key});
  @override
  ConsumerState<ReportsView> createState() => _ReportsViewState();
}

class _ReportsViewState extends ConsumerState<ReportsView> {
  bool _monthly = false;
  @override
  Widget build(BuildContext context) {
    final now = ref.watch(tickProvider).value ?? ref.read(clockProvider).now();
    final state = ref.watch(plannerProvider),
        trackers = ref.watch(trackersProvider);
    final start = _monthly
        ? DateTime(now.year, now.month)
        : DateTime(now.year, now.month, now.day - now.weekday + 1);
    final end = DateTime(now.year, now.month, now.day + 1);
    final active = state.active;
    final report = TimeAggregation.between(
      [
        ...state.entries,
        if (active != null)
          TimeEntry(
            id: active.id,
            subjectType: active.subjectType,
            subjectId: active.subjectId,
            startedAt: active.startedAt,
            durationSec: now
                .difference(active.startedAt)
                .inSeconds
                .clamp(0, 2147483647),
            projectId: active.projectId,
          ),
      ],
      start,
      end,
    );
    final top = state.projects
        .where((p) => p.id == report.topProject)
        .firstOrNull;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 8,
          children: [
            ChoiceChip(
              label: const Text('This week'),
              selected: !_monthly,
              onSelected: (_) => setState(() => _monthly = false),
            ),
            ChoiceChip(
              label: const Text('This month'),
              selected: _monthly,
              onSelected: (_) => setState(() => _monthly = true),
            ),
          ],
        ),
        const SizedBox(height: 24),
        SoftCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Time well spent'),
              Text(
                elapsedLabel(report.totalSeconds),
                style: Theme.of(context).textTheme.displaySmall,
              ),
              Text('Top project · ${top?.name ?? 'No project time yet'}'),
            ],
          ),
        ),
        const SizedBox(height: 24),
        for (final project in state.projects)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: SoftCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${project.name} · ${(report.percentage(project.id) * 100).round()}%',
                  ),
                  if (report.totalSeconds > 0)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: Text(
                        'Unassigned · ${((1 - report.projectSeconds.values.fold<int>(0, (a, b) => a + b) / report.totalSeconds) * 100).round()}%',
                      ),
                    ),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: report.percentage(project.id),
                    color: Color(project.color),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ],
              ),
            ),
          ),
        for (final tracker in trackers)
          Builder(
            builder: (context) {
              final dates = (state.checkIns[tracker.id] ?? [])
                  .map(DateTime.parse)
                  .toList();
              final plant = GrowthEngine.evaluate(
                dates,
                now,
                plantedAt: tracker.startedAt,
              );
              final eligible = calendarDay(tracker.startedAt).isAfter(start)
                  ? calendarDay(tracker.startedAt)
                  : start;
              var days = 0, complete = 0;
              for (
                var d = eligible;
                d.isBefore(end);
                d = DateTime(d.year, d.month, d.day + 1)
              ) {
                days++;
                if (dates.any((e) => calendarDay(e) == d)) complete++;
              }
              return Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: SoftCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tracker.name,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Text(
                        '${days == 0 ? 0 : (complete / days * 100).round()}% complete · ${plant.streak} day check-in streak',
                      ),
                      const SizedBox(height: 16),
                      CompletionHeatmap(dates: dates, now: now),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}

class CompletionHeatmap extends StatelessWidget {
  const CompletionHeatmap({super.key, required this.dates, required this.now});
  final List<DateTime> dates;
  final DateTime now;
  @override
  Widget build(BuildContext context) {
    final completed = dates.map(dayKey).toSet();
    final monday = DateTime(
      now.year,
      now.month,
      now.day - now.weekday + 1 - 77,
    );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var week = 0; week < 12; week++)
          Expanded(
            child: Column(
              children: [
                for (var weekday = 0; weekday < 7; weekday++)
                  Builder(
                    builder: (context) {
                      final day = DateTime(
                        monday.year,
                        monday.month,
                        monday.day + week * 7 + weekday,
                      );
                      final done = completed.contains(dayKey(day));
                      if (day.isAfter(calendarDay(now))) {
                        return const SizedBox(width: 14, height: 18);
                      }
                      return Tooltip(
                        message:
                            '${dayKey(day)} · ${done ? 'Checked in' : 'Rest day'}',
                        child: Semantics(
                          label:
                              '${dayKey(day)} ${done ? 'completed' : 'not completed'}',
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 4),
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              color: done
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).colorScheme.primary
                                        .withValues(alpha: .08),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Insights')),
    body: const SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(24, 8, 24, 128),
      child: ReportsView(),
    ),
  );
}
