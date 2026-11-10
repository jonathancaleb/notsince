import 'dart:math' as math;
import 'dart:ui' show PathMetric, lerpDouble;

import 'package:flutter/material.dart';
import 'package:notsince/core/theme/ns_colors.dart';

/// The sketchbook drawing layer: every outline in the app is drawn as if by a
/// pen, not stroked by a vector engine.
///
/// Three rules make it read as hand-drawn rather than as "broken":
///
/// * **Deterministic wobble.** Each shape takes a seed (by default derived
///   from its size), so a card is drawn the same way every frame. Lines that
///   re-randomise on rebuild look like a glitch, not a pen.
/// * **Low-frequency noise.** The line drifts a pixel or so over ~40px, the
///   way a hand does, rather than jittering every sample.
/// * **Two passes.** A second, fainter stroke on a different seed, plus an
///   overshoot where the line closes, is what a quick sketch actually looks
///   like.
abstract final class Sketch {
  /// Pen weight for full outlines.
  static const double stroke = 1.6;

  /// Pen weight for small shapes (chips, switches) so they are not heavier
  /// than the card around them.
  static const double thinStroke = 1.2;

  /// How far the line strays from the true shape, in logical pixels.
  static const double wobble = 1.1;

  /// Pitch of the dot grid on the page.
  static const double gridPitch = 22;

  /// A seed that stays stable for a given box size, so the same card in the
  /// same place is always drawn with the same hand.
  static int seedFor(Size size, [int salt = 0]) =>
      (size.width.round() * 73856093) ^
      (size.height.round() * 19349663) ^
      (salt * 83492791);

  /// A wobbly closed outline around [rect].
  ///
  /// [overshoot] extends the line past its start so the ends cross, like a
  /// pen that did not quite land where it began. Fills should pass 0.
  static Path rrect(
    Rect rect,
    double radius, {
    required int seed,
    double wobble = Sketch.wobble,
    double overshoot = 0,
    double grain = 1,
  }) {
    final r = math.min(radius, rect.shortestSide / 2);
    final base = Path()
      ..addRRect(RRect.fromRectAndRadius(rect, Radius.circular(r)));
    return wobbly(
      base,
      seed: seed,
      amount: wobble,
      overshoot: overshoot,
      grain: grain,
    );
  }

  /// A wobbly circle (or arc, with [sweep] < 2π) of [radius] around [center].
  static Path circle(
    Offset center,
    double radius, {
    required int seed,
    double wobble = Sketch.wobble,
    double start = -math.pi / 2,
    double sweep = math.pi * 2,
    double overshoot = 0,
    double grain = 1,
  }) {
    final rect = Rect.fromCircle(center: center, radius: radius);
    // A full circle is a closed contour, so it can overshoot its own start
    // the way a quickly drawn ring does; an arc is an open stroke.
    final full = sweep >= math.pi * 2 - 1e-6;
    final base = Path();
    if (full) {
      base.addOval(rect);
    } else {
      base.addArc(rect, start, sweep);
    }
    return wobbly(
      base,
      seed: seed,
      amount: wobble,
      overshoot: overshoot,
      closed: full,
      grain: grain,
    );
  }

  /// A single wobbly line between two points: underlines, ticks, dividers.
  static Path line(
    Offset a,
    Offset b, {
    required int seed,
    double wobble = Sketch.wobble,
    double grain = 1,
  }) {
    final base = Path()
      ..moveTo(a.dx, a.dy)
      ..lineTo(b.dx, b.dy);
    return wobbly(
      base,
      seed: seed,
      amount: wobble,
      closed: false,
      grain: grain,
    );
  }

  /// Resamples [base] and pushes each sample along its normal by smooth
  /// noise, then joins the samples with quadratic curves.
  ///
  /// [grain] scales the sampling and the noise wavelength together: 1 suits
  /// card-sized shapes in logical pixels; icons drawn in a 24-unit box use
  /// about 0.15 so a corner is still sampled finely enough to stay a corner.
  /// [closed] closes each contour; open paths (ticks, arrows) pass false.
  static Path wobbly(
    Path base, {
    required int seed,
    required double amount,
    double overshoot = 0,
    bool closed = true,
    double grain = 1,
  }) {
    final out = Path();
    final rng = _Rng(seed);
    for (final metric in base.computeMetrics()) {
      final pts = _samples(metric, rng, amount, overshoot, closed, grain);
      if (pts.isEmpty) continue;
      out.moveTo(pts.first.dx, pts.first.dy);
      for (var i = 1; i < pts.length - 1; i++) {
        final mid = Offset.lerp(pts[i], pts[i + 1], .5)!;
        out.quadraticBezierTo(pts[i].dx, pts[i].dy, mid.dx, mid.dy);
      }
      out.lineTo(pts.last.dx, pts.last.dy);
      if (closed && overshoot == 0) out.close();
    }
    return out;
  }

  static List<Offset> _samples(
    PathMetric metric,
    _Rng rng,
    double amount,
    double overshoot,
    bool closed,
    double grain,
  ) {
    final length = metric.length;
    if (length == 0) return const [];
    final step = 8.0 * grain;
    // Noise knots every ~40px, eased between, so the drift is slow.
    final knotEvery = 40.0 * grain;
    final total = length + (closed ? overshoot : 0);
    final count = math.max(2, (total / step).ceil());
    final knots = List.generate(
      (total / knotEvery).ceil() + 2,
      (_) => (rng.next() * 2 - 1) * amount,
    );
    if (closed && overshoot == 0) {
      // A closed fill must meet itself cleanly.
      knots[knots.length - 1] = knots[0];
    }
    final pts = <Offset>[];
    for (var i = 0; i <= count; i++) {
      final d = total * i / count;
      final along = closed ? d % length : d.clamp(0.0, length);
      final t = metric.getTangentForOffset(along);
      if (t == null) continue;
      final k = d / knotEvery;
      final k0 = k.floor().clamp(0, knots.length - 2);
      final f = k - k0;
      final eased = f * f * (3 - 2 * f);
      var n = knots[k0] + (knots[k0 + 1] - knots[k0]) * eased;
      if (closed && overshoot == 0 && i == count) n = knots[0];
      // Overshooting tails drift outward a little more, like a flick.
      if (d > length) n += (d - length) / math.max(overshoot, 1) * amount;
      final normal = Offset(-t.vector.dy, t.vector.dx);
      pts.add(t.position + normal * n);
    }
    return pts;
  }

  /// Strokes [build] twice — a firm pass and a faint second pass on another
  /// seed — which is most of what makes a line read as drawn.
  static void pen(
    Canvas canvas,
    Path Function(int seed) build, {
    required int seed,
    required Color color,
    double width = stroke,
    bool secondPass = true,
  }) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;
    canvas.drawPath(
      build(seed),
      paint
        ..color = color
        ..strokeWidth = width,
    );
    if (secondPass) {
      canvas.drawPath(
        build(seed + 7919),
        paint
          ..color = color.withValues(alpha: color.a * .35)
          ..strokeWidth = width * .6,
      );
    }
  }

  /// Pencil shading: diagonal strokes clipped to [shape].
  static void hatch(
    Canvas canvas,
    Path shape, {
    required Color color,
    double gap = 4.5,
    double width = 1,
  }) {
    final bounds = shape.getBounds();
    canvas.save();
    canvas.clipPath(shape);
    final paint = Paint()
      ..color = color
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round;
    final span = bounds.width + bounds.height;
    for (var x = -bounds.height; x < span; x += gap) {
      canvas.drawLine(
        Offset(bounds.left + x, bounds.bottom),
        Offset(bounds.left + x + bounds.height, bounds.top),
        paint,
      );
    }
    canvas.restore();
  }

  /// The ink strength for outlines. Light ink on a dark page is pulled back a
  /// touch so outlines don't glow.
  static Color inkLine(Color ink) =>
      ink.withValues(alpha: ink.computeLuminance() > .5 ? .72 : .85);

  /// The ink strength for hatched shadows.
  static Color inkShade(Color ink) =>
      ink.withValues(alpha: ink.computeLuminance() > .5 ? .22 : .28);
}

/// A small deterministic generator (xorshift32): `math.Random(seed)` would do,
/// but this keeps the sequence identical across platforms and SDK versions so
/// screenshots stay stable.
class _Rng {
  _Rng(int seed) : _s = (seed & 0x7fffffff) | 1;
  int _s;
  double next() {
    _s ^= (_s << 13) & 0xffffffff;
    _s ^= _s >> 17;
    _s ^= (_s << 5) & 0xffffffff;
    _s &= 0xffffffff;
    return _s / 0xffffffff;
  }
}

/// Paints a sketched box: a fill, a pencil-hatched drop shadow offset by
/// [shadow], and a double-pass pen outline.
class SketchBoxPainter extends CustomPainter {
  const SketchBoxPainter({
    required this.fill,
    required this.ink,
    this.radius = 24,
    this.shadow = const Offset(3, 4),
    this.strokeWidth = Sketch.stroke,
    this.seed,
    this.outline = true,
  });

  final Color fill;
  final Color ink;
  final double radius;
  final Offset shadow;
  final double strokeWidth;
  final bool outline;

  /// Defaults to [Sketch.seedFor] the painted size.
  final int? seed;

  @override
  void paint(Canvas canvas, Size size) {
    final s = seed ?? Sketch.seedFor(size);
    final rect = (Offset.zero & size).deflate(strokeWidth / 2);
    if (shadow != Offset.zero) {
      final shade = Sketch.rrect(rect.shift(shadow), radius, seed: s + 3);
      Sketch.hatch(canvas, shade, color: Sketch.inkShade(ink));
    }
    canvas.drawPath(
      Sketch.rrect(rect, radius, seed: s),
      Paint()..color = fill,
    );
    if (outline) {
      Sketch.pen(
        canvas,
        (seed) => Sketch.rrect(rect, radius, seed: seed, overshoot: 10),
        seed: s,
        color: Sketch.inkLine(ink),
        width: strokeWidth,
      );
    }
  }

  @override
  bool shouldRepaint(SketchBoxPainter old) =>
      old.fill != fill ||
      old.ink != ink ||
      old.radius != radius ||
      old.shadow != shadow ||
      old.strokeWidth != strokeWidth ||
      old.seed != seed ||
      old.outline != outline;
}

/// A child sitting on a sketched box. The sketch is the widget's whole
/// decoration; there is no Material elevation or blur anywhere under it.
class SketchBox extends StatelessWidget {
  const SketchBox({
    super.key,
    required this.child,
    required this.fill,
    this.padding = EdgeInsets.zero,
    this.radius = 24,
    this.shadow = const Offset(3, 4),
    this.strokeWidth = Sketch.stroke,
    this.seed,
  });

  final Widget child;
  final Color fill;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Offset shadow;
  final double strokeWidth;
  final int? seed;

  @override
  Widget build(BuildContext context) {
    final ink = Theme.of(context).colorScheme.onSurface;
    return RepaintBoundary(
      child: CustomPaint(
        painter: SketchBoxPainter(
          fill: fill,
          ink: ink,
          radius: radius,
          shadow: shadow,
          strokeWidth: strokeWidth,
          seed: seed,
        ),
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

/// The sketchbook page: paper colour with a faint dot grid.
class PaperPainter extends CustomPainter {
  const PaperPainter({required this.paper, required this.ink});
  final Color paper;
  final Color ink;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = paper);
    final dot = Paint()
      ..color = ink.withValues(alpha: ink.computeLuminance() > .5 ? .07 : .09);
    const p = Sketch.gridPitch;
    for (var y = p / 2; y < size.height; y += p) {
      for (var x = p / 2; x < size.width; x += p) {
        canvas.drawCircle(Offset(x, y), .9, dot);
      }
    }
  }

  @override
  bool shouldRepaint(PaperPainter old) => old.paper != paper || old.ink != ink;
}

/// Wraps [child] in the sketchbook page. Used by the theme's page transitions
/// so every route sits on paper while scaffolds stay transparent.
class Paper extends StatelessWidget {
  const Paper({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final ns = context.ns;
    return CustomPaint(
      painter: PaperPainter(paper: ns.paper, ink: ns.ink),
      isComplex: true,
      child: child,
    );
  }
}

/// A page-transition builder that puts each route on [Paper] and then hands
/// off to the platform's usual transition.
class PaperPageTransitionsBuilder extends PageTransitionsBuilder {
  const PaperPageTransitionsBuilder(this.inner);
  final PageTransitionsBuilder inner;

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => inner.buildTransitions(
    route,
    context,
    animation,
    secondaryAnimation,
    Paper(child: child),
  );
}

/// A pen underline that draws itself in from left to right — the sketchbook's
/// answer to an accent colour under a heading.
class ScribbleUnderline extends StatefulWidget {
  const ScribbleUnderline({
    super.key,
    required this.child,
    this.color,
    this.width = 3,
    this.gap = 6,
    this.delay = Duration.zero,
  });

  final Widget child;
  final Color? color;
  final double width;

  /// Room left between the child and the line.
  final double gap;
  final Duration delay;

  @override
  State<ScribbleUnderline> createState() => _ScribbleUnderlineState();
}

class _ScribbleUnderlineState extends State<ScribbleUnderline>
    with SingleTickerProviderStateMixin {
  late final _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 620),
  );
  late final _t = CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _c.value = 1;
    } else if (_c.value == 0 && !_c.isAnimating) {
      if (widget.delay == Duration.zero) {
        _c.forward();
      } else {
        Future.delayed(widget.delay, () {
          if (mounted) _c.forward();
        });
      }
    }
  }

  @override
  void dispose() {
    _t.dispose();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? Theme.of(context).colorScheme.primary;
    return CustomPaint(
      foregroundPainter: _UnderlinePainter(_t, color, widget.width),
      child: Padding(
        padding: EdgeInsets.only(bottom: widget.gap + widget.width * 2),
        child: widget.child,
      ),
    );
  }
}

class _UnderlinePainter extends CustomPainter {
  _UnderlinePainter(this.t, this.color, this.width) : super(repaint: t);
  final Animation<double> t;
  final Color color;
  final double width;

  @override
  void paint(Canvas canvas, Size size) {
    if (t.value == 0) return;
    final seed = Sketch.seedFor(size, 11);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // One confident stroke left to right, then a lighter one coming back
    // that stops short: how a word gets underlined by hand.
    void stroke(Offset a, Offset b, double from, double to, double alpha,
        double weight, int salt) {
      final p = ((t.value - from) / (to - from)).clamp(0.0, 1.0);
      if (p == 0) return;
      final path = Sketch.line(a, b, seed: seed + salt, wobble: 1.6);
      final metric = path.computeMetrics().first;
      canvas.drawPath(
        metric.extractPath(0, metric.length * p),
        paint
          ..color = color.withValues(alpha: alpha)
          ..strokeWidth = weight,
      );
    }

    final y = size.height - width * 1.6;
    stroke(Offset(-2, y), Offset(size.width + 4, y - 2), 0, .6, .9, width, 0);
    stroke(
      Offset(size.width + 2, y + width * .9),
      Offset(size.width * .2, y + width * 1.1),
      .55,
      1,
      .6,
      width * .7,
      1,
    );
  }

  @override
  bool shouldRepaint(_UnderlinePainter old) =>
      old.color != color || old.width != width;
}

/// A Material shape drawn in pen, so stock components — filled buttons,
/// chips, dialogs — take the sketch without being rebuilt by hand.
///
/// The seed comes from the shape's size, so a given button is always drawn
/// the same way; [side] supplies the ink colour and pen weight.
class SketchBorder extends OutlinedBorder {
  const SketchBorder({super.side, this.radius = 24});

  final double radius;

  Path _shape(Rect rect, {double overshoot = 0}) => Sketch.rrect(
    rect.deflate(side.width / 2),
    radius,
    seed: Sketch.seedFor(rect.size, 5),
    overshoot: overshoot,
  );

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.all(side.width);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) => _shape(rect);

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) => _shape(rect);

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    if (side.style == BorderStyle.none || side.width == 0) return;
    Sketch.pen(
      canvas,
      (seed) => Sketch.rrect(
        rect.deflate(side.width / 2),
        radius,
        seed: seed,
        overshoot: 8,
      ),
      seed: Sketch.seedFor(rect.size, 5),
      color: side.color,
      width: side.width,
    );
  }

  @override
  SketchBorder copyWith({BorderSide? side, double? radius}) =>
      SketchBorder(side: side ?? this.side, radius: radius ?? this.radius);

  @override
  ShapeBorder scale(double t) =>
      SketchBorder(side: side.scale(t), radius: radius * t);

  @override
  ShapeBorder? lerpFrom(ShapeBorder? a, double t) => a is SketchBorder
      ? SketchBorder(
          side: BorderSide.lerp(a.side, side, t),
          radius: lerpDouble(a.radius, radius, t)!,
        )
      : super.lerpFrom(a, t);

  @override
  ShapeBorder? lerpTo(ShapeBorder? b, double t) => b is SketchBorder
      ? SketchBorder(
          side: BorderSide.lerp(side, b.side, t),
          radius: lerpDouble(radius, b.radius, t)!,
        )
      : super.lerpTo(b, t);

  @override
  bool operator ==(Object other) =>
      other is SketchBorder && other.side == side && other.radius == radius;

  @override
  int get hashCode => Object.hash(side, radius);
}
