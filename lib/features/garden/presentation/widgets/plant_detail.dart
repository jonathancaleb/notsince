part of '../garden_screen.dart';

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
    // Pops in with a small overshoot and a one-off wobble, like a doodle
    // being stuck onto the page. Nothing loops.
    child: TweenAnimationBuilder<double>(
      key: ValueKey(stage),
      tween: Tween(begin: 0, end: 1),
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 520),
      curve: Curves.easeOutBack,
      builder: (context, value, child) => Transform.rotate(
        angle: math.sin(value * math.pi * 2) * .035 * (1 - value),
        alignment: Alignment.bottomCenter,
        child: Transform.scale(
          scale: .92 + .08 * value,
          alignment: Alignment.bottomCenter,
          child: child,
        ),
      ),
      child: RepaintBoundary(
        child: CustomPaint(
          size: const Size(112, 120),
          painter: _PlantPainter(stage, wilted, color, context.ns.ink),
        ),
      ),
    ),
  );
}

/// The garden plant as a pen doodle: every shape is a flat crayon fill with a
/// wobbling ink outline over it, the pot is shaded with pencil hatching, and
/// the seeds are fixed so a plant is always drawn the same way.
class _PlantPainter extends CustomPainter {
  _PlantPainter(this.stage, this.wilted, this.color, this.ink);
  final GrowthStage stage;
  final bool wilted;
  final Color color;
  final Color ink;

  static const _cx = 56.0;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 112, size.height / 120);
    final leaf = color.withValues(alpha: wilted ? .45 : 1);
    final line = Sketch.inkLine(ink);
    final pen = Paint()
      ..color = line
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    _ground(canvas, pen);

    final top = switch (stage) {
      GrowthStage.seed => 88.0,
      GrowthStage.sprout => 66.0,
      GrowthStage.sapling => 40.0,
      _ => 26.0,
    };

    if (stage == GrowthStage.seed) {
      final seed = Path()
        ..addOval(
          Rect.fromCenter(center: const Offset(_cx, 87), width: 13, height: 9),
        );
      canvas.drawPath(seed, Paint()..color = leaf);
      canvas.drawPath(seed, pen);
      // A tiny sprouting tick, the promise of something.
      canvas.drawPath(
        Sketch.line(const Offset(_cx + 2, 82), const Offset(_cx + 5, 77),
            seed: 3, wobble: .3),
        pen,
      );
    } else {
      final lean = wilted ? 12.0 : 0.0;
      final stem = Path()
        ..moveTo(_cx, 92)
        ..quadraticBezierTo(_cx + lean + 3, 64, _cx + lean, top);
      canvas.drawPath(
        stem,
        Paint()
          ..color = leaf
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4
          ..strokeCap = StrokeCap.round,
      );
      canvas.drawPath(stem, pen..strokeWidth = 1.2);
      pen.strokeWidth = 1.6;

      final pairs = stage == GrowthStage.sprout ? 1 : 3;
      for (var i = 0; i < pairs; i++) {
        final y = 82 - i * 16.0;
        final x = _cx + lean * (1 - (y - top) / (92 - top));
        final droop = wilted ? 6.0 : 0.0;
        _leaf(canvas, Offset(x, y), -1, 22 - i * 2.0, droop, leaf, pen, i * 2);
        _leaf(canvas, Offset(x, y - 6), 1, 22 - i * 2.0, droop, leaf, pen,
            i * 2 + 1);
      }

      if (stage == GrowthStage.bloom) _bloom(canvas, Offset(_cx + lean, top), pen);
    }

    _pot(canvas, pen);
  }

  void _ground(Canvas canvas, Paint pen) {
    // A few grass ticks either side of the pot, so it sits on something.
    final grass = Paint()
      ..color = Sketch.inkShade(ink)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3
      ..strokeCap = StrokeCap.round;
    for (final (x, h, d) in const [
      (22.0, 7.0, -2.0),
      (27.0, 10.0, 1.0),
      (86.0, 9.0, -1.0),
      (91.0, 6.0, 2.0),
    ]) {
      canvas.drawLine(Offset(x, 114), Offset(x + d, 114 - h), grass);
    }
    canvas.drawPath(
      Sketch.line(const Offset(14, 115), const Offset(98, 114),
          seed: 21, wobble: .8),
      grass,
    );
  }

  void _pot(Canvas canvas, Paint pen) {
    final body = Path()
      ..moveTo(_cx - 20, 96)
      ..lineTo(_cx + 20, 96)
      ..lineTo(_cx + 16, 114)
      ..quadraticBezierTo(_cx, 116, _cx - 16, 114)
      ..close();
    canvas.drawPath(body, Paint()..color = AppColors.pot);
    // Shade the right-hand side, as if lit from the top left.
    canvas.save();
    canvas.clipRect(const Rect.fromLTWH(_cx + 6, 90, 30, 30));
    Sketch.hatch(canvas, body, color: Sketch.inkShade(ink), gap: 3.5);
    canvas.restore();
    canvas.drawPath(body, pen);

    final rim = Sketch.rrect(
      const Rect.fromLTWH(_cx - 24, 89, 48, 9),
      4,
      seed: 77,
      wobble: .5,
    );
    canvas.drawPath(rim, Paint()..color = AppColors.pot);
    canvas.drawPath(
      Sketch.rrect(const Rect.fromLTWH(_cx - 24, 89, 48, 9), 4,
          seed: 77, wobble: .5, overshoot: 5),
      pen,
    );
  }

  void _leaf(
    Canvas canvas,
    Offset base,
    double dir,
    double length,
    double droop,
    Color fill,
    Paint pen,
    int seed,
  ) {
    final tip = base + Offset(dir * length, -length * .45 + droop);
    final shape = Path()
      ..moveTo(base.dx, base.dy)
      ..quadraticBezierTo(
        base.dx + dir * length * .35,
        base.dy - length * .75 + droop,
        tip.dx,
        tip.dy,
      )
      ..quadraticBezierTo(
        base.dx + dir * length * .75,
        base.dy + length * .05 + droop,
        base.dx,
        base.dy,
      )
      ..close();
    canvas.drawPath(shape, Paint()..color = fill);
    canvas.drawPath(shape, pen);
    // The vein, stopping short of the tip like a quick stroke would.
    canvas.drawPath(
      Sketch.line(base, Offset.lerp(base, tip, .7)!, seed: seed, wobble: .4),
      Paint()
        ..color = Sketch.inkLine(ink).withValues(alpha: .5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..strokeCap = StrokeCap.round,
    );
  }

  void _bloom(Canvas canvas, Offset at, Paint pen) {
    final petal = Paint()..color = color.withValues(alpha: wilted ? .45 : 1);
    for (var i = 0; i < 6; i++) {
      final angle = i * math.pi / 3;
      final c = at + Offset(math.cos(angle) * 10, math.sin(angle) * 10);
      final p = Sketch.circle(c, 7.5, seed: 40 + i, wobble: .5);
      canvas.drawPath(p, petal);
      canvas.drawPath(p, pen);
    }
    final centre = Sketch.circle(at, 6.5, seed: 50, wobble: .4);
    canvas.drawPath(centre, Paint()..color = AppColors.bloom);
    canvas.drawPath(centre, pen);
  }

  @override
  bool shouldRepaint(_PlantPainter old) =>
      old.stage != stage ||
      old.wilted != wilted ||
      old.color != color ||
      old.ink != ink;
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
        padding: const EdgeInsets.all(AppSpacing.md),
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
          const SizedBox(height: AppSpacing.md),
          Center(
            child: HabitCircle(
              label: 'Long press to water',
              color: habitColor(context, state, tracker),
              progress: (progress / goal).clamp(0, 1),
              emoji: tracker.emoji,
              onCheckIn: () => waterHabit(context, ref, tracker),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text('$progress / $goal today'),
          LinearProgressIndicator(value: (progress / goal).clamp(0, 1)),
          const SizedBox(height: AppSpacing.sm),
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
          const SizedBox(height: AppSpacing.md),
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
          padding: const EdgeInsets.all(AppSpacing.lg),
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
              const SizedBox(height: AppSpacing.md),
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
