import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notsince/core/prefs/app_prefs.dart';
import 'package:notsince/core/theme/app_colors.dart';
import 'package:notsince/core/theme/app_type.dart';
import 'package:notsince/core/theme/ns_colors.dart';
import 'package:notsince/core/theme/sketch.dart';
import 'package:notsince/core/widgets/doodle_icon.dart';
import 'package:notsince/core/widgets/sticker_button.dart';
import 'package:notsince/core/widgets/wordmark.dart';
import 'package:notsince/features/garden/growth_engine.dart';
import 'package:notsince/features/garden/presentation/garden_screen.dart';
import 'package:notsince/features/planner/data/planner_store.dart';

/// Three pages of a sketchbook and a fourth where you pick your crayon.
///
/// Everything on it is drawn the way the rest of the app is: the name is the
/// logo, the copy is handwritten, the plant grows a stage per page, and the
/// dots, swatches and button are pen outlines rather than Material shapes.
class WarmOnboardingScreen extends ConsumerStatefulWidget {
  const WarmOnboardingScreen({super.key, required this.onDone});
  final VoidCallback onDone;
  @override
  ConsumerState<WarmOnboardingScreen> createState() =>
      _WarmOnboardingScreenState();
}

class _WarmOnboardingScreenState extends ConsumerState<WarmOnboardingScreen> {
  int _page = 0;
  late int _color = ref.read(plannerProvider).accent;
  bool _saving = false;
  static const _slides = [
    (
      'Small beginnings.\nBeautiful growth.',
      'Keep your commitments, care for a habit, and let small daily steps take root.',
    ),
    (
      'A day with\nroom to breathe.',
      'Plan tasks, give projects a little focus, and see where your time went.',
    ),
    (
      'Your thoughts.\nYour own little world.',
      'Write a journal and gather your notes. Everything stays on this device. Rest days never erase your growth.',
    ),
  ];

  bool get _picking => _page == 3;

  Future<void> _next() async {
    if (!_picking) {
      setState(() => _page++);
      return;
    }
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await ref.read(plannerProvider.notifier).setAccent(_color);
      await ref.read(appPrefsProvider).setOnboarded();
      if (mounted) widget.onDone();
    } catch (_) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not save. Please try again.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ns = context.ns;
    final crayon = AppColors.lifted(_color, Theme.of(context).brightness);
    final instant = MediaQuery.disableAnimationsOf(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Row(
                children: [
                  const Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Wordmark(fontSize: 24),
                    ),
                  ),
                  if (!_picking)
                    TextButton(
                      onPressed: () => setState(() => _page = 3),
                      child: const Text('Skip intro'),
                    ),
                ],
              ),
              Expanded(
                child: AnimatedSwitcher(
                  duration: instant
                      ? Duration.zero
                      : const Duration(milliseconds: 280),
                  switchInCurve: Curves.easeOutCubic,
                  // A page turn, lightly: the new page drifts in from the
                  // right as it fades up, and the old one just fades.
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween(
                        begin: const Offset(.06, 0),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  ),
                  layoutBuilder: (current, previous) => Stack(
                    alignment: Alignment.topCenter,
                    children: [...previous, ?current],
                  ),
                  child: SingleChildScrollView(
                    key: ValueKey(_page),
                    child: _picking
                        ? _pickPage(ns, crayon)
                        : _slidePage(ns, crayon),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _Dots(count: 4, index: _page, color: crayon),
              const SizedBox(height: 18),
              StickerButton(
                color: crayon,
                foreground: crayon.computeLuminance() > .18
                    ? AppColors.ink
                    : AppColors.darkInk,
                onPressed: _saving ? null : _next,
                child: Text(_picking ? 'Plant my first habit' : 'Next'),
              ),
              const SizedBox(height: 6),
            ],
          ),
        ),
      ),
    );
  }

  Widget _slidePage(NsColors ns, Color crayon) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const SizedBox(height: 40),
      Center(
        child: Transform.scale(
          scale: 1.5,
          child: PlantIllustration(
            stage: GrowthStage.values[_page],
            wilted: false,
            color: crayon,
          ),
        ),
      ),
      const SizedBox(height: 56),
      Text(
        _slides[_page].$1,
        style: Theme.of(context).textTheme.displaySmall,
      ),
      const SizedBox(height: 14),
      Text(
        _slides[_page].$2,
        style: AppType.penBody.copyWith(color: ns.muted),
      ),
      const SizedBox(height: 24),
    ],
  );

  Widget _pickPage(NsColors ns, Color crayon) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const SizedBox(height: 16),
      Text(
        'Pick a color.\nPlant your first seed.',
        style: Theme.of(context).textTheme.displaySmall,
      ),
      const SizedBox(height: 14),
      Text(
        'A color for your first seed. Change it any time.',
        style: AppType.penBody.copyWith(color: ns.muted),
      ),
      const SizedBox(height: 24),
      Wrap(
        spacing: 14,
        runSpacing: 14,
        children: [
          for (final (i, color) in AppColors.palette.indexed)
            _Swatch(
              label: 'Accent ${i + 1}',
              color: Color(color),
              selected: _color == color,
              seed: 300 + i,
              onTap: () => setState(() => _color = color),
            ),
        ],
      ),
      const SizedBox(height: 28),
      // What the choice is for: the plant, fully grown, in that crayon.
      Center(
        child: PlantIllustration(
          stage: GrowthStage.bloom,
          wilted: false,
          color: crayon,
        ),
      ),
      const SizedBox(height: 16),
    ],
  );
}

/// One crayon to pick: a filled, hand-drawn circle, ringed when chosen.
class _Swatch extends StatelessWidget {
  const _Swatch({
    required this.label,
    required this.color,
    required this.selected,
    required this.seed,
    required this.onTap,
  });

  final String label;
  final Color color;
  final bool selected;
  final int seed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ns = context.ns;
    final instant = MediaQuery.disableAnimationsOf(context);
    return Semantics(
      label: label,
      selected: selected,
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: TweenAnimationBuilder<double>(
          tween: Tween(end: selected ? 1 : 0),
          duration: instant ? Duration.zero : const Duration(milliseconds: 260),
          curve: Curves.easeOutBack,
          builder: (context, t, child) => CustomPaint(
            painter: _SwatchPainter(color: color, ink: ns.ink, t: t, seed: seed),
            child: SizedBox.square(
              dimension: 56,
              child: Opacity(
                opacity: t.clamp(0, 1),
                child: Transform.scale(scale: .6 + .4 * t, child: child),
              ),
            ),
          ),
          child: Center(
            child: DoodleIcon(
              Icons.check_rounded,
              size: 24,
              color: color.computeLuminance() > .18
                  ? AppColors.ink
                  : AppColors.darkInk,
            ),
          ),
        ),
      ),
    );
  }
}

class _SwatchPainter extends CustomPainter {
  _SwatchPainter({
    required this.color,
    required this.ink,
    required this.t,
    required this.seed,
  });

  final Color color, ink;
  final double t;
  final int seed;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2 - 6 + 1.5 * t;
    canvas.drawPath(
      Sketch.circle(c, r, seed: seed, wobble: .9),
      Paint()..color = color,
    );
    Sketch.pen(
      canvas,
      (s) => Sketch.circle(c, r, seed: s, wobble: .9, overshoot: 7),
      seed: seed,
      color: Sketch.inkLine(ink),
      width: Sketch.stroke,
    );
    if (t > 0) {
      // The chosen one gets circled, the way you would on paper.
      final sweep = 6.6 * t.clamp(0.0, 1.0);
      Sketch.pen(
        canvas,
        (s) => Sketch.circle(c, r + 5, seed: s, wobble: 1.3, sweep: sweep),
        seed: seed + 40,
        color: Sketch.inkLine(ink),
        width: Sketch.thinStroke,
        secondPass: false,
      );
    }
  }

  @override
  bool shouldRepaint(_SwatchPainter old) =>
      old.color != color || old.ink != ink || old.t != t || old.seed != seed;
}

/// Page dots in pen: small rings, and a filled pill for the current page.
class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.index, required this.color});

  final int count, index;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final ns = context.ns;
    final instant = MediaQuery.disableAnimationsOf(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: AnimatedContainer(
              duration: instant
                  ? Duration.zero
                  : const Duration(milliseconds: 260),
              curve: Curves.easeOutBack,
              width: i == index ? 28 : 12,
              height: 12,
              child: CustomPaint(
                painter: SketchBoxPainter(
                  fill: i == index ? color : ns.paper,
                  ink: ns.ink,
                  radius: 6,
                  shadow: Offset.zero,
                  strokeWidth: Sketch.thinStroke,
                  seed: 900 + i,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
