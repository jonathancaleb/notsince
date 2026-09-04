import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notsince/features/counter/application/progress_provider.dart';
import 'package:notsince/features/counter/application/tracker_controller.dart';
import 'package:notsince/core/theme/ns_colors.dart';
import 'package:notsince/core/theme/app_type.dart';
import 'package:notsince/core/time/duration_text.dart';
import 'package:notsince/features/counter/domain/habit_copy.dart';
import 'package:notsince/features/counter/domain/milestones.dart';
import 'package:notsince/features/counter/domain/tracker_progress.dart';
import 'package:notsince/features/counter/presentation/history_screen.dart';
import 'package:notsince/features/counter/presentation/widgets/milestone_banner.dart';
import 'package:notsince/features/counter/presentation/reset_confirm_sheet.dart';
import 'package:notsince/features/counter/presentation/counter_settings_screen.dart';
import 'package:notsince/core/widgets/sticker_button.dart';
import 'package:notsince/core/widgets/sticker_card.dart';
import 'package:notsince/core/widgets/habit_plant.dart';

/// One counter, full screen.
///
/// The whole page is built around a single number. Everything else — icon,
/// name, progress, actions — is sized to stay clearly subordinate to it, so
/// there is never any question about what the screen is for.
class CounterPage extends ConsumerWidget {
  const CounterPage({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ns = context.ns;
    final tracker = ref.watch(trackerProvider(id));
    if (tracker == null) return const SizedBox.shrink();

    final crayon = ns.crayon(tracker.colorIndex);
    final ground = ns.crayonTint(tracker.colorIndex);

    return SingleChildScrollView(
      // No nav clearance here: this page sits inside CounterScreen, whose
      // "Add a habit" button already reserves it below the pager. Reserving it
      // twice pushed the plant off the bottom of the screen.
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MilestoneBanner(id: id, color: crayon),
          StickerCard(
            color: ground,
            padding: const EdgeInsets.fromLTRB(22, 14, 22, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Heading(id: id, emoji: tracker.emoji, name: tracker.name),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _Plant(id: id, color: crayon),
                    const SizedBox(width: 12),
                    Expanded(child: _BigCount(id: id)),
                  ],
                ),
                const SizedBox(height: 14),
                _Timeline(id: id, color: crayon),
              ],
            ),
          ),
          const SizedBox(height: 18),
          StickerButton(
            color: crayon,
            onPressed: () => ResetConfirmSheet.show(context, id),
            child: const Text('Start a new count'),
          ),
          const SizedBox(height: 10),
          StickerButton(
            color: ns.paper,
            foreground: ns.ink,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => HistoryScreen(id: id)),
            ),
            child: const Text('History'),
          ),
        ],
      ),
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading({required this.id, required this.emoji, required this.name});

  final String id;
  final String emoji;
  final String name;

  @override
  Widget build(BuildContext context) {
    final ns = context.ns;
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 30)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppType.cardTitle,
          ),
        ),
        SizedBox(
          height: 40,
          child: StickerButton(
            color: ns.paper,
            foreground: ns.ink,
            thin: true,
            expand: false,
            radius: 12,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => CounterSettingsScreen(id: id)),
            ),
            child: const Center(child: Icon(Icons.tune_rounded, size: 18)),
          ),
        ),
      ],
    );
  }
}

/// The focal point. The only widget that watches the 1 Hz tick, which is why
/// the rest of the page does not rebuild every second.
class _BigCount extends ConsumerWidget {
  const _BigCount({required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ns = context.ns;
    final progress = ref.watch(progressProvider(id));
    final tracker = ref.watch(trackerProvider(id));
    if (progress == null || tracker == null) return const SizedBox.shrink();

    final days = daysOf(progress.elapsed);
    final hasHistory = tracker.history.isNotEmpty;

    return Column(
      children: [
        // Fitted so a four-digit count still fills the card rather than
        // wrapping or shrinking the layout around it.
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            '$days',
            style: AppType.counter(80),
          ),
        ),
        Text(days == 1 ? 'day' : 'days', style: AppType.cardTitle),
        const SizedBox(height: 10),
        Text(
          secondaryLine(progress.elapsed),
          style: AppType.muted(ns),
        ),
        const SizedBox(height: 8),
        Text(
          habitEncouragement(progress.elapsed, hasHistory: hasHistory),
          textAlign: TextAlign.center,
          style: AppType.bodyText.copyWith(fontSize: 14),
        ),
      ],
    );
  }
}

class _Plant extends ConsumerWidget {
  const _Plant({required this.id, required this.color});

  final String id;
  final Color color;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tracker = ref.watch(trackerProvider(id));
    final progress = ref.watch(progressProvider(id));
    if (tracker == null || progress == null) return const SizedBox.shrink();

    final stops = tracker.sortedMilestones;
    final passed =
        crossedMilestones(tracker, tracker.startedAt.add(progress.elapsed));

    return HabitPlant(
      stage: HabitPlant.stageFor(passed: passed.length, total: stops.length),
      color: color,
      size: const Size(96, 106),
    );
  }
}

class _Timeline extends ConsumerWidget {
  const _Timeline({required this.id, required this.color});

  final String id;
  final Color color;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ns = context.ns;
    final tracker = ref.watch(trackerProvider(id));
    final progress = ref.watch(progressProvider(id));
    if (tracker == null || progress == null) return const SizedBox.shrink();

    final stops = tracker.sortedMilestones;
    final passed =
        crossedMilestones(tracker, tracker.startedAt.add(progress.elapsed));
    final next = progress.nextMilestone;

    return Text(
      next == null
          ? 'Fully grown · every milestone behind you'
          : '${passed.length} of ${stops.length} · next ${milestoneLabel(next)}',
      textAlign: TextAlign.center,
      style: AppType.muted(ns),
    );
  }
}
