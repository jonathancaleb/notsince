import 'package:flutter/material.dart';
import 'package:notsince/core/theme/sketch.dart';

/// Shape tokens for the sketchbook look: pen-weight outlines, a hard offset
/// shadow, and generous rounded corners.
///
/// Shapes built on [SketchBox] draw a wobbling pen line and a hatched shadow.
/// The [outline] and [shadow] helpers are for the few places still built on
/// `BoxDecoration`: they give the same ink weight and the same hard, blurless
/// offset, so a straight-edged box sits next to a sketched one without looking
/// like it came from a different app.
abstract final class Sticker {
  static const double border = 1.4;
  static const double thinBorder = 1.1;

  static const double radius = 24;

  /// Buttons and chips share the card radius: at 24 everything reads as cut
  /// from the same sheet. Only genuinely small shapes drop below it.
  static const double smallRadius = 24;
  static const double tinyRadius = 16;

  /// Resting depth.
  static const Offset lift = Offset(0, 4);

  /// Pressed depth. Not zero: the shape settles onto the page rather than
  /// vanishing into it.
  static const Offset pressed = Offset(0, 1);

  /// Clearance every scrolling screen leaves at the bottom for the floating
  /// nav island, which paints over the content rather than displacing it.
  static const double navClearance = 104;

  /// A vertical lift turned into the down-and-right offset a pencil shadow
  /// takes, as if the page is lit from the top left.
  static Offset hatchOffset(Offset lift) =>
      Offset(lift.dx + lift.dy * .75, lift.dy);

  static BoxBorder outline(Color ink) =>
      Border.all(color: Sketch.inkLine(ink), width: border);

  static BoxBorder thinOutline(Color ink) =>
      Border.all(color: Sketch.inkLine(ink), width: thinBorder);

  static List<BoxShadow> shadow(Color ink, Offset offset) => [
    BoxShadow(color: Sketch.inkShade(ink), offset: hatchOffset(offset)),
  ];
}
