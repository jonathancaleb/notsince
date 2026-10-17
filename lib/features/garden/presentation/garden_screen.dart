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
import 'package:notsince/widgets/habit_circle.dart';
import 'package:notsince/widgets/soft_card.dart';

import '../growth_engine.dart';

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
            icon: const Icon(Icons.add_rounded),
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
          const SizedBox(height: 24),
          if (trackers.isEmpty)
            SoftCard(
              child: Column(
                children: [
                  const Text('Your first seed is waiting.'),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => CounterFormScreen.create(context),
                    child: const Text('Plant a habit'),
                  ),
                ],
              ),
            ),
          LayoutBuilder(
            builder: (context, constraints) => Wrap(
              spacing: 16,
              runSpacing: 16,
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
                          padding: const EdgeInsets.all(16),
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
                                  child: CustomPaint(
                                    painter: _PlantPainter(
                                      growth.stage,
                                      growth.wilted,
                                      habitColor(context, state, tracker),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
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

class PlantIllustration extends StatelessWidget {
  const PlantIllustration({
    super.key,
    required this.stage,
    required this.wilted,
    required this.color,
  });
  final GrowthStage stage;
  final bool wilted;
  final Color color;
  @override
  Widget build(BuildContext context) => Semantics(
    label: '${wilted ? 'Wilting ' : ''}${stage.name}',
    child: TweenAnimationBuilder<double>(
      tween: Tween(begin: .95, end: 1),
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 280),
      curve: Curves.easeOutBack,
      builder: (context, value, child) =>
          Transform.scale(scale: value, child: child),
      child: CustomPaint(
        size: const Size(112, 120),
        painter: _PlantPainter(stage, wilted, color),
      ),
    ),
  );
}

class _PlantPainter extends CustomPainter {
  _PlantPainter(this.stage, this.wilted, this.color);
  final GrowthStage stage;
  final bool wilted;
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 112, size.height / 120);
    final paint = Paint()..color = color.withValues(alpha: wilted ? .45 : 1);
    const cx = 56.0;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cx - 22, 90, 44, 24),
        const Radius.circular(8),
      ),
      Paint()..color = const Color(0xFFCB9876),
    );
    if (stage == GrowthStage.seed) {
      canvas.drawOval(
        Rect.fromCenter(center: Offset(cx, 88), width: 12, height: 8),
        paint,
      );
      return;
    }
    final top = stage == GrowthStage.sprout
        ? 68.0
        : stage == GrowthStage.sapling
        ? 40.0
        : 24.0;
    paint
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(
      Path()
        ..moveTo(cx, 94)
        ..quadraticBezierTo(
          cx + (wilted ? 14 : 0),
          64,
          cx + (wilted ? 12 : 0),
          top,
        ),
      paint,
    );
    paint.style = PaintingStyle.fill;
    for (var i = 0; i < (stage == GrowthStage.sprout ? 1 : 3); i++) {
      final y = 80 - i * 15.0;
      canvas.drawOval(Rect.fromLTWH(cx - 26, y - 10, 26, 12), paint);
      canvas.drawOval(Rect.fromLTWH(cx, y - 16, 26, 12), paint);
    }
    if (stage == GrowthStage.bloom) {
      for (var i = 0; i < 6; i++) {
        final angle = i * math.pi / 3;
        canvas.drawCircle(
          Offset(cx + math.cos(angle) * 10, top + math.sin(angle) * 10),
          8,
          Paint()..color = color,
        );
      }
      canvas.drawCircle(
        Offset(cx, top),
        7,
        Paint()..color = const Color(0xFFF1CE6A),
      );
    }
  }

  @override
  bool shouldRepaint(_PlantPainter old) =>
      old.stage != stage || old.wilted != wilted || old.color != color;
}

class PlantDetailScreen extends ConsumerWidget {
  const PlantDetailScreen({super.key, required this.id});
  final String id;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tracker = ref.watch(trackerProvider(id)),
        state = ref.watch(plannerProvider);
    if (tracker == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('This habit has been removed.')),
      );
    }
    final now = ref.watch(tickProvider).value ?? ref.read(clockProvider).now();
    final growth = GrowthEngine.evaluate(
      (state.checkIns[id] ?? []).map(DateTime.parse),
      now,
      plantedAt: tracker.startedAt,
    );
    final progress = state.progress['$id:${dayKey(now)}'] ?? 0,
        goal = state.goals[id] ?? 1;
    return Scaffold(
      appBar: AppBar(title: Text(tracker.name)),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Center(
            child: PlantIllustration(
              stage: growth.stage,
              wilted: growth.wilted,
              color: habitColor(context, state, tracker),
            ),
          ),
          Text(
            '${growth.stage.name} · ${growth.streak} day streak',
            textAlign: TextAlign.center,
          ),
          if (growth.wilted)
            Text(
              '${growth.recovery}/3 consecutive check-ins toward recovery',
              textAlign: TextAlign.center,
            ),
          const SizedBox(height: 24),
          Center(
            child: HabitCircle(
              label: 'Long press to water',
              color: habitColor(context, state, tracker),
              progress: (progress / goal).clamp(0, 1),
              emoji: tracker.emoji,
              onCheckIn: () => waterHabit(context, ref, tracker),
            ),
          ),
          const SizedBox(height: 24),
          Text('$progress / $goal today'),
          LinearProgressIndicator(value: (progress / goal).clamp(0, 1)),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => waterHabit(context, ref, tracker),
            child: const Text('Add 1 to today’s goal'),
          ),
          Row(
            children: [
              const Expanded(child: Text('Track time for this habit')),
              TimerButton(type: SubjectType.habit, id: id),
            ],
          ),
          TextButton(
            onPressed: () => _goal(context, ref, goal),
            child: const Text('Set numeric daily goal'),
          ),
          TextButton(
            onPressed: () => _logAmount(context, ref, tracker),
            child: const Text('Log an amount'),
          ),
          Wrap(
            spacing: 8,
            children: [
              for (final color in AppColors.palette)
                ChoiceChip(
                  label: const Text('●'),
                  labelStyle: TextStyle(color: Color(color)),
                  selected: state.colors[id] == color,
                  onSelected: (_) => ref
                      .read(plannerProvider.notifier)
                      .setHabit(id, color: color),
                ),
            ],
          ),
          const SizedBox(height: 24),
          const Text('Your original counter & history'),
          CounterPage(id: id),
        ],
      ),
    );
  }

  Future<void> _goal(BuildContext context, WidgetRef ref, double goal) async {
    final controller = TextEditingController(text: goal.toString());
    final value = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Your daily target'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(hintText: 'For example, 30 pages'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.pop(context, double.tryParse(controller.text)),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (value != null && value.isFinite && value > 0) {
      await ref.read(plannerProvider.notifier).setHabit(id, goal: value);
    }
    await Future<void>.delayed(const Duration(milliseconds: 300));
    controller.dispose();
  }

  Future<void> _logAmount(
    BuildContext context,
    WidgetRef ref,
    Tracker tracker,
  ) async {
    final text = TextEditingController();
    final amount = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('A little progress'),
        content: TextField(
          controller: text,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Amount',
            hintText: 'For example, 10 pages',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, double.tryParse(text.text)),
            child: const Text('Add progress'),
          ),
        ],
      ),
    );
    if (amount != null && amount.isFinite && amount > 0 && context.mounted) {
      await waterHabit(context, ref, tracker, amount: amount);
    }
    await Future<void>.delayed(const Duration(milliseconds: 300));
    text.dispose();
  }
}

class _BloomCelebration extends StatelessWidget {
  const _BloomCelebration({required this.name, required this.stage});
  final String name;
  final GrowthStage stage;
  @override
  Widget build(BuildContext context) => Material(
    color: Theme.of(context).colorScheme.surface,
    child: SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: .9, end: 1.8),
                duration: MediaQuery.disableAnimationsOf(context)
                    ? Duration.zero
                    : const Duration(milliseconds: 700),
                curve: Curves.elasticOut,
                builder: (context, value, _) => Transform.scale(
                  scale: value,
                  child: PlantIllustration(
                    stage: stage,
                    wilted: false,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: 64),
              Text(
                '$name is growing!',
                style: Theme.of(context).textTheme.displaySmall,
                textAlign: TextAlign.center,
              ),
              Text('Hello, ${stage.name}.'),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Keep growing'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
