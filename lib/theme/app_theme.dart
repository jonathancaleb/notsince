import 'package:flutter/material.dart';
import 'package:notsince/core/theme/app_theme.dart' as legacy;
import 'package:notsince/core/theme/ns_colors.dart';

import 'app_colors.dart';

import 'app_typography.dart';

abstract final class AppTheme {
  static ThemeData get light => _finish(legacy.buildLightTheme());
  static ThemeData get dark => _finish(legacy.buildDarkTheme());
  static ThemeData lightWithAccent(int accent) =>
      _finish(legacy.buildLightTheme(), accent: accent);
  static ThemeData darkWithAccent(int accent) =>
      _finish(legacy.buildDarkTheme(), accent: accent);
  static ThemeData _finish(ThemeData base, {int? accent}) {
    final color = AppColors.lifted(
      accent ?? AppColors.accent.toARGB32(),
      base.brightness,
    );
    final scheme = base.colorScheme.copyWith(
      primary: color,
      secondary: color,
      onPrimary: color.computeLuminance() > .18
          ? AppColors.darkBg
          : Colors.white,
      surface: base.brightness == Brightness.dark
          ? AppColors.darkSurface
          : AppColors.surface,
    );
    return base.copyWith(
      colorScheme: scheme,
      extensions: [
        base.extension<NsColors>()!.copyWith(
          primary: color,
          accent: color,
          onInk: scheme.onPrimary,
        ),
      ],
      textTheme: base.textTheme
          .copyWith(
            displaySmall: AppTypography.display,
            titleLarge: AppTypography.title,
            bodyLarge: AppTypography.body,
            bodyMedium: AppTypography.body,
            labelSmall: AppTypography.caption,
          )
          .apply(bodyColor: scheme.onSurface, displayColor: scheme.onSurface),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 52),
          shape: const StadiumBorder(),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        shape: const StadiumBorder(),
        side: BorderSide(color: scheme.outlineVariant),
      ),
    );
  }
}
