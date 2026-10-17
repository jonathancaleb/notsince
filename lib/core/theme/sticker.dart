import 'package:flutter/material.dart';

/// Compatibility tokens for existing screens: warm hairlines, soft depth,
/// and generous rounded corners. New screens use lib/theme and lib/widgets.
abstract final class Sticker {
  static const double border = 0.7;
  static const double thinBorder = 0.7;

  static const double radius = 24;

  /// Buttons and chips share the card radius: at 24 everything reads as cut
  /// from the same sheet. Only genuinely small shapes drop below it.
  static const double smallRadius = 24;
  static const double tinyRadius = 16;

  /// Resting depth with a subtle vertical press response.
  static const Offset lift = Offset(0, 4);

  /// Pressed depth. Not zero: the shape settles onto the page rather than
  /// vanishing into it.
  static const Offset pressed = Offset(0, 1);

  /// Clearance every scrolling screen leaves at the bottom for the floating
  /// nav island, which paints over the content rather than displacing it.
  static const double navClearance = 104;

  static BoxBorder outline(Color ink) => Border.all(
    color: ink.withValues(alpha: ink.computeLuminance() > .5 ? .02 : .10),
    width: border,
  );

  static BoxBorder thinOutline(Color ink) => Border.all(
    color: ink.withValues(alpha: ink.computeLuminance() > .5 ? .02 : .10),
    width: thinBorder,
  );

  static List<BoxShadow> shadow(Color ink, Offset offset) => [
    BoxShadow(
      color: Colors.black.withValues(alpha: .05),
      offset: const Offset(0, 4),
      blurRadius: 18,
    ),
  ];
}
