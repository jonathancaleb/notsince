import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

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
                          SizedBox.expand(
                            child: CircularProgressIndicator(
                              value: widget.progress.clamp(0, 1),
                              strokeWidth: 5,
                              backgroundColor: widget.color.withValues(
                                alpha: .12,
                              ),
                              color: widget.color,
                            ),
                          ),
                          widget.child ??
                              Text(
                                widget.emoji,
                                style: const TextStyle(fontSize: 32),
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
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    ),
  );
}

class _Sparkles extends CustomPainter {
  _Sparkles(this.t, this.color);
  final double t;
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color.withValues(alpha: 1 - t);
    for (var i = 0; i < 10; i++) {
      final angle = i * math.pi / 5;
      final radius = 28 + t * 24;
      canvas.drawCircle(
        Offset(
          size.width / 2 + math.cos(angle) * radius,
          size.height / 2 + math.sin(angle) * radius,
        ),
        3 * (1 - t),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_Sparkles oldDelegate) =>
      oldDelegate.t != t || oldDelegate.color != color;
}
