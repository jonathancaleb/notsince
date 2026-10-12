import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notsince/core/time/clock.dart';
import 'package:notsince/core/time/ticker.dart';
import 'package:notsince/features/alarms/presentation/alarms_screen.dart';
import 'package:notsince/features/counter/application/tracker_controller.dart';
import 'package:notsince/features/counter/presentation/counter_form_screen.dart';
import 'package:notsince/features/counter/presentation/counter_screen.dart';
import 'package:notsince/features/garden/presentation/garden_screen.dart';
import 'package:notsince/features/settings/presentation/app_settings_screen.dart';
import 'package:notsince/widgets/habit_circle.dart';

import '../data/planner_store.dart';
import '../domain/models.dart';
import 'planner_screen.dart';

class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trackers = ref.watch(trackersProvider),
        state = ref.watch(plannerProvider);
    final now = ref.watch(tickProvider).value ?? ref.read(clockProvider).now();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Today'),
        actions: [
          IconButton(
            tooltip: 'Alarms',
            icon: const Icon(Icons.alarm_rounded),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AlarmsScreen()),
            ),
          ),
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings_rounded),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AppSettingsScreen()),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(24, 8, 24, 16),
            child: DayTimer(),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 128),
              children: [
                Text(
                  dayKey(now),
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'A little care, every day',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Add a habit',
                      onPressed: () => CounterFormScreen.create(context),
                      icon: const Icon(Icons.add_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (trackers.isEmpty)
                  const Text('Plant your first habit. Small beginnings count.'),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final tracker in trackers)
                        Padding(
                          padding: const EdgeInsets.only(right: 16),
                          child: HabitCircle(
                            label: tracker.name,
                            color: habitColor(context, state, tracker),
                            emoji: tracker.emoji,
                            progress:
                                ((state.progress['${tracker.id}:${dayKey(now)}'] ??
                                            0) /
                                        (state.goals[tracker.id] ?? 1))
                                    .clamp(0, 1),
                            onCheckIn: () => waterHabit(context, ref, tracker),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    PlantDetailScreen(id: tracker.id),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CounterScreen()),
                  ),
                  child: const Text('All counters & history'),
                ),
                const SizedBox(height: 24),
                Text(
                  'Your next small steps',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                const TaskList(todayOnly: true),
                const ExistingTasks(todayOnly: true),
                const SizedBox(height: 16),
                const TaskQuickAdd(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
