import 'package:flutter/material.dart';

/// Habit-level colours that live outside the theme's [NsColors].
///
/// The crayon palette is duplicated in [NsColors] (theme-sized, lerped across
/// light/dark); this holds the same list flat, for screens that pick an accent
/// before a theme exists — onboarding's accent picker, the habit form.
///
/// `bg`, `ink` and friends mirror `NsColors.light`/`NsColors.dark`; they are
/// read where no `BuildContext` exists (alarm tinting on the schedule).
abstract final class AppColors {
  static const bg = Color(0xFFFAF7F0);
  static const surface = Color(0xFFFFFDF8);
  static const ink = Color(0xFF302C27);
  static const accent = Color(0xFF639922);
  static const darkBg = Color(0xFF171513);
  static const darkSurface = Color(0xFF1E1C1A);
  static const darkInk = Color(0xFFF3EDE3);
  static const palette = <int>[
    0xFF639922,
    0xFFE8B33D,
    0xFF5B9DC9,
    0xFF9B7BC4,
    0xFF2E9187,
    0xFFD2739B,
  ];
  static Color lifted(int argb, Brightness brightness) =>
      brightness == Brightness.dark
      ? Color.lerp(Color(argb), Colors.white, .1)!
      : Color(argb);
}
