import 'package:flutter/material.dart';
import 'package:notsince/core/theme/app_theme.dart' as legacy;
import 'app_typography.dart';

abstract final class AppTheme {
  static ThemeData get light => _finish(legacy.buildLightTheme());
  static ThemeData get dark => _finish(legacy.buildDarkTheme());
  static ThemeData _finish(ThemeData base) => base.copyWith(
    textTheme: base.textTheme.copyWith(displaySmall: AppTypography.display,
      titleLarge: AppTypography.title, bodyLarge: AppTypography.body,
      bodyMedium: AppTypography.body, labelSmall: AppTypography.caption),
    filledButtonTheme: FilledButtonThemeData(style: FilledButton.styleFrom(
      minimumSize: const Size(48, 52), shape: const StadiumBorder())),
    chipTheme: base.chipTheme.copyWith(shape: const StadiumBorder(),
      side: BorderSide(color: base.colorScheme.outlineVariant)),
  );
}
