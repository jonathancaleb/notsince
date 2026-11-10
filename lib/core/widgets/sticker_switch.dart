import 'package:flutter/material.dart';
import 'package:notsince/core/theme/ns_colors.dart';
import 'package:notsince/core/theme/sketch.dart';

/// A switch drawn in pen: a sketched track and a sketched knob. Material's has
/// a blurred thumb shadow and its own palette, both of which would be the only
/// ones on the page.
class StickerSwitch extends StatelessWidget {
  const StickerSwitch({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final ns = context.ns;
    final instant = MediaQuery.disableAnimationsOf(context);
    return Semantics(
      toggled: value,
      child: GestureDetector(
        onTap: () => onChanged(!value),
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: TweenAnimationBuilder<double>(
            tween: Tween(end: value ? 1 : 0),
            duration: instant ? Duration.zero : const Duration(milliseconds: 220),
            curve: Curves.easeOutBack,
            builder: (context, t, _) => CustomPaint(
              size: const Size(56, 32),
              painter: _SwitchPainter(
                t: t,
                on: Color.lerp(ns.paper, ns.accent, t.clamp(0, 1))!,
                paper: ns.paper,
                ink: ns.ink,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SwitchPainter extends CustomPainter {
  _SwitchPainter({
    required this.t,
    required this.on,
    required this.paper,
    required this.ink,
  });
  final double t;
  final Color on, paper, ink;

  @override
  void paint(Canvas canvas, Size size) {
    final track = (Offset.zero & size).deflate(1);
    const seed = 4242;
    canvas.drawPath(
      Sketch.rrect(track, 16, seed: seed, wobble: .7),
      Paint()..color = on,
    );
    Sketch.pen(
      canvas,
      (s) => Sketch.rrect(track, 16, seed: s, wobble: .7, overshoot: 6),
      seed: seed,
      color: Sketch.inkLine(ink),
      width: Sketch.thinStroke,
    );
    final x = 16 + (size.width - 32) * t;
    final knob = Offset(x, size.height / 2);
    canvas.drawPath(
      Sketch.circle(knob, 11, seed: seed + 1, wobble: .6),
      Paint()..color = paper,
    );
    Sketch.pen(
      canvas,
      (s) => Sketch.circle(knob, 11, seed: s, wobble: .6, overshoot: 5),
      seed: seed + 1,
      color: Sketch.inkLine(ink),
      width: Sketch.thinStroke,
      secondPass: false,
    );
  }

  @override
  bool shouldRepaint(_SwitchPainter old) =>
      old.t != t || old.on != on || old.paper != paper || old.ink != ink;
}
