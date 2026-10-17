import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:notsince/core/theme/ns_colors.dart';

/// A plant that gains a stage each time a milestone is passed.
///
/// Drawn rather than illustrated, from the same ink outline and flat fills as
/// every other shape in the app, so it belongs to the interface instead of
/// sitting in it as artwork.
///
/// It never wilts, browns or dies. A reset replants: the pot goes back to a
/// seed and starts again, because a plant that visibly punishes you for
/// slipping is exactly the streak pressure this app refuses.
class HabitPlant extends StatelessWidget {
  const HabitPlant({
    super.key,
    required this.stage,
    required this.color,
    this.size = const Size(120, 132),
  });

  /// 0 (seed) to [stageCount] - 1 (flower).
  final int stage;
  final Color color;
  final Size size;

  /// Seed, sprout, first leaves, second pair, third pair, bud, flower.
  static const int stageCount = 7;

  /// Maps milestones passed onto drawing stages.
  ///
  /// Scaled rather than counted one-for-one, so the plant reaches full flower
  /// on the *last* milestone whether a habit has three thresholds or ten.
  static int stageFor({required int passed, required int total}) {
    if (total <= 0) return passed > 0 ? stageCount - 1 : 0;
    final scaled = (passed / total) * (stageCount - 1);
    return scaled.round().clamp(0, stageCount - 1);
  }

  @override
  Widget build(BuildContext context) {
    final ns = context.ns;
    return SizedBox(
      width: size.width,
      height: size.height,
      // A single short grow when the stage changes — nothing loops, and it
      // settles rather than bouncing.
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: stage.toDouble()),
        duration: const Duration(milliseconds: 650),
        curve: Curves.easeOutCubic,
        builder: (context, value, _) => RepaintBoundary(
          // The growth tween repaints this layer ~40 times; the boundary keeps
          // it from repainting the cards and nav around it.
          child: CustomPaint(
            painter: _PlantPainter(
              growth: value,
              color: color,
              ink: ns.ink,
              pot: ns.tint,
              paper: ns.paper,
            ),
            size: size,
          ),
        ),
      ),
    );
  }
}

class _PlantPainter extends CustomPainter {
  _PlantPainter({
    required this.growth,
    required this.color,
    required this.ink,
    required this.pot,
    required this.paper,
  });

  /// Continuous position between stages, so growth animates smoothly.
  final double growth;
  final Color color;
  final Color ink;
  final Color pot;
  final Color paper;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final potTop = size.height * 0.68;
    final centre = size.width / 2;

    _paintPot(canvas, size, potTop, centre, stroke);

    // Stem height ramps across the whole sequence; leaves, bud and flower
    // appear at their own points along it.
    final t = (growth / (HabitPlant.stageCount - 1)).clamp(0.0, 1.0);
    final stemTop = potTop - (potTop - size.height * 0.12) * t;

    if (growth < 0.5) {
      _paintSeed(canvas, potTop, centre, stroke);
      return;
    }

    canvas.drawLine(Offset(centre, potTop), Offset(centre, stemTop), stroke);

    // Leaf pairs arrive at stages 1, 2, 3 and 4.
    for (var pair = 0; pair < 4; pair++) {
      final appearsAt = 1.0 + pair;
      final grown = ((growth - appearsAt) + 1).clamp(0.0, 1.0);
      if (grown <= 0) continue;

      final along = 0.30 + pair * 0.18;
      final y = potTop - (potTop - stemTop) * along;
      _paintLeaf(canvas, Offset(centre, y), grown, left: pair.isEven, stroke: stroke);
      _paintLeaf(canvas, Offset(centre, y), grown, left: !pair.isEven, stroke: stroke);
    }

    final budGrown = (growth - 5 + 1).clamp(0.0, 1.0);
    final flowerGrown = (growth - 6 + 1).clamp(0.0, 1.0);

    if (flowerGrown > 0) {
      _paintFlower(canvas, Offset(centre, stemTop), flowerGrown, stroke);
    } else if (budGrown > 0) {
      _paintBud(canvas, Offset(centre, stemTop), budGrown, stroke);
    }
  }

  void _paintPot(
      Canvas canvas, Size size, double potTop, double centre, Paint stroke) {
    final halfTop = size.width * 0.30;
    final halfBottom = size.width * 0.22;
    final bottom = size.height * 0.96;

    final shape = Path()
      ..moveTo(centre - halfTop, potTop)
      ..lineTo(centre + halfTop, potTop)
      ..lineTo(centre + halfBottom, bottom)
      ..lineTo(centre - halfBottom, bottom)
      ..close();

    canvas.drawPath(shape, Paint()..color = pot);
    canvas.drawPath(shape, stroke);

    // Soil line, so the plant reads as growing out of something.
    final rim = potTop + size.height * 0.07;
    final soil = Path()
      ..moveTo(centre - halfTop * 0.94, rim)
      ..lineTo(centre + halfTop * 0.94, rim);
    canvas.drawPath(soil, stroke);
  }

  void _paintSeed(Canvas canvas, double potTop, double centre, Paint stroke) {
    final seed = Offset(centre, potTop + 14);
    canvas.drawCircle(seed, 5, Paint()..color = color);
    canvas.drawCircle(seed, 5, stroke);
  }

  void _paintLeaf(Canvas canvas, Offset base, double grown,
      {required bool left, required Paint stroke}) {
    final dir = left ? -1.0 : 1.0;
    final length = 26.0 * grown;
    final tip = base + Offset(dir * length, -length * 0.55);

    final leaf = Path()
      ..moveTo(base.dx, base.dy)
      ..quadraticBezierTo(
          base.dx + dir * length * 0.35, base.dy - length * 0.85, tip.dx, tip.dy)
      ..quadraticBezierTo(
          base.dx + dir * length * 0.80, base.dy - length * 0.05, base.dx, base.dy)
      ..close();

    canvas.drawPath(leaf, Paint()..color = color);
    canvas.drawPath(leaf, stroke);
  }

  void _paintBud(Canvas canvas, Offset top, double grown, Paint stroke) {
    final r = 7.0 * grown;
    final centre = top + Offset(0, -r * 0.6);
    canvas.drawCircle(centre, r, Paint()..color = color);
    canvas.drawCircle(centre, r, stroke);
  }

  void _paintFlower(Canvas canvas, Offset top, double grown, Paint stroke) {
    final centre = top + Offset(0, -9);
    final petal = 11.0 * grown;

    for (var i = 0; i < 6; i++) {
      final angle = (i / 6) * 2 * math.pi;
      final at = centre +
          Offset(petal * 0.95 * math.cos(angle), petal * 0.95 * math.sin(angle));
      canvas.drawCircle(at, petal * 0.55, Paint()..color = color);
      canvas.drawCircle(at, petal * 0.55, stroke);
    }

    canvas.drawCircle(centre, petal * 0.5, Paint()..color = paper);
    canvas.drawCircle(centre, petal * 0.5, stroke);
  }

  @override
  bool shouldRepaint(_PlantPainter old) =>
      old.growth != growth || old.color != color || old.ink != ink;
}
