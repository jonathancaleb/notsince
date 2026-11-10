import 'dart:math' as math;
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notsince/core/time/clock.dart';
import 'package:notsince/core/time/ticker.dart';
import 'package:notsince/features/counter/application/tracker_controller.dart';
import 'package:notsince/features/counter/domain/tracker.dart';
import 'package:notsince/features/counter/presentation/counter_form_screen.dart';
import 'package:notsince/features/counter/presentation/widgets/counter_page.dart';
import 'package:notsince/features/planner/data/planner_store.dart';
import 'package:notsince/features/planner/domain/models.dart';
import 'package:notsince/features/planner/presentation/planner_screen.dart';
import 'package:notsince/core/theme/app_colors.dart';
import 'package:notsince/core/theme/ns_colors.dart';
import 'package:notsince/core/theme/sketch.dart';
import 'package:notsince/core/theme/app_spacing.dart';
import 'package:notsince/core/widgets/habit_circle.dart';
import 'package:notsince/core/widgets/soft_card.dart';

import '../growth_engine.dart';
import 'package:notsince/core/widgets/doodle_icon.dart';

part 'widgets/plant_detail.dart';

Color habitColor(BuildContext context, PlannerState state, Tracker tracker) =>
    AppColors.lifted(
      state.colors[tracker.id] ??
          AppColors.palette[tracker.colorIndex % AppColors.palette.length],
      Theme.of(context).brightness,
    );

Future<void> waterHabit(
  BuildContext context,
  WidgetRef ref,
  Tracker tracker, {
  double amount = 1,
}) async {
  final now = ref.read(clockProvider).now(), state = ref.read(plannerProvider);
  final dates = (state.checkIns[tracker.id] ?? []).map(DateTime.parse);
  if (dates.any((d) => dayKey(d) == dayKey(now))) return;
  final before = GrowthEngine.evaluate(
    dates,
    now,
    plantedAt: tracker.startedAt,
  );
  await ref.read(plannerProvider.notifier).checkIn(tracker.id, amount: amount);
  if (!context.mounted) return;
  final after = GrowthEngine.evaluate(
    (ref.read(plannerProvider).checkIns[tracker.id] ?? []).map(DateTime.parse),
    now,
    plantedAt: tracker.startedAt,
  );
  if (after.stage.index > before.stage.index) {
    unawaited(
      Future<void>.delayed(const Duration(milliseconds: 320), () async {
        if (!context.mounted) return;
        await showGeneralDialog<void>(
          context: context,
          barrierDismissible: true,
          barrierLabel: 'Close celebration',
          transitionDuration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : const Duration(milliseconds: 280),
          pageBuilder: (context, _, _) =>
              _BloomCelebration(name: tracker.name, stage: after.stage),
        );
      }),
    );
  }
}

class GardenScreen extends ConsumerWidget {
  const GardenScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trackers = ref.watch(trackersProvider),
        state = ref.watch(plannerProvider);
    final now = ref.watch(tickProvider).value ?? ref.read(clockProvider).now();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your habit garden'),
        actions: [
          IconButton(
            tooltip: 'Plant a habit',
            icon: const DoodleIcon(Icons.add_rounded),
            onPressed: () => CounterFormScreen.create(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 128),
        children: [
          const Text(
            'Small care. Beautiful growth.\nRest days never erase what you’ve grown.',
          ),
          const SizedBox(height: AppSpacing.md),
          if (trackers.isEmpty)
            SoftCard(
              child: Column(
                children: [
                  const Text('Your first seed is waiting.'),
                  const SizedBox(height: AppSpacing.sm),
                  FilledButton(
                    onPressed: () => CounterFormScreen.create(context),
                    child: const Text('Plant a habit'),
                  ),
                ],
              ),
            ),
          LayoutBuilder(
            builder: (context, constraints) => Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final tracker in trackers)
                  SizedBox(
                    width: (constraints.maxWidth - 16) / 2,
                    child: Builder(
                      builder: (context) {
                        final growth = GrowthEngine.evaluate(
                          (state.checkIns[tracker.id] ?? []).map(
                            DateTime.parse,
                          ),
                          now,
                          plantedAt: tracker.startedAt,
                        );
                        return SoftCard(
                          padding: const EdgeInsets.all(AppSpacing.sm),
                          child: Column(
                            children: [
                              HabitCircle(
                                label: tracker.name,
                                color: habitColor(context, state, tracker),
                                progress:
                                    ((state.progress['${tracker.id}:${dayKey(now)}'] ??
                                                0) /
                                            (state.goals[tracker.id] ?? 1))
                                        .clamp(0, 1),
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        PlantDetailScreen(id: tracker.id),
                                  ),
                                ),
                                onCheckIn: () =>
                                    waterHabit(context, ref, tracker),
                                child: SizedBox(
                                  width: 68,
                                  height: 72,
                                  // One boundary per plant: each card's painter
                                  // repaints alone when its stage changes, and
                                  // the page's 1 Hz clock does not touch them.
                                  child: RepaintBoundary(
                                    child: CustomPaint(
                                      painter: _PlantPainter(
                                        growth.stage,
                                        growth.wilted,
                                        habitColor(context, state, tracker),
                                        context.ns.ink,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                growth.wilted
                                    ? 'A little water, a little patience'
                                    : growth.stage.name,
                                style: Theme.of(context).textTheme.labelSmall,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

