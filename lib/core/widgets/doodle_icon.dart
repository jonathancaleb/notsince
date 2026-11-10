import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:notsince/core/theme/app_colors.dart';
import 'package:notsince/core/theme/sketch.dart';

/// A hand-drawn stand-in for [Icon].
///
/// Takes the same [IconData] a call site would hand to [Icon] and draws the
/// sketchbook version of it in pen: wobbling strokes, a light crayon wash on
/// enclosed shapes, fixed seeds so an icon is drawn the same way every frame.
/// Size and colour come from the ambient [IconTheme] exactly as for [Icon],
/// so it drops into `IconButton`, `ListTile` and friends unchanged.
///
/// Glyphs without a drawing fall back to the Material icon, so adding a new
/// `Icons.*` somewhere never renders blank — it just renders un-sketched
/// until a drawing is added to [_drawings].
class DoodleIcon extends StatelessWidget {
  const DoodleIcon(
    this.icon, {
    super.key,
    this.size,
    this.color,
    this.semanticLabel,
  });

  final IconData? icon;
  final double? size;
  final Color? color;
  final String? semanticLabel;

  /// Whether [icon] has a hand-drawn version.
  static bool hasDrawing(IconData icon) => _drawings.containsKey(icon);

  @override
  Widget build(BuildContext context) {
    final data = icon;
    final draw = data == null ? null : _drawings[data];
    if (draw == null) {
      return Icon(
        data,
        size: size,
        color: color,
        semanticLabel: semanticLabel,
      );
    }
    final theme = IconTheme.of(context);
    final side = size ?? theme.size ?? 24;
    var ink = color ?? theme.color ?? AppColors.ink;
    if (theme.opacity != null && theme.opacity! < 1) {
      ink = ink.withValues(alpha: ink.a * theme.opacity!);
    }
    // Centred at its own size, as [Icon] does: a parent that hands down tight
    // constraints (a fixed nav cell, a list tile slot) must not stretch the
    // drawing to fill it.
    final glyph = Center(
      widthFactor: 1,
      heightFactor: 1,
      child: SizedBox.square(
        dimension: side,
        child: CustomPaint(
          painter: _DoodlePainter(draw, ink, data!.codePoint),
        ),
      ),
    );
    return Semantics(
      label: semanticLabel,
      excludeSemantics: semanticLabel == null,
      child: ExcludeSemantics(child: glyph),
    );
  }
}

typedef _Draw = void Function(_Pen pen);

class _DoodlePainter extends CustomPainter {
  const _DoodlePainter(this.draw, this.ink, this.seed);
  final _Draw draw;
  final Color ink;
  final int seed;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 24, size.height / 24);
    draw(_Pen(canvas, ink, seed));
    canvas.restore();
  }

  @override
  bool shouldRepaint(_DoodlePainter old) =>
      old.ink != ink || old.seed != seed || old.draw != draw;
}

/// A tiny drawing API in a 24-unit box. Every call takes the next seed in
/// sequence, so an icon's strokes are fixed but no two look stamped alike.
class _Pen {
  _Pen(this.canvas, this.ink, int seed) : _seed = seed * 31;

  final Canvas canvas;
  final Color ink;
  int _seed;

  static const double width = 1.9;
  static const double wobble = .38;
  static const double grain = .16;

  int get _next => _seed += 977;

  Paint get _stroke => Paint()
    ..color = ink
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  /// The crayon wash inside a closed shape: the pen colour, thinned out.
  Paint get _wash => Paint()..color = ink.withValues(alpha: ink.a * .22);

  Paint get _solid => Paint()..color = ink;

  void line(Offset a, Offset b, {double w = width}) => canvas.drawPath(
    Sketch.line(a, b, seed: _next, wobble: wobble, grain: grain),
    _stroke..strokeWidth = w,
  );

  /// An open polyline through [points].
  void poly(List<Offset> points, {bool close = false, Fill fill = Fill.none}) {
    final base = Path()..moveTo(points.first.dx, points.first.dy);
    for (final p in points.skip(1)) {
      base.lineTo(p.dx, p.dy);
    }
    if (close) base.close();
    shape(base, closed: close, fill: fill);
  }

  /// Any path, sketched. Closed shapes overshoot their start a touch.
  void shape(Path base, {bool closed = true, Fill fill = Fill.none}) {
    final s = _next;
    if (fill != Fill.none) {
      canvas.drawPath(
        Sketch.wobbly(base, seed: s, amount: wobble, grain: grain),
        fill == Fill.solid ? _solid : _wash,
      );
    }
    canvas.drawPath(
      Sketch.wobbly(
        base,
        seed: s,
        amount: wobble,
        closed: closed,
        overshoot: closed ? 1.6 : 0,
        grain: grain,
      ),
      _stroke,
    );
  }

  void circle(Offset c, double r, {Fill fill = Fill.none}) {
    final s = _next;
    if (fill != Fill.none) {
      canvas.drawPath(
        Sketch.circle(c, r, seed: s, wobble: wobble, grain: grain),
        fill == Fill.solid ? _solid : _wash,
      );
    }
    if (fill == Fill.solid && r < 2.2) return; // a dot, not a ring
    canvas.drawPath(
      Sketch.circle(
        c,
        r,
        seed: s,
        wobble: wobble,
        overshoot: 1.8,
        grain: grain,
      ),
      _stroke,
    );
  }

  void box(Rect r, double radius, {Fill fill = Fill.none}) => shape(
    Path()..addRRect(RRect.fromRectAndRadius(r, Radius.circular(radius))),
    fill: fill,
  );

  /// A four-point sparkle, the doodler's star.
  void sparkle(Offset c, double r, {Fill fill = Fill.wash}) {
    final p = Path()
      ..moveTo(c.dx, c.dy - r)
      ..quadraticBezierTo(c.dx + r * .18, c.dy - r * .18, c.dx + r, c.dy)
      ..quadraticBezierTo(c.dx + r * .18, c.dy + r * .18, c.dx, c.dy + r)
      ..quadraticBezierTo(c.dx - r * .18, c.dy + r * .18, c.dx - r, c.dy)
      ..quadraticBezierTo(c.dx - r * .18, c.dy - r * .18, c.dx, c.dy - r)
      ..close();
    shape(p, fill: fill);
  }

  void tick(Offset at, double scale) => poly([
    at + Offset(-5, .5) * scale,
    at + Offset(-1, 4.5) * scale,
    at + Offset(6, -4.5) * scale,
  ]);
}

enum Fill { none, wash, solid }

const _c = Offset(12, 12);

Offset _polar(Offset c, double r, double a) =>
    c + Offset(math.cos(a) * r, math.sin(a) * r);

void _sun(_Pen p) {
  p.circle(_c, 4.3, fill: Fill.wash);
  for (var i = 0; i < 8; i++) {
    final a = i * math.pi / 4;
    p.line(_polar(_c, 7.2, a), _polar(_c, 9.9, a));
  }
}

void _moon(_Pen p) {
  final outer = Path()..addOval(Rect.fromCircle(center: _c, radius: 8.4));
  final bite = Path()
    ..addOval(Rect.fromCircle(center: const Offset(16, 8.5), radius: 6.8));
  p.shape(Path.combine(PathOperation.difference, outer, bite), fill: Fill.wash);
  p.sparkle(const Offset(19, 16.5), 2.2, fill: Fill.solid);
}

void _phone(_Pen p) {
  p.box(const Rect.fromLTWH(6.5, 2.8, 11, 18.4), 2.6, fill: Fill.wash);
  p.line(const Offset(10.6, 17.6), const Offset(13.4, 17.6));
}

void _calendarFrame(_Pen p) {
  p.box(const Rect.fromLTWH(3.6, 5.4, 16.8, 15.2), 3, fill: Fill.wash);
  p.line(const Offset(3.8, 10), const Offset(20.2, 10));
  p.line(const Offset(8.4, 3.2), const Offset(8.4, 7.2));
  p.line(const Offset(15.6, 3.2), const Offset(15.6, 7.2));
}

void _calendarMonth(_Pen p) {
  _calendarFrame(p);
  for (final y in const [13.6, 17.2]) {
    for (final x in const [8.0, 12.0, 16.0]) {
      p.circle(Offset(x, y), .95, fill: Fill.solid);
    }
  }
}

void _calendarDay(_Pen p) {
  _calendarFrame(p);
  p.circle(const Offset(15.4, 15.6), 1.6, fill: Fill.solid);
}

void _calendarEdit(_Pen p) {
  _calendarFrame(p);
  p.tick(const Offset(12, 15.4), .62);
}

void _flower(_Pen p) {
  const c = Offset(12, 9.4);
  for (var i = 0; i < 5; i++) {
    p.circle(
      _polar(c, 4.3, -math.pi / 2 + i * 2 * math.pi / 5),
      2.9,
      fill: Fill.wash,
    );
  }
  p.circle(c, 1.9, fill: Fill.solid);
  p.line(const Offset(12, 15.2), const Offset(12.4, 21.4));
  p.shape(
    Path()
      ..moveTo(12.3, 19)
      ..quadraticBezierTo(15.5, 15.8, 18, 16.6)
      ..quadraticBezierTo(16.4, 19.8, 12.3, 19),
    fill: Fill.wash,
  );
}

void _note(_Pen p) {
  p.poly(
    const [
      Offset(4.6, 3.8),
      Offset(19.4, 3.8),
      Offset(19.4, 14.8),
      Offset(14.6, 20.2),
      Offset(4.6, 20.2),
    ],
    close: true,
    fill: Fill.wash,
  );
  p.poly(const [Offset(19.2, 14.8), Offset(14.6, 14.8), Offset(14.6, 20)]);
  p.line(const Offset(8, 8.8), const Offset(16, 8.8));
  p.line(const Offset(8, 12.4), const Offset(12.6, 12.4));
}

void _insights(_Pen p) {
  p.poly(const [
    Offset(3.4, 18.6),
    Offset(8.6, 12.4),
    Offset(12.6, 15.6),
    Offset(19.8, 8.2),
  ]);
  p.sparkle(const Offset(16.4, 4.4), 2.6);
  p.circle(const Offset(21, 13.4), 1, fill: Fill.solid);
}

void _sparkles(_Pen p) {
  p.sparkle(const Offset(10, 13.4), 7);
  p.sparkle(const Offset(18.6, 5.2), 3.1);
  p.circle(const Offset(19.2, 18), 1.1, fill: Fill.solid);
}

void _add(_Pen p) {
  p.line(const Offset(12, 4.6), const Offset(12, 19.4));
  p.line(const Offset(4.6, 12), const Offset(19.4, 12));
}

void _close(_Pen p) {
  p.line(const Offset(6, 6), const Offset(18, 18));
  p.line(const Offset(18, 6), const Offset(6, 18));
}

void _check(_Pen p) => p.tick(_c, 1.2);

void _chevronRight(_Pen p) =>
    p.poly(const [Offset(9.2, 5.6), Offset(15.6, 12), Offset(9.2, 18.4)]);

void _arrowForward(_Pen p) {
  p.line(const Offset(4.4, 12), const Offset(19, 12.2));
  p.poly(const [Offset(13.2, 6.2), Offset(19.2, 12.2), Offset(13.2, 18)]);
}

void _arrowBack(_Pen p) {
  p.line(const Offset(19.6, 12), const Offset(5, 12.2));
  p.poly(const [Offset(10.8, 6.2), Offset(4.8, 12.2), Offset(10.8, 18)]);
}

void _gear(_Pen p) {
  for (var i = 0; i < 8; i++) {
    final a = i * math.pi / 4 + math.pi / 8;
    p.line(_polar(_c, 6.4, a), _polar(_c, 9.2, a), w: 2.8);
  }
  p.circle(_c, 6.3, fill: Fill.wash);
  p.circle(_c, 2.4);
}

void _tune(_Pen p) {
  for (final (y, x) in const [(6.6, 15.2), (12.0, 8.6), (17.4, 13.4)]) {
    p.line(Offset(3.6, y), Offset(x - 2.6, y));
    p.line(Offset(x + 2.6, y), Offset(20.4, y));
    p.circle(Offset(x, y), 2.2, fill: Fill.wash);
  }
}

void _more(_Pen p) {
  for (final x in const [5.6, 12.0, 18.4]) {
    p.circle(Offset(x, 12.2), 1.75, fill: Fill.solid);
  }
}

void _drag(_Pen p) {
  p.line(const Offset(5, 9.4), const Offset(19, 9.4));
  p.line(const Offset(5, 14.6), const Offset(19, 14.6));
}

void _lock(_Pen p) {
  p.shape(
    Path()
      ..moveTo(8, 11)
      ..lineTo(8, 8)
      ..arcToPoint(const Offset(16, 8), radius: const Radius.circular(4))
      ..lineTo(16, 11),
    closed: false,
  );
  p.box(const Rect.fromLTWH(5.2, 10.8, 13.6, 10.2), 2.6, fill: Fill.wash);
  p.line(const Offset(12, 14.6), const Offset(12, 17.2));
}

void _link(_Pen p) {
  for (final c in const [Offset(8.6, 15.4), Offset(15.4, 8.6)]) {
    final m = Matrix4.identity()
      ..translateByDouble(c.dx, c.dy, 0, 1)
      ..rotateZ(-math.pi / 4)
      ..translateByDouble(-c.dx, -c.dy, 0, 1);
    p.shape(
      (Path()..addRRect(
            RRect.fromRectAndRadius(
              Rect.fromCenter(center: c, width: 10.4, height: 6),
              const Radius.circular(3),
            ),
          ))
          .transform(m.storage),
    );
  }
}

void _archive(_Pen p) {
  p.box(const Rect.fromLTWH(3.2, 4, 17.6, 5.2), 1.6, fill: Fill.wash);
  p.poly(const [
    Offset(5, 9.4),
    Offset(5.4, 20.2),
    Offset(18.6, 20.2),
    Offset(19, 9.4),
  ]);
  p.line(const Offset(10, 13.2), const Offset(14, 13.2));
}

Path _folderPath() => Path()
  ..moveTo(3.4, 6.2)
  ..lineTo(9.2, 6.2)
  ..lineTo(11.2, 8.4)
  ..lineTo(20.6, 8.4)
  ..lineTo(20.6, 19.2)
  ..lineTo(3.4, 19.2)
  ..close();

void _folder(_Pen p) => p.shape(_folderPath(), fill: Fill.wash);

void _folderAdd(_Pen p) {
  p.shape(_folderPath(), fill: Fill.wash);
  p.line(const Offset(12, 11), const Offset(12, 16.6));
  p.line(const Offset(9.2, 13.8), const Offset(14.8, 13.8));
}

void _pencil(_Pen p) {
  p.poly(
    const [
      Offset(4.6, 19.4),
      Offset(5.8, 15),
      Offset(15.8, 5),
      Offset(19, 8.2),
      Offset(9, 18.2),
    ],
    close: true,
    fill: Fill.wash,
  );
  p.line(const Offset(5.9, 15.1), const Offset(8.9, 18.1));
  p.line(const Offset(13.8, 7), const Offset(17, 10.2));
}

void _eye(_Pen p) {
  p.shape(
    Path()
      ..moveTo(2.8, 12)
      ..quadraticBezierTo(12, 3.4, 21.2, 12)
      ..quadraticBezierTo(12, 20.6, 2.8, 12)
      ..close(),
  );
  p.circle(_c, 3.2, fill: Fill.wash);
  p.circle(_c, 1.3, fill: Fill.solid);
}

void _trash(_Pen p) {
  p.line(const Offset(4.2, 6.6), const Offset(19.8, 6.4));
  p.poly(const [
    Offset(9.4, 6.4),
    Offset(9.9, 3.8),
    Offset(14.1, 3.8),
    Offset(14.6, 6.4),
  ]);
  p.poly(
    const [
      Offset(6.4, 6.8),
      Offset(7.4, 20.2),
      Offset(16.6, 20.2),
      Offset(17.6, 6.8),
    ],
    fill: Fill.wash,
  );
  p.line(const Offset(10.1, 10.2), const Offset(10.3, 16.6));
  p.line(const Offset(13.9, 10.2), const Offset(13.7, 16.6));
}

void _play(_Pen p) => p.poly(
  const [Offset(7.8, 4.8), Offset(19.2, 12), Offset(7.8, 19.2)],
  close: true,
  fill: Fill.solid,
);

void _pause(_Pen p) {
  p.box(const Rect.fromLTWH(6.4, 5, 3.8, 14), 1.6, fill: Fill.solid);
  p.box(const Rect.fromLTWH(13.8, 5, 3.8, 14), 1.6, fill: Fill.solid);
}

void _clock(_Pen p) {
  p.circle(_c, 8.6, fill: Fill.wash);
  p.line(_c, const Offset(12, 7.2));
  p.line(_c, const Offset(15.4, 14.2));
}

void _alarm(_Pen p) {
  const c = Offset(12, 13);
  p.line(const Offset(7, 19.2), const Offset(5.4, 21.2));
  p.line(const Offset(17, 19.2), const Offset(18.6, 21.2));
  p.circle(c, 7.2, fill: Fill.wash);
  p.line(c, const Offset(12, 9.2));
  p.line(c, const Offset(14.8, 14.6));
  p.shape(
    Path()
      ..moveTo(3.2, 7.4)
      ..quadraticBezierTo(3.8, 3.6, 7.6, 3.4),
    closed: false,
  );
  p.shape(
    Path()
      ..moveTo(20.8, 7.4)
      ..quadraticBezierTo(20.2, 3.6, 16.4, 3.4),
    closed: false,
  );
}

void _ring(_Pen p) => p.circle(_c, 8.2);

void _boxBlank(_Pen p) =>
    p.box(const Rect.fromLTWH(4, 4, 16, 16), 3.6, fill: Fill.none);

void _boxChecked(_Pen p) {
  p.box(const Rect.fromLTWH(4, 4, 16, 16), 3.6, fill: Fill.wash);
  p.tick(const Offset(12, 12.4), .82);
}

final Map<IconData, _Draw> _drawings = {
  Icons.wb_sunny_rounded: _sun,
  Icons.nightlight_round: _moon,
  Icons.smartphone_rounded: _phone,
  Icons.calendar_month_rounded: _calendarMonth,
  Icons.calendar_today_rounded: _calendarDay,
  Icons.calendar_today_outlined: _calendarDay,
  Icons.edit_calendar_rounded: _calendarEdit,
  Icons.local_florist_rounded: _flower,
  Icons.sticky_note_2_rounded: _note,
  Icons.insights_rounded: _insights,
  Icons.auto_awesome_outlined: _sparkles,
  Icons.add_rounded: _add,
  Icons.close_rounded: _close,
  Icons.check_rounded: _check,
  Icons.check: _check,
  Icons.chevron_right_rounded: _chevronRight,
  Icons.arrow_forward_rounded: _arrowForward,
  Icons.arrow_back: _arrowBack,
  Icons.arrow_back_rounded: _arrowBack,
  Icons.settings_rounded: _gear,
  Icons.tune_rounded: _tune,
  Icons.more_horiz_rounded: _more,
  Icons.drag_handle_rounded: _drag,
  Icons.lock_rounded: _lock,
  Icons.link_rounded: _link,
  Icons.inventory_2_outlined: _archive,
  Icons.folder_rounded: _folder,
  Icons.folder_outlined: _folder,
  Icons.create_new_folder_outlined: _folderAdd,
  Icons.edit_outlined: _pencil,
  Icons.visibility_outlined: _eye,
  Icons.delete_outline_rounded: _trash,
  Icons.delete_outline: _trash,
  Icons.play_arrow_rounded: _play,
  Icons.pause_rounded: _pause,
  Icons.schedule_rounded: _clock,
  Icons.alarm_rounded: _alarm,
  Icons.radio_button_unchecked_rounded: _ring,
  Icons.radio_button_unchecked: _ring,
  Icons.check_box_outline_blank_rounded: _boxBlank,
  Icons.check_box_rounded: _boxChecked,
};
