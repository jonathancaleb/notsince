import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:notsince/core/theme/app_type.dart';
import 'package:notsince/core/theme/sketch.dart';

class HabitCircle extends StatefulWidget {
  const HabitCircle({
    super.key,
    required this.label,
    required this.color,
    required this.progress,
    required this.onCheckIn,
    this.onTap,
    this.emoji = '🌱',
    this.child,
  });
  final String label;
  final Color color;
  final double progress;
  final Future<void> Function() onCheckIn;
  final VoidCallback? onTap;
  final String emoji;
  final Widget? child;
  @override
  State<HabitCircle> createState() => _HabitCircleState();
}

class _HabitCircleState extends State<HabitCircle>
    with SingleTickerProviderStateMixin {
  late final _animation = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
  );
  bool _busy = false;
  @override
  void didUpdateWidget(HabitCircle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.progress > oldWidget.progress &&
        !MediaQuery.disableAnimationsOf(context)) {
      _animation.forward(from: 0);
    }
  }

  Future<void> _check() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await widget.onCheckIn();
      if (!mounted) return;
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not save this check-in. Please try again.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
    label:
        '${widget.label}, ${(widget.progress * 100).round()} percent. Long press to check in.',
    button: true,
    onLongPress: _check,
    child: GestureDetector(
      onTap: widget.onTap,
      onLongPress: _check,
      child: SizedBox(
        width: 104,
        child: Column(
          children: [
            AnimatedBuilder(
                  animation: _animation,
                  builder: (context, _) {
                    final t = _animation.value;
                    return SizedBox(
                      width: 88,
                      height: 88,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // The ring draws itself in on first build, then
                          // eases to new values like a pencil catching up.
                          TweenAnimationBuilder<double>(
                            tween: Tween(
                              begin: 0,
                              end: widget.progress.clamp(0.0, 1.0),
                            ),
                            duration: MediaQuery.disableAnimationsOf(context)
                                ? Duration.zero
                                : const Duration(milliseconds: 700),
                            curve: Curves.easeOutCubic,
                            builder: (context, value, _) => CustomPaint(
                              size: const Size(88, 88),
                              painter: SketchRingPainter(
                                progress: value,
                                color: widget.color,
                                ink: Theme.of(context).colorScheme.onSurface,
                                seed: widget.label.hashCode,
                              ),
                            ),
                          ),
                          widget.child ??
                              Text(
                                widget.emoji,
                                style: AppType.glyph(32),
                              ),
                          if (t > 0 &&
                              t < 1 &&
                              !MediaQuery.disableAnimationsOf(context))
                            CustomPaint(
                              size: const Size(88, 88),
                              painter: _Sparkles(t, widget.color),
                            ),
                        ],
                      ),
                    );
                  },
                )
                .animate(controller: _animation, autoPlay: false)
                .custom(
                  duration: const Duration(milliseconds: 320),
                  builder: (context, value, child) => Transform.scale(
                    scale: MediaQuery.disableAnimationsOf(context)
                        ? 1
                        : 1 + .09 * math.sin(value * math.pi),
                    child: child,
                  ),
                ),
            const SizedBox(height: 12),
            Text(
              widget.label,
              maxLines: 2,
              style: AppType.cardSmall,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    ),
  );
}

/// A hand-drawn progress ring: a faint pencil circle for the track and a
/// thick crayon stroke for the progress, both wobbling on a fixed seed.
class SketchRingPainter extends CustomPainter {
  const SketchRingPainter({
    required this.progress,
    required this.color,
    required this.ink,
    required this.seed,
    this.width = 5,
  });

  final double progress;
  final Color color;
  final Color ink;
  final int seed;
  final double width;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2 - width / 2 - 1;
    Sketch.pen(
      canvas,
      (s) => Sketch.circle(c, r, seed: s, wobble: .9, overshoot: 12),
      seed: seed,
      color: Sketch.inkShade(ink),
      width: 1.3,
    );
    if (progress <= 0) return;
    final arc = Sketch.circle(
      c,
      r,
      seed: seed + 5,
      wobble: 1.1,
      sweep: math.pi * 2 * progress,
    );
    canvas.drawPath(
      arc,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = width,
    );
  }

  @override
  bool shouldRepaint(SketchRingPainter old) =>
      old.progress != progress ||
      old.color != color ||
      old.ink != ink ||
      old.seed != seed ||
      old.width != width;
}

/// Doodle sparkles: little four-point pen stars that fly out and fade.
class _Sparkles extends CustomPainter {
  _Sparkles(this.t, this.color);
  final double t;
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 1 - t)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 6; i++) {
      final angle = i * math.pi / 3 + .4;
      final radius = 30 + t * 22;
      final at = Offset(
        size.width / 2 + math.cos(angle) * radius,
        size.height / 2 + math.sin(angle) * radius,
      );
      final arm = 5 * (1 - t * .6) * (i.isEven ? 1 : .7);
      canvas.drawLine(at - Offset(arm, 0), at + Offset(arm, 0), paint);
      canvas.drawLine(at - Offset(0, arm), at + Offset(0, arm), paint);
    }
  }

  @override
  bool shouldRepaint(_Sparkles oldDelegate) =>
      oldDelegate.t != t || oldDelegate.color != color;
}
