import 'package:flutter/material.dart';

/// The constants that make a surface read as a sticker.
///
/// Three rules, applied without exception: one ink outline, one hard offset
/// shadow with no blur, and a radius that stays generous at every size. The
/// discipline is the style — a blurred shadow or a second border colour
/// anywhere would break the illusion that these are cut-out shapes.
///
/// The ink colour is passed in rather than baked in, because it flips between
/// light and dark themes.
abstract final class Sticker {
  static const double border = 0.7;
  static const double thinBorder = 0.7;

  static const double radius = 24;

  /// Buttons and chips share the card radius: at 24 everything reads as cut
  /// from the same sheet. Only genuinely small shapes drop below it.
  static const double smallRadius = 24;
  static const double tinyRadius = 14;

  /// Resting depth. The shadow is the ink colour at full opacity, offset down
  /// and right — a drawn drop shadow, not a lighting effect.
  static const Offset lift = Offset(4, 5);

  /// Pressed depth. Not zero: the shape settles onto the page rather than
  /// vanishing into it.
  static const Offset pressed = Offset(1, 1);

  /// Clearance every scrolling screen leaves at the bottom for the floating
  /// nav island, which paints over the content rather than displacing it.
  static const double navClearance = 104;

  static BoxBorder outline(Color ink) =>
      Border.all(color: ink.withValues(alpha: ink.computeLuminance() > .5 ? .02 : .10), width: border);

  static BoxBorder thinOutline(Color ink) =>
      Border.all(color: ink.withValues(alpha: ink.computeLuminance() > .5 ? .02 : .10), width: thinBorder);

  static List<BoxShadow> shadow(Color ink, Offset offset) =>
      [BoxShadow(color: Colors.black.withValues(alpha: .05), offset: const Offset(0, 4), blurRadius: 18)];
}

