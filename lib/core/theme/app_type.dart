import 'package:flutter/material.dart';
import 'package:notsince/core/theme/ns_colors.dart';

/// Two families with distinct jobs, both bundled as assets rather than fetched
/// by `google_fonts` — the app makes no network calls, and a font that
/// downloads itself would break that. Both licensed OFL; see assets/fonts/.
///
/// Baloo 2 is the voice: heavy, round, slightly goofy. It is used *only* where
/// something should feel spoken out loud — the day count, an alarm time, a
/// screen title. Quicksand carries everything a person actually reads, where
/// Baloo's personality would get tiring.
///
/// None of these styles name a colour. They inherit from the theme's text
/// styles so the same style works in light and dark; anything that needs a
/// specific colour applies it with `copyWith` at the call site.
abstract final class AppType {
  static const display = 'Baloo2';
  static const body = 'Quicksand';

  /// The day count. Sized by the caller; this only fixes its character.
  static TextStyle counter(double size) => TextStyle(
    fontFamily: display,
    fontSize: size,
    fontWeight: FontWeight.w800,
    height: 1.0,
    // Baloo is wide by nature; pulling it in keeps a big number a single
    // shape rather than a row of separate glyphs.
    letterSpacing: size * -0.03,
  );

  static const screenTitle = TextStyle(
    fontFamily: display,
    fontSize: 22,
    fontWeight: FontWeight.w700,
  );

  static const cardTitle = TextStyle(
    fontFamily: display,
    fontSize: 22,
    fontWeight: FontWeight.w600,
  );

  /// Alarm times, which need the same at-a-glance weight as the day count.
  static const clock = TextStyle(
    fontFamily: display,
    fontSize: 34,
    fontWeight: FontWeight.w700,
    height: 1.1,
  );

  static const bodyText = TextStyle(
    fontFamily: body,
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 1.45,
  );

  static const label = TextStyle(
    fontFamily: body,
    fontSize: 16,
    fontWeight: FontWeight.w600,
  );

  static const button = TextStyle(
    fontFamily: body,
    fontSize: 16,
    fontWeight: FontWeight.w700,
    height: 1.2,
  );

  /// Secondary text is a weight and a colour, not a different face.
  static const small = TextStyle(
    fontFamily: body,
    fontSize: 13,
    fontWeight: FontWeight.w500,
    height: 1.45,
  );

  /// Secondary text in the current theme's muted ink.
  static TextStyle muted(NsColors ns) => small.copyWith(color: ns.muted);
}
